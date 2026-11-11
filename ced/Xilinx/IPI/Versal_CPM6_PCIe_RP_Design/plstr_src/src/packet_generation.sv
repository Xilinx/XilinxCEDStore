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

`timescale 1ps / 1ps

import pcie_intf_pkg::*;

module packet_generation #(
    parameter NUM_SLOTS = 3, 
    parameter FUNC_NUM = 0,
    parameter VFUNC_NUM = 0,
    parameter VFUNC_ACTIVE = 0,
    parameter TX_SLOT_WIDTH = 852,
    parameter DW_SIZE = 32,
    parameter MAX_PAYLOAD_SIZE = 128, // Default payload size
    parameter ACTUAL_PAYLOAD_SIZE_SLOT = 2, // 0-64B payload then 1 slot 65-128B payload then 2 slot
    parameter ACTUAL_PAYLOAD_SIZE_BYTE = 128
)(
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            link_down,      // Link down signal
    input  logic                            halt,           // Halt signal
    input  tx_pkt_intf [NUM_SLOTS-1:0]      tx_pkt_data,   // Input transactions
    input  logic                            is_flitmode,    // Flit mode indicator
    input  logic [3:0]                      payload_end_byte, // End byte for payload

    output tx_intf                          tx_if,          // Output control interface for transactions
    output logic [(NUM_SLOTS)-1:0]          tx_credit_used

);
    logic [(NUM_SLOTS)-1:0]                 end_slot, start_slot; // Slot counters for end and start
    tx_intf                                 tx_if_reg, tx_if_wire; // Wire for output interface
    logic        [NUM_SLOTS-1:0]            tx_pkt_valid;

    logic [511:0]                           data_mask;  // 512-bit mask
    logic [6:0]                             payload_byte_mod;
    logic [(NUM_SLOTS)-1:0]                 tx_credit_used_wire, tx_credit_used_reg; 

    logic [3:0]                             mem_lbe;
    logic [3:0]                             mem_fbe;

    // Define fmt and type for cfg rd/wr type0, mem32 rd, mem64 rd
    localparam CFG_RD_FMT   = 3'b000;
    localparam CFG_WR_FMT   = 3'b010;
    localparam MEM32_RD_FMT = 3'b000;
    localparam MEM64_RD_FMT = 3'b001;
    localparam MEM32_WR_FMT = 3'b010;
    localparam MEM64_WR_FMT = 3'b011;

    localparam CFG_TYPE     = 5'b00100;
    localparam MEM_TYPE_NFM = 5'b00000;
    localparam MEM_TYPE_FM  = 5'b00011;

    // Initialize the data_mask based on payload size
    assign payload_byte_mod = (6'(ACTUAL_PAYLOAD_SIZE_BYTE) == 6'b0) ? 'h40 : {1'b0, 6'(ACTUAL_PAYLOAD_SIZE_BYTE)};
    assign data_mask = ({512{1'b1}} >> (512 - (payload_byte_mod * 8)));

    assign mem_fbe = 4'b1111;
    assign mem_lbe = ACTUAL_PAYLOAD_SIZE_BYTE > 'h4 ? 4'b1111 : 4'b0000;

    ////////////// CONTROL INTERFACE ////////////
    always_comb begin
        tx_if_wire = '{default: '0}; // Initialize output to default values
        end_slot = '0;
        start_slot = '0;
        for (int i = 0; i < NUM_SLOTS; i++) begin
            if (tx_pkt_data[i].pkt_valid) begin
                if (tx_pkt_data[i].pkt_type && tx_pkt_data[i].pkt_info[0]) begin
                    tx_if_wire.tx_end[end_slot] = 1'b1; // Set end signal for posted transactions
                    if(tx_pkt_data[i].pkt_info[2]) begin //mem
                        tx_if_wire.tx_endptr[end_slot] = '{ptr: i, dptr: payload_end_byte}; // Set end pointer to current slot and payload end byte
                    end else begin
                        tx_if_wire.tx_endptr[end_slot] = '{ptr: i, dptr: '0}; // Set end pointer to current slot and no data pointer
                    end
                    end_slot = end_slot + 1; // Increment end slot
                end
                else if(!tx_pkt_data[i].pkt_type) begin
                    tx_if_wire.tx_start[start_slot] = 1'b1; 
                    tx_if_wire.tx_startptr[start_slot] = i; 
                    tx_if_wire.tx_starttype[start_slot] = {1'b0, tx_pkt_data[i].pkt_info[2]}; //01 Rd/NP   00 Wr/P
                    if(tx_pkt_data[i].pkt_info[1:0] != 2'b10) begin
                        tx_if_wire.tx_startnpinfo[start_slot] = {2'b0, tx_pkt_data[i].pkt_info[2]}; //if NP 001 else 000
                    end else begin
                        tx_if_wire.tx_startnpinfo[start_slot] = 3'b0; // If not NP, set to 000
                    end
                    start_slot = start_slot + 1; // Increment start slot
                    if(tx_pkt_data[i].pkt_info[2] && (tx_pkt_data[i].pkt_info[1:0] != 2'b10)) begin
                        // Handle end of packet for NP without Data
                        tx_if_wire.tx_end[end_slot] = 1'b1; // Set end signal for NP transactions
                        tx_if_wire.tx_endptr[end_slot] = '{ptr: i, dptr: '0}; // Set end pointer to current slot and payload end byte
                        end_slot = end_slot + 1; // Increment end slot
                    end
                end

                case ({tx_pkt_data[i].pkt_type, tx_pkt_data[i].pkt_info})
                    // Type is Hdr with info Config WR
                    {1'b0, 3'b110}: begin
                        tx_if_wire.tx_data[i].npd = '{
                            reserved: '0,
                            hdr_prot: '0,
                            dst_segment: '0,
                            segment: '0,
                            prfx: '0,
                            addr_align_en: '0,
                            atu_bypass: '0,
                            bad_eot: '0,
                            ep: '0,
                            st: '0,
                            ph: '0,
                            th: '0,
                            nw: '0,
                            ats: '0,
                            byte_en: {4'b0000, 4'b1111},
                            byte_len: 'b100, //32 bit, 1DW, 4byte
                            td: '0,
                            vfunc_active: VFUNC_ACTIVE,
                            vfunc_num: VFUNC_NUM,
                            func_num: FUNC_NUM,
                            t_bit: '0,
                            tid: tx_pkt_data[i].pkt_tag, // Map pkt_tag to tid
                            remote_req_id: '0,
                            attr: '0,
                            tc: '0,
                            ttype: CFG_TYPE, // Map pkt_type
                            fmt: CFG_WR_FMT, // Map pkt_info
                            addr: tx_pkt_data[i].pkt_addr_data // Map pkt_addr_data to addr
                        };
                    end
                    // Type is Hdr with info Config RD
                    {1'b0, 3'b101}: begin
                        tx_if_wire.tx_data[i].np[0] = '{
                            reserved: '0,
                            dst_segment: '0,
                            segment: '0,
                            prfx: '0,
                            addr_align_en: '0,
                            atu_bypass: '0,
                            bad_eot: '0,
                            ep: '0,
                            st: '0,
                            ph: '0,
                            th: '0,
                            nw: '0,
                            ats: '0,
                            byte_en: {4'b0000, 4'b1111},
                            byte_len: 'b100, //32 bit, 1DW, 4byte
                            td: 0,
                            vfunc_active: VFUNC_ACTIVE,
                            vfunc_num: VFUNC_NUM,
                            func_num: FUNC_NUM,
                            t_bit: '0,
                            tid: tx_pkt_data[i].pkt_tag, // Map pkt_tag to tid
                            remote_req_id: '0,
                            attr: '0,
                            tc: '0,
                            ttype: CFG_TYPE, // Map pkt_type
                            fmt: CFG_RD_FMT, // Map pkt_info
                            addr: tx_pkt_data[i].pkt_addr_data // Map pkt_addr_data to addr
                        };
                    end
                    // Type is Hdr with info Mem32 Wr
                    {1'b0, 3'b000}: begin
                        tx_if_wire.tx_data[i].p = '{
                            reserved: '0,
                            hdr_prot: '0, 
                            dst_segment: '0,
                            segment: '0,
                            prfx: '0,
                            addr_align_en: '0,
                            atu_bypass: '0,
                            bad_eot: '0,
                            ep: '0,
                            st: '0,
                            ph: '0,
                            th: '0,
                            nw: '0,
                            ats: '0,
                            byte_en: {mem_lbe, mem_fbe},
                            byte_len: 13'(ACTUAL_PAYLOAD_SIZE_BYTE),
                            td: '0,
                            vfunc_active: VFUNC_ACTIVE,
                            vfunc_num: VFUNC_NUM,
                            func_num: FUNC_NUM,
                            t_bit: tx_pkt_data[i].pkt_tag, // Map pkt_tag to t_bit
                            tid: tx_pkt_data[i].pkt_tag, // Map pkt_tag to tid
                            remote_req_id: '0,
                            attr: '0,
                            tc: '0,
                            ttype: MEM_TYPE_NFM, // Map pkt_type
                            fmt: MEM32_WR_FMT, // Map pkt_info
                            addr: tx_pkt_data[i].pkt_addr_data // Map pkt_addr_data to addr
                        };
                    end
                    // Type is Hdr with info Mem32 Rd
                    {1'b0, 3'b100}: begin
                        tx_if_wire.tx_data[i].np[0] = '{
                            reserved: '0,
                            dst_segment: '0,
                            segment: '0,
                            prfx: '0,
                            addr_align_en: '0,
                            atu_bypass: '0,
                            bad_eot: '0,
                            ep: '0,
                            st: '0,
                            ph: '0,
                            th: '0,
                            nw: '0,
                            ats: '0,
                            byte_en: {mem_lbe, mem_fbe},
                            byte_len: 13'(ACTUAL_PAYLOAD_SIZE_BYTE),
                            td: '0,
                            vfunc_active: VFUNC_ACTIVE,
                            vfunc_num: VFUNC_NUM,
                            func_num: FUNC_NUM,
                            t_bit: tx_pkt_data[i].pkt_tag, // Map pkt_tag to t_bit
                            tid: tx_pkt_data[i].pkt_tag, // Map pkt_tag to tid
                            remote_req_id: '0,
                            attr: '0,
                            tc: '0,
                            ttype: MEM_TYPE_NFM, // Map pkt_type
                            fmt: MEM32_RD_FMT, // Map pkt_info
                            addr: tx_pkt_data[i].pkt_addr_data // Map pkt_addr_data to addr
                        };
                    end
                    // Type is Hdr with info Mem64 Wr
                    {1'b0, 3'b011}: begin
                        tx_if_wire.tx_data[i].p = '{
                            reserved: '0,
                            hdr_prot: '0, 
                            dst_segment: '0,
                            segment: '0,
                            prfx: '0,
                            addr_align_en: '0,
                            atu_bypass: '0,
                            bad_eot: '0,
                            ep: '0,
                            st: '0,
                            ph: '0,
                            th: '0,
                            nw: '0,
                            ats: '0,
                            byte_en: {mem_lbe, mem_fbe},
                            byte_len: 13'(ACTUAL_PAYLOAD_SIZE_BYTE),
                            td: '0,
                            vfunc_active: VFUNC_ACTIVE,
                            vfunc_num: VFUNC_NUM,
                            func_num: FUNC_NUM,
                            t_bit: tx_pkt_data[i].pkt_tag, // Map pkt_tag to t_bit
                            tid: tx_pkt_data[i].pkt_tag, // Map pkt_tag to tid
                            remote_req_id: '0,
                            attr: '0,
                            tc: '0,
                            ttype: MEM_TYPE_NFM, // Map pkt_type
                            fmt: MEM64_WR_FMT, // Map pkt_info
                            addr: tx_pkt_data[i].pkt_addr_data // Map pkt_addr_data to addr
                        };
                    end
                    // Type is Hdr with info Mem64 Rd
                    {1'b0, 3'b111}: begin
                        tx_if_wire.tx_data[i].np[0] = '{
                            reserved: '0,
                            dst_segment: '0,
                            segment: '0,
                            prfx: '0,
                            addr_align_en: '0,
                            atu_bypass: '0,
                            bad_eot: '0,
                            ep: '0,
                            st: '0,
                            ph: '0,
                            th: '0,
                            nw: '0,
                            ats: '0,
                            byte_en: {mem_lbe, mem_fbe},
                            byte_len: 13'(ACTUAL_PAYLOAD_SIZE_BYTE),
                            td: '0,
                            vfunc_active: VFUNC_ACTIVE,
                            vfunc_num: VFUNC_NUM,
                            func_num: FUNC_NUM,
                            t_bit: '0, 
                            tid: tx_pkt_data[i].pkt_tag, // Map pkt_tag to tid
                            remote_req_id: '0, // RP requester ID - 0:0:0
                            attr: '0,
                            tc: '0,
                            ttype: MEM_TYPE_NFM, // Map pkt_type
                            fmt: MEM64_RD_FMT, // Map pkt_info
                            addr: tx_pkt_data[i].pkt_addr_data // Map pkt_addr_data to addr
                        };
                    end
                    // Type is Data with Mem and not end
                    {1'b1, 3'b100}: begin
                        tx_if_wire.tx_data[i].data = {pcie_str_pkg::DATA_SLOT_WIDTH/DW_SIZE{tx_pkt_data[i].pkt_addr_data[DW_SIZE-1:0]}}; // Repeat data_pattern for all slots
                    end
                    // Type is Data with Mem and end
                    {1'b1, 3'b101}: begin
                        tx_if_wire.tx_data[i].data = {pcie_str_pkg::DATA_SLOT_WIDTH/DW_SIZE{tx_pkt_data[i].pkt_addr_data[DW_SIZE-1:0]}} & data_mask; // Repeat data_pattern uptil mask true or end of payload
                    end
                    // Type is Data with Config and not end
                    {1'b1, 3'b011}: begin
                        tx_if_wire.tx_data[i].data = {{(pcie_str_pkg::DATA_SLOT_WIDTH/DW_SIZE-1){32'h0}}, tx_pkt_data[i].pkt_addr_data[DW_SIZE-1:0]}; // Repeat data_pattern
                    end
                    default : begin
                        tx_if_wire = '{default : '0};
                       end
                endcase
            end
            tx_pkt_valid[i] = tx_pkt_data[i].pkt_valid;
        end
    end
    /////////// END CONTROL INTERFACE //////////


    ////////////// CREDIT MANAGEMENT //////////////
    always_comb begin
        tx_credit_used_wire = '0; // Initialize credit used
        for (int i = 0; i < NUM_SLOTS; i++) begin
            if (tx_pkt_data[i].pkt_valid) begin
                tx_credit_used_wire = tx_credit_used_wire + 1; // Increment credit used for each valid packet
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_credit_used_reg <= '0; // Reset credit used
        end else if (link_down) begin
            tx_credit_used_reg <= '0; // Reset credit used on link down
        end else begin
            tx_credit_used_reg <= tx_credit_used_wire;
        end
    end

    assign tx_credit_used = tx_if_reg.tx_valid ? tx_credit_used_reg : '0; // Output credit used only if tx is valid
    //////////// END CREDIT MANAGEMENT //////////// 

    ////////////// Send to TX if credits are available //////////////
    always_ff @(posedge clk or negedge rst_n ) begin
        if(!rst_n) begin
            // Reset logic
            tx_if_reg <= '{default: '0}; // Reset all output signals
        end else if (link_down) begin
            // Handle link down condition
            tx_if_reg <= '{default: '0}; // Reset all output signals on link down
        end else if (!halt) begin
            // Normal operation, send packets if valid and credits available
            tx_if_reg.tx_data <= tx_if_wire.tx_data; // Send data or header based on pkt_type
            tx_if_reg.tx_start <= tx_if_wire.tx_start; // Start signal
            tx_if_reg.tx_end <= tx_if_wire.tx_end; // End signal
            tx_if_reg.tx_startptr <= tx_if_wire.tx_startptr; // Start pointer
            tx_if_reg.tx_endptr <= tx_if_wire.tx_endptr; // End pointer
            tx_if_reg.tx_starttype <= tx_if_wire.tx_starttype; // Start type
            tx_if_reg.tx_startnpinfo <= tx_if_wire.tx_startnpinfo; // Start NP info       
            tx_if_reg.tx_valid <= |tx_pkt_valid; // Set valid signal if any packet is valid
        end else begin
            // If halted, do not send any packets
            tx_if_reg.tx_valid <= 1'b0; // Clear valid signals on halt
        end
        
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tx_if <= '{default: '0}; // Reset all output signals
        end else if (link_down) begin
            tx_if <= '{default: '0}; // Reset all output signals on link down
        end else begin
            tx_if <= tx_if_reg; // Update output interface
        end
    end

endmodule