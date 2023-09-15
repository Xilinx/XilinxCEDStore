`timescale 1ps / 1ps

`include "cpm5n_interface.svh"

module cdm_msgld_msgst_top
import cpm5n_v1_0_1_pkg::*;
(
    PCIE0_GT_0_grx_n,
    PCIE0_GT_0_grx_p,
    PCIE0_GT_0_gtx_n,
    PCIE0_GT_0_gtx_p,
    gt_refclk0_0_clk_n,
    gt_refclk0_0_clk_p
    );
    
    input  [15:0]    PCIE0_GT_0_grx_n;
    input  [15:0]    PCIE0_GT_0_grx_p;
    output [15:0]    PCIE0_GT_0_gtx_n;
    output [15:0]    PCIE0_GT_0_gtx_p;
    
    input            gt_refclk0_0_clk_n;
    input            gt_refclk0_0_clk_p;
    
    
    
    wire [15:0]      PCIE0_GT_0_grx_n;
    wire [15:0]      PCIE0_GT_0_grx_p;
    wire [15:0]      PCIE0_GT_0_gtx_n;
    wire [15:0]      PCIE0_GT_0_gtx_p;
    wire [388:0]     cdm0_msgld_dat_0_tdata;
    wire             cdm0_msgld_dat_0_tready;
    wire             cdm0_msgld_dat_0_tvalid;
    wire [164:0]     cdm0_msgld_req_0_tdata;
    wire             cdm0_msgld_req_0_tready;
    wire             cdm0_msgld_req_0_tvalid;
    wire [475:0]     cdm0_msgst_0_tdata;
    wire             cdm0_msgst_0_tready;
    wire             cdm0_msgst_0_tvalid;
    wire             cpm_bot_user_clk;
    wire             gt_refclk0_0_clk_n;
    wire             gt_refclk0_0_clk_p;
    reg              user_reset;
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
	
	logic msgst_cmd_fill_bram;
    logic msgld_cmd_fill_bram;
    logic msgst_payload_fill_bram;
	
	  cdx5n_cmpt_msgst_if 			usr_msgst(); 
	  cdx5n_dsc_crd_in_msgld_req_if usr_msgld_req();
	  cdx5n_mm_byp_out_rsp_if     usr_msgld_dat();
	
          design_1_wrapper design_ep_wrapper_i

       (
		.PCIE0_GT_0_grx_n				(PCIE0_GT_0_grx_n),
        .PCIE0_GT_0_grx_p				(PCIE0_GT_0_grx_p),
        .PCIE0_GT_0_gtx_n				(PCIE0_GT_0_gtx_n),
        .PCIE0_GT_0_gtx_p				(PCIE0_GT_0_gtx_p),
        .cdm0_msgld_dat_0_client_id (usr_msgld_dat.intf.client_id),
        .cdm0_msgld_dat_0_data (usr_msgld_dat.intf.dsc),
        .cdm0_msgld_dat_0_ecc (usr_msgld_dat.intf.ecc),
        .cdm0_msgld_dat_0_eop (usr_msgld_dat.intf.eop),
        .cdm0_msgld_dat_0_err_status (usr_msgld_dat.intf.u.cdm.err_status),
        .cdm0_msgld_dat_0_error (usr_msgld_dat.intf.u.cdm.error),
        .cdm0_msgld_dat_0_mty (usr_msgld_dat.intf.mty),
        .cdm0_msgld_dat_0_rc_id (usr_msgld_dat.intf.u.cdm.rc_id),
        .cdm0_msgld_dat_0_rdy (usr_msgld_dat.rdy),
        .cdm0_msgld_dat_0_response_cookie (usr_msgld_dat.intf.u.cdm.response_cookie),
        .cdm0_msgld_dat_0_start_offset (usr_msgld_dat.intf.u.cdm.start_offset),
        .cdm0_msgld_dat_0_status (usr_msgld_dat.intf.u.cdm.status),
        .cdm0_msgld_dat_0_vld (usr_msgld_dat.vld),
        .cdm0_msgld_dat_0_zero_byte (usr_msgld_dat.intf.u.cdm.zero_byte),
        .cdm0_msgld_req_0_addr (usr_msgld_req.intf.cmd.msgld.addr),
        .cdm0_msgld_req_0_addr_spc (usr_msgld_req.intf.cmd.msgld.addr_spc),
        .cdm0_msgld_req_0_attr (usr_msgld_req.intf.cmd.msgld.attr),
        .cdm0_msgld_req_0_data_width (usr_msgld_req.intf.cmd.msgld.data_width),
        .cdm0_msgld_req_0_if_op (usr_msgld_req.intf.op),
        .cdm0_msgld_req_0_length (usr_msgld_req.intf.cmd.msgld.length),
        .cdm0_msgld_req_0_relaxed_read (usr_msgld_req.intf.cmd.msgld.relaxed_read),
        .cdm0_msgld_req_0_response_cookie (usr_msgld_req.intf.cmd.msgld.response_cookie),
        .cdm0_msgld_req_0_start_offset (usr_msgld_req.intf.cmd.msgld.start_offset),
        .cdm0_msgld_req_0_op (usr_msgld_req.intf.cmd.msgld.op),
        .cdm0_msgld_req_0_rc_id (usr_msgld_req.intf.rc_id),
        .cdm0_msgld_req_0_client_id (usr_msgld_req.intf.client_id),
        .cdm0_msgld_req_0_vld (usr_msgld_req.vld),
        .cdm0_msgld_req_0_rdy (usr_msgld_req.rdy),
        .cdm0_msgst_0_addr (usr_msgst.intf.u.cdm_bal.cdm.addr),
        .cdm0_msgst_0_addr_spc (usr_msgst.intf.op == CDM_MSG_STORE_MSG ? usr_msgst.intf.u.cdm_bal.cdm.addr_spc : usr_msgst.intf.u.intr_bal.intr.addr_spc),
        .cdm0_msgst_0_attr (usr_msgst.intf.op == CDM_MSG_STORE_MSG ? usr_msgst.intf.u.cdm_bal.cdm.attr : usr_msgst.intf.u.intr_bal.intr.attr),
        .cdm0_msgst_0_irq_vector (usr_msgst.intf.u.intr_bal.intr.irq_vector),
        .cdm0_msgst_0_length (usr_msgst.intf.length),
        .cdm0_msgst_0_op (usr_msgst.intf.op),
        .cdm0_msgst_0_rdy (usr_msgst.rdy),
        .cdm0_msgst_0_response_cookie (usr_msgst.intf.op == CDM_MSG_STORE_MSG ? usr_msgst.intf.u.cdm_bal.cdm.response_cookie : usr_msgst.intf.u.intr_bal.intr.response_cookie),
        .cdm0_msgst_0_response_req (usr_msgst.intf.op == CDM_MSG_STORE_MSG ? usr_msgst.intf.u.cdm_bal.cdm.response_req : usr_msgst.intf.u.intr_bal.intr.response_req),
        .cdm0_msgst_0_st2m_ordered (usr_msgst.intf.u.cdm_bal.cdm.st2m_ordered),
        .cdm0_msgst_0_start_offset (usr_msgst.intf.u.cdm_bal.cdm.start_offset[3:0]),
        .cdm0_msgst_0_tph ((usr_msgst.intf.op == CDM_MSG_STORE_MSG) ? usr_msgst.intf.u.cdm_bal.cdm.tph : usr_msgst.intf.u.intr_bal.intr.tph),
        .cdm0_msgst_0_vld (usr_msgst.vld),
        .cdm0_msgst_0_client_id (usr_msgst.intf.client_id),
        .cdm0_msgst_0_data (usr_msgst.intf.dat),
        .cdm0_msgst_0_data_width (usr_msgst.intf.data_width),
        .cdm0_msgst_0_ecc (usr_msgst.intf.ecc),
        .cdm0_msgst_0_eop (usr_msgst.intf.eop),
        .cdm0_msgst_0_wait_pld_pkt_id (usr_msgst.intf.wait_pld_pkt_id),
        .cdx_bot_rst_n_0                (~user_reset),
        .cpm_bot_user_clk_0				(cpm_bot_user_clk),
        .gt_refclk0_0_clk_n				(gt_refclk0_0_clk_n),
        .gt_refclk0_0_clk_p				(gt_refclk0_0_clk_p)

		);
	

		
	// assign cdm0_msgst_0_tdata 		= user_reset ? 476'h0 : usr_msgst.intf;
	// assign cdm0_msgld_req_0_tdata 	= user_reset ? 165'h0 : usr_msgld_req.intf;
	// assign usr_msgld_dat.intf      = cdm0_msgld_dat_0_tdata;
	// assign usr_msgld_dat.vld       = cdm0_msgld_dat_0_tvalid;
	// assign cdm0_msgld_dat_0_tready = usr_msgld_dat.rdy;
	
	
	cdm_msgld_msgst cdm_msgld_msgst_inst
(
	.fabric_clk(cpm_bot_user_clk),
	.fabric_rst_n(~user_reset),
	.S_AXI_CDM_araddr	(M_AXI_CDM_araddr),//msgst_rsp_status
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
	.fab0_cmpt_msgst_fab_int(usr_msgst),                   
	.fab0_byp_out_msgld_dat_fab_int(usr_msgld_dat),            
	.fab0_dsc_crd_msgld_req_fab_int(usr_msgld_req)  
);

msgst_ld_tg msgst_ld_tg_inst
(
    .fabric_clk(cpm_bot_user_clk),
	.fabric_rst_n(~user_reset),
	.M_AXI_CDM_araddr	(M_AXI_CDM_araddr),//msgst_rsp_status
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
	.msgst_cmd_fill_bram (msgst_cmd_fill_bram),
	.msgld_cmd_fill_bram (msgld_cmd_fill_bram),
	.msgst_payload_fill_bram (msgst_payload_fill_bram)

);


endmodule
