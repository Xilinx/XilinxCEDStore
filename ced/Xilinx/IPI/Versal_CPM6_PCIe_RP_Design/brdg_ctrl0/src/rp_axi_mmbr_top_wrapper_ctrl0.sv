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

// GT bus widths come from rp_link_pkg (src/defines.sv), which run.tcl
// regenerates in the project from CTRL_LINK_WIDTH. At the default X8,
// LINK_WIDTH = 8 and these are [7:0] - identical to the pre-CED wrapper.
module rp_axi_mmbr_top_wrapper_ctrl0
  import rp_link_pkg::*;
(
    input  [LINK_WIDTH-1:0] CTRL0_GT_0_grx_n,
    input  [LINK_WIDTH-1:0] CTRL0_GT_0_grx_p,
    output [LINK_WIDTH-1:0] CTRL0_GT_0_gtx_n,
    output [LINK_WIDTH-1:0] CTRL0_GT_0_gtx_p,
    input                   ctrl0_gt_refclk_0_clk_n,
    input                   ctrl0_gt_refclk_0_clk_p
);

  // PL0 ref clock — brought out of design_1_wrapper. Same domain as the
  // cfg_status outputs, so store_ltssm below needs no CDC.
  (* MARK_DEBUG = "TRUE" *) wire pl0_ref_clk;

  (* MARK_DEBUG = "TRUE" *) wire pcie0_rstn_0;
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

  // ============================================================
  // STORE_LTSSM - per-controller 3-stage pipeline + transition-detect.
  //   ltssmN_reg0 = current sample, _reg1 = prev, _reg2 = prev-prev.
  //   store_ltssmN pulses HIGH for one cycle whenever that controller's
  //   LTSSM state changes - use as ILA trigger / storage qualifier to
  //   capture every transition. Clocked on pl0_ref_clk (the BD-generated
  //   PL clock, same domain as the cfg_status outputs - no CDC needed).
  //   Ctrl0 only here; this design has no Ctrl1.
  // ============================================================
  (* mark_debug = "true", keep = "true" *) wire       store_ltssm0;
  (* mark_debug = "true", keep = "true" *) reg [5:0]  ltssm0_reg0 = 6'b0;
  (* mark_debug = "true", keep = "true" *) reg [5:0]  ltssm0_reg1 = 6'b0;
  (* mark_debug = "true", keep = "true" *) reg [5:0]  ltssm0_reg2 = 6'b0;

  assign store_ltssm0 = (ltssm0_reg0 != ltssm0_reg1);

  always @(posedge pl0_ref_clk) begin
    ltssm0_reg0 <= pcie0_cfg_status_0_smlh_ltssm_state;
    ltssm0_reg1 <= ltssm0_reg0;
    ltssm0_reg2 <= ltssm0_reg1;
  end

    design_1_wrapper design_1_wrapper_inst
   (.CTRL0_GT_0_grx_n   (CTRL0_GT_0_grx_n),
    .CTRL0_GT_0_grx_p   (CTRL0_GT_0_grx_p),
    .CTRL0_GT_0_gtx_n   (CTRL0_GT_0_gtx_n),
    .CTRL0_GT_0_gtx_p   (CTRL0_GT_0_gtx_p),
    .ctrl0_gt_refclk_0_clk_n(ctrl0_gt_refclk_0_clk_n),
    .ctrl0_gt_refclk_0_clk_p(ctrl0_gt_refclk_0_clk_p),
    .pcie0_rstn_0 (pcie0_rstn_0),
    .pl0_ref_clk(pl0_ref_clk),
    .pcie0_cfg_status_0_cfg_neg_link_width(pcie0_cfg_status_0_cfg_neg_link_width),
    .pcie0_cfg_status_0_pf_func_num(pcie0_cfg_status_0_pf_func_num),
    .pcie0_cfg_status_0_pf_info(pcie0_cfg_status_0_pf_info),
    .pcie0_cfg_status_0_pf_sos(pcie0_cfg_status_0_pf_sos),
    .pcie0_cfg_status_0_pf_vld(pcie0_cfg_status_0_pf_vld),
    .pcie0_cfg_status_0_rdlh_link_up(pcie0_cfg_status_0_rdlh_link_up),
    .pcie0_cfg_status_0_smlh_link_up(pcie0_cfg_status_0_smlh_link_up),
    .pcie0_cfg_status_0_smlh_ltssm_state(pcie0_cfg_status_0_smlh_ltssm_state),
    .pcie0_cfg_status_0_vf_func_num(pcie0_cfg_status_0_vf_func_num),
    .pcie0_cfg_status_0_vf_info(pcie0_cfg_status_0_vf_info),
    .pcie0_cfg_status_0_vf_sos(pcie0_cfg_status_0_vf_sos),
    .pcie0_cfg_status_0_vf_vld(pcie0_cfg_status_0_vf_vld)
    );

endmodule
