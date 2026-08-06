
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
// File       : BMED_BACKPRESSURE_ARB.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMED_BACKPRESSURE_ARB.sv
//--
//-- Description: Provides backpressure to previous arbitration modules
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_BACKPRESSURE_ARB
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
#(
    parameter int unsigned ARB_DELTA = 2, // This is absolute number of buffer spaces of delay in true depth
    parameter int unsigned ARB_DEPTH = 3, // True depth will be ARB_SLOTS * ARB_DEPTH
    parameter int unsigned ARB_SLOTS = NUM_SLOTS,
    parameter int unsigned ARB_WIDTH = ENCODING_WIDTH_TX
)(
    input  logic                                    clk,
    input  logic                                    rst_n,

    output logic [ARB_SLOTS-1:0][ARB_WIDTH-1:0]     dout_o,
    output logic [ARB_SLOTS-1:0]                    valid_o,
    input  logic [ARB_SLOTS-1:0]                    rd_en_i,

    input  logic [ARB_SLOTS-1:0]                    valid_i,
    input  logic [ARB_SLOTS-1:0][ARB_WIDTH-1:0]     slots_i,

    output logic                                    halt_o
);

logic                                               next_halt;

// Used for ord en count from previous cycle
logic [$clog2(ARB_SLOTS):0]                         ord_en_r, next_ord_en;
logic [$clog2(ARB_SLOTS*ARB_DEPTH):0]               ord_up_r, next_ord_up;
logic [$clog2(ARB_SLOTS):0]                         rd_sum_r, next_rd_sum;
// Used for internal buffering
logic [(ARB_SLOTS*ARB_DEPTH)-1:0]                   rd_valid_int, next_rd_valid_int;
logic [(ARB_SLOTS*ARB_DEPTH)-1:0][ARB_WIDTH-1:0]    rd_data_int, next_rd_data_int;

// Data output
//////////////////////////////////////////////////////
always_comb begin
    valid_o = '0;
    dout_o = '0;
    for (int unsigned i = 0; i < ARB_SLOTS; i++) begin
        dout_o[i] = rd_data_int[i + ord_en_r];
        valid_o[i] = rd_valid_int[i + ord_en_r];
    end
end

// Internal Data Handling
//////////////////////////////////////////////////////
always @(posedge clk) begin
    if (!rst_n) begin
        rd_data_int <= '0;
        rd_valid_int <= '0;
        halt_o <= 1'b0;
    end else begin
        halt_o <= next_halt;
        rd_data_int <= next_rd_data_int;
        rd_valid_int <= next_rd_valid_int;
    end
end

always_comb begin
    next_rd_data_int = '0;
    next_rd_valid_int = '0;
    next_halt = 1'b0;

    if ((next_ord_up - next_ord_en) > ((ARB_SLOTS * ARB_DEPTH) - ARB_DELTA)) next_halt = 1'b1;

    for (int unsigned i = 0; i < (ARB_SLOTS*ARB_DEPTH); i++) begin
        if (i < (ord_up_r - ord_en_r)) begin
            next_rd_data_int[i] = rd_data_int[i + ord_en_r];
            next_rd_valid_int[i] = rd_valid_int[i + ord_en_r];
        end else begin
            for (int unsigned k = 0; (k + i) < (ARB_SLOTS*ARB_DEPTH) && k < ARB_SLOTS; k++) begin
                next_rd_data_int[i + k] = slots_i[k];
                next_rd_valid_int[i + k] = valid_i[k];
            end
            break;
        end
    end
end

// Enable counter
//////////////////////////////////////////////////////
always @(posedge clk) begin
    if (!rst_n) begin
        ord_en_r <= '0;
        ord_up_r <= '0;
        rd_sum_r <= '0;
    end else begin
        ord_en_r <= next_ord_en;
        ord_up_r <= next_ord_up;
        rd_sum_r <= next_rd_sum;
    end
end

always_comb begin
    next_rd_sum = '0;
    next_ord_en = $countones(rd_en_i);

    for (int unsigned i = 0; i < ARB_SLOTS; i++) begin
        next_rd_sum = next_rd_sum + valid_i[i];
    end
    next_ord_up = ord_up_r - ord_en_r + next_rd_sum;
end

endmodule
