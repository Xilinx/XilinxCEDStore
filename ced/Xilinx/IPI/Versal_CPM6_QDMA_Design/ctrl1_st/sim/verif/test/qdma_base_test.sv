import uvm_pkg::*;
import shim_pkg::*;
import shim_enum_pkg::*;
import shim_caps_pkg::*;
import cpm6_qdma_params_pkg::*;
import qdma_periph_agent_pkg::*;
// Note: this file is included within the test package; do not import that package here
`include "uvm_macros.svh"

class qdma_base_test #(
  bit [31:0] CMPT_ADDR           = 32'h3000,
  integer    QUEUE_PER_PF        = 32,
  bit [31:0] GLBL_RNG_SIZE       = RING_SIZE,
  bit [31:0] QUEUE_PTR_PF_ADDR   = 32'h00018000,
  int        MM_ST               = 1,//1 -> MM, 0 -> ST
  int        Tcq                 = 1) extends base_ep_test;

  byte host_mem[int];
  bit  enable_c2h_cmpt;  // runtime flag: +ENABLE_C2H_CMPT
  // Completion timer-coalescing test hooks. Default behavior (no plusarg) is
  // trig_mode=WRB_TRIG_EVERY.
  bit  cmpt_timer_test;   // +CMPT_TIMER_TEST -- program trig_mode=WRB_TRIG_USER_TIMER instead of EVERY
  int  cmpt_timer_idx;    // +CMPT_TIMER_IDX=<0..15> (default 1) -- timer_ix into the threshold table
  int  cmpt_timer_thresh; // +CMPT_TIMER_THRESH=<n>  (default 32) -- threshold table entry value (ref_timer ticks)
  // Completion contexts as written at queue setup, keyed by hardware qid, and
  // the BAR they were written through. Read back after the transfers by
  // TSK_CMPT_CTXT_POST_CHECK.
  bit [255:0] cmpt_ctxt_exp [bit [10:0]];
  int         cmpt_ctxt_bar [bit [10:0]];
  localparam bit [15:0]  GLBL_ERR_STAT_OFFSET = 16'h248;
  localparam bit [255:0] IND_CTXT_200B_MASK   = (256'h1 << 200) - 256'h1;  // DATA0..DATA6[7:0]

  `uvm_component_utils(qdma_base_test);

  amd_cfg_tlp        cfg_tlp;

  pcie_device        pdev_ep;

  virtual task pre_main_phase(uvm_phase phase);
    super.pre_main_phase(phase);
    phase.raise_objection(this);

    // Configure PS VIP for QDMA - this must be done after CDO loads
    `ifdef CPM6_VIVADO
      `ifndef QEMU_PS
        `uvm_info(get_type_name(), "Configuring PS VIP for QDMA operation", UVM_MEDIUM)

        // Set up PS NOC PCI AXI interface clocks (required for QDMA DMA transfers)
        `uvm_info(get_type_name(), "Setting PS NOC PCI AXI clocks to 333.33 MHz", UVM_MEDIUM)
        ps_vip_api.ps_gen_clock(13, 333.33);  // psnocpci0axi_aclk
        ps_vip_api.ps_gen_clock(14, 333.33);  // psnocpci1axi_aclk

        // Set up AXI routing paths for QDMA data transfers
        // These connect CPM AXI master ports to PS NOC slave ports
        `uvm_info(get_type_name(), "Configuring PS VIP AXI routing paths", UVM_MEDIUM)
        ps_vip_api.set_routing_config(CPM_PS_AXI_0, PS_NOC_PCI_AXI_0, 1'b1);
        ps_vip_api.set_routing_config(CPM_PS_AXI_1, PS_NOC_PCI_AXI_1, 1'b1);
        ps_vip_api.set_routing_config(NOC_PS_PCI_AXI_0, PS_CPM_PCIE_AXI, 1'b1);

        `uvm_info(get_type_name(), "PS VIP configuration for QDMA complete", UVM_MEDIUM)
      `endif
    `endif

    phase.drop_objection(this);
  endtask

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    phase.raise_objection(this);
      `uvm_info(get_type_name, $sformatf("number of pdevs = %0d",env.shim.container.pdev.size), UVM_MEDIUM)
      pdev_ep = env.shim.container.get_pdev_EP;

      // Program PCIe Device Control Register (MRRS / MPS) after enumeration.
      // Defaults: MRRS=3 (1024B), MPS=2 (512B). MPS=2 matches the RC/VIP side's own Device
      // Control default. Override via +PCIE_MRRS=<0-5> / +PCIE_MPS=<0-3>.
      begin
        int parg_mrrs, parg_mps;
        parg_mrrs = 3;
        parg_mps  = 2;
        void'($value$plusargs("PCIE_MRRS=%0d", parg_mrrs));
        void'($value$plusargs("PCIE_MPS=%0d",  parg_mps));
        TSK_PROGRAM_PCIE_DEVCTL(parg_mrrs[2:0], parg_mps[2:0]);
      end
    phase.drop_objection(this);
  endtask

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  parameter NUM_FN=9'h1;
  parameter int NUM_CHN = 128;
  parameter int NUM_PFS = NUM_PF;//Supported by PCIe controller
  parameter int MAX_PFS = 4;//Supported by QDMA
  parameter int MAX_VFS = 252;//Supported by QDMA
  parameter int DSC_CNT_QID = 'd8; //Number of descriptors loaded per each qid.
  // Number of AXI-PL destination ports to distribute DMA traffic across (1–4).
  // Overridden at runtime by +NUM_DMA_PORTS=N plusarg; set in build_phase.
  // Default 1 = all traffic to AXI-PL0 (ADDR0 = 0xC000_0000).
  // Ports: 0=ADDR0(AXI-PL0), 1=ADDR1(AXI-PL1), 2=ADDR2(AXI-PL2), 3=ADDR3(AXI-PL3).
  // Distribution is sequential (not qid-based) so all ports get equal traffic
  // regardless of the qid values used by the test.
  int num_dma_ports  = 1;   // set by +NUM_DMA_PORTS; default = AXI-PL0 only
  int dma_port_base  = 0;   // set by +DMA_PORT_BASE; offset added to port assignment
  // Number of CPM6 DMA apertures that target a CPM_AXI_PLn port, i.e. the
  // highest port_id a transfer can use and still be routed. A port with no
  // aperture behind it leaves the transfer address unmapped and the channel
  // aborts before issuing any AXI beat. This is a property of the block design
  // (how many DMA apertures name a CPM_AXI_PLn destination), not of the DMA
  // mode, so it applies equally to MM and ST and is overridable rather than
  // hard-coded. Override with +MAX_DMA_PORTS when the aperture map changes.
  int max_dma_ports  = 3;   // set by +MAX_DMA_PORTS

  // qid -> actual descriptor size in bytes for that queue's ring (32 for MM,
  // 16 for ST). Set by whichever TSK_INIT_QDMA_{MM,ST}_DATA_{H2C,C2H} task
  // programs the queue; read by dma_req_processor to compute the writeback
  // status slot address, which sits at the END of the ring's fixed
  // RING_SIZE*QDMA_DSC_SZ byte window -- a position that depends on the
  // actual per-descriptor size, not on QDMA_DSC_SZ (32) alone: the last slot
  // is (window_size - actual_dsc_sz), not (ring_entries-1)*QDMA_DSC_SZ.
  int h2c_qid_dsc_sz[int];
  int c2h_qid_dsc_sz[int];
  // Ring base per C2H queue, as programmed in its SW context. The stream tasks
  // place rings at a 16 B pitch while stream descriptors are 8 B, so the base
  // cannot be recovered from the descriptor size alone.
  longint unsigned c2h_qid_dsc_base[int];

  integer i,j,k;
  integer PF_DMA_BAR_INDEX = 1;
  integer PF_USR_BAR_INDEX = 2;
  integer VF_DMA_BAR_INDEX = 1;
  bit [7:0]      fnc = 0;
  bit [3:0]      pf_fnc = 0;  // 0-based PF function number for the current PF under test
  // MSI-X vector table BAR/offset are read per-function from that function's
  // own MSI-X capability (pdev_ep.msi_x / pdev_ep.vf[n+1].msi_x, populated by
  // seq_cap_traverse during enumeration) -- see TSK_PROGRAM_MSIX_VEC_TABLE.
  // PBA base is unused by this test; PF_MSIX_PBA_OFFSET/VF_MSIX_PBA_OFFSET
  // below are not referenced.
  bit [31:0]     PF_MSIX_PBA_OFFSET = 32'h15000; // PF PBA base in BAR0
  // Vectors allocated per function. PF and VF each get 8; at 16 B per MSI-X table
  // entry this makes the per-VF table stride 0x80. Used both as the programming
  // loop bound and as that stride, so the two can never drift apart.
  int unsigned   MSIX_VEC_PER_FNC   = 8;
  bit [31:0]     VF_MSIX_PBA_OFFSET = 32'h15000; // VF PBA base in BAR0
  bit [15:0]     pidx = 5;
  // pkt_count: the only user-facing "how many packets" input (+PKT_COUNT=).
  // pidx (above) is ALWAYS derived from it -- pidx = pkt_count *
  // per-packet-descriptor-count -- never set directly from a plusarg.
  bit [15:0]     pkt_count = 1;
  bit [31:0] DMA_BYTE_CNT        = 32'h1000;

  // ---------------------------------------------------------------------
  // Driver-accurate scatter-gather transfer mode (+XFER_BYTES)
  // ---------------------------------------------------------------------
  // Default TB behaviour builds `pidx` IDENTICAL descriptors, each moving
  // DMA_BYTE_CNT bytes from/to the SAME src and dst, with SDI set on every
  // one. That is a throughput stimulus, not what the driver emits.
  //
  // The Linux driver splits a transfer by PAGE. Each SG entry becomes one MM
  // descriptor, so a transfer of N bytes yields
  // ceil(N/PAGE) descriptors with ADVANCING src/dst and a SHORT final
  // descriptor -- e.g. 40000 B -> 10 descriptors: 9 x 4096 + 1 x 3136.
  //
  // When xfer_bytes > 0 this mode is active and pidx is derived from it
  // (pidx = pkt_count * ceil(xfer_bytes/desc_page_bytes)). When xfer_bytes == 0
  // (default) pidx = pkt_count.
  // ---------------------------------------------------------------------
  // 64-bit descriptor ring base (+DSC_BASE_HI) -- split hi/lo by design
  // ---------------------------------------------------------------------
  // dsc_base is a 64-bit field in the SW context, but the TB's host memory
  // model is `byte host_mem[int]` -- a 32-bit SIGNED index. Widening that
  // array to exercise a >4 GB base would silently alias every descriptor
  // access to a low address.
  //
  // So the base is split instead of widened:
  //   [31:0]  dsc_base   - the computed value. Host memory is stored
  //                        and retrieved by THIS word only, so host_mem[int]
  //                        stays correct.
  //   [63:32] dsc_base_hi - programmed into the SW context so the DUT emits a
  //                        genuine 64-bit fetch address. qdma_mem_callback
  //                        checks the upper word arrived intact and services
  //                        the read from the lower one.
  bit [31:0] dsc_base_hi     = 32'h0;     // +DSC_BASE_HI (upper word of dsc_base)

  // +C2H_SRC_OFFSET=<hex bytes>: card-side offset added to every MM C2H source
  // address. 0 (default) keeps the loopback layout, where a queue's C2H source
  // is the same card bytes its H2C transfer writes. A non-zero offset moves the
  // C2H source to bytes no H2C transfer touches, so H2C writes and C2H reads of
  // one queue never target the same memory. The C2H payload is then not loopback
  // data and the scoreboard reports it NOT CHECKED; byte counts are still checked.
  bit [31:0] c2h_src_offset  = 32'h0;

  bit [31:0] xfer_bytes      = 32'h0;     // +XFER_BYTES  (driver's -s argument)
  bit [31:0] desc_page_bytes = 32'h1000;  // +DESC_PAGE_BYTES (SG granularity, 4 KB)

  // ---------------------------------------------------------------------
  // Multi-packet transfer mode (+XFER_LIST) -- several packets, ONE test
  // ---------------------------------------------------------------------
  // +XFER_LIST=65536,34048 sends each byte count as its OWN packet on the same
  // queue, in order, with a fresh doorbell per packet. The producer index the
  // doorbell carries is CUMULATIVE, so it differs every round (65536 -> pidx 16,
  // then 34048 -> pidx 25). The TB completes that packet's checks BEFORE ringing
  // the next doorbell, so a failure is attributable to one packet rather than to
  // an aggregate.
  //
  // Relationship to +XFER_BYTES: single-packet mode is the 1-element case of
  // this. They are mutually exclusive.
  // xfer_bytes is RE-DRIVEN from xfer_list[p] as each packet is staged.
  bit [31:0] xfer_list [$];               // +XFER_LIST, one entry per packet

  // Total descriptors across the whole list -- the final cumulative pidx.
  function automatic int unsigned xfer_list_total_desc();
    int unsigned t = 0;
    foreach (xfer_list[i])
      t += int'((xfer_list[i] + desc_page_bytes - 1) / desc_page_bytes);
    return t;
  endfunction

  // ---------------------------------------------------------------------
  // Runtime descriptor-ring size (+RING_ENTRIES) -- for rollover testing
  // ---------------------------------------------------------------------
  // The hardware ring size programmed into the GLBL_RNG_SZ table at BAR1
  // 0x204+ and the per-queue descriptor-ring ADDRESS SPACING
  // (dsc_base = BASE + qid*GLBL_RNG_SIZE*QDMA_DSC_SZ) are kept separate to
  // test ring rollover. Shrinking the ring so pidx
  // wraps quickly is cheap; shrinking the SPACING as well would desync
  // dma_req_processor, which derives qid from address using the package
  // RING_SIZE and would then attribute every TLP to the wrong queue.
  //
  // So: ring_entries = how many descriptors the ring holds (what the DUT wraps
  // at, what pidx is taken modulo, where the WB status descriptor lives).
  //     GLBL_RNG_SIZE = address spacing only, left at RING_SIZE.
  //
  // Defaults to GLBL_RNG_SIZE.
  bit [31:0] ring_entries = GLBL_RNG_SIZE;

  // Usable descriptor slots: the LAST ring entry is reserved for the writeback
  // status descriptor, so pidx wraps at ring_entries-1, not ring_entries.
  function automatic bit [31:0] ring_usable();
    return (ring_entries > 1) ? (ring_entries - 1) : 32'd1;
  endfunction

  // C2H-ST packet size generated by the example-design C2H source
  // (+C2H_PKT_BYTES; 0 = same as DMA_BYTE_CNT). The source takes one C2H
  // buffer (C2H_SRC_BUF_BYTES) per descriptor, so a longer packet consumes
  // several descriptors: PIDX counts packets and the C2H ring advances by
  // c2h_dsc_per_pkt() descriptors per packet.
  int unsigned c2h_pkt_bytes = 0;
  localparam int unsigned C2H_SRC_BUF_BYTES = 4096;
  // Example-design C2H source configuration block: PF/VF USR BAR (BAR2),
  // offset 0 (through AXI-PL3). Reset values: 512-byte packets on every
  // port, MAX_DSC 7.
  localparam bit [31:0]   C2H_SRC_CFG_OFF       = 32'h0000_0000;
  localparam bit [31:0]   C2H_SRC_CFG_ID        = 32'h4332_4843;
  localparam int unsigned C2H_SRC_RST_PKT_BYTES = 512;
  localparam int unsigned C2H_SRC_RST_MAX_DSC   = 7;
  localparam int unsigned C2H_SRC_NUM_PORTS     = 4;
  int unsigned c2h_src_pkt_bytes_q[int unsigned];   // value last programmed per port
  int unsigned c2h_src_max_dsc_q = C2H_SRC_RST_MAX_DSC;
  bit          c2h_src_cfg_seen  = 1'b0;   // ID register checked
  bit          c2h_src_neg_done  = 1'b0;   // +C2H_SRC_CFG_NEG checks run
  // Register-driven C2H generator. Port 0 at qdma_v5.1-aligned offsets
  // (QID 0x00, LEN 0x04, CONTROL 0x08 bit[1]=START, NUM_PKT 0x20; STOP and
  // BUSY/STOPPED/left status at EXT_CONTROL 0x100, BURST_SEQ 0x104, PKT_INFO
  // 0x108, PKT_CNT 0x10C). Ports 1-3 use a combined CONTROL
  // (bit[0]=START/bit[1]=STOP) at a 0x20-byte stride from 0x120; shared
  // ID/VERSION/CAPS/STATUS/BUF_BYTES/MAX_DSC at 0x1C0-0x1D4. Software
  // posts descriptors and then starts a burst; the generator does not follow
  // the PIDX doorbell.
  localparam bit [31:0]   C2H_SRC_CFG_VERSION   = 32'h0003_0000;
  localparam bit [31:0]   C2H_SRC_A_ID          = 32'h1C0;
  localparam bit [31:0]   C2H_SRC_A_VERSION     = 32'h1C4;
  localparam bit [31:0]   C2H_SRC_A_STATUS      = 32'h1CC;
  localparam bit [31:0]   C2H_SRC_A_MAX_DSC     = 32'h1D4;
  localparam bit [31:0]   C2H_SRC_P13_BASE      = 32'h120;
  localparam bit [31:0]   C2H_SRC_P13_STRIDE    = 32'h20;

  // Byte offset of a per-port register. `word` is the within-port-block byte
  // offset ports 1-3 use (QID 0x00, LEN 0x04, CONTROL 0x08, NUM_PKT 0x0C,
  // BURST_SEQ 0x10, PKT_INFO 0x14, PKT_CNT 0x18); port 0 uses its own
  // qdma-aligned or extension address, passed as port0_addr.
  function automatic bit [31:0] c2h_src_a(input int unsigned port, input bit [31:0] port0_addr, input bit [31:0] word);
    return (port == 0) ? port0_addr : (C2H_SRC_P13_BASE + C2H_SRC_P13_STRIDE * (port - 1) + word);
  endfunction
  function automatic bit [31:0] c2h_src_a_qid(input int unsigned port);    return c2h_src_a(port, 32'h000, 32'h00); endfunction
  function automatic bit [31:0] c2h_src_a_len(input int unsigned port);    return c2h_src_a(port, 32'h004, 32'h04); endfunction
  function automatic bit [31:0] c2h_src_a_num(input int unsigned port);    return c2h_src_a(port, 32'h020, 32'h0C); endfunction
  function automatic bit [31:0] c2h_src_a_info(input int unsigned port);   return c2h_src_a(port, 32'h108, 32'h14); endfunction
  function automatic bit [31:0] c2h_src_a_seq(input int unsigned port);    return c2h_src_a(port, 32'h104, 32'h10); endfunction
  function automatic bit [31:0] c2h_src_a_status(input int unsigned port); return c2h_src_a(port, 32'h100, 32'h08); endfunction
  function automatic bit [31:0] c2h_src_a_start(input int unsigned port);  return c2h_src_a(port, 32'h008, 32'h08); endfunction
  function automatic bit [31:0] c2h_src_start_bit(input int unsigned port); return (port == 0) ? 32'h2 : 32'h1; endfunction
  function automatic bit [31:0] c2h_src_a_pkt_cnt(input int unsigned port); return c2h_src_a(port, 32'h10C, 32'h18); endfunction
  semaphore    c2h_src_port_lock [C2H_SRC_NUM_PORTS];   // one burst setup / size change per port at a time
  int unsigned c2h_src_burst_seq [C2H_SRC_NUM_PORTS];   // bursts started per port (BURST_SEQ model)
  longint unsigned c2h_src_pkts_started [C2H_SRC_NUM_PORTS];   // Σ NUM_PKT per port (PKT_CNT model)
  int          c2h_src_bursts_pending = 0;              // requested, not yet started
  bit          c2h_src_sched_up = 1'b0;
  // Doorbell-to-START barrier: descriptors posted per queue, counted from the
  // DMA's C2H descriptor-status events (tm_dsc_sts avl), against descriptors
  // the bursts started so far need. A burst starts only when the queue has
  // enough posted descriptors that no earlier burst has used.
  virtual qdma_periph_tm_dsc_if c2h_src_tm_vif;
  longint      c2h_src_dsc_posted    [bit [10:0]];
  longint      c2h_src_dsc_committed [bit [10:0]];
  int unsigned c2h_src_barrier_ns = 200000;   // +C2H_SRC_BARRIER_NS: longest wait for posted descriptors
  int unsigned c2h_src_idle_ns    = 1000000;  // +C2H_SRC_IDLE_NS: longest wait for a port's burst to end

  function automatic int unsigned c2h_eff_pkt_bytes();
    return (c2h_pkt_bytes != 0) ? c2h_pkt_bytes : int'(DMA_BYTE_CNT);
  endfunction

  function automatic int unsigned c2h_dsc_per_pkt();
    return (c2h_eff_pkt_bytes() + C2H_SRC_BUF_BYTES - 1) / C2H_SRC_BUF_BYTES;
  endfunction

  // C2H ring PIDX for +PIDX packets
  function automatic bit [15:0] c2h_ring_pidx();
    return 16'(int'(pidx) * c2h_dsc_per_pkt());
  endfunction

  // Host-address stride of the per-queue C2H destination window: large enough
  // for both a DMA_BYTE_CNT transfer and one C2H packet.
  function automatic int unsigned c2h_qid_shift();
    int unsigned a, b;
    a = $clog2(int'(DMA_BYTE_CNT));
    b = $clog2(c2h_eff_pkt_bytes());
    return (a > b) ? a : b;
  endfunction

  // Number of descriptors the driver would emit for xfer_bytes.
  function automatic int unsigned xfer_num_desc();
    if (xfer_bytes == 0) return 0;
    return int'((xfer_bytes + desc_page_bytes - 1) / desc_page_bytes);
  endfunction

  // Byte count carried by descriptor k (the last one is short).
  //
  // The MM descriptor's lengthInBytes field is [79:64] -- SIXTEEN bits -- so a
  // single descriptor can carry at most 65535 B. desc_page_bytes must respect
  // that; a larger value would silently truncate and move the wrong byte count.
  function automatic bit [31:0] xfer_desc_len(input int unsigned k);
    bit [31:0] consumed;
    bit [31:0] this_len;
    consumed = k * desc_page_bytes;
    if (consumed >= xfer_bytes) return 32'h0;
    this_len = ((xfer_bytes - consumed) < desc_page_bytes) ? (xfer_bytes - consumed)
                                                          : desc_page_bytes;
    if (this_len > 32'hFFFF)
      `uvm_fatal("XFER_SG",
        $sformatf("descriptor %0d length %0d B exceeds the 16-bit MM lengthInBytes field ([79:64], max 65535) -- reduce +DESC_PAGE_BYTES",
                  k, this_len))
    return this_len;
  endfunction
  bit glbl_pgm_done=0;
  bit [(MAX_PFS + MAX_VFS - 1) : 0] fnc_map_pgm_done='0;

  logic [NUM_CHN-1:0]         CHANNEL_IRQ;

  // Initialised at declaration: if left X, TSK_FIND_PF_VF_NUM's range compare
  // would evaluate X -> false and every VF would decode to vfn=0.
  logic  [15:0] FIRST_VF_OFFSET [NUM_PFS-1:0] = '{default: 16'(VF_OFFSET)};
  reg    [15:0] NUM_VFS         [NUM_PFS-1:0] = '{default: 16'(NUM_VF)};
  reg    [15:0] TOTAL_VFS       [NUM_PFS-1:0] = '{default: 16'h20};
  bit           error_check;
  logic   [31:0][31:0]            MAILBOX_MSG_DATA_SND, MAILBOX_MSG_DATA_RCV;
  amd_mem_tlp     mem_tlp;
  bit [10:0] qid;

  host_req_bus dma_trfr_bus;
  dma_req_processor dma_req_proc;
  h2c_user_subscriber h2c_user_sub;
  cpm_axi_pl_vnc_env   axi_pl_env;
  pswizard_agent       psw_agnt;
  qdma_periph_agent    qdma_periph_agnt;
  // Per-HDMA-channel lifecycle status map — subscribes to
  // qdma_periph_agnt.ap + psw_agnt.ap, connected in connect_phase below.
  dma_channel_status_tracker chan_status_tracker;
  qdma_user_agent      user_agnt[4];
`ifdef USE_DSC_CRDT
  dsc_crdt_agent       dsc_crdt_agnt;
`endif
  int shared_log_fd;  // shared file descriptor for cpm6_qdma_dbg.log
  int use_dsc_crdt;   // 1=use dsc_crdt PL-side credits instead of PIDX doorbells
  int c2h_pfch;       // 1=C2H-ST descriptor prefetch engine present (see C2H_PFCH plusarg)
  int c2h_pfch_en;    // prefetch context pfch_en for C2H-ST queues (see C2H_PFCH_EN plusarg)
  int driver_mode;    // 1=stream queues post descriptors as the host driver does (see DRIVER_MODE plusarg)
  // SW-context bypass bit for the streaming queues. Defaults to 0 (non-bypass),
  // where the descriptor size is fixed by specification -- 32B memory-mapped,
  // 16B H2C stream, 8B C2H stream -- rather than chosen by software. Set the
  // ST_DSC_BYPASS plusarg to 1 to program the queues as bypass instead, where
  // software selects the size.
  int st_dsc_bypass;
  // When set to 1, qdma_user_agent is created as UVM_ACTIVE (driver+sequencer)
  // so C2H prefill sequences can inject data into the bridge FIFO.
  // Set by ST tests when direction includes C2H.
  bit c2h_active = 0;
  // Set to 0 via +ENABLE_QDMA_MON=0 plusarg to disable all passive monitor agents.
  // Default 1 (enabled). When disabled, no monitor agent is created and
  // cpm6_qdma_dbg.log contains only the header lines.
  int enable_qdma_mon = 1;
  time TIMEOUT = 500us;

  // Apply the UVM phase timeout as the max of the test's floor (TIMEOUT) and
  // whatever +SIM_TIMEOUT set in test_base.end_of_elaboration_phase (stored in
  // 'timeout'). This runs after super so +SIM_TIMEOUT is already parsed.
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    if (timeout > TIMEOUT)
      TIMEOUT = timeout;
    uvm_top.set_timeout(TIMEOUT, 1);
  endfunction

  // Set use_vf_enum=1 in end_of_elaboration_phase of any test that uses VFs.
  // start_of_simulation_phase runs after end_of_elaboration_phase and after
  // test_base calls setup_vip_defaults() (which sets bus_enum_skip_vf_enable=1).
  // Applying the override here ensures the BFM setting is never overwritten.
  bit use_vf_enum = 0;
  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    if (use_vf_enum) begin
      // The DUT places its VFs at functions 1..TotalVFs (First VF Offset 1, Stride 1),
      // so VF function numbers above 7 are reachable only through ARI. The VIP root
      // port draws ARI and SR-IOV support at random when it is constructed; without
      // SR-IOV support its enumeration leaves the PF's SR-IOV control untouched (no
      // NumVFs, no VF Enable). Pin both so that VF enumeration does not depend on the
      // seed or on the simulator build.
      env.shim.vip.cfg_info.ARI_sup   = 1;
      env.shim.vip.cfg_info.SRIOV_sup = 1;
      env.shim.vip.set("bus_enum_skip_vf_enable", 0); // activate VFs during enumeration
      `uvm_info("VF_ENUM", $sformatf("VIP root port ARI_sup=%0d SRIOV_sup=%0d",
                env.shim.vip.cfg_info.ARI_sup, env.shim.vip.cfg_info.SRIOV_sup), UVM_LOW)
    end
  endfunction

  virtual function void build_phase(uvm_phase phase);
    phase.raise_objection(this);
      super.build_phase(phase);

      // Open the shared debug log file once; all monitors retrieve this fd
      // via uvm_config_db rather than opening the file themselves.
      shared_log_fd = $fopen("cpm6_qdma_dbg.log", "w");
      if (shared_log_fd == 0)
        `uvm_fatal("qdma_base_test", "Failed to open cpm6_qdma_dbg.log for writing")
      $fdisplay(shared_log_fd, "# cpm6_qdma_dbg.log  - DMA monitor log");
      $fdisplay(shared_log_fd, "# src:  DMA = PCIe TLP scoreboard");
      $fdisplay(shared_log_fd, "# DMA  events:  DSC_FETCH, DMA, DONE, MISMATCH, UNKNOWN_MRD/MWR, SUMMARY");
      $fdisplay(shared_log_fd, "# DMA  detail:  addr  bytes  cum/exp (rem)  tlp#N");
      uvm_config_db#(int)::set(this, "*", "log_fd", shared_log_fd);

    dma_trfr_bus = host_req_bus::type_id::create("dma_trfr_bus",this);
      dma_req_proc = dma_req_processor::type_id::create("dma_req_proc",this);
      // give bus to dma_req_processor via config_db
      uvm_config_db#(host_req_bus)::set(this, "dma_req_proc", "dma_trfr_bus", dma_trfr_bus);

      // Parse +NUM_DMA_PORTS=N plusarg: number of AXI-PL ports to use (1-4, default 1).
      // Queues are assigned to ports sequentially (not by qid) for even distribution.
      if (!$value$plusargs("NUM_DMA_PORTS=%d", num_dma_ports))
        num_dma_ports = 1;
      `uvm_info("qdma_base_test", $sformatf("NUM_DMA_PORTS=%0d (H2C/C2H distributed by qid%%num_dma_ports)", num_dma_ports), UVM_MEDIUM)

      // Parse +DMA_PORT_BASE=N plusarg: base port offset (default 0).
      // When DMA aperture routes all traffic to a specific port (e.g. port 3),
      // set this to match so c2h_source_ctrl pushes data to the correct bridge.
      if (!$value$plusargs("DMA_PORT_BASE=%d", dma_port_base))
        dma_port_base = 0;
      if (dma_port_base != 0)
        `uvm_info("qdma_base_test", $sformatf("DMA_PORT_BASE=%0d (port_id = qid%%num_dma_ports + %0d)", dma_port_base, dma_port_base), UVM_MEDIUM)

      // Parse +MAX_DMA_PORTS=N: highest usable port_id + 1, from the aperture map.
      if (!$value$plusargs("MAX_DMA_PORTS=%d", max_dma_ports))
        max_dma_ports = 3;
      // Warn rather than clamp: clamping would silently change the port
      // distribution a test asked for, and the abort this predicts is easier to
      // recognise when the warning names it in advance.
      if ((num_dma_ports + dma_port_base) > max_dma_ports)
        `uvm_warning("qdma_base_test", $sformatf(
          "NUM_DMA_PORTS=%0d + DMA_PORT_BASE=%0d reaches port_id %0d, but only %0d DMA aperture(s) target a CPM_AXI_PLn port (max port_id %0d). Transfers on the unmapped port(s) will land outside every aperture and the channel will abort before any AXI beat is issued. Raise +MAX_DMA_PORTS only after adding the matching aperture in the block design.",
          num_dma_ports, dma_port_base, num_dma_ports + dma_port_base - 1,
          max_dma_ports, max_dma_ports - 1))

      // Parse +DSC_BASE_HI=<hex>: upper 32 bits of the 64-bit descriptor ring
      // base. Read HERE, in the base test, so every path that programs a SW
      // context (MM H2C/C2H, ST, VF) picks it up from the one variable -- all of
      // them write {dsc_base_hi, dsc_base[31:0]} into wr_dat[127:64].
      //
      // The split is deliberate: host_mem is indexed by the LOW word only, so
      // descriptor storage and retrieval are untouched, while the DUT is
      // programmed with a genuine 64-bit address and must emit it on the wire.
      // qdma_mem_callback checks every TLP's upper word against this
      // value and errors if the DUT emits an address the TB never programmed.
      if (!$value$plusargs("DSC_BASE_HI=%h", dsc_base_hi))
        dsc_base_hi = 32'h0;
      if (dsc_base_hi != 32'h0)
        `uvm_info("qdma_base_test", $sformatf(
          "DSC_BASE_HI=0x%08h -- descriptor rings programmed at 64-bit base 0x%08h_xxxxxxxx; every DMA TLP must carry this upper word",
          dsc_base_hi, dsc_base_hi), UVM_LOW)

      // MM C2H source placement. With DIRECTION=BOTH, a queue's C2H transfer
      // runs while its own H2C transfer is still writing card memory. In the
      // loopback layout (offset 0) both use the same card bytes, so the C2H
      // channel reads bytes the H2C channel is concurrently writing: the
      // payload is undefined and the C2H write channel can stop after a
      // partial transfer. In MM builds DIRECTION=BOTH therefore defaults the
      // C2H source to the upper half of the PL BRAM aperture, away from every
      // H2C destination, whenever all H2C destinations fit below it. ST builds
      // keep the loopback default: their C2H payload check relies on it. An
      // explicit +C2H_SRC_OFFSET always wins; +C2H_SRC_OFFSET=0 restores the
      // loopback layout.
      if (!$value$plusargs("C2H_SRC_OFFSET=%h", c2h_src_offset)) begin
        string       dir_arg;
        int unsigned n_pf = 1, n_vf = 0, n_q = 1;
        int unsigned slot_bytes = DMA_BYTE_CNT, q_bytes, xb = 0;
        longint unsigned h2c_end;
        c2h_src_offset = 32'h0;
        if (DMA_ST == 0 && $value$plusargs("DIRECTION=%s", dir_arg) && dir_arg == "BOTH") begin
          void'($value$plusargs("NUM_PF_TEST=%d", n_pf));
          void'($value$plusargs("NUM_VF_TEST=%d", n_vf));
          void'($value$plusargs("NUM_Q_TEST=%d", n_q));
          void'($value$plusargs("DMA_BYTE_CNT=%d", slot_bytes));
          void'($value$plusargs("XFER_BYTES=%d", xb));
          q_bytes = (xb != 0) ? xb : slot_bytes;
          // H2C destinations occupy slots 0..N-1 at a DMA_BYTE_CNT stride, so
          // the last one ends at (N-1) x stride + per-queue bytes.
          h2c_end = ((n_pf + n_vf) * n_q == 0) ? 0 :
                    longint'((n_pf + n_vf) * n_q - 1) * slot_bytes + q_bytes;
          if (h2c_end <= PL_BRAM_APERTURE_SIZE / 2)
            c2h_src_offset = 32'(PL_BRAM_APERTURE_SIZE / 2);
          else
            `uvm_warning("qdma_base_test", $sformatf(
              "DIRECTION=BOTH: H2C destinations end at 0x%0h, above half the 0x%0h-byte PL BRAM aperture, so the C2H source stays on the H2C destination bytes (loopback layout); each queue's C2H reads bytes its H2C may still be writing",
              h2c_end, PL_BRAM_APERTURE_SIZE))
        end
      end
      if (c2h_src_offset != 32'h0)
        `uvm_info("qdma_base_test", $sformatf(
          "C2H_SRC_OFFSET=0x%0h -- MM C2H source moved off the H2C destination bytes; C2H payload is not loopback data and is reported NOT CHECKED",
          c2h_src_offset), UVM_LOW)
      // The scoreboard decides payload checking from the same value.
      uvm_config_db#(bit [31:0])::set(this, "dma_req_proc", "c2h_src_offset", c2h_src_offset);

      // Parse +ENABLE_C2H_CMPT plusarg: enable C2H completion context programming.
      enable_c2h_cmpt = $test$plusargs("ENABLE_C2H_CMPT") ? 1'b1 : 1'b0;
      if (enable_c2h_cmpt)
        `uvm_info("qdma_base_test", "ENABLE_C2H_CMPT: C2H completion context will be programmed", UVM_MEDIUM)

      // Parse +CMPT_TIMER_TEST plusarg: exercise timer-based
      // coalescing (trig_mode=WRB_TRIG_USER_TIMER) instead of the default
      // trig_mode=EVERY. Only meaningful when ENABLE_C2H_CMPT is also set.
      cmpt_timer_test = $test$plusargs("CMPT_TIMER_TEST") ? 1'b1 : 1'b0;
      if (!$value$plusargs("CMPT_TIMER_IDX=%0d", cmpt_timer_idx))
        cmpt_timer_idx = 1;
      if (!$value$plusargs("CMPT_TIMER_THRESH=%0d", cmpt_timer_thresh))
        cmpt_timer_thresh = 32;
      if (cmpt_timer_test)
        `uvm_info("qdma_base_test", $sformatf(
          "CMPT_TIMER_TEST: trig_mode=WRB_TRIG_USER_TIMER, timer_idx=%0d, threshold=%0d",
          cmpt_timer_idx, cmpt_timer_thresh), UVM_MEDIUM)

      // Parse +ENABLE_QDMA_MON=0/1 plusarg (default 1 = enabled).
      if (!$value$plusargs("ENABLE_QDMA_MON=%d", enable_qdma_mon))
        enable_qdma_mon = 1;
      if (!enable_qdma_mon)
        `uvm_info("qdma_base_test",
          "ENABLE_QDMA_MON=0: all passive monitor agents DISABLED", UVM_MEDIUM)

      if (enable_qdma_mon) begin


      // --- AXI-PL performance monitor (PL0, PL1, PL3) ---
      // bind_axi_pl (bound to design_1) registers vif_axi_pl0/1/3 in the
      // global config_db.  cpm_axi_pl_vnc_env retrieves them in its own
      // build_phase.  The env is purely passive: it drives nothing on the
      // AXI-PL ports.  Performance metrics (bandwidth, latency, protocol
      // violations) are written to reports/ at the end of simulation.
      begin
        virtual axi_if vif_pl0, vif_pl1, vif_pl3;
        if (uvm_config_db#(virtual axi_if)::get(null, "*", "vif_axi_pl0", vif_pl0))
          uvm_config_db#(virtual axi_if)::set(this, "axi_pl_env", "vif_axi_pl0", vif_pl0);
        else
          `uvm_warning("qdma_base_test",
            "vif_axi_pl0 not found  - bind.axi_pl.sv may not have run yet")
        if (uvm_config_db#(virtual axi_if)::get(null, "*", "vif_axi_pl1", vif_pl1))
          uvm_config_db#(virtual axi_if)::set(this, "axi_pl_env", "vif_axi_pl1", vif_pl1);
        else
          `uvm_warning("qdma_base_test", "vif_axi_pl1 not found")
        if (uvm_config_db#(virtual axi_if)::get(null, "*", "vif_axi_pl3", vif_pl3))
          uvm_config_db#(virtual axi_if)::set(this, "axi_pl_env", "vif_axi_pl3", vif_pl3);
        else
          `uvm_warning("qdma_base_test", "vif_axi_pl3 not found")
        // log_fd for the axi_pl_protocol_monitor instances
        uvm_config_db#(int)::set(this, "axi_pl_env*", "log_fd", shared_log_fd);
        axi_pl_env = cpm_axi_pl_vnc_env::type_id::create("axi_pl_env", this);
      end

      // --- PS wizard NOC / DMA IRQ monitor ---
      // bind_pswizard (bound to design_1) registers "vif_pswizard" in config_db.
      // Monitors CPM_PCIE_AXI_NOC0, CPM_PCIE_AXI_NOC1 AXI handshakes and the
      // 128-bit DMA completion IRQ vector.
      begin
        virtual pswizard_if vif_psw;
        pswizard_cfg cfg_psw = pswizard_cfg::type_id::create("cfg_psw", this);
        uvm_config_db#(pswizard_cfg)::set(this, "psw_agnt*", "cfg", cfg_psw);
        uvm_config_db#(int)::set(this, "psw_agnt*", "log_fd", shared_log_fd);
        if (uvm_config_db#(virtual pswizard_if)::get(null, "*", "vif_pswizard", vif_psw))
          uvm_config_db#(virtual pswizard_if)::set(this, "psw_agnt", "vif", vif_psw);
        else
          `uvm_warning("qdma_base_test",
            "vif_pswizard not found  - bind.pswizard.sv may not have run")
        psw_agnt = pswizard_agent::type_id::create("psw_agnt", this);
      end


      // --- QDMA periphery monitor (s_axi_mem + s_axi_reg + m_axil_dbi + MSIX) ---
      // bind_qdma_periph (bound to design_1) registers "vif_qdma_periph" in config_db.
      // Monitors ALL external AXI interfaces at the cpm6_qdma boundary.
      // Key: MEM_W beat-level gap timing for completion arrival analysis.
      begin
        virtual qdma_periph_if vif_qper;
        virtual qdma_periph_tm_dsc_if vif_tm_dsc;
        qdma_periph_cfg cfg_qper = qdma_periph_cfg::type_id::create("cfg_qper", this);
        uvm_config_db#(qdma_periph_cfg)::set(this, "qdma_periph_agnt*", "cfg", cfg_qper);
        uvm_config_db#(int)::set(this, "qdma_periph_agnt*", "log_fd", shared_log_fd);
        if (uvm_config_db#(virtual qdma_periph_if)::get(null, "*", "vif_qdma_periph", vif_qper))
          uvm_config_db#(virtual qdma_periph_if)::set(this, "qdma_periph_agnt", "vif", vif_qper);
        else
          `uvm_warning("qdma_base_test",
            "vif_qdma_periph not found  -  bind.qdma_periph.sv may not have run")
        // Descriptor-status interface: optional, separate config_db key. The
        // periphery monitor's own get is non-fatal, so no warning is needed
        // here if it is absent.
        if (uvm_config_db#(virtual qdma_periph_tm_dsc_if)::get(null, "*", "vif_tm_dsc_sts", vif_tm_dsc))
          uvm_config_db#(virtual qdma_periph_tm_dsc_if)::set(this, "qdma_periph_agnt", "vif_tm", vif_tm_dsc);
        qdma_periph_agnt = qdma_periph_agent::type_id::create("qdma_periph_agnt", this);
      end

      // --- per-HDMA-channel status tracker ---
      uvm_config_db#(int)::set(this, "chan_status_tracker*", "log_fd", shared_log_fd);
      chan_status_tracker = dma_channel_status_tracker::type_id::create("chan_status_tracker", this);

      // --- QDMA user-side AXI4-Stream agent (H2C monitor + C2H driver) ---
      // bind_qdma_user_st registers "qdma_user_vif" in config_db.
      begin
        virtual qdma_user_if vif_user;
        bit user_vif_found;
        string vif_key;
        string agnt_name;

        user_vif_found = 0;
        uvm_config_db#(int)::set(this, "user_agnt*", "log_fd", shared_log_fd);

        for (int port = 0; port < 4; port++) begin
          vif_key = $sformatf("qdma_user_vif%0d", port);
          if (!uvm_config_db#(virtual qdma_user_if)::get(null, "*", vif_key, vif_user) &&
              (port == 0))
            void'(uvm_config_db#(virtual qdma_user_if)::get(null, "*", "qdma_user_vif", vif_user));

          if (vif_user != null) begin
            agnt_name = $sformatf("user_agnt%0d", port);
            uvm_config_db#(virtual qdma_user_if)::set(this, agnt_name, "qdma_user_vif", vif_user);
            uvm_config_db#(virtual qdma_user_if)::set(this, {agnt_name, ".mon"}, "vif", vif_user);
            // c2h_source_ctrl drives C2H data structurally from the wrapper;
            // user agent stays PASSIVE (monitor-only, no UVM driver needed).
            user_agnt[port] = qdma_user_agent::type_id::create(agnt_name, this);
            user_vif_found = 1;
          end
          vif_user = null;
        end

        if (!user_vif_found)
          `uvm_warning("qdma_base_test",
            "No qdma_user_vif[0:3] found  -  bind.qdma_user_st.sv may not have run")

        h2c_user_sub = h2c_user_subscriber::type_id::create("h2c_user_sub", this);
      end


      end // if (enable_qdma_mon)

      // --- DSC_CRDT descriptor credit agent (active, ST-only) ---
      // When +USE_DSC_CRDT=1, credits are sent via the PL-side dsc_crdt
      // interface instead of PIDX doorbell register writes.
      if (!$value$plusargs("USE_DSC_CRDT=%d", use_dsc_crdt))
         use_dsc_crdt = 0;

      // Streaming SW-context bypass bit, runtime-selectable so either mode can
      // be exercised without a source edit. Non-bypass is the default.
      if (!$value$plusargs("ST_DSC_BYPASS=%d", st_dsc_bypass))
         st_dsc_bypass = 0;
      // C2H-ST descriptor prefetch engine present (default 1). Each C2H-ST queue
      // then gets a valid prefetch context and fcrd_en=1, and its fetch credits
      // come from the engine rather than the test. C2H_PFCH_EN sets the
      // context's pfch_en: prefetch ahead on a queue's first packet.
      if (!$value$plusargs("C2H_PFCH=%d", c2h_pfch))
         c2h_pfch = 1;
      if (!$value$plusargs("C2H_PFCH_EN=%d", c2h_pfch_en))
         c2h_pfch_en = 1;
      // Stream queues post their descriptors the way the host driver does: the
      // SW context is written with PIDX 0, and the PIDX doorbell is rung after
      // the contexts and the completion CIDX. DRIVER_MODE=0 puts the PIDX in
      // the SW context instead and rings no doorbell.
      if (!$value$plusargs("DRIVER_MODE=%d", driver_mode))
         driver_mode = 1;
      `uvm_info("qdma_base_test",
                $sformatf("Stream descriptor posting: %s",
                          driver_mode ? "driver mode (PIDX doorbell)" : "PIDX in SW context"), UVM_LOW)
      `uvm_info("qdma_base_test",
                $sformatf("C2H-ST prefetch engine = %0d, pfch_en = %0d", c2h_pfch, c2h_pfch_en), UVM_LOW)
      `uvm_info("qdma_base_test",
                $sformatf("ST SW-context bypass bit = %0d", st_dsc_bypass), UVM_LOW)
`ifdef USE_DSC_CRDT
      if (use_dsc_crdt) begin
         virtual dsc_crdt_if vif_crdt;
         uvm_config_db#(int)::set(this, "dsc_crdt_agnt*", "log_fd", shared_log_fd);
         if (uvm_config_db#(virtual dsc_crdt_if)::get(null, "*", "vif_dsc_crdt", vif_crdt)) begin
            uvm_config_db#(virtual dsc_crdt_if)::set(this, "dsc_crdt_agnt", "vif", vif_crdt);
            uvm_config_db#(virtual dsc_crdt_if)::set(this, "dsc_crdt_agnt.mon", "vif", vif_crdt);
            uvm_config_db#(virtual dsc_crdt_if)::set(this, "dsc_crdt_agnt.drv", "vif", vif_crdt);
         end else
            `uvm_fatal("qdma_base_test",
               "vif_dsc_crdt not found  -  bind.dsc_crdt.sv may not have run")
         dsc_crdt_agnt = dsc_crdt_agent::type_id::create("dsc_crdt_agnt", this);
         `uvm_info("qdma_base_test",
            "USE_DSC_CRDT=1: descriptor credits via PL-side dsc_crdt interface", UVM_MEDIUM)
      end
`endif

    phase.drop_objection(this);
  endfunction


function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    dma_req_proc.dma_trfr_bus = dma_trfr_bus;
    // Give the scoreboard a live handle to this test so it can access
    // host_mem after MWR writes land during the C2H transfer
    dma_req_proc.test_ref = this;

    // Connect DBI/NOC0/PL0-1 events -> per-channel status tracker
    if (chan_status_tracker != null) begin
      if (qdma_periph_agnt != null) qdma_periph_agnt.ap.connect(chan_status_tracker.qper_imp);
      if (psw_agnt         != null) psw_agnt.ap.connect(chan_status_tracker.psw_imp);
    end


    // Connect H2C user-side data -> dma_req_processor (H2C data integrity)
    if (h2c_user_sub != null) begin
      h2c_user_sub.proc_ref = dma_req_proc;
      for (int port = 0; port < 4; port++) begin
        if (user_agnt[port] != null)
          user_agnt[port].ap.connect(h2c_user_sub.analysis_export);
      end
    end


endfunction

  virtual function void final_phase(uvm_phase phase);
    if (shared_log_fd != 0) begin
      $fdisplay(shared_log_fd, "# -----------------------------------------------");
      $fdisplay(shared_log_fd, "# Simulation ended at %0t", $time);
      $fclose(shared_log_fd);
      shared_log_fd = 0;
    end
  endfunction


// ---------------------------------------------------------------------------
// TSK_QDMA_DBG_DUMP: read the streaming words of the debug register bank
// (PF DMA BAR, 0x1000 bank) under DBG_CTRL.freeze, every PL port through the
// DBG_SEL window, and print them as "DBG_DUMP <name>[port] = value".
// DBG_CTRL is read-modify-written so only its freeze bit changes. The prefetch
// tag window is frozen with the rest, so each tag is selected before its own
// freeze. Requires a build with the debug bank enabled; the bank reads
// 0xBADACCE5 otherwise.
// ---------------------------------------------------------------------------
virtual task TSK_QDMA_DBG_DUMP(input int n_tags = 0);
    bit [31:0] rd, ctrl;
    bit [31:0] g_off [$]   = '{32'h109C, 32'h10A0, 32'h10A4, 32'h10C4, 32'h10CC, 32'h10D0, 32'h10D4,
                               32'h10D8, 32'h10DC, 32'h10E0, 32'h10E4, 32'h10E8, 32'h10EC, 32'h10F0, 32'h10F4};
    string     g_name [$]  = '{"DBG_SEL", "ISR_C2H_0", "ISR_C2H_1", "PFCH_POOL", "PFCH_STATE", "PFCH_ERR",
                               "PFCH_FIRST_ERR", "CMPT2_0", "CMPT2_1", "CMPT2_GATE", "CMPT2_DROPQID",
                               "CARB", "CRDT", "ST_MISC", "ST_EVER"};
    bit [31:0] p_off [$]   = '{32'h10A8, 32'h10AC, 32'h10B0, 32'h10B4, 32'h10B8, 32'h10BC, 32'h10C0};
    string     p_name [$]  = '{"ST_H2C_0", "ST_H2C_1", "ST_C2H_STS", "ST_C2H_FWD", "ST_C2H_DROP",
                               "ST_C2H_FIRSTDROP", "ST_PKTC"};
    issue_reg_read(PF_DMA_BAR_INDEX, 32'h1000, , , , ctrl);
    ctrl[1] = 1'b0;                                                 // never pulse cnt_clr
    issue_reg_write(PF_DMA_BAR_INDEX, 32'h1000, ctrl | 32'h1);       // freeze
    foreach (g_off[i]) begin
      issue_reg_read(PF_DMA_BAR_INDEX, g_off[i], , , , rd);
      `uvm_info("DBG_DUMP", $sformatf("%s = 0x%08h", g_name[i], rd), UVM_NONE)
    end
    for (int p = 0; p < 4; p++) begin
      issue_reg_write(PF_DMA_BAR_INDEX, 32'h109C, 32'(p));
      foreach (p_off[i]) begin
        issue_reg_read(PF_DMA_BAR_INDEX, p_off[i], , , , rd);
        `uvm_info("DBG_DUMP", $sformatf("%s[%0d] = 0x%08h", p_name[i], p, rd), UVM_NONE)
      end
    end
    issue_reg_write(PF_DMA_BAR_INDEX, 32'h1000, ctrl & ~32'h1);      // unfreeze
    for (int t = 0; t < n_tags; t++) begin
      issue_reg_write(PF_DMA_BAR_INDEX, 32'h109C, 32'(t) << 8);
      issue_reg_write(PF_DMA_BAR_INDEX, 32'h1000, ctrl | 32'h1);     // freeze this tag's window
      issue_reg_read(PF_DMA_BAR_INDEX, 32'h10C8, , , , rd);
      `uvm_info("DBG_DUMP", $sformatf("PFCH_TAG[%0d] = 0x%08h", t, rd), UVM_NONE)
      issue_reg_write(PF_DMA_BAR_INDEX, 32'h1000, ctrl & ~32'h1);
    end
    issue_reg_write(PF_DMA_BAR_INDEX, 32'h109C, 32'h0);
endtask

  //reg_offset -> Input --> Provide offset from base address of the BAR.
  //data --> Input --> Data to be written to the register
  //bar_num --> BAR to which the register is mapped to.
virtual task issue_reg_write(int  bar_num,
                       bit [31:0]  reg_offset,
                       bit [31:0] data,
             bit is_pf = 1'b1,
             bit [7:0] pfn = 8'h0,
             bit [7:0] vfn = 8'h0
                      );
      logic [63:0] addr;
      logic [31:0] data_arr[];
    data_arr = {data};

    if(is_pf) begin
        // Access PF BAR from pdev_ep.membar
        addr = pdev_ep.membar[bar_num].base;
      end else begin
        begin
          bit [63:0] vf0_base, bar_sz;
          if (!pdev_ep.sriov.vf_membar.exists(bar_num))
            `uvm_fatal("REG_WRITE", $sformatf("VF BAR[%0d] does not exist in sriov.vf_membar", bar_num))
          vf0_base = pdev_ep.sriov.vf_membar[bar_num].base;
          bar_sz   = pdev_ep.sriov.vf_membar[bar_num].sz;
          if ($isunknown(vf0_base[63:32]) || vf0_base[63:32] == 32'hFFFF_FFFF)
            vf0_base[63:32] = 32'h0;
          if ($isunknown(bar_sz[63:32]) || bar_sz[63:32] != 32'h0)
            bar_sz[63:32] = 32'h0;
          addr = vf0_base + 64'(vfn) * bar_sz;
        end
      end

    `uvm_info("reg_write", $sformatf("PCIe BAR:%d, PCIe BAR Addr: 0x%0h, reg_offset: 0x%0h, Reg Addr: 0x%0h, Data: 0x%0h, pfn: %d, vfn: %d",bar_num, addr, reg_offset, (addr + reg_offset),data, pfn, vfn), UVM_MEDIUM)
    // After a register-read completion timeout the host has lost the device:
    // no further register traffic (driver-sequence runs only).
    if (drv_mmio_dead) return;
    drv_trace("W", reg_offset, data, is_pf, vfn);

    // A1. Create a txn. A handle local to this call: register accesses run
    // from concurrent threads (per-port C2H burst threads), so a shared
    // handle would be overwritten by another access in flight.
      begin
        amd_mem_tlp tlp;
        tlp = amd_mem_tlp::type_id::create("tlp");
    // A2. Build the txn
      // A3. Send it (via a generic txn datapath)
      // Write 1 DW to BAR
        tlp.build_wr(addr + reg_offset, .data(data_arr));
        env.shim.api.send_mem(tlp);
      end
    // Host register traffic is DMA activity for the stall watchdogs.
    if (dma_req_proc != null) dma_req_proc.notify_mmio_activity();
endtask
  //reg_offset -> Input --> Provide offset from base address of the BAR.
  //data --> Output --> Data to be written to the register
  //bar_num --> Input  --> BAR to which the register is mapped to.
virtual task issue_reg_read(int bar_num,
                      bit [31:0] reg_offset,
            bit is_pf = 1'b1,
            bit [7:0] pfn = 8'h0,
            bit [7:0] vfn = 8'h0,
                      output bit [31:0] data
                      );
      logic [63:0] addr;
      int          len;

    if(is_pf) begin
        // Access PF BAR from pdev_ep.membar
        addr = pdev_ep.membar[bar_num].base;
      end else begin
        begin
          bit [63:0] vf0_base, bar_sz;
          if (!pdev_ep.sriov.vf_membar.exists(bar_num))
            `uvm_fatal("REG_READ", $sformatf("VF BAR[%0d] does not exist in sriov.vf_membar", bar_num))
          vf0_base = pdev_ep.sriov.vf_membar[bar_num].base;
          bar_sz   = pdev_ep.sriov.vf_membar[bar_num].sz;
          if ($isunknown(vf0_base[63:32]) || vf0_base[63:32] == 32'hFFFF_FFFF)
            vf0_base[63:32] = 32'h0;
          if ($isunknown(bar_sz[63:32]) || bar_sz[63:32] != 32'h0)
            bar_sz[63:32] = 32'h0;
          addr = vf0_base + 64'(vfn) * bar_sz;
        end
      end

    `uvm_info("reg_read", $sformatf("PCIe BAR:%d, PCIe BAR Addr: 0x%0h, reg_offset: 0x%0h, Reg Addr: 0x%0h, pfn: %d, vfn: %d",bar_num, addr, reg_offset, (addr + reg_offset), pfn, vfn), UVM_MEDIUM)

    // A1. Create a txn. A handle local to this call: a blocking read waits
    // for its completion, and a shared handle would be overwritten by an
    // access from another thread meanwhile (per-port C2H burst threads).
      begin
        amd_mem_tlp tlp;
        tlp = amd_mem_tlp::type_id::create("tlp");
    // A2. Build the txn
      // A3. Send it (via a generic txn datapath)

      // Read 1 DW from BAR. blocking(DONE) makes send_mem wait for the
      // completion (tr.wait_done) and write the payload back into tlp.data
      // (shim_api.sv: tlp.data = tr.payload under DONE). Without DONE the read
      // returns before the completion arrives and data is always 0.
        tlp.build_rd(addr + reg_offset, 1, .blocking(DONE));
        if (drv_mmio_dead) begin
          data = 32'hDEAD_DEAD;
          return;
        end
        // Driver-sequence runs: a read not completed within the budget is a
        // completion timeout -- the host would hang or see all ones, so the
        // run's register traffic stops there.
        if (drv_mmio_cto_ns == 0 && drv_mmio_cto_once == 0) begin
          env.shim.api.send_mem(tlp);
          data = tlp.data[0];
        end else begin
          bit done;
          int cto;
          cto = (drv_mmio_cto_once != 0) ? drv_mmio_cto_once : drv_mmio_cto_ns;
          drv_mmio_cto_once = 0;
          done = 1'b0;
          fork
            begin
              fork
                begin
                  env.shim.api.send_mem(tlp);
                  done = 1'b1;
                end
                #(cto * 1ns);
              join_any
              disable fork;
            end
          join
          if (done) data = tlp.data[0];
          else begin
            data          = 32'hDEAD_DEAD;
            drv_mmio_dead = 1'b1;
          end
          void'(dma_req_proc.drv_chk("DRV_MMIO_CTO", done, $sformatf(
            "register read %s BAR %0d + 0x%0h not completed within %0d ns -- the host sees a completion timeout; register traffic stops here",
            is_pf ? "PF" : $sformatf("VF%0d", vfn), bar_num, reg_offset, cto)));
        end
        drv_trace("R", reg_offset, data, is_pf, vfn);
      end
    // A completed register read is DMA activity for the stall watchdogs (a
    // read that hit the completion timeout set drv_mmio_dead and is not).
    if (dma_req_proc != null && !drv_mmio_dead) dma_req_proc.notify_mmio_activity();
    `uvm_info("reg_read", $sformatf("Read Data (data) : 0x%8h",data), UVM_MEDIUM)
endtask

// Poll QDMA indirect context command register (0x844) until BUSY bit[0] clears.
// Must be called after every issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, ...) to
// ensure the hardware has committed the context before the registers are reused.
task poll_ctxt_busy;
  bit [31:0] rd;
  int        tries;
  tries = 0;
  do begin
    issue_reg_read(PF_DMA_BAR_INDEX, 16'h844, , , , rd);
    tries++;
    if (tries > 1000)
      `uvm_fatal("poll_ctxt_busy", "CTXT_CMD BUSY bit never cleared after 1000 polls")
  end while (rd[0] === 1'b1);
  `uvm_info("poll_ctxt_busy", $sformatf("CTXT_CMD cleared after %0d poll(s)", tries), UVM_LOW)
endtask

task TSK_PRINT_QDMA_ENV();
begin
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** All Values are printed in HexaDecimal ***"), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** NUM_QIDS : 0x%0h ***", NUM_QIDS), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** NUM_PF : 0x%0h ***", NUM_PF), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** NUM_VF : 0x%0h ***", NUM_VF), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** NUM_CHN : 0x%0h ***", NUM_CHN), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** RING_SIZE : 0x%0h ***", RING_SIZE), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** H2C_DSC_ADDR : 0x%0h ***", H2C_DSC_ADDR), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** H2C DATA Buffer space Base address : 0x%0h ***", H2C_DAT_SRC_ADDR), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** H2C Data Buffer total size : 0x%0h ***", H2C_DAT_SIZE), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** NUM_DMA_PORTS : %0d (port = qid %% num_dma_ports) ***", num_dma_ports), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** C2H_DSC_ADDR : 0x%0h ***", C2H_DSC_ADDR), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** C2H Data Buffer total size : 0x%0h ***", C2H_DAT_SIZE), UVM_MEDIUM)
  if (DMA_ST == 1) begin
    `uvm_info("TSK_PRINT_QDMA_ENV", " **** ST mode: package H2C_DAT_DST_ADDR* constants are not used for H2C-ST descriptors ***", UVM_MEDIUM)
    `uvm_info("TSK_PRINT_QDMA_ENV", " **** ST mode: C2H source port selection comes from SW context port_id; package C2H_DAT_SRC_ADDR* constants are not used for H2C-ST routing ***", UVM_MEDIUM)
  end else begin
    `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** H2C_DAT_DST_ADDR0 : 0x%0h ***", H2C_DAT_DST_ADDR0), UVM_MEDIUM)
    `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** H2C_DAT_DST_ADDR1 : 0x%0h ***", H2C_DAT_DST_ADDR1), UVM_MEDIUM)
    `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** H2C_DAT_DST_ADDR2 : 0x%0h ***", H2C_DAT_DST_ADDR2), UVM_MEDIUM)
    `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** H2C_DAT_DST_ADDR3 : 0x%0h ***", H2C_DAT_DST_ADDR3), UVM_MEDIUM)
    `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** C2H_DAT_SRC_ADDR0 : 0x%0h ***", C2H_DAT_SRC_ADDR0), UVM_MEDIUM)
    `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** C2H_DAT_SRC_ADDR1 : 0x%0h ***", C2H_DAT_SRC_ADDR1), UVM_MEDIUM)
    `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** C2H_DAT_SRC_ADDR2 : 0x%0h ***", C2H_DAT_SRC_ADDR2), UVM_MEDIUM)
    `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** C2H_DAT_SRC_ADDR3 : 0x%0h ***", C2H_DAT_SRC_ADDR3), UVM_MEDIUM)
  end
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** PF_MB_MSIX_OFFSET : 0x%0h ***", PF_MB_MSIX_OFFSET), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** VF_MB_MSIX_OFFSET : 0x%0h ***", VF_MB_MSIX_OFFSET), UVM_MEDIUM)
  `uvm_info("TSK_PRINT_QDMA_ENV", $sformatf(" **** QUEUE_PER_VF : 0x%0h ***", QUEUE_PER_VF), UVM_MEDIUM)
end
endtask
/************************************************************
Task : TSK_INIT_QDMA_ST_DATA_H2C
Inputs : fnc, qid, dsc_base
Outputs : None
Description : Initialize H2C Streaming 16B Descriptors and Data
*************************************************************/

task TSK_INIT_QDMA_ST_DATA_H2C (input bit [7:0] fnc, input bit [10:0] qid, input bit [63:0] dsc_base);
  integer k;
  localparam ST_DSC_SZ = 16;
begin
  bit [63:0] HOST_DAT_BUF_ADDR;
  bit [31:0] h2c_st_fill_bytes;

  h2c_qid_dsc_sz[int'(qid)] = ST_DSC_SZ;

  HOST_DAT_BUF_ADDR = H2C_DAT_SRC_ADDR;
  HOST_DAT_BUF_ADDR[$clog2(DMA_BYTE_CNT)+:$bits(qid)] = qid;
  h2c_st_fill_bytes = (xfer_bytes != 0) ? xfer_bytes : DMA_BYTE_CNT;

  `uvm_info("H2C_ST", $sformatf(" **** TASK QDMA ST H2C DSC at address 0x%0h ***", dsc_base), UVM_MEDIUM)
  `uvm_info("H2C_ST", $sformatf(" **** HOST_DAT_BUF_ADDR : 0x%0h ***", HOST_DAT_BUF_ADDR), UVM_MEDIUM)
  `uvm_info("H2C_ST", $sformatf(" **** DMA_BYTE_CNT : 0x%0h ***", DMA_BYTE_CNT), UVM_MEDIUM)
  `uvm_info("H2C_ST", " **** Initialize ST Descriptor data ***", UVM_HIGH)
  `uvm_info("H2C_ST", $sformatf("pidx (Decimal value): %0d",pidx), UVM_MEDIUM)

  if (xfer_bytes != 0 && int'(pidx) != int'(xfer_num_desc()))
    `uvm_fatal("XFER_SG",
      $sformatf("TEST CONFIG CORRUPTED (ST H2C): pidx=%0d but +XFER_BYTES=%0d / +DESC_PAGE_BYTES=%0d requires %0d descriptors.",
                pidx, xfer_bytes, desc_page_bytes, xfer_num_desc()))

  // H2C-ST descriptor is 16 bytes:
  //   Byte [3:0]   = metadata[31:0]   -> 0 (unused)
  //   Byte [5:4]   = length[15:0]     -> per-descriptor length (see d_len below)
  //   Byte [7:6]   = rsvd[15:0]       -> 0
  //   Byte [11:8]  = addr_l[31:0]     -> source address [31:0]
  //   Byte [15:12] = addr_h[31:0]     -> source address [63:32]
  for (k=0;k<pidx;k=k+1) begin
    // Driver-accurate page split when xfer_bytes is set (advancing source
    // address, page-sized chunks, short final descriptor), otherwise the
    // same address, full DMA_BYTE_CNT in one descriptor.
    bit [63:0] d_addr;
    bit [31:0] d_len;
    if (xfer_bytes != 0) begin
      d_addr = HOST_DAT_BUF_ADDR + (k * desc_page_bytes);
      d_len  = xfer_desc_len(k);
    end else begin
      d_addr = HOST_DAT_BUF_ADDR;
      d_len  = DMA_BYTE_CNT;
    end
    host_mem[dsc_base+(k*ST_DSC_SZ)+0]  = 8'h00; // metadata[7:0]
    host_mem[dsc_base+(k*ST_DSC_SZ)+1]  = 8'h00; // metadata[15:8]
    host_mem[dsc_base+(k*ST_DSC_SZ)+2]  = 8'h00; // metadata[23:16]
    host_mem[dsc_base+(k*ST_DSC_SZ)+3]  = 8'h00; // metadata[31:24]
    host_mem[dsc_base+(k*ST_DSC_SZ)+4]  = d_len[7:0];  // length[7:0]
    host_mem[dsc_base+(k*ST_DSC_SZ)+5]  = d_len[15:8]; // length[15:8]
    host_mem[dsc_base+(k*ST_DSC_SZ)+6]  = 8'h00; // rsvd[7:0]
    host_mem[dsc_base+(k*ST_DSC_SZ)+7]  = 8'h00; // rsvd[15:8]
    host_mem[dsc_base+(k*ST_DSC_SZ)+8]  = d_addr[7:0];   // addr_l[7:0]
    host_mem[dsc_base+(k*ST_DSC_SZ)+9]  = d_addr[15:8];  // addr_l[15:8]
    host_mem[dsc_base+(k*ST_DSC_SZ)+10] = d_addr[23:16]; // addr_l[23:16]
    host_mem[dsc_base+(k*ST_DSC_SZ)+11] = d_addr[31:24]; // addr_l[31:24]
    host_mem[dsc_base+(k*ST_DSC_SZ)+12] = d_addr[39:32]; // addr_h[7:0]
    host_mem[dsc_base+(k*ST_DSC_SZ)+13] = d_addr[47:40]; // addr_h[15:8]
    host_mem[dsc_base+(k*ST_DSC_SZ)+14] = d_addr[55:48]; // addr_h[23:16]
    host_mem[dsc_base+(k*ST_DSC_SZ)+15] = d_addr[63:56]; // addr_h[31:24]
  end

  // Initialize Status write back location to 0's -- the last slot is the
  // final ST_DSC_SZ-sized chunk of the ring's fixed ring_entries*QDMA_DSC_SZ
  // byte window, not ST_DSC_SZ*(ring_entries-1).
  host_mem[dsc_base + (longint'(ring_entries)*QDMA_DSC_SZ - ST_DSC_SZ) +0] = 8'h00;
  host_mem[dsc_base + (longint'(ring_entries)*QDMA_DSC_SZ - ST_DSC_SZ) +1] = 8'h00;
  host_mem[dsc_base + (longint'(ring_entries)*QDMA_DSC_SZ - ST_DSC_SZ) +2] = 8'h00;
  host_mem[dsc_base + (longint'(ring_entries)*QDMA_DSC_SZ - ST_DSC_SZ) +3] = 8'h00;

  for (k = 0; k < ST_DSC_SZ; k = k + 1)  begin
    `uvm_info("H2C_ST", $sformatf(" **** Descriptor data *** data = 0x%0h, addr= 0x%0h", host_mem[dsc_base+k], dsc_base+k), UVM_HIGH)
    #(Tcq);
  end

  // Initialize source data buffer with recognizable pattern
  host_mem[HOST_DAT_BUF_ADDR+0]  = HOST_DAT_BUF_ADDR[7:0];
  host_mem[HOST_DAT_BUF_ADDR+1]  = HOST_DAT_BUF_ADDR[15:8];
  host_mem[HOST_DAT_BUF_ADDR+2]  = HOST_DAT_BUF_ADDR[23:16];
  host_mem[HOST_DAT_BUF_ADDR+3]  = HOST_DAT_BUF_ADDR[31:24];
  host_mem[HOST_DAT_BUF_ADDR+4]  = HOST_DAT_BUF_ADDR[39:32];
  host_mem[HOST_DAT_BUF_ADDR+5]  = HOST_DAT_BUF_ADDR[47:40];
  host_mem[HOST_DAT_BUF_ADDR+6]  = HOST_DAT_BUF_ADDR[55:48];
  host_mem[HOST_DAT_BUF_ADDR+7]  = HOST_DAT_BUF_ADDR[63:56];
  host_mem[HOST_DAT_BUF_ADDR+8]  = DMA_BYTE_CNT[7:0];
  host_mem[HOST_DAT_BUF_ADDR+9]  = DMA_BYTE_CNT[15:8];
  host_mem[HOST_DAT_BUF_ADDR+10] = DMA_BYTE_CNT[23:16];
  host_mem[HOST_DAT_BUF_ADDR+11] = qid[7:0];
  host_mem[HOST_DAT_BUF_ADDR+12] = {'0,qid[10:8]};

  // h2c_st_fill_bytes, not DMA_BYTE_CNT alone -- in +XFER_BYTES mode the split
  // descriptors above read contiguously across the whole logical transfer,
  // starting at HOST_DAT_BUF_ADDR (descriptor k's advancing address is
  // HOST_DAT_BUF_ADDR + k*desc_page_bytes), so the fill must cover that same
  // full range.
  for (k = 13; k < h2c_st_fill_bytes; k = k + 1)  begin
    #(Tcq) host_mem[HOST_DAT_BUF_ADDR+k] = k;
  end
 end
endtask

/************************************************************
Task : TSK_C2H_SRC_CFG_WR
Inputs : off (byte offset in the block), data
Outputs : rd (value read back)
Description : Write one example-design C2H source configuration register
  through PF BAR2 and read it back. The read is non-posted and travels the
  same path as the posted write, so its completion means the write has
  landed. Required before the C2H context commit: the commit goes to the DMA
  register path, which is not ordered with the configuration path.
*************************************************************/
task TSK_C2H_SRC_CFG_WR (input bit [31:0] off, input bit [31:0] data, output bit [31:0] rd);
  begin
    issue_reg_write(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + off, data);
    issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + off, , , , rd);
  end
endtask

/************************************************************
Task : TSK_C2H_SRC_CFG_SET
Inputs : port (C2H source port 0..3), pkt_bytes
Outputs : None
Description : Program the C2H packet size of one example-design C2H source
  port and check that it took effect: PKT_BYTES and PKT_INFO
  ({descriptors, beats}) read back as written and STATUS reports no reject.
  A packet needing more descriptors than MAX_DSC raises MAX_DSC first. The
  DMA hand-out drops packets needing more than 7 descriptors, so a larger
  size is only allowed with +C2H_EXPECT_PFCH_DROP.
*************************************************************/
task TSK_C2H_SRC_CFG_SET (input int unsigned port, input int unsigned pkt_bytes);
  bit [31:0]   rd, exp_info;
  int unsigned dpp, beats;
  begin
    dpp   = (pkt_bytes + C2H_SRC_BUF_BYTES - 1) / C2H_SRC_BUF_BYTES;
    beats = pkt_bytes / 64;
    if (port >= C2H_SRC_NUM_PORTS)
      `uvm_fatal("C2H_SRC_CFG", $sformatf("port %0d has no C2H source (ports 0..%0d)", port, C2H_SRC_NUM_PORTS - 1))
    if (pkt_bytes == 0 || pkt_bytes > 16'hFFFF || (pkt_bytes % 64) != 0 || dpp > 15)
      `uvm_fatal("C2H_SRC_CFG", $sformatf(
        "C2H packet size %0d B is not programmable: a non-zero multiple of 64 B, at most 15 buffers of %0d B",
        pkt_bytes, C2H_SRC_BUF_BYTES))
    if (dpp > C2H_SRC_RST_MAX_DSC && !$test$plusargs("C2H_EXPECT_PFCH_DROP"))
      `uvm_fatal("C2H_SRC_CFG", $sformatf(
        "C2H packet size %0d B needs %0d descriptors; the DMA drops packets needing more than %0d. Add +C2H_EXPECT_PFCH_DROP for a drop test.",
        pkt_bytes, dpp, C2H_SRC_RST_MAX_DSC))

    TSK_C2H_SRC_CHECK_ID();

    // PKT_BYTES writes are checked against MAX_DSC, so raise it first.
    if (dpp > c2h_src_max_dsc_q) begin
      TSK_C2H_SRC_CFG_WR(C2H_SRC_A_MAX_DSC, 32'(dpp), rd);
      if (rd !== 32'(dpp))
        `uvm_error("C2H_SRC_CFG", $sformatf("MAX_DSC write %0d read back %0d", dpp, rd))
      c2h_src_max_dsc_q = dpp;
    end

    TSK_C2H_SRC_CFG_WR(c2h_src_a_len(port), 32'(pkt_bytes), rd);
    if (rd !== 32'(pkt_bytes))
      `uvm_error("C2H_SRC_CFG", $sformatf("port %0d PKT_BYTES write %0d read back %0d", port, pkt_bytes, rd))
    exp_info = {12'd0, 4'(dpp), 6'd0, 10'(beats)};
    issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + c2h_src_a_info(port), , , , rd);
    if (rd !== exp_info)
      `uvm_error("C2H_SRC_CFG", $sformatf("port %0d PKT_INFO 0x%08h, expected 0x%08h (%0d descriptors, %0d beats)",
                                          port, rd, exp_info, dpp, beats))
    issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + C2H_SRC_A_STATUS, , , , rd);
    if (rd[0])
      `uvm_error("C2H_SRC_CFG", $sformatf("STATUS 0x%08h: write rejected, code %0d at word %0d, data 0x%04h",
                                          rd, rd[7:4], rd[15:8], rd[31:16]))
    c2h_src_pkt_bytes_q[port] = pkt_bytes;
    `uvm_info("C2H_SRC_CFG", $sformatf("port %0d: C2H packet %0d B = %0d beats, %0d descriptors (PKT_INFO 0x%08h)",
                                       port, pkt_bytes, beats, dpp, exp_info), UVM_NONE)
  end
endtask

/************************************************************
Task : TSK_C2H_SRC_CFG_NEG
Inputs : port
Outputs : None
Description : Reject checks on the C2H source configuration block. Each
  illegal write must leave the register unchanged and record the reason in
  STATUS ({data[15:0], word offset, code, ERR}); STATUS is cleared by
  writing 1 to bit 0. Partial-strobe writes (code 5) cannot be issued from
  here.
*************************************************************/
task TSK_C2H_SRC_CFG_NEG (input int unsigned port);
  bit [31:0]   rd, cur, cur_max;
  bit [31:0]   bad   [4];
  bit [31:0]   offs  [4];
  bit [3:0]    code  [4];
  begin
    issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + c2h_src_a_len(port), , , , cur);
    issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + C2H_SRC_A_MAX_DSC, , , , cur_max);
    offs[0] = c2h_src_a_len(port); bad[0] = 32'd0;                                         code[0] = 4'd1;
    offs[1] = c2h_src_a_len(port); bad[1] = 32'd100;                                       code[1] = 4'd2;
    offs[2] = c2h_src_a_len(port); bad[2] = cur_max * C2H_SRC_BUF_BYTES + 64;              code[2] = 4'd3;
    offs[3] = C2H_SRC_A_MAX_DSC;   bad[3] = 32'd16;                                        code[3] = 4'd4;
    for (int i = 0; i < 4; i++) begin
      bit [31:0] exp_sts, before_val;
      issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + offs[i], , , , before_val);
      TSK_C2H_SRC_CFG_WR(offs[i], bad[i], rd);
      exp_sts = {bad[i][15:0], 8'(offs[i] >> 2), code[i], 3'd0, 1'b1};
      if (rd !== before_val)
        `uvm_error("C2H_SRC_CFG", $sformatf("reject check %0d: offset 0x%02h changed 0x%0h -> 0x%0h on an illegal write of 0x%0h",
                                            i, offs[i], before_val, rd, bad[i]))
      issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + C2H_SRC_A_STATUS, , , , rd);
      if (rd !== exp_sts)
        `uvm_error("C2H_SRC_CFG", $sformatf("reject check %0d: STATUS 0x%08h, expected 0x%08h", i, rd, exp_sts))
      else
        `uvm_info("C2H_SRC_CFG", $sformatf("reject check %0d: write 0x%0h to offset 0x%02h rejected with code %0d",
                                           i, bad[i], offs[i], code[i]), UVM_NONE)
      TSK_C2H_SRC_CFG_WR(C2H_SRC_A_STATUS, 32'h1, rd);
      if (rd !== 32'h0)
        `uvm_error("C2H_SRC_CFG", $sformatf("reject check %0d: STATUS 0x%08h after clear", i, rd))
    end
  end
endtask

/************************************************************
Task : TSK_C2H_SRC_CFG
Inputs : port_id
Outputs : None
Description : Bring one C2H source port to the test's C2H packet size before
  its queue is started. The block is not touched when the port already
  generates that size, unless +C2H_SRC_CFG_CHK (always write and check) or
  +C2H_SRC_CFG_NEG (reject checks, once per run) is given.
*************************************************************/
task TSK_C2H_SRC_CFG (input bit [2:0] port_id);
  int unsigned want, cur;
  begin
    TSK_C2H_SRC_SCHED_INIT();
    // The port's burst thread may be running a burst: size writes are
    // rejected while the port is busy, so take the port and wait for idle.
    c2h_src_port_lock[int'(port_id)].get(1);
    TSK_C2H_SRC_WAIT_IDLE(int'(port_id));
    want = c2h_eff_pkt_bytes();
    cur  = c2h_src_pkt_bytes_q.exists(int'(port_id)) ? c2h_src_pkt_bytes_q[int'(port_id)] : C2H_SRC_RST_PKT_BYTES;
    if ($test$plusargs("C2H_SRC_CFG_NEG") && !c2h_src_neg_done) begin
      TSK_C2H_SRC_CFG_SET(int'(port_id), cur);
      TSK_C2H_SRC_CFG_NEG(int'(port_id));
      c2h_src_neg_done = 1'b1;
    end
    if (want != cur || $test$plusargs("C2H_SRC_CFG_CHK"))
      TSK_C2H_SRC_CFG_SET(int'(port_id), want);
    c2h_src_port_lock[int'(port_id)].put(1);
  end
endtask

/************************************************************
Task : TSK_C2H_SRC_CHECK_ID
Inputs : None
Outputs : None
Description : Check once that the example-design C2H source configuration
  block is present (ID) and is the register-driven generator (VERSION): an
  older generator ignores QID / NUM_PKT / CONTROL and would leave every
  C2H test without packets, or run them from the PIDX doorbell instead.
*************************************************************/
task TSK_C2H_SRC_CHECK_ID();
  bit [31:0] rd;
  begin
    if (!c2h_src_cfg_seen) begin
      issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + C2H_SRC_A_ID, , , , rd);
      if (rd !== C2H_SRC_CFG_ID)
        `uvm_fatal("C2H_SRC_CFG", $sformatf(
          "C2H source configuration block not found: PF BAR2 + 0x%0h reads 0x%08h, expected ID 0x%08h. The design has no AXI-PL3 configuration branch behind BAR2.",
          C2H_SRC_CFG_OFF + C2H_SRC_A_ID, rd, C2H_SRC_CFG_ID))
      issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + C2H_SRC_A_VERSION, , , , rd);
      if (rd !== C2H_SRC_CFG_VERSION)
        `uvm_fatal("C2H_SRC_CFG", $sformatf(
          "C2H source VERSION 0x%08h, expected 0x%08h: the design does not have the register-driven C2H generator (QID / NUM_PKT / START)",
          rd, C2H_SRC_CFG_VERSION))
      c2h_src_cfg_seen = 1'b1;
    end
  end
endtask

/************************************************************
Task : TSK_C2H_SRC_SCHED_INIT
Inputs : None
Outputs : None
Description : Set up the C2H burst machinery once per run: the per-port
  locks and the count of descriptors posted per queue, taken from the DMA's
  C2H descriptor-status events (published by bind.c2h_src.sv as
  vif_c2h_tm_dsc_sts). Called before any C2H queue is set up, so no
  descriptor-status event of a C2H queue is missed.
*************************************************************/
task TSK_C2H_SRC_SCHED_INIT();
  begin
    if (!c2h_src_sched_up) begin
      c2h_src_sched_up = 1'b1;
      void'($value$plusargs("C2H_SRC_BARRIER_NS=%d", c2h_src_barrier_ns));
      void'($value$plusargs("C2H_SRC_IDLE_NS=%d", c2h_src_idle_ns));
      foreach (c2h_src_port_lock[p]) c2h_src_port_lock[p] = new(1);
      if (!uvm_config_db#(virtual qdma_periph_tm_dsc_if)::get(null, "", "vif_c2h_tm_dsc_sts", c2h_src_tm_vif))
        `uvm_error("C2H_SRC_BARRIER",
          "vif_c2h_tm_dsc_sts not found (bind.c2h_src.sv, C2H_SRC_MON=1): descriptor-status events cannot be counted, so C2H bursts start without the doorbell-to-START barrier")
      else
        fork
          forever begin
            @(posedge c2h_src_tm_vif.clk);
            if (c2h_src_tm_vif.rst_n && c2h_src_tm_vif.tm_dsc_sts_vld &&
                c2h_src_tm_vif.tm_dsc_sts_dir && c2h_src_tm_vif.tm_dsc_sts_qen) begin
              bit [10:0] q;
              q = c2h_src_tm_vif.tm_dsc_sts_qid[10:0];
              if (!c2h_src_dsc_posted.exists(q)) c2h_src_dsc_posted[q] = 0;
              c2h_src_dsc_posted[q] += longint'(c2h_src_tm_vif.tm_dsc_sts_avl);
            end
          end
        join_none
    end
  end
endtask

/************************************************************
Task : TSK_C2H_SRC_WAIT_IDLE
Inputs : port
Outputs : None
Description : Wait until the port's C2H generator is idle (CONTROL.BUSY 0),
  at most +C2H_SRC_IDLE_NS; a port still busy then is an error with the
  CONTROL value (packets left in [31:16]).
*************************************************************/
task automatic TSK_C2H_SRC_WAIT_IDLE(input int port);
  bit [31:0] rd;
  time       t0;
  begin
    t0 = $time;
    issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + c2h_src_a_status(port), , , , rd);
    while (rd[0] && ($time - t0) < c2h_src_idle_ns * 1ns) begin
      #500ns;
      issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + c2h_src_a_status(port), , , , rd);
    end
    if (rd[0])
      `uvm_error("C2H_SRC_BUSY", $sformatf(
        "port %0d C2H generator still busy after %0d ns: CONTROL 0x%08h, %0d packets of the burst not started",
        port, c2h_src_idle_ns, rd, rd[31:16]))
  end
endtask

/************************************************************
Task : TSK_C2H_SRC_START_BURST
Inputs : port, qid (absolute queue id), n_pkt, pkt_bytes, no_barrier
Outputs : seq (burst sequence number on the port; 0 when n_pkt is 0)
Description : Start one burst of the example-design C2H generator: n_pkt
  packets of pkt_bytes to queue qid on C2H port `port`, the way software
  does it after posting descriptors:
  - wait until the port is idle and set the packet size if it differs
  - doorbell-to-START barrier: wait until the queue has n_pkt x
    descriptors-per-packet posted descriptors that no earlier burst has used
    (descriptor-status events), at most +C2H_SRC_BARRIER_NS (an error when
    it runs out: the packets beyond the posted descriptors would be dropped)
  - write QID and NUM_PKT, read both back, write START, check STATUS and
    BURST_SEQ
  Returns once the burst has started; the next burst on the port waits for
  this one to end.
*************************************************************/
task automatic TSK_C2H_SRC_START_BURST(input int port, input bit [10:0] qid, input int n_pkt,
                                        input int pkt_bytes, output int seq, input bit no_barrier = 1'b0);
  bit [31:0] rd;
  longint    need, avail;
  int        dpp;
  time       t0;
  begin
    TSK_C2H_SRC_SCHED_INIT();
    TSK_C2H_SRC_CHECK_ID();
    seq   = 0;
    avail = -1;   // -1: not counted (no descriptor-status interface, or no barrier)
    dpp   = (pkt_bytes + C2H_SRC_BUF_BYTES - 1) / C2H_SRC_BUF_BYTES;
    need  = longint'(n_pkt) * dpp;
    c2h_src_port_lock[port].get(1);
    TSK_C2H_SRC_WAIT_IDLE(port);
    if ((c2h_src_pkt_bytes_q.exists(port) ? c2h_src_pkt_bytes_q[port] : C2H_SRC_RST_PKT_BYTES) != pkt_bytes)
      TSK_C2H_SRC_CFG_SET(port, pkt_bytes);

    if (c2h_src_tm_vif != null && !no_barrier) begin
      if (!c2h_src_dsc_posted.exists(qid))    c2h_src_dsc_posted[qid]    = 0;
      if (!c2h_src_dsc_committed.exists(qid)) c2h_src_dsc_committed[qid] = 0;
      t0 = $time;
      while ((c2h_src_dsc_posted[qid] - c2h_src_dsc_committed[qid]) < need &&
             ($time - t0) < c2h_src_barrier_ns * 1ns)
        #100ns;
      avail = c2h_src_dsc_posted[qid] - c2h_src_dsc_committed[qid];
      if (avail < need)
        `uvm_error("C2H_SRC_BARRIER", $sformatf(
          "port %0d qid %0d: burst needs %0d descriptors, %0d posted and not used by earlier bursts after %0d ns; starting anyway (packets beyond the posted descriptors are dropped by the DMA)",
          port, qid, need, avail, c2h_src_barrier_ns))
      c2h_src_dsc_committed[qid] += need;
    end
    if (!c2h_src_dsc_committed.exists(qid)) c2h_src_dsc_committed[qid] = 0;
    if (no_barrier) c2h_src_dsc_committed[qid] += need;

    TSK_C2H_SRC_CFG_WR(c2h_src_a_qid(port), 32'(qid), rd);
    if (rd !== 32'(qid))
      `uvm_error("C2H_SRC_CFG", $sformatf("port %0d QID write %0d read back 0x%08h", port, qid, rd))
    TSK_C2H_SRC_CFG_WR(c2h_src_a_num(port), 32'(n_pkt), rd);
    if (rd !== 32'(n_pkt))
      `uvm_error("C2H_SRC_CFG", $sformatf("port %0d NUM_PKT write %0d read back 0x%08h", port, n_pkt, rd))
    issue_reg_write(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + c2h_src_a_start(port), c2h_src_start_bit(port));
    issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + C2H_SRC_A_STATUS, , , , rd);
    if (rd[0]) begin
      `uvm_error("C2H_SRC_CFG", $sformatf(
        "port %0d qid %0d START: STATUS 0x%08h, write rejected (code %0d at word %0d) -- the burst may not have run",
        port, qid, rd, rd[7:4], rd[15:8]))
      TSK_C2H_SRC_CFG_WR(C2H_SRC_A_STATUS, 32'h1, rd);
    end
    if (n_pkt != 0) begin
      c2h_src_burst_seq[port]++;
      seq = c2h_src_burst_seq[port];
      c2h_src_pkts_started[port] += n_pkt;
      // The burst's data carries this sequence in seed bits [47:32].
      dma_req_proc.set_c2h_expected_burst(11'(qid), 16'(seq));
      issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + c2h_src_a_seq(port), , , , rd);
      if (rd[15:0] !== 16'(seq))
        `uvm_error("C2H_SRC_CFG", $sformatf("port %0d BURST_SEQ %0d after START, expected %0d", port, rd[15:0], seq))
    end
    `uvm_info("C2H_SRC_BURST", $sformatf(
      "port %0d qid %0d: START %0d packets of %0d B (burst %0d, needs %0d descriptors, %0d posted and unused at START%s)",
      port, qid, n_pkt, pkt_bytes, seq, need, avail, no_barrier ? ", no barrier" : ""), UVM_NONE)
    c2h_src_port_lock[port].put(1);
  end
endtask

/************************************************************
Task : TSK_C2H_SRC_BURST
Inputs : port, qid (absolute), n_pkt, pkt_bytes
Outputs : None
Description : Request a C2H burst without waiting for it: the burst starts
  in its own thread (TSK_C2H_SRC_START_BURST), so queues on different ports
  run concurrently and the caller can go on to set up the next queue.
*************************************************************/
task automatic TSK_C2H_SRC_BURST(input int port, input bit [10:0] qid, input int n_pkt, input int pkt_bytes);
  begin
    c2h_src_bursts_pending++;
    fork
      begin
        int seq;
        TSK_C2H_SRC_START_BURST(port, qid, n_pkt, pkt_bytes, seq);
        c2h_src_bursts_pending--;
      end
    join_none
  end
endtask

/************************************************************
Task : TSK_C2H_SRC_JOIN
Inputs : None
Outputs : None
Description : End of a C2H run: wait until every requested burst has
  started and every port is idle, then check that each port's PKT_CNT equals
  the packets the bursts asked for -- a generator that started packets on
  its own (e.g. from the PIDX doorbell) or missed a START shows here.
*************************************************************/
task TSK_C2H_SRC_JOIN();
  bit [31:0] rd;
  time       t0;
  begin
    if (c2h_src_sched_up) begin
      t0 = $time;
      while (c2h_src_bursts_pending > 0 && ($time - t0) < c2h_src_idle_ns * 1ns)
        #1us;
      if (c2h_src_bursts_pending > 0)
        `uvm_error("C2H_SRC_BURST", $sformatf("%0d C2H bursts never started after %0d ns", c2h_src_bursts_pending, c2h_src_idle_ns))
      for (int p = 0; p < C2H_SRC_NUM_PORTS; p++) begin
        TSK_C2H_SRC_WAIT_IDLE(p);
        issue_reg_read(PF_USR_BAR_INDEX, C2H_SRC_CFG_OFF + c2h_src_a_pkt_cnt(p), , , , rd);
        if (longint'(rd) != c2h_src_pkts_started[p])
          `uvm_error("C2H_SRC_PKT_CNT", $sformatf(
            "port %0d PKT_CNT %0d, bursts asked for %0d packets (%0d bursts)", p, rd, c2h_src_pkts_started[p], c2h_src_burst_seq[p]))
        else if (rd != 0)
          `uvm_info("C2H_SRC_PKT_CNT", $sformatf(
            "port %0d PKT_CNT %0d = packets of %0d bursts", p, rd, c2h_src_burst_seq[p]), UVM_NONE)
      end
    end
  end
endtask

/************************************************************
Task : TSK_INIT_QDMA_ST_DATA_C2H
Inputs : fnc, qid, dsc_base
Outputs : None
Description : Initialize C2H Streaming 8B Descriptors.
              Sets up host memory destination buffer and 8B C2H-ST
              descriptors carrying destination addresses in host memory.
*************************************************************/

task TSK_INIT_QDMA_ST_DATA_C2H (input bit [7:0] fnc, input bit [10:0] qid, input bit [63:0] dsc_base);
  integer k;
  int unsigned c2h_bytes, c2h_dpp, c2h_ndsc;
  bit [63:0]   c2h_dst;
  // Non-bypass C2H stream descriptors are 8 bytes. For this direction the size
  // is fixed by specification rather than chosen by software, and it must match
  // the dsc_sz field programmed into the queue's SW context.
  localparam ST_DSC_SZ = 8;
begin

  // Count descriptor-status events from here on, before the queue posts any
  // descriptors (doorbell-to-START barrier of the C2H bursts).
  TSK_C2H_SRC_SCHED_INIT();
  c2h_qid_dsc_sz[int'(qid)] = ST_DSC_SZ;
  c2h_qid_dsc_base[int'(qid)] = dsc_base;

  // One C2H packet per +PIDX; a packet longer than one C2H buffer takes
  // c2h_dpp descriptors, so the ring carries PIDX x c2h_dpp descriptors.
  c2h_bytes = c2h_eff_pkt_bytes();
  c2h_dpp   = c2h_dsc_per_pkt();
  c2h_ndsc  = int'(c2h_ring_pidx());
  if (c2h_ndsc > int'(ring_usable()))
    `uvm_fatal("C2H_ST", $sformatf(
      "qid=%0d: %0d packets x %0d descriptors = %0d descriptors exceed the %0d usable ring entries",
      qid, pidx, c2h_dpp, c2h_ndsc, ring_usable()))

  C2H_DAT_DST_ADDR[c2h_qid_shift()+:$bits(qid)] = qid;
  // A window past CMPT_RING_BASE overwrites the completion rings. Fatal for
  // a +C2H_PKT_BYTES run; a warning otherwise.
  if (C2H_DAT_DST_ADDR + c2h_bytes > CMPT_RING_BASE) begin
    if (c2h_pkt_bytes != 0)
      `uvm_fatal("C2H_ST", $sformatf(
        "qid=%0d: C2H destination 0x%0h + %0d B runs into the completion rings at 0x%0h; use fewer or lower queues or a smaller C2H packet",
        qid, C2H_DAT_DST_ADDR, c2h_bytes, CMPT_RING_BASE))
    else
      `uvm_warning("C2H_ST", $sformatf(
        "qid=%0d: C2H destination 0x%0h + %0d B runs into the completion rings at 0x%0h",
        qid, C2H_DAT_DST_ADDR, c2h_bytes, CMPT_RING_BASE))
  end

  `uvm_info("C2H_ST", $sformatf(" **** TASK QDMA ST C2H DSC at address 0x%0h ***", dsc_base), UVM_MEDIUM)
  `uvm_info("C2H_ST", $sformatf(" **** C2H_DAT_DST_ADDR : 0x%0h ***", C2H_DAT_DST_ADDR), UVM_MEDIUM)
  `uvm_info("C2H_ST", $sformatf(" **** DMA_BYTE_CNT : 0x%0h ***", DMA_BYTE_CNT), UVM_MEDIUM)
  `uvm_info("C2H_ST", " **** Initialize ST C2H Descriptor data ***", UVM_HIGH)
  `uvm_info("C2H_ST", $sformatf("pidx (Decimal value): %0d",pidx), UVM_MEDIUM)
  `uvm_info("C2H_ST", $sformatf("C2H packet %0d B, %0d descriptors per packet, ring pidx %0d",
                                c2h_bytes, c2h_dpp, c2h_ndsc), UVM_MEDIUM)

  // C2H-ST descriptor is 8 bytes -- destination address only:
  //   Byte [7:0] = dst_addr[63:0] -> C2H_DAT_DST_ADDR (host memory destination)
  // There is no length field in this format. The transfer length is carried by
  // the C2H packet, so the packet size is set by the C2H data source rather
  // than by the descriptor. Descriptor j of a packet points at buffer j of one
  // contiguous window, so every packet lands at C2H_DAT_DST_ADDR in order.
  for (k=0;k<c2h_ndsc;k=k+1) begin
    c2h_dst = C2H_DAT_DST_ADDR + (k % c2h_dpp) * C2H_SRC_BUF_BYTES;
    host_mem[dsc_base+(k*ST_DSC_SZ)+0]  = c2h_dst[7:0];   // dst_addr[7:0]
    host_mem[dsc_base+(k*ST_DSC_SZ)+1]  = c2h_dst[15:8];  // dst_addr[15:8]
    host_mem[dsc_base+(k*ST_DSC_SZ)+2]  = c2h_dst[23:16]; // dst_addr[23:16]
    host_mem[dsc_base+(k*ST_DSC_SZ)+3]  = c2h_dst[31:24]; // dst_addr[31:24]
    host_mem[dsc_base+(k*ST_DSC_SZ)+4]  = c2h_dst[39:32]; // dst_addr[39:32]
    host_mem[dsc_base+(k*ST_DSC_SZ)+5]  = c2h_dst[47:40]; // dst_addr[47:40]
    host_mem[dsc_base+(k*ST_DSC_SZ)+6]  = c2h_dst[55:48]; // dst_addr[55:48]
    host_mem[dsc_base+(k*ST_DSC_SZ)+7]  = c2h_dst[63:56]; // dst_addr[63:56]
  end

  // Initialize Status write back location to 0's -- the last slot is the
  // final ST_DSC_SZ-sized chunk of the ring's fixed ring_entries*QDMA_DSC_SZ
  // byte window, not ST_DSC_SZ*(ring_entries-1).
  host_mem[dsc_base + (longint'(ring_entries)*QDMA_DSC_SZ - ST_DSC_SZ) +0] = 8'h00;
  host_mem[dsc_base + (longint'(ring_entries)*QDMA_DSC_SZ - ST_DSC_SZ) +1] = 8'h00;
  host_mem[dsc_base + (longint'(ring_entries)*QDMA_DSC_SZ - ST_DSC_SZ) +2] = 8'h00;
  host_mem[dsc_base + (longint'(ring_entries)*QDMA_DSC_SZ - ST_DSC_SZ) +3] = 8'h00;

  for (k = 0; k < ST_DSC_SZ; k = k + 1)  begin
    `uvm_info("C2H_ST", $sformatf(" **** Descriptor data *** data = 0x%0h, addr= 0x%0h", host_mem[dsc_base+k], dsc_base+k), UVM_HIGH)
    #(Tcq);
  end

  // Zero the C2H destination buffer so stale data doesn't mask failures
  for (k = 0; k < c2h_bytes; k = k + 1)  begin
    #(Tcq) host_mem[C2H_DAT_DST_ADDR+k] = 8'h00;
  end

  if (enable_c2h_cmpt) begin
    // Initialize CMPT ring area to zeros (8 bytes per entry, GLBL_RNG_SIZE entries)
    bit [63:0] cmpt_base;
    cmpt_base = CMPT_RING_BASE + (qid * GLBL_RNG_SIZE * 8);
    for (k = 0; k < GLBL_RNG_SIZE * 8; k = k + 1)
      host_mem[cmpt_base + k] = 8'h00;
    // The scoreboard checks every completion entry written to this ring.
    dma_req_proc.register_cmpt_ring(qid, cmpt_base);
  end

  // Register expected C2H data for scoreboard comparison.
  // Every packet for this QID writes the same window at C2H_DAT_DST_ADDR, so
  // only the last packet's data will be in host_mem after the transfer.
  if (c2h_active) begin
    // Active C2H: data comes from the C2H source (deterministic pattern).
    // Register only the last packet's pattern (packet index pidx-1).
    dma_req_proc.register_c2h_expected_pattern(qid, C2H_DAT_DST_ADDR,
                                                c2h_bytes,
                                                1, c2h_bytes / 64,
                                                int'(pidx) - 1);
  end else begin
    // Loopback: H2C task has already filled host_mem with the source pattern
    dma_req_proc.register_c2h_expected(qid, C2H_DAT_DST_ADDR, DMA_BYTE_CNT,
                                        64'(qid) * DMA_BYTE_CNT);
  end
 end
endtask

task TSK_GLBL_PGM;
begin
  // initilize all ring size to some value.
  // Ring size below is the RUNTIME value the DUT wraps pidx at. Defaults to
  // GLBL_RNG_SIZE; set by +RING_ENTRIES.
  `uvm_info("GLBL_PGM", $sformatf("---Initilize all ring size to %h (%0d entries, %0d usable) -------", ring_entries, ring_entries, ring_usable()), UVM_MEDIUM)
  //-------------- Global Ring Size for Queue 0  0x204  : num of dsc 16 ------------------------
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h204, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h208, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h20C, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h210, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h214, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h218, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h21C, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h220, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h224, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h228, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h22C, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h230, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h234, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h238, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h23C, ring_entries);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h240, ring_entries);

  //-------------- Indirect CTXT MASK 0x814  0xffffffff for all 128 bits -------------------
  `uvm_info("GLBL_PGM", "---Programming Indirect CTXT MASK to 0xffffffff-------", UVM_MEDIUM)
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h824, 32'hffffffff);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h828, 32'hffffffff);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h82C, 32'hffffffff);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h830, 32'hffffffff);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h834, 32'hffffffff);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h838, 32'hffffffff);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h83C, 32'hffffffff);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h840, 32'hffffffff);

  //-------------- C2H Completion Global Registers (ST mode only) --------------
  // Not programmed here: 0xA00, 0xA40, 0xAB0 are C2H completion coalescing
  // config (timer, counter threshold, buffer size) -- not required for basic
  // CMPT testing. The QDMA CMPT hardware uses trig_mode from the CMPT context
  // (programmed per-QID in TSK_QDMA_ST_C2H_TEST).

  glbl_pgm_done = 1;
end
endtask

task TSK_FNC_MAP_PGM;
  input [7:0] fnc;
  input [10:0] q_base;
  input [11:0] q_count;
  bit [255:0] wr_dat;
begin


  //-------------- Global Function MAP 0x400  : Func0 22:11 Qnumber ( 16 Queue ) : 10:0 Qid_base for this Func
  `uvm_info("GLBL_PGM", $sformatf("---Programming Function Map for fnc: %h -------",fnc), UVM_MEDIUM)
  `uvm_info("GLBL_PGM", $sformatf("---                          q_base: %h -------",q_base), UVM_MEDIUM)
  `uvm_info("GLBL_PGM", $sformatf("---                         q_count: %h -------",q_count), UVM_MEDIUM)

  // Give the scoreboard the same qid->function map the DUT is being programmed
  // with. Registered HERE, from the values actually written to the FMAP, so the
  // two cannot drift. Without it the MSI-X completion gate has no way to tell
  // which function owns a queue and falls back to crediting any interrupt in
  // the right direction -- which retired VF1/VF2/VF3's queues on PF0's and
  // VF0's interrupts.
  if (dma_req_proc != null)
    dma_req_proc.register_fnc_qrange(int'(fnc), int'(q_base), int'(q_count));

  wr_dat[31:0]   = 32'h0 | q_base;
  wr_dat[63:32]  = 32'h0 | q_count;
  wr_dat[255:64] = 'h0;

  issue_reg_write(PF_DMA_BAR_INDEX, 16'h804, wr_dat[31 :0 ]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h808, wr_dat[63 :32]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h80C, wr_dat[95 :64]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h810, wr_dat[127:96]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h814, wr_dat[159:128]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h818, wr_dat[191:160]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h81C, wr_dat[223:192]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h820, wr_dat[255:224]);

  wr_dat[31:18] = 'h0; // reserved
  wr_dat[17:7]  = 11'h0 | fnc[7:0]; // fnc
  wr_dat[6:5]   = 2'h1; // MDMA_CTXT_CMD_WR
  wr_dat[4:1]   = 4'hC; // QDMA_CTXT_SELC_FMAP
  wr_dat[0]     = 'h0;
  issue_reg_write(PF_DMA_BAR_INDEX, 32'h844, wr_dat[31:0]);
  poll_ctxt_busy();
  fnc_map_pgm_done[fnc] = 1;
  end
endtask

/************************************************************
Task : TSK_QDMA_ST_H2C_TEST
Inputs : qid, port_id, irq_en
Outputs : None
Description : H2C Streaming DMA transfer test.
              Programs SW context with is_mm=0, dsc_sz=16B,
              bypass=1, writes 16B H2C-ST descriptors, and
              rings the doorbell to trigger the transfer.
*************************************************************/

task TSK_QDMA_ST_H2C_TEST (input bit [10:0] qid, input bit [2:0] port_id, input irq_en);

  bit [63:0]  dsc_base;
  bit [11:0]  q_base;
  bit [7:0]   fnc = 8'(pf_fnc);
  bit [255:0] wr_dat;
  bit [31:0]  wr_add;
  bit [10:0]  st_q;
  bit [31:0]  READ_DATA;
  localparam  ST_DSC_SZ = 16;
  localparam  NUM_ITER = 1;
  integer     iter;
  begin
   //----------------------------------------------------------------------------------------
   // QDMA AXI-ST H2C Test Starts
   //----------------------------------------------------------------------------------------
  `uvm_info("H2C_ST", "------AXI-ST H2C Tests start--------", UVM_MEDIUM)

  st_q = qid;
  dsc_base = H2C_DSC_ADDR + qid * GLBL_RNG_SIZE * ST_DSC_SZ;
  q_base  = pf_fnc * QUEUE_PER_PF;

  //-------------- Load DATA in Buffer ----------------------------------------------------
  TSK_INIT_QDMA_ST_DATA_H2C(fnc, st_q, dsc_base);

  // Global programming
  if(!glbl_pgm_done)
    TSK_GLBL_PGM;

  if(!fnc_map_pgm_done[fnc])
    TSK_FNC_MAP_PGM(fnc, q_base, QUEUE_PER_PF);

   //-------------- DMA Engine ID Read -----------------------------------------------------
  `uvm_info("H2C_ST", $sformatf("------DMA Engine ID Read--------, PF_DMA_BAR_INDEX:%d",PF_DMA_BAR_INDEX), UVM_LOW)
  issue_reg_read(PF_DMA_BAR_INDEX, 16'h00, , , ,READ_DATA);

  //-------------- Clear HW CXTX for H2C for Qid -----------------------------------------
  wr_dat[31:18] = 'h0; // reserved
  wr_dat[17:7]  = st_q[10:0]; // qid
  wr_dat[6:5]   = 2'h0; // MDMA_CTXT_CMD_CLR
  wr_dat[4:1]   = 4'h3; // MDMA_CTXT_SELC_DSC_HW_H2C
  wr_dat[0]     = 'h0;
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  if(irq_en == 1'b1) begin
    TSK_PROGRAM_MSIX_VEC_TABLE (fnc);
  end

  // AXI-ST H2C Transfer start
  `uvm_info("H2C_ST", " *** QDMA H2C ST *** ", UVM_MEDIUM)
  //-------------- Ind Direct AXI-ST H2C CTXT DATA -------------------
  wr_dat[255:140] = 'd0;
  wr_dat[139]     = 'd0;    // int_aggr
  wr_dat[138:128] = 'd1;    // vec MSI-X Vector
  wr_dat[127:64]  =  {dsc_base_hi, dsc_base[31:0]}; // dsc base
  wr_dat[63]      =  1'b0;  // is_mm (streaming mode)
  wr_dat[62]      =  1'b0;  // mrkr_dis
  wr_dat[61]      =  1'b0;  // irq_req
  wr_dat[60]      =  1'b0;  // err_wb_sent
  wr_dat[59:58]   =  2'b0;  // err
  wr_dat[57]      =  1'b0;  // irq_no_last
  wr_dat[56:54]   =  port_id; // port_id
  wr_dat[53]      =  irq_en;  // irq_en
  wr_dat[52]      =  1'b0;  // wbk_en
  wr_dat[51]      =  1'b0;  // mm_chn
  wr_dat[50]      =  st_dsc_bypass[0];  // bypass (see ST_DSC_BYPASS plusarg)
  wr_dat[49:48]   =  2'b01; // dsc_sz, 16 bytes
  wr_dat[47:44]   =  4'h1;  // rng_sz
  wr_dat[43:41]   =  3'h0;  // reserved
  wr_dat[40:37]   =  4'h0;  // fetch_max
  wr_dat[36]      =  1'b0;  // atc
  wr_dat[35]      =  1'b0;  // wbi_intvl_en
  wr_dat[34]      =  1'b1;  // wbi_chk
  wr_dat[33]      =  use_dsc_crdt ? 1'b1 : 1'b0;  // fcrd_en — enable for dsc_crdt mode
  wr_dat[32]      =  1'b1;  // qen
  wr_dat[31:25]   =  7'h0;  // reserved
  wr_dat[24:17]   =  {4'h0,pf_fnc[3:0]}; // func_id
  wr_dat[16]      =  1'b0;  // irq_arm
  wr_dat[15:0]    =  16'b0; // pidx

  issue_reg_write(PF_DMA_BAR_INDEX, 16'h804, wr_dat[31 :0 ]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h808, wr_dat[63 :32]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h80C, wr_dat[95 :64]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h810, wr_dat[127:96]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h814, wr_dat[159:128]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h818, wr_dat[191:160]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h81C, wr_dat[223:192]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h820, wr_dat[255:224]);

//-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : CMD MDMA_CTXT_CMD_WR=1 ---------
// [17:7] QID
// [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
// [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
// 0      BUSY : 0
//        00000000000_01_0001_0 : 0x22
  wr_dat = {14'h0,st_q[10:0],7'b0100010};
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  for (iter=0; iter < NUM_ITER; iter=iter+1) begin
    fork
`ifdef USE_DSC_CRDT
      if (use_dsc_crdt && dsc_crdt_agnt != null) begin
         // Per PG302: fetch credit is a secondary throttle on top of PIDX-advertised
         // descriptor availability (the effective count is min(credit,
         // pidx-cidx)), not a replacement for the PIDX doorbell. Skipping the doorbell
         // leaves pidx=0, so pidx-cidx=0 regardless of credit, and the queue never
         // dispatches. Write the doorbell first to advertise availability, then send
         // the credit to throttle how much of it gets fetched.
         dsc_crdt_seq crdt_seq = dsc_crdt_seq::type_id::create("crdt_seq");
         wr_add = QUEUE_PTR_PF_ADDR + (st_q * 16) + 4;
         issue_reg_write(PF_DMA_BAR_INDEX, wr_add[31:0], {irq_en, pidx[15:0]} | 32'h0);
         crdt_seq.qid   = {1'b0, st_q};
         crdt_seq.crdt  = pidx;
         crdt_seq.dir   = 1'b0;  // H2C
         crdt_seq.fence = 1'b0;
         `uvm_info("H2C_ST", $sformatf("dsc_crdt: crdt=%0d qid=%0d (PIDX doorbell written, then credit sent)", pidx, st_q), UVM_MEDIUM)
         crdt_seq.start(dsc_crdt_agnt.seqr);
      end else
`endif
      begin
         // Standard PIDX doorbell write via PCIe register interface
         `uvm_info("H2C_ST", $sformatf("pidx %0d value written to qid:%0d",pidx,qid), UVM_MEDIUM)
         wr_add = QUEUE_PTR_PF_ADDR + (st_q * 16) + 4;
         issue_reg_write(PF_DMA_BAR_INDEX, wr_add[31:0], {irq_en, pidx[15:0]} | 32'h0);
      end

    join
  end


  if (irq_en) begin
    TSK_CHECK_MSIX_TLP(.vec(11'd1), .fnc(8'(fnc)));  // H2C uses vec=1
  end

  end
  endtask

/************************************************************
Task : TSK_QDMA_ST_H2C_DRV_QUEUE
Inputs : qid, port_id, frcd_en, req_n (descriptors per request),
         last_len (length of the queue's final descriptor; 0 = DMA_BYTE_CNT),
         step0 (step number of the first request, for the log)
Outputs : n_fail (requests that did not retire)
Description : Runs one queue the way the Linux driver does in poll mode.
  The SW context carries the driver's ST-H2C settings (writeback on,
  accumulation and pending check on, marker response off, no interrupt,
  fetch_max 7, 16-byte descriptors, fetch credit as given). Each request
  places req_n[r] descriptors and rings ONE doorbell for all of them, then
  waits for the host-memory status writeback to report cidx == the new pidx,
  which is the only completion signal the driver has. The PL-side byte count
  of the queue is reported alongside. A request that does not retire within
  +H2C_DRV_STEP_NS is reported and the sequence moves on, so the requests
  after a stuck one still run.
*************************************************************/
task TSK_QDMA_ST_H2C_DRV_QUEUE (input bit [10:0] qid, input bit [2:0] port_id, input bit frcd_en,
                                input int req_n[$], input int last_len, input int step0,
                                output int n_fail);
  localparam int ST_DSC_SZ = 16;
  bit [63:0]  dsc_base;
  bit [63:0]  wb_addr;
  bit [11:0]  q_base;
  bit [7:0]   fnc = 8'(pf_fnc);
  bit [255:0] wr_dat;
  bit [31:0]  wr_add;
  bit [31:0]  READ_DATA;
  int         total, cum, step_ns;
  begin
    n_fail  = 0;
    step_ns = 40000;
    void'($value$plusargs("H2C_DRV_STEP_NS=%d", step_ns));
    total = 0;
    foreach (req_n[r]) total += req_n[r];

    dsc_base = H2C_DSC_ADDR + qid * GLBL_RNG_SIZE * ST_DSC_SZ;
    wb_addr  = dsc_base + (longint'(ring_entries) - 1) * ST_DSC_SZ;
    q_base   = pf_fnc * QUEUE_PER_PF;

    // Descriptors for every request of this queue, all reading the queue's
    // source buffer; the final one may be shorter.
    pidx = 16'(total);
    TSK_INIT_QDMA_ST_DATA_H2C(fnc, qid, dsc_base);
    if (last_len > 0) begin
      host_mem[int'(dsc_base + (total - 1) * ST_DSC_SZ + 4)] = 8'(last_len);
      host_mem[int'(dsc_base + (total - 1) * ST_DSC_SZ + 5)] = 8'(last_len >> 8);
    end

    if (!glbl_pgm_done)
      TSK_GLBL_PGM;
    if (!fnc_map_pgm_done[fnc])
      TSK_FNC_MAP_PGM(fnc, q_base, QUEUE_PER_PF);

    // Clear the H2C HW context for the queue
    wr_dat = '0;
    wr_dat[17:7] = qid[10:0];
    wr_dat[6:5]  = 2'h0;          // clear
    wr_dat[4:1]  = 4'h3;          // DSC_HW_H2C
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    // H2C SW context as the driver programs it (poll mode)
    wr_dat = '0;
    wr_dat[139]     = 1'b0;       // intr_aggr
    wr_dat[138:128] = 11'd0;      // vec
    wr_dat[127:64]  = {dsc_base_hi, dsc_base[31:0]};
    wr_dat[63]      = 1'b0;       // is_mm
    wr_dat[62]      = 1'b1;       // mrkr_dis
    wr_dat[56:54]   = port_id;
    wr_dat[53]      = 1'b0;       // irq_en
    wr_dat[52]      = 1'b1;       // wbk_en
    wr_dat[50]      = 1'b0;       // bypass
    wr_dat[49:48]   = 2'b01;      // dsc_sz 16 bytes
    wr_dat[47:44]   = 4'h1;       // rng_sz index
    wr_dat[40:37]   = 4'd7;       // fetch_max
    wr_dat[35]      = 1'b1;       // wbi_intvl_en
    wr_dat[34]      = 1'b1;       // wbi_chk
    wr_dat[33]      = frcd_en;    // fcrd_en
    wr_dat[32]      = 1'b1;       // qen
    wr_dat[24:17]   = {4'h0, pf_fnc[3:0]};
    wr_dat[16]      = 1'b0;       // irq_arm
    wr_dat[15:0]    = 16'd0;      // pidx
    for (int w = 0; w < 8; w++)
      issue_reg_write(PF_DMA_BAR_INDEX, 16'h804 + 4 * w, wr_dat[32 * w +: 32]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, {14'h0, qid[10:0], 7'b0100010});
    poll_ctxt_busy();

    cum = 0;
    foreach (req_n[r]) begin
      longint unsigned b0, b1, exp_b;
      bit [15:0] cidx;
      time t0;
      bit done;
      exp_b = 0;
      for (int d = cum; d < cum + req_n[r]; d++)
        exp_b += (d == total - 1 && last_len > 0) ? last_len : DMA_BYTE_CNT;
      b0 = dma_req_proc.h2c_user_data.exists(qid) ? dma_req_proc.h2c_user_data[qid].size() : 0;
      cum += req_n[r];
      // One doorbell for the whole request, irq_arm clear
      wr_add = QUEUE_PTR_PF_ADDR + (qid * 16) + 4;
      issue_reg_write(PF_DMA_BAR_INDEX, wr_add[31:0], {16'h0, 16'(cum)});
      t0 = $time;
      done = 1'b0;
      cidx = '0;
      while (!done && ($time - t0) < step_ns * 1ns) begin
        #100ns;
        if (host_mem.exists(int'(wb_addr + 2)) && host_mem.exists(int'(wb_addr + 3))) begin
          cidx = {host_mem[int'(wb_addr + 3)], host_mem[int'(wb_addr + 2)]};
          done = (cidx == 16'(cum));
        end
      end
      #2us;   // let the PL-side byte count settle
      b1 = dma_req_proc.h2c_user_data.exists(qid) ? dma_req_proc.h2c_user_data[qid].size() : 0;
      if (done)
        `uvm_info("H2C_DRV_SEQ", $sformatf(
          "S%0d qid=%0d descriptors=%0d pidx=%0d: RETIRED, status cidx=%0d after %0t; PL bytes +%0d (exp %0d)",
          step0 + r, qid, req_n[r], cum, cidx, $time - t0 - 2us, b1 - b0, exp_b), UVM_NONE)
      else begin
        n_fail++;
        `uvm_error("H2C_DRV_SEQ", $sformatf(
          "S%0d qid=%0d descriptors=%0d pidx=%0d: NOT RETIRED after %0d ns, status cidx=%0d%s; PL bytes +%0d (exp %0d)",
          step0 + r, qid, req_n[r], cum, step_ns, cidx,
          host_mem.exists(int'(wb_addr + 2)) ? "" : " (no status write seen)", b1 - b0, exp_b))
      end
      if (b1 - b0 != exp_b)
        `uvm_error("H2C_DRV_SEQ", $sformatf("S%0d qid=%0d PL bytes +%0d, expected %0d",
                                            step0 + r, qid, b1 - b0, exp_b))
    end
  end
endtask

/************************************************************
Task : TSK_QDMA_ST_H2C_DRV_SEQ
Inputs : port_id
Outputs : None
Description : H2C-ST multi-descriptor sequence run the driver's way (poll
  mode). One queue takes three single-descriptor requests (control group);
  a fresh queue then takes two 2-descriptor requests, each under one
  doorbell, and a final 32-byte single-descriptor request.
  +H2C_DRV_FRCD=<0|1> sets the queues' fetch-credit enable
  (default 1, the dma-ctl default); no fetch credits are sent.
*************************************************************/
task TSK_QDMA_ST_H2C_DRV_SEQ (input bit [2:0] port_id);
  int frcd, fa, fb;
  int one[$], two[$];
  begin
    frcd = 1;
    void'($value$plusargs("H2C_DRV_FRCD=%d", frcd));
    pf_fnc = 0;
    `uvm_info("H2C_DRV_SEQ", $sformatf("H2C-ST driver sequence: port %0d, fcrd_en %0d, DMA_BYTE_CNT %0d",
                                       port_id, frcd, DMA_BYTE_CNT), UVM_NONE)
    one = '{1, 1, 1};
    TSK_QDMA_ST_H2C_DRV_QUEUE(11'd1, port_id, 1'(frcd), one, 0, 1, fa);
    two = '{2, 2, 1};
    TSK_QDMA_ST_H2C_DRV_QUEUE(11'd2, port_id, 1'(frcd), two, 32, 5, fb);
    `uvm_info("H2C_DRV_SEQ", $sformatf(
      "H2C-ST driver sequence done: control queue %0d of 3 retired, multi-descriptor queue %0d of 3 retired",
      3 - fa, 3 - fb), UVM_NONE)
  end
endtask

/************************************************************
Task : TSK_QDMA_ST_C2H_DRV_QUEUE
Inputs : qid, port_id, n_pkts (packets to receive)
Outputs : n_fail (packets not received correctly)
Description : Receives C2H-ST packets on one queue the way the Linux driver
  does in poll mode, judging everything from host memory only:
  - Reads the ring size (0x204, entry 0) and the C2H buffer size (0xAB0,
    entry 0) like the driver; both rings hold ring size - 1 entries.
  - Contexts as the driver programs them: SW context with no interrupt,
    no writeback, fetch_max 7, 8-byte descriptors, fetch credit as given;
    prefetch context with the buffer-size index 0; completion context with
    status entries on, trigger EVERY, colour 1, ring-size index 0, 8-byte
    entries. The free list holds one buffer per descriptor.
  - Posts ring size - 2 descriptors with the C2H PIDX doorbell
    (+C2H_DRV_PIDX_DB=0 puts the pidx in the SW context instead) and writes
    the completion CIDX register once; then starts one example-design C2H
    burst of one packet per posted buffer group (TSK_C2H_SRC_START_BURST).
  - Polls the completion ring's status entry (after the last entry) for its
    pidx, then reads each new entry: colour (bit 1) must match the expected
    colour, which flips on every ring wrap; desc_used set, no error, length
    in bits [19:4]. The packet's bytes are checked in the buffer(s) it used,
    against the example design's pattern (beat b of the k-th packet of a
    burst carries k*beats+b in bits [31:0], the burst's sequence number in
    [47:32] and the queue id in [63:53]).
  - Hands entries back through the completion CIDX register and reposts the
    used buffers (cleared first, so stale data shows) with a new doorbell
    and a burst for them, until n_pkts packets are posted.
  A step in which the status pidx does not move within +C2H_DRV_STEP_NS
  ends the queue with a dump of what did land.
*************************************************************/
task TSK_QDMA_ST_C2H_DRV_QUEUE (input bit [10:0] qid, input bit [2:0] port_id, input int n_pkts,
                                output int n_fail);
  localparam int C2H_DSC_SZ = 8;
  bit [63:0]  dsc_base, cmpt_base, cmpt_sts, buf_base;
  bit [11:0]  q_base;
  bit [7:0]   fnc = 8'(pf_fnc);
  bit [255:0] wr_dat;
  bit [31:0]  wr_add, rd;
  int         rngsz, bufsz, pkt_bytes, beats, step_ns, frcd, pfch_en, pidx_db;
  int         posted, pidx_c2h, cidx_c2h, cidx_cmpt, n_done, sv_pfch_en;
  bit         exp_col;
  bit [31:0]  cmpt_cidx_reg;
  bit         rt_ok;
  int         dpp_drv, seq, sg, pkts_req;
  int         seg_first [$];   // first packet index of each burst
  int         seg_seq   [$];   // that burst's sequence number
  begin
    TSK_C2H_SRC_SCHED_INIT();
    n_fail    = 0;
    step_ns   = 40000;
    frcd      = 1;
    pfch_en   = 0;
    pidx_db   = 1;
    pkt_bytes = 512;
    void'($value$plusargs("C2H_DRV_STEP_NS=%d", step_ns));
    void'($value$plusargs("C2H_DRV_FRCD=%d", frcd));
    void'($value$plusargs("C2H_DRV_PFCH_EN=%d", pfch_en));
    void'($value$plusargs("C2H_DRV_PIDX_DB=%d", pidx_db));
    void'($value$plusargs("C2H_DRV_PKT_BYTES=%d", pkt_bytes));
    beats = pkt_bytes / 64;

    q_base = pf_fnc * QUEUE_PER_PF;
    if (!glbl_pgm_done)
      TSK_GLBL_PGM;
    if (!fnc_map_pgm_done[fnc])
      TSK_FNC_MAP_PGM(fnc, q_base, QUEUE_PER_PF);

    // Ring and buffer sizes as the driver reads them
    issue_reg_read(PF_DMA_BAR_INDEX, 16'h204, , , , rd);
    rngsz = int'(rd[15:0]) - 1;
    issue_reg_read(PF_DMA_BAR_INDEX, 16'hAB0, , , , rd);
    bufsz = int'(rd);
    if (rngsz < 2 || bufsz == 0 || bufsz > 65536 || (pkt_bytes > bufsz * 7)) begin
      n_fail = n_pkts;
      `uvm_error("C2H_DRV_SEQ", $sformatf(
        "qid=%0d cannot start: ring size register 0x%0h (%0d entries), C2H buffer size 0x%0h (the driver's q start fails)",
        qid, rngsz + 1, rngsz, bufsz))
      return;
    end

    // The example-design C2H source splits a packet into buffers of
    // C2H_SRC_BUF_BYTES, so it must match the queue's buffer size whenever
    // that changes the descriptor count.
    if (pkt_bytes != C2H_SRC_RST_PKT_BYTES || $test$plusargs("C2H_SRC_CFG_CHK")) begin
      if ((pkt_bytes + bufsz - 1) / bufsz != (pkt_bytes + C2H_SRC_BUF_BYTES - 1) / C2H_SRC_BUF_BYTES) begin
        n_fail = n_pkts;
        `uvm_error("C2H_DRV_SEQ", $sformatf(
          "qid=%0d cannot start: %0d-byte packets take %0d buffers of %0d B, but the C2H source splits them into %0d-byte buffers",
          qid, pkt_bytes, (pkt_bytes + bufsz - 1) / bufsz, bufsz, C2H_SRC_BUF_BYTES))
        return;
      end
      TSK_C2H_SRC_CFG_SET(int'(port_id), int'(pkt_bytes));
    end

    dsc_base  = C2H_DSC_ADDR + qid * GLBL_RNG_SIZE * 16;
    cmpt_base = CMPT_RING_BASE + qid * GLBL_RNG_SIZE * 8;
    cmpt_sts  = cmpt_base + rngsz * 8;
    buf_base  = 64'h3000_0000 + qid * 64'h0010_0000;
    if (rngsz * bufsz > 'h10_0000)
      `uvm_warning("C2H_DRV_SEQ", $sformatf("qid=%0d buffers (%0d x %0d B) overlap the next queue's", qid, rngsz, bufsz))
    c2h_qid_dsc_sz[int'(qid)]   = C2H_DSC_SZ;
    c2h_qid_dsc_base[int'(qid)] = dsc_base;

    // Free list: descriptor k points at buffer k; completion ring and status zeroed
    for (int k = 0; k < rngsz; k++) begin
      bit [63:0] a;
      a = buf_base + k * bufsz;
      for (int b = 0; b < 8; b++)
        host_mem[int'(dsc_base + k * C2H_DSC_SZ + b)] = a[8 * b +: 8];
    end
    for (int k = 0; k < (rngsz + 1) * 8; k++)
      host_mem[int'(cmpt_base + k)] = 8'h00;

    // Clear the C2H HW context and the completion context
    wr_dat = '0;
    wr_dat[17:7] = qid[10:0];
    wr_dat[4:1]  = 4'h2;          // DSC_HW_C2H
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();
    wr_dat[4:1]  = 4'h6;          // WRB (completion)
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    // C2H SW context as the driver programs it (poll mode)
    posted = rngsz - 1;
    wr_dat = '0;
    wr_dat[139]     = 1'b0;       // intr_aggr
    wr_dat[138:128] = 11'd0;      // vec
    wr_dat[127:64]  = {dsc_base_hi, dsc_base[31:0]};
    wr_dat[63]      = 1'b0;       // is_mm
    wr_dat[62]      = 1'b0;       // mrkr_dis
    wr_dat[56:54]   = port_id;
    wr_dat[53]      = 1'b0;       // irq_en
    wr_dat[52]      = 1'b0;       // wbk_en
    wr_dat[50]      = 1'b0;       // bypass
    wr_dat[49:48]   = 2'b00;      // dsc_sz 8 bytes
    wr_dat[47:44]   = 4'h0;       // rng_sz index
    wr_dat[40:37]   = 4'd7;       // fetch_max
    wr_dat[35]      = 1'b1;       // wbi_intvl_en
    wr_dat[34]      = 1'b0;       // wbi_chk
    wr_dat[33]      = 1'(frcd);   // fcrd_en
    wr_dat[32]      = 1'b1;       // qen
    wr_dat[24:17]   = {4'h0, pf_fnc[3:0]};
    wr_dat[16]      = 1'b0;       // irq_arm
    wr_dat[15:0]    = pidx_db ? 16'd0 : 16'(posted);
    for (int w = 0; w < 8; w++)
      issue_reg_write(PF_DMA_BAR_INDEX, 16'h804 + 4 * w, wr_dat[32 * w +: 32]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, {14'h0, qid[10:0], 7'b0100000});
    poll_ctxt_busy();

    // Prefetch context: valid, pfch_en as given, port, buffer-size index 0
    sv_pfch_en  = c2h_pfch_en;
    c2h_pfch_en = pfch_en;
    TSK_QDMA_C2H_PFCH_CTXT(qid, port_id);
    c2h_pfch_en = sv_pfch_en;

    // Completion context
    wr_dat = '0;
    wr_dat[0]       = 1'b1;                     // en_stat_desc
    wr_dat[1]       = 1'b0;                     // en_int
    wr_dat[4:2]     = 3'h1;                     // trig_mode EVERY
    wr_dat[12:5]    = {4'h0, pf_fnc[3:0]};      // func_id
    wr_dat[20:17]   = 4'h0;                     // counter_idx
    wr_dat[24:21]   = 4'h0;                     // timer_idx
    wr_dat[27]      = 1'b1;                     // color
    wr_dat[31:28]   = 4'h0;                     // ring-size index
    wr_dat[89:32]   = cmpt_base[63:6];          // ring base
    wr_dat[91:90]   = 2'h0;                     // 8-byte entries
    wr_dat[124]     = 1'b1;                     // valid
    wr_dat[146]     = 1'b1;                     // dir_c2h
    for (int w = 0; w < 8; w++)
      issue_reg_write(PF_DMA_BAR_INDEX, 16'h804 + 4 * w, wr_dat[32 * w +: 32]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, {14'h0, qid[10:0], 7'b0101100});
    poll_ctxt_busy();
    // Read it back before any traffic, as at queue setup in the default flow
    TSK_IND_CTXT_READBACK(PF_DMA_BAR_INDEX, qid, 4'h6 /*CMPT*/, wr_dat, IND_CTXT_200B_MASK,
                          "after write", rt_ok);
    cmpt_ctxt_exp[qid] = wr_dat;
    cmpt_ctxt_bar[qid] = PF_DMA_BAR_INDEX;

    // Completion CIDX register: cidx 0, status entries on, trigger EVERY
    cmpt_cidx_reg = '0;
    cmpt_cidx_reg[27]    = 1'b1;
    cmpt_cidx_reg[26:24] = 3'h1;
    issue_reg_write(PF_DMA_BAR_INDEX, QUEUE_PTR_PF_ADDR + (qid * 16) + 12, cmpt_cidx_reg);

    // Post the free list
    pidx_c2h = posted;
    if (pidx_db) begin
      issue_reg_write(PF_DMA_BAR_INDEX, QUEUE_PTR_PF_ADDR + (qid * 16) + 8, 32'(pidx_c2h));
      issue_reg_read(PF_DMA_BAR_INDEX, QUEUE_PTR_PF_ADDR + (qid * 16) + 8, , , , rd);   // doorbell landed
    end
    `uvm_info("C2H_DRV_SEQ", $sformatf(
      "qid=%0d port=%0d: rings %0d entries, buffers %0d B, packets %0d x %0d B, pidx %0d posted by %s, fcrd_en %0d, pfch_en %0d",
      qid, port_id, rngsz, bufsz, n_pkts, pkt_bytes, pidx_c2h, pidx_db ? "doorbell" : "SW context", frcd, pfch_en), UVM_NONE)
    // The data source sends one packet per posted buffer group, started the
    // way software does it: a burst after the buffers are posted. Each burst
    // restarts the data pattern's beat index and carries its own sequence
    // number, so the data check below works per burst.
    dpp_drv = (pkt_bytes + bufsz - 1) / bufsz;
    seg_first.delete(); seg_seq.delete();
    begin
      int n_burst;
      n_burst = (posted / dpp_drv < n_pkts) ? posted / dpp_drv : n_pkts;
      TSK_C2H_SRC_START_BURST(int'(port_id), qid, n_burst, pkt_bytes, seq);
      seg_first.push_back(0);
      seg_seq.push_back(seq);
      pkts_req = n_burst;
    end

    n_done    = 0;
    cidx_c2h  = 0;
    cidx_cmpt = 0;
    exp_col   = 1'b1;
    while (n_done < n_pkts) begin
      time t0;
      bit  got;
      int  sts_pidx, consumed;
      // wait for the status entry's pidx to move past the consumer index
      t0 = $time;
      got = 1'b0;
      sts_pidx = 0;
      while (!got && ($time - t0) < step_ns * 1ns) begin
        #200ns;
        if (host_mem.exists(int'(cmpt_sts)) && host_mem.exists(int'(cmpt_sts + 1))) begin
          sts_pidx = int'({host_mem[int'(cmpt_sts + 1)], host_mem[int'(cmpt_sts)]});
          got = (sts_pidx != cidx_cmpt);
        end
      end
      if (!got) begin
        string ring;
        int    land;
        ring = "";
        for (int k = 0; k <= rngsz && k < 8; k++) begin
          bit [63:0] e;
          for (int b = 0; b < 8; b++) e[8 * b +: 8] = host_mem[int'(cmpt_base + k * 8 + b)];
          ring = {ring, $sformatf(" [%0d]=%h", k, e)};
        end
        land = 0;
        for (int b = 0; b < pkt_bytes; b++)
          if (host_mem.exists(int'(buf_base + cidx_c2h * bufsz + b))) land++;
        n_fail += n_pkts - n_done;
        `uvm_error("C2H_DRV_SEQ", $sformatf(
          "qid=%0d packet %0d: no new completion after %0d ns (status pidx %0d, consumer %0d%s); next buffer holds %0d of %0d bytes; completion ring%s",
          qid, n_done, step_ns, sts_pidx, cidx_cmpt,
          host_mem.exists(int'(cmpt_sts)) && (host_mem[int'(cmpt_sts)] | host_mem[int'(cmpt_sts + 1)] | host_mem[int'(cmpt_sts + 4)]) != 0 ?
            "" : ", status entry never written", land, pkt_bytes, ring))
        break;
      end

      consumed = 0;
      while (cidx_cmpt != sts_pidx && n_done < n_pkts) begin
        bit [63:0] e;
        int        len, nd, mism;
        for (int b = 0; b < 8; b++) e[8 * b +: 8] = host_mem[int'(cmpt_base + cidx_cmpt * 8 + b)];
        len = int'(e[19:4]);
        if (e[1] !== exp_col || e[0] || e[2] || !e[3] || len != pkt_bytes) begin
          n_fail++;
          `uvm_error("C2H_DRV_SEQ", $sformatf(
            "qid=%0d packet %0d: completion entry [%0d] = %h: colour %0d (expected %0d), format %0d, error %0d, desc_used %0d, length %0d (expected %0d)",
            qid, n_done, cidx_cmpt, e, e[1], exp_col, e[0], e[2], e[3], len, pkt_bytes))
          if (e[1] !== exp_col) begin
            // the driver would wait here for the entry to be written
            n_fail += n_pkts - n_done - 1;
            n_done = n_pkts;
            break;
          end
        end
        if (len == 0) len = pkt_bytes;
        nd   = (len + bufsz - 1) / bufsz;
        mism = 0;
        // burst this packet belongs to: the last one started at or before it
        sg = 0;
        foreach (seg_first[i]) if (seg_first[i] <= n_done) sg = i;
        for (int b = 0; b < len; b++) begin
          bit [511:0] w;
          int         a;
          w = '0;
          w[31:0]  = 32'((n_done - seg_first[sg]) * beats + b / 64);
          w[47:32] = 16'(seg_seq[sg]);
          w[63:53] = qid;
          a = int'(buf_base + ((cidx_c2h + b / bufsz) % rngsz) * bufsz + (b % bufsz));
          if (!host_mem.exists(a) || host_mem[a] !== w[(b % 64) * 8 +: 8]) mism++;
        end
        if (mism != 0) begin
          n_fail++;
          `uvm_error("C2H_DRV_SEQ", $sformatf("qid=%0d packet %0d: %0d of %0d bytes wrong in buffer %0d",
                                              qid, n_done, mism, len, cidx_c2h))
        end else
          `uvm_info("C2H_DRV_SEQ", $sformatf(
            "qid=%0d packet %0d: entry [%0d] %h colour %0d, %0d B in buffer %0d: data OK",
            qid, n_done, cidx_cmpt, e, e[1], len, cidx_c2h), UVM_NONE)
        cidx_c2h  = (cidx_c2h + nd) % rngsz;
        consumed += nd;
        cidx_cmpt++;
        if (cidx_cmpt == rngsz) begin
          cidx_cmpt = 0;
          exp_col   = ~exp_col;
        end
        n_done++;
      end

      // Hand the entries back, then repost the used buffers
      cmpt_cidx_reg[15:0] = 16'(cidx_cmpt);
      issue_reg_write(PF_DMA_BAR_INDEX, QUEUE_PTR_PF_ADDR + (qid * 16) + 12, cmpt_cidx_reg);
      if (posted < n_pkts && consumed > 0) begin
        int add;
        add = (n_pkts - posted < consumed) ? n_pkts - posted : consumed;
        for (int d = 0; d < add; d++) begin
          int slot;
          slot = (pidx_c2h + d) % rngsz;
          for (int b = 0; b < bufsz; b++)
            host_mem.delete(int'(buf_base + slot * bufsz + b));
        end
        posted  += add;
        pidx_c2h = (pidx_c2h + add) % rngsz;
        issue_reg_write(PF_DMA_BAR_INDEX, QUEUE_PTR_PF_ADDR + (qid * 16) + 8, 32'(pidx_c2h));
        issue_reg_read(PF_DMA_BAR_INDEX, QUEUE_PTR_PF_ADDR + (qid * 16) + 8, , , , rd);   // doorbell landed
        // One burst for the reposted buffers
        begin
          int n_burst;
          n_burst = add / dpp_drv;
          if (n_burst > n_pkts - pkts_req) n_burst = n_pkts - pkts_req;
          if (n_burst > 0) begin
            TSK_C2H_SRC_START_BURST(int'(port_id), qid, n_burst, pkt_bytes, seq);
            seg_first.push_back(pkts_req);
            seg_seq.push_back(seq);
            pkts_req += n_burst;
          end
        end
      end
    end
    `uvm_info("C2H_DRV_SEQ", $sformatf("qid=%0d: %0d of %0d packets received correctly",
                                       qid, n_pkts - n_fail, n_pkts), UVM_NONE)
  end
endtask

/************************************************************
Task : TSK_QDMA_ST_C2H_DRV_SEQ
Inputs : port_id
Outputs : None
Description : C2H-ST receive run the driver's way (poll mode) on one PF
  queue. +C2H_DRV_PKTS sets the packet count (default two ring passes plus
  three, so both rings wrap and the completion colour flips twice).
*************************************************************/
task TSK_QDMA_ST_C2H_DRV_SEQ (input bit [2:0] port_id);
  int n_pkts, nf;
  begin
    pf_fnc = 0;
    n_pkts = 2 * (int'(ring_entries) - 1) + 3;
    void'($value$plusargs("C2H_DRV_PKTS=%d", n_pkts));
    `uvm_info("C2H_DRV_SEQ", $sformatf("C2H-ST driver sequence: port %0d, %0d packets", port_id, n_pkts), UVM_NONE)
    TSK_QDMA_ST_C2H_DRV_QUEUE(11'd1, port_id, n_pkts, nf);
    `uvm_info("C2H_DRV_SEQ", $sformatf("C2H-ST driver sequence done: %0d of %0d packets received correctly",
                                       n_pkts - nf, n_pkts), UVM_NONE)
  end
endtask

// Stream DMA through the Linux-driver sequence (PF and VF queues, both
// directions, poll and direct-interrupt mode): TSK_QDMA_ST_DRV_SEQ.
`include "qdma_st_drv_engine.svh"


/************************************************************
Task : TSK_QDMA_C2H_PFCH_CTXT
Inputs : hw_qid, port_id
Outputs : None
Description : Programs a C2H-ST queue's prefetch context through the PF
              indirect context registers (sel 7) and reads it back. The
              engine keeps a packet only for a queue whose context is valid.
              Software sets valid, pfch_en, port_id, the buffer-size index
              and cache bypass; the engine owns sw_crdt, pfch, num_pfch and
              err, which this full write clears.
              Layout: valid[45] sw_crdt[44:29] pfch[28] pfch_en[27] err[26]
              pfch_need[21:16] num_pfch[15:10] virtio[9] var_desc[8]
              port_id[7:5] buf_size_ix[4:1] bypass[0].
*************************************************************/

task TSK_QDMA_C2H_PFCH_CTXT (input bit [10:0] hw_qid, input bit [2:0] port_id);
  bit [45:0] pf;
  bit [45:0] rb;
  bit [45:0] sw_mask;
  bit [31:0] rd0, rd1;
  begin
  pf        = '0;
  pf[45]    = 1'b1;              // valid
  pf[27]    = c2h_pfch_en[0];    // pfch_en
  pf[7:5]   = port_id;           // port_id
  pf[4:1]   = 4'h0;              // buf_size_ix: entry 0 (4 KB)
  pf[0]     = 1'b0;              // cache bypass off: the engine prefetches for the queue

  issue_reg_write(PF_DMA_BAR_INDEX, 16'h804, pf[31:0]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h808, {18'h0, pf[45:32]});
  for (int a = 'h80C; a <= 'h820; a += 4)
    issue_reg_write(PF_DMA_BAR_INDEX, 16'(a), 32'h0);
  // [17:7] QID, [6:5] MDMA_CTXT_CMD_WR=1, [4:1] MDMA_CTXT_SEL_PFTCH=7
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, {14'h0, hw_qid[10:0], 2'b01, 4'h7, 1'b0});
  poll_ctxt_busy();

  // Read back: MDMA_CTXT_CMD_RD=2 returns the entry in DATA0/DATA1.
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, {14'h0, hw_qid[10:0], 2'b10, 4'h7, 1'b0});
  poll_ctxt_busy();
  issue_reg_read(PF_DMA_BAR_INDEX, 16'h804, , , , rd0);
  issue_reg_read(PF_DMA_BAR_INDEX, 16'h808, , , , rd1);
  rb      = {rd1[13:0], rd0};
  sw_mask = '0;
  sw_mask[45] = 1'b1; sw_mask[27] = 1'b1; sw_mask[7:0] = 8'hFF;   // fields software sets
  if ((rb & sw_mask) !== (pf & sw_mask))
    `uvm_error("C2H_PFCH_CTXT", $sformatf("qid %0d prefetch context read back 0x%012h, wrote 0x%012h", hw_qid, rb, pf))
  else
    `uvm_info("C2H_PFCH_CTXT", $sformatf("qid %0d prefetch context 0x%012h (valid, pfch_en %0d, port %0d)", hw_qid, rb, pf[27], port_id), UVM_MEDIUM)
  end
endtask

/************************************************************
Task : TSK_QDMA_ST_C2H_TEST
Inputs : qid, port_id, irq_en
Outputs : None
Description : C2H Streaming DMA transfer test for PF.
              Programs SW context with is_mm=0, dsc_sz=16B,
              bypass=1, writes 16B C2H-ST descriptors with
              host destination addresses, and rings the doorbell.
*************************************************************/

task TSK_QDMA_ST_C2H_TEST (input bit [10:0] qid, input bit [2:0] port_id, input irq_en);

  bit [63:0]  dsc_base;
  bit [11:0]  q_base;
  bit [7:0]   fnc = 8'(pf_fnc);
  bit [255:0] wr_dat;
  bit [31:0]  wr_add;
  bit [10:0]  st_q;
  bit [31:0]  READ_DATA;
  bit [63:0]  cmpt_ring_addr;
  bit [255:0] cmpt_exp;
  bit         rt_ok;
  localparam  ST_DSC_SZ = 16;
  localparam  NUM_ITER = 1;
  integer     iter;
  begin
   //----------------------------------------------------------------------------------------
   // QDMA AXI-ST C2H Test Starts
   //----------------------------------------------------------------------------------------
  `uvm_info("C2H_ST", "------AXI-ST C2H Tests start--------", UVM_MEDIUM)

  st_q = qid;
  dsc_base = C2H_DSC_ADDR + qid * GLBL_RNG_SIZE * ST_DSC_SZ;
  q_base  = pf_fnc * QUEUE_PER_PF;

  // Global programming
  if(!glbl_pgm_done)
    TSK_GLBL_PGM;

  if(!fnc_map_pgm_done[fnc])
    TSK_FNC_MAP_PGM(fnc, q_base, QUEUE_PER_PF);

  //-------------- C2H source packet size for this port ----------------------------------
  // Before the context commit below: the source must already generate this
  // queue's packet size when descriptors arrive.
  TSK_C2H_SRC_CFG(port_id);

  //-------------- Load C2H-ST Descriptors into host memory --------------------------------
  TSK_INIT_QDMA_ST_DATA_C2H(fnc, st_q, dsc_base);

   //-------------- DMA Engine ID Read -----------------------------------------------------
  `uvm_info("C2H_ST", $sformatf("------DMA Engine ID Read--------, PF_DMA_BAR_INDEX:%d",PF_DMA_BAR_INDEX), UVM_LOW)
  issue_reg_read(PF_DMA_BAR_INDEX, 16'h00, , , ,READ_DATA);

  //-------------- Clear HW CXTX for C2H for Qid -----------------------------------------
  wr_dat[31:18] = 'h0; // reserved
  wr_dat[17:7]  = st_q[10:0]; // qid
  wr_dat[6:5]   = 2'h0; // MDMA_CTXT_CMD_CLR
  wr_dat[4:1]   = 4'h2; // MDMA_CTXT_SELC_DSC_HW_C2H
  wr_dat[0]     = 'h0;
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  if (enable_c2h_cmpt) begin
    //-------------- Clear CMPT (WRB) CXTX for C2H for Qid --------------------------------
    wr_dat[31:18] = 'h0;
    wr_dat[17:7]  = st_q[10:0]; // qid
    wr_dat[6:5]   = 2'h0;       // MDMA_CTXT_CMD_CLR
    wr_dat[4:1]   = 4'h6;       // MDMA_CTXT_SEL_WRB (CMPT)
    wr_dat[0]     = 'h0;
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();
  end

  if(irq_en == 1'b1) begin
    TSK_PROGRAM_MSIX_VEC_TABLE (fnc);
  end

  // Prefetch context first: the SW context write below advertises descriptors,
  // and a packet arriving for a queue without a valid prefetch context is dropped.
  if (c2h_pfch)
    TSK_QDMA_C2H_PFCH_CTXT(st_q, port_id);

  // AXI-ST C2H Transfer start
  `uvm_info("C2H_ST", " *** QDMA C2H ST *** ", UVM_MEDIUM)
  //-------------- Ind Direct AXI-ST C2H CTXT DATA -------------------
  wr_dat[255:140] = 'd0;
  wr_dat[139]     = 'd0;    // int_aggr
  wr_dat[138:128] = 'd2;    // vec MSI-X Vector (C2H uses vec=2)
  wr_dat[127:64]  =  {dsc_base_hi, dsc_base[31:0]}; // dsc base
  wr_dat[63]      =  1'b0;  // is_mm (streaming mode)
  wr_dat[62]      =  1'b0;  // mrkr_dis
  wr_dat[61]      =  1'b0;  // irq_req
  wr_dat[60]      =  1'b0;  // err_wb_sent
  wr_dat[59:58]   =  2'b0;  // err
  wr_dat[57]      =  1'b0;  // irq_no_last
  wr_dat[56:54]   =  port_id; // port_id
  wr_dat[53]      =  irq_en;  // irq_en
  wr_dat[52]      =  enable_c2h_cmpt;  // wbk_en (enable when CMPT enabled)
  wr_dat[51]      =  1'b0;  // mm_chn
  wr_dat[50]      =  st_dsc_bypass[0];  // bypass (see ST_DSC_BYPASS plusarg)
  wr_dat[49:48]   =  2'b00; // dsc_sz, 8 bytes (C2H stream non-bypass size)
  wr_dat[47:44]   =  4'h1;  // rng_sz
  wr_dat[43:41]   =  3'h0;  // reserved
  wr_dat[40:37]   =  4'h0;  // fetch_max
  wr_dat[36]      =  1'b0;  // atc
  wr_dat[35]      =  1'b0;  // wbi_intvl_en
  wr_dat[34]      =  1'b1;  // wbi_chk
  wr_dat[33]      =  c2h_pfch ? 1'b1 : 1'b0;  // fcrd_en: the prefetch engine's credits drive C2H-ST fetches
  wr_dat[32]      =  1'b1;  // qen
  wr_dat[31:25]   =  7'h0;  // reserved
  wr_dat[24:17]   =  {4'h0,pf_fnc[3:0]}; // func_id
  wr_dat[16]      =  1'b0;  // irq_arm
  // PIDX: 0 in driver mode (the doorbell below posts the descriptors);
  // otherwise the ring PIDX, so the SW_C2H commit itself posts them. The ring
  // PIDX is the descriptor count: pidx packets x descriptors per packet.
  wr_dat[15:0]    =  driver_mode ? 16'h0 : c2h_ring_pidx(); // pidx

  issue_reg_write(PF_DMA_BAR_INDEX, 16'h804, wr_dat[31 :0 ]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h808, wr_dat[63 :32]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h80C, wr_dat[95 :64]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h810, wr_dat[127:96]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h814, wr_dat[159:128]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h818, wr_dat[191:160]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h81C, wr_dat[223:192]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h820, wr_dat[255:224]);

//-------------- Ind Dire CTXT CMD 0x844 [17:7] Qid : CMD MDMA_CTXT_CMD_WR=1 ---------
// [17:7] QID
// [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
// [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
// 0      BUSY : 0
//        00000000000_01_0000_0 : 0x20
  wr_dat = {14'h0,st_q[10:0],7'b0100000};
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  if (enable_c2h_cmpt) begin
  //-------------- Program Completion (CMPT) Context for C2H --------------------------
  cmpt_ring_addr = CMPT_RING_BASE + (st_q * GLBL_RNG_SIZE * 8);
  `uvm_info("C2H_ST", $sformatf("Programming CMPT context for QID %0d, ring addr 0x%0h", st_q, cmpt_ring_addr), UVM_MEDIUM)

  // Program the timer table entry BEFORE the CMPT context references it, so
  // the slot's latched expiry target is valid from the moment it's allocated.
  // C2H_TIMER_CNT<idx> is at its standard offset 0xA00 + idx*4.
  if (cmpt_timer_test) begin
    `uvm_info("C2H_ST", $sformatf(
      "Programming CMPT timer threshold table[%0d]=%0d (addr 0x%0h)",
      cmpt_timer_idx, cmpt_timer_thresh, 16'hA00 + (cmpt_timer_idx * 4)), UVM_MEDIUM)
    issue_reg_write(PF_DMA_BAR_INDEX, 16'hA00 + (cmpt_timer_idx * 4), cmpt_timer_thresh[31:0]);
  end

  wr_dat = 256'h0;
  wr_dat[0]       = 1'b1;                     // en_stat_desc
  wr_dat[1]       = 1'b0;                     // en_int
  wr_dat[4:2]     = cmpt_timer_test ? 3'h4 : 3'h1;  // trig_mode: USER_TIMER (4) if +CMPT_TIMER_TEST, else EVERY
  wr_dat[12:5]    = {4'h0, pf_fnc[3:0]};      // func_id
  wr_dat[20:17]   = 4'h0;                     // counter_idx
  wr_dat[24:21]   = cmpt_timer_test ? cmpt_timer_idx[3:0] : 4'h0;  // timer_idx
  wr_dat[27]      = 1'b1;                     // color = 1
  wr_dat[89:32]   = cmpt_ring_addr[63:6];     // baddr_64
  wr_dat[91:90]   = 2'h0;                     // desc_size = 8B
  wr_dat[107:92]  = 16'h0;                    // pidx
  wr_dat[123:108] = 16'h0;                    // cidx
  wr_dat[124]     = 1'b1;                     // valid
  wr_dat[142:132] = 'd4;                      // vec (MSI-X vector 4)
  wr_dat[146]     = 1'b1;                     // dir_c2h

  issue_reg_write(PF_DMA_BAR_INDEX, 16'h804, wr_dat[31:0]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h808, wr_dat[63:32]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h80C, wr_dat[95:64]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h810, wr_dat[127:96]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h814, wr_dat[159:128]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h818, wr_dat[191:160]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h81C, wr_dat[223:192]);
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h820, wr_dat[255:224]);

  cmpt_exp = wr_dat;

  // Command: write CMPT context (CMD_WR=01, SEL=0110)
  wr_dat = {14'h0, st_q[10:0], 7'b0101100};
  issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  // Read the completion context back before any traffic and compare all of
  // it with what was written (IND_CTXT_CMD RD, sel=6). Kept for the
  // static-field check after the transfers.
  TSK_IND_CTXT_READBACK(PF_DMA_BAR_INDEX, st_q, 4'h6 /*CMPT*/, cmpt_exp, IND_CTXT_200B_MASK,
                        "after write", rt_ok);
  cmpt_ctxt_exp[st_q] = cmpt_exp;
  cmpt_ctxt_bar[st_q] = PF_DMA_BAR_INDEX;

  //-------------- Update CIDX for Completion Ring ------------------------------------
  wr_dat = 256'h0;
  wr_dat[27]    = 1'b1;   // en_stat_desc
  wr_dat[26:24] = cmpt_timer_test ? 3'h4 : 3'h1;   // trig_mode: USER_TIMER (4) if +CMPT_TIMER_TEST, else EVERY
  wr_dat[15:0]  = 16'h0;  // sw_cidx = 0
  wr_add = QUEUE_PTR_PF_ADDR + (st_q * 16) + 12;  // CIDX offset
  issue_reg_write(PF_DMA_BAR_INDEX, wr_add[31:0], wr_dat[31:0]);
  end

  // Driver mode: post the descriptors with the C2H PIDX doorbell, after the
  // contexts and the completion CIDX.
  if (driver_mode) begin
    wr_add = QUEUE_PTR_PF_ADDR + (st_q * 16) + 8;  // C2H PIDX offset
    issue_reg_write(PF_DMA_BAR_INDEX, wr_add[31:0], {irq_en, c2h_ring_pidx()} | 32'h0);
    // Non-posted read on the same path: the doorbell has landed when it returns.
    issue_reg_read(PF_DMA_BAR_INDEX, wr_add[31:0], , , , READ_DATA);
  end

  // C2H data comes from the example design's C2H generator (c2h_source_ctrl
  // in design_1_wrapper) when software starts a burst: pidx packets to this
  // queue, started once the descriptors posted above have reached the DMA.
  TSK_C2H_SRC_BURST(int'(port_id), st_q, int'(pidx), int'(c2h_eff_pkt_bytes()));

  for (iter=0; iter < NUM_ITER; iter=iter+1) begin
    // The descriptors were posted above: by the C2H PIDX doorbell in driver
    // mode, otherwise by the SW_C2H commit carrying the PIDX.
    fork
      `uvm_info("C2H_ST", $sformatf("pidx %0d value written to qid:%0d",c2h_ring_pidx(),qid), UVM_MEDIUM)
    join
  end

  if (irq_en) begin
    TSK_CHECK_MSIX_TLP(.vec(11'd2), .fnc(8'(fnc)));  // C2H uses vec=2
  end

  end
  endtask


/************************************************************
Task : TSK_QDMA_VF_ST_H2C_TEST
Inputs : fnc (VF function number), qid (relative), port_id, irq_en
Outputs : None
Description : AXI-ST H2C test for VF functions.
  VF-specific BAR/function handling with the ST context programming of
  TSK_QDMA_ST_H2C_TEST.
*************************************************************/
task TSK_QDMA_VF_ST_H2C_TEST;

  input [7:0]  fnc;
  input [10:0] qid;      // relative qid within VF
  input [2:0]  port_id;
  input        irq_en;

  logic [11:0] q_count;
  logic [11:0] q_base;
  logic [11:0] hw_qid;
  integer ptr_upt_dma_bar_idx;
  logic [31:0] trq_sel_queue_addr;
  localparam   ST_DSC_SZ = 16;
  localparam   NUM_ITER  = 1;
  bit  [63:0]  dsc_base;
  bit [7:0]    pfn;
  bit [7:0]    vfn;
  bit [255:0]  wr_dat;
  bit [31:0]   wr_add;
  bit          is_pf;
  bit [31:0]   READ_DATA;

  begin

  TOTAL_VFS[0] = 16'h20;
  NUM_VFS[0] = NUM_VF;
  FIRST_VF_OFFSET[0] = VF_OFFSET;

  TSK_FIND_PF_VF_NUM(fnc, pfn, vfn);

  if (fnc < NUM_PFS) begin
    `uvm_info("VF_H2C_ST", $sformatf("Launching H2C ST for PF%0d, QID#%d", pfn, qid), UVM_MEDIUM)
    trq_sel_queue_addr = 32'h18000;
    q_base  = QUEUE_PER_PF * fnc;
    q_count = QUEUE_PER_PF;
    ptr_upt_dma_bar_idx = PF_DMA_BAR_INDEX;
  end
  else begin
    `uvm_info("VF_H2C_ST", $sformatf("Launching H2C ST for PF%0d, VF%0d, QID#%d", pfn, vfn, qid), UVM_MEDIUM)
    trq_sel_queue_addr = 32'h3000;
    q_base  = QUEUE_PER_PF * NUM_PFS + (fnc - VF_OFFSET) * QUEUE_PER_VF;
    q_count = QUEUE_PER_VF;
    ptr_upt_dma_bar_idx = VF_DMA_BAR_INDEX;
    if (qid > QUEUE_PER_VF - 1)
      `uvm_fatal("VF_H2C_ST", $sformatf("VF QID#%0d exceeds maximum %0d", qid, QUEUE_PER_VF-1))
  end

  // Global programming
  if (!glbl_pgm_done)
    TSK_GLBL_PGM;

  if (!fnc_map_pgm_done[fnc])
    TSK_FNC_MAP_PGM(fnc, q_base, q_count);

  hw_qid   = qid + q_base;
  dsc_base = H2C_DSC_ADDR + hw_qid * GLBL_RNG_SIZE * ST_DSC_SZ;
  `uvm_info("VF_H2C_ST", $sformatf("q_base:%0d qid:%0d hw_qid:%0d dsc_base:0x%0h", q_base, qid, hw_qid, dsc_base), UVM_MEDIUM)

  // Load ST descriptors into host memory
  TSK_INIT_QDMA_ST_DATA_H2C(fnc, hw_qid, dsc_base);

  // DMA Engine ID Read
  issue_reg_read(PF_DMA_BAR_INDEX, 16'h00, , , , READ_DATA);

  // VF0 only: a short delay lets the PF task's context-data writes
  // (0x804-0x820) complete before this VF's context is staged.
  if (fnc == NUM_PFS) #500ns;

  // Clear HW CTXT for H2C
  wr_dat[31:0] = {hw_qid[10:0], 2'h0, 4'b0011, 1'b0};
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  if (irq_en)
    TSK_PROGRAM_MSIX_VEC_TABLE(fnc);

  // AXI-ST H2C SW context (is_mm=0, bypass=1, dsc_sz=16B, port_id set)
  wr_dat[255:140] = 'd0;
  wr_dat[139]     = 'd0;         // int_aggr
  wr_dat[138:128] = 'd1;         // vec MSI-X Vector
  wr_dat[127:64]  = {dsc_base_hi, dsc_base[31:0]};    // dsc base
  wr_dat[63]      = 1'b0;        // is_mm (streaming mode)
  wr_dat[62]      = 1'b0;        // mrkr_dis
  wr_dat[61]      = 1'b0;        // irq_req
  wr_dat[60]      = 1'b0;        // err_wb_sent
  wr_dat[59:58]   = 2'b0;        // err
  wr_dat[57]      = 1'b0;        // irq_no_last
  wr_dat[56:54]   = port_id;     // port_id
  wr_dat[53]      = irq_en;      // irq_en
  wr_dat[52]      = 1'b0;        // wbk_en
  wr_dat[51]      = 1'b0;        // mm_chn
  wr_dat[50]      = st_dsc_bypass[0];        // bypass (see ST_DSC_BYPASS plusarg)
  wr_dat[49:48]   = 2'b01;       // dsc_sz, 16 bytes
  wr_dat[47:44]   = 4'h1;        // rng_sz
  wr_dat[43:41]   = 3'h0;        // reserved
  wr_dat[40:37]   = 4'h0;        // fetch_max
  wr_dat[36]      = 1'b0;        // atc
  wr_dat[35]      = 1'b0;        // wbi_intvl_en
  wr_dat[34]      = 1'b1;        // wbi_chk
  wr_dat[33]      = use_dsc_crdt ? 1'b1 : 1'b0;  // fcrd_en — enable for dsc_crdt mode
  wr_dat[32]      = 1'b1;        // qen
  wr_dat[31:25]   = 7'h0;        // reserved
  wr_dat[24:17]   = fnc;         // func_id (VF fnc, not PF pfn)
  wr_dat[16]      = 1'b0;        // irq_arm
  // PIDX: 0 in driver mode (the doorbell below posts the descriptors);
  // otherwise pidx, so the SW_H2C commit itself posts them.
  wr_dat[15:0]    = driver_mode ? 16'h0 : pidx[15:0];  // pidx

  issue_reg_write(ptr_upt_dma_bar_idx, 16'h804, wr_dat[31 :0 ]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h808, wr_dat[63 :32]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h80C, wr_dat[95 :64]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h810, wr_dat[127:96]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h814, wr_dat[159:128]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h818, wr_dat[191:160]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h81C, wr_dat[223:192]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h820, wr_dat[255:224]);

  // Program SW H2C CTXT
  wr_dat[31:0] = {hw_qid[10:0], 2'b01, 4'b0001, 1'b0};
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  // Start DMA transfer. Driver mode posts the descriptors with the H2C PIDX
  // doorbell; the context above then carries PIDX 0, so the doorbell is the
  // queue's only admission. Without driver mode the SW_H2C commit carries the
  // PIDX and no doorbell is rung: a doorbell repeating the same PIDX after
  // such a commit admits the queue a second time.
  is_pf = (fnc < NUM_PFS) ? 1 : 0;
  if (driver_mode) begin
    wr_add = trq_sel_queue_addr + (qid * 16) + 4;  // H2C PIDX offset
    issue_reg_write(ptr_upt_dma_bar_idx, wr_add[31:0], {irq_en, pidx[15:0]} | 32'h0, is_pf, pfn, vfn);
  end
  for (int iter = 0; iter < NUM_ITER; iter++) begin
    fork
`ifdef USE_DSC_CRDT
      // The context above sets fcrd_en, so the queue fetches no more than the
      // credits it has received: send one credit per posted descriptor, as
      // the PF stream task does after its doorbell.
      if (use_dsc_crdt && dsc_crdt_agnt != null) begin
         dsc_crdt_seq crdt_seq = dsc_crdt_seq::type_id::create("crdt_seq");
         crdt_seq.qid   = hw_qid[11:0];
         crdt_seq.crdt  = pidx;
         crdt_seq.dir   = 1'b0;  // H2C
         crdt_seq.fence = 1'b0;
         `uvm_info("VF_H2C_ST", $sformatf("dsc_crdt H2C: crdt=%0d hw_qid=%0d fnc=%0d", pidx, hw_qid, fnc), UVM_MEDIUM)
         crdt_seq.start(dsc_crdt_agnt.seqr);
      end
`endif
      begin
         `uvm_info("VF_H2C_ST", $sformatf("pidx %0d written to hw_qid:%0d fnc:%0d", pidx, hw_qid, fnc), UVM_MEDIUM)
      end
    join
  end


  if (irq_en)
    TSK_CHECK_MSIX_TLP(.vec(11'd1), .fnc(8'(fnc)));

  end
endtask

/************************************************************
Task : TSK_QDMA_VF_ST_C2H_TEST
Inputs : fnc (VF function number), qid (relative), port_id, irq_en
Outputs : None
Description : AXI-ST C2H test for VF functions.
  VF-specific BAR/function handling with the ST context programming of
  TSK_QDMA_ST_C2H_TEST.
*************************************************************/
task TSK_QDMA_VF_ST_C2H_TEST;

  input [7:0]  fnc;
  input [10:0] qid;      // relative qid within VF
  input [2:0]  port_id;
  input        irq_en;

  logic [11:0] q_count;
  logic [11:0] q_base;
  logic [11:0] hw_qid;
  integer ptr_upt_dma_bar_idx;
  logic [31:0] trq_sel_queue_addr;
  localparam   ST_DSC_SZ = 16;
  localparam   NUM_ITER  = 1;
  bit  [63:0]  dsc_base;
  bit  [63:0]  cmpt_ring_addr;
  bit [255:0]  cmpt_exp;
  bit          rt_ok;
  bit          is_pf;
  bit [7:0]    pfn;
  bit [7:0]    vfn;
  bit [255:0]  wr_dat;
  bit [31:0]   wr_add;
  bit [31:0]   READ_DATA;

  begin

  TOTAL_VFS[0] = 16'h20;
  NUM_VFS[0] = NUM_VF;
  FIRST_VF_OFFSET[0] = VF_OFFSET;

  TSK_FIND_PF_VF_NUM(fnc, pfn, vfn);

  if (fnc < NUM_PFS) begin
    `uvm_info("VF_C2H_ST", $sformatf("Launching C2H ST for PF%0d, QID#%d", pfn, qid), UVM_MEDIUM)
    trq_sel_queue_addr = 32'h18000;
    q_base  = QUEUE_PER_PF * fnc;
    q_count = QUEUE_PER_PF;
    ptr_upt_dma_bar_idx = PF_DMA_BAR_INDEX;
  end
  else begin
    `uvm_info("VF_C2H_ST", $sformatf("Launching C2H ST for PF%0d, VF%0d, QID#%d", pfn, vfn, qid), UVM_MEDIUM)
    trq_sel_queue_addr = 32'h3000;
    q_base  = QUEUE_PER_PF * NUM_PFS + (fnc - VF_OFFSET) * QUEUE_PER_VF;
    q_count = QUEUE_PER_VF;
    ptr_upt_dma_bar_idx = VF_DMA_BAR_INDEX;
    if (qid > QUEUE_PER_VF - 1)
      `uvm_fatal("VF_C2H_ST", $sformatf("VF QID#%0d exceeds maximum %0d", qid, QUEUE_PER_VF-1))
  end

  // Global programming
  if (!glbl_pgm_done)
    TSK_GLBL_PGM;

  if (!fnc_map_pgm_done[fnc])
    TSK_FNC_MAP_PGM(fnc, q_base, q_count);

  hw_qid   = qid + q_base;
  dsc_base = C2H_DSC_ADDR + hw_qid * GLBL_RNG_SIZE * ST_DSC_SZ;
  `uvm_info("VF_C2H_ST", $sformatf("q_base:%0d qid:%0d hw_qid:%0d dsc_base:0x%0h", q_base, qid, hw_qid, dsc_base), UVM_MEDIUM)

  // C2H source packet size for this port, before the context commit
  TSK_C2H_SRC_CFG(port_id);

  // Load C2H-ST descriptors into host memory
  TSK_INIT_QDMA_ST_DATA_C2H(fnc, hw_qid, dsc_base);

  // DMA Engine ID Read
  issue_reg_read(PF_DMA_BAR_INDEX, 16'h00, , , , READ_DATA);

  // Clear HW CTXT for C2H
  wr_dat[31:0] = {hw_qid[10:0], 2'h0, 4'b0010, 1'b0};
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  if (enable_c2h_cmpt) begin
  // Clear CMPT (WRB) CTXT for C2H
  wr_dat[31:0] = {hw_qid[10:0], 2'h0, 4'b0110, 1'b0};  // CMD_CLR, SEL=6 (CMPT)
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();
  end

  if (irq_en)
    TSK_PROGRAM_MSIX_VEC_TABLE(fnc);

  // Prefetch context first (see TSK_QDMA_ST_C2H_TEST).
  if (c2h_pfch)
    TSK_QDMA_C2H_PFCH_CTXT(hw_qid[10:0], port_id);

  // AXI-ST C2H SW context (is_mm=0, bypass=1, dsc_sz=16B, port_id set)
  wr_dat[255:140] = 'd0;
  wr_dat[139]     = 'd0;         // int_aggr
  wr_dat[138:128] = 'd2;         // vec MSI-X Vector (C2H uses vec=2)
  wr_dat[127:64]  = {dsc_base_hi, dsc_base[31:0]};    // dsc base
  wr_dat[63]      = 1'b0;        // is_mm (streaming mode)
  wr_dat[62]      = 1'b0;        // mrkr_dis
  wr_dat[61]      = 1'b0;        // irq_req
  wr_dat[60]      = 1'b0;        // err_wb_sent
  wr_dat[59:58]   = 2'b0;        // err
  wr_dat[57]      = 1'b0;        // irq_no_last
  wr_dat[56:54]   = port_id;     // port_id
  wr_dat[53]      = irq_en;      // irq_en
  wr_dat[52]      = enable_c2h_cmpt;  // wbk_en (enable when CMPT enabled)
  wr_dat[51]      = 1'b0;        // mm_chn
  wr_dat[50]      = st_dsc_bypass[0];        // bypass (see ST_DSC_BYPASS plusarg)
  wr_dat[49:48]   = 2'b00;       // dsc_sz, 8 bytes (C2H stream non-bypass size)
  wr_dat[47:44]   = 4'h1;        // rng_sz
  wr_dat[43:41]   = 3'h0;        // reserved
  wr_dat[40:37]   = 4'h0;        // fetch_max
  wr_dat[36]      = 1'b0;        // atc
  wr_dat[35]      = 1'b0;        // wbi_intvl_en
  wr_dat[34]      = 1'b1;        // wbi_chk
  wr_dat[33]      = c2h_pfch ? 1'b1 : 1'b0;  // fcrd_en: the prefetch engine's credits drive C2H-ST fetches
  wr_dat[32]      = 1'b1;        // qen
  wr_dat[31:25]   = 7'h0;        // reserved
  wr_dat[24:17]   = fnc;         // func_id (VF fnc, not PF pfn)
  wr_dat[16]      = 1'b0;        // irq_arm
  // PIDX: 0 in driver mode (the doorbell below posts the descriptors);
  // otherwise the ring PIDX (pidx packets x descriptors per packet), so the
  // SW_C2H commit itself posts them.
  wr_dat[15:0]    = driver_mode ? 16'h0 : c2h_ring_pidx();  // pidx

  issue_reg_write(ptr_upt_dma_bar_idx, 16'h804, wr_dat[31 :0 ]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h808, wr_dat[63 :32]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h80C, wr_dat[95 :64]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h810, wr_dat[127:96]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h814, wr_dat[159:128]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h818, wr_dat[191:160]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h81C, wr_dat[223:192]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h820, wr_dat[255:224]);

  // Commit the SW C2H context: command {qid, op 1 (write), select 0 (SW C2H),
  // busy}, as the PF C2H task does. Without driver mode the context carries the
  // PIDX, so this commit also posts the descriptors.
  wr_dat[31:0] = {hw_qid[10:0], 2'b01, 4'b0000, 1'b0};
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  if (enable_c2h_cmpt) begin
  //-------------- Program Completion (CMPT) Context for C2H --------------------------
  cmpt_ring_addr = CMPT_RING_BASE + (hw_qid * GLBL_RNG_SIZE * 8);
  `uvm_info("VF_C2H_ST", $sformatf("Programming CMPT context for hw_qid %0d, ring addr 0x%0h", hw_qid, cmpt_ring_addr), UVM_MEDIUM)

  // Program the timer table entry BEFORE the CMPT context references it
  // (see PF-path TSK_QDMA_ST_C2H_TEST for details). The table is global and
  // physical-function only, as the driver programs it from the PF.
  if (cmpt_timer_test) begin
    `uvm_info("VF_C2H_ST", $sformatf(
      "Programming CMPT timer threshold table[%0d]=%0d (addr 0x%0h)",
      cmpt_timer_idx, cmpt_timer_thresh, 16'hA00 + (cmpt_timer_idx * 4)), UVM_MEDIUM)
    issue_reg_write(PF_DMA_BAR_INDEX, 16'hA00 + (cmpt_timer_idx * 4), cmpt_timer_thresh[31:0]);
  end

  wr_dat = 256'h0;
  wr_dat[0]       = 1'b1;                     // en_stat_desc
  wr_dat[1]       = 1'b0;                     // en_int
  wr_dat[4:2]     = cmpt_timer_test ? 3'h4 : 3'h1;  // trig_mode: USER_TIMER (4) if +CMPT_TIMER_TEST, else EVERY
  wr_dat[12:5]    = fnc;                       // func_id
  wr_dat[20:17]   = 4'h0;                     // counter_idx
  wr_dat[24:21]   = cmpt_timer_test ? cmpt_timer_idx[3:0] : 4'h0;  // timer_idx
  wr_dat[27]      = 1'b1;                     // color = 1
  wr_dat[89:32]   = cmpt_ring_addr[63:6];     // baddr_64
  wr_dat[91:90]   = 2'h0;                     // desc_size = 8B
  wr_dat[107:92]  = 16'h0;                    // pidx
  wr_dat[123:108] = 16'h0;                    // cidx
  wr_dat[124]     = 1'b1;                     // valid
  wr_dat[142:132] = 'd4;                      // vec (MSI-X vector 4)
  wr_dat[146]     = 1'b1;                     // dir_c2h

  issue_reg_write(ptr_upt_dma_bar_idx, 16'h804, wr_dat[31:0]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h808, wr_dat[63:32]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h80C, wr_dat[95:64]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h810, wr_dat[127:96]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h814, wr_dat[159:128]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h818, wr_dat[191:160]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h81C, wr_dat[223:192]);
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h820, wr_dat[255:224]);

  cmpt_exp = wr_dat;

  // Command: write CMPT context (CMD_WR=01, SEL=0110)
  wr_dat[31:0] = {hw_qid[10:0], 2'b01, 4'b0110, 1'b0};
  issue_reg_write(ptr_upt_dma_bar_idx, 16'h844, wr_dat[31:0]);
  poll_ctxt_busy();

  // Read the completion context back before any traffic and compare all of
  // it with what was written (IND_CTXT_CMD RD, sel=6). Kept for the
  // static-field check after the transfers.
  TSK_IND_CTXT_READBACK(ptr_upt_dma_bar_idx, hw_qid[10:0], 4'h6 /*CMPT*/, cmpt_exp,
                        IND_CTXT_200B_MASK, "after write", rt_ok);
  cmpt_ctxt_exp[hw_qid[10:0]] = cmpt_exp;
  cmpt_ctxt_bar[hw_qid[10:0]] = ptr_upt_dma_bar_idx;

  //-------------- Update CIDX for Completion Ring ------------------------------------
  is_pf = (fnc < NUM_PFS) ? 1 : 0;
  wr_dat = 256'h0;
  wr_dat[27]    = 1'b1;   // en_stat_desc
  wr_dat[26:24] = cmpt_timer_test ? 3'h4 : 3'h1;   // trig_mode: USER_TIMER (4) if +CMPT_TIMER_TEST, else EVERY
  wr_dat[15:0]  = 16'h0;  // sw_cidx = 0
  wr_add = trq_sel_queue_addr + (qid * 16) + 12;  // CIDX offset
  issue_reg_write(ptr_upt_dma_bar_idx, wr_add[31:0], wr_dat[31:0], is_pf, pfn, vfn);
  end

  is_pf = (fnc < NUM_PFS) ? 1 : 0;

  // Driver mode: post the descriptors with the C2H PIDX doorbell, after the
  // contexts and the completion CIDX.
  if (driver_mode) begin
    wr_add = trq_sel_queue_addr + (qid * 16) + 8;  // C2H PIDX offset
    issue_reg_write(ptr_upt_dma_bar_idx, wr_add[31:0], {irq_en, c2h_ring_pidx()} | 32'h0, is_pf, pfn, vfn);
    // Non-posted read on the same path: the doorbell has landed when it returns.
    issue_reg_read(ptr_upt_dma_bar_idx, wr_add[31:0], is_pf, pfn, vfn, READ_DATA);
  end

  // C2H data comes from the example design's C2H generator (c2h_source_ctrl
  // in design_1_wrapper) when software starts a burst: pidx packets to this
  // queue (absolute queue id), started once the descriptors posted above have
  // reached the DMA.
  TSK_C2H_SRC_BURST(int'(port_id), hw_qid[10:0], int'(pidx), int'(c2h_eff_pkt_bytes()));

  // Without the prefetch engine, dsc_crdt_in credits (USE_DSC_CRDT) let the
  // queue fetch what was posted above.
  for (int iter = 0; iter < NUM_ITER; iter++) begin
    fork
`ifdef USE_DSC_CRDT
      // With the prefetch engine its credits fetch for C2H-ST queues; a test
      // credit on top would exceed what the host posted.
      if (use_dsc_crdt && dsc_crdt_agnt != null && !c2h_pfch) begin
         dsc_crdt_seq crdt_seq = dsc_crdt_seq::type_id::create("crdt_seq");
         crdt_seq.qid   = hw_qid[11:0];
         crdt_seq.crdt  = c2h_ring_pidx();
         crdt_seq.dir   = 1'b1;  // C2H
         crdt_seq.fence = 1'b0;
         `uvm_info("VF_C2H_ST", $sformatf("dsc_crdt C2H: crdt=%0d hw_qid=%0d fnc=%0d", c2h_ring_pidx(), hw_qid, fnc), UVM_MEDIUM)
         crdt_seq.start(dsc_crdt_agnt.seqr);
      end else
`endif
      `uvm_info("VF_C2H_ST", $sformatf("pidx %0d written to hw_qid:%0d fnc:%0d", c2h_ring_pidx(), hw_qid, fnc), UVM_MEDIUM)
    join
  end

  if (irq_en)
    TSK_CHECK_MSIX_TLP(.vec(11'd2), .fnc(8'(fnc)));

  end
endtask


/************************************************************
Task : TSK_PROGRAM_MSIX_VEC_TABLE
Inputs : function number
Outputs : None
Description : Program the MSIX vector table
*************************************************************/
task TSK_PROGRAM_MSIX_VEC_TABLE;
  input [7:0] fnc_i;
  integer     i;
  bit [31:0]  msix_base;
  integer     bar_idx;
  bit [7:0]   pfn, vfn;
  bit         is_pf;
begin
  // Select BAR and table base depending on PF vs VF.
  // Read the MSI-X Table Offset/BIR from the function's own MSI-X capability
  // (populated by seq_cap_traverse during enumeration in shim_layer.sv) rather
  // than assuming a fixed offset.
  TSK_FIND_PF_VF_NUM(fnc_i, pfn, vfn);
  if (fnc_i < NUM_PFS) begin
    bar_idx   = pdev_ep.msi_x.table_bar;
    msix_base = pdev_ep.msi_x.table_offset;
    is_pf     = 1'b1;
  end else begin
    // pdev_ep.vf[0] is a null placeholder pushed before the enumeration loop
    // in shim_layer.sv; VF index vfn (0-based) is stored at pdev_ep.vf[vfn+1].
    bar_idx   = pdev_ep.vf[vfn+1].msi_x.table_bar;
    msix_base = pdev_ep.vf[vfn+1].msi_x.table_offset;
    is_pf     = 1'b0;
  end

  `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
    "Programming MSI-X VT: fnc=%0d pfn=%0d vfn=%0d bar=%0d base=0x%0h",
    fnc_i, pfn, vfn, bar_idx, msix_base), UVM_MEDIUM)

  // MSI-X host target address: placed in the 4KB gap between H2C data area and
  // H2C descriptor rings (H2C_DAT_SRC_ADDR + H2C_DAT_SIZE = 0xB1000).
  // This range is within the PCIe address window declared by the Avery VIP RC.
  begin
    bit [31:0] msix_host_base;
    // PER-FUNCTION base, so concurrent interrupts on the same vector from
    // different functions do not collide on one host DWORD.
    // 32 B per function (MSIX_VEC_PER_FNC=8 x 4 B) indexed by the ABSOLUTE
    // function number, so every function owns a disjoint region. Worst case is
    // MAX_PF(4) + 8 VFs = 12 functions -> 384 B, inside the 4 KB gap this area
    // sits in. Keying on fnc_i also lets the scoreboard attribute an MSI-X MWr
    // to a function.
    msix_host_base = 32'(H2C_DAT_SRC_ADDR + H2C_DAT_SIZE)
                     + 32'(fnc_i) * 32'(MSIX_VEC_PER_FNC) * 32'd4;

    // Each VF's MSI-X table lives at offset msix_base (from that VF's OWN
    // discovered MSI-X capability, pdev_ep.vf[vfn+1].msi_x.table_offset)
    // inside THAT VF's OWN BAR aperture -- common to every VF in the group
    // (VFs share the same capability layout), not a per-VF displacement
    // within one shared window.
    // issue_reg_write resolves a VF write to vf0_base + vfn*bar_sz.
    for (i=0; i<MSIX_VEC_PER_FNC; i=i+1) begin
      issue_reg_write(bar_idx, msix_base+16*i+0*4, msix_host_base + i*4, is_pf, pfn, vfn); // addr_lo
      issue_reg_write(bar_idx, msix_base+16*i+1*4, 32'h00000000,         is_pf, pfn, vfn); // addr_hi
      issue_reg_write(bar_idx, msix_base+16*i+2*4, 32'hFACE0000 + i,     is_pf, pfn, vfn); // data
      issue_reg_write(bar_idx, msix_base+16*i+3*4, 32'h00000000,         is_pf, pfn, vfn); // ctrl (unmasked)
    end

    `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
      "MSI-X VT programmed: fnc=%0d is_pf=%0b vfn=%0d bar=%0d offset=0x%0h (%0d entries)",
      fnc_i, is_pf, vfn, bar_idx, msix_base, MSIX_VEC_PER_FNC), UVM_LOW)

    // ---- VERIFY-AFTER-WRITE -------------------------------------------------
    // The table writes above are POSTED memory writes: no completion, no error
    // path. If the target function's BAR aperture is not being decoded, all of
    // them are dropped SILENTLY and the table simply stays unprogrammed -- which
    // presents downstream as CPM asserting msix_grant AND msix_error together,
    // indistinguishable from "msix_enable is clear".
    //
    // That the write task ran is not evidence that the writes landed. Reading
    // the table back separates the two directly, per function.
    begin
      bit [31:0] rb_addr, rb_data, rb_ctrl;
      int        mism;
      mism = 0;
      for (i=0; i<MSIX_VEC_PER_FNC; i=i+1) begin
        issue_reg_read(bar_idx, msix_base+16*i+0*4, is_pf, pfn, vfn, rb_addr);
        issue_reg_read(bar_idx, msix_base+16*i+2*4, is_pf, pfn, vfn, rb_data);
        // DW3 = Vector Control. Bit 0 is the per-vector MASK and it RESETS TO 1
        // (masked). That makes it the one field in the entry whose failed write
        // is SILENT: addr_lo and data reset to 0, so a dropped write to either
        // shows up as a readback mismatch below, but a dropped write to DW3
        // leaves the vector masked and every other check still passes.
        //
        // A masked vector is a reason CPM refuses delivery. The capability's
        // function_mask is a different register from this per-entry mask.
        issue_reg_read(bar_idx, msix_base+16*i+3*4, is_pf, pfn, vfn, rb_ctrl);
        if (rb_ctrl[0] !== 1'b0) begin
          mism++;
          `uvm_error("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
            "MSI-X VECTOR MASKED fnc=%0d is_pf=%0b vfn=%0d vec=%0d: Vector Control DW3 = 0x%08h, mask bit still 1 after writing 0. The vector cannot be delivered and CPM will answer msix_error. Either the DW3 write did not reach this function's table aperture, or the entry is being re-masked.",
            fnc_i, is_pf, vfn, i, rb_ctrl))
        end
        if (rb_addr !== (msix_host_base + i*4) || rb_data !== (32'hFACE0000 + i)) begin
          mism++;
          `uvm_error("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
            "MSI-X VT READBACK MISMATCH fnc=%0d is_pf=%0b vfn=%0d vec=%0d: addr_lo wrote 0x%08h read 0x%08h, data wrote 0x%08h read 0x%08h -- the write did not land (posted write dropped, or the BAR aperture for this function is not decoded)",
            fnc_i, is_pf, vfn, i,
            msix_host_base + i*4, rb_addr, 32'hFACE0000 + i, rb_data))
        end
      end
      if (mism == 0)
        `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
          "MSI-X VT readback OK: fnc=%0d is_pf=%0b vfn=%0d -- all %0d entries verified in the DUT",
          fnc_i, is_pf, vfn, MSIX_VEC_PER_FNC), UVM_LOW)
      else
        `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
          "MSI-X VT readback: fnc=%0d is_pf=%0b vfn=%0d -- %0d of %0d entries did NOT land",
          fnc_i, is_pf, vfn, mism, MSIX_VEC_PER_FNC), UVM_LOW)
    end
  end

  // Enable MSI-X in PCIe config space for this function by setting the
  // msix_enable bit (bit 31 of DW0 in the MSI-X Capability Control register).
  //
  // CPM6 checks the function's MSI-X enable. When it is 0, CPM6 asserts both
  // msix_grant AND msix_error for every interrupt request; the DMA treats the
  // grant as success, so the host never receives the MSI-X message.
  begin
    bit         cap_err;
    bit [31:0]  cap_dw0;
    if (is_pf) begin
      env.shim.api.read_cap_dw(pdev_ep.bdf, .cap(CAP_MSI_X), .offset(0),
                               .data(cap_dw0), .err(cap_err));
      cap_dw0[31] = 1'b1;  // msix_enable = 1
      cap_dw0[30] = 1'b0;  // function_mask = 0 (interrupts not globally masked)
      env.shim.api.write_cap_dw(pdev_ep.bdf, .cap(CAP_MSI_X), .offset(0),
                                .be(4'b1100), .data(cap_dw0), .err(cap_err));
    end else begin
      // Avery VIP pdev_ep.vf[] is 1-based: vf[0]=null, vf[1]=VF0, vf[2]=VF1, ...
      // TSK_FIND_PF_VF_NUM returns 0-based vfn, so use vfn+1 as the array index.
      if ((vfn+1) >= pdev_ep.vf.size() || pdev_ep.vf[vfn+1] == null)
        `uvm_fatal("TSK_PROGRAM_MSIX_VEC_TABLE",
          $sformatf("VF[%0d] not found in pdev_ep.vf[] (size=%0d, index=%0d)", vfn, pdev_ep.vf.size(), vfn+1))
      env.shim.api.read_cap_dw(pdev_ep.vf[vfn+1].bdf, .cap(CAP_MSI_X), .offset(0),
                               .data(cap_dw0), .err(cap_err));
      cap_dw0[31] = 1'b1;  // msix_enable = 1
      cap_dw0[30] = 1'b0;  // function_mask = 0
      env.shim.api.write_cap_dw(pdev_ep.vf[vfn+1].bdf, .cap(CAP_MSI_X), .offset(0),
                                .be(4'b1100), .data(cap_dw0), .err(cap_err));
    end
    `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
      "MSI-X cap enabled: fnc=%0d pfn=%0d vfn=%0d cap_dw0=0x%08h err=%0b",
      fnc_i, pfn, vfn, cap_dw0, cap_err), UVM_MEDIUM)
  end

  // No readback check: PCIe MSI-X vector table registers are write-only per spec  -
  // reads return 0x00000000 regardless of what was written.  Correct programming
  // is confirmed by the MSIX_MWR TLP the DUT sends after queue completion.
  // See TSK_CHECK_MSIX_TLP.
  `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
    "MSI-X VT programmed: fnc=%0d bar=%0d base=0x%0h (7 entries, vec 0-6)",
    fnc_i, bar_idx, msix_base), UVM_MEDIUM)
end
endtask // TSK_PROGRAM_MSIX_VEC_TABLE

/************************************************************
Task : TSK_PROGRAM_PCIE_DEVCTL
Inputs : mrrs_val - Max Read Request Size (0=128B, 1=256B, 2=512B, 3=1024B, 4=2048B, 5=4096B)
         mps_val  - Max Payload Size      (0=128B, 1=256B, 2=512B, 3=1024B)
Outputs : None
Description : Program the PCIe Device Control Register (PCIe Express Capability
              offset +0x08) via CfgWr TLP from Root Complex.  Sets MRRS and MPS
              fields while preserving all other Device Control bits (NoSnoop,
              ExtTag, Relaxed Ordering, error reporting enables).

              This programs the EP's config space as seen from the PCIe link,
              which is what the HDMA engine uses for MRd/MWr TLP sizing.
              Called after enumeration, before DMA operations.

              Override via +PCIE_MRRS / +PCIE_MPS.
*************************************************************/
task TSK_PROGRAM_PCIE_DEVCTL;
  input [2:0] mrrs_val;
  input [2:0] mps_val;

  bit         cap_err;
  bit [31:0]  devctl_dw;
  bit [15:0]  devctl_before, devctl_after;

  // Read Device Control + Device Status (DW2 of PCIe Express Capability)
  env.shim.api.read_cap_dw(pdev_ep.bdf, .cap(CAP_PCI_EXP), .offset(2),
                           .data(devctl_dw), .err(cap_err));
  if (cap_err)
    `uvm_warning("TSK_PROGRAM_PCIE_DEVCTL",
      "Failed to read Device Control Register  -  skipping MRRS/MPS programming")
  else begin
    devctl_before = devctl_dw[15:0];

    // Modify MRRS (bits [14:12]) and MPS (bits [7:5]) in Device Control
    devctl_dw[14:12] = mrrs_val;
    devctl_dw[7:5]   = mps_val;
    devctl_after = devctl_dw[15:0];

    // Write back Device Control only (lower 2 bytes); Device Status (upper 2) is RO
    env.shim.api.write_cap_dw(pdev_ep.bdf, .cap(CAP_PCI_EXP), .offset(2),
                              .be(4'b0011), .data(devctl_dw), .err(cap_err));
    if (cap_err)
      `uvm_warning("TSK_PROGRAM_PCIE_DEVCTL",
        "Failed to write Device Control Register")

    `uvm_info("TSK_PROGRAM_PCIE_DEVCTL", $sformatf(
      "Device Control programmed: MRRS=%0d (%0dB) MPS=%0d (%0dB)  before=0x%04h after=0x%04h err=%0b",
      mrrs_val, (128 << mrrs_val), mps_val, (128 << mps_val),
      devctl_before, devctl_after, cap_err), UVM_NONE)
  end
endtask // TSK_PROGRAM_PCIE_DEVCTL

/************************************************************
Task : TSK_CHECK_MSIX_TLP
Inputs : vec   - MSI-X vector index (0-based, matches TSK_PROGRAM_MSIX_VEC_TABLE entry)
         fnc   - function number (PF or VF, for log only)
Outputs : None
Description : Wait for and verify the MSI-X Memory Write TLP generated by the
              CPM6 after the DMA raises its MSI-X request.
              The expected TLP target address and data are derived from the
              MVT entries written by TSK_PROGRAM_MSIX_VEC_TABLE:
                addr = { 32'h0, (H2C_DAT_SRC_ADDR+H2C_DAT_SIZE) + vec*4 }
                data = entry[2*4] = 0xFACE0000 + vec
              Detection mechanism: the qdma_mem_callback.write_mem_cb() fires for
              every MWr TLP received at the RP VIP (registered via
              env.shim.vip.append_callback() in each test's main_phase).
              dma_req_processor.run_phase() consumes callbacks from dma_trfr_bus
              and increments h2c_msix_cnt (vec==1) or c2h_msix_cnt (vec==2) when
              the MWr address falls in the MSI-X window.  This task snapshots the
              relevant counter, then polls it (1ns steps) until it increments by 1,
              confirming that exactly one MSI-X MWr TLP for this vec was received.
              Timeout: MSIX_TLP_TIMEOUT, scaled as 200us + (pidx*DMA_BYTE_CNT)/20000
              us so it covers the full DMA + IRQ path at any transfer size.
*************************************************************/
task TSK_CHECK_MSIX_TLP;
  input [10:0] vec;   // MSI-X vector index (0..6 for the 7 entries programmed)
  input [7:0]  fnc;   // function number (for message context only)

  logic [63:0] exp_addr;
  logic [31:0] exp_data;
  // Snapshot of the dma_req_processor MSI-X counter taken before polling.
  // dma_req_processor increments h2c_msix_cnt (vec=1) / c2h_msix_cnt (vec=2)
  // inside run_phase when write_mem_cb delivers an MWr in the MSI-X window.
  int          cnt_before;
  // Scaled with the transfer size: the deadline has to cover the REMAINDER of
  // the DMA plus the IRQ path, and the DMA part grows with pidx * DMA_BYTE_CNT.
  // A fixed component (descriptor fetch, arbitration and IRQ latency) plus a
  // per-byte term, both doubled for margin.
  time         MSIX_TLP_TIMEOUT = 200us +
                                  (1us * ((longint'(pidx) * longint'(DMA_BYTE_CNT)) / 20000));

  begin
    exp_addr = {32'h0, 32'(H2C_DAT_SRC_ADDR + H2C_DAT_SIZE) + 32'(vec) * 4}; // 0xB1000+vec*4
    exp_data = 32'hFACE0000 + 32'(vec);

    // Snapshot counter before DMA completes to detect exactly +1.
    // Any vector in the programmed 7-entry table is supported: dma_req_processor
    // counts every MSI-X MWr per vector in msix_vec_cnt[]. h2c/c2h (vec 1/2) use
    // their dedicated counters; other vectors -- e.g. the mailbox vector -- use
    // the array.
    if (vec == 11'd1)
      cnt_before = dma_req_proc.h2c_msix_cnt;
    else if (vec == 11'd2)
      cnt_before = dma_req_proc.c2h_msix_cnt;
    else if (vec <= 11'd6)
      cnt_before = dma_req_proc.msix_vec_cnt[int'(vec)];
    else
      cnt_before = 0; // outside the programmed table; timeout path emits the error

    `uvm_info("TSK_CHECK_MSIX_TLP", $sformatf(
      "Waiting for MSI-X MWr TLP: vec=%0d fnc=%0d exp_addr=0x%016h exp_data=0x%08h cnt_before=%0d",
      vec, fnc, exp_addr, exp_data, cnt_before), UVM_MEDIUM)

    // Poll dma_req_proc MSI-X counter until it increments (TLP detected) or
    // the timeout expires.  The Avery VIP calls write_mem_cb() synchronously
    // when the MWr TLP is received; qdma_mem_callback forwards it into
    // dma_trfr_bus.req_mbx; dma_req_processor drains the mailbox and updates
    // the counter, all within the same simulation time step.  The #1ns tick
    // here lets the simulator settle before re-checking the counter.
    begin : MSIX_POLL_BLOCK
      automatic time deadline = $time + MSIX_TLP_TIMEOUT;
      automatic bit timed_out  = 0;
      forever begin
        #1ns;
        if (vec == 11'd1 && dma_req_proc.h2c_msix_cnt > cnt_before) break;
        if (vec == 11'd2 && dma_req_proc.c2h_msix_cnt > cnt_before) break;
        if (vec != 11'd1 && vec != 11'd2 && vec <= 11'd6 &&
            dma_req_proc.msix_vec_cnt[int'(vec)] > cnt_before) break;
        if ($time >= deadline) begin
          timed_out = 1;
          break;
        end
      end
      if (timed_out) begin
        `uvm_error("TSK_CHECK_MSIX_TLP", $sformatf(
          "TIMEOUT %0t: MSI-X MWr TLP NOT received for vec=%0d fnc=%0d exp_addr=0x%016h exp_data=0x%08h. h2c_msix_cnt=%0d c2h_msix_cnt=%0d",
          MSIX_TLP_TIMEOUT, vec, fnc, exp_addr, exp_data,
          dma_req_proc.h2c_msix_cnt, dma_req_proc.c2h_msix_cnt))
      end else begin
        `uvm_info("TSK_CHECK_MSIX_TLP", $sformatf(
          "PASS: MSI-X MWr TLP received for vec=%0d fnc=%0d exp_addr=0x%016h exp_data=0x%08h",
          vec, fnc, exp_addr, exp_data), UVM_MEDIUM)
      end
    end
  end
endtask // TSK_CHECK_MSIX_TLP

/************************************************************
Task : TSK_FIND_PF_VF_NUM
Inputs : function number
Outputs : None
Description : Find out the associated PF# of a VF
*************************************************************/

task TSK_FIND_PF_VF_NUM;
  input  [7:0] fnc;
  output [7:0] pfn;
  output [7:0] vfn;

  begin

    if (fnc < NUM_PFS) begin
      pfn = fnc;
      vfn = 'h0;
    end
    else begin
      bit hit;
      pfn = '0;
      vfn = '0;
      hit = 1'b0;
      for (int pf_i=0; pf_i<NUM_PFS; pf_i=pf_i+1) begin
        // X in either bound makes the range compare below evaluate false, which
        // returns vfn=0 -- indistinguishable from a legitimate VF0 decode. Fail
        // here instead: a wrong-but-plausible function index sends config writes
        // to the wrong VF and is near-impossible to spot downstream.
        if ($isunknown(FIRST_VF_OFFSET[pf_i]) || $isunknown(NUM_VFS[pf_i]))
          `uvm_fatal("TSK_FIND_PF_VF_NUM", $sformatf(
            "SR-IOV geometry unresolved for pf_i=%0d (FIRST_VF_OFFSET=%0h NUM_VFS=%0h) decoding fnc=%0d. Every VF would decode to vfn=0 and alias onto VF0.",
            pf_i, FIRST_VF_OFFSET[pf_i], NUM_VFS[pf_i], fnc))
        `uvm_info("TSK_FIND_PF_VF_NUM", $sformatf(
          "  pf_i=%0d FIRST_VF_OFFSET=%0d NUM_VFS=%0d range=[%0d..%0d)",
          pf_i, FIRST_VF_OFFSET[pf_i], NUM_VFS[pf_i],
          FIRST_VF_OFFSET[pf_i] + pf_i,
          FIRST_VF_OFFSET[pf_i] + NUM_VFS[pf_i] + pf_i), UVM_MEDIUM)
        if (
            (fnc >= FIRST_VF_OFFSET[pf_i] + pf_i) &&
            (fnc < FIRST_VF_OFFSET[pf_i] + NUM_VFS[pf_i] + pf_i)
           ) begin
          pfn = pf_i[7:0];
          vfn = fnc - FIRST_VF_OFFSET[pf_i] - pf_i;
          hit = 1'b1;
        end
      end
      if (!hit)
        `uvm_fatal("TSK_FIND_PF_VF_NUM", $sformatf(
          "fnc=%0d falls in no PF VF range -- returning vfn=0 would alias it onto VF0.", fnc))
    end
    `uvm_info("TSK_FIND_PF_VF_NUM", $sformatf(" fnc %0d Translates to pfn%0d and vfn%0d", fnc, pfn, vfn), UVM_MEDIUM)

  end
endtask

// =================================================================
// SLT Test Tasks, invoked via +TEST_MODE=<mode>
// All tasks parameterized so subclass main_phase passes its config.
// =================================================================

// ---------------------------------------------------------------
// TSK_SLT_ST_PERF_TEST — ST DMA Performance
// ---------------------------------------------------------------
task TSK_SLT_ST_PERF_TEST(input int num_pf_test, input int num_vf_test,
                            input int num_q_test, input string slt_direction,
                            input logic slt_irq_en);
   time test_start, test_end;
   int qid_counter;
   bit [2:0] port_id;

   `uvm_info("SLT_ST_PERF", "=== ST Performance Test Start ===", UVM_NONE)
   `uvm_info("SLT_ST_PERF", $sformatf("DMA_BYTE_CNT=%0d, PIDX=%0d, PFs=%0d, VFs=%0d, direction=%s, ports=%0d",
                                       DMA_BYTE_CNT, pidx, num_pf_test, num_vf_test, slt_direction, num_dma_ports), UVM_NONE)

   test_start = $time;
   qid_counter = 0;

   if (num_pf_test > 0) begin
      qid = 11'h1;
      for (int i = 0; i < num_pf_test; i++) begin
         pf_fnc = 4'(i);
         for (int j = 0; j < num_q_test; j++) begin
            port_id = 3'((qid_counter % num_dma_ports) + dma_port_base);
            if (slt_direction != "C2H") TSK_QDMA_ST_H2C_TEST(qid + j, port_id, slt_irq_en);
            if (slt_direction != "H2C") TSK_QDMA_ST_C2H_TEST(qid + j, port_id, slt_irq_en);
            qid_counter++;
         end
      end
   end

   if (num_vf_test > 0) begin
      qid = 11'h1; fnc = VF_OFFSET;
      for (int i = 0; i < num_vf_test; i++) begin
         for (int j = 0; j < num_q_test; j++) begin
            port_id = 3'((qid_counter % num_dma_ports) + dma_port_base);
            if (slt_direction != "C2H") TSK_QDMA_VF_ST_H2C_TEST(fnc + i, qid + j, port_id, slt_irq_en);
            if (slt_direction != "H2C") TSK_QDMA_VF_ST_C2H_TEST(fnc + i, qid + j, port_id, slt_irq_en);
            qid_counter++;
         end
      end
   end

   fork
      begin dma_req_proc.done_ev.wait_trigger(); end
      begin #TIMEOUT; if (!dma_req_proc.test_done)
         `uvm_error("SLT_ST_PERF", "Timeout waiting for ST DMA completion") end
   join_any
   disable fork;

   test_end = $time;
   TSK_SLT_REPORT_PERF("ST", test_start, test_end);
endtask : TSK_SLT_ST_PERF_TEST

// ---------------------------------------------------------------
// TSK_SLT_REPORT_PERF — Shared performance report for MM and ST
// ---------------------------------------------------------------
task TSK_SLT_REPORT_PERF(input string mode, input time t_start, input time t_end);
   `uvm_info("SLT_PERF", $sformatf("=== %s Performance Results ===", mode), UVM_NONE)

   foreach (dma_req_proc.h2c_bytes[q]) begin
      if (dma_req_proc.h2c_last_tlp_time[q] > dma_req_proc.h2c_first_tlp_time[q]) begin
         real elapsed_ns = real'(dma_req_proc.h2c_last_tlp_time[q] - dma_req_proc.h2c_first_tlp_time[q]) / 1000.0;
         real bw = real'(dma_req_proc.h2c_bytes[q]) * 8.0 / elapsed_ns;
         `uvm_info("SLT_PERF", $sformatf("H2C QID %0d: %0d bytes, %.1f ns, %.3f Gbps",
                                          q, dma_req_proc.h2c_bytes[q], elapsed_ns, bw), UVM_NONE)
      end
   end

   foreach (dma_req_proc.c2h_bytes[q]) begin
      if (dma_req_proc.c2h_last_tlp_time[q] > dma_req_proc.c2h_first_tlp_time[q]) begin
         real elapsed_ns = real'(dma_req_proc.c2h_last_tlp_time[q] - dma_req_proc.c2h_first_tlp_time[q]) / 1000.0;
         real bw = real'(dma_req_proc.c2h_bytes[q]) * 8.0 / elapsed_ns;
         `uvm_info("SLT_PERF", $sformatf("C2H QID %0d: %0d bytes, %.1f ns, %.3f Gbps",
                                          q, dma_req_proc.c2h_bytes[q], elapsed_ns, bw), UVM_NONE)
      end
   end

   begin
      longint total_h2c = 0, total_c2h = 0, total_bytes;
      foreach (dma_req_proc.h2c_bytes[q]) total_h2c += dma_req_proc.h2c_bytes[q];
      foreach (dma_req_proc.c2h_bytes[q]) total_c2h += dma_req_proc.c2h_bytes[q];
      total_bytes = total_h2c + total_c2h;

      if (t_end > t_start) begin
         real total_ns = real'(t_end - t_start) / 1000.0;
         real throughput_gbps = real'(total_bytes) * 8.0 / total_ns;
         `uvm_info("SLT_PERF", $sformatf("Aggregate: H2C=%0d, C2H=%0d bytes, Total=%.3f Gbps, Elapsed=%.1f ns",
                                          total_h2c, total_c2h, throughput_gbps, total_ns), UVM_NONE)
      end
   end

   if (dma_req_proc.dma_first_tlp_time > 0) begin
      real latency_ns = real'(dma_req_proc.dma_first_tlp_time) / 1000.0;
      `uvm_info("SLT_PERF", $sformatf("First TLP latency: %.1f ns", latency_ns), UVM_NONE)
   end

   // ---------------------------------------------------------------
   // Per-port byte-total confirmation: confirms the assigned traffic actually
   // ARRIVED, reading the axi_pl_protocol_monitor h2c_bytes_written counter.
   // Only ports 0/1 have a valid axi_pl_env.proto_mon[] mapping — ports >=2
   // are reported as unconfirmable rather than risk
   // indexing proto_mon[] against the wrong port_id (proto_mon[2] is PL3,
   // port_id=3, not a "port 2").
   // ---------------------------------------------------------------
   begin
      int p;
      for (p = 0; p < num_dma_ports; p++) begin
         if (p < 2) begin
            if (axi_pl_env.proto_mon[p] != null) begin
               `uvm_info("SLT_PERF_PORT_COVERAGE",
                  $sformatf("port=%0d h2c_bytes_written=%0d", p, axi_pl_env.proto_mon[p].h2c_bytes_written), UVM_NONE)
               if (axi_pl_env.proto_mon[p].h2c_bytes_written == 0)
                  `uvm_error("SLT_PERF_PORT_COVERAGE",
                     $sformatf("port=%0d shows ZERO AXI-PL bytes written at end of test despite being an active DMA port (NUM_DMA_PORTS=%0d)  -  traffic never actually reached this port.",
                                p, num_dma_ports))
            end else begin
               `uvm_error("SLT_PERF_PORT_COVERAGE",
                  $sformatf("port=%0d is an active DMA port (NUM_DMA_PORTS=%0d) but axi_pl_env.proto_mon[%0d] is not bound (vif not connected?)  -  cannot confirm it received traffic.",
                             p, num_dma_ports, p))
            end
         end else begin
            `uvm_info("SLT_PERF_PORT_COVERAGE",
               $sformatf("port=%0d requested by NUM_DMA_PORTS=%0d but this environment only has confirmed valid DMA targets on ports 0,1  -  byte-total cannot be confirmed for this port.",
                          p, num_dma_ports), UVM_NONE)
         end
      end
   end

   `uvm_info("SLT_PERF", $sformatf("*** %s PERFORMANCE TEST PASSED ***", mode), UVM_NONE)
endtask : TSK_SLT_REPORT_PERF

// IND_CTXT_CMD register layout:
//   cmd[31:18] = reserved (0)
//   cmd[17:7]  = qid (11 bits)
//   cmd[6:5]   = op
//   cmd[4:1]   = sel
//   cmd[0]     = busy (HW clears when done)
localparam bit [15:0] DRV_BIND_IND_CTXT_CMD_OFFSET = 16'h844;
localparam bit [15:0] DRV_BIND_IND_CTXT_DATA0_OFFSET = 16'h804;

localparam bit [1:0] DRV_BIND_OP_CLR = 2'h0;
localparam bit [1:0] DRV_BIND_OP_WR  = 2'h1;
localparam bit [1:0] DRV_BIND_OP_RD  = 2'h2;
localparam bit [1:0] DRV_BIND_OP_INV = 2'h3;

localparam bit [3:0] DRV_BIND_SEL_SW_C2H   = 4'h0;
localparam bit [3:0] DRV_BIND_SEL_SW_H2C   = 4'h1;
localparam bit [3:0] DRV_BIND_SEL_HW_C2H   = 4'h2;
localparam bit [3:0] DRV_BIND_SEL_HW_H2C   = 4'h3;
localparam bit [3:0] DRV_BIND_SEL_CR_C2H   = 4'h4;
localparam bit [3:0] DRV_BIND_SEL_CR_H2C   = 4'h5;
localparam bit [3:0] DRV_BIND_SEL_WRB      = 4'h6;
localparam bit [3:0] DRV_BIND_SEL_PFTCH    = 4'h7;
localparam bit [3:0] DRV_BIND_SEL_INT_COAL = 4'h8;
localparam bit [3:0] DRV_BIND_SEL_RSVD_9   = 4'h9;  // reserved on CPM6
localparam bit [3:0] DRV_BIND_SEL_HST_PROF = 4'hA;  // reserved on CPM6
localparam bit [3:0] DRV_BIND_SEL_TIMER    = 4'hB;
localparam bit [3:0] DRV_BIND_SEL_FMAP     = 4'hC;
localparam bit [3:0] DRV_BIND_SEL_FNC_STS  = 4'hD;  // reserved on CPM6

// Poll cap for IND_CTXT ops. Normal ops clear BUSY in 0-1 polls; a stuck op
// fails after ~26us, before the UVM phase timeout.
localparam int DRV_BIND_BUSY_POLL_LIMIT = 64;

// Build a 32-bit IND_CTXT_CMD word per the register layout above.
function automatic bit [31:0] build_ind_ctxt_cmd(input bit [10:0] qid,
                                                  input bit [3:0]  sel,
                                                  input bit [1:0]  op,
                                                  input bit        busy = 1'b0);
  bit [31:0] cmd;
  cmd          = 32'h0;
  cmd[18:7]    = qid;     // qid:12 at bits[18:7], as the driver writes it
  cmd[6:5]     = op;
  cmd[4:1]     = sel;
  // The driver writes every indirect command with busy=0. The host-readable
  // 0x844[0] is a write-latched copy of the written bit[0], so a busy=1 write
  // never polls clear. Default is busy=0.
  cmd[0]       = busy;
  return cmd;
endfunction

// Non-fatal IND_CTXT_CMD BUSY poll. Returns ok=1 if BUSY cleared within
// limit, ok=0 on timeout. Records actual poll count in polls.
task automatic poll_ctxt_busy_nf(output bit ok, output int polls);
  bit [31:0] rd;
  ok    = 1'b0;
  polls = 0;
  do begin
    issue_reg_read(PF_DMA_BAR_INDEX, DRV_BIND_IND_CTXT_CMD_OFFSET, , , , rd);
    polls++;
    if (rd[0] === 1'b0) begin
      ok = 1'b1;
      return;
    end
  end while (polls < DRV_BIND_BUSY_POLL_LIMIT);
endtask

// Issue an IND_CTXT_CMD and poll BUSY (non-fatal). Returns ok = 1 on
// clean completion, 0 on poll-timeout.
task automatic issue_ind_ctxt_op_nf(input bit [10:0] qid,
                                     input bit [3:0]  sel,
                                     input bit [1:0]  op,
                                     output bit       ok,
                                     output int       polls,
                                     input bit        busy = 1'b0);  // busy=0, as the driver writes it
  bit [31:0] cmd;
  cmd = build_ind_ctxt_cmd(qid, sel, op, busy);
  issue_reg_write(PF_DMA_BAR_INDEX, DRV_BIND_IND_CTXT_CMD_OFFSET, cmd);
  poll_ctxt_busy_nf(ok, polls);
endtask

// Read back the 8 IND_CTXT_DATA registers (256 bits) after an op=RD.
task automatic read_ind_ctxt_data(output bit [255:0] data);
  bit [31:0] rd;
  data = 256'h0;
  for (int i = 0; i < 8; i++) begin
    issue_reg_read(PF_DMA_BAR_INDEX,
                   DRV_BIND_IND_CTXT_DATA0_OFFSET + 16'(i*4), , , , rd);
    data[i*32 +: 32] = rd;
  end
endtask

//---------------------------------------------------------------------------
// Indirect context write / read-back helpers (any BAR, any sel).
// IND_CTXT_CMD is written with BUSY=0, as the driver does: 0x844[0] reads back
// the bit[0] of the last command write, not the command state, so a command
// written with BUSY=1 never polls clear. GLBL_ERR_STAT[14:9]
// (IND_CTXT_CMD_ERR) is sampled after each command; this IP returns 0 for the
// whole register, so the sample is reported, not relied on.
//---------------------------------------------------------------------------

task automatic TSK_IND_CTXT_POLL(input int bar, output bit ok);
  bit [31:0] rd;
  ok = 1'b0;
  for (int p = 0; p < DRV_BIND_BUSY_POLL_LIMIT; p++) begin
    issue_reg_read(bar, DRV_BIND_IND_CTXT_CMD_OFFSET, , , , rd);
    if (rd[0] === 1'b0) begin
      ok = 1'b1;
      return;
    end
  end
endtask

task automatic TSK_IND_CTXT_ERR_STAT(input string tag, output bit err);
  bit [31:0] stat;
  issue_reg_read(PF_DMA_BAR_INDEX, GLBL_ERR_STAT_OFFSET, , , , stat);
  err = (stat !== 32'hBAD_ACCE5) && (stat[14:9] != 6'h0);
  if (err)
    `uvm_error("CMPT_CTXT_RT", $sformatf(
      "%s GLBL_ERR_STAT=0x%08h IND_CTXT_CMD_ERR[14:9]=0x%02h", tag, stat, stat[14:9]))
  else
    `uvm_info("CMPT_CTXT_RT", $sformatf(
      "%s GLBL_ERR_STAT=0x%08h IND_CTXT_CMD_ERR[14:9]=0", tag, stat), UVM_MEDIUM)
endtask

// W4 fields the driver programs. Completion context (sel=6): full_upd W4[1],
// vec W4[14:4], int_aggr W4[15], dir_c2h W4[18]. SW context (sel=0/1):
// vec W4[10:0], int_aggr W4[11].
function automatic string ind_ctxt_w4_str(input bit [3:0] sel, input bit [255:0] d);
  if (sel == DRV_BIND_SEL_WRB)
    return $sformatf("W4=0x%08h full_upd=%0d vec=%0d int_aggr=%0d dir_c2h=%0d",
                     d[159:128], d[129], d[142:132], d[143], d[146]);
  return $sformatf("W4=0x%08h vec=%0d int_aggr=%0d", d[159:128], d[138:128], d[139]);
endfunction

// Write DATA0..7 (mask registers all-ones) and issue WR.
task automatic TSK_IND_CTXT_WRITE(input int        bar,
                                  input bit [10:0] qid,
                                  input bit [3:0]  sel,
                                  input bit [255:0] data,
                                  input string     tag,
                                  output bit       ok);
  bit err;
  for (int i = 0; i < 8; i++)
    issue_reg_write(bar, DRV_BIND_IND_CTXT_DATA0_OFFSET + 16'(i*4), data[i*32 +: 32]);
  for (int i = 0; i < 8; i++)
    issue_reg_write(bar, 16'h824 + 16'(i*4), 32'hFFFF_FFFF);
  issue_reg_write(bar, DRV_BIND_IND_CTXT_CMD_OFFSET, build_ind_ctxt_cmd(qid, sel, DRV_BIND_OP_WR));
  TSK_IND_CTXT_POLL(bar, ok);
  if (!ok)
    `uvm_error("CMPT_CTXT_RT", $sformatf("%s WR qid=%0d sel=%0d: BUSY did not clear", tag, qid, sel))
  TSK_IND_CTXT_ERR_STAT($sformatf("%s WR", tag), err);
  ok = ok && !err;
endtask

// Issue RD, read DATA0..7 and compare with exp under cmp_mask. A mismatch is
// an error; the differing words and the decoded W4 fields are reported.
task automatic TSK_IND_CTXT_READBACK(input int         bar,
                                     input bit [10:0]  qid,
                                     input bit [3:0]   sel,
                                     input bit [255:0] exp,
                                     input bit [255:0] cmp_mask,
                                     input string      tag,
                                     output bit        ok);
  bit [255:0] rdat, diff;
  bit [31:0]  rd;
  bit         busy_ok, err;
  issue_reg_write(bar, DRV_BIND_IND_CTXT_CMD_OFFSET, build_ind_ctxt_cmd(qid, sel, DRV_BIND_OP_RD));
  TSK_IND_CTXT_POLL(bar, busy_ok);
  rdat = '0;
  for (int i = 0; i < 8; i++) begin
    issue_reg_read(bar, DRV_BIND_IND_CTXT_DATA0_OFFSET + 16'(i*4), , , , rd);
    rdat[i*32 +: 32] = rd;
  end
  TSK_IND_CTXT_ERR_STAT($sformatf("%s RD", tag), err);
  diff = (rdat ^ exp) & cmp_mask;
  ok   = busy_ok && !err && (diff == '0);
  if (!busy_ok)
    `uvm_error("CMPT_CTXT_RT", $sformatf("%s RD qid=%0d sel=%0d: BUSY did not clear", tag, qid, sel))
  if (diff == '0)
    `uvm_info("CMPT_CTXT_RT", $sformatf(
      "%s qid=%0d sel=%0d READBACK MATCH  read %s", tag, qid, sel, ind_ctxt_w4_str(sel, rdat)), UVM_NONE)
  else begin
    `uvm_error("CMPT_CTXT_RT", $sformatf(
      "%s qid=%0d sel=%0d READBACK MISMATCH  wrote %s  read %s", tag, qid, sel,
      ind_ctxt_w4_str(sel, exp), ind_ctxt_w4_str(sel, rdat)))
    for (int i = 0; i < 8; i++)
      if (diff[i*32 +: 32] != '0)
        `uvm_info("CMPT_CTXT_RT", $sformatf(
          "%s qid=%0d sel=%0d   W%0d wrote=0x%08h read=0x%08h differing bits=0x%08h",
          tag, qid, sel, i, exp[i*32 +: 32], rdat[i*32 +: 32], diff[i*32 +: 32]), UVM_NONE)
  end
endtask

// Completion-context fields that nothing but software writes: function,
// counter/timer index, ring size index, ring base, entry size, valid,
// full_upd, ovf_chk_dis, at, vec, int_aggr, dis_intr_on_vf, dir_c2h.
// Excluded: en_stat_desc/en_int/trig_mode and cidx (CMPT CIDX register),
// int_st, color and pidx (completion engine), err/usr_int_pend/isr_done, vio.
function automatic bit [255:0] cmpt_ctxt_static_mask();
  bit [255:0] m;
  m          = '0;
  m[24:5]    = '1;
  m[31:28]   = '1;
  m[91:32]   = '1;
  m[124]     = 1'b1;
  m[144:129] = '1;
  m[146]     = 1'b1;
  return m;
endfunction

// Read back the completion context of every C2H-ST queue set up in this run
// and compare its static fields with what was written at queue setup.
task automatic TSK_CMPT_CTXT_POST_CHECK();
  bit [10:0] q;
  bit        ok;
  int        n, n_ok;
  n = 0;
  n_ok = 0;
  if (cmpt_ctxt_exp.first(q)) begin
    do begin
      TSK_IND_CTXT_READBACK(cmpt_ctxt_bar[q], q, DRV_BIND_SEL_WRB, cmpt_ctxt_exp[q],
                            cmpt_ctxt_static_mask(), "after transfers (static fields)", ok);
      n++;
      if (ok) n_ok++;
    end while (cmpt_ctxt_exp.next(q));
  end
  `uvm_info("CMPT_CTXT_RT", $sformatf(
    "after transfers: %0d/%0d completion contexts read back with static fields intact", n_ok, n), UVM_NONE)
endtask

//---------------------------------------------------------------------------
// TSK_CMPT_CTXT_RT_TEST -- completion-context round trip, register access
// only (no queue setup, no traffic). Writes the completion context of one
// queue through IND_CTXT_DATA/IND_CTXT_CMD and reads it back:
//   1. W4=0x0004_0030 (dir_c2h=1, vec=3, int_aggr=0), other words a valid
//      context (status entries on, trigger EVERY, colour 1, ring base,
//      8-byte entries, valid W3[28])
//   2. control: SW C2H context (sel=0), vec=3 int_aggr=0 at W4[10:0]/[11]
//   3. vec = 0, 1, 3, 5 with int_aggr=0, dir_c2h=1
//   4. int_aggr=1, vec=3, dir_c2h=1
// Each round trip compares DATA0..6 exactly. Any mismatch is an error.
//---------------------------------------------------------------------------
task automatic TSK_CMPT_CTXT_RT_TEST(input bit [10:0] qid);
  bit [255:0] base, d;
  bit [63:0]  ring;
  bit         ok_wr, ok_rd;
  int         n, n_ok;
  int         vecs[4] = '{0, 1, 3, 5};
  n    = 0;
  n_ok = 0;
  ring = CMPT_RING_BASE + (qid * GLBL_RNG_SIZE * 8);
  base          = '0;
  base[0]       = 1'b1;          // en_stat_desc
  base[4:2]     = 3'h1;          // trig_mode EVERY
  base[27]      = 1'b1;          // color
  base[89:32]   = ring[63:6];    // ring base
  base[124]     = 1'b1;          // valid (W3[28])
  `uvm_info("CMPT_CTXT_RT", $sformatf(
    "=== completion-context round trip, qid=%0d, register access only ===", qid), UVM_NONE)

  // 1. The values the driver writes
  d = base;
  d[159:128] = 32'h0004_0030;
  TSK_IND_CTXT_WRITE(PF_DMA_BAR_INDEX, qid, DRV_BIND_SEL_WRB, d, "case1 W4=0x40030", ok_wr);
  TSK_IND_CTXT_READBACK(PF_DMA_BAR_INDEX, qid, DRV_BIND_SEL_WRB, d, IND_CTXT_200B_MASK,
                        "case1 W4=0x40030", ok_rd);
  n++;
  if (ok_wr && ok_rd) n_ok++;

  // 2. Control: SW C2H context, queue disabled, vec=3 int_aggr=0
  d = '0;
  d[138:128] = 11'd3;
  TSK_IND_CTXT_WRITE(PF_DMA_BAR_INDEX, qid, DRV_BIND_SEL_SW_C2H, d, "case2 control SW_C2H vec=3", ok_wr);
  TSK_IND_CTXT_READBACK(PF_DMA_BAR_INDEX, qid, DRV_BIND_SEL_SW_C2H, d, IND_CTXT_200B_MASK,
                        "case2 control SW_C2H vec=3", ok_rd);
  n++;
  if (ok_wr && ok_rd) n_ok++;

  // 3. vec sweep, int_aggr=0
  foreach (vecs[i]) begin
    d = base;
    d[142:132] = 11'(vecs[i]);
    d[146]     = 1'b1;
    TSK_IND_CTXT_WRITE(PF_DMA_BAR_INDEX, qid, DRV_BIND_SEL_WRB, d,
                       $sformatf("case3 vec=%0d int_aggr=0", vecs[i]), ok_wr);
    TSK_IND_CTXT_READBACK(PF_DMA_BAR_INDEX, qid, DRV_BIND_SEL_WRB, d, IND_CTXT_200B_MASK,
                          $sformatf("case3 vec=%0d int_aggr=0", vecs[i]), ok_rd);
    n++;
    if (ok_wr && ok_rd) n_ok++;
  end

  // 4. int_aggr=1
  d = base;
  d[142:132] = 11'd3;
  d[143]     = 1'b1;
  d[146]     = 1'b1;
  TSK_IND_CTXT_WRITE(PF_DMA_BAR_INDEX, qid, DRV_BIND_SEL_WRB, d, "case4 vec=3 int_aggr=1", ok_wr);
  TSK_IND_CTXT_READBACK(PF_DMA_BAR_INDEX, qid, DRV_BIND_SEL_WRB, d, IND_CTXT_200B_MASK,
                        "case4 vec=3 int_aggr=1", ok_rd);
  n++;
  if (ok_wr && ok_rd) n_ok++;

  if (n_ok == n)
    `uvm_info("CMPT_CTXT_RT", $sformatf("SUMMARY: %0d/%0d round trips clean", n_ok, n), UVM_NONE)
  else
    `uvm_error("CMPT_CTXT_RT", $sformatf("SUMMARY: %0d/%0d round trips clean", n_ok, n))
endtask

endclass
