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
import pcie_str_pkg::*;

module cpl_checker #(
    parameter NUM_SLOTS = 3,
    parameter BUFFER_DEPTH = 64,
    parameter MAX_PAYLOAD_SIZE = 128,
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 32,
    parameter CHECKER_DEPTH = 1024,
    parameter CHECKER_ADDR_WIDTH = 7,
    parameter CHECKER_DATA_WIDTH = 32,
    parameter ERROR_CNT_WIDTH = 16,
    parameter TAG_COUNT = 32, // Number of tags available
    parameter ACTUAL_PAYLOAD_SIZE_SLOT = 2,
    parameter ACTUAL_PAYLOAD_SIZE_BYTE = 128, // Actual payload size in bytes
    parameter IDE_EN = 0 // 1: slot check masked like expected-data (config-bridge reads have no expected data)
) (
    input  logic                                                clk,
    input  logic                                                rst_n,
    input  logic                                                link_down,

    input  logic [CHECKER_DATA_WIDTH-1:0]                       cfg_checker_ram_rd_data,
    input  logic [CHECKER_ADDR_WIDTH+CHECKER_DATA_WIDTH-1:0]    mem_checker_ram_rd_data,

    input logic [15:0]                                          ep_cfg_count,

    output error_counters_t                                     error_counts,

    output logic [$clog2(CHECKER_DEPTH)-1:0]                    cfg_checker_ram_rd_addr,
    output logic                                                cfg_checker_ram_rd_en,
    output logic [$clog2(CHECKER_DEPTH)-1:0]                    mem_checker_ram_rd_addr,
    output logic                                                mem_checker_ram_rd_en,

    output logic                                                free_tag_valid, // Indicate if a free tag is available
    output logic [$clog2(TAG_COUNT)-1:0]                        free_tag, // Free tag to be used
    output logic [(NUM_SLOTS)-1:0]                              credits_to_return,
    output logic                                                cpl_received, // Indicate if a completion has been received
    output logic [DATA_WIDTH-1:0]                               cpl_to_config_mem_handler, // Completion data to be sent to config mem handler
    output logic                                                ep_cfg_match,

    //READ FIFO INTERFACE
    input  rx_cpl_intf  [NUM_SLOTS-1:0]                         read_fifo,
    input logic                                                 total_fifo_empty,
    input logic                                                 total_fifo_almost_empty,
    output logic [NUM_SLOTS-1:0]                                rd_en_out,

    input logic [$clog2(TAG_COUNT)-1:0]                         tag_to_match,
    input logic                                                 bar_read_done
);

    localparam ACTUAL_PAYLOAD_SIZE_DW = ACTUAL_PAYLOAD_SIZE_BYTE / 4;
    localparam ACTUAL_PAYLOAD_SIZE_DW_MOD = ACTUAL_PAYLOAD_SIZE_DW % 16 ? ACTUAL_PAYLOAD_SIZE_DW % 16 : 16; // if ACTUAL_PAYLOAD_SIZE_DW is multiple of 16 DW, then the last slot would have 16 DWs, else the modulus DWs
    localparam NUM_SLOTS_WIDTH = $clog2(NUM_SLOTS);

    rx_cpl_intf [NUM_SLOTS-1:0]                         read_fifo_reg, slots_read; // Registered read FIFO interface
    logic       [NUM_SLOTS-1:0]                         slot_valid;
    rx_cpl_intf [NUM_SLOTS-1:0]                         slot_to_checker_r, slot_to_checker_r2; // Slots to checker interface
    logic       [NUM_SLOTS-1:0]                         rd_en_wire;

    logic [9:0]                                         tag, tag_reg; // Tag register
    logic                                               req_checker_buf; // Request from checker buffer

    logic [15:0]                                        ep_cfg_rcvd, ep_cfg_rcvd_reg; // EP config read received count
    logic                                               free_tag_valid_wire; // Indicate if a free tag is available
    logic [$clog2(TAG_COUNT)-1:0]                       free_tag_wire; // Free tag to be used

    logic                                               addr_err, addr_err_reg;
    logic                                               data_err_reg;
    logic                                               URs, URs_reg;
    logic                                               CAs, CAs_reg;
    logic                                               cfg_retry_err, cfg_retry_err_reg;
    logic                                               tlp_or_dllp_abort_err, tlp_or_dllp_abort_err_reg;
    logic                                               tlp_poisoned, tlp_poisoned_reg; // TLP poisoned error
    logic                                               fmt_mismatch, fmt_mismatch_reg; // Format mismatch error
    logic                                               ttype_mismatch, ttype_mismatch_reg; // TTYPE mismatch error

    logic [6:0]                                         count_credit; // Count of credits to return

    logic                                               cpl_received_wire; // Indicate if a completion has been received
    logic [DATA_WIDTH-1:0]                              cpl_to_config_mem_handler_wire; // Completion data to be sent to config mem handler

    logic [2:0]                                         num_slots_to_read, num_slots_to_read_reg, cir_ptr_next, cir_ptr_reg, cir_ptr_reg_reg; // Number of slots to read

    logic                                               ep_cfg_match_r2, ep_cfg_match_r, ep_cfg_match_wire; // EP config match register and wire

    logic [$clog2(CHECKER_DEPTH)-1:0]                   cfg_checker_ram_rd_addr_wire;
    logic                                               cfg_checker_ram_rd_en_wire;
    logic [$clog2(CHECKER_DEPTH)-1:0]                   mem_checker_ram_rd_addr_wire;
    logic                                               mem_checker_ram_rd_en_wire;

    logic                                               cpl_valid_wire, cpl_valid_r,cpl_valid_r2;
    logic [6:0]                                         addr_wire, addr_reg, addr_reg2;
    logic [2:0]                                         status_wire, status_reg;
    logic [END_ERROR_WIDTH-1:0]                         end_error_wire, end_error_reg;
    logic                                               tlp_abort_wire, tlp_abort_reg;
    logic                                               dllp_abort_wire, dllp_abort_reg;
    logic [1:0]                                         fmt_wire, fmt_reg;
    logic [4:0]                                         ttype_wire, ttype_reg;
    logic [NUM_SLOTS-1:0][511:0]                        data_wire, data_reg;
    logic [NUM_SLOTS-1:0]                               data_valid_wire, data_valid_r, data_valid_r2;
    logic [NUM_SLOTS-1:0]                               data_end_wire, data_end_reg, data_end_reg2;
    logic [31:0]                                        data_dw, data_dw_reg;
    logic                                               internal_slot_data_err, internal_slot_data_err_reg;
    logic                                               internal_expected_data_err, internal_expected_data_err_reg;
    logic                                               slot_mismatch_reg;
    logic                                               expected_data_err, expected_data_err_reg;

    logic [CHECKER_DATA_WIDTH-1:0]                      expected_data;
    logic [CHECKER_ADDR_WIDTH-1:0]                      expected_addr;

    logic                                               match_data_reg, match_data_reg2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic
            read_fifo_reg <= '0;
            cir_ptr_reg <= '0;
            cir_ptr_reg_reg <= '0;
            num_slots_to_read_reg <= '0;
        end else if (link_down) begin
            // Link down logic
            read_fifo_reg <= '0;
            cir_ptr_reg <= '0;
            cir_ptr_reg_reg <= '0;
            num_slots_to_read_reg <= '0;
        end else begin
            // Sequential logic
            read_fifo_reg <= !total_fifo_empty ? read_fifo : '0;
            cir_ptr_reg <= cir_ptr_next;
            cir_ptr_reg_reg <= cir_ptr_reg;
            num_slots_to_read_reg <= num_slots_to_read;
        end
    end


    generate
        if(NUM_SLOTS == 3) begin : gen_3_slots
            always_comb begin
                num_slots_to_read = '0;
                cir_ptr_next = cir_ptr_reg;
                if(!total_fifo_empty) begin
                    if(read_fifo[cir_ptr_reg].cpl_data.cpl.dw_len == 0) begin
                        num_slots_to_read = 1; // If DW length is 0, read 1 slot
                        cir_ptr_next = (cir_ptr_reg + 1) % NUM_SLOTS;
                    end else if(read_fifo[cir_ptr_reg].cpl_data.cpl.dw_len <= 16) begin
                        num_slots_to_read = 2; // If DW length is <= 16, read 2 slots
                        cir_ptr_next = (cir_ptr_reg + 2) % NUM_SLOTS;
                    end else begin
                        num_slots_to_read = 3; // Else read 3 slots
                        cir_ptr_next = (cir_ptr_reg + 3) % NUM_SLOTS;
                    end
                end
            end

            always_comb begin
                rd_en_wire = '0; // Default to no read
                case ({num_slots_to_read,cir_ptr_reg})
                    {3'd1, 3'd0}: rd_en_wire = 3'b001; // Read 1 slot if buffer not empty
                    {3'd1, 3'd1}: rd_en_wire = 3'b010; // Read 1 slot if buffer not empty
                    {3'd1, 3'd2}: rd_en_wire = 3'b100; // Read 1 slot if buffer not empty
                    {3'd2, 3'd0}: rd_en_wire = 3'b011; // Read 2 slots if buffer not empty
                    {3'd2, 3'd1}: rd_en_wire = 3'b110; // Read 2 slots if buffer not empty
                    {3'd2, 3'd2}: rd_en_wire = 3'b101; // Read only available slot if buffer not empty
                    {3'd3, 3'd0}: rd_en_wire = 3'b111; // Read all 3 slots if buffer not empty
                    {3'd3, 3'd1}: rd_en_wire = 3'b111; // Read only available slots if buffer not empty
                    {3'd3, 3'd2}: rd_en_wire = 3'b111; // Read only available slot if buffer not empty
                    default: rd_en_wire = '0; // Default to no read
                endcase
            end
        end

        else if (NUM_SLOTS == 2) begin : gen_2_slots

            typedef enum logic [1:0] {
                RD_HDR = 2'b00,
                RD_DATA = 2'b01
            } fifo_state_t;
            fifo_state_t current_fifo_state, next_fifo_state;

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    current_fifo_state <= RD_HDR;
                end else if (link_down) begin
                    current_fifo_state <= RD_HDR;
                end else begin
                    current_fifo_state <= next_fifo_state;
                end
            end

            always_comb begin
                next_fifo_state = current_fifo_state;
                num_slots_to_read = '0;
                cir_ptr_next = cir_ptr_reg;
                rd_en_wire = '0; // Default to no read
                case (current_fifo_state)
                    RD_HDR: begin
                        if (!total_fifo_empty) begin
                            if(read_fifo[cir_ptr_reg].cpl_data.cpl.dw_len > 0) begin
                                num_slots_to_read = 2;
                                cir_ptr_next = cir_ptr_reg;
                                rd_en_wire = 2'b11; // Read both slots if buffer not empty
                            end else begin
                                num_slots_to_read = 1;
                                cir_ptr_next = (cir_ptr_reg + 1) % NUM_SLOTS;
                                rd_en_wire = (cir_ptr_reg == 0) ? 2'b01 : 2'b10; // Read only available slot if buffer not empty
                            end
                            next_fifo_state = read_fifo[cir_ptr_reg].cpl_data.cpl.dw_len > 16 ? RD_DATA : RD_HDR;
                        end
                    end
                    RD_DATA: begin
                        num_slots_to_read = 1;
                        cir_ptr_next = (cir_ptr_reg + 1) % NUM_SLOTS;
                        next_fifo_state = RD_HDR;
                        rd_en_wire = (cir_ptr_reg == 0) ? 2'b01 : 2'b10; // Read only available slot if buffer not empty
                    end
                    default: begin
                        num_slots_to_read = '0;
                        cir_ptr_next = cir_ptr_reg;
                        next_fifo_state = RD_HDR;
                        rd_en_wire = '0; // Default to no read
                    end
                endcase
            end
        end

        else if (NUM_SLOTS == 1) begin : gen_1_slot
            always_comb begin
                num_slots_to_read = '0;
                cir_ptr_next = cir_ptr_reg;
                if(!total_fifo_empty) begin
                    num_slots_to_read = 1; // Always read 1 slot if not empty
                end
            end

            always_comb begin
                rd_en_wire = '0; // Default to no read
                case (num_slots_to_read)
                    3'd1: rd_en_wire = 1'b1; // Read 1 slot if buffer not empty
                    default: rd_en_wire = '0; // Default to no read
                endcase
            end
        end
    endgenerate

    assign rd_en_out = rd_en_wire; // Assign read enable output

    always_comb begin
        slots_read = '0;
        for (logic[1:0] i = 0; i < NUM_SLOTS; i++) begin
            slots_read[i] = read_fifo_reg[(cir_ptr_reg_reg + i)%NUM_SLOTS];
        end 
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slot_to_checker_r <= '0; // Reset slots read register
            slot_to_checker_r2 <= '0; // Reset slots read register
        end else if (link_down) begin
            slot_to_checker_r <= '0; // Reset on link down
            slot_to_checker_r2 <= '0; // Reset on link down
        end else begin
            for (int i = 0; i < NUM_SLOTS; i++) begin
                if(slot_valid[i]) begin
                    slot_to_checker_r[i] <= slots_read[i]; // Update slots read register for valid reads
                end else begin
                    slot_to_checker_r[i] <= '0; // Clear unused slots
                end
                slot_to_checker_r2[i] <= slot_to_checker_r[i]; // Pipeline stage 2
            end
        end
    end

    always_comb begin
        slot_valid = '0;
        case (num_slots_to_read_reg)
            2'd0: slot_valid = 3'b000; // No slots to read
            2'd1: slot_valid = 3'b001; // Read 1 slot
            2'd2: slot_valid = 3'b011; // Read 2 slots
            2'd3: slot_valid = 3'b111; // Read all 3 slots
            default: slot_valid = 3'b000; // Default to no slots
        endcase
    end



/////////////////////////////////////////////////////////////////////////

    ////// GET TAG //////////////////

    always_comb begin
        req_checker_buf = 1'b0; // Initialize request from checker buffer
        tag = tag_reg; // Initialize tag
        
        // Send to Config Mem Handler
        cpl_to_config_mem_handler_wire = '0; // Initialize completion to config mem handler
        cpl_received_wire = 1'b0; // Initialize completion received flag

        for(int i = 0; i < NUM_SLOTS; i++) begin
            if (slot_to_checker_r[i].cpl_valid && slot_to_checker_r[i].cpl_type) begin
                tag = slot_to_checker_r[i].cpl_data.cpl.tag; // Get tag from completion header
                req_checker_buf = 1'b1; // Set request from checker buffer
                if(|slot_to_checker_r[i].cpl_data.cpl.status == 1'b1 && tag == tag_to_match) begin
                    // If status is not 0, it's an error completion
                    cpl_to_config_mem_handler_wire = 32'hffff_ffff; // Indicate error completion
                    cpl_received_wire = 1'b1; // Set completion received flag
                end
            end
            else if (slot_to_checker_r[i].cpl_valid && !slot_to_checker_r[i].cpl_type) begin
                //add completion received = 1 logic and data = lower 32 bits of recvd data
                cpl_to_config_mem_handler_wire = slot_to_checker_r[i].cpl_data.data[DATA_WIDTH-1:0]; // Get completion data
                cpl_received_wire = !slot_to_checker_r[i].cpl_start ? 1'b1 : 1'b0; // Set completion received flag
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpl_received <= 1'b0; // Reset completion received flag
            cpl_to_config_mem_handler <= '0; // Reset completion to config mem handler
        end else if (link_down) begin
            cpl_received <= 1'b0; // Reset on link down
            cpl_to_config_mem_handler <= '0; // Reset completion to config mem handler on link down
        end else begin
            cpl_received <= cpl_received_wire; // Update completion received flag
            cpl_to_config_mem_handler <= cpl_to_config_mem_handler_wire; // Update completion to config mem handler
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tag_reg <= '0; // Reset tag register
        end else if (link_down) begin
            tag_reg <= '0; // Reset on link down
        end else begin
            tag_reg <= tag; // Update tag register
        end
    end


    always_comb begin
        cfg_checker_ram_rd_en_wire = 1'b0; // Initialize config checker RAM read enable
        cfg_checker_ram_rd_addr_wire = '0; // Initialize config checker RAM read address
        mem_checker_ram_rd_en_wire = 1'b0; // Initialize memory checker RAM read enable
        mem_checker_ram_rd_addr_wire = '0; // Initialize memory checker RAM read address
        case(ep_cfg_match_r) 
            1'b0: begin
                cfg_checker_ram_rd_en_wire = req_checker_buf; // Enable read from checker RAM if request from checker buffer
                cfg_checker_ram_rd_addr_wire = tag; // Use tag as read address for checker RAM
            end
            1'b1: begin
                mem_checker_ram_rd_en_wire = req_checker_buf; 
                mem_checker_ram_rd_addr_wire = tag; 
            end
            default: begin
                cfg_checker_ram_rd_en_wire = 1'b0; // Default case, disable read from checker RAM
                cfg_checker_ram_rd_addr_wire = '0; // Reset read address for checker RAM
                mem_checker_ram_rd_en_wire = 1'b0; // Disable read from checker RAM
                mem_checker_ram_rd_addr_wire = '0; // Reset read address for checker RAM
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cfg_checker_ram_rd_en <= 1'b0; // Reset config checker RAM read enable register
            cfg_checker_ram_rd_addr <= '0; // Reset config checker RAM read address register
            mem_checker_ram_rd_en <= 1'b0; // Reset memory checker RAM read enable
            mem_checker_ram_rd_addr <= '0; // Reset memory checker RAM read address register
        end else if (link_down) begin
            cfg_checker_ram_rd_en <= 1'b0; // Reset on link down
            cfg_checker_ram_rd_addr <= '0; // Reset on link down
            mem_checker_ram_rd_en <= 1'b0; // Reset on link down
            mem_checker_ram_rd_addr <= '0; // Reset on link down
        end else begin
            cfg_checker_ram_rd_en <= cfg_checker_ram_rd_en_wire; // Update config checker RAM read
            cfg_checker_ram_rd_addr <= cfg_checker_ram_rd_addr_wire; // Update config checker RAM read address
            mem_checker_ram_rd_en <= mem_checker_ram_rd_en_wire; // Update memory checker RAM read
            mem_checker_ram_rd_addr <= mem_checker_ram_rd_addr_wire; // Update memory checker RAM read address
        end
    end

    assign ep_cfg_match_wire = ep_cfg_rcvd_reg == ep_cfg_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ep_cfg_match_r <= 1'b0; // Reset EP config match register
            ep_cfg_match_r2 <= 1'b0; // Reset EP config match register 2
        end else if (link_down) begin
            ep_cfg_match_r <= 1'b0; // Reset on link down
            ep_cfg_match_r2 <= 1'b0; // Reset on link down
        end else begin
            ep_cfg_match_r <= ep_cfg_match_wire; // Update EP config match register
            ep_cfg_match_r2 <= ep_cfg_match_r; // Pipeline stage 2
        end
    end

    assign ep_cfg_match = ep_cfg_match_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_counts <= '0; // Reset error counters
        end else if (link_down) begin
            error_counts <= '0; // Reset error counters on link down
        end else begin
            // Update error counters based on addr_err and data_err
            error_counts.addr_mismatch_cnt <= error_counts.addr_mismatch_cnt + addr_err_reg; // Increment address mismatch counter
            error_counts.data_mismatch_cnt <= error_counts.data_mismatch_cnt + data_err_reg; // Increment data mismatch counter
            error_counts.URs_cnt <= error_counts.URs_cnt + URs_reg; // Increment URs counter
            error_counts.CAs_cnt <= error_counts.CAs_cnt + CAs_reg; // Increment CAs counter
            error_counts.cfg_retry_err_cnt <= error_counts.cfg_retry_err_cnt + cfg_retry_err_reg; // Increment configuration retry error counter
            error_counts.tlp_or_dllp_abort_err_cnt <= error_counts.tlp_or_dllp_abort_err_cnt + tlp_or_dllp_abort_err_reg; // Increment TLP or DLLP abort error counter
            error_counts.tlp_poisoned_cnt <= error_counts.tlp_poisoned_cnt + tlp_poisoned_reg; // Increment TLP poisoned counter
            error_counts.fmt_mismatch_cnt <= error_counts.fmt_mismatch_cnt + fmt_mismatch_reg; // Increment format mismatch counter
            error_counts.ttype_mismatch_cnt <= error_counts.ttype_mismatch_cnt + ttype_mismatch_reg; // Increment TTYPE mismatch counter
        end
    end

    always_comb begin
        
        cpl_valid_wire = 1'b0; // Initialize completion valid wire
        addr_wire = '0;
        data_wire = '0;
        status_wire = '0;
        end_error_wire = '0;
        fmt_wire = '0;
        ttype_wire = '0;
        data_valid_wire = '0;
        data_end_wire = '0;
        tlp_abort_wire = '0;
        dllp_abort_wire = '0;


        ////////////SPECIFIC CASE//////////////////
        if(NUM_SLOTS == 3) begin
            case(ep_cfg_match_r)
                1'b0: begin
                    // Handle case where ep_cfg_match_r is 0
                    if(slot_to_checker_r2[0].cpl_valid) begin
                        // GET HEADER FIELDS
                        cpl_valid_wire = 1'b1; // Set completion valid wire
                        addr_wire = slot_to_checker_r2[0].cpl_data.cpl.addr; // Get address from completion header
                        status_wire = slot_to_checker_r2[0].cpl_data.cpl.status; // Get status from completion header
                        fmt_wire = slot_to_checker_r2[0].cpl_data.cpl.fmt; // Get format from completion header
                        ttype_wire = slot_to_checker_r2[0].cpl_data.cpl.ttype; // Get TTYPE from completion header
                        tlp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.tlp_abort; // Get TLP abort from completion header
                        dllp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.dllp_abort; // Get DLLP abort from completion header
                        if(slot_to_checker_r2[0].cpl_end) begin
                            end_error_wire = slot_to_checker_r2[0].cpl_end_error; // Get end error from completion end
                        end 
                    end 
                    if(slot_to_checker_r2[1].cpl_valid) begin
                        // GET DATA FIELDS 
                        data_wire[1] = slot_to_checker_r2[1].cpl_data.data[511:0]; // Get data from completion data
                        data_valid_wire[1] = 1'b1; // Set data valid if data slot is valid
                        if(slot_to_checker_r2[1].cpl_end) begin
                            data_end_wire[1] = 1'b1; // Set data end if end bit is set
                            end_error_wire = slot_to_checker_r2[1].cpl_end_error; // Get end error from completion end
                        end
                    end
                end
                1'b1: begin
                    // Handle case where ep_cfg_match_r is 1
                    if(slot_to_checker_r2[0].cpl_valid) begin
                        // GET HEADER FIELDS
                        cpl_valid_wire = 1'b1; // Set completion valid wire
                        addr_wire = slot_to_checker_r2[0].cpl_data.cpl.addr; // Get address from completion header
                        status_wire = slot_to_checker_r2[0].cpl_data.cpl.status; // Get status from completion header
                        fmt_wire = slot_to_checker_r2[0].cpl_data.cpl.fmt; // Get format from completion header
                        ttype_wire = slot_to_checker_r2[0].cpl_data.cpl.ttype; // Get TTYPE from completion header
                        tlp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.tlp_abort; // Get TLP abort from completion header
                        dllp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.dllp_abort; // Get DLLP abort from completion header
                    end 

                    // GET DATA FIELDS
                    if(slot_to_checker_r2[1].cpl_valid) begin
                        data_wire[1] = slot_to_checker_r2[1].cpl_data.data[511:0]; // Get data from completion data
                        data_valid_wire[1] = 1'b1; // Set data valid if data slot is valid
                        if(slot_to_checker_r2[1].cpl_end) begin
                            data_end_wire[1] = 1'b1; // Set data end if end bit is set
                            end_error_wire = slot_to_checker_r2[1].cpl_end_error; // Get end error from completion end
                        end
                    end
                    if(slot_to_checker_r2[2].cpl_valid) begin
                        data_wire[2] = slot_to_checker_r2[2].cpl_data.data[511:0]; // Get data from completion data
                        data_valid_wire[2] = 1'b1; // Set data valid if data slot is valid
                        if(slot_to_checker_r2[2].cpl_end) begin
                            data_end_wire[2] = 1'b1; // Set data end if end bit is set
                            end_error_wire = slot_to_checker_r2[2].cpl_end_error; // Get end error from completion end
                        end
                    end                     
                end
            endcase
        end

        if(NUM_SLOTS == 2) begin
            case(ep_cfg_match_r)
                1'b0: begin
                    // Handle case where ep_cfg_match_r is 0
                    if(slot_to_checker_r2[0].cpl_valid) begin
                        // GET HEADER FIELDS
                        cpl_valid_wire = 1'b1; // Set completion valid wire
                        addr_wire = slot_to_checker_r2[0].cpl_data.cpl.addr; // Get address from completion header
                        status_wire = slot_to_checker_r2[0].cpl_data.cpl.status; // Get status from completion header
                        fmt_wire = slot_to_checker_r2[0].cpl_data.cpl.fmt; // Get format from completion header
                        ttype_wire = slot_to_checker_r2[0].cpl_data.cpl.ttype; // Get TTYPE from completion header
                        tlp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.tlp_abort; // Get TLP abort from completion header
                        dllp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.dllp_abort; // Get DLLP abort from completion header
                        if(slot_to_checker_r2[0].cpl_end) begin
                            end_error_wire = slot_to_checker_r2[0].cpl_end_error; // Get end error from completion end
                        end
                    end
                    if(slot_to_checker_r2[1].cpl_valid) begin
                        // GET DATA FIELDS 
                        data_wire[1] = slot_to_checker_r2[1].cpl_data.data[511:0]; // Get data from completion data
                        data_valid_wire[1] = 1'b1; // Set data valid if data slot is valid
                        if(slot_to_checker_r2[1].cpl_end) begin
                            data_end_wire[1] = 1'b1; // Set data end if end bit is set
                            end_error_wire = slot_to_checker_r2[1].cpl_end_error; // Get end error from completion end
                        end
                    end
                end
                1'b1: begin
                    // Handle case where ep_cfg_match_r is 1
                    if(slot_to_checker_r2[0].cpl_valid && slot_to_checker_r2[0].cpl_type) begin
                        // GET HEADER FIELDS
                        cpl_valid_wire = 1'b1; // Set completion valid wire
                        addr_wire = slot_to_checker_r2[0].cpl_data.cpl.addr; // Get address from completion header
                        status_wire = slot_to_checker_r2[0].cpl_data.cpl.status; // Get status from completion header
                        fmt_wire = slot_to_checker_r2[0].cpl_data.cpl.fmt; // Get format from completion header
                        ttype_wire = slot_to_checker_r2[0].cpl_data.cpl.ttype; // Get TTYPE from completion header  
                        tlp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.tlp_abort; // Get TLP abort from completion header
                        dllp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.dllp_abort; // Get DLLP abort from completion header
                    end
                    // GET DATA FIELDS
                    if(slot_to_checker_r2[1].cpl_valid) begin
                        data_wire[1] = slot_to_checker_r2[1].cpl_data.data[511:0]; // Get data from completion data
                        data_valid_wire[1] = 1'b1; // Set data valid if data slot is valid
                        if(slot_to_checker_r2[1].cpl_end) begin
                            data_end_wire[1] = 1'b1; // Set data end if end bit is set
                            end_error_wire = slot_to_checker_r2[1].cpl_end_error; // Get end error from completion end
                        end
                    end
                    if(slot_to_checker_r2[0].cpl_valid && !slot_to_checker_r2[0].cpl_type) begin
                        data_wire[0] = slot_to_checker_r2[0].cpl_data.data[511:0]; // Get data from completion data
                        data_valid_wire[0] = 1'b1; // Set data valid if data slot is valid
                        if(slot_to_checker_r2[0].cpl_end) begin
                            data_end_wire[0] = 1'b1; // Set data end if end bit is set
                            end_error_wire = slot_to_checker_r2[0].cpl_end_error; // Get end error from completion end
                        end
                    end
                end
            endcase
        end

        if(NUM_SLOTS == 1) begin
            // Handle case where ep_cfg_match_r is 0
            if(slot_to_checker_r2[0].cpl_valid && slot_to_checker_r2[0].cpl_type) begin
                // GET HEADER FIELDS
                cpl_valid_wire = 1'b1; // Set completion valid wire
                addr_wire = slot_to_checker_r2[0].cpl_data.cpl.addr; // Get address from completion header
                status_wire = slot_to_checker_r2[0].cpl_data.cpl.status; // Get status from completion header
                fmt_wire = slot_to_checker_r2[0].cpl_data.cpl.fmt; // Get format from completion header
                ttype_wire = slot_to_checker_r2[0].cpl_data.cpl.ttype; // Get TTYPE from completion header
                tlp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.tlp_abort; // Get TLP abort from completion header
                dllp_abort_wire = slot_to_checker_r2[0].cpl_data.cpl.dllp_abort; // Get DLLP abort from completion header
                if(slot_to_checker_r2[0].cpl_end) begin
                    end_error_wire = slot_to_checker_r2[0].cpl_end_error; // Get end error from completion end
                end
            end
            if(slot_to_checker_r2[0].cpl_valid && !slot_to_checker_r2[0].cpl_type) begin
                // GET DATA FIELDS  
                data_wire[0] = slot_to_checker_r2[0].cpl_data.data[511:0]; // Get data from completion data
                data_valid_wire[0] = 1'b1; // Set data valid if data slot is valid
                if(slot_to_checker_r2[0].cpl_end) begin
                    data_end_wire[0] = 1'b1; // Set data end if end bit is set
                    end_error_wire = slot_to_checker_r2[0].cpl_end_error; // Get end error from completion end
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpl_valid_r <= 1'b0; // Reset completion valid register
            cpl_valid_r2 <= 1'b0; // Reset completion valid register 2
            addr_reg <= '0; // Reset address register
            addr_reg2 <= '0; // Reset address register 2
            data_reg <= '0; // Reset data register
            status_reg <= '0; // Reset status register
            end_error_reg <= '0; // Reset end error register
            fmt_reg <= '0; // Reset format register
            ttype_reg <= '0; // Reset TTYPE register
            tlp_abort_reg <= '0; // Reset TLP abort register
            dllp_abort_reg <= '0; // Reset DLLP abort register
            data_valid_r <= '0; // Reset data valid register
            data_valid_r2 <= '0; // Reset data valid register 2
            data_end_reg <= '0; // Reset data end register
            data_end_reg2 <= '0; // Reset data end register 2
        end else if (link_down) begin
            cpl_valid_r <= 1'b0; // Reset on link down
            cpl_valid_r2 <= 1'b0; // Reset on link down
            addr_reg <= '0; // Reset on link down
            addr_reg2 <= '0; // Reset on link down
            data_reg <= '0; // Reset on link down
            status_reg <= '0; // Reset on link down
            end_error_reg <= '0; // Reset on link down
            fmt_reg <= '0; // Reset on link down
            ttype_reg <= '0; // Reset on link down
            tlp_abort_reg <= '0; // Reset on link down
            dllp_abort_reg <= '0; // Reset on link down
            data_valid_r <= '0; // Reset on link down
            data_valid_r2 <= '0; // Reset on link down
            data_end_reg <= '0; // Reset on link down
            data_end_reg2 <= '0; // Reset on link down
        end
        else begin
            cpl_valid_r <= cpl_valid_wire; // Update completion valid register
            cpl_valid_r2 <= cpl_valid_r; // Pipeline stage 2
            addr_reg <= addr_wire; // Update address register
            addr_reg2 <= addr_reg; // Pipeline stage 2
            data_reg <= data_wire; // Update data register
            status_reg <= status_wire; // Update status register
            end_error_reg <= end_error_wire; // Update end error register
            fmt_reg <= fmt_wire; // Update format register
            ttype_reg <= ttype_wire; // Update TTYPE register
            tlp_abort_reg <= tlp_abort_wire; // Update TLP abort register
            dllp_abort_reg <= dllp_abort_wire; // Update DLLP abort register
            data_valid_r <= data_valid_wire; // Update data valid register
            data_valid_r2 <= data_valid_r; // Pipeline stage 2
            data_end_reg <= data_end_wire; // Update data end register
            data_end_reg2 <= data_end_reg; // Pipeline stage 2
        end
    end

    always_comb begin
        fmt_mismatch = 1'b0; // Initialize format mismatch
        ttype_mismatch = 1'b0; // Initialize TTYPE mismatch
        URs = 1'b0; // Initialize URs
        CAs = 1'b0; // Initialize CAs
        cfg_retry_err = 1'b0; // Initialize configuration retry error
        tlp_or_dllp_abort_err = 1'b0; // Initialize TLP or DLLP abort error
        tlp_poisoned = 1'b0; // Initialize TLP poisoned error
        data_dw = '0; // Initialize data DW
        internal_slot_data_err = internal_slot_data_err_reg; // Initialize internal slot data error

        if(cpl_valid_r) begin
            // Check for format mismatch
            if (fmt_reg != 2'b00 && fmt_reg != 2'b10) begin
                fmt_mismatch = 1'b1; // Set format mismatch if fmt is not 00 or 10
            end
            // Check for TTYPE mismatch
            if (ttype_reg != 5'b01010) begin
                ttype_mismatch = 1'b1; // Set TTYPE mismatch if ttype is not 01010 (Completion with Data)
            end
            if (status_reg[0] == 1'b1) begin
                URs = 1'b1; // Set URs if status is xx1 (Unsupported Request)
            end
            if (status_reg[1] == 1'b1) begin
                cfg_retry_err = 1'b1; // Set configuration retry error if status is 1xx (Configuration Retry Status)
            end
            if (status_reg[2] == 1'b1) begin
                CAs = 1'b1; // Set CAs if status is x1x (Completer Abort)
            end
            if (end_error_reg[2] == 1'b1) begin
                tlp_poisoned = 1'b1; // Set TLP poisoned if end error bit 2 is set
            end
            if (tlp_abort_reg || dllp_abort_reg) begin
                tlp_or_dllp_abort_err = 1'b1; // Set TLP or DLLP abort error if either abort signal is set
            end
        end
        
        case(ep_cfg_match_r2)
            1'b0: begin
                // Configuration space
                if(NUM_SLOTS == 1) begin
                    if (data_valid_r[0]) begin
                        data_dw = data_reg[0][31:0]; // Use lower 32 bits for config space
                    end
                end else begin
                    if (data_valid_r[1]) begin
                        data_dw = data_reg[1][31:0]; // Use lower 32 bits for config space
                    end
                end
            end
            1'b1: begin
                // Memory space
                for(int i = 0; i < NUM_SLOTS; i++) begin
                    if (data_valid_r[i]) begin
                        if (data_end_reg[i]) begin
                            data_dw = data_reg[i][31:0]; // Use lower 32 bits for memory space
                            // Additional processing for end of data
                            for(int j = 1; j < ACTUAL_PAYLOAD_SIZE_DW_MOD; j++) begin
                                if(data_dw != data_reg[i][j*32 +: 32]) begin
                                    internal_slot_data_err = 1'b1; // Set data error flag
                                end
                            end
                        end else begin
                            data_dw = data_reg[i][31:0]; // Use lower 32 bits for memory space
                            // Additional processing for non-end of data
                            for(int j = 1; j < 16; j++) begin
                                if(data_dw != data_reg[i][j*32 +: 32]) begin
                                    internal_slot_data_err = 1'b1; // Set data error flag
                                end
                            end
                        end
                    end
                end
            end
            default: begin
                data_dw = '0; // Default to 0 if ep_cfg_match_r2 is invalid
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fmt_mismatch_reg <= 1'b0; // Reset format mismatch register
            ttype_mismatch_reg <= 1'b0; // Reset TTYPE mismatch register
            URs_reg <= 1'b0; // Reset URs register
            CAs_reg <= 1'b0; // Reset CAs register
            cfg_retry_err_reg <= 1'b0; // Reset configuration retry error register
            tlp_or_dllp_abort_err_reg <= 1'b0; // Reset TLP or DLLP abort error register
            tlp_poisoned_reg <= 1'b0; // Reset TLP poisoned register
            data_dw_reg <= '0; // Reset data DW register
            internal_slot_data_err_reg <= 1'b0; // Reset internal slot data error register
            slot_mismatch_reg <= 1'b0; // Reset slot mismatch register
            match_data_reg <= 1'b0; // Reset match data register
            match_data_reg2 <= 1'b0; // Reset match data register stage 2
        end else if (link_down) begin
            fmt_mismatch_reg <= 1'b0; // Reset on link down
            ttype_mismatch_reg <= 1'b0; // Reset on link down
            URs_reg <= 1'b0; // Reset on link down
            CAs_reg <= 1'b0; // Reset on link down
            cfg_retry_err_reg <= 1'b0; // Reset on link down
            tlp_or_dllp_abort_err_reg <= 1'b0; // Reset on link down
            tlp_poisoned_reg <= 1'b0; // Reset on link down
            data_dw_reg <= '0; // Reset on link down
            internal_slot_data_err_reg <= 1'b0; // Reset on link down
            slot_mismatch_reg <= 1'b0; // Reset slot mismatch register
            match_data_reg <= 1'b0; // Reset don't match data register
            match_data_reg2 <= 1'b0; // Reset don't match data register stage 2
        end else begin
            fmt_mismatch_reg <= fmt_mismatch; // Update format mismatch register
            ttype_mismatch_reg <= ttype_mismatch; // Update TTYPE mismatch register
            URs_reg <= URs; // Update URs register
            CAs_reg <= CAs; // Update CAs register
            cfg_retry_err_reg <= cfg_retry_err; // Update configuration retry error register
            tlp_or_dllp_abort_err_reg <= tlp_or_dllp_abort_err; // Update TLP or DLLP abort error register
            tlp_poisoned_reg <= tlp_poisoned; // Update TLP poisoned register
            data_dw_reg <= data_dw; // Update data DW register
            internal_slot_data_err_reg <= (|data_end_reg) ? '0 : internal_slot_data_err; // Update internal slot data error register
            slot_mismatch_reg <= (|data_end_reg) ? internal_slot_data_err : '0;
            match_data_reg <= bar_read_done;
            match_data_reg2 <= match_data_reg;
        end
    end

    always_comb begin
        addr_err = 1'b0; // Initialize address error
        internal_expected_data_err = internal_expected_data_err_reg; // Initialize internal expected data error
        expected_data_err = '0; // Initialize expected data error
        if(cpl_valid_r2) begin
            addr_err = addr_reg2 != expected_addr; // Check for address mismatch
        end

        for(int i = 0; i < NUM_SLOTS; i++) begin
            if(data_valid_r2[i]) begin
                if(data_dw_reg != expected_data) begin
                    internal_expected_data_err = 1'b1; // Set expected data error if data mismatch
                end
            end
        end
        expected_data_err = match_data_reg2 && (|data_end_reg2) && internal_expected_data_err; // Update expected data error

    end

    assign expected_data = ep_cfg_match_r2 ? mem_checker_ram_rd_data[CHECKER_DATA_WIDTH-1:0] : cfg_checker_ram_rd_data[CHECKER_DATA_WIDTH-1:0];
    assign expected_addr = ep_cfg_match_r2 ? mem_checker_ram_rd_data[CHECKER_DATA_WIDTH + CHECKER_ADDR_WIDTH-1:CHECKER_DATA_WIDTH] : '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_err_reg <= 1'b0; // Reset address error register
            expected_data_err_reg <= 1'b0; // Reset expected data error register
            internal_expected_data_err_reg <= 1'b0; // Reset internal expected data error register
            data_err_reg <= 1'b0; // Reset data error register
        end else if (link_down) begin
            addr_err_reg <= 1'b0; // Reset on link down
            expected_data_err_reg <= 1'b0; // Reset on link down
            internal_expected_data_err_reg <= 1'b0; // Reset on link down
            data_err_reg <= 1'b0; // Reset on link down
        end else begin
            addr_err_reg <= addr_err; // Update address error register
            expected_data_err_reg <= expected_data_err; // Update expected data error register
            internal_expected_data_err_reg <= (|data_end_reg2) ? '0 : internal_expected_data_err; // Update internal expected data error register
            data_err_reg <= ((IDE_EN ? (slot_mismatch_reg && match_data_reg2) : slot_mismatch_reg) || expected_data_err); // Update data error register
        end
    end



    always_comb begin
        free_tag_valid_wire = 1'b0; // Initialize free tag valid
        free_tag_wire = '0; // Initialize free tag
        count_credit = '0; // Initialize credits to return
        ep_cfg_rcvd = ep_cfg_rcvd_reg; // Initialize EP config read received count
        for (int i = 0; i < NUM_SLOTS; i++) begin
            if (slot_to_checker_r2[i].cpl_valid) begin
                // If completion header is valid, release tag
                if( slot_to_checker_r2[i].cpl_type && slot_to_checker_r2[i].cpl_data.cpl.ttype == 'ha) begin
                    free_tag_valid_wire = 1'b1; // Set free tag valid
                    free_tag_wire = tag_reg; // Use tag register as free tag
                    ep_cfg_rcvd = (ep_cfg_rcvd_reg >= ep_cfg_count) ? ep_cfg_rcvd_reg : ep_cfg_rcvd_reg + 1'b1; // Increment read count for config
                end
                count_credit = count_credit + 1'b1; // Set credit to return for this slot
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ep_cfg_rcvd_reg <= '0; // Reset EP config read received count
            free_tag_valid <= '0;
            free_tag <= '0;
        end else if (link_down) begin
            ep_cfg_rcvd_reg <= '0; // Reset on link down
            free_tag_valid <= '0;
            free_tag <= '0;
        end else begin
            ep_cfg_rcvd_reg <= ep_cfg_rcvd; // Update EP config read received count
            free_tag_valid <= free_tag_valid_wire;
            free_tag <= free_tag_wire;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            credits_to_return <= '0; // Reset credits to return
        end else if (link_down) begin
            credits_to_return <= '0; // Reset on link down
        end else begin
            credits_to_return <= count_credit; // Update credits to return
        end
    end


endmodule