//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.2.1 (lin64) Build 3414424 Sun Dec 19 10:57:14 MST 2021
//Date        : Fri Jun 10 08:52:10 2022
//Host        : xsjrdevl154 running 64-bit CentOS Linux release 7.5.1804 (Core)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (CH0_LPDDR4_0_0_ca_a,
    CH0_LPDDR4_0_0_ca_b,
    CH0_LPDDR4_0_0_ck_c_a,
    CH0_LPDDR4_0_0_ck_c_b,
    CH0_LPDDR4_0_0_ck_t_a,
    CH0_LPDDR4_0_0_ck_t_b,
    CH0_LPDDR4_0_0_cke_a,
    CH0_LPDDR4_0_0_cke_b,
    CH0_LPDDR4_0_0_cs_a,
    CH0_LPDDR4_0_0_cs_b,
    CH0_LPDDR4_0_0_dmi_a,
    CH0_LPDDR4_0_0_dmi_b,
    CH0_LPDDR4_0_0_dq_a,
    CH0_LPDDR4_0_0_dq_b,
    CH0_LPDDR4_0_0_dqs_c_a,
    CH0_LPDDR4_0_0_dqs_c_b,
    CH0_LPDDR4_0_0_dqs_t_a,
    CH0_LPDDR4_0_0_dqs_t_b,
    CH0_LPDDR4_0_0_reset_n,
    CH0_LPDDR4_0_1_ca_a,
    CH0_LPDDR4_0_1_ca_b,
    CH0_LPDDR4_0_1_ck_c_a,
    CH0_LPDDR4_0_1_ck_c_b,
    CH0_LPDDR4_0_1_ck_t_a,
    CH0_LPDDR4_0_1_ck_t_b,
    CH0_LPDDR4_0_1_cke_a,
    CH0_LPDDR4_0_1_cke_b,
    CH0_LPDDR4_0_1_cs_a,
    CH0_LPDDR4_0_1_cs_b,
    CH0_LPDDR4_0_1_dmi_a,
    CH0_LPDDR4_0_1_dmi_b,
    CH0_LPDDR4_0_1_dq_a,
    CH0_LPDDR4_0_1_dq_b,
    CH0_LPDDR4_0_1_dqs_c_a,
    CH0_LPDDR4_0_1_dqs_c_b,
    CH0_LPDDR4_0_1_dqs_t_a,
    CH0_LPDDR4_0_1_dqs_t_b,
    CH0_LPDDR4_0_1_reset_n,
    CH0_LPDDR4_0_2_ca_a,
    CH0_LPDDR4_0_2_ca_b,
    CH0_LPDDR4_0_2_ck_c_a,
    CH0_LPDDR4_0_2_ck_c_b,
    CH0_LPDDR4_0_2_ck_t_a,
    CH0_LPDDR4_0_2_ck_t_b,
    CH0_LPDDR4_0_2_cke_a,
    CH0_LPDDR4_0_2_cke_b,
    CH0_LPDDR4_0_2_cs_a,
    CH0_LPDDR4_0_2_cs_b,
    CH0_LPDDR4_0_2_dmi_a,
    CH0_LPDDR4_0_2_dmi_b,
    CH0_LPDDR4_0_2_dq_a,
    CH0_LPDDR4_0_2_dq_b,
    CH0_LPDDR4_0_2_dqs_c_a,
    CH0_LPDDR4_0_2_dqs_c_b,
    CH0_LPDDR4_0_2_dqs_t_a,
    CH0_LPDDR4_0_2_dqs_t_b,
    CH0_LPDDR4_0_2_reset_n,
    CH1_LPDDR4_0_0_ca_a,
    CH1_LPDDR4_0_0_ca_b,
    CH1_LPDDR4_0_0_ck_c_a,
    CH1_LPDDR4_0_0_ck_c_b,
    CH1_LPDDR4_0_0_ck_t_a,
    CH1_LPDDR4_0_0_ck_t_b,
    CH1_LPDDR4_0_0_cke_a,
    CH1_LPDDR4_0_0_cke_b,
    CH1_LPDDR4_0_0_cs_a,
    CH1_LPDDR4_0_0_cs_b,
    CH1_LPDDR4_0_0_dmi_a,
    CH1_LPDDR4_0_0_dmi_b,
    CH1_LPDDR4_0_0_dq_a,
    CH1_LPDDR4_0_0_dq_b,
    CH1_LPDDR4_0_0_dqs_c_a,
    CH1_LPDDR4_0_0_dqs_c_b,
    CH1_LPDDR4_0_0_dqs_t_a,
    CH1_LPDDR4_0_0_dqs_t_b,
    CH1_LPDDR4_0_0_reset_n,
    CH1_LPDDR4_0_1_ca_a,
    CH1_LPDDR4_0_1_ca_b,
    CH1_LPDDR4_0_1_ck_c_a,
    CH1_LPDDR4_0_1_ck_c_b,
    CH1_LPDDR4_0_1_ck_t_a,
    CH1_LPDDR4_0_1_ck_t_b,
    CH1_LPDDR4_0_1_cke_a,
    CH1_LPDDR4_0_1_cke_b,
    CH1_LPDDR4_0_1_cs_a,
    CH1_LPDDR4_0_1_cs_b,
    CH1_LPDDR4_0_1_dmi_a,
    CH1_LPDDR4_0_1_dmi_b,
    CH1_LPDDR4_0_1_dq_a,
    CH1_LPDDR4_0_1_dq_b,
    CH1_LPDDR4_0_1_dqs_c_a,
    CH1_LPDDR4_0_1_dqs_c_b,
    CH1_LPDDR4_0_1_dqs_t_a,
    CH1_LPDDR4_0_1_dqs_t_b,
    CH1_LPDDR4_0_1_reset_n,
    CH1_LPDDR4_0_2_ca_a,
    CH1_LPDDR4_0_2_ca_b,
    CH1_LPDDR4_0_2_ck_c_a,
    CH1_LPDDR4_0_2_ck_c_b,
    CH1_LPDDR4_0_2_ck_t_a,
    CH1_LPDDR4_0_2_ck_t_b,
    CH1_LPDDR4_0_2_cke_a,
    CH1_LPDDR4_0_2_cke_b,
    CH1_LPDDR4_0_2_cs_a,
    CH1_LPDDR4_0_2_cs_b,
    CH1_LPDDR4_0_2_dmi_a,
    CH1_LPDDR4_0_2_dmi_b,
    CH1_LPDDR4_0_2_dq_a,
    CH1_LPDDR4_0_2_dq_b,
    CH1_LPDDR4_0_2_dqs_c_a,
    CH1_LPDDR4_0_2_dqs_c_b,
    CH1_LPDDR4_0_2_dqs_t_a,
    CH1_LPDDR4_0_2_dqs_t_b,
    CH1_LPDDR4_0_2_reset_n,
    PCIE1_GT_0_grx_n,
    PCIE1_GT_0_grx_p,
    PCIE1_GT_0_gtx_n,
    PCIE1_GT_0_gtx_p,
//    arb_force,
//    arb_force_dir,
//    arb_priority,
//    batch_num,
//    dma1_axi_aresetn_0,
//    dma1_dsc_crdt_in_0_crdt,
//    dma1_dsc_crdt_in_0_dir,
//    dma1_dsc_crdt_in_0_fence,
//    dma1_dsc_crdt_in_0_qid,
//    dma1_dsc_crdt_in_0_rdy,
//    dma1_dsc_crdt_in_0_valid,
//    dma1_tm_dsc_sts_0_avl,
//    dma1_tm_dsc_sts_0_byp,
//    dma1_tm_dsc_sts_0_dir,
//    dma1_tm_dsc_sts_0_error,
//    dma1_tm_dsc_sts_0_irq_arm,
//    dma1_tm_dsc_sts_0_mm,
//    dma1_tm_dsc_sts_0_pidx,
//    dma1_tm_dsc_sts_0_port_id,
//    dma1_tm_dsc_sts_0_qen,
//    dma1_tm_dsc_sts_0_qid,
//    dma1_tm_dsc_sts_0_qinv,
//    dma1_tm_dsc_sts_0_rdy,
//    dma1_tm_dsc_sts_0_valid,
    gt_refclk1_0_clk_n,
    gt_refclk1_0_clk_p,
//    pl0_ref_clk_0,
//    port_limit,
    sys_clk0_0_clk_n,
    sys_clk0_0_clk_p,
    sys_clk0_1_clk_n,
    sys_clk0_1_clk_p,
    sys_clk0_2_clk_n,
    sys_clk0_2_clk_p);
  output [5:0]CH0_LPDDR4_0_0_ca_a;
  output [5:0]CH0_LPDDR4_0_0_ca_b;
  output [0:0]CH0_LPDDR4_0_0_ck_c_a;
  output [0:0]CH0_LPDDR4_0_0_ck_c_b;
  output [0:0]CH0_LPDDR4_0_0_ck_t_a;
  output [0:0]CH0_LPDDR4_0_0_ck_t_b;
  output [0:0]CH0_LPDDR4_0_0_cke_a;
  output [0:0]CH0_LPDDR4_0_0_cke_b;
  output [0:0]CH0_LPDDR4_0_0_cs_a;
  output [0:0]CH0_LPDDR4_0_0_cs_b;
  inout [1:0]CH0_LPDDR4_0_0_dmi_a;
  inout [1:0]CH0_LPDDR4_0_0_dmi_b;
  inout [15:0]CH0_LPDDR4_0_0_dq_a;
  inout [15:0]CH0_LPDDR4_0_0_dq_b;
  inout [1:0]CH0_LPDDR4_0_0_dqs_c_a;
  inout [1:0]CH0_LPDDR4_0_0_dqs_c_b;
  inout [1:0]CH0_LPDDR4_0_0_dqs_t_a;
  inout [1:0]CH0_LPDDR4_0_0_dqs_t_b;
  output [0:0]CH0_LPDDR4_0_0_reset_n;
  output [5:0]CH0_LPDDR4_0_1_ca_a;
  output [5:0]CH0_LPDDR4_0_1_ca_b;
  output [0:0]CH0_LPDDR4_0_1_ck_c_a;
  output [0:0]CH0_LPDDR4_0_1_ck_c_b;
  output [0:0]CH0_LPDDR4_0_1_ck_t_a;
  output [0:0]CH0_LPDDR4_0_1_ck_t_b;
  output [0:0]CH0_LPDDR4_0_1_cke_a;
  output [0:0]CH0_LPDDR4_0_1_cke_b;
  output [0:0]CH0_LPDDR4_0_1_cs_a;
  output [0:0]CH0_LPDDR4_0_1_cs_b;
  inout [1:0]CH0_LPDDR4_0_1_dmi_a;
  inout [1:0]CH0_LPDDR4_0_1_dmi_b;
  inout [15:0]CH0_LPDDR4_0_1_dq_a;
  inout [15:0]CH0_LPDDR4_0_1_dq_b;
  inout [1:0]CH0_LPDDR4_0_1_dqs_c_a;
  inout [1:0]CH0_LPDDR4_0_1_dqs_c_b;
  inout [1:0]CH0_LPDDR4_0_1_dqs_t_a;
  inout [1:0]CH0_LPDDR4_0_1_dqs_t_b;
  output [0:0]CH0_LPDDR4_0_1_reset_n;
  output [5:0]CH0_LPDDR4_0_2_ca_a;
  output [5:0]CH0_LPDDR4_0_2_ca_b;
  output [0:0]CH0_LPDDR4_0_2_ck_c_a;
  output [0:0]CH0_LPDDR4_0_2_ck_c_b;
  output [0:0]CH0_LPDDR4_0_2_ck_t_a;
  output [0:0]CH0_LPDDR4_0_2_ck_t_b;
  output [0:0]CH0_LPDDR4_0_2_cke_a;
  output [0:0]CH0_LPDDR4_0_2_cke_b;
  output [0:0]CH0_LPDDR4_0_2_cs_a;
  output [0:0]CH0_LPDDR4_0_2_cs_b;
  inout [1:0]CH0_LPDDR4_0_2_dmi_a;
  inout [1:0]CH0_LPDDR4_0_2_dmi_b;
  inout [15:0]CH0_LPDDR4_0_2_dq_a;
  inout [15:0]CH0_LPDDR4_0_2_dq_b;
  inout [1:0]CH0_LPDDR4_0_2_dqs_c_a;
  inout [1:0]CH0_LPDDR4_0_2_dqs_c_b;
  inout [1:0]CH0_LPDDR4_0_2_dqs_t_a;
  inout [1:0]CH0_LPDDR4_0_2_dqs_t_b;
  output [0:0]CH0_LPDDR4_0_2_reset_n;
  output [5:0]CH1_LPDDR4_0_0_ca_a;
  output [5:0]CH1_LPDDR4_0_0_ca_b;
  output [0:0]CH1_LPDDR4_0_0_ck_c_a;
  output [0:0]CH1_LPDDR4_0_0_ck_c_b;
  output [0:0]CH1_LPDDR4_0_0_ck_t_a;
  output [0:0]CH1_LPDDR4_0_0_ck_t_b;
  output [0:0]CH1_LPDDR4_0_0_cke_a;
  output [0:0]CH1_LPDDR4_0_0_cke_b;
  output [0:0]CH1_LPDDR4_0_0_cs_a;
  output [0:0]CH1_LPDDR4_0_0_cs_b;
  inout [1:0]CH1_LPDDR4_0_0_dmi_a;
  inout [1:0]CH1_LPDDR4_0_0_dmi_b;
  inout [15:0]CH1_LPDDR4_0_0_dq_a;
  inout [15:0]CH1_LPDDR4_0_0_dq_b;
  inout [1:0]CH1_LPDDR4_0_0_dqs_c_a;
  inout [1:0]CH1_LPDDR4_0_0_dqs_c_b;
  inout [1:0]CH1_LPDDR4_0_0_dqs_t_a;
  inout [1:0]CH1_LPDDR4_0_0_dqs_t_b;
  output [0:0]CH1_LPDDR4_0_0_reset_n;
  output [5:0]CH1_LPDDR4_0_1_ca_a;
  output [5:0]CH1_LPDDR4_0_1_ca_b;
  output [0:0]CH1_LPDDR4_0_1_ck_c_a;
  output [0:0]CH1_LPDDR4_0_1_ck_c_b;
  output [0:0]CH1_LPDDR4_0_1_ck_t_a;
  output [0:0]CH1_LPDDR4_0_1_ck_t_b;
  output [0:0]CH1_LPDDR4_0_1_cke_a;
  output [0:0]CH1_LPDDR4_0_1_cke_b;
  output [0:0]CH1_LPDDR4_0_1_cs_a;
  output [0:0]CH1_LPDDR4_0_1_cs_b;
  inout [1:0]CH1_LPDDR4_0_1_dmi_a;
  inout [1:0]CH1_LPDDR4_0_1_dmi_b;
  inout [15:0]CH1_LPDDR4_0_1_dq_a;
  inout [15:0]CH1_LPDDR4_0_1_dq_b;
  inout [1:0]CH1_LPDDR4_0_1_dqs_c_a;
  inout [1:0]CH1_LPDDR4_0_1_dqs_c_b;
  inout [1:0]CH1_LPDDR4_0_1_dqs_t_a;
  inout [1:0]CH1_LPDDR4_0_1_dqs_t_b;
  output [0:0]CH1_LPDDR4_0_1_reset_n;
  output [5:0]CH1_LPDDR4_0_2_ca_a;
  output [5:0]CH1_LPDDR4_0_2_ca_b;
  output [0:0]CH1_LPDDR4_0_2_ck_c_a;
  output [0:0]CH1_LPDDR4_0_2_ck_c_b;
  output [0:0]CH1_LPDDR4_0_2_ck_t_a;
  output [0:0]CH1_LPDDR4_0_2_ck_t_b;
  output [0:0]CH1_LPDDR4_0_2_cke_a;
  output [0:0]CH1_LPDDR4_0_2_cke_b;
  output [0:0]CH1_LPDDR4_0_2_cs_a;
  output [0:0]CH1_LPDDR4_0_2_cs_b;
  inout [1:0]CH1_LPDDR4_0_2_dmi_a;
  inout [1:0]CH1_LPDDR4_0_2_dmi_b;
  inout [15:0]CH1_LPDDR4_0_2_dq_a;
  inout [15:0]CH1_LPDDR4_0_2_dq_b;
  inout [1:0]CH1_LPDDR4_0_2_dqs_c_a;
  inout [1:0]CH1_LPDDR4_0_2_dqs_c_b;
  inout [1:0]CH1_LPDDR4_0_2_dqs_t_a;
  inout [1:0]CH1_LPDDR4_0_2_dqs_t_b;
  output [0:0]CH1_LPDDR4_0_2_reset_n;
  input [7:0]PCIE1_GT_0_grx_n;
  input [7:0]PCIE1_GT_0_grx_p;
  output [7:0]PCIE1_GT_0_gtx_n;
  output [7:0]PCIE1_GT_0_gtx_p;
//  output [0:0]arb_force;
//  output [0:0]arb_force_dir;
//  output [8:0]arb_priority;
//  output [15:0]batch_num;
//  output dma1_axi_aresetn_0;
//  input [15:0]dma1_dsc_crdt_in_0_crdt;
//  input dma1_dsc_crdt_in_0_dir;
//  input dma1_dsc_crdt_in_0_fence;
//  input [10:0]dma1_dsc_crdt_in_0_qid;
//  output dma1_dsc_crdt_in_0_rdy;
//  input dma1_dsc_crdt_in_0_valid;
//  output [15:0]dma1_tm_dsc_sts_0_avl;
//  output dma1_tm_dsc_sts_0_byp;
//  output dma1_tm_dsc_sts_0_dir;
//  output dma1_tm_dsc_sts_0_error;
//  output dma1_tm_dsc_sts_0_irq_arm;
//  output dma1_tm_dsc_sts_0_mm;
//  output [15:0]dma1_tm_dsc_sts_0_pidx;
//  output [2:0]dma1_tm_dsc_sts_0_port_id;
//  output dma1_tm_dsc_sts_0_qen;
//  output [11:0]dma1_tm_dsc_sts_0_qid;
//  output dma1_tm_dsc_sts_0_qinv;
//  input dma1_tm_dsc_sts_0_rdy;
//  output dma1_tm_dsc_sts_0_valid;
  input gt_refclk1_0_clk_n;
  input gt_refclk1_0_clk_p;
//  output pl0_ref_clk_0;
//  output [15:0]port_limit;
  input [0:0]sys_clk0_0_clk_n;
  input [0:0]sys_clk0_0_clk_p;
  input [0:0]sys_clk0_1_clk_n;
  input [0:0]sys_clk0_1_clk_p;
  input [0:0]sys_clk0_2_clk_n;
  input [0:0]sys_clk0_2_clk_p;

  wire [5:0]CH0_LPDDR4_0_0_ca_a;
  wire [5:0]CH0_LPDDR4_0_0_ca_b;
  wire [0:0]CH0_LPDDR4_0_0_ck_c_a;
  wire [0:0]CH0_LPDDR4_0_0_ck_c_b;
  wire [0:0]CH0_LPDDR4_0_0_ck_t_a;
  wire [0:0]CH0_LPDDR4_0_0_ck_t_b;
  wire [0:0]CH0_LPDDR4_0_0_cke_a;
  wire [0:0]CH0_LPDDR4_0_0_cke_b;
  wire [0:0]CH0_LPDDR4_0_0_cs_a;
  wire [0:0]CH0_LPDDR4_0_0_cs_b;
  wire [1:0]CH0_LPDDR4_0_0_dmi_a;
  wire [1:0]CH0_LPDDR4_0_0_dmi_b;
  wire [15:0]CH0_LPDDR4_0_0_dq_a;
  wire [15:0]CH0_LPDDR4_0_0_dq_b;
  wire [1:0]CH0_LPDDR4_0_0_dqs_c_a;
  wire [1:0]CH0_LPDDR4_0_0_dqs_c_b;
  wire [1:0]CH0_LPDDR4_0_0_dqs_t_a;
  wire [1:0]CH0_LPDDR4_0_0_dqs_t_b;
  wire [0:0]CH0_LPDDR4_0_0_reset_n;
  wire [5:0]CH0_LPDDR4_0_1_ca_a;
  wire [5:0]CH0_LPDDR4_0_1_ca_b;
  wire [0:0]CH0_LPDDR4_0_1_ck_c_a;
  wire [0:0]CH0_LPDDR4_0_1_ck_c_b;
  wire [0:0]CH0_LPDDR4_0_1_ck_t_a;
  wire [0:0]CH0_LPDDR4_0_1_ck_t_b;
  wire [0:0]CH0_LPDDR4_0_1_cke_a;
  wire [0:0]CH0_LPDDR4_0_1_cke_b;
  wire [0:0]CH0_LPDDR4_0_1_cs_a;
  wire [0:0]CH0_LPDDR4_0_1_cs_b;
  wire [1:0]CH0_LPDDR4_0_1_dmi_a;
  wire [1:0]CH0_LPDDR4_0_1_dmi_b;
  wire [15:0]CH0_LPDDR4_0_1_dq_a;
  wire [15:0]CH0_LPDDR4_0_1_dq_b;
  wire [1:0]CH0_LPDDR4_0_1_dqs_c_a;
  wire [1:0]CH0_LPDDR4_0_1_dqs_c_b;
  wire [1:0]CH0_LPDDR4_0_1_dqs_t_a;
  wire [1:0]CH0_LPDDR4_0_1_dqs_t_b;
  wire [0:0]CH0_LPDDR4_0_1_reset_n;
  wire [5:0]CH0_LPDDR4_0_2_ca_a;
  wire [5:0]CH0_LPDDR4_0_2_ca_b;
  wire [0:0]CH0_LPDDR4_0_2_ck_c_a;
  wire [0:0]CH0_LPDDR4_0_2_ck_c_b;
  wire [0:0]CH0_LPDDR4_0_2_ck_t_a;
  wire [0:0]CH0_LPDDR4_0_2_ck_t_b;
  wire [0:0]CH0_LPDDR4_0_2_cke_a;
  wire [0:0]CH0_LPDDR4_0_2_cke_b;
  wire [0:0]CH0_LPDDR4_0_2_cs_a;
  wire [0:0]CH0_LPDDR4_0_2_cs_b;
  wire [1:0]CH0_LPDDR4_0_2_dmi_a;
  wire [1:0]CH0_LPDDR4_0_2_dmi_b;
  wire [15:0]CH0_LPDDR4_0_2_dq_a;
  wire [15:0]CH0_LPDDR4_0_2_dq_b;
  wire [1:0]CH0_LPDDR4_0_2_dqs_c_a;
  wire [1:0]CH0_LPDDR4_0_2_dqs_c_b;
  wire [1:0]CH0_LPDDR4_0_2_dqs_t_a;
  wire [1:0]CH0_LPDDR4_0_2_dqs_t_b;
  wire [0:0]CH0_LPDDR4_0_2_reset_n;
  wire [5:0]CH1_LPDDR4_0_0_ca_a;
  wire [5:0]CH1_LPDDR4_0_0_ca_b;
  wire [0:0]CH1_LPDDR4_0_0_ck_c_a;
  wire [0:0]CH1_LPDDR4_0_0_ck_c_b;
  wire [0:0]CH1_LPDDR4_0_0_ck_t_a;
  wire [0:0]CH1_LPDDR4_0_0_ck_t_b;
  wire [0:0]CH1_LPDDR4_0_0_cke_a;
  wire [0:0]CH1_LPDDR4_0_0_cke_b;
  wire [0:0]CH1_LPDDR4_0_0_cs_a;
  wire [0:0]CH1_LPDDR4_0_0_cs_b;
  wire [1:0]CH1_LPDDR4_0_0_dmi_a;
  wire [1:0]CH1_LPDDR4_0_0_dmi_b;
  wire [15:0]CH1_LPDDR4_0_0_dq_a;
  wire [15:0]CH1_LPDDR4_0_0_dq_b;
  wire [1:0]CH1_LPDDR4_0_0_dqs_c_a;
  wire [1:0]CH1_LPDDR4_0_0_dqs_c_b;
  wire [1:0]CH1_LPDDR4_0_0_dqs_t_a;
  wire [1:0]CH1_LPDDR4_0_0_dqs_t_b;
  wire [0:0]CH1_LPDDR4_0_0_reset_n;
  wire [5:0]CH1_LPDDR4_0_1_ca_a;
  wire [5:0]CH1_LPDDR4_0_1_ca_b;
  wire [0:0]CH1_LPDDR4_0_1_ck_c_a;
  wire [0:0]CH1_LPDDR4_0_1_ck_c_b;
  wire [0:0]CH1_LPDDR4_0_1_ck_t_a;
  wire [0:0]CH1_LPDDR4_0_1_ck_t_b;
  wire [0:0]CH1_LPDDR4_0_1_cke_a;
  wire [0:0]CH1_LPDDR4_0_1_cke_b;
  wire [0:0]CH1_LPDDR4_0_1_cs_a;
  wire [0:0]CH1_LPDDR4_0_1_cs_b;
  wire [1:0]CH1_LPDDR4_0_1_dmi_a;
  wire [1:0]CH1_LPDDR4_0_1_dmi_b;
  wire [15:0]CH1_LPDDR4_0_1_dq_a;
  wire [15:0]CH1_LPDDR4_0_1_dq_b;
  wire [1:0]CH1_LPDDR4_0_1_dqs_c_a;
  wire [1:0]CH1_LPDDR4_0_1_dqs_c_b;
  wire [1:0]CH1_LPDDR4_0_1_dqs_t_a;
  wire [1:0]CH1_LPDDR4_0_1_dqs_t_b;
  wire [0:0]CH1_LPDDR4_0_1_reset_n;
  wire [5:0]CH1_LPDDR4_0_2_ca_a;
  wire [5:0]CH1_LPDDR4_0_2_ca_b;
  wire [0:0]CH1_LPDDR4_0_2_ck_c_a;
  wire [0:0]CH1_LPDDR4_0_2_ck_c_b;
  wire [0:0]CH1_LPDDR4_0_2_ck_t_a;
  wire [0:0]CH1_LPDDR4_0_2_ck_t_b;
  wire [0:0]CH1_LPDDR4_0_2_cke_a;
  wire [0:0]CH1_LPDDR4_0_2_cke_b;
  wire [0:0]CH1_LPDDR4_0_2_cs_a;
  wire [0:0]CH1_LPDDR4_0_2_cs_b;
  wire [1:0]CH1_LPDDR4_0_2_dmi_a;
  wire [1:0]CH1_LPDDR4_0_2_dmi_b;
  wire [15:0]CH1_LPDDR4_0_2_dq_a;
  wire [15:0]CH1_LPDDR4_0_2_dq_b;
  wire [1:0]CH1_LPDDR4_0_2_dqs_c_a;
  wire [1:0]CH1_LPDDR4_0_2_dqs_c_b;
  wire [1:0]CH1_LPDDR4_0_2_dqs_t_a;
  wire [1:0]CH1_LPDDR4_0_2_dqs_t_b;
  wire [0:0]CH1_LPDDR4_0_2_reset_n;
  wire [7:0]PCIE1_GT_0_grx_n;
  wire [7:0]PCIE1_GT_0_grx_p;
  wire [7:0]PCIE1_GT_0_gtx_n;
  wire [7:0]PCIE1_GT_0_gtx_p;
  wire [0:0]arb_force;
  wire [0:0]arb_force_dir;
  wire [8:0]arb_priority;
  wire [15:0]batch_num;
  wire dma1_axi_aresetn_0;
  wire [15:0]dma1_dsc_crdt_in_0_crdt;
  wire dma1_dsc_crdt_in_0_dir;
  wire dma1_dsc_crdt_in_0_fence;
  wire [10:0]dma1_dsc_crdt_in_0_qid;
  wire dma1_dsc_crdt_in_0_rdy;
  wire dma1_dsc_crdt_in_0_valid;
  wire [15:0]dma1_tm_dsc_sts_0_avl;
  wire dma1_tm_dsc_sts_0_byp;
  wire dma1_tm_dsc_sts_0_dir;
  wire dma1_tm_dsc_sts_0_error;
  wire dma1_tm_dsc_sts_0_irq_arm;
  wire dma1_tm_dsc_sts_0_mm;
  wire [15:0]dma1_tm_dsc_sts_0_pidx;
  wire [2:0]dma1_tm_dsc_sts_0_port_id;
  wire dma1_tm_dsc_sts_0_qen;
  wire [11:0]dma1_tm_dsc_sts_0_qid;
  wire dma1_tm_dsc_sts_0_qinv;
  wire dma1_tm_dsc_sts_0_rdy;
  wire dma1_tm_dsc_sts_0_valid;
  wire gt_refclk1_0_clk_n;
  wire gt_refclk1_0_clk_p;
  wire pl0_ref_clk_0;
  wire [15:0]port_limit;
  wire [0:0]sys_clk0_0_clk_n;
  wire [0:0]sys_clk0_0_clk_p;
  wire [0:0]sys_clk0_1_clk_n;
  wire [0:0]sys_clk0_1_clk_p;
  wire [0:0]sys_clk0_2_clk_n;
  wire [0:0]sys_clk0_2_clk_p;

  design_1 design_1_i
       (.CH0_LPDDR4_0_0_ca_a(CH0_LPDDR4_0_0_ca_a),
        .CH0_LPDDR4_0_0_ca_b(CH0_LPDDR4_0_0_ca_b),
        .CH0_LPDDR4_0_0_ck_c_a(CH0_LPDDR4_0_0_ck_c_a),
        .CH0_LPDDR4_0_0_ck_c_b(CH0_LPDDR4_0_0_ck_c_b),
        .CH0_LPDDR4_0_0_ck_t_a(CH0_LPDDR4_0_0_ck_t_a),
        .CH0_LPDDR4_0_0_ck_t_b(CH0_LPDDR4_0_0_ck_t_b),
        .CH0_LPDDR4_0_0_cke_a(CH0_LPDDR4_0_0_cke_a),
        .CH0_LPDDR4_0_0_cke_b(CH0_LPDDR4_0_0_cke_b),
        .CH0_LPDDR4_0_0_cs_a(CH0_LPDDR4_0_0_cs_a),
        .CH0_LPDDR4_0_0_cs_b(CH0_LPDDR4_0_0_cs_b),
        .CH0_LPDDR4_0_0_dmi_a(CH0_LPDDR4_0_0_dmi_a),
        .CH0_LPDDR4_0_0_dmi_b(CH0_LPDDR4_0_0_dmi_b),
        .CH0_LPDDR4_0_0_dq_a(CH0_LPDDR4_0_0_dq_a),
        .CH0_LPDDR4_0_0_dq_b(CH0_LPDDR4_0_0_dq_b),
        .CH0_LPDDR4_0_0_dqs_c_a(CH0_LPDDR4_0_0_dqs_c_a),
        .CH0_LPDDR4_0_0_dqs_c_b(CH0_LPDDR4_0_0_dqs_c_b),
        .CH0_LPDDR4_0_0_dqs_t_a(CH0_LPDDR4_0_0_dqs_t_a),
        .CH0_LPDDR4_0_0_dqs_t_b(CH0_LPDDR4_0_0_dqs_t_b),
        .CH0_LPDDR4_0_0_reset_n(CH0_LPDDR4_0_0_reset_n),
        .CH0_LPDDR4_0_1_ca_a(CH0_LPDDR4_0_1_ca_a),
        .CH0_LPDDR4_0_1_ca_b(CH0_LPDDR4_0_1_ca_b),
        .CH0_LPDDR4_0_1_ck_c_a(CH0_LPDDR4_0_1_ck_c_a),
        .CH0_LPDDR4_0_1_ck_c_b(CH0_LPDDR4_0_1_ck_c_b),
        .CH0_LPDDR4_0_1_ck_t_a(CH0_LPDDR4_0_1_ck_t_a),
        .CH0_LPDDR4_0_1_ck_t_b(CH0_LPDDR4_0_1_ck_t_b),
        .CH0_LPDDR4_0_1_cke_a(CH0_LPDDR4_0_1_cke_a),
        .CH0_LPDDR4_0_1_cke_b(CH0_LPDDR4_0_1_cke_b),
        .CH0_LPDDR4_0_1_cs_a(CH0_LPDDR4_0_1_cs_a),
        .CH0_LPDDR4_0_1_cs_b(CH0_LPDDR4_0_1_cs_b),
        .CH0_LPDDR4_0_1_dmi_a(CH0_LPDDR4_0_1_dmi_a),
        .CH0_LPDDR4_0_1_dmi_b(CH0_LPDDR4_0_1_dmi_b),
        .CH0_LPDDR4_0_1_dq_a(CH0_LPDDR4_0_1_dq_a),
        .CH0_LPDDR4_0_1_dq_b(CH0_LPDDR4_0_1_dq_b),
        .CH0_LPDDR4_0_1_dqs_c_a(CH0_LPDDR4_0_1_dqs_c_a),
        .CH0_LPDDR4_0_1_dqs_c_b(CH0_LPDDR4_0_1_dqs_c_b),
        .CH0_LPDDR4_0_1_dqs_t_a(CH0_LPDDR4_0_1_dqs_t_a),
        .CH0_LPDDR4_0_1_dqs_t_b(CH0_LPDDR4_0_1_dqs_t_b),
        .CH0_LPDDR4_0_1_reset_n(CH0_LPDDR4_0_1_reset_n),
        .CH0_LPDDR4_0_2_ca_a(CH0_LPDDR4_0_2_ca_a),
        .CH0_LPDDR4_0_2_ca_b(CH0_LPDDR4_0_2_ca_b),
        .CH0_LPDDR4_0_2_ck_c_a(CH0_LPDDR4_0_2_ck_c_a),
        .CH0_LPDDR4_0_2_ck_c_b(CH0_LPDDR4_0_2_ck_c_b),
        .CH0_LPDDR4_0_2_ck_t_a(CH0_LPDDR4_0_2_ck_t_a),
        .CH0_LPDDR4_0_2_ck_t_b(CH0_LPDDR4_0_2_ck_t_b),
        .CH0_LPDDR4_0_2_cke_a(CH0_LPDDR4_0_2_cke_a),
        .CH0_LPDDR4_0_2_cke_b(CH0_LPDDR4_0_2_cke_b),
        .CH0_LPDDR4_0_2_cs_a(CH0_LPDDR4_0_2_cs_a),
        .CH0_LPDDR4_0_2_cs_b(CH0_LPDDR4_0_2_cs_b),
        .CH0_LPDDR4_0_2_dmi_a(CH0_LPDDR4_0_2_dmi_a),
        .CH0_LPDDR4_0_2_dmi_b(CH0_LPDDR4_0_2_dmi_b),
        .CH0_LPDDR4_0_2_dq_a(CH0_LPDDR4_0_2_dq_a),
        .CH0_LPDDR4_0_2_dq_b(CH0_LPDDR4_0_2_dq_b),
        .CH0_LPDDR4_0_2_dqs_c_a(CH0_LPDDR4_0_2_dqs_c_a),
        .CH0_LPDDR4_0_2_dqs_c_b(CH0_LPDDR4_0_2_dqs_c_b),
        .CH0_LPDDR4_0_2_dqs_t_a(CH0_LPDDR4_0_2_dqs_t_a),
        .CH0_LPDDR4_0_2_dqs_t_b(CH0_LPDDR4_0_2_dqs_t_b),
        .CH0_LPDDR4_0_2_reset_n(CH0_LPDDR4_0_2_reset_n),
        .CH1_LPDDR4_0_0_ca_a(CH1_LPDDR4_0_0_ca_a),
        .CH1_LPDDR4_0_0_ca_b(CH1_LPDDR4_0_0_ca_b),
        .CH1_LPDDR4_0_0_ck_c_a(CH1_LPDDR4_0_0_ck_c_a),
        .CH1_LPDDR4_0_0_ck_c_b(CH1_LPDDR4_0_0_ck_c_b),
        .CH1_LPDDR4_0_0_ck_t_a(CH1_LPDDR4_0_0_ck_t_a),
        .CH1_LPDDR4_0_0_ck_t_b(CH1_LPDDR4_0_0_ck_t_b),
        .CH1_LPDDR4_0_0_cke_a(CH1_LPDDR4_0_0_cke_a),
        .CH1_LPDDR4_0_0_cke_b(CH1_LPDDR4_0_0_cke_b),
        .CH1_LPDDR4_0_0_cs_a(CH1_LPDDR4_0_0_cs_a),
        .CH1_LPDDR4_0_0_cs_b(CH1_LPDDR4_0_0_cs_b),
        .CH1_LPDDR4_0_0_dmi_a(CH1_LPDDR4_0_0_dmi_a),
        .CH1_LPDDR4_0_0_dmi_b(CH1_LPDDR4_0_0_dmi_b),
        .CH1_LPDDR4_0_0_dq_a(CH1_LPDDR4_0_0_dq_a),
        .CH1_LPDDR4_0_0_dq_b(CH1_LPDDR4_0_0_dq_b),
        .CH1_LPDDR4_0_0_dqs_c_a(CH1_LPDDR4_0_0_dqs_c_a),
        .CH1_LPDDR4_0_0_dqs_c_b(CH1_LPDDR4_0_0_dqs_c_b),
        .CH1_LPDDR4_0_0_dqs_t_a(CH1_LPDDR4_0_0_dqs_t_a),
        .CH1_LPDDR4_0_0_dqs_t_b(CH1_LPDDR4_0_0_dqs_t_b),
        .CH1_LPDDR4_0_0_reset_n(CH1_LPDDR4_0_0_reset_n),
        .CH1_LPDDR4_0_1_ca_a(CH1_LPDDR4_0_1_ca_a),
        .CH1_LPDDR4_0_1_ca_b(CH1_LPDDR4_0_1_ca_b),
        .CH1_LPDDR4_0_1_ck_c_a(CH1_LPDDR4_0_1_ck_c_a),
        .CH1_LPDDR4_0_1_ck_c_b(CH1_LPDDR4_0_1_ck_c_b),
        .CH1_LPDDR4_0_1_ck_t_a(CH1_LPDDR4_0_1_ck_t_a),
        .CH1_LPDDR4_0_1_ck_t_b(CH1_LPDDR4_0_1_ck_t_b),
        .CH1_LPDDR4_0_1_cke_a(CH1_LPDDR4_0_1_cke_a),
        .CH1_LPDDR4_0_1_cke_b(CH1_LPDDR4_0_1_cke_b),
        .CH1_LPDDR4_0_1_cs_a(CH1_LPDDR4_0_1_cs_a),
        .CH1_LPDDR4_0_1_cs_b(CH1_LPDDR4_0_1_cs_b),
        .CH1_LPDDR4_0_1_dmi_a(CH1_LPDDR4_0_1_dmi_a),
        .CH1_LPDDR4_0_1_dmi_b(CH1_LPDDR4_0_1_dmi_b),
        .CH1_LPDDR4_0_1_dq_a(CH1_LPDDR4_0_1_dq_a),
        .CH1_LPDDR4_0_1_dq_b(CH1_LPDDR4_0_1_dq_b),
        .CH1_LPDDR4_0_1_dqs_c_a(CH1_LPDDR4_0_1_dqs_c_a),
        .CH1_LPDDR4_0_1_dqs_c_b(CH1_LPDDR4_0_1_dqs_c_b),
        .CH1_LPDDR4_0_1_dqs_t_a(CH1_LPDDR4_0_1_dqs_t_a),
        .CH1_LPDDR4_0_1_dqs_t_b(CH1_LPDDR4_0_1_dqs_t_b),
        .CH1_LPDDR4_0_1_reset_n(CH1_LPDDR4_0_1_reset_n),
        .CH1_LPDDR4_0_2_ca_a(CH1_LPDDR4_0_2_ca_a),
        .CH1_LPDDR4_0_2_ca_b(CH1_LPDDR4_0_2_ca_b),
        .CH1_LPDDR4_0_2_ck_c_a(CH1_LPDDR4_0_2_ck_c_a),
        .CH1_LPDDR4_0_2_ck_c_b(CH1_LPDDR4_0_2_ck_c_b),
        .CH1_LPDDR4_0_2_ck_t_a(CH1_LPDDR4_0_2_ck_t_a),
        .CH1_LPDDR4_0_2_ck_t_b(CH1_LPDDR4_0_2_ck_t_b),
        .CH1_LPDDR4_0_2_cke_a(CH1_LPDDR4_0_2_cke_a),
        .CH1_LPDDR4_0_2_cke_b(CH1_LPDDR4_0_2_cke_b),
        .CH1_LPDDR4_0_2_cs_a(CH1_LPDDR4_0_2_cs_a),
        .CH1_LPDDR4_0_2_cs_b(CH1_LPDDR4_0_2_cs_b),
        .CH1_LPDDR4_0_2_dmi_a(CH1_LPDDR4_0_2_dmi_a),
        .CH1_LPDDR4_0_2_dmi_b(CH1_LPDDR4_0_2_dmi_b),
        .CH1_LPDDR4_0_2_dq_a(CH1_LPDDR4_0_2_dq_a),
        .CH1_LPDDR4_0_2_dq_b(CH1_LPDDR4_0_2_dq_b),
        .CH1_LPDDR4_0_2_dqs_c_a(CH1_LPDDR4_0_2_dqs_c_a),
        .CH1_LPDDR4_0_2_dqs_c_b(CH1_LPDDR4_0_2_dqs_c_b),
        .CH1_LPDDR4_0_2_dqs_t_a(CH1_LPDDR4_0_2_dqs_t_a),
        .CH1_LPDDR4_0_2_dqs_t_b(CH1_LPDDR4_0_2_dqs_t_b),
        .CH1_LPDDR4_0_2_reset_n(CH1_LPDDR4_0_2_reset_n),
        .PCIE1_GT_0_grx_n(PCIE1_GT_0_grx_n),
        .PCIE1_GT_0_grx_p(PCIE1_GT_0_grx_p),
        .PCIE1_GT_0_gtx_n(PCIE1_GT_0_gtx_n),
        .PCIE1_GT_0_gtx_p(PCIE1_GT_0_gtx_p),
//        .arb_force(arb_force),
//        .arb_force_dir(arb_force_dir),
//        .arb_priority(arb_priority),
//        .batch_num(batch_num),
//        .port_limit(port_limit),
//        .dma1_axi_aresetn_0(dma1_axi_aresetn_0),
//       .dma1_dsc_crdt_in_0_crdt(dma1_dsc_crdt_in_0_crdt),
//        .dma1_dsc_crdt_in_0_dir(dma1_dsc_crdt_in_0_dir),
//        .dma1_dsc_crdt_in_0_fence(dma1_dsc_crdt_in_0_fence),
//        .dma1_dsc_crdt_in_0_qid(dma1_dsc_crdt_in_0_qid),
//        .dma1_dsc_crdt_in_0_rdy(dma1_dsc_crdt_in_0_rdy),
//        .dma1_dsc_crdt_in_0_valid(dma1_dsc_crdt_in_0_valid),

        .dma1_dsc_crdt_in_0_crdt('h0),
        .dma1_dsc_crdt_in_0_dir('h0),
        .dma1_dsc_crdt_in_0_fence('h0),
        .dma1_dsc_crdt_in_0_qid('h0),
        .dma1_dsc_crdt_in_0_rdy(),
        .dma1_dsc_crdt_in_0_valid('h0),
        .dma1_tm_dsc_sts_0_avl(dma1_tm_dsc_sts_0_avl),
        .dma1_tm_dsc_sts_0_byp(dma1_tm_dsc_sts_0_byp),
        .dma1_tm_dsc_sts_0_dir(dma1_tm_dsc_sts_0_dir),
        .dma1_tm_dsc_sts_0_error(dma1_tm_dsc_sts_0_error),
        .dma1_tm_dsc_sts_0_irq_arm(dma1_tm_dsc_sts_0_irq_arm),
        .dma1_tm_dsc_sts_0_mm(dma1_tm_dsc_sts_0_mm),
        .dma1_tm_dsc_sts_0_pidx(dma1_tm_dsc_sts_0_pidx),
        .dma1_tm_dsc_sts_0_port_id(dma1_tm_dsc_sts_0_port_id),
        .dma1_tm_dsc_sts_0_qen(dma1_tm_dsc_sts_0_qen),
        .dma1_tm_dsc_sts_0_qid(dma1_tm_dsc_sts_0_qid),
        .dma1_tm_dsc_sts_0_qinv(dma1_tm_dsc_sts_0_qinv),
//        .dma1_tm_dsc_sts_0_rdy(dma1_tm_dsc_sts_0_rdy),
        .dma1_tm_dsc_sts_0_rdy(1'b1),
        .dma1_tm_dsc_sts_0_valid(dma1_tm_dsc_sts_0_valid),
        .gt_refclk1_0_clk_n(gt_refclk1_0_clk_n),
        .gt_refclk1_0_clk_p(gt_refclk1_0_clk_p),
        .pl0_ref_clk_0(pl0_ref_clk_0),
        .sys_clk0_0_clk_n(sys_clk0_0_clk_n),
        .sys_clk0_0_clk_p(sys_clk0_0_clk_p),
        .sys_clk0_1_clk_n(sys_clk0_1_clk_n),
        .sys_clk0_1_clk_p(sys_clk0_1_clk_p),
        .sys_clk0_2_clk_n(sys_clk0_2_clk_n),
        .sys_clk0_2_clk_p(sys_clk0_2_clk_p));

/*   
desc_crdt_arb desc_crdt_arb_i (
  .user_clk       (pl0_ref_clk_0),
  .user_reset_n   (dma1_axi_aresetn_0),
  
  // Control
  .batch_num      ('d8),    // Number of descriptor batched each time.
  .arb_force      ('d0),    // 1=Force Arbitration, use arb_force_dir
  .arb_force_dir  ('d0),// 0=H2C; 1=C2H
  .arb_priority   ('d0), // Bit[width-1]=0 H2C higher priority; Bit[width-1]=1 C2H higher priority
                                                   // Bit[width-2:0] determines 2^Bit[width-2:0] desc total before switching dir
                                                   // Quiesce traffic before switching
  .port_limit     ('d8),   // Limit the number of descriptor fetched per MM port. Applies to both dir.
                                                   // Must be set equal or higher than batch_num
                                                   
  // tmsts throttle/backpresure signals
  .back_pres      (1'b0),
  .turn_off       (1'b0),

  // tm interface signals
  .tm_dsc_sts_vld     (dma1_tm_dsc_sts_0_valid),
  .tm_dsc_sts_qen     (dma1_tm_dsc_sts_0_qen),
  .tm_dsc_sts_byp     (dma1_tm_dsc_sts_0_byp), // 0=desc fetched from host; 1=desc came from descriptory bypass
  .tm_dsc_sts_dir     (dma1_tm_dsc_sts_0_dir), // 0=H2C; 1=C2H
  .tm_dsc_sts_mm      (dma1_tm_dsc_sts_0_mm), // 0=ST; 1=MM
  .tm_dsc_sts_qid     (dma1_tm_dsc_sts_0_qid), // QID for update
  .tm_dsc_sts_avl     (dma1_tm_dsc_sts_0_avl), // Number of new descriptors since last update
  .tm_dsc_sts_qinv    (dma1_tm_dsc_sts_0_qinv), // 1 indicated to invalidate the queue
  .tm_dsc_sts_irq_arm (dma1_tm_dsc_sts_0_irq_arm), // 1 indicated to that the driver is using interrupts
  .tm_dsc_sts_rdy     (dma1_tm_dsc_sts_0_rdy), // 1 indicates valid data on the bus
  
  // Descriptor Credit interface
  .dsc_crdt_in_rdy    (dma1_dsc_crdt_in_0_rdy),
  .dsc_crdt_in_valid  (dma1_dsc_crdt_in_0_valid),
  .dsc_crdt_in_fence  (dma1_dsc_crdt_in_0_fence),
  .dsc_crdt_in_dir    (dma1_dsc_crdt_in_0_dir),
  .dsc_crdt_in_qid    (dma1_dsc_crdt_in_0_qid),
  .dsc_crdt_in_crdt   (dma1_dsc_crdt_in_0_crdt)
);
  */      
endmodule
