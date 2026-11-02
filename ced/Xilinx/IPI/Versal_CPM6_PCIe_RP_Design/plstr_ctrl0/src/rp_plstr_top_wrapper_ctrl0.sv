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

`timescale 1 ps / 1 ps

import rp_link_pkg::*;

// CTRL0 wrapper: uses CTRL0 GT/refclk and pcie0/pl_axil_dbi0 signal set.
module rp_plstr_top_wrapper_ctrl0 (

    input [LINK_WIDTH-1:0]CTRL0_GT_0_grx_n,
    input [LINK_WIDTH-1:0]CTRL0_GT_0_grx_p,
    output [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_n,
    output [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_p,
    input ctrl0_gt_refclk_0_clk_n,
    input ctrl0_gt_refclk_0_clk_p/*,
//    input dbi0_clk_0,
    output dbi0_rstn_0,
//    input pcie0_clk_0,
    output pcie0_rstn_0,
    output pl0_ref_clk,
    output pl0_resetn_0*/
);

    // wire dbi0_clk_0;
    // wire dbi0_rstn_0;
    (* MARK_DEBUG = "TRUE" *) wire [5:0]pcie0_cfg_status_0_cfg_neg_link_width;
    (* MARK_DEBUG = "TRUE" *) wire [2:0]pcie0_cfg_status_0_pf_func_num;
    (* MARK_DEBUG = "TRUE" *) wire [15:0]pcie0_cfg_status_0_pf_info;
    (* MARK_DEBUG = "TRUE" *) wire pcie0_cfg_status_0_pf_sos;
    (* MARK_DEBUG = "TRUE" *) wire pcie0_cfg_status_0_pf_vld;
    (* MARK_DEBUG = "TRUE" *) wire pcie0_cfg_status_0_rdlh_link_up;
    (* MARK_DEBUG = "TRUE" *) wire pcie0_cfg_status_0_smlh_link_up;
    (* MARK_DEBUG = "TRUE" *) wire [5:0]pcie0_cfg_status_0_smlh_ltssm_state;
    wire [7:0]pcie0_cfg_status_0_vf_func_num;
    wire [15:0]pcie0_cfg_status_0_vf_info;
    wire pcie0_cfg_status_0_vf_sos;
    wire pcie0_cfg_status_0_vf_vld;
    // wire pcie0_clk_0;
    // wire pcie0_rstn_0;
    wire [15:0]pcie0_strm_0_cpld_cdts;
    wire [11:0]pcie0_strm_0_cplh_cdts;
    wire [15:0]pcie0_strm_0_npd_cdts;
    wire [11:0]pcie0_strm_0_nph_cdts;
    wire [15:0]pcie0_strm_0_pd_cdts;
    wire [11:0]pcie0_strm_0_ph_cdts;
    wire [2:0]pcie0_strm_0_rx_credit;
    wire pcie0_strm_0_rx_credit_ready;
    wire pcie0_strm_0_rx_credit_valid;
    wire [2645:0]pcie0_strm_0_rx_data;
    wire [2:0]pcie0_strm_0_rx_end;
    wire [5:0]pcie0_strm_0_rx_end0_ptr;
    wire [5:0]pcie0_strm_0_rx_end1_ptr;
    wire [5:0]pcie0_strm_0_rx_end2_ptr;
    wire [8:0]pcie0_strm_0_rx_end_error;
    wire [44:0]pcie0_strm_0_rx_parity;
    // rx_slot*_np_valid: tied off
    wire [2:0]pcie0_strm_0_rx_slot0_np_valid = 3'b0;
    wire [1:0]pcie0_strm_0_rx_slot0_type;
    wire [2:0]pcie0_strm_0_rx_slot1_np_valid = 3'b0;
    wire [1:0]pcie0_strm_0_rx_slot1_type;
    wire [2:0]pcie0_strm_0_rx_slot2_np_valid = 3'b0;
    wire [1:0]pcie0_strm_0_rx_slot2_type;
    wire [2:0]pcie0_strm_0_rx_start;
    wire [1:0]pcie0_strm_0_rx_start0_ptr;
    wire [1:0]pcie0_strm_0_rx_start1_ptr;
    wire [1:0]pcie0_strm_0_rx_start2_ptr;
    (* mark_debug = "true", keep = "true" *) wire pcie0_strm_0_rx_valid;
    wire [2:0]pcie0_strm_0_tx_credit;
    wire pcie0_strm_0_tx_credit_ready;
    wire pcie0_strm_0_tx_credit_valid;
    wire [2555:0]pcie0_strm_0_tx_data;
    wire [2:0]pcie0_strm_0_tx_end;
    wire [5:0]pcie0_strm_0_tx_end0_ptr;
    wire [5:0]pcie0_strm_0_tx_end1_ptr;
    wire [5:0]pcie0_strm_0_tx_end2_ptr;
    wire [8:0]pcie0_strm_0_tx_end_error;
    wire [43:0]pcie0_strm_0_tx_parity;
    wire [2:0]pcie0_strm_0_tx_slot0_np_valid;
    wire [1:0]pcie0_strm_0_tx_slot0_type;
    wire [2:0]pcie0_strm_0_tx_slot1_np_valid;
    wire [1:0]pcie0_strm_0_tx_slot1_type;
    wire [2:0]pcie0_strm_0_tx_slot2_np_valid;
    wire [1:0]pcie0_strm_0_tx_slot2_type;
    wire [2:0]pcie0_strm_0_tx_start;
    wire [1:0]pcie0_strm_0_tx_start0_ptr;
    wire [1:0]pcie0_strm_0_tx_start1_ptr;
    wire [1:0]pcie0_strm_0_tx_start2_ptr;
    (* mark_debug = "true", keep = "true" *) wire pcie0_strm_0_tx_valid;
    wire [31:0]pl_axil_dbi0_0_araddr;
    wire [2:0]pl_axil_dbi0_0_arprot;
    wire pl_axil_dbi0_0_arready;
    wire [15:0]pl_axil_dbi0_0_aruser;
    wire pl_axil_dbi0_0_arvalid;
    wire [31:0]pl_axil_dbi0_0_awaddr;
    wire [2:0]pl_axil_dbi0_0_awprot;
    wire pl_axil_dbi0_0_awready;
    wire [15:0]pl_axil_dbi0_0_awuser;
    wire pl_axil_dbi0_0_awvalid;
    wire pl_axil_dbi0_0_bready;
    wire [1:0]pl_axil_dbi0_0_bresp;
    wire [5:0]pl_axil_dbi0_0_buser;
    wire pl_axil_dbi0_0_bvalid;
    wire [31:0]pl_axil_dbi0_0_rdata;
    wire pl_axil_dbi0_0_rready;
    wire [1:0]pl_axil_dbi0_0_rresp;
    wire [3:0]pl_axil_dbi0_0_ruser;
    wire pl_axil_dbi0_0_rvalid;
    wire [31:0]pl_axil_dbi0_0_wdata;
    wire pl_axil_dbi0_0_wready;
    wire [3:0]pl_axil_dbi0_0_wstrb;
    wire [3:0]pl_axil_dbi0_0_wuser;
    wire pl_axil_dbi0_0_wvalid; 
//    wire pl0_resetn_0;
   (* MARK_DEBUG = "TRUE" *) wire pl0_ref_clk;

    reg [7:0] link_down_bus;

    // LTSSM history: ltssm0_reg0 newest, reg1/reg2 the previous two.
    // store_ltssm0 is high for one cycle on each state change.
    (* mark_debug = "true", keep = "true" *) wire       store_ltssm0;
    (* mark_debug = "true", keep = "true" *) reg [5:0]  ltssm0_reg0 = 6'b0;
    (* mark_debug = "true", keep = "true" *) reg [5:0]  ltssm0_reg1 = 6'b0;
    (* mark_debug = "true", keep = "true" *) reg [5:0]  ltssm0_reg2 = 6'b0;

    // config_mem_handler enumeration/traffic state (IDLE .. TRAFFIC_GEN .. DONE).
    (* mark_debug = "true", keep = "true" *) wire [3:0] cmh0_state;

    assign store_ltssm0 = (ltssm0_reg0 != ltssm0_reg1);

    always @(posedge pl0_ref_clk) begin
        ltssm0_reg0 <= pcie0_cfg_status_0_smlh_ltssm_state;
        ltssm0_reg1 <= ltssm0_reg0;
        ltssm0_reg2 <= ltssm0_reg1;
    end

    design_1_wrapper design_1_wrapper_inst (
        .CTRL0_GT_0_grx_n(CTRL0_GT_0_grx_n),
        .CTRL0_GT_0_grx_p(    CTRL0_GT_0_grx_p),
        .CTRL0_GT_0_gtx_n(    CTRL0_GT_0_gtx_n),
        .CTRL0_GT_0_gtx_p(    CTRL0_GT_0_gtx_p),
        .ctrl0_gt_refclk_0_clk_n(    ctrl0_gt_refclk_0_clk_n),
        .ctrl0_gt_refclk_0_clk_p(    ctrl0_gt_refclk_0_clk_p),
//        .dbi0_clk_0(    dbi0_clk_0),
        .dbi0_rstn_0(    dbi0_rstn_0),
        .pcie0_cfg_status_0_cfg_neg_link_width(    pcie0_cfg_status_0_cfg_neg_link_width),
        .pcie0_cfg_status_0_pf_func_num(    pcie0_cfg_status_0_pf_func_num),
        .pcie0_cfg_status_0_pf_info(    pcie0_cfg_status_0_pf_info),
        .pcie0_cfg_status_0_pf_sos(    pcie0_cfg_status_0_pf_sos),
        .pcie0_cfg_status_0_pf_vld(    pcie0_cfg_status_0_pf_vld),
        .pcie0_cfg_status_0_rdlh_link_up(    pcie0_cfg_status_0_rdlh_link_up),
        .pcie0_cfg_status_0_smlh_link_up(    pcie0_cfg_status_0_smlh_link_up),
        .pcie0_cfg_status_0_smlh_ltssm_state(    pcie0_cfg_status_0_smlh_ltssm_state),
        .pcie0_cfg_status_0_vf_func_num(    pcie0_cfg_status_0_vf_func_num),
        .pcie0_cfg_status_0_vf_info(    pcie0_cfg_status_0_vf_info),
        .pcie0_cfg_status_0_vf_sos(    pcie0_cfg_status_0_vf_sos),
        .pcie0_cfg_status_0_vf_vld(    pcie0_cfg_status_0_vf_vld),
//        .pcie0_clk_0(    pcie0_clk_0),
        .pcie0_rstn_0(    pcie0_rstn_0),
        .pcie0_strm_0_cpld_cdts(    pcie0_strm_0_cpld_cdts),
        .pcie0_strm_0_cplh_cdts(    pcie0_strm_0_cplh_cdts),
        .pcie0_strm_0_npd_cdts(    pcie0_strm_0_npd_cdts),
        .pcie0_strm_0_nph_cdts(    pcie0_strm_0_nph_cdts),
        .pcie0_strm_0_pd_cdts(    pcie0_strm_0_pd_cdts),
        .pcie0_strm_0_ph_cdts(    pcie0_strm_0_ph_cdts),
        .pcie0_strm_0_rx_credit(    pcie0_strm_0_rx_credit),
        .pcie0_strm_0_rx_credit_ready(    pcie0_strm_0_rx_credit_ready),
        .pcie0_strm_0_rx_credit_valid(    pcie0_strm_0_rx_credit_valid),
        .pcie0_strm_0_rx_data(    pcie0_strm_0_rx_data),
        .pcie0_strm_0_rx_end(    pcie0_strm_0_rx_end),
        .pcie0_strm_0_rx_end0_ptr(    pcie0_strm_0_rx_end0_ptr),
        .pcie0_strm_0_rx_end1_ptr(    pcie0_strm_0_rx_end1_ptr),
        .pcie0_strm_0_rx_end2_ptr(    pcie0_strm_0_rx_end2_ptr),
        .pcie0_strm_0_rx_end_error(    pcie0_strm_0_rx_end_error),
        .pcie0_strm_0_rx_parity(    pcie0_strm_0_rx_parity),
        // rx_slot*_np_valid: tied off
        .pcie0_strm_0_rx_slot0_type(    pcie0_strm_0_rx_slot0_type),
        .pcie0_strm_0_rx_slot1_type(    pcie0_strm_0_rx_slot1_type),
        .pcie0_strm_0_rx_slot2_type(    pcie0_strm_0_rx_slot2_type),
        .pcie0_strm_0_rx_start(    pcie0_strm_0_rx_start),
        .pcie0_strm_0_rx_start0_ptr(    pcie0_strm_0_rx_start0_ptr),
        .pcie0_strm_0_rx_start1_ptr(    pcie0_strm_0_rx_start1_ptr),
        .pcie0_strm_0_rx_start2_ptr(    pcie0_strm_0_rx_start2_ptr),
        .pcie0_strm_0_rx_valid(    pcie0_strm_0_rx_valid),
        .pcie0_strm_0_tx_credit(    pcie0_strm_0_tx_credit),
        .pcie0_strm_0_tx_credit_ready(    pcie0_strm_0_tx_credit_ready),
        .pcie0_strm_0_tx_credit_valid(    pcie0_strm_0_tx_credit_valid),
        .pcie0_strm_0_tx_data(    pcie0_strm_0_tx_data),
        .pcie0_strm_0_tx_end(    pcie0_strm_0_tx_end),
        .pcie0_strm_0_tx_end0_ptr(    pcie0_strm_0_tx_end0_ptr),
        .pcie0_strm_0_tx_end1_ptr(    pcie0_strm_0_tx_end1_ptr),
        .pcie0_strm_0_tx_end2_ptr(    pcie0_strm_0_tx_end2_ptr),
        .pcie0_strm_0_tx_end_error(    pcie0_strm_0_tx_end_error),
        .pcie0_strm_0_tx_parity(    pcie0_strm_0_tx_parity),
        .pcie0_strm_0_tx_slot0_np_valid(    pcie0_strm_0_tx_slot0_np_valid),
        .pcie0_strm_0_tx_slot0_type(    pcie0_strm_0_tx_slot0_type),
        .pcie0_strm_0_tx_slot1_np_valid(    pcie0_strm_0_tx_slot1_np_valid),
        .pcie0_strm_0_tx_slot1_type(    pcie0_strm_0_tx_slot1_type),
        .pcie0_strm_0_tx_slot2_np_valid(    pcie0_strm_0_tx_slot2_np_valid),
        .pcie0_strm_0_tx_slot2_type(    pcie0_strm_0_tx_slot2_type),
        .pcie0_strm_0_tx_start(    pcie0_strm_0_tx_start),
        .pcie0_strm_0_tx_start0_ptr(    pcie0_strm_0_tx_start0_ptr),
        .pcie0_strm_0_tx_start1_ptr(    pcie0_strm_0_tx_start1_ptr),
        .pcie0_strm_0_tx_start2_ptr(    pcie0_strm_0_tx_start2_ptr),
        .pcie0_strm_0_tx_valid(    pcie0_strm_0_tx_valid),
        .pl_axil_dbi0_0_araddr(    pl_axil_dbi0_0_araddr),
        .pl_axil_dbi0_0_arprot(    pl_axil_dbi0_0_arprot),
        .pl_axil_dbi0_0_arready(    pl_axil_dbi0_0_arready),
        .pl_axil_dbi0_0_aruser(    pl_axil_dbi0_0_aruser),
        .pl_axil_dbi0_0_arvalid(    pl_axil_dbi0_0_arvalid),
        .pl_axil_dbi0_0_awaddr(    pl_axil_dbi0_0_awaddr),
        .pl_axil_dbi0_0_awprot(    pl_axil_dbi0_0_awprot),
        .pl_axil_dbi0_0_awready(    pl_axil_dbi0_0_awready),
        .pl_axil_dbi0_0_awuser(    pl_axil_dbi0_0_awuser),
        .pl_axil_dbi0_0_awvalid(    pl_axil_dbi0_0_awvalid),
        .pl_axil_dbi0_0_bready(    pl_axil_dbi0_0_bready),
        .pl_axil_dbi0_0_bresp(    pl_axil_dbi0_0_bresp),
        .pl_axil_dbi0_0_buser(    pl_axil_dbi0_0_buser),
        .pl_axil_dbi0_0_bvalid(    pl_axil_dbi0_0_bvalid),
        .pl_axil_dbi0_0_rdata(    pl_axil_dbi0_0_rdata),
        .pl_axil_dbi0_0_rready(    pl_axil_dbi0_0_rready),
        .pl_axil_dbi0_0_rresp(    pl_axil_dbi0_0_rresp),
        .pl_axil_dbi0_0_ruser(    pl_axil_dbi0_0_ruser),
        .pl_axil_dbi0_0_rvalid(    pl_axil_dbi0_0_rvalid),
        .pl_axil_dbi0_0_wdata(    pl_axil_dbi0_0_wdata),
        .pl_axil_dbi0_0_wready(    pl_axil_dbi0_0_wready),
        .pl_axil_dbi0_0_wstrb(    pl_axil_dbi0_0_wstrb),
        .pl_axil_dbi0_0_wuser(    pl_axil_dbi0_0_wuser),
        .pl_axil_dbi0_0_wvalid(    pl_axil_dbi0_0_wvalid),
        .pl0_ref_clk( pl0_ref_clk),
        .pl0_resetn_0(  pl0_resetn_0)

    );
    
    rp_top rp_top_inst (
        .clk(pl0_ref_clk),
        .rst_n(pl0_resetn_0),
        .link_down(link_down_bus),
        .rx_valid(pcie0_strm_0_rx_valid),
        .rx_data(pcie0_strm_0_rx_data),
        .rx_parity(pcie0_strm_0_rx_parity),
        .rx_start(pcie0_strm_0_rx_start),
        .rx_start0ptr(pcie0_strm_0_rx_start0_ptr),
        .rx_start1ptr(pcie0_strm_0_rx_start1_ptr),
        .rx_start2ptr(pcie0_strm_0_rx_start2_ptr),
        .rx_start0type(pcie0_strm_0_rx_slot0_type),
        .rx_start1type(pcie0_strm_0_rx_slot1_type),
        .rx_start2type(pcie0_strm_0_rx_slot2_type),
        .rx_start0npinfo(pcie0_strm_0_rx_slot0_np_valid),
        .rx_start1npinfo(pcie0_strm_0_rx_slot1_np_valid),
        .rx_start2npinfo(pcie0_strm_0_rx_slot2_np_valid),
        .rx_end(pcie0_strm_0_rx_end),
        .rx_end0ptr(pcie0_strm_0_rx_end0_ptr),
        .rx_end1ptr(pcie0_strm_0_rx_end1_ptr),
        .rx_end2ptr(pcie0_strm_0_rx_end2_ptr),
        .rx_end_err(pcie0_strm_0_rx_end_error),
        .tx_credit_valid(pcie0_strm_0_tx_credit_valid),
        .tx_credit(pcie0_strm_0_tx_credit),
        .tx_credit_active(pcie0_strm_0_tx_credit_ready),
        .rx_credit_valid(pcie0_strm_0_rx_credit_valid),
        .rx_credit(pcie0_strm_0_rx_credit),
        .rx_credit_active(pcie0_strm_0_rx_credit_ready),
        .tx_valid(pcie0_strm_0_tx_valid),
        .tx_data(pcie0_strm_0_tx_data),
        .tx_parity(pcie0_strm_0_tx_parity),
        .tx_start(pcie0_strm_0_tx_start),
        .tx_start0ptr(pcie0_strm_0_tx_start0_ptr),
        .tx_start1ptr(pcie0_strm_0_tx_start1_ptr),
        .tx_start2ptr(pcie0_strm_0_tx_start2_ptr),
        .tx_start0type(pcie0_strm_0_tx_slot0_type),
        .tx_start1type(pcie0_strm_0_tx_slot1_type),
        .tx_start2type(pcie0_strm_0_tx_slot2_type),
        .tx_start0npinfo(pcie0_strm_0_tx_slot0_np_valid),
        .tx_start1npinfo(pcie0_strm_0_tx_slot1_np_valid),
        .tx_start2npinfo(pcie0_strm_0_tx_slot2_np_valid),
        .tx_end(pcie0_strm_0_tx_end),
        .tx_end0ptr(pcie0_strm_0_tx_end0_ptr),
        .tx_end1ptr(pcie0_strm_0_tx_end1_ptr),
        .tx_end2ptr(pcie0_strm_0_tx_end2_ptr),
        .tx_end_error(pcie0_strm_0_tx_end_error),
        .pf_cfg_status_pvld(pcie0_cfg_status_0_pf_vld),
        .pf_cfg_status_info(pcie0_cfg_status_0_pf_info),
        .pf_cfg_status_sos(pcie0_cfg_status_0_pf_sos),
        .pf_cfg_status_func_num(pcie0_cfg_status_0_pf_func_num),
        .vf_cfg_status_pvld(pcie0_cfg_status_0_vf_vld),
        .vf_cfg_status_info(pcie0_cfg_status_0_vf_info),
        .vf_cfg_status_sos(pcie0_cfg_status_0_vf_sos),
        .vf_cfg_status_func_num(pcie0_cfg_status_0_vf_func_num),
        .pl_dbi_axil_if_awaddr(pl_axil_dbi0_0_awaddr),
        .pl_dbi_axil_if_awready(pl_axil_dbi0_0_awready),
        .pl_dbi_axil_if_awvalid(pl_axil_dbi0_0_awvalid),
        .pl_dbi_axil_if_awuser(pl_axil_dbi0_0_awuser),
        .pl_dbi_axil_if_awprot(pl_axil_dbi0_0_awprot),
        .pl_dbi_axil_if_araddr(pl_axil_dbi0_0_araddr),
        .pl_dbi_axil_if_arready(pl_axil_dbi0_0_arready),
        .pl_dbi_axil_if_arvalid(pl_axil_dbi0_0_arvalid),
        .pl_dbi_axil_if_aruser(pl_axil_dbi0_0_aruser),
        .pl_dbi_axil_if_arprot(pl_axil_dbi0_0_arprot),
        .pl_dbi_axil_if_wdata(pl_axil_dbi0_0_wdata),
        .pl_dbi_axil_if_wuser(pl_axil_dbi0_0_wuser),
        .pl_dbi_axil_if_wstrb(pl_axil_dbi0_0_wstrb),
        .pl_dbi_axil_if_wready(pl_axil_dbi0_0_wready),
        .pl_dbi_axil_if_wvalid(pl_axil_dbi0_0_wvalid),
        .pl_dbi_axil_if_rdata(pl_axil_dbi0_0_rdata),
        .pl_dbi_axil_if_rresp(pl_axil_dbi0_0_rresp),
        .pl_dbi_axil_if_ruser(pl_axil_dbi0_0_ruser),
        .pl_dbi_axil_if_rready(pl_axil_dbi0_0_rready),
        .pl_dbi_axil_if_rvalid(pl_axil_dbi0_0_rvalid),
        .pl_dbi_axil_if_bresp(pl_axil_dbi0_0_bresp),
        .pl_dbi_axil_if_buser(pl_axil_dbi0_0_buser),
        .pl_dbi_axil_if_bready(pl_axil_dbi0_0_bready),
        .pl_dbi_axil_if_bvalid(pl_axil_dbi0_0_bvalid),
        .dbg_state(cmh0_state)
    );


    always @(posedge pl0_ref_clk or negedge pl0_resetn_0 ) begin
        if(!pl0_resetn_0) begin
            link_down_bus[7:0] <= 8'hff;
        end
        else begin
            link_down_bus[7:0] <= {8{~pcie0_cfg_status_0_rdlh_link_up | ~pcie0_cfg_status_0_smlh_link_up}};
        end
    end
endmodule
