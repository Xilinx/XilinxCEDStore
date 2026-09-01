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
