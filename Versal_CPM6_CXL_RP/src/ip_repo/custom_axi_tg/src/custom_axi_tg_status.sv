// MODULE : custom_axi_tg_status
//
// DESCRIPTION:
// Per-command status flop array.  Only the immutable programmed command fields
// live in the iRAM BRAM; everything the hardware writes while a program runs
// lives here, in flops.  That split is what lets the SDPRAM keep a single write
// port (AXI-Lite only) and a single read port (fetch only) with no
// read-modify-write and no three-way arbitration - and it is what allows the
// fetch port to run free at one address per cycle.
//
// Two dispatcher-side writers plus the AXI-Lite reader are resolved with
// dedicated ports rather than a shared bus, so no writer ever has to read a
// field back before updating it.  The two dispatchers can never target the same
// index because a command is either a WRITE or a READ, never both.
//
// DETAILS:
//  - 21 bits per command:
//      fully_requested        1   set by a dispatcher off its `roll` pulse
//      fully_responded        1   set by a dispatcher when its ring entry retires
//      invalid_response_rcvd  1   set on the first non-OKAY response
//      is_slverr              1   SLVERR (1) vs DECERR (0) of that first error
//      first_invalid_number  12   PER-ID response ordinal of that error
//      first_invalid_axiid    4   AXI ID of that error
//      programmed_valid       1   set by the AXI-Lite commit
//  - clr_all is one cycle at start.  It clears everything EXCEPT
//    programmed_valid, for ALL entries at once - a flop array can be cleared
//    in a single cycle, where clearing status held in the iRAM would need a
//    walk over every entry.  It is registered one cycle ahead of use; the
//    sequencer spends that cycle presenting the very first iRAM fetch address,
//    so the extra cycle is free.
//  - There is no mid-run clear.  A program is strictly linear and runs exactly
//    once per start, so every status field is written at most once per run.
//    The rule "first error in the run wins" is therefore satisfied trivially
//    by the write-enable !invalid_response_rcvd[err_idx], with no
//    sticky-across-passes logic.
//  - programmed_valid is cleared by rstn, and also by prog_valid_clr_all - a
//    one-cycle pulse from the CSR's TG_CTRL.SOFT_RESET bit that clears every
//    entry at once so a new program can be loaded without a hard reset.
//    Shortening TG_DONE_PTR on its own must not destroy commands, so a
//    program can still be re-extended without reprogramming; it is only the
//    explicit soft reset that wipes the whole array.
//
// RESTRICTIONS:
//  - MAX_COMMANDS <= 512 (the iRAM depth).  Note that at 512 the head_cmd_freq
//    lookup becomes a 512:1 asynchronous mux inside the ring's retire path,
//    which is likely to need pipelining before it closes timing.
//
// ACRONYMS:
//  - freq  = fully_requested
//  - fresp = fully_responded

module custom_axi_tg_status #(
  parameter int  MAX_COMMANDS = 32,
  // Command indices arrive on 9-bit ports (the iRAM is 512 deep) but the array
  // is only MAX_COMMANDS entries, so they are truncated to IDX_W bits on the
  // way in.  Every read port is additionally range checked.
  localparam int IDX_W        = $clog2(MAX_COMMANDS)
)(
  input                    clk,
  input                    rstn,
  // whole-array clear on start (one cycle, not an iRAM walk)
  input                    clr_all,
  // dispatcher writes (write side)
  input                    wr_set_freq,   input [ 8:0] wr_freq_idx,
  input                    wr_set_fresp,  input [ 8:0] wr_fresp_idx,
  input                    wr_err_vld,    input [ 8:0] wr_err_idx,
  input                    wr_err_slverr, input [11:0] wr_err_num,
                                          input [3:0] wr_err_axiid,
  // dispatcher writes (read side)
  input                    rd_set_freq,   input [ 8:0] rd_freq_idx,
  input                    rd_set_fresp,  input [ 8:0] rd_fresp_idx,
  input                    rd_err_vld,    input [ 8:0] rd_err_idx,
  input                    rd_err_slverr, input [11:0] rd_err_num,
                                          input [3:0] rd_err_axiid,
  // programmed_valid (AXI-Lite commit; cleared by rstn or a soft reset)
  input                           prog_valid_set,
  input        [             8:0] prog_valid_idx,
  input                           prog_valid_clr_all,
  // combinational read port - AXI-Lite per-command status window
  input        [             8:0] rd_idx,
  output logic [            20:0] rd_data,
  // combinational query ports - ring retirement ("is the head's command
  // fully_requested yet?").  One per dispatcher.
  input        [             8:0] wr_q_idx,
  output logic                    wr_q_fully_requested,
  input        [             8:0] rd_q_idx,
  output logic                    rd_q_fully_requested,
  // combinational query port - sequencer (sim-only program legality check)
  input        [             8:0] q_idx,
  output logic                    q_programmed_valid,
  // debug / status
  output logic [MAX_COMMANDS-1:0] prog_valid_vec,
  output logic                    any_cmd_err
);

  logic [MAX_COMMANDS-1:0] fully_requested;
  logic [MAX_COMMANDS-1:0] fully_responded;
  logic [MAX_COMMANDS-1:0] invalid_response_rcvd;
  logic [MAX_COMMANDS-1:0] is_slverr;
  logic [MAX_COMMANDS-1:0] programmed_valid;
  logic [11:0]             first_invalid_number [MAX_COMMANDS];
  logic [ 3:0]             first_invalid_axiid  [MAX_COMMANDS];

  // clr_all fans out to 672 flops (21 x 32).  It is registered one cycle ahead
  // of use by the sequencer, so the extra cycle costs nothing, and
  // MAX_FANOUT asks Vivado to replicate the driver.
  (* MAX_FANOUT = 64 *) logic clr_all_q;

  always_ff @(posedge clk) begin
    if (!rstn)
      clr_all_q <= 1'b0;
    else
      clr_all_q <= clr_all;
  end

  always_ff @(posedge clk) begin
    if (!rstn) begin
      fully_requested       <= '0;
      fully_responded       <= '0;
      invalid_response_rcvd <= '0;
      is_slverr             <= '0;
      programmed_valid      <= '0;
      for (int i = 0; i < MAX_COMMANDS; i++) begin
        first_invalid_number[i] <= 12'h000;
        first_invalid_axiid [i] <= 4'h0;
      end
    end
    else begin
      //--- clear -------------------------------------------------------------
      if (clr_all_q) begin
        fully_requested       <= '0;
        fully_responded       <= '0;
        invalid_response_rcvd <= '0;
        is_slverr             <= '0;
        for (int i = 0; i < MAX_COMMANDS; i++) begin
          first_invalid_number[i] <= 12'h000;
          first_invalid_axiid [i] <= 4'h0;
        end
      end

      //--- sets (written after the clear so a set always wins at its index) ---
      if (wr_set_freq)
        fully_requested[wr_freq_idx[IDX_W-1:0]]  <= 1'b1;
      if (rd_set_freq)
        fully_requested[rd_freq_idx[IDX_W-1:0]]  <= 1'b1;
      if (wr_set_fresp)
        fully_responded[wr_fresp_idx[IDX_W-1:0]] <= 1'b1;
      if (rd_set_fresp)
        fully_responded[rd_fresp_idx[IDX_W-1:0]] <= 1'b1;

      // First error in the run wins.  Because a linear program runs exactly
      // once, "first error in the run" == "first error for this command", so
      // the write-enable alone gives the sticky behaviour.
      if (wr_err_vld && !invalid_response_rcvd[wr_err_idx[IDX_W-1:0]]) begin
        invalid_response_rcvd[wr_err_idx[IDX_W-1:0]] <= 1'b1;
        is_slverr            [wr_err_idx[IDX_W-1:0]] <= wr_err_slverr;
        first_invalid_number [wr_err_idx[IDX_W-1:0]] <= wr_err_num;
        first_invalid_axiid  [wr_err_idx[IDX_W-1:0]] <= wr_err_axiid;
      end
      if (rd_err_vld && !invalid_response_rcvd[rd_err_idx[IDX_W-1:0]]) begin
        invalid_response_rcvd[rd_err_idx[IDX_W-1:0]] <= 1'b1;
        is_slverr            [rd_err_idx[IDX_W-1:0]] <= rd_err_slverr;
        first_invalid_number [rd_err_idx[IDX_W-1:0]] <= rd_err_num;
        first_invalid_axiid  [rd_err_idx[IDX_W-1:0]] <= rd_err_axiid;
      end

      // programmed_valid is outside clr_all, so shortening TG_DONE_PTR alone
      // does not destroy already-programmed commands.  prog_valid_clr_all is
      // the explicit exception: a whole-array wipe from TG_CTRL.SOFT_RESET.
      // The two can never fire in the same cycle (they are driven by CSR
      // writes to different addresses, and the regbus is single-outstanding),
      // so the order between them here is not load-bearing.
      if (prog_valid_clr_all)
        programmed_valid <= '0;
      if (prog_valid_set)
        programmed_valid[prog_valid_idx[IDX_W-1:0]] <= 1'b1;
    end
  end

  //--- read / query ports ---------------------------------------------------
  logic in_range_rd, in_range_q, in_range_wq, in_range_rq;
  assign in_range_rd = (rd_idx   < 9'(MAX_COMMANDS));
  assign in_range_q  = (q_idx    < 9'(MAX_COMMANDS));
  assign in_range_wq = (wr_q_idx < 9'(MAX_COMMANDS));
  assign in_range_rq = (rd_q_idx < 9'(MAX_COMMANDS));

  always_comb begin
    rd_data = 21'h0;
    if (in_range_rd)
      rd_data = {first_invalid_axiid   [rd_idx[IDX_W-1:0]],   // [20:17]
                 first_invalid_number  [rd_idx[IDX_W-1:0]],   // [16: 5]
                 programmed_valid      [rd_idx[IDX_W-1:0]],   // [4]
                 is_slverr             [rd_idx[IDX_W-1:0]],   // [3]
                 invalid_response_rcvd [rd_idx[IDX_W-1:0]],   // [2]
                 fully_responded       [rd_idx[IDX_W-1:0]],   // [1]
                 fully_requested       [rd_idx[IDX_W-1:0]]};  // [0]
  end

  assign q_programmed_valid   = in_range_q &&
                                programmed_valid[q_idx[IDX_W-1:0]];
  assign wr_q_fully_requested = in_range_wq &&
                                fully_requested[wr_q_idx[IDX_W-1:0]];
  assign rd_q_fully_requested = in_range_rq &&
                                fully_requested[rd_q_idx[IDX_W-1:0]];

  assign prog_valid_vec       = programmed_valid;
  assign any_cmd_err          = |invalid_response_rcvd;

  `ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (MAX_COMMANDS > 512)
      $fatal(1, $sformatf({"custom_axi_tg_status: MAX_COMMANDS=%0d is invalid; ",
                           "maximum is 512 (BRAM depth)"}, MAX_COMMANDS));
    if (MAX_COMMANDS < 2)
      $fatal(1, $sformatf({"custom_axi_tg_status: MAX_COMMANDS=%0d is invalid; ",
                           "minimum is 2"}, MAX_COMMANDS));
  end
  //synthesis on
  `endif

endmodule
