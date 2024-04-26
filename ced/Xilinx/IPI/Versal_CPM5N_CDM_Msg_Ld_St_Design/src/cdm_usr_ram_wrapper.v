//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1.0 (lin64) Build 3765534 Thu Feb  2 19:12:49 MST 2023
//Date        : Fri Feb  3 18:39:02 2023
//Host        : xsjrdevl157 running 64-bit CentOS Linux release 7.4.1708 (Core)
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
    S_AXIL_CDMRAM_araddr,
    S_AXIL_CDMRAM_arprot,
    S_AXIL_CDMRAM_arready,
    S_AXIL_CDMRAM_arvalid,
    S_AXIL_CDMRAM_awaddr,
    S_AXIL_CDMRAM_awprot,
    S_AXIL_CDMRAM_awready,
    S_AXIL_CDMRAM_awvalid,
    S_AXIL_CDMRAM_bready,
    S_AXIL_CDMRAM_bresp,
    S_AXIL_CDMRAM_bvalid,
    S_AXIL_CDMRAM_rdata,
    S_AXIL_CDMRAM_rready,
    S_AXIL_CDMRAM_rresp,
    S_AXIL_CDMRAM_rvalid,
    S_AXIL_CDMRAM_wdata,
    S_AXIL_CDMRAM_wready,
    S_AXIL_CDMRAM_wstrb,
    S_AXIL_CDMRAM_wvalid,
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
    msgstld_perf_reg_araddr,
    msgstld_perf_reg_arprot,
    msgstld_perf_reg_arready,
    msgstld_perf_reg_arvalid,
    msgstld_perf_reg_awaddr,
    msgstld_perf_reg_awprot,
    msgstld_perf_reg_awready,
    msgstld_perf_reg_awvalid,
    msgstld_perf_reg_bready,
    msgstld_perf_reg_bresp,
    msgstld_perf_reg_bvalid,
    msgstld_perf_reg_rdata,
    msgstld_perf_reg_rready,
    msgstld_perf_reg_rresp,
    msgstld_perf_reg_rvalid,
    msgstld_perf_reg_wdata,
    msgstld_perf_reg_wready,
    msgstld_perf_reg_wstrb,
    msgstld_perf_reg_wvalid,
    rst_n);
  input [12:0]MSGLD_CMD_RAM_addrb;
  output [31:0]MSGLD_CMD_RAM_doutb;
  input MSGLD_CMD_RAM_enb;
  input [12:0]MSGLD_Payload_RAM_addrb;
  input [255:0]MSGLD_Payload_RAM_dinb;
  input [31:0]MSGLD_Payload_RAM_web;
  input [12:0]MSGST_CMD_RAM_addrb;
  output [31:0]MSGST_CMD_RAM_doutb;
  input MSGST_CMD_RAM_enb;
  input [12:0]MSGST_Payload_RAM_addrb;
  input [255:0]MSGST_Payload_RAM_dinb;
  input [31:0]MSGST_Payload_RAM_web;
  input [12:0]MSG_Response_RAM_addrb;
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
  input [31:0]S_AXIL_CDMRAM_araddr;
  input [2:0]S_AXIL_CDMRAM_arprot;
  output S_AXIL_CDMRAM_arready;
  input S_AXIL_CDMRAM_arvalid;
  input [31:0]S_AXIL_CDMRAM_awaddr;
  input [2:0]S_AXIL_CDMRAM_awprot;
  output S_AXIL_CDMRAM_awready;
  input S_AXIL_CDMRAM_awvalid;
  input S_AXIL_CDMRAM_bready;
  output [1:0]S_AXIL_CDMRAM_bresp;
  output S_AXIL_CDMRAM_bvalid;
  output [31:0]S_AXIL_CDMRAM_rdata;
  input S_AXIL_CDMRAM_rready;
  output [1:0]S_AXIL_CDMRAM_rresp;
  output S_AXIL_CDMRAM_rvalid;
  input [31:0]S_AXIL_CDMRAM_wdata;
  output S_AXIL_CDMRAM_wready;
  input [3:0]S_AXIL_CDMRAM_wstrb;
  input S_AXIL_CDMRAM_wvalid;
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
  output [31:0]msgstld_perf_reg_araddr;
  output [2:0]msgstld_perf_reg_arprot;
  input msgstld_perf_reg_arready;
  output msgstld_perf_reg_arvalid;
  output [31:0]msgstld_perf_reg_awaddr;
  output [2:0]msgstld_perf_reg_awprot;
  input msgstld_perf_reg_awready;
  output msgstld_perf_reg_awvalid;
  output msgstld_perf_reg_bready;
  input [1:0]msgstld_perf_reg_bresp;
  input msgstld_perf_reg_bvalid;
  input [31:0]msgstld_perf_reg_rdata;
  output msgstld_perf_reg_rready;
  input [1:0]msgstld_perf_reg_rresp;
  input msgstld_perf_reg_rvalid;
  output [31:0]msgstld_perf_reg_wdata;
  input msgstld_perf_reg_wready;
  output [3:0]msgstld_perf_reg_wstrb;
  output msgstld_perf_reg_wvalid;
  input rst_n;

  wire [12:0]MSGLD_CMD_RAM_addrb;
  wire [31:0]MSGLD_CMD_RAM_doutb;
  wire MSGLD_CMD_RAM_enb;
  wire [12:0]MSGLD_Payload_RAM_addrb;
  wire [255:0]MSGLD_Payload_RAM_dinb;
  wire [31:0]MSGLD_Payload_RAM_web;
  wire [12:0]MSGST_CMD_RAM_addrb;
  wire [31:0]MSGST_CMD_RAM_doutb;
  wire MSGST_CMD_RAM_enb;
  wire [12:0]MSGST_Payload_RAM_addrb;
  wire [255:0]MSGST_Payload_RAM_dinb;
  wire [31:0]MSGST_Payload_RAM_web;
  wire [12:0]MSG_Response_RAM_addrb;
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
  wire [31:0]S_AXIL_CDMRAM_araddr;
  wire [2:0]S_AXIL_CDMRAM_arprot;
  wire S_AXIL_CDMRAM_arready;
  wire S_AXIL_CDMRAM_arvalid;
  wire [31:0]S_AXIL_CDMRAM_awaddr;
  wire [2:0]S_AXIL_CDMRAM_awprot;
  wire S_AXIL_CDMRAM_awready;
  wire S_AXIL_CDMRAM_awvalid;
  wire S_AXIL_CDMRAM_bready;
  wire [1:0]S_AXIL_CDMRAM_bresp;
  wire S_AXIL_CDMRAM_bvalid;
  wire [31:0]S_AXIL_CDMRAM_rdata;
  wire S_AXIL_CDMRAM_rready;
  wire [1:0]S_AXIL_CDMRAM_rresp;
  wire S_AXIL_CDMRAM_rvalid;
  wire [31:0]S_AXIL_CDMRAM_wdata;
  wire S_AXIL_CDMRAM_wready;
  wire [3:0]S_AXIL_CDMRAM_wstrb;
  wire S_AXIL_CDMRAM_wvalid;
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
  wire [31:0]msgstld_perf_reg_araddr;
  wire [2:0]msgstld_perf_reg_arprot;
  wire msgstld_perf_reg_arready;
  wire msgstld_perf_reg_arvalid;
  wire [31:0]msgstld_perf_reg_awaddr;
  wire [2:0]msgstld_perf_reg_awprot;
  wire msgstld_perf_reg_awready;
  wire msgstld_perf_reg_awvalid;
  wire msgstld_perf_reg_bready;
  wire [1:0]msgstld_perf_reg_bresp;
  wire msgstld_perf_reg_bvalid;
  wire [31:0]msgstld_perf_reg_rdata;
  wire msgstld_perf_reg_rready;
  wire [1:0]msgstld_perf_reg_rresp;
  wire msgstld_perf_reg_rvalid;
  wire [31:0]msgstld_perf_reg_wdata;
  wire msgstld_perf_reg_wready;
  wire [3:0]msgstld_perf_reg_wstrb;
  wire msgstld_perf_reg_wvalid;
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
        .S_AXIL_CDMRAM_araddr(S_AXIL_CDMRAM_araddr),
        .S_AXIL_CDMRAM_arprot(S_AXIL_CDMRAM_arprot),
        .S_AXIL_CDMRAM_arready(S_AXIL_CDMRAM_arready),
        .S_AXIL_CDMRAM_arvalid(S_AXIL_CDMRAM_arvalid),
        .S_AXIL_CDMRAM_awaddr(S_AXIL_CDMRAM_awaddr),
        .S_AXIL_CDMRAM_awprot(S_AXIL_CDMRAM_awprot),
        .S_AXIL_CDMRAM_awready(S_AXIL_CDMRAM_awready),
        .S_AXIL_CDMRAM_awvalid(S_AXIL_CDMRAM_awvalid),
        .S_AXIL_CDMRAM_bready(S_AXIL_CDMRAM_bready),
        .S_AXIL_CDMRAM_bresp(S_AXIL_CDMRAM_bresp),
        .S_AXIL_CDMRAM_bvalid(S_AXIL_CDMRAM_bvalid),
        .S_AXIL_CDMRAM_rdata(S_AXIL_CDMRAM_rdata),
        .S_AXIL_CDMRAM_rready(S_AXIL_CDMRAM_rready),
        .S_AXIL_CDMRAM_rresp(S_AXIL_CDMRAM_rresp),
        .S_AXIL_CDMRAM_rvalid(S_AXIL_CDMRAM_rvalid),
        .S_AXIL_CDMRAM_wdata(S_AXIL_CDMRAM_wdata),
        .S_AXIL_CDMRAM_wready(S_AXIL_CDMRAM_wready),
        .S_AXIL_CDMRAM_wstrb(S_AXIL_CDMRAM_wstrb),
        .S_AXIL_CDMRAM_wvalid(S_AXIL_CDMRAM_wvalid),
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
        .msgstld_perf_reg_araddr(msgstld_perf_reg_araddr),
        .msgstld_perf_reg_arprot(msgstld_perf_reg_arprot),
        .msgstld_perf_reg_arready(msgstld_perf_reg_arready),
        .msgstld_perf_reg_arvalid(msgstld_perf_reg_arvalid),
        .msgstld_perf_reg_awaddr(msgstld_perf_reg_awaddr),
        .msgstld_perf_reg_awprot(msgstld_perf_reg_awprot),
        .msgstld_perf_reg_awready(msgstld_perf_reg_awready),
        .msgstld_perf_reg_awvalid(msgstld_perf_reg_awvalid),
        .msgstld_perf_reg_bready(msgstld_perf_reg_bready),
        .msgstld_perf_reg_bresp(msgstld_perf_reg_bresp),
        .msgstld_perf_reg_bvalid(msgstld_perf_reg_bvalid),
        .msgstld_perf_reg_rdata(msgstld_perf_reg_rdata),
        .msgstld_perf_reg_rready(msgstld_perf_reg_rready),
        .msgstld_perf_reg_rresp(msgstld_perf_reg_rresp),
        .msgstld_perf_reg_rvalid(msgstld_perf_reg_rvalid),
        .msgstld_perf_reg_wdata(msgstld_perf_reg_wdata),
        .msgstld_perf_reg_wready(msgstld_perf_reg_wready),
        .msgstld_perf_reg_wstrb(msgstld_perf_reg_wstrb),
        .msgstld_perf_reg_wvalid(msgstld_perf_reg_wvalid),
        .rst_n(rst_n));
endmodule
