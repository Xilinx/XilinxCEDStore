`timescale 1 ps / 1 ps

module h2c_slice #
  (
   parameter PATT_WIDTH = 8
   )
   (input [PATT_WIDTH-1:0] data_in,
    input tkeep,
    input [PATT_WIDTH-1:0] value,
    output wire cmp
    );
//wire cmp;
assign cmp = tkeep ? (data_in == value) : 1;

endmodule