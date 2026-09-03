# control_pkg.tcl
#
# Fixed PMC register constants for PL reset-pin control -- not .hwh-
# discovered, same category as design::TARGET_INDEX / the MIO/GPIO
# constants in design_cmds.tcl.

namespace eval control {
  variable RST_PL_ADDR 0xF1260330   ;# CRP.RST_PL

  # bit -> description. Verified against run.tcl's create_hier_cell_cxl_datapath
  # port-connection block and the generated .hwh's PS_PMC_CONFIG
  # (PS_NUM_FABRIC_RESETS=3).
  variable RST_PL_BITS
  array set RST_PL_BITS {
    0 {cxl1_rstn -- per-cpi cxl_datapath_N/s_axi_aresetn (pl_axi_cpi_bridge_N + custom_axi_tg_N/m_axi_aresetn), smartconnect_2, axil_cxl_pm_viral_0 (via ps_wizard_0/pl0_resetn + xpm_cdc_gen_0)}
    1 {(not connected to any net in this design -- ps_wizard_0/pl1_resetn exists but run.tcl only wires pl1_ref_clk, as pcie1_clk)}
    2 {axil_rstn -- per-cpi cxl_datapath_N/axil_rstn (custom_axi_tg_N/s_axil_aresetn), smartconnect_3, axil_gpio4_0 (via ps_wizard_0/pl2_resetn + xpm_cdc_gen_2)}
    3 {(does not exist in this configuration -- PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS)=3, no pl3_resetn port on ps_wizard_0)}
  }
  variable RST_PL_WIRED_BITS {0 2}  ;# bits actually connected to a net here
}
