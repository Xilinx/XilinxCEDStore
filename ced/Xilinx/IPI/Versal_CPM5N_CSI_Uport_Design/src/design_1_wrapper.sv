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

module design_1_wrapper
import cpm5n_v1_0_5_pkg::*;
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
  
  wire [15:0]PCIE0_GT_0_grx_n;
  wire [15:0]PCIE0_GT_0_grx_p;
  wire [15:0]PCIE0_GT_0_gtx_n;
  wire [15:0]PCIE0_GT_0_gtx_p;
  
  wire cpm_bot_user_clk_0;
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
  
  wire gt_refclk0_0_clk_n;
  wire gt_refclk0_0_clk_p;
  wire pl0_ref_clk_0;

  wire pl0_rst_n;
  wire pcie0_user_clk_0;
  wire pcie0_user_reset_0;

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

  wire  [31:0]                       axi_vip_axil_araddr;
  wire  [2:0]                        axi_vip_axil_arprot;
  wire                               axi_vip_axil_arready;
  wire                               axi_vip_axil_arvalid;
  wire  [31:0]                       axi_vip_axil_awaddr;
  wire  [2:0]                        axi_vip_axil_awprot;
  wire                               axi_vip_axil_awready;
  wire                               axi_vip_axil_awvalid;
  wire                               axi_vip_axil_bready;
  wire  [1:0]                        axi_vip_axil_bresp;
  wire                               axi_vip_axil_bvalid;
  wire  [31:0]                       axi_vip_axil_rdata;
  wire                               axi_vip_axil_rready;
  wire  [1:0]                        axi_vip_axil_rresp;
  wire                               axi_vip_axil_rvalid;
  wire  [31:0]                       axi_vip_axil_wdata;
  wire                               axi_vip_axil_wready;
  wire  [3:0]                        axi_vip_axil_wstrb;
  wire                               axi_vip_axil_wvalid;
  wire                               axi_vip_en;



   
  //using 250MHz clk as PL Ref clk;
  assign cpm_bot_user_clk_0 = pl0_ref_clk_0;


  design_1 design_1_i
       (
        .PCIE0_GT_0_grx_n(PCIE0_GT_0_grx_n),
        .PCIE0_GT_0_grx_p(PCIE0_GT_0_grx_p),
        .PCIE0_GT_0_gtx_n(PCIE0_GT_0_gtx_n),
        .PCIE0_GT_0_gtx_p(PCIE0_GT_0_gtx_p),
        .gt_refclk0_0_clk_n(gt_refclk0_0_clk_n),
        .gt_refclk0_0_clk_p(gt_refclk0_0_clk_p),
       
        .cpm_bot_user_clk_0(cpm_bot_user_clk_0),
        .pl0_ref_clk_0(pl0_ref_clk_0), // pl0_ref_clk_0),
	.cdx_bot_rst_n_0(pl0_rst_n),
	.pl0_resetn_0(pl0_rst_n),
        
        .AXI4L_PL_0_araddr  (csi_uport_axil_araddr  ),
        .AXI4L_PL_0_arprot  (csi_uport_axil_arprot  ),
        .AXI4L_PL_0_arready (csi_uport_axil_arready ),
        .AXI4L_PL_0_arvalid (csi_uport_axil_arvalid ),
        .AXI4L_PL_0_awaddr  (csi_uport_axil_awaddr  ),
        .AXI4L_PL_0_awprot  (csi_uport_axil_awprot  ),
        .AXI4L_PL_0_awready (csi_uport_axil_awready ),
        .AXI4L_PL_0_awvalid (csi_uport_axil_awvalid ),
        .AXI4L_PL_0_bready  (csi_uport_axil_bready  ),
        .AXI4L_PL_0_bresp   (csi_uport_axil_bresp   ),
        .AXI4L_PL_0_bvalid  (csi_uport_axil_bvalid  ),
        .AXI4L_PL_0_rdata   (csi_uport_axil_rdata   ),
        .AXI4L_PL_0_rready  (csi_uport_axil_rready  ),
        .AXI4L_PL_0_rresp   (csi_uport_axil_rresp   ),
        .AXI4L_PL_0_rvalid  (csi_uport_axil_rvalid  ),
        .AXI4L_PL_0_wdata   (csi_uport_axil_wdata   ),
        .AXI4L_PL_0_wready  (csi_uport_axil_wready  ),
        .AXI4L_PL_0_wstrb   (csi_uport_axil_wstrb   ),
        .AXI4L_PL_0_wvalid  (csi_uport_axil_wvalid  ),

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
        .csi0_prcmpl_req1_0_vld(csi0_prcmpl_req1_0_vld)
	);
       

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
        
       .S_AXI_UPORT_araddr       (axi_vip_en ? axi_vip_axil_araddr  : csi_uport_axil_araddr   ),      
       .S_AXI_UPORT_arprot       (axi_vip_en ? axi_vip_axil_arprot  : csi_uport_axil_arprot   ), 
       //.S_AXI_UPORT_arready      (axi_vip_en ? axi_vip_axil_arready : csi_uport_axil_arready  ), 
       .S_AXI_UPORT_arready      (csi_uport_axil_arready  ), 
       .S_AXI_UPORT_arvalid      (axi_vip_en ? axi_vip_axil_arvalid : csi_uport_axil_arvalid  ), 
       .S_AXI_UPORT_awaddr       (axi_vip_en ? axi_vip_axil_awaddr  : csi_uport_axil_awaddr   ), 
       .S_AXI_UPORT_awprot       (axi_vip_en ? axi_vip_axil_awprot  : csi_uport_axil_awprot   ), 
       //.S_AXI_UPORT_awready      (axi_vip_en ? axi_vip_axil_awready : csi_uport_axil_awready  ), 
       .S_AXI_UPORT_awready      (csi_uport_axil_awready  ), 
       .S_AXI_UPORT_awvalid      (axi_vip_en ? axi_vip_axil_awvalid : csi_uport_axil_awvalid  ), 
       .S_AXI_UPORT_bready       (axi_vip_en ? axi_vip_axil_bready  : csi_uport_axil_bready   ), 
       //.S_AXI_UPORT_bresp        (axi_vip_en ? axi_vip_axil_bresp   : csi_uport_axil_bresp    ), 
       //.S_AXI_UPORT_bvalid       (axi_vip_en ? axi_vip_axil_bvalid  : csi_uport_axil_bvalid   ), 
       .S_AXI_UPORT_bresp        (csi_uport_axil_bresp    ), 
       .S_AXI_UPORT_bvalid       (csi_uport_axil_bvalid   ), 
       //.S_AXI_UPORT_rdata        (axi_vip_en ? axi_vip_axil_rdata   : csi_uport_axil_rdata    ), 
       .S_AXI_UPORT_rdata        (csi_uport_axil_rdata    ), 
       .S_AXI_UPORT_rready       (axi_vip_en ? axi_vip_axil_rready  : csi_uport_axil_rready   ), 
       //.S_AXI_UPORT_rresp        (axi_vip_en ? axi_vip_axil_rresp   : csi_uport_axil_rresp    ), 
       //.S_AXI_UPORT_rvalid       (axi_vip_en ? axi_vip_axil_rvalid  : csi_uport_axil_rvalid   ), 
       .S_AXI_UPORT_rresp        (csi_uport_axil_rresp    ), 
       .S_AXI_UPORT_rvalid       (csi_uport_axil_rvalid   ), 
       .S_AXI_UPORT_wdata        (axi_vip_en ? axi_vip_axil_wdata   : csi_uport_axil_wdata    ), 
       //.S_AXI_UPORT_wready       (axi_vip_en ? axi_vip_axil_wready  : csi_uport_axil_wready   ), 
       .S_AXI_UPORT_wready       (csi_uport_axil_wready   ), 
       .S_AXI_UPORT_wstrb        (axi_vip_en ? axi_vip_axil_wstrb   : csi_uport_axil_wstrb    ), 
       .S_AXI_UPORT_wvalid       (axi_vip_en ? axi_vip_axil_wvalid  : csi_uport_axil_wvalid   ) 
       
  );

  //synthesis translate off
  assign axi_vip_en = 1;

  axi_vip_0 U_DRIVER_UB_AXI4L(
      .aclk            (pl0_ref_clk_0),
      .aresetn         (pl0_rst_n),
      //.aresetn         (sys_rst_n_c ),
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

endmodule
