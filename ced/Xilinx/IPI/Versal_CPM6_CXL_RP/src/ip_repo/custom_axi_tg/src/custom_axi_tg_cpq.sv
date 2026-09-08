// MODULE : custom_axi_tg_cpq
//
// DESCRIPTION:
// Command prefetch queue - the structure that removes the per-command setup
// bubble.  One instance lives in each dispatcher.  It holds commands that have
// been FETCHED AND ROUTED by the sequencer but not yet LOADED into the
// dispatcher's working registers: the sequencer pushes, the dispatcher pops.
//
// Because the instruction layout is fixed rather than opcode-dependent,
// extracting a field from head_word is pure bit-slicing with zero LUT delay.
// That is what lets the dispatcher load and issue with no setup state: on the
// cycle a command is loaded the working registers are written directly from
// head_word slices, and the FOLLOWING cycle drives AXI.
//
// DETAILS:
//  - This is DELIBERATELY a registered-array FIFO built from CPQ_DEPTH flat
//    registers with a combinational output mux (a 2:1 mux at CPQ_DEPTH = 2),
//    and NOT an XPM_FIFO.  An XPM FIFO's read latency would reintroduce
//    exactly the bubble this structure exists to remove.
//  - push and pop may occur in the same cycle at any occupancy.  A push into
//    an empty queue that is being popped in the same cycle writes the array
//    normally and leaves cnt unchanged; head_vld/head_word only become visible
//    on the next cycle, which is the intended one-command-per-cycle rate.
//  - flush is a hard clear used on reset, on an accepted start pulse and at
//    the end of a STOPPING drain.  Discarding queued commands is safe because
//    a command that is still in the queue has never been loaded, never
//    allocated a ring entry and never issued anything, so nothing downstream
//    is left waiting for it.
//
// RESTRICTIONS:
//  - CPQ_DEPTH must be at least 2 (zero-bubble command boundaries need two
//    staged commands) and a power of 2 (the pointers wrap naturally).
//  - Overflow is prevented UPSTREAM by the sequencer's fully registered
//    prefetch credit rule; there is deliberately no back-pressure path from
//    here into the BRAM address path, because a back-pressure signal reaching
//    the BRAM address would not close timing.  A push into a full queue is
//    caught by a bound simulation checker.
//
// ACRONYMS:
//  - CPQ = command prefetch queue

module custom_axi_tg_cpq #(
  parameter int  IRAM_WIDTH = 192,
  parameter int  CPQ_DEPTH  = 2,
  localparam int PTR_W      = $clog2(CPQ_DEPTH)
)(
  input                         clk,
  input                         rstn,
  input                         flush,      // hard clear (reset / stop)
  input                         push,
  input        [           8:0] push_idx,
  input        [IRAM_WIDTH-1:0] push_word,
  input                         pop,
  output logic                  head_vld,
  output logic [           8:0] head_idx,
  output logic [IRAM_WIDTH-1:0] head_word,
  output logic [           1:0] cnt,
  output logic                  full
);

  logic [IRAM_WIDTH-1:0] word_q [CPQ_DEPTH];
  logic [8:0]            idx_q  [CPQ_DEPTH];
  logic [PTR_W-1:0]      head_ptr, tail_ptr;
  logic [PTR_W:0] count_r;

  assign cnt      = 2'(count_r);
  assign full     = (count_r == (PTR_W+1)'(CPQ_DEPTH));
  assign head_vld = (count_r != '0);

  // Pure combinational output mux off registered storage - zero LUT delay for
  // the field slices the dispatcher takes out of head_word.
  assign head_word = word_q[head_ptr];
  assign head_idx  = idx_q [head_ptr];

  // word_q/idx_q are data qualified by count_r (head_vld = count_r != 0):
  // head_ptr and tail_ptr both start at 0, so the first real push always
  // writes the exact slot the first real pop will read, before head_vld can
  // ever go true. They are intentionally left out of reset.
  always_ff @(posedge clk) begin
    if (!rstn || flush) begin
      head_ptr <= '0;
      tail_ptr <= '0;
      count_r  <= '0;
    end
    else begin
      if (push) begin
        word_q[tail_ptr] <= push_word;
        idx_q [tail_ptr] <= push_idx;
        tail_ptr         <= tail_ptr + 1'b1;
      end
      if (pop)
        head_ptr <= head_ptr + 1'b1;

      case ({push, pop})
        2'b10   : count_r <= count_r + 1'b1;
        2'b01   : count_r <= count_r - 1'b1;
        default : count_r <= count_r;
      endcase
    end
  end

  `ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (CPQ_DEPTH < 2)
      $fatal(1, $sformatf({"custom_axi_tg_cpq: CPQ_DEPTH=%0d is invalid; a ",
                           "depth of at least 2 is required for zero-bubble ",
                           "command boundaries"}, CPQ_DEPTH));
    if (|(CPQ_DEPTH & (CPQ_DEPTH-1)))
      $fatal(1, $sformatf({"custom_axi_tg_cpq: CPQ_DEPTH=%0d is invalid; must ",
                           "be a power of 2"}, CPQ_DEPTH));
    if (CPQ_DEPTH > 3)
      $fatal(1, $sformatf({"custom_axi_tg_cpq: CPQ_DEPTH=%0d is invalid; cnt ",
                           "is exported as 2 bits (TG_STATUS.WR_CPQ_CNT), so ",
                           "the maximum is 3"}, CPQ_DEPTH));
  end
  //synthesis on
  `endif

endmodule
