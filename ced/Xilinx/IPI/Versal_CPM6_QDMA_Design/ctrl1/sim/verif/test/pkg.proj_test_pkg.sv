// Real proj_test_pkg for this CED (QDMA MM basic tests). tb_top.sv `includes
// "pkg.proj_test_pkg.sv" and resolves it via +incdir search order -- this
// file must be found ahead of any empty framework stub of the same name
// (see ctrl1/sim/tb_files.f: +incdir+verif/test appears before +incdir+tb/test).
//
// Content list mirrors what this CED's test (test_qdma_h2c_c2h_mm_Mfnc_MQ.sv)
// and its qdma_base_test.sv base class actually need. pswizard_agent
// (imported below) monitors the PS wizard's NOC AXI handshakes, DMA
// completion IRQ vector, and reset.
package proj_test_pkg;

  timeunit 1ps;
  timeprecision 1ps;

  import uvm_pkg::*;
  import pcie_cfg_pkg::*;
  import avery_pkg::*;
  import apci_pkg::*;
  import apci_pkg_test::*;
  import env_pkg::*;
  import test_pkg::*;
  import shim_enum_pkg::*;
  import shim_caps_pkg::*;
  import shim_device_pkg::*;
  import shim_pkg::*;
  import shim_ecaps_pkg::*;
`ifdef CPM6_VIVADO
  // Needed by qdma_base_test.sv's pre_main_phase (PS VIP routing config).
  // Package-scoped imports don't cross package boundaries -- test_pkg.svh
  // importing this doesn't make it visible here, since qdma_base_test lives
  // in this (proj_test_pkg), not test_pkg.
  import ps_vip_api_pkg::*;
`endif
  // cpm6_qdma_params_pkg is a standalone package (params/pkg.cpm6_qdma_params.sv)
  // compiled ahead of this file -- see ctrl1/sim/tb_files.f -- not `included
  // here since a `package` declaration cannot be nested inside another.
  import cpm6_qdma_params_pkg::*;

  // pswizard_agent_pkg compiled ahead of this file -- see ctrl1/sim/tb_files.f.
  // Needed by qdma_base_test.sv's build_phase (psw_agnt creation).
  import pswizard_agent_pkg::*;

  // qdma_periph_agent_pkg compiled ahead of this file -- see ctrl1/sim/tb_files.f.
  // Needed by qdma_base_test.sv's build_phase
  // (qdma_periph_agnt creation).
  import qdma_periph_agent_pkg::*;

  // Transaction + bus used to hand PCIe-observed H2C/C2H TLPs from
  // qdma_mem_callback (boundary-level: watches the PCIe link only) to
  // dma_req_processor (boundary-level: tracks completion, MSI-X counts,
  // data integrity -- from those PCIe-observed TLPs only).
  `include "host_req_tr.sv"
  `include "host_req_bus.sv"
  `include "dma_req_processor.sv"
  `include "qdma_mem_callback.sv"

  // Per-HDMA-channel lifecycle status map --
  // subscribes to qdma_periph_agnt.ap + psw_agnt.ap, both declared in
  // qdma_base_test.sv, so must come BEFORE it (no forward reference).
  `include "dma_channel_status_tracker.sv"

  // Base test + the test this CED ships.
  `include "qdma_base_test.sv"
  `include "test_qdma_h2c_c2h_mm_Mfnc_MQ.sv"

endpackage
