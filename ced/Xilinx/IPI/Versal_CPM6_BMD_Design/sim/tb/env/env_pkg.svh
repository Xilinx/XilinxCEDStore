
`include "tb_params_pkg.svh"

package env_pkg;

  // Avery VIP uses these values so we set ours to these so that 
  // hardcoded time literals (e.g. 100us) actually resolves to that
  // time value in the VIP
  timeunit 1ps;
  timeprecision 1ps;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import tb_params_pkg::*;

  // SNPS VIP
`ifdef CPM6_RTL
  import svt_uvm_pkg::*; 
  import svt_axi_uvm_pkg::*; 
`endif

  // AVERY VIP
  import avery_pkg::*;
  import apci_pkg::*;

  import dut_reg_pkg::*;

  // UVMA Agents
  import base_agent_pkg::*;
  import base_sb_pkg::*;
  import reset_agent_pkg::*;
  import gpmon_agent_pkg::*;
  import elbi_agent_pkg::*;
  import cxl_credit_agent_pkg::*;
  import cxl_nfi_agent_pkg::*;
  import cxl_nfi_other_pkg::*;
  import cxl31_ll_pkg::*;
  import aximon_agent_pkg::*;

  // PCIe DUT and VIP config
  import pcie_cfg_pkg::*;
  // TB config
  `include "tb_env_cfg.sv"

  // AMD<->VIP shim
  import shim_pkg::*;

  // sequences
  import axi_mst_seq_pkg::*;
`ifdef CPM6_RTL
  `include "seq/axi_slv/seq_svt_slv_mem_rsp.sv"
`endif

  // For gpmon 
  `include "gpmon_cb/cxl_cfgsts_cb.sv"
  `include "gpmon_cb/cxl_pm_out_cb.sv"
  `include "gpmon_cb/isr_cb.sv"

  // All other
  `include "elbi_callback.sv"
  `include "cxl_credit_shim.sv"
  `include "tb_env.sv"

endpackage
