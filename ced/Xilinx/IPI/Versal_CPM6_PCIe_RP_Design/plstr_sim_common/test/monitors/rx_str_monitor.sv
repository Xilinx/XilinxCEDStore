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

class rx_str_monitor extends uvm_monitor;
  
    `uvm_component_utils(rx_str_monitor)

    virtual rx_str_if.monitor_mp vif;
    virtual cr_str_if.monitor_mp rx_cr_vif;

    virtual link_if.monitor_mp link_vif;

    uvm_analysis_port #(rx_str_txn) ap;
    uvm_analysis_port #(cr_txn) cr_ap;

    int rx_credits_available = 0;
    int rx_credits_used = 0;
    int rx_credits_received = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
        cr_ap = new("cr_ap", this);
        `uvm_info(get_type_name(), $sformatf("Created %s", name), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Created %s", ap.get_name()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Created %s", cr_ap.get_name()), UVM_LOW);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual rx_str_if.monitor_mp)::get(this, "", "rx_str_if", vif)) begin
            `uvm_fatal(get_type_name(), "rx_str_if.monitor_mp is not set");
        end
        if (!uvm_config_db#(virtual cr_str_if.monitor_mp)::get(this, "", "rx_cr_vif", rx_cr_vif)) begin
            `uvm_fatal(get_type_name(), "cr_str_if.monitor_mp is not set");
        end
        if (!uvm_config_db#(virtual link_if.monitor_mp)::get(this,"","link_if", link_vif)) begin
            `uvm_fatal(get_type_name(), "link_if.monitor_mp is not set");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            monitor_rx_credits();
            monitor_rx_str();
        join
    endtask

    virtual task monitor_rx_str();
        int txn_count = 0;
        int curr_start;
        int curr_end;
        int curr_valid;
        logic [2:0][START_PTR_WIDTH-1:0] start_ptr;
        logic [2:0][END_PTR_WIDTH-1:0] end_ptr;
        logic [2:0][END_DPTR_WIDTH-1:0] end_be;
        rx_str_txn txn;
        cr_txn rx_cr_txn;
        rx_cr_txn = cr_txn::type_id::create("txn", this);
        forever begin
            @(posedge vif.clk);
            if(vif.rx_intf.rx_valid) begin
                curr_start = 0;
                curr_end   = 0;
                curr_valid = 0;
                // txn_count = txn_count_reg;
                start_ptr = vif.rx_intf.rx_startptr; // {vif.rx_intf.rx_start2_ptr, vif.rx_intf.rx_start1_ptr, vif.rx_intf.rx_start0_ptr};
                end_ptr   = {vif.rx_intf.rx_endptr[2].ptr, vif.rx_intf.rx_endptr[1].ptr, vif.rx_intf.rx_endptr[0].ptr};
                end_be    = {vif.rx_intf.rx_endptr[2].dptr, vif.rx_intf.rx_endptr[1].dptr, vif.rx_intf.rx_endptr[0].dptr};
                for(int i = 0; i < pcie_str_pkg::TX_NUM_SLOTS; i++) begin
                    txn = rx_str_txn::type_id::create("txn", this);
                    if(vif.rx_intf.rx_start[curr_start] && (start_ptr[curr_start] == i)) begin
                        txn.txn_start = 1;
                        txn.txn_h_or_d = 1;
                        curr_start++;
                        txn_count++;
                    end else begin
                        txn.txn_start = 0;
                        txn.txn_h_or_d = 0;
                    end
                    if(vif.rx_intf.rx_end[curr_end] && (end_ptr[curr_end] == i)) begin
                        txn.txn_end = 1;
                        txn.txn_end_dptr = end_be[curr_end*END_DPTR_WIDTH +: END_DPTR_WIDTH];
                        txn.txn_end_error = vif.rx_intf.rx_end_error[curr_end*3 +: 3];
                        curr_end++;
                        txn_count--;
                    end else begin
                        txn.txn_end = 0;
                        txn.txn_end_dptr = '0;
                        txn.txn_end_error = '0;
                    end

                    txn.txn_valid     = txn.txn_end ? 1'b1 : txn_count > 0;
                    if(txn.txn_h_or_d) begin
                        txn.txn_type  =  encode_txn_type(vif.rx_intf.rx_data[i].cpl.fmt, vif.rx_intf.rx_data[i].cpl.ttype);
                    end
                    else begin
                        txn.txn_type  = -1;
                    end

                    if(txn.txn_valid) begin
                        txn.txn_data      = vif.rx_intf.rx_data[i];
                        curr_valid++;
                        ap.write(txn);
                        `uvm_info(get_type_name(), $sformatf("RX_STR MONITOR: Sent txn: %s , %s", txn.sprint(), txn.txn_h_or_d ? $sformatf("Status: 0x%h", txn.txn_data.cpl.status) : ""), UVM_MEDIUM);
                    end
                end
                rx_credits_used = rx_credits_used + curr_valid;
                
                // `uvm_info(get_type_name(), $sformatf("RX_STR MONITOR: Credits - Used: %0d, Received: %0d, Available: %0d", rx_credits_used, rx_credits_received, rx_credits_available), UVM_LOW);
            end
                rx_credits_available = rx_credits_received - rx_credits_used;
                rx_cr_txn.credit_used = rx_credits_used;
                rx_cr_txn.credit_received = rx_credits_received;
                rx_cr_txn.credit_available = rx_credits_available;
                cr_ap.write(rx_cr_txn);

                if(link_vif.link_down) begin
                    rx_credits_available = 0;
                    rx_credits_used = 0;
                    rx_cr_txn.credit_used = 0;
                    rx_cr_txn.credit_received = 0;
                    rx_cr_txn.credit_available = 0;
                end
        end
    endtask

    virtual function int encode_txn_type(logic [1:0] fmt, logic [4:0] ttype);
        int enc_type; //P; NP; NPD; CPL; CPLD; MSG
        casex({fmt, ttype})
            7'b100_0000: enc_type = 0;
            7'b110_0000: enc_type = 0;
            7'b000_0000: enc_type = 1;
            7'b010_0000: enc_type = 1;
            7'b000_0100: enc_type = 1;
            7'b000_0101: enc_type = 1;
            7'b100_0100: enc_type = 2;
            7'b100_0101: enc_type = 2;
            7'b000_1010: enc_type = 3;
            7'b100_1010: enc_type = 4;
            7'b011_0xxx: enc_type = 5;
            7'b111_0xxx: enc_type = 5;
            default:     enc_type = -1;
        endcase

        `uvm_info(get_type_name(), $sformatf("RX_STR_MONITOR: Encoded Transaction Type - %0d, Format: %0d, TTYPE: %0d", enc_type, fmt, ttype), UVM_MEDIUM);

        return enc_type;

    endfunction

    virtual task monitor_rx_credits();
        forever begin
            @(posedge rx_cr_vif.clk);
            if(rx_cr_vif.cr_active) begin
                if(rx_cr_vif.cr_valid) begin
                    rx_credits_received = rx_credits_received + decode_credit(rx_cr_vif.cr);
                end
            end

            if(link_vif.link_down) begin
                rx_credits_received = 0;
            end
        end
    endtask

    function automatic logic [6:0] decode_credit(input logic [2:0] encoded);
        case (encoded)
            3'b111:  return 7'd64;
            3'b110:  return 7'd32;
            3'b101:  return 7'd16;
            3'b100:  return 7'd8;
            3'b011:  return 7'd4;
            3'b010:  return 7'd2;
            3'b001:  return 7'd1;
            default: return 7'd0;
        endcase
    endfunction

endclass