// This module is translating between the Vivado generated CPM6 instance 
// to the UVM interfaces used in the uvma-pcie-sim-framework for this 
// reset . This is specifically designed to be bound at the CPM6 uni-sim 
// instance level e.g.
//   bind CPM6 bind_lpd_por_n bind_lpd_por_n();
module bind_lpd_por_n
  import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  reset_if lpd_rst_n();

  // CPM6 doesn't even drive it, so no need for a force
  assign inst.lpd_cpm6_por_n = lpd_rst_n.reset;

  initial
    uvm_config_db#(virtual reset_if)::set(null, "*", "lpd_por_n_vif", lpd_rst_n);

endmodule
