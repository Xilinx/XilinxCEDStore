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

import test_param_pkg::*;

class mem_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(mem_scoreboard);

    uvm_analysis_export #(apci_tlp) mem_rq_exp;
    uvm_tlm_analysis_fifo #(apci_tlp) mem_rq_fifo;

    uvm_analysis_export #(apci_tlp) mem_cpl_exp;
    uvm_tlm_analysis_fifo #(apci_tlp) mem_cpl_fifo;

    uvm_analysis_imp #(rp_scoreboard::addr_msg_t, mem_scoreboard) addr_imp;

    virtual link_if.monitor_mp link_vif_mcfg;

    logic is_64bit_bar = test_param_pkg::IS_64BIT_BAR; // 0: 32 bit BAR, 1: 64 bit BAR
    int flit_mode = 1; // 0: non-flit, 1: flit; set from the test in build_phase

    int mem_file_handle;

    logic [63:0] addr_to_match;
    logic [63:0] wr_addr_queue[$];
    logic [63:0] rd_addr_queue[$];
    
    typedef struct {
        bit[31:0] data[];  // Array to store all DWs
        int length;        // Number of DWs
    } mem_data_t;
    
    // Associate address with data
    mem_data_t mem_data[logic [63:0]];

    bit [63:0] addr_for_tag[logic [7:0]]; // Array to store addresses for each tag
    int cpld_err_at_entry = 0;           // data_error_cnt before checking this CplD

    int mem_rd_count = 0;
    int mem_wr_count = 0;
    int mem_cpld_count = 0;
    int data_error_cnt = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mem_rq_exp = new("mem_rq_exp", this);
        mem_rq_fifo = new("mem_rq_fifo", this);
        mem_cpl_exp = new("mem_cpl_exp", this);
        mem_cpl_fifo = new("mem_cpl_fifo", this);

        addr_imp = new("addr_imp", this);
    endfunction

    // Simple write method - just add the address to the appropriate queue
    function void write(rp_scoreboard::addr_msg_t addr_msg);
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
        mem_file_handle = $fopen("memory_txn_log.txt", "w");
        if (!mem_file_handle) begin
            `uvm_fatal(get_type_name(), "Failed to open memory_txn_log.txt");
        end
        else begin
            `uvm_info(get_type_name(), "Memory transaction log file opened: memory_txn_log.txt", UVM_LOW);
            $fwrite(mem_file_handle, "=============================================================\n");
            $fwrite(mem_file_handle, "              MEMORY TRANSACTION LOG\n");
            $fwrite(mem_file_handle, "=============================================================\n");
            $fflush(mem_file_handle);
        end

        if (!uvm_config_db#(virtual link_if.monitor_mp)::get(this,"","link_if", link_vif_mcfg)) begin
            `uvm_fatal(get_type_name(), "link_if.monitor_mp is not set");
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mem_rq_exp.connect(mem_rq_fifo.analysis_export);
        mem_cpl_exp.connect(mem_cpl_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            check_mem_rq_tlps();
            check_mem_cpl_tlps();
            check_link_status();
        join
    endtask

    virtual function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);
        uvm_config_db#(int)::set(null, "*", "mem_scoreboard", data_error_cnt);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Memory Read Count: %0d", mem_rd_count), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Memory Write Count: %0d", mem_wr_count), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Memory Completion Count: %0d", mem_cpld_count), UVM_LOW);

        if (mem_file_handle) begin
            $fwrite(mem_file_handle, "=============================================================\n");
            $fwrite(mem_file_handle, $sformatf("Memory Read Count: %0d\n", mem_rd_count));
            $fwrite(mem_file_handle, $sformatf("Memory Write Count: %0d\n", mem_wr_count));
            $fwrite(mem_file_handle, $sformatf("Memory Completion Count: %0d\n", mem_cpld_count));
            $fwrite(mem_file_handle, "=============================================================\n");
            if(mem_rd_count != mem_cpld_count) begin
                `uvm_error(get_type_name(), $sformatf(
                    "Mismatch between Memory Read Count (%0d) and Completion Count (%0d) - a memory read never got its completion",
                    mem_rd_count, mem_cpld_count));
                $fwrite(mem_file_handle, "MEMORY SCBD: ERROR - Mismatch between Memory Read Count and Completion Count\n");
            end
            if(mem_rd_count != mem_wr_count) begin
                `uvm_error(get_type_name(), $sformatf(
                    "Mismatch between Memory Read Count (%0d) and Write Count (%0d)",
                    mem_rd_count, mem_wr_count));
                $fwrite(mem_file_handle, "MEMORY SCBD: ERROR - Mismatch between Memory Read Count and Write Count\n");
            end
            if(mem_wr_count != pcie_rp_pkg::TRAFFIC_COUNT || mem_rd_count != pcie_rp_pkg::TRAFFIC_COUNT) begin
                `uvm_error(get_type_name(), $sformatf(
                    "Traffic count mismatch - expected %0d, got %0d reads and %0d writes",
                    pcie_rp_pkg::TRAFFIC_COUNT, mem_rd_count, mem_wr_count));
                $fwrite(mem_file_handle, "MEMORY SCBD: ERROR - Mismatch between expected Traffic Count and actual Read/Write Count\n");
                $fwrite(mem_file_handle, $sformatf("Expected Traffic Count: %0d\n", pcie_rp_pkg::TRAFFIC_COUNT));
                $fwrite(mem_file_handle, $sformatf("Actual Memory Read Count: %0d\n", mem_rd_count));
                $fwrite(mem_file_handle, $sformatf("Actual Memory Write Count: %0d\n", mem_wr_count));
            end
            $fflush(mem_file_handle);
            $fclose(mem_file_handle);
        end
    endfunction

    task check_link_status();
        forever begin
            @(posedge link_vif_mcfg.clk);

            if(link_vif_mcfg.link_down) begin
                `uvm_info(get_type_name(), "Link is down. resetting memory TLP counts." , UVM_LOW);
                if(mem_file_handle) begin
                    $fwrite(mem_file_handle, "=============================================================\n");
                    $fwrite(mem_file_handle, "[%0t] Link down detected\n", $time);
                    $fwrite(mem_file_handle, "=============================================================\n");
                    $fflush(mem_file_handle);
                end
                mem_cpld_count = 0;
                mem_rd_count = 0;
                mem_wr_count = 0;
                data_error_cnt = 0;

                while(link_vif_mcfg.link_down) begin
                    @(posedge link_vif_mcfg.clk);
                end
                `uvm_info(get_type_name(), "Link is up." , UVM_LOW);
                if(mem_file_handle) begin
                    $fwrite(mem_file_handle, "=============================================================\n");
                    $fwrite(mem_file_handle, " [%0t] Link back up detected\n", $time);
                    $fwrite(mem_file_handle, "=============================================================\n");
                    $fflush(mem_file_handle);
                end
            end
        end
    endtask

    task check_mem_rq_tlps();
        apci_tlp rq_tlp;
        logic [11:0] tag = 12'hfff;
        forever begin
            mem_rq_fifo.get(rq_tlp);
            `uvm_info(get_type_name(), $sformatf("mem rq sb received mem rd/wr tlp: %s (%0d)", rq_tlp.kind.name(),rq_tlp.kind), UVM_MEDIUM);
            if (mem_file_handle) begin
                $fwrite(mem_file_handle, "Received mem rd/wr tlp: %s (%0d)\n", rq_tlp.kind.name(), rq_tlp.kind);
            end
            case(rq_tlp.kind)
                APCI_TLP_mrd: begin
                    // Handle Memory Read Request TLP
                    case(flit_mode)
                        0: begin
                            // Non-flit mode
                            if(is_64bit_bar) begin
                                // 64-bit BAR handling
                                print_mrd_count();
                                check_rd_address(rq_tlp.u.mem64.addr);
                                store_addr_for_tag(rq_tlp.u.mem64.tag, rq_tlp.u.mem64.addr);
                                check_header_fields({rq_tlp.u.mem64.fmt,rq_tlp.u.mem64.typ}, rq_tlp.u.mem64.length, rq_tlp.u.mem64.req_id, rq_tlp.u.mem64.lbe, rq_tlp.u.mem64.fbe);
                                if(tag == rq_tlp.u.mem64.tag) begin
                                    `uvm_error(get_type_name(), $sformatf("Duplicate tag detected for memrd: %0h", rq_tlp.u.mem64.tag));
                                    $fwrite(mem_file_handle, $sformatf("[ERROR] Duplicate tag detected for memrd: %0h\n", rq_tlp.u.mem64.tag));
                                end
                                tag = rq_tlp.u.mem64.tag;
                            end
                            else begin
                                // 32-bit BAR handling
                                print_mrd_count();
                                check_rd_address({32'b0, rq_tlp.u.mem32.addr});
                                store_addr_for_tag(rq_tlp.u.mem32.tag, {32'b0, rq_tlp.u.mem32.addr});
                                check_header_fields({rq_tlp.u.mem32.fmt,rq_tlp.u.mem32.typ}, rq_tlp.u.mem32.length, rq_tlp.u.mem32.req_id, rq_tlp.u.mem32.lbe, rq_tlp.u.mem32.fbe);
                                if(tag == rq_tlp.u.mem32.tag) begin
                                    `uvm_error(get_type_name(), $sformatf("Duplicate tag detected for memrd: %0h", rq_tlp.u.mem32.tag));
                                    $fwrite(mem_file_handle, $sformatf("[ERROR] Duplicate tag detected for memrd: %0h\n", rq_tlp.u.mem32.tag));
                                end
                                tag = rq_tlp.u.mem32.tag;
                            end
                        end
                        1: begin
                            // Flit mode
                            if(is_64bit_bar) begin
                                // 64-bit BAR handling
                                print_mrd_count();
                                check_rd_address(rq_tlp.u.fm_mem64.addr);
                                store_addr_for_tag(rq_tlp.u.fm_mem64.tag, rq_tlp.u.fm_mem64.addr);
                                check_header_fields(rq_tlp.u.fm_mem64.typ, rq_tlp.u.fm_mem64.length, rq_tlp.u.fm_mem64.req_id, -1, -1);
                            if(tag == rq_tlp.u.fm_mem64.tag) begin
                                    `uvm_error(get_type_name(), $sformatf("Duplicate tag detected for memrd: %0h", rq_tlp.u.fm_mem64.tag));
                                    $fwrite(mem_file_handle, $sformatf("[ERROR] Duplicate tag detected for memrd: %0h\n", rq_tlp.u.fm_mem64.tag));
                                end
                            tag = rq_tlp.u.fm_mem64.tag;
                            end
                            else begin
                                // 32-bit BAR handling
                                print_mrd_count();
                                check_rd_address({32'b0, rq_tlp.u.fm_mem32.addr});
                                store_addr_for_tag(rq_tlp.u.fm_mem32.tag, {32'b0, rq_tlp.u.fm_mem32.addr});
                                check_header_fields(rq_tlp.u.fm_mem32.typ, rq_tlp.u.fm_mem32.length, rq_tlp.u.fm_mem32.req_id, -1, -1);
                                if(tag == rq_tlp.u.fm_mem32.tag) begin
                                    `uvm_error(get_type_name(), $sformatf("Duplicate tag detected for memrd: %0h", rq_tlp.u.fm_mem32.tag));
                                    $fwrite(mem_file_handle, $sformatf("[ERROR] Duplicate tag detected for memrd: %0h\n", rq_tlp.u.fm_mem32.tag));
                                end
                                tag = rq_tlp.u.fm_mem32.tag;
                            end
                        end
                        default: begin
                            `uvm_warning(get_type_name(), $sformatf("MEMORY SCBD: Unknown flit mode: %0d", flit_mode));
                        end
                    endcase
                    $fflush(mem_file_handle);
                    mem_rd_count++;
                end
                APCI_TLP_mwr: begin
                    // Handle Memory Write Request TLP
                    case(flit_mode)
                        0: begin
                            // Non-flit mode
                            if(is_64bit_bar) begin
                                // 64-bit BAR handling
                                print_mwr_count();
                                check_wr_address(rq_tlp.u.mem64.addr);
                                memwr_store_data(rq_tlp.u.mem64.addr, rq_tlp.payload);
                                check_header_fields({rq_tlp.u.mem64.fmt,rq_tlp.u.mem64.typ}, rq_tlp.u.mem64.length, rq_tlp.u.mem64.req_id, rq_tlp.u.mem64.lbe, rq_tlp.u.mem64.fbe);
                            end
                            else begin
                                // 32-bit BAR handling
                                print_mwr_count();
                                check_wr_address({32'b0, rq_tlp.u.mem32.addr});
                                memwr_store_data({32'b0, rq_tlp.u.mem32.addr}, rq_tlp.payload);
                                check_header_fields({rq_tlp.u.mem32.fmt,rq_tlp.u.mem32.typ}, rq_tlp.u.mem32.length, rq_tlp.u.mem32.req_id, rq_tlp.u.mem32.lbe, rq_tlp.u.mem32.fbe);
                            end
                        end
                        1: begin
                            // Flit mode
                            if(is_64bit_bar) begin
                                // 64-bit BAR handling
                                print_mwr_count();
                                check_wr_address(rq_tlp.u.fm_mem64.addr);
                                memwr_store_data(rq_tlp.u.fm_mem64.addr, rq_tlp.payload);
                                check_header_fields(rq_tlp.u.fm_mem64.typ, rq_tlp.u.fm_mem64.length, rq_tlp.u.fm_mem64.req_id, -1, -1);
                            end
                            else begin
                                // 32-bit BAR handling
                                print_mwr_count();
                                check_wr_address({32'b0, rq_tlp.u.fm_mem32.addr});
                                memwr_store_data({32'b0, rq_tlp.u.fm_mem32.addr}, rq_tlp.payload);
                                check_header_fields(rq_tlp.u.fm_mem32.typ, rq_tlp.u.fm_mem32.length, rq_tlp.u.fm_mem32.req_id, -1, -1);
                            end
                        end
                        default: begin
                            `uvm_warning(get_type_name(), $sformatf("MEMORY SCBD: Unknown flit mode: %0d", flit_mode));
                        end
                    endcase
                    mem_wr_count++;
                end
                default: begin
                    `uvm_warning(get_type_name(), $sformatf("MEMORY SCBD: Received unexpected Memory Request TLP kind: %0d", rq_tlp.kind));
                end
            endcase
        end
    endtask

    task check_mem_cpl_tlps();
        apci_tlp cpl_tlp;
        logic [63:0] address;
        forever begin
            #1ns;
            mem_cpl_fifo.get(cpl_tlp);
            #1ns;
            `uvm_info(get_type_name(), $sformatf("mem cpl sb received mem cpl tlp: %s (%0d)", cpl_tlp.kind.name(),cpl_tlp.kind), UVM_MEDIUM);
            cpld_err_at_entry = data_error_cnt;
            case(cpl_tlp.kind)
                APCI_TLP_cpld: begin
                    // Handle Memory Completion with Data TLP
                    if(flit_mode) begin
                        address = get_addr_for_tag(cpl_tlp.u.fm_cpl.tag);
                        check_cpld_data(address, cpl_tlp.payload, cpl_tlp.u.fm_cpl.tag);
                        check_header_fields(cpl_tlp.u.fm_cpl.typ, cpl_tlp.u.fm_cpl.length, cpl_tlp.u.fm_cpl.cpl_id, -1, -1);
                        if(cpl_tlp.u.fm_com.ohc[0] == 1'b1) begin
                            check_error_status(cpl_tlp.ohc[0].ohc_a5.cpl_status);
                        end
                    end
                    else begin
                        address = get_addr_for_tag(cpl_tlp.u.cpl.tag);
                        check_cpld_data(address, cpl_tlp.payload, cpl_tlp.u.cpl.tag);
                        check_header_fields({cpl_tlp.u.cpl.fmt,cpl_tlp.u.cpl.typ}, cpl_tlp.u.cpl.length, cpl_tlp.u.cpl.cpl_id, -1, -1);
                        check_error_status(cpl_tlp.u.cpl.cpl_status);
                    end
                    mem_cpld_count++;
                    begin
                        string cpl_res;
                        if (data_error_cnt == cpld_err_at_entry) cpl_res = "OK";
                        else                                     cpl_res = "MISMATCH";
                        `rp_flow($sformatf(
                            "EP -> RP : CplD   addr 0x%016h  tag 0x%02h  %0d DW  data %s",
                            address,
                            flit_mode ? cpl_tlp.u.fm_cpl.tag : cpl_tlp.u.cpl.tag,
                            flit_mode ? cpl_tlp.u.fm_cpl.length : cpl_tlp.u.cpl.length,
                            cpl_res))
                    end
                end
                default: begin
                    `uvm_warning(get_type_name(), $sformatf("MEMORY SCBD: Received unexpected Memory Completion TLP kind: %0d", cpl_tlp.kind));
                end
            endcase        
        end
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
            if (mem_file_handle) begin
                $fwrite(mem_file_handle, $sformatf("RX TLP memrd address mismatch: expected = 0x%0h, received = 0x%016h\n", 
                       addr_to_match, addr));
            end
            $fflush(mem_file_handle);
        end else begin
            if (mem_file_handle) begin
                $fwrite(mem_file_handle, $sformatf("RX TLP memrd address match: 0x%016h\n", addr));
            end
        end
        $fflush(mem_file_handle);
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
        end else begin
            if (mem_file_handle) begin
                $fwrite(mem_file_handle, $sformatf("RX TLP memwr address match: 0x%016h\n", addr));
            end
        end
    endfunction

    function void store_addr_for_tag(logic [7:0] tag, logic [63:0] addr);
        addr_for_tag[tag] = addr;
        `uvm_info(get_type_name(), $sformatf("Stored address for tag 0x%h: 0x%h", tag, addr), UVM_MEDIUM)
        `rp_flow($sformatf("RP -> EP : MemRd  addr 0x%016h  tag 0x%02h",
                                      addr, tag))
        if(mem_file_handle) begin
            $fwrite(mem_file_handle, $sformatf("Stored address for tag 0x%h: 0x%h\n", tag, addr));
            $fflush(mem_file_handle);
        end
    endfunction

    function logic [63:0] get_addr_for_tag(logic [7:0] tag);
        `uvm_info(get_type_name(), $sformatf("Retrieved address for tag 0x%h: 0x%h", tag, addr_for_tag[tag]), UVM_MEDIUM)
        if (mem_file_handle) begin
            $fwrite(mem_file_handle, $sformatf("Retrieved address for tag 0x%h: 0x%h\n", tag, addr_for_tag[tag]));
            $fflush(mem_file_handle);
        end
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

        if(payload.size() != pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4) begin
            `uvm_error(get_type_name(), $sformatf("Memory Write payload size mismatch at address 0x%h: expected %0d DWs, received %0d DWs", 
                         addr, pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4, payload.size()));
            if(mem_file_handle) begin
                $fwrite(mem_file_handle, $sformatf("[ERROR] Memory Write payload size mismatch at address 0x%h: expected %0d DWs, received %0d DWs\n", 
                             addr, pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4, payload.size()));
                $fflush(mem_file_handle);
            end
        end
        
        `uvm_info(get_type_name(), $sformatf("Memory Write at address 0x%h, length: %0d DWs", 
                                      addr, entry.length), UVM_MEDIUM)
        `rp_flow($sformatf("RP -> EP : MemWr  addr 0x%016h  %0d DW",
                                      addr, entry.length))
        if (mem_file_handle) begin
            $fwrite(mem_file_handle, $sformatf("Memory Write at address 0x%h, length: %0d DWs\n", 
                                      addr, entry.length));
            $fflush(mem_file_handle);
        end
    endfunction

    function void check_cpld_data(logic [63:0] addr, bit[31:0] payload[], logic [7:0] tag);
        mem_data_t expected_entry;
        logic data_error_current = '0;
        if(!mem_data.exists(addr)) begin
            `uvm_error(get_type_name(), $sformatf("TX TLP Completion with Data received for address 0x%h and tag 0x%h with no prior write", addr, tag))
            if(mem_file_handle) begin
                $fwrite(mem_file_handle, $sformatf("[ERROR] TX TLP Completion with Data received for address 0x%h and tag 0x%h with no prior write\n", addr, tag));
                $fflush(mem_file_handle);
            end
            data_error_cnt++;
            return;
        end
        
        expected_entry = mem_data[addr];
        
        if(expected_entry.length != payload.size()) begin
            `uvm_error(get_type_name(), $sformatf("TX TLP Completion with Data length mismatch at address 0x%h: expected %0d DWs, received %0d DWs", 
                                           addr, expected_entry.length, payload.size()))
            if(mem_file_handle) begin
                $fwrite(mem_file_handle, $sformatf("[ERROR] TX TLP Completion with Data length mismatch at address 0x%h: expected %0d DWs, received %0d DWs\n", 
                                           addr, expected_entry.length, payload.size()));
                $fflush(mem_file_handle);
            end
            data_error_cnt++;
            return;
        end
        
        foreach (payload[i]) begin
            if(payload[i] != expected_entry.data[i]) begin
                `uvm_error(get_type_name(), $sformatf("TX TLP Completion Data mismatch with Mem Wr data at address 0x%h, DW[%0d]: expected 0x%h, received 0x%h", 
                                               addr, i, expected_entry.data[i], payload[i]))
                if(mem_file_handle) begin
                    $fwrite(mem_file_handle, $sformatf("[ERROR] TX TLP Completion Data mismatch with Mem Wr data at address 0x%h, DW[%0d]: expected 0x%h, received 0x%h\n", 
                                               addr, i, expected_entry.data[i], payload[i]));
                    $fflush(mem_file_handle);
                end
                data_error_current = '1;
            end
            if(payload[i] != tag) begin
                `uvm_error(get_type_name(), $sformatf("TX TLP Completion Data mismatch with tag for address 0x%h, DW[%0d]: tag 0x%h, received data 0x%h", 
                                               addr, i, tag, payload[i]))
                if(mem_file_handle) begin
                    $fwrite(mem_file_handle, $sformatf("[ERROR] TX TLP Completion Data mismatch with tag for address 0x%h, DW[%0d]: tag 0x%h, received data 0x%h\n", 
                                               addr, i, tag, payload[i]));
                    $fflush(mem_file_handle);
                    data_error_current = '1;
                end
            end
        end

        if(data_error_current) begin
            data_error_cnt++;
        end
        
        mem_data.delete(addr);
        `uvm_info(get_type_name(), $sformatf("TX TLP Completion with Data verified successfully at address 0x%h", addr), UVM_MEDIUM)
        if(mem_file_handle) begin
            $fwrite(mem_file_handle, $sformatf("TX TLP Completion with Data verified successfully at address 0x%h\n", addr));
            $fflush(mem_file_handle);
        end
    endfunction

    function void check_error_status(logic [2:0] status);
        // Check for UR, CA, aborts, poisoned, etc.
        if(status != 3'b000) begin
            `uvm_error(get_type_name(), $sformatf("TX TLP Completion with Data/Completion received with error status: 0b%b", status))
            if(mem_file_handle) begin
                $fwrite(mem_file_handle, $sformatf("[ERROR] TX TLP Completion with Data/Completion received with error status: 0b%b\n", status));
                $fflush(mem_file_handle);
            end
            case(status)
                3'b001: `uvm_error(get_type_name(), "Error Status: UR (Unsupported Request)")
                3'b010: `uvm_error(get_type_name(), "Error Status: CRS (Configuration Retry Status)")
                3'b100: `uvm_error(get_type_name(), "Error Status: CA (Abort)")
                default: `uvm_error(get_type_name(), "Error Status: Unknown error code")
            endcase
        end
    endfunction

    function void check_header_fields(logic [7:0] typ, logic [9:0] length, logic [15:0] req_id, logic [3:0] lbe, logic [3:0] fbe);
        if(mem_file_handle) begin
            $fwrite(mem_file_handle, $sformatf("Checking header fields: typ=0b%b, length=%0d, req_id=0x%h, lbe=0b%b, fbe=0b%b\n", 
                               typ, length, req_id, lbe, fbe));
            case(typ)
                7'b100_0000: begin //Mem Wr 32
                    if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4)) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 32 length mismatch: expected = %0d DWs, received = %0d DWs", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Wr 32 length mismatch: expected = %0d DWs, received = %0d DWs\n", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length));
                    end
                    if(lbe != 4'b1111 || fbe != 4'b1111) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                            lbe, fbe))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Wr 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                            lbe, fbe));
                    end
                    if(req_id != '0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 32 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                            req_id))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Wr 32 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                            req_id));
                    end
                end
                7'b110_0000: begin //Mem Wr 64
                    if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4)) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 64 length mismatch: expected = %0d DWs, received = %0d DWs", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Wr 64 length mismatch: expected = %0d DWs, received = %0d DWs\n", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length));
                    end
                    if(lbe != 4'b1111 || fbe != 4'b1111) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 64 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                            lbe, fbe))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Wr 64 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                            lbe, fbe));
                    end
                    if(req_id != '0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 64 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                            req_id))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Wr 64 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                            req_id));
                    end
                end
                7'b000_0000: begin //Mem Rd 32 Non Flit Mode
                    if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4)) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 32 length mismatch: expected = %0d DWs, received = %0d DWs", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Rd 32 length mismatch: expected = %0d DWs, received = %0d DWs\n", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length));
                    end
                    if(lbe != 4'b1111 || fbe != 4'b1111) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                            lbe, fbe))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Rd 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                            lbe, fbe));
                    end
                    if(req_id != '0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 32 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                            req_id))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Rd 32 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                            req_id));
                    end
                    if(flit_mode == 1) begin
                        `uvm_error(get_type_name(), "RX TLP Mem Wr 32 received in flit mode, but expected non-flit mode")
                        $fwrite(mem_file_handle, "[ERROR] RX TLP Mem Wr 32 received in flit mode, but expected non-flit mode\n");
                    end
                end
                7'b000_0011: begin //Mem Rd 32 Flit Mode
                    if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4)) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 32 length mismatch: expected = %0d DWs, received = %0d DWs", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Rd 32 length mismatch: expected = %0d DWs, received = %0d DWs\n", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length));
                    end
                    if(lbe != 4'b1111 || fbe != 4'b1111) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                            lbe, fbe))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Rd 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                            lbe, fbe));
                    end
                    if(req_id != '0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 32 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                            req_id))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Rd 32 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                            req_id));
                    end
                    if(flit_mode == 0) begin
                        `uvm_error(get_type_name(), "RX TLP Mem Wr 32 received in non-flit mode, but expected flit mode")
                        $fwrite(mem_file_handle, "[ERROR] RX TLP Mem Wr 32 received in non-flit mode, but expected flit mode\n");
                    end
                end
                7'b010_0000: begin //Mem Rd 64
                    if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4)) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 64 length mismatch: expected = %0d DWs, received = %0d DWs", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Rd 64 length mismatch: expected = %0d DWs, received = %0d DWs\n", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length));
                    end
                    if(lbe != 4'b1111 || fbe != 4'b1111) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 64 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                            lbe, fbe))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Rd 64 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                            lbe, fbe));
                    end
                    if(req_id != '0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 64 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                            req_id))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Mem Rd 64 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                            req_id));
                    end
                end
                7'b000_0100: begin //Cfg Rd 0
                    if(length != 1) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 0 length mismatch: expected = 1 DW, received = %0d DWs", 
                                            length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Rd 0 length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                            length));
                    end
                    if(lbe != 4'b0000 || fbe != 4'b1111) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 0 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                            lbe, fbe))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Rd 0 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                            lbe, fbe));
                    end
                    if(req_id != '0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 0 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                            req_id))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Rd 0 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                            req_id));
                    end
                end
                7'b000_0101: begin //Cfg Rd 1
                    if(length != 1) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 1 length mismatch: expected = 1 DW, received = %0d DWs", 
                                            length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Rd 1 length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                            length));
                    end
                    if(lbe != 4'b0000 || fbe != 4'b1111) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 1 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                            lbe, fbe))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Rd 1 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                            lbe, fbe));
                    end
                    if(req_id != '0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 1 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                            req_id))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Rd 1 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                            req_id));
                    end
                end
                7'b100_0100: begin //Cfg Wr 0
                    if(length != 1) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 0 length mismatch: expected = 1 DW, received = %0d DWs", 
                                            length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Wr 0 length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                            length));
                    end
                    if(lbe != 4'b0000 || fbe != 4'b1111) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 0 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                            lbe, fbe))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Wr 0 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                            lbe, fbe));
                    end
                    if(req_id != '0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 0 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                            req_id))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Wr 0 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                            req_id));
                    end
                end
                7'b100_0101: begin //Cfg Wr 1
                    if(length != 1) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 1 length mismatch: expected = 1 DW, received = %0d DWs", 
                                            length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Wr 1 length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                            length));
                    end
                    if(lbe != 4'b0000 || fbe != 4'b1111) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 1 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                            lbe, fbe))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Wr 1 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                            lbe, fbe));
                    end
                    if(req_id != '0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 1 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                            req_id))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Cfg Wr 1 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                            req_id));
                    end
                end
                7'b000_1010: begin //Cpl
                    if(length != 0) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Completion length mismatch: expected = 1 DW, received = %0d DWs", 
                                            length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Completion length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                            length));
                    end
                end
                7'b100_1010: begin //Cpl Data
                    if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4) && length != 1) begin
                        `uvm_error(get_type_name(), $sformatf("RX TLP Completion with Data length mismatch: expected = %0d or %0d DWs, received = %0d DWs", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), 1, length))
                        $fwrite(mem_file_handle, $sformatf("[ERROR] RX TLP Completion with Data length mismatch: expected = %0d or %0d DWs, received = %0d DWs\n", 
                                            (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), 1, length));
                    end
                end
                7'b011_0xxx: begin //MSG
                    `uvm_info(get_type_name(), "RX TLP Message type received, no specific checks implemented", UVM_LOW)
                    $fwrite(mem_file_handle, $sformatf("[INFO] RX TLP Message type received, no specific checks implemented\n"));
                end
                7'b111_0xxx: begin //MSG
                    `uvm_info(get_type_name(), "RX TLP Message type received, no specific checks implemented", UVM_LOW)
                    $fwrite(mem_file_handle, $sformatf("[INFO] RX TLP Message type received, no specific checks implemented\n"));
                end
                default: begin
                    `uvm_warning(get_type_name(), $sformatf("RX TLP type 0b%b not specifically checked in header fields", typ))
                    $fwrite(mem_file_handle, $sformatf("[WARNING] RX TLP type 0b%b not specifically checked in header fields\n", typ));
                end
            endcase
            $fwrite(mem_file_handle, "\n");
            $fflush(mem_file_handle);
        end
    endfunction

    function void print_mwr_count();
        if (mem_file_handle) begin
            $fwrite(mem_file_handle, $sformatf("Processing Memory Write TLP number: %0d\n", mem_wr_count+1));
            $fflush(mem_file_handle);
        end
    endfunction

    function void print_mrd_count();
        if (mem_file_handle) begin
            $fwrite(mem_file_handle, $sformatf("Processing Memory Read TLP number: %0d\n", mem_rd_count+1));
            $fflush(mem_file_handle);
        end
    endfunction

endclass