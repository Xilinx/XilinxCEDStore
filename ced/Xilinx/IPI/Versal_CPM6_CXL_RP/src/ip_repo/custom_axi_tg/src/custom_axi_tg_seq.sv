// MODULE : custom_axi_tg_seq
//
// DESCRIPTION:
// Fetch sequencer.  Owns the fetch pointer, the iRAM read, the opcode routing
// into the two command prefetch queues, the WAIT barrier, the exported run
// state and the stop/drain sequencing.
//
// Two co-operating pieces:
//  - run_state[2:0], the EXPORTED status.  Five states:
//    IDLE / IN_PROG / ALL_REQUESTED / ALL_RESPONDED / STOPPING.
//  - a PIPELINED FETCH ENGINE, not a state machine.  Fetch issues one iRAM
//    address per cycle subject to prefetch credit.  A per-command fetch state
//    machine would spend several cycles per command even when the dispatcher
//    is starving, which alone would make the zero-bubble requirement
//    unreachable.
//
// THERE IS NO LOOP CONSTRUCT: no back-edge, no iteration counter, no
// body-scoped drain.  A program is strictly the linear sequence
// [0, done_ptr-1] and executes EXACTLY ONCE per accepted start pulse.  Because
// of that, every status field is written at most once per run, which is what
// makes "first error in the run wins" free and what guarantees two ring
// entries never share a cmd_idx.
//
// DETAILS:
//  - Fetch pipeline.  Stage 0 presents the address (addrb changes EVERY cycle a
//    fetch issues), stage 1 is BRAM internal, stage 2 has doutb valid and
//    routes the word straight into a CPQ.  Total latency L = 3 cycles from
//    "fetch issued at cycle F" to "the command is the CPQ head and can be
//    LOADED at cycle F+3".
//  - Prefetch credit.  Conservative and FULLY REGISTERED: it assumes every
//    not-yet-landed fetch could turn out to target either CPQ.  Using the
//    registered CPQ counts rather than the post-pop counts keeps
//    m_axi_awready / m_axi_wready OUT of the BRAM address path, which matters
//    at 3.0 ns.  The cost of being conservative is that a run of three or more
//    1-transaction commands settles to about 0.5 txn/cycle.
//  - Same-type ordering needs no logic here: a dispatcher processes one
//    command at a time and load_new for the later command can only fire on the
//    cycle the earlier one rolls.
//  - WAIT is a GLOBAL drain (both CPQs empty, both dispatchers idle, both rings
//    empty).  Because a WAIT sits between two commands in program order, every
//    previously dispatched command is by definition "previous", so the global
//    drain is a correct - if stronger than literal - way to order it against
//    everything before it.
//  - OP_RSVD (2'b11) cannot be programmed (its commit is rejected with SLVERR),
//    but is routed to the WAIT path defensively: a barrier only drains and
//    cannot generate traffic, so it is the safe direction after a BRAM soft
//    error.
//  - STOP AND DRAIN.  stop_pulse does NOT flush anything.  It asserts the
//    level stop_req, which gates load_new in both dispatchers and lets each of
//    them complete the transaction it is currently offering.  Both rings, both
//    per-ID counter sets and the whole status array stay UNTOUCHED AND LIVE, so
//    responses keep being attributed during the drain and no orphan is
//    possible.  Only when the drain finishes does the state reach IDLE and the
//    CPQs get flushed - the commands they still hold were never loaded, never
//    allocated a ring entry and never issued anything.
//
// RESTRICTIONS:
//  - A start pulse is accepted only when run_state is IDLE or ALL_RESPONDED.
//    Those two states are exactly "nothing is outstanding", so no separate
//    outstanding counter is needed.  An internal (AXI-Lite) start while busy is
//    reported as SLVERR + ERR_START_BUSY by the CSR; the external pin has no
//    response channel, so it records itself in the sticky W1C start_busy_err
//    bit owned here.
//  - done_ptr == 0 means "no program": the start is accepted, nothing runs, and
//    the state stays IDLE.  That is NOT a busy error.
//
// ACRONYMS:
//  - CPQ  = command prefetch queue
//  - fv   = fetch-valid pipeline
//  - freq = fully_requested

module custom_axi_tg_seq
  import custom_axi_tg_pkg::*;
#(
  parameter int  MAX_COMMANDS = 32,
  parameter int  IRAM_WIDTH   = 192,
  parameter int  CPQ_DEPTH    = 2,
  // fetch_ptr settles AT done_ptr once a program finishes fetching, and
  // done_ptr can legally equal MAX_COMMANDS (one past the last valid index),
  // so cur_cmd_ptr needs one bit more than $clog2(MAX_COMMANDS) or that
  // terminal value aliases to 0 - indistinguishable from "on command 0".
  localparam int CMD_PTR_W    = $clog2(MAX_COMMANDS) + 1
)(
  input                         clk,
  input                         rstn,
  input                         start_pulse_int,     // from TG_CTRL.START = 1
  input                         start_pulse_ext,     // from the i_start pin
  input                         stop_pulse,          // from TG_CTRL.START = 0
  input                         start_busy_err_clr,
  input        [           9:0] done_ptr,
  // iRAM read port B (arbitrated against the CSR block, which owns it only
  // while run_state == IDLE, so there is never a real conflict)
  output logic                  iram_ren,
  output logic [           8:0] iram_raddr,
  input        [IRAM_WIDTH-1:0] iram_rdata,
  // command push into the per-dispatcher prefetch queues
  output logic                  wr_cpq_push,
  output logic                  rd_cpq_push,
  output logic [           8:0] cpq_push_idx,
  output logic [IRAM_WIDTH-1:0] cpq_push_word,
  input        [           1:0] wr_cpq_cnt,
  input        [           1:0] rd_cpq_cnt,
  // drain observation
  input                         wr_ring_empty,
  input                         rd_ring_empty,
  input                         wr_disp_busy,
  input                         rd_disp_busy,
  input                         wr_stop_done,
  input                         rd_stop_done,
  // stop / drain handshake to the dispatchers
  output logic                  stop_req,            // level: stop issuing
  output logic                  cpq_flush,           // clear both CPQs on stop
  // status array interface
  output logic                  clr_all,
  output logic [           8:0] q_idx,
  input                         q_programmed_valid,
  // status out
  output logic [           2:0] run_state,
  output logic [CMD_PTR_W-1:0]  cur_cmd_ptr,
  output logic                  start_busy_err       // sticky, W1C from the CSR
);

  //--------------------------------------------------------------------------
  // Fetch pipeline
  //--------------------------------------------------------------------------
  logic [9:0] fetch_ptr;  // next iRAM entry to fetch
  logic [1:0] fv;         // fv[0]: fetch issued last cycle
                                      // fv[1]: its data is on doutb NOW
  logic [8:0] fidx [2];               // index pipeline, parallel to fv
  logic       wait_pend;

  logic       fetch_issue, fetch_done, pipe_kill;
  logic [2:0] fetch_credit;
  logic       land, wait_land;
  logic [8:0] land_idx;
  logic [1:0] land_op;

  logic       start_busy, start_ok, start_accepted;
  logic       prog_drained_req, stop_drained, wait_clear;

  assign iram_ren   = fetch_issue;
  assign iram_raddr = fetch_ptr[8:0];
  assign fetch_done = (fetch_ptr >= done_ptr);

  // Credit rule:
  //   cpq_cnt[q] + (#fetches not yet landed) + 1 <= CPQ_DEPTH   for q in {wr,rd}
  // evaluated on registered values only and pessimistically assuming EVERY
  // in-flight fetch could target queue q.  A CPQ can therefore never overflow
  // no matter what mix of opcodes the in-flight fetches turn out to hold, and
  // no back-pressure path is needed from a CPQ back into the BRAM.
  assign fetch_credit = 3'd1 + {2'b0, fv[0]} + {2'b0, fv[1]};   // 1..3

  assign fetch_issue  = (run_state == ST_IN_PROG) && !wait_pend && !fetch_done &&
                        (({1'b0, wr_cpq_cnt} + fetch_credit) <= 3'(CPQ_DEPTH)) &&
                        (({1'b0, rd_cpq_cnt} + fetch_credit) <= 3'(CPQ_DEPTH));

  //--- landing / routing.  Everything here is a pure wire off doutb. ---------
  assign land          = fv[1];
  assign land_idx      = fidx[1];
  assign land_op       = iram_rdata[IW_OPCODE_LSB +: 2];

  assign cpq_push_idx  = land_idx;
  assign cpq_push_word = iram_rdata;
  assign wr_cpq_push   = land && (land_op == OP_WRITE);
  assign rd_cpq_push   = land && (land_op == OP_READ);
  assign wait_land     = land && ((land_op == OP_WAIT) || (land_op == OP_RSVD));

  assign cur_cmd_ptr   = fetch_ptr[CMD_PTR_W-1:0];
  assign q_idx         = land_idx;

  //--------------------------------------------------------------------------
  // Run-state conditions
  //--------------------------------------------------------------------------
  // "the program has issued everything it is ever going to issue".  The
  // (fv == '0) term is required, not redundant: without it, a two-command
  // program reaches fetch_done with both commands still in the fetch pipeline
  // and every other term already true, so the state would leave IN_PROG
  // before either command was ever loaded.
  assign prog_drained_req = fetch_done          && (fv == 2'b00) &&
                            !wait_pend          &&
                            (wr_cpq_cnt == '0)  && (rd_cpq_cnt == '0) &&
                            !wr_disp_busy       && !rd_disp_busy;

  // "everything that was issued has been answered"
  assign stop_drained     = wr_stop_done && rd_stop_done &&
                            wr_ring_empty && rd_ring_empty;

  // The WAIT barrier lifts on a GLOBAL drain.
  assign wait_clear       = (wr_cpq_cnt == '0) && (rd_cpq_cnt == '0) &&
                            !wr_disp_busy && !rd_disp_busy &&
                            wr_ring_empty && rd_ring_empty;

  assign start_busy       = (run_state != ST_IDLE) &&
                            (run_state != ST_ALL_RESPONDED);
  assign start_ok         = (start_pulse_int | start_pulse_ext) && !start_busy;
  assign start_accepted   = start_ok && (done_ptr != 10'h000);

  // pipe_kill discards fetches that are in flight but must not be delivered.
  assign pipe_kill        = start_accepted || wait_land ||
                            (stop_pulse && ((run_state == ST_IN_PROG) ||
                                            (run_state == ST_ALL_REQUESTED)));

  //--------------------------------------------------------------------------
  // Sequencer state
  //--------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rstn) begin
      run_state <= ST_IDLE;
      fetch_ptr <= 10'd0;
      fv        <= 2'b00;
      fidx[0]   <= 9'h000;
      fidx[1]   <= 9'h000;
      wait_pend <= 1'b0;
      stop_req  <= 1'b0;
      cpq_flush <= 1'b1;             // hold both CPQs clear out of reset
      // clr_all is a default-then-override pulse (unconditionally cleared
      // below, then conditionally set): its reset value is redundant and it
      // is intentionally left out of this branch.
    end
    else begin
      clr_all   <= 1'b0;
      cpq_flush <= 1'b0;

      //----------------------------------------------------------------------
      // Fetch pipeline
      //----------------------------------------------------------------------
      if (pipe_kill) begin
        fv <= 2'b00;
      end
      else begin
        fv[0] <= fetch_issue;
        fv[1] <= fv[0];
      end
      fidx[0] <= fetch_ptr[8:0];
      fidx[1] <= fidx[0];

      if (start_accepted)     fetch_ptr <= 10'd0;
      else if (wait_land)     fetch_ptr <= {1'b0, land_idx} + 10'd1;
      else if (fetch_issue)   fetch_ptr <= fetch_ptr + 10'd1;

      //----------------------------------------------------------------------
      // WAIT barrier.  A WAIT is discovered when it LANDS, by which time one or
      // two fetches behind it may already be in flight; those are discarded by
      // pipe_kill and re-fetched, which is free next to the drain itself.
      //----------------------------------------------------------------------
      if (wait_land)
        wait_pend <= 1'b1;
      else if (wait_pend && wait_clear)
        wait_pend <= 1'b0;

      //----------------------------------------------------------------------
      // Exported run state
      //----------------------------------------------------------------------
      case (run_state)
        ST_IDLE : begin
          // A start with done_ptr == 0 means "no program" and runs nothing,
          // but is NOT an error.
          if (start_accepted) begin
            run_state <= ST_IN_PROG;
            clr_all   <= 1'b1;
            wait_pend <= 1'b0;
            cpq_flush <= 1'b1;
          end
        end

        ST_IN_PROG : begin
          if (stop_pulse) begin
            run_state <= ST_STOPPING;
            stop_req  <= 1'b1;
          end
          else if (prog_drained_req) begin
            run_state <= ST_ALL_REQUESTED;
          end
        end

        ST_ALL_REQUESTED : begin
          // Occupied for at least one cycle even if every response is already
          // back, so it is always observable.
          if (stop_pulse) begin
            run_state <= ST_STOPPING;
            stop_req  <= 1'b1;
          end
          else if (wr_ring_empty && rd_ring_empty) begin
            run_state <= ST_ALL_RESPONDED;
          end
        end

        ST_ALL_RESPONDED : begin
          // Nothing is outstanding here, so a stop needs no drain at all.
          if (start_accepted) begin
            run_state <= ST_IN_PROG;
            clr_all   <= 1'b1;
            wait_pend <= 1'b0;
            cpq_flush <= 1'b1;
          end
          else if (stop_pulse) begin
            run_state <= ST_IDLE;
          end
        end

        ST_STOPPING : begin
          if (stop_drained) begin
            run_state <= ST_IDLE;
            stop_req  <= 1'b0;
            cpq_flush <= 1'b1;
            wait_pend <= 1'b0;
          end
        end

        default : run_state <= ST_IDLE;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // Start-while-busy for the EXTERNAL pin.  The pin has no response
  // channel, so a rising edge while run_state is not IDLE / ALL_RESPONDED is
  // dropped and records itself in this sticky W1C bit.  An INTERNAL start while
  // busy is reported on the AXI-Lite response channel instead (SLVERR +
  // ERR_START_BUSY) and deliberately does NOT set this bit, so software can
  // always tell the two sources apart.
  //--------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rstn)
      start_busy_err <= 1'b0;
    else if (start_busy_err_clr)
      start_busy_err <= 1'b0;
    else if (start_pulse_ext && start_busy)
      start_busy_err <= 1'b1;
  end

endmodule
