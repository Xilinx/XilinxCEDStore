// Overlay for the "dma" (non-DDR, Controller-1) variant.
// Copied on top of sim/verif/dut_inst.sv by run.tcl when this variant is
// selected. Instantiates the Vivado-generated NoC simulation wrapper
// (dma_top_sim_wrapper, auto-generated per-project alongside dma_top --
// NOT the generic design_1_wrapper_sim_wrapper.v checked into this repo,
// which wraps a different top module name and is not used by this variant).
// Instantiating dma_top directly here (without the _sim_wrapper) skips the
// xlnoc NoC switch model and its port-driving assigns, leaving axi_noc2_0's
// npp_in/npp_out ports undriven -- this caused a "noc_valid ... unknown"
// elaboration fatal.
wire [7:0] ctrl1_gt_grx_n;
wire [7:0] ctrl1_gt_grx_p;
wire [7:0] ctrl1_gt_gtx_n;
wire [7:0] ctrl1_gt_gtx_p;
wire [127:0] dma1_irq_0;

dma_top_sim_wrapper dma_top_i
(
  .CTRL1_GT_0_grx_n        (ctrl1_gt_grx_n)
 ,.CTRL1_GT_0_grx_p        (ctrl1_gt_grx_p)
 ,.CTRL1_GT_0_gtx_n        (ctrl1_gt_gtx_n)
 ,.CTRL1_GT_0_gtx_p        (ctrl1_gt_gtx_p)
 ,.ctrl1_gt_refclk_0_clk_n (refclk_0_n)
 ,.ctrl1_gt_refclk_0_clk_p (refclk_0_p)
 ,.dma1_irq_0              (dma1_irq_0)
);
