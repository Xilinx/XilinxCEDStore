`timescale 1ps / 1ps
//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1.0 (lin64) Build 3682038 Thu Oct 27 19:14:51 MDT 2022
//Date        : Fri Oct 28 11:13:22 2022
//Host        : xsjrdevl155 running 64-bit CentOS Linux release 7.5.1804 (Core)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------

`define CDX5N_PROTO_UPORT 1
//`include "cpm5n_interface.svh"

module cdm_msgld_msgst_top
//synthesis translate off
 import cpm5n_v1_0_7_pkg::*;
//synthesis translate on
(
	PCIE0_GT_grx_n,
    PCIE0_GT_grx_p,
    PCIE0_GT_gtx_n,
    PCIE0_GT_gtx_p,
	gt_refclk0_clk_n,
    gt_refclk0_clk_p,
	
	CH0_LPDDR5_ca,
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
    sys_clk_ddr_clk_n,
    sys_clk_ddr_clk_p
	);
	
	input  [15:0]	PCIE0_GT_grx_n;
	input  [15:0]	PCIE0_GT_grx_p;
	output [15:0]	PCIE0_GT_gtx_n;
	output [15:0]	PCIE0_GT_gtx_p;
	
	input gt_refclk0_clk_n;
	input gt_refclk0_clk_p;
	
	output [6:0]	CH0_LPDDR5_ca;
    output [0:0]	CH0_LPDDR5_ck_c;
    output [0:0]	CH0_LPDDR5_ck_t;
    output [0:0]	CH0_LPDDR5_cs;
    inout  [1:0]    CH0_LPDDR5_dmi;
    inout  [15:0]	CH0_LPDDR5_dq;
    input  [1:0]	CH0_LPDDR5_rdqs_c;
    input  [1:0]	CH0_LPDDR5_rdqs_t;
    output [0:0]	CH0_LPDDR5_reset_n;
    output [1:0]	CH0_LPDDR5_wck_c;
    output [1:0]	CH0_LPDDR5_wck_t;
    output [6:0]	CH1_LPDDR5_ca;
    output [0:0]	CH1_LPDDR5_ck_c;
    output [0:0]	CH1_LPDDR5_ck_t;
    output [0:0]	CH1_LPDDR5_cs;
    inout  [1:0]    CH1_LPDDR5_dmi;
    inout  [15:0]	CH1_LPDDR5_dq;
    input  [1:0]	CH1_LPDDR5_rdqs_c;
    input  [1:0]	CH1_LPDDR5_rdqs_t;
    output [1:0]	CH1_LPDDR5_wck_c;
    output [1:0]	CH1_LPDDR5_wck_t;
    input [0:0]     sys_clk_ddr_clk_n;
    input [0:0]     sys_clk_ddr_clk_p;
	
	
	wire [15:0]		PCIE0_GT_grx_n;
	wire [15:0]		PCIE0_GT_grx_p;
	wire [15:0]		PCIE0_GT_gtx_n;
	wire [15:0]		PCIE0_GT_gtx_p;
	
	wire [6:0]		CH0_LPDDR5_ca;
	wire [0:0]		CH0_LPDDR5_ck_c;
	wire [0:0]		CH0_LPDDR5_ck_t;
	wire [0:0]		CH0_LPDDR5_cs;
    wire [1:0]      CH0_LPDDR5_dmi;
	wire [15:0]		CH0_LPDDR5_dq;
	wire [1:0]		CH0_LPDDR5_rdqs_c;
	wire [1:0]		CH0_LPDDR5_rdqs_t;
	wire [0:0]		CH0_LPDDR5_reset_n;
	wire [1:0]		CH0_LPDDR5_wck_c;
	wire [1:0]		CH0_LPDDR5_wck_t;
	wire [6:0]		CH1_LPDDR5_ca;
	wire [0:0]		CH1_LPDDR5_ck_c;
	wire [0:0]		CH1_LPDDR5_ck_t;
	wire [0:0]		CH1_LPDDR5_cs;
    wire [1:0]      CH1_LPDDR5_dmi;
	wire [15:0]		CH1_LPDDR5_dq;
	wire [1:0]		CH1_LPDDR5_rdqs_c;
	wire [1:0]		CH1_LPDDR5_rdqs_t;
	wire [1:0]		CH1_LPDDR5_wck_c;
	wire [1:0]		CH1_LPDDR5_wck_t;	
    wire [0:0]      sys_clk_ddr_clk_n;
    wire [0:0]      sys_clk_ddr_clk_p;
	
	logic [388:0]	cdm_top_msgld_dat_tdata;
	logic 			cdm_top_msgld_dat_tready;
	logic 			cdm_top_msgld_dat_tvalid;
	logic [164:0]	cdm_top_msgld_req_tdata;
	logic 			cdm_top_msgld_req_tready;
	logic 			cdm_top_msgld_req_tready_int;
	logic 			cdm_top_msgld_req_tvalid;
	logic [475:0]	cdm_top_msgst_tdata;
	logic 			cdm_top_msgst_tready;
	logic 			cdm_top_msgst_tready_int;
	logic 			cdm_top_msgst_tvalid;	
	wire 			cpm_user_clk;
	wire 			gt_refclk0_clk_n;
	wire 			gt_refclk0_clk_p;

	logic				user_reset_n;
	
	wire  [31:0]	M_AXI_CDM_araddr;	
	wire  [2:0] 	M_AXI_CDM_arprot;	
	wire 		 	M_AXI_CDM_arready;	
	wire  		 	M_AXI_CDM_arvalid;	
	wire  [31:0]	M_AXI_CDM_awaddr;	
	wire  [2:0]	M_AXI_CDM_awprot;	
	wire 			M_AXI_CDM_awready;	
	wire  			M_AXI_CDM_awvalid;	
	wire  			M_AXI_CDM_bready;	
	wire [1:0]		M_AXI_CDM_bresp;	
	wire 			M_AXI_CDM_bvalid;	
	wire [31:0]	M_AXI_CDM_rdata;	
	wire  			M_AXI_CDM_rready;	
	wire [1:0]		M_AXI_CDM_rresp;	
	wire 			M_AXI_CDM_rvalid;	
	wire  [31:0]	M_AXI_CDM_wdata;
	wire 			M_AXI_CDM_wready;	
	wire  [3:0]		M_AXI_CDM_wstrb;	
	wire  			M_AXI_CDM_wvalid;
	
	wire [41:0]		axil_cmdram_araddr;
    wire [2:0]		axil_cmdram_arprot;
    wire 			axil_cmdram_arready;
    wire 			axil_cmdram_arvalid;
    wire [41:0]		axil_cmdram_awaddr;
    wire [2:0]		axil_cmdram_awprot;
    wire 			axil_cmdram_awready;
    wire 			axil_cmdram_awvalid;
    wire 			axil_cmdram_bready;
    wire [1:0]		axil_cmdram_bresp;
    wire 			axil_cmdram_bvalid;
    wire [31:0]		axil_cmdram_rdata;
    wire 			axil_cmdram_rready;
    wire [1:0]		axil_cmdram_rresp;
    wire 			axil_cmdram_rvalid;
    wire [31:0]		axil_cmdram_wdata;
    wire 			axil_cmdram_wready;
    wire [3:0]		axil_cmdram_wstrb;
    wire 			axil_cmdram_wvalid;
	
	logic [3:0]		cdm_top_msgld_dat_client_id;
	logic [255:0]	cdm_top_msgld_dat_data;
	logic [9:0]		cdm_top_msgld_dat_ecc;
	logic 			cdm_top_msgld_dat_eop;
	logic [2:0]		cdm_top_msgld_dat_err_status;
	logic 			cdm_top_msgld_dat_error;
	logic [4:0]		cdm_top_msgld_dat_mty;
	logic [5:0]		cdm_top_msgld_dat_rc_id;	
	logic [11:0]	cdm_top_msgld_dat_response_cookie;
	logic [4:0]		cdm_top_msgld_dat_start_offset;
	logic [1:0]		cdm_top_msgld_dat_status;	
	logic 			cdm_top_msgld_dat_zero_byte;
	
	wire 			cdm_top_msgld_dat_tvalid_int;	
	wire [3:0]		cdm_top_msgld_dat_client_id_int;
	wire [255:0]	cdm_top_msgld_dat_data_int;
	wire [9:0]		cdm_top_msgld_dat_ecc_int;
	wire 			cdm_top_msgld_dat_eop_int;
	wire [2:0]		cdm_top_msgld_dat_err_status_int;
	wire 			cdm_top_msgld_dat_error_int;
	wire [4:0]		cdm_top_msgld_dat_mty_int;
	wire [5:0]		cdm_top_msgld_dat_rc_id_int;	
	wire [11:0]	    cdm_top_msgld_dat_response_cookie_int;
	wire [4:0]		cdm_top_msgld_dat_start_offset_int;
	wire [1:0]		cdm_top_msgld_dat_status_int;	
	wire 			cdm_top_msgld_dat_zero_byte_int;
	
	logic [65:0]	cdm_top_msgld_req_addr;
	logic [53:0]	cdm_top_msgld_req_addr_spc;
	logic [2:0]		cdm_top_msgld_req_attr;
	logic [3:0]		cdm_top_msgld_req_client_id;
	logic 			cdm_top_msgld_req_data_width;
	logic [1:0]		cdm_top_msgld_req_if_op;
	logic [8:0]		cdm_top_msgld_req_length;
	logic [1:0]		cdm_top_msgld_req_op;
	logic [5:0]		cdm_top_msgld_req_rc_id;	
	logic 			cdm_top_msgld_req_relaxed_read;
	logic [11:0]	cdm_top_msgld_req_response_cookie;
	logic [4:0]		cdm_top_msgld_req_start_offset;	
	
	logic [65:0]	cdm_top_msgst_addr;
	logic [53:0]	cdm_top_msgst_addr_spc;
	logic [2:0]		cdm_top_msgst_attr;
	logic [3:0]		cdm_top_msgst_client_id;
	logic [255:0]	cdm_top_msgst_data;
	logic [1:0]		cdm_top_msgst_data_width;
	logic [10:0]	cdm_top_msgst_ecc;
	logic 			cdm_top_msgst_eop;
	logic [15:0]	cdm_top_msgst_irq_vector;
	logic [8:0]		cdm_top_msgst_length;
	logic [1:0]		cdm_top_msgst_op;	
	logic [11:0]	cdm_top_msgst_response_cookie;
	logic 			cdm_top_msgst_response_req;
	logic 			cdm_top_msgst_st2m_ordered;
	logic [3:0]		cdm_top_msgst_start_offset;
	logic [10:0]	cdm_top_msgst_tph;	
	logic [15:0]	cdm_top_msgst_wait_pld_pkt_id;
	
    logic           msgst_payload_fill_bram = 1'b0; 
    
    //VIO signals to initiate msgst/msgld traffic
    logic           msgst_pld_cmd_req_vio;
    logic [14:0]    msgst_num_of_req_vio;
    logic [31:0]    msgst_pcie0_host_addr_vio;
    
    logic           msgld_pld_cmd_rd_start_vio;
    logic [14:0]    msgld_num_of_req_vio;
    logic [31:0]    msgld_pcie0_host_addr_vio;
    
    logic 			msgst_cmd_fill_bram_vio;
    logic 			msgld_cmd_fill_bram_vio;
    logic 			msgst_payload_fill_bram_vio;
    
    logic 			msgst_req_fill_start_vio;
    logic 			msgld_req_fill_start_vio;
    logic 			msgst_payload_fill_start_vio;
    
    logic [2:0]     back_pres_vio;
    logic [2:0]     halt_vio;
    logic           enforce_order_vio;
	
	logic [1:0]		atg_axi_arburst;
	logic [3:0]		atg_axi_arcache;
	logic [0:0]		atg_axi_arid;
	logic [7:0]		atg_axi_arlen;
	logic [0:0]		atg_axi_arlock;
	logic [2:0]		atg_axi_arprot;
	logic [3:0]		atg_axi_arqos;
	logic [0:0]		atg_axi_arready;
	logic [3:0]		atg_axi_arregion;
	logic [2:0]		atg_axi_arsize;
	logic [7:0]		atg_axi_aruser;
	logic [0:0]		atg_axi_arvalid;
	logic [63:0]	atg_axi_awaddr;
	logic [1:0]		atg_axi_awburst;
	logic [3:0]		atg_axi_awcache;
	logic [0:0]		atg_axi_awid;
	logic [7:0]		atg_axi_awlen;
	logic [0:0]		atg_axi_awlock;
	logic [2:0]		atg_axi_awprot;
	logic [3:0]		atg_axi_awqos;
	logic [0:0]		atg_axi_awready;
	logic [3:0]		atg_axi_awregion;
	logic [2:0]		atg_axi_awsize;
	logic [7:0]		atg_axi_awuser;
	logic [0:0]		atg_axi_awvalid;
	logic [0:0]		atg_axi_bid;
	logic [0:0]		atg_axi_bready;
	logic [1:0]		atg_axi_bresp;
	logic [0:0]		atg_axi_bvalid;
	logic [511:0]	atg_axi_rdata;
	logic [0:0]		atg_axi_rid;
	logic [0:0]		atg_axi_rlast;
	logic [0:0]		atg_axi_rready;
	logic [1:0]		atg_axi_rresp;
	logic [0:0]		atg_axi_rvalid;
	logic [511:0]	atg_axi_wdata;
	logic [0:0]		atg_axi_wlast;
	logic [0:0]		atg_axi_wready;
	logic [63:0]	atg_axi_wstrb;
	logic [0:0]		atg_axi_wvalid;
	logic [31:0]    cpm_gpo;
	logic           csi1_es1_wa_en;
	
	logic [0:0]		gen_wr_vio;
	logic [0:0]		gen_rd_vio;
	
	logic [4:0]	    msgstld_CSI_DST_vio;
	logic [8:0]	    msgstld_pld_length_vio; 
	logic [11:0]    msgst_resp_cookie_vio;
	logic [11:0]    msgld_resp_cookie_vio;	
	
	logic [21:0]	csi1_dst_crdt_tdata;
	logic 			csi1_dst_crdt_tready;
	logic 			csi1_dst_crdt_tvalid;
	logic [6:0]		csi1_local_crdt_buf_id;
	logic [15:0]	csi1_local_crdt_data;
	logic [1:0]		csi1_local_crdt_flow_type;
	logic 			csi1_local_crdt_rdy;
	logic [1:0]		csi1_local_crdt_snk_id;
	logic [1:0]		csi1_local_crdt_src_furc_id;
	logic 			csi1_local_crdt_vld;
	
	logic 			csi1_npr_req_eop;
	logic 			csi1_npr_req_err;
	logic 			csi1_npr_req_rdy;
	logic [319:0]	csi1_npr_req_seg;
	logic 			csi1_npr_req_sop;
	logic 			csi1_npr_req_vld;
	
	logic 			csi1_prcmpl_req0_eop;
	logic 			csi1_prcmpl_req0_err;
	logic 			csi1_prcmpl_req0_rdy;
	logic [319:0]	csi1_prcmpl_req0_seg;
	logic 			csi1_prcmpl_req0_sop;
	logic 			csi1_prcmpl_req0_vld;
	
	logic 			csi1_prcmpl_req1_eop;
	logic 			csi1_prcmpl_req1_err;
	logic 			csi1_prcmpl_req1_rdy;
	logic [319:0]	csi1_prcmpl_req1_seg;
	logic 			csi1_prcmpl_req1_sop;
	logic 			csi1_prcmpl_req1_vld;
	
	logic 			csi1_resp0_eop;
	logic 			csi1_resp0_err;
	logic 			csi1_resp0_rdy;
	logic [319:0]	csi1_resp0_seg;
	logic 			csi1_resp0_sop;
	logic 			csi1_resp0_vld;
	
	logic 			csi1_resp1_eop;
	logic 			csi1_resp1_err;
	logic 			csi1_resp1_rdy;
	logic [319:0]	csi1_resp1_seg;
	logic 			csi1_resp1_sop;
	logic 			csi1_resp1_vld;
	
	cdx5n_fab_2s_seg_if                csi2f_port0_out();
	cdx5n_fab_2s_seg_if                f2csi_port0_prcmpl_in();
	cdx5n_fab_1s_seg_if                f2csi_port0_npr_in();
	cdx5n_csi_local_crdt_if            local_crdt_port0_out();
	cdx5n_csi_snk_sched_ser_ing_if     dest_crdt_port0_in();
 
	logic  [31:0]   csi_uport_axil_araddr;
	logic  [2:0]    csi_uport_axil_arprot;
	logic           csi_uport_axil_arready;
	logic           csi_uport_axil_arvalid;
	logic  [31:0]   csi_uport_axil_awaddr;
	logic  [2:0]    csi_uport_axil_awprot;
	logic           csi_uport_axil_awready;
	logic           csi_uport_axil_awvalid;
	logic           csi_uport_axil_bready;
	logic  [1:0]    csi_uport_axil_bresp;
	logic           csi_uport_axil_bvalid;
	logic  [31:0]   csi_uport_axil_rdata;
	logic           csi_uport_axil_rready;
	logic  [1:0]    csi_uport_axil_rresp;
	logic           csi_uport_axil_rvalid;
	logic  [31:0]   csi_uport_axil_wdata;
	logic           csi_uport_axil_wready;
	logic  [3:0]    csi_uport_axil_wstrb;
	logic           csi_uport_axil_wvalid;

	logic  [31:0]   axi_vip_axil_araddr;
	logic  [2:0]    axi_vip_axil_arprot;
	logic           axi_vip_axil_arready;
	logic           axi_vip_axil_arvalid;
	logic  [31:0]   axi_vip_axil_awaddr;
	logic  [2:0]    axi_vip_axil_awprot;
	logic           axi_vip_axil_awready;
	logic           axi_vip_axil_awvalid;
	logic           axi_vip_axil_bready;
	logic  [1:0]    axi_vip_axil_bresp;
	logic           axi_vip_axil_bvalid;
	logic  [31:0]   axi_vip_axil_rdata;
	logic           axi_vip_axil_rready;
	logic  [1:0]    axi_vip_axil_rresp;
	logic           axi_vip_axil_rvalid;
	logic  [31:0]   axi_vip_axil_wdata;
	logic           axi_vip_axil_wready;
	logic  [3:0]    axi_vip_axil_wstrb;
	logic           axi_vip_axil_wvalid;
	logic           axi_vip_en;
	
	logic 			msgst_cmd_fill_bram;
	logic 			msgld_cmd_fill_bram;
	logic [6:0]		msgst_top_num_of_CMD;
	logic [6:0]		msgld_top_num_of_CMD;
	
	logic [31:0]	msgstld_perf_reg_araddr;
	logic 			msgstld_perf_reg_arready;
	logic 			msgstld_perf_reg_arvalid;
	logic [31:0]	msgstld_perf_reg_awaddr;
	logic 			msgstld_perf_reg_awready;
	logic 			msgstld_perf_reg_awvalid;
	logic 			msgstld_perf_reg_bready;
    logic [1:0]		msgstld_perf_reg_bresp;
	logic 			msgstld_perf_reg_bvalid;
	logic [31:0]	msgstld_perf_reg_rdata;
	logic 			msgstld_perf_reg_rready;
	logic [1:0]		msgstld_perf_reg_rresp;
	logic 			msgstld_perf_reg_rvalid;
	logic [31:0]	msgstld_perf_reg_wdata;
	logic 			msgstld_perf_reg_wready;
	logic [3:0]		msgstld_perf_reg_wstrb;
	logic 			msgstld_perf_reg_wvalid;

	assign csi2f_port0_out.seg[0]   = csi1_resp0_seg  ;
	assign csi2f_port0_out.vld[0]   = csi1_resp0_vld  ; 
	assign csi2f_port0_out.sop[0]   = csi1_resp0_sop  ; 
	assign csi2f_port0_out.eop[0]   = csi1_resp0_eop  ; 
	assign csi2f_port0_out.err[0]   = csi1_resp0_err  ; 
	assign csi1_resp0_rdy    		= csi2f_port0_out.rdy[0]; 
	
	assign csi2f_port0_out.seg[1]   = csi1_resp1_seg  ;
	assign csi2f_port0_out.vld[1]   = csi1_resp1_vld  ; 
	assign csi2f_port0_out.sop[1]   = csi1_resp1_sop  ; 
	assign csi2f_port0_out.eop[1]   = csi1_resp1_eop  ; 
	assign csi2f_port0_out.err[1]   = csi1_resp1_err  ; 
	assign csi1_resp1_rdy    		= csi2f_port0_out.rdy[1]; 
	
	assign csi1_prcmpl_req0_seg        	 =  f2csi_port0_prcmpl_in.seg[0];
	assign csi1_prcmpl_req0_vld        	 =  f2csi_port0_prcmpl_in.vld[0];
	assign csi1_prcmpl_req0_sop        	 =  f2csi_port0_prcmpl_in.sop[0];
	assign csi1_prcmpl_req0_eop        	 =  f2csi_port0_prcmpl_in.eop[0];
	assign csi1_prcmpl_req0_err        	 =  f2csi_port0_prcmpl_in.err[0];
	assign f2csi_port0_prcmpl_in.rdy[0]  =  csi1_prcmpl_req0_rdy;
	
	assign csi1_prcmpl_req1_seg        	 =  f2csi_port0_prcmpl_in.seg[1];
	assign csi1_prcmpl_req1_vld        	 =  f2csi_port0_prcmpl_in.vld[1];
	assign csi1_prcmpl_req1_sop        	 =  f2csi_port0_prcmpl_in.sop[1];
	assign csi1_prcmpl_req1_eop        	 =  f2csi_port0_prcmpl_in.eop[1];
	assign csi1_prcmpl_req1_err        	 =  f2csi_port0_prcmpl_in.err[1];
	assign f2csi_port0_prcmpl_in.rdy[1]  =  csi1_prcmpl_req1_rdy;
	
	assign csi1_npr_req_seg            	 =  f2csi_port0_npr_in.seg;
	assign csi1_npr_req_vld            	 =  f2csi_port0_npr_in.vld;
	assign csi1_npr_req_sop            	 =  f2csi_port0_npr_in.sop;
	assign csi1_npr_req_eop            	 =  f2csi_port0_npr_in.eop;
	assign csi1_npr_req_err            	 =  f2csi_port0_npr_in.err;
	assign f2csi_port0_npr_in.rdy        =  csi1_npr_req_rdy ;
	
	assign csi1_dst_crdt_tdata                =   dest_crdt_port0_in.ser_ing_intf_in; 
	assign csi1_dst_crdt_tvalid               =   dest_crdt_port0_in.ser_ing_intf_vld;
	assign dest_crdt_port0_in.ser_ing_intf_rdy  =   csi1_dst_crdt_tready; 
	
	assign local_crdt_port0_out.local_crdt_snk_id      = csi1_local_crdt_snk_id;     
	assign local_crdt_port0_out.local_crdt_src_furc_id = csi1_local_crdt_src_furc_id; 
	assign local_crdt_port0_out.local_crdt_flow_type   = csi_flow_t'(csi1_local_crdt_flow_type);   
	assign local_crdt_port0_out.local_crdt_buf_id      = csi1_local_crdt_buf_id;       
	assign local_crdt_port0_out.local_crdt             = csi1_local_crdt_data;          
	assign local_crdt_port0_out.local_crdt_vld         = csi1_local_crdt_vld;            
	assign csi1_local_crdt_rdy                         = local_crdt_port0_out.local_crdt_rdy;
    
	
	  design_1_wrapper design_ep_wrapper_i
       (
		.PCIE0_GT_grx_n						(PCIE0_GT_grx_n),
        .PCIE0_GT_grx_p						(PCIE0_GT_grx_p),
        .PCIE0_GT_gtx_n						(PCIE0_GT_gtx_n),
        .PCIE0_GT_gtx_p						(PCIE0_GT_gtx_p),
		
		.CH0_LPDDR5_ca						(CH0_LPDDR5_ca),
        .CH0_LPDDR5_ck_c					(CH0_LPDDR5_ck_c),
        .CH0_LPDDR5_ck_t					(CH0_LPDDR5_ck_t),
        .CH0_LPDDR5_cs						(CH0_LPDDR5_cs),
        .CH0_LPDDR5_dmi                     (CH0_LPDDR5_dmi),
        .CH0_LPDDR5_dq						(CH0_LPDDR5_dq),
        .CH0_LPDDR5_rdqs_c					(CH0_LPDDR5_rdqs_c),
        .CH0_LPDDR5_rdqs_t					(CH0_LPDDR5_rdqs_t),
        .CH0_LPDDR5_reset_n					(CH0_LPDDR5_reset_n),
        .CH0_LPDDR5_wck_c					(CH0_LPDDR5_wck_c),
        .CH0_LPDDR5_wck_t					(CH0_LPDDR5_wck_t),
        .CH1_LPDDR5_ca						(CH1_LPDDR5_ca),
        .CH1_LPDDR5_ck_c					(CH1_LPDDR5_ck_c),
        .CH1_LPDDR5_ck_t					(CH1_LPDDR5_ck_t),
        .CH1_LPDDR5_cs						(CH1_LPDDR5_cs),
        .CH1_LPDDR5_dmi                     (CH1_LPDDR5_dmi),
        .CH1_LPDDR5_dq						(CH1_LPDDR5_dq),
        .CH1_LPDDR5_rdqs_c					(CH1_LPDDR5_rdqs_c),
        .CH1_LPDDR5_rdqs_t					(CH1_LPDDR5_rdqs_t),
        .CH1_LPDDR5_wck_c					(CH1_LPDDR5_wck_c),
        .CH1_LPDDR5_wck_t					(CH1_LPDDR5_wck_t),
		
		.cdm_top_msgld_dat_client_id		(cdm_top_msgld_dat_client_id_int),
        .cdm_top_msgld_dat_data				(cdm_top_msgld_dat_data_int),
        .cdm_top_msgld_dat_ecc				(cdm_top_msgld_dat_ecc_int),
        .cdm_top_msgld_dat_eop				(cdm_top_msgld_dat_eop_int),
        .cdm_top_msgld_dat_err_status		(cdm_top_msgld_dat_err_status_int),
        .cdm_top_msgld_dat_error			(cdm_top_msgld_dat_error_int),
        .cdm_top_msgld_dat_mty				(cdm_top_msgld_dat_mty_int),
        .cdm_top_msgld_dat_rc_id			(cdm_top_msgld_dat_rc_id_int),
        .cdm_top_msgld_dat_rdy				(cdm_top_msgld_dat_tready),
        .cdm_top_msgld_dat_response_cookie	(cdm_top_msgld_dat_response_cookie_int),
        .cdm_top_msgld_dat_start_offset		(cdm_top_msgld_dat_start_offset_int),
        .cdm_top_msgld_dat_status			(cdm_top_msgld_dat_status_int),
        .cdm_top_msgld_dat_vld				(cdm_top_msgld_dat_tvalid_int),
        .cdm_top_msgld_dat_zero_byte		(cdm_top_msgld_dat_zero_byte_int),
		
        .cdm_top_msgld_req_addr				(cdm_top_msgld_req_addr),
        .cdm_top_msgld_req_addr_spc			(cdm_top_msgld_req_addr_spc),
        .cdm_top_msgld_req_attr				(cdm_top_msgld_req_attr),
        .cdm_top_msgld_req_client_id		(cdm_top_msgld_req_client_id),
        .cdm_top_msgld_req_data_width		(cdm_top_msgld_req_data_width),
        .cdm_top_msgld_req_if_op			(cdm_top_msgld_req_if_op),
        .cdm_top_msgld_req_length			(cdm_top_msgld_req_length),
        .cdm_top_msgld_req_op				(cdm_top_msgld_req_op),
        .cdm_top_msgld_req_rc_id			(cdm_top_msgld_req_rc_id),
        .cdm_top_msgld_req_rdy				(cdm_top_msgld_req_tready),
        .cdm_top_msgld_req_relaxed_read		(cdm_top_msgld_req_relaxed_read),
        .cdm_top_msgld_req_response_cookie	(cdm_top_msgld_req_response_cookie),
        .cdm_top_msgld_req_start_offset		(cdm_top_msgld_req_start_offset),
        .cdm_top_msgld_req_vld				(cdm_top_msgld_req_tvalid),
		
        .cdm_top_msgst_addr					(cdm_top_msgst_addr),
        .cdm_top_msgst_addr_spc				(cdm_top_msgst_addr_spc),
        .cdm_top_msgst_attr					(cdm_top_msgst_attr),
        .cdm_top_msgst_client_id			(cdm_top_msgst_client_id),
        .cdm_top_msgst_data					(cdm_top_msgst_data),
        .cdm_top_msgst_data_width			(cdm_top_msgst_data_width),
        .cdm_top_msgst_ecc					(cdm_top_msgst_ecc),
        .cdm_top_msgst_eop					(cdm_top_msgst_eop),
        .cdm_top_msgst_irq_vector			(cdm_top_msgst_irq_vector),
        .cdm_top_msgst_length				(cdm_top_msgst_length),
        .cdm_top_msgst_op					(cdm_top_msgst_op),
        .cdm_top_msgst_rdy					(cdm_top_msgst_tready),
        .cdm_top_msgst_response_cookie		(cdm_top_msgst_response_cookie),
        .cdm_top_msgst_response_req			(cdm_top_msgst_response_req),
        .cdm_top_msgst_st2m_ordered			(cdm_top_msgst_st2m_ordered),
        .cdm_top_msgst_start_offset			(cdm_top_msgst_start_offset),
        .cdm_top_msgst_tph					(cdm_top_msgst_tph),
        .cdm_top_msgst_vld					(cdm_top_msgst_tvalid),
        .cdm_top_msgst_wait_pld_pkt_id		(cdm_top_msgst_wait_pld_pkt_id),
		
        .atg_axi_araddr						(atg_axi_araddr),
        .atg_axi_arburst					(atg_axi_arburst),
        .atg_axi_arcache					(atg_axi_arcache),
        .atg_axi_arid						(atg_axi_arid),
        .atg_axi_arlen						(atg_axi_arlen),
        .atg_axi_arlock						(atg_axi_arlock),
        .atg_axi_arprot						(atg_axi_arprot),
        .atg_axi_arqos						(atg_axi_arqos),
        .atg_axi_arready					(atg_axi_arready),
        .atg_axi_arregion					(atg_axi_arregion),
        .atg_axi_arsize						(atg_axi_arsize),
        .atg_axi_aruser						(atg_axi_aruser),
        .atg_axi_arvalid					(atg_axi_arvalid),
        .atg_axi_awaddr						(atg_axi_awaddr),
        .atg_axi_awburst					(atg_axi_awburst),
        .atg_axi_awcache					(atg_axi_awcache),
        .atg_axi_awid						(atg_axi_awid),
        .atg_axi_awlen						(atg_axi_awlen),
        .atg_axi_awlock						(atg_axi_awlock),
        .atg_axi_awprot						(atg_axi_awprot),
        .atg_axi_awqos						(atg_axi_awqos),
        .atg_axi_awready					(atg_axi_awready),
        .atg_axi_awregion					(atg_axi_awregion),
        .atg_axi_awsize						(atg_axi_awsize),
        .atg_axi_awuser						(atg_axi_awuser),
        .atg_axi_awvalid					(atg_axi_awvalid),
        .atg_axi_bid						(atg_axi_bid),
        .atg_axi_bready						(atg_axi_bready),
        .atg_axi_bresp						(atg_axi_bresp),
        .atg_axi_bvalid						(atg_axi_bvalid),
        .atg_axi_rdata						(atg_axi_rdata),
        .atg_axi_rid						(atg_axi_rid),
        .atg_axi_rlast						(atg_axi_rlast),
        .atg_axi_rready						(atg_axi_rready),
        .atg_axi_rresp						(atg_axi_rresp),
        .atg_axi_rvalid						(atg_axi_rvalid),
        .atg_axi_wdata						(atg_axi_wdata),
        .atg_axi_wlast						(atg_axi_wlast),
        .atg_axi_wready						(atg_axi_wready),
        .atg_axi_wstrb						(atg_axi_wstrb),
        .atg_axi_wvalid						(atg_axi_wvalid),
		
		.axil_cmdram_araddr					(axil_cmdram_araddr),
        .axil_cmdram_arprot					(axil_cmdram_arprot),
        .axil_cmdram_arready				(axil_cmdram_arready),
        .axil_cmdram_arvalid				(axil_cmdram_arvalid),
        .axil_cmdram_awaddr					(axil_cmdram_awaddr),
        .axil_cmdram_awprot					(axil_cmdram_awprot),
        .axil_cmdram_awready				(axil_cmdram_awready),
        .axil_cmdram_awvalid				(axil_cmdram_awvalid),
        .axil_cmdram_bready					(axil_cmdram_bready),
        .axil_cmdram_bresp					(axil_cmdram_bresp),
        .axil_cmdram_bvalid					(axil_cmdram_bvalid),
        .axil_cmdram_rdata					(axil_cmdram_rdata),
        .axil_cmdram_rready					(axil_cmdram_rready),
        .axil_cmdram_rresp					(axil_cmdram_rresp),
        .axil_cmdram_rvalid					(axil_cmdram_rvalid),
        .axil_cmdram_wdata					(axil_cmdram_wdata),
        .axil_cmdram_wready					(axil_cmdram_wready),
        .axil_cmdram_wstrb					(axil_cmdram_wstrb),
        .axil_cmdram_wvalid					(axil_cmdram_wvalid),
		
		.axil_csi_exdes_araddr  			(csi_uport_axil_araddr  ),
        .axil_csi_exdes_arprot  			(csi_uport_axil_arprot  ),
        .axil_csi_exdes_arready 			(csi_uport_axil_arready ),
        .axil_csi_exdes_arvalid 			(csi_uport_axil_arvalid ),
        .axil_csi_exdes_awaddr  			(csi_uport_axil_awaddr  ),
        .axil_csi_exdes_awprot  			(csi_uport_axil_awprot  ),
        .axil_csi_exdes_awready 			(csi_uport_axil_awready ),
        .axil_csi_exdes_awvalid 			(csi_uport_axil_awvalid ),
        .axil_csi_exdes_bready  			(csi_uport_axil_bready  ),
        .axil_csi_exdes_bresp   			(csi_uport_axil_bresp   ),
        .axil_csi_exdes_bvalid  			(csi_uport_axil_bvalid  ),
        .axil_csi_exdes_rdata   			(csi_uport_axil_rdata   ),
        .axil_csi_exdes_rready  			(csi_uport_axil_rready  ),
        .axil_csi_exdes_rresp   			(csi_uport_axil_rresp   ),
        .axil_csi_exdes_rvalid  			(csi_uport_axil_rvalid  ),
        .axil_csi_exdes_wdata   			(csi_uport_axil_wdata   ),
        .axil_csi_exdes_wready  			(csi_uport_axil_wready  ),
        .axil_csi_exdes_wstrb   			(csi_uport_axil_wstrb   ),
        .axil_csi_exdes_wvalid  			(csi_uport_axil_wvalid  ),
		
        .cpm_gpo                            (cpm_gpo),
		.csi1_es1_wa_en                     (csi1_es1_wa_en),
		
        .csi1_dst_crdt_tdata				(csi1_dst_crdt_tdata),
        .csi1_dst_crdt_tready				(csi1_dst_crdt_tready),
        .csi1_dst_crdt_tvalid				(csi1_dst_crdt_tvalid),
        .csi1_local_crdt_buf_id				(csi1_local_crdt_buf_id),
        .csi1_local_crdt_data				(csi1_local_crdt_data),
        .csi1_local_crdt_flow_type			(csi1_local_crdt_flow_type),
        .csi1_local_crdt_rdy				(csi1_local_crdt_rdy),
        .csi1_local_crdt_snk_id				(csi1_local_crdt_snk_id),
        .csi1_local_crdt_src_furc_id		(csi1_local_crdt_src_furc_id),
        .csi1_local_crdt_vld				(csi1_local_crdt_vld),
		
        .csi1_npr_req_eop					(csi1_npr_req_eop),
        .csi1_npr_req_err					(csi1_npr_req_err),
        .csi1_npr_req_rdy					(csi1_npr_req_rdy),
        .csi1_npr_req_seg					(csi1_npr_req_seg),
        .csi1_npr_req_sop					(csi1_npr_req_sop),
        .csi1_npr_req_vld					(csi1_npr_req_vld),
		
        .csi1_prcmpl_req0_eop				(csi1_prcmpl_req0_eop),
        .csi1_prcmpl_req0_err				(csi1_prcmpl_req0_err),
        .csi1_prcmpl_req0_rdy				(csi1_prcmpl_req0_rdy),
        .csi1_prcmpl_req0_seg				(csi1_prcmpl_req0_seg),
        .csi1_prcmpl_req0_sop				(csi1_prcmpl_req0_sop),
        .csi1_prcmpl_req0_vld				(csi1_prcmpl_req0_vld),
		
        .csi1_prcmpl_req1_eop				(csi1_prcmpl_req1_eop),
        .csi1_prcmpl_req1_err				(csi1_prcmpl_req1_err),
        .csi1_prcmpl_req1_rdy				(csi1_prcmpl_req1_rdy),
        .csi1_prcmpl_req1_seg				(csi1_prcmpl_req1_seg),
        .csi1_prcmpl_req1_sop				(csi1_prcmpl_req1_sop),
        .csi1_prcmpl_req1_vld				(csi1_prcmpl_req1_vld),
        .csi1_resp0_eop						(csi1_resp0_eop),
        .csi1_resp0_err						(csi1_resp0_err),
        .csi1_resp0_rdy						(csi1_resp0_rdy),
        .csi1_resp0_seg						(csi1_resp0_seg),
        .csi1_resp0_sop						(csi1_resp0_sop),
        .csi1_resp0_vld						(csi1_resp0_vld),
		
        .csi1_resp1_eop						(csi1_resp1_eop),
        .csi1_resp1_err						(csi1_resp1_err),
        .csi1_resp1_rdy						(csi1_resp1_rdy),
        .csi1_resp1_seg						(csi1_resp1_seg),
        .csi1_resp1_sop						(csi1_resp1_sop),
        .csi1_resp1_vld						(csi1_resp1_vld),
        .gt_refclk0_clk_n					(gt_refclk0_clk_n),
        .gt_refclk0_clk_p					(gt_refclk0_clk_p),
        .pl0_ref_clk_0						(cpm_user_clk),
        .pl0_resetn_0						(user_reset_n),
        .sys_clk_ddr_clk_n                  (sys_clk_ddr_clk_n),
        .sys_clk_ddr_clk_p                  (sys_clk_ddr_clk_p)
		);
	
	  cdx5n_cmpt_msgst_if 			usr_msgst(); 
	  cdx5n_dsc_crd_in_msgld_req_if usr_msgld_req();
	  cdx5n_mm_byp_out_rsp_if     usr_msgld_dat();
	
	
	assign usr_msgld_dat.intf.client_id					=	cdm_top_msgld_dat_client_id_int;
	assign usr_msgld_dat.intf.dsc						=	cdm_top_msgld_dat_data_int;
	assign usr_msgld_dat.intf.ecc						=	cdm_top_msgld_dat_ecc_int;
	assign usr_msgld_dat.intf.eop						=	cdm_top_msgld_dat_eop_int;
	assign usr_msgld_dat.intf.u.cdm.err_status			=	cdm_top_msgld_dat_err_status_int;
	assign usr_msgld_dat.intf.u.cdm.error				=	cdm_top_msgld_dat_error_int;
	assign usr_msgld_dat.intf.mty						=	cdm_top_msgld_dat_mty_int;
	assign usr_msgld_dat.intf.u.cdm.rc_id				=	cdm_top_msgld_dat_rc_id_int;		
	assign usr_msgld_dat.intf.u.cdm.response_cookie		=	cdm_top_msgld_dat_response_cookie_int;
	assign usr_msgld_dat.intf.u.cdm.start_offset		=	cdm_top_msgld_dat_start_offset_int;
	assign usr_msgld_dat.intf.u.cdm.status				=	cdm_top_msgld_dat_status_int;	
	assign usr_msgld_dat.intf.u.cdm.zero_byte			=	cdm_top_msgld_dat_zero_byte_int;
	
	assign	cdm_top_msgld_req_addr				=  {usr_msgld_req.intf.cmd.msgld.addr.u.imm.translated,usr_msgld_req.intf.cmd.msgld.addr.u.imm.addr,1'b0};
	assign	cdm_top_msgld_req_addr_spc			=  usr_msgld_req.intf.cmd.msgld.addr_spc;
	assign	cdm_top_msgld_req_attr				=  usr_msgld_req.intf.cmd.msgld.attr;
	assign	cdm_top_msgld_req_client_id			=  usr_msgld_req.intf.client_id;
	assign	cdm_top_msgld_req_data_width		=  usr_msgld_req.intf.cmd.msgld.data_width;
	assign	cdm_top_msgld_req_if_op				=  usr_msgld_req.intf.op;
	assign	cdm_top_msgld_req_length			=  usr_msgld_req.intf.cmd.msgld.length;
	assign	cdm_top_msgld_req_op				=  usr_msgld_req.intf.cmd.msgld.op;
	assign	cdm_top_msgld_req_rc_id				=	usr_msgld_req.intf.rc_id;
	assign	cdm_top_msgld_req_relaxed_read		=  usr_msgld_req.intf.cmd.msgld.relaxed_read;
	assign	cdm_top_msgld_req_response_cookie	=  usr_msgld_req.intf.cmd.msgld.response_cookie;
	assign	cdm_top_msgld_req_start_offset		=	usr_msgld_req.intf.cmd.msgld.start_offset;	
	
	assign	cdm_top_msgst_addr					=	{usr_msgst.intf.u.cdm_bal.cdm.addr.u.imm.translated,usr_msgst.intf.u.cdm_bal.cdm.addr.u.imm.addr,1'b0};
	assign	cdm_top_msgst_addr_spc				=	usr_msgst.intf.u.cdm_bal.cdm.addr_spc;
	assign	cdm_top_msgst_attr					=	usr_msgst.intf.u.cdm_bal.cdm.attr;
	assign	cdm_top_msgst_client_id				=	usr_msgst.intf.client_id;
	assign	cdm_top_msgst_data					=	usr_msgst.intf.dat;
	assign	cdm_top_msgst_data_width			=	usr_msgst.intf.data_width;
	assign	cdm_top_msgst_ecc					=	usr_msgst.intf.ecc;
	assign	cdm_top_msgst_eop					=	usr_msgst.intf.eop;
	assign	cdm_top_msgst_irq_vector			=	16'h0;
	assign	cdm_top_msgst_length				=	usr_msgst.intf.length;
	assign	cdm_top_msgst_op					=	usr_msgst.intf.op;		
	assign	cdm_top_msgst_response_cookie		=	usr_msgst.intf.u.cdm_bal.cdm.response_cookie;
	assign	cdm_top_msgst_response_req			=	usr_msgst.intf.u.cdm_bal.cdm.response_req;
	assign	cdm_top_msgst_st2m_ordered			=	usr_msgst.intf.u.cdm_bal.cdm.st2m_ordered;
	assign	cdm_top_msgst_start_offset			=	usr_msgst.intf.u.cdm_bal.cdm.start_offset;
	assign	cdm_top_msgst_tph					=	usr_msgst.intf.u.cdm_bal.cdm.tph;	
	assign	cdm_top_msgst_wait_pld_pkt_id		=	usr_msgst.intf.wait_pld_pkt_id;		
	
	assign usr_msgld_dat.vld       		= 	cdm_top_msgld_dat_tvalid_int;
	assign cdm_top_msgld_dat_tready		= 	usr_msgld_dat.rdy;
	
	assign usr_msgld_req.rdy			= cdm_top_msgld_req_tready;	
	assign cdm_top_msgld_req_tvalid	    = usr_msgld_req.vld;
	
	assign usr_msgst.rdy				= cdm_top_msgst_tready;	
	assign cdm_top_msgst_tvalid 		= usr_msgst.vld;
	
	
	
	cdm_msgld_msgst cdm_msgld_msgst_inst
(
	.fabric_clk			(cpm_user_clk),
	.fabric_rst_n		(user_reset_n),
	
	.S_AXI_CDM_araddr	(M_AXI_CDM_araddr),
	.S_AXI_CDM_arprot	(M_AXI_CDM_arprot),
	.S_AXI_CDM_arready	(M_AXI_CDM_arready),
	.S_AXI_CDM_arvalid	(M_AXI_CDM_arvalid),
	.S_AXI_CDM_awaddr	(M_AXI_CDM_awaddr),	
	.S_AXI_CDM_awprot	(M_AXI_CDM_awprot),	
	.S_AXI_CDM_awready	(M_AXI_CDM_awready),	
	.S_AXI_CDM_awvalid	(M_AXI_CDM_awvalid),	
	.S_AXI_CDM_bready	(M_AXI_CDM_bready),	
	.S_AXI_CDM_bresp	(M_AXI_CDM_bresp),	
	.S_AXI_CDM_bvalid	(M_AXI_CDM_bvalid),	
	.S_AXI_CDM_rdata	(M_AXI_CDM_rdata),	
	.S_AXI_CDM_rready	(M_AXI_CDM_rready),	
	.S_AXI_CDM_rresp	(M_AXI_CDM_rresp),	
	.S_AXI_CDM_rvalid	(M_AXI_CDM_rvalid),	
	.S_AXI_CDM_wdata	(M_AXI_CDM_wdata),
	.S_AXI_CDM_wready	(M_AXI_CDM_wready),	
	.S_AXI_CDM_wstrb	(M_AXI_CDM_wstrb),	
	.S_AXI_CDM_wvalid	(M_AXI_CDM_wvalid),
	
	.S_AXIL_CDMRAM_araddr	({16'h0,axil_cmdram_araddr[15:0]}),
    .S_AXIL_CDMRAM_arprot	(axil_cmdram_arprot),
    .S_AXIL_CDMRAM_arready	(axil_cmdram_arready),
    .S_AXIL_CDMRAM_arvalid	(axil_cmdram_arvalid),
    .S_AXIL_CDMRAM_awaddr	({16'h0,axil_cmdram_awaddr[15:0]}),
    .S_AXIL_CDMRAM_awprot	(axil_cmdram_awprot),
    .S_AXIL_CDMRAM_awready	(axil_cmdram_awready),
    .S_AXIL_CDMRAM_awvalid	(axil_cmdram_awvalid),
    .S_AXIL_CDMRAM_bready	(axil_cmdram_bready),
    .S_AXIL_CDMRAM_bresp	(axil_cmdram_bresp),
    .S_AXIL_CDMRAM_bvalid	(axil_cmdram_bvalid),
    .S_AXIL_CDMRAM_rdata	(axil_cmdram_rdata),
    .S_AXIL_CDMRAM_rready	(axil_cmdram_rready),
    .S_AXIL_CDMRAM_rresp	(axil_cmdram_rresp),
    .S_AXIL_CDMRAM_rvalid	(axil_cmdram_rvalid),
    .S_AXIL_CDMRAM_wdata	(axil_cmdram_wdata),
    .S_AXIL_CDMRAM_wready	(axil_cmdram_wready),
    .S_AXIL_CDMRAM_wstrb	(axil_cmdram_wstrb),
    .S_AXIL_CDMRAM_wvalid	(axil_cmdram_wvalid),
	
	.msgstld_perf_reg_araddr	(msgstld_perf_reg_araddr),
	.msgstld_perf_reg_arready	(msgstld_perf_reg_arready),
	.msgstld_perf_reg_arvalid	(msgstld_perf_reg_arvalid),
	.msgstld_perf_reg_awaddr	(msgstld_perf_reg_awaddr),
	.msgstld_perf_reg_awready	(msgstld_perf_reg_awready),
	.msgstld_perf_reg_awvalid	(msgstld_perf_reg_awvalid),
	.msgstld_perf_reg_bready	(msgstld_perf_reg_bready),
    .msgstld_perf_reg_bresp		(msgstld_perf_reg_bresp),
	.msgstld_perf_reg_bvalid	(msgstld_perf_reg_bvalid),
	.msgstld_perf_reg_rdata		(msgstld_perf_reg_rdata),
	.msgstld_perf_reg_rready	(msgstld_perf_reg_rready),
	.msgstld_perf_reg_rresp		(msgstld_perf_reg_rresp),
	.msgstld_perf_reg_rvalid	(msgstld_perf_reg_rvalid),
	.msgstld_perf_reg_wdata		(msgstld_perf_reg_wdata),
	.msgstld_perf_reg_wready	(msgstld_perf_reg_wready),
	.msgstld_perf_reg_wstrb		(msgstld_perf_reg_wstrb),
	.msgstld_perf_reg_wvalid	(msgstld_perf_reg_wvalid),
		
	.fab0_cmpt_msgst_fab_int		(usr_msgst),                   
	.fab0_byp_out_msgld_dat_fab_int	(usr_msgld_dat),            
	.fab0_dsc_crd_msgld_req_fab_int	(usr_msgld_req),		
	
	.msgst_cmd_fill_bram				(msgst_cmd_fill_bram),
	.msgld_cmd_fill_bram				(msgld_cmd_fill_bram), 
	
	.msgst_num_of_CMD				(msgst_top_num_of_CMD),
	.msgld_num_of_CMD				(msgld_top_num_of_CMD),
	
    .msgst_pld_cmd_req_vio(msgst_pld_cmd_req_vio), 
    .msgst_num_of_req_vio(msgst_num_of_req_vio),  
    .msgst_pcie0_host_addr_vio(msgst_pcie0_host_addr_vio),
     
    .msgld_pld_cmd_rd_start_vio(msgld_pld_cmd_rd_start_vio), 
    .msgld_num_of_req_vio(msgld_num_of_req_vio),  
    .msgld_pcie0_host_addr_vio(msgld_pcie0_host_addr_vio),
    
    .back_pres_vio(back_pres_vio),
    .halt_vio(halt_vio),
    .enforce_order_vio(enforce_order_vio)
);

msgst_ld_tg msgst_ld_tg_inst
(
    .fabric_clk			(cpm_user_clk),
	.fabric_rst_n		(user_reset_n),
	
	.M_AXI_CDM_araddr	(M_AXI_CDM_araddr),
	.M_AXI_CDM_arprot	(M_AXI_CDM_arprot),
	.M_AXI_CDM_arready	(M_AXI_CDM_arready),
	.M_AXI_CDM_arvalid	(M_AXI_CDM_arvalid),
	.M_AXI_CDM_awaddr	(M_AXI_CDM_awaddr),	
	.M_AXI_CDM_awprot	(M_AXI_CDM_awprot),	
	.M_AXI_CDM_awready	(M_AXI_CDM_awready),	
	.M_AXI_CDM_awvalid	(M_AXI_CDM_awvalid),	
	.M_AXI_CDM_bready	(M_AXI_CDM_bready),	
	.M_AXI_CDM_bresp	(M_AXI_CDM_bresp),	
	.M_AXI_CDM_bvalid	(M_AXI_CDM_bvalid),	
	.M_AXI_CDM_rdata	(M_AXI_CDM_rdata),	
	.M_AXI_CDM_rready	(M_AXI_CDM_rready),	
	.M_AXI_CDM_rresp	(M_AXI_CDM_rresp),	
	.M_AXI_CDM_rvalid	(M_AXI_CDM_rvalid),	
	.M_AXI_CDM_wdata	(M_AXI_CDM_wdata),
	.M_AXI_CDM_wready	(M_AXI_CDM_wready),	
	.M_AXI_CDM_wstrb	(M_AXI_CDM_wstrb),	
	.M_AXI_CDM_wvalid	(M_AXI_CDM_wvalid),
	
	.msgst_cmd_fill_bram 	 (msgst_cmd_fill_bram || msgst_cmd_fill_bram_vio),
	.msgld_cmd_fill_bram 	 (msgld_cmd_fill_bram || msgld_cmd_fill_bram_vio),
	.msgst_payload_fill_bram (msgst_payload_fill_bram || msgst_payload_fill_bram_vio),
	
	.msgst_num_of_CMD			(msgst_top_num_of_CMD),
	.msgld_num_of_CMD			(msgld_top_num_of_CMD),  
	
	.msgst_req_fill_start(msgst_req_fill_start_vio),
	.msgld_req_fill_start(msgld_req_fill_start_vio),
	.msgst_payload_fill_start(msgst_payload_fill_start_vio),
	.msgstld_CSI_DST     (msgstld_CSI_DST_vio),
	.msgstld_pld_length  (msgstld_pld_length_vio),
	.msgst_resp_cookie_vio (msgst_resp_cookie_vio),
	.msgld_resp_cookie_vio (msgld_resp_cookie_vio)
);

slave_bridge_tg slave_bridge_tg_inst
(
	.fabric_clk			(cpm_user_clk),
	.fabric_rst_n		(user_reset_n),
	
	.M_AXI_0_araddr		(atg_axi_araddr),
	.M_AXI_0_arburst	(atg_axi_arburst),
	.M_AXI_0_arcache	(atg_axi_arcache),
	.M_AXI_0_arid		(atg_axi_arid),
	.M_AXI_0_arlen		(atg_axi_arlen),
	.M_AXI_0_arlock		(atg_axi_arlock),
	.M_AXI_0_arprot		(atg_axi_arprot),
	.M_AXI_0_arqos		(atg_axi_arqos),
	.M_AXI_0_arready	(atg_axi_arready),
	.M_AXI_0_arregion	(atg_axi_arregion),
	.M_AXI_0_arsize		(atg_axi_arsize),
	.M_AXI_0_aruser		(atg_axi_aruser),
	.M_AXI_0_arvalid	(atg_axi_arvalid),
	.M_AXI_0_awaddr		(atg_axi_awaddr),
	.M_AXI_0_awburst	(atg_axi_awburst),
	.M_AXI_0_awcache	(atg_axi_awcache),
	.M_AXI_0_awid		(atg_axi_awid),
	.M_AXI_0_awlen		(atg_axi_awlen),
	.M_AXI_0_awlock		(atg_axi_awlock),
	.M_AXI_0_awprot		(atg_axi_awprot),
	.M_AXI_0_awqos		(atg_axi_awqos),
	.M_AXI_0_awready	(atg_axi_awready),
	.M_AXI_0_awregion	(atg_axi_awregion),
	.M_AXI_0_awsize		(atg_axi_awsize),
	.M_AXI_0_awuser		(atg_axi_awuser),
	.M_AXI_0_awvalid	(atg_axi_awvalid),
	.M_AXI_0_bid		(atg_axi_bid),
	.M_AXI_0_bready		(atg_axi_bready),
	.M_AXI_0_bresp		(atg_axi_bresp),
	.M_AXI_0_bvalid		(atg_axi_bvalid),
	.M_AXI_0_rdata		(atg_axi_rdata),
	.M_AXI_0_rid		(atg_axi_rid),
	.M_AXI_0_rlast		(atg_axi_rlast),
	.M_AXI_0_rready		(atg_axi_rready),
	.M_AXI_0_rresp		(atg_axi_rresp),
	.M_AXI_0_rvalid		(atg_axi_rvalid),
	.M_AXI_0_wdata		(atg_axi_wdata),
	.M_AXI_0_wlast		(atg_axi_wlast),
	.M_AXI_0_wready		(atg_axi_wready),
	.M_AXI_0_wstrb		(atg_axi_wstrb),
	.M_AXI_0_wvalid		(atg_axi_wvalid),
	
	.gen_wr				(gen_wr_vio),
	.gen_rd				(gen_rd_vio)	

);


msgld_st_vio msgld_st_vio_inst 
(
  .probe_in0			(msgst_req_fill_start_vio),    // input wire [0 : 0] probe_in0
  .probe_in1			(msgld_req_fill_start_vio),    // input wire [0 : 0] probe_in1
  .probe_in2			(msgst_payload_fill_start_vio),    // input wire [0 : 0] probe_in2
  .probe_out0			(msgst_pld_cmd_req_vio),  // output wire [0 : 0] probe_out0
  .probe_out1			(msgst_num_of_req_vio),  // output wire [14 : 0] probe_out1
  .probe_out2			(msgst_pcie0_host_addr_vio),  // output wire [31 : 0] probe_out2
  .probe_out3			(msgld_pld_cmd_rd_start_vio),  // output wire [0 : 0] probe_out3
  .probe_out4			(msgld_num_of_req_vio),  // output wire [14 : 0] probe_out4
  .probe_out5			(msgld_pcie0_host_addr_vio),  // output wire [31 : 0] probe_out5
  .probe_out6			(msgst_cmd_fill_bram_vio),  // output wire [0 : 0] probe_out6
  .probe_out7			(msgld_cmd_fill_bram_vio),  // output wire [0 : 0] probe_out7
  .probe_out8			(msgst_payload_fill_bram_vio),  // output wire [0 : 0] probe_out8
  .probe_out9			(gen_wr_vio),  // output wire [0 : 0] probe_out9
  .probe_out10			(gen_rd_vio),  // output wire [0 : 0] probe_out10
  .probe_out11			(msgstld_CSI_DST_vio),  // output wire [4 : 0] probe_out11
  .probe_out12			(msgstld_pld_length_vio),  // output wire [8 : 0] probe_out12
  .probe_out13			(msgst_resp_cookie_vio),  // output wire [11 : 0] probe_out13
  .probe_out14			(msgld_resp_cookie_vio),  // output wire [11 : 0] probe_out14
  .probe_out15			(csi1_es1_wa_en),  // output wire [0 : 0] probe_out15
  .probe_out16			(back_pres_vio),  // output wire [2 : 0] probe_out16
  .probe_out17			(halt_vio),  // output wire [2 : 0] probe_out17
  .probe_out18			(enforce_order_vio),  // output wire [0 : 0] probe_out18
  .clk					(cpm_user_clk)                // input wire clk
);

csi_uport #(
    .USER_PORT_INST ("PORT2")
  ) csi_uport_inst (
  
       .clk                      (cpm_user_clk), 
       .rst_n                    (user_reset_n),
    
       .f2csi_prcmplout          (f2csi_port0_prcmpl_in),
       .f2csi_npr_out            (f2csi_port0_npr_in),
       .csi2f_in                 (csi2f_port0_out),
       .local_crdt_in            (local_crdt_port0_out),
       .dest_crdt                (dest_crdt_port0_in),
        
       .S_AXI_UPORT_araddr       (axi_vip_en ? axi_vip_axil_araddr  : csi_uport_axil_araddr   ),      
       .S_AXI_UPORT_arprot       (axi_vip_en ? axi_vip_axil_arprot  : csi_uport_axil_arprot   ), 
       .S_AXI_UPORT_arready      (csi_uport_axil_arready  ), 
       .S_AXI_UPORT_arvalid      (axi_vip_en ? axi_vip_axil_arvalid : csi_uport_axil_arvalid  ), 
       .S_AXI_UPORT_awaddr       (axi_vip_en ? axi_vip_axil_awaddr  : csi_uport_axil_awaddr   ), 
       .S_AXI_UPORT_awprot       (axi_vip_en ? axi_vip_axil_awprot  : csi_uport_axil_awprot   ),
       .S_AXI_UPORT_awready      (csi_uport_axil_awready  ), 
       .S_AXI_UPORT_awvalid      (axi_vip_en ? axi_vip_axil_awvalid : csi_uport_axil_awvalid  ), 
       .S_AXI_UPORT_bready       (axi_vip_en ? axi_vip_axil_bready  : csi_uport_axil_bready   ), 
       .S_AXI_UPORT_bresp        (csi_uport_axil_bresp    ), 
       .S_AXI_UPORT_bvalid       (csi_uport_axil_bvalid   ), 
       .S_AXI_UPORT_rdata        (csi_uport_axil_rdata    ), 
       .S_AXI_UPORT_rready       (axi_vip_en ? axi_vip_axil_rready  : csi_uport_axil_rready   ), 
       .S_AXI_UPORT_rresp        (csi_uport_axil_rresp    ), 
       .S_AXI_UPORT_rvalid       (csi_uport_axil_rvalid   ), 
       .S_AXI_UPORT_wdata        (axi_vip_en ? axi_vip_axil_wdata   : csi_uport_axil_wdata    ), 
       .S_AXI_UPORT_wready       (csi_uport_axil_wready   ), 
       .S_AXI_UPORT_wstrb        (axi_vip_en ? axi_vip_axil_wstrb   : csi_uport_axil_wstrb    ), 
       .S_AXI_UPORT_wvalid       (axi_vip_en ? axi_vip_axil_wvalid  : csi_uport_axil_wvalid   ) 
       
  );
  
  msgstld_perf msgstld_perf_inst (

        .cdm_top_msgld_dat_data				(cdm_top_msgld_dat_data_int),        
        .cdm_top_msgld_dat_eop				(cdm_top_msgld_dat_eop_int),
        .cdm_top_msgld_dat_err_status		(cdm_top_msgld_dat_err_status_int),
        .cdm_top_msgld_dat_error			(cdm_top_msgld_dat_error_int),                
        .cdm_top_msgld_dat_tready			(cdm_top_msgld_dat_tready),
        .cdm_top_msgld_dat_response_cookie	(cdm_top_msgld_dat_response_cookie_int),        
        .cdm_top_msgld_dat_status			(cdm_top_msgld_dat_status_int),
        .cdm_top_msgld_dat_tvalid			(cdm_top_msgld_dat_tvalid_int),     

        .cdm_top_msgld_req_tready			(cdm_top_msgld_req_tready),
        .cdm_top_msgld_req_tvalid			(cdm_top_msgld_req_tvalid),
		
        .cdm_top_msgst_tready				(cdm_top_msgst_tready),
        .cdm_top_msgst_tvalid				(cdm_top_msgst_tvalid),
		.cdm_top_msgst_eop					(cdm_top_msgst_eop),

	// AXI interface

		.axi_aclk		(cpm_user_clk),	
		.axi_aresetn	(user_reset_n),		
		.axi_awaddr		(msgstld_perf_reg_awaddr),		
		.axi_awready	(msgstld_perf_reg_awready),	
		.axi_awvalid	(msgstld_perf_reg_awvalid),	
		.axi_araddr		(msgstld_perf_reg_araddr),		
		.axi_arready	(msgstld_perf_reg_arready),	
		.axi_arvalid	(msgstld_perf_reg_arvalid),	
		.axi_wdata		(msgstld_perf_reg_wdata),		
		.axi_wstrb		(msgstld_perf_reg_wstrb),		
		.axi_wready		(msgstld_perf_reg_wready),		
		.axi_wvalid		(msgstld_perf_reg_wvalid),		
		.axi_rdata		(msgstld_perf_reg_rdata),		
		.axi_rresp		(msgstld_perf_reg_rresp),		
		.axi_rready		(msgstld_perf_reg_rready),		
		.axi_rvalid		(msgstld_perf_reg_rvalid),		
		.axi_bresp		(msgstld_perf_reg_bresp),		
		.axi_bready		(msgstld_perf_reg_bready),		
		.axi_bvalid		(msgstld_perf_reg_bvalid)
); 
/*
  //synthesis translate off
  assign axi_vip_en = 1;

  axi_vip_0 U_DRIVER_UB_AXI4L(
      .aclk            (cpm_user_clk),
      .aresetn         (user_reset_n),
      
      .m_axi_awaddr    (axi_vip_axil_awaddr  ),  //csi_uport_axil_awaddr  ),
      .m_axi_awprot    (axi_vip_axil_awprot  ),  //csi_uport_axil_awprot  ),
      .m_axi_awvalid   (axi_vip_axil_awvalid ),  //csi_uport_axil_awvalid ),
      .m_axi_awready   (csi_uport_axil_awready ),  //csi_uport_axil_awready ),
      .m_axi_wdata     (axi_vip_axil_wdata   ),  //csi_uport_axil_wdata   ),
      .m_axi_wstrb     (axi_vip_axil_wstrb   ),  //csi_uport_axil_wstrb   ),
      .m_axi_wvalid    (axi_vip_axil_wvalid  ),  //csi_uport_axil_wvalid  ),
      .m_axi_wready    (csi_uport_axil_wready  ),  //csi_uport_axil_wready  ),
      .m_axi_bresp     (csi_uport_axil_bresp   ),  //csi_uport_axil_bresp   ),
      .m_axi_bvalid    (axi_vip_en && csi_uport_axil_bvalid  ),  //csi_uport_axil_bvalid  ),
      .m_axi_bready    (axi_vip_axil_bready  ),  //csi_uport_axil_bready  ),
      .m_axi_araddr    (axi_vip_axil_araddr  ),  //csi_uport_axil_araddr  ),
      .m_axi_arprot    (axi_vip_axil_arprot  ),  //csi_uport_axil_arprot  ),
      .m_axi_arvalid   (axi_vip_axil_arvalid ),  //csi_uport_axil_arvalid ),
      .m_axi_arready   (csi_uport_axil_arready ),  //csi_uport_axil_arready ),
      .m_axi_rdata     (csi_uport_axil_rdata   ),  //csi_uport_axil_rdata   ),
      .m_axi_rresp     (csi_uport_axil_rresp   ),  //csi_uport_axil_rresp   ),
      .m_axi_rvalid    (axi_vip_en && csi_uport_axil_rvalid  ),  //csi_uport_axil_rvalid  ),
      .m_axi_rready    (axi_vip_axil_rready  )   //csi_uport_axil_rready  )
    );
  axi_vip_master axi_vip_master_i ();
  // synthesis translate_on
	*/
endmodule
