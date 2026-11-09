// MODULE : lfsr64
//
// DESCRIPTION:
// 64-bit maximal-length linear feedback shift register.  Used by
// custom_axi_tg_wr_disp as the single shared source for both the write data
// pattern (data_mode==1) and the write byte strobes (see the byte-enable
// probability logic in custom_axi_tg_wr_disp).
//
// ACRONYMS:
//  - LFSR = linear feedback shift register
//  - adv  = advance (shift by one)

module lfsr64 #(
  parameter bit          GALOIS = 1'b1, // 1=Galois 0=Fibonacci
  parameter logic [63:0] SEED   = 64'h9E37_79B9_7F4A_7C15
)(
  input               clk,
  input               rstn,
  input               adv,
  output logic [63:0] state
);

  // Maximal-length taps {64,63,61,60}
  localparam logic [63:0] POLY = 64'hD800_0000_0000_0000;
  localparam int          N    = 64;

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
      $fatal(1, $sformatf("lfsr64: SEED must be non-zero"));
  end
  //synthesis on
  `endif

endmodule
