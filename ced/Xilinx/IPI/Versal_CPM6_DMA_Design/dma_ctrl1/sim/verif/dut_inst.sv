// Overlay for the "dma" (non-DDR, Controller-1) variant.
`define XLNOC_DUT_INST tb_top.dma_top_i
wire [7:0] ctrl1_gt_grx_n;
wire [7:0] ctrl1_gt_grx_p;
wire [7:0] ctrl1_gt_gtx_n;
wire [7:0] ctrl1_gt_gtx_p;

dma_top dma_top_i
(
  .CTRL1_GT_0_grx_n        (ctrl1_gt_grx_n)
 ,.CTRL1_GT_0_grx_p        (ctrl1_gt_grx_p)
 ,.CTRL1_GT_0_gtx_n        (ctrl1_gt_gtx_n)
 ,.CTRL1_GT_0_gtx_p        (ctrl1_gt_gtx_p)
 ,.ctrl1_gt_refclk_0_clk_n (refclk_0_n)
 ,.ctrl1_gt_refclk_0_clk_p (refclk_0_p)
);
