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

module address_buffer #(
    parameter ADDR_WIDTH = 64,  // Width of the address
    parameter ADDR_BUF_DEPTH = 64       // Depth of the buffer
) (
    input  logic                                 clk,
    input  logic                                 rst_n,
    input  logic                                 write_enable,         // Enable writing to the buffer
    input  logic [ADDR_WIDTH-1:0]                  write_addr_0,         // Address 0 to write
    input  logic                                 read_enable,          // Enable reading from the buffer
    input  logic [1:0]                           read_count,           // Number of addresses to read (0-2)
    output logic [ADDR_WIDTH-1:0]                  read_addr_0,          // Address 0 read
    output logic                                 buffer_empty,         // Indicates if the buffer is empty
    output logic                                 buffer_full,          // Indicates if the buffer is full
    output logic                                 buffer_almost_full,   // Indicates if the buffer is almost full
    output logic [$clog2(ADDR_BUF_DEPTH)-1:0]    available_slots       // Number of available slots
);

    // Internal buffer storage
    logic [ADDR_WIDTH-1:0]                 buffer [ADDR_BUF_DEPTH-1:0];
    logic [$clog2(ADDR_BUF_DEPTH)-1:0]   write_ptr;                    // Write pointer
    logic [$clog2(ADDR_BUF_DEPTH)-1:0]   read_ptr;                     // Read pointer
    logic                                write_wrap;                   // Write pointer wrap signal
    logic                                read_wrap;                    // Read pointer wrap signal

    // Calculate available slots
    always_comb begin
        if (write_wrap == read_wrap) begin
            available_slots = ADDR_BUF_DEPTH - (write_ptr - read_ptr);
        end else begin
            available_slots = read_ptr - write_ptr;
        end
    end

    // Write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= '0;
            write_wrap <= '0;
            for (logic [$clog2(ADDR_BUF_DEPTH):0] i = 0; i < ADDR_BUF_DEPTH; i++) begin
                buffer[i] <= '0; // Initialize buffer to zero
            end
        end else if (write_enable) begin
            buffer[write_ptr] <= write_addr_0; // Write address 0
            write_ptr <= (write_ptr + 1) % ADDR_BUF_DEPTH;
            if (write_ptr == ADDR_BUF_DEPTH - 1) write_wrap <= ~write_wrap; // Toggle wrap
        end
    end

    // Read logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_ptr <= '0;
            read_wrap <= '0;
            read_addr_0 <= '0;
        end else if (read_enable && !buffer_empty) begin
            read_addr_0 <= buffer[read_ptr]; // Read address 0
            read_ptr <= (read_ptr + 1) % ADDR_BUF_DEPTH;
            if (read_ptr == ADDR_BUF_DEPTH - 1) read_wrap <= ~read_wrap; // Toggle wrap
        end
    end

    // Buffer status logic
    assign buffer_empty = (read_ptr == write_ptr) && (read_wrap == write_wrap);
    assign buffer_full = (read_ptr == write_ptr && (read_wrap != write_wrap));
    assign buffer_almost_full = (6'(read_ptr) == 6'(write_ptr+1));

endmodule