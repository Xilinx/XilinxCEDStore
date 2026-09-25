# ChipScoPy CED GT constraints for the VRK160 (xcvr1602-vsva2488) and
# VRK165 (xcvr1652-vsva2488) production boards. Both share the vsva2488
# package and map these quads and reference clocks to identical sites, so
# one constraint file serves both.
#
# These boards mix transceiver types: bank 104 is GTYP, banks 106 and 107 are
# GTM. Each quad owns its reference clock, so create_quad (gt_help.tcl) gives
# every quad its own refclk buffer and external differential port named
# bridge_refclk<refclk_site>_diff_gt_ref_clock.
#
# Each quad has two reference-clock sites: the even Y site is refclk0 and the
# odd Y site is refclk1. Selecting refclk0 vs refclk1 is done purely by the
# refclk LOC below; the block design always drives QUAD0_GTREFCLK0.
#
# Board bank   Function  GT quad site     Refclk           Refclk site        Pins        Rate      Refclk
# -----------  --------  ---------------  ---------------  -----------------  ----------  --------  ----------
# 104          GTYP      GTYP_QUAD_X0Y2   refclk1          GTYP_REFCLK_X0Y5   AD41/AD42   10 Gbps   156.25 MHz
# 106          GTM       GTM_QUAD_X0Y0    refclk1          GTM_REFCLK_X0Y1    T41/T42     20 Gbps   156.25 MHz
# 107          GTM       GTM_QUAD_X0Y1    refclk0          GTM_REFCLK_X0Y2    M41/M42     25 Gbps   156.25 MHz
#
# All three reference clocks are 156.25 MHz -> create_clock period 6.4 ns.

# gtyp_quad_104 : bank 104, refclk1 : 10 Gbps with 156.25 MHz
set_property LOC GTYP_QUAD_X0Y2 [get_cells chipscopy_i/gtyp_quad_104/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTYP_REFCLK_X0Y5 [get_cells chipscopy_i/gtyp_quad_104/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I]
create_clock -period 6.4 [get_ports bridge_refclkX0Y5_diff_gt_ref_clock_clk_p[0]]

# gtm_quad_106 : bank 106, refclk1 : 20 Gbps with 156.25 MHz
set_property LOC GTM_QUAD_X0Y0 [get_cells chipscopy_i/gtm_quad_106/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTM_REFCLK_X0Y1 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTME5} .*gtm_quad_106.*]
create_clock -period 6.4 [get_ports bridge_refclkX0Y1_diff_gt_ref_clock_clk_p[0]]

# gtm_quad_107 : bank 107, refclk0 : 25 Gbps with 156.25 MHz
set_property LOC GTM_QUAD_X0Y1 [get_cells chipscopy_i/gtm_quad_107/gtwiz_versal/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst]
set_property LOC GTM_REFCLK_X0Y2 [get_cells -hier -regexp -filter {LIB_CELL==IBUFDS_GTME5} .*gtm_quad_107.*]
create_clock -period 6.4 [get_ports bridge_refclkX0Y2_diff_gt_ref_clock_clk_p[0]]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
