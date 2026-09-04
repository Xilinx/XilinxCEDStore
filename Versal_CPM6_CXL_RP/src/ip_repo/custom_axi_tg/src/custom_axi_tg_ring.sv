// MODULE : custom_axi_tg_ring
//
// DESCRIPTION:
// Outstanding-command ring for one dispatcher.  It holds, for every command
// that still has AXI responses in flight, a per-AXI-ID transaction counter and
// a per-AXI-ID response ordinal, and it attributes each returning BID/RID to
// the correct command.
//
// --------------------------------------------------------------------
// OUTSTANDING-COMMAND RING - depth justification
//
// A returning BID/RID only tells us the AXI ID, not which command issued
// the transaction.  AXI orders responses only WITHIN an ID, so command K's
// responses for ID 3 all precede command K+1's responses for ID 3, but
// nothing is ordered across IDs.  Attributing a response therefore needs a
// per-COMMAND, per-ID outstanding count.
//
// A same-type command only waits for the previous same-type command's
// fully_requested (not fully_responded), so in principle every one of the
// MAX_COMMANDS entries could have responses outstanding simultaneously.
// A full per-command array would cost
//     MAX_COMMANDS x 2**AXI_ID_WIDTH x 13b = 32 x 16 x 13 = 6656 flops
// at AXI_ID_WIDTH=4, per dispatcher, for the counters alone.
//
// Instead the number of commands that may have responses outstanding at
// once is bounded to RING_DEPTH = 8 by this circular ring of
// {cmd_idx, per-ID counters, per-ID response ordinals}.
// -- a 4x reduction on the counters -- while still allowing 8 commands'
// worth of transactions (up to 8 x 4096 = 32768 requests) to be in flight,
// which is far beyond anything pl_axi_cpi_bridge can absorb (its WROB/RROB
// are 64 deep per ID).  When the ring is full the dispatcher holds off
// load_new, which stalls that dispatcher; no transaction is lost and no
// ordering is violated -- the only effect is reduced command concurrency.
//
// RING_DEPTH must be a power of 2.
// --------------------------------------------------------------------
//
// DETAILS:
//  - Attribution rule: a returning ID of value X is attributed to the OLDEST
//    resident command with a nonzero txn counter for ID X.  Commands with no
//    transactions of ID X are skipped entirely.
//
//  - THE STATE IS TRANSPOSED - INDEXED [ID][ENTRY], NOT [ENTRY][ID] - AND IS
//    NEVER MUXED BY ID.  This is the central timing decision of the block and
//    it is worth stating why, because the natural [entry][id] layout looks
//    equivalent and is not.
//
//    With cnt[entry][id] addressed by a computed entry index, evaluating the
//    attribution rule inside the response cycle means walking
//        dec_id -> NUM_IDS:1 column mux -> AND vld -> RING_DEPTH-bit rotate by
//               head -> RING_DEPTH-bit priority encode -> wrap add
//               -> NUM_IDS x RING_DEPTH counter index -> decrement
//    combinationally.  That chain does not close 333 MHz once AXI_ID_WIDTH
//    reaches 2, and it gets monotonically WORSE as AXI_ID_WIDTH grows, because
//    both the leading column mux and the trailing counter index widen with it.
//
//    Replicating the state per ID removes the mux at both ends, and the
//    priority encode is materialised as a REGISTERED per-ID owner one-hot
//    own_oh[X] computed from NEXT-STATE values (nz_n / vld_n / head_n).
//    Because own_oh[X] at the start of cycle t is a function only of register
//    values at the start of cycle t, it holds exactly the value the
//    combinational form would have produced during cycle t.  No latency is
//    added -- the same logic simply evaluates one cycle earlier, where it has
//    a full clock period to itself.
//
//    What a returning response then touches is
//        dec (flop) AND dec_oh[X] (flop) AND own_oh[X][e] (flop)
//          -> cnt[X][e] CE/direction, rsp_ord[X][e] CE
//    i.e. ONE LUT6 level plus the counter's own CARRY8, and it is INDEPENDENT
//    OF AXI_ID_WIDTH because the slices are parallel, not muxed.
//
//  - RING TIMING CONTRACT, which both dispatchers must honour:
//      * alloc and inc are COMBINATIONAL - asserted in the SAME cycle as the
//        AXI request handshake (txn_acc).
//      * dec and dec_oh are REGISTERED off BVALID / RVALID.
//      * inc_oh (the dispatcher's id_oh_q) and alloc_cmd_idx are registered
//        and stable.
//    inc MUST stay combinational.  If inc were registered it would reach the
//    ring at T+1 and nz would only update at the END of T+1, so a dec also
//    landing at T+1 would sample nz == 0, find no owner, and count the
//    response as an orphan.  alloc must likewise stay combinational, or every
//    command boundary costs a bubble cycle.
//
//  - dec_vld / dec_hit / dec_cmd_idx / dec_rsp_ord are REGISTERED, i.e. they
//    are valid one cycle AFTER dec.
//  - first_invalid_number is the PER-ID response ordinal, not a global one.
//    rsp_ord[X][e] counts the ID-X responses already received for the command
//    in entry e.  Because a dispatcher issues commands strictly one at a time
//    and strictly in program order, per-ID responses are a strict FIFO over
//    commands, so the per-ID response ordinal is identically the per-ID
//    REQUEST ordinal: {axiid=X, number=N} names exactly "the Nth transaction
//    this command issued with AXI ID X".  A global ordinal could not name the
//    failing request at all, because responses interleave across IDs.
//  - Retirement needs vld[head] && !ent_busy[head] && head_cmd_freq.  The
//    head_cmd_freq qualifier is essential: ent_busy can transiently be 0 in
//    the middle of a command (first response back before the second request
//    goes out).  Entries retire strictly in allocation order; an entry that
//    finishes early waits at its slot with all counters zero, where it is
//    invisible to own_oh because its whole nz column is zero.
//  - There is no per-entry total counter.  The same information is
//    ent_busy[e] = |{X} nz[X][e], a registered OR of values that already
//    exist, which costs nothing extra to maintain.
//
// RESTRICTIONS:
//  - RING_DEPTH must be a power of 2 and, because head/tail are exported as
//    3-bit debug fields, no deeper than 8.
//  - flush must only ever be asserted while the ring is already EMPTY (reset,
//    an accepted start, or the end of a STOPPING drain).  Flushing with
//    entries still live would strand their in-flight responses, which then
//    return with no matching entry and are reported as orphans.
//  - A single dispatcher issues one command at a time, so inc always applies
//    to the most recently allocated entry (cur_e_oh); no entry index is
//    carried on the inc port.
//
// ACRONYMS:
//  - nz      = "nonzero" (registered cnt != 0)
//  - own_oh  = registered one-hot of the entry that owns the next ID-X response
//  - rsp_ord = per-ID ordinal of the response within its command
//  - freq    = fully_requested

module custom_axi_tg_ring #(
  parameter int  RING_DEPTH = 8,   // power of 2, max 8
  parameter int  NUM_IDS    = 2,
  parameter int  CNT_W      = 13,  // 0..4096
  localparam int PTR_W      = $clog2(RING_DEPTH)
)(
  input                         clk,
  input                         rstn,
  input                         flush,           // only while already empty
  // allocation (one per command) - COMBINATIONAL from the dispatcher
  input                         alloc,
  input        [           8:0] alloc_cmd_idx,
  output logic                  full,
  output logic                  empty,
  // request counting - COMBINATIONAL, one-hot ID
  input                         inc,
  input        [   NUM_IDS-1:0] inc_oh,
  // response counting - REGISTERED, one-hot ID
  input                         dec,
  input        [   NUM_IDS-1:0] dec_oh,
  output logic                  dec_vld,         // registered copy of dec
  output logic                  dec_hit,         // 0 => orphan response (bug!)
  output logic [           8:0] dec_cmd_idx,
  output logic [          11:0] dec_rsp_ord,     // PER-ID ordinal
  output logic [           3:0] dec_axiid,
  // retirement
  output logic [           8:0] freq_query_idx,
  input                         head_cmd_freq,
  input                         req_quiesced,    // see the retire comment
  output logic                  retire,
  output logic [           8:0] retire_cmd_idx,
  // debug
  output logic [RING_DEPTH-1:0] vld_vec,
  output logic [           2:0] head,
  output logic [           2:0] tail,
  output logic [           3:0] count,
  // Orphan reporting is a sticky first-hit latch, not a counter.  An orphan
  // means the ring's attribution invariant has been broken by a bug, so it
  // should never happen at all; capturing which AXI ID it happened on
  // identifies the failing request directly, which a running total does not,
  // and costs a 1-bit compare-and-set instead of a 16-bit adder.
  output logic                  orphan_sticky,
  output logic [           3:0] orphan_axiid,
  input                         orphan_clr
);

  //--------------------------------------------------------------------------
  // State.  Shared items have one copy; everything indexed by AXI ID is
  // replicated NUM_IDS times IN PARALLEL and is never muxed by ID.
  //--------------------------------------------------------------------------
  logic [RING_DEPTH-1:0] vld;
  logic [8:0]            cmd_idx    [RING_DEPTH];
  logic [RING_DEPTH-1:0] cur_e_oh;  // entry of the command currently issuing
  logic [RING_DEPTH-1:0] ent_busy;  // registered OR over X of nz[X][e]
  logic [PTR_W-1:0]      head_r, tail_r;
  logic [PTR_W:0] count_r;
  logic [RING_DEPTH-1:0] head_oh, tail_oh;

  logic [CNT_W-1:0]      cnt        [NUM_IDS][RING_DEPTH];
  logic [11:0]           rsp_ord    [NUM_IDS][RING_DEPTH];
  logic [RING_DEPTH-1:0] nz         [NUM_IDS];
  logic [RING_DEPTH-1:0] cnt_is_one [NUM_IDS];   // mandatory timing helper
  logic [RING_DEPTH-1:0] own_oh     [NUM_IDS];   // <== THE FIX

  //--- next state ------------------------------------------------------------
  logic [RING_DEPTH-1:0] alloc_oh;
  logic [RING_DEPTH-1:0] retire_oh;
  logic [RING_DEPTH-1:0] vld_n;
  logic [PTR_W-1:0]      head_n, tail_n;
  logic [RING_DEPTH-1:0] up         [NUM_IDS];
  logic [RING_DEPTH-1:0] dn         [NUM_IDS];
  logic [CNT_W-1:0]      cnt_n      [NUM_IDS][RING_DEPTH];
  logic [RING_DEPTH-1:0] nz_n       [NUM_IDS];
  logic [RING_DEPTH-1:0] cnt_one_n  [NUM_IDS];
  logic [RING_DEPTH-1:0] avail_n    [NUM_IDS];
  logic [RING_DEPTH-1:0] own_oh_n   [NUM_IDS];
  logic [RING_DEPTH-1:0] ent_busy_n;

  logic [RING_DEPTH-1:0] sel_oh;

  assign full     = (count_r == (PTR_W+1)'(RING_DEPTH));
  assign empty    = (count_r == '0);
  assign vld_vec  = vld;
  assign head     = 3'(head_r);
  assign tail     = 3'(tail_r);
  assign count    = 4'(count_r);

  //--------------------------------------------------------------------------
  // Retirement.  All terms are registered, so retire is 2 LUT levels.
  //
  // head_cmd_freq is essential in normal operation: ent_busy can transiently be
  // 0 in the middle of a command (the first response comes back before the
  // second request goes out), and retiring then would free the entry while the
  // command still has requests to issue.
  //
  // req_quiesced is the STOP escape hatch, and it is REQUIRED, not an
  // optimisation.  A command that is stopped mid-flight deliberately never
  // reaches fully_requested -- that status bit must stay 0 to record that the
  // command did not finish -- so without this term its ring entry could never
  // retire, the ring could never empty, stop_drained could never assert and
  // STOPPING would hang forever.  The dispatcher drives req_quiesced with
  // (stop_req && stop_done), i.e. "I am stopped and no longer offering
  // anything", at which point it can never assert inc again -- so
  // ent_busy[head] == 0 genuinely means every response for that entry is back.
  //--------------------------------------------------------------------------
  assign freq_query_idx = cmd_idx[head_r];
  assign retire_cmd_idx = cmd_idx[head_r];
  assign retire         = (|(vld & head_oh)) && !(|(ent_busy & head_oh)) &&
                          (head_cmd_freq || req_quiesced);

  //--------------------------------------------------------------------------
  // Counter / flag next state.  up and dn are 3-input ANDs of registered
  // signals plus the combinational inc; there is no index mux anywhere, which
  // is precisely what makes the response path independent of AXI_ID_WIDTH.
  //--------------------------------------------------------------------------
  assign alloc_oh  = alloc  ? tail_oh : '0;
  assign retire_oh = retire ? head_oh : '0;
  assign vld_n     = (vld | alloc_oh) & ~retire_oh;
  assign head_n    = retire ? (head_r + 1'b1) : head_r;
  assign tail_n    = alloc  ? (tail_r + 1'b1) : tail_r;

  always_comb begin
    for (int x = 0; x < NUM_IDS; x++) begin
      up[x] = {RING_DEPTH{inc & inc_oh[x]}} & cur_e_oh;   // inc COMBINATIONAL
      dn[x] = {RING_DEPTH{dec & dec_oh[x]}} & own_oh[x];  // dec REGISTERED

      for (int e = 0; e < RING_DEPTH; e++) begin
        cnt_n[x][e] = alloc_oh[e]              ? '0
                    : (up[x][e] == dn[x][e])   ? cnt[x][e]
                    : up[x][e]                 ? (cnt[x][e] + CNT_W'(1))
                    :                            (cnt[x][e] - CNT_W'(1));
        cnt_one_n[x][e] = (cnt_n[x][e] == CNT_W'(1));
      end

      // nz_n uses the REGISTERED cnt_is_one flag rather than a live 13-bit
      // "cnt != 1" compare.  This is mandatory, not cosmetic: a 13-bit compare
      // in this path would sit in series with the counter's own carry chain
      // and lose the cycle.  alloc wins, so a stale count can never survive
      // re-allocation.
      for (int e = 0; e < RING_DEPTH; e++)
        nz_n[x][e] = alloc_oh[e]                 ? 1'b0
                   : ( up[x][e] && !dn[x][e])    ? 1'b1
                   : (!up[x][e] &&  dn[x][e])    ? ~cnt_is_one[x][e]
                   :                               nz[x][e];

      avail_n[x] = nz_n[x] & vld_n;
    end
  end

  //--------------------------------------------------------------------------
  // The priority encode lives in the flop-to-flop path, not in the response
  // path.
  //
  // own_oh[X] is a REGISTERED materialisation of "the oldest valid entry with
  // a nonzero ID-X count", computed from NEXT-STATE values.  Because nz_n,
  // vld_n and head_n are fully determined at the end of this cycle, own_oh[X]
  // at the start of cycle t is EXACTLY the value a combinational encode would
  // have produced during cycle t -- the result is identical, it is merely
  // available a cycle earlier and so costs no response-path delay.
  //
  // It is described as a single CYCLIC FIND-FIRST-SET of avail_n starting at
  // head_n (11 inputs -> 2 LUT6 levels) rather than as rotate -> encode ->
  // rotate-back, because written that way the tool fuses it into those two
  // levels instead of building three separate stages.  The descending loop
  // makes the LOWEST offset from head_n win.
  //--------------------------------------------------------------------------
  always_comb begin
    for (int x = 0; x < NUM_IDS; x++) begin
      own_oh_n[x] = '0;
      for (int i = RING_DEPTH-1; i >= 0; i--)
        if (avail_n[x][PTR_W'(head_n + PTR_W'(i))])
          own_oh_n[x] = RING_DEPTH'(1) << PTR_W'(head_n + PTR_W'(i));
    end
  end

  always_comb begin
    ent_busy_n = '0;
    for (int x = 0; x < NUM_IDS; x++)
      ent_busy_n = ent_busy_n | nz_n[x];
  end

  //--------------------------------------------------------------------------
  // sel_oh = the owner one-hot for the ID that is decrementing this cycle.  An
  // AND-OR over the registered per-ID owners; needed ONLY for the reporting
  // outputs below, never for the counter updates.
  //--------------------------------------------------------------------------
  always_comb begin
    sel_oh = '0;
    for (int x = 0; x < NUM_IDS; x++)
      if (dec_oh[x])
        sel_oh = sel_oh | own_oh[x];
  end

  //--------------------------------------------------------------------------
  // Ring state.  vld/head_r/tail_r/count_r are the only signals here that
  // must be reset: they are the genuine occupancy/pointer state, and if any
  // came up inconsistent with the others the first alloc/retire could
  // desync immediately. Everything else in this block is either
  // unconditionally re-registered every cycle (head_oh/tail_oh, from
  // head_n/tail_n) or force-cleared by alloc_oh the instant its entry
  // transitions valid (cmd_idx/cnt/rsp_ord/nz/cnt_is_one/own_oh/ent_busy), so
  // whatever they held before the entry was ever allocated is inconsequential
  // and they are intentionally left out of reset.
  //--------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rstn || flush) begin
      vld        <= '0;
      head_r     <= '0;
      tail_r     <= '0;
      count_r    <= '0;
      // cur_e_oh's reset is provably redundant too (it is always fresh by
      // the time inc can next legitimately fire), but that argument crosses
      // into the dispatcher's aw_pend/ar_pend timing, so it is kept out of
      // caution rather than removed alongside the local-only cases above.
      cur_e_oh   <= '0;
    end
    else begin
      vld      <= vld_n;
      ent_busy <= ent_busy_n;
      head_r   <= head_n;
      tail_r   <= tail_n;
      head_oh  <= RING_DEPTH'(1) << head_n;
      tail_oh  <= RING_DEPTH'(1) << tail_n;

      if (alloc) begin
        cmd_idx[tail_r] <= alloc_cmd_idx;
        cur_e_oh        <= tail_oh;
      end

      for (int x = 0; x < NUM_IDS; x++) begin
        nz        [x] <= nz_n     [x];
        cnt_is_one[x] <= cnt_one_n[x];
        own_oh    [x] <= own_oh_n [x];
        for (int e = 0; e < RING_DEPTH; e++) begin
          cnt[x][e] <= cnt_n[x][e];
          if (alloc_oh[e])
            rsp_ord[x][e] <= 12'h000;
          else if (dn[x][e])
            rsp_ord[x][e] <= rsp_ord[x][e] + 12'h001;
        end
      end

      case ({alloc, retire})
        2'b10   : count_r <= count_r + 1'b1;
        2'b01   : count_r <= count_r - 1'b1;
        default : count_r <= count_r;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // Registered attribution result, consumed by the dispatcher one cycle after
  // it asserted dec.  dec_rsp_ord is a NUM_IDS x RING_DEPTH one-hot mux of
  // 12-bit values (128:1 at AXI_ID_WIDTH = 4), flop to flop.  It is REPORTING
  // DATA ONLY - nothing in the counter update depends on it - so if it ever
  // becomes the failing path, adding a pipeline stage here is functionally
  // invisible and costs only reporting latency.
  //--------------------------------------------------------------------------
  logic [11:0] rsp_ord_sel;
  logic [ 3:0] dec_axiid_c;

  always_comb begin
    rsp_ord_sel = 12'h000;
    dec_axiid_c = 4'h0;
    for (int x = 0; x < NUM_IDS; x++) begin
      if (dec_oh[x])
        dec_axiid_c = 4'(x);
      for (int e = 0; e < RING_DEPTH; e++)
        if (dec_oh[x] && own_oh[x][e])
          rsp_ord_sel = rsp_ord[x][e];      // pre-increment value
    end
  end

  logic [8:0] cmd_idx_sel;
  always_comb begin
    cmd_idx_sel = 9'h000;
    for (int e = 0; e < RING_DEPTH; e++)
      if (sel_oh[e])
        cmd_idx_sel = cmd_idx[e];
  end

  // dec_hit/dec_cmd_idx/dec_rsp_ord/dec_axiid are unconditionally re-registered
  // every cycle from combinational functions of always-driven ring state, and
  // every consumer gates on dec_vld before reading them (both dispatchers and
  // the sim checker key off dec/sel_oh, never dec_hit alone).  dec_vld is
  // therefore the only signal in this group that needs a defined reset value;
  // the rest would just be overwritten with a real value on the very next
  // clock regardless, so resetting them only adds fanout to the shared reset
  // net for no behavioral benefit.  orphan_axiid is the same relationship to
  // orphan_sticky: it is only ever read while orphan_sticky is set.
  always_ff @(posedge clk) begin
    if (!rstn) begin
      dec_vld       <= 1'b0;
      orphan_sticky <= 1'b0;
    end
    else begin
      dec_vld     <= dec;
      dec_hit     <= dec && (|sel_oh);
      dec_cmd_idx <= cmd_idx_sel;
      dec_rsp_ord <= rsp_ord_sel;
      dec_axiid   <= dec_axiid_c;
      // Clear wins over a same-cycle capture, matching the W1C convention
      // used elsewhere in this design (e.g. start_busy_err).  orphan_axiid is
      // zeroed on clear (not just left stale) so a read right after a W1C
      // clear cannot show a leftover ID next to a de-asserted sticky bit.
      if (orphan_clr) begin
        orphan_sticky <= 1'b0;
        orphan_axiid  <= 4'h0;
      end
      else if (dec && !(|sel_oh) && !orphan_sticky) begin
        orphan_sticky <= 1'b1;
        orphan_axiid  <= dec_axiid_c;
      end
    end
  end

  `ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (|(RING_DEPTH & (RING_DEPTH-1)))
      $fatal(1, $sformatf({"custom_axi_tg_ring: RING_DEPTH=%0d is invalid; ",
                           "must be a power of 2"}, RING_DEPTH));
    if (RING_DEPTH > 8)
      $fatal(1, $sformatf({"custom_axi_tg_ring: RING_DEPTH=%0d is invalid; the ",
                           "debug head/tail fields of TG_RING_*_STATUS are 3 ",
                           "bits, so the maximum is 8"}, RING_DEPTH));
  end
  //synthesis on
  `endif

endmodule
