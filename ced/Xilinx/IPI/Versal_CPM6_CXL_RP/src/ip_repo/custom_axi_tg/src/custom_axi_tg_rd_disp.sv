// MODULE : custom_axi_tg_rd_disp
//
// DESCRIPTION:
// Read dispatcher.  Structurally identical to custom_axi_tg_wr_disp but with a
// single request channel (AR) instead of two (AW + W), and without the write
// data path: no lfsr64, no be_prob_k, no data_mode / data_start / data_stride.
// m_axi_aruser replaces m_axi_wuser.
//
// Like the write dispatcher it has NO SETUP STATE AND NO FSM ENUM: two
// registered flags, active and ar_pend, fed by a 2-deep command prefetch
// queue whose head word is sliced with zero LUT delay.  The
// cycle command N's last AR is accepted is the cycle command N+1 is loaded, so
// N+1's first ARVALID goes out on the very next cycle.
//
// DETAILS:
//  - RDATA is consumed and discarded; this is a traffic generator, not a data
//    checker.  Only RRESP is inspected, to populate the per-command
//    {invalid_response_rcvd, is_slverr,
//    first_invalid_number, first_invalid_axiid} fields.  RREADY is tied high so
//    the bridge can never be held off.  RLAST is ignored because every burst is
//    a single beat.
//  - RING TIMING CONTRACT (see the header of custom_axi_tg_ring.sv):
//    ring_alloc and ring_inc are COMBINATIONAL, ring_dec / ring_dec_oh are
//    REGISTERED off RVALID, and ring_inc_oh / ring_alloc_idx are registered
//    and stable.
//  - There is NO half-issued case here - AR is a single channel - so stop_done
//    is simply "AR not pending".  A stop still never drops an asserted
//    ARVALID: the current offer is ridden out and its ring entry keeps
//    counting, so no orphan response is possible.
//  - The response path is a SEPARATE always_ff so responses for command N can
//    be processed while the datapath is already issuing command N+2.
//
// RESTRICTIONS:
//  - AXI_ADDRESS_WIDTH <= 48.  The instruction word always carries a 48-bit
//    start_address; bits above AXI_ADDRESS_WIDTH-1 are silently dropped.
//  - Legal addr_k is 0..26; 27..31 are clamped to 26 at iRAM commit time.
//
// ACRONYMS:
//  - CPQ   = command prefetch queue
//  - freq  = fully_requested
//  - fresp = fully_responded
//  - acc   = accepted (valid && ready)

module custom_axi_tg_rd_disp
  import custom_axi_tg_pkg::*;
#(
  parameter int          AXI_ADDRESS_WIDTH = 48,
  parameter int          AXI_ID_WIDTH      = 1,
  parameter int          IRAM_WIDTH        = 192,
  parameter int          CPQ_DEPTH         = 2,
  parameter bit          LFSR27_GALOIS     = 1'b1,
  parameter bit          LFSR8_GALOIS      = 1'b1,
  parameter logic [26:0] LFSR27_SEED       = 27'h367AE85,
  parameter logic [ 7:0] LFSR8_SEED        = 8'h6D,
  localparam int         ID_PORT_W         = (AXI_ID_WIDTH==0) ? 1 : AXI_ID_WIDTH,
  localparam int         NUM_IDS           = (AXI_ID_WIDTH==0) ? 1
                                                               : (1<<AXI_ID_WIDTH)
)(
  input                                clk,
  input                                rstn,
  input                                run,                  // run_state == IN_PROG
  input                                stop_req,             // level, from the sequencer
  output logic                         stop_done,            // AR not pending
  input                                cpq_flush,
  // command prefetch queue (fed by the sequencer)
  input                                cpq_push,
  input        [                  8:0] cpq_push_idx,
  input        [       IRAM_WIDTH-1:0] cpq_push_word,
  output logic [                  1:0] cpq_cnt,
  output logic                         cpq_pop,
  // outstanding-command ring.  alloc / inc COMBINATIONAL, dec REGISTERED.
  output logic                         ring_alloc,
  output logic [                  8:0] ring_alloc_idx,
  output logic                         ring_inc,
  output logic [          NUM_IDS-1:0] ring_inc_oh,
  output logic                         ring_dec,
  output logic [          NUM_IDS-1:0] ring_dec_oh,
  input                                ring_full,
  input                                ring_dec_vld,
  input                                ring_dec_hit,         // 0 => orphan (bug!)
  input        [                  8:0] ring_dec_cmd_idx,
  input        [                 11:0] ring_dec_rsp_ord,     // PER-ID ordinal
  input                                ring_retire,
  input        [                  8:0] ring_retire_cmd_idx,
  // status array writes
  output logic                         set_freq,
  output logic [                  8:0] freq_idx,
  output logic                         set_fresp,
  output logic [                  8:0] fresp_idx,
  output logic                         err_vld,
  output logic [                  8:0] err_idx,
  output logic                         err_slverr,
  output logic [                 11:0] err_num,
  output logic [                  3:0] err_axiid,
  output logic                         busy,
  // debug
  output logic [                  8:0] cur_cmd_idx,
  output logic                         cur_active,
  // AXI4 master read channels
  output logic [AXI_ADDRESS_WIDTH-1:0] m_axi_araddr,
  output logic [        ID_PORT_W-1:0] m_axi_arid,
  output logic [                 34:0] m_axi_aruser,
  output logic                         m_axi_arvalid,
  input                                m_axi_arready,
  input                                m_axi_rvalid,
  output logic                         m_axi_rready,
  input        [        ID_PORT_W-1:0] m_axi_rid,
  input        [                  1:0] m_axi_rresp
);

  //--- command prefetch queue -----------------------------------------------
  logic                  cpq_head_vld;
  logic [           8:0] cpq_head_idx;
  logic [IRAM_WIDTH-1:0] cpq_head_word;
  logic                  cpq_full;

  //--- decoded command (loaded in a single cycle from CPQ head slices) -------
  logic [ 8:0] cmd_idx_q;
  logic [47:0] start_addr_q;
  logic [31:0] addr_stride_q;
  logic [ 4:0] addr_k_q;
  logic [ 3:0] id_stride_q;
  logic [ 1:0] aruser_cmd_q;
  logic        addr_mode_q;
  logic        id_mode_q;

  //--- working registers ----------------------------------------------------
  logic [         47:0] addr_q;
  logic [ID_PORT_W-1:0] id_q;
  logic [  NUM_IDS-1:0] id_oh_q;
  logic [         11:0] rem;
  logic                 last_txn_r;
  logic                 active, ar_pend;

  //--- generator outputs ----------------------------------------------------
  logic [         47:0] addr_next;
  logic [ID_PORT_W-1:0] id_next;
  logic [         26:0] lfsr27_state;
  logic [          7:0] lfsr8_state;

  logic ar_acc, txn_acc, roll, load_new, ar_pend_n;
  logic lfsr27_adv, lfsr8_adv;

  //--- CPQ head field extraction - pure bit-slicing, zero LUT delay ----------
  logic [47:0] h_start_addr;
  logic [ 3:0] h_start_id;
  assign h_start_addr = {cpq_head_word[IW_ADDR_HI_LSB   +: 16],
                         cpq_head_word[IW_ADDR_LO_LSB+6 +: 26],
                         6'h0};                       // 64 B aligned
  assign h_start_id   = cpq_head_word[IW_START_ID_LSB +: 4];

  //--------------------------------------------------------------------------
  // Issue.  ARVALID is NOT gated by `run` or `stop_req`: AXI4 forbids
  // deasserting VALID before its handshake completes.
  //--------------------------------------------------------------------------
  assign m_axi_arvalid = ar_pend;
  assign ar_acc        = m_axi_arvalid && m_axi_arready;
  assign txn_acc       = ar_acc;

  assign roll          = txn_acc && last_txn_r;
  assign load_new      = (!active || roll) && cpq_head_vld && !ring_full &&
                         run && !stop_req;

  //--- ring (alloc and inc COMBINATIONAL - see the header) ------------------
  assign cpq_pop        = load_new;
  assign ring_alloc     = load_new;
  assign ring_alloc_idx = cpq_head_idx;               // registered in the CPQ
  assign ring_inc       = txn_acc;
  assign ring_inc_oh    = id_oh_q;                    // REGISTERED one-hot

  assign busy           = active || ar_pend;
  assign stop_done      = !ar_pend;
  assign cur_cmd_idx    = cmd_idx_q;
  assign cur_active     = active;

  assign m_axi_araddr   = addr_q[AXI_ADDRESS_WIDTH-1:0];
  assign m_axi_arid     = id_q;
  assign m_axi_aruser   = {33'h0, aruser_cmd_q};  // bridge ARUSER_CMND_BS = 0
  assign m_axi_rready   = 1'b1;                   // RDATA is discarded

  assign lfsr27_adv     = txn_acc && addr_mode_q;
  assign lfsr8_adv      = txn_acc && id_mode_q;

  //--------------------------------------------------------------------------
  // Next state of the pending flag.  Same shape as the write side minus the
  // half-issued case: AR is one channel, so txn_acc == ar_acc.
  //--------------------------------------------------------------------------
  always_comb begin
    if (load_new)
      ar_pend_n = 1'b1;
    else if (roll)
      ar_pend_n = 1'b0;
    else if (txn_acc)
      ar_pend_n = !stop_req;
    else
      ar_pend_n = ar_pend;
  end

  // rem/addr_q/id_q/start_addr_q/addr_stride_q/addr_k_q/id_stride_q/
  // aruser_cmd_q/addr_mode_q/id_mode_q are all data qualified by ar_pend:
  // m_axi_araddr/m_axi_aruser/etc. drive the bus directly from these every
  // cycle, but AXI4 requires a slave to ignore them whenever ARVALID
  // (=ar_pend, which DOES reset) is low, and load_new always writes them
  // fresh before ar_pend can next assert.  They are intentionally left out of
  // reset.
  always_ff @(posedge clk) begin
    if (!rstn) begin
      active        <= 1'b0;
      ar_pend       <= 1'b0;
      last_txn_r    <= 1'b0;
      id_oh_q       <= NUM_IDS'(1);
      cmd_idx_q     <= 9'h000;
      set_freq      <= 1'b0;
      freq_idx      <= 9'h000;
    end
    else begin
      ar_pend <= ar_pend_n;

      // fully_requested is registered off `roll`, i.e. it lands in the same
      // cycle the next command's first transaction issues - zero bubble.
      set_freq <= roll;
      freq_idx <= cmd_idx_q;

      if (load_new) begin
        active        <= 1'b1;
        cmd_idx_q     <= cpq_head_idx;
        start_addr_q  <= h_start_addr;
        addr_stride_q <= cpq_head_word[IW_ADDR_STRIDE_LSB +: 32];
        addr_k_q      <= cpq_head_word[IW_ADDR_K_LSB      +:  5];
        id_stride_q   <= cpq_head_word[IW_ID_STRIDE_LSB   +:  4];
        aruser_cmd_q  <= cpq_head_word[IW_ARUSER_CMD_LSB  +:  2];
        addr_mode_q   <= cpq_head_word[IW_ADDR_MODE];
        id_mode_q     <= cpq_head_word[IW_ID_MODE];
        addr_q        <= h_start_addr;                // pure wiring
        id_q          <= (AXI_ID_WIDTH == 0) ? '0
                                             : h_start_id[ID_PORT_W-1:0];
        id_oh_q       <= (AXI_ID_WIDTH == 0)
                           ? NUM_IDS'(1)
                           : (NUM_IDS'(1) << h_start_id[ID_PORT_W-1:0]);
        rem           <= cpq_head_word[IW_REPEAT_LSB +: 12];
        last_txn_r    <= (cpq_head_word[IW_REPEAT_LSB +: 12] == 12'h000);
      end
      else if (txn_acc) begin
        addr_q     <= addr_next;
        id_q       <= id_next;
        id_oh_q    <= (AXI_ID_WIDTH == 0) ? NUM_IDS'(1)
                                          : (NUM_IDS'(1) << id_next);
        rem        <= rem - 12'h001;
        last_txn_r <= (rem == 12'h001);
      end

      if (roll && !load_new)
        active <= 1'b0;

      // A completed STOPPING drain (or an accepted start) discards any command
      // that is still loaded: it will never be continued, and leaving `active`
      // set would permanently block load_new on the NEXT run, because load_new
      // needs (!active || roll) and a roll can never arrive for a command that
      // was abandoned.  cpq_flush is only ever asserted when nothing is
      // outstanding, so this cannot drop live state.
      if (cpq_flush)
        active <= 1'b0;
    end
  end

  //--------------------------------------------------------------------------
  // Retirement -> fully_responded
  //--------------------------------------------------------------------------
  assign set_fresp = ring_retire;
  assign fresp_idx = ring_retire_cmd_idx;

  //--------------------------------------------------------------------------
  // Response path (see the timing note in custom_axi_tg_wr_disp)
  //--------------------------------------------------------------------------
  logic [1:0]           rresp_q, rresp_q2;
  logic [ID_PORT_W-1:0] rid_q, rid_q2;

  // Every signal in this always_ff is unconditionally re-registered every
  // cycle from a combinational function of the AXI pins (or is a
  // default-then-override pulse: err_vld <= 0 unconditionally, then
  // conditionally set), so none of them needs a reset value - the first real
  // post-reset clock edge already produces a correct, real value regardless.
  always_ff @(posedge clk) begin
    // Only single-beat bursts are generated, so every RVALID is a complete
    // response and RLAST need not be inspected.
    ring_dec    <= m_axi_rvalid;
    ring_dec_oh <= m_axi_rvalid ? (NUM_IDS'(1) << m_axi_rid) : '0;
    rresp_q     <= m_axi_rresp;
    rid_q       <= m_axi_rid;

    rresp_q2    <= rresp_q;
    rid_q2      <= rid_q;

    err_vld     <= 1'b0;
    if (ring_dec_vld && ring_dec_hit && (rresp_q2 != RESP_OKAY)) begin
      err_vld    <= 1'b1;
      err_idx    <= ring_dec_cmd_idx;
      err_slverr <= (rresp_q2 == RESP_SLVERR);  // the only other is DECERR
      err_num    <= ring_dec_rsp_ord;           // PER-ID ordinal
      err_axiid  <= 4'(rid_q2);
    end
  end

  //--------------------------------------------------------------------------
  // Command prefetch queue
  //--------------------------------------------------------------------------
  custom_axi_tg_cpq #(
    .IRAM_WIDTH (IRAM_WIDTH),
    .CPQ_DEPTH  (CPQ_DEPTH)
  ) i_cpq (
    .clk        (clk),
    .rstn       (rstn),
    .flush      (cpq_flush),
    .push       (cpq_push),
    .push_idx   (cpq_push_idx),
    .push_word  (cpq_push_word),
    .pop        (cpq_pop),
    .head_vld   (cpq_head_vld),
    .head_idx   (cpq_head_idx),
    .head_word  (cpq_head_word),
    .cnt        (cpq_cnt),
    .full       (cpq_full)
  );

  //--------------------------------------------------------------------------
  // Address / ID generation
  //--------------------------------------------------------------------------
  custom_axi_tg_addr_gen i_addr_gen (
    .start_address (start_addr_q),
    .addr_stride   (addr_stride_q),
    .addr_k        (addr_k_q),
    .addr_mode     (addr_mode_q),
    .addr_q        (addr_q),
    .lfsr27_state  (lfsr27_state),
    .addr_next     (addr_next)
  );

  custom_axi_tg_id_gen #(
    .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) i_id_gen (
    .id_q          (id_q),
    .id_stride     (id_stride_q),
    .id_mode       (id_mode_q),
    .lfsr8_state   (lfsr8_state),
    .id_next       (id_next)
  );

  lfsr27 #(
    .GALOIS (LFSR27_GALOIS),
    .SEED   (LFSR27_SEED)
  ) i_lfsr27 (
    .clk    (clk),
    .rstn   (rstn),
    .adv    (lfsr27_adv),
    .state  (lfsr27_state)
  );

  generate
  if (AXI_ID_WIDTH >= 1) begin : g_id_lfsr
    // lfsr8 is instantiated from AXI_ID_WIDTH 1 upwards.  Its width is fixed
    // at 8 regardless, so the 1-bit case costs 8 flops and yields a genuinely
    // pseudo-random ID bit instead of a deterministic toggle.
    lfsr8 #(
      .GALOIS (LFSR8_GALOIS),
      .SEED   (LFSR8_SEED)
    ) i_lfsr8 (
      .clk    (clk),
      .rstn   (rstn),
      .adv    (lfsr8_adv),
      .state  (lfsr8_state)
    );
  end
  else begin : g_id_tied
    // AXI_ID_WIDTH == 0: the AXI ID is hardcoded to 0, so no LFSR is needed.
    assign lfsr8_state = 8'h00;
  end
  endgenerate

endmodule
