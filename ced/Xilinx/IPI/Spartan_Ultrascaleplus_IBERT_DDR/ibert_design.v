`define C_NUM_GTH_QUADS 2
`define C_GTH_REFCLKS_USED 1
module example_ibert_ultrascale_gth_0
(
  // GT top level ports
  output [(4*`C_NUM_GTH_QUADS)-1:0]		gth_txn_o,
  output [(4*`C_NUM_GTH_QUADS)-1:0]		gth_txp_o,
  input  [(4*`C_NUM_GTH_QUADS)-1:0]    	gth_rxn_i,
  input  [(4*`C_NUM_GTH_QUADS)-1:0]   	gth_rxp_i,
  input                           	gth_sysclkp_i,
  input                           	gth_sysclkn_i,
  input  [`C_GTH_REFCLKS_USED-1:0]      gth_refclk0p_i,
  input  [`C_GTH_REFCLKS_USED-1:0]      gth_refclk0n_i,
  input  [`C_GTH_REFCLKS_USED-1:0]      gth_refclk1p_i,
  input  [`C_GTH_REFCLKS_USED-1:0]      gth_refclk1n_i,
  output                            sys_clock_out
);

  //
  // Ibert refclk internal signals
  //
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qrefclk0_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qrefclk1_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qnorthrefclk0_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qnorthrefclk1_i;        	
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qsouthrefclk0_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qsouthrefclk1_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qrefclk00_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qrefclk10_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qrefclk01_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qrefclk11_i;  
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qnorthrefclk00_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qnorthrefclk10_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qnorthrefclk01_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qnorthrefclk11_i;  
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qsouthrefclk00_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qsouthrefclk10_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qsouthrefclk01_i;
  wire  [`C_NUM_GTH_QUADS-1:0]    gth_qsouthrefclk11_i; 
  wire  [`C_GTH_REFCLKS_USED-1:0] gth_refclk0_i;
  wire  [`C_GTH_REFCLKS_USED-1:0] gth_refclk1_i;
  wire  [`C_GTH_REFCLKS_USED-1:0] gth_odiv2_0_i;
  wire  [`C_GTH_REFCLKS_USED-1:0] gth_odiv2_1_i;
  wire                        gth_sysclk_i;
  wire                        gth_sysclk_i_buf;


  //
  // Refclk IBUFDS instantiations
  //
    IBUFDS_GTE4 u_buf_gth_q1_clk0
      (
        .O            (gth_refclk0_i[0]),
        .ODIV2        (gth_odiv2_0_i[0]),
        .CEB          (1'b0),
        .I            (gth_refclk0p_i[0]),
        .IB           (gth_refclk0n_i[0])
      );

    IBUFDS_GTE4 u_buf_gth_q1_clk1
      (
        .O            (gth_refclk1_i[0]),
        .ODIV2        (gth_odiv2_1_i[0]),
        .CEB          (1'b0),
        .I            (gth_refclk1p_i[0]),
        .IB           (gth_refclk1n_i[0])
      );

  //
  // Refclk connection from each IBUFDS to respective quads depending on the source selected in gui
  //
  assign gth_qrefclk0_i[0] = 1'b0;
  assign gth_qrefclk1_i[0] = 1'b0;
  assign gth_qnorthrefclk0_i[0] = 1'b0;
  assign gth_qnorthrefclk1_i[0] = 1'b0;
  assign gth_qsouthrefclk0_i[0] = gth_refclk0_i[0];
  assign gth_qsouthrefclk1_i[0] = 1'b0;
//COMMON clock connection
  assign gth_qrefclk00_i[0] = 1'b0;
  assign gth_qrefclk10_i[0] = 1'b0;
  assign gth_qrefclk01_i[0] = 1'b0;
  assign gth_qrefclk11_i[0] = 1'b0;
  assign gth_qnorthrefclk00_i[0] = 1'b0;
  assign gth_qnorthrefclk10_i[0] = 1'b0;
  assign gth_qnorthrefclk01_i[0] = 1'b0;
  assign gth_qnorthrefclk11_i[0] = 1'b0;
  assign gth_qsouthrefclk00_i[0] = gth_refclk0_i[0];
  assign gth_qsouthrefclk10_i[0] = 1'b0;
  assign gth_qsouthrefclk01_i[0] = 1'b0;
  assign gth_qsouthrefclk11_i[0] = 1'b0;
 
  assign gth_qrefclk0_i[1] = gth_refclk0_i[0];
  assign gth_qrefclk1_i[1] = gth_refclk1_i[0];
  assign gth_qnorthrefclk0_i[1] = 1'b0;
  assign gth_qnorthrefclk1_i[1] = 1'b0;
  assign gth_qsouthrefclk0_i[1] = 1'b0;
  assign gth_qsouthrefclk1_i[1] = 1'b0;
//COMMON clock connection
  assign gth_qrefclk00_i[1] = gth_refclk0_i[0];
  assign gth_qrefclk10_i[1] = gth_refclk1_i[0];
  assign gth_qrefclk01_i[1] = 1'b0;
  assign gth_qrefclk11_i[1] = 1'b0;  
  assign gth_qnorthrefclk00_i[1] = 1'b0;
  assign gth_qnorthrefclk10_i[1] = 1'b0;
  assign gth_qnorthrefclk01_i[1] = 1'b0;
  assign gth_qnorthrefclk11_i[1] = 1'b0;  
  assign gth_qsouthrefclk00_i[1] = 1'b0;
  assign gth_qsouthrefclk10_i[1] = 1'b0;  
  assign gth_qsouthrefclk01_i[1] = 1'b0;
  assign gth_qsouthrefclk11_i[1] = 1'b0; 
 

  //
  // Sysclock IBUFDS instantiation along with BUFG
  //
  IBUFGDS 
   #(.DIFF_TERM("FALSE"))
   u_ibufgds
    (
      .I(gth_sysclkp_i),
      .IB(gth_sysclkn_i),
      .O(gth_sysclk_i_buf)
    );

    BUFG clkin1_bufg1
   (.O (gth_sysclk_i),
    .I (gth_sysclk_i_buf));

  assign sys_clock_out = gth_sysclk_i;

  //
  // IBERT core instantiation
  //
  ibert_ultrascale_gth_0 u_ibert_gth_core
    (
      .txn_o(gth_txn_o),
      .txp_o(gth_txp_o),
      .rxn_i(gth_rxn_i),
      .rxp_i(gth_rxp_i),
      .clk(gth_sysclk_i),
      .gtrefclk0_i(gth_qrefclk0_i),
      .gtrefclk1_i(gth_qrefclk1_i),
      .gtnorthrefclk0_i(gth_qnorthrefclk0_i),
      .gtnorthrefclk1_i(gth_qnorthrefclk1_i),
      .gtsouthrefclk0_i(gth_qsouthrefclk0_i),
      .gtsouthrefclk1_i(gth_qsouthrefclk1_i),
      .gtrefclk00_i(gth_qrefclk00_i),
      .gtrefclk10_i(gth_qrefclk10_i),
      .gtrefclk01_i(gth_qrefclk01_i),
      .gtrefclk11_i(gth_qrefclk11_i),
      .gtnorthrefclk00_i(gth_qnorthrefclk00_i),
      .gtnorthrefclk10_i(gth_qnorthrefclk10_i),
      .gtnorthrefclk01_i(gth_qnorthrefclk01_i),
      .gtnorthrefclk11_i(gth_qnorthrefclk11_i),
      .gtsouthrefclk00_i(gth_qsouthrefclk00_i),
      .gtsouthrefclk10_i(gth_qsouthrefclk10_i),
      .gtsouthrefclk01_i(gth_qsouthrefclk01_i),
      .gtsouthrefclk11_i(gth_qsouthrefclk11_i)
    );

endmodule
