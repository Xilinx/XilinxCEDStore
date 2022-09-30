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
`define CDX5N_PROTO_UPORT 1

`timescale 1 ps / 1 ps
`include "cpm5n_interface.svh"

module design_1_wrapper
import cpm5n_v1_0_1_pkg::*;
  (
    PCIE0_GT_0_grx_n,
    PCIE0_GT_0_grx_p,
    PCIE0_GT_0_gtx_n,
    PCIE0_GT_0_gtx_p,

    gt_refclk0_0_clk_n,
    gt_refclk0_0_clk_p
    
  );
  
  input [15:0]PCIE0_GT_0_grx_n;
  input [15:0]PCIE0_GT_0_grx_p;
  output [15:0]PCIE0_GT_0_gtx_n;
  output [15:0]PCIE0_GT_0_gtx_p;
  
  input gt_refclk0_0_clk_n;
  input gt_refclk0_0_clk_p;
  
  wire [63:0]FPD_AXI_PL_0_araddr;
  wire [1:0]FPD_AXI_PL_0_arburst;
  wire [3:0]FPD_AXI_PL_0_arcache;
  wire [15:0]FPD_AXI_PL_0_arid;
  wire [7:0]FPD_AXI_PL_0_arlen;
  wire FPD_AXI_PL_0_arlock;
  wire [2:0]FPD_AXI_PL_0_arprot;
  wire [3:0]FPD_AXI_PL_0_arqos;
  wire FPD_AXI_PL_0_arready;
  wire [2:0]FPD_AXI_PL_0_arsize;
  wire [15:0]FPD_AXI_PL_0_aruser;
  wire FPD_AXI_PL_0_arvalid;
  wire [63:0]FPD_AXI_PL_0_awaddr;
  wire [1:0]FPD_AXI_PL_0_awburst;
  wire [3:0]FPD_AXI_PL_0_awcache;
  wire [15:0]FPD_AXI_PL_0_awid;
  wire [7:0]FPD_AXI_PL_0_awlen;
  wire FPD_AXI_PL_0_awlock;
  wire [2:0]FPD_AXI_PL_0_awprot;
  wire [3:0]FPD_AXI_PL_0_awqos;
  wire FPD_AXI_PL_0_awready;
  wire [2:0]FPD_AXI_PL_0_awsize;
  wire [15:0]FPD_AXI_PL_0_awuser;
  wire FPD_AXI_PL_0_awvalid;
  wire [15:0]FPD_AXI_PL_0_bid;
  wire FPD_AXI_PL_0_bready;
  wire [1:0]FPD_AXI_PL_0_bresp;
  wire FPD_AXI_PL_0_bvalid;
  wire [31:0]FPD_AXI_PL_0_rdata;
  wire [15:0]FPD_AXI_PL_0_rid;
  wire FPD_AXI_PL_0_rlast;
  wire FPD_AXI_PL_0_rready;
  wire [1:0]FPD_AXI_PL_0_rresp;
  wire FPD_AXI_PL_0_rvalid;
  wire [31:0]FPD_AXI_PL_0_wdata;
  wire FPD_AXI_PL_0_wlast;
  wire FPD_AXI_PL_0_wready;
  wire [15:0]FPD_AXI_PL_0_wstrb;
  wire FPD_AXI_PL_0_wvalid;
  wire [15:0]PCIE0_GT_0_grx_n;
  wire [15:0]PCIE0_GT_0_grx_p;
  wire [15:0]PCIE0_GT_0_gtx_n;
  wire [15:0]PCIE0_GT_0_gtx_p;
  wire [48:0]PL_AXI_FPD0_0_araddr;
  wire [1:0]PL_AXI_FPD0_0_arburst;
  wire [3:0]PL_AXI_FPD0_0_arcache;
  wire [10:0]PL_AXI_FPD0_0_arid;
  wire [7:0]PL_AXI_FPD0_0_arlen;
  wire PL_AXI_FPD0_0_arlock;
  wire [2:0]PL_AXI_FPD0_0_arprot;
  wire [3:0]PL_AXI_FPD0_0_arqos;
  wire PL_AXI_FPD0_0_arready;
  wire [2:0]PL_AXI_FPD0_0_arsize;
  wire [11:0]PL_AXI_FPD0_0_aruser;
  wire PL_AXI_FPD0_0_arvalid;
  wire [48:0]PL_AXI_FPD0_0_awaddr;
  wire [1:0]PL_AXI_FPD0_0_awburst;
  wire [3:0]PL_AXI_FPD0_0_awcache;
  wire [10:0]PL_AXI_FPD0_0_awid;
  wire [7:0]PL_AXI_FPD0_0_awlen;
  wire PL_AXI_FPD0_0_awlock;
  wire [2:0]PL_AXI_FPD0_0_awprot;
  wire [3:0]PL_AXI_FPD0_0_awqos;
  wire PL_AXI_FPD0_0_awready;
  wire [2:0]PL_AXI_FPD0_0_awsize;
  wire [11:0]PL_AXI_FPD0_0_awuser;
  wire PL_AXI_FPD0_0_awvalid;
  wire [10:0]PL_AXI_FPD0_0_bid;
  wire PL_AXI_FPD0_0_bready;
  wire [1:0]PL_AXI_FPD0_0_bresp;
  wire PL_AXI_FPD0_0_bvalid;
  wire [31:0]PL_AXI_FPD0_0_rdata;
  wire [10:0]PL_AXI_FPD0_0_rid;
  wire PL_AXI_FPD0_0_rlast;
  wire PL_AXI_FPD0_0_rready;
  wire [1:0]PL_AXI_FPD0_0_rresp;
  wire PL_AXI_FPD0_0_rvalid;
  wire [31:0]PL_AXI_FPD0_0_wdata;
  wire PL_AXI_FPD0_0_wlast;
  wire PL_AXI_FPD0_0_wready;
  wire [15:0]PL_AXI_FPD0_0_wstrb;
  wire PL_AXI_FPD0_0_wvalid;
  wire [3:0]cdx_gic_0;
  wire cpm_bot_user_clk_0;
  wire cpm_cor_irq_0;
  wire [31:0]cpm_gpi_0;
  wire [31:0]cpm_gpo_0;
  wire cpm_irq0_0;
  wire cpm_irq1_0;
  wire cpm_misc_irq_0;
  wire cpm_uncor_irq_0;
  wire [21:0]csi0_dst_crdt_0_tdata;
  wire csi0_dst_crdt_0_tready;
  wire csi0_dst_crdt_0_tvalid;
  wire [6:0]csi0_local_crdts_0_buf_id;
  wire [15:0]csi0_local_crdts_0_data;
  wire [1:0]csi0_local_crdts_0_flow_type;
  wire csi0_local_crdts_0_rdy;
  wire [1:0]csi0_local_crdts_0_snk_id;
  wire [1:0]csi0_local_crdts_0_src_furc_id;
  wire csi0_local_crdts_0_vld;
  wire csi0_npr_req_0_eop;
  wire csi0_npr_req_0_err;
  wire csi0_npr_req_0_rdy;
  wire [319:0]csi0_npr_req_0_seg;
  wire csi0_npr_req_0_sop;
  wire csi0_npr_req_0_vld;
  wire csi0_port_resp0_0_eop;
  wire csi0_port_resp0_0_err;
  wire csi0_port_resp0_0_rdy;
  wire [319:0]csi0_port_resp0_0_seg;
  wire csi0_port_resp0_0_sop;
  wire csi0_port_resp0_0_vld;
  wire csi0_port_resp1_0_eop;
  wire csi0_port_resp1_0_err;
  wire csi0_port_resp1_0_rdy;
  wire [319:0]csi0_port_resp1_0_seg;
  wire csi0_port_resp1_0_sop;
  wire csi0_port_resp1_0_vld;
  wire csi0_prcmpl_req0_0_eop;
  wire csi0_prcmpl_req0_0_err;
  wire csi0_prcmpl_req0_0_rdy;
  wire [319:0]csi0_prcmpl_req0_0_seg;
  wire csi0_prcmpl_req0_0_sop;
  wire csi0_prcmpl_req0_0_vld;
  wire csi0_prcmpl_req1_0_eop;
  wire csi0_prcmpl_req1_0_err;
  wire csi0_prcmpl_req1_0_rdy;
  wire [319:0]csi0_prcmpl_req1_0_seg;
  wire csi0_prcmpl_req1_0_sop;
  wire csi0_prcmpl_req1_0_vld;
  wire fpd_axi_pl_aclk_0;
  wire gt_refclk0_0_clk_n;
  wire gt_refclk0_0_clk_p;
  wire [47:0]m_axi_hah_0_araddr;
  wire [2:0]m_axi_hah_0_arprot;
  wire m_axi_hah_0_arready;
  wire [31:0]m_axi_hah_0_aruser;
  wire m_axi_hah_0_arvalid;
  wire [47:0]m_axi_hah_0_awaddr;
  wire [2:0]m_axi_hah_0_awprot;
  wire m_axi_hah_0_awready;
  wire [31:0]m_axi_hah_0_awuser;
  wire m_axi_hah_0_awvalid;
  wire m_axi_hah_0_bready;
  wire [1:0]m_axi_hah_0_bresp;
  wire m_axi_hah_0_bvalid;
  wire [63:0]m_axi_hah_0_rdata;
  wire [3:0]m_axi_hah_0_rdatainfo;
  wire m_axi_hah_0_rready;
  wire [1:0]m_axi_hah_0_rresp;
  wire m_axi_hah_0_rvalid;
  wire [63:0]m_axi_hah_0_wdata;
  wire [3:0]m_axi_hah_0_wdatainfo;
  wire m_axi_hah_0_wready;
  wire [7:0]m_axi_hah_0_wstrb;
  wire m_axi_hah_0_wvalid;
  wire pl0_ref_clk_0;
  wire pl_axi_fpd0_aclk_0;
  wire [31:0]s_axi_flr_0_araddr;
  wire [2:0]s_axi_flr_0_arprot;
  wire s_axi_flr_0_arready;
  wire [12:0]s_axi_flr_0_aruser;
  wire s_axi_flr_0_arvalid;
  wire [31:0]s_axi_flr_0_awaddr;
  wire [2:0]s_axi_flr_0_awprot;
  wire s_axi_flr_0_awready;
  wire [12:0]s_axi_flr_0_awuser;
  wire s_axi_flr_0_awvalid;
  wire s_axi_flr_0_bready;
  wire [1:0]s_axi_flr_0_bresp;
  wire s_axi_flr_0_bvalid;
  wire [31:0]s_axi_flr_0_rdata;
  wire [3:0]s_axi_flr_0_rdatainfo;
  wire s_axi_flr_0_rready;
  wire [1:0]s_axi_flr_0_rresp;
  wire s_axi_flr_0_rvalid;
  wire [31:0]s_axi_flr_0_wdata;
  wire [3:0]s_axi_flr_0_wdatainfo;
  wire s_axi_flr_0_wready;
  wire [3:0]s_axi_flr_0_wstrb;
  wire s_axi_flr_0_wvalid;
  wire tstamp_pps_in_0;
  wire tstamp_pps_out_0;

  wire pl0_rst_n;
  wire pcie0_user_clk_0;
  wire pcie0_user_reset_0;

   
  //using 250MHz clk as PL Ref clk;
  assign cpm_bot_user_clk_0 = pl0_ref_clk_0;
  assign fpd_axi_pl_aclk_0  = pl0_ref_clk_0;
  assign pl_axi_fpd0_aclk_0 = pl0_ref_clk_0;


  design_1 design_1_i
       (
        .PCIE0_GT_0_grx_n(PCIE0_GT_0_grx_n),
        .PCIE0_GT_0_grx_p(PCIE0_GT_0_grx_p),
        .PCIE0_GT_0_gtx_n(PCIE0_GT_0_gtx_n),
        .PCIE0_GT_0_gtx_p(PCIE0_GT_0_gtx_p),
        .gt_refclk0_0_clk_n(gt_refclk0_0_clk_n),
        .gt_refclk0_0_clk_p(gt_refclk0_0_clk_p),
       
        .fpd_axi_pl_aclk_0(fpd_axi_pl_aclk_0),
        .cpm_bot_user_clk_0(cpm_bot_user_clk_0),
        .pl0_ref_clk_0(pl0_ref_clk_0), // pl0_ref_clk_0),
        .pl_axi_fpd0_aclk_0(pl_axi_fpd0_aclk_0),
	.cdx_bot_rst_n_0(pl0_rst_n),
	.pl0_resetn_0(pl0_rst_n),
        
	.cdx_gic_0(cdx_gic_0),
        .cpm_cor_irq_0(cpm_cor_irq_0),
        .cpm_gpi_0(cpm_gpi_0),
        .cpm_gpo_0(cpm_gpo_0),
        .cpm_misc_irq_0(cpm_misc_irq_0),
        .cpm_uncor_irq_0(cpm_uncor_irq_0),

        /*
	.FPD_AXI_PL_0_araddr(FPD_AXI_PL_0_araddr),
        .FPD_AXI_PL_0_arburst(FPD_AXI_PL_0_arburst),
        .FPD_AXI_PL_0_arcache(FPD_AXI_PL_0_arcache),
        .FPD_AXI_PL_0_arid(FPD_AXI_PL_0_arid),
        .FPD_AXI_PL_0_arlen(FPD_AXI_PL_0_arlen),
        .FPD_AXI_PL_0_arlock(FPD_AXI_PL_0_arlock),
        .FPD_AXI_PL_0_arprot(FPD_AXI_PL_0_arprot),
        .FPD_AXI_PL_0_arqos(FPD_AXI_PL_0_arqos),
        .FPD_AXI_PL_0_arready(FPD_AXI_PL_0_arready),
        .FPD_AXI_PL_0_arsize(FPD_AXI_PL_0_arsize),
        .FPD_AXI_PL_0_aruser(FPD_AXI_PL_0_aruser),
        .FPD_AXI_PL_0_arvalid(FPD_AXI_PL_0_arvalid),
        .FPD_AXI_PL_0_awaddr(FPD_AXI_PL_0_awaddr),
        .FPD_AXI_PL_0_awburst(FPD_AXI_PL_0_awburst),
        .FPD_AXI_PL_0_awcache(FPD_AXI_PL_0_awcache),
        .FPD_AXI_PL_0_awid(FPD_AXI_PL_0_awid),
        .FPD_AXI_PL_0_awlen(FPD_AXI_PL_0_awlen),
        .FPD_AXI_PL_0_awlock(FPD_AXI_PL_0_awlock),
        .FPD_AXI_PL_0_awprot(FPD_AXI_PL_0_awprot),
        .FPD_AXI_PL_0_awqos(FPD_AXI_PL_0_awqos),
        .FPD_AXI_PL_0_awready(FPD_AXI_PL_0_awready),
        .FPD_AXI_PL_0_awsize(FPD_AXI_PL_0_awsize),
        .FPD_AXI_PL_0_awuser(FPD_AXI_PL_0_awuser),
        .FPD_AXI_PL_0_awvalid(FPD_AXI_PL_0_awvalid),
        .FPD_AXI_PL_0_bid(FPD_AXI_PL_0_bid),
        .FPD_AXI_PL_0_bready(FPD_AXI_PL_0_bready),
        .FPD_AXI_PL_0_bresp(FPD_AXI_PL_0_bresp),
        .FPD_AXI_PL_0_bvalid(FPD_AXI_PL_0_bvalid),
        .FPD_AXI_PL_0_rdata(FPD_AXI_PL_0_rdata),
        .FPD_AXI_PL_0_rid(FPD_AXI_PL_0_rid),
        .FPD_AXI_PL_0_rlast(FPD_AXI_PL_0_rlast),
        .FPD_AXI_PL_0_rready(FPD_AXI_PL_0_rready),
        .FPD_AXI_PL_0_rresp(FPD_AXI_PL_0_rresp),
        .FPD_AXI_PL_0_rvalid(FPD_AXI_PL_0_rvalid),
        .FPD_AXI_PL_0_wdata(FPD_AXI_PL_0_wdata),
        .FPD_AXI_PL_0_wlast(FPD_AXI_PL_0_wlast),
        .FPD_AXI_PL_0_wready(FPD_AXI_PL_0_wready),
        .FPD_AXI_PL_0_wstrb(FPD_AXI_PL_0_wstrb),
        .FPD_AXI_PL_0_wvalid(FPD_AXI_PL_0_wvalid),
        .PL_AXI_FPD0_0_araddr(PL_AXI_FPD0_0_araddr),
        .PL_AXI_FPD0_0_arburst(PL_AXI_FPD0_0_arburst),
        .PL_AXI_FPD0_0_arcache(PL_AXI_FPD0_0_arcache),
        .PL_AXI_FPD0_0_arid(PL_AXI_FPD0_0_arid),
        .PL_AXI_FPD0_0_arlen(PL_AXI_FPD0_0_arlen),
        .PL_AXI_FPD0_0_arlock(PL_AXI_FPD0_0_arlock),
        .PL_AXI_FPD0_0_arprot(PL_AXI_FPD0_0_arprot),
        .PL_AXI_FPD0_0_arqos(PL_AXI_FPD0_0_arqos),
        .PL_AXI_FPD0_0_arready(PL_AXI_FPD0_0_arready),
        .PL_AXI_FPD0_0_arsize(PL_AXI_FPD0_0_arsize),
        .PL_AXI_FPD0_0_aruser(PL_AXI_FPD0_0_aruser),
        .PL_AXI_FPD0_0_arvalid(PL_AXI_FPD0_0_arvalid),
        .PL_AXI_FPD0_0_awaddr(PL_AXI_FPD0_0_awaddr),
        .PL_AXI_FPD0_0_awburst(PL_AXI_FPD0_0_awburst),
        .PL_AXI_FPD0_0_awcache(PL_AXI_FPD0_0_awcache),
        .PL_AXI_FPD0_0_awid(PL_AXI_FPD0_0_awid),
        .PL_AXI_FPD0_0_awlen(PL_AXI_FPD0_0_awlen),
        .PL_AXI_FPD0_0_awlock(PL_AXI_FPD0_0_awlock),
        .PL_AXI_FPD0_0_awprot(PL_AXI_FPD0_0_awprot),
        .PL_AXI_FPD0_0_awqos(PL_AXI_FPD0_0_awqos),
        .PL_AXI_FPD0_0_awready(PL_AXI_FPD0_0_awready),
        .PL_AXI_FPD0_0_awsize(PL_AXI_FPD0_0_awsize),
        .PL_AXI_FPD0_0_awuser(PL_AXI_FPD0_0_awuser),
        .PL_AXI_FPD0_0_awvalid(PL_AXI_FPD0_0_awvalid),
        .PL_AXI_FPD0_0_bid(PL_AXI_FPD0_0_bid),
        .PL_AXI_FPD0_0_bready(PL_AXI_FPD0_0_bready),
        .PL_AXI_FPD0_0_bresp(PL_AXI_FPD0_0_bresp),
        .PL_AXI_FPD0_0_bvalid(PL_AXI_FPD0_0_bvalid),
        .PL_AXI_FPD0_0_rdata(PL_AXI_FPD0_0_rdata),
        .PL_AXI_FPD0_0_rid(PL_AXI_FPD0_0_rid),
        .PL_AXI_FPD0_0_rlast(PL_AXI_FPD0_0_rlast),
        .PL_AXI_FPD0_0_rready(PL_AXI_FPD0_0_rready),
        .PL_AXI_FPD0_0_rresp(PL_AXI_FPD0_0_rresp),
        .PL_AXI_FPD0_0_rvalid(PL_AXI_FPD0_0_rvalid),
        .PL_AXI_FPD0_0_wdata(PL_AXI_FPD0_0_wdata),
        .PL_AXI_FPD0_0_wlast(PL_AXI_FPD0_0_wlast),
        .PL_AXI_FPD0_0_wready(PL_AXI_FPD0_0_wready),
        .PL_AXI_FPD0_0_wstrb(PL_AXI_FPD0_0_wstrb),
        .PL_AXI_FPD0_0_wvalid(PL_AXI_FPD0_0_wvalid),
        */

        .csi0_dst_crdt_0_tdata(csi0_dst_crdt_0_tdata),
        .csi0_dst_crdt_0_tready(csi0_dst_crdt_0_tready),
        .csi0_dst_crdt_0_tvalid(csi0_dst_crdt_0_tvalid),
        .csi0_local_crdts_0_buf_id(csi0_local_crdts_0_buf_id),
        .csi0_local_crdts_0_data(csi0_local_crdts_0_data),
        .csi0_local_crdts_0_flow_type(csi0_local_crdts_0_flow_type),
        .csi0_local_crdts_0_rdy(csi0_local_crdts_0_rdy),
        .csi0_local_crdts_0_snk_id(csi0_local_crdts_0_snk_id),
        .csi0_local_crdts_0_src_furc_id(csi0_local_crdts_0_src_furc_id),
        .csi0_local_crdts_0_vld(csi0_local_crdts_0_vld),
        .csi0_npr_req_0_eop(csi0_npr_req_0_eop),
        .csi0_npr_req_0_err(csi0_npr_req_0_err),
        .csi0_npr_req_0_rdy(csi0_npr_req_0_rdy),
        .csi0_npr_req_0_seg(csi0_npr_req_0_seg),
        .csi0_npr_req_0_sop(csi0_npr_req_0_sop),
        .csi0_npr_req_0_vld(csi0_npr_req_0_vld),
        .csi0_port_resp0_0_eop(csi0_port_resp0_0_eop),
        .csi0_port_resp0_0_err(csi0_port_resp0_0_err),
        .csi0_port_resp0_0_rdy(csi0_port_resp0_0_rdy),
        .csi0_port_resp0_0_seg(csi0_port_resp0_0_seg),
        .csi0_port_resp0_0_sop(csi0_port_resp0_0_sop),
        .csi0_port_resp0_0_vld(csi0_port_resp0_0_vld),
        .csi0_port_resp1_0_eop(csi0_port_resp1_0_eop),
        .csi0_port_resp1_0_err(csi0_port_resp1_0_err),
        .csi0_port_resp1_0_rdy(csi0_port_resp1_0_rdy),
        .csi0_port_resp1_0_seg(csi0_port_resp1_0_seg),
        .csi0_port_resp1_0_sop(csi0_port_resp1_0_sop),
        .csi0_port_resp1_0_vld(csi0_port_resp1_0_vld),
        .csi0_prcmpl_req0_0_eop(csi0_prcmpl_req0_0_eop),
        .csi0_prcmpl_req0_0_err(csi0_prcmpl_req0_0_err),
        .csi0_prcmpl_req0_0_rdy(csi0_prcmpl_req0_0_rdy),
        .csi0_prcmpl_req0_0_seg(csi0_prcmpl_req0_0_seg),
        .csi0_prcmpl_req0_0_sop(csi0_prcmpl_req0_0_sop),
        .csi0_prcmpl_req0_0_vld(csi0_prcmpl_req0_0_vld),
        .csi0_prcmpl_req1_0_eop(csi0_prcmpl_req1_0_eop),
        .csi0_prcmpl_req1_0_err(csi0_prcmpl_req1_0_err),
        .csi0_prcmpl_req1_0_rdy(csi0_prcmpl_req1_0_rdy),
        .csi0_prcmpl_req1_0_seg(csi0_prcmpl_req1_0_seg),
        .csi0_prcmpl_req1_0_sop(csi0_prcmpl_req1_0_sop),
        .csi0_prcmpl_req1_0_vld(csi0_prcmpl_req1_0_vld),
       
        .m_axi_hah_0_araddr(m_axi_hah_0_araddr),
        .m_axi_hah_0_arprot(m_axi_hah_0_arprot),
        .m_axi_hah_0_arready(m_axi_hah_0_arready),
        .m_axi_hah_0_aruser(m_axi_hah_0_aruser),
        .m_axi_hah_0_arvalid(m_axi_hah_0_arvalid),
        .m_axi_hah_0_awaddr(m_axi_hah_0_awaddr),
        .m_axi_hah_0_awprot(m_axi_hah_0_awprot),
        .m_axi_hah_0_awready(m_axi_hah_0_awready),
        .m_axi_hah_0_awuser(m_axi_hah_0_awuser),
        .m_axi_hah_0_awvalid(m_axi_hah_0_awvalid),
        .m_axi_hah_0_bready(m_axi_hah_0_bready),
        .m_axi_hah_0_bresp(m_axi_hah_0_bresp),
        .m_axi_hah_0_bvalid(m_axi_hah_0_bvalid),
        .m_axi_hah_0_rdata(m_axi_hah_0_rdata),
        .m_axi_hah_0_rdatainfo(m_axi_hah_0_rdatainfo),
        .m_axi_hah_0_rready(m_axi_hah_0_rready),
        .m_axi_hah_0_rresp(m_axi_hah_0_rresp),
        .m_axi_hah_0_rvalid(m_axi_hah_0_rvalid),
        .m_axi_hah_0_wdata(m_axi_hah_0_wdata),
        .m_axi_hah_0_wdatainfo(m_axi_hah_0_wdatainfo),
        .m_axi_hah_0_wready(m_axi_hah_0_wready),
        .m_axi_hah_0_wstrb(m_axi_hah_0_wstrb),
        .m_axi_hah_0_wvalid(m_axi_hah_0_wvalid),
        
	.s_axi_flr_0_araddr(s_axi_flr_0_araddr),
        .s_axi_flr_0_arprot(s_axi_flr_0_arprot),
        .s_axi_flr_0_arready(s_axi_flr_0_arready),
        .s_axi_flr_0_aruser(s_axi_flr_0_aruser),
        .s_axi_flr_0_arvalid(s_axi_flr_0_arvalid),
        .s_axi_flr_0_awaddr(s_axi_flr_0_awaddr),
        .s_axi_flr_0_awprot(s_axi_flr_0_awprot),
        .s_axi_flr_0_awready(s_axi_flr_0_awready),
        .s_axi_flr_0_awuser(s_axi_flr_0_awuser),
        .s_axi_flr_0_awvalid(s_axi_flr_0_awvalid),
        .s_axi_flr_0_bready(s_axi_flr_0_bready),
        .s_axi_flr_0_bresp(s_axi_flr_0_bresp),
        .s_axi_flr_0_bvalid(s_axi_flr_0_bvalid),
        .s_axi_flr_0_rdata(s_axi_flr_0_rdata),
        .s_axi_flr_0_rdatainfo(s_axi_flr_0_rdatainfo),
        .s_axi_flr_0_rready(s_axi_flr_0_rready),
        .s_axi_flr_0_rresp(s_axi_flr_0_rresp),
        .s_axi_flr_0_rvalid(s_axi_flr_0_rvalid),
        .s_axi_flr_0_wdata(s_axi_flr_0_wdata),
        .s_axi_flr_0_wdatainfo(s_axi_flr_0_wdatainfo),
        .s_axi_flr_0_wready(s_axi_flr_0_wready),
        .s_axi_flr_0_wstrb(s_axi_flr_0_wstrb),
        .s_axi_flr_0_wvalid(s_axi_flr_0_wvalid),
        .tstamp_pps_in_0(tstamp_pps_in_0),
        .tstamp_pps_out_0(tstamp_pps_out_0));

  cdx5n_fab_2s_seg_if                csi2f_port0_out();
  cdx5n_fab_2s_seg_if                f2csi_port0_prcmpl_in();
  cdx5n_fab_1s_seg_if                f2csi_port0_npr_in();
  cdx5n_csi_local_crdt_if            local_crdt_port0_out();
  cdx5n_csi_snk_sched_ser_ing_if     dest_crdt_port0_in();
 
  wire  [31:0]                       csi_uport_axil_araddr;
  wire  [2:0]                        csi_uport_axil_arprot;
  wire                               csi_uport_axil_arready;
  wire                               csi_uport_axil_arvalid;
  wire  [31:0]                       csi_uport_axil_awaddr;
  wire  [2:0]                        csi_uport_axil_awprot;
  wire                               csi_uport_axil_awready;
  wire                               csi_uport_axil_awvalid;
  wire                               csi_uport_axil_bready;
  wire  [1:0]                        csi_uport_axil_bresp;
  wire                               csi_uport_axil_bvalid;
  wire  [31:0]                       csi_uport_axil_rdata;
  wire                               csi_uport_axil_rready;
  wire  [1:0]                        csi_uport_axil_rresp;
  wire                               csi_uport_axil_rvalid;
  wire  [31:0]                       csi_uport_axil_wdata;
  wire                               csi_uport_axil_wready;
  wire  [3:0]                        csi_uport_axil_wstrb;
  wire                               csi_uport_axil_wvalid;

  assign csi2f_port0_out.seg[0]                      = csi0_port_resp0_0_seg  ;
  assign csi2f_port0_out.vld[0]                      = csi0_port_resp0_0_vld  ; 
  assign csi2f_port0_out.sop[0]                      = csi0_port_resp0_0_sop  ; 
  assign csi2f_port0_out.eop[0]                      = csi0_port_resp0_0_eop  ; 
  assign csi2f_port0_out.err[0]                      = csi0_port_resp0_0_err  ; 
  assign csi0_port_resp0_0_rdy                       = csi2f_port0_out.rdy[0]; 
  
  assign csi2f_port0_out.seg[1]                      = csi0_port_resp1_0_seg  ;
  assign csi2f_port0_out.vld[1]                      = csi0_port_resp1_0_vld  ; 
  assign csi2f_port0_out.sop[1]                      = csi0_port_resp1_0_sop  ; 
  assign csi2f_port0_out.eop[1]                      = csi0_port_resp1_0_eop  ; 
  assign csi2f_port0_out.err[1]                      = csi0_port_resp1_0_err  ; 
  assign csi0_port_resp1_0_rdy                       = csi2f_port0_out.rdy[1]; 

  assign csi0_prcmpl_req0_0_seg                      = f2csi_port0_prcmpl_in.seg[0];
  assign csi0_prcmpl_req0_0_vld                      = f2csi_port0_prcmpl_in.vld[0];
  assign csi0_prcmpl_req0_0_sop                      = f2csi_port0_prcmpl_in.sop[0];
  assign csi0_prcmpl_req0_0_eop                      = f2csi_port0_prcmpl_in.eop[0];
  assign csi0_prcmpl_req0_0_err                      = f2csi_port0_prcmpl_in.err[0];
  assign f2csi_port0_prcmpl_in.rdy[0]                = csi0_prcmpl_req0_0_rdy;

  assign csi0_prcmpl_req1_0_seg                      = f2csi_port0_prcmpl_in.seg[1];
  assign csi0_prcmpl_req1_0_vld                      = f2csi_port0_prcmpl_in.vld[1];
  assign csi0_prcmpl_req1_0_sop                      = f2csi_port0_prcmpl_in.sop[1];
  assign csi0_prcmpl_req1_0_eop                      = f2csi_port0_prcmpl_in.eop[1];
  assign csi0_prcmpl_req1_0_err                      = f2csi_port0_prcmpl_in.err[1];
  assign f2csi_port0_prcmpl_in.rdy[1]                = csi0_prcmpl_req1_0_rdy;

  assign csi0_npr_req_0_seg                          = f2csi_port0_npr_in.seg;
  assign csi0_npr_req_0_vld                          = f2csi_port0_npr_in.vld;
  assign csi0_npr_req_0_sop                          = f2csi_port0_npr_in.sop;
  assign csi0_npr_req_0_eop                          = f2csi_port0_npr_in.eop;
  assign csi0_npr_req_0_err                          = f2csi_port0_npr_in.err;
  assign f2csi_port0_npr_in.rdy                      = csi0_npr_req_0_rdy ;

  assign csi0_dst_crdt_0_tdata                       = dest_crdt_port0_in.ser_ing_intf_in; 
  assign csi0_dst_crdt_0_tvalid                      = dest_crdt_port0_in.ser_ing_intf_vld;
  assign dest_crdt_port0_in.ser_ing_intf_rdy         = csi0_dst_crdt_0_tready; 
  
  assign local_crdt_port0_out.local_crdt_snk_id      = csi0_local_crdts_0_snk_id;     
  assign local_crdt_port0_out.local_crdt_src_furc_id = csi0_local_crdts_0_src_furc_id; 
  assign local_crdt_port0_out.local_crdt_flow_type   = csi_flow_t'(csi0_local_crdts_0_flow_type);   
  assign local_crdt_port0_out.local_crdt_buf_id      = csi0_local_crdts_0_buf_id;       
  assign local_crdt_port0_out.local_crdt             = csi0_local_crdts_0_data;          
  assign local_crdt_port0_out.local_crdt_vld         = csi0_local_crdts_0_vld;            
  assign csi0_local_crdts_0_rdy                      = local_crdt_port0_out.local_crdt_rdy;


  csi_uport csi_uport_inst (
  
       .clk                      (pl0_ref_clk_0), 
       .rst_n                    (pl0_rst_n),
    
       .f2csi_prcmplout          (f2csi_port0_prcmpl_in),
       .f2csi_npr_out            (f2csi_port0_npr_in),
       .csi2f_in                 (csi2f_port0_out),
       .local_crdt_in            (local_crdt_port0_out),
       .dest_crdt                (dest_crdt_port0_in),
        
       .S_AXI_UPORT_araddr       (csi_uport_axil_araddr   ),      
       .S_AXI_UPORT_arprot       (csi_uport_axil_arprot   ), 
       .S_AXI_UPORT_arready      (csi_uport_axil_arready  ), 
       .S_AXI_UPORT_arvalid      (csi_uport_axil_arvalid  ), 
       .S_AXI_UPORT_awaddr       (csi_uport_axil_awaddr   ), 
       .S_AXI_UPORT_awprot       (csi_uport_axil_awprot   ), 
       .S_AXI_UPORT_awready      (csi_uport_axil_awready  ), 
       .S_AXI_UPORT_awvalid      (csi_uport_axil_awvalid  ), 
       .S_AXI_UPORT_bready       (csi_uport_axil_bready   ), 
       .S_AXI_UPORT_bresp        (csi_uport_axil_bresp    ), 
       .S_AXI_UPORT_bvalid       (csi_uport_axil_bvalid   ), 
       .S_AXI_UPORT_rdata        (csi_uport_axil_rdata    ), 
       .S_AXI_UPORT_rready       (csi_uport_axil_rready   ), 
       .S_AXI_UPORT_rresp        (csi_uport_axil_rresp    ), 
       .S_AXI_UPORT_rvalid       (csi_uport_axil_rvalid   ), 
       .S_AXI_UPORT_wdata        (csi_uport_axil_wdata    ), 
       .S_AXI_UPORT_wready       (csi_uport_axil_wready   ), 
       .S_AXI_UPORT_wstrb        (csi_uport_axil_wstrb    ), 
       .S_AXI_UPORT_wvalid       (csi_uport_axil_wvalid   ) 
       
  );
 
  //synthesis translate off

  axi_vip_0 U_DRIVER_UB_AXI4L(
      .aclk            (pl0_ref_clk_0),
      .aresetn         (pl0_rst_n),
      //.aresetn         (sys_rst_n_c ),
      .m_axi_awaddr    (csi_uport_axil_awaddr  ),
      .m_axi_awprot    (csi_uport_axil_awprot  ),
      .m_axi_awvalid   (csi_uport_axil_awvalid ),
      .m_axi_awready   (csi_uport_axil_awready ),
      .m_axi_wdata     (csi_uport_axil_wdata   ),
      .m_axi_wstrb     (csi_uport_axil_wstrb   ),
      .m_axi_wvalid    (csi_uport_axil_wvalid  ),
      .m_axi_wready    (csi_uport_axil_wready  ),
      .m_axi_bresp     (csi_uport_axil_bresp   ),
      .m_axi_bvalid    (csi_uport_axil_bvalid  ),
      .m_axi_bready    (csi_uport_axil_bready  ),
      .m_axi_araddr    (csi_uport_axil_araddr  ),
      .m_axi_arprot    (csi_uport_axil_arprot  ),
      .m_axi_arvalid   (csi_uport_axil_arvalid ),
      .m_axi_arready   (csi_uport_axil_arready ),
      .m_axi_rdata     (csi_uport_axil_rdata   ),
      .m_axi_rresp     (csi_uport_axil_rresp   ),
      .m_axi_rvalid    (csi_uport_axil_rvalid  ),
      .m_axi_rready    (csi_uport_axil_rready  )
    );
  axi_vip_master axi_vip_master_i ();
  // synthesis translate_on

endmodule
