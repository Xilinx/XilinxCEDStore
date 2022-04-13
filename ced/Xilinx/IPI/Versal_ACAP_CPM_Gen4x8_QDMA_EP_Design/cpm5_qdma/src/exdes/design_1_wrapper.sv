//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : The Xilinx PCI Express DMA 
// File       : xilinx_qdma_pcie_ep.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
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
    input 					  gt_refclk0_0_clk_n,
    input 					  gt_refclk0_0_clk_p,
    input [0:0] 				  sys_clk0_0_clk_n,
    input [0:0] 				  sys_clk0_0_clk_p,

    output [5:0]                                  ch0_lpddr4_trip1_ca_a,
    output [5:0]                                  ch0_lpddr4_trip1_ca_b,
    output                                        ch0_lpddr4_trip1_ck_c_a,
    output                                        ch0_lpddr4_trip1_ck_c_b,
    output                                        ch0_lpddr4_trip1_ck_t_a,
    output                                        ch0_lpddr4_trip1_ck_t_b,
    output                                        ch0_lpddr4_trip1_cke_a,
    output                                        ch0_lpddr4_trip1_cke_b,
    output                                        ch0_lpddr4_trip1_cs_a,
    output                                        ch0_lpddr4_trip1_cs_b,
    inout [1:0]                                   ch0_lpddr4_trip1_dmi_a,
    inout [1:0]                                   ch0_lpddr4_trip1_dmi_b,
    inout [15:0]                                  ch0_lpddr4_trip1_dq_a,
    inout [15:0]                                  ch0_lpddr4_trip1_dq_b,
    inout [1:0]                                   ch0_lpddr4_trip1_dqs_c_a,
    inout [1:0]                                   ch0_lpddr4_trip1_dqs_c_b,
    inout [1:0]                                   ch0_lpddr4_trip1_dqs_t_a,
    inout [1:0]                                   ch0_lpddr4_trip1_dqs_t_b,
    output                                        ch0_lpddr4_trip1_reset_n,
    output [5:0]                                  ch0_lpddr4_trip2_ca_a,
    output [5:0]                                  ch0_lpddr4_trip2_ca_b,
    output                                        ch0_lpddr4_trip2_ck_c_a,
    output                                        ch0_lpddr4_trip2_ck_c_b,
    output                                        ch0_lpddr4_trip2_ck_t_a,
    output                                        ch0_lpddr4_trip2_ck_t_b,
    output                                        ch0_lpddr4_trip2_cke_a,
    output                                        ch0_lpddr4_trip2_cke_b,
    output                                        ch0_lpddr4_trip2_cs_a,
    output                                        ch0_lpddr4_trip2_cs_b,
    inout [1:0]                                   ch0_lpddr4_trip2_dmi_a,
    inout [1:0]                                   ch0_lpddr4_trip2_dmi_b,
    inout [15:0]                                  ch0_lpddr4_trip2_dq_a,
    inout [15:0]                                  ch0_lpddr4_trip2_dq_b,
    inout [1:0]                                   ch0_lpddr4_trip2_dqs_c_a,
    inout [1:0]                                   ch0_lpddr4_trip2_dqs_c_b,
    inout [1:0]                                   ch0_lpddr4_trip2_dqs_t_a,
    inout [1:0]                                   ch0_lpddr4_trip2_dqs_t_b,
    output                                        ch0_lpddr4_trip2_reset_n,
    output [5:0]                                  ch1_lpddr4_trip1_ca_a,
    output [5:0]                                  ch1_lpddr4_trip1_ca_b,
    output                                        ch1_lpddr4_trip1_ck_c_a,
    output                                        ch1_lpddr4_trip1_ck_c_b,
    output                                        ch1_lpddr4_trip1_ck_t_a,
    output                                        ch1_lpddr4_trip1_ck_t_b,
    output                                        ch1_lpddr4_trip1_cke_a,
    output                                        ch1_lpddr4_trip1_cke_b,
    output                                        ch1_lpddr4_trip1_cs_a,
    output                                        ch1_lpddr4_trip1_cs_b,
    inout [1:0]                                   ch1_lpddr4_trip1_dmi_a,
    inout [1:0]                                   ch1_lpddr4_trip1_dmi_b,
    inout [15:0]                                  ch1_lpddr4_trip1_dq_a,
    inout [15:0]                                  ch1_lpddr4_trip1_dq_b,
    inout [1:0]                                   ch1_lpddr4_trip1_dqs_c_a,
    inout [1:0]                                   ch1_lpddr4_trip1_dqs_c_b,
    inout [1:0]                                   ch1_lpddr4_trip1_dqs_t_a,
    inout [1:0]                                   ch1_lpddr4_trip1_dqs_t_b,
    output                                        ch1_lpddr4_trip1_reset_n,
    output [5:0]                                  ch1_lpddr4_trip2_ca_a,
    output [5:0]                                  ch1_lpddr4_trip2_ca_b,
    output                                        ch1_lpddr4_trip2_ck_c_a,
    output                                        ch1_lpddr4_trip2_ck_c_b,
    output                                        ch1_lpddr4_trip2_ck_t_a,
    output                                        ch1_lpddr4_trip2_ck_t_b,
    output                                        ch1_lpddr4_trip2_cke_a,
    output                                        ch1_lpddr4_trip2_cke_b,
    output                                        ch1_lpddr4_trip2_cs_a,
    output                                        ch1_lpddr4_trip2_cs_b,
    inout [1:0]                                   ch1_lpddr4_trip2_dmi_a,
    inout [1:0]                                   ch1_lpddr4_trip2_dmi_b,
    inout [15:0]                                  ch1_lpddr4_trip2_dq_a,
    inout [15:0]                                  ch1_lpddr4_trip2_dq_b,
    inout [1:0]                                   ch1_lpddr4_trip2_dqs_c_a,
    inout [1:0]                                   ch1_lpddr4_trip2_dqs_c_b,
    inout [1:0]                                   ch1_lpddr4_trip2_dqs_t_a,
    inout [1:0]                                   ch1_lpddr4_trip2_dqs_t_b,
    output                                        ch1_lpddr4_trip2_reset_n,

    input                                         lpddr4_clk2_clk_n,
    input                                         lpddr4_clk2_clk_p

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
  wire user_lnk_up;

  //----------------------------------------------------------------------------------------------------------------//
  //  AXI Interface                                                                                                 //
  //----------------------------------------------------------------------------------------------------------------//
  wire user_clk;
  wire axi_aclk;
  wire axi_aresetn;

  wire user_clk_dma_in;
  wire user_reset_dma_in;
  wire user_reset_dma_out;
  // Wires for Avery HOT/WARM and COLD RESET
  wire avy_sys_rst_n_c;
  wire avy_cfg_hot_reset_out;
  reg  avy_sys_rst_n_g;
  reg  avy_cfg_hot_reset_out_g;

  assign  avy_sys_rst_n_c = avy_sys_rst_n_g;
  assign  avy_cfg_hot_reset_out = avy_cfg_hot_reset_out_g;

  initial begin
    avy_sys_rst_n_g = 1;
    avy_cfg_hot_reset_out_g =0;
  end

  assign user_clk = axi_aclk;






  //----------------------------------------------------------------------------------------------------------------//
  //    System(SYS) Interface                                                                                       //
  //----------------------------------------------------------------------------------------------------------------//

  wire  sys_clk;
  wire  sys_rst_n_c;


  // User Clock LED Heartbeat
  reg [25:0] user_clk_heartbeat;

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
  (* mark_debug = "true" *)wire [31:0] m_axil_awaddr;
  (* mark_debug = "true" *)wire [2:0]  m_axil_awprot;
  (* mark_debug = "true" *)wire        m_axil_awvalid;
  (* mark_debug = "true" *)wire        m_axil_awready;

  //-- AXI Master Write Data Channel
  (* mark_debug = "true" *)wire [31:0] m_axil_wdata;
  (* mark_debug = "true" *)wire [3:0]  m_axil_wstrb;
  (* mark_debug = "true" *)wire        m_axil_wvalid;
  (* mark_debug = "true" *)wire        m_axil_wready;

  //-- AXI Master Write Response Channel
  (* mark_debug = "true" *)wire        m_axil_bvalid;
  (* mark_debug = "true" *)wire        m_axil_bready;

  //-- AXI Master Read Address Channel
  (* mark_debug = "true" *)wire [31:0] m_axil_araddr;
  (* mark_debug = "true" *)wire [2:0]  m_axil_arprot;
  (* mark_debug = "true" *)wire        m_axil_arvalid;
  (* mark_debug = "true" *)wire        m_axil_arready;

  //-- AXI Master Read Data Channel
  (* mark_debug = "true" *)wire [31:0] m_axil_rdata;
  (* mark_debug = "true" *)wire [1:0]  m_axil_rresp;
  (* mark_debug = "true" *)wire        m_axil_rvalid;
  (* mark_debug = "true" *)wire        m_axil_rready;
  (* mark_debug = "true" *)wire [1:0]  m_axil_bresp;

  wire [2:0]  msi_vector_width;
  wire        msi_enable;

  wire [3:0]  leds;

  wire   free_run_clock;

  wire [5:0]  cfg_ltssm_state;

  wire [7:0]		c2h_sts_0;
  wire [7:0]		h2c_sts_0;
  wire [7:0]		c2h_sts_1;
  wire [7:0]		h2c_sts_1;
  wire [7:0]		c2h_sts_2;
  wire [7:0]		h2c_sts_2;
  wire [7:0]		c2h_sts_3;
  wire [7:0]		h2c_sts_3;

  // MDMA signals
  wire   [C_DATA_WIDTH-1:0]   m_axis_h2c_tdata;
  wire   [CRC_WIDTH-1:0]      m_axis_h2c_tcrc;
  wire   [10:0]               m_axis_h2c_tuser_qid;
  wire   [2:0]                m_axis_h2c_tuser_port_id;
  wire                        m_axis_h2c_tuser_err;
  wire   [31:0]               m_axis_h2c_tuser_mdata;
  wire   [5:0]                m_axis_h2c_tuser_mty;
  wire                        m_axis_h2c_tuser_zero_byte;
  wire                        m_axis_h2c_tvalid;
  wire                        m_axis_h2c_tready;
  wire                        m_axis_h2c_tlast;

  wire                        m_axis_h2c_tready_lpbk;
  wire                        m_axis_h2c_tready_int;

  // AXIS C2H packet wire
  (* mark_debug = "true" *)wire [C_DATA_WIDTH-1:0]     s_axis_c2h_tdata;
  (* mark_debug = "true" *)wire [CRC_WIDTH-1:0]        s_axis_c2h_tcrc;
  (* mark_debug = "true" *)wire                        s_axis_c2h_ctrl_marker;
  (* mark_debug = "true" *)wire [6:0]                  s_axis_c2h_ctrl_ecc;
  (* mark_debug = "true" *)wire [15:0]                 s_axis_c2h_ctrl_len;
  (* mark_debug = "true" *)wire [2:0]                  s_axis_c2h_ctrl_port_id;
  (* mark_debug = "true" *)wire [10:0]                 s_axis_c2h_ctrl_qid ;
  (* mark_debug = "true" *)wire                        s_axis_c2h_ctrl_has_cmpt ;
  (* mark_debug = "true" *)wire                        s_axis_c2h_tvalid;
  (* mark_debug = "true" *)wire                        s_axis_c2h_tready;
  (* mark_debug = "true" *)wire                        s_axis_c2h_tlast;
  (* mark_debug = "true" *)wire  [5:0]                 s_axis_c2h_mty;

  // AXIS C2H tuser wire
  wire  [511:0] s_axis_c2h_cmpt_tdata;
  (* mark_debug = "true" *)wire  [1:0]   s_axis_c2h_cmpt_size;
  (* mark_debug = "true" *)wire  [15:0]  s_axis_c2h_cmpt_dpar;
  (* mark_debug = "true" *)wire          s_axis_c2h_cmpt_tvalid;
  (* mark_debug = "true" *)wire          s_axis_c2h_cmpt_tready;
  (* mark_debug = "true" *)wire [10:0]	s_axis_c2h_cmpt_ctrl_qid;
  (* mark_debug = "true" *)wire [1:0]	s_axis_c2h_cmpt_ctrl_cmpt_type;
  (* mark_debug = "true" *)wire [15:0]	s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
  (* mark_debug = "true" *)wire 		s_axis_c2h_cmpt_ctrl_marker;
  (* mark_debug = "true" *)wire 		s_axis_c2h_cmpt_ctrl_user_trig;
  (* mark_debug = "true" *)wire [2:0]	s_axis_c2h_cmpt_ctrl_col_idx;
  (* mark_debug = "true" *)wire [2:0]	s_axis_c2h_cmpt_ctrl_err_idx;

  // Descriptor Bypass Out for qdma
  wire  [255:0] h2c_byp_out_dsc;
  wire  [3:0]   h2c_byp_out_fmt;
  wire          h2c_byp_out_st_mm;
  wire  [10:0]  h2c_byp_out_qid;
  wire  [1:0]   h2c_byp_out_dsc_sz;
  wire          h2c_byp_out_error;
  wire  [11:0]  h2c_byp_out_func;
  wire  [15:0]  h2c_byp_out_cidx;
  wire  [2:0]   h2c_byp_out_port_id;
  wire          h2c_byp_out_vld;
  wire          h2c_byp_out_rdy;

  (* mark_debug = "true" *)wire  [255:0] c2h_byp_out_dsc;
  (* mark_debug = "true" *)wire  [3:0]   c2h_byp_out_fmt;
  (* mark_debug = "true" *)wire          c2h_byp_out_st_mm;
  (* mark_debug = "true" *)wire  [1:0]   c2h_byp_out_dsc_sz;
  (* mark_debug = "true" *)wire  [10:0]  c2h_byp_out_qid;
  (* mark_debug = "true" *)wire          c2h_byp_out_error;
  (* mark_debug = "true" *)wire  [11:0]  c2h_byp_out_func;
  (* mark_debug = "true" *)wire  [15:0]  c2h_byp_out_cidx;
  (* mark_debug = "true" *)wire  [2:0]   c2h_byp_out_port_id;
  (* mark_debug = "true" *)wire  [6:0]   c2h_byp_out_pfch_tag;
  (* mark_debug = "true" *)wire          c2h_byp_out_vld;
  (* mark_debug = "true" *)wire          c2h_byp_out_rdy;


   assign c2h_byp_out_pfch_tag ='h0;
   
  // Descriptor Bypass In for qdma MM
  wire  [63:0]  h2c_byp_in_mm_radr;
  wire  [63:0]  h2c_byp_in_mm_wadr;
  wire  [15:0]  h2c_byp_in_mm_len;
  wire          h2c_byp_in_mm_mrkr_req;
  wire          h2c_byp_in_mm_sdi;
  wire  [10:0]  h2c_byp_in_mm_qid;
  wire          h2c_byp_in_mm_error;
  wire  [11:0]  h2c_byp_in_mm_func;
  wire  [15:0]  h2c_byp_in_mm_cidx;
  wire  [2:0]   h2c_byp_in_mm_port_id;
  wire  [1:0]   h2c_byp_in_mm_at;
  wire          h2c_byp_in_mm_no_dma;
  wire          h2c_byp_in_mm_vld;
  wire          h2c_byp_in_mm_rdy;

  wire  [63:0]  c2h_byp_in_mm_radr;
  wire  [63:0]  c2h_byp_in_mm_wadr;
  wire  [15:0]  c2h_byp_in_mm_len;
  wire          c2h_byp_in_mm_mrkr_req;
  wire          c2h_byp_in_mm_sdi;
  wire  [10:0]  c2h_byp_in_mm_qid;
  wire          c2h_byp_in_mm_error;
  wire  [11:0]  c2h_byp_in_mm_func;
  wire  [15:0]  c2h_byp_in_mm_cidx;
  wire  [2:0]   c2h_byp_in_mm_port_id;
  wire  [1:0]   c2h_byp_in_mm_at;
  wire          c2h_byp_in_mm_no_dma;
  wire          c2h_byp_in_mm_vld;
  wire          c2h_byp_in_mm_rdy;

  // Descriptor Bypass In for qdma ST
  wire [63:0]   h2c_byp_in_st_addr;
  wire [15:0]   h2c_byp_in_st_len;
  wire          h2c_byp_in_st_eop;
  wire          h2c_byp_in_st_sop;
  wire          h2c_byp_in_st_mrkr_req;
  wire          h2c_byp_in_st_sdi;
  wire  [10:0]  h2c_byp_in_st_qid;
  wire          h2c_byp_in_st_error;
  wire  [11:0]  h2c_byp_in_st_func;
  wire  [15:0]  h2c_byp_in_st_cidx;
  wire  [2:0]   h2c_byp_in_st_port_id;
  wire  [1:0]   h2c_byp_in_st_at;
  wire          h2c_byp_in_st_no_dma;
  wire          h2c_byp_in_st_vld;
  wire          h2c_byp_in_st_rdy;

  (* mark_debug = "true" *)wire  [63:0]  c2h_byp_in_st_csh_addr;
  (* mark_debug = "true" *)wire  [10:0]  c2h_byp_in_st_csh_qid;
  (* mark_debug = "true" *)wire          c2h_byp_in_st_csh_error;
  (* mark_debug = "true" *)wire  [11:0]  c2h_byp_in_st_csh_func;
  (* mark_debug = "true" *)wire  [2:0]   c2h_byp_in_st_csh_port_id;
  (* mark_debug = "true" *)wire  [6:0]   c2h_byp_in_st_csh_pfch_tag;
  (* mark_debug = "true" *)wire  [1:0]   c2h_byp_in_st_csh_at;
  (* mark_debug = "true" *)wire          c2h_byp_in_st_csh_vld;
  (* mark_debug = "true" *)wire          c2h_byp_in_st_csh_rdy;

  (* mark_debug = "true" *)wire          usr_irq_in_vld;
  (* mark_debug = "true" *)wire [10 : 0] usr_irq_in_vec;
  (* mark_debug = "true" *)wire [11 : 0] usr_irq_in_fnc;
  (* mark_debug = "true" *)wire          usr_irq_out_ack;
  (* mark_debug = "true" *)wire          usr_irq_out_fail;

  wire          st_rx_msg_rdy;
  wire          st_rx_msg_valid;
  wire          st_rx_msg_last;
  wire [31:0]   st_rx_msg_data;

  wire          tm_dsc_sts_vld;
  wire          tm_dsc_sts_qen;
  wire          tm_dsc_sts_byp;
  wire          tm_dsc_sts_dir;
  wire          tm_dsc_sts_mm;
  wire          tm_dsc_sts_error;
  wire  [10:0]  tm_dsc_sts_qid;
  wire  [15:0]  tm_dsc_sts_avl;
  wire          tm_dsc_sts_qinv;
  wire          tm_dsc_sts_irq_arm;
  wire          tm_dsc_sts_rdy;

  // Descriptor credit In
  wire          dsc_crdt_in_vld;
  wire          dsc_crdt_in_rdy;
  wire          dsc_crdt_in_dir;
  wire          dsc_crdt_in_fence;
  wire [10:0]   dsc_crdt_in_qid;
  wire [15:0]   dsc_crdt_in_crdt;

  // Report the DROP case
  wire          axis_c2h_status_drop;
  wire          axis_c2h_status_last;
  wire          axis_c2h_status_valid;
  wire          axis_c2h_status_cmp;
  wire          axis_c2h_status_error;
  wire [10:0]   axis_c2h_status_qid;
  wire [7:0]    qsts_out_op;
  wire [63:0]   qsts_out_data;
  wire [2:0]    qsts_out_port_id;
  wire [12:0]   qsts_out_qid;
  wire          qsts_out_vld;
  wire          qsts_out_rdy;

  // FLR
  (* mark_debug = "true" *)wire [7:0]  usr_flr_fnc;
  (* mark_debug = "true" *)wire        usr_flr_set;
  (* mark_debug = "true" *)wire        usr_flr_clr;
  (* mark_debug = "true" *)wire [7:0]  usr_flr_done_fnc;
  (* mark_debug = "true" *)wire        usr_flr_done_vld;
  wire [3:0]		cfg_tph_requester_enable;
  wire [251:0]	cfg_vf_tph_requester_enable;
	wire          soft_reset_n;
	wire					st_loopback;

  wire [10:0]   c2h_num_pkt;
  wire [10:0]   c2h_st_qid;
  wire [15:0]   c2h_st_len;
  wire [31:0]   h2c_count;
  wire          h2c_match;
  wire          clr_h2c_match;
  wire 	        c2h_end;
  wire [31:0]   c2h_control;
  wire [10:0]   h2c_qid;
  wire [31:0]   cmpt_size;
  wire [255:0]  wb_dat;

  wire [TM_DSC_BITS-1:0] credit_out;
  wire [TM_DSC_BITS-1:0] credit_needed;
  wire [TM_DSC_BITS-1:0] credit_perpkt_in;
  wire                   credit_updt;

  wire [15:0] buf_count;
  wire        sys_clk_gt;

wire  [63:0]   AXI_NOC_2_PL_araddr;
wire  [1:0]    AXI_NOC_2_PL_arburst;
wire  [3:0]    AXI_NOC_2_PL_arcache;
wire  [1:0]    AXI_NOC_2_PL_arid;
wire  [7:0]    AXI_NOC_2_PL_arlen;
wire  [0:0]    AXI_NOC_2_PL_arlock;
wire  [2:0]    AXI_NOC_2_PL_arprot;
wire  [3:0]    AXI_NOC_2_PL_arqos;
wire  [0:0]    AXI_NOC_2_PL_arready;
wire  [3:0]    AXI_NOC_2_PL_arregion;
wire  [2:0]    AXI_NOC_2_PL_arsize;
wire  [17:0]   AXI_NOC_2_PL_aruser;
wire  [0:0]    AXI_NOC_2_PL_arvalid;
wire  [63:0]   AXI_NOC_2_PL_awaddr;
wire  [1:0]    AXI_NOC_2_PL_awburst;
wire  [3:0]    AXI_NOC_2_PL_awcache;
wire  [1:0]    AXI_NOC_2_PL_awid;
wire  [7:0]    AXI_NOC_2_PL_awlen;
wire  [0:0]    AXI_NOC_2_PL_awlock;
wire  [2:0]    AXI_NOC_2_PL_awprot;
wire  [3:0]    AXI_NOC_2_PL_awqos;
wire  [0:0]    AXI_NOC_2_PL_awready;
wire  [3:0]    AXI_NOC_2_PL_awregion;
wire  [2:0]    AXI_NOC_2_PL_awsize;
wire  [17:0]   AXI_NOC_2_PL_awuser;
wire  [0:0]    AXI_NOC_2_PL_awvalid;
wire  [1:0]    AXI_NOC_2_PL_bid;
wire  [0:0]    AXI_NOC_2_PL_bready;
wire  [1:0]    AXI_NOC_2_PL_bresp;
wire  [0:0]    AXI_NOC_2_PL_bvalid;
wire  [31:0]   AXI_NOC_2_PL_rdata;
wire  [1:0]    AXI_NOC_2_PL_rid;
wire  [0:0]    AXI_NOC_2_PL_rlast;
wire  [0:0]    AXI_NOC_2_PL_rready;
wire  [1:0]    AXI_NOC_2_PL_rresp;
wire  [0:0]    AXI_NOC_2_PL_rvalid;
wire  [31:0]   AXI_NOC_2_PL_wdata;
wire  [1:0]    AXI_NOC_2_PL_wid;
wire  [0:0]    AXI_NOC_2_PL_wlast;
wire  [0:0]    AXI_NOC_2_PL_wready;
wire  [3:0]    AXI_NOC_2_PL_wstrb;
wire  [0:0]    AXI_NOC_2_PL_wvalid;

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
      wire [11:0] dma_usr_flr_done_fnc;
      wire       dma_usr_flr_done_vld;
      wire       dma_usr_flr_clr;
      wire [11:0] dma_usr_flr_fnc;
      wire       dma_usr_flr_set;
      wire       dma_usr_irq_ack;
      wire       dma_usr_irq_fail;
      wire [11:0] dma_usr_irq_fnc;
      wire       dma_usr_irq_valid;
      wire [10:0] dma_usr_irq_vec;

 wire [1 : 0]  pcie_mgmt_0_cpl_sts;
 wire          pcie_mgmt_0_cpl_rdy;
 wire          pcie_mgmt_0_cpl_vld;
 wire [31 : 0] pcie_mgmt_0_cpl_dat;
 wire [1 : 0]  pcie_mgmt_0_req_cmd;
 wire [7 : 0]  pcie_mgmt_0_req_fnc;
 wire [5 : 0]  pcie_mgmt_0_req_msc;
 wire [31 : 0] pcie_mgmt_0_req_adr;
 wire [31 : 0] pcie_mgmt_0_req_dat;
 wire          pcie_mgmt_0_req_rdy;
 wire          pcie_mgmt_0_req_vld;

wire dma0_axis_c2h_dmawr_0_target_vch;
wire dma0_c2h_byp_out_0_mm_chn;
wire dma0_h2c_byp_out_0_mm_chn;

  // Ref clock buffer
/*
  IBUFDS_GTE4 # (.REFCLK_HROW_CK_SEL(2'b00)) refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));
  // Reset buffer
  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));
  // LED 0 pysically resides in the reconfiguable area for Tandem with
  // Field Updates designs so the OBUF must included in the app hierarchy.
  assign led_0 = leds[0];
  // LEDs 1-3 physically reside in the stage1 region for Tandem with Field
  // Updates designs so the OBUF must be instantiated at the top-level and
  // added to the stage1 region
  OBUF led_1_obuf (.O(led_1), .I(leds[1]));
  OBUF led_2_obuf (.O(led_2), .I(leds[2]));
  OBUF led_3_obuf (.O(led_3), .I(leds[3]));
*/




//
//

design_1 design_1_i
       (
        .PCIE0_GT_0_grx_n(PCIE0_GT_0_grx_n),
        .PCIE0_GT_0_grx_p(PCIE0_GT_0_grx_p),
        .PCIE0_GT_0_gtx_n(PCIE0_GT_0_gtx_n),
        .PCIE0_GT_0_gtx_p(PCIE0_GT_0_gtx_p),
        .ch0_lpddr4_trip1_ca_a(ch0_lpddr4_trip1_ca_a),
        .ch0_lpddr4_trip1_ca_b(ch0_lpddr4_trip1_ca_b),
        .ch0_lpddr4_trip1_ck_c_a(ch0_lpddr4_trip1_ck_c_a),
        .ch0_lpddr4_trip1_ck_c_b(ch0_lpddr4_trip1_ck_c_b),
        .ch0_lpddr4_trip1_ck_t_a(ch0_lpddr4_trip1_ck_t_a),
        .ch0_lpddr4_trip1_ck_t_b(ch0_lpddr4_trip1_ck_t_b),
        .ch0_lpddr4_trip1_cke_a(ch0_lpddr4_trip1_cke_a),
        .ch0_lpddr4_trip1_cke_b(ch0_lpddr4_trip1_cke_b),
        .ch0_lpddr4_trip1_cs_a(ch0_lpddr4_trip1_cs_a),
        .ch0_lpddr4_trip1_cs_b(ch0_lpddr4_trip1_cs_b),
        .ch0_lpddr4_trip1_dmi_a(ch0_lpddr4_trip1_dmi_a),
        .ch0_lpddr4_trip1_dmi_b(ch0_lpddr4_trip1_dmi_b),
        .ch0_lpddr4_trip1_dq_a(ch0_lpddr4_trip1_dq_a),
        .ch0_lpddr4_trip1_dq_b(ch0_lpddr4_trip1_dq_b),
        .ch0_lpddr4_trip1_dqs_c_a(ch0_lpddr4_trip1_dqs_c_a),
        .ch0_lpddr4_trip1_dqs_c_b(ch0_lpddr4_trip1_dqs_c_b),
        .ch0_lpddr4_trip1_dqs_t_a(ch0_lpddr4_trip1_dqs_t_a),
        .ch0_lpddr4_trip1_dqs_t_b(ch0_lpddr4_trip1_dqs_t_b),
        .ch0_lpddr4_trip1_reset_n(ch0_lpddr4_trip1_reset_n),
        .ch0_lpddr4_trip2_ca_a(ch0_lpddr4_trip2_ca_a),
        .ch0_lpddr4_trip2_ca_b(ch0_lpddr4_trip2_ca_b),
        .ch0_lpddr4_trip2_ck_c_a(ch0_lpddr4_trip2_ck_c_a),
        .ch0_lpddr4_trip2_ck_c_b(ch0_lpddr4_trip2_ck_c_b),
        .ch0_lpddr4_trip2_ck_t_a(ch0_lpddr4_trip2_ck_t_a),
        .ch0_lpddr4_trip2_ck_t_b(ch0_lpddr4_trip2_ck_t_b),
        .ch0_lpddr4_trip2_cke_a(ch0_lpddr4_trip2_cke_a),
        .ch0_lpddr4_trip2_cke_b(ch0_lpddr4_trip2_cke_b),
        .ch0_lpddr4_trip2_cs_a(ch0_lpddr4_trip2_cs_a),
        .ch0_lpddr4_trip2_cs_b(ch0_lpddr4_trip2_cs_b),
        .ch0_lpddr4_trip2_dmi_a(ch0_lpddr4_trip2_dmi_a),
        .ch0_lpddr4_trip2_dmi_b(ch0_lpddr4_trip2_dmi_b),
        .ch0_lpddr4_trip2_dq_a(ch0_lpddr4_trip2_dq_a),
        .ch0_lpddr4_trip2_dq_b(ch0_lpddr4_trip2_dq_b),
        .ch0_lpddr4_trip2_dqs_c_a(ch0_lpddr4_trip2_dqs_c_a),
        .ch0_lpddr4_trip2_dqs_c_b(ch0_lpddr4_trip2_dqs_c_b),
        .ch0_lpddr4_trip2_dqs_t_a(ch0_lpddr4_trip2_dqs_t_a),
        .ch0_lpddr4_trip2_dqs_t_b(ch0_lpddr4_trip2_dqs_t_b),
        .ch0_lpddr4_trip2_reset_n(ch0_lpddr4_trip2_reset_n),
        .ch1_lpddr4_trip1_ca_a(ch1_lpddr4_trip1_ca_a),
        .ch1_lpddr4_trip1_ca_b(ch1_lpddr4_trip1_ca_b),
        .ch1_lpddr4_trip1_ck_c_a(ch1_lpddr4_trip1_ck_c_a),
        .ch1_lpddr4_trip1_ck_c_b(ch1_lpddr4_trip1_ck_c_b),
        .ch1_lpddr4_trip1_ck_t_a(ch1_lpddr4_trip1_ck_t_a),
        .ch1_lpddr4_trip1_ck_t_b(ch1_lpddr4_trip1_ck_t_b),
        .ch1_lpddr4_trip1_cke_a(ch1_lpddr4_trip1_cke_a),
        .ch1_lpddr4_trip1_cke_b(ch1_lpddr4_trip1_cke_b),
        .ch1_lpddr4_trip1_cs_a(ch1_lpddr4_trip1_cs_a),
        .ch1_lpddr4_trip1_cs_b(ch1_lpddr4_trip1_cs_b),
        .ch1_lpddr4_trip1_dmi_a(ch1_lpddr4_trip1_dmi_a),
        .ch1_lpddr4_trip1_dmi_b(ch1_lpddr4_trip1_dmi_b),
        .ch1_lpddr4_trip1_dq_a(ch1_lpddr4_trip1_dq_a),
        .ch1_lpddr4_trip1_dq_b(ch1_lpddr4_trip1_dq_b),
        .ch1_lpddr4_trip1_dqs_c_a(ch1_lpddr4_trip1_dqs_c_a),
        .ch1_lpddr4_trip1_dqs_c_b(ch1_lpddr4_trip1_dqs_c_b),
        .ch1_lpddr4_trip1_dqs_t_a(ch1_lpddr4_trip1_dqs_t_a),
        .ch1_lpddr4_trip1_dqs_t_b(ch1_lpddr4_trip1_dqs_t_b),
        .ch1_lpddr4_trip1_reset_n(ch1_lpddr4_trip1_reset_n),
        .ch1_lpddr4_trip2_ca_a(ch1_lpddr4_trip2_ca_a),
        .ch1_lpddr4_trip2_ca_b(ch1_lpddr4_trip2_ca_b),
        .ch1_lpddr4_trip2_ck_c_a(ch1_lpddr4_trip2_ck_c_a),
        .ch1_lpddr4_trip2_ck_c_b(ch1_lpddr4_trip2_ck_c_b),
        .ch1_lpddr4_trip2_ck_t_a(ch1_lpddr4_trip2_ck_t_a),
        .ch1_lpddr4_trip2_ck_t_b(ch1_lpddr4_trip2_ck_t_b),
        .ch1_lpddr4_trip2_cke_a(ch1_lpddr4_trip2_cke_a),
        .ch1_lpddr4_trip2_cke_b(ch1_lpddr4_trip2_cke_b),
        .ch1_lpddr4_trip2_cs_a(ch1_lpddr4_trip2_cs_a),
        .ch1_lpddr4_trip2_cs_b(ch1_lpddr4_trip2_cs_b),
        .ch1_lpddr4_trip2_dmi_a(ch1_lpddr4_trip2_dmi_a),
        .ch1_lpddr4_trip2_dmi_b(ch1_lpddr4_trip2_dmi_b),
        .ch1_lpddr4_trip2_dq_a(ch1_lpddr4_trip2_dq_a),
        .ch1_lpddr4_trip2_dq_b(ch1_lpddr4_trip2_dq_b),
        .ch1_lpddr4_trip2_dqs_c_a(ch1_lpddr4_trip2_dqs_c_a),
        .ch1_lpddr4_trip2_dqs_c_b(ch1_lpddr4_trip2_dqs_c_b),
        .ch1_lpddr4_trip2_dqs_t_a(ch1_lpddr4_trip2_dqs_t_a),
        .ch1_lpddr4_trip2_dqs_t_b(ch1_lpddr4_trip2_dqs_t_b),
        .ch1_lpddr4_trip2_reset_n(ch1_lpddr4_trip2_reset_n),
        .dma0_axis_c2h_dmawr_0_target_vch(dma0_axis_c2h_dmawr_0_target_vch), 
        .dma0_c2h_byp_in_mm_0_0_at('h0), 
        .dma0_c2h_byp_in_mm_0_0_no_dma('h0),
        .dma0_c2h_byp_in_mm_1_0_at('h0), 
        .dma0_c2h_byp_in_mm_1_0_no_dma('h0),
        .dma0_c2h_byp_in_st_csh_0_at('h0), 
        .dma0_c2h_byp_out_0_mm_chn(dma0_c2h_byp_out_0_mm_chn), 
        .dma0_h2c_byp_in_mm_0_0_at('h0), 
        .dma0_h2c_byp_in_mm_1_0_at('h0),                     
        .dma0_h2c_byp_in_st_0_at('h0),                         
        .dma0_h2c_byp_out_0_mm_chn(dma0_h2c_byp_out_0_mm_chn),                     
        .lpddr4_clk2_clk_n(lpddr4_clk2_clk_n),                                     
        .lpddr4_clk2_clk_p(lpddr4_clk2_clk_p),                                     
        .sys_clk0_0_clk_n(sys_clk0_0_clk_n),
        .sys_clk0_0_clk_p(sys_clk0_0_clk_p),

      .gt_refclk0_0_clk_n(gt_refclk0_0_clk_n),
      .gt_refclk0_0_clk_p(gt_refclk0_0_clk_p),

      .M_AXIL_araddr  (m_axil_araddr),
      .M_AXIL_arprot  (m_axil_arprot),
      .M_AXIL_arready (m_axil_arready),
      .M_AXIL_arvalid (m_axil_arvalid),
      .M_AXIL_awaddr  (m_axil_awaddr),
      .M_AXIL_awprot  (m_axil_awprot),
      .M_AXIL_awready (m_axil_awready),
      .M_AXIL_awvalid (m_axil_awvalid),
      .M_AXIL_bready  (m_axil_bready),
      .M_AXIL_bresp   (m_axil_bresp),
      .M_AXIL_bvalid  (m_axil_bvalid),
      .M_AXIL_rdata   (m_axil_rdata),
      .M_AXIL_rready  (m_axil_rready),
      .M_AXIL_rresp   (m_axil_rresp),
      .M_AXIL_rvalid  (m_axil_rvalid),
      .M_AXIL_wdata   (m_axil_wdata),
      .M_AXIL_wready  (m_axil_wready),
      .M_AXIL_wstrb   (m_axil_wstrb),
      .M_AXIL_wvalid  (m_axil_wvalid),
      
      // To AXIL BRAM
      .S_AXIL_araddr(S_AXI_0_araddr),
      .S_AXIL_arprot(S_AXI_0_arprot),
      .S_AXIL_arready(S_AXI_0_arready),
      .S_AXIL_arvalid(S_AXI_0_arvalid),
      .S_AXIL_awaddr(S_AXI_0_awaddr),
      .S_AXIL_awprot(S_AXI_0_awprot),
      .S_AXIL_awready(S_AXI_0_awready),
      .S_AXIL_awvalid(S_AXI_0_awvalid),
      .S_AXIL_bready(S_AXI_0_bready),
      .S_AXIL_bresp(S_AXI_0_bresp),
      .S_AXIL_bvalid(S_AXI_0_bvalid),
      .S_AXIL_rdata(S_AXI_0_rdata),
      .S_AXIL_rready(S_AXI_0_rready),
      .S_AXIL_rresp(S_AXI_0_rresp),
      .S_AXIL_rvalid(S_AXI_0_rvalid),
      .S_AXIL_wdata(S_AXI_0_wdata),
      .S_AXIL_wready(S_AXI_0_wready),
      .S_AXIL_wstrb(S_AXI_0_wstrb),
      .S_AXIL_wvalid(S_AXI_0_wvalid),

      .dma0_s_axis_c2h_0_tcrc         (s_axis_c2h_tcrc ),
      .dma0_s_axis_c2h_0_mty          (s_axis_c2h_mty),
      .dma0_s_axis_c2h_0_tdata        (s_axis_c2h_tdata),
      .dma0_s_axis_c2h_0_tlast        (s_axis_c2h_tlast),
      .dma0_s_axis_c2h_0_tready       (s_axis_c2h_tready),
      .dma0_s_axis_c2h_0_tvalid       (s_axis_c2h_tvalid),
      .dma0_s_axis_c2h_0_ctrl_has_cmpt(s_axis_c2h_ctrl_has_cmpt ),
      .dma0_s_axis_c2h_0_ctrl_len     (s_axis_c2h_ctrl_len),
      .dma0_s_axis_c2h_0_ctrl_marker  (s_axis_c2h_ctrl_marker),
      .dma0_s_axis_c2h_0_ctrl_port_id (s_axis_c2h_ctrl_port_id),
      .dma0_s_axis_c2h_0_ctrl_qid     (s_axis_c2h_ctrl_qid),
      .dma0_s_axis_c2h_0_ecc          (s_axis_c2h_ctrl_ecc),  // TODO

      .dma0_s_axis_c2h_cmpt_0_data     (s_axis_c2h_cmpt_tdata   ),
      .dma0_s_axis_c2h_cmpt_0_dpar     (s_axis_c2h_cmpt_dpar   ),
      .dma0_s_axis_c2h_cmpt_0_tready   (s_axis_c2h_cmpt_tready ),
      .dma0_s_axis_c2h_cmpt_0_tvalid   (s_axis_c2h_cmpt_tvalid ),
      .dma0_s_axis_c2h_cmpt_0_size            (s_axis_c2h_cmpt_size                  ),
      .dma0_s_axis_c2h_cmpt_0_cmpt_type       (s_axis_c2h_cmpt_ctrl_cmpt_type ),
      .dma0_s_axis_c2h_cmpt_0_err_idx         (s_axis_c2h_cmpt_ctrl_err_idx          ),
      .dma0_s_axis_c2h_cmpt_0_marker          (s_axis_c2h_cmpt_ctrl_marker           ),
      .dma0_s_axis_c2h_cmpt_0_no_wrb_marker   (1'b0     ),
      .dma0_s_axis_c2h_cmpt_0_col_idx         (s_axis_c2h_cmpt_ctrl_col_idx          ),
      .dma0_s_axis_c2h_cmpt_0_port_id         ('b00          ),
      .dma0_s_axis_c2h_cmpt_0_qid             ({2'b0,s_axis_c2h_cmpt_ctrl_qid}       ),
      .dma0_s_axis_c2h_cmpt_0_user_trig       (s_axis_c2h_cmpt_ctrl_user_trig        ),
      .dma0_s_axis_c2h_cmpt_0_wait_pld_pkt_id (s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id  ),
 
      .dma0_axis_c2h_status_0_drop (axis_c2h_status_drop  ),
      .dma0_axis_c2h_status_0_qid  (axis_c2h_status_qid   ),
      .dma0_axis_c2h_status_0_valid(axis_c2h_status_valid ),
      .dma0_axis_c2h_status_0_status_cmp  (axis_c2h_status_cmp   ),
      .dma0_axis_c2h_status_0_error(axis_c2h_status_error ),
      .dma0_axis_c2h_status_0_last (axis_c2h_status_last  ),

      .dma0_axis_c2h_dmawr_0_cmp    (axis_c2h_dmawr_cmp), //TODO
      .dma0_axis_c2h_dmawr_0_port_id(axis_c2h_dmawr_port_id), //TODO

      .dma0_dsc_crdt_in_0_crdt     (dsc_crdt_in_crdt  ),
      .dma0_dsc_crdt_in_0_qid      (dsc_crdt_in_qid   ),
      .dma0_dsc_crdt_in_0_rdy      (dsc_crdt_in_rdy   ),
      .dma0_dsc_crdt_in_0_dir      (dsc_crdt_in_dir   ),
      .dma0_dsc_crdt_in_0_valid    (dsc_crdt_in_vld   ),
      .dma0_dsc_crdt_in_0_fence    (dsc_crdt_in_fence ),

      .dma0_m_axis_h2c_0_err       (m_axis_h2c_tuser_err      ),
      .dma0_m_axis_h2c_0_mdata     (m_axis_h2c_tuser_mdata    ),
      .dma0_m_axis_h2c_0_mty       (m_axis_h2c_tuser_mty      ),
      .dma0_m_axis_h2c_0_tcrc      (m_axis_h2c_tcrc      ),
      .dma0_m_axis_h2c_0_port_id   (m_axis_h2c_tuser_port_id  ),
      .dma0_m_axis_h2c_0_qid       (m_axis_h2c_tuser_qid      ),
      .dma0_m_axis_h2c_0_tdata     (m_axis_h2c_tdata    ),
      .dma0_m_axis_h2c_0_tlast     (m_axis_h2c_tlast    ),
      .dma0_m_axis_h2c_0_tready    (m_axis_h2c_tready   ),
      .dma0_m_axis_h2c_0_tvalid    (m_axis_h2c_tvalid   ),
      .dma0_m_axis_h2c_0_zero_byte (m_axis_h2c_tuser_zero_byte),

      .dma0_st_rx_msg_0_tdata    (st_rx_msg_data  ),
      .dma0_st_rx_msg_0_tlast    (st_rx_msg_last  ),
      .dma0_st_rx_msg_0_tready   (st_rx_msg_rdy ),
      .dma0_st_rx_msg_0_tvalid   (st_rx_msg_valid ),

      .dma0_tm_dsc_sts_0_avl     (tm_dsc_sts_avl     ),
      .dma0_tm_dsc_sts_0_byp     (tm_dsc_sts_byp     ),
      .dma0_tm_dsc_sts_0_dir     (tm_dsc_sts_dir     ),
      .dma0_tm_dsc_sts_0_error   (tm_dsc_sts_error   ),
      .dma0_tm_dsc_sts_0_irq_arm (tm_dsc_sts_irq_arm ),
      .dma0_tm_dsc_sts_0_mm      (tm_dsc_sts_mm      ),
      .dma0_tm_dsc_sts_0_port_id (tm_dsc_sts_port_id ),  // TODO : New port?
      .dma0_tm_dsc_sts_0_qen     (tm_dsc_sts_qen     ),
      .dma0_tm_dsc_sts_0_qid     (tm_dsc_sts_qid     ),
      .dma0_tm_dsc_sts_0_qinv    (tm_dsc_sts_qinv    ),
      .dma0_tm_dsc_sts_0_rdy     (tm_dsc_sts_rdy     ),
      .dma0_tm_dsc_sts_0_valid   (tm_dsc_sts_vld   ),
      .dma0_tm_dsc_sts_0_pidx    (                   ),

      .dma0_c2h_byp_out_0_cidx            (c2h_byp_out_cidx),
      .dma0_c2h_byp_out_0_dsc             (c2h_byp_out_dsc),
      .dma0_c2h_byp_out_0_dsc_sz          (c2h_byp_out_dsc_sz),
      .dma0_c2h_byp_out_0_error           (c2h_byp_out_error),
      .dma0_c2h_byp_out_0_fmt             (c2h_byp_out_fmt),
      .dma0_c2h_byp_out_0_func            (c2h_byp_out_func),
//      .dma0_c2h_byp_out_0_pfch_tag        (c2h_byp_out_pfch_tag),
      .dma0_c2h_byp_out_0_port_id         (c2h_byp_out_port_id),
      .dma0_c2h_byp_out_0_qid             (c2h_byp_out_qid),
      .dma0_c2h_byp_out_0_ready           (c2h_byp_out_rdy),
      .dma0_c2h_byp_out_0_st_mm           (c2h_byp_out_st_mm),
      .dma0_c2h_byp_out_0_valid           (c2h_byp_out_vld),
      
      .dma0_h2c_byp_out_0_cidx            (h2c_byp_out_cidx),
      .dma0_h2c_byp_out_0_dsc             (h2c_byp_out_dsc),
      .dma0_h2c_byp_out_0_dsc_sz          (h2c_byp_out_dsc_sz),
      .dma0_h2c_byp_out_0_error           (h2c_byp_out_error),
      .dma0_h2c_byp_out_0_fmt             (h2c_byp_out_fmt),
      .dma0_h2c_byp_out_0_func            (h2c_byp_out_func),
      .dma0_h2c_byp_out_0_port_id         (h2c_byp_out_port_id),
      .dma0_h2c_byp_out_0_qid             (h2c_byp_out_qid),
      .dma0_h2c_byp_out_0_ready           (h2c_byp_out_rdy),
      .dma0_h2c_byp_out_0_st_mm           (h2c_byp_out_st_mm),
      .dma0_h2c_byp_out_0_valid           (h2c_byp_out_vld),
      
      .dma0_c2h_byp_in_st_csh_0_addr      (c2h_byp_in_st_csh_addr),
      .dma0_c2h_byp_in_st_csh_0_error     (c2h_byp_in_st_csh_error),
      .dma0_c2h_byp_in_st_csh_0_func      (c2h_byp_in_st_csh_func),
      .dma0_c2h_byp_in_st_csh_0_pfch_tag  (c2h_byp_in_st_csh_pfch_tag),
      .dma0_c2h_byp_in_st_csh_0_port_id   (c2h_byp_in_st_csh_port_id),
      .dma0_c2h_byp_in_st_csh_0_qid       (c2h_byp_in_st_csh_qid),
      .dma0_c2h_byp_in_st_csh_0_ready     (c2h_byp_in_st_csh_rdy),
      .dma0_c2h_byp_in_st_csh_0_valid     (c2h_byp_in_st_csh_vld),
      
      .dma0_h2c_byp_in_st_0_addr          (h2c_byp_in_st_addr),
      .dma0_h2c_byp_in_st_0_cidx          (h2c_byp_in_st_cidx),
      .dma0_h2c_byp_in_st_0_eop           (h2c_byp_in_st_eop),
      .dma0_h2c_byp_in_st_0_error         (h2c_byp_in_st_error),
      .dma0_h2c_byp_in_st_0_func          (h2c_byp_in_st_func),
      .dma0_h2c_byp_in_st_0_len           (h2c_byp_in_st_len),
      .dma0_h2c_byp_in_st_0_mrkr_req      (h2c_byp_in_st_mrkr_req),
      .dma0_h2c_byp_in_st_0_no_dma        (h2c_byp_in_st_no_dma),
      .dma0_h2c_byp_in_st_0_port_id       (h2c_byp_in_st_port_id),
      .dma0_h2c_byp_in_st_0_qid           (h2c_byp_in_st_qid),
      .dma0_h2c_byp_in_st_0_ready         (h2c_byp_in_st_rdy),
      .dma0_h2c_byp_in_st_0_sdi           (h2c_byp_in_st_sdi),
      .dma0_h2c_byp_in_st_0_sop           (h2c_byp_in_st_sop),
      .dma0_h2c_byp_in_st_0_valid         (h2c_byp_in_st_vld),

      .dma0_c2h_byp_in_mm_0_0_cidx        (c2h_byp_in_mm_cidx),
      .dma0_c2h_byp_in_mm_0_0_error       (c2h_byp_in_mm_error),
      .dma0_c2h_byp_in_mm_0_0_func        (c2h_byp_in_mm_func),
      .dma0_c2h_byp_in_mm_0_0_len         (c2h_byp_in_mm_len),
      .dma0_c2h_byp_in_mm_0_0_mrkr_req    (c2h_byp_in_mm_mrkr_req),
      .dma0_c2h_byp_in_mm_0_0_port_id     (c2h_byp_in_mm_port_id),
      .dma0_c2h_byp_in_mm_0_0_qid         (c2h_byp_in_mm_qid),
      .dma0_c2h_byp_in_mm_0_0_radr        (c2h_byp_in_mm_radr),
      .dma0_c2h_byp_in_mm_0_0_ready       (c2h_byp_in_mm_rdy),
      .dma0_c2h_byp_in_mm_0_0_sdi         (c2h_byp_in_mm_sdi),
      .dma0_c2h_byp_in_mm_0_0_valid       (c2h_byp_in_mm_vld),
      .dma0_c2h_byp_in_mm_0_0_wadr        (c2h_byp_in_mm_wadr),
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
      .dma0_h2c_byp_in_mm_0_0_cidx        (h2c_byp_in_mm_cidx),
      .dma0_h2c_byp_in_mm_0_0_error       (h2c_byp_in_mm_error),
      .dma0_h2c_byp_in_mm_0_0_func        (h2c_byp_in_mm_func),
      .dma0_h2c_byp_in_mm_0_0_len         (h2c_byp_in_mm_len),
      .dma0_h2c_byp_in_mm_0_0_mrkr_req    (h2c_byp_in_mm_mrkr_req),
      .dma0_h2c_byp_in_mm_0_0_no_dma      (h2c_byp_in_mm_no_dma),
      .dma0_h2c_byp_in_mm_0_0_port_id     (h2c_byp_in_mm_port_id),
      .dma0_h2c_byp_in_mm_0_0_qid         (h2c_byp_in_mm_qid),
      .dma0_h2c_byp_in_mm_0_0_radr        (h2c_byp_in_mm_radr),
      .dma0_h2c_byp_in_mm_0_0_ready       (h2c_byp_in_mm_rdy),
      .dma0_h2c_byp_in_mm_0_0_sdi         (h2c_byp_in_mm_sdi),
      .dma0_h2c_byp_in_mm_0_0_valid       (h2c_byp_in_mm_vld),
      .dma0_h2c_byp_in_mm_0_0_wadr        (h2c_byp_in_mm_wadr),
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

      .dma0_qsts_out_0_data     (qsts_out_data     ),
      .dma0_qsts_out_0_op       (qsts_out_op       ),
      .dma0_qsts_out_0_port_id  (qsts_out_port_id  ),
      .dma0_qsts_out_0_qid      (qsts_out_qid      ),
      .dma0_qsts_out_0_rdy      (qsts_out_rdy  ),
      .dma0_qsts_out_0_vld      (qsts_out_vld  ),

      // Mailbox IP connection input from user
      .usr_flr_0_clear         ( usr_flr_clr ),
      .usr_flr_0_done_fnc      ( usr_flr_done_fnc ),
      .usr_flr_0_done_vld      ( usr_flr_done_vld ),
      .usr_flr_0_fnc           ( usr_flr_fnc ),
      .usr_flr_0_set           ( usr_flr_set ),
      .usr_irq_0_ack           ( usr_irq_out_ack ),
      .usr_irq_0_fail          ( usr_irq_out_fail ),
      .usr_irq_0_fnc           ( usr_irq_in_fnc ),
      .usr_irq_0_valid         ( usr_irq_in_vld ),
      .usr_irq_0_vec           ( usr_irq_in_vec ),

      .dma0_intrfc_resetn_0(soft_reset_n),
      .dma0_axi_aresetn_0(axi_aresetn),

      .cpm_cor_irq_0(),
      .cpm_misc_irq_0(),
      .cpm_uncor_irq_0(),
      .cpm_irq0_0('d0),
      .cpm_irq1_0('d0),
      .dma0_intrfc_clk_0(axi_aclk)

      /*      
      .M_AXI_NOC_2_PL_OUT_araddr      (AXI_NOC_2_PL_araddr),         
      .M_AXI_NOC_2_PL_OUT_arburst     (AXI_NOC_2_PL_arburst),
      .M_AXI_NOC_2_PL_OUT_arcache     (AXI_NOC_2_PL_arcache),
      .M_AXI_NOC_2_PL_OUT_arid        (AXI_NOC_2_PL_arid),
      .M_AXI_NOC_2_PL_OUT_arlen       (AXI_NOC_2_PL_arlen),
      .M_AXI_NOC_2_PL_OUT_arlock      (AXI_NOC_2_PL_arlock),
      .M_AXI_NOC_2_PL_OUT_arprot      (AXI_NOC_2_PL_arprot),
      .M_AXI_NOC_2_PL_OUT_arqos       (AXI_NOC_2_PL_arqos),
      .M_AXI_NOC_2_PL_OUT_arready     (AXI_NOC_2_PL_arready),
      .M_AXI_NOC_2_PL_OUT_arregion    (AXI_NOC_2_PL_arregion),
      .M_AXI_NOC_2_PL_OUT_arsize      (AXI_NOC_2_PL_arsize),
      .M_AXI_NOC_2_PL_OUT_aruser      (AXI_NOC_2_PL_aruser),
      .M_AXI_NOC_2_PL_OUT_arvalid     (AXI_NOC_2_PL_arvalid),
      .M_AXI_NOC_2_PL_OUT_awaddr      (AXI_NOC_2_PL_awaddr),
      .M_AXI_NOC_2_PL_OUT_awburst     (AXI_NOC_2_PL_awburst),
      .M_AXI_NOC_2_PL_OUT_awcache     (AXI_NOC_2_PL_awcache),
      .M_AXI_NOC_2_PL_OUT_awid        (AXI_NOC_2_PL_awid),
      .M_AXI_NOC_2_PL_OUT_awlen       (AXI_NOC_2_PL_awlen),
      .M_AXI_NOC_2_PL_OUT_awlock      (AXI_NOC_2_PL_awlock),
      .M_AXI_NOC_2_PL_OUT_awprot      (AXI_NOC_2_PL_awprot),
      .M_AXI_NOC_2_PL_OUT_awqos       (AXI_NOC_2_PL_awqos),
      .M_AXI_NOC_2_PL_OUT_awready     (AXI_NOC_2_PL_awready),
      .M_AXI_NOC_2_PL_OUT_awregion    (AXI_NOC_2_PL_awregion),
      .M_AXI_NOC_2_PL_OUT_awsize      (AXI_NOC_2_PL_awsize),
      .M_AXI_NOC_2_PL_OUT_awuser      (AXI_NOC_2_PL_awuser),
      .M_AXI_NOC_2_PL_OUT_awvalid     (AXI_NOC_2_PL_awvalid),
      .M_AXI_NOC_2_PL_OUT_bid         (AXI_NOC_2_PL_bid),
      .M_AXI_NOC_2_PL_OUT_bready      (AXI_NOC_2_PL_bready),
      .M_AXI_NOC_2_PL_OUT_bresp       (AXI_NOC_2_PL_bresp),
      .M_AXI_NOC_2_PL_OUT_bvalid      (AXI_NOC_2_PL_bvalid),
      .M_AXI_NOC_2_PL_OUT_rdata       (AXI_NOC_2_PL_rdata),
      .M_AXI_NOC_2_PL_OUT_rid         (AXI_NOC_2_PL_rid),
      .M_AXI_NOC_2_PL_OUT_rlast       (AXI_NOC_2_PL_rlast),
      .M_AXI_NOC_2_PL_OUT_rready      (AXI_NOC_2_PL_rready),
      .M_AXI_NOC_2_PL_OUT_rresp       (AXI_NOC_2_PL_rresp),
      .M_AXI_NOC_2_PL_OUT_rvalid      (AXI_NOC_2_PL_rvalid),
      .M_AXI_NOC_2_PL_OUT_wdata       (AXI_NOC_2_PL_wdata),
      .M_AXI_NOC_2_PL_OUT_wid         (AXI_NOC_2_PL_wid),
      .M_AXI_NOC_2_PL_OUT_wlast       (AXI_NOC_2_PL_wlast),
      .M_AXI_NOC_2_PL_OUT_wready      (AXI_NOC_2_PL_wready),
      .M_AXI_NOC_2_PL_OUT_wstrb       (AXI_NOC_2_PL_wstrb),
      .M_AXI_NOC_2_PL_OUT_wvalid      (AXI_NOC_2_PL_wvalid),

      .S_AXI_NOC_2_PL_IN_araddr       (AXI_NOC_2_PL_araddr), 
      .S_AXI_NOC_2_PL_IN_arburst      (AXI_NOC_2_PL_arburst),
      .S_AXI_NOC_2_PL_IN_arcache      (AXI_NOC_2_PL_arcache),
      .S_AXI_NOC_2_PL_IN_arid         (AXI_NOC_2_PL_arid),
      .S_AXI_NOC_2_PL_IN_arlen        (AXI_NOC_2_PL_arlen),
      .S_AXI_NOC_2_PL_IN_arlock       (AXI_NOC_2_PL_arlock),
      .S_AXI_NOC_2_PL_IN_arprot       (AXI_NOC_2_PL_arprot),
      .S_AXI_NOC_2_PL_IN_arqos        (AXI_NOC_2_PL_arqos),
      .S_AXI_NOC_2_PL_IN_arready      (AXI_NOC_2_PL_arready),
                                     //(AXI_NOC_2_PL_arregion
      .S_AXI_NOC_2_PL_IN_arsize       (AXI_NOC_2_PL_arsize),
      .S_AXI_NOC_2_PL_IN_aruser       (AXI_NOC_2_PL_aruser),
      .S_AXI_NOC_2_PL_IN_arvalid      (AXI_NOC_2_PL_arvalid),
      .S_AXI_NOC_2_PL_IN_awaddr       (AXI_NOC_2_PL_awaddr),
      .S_AXI_NOC_2_PL_IN_awburst      (AXI_NOC_2_PL_awburst),
      .S_AXI_NOC_2_PL_IN_awcache      (AXI_NOC_2_PL_awcache),
      .S_AXI_NOC_2_PL_IN_awid         (AXI_NOC_2_PL_awid),
      .S_AXI_NOC_2_PL_IN_awlen        (AXI_NOC_2_PL_awlen),
      .S_AXI_NOC_2_PL_IN_awlock       (AXI_NOC_2_PL_awlock),
      .S_AXI_NOC_2_PL_IN_awprot       (AXI_NOC_2_PL_awprot),
      .S_AXI_NOC_2_PL_IN_awqos        (AXI_NOC_2_PL_awqos),
      .S_AXI_NOC_2_PL_IN_awready      (AXI_NOC_2_PL_awready),
                                      //(AXI_NOC_2_PL_awregion),
      .S_AXI_NOC_2_PL_IN_awsize       (AXI_NOC_2_PL_awsize),
      .S_AXI_NOC_2_PL_IN_awuser       (AXI_NOC_2_PL_awuser),
      .S_AXI_NOC_2_PL_IN_awvalid      (AXI_NOC_2_PL_awvalid),
      .S_AXI_NOC_2_PL_IN_bid          (AXI_NOC_2_PL_bid),
      .S_AXI_NOC_2_PL_IN_bready       (AXI_NOC_2_PL_bready),
      .S_AXI_NOC_2_PL_IN_bresp        (AXI_NOC_2_PL_bresp),
      .S_AXI_NOC_2_PL_IN_bvalid       (AXI_NOC_2_PL_bvalid),
      .S_AXI_NOC_2_PL_IN_rdata        (AXI_NOC_2_PL_rdata),
      .S_AXI_NOC_2_PL_IN_rid          (AXI_NOC_2_PL_rid),
      .S_AXI_NOC_2_PL_IN_rlast        (AXI_NOC_2_PL_rlast),
      .S_AXI_NOC_2_PL_IN_rready       (AXI_NOC_2_PL_rready),
      .S_AXI_NOC_2_PL_IN_rresp        (AXI_NOC_2_PL_rresp),
      .S_AXI_NOC_2_PL_IN_rvalid       (AXI_NOC_2_PL_rvalid),
      .S_AXI_NOC_2_PL_IN_wdata        (AXI_NOC_2_PL_wdata),
                                      //(AXI_NOC_2_PL_wid),
      .S_AXI_NOC_2_PL_IN_wlast        (AXI_NOC_2_PL_wlast),
      .S_AXI_NOC_2_PL_IN_wready       (AXI_NOC_2_PL_wready),
      .S_AXI_NOC_2_PL_IN_wstrb        (AXI_NOC_2_PL_wstrb),
      .S_AXI_NOC_2_PL_IN_wvalid       (AXI_NOC_2_PL_wvalid)
      */
      );




  // XDMA taget application
  qdma_app #(
    .C_M_AXI_ID_WIDTH(C_M_AXI_ID_WIDTH),
    .MAX_DATA_WIDTH(C_DATA_WIDTH),
    .TDEST_BITS(16),
    .TCQ(TCQ)
  ) qdma_app_i (
    .clk(axi_aclk),
    .user_clk(axi_aclk),

    .rst_n(axi_aresetn),
    .user_resetn(axi_aresetn),
    .sys_rst_n(axi_aresetn),

    .soft_reset_n(soft_reset_n),
    .user_lnk_up(user_lnk_up),

      // AXI Lite Master Interface connections
      .s_axil_awaddr  (m_axil_awaddr[31:0]),
      .s_axil_awvalid (m_axil_awvalid),
      .s_axil_awready (m_axil_awready),
      .s_axil_wdata   (m_axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
      .s_axil_wstrb   (m_axil_wstrb[3:0]),
      .s_axil_wvalid  (m_axil_wvalid),
      .s_axil_wready  (m_axil_wready),
      .s_axil_bresp   (m_axil_bresp),
      .s_axil_bvalid  (m_axil_bvalid),
      .s_axil_bready  (m_axil_bready),
      .s_axil_araddr  (m_axil_araddr[31:0]),
      .s_axil_arvalid (m_axil_arvalid),
      .s_axil_arready (m_axil_arready),
      .s_axil_rdata   (m_axil_rdata),   // block ram for AXI Lite is only 31 bits
      .s_axil_rresp   (m_axil_rresp),
      .s_axil_rvalid  (m_axil_rvalid),
      .s_axil_rready  (m_axil_rready),

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

/*
      // AXI Memory Mapped interface
      .s_axi_awid      (m_axi_awid),
      .s_axi_awaddr    (m_axi_awaddr),
      .s_axi_awlen     (m_axi_awlen),
      .s_axi_awsize    (m_axi_awsize),
      .s_axi_awburst   (m_axi_awburst),
      .s_axi_awvalid   (m_axi_awvalid),
      .s_axi_awready   (m_axi_awready),
      .s_axi_wdata     (m_axi_wdata),
      .s_axi_wstrb     (m_axi_wstrb),
      .s_axi_wlast     (m_axi_wlast),
      .s_axi_wvalid    (m_axi_wvalid),
      .s_axi_wready    (m_axi_wready),
      .s_axi_bid       (m_axi_bid),
      .s_axi_bresp     (m_axi_bresp),
      .s_axi_bvalid    (m_axi_bvalid),
      .s_axi_bready    (m_axi_bready),
      .s_axi_arid      (m_axi_arid),
      .s_axi_araddr    (m_axi_araddr),
      .s_axi_arlen     (m_axi_arlen),
      .s_axi_arsize    (m_axi_arsize),
      .s_axi_arburst   (m_axi_arburst),
      .s_axi_arvalid   (m_axi_arvalid),
      .s_axi_arready   (m_axi_arready),
      .s_axi_rid       (m_axi_rid),
      .s_axi_rdata     (m_axi_rdata),
      .s_axi_rresp     (m_axi_rresp),
      .s_axi_rlast     (m_axi_rlast),
      .s_axi_rvalid    (m_axi_rvalid),
      .s_axi_rready    (m_axi_rready),
*/
      .c2h_byp_out_dsc      (c2h_byp_out_dsc),
      .c2h_byp_out_fmt      (c2h_byp_out_fmt),
      .c2h_byp_out_st_mm    (c2h_byp_out_st_mm),
      .c2h_byp_out_dsc_sz   (c2h_byp_out_dsc_sz),
      .c2h_byp_out_qid      (c2h_byp_out_qid),
      .c2h_byp_out_error    (c2h_byp_out_error),
      .c2h_byp_out_func     (c2h_byp_out_func),
      .c2h_byp_out_cidx     (c2h_byp_out_cidx),
      .c2h_byp_out_port_id  (c2h_byp_out_port_id),
      .c2h_byp_out_pfch_tag (c2h_byp_out_pfch_tag),
      .c2h_byp_out_vld      (c2h_byp_out_vld),
      .c2h_byp_out_rdy      (c2h_byp_out_rdy),

      .c2h_byp_in_mm_radr     (c2h_byp_in_mm_radr),
      .c2h_byp_in_mm_wadr     (c2h_byp_in_mm_wadr),
      .c2h_byp_in_mm_len      (c2h_byp_in_mm_len),
      .c2h_byp_in_mm_mrkr_req (c2h_byp_in_mm_mrkr_req),
      .c2h_byp_in_mm_sdi      (c2h_byp_in_mm_sdi),
      .c2h_byp_in_mm_qid      (c2h_byp_in_mm_qid),
      .c2h_byp_in_mm_error    (c2h_byp_in_mm_error),
      .c2h_byp_in_mm_func     (c2h_byp_in_mm_func),
      .c2h_byp_in_mm_cidx     (c2h_byp_in_mm_cidx),
      .c2h_byp_in_mm_port_id  (c2h_byp_in_mm_port_id),
      .c2h_byp_in_mm_at       (c2h_byp_in_mm_at),
      .c2h_byp_in_mm_no_dma   (c2h_byp_in_mm_no_dma),
      .c2h_byp_in_mm_vld      (c2h_byp_in_mm_vld),
      .c2h_byp_in_mm_rdy      (c2h_byp_in_mm_rdy),

      .c2h_byp_in_st_csh_addr    (c2h_byp_in_st_csh_addr),
      .c2h_byp_in_st_csh_qid     (c2h_byp_in_st_csh_qid),
      .c2h_byp_in_st_csh_error   (c2h_byp_in_st_csh_error),
      .c2h_byp_in_st_csh_func    (c2h_byp_in_st_csh_func),
      .c2h_byp_in_st_csh_port_id (c2h_byp_in_st_csh_port_id),
      .c2h_byp_in_st_csh_pfch_tag(c2h_byp_in_st_csh_pfch_tag),
      .c2h_byp_in_st_csh_at      (c2h_byp_in_st_csh_at),
      .c2h_byp_in_st_csh_vld     (c2h_byp_in_st_csh_vld),
      .c2h_byp_in_st_csh_rdy     (c2h_byp_in_st_csh_rdy),

      .h2c_byp_out_dsc      (h2c_byp_out_dsc),
      .h2c_byp_out_fmt      (h2c_byp_out_fmt),
      .h2c_byp_out_st_mm    (h2c_byp_out_st_mm),
      .h2c_byp_out_dsc_sz   (h2c_byp_out_dsc_sz),
      .h2c_byp_out_qid      (h2c_byp_out_qid),
      .h2c_byp_out_error    (h2c_byp_out_error),
      .h2c_byp_out_func     (h2c_byp_out_func),
      .h2c_byp_out_cidx     (h2c_byp_out_cidx),
      .h2c_byp_out_port_id  (h2c_byp_out_port_id),
      .h2c_byp_out_vld      (h2c_byp_out_vld),
      .h2c_byp_out_rdy      (h2c_byp_out_rdy),

      .h2c_byp_in_mm_radr     (h2c_byp_in_mm_radr),
      .h2c_byp_in_mm_wadr     (h2c_byp_in_mm_wadr),
      .h2c_byp_in_mm_len      (h2c_byp_in_mm_len),
      .h2c_byp_in_mm_mrkr_req (h2c_byp_in_mm_mrkr_req),
      .h2c_byp_in_mm_sdi      (h2c_byp_in_mm_sdi),
      .h2c_byp_in_mm_qid      (h2c_byp_in_mm_qid),
      .h2c_byp_in_mm_error    (h2c_byp_in_mm_error),
      .h2c_byp_in_mm_func     (h2c_byp_in_mm_func),
      .h2c_byp_in_mm_cidx     (h2c_byp_in_mm_cidx),
      .h2c_byp_in_mm_port_id  (h2c_byp_in_mm_port_id),
      .h2c_byp_in_mm_at       (h2c_byp_in_mm_at),
      .h2c_byp_in_mm_no_dma   (h2c_byp_in_mm_no_dma),
      .h2c_byp_in_mm_vld      (h2c_byp_in_mm_vld),
      .h2c_byp_in_mm_rdy      (h2c_byp_in_mm_rdy),

      .h2c_byp_in_st_addr     (h2c_byp_in_st_addr),
      .h2c_byp_in_st_len      (h2c_byp_in_st_len),
      .h2c_byp_in_st_eop      (h2c_byp_in_st_eop),
      .h2c_byp_in_st_sop      (h2c_byp_in_st_sop),
      .h2c_byp_in_st_mrkr_req (h2c_byp_in_st_mrkr_req),
      .h2c_byp_in_st_sdi      (h2c_byp_in_st_sdi),
      .h2c_byp_in_st_qid      (h2c_byp_in_st_qid),
      .h2c_byp_in_st_error    (h2c_byp_in_st_error),
      .h2c_byp_in_st_func     (h2c_byp_in_st_func),
      .h2c_byp_in_st_cidx     (h2c_byp_in_st_cidx),
      .h2c_byp_in_st_port_id  (h2c_byp_in_st_port_id),
      .h2c_byp_in_st_at       (h2c_byp_in_st_at),
      .h2c_byp_in_st_no_dma   (h2c_byp_in_st_no_dma),
      .h2c_byp_in_st_vld      (h2c_byp_in_st_vld),
      .h2c_byp_in_st_rdy      (h2c_byp_in_st_rdy),


    .usr_flr_fnc ( usr_flr_fnc ),
    .usr_flr_set ( usr_flr_set ),
    .usr_flr_clr ( usr_flr_clr) ,
    .usr_flr_done_fnc (usr_flr_done_fnc),
    .usr_flr_done_vld (usr_flr_done_vld),


  .m_axis_h2c_tvalid         (m_axis_h2c_tvalid),
  .m_axis_h2c_tready         (m_axis_h2c_tready),
  .m_axis_h2c_tdata          (m_axis_h2c_tdata),
  .m_axis_h2c_tcrc           (m_axis_h2c_tcrc),
  .m_axis_h2c_tlast          (m_axis_h2c_tlast),
  .m_axis_h2c_tuser_qid      (m_axis_h2c_tuser_qid),
  .m_axis_h2c_tuser_port_id  (m_axis_h2c_tuser_port_id),
  .m_axis_h2c_tuser_err      (m_axis_h2c_tuser_err),
  .m_axis_h2c_tuser_mdata    (m_axis_h2c_tuser_mdata),
  .m_axis_h2c_tuser_mty      (m_axis_h2c_tuser_mty),
  .m_axis_h2c_tuser_zero_byte(m_axis_h2c_tuser_zero_byte),

  .s_axis_c2h_tdata          (s_axis_c2h_tdata ),
  .s_axis_c2h_tcrc           (s_axis_c2h_tcrc  ),
  .s_axis_c2h_ctrl_marker    (s_axis_c2h_ctrl_marker),
  .s_axis_c2h_ctrl_len       (s_axis_c2h_ctrl_len), // c2h_st_len,
  .s_axis_c2h_ctrl_port_id   (s_axis_c2h_ctrl_port_id),
  .s_axis_c2h_ctrl_ecc       (s_axis_c2h_ctrl_ecc),
  .s_axis_c2h_ctrl_qid       (s_axis_c2h_ctrl_qid ), // st_qid,
  .s_axis_c2h_ctrl_has_cmpt  (s_axis_c2h_ctrl_has_cmpt),   // write back is valid
  .s_axis_c2h_tvalid         (s_axis_c2h_tvalid),
  .s_axis_c2h_tready         (s_axis_c2h_tready),
  .s_axis_c2h_tlast          (s_axis_c2h_tlast ),
  .s_axis_c2h_mty            (s_axis_c2h_mty ),  // no empthy bytes at EOP

  .s_axis_c2h_cmpt_tdata               (s_axis_c2h_cmpt_tdata),
  .s_axis_c2h_cmpt_size                (s_axis_c2h_cmpt_size),
  .s_axis_c2h_cmpt_dpar                (s_axis_c2h_cmpt_dpar),
  .s_axis_c2h_cmpt_tvalid              (s_axis_c2h_cmpt_tvalid),
  .s_axis_c2h_cmpt_tready              (s_axis_c2h_cmpt_tready),
  .s_axis_c2h_cmpt_ctrl_qid            (s_axis_c2h_cmpt_ctrl_qid),
  .s_axis_c2h_cmpt_ctrl_cmpt_type      (s_axis_c2h_cmpt_ctrl_cmpt_type),
  .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id(s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
  .s_axis_c2h_cmpt_ctrl_marker         (s_axis_c2h_cmpt_ctrl_marker),
  .s_axis_c2h_cmpt_ctrl_user_trig      (s_axis_c2h_cmpt_ctrl_user_trig),
  .s_axis_c2h_cmpt_ctrl_col_idx        (s_axis_c2h_cmpt_ctrl_col_idx),
  .s_axis_c2h_cmpt_ctrl_err_idx        (s_axis_c2h_cmpt_ctrl_err_idx),

  .axis_c2h_status_drop                (axis_c2h_status_drop),
  .axis_c2h_status_valid               (axis_c2h_status_valid),
  .axis_c2h_status_qid                 (axis_c2h_status_qid),
  .axis_c2h_status_last                (axis_c2h_status_last),
  .axis_c2h_status_cmp                 (axis_c2h_status_cmp),
  .axis_c2h_status_error               (axis_c2h_status_error),
  
  .axis_c2h_dmawr_cmp                  (axis_c2h_dmawr_cmp), 
  .axis_c2h_dmawr_port_id              (axis_c2h_dmawr_port_id),

		
  .qsts_out_op      (qsts_out_op),
  .qsts_out_data    (qsts_out_data),
  .qsts_out_port_id (qsts_out_port_id),
  .qsts_out_qid     (qsts_out_qid),
  .qsts_out_vld     (qsts_out_vld),
  .qsts_out_rdy     (qsts_out_rdy),

  .usr_irq_in_vld   (usr_irq_in_vld),
  .usr_irq_in_vec   (usr_irq_in_vec),
  .usr_irq_in_fnc   (usr_irq_in_fnc),
  .usr_irq_out_ack  (usr_irq_out_ack),
  .usr_irq_out_fail (usr_irq_out_fail),

  .st_rx_msg_rdy   (st_rx_msg_rdy),
  .st_rx_msg_valid (st_rx_msg_valid),
  .st_rx_msg_last  (st_rx_msg_last),
  .st_rx_msg_data  (st_rx_msg_data),

  .tm_dsc_sts_vld     (tm_dsc_sts_vld   ),
  .tm_dsc_sts_qen     (tm_dsc_sts_qen   ),
  .tm_dsc_sts_byp     (tm_dsc_sts_byp   ),
  .tm_dsc_sts_dir     (tm_dsc_sts_dir   ),
  .tm_dsc_sts_mm      (tm_dsc_sts_mm    ),
  .tm_dsc_sts_error   (tm_dsc_sts_error ),
  .tm_dsc_sts_qid     (tm_dsc_sts_qid   ),
  .tm_dsc_sts_avl     (tm_dsc_sts_avl   ),
  .tm_dsc_sts_qinv    (tm_dsc_sts_qinv  ),
  .tm_dsc_sts_irq_arm (tm_dsc_sts_irq_arm),
  .tm_dsc_sts_rdy     (tm_dsc_sts_rdy),

  .dsc_crdt_in_vld        (dsc_crdt_in_vld),
  .dsc_crdt_in_rdy        (dsc_crdt_in_rdy),
  .dsc_crdt_in_dir        (dsc_crdt_in_dir),
  .dsc_crdt_in_fence      (dsc_crdt_in_fence),
  .dsc_crdt_in_qid        (dsc_crdt_in_qid),
  .dsc_crdt_in_crdt       (dsc_crdt_in_crdt),


      .leds(leds)

  );

endmodule

