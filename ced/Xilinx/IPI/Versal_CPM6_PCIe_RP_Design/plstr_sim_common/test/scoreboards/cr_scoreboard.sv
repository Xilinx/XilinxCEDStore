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

import pcie_str_pkg::*;
import pcie_rp_pkg::*;
import pcie_intf_pkg::*;

class cr_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(cr_scoreboard)

    uvm_analysis_export #(cr_txn) rx_cr_exp;
    uvm_tlm_analysis_fifo #(cr_txn) rx_cr_fifo;

    uvm_analysis_export #(cr_txn) tx_cr_exp;
    uvm_tlm_analysis_fifo #(cr_txn) tx_cr_fifo;

    virtual link_if.monitor_mp link_vif_cr;

    int rx_credits_available = 0;
    int rx_credits_used = 0;
    int rx_credits_received = 0;

    int tx_credits_available = 0;
    int tx_credits_used = 0;
    int tx_credits_received = 0;

    int cr_file_handle;
    string cr_log_file = "credit_log.txt";

    function new(string name, uvm_component parent);
        super.new(name, parent);
        rx_cr_fifo = new("rx_cr_fifo", this);
        tx_cr_fifo = new("tx_cr_fifo", this);
        rx_cr_exp = new("rx_cr_exp", this);
        tx_cr_exp = new("tx_cr_exp", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cr_file_handle = $fopen(cr_log_file, "w");
        if (cr_file_handle == 0) begin
            `uvm_fatal(get_type_name(), $sformatf("Failed to open CR log file: %s", cr_log_file));
        end
        else begin
            `uvm_info(get_type_name(), $sformatf("Credit log file opened: %s", cr_log_file), UVM_LOW);

            $fwrite(cr_file_handle, "=============================================================\n");
            $fwrite(cr_file_handle, "              CREDIT LOG\n");
            $fwrite(cr_file_handle, "=============================================================\n");
            $fflush(cr_file_handle);
        end

        if (!uvm_config_db#(virtual link_if.monitor_mp)::get(this,"","link_if", link_vif_cr)) begin
            `uvm_fatal(get_type_name(), "link_if.monitor_mp is not set");
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        rx_cr_exp.connect(rx_cr_fifo.analysis_export);
        tx_cr_exp.connect(tx_cr_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
    fork
        check_credits();
        check_link_status();
    join
    endtask

    task check_link_status();

        forever begin
            @(posedge link_vif_cr.clk);
            if(link_vif_cr.link_down) begin
                `uvm_info(get_type_name(), "CR_SCOREBOARD: Link is down. resetting CR counts." , UVM_LOW);
                if(cr_file_handle != 0) begin
                    $fwrite(cr_file_handle, "=============================================================\n");
                    $fwrite(cr_file_handle, "[%0t] Link down detected\n", $time);
                    $fwrite(cr_file_handle, "=============================================================\n");
                    $fflush(cr_file_handle);
                end
                
                while(link_vif_cr.link_down) begin
                    @(posedge link_vif_cr.clk);
                end
                `uvm_info(get_type_name(), "CR_SCOREBOARD: Link is back up." , UVM_LOW);
                if(cr_file_handle != 0) begin
                    $fwrite(cr_file_handle, "=============================================================\n");
                    $fwrite(cr_file_handle, " [%0t] Link back up detected\n", $time);
                    $fwrite(cr_file_handle, "=============================================================\n");
                    $fflush(cr_file_handle);
                end

                //Print credit count after link comes back up
                if(cr_file_handle != 0) begin
                    $fwrite(cr_file_handle, " RX CREDITS after reset - Used: %0d, Received: %0d, Available: %0d\n", rx_credits_used, rx_credits_received, rx_credits_available);
                    $fwrite(cr_file_handle, " TX CREDITS after reset - Used: %0d, Received: %0d, Available: %0d\n", tx_credits_used, tx_credits_received,  tx_credits_available);
                    $fflush(cr_file_handle);
                end
            end
        end

    endtask

    task check_credits();
        cr_txn rx_txn;
        cr_txn tx_txn;
        int rx_count = 0;
        int tx_count = 0;
        forever begin
            #1ns;

            // Check RX credits
            rx_cr_fifo.get(rx_txn);
            if(rx_credits_used != rx_txn.credit_used ||
               rx_credits_received != rx_txn.credit_received ||
               rx_credits_available != rx_txn.credit_available) begin
                `uvm_info(get_type_name(), $sformatf("CR_SCOREBOARD: RX Credit Change Detected - Used: %0d -> %0d, Received: %0d -> %0d, Available: %0d -> %0d",
                    rx_credits_used, rx_txn.credit_used,
                    rx_credits_received, rx_txn.credit_received,
                    rx_credits_available, rx_txn.credit_available), UVM_MEDIUM);
                $fwrite(cr_file_handle, "-------------------------------------------------------------\n");
                $fwrite(cr_file_handle, $sformatf("RX Credits - Used: %0d, Received: %0d, Available: %0d\n", rx_txn.credit_used, rx_txn.credit_received, rx_txn.credit_available));
                $fflush(cr_file_handle);
            end

            rx_credits_used = rx_txn.credit_used;
            rx_credits_received = rx_txn.credit_received;
            rx_credits_available = rx_txn.credit_available;           

            if(rx_txn.credit_used < 0 || rx_txn.credit_received < 0 || rx_txn.credit_available < 0) begin
                `uvm_error(get_type_name(), $sformatf("CR_SCOREBOARD: Invalid RX Credit Values - Used: %0d, Received: %0d, Available: %0d", rx_txn.credit_used, rx_txn.credit_received, rx_txn.credit_available));
                $fwrite(cr_file_handle, $sformatf("[%0t] [ERROR] Invalid RX Credit Values - Used: %0d, Received: %0d, Available: %0d\n", $time, rx_txn.credit_used, rx_txn.credit_received, rx_txn.credit_available));
                $fflush(cr_file_handle);
            end
            if(rx_txn.credit_available > (16*pcie_str_pkg::RX_NUM_SLOTS)) begin
                `uvm_error(get_type_name(), $sformatf("CR_SCOREBOARD: RX Credits Available Exceeds Maximum - Available: %0d", rx_txn.credit_available));
                $fwrite(cr_file_handle, $sformatf("[%0t] [ERROR] RX Credits Available Exceeds Maximum - Available: %0d\n", $time, rx_txn.credit_available));
                $fflush(cr_file_handle);
            end

            if(rx_count == 1000) begin
                `uvm_info(get_type_name(), $sformatf("CR_SCOREBOARD: RX Credits - Used: %0d, Received: %0d, Available: %0d", rx_txn.credit_used, rx_txn.credit_received, rx_txn.credit_available), UVM_MEDIUM);
                rx_count = 0;
            end
            rx_count++;


            // Check TX credits
            tx_cr_fifo.get(tx_txn);
            if(tx_credits_used != tx_txn.credit_used ||
               tx_credits_received != tx_txn.credit_received ||
               tx_credits_available != tx_txn.credit_available) begin
                `uvm_info(get_type_name(), $sformatf("CR_SCOREBOARD: TX Credit Change Detected - Used: %0d -> %0d, Received: %0d -> %0d, Available: %0d -> %0d",
                    tx_credits_used, tx_txn.credit_used,
                    tx_credits_received, tx_txn.credit_received,
                    tx_credits_available, tx_txn.credit_available), UVM_MEDIUM);
                $fwrite(cr_file_handle, "-------------------------------------------------------------\n");
                $fwrite(cr_file_handle, $sformatf("TX Credits - Used: %0d, Received: %0d, Available: %0d\n", tx_txn.credit_used, tx_txn.credit_received, tx_txn.credit_available));
                $fflush(cr_file_handle);
            end
            tx_credits_used = tx_txn.credit_used;
            tx_credits_received = tx_txn.credit_received;
            tx_credits_available = tx_txn.credit_available;
            if(tx_txn.credit_used < 0 || tx_txn.credit_received < 0 || tx_txn.credit_available < 0) begin
                `uvm_error(get_type_name(), $sformatf("CR_SCOREBOARD: Invalid TX Credit Values - Used: %0d, Received: %0d, Available: %0d", tx_txn.credit_used, tx_txn.credit_received, tx_txn.credit_available));
                $fwrite(cr_file_handle, $sformatf("[%0t] [ERROR] Invalid TX Credit Values - Used: %0d, Received: %0d, Available: %0d\n", $time, tx_txn.credit_used, tx_txn.credit_received, tx_txn.credit_available));
                $fflush(cr_file_handle);
            end
            if(tx_txn.credit_available > 64) begin
                `uvm_error(get_type_name(), $sformatf("CR_SCOREBOARD: TX Credits Available Exceeds Maximum - Available: %0d", tx_txn.credit_available));
                $fwrite(cr_file_handle, $sformatf("[%0t] [ERROR] TX Credits Available Exceeds Maximum - Available: %0d\n", $time, tx_txn.credit_available));
                $fflush(cr_file_handle);
            end
            if(tx_count == 1000) begin
                `uvm_info(get_type_name(), $sformatf("CR_SCOREBOARD: TX Credits - Used: %0d, Received: %0d, Available: %0d", tx_txn.credit_used, tx_txn.credit_received, tx_txn.credit_available), UVM_MEDIUM);
                tx_count = 0;
            end
            tx_count++;
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Final RX Credits - Used: %0d, Received: %0d, Available: %0d", rx_credits_used, rx_credits_received, rx_credits_available), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Final TX Credits - Used: %0d, Received: %0d, Available: %0d", tx_credits_used, tx_credits_received, tx_credits_available), UVM_LOW);

        $fwrite(cr_file_handle, "=============================================================\n");
        $fwrite(cr_file_handle, $sformatf("Final RX Credits - Used: %0d, Received: %0d, Available: %0d\n", rx_credits_used, rx_credits_received, rx_credits_available));
        $fwrite(cr_file_handle, $sformatf("Final TX Credits - Used: %0d, Received: %0d, Available: %0d\n", tx_credits_used, tx_credits_received, tx_credits_available));
        $fwrite(cr_file_handle, "=============================================================\n");

        if(tx_credits_available != 64) begin
            `uvm_error(get_type_name(), $sformatf("Final TX Credits Available is not as expected: %0d (expected 64)", tx_credits_available));
            $fwrite(cr_file_handle, "[%0t] [ERROR] Final TX Credits Available is not as expected: %0d (expected 64)\n", $time, tx_credits_available);
        end
        else begin
            `uvm_info(get_type_name(), "Final TX Credits Available is as expected: 64", UVM_LOW);
            $fwrite(cr_file_handle, "[%0t] [INFO] Final TX Credits Available is as expected: 64\n", $time);
        end

        if(rx_credits_available != 16*pcie_str_pkg::RX_NUM_SLOTS) begin
            `uvm_error(get_type_name(), $sformatf("Final RX Credits Available is not as expected: %0d (expected %0d)", rx_credits_available, 16*pcie_str_pkg::RX_NUM_SLOTS));
            $fwrite(cr_file_handle, "[%0t] [ERROR] Final RX Credits Available is not as expected: %0d (expected %0d)\n", $time, rx_credits_available, 16*pcie_str_pkg::RX_NUM_SLOTS);
        end
        else begin
            `uvm_info(get_type_name(), $sformatf("Final RX Credits Available is as expected: %0d", 16*pcie_str_pkg::RX_NUM_SLOTS), UVM_LOW);
            $fwrite(cr_file_handle, "[%0t] [INFO] Final RX Credits Available is as expected: %0d\n", $time, 16*pcie_str_pkg::RX_NUM_SLOTS);
        end
        
        $fflush(cr_file_handle);

        $fclose(cr_file_handle);
    endfunction
endclass