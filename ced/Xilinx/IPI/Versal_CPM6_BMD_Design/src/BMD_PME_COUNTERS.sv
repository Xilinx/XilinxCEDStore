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
//-- Filename: BMD_PME_COUNTERS.sv
//--
//-- Description: Track PH, NPH, CH, and Data counts
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_PME_COUNTERS
  import pcie_str_pkg::*;
  import pcie_intf_pkg::*;
#(
    parameter int                       LATENCY = 2,
    parameter logic                     IS_TX = 1'b1
)(
    input  logic                        clk,
    input  logic                        rst_n,

    input  rx_fifo_intf [NUM_SLOTS-1:0] rx_slots,
    input  tx_fifo_intf [NUM_SLOTS-1:0] tx_slots,
    input  logic [NUM_SLOTS-1:0]        valid,

    output logic [63:0]                 posted_header_count,
    output logic [63:0]                 nonposted_header_count,
    output logic [63:0]                 completion_header_count,
    output logic [63:0]                 data_count,

    output logic [31:0]                 debug
);

logic [NUM_SLOTS-1:0][1:0]  slots_ptype;
logic [NUM_SLOTS-1:0][3:0]  slots_pd_ptr;

always_comb begin
    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (IS_TX) begin
            slots_ptype[i]   = tx_slots[i].ptype;
            slots_pd_ptr[i]  = tx_slots[i].pd_ptr;
        end else begin
            slots_ptype[i]   = rx_slots[i].ptype;
            slots_pd_ptr[i]  = rx_slots[i].pd_ptr;
        end
    end
end

logic [64:0]    next_posted_header_count;
logic [64:0]    next_nonposted_header_count;
logic [64:0]    next_completion_header_count;
logic [64:0]    next_data_count;

logic           posted_valid;
logic           nonposted_valid;
logic           completion_valid;
logic           data_valid;

////////////////////////////////////////////////

logic [7:0]     posted_acum;
logic [7:0]     nonposted_acum;
logic [7:0]     completion_acum;
logic [7:0]     data_acum;

logic [7:0]     next_posted_acum;
logic [7:0]     next_nonposted_acum;
logic [7:0]     next_completion_acum;
logic [7:0]     next_data_acum;

logic           add_valid;

//////////////////////////////////////////////
// Posted Header Adder
//////////////////////////////////////////////
BMD_ADDER #(
    .WIDTH_A        ( 64 ),
    .WIDTH_B        ( 8 ),
    .LATENCY        ( LATENCY )
) PH_ADDER (
    .clk            ( clk ),
    .rst_n          ( rst_n ),

    .a_in           ( posted_header_count ),
    .b_in           ( posted_acum ),
    .valid_in       ( add_valid ),

    .sum_out        ( next_posted_header_count ),
    .valid_out      ( posted_valid ),

    .halt_i         ( 1'b0 )
);

//////////////////////////////////////////////
// Nonposted Header Adder
//////////////////////////////////////////////
BMD_ADDER #(
    .WIDTH_A        ( 64 ),
    .WIDTH_B        ( 8 ),
    .LATENCY        ( LATENCY )
) NPH_ADDER (
    .clk            ( clk ),
    .rst_n          ( rst_n ),

    .a_in           ( nonposted_header_count ),
    .b_in           ( nonposted_acum ),
    .valid_in       ( add_valid ),

    .sum_out        ( next_nonposted_header_count ),
    .valid_out      ( nonposted_valid ),

    .halt_i         ( 1'b0 )
);

//////////////////////////////////////////////
// Completion Header Adder
//////////////////////////////////////////////
BMD_ADDER #(
    .WIDTH_A        ( 64 ),
    .WIDTH_B        ( 8 ),
    .LATENCY        ( LATENCY )
) CH_ADDER (
    .clk            ( clk ),
    .rst_n          ( rst_n ),

    .a_in           ( completion_header_count ),
    .b_in           ( completion_acum ),
    .valid_in       ( add_valid  ),

    .sum_out        ( next_completion_header_count ),
    .valid_out      ( completion_valid ),

    .halt_i         ( 1'b0 )
);

//////////////////////////////////////////////
// Data Adder
//////////////////////////////////////////////
BMD_ADDER #(
    .WIDTH_A        ( 64 ),
    .WIDTH_B        ( 8 ),
    .LATENCY        ( LATENCY )
) DATA_ADDER (
    .clk            ( clk ),
    .rst_n          ( rst_n ),

    .a_in           ( data_count ),
    .b_in           ( data_acum ),
    .valid_in       ( add_valid ),

    .sum_out        ( next_data_count ),
    .valid_out      ( data_valid ),

    .halt_i         ( 1'b0 )
);

localparam logic  WAIT_FOR_VALID    = 1'b0;
localparam logic  START_ADD         = 1'b1;

logic state, next_state;

always @(posedge clk) begin
    if (!rst_n) begin
        posted_header_count      <= '0;
        nonposted_header_count   <= '0;
        completion_header_count  <= '0;
        data_count               <= '0;

        posted_acum              <= '0;
        nonposted_acum           <= '0;
        completion_acum          <= '0;
        data_acum                <= '0;

        state                       <= START_ADD;
    end else begin
        if (posted_valid)        posted_header_count      <= next_posted_header_count;
        if (nonposted_valid)     nonposted_header_count   <= next_nonposted_header_count;
        if (completion_valid)    completion_header_count  <= next_completion_header_count;
        if (data_valid)          data_count               <= next_data_count;

        posted_acum      <= next_posted_acum;
        nonposted_acum   <= next_nonposted_acum;
        completion_acum  <= next_completion_acum;
        data_acum        <= next_data_acum;

        state               <= next_state;
    end
end

always_comb begin
    add_valid = 1'b0;

    next_posted_acum     = '0;
    next_nonposted_acum  = '0;
    next_completion_acum = '0;
    next_data_acum       = '0;

    next_state              = state;

    unique case (state)
        WAIT_FOR_VALID : begin
            next_posted_acum     = posted_acum;
            next_nonposted_acum  = nonposted_acum;
            next_completion_acum = completion_acum;
            next_data_acum       = data_acum;

            for (int i = 0; i < NUM_SLOTS; i++) begin
                if (valid[i]) begin
                    unique case (slots_ptype[i])
                        2'b00 : begin // Posted
                            next_posted_acum = next_posted_acum + 1;
                        end

                        2'b01 : begin // Nonposted
                            next_nonposted_acum = next_nonposted_acum + 1;
                        end

                        2'b10 : begin // Completion
                            next_completion_acum = next_completion_acum + 1;
                        end

                        2'b11 : begin // Data
                            if (slots_pd_ptr[i] == '0) begin
                                next_data_acum = next_data_acum + (DATA_SLOT_WIDTH >> 5);
                            end else begin
                                next_data_acum = next_data_acum + slots_pd_ptr[i];
                            end
                        end
                    endcase
                end
            end

            if (data_valid || completion_valid || nonposted_valid || posted_valid) begin
                next_state = START_ADD;
            end
        end

        START_ADD : begin
            for (int i = 0; i < NUM_SLOTS; i++) begin
                if (valid[i]) begin
                    unique case (slots_ptype[i])
                        2'b00 : begin // Posted
                            next_posted_acum = next_posted_acum + 1;
                        end

                        2'b01 : begin // Nonposted
                            next_nonposted_acum = next_nonposted_acum + 1;
                        end

                        2'b10 : begin // Completion
                            next_completion_acum = next_completion_acum + 1;
                        end

                        2'b11 : begin // Data
                            if (slots_pd_ptr[i] == '0) begin
                                next_data_acum = next_data_acum + (DATA_SLOT_WIDTH >> 5);
                            end else begin
                                next_data_acum = next_data_acum + slots_pd_ptr[i];
                            end
                        end
                    endcase
                end
            end

            add_valid  = 1'b1;
            next_state = WAIT_FOR_VALID;
        end
    endcase
end

assign debug = {
    28'd0,
    next_posted_header_count[64],
    next_nonposted_header_count[64],
    next_completion_header_count[64],
    next_data_count[64]
};

endmodule
