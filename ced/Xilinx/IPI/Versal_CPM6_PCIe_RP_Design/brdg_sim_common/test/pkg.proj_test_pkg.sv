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
package proj_test_pkg; 


  timeunit 1ps;
  timeprecision 1ps;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

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
  import axi_mst_seq_pkg::*;

  import test_pkg::*;

  // Bridge log - must precede anything using `rp_txn / `rp_cfg
  `include "rp_bridge_log.svh"

  `include "seq_ps_ep_mem.sv"
  `include "test_ps_transactions.sv"
`ifdef CPM6_VIVADO
  `include "test_brdg_ide_basic.sv"
`endif


  endpackage
