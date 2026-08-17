// Overlay for the "hdma_ddr" (LPDDR5, Controller-1) variant.
// Copied on top of sim/verif/dut_inst.sv by run.tcl when this variant is
// selected. 
//
// CH0_LPDDR5_0_* pins are intentionally left unconnected below: the
// verified-passing regression's dut_inst.sv does not tie them off or
// connect a DDR5 BFM, and Vivado's -scripts_only simulation-model
// generation for this configuration completes without them driven
// (see hdma_ddr/sim/README.txt "AVAILABLE TESTS" for what is/isn't
// independently re-verified beyond BD/sim-script generation).
wire [7:0] ctrl1_gt_grx_n;
wire [7:0] ctrl1_gt_grx_p;
wire [7:0] ctrl1_gt_gtx_n;
wire [7:0] ctrl1_gt_gtx_p;
// LPDDR5 CH0 -- tied off pending confirmation (see header note above)
wire [6:0]  ch0_lpddr5_0_ca;
wire        ch0_lpddr5_0_ck_c;
wire        ch0_lpddr5_0_ck_t;
wire [1:0]  ch0_lpddr5_0_cs;
wire [3:0]  ch0_lpddr5_0_dmi;
wire [31:0] ch0_lpddr5_0_dq;
wire [3:0]  ch0_lpddr5_0_rdqs_c;
wire [3:0]  ch0_lpddr5_0_rdqs_t;
wire        ch0_lpddr5_0_reset_n;
wire [3:0]  ch0_lpddr5_0_wck_c;
wire [3:0]  ch0_lpddr5_0_wck_t;

hdma_ddr_top_sim_wrapper hdma_ddr_top_i
(
  .CTRL1_GT_0_grx_n        (ctrl1_gt_grx_n)
 ,.CTRL1_GT_0_grx_p        (ctrl1_gt_grx_p)
 ,.CTRL1_GT_0_gtx_n        (ctrl1_gt_gtx_n)
 ,.CTRL1_GT_0_gtx_p        (ctrl1_gt_gtx_p)
 ,.ctrl1_gt_refclk_0_clk_n (refclk_0_n)
 ,.ctrl1_gt_refclk_0_clk_p (refclk_0_p)
 ,.sys_clk0_0_clk_n        (sys_clk_0_n)
 ,.sys_clk0_0_clk_p        (sys_clk_0_p)
  ,.CH0_LPDDR5_0_ca         (ch0_lpddr5_0_ca)
 ,.CH0_LPDDR5_0_ck_c       (ch0_lpddr5_0_ck_c)
 ,.CH0_LPDDR5_0_ck_t       (ch0_lpddr5_0_ck_t)
 ,.CH0_LPDDR5_0_cs         (ch0_lpddr5_0_cs)
 ,.CH0_LPDDR5_0_dmi        (ch0_lpddr5_0_dmi)
 ,.CH0_LPDDR5_0_dq         (ch0_lpddr5_0_dq)
 ,.CH0_LPDDR5_0_rdqs_c     (ch0_lpddr5_0_rdqs_c)
 ,.CH0_LPDDR5_0_rdqs_t     (ch0_lpddr5_0_rdqs_t)
 ,.CH0_LPDDR5_0_reset_n    (ch0_lpddr5_0_reset_n)
 ,.CH0_LPDDR5_0_wck_c      (ch0_lpddr5_0_wck_c)
 ,.CH0_LPDDR5_0_wck_t      (ch0_lpddr5_0_wck_t)
);
