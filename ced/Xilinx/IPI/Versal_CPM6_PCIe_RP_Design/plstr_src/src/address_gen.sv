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

module address_gen #(
    parameter ADDR_WIDTH                = 64,   // Width of the address
    parameter DATA_WIDTH                = 32,   // Width of the data bus
    parameter ADDR_BUF_DEPTH            = 64,   // Depth of the address buffer
    parameter NUM_BAR                   = 6,    // Number of Base Address Registers (BARs)
    parameter MAX_PAYLOAD_SIZE_BYTE     = 128,  // Payload size
    parameter DW_SIZE                   = 32,   // Data width size
    parameter TRAFFIC_COUNT             = 32,   // Number of traffic transactions to generate
    parameter ACTUAL_PAYLOAD_SIZE_BYTE  = 128   // Actual payload size to use in the traffic generation
)(
    input  logic                                       clk,
    input  logic                                       rst_n,
    input  logic                                       link_down,      // Link down signal
    input  logic                                       halt,           // Halt signal
    input  logic                                       traffic_write,  // Traffic write enable signal  
    input  logic [$clog2(TRAFFIC_COUNT):0]             traffic_count,  // Traffic count input
    output logic [ADDR_WIDTH-1:0]                      read_addr_0,    // Read address 0
    input  logic                                       read_enable,    // Enable reading from the address buffer
    input  logic [1:0]                                 read_count,     // Number of addresses to read (0-2)

    output logic                                       buffer_empty,   // Indicates if the address buffer is empty
    output logic                                       buffer_full,    // Indicates if the address buffer is full

    input  logic                                       is_all_64bit_bar,
    input  logic [NUM_BAR-1:0]                         is_64bit_bar,   // Indicates if each BAR is 64-bit
    input  logic [NUM_BAR-1:0][DATA_WIDTH-1:0]         bar_bases,      // Base addresses for each BAR
    input  logic [NUM_BAR-1:0][DATA_WIDTH-1:0]         bar_sizes,      // Size of each BAR
    output logic [$clog2(TRAFFIC_COUNT)+1:0]           traffic_count_reg,

    input logic                                        bar_processing_done // Signal indicating BAR processing is done
);
    localparam                              DW_SIZE_IN_BYTES = DW_SIZE>>3;
    localparam                              NUM_BAR_WIDTH = $clog2(NUM_BAR);
    localparam                              NEXT_OFFSET_ADDITION = ACTUAL_PAYLOAD_SIZE_BYTE;
    localparam                              TWICE_ACTUAL_PAYLOAD_SIZE_BYTE = (ACTUAL_PAYLOAD_SIZE_BYTE << 1);

    logic [ADDR_WIDTH-1:0]                  write_addr_0;           // Address 0 to write
    logic                                   write_enable;           // Enable writing to the address buffer
    logic [$clog2(ADDR_BUF_DEPTH)-1:0]      available_slots;        // Number of available slots in the address buffer
    logic [$clog2(NUM_BAR)-1:0]             bar_num;                // Current BAR number being accessed
    logic [15:0]                            offset;                 // Offset for address generation
    logic                                   addr_gen_skip;          // Address generation skip signal
    logic                                   buffer_almost_full;
    logic                                   write_halt;
    logic [ADDR_WIDTH-1:0]                  current_bar_size;
    logic [$clog2(NUM_BAR)-1:0]             next_bar_num_comb;
    logic                                   next_bar_check;

    logic [ADDR_WIDTH:0]                    write_addr_0_lower;
    logic [ADDR_WIDTH-1:0]                  write_addr_0_upper;
    logic                                   carry_low;
    logic                                   next_write_enable;

    // State machine states
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        BAR_SIZE_LIMIT32 = 2'b01,
        BAR_SIZE_LIMIT64 = 2'b10,
        DONE = 2'b11
    } state_t;
    state_t                                current_state, next_state;
    logic [$clog2(NUM_BAR):0]              st_bar_num, st_bar_num_wire;
    logic [NUM_BAR-1:0][DATA_WIDTH-1:0]    bar_size_limit, bar_size_limit_reg;

    
    address_buffer #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .ADDR_BUF_DEPTH(ADDR_BUF_DEPTH)
    ) addr_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .write_enable(write_enable),
        .write_addr_0(write_addr_0),
        .read_enable(read_enable), 
        .read_count(read_count),
        .read_addr_0(read_addr_0),
        .buffer_empty(buffer_empty),
        .buffer_full(buffer_full),
        .buffer_almost_full(buffer_almost_full),
        .available_slots(available_slots)
    );

    always_comb begin
        if (is_all_64bit_bar) begin
            addr_gen_skip = (bar_sizes[bar_num] == '0) && (bar_sizes[bar_num+1] == '0) ? 1'b1 : 1'b0;
        end else begin
            addr_gen_skip = (bar_sizes[bar_num] == '0) ? 1'b1 : 1'b0;
        end
    end
    
    assign write_halt = buffer_full || buffer_almost_full;
    assign next_bar_num_comb = (bar_num + (is_all_64bit_bar ? 'h2 : 'h1)) % NUM_BAR;

    always_comb begin
        st_bar_num_wire = st_bar_num;
        next_state = current_state;
        foreach (bar_size_limit_reg[i]) begin
            bar_size_limit[i] = bar_size_limit_reg[i];
        end
        case(current_state)
            IDLE: begin
                bar_size_limit = 'b0;
                if(bar_processing_done)
                    next_state = is_all_64bit_bar ? BAR_SIZE_LIMIT64 : BAR_SIZE_LIMIT32;
                else
                    next_state = IDLE;
            end
            BAR_SIZE_LIMIT64: begin
                bar_size_limit[st_bar_num] = |bar_sizes[st_bar_num+1] || (|bar_sizes[st_bar_num][31:15]) ? 'h8000 :  bar_sizes[st_bar_num];
                next_state = st_bar_num >= 4 ? DONE : BAR_SIZE_LIMIT64;
                st_bar_num_wire = st_bar_num + 2;
            end
            BAR_SIZE_LIMIT32: begin
                bar_size_limit[st_bar_num] = (|bar_sizes[st_bar_num][31:15]) ? 'h8000 :  bar_sizes[st_bar_num];
                next_state = st_bar_num >= 5 ? DONE : BAR_SIZE_LIMIT32;
                st_bar_num_wire = st_bar_num + 1;
            end
            DONE: begin
                next_state = DONE;
            end
            default: begin
                next_state = IDLE;
                st_bar_num_wire = '0;
                bar_size_limit = 'b0;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            st_bar_num <= '0;
            foreach (bar_size_limit_reg[i]) begin
                bar_size_limit_reg[i] <= 'b0;
            end
        end else if (link_down) begin
            current_state <= IDLE;
            st_bar_num <= '0;
            foreach (bar_size_limit_reg[i]) begin
                bar_size_limit_reg[i] <= 'b0;
            end
        end else begin
            current_state <= next_state;
            st_bar_num <= st_bar_num_wire;
            foreach (bar_size_limit_reg[i]) begin
                bar_size_limit_reg[i] <= bar_size_limit[i];
            end
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bar_num <= '0; // Start with BAR 0
            offset <= '0;  // Initialize offset
            traffic_count_reg <= '0; // Initialize traffic count
            write_enable <= '0;
            write_addr_0 <= '0; // Initialize write address 0
            current_bar_size <= '0;
            next_bar_check <= 1'b0;
            next_write_enable <= 1'b0;
            write_addr_0_lower <= '0;
            write_addr_0_upper <= '0;
            carry_low <= 1'b0;
        end 
        else if (link_down) begin
            bar_num <= '0; // Reset BAR number on link down
            offset <= '0;  // Reset offset on link down
            traffic_count_reg <= '0; // Reset traffic count on link down
            write_enable <= '0;
            write_addr_0 <= '0; // Reset write address 0 on link down
            current_bar_size <= '0;
            next_bar_check <= 1'b0;
            next_write_enable <= 1'b0;
            write_addr_0_lower <= '0;
            write_addr_0_upper <= '0;
            carry_low <= 1'b0;
        end 
        else if (traffic_write) begin
            if (traffic_count_reg > '0 && !write_halt) begin
                next_write_enable <= addr_gen_skip ? 1'b0 : 1'b1;
                    write_enable <= next_write_enable;
                    // Generate one address and write it to the buffer
                    if(is_all_64bit_bar) begin
                        // For 64-bit BARs
                        write_addr_0_lower <= bar_bases[bar_num] + offset;
                        carry_low <= write_addr_0_lower[32];
                        write_addr_0_upper <= bar_bases[bar_num+1];
                        write_addr_0 <= {(write_addr_0_upper + carry_low), write_addr_0_lower[31:0]};
                    end
                    else begin
                        // For 32-bit BARs
                        write_addr_0_lower <= bar_bases[bar_num] + offset;
                        write_addr_0 <= {32'b0, 32'(write_addr_0_lower)};
                    end

                    if (next_bar_check) begin
                        offset <= '0;
                        bar_num <= next_bar_num_comb; // Wrap around BAR number
                        current_bar_size <= bar_size_limit_reg[next_bar_num_comb];
                        next_bar_check <= TWICE_ACTUAL_PAYLOAD_SIZE_BYTE >= bar_size_limit_reg[next_bar_num_comb];
                    end else begin
                        offset <= offset + NEXT_OFFSET_ADDITION; 
                        next_bar_check <= (offset + TWICE_ACTUAL_PAYLOAD_SIZE_BYTE) >= current_bar_size;
                    end

                    // Decrement traffic count
                    traffic_count_reg <= !addr_gen_skip ? traffic_count_reg - 1 : traffic_count_reg;
            end 
            else begin
                write_enable <= '0; // Disable writing
            end
        end 
        else begin
            write_enable <= '0; // Disable writing when not in traffic generation state
            next_write_enable <= 1'b0;
            traffic_count_reg <= traffic_count + 1;
            write_addr_0 <= '0; // Reset write address 0 when not in traffic generation state
            current_bar_size <= bar_size_limit_reg[0];
        end
    end

endmodule