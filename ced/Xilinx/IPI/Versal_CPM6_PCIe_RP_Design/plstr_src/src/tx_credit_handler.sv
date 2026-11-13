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

module tx_credit_handler #(
    parameter int                           TX_CREDIT_NUM  = 64,
    parameter int                           NUM_SLOTS      = 3
) (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            link_down,
    input  logic                            tx_credit_valid,
    input  logic [2:0]                      tx_credit,
    input  logic [(NUM_SLOTS)-1:0]          tx_credit_used, // Can only consume upto 3 credits

    output logic                            tx_credit_active,
    output logic                            tx_credit_available // Signal to hold tx_o associated with packer of this credit IF
);

    // Internal credit counter (only state that needs to be stored)
    logic [$clog2(TX_CREDIT_NUM):0] credit_count;
    
    // Combinational signals for next credit count
    logic [$clog2(TX_CREDIT_NUM):0] next_credit_count;

    logic [$clog2(TX_CREDIT_NUM):0] decoded_credit;

    // Decode tx_credit into its corresponding value
    always_comb begin
        case (tx_credit)
            3'b000: decoded_credit = 0;
            3'b001: decoded_credit = 1;
            3'b010: decoded_credit = 2;
            3'b011: decoded_credit = 4;
            3'b100: decoded_credit = 8;
            3'b101: decoded_credit = 16;
            3'b110: decoded_credit = 32;
            3'b111: decoded_credit = 64;
            default: decoded_credit = 0; // Default case for safety
        endcase
    end
    
    // Calculate next credit count combinationally
    always_comb begin
        next_credit_count = credit_count + 
                       (tx_credit_valid ? decoded_credit : '0) - 
                       (|tx_credit_used ? tx_credit_used : '0);
        
        // Credit active signal
        tx_credit_available = (credit_count >= (2*NUM_SLOTS));
    end
    
    // Only store the credit count in the sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            credit_count <= '0;
            tx_credit_active <= 1'b0;
        end else if (link_down) begin
             credit_count <= '0;
            tx_credit_active <= 1'b0;
        end else begin
            credit_count <= next_credit_count;
            tx_credit_active <= 1'b1;
        end
    end
    
endmodule