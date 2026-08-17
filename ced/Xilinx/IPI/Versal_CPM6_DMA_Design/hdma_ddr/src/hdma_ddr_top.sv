//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2026.1.0 (lin64) Build 6393872 Wed Mar 11 01:04:36 MDT 2026
//Date        : Wed Mar 18 22:25:51 2026
//Host        : xsjlc220532 running 64-bit Red Hat Enterprise Linux release 8.10 (Ootpa)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module hdma_ddr_top
import hdma_link_pkg::*;
   (CH0_LPDDR5_0_ca,
    CH0_LPDDR5_0_ck_c,
    CH0_LPDDR5_0_ck_t,
    CH0_LPDDR5_0_cs,
    CH0_LPDDR5_0_dmi,
    CH0_LPDDR5_0_dq,
    CH0_LPDDR5_0_rdqs_c,
    CH0_LPDDR5_0_rdqs_t,
    CH0_LPDDR5_0_reset_n,
    CH0_LPDDR5_0_wck_c,
    CH0_LPDDR5_0_wck_t,
    CTRL1_GT_0_grx_n,
    CTRL1_GT_0_grx_p,
    CTRL1_GT_0_gtx_n,
    CTRL1_GT_0_gtx_p,
    ctrl1_gt_refclk_0_clk_n,
    ctrl1_gt_refclk_0_clk_p,
    sys_clk0_0_clk_n,
    sys_clk0_0_clk_p);

 output [6:0]CH0_LPDDR5_0_ca;
  output [0:0]CH0_LPDDR5_0_ck_c;
  output [0:0]CH0_LPDDR5_0_ck_t;
  output [1:0]CH0_LPDDR5_0_cs;
  inout [3:0]CH0_LPDDR5_0_dmi;
  inout [31:0]CH0_LPDDR5_0_dq;
  input [3:0]CH0_LPDDR5_0_rdqs_c;
  input [3:0]CH0_LPDDR5_0_rdqs_t;
  output CH0_LPDDR5_0_reset_n;
  output [3:0]CH0_LPDDR5_0_wck_c;
  output [3:0]CH0_LPDDR5_0_wck_t;
  input  [LINK_WIDTH-1:0] CTRL1_GT_0_grx_n;
  input  [LINK_WIDTH-1:0] CTRL1_GT_0_grx_p;
  output [LINK_WIDTH-1:0] CTRL1_GT_0_gtx_n;
  output [LINK_WIDTH-1:0] CTRL1_GT_0_gtx_p;
  input ctrl1_gt_refclk_0_clk_n;
  input ctrl1_gt_refclk_0_clk_p;
  input [0:0]sys_clk0_0_clk_n;
  input [0:0]sys_clk0_0_clk_p;

  wire [6:0]CH0_LPDDR5_0_ca;
  wire [0:0]CH0_LPDDR5_0_ck_c;
  wire [0:0]CH0_LPDDR5_0_ck_t;
  wire [1:0]CH0_LPDDR5_0_cs;
  wire [3:0]CH0_LPDDR5_0_dmi;
  wire [31:0]CH0_LPDDR5_0_dq;
  wire [3:0]CH0_LPDDR5_0_rdqs_c;
  wire [3:0]CH0_LPDDR5_0_rdqs_t;
  wire CH0_LPDDR5_0_reset_n;
  wire [3:0]CH0_LPDDR5_0_wck_c;
  wire [3:0]CH0_LPDDR5_0_wck_t;
  wire [LINK_WIDTH-1:0] CTRL1_GT_0_grx_n;
  wire [LINK_WIDTH-1:0] CTRL1_GT_0_grx_p;
  wire [LINK_WIDTH-1:0] CTRL1_GT_0_gtx_n;
  wire [LINK_WIDTH-1:0] CTRL1_GT_0_gtx_p;
  wire [0:0]sys_clk0_0_clk_n;
  wire [0:0]sys_clk0_0_clk_p;
   
  wire aclk;
  wire ctrl1_gt_refclk_0_clk_n;
  wire ctrl1_gt_refclk_0_clk_p;
  wire dbi1_rstn_0;
  wire [127:0]dma1_irq_0;
  wire pcie1_msix_0_error;
  wire [2:0]pcie1_msix_0_func_num;
  wire pcie1_msix_0_grant;
  wire [1:0]pcie1_msix_0_operation;
  wire pcie1_msix_0_req;
  wire [10:0]pcie1_msix_0_vector_num;
  wire pcie1_msix_0_vfunc_active;
  wire [7:0]pcie1_msix_0_vfunc_num;
  wire pcie1_rstn_0;
/*
  Need to bring put PL-AXI-0 port out to top level and connect it to an AXI master on the host side,
  This is need because cpm6 PL-AXI0 port outputs address [50:0] which includs controler number in bit 49.
  This deisgn uses controler1 so bit [49] is set to 1. 
  But the smart conenct user that bit as part of address and give error.
  So inthe top level only 48:0 bits are connected back to S00_AXI port going to smart connect.
 
*/
  cpm6_hdma design_1_i
    (
    .CTRL1_GT_0_grx_n(CTRL1_GT_0_grx_n),
    .CTRL1_GT_0_grx_p(CTRL1_GT_0_grx_p),
    .CTRL1_GT_0_gtx_n(CTRL1_GT_0_gtx_n),
    .CTRL1_GT_0_gtx_p(CTRL1_GT_0_gtx_p),
    .CH0_LPDDR5_0_ca(CH0_LPDDR5_0_ca),
    .CH0_LPDDR5_0_ck_c(CH0_LPDDR5_0_ck_c),
    .CH0_LPDDR5_0_ck_t(CH0_LPDDR5_0_ck_t),
    .CH0_LPDDR5_0_cs(CH0_LPDDR5_0_cs),
    .CH0_LPDDR5_0_dmi(CH0_LPDDR5_0_dmi),
    .CH0_LPDDR5_0_dq(CH0_LPDDR5_0_dq),
    .CH0_LPDDR5_0_rdqs_c(CH0_LPDDR5_0_rdqs_c),
    .CH0_LPDDR5_0_rdqs_t(CH0_LPDDR5_0_rdqs_t),
    .CH0_LPDDR5_0_reset_n(CH0_LPDDR5_0_reset_n),
    .CH0_LPDDR5_0_wck_c(CH0_LPDDR5_0_wck_c),
    .CH0_LPDDR5_0_wck_t(CH0_LPDDR5_0_wck_t),
    .sys_clk0_0_clk_n(sys_clk0_0_clk_n),
    .sys_clk0_0_clk_p(sys_clk0_0_clk_p),
        .aclk(aclk),
        .ctrl1_gt_refclk_0_clk_n(ctrl1_gt_refclk_0_clk_n),
        .ctrl1_gt_refclk_0_clk_p(ctrl1_gt_refclk_0_clk_p),
      
        .dma1_irq_0(dma1_irq_0),
        .pcie1_msix_0_error(pcie1_msix_0_error),
        .pcie1_msix_0_func_num(pcie1_msix_0_func_num),
        .pcie1_msix_0_grant(pcie1_msix_0_grant),
        .pcie1_msix_0_operation(pcie1_msix_0_operation),
        .pcie1_msix_0_req(pcie1_msix_0_req),
        .pcie1_msix_0_vector_num(pcie1_msix_0_vector_num),
        .pcie1_msix_0_vfunc_active(pcie1_msix_0_vfunc_active),
        .pcie1_msix_0_vfunc_num(pcie1_msix_0_vfunc_num),
        .pcie1_rstn_0(pcie1_rstn_0)
      );


   pl_example i_pl_example
     (
      .clk (aclk),
      .reset_n (pcie1_rstn_0),
      
      .pcie_msix_error        (pcie1_msix_0_error),
      .pcie_msix_func_num     (pcie1_msix_0_func_num),
      .pcie_msix_grant         (pcie1_msix_0_grant),
      .pcie_msix_operation     (pcie1_msix_0_operation),
      .pcie_msix_req           (pcie1_msix_0_req),
      .pcie_msix_vector_num   (pcie1_msix_0_vector_num),
      .pcie_msix_vfunc_active (pcie1_msix_0_vfunc_active),
      .pcie_msix_vfunc_num     (pcie1_msix_0_vfunc_num),
      .dma_irq                 (dma1_irq_0)
      );
   


   
endmodule
