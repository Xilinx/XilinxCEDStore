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

module dma_top
import dma_link_pkg::*;
   (CTRL0_GT_0_grx_n,
    CTRL0_GT_0_grx_p,
    CTRL0_GT_0_gtx_n,
    CTRL0_GT_0_gtx_p,
    ctrl0_gt_refclk_0_clk_n,
    ctrl0_gt_refclk_0_clk_p
);
  input [LINK_WIDTH-1:0] CTRL0_GT_0_grx_n;
  input [LINK_WIDTH-1:0] CTRL0_GT_0_grx_p;
  output [LINK_WIDTH-1:0] CTRL0_GT_0_gtx_n;
  output [LINK_WIDTH-1:0] CTRL0_GT_0_gtx_p;
  input ctrl0_gt_refclk_0_clk_n;
  input ctrl0_gt_refclk_0_clk_p;


  wire [LINK_WIDTH-1:0] CTRL0_GT_0_grx_n;
  wire [LINK_WIDTH-1:0] CTRL0_GT_0_grx_p;
  wire [LINK_WIDTH-1:0] CTRL0_GT_0_gtx_n;
  wire [LINK_WIDTH-1:0] CTRL0_GT_0_gtx_p;
  wire ctrl0_gt_refclk_0_clk_n;
  wire ctrl0_gt_refclk_0_clk_p;
  wire [127:0]dma0_irq_0;

  cpm6_dma design_1_i
       (.CTRL0_GT_0_grx_n(CTRL0_GT_0_grx_n),
        .CTRL0_GT_0_grx_p(CTRL0_GT_0_grx_p),
        .CTRL0_GT_0_gtx_n(CTRL0_GT_0_gtx_n),
        .CTRL0_GT_0_gtx_p(CTRL0_GT_0_gtx_p),
        .ctrl0_gt_refclk_0_clk_n(ctrl0_gt_refclk_0_clk_n),
        .ctrl0_gt_refclk_0_clk_p(ctrl0_gt_refclk_0_clk_p),
        .dma0_irq_0(dma0_irq_0));
endmodule
