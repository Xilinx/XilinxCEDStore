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

class test_rp_traffic extends test_mem_tlp;
    `uvm_component_utils(test_rp_traffic)

    pcie_intf_pkg::error_counters_t sb_error_counts;
    pcie_intf_pkg::error_counters_t dut_error_counts;
    int data_error_cnt;
    int ep_data_error_cnt;

    bit error_counts_match;
    bit link_ok;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting RP test run_phase", UVM_LOW);

        #700ns; // Placeholder delay for test execution
        phase.drop_objection(this);
    endtask

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
    endfunction

    // The RTL's data-mismatch counter equals the scoreboards' sum, unless a derived test adds config traffic
    // the scoreboards do not model (IDE: the bridge's config reads), which only the RTL counts.
    virtual function bit data_mismatch_exact();
        return 1'b1;
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        error_counts_match = 1;

        uvm_config_db#(pcie_intf_pkg::error_counters_t)::get(null, "*", "rx_str_err_sb", sb_error_counts);
        uvm_config_db#(pcie_intf_pkg::error_counters_t)::get(null, "*", "dut_err_cnt_monitor", dut_error_counts);
        uvm_config_db#(int)::get(null, "*", "mem_scoreboard", data_error_cnt);
        uvm_config_db#(int)::get(null, "*", "ep_config_scoreboard", ep_data_error_cnt);

        if(sb_error_counts.URs_cnt != dut_error_counts.URs_cnt || 
           sb_error_counts.cfg_retry_err_cnt != dut_error_counts.cfg_retry_err_cnt ||
           sb_error_counts.CAs_cnt != dut_error_counts.CAs_cnt ||
           sb_error_counts.tlp_or_dllp_abort_err_cnt != dut_error_counts.tlp_or_dllp_abort_err_cnt ||
           sb_error_counts.fmt_mismatch_cnt != dut_error_counts.fmt_mismatch_cnt ||
           sb_error_counts.ttype_mismatch_cnt != dut_error_counts.ttype_mismatch_cnt) begin
            error_counts_match = 0;
        end

        if(!error_counts_match) begin
            `uvm_error(get_type_name(), "Error Counts Mismatch between Scoreboard and DUT");
            `uvm_info(get_type_name(), $sformatf("Scoreboard Error Counts - URs: %0d, CFG_RETRY: %0d, CAs: %0d, TLP/DLLP ABORT: %0d, FMT MISMATCH: %0d, TTYPE MISMATCH: %0d",
                sb_error_counts.URs_cnt,
                sb_error_counts.cfg_retry_err_cnt,
                sb_error_counts.CAs_cnt,
                sb_error_counts.tlp_or_dllp_abort_err_cnt,
                sb_error_counts.fmt_mismatch_cnt,
                sb_error_counts.ttype_mismatch_cnt), UVM_MEDIUM);
            `uvm_info(get_type_name(), $sformatf("DUT Error Counts - URs: %0d, CFG_RETRY: %0d, CAs: %0d, TLP/DLLP ABORT: %0d, FMT MISMATCH: %0d, TTYPE MISMATCH: %0d",
                dut_error_counts.URs_cnt,
                dut_error_counts.cfg_retry_err_cnt,
                dut_error_counts.CAs_cnt,
                dut_error_counts.tlp_or_dllp_abort_err_cnt,
                dut_error_counts.fmt_mismatch_cnt,
                dut_error_counts.ttype_mismatch_cnt), UVM_MEDIUM);
        end
        else begin
            `uvm_info(get_type_name(), "Error Counts Match", UVM_LOW);
            `uvm_info(get_type_name(), $sformatf("Scoreboard Error Counts - URs: %0d, CFG_RETRY: %0d, CAs: %0d, TLP/DLLP ABORT: %0d, FMT MISMATCH: %0d, TTYPE MISMATCH: %0d",
                sb_error_counts.URs_cnt,
                sb_error_counts.cfg_retry_err_cnt,
                sb_error_counts.CAs_cnt,
                sb_error_counts.tlp_or_dllp_abort_err_cnt,
                sb_error_counts.fmt_mismatch_cnt,
                sb_error_counts.ttype_mismatch_cnt), UVM_MEDIUM);
            `uvm_info(get_type_name(), $sformatf("DUT Error Counts - URs: %0d, CFG_RETRY: %0d, CAs: %0d, TLP/DLLP ABORT: %0d, FMT MISMATCH: %0d, TTYPE MISMATCH: %0d",
                dut_error_counts.URs_cnt,
                dut_error_counts.cfg_retry_err_cnt,
                dut_error_counts.CAs_cnt,
                dut_error_counts.tlp_or_dllp_abort_err_cnt,
                dut_error_counts.fmt_mismatch_cnt,
                dut_error_counts.ttype_mismatch_cnt), UVM_MEDIUM);
        end

        if(data_mismatch_exact() ? ((data_error_cnt + ep_data_error_cnt) != dut_error_counts.data_mismatch_cnt)
                                 : ((data_error_cnt + ep_data_error_cnt) > dut_error_counts.data_mismatch_cnt)) begin
            `uvm_error(get_type_name(), $sformatf("Data Mismatch Count Mismatch between Memory Scoreboard (%0d) + EP Config Scoreboard (%0d) and DUT (%0d)", 
                data_error_cnt, ep_data_error_cnt, dut_error_counts.data_mismatch_cnt));
        end else begin
            `uvm_info(get_type_name(), $sformatf("Data Mismatch Counts Match: DUT: %0d, EP CFG SB: %0d, MEM SB: %0d", dut_error_counts.data_mismatch_cnt, ep_data_error_cnt, data_error_cnt), UVM_LOW);
        end

        `uvm_info(get_type_name(), "Other DUT Error Counts: ", UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Poisoned TLP Count: %0d, Address Mismatch Count: %0d, Data Mismatch Count: %0d",
            dut_error_counts.tlp_poisoned_cnt, 
            dut_error_counts.addr_mismatch_cnt, 
            dut_error_counts.data_mismatch_cnt), UVM_MEDIUM);

        // End-of-test summary.
        begin
            bit dev_ok, enum_ok, mem_ok, cr_ok;
            int bars_ok;
            dev_ok  = _rp_env.ep_cfg_sb.dev_vendor_id_ok;
            bars_ok = 0;
            for (int b = 0; b < pcie_rp_pkg::NUM_BAR; b++)
                if (_rp_env.ep_cfg_sb.bar_base_ok[b]) bars_ok++;
            enum_ok = (_rp_env.ep_cfg_sb.rom_covered == pcie_rp_pkg::EP_ROM_SIZE) &&
                      (bars_ok == pcie_rp_pkg::NUM_BAR);
            mem_ok  = (_rp_env.mem_sb.mem_rd_count == _rp_env.mem_sb.mem_cpld_count) &&
                      (_rp_env.mem_sb.mem_rd_count == _rp_env.mem_sb.mem_wr_count) &&
                      (_rp_env.mem_sb.mem_rd_count == pcie_rp_pkg::TRAFFIC_COUNT) &&
                      (data_error_cnt == 0);
            cr_ok   = (_rp_env.cr_sb.tx_credits_available == 64) &&
                      (_rp_env.cr_sb.rx_credits_available == 16*pcie_str_pkg::RX_NUM_SLOTS);
            link_ok = (final_gen == exp_gen);

            `rp_note("RESULT", "==================== RESULT ====================")
            `rp_note("RESULT", $sformatf(
                "  Link          : %s  negotiated Gen%0d x%0d, configured Gen%0d",
                link_ok ? "PASS" : "FAIL",
                final_gen, lnk_width, exp_gen))
            `rp_note("RESULT", $sformatf(
                "  Device detect : %s  EP 0x%08h at BDF 0x%04h",
                dev_ok ? "PASS" : "FAIL",
                _rp_env.ep_cfg_sb.dev_vendor_id_seen, test_param_pkg::TEST_BDF))
            `rp_note("RESULT", $sformatf(
                "  Enumeration   : %s  ROM %0d/%0d entries exercised, %0d/%0d BAR bases verified",
                enum_ok ? "PASS" : "FAIL",
                _rp_env.ep_cfg_sb.rom_covered, pcie_rp_pkg::EP_ROM_SIZE,
                bars_ok, pcie_rp_pkg::NUM_BAR))
            `rp_note("RESULT", $sformatf(
                "  Memory flow   : %s  %0d reads / %0d writes / %0d completions, %0d data errors",
                mem_ok ? "PASS" : "FAIL",
                _rp_env.mem_sb.mem_rd_count, _rp_env.mem_sb.mem_wr_count,
                _rp_env.mem_sb.mem_cpld_count, data_error_cnt))
            `rp_note("RESULT", $sformatf(
                "  Credits       : %s  TX %0d/64 and RX %0d/%0d returned (no leak)",
                cr_ok ? "PASS" : "FAIL",
                _rp_env.cr_sb.tx_credits_available,
                _rp_env.cr_sb.rx_credits_available, 16*pcie_str_pkg::RX_NUM_SLOTS))
            `rp_note("RESULT", $sformatf(
                "  Consistency   : %s  scoreboard and RTL error counters agree",
                error_counts_match ? "PASS" : "FAIL"))
            `rp_note("RESULT", "================================================")
        end

        `uvm_info("RP_TEST_DONE", $sformatf("%s completed", get_type_name()), UVM_NONE);

    endfunction
endclass