// Overlay for the "dma" (non-DDR, Controller-0) variant.
`define XLNOC_DUT_INST tb_top.dma_top_i
wire [7:0] ctrl0_gt_grx_n;
wire [7:0] ctrl0_gt_grx_p;
wire [7:0] ctrl0_gt_gtx_n;
wire [7:0] ctrl0_gt_gtx_p;

dma_top dma_top_i
(
  .CTRL0_GT_0_grx_n        (ctrl0_gt_grx_n)
 ,.CTRL0_GT_0_grx_p        (ctrl0_gt_grx_p)
 ,.CTRL0_GT_0_gtx_n        (ctrl0_gt_gtx_n)
 ,.CTRL0_GT_0_gtx_p        (ctrl0_gt_gtx_p)
 ,.ctrl0_gt_refclk_0_clk_n (refclk_0_n)
 ,.ctrl0_gt_refclk_0_clk_p (refclk_0_p)
);
