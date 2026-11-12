import axil_slave_pkg::*;

module pl_example #(
    // *** Change these values in hdma_ddr_top.sv to resize the entire design. ***
    parameter int NUM_PFS        = 8,   // number of Physical Functions
    parameter int NUM_VFS_PER_PF = 7,   // VFs per PF (PF-relative indices 0..N-1)
    // CPM6 internal DBI config-space base/stride for reading per-PF registers (e.g. SR-IOV NumVFs,
    // see FLR controller below) directly through m_dbi_axil. Default matches this design's DBI1
    // connection to CPM6 Controller 0's config-space DBI window (0xFC00_0000 base; Controller 1 uses 0xFC40_0000, confirmed via
    // CPM6 register DB lookup); override CFG_DBI_CFGSPACE_BASE to 0xFC00_0000 if this design is
    // ever wired to Controller 0's DBI0 instead.
    parameter logic [31:0] CFG_DBI_CFGSPACE_BASE = 32'hFC00_0000,
    parameter logic [31:0] CFG_DBI_PF_STRIDE     = 32'h0000_1000  // per-PF config-space window size
) (
    input         clk,
    input         reset_n,

    // DBI interface
    output logic [31:0] m_dbi_axil_awaddr,
    output logic [15:0] 	m_dbi_axil_awuser,
    output logic		m_dbi_axil_awvalid,
    output logic [2:0] 	m_dbi_axil_awprot,
    input 		        m_dbi_axil_awready,
    output logic [31:0] m_dbi_axil_wdata,
    output logic [3:0] 	m_dbi_axil_wuser,
    output logic [3:0] 	m_dbi_axil_wstrb,
    output logic 		m_dbi_axil_wvalid,
    input 		        m_dbi_axil_wready,
    input [1:0] 	    m_dbi_axil_bresp,
    input 		        m_dbi_axil_bvalid,
    input [5:0] 	    m_dbi_axil_buser,
    output logic 		m_dbi_axil_bready,
    output logic [31:0] m_dbi_axil_araddr,
    output logic 		m_dbi_axil_arvalid,
    input 		        m_dbi_axil_arready,
    output logic [15:0] m_dbi_axil_aruser,
    output logic [2:0] 	m_dbi_axil_arprot,
    input [31:0] 	    m_dbi_axil_rdata,
    input [1:0] 	    m_dbi_axil_rresp,
    input [3:0] 	    m_dbi_axil_ruser,
    input 		        m_dbi_axil_rvalid,
    output logic		m_dbi_axil_rready,

    // m_pl_axil _0 interface (Master AXI)
    input logic [11:0]  m_pl_axil_awuser,  // sideband user bits from cpm_user_aligner
    input logic [63:0] 	m_pl_axil_awaddr,
    input logic [2:0]  	m_pl_axil_awprot,
    input logic        	m_pl_axil_awvalid,
    output logic       	m_pl_axil_awready,
    input logic [31:0] 	m_pl_axil_wdata,
    input logic        	m_pl_axil_wvalid,
    input logic [3:0] 	m_pl_axil_wstrb,
    output logic       	m_pl_axil_wready,
    output logic [1:0] 	m_pl_axil_bresp,
    output logic       	m_pl_axil_bvalid,
    input         		m_pl_axil_bready,
    input  [11:0]       m_pl_axil_aruser,  // sideband user bits from cpm_user_aligner
    input  [63:0] 		m_pl_axil_araddr,
    input  [2:0]  		m_pl_axil_arprot,
    input         		m_pl_axil_arvalid,
    output logic       	m_pl_axil_arready,
    output logic [31:0] m_pl_axil_rdata,
    output logic [1:0]  m_pl_axil_rresp,
    output logic        m_pl_axil_rvalid,
    input         		m_pl_axil_rready,

    // s_flr_axi interface (full AXI4 slave) — PS's LPD_AXI_PL (R5/RPU), via
    // smartconnect_1/M_LPD_AXI_0, for FLR (Function-Level Reset) communication. Independent of
    // m_pl_axil above (that's the PCIe-side path); this is a direct PS->PL path with no CPM6/PCIe
    // involvement.
    input  logic [43:0] s_flr_axi_awaddr,
    input  logic [15:0] s_flr_axi_awid,
    input  logic [2:0]  s_flr_axi_awprot,
    input  logic [7:0]  s_flr_axi_awlen,
    input  logic [2:0]  s_flr_axi_awsize,
    input  logic [1:0]  s_flr_axi_awburst,
    input  logic        s_flr_axi_awlock,
    input  logic [3:0]  s_flr_axi_awcache,
    input  logic [3:0]  s_flr_axi_awqos,
    input  logic        s_flr_axi_awvalid,
    output logic        s_flr_axi_awready,
    input  logic [31:0] s_flr_axi_wdata,
    input  logic [3:0]  s_flr_axi_wstrb,
    input  logic        s_flr_axi_wlast,
    input  logic        s_flr_axi_wvalid,
    output logic        s_flr_axi_wready,
    output logic [15:0] s_flr_axi_bid,
    output logic [1:0]  s_flr_axi_bresp,
    output logic        s_flr_axi_bvalid,
    input  logic        s_flr_axi_bready,
    input  logic [43:0] s_flr_axi_araddr,
    input  logic [15:0] s_flr_axi_arid,
    input  logic [2:0]  s_flr_axi_arprot,
    input  logic [7:0]  s_flr_axi_arlen,
    input  logic [2:0]  s_flr_axi_arsize,
    input  logic [1:0]  s_flr_axi_arburst,
    input  logic        s_flr_axi_arlock,
    input  logic [3:0]  s_flr_axi_arcache,
    input  logic [3:0]  s_flr_axi_arqos,
    input  logic        s_flr_axi_arvalid,
    output logic        s_flr_axi_arready,
    output logic [31:0] s_flr_axi_rdata,
    output logic [15:0] s_flr_axi_rid,
    output logic [1:0]  s_flr_axi_rresp,
    output logic        s_flr_axi_rlast,
    output logic        s_flr_axi_rvalid,
    input  logic        s_flr_axi_rready,

	// DMA interrupt from DMA engin, each bit represents an interrupt from a channel. So bit0 is channel 0, bit1 is channel 1 and so on.
    input [127:0]       dma_irq,

    // MSIX interface to MSI-X table module
    output logic [10:0] pcie_msix_vector_num, // output
    (* mark_debug = "true" *)output logic [2:0]  pcie_msix_func_num, // output
    (* mark_debug = "true" *)output logic        pcie_msix_vfunc_active, // output
    (* mark_debug = "true" *)output logic [7:0]  pcie_msix_vfunc_num,   // output

    output logic [1:0]  pcie_msix_operation, // output
    (* mark_debug = "true" *)output logic        pcie_msix_req, // output
    input               pcie_msix_error, //input
    (* mark_debug = "true" *)input               pcie_msix_grant        //input
);

    // Derived constants — automatically computed from module parameters
    localparam int PF_W        = $clog2(NUM_PFS);
    localparam int VF_SLOT_W   = $clog2(NUM_VFS_PER_PF + 1);
    localparam int CHN_W       = PF_W + VF_SLOT_W;
    localparam int NUM_CHN     = NUM_PFS * (NUM_VFS_PER_PF + 1);
    localparam int NUM_FUNC    = NUM_PFS * (NUM_VFS_PER_PF + 1);  // PFs + VFs

    // =========================================================================================
    // CHANNEL <-> FUNCTION ASSIGNMENT  (customer-editable)
    //
    // Function index fi = vf_slot*NUM_PFS + pf_num   (PF n -> n;  VF v of PF n -> (v+1)*NUM_PFS + n)
    //   e.g. with 8 PFs x 4 VFs: PF0..PF7 = 0..7, PF0-VF0..PF7-VF0 = 8..15, ..., PF7-VF3 = 39.
    //
    // chn_owner_func(ch)  : the function that OWNS DMA channel `ch` (gets its MSI-X interrupts).
    // func_primary_chn(fi): the channel function `fi`'s BAR1 register bank drives / reads.
    //
    // Default is 1:1 (channel k <-> function k). Rules for edits:
    //   * channels must be < NUM_CHN, functions < NUM_FUNC (checked at elaboration);
    //   * func_primary_chn must be the inverse of chn_owner_func for each function's primary channel
    //     (chn_owner_func(func_primary_chn(fi)) == fi) -- also checked;
    //   * several channels MAY share one owner (e.g. channels 4..7 owned by function 3) as a future
    //     many-channels-per-function use; slot selection for the extra channels is not implemented yet;
    //   * the driver must program each CPM6 HDMA channel's FUNC_NUM register to the same assignment.
    // Example (swap functions 1 and 2):   return (ch == 1) ? 2 : (ch == 2) ? 1 : ch;
    // =========================================================================================
    function automatic int chn_owner_func(input int ch);
        return ch;                                  // 1:1 default
    endfunction
    function automatic int func_primary_chn(input int fi);
        return fi;                                  // 1:1 default
    endfunction
    // ---- end of customer-editable section -------------------------------------------------

    function automatic chn_map_t build_func_to_chn();
        chn_map_t m;
        m = identity_map();
        for (int f = 0; f < NUM_FUNC; f++) m[f*7 +: 7] = 7'(func_primary_chn(f));
        return m;
    endfunction
    function automatic chn_map_t build_chn_to_func();
        chn_map_t m;
        m = identity_map();
        for (int c = 0; c < NUM_CHN; c++) m[c*7 +: 7] = 7'(chn_owner_func(c));
        return m;
    endfunction
    localparam chn_map_t FUNC_TO_CHN_MAP = build_func_to_chn();
    localparam chn_map_t CHN_TO_FUNC_MAP = build_chn_to_func();
    // Default (identity) tables are bypassed at elaboration so the default netlist is exactly the
    // original hard-wired logic (no ROM, no added depth).
    localparam bit F2C_IS_IDENTITY = (FUNC_TO_CHN_MAP == identity_map());
    localparam bit C2F_IS_IDENTITY = (CHN_TO_FUNC_MAP == identity_map());

    // Elaboration-time sanity checks on the table above.
    generate
        for (genvar chk_f = 0; chk_f < NUM_FUNC; chk_f++) begin : chk_func_map
            if (map_get(FUNC_TO_CHN_MAP, chk_f) >= NUM_CHN)
                $error("FUNC_TO_CHN: function %0d maps to channel %0d (>= NUM_CHN=%0d)",
                       chk_f, map_get(FUNC_TO_CHN_MAP, chk_f), NUM_CHN);
            else if (map_get(CHN_TO_FUNC_MAP, map_get(FUNC_TO_CHN_MAP, chk_f)) != chk_f)
                $error("Channel map: function %0d's primary channel %0d is owned by function %0d",
                       chk_f, map_get(FUNC_TO_CHN_MAP, chk_f),
                       map_get(CHN_TO_FUNC_MAP, map_get(FUNC_TO_CHN_MAP, chk_f)));
        end
        for (genvar chk_c = 0; chk_c < NUM_CHN; chk_c++) begin : chk_chn_map
            if (map_get(CHN_TO_FUNC_MAP, chk_c) >= NUM_FUNC)
                $error("CHN_TO_FUNC: channel %0d owned by function %0d (>= NUM_FUNC=%0d)",
                       chk_c, map_get(CHN_TO_FUNC_MAP, chk_c), NUM_FUNC);
        end
    endgenerate
    // Single VERSION register value shared by axil_slave (BAR1 0x00) and flr_slave (0x00):
    // [31:16]=0xAA00 magic, [15]=multi-function design (more than one function, i.e. NUM_CHN > 1),
    // [7:0]=version number.
    localparam logic        MULTI_FUNC_DESIGN = (NUM_CHN > 1);
    localparam logic [31:0] DESIGN_VERSION    = {16'hAA00, MULTI_FUNC_DESIGN, 7'd0, 8'h03};
    // H2C_GLB_BASE: CPM6's fixed per-direction slot count on its real dma_irq/trigger_pending
    // bus — C2H always occupies bits [63:0], H2C always [127:64], regardless of configured
    // PF/VF count. This is silicon-fixed, NOT derived from NUM_CHN/NUM_VFS_PER_PF (unlike
    // NUM_CHN, which only counts REAL configured functions and correctly shrinks below 64).
    // Must be kept in sync with axil_slave.sv's own H2C_GLB_BASE.
    localparam int H2C_GLB_BASE = 64;
    localparam int NUM_GLB_CHN  = 2 * H2C_GLB_BASE;  // matches dma_irq/trigger_pending's fixed [127:0]

///////////// Interrupt check
// find channel number so a RR check.
//

// Interrupt control interface
logic [6:0] chn_num;  // latched from arbiter when entering SM_INT_SRD
logic       start_int;
// Interrupt status read interface (DBI read of channel int-status register after MSI-X grant)
logic           int_read_req;
logic [31:0]    int_read_addr;
logic [31:0]    int_read_data;
logic           int_read_ack;
// Interrupt clear interface
logic [NUM_CHN-1:0] irq_clr_req_c2h;       // from axil_slave: per-channel C2H clear request flags
logic [NUM_CHN-1:0] irq_clr_req_h2c;       // from axil_slave: per-channel H2C clear request flags
logic           irq_clr_done;           // to axil_slave: 1-cycle pulse when clear write completes
logic           irq_clr_done_is_c2h;    // to axil_slave: direction of completed clear
logic [CHN_W-1:0]   irq_clr_done_chn;       // to axil_slave: local channel of completed clear
logic           irq_status_wr;          // to axil_slave: 1-cycle pulse to store irq_status
logic           irq_status_is_c2h;      // to axil_slave: target irq status bank
logic [CHN_W-1:0]   irq_status_chn;         // to axil_slave: local channel index for irq_status_wr
logic [31:0]    irq_status_data;        // to axil_slave: int-status value to store
logic [CHN_W-1:0]     clr_chn;                // latched local channel for current clear operation
logic           clr_is_c2h;             // clear operation selector latched at SM_INT_IDL
logic [31:0]    irq_clr_rd_c2h_status;  // from axil_slave: per-channel C2H status for clear data
logic [31:0]    irq_clr_rd_h2c_status;  // from axil_slave: per-channel H2C status for clear data
// FLR-done handshake (0x4C flr_done_trig) -- must be declared before axil_slave's instantiation
// below, which connects these as port expressions; declaring them only at their point of use
// near the FLR controller (further down this file) left them as implicitly-declared 1-bit nets
// here, silently conflicting with the real NUM_CHN-wide declaration later -- a real bug caught by
// xvlog (Vivado synthesis tolerated it silently, auto-widening the net rather than erroring).
logic [NUM_CHN-1:0] vf_flr_done_req;     // from axil_slave: per-channel set when that function writes 0x4C
logic           flr_done_req_clr;       // to axil_slave: 1-cycle pulse, channel consumed
logic [5:0]     flr_done_req_clr_chn;   // to axil_slave: local channel index that was consumed
// Per-channel clear request arbitration: lowest-indexed C2H channel wins over H2C.
logic        any_clr_pending;
logic [CHN_W-1:0]  clr_chn_nxt;
logic        clr_is_c2h_nxt;
// Interrupt DBI write interface
logic           int_write_req;
logic [31:0]    int_write_addr;
logic [31:0]    int_write_data;
logic           int_write_ack;

// Debug status signals
logic [31:0] irq_status;
logic [31:0] msix_dbg_snapshot;
logic [31:0] msix_dbg_events;
logic [31:0] dbg_last_int_read_data;  // last raw value read from CPM6 INT_STATUS (+0x84) via DBI
                                       // — held (not zeroed later), for cross-checking against
                                       // whatever the driver independently reads/writes on ack.
logic        pcie_msix_req_d;
logic        pcie_msix_grant_d;
logic        pcie_msix_error_d;
logic        msix_req_pulse;
logic        msix_grant_pulse;
logic        msix_error_pulse;

// ----------------------------------------------------------------
// MSI-X interface arbiter: sm_int (DMA-completion interrupts, below) and the FLR controller
// (near the flr_slave instantiation) both need the single physical pcie_msix_* interface. sm_int
// keeps its existing behavior unchanged except that it now drives internal dma_msix_* signals
// instead of the real ports directly; a fixed-priority mux (DMA always wins if it's requesting)
// picks which side's signals actually reach the ports. msix_owner_is_flr_r latches which side is
// mid-transaction so a newly-arriving DMA request can't yank the interface away from an
// in-flight FLR send (or vice versa) — arbitration is only re-evaluated once the current owner's
// own request deasserts.
// ----------------------------------------------------------------
logic        msix_owner_is_flr_r;

logic        dma_msix_req;
logic [10:0] dma_msix_vector_num;
logic [2:0]  dma_msix_func_num;
logic        dma_msix_vfunc_active;
logic [7:0]  dma_msix_vfunc_num;
logic [1:0]  dma_msix_operation;
wire         dma_msix_grant = pcie_msix_grant && !msix_owner_is_flr_r;
wire         dma_msix_error = pcie_msix_error && !msix_owner_is_flr_r;

logic        flr_msix_req;
logic [10:0] flr_msix_vector_num;
logic [2:0]  flr_msix_func_num;
logic        flr_msix_vfunc_active;
logic [7:0]  flr_msix_vfunc_num;
logic [1:0]  flr_msix_operation;
wire         flr_msix_grant = pcie_msix_grant && msix_owner_is_flr_r;
wire         flr_msix_error = pcie_msix_error && msix_owner_is_flr_r;

always_ff @(posedge clk) begin
    if (!reset_n) begin
        msix_owner_is_flr_r <= 1'b0;
    end else begin
        if (msix_owner_is_flr_r) begin
            if (!flr_msix_req) msix_owner_is_flr_r <= 1'b0; // FLR's own request finished
        end else begin
            if (flr_msix_req && !dma_msix_req) msix_owner_is_flr_r <= 1'b1; // FLR grabs the idle interface
        end
    end
end

assign pcie_msix_req         = msix_owner_is_flr_r ? flr_msix_req         : dma_msix_req;
assign pcie_msix_vector_num  = msix_owner_is_flr_r ? flr_msix_vector_num  : dma_msix_vector_num;
assign pcie_msix_func_num    = msix_owner_is_flr_r ? flr_msix_func_num    : dma_msix_func_num;
assign pcie_msix_vfunc_active= msix_owner_is_flr_r ? flr_msix_vfunc_active: dma_msix_vfunc_active;
assign pcie_msix_vfunc_num   = msix_owner_is_flr_r ? flr_msix_vfunc_num   : dma_msix_vfunc_num;
assign pcie_msix_operation   = msix_owner_is_flr_r ? flr_msix_operation   : dma_msix_operation;
logic [31:0] run_status_reg;  // single 32-bit LL DMA run health dashboard (BAR1+0xB4)
logic        run_status_clr;  // 1-cycle clear pulse from axil_slave (host write to BAR1+0xB8)

// Round-robin arbiter outputs
logic [6:0] grant_chn;
logic       grant_vld;
logic [6:0] grant_chn_r;  // registered: breaks long arbiter combinatorial timing path
logic       grant_vld_r;
logic       rr_advance;  // pulse: asserted when pcie_msix_grant received
logic [127:0] dma_irq_seen;      // one-shot mask: set after service, clear when source deasserts
logic [127:0] dma_irq_eligible;  // rr arbiter input after one-shot masking
localparam [2:0]
    SM_INT_IDL  = 3'b000,
    SM_INT_SRD  = 3'b001,
    SM_INT_RDW  = 3'b010,  // wait for interrupt status read to complete (after grant)
    SM_FNC_NUM  = 3'b011,
    SM_FNC_CHN  = 3'b100,
    SM_INT_GNT  = 3'b101,
    SM_INT_CLR  = 3'b110,  // issue DBI write to clear DMA interrupt register
    SM_INT_END  = 3'b111;  // wait for DBI write ack, then pulse irq_clr_done
(* mark_debug = "true" *) logic [2:0] 	sm_int;              // state for interrupt control state machine
(* mark_debug = "true" *)logic [6:0]     h2c_chn_num, c2h_chn_num;
(* mark_debug = "true" *) logic           h2c_chn_vld, c2h_chn_vld;
logic [31:0]    int_status_add;
logic [31:0]    int_clr_addr;

// Phase 1 in-progress / deassert-confirm tracking (per-channel).
logic [NUM_GLB_CHN-1:0] phase1_in_progress_r;   // read/clear issued, not yet confirmed deasserted
logic [NUM_GLB_CHN-1:0] phase1_c2h_mode_r;      // C2H LL submode flag, latched at detection time
logic                   any_phase1_deassert;     // priority-encoder: some in-progress channel deasserted
logic [6:0]             phase1_deassert_chn_nxt; // priority-encoder: lowest-indexed such channel
logic                   any_phase1_deassert_r;   // registered 1 cycle: breaks the 128-bit two's-complement
logic [6:0]             phase1_deassert_chn_r;   // lowest-set-bit encoder's carry chain from directly
                                                  // gating the ll_phase1_done_r write in the same cycle
                                                  // it reads that register (was WNS -0.712ns via a 25-level
                                                  // LOOKAHEAD8 chain). Re-qualified against the live
                                                  // phase1_deassert_req bit before use, in case dma_irq
                                                  // reasserted during the extra cycle of latency.
logic [6:0]  phase1_done_chn;                 // relay: channel just confirmed, feeds ll_pending_r arm next cycle
logic        phase1_done_c2h_mode;            // relay: C2H LL flag for that channel

// ----------------------------------------------------------------
// LL two-phase DMA state (Phase 1=Simple DMA, Phase 2=LL DMA).
//   Phase 1 context flush always uses Simple DMA register layout;
//   after Phase 1 dma_irq, FPGA autonomously programs LL DMA (Phase 2).
//   ll_desc_lo/hi_r hold the Phase 1 dst address (latched at DBI flush).
//   ll_pending_r is the Phase 2 trigger vector (one bit per global channel).
// ----------------------------------------------------------------
logic [NUM_GLB_CHN-1:0] ll_pending_r;         // set: Ph1 IRQ ack; clear: LL DBI writes done
logic [NUM_GLB_CHN-1:0] ll_phase1_done_r;     // 1=Phase 1 done, awaiting Phase 2 IRQ + MSI-X
logic [31:0] ll_desc_lo_r [0:NUM_GLB_CHN-1];  // Phase 1 dst_lo latched at flush (LL desc base lo)
logic [31:0] ll_desc_hi_r [0:NUM_GLB_CHN-1];  // Phase 1 dst_hi latched at flush (LL desc base hi)
logic [31:0] ll_write_addr [0:4];             // LL DBI write addresses (5 writes)
logic [31:0] ll_write_data [0:4];             // LL DBI write data
logic        ll_p1_arm;                       // 1-cycle pulse: set ll_pending for current chn_num
logic        phase1_clr_r;                    // SM_INT_END is serving Phase 1 CPM6 irq clear
logic [6:0]  ll_grant_chn;                    // LL RR arbiter grant channel
logic        ll_grant_vld;                    // LL RR arbiter grant valid
logic [6:0]  ll_grant_chn_r;                  // registered: breaks long arbiter combinatorial timing path
logic        ll_grant_vld_r;
logic        ll_rr_advance;                   // pulse: advance LL RR arbiter
logic [6:0]  ll_chn_lat;                      // latched global channel for current LL DBI sequence
logic [6:0]  ll_served_chn;                   // LL RR arbiter served-channel feedback
logic [1:0]  irq_chn_dma_mode;                // dma_mode[1:0] for channel being interrupt-serviced
logic [5:0]  irq_local_chn;                   // local channel index for interrupt SM chn_num

// C2H LL mode signals (Phase 1 H2C → Phase 2 C2H LL)
logic        ll_p1_c2h_mode_r;                // 1 = current Phase 1 is for C2H LL (Phase 2 is C2H)
logic [NUM_CHN-1:0] ll_c2h_mode_r;           // per-local-channel: 1 = awaiting C2H LL Phase 2 irq
logic        ll_c2h_mode_set;                 // 1-cycle pulse from sm_dbi: set ll_c2h_mode_r
logic [CHN_W-1:0] ll_c2h_mode_set_chn;       // local channel for ll_c2h_mode_set
logic        ll_c2h_mode_clr;                 // 1-cycle pulse from sm_int: clear ll_c2h_mode_r
logic [CHN_W-1:0] ll_c2h_mode_clr_chn;       // local channel for ll_c2h_mode_clr
logic [NUM_GLB_CHN-1:0] ll_p1_deassert_seen_r; // 1 = Phase 1 irq was observed deasserted after LL writes done
                                               // Guards against spurious Phase 2 when Phase 1 irq deasserts slowly

localparam [2:0]
    DBI_IDLE       = 3'b000,
    DBI_INT_RD     = 3'b001,  // interrupt status read in progress
    DBI_WR         = 3'b010,  // single DBI write (interrupt clear)
    DBI_CTXT_WR    = 3'b011,
    DBI_CTXT_WR_DN = 3'b100,
    DBI_LL_WR      = 3'b101,  // Phase 2: LL DMA context write
    DBI_LL_WR_DN   = 3'b110,  // Phase 2: LL write sequencer
    DBI_NUMVFS_RD  = 3'b111;  // FLR controller: SR-IOV NumVFs config-space read

(* mark_debug = "true" *) logic [2:0] sm_dbi;


// Channel numnber 128, dma_irq[127:0] breakdown
// [63:0]    Write channel C2H
// [127: 64] Read channel  H2C
// Split point is the fixed H2C_GLB_BASE (CPM6's real bus boundary), NOT NUM_CHN — NUM_CHN only
// counts real configured functions and can be smaller than 64.
assign c2h_chn_num = chn_num < H2C_GLB_BASE  ? chn_num : 0;
 assign c2h_chn_vld = chn_num < H2C_GLB_BASE;
 assign h2c_chn_num = chn_num >= H2C_GLB_BASE ? chn_num - H2C_GLB_BASE : 0;
 assign h2c_chn_vld = chn_num >= H2C_GLB_BASE;
assign irq_local_chn = c2h_chn_vld ? c2h_chn_num[5:0] : h2c_chn_num[5:0];

// Interrupt Status address is bsed on Channle number + Interrupt status offset
// Interrupt address set for Controller0 (DMA/DBI register base 0xFC2C_0000; Controller1 uses 0xFC6C_0000).
assign int_status_add = 32'hFC2C_0000 + (c2h_chn_vld ? 32'h000 + (c2h_chn_num * 32'h400) + 32'h84 :
                                          h2c_chn_vld ? 32'h200 + (h2c_chn_num * 32'h400) + 32'h84 :
                                          32'h0);
assign int_clr_addr = int_status_add + 32'h8;  // clear address +8 tatus address. just write to it to clear interrupt.
assign dma_irq_eligible = dma_irq & ~dma_irq_seen;

// Priority encoder: find lowest-indexed pending clear request.
// C2H has priority over H2C when both are pending simultaneously.
// Uses the same "isolate lowest set bit via two's-complement negation" trick
// as rr_arbiter_128.sv (sel = req & (~req+1)) instead of a serial priority
// chain — avoids a long dependency chain across all NUM_CHN bits, which was
// costing ~1 LUT6 level per ~6 channels (timing violation on the related
// 128-wide phase1_deassert version, below, was measured at 21 LUT6 levels).
logic [NUM_CHN-1:0] clr_req_c2h_sel, clr_req_h2c_sel;
assign clr_req_c2h_sel = irq_clr_req_c2h & (~irq_clr_req_c2h + 1'b1);
assign clr_req_h2c_sel = irq_clr_req_h2c & (~irq_clr_req_h2c + 1'b1);

logic any_clr_c2h, any_clr_h2c;
assign any_clr_c2h     = |irq_clr_req_c2h;
assign any_clr_h2c     = |irq_clr_req_h2c;
assign any_clr_pending = any_clr_c2h | any_clr_h2c;

always_comb begin
    clr_chn_nxt    = 6'd0;
    clr_is_c2h_nxt = 1'b1;
    if (any_clr_c2h) begin
        for (int i = 0; i < NUM_CHN; i++)
            if (clr_req_c2h_sel[i]) clr_chn_nxt = i[CHN_W-1:0];
    end else if (any_clr_h2c) begin
        clr_is_c2h_nxt = 1'b0;
        for (int i = 0; i < NUM_CHN; i++)
            if (clr_req_h2c_sel[i]) clr_chn_nxt = i[CHN_W-1:0];
    end
end

// Phase 1 deassert-confirm priority encoder — same two's-complement trick as
// above. Finalizes (at most) one channel per cycle; others are picked up on
// later cycles since dma_irq staying low is a level condition, not an edge.
logic [NUM_GLB_CHN-1:0] phase1_deassert_req;
assign phase1_deassert_req = phase1_in_progress_r & ~ll_phase1_done_r & ~dma_irq;

// Lowest-set-bit index + any: two-level (16x8) encoder, no 128-bit carry chain (the two's-complement
// version this replaced synthesized to 17-20 logic levels). Same function: any = |req,
// idx = lowest set bit (0 when none).
prio_enc_128 u_phase1_deassert_enc (
    .req (phase1_deassert_req),
    .idx (phase1_deassert_chn_nxt),
    .any (any_phase1_deassert)
);

// Register the encoder's output rather than consuming it combinationally in the same
// cycle it's computed — the two's-complement negate above is a full 128-bit carry chain,
// and using its result to immediately gate a write into the very register it just read
// closed the loop in one cycle (register -> 128-bit arithmetic -> register). One cycle of
// extra latency to detect Phase 1 deassert is fine (this is a level condition, not an
// edge — see comment above). The consumer re-qualifies against the live
// phase1_deassert_req bit (a cheap single-bit mux-select, not the encoder) before acting,
// in case dma_irq reasserted during that extra cycle.
always_ff @(posedge clk) begin
    if (!reset_n) begin
        any_phase1_deassert_r <= 1'b0;
        phase1_deassert_chn_r <= 7'd0;
    end else begin
        any_phase1_deassert_r <= any_phase1_deassert;
        phase1_deassert_chn_r <= phase1_deassert_chn_nxt;
    end
end

// One MSI-X per asserted dma_irq bit: re-arm only after that bit deasserts.
always @(posedge clk) begin
  if (!reset_n) begin
    dma_irq_seen <= '0;
  end else begin
    dma_irq_seen <= dma_irq_seen & dma_irq;
    if ((sm_int == SM_INT_GNT) && dma_msix_grant && dma_irq[chn_num])
      dma_irq_seen[chn_num] <= 1'b1;
    // NOTE: ll_p1_arm no longer sets dma_irq_seen. Setting it here caused a race:
    // Phase 2 LL DMA (small transfer) can complete before Phase 1 dma_irq deasserts,
    // so dma_irq_seen[chn] stays 1 (from ll_p1_arm) while Phase 2 irq fires →
    // Phase 2 irq never becomes eligible → MSI-X blocked on repeated transfers.
    // The stale Phase 1 irq race (arbiter re-presenting chn after Phase 1) is
    // handled by the guard in SM_INT_SRD: irq_chn_dma_mode && ll_phase1_done_r &&
    // ll_pending_r[chn_num] → discard. That guard is sufficient.
  end
end

  // Main SM to controle the interrupt flow.
  // 1. Get interrupt from DMA engin 128 bits (128 channels)
  // 2. Fing Interrupt Channel in roound-robin way.
  // 3. Retch Interrupt satus for the channel that is interrupting.
  // 4. find MSI-X function from functioan table.
  // 5. send interrupt request to MSI-X table module
  // 6. once MSI-X grant/error is observed, return to IDLE
  //
  always @(posedge clk) begin
      if (!reset_n) begin
	    sm_int               <= 3'h0;
	    chn_num              <= 0;
	    start_int            <= 0;
	    dma_msix_req         <= 1'b0;
	    int_read_req         <= 1'b0;
	    int_read_addr        <= '0;
	    int_write_req        <= 1'b0;
	    int_write_addr       <= '0;
	    int_write_data       <= '0;
      irq_status_data      <= '0;
      irq_status_is_c2h    <= 1'b0;
      irq_status_chn       <= 6'd0;
	    irq_status_wr        <= 1'b0;
      irq_clr_done         <= 1'b0;
      irq_clr_done_is_c2h  <= 1'b0;
      irq_clr_done_chn     <= 6'd0;
      clr_chn              <= 6'd0;
      clr_is_c2h           <= 1'b0;
      ll_p1_arm            <= 1'b0;
      phase1_clr_r         <= 1'b0;
      ll_phase1_done_r     <= '0;
      ll_p1_c2h_mode_r     <= 1'b0;
      ll_c2h_mode_clr      <= 1'b0;
      ll_c2h_mode_clr_chn  <= '0;
      phase1_in_progress_r <= '0;
      phase1_c2h_mode_r    <= '0;
      phase1_done_chn      <= 7'd0;
      phase1_done_c2h_mode <= 1'b0;
      dbg_last_int_read_data <= '0;
      end
      else begin
	 case (sm_int)
	   SM_INT_IDL : begin
        irq_status_wr    <= 1'b0; // deassert after one-cycle pulse
        irq_clr_done     <= 1'b0; // deassert after one-cycle pulse
        ll_p1_arm        <= 1'b0; // deassert after one-cycle pulse
        ll_p1_c2h_mode_r <= 1'b0; // deassert after one-cycle pulse
        ll_c2h_mode_clr  <= 1'b0; // deassert after one-cycle pulse
        // Finalize Phase 1 one cycle after CPM6's dma_irq deassertion is confirmed
        // (any_phase1_deassert_r, registered — see declaration above) — arms Phase 2
        // with one extra cycle of latency vs. the previous same-cycle version.
        // Re-qualify against the live request bit: dma_irq may have reasserted for
        // this channel during that extra cycle, in which case skip — the encoder
        // re-evaluates every cycle from current state, so a still-deasserted channel
        // (this one or another) will be picked up again next cycle regardless.
        if (any_phase1_deassert_r && phase1_deassert_req[phase1_deassert_chn_r]) begin
            phase1_in_progress_r[phase1_deassert_chn_r] <= 1'b0;
            ll_phase1_done_r[phase1_deassert_chn_r]     <= 1'b1;
            if (phase1_c2h_mode_r[phase1_deassert_chn_r])
                ll_phase1_done_r[{1'b0, phase1_deassert_chn_r[5:0]}] <= 1'b1; // C2H global mirror
            ll_p1_arm            <= 1'b1;                                        // overrides default above
            ll_p1_c2h_mode_r     <= phase1_c2h_mode_r[phase1_deassert_chn_r]; // overrides default above
            phase1_done_chn      <= phase1_deassert_chn_r;   // relay into ll_pending_r's arm, next cycle
            phase1_done_c2h_mode <= phase1_c2h_mode_r[phase1_deassert_chn_r];
        end
        // !irq_clr_done guards the same-edge race: axil_slave clears irq_clr_req at the
        // same edge SM_INT_IDL is entered; without this gate the SM would re-trigger the
        // just-completed clear because the combinatorial any_clr_pending still sees the
        // pre-edge (old) value of irq_clr_req.
        if (any_clr_pending && ~start_int && !irq_clr_done) begin  // host-requested DMA register clear
         clr_is_c2h <= clr_is_c2h_nxt;
         clr_chn    <= clr_chn_nxt;
         sm_int     <= SM_INT_CLR;
         start_int  <= 1'b1;
        end else if (grant_vld_r && ~start_int) begin  // use registered grant to break arbiter → SM timing path
	         chn_num       <= grant_chn_r;
	         sm_int        <= SM_INT_SRD;
	         start_int     <= 1'b1;
	      end
	   end
	   SM_INT_SRD : begin                             //001 Verify interrupt still pending
	      if (dma_irq[chn_num]) begin
            if (irq_chn_dma_mode[0] && !ll_phase1_done_r[chn_num]) begin
                // Phase 1 not yet confirmed done for this channel: read status,
                // then write the clear. Rolled back to the single ll_phase1_done_r
                // gate (per-channel phase1_in_progress_r no longer blocks
                // re-entry) — this channel WILL be re-presented by the arbiter
                // while CPM6 is still settling, and each re-presentation redoes
                // the read+clear. Wasteful but intentional for now: the earlier
                // "block re-entry" optimization is suspected of interfering with
                // whatever CPM6 needs to actually accept the clear, so it's
                // rolled back until that's root-caused.
                // phase1_in_progress_r is still set here purely for BAR1+0xA4-0xB0
                // debug visibility — it no longer gates anything in this SM.
                //
                // TODO(retry-limit guard): this read+clear currently retries with
                // NO LIMIT for as long as dma_irq[chn] stays high and
                // ll_phase1_done_r[chn] stays 0 — if CPM6 never drops the line,
                // this spins forever and (since int_read_req/int_write_req have
                // top DBI priority) can starve other channels' DBI traffic.
                // Deliberately left unguarded for now to test whether repeated
                // attempts are what CPM6 actually needs. Once that's answered,
                // add a per-channel retry counter (~5 attempts) here: on exceeding
                // it, give up on this channel (e.g. set a new sticky "phase1 clear
                // exhausted" debug bit) instead of retrying indefinitely.
                phase1_in_progress_r[chn_num] <= 1'b1;
                phase1_c2h_mode_r[chn_num]    <= irq_chn_dma_mode[1];
                phase1_clr_r                  <= 1'b1;
                int_read_req                  <= 1'b1;
                int_read_addr                 <= int_status_add;
                sm_int                        <= SM_INT_RDW;
            end else if (irq_chn_dma_mode[0] && ll_phase1_done_r[chn_num] && ll_pending_r[chn_num]) begin
                // Legacy Guard 2 — stale Phase 1 irq re-presentation after
                // ll_phase1_done_r is already set but Phase 2 LL writes aren't
                // flushed yet.
                start_int <= 1'b0;
                sm_int    <= SM_INT_IDL;
            end else begin
                // Simple mode OR Phase 2 LL completion
                sm_int <= SM_FNC_NUM;
            end
	      end else begin
	         // IRQ already cleared by DMA engine: release channel and return to IDLE
	         start_int <= 1'b0;
	         sm_int    <= SM_INT_IDL;
	      end
	   end
	   SM_FNC_NUM : begin                            //011 look up function number from func_vec_table
	      sm_int <= SM_FNC_CHN;
	   end

	   SM_FNC_CHN : begin                             // 100 send MSI-X interrupt request
	      dma_msix_req <= 1'b1;
	      sm_int <= SM_INT_GNT;
	   end
	   SM_INT_GNT : begin                             // 101 Wait for Interrupt Grant
        if (dma_msix_grant || dma_msix_error) begin
          sm_int        <= SM_INT_RDW;  // read interrupt status before returning to IDLE
		      dma_msix_req  <= 1'b0;
		      int_read_req   <= 1'b1;      // kick off DBI read
		      int_read_addr  <= int_status_add;
	      end
     end
	   SM_INT_RDW : begin                             // 010 Wait for interrupt status read
	      irq_status_wr <= 1'b0;  // deassert after one-cycle pulse
	      ll_c2h_mode_clr <= 1'b0;  // deassert after one-cycle pulse
	      if (int_read_ack) begin
           int_read_req <= 1'b0;
           dbg_last_int_read_data <= int_read_data;  // capture raw +0x84 value regardless of caller
           if (phase1_clr_r) begin
               // Phase 1 path: use the read value (masked to the 3 real
               // clearable bits) as write-to-clear data for +0x8C.
               int_write_req  <= 1'b1;
               int_write_addr <= int_clr_addr;   // CPM6 irq clear (base + 0x8C)
               int_write_data <= {29'b0, int_read_data[2:0]};  // mask to ABORT/WATERMARK/STOP clear bits
               sm_int         <= SM_INT_END;
           end else begin
               // Phase 2 path: store status for host (BAR1+0x44/0x24), clean up flags
               irq_status_is_c2h <= c2h_chn_vld;
               irq_status_chn    <= c2h_chn_vld ? c2h_chn_num[CHN_W-1:0] : h2c_chn_num[CHN_W-1:0];
               irq_status_data   <= int_read_data;
	             irq_status_wr     <= 1'b1;
	             if (ll_phase1_done_r[chn_num]) begin
	                 // Phase 2 LL DMA complete: clear tracking flags and return to IDLE.
	                 // ll_disable (+0x34=0) is handled by Phase 1 context flush (ctxt_write_addr[0])
	                 // before the next doorbell; CPM6 ignores +0x34 writes during post-LL-DMA
	                 // wind-down so writing it here is unnecessary.
	                 ll_phase1_done_r[chn_num] <= 1'b0;
	                 if (ll_c2h_mode_r[irq_local_chn]) begin
	                     ll_phase1_done_r[chn_num | 7'(H2C_GLB_BASE)] <= 1'b0;
	                     ll_c2h_mode_clr     <= 1'b1;
	                     ll_c2h_mode_clr_chn <= irq_local_chn;
	                 end
	             end
	             sm_int    <= SM_INT_IDL;
	             start_int <= 1'b0;
           end
	      end
	   end
	   SM_INT_CLR : begin                             // 110 Issue DBI write to clear DMA int reg
	      int_write_req  <= 1'b1;
        // Compute clear address from clr_chn on the fly (no separate latch needed)
        int_write_addr <= clr_is_c2h ?
            (32'hFC2C_0000 + ({16'b0, clr_chn, 10'b0}) + 32'h0000_008C) :
            (32'hFC2C_0000 + 32'h0000_0200 + ({16'b0, clr_chn, 10'b0}) + 32'h0000_008C);
        // Use per-channel status from axil_slave read port for write-to-clear data
        int_write_data <= clr_is_c2h ? {29'b0, irq_clr_rd_c2h_status[2:0]} :
                                       {29'b0, irq_clr_rd_h2c_status[2:0]};
	      sm_int         <= SM_INT_END;
	   end
	   SM_INT_END : begin                             // 111 Wait for DBI write ack
	      ll_p1_arm <= 1'b0;   // deassert Phase-2 arm pulse (set one cycle, cleared here)
	      if (int_write_ack) begin
           int_write_req <= 1'b0;
           if (phase1_clr_r) begin
               // Clear write acknowledged by CPM6. phase1_in_progress_r[chn_num]
               // stays set (from SM_INT_SRD); SM_INT_IDL's scan finalizes this
               // channel once dma_irq[chn_num] is confirmed low.
               phase1_clr_r <= 1'b0;
               sm_int    <= SM_INT_IDL;
               start_int <= 1'b0;
           end else begin
               // Normal host-requested clear path
               irq_status_is_c2h    <= clr_is_c2h;
               irq_status_chn       <= clr_chn;  // zero out this channel's status
               irq_status_data      <= 32'h0;
               irq_status_wr        <= 1'b1;     // clear host-visible per-channel irq status
               irq_clr_done         <= 1'b1;     // single done pulse
               irq_clr_done_is_c2h  <= clr_is_c2h;
               irq_clr_done_chn     <= clr_chn;
	             sm_int               <= SM_INT_IDL;
	             start_int            <= 1'b0;
           end
	      end
	   end
	 endcase // case (sm_int)
      end // else: !if(!reset_n)
   end // always @ (posedge clk)


//
// DBI interface state machine — handles context writes and interrupt status reads.
//
localparam [2:0]
    AXILM_IDLE = 3'b000,
    AXILM_W    = 3'b001,
    AXILM_W_B  = 3'b010,
    AXILM_R    = 3'b011,  // AR accepted, waiting for R data
    AXILM_R_RS = 3'b100;  // R data received

(* mark_debug = "true" *)logic        st_dbi_rd;
(* mark_debug = "true" *)logic        st_dbi_wr;
(* mark_debug = "true" *)logic [31:0] dbi_rd_addr;
(* mark_debug = "true" *)logic [31:0] dbi_rd_data;
(* mark_debug = "true" *)logic [31:0] dbi_wr_addr;
(* mark_debug = "true" *)logic [31:0] dbi_wr_data;
(* mark_debug = "true" *)logic        read_done;
(* mark_debug = "true" *)logic        read_error;

(* mark_debug = "true" *) logic [2:0] sm_axilm;
logic [31:0] ctxt_write_addr [0:7];
logic [31:0] ctxt_write_data [0:7];
logic [3:0]  wr_count;
localparam [3:0] NUM_WR    = 4'd7;  // DBI writes per Simple DMA context flush (incl. ll_disable)
localparam [3:0] NUM_LL_WR = 4'd5;  // DBI writes per LL DMA context flush (Phase 2)
(* mark_debug = "true" *)logic write_done;


// ----------------------------------------------------------------
// Interrupt path: PF/VF reverse lookup for the MSI-X request interface.
// Uses the shared axil_slave_pkg functions (same forward/reverse formula
// used by axil_slave's own channel indexing) rather than a local copy, so
// the two can't drift apart.
//   irq_chn's PF number is channel_to_pf(irq_chn) = irq_chn[2:0], correct
//   for both PF- and VF-owned channels since PF number is purely a
//   function of the channel's position within its 8-wide slot group
//   (channels are grouped by slot across all PFs; see axil_slave_pkg.sv).
//   pcie_msix_vfunc_num converts the channel's local slot back to CPM6's
//   expected GLOBAL vfunc_num format (pf_num*7 + pf_rel_vf).
// ----------------------------------------------------------------
logic [6:0] irq_chn;
assign irq_chn = c2h_chn_vld ? c2h_chn_num : h2c_chn_num;

// 8 vectors available per function (genBd.tcl MSIX_VECTORS=8, headroom for future use);
// only 2 currently assigned:
//   C2H -> 0
//   H2C -> 2
// Vectors 1, 3-7 are unused/reserved for now.
// Vector is table-relative; pcie_msix_func_num selects which PF MSI-X table.
assign dma_msix_vector_num   = c2h_chn_vld ? 11'd0 :
                                h2c_chn_vld ? 11'd2 :
                                11'hFF;

assign dma_msix_operation    = 2'b00;
// channel -> owning function (CHN_TO_FUNC_MAP, top of file) -> PF/VF numbers sent with the MSI-X
wire [6:0] irq_func = C2F_IS_IDENTITY ? irq_chn : chn_to_func(irq_chn, CHN_TO_FUNC_MAP);
assign dma_msix_func_num     = channel_to_pf(irq_func, PF_W);
assign dma_msix_vfunc_active = channel_to_vfunc_active(irq_func, PF_W, VF_SLOT_W);
assign dma_msix_vfunc_num    = channel_to_vfunc_num(irq_func, PF_W, VF_SLOT_W);

// Interrupt status debug register
assign irq_status = {13'b0,
                     chn_num[6:0],    // [18:12] channel being processed (bit[6]=1 means H2C)
                     pcie_msix_error, // [11]    MSI-X error
                     grant_vld,       // [10]    RR arbiter has pending grant
                     start_int,       // [9]     interrupt processing in-flight
                     sm_dbi,          // [8:6]   DBI access SM state
                     sm_int,          // [5:3]   interrupt SM state
                     pcie_msix_grant, // [2]     MSI-X grant received
                     pcie_msix_req,   // [1]     MSI-X request asserted
                     |dma_irq};       // [0]     any DMA interrupt pending

assign msix_req_pulse   = pcie_msix_req   & ~pcie_msix_req_d;
assign msix_grant_pulse = pcie_msix_grant & ~pcie_msix_grant_d;
assign msix_error_pulse = pcie_msix_error & ~pcie_msix_error_d;

// Capture MSI-X req/grant/error pulses and snapshot outputs at request time
always @(posedge clk) begin
    if (!reset_n) begin
        pcie_msix_req_d   <= 1'b0;
        pcie_msix_grant_d <= 1'b0;
        pcie_msix_error_d <= 1'b0;
        msix_dbg_snapshot <= 32'h0;
        msix_dbg_events   <= 32'h0;
    end else begin
        pcie_msix_req_d   <= pcie_msix_req;
        pcie_msix_grant_d <= pcie_msix_grant;
        pcie_msix_error_d <= pcie_msix_error;

        if (msix_req_pulse) begin
            msix_dbg_snapshot <= {
                sm_int,                  // [31:29] interrupt SM state
                sm_dbi,                  // [28:26] DBI SM state
                pcie_msix_req,           // [25]    req asserted on this pulse
                pcie_msix_operation,     // [24:23]
                pcie_msix_vfunc_num,     // [22:15]
                pcie_msix_vfunc_active,  // [14]
                pcie_msix_func_num,      // [13:11]
                pcie_msix_vector_num     // [10:0]
            };
            msix_dbg_events[11:9] <= sm_dbi;
            msix_dbg_events[8:6]  <= sm_int;
            msix_dbg_events[5:3]  <= sm_axilm;
        end

        if (msix_req_pulse)   msix_dbg_events[0] <= 1'b1;
        if (msix_grant_pulse) msix_dbg_events[1] <= 1'b1;
        if (msix_error_pulse) msix_dbg_events[2] <= 1'b1;
    end
end


// ----------------------------------------------------------------
// Per-channel concurrent context-write arbitration.
//   axil_slave now stores each of the 64 PF/VF functions' context in its
//   own bank, and exposes trigger_pending[127:0] (dma_irq-style: [63:0]=
//   C2H channel, [127:64]=H2C channel) as the single source of truth for
//   which channels have a completed-but-unflushed doorbell trigger.
//   A second rr_arbiter_128 instance (same module already used for
//   dma_irq) round-robins over trigger_pending, so multiple functions can
//   have their context staged/triggered independently without waiting on
//   each other; the single physical DBI master still flushes one
//   channel's 6-word context at a time.
// ----------------------------------------------------------------
logic [127:0] trigger_pending;
logic         trigger_clear_vld;
logic [6:0]   trigger_clear_chn;
logic [6:0]   ctxt_rd_chn;
axil_regs_t   ctxt_rd_regs;
logic [1:0]   ctxt_rd_dma_mode;  // DMA mode for channel being flushed (0=Simple,1=H2C LL,2=C2H LL)
logic [6:0]   ctxt_chn_lat;   // latched global channel currently being flushed

logic [6:0]   ctxt_grant_chn;
logic         ctxt_grant_vld;
logic [6:0]   ctxt_grant_chn_r;  // registered: breaks long arbiter combinatorial timing path
logic         ctxt_grant_vld_r;
logic         ctxt_rr_advance;
logic [6:0]   ctxt_served_chn;
// Declared here (not at point of use further down) because they're referenced in DBI_IDLE's
// stale-grant guard below, before their own always_ff (much later in this file) — xvlog flags
// use-before-declaration as an error; Vivado synthesis tolerated it silently. See that always_ff
// for why these registered copies exist.
logic ctxt_rr_advance_r, ll_rr_advance_r;

assign ctxt_rd_chn = ctxt_chn_lat;




// Context write address formulas:
//   H2C base = 0xFC2C_0000 + 0x200 + (chn * 0x400)
//   C2H base = 0xFC2C_0000 + 0x000 + (chn * 0x400)
//   Registers: ll_disable(+0x34=0), size(+0x1C), src_lo(+0x20), src_hi(+0x24),
//              dst_lo(+0x28), dst_hi(+0x2C), doorbell(+0x04)
// +0x34=0 is written BEFORE the doorbell (channel is idle) — CPM6 ignores this
// write in the post-LL-DMA wind-down state, so ctxt_write_addr[0] is the sole
// reliable ll_disable opportunity.
// Built from ctxt_chn_lat/ctxt_rd_regs (the arbitrated channel currently
// being flushed), not the live bus sideband — multiple functions can have
// triggers queued, so the channel being flushed may differ from whatever
// transaction is happening on the AXI-Lite bus right now.
 always_comb begin : context_write
    automatic logic        ctxt_is_c2h;
    automatic logic [6:0]  ctxt_local_chn;
    automatic logic [31:0] ctxt_base;
    // Default all elements to 0 to prevent latch inference for unused indices [6:7]
    ctxt_write_addr = '{default: '0};
    ctxt_write_data = '{default: '0};
    ctxt_is_c2h    = glb_chn_is_c2h(ctxt_chn_lat);
    ctxt_local_chn = glb_chn_local(ctxt_chn_lat);
    ctxt_base = ctxt_is_c2h ? (32'hFC2C_0000 + (ctxt_local_chn * 32'h400))
                             : (32'hFC2C_0000 + 32'h200 + (ctxt_local_chn * 32'h400));
    // Write[0]: clear ll_enable BEFORE doorbell — channel is idle at this point
    // so CPM6 accepts the write. This is the sole ll_disable write; CPM6 ignores
    // writes to +0x34 during post-LL-DMA wind-down so no additional write is needed
    // after Phase 2 completion.
    ctxt_write_addr[0] = ctxt_base + 32'h34; // LL mode disable
    ctxt_write_data[0] = 32'h0;
    ctxt_write_addr[1] = ctxt_base + 32'h1C; // Size
    ctxt_write_data[1] = ctxt_rd_regs.reg0;
    ctxt_write_addr[2] = ctxt_base + 32'h20; // Src addr Lo
    ctxt_write_data[2] = ctxt_rd_regs.reg1;
    ctxt_write_addr[3] = ctxt_base + 32'h24; // Src addr Hi
    ctxt_write_data[3] = ctxt_rd_regs.reg2;
    ctxt_write_addr[4] = ctxt_base + 32'h28; // Dst addr Lo  (= LL descriptor base lo for Phase 2)
    ctxt_write_data[4] = ctxt_rd_regs.reg3;
    ctxt_write_addr[5] = ctxt_base + 32'h2C; // Dst addr Hi  (= LL descriptor base hi for Phase 2)
    ctxt_write_data[5] = ctxt_rd_regs.reg4;
    ctxt_write_addr[6] = ctxt_base + 32'h04; // Doorbell
    ctxt_write_data[6] = 32'h1;
 end

// ----------------------------------------------------------------
// LL DMA context write address/data (Phase 2, FPGA-autonomous).
//   5 writes: LL_enable(+0x34=0x1), cycle_set(+0x18=0x2),
//             desc_lo(+0x10), desc_hi(+0x14), doorbell(+0x04=0x1).
//   Descriptor address latched from Phase 1 dst_lo/hi at DBI flush time.
// ----------------------------------------------------------------
 always_comb begin : ll_context_write
    automatic logic        ll_is_c2h;
    automatic logic [6:0]  ll_local_chn;
    automatic logic [31:0] ll_base;
    ll_write_addr = '{default: '0};
    ll_write_data = '{default: '0};
    ll_is_c2h    = glb_chn_is_c2h(ll_chn_lat);
    ll_local_chn = glb_chn_local(ll_chn_lat);
    ll_base = ll_is_c2h ? (32'hFC2C_0000 + (ll_local_chn * 32'h400))
                        : (32'hFC2C_0000 + 32'h200 + (ll_local_chn * 32'h400));
    ll_write_addr[0] = ll_base + 32'h34; ll_write_data[0] = 32'h1;                    // LL mode enable
    ll_write_addr[1] = ll_base + 32'h18; ll_write_data[1] = 32'h3;                    // Cycle set = 0x3 (w_din[1]=1 → CCS=1, confirmed from SECUREIP ctx_ccs=w_din[1])
    ll_write_addr[2] = ll_base + 32'h10; ll_write_data[2] = ll_desc_lo_r[ll_chn_lat]; // Descriptor addr lo
    ll_write_addr[3] = ll_base + 32'h14; ll_write_data[3] = ll_desc_hi_r[ll_chn_lat]; // Descriptor addr hi
    ll_write_addr[4] = ll_base + 32'h04; ll_write_data[4] = 32'h1;                    // Doorbell
 end

// DBI state machine to handle context programming writes from the PL master.
// Context will be written via mpl_axil interface.


assign m_dbi_axil_aruser = 'h0;
assign m_dbi_axil_arprot = 'h0;
assign m_dbi_axil_wuser  = 'h0;
assign m_dbi_axil_wstrb  = 4'hF;
assign m_dbi_axil_awprot = 'h0;
assign m_dbi_axil_awuser = 'h0;
assign m_dbi_axil_bready = 1'b1;

// FLR controller -> DBI NumVFs read (declared here, ahead of first use in the DBI mux below;
// the FLR controller that drives flr_numvfs_rd_req/addr is further down)
logic        flr_numvfs_rd_req;
logic        flr_numvfs_rd_ack;
logic [31:0] flr_numvfs_rd_addr;

assign dbi_rd_addr    = (sm_dbi == DBI_INT_RD)     ? int_read_addr              :
                        (sm_dbi == DBI_NUMVFS_RD) ? flr_numvfs_rd_addr          : 'h0;
assign dbi_wr_addr    = (sm_dbi == DBI_WR)       ? int_write_addr             :
                        (sm_dbi == DBI_CTXT_WR)  ? ctxt_write_addr[wr_count]  :
                        (sm_dbi == DBI_LL_WR)    ? ll_write_addr[wr_count]    : 'h0;
assign dbi_wr_data    = (sm_dbi == DBI_WR)       ? int_write_data             :
                        (sm_dbi == DBI_CTXT_WR)  ? ctxt_write_data[wr_count]  :
                        (sm_dbi == DBI_LL_WR)    ? ll_write_data[wr_count]    : 'h0;
assign int_read_ack   = (sm_dbi == DBI_INT_RD) & read_done;
assign int_write_ack  = (sm_dbi == DBI_WR) & write_done;
assign int_read_data  = dbi_rd_data;
assign flr_numvfs_rd_ack = (sm_dbi == DBI_NUMVFS_RD) & read_done;

always @(posedge clk) begin
  if (!reset_n) begin
    sm_dbi    <= DBI_IDLE;
    st_dbi_rd <= 1'b0;
    st_dbi_wr <= 1'b0;
    wr_count  <= 0;
    ctxt_chn_lat      <= 7'd0;
    trigger_clear_vld <= 1'b0;
    trigger_clear_chn <= 7'd0;
    ctxt_rr_advance   <= 1'b0;
    ctxt_served_chn   <= 7'd0;
    ll_chn_lat        <= 7'd0;
    ll_rr_advance     <= 1'b0;
    ll_served_chn     <= 7'd0;
    ll_c2h_mode_set     <= 1'b0;
    ll_c2h_mode_set_chn <= '0;
    for (int i = 0; i < NUM_GLB_CHN; i++) begin
      ll_desc_lo_r[i] <= '0;
      ll_desc_hi_r[i] <= '0;
    end
  end else begin
    case (sm_dbi)
      DBI_IDLE : begin
        st_dbi_rd <= 1'b0;
        st_dbi_wr <= 1'b0;
        trigger_clear_vld <= 1'b0;  // deassert after one-cycle pulse
        ctxt_rr_advance   <= 1'b0;  // deassert after one-cycle pulse
        ll_rr_advance     <= 1'b0;  // deassert after one-cycle pulse
        ll_c2h_mode_set   <= 1'b0;  // deassert after one-cycle pulse
        if (int_read_req) begin          // interrupt status read has priority
          sm_dbi    <= DBI_INT_RD;
          st_dbi_rd <= 1'b1;
        end else if (int_write_req) begin // interrupt clear / Phase 1 CPM6 irq clear
          sm_dbi    <= DBI_WR;
          st_dbi_wr <= 1'b1;
        end else if (ctxt_grant_vld_r && !ctxt_rr_advance && !ctxt_rr_advance_r) begin // Phase 1: Simple DMA context flush
          // ctxt_rr_advance/_r guard: when DBI_CTXT_WR_DN fires, ctxt_rr_advance=1 and
          // trigger_clear_vld=1 are both asserted on the same cycle that sm_dbi returns
          // to DBI_IDLE. axil_slave's trigger_pending_r and the arbiter's internal
          // last_served both clear/advance one cycle later, so the raw (unregistered)
          // ctxt_grant_vld is still stale-1 for that entire cycle — and because
          // ctxt_grant_vld_r is itself registered from that raw value, the staleness
          // shows up in ctxt_grant_vld_r one cycle further out still, after
          // ctxt_rr_advance has already reverted to 0. Without both terms, DBI_IDLE
          // would spuriously re-trigger the same channel's 7-write context flush
          // (including doorbell) a second time. ctxt_rr_advance covers the first stale
          // cycle, ctxt_rr_advance_r (its registered copy) covers the second.
          ctxt_chn_lat <= ctxt_grant_chn_r;
          sm_dbi    <= DBI_CTXT_WR;
          st_dbi_wr <= 1'b1;
          wr_count  <= 4'd0;
        end else if (ll_grant_vld_r && !ll_rr_advance && !ll_rr_advance_r) begin  // Phase 2: LL DMA programming
          // ll_rr_advance/_r guard: same two-stage staleness as ctxt_rr_advance above —
          // ll_pending_r[chn] and the LL arbiter's last_served both update one cycle
          // after ll_rr_advance fires, and ll_grant_vld_r's own registration pushes the
          // stale window out one cycle further. Both terms needed to prevent spurious
          // re-entry into DBI_LL_WR (a duplicate LL doorbell) for the same channel.
          ll_chn_lat <= ll_grant_chn_r;
          sm_dbi    <= DBI_LL_WR;
          st_dbi_wr <= 1'b1;
          wr_count  <= 4'd0;
        end else if (flr_numvfs_rd_req) begin // FLR controller: PF-level FLR's SR-IOV NumVFs read.
          // Lowest priority -- FLR is rare and not latency-sensitive (it already budgets up to
          // 10ms for VF acks), so it simply waits its turn behind the DMA/interrupt traffic above.
          sm_dbi    <= DBI_NUMVFS_RD;
          st_dbi_rd <= 1'b1;
        end
      end

      DBI_NUMVFS_RD : begin
        st_dbi_rd <= 1'b0;
        if (read_done)
          sm_dbi <= DBI_IDLE;
      end

      DBI_INT_RD : begin
        st_dbi_rd <= 1'b0;
        if (read_done)
          sm_dbi <= DBI_IDLE;
      end

      DBI_WR : begin
        st_dbi_wr <= 1'b0;
        if (write_done)
          sm_dbi <= DBI_IDLE;
      end

      DBI_CTXT_WR : begin
        st_dbi_wr <= 1'b0;
        if (write_done) begin
          sm_dbi <= DBI_CTXT_WR_DN;
          wr_count <= wr_count + 1;
        end
      end

      DBI_CTXT_WR_DN : begin
        st_dbi_wr <= 1'b0;
        if (wr_count == NUM_WR) begin
          sm_dbi   <= DBI_IDLE;
          wr_count <= 4'd0;
          trigger_clear_vld <= 1'b1;   // release this channel's stall in axil_slave
          trigger_clear_chn <= ctxt_chn_lat;
          ctxt_rr_advance   <= 1'b1;   // advance the RR pointer past this channel
          ctxt_served_chn   <= ctxt_chn_lat;
          // For LL-mode channels, latch descriptor address for Phase 2 LL programming
          if (ctxt_rd_dma_mode[0]) begin
            if (ctxt_rd_dma_mode[1]) begin
              // C2H LL: latch at C2H global index (local_chn = ctxt_chn_lat[5:0])
              ll_desc_lo_r[{1'b0, ctxt_chn_lat[5:0]}] <= ctxt_rd_regs.reg3;
              ll_desc_hi_r[{1'b0, ctxt_chn_lat[5:0]}] <= ctxt_rd_regs.reg4;
              ll_c2h_mode_set     <= 1'b1;
              ll_c2h_mode_set_chn <= ctxt_chn_lat[CHN_W-1:0];  // local_chn
            end else begin
              // H2C LL: latch at H2C global index (existing)
              ll_desc_lo_r[ctxt_chn_lat] <= ctxt_rd_regs.reg3;
              ll_desc_hi_r[ctxt_chn_lat] <= ctxt_rd_regs.reg4;
            end
          end
        end else begin
          sm_dbi <= DBI_CTXT_WR;
          st_dbi_wr <= 1'b1;
        end
      end

      DBI_LL_WR : begin                 // Phase 2: write one LL DMA register
        st_dbi_wr <= 1'b0;
        if (write_done) begin
          sm_dbi   <= DBI_LL_WR_DN;
          wr_count <= wr_count + 1;
        end
      end

      DBI_LL_WR_DN : begin              // Phase 2: advance or finish LL write sequence
        st_dbi_wr <= 1'b0;
        if (wr_count == NUM_LL_WR) begin
          sm_dbi        <= DBI_IDLE;
          wr_count      <= 4'd0;
          ll_rr_advance <= 1'b1;        // clears ll_pending[ll_chn_lat] via ll_pending_r always_ff
          ll_served_chn <= ll_chn_lat;
        end else begin
          sm_dbi    <= DBI_LL_WR;
          st_dbi_wr <= 1'b1;
        end
      end

      default : sm_dbi <= DBI_IDLE;
    endcase
  end
end

// ----------------------------------------------------------------
// ll_pending_r: Phase 2 trigger vector.
//   Set by 1-cycle pulse ll_p1_arm (from sm_int, Phase 1 CPM6 irq ack).
//   For H2C LL: arm ll_pending_r[chn_num] (H2C global = 64+local).
//   For C2H LL: arm ll_pending_r[h2c_chn_num] (C2H global = local_chn).
//   Cleared by 1-cycle pulse ll_rr_advance (from sm_dbi, LL DBI writes done).
// ----------------------------------------------------------------
always_ff @(posedge clk) begin
    if (!reset_n)
        ll_pending_r <= '0;
    else begin
        // Use phase1_done_chn (saved at Phase 1 completion in SM_INT_IDL, alongside
        // ll_p1_arm) rather than chn_num, because chn_num may have been updated to a
        // different channel by the time ll_p1_arm is consumed here.
        if (ll_p1_arm) begin
            if (phase1_done_c2h_mode)
                ll_pending_r[{1'b0, phase1_done_chn[5:0]}] <= 1'b1;  // C2H global = local_chn
            else
                ll_pending_r[phase1_done_chn]               <= 1'b1;  // H2C global
        end
        if (ll_rr_advance) ll_pending_r[ll_chn_lat] <= 1'b0;
    end
end

// ----------------------------------------------------------------
// ll_c2h_mode_r: per-local-channel flag, set when DBI_CTXT_WR_DN detects
//   C2H LL mode (ctxt_rd_dma_mode[1]=1), cleared after Phase 2 C2H MSI-X.
//   Used by SM_INT_RDW to clean up H2C ll_phase1_done_r index.
// ----------------------------------------------------------------
always_ff @(posedge clk) begin
    if (!reset_n)
        ll_c2h_mode_r <= '0;
    else begin
        if (ll_c2h_mode_set) ll_c2h_mode_r[ll_c2h_mode_set_chn] <= 1'b1;
        if (ll_c2h_mode_clr) ll_c2h_mode_r[ll_c2h_mode_clr_chn] <= 1'b0;
    end
end

// ----------------------------------------------------------------
// ll_p1_deassert_seen_r: per-channel flag set once dma_irq deasserts
//   after Phase 1 LL DBI writes complete (ll_pending=0, phase1_done=1).
//   Prevents SM_INT_SRD from treating a slow-to-deassert Phase 1 irq
//   as a Phase 2 completion, which would cause a spurious MSI-X and
//   block the real Phase 2 irq (dma_irq_seen stuck=1).
//   Set: when ll_phase1_done_r[i]=1, ll_pending_r[i]=0, dma_irq[i]=0
//   Cleared: when SM_INT_RDW finishes Phase 2 for that channel.
// ----------------------------------------------------------------
always_ff @(posedge clk) begin
    if (!reset_n)
        ll_p1_deassert_seen_r <= '0;
    else begin
        // Vector update: arm channels where Phase 1 is done AND irq now low.
        // NOTE: ll_pending_r is intentionally NOT required here — Phase 1 irq typically
        // deasserts DURING the LL DBI write sequence (ll_pending_r=1), which is before
        // the doorbell write completes. For fast channels (PF0), waiting for ll_pending_r=0
        // is too late: Phase 2 fires immediately after doorbell and dma_irq never goes
        // low while ll_pending_r=0. Guard 2 (ll_pending_r=1 stall) prevents SM_INT_SRD
        // from acting on the armed flag until LL writes are fully done.
        ll_p1_deassert_seen_r <= ll_p1_deassert_seen_r |
                                  (ll_phase1_done_r & ~dma_irq);
        // Clear when Phase 2 complete (SM_INT_RDW acks and clears ll_phase1_done_r)
        if (sm_int == SM_INT_RDW && int_read_ack && ll_phase1_done_r[chn_num]) begin
            ll_p1_deassert_seen_r[chn_num] <= 1'b0;
            // For C2H LL: also clear H2C global index (local_chn | H2C_GLB_BASE)
            if (ll_c2h_mode_r[irq_local_chn])
                ll_p1_deassert_seen_r[chn_num | 7'(H2C_GLB_BASE)] <= 1'b0;
        end
    end
end

// ----------------------------------------------------------------
// run_status_reg: live LL DMA status diagnostic register (BAR1+0xB4).
//   Live fields updated every clock. Sticky error bits accumulate
//   until host writes to BAR1+0xB8 (axil_slave pulses run_status_clr).
//   [2:0]  phase : 0=idle, 1=Ph1 running, 2=Ph2 LL DBI writes,
//                  3=Ph2 DMA running (awaiting irq), 4=MSI-X in flight,
//                  5=done waiting host clear, 6=Ph1 DBI read+write,
//                  7=Ph1 deassert wait (CPM6 slow to drop dma_irq)
//   [3]    any context flush pending (trigger_pending non-zero)
//   [4]    MSI-X error (sticky)
//   [5]    Guard 2 fired — stale Phase 1 irq discarded (sticky)
//   [6]    start_int — interrupt processing in-flight (live)
//   [7]    grant_vld — arbiter has a pending grant (live)
//   [14:8] chn_num — channel currently being processed (live)
//   [16]   any ll_pending active — Phase 2 LL DBI writes (live)
//   [17]   any ll_phase1_done active — between Ph1 irq and Ph2 (live)
//   [20:18] sm_int state (live)
//   [23:21] sm_dbi state (live)
// ----------------------------------------------------------------
always_ff @(posedge clk) begin
    if (!reset_n || run_status_clr) begin
        run_status_reg <= '0;
    end else begin
        // --- Live fields (overwritten every clock) ---
        run_status_reg[2:0]   <= (phase1_clr_r)                                              ? 3'd6 :
                                  (|phase1_in_progress_r)                                    ? 3'd7 :
                                  (sm_int == SM_FNC_NUM || sm_int == SM_FNC_CHN ||
                                   sm_int == SM_INT_GNT || sm_int == SM_INT_RDW)             ? 3'd4 :
                                  (|ll_phase1_done_r && ~|ll_pending_r)                      ? 3'd3 :
                                  |ll_pending_r                                              ? 3'd2 :
                                  (|dma_irq && !grant_vld && !start_int)                    ? 3'd5 :
                                  (start_int || sm_dbi != 3'b000 || |trigger_pending)        ? 3'd1 :
                                                                                             3'd0;
        run_status_reg[3]     <= |trigger_pending;
        run_status_reg[6]     <= start_int;
        run_status_reg[7]     <= grant_vld;
        run_status_reg[14:8]  <= chn_num;
        run_status_reg[15]    <= 1'b0;        // reserved — explicit 0 to avoid undriven FF
        run_status_reg[16]    <= |ll_pending_r;
        run_status_reg[17]    <= |ll_phase1_done_r;
        run_status_reg[20:18] <= sm_int;
        run_status_reg[23:21] <= sm_dbi;
        run_status_reg[31:24] <= 8'h0;        // reserved — explicit 0 to avoid undriven FF
        // --- Sticky error flags (OR-accumulate, cleared only by run_status_clr) ---
        if (msix_error_pulse)
            run_status_reg[4] <= 1'b1;
        if (sm_int == SM_INT_SRD && dma_irq[chn_num] &&
            irq_chn_dma_mode[0] && ll_phase1_done_r[chn_num] && ll_pending_r[chn_num])
            run_status_reg[5] <= 1'b1;
    end
end

always @(posedge clk) begin
  if (!reset_n) begin
    sm_axilm           <= AXILM_IDLE;
    m_dbi_axil_araddr  <= 'h0;
    m_dbi_axil_arvalid <= 'h0;
    m_dbi_axil_rready  <= 1'b1;   // always ready to accept read data
    m_dbi_axil_awaddr  <= 'h0;
    m_dbi_axil_awvalid <= 'h0;
    m_dbi_axil_wdata   <= 'h0;
    m_dbi_axil_wvalid  <= 'h0;
    dbi_rd_data        <= 'h0;
    read_done          <= 1'b0;
    read_error         <= 1'b0;
    write_done         <= 'h0;
  end else begin
    case (sm_axilm)
      AXILM_IDLE : begin
        read_done  <= 1'b0;
        write_done <= 1'b0;
        if (st_dbi_rd) begin              // read request: issue AR
          sm_axilm           <= AXILM_R;
          m_dbi_axil_araddr  <= dbi_rd_addr;
          m_dbi_axil_arvalid <= 1'b1;
        end else if (st_dbi_wr) begin
          sm_axilm           <= AXILM_W;
          m_dbi_axil_awaddr  <= dbi_wr_addr;
          m_dbi_axil_awvalid <= 1'b1;
          m_dbi_axil_wvalid  <= 1'b1;
          m_dbi_axil_wdata   <= dbi_wr_data;
        end
      end

      AXILM_R : begin                     // wait for AR handshake
        if (m_dbi_axil_arready) begin
          sm_axilm           <= AXILM_R_RS;
          m_dbi_axil_arvalid <= 1'b0;
        end
      end

      AXILM_R_RS : begin                  // wait for R data
        if (m_dbi_axil_rvalid) begin
          sm_axilm   <= AXILM_IDLE;
          read_done  <= 1'b1;
          if (m_dbi_axil_rresp == 2'b00)
            dbi_rd_data <= m_dbi_axil_rdata;
          else
            read_error  <= 1'b1;
        end
      end

      AXILM_W : begin
        // Deassert each valid independently as its ready fires (AXI-Lite allows
        // AW and W to be accepted in any order or simultaneously).
        if (m_dbi_axil_awvalid && m_dbi_axil_awready)
          m_dbi_axil_awvalid <= 1'b0;
        if (m_dbi_axil_wvalid && m_dbi_axil_wready)
          m_dbi_axil_wvalid  <= 1'b0;
        // Advance to B-response wait only when both channels are done
        if ((!m_dbi_axil_awvalid || m_dbi_axil_awready) &&
            (!m_dbi_axil_wvalid  || m_dbi_axil_wready))
          sm_axilm <= AXILM_W_B;
      end

      AXILM_W_B : begin
        if (m_dbi_axil_bvalid) begin
          sm_axilm   <= AXILM_IDLE;
          write_done <= 1'b1;
        end
      end

      default : sm_axilm <= AXILM_IDLE;
    endcase
  end
end


// AXI-Lite slave: receives context writes from PL master.
// Writing reg5 (offset 0x14) triggers a DMA context write sequence via DBI.
// trigger_pending is cleared per-channel by pl_example's trigger_clear_vld
// pulse once that channel's 6-entry context write completes.
axil_slave #(
    .NUM_PFS        (NUM_PFS),
    .NUM_VFS_PER_PF (NUM_VFS_PER_PF),
    .VERSION_VALUE  (DESIGN_VERSION),
    .FUNC_TO_CHN_MAP(FUNC_TO_CHN_MAP),
    .NUM_CHN        (NUM_CHN)
) u_axil_slave (
    .clk              (clk),
    .reset_n          (reset_n),
    // Write address channel
    .s_axil_awaddr    (m_pl_axil_awaddr),
    .s_axil_awprot    (m_pl_axil_awprot),
    .s_axil_awvalid   (m_pl_axil_awvalid),
    .s_axil_awready   (m_pl_axil_awready),
    // Write data channel
    .s_axil_wdata     (m_pl_axil_wdata),
    .s_axil_wstrb     (m_pl_axil_wstrb),
    .s_axil_wvalid    (m_pl_axil_wvalid),
    .s_axil_wready    (m_pl_axil_wready),
    // Write response channel
    .s_axil_bresp     (m_pl_axil_bresp),
    .s_axil_bvalid    (m_pl_axil_bvalid),
    .s_axil_bready    (m_pl_axil_bready),
    // Read address channel
    .s_axil_araddr    (m_pl_axil_araddr),
    .s_axil_arprot    (m_pl_axil_arprot),
    .s_axil_arvalid   (m_pl_axil_arvalid),
    .s_axil_arready   (m_pl_axil_arready),
    // Read data channel
    .s_axil_rdata     (m_pl_axil_rdata),
    .s_axil_rresp     (m_pl_axil_rresp),
    .s_axil_rvalid    (m_pl_axil_rvalid),
    .s_axil_rready    (m_pl_axil_rready),
    // Context trigger / arbitration interface
    .trigger_pending    (trigger_pending),
    .trigger_clear_vld  (trigger_clear_vld),
    .trigger_clear_chn  (trigger_clear_chn),
    .ctxt_rd_chn        (ctxt_rd_chn),
    .ctxt_rd_regs       (ctxt_rd_regs),
    .ctxt_rd_dma_mode   (ctxt_rd_dma_mode),
    // AW user bits sideband
    .s_axil_awuser    (m_pl_axil_awuser),
    // AR user bits sideband
    .s_axil_aruser    (m_pl_axil_aruser),
    .irq_status_wr    (irq_status_wr),
    .irq_status_is_c2h(irq_status_is_c2h),
    .irq_status_chn   (irq_status_chn),
    .irq_status_data  (irq_status_data),
    .irq_clr_req_c2h      (irq_clr_req_c2h),
    .irq_clr_req_h2c      (irq_clr_req_h2c),
    .irq_clr_done         (irq_clr_done),
    .irq_clr_done_is_c2h  (irq_clr_done_is_c2h),
    .irq_clr_done_chn     (irq_clr_done_chn),
    .irq_clr_rd_chn       (clr_chn),
    .irq_clr_rd_c2h_status(irq_clr_rd_c2h_status),
    .irq_clr_rd_h2c_status(irq_clr_rd_h2c_status),
    .vf_flr_done_req      (vf_flr_done_req),
    .flr_done_req_clr     (flr_done_req_clr),
    .flr_done_req_clr_chn (flr_done_req_clr_chn),
    // Debug status inputs
    .dma_irq          (dma_irq),
    .h2c_chn_num      (h2c_chn_num),
    .c2h_chn_num      (c2h_chn_num),
    .irq_status       (irq_status),
    .msix_dbg_snapshot(msix_dbg_snapshot),
    .msix_dbg_events  (msix_dbg_events),
    .dma_irq_eligible0(dma_irq_eligible[31:0]),
    .sm_dbi           (sm_dbi),
    .sm_axilm         (sm_axilm),
    .st_dbi_wr        (st_dbi_wr),
    .write_done       (write_done),
    .wr_count         ({1'b0, wr_count}),
    .irq_dma_mode_rd_chn(irq_local_chn),
    .irq_dma_mode_out   (irq_chn_dma_mode),
    // LL mode debug status inputs
    .ll_pending       (ll_pending_r),
    .ll_phase1_done   (ll_phase1_done_r),
    .ll_chn_lat       (ll_chn_lat),
    .ll_grant_chn     (ll_grant_chn),
    .ll_grant_vld     (ll_grant_vld),
    .ll_p1_arm        (ll_p1_arm),
    .phase1_clr_r     (phase1_clr_r),
    .ll_rr_advance    (ll_rr_advance),
    .ll_p1_deassert_seen(phase1_in_progress_r),
    .run_status       (run_status_reg),
    .run_status_clr   (run_status_clr),
    .dbg_last_int_read_data(dbg_last_int_read_data)
);

// FLR communication interface (PS LPD_AXI_PL -> smartconnect_1 -> M_LPD_AXI_0).
//
// flr_slave itself has no PF/VF awareness — it just exposes a start-event pulse and accepts
// done/error-writes from the controller below, which decodes the function-number field using the
// same channel encoding (channel = vf_slot*NUM_PFS + pf_num, vf_slot=0 => PF) as the rest of this
// module.
//
// Two cases:
//   - VF-originated FLR_START (flr_start_vf_slot != 0): a bare VF-level FLR request has nothing
//     further for PL to act on, so it's echoed straight back to FLR_DONE one cycle later.
//   - PF-originated FLR_START (flr_start_vf_slot == 0): fan out to that PF's own VFs —
//     1. Send an MSI-X vector-6 doorbell to each of the PF's NUM_VFS_PER_PF VFs, one at a time
//        (vector 7 is reserved for a separate/later stage-2 PLD-load feature, not used here).
//     2. Each VF does its own FLR handling and reports back over the PCIe-facing BAR path — any
//        write to axil_slave's 0x4C (flr_done_trig) sets that function's own vf_flr_done_req bit;
//        vf_flr_done_pulse below re-indexes just this PF's NUM_VFS_PER_PF bits out of the full
//        NUM_CHN-wide vector. axil_slave clears each bit once flr_done_req_clr/_chn (a free-
//        running scan below) confirms it's been consumed.
//     3. Once every VF's bit is seen, or a 10ms-since-broadcast-started timeout expires first
//        (some VF never responded — not bound to a guest, driver down, etc.), complete the
//        sequence: on a clean finish just write FLR_DONE; on timeout also write FLR_ERROR first
//        (bit[0]=1, bits[31:16]=PF function number, bits[15:1] = bitmap of which VF-relative
//        indices never responded) and still write FLR_DONE afterwards — the PS only ever
//        services one FLR at a time, so completing (rather than hanging) keeps that protocol
//        moving even when a VF is unresponsive.
logic        flr_start_pulse;
logic [15:0] flr_start_func_num;
wire [VF_SLOT_W-1:0] flr_start_vf_slot = flr_start_func_num[CHN_W-1:PF_W];

logic        flr_done_wr_r;
logic [15:0] flr_done_func_num_r;
logic        flr_error_wr_r;
logic [31:0] flr_error_data_r;

// 10ms timeout budget for the whole VF-collection phase, in cycles of this module's clk
// (aclk/pl0_ref_clk, ~249.997 MHz per genBd.tcl's smartconnect/M_LPD_AXI_0 FREQ_HZ) —
// 0.010 * 249_997_498 ~= 2_500_000 cycles; 22 bits comfortably covers that (max ~4.19M).
localparam logic [21:0] FLR_TIMEOUT_CYCLES = 22'd2_500_000;
localparam logic [10:0] FLR_MSIX_VECTOR    = 11'd6;

// SR-IOV Extended Capability's NumVFs register offset within one PF's own config-space window --
// confirmed empirically (a live `lspci -vvv` dump of this exact CPM6 build showed "Capabilities:
// [228 v1] Single Root I/O Virtualization (SR-IOV)"), and NumVFs sits at capability-base+0x10 per
// the PCIe spec (bits[15:0] of that dword). This offset is fixed by CPM6's build-time extended-
// capability ordering, not something that varies at runtime -- if this design's CPM6_CONFIG ever
// changes capability ordering, re-confirm via a fresh lspci dump before trusting this constant.
localparam logic [31:0] FLR_SRIOV_NUMVFS_CAP_OFFSET = 32'h238;

localparam logic [2:0] FLR_IDLE         = 3'b000,
                        FLR_READ_NUMVFS = 3'b001, // reading this PF's current SR-IOV NumVFs via DBI
                        FLR_SEND_VF     = 3'b010, // flr_msix_req asserted for flr_vf_idx_r, waiting for grant
                        FLR_SEND_VF_GAP = 3'b011, // one-cycle gap after grant before the next VF's
                                                  // doorbell (mirrors sm_int's own assert/deassert-
                                                  // on-grant discrete-request style below)
                        FLR_WAIT_DONE   = 3'b100; // collecting vf_flr_done_pulse bits, 10ms timeout running

logic [2:0]                 flr_state_r;
logic [PF_W-1:0]            flr_pf_num_r;
logic [VF_SLOT_W-1:0]       flr_vf_idx_r;         // dual-use: VF being sent to (SEND_VF/_GAP), or
                                                   // free-running ack-clear scan index (WAIT_DONE)
logic [NUM_VFS_PER_PF-1:0]  flr_vf_done_bitmap_r;
logic [21:0]                flr_timeout_cnt_r;

// How many of this PF's VFs are *actually* enabled right now (SR-IOV NumVFs, read fresh at the
// start of every PF-level FLR) -- clamped to NUM_VFS_PER_PF defensively, in case of a
// misconfigured/larger-than-expected register value. flr_active_vf_mask_r is the corresponding
// bitmask (low flr_num_vfs_r bits set): both the fan-out loop bound and the all-acked/error-bitmap
// checks below are masked by it, so VF slots beyond what the driver actually enabled can never
// cause a false FLR timeout/error (see the "no VFs enabled" bug this was added to fix).
logic [VF_SLOT_W-1:0]       flr_num_vfs_r;
logic [NUM_VFS_PER_PF-1:0]  flr_active_vf_mask_r;

assign flr_numvfs_rd_addr = CFG_DBI_CFGSPACE_BASE
                                  + ({{(32-PF_W){1'b0}}, flr_pf_num_r} * CFG_DBI_PF_STRIDE)
                                  + FLR_SRIOV_NUMVFS_CAP_OFFSET;

// vf_flr_done_req comes from axil_slave (0x4C flr_done_trig), one bit per full NUM_CHN channel
// (channel = vf_slot*NUM_PFS + pf_num) -- declared earlier in this file (see note above, near
// irq_clr_req_c2h) since it's also used in axil_slave's instantiation. Extract just the bits
// belonging to the PF currently being serviced (flr_pf_num_r), re-indexed to PF-relative VF index
// 0..NUM_VFS_PER_PF-1.
logic [NUM_VFS_PER_PF-1:0]  vf_flr_done_pulse;
genvar gi;
generate
    for (gi = 0; gi < NUM_VFS_PER_PF; gi = gi + 1) begin : gen_vf_flr_done_pulse
        wire [6:0] flr_fi_g = 7'((gi+1)*NUM_PFS) + 7'(flr_pf_num_r);
        wire [6:0] flr_chn_g = F2C_IS_IDENTITY ? flr_fi_g : func_to_chn(flr_fi_g, FUNC_TO_CHN_MAP);
        assign vf_flr_done_pulse[gi] = vf_flr_done_req[flr_chn_g];
    end
endgenerate
wire  [NUM_VFS_PER_PF-1:0]  flr_vf_done_now = flr_vf_done_bitmap_r | vf_flr_done_pulse;

// Continuously (while collecting acks) pulse axil_slave to clear whichever VF-relative channel
// flr_vf_idx_r currently points at — a free-running scan across all NUM_VFS_PER_PF slots for this
// PF, so every VF's flr_done_trig bit gets acked/cleared at least once well within the up-to-10ms
// collection window, regardless of exactly when each VF wrote it. Clearing an already-0 bit is a
// harmless no-op, so there's no need to track which ones still need it.
// (flr_done_req_clr/_chn declared earlier in this file, alongside vf_flr_done_req.)
assign flr_done_req_clr     = (flr_state_r == FLR_WAIT_DONE);
wire [6:0] flr_clr_fi = 7'((flr_vf_idx_r + 1) * NUM_PFS + flr_pf_num_r);
assign flr_done_req_clr_chn = F2C_IS_IDENTITY ? flr_clr_fi : func_to_chn(flr_clr_fi, FUNC_TO_CHN_MAP);

assign flr_msix_vector_num   = FLR_MSIX_VECTOR;
assign flr_msix_operation    = 2'b00;
assign flr_msix_func_num     = flr_pf_num_r; // pcie_msix_func_num is [2:0], exactly PF_W bits wide
assign flr_msix_vfunc_active = 1'b1; // this sequence only ever targets VFs, never the PF itself
assign flr_msix_vfunc_num    = {{(8-VF_SLOT_W){1'b0}}, flr_vf_idx_r};

always_ff @(posedge clk) begin
    if (!reset_n) begin
        flr_state_r           <= FLR_IDLE;
        flr_pf_num_r          <= '0;
        flr_vf_idx_r          <= '0;
        flr_vf_done_bitmap_r  <= '0;
        flr_timeout_cnt_r     <= '0;
        flr_num_vfs_r         <= '0;
        flr_active_vf_mask_r  <= '0;
        flr_numvfs_rd_req     <= 1'b0;
        flr_msix_req          <= 1'b0;
        flr_done_wr_r         <= 1'b0;
        flr_done_func_num_r   <= '0;
        flr_error_wr_r        <= 1'b0;
        flr_error_data_r      <= '0;
    end else begin
        flr_done_wr_r  <= 1'b0; // 1-cycle pulses into flr_slave
        flr_error_wr_r <= 1'b0;

        case (flr_state_r)
            FLR_IDLE: begin
                if (flr_start_pulse) begin
                    if (flr_start_vf_slot != '0) begin
                        // VF-originated: nothing for PL to do, echo done back immediately.
                        flr_done_wr_r       <= 1'b1;
                        flr_done_func_num_r <= flr_start_func_num;
                    end else begin
                        // PF-originated: first find out how many of this PF's VFs are actually
                        // enabled (SR-IOV NumVFs) before fanning out any doorbells.
                        flr_pf_num_r      <= flr_start_func_num[PF_W-1:0];
                        flr_timeout_cnt_r <= '0;
                        flr_numvfs_rd_req <= 1'b1;
                        flr_state_r       <= FLR_READ_NUMVFS;
                    end
                end
            end

            FLR_READ_NUMVFS: begin
                if (flr_numvfs_rd_ack) begin
                    automatic logic [VF_SLOT_W-1:0] clamped_num_vfs;
                    clamped_num_vfs = (dbi_rd_data[15:0] > 16'(NUM_VFS_PER_PF))
                                      ? VF_SLOT_W'(NUM_VFS_PER_PF)
                                      : VF_SLOT_W'(dbi_rd_data[15:0]);
                    flr_numvfs_rd_req    <= 1'b0;
                    // Clamp to NUM_VFS_PER_PF (this PL hardware's max statically-sized slot count)
                    // in case the register ever reads back something larger than expected.
                    flr_num_vfs_r        <= clamped_num_vfs;
                    flr_active_vf_mask_r <= {NUM_VFS_PER_PF{1'b1}} >> (NUM_VFS_PER_PF - clamped_num_vfs);
                    if (dbi_rd_data[15:0] == 16'd0) begin
                        // No VFs enabled by the driver -- nothing to notify, complete immediately,
                        // no error. (This is the case that used to time out and report 0x1F.)
                        flr_done_wr_r       <= 1'b1;
                        flr_done_func_num_r <= {{(16-PF_W){1'b0}}, flr_pf_num_r};
                        flr_state_r         <= FLR_IDLE;
                    end else begin
                        flr_vf_idx_r         <= '0;
                        flr_vf_done_bitmap_r <= '0;
                        flr_timeout_cnt_r    <= '0;
                        flr_msix_req         <= 1'b1;
                        flr_state_r          <= FLR_SEND_VF;
                    end
                end
            end

            FLR_SEND_VF: begin
                // Treat error the same as grant (matches sm_int's dma_msix_grant||dma_msix_error
                // pattern) -- a disabled/nonexistent VF shouldn't be able to hang this loop
                // forever waiting for a grant that will never come; just move on to the next VF.
                if (flr_msix_grant || flr_msix_error) begin
                    flr_msix_req <= 1'b0;
                    flr_state_r  <= FLR_SEND_VF_GAP;
                end
            end

            FLR_SEND_VF_GAP: begin
                if (flr_vf_idx_r == flr_num_vfs_r - 1'b1) begin
                    // Last *enabled* VF's doorbell just completed -- move on to collecting acks.
                    flr_vf_idx_r      <= '0;
                    flr_timeout_cnt_r <= '0;
                    flr_state_r       <= FLR_WAIT_DONE;
                end else begin
                    flr_vf_idx_r <= flr_vf_idx_r + 1'b1;
                    flr_msix_req <= 1'b1;
                    flr_state_r  <= FLR_SEND_VF;
                end
            end

            FLR_WAIT_DONE: begin
                flr_vf_done_bitmap_r <= flr_vf_done_now;
                // Free-running ack-clear scan (see flr_done_req_clr/_chn above) -- keep walking
                // every cycle regardless of completion/timeout below, so any VF that acks right at
                // the boundary still gets its axil_slave bit cleared before FLR_IDLE is re-entered.
                flr_vf_idx_r <= (flr_vf_idx_r == NUM_VFS_PER_PF-1) ? '0 : flr_vf_idx_r + 1'b1;

                // Masked by flr_active_vf_mask_r so VF slots the driver never enabled (bits above
                // flr_num_vfs_r) are simply ignored -- they can't block completion and can't show
                // up in the error bitmap below, regardless of their (meaningless) done/ack state.
                if ((flr_vf_done_now & flr_active_vf_mask_r) == flr_active_vf_mask_r) begin
                    // All of this PF's *enabled* VFs acked -- normal completion.
                    flr_done_wr_r       <= 1'b1;
                    flr_done_func_num_r <= {{(16-PF_W){1'b0}}, flr_pf_num_r};
                    flr_state_r         <= FLR_IDLE;
                end else if (flr_timeout_cnt_r == FLR_TIMEOUT_CYCLES) begin
                    // 10ms elapsed without every enabled VF responding -- report which ones,
                    // complete anyway (the PS only services one FLR at a time; don't leave it
                    // hanging).
                    flr_error_wr_r   <= 1'b1;
                    flr_error_data_r <= {{(16-PF_W){1'b0}}, flr_pf_num_r,
                                         {(15-NUM_VFS_PER_PF){1'b0}},
                                         (~flr_vf_done_now) & flr_active_vf_mask_r,
                                         1'b1};
                    flr_done_wr_r       <= 1'b1;
                    flr_done_func_num_r <= {{(16-PF_W){1'b0}}, flr_pf_num_r};
                    flr_state_r         <= FLR_IDLE;
                end else begin
                    flr_timeout_cnt_r <= flr_timeout_cnt_r + 1'b1;
                end
            end

            default: flr_state_r <= FLR_IDLE;
        endcase
    end
end

flr_slave #(
    .VERSION_VALUE (DESIGN_VERSION)
) u_flr_slave (
    .clk            (clk),
    .reset_n        (reset_n),
    .flr_start_pulse    (flr_start_pulse),
    .flr_start_func_num (flr_start_func_num),
    .flr_done_wr        (flr_done_wr_r),
    .flr_done_func_num  (flr_done_func_num_r),
    .flr_error_wr       (flr_error_wr_r),
    .flr_error_data     (flr_error_data_r),
    .s_axi_awaddr   (s_flr_axi_awaddr),
    .s_axi_awid     (s_flr_axi_awid),
    .s_axi_awprot   (s_flr_axi_awprot),
    .s_axi_awlen    (s_flr_axi_awlen),
    .s_axi_awsize   (s_flr_axi_awsize),
    .s_axi_awburst  (s_flr_axi_awburst),
    .s_axi_awlock   (s_flr_axi_awlock),
    .s_axi_awcache  (s_flr_axi_awcache),
    .s_axi_awqos    (s_flr_axi_awqos),
    .s_axi_awvalid  (s_flr_axi_awvalid),
    .s_axi_awready  (s_flr_axi_awready),
    .s_axi_wdata    (s_flr_axi_wdata),
    .s_axi_wstrb    (s_flr_axi_wstrb),
    .s_axi_wlast    (s_flr_axi_wlast),
    .s_axi_wvalid   (s_flr_axi_wvalid),
    .s_axi_wready   (s_flr_axi_wready),
    .s_axi_bid      (s_flr_axi_bid),
    .s_axi_bresp    (s_flr_axi_bresp),
    .s_axi_bvalid   (s_flr_axi_bvalid),
    .s_axi_bready   (s_flr_axi_bready),
    .s_axi_araddr   (s_flr_axi_araddr),
    .s_axi_arid     (s_flr_axi_arid),
    .s_axi_arprot   (s_flr_axi_arprot),
    .s_axi_arlen    (s_flr_axi_arlen),
    .s_axi_arsize   (s_flr_axi_arsize),
    .s_axi_arburst  (s_flr_axi_arburst),
    .s_axi_arlock   (s_flr_axi_arlock),
    .s_axi_arcache  (s_flr_axi_arcache),
    .s_axi_arqos    (s_flr_axi_arqos),
    .s_axi_arvalid  (s_flr_axi_arvalid),
    .s_axi_arready  (s_flr_axi_arready),
    .s_axi_rdata    (s_flr_axi_rdata),
    .s_axi_rid      (s_flr_axi_rid),
    .s_axi_rresp    (s_flr_axi_rresp),
    .s_axi_rlast    (s_flr_axi_rlast),
    .s_axi_rvalid   (s_flr_axi_rvalid),
    .s_axi_rready   (s_flr_axi_rready)
);

// Advance the round-robin pointer when MSI-X grant is received.
assign rr_advance = (sm_int == SM_INT_GNT) && dma_msix_grant;

// Round-robin arbiter: selects the next pending channel after last_served.
rr_arbiter_128 u_rr_arbiter (
    .clk        (clk),
    .reset_n    (reset_n),
  .req        (dma_irq_eligible),
    .advance    (rr_advance),
    .served_chn (chn_num),    // registered channel being processed, not combinatorial grant_chn
    .grant_chn  (grant_chn),
    .grant_vld  (grant_vld)
);

// Register arbiter grant outputs to break the long combinatorial path:
//   last_served → mask generation → 128-bit two's-complement select → grant_chn
//   → dma_irq_eligible[grant_chn] (128-bit mux) → SM register enable.
// grant_vld_r replaces the redundant dma_irq_eligible[grant_chn] check:  since
//   grant_vld = |dma_irq_eligible and grant_chn is always selected from a set bit
//   in dma_irq_eligible, dma_irq_eligible[grant_chn] is always 1 when grant_vld=1.
// Adds 1-cycle interrupt pickup latency — functionally harmless.
// Same treatment applied to ctxt/ll arbiters below: their grant_chn feeds directly
// into ctxt_chn_lat/ll_chn_lat, which for ll_chn_lat also forms the Phase 2 DBI
// write address (ll_context_write) — an unregistered glitch there would send a
// garbage address into CPM6's internal register space.
always_ff @(posedge clk) begin
    if (!reset_n) begin
        grant_chn_r      <= 7'd0;
        grant_vld_r      <= 1'b0;
        ctxt_grant_chn_r <= 7'd0;
        ctxt_grant_vld_r <= 1'b0;
        ll_grant_chn_r   <= 7'd0;
        ll_grant_vld_r   <= 1'b0;
    end else begin
        grant_chn_r      <= grant_chn;
        grant_vld_r      <= grant_vld;
        ctxt_grant_chn_r <= ctxt_grant_chn;
        ctxt_grant_vld_r <= ctxt_grant_vld;
        ll_grant_chn_r   <= ll_grant_chn;
        ll_grant_vld_r   <= ll_grant_vld;
    end
end

// ctxt_rr_advance_r / ll_rr_advance_r: 1-cycle-delayed copies of the advance
// pulses, needed because ctxt_grant_vld_r/ll_grant_vld_r are themselves
// delayed by the registration above. Without this, DBI_IDLE's stale-grant
// guard (below) only covers the cycle the raw advance pulse fires, one
// cycle too early relative to when the *registered* grant_vld_r actually
// catches up to the post-clear/post-advance state — leaving one cycle where
// DBI_IDLE would spuriously re-enter DBI_CTXT_WR/DBI_LL_WR for a channel
// that was just finished (re-issuing its doorbell a second time).
// (ctxt_rr_advance_r/ll_rr_advance_r declared earlier in this file, near ctxt_rr_advance.)
always_ff @(posedge clk) begin
    if (!reset_n) begin
        ctxt_rr_advance_r <= 1'b0;
        ll_rr_advance_r   <= 1'b0;
    end else begin
        ctxt_rr_advance_r <= ctxt_rr_advance;
        ll_rr_advance_r   <= ll_rr_advance;
    end
end

// Round-robin arbiter over channels with a completed, unflushed context
// trigger. Reused unmodified (same module as the interrupt arbiter above).
rr_arbiter_128 u_rr_arbiter_ctxt (
    .clk        (clk),
    .reset_n    (reset_n),
    .req        (trigger_pending),
    .advance    (ctxt_rr_advance),
    .served_chn (ctxt_served_chn),
    .grant_chn  (ctxt_grant_chn),
    .grant_vld  (ctxt_grant_vld)
);

// Round-robin arbiter over channels awaiting Phase 2 LL DMA programming.
rr_arbiter_128 u_rr_arbiter_ll (
    .clk        (clk),
    .reset_n    (reset_n),
    .req        (ll_pending_r),
    .advance    (ll_rr_advance),
    .served_chn (ll_served_chn),
    .grant_chn  (ll_grant_chn),
    .grant_vld  (ll_grant_vld)
);

endmodule


