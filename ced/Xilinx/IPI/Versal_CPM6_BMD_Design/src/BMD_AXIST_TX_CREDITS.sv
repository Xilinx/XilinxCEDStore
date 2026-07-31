
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
// File       : BMD_AXIST_TX_CREDITS.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

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
