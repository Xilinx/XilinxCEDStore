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

class rx_str_err_sb extends uvm_scoreboard;

    `uvm_component_utils(rx_str_err_sb);

    uvm_analysis_export #(rx_str_txn) rx_exp;

    uvm_tlm_analysis_fifo #(rx_str_txn) rx_fifo;

    virtual link_if.monitor_mp link_vif_err;

    pcie_intf_pkg::error_counters_t error_counters = '{default:0};

    function new(string name, uvm_component parent);
        super.new(name, parent);
        rx_exp = new("rx_exp", this);
        rx_fifo = new("rx_fifo", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual link_if.monitor_mp)::get(this,"","link_if", link_vif_err)) begin
            `uvm_fatal(get_type_name(), "link_if.monitor_mp is not set");
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        rx_exp.connect(rx_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            check_rx_str_errors();
            check_link_status();
        join
    endtask

    virtual function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);
        uvm_config_db#(pcie_intf_pkg::error_counters_t)::set(null, "*", "rx_str_err_sb", error_counters);
        `uvm_info(get_type_name(), $sformatf("Final Error Counts - URs: %0d, CFG_RETRY: %0d, CAs: %0d, TLP/DLLP ABORT: %0d, FMT MISMATCH: %0d, TTYPE MISMATCH: %0d",
            error_counters.URs_cnt,
            error_counters.cfg_retry_err_cnt,
            error_counters.CAs_cnt,
            error_counters.tlp_or_dllp_abort_err_cnt,
            error_counters.fmt_mismatch_cnt,
            error_counters.ttype_mismatch_cnt), UVM_MEDIUM);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        uvm_report_info(get_type_name(), $sformatf("Report Phase - URs: %0d, CFG_RETRY: %0d, CAs: %0d, TLP/DLLP ABORT: %0d, FMT MISMATCH: %0d, TTYPE MISMATCH: %0d",
            error_counters.URs_cnt,
            error_counters.cfg_retry_err_cnt,
            error_counters.CAs_cnt,
            error_counters.tlp_or_dllp_abort_err_cnt,
            error_counters.fmt_mismatch_cnt,
            error_counters.ttype_mismatch_cnt), UVM_MEDIUM);            
    endfunction

    task check_link_status();
        forever begin
            @(posedge link_vif_err.clk);
            if(link_vif_err.link_down) begin
                `uvm_info(get_type_name(), "RX_STR_ERR_SB: Link is down. Clearing RX STR error counters." , UVM_LOW);
                error_counters = '{default:0};
                // Additional handling can be added here if needed
                while(link_vif_err.link_down) begin
                    @(posedge link_vif_err.clk);
                end
                `uvm_info(get_type_name(), "RX_STR_ERR_SB: Link is up." , UVM_LOW);
            end
        end
    endtask

    task check_rx_str_errors();
        rx_str_txn rx_txn;
        rx_txn = rx_str_txn::type_id::create("rx_txn", this);
        forever begin
            rx_fifo.get(rx_txn);
            `uvm_info(get_type_name(), $sformatf("RX_STR_ERR_SB: Received RX STR Transaction - Type: 0x%0h, H_or_D: %0b, Tag: 0x%0h, Addr: 0x%0h, Status: 0x%0h",
                rx_txn.txn_type,
                rx_txn.txn_h_or_d,
                rx_txn.txn_data.cpl.tag,
                rx_txn.txn_data.cpl.addr,
                rx_txn.txn_data.cpl.status), UVM_MEDIUM);
            if(rx_txn.txn_h_or_d) begin
                if(rx_txn.txn_type == 'h3 || rx_txn.txn_type == 'h4) begin // for CPL and CPL DATA
                    case(rx_txn.txn_data.cpl.status)
                        3'b001: begin
                            error_counters.URs_cnt++;
                            `uvm_info(get_type_name(), $sformatf("RX_STR_ERR_SB: Detected UR Completion - Tag: 0x%0h, Addr: 0x%0h", rx_txn.txn_data.cpl.tag, rx_txn.txn_data.cpl.addr), UVM_LOW);
                        end
                        3'b010: begin
                            error_counters.cfg_retry_err_cnt++;
                            `uvm_info(get_type_name(), $sformatf("RX_STR_ERR_SB: Detected CFG RETRY Completion - Tag: 0x%0h, Addr: 0x%0h", rx_txn.txn_data.cpl.tag, rx_txn.txn_data.cpl.addr), UVM_LOW);
                        end
                        3'b100: begin
                            error_counters.CAs_cnt++;
                            `uvm_info(get_type_name(), $sformatf("RX_STR_ERR_SB: Detected CA Completion - Tag: 0x%0h, Addr: 0x%0h", rx_txn.txn_data.cpl.tag, rx_txn.txn_data.cpl.addr), UVM_LOW);
                        end
                        default: ;
                    endcase
                    if(rx_txn.txn_data.cpl.dllp_abort || rx_txn.txn_data.cpl.tlp_abort) begin
                        error_counters.tlp_or_dllp_abort_err_cnt++;
                        `uvm_info(get_type_name(), $sformatf("RX_STR_ERR_SB: Detected TLP/DLLP ABORT Completion - Tag: 0x%0h, Addr: 0x%0h", rx_txn.txn_data.cpl.tag, rx_txn.txn_data.cpl.addr), UVM_LOW);
                    end
                end
                else begin // Any other TLP type - check fmt or ttype or both mismatched
                    if(rx_txn.txn_data.cpl.fmt != 2'b00 && rx_txn.txn_data.cpl.fmt != 2'b10) begin
                        error_counters.fmt_mismatch_cnt++;
                        `uvm_info(get_type_name(), $sformatf("RX_STR_ERR_SB: Detected Format Mismatch FMT: 'b%b - Tag: 0x%0h, Addr: 0x%0h", rx_txn.txn_data.cpl.fmt, rx_txn.txn_data.cpl.tag, rx_txn.txn_data.cpl.addr), UVM_LOW);
                    end
                    if(rx_txn.txn_data.cpl.ttype != 5'b01010) begin
                        error_counters.ttype_mismatch_cnt++;
                        `uvm_info(get_type_name(), $sformatf("RX_STR_ERR_SB: Detected TTYPE Mismatch TTYPE: 'b%b - Tag: 0x%0h, Addr: 0x%0h", rx_txn.txn_data.cpl.ttype, rx_txn.txn_data.cpl.tag, rx_txn.txn_data.cpl.addr), UVM_LOW);
                    end
                end
            end
        end
    endtask

endclass