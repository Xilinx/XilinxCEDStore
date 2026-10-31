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


`uvm_analysis_imp_decl(_rx_pkt)
`uvm_analysis_imp_decl(_tx_pkt)

import pcie_str_pkg::*;
import pcie_rp_pkg::*;
import pcie_intf_pkg::*;
import test_param_pkg::*;

class rp_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(rp_scoreboard)

    uvm_analysis_imp_tx_pkt #(apci_packet, rp_scoreboard) txp;
    uvm_analysis_imp_rx_pkt #(apci_packet, rp_scoreboard) rxp;

    virtual link_if.monitor_mp link_vif_rp;

    // Simple struct for address communication
    typedef struct {
        logic [63:0] address;
        bit is_read; // 1 = read, 0 = write
    } addr_msg_t;

    // TLM import to receive addresses
    uvm_analysis_imp #(addr_msg_t, rp_scoreboard) addr_imp;

    uvm_analysis_port #(apci_tlp) rx_ap;
    uvm_analysis_port #(apci_tlp) tx_ap;

    uvm_analysis_port #(apci_tlp) mem_rx_ap;
    uvm_analysis_port #(apci_tlp) mem_tx_ap;

    apci_tlp tx_tlps[$];
    apci_tlp rx_tlps[$];

    // Define below variables according to testbench configuration
    logic flit_mode = 1; // 0: non-flit, 1: flit; set from the test in build_phase
    logic is_64bit_bar = test_param_pkg::IS_64BIT_BAR; // 0: 32 bit BAR, 1: 64 bit BAR
    bit [15:0] expected_bdf = test_param_pkg::TEST_BDF; // To be set from test


    int msg_dropped_cnt = 0;   // Message TLPs dropped by design

    bit tag_in_use[bit [7:0]]; // Track tags in use for RX TLPs
    bit any_tags_in_use;
    logic mem_start = 0;

    // Queues to track expected addresses and reg_no for RX TLPs
    logic [63:0] addr_to_match;
    logic [63:0] wr_addr_queue[$];
    logic [63:0] rd_addr_queue[$];


    typedef struct {
        bit[31:0] data[];  // Array to store all DWs
        int length;        // Number of DWs
    } mem_data_t;
    
    // Associate address with data
    mem_data_t mem_data[logic [63:0]];

    bit [63:0] addr_for_tag[logic [7:0]];  // Array to store addresses for each tag

    int mem_start_tag = -1;
    logic mem_cpl_check_start = 0;


    function new(string name, uvm_component parent);
        super.new(name, parent);
        txp = new("txp", this);
        rxp = new("rxp", this);
        addr_imp = new("addr_imp", this);

        rx_ap = new("rx_ap", this);
        tx_ap = new("tx_ap", this);

        mem_rx_ap = new("mem_rx_ap", this);
        mem_tx_ap = new("mem_tx_ap", this);
    endfunction

    // Simple write method - just add the address to the appropriate queue
    function void write(addr_msg_t addr_msg);
        if(addr_msg.is_read) begin
            // Add read address to queue
            rd_addr_queue.push_back(addr_msg.address);
            `uvm_info(get_type_name(), $sformatf("Added read address to queue[%0d]: 0x%016h", 
                      rd_addr_queue.size()-1, addr_msg.address), UVM_HIGH)
        end else begin
            // Add write address to queue
            wr_addr_queue.push_back(addr_msg.address);
            `uvm_info(get_type_name(), $sformatf("Added write address to queue[%0d]: 0x%016h", 
                      wr_addr_queue.size()-1, addr_msg.address), UVM_HIGH)
        end
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        begin
            int fm;
            if (uvm_config_db#(int)::get(this, "", "flit_mode", fm)) flit_mode = fm;
        end
        if (!uvm_config_db#(virtual link_if.monitor_mp)::get(this,"","link_if", link_vif_rp)) begin
            `uvm_fatal(get_type_name(), "link_if.monitor_mp is not set");
        end

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    //RUN PHASE

    virtual task run_phase(uvm_phase phase);
        fork
            forever begin
                #1ps
                if(rx_tlps.size() > 0) begin
                    collect_rx_tlps();
                end
                if(link_vif_rp.link_down) begin
                    mem_start_tag = -1;
                    mem_start = 0;
                    mem_cpl_check_start = 0;
                    tag_in_use = '{default: '0};
                end
            end
        join_none

        fork
            forever begin
                #1ps
                if(tx_tlps.size() > 0) begin
                    collect_tx_tlps();
                end
                if(link_vif_rp.link_down) begin
                    mem_start_tag = -1;
                    mem_start = 0;
                    mem_cpl_check_start = 0;
                    tag_in_use = '{default: '0};
                end
            end
        join_none
    endtask

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        any_tags_in_use = 0;
        foreach(tag_in_use[i]) begin
            if(tag_in_use[i]) begin
                any_tags_in_use = 1;
                break;
            end
        end
        if(any_tags_in_use) begin
            `uvm_error(get_type_name(), "Some tags are still in use at end of simulation:")

            foreach(tag_in_use[i]) begin
                if(tag_in_use[i]) begin
                    `uvm_error(get_type_name(), $sformatf("Tag still in use: %0d", i))
                end
            end
        end
        else begin
            `uvm_info(get_type_name(), "All tags released at end of simulation", UVM_LOW)
        end
    endfunction

    // EP transmitted this packet
    function void write_tx_pkt(input apci_packet p);
        apci_tlp tlp;
        if ($cast(tlp, p)) begin
            `uvm_info(get_type_name(), $sformatf("sb received Avery TX TLP: %s (%0d)", tlp.kind.name(), tlp.kind), UVM_MEDIUM)
        end else begin
            `uvm_info(get_type_name(), "sb received non-TLP Avery TX packet", UVM_MEDIUM)
        end
        if (uvm_report_enabled(UVM_HIGH, UVM_INFO, get_type_name())) p.print();
        tx_tlps.push_back(tlp);
    endfunction

    // EP received this packet
    function void write_rx_pkt(input apci_packet p);
        apci_tlp tlp;
        if ($cast(tlp, p)) begin
            `uvm_info(get_type_name(), $sformatf("sb received Avery RX TLP: %s (%0d)", tlp.kind.name(), tlp.kind), UVM_MEDIUM)
        end else begin
            `uvm_info(get_type_name(), "sb received non-TLP Avery RX packet", UVM_MEDIUM)
        end
        if (uvm_report_enabled(UVM_HIGH, UVM_INFO, get_type_name())) p.print();
        rx_tlps.push_back(tlp);
    endfunction

    function void print_tx_tlps();
        `uvm_info(get_type_name(), $sformatf("Printing all TX TLPs (Total: %0d):", tx_tlps.size()), UVM_MEDIUM)
        foreach (tx_tlps[i]) begin
            `uvm_info(get_type_name(), $sformatf("TX TLP[%0d]: %s (%0d)", i, tx_tlps[i].kind.name(), tx_tlps[i].kind), UVM_MEDIUM)
            tx_tlps[i].print();
        end
    endfunction

    function void print_rx_tlps();
        `uvm_info(get_type_name(), $sformatf("Printing all RX TLPs (Total: %0d):", rx_tlps.size()), UVM_MEDIUM)
        foreach (rx_tlps[i]) begin
            `uvm_info(get_type_name(), $sformatf("RX TLP[%0d]: %s (%0d)", i, rx_tlps[i].kind.name(), rx_tlps[i].kind), UVM_MEDIUM)
            rx_tlps[i].print();
        end
    endfunction



    // RX packets (TX of cpm6):

    task collect_rx_tlps();
        apci_tlp rx_tlp;
        rx_tlp = rx_tlps.pop_front();

        // Process the received RX TLP
        case(rx_tlp.kind)
            APCI_TLP_mrd:
                begin
                    // Handle Memory Read Request
                    case(flit_mode)
                        0: begin
                            // Non-flit mode
                            if(is_64bit_bar) begin
                                // 64 bit BAR
                                // rx_tlp.u.mem64. //fmt[2:0], typ[4:0], length, req_id, tag, lbe, fbe, addr - {dw_addr[63:2],ph[1:0]}
                                // rx_tlp.payload //variable size
                                check_and_add_tag(rx_tlp.u.mem64.tag);
                                mem_start_tag = !mem_start ? rx_tlp.u.mem64.tag : mem_start_tag;
                                mem_rx_ap.write(rx_tlp);
                            end
                            else begin
                                // 32 bit BAR
                                // rx_tlp.u.mem32. //fmt[2:0], typ[4:0], length, req_id, tag, lbe, fbe, addr - {dw_addr[31:2],ph[1:0]}
                                // rx_tlp.payload //variable size
                                check_and_add_tag(rx_tlp.u.mem32.tag);
                                mem_start_tag = !mem_start ? rx_tlp.u.mem32.tag : mem_start_tag;
                                mem_rx_ap.write(rx_tlp);
                            end
                        end
                        1: begin
                            // Flit mode
                            if(is_64bit_bar) begin
                                // 64 bit BAR
                                // rx_tlp.u.fm_mem64. //typ[7:0], length, req_id, tag, addr - {dw_addr[63:2],ph[1:0]}
                                // rx_tlp.payload //variable size
                                check_and_add_tag(rx_tlp.u.fm_mem64.tag);
                                mem_start_tag = !mem_start ? rx_tlp.u.fm_mem64.tag : mem_start_tag;
                                mem_rx_ap.write(rx_tlp);
                            end
                            else begin
                                // 32 bit BAR
                                // rx_tlp.u.fm_mem32. //typ[7:0], length, req_id, tag, addr - {dw_addr[31:2],ph[1:0]}
                                // rx_tlp.payload //variable size
                                check_and_add_tag(rx_tlp.u.fm_mem32.tag);
                                mem_start_tag = !mem_start ? rx_tlp.u.fm_mem32.tag : mem_start_tag;
                                mem_rx_ap.write(rx_tlp);
                            end
                        end
                        default: begin
                            `uvm_fatal(get_type_name(), "Invalid flit_mode value")
                        end
                    endcase
                    mem_start = 1;
                end
            APCI_TLP_mwr:
                begin
                    // Handle Memory Write Request
                    case(flit_mode)
                        0: begin
                            // Non-flit mode
                            if(is_64bit_bar) begin
                                // 64 bit BAR
                                // rx_tlp.u.mem64. //fmt[2:0], typ[4:0], length, req_id, tag, lbe, fbe, addr - {dw_addr[63:2],ph[1:0]}
                                // rx_tlp.payload //variable size
                                check_header_fields({rx_tlp.u.mem64.fmt,rx_tlp.u.mem64.typ}, rx_tlp.u.mem64.length, rx_tlp.u.mem64.req_id, rx_tlp.u.mem64.lbe, rx_tlp.u.mem64.fbe);
                                mem_rx_ap.write(rx_tlp);
                            end
                            else begin
                                // 32 bit BAR
                                // rx_tlp.u.mem32. //fmt[2:0], typ[4:0], length, req_id, tag, lbe, fbe, addr - {dw_addr[31:2],ph[1:0]}
                                // rx_tlp.payload //variable size
                                check_header_fields({rx_tlp.u.mem32.fmt,rx_tlp.u.mem32.typ}, rx_tlp.u.mem32.length, rx_tlp.u.mem32.req_id, rx_tlp.u.mem32.lbe, rx_tlp.u.mem32.fbe);
                                mem_rx_ap.write(rx_tlp);
                            end
                        end
                        1: begin
                            // Flit mode
                            if(is_64bit_bar) begin
                                // 64 bit BAR
                                // rx_tlp.u.fm_mem64. //typ[7:0], length, req_id, tag, addr - {dw_addr[63:2],ph[1:0]}
                                // rx_tlp.payload //variable size
                                // NOTE: no lbe fbe present in flit mode
                                check_header_fields(rx_tlp.u.fm_mem64.typ, rx_tlp.u.fm_mem64.length, rx_tlp.u.fm_mem64.req_id, -1, -1);
                                mem_rx_ap.write(rx_tlp);
                            end
                            else begin
                                // 32 bit BAR
                                // rx_tlp.u.fm_mem32. //typ[7:0], length, req_id, tag, addr - {dw_addr[31:2],ph[1:0]}
                                // rx_tlp.payload //variable size
                                // NOTE: no lbe fbe present in flit mode
                                check_header_fields(rx_tlp.u.fm_mem32.typ, rx_tlp.u.fm_mem32.length, rx_tlp.u.fm_mem32.req_id, -1, -1);
                                mem_rx_ap.write(rx_tlp);
                            end
                        end
                        default: begin
                            `uvm_fatal(get_type_name(), "Invalid flit_mode value")
                        end
                    endcase
                end
            APCI_TLP_cfgrd0:
                begin
                    // Handle Config Read Request
                    // check if addr matches next addr from ep rom
                    case(flit_mode)
                        0: begin
                            // Non-flit mode
                            // rx_tlp.u.cfg. //fmt[2:0], typ[4:0], length, req_id, tag, lbe, fbe, bdf (cmpl id), reg_no {ext[3:0], low[5:0]}
                            // rx_tlp.payload //variable size
                            check_and_add_tag(rx_tlp.u.cfg.tag);
                            `uvm_info(get_type_name(), $sformatf("About to send RX TLP (cfg read) to ep_config_sb:%s (%0d)", rx_tlp.kind.name(), rx_tlp.kind), UVM_MEDIUM)
                            rx_ap.write(rx_tlp);
                            `uvm_info(get_type_name(), $sformatf("sent RX TLP (cfg read) to ep_config_sb: %s (%0d)", rx_tlp.kind.name(), rx_tlp.kind), UVM_MEDIUM)

                        end
                        1: begin
                            // Flit mode
                            // rx_tlp.u.fm_cfg. //typ[7:0], length, req_id, tag, bdf (cmpl id), reg_no {ext[3:0], low[5:0]}
                            // rx_tlp.payload //variable size
                            check_and_add_tag(rx_tlp.u.fm_cfg.tag);
                            rx_ap.write(rx_tlp); 
                        end
                        default: begin
                            `uvm_fatal(get_type_name(), "Invalid flit_mode value")
                        end
                    endcase
                end
            APCI_TLP_cfgwr0:
                begin
                    // Handle Config Write Request
                    // store data in cfg space model (based on offsets as addr)
                    // see if BAR base matches calc bar( this would be updated once TX(cpm6 rx) BAR write is received)
                    // check if addr matches next addr from ep rom
                    case(flit_mode)
                        0: begin
                            // Non-flit mode
                            // rx_tlp.u.cfg. //fmt[2:0], typ[4:0], length, req_id, tag, lbe, fbe, bdf (cmpl id), reg_no {ext[3:0], low[5:0]}
                            // rx_tlp.payload //variable size
                            `uvm_info(get_type_name(), $sformatf("About to send RX TLP (cfg write) to ep_config_sb: %s (%0d)", rx_tlp.kind.name(), rx_tlp.kind), UVM_MEDIUM);
                            rx_ap.write(rx_tlp); 
                            `uvm_info(get_type_name(), $sformatf("sent RX TLP (cfg write) to ep_config_sb: %s (%0d)", rx_tlp.kind.name(), rx_tlp.kind), UVM_MEDIUM);
                            check_and_add_tag(rx_tlp.u.cfg.tag);
                        end
                        1: begin
                            // Flit mode
                            // rx_tlp.u.fm_cfg. //typ[7:0], length, req_id, tag, bdf (cmpl id), reg_no {ext[3:0], low[5:0]}
                            // rx_tlp.payload //variable size
                            rx_ap.write(rx_tlp); 
                            check_and_add_tag(rx_tlp.u.fm_cfg.tag);
                        end
                        default: begin
                            `uvm_fatal(get_type_name(), "Invalid flit_mode value")
                        end
                    endcase
                end
            APCI_TLP_msg, APCI_TLP_msgd:
                begin
                    msg_dropped_cnt++;
                    `uvm_warning(get_type_name(), $sformatf(
                        "RX Message TLP (code 0x%02h) received - RP design does not process messages, dropping by design",
                        rx_tlp.is_flit_mode ? rx_tlp.u.fm_msg.msg_code : rx_tlp.u.msg.msg_code))
                end
            default:
                begin
                    // throw uvm warning for other tlp types
                    `uvm_warning(get_type_name(), $sformatf("RX TLP kind not generated from RP DUT: kind = %s (%0d)", rx_tlp.kind.name(), rx_tlp.kind))
                end
        endcase
    endtask

    // TX packets (RX of cpm6):
    task collect_tx_tlps();
        apci_tlp tx_tlp;
        logic [63:0] address;
        tx_tlp = tx_tlps.pop_front();
        #2ns;
        // Process the received TX TLP
        case(tx_tlp.kind)
            APCI_TLP_mrd:
                begin
                    // Handle Memory Read Request
                    // throw uvm error if memrd
                    `uvm_error(get_type_name(), "TX TLP Memory Read Request received, which is unexpected");
                end
            APCI_TLP_mwr:
                begin
                    // Handle Memory Write Request
                    // throw uvm error if memwr
                    `uvm_error(get_type_name(), "TX TLP Memory Write Request received, which is unexpected");
                end
            APCI_TLP_cpl:
                begin
                    // Handle Completion without Data
                    // release tag from tag in use
                    // check for any errors - UR, CA, aborts, poisoned, etc.
                    if(flit_mode) begin
                        // Flit mode
                        release_tag(tx_tlp.u.fm_cpl.tag);
                        check_header_fields(tx_tlp.u.fm_cpl.typ, tx_tlp.u.fm_cpl.length, tx_tlp.u.fm_cpl.cpl_id, -1, -1);
                        if(tx_tlp.u.fm_com.ohc[0] == 1'b1) begin
                            check_error_status(tx_tlp.ohc[0].ohc_a5.cpl_status);
                        end
                        tx_ap.write(tx_tlp);
                    end
                    else begin
                        // Non-flit mode
                        release_tag(tx_tlp.u.cpl.tag);
                        check_header_fields({tx_tlp.u.cpl.fmt,tx_tlp.u.cpl.typ}, tx_tlp.u.cpl.length, tx_tlp.u.cpl.cpl_id, -1, -1);
                        check_error_status(tx_tlp.u.cpl.cpl_status);
                        tx_ap.write(tx_tlp);
                    end
                end
            APCI_TLP_cpld:
                begin
                    // Handle Completion with Data
                    if(flit_mode) begin
                        // Flit mode
                        if(mem_start) begin
                            if(mem_cpl_check_start) begin
                                mem_tx_ap.write(tx_tlp);
                            end
                            else begin
                                if(tx_tlp.u.fm_cpl.tag == mem_start_tag) begin
                                    mem_cpl_check_start = 1;
                                    mem_tx_ap.write(tx_tlp);
                                end
                                else begin
                                    `uvm_info(get_type_name(), $sformatf("About to send TX TLP (cfg write) to ep_config_sb: %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind), UVM_MEDIUM)
                                    tx_ap.write(tx_tlp);
                                    `uvm_info(get_type_name(), $sformatf("sent TX TLP (cfg write) to ep_config_sb: %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind), UVM_MEDIUM)
                                end
                            end
                        end
                        else begin
                            `uvm_info(get_type_name(), $sformatf("About to send TX TLP (cfg write) to ep_config_sb: %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind), UVM_MEDIUM)
                            tx_ap.write(tx_tlp);
                            `uvm_info(get_type_name(), $sformatf("sent TX TLP (cfg write) to ep_config_sb: %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind), UVM_MEDIUM)
                        end

                        release_tag(tx_tlp.u.fm_cpl.tag);
                        if(tx_tlp.u.fm_com.ohc[0] == 1'b1) begin
                            check_error_status(tx_tlp.ohc[0].ohc_a5.cpl_status);
                        end
                        check_header_fields(tx_tlp.u.fm_cpl.typ, tx_tlp.u.fm_cpl.length, tx_tlp.u.fm_cpl.cpl_id, -1, -1);
                    end
                    else begin
                        // Non-flit mode
                        if(mem_start) begin
                            if(mem_cpl_check_start) begin
                                mem_tx_ap.write(tx_tlp);
                            end
                            else begin
                                if(tx_tlp.u.cpl.tag == mem_start_tag) begin
                                    mem_cpl_check_start = 1;
                                    mem_tx_ap.write(tx_tlp);
                                end
                                else begin
                                    `uvm_info(get_type_name(), $sformatf("About to send TX TLP (cfg write) to ep_config_sb: %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind), UVM_MEDIUM)
                                    tx_ap.write(tx_tlp);
                                    `uvm_info(get_type_name(), $sformatf("sent TX TLP (cfg write) to ep_config_sb: %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind), UVM_MEDIUM)
                                end
                            end
                        end
                        else begin
                            `uvm_info(get_type_name(), $sformatf("About to send TX TLP (cfg write) to ep_config_sb: %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind), UVM_MEDIUM)
                            tx_ap.write(tx_tlp);
                            `uvm_info(get_type_name(), $sformatf("sent TX TLP (cfg write) to ep_config_sb: %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind), UVM_MEDIUM)
                        end

                        //For both
                        release_tag(tx_tlp.u.cpl.tag);
                        check_error_status(tx_tlp.u.cpl.cpl_status);
                        check_header_fields({tx_tlp.u.cpl.fmt,tx_tlp.u.cpl.typ}, tx_tlp.u.cpl.length, tx_tlp.u.cpl.cpl_id, -1, -1);
                    end
                end
            APCI_TLP_cfgrd:
                begin
                    // Handle Config Read Request
                    // throw uvm error if cfg read
                    `uvm_error(get_type_name(), "TX TLP Config Read Request received, which is unexpected");
                end
            APCI_TLP_cfgwr:
                begin
                    // Handle Config Write Request
                    // throw uvm error if cfg write
                    `uvm_error(get_type_name(), "TX TLP Config Write Request received, which is unexpected");
                end
            APCI_TLP_msg, APCI_TLP_msgd:
                begin
                    // See the matching RX arm. Messages are dropped by design.
                    msg_dropped_cnt++;
                    `uvm_warning(get_type_name(), $sformatf(
                        "TX Message TLP (code 0x%02h) received - RP design does not process messages, dropping by design",
                        tx_tlp.is_flit_mode ? tx_tlp.u.fm_msg.msg_code : tx_tlp.u.msg.msg_code))
                end
            default:
                begin
                    // throw uvm warning for other tlp types
                    `uvm_warning(get_type_name(), $sformatf("TX TLP kind not generated from RP DUT: kind = %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind))
                end
        endcase
    endtask

    function void check_rd_address(logic [63:0] addr);
        logic [63:0] addr_to_match;

        if(rd_addr_queue.size() == 0) begin
            `uvm_error(get_type_name(), "No read addresses available in queue")
            return;
        end

        addr_to_match = rd_addr_queue.pop_front();
        if(addr != addr_to_match) begin
            `uvm_error(get_type_name(), $sformatf("RX TLP memrd address mismatch: expected = 0x%0h, received = 0x%016h", 
                       addr_to_match, addr))
        end
    endfunction

    function void check_wr_address(logic [63:0] addr);
        logic [63:0] addr_to_match;

        if(wr_addr_queue.size() == 0) begin
            `uvm_error(get_type_name(), "No write addresses available in queue")
            return;
        end

        addr_to_match = wr_addr_queue.pop_front();
        if(addr != addr_to_match) begin
            `uvm_error(get_type_name(), $sformatf("RX TLP memwr address mismatch: expected = 0x%0h, received = 0x%016h", 
                       addr_to_match, addr))
        end
    endfunction

    function void check_and_add_tag(logic [7:0] tag);
        if(tag_in_use[tag]) begin
            `uvm_error(get_type_name(), $sformatf("RX TLP tag already in use: tag = 0x%h", tag))
        end else begin
            tag_in_use[tag] = 1;
        end
    endfunction

    function void release_tag(logic [7:0] tag);
        if(!tag_in_use[tag]) begin
            `uvm_error(get_type_name(), $sformatf("TX TLP releasing tag not in use: tag = 0x%h", tag))
        end else begin
            tag_in_use[tag] = 0;
        end
    endfunction

    function void store_addr_for_tag(logic [7:0] tag, logic [63:0] addr);
        addr_for_tag[tag] = addr;
        `uvm_info(get_type_name(), $sformatf("Stored address for tag 0x%h: 0x%h", tag, addr), UVM_MEDIUM)
    endfunction

    function logic [63:0] get_addr_for_tag(logic [7:0] tag);
        `uvm_info(get_type_name(), $sformatf("Retrieved address for tag 0x%h: 0x%h", tag, addr_for_tag[tag]), UVM_MEDIUM)
        return addr_for_tag[tag];
    endfunction
    
    function void memwr_store_data(logic [63:0] addr, bit[31:0] payload[]);
        // Store the entire payload as one entry indexed by address
        mem_data_t entry;
        
        // Allocate and copy data
        entry.length = payload.size();
        entry.data = new[entry.length];
        foreach (payload[i]) begin
            entry.data[i] = payload[i];
        end
        
        // Store at address
        mem_data[addr] = entry;
        
        `uvm_info(get_type_name(), $sformatf("Memory Write at address 0x%h, length: %0d DWs", 
                                      addr, entry.length), UVM_MEDIUM)
    endfunction


    function void check_cpld_data(logic [63:0] addr, bit[31:0] payload[], logic [7:0] tag);
        mem_data_t expected_entry;
        if(!mem_data.exists(addr)) begin
            `uvm_error(get_type_name(), $sformatf("TX TLP Completion with Data received for address 0x%h and tag 0x%h with no prior write", addr, tag))
            return;
        end
        
        expected_entry = mem_data[addr];
        
        if(expected_entry.length != payload.size()) begin
            `uvm_error(get_type_name(), $sformatf("TX TLP Completion with Data length mismatch at address 0x%h: expected %0d DWs, received %0d DWs", 
                                           addr, expected_entry.length, payload.size()))
            return;
        end
        
        foreach (payload[i]) begin
            if(payload[i] != expected_entry.data[i]) begin
                `uvm_error(get_type_name(), $sformatf("TX TLP Completion Data mismatch with Mem Wr data at address 0x%h, DW[%0d]: expected 0x%h, received 0x%h", 
                                               addr, i, expected_entry.data[i], payload[i]))
            end
            if(payload[i] != tag) begin
                `uvm_error(get_type_name(), $sformatf("TX TLP Completion Data mismatch with tag for address 0x%h, DW[%0d]: tag 0x%h, received data 0x%h", 
                                               addr, i, tag, payload[i]))
            end
        end
        
        // Optionally remove the entry after verification
        mem_data.delete(addr);
        `uvm_info(get_type_name(), $sformatf("TX TLP Completion with Data verified successfully at address 0x%h", addr), UVM_MEDIUM)
    endfunction

    function void check_error_status(logic [2:0] status);
        if(status == 3'b010) begin
            `uvm_warning(get_type_name(), "Error Status: CRS (Configuration Retry Status) - EP not ready, retry expected; legal per PCIe spec")
        end
        else if(status != 3'b000) begin
            `uvm_error(get_type_name(), $sformatf("TX TLP Completion with Data/Completion received with error status: 0b%b", status))
            case(status)
                3'b001: `uvm_error(get_type_name(), "Error Status: UR (Unsupported Request)")
                3'b100: `uvm_error(get_type_name(), "Error Status: CA (Abort)")
                default: `uvm_error(get_type_name(), "Error Status: Unknown error code")
            endcase
        end
    endfunction

    function void check_header_fields(logic [7:0] typ, logic [9:0] length, logic [15:0] req_id, logic [3:0] lbe, logic [3:0] fbe);
    endfunction


endclass