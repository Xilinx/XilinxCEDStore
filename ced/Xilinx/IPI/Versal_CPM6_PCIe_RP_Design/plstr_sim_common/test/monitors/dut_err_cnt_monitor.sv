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

class dut_err_cnt_monitor extends uvm_monitor;

    `uvm_component_utils(dut_err_cnt_monitor)

    virtual dut_err_cnt_if.monitor_mp err_vif;

    pcie_intf_pkg::error_counters_t curr_error_counts = '{default:0};

    uvm_analysis_port #() ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual dut_err_cnt_if.monitor_mp)::get(this, "", "dut_err_cnt_if", err_vif)) begin
            `uvm_fatal(get_type_name(), "dut_err_cnt_if.monitor_mp is not set");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "CPL Error Count Monitor running", UVM_LOW);
        // Monitoring logic to be implemented
        forever begin
            @(err_vif.monitor_cb);
            if(curr_error_counts != err_vif.error_counts)
                `uvm_info(get_type_name(), $sformatf("CPL Error Counts Changed"), UVM_LOW);
            curr_error_counts = err_vif.error_counts;  
        end
    endtask

    virtual function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);
        uvm_config_db#(pcie_intf_pkg::error_counters_t)::set(null, "*", "dut_err_cnt_monitor", curr_error_counts);
        `uvm_info(get_type_name(), $sformatf("Final DUT Error Counts - URs: %0d, CFG_RETRY: %0d, CAs: %0d, TLP/DLLP ABORT: %0d, FMT MISMATCH: %0d, TTYPE MISMATCH: %0d",
            curr_error_counts.URs_cnt,
            curr_error_counts.cfg_retry_err_cnt,
            curr_error_counts.CAs_cnt,
            curr_error_counts.tlp_or_dllp_abort_err_cnt,
            curr_error_counts.fmt_mismatch_cnt,
            curr_error_counts.ttype_mismatch_cnt), UVM_MEDIUM);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Report Phase: DUT Error Counts Report - URs: %0d, CFG_RETRY: %0d, CAs: %0d, TLP/DLLP ABORT: %0d, FMT MISMATCH: %0d, TTYPE MISMATCH: %0d",
            curr_error_counts.URs_cnt,
            curr_error_counts.cfg_retry_err_cnt,
            curr_error_counts.CAs_cnt,
            curr_error_counts.tlp_or_dllp_abort_err_cnt,
            curr_error_counts.fmt_mismatch_cnt,
            curr_error_counts.ttype_mismatch_cnt), UVM_MEDIUM);
    endfunction
endclass