
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
// File       : BMD_AXIST_RX_MUX.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_RX_MUX.sv
//--
//-- Description: Buffer the incoming RX TLPs on a per slot basis (buffer per slot)
//--              and controls the credits. Splitter component will write RX into
//--              the slot FIFOs, and the combiner component provides a simple
//--              interface for serially reading the slots.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_RX_MUX
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
#(
    parameter int           FIFO_DEPTH = 512   // Min value is 16
) (
    input logic                         clk,
    input logic                         rst_n,
    // From core
    input rx_intf                       rx,
    // credit signals
    output logic [NUM_SLOTS-1:0][1:0]   empty,
    output logic [NUM_SLOTS-1:0][1:0]   rd_en,
    // To BMD (main)
    output logic                        mmio_valid,
    output rx_fifo_intf                 mmio_slot,

    // From BMD
    input  logic                        mmio_rd_en,
    // To BMD (cpl)
    output rx_intf                      rx_cpl,

    output logic [63:0]                 rx_posted_header_count,
    output logic [63:0]                 rx_nonposted_header_count,
    output logic [63:0]                 rx_completion_header_count,
    output logic [63:0]                 rx_data_count,

    output logic [31:0]                 debug_cpl_filter,
    output logic [31:0]                 debug_fifo,
    output logic [31:0]                 debug_packer
);

logic [NUM_SLOTS-1:0]                          wr_en_main;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_RX-1:0]   wr_data_main;
logic [NUM_SLOTS-1:0]                          wr_en_cpl;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_RX-1:0]   wr_data_cpl;
rx_fifo_intf [NUM_SLOTS-1:0]                   dout_main;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_RX-1:0]   dout_cpl;
logic [NUM_SLOTS-1:0]                          empty_cpl;
logic [NUM_SLOTS-1:0]                          valid_cpl; // inverse of empty_cpl
logic [NUM_SLOTS-1:0]                          empty_main;
logic [NUM_SLOTS-1:0]                          rd_en_main;
logic [NUM_SLOTS-1:0]                          overflow_main;
logic [NUM_SLOTS-1:0]                          underflow_main;
logic [NUM_SLOTS-1:0]                          overflow_cpl;
logic [NUM_SLOTS-1:0]                          underflow_cpl;
logic [NUM_SLOTS-1:0]                          full_main;
logic [NUM_SLOTS-1:0]                          full_cpl;

always @(posedge clk) begin
    if (!rst_n) begin
        empty <= '1;
        rd_en <= '0;
    end else begin
        for (int i = 0; i < NUM_SLOTS; i++) begin
            empty[i] <= {empty_main[i], empty_cpl[i]};
            rd_en[i] <= {rd_en_main[i], valid_cpl[i]};
        end
    end
end
always_comb begin
    for (int i = 0; i < NUM_SLOTS; i++) begin
        valid_cpl[i] = !empty_cpl[i];
    end
end

always_comb begin
    debug_fifo = '0;
    case (NUM_SLOTS)
        1 : begin
            debug_fifo = {
                wr_en_cpl[0],
                wr_en_main[0],
                empty_cpl[0],
                full_cpl[0],
                empty_main[0],
                full_main[0],
                underflow_cpl[0],
                overflow_cpl[0],
                underflow_main[0],
                overflow_main[0]
            };
        end

        2 : begin
            debug_fifo = {
                wr_en_cpl[1],
                wr_en_cpl[0],
                wr_en_main[1],
                wr_en_main[0],
                empty_cpl[1],
                empty_cpl[0],
                full_cpl[1],
                full_cpl[0],
                empty_main[1],
                empty_main[0],
                full_main[1],
                full_main[0],
                underflow_cpl[1],
                underflow_cpl[0],
                overflow_cpl[1],
                overflow_cpl[0],
                underflow_main[1],
                underflow_main[0],
                overflow_main[1],
                overflow_main[0]
            };
        end

        default : begin
            debug_fifo = {
                wr_en_cpl[2],
                wr_en_cpl[1],
                wr_en_cpl[0],
                wr_en_main[2],
                wr_en_main[1],
                wr_en_main[0],
                empty_cpl[2],
                empty_cpl[1],
                empty_cpl[0],
                full_cpl[2],
                full_cpl[1],
                full_cpl[0],
                empty_main[2],
                empty_main[1],
                empty_main[0],
                full_main[2],
                full_main[1],
                full_main[0],
                underflow_cpl[2],
                underflow_cpl[1],
                underflow_cpl[0],
                overflow_cpl[2],
                overflow_cpl[1],
                overflow_cpl[0],
                underflow_main[2],
                underflow_main[1],
                underflow_main[0],
                overflow_main[2],
                overflow_main[1],
                overflow_main[0]
            };
        end
    endcase
end

///////////////////////////////////////////////////////////////////
//
//            Stream Preparation
//
///////////////////////////////////////////////////////////////////
BMD_AXIST_RX_CPL_FILTER EP_RX_CPL_FILTER (
    .clk                        ( clk ),
    .rst_n                      ( rst_n ),
    // From core
    .rx                         ( rx ),
    // To FIFOs (main)
    .wr_en_main                 ( wr_en_main ),
    .wr_data_main               ( wr_data_main ),
    // To FIFOs (cpl)
    .wr_en_cpl                  ( wr_en_cpl ),
    .wr_data_cpl                ( wr_data_cpl ),

    .rx_posted_header_count     ( rx_posted_header_count ),
    .rx_nonposted_header_count  ( rx_nonposted_header_count ),
    .rx_completion_header_count ( rx_completion_header_count ),
    .rx_data_count              ( rx_data_count ),

    .debug                      ( debug_cpl_filter )
);

///////////////////////////////////////////////////////////////////
//
//            Main Pipeline
//
///////////////////////////////////////////////////////////////////

genvar i;
generate
for (i=0; i<NUM_SLOTS; i++) begin : g_per_slot_main_buffer
    xpm_fifo_sync #(
        //.FIFO_MEMORY_TYPE   ("block"),
        .FIFO_READ_LATENCY  ( 1 ),
        .FIFO_WRITE_DEPTH   ( FIFO_DEPTH ),
        .READ_MODE          ( "std" ),
        .USE_ADV_FEATURES   ( "0101" ),
        .READ_DATA_WIDTH    ( ENCODING_WIDTH_RX ),
        .WRITE_DATA_WIDTH   ( ENCODING_WIDTH_RX )
    ) EP_RX_MAIN_FIFO (
        .wr_clk             ( clk ),
        .rst                ( !rst_n ),

        .wr_en              ( wr_en_main[i] ),          // FROM filter
        .din                ( wr_data_main[i] ),        // FROM filter

        .full               ( full_main[i] ),

        .rd_en              ( rd_en_main[i] ),
        .dout               ( dout_main[i] ),
        .empty              ( empty_main[i] ),

        .rd_rst_busy(),
        .wr_rst_busy(),
        // Error
        .overflow           ( overflow_main[i] ),
        .underflow          ( underflow_main[i] ),
        // Unused
        .sleep('0),
        .almost_full(),
        .almost_empty(),
        .prog_empty(),
        .prog_full(),
        .wr_ack(),
        .sbiterr(),
        .rd_data_count(),
        .wr_data_count(),
        .injectdbiterr('0),
        .injectsbiterr('0),
        .data_valid(),
        .dbiterr()
    );
end
endgenerate

logic [1:0] rd_ptr_pre, rd_ptr_post;
logic rd_valid_d;
always @(posedge clk) begin
    if (!rst_n) begin
        rd_ptr_pre <= '0;
        rd_ptr_post <= '0;

        rd_valid_d <= '0;
    end else begin
        rd_ptr_pre <= (rd_ptr_pre + (mmio_rd_en & !empty_main[rd_ptr_pre])) % NUM_SLOTS;
        rd_ptr_post <= (rd_ptr_post + rd_valid_d) % NUM_SLOTS;

        rd_valid_d <= mmio_rd_en & !empty_main[rd_ptr_pre];
    end
end

assign mmio_valid = rd_valid_d;
assign mmio_slot  = dout_main[rd_ptr_post];

always_comb begin
    rd_en_main = '0;
    rd_en_main[rd_ptr_pre] = mmio_rd_en;
end

///////////////////////////////////////////////////////////////////
//
//            Completion Pipeline
//
///////////////////////////////////////////////////////////////////

genvar j;
generate
for (j=0; j<NUM_SLOTS; j++) begin : g_per_slot_cpl_buffer
    xpm_fifo_sync #(
        .FIFO_MEMORY_TYPE   ("block"),
        .FIFO_READ_LATENCY  ( 0 ),
        .FIFO_WRITE_DEPTH   ( FIFO_DEPTH ),
        .READ_MODE          ( "fwft" ),
        .USE_ADV_FEATURES   ( "0101" ),
        .READ_DATA_WIDTH    ( ENCODING_WIDTH_RX ),
        .WRITE_DATA_WIDTH   ( ENCODING_WIDTH_RX )
    ) EP_RX_CPL_FIFO (
        .wr_clk             ( clk ),
        .rst                ( !rst_n ),
        .wr_rst_busy        (),
        .wr_en              ( wr_en_cpl[j] ),               // FROM splitter
        .din                ( wr_data_cpl[j] ),                 // FROM splitter
        .full               ( full_cpl[j] ),
        .rd_rst_busy        (),
        .rd_en              ( valid_cpl[j] ),               // TO combiner
        .dout               ( dout_cpl[j] ),                // TO combiner
        .empty              ( empty_cpl[j] ),
        // Error
        .overflow           ( overflow_cpl[j] ),
        .underflow          ( underflow_cpl[j] ),
        // Unused
        .sleep('0),
        .almost_full(),
        .almost_empty(),
        .prog_empty(),
        .prog_full(),
        .wr_ack(),
        .sbiterr(),
        .rd_data_count(),
        .wr_data_count(),
        .injectdbiterr('0),
        .injectsbiterr('0),
        .data_valid(),
        .dbiterr()
    );
end
endgenerate

BMD_AXIST_RX_PACKER EP_RX_PACKER (
    .clk                    ( clk ),
    .rst_n                  ( rst_n ),
    // Input
    .packer_rd_en           ( 1'b1 ), // Don't backpressure completions
    .slots                  ( dout_cpl ),
    .valid                  ( valid_cpl ),
    // Output
    .rx                     ( rx_cpl ),

    .debug                  ( debug_packer )
);

endmodule // BMD_AXIST_RX_MUX
