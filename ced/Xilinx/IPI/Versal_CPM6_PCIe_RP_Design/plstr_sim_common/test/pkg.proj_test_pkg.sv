////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
////////////////////////////////////////////////////////////////////////

// Vivado projects will set their incdir so that their actual proj_test_pkg
// can be found first before this empty one
`include "cr_str_if.sv"
`include "dut_err_cnt_if.sv"
`include "link_if.sv"
`include "pf_cfg_if.sv"
`include "pl_dbi_if.sv"
`include "rx_str_if.sv"
`include "tx_str_if.sv"
`include "vf_cfg_if.sv"

package proj_test_pkg; 


  timeunit 1ps;
  timeprecision 1ps;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import pcie_str_pkg::*;
  import pcie_intf_pkg::*;
  import pcie_rp_pkg::*;

  import avery_pkg::*;
  import apci_pkg::*;
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

  import test_pkg::*;


    // Flow log - must precede anything that uses the `rp_flow macro
  `include "rp_flow_log.svh"

      // Transactions
  `include "sequences/rp_pl_str/tx_str_txn.sv"
  `include "sequences/rp_pl_str/rx_str_txn.sv"
  `include "sequences/rp_pl_str/rp_cfg_txn.sv"
  `include "sequences/rp_pl_str/cr_txn.sv"
  `include "sequences/rp_pl_str/cpl_txn.sv"

    // Monitors
  `include "monitors/tx_str_monitor.sv"
  `include "monitors/rx_str_monitor.sv"
  `include "monitors/pl_dbi_monitor.sv"
  `include "monitors/rp_cfg_status_monitor.sv"
  `include "monitors/dut_err_cnt_monitor.sv"

  // Scoreboard
  `include "scoreboards/rp_scoreboard.sv"
  `include "scoreboards/cr_scoreboard.sv"
  `include "scoreboards/ep_config_scoreboard.sv"
  `include "scoreboards/rx_str_err_sb.sv"
  `include "scoreboards/rp_config_scoreboard.sv"
  `include "scoreboards/mem_scoreboard.sv"

    //Env
  `include "env/rp_env.sv"

    // RP Tests
  `include "test_mem_tlp.sv"
  `include "test_rp_traffic.sv"
`ifdef CPM6_VIVADO
  `include "test_rp_ide_basic.sv"
`endif


  endpackage