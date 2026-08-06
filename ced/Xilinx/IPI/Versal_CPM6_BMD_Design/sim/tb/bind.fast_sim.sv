// This module is designed to be bound at a higher level and then navigate
// down to the hierarchy as displayed.  The hierarchy differs between RTL
// and Vivado outputs.
module bind_fast_sim;

`ifdef CPM6_RTL
  `define ISO_WRAP   i_cpm6_iso_wrap
`else
  `define ISO_WRAP   BUT.uut.Icpm6_atom_X1Y0_R0.Icpm6_core_top.i_cpm6_iso_wrap
`endif
   // DEST MOD = "destination module"
  `define DEST_MOD_0 `ISO_WRAP.i_cpm6_pcie_core_0.i_pcie6_native_core_wrap.u_pcie6_native_core_pm_ctrl.snps_ip_u_DWC_pcie_native_core.u_DWC_pcie_core.u_cdm.u_cdm_pl_reg
  `define DEST_MOD_1 `ISO_WRAP.i_cpm6_pcie_core_1.i_pcie6_native_core_wrap.u_pcie6_native_core_pm_ctrl.snps_ip_u_DWC_pcie_native_core.u_DWC_pcie_core.u_cdm.u_cdm_pl_reg

  // This is a synthesizable net in the CfgSpace Port Logic (PL)
  // registers, which start at offset 0x700. This exact net
  // is found at 0x710[7]. Thus, it could theoretically be written
  // from the AXI-L DBI port in the real world, but I believe it's
  // sufficient in sim to just force it.
  initial begin
    force `DEST_MOD_0.cfg_fast_link_mode = 1;
    force `DEST_MOD_1.cfg_fast_link_mode = 1;
  end

  `undef DEST_MOD_0
  `undef DEST_MOD_1

endmodule
