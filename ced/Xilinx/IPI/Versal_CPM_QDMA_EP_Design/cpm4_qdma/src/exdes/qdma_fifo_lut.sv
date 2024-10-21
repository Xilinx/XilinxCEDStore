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
// File       : qdma_fifo_lut.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

`ifndef FIFO_LUT_EXDES_SV
`define FIFO_LUT_EXDES_SV
//`include "qdma_axi4mm_axi_bridge_exdes.vh"
`timescale 1ps/1ps
`include "qdma_stm_defines.svh"


module qdma_fifo_lut #(
    parameter               TCQ=1,
    parameter               IN_BITS=128,
    parameter               OUT_BITS=128,
    parameter               SB_BITS=5,
    parameter               EN_CRDT=1,
    /*
    * Number of FIFO entries of quanta = min ( IN_BITS, OUT_BITS)
    */
    parameter               FIFO_DEPTH=4,
    // If output is wider than input then program UPF=OUT_BITS/IN_BITS
    // Else it should be 1
    parameter               UPF=1,
    // If input is wider than output then program DNF=IN_BITS/OUT_BITS
    // Else it should be 1
    parameter               DNF=1,
    parameter               OUT_REG=0,
    parameter               DNF_LOG = DNF > 1 ? $clog2(DNF+1) : 1,
    parameter               PTR_BITS= (FIFO_DEPTH > 1) ? $clog2(FIFO_DEPTH) : 1 ,
    parameter               LOC_OUT_BITS=DNF>1 ? OUT_BITS : IN_BITS,
    parameter               OUT_SRAM=0, // 1 means output will be SRAM interface, 0 will be AXI interface
    parameter               CNT_BITS=$clog2(FIFO_DEPTH+1),
    parameter               AVOID_ADDR_COLLIS=0  
) (
    input                           clk,
    input                           rst_n,

    /* Input interface */
    input  [IN_BITS-1:0]            in_data,
    //If UPF>1, then in_data_en becomes last
    input  [DNF    -1:0]            in_data_en,
    //Tie-off if Side data is not needed
    input  [DNF-1:0][SB_BITS-1:0]   in_sb,
    input                           in_vld,
    output logic                    in_rdy,

    // Credit interface. Allocation in terms of input width. 
    input                           crdt_req,
    input [DNF_LOG-1:0]             crdt_req_cnt,
    output logic                    crdt_gnt,

    /* Output Interface */
    output logic [UPF-1:0][LOC_OUT_BITS-1:0] out_data,
    output logic [UPF-1:0][SB_BITS-1:0]      out_sb,
    output logic                    out_vld,
    input                           out_rdy,
    input                           out_ren,
    input                           out_inc,
    output logic [UPF-1:0]          out_last,
    output logic [CNT_BITS-1:0]     crdt,
    output logic [CNT_BITS-1:0]     cnt,
    input logic                     addr_collis
);

    logic [PTR_BITS-1:0]        nxt_wptr, wptr;
    logic [PTR_BITS-1:0]        nxt_rptr, rptr;

    localparam UPF_LOG = UPF > 1 ? $clog2(UPF+1) : 1;

    localparam RAM_BITS =  IN_BITS > OUT_BITS ? OUT_BITS : IN_BITS;
    localparam RAM_DEPTH = FIFO_DEPTH;
    localparam MEM_SIZE = FIFO_DEPTH*RAM_BITS;

    (* ram_style = "distributed" *) logic [RAM_BITS-1:0]           sram [RAM_DEPTH-1:0];
    (* ram_style = "distributed" *) logic [SB_BITS-1:0]            sram_sb [DNF*RAM_DEPTH-1:0];
    (* ram_style = "distributed" *) logic [RAM_DEPTH-1:0][DNF-1:0]              sram_last ;

    logic [RAM_BITS-1:0]           nxt_sram [RAM_DEPTH-1:0];
    logic [SB_BITS-1:0]            nxt_sram_sb [DNF*RAM_DEPTH-1:0];

    logic [RAM_DEPTH-1:0]                       sram_vld;
    logic [DNF-1:0]                      sram_ld;
    logic [DNF-1:0][PTR_BITS-1:0]        sram_ix;
    logic [DNF-1:0][RAM_BITS-1:0]        nxt_sram_data_tmp;
    logic [DNF-1:0][SB_BITS-1:0]         nxt_sram_sb_tmp;

    logic [CNT_BITS:0]          nxt_credit, credit;
    logic [CNT_BITS-1:0]        nxt_cnt;
    logic [DNF_LOG-1:0]         inc_cnt;
    logic [UPF_LOG-1:0]         dec_cnt;
    logic [DNF_LOG-1:0]         inc_credit;
    logic [UPF_LOG-1:0]         dec_credit;

    // OUT_SRAM
    logic [UPF-1:0][LOC_OUT_BITS-1:0]  out_data_pre;
    logic                              out_pop_up;
    logic [UPF-1:0][SB_BITS-1:0]       out_sb_pre;


    localparam SCALING_BITS = DNF_LOG > 1 ? DNF_LOG : UPF_LOG;

    assign crdt = credit;

    logic           int_push;

    always_comb begin
        in_rdy = (cnt <= (FIFO_DEPTH-inc_cnt)) ? 1'b1 : 1'b0;
        int_push = in_vld && in_rdy;
    end

    always_comb begin
        integer i;
        inc_cnt = '0;
        if (DNF > 1) begin
            for (i=0; i < DNF; i += 1) begin
                if (in_data_en[i]) begin
                    inc_cnt += DNF_LOG'(1);
                end
            end
        end
        else begin
            inc_cnt = DNF_LOG'(1);
        end
    end

    always_comb begin
        integer i;
        nxt_wptr = wptr;
        if (int_push) begin
            if (DNF > 1) begin
                if ((wptr + inc_cnt) > FIFO_DEPTH-1) begin
                    nxt_wptr = FIFO_DEPTH - (wptr + inc_cnt);
                end
                else begin
                    nxt_wptr = wptr + inc_cnt;
                end
            end
            else begin
                if (wptr == FIFO_DEPTH -1) begin
                    nxt_wptr = '0;
                end
                else begin
                    nxt_wptr = wptr + 1;
                end
            end
        end
    end

    localparam ptr_shift = ((UPF > 1) ? UPF : DNF) - 1;


    always_comb begin
        int i;
        sram_vld = '0;
        if (rptr <= wptr) begin
            for (i=0; i < FIFO_DEPTH; i += 1) begin
                if (i >= rptr && i < wptr) begin
                    sram_vld[i] = 1'b1;
                end
            end
        end
        else begin
            for (i=0; i < FIFO_DEPTH; i += 1) begin
                if (i < wptr || i >= rptr) begin
                    sram_vld[i] = 1'b1;
                end
            end
        end
    end

    //logic           nxt_out_vld;
    if (UPF > 1) begin :UPF_MODE
        always_comb begin
            int i;
            logic [PTR_BITS-1:0] loc_rptr;
            out_last = '0;
            out_data_pre = '0;
            out_sb_pre = '0;
            loc_rptr = rptr;
            for (i=0; i < UPF; i += 1) begin
                out_data_pre[i] = sram[loc_rptr];
                out_sb_pre[i] =  sram_sb[loc_rptr];
                out_last[i] = sram_last[loc_rptr]&sram_vld[loc_rptr];
                if (out_last[i]) break;
                if (loc_rptr == FIFO_DEPTH-1) begin
                    loc_rptr = '0;
                end
                else begin
                    loc_rptr += 1;
                end
            end
        end
    end
    else begin
        always_comb begin
            out_data_pre = sram[rptr];
            out_last = sram_last[rptr];
            out_sb_pre =  sram_sb[rptr];
        end
    end

    if (OUT_SRAM) begin :OUTPUT_ASSIGN
        logic [UPF-1:0][SB_BITS-1:0]       out_sb_pre_p1;
        logic                              out_ren_p1;
        logic [UPF-1:0][LOC_OUT_BITS-1:0]  out_data_pre_p1;
        always_comb begin
            out_vld  = out_ren_p1;
            out_data = out_data_pre_p1;
            out_sb   = out_sb_pre_p1;
            out_pop_up = out_inc && out_ren;
        end

        `XSRREG_HARD_CLR_EXDES(clk, rst_n, out_ren_p1, out_ren)
        `XSRREG_HARD_CLR_EXDES(clk, rst_n, out_data_pre_p1, out_data_pre)
        `XSRREG_HARD_CLR_EXDES(clk, rst_n, out_sb_pre_p1, out_sb_pre)

    end
    else if (OUT_REG) begin :REG_OUTPUT
        logic [UPF-1:0][SB_BITS-1:0]        nxt_out_sb;
        logic                               nxt_out_vld;
        logic [UPF-1:0][LOC_OUT_BITS-1:0]   nxt_out_data;
        logic                               out_rdy_pre;
        always_comb begin
            nxt_out_data = out_data;
            nxt_out_sb   = out_sb;
            if (out_rdy) begin
                nxt_out_vld = 1'b0;
            end
            else begin
            nxt_out_vld      = out_vld;
            end
            if (!out_vld || out_rdy) begin
                nxt_out_vld = cnt > 0 ? 1: 0;
                nxt_out_data = out_data_pre;
                nxt_out_sb   = out_sb_pre;
            end
        end
        assign out_rdy_pre = !out_vld || out_rdy;
        assign out_pop_up = nxt_out_vld & out_rdy_pre;

        `XSRREG_HARD_CLR_EXDES(clk, rst_n, out_data, nxt_out_data)
        `XSRREG_HARD_CLR_EXDES(clk, rst_n, out_sb, nxt_out_sb)
        `XSRREG_XDMA_EXDES (clk, rst_n, out_vld, nxt_out_vld, 1'b0)
    end
    else begin
        always_comb begin
            if (UPF > 1) begin
                out_vld = cnt >= UPF ? 1: |out_last;
            end
            else begin
                out_vld = cnt > 0 ? 1: 0;
            end

            out_data = out_data_pre;
            out_sb   = out_sb_pre;
        end    
        assign out_pop_up = out_vld & out_rdy;
    end

    always_comb begin
        int i;
        logic [PTR_BITS-1:0]        loc_rptr;
        logic [SCALING_BITS-1:0]    loc_cnt;
        logic last_upd;
        last_upd = 1'b0;
        loc_rptr = '0;
        nxt_rptr = rptr;
        dec_cnt = '0;
        inc_credit = '0;
        loc_cnt = 0;
        if (out_pop_up) begin
            if (UPF == 1) begin
                dec_cnt = 1;
                inc_credit = 1;
                if (rptr == FIFO_DEPTH-1) begin
                    nxt_rptr = '0;
                end
                else begin
                    nxt_rptr = rptr + 1;
                end
            end
            else begin
                loc_cnt = 0;
                loc_rptr = rptr;
                for (i=0; i < UPF; i += 1) begin
                    if (sram_last[loc_rptr]) begin
                        last_upd = 1'b1;
                    end
                    loc_cnt += 1;
                    if (loc_rptr == FIFO_DEPTH-1) begin
                        loc_rptr = '0;
                    end
                    else begin
                        loc_rptr += 1;
                    end
                    if (last_upd) begin
                        break;
                    end
                end
                nxt_rptr = loc_rptr;
                dec_cnt = loc_cnt;
                inc_credit = loc_cnt;
            end
        end
    end

    always_comb begin
        crdt_gnt = 1'b0;
        dec_credit = '0;
        if (((crdt_req && |credit) || (crdt_req && |inc_credit)) & (~AVOID_ADDR_COLLIS | ~addr_collis)) begin
            crdt_gnt = EN_CRDT;
            dec_credit = crdt_req_cnt;
        end
    end

    always_comb begin
        if (EN_CRDT) begin
            nxt_credit = credit + inc_credit - dec_credit;
        end 
        else begin
            nxt_credit = '0;
        end
        nxt_cnt = cnt + (int_push ? inc_cnt : '0) - dec_cnt;
    end

    logic  [DNF    -1:0]            nxt_sram_last_dnf, nxt_sram_last;
    always_comb begin
        int i;
        nxt_sram_last_dnf = '0;
        for (i=DNF-1; i >= 0; i -= 1) begin
            if (in_data_en[i]) begin
                nxt_sram_last_dnf[i] = 1'b1;
                break;
            end
        end
    end

    `XLREG_XDMA_EXDES(clk, rst_n) begin
        integer i, j;
        if (~rst_n) begin
            wptr <= '0;
            rptr <= '0;
            credit <= FIFO_DEPTH;
            cnt <= '0;
            sram_last <= '0;
        end
        else begin
            wptr <= nxt_wptr;
            rptr <= nxt_rptr;
            credit <= nxt_credit;
            cnt <= nxt_cnt;
            for (i=0; i < DNF; i += 1) begin
                if (sram_ld[i]) begin
                    sram_last[sram_ix[i]] <= nxt_sram_last[i];
                end
            end
        end
    end

    always_comb begin
        integer i, j;
        nxt_sram_sb_tmp = '0;
        nxt_sram_data_tmp = '0;
        nxt_sram_last = '0;
        sram_ld = 1'b0;
        sram_ix = '0;
        j = 0;
        if (int_push) begin
            if (DNF>1) begin
                j=wptr;
                for (i=0; i < DNF; i += 1) begin
                    if (in_data_en[i]) begin
                        nxt_sram_sb_tmp[i] = in_sb[i];
                        nxt_sram_data_tmp[i] = in_data[OUT_BITS*i +: OUT_BITS];
                        nxt_sram_last[i] = nxt_sram_last_dnf[i];
                        sram_ix[i] = j;
                        sram_ld[i] = 1'b1;
                        if (j == FIFO_DEPTH-1) begin
                            j = 0;
                        end
                        else begin
                            j += 1;
                        end
                    end
                end
            end
            else begin
                nxt_sram_data_tmp[0] = in_data;
                nxt_sram_sb_tmp[0] = in_sb;
                nxt_sram_last[0] = in_data_en;
                sram_ld[0] = 1'b1;
                sram_ix[0] = wptr;
            end
        end
        //out_vld <= nxt_out_vld;
    end

    if (DNF >1) begin :DNF_MODE
        always_comb begin
            integer i;
            nxt_sram_sb = sram_sb;
            nxt_sram = sram;
            for (i=0; i < DNF; i += 1) begin
                if (sram_ld[i]) begin
                    nxt_sram_sb[sram_ix[i]] = nxt_sram_sb_tmp[i];
                    nxt_sram[sram_ix[i]] = nxt_sram_data_tmp[i];
                end
            end
        end
    end
    else begin
        `ifndef SOFT_IP
        always_comb begin
            integer i;
            nxt_sram_sb = sram_sb;
            nxt_sram = sram;
            if (sram_ld[0]) begin
                nxt_sram_sb[wptr] = nxt_sram_sb_tmp[0];
                nxt_sram[wptr] = nxt_sram_data_tmp[0];
            end
        end
        `endif
    end

    `ifndef SOFT_IP
        genvar I;
        for (I=0; I < FIFO_DEPTH; I += 1) begin
            `XSRREG_HARD_CLR_EXDES(clk, rst_n, sram_sb[I], nxt_sram_sb[I])
            `XSRREG_HARD_CLR_EXDES(clk, rst_n, sram[I], nxt_sram[I])
        end
    `else
        if (DNF == 1) begin :NDNF_SRAM_MODE
            always_ff @(posedge clk) begin
                if (sram_ld[0]) begin
                    sram_sb[wptr] <= nxt_sram_sb_tmp[0];
                    sram[wptr] <= nxt_sram_data_tmp[0];
                end
            end
        end
        else begin
            `XSRREG_HARD_CLR_EXDES(clk, rst_n, sram_sb, nxt_sram_sb)
            `XSRREG_HARD_CLR_EXDES(clk, rst_n, sram, nxt_sram)
        end
    `endif

    //Add an assert for FIFO_DEPTH != 2**n in case of DNF >1 or UPF > 1 as the pointer calculation extremely gets complicated
    logic       ptr_eq;
    assign       ptr_eq = (rptr == wptr) ? 1 : 0;
    logic       cnt0;
    assign       cnt0 = (cnt == 0) ? 1 : 0;
    logic       crdt_full;
    assign       crdt_full = (crdt == FIFO_DEPTH) ? 1 : EN_CRDT ? 0: 1;
    logic       ovrflow;
    assign       ovrflow = in_vld && !in_rdy && |EN_CRDT;

endmodule

`endif // FIFO_LUT_SV
