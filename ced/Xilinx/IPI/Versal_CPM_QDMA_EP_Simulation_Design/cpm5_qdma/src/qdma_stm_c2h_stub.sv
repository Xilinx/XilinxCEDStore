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
// File       : qdma_stm_c2h_stub.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

`ifndef QDMA_STM_C2H_STUB_SV
`define QDMA_STM_C2H_STUB_SV

`timescale 1ps/1ps
//`include "qdma_axi4mm_axi_bridge_exdes.vh"
//`include "pciedmacoredefines_exdes.vh"
//`include "qdma_defines_exdes.vh"
//`include "mdma_defines_exdes.svh"
`include "qdma_stm_defines.svh"

module  qdma_stm_c2h_stub #(
    parameter MAX_DATA_WIDTH    = 512,
    parameter TDEST_BITS        = 16,
    parameter TCQ               = 0
) (

    // Clock and Reset
    input                                           clk,
    input                                           rst_n,

    //Input from FAB
    input   [MAX_DATA_WIDTH-1:0]                    in_axis_tdata,
    input                                           in_axis_tuser,
    input                                           in_axis_tlast,
    input                                           in_axis_tvalid,
    output logic                                    in_axis_tready,
    //TODO: Find out why no TDEST here

    //HDR output to QDMA
    output c2h_stub_std_cmp_t                       out_axis_cmp_data,
    output c2h_stub_std_cmp_ctrl_t                  out_axis_cmp_ctrl,
    output logic                                    out_axis_cmp_tlast,
    output logic                                    out_axis_cmp_tvalid,
    input                                           out_axis_cmp_tready,

    //PLD output to QDMA
    output mdma_c2h_axis_data_exdes_t                     out_axis_pld_data,
    output mdma_c2h_axis_ctrl_exdes_t                     out_axis_pld_ctrl,
    output logic [$clog2(MAX_DATA_WIDTH/8)-1:0]     out_axis_pld_mty,
    output logic                                    out_axis_pld_tlast,
    output logic                                    out_axis_pld_tvalid,
    input                                           out_axis_pld_tready
);

    //----------------------------------------------------------------
    //declarations
    //----------------------------------------------------------------
    typedef struct packed {
        logic [MAX_DATA_WIDTH-1:0]                  tdata;
        logic                                       tuser;
        logic                                       tlast;
    } c2h_stub_inp_fifo_t;

    c2h_stub_inp_fifo_t                             inp_fifo_in_data;
    logic                                           inp_fifo_in_vld;
    logic                                           inp_fifo_in_rdy;
    c2h_stub_inp_fifo_t                             inp_fifo_out_data;
    logic                                           inp_fifo_out_vld;
    logic                                           inp_fifo_out_rdy;

    typedef struct packed {
        c2h_stub_std_cmp_t          data;
        c2h_stub_std_cmp_ctrl_t     ctrl;
    } c2h_stub_cmp_fifo_t;

    c2h_stub_cmp_fifo_t                             cmp_fifo_in_data;
    logic                                           cmp_fifo_in_vld;
    logic                                           cmp_fifo_in_rdy;
    c2h_stub_cmp_fifo_t                             cmp_fifo_out_data;
    logic                                           cmp_fifo_out_vld;
    logic                                           cmp_fifo_out_rdy;

    typedef struct packed {
        mdma_c2h_axis_data_exdes_t                        data;
        mdma_c2h_axis_ctrl_exdes_t                        ctrl;
        logic [$clog2(MAX_DATA_WIDTH/8)-1:0]        mty;
        logic                                       tlast;
    } c2h_stub_pld_fifo_t;

    c2h_stub_pld_fifo_t                             pld_fifo_in_data;
    logic                                           pld_fifo_in_vld;
    logic                                           pld_fifo_in_rdy;
    c2h_stub_pld_fifo_t                             pld_fifo_out_data;
    logic                                           pld_fifo_out_vld;
    logic                                           pld_fifo_out_rdy;

    typedef struct packed {
        logic                                       usr_int;
        logic                                       eot;
        logic [15:0]                                pkt_len;
        mdma_qid_exdes_t                                  qid;
    } stm_c2h_hld_ctx_t;

    stm_c2h_hld_ctx_t           hld_ctx;
    stm_c2h_hld_ctx_t           hld_ctx_nxt;
    logic [15:0]                rem_pkt_len;
    logic [15:0]                rem_pkt_len_nxt;

    logic [15:0]                pkt_id_nxt;
    logic [15:0]                pkt_id;

    localparam INP_FIFO_DEPTH   = 2;
    localparam INP_FIFO_WIDTH   = $bits(c2h_stub_inp_fifo_t);
    localparam WRB_FIFO_DEPTH   = 2;
    localparam WRB_FIFO_WIDTH   = $bits(c2h_stub_cmp_fifo_t);
    localparam PLD_FIFO_DEPTH   = 2;
    localparam PLD_FIFO_WIDTH   = $bits(c2h_stub_pld_fifo_t);
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
    //hdr-pld demux +CDH holding stage
    //----------------------------------------------------------------

    //When HDR(TUSER=1) beat is at the head of the inp_fifo:
    //  + apply the TMH part of the HDR at the input of the holding stage
    //  + apply the WRB part of the HDR at the input of the cmp_fifo
    //  + pop the inp_fifo if the cmp_fifo is ready

    //When PLD(TUSER=0) beat is at the head of the inp_fifo:
    //  + apply the relevant bits(from the holding stage0 at the input of the pld_fifo.ctrl
    //  + apply the pld(from the inp_fifo head) at the input of the pld_fifo.data
    //  pop the inp_fifo if the pld_fifo is ready

    always_comb begin

        hld_ctx_nxt         = hld_ctx;
        rem_pkt_len_nxt     = rem_pkt_len;
        inp_fifo_out_rdy    = 1'b0;
        cmp_fifo_in_vld     = 1'b0;
        pld_fifo_in_vld     = 1'b0;
        cmp_fifo_in_data    = '0;
        pld_fifo_in_data    = '0;

        if (inp_fifo_out_vld) begin
            if (inp_fifo_out_data.tuser) begin

                //hdr beat
                c2h_stub_hdr_beat_t     hdr_beat;
                hdr_beat                                = inp_fifo_out_data.tdata;

                //held CTX
                hld_ctx_nxt.qid                         = hdr_beat.qid;
                hld_ctx_nxt.pkt_len                     = hdr_beat.cmp.tmh.pkt_len;
                hld_ctx_nxt.usr_int                     = hdr_beat.cmp.tmh.usr_int;

                //initialize remaining pkt len with pkt_len
                rem_pkt_len_nxt                         = hdr_beat.cmp.tmh.pkt_len;

                //cmp_fifo data+parity
                cmp_fifo_in_data.data.cmp_ent.usr_data  = $bits(cmp_fifo_in_data.data.cmp_ent.usr_data)'(hdr_beat.cmp.cmp_data_0);
                cmp_fifo_in_data.data.cmp_ent.len       = hdr_beat.cmp.tmh.pkt_len;
                cmp_fifo_in_data.data.cmp_ent.desc_used = 1'b1; //We always send PLD+CMPT
                cmp_fifo_in_data.data.cmp_size          = WRB_DSC_16B_EXDES; //NOTE: Design limitation. Hardcoded
                cmp_fifo_in_data.ctrl.user_trig         = hdr_beat.cmp.tmh.usr_int;
                cmp_fifo_in_data.ctrl.error_idx         = 3'd0; //Use CMPT_FORMAT_REG0 of QDMA
                cmp_fifo_in_data.ctrl.color_idx         = 3'd0; //Use CMPT_FORMAT_REG0 of QDMA
                cmp_fifo_in_data.ctrl.wait_pld_pkt_id   = pkt_id;
                cmp_fifo_in_data.ctrl.cmpt_type         = 2'd3; //HAS_PLD
                cmp_fifo_in_data.ctrl.qid               = hdr_beat.qid;

                //compute cmp data parity(defined as bit-per-word odd parity)
                for (int i=0; i<$bits(cmp_fifo_in_data.data.dpar); i=i+1) begin
                    cmp_fifo_in_data.data.dpar[i] = ~^cmp_fifo_in_data.data.cmp_ent[i*32+:32];
                end

                //flow control
                cmp_fifo_in_vld                         = 1;
                inp_fifo_out_rdy                        = cmp_fifo_in_rdy ? 1 : 0;
            end
            else begin

                //pld fifo data+parity
                pld_fifo_in_data.data.tdata     = inp_fifo_out_data.tdata;
                //compute pld data parity(defined as bit-per-byte odd parity)
                for (int i=0; i<$bits(pld_fifo_in_data.data.par); i=i+1) begin
                    pld_fifo_in_data.data.par[i] = ~^pld_fifo_in_data.data.tdata[i*8+:8];
                end

                //pld fifo ctrl
                pld_fifo_in_data.ctrl           = '0;
                pld_fifo_in_data.ctrl.has_cmpt  = 1'd1; //HAS_CMPT
                pld_fifo_in_data.ctrl.qid       = hld_ctx.qid;
                pld_fifo_in_data.ctrl.len       = hld_ctx.pkt_len;

                //mty and remaining pkt_len
                pld_fifo_in_data.mty            = inp_fifo_out_data.tlast ? (MAX_DATA_WIDTH/8) - rem_pkt_len : '0;
                if (pld_fifo_in_rdy) begin
                    rem_pkt_len_nxt             = rem_pkt_len - (MAX_DATA_WIDTH/8);
                end

                //flow control
                pld_fifo_in_data.tlast          = inp_fifo_out_data.tlast;
                pld_fifo_in_vld                 = 1;
                inp_fifo_out_rdy                = pld_fifo_in_rdy ? 1 : 0;
            end
        end
    end
    `XSRREG_HARD_CLR_EXDES(clk, rst_n, hld_ctx, hld_ctx_nxt)
    `XSRREG_HARD_CLR_EXDES(clk, rst_n, rem_pkt_len, rem_pkt_len_nxt)

    always_comb begin
        pkt_id_nxt = pkt_id;
        if (pld_fifo_in_vld && pld_fifo_in_rdy && pld_fifo_in_data.tlast) begin
            pkt_id_nxt = pkt_id + 1'd1;
        end
    end
    `XSRREG_HARD_CLR_EXDES(clk, rst_n, pkt_id, pkt_id_nxt)

    //----------------------------------------------------------------



    //----------------------------------------------------------------
    //2-entry cmp/pld output fifos
    //----------------------------------------------------------------
     qdma_fifo_lut #(
        .FIFO_DEPTH     (WRB_FIFO_DEPTH),
        .IN_BITS        (WRB_FIFO_WIDTH),
        .OUT_BITS       (WRB_FIFO_WIDTH),
        .OUT_REG        (0),
        .EN_CRDT        (0),
        .SB_BITS        (1),
        .OUT_SRAM       (0),
        .DNF            (1),
        .UPF            (1)
    ) u_cmp_fifo (
        .clk                (clk),
        .rst_n              (rst_n),
        .in_data            (cmp_fifo_in_data),
        .in_data_en         (1'b0),
        .in_sb              (1'b0),
        .in_rdy             (cmp_fifo_in_rdy),
        .in_vld             (cmp_fifo_in_vld),
        .crdt_req           (1'b0),
        .crdt_req_cnt       (1'b1),
        .crdt_gnt           (),
        .addr_collis        (1'b0),
        .out_data           (cmp_fifo_out_data),
        .out_sb             (),
        .out_ren            (1'b0),
        .out_inc            (1'b0),
        .out_last           (),
        .out_vld            (cmp_fifo_out_vld),
        .out_rdy            (cmp_fifo_out_rdy),
        .crdt               (),
        .cnt                ()
    );

    always_comb begin
        out_axis_cmp_data       = cmp_fifo_out_data.data;
        out_axis_cmp_ctrl       = cmp_fifo_out_data.ctrl;
        out_axis_cmp_tlast      = 1'b1;
        out_axis_cmp_tvalid     = cmp_fifo_out_vld;
        cmp_fifo_out_rdy        = out_axis_cmp_tready;
    end

     qdma_fifo_lut #(
        .FIFO_DEPTH     (PLD_FIFO_DEPTH),
        .IN_BITS        (PLD_FIFO_WIDTH),
        .OUT_BITS       (PLD_FIFO_WIDTH),
        .OUT_REG        (0),
        .EN_CRDT        (0),
        .SB_BITS        (1),
        .OUT_SRAM       (0),
        .DNF            (1),
        .UPF            (1)
    ) u_pld_fifo (
        .clk                (clk),
        .rst_n              (rst_n),
        .in_data            (pld_fifo_in_data),
        .in_data_en         (1'b0),
        .in_sb              (1'b0),
        .in_rdy             (pld_fifo_in_rdy),
        .in_vld             (pld_fifo_in_vld),
        .crdt_req           (1'b0),
        .crdt_req_cnt       (1'b1),
        .crdt_gnt           (),
        .addr_collis        (1'b0),
        .out_data           (pld_fifo_out_data),
        .out_sb             (),
        .out_ren            (1'b0),
        .out_inc            (1'b0),
        .out_last           (),
        .out_vld            (pld_fifo_out_vld),
        .out_rdy            (pld_fifo_out_rdy),
        .crdt               (),
        .cnt                ()
    );

    always_comb begin
        out_axis_pld_data       = pld_fifo_out_data.data;
        out_axis_pld_ctrl       = pld_fifo_out_data.ctrl;
        out_axis_pld_mty        = pld_fifo_out_data.mty;
        out_axis_pld_tlast      = pld_fifo_out_data.tlast;
        out_axis_pld_tvalid     = pld_fifo_out_vld;
        pld_fifo_out_rdy        = out_axis_pld_tready;

    end
    //----------------------------------------------------------------

endmodule

//NOTE: Design assumptions/limitations: 
//      + There is always a PLD packet following the CDH packet. In other words, we do not use QDMA's imm_data feature
//      + 16B WRB only
//      + No dis_wrb

`endif // QDMA_STM_C2H_STUB_SV


