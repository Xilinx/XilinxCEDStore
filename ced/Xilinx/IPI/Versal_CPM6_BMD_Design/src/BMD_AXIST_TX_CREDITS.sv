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

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TX_CREDITS.sv
//--
//-- Description: Controls the credits between the core and the TX switch and the
//--              TX switch and user logic designs (TX MUX, MSI-X, etc.)
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TX_CREDITS
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
#(
    parameter int                           MAX_TX_CREDITS  = 48
) (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            link_down_reset,

    output logic                            cr_active,
    input  logic                            cr_valid,
    input  logic [2:0]                      cr,

    input  logic                            tx_slot_consumed,
    input  logic [$clog2(NUM_SLOTS)-1:0]    tx_credits_consumed, // Can only consume upto 3 credits
    output logic                            tx_credits_available, // Signal to hold tx_o associated with packer of this credit IF
    output logic                            tx_slot_available,

    output logic [15:0]                     debug
);
    logic                            tx_slot_consumed_r;
    logic [$clog2(NUM_SLOTS)-1:0]    tx_credits_consumed_r;
    logic                            tx_credits_available_r;

    logic [$clog2(MAX_TX_CREDITS) : 0] tx_credit_count;
    logic [$clog2(MAX_TX_CREDITS) : 0] tx_credit_count_wire;

    logic [7:0][6:0] credit_encoding;
    assign      credit_encoding = {7'd64, 7'd32, 7'd16, 7'd8, 7'd4, 7'd2, 7'd1, 7'd0};

    assign tx_credits_available = (tx_credit_count >= 6); // Assume we send 3 slots
                                                          // we outpace how fast credits can be returned so shouldn't matter

    assign tx_slot_available = tx_credit_count >= 4;

    assign debug = {
        8'h00,
        tx_credits_available,
        tx_credits_consumed,
        cr,
        cr_valid,
        cr_active
    };

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tx_credit_count <= 0;
            cr_active <= 0;
        end else begin
            if (link_down_reset) begin
                tx_credit_count <= tx_credit_count_wire;
                cr_active <= 1;
            end else begin
                tx_credit_count <= '0;
                cr_active <= '0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            tx_credits_available_r  <= '0;
            tx_credits_consumed_r   <= '0;
            tx_slot_consumed_r      <= '0;
        end else begin
            tx_credits_available_r  <= tx_credits_available;
            tx_credits_consumed_r   <= tx_credits_consumed;
            tx_slot_consumed_r      <= tx_slot_consumed;
        end
    end

    always_comb begin
        tx_credit_count_wire = tx_credit_count +
                            (cr_valid ? credit_encoding[cr] : 0) -
                            (tx_credits_available_r ? tx_credits_consumed_r : 0) -
                            tx_slot_consumed_r;
    end

endmodule // BMD_AXIST_TX_CREDITS
