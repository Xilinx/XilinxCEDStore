
//-----------------------------------------------------------------------------
//
// (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Versal PCI Express Integrated Block
// File       : BMD_AXIST_RX_CREDITS.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

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
