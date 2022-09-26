# refclkX1Y1 : 25.0 Gbps with 100.0 MHz
set_property LOC GTYP_QUAD_X1Y0 [get_cells chipscopy_i/gtyp_quad_200/gt_quad_base/inst/quad_inst]
set_property LOC GTYP_REFCLK_X1Y0 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTE5} .*gtyp_quad_200.*]
create_clock -period 10.0 [get_ports bridge_refclkX1Y0_diff_gt_ref_clock_clk_p[0]]

# refclkX1Y2 : 16.0 Gbps with 100.00 MHz
set_property LOC GTYP_QUAD_X1Y1 [get_cells chipscopy_i/gtyp_quad_201/gt_quad_base_1/inst/quad_inst]
set_property LOC GTYP_REFCLK_X1Y2 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTE5} .*gtyp_quad_201.*]
create_clock -period 10.0 [get_ports bridge_refclkX1Y2_diff_gt_ref_clock_clk_p[0]]

# refclkX0Y4 : 56.42 Gbps with 156.25 MHz
set_property LOC GTM_QUAD_X0Y2 [get_cells chipscopy_i/gtm_quad_204/gt_quad_base/inst/quad_inst]
set_property LOC GTM_REFCLK_X0Y4 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTME5} .*gtm_quad_204.*]
create_clock -period 6.4 [get_ports bridge_refclkX0Y4_diff_gt_ref_clock_clk_p[0]]

# refclkX0Y6 : 56.42 Gbps with 156.25 MHz
set_property LOC GTM_QUAD_X0Y3 [get_cells chipscopy_i/gtm_quad_205/gt_quad_base/inst/quad_inst]
set_property LOC GTM_REFCLK_X0Y6 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTME5} .*gtm_quad_205.*]
create_clock -period 10.0 [get_ports bridge_refclkX0Y6_diff_gt_ref_clock_clk_p[0]]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
