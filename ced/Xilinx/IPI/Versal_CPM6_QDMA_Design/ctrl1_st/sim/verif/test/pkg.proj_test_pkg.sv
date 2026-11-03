// proj_test_pkg for the streaming configuration of this design. tb_top.sv
// `includes "pkg.proj_test_pkg.sv" and resolves it via +incdir search order
// (see ctrl1_st/sim/tb_files.f: +incdir+verif/test appears before
// +incdir+tb/test).
//
// Content list mirrors what the streaming test (test_qdma_h2c_c2h_st_Mfnc_MQ.sv)
// and its qdma_base_test.sv base class need. The agent packages imported below
// are compiled ahead of this file (see ctrl1_st/sim/tb_files.f); a `package`
// cannot be `included inside another.
package proj_test_pkg;

  timeunit 1ps;
  timeprecision 1ps;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import pcie_cfg_pkg::*;
  import avery_pkg::*;
  import apci_pkg::*;
  import apci_pkg_test::*;
  import env_pkg::*;
  import test_pkg::*;
  import tb_params_pkg::*;
  import shim_enum_pkg::*;
  import shim_caps_pkg::*;
  import shim_device_pkg::*;
  import shim_pkg::*;
  import shim_ecaps_pkg::*;
`ifdef CPM6_VIVADO
  // Needed by qdma_base_test.sv's pre_main_phase (PS VIP routing config).
  import ps_vip_api_pkg::*;
`endif
  import base_agent_pkg::*;
  import cpm6_qdma_params_pkg::*;

  // Agents created by qdma_base_test.sv's build_phase
  import cpm_axi_env_pkg::*;        // AXI-PL port monitors (axi_pl_env)
  import pswizard_agent_pkg::*;     // PS wizard NOC AXI, DMA IRQ and reset
  import qdma_periph_agent_pkg::*;  // s_axi_mem/s_axi_reg/m_axil_dbi/MSI-X
  import qdma_user_agent_pkg::*;    // H2C/C2H stream user ports
`ifdef USE_DSC_CRDT
  import dsc_crdt_agent_pkg::*;     // C2H descriptor credits on dsc_crdt_in
`endif

  // Transaction + bus used to hand PCIe-observed H2C/C2H TLPs from
  // qdma_mem_callback (watches the PCIe link) to dma_req_processor (tracks
  // completion, MSI-X counts and data integrity from those TLPs).
  `include "host_req_tr.sv"
  `include "host_req_bus.sv"
  `include "dma_req_processor.sv"
  `include "qdma_mem_callback.sv"

  // Per-HDMA-channel lifecycle status map -- subscribes to qdma_periph_agnt.ap
  // and psw_agnt.ap, both declared in qdma_base_test.sv, so must come BEFORE it.
  `include "dma_channel_status_tracker.sv"

  // Base test (includes the driver-sequence engine, qdma_st_drv_engine.svh)
  // and the streaming test this configuration ships.
  `include "qdma_base_test.sv"
  `include "test_qdma_h2c_c2h_st_Mfnc_MQ.sv"
  `include "test_qdma_mem_tlps.sv"

endpackage
