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

import ps_param_pkg::*;

class rp_config_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(rp_config_scoreboard)

    uvm_analysis_export #(rp_cfg_txn) dbi_exp;
    uvm_tlm_analysis_fifo #(rp_cfg_txn) dbi_fifo;

    virtual link_if.monitor_mp link_vif_rpcfg;

    // Config transactions the RTL issues beyond the ROM. Counted, not ROM-checked.
    localparam int RP_EXTRA_CFG_TXNS = 4;

    logic [63:0] addr_mem_rom[0:pcie_rp_pkg::RP_ROM_SIZE-1];
    logic [31:0] expected_data_mem_rom[0:pcie_rp_pkg::RP_ROM_SIZE-1];
    logic [31:0] data_mem_rom[0:pcie_rp_pkg::RP_ROM_SIZE-1];
    logic        type_mem_rom[0:pcie_rp_pkg::RP_ROM_SIZE-1]; // 0 = write, 1 = read

    int rp_config_file_handle;
    string rp_config_log_file = "rp_config_log.txt";

    int rp_error_count = 0;
    int rp_config_count = 0;
    int rp_cfg_cnt = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        dbi_fifo = new("dbi_fifo", this);
        dbi_exp = new("dbi_exp", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Open RP config log file
        rp_config_file_handle = $fopen(rp_config_log_file, "w");
        if (rp_config_file_handle == 0) begin
            `uvm_error(get_type_name(), $sformatf("Failed to open RP config log file: %s", rp_config_log_file))
        end else begin
            `uvm_info(get_type_name(), $sformatf("RP config log file opened: %s", rp_config_log_file), UVM_LOW)
            
            // Write header to log file
            $fwrite(rp_config_file_handle, "=============================================================\n");
            $fwrite(rp_config_file_handle, "              RP CONFIGURATION LOG\n");
            $fwrite(rp_config_file_handle, "=============================================================\n");
            $fflush(rp_config_file_handle);
        end
        if (!uvm_config_db#(virtual link_if.monitor_mp)::get(this,"","link_if", link_vif_rpcfg)) begin
            `uvm_fatal(get_type_name(), "link_if.monitor_mp is not set");
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        dbi_exp.connect(dbi_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        load_rp_rom_data();
        fork
            check_dbi_transactions();
            check_link_status();
        join
    endtask

    task check_link_status();
        forever begin
            @(posedge link_vif_rpcfg.clk);
            if(link_vif_rpcfg.link_down) begin
                `uvm_info(get_type_name(), "Link is down. resetting RP config counts." , UVM_LOW);
                if(rp_config_file_handle != 0) begin
                    $fwrite(rp_config_file_handle, "=============================================================\n");
                    $fwrite(rp_config_file_handle, "[%0t] Link down detected\n", $time);
                    $fwrite(rp_config_file_handle, "=============================================================\n");
                    $fflush(rp_config_file_handle);
                end
                rp_error_count = 0;
                rp_config_count = 0;
                rp_cfg_cnt = 0;
                while(link_vif_rpcfg.link_down) begin
                    @(posedge link_vif_rpcfg.clk);
                end
                `uvm_info(get_type_name(), "Link is back up." , UVM_LOW);
                if(rp_config_file_handle != 0) begin
                    $fwrite(rp_config_file_handle, "=============================================================\n");
                    $fwrite(rp_config_file_handle, " [%0t] Link back up detected\n", $time);
                    $fwrite(rp_config_file_handle, "=============================================================\n");
                    $fflush(rp_config_file_handle);
                end
            end
        end
    endtask

    task check_dbi_transactions();
        rp_cfg_txn dbi_txn;
        forever begin
            dbi_fifo.get(dbi_txn);
            `uvm_info(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: DBI Transaction - %s", dbi_txn.sprint()), UVM_LOW);
            rp_config_count++;
            
            if(rp_config_file_handle != 0) begin
                $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: DBI Transaction - %s\n", dbi_txn.sprint());
                $fflush(rp_config_file_handle);
            end

            if(dbi_txn.resp != 0) begin
                `uvm_error(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: DBI Transaction has error response: %0d", dbi_txn.resp));
                if(rp_config_file_handle != 0) begin
                    $fwrite(rp_config_file_handle, "[ERROR] RP CONFIG SCOREBOARD: DBI Transaction has error response: %0d\n", dbi_txn.resp);
                    $fflush(rp_config_file_handle);
                end
                rp_error_count++;
            end

            if(rp_cfg_cnt < pcie_rp_pkg::RP_ROM_SIZE) begin
                if(dbi_txn.is_write == !(type_mem_rom[rp_cfg_cnt])) begin
                    `uvm_info(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: MATCHED RP ROM TXN TYPE : Expected: %s, Received: %s",
                        type_mem_rom[rp_cfg_cnt] ? "READ" : "WRITE",
                        dbi_txn.is_write ? "WRITE" : "READ"), UVM_LOW);
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: MATCHED RP ROM TXN TYPE : Expected: %s, Received: %s\n",
                                type_mem_rom[rp_cfg_cnt] ? "READ" : "WRITE",
                                dbi_txn.is_write ? "WRITE" : "READ");
                            $fflush(rp_config_file_handle);
                        end
                end
                else begin
                    `uvm_error(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: MISMATCHED RP ROM TXN TYPE : Expected: %s, Received: %s",
                        type_mem_rom[rp_cfg_cnt] ? "READ" : "WRITE",
                        dbi_txn.is_write ? "WRITE" : "READ"));
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "[ERROR] RP CONFIG SCOREBOARD: MISMATCHED RP ROM TXN TYPE : Expected: %s, Received: %s\n",
                                type_mem_rom[rp_cfg_cnt] ? "READ" : "WRITE",
                                dbi_txn.is_write ? "WRITE" : "READ");
                            $fflush(rp_config_file_handle);
                        end
                    rp_error_count++;
                end

                if(dbi_txn.addr == addr_mem_rom[rp_cfg_cnt]) begin
                    `uvm_info(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: MATCHED RP ROM TXN ADDR : Expected: 0x%h, Received: 0x%h",
                        addr_mem_rom[rp_cfg_cnt],
                        dbi_txn.addr), UVM_LOW);
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: MATCHED RP ROM TXN ADDR : Expected: 0x%h, Received: 0x%h\n",
                                addr_mem_rom[rp_cfg_cnt],
                                dbi_txn.addr);
                            $fflush(rp_config_file_handle);
                        end
                end
                else begin
                    `uvm_error(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: MISMATCHED RP ROM TXN ADDR : Expected: 0x%h, Received: 0x%h",
                        addr_mem_rom[rp_cfg_cnt],
                        dbi_txn.addr));
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "[ERROR] RP CONFIG SCOREBOARD: MISMATCHED RP ROM TXN ADDR : Expected: 0x%h, Received: 0x%h\n",
                                addr_mem_rom[rp_cfg_cnt],
                                dbi_txn.addr);
                            $fflush(rp_config_file_handle);
                        end
                    rp_error_count++;
                end
                
                if(!dbi_txn.is_write) begin
                    if(dbi_txn.data == expected_data_mem_rom[rp_cfg_cnt]) begin
                        `uvm_info(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: MATCHED RP ROM TXN READ DATA : Expected: 0x%h, Received: 0x%h",
                            expected_data_mem_rom[rp_cfg_cnt],
                            dbi_txn.data), UVM_LOW);
                            if(rp_config_file_handle != 0) begin
                                $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: MATCHED RP ROM TXN READ DATA : Expected: 0x%h, Received: 0x%h\n",
                                    expected_data_mem_rom[rp_cfg_cnt],
                                    dbi_txn.data);
                                $fflush(rp_config_file_handle);
                            end
                    end
                    else begin
                        `uvm_warning(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: MISMATCHED RP ROM TXN READ DATA : Expected: 0x%h, Received: 0x%h",
                            expected_data_mem_rom[rp_cfg_cnt],
                            dbi_txn.data));
                            if(rp_config_file_handle != 0) begin
                                $fwrite(rp_config_file_handle, "[WARNING] RP CONFIG SCOREBOARD: MISMATCHED RP ROM TXN READ DATA : Expected: 0x%h, Received: 0x%h\n",
                                    expected_data_mem_rom[rp_cfg_cnt],
                                    dbi_txn.data);
                                $fflush(rp_config_file_handle);
                            end
                        rp_error_count++;
                    end
                end
                else begin
                    if(dbi_txn.data == data_mem_rom[rp_cfg_cnt]) begin
                        `uvm_info(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: MATCHED RP ROM TXN WRITE DATA : Expected: 0x%h, Received: 0x%h",
                            data_mem_rom[rp_cfg_cnt],
                            dbi_txn.data), UVM_LOW);
                            if(rp_config_file_handle != 0) begin
                                $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: MATCHED RP ROM TXN WRITE DATA : Expected: 0x%h, Received: 0x%h\n",
                                    data_mem_rom[rp_cfg_cnt],
                                    dbi_txn.data);
                                $fflush(rp_config_file_handle);
                            end
                    end
                    else begin
                        `uvm_error(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: MISMATCHED RP ROM TXN WRITE DATA : Expected: 0x%h, Received: 0x%h",
                            data_mem_rom[rp_cfg_cnt],
                            dbi_txn.data));
                            if(rp_config_file_handle != 0) begin
                                $fwrite(rp_config_file_handle, "[ERROR] RP CONFIG SCOREBOARD: MISMATCHED RP ROM TXN WRITE DATA : Expected: 0x%h, Received: 0x%h\n",
                                    data_mem_rom[rp_cfg_cnt],
                                    dbi_txn.data);
                                $fflush(rp_config_file_handle);
                            end
                        rp_error_count++;
                    end
                end
                rp_cfg_cnt++;
            end
            else begin
                `uvm_info(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: DBI Transaction - %s", dbi_txn.sprint()), UVM_LOW);
                if(rp_config_file_handle != 0) begin
                    $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: DBI Transaction - %s\n", dbi_txn.sprint());
                    $fflush(rp_config_file_handle);
                end
                if(dbi_txn.addr == 'hfc000074 && dbi_txn.is_write) begin
                    if(dbi_txn.data[2:0] == 'b0) begin
                        `uvm_info(get_type_name(), "RP_CONFIG_SCOREBOARD: Max Payload Size Set to 128 Bytes", UVM_LOW);
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: Max Payload Size Set to 128 Bytes\n");
                            $fflush(rp_config_file_handle);
                        end
                    end else begin
                        `uvm_error(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: Unexpected Max Payload Size Setting: 'b%b", dbi_txn.data[2:0]));
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "[ERROR] RP CONFIG SCOREBOARD: Unexpected Max Payload Size Setting: 'b%b\n", dbi_txn.data[2:0]);
                            $fflush(rp_config_file_handle);
                        end
                        rp_error_count++;
                    end

                    if(dbi_txn.data[5] && pcie_rp_pkg::ENABLE_EXTENDED_TAG) begin
                        `uvm_info(get_type_name(), "RP_CONFIG_SCOREBOARD: Extended Tag Enabled", UVM_LOW);
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: Extended Tag Enabled\n");
                            $fflush(rp_config_file_handle);
                        end
                    end
                    else if(!dbi_txn.data[5] && !pcie_rp_pkg::ENABLE_EXTENDED_TAG) begin
                        `uvm_info(get_type_name(), "RP_CONFIG_SCOREBOARD: Extended Tag Disabled", UVM_LOW);
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: Extended Tag Disabled\n");
                            $fflush(rp_config_file_handle);
                        end
                    end
                    else begin
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "[ERROR] RP CONFIG SCOREBOARD: Unexpected Extended Tag Setting: %0b when parameter is %0b\n", dbi_txn.data[5], pcie_rp_pkg::ENABLE_EXTENDED_TAG);
                            $fflush(rp_config_file_handle);
                        end
                        `uvm_error(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: Unexpected Extended Tag Setting: %0b when parameter is %0b", dbi_txn.data[5], pcie_rp_pkg::ENABLE_EXTENDED_TAG));
                        rp_error_count++;
                    end
                end
                if(dbi_txn.addr == 'hfc000078 && dbi_txn.is_write) begin
                    if(dbi_txn.data[7:5] == 'b0) begin
                        `uvm_info(get_type_name(), "RP_CONFIG_SCOREBOARD: Max Read Request Size Set to 128 Bytes", UVM_LOW);
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: Max Read Request Size Set to 128 Bytes\n");
                            $fflush(rp_config_file_handle);
                        end
                    end else begin
                        `uvm_error(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: Unexpected Max Read Request Size Setting: 'b%b", dbi_txn.data[7:5]));
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "[ERROR] RP CONFIG SCOREBOARD: Unexpected Max Read Request Size Setting: 'b%b\n", dbi_txn.data[7:5]);
                            $fflush(rp_config_file_handle);
                        end
                        rp_error_count++;
                    end

                    if(dbi_txn.data[8] && pcie_rp_pkg::ENABLE_EXTENDED_TAG) begin
                        `uvm_info(get_type_name(), "RP_CONFIG_SCOREBOARD: Extended Tag Enabled", UVM_LOW);
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: Extended Tag Enabled\n");
                            $fflush(rp_config_file_handle);
                        end
                    end
                    else if(!dbi_txn.data[8] && !pcie_rp_pkg::ENABLE_EXTENDED_TAG) begin
                        `uvm_info(get_type_name(), "RP_CONFIG_SCOREBOARD: Extended Tag Disabled", UVM_LOW);
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "RP CONFIG SCOREBOARD: Extended Tag Disabled\n");
                            $fflush(rp_config_file_handle);
                        end
                    end
                    else begin
                        if(rp_config_file_handle != 0) begin
                            $fwrite(rp_config_file_handle, "[ERROR] RP CONFIG SCOREBOARD: Unexpected Extended Tag Setting: %0b when parameter is %0b\n", dbi_txn.data[8], pcie_rp_pkg::ENABLE_EXTENDED_TAG);
                            $fflush(rp_config_file_handle);
                        end
                        `uvm_error(get_type_name(), $sformatf("RP_CONFIG_SCOREBOARD: Unexpected Extended Tag Setting: %0b when parameter is %0b", dbi_txn.data[8], pcie_rp_pkg::ENABLE_EXTENDED_TAG));
                        rp_error_count++;
                    end
                end
            end
            $fwrite(rp_config_file_handle, "\n");
            $fflush(rp_config_file_handle);
        end
    endtask
    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        uvm_report_info(get_type_name(), "RP Configuration Scoreboard Report", UVM_LOW);
        if (rp_error_count > 0) begin
            uvm_report_warning(get_type_name(), $sformatf("RP Configuration Scoreboard detected %0d errors during the test.", rp_error_count));
        end else begin
            uvm_report_info(get_type_name(), "RP Configuration Scoreboard detected no errors during the test.", UVM_LOW);
        end

        if (rp_config_file_handle != 0) begin
            $fwrite(rp_config_file_handle, "=============================================================\n");
            $fwrite(rp_config_file_handle, "RP Configuration Scoreboard Report\n");
            if (rp_error_count > 0) begin
                $fwrite(rp_config_file_handle, "Total Errors Detected: %0d\n", rp_error_count);
            end else begin
                $fwrite(rp_config_file_handle, "No Errors Detected\n");
            end
            $fwrite(rp_config_file_handle, "=============================================================\n");
            $fflush(rp_config_file_handle);
        end

        uvm_report_info(get_type_name(), $sformatf("Total RP configuration count: %0d", rp_config_count));

        // Total = RP_ROM_SIZE checked entries + RP_EXTRA_CFG_TXNS the RTL issues on
        // its own. The extra ones are counted here but not compared against the ROM.
        // IDE: the RTL also polls the RP IDE capability, on top of the ROM and the fixed RTL transactions
        if(rp_ide_helper::ide_active ? (rp_config_count < (pcie_rp_pkg::RP_ROM_SIZE + RP_EXTRA_CFG_TXNS)) : (rp_config_count != (pcie_rp_pkg::RP_ROM_SIZE + RP_EXTRA_CFG_TXNS))) begin
            uvm_report_error(get_type_name(), $sformatf("RP Configuration Scoreboard: Mismatch in expected RP configuration count. Expected: %0d (%0d ROM + %0d RTL), Received: %0d", pcie_rp_pkg::RP_ROM_SIZE + RP_EXTRA_CFG_TXNS, pcie_rp_pkg::RP_ROM_SIZE, RP_EXTRA_CFG_TXNS, rp_config_count));
            if (rp_config_file_handle != 0) begin
                $fwrite(rp_config_file_handle, "[ERROR] RP Configuration Scoreboard: Mismatch in expected RP configuration count. Expected: %0d (%0d ROM + %0d RTL), Received: %0d\n", pcie_rp_pkg::RP_ROM_SIZE + RP_EXTRA_CFG_TXNS, pcie_rp_pkg::RP_ROM_SIZE, RP_EXTRA_CFG_TXNS, rp_config_count);
                $fflush(rp_config_file_handle);
            end
        end

        $fclose(rp_config_file_handle);

    endfunction

    function void load_rp_rom_data();
        $display("[SCOREBOARD] Loading RP ROM data from files...");
        
        // Load ROM files
        if(RP_CTRL1)
            $readmemh("../mem/rp_rom_addr_ctrl1.hex", addr_mem_rom);
        else if(RP_CTRL0)
            $readmemh("../mem/rp_rom_addr_ctrl0.hex", addr_mem_rom);

        $readmemh("../mem/rp_rom_expected_data.hex", expected_data_mem_rom);
        $readmemh("../mem/rp_rom_type.hex", type_mem_rom);
        $readmemh("../mem/rp_rom_data.hex", data_mem_rom);

        $display("[SCOREBOARD] RP ROM data loaded successfully");
        // Display first few entries for verification
        $display("[SCOREBOARD] First 8 ROM entries:");
        for (int i = 0; i < 8 && i < pcie_rp_pkg::RP_ROM_SIZE; i++) begin
            $display("  ROM[%0d]: Addr=0x%h, Data=0x%h", 
                     i, addr_mem_rom[i], expected_data_mem_rom[i]);
        end
        if(rp_config_file_handle != 0) begin
            $fwrite(rp_config_file_handle, "RP ROM data loaded successfully with %d entries\n", pcie_rp_pkg::RP_ROM_SIZE);
            $fflush(rp_config_file_handle);
        end
        for (int i = 0; i < pcie_rp_pkg::RP_ROM_SIZE; i++) begin
            if(rp_config_file_handle != 0) begin
                $fwrite(rp_config_file_handle, "ROM[%0d]: Addr=0x%h, Expected_Data=0x%h, Type=%s, Write_Data=0x%h\n", 
                    i, addr_mem_rom[i], expected_data_mem_rom[i],
                    type_mem_rom[i] ? "READ" : "WRITE",
                    data_mem_rom[i]);
            end
        end
        $fwrite(rp_config_file_handle, "\n");
        $fflush(rp_config_file_handle);
    endfunction
endclass