# ChipScoPy CED GT constraints for the VPK180 board (xcvp1802)
# The four GTM quads are created via the
# shared create_quad helper (gt_help.tcl); each quad exposes an external
# differential reference clock port named bridge_refclk<loc>_diff_gt_ref_clock.
#
# GTM refclk 156.25 MHz -> create_clock period 6.4 ns.
# GT quad LOC = GTM_QUAD_X1Y(refclk_Y/2) following the Versal refclk-to-quad
# numbering convention (two refclks per quad).

# gtm_quad_208 : refclkX1Y12 : 10.3125 Gbps with 156.25 MHz
set_property LOC GTM_QUAD_X1Y6 [get_cells chipscopy_i/gtm_quad_208/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTM_REFCLK_X1Y12 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTME5} .*gtm_quad_208.*]
create_clock -period 6.4 [get_ports bridge_refclkX1Y12_diff_gt_ref_clock_clk_p[0]]

# gtm_quad_209 : refclkX1Y14 : 20.0 Gbps with 156.25 MHz
set_property LOC GTM_QUAD_X1Y7 [get_cells chipscopy_i/gtm_quad_209/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTM_REFCLK_X1Y14 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTME5} .*gtm_quad_209.*]
create_clock -period 6.4 [get_ports bridge_refclkX1Y14_diff_gt_ref_clock_clk_p[0]]

# gtm_quad_210 : refclkX1Y16 : 10.0 Gbps with 156.25 MHz
set_property LOC GTM_QUAD_X1Y8 [get_cells chipscopy_i/gtm_quad_210/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTM_REFCLK_X1Y16 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTME5} .*gtm_quad_210.*]
create_clock -period 6.4 [get_ports bridge_refclkX1Y16_diff_gt_ref_clock_clk_p[0]]

# gtm_quad_211 : refclkX1Y18 : 40.0 Gbps with 156.25 MHz
set_property LOC GTM_QUAD_X1Y9 [get_cells chipscopy_i/gtm_quad_211/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTM_REFCLK_X1Y18 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTME5} .*gtm_quad_211.*]
create_clock -period 6.4 [get_ports bridge_refclkX1Y18_diff_gt_ref_clock_clk_p[0]]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
