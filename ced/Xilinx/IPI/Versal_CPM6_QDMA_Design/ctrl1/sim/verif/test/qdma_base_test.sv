// qdma_base_test -- base class for this CED's MM DMA test
// (test_qdma_h2c_c2h_mm_Mfnc_MQ.sv).
//
// Provides: PCIe BAR register access (issue_reg_write/issue_reg_read,
// poll_ctxt_busy), QDMA global ring-size and function-map programming
// (TSK_GLBL_PGM, TSK_FNC_MAP_PGM), PF/VF number resolution
// (TSK_FIND_PF_VF_NUM), per-qid H2C/C2H descriptor ring and host-buffer
// setup (TSK_INIT_QDMA_MM_DATA_H2C/C2H), MSI-X vector table programming and
// completion detection (TSK_PROGRAM_MSIX_VEC_TABLE, TSK_CHECK_MSIX_TLP),
// PCIe Device Control (MRRS/MPS) programming (TSK_PROGRAM_PCIE_DEVCTL), and
// the two top-level H2C/C2H MM DMA test tasks (TSK_QDMA_MM_H2C_TEST,
// TSK_QDMA_MM_C2H_TEST) that the test calls per PF and per queue.
//
// PF-only: test_qdma_h2c_c2h_mm_Mfnc_MQ.sv never sets fnc >= NUM_PFS, so
// TSK_FIND_PF_VF_NUM's VF branch is never reached; its "Mfnc" covers
// multiple PFs (looping pf_fnc 0..NUM_PF_TEST-1), not VFs. FIRST_VF_OFFSET/
// NUM_VFS are initialized to this IP build's real VF_OFFSET/NUM_VF anyway,
// so a future VF-aware test resolves fnc->pfn/vfn correctly from the start.

import cpm6_qdma_params_pkg::*;

class qdma_base_test extends base_ep_test;

  `uvm_component_utils(qdma_base_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  byte host_mem[int];

  amd_mem_tlp mem_tlp;
  pcie_device pdev_ep;

  parameter int NUM_PFS = NUM_PF; // supported by the PCIe controller

  integer    i, j, k;
  integer    PF_DMA_BAR_INDEX = 1;
  integer    PF_USR_BAR_INDEX = 2;
  integer    VF_DMA_BAR_INDEX = 1;
  integer    VF_USR_BAR_INDEX = 2;
  bit [3:0]  pf_fnc = 0;          // 0-based PF function number for the current PF under test

  // qdma_mem_callback checks this before logging per-TLP detail.
  int shared_log_fd = 0;

  // MSI-X vector table + PBA are in BAR0 for both PF and VF.
  integer    PF_MSIX_BAR_INDEX  = 0;
  integer    VF_MSIX_BAR_INDEX  = 0;
  bit [31:0] PF_MSIX_VEC_OFFSET = 32'h30000;
  bit [31:0] PF_MSIX_PBA_OFFSET = 32'h34000;
  bit [31:0] VF_MSIX_VEC_OFFSET = 32'h4000;
  bit [31:0] VF_MSIX_PBA_OFFSET = 32'h4800;

  bit [15:0] pidx = 5;
  bit [31:0] DMA_BYTE_CNT = 32'h1000;
  bit [31:0] GLBL_RNG_SIZE = RING_SIZE;
  integer    QUEUE_PER_PF  = 32;  // overridden in build_phase; +QUEUE_PER_PF=<N> to change
  bit [31:0] QUEUE_PTR_PF_ADDR = 32'h00018000;
  parameter int Tcq = 1;

  // Round-robin AXI-PL port assignment for H2C: each new qid gets the next
  // port in sequence (mod num_dma_ports) so traffic is spread evenly
  // regardless of qid values. C2H always reads from PL1 independent of this.
  int num_dma_ports  = 2;
  int dma_assign_ctr = 0;
  int qid_to_port[int];

  bit        glbl_pgm_done = 0;
  bit [255:0] fnc_map_pgm_done = '0; // sized generously; bit[pf_fnc] is used by the MM basic tests

  // PF/VF topology tables consulted by TSK_FIND_PF_VF_NUM and the VF DMA
  // test tasks below 
  logic [15:0] FIRST_VF_OFFSET[NUM_PFS-1:0] = '{default: 16'(VF_OFFSET)};
  reg    [15:0] NUM_VFS[NUM_PFS-1:0]        = '{default: 16'(NUM_VF)};
  // 0x20 (32): a generic upper-bound placeholder for max VFs-per-PF capacity in
  // this table, independent of how many VFs this build's BD actually
  // instantiates (see CPM6_CONFIG's VFG0_TOTAL_VFS, typically 8) -- nothing
  // reads this assuming exactly 32 VFs exist.
  reg    [15:0] TOTAL_VFS[NUM_PFS-1:0]      = '{default: 16'h20};

  // 64-bit descriptor ring base upper word (dsc_base itself stays 32-bit --
  // host_mem[int] is a 32-bit-indexed associative array in this CED). Default 0
  // keeps every existing PF test bit-identical; the
  // VF DMA tasks below program it into the SW context's dsc_base[63:32].
  bit [31:0] dsc_base_hi = 32'h0;

  // Set use_vf_enum=1 (in a test's end_of_elaboration_phase) to activate
  // VF enumeration on the VIP -- see start_of_simulation_phase below.
  bit use_vf_enum = 0;
  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    if (use_vf_enum)
      env.shim.vip.set("bus_enum_skip_vf_enable", 0); // activate VFs during enumeration
  endfunction

  dma_req_processor dma_req_proc;
  host_req_bus       dma_trfr_bus;

  // --- PS wizard NOC / DMA IRQ monitor ---
  pswizard_agent     psw_agnt;

  // --- QDMA periphery monitor ---
  qdma_periph_agent  qdma_periph_agnt;
  // Per-HDMA-channel lifecycle status map —
  // subscribes to qdma_periph_agnt.ap + psw_agnt.ap, connected in connect_phase below.
  dma_channel_status_tracker chan_status_tracker;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    dma_trfr_bus = host_req_bus::type_id::create("dma_trfr_bus", this);
    dma_req_proc = dma_req_processor::type_id::create("dma_req_proc", this);
    uvm_config_db#(host_req_bus)::set(this, "dma_req_proc", "dma_trfr_bus", dma_trfr_bus);

    // Parse +NUM_DMA_PORTS=N plusarg: number of AXI-PL ports to use (1-4,
    // default 1). Queues are assigned to ports sequentially (not by qid) for
    // even distribution.
    if (!$value$plusargs("NUM_DMA_PORTS=%d", num_dma_ports))
      num_dma_ports = 2;
    `uvm_info("qdma_base_test", $sformatf("NUM_DMA_PORTS=%0d (H2C distributed by qid%%num_dma_ports; C2H always PL1)", num_dma_ports), UVM_MEDIUM)

    // Parse +QUEUE_PER_PF=N plusarg: PF queue-space reservation used to compute
    // VF q_base (q_base = QUEUE_PER_PF*NUM_PFS + (fnc-VF_OFFSET)*QUEUE_PER_VF).
    // Default 32, exposed as a runtime override for tuning without a rebuild.
    if (!$value$plusargs("QUEUE_PER_PF=%d", QUEUE_PER_PF))
      QUEUE_PER_PF = 32;
    `uvm_info("qdma_base_test", $sformatf("QUEUE_PER_PF=%0d", QUEUE_PER_PF), UVM_MEDIUM)

    // shared_log_fd was declared but never opened/registered in this CED
    // (dma_req_processor.sv's own "log_fd not found in config_db" warning
    // traces back to this) -- opening it here is a prerequisite for
    // pswizard_monitor.sv, which uvm_fatals if "log_fd" isn't in config_db.
    if (shared_log_fd == 0) begin
      shared_log_fd = $fopen("cpm6_qdma_dbg.log", "w");
      uvm_config_db#(int)::set(this, "*", "log_fd", shared_log_fd);
    end

    // --- PS wizard NOC / DMA IRQ monitor ---
    // bind_pswizard (bound to cpm6_qdma, this CED's BD top module) registers
    // "vif_pswizard" in config_db. Monitors CPM_PCIE_AXI_NOC0,
    // CPM_PCIE_AXI_NOC1 AXI handshakes and the 128-bit DMA completion IRQ
    // vector -- and, via its own run_phase blocking on
    // "wait(vif.rst_n === 1'b1)", gives independent, ground-truth
    // confirmation of whether ps_wizard_0_pl0_resetn actually deasserts.
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
    // bind_qdma_periph (bound to cpm6_qdma, this CED's BD top module) registers
    // "vif_qdma_periph" in config_db. No tm_dsc_sts bridging here (no
    // bind.tm_dsc_sts.sv in
    // this project; the monitor's own get for it is non-fatal, see
    // bind.qdma_periph.sv's header note). Full tm_dsc_sts coverage for this
    // project comes from the pre-existing qdma_boundary_probe.sv instead.
    begin
      virtual qdma_periph_if vif_qper;
      qdma_periph_cfg cfg_qper = qdma_periph_cfg::type_id::create("cfg_qper", this);
      uvm_config_db#(qdma_periph_cfg)::set(this, "qdma_periph_agnt*", "cfg", cfg_qper);
      uvm_config_db#(int)::set(this, "qdma_periph_agnt*", "log_fd", shared_log_fd);
      if (uvm_config_db#(virtual qdma_periph_if)::get(null, "*", "vif_qdma_periph", vif_qper))
        uvm_config_db#(virtual qdma_periph_if)::set(this, "qdma_periph_agnt", "vif", vif_qper);
      else
        `uvm_warning("qdma_base_test",
          "vif_qdma_periph not found  - bind.qdma_periph.sv may not have run")
      qdma_periph_agnt = qdma_periph_agent::type_id::create("qdma_periph_agnt", this);
    end

    // --- per-HDMA-channel status tracker ---
    // log_fd already broadcast globally via the "*" set above.
    chan_status_tracker = dma_channel_status_tracker::type_id::create("chan_status_tracker", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    dma_req_proc.dma_trfr_bus = dma_trfr_bus;

    // Connect DBI/NOC0/PL0-1 events -> per-channel status tracker
    if (chan_status_tracker != null) begin
      if (qdma_periph_agnt != null) qdma_periph_agnt.ap.connect(chan_status_tracker.qper_imp);
      if (psw_agnt         != null) psw_agnt.ap.connect(chan_status_tracker.psw_imp);
    end
  endfunction

  virtual task pre_main_phase(uvm_phase phase);
    super.pre_main_phase(phase);
    phase.raise_objection(this);
    // Configure PS VIP for QDMA -- must run after CDO loads.
    `ifdef CPM6_VIVADO
      `ifndef QEMU_PS
        `uvm_info(get_type_name(), "Configuring PS VIP for QDMA operation", UVM_MEDIUM)
        ps_vip_api.ps_gen_clock(13, 333.33);  // psnocpci0axi_aclk
        ps_vip_api.ps_gen_clock(14, 333.33);  // psnocpci1axi_aclk
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
      `uvm_info(get_type_name, $sformatf("number of pdevs = %0d", env.shim.container.pdev.size), UVM_MEDIUM)
      pdev_ep = env.shim.container.get_pdev_EP;
      // Program PCIe Device Control Register (MRRS/MPS) after enumeration.
      // Defaults: MRRS=3 (1024B), MPS=2 (512B). Override via +PCIE_MRRS=<0-5> / +PCIE_MPS=<0-3>.
      // MPS=2 is required so the DUT's setting matches the RC/VIP side's own
      // Device Control register, which defaults to 512B.
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

      mem_tlp = amd_mem_tlp::type_id::create("tlp");
      mem_tlp.build_wr(addr + reg_offset, .data(data_arr));
      env.shim.api.send_mem(mem_tlp);
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

    if(is_pf) begin
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

      mem_tlp = amd_mem_tlp::type_id::create("tlp");
      // Read 1 DW from BAR. blocking(DONE) makes send_mem wait for the
      // completion (tr.wait_done) and write the payload back into tlp.data.
      mem_tlp.build_rd(addr + reg_offset, 1, .blocking(DONE));
      env.shim.api.send_mem(mem_tlp);
      data = mem_tlp.data[0];
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

  /************************************************************
  Task : TSK_INIT_QDMA_MM_DATA_H2C
  Description : Stage the H2C descriptor ring (dsc_base) and the H2C source
                data pattern (at HOST_DAT_BUF_ADDR) that the ring's
                descriptors point at.
  *************************************************************/
  task TSK_INIT_QDMA_MM_DATA_H2C (input bit [7:0] fnc, input bit [10:0] qid, input bit [63:0] dsc_base);
    integer k;
  begin
    bit [63:0] H2C_DAT_DST_ADDR;
    bit [63:0] HOST_DAT_BUF_ADDR;
    int        port_sel;

    // H2C always writes to PL0 BRAM (independent of C2H, which always reads
    // from PL1 -- see TSK_INIT_QDMA_MM_DATA_C2H). Direction determines the
    // port, not qid or num_dma_ports.
    if (!qid_to_port.exists(int'(qid))) begin
      qid_to_port[int'(qid)] = 0;
      dma_assign_ctr++;
    end
    port_sel = qid_to_port[int'(qid)];
    case (port_sel)
      0:       H2C_DAT_DST_ADDR = H2C_DAT_DST_ADDR0 + 64'(get_dma_slot(qid, DMA_BYTE_CNT)) * DMA_BYTE_CNT;
      1:       H2C_DAT_DST_ADDR = H2C_DAT_DST_ADDR1 + 64'(get_dma_slot(qid, DMA_BYTE_CNT)) * DMA_BYTE_CNT;
      2:       H2C_DAT_DST_ADDR = H2C_DAT_DST_ADDR2 + 64'(get_dma_slot(qid, DMA_BYTE_CNT)) * DMA_BYTE_CNT;
      default: H2C_DAT_DST_ADDR = H2C_DAT_DST_ADDR3 + 64'(get_dma_slot(qid, DMA_BYTE_CNT)) * DMA_BYTE_CNT;
    endcase
    HOST_DAT_BUF_ADDR = H2C_DAT_SRC_ADDR;
    HOST_DAT_BUF_ADDR[$clog2(DMA_BYTE_CNT)+:$bits(qid)] = qid;

    `uvm_info("H2C_MM", $sformatf(" **** TASK QDMA MM H2C DSC at address 0x%0h ***", dsc_base), UVM_MEDIUM)
    `uvm_info("H2C_MM", $sformatf(" **** H2C_DAT_DST_ADDR : 0x%0h (port=%0d slot=%0d) ***", H2C_DAT_DST_ADDR, port_sel, qid_to_slot[int'(qid)]), UVM_MEDIUM)

    // QDMA MM descriptor size is 32 bytes; write each descriptor byte up to pidx.
    for (k=0;k<pidx;k=k+1) begin
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+0]  = HOST_DAT_BUF_ADDR[7:0];  //-- Src_add [31:0]
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+1]  = HOST_DAT_BUF_ADDR[15:8];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+2]  = HOST_DAT_BUF_ADDR[23:16];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+3]  = HOST_DAT_BUF_ADDR[31:24];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+4]  = HOST_DAT_BUF_ADDR[39:32]; //-- Src add [63:32]
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+5]  = HOST_DAT_BUF_ADDR[47:40];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+6]  = HOST_DAT_BUF_ADDR[55:48];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+7]  = HOST_DAT_BUF_ADDR[63:56];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+8]  = DMA_BYTE_CNT[7:0];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+9]  = DMA_BYTE_CNT[15:8];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+10] = DMA_BYTE_CNT[23:16];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+11] = 8'h40; // {Rsvd,SDI,EOP,SOP,len[27:24]} -- last dsc sends SDI for completion
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+12] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+13] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+14] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+15] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+16] = H2C_DAT_DST_ADDR[7:0]; // Dst add 64bits [31:0]
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+17] = H2C_DAT_DST_ADDR[15:8];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+18] = H2C_DAT_DST_ADDR[23:16];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+19] = H2C_DAT_DST_ADDR[31:24];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+20] = H2C_DAT_DST_ADDR[39:32];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+21] = H2C_DAT_DST_ADDR[47:40];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+22] = H2C_DAT_DST_ADDR[55:48];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+23] = H2C_DAT_DST_ADDR[63:56];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+24] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+25] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+26] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+27] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+28] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+29] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+30] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+31] = 8'h00;
    end

    // Status write-back location (last slot of the ring) -- zero it.
    host_mem[dsc_base + (32*(GLBL_RNG_SIZE-1)) +0] = 8'h00;
    host_mem[dsc_base + (32*(GLBL_RNG_SIZE-1)) +1] = 8'h00;
    host_mem[dsc_base + (32*(GLBL_RNG_SIZE-1)) +2] = 8'h00;
    host_mem[dsc_base + (32*(GLBL_RNG_SIZE-1)) +3] = 8'h00;

    for (k = 0; k < 32; k = k + 1)  begin
      #(Tcq);
    end

    // H2C source data pattern at HOST_DAT_BUF_ADDR: first 13 bytes encode
    // addr/len/qid (consumed by the scoreboard), remainder is an
    // incrementing byte pattern up to DMA_BYTE_CNT.
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

    for (k = 13; k < DMA_BYTE_CNT; k = k + 1)  begin
      #(Tcq) host_mem[HOST_DAT_BUF_ADDR+k] = k;
    end
  end
  endtask

  /************************************************************
  Task : TSK_INIT_QDMA_MM_DATA_C2H
  Description : Stage the C2H descriptor ring (dsc_base), zero the expected
                host landing zone (C2H_DAT_DST_ADDR), and pre-load the PL1
                BRAM staging address with the 0xA5^offset pattern the C2H
                engine will read and forward to the host.
  *************************************************************/
  task TSK_INIT_QDMA_MM_DATA_C2H (input bit [7:0] fnc, input bit [10:0] qid, input bit [63:0] dsc_base);
    integer k;
  begin
    bit [63:0] C2H_DAT_SRC_ADDR;
    int        port_sel;

    // C2H always reads from PL1 BRAM (independent of H2C, which uses PL0).
    port_sel = 1;
    C2H_DAT_SRC_ADDR = C2H_DAT_SRC_ADDR1 + 64'(get_dma_slot(qid, DMA_BYTE_CNT)) * DMA_BYTE_CNT;

    // C2H_DAT_DST_ADDR (host landing zone) is the package-level default,
    // with the qid encoded into it -- must match cpm6_qdma_params_pkg.
    C2H_DAT_DST_ADDR[$clog2(DMA_BYTE_CNT)+:$bits(qid)] = qid;
    `uvm_info("C2H_MM", $sformatf(" **** TASK QDMA MM C2H DSC at address 0x%h ***", dsc_base), UVM_MEDIUM)
    `uvm_info("C2H_MM", $sformatf(" **** C2H_DAT_SRC_ADDR : 0x%0h (port=%0d slot=%0d) ***", C2H_DAT_SRC_ADDR, port_sel, qid_to_slot[int'(qid)]), UVM_MEDIUM)
    `uvm_info("C2H_MM", $sformatf(" **** C2H_DAT_DST_ADDR : 0x%0h ***", C2H_DAT_DST_ADDR), UVM_MEDIUM)

    for (k=0;k<pidx;k=k+1) begin
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+0]  = C2H_DAT_SRC_ADDR[7:0]; //-- Src_add [31:0]
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+1]  = C2H_DAT_SRC_ADDR[15:8];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+2]  = C2H_DAT_SRC_ADDR[23:16];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+3]  = C2H_DAT_SRC_ADDR[31:24];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+4]  = C2H_DAT_SRC_ADDR[39:32];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+5]  = C2H_DAT_SRC_ADDR[47:40];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+6]  = C2H_DAT_SRC_ADDR[55:48];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+7]  = C2H_DAT_SRC_ADDR[63:56];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+8]  = DMA_BYTE_CNT[7:0];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+9]  = DMA_BYTE_CNT[15:8];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+10] = DMA_BYTE_CNT[23:16];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+11] = 8'h40;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+12] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+13] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+14] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+15] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+16] = C2H_DAT_DST_ADDR[7:0]; // Dst add 64bits [31:0]
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+17] = C2H_DAT_DST_ADDR[15:8];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+18] = C2H_DAT_DST_ADDR[23:16];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+19] = C2H_DAT_DST_ADDR[31:24];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+20] = C2H_DAT_DST_ADDR[39:32];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+21] = C2H_DAT_DST_ADDR[47:40];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+22] = C2H_DAT_DST_ADDR[55:48];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+23] = C2H_DAT_DST_ADDR[63:56];
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+24] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+25] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+26] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+27] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+28] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+29] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+30] = 8'h00;
      host_mem[dsc_base+(k*QDMA_DSC_SZ)+31] = 8'h00;
    end

    // Status write-back location (last slot of the ring) -- zero it.
    host_mem[dsc_base + (32*(GLBL_RNG_SIZE-1)) +0] = 8'h00;
    host_mem[dsc_base + (32*(GLBL_RNG_SIZE-1)) +1] = 8'h00;
    host_mem[dsc_base + (32*(GLBL_RNG_SIZE-1)) +2] = 8'h00;
    host_mem[dsc_base + (32*(GLBL_RNG_SIZE-1)) +3] = 8'h00;

    for (k = 0; k < 32; k = k + 1)  begin
      #(Tcq);
    end

    // Zero the expected host landing zone; pre-load the PL1 BRAM staging
    // address with the 0xA5^offset pattern the scoreboard expects.
    for (k = 0; k < DMA_BYTE_CNT; k = k + 1) begin
      #(Tcq) host_mem[C2H_DAT_DST_ADDR + k]                     = 8'h00;
      #(Tcq) host_mem[C2H_DAT_SRC_ADDR1 + 64'(get_dma_slot(qid, DMA_BYTE_CNT))*DMA_BYTE_CNT + k] = 8'hA5 ^ k[7:0];
    end

    // Register expected: must match the C2H_DAT_DST_ADDR/C2H_DAT_SRC_ADDR1
    // computation above exactly.
    dma_req_proc.register_c2h_expected(qid, C2H_DAT_DST_ADDR, DMA_BYTE_CNT,
                                        C2H_DAT_SRC_ADDR1 + 64'(get_dma_slot(qid, DMA_BYTE_CNT)) * DMA_BYTE_CNT);
  end
  endtask

  // Returns a stable, wrapped slot index for `qid`, lazily assigning the next
  // free slot (in first-seen order) on first use. Slots only wrap (aliasing
  // two QIDs to the same address) once more than PL_BRAM_APERTURE_SIZE /
  // dma_byte_cnt distinct QIDs have been assigned on the same port -- a real
  // hardware capacity ceiling (AXI-PL0/PL1 BRAMs are 64 KB), not an artifact
  // of qid numbering.
  int slot_assign_ctr = 0;
  int qid_to_slot[int];
  function int get_dma_slot(bit [10:0] qid, int unsigned dma_byte_cnt);
    int num_slots;
    if (!qid_to_slot.exists(int'(qid))) begin
      num_slots = int'(PL_BRAM_APERTURE_SIZE / longint'(dma_byte_cnt));
      qid_to_slot[int'(qid)] = slot_assign_ctr % num_slots;
      slot_assign_ctr++;
    end
    return qid_to_slot[int'(qid)];
  endfunction

  task TSK_GLBL_PGM;
  begin
    `uvm_info("GLBL_PGM", $sformatf("---Initilize all ring size to %h -------",GLBL_RNG_SIZE), UVM_MEDIUM)
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h204, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h208, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h20C, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h210, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h214, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h218, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h21C, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h220, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h224, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h228, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h22C, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h230, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h234, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h238, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h23C, GLBL_RNG_SIZE);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h240, GLBL_RNG_SIZE);

    `uvm_info("GLBL_PGM", "---Programming Indirect CTXT MASK to 0xffffffff-------", UVM_MEDIUM)
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h824, 32'hffffffff);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h828, 32'hffffffff);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h82C, 32'hffffffff);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h830, 32'hffffffff);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h834, 32'hffffffff);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h838, 32'hffffffff);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h83C, 32'hffffffff);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h840, 32'hffffffff);

    glbl_pgm_done = 1;
  end
  endtask

  task TSK_FNC_MAP_PGM;
    input [7:0] fnc;
    input [10:0] q_base;
    input [11:0] q_count;
    bit [255:0] wr_dat;
  begin
    `uvm_info("GLBL_PGM", $sformatf("---Programming Function Map for fnc: %h -------",fnc), UVM_MEDIUM)
    `uvm_info("GLBL_PGM", $sformatf("---                          q_base: %h -------",q_base), UVM_MEDIUM)
    `uvm_info("GLBL_PGM", $sformatf("---                         q_count: %h -------",q_count), UVM_MEDIUM)
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

    wr_dat[31:18] = 'h0;             // reserved
    wr_dat[17:7]  = 11'h0 | fnc[7:0]; // fnc
    wr_dat[6:5]   = 2'h1;            // MDMA_CTXT_CMD_WR
    wr_dat[4:1]   = 4'hC;            // QDMA_CTXT_SELC_FMAP
    wr_dat[0]     = 'h0;
    issue_reg_write(PF_DMA_BAR_INDEX, 32'h844, wr_dat[31:0]);
    poll_ctxt_busy();
    fnc_map_pgm_done[fnc] = 1;
  end
  endtask

  /************************************************************
  Task : TSK_FIND_PF_VF_NUM
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
      pfn = '0;
      vfn = '0;
      for (int pf_i=0; pf_i<NUM_PFS; pf_i=pf_i+1) begin
        if (
            (fnc >= FIRST_VF_OFFSET[pf_i] + pf_i) &&
            (fnc < FIRST_VF_OFFSET[pf_i] + NUM_VFS[pf_i] + pf_i)
           ) begin
          pfn = pf_i[7:0];
          vfn = fnc - FIRST_VF_OFFSET[pf_i] - pf_i;
        end
      end
    end
    `uvm_info("TSK_FIND_PF_VF_NUM", $sformatf(" fnc %0d Translates to pfn%0d and vfn%0d", fnc, pfn, vfn), UVM_MEDIUM)
  end
  endtask

  /************************************************************
  Task : TSK_PROGRAM_PCIE_DEVCTL
  Description : Program the PCIe Device Control Register (PCI Express
                Capability offset +0x08) via CfgWr TLP from the Root Complex.
                Sets MRRS/MPS while preserving all other Device Control bits.
                Default values (MRRS=3, MPS=3, both 1024B) match the CDO
                programming at 0xfc000078. Override via +PCIE_MRRS/+PCIE_MPS.
  *************************************************************/
  task TSK_PROGRAM_PCIE_DEVCTL;
    input [2:0] mrrs_val;
    input [2:0] mps_val;

    bit         cap_err;
    bit [31:0]  devctl_dw;
    bit [15:0]  devctl_before, devctl_after;
  begin
    env.shim.api.read_cap_dw(pdev_ep.bdf, .cap(CAP_PCI_EXP), .offset(2),
                             .data(devctl_dw), .err(cap_err));
    if (cap_err)
      `uvm_warning("TSK_PROGRAM_PCIE_DEVCTL",
        "Failed to read Device Control Register -- skipping MRRS/MPS programming")
    else begin
      devctl_before = devctl_dw[15:0];
      devctl_dw[14:12] = mrrs_val;
      devctl_dw[7:5]   = mps_val;
      devctl_after = devctl_dw[15:0];

      env.shim.api.write_cap_dw(pdev_ep.bdf, .cap(CAP_PCI_EXP), .offset(2),
                                .be(4'b0011), .data(devctl_dw), .err(cap_err));
      if (cap_err)
        `uvm_warning("TSK_PROGRAM_PCIE_DEVCTL", "Failed to write Device Control Register")

      `uvm_info("TSK_PROGRAM_PCIE_DEVCTL", $sformatf(
        "Device Control programmed: MRRS=%0d (%0dB) MPS=%0d (%0dB) before=0x%04h after=0x%04h err=%0b",
        mrrs_val, (128 << mrrs_val), mps_val, (128 << mps_val),
        devctl_before, devctl_after, cap_err), UVM_NONE)
    end
  end
  endtask

  /************************************************************
  Task : TSK_PROGRAM_MSIX_VEC_TABLE
  *************************************************************/
  task TSK_PROGRAM_MSIX_VEC_TABLE;
    input [7:0] fnc_i;
    integer     i;
    bit [31:0]  msix_base;
    integer     bar_idx;
    bit [7:0]   pfn, vfn;
    bit         is_pf;
  begin
    TSK_FIND_PF_VF_NUM(fnc_i, pfn, vfn);
    if (fnc_i < NUM_PFS) begin
      bar_idx   = PF_MSIX_BAR_INDEX;
      msix_base = PF_MSIX_VEC_OFFSET;
      is_pf     = 1'b1;
    end else begin
      bar_idx   = VF_MSIX_BAR_INDEX;
      msix_base = VF_MSIX_VEC_OFFSET;
      is_pf     = 1'b0;
    end

    `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
      "Programming MSI-X VT: fnc=%0d pfn=%0d vfn=%0d bar=%0d base=0x%0h",
      fnc_i, pfn, vfn, bar_idx, msix_base), UVM_MEDIUM)

    // MSI-X host target address: placed in the 4KB gap between H2C data area
    // and H2C descriptor rings (H2C_DAT_SRC_ADDR + H2C_DAT_SIZE = 0xB1000),
    // within the PCIe address window declared by the Avery VIP RC.
    begin
      bit [31:0] msix_host_base;
      msix_host_base = 32'(H2C_DAT_SRC_ADDR + H2C_DAT_SIZE);
      for (i=0; i<7; i=i+1) begin
        issue_reg_write(bar_idx, msix_base+16*i+0*4, msix_host_base + i*4, is_pf, pfn, vfn); // addr_lo
        issue_reg_write(bar_idx, msix_base+16*i+1*4, 32'h00000000,          is_pf, pfn, vfn); // addr_hi
        issue_reg_write(bar_idx, msix_base+16*i+2*4, 32'hFACE0000 + i,     is_pf, pfn, vfn); // data
        issue_reg_write(bar_idx, msix_base+16*i+3*4, 32'h00000000,          is_pf, pfn, vfn); // ctrl (unmasked)
      end
    end

    // Enable MSI-X in PCIe config space for this function by setting
    // msix_enable (bit 31 of DW0 in the MSI-X Capability Control register).
    // CPM6's cpm6_msix_ctrl_logic checks user_function_is_enabled_reg; when 0,
    // CPM6 asserts msix_error alongside msix_grant and irq_mgr drops the
    // retry, so the host never receives the MSI-X message.
    begin
      bit         cap_err;
      bit [31:0]  cap_dw0;
      if (is_pf) begin
        env.shim.api.read_cap_dw(pdev_ep.bdf, .cap(CAP_MSI_X), .offset(0),
                                 .data(cap_dw0), .err(cap_err));
        cap_dw0[31] = 1'b1;
        cap_dw0[30] = 1'b0;
        env.shim.api.write_cap_dw(pdev_ep.bdf, .cap(CAP_MSI_X), .offset(0),
                                  .be(4'b1100), .data(cap_dw0), .err(cap_err));
      end else begin
        // Avery VIP pdev_ep.vf[] is 1-based: vf[0]=null, vf[1]=VF0, ...
        if ((vfn+1) >= pdev_ep.vf.size() || pdev_ep.vf[vfn+1] == null)
          `uvm_fatal("TSK_PROGRAM_MSIX_VEC_TABLE",
            $sformatf("VF[%0d] not found in pdev_ep.vf[] (size=%0d, index=%0d)", vfn, pdev_ep.vf.size(), vfn+1))
        env.shim.api.read_cap_dw(pdev_ep.vf[vfn+1].bdf, .cap(CAP_MSI_X), .offset(0),
                                 .data(cap_dw0), .err(cap_err));
        cap_dw0[31] = 1'b1;
        cap_dw0[30] = 1'b0;
        env.shim.api.write_cap_dw(pdev_ep.vf[vfn+1].bdf, .cap(CAP_MSI_X), .offset(0),
                                  .be(4'b1100), .data(cap_dw0), .err(cap_err));
      end
      `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
        "MSI-X cap enabled: fnc=%0d pfn=%0d vfn=%0d cap_dw0=0x%08h err=%0b",
        fnc_i, pfn, vfn, cap_dw0, cap_err), UVM_MEDIUM)
    end

    // No readback check: PCIe MSI-X vector table registers are write-only per
    // spec -- correct programming is confirmed by the MSIX_MWR TLP the DUT
    // sends after queue completion; see TSK_CHECK_MSIX_TLP.
    `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
      "MSI-X VT programmed: fnc=%0d bar=%0d base=0x%0h (7 entries, vec 0-6)",
      fnc_i, bar_idx, msix_base), UVM_MEDIUM)
  end
  endtask // TSK_PROGRAM_MSIX_VEC_TABLE

  /************************************************************
  Task : TSK_CHECK_MSIX_TLP
  Description : Wait for and verify the MSI-X Memory Write TLP generated by
                CPM6 after irq_mgr asserts pcie_msix_req. Detection: dma_req_proc
                (via qdma_mem_callback, boundary-level) increments
                h2c_msix_cnt (vec==1) / c2h_msix_cnt (vec==2) when an MWr TLP
                lands in the MSI-X window; this task snapshots the relevant
                counter and polls (1ns steps) until it increments by 1.
                Timeout: MSIX_TLP_TIMEOUT (default 100us).
  *************************************************************/
  task TSK_CHECK_MSIX_TLP;
    input [10:0] vec;
    input [7:0]  fnc;

    logic [63:0] exp_addr;
    logic [31:0] exp_data;
    int          cnt_before;
    time         MSIX_TLP_TIMEOUT = 100us;
  begin
    exp_addr = {32'h0, 32'(H2C_DAT_SRC_ADDR + H2C_DAT_SIZE) + 32'(vec) * 4};
    exp_data = 32'hFACE0000 + 32'(vec);

    if (vec == 11'd1)
      cnt_before = dma_req_proc.h2c_msix_cnt;
    else if (vec == 11'd2)
      cnt_before = dma_req_proc.c2h_msix_cnt;
    else
      cnt_before = 0;

    `uvm_info("TSK_CHECK_MSIX_TLP", $sformatf(
      "Waiting for MSI-X MWr TLP: vec=%0d fnc=%0d exp_addr=0x%016h exp_data=0x%08h cnt_before=%0d",
      vec, fnc, exp_addr, exp_data, cnt_before), UVM_MEDIUM)

    begin : MSIX_POLL_BLOCK
      automatic time deadline = $time + MSIX_TLP_TIMEOUT;
      automatic bit timed_out  = 0;
      forever begin
        #1ns;
        if (vec == 11'd1 && dma_req_proc.h2c_msix_cnt > cnt_before) break;
        if (vec == 11'd2 && dma_req_proc.c2h_msix_cnt > cnt_before) break;
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
  Task : TSK_QDMA_MM_H2C_TEST
  Description : Programs global ring size / function map (once each), reads the DMA
                Engine ID, clears + programs the H2C indirect SW context for
                this qid, then rings the PIDX doorbell.
  *************************************************************/
  task TSK_QDMA_MM_H2C_TEST(input bit [10:0] qid, input dsc_bypass, input irq_en,
                             input bit defer_doorbell = 1'b0);
    bit [63:0]  dsc_base;
    bit [11:0]  q_base;
    bit [7:0]   fnc = 8'(pf_fnc);
    bit [255:0] wr_dat;
    bit [31:0]  wr_add;
    bit [10:0]  axi_mm_q;
    bit [31:0]  READ_DATA;
    localparam NUM_ITER = 1;
    integer    iter;
  begin
    `uvm_info("H2C_MM", "------AXI-MM H2C Tests start--------", UVM_MEDIUM)

    axi_mm_q = qid;
    dsc_base = H2C_DSC_ADDR + qid * GLBL_RNG_SIZE * QDMA_DSC_SZ;
    q_base   = pf_fnc * QUEUE_PER_PF;

    TSK_INIT_QDMA_MM_DATA_H2C(fnc, axi_mm_q, dsc_base);

    if (!glbl_pgm_done)
      TSK_GLBL_PGM;
    if (!fnc_map_pgm_done[fnc])
      TSK_FNC_MAP_PGM(fnc, q_base, QUEUE_PER_PF);

    `uvm_info("H2C_MM", $sformatf("------DMA Engine ID Read--------, PF_DMA_BAR_INDEX:%d",PF_DMA_BAR_INDEX), UVM_LOW)
    issue_reg_read(PF_DMA_BAR_INDEX, 16'h00, , , ,READ_DATA);

    if (dsc_bypass)
      issue_reg_write(PF_USR_BAR_INDEX, 32'h90, 32'h3);

    // Clear HW CTXT for H2C for this qid.
    wr_dat[31:18] = 'h0;
    wr_dat[17:7]  = axi_mm_q[10:0];
    wr_dat[6:5]   = 2'h0; // MDMA_CTXT_CMD_CLR
    wr_dat[4:1]   = 4'h3; // MDMA_CTXT_SELC_DSC_HW_H2C
    wr_dat[0]     = 'h0;
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    if (irq_en == 1'b1)
      TSK_PROGRAM_MSIX_VEC_TABLE(fnc);

    `uvm_info("H2C_MM", " *** QDMA H2C *** ", UVM_MEDIUM)
    // Indirect AXI-MM H2C CTXT DATA.
    wr_dat[255:140] = 'd0;
    wr_dat[139]     = 'd0;    // int_aggr
    wr_dat[138:128] = 'd1;    // vec MSI-X Vector
    wr_dat[127:64]  = dsc_base;
    wr_dat[63]      = 1'b1;   // is_mm
    wr_dat[62]      = 1'b0;   // mrkr_dis
    wr_dat[61]      = 1'b0;   // irq_req
    wr_dat[60]      = 1'b0;   // err_wb_sent
    wr_dat[59:58]   = 2'b0;   // err
    wr_dat[57]      = 1'b0;   // irq_no_last
    wr_dat[56:54]   = 3'h0;   // port_id
    wr_dat[53]      = irq_en;
    wr_dat[52]      = 1'b0;   // wbk_en: disabled for MM mode (no CMPT ring programmed)
    wr_dat[51]      = 1'b0;   // mm_chn
    wr_dat[50]      = dsc_bypass ? 1'b1 : 1'b0;
    wr_dat[49:48]   = 2'b10;  // dsc_sz, 32 bytes
    wr_dat[47:44]   = 4'h1;   // rng_sz
    wr_dat[43:41]   = 3'h0;
    wr_dat[40:37]   = 4'h0;   // fetch_max
    wr_dat[36]      = 1'b0;   // atc
    wr_dat[35]      = 1'b0;   // wbi_intvl_en
    wr_dat[34]      = 1'b1;   // wbi_chk
    wr_dat[33]      = 1'b0;   // fcrd_en
    wr_dat[32]      = 1'b1;   // qen
    wr_dat[31:25]   = 7'h0;
    wr_dat[24:17]   = {4'h0,pf_fnc[3:0]}; // func_id
    wr_dat[16]      = 1'b0;   // irq_arm
    wr_dat[15:0]    = 16'b0;  // pidx

    issue_reg_write(PF_DMA_BAR_INDEX, 16'h804, wr_dat[31 :0 ]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h808, wr_dat[63 :32]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h80C, wr_dat[95 :64]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h810, wr_dat[127:96]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h814, wr_dat[159:128]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h818, wr_dat[191:160]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h81C, wr_dat[223:192]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h820, wr_dat[255:224]);

    // Ind Dir CTXT CMD 0x844: [17:7]=qid, [6:5]=MDMA_CTXT_CMD_WR=01,
    // [4:1]=MDMA_CTXT_SELC_DSC_SW_H2C=0001, [0]=BUSY=0.
    wr_dat = {14'h0,axi_mm_q[10:0],7'b0100010};
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    if (!defer_doorbell) begin
      for (iter=0; iter < NUM_ITER; iter=iter+1) begin
        wr_add = QUEUE_PTR_PF_ADDR + (axi_mm_q* 16) + 4;
        issue_reg_write(PF_DMA_BAR_INDEX, wr_add[31:0], {irq_en, pidx[15:0]} | 32'h0);
        `uvm_info("H2C_MM", $sformatf("pidx %0d value written to qid:%0d",pidx,qid), UVM_MEDIUM)
      end

      if (irq_en)
        TSK_CHECK_MSIX_TLP(.vec(11'd1), .fnc(8'(fnc)));
    end
  end
  endtask

  /************************************************************
  Task : TSK_QDMA_MM_C2H_TEST
  Description : Mirror of TSK_QDMA_MM_H2C_TEST for the C2H direction; see that task's
                header for the defer_doorbell/refill scope note.
  *************************************************************/
  task TSK_QDMA_MM_C2H_TEST(input bit [10:0] qid, input dsc_bypass, input irq_en,
                             input bit defer_doorbell = 1'b0);
    bit [63:0]  dsc_base;
    bit [11:0]  q_base;
    bit [7:0]   fnc = 8'(pf_fnc);
    bit [255:0] wr_dat;
    bit [31:0]  wr_add;
    bit [10:0]  axi_mm_q;
    bit [31:0]  READ_DATA;
    localparam NUM_ITER = 1;
    integer    iter;
  begin
    `uvm_info("C2H_MM", "------AXI-MM C2H Tests start--------", UVM_MEDIUM)

    axi_mm_q = qid;
    dsc_base = C2H_DSC_ADDR + qid * GLBL_RNG_SIZE * QDMA_DSC_SZ;
    q_base   = pf_fnc * QUEUE_PER_PF;

    if (!glbl_pgm_done)
      TSK_GLBL_PGM;
    if (!fnc_map_pgm_done[fnc])
      TSK_FNC_MAP_PGM(fnc, q_base, QUEUE_PER_PF);

    issue_reg_read(PF_DMA_BAR_INDEX, 16'h00, , , ,READ_DATA);

    if (dsc_bypass)
      issue_reg_write(PF_USR_BAR_INDEX, 32'h90, 32'h3);

    // Clear HW CTXT for C2H for this qid.
    wr_dat[31:18] = 'h0;
    wr_dat[17:7]  = axi_mm_q[10:0];
    wr_dat[6:5]   = 2'h0; // MDMA_CTXT_CMD_CLR
    wr_dat[4:1]   = 4'h2; // MDMA_CTXT_SELC_DSC_HW_C2H
    wr_dat[0]     = 'h0;
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    if (irq_en == 1'b1)
      TSK_PROGRAM_MSIX_VEC_TABLE(fnc);

    TSK_INIT_QDMA_MM_DATA_C2H(8'h0, axi_mm_q, dsc_base);

    // Indirect AXI-MM C2H CTXT DATA.
    wr_dat[255:140] = 'd0;
    wr_dat[139]     = 'd0;    // int_aggr
    wr_dat[138:128] = 'd2;    // vec MSI-X Vector
    wr_dat[127:64]  = dsc_base;
    wr_dat[63]      = 1'b1;   // is_mm
    wr_dat[62]      = 1'b0;   // mrkr_dis
    wr_dat[61]      = 1'b0;   // irq_req
    wr_dat[60]      = 1'b0;   // err_wb_sent
    wr_dat[59:58]   = 2'b0;   // err
    wr_dat[57]      = 1'b0;   // irq_no_last
    wr_dat[56:54]   = 3'h0;   // port_id
    wr_dat[53]      = irq_en;
    wr_dat[52]      = 1'b0;   // wbk_en: disabled for MM mode (no CMPT ring programmed)
    wr_dat[51]      = 1'b0;   // mm_chn
    wr_dat[50]      = dsc_bypass ? 1'b1 : 1'b0;
    wr_dat[49:48]   = 2'b10;  // dsc_sz, 32 bytes
    wr_dat[47:44]   = 4'h1;   // rng_sz
    wr_dat[43:41]   = 3'h0;
    wr_dat[40:37]   = 4'h0;   // fetch_max
    wr_dat[36]      = 1'b0;   // atc
    wr_dat[35]      = 1'b0;   // wbi_intvl_en
    wr_dat[34]      = 1'b1;   // wbi_chk
    wr_dat[33]      = 1'b0;   // fcrd_en
    wr_dat[32]      = 1'b1;   // qen
    wr_dat[31:25]   = 7'h0;
    wr_dat[24:17]   = {4'h0,pf_fnc[3:0]};
    wr_dat[16]      = 1'b0;   // irq_arm
    wr_dat[15:0]    = 16'b0;  // pidx

    issue_reg_write(PF_DMA_BAR_INDEX, 16'h804, wr_dat[31 :0]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h808, wr_dat[63 :32]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h80C, wr_dat[95 :64]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h810, wr_dat[127:96]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h814, wr_dat[159:128]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h818, wr_dat[191:160]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h81C, wr_dat[223:192]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h820, wr_dat[255:224]);

    // Ind Dir CTXT CMD 0x844: [17:7]=qid, [6:5]=MDMA_CTXT_CMD_WR=01,
    // [4:1]=MDMA_CTXT_SELC_DSC_SW_C2H=0000, [0]=BUSY=0.
    wr_dat = {14'h0,axi_mm_q[10:0],7'b0100000};
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    if (!defer_doorbell) begin
      for (iter=0; iter < NUM_ITER; iter=iter+1) begin
        wr_add = QUEUE_PTR_PF_ADDR + (axi_mm_q* 16) + 8;
        issue_reg_write(PF_DMA_BAR_INDEX, wr_add[31:0], {irq_en, pidx[15:0]} | 32'h0);
        `uvm_info("C2H_MM", $sformatf("pidx %0d value written to qid:%0d",pidx,qid), UVM_MEDIUM)
      end

      if (irq_en)
        TSK_CHECK_MSIX_TLP(.vec(11'd2), .fnc(8'(fnc)));
    end
  end
  endtask

  /************************************************************
  Task : TSK_QDMA_VF_H2C_MM_TEST / TSK_QDMA_VF_C2H_MM_TEST
  Description : VF-capable counterparts of TSK_QDMA_MM_H2C_TEST /
                TSK_QDMA_MM_C2H_TEST above. Context/SW-ctxt register
                programming always goes through PF_DMA_BAR_INDEX (indirect
                context commands are a PF-privileged global resource); only
                the PIDX doorbell is routed through the owning function's
                own BAR (ptr_upt_dma_bar_idx), letting a VF ring its own
                doorbell without PF BAR access.
  *************************************************************/
  task TSK_QDMA_VF_H2C_MM_TEST(input logic [7:0] fnc, input logic [10:0] qid,
                                input logic irq_en, input logic defer_doorbell = 1'b0);

    logic [11:0] q_count;
    logic [11:0] q_base;
    logic [11:0] hw_qid; // hw qid: use for global space reg access and user logic.
    logic [31:0] trq_sel_queue_addr;
    integer ptr_upt_dma_bar_idx;
    integer usr_bar_idx;
    localparam NUM_ITER = 1;
    bit  [63:0]  dsc_base;
    bit          is_pf;
    bit [1:0]    dsc_sz;
    bit [7:0]    pfn;
    bit [7:0]    vfn;
    bit [255:0]  wr_dat;
    bit [31:0]   wr_add;
    bit [31:0]   READ_DATA;

    begin
    ptr_upt_dma_bar_idx = 0;
    usr_bar_idx = 2;
    is_pf = 1;

    TOTAL_VFS[0] = 16'h20;
    NUM_VFS[0] = NUM_VF;
    FIRST_VF_OFFSET[0] = VF_OFFSET;

    TSK_FIND_PF_VF_NUM(fnc, pfn, vfn);

    if (fnc < NUM_PFS) begin
      `uvm_info("TSK_QDMA_VF_H2C_MM_TEST", $sformatf(" ****************** Lauching H2C MM for PF%0d, QID#%d ***********************", pfn, qid), UVM_MEDIUM)
      trq_sel_queue_addr = 32'h18000;
      q_base = QUEUE_PER_PF * fnc;
      q_count = QUEUE_PER_PF;
      ptr_upt_dma_bar_idx = PF_DMA_BAR_INDEX;
      usr_bar_idx = PF_USR_BAR_INDEX;
    end
    else begin
      `uvm_info("TSK_QDMA_VF_H2C_MM_TEST", $sformatf(" ****************** Launching H2C MM for PF%0d, VF%0d, QID#%d ***********************", pfn, vfn, qid), UVM_MEDIUM)
      trq_sel_queue_addr = 32'h3000;
      q_base = QUEUE_PER_PF * NUM_PFS + (fnc - VF_OFFSET) * QUEUE_PER_VF;
      q_count = QUEUE_PER_VF;
      ptr_upt_dma_bar_idx = VF_DMA_BAR_INDEX;
      usr_bar_idx = VF_USR_BAR_INDEX;
      if (qid > QUEUE_PER_VF-1)
        `uvm_fatal("TSK_QDMA_VF_H2C_MM_TEST", $sformatf("VF QID#%0d exceeds maximum %0d", qid, QUEUE_PER_VF-1))
    end

    // Global programming
    if(!glbl_pgm_done)
      TSK_GLBL_PGM;

    if(!fnc_map_pgm_done[fnc])
      TSK_FNC_MAP_PGM(fnc,q_base,q_count);

    hw_qid = qid + q_base;
    `uvm_info("TSK_QDMA_VF_H2C_MM_TEST", $sformatf(" q_base : %d, qid : %d, hw_qid : %d", q_base, qid, hw_qid), UVM_MEDIUM)
    dsc_base = H2C_DSC_ADDR + hw_qid * GLBL_RNG_SIZE * QDMA_DSC_SZ;
    `uvm_info("TSK_QDMA_VF_H2C_MM_TEST", $sformatf(" dsc_base : 0x%0h", dsc_base), UVM_MEDIUM)

    // Load DATA in Buffer
    TSK_INIT_QDMA_MM_DATA_H2C(fnc, hw_qid, dsc_base);

    // DMA Engine ID Read
    issue_reg_read(PF_DMA_BAR_INDEX, 16'h00, , , , READ_DATA);
    `uvm_info("TSK_QDMA_VF_H2C_MM_TEST", $sformatf(" DMA Engine ID = %0h",READ_DATA), UVM_LOW)

    // Clear HW CXTX for H2C
    //   [17:7] QID
    //   [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
    //   [4:1]  MDMA_CTXT_SELC_DSC_HW_H2C = 3 : 0011
    //   0      BUSY : 0
    wr_dat[31:0] = {hw_qid, 2'h0, 4'b0011, 1'b0} | 32'h0;
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    if (irq_en) begin
      TSK_PROGRAM_MSIX_VEC_TABLE(fnc);  // pass actual function number (VF fnc, not PF pfn)
    end

    if(QDMA_DSC_SZ == 6'd8)
      dsc_sz = 2'b00;
    else if(QDMA_DSC_SZ == 6'd16)
      dsc_sz = 2'b01;
    else if(QDMA_DSC_SZ == 6'd32)
      dsc_sz = 2'b10;
    else if(QDMA_DSC_SZ == 7'd64)
      dsc_sz = 2'b11;

    // Set up H2C SW CTXT
    wr_dat[255:140] = 'd0;
    wr_dat[139]     = 'd0;    // int_aggr
    wr_dat[138:128] = 'd1;    // vec MSI-X Vector
    wr_dat[127:64]  =  {dsc_base_hi, dsc_base[31:0]}; // dsc base
    wr_dat[63]      =  1'b1;  // is_mm
    wr_dat[62]      =  1'b0;  // mrkr_dis
    wr_dat[61]      =  1'b0;  // irq_req
    wr_dat[60]      =  1'b0;  // err_wb_sent
    wr_dat[59:58]   =  2'b0;  // err
    wr_dat[57]      =  1'b0;  // irq_no_last
    wr_dat[56:54]   =  3'h0;  // port_id
    wr_dat[53]      =  irq_en;// irq_en
    wr_dat[52]      =  1'b0;  // wbk_en: disabled for MM mode (no CMPT ring programmed)
    wr_dat[51]      =  1'b0;  // mm_chn
    wr_dat[50]      =  1'b0;  // bypass
    wr_dat[49:48]   =  dsc_sz; // dsc_sz
    wr_dat[47:44]   =  4'h1;  // rng_sz
    wr_dat[43:41]   =  3'h0;  // reserved
    wr_dat[40:37]   =  4'h0;  // fetch_max
    wr_dat[36]      =  1'b0;  // atc
    wr_dat[35]      =  1'b0;  // wbi_intvl_en
    wr_dat[34]      =  1'b1;  // wbi_chk
    wr_dat[33]      =  1'b0;  // fcrd_en
    wr_dat[32]      =  1'b1;  // qen
    wr_dat[31:25]   =  7'h0;  // reserved
    wr_dat[24:17]   =  fnc;   // func_id
    wr_dat[16]      =  1'b0;  // irq_arm
    wr_dat[15:0]    =  16'b0; // pidx

    // Use ptr_upt_dma_bar_idx so VF queues go through VF_DMA_BAR_INDEX.
    issue_reg_write(ptr_upt_dma_bar_idx, 16'h804, wr_dat[31:0]);
    issue_reg_write(ptr_upt_dma_bar_idx, 16'h808, wr_dat[63:32]);
    issue_reg_write(ptr_upt_dma_bar_idx, 16'h80C, wr_dat[95:64]);
    issue_reg_write(ptr_upt_dma_bar_idx, 16'h810, wr_dat[127:96]);
    issue_reg_write(ptr_upt_dma_bar_idx, 16'h814, wr_dat[159:128]);
    issue_reg_write(ptr_upt_dma_bar_idx, 16'h818, wr_dat[191:160]);
    issue_reg_write(ptr_upt_dma_bar_idx, 16'h81C, wr_dat[223:192]);
    issue_reg_write(ptr_upt_dma_bar_idx, 16'h820, wr_dat[255:224]);

    // Program SW H2C CTXT
    // [17:7] QID
    // [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    // [4:1]  MDMA_CTXT_SELC_DSC_SW_H2C = 1 : 0001
    // 0      BUSY : 0
    wr_dat[31:0] = {hw_qid[10:0],2'b01, 4'b0001, 1'b0} | 32'h0;
    issue_reg_write(ptr_upt_dma_bar_idx, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    // Start DMA tranfer
    if (!defer_doorbell) begin
    for (int iter=0; iter < NUM_ITER; iter=iter+1) begin
      `uvm_info("TSK_QDMA_VF_H2C_MM_TEST", $sformatf(" Start H2C MM Iteration %0d for fnc %0d",iter, fnc), UVM_MEDIUM)
      if(fnc > (NUM_PFS-1))
        is_pf = 0;

      wr_add = trq_sel_queue_addr + (qid* 16) + 4;
      // Sequential (not fork/join): no concurrency was needed for a single
      // blocking call -- see the matching fix in TSK_QDMA_VF_C2H_MM_TEST, which
      // had a live is_pf race from this same fork-without-begin/end pattern.
      `uvm_info("TSK_QDMA_VF_H2C_MM_TEST", $sformatf(" Enabling PIDX 'd%0d for H2C", pidx), UVM_MEDIUM)
      // bit[16]=irq_en arms the interrupt on this PIDX update (same field as PF PIDX register)
      issue_reg_write(ptr_upt_dma_bar_idx, wr_add[31:0], {irq_en, pidx[15:0]}, is_pf, pfn, vfn);
    end

    if (irq_en) begin
      TSK_CHECK_MSIX_TLP(.vec(11'd1), .fnc(8'(fnc)));  // H2C uses vec=1
    end
    end // !defer_doorbell
    end

  endtask

  task TSK_QDMA_VF_C2H_MM_TEST(input logic [7:0] fnc, input logic [10:0] qid,
                                input logic irq_en, input logic defer_doorbell = 1'b0);

    logic [11:0] q_count;
    logic [10:0] q_base;
    logic [10:0] hw_qid; // hw qid: use for global space reg access and user logic.
    logic [31:0] trq_sel_queue_addr;
    integer ptr_upt_dma_bar_idx;
    integer usr_bar_idx;
    localparam NUM_ITER = 1;
    bit [63:0]  dsc_base;
    bit [7:0]   pfn;
    bit [7:0]   vfn;
    bit [255:0] wr_dat;
    bit [31:0]  wr_add;
    bit [31:0]  READ_DATA;
    bit is_pf;
    bit [1:0] dsc_sz;

    begin
    ptr_upt_dma_bar_idx=0;
    usr_bar_idx =2;
    is_pf = 1;

    TOTAL_VFS[0] = 16'h20;
    NUM_VFS[0] = NUM_VF;
    FIRST_VF_OFFSET[0] = VF_OFFSET;

    TSK_FIND_PF_VF_NUM(fnc, pfn, vfn);

    if (fnc < NUM_PFS) begin
      `uvm_info("TSK_QDMA_VF_C2H_MM_TEST", $sformatf(" ****************** Lauching C2H MM for PF%0d, QID#%d ***********************", pfn, qid), UVM_MEDIUM)
      trq_sel_queue_addr = 32'h18000;
      q_base = QUEUE_PER_PF * fnc;
      q_count = QUEUE_PER_PF;
      ptr_upt_dma_bar_idx = PF_DMA_BAR_INDEX;
      usr_bar_idx = PF_USR_BAR_INDEX;
    end
    else begin
      `uvm_info("TSK_QDMA_VF_C2H_MM_TEST", $sformatf(" ****************** Launching C2H MM for PF%0d, VF%0d, QID#%d *********************", pfn, vfn, qid), UVM_MEDIUM)
      trq_sel_queue_addr = 32'h3000;
      q_base = QUEUE_PER_PF * NUM_PFS + (fnc - VF_OFFSET) * QUEUE_PER_VF;
      q_count = QUEUE_PER_VF;
      ptr_upt_dma_bar_idx = VF_DMA_BAR_INDEX;
      usr_bar_idx = VF_USR_BAR_INDEX;
      if (qid > QUEUE_PER_VF-1)
        `uvm_fatal("TSK_QDMA_VF_C2H_MM_TEST", $sformatf("VF QID#%0d exceeds maximum %0d", qid, QUEUE_PER_VF-1))
    end

    `uvm_info("TSK_QDMA_VF_C2H_MM_TEST", $sformatf(" Warning - Must run H2C MM before C2H MM"), UVM_MEDIUM)

    // Global programming
    if(!glbl_pgm_done)
      TSK_GLBL_PGM;

    if(!fnc_map_pgm_done[fnc])
      TSK_FNC_MAP_PGM(fnc,q_base,q_count);

    hw_qid = qid + q_base;
    `uvm_info("TSK_QDMA_VF_C2H_MM_TEST", $sformatf(" q_base : %d, qid : %d, hw_qid : %d", q_base, qid, hw_qid), UVM_MEDIUM)
    dsc_base = C2H_DSC_ADDR + hw_qid * GLBL_RNG_SIZE * QDMA_DSC_SZ;
    `uvm_info("TSK_QDMA_VF_C2H_MM_TEST", $sformatf(" dsc_base : 0x%0h", dsc_base), UVM_MEDIUM)

    // Load DATA in Buffer
    TSK_INIT_QDMA_MM_DATA_C2H(fnc, hw_qid, dsc_base);

    // DMA Engine ID Read
    issue_reg_read(PF_DMA_BAR_INDEX, 16'h00, , , , READ_DATA);
    `uvm_info("TSK_QDMA_VF_C2H_MM_TEST", $sformatf(" DMA Engine ID = %0h",READ_DATA), UVM_LOW)
    // Clear HW CXTX for C2H
    //   [17:7] QID
    //   [6:5 ] MDMA_CTXT_CMD_CLR=0 : 00
    //   [4:1]  MDMA_CTXT_SELC_DSC_HW_C2H = 2 : 0010
    //   0      BUSY : 0
    wr_dat[31:0] = {hw_qid, 2'h0, 4'b0010, 1'b0} | 32'h0;
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    if (irq_en) begin
      TSK_PROGRAM_MSIX_VEC_TABLE(fnc);  // pass actual function number (VF fnc, not PF pfn)
    end

    if(QDMA_DSC_SZ == 6'd8)
      dsc_sz = 2'b00;
    else if(QDMA_DSC_SZ == 6'd16)
      dsc_sz = 2'b01;
    else if(QDMA_DSC_SZ == 6'd32)
      dsc_sz = 2'b10;
    else if(QDMA_DSC_SZ == 7'd64)
      dsc_sz = 2'b11;

    // Set up C2H SW CTXT
    wr_dat[255:140] = 'd0;
    wr_dat[139]     = 'd0;    // int_aggr
    wr_dat[138:128] = 'd2;    // vec MSI-X Vector
    wr_dat[127:64]  =  {dsc_base_hi, dsc_base[31:0]}; // dsc base
    wr_dat[63]      =  1'b1;  // is_mm
    wr_dat[62]      =  1'b0;  // mrkr_dis
    wr_dat[61]      =  1'b0;  // irq_req
    wr_dat[60]      =  1'b0;  // err_wb_sent
    wr_dat[59:58]   =  2'b0;  // err
    wr_dat[57]      =  1'b0;  // irq_no_last
    wr_dat[56:54]   =  3'h0;  // port_id
    wr_dat[53]      =  irq_en;// irq_en
    wr_dat[52]      =  1'b0;  // wbk_en: disabled for MM mode (no CMPT ring programmed)
    wr_dat[51]      =  1'b0;  // mm_chn
    wr_dat[50]      =  1'b0;  // bypass
    wr_dat[49:48]   =  dsc_sz;// dsc_sz
    wr_dat[47:44]   =  4'h1;  // rng_sz
    wr_dat[43:41]   =  3'h0;  // reserved
    wr_dat[40:37]   =  4'h0;  // fetch_max
    wr_dat[36]      =  1'b0;  // atc
    wr_dat[35]      =  1'b0;  // wbi_intvl_en
    wr_dat[34]      =  1'b1;  // wbi_chk
    wr_dat[33]      =  1'b0;  // fcrd_en
    wr_dat[32]      =  1'b1;  // qen
    wr_dat[31:25]   =  7'h0;  // reserved
    wr_dat[24:17]   =  fnc;   // func_id
    wr_dat[16]      =  1'b0;  // irq_arm
    wr_dat[15:0]    =  16'b0; // pidx

    issue_reg_write(PF_DMA_BAR_INDEX, 16'h804, wr_dat[31:0]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h808, wr_dat[63:32]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h80C, wr_dat[95:64]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h810, wr_dat[127:96]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h814, wr_dat[159:128]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h818, wr_dat[191:160]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h81C, wr_dat[223:192]);
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h820, wr_dat[255:224]);

    // Program SW C2H CTXT
    //   [17:7] QID
    //   [6:5 ] MDMA_CTXT_CMD_WR=1 : 01
    //   [4:1]  MDMA_CTXT_SELC_DSC_SW_C2H = 0 : 0000
    //   0      BUSY : 0
    wr_dat[31:0] = {hw_qid[10:0],2'b01, 4'b0000, 1'b0} | 32'h0;
    issue_reg_write(PF_DMA_BAR_INDEX, 16'h844, wr_dat[31:0]);
    poll_ctxt_busy();

    // Start DMA tranfer
    if (!defer_doorbell) begin
    for (int iter=0; iter < NUM_ITER; iter=iter+1) begin

      `uvm_info("TSK_QDMA_VF_C2H_MM_TEST", $sformatf(" Start C2H Iteration %0d for fnc %0d", iter, fnc), UVM_MEDIUM)
      // Sequential (not fork/join): fork with no begin/end grouping spawns each
      // statement as an independent parallel thread, so issue_reg_write's read of
      // is_pf raced against the is_pf=0 assignment above it with no ordering
      // guarantee -- a VF doorbell could be issued with the stale is_pf=1 (PF
      // addressing). No concurrency was needed here; these steps are sequential
      // by data dependency (is_pf/wr_add must resolve before the write uses them).
      if(fnc > (NUM_PFS-1))
        is_pf = 0;
      wr_add = trq_sel_queue_addr + (qid* 16) + 8;
      `uvm_info("TSK_QDMA_VF_C2H_MM_TEST", $sformatf(" Enabling PIDX %0d for C2H", pidx), UVM_MEDIUM)
      // bit[16]=irq_en arms the interrupt on this PIDX update (same field as PF PIDX register)
      issue_reg_write(ptr_upt_dma_bar_idx, wr_add[31:0], {irq_en, pidx[15:0]}, is_pf, pfn, vfn);
    end

    if (irq_en) begin
      TSK_CHECK_MSIX_TLP(.vec(11'd2), .fnc(8'(fnc)));  // C2H uses vec=2
    end
    end // !defer_doorbell
    end
  endtask  // TSK_QDMA_VF_C2H_MM_TEST

endclass
