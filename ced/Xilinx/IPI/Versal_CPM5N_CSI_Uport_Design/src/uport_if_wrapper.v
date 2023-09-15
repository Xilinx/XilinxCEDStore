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

module uport_if_wrapper
   (ACLK_UPORT,
    ARESETN_UPORT,
    M_AXI_CSI_UPORT_axil_araddr,
    M_AXI_CSI_UPORT_axil_arprot,
    M_AXI_CSI_UPORT_axil_arready,
    M_AXI_CSI_UPORT_axil_arvalid,
    M_AXI_CSI_UPORT_axil_awaddr,
    M_AXI_CSI_UPORT_axil_awprot,
    M_AXI_CSI_UPORT_axil_awready,
    M_AXI_CSI_UPORT_axil_awvalid,
    M_AXI_CSI_UPORT_axil_bready,
    M_AXI_CSI_UPORT_axil_bresp,
    M_AXI_CSI_UPORT_axil_bvalid,
    M_AXI_CSI_UPORT_axil_rdata,
    M_AXI_CSI_UPORT_axil_rready,
    M_AXI_CSI_UPORT_axil_rresp,
    M_AXI_CSI_UPORT_axil_rvalid,
    M_AXI_CSI_UPORT_axil_wdata,
    M_AXI_CSI_UPORT_axil_wready,
    M_AXI_CSI_UPORT_axil_wstrb,
    M_AXI_CSI_UPORT_axil_wvalid,
    S_AXI_UPORT_araddr,
    S_AXI_UPORT_arprot,
    S_AXI_UPORT_arready,
    S_AXI_UPORT_arvalid,
    S_AXI_UPORT_awaddr,
    S_AXI_UPORT_awprot,
    S_AXI_UPORT_awready,
    S_AXI_UPORT_awvalid,
    S_AXI_UPORT_bready,
    S_AXI_UPORT_bresp,
    S_AXI_UPORT_bvalid,
    S_AXI_UPORT_rdata,
    S_AXI_UPORT_rready,
    S_AXI_UPORT_rresp,
    S_AXI_UPORT_rvalid,
    S_AXI_UPORT_wdata,
    S_AXI_UPORT_wready,
    S_AXI_UPORT_wstrb,
    S_AXI_UPORT_wvalid,
    addra_cmpl_cmd,
    addrb_cmpl_check_seed,
    addrb_cmpl_cmd,
    addrb_cmpl_data,
    addrb_npr_cmd,
    addrb_npr_data,
    addrb_pr_check_seed,
    addrb_pr_cmd,
    addrb_pr_data,
    dina_cmpl_cmd,
    dinb_cmpl_check_seed,
    dinb_cmpl_data,
    dinb_npr_cmd,
    dinb_npr_data,
    dinb_pr_check_seed,
    dinb_pr_cmd,
    dinb_pr_data,
    doutb_cmpl_check_seed,
    doutb_cmpl_cmd,
    doutb_cmpl_data,
    doutb_npr_cmd,
    doutb_npr_data,
    doutb_pr_check_seed,
    doutb_pr_cmd,
    doutb_pr_data,
    ena_cmpl_cmd,
    enb_cmpl_check_seed,
    enb_cmpl_cmd,
    enb_cmpl_data,
    enb_npr_cmd,
    enb_npr_data,
    enb_pr_check_seed,
    enb_pr_cmd,
    enb_pr_data,
    rsta_cmpl_cmd,
    rstb_cmpl_check_seed,
    rstb_cmpl_cmd,
    rstb_cmpl_data,
    rstb_npr_cmd,
    rstb_npr_data,
    rstb_pr_check_seed,
    rstb_pr_cmd,
    rstb_pr_data,
    wea_cmpl_cmd,
    web_cmpl_check_seed,
    web_cmpl_data,
    web_npr_cmd,
    web_npr_data,
    web_pr_check_seed,
    web_pr_cmd,
    web_pr_data);
  input ACLK_UPORT;
  input ARESETN_UPORT;
  output [31:0]M_AXI_CSI_UPORT_axil_araddr;
  output [2:0]M_AXI_CSI_UPORT_axil_arprot;
  input M_AXI_CSI_UPORT_axil_arready;
  output M_AXI_CSI_UPORT_axil_arvalid;
  output [31:0]M_AXI_CSI_UPORT_axil_awaddr;
  output [2:0]M_AXI_CSI_UPORT_axil_awprot;
  input M_AXI_CSI_UPORT_axil_awready;
  output M_AXI_CSI_UPORT_axil_awvalid;
  output M_AXI_CSI_UPORT_axil_bready;
  input [1:0]M_AXI_CSI_UPORT_axil_bresp;
  input M_AXI_CSI_UPORT_axil_bvalid;
  input [31:0]M_AXI_CSI_UPORT_axil_rdata;
  output M_AXI_CSI_UPORT_axil_rready;
  input [1:0]M_AXI_CSI_UPORT_axil_rresp;
  input M_AXI_CSI_UPORT_axil_rvalid;
  output [31:0]M_AXI_CSI_UPORT_axil_wdata;
  input M_AXI_CSI_UPORT_axil_wready;
  output [3:0]M_AXI_CSI_UPORT_axil_wstrb;
  output M_AXI_CSI_UPORT_axil_wvalid;
  input [31:0]S_AXI_UPORT_araddr;
  input [2:0]S_AXI_UPORT_arprot;
  output S_AXI_UPORT_arready;
  input S_AXI_UPORT_arvalid;
  input [31:0]S_AXI_UPORT_awaddr;
  input [2:0]S_AXI_UPORT_awprot;
  output S_AXI_UPORT_awready;
  input S_AXI_UPORT_awvalid;
  input S_AXI_UPORT_bready;
  output [1:0]S_AXI_UPORT_bresp;
  output S_AXI_UPORT_bvalid;
  output [31:0]S_AXI_UPORT_rdata;
  input S_AXI_UPORT_rready;
  output [1:0]S_AXI_UPORT_rresp;
  output S_AXI_UPORT_rvalid;
  input [31:0]S_AXI_UPORT_wdata;
  output S_AXI_UPORT_wready;
  input [3:0]S_AXI_UPORT_wstrb;
  input S_AXI_UPORT_wvalid;
  input [8:0]addra_cmpl_cmd;
  input [12:0]addrb_cmpl_check_seed;
  input [8:0]addrb_cmpl_cmd;
  input [31:0]addrb_cmpl_data;
  input [31:0]addrb_npr_cmd;
  input [31:0]addrb_npr_data;
  input [12:0]addrb_pr_check_seed;
  input [31:0]addrb_pr_cmd;
  input [31:0]addrb_pr_data;
  input [255:0]dina_cmpl_cmd;
  input [63:0]dinb_cmpl_check_seed;
  input [31:0]dinb_cmpl_data;
  input [127:0]dinb_npr_cmd;
  input [127:0]dinb_npr_data;
  input [63:0]dinb_pr_check_seed;
  input [127:0]dinb_pr_cmd;
  input [127:0]dinb_pr_data;
  output [63:0]doutb_cmpl_check_seed;
  output [255:0]doutb_cmpl_cmd;
  output [31:0]doutb_cmpl_data;
  output [127:0]doutb_npr_cmd;
  output [127:0]doutb_npr_data;
  output [63:0]doutb_pr_check_seed;
  output [127:0]doutb_pr_cmd;
  output [127:0]doutb_pr_data;
  input ena_cmpl_cmd;
  input enb_cmpl_check_seed;
  input enb_cmpl_cmd;
  input enb_cmpl_data;
  input enb_npr_cmd;
  input enb_npr_data;
  input enb_pr_check_seed;
  input enb_pr_cmd;
  input enb_pr_data;
  input rsta_cmpl_cmd;
  input rstb_cmpl_check_seed;
  input rstb_cmpl_cmd;
  input rstb_cmpl_data;
  input rstb_npr_cmd;
  input rstb_npr_data;
  input rstb_pr_check_seed;
  input rstb_pr_cmd;
  input rstb_pr_data;
  input [0:0]wea_cmpl_cmd;
  input [7:0]web_cmpl_check_seed;
  input [3:0]web_cmpl_data;
  input [15:0]web_npr_cmd;
  input [15:0]web_npr_data;
  input [7:0]web_pr_check_seed;
  input [15:0]web_pr_cmd;
  input [15:0]web_pr_data;

  wire ACLK_UPORT;
  wire ARESETN_UPORT;
  wire [31:0]M_AXI_CSI_UPORT_axil_araddr;
  wire [2:0]M_AXI_CSI_UPORT_axil_arprot;
  wire M_AXI_CSI_UPORT_axil_arready;
  wire M_AXI_CSI_UPORT_axil_arvalid;
  wire [31:0]M_AXI_CSI_UPORT_axil_awaddr;
  wire [2:0]M_AXI_CSI_UPORT_axil_awprot;
  wire M_AXI_CSI_UPORT_axil_awready;
  wire M_AXI_CSI_UPORT_axil_awvalid;
  wire M_AXI_CSI_UPORT_axil_bready;
  wire [1:0]M_AXI_CSI_UPORT_axil_bresp;
  wire M_AXI_CSI_UPORT_axil_bvalid;
  wire [31:0]M_AXI_CSI_UPORT_axil_rdata;
  wire M_AXI_CSI_UPORT_axil_rready;
  wire [1:0]M_AXI_CSI_UPORT_axil_rresp;
  wire M_AXI_CSI_UPORT_axil_rvalid;
  wire [31:0]M_AXI_CSI_UPORT_axil_wdata;
  wire M_AXI_CSI_UPORT_axil_wready;
  wire [3:0]M_AXI_CSI_UPORT_axil_wstrb;
  wire M_AXI_CSI_UPORT_axil_wvalid;
  wire [31:0]S_AXI_UPORT_araddr;
  wire [2:0]S_AXI_UPORT_arprot;
  wire S_AXI_UPORT_arready;
  wire S_AXI_UPORT_arvalid;
  wire [31:0]S_AXI_UPORT_awaddr;
  wire [2:0]S_AXI_UPORT_awprot;
  wire S_AXI_UPORT_awready;
  wire S_AXI_UPORT_awvalid;
  wire S_AXI_UPORT_bready;
  wire [1:0]S_AXI_UPORT_bresp;
  wire S_AXI_UPORT_bvalid;
  wire [31:0]S_AXI_UPORT_rdata;
  wire S_AXI_UPORT_rready;
  wire [1:0]S_AXI_UPORT_rresp;
  wire S_AXI_UPORT_rvalid;
  wire [31:0]S_AXI_UPORT_wdata;
  wire S_AXI_UPORT_wready;
  wire [3:0]S_AXI_UPORT_wstrb;
  wire S_AXI_UPORT_wvalid;
  wire [8:0]addra_cmpl_cmd;
  wire [12:0]addrb_cmpl_check_seed;
  wire [8:0]addrb_cmpl_cmd;
  wire [31:0]addrb_cmpl_data;
  wire [31:0]addrb_npr_cmd;
  wire [31:0]addrb_npr_data;
  wire [12:0]addrb_pr_check_seed;
  wire [31:0]addrb_pr_cmd;
  wire [31:0]addrb_pr_data;
  wire [255:0]dina_cmpl_cmd;
  wire [63:0]dinb_cmpl_check_seed;
  wire [31:0]dinb_cmpl_data;
  wire [127:0]dinb_npr_cmd;
  wire [127:0]dinb_npr_data;
  wire [63:0]dinb_pr_check_seed;
  wire [127:0]dinb_pr_cmd;
  wire [127:0]dinb_pr_data;
  wire [63:0]doutb_cmpl_check_seed;
  wire [255:0]doutb_cmpl_cmd;
  wire [31:0]doutb_cmpl_data;
  wire [127:0]doutb_npr_cmd;
  wire [127:0]doutb_npr_data;
  wire [63:0]doutb_pr_check_seed;
  wire [127:0]doutb_pr_cmd;
  wire [127:0]doutb_pr_data;
  wire ena_cmpl_cmd;
  wire enb_cmpl_check_seed;
  wire enb_cmpl_cmd;
  wire enb_cmpl_data;
  wire enb_npr_cmd;
  wire enb_npr_data;
  wire enb_pr_check_seed;
  wire enb_pr_cmd;
  wire enb_pr_data;
  wire rsta_cmpl_cmd;
  wire rstb_cmpl_check_seed;
  wire rstb_cmpl_cmd;
  wire rstb_cmpl_data;
  wire rstb_npr_cmd;
  wire rstb_npr_data;
  wire rstb_pr_check_seed;
  wire rstb_pr_cmd;
  wire rstb_pr_data;
  wire [0:0]wea_cmpl_cmd;
  wire [7:0]web_cmpl_check_seed;
  wire [3:0]web_cmpl_data;
  wire [15:0]web_npr_cmd;
  wire [15:0]web_npr_data;
  wire [7:0]web_pr_check_seed;
  wire [15:0]web_pr_cmd;
  wire [15:0]web_pr_data;

  uport_if uport_if_i
       (.ACLK_UPORT(ACLK_UPORT),
        .ARESETN_UPORT(ARESETN_UPORT),
        .M_AXI_CSI_UPORT_axil_araddr(M_AXI_CSI_UPORT_axil_araddr),
        .M_AXI_CSI_UPORT_axil_arprot(M_AXI_CSI_UPORT_axil_arprot),
        .M_AXI_CSI_UPORT_axil_arready(M_AXI_CSI_UPORT_axil_arready),
        .M_AXI_CSI_UPORT_axil_arvalid(M_AXI_CSI_UPORT_axil_arvalid),
        .M_AXI_CSI_UPORT_axil_awaddr(M_AXI_CSI_UPORT_axil_awaddr),
        .M_AXI_CSI_UPORT_axil_awprot(M_AXI_CSI_UPORT_axil_awprot),
        .M_AXI_CSI_UPORT_axil_awready(M_AXI_CSI_UPORT_axil_awready),
        .M_AXI_CSI_UPORT_axil_awvalid(M_AXI_CSI_UPORT_axil_awvalid),
        .M_AXI_CSI_UPORT_axil_bready(M_AXI_CSI_UPORT_axil_bready),
        .M_AXI_CSI_UPORT_axil_bresp(M_AXI_CSI_UPORT_axil_bresp),
        .M_AXI_CSI_UPORT_axil_bvalid(M_AXI_CSI_UPORT_axil_bvalid),
        .M_AXI_CSI_UPORT_axil_rdata(M_AXI_CSI_UPORT_axil_rdata),
        .M_AXI_CSI_UPORT_axil_rready(M_AXI_CSI_UPORT_axil_rready),
        .M_AXI_CSI_UPORT_axil_rresp(M_AXI_CSI_UPORT_axil_rresp),
        .M_AXI_CSI_UPORT_axil_rvalid(M_AXI_CSI_UPORT_axil_rvalid),
        .M_AXI_CSI_UPORT_axil_wdata(M_AXI_CSI_UPORT_axil_wdata),
        .M_AXI_CSI_UPORT_axil_wready(M_AXI_CSI_UPORT_axil_wready),
        .M_AXI_CSI_UPORT_axil_wstrb(M_AXI_CSI_UPORT_axil_wstrb),
        .M_AXI_CSI_UPORT_axil_wvalid(M_AXI_CSI_UPORT_axil_wvalid),
        .S_AXI_UPORT_araddr(S_AXI_UPORT_araddr),
        .S_AXI_UPORT_arprot(S_AXI_UPORT_arprot),
        .S_AXI_UPORT_arready(S_AXI_UPORT_arready),
        .S_AXI_UPORT_arvalid(S_AXI_UPORT_arvalid),
        .S_AXI_UPORT_awaddr(S_AXI_UPORT_awaddr),
        .S_AXI_UPORT_awprot(S_AXI_UPORT_awprot),
        .S_AXI_UPORT_awready(S_AXI_UPORT_awready),
        .S_AXI_UPORT_awvalid(S_AXI_UPORT_awvalid),
        .S_AXI_UPORT_bready(S_AXI_UPORT_bready),
        .S_AXI_UPORT_bresp(S_AXI_UPORT_bresp),
        .S_AXI_UPORT_bvalid(S_AXI_UPORT_bvalid),
        .S_AXI_UPORT_rdata(S_AXI_UPORT_rdata),
        .S_AXI_UPORT_rready(S_AXI_UPORT_rready),
        .S_AXI_UPORT_rresp(S_AXI_UPORT_rresp),
        .S_AXI_UPORT_rvalid(S_AXI_UPORT_rvalid),
        .S_AXI_UPORT_wdata(S_AXI_UPORT_wdata),
        .S_AXI_UPORT_wready(S_AXI_UPORT_wready),
        .S_AXI_UPORT_wstrb(S_AXI_UPORT_wstrb),
        .S_AXI_UPORT_wvalid(S_AXI_UPORT_wvalid),
        .addra_cmpl_cmd(addra_cmpl_cmd),
        .addrb_cmpl_check_seed(addrb_cmpl_check_seed),
        .addrb_cmpl_cmd(addrb_cmpl_cmd),
        .addrb_cmpl_data(addrb_cmpl_data),
        .addrb_npr_cmd(addrb_npr_cmd),
        .addrb_npr_data(addrb_npr_data),
        .addrb_pr_check_seed(addrb_pr_check_seed),
        .addrb_pr_cmd(addrb_pr_cmd),
        .addrb_pr_data(addrb_pr_data),
        .dina_cmpl_cmd(dina_cmpl_cmd),
        .dinb_cmpl_check_seed(dinb_cmpl_check_seed),
        .dinb_cmpl_data(dinb_cmpl_data),
        .dinb_npr_cmd(dinb_npr_cmd),
        .dinb_npr_data(dinb_npr_data),
        .dinb_pr_check_seed(dinb_pr_check_seed),
        .dinb_pr_cmd(dinb_pr_cmd),
        .dinb_pr_data(dinb_pr_data),
        .doutb_cmpl_check_seed(doutb_cmpl_check_seed),
        .doutb_cmpl_cmd(doutb_cmpl_cmd),
        .doutb_cmpl_data(doutb_cmpl_data),
        .doutb_npr_cmd(doutb_npr_cmd),
        .doutb_npr_data(doutb_npr_data),
        .doutb_pr_check_seed(doutb_pr_check_seed),
        .doutb_pr_cmd(doutb_pr_cmd),
        .doutb_pr_data(doutb_pr_data),
        .ena_cmpl_cmd(ena_cmpl_cmd),
        .enb_cmpl_check_seed(enb_cmpl_check_seed),
        .enb_cmpl_cmd(enb_cmpl_cmd),
        .enb_cmpl_data(enb_cmpl_data),
        .enb_npr_cmd(enb_npr_cmd),
        .enb_npr_data(enb_npr_data),
        .enb_pr_check_seed(enb_pr_check_seed),
        .enb_pr_cmd(enb_pr_cmd),
        .enb_pr_data(enb_pr_data),
        .rsta_cmpl_cmd(rsta_cmpl_cmd),
        .rstb_cmpl_check_seed(rstb_cmpl_check_seed),
        .rstb_cmpl_cmd(rstb_cmpl_cmd),
        .rstb_cmpl_data(rstb_cmpl_data),
        .rstb_npr_cmd(rstb_npr_cmd),
        .rstb_npr_data(rstb_npr_data),
        .rstb_pr_check_seed(rstb_pr_check_seed),
        .rstb_pr_cmd(rstb_pr_cmd),
        .rstb_pr_data(rstb_pr_data),
        .wea_cmpl_cmd(wea_cmpl_cmd),
        .web_cmpl_check_seed(web_cmpl_check_seed),
        .web_cmpl_data(web_cmpl_data),
        .web_npr_cmd(web_npr_cmd),
        .web_npr_data(web_npr_data),
        .web_pr_check_seed(web_pr_check_seed),
        .web_pr_cmd(web_pr_cmd),
        .web_pr_data(web_pr_data));
endmodule
