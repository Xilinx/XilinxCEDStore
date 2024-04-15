// This module reverses a word, nibble-by-nibble
module reverse #(
  parameter WIDTH=32
)(
  input      [WIDTH-1:0] din,
  output reg [WIDTH-1:0] dout
);

  integer ii;

  always @(*) begin
    for (ii=0; ii<WIDTH; ii=ii+4)
      dout[WIDTH-ii-4 +: 4] = din[ii +: 4];
  end

endmodule
