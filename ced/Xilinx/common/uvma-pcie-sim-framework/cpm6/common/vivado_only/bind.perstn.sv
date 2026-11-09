// This module is translating between the Vivado generated CPM6 instance 
// to the UVM interface used in the uvma-pcie-sim-framework for the perstn
// signals for both controllers. This is specifically designed to be bound 
// at the CPM6 uni-sim instance level e.g.
//   bind CPM6 bind_perstn bind_perstn();
module bind_perstn
 import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  // --------------------
  // PERST for each controller
  // --------------------
  reset_if perstn_if[0:1]();
  
  initial begin
    force inst.perst0n = perstn_if[0].reset;
    force inst.perst1n = perstn_if[1].reset;
    uvm_config_db#(virtual reset_if)::set(null, "*", "vif_perstn[0]", perstn_if[0]);
    uvm_config_db#(virtual reset_if)::set(null, "*", "vif_perstn[1]", perstn_if[1]);
  end

endmodule
