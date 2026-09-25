// MODULE : lfsr8
//
// DESCRIPTION:
// Fixed 8-bit maximal-length linear feedback shift register, used for AXI ID
// randomization.
//
// ACRONYMS:
//  - LFSR = linear feedback shift register
//  - adv  = advance (shift by one)
module lfsr8 #(
  parameter bit         GALOIS = 1'b1,  // 1=Galois 0=Fibonacci
  parameter logic [7:0] SEED   = 8'hB5  // non-zero, popcount 4
)(
  input              clk,
  input              rstn,
  input              adv,
  output logic [7:0] state
);

  // Maximal-length taps {8,6,5,4}; period 2**8-1 = 255
  localparam logic [7:0] POLY = 8'hB8;  // bits 7,5,4,3
  localparam int         N    = 8;

  // No need to control an initial state
  initial state <= SEED;

  always @(posedge clk) begin
    if (adv) begin
      if (GALOIS)
        state <= {1'b0, state[N-1:1]} ^ (state[0] ? POLY : '0);
      else
        state <= {state[N-2:0], ^(state & POLY)};
    end
  end

  `ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (SEED == '0)
      $fatal(1, "lfsr8: SEED must be non-zero (a zeroed LFSR is stuck)");
  end
  //synthesis on
  `endif

endmodule
