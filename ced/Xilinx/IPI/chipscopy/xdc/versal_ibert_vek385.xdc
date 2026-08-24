# refclkX0Y2 : 25 Gbps with 100 MHz
set_property LOC GTYP_QUAD_X0Y1 [get_cells chipscopy_i/gtyp_quad_106/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X0Y2 [get_cells  chipscopy_i/gtyp_quad_106/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkX0Y2_diff_gt_ref_clock_clk_p[0]]

# refclkX0Y4 : 16 Gbps with 100.00 MHz
set_property LOC GTYP_QUAD_X0Y2 [get_cells chipscopy_i/gtyp_quad_107/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X0Y4 [get_cells chipscopy_i/gtyp_quad_107/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkX0Y4_diff_gt_ref_clock_clk_p[0]]

# refclkX1Y0 : 20 Gbps with 156.25 MHz
set_property LOC GTYP_QUAD_X1Y0 [get_cells chipscopy_i/gtyp_quad_205/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y0 [get_cells chipscopy_i/gtyp_quad_205/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 6.4 [get_ports bridge_refclkX1Y0_diff_gt_ref_clock_clk_p[0]]

# refclkX1Y2 : 10 Gbps with 156.25 MHz
set_property LOC GTYP_QUAD_X1Y1 [get_cells chipscopy_i/gtyp_quad_206/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y2 [get_cells chipscopy_i/gtyp_quad_206/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 6.4 [get_ports bridge_refclkX1Y2_diff_gt_ref_clock_clk_p[0]]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]