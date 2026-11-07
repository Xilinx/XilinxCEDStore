package proj_test_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import tb_params_pkg::*;
  import test_pkg::*;  //framework base tests
  import ps_vip_api_pkg::*;
  import axi4_sim_pkg::*;  
  import shim_device_pkg::pcie_device;

  `include "test/base_ced_test.sv"
  `include "test/cpi0_basic_test.sv"
  `include "test/base_cpi_cmds_test.sv"
  `include "test/cpi0_wr_full_test.sv"
  `include "test/cpi0_rd_full_test.sv"
  `include "test/cpi0_mix_full_test.sv"
  `include "test/cpiALL_wr_full_test.sv"
  `include "test/cpiALL_rd_full_test.sv"
  `include "test/cpiALL_mix_full_test.sv"
  `include "test/cpi0_wr_mid_test.sv"
  `include "test/cpi0_rd_mid_test.sv"
  `include "test/cpi0_mix_mid_test.sv"
  `include "test/cpiALL_wr_mid_test.sv"
  `include "test/cpiALL_rd_mid_test.sv"
  `include "test/cpiALL_mix_mid_test.sv"

endpackage

