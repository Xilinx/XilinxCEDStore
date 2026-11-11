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

module completor #(
    
) (
    input  logic                                                    clk,
    input  logic                                                    rst_n,
    input  logic                                                    link_down,

    input  rx_intf                                                  rx_if,

    output logic        [RX_NUM_SLOTS-1:0]                             wr_en_out,
    output rx_cpl_intf  [RX_NUM_SLOTS-1:0]                             wr_cpl_fifo,
    input  logic        [RX_NUM_SLOTS-1:0]                             fifo_full

);

    // Local parameters
    localparam RX_DATA_WIDTH = pcie_str_pkg::RX_SLOT_WIDTH;
    localparam NUM_SLOTS = pcie_str_pkg::RX_NUM_SLOTS;

    // Internal signals
    rx_single_slot_data [NUM_SLOTS-1:0]                 cpl_data_r_wire, cpl_data_r;
    logic  [NUM_SLOTS-1:0]                              cpl_start_r, cpl_start_wire; // Start bits for each slot 1: start, 0: not start
    logic  [NUM_SLOTS-1:0]                              cpl_type_r, cpl_type_wire; // Start type for each slot 1: cpl hdr 0: data/other

    logic  [MAX_NUM_SLOTS-1:0]                          rx_cpl_start; // Start pointer for each slot
    logic  [(START_TYPE_WIDTH*MAX_NUM_SLOTS)-1:0]       rx_cpl_start_type; // Start type for each slot
    logic  [(START_PTR_WIDTH*MAX_NUM_SLOTS)-1:0]        rx_cpl_start_ptr; // Start pointer for each slot

    logic  [NUM_SLOTS-1:0]                              cpl_end_r, cpl_end_wire; // End bits for each slot 1: end, 0: not end
    logic  [NUM_SLOTS-1:0][END_DPTR_WIDTH-1:0]          cpl_end_dptr_r, cpl_end_dptr_wire; // End data pointer for each slot
    logic  [NUM_SLOTS-1:0][END_ERROR_WIDTH-1:0]         cpl_end_error_r, cpl_end_error_wire; // End error for each slot

    logic  [MAX_NUM_SLOTS-1:0]                          rx_cpl_end; // End pointer for each slot
    logic  [(END_PTR_WIDTH*MAX_NUM_SLOTS)-1:0]          rx_cpl_end_ptr; // End pointer for each slot
    logic  [(END_DPTR_WIDTH*MAX_NUM_SLOTS)-1:0]         rx_cpl_end_be; // End byte enables for each slot
    logic  [END_ERROR_WIDTH-1:0]                        rx_cpl_end_err; // End error for each slot

    logic  [NUM_SLOTS-1:0]                              total_valid, total_valid_reg; // Total valid slots based on start and end bits

    logic                                               cpl_rx_valid; // Validity of the RX interface   
    logic  [NUM_SLOTS-1:0]                              cpl_valid_wire; // Validity of each slot based on start and end bits

    rx_intf                                             rx_if_r; // Registered RX interface

    rx_cpl_intf [NUM_SLOTS-1:0]                         rx_cpl_if, rx_cpl_if_r; // Output interface for each slot
    rx_cpl_intf [NUM_SLOTS-1:0]                         cpl_fifo_wire, cpl_fifo_reg;
    logic [NUM_SLOTS-1:0]                               wr_en_wire, wr_en_reg;

    logic [$clog2(NUM_SLOTS):0]                         cir_ptr_reg, cir_ptr_next;
    logic [NUM_SLOTS-1:0][$clog2(NUM_SLOTS):0]          fifo_ptr_wire, fifo_ptr_reg;
    logic [NUM_SLOTS-1:0]                               curr_valid_slots;
    logic                                               cpl_fifo_full; // FIFO full signal

    // Registering the inputs
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rx_if_r <= '{default: '0};
        end else if(link_down) begin
            // Reset logic when link is down  
            rx_if_r <= '{default: '0};
        end else begin
            // Register the inputs
            rx_if_r <= rx_if; // Register the entire interface
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(int i = 0; i < NUM_SLOTS; i++) begin
                rx_cpl_if[i].reserved <= '0; // Reset logic
                rx_cpl_if[i].cpl_data <= '0; // Reset logic
                rx_cpl_if[i].cpl_start <= '0;
                rx_cpl_if[i].cpl_end <= '0;
                rx_cpl_if[i].cpl_type <= '0;
                rx_cpl_if[i].cpl_end_dptr <= '0;
                rx_cpl_if[i].cpl_end_error <= '0;
                rx_cpl_if[i].cpl_valid <= '0; // Reset valid flag
            end
            rx_cpl_if_r <= '{default: '0};
        end 
        else if(link_down) begin
            for(int i = 0; i < NUM_SLOTS; i++) begin
                rx_cpl_if[i].reserved <= '0; // Reset logic when link is down
                rx_cpl_if[i].cpl_data <= '0; // Reset logic when link is down
                rx_cpl_if[i].cpl_start <= '0;
                rx_cpl_if[i].cpl_end <= '0;
                rx_cpl_if[i].cpl_type <= '0;
                rx_cpl_if[i].cpl_end_dptr <= '0;
                rx_cpl_if[i].cpl_end_error <= '0;
                rx_cpl_if[i].cpl_valid <= '0; // Reset valid flag
            end
            rx_cpl_if_r <= '{default: '0};
        end
        else begin
            for(int i = 0; i < NUM_SLOTS; i++) begin
                rx_cpl_if[i].reserved <= '0; // Reserved bits
                rx_cpl_if[i].cpl_data <= cpl_data_r[i]; 
                rx_cpl_if[i].cpl_start <= cpl_start_r[i];
                rx_cpl_if[i].cpl_end <= cpl_end_r[i];
                rx_cpl_if[i].cpl_type <= cpl_type_r[i];
                rx_cpl_if[i].cpl_end_dptr <= cpl_end_dptr_r[i];
                rx_cpl_if[i].cpl_end_error <= cpl_end_error_r[i];
                rx_cpl_if[i].cpl_valid <= cpl_valid_wire[i]; 
            end
            rx_cpl_if_r <= rx_cpl_if; // Register the output interface
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
      
        if (!rst_n) begin
            cpl_rx_valid <= '0; // Reset logic
            for(int i = 0; i < NUM_SLOTS; i++) begin
            cpl_data_r[i]     <= '0; // Reset logic
            cpl_start_r[i]     <= '0;
            cpl_end_r[i]       <= '0;
            cpl_type_r[i]      <= '0;
            cpl_end_dptr_r[i]  <= '0;
            cpl_end_error_r[i] <= '0;
            end
        end 
        else if (link_down) begin
            cpl_rx_valid <= '0; // Reset logic when link is down
            for(int i = 0; i < NUM_SLOTS; i++) begin
            cpl_data_r[i]     <= '0; // Reset logic when link is down
            cpl_start_r[i]     <= '0;
            cpl_end_r[i]       <= '0;
            cpl_type_r[i]      <= '0;
            cpl_end_dptr_r[i]  <= '0;
            cpl_end_error_r[i] <= '0;
            end
        end
        else begin
            cpl_rx_valid <= rx_if_r.rx_valid; // Register the rx_valid signal
            for(int i = 0; i < NUM_SLOTS; i++) begin
                cpl_data_r[i]      <= cpl_data_r_wire[i];
                cpl_start_r[i]     <= cpl_start_wire[i];
                cpl_end_r[i]       <= cpl_end_wire[i];
                cpl_type_r[i]      <= cpl_type_wire[i];
                cpl_end_dptr_r[i]  <= cpl_end_dptr_wire[i];
                cpl_end_error_r[i] <= cpl_end_error_wire[i];
            end
        end
    end

    always_comb begin
        cpl_data_r_wire = '0;
        for(int i = 0; i < NUM_SLOTS; i++) begin
            if(cpl_start_wire[i] == 1'b1) begin
                cpl_data_r_wire[i].cpl = rx_if_r.rx_data[i];
            end
            else begin 
                cpl_data_r_wire[i].data = rx_if_r.rx_data[i];
            end
        end
    end

    // START AND END LOGIC

    // Assigning start bits and type based on rx_start signals
    always_comb begin
        cpl_start_wire = '0;  // Default all starts to 0
        cpl_type_wire = '0; // Default all start types to 0

        rx_cpl_start = rx_if_r.rx_start; // Default all start pointers
        rx_cpl_start_type = rx_if_r.rx_starttype; // Combine start types for easier access
        rx_cpl_start_ptr = rx_if_r.rx_startptr; // Combine start pointers for easier access

        if(rx_if_r.rx_valid) begin
            for(int i=0; i<NUM_SLOTS; i++) begin
                if(rx_cpl_start && (rx_cpl_start_ptr[1:0] == i)) begin
                    cpl_start_wire[i] = 1'b1;
                    cpl_type_wire[i] = 1'b1; // Since this is a completion start, type is hdr - 1'b1; data/other - 1'b0
                    
                    rx_cpl_start = rx_cpl_start >> 1; // Shift the start bits to check next pointer
                    rx_cpl_start_ptr = rx_cpl_start_ptr >> START_PTR_WIDTH; // Shift the start pointers to check next pointer
                    rx_cpl_start_type = rx_cpl_start_type >> START_TYPE_WIDTH; // Shift the start types to check next pointer
                end
            end
        end
    end

    always_comb begin
        cpl_end_wire = '0; // Default all ends to 0
        cpl_end_dptr_wire = '0; // Default all end data pointers to
        cpl_end_error_wire = '0; // Default all end errors to 0

        rx_cpl_end = rx_if_r.rx_end; // Default all end pointers
        rx_cpl_end_ptr = {rx_if_r.rx_endptr[2].ptr, rx_if_r.rx_endptr[1].ptr, rx_if_r.rx_endptr[0].ptr}; // Combine end pointers for easier access
        rx_cpl_end_be = {rx_if_r.rx_endptr[2].dptr, rx_if_r.rx_endptr[1].dptr, rx_if_r.rx_endptr[0].dptr}; // Combine end byte enables for easier access
        rx_cpl_end_err = rx_if_r.rx_end_error; // Default all end errors

        if(rx_if_r.rx_valid) begin
            for(int i=0; i<NUM_SLOTS; i++) begin
                if(rx_cpl_end && (rx_cpl_end_ptr[1:0] == i)) begin
                    cpl_end_wire[i] = 1'b1;
                    cpl_end_dptr_wire[i] = rx_cpl_end_be[3:0]; // Assign the data pointer from the end pointer
                    cpl_end_error_wire[i] = rx_cpl_end_err[2:0]; // Assign the error bits from the end error 

                    rx_cpl_end = rx_cpl_end >> 1; // Shift the end bits to check next pointer
                    rx_cpl_end_ptr = rx_cpl_end_ptr >> END_PTR_WIDTH; // Shift the end pointers to check next pointer
                    rx_cpl_end_be = rx_cpl_end_be >> END_DPTR_WIDTH; // Shift the end byte enables to check next pointer
                    rx_cpl_end_err = rx_cpl_end_err >> 3; // Shift the end errors to check next pointer
                end
            end
        end
    end

    always_comb begin
        total_valid = total_valid_reg; // Initialize total valid slots
        cpl_valid_wire = '0; // Default all slots to invalid
        if(cpl_rx_valid)
        begin
            for(int i = 0; i < NUM_SLOTS; i++) begin
                total_valid = total_valid + cpl_start_r[i] - cpl_end_r[i];
                if(total_valid == '0 && !cpl_end_r[i]) begin
                    cpl_valid_wire[i] = 1'b0; // If total valid is 0 and this slot is not an end, mark it as invalid
                end else begin
                    cpl_valid_wire[i] = 1'b1; // If total valid is greater than 0, mark it as valid
                end
            end
        end  
    end
      // Calculate total valid slots based on start and end bits

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_valid_reg <= '0; // Reset total valid slots
        end else if (link_down) begin
            total_valid_reg <= '0; // Reset total valid slots when link is down
        end else begin
            total_valid_reg <= total_valid; // Update total valid slots
        end
    end

    always_comb begin
        fifo_ptr_wire = '0; // Default fifo pointer to 0
        curr_valid_slots = '0; // Default current valid slots to 0
        for(logic [$clog2(NUM_SLOTS):0] i = 0; i < NUM_SLOTS; i++) begin
            if(rx_cpl_if[i].cpl_valid) begin
                curr_valid_slots = curr_valid_slots + 1; // Count the number of valid slots
                fifo_ptr_wire[i] = (cir_ptr_reg + i)%NUM_SLOTS; // Assign fifo pointer in a circular manner
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_ptr_reg <= '0; // Reset fifo pointer
        end else if (link_down) begin
            fifo_ptr_reg <= '0; // Reset fifo pointer when link is down
        end else begin
            fifo_ptr_reg <= fifo_ptr_wire;
        end
    end

    always_comb begin
        cir_ptr_next = (cir_ptr_reg + curr_valid_slots)%NUM_SLOTS; // Update the circular pointer based on the number of valid slots
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cir_ptr_reg <= '0; // Reset circular pointer
        end else if (link_down) begin
            cir_ptr_reg <= '0; // Reset circular pointer when link is down
        end else begin
            cir_ptr_reg <= cir_ptr_next; // Update circular pointer
        end
    end

    always_comb begin
        cpl_fifo_wire = '0; // Default fifo to 0
        wr_en_wire = '0; // Default write enable to 0
        for(logic [2:0] i = 0; i < NUM_SLOTS; i++) begin
            if(rx_cpl_if_r[i].cpl_valid) begin
                cpl_fifo_wire[fifo_ptr_reg[i]] = rx_cpl_if_r[i]; // Write valid slots to fifo based on fifo pointer
                wr_en_wire[fifo_ptr_reg[i]] = 1'b1; // Enable write if there is at least one valid slot
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_reg <= '0;
            cpl_fifo_reg <= '0; // Reset fifo
        end else if (link_down) begin
            wr_en_reg <= '0;
            cpl_fifo_reg <= '0; // Reset fifo when link is down
        end else begin
            cpl_fifo_reg <= cpl_fifo_wire; // Update fifo
            wr_en_reg <= wr_en_wire;
            if(cpl_fifo_full) begin
                if(|wr_en_wire) begin
                end
            end
        end
    end

    assign cpl_fifo_full = &fifo_full; // FIFO is full if all fifo_full signals are high

    assign wr_cpl_fifo = cpl_fifo_reg;
    assign wr_en_out = wr_en_reg;
    
endmodule