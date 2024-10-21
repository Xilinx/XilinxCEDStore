// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

`timescale 1ps / 1ps

`include "qdma_stm_defines.svh"
module design_1_wrapper #
  (
    parameter PL_LINK_CAP_MAX_LINK_WIDTH  = 8,            // 1- X1; 2 - X2; 4 - X4; 8 - X8
    parameter PL_SIM_FAST_LINK_TRAINING   = "FALSE",  // Simulation Speedup
    parameter PL_LINK_CAP_MAX_LINK_SPEED  = 4,             // 1- GEN1; 2 - GEN2; 4 - GEN3
    parameter C_DATA_WIDTH                = 512 ,
    parameter EXT_PIPE_SIM                = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.
    parameter C_ROOT_PORT                 = "FALSE",  // PCIe block is in root port mode
    parameter C_DEVICE_NUMBER             = 0,        // Device number for Root Port configurations only
    parameter AXIS_CCIX_RX_TDATA_WIDTH    = 256,
    parameter AXIS_CCIX_TX_TDATA_WIDTH    = 256,
    parameter AXIS_CCIX_RX_TUSER_WIDTH    = 46,
    parameter AXIS_CCIX_TX_TUSER_WIDTH    = 46
  )
  (
    input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  PCIE0_GT_0_grx_p,
    input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  PCIE0_GT_0_grx_n,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] PCIE0_GT_0_gtx_p,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] PCIE0_GT_0_gtx_n,
    input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  PCIE1_GT_0_grx_p,
    input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  PCIE1_GT_0_grx_n,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] PCIE1_GT_0_gtx_p,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] PCIE1_GT_0_gtx_n,
    input 					  gt_refclk0_0_clk_n,
    input 					  gt_refclk0_0_clk_p,
    input [0:0] 				  sys_clk0_0_clk_n,
    input [0:0] 				  sys_clk0_0_clk_p,
    output [5:0] 				  CH0_LPDDR4_0_0_ca_a,
    output [5:0] 				  CH0_LPDDR4_0_0_ca_b,
    output [0:0] 				  CH0_LPDDR4_0_0_ck_c_a,
    output [0:0] 				  CH0_LPDDR4_0_0_ck_c_b,
    output [0:0] 				  CH0_LPDDR4_0_0_ck_t_a,
    output [0:0] 				  CH0_LPDDR4_0_0_ck_t_b,
    output [0:0] 				  CH0_LPDDR4_0_0_cke_a,
    output [0:0] 				  CH0_LPDDR4_0_0_cke_b,
    output [0:0] 				  CH0_LPDDR4_0_0_cs_a,
    output [0:0] 				  CH0_LPDDR4_0_0_cs_b,
    inout [1:0] 				  CH0_LPDDR4_0_0_dmi_a,
    inout [1:0] 				  CH0_LPDDR4_0_0_dmi_b,
    inout [15:0] 				  CH0_LPDDR4_0_0_dq_a,
    inout [15:0] 				  CH0_LPDDR4_0_0_dq_b,
    inout [1:0] 				  CH0_LPDDR4_0_0_dqs_c_a,
    inout [1:0] 				  CH0_LPDDR4_0_0_dqs_c_b,
    inout [1:0] 				  CH0_LPDDR4_0_0_dqs_t_a,
    inout [1:0] 				  CH0_LPDDR4_0_0_dqs_t_b,
    output [0:0] 				  CH0_LPDDR4_0_0_reset_n,
    output [5:0] 				  CH1_LPDDR4_0_0_ca_a,
    output [5:0] 				  CH1_LPDDR4_0_0_ca_b,
    output [0:0] 				  CH1_LPDDR4_0_0_ck_c_a,
    output [0:0] 				  CH1_LPDDR4_0_0_ck_c_b,
    output [0:0] 				  CH1_LPDDR4_0_0_ck_t_a,
    output [0:0] 				  CH1_LPDDR4_0_0_ck_t_b,
    output [0:0] 				  CH1_LPDDR4_0_0_cke_a,
    output [0:0] 				  CH1_LPDDR4_0_0_cke_b,
    output [0:0] 				  CH1_LPDDR4_0_0_cs_a,
    output [0:0] 				  CH1_LPDDR4_0_0_cs_b,
    inout [1:0] 				  CH1_LPDDR4_0_0_dmi_a,
    inout [1:0] 				  CH1_LPDDR4_0_0_dmi_b,
    inout [15:0] 				  CH1_LPDDR4_0_0_dq_a,
    inout [15:0] 				  CH1_LPDDR4_0_0_dq_b,
    inout [1:0] 				  CH1_LPDDR4_0_0_dqs_c_a,
    inout [1:0] 				  CH1_LPDDR4_0_0_dqs_c_b,
    inout [1:0] 				  CH1_LPDDR4_0_0_dqs_t_a,
    inout [1:0] 				  CH1_LPDDR4_0_0_dqs_t_b,
    output [0:0] 				  CH1_LPDDR4_0_0_reset_n
 );

   //-----------------------------------------------------------------------------------------------------------------------


   // Local Parameters derived from user selection
   localparam integer USER_CLK_FREQ = ((PL_LINK_CAP_MAX_LINK_SPEED == 3'h4) ? 5 : 4);
   localparam TCQ = 1;
   localparam C_S_AXI_ID_WIDTH   = 4;
   localparam C_M_AXI_ID_WIDTH   = 4;
   localparam C_S_AXI_DATA_WIDTH = C_DATA_WIDTH;
   localparam C_M_AXI_DATA_WIDTH = C_DATA_WIDTH;
   localparam C_S_AXI_ADDR_WIDTH = 64;
   localparam C_M_AXI_ADDR_WIDTH = 64;
   localparam C_NUM_USR_IRQ  = 16;
   localparam CRC_WIDTH          = 32;
   localparam MULTQ_EN = 1;
   localparam C_DSC_MAGIC_EN	= 1;
   localparam C_H2C_NUM_RIDS	= 64;
   localparam C_H2C_NUM_CHNL	= MULTQ_EN ? 4 : 4;
   localparam C_C2H_NUM_CHNL	= MULTQ_EN ? 4 : 4;
   localparam C_C2H_NUM_RIDS	= 32;
   localparam C_NUM_PCIE_TAGS	= 256;
   localparam C_S_AXI_NUM_READ 	= 32;
   localparam C_S_AXI_NUM_WRITE	= 8;
   localparam C_H2C_TUSER_WIDTH	= 55;
   localparam C_C2H_TUSER_WIDTH	= 64;
   localparam C_MDMA_DSC_IN_NUM_CHNL = 3;   // only 2 interface are userd. 0 is for MM and 2 is for ST. 1 is not used
   localparam C_MAX_NUM_QUEUE    = 128;
   localparam TM_DSC_BITS = 16;

  //----------------------------------------------------------------------------------------------------------------//
  //  AXI Interface                                                                                                 //
  //----------------------------------------------------------------------------------------------------------------//
  wire user_clk;
  wire axi_aclk;
  wire axi_aresetn;

  assign user_clk = axi_aclk;

  //----------------------------------------------------------------------------------------------------------------//
  //    System(SYS) Interface                                                                                       //
  //----------------------------------------------------------------------------------------------------------------//


  //-- AXI Master Write Address Channel
  wire [C_M_AXI_ADDR_WIDTH-1:0]  m_axi_awaddr;
  wire [C_M_AXI_ID_WIDTH-1:0]    m_axi_awid;
  wire [2:0]                     m_axi_awprot;
  wire [1:0]                     m_axi_awburst;
  wire [2:0]                     m_axi_awsize;
  wire [3:0]                     m_axi_awcache;
  wire [7:0]                     m_axi_awlen;
  wire                           m_axi_awlock;
  wire                           m_axi_awvalid;
  wire                           m_axi_awready;

  //-- AXI Master Write Data Channel
  wire [C_M_AXI_DATA_WIDTH-1:0]      m_axi_wdata;
  wire [(C_M_AXI_DATA_WIDTH/8)-1:0]  m_axi_wstrb;
  wire                               m_axi_wlast;
  wire                               m_axi_wvalid;
  wire                               m_axi_wready;

  //-- AXI Master Write Response Channel
  wire                           m_axi_bvalid;
  wire                           m_axi_bready;
  wire [C_M_AXI_ID_WIDTH-1 : 0]  m_axi_bid ;
  wire [1:0]                     m_axi_bresp ;

  //-- AXI Master Read Address Channel
  wire [C_M_AXI_ID_WIDTH-1 : 0]  m_axi_arid;
  wire [C_M_AXI_ADDR_WIDTH-1:0]  m_axi_araddr;
  wire [7:0]                     m_axi_arlen;
  wire [2:0]                     m_axi_arsize;
  wire [1:0]                     m_axi_arburst;
  wire [2:0]                     m_axi_arprot;
  wire                           m_axi_arvalid;
  wire                           m_axi_arready;
  wire                           m_axi_arlock;
  wire [3:0]                     m_axi_arcache;

  //-- AXI Master Read Data Channel
  wire [C_M_AXI_ID_WIDTH-1 : 0]  m_axi_rid;
  wire [C_M_AXI_DATA_WIDTH-1:0]  m_axi_rdata;
  wire [1:0]                     m_axi_rresp;
  wire                           m_axi_rvalid;
  wire                           m_axi_rready;
  wire                           m_axi_rlast;


  //////////////////////////////////////////////////  LITE
  //-- AXI Master Write Address Channel
  (* mark_debug = "true" *)wire [31:0] dma0_m_axil_awaddr;
  (* mark_debug = "true" *)wire [2:0]  dma0_m_axil_awprot;
  (* mark_debug = "true" *)wire        dma0_m_axil_awvalid;
  (* mark_debug = "true" *)wire        dma0_m_axil_awready;

  //-- AXI Master Write Data Channel
  (* mark_debug = "true" *)wire [31:0] dma0_m_axil_wdata;
  (* mark_debug = "true" *)wire [3:0]  dma0_m_axil_wstrb;
  (* mark_debug = "true" *)wire        dma0_m_axil_wvalid;
  (* mark_debug = "true" *)wire        dma0_m_axil_wready;

  //-- AXI Master Write Response Channel
  (* mark_debug = "true" *)wire        dma0_m_axil_bvalid;
  (* mark_debug = "true" *)wire        dma0_m_axil_bready;

  //-- AXI Master Read Address Channel
  (* mark_debug = "true" *)wire [31:0] dma0_m_axil_araddr;
  (* mark_debug = "true" *)wire [2:0]  dma0_m_axil_arprot;
  (* mark_debug = "true" *)wire        dma0_m_axil_arvalid;
  (* mark_debug = "true" *)wire        dma0_m_axil_arready;

  //-- AXI Master Read Data Channel
  (* mark_debug = "true" *)wire [31:0] dma0_m_axil_rdata;
  (* mark_debug = "true" *)wire [1:0]  dma0_m_axil_rresp;
  (* mark_debug = "true" *)wire        dma0_m_axil_rvalid;
  (* mark_debug = "true" *)wire        dma0_m_axil_rready;
  (* mark_debug = "true" *)wire [1:0]  dma0_m_axil_bresp;
  //////////////////////////////////////////////////  LITE 1
  //-- AXI Master Write Address Channel
  (* mark_debug = "true" *)wire [31:0] dma1_m_axil_awaddr;
  (* mark_debug = "true" *)wire [2:0]  dma1_m_axil_awprot;
  (* mark_debug = "true" *)wire        dma1_m_axil_awvalid;
  (* mark_debug = "true" *)wire        dma1_m_axil_awready;

  //-- AXI Master Write Data Channel
  (* mark_debug = "true" *)wire [31:0] dma1_m_axil_wdata;
  (* mark_debug = "true" *)wire [3:0]  dma1_m_axil_wstrb;
  (* mark_debug = "true" *)wire        dma1_m_axil_wvalid;
  (* mark_debug = "true" *)wire        dma1_m_axil_wready;

  //-- AXI Master Write Response Channel
  (* mark_debug = "true" *)wire        dma1_m_axil_bvalid;
  (* mark_debug = "true" *)wire        dma1_m_axil_bready;

  //-- AXI Master Read Address Channel
  (* mark_debug = "true" *)wire [31:0] dma1_m_axil_araddr;
  (* mark_debug = "true" *)wire [2:0]  dma1_m_axil_arprot;
  (* mark_debug = "true" *)wire        dma1_m_axil_arvalid;
  (* mark_debug = "true" *)wire        dma1_m_axil_arready;

  //-- AXI Master Read Data Channel
  (* mark_debug = "true" *)wire [31:0] dma1_m_axil_rdata;
  (* mark_debug = "true" *)wire [1:0]  dma1_m_axil_rresp;
  (* mark_debug = "true" *)wire        dma1_m_axil_rvalid;
  (* mark_debug = "true" *)wire        dma1_m_axil_rready;
  (* mark_debug = "true" *)wire [1:0]  dma1_m_axil_bresp;

  // MDMA signals
  wire   [C_DATA_WIDTH-1:0]   dma0_m_axis_h2c_tdata;
  wire   [CRC_WIDTH-1:0]      dma0_m_axis_h2c_tcrc;
  wire   [10:0]               dma0_m_axis_h2c_tuser_qid;
  wire   [2:0]                dma0_m_axis_h2c_tuser_port_id;
  wire                        dma0_m_axis_h2c_tuser_err;
  wire   [31:0]               dma0_m_axis_h2c_tuser_mdata;
  wire   [5:0]                dma0_m_axis_h2c_tuser_mty;
  wire                        dma0_m_axis_h2c_tuser_zero_byte;
  wire                        dma0_m_axis_h2c_tvalid;
  wire                        dma0_m_axis_h2c_tready;
  wire                        dma0_m_axis_h2c_tlast;

  wire                        dma0_m_axis_h2c_tready_lpbk;
  wire                        dma0_m_axis_h2c_tready_int;

  // AXIS C2H packet wire
  (* mark_debug = "true" *)wire [C_DATA_WIDTH-1:0]     dma0_s_axis_c2h_tdata;
  (* mark_debug = "true" *)wire [CRC_WIDTH-1:0]        dma0_s_axis_c2h_tcrc;
  (* mark_debug = "true" *)wire                        dma0_s_axis_c2h_ctrl_marker;
  (* mark_debug = "true" *)wire [6:0]                  dma0_s_axis_c2h_ctrl_ecc;
  (* mark_debug = "true" *)wire [15:0]                 dma0_s_axis_c2h_ctrl_len;
  (* mark_debug = "true" *)wire [2:0]                  dma0_s_axis_c2h_ctrl_port_id;
  (* mark_debug = "true" *)wire [10:0]                 dma0_s_axis_c2h_ctrl_qid ;
  (* mark_debug = "true" *)wire                        dma0_s_axis_c2h_ctrl_has_cmpt ;
  (* mark_debug = "true" *)wire                        dma0_s_axis_c2h_tvalid;
  (* mark_debug = "true" *)wire                        dma0_s_axis_c2h_tready;
  (* mark_debug = "true" *)wire                        dma0_s_axis_c2h_tlast;
  (* mark_debug = "true" *)wire  [5:0]                 dma0_s_axis_c2h_mty;

  // AXIS C2H tuser wire
   wire [511:0] 	                dma0_s_axis_c2h_cmpt_tdata;
  (* mark_debug = "true" *)wire  [1:0]  dma0_s_axis_c2h_cmpt_size;
  (* mark_debug = "true" *)wire  [15:0] dma0_s_axis_c2h_cmpt_dpar;
  (* mark_debug = "true" *)wire         dma0_s_axis_c2h_cmpt_tvalid;
  (* mark_debug = "true" *)wire         dma0_s_axis_c2h_cmpt_tready;
  (* mark_debug = "true" *)wire [10:0]	dma0_s_axis_c2h_cmpt_ctrl_qid;
  (* mark_debug = "true" *)wire [1:0]	dma0_s_axis_c2h_cmpt_ctrl_cmpt_type;
  (* mark_debug = "true" *)wire [15:0]	dma0_s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
  (* mark_debug = "true" *)wire 	dma0_s_axis_c2h_cmpt_ctrl_marker;
  (* mark_debug = "true" *)wire 	dma0_s_axis_c2h_cmpt_ctrl_user_trig;
  (* mark_debug = "true" *)wire [2:0]	dma0_s_axis_c2h_cmpt_ctrl_col_idx;
  (* mark_debug = "true" *)wire [2:0]	dma0_s_axis_c2h_cmpt_ctrl_err_idx;

  // Descriptor Bypass Out for qdma
  (* mark_debug = "true" *)wire  [255:0] dma0_h2c_byp_out_dsc;
  (* mark_debug = "true" *)wire  [3:0]   dma0_h2c_byp_out_fmt;
  (* mark_debug = "true" *)wire  [4:0]   dma0_h2c_byp_out_cnt;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_out_st_mm;
  (* mark_debug = "true" *)wire  [10:0]  dma0_h2c_byp_out_qid;
  (* mark_debug = "true" *)wire  [1:0]   dma0_h2c_byp_out_dsc_sz;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_out_error;
  (* mark_debug = "true" *)wire  [11:0]  dma0_h2c_byp_out_func;
  (* mark_debug = "true" *)wire  [15:0]  dma0_h2c_byp_out_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma0_h2c_byp_out_port_id;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_out_vld;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_out_rdy;

  (* mark_debug = "true" *)wire  [255:0] dma0_c2h_byp_out_dsc;
  (* mark_debug = "true" *)wire  [3:0]   dma0_c2h_byp_out_fmt;
  (* mark_debug = "true" *)wire  [4:0]   dma0_c2h_byp_out_cnt;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_out_st_mm;
  (* mark_debug = "true" *)wire  [1:0]   dma0_c2h_byp_out_dsc_sz;
  (* mark_debug = "true" *)wire  [10:0]  dma0_c2h_byp_out_qid;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_out_error;
  (* mark_debug = "true" *)wire  [11:0]  dma0_c2h_byp_out_func;
  (* mark_debug = "true" *)wire  [15:0]  dma0_c2h_byp_out_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma0_c2h_byp_out_port_id;
  (* mark_debug = "true" *)wire  [6:0]   dma0_c2h_byp_out_pfch_tag;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_out_vld;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_out_rdy;


   assign c2h_byp_out_pfch_tag ='h0;
   
  // Descriptor Bypass In for qdma MM
  (* mark_debug = "true" *)wire  [63:0]  dma0_h2c_byp_in_mm_radr;
  (* mark_debug = "true" *)wire  [63:0]  dma0_h2c_byp_in_mm_wadr;
  (* mark_debug = "true" *)wire  [15:0]  dma0_h2c_byp_in_mm_len;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_mm_mrkr_req;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_mm_sdi;
  (* mark_debug = "true" *)wire  [10:0]  dma0_h2c_byp_in_mm_qid;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_mm_error;
  (* mark_debug = "true" *)wire  [11:0]  dma0_h2c_byp_in_mm_func;
  (* mark_debug = "true" *)wire  [15:0]  dma0_h2c_byp_in_mm_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma0_h2c_byp_in_mm_port_id;
  (* mark_debug = "true" *)wire  [1:0]   dma0_h2c_byp_in_mm_at;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_mm_no_dma;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_mm_vld;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_mm_rdy;

  (* mark_debug = "true" *)wire  [63:0]  dma0_c2h_byp_in_mm_radr;
  (* mark_debug = "true" *)wire  [63:0]  dma0_c2h_byp_in_mm_wadr;
  (* mark_debug = "true" *)wire  [15:0]  dma0_c2h_byp_in_mm_len;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_in_mm_mrkr_req;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_in_mm_sdi;
  (* mark_debug = "true" *)wire  [10:0]  dma0_c2h_byp_in_mm_qid;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_in_mm_error;
  (* mark_debug = "true" *)wire  [11:0]  dma0_c2h_byp_in_mm_func;
  (* mark_debug = "true" *)wire  [15:0]  dma0_c2h_byp_in_mm_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma0_c2h_byp_in_mm_port_id;
  (* mark_debug = "true" *)wire  [1:0]   dma0_c2h_byp_in_mm_at;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_in_mm_no_dma;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_in_mm_vld;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_in_mm_rdy;

  // Descriptor Bypass In for qdma ST
  (* mark_debug = "true" *)wire [63:0]   dma0_h2c_byp_in_st_addr;
  (* mark_debug = "true" *)wire [15:0]   dma0_h2c_byp_in_st_len;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_st_eop;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_st_sop;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_st_mrkr_req;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_st_sdi;
  (* mark_debug = "true" *)wire  [10:0]  dma0_h2c_byp_in_st_qid;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_st_error;
  (* mark_debug = "true" *)wire  [11:0]  dma0_h2c_byp_in_st_func;
  (* mark_debug = "true" *)wire  [15:0]  dma0_h2c_byp_in_st_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma0_h2c_byp_in_st_port_id;
  (* mark_debug = "true" *)wire  [1:0]   dma0_h2c_byp_in_st_at;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_st_no_dma;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_st_vld;
  (* mark_debug = "true" *)wire          dma0_h2c_byp_in_st_rdy;

  (* mark_debug = "true" *)wire  [63:0]  dma0_c2h_byp_in_st_csh_addr;
  (* mark_debug = "true" *)wire  [10:0]  dma0_c2h_byp_in_st_csh_qid;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_in_st_csh_error;
  (* mark_debug = "true" *)wire  [11:0]  dma0_c2h_byp_in_st_csh_func;
  (* mark_debug = "true" *)wire  [2:0]   dma0_c2h_byp_in_st_csh_port_id;
  (* mark_debug = "true" *)wire  [6:0]   dma0_c2h_byp_in_st_csh_pfch_tag;
  (* mark_debug = "true" *)wire  [1:0]   dma0_c2h_byp_in_st_csh_at;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_in_st_csh_vld;
  (* mark_debug = "true" *)wire          dma0_c2h_byp_in_st_csh_rdy;

  (* mark_debug = "true" *)wire          dma0_usr_irq_in_vld;
  (* mark_debug = "true" *)wire [10 : 0] dma0_usr_irq_in_vec;
  (* mark_debug = "true" *)wire [11 : 0] dma0_usr_irq_in_fnc;
  (* mark_debug = "true" *)wire          dma0_usr_irq_out_ack;
  (* mark_debug = "true" *)wire          dma0_usr_irq_out_fail;

  (* mark_debug = "true" *)  wire          dma0_st_rx_msg_rdy;
  (* mark_debug = "true" *)  wire          dma0_st_rx_msg_valid;
  (* mark_debug = "true" *)  wire          dma0_st_rx_msg_last;
  (* mark_debug = "true" *)  wire [31:0]   dma0_st_rx_msg_data;

  (* mark_debug = "true" *)  wire          dma0_tm_dsc_sts_vld;
  (* mark_debug = "true" *)  wire          dma0_tm_dsc_sts_qen;
  (* mark_debug = "true" *)  wire          dma0_tm_dsc_sts_byp;
  (* mark_debug = "true" *)  wire          dma0_tm_dsc_sts_dir;
  (* mark_debug = "true" *)  wire          dma0_tm_dsc_sts_mm;
  (* mark_debug = "true" *)  wire          dma0_tm_dsc_sts_error;
  (* mark_debug = "true" *)  wire  [10:0]  dma0_tm_dsc_sts_qid;
  (* mark_debug = "true" *)  wire  [15:0]  dma0_tm_dsc_sts_avl;
  (* mark_debug = "true" *)  wire          dma0_tm_dsc_sts_qinv;
  (* mark_debug = "true" *)  wire          dma0_tm_dsc_sts_irq_arm;
  (* mark_debug = "true" *)  wire          dma0_tm_dsc_sts_rdy;

  // Descriptor credit In
  wire          dma0_dsc_crdt_in_vld;
  wire          dma0_dsc_crdt_in_rdy;
  wire          dma0_dsc_crdt_in_dir;
  wire          dma0_dsc_crdt_in_fence;
  wire [10:0]   dma0_dsc_crdt_in_qid;
  wire [15:0]   dma0_dsc_crdt_in_crdt;

  // Report the DROP case
  (* mark_debug = "true" *)  wire          dma0_axis_c2h_status_drop;
  (* mark_debug = "true" *)  wire          dma0_axis_c2h_status_last;
  (* mark_debug = "true" *)  wire          dma0_axis_c2h_status_valid;
  (* mark_debug = "true" *)  wire          dma0_axis_c2h_status_cmp;
  (* mark_debug = "true" *)  wire          dma0_axis_c2h_status_error;
  (* mark_debug = "true" *)  wire [10:0]   dma0_axis_c2h_status_qid;
  (* mark_debug = "true" *)  wire [7:0]    dma0_qsts_out_op;
  (* mark_debug = "true" *)  wire [63:0]   dma0_qsts_out_data;
  (* mark_debug = "true" *)  wire [2:0]    dma0_qsts_out_port_id;
  (* mark_debug = "true" *)  wire [12:0]   dma0_qsts_out_qid;
  (* mark_debug = "true" *)  wire          dma0_qsts_out_vld;
  (* mark_debug = "true" *)  wire          dma0_qsts_out_rdy;

  // FLR
  (* mark_debug = "true" *)wire [7:0]  dma0_usr_flr_fnc;
  (* mark_debug = "true" *)wire        dma0_usr_flr_set;
  (* mark_debug = "true" *)wire        dma0_usr_flr_clr;
  (* mark_debug = "true" *)wire [7:0]  dma0_usr_flr_done_fnc;
  (* mark_debug = "true" *)wire        dma0_usr_flr_done_vld;

  // DMA1 signals
  wire   [C_DATA_WIDTH-1:0]   dma1_m_axis_h2c_tdata;
  wire   [CRC_WIDTH-1:0]      dma1_m_axis_h2c_tcrc;
  wire   [10:0]               dma1_m_axis_h2c_tuser_qid;
  wire   [2:0]                dma1_m_axis_h2c_tuser_port_id;
  wire                        dma1_m_axis_h2c_tuser_err;
  wire   [31:0]               dma1_m_axis_h2c_tuser_mdata;
  wire   [5:0]                dma1_m_axis_h2c_tuser_mty;
  wire                        dma1_m_axis_h2c_tuser_zero_byte;
  wire                        dma1_m_axis_h2c_tvalid;
  wire                        dma1_m_axis_h2c_tready;
  wire                        dma1_m_axis_h2c_tlast;

  wire                        dma1_m_axis_h2c_tready_lpbk;
  wire                        dma1_m_axis_h2c_tready_int;

  // AXIS C2H packet wire
  (* mark_debug = "true" *)wire [C_DATA_WIDTH-1:0]     dma1_s_axis_c2h_tdata;
  (* mark_debug = "true" *)wire [CRC_WIDTH-1:0]        dma1_s_axis_c2h_tcrc;
  (* mark_debug = "true" *)wire                        dma1_s_axis_c2h_ctrl_marker;
  (* mark_debug = "true" *)wire [6:0]                  dma1_s_axis_c2h_ctrl_ecc;
  (* mark_debug = "true" *)wire [15:0]                 dma1_s_axis_c2h_ctrl_len;
  (* mark_debug = "true" *)wire [2:0]                  dma1_s_axis_c2h_ctrl_port_id;
  (* mark_debug = "true" *)wire [10:0]                 dma1_s_axis_c2h_ctrl_qid ;
  (* mark_debug = "true" *)wire                        dma1_s_axis_c2h_ctrl_has_cmpt ;
  (* mark_debug = "true" *)wire                        dma1_s_axis_c2h_tvalid;
  (* mark_debug = "true" *)wire                        dma1_s_axis_c2h_tready;
  (* mark_debug = "true" *)wire                        dma1_s_axis_c2h_tlast;
  (* mark_debug = "true" *)wire  [5:0]                 dma1_s_axis_c2h_mty;

  // AXIS C2H tuser wire
   wire [511:0] 	                dma1_s_axis_c2h_cmpt_tdata;
  (* mark_debug = "true" *)wire  [1:0]  dma1_s_axis_c2h_cmpt_size;
  (* mark_debug = "true" *)wire  [15:0] dma1_s_axis_c2h_cmpt_dpar;
  (* mark_debug = "true" *)wire         dma1_s_axis_c2h_cmpt_tvalid;
  (* mark_debug = "true" *)wire         dma1_s_axis_c2h_cmpt_tready;
  (* mark_debug = "true" *)wire [10:0]	dma1_s_axis_c2h_cmpt_ctrl_qid;
  (* mark_debug = "true" *)wire [1:0]	dma1_s_axis_c2h_cmpt_ctrl_cmpt_type;
  (* mark_debug = "true" *)wire [15:0]	dma1_s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
  (* mark_debug = "true" *)wire 	dma1_s_axis_c2h_cmpt_ctrl_marker;
  (* mark_debug = "true" *)wire 	dma1_s_axis_c2h_cmpt_ctrl_user_trig;
  (* mark_debug = "true" *)wire [2:0]	dma1_s_axis_c2h_cmpt_ctrl_col_idx;
  (* mark_debug = "true" *)wire [2:0]	dma1_s_axis_c2h_cmpt_ctrl_err_idx;

  // Descriptor Bypass Out for qdma
  (* mark_debug = "true" *)wire  [255:0] dma1_h2c_byp_out_dsc;
  (* mark_debug = "true" *)wire  [3:0]   dma1_h2c_byp_out_fmt;
  (* mark_debug = "true" *)wire  [4:0]   dma1_h2c_byp_out_cnt;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_out_st_mm;
  (* mark_debug = "true" *)wire  [10:0]  dma1_h2c_byp_out_qid;
  (* mark_debug = "true" *)wire  [1:0]   dma1_h2c_byp_out_dsc_sz;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_out_error;
  (* mark_debug = "true" *)wire  [11:0]  dma1_h2c_byp_out_func;
  (* mark_debug = "true" *)wire  [15:0]  dma1_h2c_byp_out_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma1_h2c_byp_out_port_id;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_out_vld;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_out_rdy;

  (* mark_debug = "true" *)wire  [255:0] dma1_c2h_byp_out_dsc;
  (* mark_debug = "true" *)wire  [3:0]   dma1_c2h_byp_out_fmt;
  (* mark_debug = "true" *)wire  [4:0]   dma1_c2h_byp_out_cnt;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_out_st_mm;
  (* mark_debug = "true" *)wire  [1:0]   dma1_c2h_byp_out_dsc_sz;
  (* mark_debug = "true" *)wire  [10:0]  dma1_c2h_byp_out_qid;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_out_error;
  (* mark_debug = "true" *)wire  [11:0]  dma1_c2h_byp_out_func;
  (* mark_debug = "true" *)wire  [15:0]  dma1_c2h_byp_out_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma1_c2h_byp_out_port_id;
  (* mark_debug = "true" *)wire  [6:0]   dma1_c2h_byp_out_pfch_tag;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_out_vld;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_out_rdy;


   assign c2h_byp_out_pfch_tag ='h0;
   
  // Descriptor Bypass In for qdma MM
  (* mark_debug = "true" *)wire  [63:0]  dma1_h2c_byp_in_mm_radr;
  (* mark_debug = "true" *)wire  [63:0]  dma1_h2c_byp_in_mm_wadr;
  (* mark_debug = "true" *)wire  [15:0]  dma1_h2c_byp_in_mm_len;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_mm_mrkr_req;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_mm_sdi;
  (* mark_debug = "true" *)wire  [10:0]  dma1_h2c_byp_in_mm_qid;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_mm_error;
  (* mark_debug = "true" *)wire  [11:0]  dma1_h2c_byp_in_mm_func;
  (* mark_debug = "true" *)wire  [15:0]  dma1_h2c_byp_in_mm_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma1_h2c_byp_in_mm_port_id;
  (* mark_debug = "true" *)wire  [1:0]   dma1_h2c_byp_in_mm_at;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_mm_no_dma;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_mm_vld;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_mm_rdy;

  (* mark_debug = "true" *)wire  [63:0]  dma1_c2h_byp_in_mm_radr;
  (* mark_debug = "true" *)wire  [63:0]  dma1_c2h_byp_in_mm_wadr;
  (* mark_debug = "true" *)wire  [15:0]  dma1_c2h_byp_in_mm_len;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_in_mm_mrkr_req;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_in_mm_sdi;
  (* mark_debug = "true" *)wire  [10:0]  dma1_c2h_byp_in_mm_qid;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_in_mm_error;
  (* mark_debug = "true" *)wire  [11:0]  dma1_c2h_byp_in_mm_func;
  (* mark_debug = "true" *)wire  [15:0]  dma1_c2h_byp_in_mm_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma1_c2h_byp_in_mm_port_id;
  (* mark_debug = "true" *)wire  [1:0]   dma1_c2h_byp_in_mm_at;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_in_mm_no_dma;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_in_mm_vld;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_in_mm_rdy;

  // Descriptor Bypass In for qdma ST
  (* mark_debug = "true" *)wire [63:0]   dma1_h2c_byp_in_st_addr;
  (* mark_debug = "true" *)wire [15:0]   dma1_h2c_byp_in_st_len;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_st_eop;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_st_sop;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_st_mrkr_req;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_st_sdi;
  (* mark_debug = "true" *)wire  [10:0]  dma1_h2c_byp_in_st_qid;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_st_error;
  (* mark_debug = "true" *)wire  [11:0]  dma1_h2c_byp_in_st_func;
  (* mark_debug = "true" *)wire  [15:0]  dma1_h2c_byp_in_st_cidx;
  (* mark_debug = "true" *)wire  [2:0]   dma1_h2c_byp_in_st_port_id;
  (* mark_debug = "true" *)wire  [1:0]   dma1_h2c_byp_in_st_at;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_st_no_dma;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_st_vld;
  (* mark_debug = "true" *)wire          dma1_h2c_byp_in_st_rdy;

  (* mark_debug = "true" *)wire  [63:0]  dma1_c2h_byp_in_st_csh_addr;
  (* mark_debug = "true" *)wire  [10:0]  dma1_c2h_byp_in_st_csh_qid;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_in_st_csh_error;
  (* mark_debug = "true" *)wire  [11:0]  dma1_c2h_byp_in_st_csh_func;
  (* mark_debug = "true" *)wire  [2:0]   dma1_c2h_byp_in_st_csh_port_id;
  (* mark_debug = "true" *)wire  [6:0]   dma1_c2h_byp_in_st_csh_pfch_tag;
  (* mark_debug = "true" *)wire  [1:0]   dma1_c2h_byp_in_st_csh_at;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_in_st_csh_vld;
  (* mark_debug = "true" *)wire          dma1_c2h_byp_in_st_csh_rdy;

  (* mark_debug = "true" *)wire          dma1_usr_irq_in_vld;
  (* mark_debug = "true" *)wire [10 : 0] dma1_usr_irq_in_vec;
  (* mark_debug = "true" *)wire [11 : 0] dma1_usr_irq_in_fnc;
  (* mark_debug = "true" *)wire          dma1_usr_irq_out_ack;
  (* mark_debug = "true" *)wire          dma1_usr_irq_out_fail;

  (* mark_debug = "true" *)  wire          dma1_st_rx_msg_rdy;
  (* mark_debug = "true" *)  wire          dma1_st_rx_msg_valid;
  (* mark_debug = "true" *)  wire          dma1_st_rx_msg_last;
  (* mark_debug = "true" *)  wire [31:0]   dma1_st_rx_msg_data;

  (* mark_debug = "true" *)  wire          dma1_tm_dsc_sts_vld;
  (* mark_debug = "true" *)  wire          dma1_tm_dsc_sts_qen;
  (* mark_debug = "true" *)  wire          dma1_tm_dsc_sts_byp;
  (* mark_debug = "true" *)  wire          dma1_tm_dsc_sts_dir;
  (* mark_debug = "true" *)  wire          dma1_tm_dsc_sts_mm;
  (* mark_debug = "true" *)  wire          dma1_tm_dsc_sts_error;
  (* mark_debug = "true" *)  wire  [10:0]  dma1_tm_dsc_sts_qid;
  (* mark_debug = "true" *)  wire  [15:0]  dma1_tm_dsc_sts_avl;
  (* mark_debug = "true" *)  wire          dma1_tm_dsc_sts_qinv;
  (* mark_debug = "true" *)  wire          dma1_tm_dsc_sts_irq_arm;
  (* mark_debug = "true" *)  wire          dma1_tm_dsc_sts_rdy;

  // Descriptor credit In
  wire          dma1_dsc_crdt_in_vld;
  wire          dma1_dsc_crdt_in_rdy;
  wire          dma1_dsc_crdt_in_dir;
  wire          dma1_dsc_crdt_in_fence;
  wire [10:0]   dma1_dsc_crdt_in_qid;
  wire [15:0]   dma1_dsc_crdt_in_crdt;

  // Report the DROP case
  (* mark_debug = "true" *)  wire          dma1_axis_c2h_status_drop;
  (* mark_debug = "true" *)  wire          dma1_axis_c2h_status_last;
  (* mark_debug = "true" *)  wire          dma1_axis_c2h_status_valid;
  (* mark_debug = "true" *)  wire          dma1_axis_c2h_status_cmp;
  (* mark_debug = "true" *)  wire          dma1_axis_c2h_status_error;
  (* mark_debug = "true" *)  wire [10:0]   dma1_axis_c2h_status_qid;
  (* mark_debug = "true" *)  wire [7:0]    dma1_qsts_out_op;
  (* mark_debug = "true" *)  wire [63:0]   dma1_qsts_out_data;
  (* mark_debug = "true" *)  wire [2:0]    dma1_qsts_out_port_id;
  (* mark_debug = "true" *)  wire [12:0]   dma1_qsts_out_qid;
  (* mark_debug = "true" *)  wire          dma1_qsts_out_vld;
  (* mark_debug = "true" *)  wire          dma1_qsts_out_rdy;

  // FLR
  (* mark_debug = "true" *)wire [7:0]  dma1_usr_flr_fnc;
  (* mark_debug = "true" *)wire        dma1_usr_flr_set;
  (* mark_debug = "true" *)wire        dma1_usr_flr_clr;
  (* mark_debug = "true" *)wire [7:0]  dma1_usr_flr_done_fnc;
  (* mark_debug = "true" *)wire        dma1_usr_flr_done_vld;
//--------------------------------------------------------------------------
   
   wire [11:0]                        S_AXI_0_araddr;
   wire [2:0]                         S_AXI_0_arprot;
   wire                               S_AXI_0_arready;
   wire                               S_AXI_0_arvalid;
   wire [11:0]                        S_AXI_0_awaddr;
   wire [2:0]                         S_AXI_0_awprot;
   wire                               S_AXI_0_awready;
   wire                               S_AXI_0_awvalid;
   wire                               S_AXI_0_bready;
   wire [1:0]                         S_AXI_0_bresp;
   wire                               S_AXI_0_bvalid;
   wire [31:0]                        S_AXI_0_rdata;
   wire                               S_AXI_0_rready;
   wire [1:0]                         S_AXI_0_rresp;
   wire                               S_AXI_0_rvalid;
   wire [31:0]                        S_AXI_0_wdata;
   wire                               S_AXI_0_wready;
   wire [3:0]                         S_AXI_0_wstrb;
   wire                               S_AXI_0_wvalid;

   wire [11:0]                        S_AXI_1_araddr;
   wire [2:0]                         S_AXI_1_arprot;
   wire                               S_AXI_1_arready;
   wire                               S_AXI_1_arvalid;
   wire [11:0]                        S_AXI_1_awaddr;
   wire [2:0]                         S_AXI_1_awprot;
   wire                               S_AXI_1_awready;
   wire                               S_AXI_1_awvalid;
   wire                               S_AXI_1_bready;
   wire [1:0]                         S_AXI_1_bresp;
   wire                               S_AXI_1_bvalid;
   wire [31:0]                        S_AXI_1_rdata;
   wire                               S_AXI_1_rready;
   wire [1:0]                         S_AXI_1_rresp;
   wire                               S_AXI_1_rvalid;
   wire [31:0]                        S_AXI_1_wdata;
   wire                               S_AXI_1_wready;
   wire [3:0]                         S_AXI_1_wstrb;
   wire                               S_AXI_1_wvalid;
//-----------------------------------------------------------------------
   //    
  design_1 design_1_i 
       (.CH0_LPDDR4_0_0_ca_a(CH0_LPDDR4_0_0_ca_a),
        .CH0_LPDDR4_0_0_ca_b(CH0_LPDDR4_0_0_ca_b),
        .CH0_LPDDR4_0_0_ck_c_a(CH0_LPDDR4_0_0_ck_c_a),
        .CH0_LPDDR4_0_0_ck_c_b(CH0_LPDDR4_0_0_ck_c_b),
        .CH0_LPDDR4_0_0_ck_t_a(CH0_LPDDR4_0_0_ck_t_a),
        .CH0_LPDDR4_0_0_ck_t_b(CH0_LPDDR4_0_0_ck_t_b),
        .CH0_LPDDR4_0_0_cke_a(CH0_LPDDR4_0_0_cke_a),
        .CH0_LPDDR4_0_0_cke_b(CH0_LPDDR4_0_0_cke_b),
        .CH0_LPDDR4_0_0_cs_a(CH0_LPDDR4_0_0_cs_a),
        .CH0_LPDDR4_0_0_cs_b(CH0_LPDDR4_0_0_cs_b),
        .CH0_LPDDR4_0_0_dmi_a(CH0_LPDDR4_0_0_dmi_a),
        .CH0_LPDDR4_0_0_dmi_b(CH0_LPDDR4_0_0_dmi_b),
        .CH0_LPDDR4_0_0_dq_a(CH0_LPDDR4_0_0_dq_a),
        .CH0_LPDDR4_0_0_dq_b(CH0_LPDDR4_0_0_dq_b),
        .CH0_LPDDR4_0_0_dqs_c_a(CH0_LPDDR4_0_0_dqs_c_a),
        .CH0_LPDDR4_0_0_dqs_c_b(CH0_LPDDR4_0_0_dqs_c_b),
        .CH0_LPDDR4_0_0_dqs_t_a(CH0_LPDDR4_0_0_dqs_t_a),
        .CH0_LPDDR4_0_0_dqs_t_b(CH0_LPDDR4_0_0_dqs_t_b),
        .CH0_LPDDR4_0_0_reset_n(CH0_LPDDR4_0_0_reset_n),
        .CH1_LPDDR4_0_0_ca_a(CH1_LPDDR4_0_0_ca_a),
        .CH1_LPDDR4_0_0_ca_b(CH1_LPDDR4_0_0_ca_b),
        .CH1_LPDDR4_0_0_ck_c_a(CH1_LPDDR4_0_0_ck_c_a),
        .CH1_LPDDR4_0_0_ck_c_b(CH1_LPDDR4_0_0_ck_c_b),
        .CH1_LPDDR4_0_0_ck_t_a(CH1_LPDDR4_0_0_ck_t_a),
        .CH1_LPDDR4_0_0_ck_t_b(CH1_LPDDR4_0_0_ck_t_b),
        .CH1_LPDDR4_0_0_cke_a(CH1_LPDDR4_0_0_cke_a),
        .CH1_LPDDR4_0_0_cke_b(CH1_LPDDR4_0_0_cke_b),
        .CH1_LPDDR4_0_0_cs_a(CH1_LPDDR4_0_0_cs_a),
        .CH1_LPDDR4_0_0_cs_b(CH1_LPDDR4_0_0_cs_b),
        .CH1_LPDDR4_0_0_dmi_a(CH1_LPDDR4_0_0_dmi_a),
        .CH1_LPDDR4_0_0_dmi_b(CH1_LPDDR4_0_0_dmi_b),
        .CH1_LPDDR4_0_0_dq_a(CH1_LPDDR4_0_0_dq_a),
        .CH1_LPDDR4_0_0_dq_b(CH1_LPDDR4_0_0_dq_b),
        .CH1_LPDDR4_0_0_dqs_c_a(CH1_LPDDR4_0_0_dqs_c_a),
        .CH1_LPDDR4_0_0_dqs_c_b(CH1_LPDDR4_0_0_dqs_c_b),
        .CH1_LPDDR4_0_0_dqs_t_a(CH1_LPDDR4_0_0_dqs_t_a),
        .CH1_LPDDR4_0_0_dqs_t_b(CH1_LPDDR4_0_0_dqs_t_b),
        .CH1_LPDDR4_0_0_reset_n(CH1_LPDDR4_0_0_reset_n),
        .sys_clk0_0_clk_n(sys_clk0_0_clk_n),
        .sys_clk0_0_clk_p(sys_clk0_0_clk_p),

      .gt_refclk0_0_clk_n(gt_refclk0_0_clk_n),
      .gt_refclk0_0_clk_p(gt_refclk0_0_clk_p),

      .PCIE0_GT_0_grx_n(PCIE0_GT_0_grx_n),
      .PCIE0_GT_0_grx_p(PCIE0_GT_0_grx_p),
      .PCIE0_GT_0_gtx_n(PCIE0_GT_0_gtx_n),
      .PCIE0_GT_0_gtx_p(PCIE0_GT_0_gtx_p),
      .PCIE1_GT_0_grx_n(PCIE1_GT_0_grx_n),
      .PCIE1_GT_0_grx_p(PCIE1_GT_0_grx_p),
      .PCIE1_GT_0_gtx_n(PCIE1_GT_0_gtx_n),
      .PCIE1_GT_0_gtx_p(PCIE1_GT_0_gtx_p),

// Lite 0	
      .M00_AXI_0_araddr  (dma0_m_axil_araddr),
      .M00_AXI_0_arprot  (dma0_m_axil_arprot),
      .M00_AXI_0_arready (dma0_m_axil_arready),
      .M00_AXI_0_arvalid (dma0_m_axil_arvalid),
      .M00_AXI_0_awaddr  (dma0_m_axil_awaddr),
      .M00_AXI_0_awprot  (dma0_m_axil_awprot),
      .M00_AXI_0_awready (dma0_m_axil_awready),
      .M00_AXI_0_awvalid (dma0_m_axil_awvalid),
      .M00_AXI_0_bready  (dma0_m_axil_bready),
      .M00_AXI_0_bresp   (dma0_m_axil_bresp),
      .M00_AXI_0_bvalid  (dma0_m_axil_bvalid),
      .M00_AXI_0_rdata   (dma0_m_axil_rdata),
      .M00_AXI_0_rready  (dma0_m_axil_rready),
      .M00_AXI_0_rresp   (dma0_m_axil_rresp),
      .M00_AXI_0_rvalid  (dma0_m_axil_rvalid),
      .M00_AXI_0_wdata   (dma0_m_axil_wdata),
      .M00_AXI_0_wready  (dma0_m_axil_wready),
      .M00_AXI_0_wstrb   (dma0_m_axil_wstrb),
      .M00_AXI_0_wvalid  (dma0_m_axil_wvalid),

      .S_AXIL_0_araddr(S_AXI_0_araddr),
      .S_AXIL_0_arprot(S_AXI_0_arprot),
      .S_AXIL_0_arready(S_AXI_0_arready),
      .S_AXIL_0_arvalid(S_AXI_0_arvalid),
      .S_AXIL_0_awaddr(S_AXI_0_awaddr),
      .S_AXIL_0_awprot(S_AXI_0_awprot),
      .S_AXIL_0_awready(S_AXI_0_awready),
      .S_AXIL_0_awvalid(S_AXI_0_awvalid),
      .S_AXIL_0_bready(S_AXI_0_bready),
      .S_AXIL_0_bresp(S_AXI_0_bresp),
      .S_AXIL_0_bvalid(S_AXI_0_bvalid),
      .S_AXIL_0_rdata(S_AXI_0_rdata),
      .S_AXIL_0_rready(S_AXI_0_rready),
      .S_AXIL_0_rresp(S_AXI_0_rresp),
      .S_AXIL_0_rvalid(S_AXI_0_rvalid),
      .S_AXIL_0_wdata(S_AXI_0_wdata),
      .S_AXIL_0_wready(S_AXI_0_wready),
      .S_AXIL_0_wstrb(S_AXI_0_wstrb),
      .S_AXIL_0_wvalid(S_AXI_0_wvalid),

// Lite 1      
      .M01_AXI_0_araddr  (dma1_m_axil_araddr),
      .M01_AXI_0_arprot  (dma1_m_axil_arprot),
      .M01_AXI_0_arready (dma1_m_axil_arready),
      .M01_AXI_0_arvalid (dma1_m_axil_arvalid),
      .M01_AXI_0_awaddr  (dma1_m_axil_awaddr),
      .M01_AXI_0_awprot  (dma1_m_axil_awprot),
      .M01_AXI_0_awready (dma1_m_axil_awready),
      .M01_AXI_0_awvalid (dma1_m_axil_awvalid),
      .M01_AXI_0_bready  (dma1_m_axil_bready),
      .M01_AXI_0_bresp   (dma1_m_axil_bresp),
      .M01_AXI_0_bvalid  (dma1_m_axil_bvalid),
      .M01_AXI_0_rdata   (dma1_m_axil_rdata),
      .M01_AXI_0_rready  (dma1_m_axil_rready),
      .M01_AXI_0_rresp   (dma1_m_axil_rresp),
      .M01_AXI_0_rvalid  (dma1_m_axil_rvalid),
      .M01_AXI_0_wdata   (dma1_m_axil_wdata),
      .M01_AXI_0_wready  (dma1_m_axil_wready),
      .M01_AXI_0_wstrb   (dma1_m_axil_wstrb),
      .M01_AXI_0_wvalid  (dma1_m_axil_wvalid),
      
      .S_AXIL_1_araddr(S_AXI_1_araddr),
      .S_AXIL_1_arprot(S_AXI_1_arprot),
      .S_AXIL_1_arready(S_AXI_1_arready),
      .S_AXIL_1_arvalid(S_AXI_1_arvalid),
      .S_AXIL_1_awaddr(S_AXI_1_awaddr),
      .S_AXIL_1_awprot(S_AXI_1_awprot),
      .S_AXIL_1_awready(S_AXI_1_awready),
      .S_AXIL_1_awvalid(S_AXI_1_awvalid),
      .S_AXIL_1_bready(S_AXI_1_bready),
      .S_AXIL_1_bresp(S_AXI_1_bresp),
      .S_AXIL_1_bvalid(S_AXI_1_bvalid),
      .S_AXIL_1_rdata(S_AXI_1_rdata),
      .S_AXIL_1_rready(S_AXI_1_rready),
      .S_AXIL_1_rresp(S_AXI_1_rresp),
      .S_AXIL_1_rvalid(S_AXI_1_rvalid),
      .S_AXIL_1_wdata(S_AXI_1_wdata),
      .S_AXIL_1_wready(S_AXI_1_wready),
      .S_AXIL_1_wstrb(S_AXI_1_wstrb),
      .S_AXIL_1_wvalid(S_AXI_1_wvalid),


      .dma0_s_axis_c2h_0_tcrc (dma0_s_axis_c2h_tcrc ),
      .dma0_s_axis_c2h_0_mty (dma0_s_axis_c2h_mty),
      .dma0_s_axis_c2h_0_tdata (dma0_s_axis_c2h_tdata),
      .dma0_s_axis_c2h_0_tlast (dma0_s_axis_c2h_tlast),
      .dma0_s_axis_c2h_0_tready (dma0_s_axis_c2h_tready),
      .dma0_s_axis_c2h_0_tvalid (dma0_s_axis_c2h_tvalid),
      .dma0_s_axis_c2h_0_ctrl_has_cmpt(dma0_s_axis_c2h_ctrl_has_cmpt ),
      .dma0_s_axis_c2h_0_ctrl_len (dma0_s_axis_c2h_ctrl_len),
      .dma0_s_axis_c2h_0_ctrl_marker (dma0_s_axis_c2h_ctrl_marker),
      .dma0_s_axis_c2h_0_ctrl_port_id (dma0_s_axis_c2h_ctrl_port_id),
      .dma0_s_axis_c2h_0_ctrl_qid (dma0_s_axis_c2h_ctrl_qid),
      .dma0_s_axis_c2h_0_ecc (dma0_s_axis_c2h_ctrl_ecc), // TODO

      .dma0_s_axis_c2h_cmpt_0_data     (dma0_s_axis_c2h_cmpt_tdata   ),
      .dma0_s_axis_c2h_cmpt_0_dpar     (dma0_s_axis_c2h_cmpt_dpar   ),
      .dma0_s_axis_c2h_cmpt_0_tready   (dma0_s_axis_c2h_cmpt_tready ),
      .dma0_s_axis_c2h_cmpt_0_tvalid   (dma0_s_axis_c2h_cmpt_tvalid ),
      .dma0_s_axis_c2h_cmpt_0_size            (dma0_s_axis_c2h_cmpt_size                  ),
      .dma0_s_axis_c2h_cmpt_0_cmpt_type       (dma0_s_axis_c2h_cmpt_ctrl_cmpt_type ),
      .dma0_s_axis_c2h_cmpt_0_err_idx         (dma0_s_axis_c2h_cmpt_ctrl_err_idx          ),
      .dma0_s_axis_c2h_cmpt_0_marker          (dma0_s_axis_c2h_cmpt_ctrl_marker           ),
      .dma0_s_axis_c2h_cmpt_0_no_wrb_marker   (1'b0     ),
      .dma0_s_axis_c2h_cmpt_0_col_idx         (dma0_s_axis_c2h_cmpt_ctrl_col_idx          ),
      .dma0_s_axis_c2h_cmpt_0_port_id         ('b00          ),
      .dma0_s_axis_c2h_cmpt_0_qid             ({2'b0,dma0_s_axis_c2h_cmpt_ctrl_qid}       ),
      .dma0_s_axis_c2h_cmpt_0_user_trig       (dma0_s_axis_c2h_cmpt_ctrl_user_trig        ),
      .dma0_s_axis_c2h_cmpt_0_wait_pld_pkt_id (dma0_s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id  ),
 
      .dma0_axis_c2h_status_0_drop (dma0_axis_c2h_status_drop  ),
      .dma0_axis_c2h_status_0_qid  (dma0_axis_c2h_status_qid   ),
      .dma0_axis_c2h_status_0_valid(dma0_axis_c2h_status_valid ),
      .dma0_axis_c2h_status_0_status_cmp  (dma0_axis_c2h_status_cmp   ),
      .dma0_axis_c2h_status_0_error(dma0_axis_c2h_status_error ),
      .dma0_axis_c2h_status_0_last (dma0_axis_c2h_status_last  ),

      .dma0_axis_c2h_dmawr_0_cmp    (dma0_axis_c2h_dmawr_cmp), //TODO
      .dma0_axis_c2h_dmawr_0_port_id(dma0_axis_c2h_dmawr_port_id), //TODO

      .dma0_dsc_crdt_in_0_crdt     (dma0_dsc_crdt_in_crdt  ),
      .dma0_dsc_crdt_in_0_qid      (dma0_dsc_crdt_in_qid   ),
      .dma0_dsc_crdt_in_0_rdy      (dma0_dsc_crdt_in_rdy   ),
      .dma0_dsc_crdt_in_0_dir      (dma0_dsc_crdt_in_dir   ),
      .dma0_dsc_crdt_in_0_valid    (dma0_dsc_crdt_in_vld   ),
      .dma0_dsc_crdt_in_0_fence    (dma0_dsc_crdt_in_fence ),

      .dma0_m_axis_h2c_0_err       (dma0_m_axis_h2c_tuser_err      ),
      .dma0_m_axis_h2c_0_mdata     (dma0_m_axis_h2c_tuser_mdata    ),
      .dma0_m_axis_h2c_0_mty       (dma0_m_axis_h2c_tuser_mty      ),
      .dma0_m_axis_h2c_0_tcrc      (dma0_m_axis_h2c_tcrc      ),
      .dma0_m_axis_h2c_0_port_id   (dma0_m_axis_h2c_tuser_port_id  ),
      .dma0_m_axis_h2c_0_qid       (dma0_m_axis_h2c_tuser_qid      ),
      .dma0_m_axis_h2c_0_tdata     (dma0_m_axis_h2c_tdata    ),
      .dma0_m_axis_h2c_0_tlast     (dma0_m_axis_h2c_tlast    ),
      .dma0_m_axis_h2c_0_tready    (dma0_m_axis_h2c_tready   ),
      .dma0_m_axis_h2c_0_tvalid    (dma0_m_axis_h2c_tvalid   ),
      .dma0_m_axis_h2c_0_zero_byte (dma0_m_axis_h2c_tuser_zero_byte),

      .dma0_st_rx_msg_0_tdata    (dma0_st_rx_msg_data  ),
      .dma0_st_rx_msg_0_tlast    (dma0_st_rx_msg_last  ),
      .dma0_st_rx_msg_0_tready   (dma0_st_rx_msg_rdy ),
      .dma0_st_rx_msg_0_tvalid   (dma0_st_rx_msg_valid ),

      .dma0_tm_dsc_sts_0_avl     (dma0_tm_dsc_sts_avl     ),
      .dma0_tm_dsc_sts_0_byp     (dma0_tm_dsc_sts_byp     ),
      .dma0_tm_dsc_sts_0_dir     (dma0_tm_dsc_sts_dir     ),
      .dma0_tm_dsc_sts_0_error   (dma0_tm_dsc_sts_error   ),
      .dma0_tm_dsc_sts_0_irq_arm (dma0_tm_dsc_sts_irq_arm ),
      .dma0_tm_dsc_sts_0_mm      (dma0_tm_dsc_sts_mm      ),
      .dma0_tm_dsc_sts_0_port_id (dma0_tm_dsc_sts_port_id ),  // TODO : New port?
      .dma0_tm_dsc_sts_0_qen     (dma0_tm_dsc_sts_qen     ),
      .dma0_tm_dsc_sts_0_qid     (dma0_tm_dsc_sts_qid     ),
      .dma0_tm_dsc_sts_0_qinv    (dma0_tm_dsc_sts_qinv    ),
      .dma0_tm_dsc_sts_0_rdy     (dma0_tm_dsc_sts_rdy     ),
      .dma0_tm_dsc_sts_0_valid   (dma0_tm_dsc_sts_vld   ),
      .dma0_tm_dsc_sts_0_pidx    (                   ),

      .dma0_c2h_byp_out_0_cidx            (dma0_c2h_byp_out_cidx),
      .dma0_c2h_byp_out_0_dsc             (dma0_c2h_byp_out_dsc),
      .dma0_c2h_byp_out_0_dsc_sz          (dma0_c2h_byp_out_dsc_sz),
      .dma0_c2h_byp_out_0_error           (dma0_c2h_byp_out_error),
      .dma0_c2h_byp_out_0_fmt             (dma0_c2h_byp_out_fmt),
//      .dma0_c2h_byp_out_0_cnt             (dma0_c2h_byp_out_cnt),
      .dma0_c2h_byp_out_0_func            (dma0_c2h_byp_out_func),
//      .dma0_c2h_byp_out_0_pfch_tag        (dma0_c2h_byp_out_pfch_tag),
      .dma0_c2h_byp_out_0_port_id         (dma0_c2h_byp_out_port_id),
      .dma0_c2h_byp_out_0_qid             (dma0_c2h_byp_out_qid),
      .dma0_c2h_byp_out_0_ready           (dma0_c2h_byp_out_rdy),
      .dma0_c2h_byp_out_0_st_mm           (dma0_c2h_byp_out_st_mm),
      .dma0_c2h_byp_out_0_valid           (dma0_c2h_byp_out_vld),
      
      .dma0_h2c_byp_out_0_cidx            (dma0_h2c_byp_out_cidx),
      .dma0_h2c_byp_out_0_dsc             (dma0_h2c_byp_out_dsc),
      .dma0_h2c_byp_out_0_dsc_sz          (dma0_h2c_byp_out_dsc_sz),
      .dma0_h2c_byp_out_0_error           (dma0_h2c_byp_out_error),
      .dma0_h2c_byp_out_0_fmt             (dma0_h2c_byp_out_fmt),
//      .dma0_h2c_byp_out_0_cnt             (dma0_h2c_byp_out_cnt),
      .dma0_h2c_byp_out_0_func            (dma0_h2c_byp_out_func),
      .dma0_h2c_byp_out_0_port_id         (dma0_h2c_byp_out_port_id),
      .dma0_h2c_byp_out_0_qid             (dma0_h2c_byp_out_qid),
      .dma0_h2c_byp_out_0_ready           (dma0_h2c_byp_out_rdy),
      .dma0_h2c_byp_out_0_st_mm           (dma0_h2c_byp_out_st_mm),
      .dma0_h2c_byp_out_0_valid           (dma0_h2c_byp_out_vld),
      
      .dma0_c2h_byp_in_st_csh_0_addr      (dma0_c2h_byp_in_st_csh_addr),
      .dma0_c2h_byp_in_st_csh_0_error     (dma0_c2h_byp_in_st_csh_error),
      .dma0_c2h_byp_in_st_csh_0_func      (dma0_c2h_byp_in_st_csh_func),
      .dma0_c2h_byp_in_st_csh_0_pfch_tag  (dma0_c2h_byp_in_st_csh_pfch_tag),
      .dma0_c2h_byp_in_st_csh_0_port_id   (dma0_c2h_byp_in_st_csh_port_id),
      .dma0_c2h_byp_in_st_csh_0_qid       (dma0_c2h_byp_in_st_csh_qid),
      .dma0_c2h_byp_in_st_csh_0_ready     (dma0_c2h_byp_in_st_csh_rdy),
      .dma0_c2h_byp_in_st_csh_0_valid     (dma0_c2h_byp_in_st_csh_vld),
      
      .dma0_h2c_byp_in_st_0_addr          (dma0_h2c_byp_in_st_addr),
      .dma0_h2c_byp_in_st_0_cidx          (dma0_h2c_byp_in_st_cidx),
      .dma0_h2c_byp_in_st_0_eop           (dma0_h2c_byp_in_st_eop),
      .dma0_h2c_byp_in_st_0_error         (dma0_h2c_byp_in_st_error),
      .dma0_h2c_byp_in_st_0_func          (dma0_h2c_byp_in_st_func),
      .dma0_h2c_byp_in_st_0_len           (dma0_h2c_byp_in_st_len),
      .dma0_h2c_byp_in_st_0_mrkr_req      (dma0_h2c_byp_in_st_mrkr_req),
      .dma0_h2c_byp_in_st_0_no_dma        (dma0_h2c_byp_in_st_no_dma),
      .dma0_h2c_byp_in_st_0_port_id       (dma0_h2c_byp_in_st_port_id),
      .dma0_h2c_byp_in_st_0_qid           (dma0_h2c_byp_in_st_qid),
      .dma0_h2c_byp_in_st_0_ready         (dma0_h2c_byp_in_st_rdy),
      .dma0_h2c_byp_in_st_0_sdi           (dma0_h2c_byp_in_st_sdi),
      .dma0_h2c_byp_in_st_0_sop           (dma0_h2c_byp_in_st_sop),
      .dma0_h2c_byp_in_st_0_valid         (dma0_h2c_byp_in_st_vld),

      .dma0_c2h_byp_in_mm_0_0_cidx        (dma0_c2h_byp_in_mm_cidx),
      .dma0_c2h_byp_in_mm_0_0_error       (dma0_c2h_byp_in_mm_error),
      .dma0_c2h_byp_in_mm_0_0_func        (dma0_c2h_byp_in_mm_func),
      .dma0_c2h_byp_in_mm_0_0_len         (dma0_c2h_byp_in_mm_len),
      .dma0_c2h_byp_in_mm_0_0_mrkr_req    (dma0_c2h_byp_in_mm_mrkr_req),
      .dma0_c2h_byp_in_mm_0_0_port_id     (dma0_c2h_byp_in_mm_port_id),
      .dma0_c2h_byp_in_mm_0_0_qid         (dma0_c2h_byp_in_mm_qid),
      .dma0_c2h_byp_in_mm_0_0_radr        (dma0_c2h_byp_in_mm_radr),
      .dma0_c2h_byp_in_mm_0_0_ready       (dma0_c2h_byp_in_mm_rdy),
      .dma0_c2h_byp_in_mm_0_0_sdi         (dma0_c2h_byp_in_mm_sdi),
      .dma0_c2h_byp_in_mm_0_0_valid       (dma0_c2h_byp_in_mm_vld),
      .dma0_c2h_byp_in_mm_0_0_wadr        (dma0_c2h_byp_in_mm_wadr),
      .dma0_c2h_byp_in_mm_1_0_cidx        ('h0),
      .dma0_c2h_byp_in_mm_1_0_error       ('h0),
      .dma0_c2h_byp_in_mm_1_0_func        ('h0),
      .dma0_c2h_byp_in_mm_1_0_len         ('h0),
      .dma0_c2h_byp_in_mm_1_0_mrkr_req    ('h0),
      .dma0_c2h_byp_in_mm_1_0_port_id     ('h0),
      .dma0_c2h_byp_in_mm_1_0_qid         ('h0),
      .dma0_c2h_byp_in_mm_1_0_radr        ('h0),
      .dma0_c2h_byp_in_mm_1_0_ready       ( ),
      .dma0_c2h_byp_in_mm_1_0_sdi         ('h0),
      .dma0_c2h_byp_in_mm_1_0_valid       ('h0),
      .dma0_c2h_byp_in_mm_1_0_wadr        ('h0),
      .dma0_h2c_byp_in_mm_0_0_cidx        (dma0_h2c_byp_in_mm_cidx),
      .dma0_h2c_byp_in_mm_0_0_error       (dma0_h2c_byp_in_mm_error),
      .dma0_h2c_byp_in_mm_0_0_func        (dma0_h2c_byp_in_mm_func),
      .dma0_h2c_byp_in_mm_0_0_len         (dma0_h2c_byp_in_mm_len),
      .dma0_h2c_byp_in_mm_0_0_mrkr_req    (dma0_h2c_byp_in_mm_mrkr_req),
      .dma0_h2c_byp_in_mm_0_0_no_dma      (dma0_h2c_byp_in_mm_no_dma),
      .dma0_h2c_byp_in_mm_0_0_port_id     (dma0_h2c_byp_in_mm_port_id),
      .dma0_h2c_byp_in_mm_0_0_qid         (dma0_h2c_byp_in_mm_qid),
      .dma0_h2c_byp_in_mm_0_0_radr        (dma0_h2c_byp_in_mm_radr),
      .dma0_h2c_byp_in_mm_0_0_ready       (dma0_h2c_byp_in_mm_rdy),
      .dma0_h2c_byp_in_mm_0_0_sdi         (dma0_h2c_byp_in_mm_sdi),
      .dma0_h2c_byp_in_mm_0_0_valid       (dma0_h2c_byp_in_mm_vld),
      .dma0_h2c_byp_in_mm_0_0_wadr        (dma0_h2c_byp_in_mm_wadr),
      .dma0_h2c_byp_in_mm_1_0_cidx        ('h0),
      .dma0_h2c_byp_in_mm_1_0_error       ('h0),
      .dma0_h2c_byp_in_mm_1_0_func        ('h0),
      .dma0_h2c_byp_in_mm_1_0_len         ('h0),
      .dma0_h2c_byp_in_mm_1_0_mrkr_req    ('h0),
      .dma0_h2c_byp_in_mm_1_0_no_dma      ('h0),
      .dma0_h2c_byp_in_mm_1_0_port_id     ('h0),
      .dma0_h2c_byp_in_mm_1_0_qid         ('h0),
      .dma0_h2c_byp_in_mm_1_0_radr        ('h0),
      .dma0_h2c_byp_in_mm_1_0_ready       ( ),
      .dma0_h2c_byp_in_mm_1_0_sdi         ('h0),
      .dma0_h2c_byp_in_mm_1_0_valid       ('h0),
      .dma0_h2c_byp_in_mm_1_0_wadr        ('h0),

      .dma0_qsts_out_0_data     (dma0_qsts_out_data     ),
      .dma0_qsts_out_0_op       (dma0_qsts_out_op       ),
      .dma0_qsts_out_0_port_id  (dma0_qsts_out_port_id  ),
      .dma0_qsts_out_0_qid      (dma0_qsts_out_qid      ),
      .dma0_qsts_out_0_rdy      (dma0_qsts_out_rdy  ),
      .dma0_qsts_out_0_vld      (dma0_qsts_out_vld  ),

      // Mailbox IP connection input from user
      .usr_flr_0_clear         (dma0_usr_flr_clr ),
      .usr_flr_0_done_fnc      (dma0_usr_flr_done_fnc ),
      .usr_flr_0_done_vld      (dma0_usr_flr_done_vld ),
      .usr_flr_0_fnc           (dma0_usr_flr_fnc ),
      .usr_flr_0_set           (dma0_usr_flr_set ),
      .usr_irq_0_ack           (dma0_usr_irq_out_ack ),
      .usr_irq_0_fail          (dma0_usr_irq_out_fail ),
      .usr_irq_0_fnc           (dma0_usr_irq_in_fnc ),
      .usr_irq_0_valid         (dma0_usr_irq_in_vld ),
      .usr_irq_0_vec           (dma0_usr_irq_in_vec ),

      .dma0_axi_aresetn_0(dma0_axi_aresetn),
      .dma0_user_clk_0(dma0_axi_aclk),

// DMA1
      .dma1_s_axis_c2h_0_tcrc (dma1_s_axis_c2h_tcrc ),
      .dma1_s_axis_c2h_0_mty (dma1_s_axis_c2h_mty),
      .dma1_s_axis_c2h_0_tdata (dma1_s_axis_c2h_tdata),
      .dma1_s_axis_c2h_0_tlast (dma1_s_axis_c2h_tlast),
      .dma1_s_axis_c2h_0_tready (dma1_s_axis_c2h_tready),
      .dma1_s_axis_c2h_0_tvalid (dma1_s_axis_c2h_tvalid),
      .dma1_s_axis_c2h_0_ctrl_has_cmpt(dma1_s_axis_c2h_ctrl_has_cmpt ),
      .dma1_s_axis_c2h_0_ctrl_len (dma1_s_axis_c2h_ctrl_len),
      .dma1_s_axis_c2h_0_ctrl_marker (dma1_s_axis_c2h_ctrl_marker),
      .dma1_s_axis_c2h_0_ctrl_port_id (dma1_s_axis_c2h_ctrl_port_id),
      .dma1_s_axis_c2h_0_ctrl_qid (dma1_s_axis_c2h_ctrl_qid),
      .dma1_s_axis_c2h_0_ecc (dma1_s_axis_c2h_ctrl_ecc), // TODO

      .dma1_s_axis_c2h_cmpt_0_data     (dma1_s_axis_c2h_cmpt_tdata   ),
      .dma1_s_axis_c2h_cmpt_0_dpar     (dma1_s_axis_c2h_cmpt_dpar   ),
      .dma1_s_axis_c2h_cmpt_0_tready   (dma1_s_axis_c2h_cmpt_tready ),
      .dma1_s_axis_c2h_cmpt_0_tvalid   (dma1_s_axis_c2h_cmpt_tvalid ),
      .dma1_s_axis_c2h_cmpt_0_size            (dma1_s_axis_c2h_cmpt_size                  ),
      .dma1_s_axis_c2h_cmpt_0_cmpt_type       (dma1_s_axis_c2h_cmpt_ctrl_cmpt_type ),
      .dma1_s_axis_c2h_cmpt_0_err_idx         (dma1_s_axis_c2h_cmpt_ctrl_err_idx          ),
      .dma1_s_axis_c2h_cmpt_0_marker          (dma1_s_axis_c2h_cmpt_ctrl_marker           ),
      .dma1_s_axis_c2h_cmpt_0_no_wrb_marker   (1'b0     ),
      .dma1_s_axis_c2h_cmpt_0_col_idx         (dma1_s_axis_c2h_cmpt_ctrl_col_idx          ),
      .dma1_s_axis_c2h_cmpt_0_port_id         ('b00          ),
      .dma1_s_axis_c2h_cmpt_0_qid             ({2'b0,dma1_s_axis_c2h_cmpt_ctrl_qid}       ),
      .dma1_s_axis_c2h_cmpt_0_user_trig       (dma1_s_axis_c2h_cmpt_ctrl_user_trig        ),
      .dma1_s_axis_c2h_cmpt_0_wait_pld_pkt_id (dma1_s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id  ),
 
      .dma1_axis_c2h_status_0_drop (dma1_axis_c2h_status_drop  ),
      .dma1_axis_c2h_status_0_qid  (dma1_axis_c2h_status_qid   ),
      .dma1_axis_c2h_status_0_valid(dma1_axis_c2h_status_valid ),
      .dma1_axis_c2h_status_0_status_cmp  (dma1_axis_c2h_status_cmp   ),
      .dma1_axis_c2h_status_0_error(dma1_axis_c2h_status_error ),
      .dma1_axis_c2h_status_0_last (dma1_axis_c2h_status_last  ),

      .dma1_axis_c2h_dmawr_0_cmp    (dma1_axis_c2h_dmawr_cmp), //TODO
      .dma1_axis_c2h_dmawr_0_port_id(dma1_axis_c2h_dmawr_port_id), //TODO

      .dma1_dsc_crdt_in_0_crdt     (dma1_dsc_crdt_in_crdt  ),
      .dma1_dsc_crdt_in_0_qid      (dma1_dsc_crdt_in_qid   ),
      .dma1_dsc_crdt_in_0_rdy      (dma1_dsc_crdt_in_rdy   ),
      .dma1_dsc_crdt_in_0_dir      (dma1_dsc_crdt_in_dir   ),
      .dma1_dsc_crdt_in_0_valid    (dma1_dsc_crdt_in_vld   ),
      .dma1_dsc_crdt_in_0_fence    (dma1_dsc_crdt_in_fence ),

      .dma1_m_axis_h2c_0_err       (dma1_m_axis_h2c_tuser_err      ),
      .dma1_m_axis_h2c_0_mdata     (dma1_m_axis_h2c_tuser_mdata    ),
      .dma1_m_axis_h2c_0_mty       (dma1_m_axis_h2c_tuser_mty      ),
      .dma1_m_axis_h2c_0_tcrc      (dma1_m_axis_h2c_tcrc      ),
      .dma1_m_axis_h2c_0_port_id   (dma1_m_axis_h2c_tuser_port_id  ),
      .dma1_m_axis_h2c_0_qid       (dma1_m_axis_h2c_tuser_qid      ),
      .dma1_m_axis_h2c_0_tdata     (dma1_m_axis_h2c_tdata    ),
      .dma1_m_axis_h2c_0_tlast     (dma1_m_axis_h2c_tlast    ),
      .dma1_m_axis_h2c_0_tready    (dma1_m_axis_h2c_tready   ),
      .dma1_m_axis_h2c_0_tvalid    (dma1_m_axis_h2c_tvalid   ),
      .dma1_m_axis_h2c_0_zero_byte (dma1_m_axis_h2c_tuser_zero_byte),

      .dma1_st_rx_msg_0_tdata    (dma1_st_rx_msg_data  ),
      .dma1_st_rx_msg_0_tlast    (dma1_st_rx_msg_last  ),
      .dma1_st_rx_msg_0_tready   (dma1_st_rx_msg_rdy ),
      .dma1_st_rx_msg_0_tvalid   (dma1_st_rx_msg_valid ),

      .dma1_tm_dsc_sts_0_avl     (dma1_tm_dsc_sts_avl     ),
      .dma1_tm_dsc_sts_0_byp     (dma1_tm_dsc_sts_byp     ),
      .dma1_tm_dsc_sts_0_dir     (dma1_tm_dsc_sts_dir     ),
      .dma1_tm_dsc_sts_0_error   (dma1_tm_dsc_sts_error   ),
      .dma1_tm_dsc_sts_0_irq_arm (dma1_tm_dsc_sts_irq_arm ),
      .dma1_tm_dsc_sts_0_mm       (dma1_tm_dsc_sts_mm      ),
      .dma1_tm_dsc_sts_0_port_id (dma1_tm_dsc_sts_port_id ),  // TODO : New port?
      .dma1_tm_dsc_sts_0_qen     (dma1_tm_dsc_sts_qen     ),
      .dma1_tm_dsc_sts_0_qid     (dma1_tm_dsc_sts_qid     ),
      .dma1_tm_dsc_sts_0_qinv    (dma1_tm_dsc_sts_qinv    ),
      .dma1_tm_dsc_sts_0_rdy     (dma1_tm_dsc_sts_rdy     ),
      .dma1_tm_dsc_sts_0_valid   (dma1_tm_dsc_sts_vld   ),
      .dma1_tm_dsc_sts_0_pidx    (                   ),

      .dma1_c2h_byp_out_0_cidx            (dma1_c2h_byp_out_cidx),
      .dma1_c2h_byp_out_0_dsc             (dma1_c2h_byp_out_dsc),
      .dma1_c2h_byp_out_0_dsc_sz          (dma1_c2h_byp_out_dsc_sz),
      .dma1_c2h_byp_out_0_error           (dma1_c2h_byp_out_error),
      .dma1_c2h_byp_out_0_fmt             (dma1_c2h_byp_out_fmt),
//      .dma1_c2h_byp_out_0_cnt             (dma1_c2h_byp_out_cnt),
      .dma1_c2h_byp_out_0_func            (dma1_c2h_byp_out_func),
//      .dma1_c2h_byp_out_0_pfch_tag        (dma1_c2h_byp_out_pfch_tag),
      .dma1_c2h_byp_out_0_port_id         (dma1_c2h_byp_out_port_id),
      .dma1_c2h_byp_out_0_qid             (dma1_c2h_byp_out_qid),
      .dma1_c2h_byp_out_0_ready           (dma1_c2h_byp_out_rdy),
      .dma1_c2h_byp_out_0_st_mm           (dma1_c2h_byp_out_st_mm),
      .dma1_c2h_byp_out_0_valid           (dma1_c2h_byp_out_vld),
      
      .dma1_h2c_byp_out_0_cidx            (dma1_h2c_byp_out_cidx),
      .dma1_h2c_byp_out_0_dsc             (dma1_h2c_byp_out_dsc),
      .dma1_h2c_byp_out_0_dsc_sz          (dma1_h2c_byp_out_dsc_sz),
      .dma1_h2c_byp_out_0_error           (dma1_h2c_byp_out_error),
      .dma1_h2c_byp_out_0_fmt             (dma1_h2c_byp_out_fmt),
//      .dma1_h2c_byp_out_0_cnt             (dma1_h2c_byp_out_cnt),
      .dma1_h2c_byp_out_0_func            (dma1_h2c_byp_out_func),
      .dma1_h2c_byp_out_0_port_id         (dma1_h2c_byp_out_port_id),
      .dma1_h2c_byp_out_0_qid             (dma1_h2c_byp_out_qid),
      .dma1_h2c_byp_out_0_ready           (dma1_h2c_byp_out_rdy),
      .dma1_h2c_byp_out_0_st_mm           (dma1_h2c_byp_out_st_mm),
      .dma1_h2c_byp_out_0_valid           (dma1_h2c_byp_out_vld),
      
      .dma1_c2h_byp_in_st_csh_0_addr      (dma1_c2h_byp_in_st_csh_addr),
      .dma1_c2h_byp_in_st_csh_0_error     (dma1_c2h_byp_in_st_csh_error),
      .dma1_c2h_byp_in_st_csh_0_func      (dma1_c2h_byp_in_st_csh_func),
      .dma1_c2h_byp_in_st_csh_0_pfch_tag  (dma1_c2h_byp_in_st_csh_pfch_tag),
      .dma1_c2h_byp_in_st_csh_0_port_id   (dma1_c2h_byp_in_st_csh_port_id),
      .dma1_c2h_byp_in_st_csh_0_qid       (dma1_c2h_byp_in_st_csh_qid),
      .dma1_c2h_byp_in_st_csh_0_ready     (dma1_c2h_byp_in_st_csh_rdy),
      .dma1_c2h_byp_in_st_csh_0_valid     (dma1_c2h_byp_in_st_csh_vld),
      
      .dma1_h2c_byp_in_st_0_addr          (dma1_h2c_byp_in_st_addr),
      .dma1_h2c_byp_in_st_0_cidx          (dma1_h2c_byp_in_st_cidx),
      .dma1_h2c_byp_in_st_0_eop           (dma1_h2c_byp_in_st_eop),
      .dma1_h2c_byp_in_st_0_error         (dma1_h2c_byp_in_st_error),
      .dma1_h2c_byp_in_st_0_func          (dma1_h2c_byp_in_st_func),
      .dma1_h2c_byp_in_st_0_len           (dma1_h2c_byp_in_st_len),
      .dma1_h2c_byp_in_st_0_mrkr_req      (dma1_h2c_byp_in_st_mrkr_req),
      .dma1_h2c_byp_in_st_0_no_dma        (dma1_h2c_byp_in_st_no_dma),
      .dma1_h2c_byp_in_st_0_port_id       (dma1_h2c_byp_in_st_port_id),
      .dma1_h2c_byp_in_st_0_qid           (dma1_h2c_byp_in_st_qid),
      .dma1_h2c_byp_in_st_0_ready         (dma1_h2c_byp_in_st_rdy),
      .dma1_h2c_byp_in_st_0_sdi           (dma1_h2c_byp_in_st_sdi),
      .dma1_h2c_byp_in_st_0_sop           (dma1_h2c_byp_in_st_sop),
      .dma1_h2c_byp_in_st_0_valid         (dma1_h2c_byp_in_st_vld),

      .dma1_c2h_byp_in_mm_0_0_cidx        (dma1_c2h_byp_in_mm_cidx),
      .dma1_c2h_byp_in_mm_0_0_error       (dma1_c2h_byp_in_mm_error),
      .dma1_c2h_byp_in_mm_0_0_func        (dma1_c2h_byp_in_mm_func),
      .dma1_c2h_byp_in_mm_0_0_len         (dma1_c2h_byp_in_mm_len),
      .dma1_c2h_byp_in_mm_0_0_mrkr_req    (dma1_c2h_byp_in_mm_mrkr_req),
      .dma1_c2h_byp_in_mm_0_0_port_id     (dma1_c2h_byp_in_mm_port_id),
      .dma1_c2h_byp_in_mm_0_0_qid         (dma1_c2h_byp_in_mm_qid),
      .dma1_c2h_byp_in_mm_0_0_radr        (dma1_c2h_byp_in_mm_radr),
      .dma1_c2h_byp_in_mm_0_0_ready       (dma1_c2h_byp_in_mm_rdy),
      .dma1_c2h_byp_in_mm_0_0_sdi         (dma1_c2h_byp_in_mm_sdi),
      .dma1_c2h_byp_in_mm_0_0_valid       (dma1_c2h_byp_in_mm_vld),
      .dma1_c2h_byp_in_mm_0_0_wadr        (dma1_c2h_byp_in_mm_wadr),
      .dma1_c2h_byp_in_mm_1_0_cidx        ('h0),
      .dma1_c2h_byp_in_mm_1_0_error       ('h0),
      .dma1_c2h_byp_in_mm_1_0_func        ('h0),
      .dma1_c2h_byp_in_mm_1_0_len         ('h0),
      .dma1_c2h_byp_in_mm_1_0_mrkr_req    ('h0),
      .dma1_c2h_byp_in_mm_1_0_port_id     ('h0),
      .dma1_c2h_byp_in_mm_1_0_qid         ('h0),
      .dma1_c2h_byp_in_mm_1_0_radr        ('h0),
      .dma1_c2h_byp_in_mm_1_0_ready       ( ),
      .dma1_c2h_byp_in_mm_1_0_sdi         ('h0),
      .dma1_c2h_byp_in_mm_1_0_valid       ('h0),
      .dma1_c2h_byp_in_mm_1_0_wadr        ('h0),
      .dma1_h2c_byp_in_mm_0_0_cidx        (dma1_h2c_byp_in_mm_cidx),
      .dma1_h2c_byp_in_mm_0_0_error       (dma1_h2c_byp_in_mm_error),
      .dma1_h2c_byp_in_mm_0_0_func        (dma1_h2c_byp_in_mm_func),
      .dma1_h2c_byp_in_mm_0_0_len         (dma1_h2c_byp_in_mm_len),
      .dma1_h2c_byp_in_mm_0_0_mrkr_req    (dma1_h2c_byp_in_mm_mrkr_req),
      .dma1_h2c_byp_in_mm_0_0_no_dma      (dma1_h2c_byp_in_mm_no_dma),
      .dma1_h2c_byp_in_mm_0_0_port_id     (dma1_h2c_byp_in_mm_port_id),
      .dma1_h2c_byp_in_mm_0_0_qid         (dma1_h2c_byp_in_mm_qid),
      .dma1_h2c_byp_in_mm_0_0_radr        (dma1_h2c_byp_in_mm_radr),
      .dma1_h2c_byp_in_mm_0_0_ready       (dma1_h2c_byp_in_mm_rdy),
      .dma1_h2c_byp_in_mm_0_0_sdi         (dma1_h2c_byp_in_mm_sdi),
      .dma1_h2c_byp_in_mm_0_0_valid       (dma1_h2c_byp_in_mm_vld),
      .dma1_h2c_byp_in_mm_0_0_wadr        (dma1_h2c_byp_in_mm_wadr),
      .dma1_h2c_byp_in_mm_1_0_cidx        ('h0),
      .dma1_h2c_byp_in_mm_1_0_error       ('h0),
      .dma1_h2c_byp_in_mm_1_0_func        ('h0),
      .dma1_h2c_byp_in_mm_1_0_len         ('h0),
      .dma1_h2c_byp_in_mm_1_0_mrkr_req    ('h0),
      .dma1_h2c_byp_in_mm_1_0_no_dma      ('h0),
      .dma1_h2c_byp_in_mm_1_0_port_id     ('h0),
      .dma1_h2c_byp_in_mm_1_0_qid         ('h0),
      .dma1_h2c_byp_in_mm_1_0_radr        ('h0),
      .dma1_h2c_byp_in_mm_1_0_ready       ( ),
      .dma1_h2c_byp_in_mm_1_0_sdi         ('h0),
      .dma1_h2c_byp_in_mm_1_0_valid       ('h0),
      .dma1_h2c_byp_in_mm_1_0_wadr        ('h0),

      .dma1_qsts_out_0_data     (dma1_qsts_out_data     ),
      .dma1_qsts_out_0_op       (dma1_qsts_out_op       ),
      .dma1_qsts_out_0_port_id  (dma1_qsts_out_port_id  ),
      .dma1_qsts_out_0_qid      (dma1_qsts_out_qid      ),
      .dma1_qsts_out_0_rdy      (dma1_qsts_out_rdy  ),
      .dma1_qsts_out_0_vld      (dma1_qsts_out_vld  ),

      // Mailbox IP connection input from user
      .usr_flr_1_clear         (dma1_usr_flr_clr ),
      .usr_flr_1_done_fnc      (dma1_usr_flr_done_fnc ),
      .usr_flr_1_done_vld      (dma1_usr_flr_done_vld ),
      .usr_flr_1_fnc           (dma1_usr_flr_fnc ),
      .usr_flr_1_set           (dma1_usr_flr_set ),
      .usr_irq_1_ack           (dma1_usr_irq_out_ack ),
      .usr_irq_1_fail          (dma1_usr_irq_out_fail ),
      .usr_irq_1_fnc           (dma1_usr_irq_in_fnc ),
      .usr_irq_1_valid         (dma1_usr_irq_in_vld ),
      .usr_irq_1_vec           (dma1_usr_irq_in_vec ),

      .dma1_axi_aresetn_0(dma1_axi_aresetn),

      .dma0_intrfc_resetn_0 (soft_reset_n),
	
      .cpm_cor_irq_0(),
      .cpm_misc_irq_0(),
      .cpm_uncor_irq_0(),
      .cpm_irq0_0('d0),
      .cpm_irq1_0('d0)

      );


  // DMA taget application for DMA0
  qdma_app #(
    .C_M_AXI_ID_WIDTH(C_M_AXI_ID_WIDTH),
    .MAX_DATA_WIDTH(C_DATA_WIDTH),
    .TDEST_BITS(16),
    .TCQ(TCQ)
  ) dma0_qdma_app_i (
    .clk(dma0_axi_aclk),
    .user_clk(dma0_axi_aclk),

    .rst_n(dma0_axi_aresetn),
    .user_resetn(dma0_axi_aresetn),
    .sys_rst_n(dma0_axi_aresetn),

    .soft_reset_n(soft_reset_n),
    .user_lnk_up(),

      // AXI Lite Master Interface connections
      .s_axil_awaddr  (dma0_m_axil_awaddr[31:0]),
      .s_axil_awvalid (dma0_m_axil_awvalid),
      .s_axil_awready (dma0_m_axil_awready),
      .s_axil_wdata   (dma0_m_axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
      .s_axil_wstrb   (dma0_m_axil_wstrb[3:0]),
      .s_axil_wvalid  (dma0_m_axil_wvalid),
      .s_axil_wready  (dma0_m_axil_wready),
      .s_axil_bresp   (dma0_m_axil_bresp),
      .s_axil_bvalid  (dma0_m_axil_bvalid),
      .s_axil_bready  (dma0_m_axil_bready),
      .s_axil_araddr  (dma0_m_axil_araddr[31:0]),
      .s_axil_arvalid (dma0_m_axil_arvalid),
      .s_axil_arready (dma0_m_axil_arready),
      .s_axil_rdata   (dma0_m_axil_rdata),   // block ram for AXI Lite is only 31 bits
      .s_axil_rresp   (dma0_m_axil_rresp),
      .s_axil_rvalid  (dma0_m_axil_rvalid),
      .s_axil_rready  (dma0_m_axil_rready),

      .bram_axil_araddr(S_AXI_0_araddr),
      .bram_axil_arprot(S_AXI_0_arprot),
      .bram_axil_arready(S_AXI_0_arready),
      .bram_axil_arvalid(S_AXI_0_arvalid),
      .bram_axil_awaddr(S_AXI_0_awaddr),
      .bram_axil_awprot(S_AXI_0_awprot),
      .bram_axil_awready(S_AXI_0_awready),
      .bram_axil_awvalid(S_AXI_0_awvalid),
      .bram_axil_bready(S_AXI_0_bready),
      .bram_axil_bresp(S_AXI_0_bresp),
      .bram_axil_bvalid(S_AXI_0_bvalid),
      .bram_axil_rdata(S_AXI_0_rdata),
      .bram_axil_rready(S_AXI_0_rready),
      .bram_axil_rresp(S_AXI_0_rresp),
      .bram_axil_rvalid(S_AXI_0_rvalid),
      .bram_axil_wdata(S_AXI_0_wdata),
      .bram_axil_wready(S_AXI_0_wready),
      .bram_axil_wstrb(S_AXI_0_wstrb),
      .bram_axil_wvalid(S_AXI_0_wvalid),

      .c2h_byp_out_dsc      (dma0_c2h_byp_out_dsc),
      .c2h_byp_out_fmt      (dma0_c2h_byp_out_fmt),
//      .c2h_byp_out_cnt      ('d1),
      .c2h_byp_out_st_mm    (dma0_c2h_byp_out_st_mm),
      .c2h_byp_out_dsc_sz   (dma0_c2h_byp_out_dsc_sz),
      .c2h_byp_out_qid      (dma0_c2h_byp_out_qid),
      .c2h_byp_out_error    (dma0_c2h_byp_out_error),
      .c2h_byp_out_func     (dma0_c2h_byp_out_func),
      .c2h_byp_out_cidx     (dma0_c2h_byp_out_cidx),
      .c2h_byp_out_port_id  (dma0_c2h_byp_out_port_id),
      .c2h_byp_out_pfch_tag (dma0_c2h_byp_out_pfch_tag),
      .c2h_byp_out_vld      (dma0_c2h_byp_out_vld),
      .c2h_byp_out_rdy      (dma0_c2h_byp_out_rdy),

      .c2h_byp_in_mm_radr     (dma0_c2h_byp_in_mm_radr),
      .c2h_byp_in_mm_wadr     (dma0_c2h_byp_in_mm_wadr),
      .c2h_byp_in_mm_len      (dma0_c2h_byp_in_mm_len),
      .c2h_byp_in_mm_mrkr_req (dma0_c2h_byp_in_mm_mrkr_req),
      .c2h_byp_in_mm_sdi      (dma0_c2h_byp_in_mm_sdi),
      .c2h_byp_in_mm_qid      (dma0_c2h_byp_in_mm_qid),
      .c2h_byp_in_mm_error    (dma0_c2h_byp_in_mm_error),
      .c2h_byp_in_mm_func     (dma0_c2h_byp_in_mm_func),
      .c2h_byp_in_mm_cidx     (dma0_c2h_byp_in_mm_cidx),
      .c2h_byp_in_mm_port_id  (dma0_c2h_byp_in_mm_port_id),
      .c2h_byp_in_mm_at       (dma0_c2h_byp_in_mm_at),
      .c2h_byp_in_mm_no_dma   (dma0_c2h_byp_in_mm_no_dma),
      .c2h_byp_in_mm_vld      (dma0_c2h_byp_in_mm_vld),
      .c2h_byp_in_mm_rdy      (dma0_c2h_byp_in_mm_rdy),

      .c2h_byp_in_st_csh_addr    (dma0_c2h_byp_in_st_csh_addr),
      .c2h_byp_in_st_csh_qid     (dma0_c2h_byp_in_st_csh_qid),
      .c2h_byp_in_st_csh_error   (dma0_c2h_byp_in_st_csh_error),
      .c2h_byp_in_st_csh_func    (dma0_c2h_byp_in_st_csh_func),
      .c2h_byp_in_st_csh_port_id (dma0_c2h_byp_in_st_csh_port_id),
      .c2h_byp_in_st_csh_pfch_tag(dma0_c2h_byp_in_st_csh_pfch_tag),
      .c2h_byp_in_st_csh_at      (dma0_c2h_byp_in_st_csh_at),
      .c2h_byp_in_st_csh_vld     (dma0_c2h_byp_in_st_csh_vld),
      .c2h_byp_in_st_csh_rdy     (dma0_c2h_byp_in_st_csh_rdy),

      .h2c_byp_out_dsc      (dma0_h2c_byp_out_dsc),
      .h2c_byp_out_fmt      (dma0_h2c_byp_out_fmt),
//      .h2c_byp_out_cnt      ('d1),
      .h2c_byp_out_st_mm    (dma0_h2c_byp_out_st_mm),
      .h2c_byp_out_dsc_sz   (dma0_h2c_byp_out_dsc_sz),
      .h2c_byp_out_qid      (dma0_h2c_byp_out_qid),
      .h2c_byp_out_error    (dma0_h2c_byp_out_error),
      .h2c_byp_out_func     (dma0_h2c_byp_out_func),
      .h2c_byp_out_cidx     (dma0_h2c_byp_out_cidx),
      .h2c_byp_out_port_id  (dma0_h2c_byp_out_port_id),
      .h2c_byp_out_vld      (dma0_h2c_byp_out_vld),
      .h2c_byp_out_rdy      (dma0_h2c_byp_out_rdy),

      .h2c_byp_in_mm_radr     (dma0_h2c_byp_in_mm_radr),
      .h2c_byp_in_mm_wadr     (dma0_h2c_byp_in_mm_wadr),
      .h2c_byp_in_mm_len      (dma0_h2c_byp_in_mm_len),
      .h2c_byp_in_mm_mrkr_req (dma0_h2c_byp_in_mm_mrkr_req),
      .h2c_byp_in_mm_sdi      (dma0_h2c_byp_in_mm_sdi),
      .h2c_byp_in_mm_qid      (dma0_h2c_byp_in_mm_qid),
      .h2c_byp_in_mm_error    (dma0_h2c_byp_in_mm_error),
      .h2c_byp_in_mm_func     (dma0_h2c_byp_in_mm_func),
      .h2c_byp_in_mm_cidx     (dma0_h2c_byp_in_mm_cidx),
      .h2c_byp_in_mm_port_id  (dma0_h2c_byp_in_mm_port_id),
      .h2c_byp_in_mm_at       (dma0_h2c_byp_in_mm_at),
      .h2c_byp_in_mm_no_dma   (dma0_h2c_byp_in_mm_no_dma),
      .h2c_byp_in_mm_vld      (dma0_h2c_byp_in_mm_vld),
      .h2c_byp_in_mm_rdy      (dma0_h2c_byp_in_mm_rdy),

      .h2c_byp_in_st_addr     (dma0_h2c_byp_in_st_addr),
      .h2c_byp_in_st_len      (dma0_h2c_byp_in_st_len),
      .h2c_byp_in_st_eop      (dma0_h2c_byp_in_st_eop),
      .h2c_byp_in_st_sop      (dma0_h2c_byp_in_st_sop),
      .h2c_byp_in_st_mrkr_req (dma0_h2c_byp_in_st_mrkr_req),
      .h2c_byp_in_st_sdi      (dma0_h2c_byp_in_st_sdi),
      .h2c_byp_in_st_qid      (dma0_h2c_byp_in_st_qid),
      .h2c_byp_in_st_error    (dma0_h2c_byp_in_st_error),
      .h2c_byp_in_st_func     (dma0_h2c_byp_in_st_func),
      .h2c_byp_in_st_cidx     (dma0_h2c_byp_in_st_cidx),
      .h2c_byp_in_st_port_id  (dma0_h2c_byp_in_st_port_id),
      .h2c_byp_in_st_at       (dma0_h2c_byp_in_st_at),
      .h2c_byp_in_st_no_dma   (dma0_h2c_byp_in_st_no_dma),
      .h2c_byp_in_st_vld      (dma0_h2c_byp_in_st_vld),
      .h2c_byp_in_st_rdy      (dma0_h2c_byp_in_st_rdy),


    .usr_flr_fnc (dma0_usr_flr_fnc ),
    .usr_flr_set (dma0_usr_flr_set ),
    .usr_flr_clr (dma0_usr_flr_clr) ,
    .usr_flr_done_fnc (dma0_usr_flr_done_fnc),
    .usr_flr_done_vld (dma0_usr_flr_done_vld),


  .m_axis_h2c_tvalid         (dma0_m_axis_h2c_tvalid),
  .m_axis_h2c_tready         (dma0_m_axis_h2c_tready),
  .m_axis_h2c_tdata          (dma0_m_axis_h2c_tdata),
  .m_axis_h2c_tcrc           (dma0_m_axis_h2c_tcrc),
  .m_axis_h2c_tlast          (dma0_m_axis_h2c_tlast),
  .m_axis_h2c_tuser_qid      (dma0_m_axis_h2c_tuser_qid),
  .m_axis_h2c_tuser_port_id  (dma0_m_axis_h2c_tuser_port_id),
  .m_axis_h2c_tuser_err      (dma0_m_axis_h2c_tuser_err),
  .m_axis_h2c_tuser_mdata    (dma0_m_axis_h2c_tuser_mdata),
  .m_axis_h2c_tuser_mty      (dma0_m_axis_h2c_tuser_mty),
  .m_axis_h2c_tuser_zero_byte(dma0_m_axis_h2c_tuser_zero_byte),

  .s_axis_c2h_tdata          (dma0_s_axis_c2h_tdata ),
  .s_axis_c2h_tcrc           (dma0_s_axis_c2h_tcrc  ),
  .s_axis_c2h_ctrl_marker    (dma0_s_axis_c2h_ctrl_marker),
  .s_axis_c2h_ctrl_len       (dma0_s_axis_c2h_ctrl_len), // c2h_st_len,
  .s_axis_c2h_ctrl_port_id   (dma0_s_axis_c2h_ctrl_port_id),
  .s_axis_c2h_ctrl_ecc       (dma0_s_axis_c2h_ctrl_ecc),
  .s_axis_c2h_ctrl_qid       (dma0_s_axis_c2h_ctrl_qid ), // st_qid,
  .s_axis_c2h_ctrl_has_cmpt  (dma0_s_axis_c2h_ctrl_has_cmpt),   // write back is valid
  .s_axis_c2h_tvalid         (dma0_s_axis_c2h_tvalid),
  .s_axis_c2h_tready         (dma0_s_axis_c2h_tready),
  .s_axis_c2h_tlast          (dma0_s_axis_c2h_tlast ),
  .s_axis_c2h_mty            (dma0_s_axis_c2h_mty ),  // no empthy bytes at EOP

  .s_axis_c2h_cmpt_tdata               (dma0_s_axis_c2h_cmpt_tdata),
  .s_axis_c2h_cmpt_size                (dma0_s_axis_c2h_cmpt_size),
  .s_axis_c2h_cmpt_dpar                (dma0_s_axis_c2h_cmpt_dpar),
  .s_axis_c2h_cmpt_tvalid              (dma0_s_axis_c2h_cmpt_tvalid),
  .s_axis_c2h_cmpt_tready              (dma0_s_axis_c2h_cmpt_tready),
  .s_axis_c2h_cmpt_ctrl_qid            (dma0_s_axis_c2h_cmpt_ctrl_qid),
  .s_axis_c2h_cmpt_ctrl_cmpt_type      (dma0_s_axis_c2h_cmpt_ctrl_cmpt_type),
  .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id(dma0_s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
  .s_axis_c2h_cmpt_ctrl_marker         (dma0_s_axis_c2h_cmpt_ctrl_marker),
  .s_axis_c2h_cmpt_ctrl_user_trig      (dma0_s_axis_c2h_cmpt_ctrl_user_trig),
  .s_axis_c2h_cmpt_ctrl_col_idx        (dma0_s_axis_c2h_cmpt_ctrl_col_idx),
  .s_axis_c2h_cmpt_ctrl_err_idx        (dma0_s_axis_c2h_cmpt_ctrl_err_idx),

  .axis_c2h_status_drop                (dma0_axis_c2h_status_drop),
  .axis_c2h_status_valid               (dma0_axis_c2h_status_valid),
  .axis_c2h_status_qid                 (dma0_axis_c2h_status_qid),
  .axis_c2h_status_last                (dma0_axis_c2h_status_last),
  .axis_c2h_status_cmp                 (dma0_axis_c2h_status_cmp),
  .axis_c2h_status_error               (dma0_axis_c2h_status_error),
  
  .axis_c2h_dmawr_cmp                  (dma0_axis_c2h_dmawr_cmp), 
  .axis_c2h_dmawr_port_id              (dma0_axis_c2h_dmawr_port_id),

		
  .qsts_out_op      (dma0_qsts_out_op),
  .qsts_out_data    (dma0_qsts_out_data),
  .qsts_out_port_id (dma0_qsts_out_port_id),
  .qsts_out_qid     (dma0_qsts_out_qid),
  .qsts_out_vld     (dma0_qsts_out_vld),
  .qsts_out_rdy     (dma0_qsts_out_rdy),

  .usr_irq_in_vld   (dma0_usr_irq_in_vld),
  .usr_irq_in_vec   (dma0_usr_irq_in_vec),
  .usr_irq_in_fnc   (dma0_usr_irq_in_fnc),
  .usr_irq_out_ack  (dma0_usr_irq_out_ack),
  .usr_irq_out_fail (dma0_usr_irq_out_fail),

  .st_rx_msg_rdy   (dma0_st_rx_msg_rdy),
  .st_rx_msg_valid (dma0_st_rx_msg_valid),
  .st_rx_msg_last  (dma0_st_rx_msg_last),
  .st_rx_msg_data  (dma0_st_rx_msg_data),

  .tm_dsc_sts_vld     (dma0_tm_dsc_sts_vld   ),
  .tm_dsc_sts_qen     (dma0_tm_dsc_sts_qen   ),
  .tm_dsc_sts_byp     (dma0_tm_dsc_sts_byp   ),
  .tm_dsc_sts_dir     (dma0_tm_dsc_sts_dir   ),
  .tm_dsc_sts_mm      (dma0_tm_dsc_sts_mm    ),
  .tm_dsc_sts_error   (dma0_tm_dsc_sts_error ),
  .tm_dsc_sts_qid     (dma0_tm_dsc_sts_qid   ),
  .tm_dsc_sts_avl     (dma0_tm_dsc_sts_avl   ),
  .tm_dsc_sts_qinv    (dma0_tm_dsc_sts_qinv  ),
  .tm_dsc_sts_irq_arm (dma0_tm_dsc_sts_irq_arm),
  .tm_dsc_sts_rdy     (dma0_tm_dsc_sts_rdy),

  .dsc_crdt_in_vld        (dma0_dsc_crdt_in_vld),
  .dsc_crdt_in_rdy        (dma0_dsc_crdt_in_rdy),
  .dsc_crdt_in_dir        (dma0_dsc_crdt_in_dir),
  .dsc_crdt_in_fence      (dma0_dsc_crdt_in_fence),
  .dsc_crdt_in_qid        (dma0_dsc_crdt_in_qid),
  .dsc_crdt_in_crdt       (dma0_dsc_crdt_in_crdt),


      .leds()

  );


  // DMA taget application for DMA`1
  qdma_app #(
    .C_M_AXI_ID_WIDTH(C_M_AXI_ID_WIDTH),
    .MAX_DATA_WIDTH(C_DATA_WIDTH),
    .TDEST_BITS(16),
    .TCQ(TCQ)
  ) dma1_qdma_app_i (
    .clk(dma0_axi_aclk),
    .user_clk(dma0_axi_aclk),

    .rst_n(dma0_axi_aresetn),
    .user_resetn(dma0_axi_aresetn),
    .sys_rst_n(dma0_axi_aresetn),

    .soft_reset_n(),
    .user_lnk_up(),

      // AXI Lite Master Interface connections
      .s_axil_awaddr  (dma1_m_axil_awaddr[31:0]),
      .s_axil_awvalid (dma1_m_axil_awvalid),
      .s_axil_awready (dma1_m_axil_awready),
      .s_axil_wdata   (dma1_m_axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
      .s_axil_wstrb   (dma1_m_axil_wstrb[3:0]),
      .s_axil_wvalid  (dma1_m_axil_wvalid),
      .s_axil_wready  (dma1_m_axil_wready),
      .s_axil_bresp   (dma1_m_axil_bresp),
      .s_axil_bvalid  (dma1_m_axil_bvalid),
      .s_axil_bready  (dma1_m_axil_bready),
      .s_axil_araddr  (dma1_m_axil_araddr[31:0]),
      .s_axil_arvalid (dma1_m_axil_arvalid),
      .s_axil_arready (dma1_m_axil_arready),
      .s_axil_rdata   (dma1_m_axil_rdata),   // block ram for AXI Lite is only 31 bits
      .s_axil_rresp   (dma1_m_axil_rresp),
      .s_axil_rvalid  (dma1_m_axil_rvalid),
      .s_axil_rready  (dma1_m_axil_rready),

      .bram_axil_araddr(S_AXI_1_araddr),
      .bram_axil_arprot(S_AXI_1_arprot),
      .bram_axil_arready(S_AXI_1_arready),
      .bram_axil_arvalid(S_AXI_1_arvalid),
      .bram_axil_awaddr(S_AXI_1_awaddr),
      .bram_axil_awprot(S_AXI_1_awprot),
      .bram_axil_awready(S_AXI_1_awready),
      .bram_axil_awvalid(S_AXI_1_awvalid),
      .bram_axil_bready(S_AXI_1_bready),
      .bram_axil_bresp(S_AXI_1_bresp),
      .bram_axil_bvalid(S_AXI_1_bvalid),
      .bram_axil_rdata(S_AXI_1_rdata),
      .bram_axil_rready(S_AXI_1_rready),
      .bram_axil_rresp(S_AXI_1_rresp),
      .bram_axil_rvalid(S_AXI_1_rvalid),
      .bram_axil_wdata(S_AXI_1_wdata),
      .bram_axil_wready(S_AXI_1_wready),
      .bram_axil_wstrb(S_AXI_1_wstrb),
      .bram_axil_wvalid(S_AXI_1_wvalid),

      .c2h_byp_out_dsc      (dma1_c2h_byp_out_dsc),
      .c2h_byp_out_fmt      (dma1_c2h_byp_out_fmt),
//      .c2h_byp_out_cnt      ('d1),
      .c2h_byp_out_st_mm    (dma1_c2h_byp_out_st_mm),
      .c2h_byp_out_dsc_sz   (dma1_c2h_byp_out_dsc_sz),
      .c2h_byp_out_qid      (dma1_c2h_byp_out_qid),
      .c2h_byp_out_error    (dma1_c2h_byp_out_error),
      .c2h_byp_out_func     (dma1_c2h_byp_out_func),
      .c2h_byp_out_cidx     (dma1_c2h_byp_out_cidx),
      .c2h_byp_out_port_id  (dma1_c2h_byp_out_port_id),
      .c2h_byp_out_pfch_tag (dma1_c2h_byp_out_pfch_tag),
      .c2h_byp_out_vld      (dma1_c2h_byp_out_vld),
      .c2h_byp_out_rdy      (dma1_c2h_byp_out_rdy),

      .c2h_byp_in_mm_radr     (dma1_c2h_byp_in_mm_radr),
      .c2h_byp_in_mm_wadr     (dma1_c2h_byp_in_mm_wadr),
      .c2h_byp_in_mm_len      (dma1_c2h_byp_in_mm_len),
      .c2h_byp_in_mm_mrkr_req (dma1_c2h_byp_in_mm_mrkr_req),
      .c2h_byp_in_mm_sdi      (dma1_c2h_byp_in_mm_sdi),
      .c2h_byp_in_mm_qid      (dma1_c2h_byp_in_mm_qid),
      .c2h_byp_in_mm_error    (dma1_c2h_byp_in_mm_error),
      .c2h_byp_in_mm_func     (dma1_c2h_byp_in_mm_func),
      .c2h_byp_in_mm_cidx     (dma1_c2h_byp_in_mm_cidx),
      .c2h_byp_in_mm_port_id  (dma1_c2h_byp_in_mm_port_id),
      .c2h_byp_in_mm_at       (dma1_c2h_byp_in_mm_at),
      .c2h_byp_in_mm_no_dma   (dma1_c2h_byp_in_mm_no_dma),
      .c2h_byp_in_mm_vld      (dma1_c2h_byp_in_mm_vld),
      .c2h_byp_in_mm_rdy      (dma1_c2h_byp_in_mm_rdy),

      .c2h_byp_in_st_csh_addr    (dma1_c2h_byp_in_st_csh_addr),
      .c2h_byp_in_st_csh_qid     (dma1_c2h_byp_in_st_csh_qid),
      .c2h_byp_in_st_csh_error   (dma1_c2h_byp_in_st_csh_error),
      .c2h_byp_in_st_csh_func    (dma1_c2h_byp_in_st_csh_func),
      .c2h_byp_in_st_csh_port_id (dma1_c2h_byp_in_st_csh_port_id),
      .c2h_byp_in_st_csh_pfch_tag(dma1_c2h_byp_in_st_csh_pfch_tag),
      .c2h_byp_in_st_csh_at      (dma1_c2h_byp_in_st_csh_at),
      .c2h_byp_in_st_csh_vld     (dma1_c2h_byp_in_st_csh_vld),
      .c2h_byp_in_st_csh_rdy     (dma1_c2h_byp_in_st_csh_rdy),

      .h2c_byp_out_dsc      (dma1_h2c_byp_out_dsc),
      .h2c_byp_out_fmt      (dma1_h2c_byp_out_fmt),
//      .h2c_byp_out_cnt      ('d1),
      .h2c_byp_out_st_mm    (dma1_h2c_byp_out_st_mm),
      .h2c_byp_out_dsc_sz   (dma1_h2c_byp_out_dsc_sz),
      .h2c_byp_out_qid      (dma1_h2c_byp_out_qid),
      .h2c_byp_out_error    (dma1_h2c_byp_out_error),
      .h2c_byp_out_func     (dma1_h2c_byp_out_func),
      .h2c_byp_out_cidx     (dma1_h2c_byp_out_cidx),
      .h2c_byp_out_port_id  (dma1_h2c_byp_out_port_id),
      .h2c_byp_out_vld      (dma1_h2c_byp_out_vld),
      .h2c_byp_out_rdy      (dma1_h2c_byp_out_rdy),

      .h2c_byp_in_mm_radr     (dma1_h2c_byp_in_mm_radr),
      .h2c_byp_in_mm_wadr     (dma1_h2c_byp_in_mm_wadr),
      .h2c_byp_in_mm_len      (dma1_h2c_byp_in_mm_len),
      .h2c_byp_in_mm_mrkr_req (dma1_h2c_byp_in_mm_mrkr_req),
      .h2c_byp_in_mm_sdi      (dma1_h2c_byp_in_mm_sdi),
      .h2c_byp_in_mm_qid      (dma1_h2c_byp_in_mm_qid),
      .h2c_byp_in_mm_error    (dma1_h2c_byp_in_mm_error),
      .h2c_byp_in_mm_func     (dma1_h2c_byp_in_mm_func),
      .h2c_byp_in_mm_cidx     (dma1_h2c_byp_in_mm_cidx),
      .h2c_byp_in_mm_port_id  (dma1_h2c_byp_in_mm_port_id),
      .h2c_byp_in_mm_at       (dma1_h2c_byp_in_mm_at),
      .h2c_byp_in_mm_no_dma   (dma1_h2c_byp_in_mm_no_dma),
      .h2c_byp_in_mm_vld      (dma1_h2c_byp_in_mm_vld),
      .h2c_byp_in_mm_rdy      (dma1_h2c_byp_in_mm_rdy),

      .h2c_byp_in_st_addr     (dma1_h2c_byp_in_st_addr),
      .h2c_byp_in_st_len      (dma1_h2c_byp_in_st_len),
      .h2c_byp_in_st_eop      (dma1_h2c_byp_in_st_eop),
      .h2c_byp_in_st_sop      (dma1_h2c_byp_in_st_sop),
      .h2c_byp_in_st_mrkr_req (dma1_h2c_byp_in_st_mrkr_req),
      .h2c_byp_in_st_sdi      (dma1_h2c_byp_in_st_sdi),
      .h2c_byp_in_st_qid      (dma1_h2c_byp_in_st_qid),
      .h2c_byp_in_st_error    (dma1_h2c_byp_in_st_error),
      .h2c_byp_in_st_func     (dma1_h2c_byp_in_st_func),
      .h2c_byp_in_st_cidx     (dma1_h2c_byp_in_st_cidx),
      .h2c_byp_in_st_port_id  (dma1_h2c_byp_in_st_port_id),
      .h2c_byp_in_st_at       (dma1_h2c_byp_in_st_at),
      .h2c_byp_in_st_no_dma   (dma1_h2c_byp_in_st_no_dma),
      .h2c_byp_in_st_vld      (dma1_h2c_byp_in_st_vld),
      .h2c_byp_in_st_rdy      (dma1_h2c_byp_in_st_rdy),


    .usr_flr_fnc (dma1_usr_flr_fnc ),
    .usr_flr_set (dma1_usr_flr_set ),
    .usr_flr_clr (dma1_usr_flr_clr) ,
    .usr_flr_done_fnc (dma1_usr_flr_done_fnc),
    .usr_flr_done_vld (dma1_usr_flr_done_vld),


  .m_axis_h2c_tvalid         (dma1_m_axis_h2c_tvalid),
  .m_axis_h2c_tready         (dma1_m_axis_h2c_tready),
  .m_axis_h2c_tdata          (dma1_m_axis_h2c_tdata),
  .m_axis_h2c_tcrc           (dma1_m_axis_h2c_tcrc),
  .m_axis_h2c_tlast          (dma1_m_axis_h2c_tlast),
  .m_axis_h2c_tuser_qid      (dma1_m_axis_h2c_tuser_qid),
  .m_axis_h2c_tuser_port_id  (dma1_m_axis_h2c_tuser_port_id),
  .m_axis_h2c_tuser_err      (dma1_m_axis_h2c_tuser_err),
  .m_axis_h2c_tuser_mdata    (dma1_m_axis_h2c_tuser_mdata),
  .m_axis_h2c_tuser_mty      (dma1_m_axis_h2c_tuser_mty),
  .m_axis_h2c_tuser_zero_byte(dma1_m_axis_h2c_tuser_zero_byte),

  .s_axis_c2h_tdata          (dma1_s_axis_c2h_tdata ),
  .s_axis_c2h_tcrc           (dma1_s_axis_c2h_tcrc  ),
  .s_axis_c2h_ctrl_marker    (dma1_s_axis_c2h_ctrl_marker),
  .s_axis_c2h_ctrl_len       (dma1_s_axis_c2h_ctrl_len), // c2h_st_len,
  .s_axis_c2h_ctrl_port_id   (dma1_s_axis_c2h_ctrl_port_id),
  .s_axis_c2h_ctrl_ecc       (dma1_s_axis_c2h_ctrl_ecc),
  .s_axis_c2h_ctrl_qid       (dma1_s_axis_c2h_ctrl_qid ), // st_qid,
  .s_axis_c2h_ctrl_has_cmpt  (dma1_s_axis_c2h_ctrl_has_cmpt),   // write back is valid
  .s_axis_c2h_tvalid         (dma1_s_axis_c2h_tvalid),
  .s_axis_c2h_tready         (dma1_s_axis_c2h_tready),
  .s_axis_c2h_tlast          (dma1_s_axis_c2h_tlast ),
  .s_axis_c2h_mty            (dma1_s_axis_c2h_mty ),  // no empthy bytes at EOP

  .s_axis_c2h_cmpt_tdata               (dma1_s_axis_c2h_cmpt_tdata),
  .s_axis_c2h_cmpt_size                (dma1_s_axis_c2h_cmpt_size),
  .s_axis_c2h_cmpt_dpar                (dma1_s_axis_c2h_cmpt_dpar),
  .s_axis_c2h_cmpt_tvalid              (dma1_s_axis_c2h_cmpt_tvalid),
  .s_axis_c2h_cmpt_tready              (dma1_s_axis_c2h_cmpt_tready),
  .s_axis_c2h_cmpt_ctrl_qid            (dma1_s_axis_c2h_cmpt_ctrl_qid),
  .s_axis_c2h_cmpt_ctrl_cmpt_type      (dma1_s_axis_c2h_cmpt_ctrl_cmpt_type),
  .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id(dma1_s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
  .s_axis_c2h_cmpt_ctrl_marker         (dma1_s_axis_c2h_cmpt_ctrl_marker),
  .s_axis_c2h_cmpt_ctrl_user_trig      (dma1_s_axis_c2h_cmpt_ctrl_user_trig),
  .s_axis_c2h_cmpt_ctrl_col_idx        (dma1_s_axis_c2h_cmpt_ctrl_col_idx),
  .s_axis_c2h_cmpt_ctrl_err_idx        (dma1_s_axis_c2h_cmpt_ctrl_err_idx),

  .axis_c2h_status_drop                (dma1_axis_c2h_status_drop),
  .axis_c2h_status_valid               (dma1_axis_c2h_status_valid),
  .axis_c2h_status_qid                 (dma1_axis_c2h_status_qid),
  .axis_c2h_status_last                (dma1_axis_c2h_status_last),
  .axis_c2h_status_cmp                 (dma1_axis_c2h_status_cmp),
  .axis_c2h_status_error               (dma1_axis_c2h_status_error),
  
  .axis_c2h_dmawr_cmp                  (dma1_axis_c2h_dmawr_cmp), 
  .axis_c2h_dmawr_port_id              (dma1_axis_c2h_dmawr_port_id),

		
  .qsts_out_op      (dma1_qsts_out_op),
  .qsts_out_data    (dma1_qsts_out_data),
  .qsts_out_port_id (dma1_qsts_out_port_id),
  .qsts_out_qid     (dma1_qsts_out_qid),
  .qsts_out_vld     (dma1_qsts_out_vld),
  .qsts_out_rdy     (dma1_qsts_out_rdy),

  .usr_irq_in_vld   (dma1_usr_irq_in_vld),
  .usr_irq_in_vec   (dma1_usr_irq_in_vec),
  .usr_irq_in_fnc   (dma1_usr_irq_in_fnc),
  .usr_irq_out_ack  (dma1_usr_irq_out_ack),
  .usr_irq_out_fail (dma1_usr_irq_out_fail),

  .st_rx_msg_rdy   (dma1_st_rx_msg_rdy),
  .st_rx_msg_valid (dma1_st_rx_msg_valid),
  .st_rx_msg_last  (dma1_st_rx_msg_last),
  .st_rx_msg_data  (dma1_st_rx_msg_data),

  .tm_dsc_sts_vld     (dma1_tm_dsc_sts_vld   ),
  .tm_dsc_sts_qen     (dma1_tm_dsc_sts_qen   ),
  .tm_dsc_sts_byp     (dma1_tm_dsc_sts_byp   ),
  .tm_dsc_sts_dir     (dma1_tm_dsc_sts_dir   ),
  .tm_dsc_sts_mm      (dma1_tm_dsc_sts_mm    ),
  .tm_dsc_sts_error   (dma1_tm_dsc_sts_error ),
  .tm_dsc_sts_qid     (dma1_tm_dsc_sts_qid   ),
  .tm_dsc_sts_avl     (dma1_tm_dsc_sts_avl   ),
  .tm_dsc_sts_qinv    (dma1_tm_dsc_sts_qinv  ),
  .tm_dsc_sts_irq_arm (dma1_tm_dsc_sts_irq_arm),
  .tm_dsc_sts_rdy     (dma1_tm_dsc_sts_rdy),

  .dsc_crdt_in_vld        (dma1_dsc_crdt_in_vld),
  .dsc_crdt_in_rdy        (dma1_dsc_crdt_in_rdy),
  .dsc_crdt_in_dir        (dma1_dsc_crdt_in_dir),
  .dsc_crdt_in_fence      (dma1_dsc_crdt_in_fence),
  .dsc_crdt_in_qid        (dma1_dsc_crdt_in_qid),
  .dsc_crdt_in_crdt       (dma1_dsc_crdt_in_crdt),

      .leds()

  );

endmodule

