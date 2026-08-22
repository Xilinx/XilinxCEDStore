//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Design : design_1_wrapper_sim_wrapper
//Purpose: NoC Simulation Wrapper netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper_sim_wrapper
   (CTRL1_GT_0_grx_n,
    CTRL1_GT_0_grx_p,
    CTRL1_GT_0_gtx_n,
    CTRL1_GT_0_gtx_p,
    ctrl1_gt_refclk_0_clk_n,
    ctrl1_gt_refclk_0_clk_p,
    dma1_irq_0);
  input [7:0]CTRL1_GT_0_grx_n;
  input [7:0]CTRL1_GT_0_grx_p;
  output [7:0]CTRL1_GT_0_gtx_n;
  output [7:0]CTRL1_GT_0_gtx_p;
  input ctrl1_gt_refclk_0_clk_n;
  input ctrl1_gt_refclk_0_clk_p;
  output [127:0]dma1_irq_0;

  wire [7:0]ctrl1_gt_0_grx_n_net;
  wire [7:0]ctrl1_gt_0_grx_p_net;
  wire [7:0]ctrl1_gt_0_gtx_n_net;
  wire [7:0]ctrl1_gt_0_gtx_p_net;
  wire ctrl1_gt_refclk_0_clk_n_net;
  wire ctrl1_gt_refclk_0_clk_p_net;
  wire [127:0]dma1_irq_0_net;
  wire [0:0]nps_0_mnpp_s_credit_rdy_net;
  wire [7:0]nps_0_mnpp_s_credit_return_net;
  wire [181:0]nps_0_mnpp_s_flit_net;
  wire [7:0]nps_0_mnpp_s_valid_net;
  wire [0:0]nps_0_snpp_s_credit_rdy_net;
  wire [7:0]nps_0_snpp_s_credit_return_net;
  wire [181:0]nps_0_snpp_s_flit_net;
  wire [7:0]nps_0_snpp_s_valid_net;
  wire [0:0]nps_3_mnpp_n_credit_rdy_net;
  wire [7:0]nps_3_mnpp_n_credit_return_net;
  wire [181:0]nps_3_mnpp_n_flit_net;
  wire [7:0]nps_3_mnpp_n_valid_net;
  wire [0:0]nps_3_mnpp_w_credit_rdy_net;
  wire [7:0]nps_3_mnpp_w_credit_return_net;
  wire [181:0]nps_3_mnpp_w_flit_net;
  wire [7:0]nps_3_mnpp_w_valid_net;
  wire [0:0]nps_3_snpp_n_credit_rdy_net;
  wire [7:0]nps_3_snpp_n_credit_return_net;
  wire [181:0]nps_3_snpp_n_flit_net;
  wire [7:0]nps_3_snpp_n_valid_net;
  wire [0:0]nps_3_snpp_w_credit_rdy_net;
  wire [7:0]nps_3_snpp_w_credit_return_net;
  wire [181:0]nps_3_snpp_w_flit_net;
  wire [7:0]nps_3_snpp_w_valid_net;

  assign CTRL1_GT_0_gtx_n[7:0] = ctrl1_gt_0_gtx_n_net;
  assign CTRL1_GT_0_gtx_p[7:0] = ctrl1_gt_0_gtx_p_net;
  assign ctrl1_gt_0_grx_n_net = CTRL1_GT_0_grx_n[7:0];
  assign ctrl1_gt_0_grx_p_net = CTRL1_GT_0_grx_p[7:0];
  assign ctrl1_gt_refclk_0_clk_n_net = ctrl1_gt_refclk_0_clk_n;
  assign ctrl1_gt_refclk_0_clk_p_net = ctrl1_gt_refclk_0_clk_p;
  assign dma1_irq_0[127:0] = dma1_irq_0_net;
  design_1_wrapper design_1_wrapper_i
       (.CTRL1_GT_0_grx_n(ctrl1_gt_0_grx_n_net),
        .CTRL1_GT_0_grx_p(ctrl1_gt_0_grx_p_net),
        .CTRL1_GT_0_gtx_n(ctrl1_gt_0_gtx_n_net),
        .CTRL1_GT_0_gtx_p(ctrl1_gt_0_gtx_p_net),
        .ctrl1_gt_refclk_0_clk_n(ctrl1_gt_refclk_0_clk_n_net),
        .ctrl1_gt_refclk_0_clk_p(ctrl1_gt_refclk_0_clk_p_net),
        .dma1_irq_0(dma1_irq_0_net));
  xlnoc xlnoc_i
       (.nps_0_MNPP_S_credit_rdy(nps_0_mnpp_s_credit_rdy_net),
        .nps_0_MNPP_S_credit_return(nps_0_mnpp_s_credit_return_net),
        .nps_0_MNPP_S_flit(nps_0_mnpp_s_flit_net),
        .nps_0_MNPP_S_valid(nps_0_mnpp_s_valid_net),
        .nps_0_SNPP_S_credit_rdy(nps_0_snpp_s_credit_rdy_net),
        .nps_0_SNPP_S_credit_return(nps_0_snpp_s_credit_return_net),
        .nps_0_SNPP_S_flit(nps_0_snpp_s_flit_net),
        .nps_0_SNPP_S_valid(nps_0_snpp_s_valid_net),
        .nps_3_MNPP_N_credit_rdy(nps_3_mnpp_n_credit_rdy_net),
        .nps_3_MNPP_N_credit_return(nps_3_mnpp_n_credit_return_net),
        .nps_3_MNPP_N_flit(nps_3_mnpp_n_flit_net),
        .nps_3_MNPP_N_valid(nps_3_mnpp_n_valid_net),
        .nps_3_MNPP_W_credit_rdy(nps_3_mnpp_w_credit_rdy_net),
        .nps_3_MNPP_W_credit_return(nps_3_mnpp_w_credit_return_net),
        .nps_3_MNPP_W_flit(nps_3_mnpp_w_flit_net),
        .nps_3_MNPP_W_valid(nps_3_mnpp_w_valid_net),
        .nps_3_SNPP_N_credit_rdy(nps_3_snpp_n_credit_rdy_net),
        .nps_3_SNPP_N_credit_return(nps_3_snpp_n_credit_return_net),
        .nps_3_SNPP_N_flit(nps_3_snpp_n_flit_net),
        .nps_3_SNPP_N_valid(nps_3_snpp_n_valid_net),
        .nps_3_SNPP_W_credit_rdy(nps_3_snpp_w_credit_rdy_net),
        .nps_3_SNPP_W_credit_return(nps_3_snpp_w_credit_return_net),
        .nps_3_SNPP_W_flit(nps_3_snpp_w_flit_net),
        .nps_3_SNPP_W_valid(nps_3_snpp_w_valid_net));

assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_credit_rdy = nps_0_mnpp_s_credit_rdy_net;
assign nps_0_mnpp_s_credit_return_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_credit_return;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_flit = nps_0_mnpp_s_flit_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_valid = nps_0_mnpp_s_valid_net;
assign nps_0_snpp_s_credit_rdy_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_credit_rdy;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_credit_return = nps_0_snpp_s_credit_return_net;
assign nps_0_snpp_s_flit_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_flit;
assign nps_0_snpp_s_valid_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_valid;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_3_mnpp_n_credit_rdy_net;
assign nps_3_mnpp_n_credit_return_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_credit_return;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_flit = nps_3_mnpp_n_flit_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_valid = nps_3_mnpp_n_valid_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_3_mnpp_w_credit_rdy_net;
assign nps_3_mnpp_w_credit_return_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_return;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_flit = nps_3_mnpp_w_flit_net;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_valid = nps_3_mnpp_w_valid_net;
assign nps_3_snpp_n_credit_rdy_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_credit_return = nps_3_snpp_n_credit_return_net;
assign nps_3_snpp_n_flit_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_3_snpp_n_valid_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_valid;
assign nps_3_snpp_w_credit_rdy_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_return = nps_3_snpp_w_credit_return_net;
assign nps_3_snpp_w_flit_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_3_snpp_w_valid_net = design_1_wrapper_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_valid;

endmodule