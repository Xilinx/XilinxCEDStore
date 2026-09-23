package shim_pkg;

  // Avery VIP uses these values so we set ours to these so that 
  // hardcoded time literals (e.g. 100us) actually resolves to that
  // time value in the VIP
  timeunit 1ps;
  timeprecision 1ps;

  `include "uvm_macros.svh" 
  import uvm_pkg::*;

  // SNPS VIP
`ifdef CPM6_RTL
  import svt_uvm_pkg::*; 
  import svt_axi_uvm_pkg::*; 
`else
  import axi_mst_seq_pkg::ps_vip_vsequencer;
`endif

  // AVERY VIP
  import apci_pkg::*;
  import avery_pkg::*;

  // AVERY COSIM STUFF
 `ifdef AVERY_CPM6_COSIM
  import apci_cosim_env_pkg::*;
  import qemu_rx_pkg::*;
  `include "apci_cosim_rp_callbacks.sv"
 `endif

  import cxl_mbox_pkg::*;
  import shim_caps_pkg::*;
  import shim_ecaps_pkg::*;
  import shim_enum_pkg::*;
  import shim_device_pkg::*;
  import pcie_cfg_pkg::generic_config;
  import pcie_cfg_pkg::pcie_config;

  import base_agent_pkg::*;
  import cxl_nfi_agent_pkg::*; // This includes mem_txns.sv
  import cxl31_ll_pkg::*; // This defines flit_mode_t and other constructs
  import cxl31_tl_pkg::*; // This defines m2srwd68_hdr_t and other constructs

  // Transactions
  `include "amd_base_tlp.sv"
  `include "amd_cfg_tlp.sv"
  `include "amd_mem_tlp.sv"
  `include "amd_cxlbase_tlp.sv"
  `include "amd_cxlmem_tlp.sv"
  // Scoreboards and VIP callbacks — RTL mode only (use svt_axi_transaction, SVT VIP types)
`ifdef CPM6_RTL
  `include "vip_tlp_cb.sv"
  `include "apci_tlp_sb.sv"
  `include "amd_tlp_converter_sb.sv"
`endif
  // Components
  `include "pdev_container.sv"
  `include "shim_vsequencer.sv"
  `include "shim_api.sv"
  `include "cxl_cm_reg_cb.sv"
  `include "shim_layer.sv"
  // Base sequences
  `include "seq/vseq_base.sv"
  `include "seq/vseq_in_order.sv"
  `include "seq/vseq_random_order.sv"
  `include "seq/vseq_loop.sv"
  `include "seq/vseq_loop_until.sv"
  // Useful sequences 
  `include "seq/seq_cap_traverse.sv"
  `include "seq/seq_cfg_spc_header.sv"
  `include "seq/seq_ep_get_bars.sv"
  `include "seq/seq_ep_get_sriov.sv"

  // CXL-specific sequences
  `include "seq/seq_cxl_base.sv"
  `include "seq/seq_cxl_cachemem_reqrwd_avery_rand.sv"

endpackage
