//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2026.1.0 (lin64) Build 6393872 Wed Mar 11 01:04:36 MDT 2026
//Date        : Wed Mar 18 22:25:51 2026
//Host        : xsjlc220532 running 64-bit Red Hat Enterprise Linux release 8.10 (Ootpa)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

import axil_slave_pkg::*;

module dma_ddr_top
import dma_link_pkg::*;
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
    CTRL0_GT_0_grx_n,
    CTRL0_GT_0_grx_p,
    CTRL0_GT_0_gtx_n,
    CTRL0_GT_0_gtx_p,
    ctrl0_gt_refclk_0_clk_n,
    ctrl0_gt_refclk_0_clk_p,
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
  input [LINK_WIDTH-1:0]CTRL0_GT_0_grx_n;
  input [LINK_WIDTH-1:0]CTRL0_GT_0_grx_p;
  output [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_n;
  output [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_p;
  input ctrl0_gt_refclk_0_clk_n;
  input ctrl0_gt_refclk_0_clk_p;
  input [0:0]sys_clk0_0_clk_n;
  input [0:0]sys_clk0_0_clk_p;

  wire [6:0]CH0_LPDDR5_0_ca;
  wire [0:0]CH0_LPDDR5_0_ck_c;
  wire [0:0]CH0_LPDDR5_0_ck_t;
  wire [1:0]CH0_LPDDR5_0_cs;
  wire [3:0]CH0_LPDDR5_0_dmi;
  wire [31:0]CH0_LPDDR5_0_dq;
  wire [3:0]CH0_LPDDR5_0_rdqs_c;
  wire [3:0]CH0_LPDDR5_0_rdqs_t;
  wire CH0_LPDDR5_0_reset_n;
  wire [3:0]CH0_LPDDR5_0_wck_c;
  wire [3:0]CH0_LPDDR5_0_wck_t;
  wire [LINK_WIDTH-1:0]CTRL0_GT_0_grx_n;
  wire [LINK_WIDTH-1:0]CTRL0_GT_0_grx_p;
  wire [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_n;
  wire [LINK_WIDTH-1:0]CTRL0_GT_0_gtx_p;
  wire [0:0]sys_clk0_0_clk_n;
  wire [0:0]sys_clk0_0_clk_p;
   
  wire aclk;
  wire ctrl0_gt_refclk_0_clk_n;
  wire ctrl0_gt_refclk_0_clk_p;
  wire dbi0_rstn_0;
  wire [127:0]dma0_irq_0;
  wire pcie0_msix_0_error;
  wire [2:0]pcie0_msix_0_func_num;
  wire pcie0_msix_0_grant;
  wire [1:0]pcie0_msix_0_operation;
  wire pcie0_msix_0_req;
  wire [10:0]pcie0_msix_0_vector_num;
  wire pcie0_msix_0_vfunc_active;
  wire [7:0]pcie0_msix_0_vfunc_num;
  wire pcie0_rstn_0;
  wire [31:0]pl_axil_dbi0_0_araddr;
  wire [2:0]pl_axil_dbi0_0_arprot;
  wire pl_axil_dbi0_0_arready;
  wire [15:0]pl_axil_dbi0_0_aruser;
  wire pl_axil_dbi0_0_arvalid;
  wire [31:0]pl_axil_dbi0_0_awaddr;
  wire [2:0]pl_axil_dbi0_0_awprot;
  wire pl_axil_dbi0_0_awready;
  wire [15:0]pl_axil_dbi0_0_awuser;
  wire pl_axil_dbi0_0_awvalid;
  wire pl_axil_dbi0_0_bready;
  wire [1:0]pl_axil_dbi0_0_bresp;
  wire [5:0]pl_axil_dbi0_0_buser;
  wire pl_axil_dbi0_0_bvalid;
  wire [31:0]pl_axil_dbi0_0_rdata;
  wire pl_axil_dbi0_0_rready;
  wire [1:0]pl_axil_dbi0_0_rresp;
  wire [3:0]pl_axil_dbi0_0_ruser;
  wire pl_axil_dbi0_0_rvalid;
  wire [31:0]pl_axil_dbi0_0_wdata;
  wire pl_axil_dbi0_0_wready;
  wire [3:0]pl_axil_dbi0_0_wstrb;
  wire [3:0]pl_axil_dbi0_0_wuser;
  wire pl_axil_dbi0_0_wvalid;

  wire [63:0]M00_AXI_0_araddr;
  wire [2:0]M00_AXI_0_arprot;
  wire M00_AXI_0_arready;
  wire M00_AXI_0_arvalid;
  wire [63:0]M00_AXI_0_awaddr;
  wire [2:0]M00_AXI_0_awprot;
  wire M00_AXI_0_awready;
  wire M00_AXI_0_awvalid;
  wire M00_AXI_0_bready;
  wire [1:0]M00_AXI_0_bresp;
  wire M00_AXI_0_bvalid;
  wire [31:0]M00_AXI_0_rdata;
  wire M00_AXI_0_rready;
  wire [1:0]M00_AXI_0_rresp;
  wire M00_AXI_0_rvalid;
  wire [31:0]M00_AXI_0_wdata;
  wire M00_AXI_0_wready;
  wire [3:0]M00_AXI_0_wstrb;
  wire M00_AXI_0_wvalid;

  wire [50:0]S00_AXI_0_araddr;
  wire [1:0]S00_AXI_0_arburst;
  wire [3:0]S00_AXI_0_arcache;
  wire [9:0]S00_AXI_0_arid;
  wire [7:0]S00_AXI_0_arlen;
  wire [0:0]S00_AXI_0_arlock;
  wire [2:0]S00_AXI_0_arprot;
  wire [3:0]S00_AXI_0_arqos;
  wire S00_AXI_0_arready;
  wire [2:0]S00_AXI_0_arsize;
  wire [55:0]S00_AXI_0_aruser;
  wire S00_AXI_0_arvalid;
  wire [50:0]S00_AXI_0_awaddr;
  wire [1:0]S00_AXI_0_awburst;
  wire [3:0]S00_AXI_0_awcache;
  wire [9:0]S00_AXI_0_awid;
  wire [7:0]S00_AXI_0_awlen;
  wire [0:0]S00_AXI_0_awlock;
  wire [2:0]S00_AXI_0_awprot;
  wire [3:0]S00_AXI_0_awqos;
  wire S00_AXI_0_awready;
  wire [2:0]S00_AXI_0_awsize;
  wire [146:0]S00_AXI_0_awuser;
  wire S00_AXI_0_awvalid;
  wire [9:0]S00_AXI_0_bid;
  wire S00_AXI_0_bready;
  wire [1:0]S00_AXI_0_bresp;
  wire [2:0]S00_AXI_0_buser;
  wire S00_AXI_0_bvalid;
  wire [511:0]S00_AXI_0_rdata;
  wire [9:0]S00_AXI_0_rid;
  wire S00_AXI_0_rlast;
  wire S00_AXI_0_rready;
  wire [1:0]S00_AXI_0_rresp;
  wire [127:0]S00_AXI_0_ruser;
  wire S00_AXI_0_rvalid;
  wire [511:0]S00_AXI_0_wdata;
  wire S00_AXI_0_wlast;
  wire S00_AXI_0_wready;
  wire [63:0]S00_AXI_0_wstrb;
  wire [63:0]S00_AXI_0_wuser;
  wire S00_AXI_0_wvalid;

  wire [50:0]cpm_axi_pl0_0_araddr;
  wire [1:0]cpm_axi_pl0_0_arburst;
  wire [3:0]cpm_axi_pl0_0_arcache;
  wire [9:0]cpm_axi_pl0_0_arid;
  wire [7:0]cpm_axi_pl0_0_arlen;
  wire cpm_axi_pl0_0_arlock;
  wire [2:0]cpm_axi_pl0_0_arprot;
  wire [3:0]cpm_axi_pl0_0_arqos;
  wire cpm_axi_pl0_0_arready;
  wire [2:0]cpm_axi_pl0_0_arsize;
  wire [55:0]cpm_axi_pl0_0_aruser;
  wire cpm_axi_pl0_0_arvalid;
  wire [50:0]cpm_axi_pl0_0_awaddr;
  wire [1:0]cpm_axi_pl0_0_awburst;
  wire [3:0]cpm_axi_pl0_0_awcache;
  wire [9:0]cpm_axi_pl0_0_awid;
  wire [7:0]cpm_axi_pl0_0_awlen;
  wire cpm_axi_pl0_0_awlock;
  wire [2:0]cpm_axi_pl0_0_awprot;
  wire [3:0]cpm_axi_pl0_0_awqos;
  wire cpm_axi_pl0_0_awready;
  wire [2:0]cpm_axi_pl0_0_awsize;
  wire [146:0]cpm_axi_pl0_0_awuser;
  wire cpm_axi_pl0_0_awvalid;
  wire [9:0]cpm_axi_pl0_0_bid;
  wire cpm_axi_pl0_0_bready;
  wire [1:0]cpm_axi_pl0_0_bresp;
  wire [2:0]cpm_axi_pl0_0_buser;
  wire cpm_axi_pl0_0_bvalid;
  wire [511:0]cpm_axi_pl0_0_rdata;
  wire [9:0]cpm_axi_pl0_0_rid;
  wire cpm_axi_pl0_0_rlast;
  wire cpm_axi_pl0_0_rready;
  wire [1:0]cpm_axi_pl0_0_rresp;
  wire [127:0]cpm_axi_pl0_0_ruser;
  wire cpm_axi_pl0_0_rvalid;
  wire [511:0]cpm_axi_pl0_0_wdata;
  wire cpm_axi_pl0_0_wlast;
  wire cpm_axi_pl0_0_wready;
  wire [63:0]cpm_axi_pl0_0_wstrb;
  wire [63:0]cpm_axi_pl0_0_wuser;
  wire cpm_axi_pl0_0_wvalid;

  // ----------------------------------------------------------------
  // New LPD-to-PL AXI4 interface (PS's LPD_AXI_PL, wired directly — no interconnect IP,
  // same direct-passthrough pattern as cpm_axi_pl0_0 below), driven by the R5/RPU — for
  // FLR communication with pl_example's new flr_slave. Full AXI4. AWADDR/ARADDR and
  // AWID/ARID/BID/RID are sized to LPD_AXI_PL's real native widths (44-bit address,
  // 16-bit ID) since there's no SmartConnect here to narrow them — flr_slave decodes only
  // the low address bits and simply echoes ID back on BID/RID. ARUSER/AWUSER (also native
  // to this port, 16-bit) are left unconnected — flr_slave has nothing to disambiguate,
  // unlike cpm_axi_pl0_0's PF/VF-carrying USER bits.
  // ----------------------------------------------------------------
  wire [43:0]M_LPD_AXI_0_araddr;
  wire [15:0]M_LPD_AXI_0_arid;
  wire [1:0]M_LPD_AXI_0_arburst;
  wire [3:0]M_LPD_AXI_0_arcache;
  wire [7:0]M_LPD_AXI_0_arlen;
  wire M_LPD_AXI_0_arlock;
  wire [2:0]M_LPD_AXI_0_arprot;
  wire [3:0]M_LPD_AXI_0_arqos;
  wire M_LPD_AXI_0_arready;
  wire [2:0]M_LPD_AXI_0_arsize;
  wire M_LPD_AXI_0_arvalid;
  wire [43:0]M_LPD_AXI_0_awaddr;
  wire [15:0]M_LPD_AXI_0_awid;
  wire [1:0]M_LPD_AXI_0_awburst;
  wire [3:0]M_LPD_AXI_0_awcache;
  wire [7:0]M_LPD_AXI_0_awlen;
  wire M_LPD_AXI_0_awlock;
  wire [2:0]M_LPD_AXI_0_awprot;
  wire [3:0]M_LPD_AXI_0_awqos;
  wire M_LPD_AXI_0_awready;
  wire [2:0]M_LPD_AXI_0_awsize;
  wire M_LPD_AXI_0_awvalid;
  wire M_LPD_AXI_0_bready;
  wire [15:0]M_LPD_AXI_0_bid;
  wire [1:0]M_LPD_AXI_0_bresp;
  wire M_LPD_AXI_0_bvalid;
  wire [31:0]M_LPD_AXI_0_rdata;
  wire [15:0]M_LPD_AXI_0_rid;
  wire M_LPD_AXI_0_rlast;
  wire M_LPD_AXI_0_rready;
  wire [1:0]M_LPD_AXI_0_rresp;
  wire M_LPD_AXI_0_rvalid;
  wire [31:0]M_LPD_AXI_0_wdata;
  wire M_LPD_AXI_0_wlast;
  wire M_LPD_AXI_0_wready;
  wire [3:0]M_LPD_AXI_0_wstrb;
  wire M_LPD_AXI_0_wvalid;

  wire [11:0] cpm_m00_awuser;  // aligned AW user bits from cpm_user_aligner
  wire [11:0] cpm_m00_aruser;  // aligned AR user bits from cpm_user_aligner

  cpm_user_aligner u_cpm_user_aligner (
    .clk          (aclk),
    .reset_n      (dbi0_rstn_0),
    .cpm_awvalid  (cpm_axi_pl0_0_awvalid),
    .cpm_awready  (cpm_axi_pl0_0_awready),
    .cpm_awuser   (cpm_axi_pl0_0_awuser),
    .cpm_arvalid  (cpm_axi_pl0_0_arvalid),
    .cpm_arready  (cpm_axi_pl0_0_arready),
    .cpm_aruser   (cpm_axi_pl0_0_aruser),
    .m00_awuser   (cpm_m00_awuser),
    .m00_aruser   (cpm_m00_aruser)
  );

  // AXI loopback: connect CPM AXI master interface to S00 AXI slave interface.
  assign S00_AXI_0_araddr  = {3'b0, cpm_axi_pl0_0_araddr[47:0]};
  assign S00_AXI_0_arburst = cpm_axi_pl0_0_arburst;
  assign S00_AXI_0_arcache = cpm_axi_pl0_0_arcache;
  assign S00_AXI_0_arid    = cpm_axi_pl0_0_arid;
  assign S00_AXI_0_arlen   = cpm_axi_pl0_0_arlen;
  assign S00_AXI_0_arlock  = {cpm_axi_pl0_0_arlock};
  assign S00_AXI_0_arprot  = cpm_axi_pl0_0_arprot;
  assign S00_AXI_0_arqos   = cpm_axi_pl0_0_arqos;
  assign cpm_axi_pl0_0_arready = S00_AXI_0_arready;
  assign S00_AXI_0_arsize  = cpm_axi_pl0_0_arsize;
  assign S00_AXI_0_aruser  = cpm_axi_pl0_0_aruser;
  assign S00_AXI_0_arvalid = cpm_axi_pl0_0_arvalid;

  assign S00_AXI_0_awaddr  = {3'b0, cpm_axi_pl0_0_awaddr[47:0]};
  assign S00_AXI_0_awburst = cpm_axi_pl0_0_awburst;
  assign S00_AXI_0_awcache = cpm_axi_pl0_0_awcache;
  assign S00_AXI_0_awid    = cpm_axi_pl0_0_awid;
  assign S00_AXI_0_awlen   = cpm_axi_pl0_0_awlen;
  assign S00_AXI_0_awlock  = {cpm_axi_pl0_0_awlock};
  assign S00_AXI_0_awprot  = cpm_axi_pl0_0_awprot;
  assign S00_AXI_0_awqos   = cpm_axi_pl0_0_awqos;
  assign cpm_axi_pl0_0_awready = S00_AXI_0_awready;
  assign S00_AXI_0_awsize  = cpm_axi_pl0_0_awsize;
  assign S00_AXI_0_awuser  = cpm_axi_pl0_0_awuser;
  assign S00_AXI_0_awvalid = cpm_axi_pl0_0_awvalid;

  assign cpm_axi_pl0_0_bid    = S00_AXI_0_bid;
  assign S00_AXI_0_bready     = cpm_axi_pl0_0_bready;
  assign cpm_axi_pl0_0_bresp  = S00_AXI_0_bresp;
  assign cpm_axi_pl0_0_buser  = S00_AXI_0_buser;
  assign cpm_axi_pl0_0_bvalid = S00_AXI_0_bvalid;

  assign cpm_axi_pl0_0_rdata  = S00_AXI_0_rdata;
  assign cpm_axi_pl0_0_rid    = S00_AXI_0_rid;
  assign cpm_axi_pl0_0_rlast  = S00_AXI_0_rlast;
  assign S00_AXI_0_rready     = cpm_axi_pl0_0_rready;
  assign cpm_axi_pl0_0_rresp  = S00_AXI_0_rresp;
  assign cpm_axi_pl0_0_ruser  = S00_AXI_0_ruser;
  assign cpm_axi_pl0_0_rvalid = S00_AXI_0_rvalid;

  assign S00_AXI_0_wdata  = cpm_axi_pl0_0_wdata;
  assign S00_AXI_0_wlast  = cpm_axi_pl0_0_wlast;
  assign cpm_axi_pl0_0_wready = S00_AXI_0_wready;
  assign S00_AXI_0_wstrb  = cpm_axi_pl0_0_wstrb;
  assign S00_AXI_0_wuser  = cpm_axi_pl0_0_wuser;
  assign S00_AXI_0_wvalid = cpm_axi_pl0_0_wvalid;

/*
  Need to bring put PL-AXI-0 port out to top level and connect it to an AXI master on the host side,
  This is need because cpm6 PL-AXI0 port outputs address [50:0] which includs controler number in bit 49.
  This deisgn uses controler1 so bit [49] is set to 1. 
  But the smart conenct user that bit as part of address and give error.
  So inthe top level only 48:0 bits are connected back to S00_AXI port going to smart connect.
 
*/
  cpm6_dma design_1_i
    (.CH0_LPDDR5_0_ca(CH0_LPDDR5_0_ca),
    .CH0_LPDDR5_0_ck_c(CH0_LPDDR5_0_ck_c),
    .CH0_LPDDR5_0_ck_t(CH0_LPDDR5_0_ck_t),
    .CH0_LPDDR5_0_cs(CH0_LPDDR5_0_cs),
    .CH0_LPDDR5_0_dmi(CH0_LPDDR5_0_dmi),
    .CH0_LPDDR5_0_dq(CH0_LPDDR5_0_dq),
    .CH0_LPDDR5_0_rdqs_c(CH0_LPDDR5_0_rdqs_c),
    .CH0_LPDDR5_0_rdqs_t(CH0_LPDDR5_0_rdqs_t),
    .CH0_LPDDR5_0_reset_n(CH0_LPDDR5_0_reset_n),
    .CH0_LPDDR5_0_wck_c(CH0_LPDDR5_0_wck_c),
    .CH0_LPDDR5_0_wck_t(CH0_LPDDR5_0_wck_t),
    .CTRL0_GT_0_grx_n(CTRL0_GT_0_grx_n),
    .CTRL0_GT_0_grx_p(CTRL0_GT_0_grx_p),
    .CTRL0_GT_0_gtx_n(CTRL0_GT_0_gtx_n),
    .CTRL0_GT_0_gtx_p(CTRL0_GT_0_gtx_p),
   
    .M00_AXI_0_araddr(M00_AXI_0_araddr),
    .M00_AXI_0_arprot(M00_AXI_0_arprot),
    .M00_AXI_0_arready(M00_AXI_0_arready),
    .M00_AXI_0_arvalid(M00_AXI_0_arvalid),
    .M00_AXI_0_awaddr(M00_AXI_0_awaddr),
    .M00_AXI_0_awprot(M00_AXI_0_awprot),
    .M00_AXI_0_awready(M00_AXI_0_awready),
    .M00_AXI_0_awvalid(M00_AXI_0_awvalid),
    .M00_AXI_0_bready(M00_AXI_0_bready),
    .M00_AXI_0_bresp(M00_AXI_0_bresp),
    .M00_AXI_0_bvalid(M00_AXI_0_bvalid),
    .M00_AXI_0_rdata(M00_AXI_0_rdata),
    .M00_AXI_0_rready(M00_AXI_0_rready),
    .M00_AXI_0_rresp(M00_AXI_0_rresp),
    .M00_AXI_0_rvalid(M00_AXI_0_rvalid),
    .M00_AXI_0_wdata(M00_AXI_0_wdata),
    .M00_AXI_0_wready(M00_AXI_0_wready),
    .M00_AXI_0_wstrb(M00_AXI_0_wstrb),
    .M00_AXI_0_wvalid(M00_AXI_0_wvalid),

    .S00_AXI_0_araddr(S00_AXI_0_araddr),
    .S00_AXI_0_arburst(S00_AXI_0_arburst),
    .S00_AXI_0_arcache(S00_AXI_0_arcache),
    .S00_AXI_0_arid(S00_AXI_0_arid),
    .S00_AXI_0_arlen(S00_AXI_0_arlen),
    .S00_AXI_0_arlock(S00_AXI_0_arlock),
    .S00_AXI_0_arprot(S00_AXI_0_arprot),
    .S00_AXI_0_arqos(S00_AXI_0_arqos),
    .S00_AXI_0_arready(S00_AXI_0_arready),
    .S00_AXI_0_arsize(S00_AXI_0_arsize),
    .S00_AXI_0_aruser(S00_AXI_0_aruser),
    .S00_AXI_0_arvalid(S00_AXI_0_arvalid),
    .S00_AXI_0_awaddr(S00_AXI_0_awaddr),
    .S00_AXI_0_awburst(S00_AXI_0_awburst),
    .S00_AXI_0_awcache(S00_AXI_0_awcache),
    .S00_AXI_0_awid(S00_AXI_0_awid),
    .S00_AXI_0_awlen(S00_AXI_0_awlen),
    .S00_AXI_0_awlock(S00_AXI_0_awlock),
    .S00_AXI_0_awprot(S00_AXI_0_awprot),
    .S00_AXI_0_awqos(S00_AXI_0_awqos),
    .S00_AXI_0_awready(S00_AXI_0_awready),
    .S00_AXI_0_awsize(S00_AXI_0_awsize),
    .S00_AXI_0_awuser(S00_AXI_0_awuser),
    .S00_AXI_0_awvalid(S00_AXI_0_awvalid),
    .S00_AXI_0_bid(S00_AXI_0_bid),
    .S00_AXI_0_bready(S00_AXI_0_bready),
    .S00_AXI_0_bresp(S00_AXI_0_bresp),
    .S00_AXI_0_buser(S00_AXI_0_buser),
    .S00_AXI_0_bvalid(S00_AXI_0_bvalid),
    .S00_AXI_0_rdata(S00_AXI_0_rdata),
    .S00_AXI_0_rid(S00_AXI_0_rid),
    .S00_AXI_0_rlast(S00_AXI_0_rlast),
    .S00_AXI_0_rready(S00_AXI_0_rready),
    .S00_AXI_0_rresp(S00_AXI_0_rresp),
    .S00_AXI_0_ruser(S00_AXI_0_ruser),
    .S00_AXI_0_rvalid(S00_AXI_0_rvalid),
    .S00_AXI_0_wdata(S00_AXI_0_wdata),
    .S00_AXI_0_wlast(S00_AXI_0_wlast),
    .S00_AXI_0_wready(S00_AXI_0_wready),
    .S00_AXI_0_wstrb(S00_AXI_0_wstrb),
    .S00_AXI_0_wuser(S00_AXI_0_wuser),
    .S00_AXI_0_wvalid(S00_AXI_0_wvalid),

    .cpm_axi_pl0_0_araddr(cpm_axi_pl0_0_araddr),
    .cpm_axi_pl0_0_arburst(cpm_axi_pl0_0_arburst),
    .cpm_axi_pl0_0_arcache(cpm_axi_pl0_0_arcache),
    .cpm_axi_pl0_0_arid(cpm_axi_pl0_0_arid),
    .cpm_axi_pl0_0_arlen(cpm_axi_pl0_0_arlen),
    .cpm_axi_pl0_0_arlock(cpm_axi_pl0_0_arlock),
    .cpm_axi_pl0_0_arprot(cpm_axi_pl0_0_arprot),
    .cpm_axi_pl0_0_arqos(cpm_axi_pl0_0_arqos),
    .cpm_axi_pl0_0_arready(cpm_axi_pl0_0_arready),
    .cpm_axi_pl0_0_arsize(cpm_axi_pl0_0_arsize),
    .cpm_axi_pl0_0_aruser(cpm_axi_pl0_0_aruser),
    .cpm_axi_pl0_0_arvalid(cpm_axi_pl0_0_arvalid),
    .cpm_axi_pl0_0_awaddr(cpm_axi_pl0_0_awaddr),
    .cpm_axi_pl0_0_awburst(cpm_axi_pl0_0_awburst),
    .cpm_axi_pl0_0_awcache(cpm_axi_pl0_0_awcache),
    .cpm_axi_pl0_0_awid(cpm_axi_pl0_0_awid),
    .cpm_axi_pl0_0_awlen(cpm_axi_pl0_0_awlen),
    .cpm_axi_pl0_0_awlock(cpm_axi_pl0_0_awlock),
    .cpm_axi_pl0_0_awprot(cpm_axi_pl0_0_awprot),
    .cpm_axi_pl0_0_awqos(cpm_axi_pl0_0_awqos),
    .cpm_axi_pl0_0_awready(cpm_axi_pl0_0_awready),
    .cpm_axi_pl0_0_awsize(cpm_axi_pl0_0_awsize),
    .cpm_axi_pl0_0_awuser(cpm_axi_pl0_0_awuser),
    .cpm_axi_pl0_0_awvalid(cpm_axi_pl0_0_awvalid),
    .cpm_axi_pl0_0_bid(cpm_axi_pl0_0_bid),
    .cpm_axi_pl0_0_bready(cpm_axi_pl0_0_bready),
    .cpm_axi_pl0_0_bresp(cpm_axi_pl0_0_bresp),
    .cpm_axi_pl0_0_buser(cpm_axi_pl0_0_buser),
    .cpm_axi_pl0_0_bvalid(cpm_axi_pl0_0_bvalid),
    .cpm_axi_pl0_0_rdata(cpm_axi_pl0_0_rdata),
    .cpm_axi_pl0_0_rid(cpm_axi_pl0_0_rid),
    .cpm_axi_pl0_0_rlast(cpm_axi_pl0_0_rlast),
    .cpm_axi_pl0_0_rready(cpm_axi_pl0_0_rready),
    .cpm_axi_pl0_0_rresp(cpm_axi_pl0_0_rresp),
    .cpm_axi_pl0_0_ruser(cpm_axi_pl0_0_ruser),
    .cpm_axi_pl0_0_rvalid(cpm_axi_pl0_0_rvalid),
    .cpm_axi_pl0_0_wdata(cpm_axi_pl0_0_wdata),
    .cpm_axi_pl0_0_wlast(cpm_axi_pl0_0_wlast),
    .cpm_axi_pl0_0_wready(cpm_axi_pl0_0_wready),
    .cpm_axi_pl0_0_wstrb(cpm_axi_pl0_0_wstrb),
    .cpm_axi_pl0_0_wuser(cpm_axi_pl0_0_wuser),
    .cpm_axi_pl0_0_wvalid(cpm_axi_pl0_0_wvalid),
    
        .aclk(aclk),
        .ctrl0_gt_refclk_0_clk_n(ctrl0_gt_refclk_0_clk_n),
        .ctrl0_gt_refclk_0_clk_p(ctrl0_gt_refclk_0_clk_p),
        .dbi0_rstn_0(dbi0_rstn_0),
        .dma0_irq_0(dma0_irq_0),
        .pcie0_msix_0_error(pcie0_msix_0_error),
        .pcie0_msix_0_func_num(pcie0_msix_0_func_num),
        .pcie0_msix_0_grant(pcie0_msix_0_grant),
        .pcie0_msix_0_operation(pcie0_msix_0_operation),
        .pcie0_msix_0_req(pcie0_msix_0_req),
        .pcie0_msix_0_vector_num(pcie0_msix_0_vector_num),
        .pcie0_msix_0_vfunc_active(pcie0_msix_0_vfunc_active),
        .pcie0_msix_0_vfunc_num(pcie0_msix_0_vfunc_num),
        .pcie0_rstn_0(pcie0_rstn_0),
        .pl_axil_dbi0_0_araddr(pl_axil_dbi0_0_araddr),
        .pl_axil_dbi0_0_arprot(pl_axil_dbi0_0_arprot),
        .pl_axil_dbi0_0_arready(pl_axil_dbi0_0_arready),
        .pl_axil_dbi0_0_aruser(pl_axil_dbi0_0_aruser),
        .pl_axil_dbi0_0_arvalid(pl_axil_dbi0_0_arvalid),
        .pl_axil_dbi0_0_awaddr(pl_axil_dbi0_0_awaddr),
        .pl_axil_dbi0_0_awprot(pl_axil_dbi0_0_awprot),
        .pl_axil_dbi0_0_awready(pl_axil_dbi0_0_awready),
        .pl_axil_dbi0_0_awuser(pl_axil_dbi0_0_awuser),
        .pl_axil_dbi0_0_awvalid(pl_axil_dbi0_0_awvalid),
        .pl_axil_dbi0_0_bready(pl_axil_dbi0_0_bready),
        .pl_axil_dbi0_0_bresp(pl_axil_dbi0_0_bresp),
        .pl_axil_dbi0_0_buser(pl_axil_dbi0_0_buser),
        .pl_axil_dbi0_0_bvalid(pl_axil_dbi0_0_bvalid),
        .pl_axil_dbi0_0_rdata(pl_axil_dbi0_0_rdata),
        .pl_axil_dbi0_0_rready(pl_axil_dbi0_0_rready),
        .pl_axil_dbi0_0_rresp(pl_axil_dbi0_0_rresp),
        .pl_axil_dbi0_0_ruser(pl_axil_dbi0_0_ruser),
        .pl_axil_dbi0_0_rvalid(pl_axil_dbi0_0_rvalid),
        .pl_axil_dbi0_0_wdata(pl_axil_dbi0_0_wdata),
        .pl_axil_dbi0_0_wready(pl_axil_dbi0_0_wready),
        .pl_axil_dbi0_0_wstrb(pl_axil_dbi0_0_wstrb),
        .pl_axil_dbi0_0_wuser(pl_axil_dbi0_0_wuser),
        .pl_axil_dbi0_0_wvalid(pl_axil_dbi0_0_wvalid),
        .M_LPD_AXI_0_araddr(M_LPD_AXI_0_araddr),
        .M_LPD_AXI_0_arid(M_LPD_AXI_0_arid),
        .M_LPD_AXI_0_arburst(M_LPD_AXI_0_arburst),
        .M_LPD_AXI_0_arcache(M_LPD_AXI_0_arcache),
        .M_LPD_AXI_0_arlen(M_LPD_AXI_0_arlen),
        .M_LPD_AXI_0_arlock(M_LPD_AXI_0_arlock),
        .M_LPD_AXI_0_arprot(M_LPD_AXI_0_arprot),
        .M_LPD_AXI_0_arqos(M_LPD_AXI_0_arqos),
        .M_LPD_AXI_0_arready(M_LPD_AXI_0_arready),
        .M_LPD_AXI_0_arsize(M_LPD_AXI_0_arsize),
        .M_LPD_AXI_0_arvalid(M_LPD_AXI_0_arvalid),
        .M_LPD_AXI_0_awaddr(M_LPD_AXI_0_awaddr),
        .M_LPD_AXI_0_awid(M_LPD_AXI_0_awid),
        .M_LPD_AXI_0_awburst(M_LPD_AXI_0_awburst),
        .M_LPD_AXI_0_awcache(M_LPD_AXI_0_awcache),
        .M_LPD_AXI_0_awlen(M_LPD_AXI_0_awlen),
        .M_LPD_AXI_0_awlock(M_LPD_AXI_0_awlock),
        .M_LPD_AXI_0_awprot(M_LPD_AXI_0_awprot),
        .M_LPD_AXI_0_awqos(M_LPD_AXI_0_awqos),
        .M_LPD_AXI_0_awready(M_LPD_AXI_0_awready),
        .M_LPD_AXI_0_awsize(M_LPD_AXI_0_awsize),
        .M_LPD_AXI_0_awvalid(M_LPD_AXI_0_awvalid),
        .M_LPD_AXI_0_bready(M_LPD_AXI_0_bready),
        .M_LPD_AXI_0_bid(M_LPD_AXI_0_bid),
        .M_LPD_AXI_0_bresp(M_LPD_AXI_0_bresp),
        .M_LPD_AXI_0_bvalid(M_LPD_AXI_0_bvalid),
        .M_LPD_AXI_0_rdata(M_LPD_AXI_0_rdata),
        .M_LPD_AXI_0_rid(M_LPD_AXI_0_rid),
        .M_LPD_AXI_0_rlast(M_LPD_AXI_0_rlast),
        .M_LPD_AXI_0_rready(M_LPD_AXI_0_rready),
        .M_LPD_AXI_0_rresp(M_LPD_AXI_0_rresp),
        .M_LPD_AXI_0_rvalid(M_LPD_AXI_0_rvalid),
        .M_LPD_AXI_0_wdata(M_LPD_AXI_0_wdata),
        .M_LPD_AXI_0_wlast(M_LPD_AXI_0_wlast),
        .M_LPD_AXI_0_wready(M_LPD_AXI_0_wready),
        .M_LPD_AXI_0_wstrb(M_LPD_AXI_0_wstrb),
        .M_LPD_AXI_0_wvalid(M_LPD_AXI_0_wvalid),
        .sys_clk0_0_clk_n(sys_clk0_0_clk_n),
        .sys_clk0_0_clk_p(sys_clk0_0_clk_p));


   // *** EDIT THESE TWO VALUES to resize PF/VF count across the entire design ***
   pl_example #(
     .NUM_PFS        (8),   // number of Physical Functions (PF0..PF7)
     .NUM_VFS_PER_PF (4)    // VFs per PF: PF-relative indices 0..3
   ) i_pl_example
     (
      .clk (aclk),
      .reset_n (pcie0_rstn_0),
      
      .m_pl_axil_awuser(cpm_m00_awuser),
      .m_pl_axil_aruser(cpm_m00_aruser),
      .m_pl_axil_araddr(M00_AXI_0_araddr),
      .m_pl_axil_arprot(M00_AXI_0_arprot),
      .m_pl_axil_arready(M00_AXI_0_arready),
      .m_pl_axil_arvalid(M00_AXI_0_arvalid),
      .m_pl_axil_awaddr(M00_AXI_0_awaddr),
      .m_pl_axil_awprot(M00_AXI_0_awprot),
      .m_pl_axil_awready(M00_AXI_0_awready),
      .m_pl_axil_awvalid(M00_AXI_0_awvalid),
      .m_pl_axil_bready(M00_AXI_0_bready),
      .m_pl_axil_bresp(M00_AXI_0_bresp),
      .m_pl_axil_bvalid(M00_AXI_0_bvalid),
      .m_pl_axil_rdata(M00_AXI_0_rdata),
      .m_pl_axil_rready(M00_AXI_0_rready),
      .m_pl_axil_rresp(M00_AXI_0_rresp),
      .m_pl_axil_rvalid(M00_AXI_0_rvalid),
      .m_pl_axil_wdata(M00_AXI_0_wdata),
      .m_pl_axil_wready(M00_AXI_0_wready),
      .m_pl_axil_wstrb(M00_AXI_0_wstrb),
      .m_pl_axil_wvalid(M00_AXI_0_wvalid),

      .s_flr_axi_awaddr(M_LPD_AXI_0_awaddr),
      .s_flr_axi_awid(M_LPD_AXI_0_awid),
      .s_flr_axi_awprot(M_LPD_AXI_0_awprot),
      .s_flr_axi_awlen(M_LPD_AXI_0_awlen),
      .s_flr_axi_awsize(M_LPD_AXI_0_awsize),
      .s_flr_axi_awburst(M_LPD_AXI_0_awburst),
      .s_flr_axi_awlock(M_LPD_AXI_0_awlock),
      .s_flr_axi_awcache(M_LPD_AXI_0_awcache),
      .s_flr_axi_awqos(M_LPD_AXI_0_awqos),
      .s_flr_axi_awvalid(M_LPD_AXI_0_awvalid),
      .s_flr_axi_awready(M_LPD_AXI_0_awready),
      .s_flr_axi_wdata(M_LPD_AXI_0_wdata),
      .s_flr_axi_wstrb(M_LPD_AXI_0_wstrb),
      .s_flr_axi_wlast(M_LPD_AXI_0_wlast),
      .s_flr_axi_wvalid(M_LPD_AXI_0_wvalid),
      .s_flr_axi_wready(M_LPD_AXI_0_wready),
      .s_flr_axi_bid(M_LPD_AXI_0_bid),
      .s_flr_axi_bresp(M_LPD_AXI_0_bresp),
      .s_flr_axi_bvalid(M_LPD_AXI_0_bvalid),
      .s_flr_axi_bready(M_LPD_AXI_0_bready),
      .s_flr_axi_araddr(M_LPD_AXI_0_araddr),
      .s_flr_axi_arid(M_LPD_AXI_0_arid),
      .s_flr_axi_arprot(M_LPD_AXI_0_arprot),
      .s_flr_axi_arlen(M_LPD_AXI_0_arlen),
      .s_flr_axi_arsize(M_LPD_AXI_0_arsize),
      .s_flr_axi_arburst(M_LPD_AXI_0_arburst),
      .s_flr_axi_arlock(M_LPD_AXI_0_arlock),
      .s_flr_axi_arcache(M_LPD_AXI_0_arcache),
      .s_flr_axi_arqos(M_LPD_AXI_0_arqos),
      .s_flr_axi_arvalid(M_LPD_AXI_0_arvalid),
      .s_flr_axi_arready(M_LPD_AXI_0_arready),
      .s_flr_axi_rdata(M_LPD_AXI_0_rdata),
      .s_flr_axi_rid(M_LPD_AXI_0_rid),
      .s_flr_axi_rresp(M_LPD_AXI_0_rresp),
      .s_flr_axi_rlast(M_LPD_AXI_0_rlast),
      .s_flr_axi_rvalid(M_LPD_AXI_0_rvalid),
      .s_flr_axi_rready(M_LPD_AXI_0_rready),

      .m_dbi_axil_araddr(pl_axil_dbi0_0_araddr),
      .m_dbi_axil_arprot(pl_axil_dbi0_0_arprot),
      .m_dbi_axil_arready(pl_axil_dbi0_0_arready),
      .m_dbi_axil_aruser(pl_axil_dbi0_0_aruser),
      .m_dbi_axil_arvalid(pl_axil_dbi0_0_arvalid),
      .m_dbi_axil_awaddr(pl_axil_dbi0_0_awaddr),
      .m_dbi_axil_awprot(pl_axil_dbi0_0_awprot),
      .m_dbi_axil_awready(pl_axil_dbi0_0_awready),
      .m_dbi_axil_awuser(pl_axil_dbi0_0_awuser),
      .m_dbi_axil_awvalid(pl_axil_dbi0_0_awvalid),
      .m_dbi_axil_bready(pl_axil_dbi0_0_bready),
      .m_dbi_axil_bresp(pl_axil_dbi0_0_bresp),
      .m_dbi_axil_buser(pl_axil_dbi0_0_buser),
      .m_dbi_axil_bvalid(pl_axil_dbi0_0_bvalid),
      .m_dbi_axil_rdata(pl_axil_dbi0_0_rdata),
      .m_dbi_axil_rready(pl_axil_dbi0_0_rready),
      .m_dbi_axil_rresp(pl_axil_dbi0_0_rresp),
      .m_dbi_axil_ruser(pl_axil_dbi0_0_ruser),
      .m_dbi_axil_rvalid(pl_axil_dbi0_0_rvalid),
      .m_dbi_axil_wdata(pl_axil_dbi0_0_wdata),
      .m_dbi_axil_wready(pl_axil_dbi0_0_wready),
      .m_dbi_axil_wstrb(pl_axil_dbi0_0_wstrb),
      .m_dbi_axil_wuser(pl_axil_dbi0_0_wuser),
      .m_dbi_axil_wvalid(pl_axil_dbi0_0_wvalid),
      .pcie_msix_error        (pcie0_msix_0_error),
      .pcie_msix_func_num     (pcie0_msix_0_func_num),
      .pcie_msix_grant         (pcie0_msix_0_grant),
      .pcie_msix_operation     (pcie0_msix_0_operation),
      .pcie_msix_req           (pcie0_msix_0_req),
      .pcie_msix_vector_num   (pcie0_msix_0_vector_num),
      .pcie_msix_vfunc_active (pcie0_msix_0_vfunc_active),
      .pcie_msix_vfunc_num     (pcie0_msix_0_vfunc_num),
      .dma_irq                 (dma0_irq_0)
      );
   


   
endmodule
