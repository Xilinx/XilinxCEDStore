# ChipScoPy CED GT constraints for the VPK360 board (EK-VPK360-G, xc2vp3602)
# The four GTM2 quads are created via the shared
# create_quad helper (gt_help.tcl); each quad exposes an external differential
# reference clock port named bridge_refclk<loc>_diff_gt_ref_clock and uses the
# IBUFDS_GTM2 refclk buffer.
#
# GTM2 refclk 312.5 MHz -> create_clock period 3.2 ns; 156.25 MHz -> 6.4 ns.
# GT quad LOC = GTM2_QUAD_X1Y(refclk_Y/2) following the Versal refclk-to-quad
# numbering convention (two refclks per quad).

# gtm2_quad_202 : refclkX1Y4 : 10.3125 Gbps with 312.5 MHz
set_property LOC GTM2_QUAD_X1Y2 [get_cells chipscopy_i/gtm2_quad_202/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTM2_REFCLK_X1Y4 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTM2} .*gtm2_quad_202.*]
create_clock -period 3.2 [get_ports bridge_refclkX1Y4_diff_gt_ref_clock_clk_p[0]]

# gtm2_quad_204 : refclkX1Y8 : 20.0 Gbps with 312.5 MHz
set_property LOC GTM2_QUAD_X1Y4 [get_cells chipscopy_i/gtm2_quad_204/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTM2_REFCLK_X1Y8 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTM2} .*gtm2_quad_204.*]
create_clock -period 3.2 [get_ports bridge_refclkX1Y8_diff_gt_ref_clock_clk_p[0]]

# gtm2_quad_207 : refclkX1Y14 : 40.0 Gbps with 312.5 MHz
set_property LOC GTM2_QUAD_X1Y7 [get_cells chipscopy_i/gtm2_quad_207/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTM2_REFCLK_X1Y14 [get_cells chipscopy_i/util_ds_buf_x1y14/U0/USE_IBUFDS_GTM2.GEN_IBUFDS_GTM2[0].IBUFDS_GTM2_U]
create_clock -period 3.2 [get_ports bridge_refclkX1Y14_diff_gt_ref_clock_clk_p[0]]

# gtm2_quad_208 : refclkX1Y14 : 10.0 Gbps with 312.5 MHz
set_property LOC GTM2_QUAD_X1Y8 [get_cells chipscopy_i/gtm2_quad_208/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]



set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

