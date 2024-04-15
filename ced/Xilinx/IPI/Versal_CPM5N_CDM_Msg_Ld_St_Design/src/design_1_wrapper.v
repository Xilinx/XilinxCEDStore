//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1.0 (lin64) Build 3709180 Mon Nov 28 19:00:12 MST 2022
//Date        : Tue Nov 29 11:56:43 2022
//Host        : xsjrdevl155 running 64-bit CentOS Linux release 7.5.1804 (Core)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (CH0_LPDDR5_ca,
    CH0_LPDDR5_ck_c,
    CH0_LPDDR5_ck_t,
    CH0_LPDDR5_cs,
    CH0_LPDDR5_dmi,
    CH0_LPDDR5_dq,
    CH0_LPDDR5_rdqs_c,
    CH0_LPDDR5_rdqs_t,
    CH0_LPDDR5_reset_n,
    CH0_LPDDR5_wck_c,
    CH0_LPDDR5_wck_t,
    CH1_LPDDR5_ca,
    CH1_LPDDR5_ck_c,
    CH1_LPDDR5_ck_t,
    CH1_LPDDR5_cs,
    CH1_LPDDR5_dmi,
    CH1_LPDDR5_dq,
    CH1_LPDDR5_rdqs_c,
    CH1_LPDDR5_rdqs_t,
    CH1_LPDDR5_wck_c,
    CH1_LPDDR5_wck_t,
    PCIE0_GT_grx_n,
    PCIE0_GT_grx_p,
    PCIE0_GT_gtx_n,
    PCIE0_GT_gtx_p,
    atg_axi_araddr,
    atg_axi_arburst,
    atg_axi_arcache,
    atg_axi_arid,
    atg_axi_arlen,
    atg_axi_arlock,
    atg_axi_arprot,
    atg_axi_arqos,
    atg_axi_arready,
    atg_axi_arregion,
    atg_axi_arsize,
    atg_axi_aruser,
    atg_axi_arvalid,
    atg_axi_awaddr,
    atg_axi_awburst,
    atg_axi_awcache,
    atg_axi_awid,
    atg_axi_awlen,
    atg_axi_awlock,
    atg_axi_awprot,
    atg_axi_awqos,
    atg_axi_awready,
    atg_axi_awregion,
    atg_axi_awsize,
    atg_axi_awuser,
    atg_axi_awvalid,
    atg_axi_bid,
    atg_axi_bready,
    atg_axi_bresp,
    atg_axi_bvalid,
    atg_axi_rdata,
    atg_axi_rid,
    atg_axi_rlast,
    atg_axi_rready,
    atg_axi_rresp,
    atg_axi_rvalid,
    atg_axi_wdata,
    atg_axi_wlast,
    atg_axi_wready,
    atg_axi_wstrb,
    atg_axi_wvalid,
    axil_cmdram_araddr,
    axil_cmdram_arprot,
    axil_cmdram_arready,
    axil_cmdram_arvalid,
    axil_cmdram_awaddr,
    axil_cmdram_awprot,
    axil_cmdram_awready,
    axil_cmdram_awvalid,
    axil_cmdram_bready,
    axil_cmdram_bresp,
    axil_cmdram_bvalid,
    axil_cmdram_rdata,
    axil_cmdram_rready,
    axil_cmdram_rresp,
    axil_cmdram_rvalid,
    axil_cmdram_wdata,
    axil_cmdram_wready,
    axil_cmdram_wstrb,
    axil_cmdram_wvalid,
    axil_csi_exdes_araddr,
    axil_csi_exdes_arprot,
    axil_csi_exdes_arready,
    axil_csi_exdes_arvalid,
    axil_csi_exdes_awaddr,
    axil_csi_exdes_awprot,
    axil_csi_exdes_awready,
    axil_csi_exdes_awvalid,
    axil_csi_exdes_bready,
    axil_csi_exdes_bresp,
    axil_csi_exdes_bvalid,
    axil_csi_exdes_rdata,
    axil_csi_exdes_rready,
    axil_csi_exdes_rresp,
    axil_csi_exdes_rvalid,
    axil_csi_exdes_wdata,
    axil_csi_exdes_wready,
    axil_csi_exdes_wstrb,
    axil_csi_exdes_wvalid,
    cdm_top_msgld_dat_client_id,
    cdm_top_msgld_dat_data,
    cdm_top_msgld_dat_ecc,
    cdm_top_msgld_dat_eop,
    cdm_top_msgld_dat_err_status,
    cdm_top_msgld_dat_error,
    cdm_top_msgld_dat_mty,
    cdm_top_msgld_dat_rc_id,
    cdm_top_msgld_dat_rdy,
    cdm_top_msgld_dat_response_cookie,
    cdm_top_msgld_dat_start_offset,
    cdm_top_msgld_dat_status,
    cdm_top_msgld_dat_vld,
    cdm_top_msgld_dat_zero_byte,
    cdm_top_msgld_req_addr,
    cdm_top_msgld_req_addr_spc,
    cdm_top_msgld_req_attr,
    cdm_top_msgld_req_client_id,
    cdm_top_msgld_req_data_width,
    cdm_top_msgld_req_if_op,
    cdm_top_msgld_req_length,
    cdm_top_msgld_req_op,
    cdm_top_msgld_req_rc_id,
    cdm_top_msgld_req_rdy,
    cdm_top_msgld_req_relaxed_read,
    cdm_top_msgld_req_response_cookie,
    cdm_top_msgld_req_start_offset,
    cdm_top_msgld_req_vld,
    cdm_top_msgst_addr,
    cdm_top_msgst_addr_spc,
    cdm_top_msgst_attr,
    cdm_top_msgst_client_id,
    cdm_top_msgst_data,
    cdm_top_msgst_data_width,
    cdm_top_msgst_ecc,
    cdm_top_msgst_eop,
    cdm_top_msgst_irq_vector,
    cdm_top_msgst_length,
    cdm_top_msgst_op,
    cdm_top_msgst_rdy,
    cdm_top_msgst_response_cookie,
    cdm_top_msgst_response_req,
    cdm_top_msgst_st2m_ordered,
    cdm_top_msgst_start_offset,
    cdm_top_msgst_tph,
    cdm_top_msgst_vld,
    cdm_top_msgst_wait_pld_pkt_id,
    cpm_gpo,
    csi1_dst_crdt_tdata,
    csi1_dst_crdt_tready,
    csi1_dst_crdt_tvalid,
    csi1_es1_wa_en,
    csi1_local_crdt_buf_id,
    csi1_local_crdt_data,
    csi1_local_crdt_flow_type,
    csi1_local_crdt_rdy,
    csi1_local_crdt_snk_id,
    csi1_local_crdt_src_furc_id,
    csi1_local_crdt_vld,
    csi1_npr_req_eop,
    csi1_npr_req_err,
    csi1_npr_req_rdy,
    csi1_npr_req_seg,
    csi1_npr_req_sop,
    csi1_npr_req_vld,
    csi1_prcmpl_req0_eop,
    csi1_prcmpl_req0_err,
    csi1_prcmpl_req0_rdy,
    csi1_prcmpl_req0_seg,
    csi1_prcmpl_req0_sop,
    csi1_prcmpl_req0_vld,
    csi1_prcmpl_req1_eop,
    csi1_prcmpl_req1_err,
    csi1_prcmpl_req1_rdy,
    csi1_prcmpl_req1_seg,
    csi1_prcmpl_req1_sop,
    csi1_prcmpl_req1_vld,
    csi1_resp0_eop,
    csi1_resp0_err,
    csi1_resp0_rdy,
    csi1_resp0_seg,
    csi1_resp0_sop,
    csi1_resp0_vld,
    csi1_resp1_eop,
    csi1_resp1_err,
    csi1_resp1_rdy,
    csi1_resp1_seg,
    csi1_resp1_sop,
    csi1_resp1_vld,
    gt_refclk0_clk_n,
    gt_refclk0_clk_p,
    pl0_ref_clk_0,
    pl0_resetn_0,
    sys_clk_ddr_clk_n,
    sys_clk_ddr_clk_p);
  output [6:0]CH0_LPDDR5_ca;
  output [0:0]CH0_LPDDR5_ck_c;
  output [0:0]CH0_LPDDR5_ck_t;
  output [0:0]CH0_LPDDR5_cs;
  inout [1:0]CH0_LPDDR5_dmi;
  inout [15:0]CH0_LPDDR5_dq;
  input [1:0]CH0_LPDDR5_rdqs_c;
  input [1:0]CH0_LPDDR5_rdqs_t;
  output CH0_LPDDR5_reset_n;
  output [1:0]CH0_LPDDR5_wck_c;
  output [1:0]CH0_LPDDR5_wck_t;
  output [6:0]CH1_LPDDR5_ca;
  output [0:0]CH1_LPDDR5_ck_c;
  output [0:0]CH1_LPDDR5_ck_t;
  output [0:0]CH1_LPDDR5_cs;
  inout [1:0]CH1_LPDDR5_dmi;
  inout [15:0]CH1_LPDDR5_dq;
  input [1:0]CH1_LPDDR5_rdqs_c;
  input [1:0]CH1_LPDDR5_rdqs_t;
  output [1:0]CH1_LPDDR5_wck_c;
  output [1:0]CH1_LPDDR5_wck_t;
  input [15:0]PCIE0_GT_grx_n;
  input [15:0]PCIE0_GT_grx_p;
  output [15:0]PCIE0_GT_gtx_n;
  output [15:0]PCIE0_GT_gtx_p;
  input [63:0]atg_axi_araddr;
  input [1:0]atg_axi_arburst;
  input [3:0]atg_axi_arcache;
  input [0:0]atg_axi_arid;
  input [7:0]atg_axi_arlen;
  input [0:0]atg_axi_arlock;
  input [2:0]atg_axi_arprot;
  input [3:0]atg_axi_arqos;
  output [0:0]atg_axi_arready;
  input [3:0]atg_axi_arregion;
  input [2:0]atg_axi_arsize;
  input [7:0]atg_axi_aruser;
  input [0:0]atg_axi_arvalid;
  input [63:0]atg_axi_awaddr;
  input [1:0]atg_axi_awburst;
  input [3:0]atg_axi_awcache;
  input [0:0]atg_axi_awid;
  input [7:0]atg_axi_awlen;
  input [0:0]atg_axi_awlock;
  input [2:0]atg_axi_awprot;
  input [3:0]atg_axi_awqos;
  output [0:0]atg_axi_awready;
  input [3:0]atg_axi_awregion;
  input [2:0]atg_axi_awsize;
  input [7:0]atg_axi_awuser;
  input [0:0]atg_axi_awvalid;
  output [0:0]atg_axi_bid;
  input [0:0]atg_axi_bready;
  output [1:0]atg_axi_bresp;
  output [0:0]atg_axi_bvalid;
  output [511:0]atg_axi_rdata;
  output [0:0]atg_axi_rid;
  output [0:0]atg_axi_rlast;
  input [0:0]atg_axi_rready;
  output [1:0]atg_axi_rresp;
  output [0:0]atg_axi_rvalid;
  input [511:0]atg_axi_wdata;
  input [0:0]atg_axi_wlast;
  output [0:0]atg_axi_wready;
  input [63:0]atg_axi_wstrb;
  input [0:0]atg_axi_wvalid;
  output [41:0]axil_cmdram_araddr;
  output [2:0]axil_cmdram_arprot;
  input axil_cmdram_arready;
  output axil_cmdram_arvalid;
  output [41:0]axil_cmdram_awaddr;
  output [2:0]axil_cmdram_awprot;
  input axil_cmdram_awready;
  output axil_cmdram_awvalid;
  output axil_cmdram_bready;
  input [1:0]axil_cmdram_bresp;
  input axil_cmdram_bvalid;
  input [31:0]axil_cmdram_rdata;
  output axil_cmdram_rready;
  input [1:0]axil_cmdram_rresp;
  input axil_cmdram_rvalid;
  output [31:0]axil_cmdram_wdata;
  input axil_cmdram_wready;
  output [3:0]axil_cmdram_wstrb;
  output axil_cmdram_wvalid;
  output [41:0]axil_csi_exdes_araddr;
  output [2:0]axil_csi_exdes_arprot;
  input axil_csi_exdes_arready;
  output axil_csi_exdes_arvalid;
  output [41:0]axil_csi_exdes_awaddr;
  output [2:0]axil_csi_exdes_awprot;
  input axil_csi_exdes_awready;
  output axil_csi_exdes_awvalid;
  output axil_csi_exdes_bready;
  input [1:0]axil_csi_exdes_bresp;
  input axil_csi_exdes_bvalid;
  input [31:0]axil_csi_exdes_rdata;
  output axil_csi_exdes_rready;
  input [1:0]axil_csi_exdes_rresp;
  input axil_csi_exdes_rvalid;
  output [31:0]axil_csi_exdes_wdata;
  input axil_csi_exdes_wready;
  output [3:0]axil_csi_exdes_wstrb;
  output axil_csi_exdes_wvalid;
  output [3:0]cdm_top_msgld_dat_client_id;
  output [255:0]cdm_top_msgld_dat_data;
  output [9:0]cdm_top_msgld_dat_ecc;
  output cdm_top_msgld_dat_eop;
  output [2:0]cdm_top_msgld_dat_err_status;
  output cdm_top_msgld_dat_error;
  output [4:0]cdm_top_msgld_dat_mty;
  output [5:0]cdm_top_msgld_dat_rc_id;
  input cdm_top_msgld_dat_rdy;
  output [11:0]cdm_top_msgld_dat_response_cookie;
  output [4:0]cdm_top_msgld_dat_start_offset;
  output [1:0]cdm_top_msgld_dat_status;
  output cdm_top_msgld_dat_vld;
  output cdm_top_msgld_dat_zero_byte;
  input [65:0]cdm_top_msgld_req_addr;
  input [53:0]cdm_top_msgld_req_addr_spc;
  input [2:0]cdm_top_msgld_req_attr;
  input [3:0]cdm_top_msgld_req_client_id;
  input cdm_top_msgld_req_data_width;
  input [1:0]cdm_top_msgld_req_if_op;
  input [8:0]cdm_top_msgld_req_length;
  input [1:0]cdm_top_msgld_req_op;
  input [5:0]cdm_top_msgld_req_rc_id;
  output cdm_top_msgld_req_rdy;
  input cdm_top_msgld_req_relaxed_read;
  input [11:0]cdm_top_msgld_req_response_cookie;
  input [4:0]cdm_top_msgld_req_start_offset;
  input cdm_top_msgld_req_vld;
  input [65:0]cdm_top_msgst_addr;
  input [53:0]cdm_top_msgst_addr_spc;
  input [2:0]cdm_top_msgst_attr;
  input [3:0]cdm_top_msgst_client_id;
  input [255:0]cdm_top_msgst_data;
  input [1:0]cdm_top_msgst_data_width;
  input [10:0]cdm_top_msgst_ecc;
  input cdm_top_msgst_eop;
  input [15:0]cdm_top_msgst_irq_vector;
  input [8:0]cdm_top_msgst_length;
  input [1:0]cdm_top_msgst_op;
  output cdm_top_msgst_rdy;
  input [11:0]cdm_top_msgst_response_cookie;
  input cdm_top_msgst_response_req;
  input cdm_top_msgst_st2m_ordered;
  input [3:0]cdm_top_msgst_start_offset;
  input [10:0]cdm_top_msgst_tph;
  input cdm_top_msgst_vld;
  input [15:0]cdm_top_msgst_wait_pld_pkt_id;
  output [31:0]cpm_gpo;
  input [21:0]csi1_dst_crdt_tdata;
  output csi1_dst_crdt_tready;
  input csi1_dst_crdt_tvalid;
  input csi1_es1_wa_en;
  output [6:0]csi1_local_crdt_buf_id;
  output [15:0]csi1_local_crdt_data;
  output [1:0]csi1_local_crdt_flow_type;
  input csi1_local_crdt_rdy;
  output [1:0]csi1_local_crdt_snk_id;
  output [1:0]csi1_local_crdt_src_furc_id;
  output csi1_local_crdt_vld;
  input csi1_npr_req_eop;
  input csi1_npr_req_err;
  output csi1_npr_req_rdy;
  input [319:0]csi1_npr_req_seg;
  input csi1_npr_req_sop;
  input csi1_npr_req_vld;
  input csi1_prcmpl_req0_eop;
  input csi1_prcmpl_req0_err;
  output csi1_prcmpl_req0_rdy;
  input [319:0]csi1_prcmpl_req0_seg;
  input csi1_prcmpl_req0_sop;
  input csi1_prcmpl_req0_vld;
  input csi1_prcmpl_req1_eop;
  input csi1_prcmpl_req1_err;
  output csi1_prcmpl_req1_rdy;
  input [319:0]csi1_prcmpl_req1_seg;
  input csi1_prcmpl_req1_sop;
  input csi1_prcmpl_req1_vld;
  output csi1_resp0_eop;
  output csi1_resp0_err;
  input csi1_resp0_rdy;
  output [319:0]csi1_resp0_seg;
  output csi1_resp0_sop;
  output csi1_resp0_vld;
  output csi1_resp1_eop;
  output csi1_resp1_err;
  input csi1_resp1_rdy;
  output [319:0]csi1_resp1_seg;
  output csi1_resp1_sop;
  output csi1_resp1_vld;
  input gt_refclk0_clk_n;
  input gt_refclk0_clk_p;
  output pl0_ref_clk_0;
  output pl0_resetn_0;
  input [0:0]sys_clk_ddr_clk_n;
  input [0:0]sys_clk_ddr_clk_p;

  wire [6:0]CH0_LPDDR5_ca;
  wire [0:0]CH0_LPDDR5_ck_c;
  wire [0:0]CH0_LPDDR5_ck_t;
  wire [0:0]CH0_LPDDR5_cs;
  wire [1:0]CH0_LPDDR5_dmi;
  wire [15:0]CH0_LPDDR5_dq;
  wire [1:0]CH0_LPDDR5_rdqs_c;
  wire [1:0]CH0_LPDDR5_rdqs_t;
  wire CH0_LPDDR5_reset_n;
  wire [1:0]CH0_LPDDR5_wck_c;
  wire [1:0]CH0_LPDDR5_wck_t;
  wire [6:0]CH1_LPDDR5_ca;
  wire [0:0]CH1_LPDDR5_ck_c;
  wire [0:0]CH1_LPDDR5_ck_t;
  wire [0:0]CH1_LPDDR5_cs;
  wire [1:0]CH1_LPDDR5_dmi;
  wire [15:0]CH1_LPDDR5_dq;
  wire [1:0]CH1_LPDDR5_rdqs_c;
  wire [1:0]CH1_LPDDR5_rdqs_t;
  wire [1:0]CH1_LPDDR5_wck_c;
  wire [1:0]CH1_LPDDR5_wck_t;
  wire [15:0]PCIE0_GT_grx_n;
  wire [15:0]PCIE0_GT_grx_p;
  wire [15:0]PCIE0_GT_gtx_n;
  wire [15:0]PCIE0_GT_gtx_p;
  wire [63:0]atg_axi_araddr;
  wire [1:0]atg_axi_arburst;
  wire [3:0]atg_axi_arcache;
  wire [0:0]atg_axi_arid;
  wire [7:0]atg_axi_arlen;
  wire [0:0]atg_axi_arlock;
  wire [2:0]atg_axi_arprot;
  wire [3:0]atg_axi_arqos;
  wire [0:0]atg_axi_arready;
  wire [3:0]atg_axi_arregion;
  wire [2:0]atg_axi_arsize;
  wire [7:0]atg_axi_aruser;
  wire [0:0]atg_axi_arvalid;
  wire [63:0]atg_axi_awaddr;
  wire [1:0]atg_axi_awburst;
  wire [3:0]atg_axi_awcache;
  wire [0:0]atg_axi_awid;
  wire [7:0]atg_axi_awlen;
  wire [0:0]atg_axi_awlock;
  wire [2:0]atg_axi_awprot;
  wire [3:0]atg_axi_awqos;
  wire [0:0]atg_axi_awready;
  wire [3:0]atg_axi_awregion;
  wire [2:0]atg_axi_awsize;
  wire [7:0]atg_axi_awuser;
  wire [0:0]atg_axi_awvalid;
  wire [0:0]atg_axi_bid;
  wire [0:0]atg_axi_bready;
  wire [1:0]atg_axi_bresp;
  wire [0:0]atg_axi_bvalid;
  wire [511:0]atg_axi_rdata;
  wire [0:0]atg_axi_rid;
  wire [0:0]atg_axi_rlast;
  wire [0:0]atg_axi_rready;
  wire [1:0]atg_axi_rresp;
  wire [0:0]atg_axi_rvalid;
  wire [511:0]atg_axi_wdata;
  wire [0:0]atg_axi_wlast;
  wire [0:0]atg_axi_wready;
  wire [63:0]atg_axi_wstrb;
  wire [0:0]atg_axi_wvalid;
  wire [41:0]axil_cmdram_araddr;
  wire [2:0]axil_cmdram_arprot;
  wire axil_cmdram_arready;
  wire axil_cmdram_arvalid;
  wire [41:0]axil_cmdram_awaddr;
  wire [2:0]axil_cmdram_awprot;
  wire axil_cmdram_awready;
  wire axil_cmdram_awvalid;
  wire axil_cmdram_bready;
  wire [1:0]axil_cmdram_bresp;
  wire axil_cmdram_bvalid;
  wire [31:0]axil_cmdram_rdata;
  wire axil_cmdram_rready;
  wire [1:0]axil_cmdram_rresp;
  wire axil_cmdram_rvalid;
  wire [31:0]axil_cmdram_wdata;
  wire axil_cmdram_wready;
  wire [3:0]axil_cmdram_wstrb;
  wire axil_cmdram_wvalid;
  wire [41:0]axil_csi_exdes_araddr;
  wire [2:0]axil_csi_exdes_arprot;
  wire axil_csi_exdes_arready;
  wire axil_csi_exdes_arvalid;
  wire [41:0]axil_csi_exdes_awaddr;
  wire [2:0]axil_csi_exdes_awprot;
  wire axil_csi_exdes_awready;
  wire axil_csi_exdes_awvalid;
  wire axil_csi_exdes_bready;
  wire [1:0]axil_csi_exdes_bresp;
  wire axil_csi_exdes_bvalid;
  wire [31:0]axil_csi_exdes_rdata;
  wire axil_csi_exdes_rready;
  wire [1:0]axil_csi_exdes_rresp;
  wire axil_csi_exdes_rvalid;
  wire [31:0]axil_csi_exdes_wdata;
  wire axil_csi_exdes_wready;
  wire [3:0]axil_csi_exdes_wstrb;
  wire axil_csi_exdes_wvalid;
  wire [3:0]cdm_top_msgld_dat_client_id;
  wire [255:0]cdm_top_msgld_dat_data;
  wire [9:0]cdm_top_msgld_dat_ecc;
  wire cdm_top_msgld_dat_eop;
  wire [2:0]cdm_top_msgld_dat_err_status;
  wire cdm_top_msgld_dat_error;
  wire [4:0]cdm_top_msgld_dat_mty;
  wire [5:0]cdm_top_msgld_dat_rc_id;
  wire cdm_top_msgld_dat_rdy;
  wire [11:0]cdm_top_msgld_dat_response_cookie;
  wire [4:0]cdm_top_msgld_dat_start_offset;
  wire [1:0]cdm_top_msgld_dat_status;
  wire cdm_top_msgld_dat_vld;
  wire cdm_top_msgld_dat_zero_byte;
  wire [65:0]cdm_top_msgld_req_addr;
  wire [53:0]cdm_top_msgld_req_addr_spc;
  wire [2:0]cdm_top_msgld_req_attr;
  wire [3:0]cdm_top_msgld_req_client_id;
  wire cdm_top_msgld_req_data_width;
  wire [1:0]cdm_top_msgld_req_if_op;
  wire [8:0]cdm_top_msgld_req_length;
  wire [1:0]cdm_top_msgld_req_op;
  wire [5:0]cdm_top_msgld_req_rc_id;
  wire cdm_top_msgld_req_rdy;
  wire cdm_top_msgld_req_relaxed_read;
  wire [11:0]cdm_top_msgld_req_response_cookie;
  wire [4:0]cdm_top_msgld_req_start_offset;
  wire cdm_top_msgld_req_vld;
  wire [65:0]cdm_top_msgst_addr;
  wire [53:0]cdm_top_msgst_addr_spc;
  wire [2:0]cdm_top_msgst_attr;
  wire [3:0]cdm_top_msgst_client_id;
  wire [255:0]cdm_top_msgst_data;
  wire [1:0]cdm_top_msgst_data_width;
  wire [10:0]cdm_top_msgst_ecc;
  wire cdm_top_msgst_eop;
  wire [15:0]cdm_top_msgst_irq_vector;
  wire [8:0]cdm_top_msgst_length;
  wire [1:0]cdm_top_msgst_op;
  wire cdm_top_msgst_rdy;
  wire [11:0]cdm_top_msgst_response_cookie;
  wire cdm_top_msgst_response_req;
  wire cdm_top_msgst_st2m_ordered;
  wire [3:0]cdm_top_msgst_start_offset;
  wire [10:0]cdm_top_msgst_tph;
  wire cdm_top_msgst_vld;
  wire [15:0]cdm_top_msgst_wait_pld_pkt_id;
  wire [31:0]cpm_gpo;
  wire [21:0]csi1_dst_crdt_tdata;
  wire csi1_dst_crdt_tready;
  wire csi1_dst_crdt_tvalid;
  wire csi1_es1_wa_en;
  wire [6:0]csi1_local_crdt_buf_id;
  wire [15:0]csi1_local_crdt_data;
  wire [1:0]csi1_local_crdt_flow_type;
  wire csi1_local_crdt_rdy;
  wire [1:0]csi1_local_crdt_snk_id;
  wire [1:0]csi1_local_crdt_src_furc_id;
  wire csi1_local_crdt_vld;
  wire csi1_npr_req_eop;
  wire csi1_npr_req_err;
  wire csi1_npr_req_rdy;
  wire [319:0]csi1_npr_req_seg;
  wire csi1_npr_req_sop;
  wire csi1_npr_req_vld;
  wire csi1_prcmpl_req0_eop;
  wire csi1_prcmpl_req0_err;
  wire csi1_prcmpl_req0_rdy;
  wire [319:0]csi1_prcmpl_req0_seg;
  wire csi1_prcmpl_req0_sop;
  wire csi1_prcmpl_req0_vld;
  wire csi1_prcmpl_req1_eop;
  wire csi1_prcmpl_req1_err;
  wire csi1_prcmpl_req1_rdy;
  wire [319:0]csi1_prcmpl_req1_seg;
  wire csi1_prcmpl_req1_sop;
  wire csi1_prcmpl_req1_vld;
  wire csi1_resp0_eop;
  wire csi1_resp0_err;
  wire csi1_resp0_rdy;
  wire [319:0]csi1_resp0_seg;
  wire csi1_resp0_sop;
  wire csi1_resp0_vld;
  wire csi1_resp1_eop;
  wire csi1_resp1_err;
  wire csi1_resp1_rdy;
  wire [319:0]csi1_resp1_seg;
  wire csi1_resp1_sop;
  wire csi1_resp1_vld;
  wire gt_refclk0_clk_n;
  wire gt_refclk0_clk_p;
  wire pl0_ref_clk_0;
  wire pl0_resetn_0;
  wire [0:0]sys_clk_ddr_clk_n;
  wire [0:0]sys_clk_ddr_clk_p;

  design_1 design_1_i
       (.CH0_LPDDR5_ca(CH0_LPDDR5_ca),
        .CH0_LPDDR5_ck_c(CH0_LPDDR5_ck_c),
        .CH0_LPDDR5_ck_t(CH0_LPDDR5_ck_t),
        .CH0_LPDDR5_cs(CH0_LPDDR5_cs),
        .CH0_LPDDR5_dmi(CH0_LPDDR5_dmi),
        .CH0_LPDDR5_dq(CH0_LPDDR5_dq),
        .CH0_LPDDR5_rdqs_c(CH0_LPDDR5_rdqs_c),
        .CH0_LPDDR5_rdqs_t(CH0_LPDDR5_rdqs_t),
        .CH0_LPDDR5_reset_n(CH0_LPDDR5_reset_n),
        .CH0_LPDDR5_wck_c(CH0_LPDDR5_wck_c),
        .CH0_LPDDR5_wck_t(CH0_LPDDR5_wck_t),
        .CH1_LPDDR5_ca(CH1_LPDDR5_ca),
        .CH1_LPDDR5_ck_c(CH1_LPDDR5_ck_c),
        .CH1_LPDDR5_ck_t(CH1_LPDDR5_ck_t),
        .CH1_LPDDR5_cs(CH1_LPDDR5_cs),
        .CH1_LPDDR5_dmi(CH1_LPDDR5_dmi),
        .CH1_LPDDR5_dq(CH1_LPDDR5_dq),
        .CH1_LPDDR5_rdqs_c(CH1_LPDDR5_rdqs_c),
        .CH1_LPDDR5_rdqs_t(CH1_LPDDR5_rdqs_t),
        .CH1_LPDDR5_wck_c(CH1_LPDDR5_wck_c),
        .CH1_LPDDR5_wck_t(CH1_LPDDR5_wck_t),
        .PCIE0_GT_grx_n(PCIE0_GT_grx_n),
        .PCIE0_GT_grx_p(PCIE0_GT_grx_p),
        .PCIE0_GT_gtx_n(PCIE0_GT_gtx_n),
        .PCIE0_GT_gtx_p(PCIE0_GT_gtx_p),
        .atg_axi_araddr(atg_axi_araddr),
        .atg_axi_arburst(atg_axi_arburst),
        .atg_axi_arcache(atg_axi_arcache),
        .atg_axi_arid(atg_axi_arid),
        .atg_axi_arlen(atg_axi_arlen),
        .atg_axi_arlock(atg_axi_arlock),
        .atg_axi_arprot(atg_axi_arprot),
        .atg_axi_arqos(atg_axi_arqos),
        .atg_axi_arready(atg_axi_arready),
        .atg_axi_arregion(atg_axi_arregion),
        .atg_axi_arsize(atg_axi_arsize),
        .atg_axi_aruser(atg_axi_aruser),
        .atg_axi_arvalid(atg_axi_arvalid),
        .atg_axi_awaddr(atg_axi_awaddr),
        .atg_axi_awburst(atg_axi_awburst),
        .atg_axi_awcache(atg_axi_awcache),
        .atg_axi_awid(atg_axi_awid),
        .atg_axi_awlen(atg_axi_awlen),
        .atg_axi_awlock(atg_axi_awlock),
        .atg_axi_awprot(atg_axi_awprot),
        .atg_axi_awqos(atg_axi_awqos),
        .atg_axi_awready(atg_axi_awready),
        .atg_axi_awregion(atg_axi_awregion),
        .atg_axi_awsize(atg_axi_awsize),
        .atg_axi_awuser(atg_axi_awuser),
        .atg_axi_awvalid(atg_axi_awvalid),
        .atg_axi_bid(atg_axi_bid),
        .atg_axi_bready(atg_axi_bready),
        .atg_axi_bresp(atg_axi_bresp),
        .atg_axi_bvalid(atg_axi_bvalid),
        .atg_axi_rdata(atg_axi_rdata),
        .atg_axi_rid(atg_axi_rid),
        .atg_axi_rlast(atg_axi_rlast),
        .atg_axi_rready(atg_axi_rready),
        .atg_axi_rresp(atg_axi_rresp),
        .atg_axi_rvalid(atg_axi_rvalid),
        .atg_axi_wdata(atg_axi_wdata),
        .atg_axi_wlast(atg_axi_wlast),
        .atg_axi_wready(atg_axi_wready),
        .atg_axi_wstrb(atg_axi_wstrb),
        .atg_axi_wvalid(atg_axi_wvalid),
        .axil_cmdram_araddr(axil_cmdram_araddr),
        .axil_cmdram_arprot(axil_cmdram_arprot),
        .axil_cmdram_arready(axil_cmdram_arready),
        .axil_cmdram_arvalid(axil_cmdram_arvalid),
        .axil_cmdram_awaddr(axil_cmdram_awaddr),
        .axil_cmdram_awprot(axil_cmdram_awprot),
        .axil_cmdram_awready(axil_cmdram_awready),
        .axil_cmdram_awvalid(axil_cmdram_awvalid),
        .axil_cmdram_bready(axil_cmdram_bready),
        .axil_cmdram_bresp(axil_cmdram_bresp),
        .axil_cmdram_bvalid(axil_cmdram_bvalid),
        .axil_cmdram_rdata(axil_cmdram_rdata),
        .axil_cmdram_rready(axil_cmdram_rready),
        .axil_cmdram_rresp(axil_cmdram_rresp),
        .axil_cmdram_rvalid(axil_cmdram_rvalid),
        .axil_cmdram_wdata(axil_cmdram_wdata),
        .axil_cmdram_wready(axil_cmdram_wready),
        .axil_cmdram_wstrb(axil_cmdram_wstrb),
        .axil_cmdram_wvalid(axil_cmdram_wvalid),
        .axil_csi_exdes_araddr(axil_csi_exdes_araddr),
        .axil_csi_exdes_arprot(axil_csi_exdes_arprot),
        .axil_csi_exdes_arready(axil_csi_exdes_arready),
        .axil_csi_exdes_arvalid(axil_csi_exdes_arvalid),
        .axil_csi_exdes_awaddr(axil_csi_exdes_awaddr),
        .axil_csi_exdes_awprot(axil_csi_exdes_awprot),
        .axil_csi_exdes_awready(axil_csi_exdes_awready),
        .axil_csi_exdes_awvalid(axil_csi_exdes_awvalid),
        .axil_csi_exdes_bready(axil_csi_exdes_bready),
        .axil_csi_exdes_bresp(axil_csi_exdes_bresp),
        .axil_csi_exdes_bvalid(axil_csi_exdes_bvalid),
        .axil_csi_exdes_rdata(axil_csi_exdes_rdata),
        .axil_csi_exdes_rready(axil_csi_exdes_rready),
        .axil_csi_exdes_rresp(axil_csi_exdes_rresp),
        .axil_csi_exdes_rvalid(axil_csi_exdes_rvalid),
        .axil_csi_exdes_wdata(axil_csi_exdes_wdata),
        .axil_csi_exdes_wready(axil_csi_exdes_wready),
        .axil_csi_exdes_wstrb(axil_csi_exdes_wstrb),
        .axil_csi_exdes_wvalid(axil_csi_exdes_wvalid),
        .cdm_top_msgld_dat_client_id(cdm_top_msgld_dat_client_id),
        .cdm_top_msgld_dat_data(cdm_top_msgld_dat_data),
        .cdm_top_msgld_dat_ecc(cdm_top_msgld_dat_ecc),
        .cdm_top_msgld_dat_eop(cdm_top_msgld_dat_eop),
        .cdm_top_msgld_dat_err_status(cdm_top_msgld_dat_err_status),
        .cdm_top_msgld_dat_error(cdm_top_msgld_dat_error),
        .cdm_top_msgld_dat_mty(cdm_top_msgld_dat_mty),
        .cdm_top_msgld_dat_rc_id(cdm_top_msgld_dat_rc_id),
        .cdm_top_msgld_dat_rdy(cdm_top_msgld_dat_rdy),
        .cdm_top_msgld_dat_response_cookie(cdm_top_msgld_dat_response_cookie),
        .cdm_top_msgld_dat_start_offset(cdm_top_msgld_dat_start_offset),
        .cdm_top_msgld_dat_status(cdm_top_msgld_dat_status),
        .cdm_top_msgld_dat_vld(cdm_top_msgld_dat_vld),
        .cdm_top_msgld_dat_zero_byte(cdm_top_msgld_dat_zero_byte),
        .cdm_top_msgld_req_addr(cdm_top_msgld_req_addr),
        .cdm_top_msgld_req_addr_spc(cdm_top_msgld_req_addr_spc),
        .cdm_top_msgld_req_attr(cdm_top_msgld_req_attr),
        .cdm_top_msgld_req_client_id(cdm_top_msgld_req_client_id),
        .cdm_top_msgld_req_data_width(cdm_top_msgld_req_data_width),
        .cdm_top_msgld_req_if_op(cdm_top_msgld_req_if_op),
        .cdm_top_msgld_req_length(cdm_top_msgld_req_length),
        .cdm_top_msgld_req_op(cdm_top_msgld_req_op),
        .cdm_top_msgld_req_rc_id(cdm_top_msgld_req_rc_id),
        .cdm_top_msgld_req_rdy(cdm_top_msgld_req_rdy),
        .cdm_top_msgld_req_relaxed_read(cdm_top_msgld_req_relaxed_read),
        .cdm_top_msgld_req_response_cookie(cdm_top_msgld_req_response_cookie),
        .cdm_top_msgld_req_start_offset(cdm_top_msgld_req_start_offset),
        .cdm_top_msgld_req_vld(cdm_top_msgld_req_vld),
        .cdm_top_msgst_addr(cdm_top_msgst_addr),
        .cdm_top_msgst_addr_spc(cdm_top_msgst_addr_spc),
        .cdm_top_msgst_attr(cdm_top_msgst_attr),
        .cdm_top_msgst_client_id(cdm_top_msgst_client_id),
        .cdm_top_msgst_data(cdm_top_msgst_data),
        .cdm_top_msgst_data_width(cdm_top_msgst_data_width),
        .cdm_top_msgst_ecc(cdm_top_msgst_ecc),
        .cdm_top_msgst_eop(cdm_top_msgst_eop),
        .cdm_top_msgst_irq_vector(cdm_top_msgst_irq_vector),
        .cdm_top_msgst_length(cdm_top_msgst_length),
        .cdm_top_msgst_op(cdm_top_msgst_op),
        .cdm_top_msgst_rdy(cdm_top_msgst_rdy),
        .cdm_top_msgst_response_cookie(cdm_top_msgst_response_cookie),
        .cdm_top_msgst_response_req(cdm_top_msgst_response_req),
        .cdm_top_msgst_st2m_ordered(cdm_top_msgst_st2m_ordered),
        .cdm_top_msgst_start_offset(cdm_top_msgst_start_offset),
        .cdm_top_msgst_tph(cdm_top_msgst_tph),
        .cdm_top_msgst_vld(cdm_top_msgst_vld),
        .cdm_top_msgst_wait_pld_pkt_id(cdm_top_msgst_wait_pld_pkt_id),
        .cpm_gpo(cpm_gpo),
        .csi1_dst_crdt_tdata(csi1_dst_crdt_tdata),
        .csi1_dst_crdt_tready(csi1_dst_crdt_tready),
        .csi1_dst_crdt_tvalid(csi1_dst_crdt_tvalid),
        .csi1_es1_wa_en(csi1_es1_wa_en),
        .csi1_local_crdt_buf_id(csi1_local_crdt_buf_id),
        .csi1_local_crdt_data(csi1_local_crdt_data),
        .csi1_local_crdt_flow_type(csi1_local_crdt_flow_type),
        .csi1_local_crdt_rdy(csi1_local_crdt_rdy),
        .csi1_local_crdt_snk_id(csi1_local_crdt_snk_id),
        .csi1_local_crdt_src_furc_id(csi1_local_crdt_src_furc_id),
        .csi1_local_crdt_vld(csi1_local_crdt_vld),
        .csi1_npr_req_eop(csi1_npr_req_eop),
        .csi1_npr_req_err(csi1_npr_req_err),
        .csi1_npr_req_rdy(csi1_npr_req_rdy),
        .csi1_npr_req_seg(csi1_npr_req_seg),
        .csi1_npr_req_sop(csi1_npr_req_sop),
        .csi1_npr_req_vld(csi1_npr_req_vld),
        .csi1_prcmpl_req0_eop(csi1_prcmpl_req0_eop),
        .csi1_prcmpl_req0_err(csi1_prcmpl_req0_err),
        .csi1_prcmpl_req0_rdy(csi1_prcmpl_req0_rdy),
        .csi1_prcmpl_req0_seg(csi1_prcmpl_req0_seg),
        .csi1_prcmpl_req0_sop(csi1_prcmpl_req0_sop),
        .csi1_prcmpl_req0_vld(csi1_prcmpl_req0_vld),
        .csi1_prcmpl_req1_eop(csi1_prcmpl_req1_eop),
        .csi1_prcmpl_req1_err(csi1_prcmpl_req1_err),
        .csi1_prcmpl_req1_rdy(csi1_prcmpl_req1_rdy),
        .csi1_prcmpl_req1_seg(csi1_prcmpl_req1_seg),
        .csi1_prcmpl_req1_sop(csi1_prcmpl_req1_sop),
        .csi1_prcmpl_req1_vld(csi1_prcmpl_req1_vld),
        .csi1_resp0_eop(csi1_resp0_eop),
        .csi1_resp0_err(csi1_resp0_err),
        .csi1_resp0_rdy(csi1_resp0_rdy),
        .csi1_resp0_seg(csi1_resp0_seg),
        .csi1_resp0_sop(csi1_resp0_sop),
        .csi1_resp0_vld(csi1_resp0_vld),
        .csi1_resp1_eop(csi1_resp1_eop),
        .csi1_resp1_err(csi1_resp1_err),
        .csi1_resp1_rdy(csi1_resp1_rdy),
        .csi1_resp1_seg(csi1_resp1_seg),
        .csi1_resp1_sop(csi1_resp1_sop),
        .csi1_resp1_vld(csi1_resp1_vld),
        .gt_refclk0_clk_n(gt_refclk0_clk_n),
        .gt_refclk0_clk_p(gt_refclk0_clk_p),
        .pl0_ref_clk_0(pl0_ref_clk_0),
        .pl0_resetn_0(pl0_resetn_0),
        .sys_clk_ddr_clk_n(sys_clk_ddr_clk_n),
        .sys_clk_ddr_clk_p(sys_clk_ddr_clk_p));
endmodule
