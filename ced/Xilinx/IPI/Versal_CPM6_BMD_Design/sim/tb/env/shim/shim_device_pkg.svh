package shim_device_pkg;

  `include "uvm_macros.svh" 
  import uvm_pkg::*;
  
  import shim_caps_pkg::*;
  import shim_ecaps_pkg::*;
  import shim_enum_pkg::*;
  import pcie_cfg_pkg::generic_config;
  import pcie_cfg_pkg::pcie_config;

  // Components
  `include "pcie_device_base.sv"
  `include "pcie_vdevice.sv"
  `include "pcie_device.sv"

endpackage
