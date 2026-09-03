// MODULE : custom_axi_tg
//
// DESCRIPTION:
// AXI4 traffic generator purpose-built to drive the slave port of
// pl_axi_cpi_bridge.  A program of up to MAX_COMMANDS instructions is written
// over an AXI4-Lite programming port into a BRAM instruction RAM; a start pulse
// (external pin or CSR) then runs the program from entry 0 to TG_DONE_PTR-1,
// dispatching WRITE commands to a write dispatcher and READ commands to a read
// dispatcher.  Per-command status - fully_requested, fully_responded and the
// first non-OKAY response with its AXI ID and per-ID ordinal - is read back over
// the same AXI-Lite port.
//
// DETAILS:
//  - Opcodes: WRITE, READ and WAIT (drain both dispatchers and both rings).
//    2'b11 is RESERVED; committing it returns SLVERR.  There is no loop
//    construct, so a program is STRICTLY LINEAR and executes EXACTLY ONCE per
//    accepted start.
//  - ZERO BUBBLE.  There is no per-command setup state: each dispatcher owns a
//    2-deep command prefetch queue whose head word is sliced with zero LUT
//    delay, and the sequencer fetches one iRAM address per cycle.  With the
//    slave always ready and the ring not full, the TG issues exactly one
//    transaction per cycle continuously, INCLUDING ACROSS SAME-TYPE COMMAND
//    BOUNDARIES, for any program whose commands all have repeat_count >= 1 -
//    64 B/cycle = 21.3 GB/s at 333 MHz.
//  - A returning BID/RID names only an AXI ID, not a command, so each
//    dispatcher owns an 8-deep outstanding-command ring of per-ID counters that
//    attributes each response to the oldest resident command with a nonzero
//    count for that ID.  The ring materialises that attribution as a
//    REGISTERED per-ID owner one-hot, which is what closes 333 MHz at every
//    AXI_ID_WIDTH; see the header of custom_axi_tg_ring.sv.
//  - DRAIN ON STOP.  Writing TG_CTRL.START = 0 moves the state to STOPPING, not
//    IDLE: no further command is loaded, but the transaction currently being
//    offered is ridden out and every outstanding response is still counted and
//    attributed.  Nothing is ever flushed while transactions are in flight, so
//    TG_ORPHAN_RSP is a pure bug detector and must always read 0.
//  - Every register, the whole iRAM, the status array and every FSM live in the
//    m_axi_aclk domain.  custom_axi_tg_reg_space is the ONLY clock-domain
//    crossing: a single-outstanding req/ack shuttle in which just four
//    single-bit toggles and three quasi-static buses cross clocks.  Set
//    AXI_AXIL_SYNC=1 to remove the synchronisers when the two clocks are the
//    same net; both clock pins exist in every configuration so that the BD
//    symbol is stable.
//
// RESTRICTIONS:
//  - AXI data bus is always 512 bits; narrow and unaligned transfers are not
//    generated (AxSIZE is always 3'b110 and every address is 64 B aligned)
//  - AXI max beats per burst is 1 (AxLEN = 0), burst type FIXED, which is
//    identical to INCR for a single beat
//  - AXI_ADDRESS_WIDTH <= 48; AXI_ID_WIDTH <= 4 (0 means the AXI ID is
//    hardcoded to 0 on a 1-bit tied-off port)
//  - MAX_COMMANDS <= 512 (the depth of a Versal 36Kb BRAM in its 512x72 shape)
//  - The external start pin i_start must be held high for at least two
//    m_axi_aclk periods so the 2FF synchroniser can sample it
//  - A start pulse is only accepted when the state is IDLE or ALL_RESPONDED.
//    From AXI-Lite a start while busy returns SLVERR + ERR_START_BUSY; from the
//    pin it sets the sticky W1C bit TG_STATUS.START_BUSY_ERR.
//
// ACRONYMS:
//  - TG    = traffic generator
//  - iRAM  = instruction RAM
//  - CPQ   = command prefetch queue
//  - CSR   = control / status register
//  - freq  = fully_requested
//  - fresp = fully_responded

module custom_axi_tg
  import custom_axi_tg_pkg::*;
#(
  //--- AXI master geometry -------------------------------------------------
  parameter int  AXI_ADDRESS_WIDTH = 48,        // max 48
  parameter int  AXI_ID_WIDTH      = 1,         // 0..4;  0 => AXI ID hardcoded
                                                //        to 0 on a 1-bit
                                                //        tied-off port
  //--- Clocking ------------------------------------------------------------
  parameter bit  AXI_AXIL_SYNC     = 1'b0,      // 0 = async, generate
                                                //     synchronizers
                                                // 1 = s_axil_aclk == m_axi_aclk,
                                                //     bypass them.  Both clock
                                                //     pins exist either way
  //--- LFSR implementation selection --------------------------------------
  parameter bit  LFSR64_GALOIS     = 1'b1,      // 1 = Galois, 0 = Fibonacci
  parameter bit  LFSR27_GALOIS     = 1'b1,      // address LFSR
  parameter bit  LFSR8_GALOIS      = 1'b1,      // AXI ID LFSR
  //--- LFSR seeds ----------------------------------------------------------
  //  MUST be non-zero AND high-entropy across the FULL width.  A seed whose
  //  upper bits are near zero biases the write byte-enable probability for
  //  tens of thousands of advances, because that logic samples taps spread
  //  across the whole 64-bit state.  The defaults below are the 64-bit
  //  golden-ratio constant and slices of it and of a SHA-256 round constant,
  //  deliberately decorrelated between the read and write paths so the two
  //  address and ID streams do not walk in lockstep.
  parameter logic [63:0] LFSR64_SEED    = 64'h9E37_79B9_7F4A_7C15,
  parameter logic [26:0] LFSR27_WR_SEED = 27'h63779B9,
  parameter logic [26:0] LFSR27_RD_SEED = 27'h367AE85,
  parameter logic [ 7:0] LFSR8_WR_SEED  = 8'hB5,
  parameter logic [ 7:0] LFSR8_RD_SEED  = 8'h6D,
  //--- CAN'T TOUCH ---------------------------------------------------------
  localparam int AXI_DATA_WIDTH = 512,          // fixed by pl_axi_cpi_bridge
  localparam int AXI_STRB_WIDTH = AXI_DATA_WIDTH/8,
  localparam int WUSER_WIDTH    = 33,           // bridge WUSER_MAX_WIDTH  = 1+32
  localparam int BUSER_WIDTH    =  2,           // bridge BUSER_MAX_WIDTH  = 2
  localparam int ARUSER_WIDTH   = 35,           // bridge ARUSER_MAX_WIDTH = 2+1+32
  localparam int RUSER_WIDTH    = 34,           // bridge RUSER_MAX_WIDTH  = 2+32
  localparam int ID_PORT_W      = (AXI_ID_WIDTH==0) ? 1 : AXI_ID_WIDTH,
  localparam int NUM_IDS        = (AXI_ID_WIDTH==0) ? 1 : (1<<AXI_ID_WIDTH),
  // MAX_COMMANDS is the number of iRAM entries the TG will execute.  The
  // absolute maximum is 512 because that is the depth of a Versal 36Kb BRAM
  // configured 512x72, which is the shape this iRAM uses.  It is set to 32 for
  // now to keep the status flop array and the per-command AXI-Lite status
  // window small.  Raising it to 512 requires no other change.
  localparam int MAX_COMMANDS   = 32,           // absolute maximum 512
  localparam int TG_IRAM_WIDTH  = IRAM_WIDTH,   // 192 - 6 x 32b AXI-Lite slices
  localparam int TG_IRAM_DEPTH  = IRAM_DEPTH,   // 512
  localparam int RING_DEPTH     = 8,            // see custom_axi_tg_ring.sv
  localparam int CPQ_DEPTH      = 2,            // command prefetch depth
  localparam int TXN_CNT_W      = 13,           // 0..4096 transactions
  // fetch_ptr settles AT done_ptr once a program finishes fetching, and
  // done_ptr can legally equal MAX_COMMANDS (one past the last valid index),
  // so this needs one bit more than $clog2(MAX_COMMANDS) or that terminal
  // value aliases to 0 - indistinguishable from "currently on command 0".
  localparam int CMD_PTR_W      = $clog2(MAX_COMMANDS) + 1
)(
  /*** Clocks and resets - both clock pins always present ***/
  input                                m_axi_aclk,
  input                                m_axi_aresetn,   // active-low SYNC
  input                                s_axil_aclk,
  input                                s_axil_aresetn,  // active-low SYNC

  /*** External start pin (async, edge detected, 2FF sync) ***/
  input                                i_start,

  /*** Status outputs (m_axi_aclk domain) - pins AND AXI-L readable ***/
  output logic [                  2:0] o_state,         // 3 bits:
                                                        //  0 IDLE
                                                        //  1 IN_PROG
                                                        //  2 ALL_REQUESTED
                                                        //  3 ALL_RESPONDED
                                                        //  4 STOPPING
  output logic [       CMD_PTR_W-1:0] o_cur_cmd_ptr,   // fetch pointer; leads
                                                        // the bus by <= 3 cmds
                                                        // range [0,MAX_COMMANDS]
  output logic                         o_running,       // o_state != IDLE

  /*** AMBA AXI4 Master Port - drives pl_axi_cpi_bridge's slave port ***/
  //-- Write Address Channel
  output logic [AXI_ADDRESS_WIDTH-1:0] m_axi_awaddr,
  output logic [        ID_PORT_W-1:0] m_axi_awid,      // tied 0 if AXI_ID_WIDTH==0
  output logic [                  2:0] m_axi_awprot,    // 3'h0
  output logic [                  1:0] m_axi_awburst,   // 2'b00 FIXED
  output logic [                  2:0] m_axi_awsize,    // 3'b110 = 64 B
  output logic [                  3:0] m_axi_awcache,   // 4'h0
  output logic [                  7:0] m_axi_awlen,     // 8'h00 = 1 beat
  output logic                         m_axi_awlock,    // 1'b0
  output logic                         m_axi_awvalid,
  input                                m_axi_awready,
  //-- Write Data Channel
  output logic [      WUSER_WIDTH-1:0] m_axi_wuser,     // {32'h0, poison}
  output logic [   AXI_DATA_WIDTH-1:0] m_axi_wdata,
  output logic [   AXI_STRB_WIDTH-1:0] m_axi_wstrb,
  output logic                         m_axi_wlast,     // 1'b1
  output logic                         m_axi_wvalid,
  input                                m_axi_wready,
  //-- Write Response Channel
  input        [      BUSER_WIDTH-1:0] m_axi_buser,     // devload; unused
  input                                m_axi_bvalid,
  output logic                         m_axi_bready,    // 1'b1
  input        [        ID_PORT_W-1:0] m_axi_bid,
  input        [                  1:0] m_axi_bresp,
  //-- Read Address Channel
  output logic [     ARUSER_WIDTH-1:0] m_axi_aruser,    // {33'h0, aruser_cmd}
  output logic [AXI_ADDRESS_WIDTH-1:0] m_axi_araddr,
  output logic [        ID_PORT_W-1:0] m_axi_arid,      // tied 0 if AXI_ID_WIDTH==0
  output logic [                  2:0] m_axi_arprot,    // 3'h0
  output logic [                  1:0] m_axi_arburst,   // 2'b00 FIXED
  output logic [                  2:0] m_axi_arsize,    // 3'b110 = 64 B
  output logic [                  3:0] m_axi_arcache,   // 4'h0
  output logic [                  7:0] m_axi_arlen,     // 8'h00 = 1 beat
  output logic                         m_axi_arlock,    // 1'b0
  output logic                         m_axi_arvalid,
  input                                m_axi_arready,
  //-- Read Data Channel
  input        [      RUSER_WIDTH-1:0] m_axi_ruser,     // unused
  input        [        ID_PORT_W-1:0] m_axi_rid,
  input        [   AXI_DATA_WIDTH-1:0] m_axi_rdata,     // discarded
  input        [                  1:0] m_axi_rresp,
  input                                m_axi_rvalid,
  input                                m_axi_rlast,     // unused (always 1)
  output logic                         m_axi_rready,    // 1'b1

  /*** AXI4-Lite Slave Port - programming interface (16b address) ***/
  //  . AW
  input                                s_axil_awvalid,
  output logic                         s_axil_awready,
  input        [                 15:0] s_axil_awaddr,
  input        [                  2:0] s_axil_awprot,
  //  .  W
  input                                s_axil_wvalid,
  output logic                         s_axil_wready,
  input        [                 31:0] s_axil_wdata,
  input        [                  3:0] s_axil_wstrb,
  //  .  B
  output logic                         s_axil_bvalid,
  input                                s_axil_bready,
  output logic [                  1:0] s_axil_bresp,
  //  . AR
  input                                s_axil_arvalid,
  output logic                         s_axil_arready,
  input        [                 15:0] s_axil_araddr,
  input        [                  2:0] s_axil_arprot,
  //  .  R
  output logic                         s_axil_rvalid,
  input                                s_axil_rready,
  output logic [                  1:0] s_axil_rresp,
  output logic [                 31:0] s_axil_rdata
);

  //--------------------------------------------------------------------------
  // Fixed AXI master sideband.  FIXED and INCR are identical at AxLEN=0, so the
  // "only INCR" note in pl_axi_cpi_bridge.sv is stale for a single beat.
  //--------------------------------------------------------------------------
  assign m_axi_awprot  = 3'h0;                  // NU on the bridge
  assign m_axi_awburst = 2'b00;                 // FIXED
  assign m_axi_awsize  = 3'b110;                // 64 B, no narrow transfers
  assign m_axi_awcache = 4'h0;                  // NU on the bridge
  assign m_axi_awlen   = 8'h00;                 // single beat only
  assign m_axi_awlock  = 1'b0;                  // NU on the bridge
  assign m_axi_wlast   = 1'b1;                  // always the last beat
  assign m_axi_arprot  = 3'h0;
  assign m_axi_arburst = 2'b00;
  assign m_axi_arsize  = 3'b110;
  assign m_axi_arcache = 4'h0;
  assign m_axi_arlen   = 8'h00;
  assign m_axi_arlock  = 1'b0;

  //--------------------------------------------------------------------------
  // External start pin: asynchronous, edge detected, 2FF metastability sync.
  // The user must hold it high long enough to be sampled (at least two
  // m_axi_aclk periods).  A rising edge while the TG is busy is dropped and
  // records itself in the sticky TG_STATUS.START_BUSY_ERR bit owned by the
  // sequencer - the pin has no response channel to report on.
  //--------------------------------------------------------------------------
  (* ASYNC_REG = "TRUE" *) logic start_ext_sync_0, start_ext_sync_1;
  logic start_ext_q;
  logic start_pulse_ext;
  logic start_pulse_int;

  always_ff @(posedge m_axi_aclk) begin
    if (!m_axi_aresetn) begin
      start_ext_sync_0 <= 1'b0;
      start_ext_sync_1 <= 1'b0;
      start_ext_q      <= 1'b0;
    end
    else begin
      start_ext_sync_0 <= i_start;
      start_ext_sync_1 <= start_ext_sync_0;
      start_ext_q      <= start_ext_sync_1;
    end
  end

  assign start_pulse_ext = start_ext_sync_1 & ~start_ext_q;   // rising edge

  //--------------------------------------------------------------------------
  // Internal wiring
  //--------------------------------------------------------------------------
  // regbus
  logic        regbus_req, regbus_we, regbus_done;
  logic [15:0] regbus_addr;
  logic [31:0] regbus_wdata, regbus_rdata;
  logic [3:0] regbus_wstrb;
  logic [1:0] regbus_resp;

  // iRAM
  logic                     iram_wen;
  logic [              8:0] iram_waddr;
  logic [TG_IRAM_WIDTH-1:0] iram_wdata;
  logic                     iram_csr_rd_req;
  logic [              8:0] iram_csr_raddr;
  logic                     iram_enb;
  logic [              8:0] iram_addrb;
  logic [TG_IRAM_WIDTH-1:0] iram_rdata;

  // control / status
  logic       stop_pulse;
  logic [9:0] done_ptr;
  logic       prog_valid_set;
  logic [8:0] prog_valid_idx;
  logic       prog_valid_clr_all;
  logic [2:0] run_state;
  logic [CMD_PTR_W-1:0] cur_cmd_ptr;
  logic        start_busy_err, start_busy_err_clr;
  logic [             8:0] stat_rd_idx;
  logic [            20:0] stat_rd_data;
  logic                    any_cmd_err;
  logic [MAX_COMMANDS-1:0] prog_valid_vec;

  // sequencer <-> dispatchers
  logic       seq_iram_ren;
  logic [8:0] seq_iram_raddr;
  logic                     wr_cpq_push, rd_cpq_push;
  logic [              8:0] cpq_push_idx;
  logic [TG_IRAM_WIDTH-1:0] cpq_push_word;
  logic [1:0]               wr_cpq_cnt, rd_cpq_cnt;
  logic                     wr_cpq_pop, rd_cpq_pop;
  logic                     stop_req, cpq_flush;
  logic                     wr_stop_done, rd_stop_done;

  // status array
  logic       clr_all;
  logic [8:0] q_idx;
  logic       q_programmed_valid;

  logic        wr_set_freq,  rd_set_freq;
  logic [8:0]  wr_freq_idx,  rd_freq_idx;
  logic        wr_set_fresp, rd_set_fresp;
  logic [8:0]  wr_fresp_idx, rd_fresp_idx;
  logic        wr_err_vld,   rd_err_vld;
  logic [8:0]  wr_err_idx,   rd_err_idx;
  logic        wr_err_slverr, rd_err_slverr;
  logic [11:0] wr_err_num,   rd_err_num;
  logic [3:0]  wr_err_axiid, rd_err_axiid;
  logic        wr_disp_busy, rd_disp_busy;
  logic [8:0]  wr_cur_cmd_idx, rd_cur_cmd_idx;
  logic        wr_cur_active, rd_cur_active;

  // rings
  logic                  wr_ring_alloc, rd_ring_alloc;
  logic [8:0]            wr_ring_alloc_idx, rd_ring_alloc_idx;
  logic                  wr_ring_inc, rd_ring_inc;
  logic [NUM_IDS-1:0]    wr_ring_inc_oh, rd_ring_inc_oh;
  logic                  wr_ring_dec, rd_ring_dec;
  logic [NUM_IDS-1:0]    wr_ring_dec_oh, rd_ring_dec_oh;
  logic                  wr_ring_full, rd_ring_full;
  logic                  wr_ring_empty, rd_ring_empty;
  logic                  wr_ring_dec_vld, rd_ring_dec_vld;
  logic                  wr_ring_dec_hit, rd_ring_dec_hit;
  logic [8:0]            wr_ring_dec_cmd_idx, rd_ring_dec_cmd_idx;
  logic [11:0]           wr_ring_dec_rsp_ord, rd_ring_dec_rsp_ord;
  logic [3:0]            wr_ring_dec_axiid, rd_ring_dec_axiid;
  logic [8:0]            wr_q_idx, rd_q_idx;
  logic                  wr_q_fully_requested, rd_q_fully_requested;
  logic                  wr_ring_retire, rd_ring_retire;
  logic [8:0]            wr_ring_retire_idx, rd_ring_retire_idx;
  logic [RING_DEPTH-1:0] wr_ring_vld_vec, rd_ring_vld_vec;
  logic [2:0]            wr_ring_head, wr_ring_tail;
  logic [2:0]            rd_ring_head, rd_ring_tail;
  logic [3:0]            wr_ring_count, rd_ring_count;
  logic                  wr_orphan_sticky, rd_orphan_sticky;
  logic [3:0]            wr_orphan_axiid, rd_orphan_axiid;
  logic                  wr_orphan_clr, rd_orphan_clr;

  //--------------------------------------------------------------------------
  // Status pins.
  //--------------------------------------------------------------------------
  assign o_state       = run_state;
  assign o_cur_cmd_ptr = cur_cmd_ptr;
  assign o_running     = (run_state != ST_IDLE);

  //--------------------------------------------------------------------------
  // iRAM read port arbitration.  The sequencer wins; the CSR block only ever
  // requests a read while run_state == IDLE, i.e. while the sequencer is not
  // fetching, so the two can never actually collide.  enb is free-running
  // while fetching (one address per cycle) - see custom_axi_tg_iram.sv.
  //--------------------------------------------------------------------------
  assign iram_enb   = seq_iram_ren | iram_csr_rd_req;
  assign iram_addrb = seq_iram_ren ? seq_iram_raddr : iram_csr_raddr;

  //--------------------------------------------------------------------------
  // AXI4-Lite front end + the only CDC in the IP
  //--------------------------------------------------------------------------
  custom_axi_tg_reg_space #(
    .AXI_AXIL_SYNC   (AXI_AXIL_SYNC)
  ) i_reg_space (
    .axil_clk        (s_axil_aclk),
    .axil_rstn       (s_axil_aresetn),
    .dest_clk        (m_axi_aclk),
    .dest_rstn       (m_axi_aresetn),
    .regbus_req      (regbus_req),
    .regbus_we       (regbus_we),
    .regbus_addr     (regbus_addr),
    .regbus_wdata    (regbus_wdata),
    .regbus_wstrb    (regbus_wstrb),
    .regbus_done     (regbus_done),
    .regbus_rdata    (regbus_rdata),
    .regbus_resp     (regbus_resp),
    .s_axil_awvalid  (s_axil_awvalid),
    .s_axil_awready  (s_axil_awready),
    .s_axil_awaddr   (s_axil_awaddr),
    .s_axil_awprot   (s_axil_awprot),
    .s_axil_wvalid   (s_axil_wvalid),
    .s_axil_wready   (s_axil_wready),
    .s_axil_wdata    (s_axil_wdata),
    .s_axil_wstrb    (s_axil_wstrb),
    .s_axil_bvalid   (s_axil_bvalid),
    .s_axil_bready   (s_axil_bready),
    .s_axil_bresp    (s_axil_bresp),
    .s_axil_arvalid  (s_axil_arvalid),
    .s_axil_arready  (s_axil_arready),
    .s_axil_araddr   (s_axil_araddr),
    .s_axil_arprot   (s_axil_arprot),
    .s_axil_rvalid   (s_axil_rvalid),
    .s_axil_rready   (s_axil_rready),
    .s_axil_rresp    (s_axil_rresp),
    .s_axil_rdata    (s_axil_rdata)
  );

  //--------------------------------------------------------------------------
  // Register decode, iRAM assembly / commit, CSRs
  //--------------------------------------------------------------------------
  custom_axi_tg_csr #(
    .AXI_ADDRESS_WIDTH  (AXI_ADDRESS_WIDTH),
    .AXI_ID_WIDTH       (AXI_ID_WIDTH),
    .AXI_AXIL_SYNC      (AXI_AXIL_SYNC),
    .MAX_COMMANDS       (MAX_COMMANDS),
    .IRAM_WIDTH         (TG_IRAM_WIDTH),
    .RING_DEPTH         (RING_DEPTH),
    .CPQ_DEPTH          (CPQ_DEPTH)
  ) i_csr (
    .clk                (m_axi_aclk),
    .rstn               (m_axi_aresetn),
    .regbus_req         (regbus_req),
    .regbus_we          (regbus_we),
    .regbus_addr        (regbus_addr),
    .regbus_wdata       (regbus_wdata),
    .regbus_wstrb       (regbus_wstrb),
    .regbus_done        (regbus_done),
    .regbus_rdata       (regbus_rdata),
    .regbus_resp        (regbus_resp),
    .iram_wen           (iram_wen),
    .iram_waddr         (iram_waddr),
    .iram_wdata         (iram_wdata),
    .iram_csr_rd_req    (iram_csr_rd_req),
    .iram_csr_raddr     (iram_csr_raddr),
    .iram_rdata         (iram_rdata),
    .start_pulse_int    (start_pulse_int),
    .stop_pulse         (stop_pulse),
    .done_ptr           (done_ptr),
    .prog_valid_set     (prog_valid_set),
    .prog_valid_idx     (prog_valid_idx),
    .prog_valid_clr_all (prog_valid_clr_all),
    .start_busy_err_clr (start_busy_err_clr),
    .run_state          (run_state),
    .cur_cmd_ptr        (cur_cmd_ptr),
    .wr_disp_busy       (wr_disp_busy),
    .rd_disp_busy       (rd_disp_busy),
    .wr_ring_empty      (wr_ring_empty),
    .rd_ring_empty      (rd_ring_empty),
    .wr_ring_full       (wr_ring_full),
    .rd_ring_full       (rd_ring_full),
    .wr_cpq_cnt         (wr_cpq_cnt),
    .rd_cpq_cnt         (rd_cpq_cnt),
    .start_busy_err     (start_busy_err),
    .wr_orphan_sticky   (wr_orphan_sticky),
    .wr_orphan_axiid    (wr_orphan_axiid),
    .wr_orphan_clr      (wr_orphan_clr),
    .rd_orphan_sticky   (rd_orphan_sticky),
    .rd_orphan_axiid    (rd_orphan_axiid),
    .rd_orphan_clr      (rd_orphan_clr),
    .wr_ring_vld_vec    (wr_ring_vld_vec),
    .rd_ring_vld_vec    (rd_ring_vld_vec),
    .wr_ring_head       (wr_ring_head),
    .wr_ring_tail       (wr_ring_tail),
    .wr_ring_count      (wr_ring_count),
    .rd_ring_head       (rd_ring_head),
    .rd_ring_tail       (rd_ring_tail),
    .rd_ring_count      (rd_ring_count),
    .wr_cur_cmd_idx     (wr_cur_cmd_idx),
    .wr_cur_active      (wr_cur_active),
    .rd_cur_cmd_idx     (rd_cur_cmd_idx),
    .rd_cur_active      (rd_cur_active),
    .stat_rd_idx        (stat_rd_idx),
    .stat_rd_data       (stat_rd_data),
    .any_cmd_err        (any_cmd_err)
  );

  //--------------------------------------------------------------------------
  // Instruction RAM (XPM_MEMORY_SDPRAM, 3 x RAMB36E5)
  //--------------------------------------------------------------------------
  custom_axi_tg_iram #(
    .IRAM_WIDTH (TG_IRAM_WIDTH),
    .IRAM_DEPTH (TG_IRAM_DEPTH)
  ) i_iram (
    .clk        (m_axi_aclk),
    .rstn       (m_axi_aresetn),
    .wea        (iram_wen),
    .addra      (iram_waddr),
    .dina       (iram_wdata),
    .enb        (iram_enb),
    .addrb      (iram_addrb),
    .doutb      (iram_rdata)
  );

  //--------------------------------------------------------------------------
  // Per-command status flop array
  //--------------------------------------------------------------------------
  custom_axi_tg_status #(
    .MAX_COMMANDS         (MAX_COMMANDS)
  ) i_status (
    .clk                  (m_axi_aclk),
    .rstn                 (m_axi_aresetn),
    .clr_all              (clr_all),
    .wr_set_freq          (wr_set_freq),
    .wr_freq_idx          (wr_freq_idx),
    .wr_set_fresp         (wr_set_fresp),
    .wr_fresp_idx         (wr_fresp_idx),
    .wr_err_vld           (wr_err_vld),
    .wr_err_idx           (wr_err_idx),
    .wr_err_slverr        (wr_err_slverr),
    .wr_err_num           (wr_err_num),
    .wr_err_axiid         (wr_err_axiid),
    .rd_set_freq          (rd_set_freq),
    .rd_freq_idx          (rd_freq_idx),
    .rd_set_fresp         (rd_set_fresp),
    .rd_fresp_idx         (rd_fresp_idx),
    .rd_err_vld           (rd_err_vld),
    .rd_err_idx           (rd_err_idx),
    .rd_err_slverr        (rd_err_slverr),
    .rd_err_num           (rd_err_num),
    .rd_err_axiid         (rd_err_axiid),
    .prog_valid_set       (prog_valid_set),
    .prog_valid_idx       (prog_valid_idx),
    .prog_valid_clr_all   (prog_valid_clr_all),
    .rd_idx               (stat_rd_idx),
    .rd_data              (stat_rd_data),
    .wr_q_idx             (wr_q_idx),
    .wr_q_fully_requested (wr_q_fully_requested),
    .rd_q_idx             (rd_q_idx),
    .rd_q_fully_requested (rd_q_fully_requested),
    .q_idx                (q_idx),
    .q_programmed_valid   (q_programmed_valid),
    .prog_valid_vec       (prog_valid_vec),
    .any_cmd_err          (any_cmd_err)
  );

  //--------------------------------------------------------------------------
  // Pipelined fetch sequencer
  //--------------------------------------------------------------------------
  custom_axi_tg_seq #(
    .MAX_COMMANDS       (MAX_COMMANDS),
    .IRAM_WIDTH         (TG_IRAM_WIDTH),
    .CPQ_DEPTH          (CPQ_DEPTH)
  ) i_seq (
    .clk                (m_axi_aclk),
    .rstn               (m_axi_aresetn),
    .start_pulse_int    (start_pulse_int),
    .start_pulse_ext    (start_pulse_ext),
    .stop_pulse         (stop_pulse),
    .start_busy_err_clr (start_busy_err_clr),
    .done_ptr           (done_ptr),
    .iram_ren           (seq_iram_ren),
    .iram_raddr         (seq_iram_raddr),
    .iram_rdata         (iram_rdata),
    .wr_cpq_push        (wr_cpq_push),
    .rd_cpq_push        (rd_cpq_push),
    .cpq_push_idx       (cpq_push_idx),
    .cpq_push_word      (cpq_push_word),
    .wr_cpq_cnt         (wr_cpq_cnt),
    .rd_cpq_cnt         (rd_cpq_cnt),
    .wr_ring_empty      (wr_ring_empty),
    .rd_ring_empty      (rd_ring_empty),
    .wr_disp_busy       (wr_disp_busy),
    .rd_disp_busy       (rd_disp_busy),
    .wr_stop_done       (wr_stop_done),
    .rd_stop_done       (rd_stop_done),
    .stop_req           (stop_req),
    .cpq_flush          (cpq_flush),
    .clr_all            (clr_all),
    .q_idx              (q_idx),
    .q_programmed_valid (q_programmed_valid),
    .run_state          (run_state),
    .cur_cmd_ptr        (cur_cmd_ptr),
    .start_busy_err     (start_busy_err)
  );

  //--------------------------------------------------------------------------
  // Write dispatcher + its outstanding-command ring
  //--------------------------------------------------------------------------
  custom_axi_tg_wr_disp #(
    .AXI_ADDRESS_WIDTH   (AXI_ADDRESS_WIDTH),
    .AXI_ID_WIDTH        (AXI_ID_WIDTH),
    .IRAM_WIDTH          (TG_IRAM_WIDTH),
    .CPQ_DEPTH           (CPQ_DEPTH),
    .LFSR64_GALOIS       (LFSR64_GALOIS),
    .LFSR27_GALOIS       (LFSR27_GALOIS),
    .LFSR8_GALOIS        (LFSR8_GALOIS),
    .LFSR64_SEED         (LFSR64_SEED),
    .LFSR27_SEED         (LFSR27_WR_SEED),
    .LFSR8_SEED          (LFSR8_WR_SEED)
  ) i_wr_disp (
    .clk                 (m_axi_aclk),
    .rstn                (m_axi_aresetn),
    .run                 (run_state == ST_IN_PROG),
    .stop_req            (stop_req),
    .stop_done           (wr_stop_done),
    .cpq_flush           (cpq_flush),
    .cpq_push            (wr_cpq_push),
    .cpq_push_idx        (cpq_push_idx),
    .cpq_push_word       (cpq_push_word),
    .cpq_cnt             (wr_cpq_cnt),
    .cpq_pop             (wr_cpq_pop),
    .ring_alloc          (wr_ring_alloc),
    .ring_alloc_idx      (wr_ring_alloc_idx),
    .ring_inc            (wr_ring_inc),
    .ring_inc_oh         (wr_ring_inc_oh),
    .ring_dec            (wr_ring_dec),
    .ring_dec_oh         (wr_ring_dec_oh),
    .ring_full           (wr_ring_full),
    .ring_dec_vld        (wr_ring_dec_vld),
    .ring_dec_hit        (wr_ring_dec_hit),
    .ring_dec_cmd_idx    (wr_ring_dec_cmd_idx),
    .ring_dec_rsp_ord    (wr_ring_dec_rsp_ord),
    .ring_retire         (wr_ring_retire),
    .ring_retire_cmd_idx (wr_ring_retire_idx),
    .set_freq            (wr_set_freq),
    .freq_idx            (wr_freq_idx),
    .set_fresp           (wr_set_fresp),
    .fresp_idx           (wr_fresp_idx),
    .err_vld             (wr_err_vld),
    .err_idx             (wr_err_idx),
    .err_slverr          (wr_err_slverr),
    .err_num             (wr_err_num),
    .err_axiid           (wr_err_axiid),
    .busy                (wr_disp_busy),
    .cur_cmd_idx         (wr_cur_cmd_idx),
    .cur_active          (wr_cur_active),
    .m_axi_awaddr        (m_axi_awaddr),
    .m_axi_awid          (m_axi_awid),
    .m_axi_awvalid       (m_axi_awvalid),
    .m_axi_awready       (m_axi_awready),
    .m_axi_wdata         (m_axi_wdata),
    .m_axi_wstrb         (m_axi_wstrb),
    .m_axi_wuser         (m_axi_wuser),
    .m_axi_wvalid        (m_axi_wvalid),
    .m_axi_wready        (m_axi_wready),
    .m_axi_bvalid        (m_axi_bvalid),
    .m_axi_bready        (m_axi_bready),
    .m_axi_bid           (m_axi_bid),
    .m_axi_bresp         (m_axi_bresp)
  );

  // The ring is only ever flushed while it is already EMPTY: cpq_flush pulses
  // out of reset, on an accepted start (reachable only from IDLE or
  // ALL_RESPONDED, both of which mean "nothing outstanding") and at the end of
  // a STOPPING drain.  Flushing mid-flight would strand outstanding responses
  // and turn them into orphans, so it is never done.
  custom_axi_tg_ring #(
    .RING_DEPTH     (RING_DEPTH),
    .NUM_IDS        (NUM_IDS),
    .CNT_W          (TXN_CNT_W)
  ) i_wr_ring (
    .clk            (m_axi_aclk),
    .rstn           (m_axi_aresetn),
    .flush          (cpq_flush),
    .alloc          (wr_ring_alloc),
    .alloc_cmd_idx  (wr_ring_alloc_idx),
    .full           (wr_ring_full),
    .empty          (wr_ring_empty),
    .inc            (wr_ring_inc),
    .inc_oh         (wr_ring_inc_oh),
    .dec            (wr_ring_dec),
    .dec_oh         (wr_ring_dec_oh),
    .dec_vld        (wr_ring_dec_vld),
    .dec_hit        (wr_ring_dec_hit),
    .dec_cmd_idx    (wr_ring_dec_cmd_idx),
    .dec_rsp_ord    (wr_ring_dec_rsp_ord),
    .dec_axiid      (wr_ring_dec_axiid),
    .freq_query_idx (wr_q_idx),
    .head_cmd_freq  (wr_q_fully_requested),
    .req_quiesced   (stop_req && wr_stop_done),
    .retire         (wr_ring_retire),
    .retire_cmd_idx (wr_ring_retire_idx),
    .vld_vec        (wr_ring_vld_vec),
    .head           (wr_ring_head),
    .tail           (wr_ring_tail),
    .count          (wr_ring_count),
    .orphan_sticky  (wr_orphan_sticky),
    .orphan_axiid   (wr_orphan_axiid),
    .orphan_clr     (wr_orphan_clr)
  );

  //--------------------------------------------------------------------------
  // Read dispatcher + its outstanding-command ring
  //--------------------------------------------------------------------------
  custom_axi_tg_rd_disp #(
    .AXI_ADDRESS_WIDTH   (AXI_ADDRESS_WIDTH),
    .AXI_ID_WIDTH        (AXI_ID_WIDTH),
    .IRAM_WIDTH          (TG_IRAM_WIDTH),
    .CPQ_DEPTH           (CPQ_DEPTH),
    .LFSR27_GALOIS       (LFSR27_GALOIS),
    .LFSR8_GALOIS        (LFSR8_GALOIS),
    .LFSR27_SEED         (LFSR27_RD_SEED),
    .LFSR8_SEED          (LFSR8_RD_SEED)
  ) i_rd_disp (
    .clk                 (m_axi_aclk),
    .rstn                (m_axi_aresetn),
    .run                 (run_state == ST_IN_PROG),
    .stop_req            (stop_req),
    .stop_done           (rd_stop_done),
    .cpq_flush           (cpq_flush),
    .cpq_push            (rd_cpq_push),
    .cpq_push_idx        (cpq_push_idx),
    .cpq_push_word       (cpq_push_word),
    .cpq_cnt             (rd_cpq_cnt),
    .cpq_pop             (rd_cpq_pop),
    .ring_alloc          (rd_ring_alloc),
    .ring_alloc_idx      (rd_ring_alloc_idx),
    .ring_inc            (rd_ring_inc),
    .ring_inc_oh         (rd_ring_inc_oh),
    .ring_dec            (rd_ring_dec),
    .ring_dec_oh         (rd_ring_dec_oh),
    .ring_full           (rd_ring_full),
    .ring_dec_vld        (rd_ring_dec_vld),
    .ring_dec_hit        (rd_ring_dec_hit),
    .ring_dec_cmd_idx    (rd_ring_dec_cmd_idx),
    .ring_dec_rsp_ord    (rd_ring_dec_rsp_ord),
    .ring_retire         (rd_ring_retire),
    .ring_retire_cmd_idx (rd_ring_retire_idx),
    .set_freq            (rd_set_freq),
    .freq_idx            (rd_freq_idx),
    .set_fresp           (rd_set_fresp),
    .fresp_idx           (rd_fresp_idx),
    .err_vld             (rd_err_vld),
    .err_idx             (rd_err_idx),
    .err_slverr          (rd_err_slverr),
    .err_num             (rd_err_num),
    .err_axiid           (rd_err_axiid),
    .busy                (rd_disp_busy),
    .cur_cmd_idx         (rd_cur_cmd_idx),
    .cur_active          (rd_cur_active),
    .m_axi_araddr        (m_axi_araddr),
    .m_axi_arid          (m_axi_arid),
    .m_axi_aruser        (m_axi_aruser),
    .m_axi_arvalid       (m_axi_arvalid),
    .m_axi_arready       (m_axi_arready),
    .m_axi_rvalid        (m_axi_rvalid),
    .m_axi_rready        (m_axi_rready),
    .m_axi_rid           (m_axi_rid),
    .m_axi_rresp         (m_axi_rresp)
  );

  custom_axi_tg_ring #(
    .RING_DEPTH     (RING_DEPTH),
    .NUM_IDS        (NUM_IDS),
    .CNT_W          (TXN_CNT_W)
  ) i_rd_ring (
    .clk            (m_axi_aclk),
    .rstn           (m_axi_aresetn),
    .flush          (cpq_flush),
    .alloc          (rd_ring_alloc),
    .alloc_cmd_idx  (rd_ring_alloc_idx),
    .full           (rd_ring_full),
    .empty          (rd_ring_empty),
    .inc            (rd_ring_inc),
    .inc_oh         (rd_ring_inc_oh),
    .dec            (rd_ring_dec),
    .dec_oh         (rd_ring_dec_oh),
    .dec_vld        (rd_ring_dec_vld),
    .dec_hit        (rd_ring_dec_hit),
    .dec_cmd_idx    (rd_ring_dec_cmd_idx),
    .dec_rsp_ord    (rd_ring_dec_rsp_ord),
    .dec_axiid      (rd_ring_dec_axiid),
    .freq_query_idx (rd_q_idx),
    .head_cmd_freq  (rd_q_fully_requested),
    .req_quiesced   (stop_req && rd_stop_done),
    .retire         (rd_ring_retire),
    .retire_cmd_idx (rd_ring_retire_idx),
    .vld_vec        (rd_ring_vld_vec),
    .head           (rd_ring_head),
    .tail           (rd_ring_tail),
    .count          (rd_ring_count),
    .orphan_sticky  (rd_orphan_sticky),
    .orphan_axiid   (rd_orphan_axiid),
    .orphan_clr     (rd_orphan_clr)
  );

  `ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (AXI_ADDRESS_WIDTH > 48)
      $fatal(1, $sformatf("AXI_ADDRESS_WIDTH=%0d is invalid; maximum is 48",
                          AXI_ADDRESS_WIDTH));
    if (AXI_ID_WIDTH > 4)
      $fatal(1, $sformatf("AXI_ID_WIDTH=%0d is invalid; maximum is 4",
                          AXI_ID_WIDTH));
    if (MAX_COMMANDS > 512)
      $fatal(1, $sformatf({"MAX_COMMANDS=%0d is invalid; maximum is 512 ",
                           "(BRAM depth)"}, MAX_COMMANDS));
    if (|(RING_DEPTH & (RING_DEPTH-1)))
      $fatal(1, $sformatf("RING_DEPTH=%0d is invalid; must be a power of 2",
                          RING_DEPTH));
    if (CPQ_DEPTH < 2)
      $fatal(1, $sformatf({"CPQ_DEPTH=%0d is invalid; a depth of at least 2 is ",
                           "required for zero-bubble command boundaries"},
                          CPQ_DEPTH));
    if (LFSR64_SEED == '0 || LFSR27_WR_SEED == '0 || LFSR27_RD_SEED == '0 ||
        LFSR8_WR_SEED == '0 || LFSR8_RD_SEED == '0)
      $fatal(1, "custom_axi_tg: every LFSR seed must be non-zero");
  end
  //synthesis on
  `endif

endmodule
