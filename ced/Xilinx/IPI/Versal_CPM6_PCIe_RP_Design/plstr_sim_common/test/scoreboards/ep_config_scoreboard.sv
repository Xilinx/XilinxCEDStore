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

class ep_config_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ep_config_scoreboard)
    
    // TLM port to send addresses to rp_scoreboard

    uvm_analysis_port #(rp_scoreboard::addr_msg_t) addr_port;

    virtual link_if.monitor_mp link_vif_epcfg;
    
    // Simple parameters
    int TRAFFIC_COUNT = pcie_rp_pkg::TRAFFIC_COUNT;
    int ACTUAL_PAYLOAD_SIZE_BYTE = pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE;
    
    uvm_analysis_export #(apci_tlp) rx_exp;
    uvm_analysis_export #(apci_tlp) tx_exp;

    uvm_tlm_analysis_fifo #(apci_tlp) rx_fifo;
    uvm_tlm_analysis_fifo #(apci_tlp) tx_fifo;

    uvm_analysis_port #(cpl_txn) cpl_ap;
    uvm_tlm_analysis_fifo #(cpl_txn) cpl_fifo;
    cpl_txn tx_cpl_txn; 

    // Declare any necessary handles or variables here
    apci_tlp tx_tlps[$];
    apci_tlp rx_tlps[$];

    // Define below variables according to testbench configuration
    logic flit_mode = 1; // 0: non-flit, 1: flit; set from the test in build_phase
    logic is_64bit_bar = test_param_pkg::IS_64BIT_BAR; // 0: 32 bit BAR, 1: 64 bit BAR
    bit [15:0] expected_bdf = test_param_pkg::TEST_BDF;
    logic [9:0] reg_no_to_match;


    typedef struct {
        logic [7:0] tag;
        logic [15:0] bdf;
        logic [9:0] reg_no;
    } bar_tag_t;

    bar_tag_t bar_tags[$]; // Queue to store BAR tags

    // Device/Vendor ID detection logging
    int dev_vendor_id_retry_cnt = 0;
    logic check_device_vendor_id = 0;
    int dev_vendor_id_file_handle;
    string dev_vendor_id_log_file = "device_vendor_id_log.txt";

    // BAR handling 
    int bar_config_file_handle;
    string bar_config_log_file = "bar_config_log.txt";
    bit bar_calculation_complete = 0;

    int ep_config_file_handle;
    string ep_config_log_file = "ep_config_log.txt";

    int seq_count [6];

    // BAR structs
    logic [31:0] bar_base [5:0];
    logic [31:0] bar_sizes [5:0];
    logic [31:0] bar_rcvd_values [5:0];
    
    // Queue to store expected BAR base addresses for completion matching
    logic [31:0] bar_base_queue[$];

    
    logic [63:0] addr_mem_rom[0:pcie_rp_pkg::EP_ROM_SIZE-1];
    logic [31:0] expected_data_mem_rom[0:pcie_rp_pkg::EP_ROM_SIZE-1];
    logic [31:0] data_mem_rom[0:pcie_rp_pkg::EP_ROM_SIZE-1];
    logic [31:0] type_mem_rom[0:pcie_rp_pkg::EP_ROM_SIZE-1];

    logic [9:0] cfg_addr_queue[$];

    int cfgrd_cnt = 0;
    int cfgwr_cnt = 0;
    int cpl_cnt = 0;
    int cpl_data_cnt = 0;
    int cpl_err_cnt = 0;
    int cfg_retry_cnt = 0;
    int cfg_ur_cnt = 0;
    int cfg_ca_cnt = 0;

    // Published for the end-of-test summary in test_rp_traffic.report_phase.
    int  rom_covered        = 0;   // ROM entries actually exercised
    bit  bar_base_ok[6];           // set per BAR when its base read back correctly
    int  dev_vendor_id_seen = -1;  // -1 until the Device/Vendor ID completion arrives
    bit  dev_vendor_id_ok   = 0;   // set when it matched the ROM

    int total_ep_errors = 0;
    int ep_data_error_cnt = 0;

    typedef struct {
        logic [31:0] addr;
        bit[31:0] data[];  // Array to store all DWs
        int length;        // Number of DWs
    } cfg_data_t;

    // Change from dynamic arrays to associative arrays
    cfg_data_t cfg_space[logic [7:0]];        // ← Associative array indexed by tag
    typedef struct {
        int          rom_index;   // -1 = transaction is not described by the ROM
        logic [31:0] expected;
    } rom_binding_t;

    // ROM[0] is the device-detect entry.
    localparam int EP_ROM_DETECT_IDX = 0;

    int           ep_rom_ptr = 0;
    bit           rom_hit[pcie_rp_pkg::EP_ROM_SIZE];
    rom_binding_t tag_rom[logic [7:0]];
    int           rom_extra_txn_cnt  = 0;
    int           rom_crs_rewind_cnt = 0;

    function new(string name = "ep_config_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        rx_exp = new("rx_exp", this);
        tx_exp = new("tx_exp", this);

        rx_fifo = new("rx_fifo", this);
        tx_fifo = new("tx_fifo", this);

        cpl_ap = new("cpl_ap", this);
        cpl_fifo = new("cpl_fifo", this);
        
        addr_port = new("addr_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        begin
            int fm;
            if (uvm_config_db#(int)::get(this, "", "flit_mode", fm)) flit_mode = fm;
        end

        // Open device/vendor ID log file
        dev_vendor_id_file_handle = $fopen(dev_vendor_id_log_file, "w");
        if (dev_vendor_id_file_handle == 0) begin
            `uvm_error(get_type_name(), $sformatf("Failed to open device/vendor ID log file: %s", dev_vendor_id_log_file))
        end else begin
            `uvm_info(get_type_name(), $sformatf("Device/Vendor ID log file opened: %s", dev_vendor_id_log_file), UVM_LOW)
            
            // Write header to log file
            $fwrite(dev_vendor_id_file_handle, "=============================================================\n");
            $fwrite(dev_vendor_id_file_handle, "             DEVICE/VENDOR ID DETECTION LOG\n");
            $fwrite(dev_vendor_id_file_handle, "=============================================================\n");
            $fflush(dev_vendor_id_file_handle);
        end

         // Open BAR configuration log file
        bar_config_file_handle = $fopen(bar_config_log_file, "w");
        if (bar_config_file_handle == 0) begin
            `uvm_error(get_type_name(), $sformatf("Failed to open BAR config log file: %s", bar_config_log_file))
        end else begin
            `uvm_info(get_type_name(), $sformatf("BAR configuration log file opened: %s", bar_config_log_file), UVM_LOW)
            
            // Write header to BAR log file
            $fwrite(bar_config_file_handle, "=============================================================\n");
            $fwrite(bar_config_file_handle, "              BAR CONFIGURATION LOG\n");
            $fwrite(bar_config_file_handle, "=============================================================\n");
        end

        ep_config_file_handle = $fopen(ep_config_log_file, "w");
        if (ep_config_file_handle == 0) begin
            `uvm_error(get_type_name(), $sformatf("Failed to open EP config log file: %s", ep_config_log_file))
        end else begin
            `uvm_info(get_type_name(), $sformatf("EP configuration log file opened: %s", ep_config_log_file), UVM_LOW)
            
            // Write header to EP config log file
            $fwrite(ep_config_file_handle, "=============================================================\n");
            $fwrite(ep_config_file_handle, "              EP CONFIGURATION LOG\n");
            $fwrite(ep_config_file_handle, "=============================================================\n");
        end

        if (!uvm_config_db#(virtual link_if.monitor_mp)::get(this,"","link_if", link_vif_epcfg)) begin
            `uvm_fatal(get_type_name(), "link_if.monitor_mp is not set");
        end

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        rx_exp.connect(rx_fifo.analysis_export);
        tx_exp.connect(tx_fifo.analysis_export);
        cpl_ap.connect(cpl_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        load_ep_rom_data();
        fork
            check_rx_config_tlps();
            check_tx_config_tlps();
            check_link_down();
        join_none;
    endtask

    virtual function void extract_phase(uvm_phase phase);
        foreach (rom_hit[i]) if (rom_hit[i]) rom_covered++;
        super.extract_phase(phase);
        uvm_config_db#(int)::set(null, "*", "ep_config_scoreboard", ep_data_error_cnt);
    endfunction
        
    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);

        // Every ROM entry must have been exercised.
        for (int i = 0; i < pcie_rp_pkg::EP_ROM_SIZE; i++) begin
            if (!rom_hit[i]) begin
                `uvm_error(get_type_name(), $sformatf("ROM[%0d] never exercised: addr 0x%h, %s",
                           i, addr_mem_rom[i][31:0], type_mem_rom[i][0] ? "READ" : "WRITE"))
                total_ep_errors++;
            end
        end

        // A binding still held means its completion never arrived.
        if (tag_rom.num() != 0) begin
            `uvm_error(get_type_name(), $sformatf("%0d config request(s) never completed", tag_rom.num()))
            total_ep_errors++;
        end

        `uvm_info(get_type_name(), $sformatf(
            "ROM coverage: %0d/%0d entries exercised, %0d non-ROM transactions, %0d CRS rewind(s)",
            rom_covered, pcie_rp_pkg::EP_ROM_SIZE, rom_extra_txn_cnt, rom_crs_rewind_cnt), UVM_NONE)

        `uvm_info(get_type_name(), $sformatf("Finalizing scoreboard: %s", get_name()), UVM_LOW)

        `uvm_info(get_type_name(), $sformatf("Total CFG Read TLPs processed: %0d", cfgrd_cnt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total CFG Write TLPs processed: %0d", cfgwr_cnt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total Completion TLPs processed: %0d", cpl_cnt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total Completion Data DWs processed: %0d", cpl_data_cnt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total Config Completion Errors received: %0d", cpl_err_cnt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total CFG Retries detected: %0d", cfg_retry_cnt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total CFG UR errors detected: %0d", cfg_ur_cnt), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total CFG CA errors detected: %0d", cfg_ca_cnt), UVM_LOW)

        if(cfgrd_cnt == (cpl_data_cnt + cfg_retry_cnt)) begin
            `uvm_info(get_type_name(), $sformatf("CFG Read TLPs and Completion Data DWs count match with CFG Retries. = %0d", cfg_retry_cnt), UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in CFG Read TLPs (%0d) and Completion Data DWs (%0d).", cfgrd_cnt, cpl_data_cnt))
        end

        if(cfgwr_cnt == (cpl_cnt - cfg_retry_cnt)) begin
            `uvm_info(get_type_name(), $sformatf("CFG Write TLPs and Completion TLPs count match with CFG Retries. = %0d", cfg_retry_cnt), UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in CFG Write TLPs (%0d) and Completion TLPs (%0d).", cfgwr_cnt, cpl_cnt))
        end

        if(ep_config_file_handle != 0) begin
            $fwrite(ep_config_file_handle, "=============================================================\n");
            $fwrite(ep_config_file_handle, "              EP CONFIGURATION SUMMARY\n");
            $fwrite(ep_config_file_handle, "=============================================================\n");
            $fwrite(ep_config_file_handle, "Total CFG Read TLPs processed: %0d\n", cfgrd_cnt);
            $fwrite(ep_config_file_handle, "Total CFG Write TLPs processed: %0d\n", cfgwr_cnt);
            $fwrite(ep_config_file_handle, "Total Completion TLPs processed: %0d\n", cpl_cnt);
            $fwrite(ep_config_file_handle, "Total Completion Data DWs processed: %0d\n", cpl_data_cnt);
            $fwrite(ep_config_file_handle, "Total Config Completion Errors received: %0d\n", cpl_err_cnt);
            $fwrite(ep_config_file_handle, "Total CFG Retries detected: %0d\n", cfg_retry_cnt);
            $fwrite(ep_config_file_handle, "Total CFG UR errors detected: %0d\n", cfg_ur_cnt);
            $fwrite(ep_config_file_handle, "Total CFG CA errors detected: %0d\n", cfg_ca_cnt);

            if(cfgrd_cnt == (cpl_data_cnt + cfg_retry_cnt)) begin
                $fwrite(ep_config_file_handle, "CFG Read TLPs and Completion Data DWs count match with CFG Retries. = %0d\n", cfg_retry_cnt);
            end else begin
                $fwrite(ep_config_file_handle, "Mismatch in CFG Read TLPs (%0d) and Completion Data DWs (%0d).\n", cfgrd_cnt, cpl_data_cnt);
            end
            if(cfgwr_cnt == (cpl_cnt - cfg_retry_cnt)) begin
                $fwrite(ep_config_file_handle, "CFG Write TLPs and Completion TLPs count match with CFG Retries. = %0d\n", cfg_retry_cnt);
            end else begin
                $fwrite(ep_config_file_handle, "Mismatch in CFG Write TLPs (%0d) and Completion TLPs (%0d).\n", cfgwr_cnt, cpl_cnt);
            end

            if(cfgrd_cnt + cfgwr_cnt == pcie_rp_pkg::EP_ROM_SIZE+12) begin
                $fwrite(ep_config_file_handle, "All expected CFG transactions processed successfully.\n");
            end else begin
                $fwrite(ep_config_file_handle, "Expected CFG transactions (%0d) do not match processed (%0d).\n", pcie_rp_pkg::EP_ROM_SIZE+12, cfgrd_cnt + cfgwr_cnt);
            end

            $fwrite(ep_config_file_handle, "Total EP Errors Detected: %0d\n", total_ep_errors);
            $fwrite(ep_config_file_handle, "=============================================================\n");

            $fflush(ep_config_file_handle);
        end

        // Close device/vendor ID log file and write summary
        if (dev_vendor_id_file_handle != 0) begin            
            $fclose(dev_vendor_id_file_handle);
            `uvm_info(get_type_name(), $sformatf("Device/Vendor ID log file closed: %s", dev_vendor_id_log_file), UVM_LOW)
        end

        // Close BAR configuration log file and write summary
        if (bar_config_file_handle != 0) begin 
            $fclose(bar_config_file_handle);
            `uvm_info(get_type_name(), $sformatf("BAR configuration log file closed: %s", bar_config_log_file), UVM_LOW)
        end

        // Close EP configuration log file and write summary
        if (ep_config_file_handle != 0) begin
            $fclose(ep_config_file_handle);
            `uvm_info(get_type_name(), $sformatf("EP configuration log file closed: %s", ep_config_log_file), UVM_LOW)
        end
    endfunction

    function void log_dev_vendor_id_req(bit [15:0] bdf, bit [7:0] tag);
        if (dev_vendor_id_file_handle == 0) return;
        $fwrite(dev_vendor_id_file_handle, "[%0t] DEVICE/VENDOR ID READ REQUEST\n", $time);
        $fwrite(dev_vendor_id_file_handle, "  BDF: 0x%04h (Bus:%02d, Dev:%02d, Func:%02d)\n",
                bdf, bdf[15:8], bdf[7:3], bdf[2:0]);
        $fwrite(dev_vendor_id_file_handle, "  Tag: 0x%02h\n\n", tag);
        $fflush(dev_vendor_id_file_handle);
    endfunction

    function void load_ep_rom_data();
        $display("[SCOREBOARD] Loading EP ROM data from files...");
        
        // Load ROM files
        $readmemh("../mem/ep_rom_addr.hex", addr_mem_rom);
        $readmemh("../mem/ep_rom_expected_data.hex", expected_data_mem_rom);
        $readmemh("../mem/ep_rom_data.hex", data_mem_rom);
        $readmemh("../mem/ep_rom_type.hex", type_mem_rom);

        ep_rom_ptr         = 0;
        rom_extra_txn_cnt  = 0;
        rom_crs_rewind_cnt = 0;
        foreach (rom_hit[i]) rom_hit[i] = 1'b0;
        tag_rom.delete();

        // An X in the tail means a .hex file is shorter than EP_ROM_SIZE.
        for (int i = 0; i < pcie_rp_pkg::EP_ROM_SIZE; i++) begin
            if ($isunknown(addr_mem_rom[i]) || $isunknown(type_mem_rom[i])) begin
                `uvm_error(get_type_name(), $sformatf(
                    "ROM[%0d] is X - a mem/ep_rom_*.hex file has fewer than EP_ROM_SIZE (%0d) lines",
                    i, pcie_rp_pkg::EP_ROM_SIZE))
            end
        end

        $display("[SCOREBOARD] ROM loaded: %0d entries", pcie_rp_pkg::EP_ROM_SIZE);

        $display("[SCOREBOARD] EP ROM data loaded successfully");
        
        // Display first few entries for verification
        $display("[SCOREBOARD] First 5 ROM entries:");
        for (int i = 0; i < 5 && i < pcie_rp_pkg::EP_ROM_SIZE; i++) begin
            $display("  ROM[%0d]: Addr=0x%h, Data=0x%h, Type=%s",
                     i, addr_mem_rom[i],
                     type_mem_rom[i] ? expected_data_mem_rom[i] : data_mem_rom[i],
                     type_mem_rom[i] ? "READ" : "WRITE");
        end

        if(ep_config_file_handle != 0) begin
            $fwrite(ep_config_file_handle, "EP ROM DATA LOADED INTO SCOREBOARD with %0d entries\n", pcie_rp_pkg::EP_ROM_SIZE);
        end
        for(int i = 0; i < pcie_rp_pkg::EP_ROM_SIZE; i++) begin
            if(ep_config_file_handle != 0) begin
                $fwrite(ep_config_file_handle, "ROM Entry %0d: Addr=0x%h, Data=0x%h, Type=%s\n",
                         i, addr_mem_rom[i],
                         type_mem_rom[i] ? expected_data_mem_rom[i] : data_mem_rom[i],
                         type_mem_rom[i] ? "READ" : "WRITE");
            end
        end
        if(ep_config_file_handle != 0) begin
            $fwrite(ep_config_file_handle, "\n");
            $fflush(ep_config_file_handle);
        end

        foreach (addr_mem_rom[i]) begin
            cfg_addr_queue.push_back(addr_mem_rom[i][9:0]); 
        end
    endfunction

    task check_link_down();
        forever begin
            @(posedge link_vif_epcfg.clk);
            if(link_vif_epcfg.link_down) begin
                `uvm_info(get_type_name(), "EP_CONFIG_SB: Link is down. resetting EP config counts." , UVM_LOW);
                if(ep_config_file_handle != 0) begin
                    $fwrite(ep_config_file_handle, "=============================================================\n");
                    $fwrite(ep_config_file_handle, "[%0t] Link down detected\n", $time);
                    $fwrite(ep_config_file_handle, "=============================================================\n");
                    $fflush(ep_config_file_handle);
                end
                // Reset all relevant counters and states
                check_device_vendor_id = 0;
                dev_vendor_id_retry_cnt = 0;
                check_device_vendor_id = 0;
                bar_calculation_complete = 0;
                for(int i = 0; i < 6; i++) begin
                    seq_count[i] = 0;
                    bar_base[i] = 0;
                    bar_sizes[i] = 0;
                    bar_rcvd_values[i] = 0;
                end
                cfgrd_cnt = 0;
                cfgwr_cnt = 0;
                cpl_cnt = 0;
                cpl_data_cnt = 0;
                cpl_err_cnt = 0;
                cfg_retry_cnt = 0;
                cfg_ur_cnt = 0;
                cfg_ca_cnt = 0;
                total_ep_errors = 0;
                ep_data_error_cnt = 0;

                // The DUT restarts its ROM walk, so the cursor and its bindings go back.
                ep_rom_ptr         = 0;
                rom_extra_txn_cnt  = 0;
                rom_crs_rewind_cnt = 0;
                foreach (rom_hit[i]) rom_hit[i] = 1'b0;
                tag_rom.delete(); 

                while(link_vif_epcfg.link_down) begin
                    @(posedge link_vif_epcfg.clk);
                end
                `uvm_info(get_type_name(), "EP_CONFIG_SB: Link is back up." , UVM_LOW);
                if(ep_config_file_handle != 0) begin
                    $fwrite(ep_config_file_handle, "=============================================================\n");
                    $fwrite(ep_config_file_handle, " [%0t] Link back up detected\n", $time);
                    $fwrite(ep_config_file_handle, "=============================================================\n");
                    $fflush(ep_config_file_handle);
                end
            end
        end
    endtask

    task check_rx_config_tlps();
        apci_tlp rx_tlp;
        forever begin
            rx_fifo.get(rx_tlp);
            `uvm_info(get_type_name(), $sformatf("ep_config_sb received RX TLP: %s (%0d)", rx_tlp.kind.name(), rx_tlp.kind), UVM_MEDIUM)

            case(rx_tlp.kind)
                APCI_TLP_cfgrd0: begin
                    case(flit_mode)
                        0: begin
                    // Non-flit mode
                    // rx_tlp.u.cfg. //fmt[2:0], typ[4:0], length, req_id, tag, lbe, fbe, bdf (cmpl id), reg_no {ext[3:0], low[5:0]}
                    // rx_tlp.payload //variable size
                            check_cfg_address(rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no);
                            check_header_fields({rx_tlp.u.cfg.fmt,rx_tlp.u.cfg.typ}, rx_tlp.u.cfg.length, rx_tlp.u.cfg.req_id, rx_tlp.u.cfg.lbe, rx_tlp.u.cfg.fbe);
                            if(rx_tlp.u.cfg.reg_no >= 'h4 && rx_tlp.u.cfg.reg_no <= 'h9) begin
                                store_tag_for_bar(rx_tlp.u.cfg.tag, rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no);
                                check_bar_seq(rx_tlp.u.cfg.reg_no, 0, 0);
                            end
                            if(rx_tlp.u.cfg.reg_no == 0) begin
                                // Device ID and Vendor ID read
                                check_device_vendor_id = 1;
                                log_dev_vendor_id_req(rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.tag);
                            end
                            `rp_flow($sformatf(
                                "RP -> EP : CfgRd0 BDF 0x%04h reg 0x%03h  tag 0x%02h",
                                rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no, rx_tlp.u.cfg.tag))
                            bind_rom_entry(rx_tlp.u.cfg.tag, rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no, rx_tlp.payload, 1'b1);
                            store_cfg_data(rx_tlp.u.cfg.tag, rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no, rx_tlp.payload, rx_tlp.u.cfg.length);
                            send_cfgrd_wait_for_cpl(rx_tlp.u.cfg.tag, rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no, rx_tlp.u.cfg.length);
                        end
                        1: begin
                            // Flit mode
                            // rx_tlp.u.fm_cfg. //typ[7:0], length, req_id, tag, bdf (cmpl id), reg_no {ext[3:0], low[5:0]}
                            // rx_tlp.payload //variable size
                            check_cfg_address(rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no);
                            check_header_fields(rx_tlp.u.fm_cfg.typ, rx_tlp.u.fm_cfg.length, rx_tlp.u.fm_cfg.req_id, rx_tlp.ohc[0].ohc_a3.lbe, rx_tlp.ohc[0].ohc_a3.fbe);
                            if(rx_tlp.u.fm_cfg.reg_no >= 'h4 && rx_tlp.u.fm_cfg.reg_no <= 'h9) begin
                                store_tag_for_bar(rx_tlp.u.fm_cfg.tag, rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no);
                                check_bar_seq(rx_tlp.u.fm_cfg.reg_no, 0, 0);
                            end
                            if(rx_tlp.u.fm_cfg.reg_no == 0) begin
                                // Device ID and Vendor ID read
                                check_device_vendor_id = 1;
                                log_dev_vendor_id_req(rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.tag);
                            end
                            `rp_flow($sformatf(
                                "RP -> EP : CfgRd0 BDF 0x%04h reg 0x%03h  tag 0x%02h",
                                rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no, rx_tlp.u.fm_cfg.tag))
                            bind_rom_entry(rx_tlp.u.fm_cfg.tag, rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no, rx_tlp.payload, 1'b1);
                            store_cfg_data(rx_tlp.u.fm_cfg.tag, rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no, rx_tlp.payload, rx_tlp.u.fm_cfg.length);
                            send_cfgrd_wait_for_cpl(rx_tlp.u.fm_cfg.tag, rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no, rx_tlp.u.fm_cfg.length);
                        end
                        default: begin
                            `uvm_fatal(get_type_name(), "Invalid flit_mode value")
                        end
                    endcase
                    cfgrd_cnt++;
                end
                APCI_TLP_cfgwr0: begin
                    case(flit_mode)
                        0: begin
                            // Non-flit mode
                            // rx_tlp.u.cfg. //fmt[2:0], typ[4:0], length, req_id, tag, lbe, fbe, bdf (cmpl id), reg_no {ext[3:0], low[5:0]}
                            // rx_tlp.payload //variable size
                            if(rx_tlp.u.cfg.reg_no >= 'h4 && rx_tlp.u.cfg.reg_no <= 'h9) begin
                                // BAR0 to BAR5
                                // check BAR base matches calc bar
                                if(rx_tlp.payload[0] != 32'hffffffff) begin
                                    check_bar_base(rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no, rx_tlp.payload);
                                end
                                check_bar_seq(rx_tlp.u.cfg.reg_no, rx_tlp.payload[0], 1);
                            end
                            else begin
                                check_cfg_address(rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no);
                            end
                            bind_rom_entry(rx_tlp.u.cfg.tag, rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no, rx_tlp.payload, 1'b0);
                            store_cfg_data(rx_tlp.u.cfg.tag, rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no, rx_tlp.payload, rx_tlp.u.cfg.length);
                            check_header_fields({rx_tlp.u.cfg.fmt,rx_tlp.u.cfg.typ}, rx_tlp.u.cfg.length, rx_tlp.u.cfg.req_id, rx_tlp.u.cfg.lbe, rx_tlp.u.cfg.fbe);
                            send_cfgwr_wait_for_cpl(rx_tlp.u.cfg.tag, rx_tlp.u.cfg.bdf, rx_tlp.u.cfg.reg_no, rx_tlp.u.cfg.length, rx_tlp.payload[0]);
                        end
                        1: begin
                            // Flit mode
                            // rx_tlp.u.fm_cfg. //typ[7:0], length, req_id, tag, bdf (cmpl id), reg_no {ext[3:0], low[5:0]}
                            // rx_tlp.payload //variable size
                            if(rx_tlp.u.fm_cfg.reg_no >= 'h4 && rx_tlp.u.fm_cfg.reg_no <= 'h9) begin
                                // BAR0 to BAR5
                                // check BAR base matches calc bar
                                if(rx_tlp.payload[0] != 32'hffffffff) begin
                                    check_bar_base(rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no, rx_tlp.payload);
                                end
                                check_bar_seq(rx_tlp.u.cfg.reg_no, rx_tlp.payload[0], 1);
                            end
                            else begin
                                check_cfg_address(rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no);
                            end
                            bind_rom_entry(rx_tlp.u.fm_cfg.tag, rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no, rx_tlp.payload, 1'b0);
                            store_cfg_data(rx_tlp.u.fm_cfg.tag, rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no, rx_tlp.payload, rx_tlp.u.fm_cfg.length);
                            check_header_fields(rx_tlp.u.fm_cfg.typ, rx_tlp.u.fm_cfg.length, rx_tlp.u.fm_cfg.req_id, rx_tlp.ohc[0].ohc_a3.lbe, rx_tlp.ohc[0].ohc_a3.fbe);
                            send_cfgwr_wait_for_cpl(rx_tlp.u.fm_cfg.tag, rx_tlp.u.fm_cfg.bdf, rx_tlp.u.fm_cfg.reg_no, rx_tlp.u.fm_cfg.length, rx_tlp.payload[0]);
                        end
                        default: begin
                            `uvm_fatal(get_type_name(), "Invalid flit_mode value")
                        end
                    endcase
                    cfgwr_cnt++;
                end
                default: begin
                    `uvm_warning(get_type_name(), $sformatf("Received unexpected TLP kind: %0d", rx_tlp.kind))
                end
            endcase
        end
    endtask


    task check_tx_config_tlps();
        apci_tlp tx_tlp;
        bar_tag_t bar_tag;
        cpl_txn tx_cpl_txn;
        #1ns

        forever begin
            tx_fifo.get(tx_tlp);
            `uvm_info(get_type_name(), $sformatf("ep_config_sb received TX TLP: %s (%0d)", tx_tlp.kind.name(), tx_tlp.kind), UVM_MEDIUM);
            case(tx_tlp.kind)
                APCI_TLP_cpl:
                begin
                    tx_cpl_txn = new();
                    // Handle Completion without Data
                    // release tag from tag in use
                    // check for any errors - UR, CA, aborts, poisoned, etc.
                    if(flit_mode) begin
                        // Flit mode
                        check_header_fields(tx_tlp.u.fm_cpl.typ, tx_tlp.u.fm_cpl.length, tx_tlp.u.fm_cpl.cpl_id, -1, -1);
                        if(tx_tlp.u.fm_com.ohc[0] == 1'b1) begin
                            check_error_status(tx_tlp.ohc[0].ohc_a5.cpl_status);
                            tx_cpl_txn.status = tx_tlp.ohc[0].ohc_a5.cpl_status;
                        end
                        else begin
                            tx_cpl_txn.status = '0;
                        end
                        tx_cpl_txn.tag = tx_tlp.u.fm_cpl.tag;
                        tx_cpl_txn.typ = tx_tlp.u.fm_cpl.typ;
                        tx_cpl_txn.length = tx_tlp.u.fm_cpl.length;
                        tx_cpl_txn.cpl_id = tx_tlp.u.fm_cpl.cpl_id;
                        tx_cpl_txn.data = '0;
                        rom_cpl_done(tx_tlp.u.fm_cpl.tag, tx_cpl_txn.status);
                    end else begin
                        // Non-flit mode
                        check_header_fields({tx_tlp.u.cpl.fmt,tx_tlp.u.cpl.typ}, tx_tlp.u.cpl.length, tx_tlp.u.cpl.cpl_id, -1, -1);
                        check_error_status(tx_tlp.u.cpl.cpl_status);
                        tx_cpl_txn.status = tx_tlp.u.cpl.cpl_status;
                        tx_cpl_txn.tag = tx_tlp.u.cpl.tag;
                        tx_cpl_txn.typ = {tx_tlp.u.cpl.fmt,tx_tlp.u.cpl.typ};
                        tx_cpl_txn.length = tx_tlp.u.cpl.length;
                        tx_cpl_txn.cpl_id = tx_tlp.u.cpl.cpl_id;
                        tx_cpl_txn.data = '0;
                        rom_cpl_done(tx_tlp.u.cpl.tag, tx_tlp.u.cpl.cpl_status);
                    end
                    cpl_ap.write(tx_cpl_txn);                    

                    cpl_cnt++;
                end
                APCI_TLP_cpld:
                begin
                    // Handle Completion with Data
                    // check if addr and data match with stored addr and data based on tag (mem)
                    // release tag from tag in use
                    // check for any errors - UR, CA, aborts, poisoned, etc.
                    // only for mem
                    tx_cpl_txn = new();
                    if(flit_mode) begin
                        // Flit mode
                        if(check_device_vendor_id) begin
                            check_device_vendor_id = 0;
                            if(tx_tlp.u.fm_com.ohc[0] == 1'b1) begin
                                check_device_vendor_id_data(tx_tlp.payload[0], tx_tlp.ohc[0].ohc_a5.cpl_status);
                            end else begin
                                check_device_vendor_id_data(tx_tlp.payload[0], '0);
                            end
                        end

                        // Only for cfg
                        // BAR read completion - to calc bar size
                        if(bar_tags.size() != 0) begin
                            bar_tag = get_bar_from_tag(tx_tlp.u.fm_cpl.tag);
                            store_bar_read_back(bar_tag.bdf, bar_tag.reg_no, tx_tlp.payload);
                        end
                        check_cpl_data(tx_tlp.u.fm_cpl.tag, tx_tlp.payload);
                        if(tx_tlp.u.fm_com.ohc[0] == 1'b1) begin
                            check_error_status(tx_tlp.ohc[0].ohc_a5.cpl_status);
                            tx_cpl_txn.status = tx_tlp.ohc[0].ohc_a5.cpl_status;
                        end
                        else begin
                            tx_cpl_txn.status = '0;
                        end
                        tx_cpl_txn.tag = tx_tlp.u.fm_cpl.tag;
                        tx_cpl_txn.typ = tx_tlp.u.fm_cpl.typ;
                        tx_cpl_txn.length = tx_tlp.u.fm_cpl.length;
                        tx_cpl_txn.cpl_id = tx_tlp.u.fm_cpl.cpl_id;
                        tx_cpl_txn.data = tx_tlp.payload[0];

                        check_header_fields(tx_tlp.u.fm_cpl.typ, tx_tlp.u.fm_cpl.length, tx_tlp.u.fm_cpl.cpl_id, -1, -1);
                        rom_cpl_done(tx_tlp.u.fm_cpl.tag, tx_cpl_txn.status);
                        cpl_data_cnt++;
                    end
                    else begin
                        // Non-flit mode
                        if(check_device_vendor_id) begin
                            check_device_vendor_id = 0;
                            check_device_vendor_id_data(tx_tlp.payload[0], tx_tlp.u.cpl.cpl_status);
                        end

                        // Only for cfg
                        // BAR read completion - to calc bar size
                        if(bar_tags.size() != 0) begin
                            bar_tag = get_bar_from_tag(tx_tlp.u.cpl.tag);
                            store_bar_read_back(bar_tag.bdf, bar_tag.reg_no, tx_tlp.payload);
                        end
                        check_cpl_data(tx_tlp.u.cpl.tag, tx_tlp.payload);
                        check_error_status(tx_tlp.u.cpl.cpl_status);
                        
                        tx_cpl_txn.status = tx_tlp.u.cpl.cpl_status;
                        tx_cpl_txn.tag = tx_tlp.u.cpl.tag;
                        tx_cpl_txn.typ = {tx_tlp.u.cpl.fmt,tx_tlp.u.cpl.typ};
                        tx_cpl_txn.length = tx_tlp.u.cpl.length;
                        tx_cpl_txn.cpl_id = tx_tlp.u.cpl.cpl_id;
                        tx_cpl_txn.data = tx_tlp.payload[0];
                        
                        check_header_fields({tx_tlp.u.cpl.fmt,tx_tlp.u.cpl.typ}, tx_tlp.u.cpl.length, tx_tlp.u.cpl.cpl_id, -1, -1);
                        rom_cpl_done(tx_tlp.u.cpl.tag, tx_tlp.u.cpl.cpl_status);
                        cpl_data_cnt++;
                    end
                    cpl_ap.write(tx_cpl_txn);
                end
                default: begin
                    `uvm_warning(get_type_name(), $sformatf("Received unexpected TX TLP kind: %0d", tx_tlp.kind))
                end
            endcase
        end

    endtask

    function void check_cfg_address(logic [15:0] bdf, logic [9:0] reg_no);
        // Check if BDF matches
        if(bdf != expected_bdf) begin
            `uvm_error(get_type_name(), $sformatf("RX TLP cfg address mismatch: expected BDF = 0x%h, received BDF = 0x%h", expected_bdf, bdf))
            if(ep_config_file_handle != 0) begin
                $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP cfg address mismatch: expected BDF = 0x%h, received BDF = 0x%h\n", $time, expected_bdf, bdf);
                $fflush(ep_config_file_handle);
                total_ep_errors++;
            end
        end
        // Check if reg_no matches
        if(!(dev_vendor_id_retry_cnt > 0 && reg_no == 0)) begin
            reg_no_to_match = cfg_addr_queue.pop_front();
            if(reg_no != {'0,reg_no_to_match[9:2]}) begin
                `uvm_error(get_type_name(), $sformatf("RX TLP cfg address mismatch: expected reg_no = 0x%h, received reg_no = 0x%h", reg_no_to_match, reg_no))
                if(ep_config_file_handle != 0) begin
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP cfg address mismatch: expected reg_no = 0x%h, received reg_no = 0x%h\n", $time, reg_no_to_match, reg_no);
                    $fflush(ep_config_file_handle);
                    total_ep_errors++;
                end
            end
            if(reg_no == 0)
                dev_vendor_id_retry_cnt++;
        end
    endfunction


    function void store_tag_for_bar(logic [7:0] tag, logic [15:0] bdf, logic [9:0] reg_no);
        // Store the tag, BDF, and register number for later use
        bar_tag_t bar_tag;
        bar_tag.tag = tag;
        bar_tag.bdf = bdf;
        bar_tag.reg_no = reg_no;
        bar_tags.push_back(bar_tag);
        `uvm_info(get_type_name(), $sformatf("Stored BAR tag: 0x%h for BDF: 0x%h, reg_no: 0x%h", tag, bdf, reg_no), UVM_MEDIUM);
    endfunction
    
    function bar_tag_t get_bar_from_tag(logic [7:0] tag);
        bar_tag_t bar_tag;
        bar_tag = bar_tags.pop_front();
        if(bar_tag.tag == tag) begin
            `uvm_info(get_type_name(), $sformatf("Retrieved BAR tag: 0x%h for BDF: 0x%h, reg_no: 0x%h", bar_tag.tag, bar_tag.bdf, bar_tag.reg_no), UVM_MEDIUM);
            return bar_tag;
        end else begin
            `uvm_error(get_type_name(), $sformatf("No matching BAR tag found for tag: 0x%h", tag))
            if(ep_config_file_handle != 0) begin
                $fwrite(ep_config_file_handle, "[%0t] [ERROR] No matching BAR tag found for tag: 0x%h\n", $time, tag);
                $fflush(ep_config_file_handle);
                total_ep_errors++;
            end
            return '{default:0};
        end        
    endfunction

    // Bind a config request to the next ROM entry; advances only on a match.
    function void bind_rom_entry(logic [7:0] tag, logic [15:0] bdf, logic [9:0] reg_no,
                                 bit[31:0] payload[], bit is_read);
        logic [31:0]  addr;
        rom_binding_t b;
        addr = {bdf, 4'b0, reg_no, 2'b0};

        if (ep_rom_ptr < pcie_rp_pkg::EP_ROM_SIZE
            && addr    === addr_mem_rom[ep_rom_ptr][31:0]
            && is_read === type_mem_rom[ep_rom_ptr][0]) begin

            if (!is_read && payload.size() > 0
                && payload[0] !== data_mem_rom[ep_rom_ptr]) begin
                `uvm_error(get_type_name(), $sformatf(
                    "ROM[%0d] write data mismatch at 0x%h: expected 0x%h, received 0x%h",
                    ep_rom_ptr, addr, data_mem_rom[ep_rom_ptr], payload[0]))
                ep_data_error_cnt++;
                total_ep_errors++;
            end

            b.rom_index  = ep_rom_ptr;
            b.expected   = expected_data_mem_rom[ep_rom_ptr];
            tag_rom[tag] = b;
            rom_hit[ep_rom_ptr] = 1'b1;
            `uvm_info(get_type_name(), $sformatf("ROM[%0d] bound to tag 0x%h: %s 0x%h",
                      ep_rom_ptr, tag, is_read ? "RD" : "WR", addr), UVM_HIGH)
            ep_rom_ptr++;
        end
        else begin
            b.rom_index  = -1;
            b.expected   = '0;
            tag_rom[tag] = b;
            rom_extra_txn_cnt++;
            `uvm_info(get_type_name(), $sformatf("Not a ROM entry (tag 0x%h): %s 0x%h",
                      tag, is_read ? "RD" : "WR", addr), UVM_HIGH)
        end
    endfunction

    // Release a tag once its completion has been seen.
    function void rom_cpl_done(logic [7:0] tag, logic [2:0] status);
        if (!tag_rom.exists(tag)) return;
        if (status == 3'b010) begin
            if (tag_rom[tag].rom_index >= 0) begin
                ep_rom_ptr          = tag_rom[tag].rom_index;
                rom_hit[ep_rom_ptr] = 1'b0;
                rom_crs_rewind_cnt++;
                `uvm_info(get_type_name(), $sformatf("CRS on tag 0x%h - ROM cursor rewound to %0d",
                          tag, ep_rom_ptr), UVM_MEDIUM)
            end
        end
        tag_rom.delete(tag);
    endfunction

    function void store_cfg_data(logic [7:0] tag, logic [15:0] bdf, logic [9:0] reg_no, bit[31:0] payload[], logic[9:0] length);
        cfg_data_t cfg_entry;
        cfg_entry.length = length;
        cfg_entry.data = new[cfg_entry.length];
        foreach (payload[i]) begin
            cfg_entry.data[i] = payload[i];
        end
        cfg_entry.addr = {bdf, 4'b0, reg_no, 2'b0};
        cfg_space[tag] = cfg_entry;
        `uvm_info(get_type_name(), $sformatf("Config Write at BDF 0x%h, reg_no 0x%h, addr 0x%h, length: %0d DWs", 
                                      bdf, reg_no, {reg_no, 2'b0}, cfg_entry.length), UVM_MEDIUM);
        
    endfunction

    // Compare a completion against the expectation bound to its tag.
    function void check_cpl_data(logic [7:0] tag, bit[31:0] payload[]);
        logic [31:0] addr;
        int          idx;

        if (!tag_rom.exists(tag)) begin
            `uvm_warning(get_type_name(), $sformatf("Completion tag 0x%h has no outstanding request", tag));
            return;
        end

        idx = tag_rom[tag].rom_index;
        if (idx < 0) begin
            `uvm_info(get_type_name(), $sformatf("Completion tag 0x%h is not a ROM transaction - no data check", tag), UVM_HIGH);
            return;
        end
        addr = addr_mem_rom[idx][31:0];

        foreach (payload[i]) begin
            if (payload[i] !== tag_rom[tag].expected) begin
                `uvm_warning(get_type_name(), $sformatf(
                    "ROM[%0d] read data mismatch at 0x%h: expected = 0x%h, received = 0x%h%s",
                    idx, addr, tag_rom[tag].expected, payload[i],
                    (idx == EP_ROM_DETECT_IDX) ? " (device-detect entry - not counted against the DUT)" : ""));
                total_ep_errors++;
                if (idx != EP_ROM_DETECT_IDX) ep_data_error_cnt++;
                if (ep_config_file_handle != 0) begin
                    $fwrite(ep_config_file_handle, "[%0t] [WARNING] ROM[%0d] read data mismatch at 0x%h: expected = 0x%h, received = 0x%h\n",
                             $time, idx, addr, tag_rom[tag].expected, payload[i]);
                    $fflush(ep_config_file_handle);
                end
            end else begin
                `uvm_info(get_type_name(), $sformatf("ROM[%0d] read data match at 0x%h: data = 0x%h", idx, addr, payload[i]), UVM_MEDIUM);
                if (ep_config_file_handle != 0) begin
                    $fwrite(ep_config_file_handle, "[%0t] ROM[%0d] read data match at 0x%h: data = 0x%h\n",
                             $time, idx, addr, payload[i]);
                    $fflush(ep_config_file_handle);
                end
            end
        end
        cfg_space.delete(tag);
    endfunction

    function void log_ep(string msg);
        if (ep_config_file_handle != 0) begin
            $fwrite(ep_config_file_handle, "[%0t] %s\n", $time, msg);
            $fflush(ep_config_file_handle);
        end
    endfunction

    function void check_error_status(logic [2:0] status);
        if(status == 3'b010) begin
            `uvm_warning(get_type_name(), "Error Status: CRS (Configuration Retry Status) - EP not ready, retry expected; legal per PCIe spec")
            log_ep($sformatf("[WARNING] Error Status: CRS (Configuration Retry Status) - EP not ready, retry expected"));
            cfg_retry_cnt++;
        end
        else if(status != 3'b000) begin
            `uvm_error(get_type_name(), $sformatf("TX TLP Completion with Data/Completion received with error status: 0b%b", status))
            log_ep($sformatf("[ERROR] TX TLP Completion with Data/Completion received with error status: 0b%b", status));
            case(status)
                3'b001: begin
                    `uvm_error(get_type_name(), "Error Status: UR (Unsupported Request)")
                    log_ep("[ERROR] Error Status: UR (Unsupported Request)");
                    cfg_ur_cnt++;
                end
                3'b100: begin
                    `uvm_error(get_type_name(), "Error Status: CA (Abort)")
                    log_ep("[ERROR] Error Status: CA (Abort)");
                    cfg_ca_cnt++;
                end
                default: begin
                    `uvm_error(get_type_name(), "Error Status: Unknown error code")
                    log_ep("[ERROR] Error Status: Unknown error code");
                end
            endcase
            cpl_err_cnt++;
            total_ep_errors++;
        end
    endfunction

    function void check_header_fields(logic [7:0] typ, logic [9:0] length, logic [15:0] req_id, logic [3:0] lbe, logic [3:0] fbe);
        case(typ)
            7'b100_0000: begin //Mem Wr 32
                if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4)) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 32 length mismatch: expected = %0d DWs, received = %0d DWs", 
                                        (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Wr 32 length mismatch: expected = %0d DWs, received = %0d DWs\n", 
                                 $time, (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length);
                    total_ep_errors++;
                end
                if(lbe != 4'b1111 || fbe != 4'b1111) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                        lbe, fbe))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Wr 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                 $time, lbe, fbe);
                    total_ep_errors++;
                end
                if(req_id != '0) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 32 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                        req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Wr 32 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                 $time, req_id);
                    total_ep_errors++;
                end
            end
            7'b110_0000: begin //Mem Wr 64
                if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4)) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 64 length mismatch: expected = %0d DWs, received = %0d DWs", 
                                        (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Wr 64 length mismatch: expected = %0d DWs, received = %0d DWs\n", 
                                 $time, (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length);
                    total_ep_errors++;
                end
                if(lbe != 4'b1111 || fbe != 4'b1111) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 64 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                        lbe, fbe))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Wr 64 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                 $time, lbe, fbe);
                    total_ep_errors++;
                end
                if(req_id != '0) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Wr 64 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                        req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Wr 64 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                 $time, req_id);
                    total_ep_errors++;
                end
            end
            7'b000_0000: begin //Mem Rd 32
                if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4)) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 32 length mismatch: expected = %0d DWs, received = %0d DWs", 
                                        (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Rd 32 length mismatch: expected = %0d DWs, received = %0d DWs\n", 
                                 $time, (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length);
                    total_ep_errors++;
                end
                if(lbe != 4'b1111 || fbe != 4'b1111) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                        lbe, fbe))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Rd 32 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                 $time, lbe, fbe);
                    total_ep_errors++;
                end
                if(req_id != '0) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 32 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                        req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Rd 32 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                 $time, req_id);
                    total_ep_errors++;
                end
            end
            7'b010_0000: begin //Mem Rd 64
                if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4)) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 64 length mismatch: expected = %0d DWs, received = %0d DWs", 
                                        (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Rd 64 length mismatch: expected = %0d DWs, received = %0d DWs\n", 
                                 $time, (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), length);
                    total_ep_errors++;
                end
                if(lbe != 4'b1111 || fbe != 4'b1111) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 64 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                        lbe, fbe))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Rd 64 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                 $time, lbe, fbe);
                    total_ep_errors++;    
                end
                if(req_id != '0) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Mem Rd 64 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                        req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Mem Rd 64 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                 $time, req_id);
                    total_ep_errors++;
                end
            end
            7'b000_0100: begin //Cfg Rd 0
                if(length != 1) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 0 length mismatch: expected = 1 DW, received = %0d DWs", 
                                        length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Rd 0 length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                 $time, length);
                    total_ep_errors++;
                end
                if(lbe != 4'b0000 || fbe != 4'b1111) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 0 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                        lbe, fbe))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Rd 0 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                 $time, lbe, fbe);
                    total_ep_errors++;
                end
                if(req_id != '0) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 0 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                        req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Rd 0 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                 $time, req_id);
                    total_ep_errors++;
                end
            end
            7'b000_0101: begin //Cfg Rd 1
                if(length != 1) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 1 length mismatch: expected = 1 DW, received = %0d DWs", 
                                        length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Rd 1 length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                 $time, length);
                    total_ep_errors++;
                end
                if(lbe != 4'b0000 || fbe != 4'b1111) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 1 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                        lbe, fbe))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Rd 1 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                 $time, lbe, fbe);
                    total_ep_errors++;
                end
                if(req_id != '0) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Rd 1 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                        req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Rd 1 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                 $time, req_id);
                    total_ep_errors++;
                end
            end
            7'b100_0100: begin //Cfg Wr 0
                if(length != 1) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 0 length mismatch: expected = 1 DW, received = %0d DWs", 
                                        length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Wr 0 length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                 $time, length);
                    total_ep_errors++;
                end
                if(lbe != 4'b0000 || fbe != 4'b1111) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 0 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                        lbe, fbe))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Wr 0 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                 $time, lbe, fbe);
                    total_ep_errors++;
                end
                if(req_id != '0) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 0 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                        req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Wr 0 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                 $time, req_id);
                    total_ep_errors++;
                end
            end
            7'b100_0101: begin //Cfg Wr 1
                if(length != 1) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 1 length mismatch: expected = 1 DW, received = %0d DWs", 
                                        length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Wr 1 length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                 $time, length);
                    total_ep_errors++;
                end
                if(lbe != 4'b0000 || fbe != 4'b1111) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 1 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b", 
                                        lbe, fbe))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Wr 1 byte enable mismatch: expected = 4'b1111, received LBE = 4'b%b, FBE = 4'b%b\n", 
                                 $time, lbe, fbe);
                    total_ep_errors++;
                end
                if(req_id != '0) begin
                    `uvm_error(get_type_name(), $sformatf("RX TLP Cfg Wr 1 req_id mismatch: expected = 0x0000, received = 0x%h", 
                                        req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] RX TLP Cfg Wr 1 req_id mismatch: expected = 0x0000, received = 0x%h\n", 
                                 $time, req_id);
                    total_ep_errors++;
                end
            end
            7'b000_1010: begin //Cpl
                if(length != 0) begin
                    `uvm_error(get_type_name(), $sformatf("TX TLP Completion length mismatch: expected = 1 DW, received = %0d DWs", 
                                        length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] TX TLP Completion length mismatch: expected = 1 DW, received = %0d DWs\n", 
                                 $time, length);
                    total_ep_errors++;
                end
                if(req_id != expected_bdf) begin
                    `uvm_warning(get_type_name(), $sformatf("TX TLP Completion cpl_id mismatch: expected = 16'h%04h, received = 16'h%04h (EP BDF is not programmed by this environment)",
                                        expected_bdf, req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [WARNING] TX TLP Completion cpl_id mismatch: expected = 16'h%04h, received = 16'h%04h\n",
                                 $time, expected_bdf, req_id);
                    total_ep_errors++;   // still tallied, so the count stays comparable to the RTL counters
                end
            end
            7'b100_1010: begin //Cpl Data
                if(length != (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4) && length != 1) begin
                    `uvm_error(get_type_name(), $sformatf("TX TLP Completion with Data length mismatch: expected = %0d or %0d DWs, received = %0d DWs", 
                                        (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), 1, length))
                    $fwrite(ep_config_file_handle, "[%0t] [ERROR] TX TLP Completion with Data length mismatch: expected = %0d or %0d DWs, received = %0d DWs\n", 
                                 $time, (pcie_rp_pkg::ACTUAL_PAYLOAD_SIZE_BYTE/4), 1, length);
                    total_ep_errors++;
                end
                // Warning, not error - see the Cpl arm above.
                if(req_id != expected_bdf) begin
                    `uvm_warning(get_type_name(), $sformatf("TX TLP Completion with Data cpl_id mismatch: expected = 16'h%04h, received = 16'h%04h (EP BDF is not programmed by this environment)",
                                        expected_bdf, req_id))
                    $fwrite(ep_config_file_handle, "[%0t] [WARNING] TX TLP Completion with Data cpl_id mismatch: expected = 16'h%04h, received = 16'h%04h\n",
                                 $time, expected_bdf, req_id);
                    total_ep_errors++;   // still tallied, so the count stays comparable to the RTL counters
                end
            end
            7'b011_0xxx: begin //MSG
                `uvm_info(get_type_name(), "TLP Message type received, no specific checks implemented", UVM_LOW)
                $fwrite(ep_config_file_handle, "[%0t] [INFO] TLP Message type received, no specific checks implemented\n", $time);
            end
            7'b111_0xxx: begin //MSG
                `uvm_info(get_type_name(), "TLP Message type received, no specific checks implemented", UVM_LOW)
                $fwrite(ep_config_file_handle, "[%0t] [INFO] TLP Message type received, no specific checks implemented\n", $time);
            end
            default: begin
                `uvm_warning(get_type_name(), $sformatf("TLP type 0b%b not specifically checked in header fields", typ))
                $fwrite(ep_config_file_handle, "[%0t] [WARNING] TLP type 0b%b not specifically checked in header fields\n", $time, typ);
            end
        endcase
        if (ep_config_file_handle != 0) $fflush(ep_config_file_handle);
    endfunction

    function void check_bar_base(logic [15:0] bdf, logic [9:0] reg_no, bit[31:0] payload[]);
        // match with expected bar base
        logic [31:0] matched_bar_base;
        matched_bar_base = match_and_pop_bar_base(payload[0]);
        if(matched_bar_base == 32'hffff_ffff) begin
            `uvm_error(get_type_name(), $sformatf("RX TLP BAR%0d base not found: received = 0x%h", 
                                           reg_no - 4, payload[0]))
            if(bar_config_file_handle != 0) begin
                $fwrite(bar_config_file_handle, "[%0t] BAR%0d BASE NOT FOUND: received = 0x%h\n", 
                         $time, reg_no - 4, payload[0]);
                $fflush(bar_config_file_handle);
                total_ep_errors++;
                display_bar_base_queue();
            end
        end
        else begin
            `uvm_info(get_type_name(), $sformatf("RX TLP BAR%0d base match: base = 0x%h", 
                                           reg_no - 4, matched_bar_base), UVM_MEDIUM)
            if ((reg_no - 4) < 6) bar_base_ok[reg_no - 4] = 1'b1;
            if(bar_config_file_handle != 0) begin
                $fwrite(bar_config_file_handle, "[%0t] BAR%0d BASE MATCH: expected = 0x%h, received = 0x%h\n", 
                         $time, reg_no - 4, matched_bar_base, payload[0]);
                $fflush(bar_config_file_handle);
            end
        end
        bar_base[reg_no-4] = payload[0];
        if(reg_no == 'h9) begin
            generate_addresses();
        end
    endfunction

    function void store_bar_read_back (logic [15:0] bdf, logic [9:0] reg_no, bit[31:0] payload[]);
        bar_rcvd_values[reg_no - 4] = payload[0];

        // Log BAR readback
        if (bar_config_file_handle != 0) begin
            $fwrite(bar_config_file_handle, "[%0t] BAR%0d READ BACK: value = 0x%h\n", $time, reg_no - 4, payload[0]);
            $fflush(bar_config_file_handle);
        end

        if(reg_no == 'h9) begin
            calc_bar_size();
        end
    endfunction

    function void calc_bar_size();
        logic [63:0] bar_size_1;
        logic [63:0] bar_size_3;
        logic [63:0] bar_size_5;
        // calc bar size based on payload data
        //store all calculated bar sizes
        if(is_64bit_bar) begin
            // 64 bit BAR
            if(bar_rcvd_values[0][0] != 1) begin
                bar_size_1 = ~({bar_rcvd_values[1], bar_rcvd_values[0]} & 64'hffff_ffff_ffff_fff0) + 1;
                {bar_sizes[1], bar_sizes[0]} = bar_size_1;
            end
            else begin
                {bar_sizes[1], bar_sizes[0]} = 64'b0;
            end

            if(bar_rcvd_values[2][0] != 1) begin
                bar_size_3 = ~({bar_rcvd_values[3], bar_rcvd_values[2]} & 64'hffff_ffff_ffff_fff0) + 1;
                {bar_sizes[3], bar_sizes[2]} = bar_size_3;
            end
            else begin
                {bar_sizes[3], bar_sizes[2]} = 64'b0;
            end

            if(bar_rcvd_values[4][0] != 1) begin
                bar_size_5 = ~({bar_rcvd_values[5], bar_rcvd_values[4]} & 64'hffff_ffff_ffff_fff0) + 1;
                {bar_sizes[5], bar_sizes[4]} = bar_size_5;
            end
            else begin
                {bar_sizes[5], bar_sizes[4]} = 64'b0;
            end
            if(bar_config_file_handle != 0) begin
                $fwrite(bar_config_file_handle, "\nCALCULATED BAR SIZES:\n");
                $fwrite(bar_config_file_handle, "  BAR0+BAR1 Size: 0x%h\n", {bar_sizes[1],bar_sizes[0]});
                $fwrite(bar_config_file_handle, "  BAR2+BAR3 Size: 0x%h\n", {bar_sizes[3],bar_sizes[2]});
                $fwrite(bar_config_file_handle, "  BAR4+BAR5 Size: 0x%h\n\n", {bar_sizes[5],bar_sizes[4]});
                $fflush(bar_config_file_handle);
            end
        end else begin
            // 32 bit BAR
            for(int i=0; i<6; i=i+1) begin
                if(bar_rcvd_values[i][0] == 1'b1) begin
                    bar_sizes[i] = 32'b0;
                end
                else begin
                    bar_sizes[i] = ~(bar_rcvd_values[i] & 32'hffff_fff0) + 1;
                end
            end
            if(bar_config_file_handle != 0) begin
                $fwrite(bar_config_file_handle, "\nCALCULATED BAR SIZES:\n");
                for(int i=0; i<6; i=i+1) begin
                    $fwrite(bar_config_file_handle, "  BAR%0d Size: 0x%h\n", i, bar_sizes[i]);
                end
                $fflush(bar_config_file_handle);
            end
        end
        calc_bar_base();
    endfunction

    function void calc_bar_base();
        logic [63:0] bar_size_sorted_64 [3];
        logic [2:0]  bar_index_sorted_64 [3];
        logic [31:0] bar_size_sorted_32 [6];
        logic [31:0] bar_size_sorted_32_final [6];
        logic [2:0]  bar_index_sorted_32 [6];
        logic [2:0]  bar_index_sorted_32_final [6];
        int k, j;
        logic [31:0] temp_size;
        logic [2:0]  temp_index;

        //// SORT BAR SIZES ////
        if(is_64bit_bar) begin
            if({bar_sizes[1], bar_sizes[0]} <= {bar_sizes[3], bar_sizes[2]}) begin
                if({bar_sizes[1], bar_sizes[0]} <= {bar_sizes[5], bar_sizes[4]}) begin
                    bar_size_sorted_64[2] = {bar_sizes[1], bar_sizes[0]};
                    bar_index_sorted_64[2] = 0;
                    if({bar_sizes[3], bar_sizes[2]} <= {bar_sizes[5], bar_sizes[4]}) begin
                        bar_size_sorted_64[1] = {bar_sizes[3], bar_sizes[2]};
                        bar_index_sorted_64[1] = 1;
                        bar_size_sorted_64[0] = {bar_sizes[5], bar_sizes[4]};
                        bar_index_sorted_64[0] = 2;
                    end else begin
                        bar_size_sorted_64[1] = {bar_sizes[5], bar_sizes[4]};
                        bar_index_sorted_64[1] = 2;
                        bar_size_sorted_64[0] = {bar_sizes[3], bar_sizes[2]};
                        bar_index_sorted_64[0] = 1;
                    end
                end else begin
                    bar_size_sorted_64[2] = {bar_sizes[5], bar_sizes[4]};
                    bar_index_sorted_64[2] = 2;
                    bar_size_sorted_64[1] = {bar_sizes[1], bar_sizes[0]};
                    bar_index_sorted_64[1] = 0;
                    bar_size_sorted_64[0] = {bar_sizes[3], bar_sizes[2]};
                    bar_index_sorted_64[0] = 1;
                end
            end else begin
                if({bar_sizes[3], bar_sizes[2]} <= {bar_sizes[5], bar_sizes[4]}) begin
                    bar_size_sorted_64[2] = {bar_sizes[3], bar_sizes[2]};
                    bar_index_sorted_64[2] = 1;
                    if({bar_sizes[1], bar_sizes[0]} <= {bar_sizes[5], bar_sizes[4]}) begin
                        bar_size_sorted_64[1] = {bar_sizes[1], bar_sizes[0]};
                        bar_index_sorted_64[1] = 0;
                        bar_size_sorted_64[0] = {bar_sizes[5], bar_sizes[4]};
                        bar_index_sorted_64[0] = 2;
                    end else begin
                        bar_size_sorted_64[1] = {bar_sizes[5], bar_sizes[4]};
                        bar_index_sorted_64[1] = 2;
                        bar_size_sorted_64[0] = {bar_sizes[1], bar_sizes[0]};
                        bar_index_sorted_64[0] = 0;
                    end
                end else begin
                    bar_size_sorted_64[2] = {bar_sizes[5], bar_sizes[4]};
                    bar_index_sorted_64[2] = 2;
                    bar_size_sorted_64[1] = {bar_sizes[3], bar_sizes[2]};
                    bar_index_sorted_64[1] = 1;
                    bar_size_sorted_64[0] = {bar_sizes[1], bar_sizes[0]};
                    bar_index_sorted_64[0] = 0;
                end
            end
            `uvm_info(get_type_name(), $sformatf("BAR sizes sorted: %0d %0d %0d", bar_size_sorted_64[0], bar_size_sorted_64[1], bar_size_sorted_64[2]), UVM_MEDIUM);
            `uvm_info(get_type_name(), $sformatf("BAR indices sorted: %0d %0d %0d", bar_index_sorted_64[0], bar_index_sorted_64[1], bar_index_sorted_64[2]), UVM_MEDIUM);
        end
        else begin
            // 32 bit BAR
            for(int i=0; i<6; i=i+1) begin
                bar_size_sorted_32[i] = bar_sizes[i];
                bar_index_sorted_32[i] = i;
            end

            for(int i = 0; i<5; i++) begin
                for(int j = i+1; j<6; j++) begin
                    if(bar_size_sorted_32[i] < bar_size_sorted_32[j]) begin
                        // swap size
                        temp_size = bar_size_sorted_32[i];
                        bar_size_sorted_32[i] = bar_size_sorted_32[j];
                        bar_size_sorted_32[j] = temp_size;
                        // swap index
                        temp_index = bar_index_sorted_32[i];
                        bar_index_sorted_32[i] = bar_index_sorted_32[j];
                        bar_index_sorted_32[j] = temp_index;
                    end
                end
            end

            for(int i = 0; i<6; i=i+1) begin
                bar_size_sorted_32_final[i] = bar_size_sorted_32[i];
                bar_index_sorted_32_final[i] = bar_index_sorted_32[i];
            end

            `uvm_info(get_type_name(), $sformatf("BAR sizes sorted: %h %h %h %h %h %h", 
                                   bar_size_sorted_32_final[0], bar_size_sorted_32_final[1], bar_size_sorted_32_final[2], 
                                   bar_size_sorted_32_final[3], bar_size_sorted_32_final[4], bar_size_sorted_32_final[5]), UVM_MEDIUM);
            `uvm_info(get_type_name(), $sformatf("BAR indices sorted: %0d %0d %0d %0d %0d %0d", 
                                   bar_index_sorted_32_final[0], bar_index_sorted_32_final[1], bar_index_sorted_32_final[2], 
                                   bar_index_sorted_32_final[3], bar_index_sorted_32_final[4], bar_index_sorted_32_final[5]), UVM_MEDIUM);
        end

        /// CALCULATE BAR BASE ADDRESSES
        if(is_64bit_bar) begin
            // 64 bit BAR
            {bar_base[bar_index_sorted_64[0]*2+1],bar_base[bar_index_sorted_64[0]*2]} = 64'b0 - bar_size_sorted_64[0];
            {bar_base[bar_index_sorted_64[1]*2+1],bar_base[bar_index_sorted_64[1]*2]} = 
                {bar_base[bar_index_sorted_64[0]*2+1],bar_base[bar_index_sorted_64[0]*2]} - bar_size_sorted_64[1];
            {bar_base[bar_index_sorted_64[2]*2+1],bar_base[bar_index_sorted_64[2]*2]} = 
                {bar_base[bar_index_sorted_64[1]*2+1],bar_base[bar_index_sorted_64[1]*2]} - bar_size_sorted_64[2];
                `uvm_info(get_type_name(), $sformatf("Calculated BAR 0+1 base: 0x%h", 
                                   {bar_base[0], bar_base[1]}), UVM_MEDIUM);
                `uvm_info(get_type_name(), $sformatf("Calculated BAR 2+3 base: 0x%h", 
                                   {bar_base[2], bar_base[3]}), UVM_MEDIUM);
                `uvm_info(get_type_name(), $sformatf("Calculated BAR 4+5 base: 0x%h",
                                      {bar_base[4], bar_base[5]}), UVM_MEDIUM); 
        end else begin
            // 32 bit BAR
            bar_base[bar_index_sorted_32_final[0]] = 32'b0 - bar_size_sorted_32_final[0];
            for(int i=1; i<6; i=i+1) begin
                bar_base[bar_index_sorted_32_final[i]] = bar_base[bar_index_sorted_32_final[i-1]] - bar_size_sorted_32_final[i];
            end
            for(int i=0; i<6; i=i+1) begin
                `uvm_info(get_type_name(), $sformatf("Calculated BAR%0d base: 0x%h", 
                                       i, bar_base[i]), UVM_MEDIUM);
            end
        end

        bar_calculation_complete = 1;
        `uvm_info(get_type_name(), "BAR calculation completed. ep_config_scoreboard can now generate addresses.", UVM_MEDIUM)
        
        // Clear any existing entries in the queue
        bar_base_queue.delete();
        
        // Populate the queue with all 6 BAR base addresses for completion matching
        for(int i = 0; i < 6; i++) begin
            bar_base_queue.push_back(bar_base[i]);
            `uvm_info(get_type_name(), $sformatf("Added BAR%0d base 0x%h to completion matching queue", i, bar_base[i]), UVM_MEDIUM);
        end
        
        `uvm_info(get_type_name(), $sformatf("BAR base queue populated with %0d entries for completion matching", bar_base_queue.size()), UVM_MEDIUM);
        
    endfunction

    function void calc_bar_base_old();
        if(is_64bit_bar) begin
            // 64 bit BAR
            bar_base[0] = 32'h0;
            bar_base[1] = 32'h0000_0001;

            {bar_base[3], bar_base[2]} = {bar_sizes[1], bar_sizes[0]} + {bar_base[1], bar_base[0]};
            {bar_base[5], bar_base[4]} = {bar_sizes[3], bar_sizes[2]} + {bar_base[3], bar_base[2]};
            
            `uvm_info(get_type_name(), $sformatf("Calculated BAR%0d+%0d base: 0x%h", 0, 1, {bar_base[1],bar_base[0]}), UVM_MEDIUM)
            `uvm_info(get_type_name(), $sformatf("Calculated BAR%0d+%0d base: 0x%h", 2, 3, {bar_base[3],bar_base[2]}), UVM_MEDIUM)
            `uvm_info(get_type_name(), $sformatf("Calculated BAR%0d+%0d base: 0x%h", 4, 5, {bar_base[5],bar_base[4]}), UVM_MEDIUM)
            
            if(bar_config_file_handle != 0) begin
                $fwrite(bar_config_file_handle, "\nCALCULATED BAR BASE ADDRESSES:\n");
                $fwrite(bar_config_file_handle, "  BAR0+BAR1 Base: 0x%h\n", {bar_base[1],bar_base[0]});
                $fwrite(bar_config_file_handle, "  BAR2+BAR3 Base: 0x%h\n", {bar_base[3],bar_base[2]});
                $fwrite(bar_config_file_handle, "  BAR4+BAR5 Base: 0x%h\n\n", {bar_base[5],bar_base[4]});
                $fflush(bar_config_file_handle);
            end
        end else begin
            // 32 bit BAR
            bar_base[0] = 32'h0;
            `uvm_info(get_type_name(), $sformatf("Calculated BAR%0d base: 0x%h", 0, bar_base[0]), UVM_MEDIUM)
            for(int i=1; i<6; i=i+1) begin
                bar_base[i] = bar_sizes[i-1] + bar_base[i-1];
                `uvm_info(get_type_name(), $sformatf("Calculated BAR%0d base: 0x%h", i, bar_base[i]), UVM_MEDIUM)
            end
            
            if(bar_config_file_handle != 0) begin
                $fwrite(bar_config_file_handle, "\nCALCULATED BAR BASE ADDRESSES:\n");
                for(int i=0; i<6; i=i+1) begin
                    $fwrite(bar_config_file_handle, "  BAR%0d Base: 0x%h\n", i, bar_base[i]);
                end
                $fwrite(bar_config_file_handle, "\n");
                $fflush(bar_config_file_handle);
            end
        end
        
        bar_calculation_complete = 1;
        `uvm_info(get_type_name(), "BAR calculation completed. ep_config_scoreboard can now generate addresses.", UVM_MEDIUM)
        
        generate_addresses();
    endfunction

    function void check_bar_seq(logic [9:0] reg_no, logic [31:0] payload, logic is_write);
        case(reg_no-4)
            0: begin
                `uvm_info(get_type_name(), $sformatf("Checking BAR0 %s sequence, seq_count = %0d %s", 
                                       is_write ? "write" : "read", seq_count[0], is_write ? $sformatf("Payload: 'h%h", payload) : ""), UVM_MEDIUM)
                if(bar_config_file_handle != 0)
                begin
                    $fwrite(bar_config_file_handle, "[%0t] CHECKING BAR0 %s SEQUENCE, SEQ_COUNT = %0d %s\n", 
                         $time, is_write ? "WRITE" : "READ", seq_count[0], is_write ? $sformatf("PAYLOAD: 'h%h", payload) : "");
                end

                if(!is_write) begin
                    if(seq_count[0] != 1) begin
                        `uvm_error(get_type_name(), $sformatf("BAR0 write sequence error: expected seq_count = %0d, received seq_count = %0d", 
                                               1, seq_count[0]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR0 READ SEQUENCE ERROR: expected seq_count = %0d, received seq_count = %0d\n", 
                                     $time, 1, seq_count[0]);
                        end
                    end
                    seq_count[0]++;
                end
                else begin
                    if(seq_count[0] != 0 && seq_count[0] != 2) begin
                        `uvm_error(get_type_name(), $sformatf("BAR0 read sequence error: expected seq_count = %0d or %0d, received seq_count = %0d", 
                                               0, 2, seq_count[0]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR0 WRITE SEQUENCE ERROR: expected seq_count = %0d or %0d, received seq_count = %0d\n", 
                                        $time, 0, 2, seq_count[0]);
                        end
                    end
                    seq_count[0]++;
                end
                $fflush(bar_config_file_handle);
            end
            1: begin
                `uvm_info(get_type_name(), $sformatf("Checking BAR1 %s sequence, seq_count = %0d %s", 
                                       is_write ? "write" : "read", seq_count[1], is_write ? $sformatf("Payload: 'h%h", payload) : ""), UVM_MEDIUM)
                if(bar_config_file_handle != 0)
                begin
                    $fwrite(bar_config_file_handle, "[%0t] CHECKING BAR1 %s SEQUENCE, SEQ_COUNT = %0d %s\n", 
                         $time, is_write ? "WRITE" : "READ", seq_count[1], is_write ? $sformatf("PAYLOAD: 'h%h", payload) : "");
                end

                if(!is_write) begin
                    if(seq_count[1] != 1) begin
                        `uvm_error(get_type_name(), $sformatf("BAR1 write sequence error: expected seq_count = %0d, received seq_count = %0d", 
                                               1, seq_count[1]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR1 READ SEQUENCE ERROR: expected seq_count = %0d, received seq_count = %0d\n", 
                                     $time, 1, seq_count[1]);
                        end
                    end
                    seq_count[1]++;
                end
                else begin
                    if(seq_count[1] != 0 && seq_count[1] != 2) begin
                        `uvm_error(get_type_name(), $sformatf("BAR1 read sequence error: expected seq_count = %0d or %0d, received seq_count = %0d", 
                                               0, 2, seq_count[1]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR1 WRITE SEQUENCE ERROR: expected seq_count = %0d or %0d, received seq_count = %0d\n", 
                                        $time, 0, 2, seq_count[1]);
                        end
                    end
                    seq_count[1]++;
                end
                $fflush(bar_config_file_handle);
            end
            2: begin
                `uvm_info(get_type_name(), $sformatf("Checking BAR2 %s sequence, seq_count = %0d %s", 
                                       is_write ? "write" : "read", seq_count[2], is_write ? $sformatf("Payload: 'h%h", payload) : ""), UVM_MEDIUM)
                if(bar_config_file_handle != 0)
                begin
                    $fwrite(bar_config_file_handle, "[%0t] CHECKING BAR2 %s SEQUENCE, SEQ_COUNT = %0d %s\n", 
                         $time, is_write ? "WRITE" : "READ", seq_count[2], is_write ? $sformatf("PAYLOAD: 'h%h", payload) : "");
                end

                if(!is_write) begin
                    if(seq_count[2] != 1) begin
                        `uvm_error(get_type_name(), $sformatf("BAR2 write sequence error: expected seq_count = %0d, received seq_count = %0d", 
                                               1, seq_count[2]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR2 READ SEQUENCE ERROR: expected seq_count = %0d, received seq_count = %0d\n", 
                                     $time, 1, seq_count[2]);
                        end
                    end
                    seq_count[2]++;
                end
                else begin
                    if(seq_count[2] != 0 && seq_count[2] != 2) begin
                        `uvm_error(get_type_name(), $sformatf("BAR2 read sequence error: expected seq_count = %0d or %0d, received seq_count = %0d", 
                                               0, 2, seq_count[2]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR2 WRITE SEQUENCE ERROR: expected seq_count = %0d or %0d, received seq_count = %0d\n", 
                                        $time, 0, 2, seq_count[2]);
                        end
                    end
                    seq_count[2]++;
                end
                $fflush(bar_config_file_handle);
            end
            3: begin
                `uvm_info(get_type_name(), $sformatf("Checking BAR3 %s sequence, seq_count = %0d %s", 
                                       is_write ? "write" : "read", seq_count[3], is_write ? $sformatf("Payload: 'h%h", payload) : ""), UVM_MEDIUM)
                if(bar_config_file_handle != 0)
                begin
                    $fwrite(bar_config_file_handle, "[%0t] CHECKING BAR3 %s SEQUENCE, SEQ_COUNT = %0d %s\n", 
                         $time, is_write ? "WRITE" : "READ", seq_count[3], is_write ? $sformatf("PAYLOAD: 'h%h", payload) : "");
                end

                if(!is_write) begin
                    if(seq_count[3] != 1) begin
                        `uvm_error(get_type_name(), $sformatf("BAR3 write sequence error: expected seq_count = %0d, received seq_count = %0d", 
                                               1, seq_count[3]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR3 READ SEQUENCE ERROR: expected seq_count = %0d, received seq_count = %0d\n", 
                                     $time, 1, seq_count[3]);
                        end
                    end
                    seq_count[3]++;
                end
                else begin
                    if(seq_count[3] != 0 && seq_count[3] != 2) begin
                        `uvm_error(get_type_name(), $sformatf("BAR3 read sequence error: expected seq_count = %0d or %0d, received seq_count = %0d", 
                                               0, 2, seq_count[3]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR3 WRITE SEQUENCE ERROR: expected seq_count = %0d or %0d, received seq_count = %0d\n", 
                                        $time, 0, 2, seq_count[3]);
                        end
                    end
                    seq_count[3]++;
                end
                $fflush(bar_config_file_handle);
            end
            4:begin
                `uvm_info(get_type_name(), $sformatf("Checking BAR4 %s sequence, seq_count = %0d %s", 
                                       is_write ? "write" : "read", seq_count[4], is_write ? $sformatf("Payload: 'h%h", payload) : ""), UVM_MEDIUM)
                if(bar_config_file_handle != 0)
                begin
                    $fwrite(bar_config_file_handle, "[%0t] CHECKING BAR4 %s SEQUENCE, SEQ_COUNT = %0d %s\n", 
                         $time, is_write ? "WRITE" : "READ", seq_count[4], is_write ? $sformatf("PAYLOAD: 'h%h", payload) : "");
                end

                if(!is_write) begin
                    if(seq_count[4] != 1) begin
                        `uvm_error(get_type_name(), $sformatf("BAR4 write sequence error: expected seq_count = %0d, received seq_count = %0d", 
                                               1, seq_count[4]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR4 READ SEQUENCE ERROR: expected seq_count = %0d, received seq_count = %0d\n", 
                                     $time, 1, seq_count[4]);
                        end
                    end
                    seq_count[4]++;
                end
                else begin
                    if(seq_count[4] != 0 && seq_count[4] != 2) begin
                        `uvm_error(get_type_name(), $sformatf("BAR4 read sequence error: expected seq_count = %0d or %0d, received seq_count = %0d", 
                                               0, 2, seq_count[4]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR4 WRITE SEQUENCE ERROR: expected seq_count = %0d or %0d, received seq_count = %0d\n", 
                                        $time, 0, 2, seq_count[4]);
                        end
                    end
                    seq_count[4]++;
                end
                $fflush(bar_config_file_handle);
            end
            5:begin
                `uvm_info(get_type_name(), $sformatf("Checking BAR5 %s sequence, seq_count = %0d %s", 
                                       is_write ? "write" : "read", seq_count[5], is_write ? $sformatf("Payload: 'h%h", payload) : ""), UVM_MEDIUM)
                if(bar_config_file_handle != 0)
                begin
                    $fwrite(bar_config_file_handle, "[%0t] CHECKING BAR5 %s SEQUENCE, SEQ_COUNT = %0d %s\n", 
                         $time, is_write ? "WRITE" : "READ", seq_count[5], is_write ? $sformatf("PAYLOAD: 'h%h", payload) : "");
                end

                if(!is_write) begin
                    if(seq_count[5] != 1) begin
                        `uvm_error(get_type_name(), $sformatf("BAR5 write sequence error: expected seq_count = %0d, received seq_count = %0d", 
                                               1, seq_count[5]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR5 READ SEQUENCE ERROR: expected seq_count = %0d, received seq_count = %0d\n", 
                                     $time, 1, seq_count[5]);
                        end
                    end
                    seq_count[5]++;
                end
                else begin
                    if(seq_count[5] != 0 && seq_count[5] != 2) begin
                        `uvm_error(get_type_name(), $sformatf("BAR5 read sequence error: expected seq_count = %0d or %0d, received seq_count = %0d", 
                                               0, 2, seq_count[5]))
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "[%0t] BAR5 WRITE SEQUENCE ERROR: expected seq_count = %0d or %0d, received seq_count = %0d\n", 
                                        $time, 0, 2, seq_count[5]);
                        end
                    end
                    if(seq_count[5] == 2) begin
                        if(bar_config_file_handle != 0) begin
                            $fwrite(bar_config_file_handle, "================================\n");
                            $fwrite(bar_config_file_handle, "[%0t] BAR SEQUENCE COMPLETION\n", $time);
                            $fwrite(bar_config_file_handle, "================================\n");
                        end
                    end
                    seq_count[5]++;
                end
                $fflush(bar_config_file_handle);
            end
            default: begin
                `uvm_error(get_type_name(), $sformatf("BAR number %0d is invalid for sequence checking", reg_no - 4))
                if(bar_config_file_handle != 0) begin
                    $fwrite(bar_config_file_handle, "[%0t] BAR NUMBER %0d IS INVALID FOR SEQUENCE CHECKING\n", $time, reg_no - 4);
                end
            end
        endcase

    endfunction

    function void generate_addresses();
        logic [64:0] next_addr;
        int curr_bar = 0;
        rp_scoreboard::addr_msg_t addr_msg;
        
        `uvm_info(get_type_name(), $sformatf("Starting address generation for %0d transactions", TRAFFIC_COUNT), UVM_MEDIUM)
        
        // Starting address
        if(is_64bit_bar)
        begin
            next_addr = {bar_base[1], bar_base[0]};
            if(ep_config_file_handle != 0) begin
                $fwrite(ep_config_file_handle, "[%0t] STARTING TRAFFIC GENERATION: \n", $time);
                $fwrite(ep_config_file_handle, "  Starting Address (64-bit BAR0,1): 0x%h\n", next_addr);
                $fflush(ep_config_file_handle);
            end
        end
        else
        begin
            next_addr = bar_base[0];
            if(ep_config_file_handle != 0) begin
                $fwrite(ep_config_file_handle, "[%0t] STARTING TRAFFIC GENERATION: \n", $time);
                $fwrite(ep_config_file_handle, "  Starting Address (32-bit BAR0): 0x%h\n", next_addr);
                $fflush(ep_config_file_handle);
            end
        end

        for(int i = 0; i < TRAFFIC_COUNT; i++) begin
            // Send read address
            addr_msg.address = next_addr[63:0];
            addr_msg.is_read = 1;
            addr_port.write(addr_msg);
            
            // Send write address  
            addr_msg.address = next_addr[63:0];
            addr_msg.is_read = 0;
            addr_port.write(addr_msg);
            
            // Calculate next address
            next_addr = next_addr + ACTUAL_PAYLOAD_SIZE_BYTE;
            if(TRAFFIC_COUNT - 1 == i) begin
                if(ep_config_file_handle != 0) begin
                    $fwrite(ep_config_file_handle, "[%0t] Last address sent: 0x%h\n", $time, next_addr - ACTUAL_PAYLOAD_SIZE_BYTE);
                    $fwrite(ep_config_file_handle, "[%0t] Completed sending all %0d addresses.\n", $time, TRAFFIC_COUNT);
                    $fflush(ep_config_file_handle);
                end
            end
            
            // Check if we need to move to next BAR
            if(is_64bit_bar) begin
                if(next_addr >= ({bar_base[curr_bar+1], bar_base[curr_bar]} + 
                                {bar_sizes[curr_bar+1], bar_sizes[curr_bar]}) || 
                   next_addr >= ({bar_base[curr_bar+1], bar_base[curr_bar]} + 16'h7fff)) begin
                    `uvm_info(get_type_name(), $sformatf("Current BAR %0d,%0d limit reached. Moving to next BAR.", curr_bar, curr_bar+1), UVM_MEDIUM)
                    `uvm_info(get_type_name(), $sformatf("BAR sizes are: BAR%0d size = 0x%h, BAR%0d size = 0x%h", 
                                           curr_bar, bar_sizes[curr_bar], curr_bar+1, bar_sizes[curr_bar+1]), UVM_MEDIUM);
                                           `uvm_info(get_type_name(), $sformatf("BAR bases are: BAR%0d base = 0x%h, BAR%0d base = 0x%h", 
                                           curr_bar, bar_base[curr_bar], curr_bar+1, bar_base[curr_bar+1]), UVM_MEDIUM);
                    if(ep_config_file_handle != 0) begin
                        $fwrite(ep_config_file_handle, "[%0t] Last address in current BAR %d,%d reached: 0x%h\n", 
                                 $time, curr_bar, curr_bar+1, next_addr - ACTUAL_PAYLOAD_SIZE_BYTE);
                        $fwrite(ep_config_file_handle, "[%0t] MOVING TO NEXT BAR: %0d\n", $time, curr_bar + 2);
                        $fflush(ep_config_file_handle);
                    end
                    curr_bar = curr_bar + 2;
                    if(curr_bar >= 6) curr_bar = 0;
                    next_addr = {bar_base[curr_bar+1], bar_base[curr_bar]};
                    if(ep_config_file_handle != 0) begin
                        $fwrite(ep_config_file_handle, "[%0t] Starting Address (64-bit BAR %d,%d): 0x%h\n", $time, curr_bar, curr_bar+1, next_addr);
                        $fflush(ep_config_file_handle);
                    end
                end
            end else begin
                if(next_addr >= (bar_base[curr_bar] + bar_sizes[curr_bar]) || 
                   next_addr >= (bar_base[curr_bar] + 32'h7fff)) begin
                    if(ep_config_file_handle != 0) begin
                        $fwrite(ep_config_file_handle, "[%0t] Last address in current BAR %d reached: 0x%h\n", 
                                 $time, curr_bar, next_addr - ACTUAL_PAYLOAD_SIZE_BYTE);
                        $fwrite(ep_config_file_handle, "[%0t] MOVING TO NEXT BAR: %0d\n", $time, curr_bar + 1);
                        $fflush(ep_config_file_handle);
                    end
                    curr_bar = curr_bar + 1;
                    if(curr_bar >= 6) curr_bar = 0;
                    next_addr = bar_base[curr_bar];
                    if(ep_config_file_handle != 0) begin
                        $fwrite(ep_config_file_handle, "[%0t] Starting Address (32-bit BAR %d): 0x%h\n", $time, curr_bar, next_addr);
                        $fflush(ep_config_file_handle);
                    end
                end
            end
        end

        
        `uvm_info(get_type_name(), $sformatf("Completed sending %0d addresses", TRAFFIC_COUNT), UVM_MEDIUM)

    endfunction

    function void check_device_vendor_id_data(bit[31:0] payload, logic [2:0] status);
        if(status != 3'b000) begin
            `uvm_error(get_type_name(), $sformatf("TX TLP Completion for Device/Vendor ID read received with error status: 0b%b", status))
            case(status)
                3'b001: `uvm_error(get_type_name(), "Error Status: UR (Unsupported Request)")
                3'b010: `uvm_error(get_type_name(), "Error Status: CRS (Configuration Retry Status)")
                3'b100: `uvm_error(get_type_name(), "Error Status: CA (Abort)")
                default: `uvm_error(get_type_name(), "Error Status: Unknown error code")
            endcase
            if(dev_vendor_id_file_handle != 0) begin
                $fwrite(dev_vendor_id_file_handle, "[%0t] DEVICE/VENDOR ID READ COMPLETION WITH ERROR STATUS: 0b%b\n\n", $time, status);
                $fflush(dev_vendor_id_file_handle);
            end
        end else begin
            if(payload == 32'hffff_ffff) begin
                `uvm_error(get_type_name(), $sformatf("TX TLP Device/Vendor ID data received = 0x%h", 
                                               payload))
                if(dev_vendor_id_file_handle != 0) begin
                    $fwrite(dev_vendor_id_file_handle, "[%0t] DEVICE/VENDOR ID READ COMPLETION WITH ERROR: ALL 1's DATA: data = 0x%h\n\n", $time, payload);
                    $fflush(dev_vendor_id_file_handle);
                end
            end else begin
                `uvm_info(get_type_name(), $sformatf("TX TLP Device/Vendor ID data received: data = 0x%h", 
                                               payload), UVM_MEDIUM)
                dev_vendor_id_seen = payload;
                dev_vendor_id_ok   = 1;
                if(dev_vendor_id_file_handle != 0) begin
                    $fwrite(dev_vendor_id_file_handle, "[%0t] DEVICE/VENDOR ID READ COMPLETION SUCCESSFUL: data = 0x%h\n\n", $time, payload);
                    $fflush(dev_vendor_id_file_handle);
                end
            end
        end
    endfunction

    task send_cfgrd_wait_for_cpl(logic [7:0] tag, logic [15:0] bdf, logic [9:0] reg_no, logic [9:0] length);

        fork 
            automatic bit match = 0;
            automatic cpl_txn tx_cpl_txn;
            automatic int timeout_cycles = 0;
            begin
                while(!match) begin
                    tx_cpl_txn = new();
                    if(cpl_fifo.try_peek(tx_cpl_txn)) begin
                        if(tx_cpl_txn.tag == tag) begin
                            match = 1;
                            cpl_fifo.get(tx_cpl_txn);
                            // Process the completion transaction
                            `uvm_info(get_type_name(), $sformatf("Received completion for cfg read - Tag: 0x%h, BDF: 0x%h, Reg No: 0x%h, Length: %0d DWs", 
                                        tag, bdf, reg_no, length), UVM_MEDIUM);
                            `rp_flow($sformatf(
                                "EP -> RP : CplD   BDF 0x%04h reg 0x%03h  tag 0x%02h  data 0x%08h",
                                bdf, reg_no, tag, tx_cpl_txn.data))
                            `uvm_info(get_type_name(), $sformatf("Completion Transaction - Tag: 0x%h, Type: 0x%h, Length: %0d DWs, Completion ID: 0x%h, Status: 0x%h, Data: 0x%h", 
                                        tx_cpl_txn.tag, tx_cpl_txn.typ, tx_cpl_txn.length, tx_cpl_txn.cpl_id, tx_cpl_txn.status, tx_cpl_txn.data), UVM_MEDIUM);
                            if(ep_config_file_handle != 0) begin
                                $fwrite(ep_config_file_handle, "[%0t] CFG READ COMPLETION RECEIVED:  Tag: 0x%h, BDF: 0x%h, Reg No: 0x%h, Length: %0d DWs, Completion ID: 0x%h, Status: 0x%h, Data: 0x%h\n\n", 
                                         $time, tag, bdf, reg_no, length, tx_cpl_txn.cpl_id, tx_cpl_txn.status, tx_cpl_txn.data);
                                $fflush(ep_config_file_handle);
                            end
                        end
                    end
                    #1ns;
                end
            end
            begin
                while(!match && timeout_cycles < 500) begin
                    #1ns;
                    timeout_cycles++;
                end
                if(!match) begin
                    `uvm_error(get_type_name(), $sformatf("Timeout waiting for completion for cfg read - Tag: 0x%h, BDF: 0x%h, Reg No: 0x%h, Length: %0d DWs", 
                                tag, bdf, reg_no, length))
                    if(ep_config_file_handle != 0) begin
                        $fwrite(ep_config_file_handle, "[%0t] [ERROR] TIMEOUT WAITING FOR CFG READ COMPLETION: Tag: 0x%h, BDF: 0x%h, Reg No: 0x%h, Length: %0d DWs\n\n", 
                                 $time, tag, bdf, reg_no, length);
                        $fflush(ep_config_file_handle);
                        total_ep_errors++;
                    end
                end
            end
        join_none
    endtask

    task send_cfgwr_wait_for_cpl(logic [7:0] tag, logic [15:0] bdf, logic [9:0] reg_no, logic [9:0] length, logic [31:0] data);

        fork 
            automatic bit match = 0;
            automatic cpl_txn tx_cpl_txn;
            automatic int timeout_cycles = 0;
            begin
                while(!match) begin
                    tx_cpl_txn = new();
                    if(cpl_fifo.try_peek(tx_cpl_txn)) begin
                        if(tx_cpl_txn.tag == tag) begin
                            match = 1;
                            cpl_fifo.get(tx_cpl_txn);
                            // Process the completion transaction
                            `uvm_info(get_type_name(), $sformatf("Received completion for cfg write - Tag: 0x%h, BDF: 0x%h, Reg No: 0x%h, Length: %0d DWs, Data: 0x%h", 
                                        tag, bdf, reg_no, length, data), UVM_MEDIUM);
                            `uvm_info(get_type_name(), $sformatf("Completion Transaction - Tag: 0x%h, Type: 0x%h, Length: %0d DWs, Completion ID: 0x%h, Status: 0x%h", 
                                        tx_cpl_txn.tag, tx_cpl_txn.typ, tx_cpl_txn.length, tx_cpl_txn.cpl_id, tx_cpl_txn.status), UVM_MEDIUM);

                            if(ep_config_file_handle != 0) begin
                                $fwrite(ep_config_file_handle, "[%0t] CFG WRITE COMPLETION RECEIVED: Tag: 0x%h, BDF: 0x%h, Reg No: 0x%h, Length: %0d DWs, Completion ID: 0x%h, Status: 0x%h, Data: 0x%h\n\n", 
                                         $time, tag, bdf, reg_no, length, tx_cpl_txn.cpl_id, tx_cpl_txn.status, data);
                                $fflush(ep_config_file_handle);
                            end

                        
                        end
                    end
                    #1ns;
                end
            end
            begin
                while(!match && timeout_cycles < 500) begin
                    #1ns;
                    timeout_cycles++;
                end
                if(!match) begin
                    `uvm_error(get_type_name(), $sformatf("Timeout waiting for completion for cfg write - Tag: 0x%h, BDF: 0x%h, Reg No: 0x%h, Length: %0d DWs, Data: 0x%h", 
                                tag, bdf, reg_no, length, data))
                    if(ep_config_file_handle != 0) begin
                        $fwrite(ep_config_file_handle, "[%0t] [ERROR] TIMEOUT WAITING FOR CFG WRITE COMPLETION: Tag: 0x%h, BDF: 0x%h, Reg No: 0x%h, Length: %0d DWs, Data: 0x%h\n\n", 
                                 $time, tag, bdf, reg_no, length, data);
                        $fflush(ep_config_file_handle);
                        total_ep_errors++;
                    end
                end
            end
        join_none
    endtask

    // Function to match and pop BAR base address from queue when completion arrives
    function logic [31:0] match_and_pop_bar_base(logic [31:0] cpl_data);
        logic [31:0] matched_bar_base;
        int match_index = -1;
        
        // Search for matching BAR base in the queue
        for(int i = 0; i < bar_base_queue.size(); i++) begin
            if(bar_base_queue[i] == cpl_data) begin
                match_index = i;
                break;
            end
        end
        
        if(match_index >= 0) begin
            // Found a match, remove it from the queue
            matched_bar_base = bar_base_queue[match_index];
            bar_base_queue.delete(match_index);
            `uvm_info(get_type_name(), $sformatf("BAR base match found: 0x%h at queue index %0d. Remaining queue size: %0d", 
                                           matched_bar_base, match_index, bar_base_queue.size()), UVM_MEDIUM);
            return matched_bar_base;
        end else begin
            `uvm_warning(get_type_name(), $sformatf("No BAR base match found for completion data: 0x%h. Queue size: %0d", 
                                               cpl_data, bar_base_queue.size()));
            return 32'hffff_ffff;  // Return 0 if no match found
        end
    endfunction

    // Function to check if expected BAR base addresses are still pending in queue
    function int get_pending_bar_count();
        return bar_base_queue.size();
    endfunction

    // Function to display current queue contents for debugging
    function void display_bar_base_queue();
        `uvm_info(get_type_name(), $sformatf("Current BAR base queue size: %0d", bar_base_queue.size()), UVM_MEDIUM);
        if(bar_config_file_handle!=0) begin
            $fwrite(bar_config_file_handle, "[%0t] Current BAR base queue size: %0d\n", $time, bar_base_queue.size());
        end
        for(int i = 0; i < bar_base_queue.size(); i++) begin
            `uvm_info(get_type_name(), $sformatf("Queue[%0d]: 0x%h", i, bar_base_queue[i]), UVM_MEDIUM);
            $fwrite(bar_config_file_handle, "[%0t] Queue[%0d]: 0x%h\n", $time, i, bar_base_queue[i]);
        end
        $fflush(bar_config_file_handle);
    endfunction
            

endclass