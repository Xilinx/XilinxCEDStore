# refclkX0Y8 : 10.3125 Gbps with 156.25 MHz
set_property LOC GTYP_QUAD_X0Y4 [get_cells chipscopy_i/gtyp_quad_106/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X0Y8 [get_cells  chipscopy_i/gtyp_quad_106/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 6.4 [get_ports bridge_refclkX0Y8_diff_gt_ref_clock_clk_p[0]]

# refclkX1Y4 : 10.3125 Gbps with 100.00 MHz
set_property LOC GTYP_QUAD_X1Y2 [get_cells chipscopy_i/gtyp_quad_204/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y4 [get_cells chipscopy_i/gtyp_quad_204/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkX1Y4_diff_gt_ref_clock_clk_p[0]]

# refclkX1Y6 : 16 Gbps with 100.00 MHz
set_property LOC GTYP_QUAD_X1Y3 [get_cells chipscopy_i/gtyp_quad_205/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y6 [get_cells chipscopy_i/gtyp_quad_205/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkX1Y6_diff_gt_ref_clock_clk_p[0]]

# refclkX1Y8 : 25 Gbps with 100.00 MHz
set_property LOC GTYP_QUAD_X1Y4 [get_cells chipscopy_i/gtyp_quad_206/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]

set_property LOC GTYP_REFCLK_X1Y8 [get_cells chipscopy_i/gtyp_quad_206/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 10.0 [get_ports bridge_refclkX1Y8_diff_gt_ref_clock_clk_p[0]]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]