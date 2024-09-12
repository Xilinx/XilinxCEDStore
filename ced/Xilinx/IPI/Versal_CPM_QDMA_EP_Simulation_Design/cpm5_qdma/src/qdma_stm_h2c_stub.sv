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
// File       : qdma_stm_h2c_stub.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

`ifndef QDMA_STM_H2C_STUB_SV
`define QDMA_STM_H2C_STUB_SV

`timescale 1ps/1ps
//`include "qdma_axi4mm_axi_bridge_exdes.vh"
//`include "pciedmacoredefines_exdes.vh"
//`include "qdma_defines_exdes.vh"
//`include "mdma_defines_exdes.svh"
`include "qdma_stm_defines.svh"


module  qdma_stm_h2c_stub #(
    parameter MAX_DATA_WIDTH    = 512,
    parameter TDEST_BITS        = 16,
    parameter TCQ               = 0
) (
    // Clock and Reset
    input                                           clk,
    input                                           rst_n,

    //Input from QDMA
    input  [MAX_DATA_WIDTH-1:0]                     in_axis_tdata,
    input  mdma_h2c_axis_tuser_exdes_t                    in_axis_tuser,
    input                                           in_axis_tlast,
    input                                           in_axis_tvalid,
    output logic                                    in_axis_tready,

    //Output to FAB
    output logic [MAX_DATA_WIDTH-1:0]               out_axis_tdata,
    output logic                                    out_axis_tvalid,
    output logic [TDEST_BITS-1:0]                   out_axis_tdest,
    output logic                                    out_axis_tuser,
    output logic                                    out_axis_tlast,
    input                                           out_axis_tready
    //TODO: Is there a separate port for tid?
);

    //----------------------------------------------------------------
    //declarations
    //----------------------------------------------------------------
    typedef struct packed {
        logic [MAX_DATA_WIDTH-1:0]      tdata;
        mdma_h2c_axis_tuser_exdes_t           tuser;
        logic                           tlast;
    } h2c_stub_in_fifo_t;

    h2c_stub_in_fifo_t                  inp_fifo_in_data;
    logic                               inp_fifo_in_vld;
    logic                               inp_fifo_in_rdy;

    h2c_stub_in_fifo_t                  inp_fifo_out_data;
    logic                               inp_fifo_out_vld;
    logic                               inp_fifo_out_rdy;

    logic                               send_pld;
    logic                               send_pld_nxt;

    logic [MAX_DATA_WIDTH-1:0]          out_axis_tdata_nxt; //TODO: Use 1 deep LUTRAM?
    logic                               out_axis_tuser_nxt;
    logic [TDEST_BITS:0]                out_axis_tdest_nxt;
    logic                               out_axis_tlast_nxt;
    logic                               out_axis_tvalid_nxt;

    localparam INP_FIFO_DEPTH   = 2;
    localparam INP_FIFO_WIDTH   = $bits(h2c_stub_in_fifo_t);
    //----------------------------------------------------------------



    //----------------------------------------------------------------
    //2-entry input fifo
    //----------------------------------------------------------------
    always_comb begin
        inp_fifo_in_data.tdata  = in_axis_tdata;
        inp_fifo_in_data.tuser  = in_axis_tuser;
        inp_fifo_in_data.tlast  = in_axis_tlast;
        inp_fifo_in_vld         = in_axis_tvalid;

        in_axis_tready          = inp_fifo_in_rdy;
    end

     qdma_fifo_lut #(
        .FIFO_DEPTH     (INP_FIFO_DEPTH),
        .IN_BITS        (INP_FIFO_WIDTH),
        .OUT_BITS       (INP_FIFO_WIDTH),
        .OUT_REG        (0),
        .EN_CRDT        (0),
        .SB_BITS        (1),
        .OUT_SRAM       (0),
        .DNF            (1),
        .UPF            (1)
    ) u_inp_fifo (
        .clk                (clk),
        .rst_n              (rst_n),
        .in_data            (inp_fifo_in_data),
        .in_data_en         (1'b0),
        .in_sb              (1'b0),
        .in_rdy             (inp_fifo_in_rdy),
        .in_vld             (inp_fifo_in_vld),
        .crdt_req           (1'b0),
        .crdt_req_cnt       (1'b1),
        .crdt_gnt           (),
        .addr_collis        (1'b0),
        .out_data           (inp_fifo_out_data),
        .out_sb             (),
        .out_ren            (1'b0),
        .out_inc            (1'b0),
        .out_last           (),
        .out_vld            (inp_fifo_out_vld),
        .out_rdy            (inp_fifo_out_rdy),
        .crdt               (),
        .cnt                ()
    );
    //----------------------------------------------------------------



    //----------------------------------------------------------------
    //HDR-PLD mux stage
    //----------------------------------------------------------------
    always_comb begin

        h2c_stub_hdr_beat_t hdr_beat;

        out_axis_tdata_nxt  = out_axis_tdata;
        out_axis_tuser_nxt  = out_axis_tuser;
        out_axis_tdest_nxt  = out_axis_tdest;
        out_axis_tlast_nxt  = out_axis_tlast;
        out_axis_tvalid_nxt = out_axis_tvalid;
        inp_fifo_out_rdy    = 0;

        if (!out_axis_tvalid || out_axis_tready) begin
            if (inp_fifo_out_vld) begin
                out_axis_tdest_nxt  = inp_fifo_out_data.tuser.qid[5:0]; //tdest is a sb signal. It is also on hdr_beat
                out_axis_tvalid_nxt = 1;

                if (!send_pld) begin
                    hdr_beat                = '0;
                    hdr_beat.qid            = inp_fifo_out_data.tuser.qid;
                    hdr_beat.flow_id        = inp_fifo_out_data.tuser.qid; //NOTE: Hardcoded: flow_id = qid[5:0]
                    hdr_beat.tdest          = inp_fifo_out_data.tuser.qid; //NOTE: Hardcoded: tdest = qid[5:0]
                    hdr_beat.cdh_slot_0.tmh = inp_fifo_out_data.tuser.mdata;
                    hdr_beat.rsv3           = inp_fifo_out_data.tuser.mdata[31:16];

                    out_axis_tuser_nxt      = 1;
                    out_axis_tlast_nxt      = 0;

                    out_axis_tdata_nxt      = hdr_beat;
                    inp_fifo_out_rdy        = 0;
                end
                else begin
                    out_axis_tuser_nxt  = 0;
                    out_axis_tlast_nxt  = inp_fifo_out_data.tlast;
                    out_axis_tdata_nxt  = inp_fifo_out_data.tdata;
                    inp_fifo_out_rdy    = 1;
                end
            end
            else begin
                out_axis_tvalid_nxt = 0;
            end
        end
    end

    `XSRREG_XDMA_EXDES(clk, rst_n, out_axis_tvalid, out_axis_tvalid_nxt, 'h0)

    `XSRREG_HARD_CLR_EXDES(clk, rst_n, out_axis_tdest, out_axis_tdest_nxt)
    `XSRREG_HARD_CLR_EXDES(clk, rst_n, out_axis_tlast, out_axis_tlast_nxt)
    `XSRREG_HARD_CLR_EXDES(clk, rst_n, out_axis_tuser, out_axis_tuser_nxt)
    `XSRREG_HARD_CLR_EXDES(clk, rst_n, out_axis_tdata, out_axis_tdata_nxt)

    //mux control logic
    always_comb begin

        send_pld_nxt = send_pld;
        if (inp_fifo_out_vld && (!out_axis_tvalid || out_axis_tready)) begin
            if (!send_pld) begin
                send_pld_nxt = 1;
            end
            else if (inp_fifo_out_data.tlast) begin
                send_pld_nxt = 0;
            end
        end
    end

    `XSRREG_XDMA_EXDES(clk, rst_n, send_pld, send_pld_nxt, 'h0)
    //----------------------------------------------------------------

endmodule
`endif // QDMA_STM_H2C_STUB_SV

