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
// File       : BMD_AXIST_TX_MUX.sv
// Version    : 1.0
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//-- Filename: BMD_AXIST_TX_MUX.sv
//--
//-- Description: Arbitrates between multiple different streams within BMD (Reads,
//--              Writes, and Completions) and handles credits. Arbitrations is done
//--              based on passed priority and handshake signals.
//--
//--------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_TX_MUX
  import pcie_intf_pkg::*;
  import pcie_str_pkg::*;
#(
    parameter int                           FIFO_DEPTH = 512,
    parameter int                           NUM_STREAMS = 3
)(
    input  logic                            clk,
    input  logic                            rst_n,

    input  logic                            tx_credits_available,
    output logic [$clog2(NUM_STREAMS)-1:0]  tx_credits_consumed,

    output logic [1:0][NUM_SLOTS-1:0]       fifo_full,
    output logic                            wr_fifo_empty,

    // Streams for each producer
    input  tx_intf [NUM_STREAMS-1:0]        sub_tx,
    output tx_intf                          main_tx,

    output logic [NUM_SLOTS-1:0]            empty_cpl,

    output logic                            inp,

    output logic [63:0]                     tx_posted_header_count,
    output logic [63:0]                     tx_nonposted_header_count,
    output logic [63:0]                     tx_completion_header_count,
    output logic [63:0]                     tx_data_count,

    output logic [31:0]                     debug_fifo,
    output logic [31:0]                     debug_splitter,
    output logic [31:0]                     debug_arbitration
);

logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]       arb_slots;
logic [NUM_SLOTS-1:0]                              arb_valid;

// WR FIFOs
logic [NUM_SLOTS-1:0]                              wr_en_wr;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]       wr_data_wr;
logic [NUM_SLOTS-1:0]                              full_wr_n;
logic [NUM_SLOTS-1:0]                              valid_wr;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]       dout_wr;
logic [NUM_SLOTS-1:0]                              empty_wr_n;

// RD FIFOs
logic [NUM_SLOTS-1:0]                              wr_en_rd;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]       wr_data_rd;
logic [NUM_SLOTS-1:0]                              full_rd_n;
logic [NUM_SLOTS-1:0]                              valid_rd;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]       dout_rd;
logic [NUM_SLOTS-1:0]                              empty_rd_n;

// CPL FIFOs
logic [NUM_SLOTS-1:0]                              wr_en_cpl;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1 :0]      wr_data_cpl;
logic [NUM_SLOTS-1:0]                              full_cpl;
logic [NUM_SLOTS-1:0]                              valid_cpl;
logic [NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1 :0]      dout_cpl;
logic [NUM_SLOTS-1:0]                              overflow_cpl;
logic [NUM_SLOTS-1:0]                              underflow_cpl;

logic [NUM_STREAMS-1:0][NUM_SLOTS-1:0]                              rd_en_wire;
logic [NUM_STREAMS-1:0][NUM_SLOTS-1:0][ENCODING_WIDTH_TX-1:0]       dout_wire;
logic [NUM_STREAMS-1:0][NUM_SLOTS-1:0]                              empty_wire;

always_comb begin
    wr_fifo_empty = 1'b1;
    for (int i = 0; i < NUM_SLOTS; i++) begin
        if (empty_wr_n[i]) wr_fifo_empty = 1'b0;
    end
end

assign valid_rd     = rd_en_wire[2];
assign valid_wr     = rd_en_wire[1];
assign valid_cpl    = rd_en_wire[0];

assign dout_wire    = {dout_rd, dout_wr, dout_cpl};
assign empty_wire   = {~empty_rd_n, ~empty_wr_n, empty_cpl};

always_comb begin
    fifo_full = '0;
    for (int i = 0; i < 2; i++) begin
        for (int j = 0; j < NUM_SLOTS; j++) begin
            case(i)
                0 : begin
                    fifo_full[i][j] = !full_wr_n[j];
                end

                1 : begin
                    fifo_full[i][j] = !full_rd_n[j];
                end

                default : begin
                    fifo_full[i][j] = '0;
                end
            endcase
        end
    end
end

always_comb begin
    debug_fifo = '0;
    case (NUM_SLOTS)
        1 : begin
            debug_fifo = {
                full_cpl[0],
                underflow_cpl[0],
                overflow_cpl[0],
                full_rd_n[0],
                full_wr_n[0]
            };
        end

        2 : begin
            debug_fifo = {
                full_cpl[1],
                full_cpl[0],
                underflow_cpl[1],
                underflow_cpl[0],
                overflow_cpl[1],
                overflow_cpl[0],
                full_rd_n[1],
                full_rd_n[0],
                full_wr_n[1],
                full_wr_n[0]
            };
        end

        default : begin
            debug_fifo = {
                full_cpl[2],
                full_cpl[1],
                full_cpl[0],
                underflow_cpl[2],
                underflow_cpl[1],
                underflow_cpl[0],
                overflow_cpl[2],
                overflow_cpl[1],
                overflow_cpl[0],
                full_rd_n[2],
                full_rd_n[1],
                full_rd_n[0],
                full_wr_n[2],
                full_wr_n[1],
                full_wr_n[0]
            };
        end
    endcase
end

assign debug_splitter[31:27] = '0;

///////////////////////////////////////////////////////////////////
//
//            Write Pipeline
//
///////////////////////////////////////////////////////////////////

BMD_AXIST_TX_SPLITTER EP_TX_SPLITTER_WR (
    .clk                    ( clk ),
    .rst_n                  ( rst_n ),

    .tx                     ( sub_tx[0] ),
    .halt                   ( !(&full_wr_n) ),

    .wr_en                  ( wr_en_wr ),
    .wr_data                ( wr_data_wr ),
    .debug                  ( debug_splitter[8:0] )
);

genvar i;
generate
for (i=0; i<NUM_SLOTS; i++) begin : g_per_slot_wr_buffer
    SKID_BUFF #(
        .SKD_DATA_WIDTH     (ENCODING_WIDTH_TX)
    ) tx_wr_skid (
        .clk                ( clk ),
        .rst_n              ( rst_n ),

        .s_data             ( wr_data_wr[i] ),
        .s_valid            ( wr_en_wr[i] ),
        .s_ready            ( full_wr_n[i] ),

        .m_data             ( dout_wr[i] ),
        .m_valid            ( empty_wr_n[i] ),
        .m_ready            ( valid_wr[i] )
    );
end
endgenerate

///////////////////////////////////////////////////////////////////
//
//            Read Pipeline
//
///////////////////////////////////////////////////////////////////

BMD_AXIST_TX_SPLITTER EP_TX_SPLITTER_RD (
    .clk                    ( clk ),
    .rst_n                  ( rst_n ),

    .tx                     ( sub_tx[1] ),
    .halt                   ( !(&full_rd_n) ),

    .wr_en                  ( wr_en_rd ),
    .wr_data                ( wr_data_rd ),
    .debug                  ( debug_splitter[17:9])
);

genvar j;
generate
for (j=0; j<NUM_SLOTS; j++) begin : g_per_slot_rd_buffer
    SKID_BUFF #(
        .SKD_DATA_WIDTH     (ENCODING_WIDTH_TX)
    ) tx_rd_skid (
        .clk                ( clk ),
        .rst_n              ( rst_n ),

        .s_data             ( wr_data_rd[j] ),
        .s_valid            ( wr_en_rd[j] ),
        .s_ready            ( full_rd_n[j] ),

        .m_data             ( dout_rd[j] ),
        .m_valid            ( empty_rd_n[j] ),
        .m_ready            ( valid_rd[j] )
    );
end
endgenerate

///////////////////////////////////////////////////////////////////
//
//            Completion Pipeline
//
///////////////////////////////////////////////////////////////////

BMD_AXIST_TX_SPLITTER EP_TX_SPLITTER_CPL (
    .clk                    ( clk ),
    .rst_n                  ( rst_n ),

    .tx                     ( sub_tx[2] ),
    .halt                   ( 1'b0 ),

    .wr_en                  ( wr_en_cpl ),
    .wr_data                ( wr_data_cpl ),
    .debug                  ( debug_splitter[26:18] )
);

genvar k;
generate
for (k=0; k<NUM_SLOTS; k++) begin : g_per_slot_cpl_buffer
    xpm_fifo_sync #(
        .FIFO_MEMORY_TYPE   ("block"),
        .FIFO_READ_LATENCY  ( 0 ),
        .FIFO_WRITE_DEPTH   ( FIFO_DEPTH ),
        .READ_MODE          ( "fwft" ),
        .USE_ADV_FEATURES   ( "0103" ),
        .READ_DATA_WIDTH    ( ENCODING_WIDTH_TX ),
        .WRITE_DATA_WIDTH   ( ENCODING_WIDTH_TX ),
        .PROG_FULL_THRESH   ( FIFO_DEPTH - 5 )
    ) EP_TX_CPL_FIFO (
        .wr_clk             ( clk ),
        .rst                ( !rst_n ),
        .wr_rst_busy        ( ),
        .wr_en              ( wr_en_cpl[k] ),               // FROM splitter
        .din                ( wr_data_cpl[k] ),                 // FROM splitter
        .full               ( ),
        .rd_rst_busy        ( ),
        .rd_en              ( valid_cpl[k] ),               // TO combiner
        .dout               ( dout_cpl[k] ),                // TO combiner
        .empty              ( empty_cpl[k] ),
        // Error
        .overflow           ( overflow_cpl[k] ),
        .underflow          ( underflow_cpl[k] ),
        // Unused
        .sleep('0),
        .almost_full(),
        .almost_empty(),
        .prog_empty(),
        .prog_full          ( full_cpl[k] ),
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

///////////////////////////////////////////////////////////////////
//
//            Arbitration Between Streams
//
///////////////////////////////////////////////////////////////////

BMD_AXIST_TX_ARBITRATION #(
    .NUM_STREAMS            ( NUM_STREAMS )
) EP_TX_ARBITER (
    .clk                    ( clk ),
    .rst_n                  ( rst_n ),
    // FIFO
    .rd_en                  ( rd_en_wire ),
    .dout                   ( dout_wire ),
    .empty                  ( empty_wire ),
    // Packer
    .packer_rd_en           ( tx_credits_available ), // Here too to block rd_en
    .slots                  ( arb_slots ),
    .valid                  ( arb_valid ),

    .debug                  ( debug_arbitration )
);

BMD_PME_COUNTERS #(
    .IS_TX                              ( 1'b1 )
) EP_TX_PME_COUNTER (
    .clk                                ( clk ),
    .rst_n                              ( rst_n ),

    .rx_slots                           ( '0 ),
    .tx_slots                           ( arb_slots ),
    .valid                              ( arb_valid ),

    .posted_header_count                ( tx_posted_header_count ),
    .nonposted_header_count             ( tx_nonposted_header_count ),
    .completion_header_count            ( tx_completion_header_count ),
    .data_count                         ( tx_data_count ),

    .debug                              ()
);

BMD_AXIST_TX_PACKER EP_TX_PACKER (
    .clk                    ( clk ),
    .rst_n                  ( rst_n ),

    .inp                    ( inp ),

    .packer_rd_en           ( tx_credits_available ),
    .slots                  ( arb_slots ),
    .valid                  ( arb_valid ),
    .tx                     ( main_tx ),
    .tx_credits_consumed    ( tx_credits_consumed )
);

endmodule // BMD_AXIST_TX_MUX
