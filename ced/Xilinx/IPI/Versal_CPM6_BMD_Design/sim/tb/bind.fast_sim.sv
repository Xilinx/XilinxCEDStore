// This module is designed to be bound at a higher level and then navigate
// down to the hierarchy as displayed.  The hierarchy differs between RTL
// and Vivado outputs.
module bind_fast_sim;

`ifdef CPM6_RTL
  `define ISO_WRAP   i_cpm6_iso_wrap
`else
  `define ISO_WRAP   BUT.uut.Icpm6_atom_X1Y0_R0.Icpm6_core_top.i_cpm6_iso_wrap
`endif

endmodule 
