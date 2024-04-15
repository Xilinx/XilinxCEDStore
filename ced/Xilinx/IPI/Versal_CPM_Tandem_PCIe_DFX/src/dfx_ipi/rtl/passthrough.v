// This module wires out to in
module passthrough #(
  parameter WIDTH=32
)(
  input  [WIDTH-1:0] din,
  output [WIDTH-1:0] dout
);

  assign dout = din;

endmodule
