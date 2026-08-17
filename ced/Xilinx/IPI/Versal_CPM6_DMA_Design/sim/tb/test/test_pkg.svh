package test_pkg;

  // Avery VIP uses these values so we set ours to these so that 
  // hardcoded time literals (e.g. 100us) actually resolves to that
  // time value in the VIP
  timeunit 1ps;
  timeprecision 1ps;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import avery_pkg::*;
  import apci_pkg::*;
  import apci_pkg_test::*;
`ifdef CPM6_RTL
  import svt_uvm_pkg::*; 
  import svt_axi_uvm_pkg::*; 
`endif
  import base_agent_pkg::*;
  import reset_agent_pkg::*;
  import cxl_nfi_agent_pkg::*;
  import elbi_agent_pkg::*;
  import cxl31_ll_pkg::*;
  import cxl31_tl_pkg::*;
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
  import cxl_mbox_pkg::*;

  import socket_dpi_pkg::*;

  // Just for printing
  `include "other/custom_report_server.sv"

  // Callbacks
  `include "cb/cxl_hdm_decoder.sv"

  // Callbacks for below specific sequences
  `include "seq/seq_enum_callback.sv"
  // Sequences that may be used across several tests
  import axi_mst_seq_pkg::*;
  `include "seq/seq_enum.sv"
  `include "seq/seq_hot_reset.sv"
  `include "seq/cseq_core_cxl_decoder_commit.sv"
  `include "seq/cseq_core_doe_discovery_cfg_mb.sv"
  `include "seq/cseq_core_doe_emu_cfg_mb.sv"
  `include "seq/seq_program_ide_key.sv"

  // Base Tests
  `include "test_base.sv"
  `include "test_init.sv"
  `include "test_enum.sv"
  `include "base_ep_test.sv"
  `include "test_ide_basic.sv"
  `include "base_rp_test.sv"
  `include "base_rp_gen6x8_bar_access_test.sv"
  `include "base_cxl_ep_test.sv"
  `include "base_cxl_rp_test.sv"
  `include "base_cxl_ep_type3_hdm1_fm.sv"
  `include "base_cxl_ep_type3_hdm2_fm.sv"
  `include "base_cxl_ep_type3_hdm1_nfm.sv"
  `include "base_cxl_ep_type3_hdm2_nfm.sv"

  // Operational Tests
  //   - CXL
  `include "ext_cxl_test/other/cxl_basic_responder.sv"

  //     - Controller - Agnostic
  `include "rand_traffic_cxl_mem_hdm1.sv"

  //     - Controller 0
  `include "ext_cxl_test/basic_cxl0_ep_type3_hdm1_fm.sv"
  `include "ext_cxl_test/basic_cxl0_ep_type3_hdm2_fm.sv"
  `include "ext_cxl_test/basic_cxl0_ep_type3_hdm1_nfm.sv"
  `include "ext_cxl_test/basic_cxl0_ep_type3_hdm2_nfm.sv"

  `include "ext_cxl_test/ctrl0_rand_traffic_cxl_mem_hdm1.sv"
  //     - Controller 1
  `include "ext_cxl_test/basic_cxl1_ep_type3_hdm1_fm.sv"
  `include "ext_cxl_test/basic_cxl1_ep_type3_hdm2_fm.sv"
  `include "ext_cxl_test/basic_cxl1_ep_type3_hdm1_nfm.sv"
  `include "ext_cxl_test/basic_cxl1_ep_type3_hdm2_nfm.sv"

  `include "ext_cxl_test/ctrl1_rand_traffic_cxl_mem_hdm1.sv"
  // Example Tests
  `include "hello_world.sv"
  `include "examples/test_cfg_tlps.sv"
  `include "examples/test_mem_tlps.sv"
  `include "examples/test_ide_tlps.sv"
  `include "examples/test_mem_ide_tlps.sv"
  `include "examples/test_ide_tlps_spdm.sv"

  // HDMA Tests
  // Ported from uvma-pcie-sim-framework/cpm6/common/test/hdma/ (same file
  // set and order as the verified-passing RDI regression at
  // cpm6/ctrl1ep_g6x8_hdma_1pf) -- see sim/tb/test/hdma/ for sources.
  `include "hdma/rc_mem_callback.sv"
  `include "hdma/test_hdma_tasks.sv"
  `include "hdma/test_M_bridge_plaxi_ctrlr1.sv"
  `include "hdma/test_M_bridge_plaxi_ctrlr1_4pf.sv"
  `include "hdma/test_M_bridge_plaxi_ctrlr1_4pf_axildecode.sv"
  `include "hdma/test_M_bridge_ddr_ctrlr1.sv"
  `include "hdma/test_M_bridge_ddr_ctrlr1_4pf.sv"
  `include "hdma/test_M_bridge_ddr_ctrlr1_bar24_1pf.sv"
  `include "hdma/test_s_hdma_plaxi_ctrlr1.sv"
  `include "hdma/test_s_hdma_ddr_ctrlr1.sv"
  `include "hdma/test_s_hdma_ddr_ctrlr1_msix.sv"
  `include "hdma/test_s_hdma_ddr_ctrlr1_multipf.sv"

endpackage
