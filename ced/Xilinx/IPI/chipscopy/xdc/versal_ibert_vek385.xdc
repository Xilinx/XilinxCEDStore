# vek385 (reva and revb): three GTYP quads all sharing refclk X1Y2 (322.265 MHz).
# A single IBUFDSGTE (util_ds_buf_x1y2) drives the shared refclk to all three quads.
#
# gtyp_quad_205 : 16.0 Gbps  -> GTYP_QUAD_X1Y1
# gtyp_quad_206 : 20.0 Gbps  -> GTYP_QUAD_X1Y2
# gtyp_quad_207 : 10.0 Gbps  -> GTYP_QUAD_X1Y3
# Shared refclk: GTYP_REFCLK_X1Y2 (period = 1000 / 322.265 ~= 3.103 ns)

set_property LOC GTYP_QUAD_X1Y0 [get_cells chipscopy_i/gtyp_quad_205/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTYP_QUAD_X1Y1 [get_cells chipscopy_i/gtyp_quad_206/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTYP_QUAD_X1Y2 [get_cells chipscopy_i/gtyp_quad_207/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y2 [get_cells chipscopy_i/util_ds_buf_x1y2/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 3.103 [get_ports bridge_refclkX1Y2_diff_gt_ref_clock_clk_p[0]]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]