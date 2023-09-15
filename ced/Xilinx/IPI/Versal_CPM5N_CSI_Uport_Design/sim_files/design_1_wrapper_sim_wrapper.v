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

module design_1_wrapper_sim_wrapper
   (PCIE0_GT_0_grx_n,
    PCIE0_GT_0_grx_p,
    PCIE0_GT_0_gtx_n,
    PCIE0_GT_0_gtx_p,
    gt_refclk0_0_clk_n,
    gt_refclk0_0_clk_p);
  input [15:0]PCIE0_GT_0_grx_n;
  input [15:0]PCIE0_GT_0_grx_p;
  output [15:0]PCIE0_GT_0_gtx_n;
  output [15:0]PCIE0_GT_0_gtx_p;
  input gt_refclk0_0_clk_n;
  input gt_refclk0_0_clk_p;

  wire gt_refclk0_0_clk_n_net;
  wire gt_refclk0_0_clk_p_net;
  wire [0:0]nps_12_mnpp_n_credit_rdy_net;
  wire [7:0]nps_12_mnpp_n_credit_return_net;
  wire [181:0]nps_12_mnpp_n_flit_net;
  wire [7:0]nps_12_mnpp_n_valid_net;
  wire [0:0]nps_12_snpp_n_credit_rdy_net;
  wire [7:0]nps_12_snpp_n_credit_return_net;
  wire [181:0]nps_12_snpp_n_flit_net;
  wire [7:0]nps_12_snpp_n_valid_net;
  wire [0:0]nps_1_mnpp_s_credit_rdy_net;
  wire [7:0]nps_1_mnpp_s_credit_return_net;
  wire [181:0]nps_1_mnpp_s_flit_net;
  wire [7:0]nps_1_mnpp_s_valid_net;
  wire [0:0]nps_1_snpp_s_credit_rdy_net;
  wire [7:0]nps_1_snpp_s_credit_return_net;
  wire [181:0]nps_1_snpp_s_flit_net;
  wire [7:0]nps_1_snpp_s_valid_net;
  wire [0:0]nps_2_mnpp_s_credit_rdy_net;
  wire [7:0]nps_2_mnpp_s_credit_return_net;
  wire [181:0]nps_2_mnpp_s_flit_net;
  wire [7:0]nps_2_mnpp_s_valid_net;
  wire [0:0]nps_2_snpp_s_credit_rdy_net;
  wire [7:0]nps_2_snpp_s_credit_return_net;
  wire [181:0]nps_2_snpp_s_flit_net;
  wire [7:0]nps_2_snpp_s_valid_net;
  wire [0:0]nps_3_mnpp_n_credit_rdy_net;
  wire [7:0]nps_3_mnpp_n_credit_return_net;
  wire [181:0]nps_3_mnpp_n_flit_net;
  wire [7:0]nps_3_mnpp_n_valid_net;
  wire [0:0]nps_3_snpp_n_credit_rdy_net;
  wire [7:0]nps_3_snpp_n_credit_return_net;
  wire [181:0]nps_3_snpp_n_flit_net;
  wire [7:0]nps_3_snpp_n_valid_net;
  wire [0:0]nps_8_mnpp_n_credit_rdy_net;
  wire [7:0]nps_8_mnpp_n_credit_return_net;
  wire [181:0]nps_8_mnpp_n_flit_net;
  wire [7:0]nps_8_mnpp_n_valid_net;
  wire [0:0]nps_8_snpp_n_credit_rdy_net;
  wire [7:0]nps_8_snpp_n_credit_return_net;
  wire [181:0]nps_8_snpp_n_flit_net;
  wire [7:0]nps_8_snpp_n_valid_net;
  wire [0:0]nps_9_mnpp_s_credit_rdy_net;
  wire [7:0]nps_9_mnpp_s_credit_return_net;
  wire [181:0]nps_9_mnpp_s_flit_net;
  wire [7:0]nps_9_mnpp_s_valid_net;
  wire [0:0]nps_9_snpp_s_credit_rdy_net;
  wire [7:0]nps_9_snpp_s_credit_return_net;
  wire [181:0]nps_9_snpp_s_flit_net;
  wire [7:0]nps_9_snpp_s_valid_net;
  wire [15:0]pcie0_gt_0_grx_n_net;
  wire [15:0]pcie0_gt_0_grx_p_net;
  wire [15:0]pcie0_gt_0_gtx_n_net;
  wire [15:0]pcie0_gt_0_gtx_p_net;

  assign PCIE0_GT_0_gtx_n[15:0] = pcie0_gt_0_gtx_n_net;
  assign PCIE0_GT_0_gtx_p[15:0] = pcie0_gt_0_gtx_p_net;
  assign gt_refclk0_0_clk_n_net = gt_refclk0_0_clk_n;
  assign gt_refclk0_0_clk_p_net = gt_refclk0_0_clk_p;
  assign pcie0_gt_0_grx_n_net = PCIE0_GT_0_grx_n[15:0];
  assign pcie0_gt_0_grx_p_net = PCIE0_GT_0_grx_p[15:0];
  design_1_wrapper design_1_wrapper_i
       (.PCIE0_GT_0_grx_n(pcie0_gt_0_grx_n_net),
        .PCIE0_GT_0_grx_p(pcie0_gt_0_grx_p_net),
        .PCIE0_GT_0_gtx_n(pcie0_gt_0_gtx_n_net),
        .PCIE0_GT_0_gtx_p(pcie0_gt_0_gtx_p_net),
        .gt_refclk0_0_clk_n(gt_refclk0_0_clk_n_net),
        .gt_refclk0_0_clk_p(gt_refclk0_0_clk_p_net));
  xlnoc xlnoc_i
       (.nps_12_MNPP_N_credit_rdy(nps_12_mnpp_n_credit_rdy_net),
        .nps_12_MNPP_N_credit_return(nps_12_mnpp_n_credit_return_net),
        .nps_12_MNPP_N_flit(nps_12_mnpp_n_flit_net),
        .nps_12_MNPP_N_valid(nps_12_mnpp_n_valid_net),
        .nps_12_SNPP_N_credit_rdy(nps_12_snpp_n_credit_rdy_net),
        .nps_12_SNPP_N_credit_return(nps_12_snpp_n_credit_return_net),
        .nps_12_SNPP_N_flit(nps_12_snpp_n_flit_net),
        .nps_12_SNPP_N_valid(nps_12_snpp_n_valid_net),
        .nps_1_MNPP_S_credit_rdy(nps_1_mnpp_s_credit_rdy_net),
        .nps_1_MNPP_S_credit_return(nps_1_mnpp_s_credit_return_net),
        .nps_1_MNPP_S_flit(nps_1_mnpp_s_flit_net),
        .nps_1_MNPP_S_valid(nps_1_mnpp_s_valid_net),
        .nps_1_SNPP_S_credit_rdy(nps_1_snpp_s_credit_rdy_net),
        .nps_1_SNPP_S_credit_return(nps_1_snpp_s_credit_return_net),
        .nps_1_SNPP_S_flit(nps_1_snpp_s_flit_net),
        .nps_1_SNPP_S_valid(nps_1_snpp_s_valid_net),
        .nps_2_MNPP_S_credit_rdy(nps_2_mnpp_s_credit_rdy_net),
        .nps_2_MNPP_S_credit_return(nps_2_mnpp_s_credit_return_net),
        .nps_2_MNPP_S_flit(nps_2_mnpp_s_flit_net),
        .nps_2_MNPP_S_valid(nps_2_mnpp_s_valid_net),
        .nps_2_SNPP_S_credit_rdy(nps_2_snpp_s_credit_rdy_net),
        .nps_2_SNPP_S_credit_return(nps_2_snpp_s_credit_return_net),
        .nps_2_SNPP_S_flit(nps_2_snpp_s_flit_net),
        .nps_2_SNPP_S_valid(nps_2_snpp_s_valid_net),
        .nps_3_MNPP_N_credit_rdy(nps_3_mnpp_n_credit_rdy_net),
        .nps_3_MNPP_N_credit_return(nps_3_mnpp_n_credit_return_net),
        .nps_3_MNPP_N_flit(nps_3_mnpp_n_flit_net),
        .nps_3_MNPP_N_valid(nps_3_mnpp_n_valid_net),
        .nps_3_SNPP_N_credit_rdy(nps_3_snpp_n_credit_rdy_net),
        .nps_3_SNPP_N_credit_return(nps_3_snpp_n_credit_return_net),
        .nps_3_SNPP_N_flit(nps_3_snpp_n_flit_net),
        .nps_3_SNPP_N_valid(nps_3_snpp_n_valid_net),
        .nps_8_MNPP_N_credit_rdy(nps_8_mnpp_n_credit_rdy_net),
        .nps_8_MNPP_N_credit_return(nps_8_mnpp_n_credit_return_net),
        .nps_8_MNPP_N_flit(nps_8_mnpp_n_flit_net),
        .nps_8_MNPP_N_valid(nps_8_mnpp_n_valid_net),
        .nps_8_SNPP_N_credit_rdy(nps_8_snpp_n_credit_rdy_net),
        .nps_8_SNPP_N_credit_return(nps_8_snpp_n_credit_return_net),
        .nps_8_SNPP_N_flit(nps_8_snpp_n_flit_net),
        .nps_8_SNPP_N_valid(nps_8_snpp_n_valid_net),
        .nps_9_MNPP_S_credit_rdy(nps_9_mnpp_s_credit_rdy_net),
        .nps_9_MNPP_S_credit_return(nps_9_mnpp_s_credit_return_net),
        .nps_9_MNPP_S_flit(nps_9_mnpp_s_flit_net),
        .nps_9_MNPP_S_valid(nps_9_mnpp_s_valid_net),
        .nps_9_SNPP_S_credit_rdy(nps_9_snpp_s_credit_rdy_net),
        .nps_9_SNPP_S_credit_return(nps_9_snpp_s_credit_return_net),
        .nps_9_SNPP_S_flit(nps_9_snpp_s_flit_net),
        .nps_9_SNPP_S_valid(nps_9_snpp_s_valid_net));

assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_12_mnpp_n_credit_rdy_net;
assign nps_12_mnpp_n_credit_return_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_credit_return;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_flit = nps_12_mnpp_n_flit_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_valid = nps_12_mnpp_n_valid_net;
assign nps_12_snpp_n_credit_rdy_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_credit_return = nps_12_snpp_n_credit_return_net;
assign nps_12_snpp_n_flit_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_12_snpp_n_valid_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_valid;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_1_mnpp_s_credit_rdy_net;
assign nps_1_mnpp_s_credit_return_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_return;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_flit = nps_1_mnpp_s_flit_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_valid = nps_1_mnpp_s_valid_net;
assign nps_1_snpp_s_credit_rdy_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_return = nps_1_snpp_s_credit_return_net;
assign nps_1_snpp_s_flit_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_1_snpp_s_valid_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_valid;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s02_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_2_mnpp_s_credit_rdy_net;
assign nps_2_mnpp_s_credit_return_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s02_axi_nmu_if_noc_npp_in_noc_credit_return;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s02_axi_nmu_if_noc_npp_in_noc_flit = nps_2_mnpp_s_flit_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s02_axi_nmu_if_noc_npp_in_noc_valid = nps_2_mnpp_s_valid_net;
assign nps_2_snpp_s_credit_rdy_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s02_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s02_axi_nmu_if_noc_npp_out_noc_credit_return = nps_2_snpp_s_credit_return_net;
assign nps_2_snpp_s_flit_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s02_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_2_snpp_s_valid_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s02_axi_nmu_if_noc_npp_out_noc_valid;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s03_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_3_mnpp_n_credit_rdy_net;
assign nps_3_mnpp_n_credit_return_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s03_axi_nmu_if_noc_npp_in_noc_credit_return;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s03_axi_nmu_if_noc_npp_in_noc_flit = nps_3_mnpp_n_flit_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s03_axi_nmu_if_noc_npp_in_noc_valid = nps_3_mnpp_n_valid_net;
assign nps_3_snpp_n_credit_rdy_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s03_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s03_axi_nmu_if_noc_npp_out_noc_credit_return = nps_3_snpp_n_credit_return_net;
assign nps_3_snpp_n_flit_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s03_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_3_snpp_n_valid_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s03_axi_nmu_if_noc_npp_out_noc_valid;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s04_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_8_mnpp_n_credit_rdy_net;
assign nps_8_mnpp_n_credit_return_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s04_axi_nmu_if_noc_npp_in_noc_credit_return;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s04_axi_nmu_if_noc_npp_in_noc_flit = nps_8_mnpp_n_flit_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s04_axi_nmu_if_noc_npp_in_noc_valid = nps_8_mnpp_n_valid_net;
assign nps_8_snpp_n_credit_rdy_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s04_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s04_axi_nmu_if_noc_npp_out_noc_credit_return = nps_8_snpp_n_credit_return_net;
assign nps_8_snpp_n_flit_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s04_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_8_snpp_n_valid_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s04_axi_nmu_if_noc_npp_out_noc_valid;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_credit_rdy = nps_9_mnpp_s_credit_rdy_net;
assign nps_9_mnpp_s_credit_return_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_credit_return;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_flit = nps_9_mnpp_s_flit_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_valid = nps_9_mnpp_s_valid_net;
assign nps_9_snpp_s_credit_rdy_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_credit_rdy;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_credit_return = nps_9_snpp_s_credit_return_net;
assign nps_9_snpp_s_flit_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_flit;
assign nps_9_snpp_s_valid_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_valid;

endmodule
