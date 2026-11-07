Versal_CPM6_CXL_RP_wrapper DUT (
  // Serial lanes (PIPE sim still possible)
  .CTRL1_GT_0_grx_n(vip2dut_1_n),
  .CTRL1_GT_0_grx_p(vip2dut_1_p),
  .CTRL1_GT_0_gtx_n(dut2vip_1_n),
  .CTRL1_GT_0_gtx_p(dut2vip_1_p),
  // 100 MHz PCIe ref clock
  .ctrl1_gt_refclk_0_clk_n(refclk_1_n),
  .ctrl1_gt_refclk_0_clk_p(refclk_1_p),
  // VPK360 GPIO
  .gpio_pb ('0), //4 pushbuttons
  .gpio_dip('0), //4 DIP switches
  .gpio_led(  )  //8 LEDs
);

`define XLNOC_DUT_INST Versal_CPM6_CXL_RP_wrapper
