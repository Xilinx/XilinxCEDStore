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
//-- Filename: BMD_AXIST_RX_CREDITS.sv
//--
//-- Description: Controls the credits between the core and the RX switch and the
//--              RX switch and user logic designs (RX MUX, MSI-X, etc.)
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RX_CREDITS
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
#(
    parameter int                       NUM_CONSUMERS = 1,
    parameter int                       RX_CREDIT_CNT = 48
) (
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        link_down_reset,

    input  logic [NUM_SLOTS - 1 :0][NUM_CONSUMERS-1:0]    fifo_rd_en,
    input  logic [NUM_SLOTS - 1 :0][NUM_CONSUMERS-1:0]    fifo_empty,

    input  logic                        cr_active,
    output logic                        cr_valid,
    output logic [2:0]                  cr,

    output logic [15:0]                 debug
);
    logic [2:0] first_crd, second_crd;

    logic [7:0][6:0] credit_encoding;
    assign      credit_encoding = {7'd64, 7'd32, 7'd16, 7'd8, 7'd4, 7'd2, 7'd1, 7'd0};

    always_comb begin
        first_crd = '0;
        second_crd = '0;
        for (int i = 0; i < 8; i++) begin
            if (RX_CREDIT_CNT < credit_encoding[i])
                if (i != 0) begin
                    first_crd = i-1;
                    break;
                end
        end
        for (int i = 0; i < 8; i++) begin
            if ((RX_CREDIT_CNT - credit_encoding[first_crd]) < credit_encoding[i]) begin
                if (i != 0) begin
                    second_crd = i-1;
                    break;
                end
            end
        end
    end

    logic [$clog2(NUM_SLOTS)-1:0]   used_credits;
    logic [$clog2(NUM_SLOTS)-1:0]   remaining_credits;
    logic [$clog2(NUM_SLOTS)-1:0]   remaining_credits_reg;
    logic [$clog2(NUM_SLOTS):0]     total_credits;

    logic                   link_down_reset_reg, link_down_reset_reg2;
    logic                   rx_credit_active_reg, rx_credit_active_reg2;

    assign total_credits = {1'b0, used_credits} + {1'b0, remaining_credits_reg};

    // If not 1 and odd we will have leftover credits
    assign remaining_credits = (total_credits != 'd1) ? {'0, total_credits[0]} : '0;

    assign debug = {
        4'h0,
        total_credits,
        used_credits,
        remaining_credits,
        cr,
        cr_valid,
        cr_active
    };

    always_comb begin
        used_credits = '0;
        for (int j = 0; j < NUM_CONSUMERS; j++) begin
            for (int i = 0; i < NUM_SLOTS; i++) begin
                used_credits += ~fifo_empty[i][j] & fifo_rd_en[i][j];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            link_down_reset_reg <= 1'b1;
            link_down_reset_reg2 <= 1'b1;
            rx_credit_active_reg <= 1'b0;
            rx_credit_active_reg2 <= 1'b0;
        end else begin
            link_down_reset_reg <= link_down_reset;
            link_down_reset_reg2 <= link_down_reset_reg;
            rx_credit_active_reg <= cr_active;
            rx_credit_active_reg2 <= rx_credit_active_reg;
        end

        //////////////////////////////////////////////////////////////////////////////////////////

        if (~rst_n) begin
            remaining_credits_reg <= '0;
        end else begin
            if (link_down_reset) begin
                remaining_credits_reg <= remaining_credits;
            end
        end

        ///////////////////////////////////////////////////////////////////////////////////////////

        if (~rst_n) begin
            cr_valid <= 1'b0;
            cr <= 3'b000;
        end else if ((~link_down_reset & link_down_reset_reg & cr_active) |
        (~link_down_reset & rx_credit_active_reg != 1'b1 & cr_active)) begin // Init pulse 1
            cr_valid <= 1'b1;
            cr <= first_crd;
            // cr_active <= 1'b1;
        end else if ((~link_down_reset_reg & link_down_reset_reg2 & cr_active) |
        (~link_down_reset & rx_credit_active_reg2 != 1'b1 & rx_credit_active_reg)) begin // Init pulse 2
            cr_valid <= 1'b1;
            cr <= second_crd;
            // cr_active <= 1'b1;
        end else begin
            // cr_active <= 1'b1;
            cr_valid <= (total_credits != 0) ? 1'b1 : 1'b0;
            cr <= (total_credits >> 1) + 1;
        end
    end


endmodule // BMD_AXIST_RX_CREDITS
