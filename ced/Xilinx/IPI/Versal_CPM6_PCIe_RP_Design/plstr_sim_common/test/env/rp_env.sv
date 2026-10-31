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

`include "uvm_macros.svh"

class rp_env extends uvm_env;
  `uvm_component_utils(rp_env)

  // Monitor instances
    pl_dbi_monitor        pl_dbi_mon;
    rp_cfg_status_monitor cfg_status_mon;
    rx_str_monitor      rx_str_mon;
    tx_str_monitor      tx_str_mon;
    dut_err_cnt_monitor  dut_err_mon;

  // Scoreboard instance
    rp_scoreboard       sb;
    cr_scoreboard       cr_sb;
    ep_config_scoreboard ep_cfg_sb;
    rp_config_scoreboard  rp_cfg_sb;
    rx_str_err_sb     rx_str_err_sb;
    mem_scoreboard     mem_sb;


  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    `uvm_info(get_type_name(), "Starting build phase", UVM_LOW)

    // Create monitors
    pl_dbi_mon = proj_test_pkg::pl_dbi_monitor::type_id::create("pl_dbi_mon", this);
    cfg_status_mon = proj_test_pkg::rp_cfg_status_monitor::type_id::create("cfg_status_mon", this);
    rx_str_mon = proj_test_pkg::rx_str_monitor::type_id::create("rx_str_mon", this);
    tx_str_mon = proj_test_pkg::tx_str_monitor::type_id::create("tx_str_mon", this);
    dut_err_mon = proj_test_pkg::dut_err_cnt_monitor::type_id::create("dut_err_mon", this);

    if (!pl_dbi_mon || !cfg_status_mon || !rx_str_mon || !tx_str_mon || !dut_err_mon)
        `uvm_fatal(get_type_name(), "Failed to create one or more monitors")

    // Set cfg_mon handle in scoreboard

    // Create scoreboard
    sb = proj_test_pkg::rp_scoreboard::type_id::create("sb", this);
    if (!sb)
        `uvm_fatal(get_type_name(), "Failed to create scoreboard")
    
    cr_sb = proj_test_pkg::cr_scoreboard::type_id::create("cr_sb", this);
    if (!cr_sb)
        `uvm_fatal(get_type_name(), "Failed to create cr_scoreboard")

    ep_cfg_sb = proj_test_pkg::ep_config_scoreboard::type_id::create("ep_cfg_sb", this);
    if (!ep_cfg_sb)
        `uvm_fatal(get_type_name(), "Failed to create ep_config_scoreboard")

    rp_cfg_sb = proj_test_pkg::rp_config_scoreboard::type_id::create("rp_cfg_sb", this);
    if (!rp_cfg_sb)
        `uvm_fatal(get_type_name(), "Failed to create rp_config_scoreboard")

    rx_str_err_sb = proj_test_pkg::rx_str_err_sb::type_id::create("rx_str_err_sb", this);
    if (!rx_str_err_sb)
        `uvm_fatal(get_type_name(), "Failed to create rx_str_err_sb")

    mem_sb = proj_test_pkg::mem_scoreboard::type_id::create("mem_sb", this);
    if (!mem_sb)
        `uvm_fatal(get_type_name(), "Failed to create mem_scoreboard")

    `uvm_info(get_type_name(), "Completed build phase", UVM_LOW)

  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    `uvm_info(get_type_name(), "Starting connect phase", UVM_LOW)

    // Connect Credit scoreboard
    tx_str_mon.cr_ap.connect(cr_sb.tx_cr_exp);
    rx_str_mon.cr_ap.connect(cr_sb.rx_cr_exp);

    sb.rx_ap.connect(ep_cfg_sb.rx_exp);
    sb.tx_ap.connect(ep_cfg_sb.tx_exp);

    sb.mem_rx_ap.connect(mem_sb.mem_rq_exp);
    sb.mem_tx_ap.connect(mem_sb.mem_cpl_exp);

    // Connect RP to EP config scoreboard
    ep_cfg_sb.addr_port.connect(sb.addr_imp);
    ep_cfg_sb.addr_port.connect(mem_sb.addr_imp);

    // Connect PL DBI monitor to RP config scoreboard
    pl_dbi_mon.ap.connect(rp_cfg_sb.dbi_exp);

    // Connect Error monitor to RX STR error scoreboard
    rx_str_mon.ap.connect(rx_str_err_sb.rx_exp);


    `uvm_info(get_type_name(), "Completed connect phase", UVM_LOW)

  endfunction

endclass