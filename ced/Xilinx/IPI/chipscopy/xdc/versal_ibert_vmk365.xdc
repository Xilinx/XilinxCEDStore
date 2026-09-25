# ChipScoPy CED GT constraints for the VMK365 board (xc2vm3654-sfvb1440).
#
# Three GTYP quads, each with its own board-routed reference clock. The quads
# are created by the shared create_quad helper (gt_help.tcl), which instantiates
# a per-quad IBUFDSGTE and exposes an external differential port named
# bridge_refclk<refclk_site>_diff_gt_ref_clock.
#
# Board bank    Function   GT quad site      Refclk site        Refclk pins   Rate      Refclk
# ------------  ---------  ----------------  -----------------  ------------  --------  ---------
# 204           SFP        GTYP_QUAD_X1Y1    GTYP_REFCLK_X1Y2   J31 / H31     20 Gbps   156.25 MHz
# 205           QSFP       GTYP_QUAD_X1Y2    GTYP_REFCLK_X1Y4   J27 / H27     10 Gbps   156.25 MHz
# 206           SDI        GTYP_QUAD_X1Y3    GTYP_REFCLK_X1Y6   J23 / H23     25 Gbps   148.5  MHz
#
# Clock periods are 1000 / refclk_MHz: 156.25 MHz -> 6.4 ns, 148.5 MHz -> 6.734 ns.

# gtyp_quad_204 : bank 204 (SFP) : 20 Gbps with 156.25 MHz
set_property LOC GTYP_QUAD_X1Y1 [get_cells chipscopy_i/gtyp_quad_204/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTYP_REFCLK_X1Y2 [get_cells chipscopy_i/gtyp_quad_204/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 6.4 [get_ports bridge_refclkX1Y2_diff_gt_ref_clock_clk_p[0]]

# gtyp_quad_205 : bank 205 (QSFP) : 10 Gbps with 156.25 MHz
set_property LOC GTYP_QUAD_X1Y2 [get_cells chipscopy_i/gtyp_quad_205/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTYP_REFCLK_X1Y4 [get_cells chipscopy_i/gtyp_quad_205/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 6.4 [get_ports bridge_refclkX1Y4_diff_gt_ref_clock_clk_p[0]]

# gtyp_quad_206 : bank 206 (SDI) : 25 Gbps with 148.5 MHz
set_property LOC GTYP_QUAD_X1Y3 [get_cells chipscopy_i/gtyp_quad_206/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTYP_REFCLK_X1Y6 [get_cells chipscopy_i/gtyp_quad_206/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 6.734 [get_ports bridge_refclkX1Y6_diff_gt_ref_clock_clk_p[0]]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
