`timescale 1ps / 1ps



module cdm_msgld_msgst



(



	input fabric_clk,	

	input fabric_rst_n,	

	input [31:0]S_AXI_CDM_araddr,	

	input [2:0]S_AXI_CDM_arprot,	

	output S_AXI_CDM_arready,	

	input S_AXI_CDM_arvalid,	

	input [31:0]S_AXI_CDM_awaddr,	

	input [2:0]S_AXI_CDM_awprot,	

	output S_AXI_CDM_awready,	

	input S_AXI_CDM_awvalid,	

	input S_AXI_CDM_bready,	

	output [1:0]S_AXI_CDM_bresp,	

	output S_AXI_CDM_bvalid,	

	output [31:0]S_AXI_CDM_rdata,	

	input S_AXI_CDM_rready,	

	output [1:0]S_AXI_CDM_rresp,	

	output S_AXI_CDM_rvalid,	

	input [31:0]S_AXI_CDM_wdata,	

	output S_AXI_CDM_wready,	

	input [3:0]S_AXI_CDM_wstrb,	

	input S_AXI_CDM_wvalid,



	cdx5n_cmpt_msgst_if.m                         fab0_cmpt_msgst_fab_int,                   

	cdx5n_mm_byp_out_rsp_if.s                     fab0_byp_out_msgld_dat_fab_int,            

	cdx5n_dsc_crd_in_msgld_req_if.m               fab0_dsc_crd_msgld_req_fab_int  

          

);



  wire [31:0]MSGLD_CMD_RAM_addrb;

  wire [31:0]MSGLD_CMD_RAM_doutb;

  wire MSGLD_CMD_RAM_enb;

  wire [31:0]MSGLD_Payload_RAM_addrb;

  wire [255:0]MSGLD_Payload_RAM_dinb;

  wire [31:0]MSGLD_Payload_RAM_web;

  wire [31:0]MSGST_CMD_RAM_addrb;

  wire [31:0]MSGST_CMD_RAM_doutb;

  wire MSGST_CMD_RAM_enb;

  wire [31:0]MSGST_Payload_RAM_addrb;

  wire [255:0]MSGST_Payload_RAM_dinb;

  wire [31:0]MSGST_Payload_RAM_web;

  wire [31:0]MSG_Response_RAM_addrb;

  wire [31:0]MSG_Response_RAM_dinb;

  wire [3:0]MSG_Response_RAM_web;

  wire [31:0]M_CDM_ADAPT_CTRL_REGS_araddr;

  wire [2:0]M_CDM_ADAPT_CTRL_REGS_arprot;

  wire M_CDM_ADAPT_CTRL_REGS_arready;

  wire M_CDM_ADAPT_CTRL_REGS_arvalid;

  wire [31:0]M_CDM_ADAPT_CTRL_REGS_awaddr;

  wire [2:0]M_CDM_ADAPT_CTRL_REGS_awprot;

  wire M_CDM_ADAPT_CTRL_REGS_awready;

  wire M_CDM_ADAPT_CTRL_REGS_awvalid;

  wire M_CDM_ADAPT_CTRL_REGS_bready;

  wire [1:0]M_CDM_ADAPT_CTRL_REGS_bresp;

  wire M_CDM_ADAPT_CTRL_REGS_bvalid;

  wire [31:0]M_CDM_ADAPT_CTRL_REGS_rdata;

  wire M_CDM_ADAPT_CTRL_REGS_rready;

  wire [1:0]M_CDM_ADAPT_CTRL_REGS_rresp;

  wire M_CDM_ADAPT_CTRL_REGS_rvalid;

  wire [31:0]M_CDM_ADAPT_CTRL_REGS_wdata;

  wire M_CDM_ADAPT_CTRL_REGS_wready;

  wire [3:0]M_CDM_ADAPT_CTRL_REGS_wstrb;

  wire M_CDM_ADAPT_CTRL_REGS_wvalid;


  wire [255:0] cmd_ram_din;	 			// cmd ram data bus is 256 bit width

  wire 		   cmd_ram_ren;     		// RAM enable

  wire [31:0]  cmd_ram_addr;	 		// 32 bit address bus

  wire [31:0]  cmd_ram_web;     		// Byte strobes


   wire [31:0]  soft_rst_n;



  cdm_usr_ram_wrapper i_cdm_msg_st_ld_adapter_bd_logic_wrapper

       (


	    .MSGLD_CMD_RAM_addrb(MSGLD_CMD_RAM_addrb),

        .MSGLD_CMD_RAM_doutb(MSGLD_CMD_RAM_doutb),

        .MSGLD_CMD_RAM_enb(MSGLD_CMD_RAM_enb),

        .MSGLD_Payload_RAM_addrb(MSGLD_Payload_RAM_addrb),

        .MSGLD_Payload_RAM_dinb(MSGLD_Payload_RAM_dinb),

        .MSGLD_Payload_RAM_web(MSGLD_Payload_RAM_web),

        .MSGST_CMD_RAM_addrb(MSGST_CMD_RAM_addrb),

        .MSGST_CMD_RAM_doutb(MSGST_CMD_RAM_doutb),

        .MSGST_CMD_RAM_enb(MSGST_CMD_RAM_enb),

        .MSGST_Payload_RAM_addrb(MSGST_Payload_RAM_addrb),

        .MSGST_Payload_RAM_dinb(MSGST_Payload_RAM_dinb),

        .MSGST_Payload_RAM_web(MSGST_Payload_RAM_web),

        .MSG_Response_RAM_addrb(MSG_Response_RAM_addrb),

        .MSG_Response_RAM_dinb(MSG_Response_RAM_dinb),

        .MSG_Response_RAM_web(MSG_Response_RAM_web),

        .M_CDM_ADAPT_CTRL_REGS_araddr(M_CDM_ADAPT_CTRL_REGS_araddr),

        .M_CDM_ADAPT_CTRL_REGS_arprot(),

        .M_CDM_ADAPT_CTRL_REGS_arready(M_CDM_ADAPT_CTRL_REGS_arready),

        .M_CDM_ADAPT_CTRL_REGS_arvalid(M_CDM_ADAPT_CTRL_REGS_arvalid),

        .M_CDM_ADAPT_CTRL_REGS_awaddr(M_CDM_ADAPT_CTRL_REGS_awaddr),

        .M_CDM_ADAPT_CTRL_REGS_awprot(),

        .M_CDM_ADAPT_CTRL_REGS_awready(M_CDM_ADAPT_CTRL_REGS_awready),

        .M_CDM_ADAPT_CTRL_REGS_awvalid(M_CDM_ADAPT_CTRL_REGS_awvalid),

        .M_CDM_ADAPT_CTRL_REGS_bready(M_CDM_ADAPT_CTRL_REGS_bready),

        .M_CDM_ADAPT_CTRL_REGS_bresp(M_CDM_ADAPT_CTRL_REGS_bresp),

        .M_CDM_ADAPT_CTRL_REGS_bvalid(M_CDM_ADAPT_CTRL_REGS_bvalid),

        .M_CDM_ADAPT_CTRL_REGS_rdata(M_CDM_ADAPT_CTRL_REGS_rdata),

        .M_CDM_ADAPT_CTRL_REGS_rready(M_CDM_ADAPT_CTRL_REGS_rready),

        .M_CDM_ADAPT_CTRL_REGS_rresp(M_CDM_ADAPT_CTRL_REGS_rresp),

        .M_CDM_ADAPT_CTRL_REGS_rvalid(M_CDM_ADAPT_CTRL_REGS_rvalid),

        .M_CDM_ADAPT_CTRL_REGS_wdata(M_CDM_ADAPT_CTRL_REGS_wdata),

        .M_CDM_ADAPT_CTRL_REGS_wready(M_CDM_ADAPT_CTRL_REGS_wready),

        .M_CDM_ADAPT_CTRL_REGS_wstrb(M_CDM_ADAPT_CTRL_REGS_wstrb),

        .M_CDM_ADAPT_CTRL_REGS_wvalid(M_CDM_ADAPT_CTRL_REGS_wvalid),


        .S_AXI_CDM_araddr(S_AXI_CDM_araddr),

        .S_AXI_CDM_arprot(S_AXI_CDM_arprot),

        .S_AXI_CDM_arready(S_AXI_CDM_arready),

        .S_AXI_CDM_arvalid(S_AXI_CDM_arvalid),

        .S_AXI_CDM_awaddr(S_AXI_CDM_awaddr),

        .S_AXI_CDM_awprot(S_AXI_CDM_awprot),

        .S_AXI_CDM_awready(S_AXI_CDM_awready),

        .S_AXI_CDM_awvalid(S_AXI_CDM_awvalid),

        .S_AXI_CDM_bready(S_AXI_CDM_bready),

        .S_AXI_CDM_bresp(S_AXI_CDM_bresp),

        .S_AXI_CDM_bvalid(S_AXI_CDM_bvalid),

        .S_AXI_CDM_rdata(S_AXI_CDM_rdata),

        .S_AXI_CDM_rready(S_AXI_CDM_rready),

        .S_AXI_CDM_rresp(S_AXI_CDM_rresp),

        .S_AXI_CDM_rvalid(S_AXI_CDM_rvalid),

        .S_AXI_CDM_wdata(S_AXI_CDM_wdata),

        .S_AXI_CDM_wready(S_AXI_CDM_wready),

        .S_AXI_CDM_wstrb(S_AXI_CDM_wstrb),

        .S_AXI_CDM_wvalid(S_AXI_CDM_wvalid),

        .clk_in(fabric_clk),

        .rst_n(fabric_rst_n));

		

  

  //wire [31:0]host_ctrl_reg;

  wire [31:0]psx_host_ctrl_reg;  

  wire [31:0]pci0_host_ctrl_reg;

  //wire [31:0]host_reqid;

  wire [31:0]psx_host_reqid;  

  wire [31:0]pci0_host_reqid;



  wire [31:0]msgld_rsp_status;



  wire [31:0]msg_ctrl_reg_0;

  

  wire [31:0]msg_ctrl_reg_1;



  wire [31:0]msgst_rsp_status;

  

  wire [31:0] msgld_pass_counter_stats;

  

  wire [31:0] msgld_fail_counter_stats;

  

  //wire [31:0] host_addr_0, host_addr_1;

  wire [31:0] psx_msgst_host_addr_0, psx_msgst_host_addr_1;  

  wire [31:0] psx_msgld_host_addr_0, psx_msgld_host_addr_1;  

  wire [31:0] pci0_msgst_host_addr_0, pci0_msgst_host_addr_1;  

  wire [31:0] pci0_msgld_host_addr_0, pci0_msgld_host_addr_1;

  

cdm_adapt_ctrl_regs i_cdm_adapt_ctrl_regs (

  

        .msg_ctrl_reg_0(msg_ctrl_reg_0),

        .msg_ctrl_reg_1(msg_ctrl_reg_1),

		.psx_msgst_host_addr_0(psx_msgst_host_addr_0),

		.psx_msgst_host_addr_1(psx_msgst_host_addr_1),

        .psx_host_reqid(psx_host_reqid),

        .psx_host_ctrl_reg(psx_host_ctrl_reg),

		.psx_msgld_host_addr_0(psx_msgld_host_addr_0),

		.psx_msgld_host_addr_1(psx_msgld_host_addr_1),

		.pci0_msgst_host_addr_0(pci0_msgst_host_addr_0),

		.pci0_msgst_host_addr_1(pci0_msgst_host_addr_1),

        .pci0_host_reqid(pci0_host_reqid),

        .pci0_host_ctrl_reg(pci0_host_ctrl_reg),

		.pci0_msgld_host_addr_0(pci0_msgld_host_addr_0),

		.pci0_msgld_host_addr_1(pci0_msgld_host_addr_1),

        .msgst_rsp_status({31'd0, msgst_rsp_status[0]}),

        .msgld_rsp_status({31'd0, msgld_rsp_status[0]}),

        .msgld_pass_counter_stats(msgld_pass_counter_stats),

		.msgld_fail_counter_stats(msgld_fail_counter_stats),


		.soft_rst_n(soft_rst_n),

		// AXI interface

		.axi_aclk(fabric_clk),		

		.axi_aresetn(fabric_rst_n),		

		.axi_awaddr(M_CDM_ADAPT_CTRL_REGS_awaddr),		

		.axi_awready(M_CDM_ADAPT_CTRL_REGS_awready),		

		.axi_awvalid(M_CDM_ADAPT_CTRL_REGS_awvalid),		

		.axi_araddr(M_CDM_ADAPT_CTRL_REGS_araddr),		

		.axi_arready(M_CDM_ADAPT_CTRL_REGS_arready),		

		.axi_arvalid(M_CDM_ADAPT_CTRL_REGS_arvalid),		

		.axi_wdata(M_CDM_ADAPT_CTRL_REGS_wdata),		

		.axi_wstrb(M_CDM_ADAPT_CTRL_REGS_wstrb),		

		.axi_wready(M_CDM_ADAPT_CTRL_REGS_wready),		

		.axi_wvalid(M_CDM_ADAPT_CTRL_REGS_wvalid),		

		.axi_rdata(M_CDM_ADAPT_CTRL_REGS_rdata),		

		.axi_rresp(M_CDM_ADAPT_CTRL_REGS_rresp),		

		.axi_rready(M_CDM_ADAPT_CTRL_REGS_rready),		

		.axi_rvalid(M_CDM_ADAPT_CTRL_REGS_rvalid),		

		.axi_bresp(M_CDM_ADAPT_CTRL_REGS_bresp),		

		.axi_bready(M_CDM_ADAPT_CTRL_REGS_bready),		

		.axi_bvalid(M_CDM_ADAPT_CTRL_REGS_bvalid),
		
		.msgst_dbg0(32'h0),
		.msgst_dbg1(32'h0),
		.msgld_dbg0(32'h0),
		.msgld_dbg1(32'h0),
		.msgld_dbg2(32'h0)

	);



msgst_engine CDM_adapter_msgst (

    .clk(fabric_clk),

    .rst_n(fabric_rst_n & soft_rst_n[0]),

    .pld_ram_din(MSGST_Payload_RAM_dinb),

    .pld_ram_wen(MSGST_Payload_RAM_web),

    .pld_ram_addr(MSGST_Payload_RAM_addrb),

    .cmd_ram_din(MSGST_CMD_RAM_doutb),

    .cmd_ram_ren(MSGST_CMD_RAM_enb),

    .cmd_ram_addr(MSGST_CMD_RAM_addrb),

    .pci_host_addr({pci0_msgst_host_addr_1,pci0_msgst_host_addr_0}),

    .pci_pasid('d0),

    .pci_requester_id(pci0_host_reqid[15:0]),

    .psx_host_addr({psx_msgst_host_addr_1,psx_msgst_host_addr_0}),

    .psx_pasid('d0),

    .psx_requester_id(psx_host_reqid[15:0]),



    .num_of_reqs(msg_ctrl_reg_0[15:1]),



    .req_done(msgst_rsp_status[0]),



    .pld_cmd_req((msg_ctrl_reg_0[0] & psx_host_ctrl_reg[0]) || (msg_ctrl_reg_0[0] & pci0_host_ctrl_reg[0])),



    .fab0_cmpt_msgst(fab0_cmpt_msgst_fab_int)

    );



msgld_engine CDM_adapter_msgld (

    .clk(fabric_clk),	

    .rst_n(fabric_rst_n & soft_rst_n[0]),	

	.pld_ram_dout(MSGLD_Payload_RAM_dinb),	

    .pld_ram_wen(MSGLD_Payload_RAM_web),	

	.pld_ram_addr(MSGLD_Payload_RAM_addrb),	

    .rsp_ram_dout(MSG_Response_RAM_dinb),	

    .rsp_ram_wen(MSG_Response_RAM_web),	

    .rsp_ram_addr(MSG_Response_RAM_addrb),	

    .cmd_ram_din(MSGLD_CMD_RAM_doutb),	

    .cmd_ram_ren(MSGLD_CMD_RAM_enb),	

    .cmd_ram_addr(MSGLD_CMD_RAM_addrb),

    .pci_host_addr({pci0_msgld_host_addr_1,pci0_msgld_host_addr_0}),

    .pci_pasid('d0),

    .pci_requester_id(pci0_host_reqid[15:0]),

    .psx_host_addr({psx_msgld_host_addr_1,psx_msgld_host_addr_0}),

    .psx_pasid('d0),

    .psx_requester_id(psx_host_reqid[15:0]),



    .num_of_reqs(msg_ctrl_reg_0[31:17]),

	

    .req_done(msgld_rsp_status[0]),	

	

    .cmd_rd_start((msg_ctrl_reg_0[16] & psx_host_ctrl_reg[0]) || (msg_ctrl_reg_0[16] & pci0_host_ctrl_reg[0])),

	

	.start_pkt_count(msg_ctrl_reg_1[0]),

	

	.pkt_pass_count(msgld_pass_counter_stats),

	

	.pkt_fail_count(msgld_fail_counter_stats),

	

	.fab0_byp_out_msgld_dat(fab0_byp_out_msgld_dat_fab_int),	

	.fab0_dsc_crd_msgld_req(fab0_dsc_crd_msgld_req_fab_int)

    

); 





endmodule



