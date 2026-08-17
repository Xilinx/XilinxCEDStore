//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Design : hdma_ddr_top_sim_wrapper
//Purpose: NoC Simulation Wrapper netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module hdma_ddr_top_sim_wrapper
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
  input [7:0]CTRL1_GT_0_grx_n;
  input [7:0]CTRL1_GT_0_grx_p;
  output [7:0]CTRL1_GT_0_gtx_n;
  output [7:0]CTRL1_GT_0_gtx_p;
  input ctrl1_gt_refclk_0_clk_n;
  input ctrl1_gt_refclk_0_clk_p;
  input [0:0]sys_clk0_0_clk_n;
  input [0:0]sys_clk0_0_clk_p;

  wire [6:0]ch0_lpddr5_0_ca_net;
  wire [0:0]ch0_lpddr5_0_ck_c_net;
  wire [0:0]ch0_lpddr5_0_ck_t_net;
  wire [1:0]ch0_lpddr5_0_cs_net;
  wire [3:0]ch0_lpddr5_0_dmi_net;
  wire [31:0]ch0_lpddr5_0_dq_net;
  wire [3:0]ch0_lpddr5_0_rdqs_c_net;
  wire [3:0]ch0_lpddr5_0_rdqs_t_net;
  wire ch0_lpddr5_0_reset_n_net;
  wire [3:0]ch0_lpddr5_0_wck_c_net;
  wire [3:0]ch0_lpddr5_0_wck_t_net;
  wire [7:0]ctrl1_gt_0_grx_n_net;
  wire [7:0]ctrl1_gt_0_grx_p_net;
  wire [7:0]ctrl1_gt_0_gtx_n_net;
  wire [7:0]ctrl1_gt_0_gtx_p_net;
  wire ctrl1_gt_refclk_0_clk_n_net;
  wire ctrl1_gt_refclk_0_clk_p_net;
  wire [0:0]nps4_2_0_mdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_0_mdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_0_mdmc_npp_0_flit_net;
  wire [1:0]nps4_2_0_mdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_0_mdmc_npp_0_valid_net;
  wire [0:0]nps4_2_0_sdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_0_sdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_0_sdmc_npp_0_flit_net;
  wire [1:0]nps4_2_0_sdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_0_sdmc_npp_0_valid_net;
  wire [0:0]nps_0_mnpp_n_credit_rdy_net;
  wire [7:0]nps_0_mnpp_n_credit_return_net;
  wire [181:0]nps_0_mnpp_n_flit_net;
  wire [7:0]nps_0_mnpp_n_valid_net;
  wire [0:0]nps_0_mnpp_w_credit_rdy_net;
  wire [7:0]nps_0_mnpp_w_credit_return_net;
  wire [181:0]nps_0_mnpp_w_flit_net;
  wire [7:0]nps_0_mnpp_w_valid_net;
  wire [0:0]nps_0_snpp_n_credit_rdy_net;
  wire [7:0]nps_0_snpp_n_credit_return_net;
  wire [181:0]nps_0_snpp_n_flit_net;
  wire [7:0]nps_0_snpp_n_valid_net;
  wire [0:0]nps_0_snpp_w_credit_rdy_net;
  wire [7:0]nps_0_snpp_w_credit_return_net;
  wire [181:0]nps_0_snpp_w_flit_net;
  wire [7:0]nps_0_snpp_w_valid_net;
  wire [0:0]sys_clk0_0_clk_n_net;
  wire [0:0]sys_clk0_0_clk_p_net;

  assign CH0_LPDDR5_0_ca[6:0] = ch0_lpddr5_0_ca_net;
  assign CH0_LPDDR5_0_ck_c[0] = ch0_lpddr5_0_ck_c_net;
  assign CH0_LPDDR5_0_ck_t[0] = ch0_lpddr5_0_ck_t_net;
  assign CH0_LPDDR5_0_cs[1:0] = ch0_lpddr5_0_cs_net;
  assign CH0_LPDDR5_0_reset_n = ch0_lpddr5_0_reset_n_net;
  assign CH0_LPDDR5_0_wck_c[3:0] = ch0_lpddr5_0_wck_c_net;
  assign CH0_LPDDR5_0_wck_t[3:0] = ch0_lpddr5_0_wck_t_net;
  assign CTRL1_GT_0_gtx_n[7:0] = ctrl1_gt_0_gtx_n_net;
  assign CTRL1_GT_0_gtx_p[7:0] = ctrl1_gt_0_gtx_p_net;
  assign ch0_lpddr5_0_rdqs_c_net = CH0_LPDDR5_0_rdqs_c[3:0];
  assign ch0_lpddr5_0_rdqs_t_net = CH0_LPDDR5_0_rdqs_t[3:0];
  assign ctrl1_gt_0_grx_n_net = CTRL1_GT_0_grx_n[7:0];
  assign ctrl1_gt_0_grx_p_net = CTRL1_GT_0_grx_p[7:0];
  assign ctrl1_gt_refclk_0_clk_n_net = ctrl1_gt_refclk_0_clk_n;
  assign ctrl1_gt_refclk_0_clk_p_net = ctrl1_gt_refclk_0_clk_p;
  assign sys_clk0_0_clk_n_net = sys_clk0_0_clk_n[0];
  assign sys_clk0_0_clk_p_net = sys_clk0_0_clk_p[0];
  hdma_ddr_top hdma_ddr_top_i
       (.CH0_LPDDR5_0_ca(ch0_lpddr5_0_ca_net),
        .CH0_LPDDR5_0_ck_c(ch0_lpddr5_0_ck_c_net),
        .CH0_LPDDR5_0_ck_t(ch0_lpddr5_0_ck_t_net),
        .CH0_LPDDR5_0_cs(ch0_lpddr5_0_cs_net),
        .CH0_LPDDR5_0_dmi(CH0_LPDDR5_0_dmi[3:0]),
        .CH0_LPDDR5_0_dq(CH0_LPDDR5_0_dq[31:0]),
        .CH0_LPDDR5_0_rdqs_c(ch0_lpddr5_0_rdqs_c_net),
        .CH0_LPDDR5_0_rdqs_t(ch0_lpddr5_0_rdqs_t_net),
        .CH0_LPDDR5_0_reset_n(ch0_lpddr5_0_reset_n_net),
        .CH0_LPDDR5_0_wck_c(ch0_lpddr5_0_wck_c_net),
        .CH0_LPDDR5_0_wck_t(ch0_lpddr5_0_wck_t_net),
        .CTRL1_GT_0_grx_n(ctrl1_gt_0_grx_n_net),
        .CTRL1_GT_0_grx_p(ctrl1_gt_0_grx_p_net),
        .CTRL1_GT_0_gtx_n(ctrl1_gt_0_gtx_n_net),
        .CTRL1_GT_0_gtx_p(ctrl1_gt_0_gtx_p_net),
        .ctrl1_gt_refclk_0_clk_n(ctrl1_gt_refclk_0_clk_n_net),
        .ctrl1_gt_refclk_0_clk_p(ctrl1_gt_refclk_0_clk_p_net),
        .sys_clk0_0_clk_n(sys_clk0_0_clk_n_net),
        .sys_clk0_0_clk_p(sys_clk0_0_clk_p_net));
  xlnoc xlnoc_i
       (.nps4_2_0_MDMC_NPP_0_credit_rdy(nps4_2_0_mdmc_npp_0_credit_rdy_net),
        .nps4_2_0_MDMC_NPP_0_credit_return(nps4_2_0_mdmc_npp_0_credit_return_net),
        .nps4_2_0_MDMC_NPP_0_flit(nps4_2_0_mdmc_npp_0_flit_net),
        .nps4_2_0_MDMC_NPP_0_pdest_id(nps4_2_0_mdmc_npp_0_pdest_id_net),
        .nps4_2_0_MDMC_NPP_0_valid(nps4_2_0_mdmc_npp_0_valid_net),
        .nps4_2_0_SDMC_NPP_0_credit_rdy(nps4_2_0_sdmc_npp_0_credit_rdy_net),
        .nps4_2_0_SDMC_NPP_0_credit_return(nps4_2_0_sdmc_npp_0_credit_return_net),
        .nps4_2_0_SDMC_NPP_0_flit(nps4_2_0_sdmc_npp_0_flit_net),
        .nps4_2_0_SDMC_NPP_0_pdest_id(nps4_2_0_sdmc_npp_0_pdest_id_net),
        .nps4_2_0_SDMC_NPP_0_valid(nps4_2_0_sdmc_npp_0_valid_net),
        .nps_0_MNPP_N_credit_rdy(nps_0_mnpp_n_credit_rdy_net),
        .nps_0_MNPP_N_credit_return(nps_0_mnpp_n_credit_return_net),
        .nps_0_MNPP_N_flit(nps_0_mnpp_n_flit_net),
        .nps_0_MNPP_N_valid(nps_0_mnpp_n_valid_net),
        .nps_0_MNPP_W_credit_rdy(nps_0_mnpp_w_credit_rdy_net),
        .nps_0_MNPP_W_credit_return(nps_0_mnpp_w_credit_return_net),
        .nps_0_MNPP_W_flit(nps_0_mnpp_w_flit_net),
        .nps_0_MNPP_W_valid(nps_0_mnpp_w_valid_net),
        .nps_0_SNPP_N_credit_rdy(nps_0_snpp_n_credit_rdy_net),
        .nps_0_SNPP_N_credit_return(nps_0_snpp_n_credit_return_net),
        .nps_0_SNPP_N_flit(nps_0_snpp_n_flit_net),
        .nps_0_SNPP_N_valid(nps_0_snpp_n_valid_net),
        .nps_0_SNPP_W_credit_rdy(nps_0_snpp_w_credit_rdy_net),
        .nps_0_SNPP_W_credit_return(nps_0_snpp_w_credit_return_net),
        .nps_0_SNPP_W_flit(nps_0_snpp_w_flit_net),
        .nps_0_SNPP_W_valid(nps_0_snpp_w_valid_net));

assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_noc2dmc_credit_rdy_0 = nps4_2_0_mdmc_npp_0_credit_rdy_net;
assign nps4_2_0_mdmc_npp_0_credit_return_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_noc2dmc_credit_rtn_0;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_noc2dmc_data_in_0 = nps4_2_0_mdmc_npp_0_flit_net;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_noc2dmc_pdest_id_in_0 = nps4_2_0_mdmc_npp_0_pdest_id_net;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_noc2dmc_valid_in_0 = nps4_2_0_mdmc_npp_0_valid_net;
assign nps4_2_0_sdmc_npp_0_credit_rdy_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_dmc2noc_credit_rdy_0;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_dmc2noc_credit_rtn_0 = nps4_2_0_sdmc_npp_0_credit_return_net;
assign nps4_2_0_sdmc_npp_0_flit_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_dmc2noc_data_out_0;
assign nps4_2_0_sdmc_npp_0_pdest_id_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_dmc2noc_pdest_id_out_0;
assign nps4_2_0_sdmc_npp_0_valid_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.mc0_ddrc_dmc2noc_valid_out_0;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_0_mnpp_n_credit_rdy_net;
assign nps_0_mnpp_n_credit_return_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_credit_return;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_flit = nps_0_mnpp_n_flit_net;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_in_noc_valid = nps_0_mnpp_n_valid_net;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_0_mnpp_w_credit_rdy_net;
assign nps_0_mnpp_w_credit_return_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_return;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_flit = nps_0_mnpp_w_flit_net;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_valid = nps_0_mnpp_w_valid_net;
assign nps_0_snpp_n_credit_rdy_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_credit_return = nps_0_snpp_n_credit_return_net;
assign nps_0_snpp_n_flit_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_0_snpp_n_valid_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s01_axi_nmu_if_noc_npp_out_noc_valid;
assign nps_0_snpp_w_credit_rdy_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_return = nps_0_snpp_w_credit_return_net;
assign nps_0_snpp_w_flit_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_0_snpp_w_valid_net = hdma_ddr_top_i.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_valid;

endmodule
