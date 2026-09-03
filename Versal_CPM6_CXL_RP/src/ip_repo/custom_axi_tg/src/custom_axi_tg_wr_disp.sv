// MODULE : custom_axi_tg_wr_disp
//
// DESCRIPTION:
// Write dispatcher.  Turns one decoded WRITE command into repeat_count+1 AXI
// write transactions, owns the address / ID / data generators and all three
// LFSRs of the write path, and processes returning B responses through the
// outstanding-command ring.
//
// THERE IS NO W_SETUP STATE AND NO FSM ENUM AT ALL.  The dispatcher is a
// datapath governed by three registered flags - active, aw_pend, w_pend - fed
// by a 2-deep command prefetch queue.
// Because the instruction layout is fixed, extracting a field from the CPQ head
// word is pure bit-slicing with zero LUT delay, so on the cycle a command is
// loaded the working registers are written directly from head_word slices and
// the FOLLOWING cycle drives AXI:
//
//   cycle T   : command N's LAST transaction is accepted (txn_acc && last_txn_r)
//               -> roll = 1, load_new = 1, cpq_pop = 1, ring_alloc = 1
//               -> addr_q / id_q / data_q / rem <= N+1's start values
//   cycle T+1 : command N+1 drives AWVALID+WVALID - NO BUBBLE
//               -> set_freq for command N pulses HERE, satisfying
//                  "fully_requested for N asserts in the same cycle N+1's
//                  first transaction issues"
//
// DETAILS:
//  - AW and W have independent ready.  pl_axi_cpi_bridge asserts
//    awready = !w_ph_now, i.e. it can take AW before W, so the two channels are
//    tracked with separate pending flags and a transaction is only counted once
//    BOTH have been accepted.
//  - Same-type ordering needs no extra logic: load_new for command N+1 can
//    only fire on the cycle command N rolls, so N+1's requests strictly follow
//    all of N's on the wire.  That is also what makes the ring's per-ID
//    attribution a strict FIFO over commands.
//  - RING TIMING CONTRACT (see the header of custom_axi_tg_ring.sv), honoured
//    below:
//      ring_alloc and ring_inc are COMBINATIONAL - asserted in the SAME cycle
//      as the AXI handshake; ring_dec / ring_dec_oh are REGISTERED off BVALID;
//      ring_inc_oh (id_oh_q) and ring_alloc_idx (straight out of the CPQ
//      register) are registered and stable.
//    Registering inc would put nz one cycle behind a response that arrives
//    immediately after its request, so that response would find no owner and
//    be counted as an orphan; registering alloc would cost a bubble cycle at
//    every command boundary.
//  - last_txn_r is a REGISTERED flag, not a combinational rem == 0 compare.
//    roll (and therefore load_new, cpq_pop and ring_alloc) sits directly
//    downstream of m_axi_awready / m_axi_wready, so keeping the last-transaction
//    test out of that cone reduces it to one LUT level from the input pins.
//  - The response path is a SEPARATE always_ff, not part of the issue datapath,
//    because responses for command N arrive while the datapath is already
//    issuing command N+2.
//  - Only 64 B aligned, single beat, full-width transfers are generated, so
//    AWLEN / AWSIZE / AWBURST are constants driven at the top level.
//
// RESTRICTIONS:
//  - AXI_ADDRESS_WIDTH <= 48.  The instruction word always carries a 48-bit
//    start_address; bits above AXI_ADDRESS_WIDTH-1 are silently dropped.
//  - Legal addr_k is 0..26; 27..31 are clamped to 26 at iRAM commit time, so
//    this module never sees an out-of-range value.  be_prob_k has no such
//    restriction: all 8 encodings of its 3-bit field are legal (0..6 select
//    a 1/2**k partial-BE probability, 7 forces WSTRB='1 unconditionally).
//
// ACRONYMS:
//  - CPQ   = command prefetch queue
//  - freq  = fully_requested
//  - fresp = fully_responded
//  - BE    = byte enable (WSTRB)
//  - acc   = accepted (valid && ready)

module custom_axi_tg_wr_disp
  import custom_axi_tg_pkg::*;
#(
  parameter int          AXI_ADDRESS_WIDTH = 48,
  parameter int          AXI_ID_WIDTH      = 1,
  parameter int          IRAM_WIDTH        = 192,
  parameter int          CPQ_DEPTH         = 2,
  parameter bit          LFSR64_GALOIS     = 1'b1,
  parameter bit          LFSR27_GALOIS     = 1'b1,
  parameter bit          LFSR8_GALOIS      = 1'b1,
  parameter logic [63:0] LFSR64_SEED       = 64'h9E37_79B9_7F4A_7C15,
  parameter logic [26:0] LFSR27_SEED       = 27'h63779B9,
  parameter logic [ 7:0] LFSR8_SEED        = 8'hB5,
  localparam int         ID_PORT_W         = (AXI_ID_WIDTH==0) ? 1 : AXI_ID_WIDTH,
  localparam int         NUM_IDS           = (AXI_ID_WIDTH==0) ? 1
                                                               : (1<<AXI_ID_WIDTH)
)(
  input                                clk,
  input                                rstn,
  input                                run,                  // run_state == IN_PROG
  input                                stop_req,             // level, from the sequencer
  output logic                         stop_done,            // nothing being offered
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
  // AXI4 master write channels
  output logic [AXI_ADDRESS_WIDTH-1:0] m_axi_awaddr,
  output logic [        ID_PORT_W-1:0] m_axi_awid,
  output logic                         m_axi_awvalid,
  input                                m_axi_awready,
  output logic [                511:0] m_axi_wdata,
  output logic [                 63:0] m_axi_wstrb,
  output logic [                 32:0] m_axi_wuser,
  output logic                         m_axi_wvalid,
  input                                m_axi_wready,
  input                                m_axi_bvalid,
  output logic                         m_axi_bready,
  input        [        ID_PORT_W-1:0] m_axi_bid,
  input        [                  1:0] m_axi_bresp
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
  logic [31:0] data_stride_q;
  logic [ 4:0] addr_k_q;
  logic [ 2:0] be_k_q;
  logic [ 3:0] id_stride_q;
  logic        addr_mode_q;
  logic        id_mode_q;
  logic        data_mode_q;
  logic        wuser_pois_q;

  //--- working registers ----------------------------------------------------
  logic [         47:0] addr_q;
  logic [ID_PORT_W-1:0] id_q;
  logic [  NUM_IDS-1:0] id_oh_q;
  logic [         31:0] data_q;
  logic [         11:0] rem;
  logic                 last_txn_r;
  logic                 active, aw_pend, w_pend;

  //--- generator outputs ----------------------------------------------------
  logic [         47:0] addr_next;
  logic [ID_PORT_W-1:0] id_next;
  logic [         26:0] lfsr27_state;
  logic [         63:0] lfsr64_state;
  logic [          7:0] lfsr8_state;

  logic aw_acc, w_acc, txn_acc, roll, load_new;
  logic aw_pend_n, w_pend_n;
  logic lfsr64_adv, lfsr27_adv, lfsr8_adv;

  //--------------------------------------------------------------------------
  // CPQ head field extraction - pure bit-slicing, zero LUT delay.  This is
  // what removes the setup state.
  //--------------------------------------------------------------------------
  logic [47:0] h_start_addr;
  logic [ 3:0] h_start_id;
  assign h_start_addr = {cpq_head_word[IW_ADDR_HI_LSB   +: 16],
                         cpq_head_word[IW_ADDR_LO_LSB+6 +: 26],
                         6'h0};                       // 64 B aligned
  assign h_start_id   = cpq_head_word[IW_START_ID_LSB +: 4];

  //--------------------------------------------------------------------------
  // Issue.  AWVALID / WVALID are NOT gated by `run` or `stop_req`: AXI4
  // forbids deasserting VALID before its handshake completes.
  //--------------------------------------------------------------------------
  assign m_axi_awvalid = aw_pend;
  assign m_axi_wvalid  = w_pend;
  assign aw_acc        = m_axi_awvalid && m_axi_awready;
  assign w_acc         = m_axi_wvalid  && m_axi_wready;
  assign txn_acc       = (aw_acc || !aw_pend) && (w_acc || !w_pend) &&
                         (aw_acc || w_acc);

  assign roll          = txn_acc && last_txn_r;       // 1 LUT from the pins
  assign load_new      = (!active || roll) && cpq_head_vld && !ring_full &&
                         run && !stop_req;

  //--- ring (alloc and inc COMBINATIONAL - see the header) ------------------
  assign cpq_pop        = load_new;
  assign ring_alloc     = load_new;
  assign ring_alloc_idx = cpq_head_idx;               // registered in the CPQ
  assign ring_inc       = txn_acc;
  assign ring_inc_oh    = id_oh_q;                    // REGISTERED one-hot

  assign busy           = active || aw_pend || w_pend;
  assign stop_done      = !aw_pend && !w_pend;
  assign cur_cmd_idx    = cmd_idx_q;
  assign cur_active     = active;

  assign m_axi_awaddr   = addr_q[AXI_ADDRESS_WIDTH-1:0];
  assign m_axi_awid     = id_q;
  assign m_axi_wuser    = {32'h0, wuser_pois_q};   // bridge WUSER_POIS_BS = 0
  assign m_axi_bready   = 1'b1;                    // never backpressure

  assign lfsr64_adv     = w_acc;                   // once per accepted W beat
  assign lfsr27_adv     = txn_acc && addr_mode_q;
  assign lfsr8_adv      = txn_acc && id_mode_q;

  //--------------------------------------------------------------------------
  // Next state of the pending flags.
  //  * load_new  : arm both channels for the new command's first transaction
  //  * roll only : the command ended and nothing follows -> go idle
  //  * txn_acc   : re-arm for the next transaction of the SAME command
  //  * otherwise : clear whichever channel was accepted, hold the other -
  //                this is the HALF-ISSUED case and it is legal AXI
  //--------------------------------------------------------------------------
  always_comb begin
    if (load_new)
      {aw_pend_n, w_pend_n} = 2'b11;
    else if (roll)
      {aw_pend_n, w_pend_n} = 2'b00;
    else if (txn_acc)
      {aw_pend_n, w_pend_n} = stop_req ? 2'b00 : 2'b11;
    else
      {aw_pend_n, w_pend_n} = {aw_pend && !aw_acc, w_pend && !w_acc};
  end

  //--------------------------------------------------------------------------
  // STOP RULE.  stop_req is a LEVEL.  It does two things and nothing else:
  //   (a) load_new is gated off, so no further command is loaded;
  //   (b) after the CURRENT transaction is fully accepted (txn_acc), the AW/W
  //       pending flags are NOT re-armed.
  //
  // What it deliberately does NOT do is drop an already-asserted AWVALID or
  // WVALID.  AXI4 forbids deasserting VALID before its handshake completes,
  // so clearing the pending flags on a stop would be a protocol violation.
  // The current transaction is always ridden out instead.
  //
  // The half-issued case (AW accepted, W not, or vice versa) falls out of the
  // ordinary `else` branch above: the accepted channel clears, the other stays
  // pending until the slave takes it, then txn_acc fires.
  //
  // The ring is likewise NOT flushed on stop.  That is what keeps orphans
  // impossible: the final txn_acc still asserts ring_inc, its ring entry stays
  // live, and its response is counted and attributed normally when it returns.
  // Flushing the ring at stop time would strand exactly those in-flight
  // responses, and they would come back with no entry to charge them to --
  // which is what TG_ORPHAN_RSP flags.
  //--------------------------------------------------------------------------
  // rem/addr_q/id_q/data_q/start_addr_q/addr_stride_q/data_stride_q/addr_k_q/
  // be_k_q/id_stride_q/addr_mode_q/id_mode_q/data_mode_q/wuser_pois_q are all
  // data qualified by aw_pend/w_pend: m_axi_awaddr/m_axi_wdata/etc. drive the
  // bus directly from these every cycle, but AXI4 requires a slave to ignore
  // them whenever AWVALID/WVALID (=aw_pend/w_pend, which DO reset) is low, and
  // load_new always writes them fresh before aw_pend/w_pend can next assert.
  // They are intentionally left out of reset.
  always_ff @(posedge clk) begin
    if (!rstn) begin
      active        <= 1'b0;
      aw_pend       <= 1'b0;
      w_pend        <= 1'b0;
      last_txn_r    <= 1'b0;
      id_oh_q       <= NUM_IDS'(1);
      cmd_idx_q     <= 9'h000;
      set_freq      <= 1'b0;
      freq_idx      <= 9'h000;
    end
    else begin
      aw_pend <= aw_pend_n;
      w_pend  <= w_pend_n;

      // fully_requested is registered off `roll`, which places it in the same
      // cycle the next command's first transaction issues - zero bubble.
      // Non-blocking, so freq_idx samples the PRE-load value of cmd_idx_q.
      set_freq <= roll;
      freq_idx <= cmd_idx_q;

      if (load_new) begin
        active        <= 1'b1;
        cmd_idx_q     <= cpq_head_idx;
        start_addr_q  <= h_start_addr;
        addr_stride_q <= cpq_head_word[IW_ADDR_STRIDE_LSB +: 32];
        data_stride_q <= cpq_head_word[IW_DATA_STRIDE_LSB +: 32];
        addr_k_q      <= cpq_head_word[IW_ADDR_K_LSB      +:  5];
        be_k_q        <= cpq_head_word[IW_BE_K_LSB        +:  3];
        id_stride_q   <= cpq_head_word[IW_ID_STRIDE_LSB   +:  4];
        addr_mode_q   <= cpq_head_word[IW_ADDR_MODE];
        id_mode_q     <= cpq_head_word[IW_ID_MODE];
        data_mode_q   <= cpq_head_word[IW_DATA_MODE];
        wuser_pois_q  <= cpq_head_word[IW_WUSER_POISON];
        // Working registers: transaction 0 uses the programmed values
        addr_q        <= h_start_addr;                // pure wiring
        id_q          <= (AXI_ID_WIDTH == 0) ? '0
                                             : h_start_id[ID_PORT_W-1:0];
        id_oh_q       <= (AXI_ID_WIDTH == 0)
                           ? NUM_IDS'(1)
                           : (NUM_IDS'(1) << h_start_id[ID_PORT_W-1:0]);
        data_q        <= cpq_head_word[IW_DATA_START_LSB +: 32];
        rem           <= cpq_head_word[IW_REPEAT_LSB     +: 12];
        last_txn_r    <= (cpq_head_word[IW_REPEAT_LSB +: 12] == 12'h000);
      end
      else if (txn_acc) begin
        addr_q     <= addr_next;
        id_q       <= id_next;
        id_oh_q    <= (AXI_ID_WIDTH == 0) ? NUM_IDS'(1)
                                          : (NUM_IDS'(1) << id_next);
        data_q     <= data_q + data_stride_q;
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
  // Response path.  Concurrent with the issue datapath.
  //
  //   T   : BVALID.
  //   T+1 : ring_dec / ring_dec_oh asserted; the ring attributes the response.
  //   T+2 : ring_dec_vld (the ring's own registered copy of dec) qualifies the
  //         ring's REGISTERED attribution result.
  //   T+3 : err_vld to the status array.
  //
  // err_axiid could come either from bid_q2 or from the ring's ring_dec_axiid
  // (the ring re-encoding its registered dec_oh).  They are identical by
  // construction, so bid_q2 is used because it costs zero extra logic and the
  // ring's copy can then be trimmed.
  //--------------------------------------------------------------------------
  logic [1:0]           bresp_q, bresp_q2;
  logic [ID_PORT_W-1:0] bid_q, bid_q2;

  // Every signal in this always_ff is unconditionally re-registered every
  // cycle from a combinational function of the AXI pins (or is a
  // default-then-override pulse: err_vld <= 0 unconditionally, then
  // conditionally set), so none of them needs a reset value - the first real
  // post-reset clock edge already produces a correct, real value regardless.
  always_ff @(posedge clk) begin
    // Stage A: register everything off the AXI pins.  The ID is decoded to a
    // one-hot HERE, at the source, so the ring never muxes by ID.
    ring_dec    <= m_axi_bvalid;
    ring_dec_oh <= m_axi_bvalid ? (NUM_IDS'(1) << m_axi_bid) : '0;
    bresp_q     <= m_axi_bresp;
    bid_q       <= m_axi_bid;

    // Stage B: the ring's registered attribution is now valid.
    bresp_q2    <= bresp_q;
    bid_q2      <= bid_q;

    err_vld     <= 1'b0;
    if (ring_dec_vld && ring_dec_hit && (bresp_q2 != RESP_OKAY)) begin
      err_vld    <= 1'b1;
      err_idx    <= ring_dec_cmd_idx;
      err_slverr <= (bresp_q2 == RESP_SLVERR);  // the only other is DECERR
      err_num    <= ring_dec_rsp_ord;           // PER-ID ordinal
      err_axiid  <= 4'(bid_q2);
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
  // Address / ID / data generation
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

  lfsr64 #(
    .GALOIS (LFSR64_GALOIS),
    .SEED   (LFSR64_SEED)
  ) i_lfsr64 (
    .clk    (clk),
    .rstn   (rstn),
    .adv    (lfsr64_adv),
    .state  (lfsr64_state)
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

  //--------------------------------------------------------------------------
  // BYTE-ENABLE PROBABILITY
  //
  // NOTE: WSTRB = '0 is IMPOSSIBLE here.  lfsr64 is a maximal-length LFSR, so
  // it never enters the all-zeros state -- there is always at least one byte
  // enabled.  WSTRB = '1 IS possible (it is one of the 2**64-1 legal LFSR
  // states) even though a full-width strobe is not really the intended result
  // of selecting partial byte enables.  Both facts are deliberate.
  //
  // be_prob_k is k, with n = 2**k. Every active write cycle samples k of the
  // 6 positions in BE_TAP_POS below; if ALL k sampled taps are zero
  // (probability 1/2**k) the strobe is the raw LFSR state, otherwise it is
  // all ones. be_prob_k = 7 is a special case, not k=7 of the tap pattern: it
  // forces WSTRB='1 unconditionally, i.e. "never generate a partial write".
  //
  // TAP POSITIONS: BE_TAP_POS is ONE constant, fixed set of 6 positions
  // (0 and 63 anchor the ends, 4 more roughly fill the middle) -- every
  // be_k_q level draws its taps as a subset of this same array rather than
  // inventing its own numbers, so there is exactly one place that defines
  // "where do we look." Lower-k subsets are only approximately, not
  // perfectly, evenly spaced as a result (e.g. k=3 uses positions 0/26/63,
  // not the ideal 0/31/63) -- acceptable for a traffic generator.
  //
  // SEED NOTE: this test is exactly why LFSR64_SEED must be a full-width
  // high-entropy constant and not merely non-zero.  A seed whose upper bits
  // are near zero leaves the high taps stuck at 0 for tens of thousands of
  // advances, which makes the "all taps zero" test fire far more often than
  // 1/2**k and skews the partial-write rate badly.
  //
  // The bridge picks its CPI memopcode with !(&s_axi_wstrb) ? MemWrPtl :
  // MemWrMem, so use_partial_be is exactly the "generate a MemWrPtl" knob.
  //--------------------------------------------------------------------------
  // Constant, shared pool of 6 tap positions across the 64-bit lfsr64 state.
  // Every be_k_q level below indexes into THIS array; none recompute their
  // own positions.
  localparam int BE_TAP_POS [6] = '{0, 13, 26, 38, 51, 63};

  logic use_partial_be;

  // Registered for timing.  This decouples the go-partial decision from the
  // lfsr64_state sample it actually masks: lfsr64_adv=w_acc advances the
  // LFSR every accepted beat, so on back-to-back beats (the steady-state
  // case) the decision here is one sample stale relative to the state
  // m_axi_wstrb/m_axi_wdata use below. That skew is accepted deliberately --
  // this is a traffic generator, not a precision statistics engine, and a
  // decision made off any pseudorandom sample of the same LFSR stream is as
  // good as one made off the exact sample it gates.
  always_ff @(posedge clk) begin
    // Special: '1 (3'd7) means NO BE
    use_partial_be <= 1'b0;
    // Else, 1/2^be_k_q probability of BE. Each case ORs together k of the
    // 6 fixed BE_TAP_POS entries (indices chosen per level below).
    case (be_k_q)
      3'd0    : use_partial_be <= 1'b1; // n=1 : always partial
      3'd1    : use_partial_be <= ~lfsr64_state[BE_TAP_POS[0]];
      3'd2    : use_partial_be <= ~(lfsr64_state[BE_TAP_POS[0]] |
                                    lfsr64_state[BE_TAP_POS[5]]);
      3'd3    : use_partial_be <= ~(lfsr64_state[BE_TAP_POS[0]] |
                                    lfsr64_state[BE_TAP_POS[2]] |
                                    lfsr64_state[BE_TAP_POS[5]]);
      3'd4    : use_partial_be <= ~(lfsr64_state[BE_TAP_POS[0]] |
                                    lfsr64_state[BE_TAP_POS[2]] |
                                    lfsr64_state[BE_TAP_POS[3]] |
                                    lfsr64_state[BE_TAP_POS[5]]);
      3'd5    : use_partial_be <= ~(lfsr64_state[BE_TAP_POS[0]] |
                                    lfsr64_state[BE_TAP_POS[1]] |
                                    lfsr64_state[BE_TAP_POS[2]] |
                                    lfsr64_state[BE_TAP_POS[3]] |
                                    lfsr64_state[BE_TAP_POS[5]]);
      3'd6    : use_partial_be <= ~(lfsr64_state[BE_TAP_POS[0]] |
                                    lfsr64_state[BE_TAP_POS[1]] |
                                    lfsr64_state[BE_TAP_POS[2]] |
                                    lfsr64_state[BE_TAP_POS[3]] |
                                    lfsr64_state[BE_TAP_POS[4]] |
                                    lfsr64_state[BE_TAP_POS[5]]);
    endcase
  end

  //--------------------------------------------------------------------------
  // WSTRB is the RAW lfsr64 state; WDATA uses the BIT-REVERSED state.
  // Without the reversal, byte lane i would be enabled by state[i] AND would
  // carry bits derived from state[i] -- so "a lane is enabled iff a bit of its
  // own content is set", which visibly distorts partial-write patterns.  With
  // the reversal, lane i is enabled by state[i] but carries bits derived from
  // state[63-i].
  //
  // HONEST CAVEAT (do not oversell this): the strobe and the data are still
  // two PERMUTATIONS OF THE SAME 64 BITS in the same cycle, so they are not
  // statistically independent -- popcount(WSTRB) and the popcount of the WDATA
  // pattern remain perfectly correlated.  The swizzle removes the POSITIONAL
  // correlation, which is the part that actually distorts partial writes.
  // True independence needs lfsr64 advanced twice per beat (once for data,
  // once for strobe) -- a two-line change if it is ever needed.
  //
  // bitrev is pure wiring - zero LUTs, zero delay.
  //--------------------------------------------------------------------------
  logic [63:0] lfsr64_rev;
  always_comb
    for (int i = 0; i < 64; i++)
      lfsr64_rev[i] = lfsr64_state[63-i];

  assign m_axi_wstrb = use_partial_be ? lfsr64_state : {64{1'b1}};
  assign m_axi_wdata = data_mode_q ? {8{lfsr64_rev}}    // LFSR: x8 replication
                                   : {16{data_q}};      // counter: x16

endmodule
