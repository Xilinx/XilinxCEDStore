// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
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
// ////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps

module design_1_wrapper
   (PCIE0_GT_0_grx_n,
    PCIE0_GT_0_grx_p,
    PCIE0_GT_0_gtx_n,
    PCIE0_GT_0_gtx_p,
    gt_refclk0_0_clk_n,
    gt_refclk0_0_clk_p);
  input [7:0]PCIE0_GT_0_grx_n;
  input [7:0]PCIE0_GT_0_grx_p;
  output [7:0]PCIE0_GT_0_gtx_n;
  output [7:0]PCIE0_GT_0_gtx_p;
  input gt_refclk0_0_clk_n;
  input gt_refclk0_0_clk_p;

  wire [7:0]PCIE0_GT_0_grx_n;
  wire [7:0]PCIE0_GT_0_grx_p;
  wire [7:0]PCIE0_GT_0_gtx_n;
  wire [7:0]PCIE0_GT_0_gtx_p;
  wire gt_refclk0_0_clk_n;
  wire gt_refclk0_0_clk_p;

  design_1 design_1_i
       (.PCIE0_GT_0_grx_n(PCIE0_GT_0_grx_n),
        .PCIE0_GT_0_grx_p(PCIE0_GT_0_grx_p),
        .PCIE0_GT_0_gtx_n(PCIE0_GT_0_gtx_n),
        .PCIE0_GT_0_gtx_p(PCIE0_GT_0_gtx_p),
        .gt_refclk0_0_clk_n(gt_refclk0_0_clk_n),
        .gt_refclk0_0_clk_p(gt_refclk0_0_clk_p));
endmodule
