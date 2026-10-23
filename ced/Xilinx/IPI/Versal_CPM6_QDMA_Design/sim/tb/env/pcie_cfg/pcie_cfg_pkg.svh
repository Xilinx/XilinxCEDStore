`include "dut_reg_pkg.svh"

package pcie_cfg_pkg;

  `include "uvm_macros.svh" 
  import uvm_pkg::*;

  import dut_reg_pkg::*;

  // For DUT and VIP config; unique per controller
  `include "cfg_defs.sv"
  `include "pcie_config.sv"
  `include "cxl_config.sv"
  `include "generic_config.sv"
  `include "dut_config.sv"
  `include "cfg_undefs.sv"

endpackage
