package test_pkg;

  timeunit 1ps;
  timeprecision 1ps;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import avery_pkg::*;
  import apci_pkg::*;
  import apci_pkg_test::*;
  import base_agent_pkg::*;
  import reset_agent_pkg::*;
  import env_pkg::*;
  import tb_params_pkg::*;
`ifdef CPM6_VIVADO
  import ps_vip_api_pkg::*;
`endif

  import shim_enum_pkg::*;
  import shim_caps_pkg::*;
  import shim_ecaps_pkg::*;
  import shim_device_pkg::*;
  import shim_pkg::*;
  import pcie_cfg_pkg::*;

  // Just for printing
  `include "other/custom_report_server.sv"

  // Sequences used during enumeration
  import axi_mst_seq_pkg::*;
  `include "seq/seq_enum_callback.sv"
  `include "seq/seq_enum.sv"

  // Base Tests
  `include "test_base.sv"
  `include "test_init.sv"
  `include "test_enum.sv"
  `include "base_ep_test.sv"

endpackage
