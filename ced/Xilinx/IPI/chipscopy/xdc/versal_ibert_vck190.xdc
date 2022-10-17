# refclkX0Y10 : 10.3125 Gbps with 156.25 MHz
set_property LOC GTY_QUAD_X0Y5 [get_cells chipscopy_i/gty_quad_105/gt_quad_base/inst/quad_inst]
create_clock -period 7.757575757575758 [get_pins -hierarchical -regexp chipscopy_i/gty_quad_105/gt_quad_base/inst/quad_inst/CH0_TXOUTCLK]
create_clock -period 7.757575757575758 [get_pins -hierarchical -regexp chipscopy_i/gty_quad_105/gt_quad_base/inst/quad_inst/CH0_RXOUTCLK]

set_property LOC GTY_REFCLK_X0Y10 [get_cells  chipscopy_i/gty_quad_105/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 6.4 [get_ports bridge_refclkX0Y10_diff_gt_ref_clock_clk_p[0]]

# refclkX1Y2 : 10.3125 Gbps with 100.00 MHz
set_property LOC GTY_QUAD_X1Y1 [get_cells chipscopy_i/gty_quad_201/gt_quad_base/inst/quad_inst]
create_clock -period 7.757575757575758 [get_pins -hierarchical -regexp chipscopy_i/gty_quad_201/gt_quad_base/inst/quad_inst/CH0_TXOUTCLK]
create_clock -period 7.757575757575758 [get_pins -hierarchical -regexp chipscopy_i/gty_quad_201/gt_quad_base/inst/quad_inst/CH0_RXOUTCLK]

set_property LOC GTY_REFCLK_X1Y2 [get_cells chipscopy_i/gty_quad_201/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkX1Y2_diff_gt_ref_clock_clk_p[0]]

# refclkX1Y8 : 16 Gbps with 100.00 MHz
set_property LOC GTY_QUAD_X1Y4 [get_cells chipscopy_i/gty_quad_204/gt_quad_base/inst/quad_inst]
create_clock -period 5.0 [get_pins -hierarchical -regexp chipscopy_i/gty_quad_204/gt_quad_base/inst/quad_inst/CH0_TXOUTCLK]
create_clock -period 5.0 [get_pins -hierarchical -regexp chipscopy_i/gty_quad_204/gt_quad_base/inst/quad_inst/CH0_RXOUTCLK]

set_property LOC GTY_REFCLK_X1Y8 [get_cells chipscopy_i/gty_quad_204/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkX1Y8_diff_gt_ref_clock_clk_p[0]]

# refclkX1Y10 : 25 Gbps with 100.00 MHz
set_property LOC GTY_QUAD_X1Y5 [get_cells chipscopy_i/gty_quad_205/gt_quad_base/inst/quad_inst]
create_clock -period 3.2 [get_pins -hierarchical -regexp chipscopy_i/gty_quad_205/gt_quad_base/inst/quad_inst/CH0_TXOUTCLK]
create_clock -period 3.2 [get_pins -hierarchical -regexp chipscopy_i/gty_quad_205/gt_quad_base/inst/quad_inst/CH0_RXOUTCLK]

set_property LOC GTY_REFCLK_X1Y10 [get_cells chipscopy_i/gty_quad_205/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkX1Y10_diff_gt_ref_clock_clk_p[0]]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
