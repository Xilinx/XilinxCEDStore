//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : The Xilinx PCI Express DMA 
// File       : qdma_stm_lpbk.sv
// Version    : 5.0
//-----------------------------------------------------------------------------


`timescale 1ps/1ps
//`include "qdma_axi4mm_axi_bridge_exdes.vh"
//`include "pciedmacoredefines_exdes.vh"
//`include "qdma_defines_exdes.vh"
//`include "mdma_defines_exdes.svh"
`include "qdma_stm_defines.svh"

module qdma_stm_lpbk #(
    parameter MAX_DATA_WIDTH    = 512,
    parameter TDEST_BITS        = 16,
    parameter TCQ               = 0
) (

    // Clock and Reset
    input                                           clk,
    input                                           rst_n,

    //Input from FAB
    input  [MAX_DATA_WIDTH-1:0]                     in_axis_tdata,
    input                                           in_axis_tvalid,
    input  [TDEST_BITS-1:0]                         in_axis_tdest,
    input                                           in_axis_tuser,
    input                                           in_axis_tlast,
    output logic                                    in_axis_tready,
    //TODO: Is there a separate port for tid?

    //Output to FAB
    output  logic [MAX_DATA_WIDTH-1:0]              out_axis_tdata,
    output  logic                                   out_axis_tuser,
    output  logic                                   out_axis_tlast,
    output  logic                                   out_axis_tvalid,
    input                                           out_axis_tready
    //TODO: Find out why no TDEST here
);


    //----------------------------------------------------------------
    //declarations
    //----------------------------------------------------------------

    typedef struct packed {
        logic [MAX_DATA_WIDTH-1:0]                  tdata;
        logic                                       tuser;
        logic [TDEST_BITS-1:0]                      tdest;
        logic                                       tlast;
    } stm_lpbk_fifo_t;

    stm_lpbk_fifo_t                                 fifo_in_data;
    logic                                           fifo_in_vld;
    logic                                           fifo_in_rdy;

    stm_lpbk_fifo_t                                 fifo_out_data;
    logic                                           fifo_out_vld;
    logic                                           fifo_out_rdy;

    localparam FIFO_DEPTH   = 2;
    localparam FIFO_WIDTH   = $bits(stm_lpbk_fifo_t);
    //----------------------------------------------------------------



    //----------------------------------------------------------------
    //Loopback 
    //----------------------------------------------------------------
    //when looping back a header beat, translate from h2c to c2h hdr format
    //when looping back a payload beat, do a faithful loopback
    
    always_comb begin

        if (in_axis_tuser) begin
            h2c_stub_hdr_beat_t                     h2c_hdr_beat;
            c2h_stub_hdr_beat_t                     c2h_hdr_beat;

            h2c_hdr_beat                    = in_axis_tdata;

            c2h_hdr_beat                    = '0;
            c2h_hdr_beat.qid                = h2c_hdr_beat.qid;
            c2h_hdr_beat.flow_id            = h2c_hdr_beat.flow_id;
            c2h_hdr_beat.tdest              = h2c_hdr_beat.tdest;
            c2h_hdr_beat.rsv3               = h2c_hdr_beat.rsv3;
            c2h_hdr_beat.cmp.tmh.pkt_len    = h2c_hdr_beat.cdh_slot_0.tmh.pld_len;
            c2h_hdr_beat.cmp.tmh.eot        = h2c_hdr_beat.cdh_slot_0.tmh.eot;
            c2h_hdr_beat.cmp.tmh.usr_int    = 1'b0; //NOTE: Hardcoded to 0
            c2h_hdr_beat.cmp.cmp_data_0     = '0; //This will become the WrbRng entry

            fifo_in_data.tdata = c2h_hdr_beat;
        end
        else begin
            fifo_in_data.tdata = in_axis_tdata;
        end

        fifo_in_data.tuser  = in_axis_tuser;
        fifo_in_data.tdest  = in_axis_tdest;
        fifo_in_data.tlast  = in_axis_tlast;

        fifo_in_vld         = in_axis_tvalid;
        in_axis_tready      = fifo_in_rdy;
    end


    qdma_fifo_lut #(
        .FIFO_DEPTH     (FIFO_DEPTH),
        .IN_BITS        (FIFO_WIDTH),
        .OUT_BITS       (FIFO_WIDTH),
        .OUT_REG        (0),
        .EN_CRDT        (0),
        .SB_BITS        (1),
        .OUT_SRAM       (0),
        .DNF            (1),
        .UPF            (1)
    ) u_inp_fifo (
        .clk                (clk),
        .rst_n              (rst_n),
        .in_data            (fifo_in_data),
        .in_data_en         (1'b0),
        .in_sb              (1'b0),
        .in_rdy             (fifo_in_rdy),
        .in_vld             (fifo_in_vld),
        .crdt_req           (1'b0),
        .crdt_req_cnt       (1'b1),
        .crdt_gnt           (),
        .addr_collis        (1'b0),
        .out_data           (fifo_out_data),
        .out_sb             (),
        .out_ren            (1'b0),
        .out_inc            (1'b0),
        .out_last           (),
        .out_vld            (fifo_out_vld),
        .out_rdy            (fifo_out_rdy),
        .crdt               (),
        .cnt                ()
    );

    always_comb begin
        out_axis_tdata  = fifo_out_data.tdata;
        out_axis_tuser  = fifo_out_data.tuser;
        out_axis_tlast  = fifo_out_data.tlast;

        out_axis_tvalid = fifo_out_vld;
        fifo_out_rdy    = out_axis_tready;
    end
    //----------------------------------------------------------------
endmodule




