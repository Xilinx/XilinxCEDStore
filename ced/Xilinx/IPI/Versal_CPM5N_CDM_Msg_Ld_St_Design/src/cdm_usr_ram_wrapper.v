//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3627241 Sun Aug 28 20:17:06 MDT 2022
//Date        : Tue Aug 30 12:14:28 2022
//Host        : xsjrdevl155 running 64-bit CentOS Linux release 7.5.1804 (Core)
//Command     : generate_target cdm_usr_ram_wrapper.bd
//Design      : cdm_usr_ram_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module cdm_usr_ram_wrapper
   (MSGLD_CMD_RAM_addrb,
    MSGLD_CMD_RAM_doutb,
    MSGLD_CMD_RAM_enb,
    MSGLD_Payload_RAM_addrb,
    MSGLD_Payload_RAM_dinb,
    MSGLD_Payload_RAM_web,
    MSGST_CMD_RAM_addrb,
    MSGST_CMD_RAM_doutb,
    MSGST_CMD_RAM_enb,
    MSGST_Payload_RAM_addrb,
    MSGST_Payload_RAM_dinb,
    MSGST_Payload_RAM_web,
    MSG_Response_RAM_addrb,
    MSG_Response_RAM_dinb,
    MSG_Response_RAM_web,
    M_CDM_ADAPT_CTRL_REGS_araddr,
    M_CDM_ADAPT_CTRL_REGS_arprot,
    M_CDM_ADAPT_CTRL_REGS_arready,
    M_CDM_ADAPT_CTRL_REGS_arvalid,
    M_CDM_ADAPT_CTRL_REGS_awaddr,
    M_CDM_ADAPT_CTRL_REGS_awprot,
    M_CDM_ADAPT_CTRL_REGS_awready,
    M_CDM_ADAPT_CTRL_REGS_awvalid,
    M_CDM_ADAPT_CTRL_REGS_bready,
    M_CDM_ADAPT_CTRL_REGS_bresp,
    M_CDM_ADAPT_CTRL_REGS_bvalid,
    M_CDM_ADAPT_CTRL_REGS_rdata,
    M_CDM_ADAPT_CTRL_REGS_rready,
    M_CDM_ADAPT_CTRL_REGS_rresp,
    M_CDM_ADAPT_CTRL_REGS_rvalid,
    M_CDM_ADAPT_CTRL_REGS_wdata,
    M_CDM_ADAPT_CTRL_REGS_wready,
    M_CDM_ADAPT_CTRL_REGS_wstrb,
    M_CDM_ADAPT_CTRL_REGS_wvalid,
    S_AXI_CDM_araddr,
    S_AXI_CDM_arprot,
    S_AXI_CDM_arready,
    S_AXI_CDM_arvalid,
    S_AXI_CDM_awaddr,
    S_AXI_CDM_awprot,
    S_AXI_CDM_awready,
    S_AXI_CDM_awvalid,
    S_AXI_CDM_bready,
    S_AXI_CDM_bresp,
    S_AXI_CDM_bvalid,
    S_AXI_CDM_rdata,
    S_AXI_CDM_rready,
    S_AXI_CDM_rresp,
    S_AXI_CDM_rvalid,
    S_AXI_CDM_wdata,
    S_AXI_CDM_wready,
    S_AXI_CDM_wstrb,
    S_AXI_CDM_wvalid,
    clk_in,
    rst_n);
  input [31:0]MSGLD_CMD_RAM_addrb;
  output [31:0]MSGLD_CMD_RAM_doutb;
  input MSGLD_CMD_RAM_enb;
  input [31:0]MSGLD_Payload_RAM_addrb;
  input [255:0]MSGLD_Payload_RAM_dinb;
  input [31:0]MSGLD_Payload_RAM_web;
  input [31:0]MSGST_CMD_RAM_addrb;
  output [31:0]MSGST_CMD_RAM_doutb;
  input MSGST_CMD_RAM_enb;
  input [31:0]MSGST_Payload_RAM_addrb;
  input [255:0]MSGST_Payload_RAM_dinb;
  input [31:0]MSGST_Payload_RAM_web;
  input [31:0]MSG_Response_RAM_addrb;
  input [31:0]MSG_Response_RAM_dinb;
  input [3:0]MSG_Response_RAM_web;
  output [31:0]M_CDM_ADAPT_CTRL_REGS_araddr;
  output [2:0]M_CDM_ADAPT_CTRL_REGS_arprot;
  input M_CDM_ADAPT_CTRL_REGS_arready;
  output M_CDM_ADAPT_CTRL_REGS_arvalid;
  output [31:0]M_CDM_ADAPT_CTRL_REGS_awaddr;
  output [2:0]M_CDM_ADAPT_CTRL_REGS_awprot;
  input M_CDM_ADAPT_CTRL_REGS_awready;
  output M_CDM_ADAPT_CTRL_REGS_awvalid;
  output M_CDM_ADAPT_CTRL_REGS_bready;
  input [1:0]M_CDM_ADAPT_CTRL_REGS_bresp;
  input M_CDM_ADAPT_CTRL_REGS_bvalid;
  input [31:0]M_CDM_ADAPT_CTRL_REGS_rdata;
  output M_CDM_ADAPT_CTRL_REGS_rready;
  input [1:0]M_CDM_ADAPT_CTRL_REGS_rresp;
  input M_CDM_ADAPT_CTRL_REGS_rvalid;
  output [31:0]M_CDM_ADAPT_CTRL_REGS_wdata;
  input M_CDM_ADAPT_CTRL_REGS_wready;
  output [3:0]M_CDM_ADAPT_CTRL_REGS_wstrb;
  output M_CDM_ADAPT_CTRL_REGS_wvalid;
  input [31:0]S_AXI_CDM_araddr;
  input [2:0]S_AXI_CDM_arprot;
  output S_AXI_CDM_arready;
  input S_AXI_CDM_arvalid;
  input [31:0]S_AXI_CDM_awaddr;
  input [2:0]S_AXI_CDM_awprot;
  output S_AXI_CDM_awready;
  input S_AXI_CDM_awvalid;
  input S_AXI_CDM_bready;
  output [1:0]S_AXI_CDM_bresp;
  output S_AXI_CDM_bvalid;
  output [31:0]S_AXI_CDM_rdata;
  input S_AXI_CDM_rready;
  output [1:0]S_AXI_CDM_rresp;
  output S_AXI_CDM_rvalid;
  input [31:0]S_AXI_CDM_wdata;
  output S_AXI_CDM_wready;
  input [3:0]S_AXI_CDM_wstrb;
  input S_AXI_CDM_wvalid;
  input clk_in;
  input rst_n;

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
  wire [31:0]S_AXI_CDM_araddr;
  wire [2:0]S_AXI_CDM_arprot;
  wire S_AXI_CDM_arready;
  wire S_AXI_CDM_arvalid;
  wire [31:0]S_AXI_CDM_awaddr;
  wire [2:0]S_AXI_CDM_awprot;
  wire S_AXI_CDM_awready;
  wire S_AXI_CDM_awvalid;
  wire S_AXI_CDM_bready;
  wire [1:0]S_AXI_CDM_bresp;
  wire S_AXI_CDM_bvalid;
  wire [31:0]S_AXI_CDM_rdata;
  wire S_AXI_CDM_rready;
  wire [1:0]S_AXI_CDM_rresp;
  wire S_AXI_CDM_rvalid;
  wire [31:0]S_AXI_CDM_wdata;
  wire S_AXI_CDM_wready;
  wire [3:0]S_AXI_CDM_wstrb;
  wire S_AXI_CDM_wvalid;
  wire clk_in;
  wire rst_n;

  cdm_usr_ram cdm_usr_ram_i
       (.MSGLD_CMD_RAM_addrb(MSGLD_CMD_RAM_addrb),
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
        .M_CDM_ADAPT_CTRL_REGS_arprot(M_CDM_ADAPT_CTRL_REGS_arprot),
        .M_CDM_ADAPT_CTRL_REGS_arready(M_CDM_ADAPT_CTRL_REGS_arready),
        .M_CDM_ADAPT_CTRL_REGS_arvalid(M_CDM_ADAPT_CTRL_REGS_arvalid),
        .M_CDM_ADAPT_CTRL_REGS_awaddr(M_CDM_ADAPT_CTRL_REGS_awaddr),
        .M_CDM_ADAPT_CTRL_REGS_awprot(M_CDM_ADAPT_CTRL_REGS_awprot),
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
        .clk_in(clk_in),
        .rst_n(rst_n));
endmodule
