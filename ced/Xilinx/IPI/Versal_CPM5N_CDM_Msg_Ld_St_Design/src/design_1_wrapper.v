//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3606780 Mon Aug  8 12:17:44 MDT 2022
//Date        : Sat Aug 13 19:09:45 2022
//Host        : xsjrdevl155 running 64-bit CentOS Linux release 7.5.1804 (Core)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (PCIE0_GT_0_grx_n,
    PCIE0_GT_0_grx_p,
    PCIE0_GT_0_gtx_n,
    PCIE0_GT_0_gtx_p,
    cdm0_msgld_dat_0_client_id,
    cdm0_msgld_dat_0_data,
    cdm0_msgld_dat_0_ecc,
    cdm0_msgld_dat_0_eop,
    cdm0_msgld_dat_0_err_status,
    cdm0_msgld_dat_0_error,
    cdm0_msgld_dat_0_mty,
    cdm0_msgld_dat_0_rc_id,
    cdm0_msgld_dat_0_rdy,
    cdm0_msgld_dat_0_response_cookie,
    cdm0_msgld_dat_0_start_offset,
    cdm0_msgld_dat_0_status,
    cdm0_msgld_dat_0_vld,
    cdm0_msgld_dat_0_zero_byte,
    cdm0_msgld_req_0_addr,
    cdm0_msgld_req_0_addr_spc,
    cdm0_msgld_req_0_attr,
    cdm0_msgld_req_0_client_id,
    cdm0_msgld_req_0_data_width,
    cdm0_msgld_req_0_if_op,
    cdm0_msgld_req_0_length,
    cdm0_msgld_req_0_op,
    cdm0_msgld_req_0_rc_id,
    cdm0_msgld_req_0_rdy,
    cdm0_msgld_req_0_relaxed_read,
    cdm0_msgld_req_0_response_cookie,
    cdm0_msgld_req_0_start_offset,
    cdm0_msgld_req_0_vld,
    cdm0_msgst_0_addr,
    cdm0_msgst_0_addr_spc,
    cdm0_msgst_0_attr,
    cdm0_msgst_0_client_id,
    cdm0_msgst_0_data,
    cdm0_msgst_0_data_width,
    cdm0_msgst_0_ecc,
    cdm0_msgst_0_eop,
    cdm0_msgst_0_irq_vector,
    cdm0_msgst_0_length,
    cdm0_msgst_0_op,
    cdm0_msgst_0_rdy,
    cdm0_msgst_0_response_cookie,
    cdm0_msgst_0_response_req,
    cdm0_msgst_0_st2m_ordered,
    cdm0_msgst_0_start_offset,
    cdm0_msgst_0_tph,
    cdm0_msgst_0_vld,
    cdm0_msgst_0_wait_pld_pkt_id,
    cdx_bot_rst_n_0,
    cpm_bot_user_clk_0,
    gt_refclk0_0_clk_n,
    gt_refclk0_0_clk_p);

  input [15:0]PCIE0_GT_0_grx_n;
  input [15:0]PCIE0_GT_0_grx_p;
  output [15:0]PCIE0_GT_0_gtx_n;
  output [15:0]PCIE0_GT_0_gtx_p;
  output [3:0]cdm0_msgld_dat_0_client_id;
  output [255:0]cdm0_msgld_dat_0_data;
  output [9:0]cdm0_msgld_dat_0_ecc;
  output cdm0_msgld_dat_0_eop;
  output [2:0]cdm0_msgld_dat_0_err_status;
  output cdm0_msgld_dat_0_error;
  output [4:0]cdm0_msgld_dat_0_mty;
  output [5:0]cdm0_msgld_dat_0_rc_id;
  input cdm0_msgld_dat_0_rdy;
  output [11:0]cdm0_msgld_dat_0_response_cookie;
  output [4:0]cdm0_msgld_dat_0_start_offset;
  output [1:0]cdm0_msgld_dat_0_status;
  output cdm0_msgld_dat_0_vld;
  output cdm0_msgld_dat_0_zero_byte;
  input [65:0]cdm0_msgld_req_0_addr;
  input [53:0]cdm0_msgld_req_0_addr_spc;
  input [2:0]cdm0_msgld_req_0_attr;
  input [3:0]cdm0_msgld_req_0_client_id;
  input cdm0_msgld_req_0_data_width;
  input [1:0]cdm0_msgld_req_0_if_op;
  input [8:0]cdm0_msgld_req_0_length;
  input [1:0]cdm0_msgld_req_0_op;
  input [5:0]cdm0_msgld_req_0_rc_id;
  output cdm0_msgld_req_0_rdy;
  input cdm0_msgld_req_0_relaxed_read;
  input [11:0]cdm0_msgld_req_0_response_cookie;
  input [4:0]cdm0_msgld_req_0_start_offset;
  input cdm0_msgld_req_0_vld;
  input [65:0]cdm0_msgst_0_addr;
  input [53:0]cdm0_msgst_0_addr_spc;
  input [2:0]cdm0_msgst_0_attr;
  input [3:0]cdm0_msgst_0_client_id;
  input [255:0]cdm0_msgst_0_data;
  input [1:0]cdm0_msgst_0_data_width;
  input [10:0]cdm0_msgst_0_ecc;
  input cdm0_msgst_0_eop;
  input [15:0]cdm0_msgst_0_irq_vector;
  input [8:0]cdm0_msgst_0_length;
  input [1:0]cdm0_msgst_0_op;
  output cdm0_msgst_0_rdy;
  input [11:0]cdm0_msgst_0_response_cookie;
  input cdm0_msgst_0_response_req;
  input cdm0_msgst_0_st2m_ordered;
  input [3:0]cdm0_msgst_0_start_offset;
  input [10:0]cdm0_msgst_0_tph;
  input cdm0_msgst_0_vld;
  input [15:0]cdm0_msgst_0_wait_pld_pkt_id;
  input cdx_bot_rst_n_0;
  input cpm_bot_user_clk_0;
  input gt_refclk0_0_clk_n;
  input gt_refclk0_0_clk_p;

  wire [15:0]PCIE0_GT_0_grx_n;
  wire [15:0]PCIE0_GT_0_grx_p;
  wire [15:0]PCIE0_GT_0_gtx_n;
  wire [15:0]PCIE0_GT_0_gtx_p;
  wire [3:0]cdm0_msgld_dat_0_client_id;
  wire [255:0]cdm0_msgld_dat_0_data;
  wire [9:0]cdm0_msgld_dat_0_ecc;
  wire cdm0_msgld_dat_0_eop;
  wire [2:0]cdm0_msgld_dat_0_err_status;
  wire cdm0_msgld_dat_0_error;
  wire [4:0]cdm0_msgld_dat_0_mty;
  wire [5:0]cdm0_msgld_dat_0_rc_id;
  wire cdm0_msgld_dat_0_rdy;
  wire [11:0]cdm0_msgld_dat_0_response_cookie;
  wire [4:0]cdm0_msgld_dat_0_start_offset;
  wire [1:0]cdm0_msgld_dat_0_status;
  wire cdm0_msgld_dat_0_vld;
  wire cdm0_msgld_dat_0_zero_byte;
  wire [65:0]cdm0_msgld_req_0_addr;
  wire [53:0]cdm0_msgld_req_0_addr_spc;
  wire [2:0]cdm0_msgld_req_0_attr;
  wire [3:0]cdm0_msgld_req_0_client_id;
  wire cdm0_msgld_req_0_data_width;
  wire [1:0]cdm0_msgld_req_0_if_op;
  wire [8:0]cdm0_msgld_req_0_length;
  wire [1:0]cdm0_msgld_req_0_op;
  wire [5:0]cdm0_msgld_req_0_rc_id;
  wire cdm0_msgld_req_0_rdy;
  wire cdm0_msgld_req_0_relaxed_read;
  wire [11:0]cdm0_msgld_req_0_response_cookie;
  wire [4:0]cdm0_msgld_req_0_start_offset;
  wire cdm0_msgld_req_0_vld;
  wire [65:0]cdm0_msgst_0_addr;
  wire [53:0]cdm0_msgst_0_addr_spc;
  wire [2:0]cdm0_msgst_0_attr;
  wire [3:0]cdm0_msgst_0_client_id;
  wire [255:0]cdm0_msgst_0_data;
  wire [1:0]cdm0_msgst_0_data_width;
  wire [10:0]cdm0_msgst_0_ecc;
  wire cdm0_msgst_0_eop;
  wire [15:0]cdm0_msgst_0_irq_vector;
  wire [8:0]cdm0_msgst_0_length;
  wire [1:0]cdm0_msgst_0_op;
  wire cdm0_msgst_0_rdy;
  wire [11:0]cdm0_msgst_0_response_cookie;
  wire cdm0_msgst_0_response_req;
  wire cdm0_msgst_0_st2m_ordered;
  wire [3:0]cdm0_msgst_0_start_offset;
  wire [10:0]cdm0_msgst_0_tph;
  wire cdm0_msgst_0_vld;
  wire [15:0]cdm0_msgst_0_wait_pld_pkt_id;
  wire cdx_bot_rst_n_0;
  wire cpm_bot_user_clk_0;
  wire gt_refclk0_0_clk_n;
  wire gt_refclk0_0_clk_p;

  design_1 design_1_i
       (.PCIE0_GT_0_grx_n(PCIE0_GT_0_grx_n),
        .PCIE0_GT_0_grx_p(PCIE0_GT_0_grx_p),
        .PCIE0_GT_0_gtx_n(PCIE0_GT_0_gtx_n),
        .PCIE0_GT_0_gtx_p(PCIE0_GT_0_gtx_p),
        .cdm0_msgld_dat_0_client_id(cdm0_msgld_dat_0_client_id),
        .cdm0_msgld_dat_0_data(cdm0_msgld_dat_0_data),
        .cdm0_msgld_dat_0_ecc(cdm0_msgld_dat_0_ecc),
        .cdm0_msgld_dat_0_eop(cdm0_msgld_dat_0_eop),
        .cdm0_msgld_dat_0_err_status(cdm0_msgld_dat_0_err_status),
        .cdm0_msgld_dat_0_error(cdm0_msgld_dat_0_error),
        .cdm0_msgld_dat_0_mty(cdm0_msgld_dat_0_mty),
        .cdm0_msgld_dat_0_rc_id(cdm0_msgld_dat_0_rc_id),
        .cdm0_msgld_dat_0_rdy(cdm0_msgld_dat_0_rdy),
        .cdm0_msgld_dat_0_response_cookie(cdm0_msgld_dat_0_response_cookie),
        .cdm0_msgld_dat_0_start_offset(cdm0_msgld_dat_0_start_offset),
        .cdm0_msgld_dat_0_status(cdm0_msgld_dat_0_status),
        .cdm0_msgld_dat_0_vld(cdm0_msgld_dat_0_vld),
        .cdm0_msgld_dat_0_zero_byte(cdm0_msgld_dat_0_zero_byte),
        .cdm0_msgld_req_0_addr(cdm0_msgld_req_0_addr),
        .cdm0_msgld_req_0_addr_spc(cdm0_msgld_req_0_addr_spc),
        .cdm0_msgld_req_0_attr(cdm0_msgld_req_0_attr),
        .cdm0_msgld_req_0_client_id(cdm0_msgld_req_0_client_id),
        .cdm0_msgld_req_0_data_width(cdm0_msgld_req_0_data_width),
        .cdm0_msgld_req_0_if_op(cdm0_msgld_req_0_if_op),
        .cdm0_msgld_req_0_length(cdm0_msgld_req_0_length),
        .cdm0_msgld_req_0_op(cdm0_msgld_req_0_op),
        .cdm0_msgld_req_0_rc_id(cdm0_msgld_req_0_rc_id),
        .cdm0_msgld_req_0_rdy(cdm0_msgld_req_0_rdy),
        .cdm0_msgld_req_0_relaxed_read(cdm0_msgld_req_0_relaxed_read),
        .cdm0_msgld_req_0_response_cookie(cdm0_msgld_req_0_response_cookie),
        .cdm0_msgld_req_0_start_offset(cdm0_msgld_req_0_start_offset),
        .cdm0_msgld_req_0_vld(cdm0_msgld_req_0_vld),
        .cdm0_msgst_0_addr(cdm0_msgst_0_addr),
        .cdm0_msgst_0_addr_spc(cdm0_msgst_0_addr_spc),
        .cdm0_msgst_0_attr(cdm0_msgst_0_attr),
        .cdm0_msgst_0_client_id(cdm0_msgst_0_client_id),
        .cdm0_msgst_0_data(cdm0_msgst_0_data),
        .cdm0_msgst_0_data_width(cdm0_msgst_0_data_width),
        .cdm0_msgst_0_ecc(cdm0_msgst_0_ecc),
        .cdm0_msgst_0_eop(cdm0_msgst_0_eop),
        .cdm0_msgst_0_irq_vector(cdm0_msgst_0_irq_vector),
        .cdm0_msgst_0_length(cdm0_msgst_0_length),
        .cdm0_msgst_0_op(cdm0_msgst_0_op),
        .cdm0_msgst_0_rdy(cdm0_msgst_0_rdy),
        .cdm0_msgst_0_response_cookie(cdm0_msgst_0_response_cookie),
        .cdm0_msgst_0_response_req(cdm0_msgst_0_response_req),
        .cdm0_msgst_0_st2m_ordered(cdm0_msgst_0_st2m_ordered),
        .cdm0_msgst_0_start_offset(cdm0_msgst_0_start_offset),
        .cdm0_msgst_0_tph(cdm0_msgst_0_tph),
        .cdm0_msgst_0_vld(cdm0_msgst_0_vld),
        .cdm0_msgst_0_wait_pld_pkt_id(cdm0_msgst_0_wait_pld_pkt_id),
        .cdx_bot_rst_n_0(cdx_bot_rst_n_0),
        .cpm_bot_user_clk_0(cpm_bot_user_clk_0),
        .gt_refclk0_0_clk_n(gt_refclk0_0_clk_n),
        .gt_refclk0_0_clk_p(gt_refclk0_0_clk_p));
endmodule
