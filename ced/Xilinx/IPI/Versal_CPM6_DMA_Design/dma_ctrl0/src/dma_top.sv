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
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2026.1.0 (lin64) Build 6384650 Mon Mar 02 16:03:59 MST 2026
//Date        : Tue Mar  3 16:13:38 2026
//Host        : xsjlc220532 running 64-bit Red Hat Enterprise Linux release 8.10 (Ootpa)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

`timescale 1 ps / 1 ps

module dma_top
import dma_link_pkg::*;
   (
    CTRL0_GT_0_grx_n,
    CTRL0_GT_0_grx_p,
    CTRL0_GT_0_gtx_n,
    CTRL0_GT_0_gtx_p,
    ctrl0_gt_refclk_0_clk_n,
    ctrl0_gt_refclk_0_clk_p
    );

  input [LINK_WIDTH-1:0]CTRL0_GT_0_grx_n;
  input [LINK_WIDTH-1:0]CTRL0_GT_0_grx_p;
  output [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_n;
  output [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_p;
  input ctrl0_gt_refclk_0_clk_n;
  input ctrl0_gt_refclk_0_clk_p;

  wire [LINK_WIDTH-1:0]CTRL0_GT_0_grx_n;
  wire [LINK_WIDTH-1:0]CTRL0_GT_0_grx_p;
  wire [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_n;
  wire [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_p;
  wire [0:0]sys_clk0_0_clk_n;
  wire [0:0]sys_clk0_0_clk_p;

  wire aclk;
  wire ctrl0_gt_refclk_0_clk_n;
  wire ctrl0_gt_refclk_0_clk_p;
  wire dbi0_rstn_0;
  wire [127:0]dma0_irq_0;
  wire pcie0_msix_0_error;
  wire [2:0]pcie0_msix_0_func_num;
  wire pcie0_msix_0_grant;
  wire [1:0]pcie0_msix_0_operation;
  wire pcie0_msix_0_req;
  wire [10:0]pcie0_msix_0_vector_num;
  wire pcie0_msix_0_vfunc_active;
  wire [7:0]pcie0_msix_0_vfunc_num;
  wire pcie0_rstn_0;
/*
  Need to bring put PL-AXI-0 port out to top level and connect it to an AXI master on the host side,
  This is need because cpm6 PL-AXI0 port outputs address [50:0] which includs controler number in bit 49.
  This deisgn uses controler0 so bit [49] is set to 0.
  But the smart conenct user that bit as part of address and give error.
  So inthe top level only 48:0 bits are connected back to S00_AXI port going to smart connect.

*/
  cpm6_dma design_1_i
    (
    .CTRL0_GT_0_grx_n(CTRL0_GT_0_grx_n),
    .CTRL0_GT_0_grx_p(CTRL0_GT_0_grx_p),
    .CTRL0_GT_0_gtx_n(CTRL0_GT_0_gtx_n),
    .CTRL0_GT_0_gtx_p(CTRL0_GT_0_gtx_p),

        .aclk(aclk),
        .ctrl0_gt_refclk_0_clk_n(ctrl0_gt_refclk_0_clk_n),
        .ctrl0_gt_refclk_0_clk_p(ctrl0_gt_refclk_0_clk_p),

        .dma0_irq_0(dma0_irq_0),
        .pcie0_msix_0_error(pcie0_msix_0_error),
        .pcie0_msix_0_func_num(pcie0_msix_0_func_num),
        .pcie0_msix_0_grant(pcie0_msix_0_grant),
        .pcie0_msix_0_operation(pcie0_msix_0_operation),
        .pcie0_msix_0_req(pcie0_msix_0_req),
        .pcie0_msix_0_vector_num(pcie0_msix_0_vector_num),
        .pcie0_msix_0_vfunc_active(pcie0_msix_0_vfunc_active),
        .pcie0_msix_0_vfunc_num(pcie0_msix_0_vfunc_num),
        .pcie0_rstn_0(pcie0_rstn_0)
      );


   pl_example i_pl_example
     (
      .clk (aclk),
      .reset_n (pcie0_rstn_0),

      .pcie_msix_error        (pcie0_msix_0_error),
      .pcie_msix_func_num     (pcie0_msix_0_func_num),
      .pcie_msix_grant         (pcie0_msix_0_grant),
      .pcie_msix_operation     (pcie0_msix_0_operation),
      .pcie_msix_req           (pcie0_msix_0_req),
      .pcie_msix_vector_num   (pcie0_msix_0_vector_num),
      .pcie_msix_vfunc_active (pcie0_msix_0_vfunc_active),
      .pcie_msix_vfunc_num     (pcie0_msix_0_vfunc_num),
      .dma_irq                 (dma0_irq_0)
      );
endmodule
