// ===========================================================================
// pkg.proj_test_pkg.sv - Versal CPM6 CXL EP Bridge Design
//
// Project-specific override of the empty sim/tb/test/pkg.proj_test_pkg.sv
// placeholder ("package proj_test_pkg; endpackage" - see that file's own
// header comment: "Vivado projects will set their incdir so that their
// actual proj_test_pkg can be found first before this empty one").
//
// Picked up because sim/standalone/Makefile's TESTCASE_INCDIR lists this
// verif/ directory BEFORE sim/tb, matching the exact mechanism documented
// at the top of sim/tb/tb_top.sv.
// ===========================================================================
package proj_test_pkg;
  // uvm_pkg imported directly since package wildcard imports are not
  // transitive in SystemVerilog: `uvm_component_utils expands to a
  // reference to uvm_component_registry (a uvm_pkg type), which
  // "import test_pkg::*" alone would not bring into scope here.
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import test_pkg::*;
  // Same non-transitive-import gap as uvm_pkg above: these packages are
  // only re-exported by test_pkg.svh via its OWN "import <pkg>::*", so
  // "import test_pkg::*" alone doesn't bring them into scope here. Safe to
  // re-import directly (identical declarations from the same source
  // packages, not a second/conflicting definition).
  import env_pkg::*;
  import shim_pkg::*;
  import shim_enum_pkg::*;
  import shim_device_pkg::*;
  import axi_mst_seq_pkg::*;
  import ps_vip_api_pkg::*;
  // pcie_config (used via pcie_config::speed_e/GEN5/GEN6) is a class, not a
  // package, declared inside package pcie_cfg_pkg - import the package
  // here too, same non-transitive-import reason as above.
  import pcie_cfg_pkg::*;
  `include "seq/cseq_cfg_ctrl_reg_ep.sv"
  `include "seq/cxl_mem_wr_rd_4consec_seq.sv"
  `include "seq/cseq_app_req_retry_en.sv"
  `include "seq/cseq_cxl_dvsec_next_cap.sv"
  `include "seq/cseq_irq_enables.sv"
  `include "seq/cseq_fix_cxl_hdm_dec_caps.sv"
  `include "cxl_ep_brdg_sanity.sv"
endpackage
