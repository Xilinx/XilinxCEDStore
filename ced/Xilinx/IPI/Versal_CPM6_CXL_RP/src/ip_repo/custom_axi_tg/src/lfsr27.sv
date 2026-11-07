// MODULE : lfsr27
//
// DESCRIPTION:
// 27-bit maximal-length linear feedback shift register.  It is the address
// source for addr[31:6] when addr_mode==1.
//
// ACRONYMS:
//  - LFSR = linear feedback shift register
//  - adv  = advance (shift by one)

module lfsr27 #(
  parameter bit          GALOIS = 1'b1,  // 1=Galois 0=Fibonacci
  parameter logic [26:0] SEED   = 27'h63779B9
)(
  input               clk,
  input               rstn,
  input               adv,
  output logic [26:0] state
);

  // Maximal-length taps {27,5,2,1}; period 2**27-1 = 134,217,727
  localparam logic [26:0] POLY = 27'h400_0013;     // bits 26,4,1,0
  localparam int          N    = 27;

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
      $fatal(1, "lfsr27: SEED must be non-zero (a zeroed LFSR is stuck)");
  end
  //synthesis on
  `endif

endmodule
