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
    parameter C_DEVICE_NUMBER             = 0        // Device number for Root Port configurations only
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
   // Local Parameters derived from user selection
   localparam integer  USER_CLK_FREQ          = ((PL_LINK_CAP_MAX_LINK_SPEED == 3'h4) ? 5 : 4);
   localparam          TCQ                    = 1;
   localparam          C_S_AXI_ID_WIDTH       = 4; 
   localparam          C_M_AXI_ID_WIDTH       = 4; 
   localparam          C_S_AXI_DATA_WIDTH     = C_DATA_WIDTH;
   localparam          C_M_AXI_DATA_WIDTH     = C_DATA_WIDTH;
   localparam          C_S_AXI_ADDR_WIDTH     = 64;
   localparam          C_M_AXI_ADDR_WIDTH     = 64;
   localparam          C_NUM_USR_IRQ          = 16;
   localparam          MULTQ_EN               = 1;
   localparam          CRC_WIDTH              = 32;
   localparam          C_DSC_MAGIC_EN         = 1;
   localparam          C_H2C_NUM_RIDS         = 64;
   localparam          C_H2C_NUM_CHNL         = MULTQ_EN ? 4 : 4;
   localparam          C_C2H_NUM_CHNL         = MULTQ_EN ? 4 : 4;
   localparam          C_C2H_NUM_RIDS         = 32;
   localparam          C_NUM_PCIE_TAGS        = 256;
   localparam          C_S_AXI_NUM_READ       = 32;
   localparam          C_S_AXI_NUM_WRITE      = 8;
   localparam          C_C2H_TUSER_WIDTH      = 64;
   localparam          C_MDMA_DSC_IN_NUM_CHNL = 3;   // only 2 interface are used. 0 is for MM and 2 is for ST. 1 is not used
   localparam          C_MAX_NUM_QUEUE        = 128;
   localparam          TM_DSC_BITS            = 16;
   
   localparam          C_DATA_WIDTH_ST        = C_DATA_WIDTH; // Note that the internal DMA pin is fixed at 512-bit (XDMA Fab Demux)
   localparam          QID_MAX                = 256;
   localparam          C_CNTR_WIDTH           = 64;           // Performance counter bit width

  //----------------------------------------------------------------------------------------------------------------//
  //  AXI Interface                                                                                                 //
  //----------------------------------------------------------------------------------------------------------------//
  wire user_clk;
  wire axi_aresetn;
  wire                phy_ready; // Not currently used

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
  wire [C_M_AXI_DATA_WIDTH-1:0]     m_axi_wdata;
  wire [(C_M_AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb;
  wire                              m_axi_wlast;
  wire                              m_axi_wvalid;
  wire                              m_axi_wready;

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
  
//////////////////////////////////////////////////  LITE
  //-- AXI Master Write Address Channel
  wire [31:0] dma0_m_axil_awaddr;
  wire [2:0]  dma0_m_axil_awprot;
  wire        dma0_m_axil_awvalid;
  wire        dma0_m_axil_awready;

  //-- AXI Master Write Data Channel
  wire [31:0] dma0_m_axil_wdata;
  wire [3:0]  dma0_m_axil_wstrb;
  wire        dma0_m_axil_wvalid;
  wire        dma0_m_axil_wready;

  //-- AXI Master Write Response Channel
  wire        dma0_m_axil_bvalid;
  wire        dma0_m_axil_bready;

  //-- AXI Master Read Address Channel
  wire [31:0] dma0_m_axil_araddr;
  wire [2:0]  dma0_m_axil_arprot;
  wire        dma0_m_axil_arvalid;
  wire        dma0_m_axil_arready;

  //-- AXI Master Read Data Channel
  wire [31:0] dma0_m_axil_rdata_bram;
  wire [31:0] dma0_m_axil_rdata;
  wire [1:0]  dma0_m_axil_rresp;
  wire        dma0_m_axil_rvalid;
  wire        dma0_m_axil_rready;
  wire [1:0]  dma0_m_axil_bresp;
  //////////////////////////////////////////////////  LITE 1
  //-- AXI Master Write Address Channel
  wire [31:0] dma1_m_axil_awaddr;
  wire [2:0]  dma1_m_axil_awprot;
  wire        dma1_m_axil_awvalid;
  wire        dma1_m_axil_awready;

  //-- AXI Master Write Data Channel
  wire [31:0] dma1_m_axil_wdata;
  wire [3:0]  dma1_m_axil_wstrb;
  wire        dma1_m_axil_wvalid;
  wire        dma1_m_axil_wready;

  //-- AXI Master Write Response Channel
  wire        dma1_m_axil_bvalid;
  wire        dma1_m_axil_bready;

  //-- AXI Master Read Address Channel
  wire [31:0] dma1_m_axil_araddr;
  wire [2:0]  dma1_m_axil_arprot;
  wire        dma1_m_axil_arvalid;
  wire        dma1_m_axil_arready;

  //-- AXI Master Read Data Channel
  wire [31:0] dma1_m_axil_rdata_bram;
  wire [31:0] dma1_m_axil_rdata;
  wire [1:0]  dma1_m_axil_rresp;
  wire        dma1_m_axil_rvalid;
  wire        dma1_m_axil_rready;
  wire [1:0]  dma1_m_axil_bresp;

  // MDMA signals
  wire   [C_DATA_WIDTH-1:0]   dma0_m_axis_h2c_tdata;
  wire   [CRC_WIDTH-1:0]      dma0_m_axis_h2c_tcrc; //TBD
  wire   [11:0]               dma0_m_axis_h2c_tuser_qid;
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
  wire [C_DATA_WIDTH-1:0]     dma0_s_axis_c2h_tdata;
  wire [CRC_WIDTH-1:0]        dma0_s_axis_c2h_tcrc;
  wire                        dma0_s_axis_c2h_ctrl_marker;
  wire [6:0]                  dma0_s_axis_c2h_ctrl_ecc;
  wire [15:0]                 dma0_s_axis_c2h_ctrl_len;
  wire [2:0]                  dma0_s_axis_c2h_ctrl_port_id;
  wire [11:0]                 dma0_s_axis_c2h_ctrl_qid ;
  wire                        dma0_s_axis_c2h_ctrl_has_cmpt ;
  wire                        dma0_s_axis_c2h_tvalid;
  wire                        dma0_s_axis_c2h_tready;
  wire                        dma0_s_axis_c2h_tlast;
  wire  [5:0]                 dma0_s_axis_c2h_mty;

  // AXIS C2H tuser wire
   wire [511:0] 	                dma0_s_axis_c2h_cmpt_tdata;
  wire  [1:0]  dma0_s_axis_c2h_cmpt_size;
  wire  [15:0] dma0_s_axis_c2h_cmpt_dpar;
  wire         dma0_s_axis_c2h_cmpt_tvalid;
  wire         dma0_s_axis_c2h_cmpt_tready;
  wire [11:0]	dma0_s_axis_c2h_cmpt_ctrl_qid;
  wire [1:0]	dma0_s_axis_c2h_cmpt_ctrl_cmpt_type;
  wire [15:0]	dma0_s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
  wire 	dma0_s_axis_c2h_cmpt_ctrl_marker;
  wire 	dma0_s_axis_c2h_cmpt_ctrl_user_trig;
  wire [2:0]	dma0_s_axis_c2h_cmpt_ctrl_col_idx;
  wire [2:0]	dma0_s_axis_c2h_cmpt_ctrl_err_idx;

    wire          dma0_tm_dsc_sts_vld;
    wire          dma0_tm_dsc_sts_qen;
    wire          dma0_tm_dsc_sts_byp;
    wire          dma0_tm_dsc_sts_dir;
    wire          dma0_tm_dsc_sts_mm;
    wire          dma0_tm_dsc_sts_error;
    wire  [11:0]  dma0_tm_dsc_sts_qid;
    wire  [15:0]  dma0_tm_dsc_sts_avl;
    wire          dma0_tm_dsc_sts_qinv;
    wire          dma0_tm_dsc_sts_irq_arm;
    wire          dma0_tm_dsc_sts_rdy;

  // Descriptor credit In
  wire          dma0_dsc_crdt_in_vld;
  wire          dma0_dsc_crdt_in_rdy;
  wire          dma0_dsc_crdt_in_dir;
  wire          dma0_dsc_crdt_in_fence;
  wire [11:0]   dma0_dsc_crdt_in_qid;
  wire [15:0]   dma0_dsc_crdt_in_crdt;

 // Report the DROP case
    wire          dma0_axis_c2h_status_drop;
    wire          dma0_axis_c2h_status_last;
    wire          dma0_axis_c2h_status_valid;
    wire          dma0_axis_c2h_status_cmp;
    wire          dma0_axis_c2h_status_error;
    wire [11:0]   dma0_axis_c2h_status_qid;

    wire [7:0]    dma0_qsts_out_op;
    wire [63:0]   dma0_qsts_out_data;
    wire [2:0]    dma0_qsts_out_port_id;
    wire [12:0]   dma0_qsts_out_qid;
    wire          dma0_qsts_out_vld;
    wire          dma0_qsts_out_rdy;

    wire          dma0_st_rx_msg_rdy;
    wire          dma0_st_rx_msg_valid;
    wire          dma0_st_rx_msg_last;
    wire [31:0]   dma0_st_rx_msg_data;

   

  // Descriptor Bypass Out for qdma
  wire  [255:0] dma0_h2c_byp_out_dsc;
  wire  [3:0]   dma0_h2c_byp_out_fmt;
  wire          dma0_h2c_byp_out_st_mm;
  wire  [11:0]  dma0_h2c_byp_out_qid;
  wire  [1:0]   dma0_h2c_byp_out_dsc_sz;
  wire          dma0_h2c_byp_out_error;
  wire  [11:0]  dma0_h2c_byp_out_func;
  wire  [15:0]  dma0_h2c_byp_out_cidx;
  wire  [2:0]   dma0_h2c_byp_out_port_id;
  wire          dma0_h2c_byp_out_vld;
  wire          dma0_h2c_byp_out_rdy;

  wire  [255:0] dma0_c2h_byp_out_dsc;
  wire  [3:0]   dma0_c2h_byp_out_fmt;
  wire          dma0_c2h_byp_out_st_mm;
  wire  [1:0]   dma0_c2h_byp_out_dsc_sz;
  wire  [11:0]  dma0_c2h_byp_out_qid;
  wire          dma0_c2h_byp_out_error;
  wire  [11:0]  dma0_c2h_byp_out_func;
  wire  [15:0]  dma0_c2h_byp_out_cidx;
  wire  [2:0]   dma0_c2h_byp_out_port_id;
  wire  [6:0]   dma0_c2h_byp_out_pfch_tag;
  wire          dma0_c2h_byp_out_vld;
  wire          dma0_c2h_byp_out_rdy;


   assign c2h_byp_out_pfch_tag ='h0;
   
  // Descriptor Bypass In for qdma MM
  wire  [63:0]  dma0_h2c_byp_in_mm_radr;
  wire  [63:0]  dma0_h2c_byp_in_mm_wadr;
  wire  [15:0]  dma0_h2c_byp_in_mm_len;
  wire          dma0_h2c_byp_in_mm_mrkr_req;
  wire          dma0_h2c_byp_in_mm_sdi;
  wire  [11:0]  dma0_h2c_byp_in_mm_qid;
  wire          dma0_h2c_byp_in_mm_error;
  wire  [11:0]  dma0_h2c_byp_in_mm_func;
  wire  [15:0]  dma0_h2c_byp_in_mm_cidx;
  wire  [2:0]   dma0_h2c_byp_in_mm_port_id;
  wire  [1:0]   dma0_h2c_byp_in_mm_at;
  wire          dma0_h2c_byp_in_mm_no_dma;
  wire          dma0_h2c_byp_in_mm_vld;
  wire          dma0_h2c_byp_in_mm_rdy;

  wire  [63:0]  dma0_c2h_byp_in_mm_radr;
  wire  [63:0]  dma0_c2h_byp_in_mm_wadr;
  wire  [15:0]  dma0_c2h_byp_in_mm_len;
  wire          dma0_c2h_byp_in_mm_mrkr_req;
  wire          dma0_c2h_byp_in_mm_sdi;
  wire  [11:0]  dma0_c2h_byp_in_mm_qid;
  wire          dma0_c2h_byp_in_mm_error;
  wire  [11:0]  dma0_c2h_byp_in_mm_func;
  wire  [15:0]  dma0_c2h_byp_in_mm_cidx;
  wire  [2:0]   dma0_c2h_byp_in_mm_port_id;
  wire  [1:0]   dma0_c2h_byp_in_mm_at;
  wire          dma0_c2h_byp_in_mm_no_dma;
  wire          dma0_c2h_byp_in_mm_vld;
  wire          dma0_c2h_byp_in_mm_rdy;

  // Descriptor Bypass In for qdma ST
  wire [63:0]   dma0_h2c_byp_in_st_addr;
  wire [15:0]   dma0_h2c_byp_in_st_len;
  wire          dma0_h2c_byp_in_st_eop;
  wire          dma0_h2c_byp_in_st_sop;
  wire          dma0_h2c_byp_in_st_mrkr_req;
  wire          dma0_h2c_byp_in_st_sdi;
  wire  [11:0]  dma0_h2c_byp_in_st_qid;
  wire          dma0_h2c_byp_in_st_error;
  wire  [11:0]  dma0_h2c_byp_in_st_func;
  wire  [15:0]  dma0_h2c_byp_in_st_cidx;
  wire  [2:0]   dma0_h2c_byp_in_st_port_id;
  wire  [1:0]   dma0_h2c_byp_in_st_at;
  wire          dma0_h2c_byp_in_st_no_dma;
  wire          dma0_h2c_byp_in_st_vld;
  wire          dma0_h2c_byp_in_st_rdy;

  wire  [63:0]  dma0_c2h_byp_in_st_csh_addr;
  wire  [11:0]  dma0_c2h_byp_in_st_csh_qid;
  wire          dma0_c2h_byp_in_st_csh_error;
  wire  [11:0]  dma0_c2h_byp_in_st_csh_func;
  wire  [2:0]   dma0_c2h_byp_in_st_csh_port_id;
  wire  [6:0]   dma0_c2h_byp_in_st_csh_pfch_tag;
  wire  [1:0]   dma0_c2h_byp_in_st_csh_at;
  wire          dma0_c2h_byp_in_st_csh_vld;
  wire          dma0_c2h_byp_in_st_csh_rdy;
  // FLR
  wire [11:0] dma0_usr_flr_fnc;
  wire        dma0_usr_flr_set;
  wire        dma0_usr_flr_clr;
  wire [11:0] dma0_usr_flr_done_fnc;
  wire        dma0_usr_flr_done_vld;
  wire          dma0_usr_irq_in_vld;
  wire [10 : 0] dma0_usr_irq_in_vec;
  wire [11 : 0] dma0_usr_irq_in_fnc;
  wire          dma0_usr_irq_out_ack;
  wire          dma0_usr_irq_out_fail;



  // DMA1 signals
  wire   [C_DATA_WIDTH-1:0]   dma1_m_axis_h2c_tdata;
  wire   [CRC_WIDTH-1:0]      dma1_m_axis_h2c_tcrc;
  wire   [11:0]               dma1_m_axis_h2c_tuser_qid;
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
  wire [C_DATA_WIDTH-1:0]     dma1_s_axis_c2h_tdata;
  wire [CRC_WIDTH-1:0]        dma1_s_axis_c2h_tcrc;
  wire                        dma1_s_axis_c2h_ctrl_marker;
  wire [6:0]                  dma1_s_axis_c2h_ctrl_ecc;
  wire [15:0]                 dma1_s_axis_c2h_ctrl_len;
  wire [2:0]                  dma1_s_axis_c2h_ctrl_port_id;
  wire [11:0]                 dma1_s_axis_c2h_ctrl_qid ;
  wire                        dma1_s_axis_c2h_ctrl_has_cmpt ;
  wire                        dma1_s_axis_c2h_tvalid;
  wire                        dma1_s_axis_c2h_tready;
  wire                        dma1_s_axis_c2h_tlast;
  wire  [5:0]                 dma1_s_axis_c2h_mty;

  // AXIS C2H tuser wire
   wire [511:0] 	                dma1_s_axis_c2h_cmpt_tdata;
  wire  [1:0]  dma1_s_axis_c2h_cmpt_size;
  wire  [15:0] dma1_s_axis_c2h_cmpt_dpar;
  wire         dma1_s_axis_c2h_cmpt_tvalid;
  wire         dma1_s_axis_c2h_cmpt_tready;
  wire [11:0]	dma1_s_axis_c2h_cmpt_ctrl_qid;
  wire [1:0]	dma1_s_axis_c2h_cmpt_ctrl_cmpt_type;
  wire [15:0]	dma1_s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
  wire 	dma1_s_axis_c2h_cmpt_ctrl_marker;
  wire 	dma1_s_axis_c2h_cmpt_ctrl_user_trig;
  wire [2:0]	dma1_s_axis_c2h_cmpt_ctrl_col_idx;
  wire [2:0]	dma1_s_axis_c2h_cmpt_ctrl_err_idx;

  // Descriptor Bypass Out for qdma
  wire  [255:0] dma1_h2c_byp_out_dsc;
  wire  [3:0]   dma1_h2c_byp_out_fmt;
  wire  [4:0]   dma1_h2c_byp_out_cnt;
  wire          dma1_h2c_byp_out_st_mm;
  wire  [11:0]  dma1_h2c_byp_out_qid;
  wire  [1:0]   dma1_h2c_byp_out_dsc_sz;
  wire          dma1_h2c_byp_out_error;
  wire  [11:0]  dma1_h2c_byp_out_func;
  wire  [15:0]  dma1_h2c_byp_out_cidx;
  wire  [2:0]   dma1_h2c_byp_out_port_id;
  wire          dma1_h2c_byp_out_vld;
  wire          dma1_h2c_byp_out_rdy;

  wire  [255:0] dma1_c2h_byp_out_dsc;
  wire  [3:0]   dma1_c2h_byp_out_fmt;
  wire  [4:0]   dma1_c2h_byp_out_cnt;
  wire          dma1_c2h_byp_out_st_mm;
  wire  [1:0]   dma1_c2h_byp_out_dsc_sz;
  wire  [11:0]  dma1_c2h_byp_out_qid;
  wire          dma1_c2h_byp_out_error;
  wire  [11:0]  dma1_c2h_byp_out_func;
  wire  [15:0]  dma1_c2h_byp_out_cidx;
  wire  [2:0]   dma1_c2h_byp_out_port_id;
  wire  [6:0]   dma1_c2h_byp_out_pfch_tag;
  wire          dma1_c2h_byp_out_vld;
  wire          dma1_c2h_byp_out_rdy;


   assign c2h_byp_out_pfch_tag ='h0;
   
  // Descriptor Bypass In for qdma MM
  wire  [63:0]  dma1_h2c_byp_in_mm_radr;
  wire  [63:0]  dma1_h2c_byp_in_mm_wadr;
  wire  [15:0]  dma1_h2c_byp_in_mm_len;
  wire          dma1_h2c_byp_in_mm_mrkr_req;
  wire          dma1_h2c_byp_in_mm_sdi;
  wire  [11:0]  dma1_h2c_byp_in_mm_qid;
  wire          dma1_h2c_byp_in_mm_error;
  wire  [11:0]  dma1_h2c_byp_in_mm_func;
  wire  [15:0]  dma1_h2c_byp_in_mm_cidx;
  wire  [2:0]   dma1_h2c_byp_in_mm_port_id;
  wire  [1:0]   dma1_h2c_byp_in_mm_at;
  wire          dma1_h2c_byp_in_mm_no_dma;
  wire          dma1_h2c_byp_in_mm_vld;
  wire          dma1_h2c_byp_in_mm_rdy;

  wire  [63:0]  dma1_c2h_byp_in_mm_radr;
  wire  [63:0]  dma1_c2h_byp_in_mm_wadr;
  wire  [15:0]  dma1_c2h_byp_in_mm_len;
  wire          dma1_c2h_byp_in_mm_mrkr_req;
  wire          dma1_c2h_byp_in_mm_sdi;
  wire  [11:0]  dma1_c2h_byp_in_mm_qid;
  wire          dma1_c2h_byp_in_mm_error;
  wire  [11:0]  dma1_c2h_byp_in_mm_func;
  wire  [15:0]  dma1_c2h_byp_in_mm_cidx;
  wire  [2:0]   dma1_c2h_byp_in_mm_port_id;
  wire  [1:0]   dma1_c2h_byp_in_mm_at;
  wire          dma1_c2h_byp_in_mm_no_dma;
  wire          dma1_c2h_byp_in_mm_vld;
  wire          dma1_c2h_byp_in_mm_rdy;

  // Descriptor Bypass In for qdma ST
  wire [63:0]   dma1_h2c_byp_in_st_addr;
  wire [15:0]   dma1_h2c_byp_in_st_len;
  wire          dma1_h2c_byp_in_st_eop;
  wire          dma1_h2c_byp_in_st_sop;
  wire          dma1_h2c_byp_in_st_mrkr_req;
  wire          dma1_h2c_byp_in_st_sdi;
  wire  [11:0]  dma1_h2c_byp_in_st_qid;
  wire          dma1_h2c_byp_in_st_error;
  wire  [11:0]  dma1_h2c_byp_in_st_func;
  wire  [15:0]  dma1_h2c_byp_in_st_cidx;
  wire  [2:0]   dma1_h2c_byp_in_st_port_id;
  wire  [1:0]   dma1_h2c_byp_in_st_at;
  wire          dma1_h2c_byp_in_st_no_dma;
  wire          dma1_h2c_byp_in_st_vld;
  wire          dma1_h2c_byp_in_st_rdy;

  wire  [63:0]  dma1_c2h_byp_in_st_csh_addr;
  wire  [11:0]  dma1_c2h_byp_in_st_csh_qid;
  wire          dma1_c2h_byp_in_st_csh_error;
  wire  [11:0]  dma1_c2h_byp_in_st_csh_func;
  wire  [2:0]   dma1_c2h_byp_in_st_csh_port_id;
  wire  [6:0]   dma1_c2h_byp_in_st_csh_pfch_tag;
  wire  [1:0]   dma1_c2h_byp_in_st_csh_at;
  wire          dma1_c2h_byp_in_st_csh_vld;
  wire          dma1_c2h_byp_in_st_csh_rdy;

  wire          dma1_usr_irq_in_vld;
  wire [10 : 0] dma1_usr_irq_in_vec;
  wire [11 : 0] dma1_usr_irq_in_fnc;
  wire          dma1_usr_irq_out_ack;
  wire          dma1_usr_irq_out_fail;

    wire          dma1_st_rx_msg_rdy;
    wire          dma1_st_rx_msg_valid;
    wire          dma1_st_rx_msg_last;
    wire [31:0]   dma1_st_rx_msg_data;

    wire          dma1_tm_dsc_sts_vld;
    wire          dma1_tm_dsc_sts_qen;
    wire          dma1_tm_dsc_sts_byp;
    wire          dma1_tm_dsc_sts_dir;
    wire          dma1_tm_dsc_sts_mm;
    wire          dma1_tm_dsc_sts_error;
    wire  [11:0]  dma1_tm_dsc_sts_qid;
    wire  [15:0]  dma1_tm_dsc_sts_avl;
    wire          dma1_tm_dsc_sts_qinv;
    wire          dma1_tm_dsc_sts_irq_arm;
    wire          dma1_tm_dsc_sts_rdy;

  // Descriptor credit In
  wire          dma1_dsc_crdt_in_vld;
  wire          dma1_dsc_crdt_in_rdy;
  wire          dma1_dsc_crdt_in_dir;
  wire          dma1_dsc_crdt_in_fence;
  wire [11:0]   dma1_dsc_crdt_in_qid;
  wire [15:0]   dma1_dsc_crdt_in_crdt;

  // Report the DROP case
    wire          dma1_axis_c2h_status_drop;
    wire          dma1_axis_c2h_status_last;
    wire          dma1_axis_c2h_status_valid;
    wire          dma1_axis_c2h_status_cmp;
    wire          dma1_axis_c2h_status_error;
    wire [11:0]   dma1_axis_c2h_status_qid;
    wire [7:0]    dma1_qsts_out_op;
    wire [63:0]   dma1_qsts_out_data;
    wire [2:0]    dma1_qsts_out_port_id;
    wire [12:0]   dma1_qsts_out_qid;
    wire          dma1_qsts_out_vld;
    wire          dma1_qsts_out_rdy;

  // FLR
  wire [11:0] dma1_usr_flr_fnc;
  wire        dma1_usr_flr_set;
  wire        dma1_usr_flr_clr;
  wire [11:0] dma1_usr_flr_done_fnc;
  wire        dma1_usr_flr_done_vld;
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
      .M_AXIL_0_araddr  (dma0_m_axil_araddr),
      .M_AXIL_0_arprot  (dma0_m_axil_arprot),
      .M_AXIL_0_arready (dma0_m_axil_arready),
      .M_AXIL_0_arvalid (dma0_m_axil_arvalid),
      .M_AXIL_0_awaddr  (dma0_m_axil_awaddr),
      .M_AXIL_0_awprot  (dma0_m_axil_awprot),
      .M_AXIL_0_awready (dma0_m_axil_awready),
      .M_AXIL_0_awvalid (dma0_m_axil_awvalid),
      .M_AXIL_0_bready  (dma0_m_axil_bready),
      .M_AXIL_0_bresp   (dma0_m_axil_bresp),
      .M_AXIL_0_bvalid  (dma0_m_axil_bvalid),
      .M_AXIL_0_rdata   (dma0_m_axil_rdata),
      .M_AXIL_0_rready  (dma0_m_axil_rready),
      .M_AXIL_0_rresp   (dma0_m_axil_rresp),
      .M_AXIL_0_rvalid  (dma0_m_axil_rvalid),
      .M_AXIL_0_wdata   (dma0_m_axil_wdata),
      .M_AXIL_0_wready  (dma0_m_axil_wready),
      .M_AXIL_0_wstrb   (dma0_m_axil_wstrb),
      .M_AXIL_0_wvalid  (dma0_m_axil_wvalid),

      .S_AXIL_0_araddr  (dma0_m_axil_araddr[11:0]),
      .S_AXIL_0_arprot  (dma0_m_axil_arprot),
      .S_AXIL_0_arready (dma0_m_axil_arready),
      .S_AXIL_0_arvalid (dma0_m_axil_arvalid),
      .S_AXIL_0_awaddr  (dma0_m_axil_awaddr[11:0]),
      .S_AXIL_0_awprot  (dma0_m_axil_awprot),
      .S_AXIL_0_awready (dma0_m_axil_awready),
      .S_AXIL_0_awvalid (dma0_m_axil_awvalid),
      .S_AXIL_0_bready  (dma0_m_axil_bready),
      .S_AXIL_0_bresp   (dma0_m_axil_bresp),
      .S_AXIL_0_bvalid  (dma0_m_axil_bvalid),
      .S_AXIL_0_rdata   (dma0_m_axil_rdata_bram),
      .S_AXIL_0_rready  (dma0_m_axil_rready),
      .S_AXIL_0_rresp   (dma0_m_axil_rresp),
      .S_AXIL_0_rvalid  (dma0_m_axil_rvalid),
      .S_AXIL_0_wdata   (dma0_m_axil_wdata),
      .S_AXIL_0_wready  (dma0_m_axil_wready),
      .S_AXIL_0_wstrb   (dma0_m_axil_wstrb),
      .S_AXIL_0_wvalid  (dma0_m_axil_wvalid),


// Lite 1      
      .M_AXIL_1_araddr  (dma1_m_axil_araddr),
      .M_AXIL_1_arprot  (dma1_m_axil_arprot),
      .M_AXIL_1_arready (dma1_m_axil_arready),
      .M_AXIL_1_arvalid (dma1_m_axil_arvalid),
      .M_AXIL_1_awaddr  (dma1_m_axil_awaddr),
      .M_AXIL_1_awprot  (dma1_m_axil_awprot),
      .M_AXIL_1_awready (dma1_m_axil_awready),
      .M_AXIL_1_awvalid (dma1_m_axil_awvalid),
      .M_AXIL_1_bready  (dma1_m_axil_bready),
      .M_AXIL_1_bresp   (dma1_m_axil_bresp),
      .M_AXIL_1_bvalid  (dma1_m_axil_bvalid),
      .M_AXIL_1_rdata   (dma1_m_axil_rdata),
      .M_AXIL_1_rready  (dma1_m_axil_rready),
      .M_AXIL_1_rresp   (dma1_m_axil_rresp),
      .M_AXIL_1_rvalid  (dma1_m_axil_rvalid),
      .M_AXIL_1_wdata   (dma1_m_axil_wdata),
      .M_AXIL_1_wready  (dma1_m_axil_wready),
      .M_AXIL_1_wstrb   (dma1_m_axil_wstrb),
      .M_AXIL_1_wvalid  (dma1_m_axil_wvalid),
      
      .S_AXIL_1_araddr  (dma1_m_axil_araddr[11:0]),
      .S_AXIL_1_arprot  (dma1_m_axil_arprot),
      .S_AXIL_1_arready (dma1_m_axil_arready),
      .S_AXIL_1_arvalid (dma1_m_axil_arvalid),
      .S_AXIL_1_awaddr  (dma1_m_axil_awaddr[11:0]),
      .S_AXIL_1_awprot  (dma1_m_axil_awprot),
      .S_AXIL_1_awready (dma1_m_axil_awready),
      .S_AXIL_1_awvalid (dma1_m_axil_awvalid),
      .S_AXIL_1_bready  (dma1_m_axil_bready),
      .S_AXIL_1_bresp   (dma1_m_axil_bresp),
      .S_AXIL_1_bvalid  (dma1_m_axil_bvalid),
      .S_AXIL_1_rdata   (dma1_m_axil_rdata_bram),
      .S_AXIL_1_rready  (dma1_m_axil_rready),
      .S_AXIL_1_rresp   (dma1_m_axil_rresp),
      .S_AXIL_1_rvalid  (dma1_m_axil_rvalid),
      .S_AXIL_1_wdata   (dma1_m_axil_wdata),
      .S_AXIL_1_wready  (dma1_m_axil_wready),
      .S_AXIL_1_wstrb   (dma1_m_axil_wstrb),
      .S_AXIL_1_wvalid  (dma1_m_axil_wvalid),


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
      .dma0_s_axis_c2h_cmpt_0_qid             ({1'b0,dma0_s_axis_c2h_cmpt_ctrl_qid}       ),
      .dma0_s_axis_c2h_cmpt_0_user_trig       (dma0_s_axis_c2h_cmpt_ctrl_user_trig        ),
      .dma0_s_axis_c2h_cmpt_0_wait_pld_pkt_id (dma0_s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id  ),
 
      .dma0_axis_c2h_status_0_drop (dma0_axis_c2h_status_drop  ),
      .dma0_axis_c2h_status_0_qid  (dma0_axis_c2h_status_qid   ),
      .dma0_axis_c2h_status_0_valid(dma0_axis_c2h_status_valid ),
      .dma0_axis_c2h_status_0_status_cmp  (dma0_axis_c2h_status_cmp   ),
      .dma0_axis_c2h_status_0_error(), //TBD
      //.dma0_axis_c2h_status_0_error(dma0_axis_c2h_status_error ),
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

      .dma0_tm_dsc_sts_0_pidx    (                   ),
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

      .dma0_c2h_byp_out_0_cidx            (dma0_c2h_byp_out_cidx),
      .dma0_c2h_byp_out_0_dsc             (dma0_c2h_byp_out_dsc),
      .dma0_c2h_byp_out_0_dsc_sz          (dma0_c2h_byp_out_dsc_sz),
      .dma0_c2h_byp_out_0_error           (dma0_c2h_byp_out_error),
      .dma0_c2h_byp_out_0_fmt             (dma0_c2h_byp_out_fmt),
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
      .dma0_h2c_byp_out_0_func            (dma0_h2c_byp_out_func),
      .dma0_h2c_byp_out_0_mm_chn          (dma0_h2c_byp_out_mm_chn),
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
      .dma0_user_clk_0(user_clk),

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
      .dma1_s_axis_c2h_cmpt_0_qid             ({1'b0,dma1_s_axis_c2h_cmpt_ctrl_qid}       ),
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
      .dma1_h2c_byp_out_0_func            (dma1_h2c_byp_out_func),
      .dma1_h2c_byp_out_0_mm_chn          (dma1_h2c_byp_out_mm_chn),
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
      .dma1_c2h_byp_in_mm_0_0_no_dma      (dma1_c2h_byp_in_mm_no_dma),
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
      .dma1_c2h_byp_in_mm_1_0_no_dma      ('h0),
      .dma1_c2h_byp_in_mm_1_0_port_id     ('h0),
      .dma1_c2h_byp_in_mm_1_0_qid         ('h0),
      .dma1_c2h_byp_in_mm_1_0_radr        (64'h0),
      .dma1_c2h_byp_in_mm_1_0_ready       ( ),
      .dma1_c2h_byp_in_mm_1_0_sdi         ('h0),
      .dma1_c2h_byp_in_mm_1_0_valid       ('h0),
      .dma1_c2h_byp_in_mm_1_0_wadr        (64'h0),
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
      .dma1_h2c_byp_in_mm_1_0_radr        (64'h0),
      .dma1_h2c_byp_in_mm_1_0_ready       ( ),
      .dma1_h2c_byp_in_mm_1_0_sdi         ('h0),
      .dma1_h2c_byp_in_mm_1_0_valid       ('h0),
      .dma1_h2c_byp_in_mm_1_0_wadr        (64'h0),

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
      .dma0_intrfc_resetn_0 (dma0_gen_user_reset_n),// TBD
      .cpm_cor_irq_0(),
      .cpm_misc_irq_0(),
      .cpm_uncor_irq_0(),
      .cpm_irq0_0('d0),
      .cpm_irq1_0('d0)

      );

  // DMA taget application for DMA0
  qdma_app #(
    .C_M_AXI_ID_WIDTH  ( C_M_AXI_ID_WIDTH),
    .C_DATA_WIDTH       ( C_DATA_WIDTH),
    .TM_DSC_BITS        ( TM_DSC_BITS),
    .C_CNTR_WIDTH       ( C_CNTR_WIDTH ),
    .QID_MAX             ( QID_MAX     ),
    .CRC_WIDTH           ( CRC_WIDTH   ),
    .BYTE_CREDIT        ( 2048 ),
    .TCQ                 ( TCQ)
  ) dma0_qdma_app_i (
    .user_clk            (user_clk),
    .user_resetn         (dma0_axi_aresetn),
    .gen_user_reset_n   (dma0_gen_user_reset_n),


      // AXI Lite Master Interface connections
      .m_axil_awaddr  ( dma0_m_axil_awaddr[31:0]),
      .m_axil_wdata   ( dma0_m_axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
      .m_axil_wvalid  ( dma0_m_axil_wvalid),
      .m_axil_wready  ( dma0_m_axil_wready),
      .m_axil_araddr  ( dma0_m_axil_araddr[31:0]),
      .m_axil_rdata   ( dma0_m_axil_rdata),   // block ram for AXI Lite is only 31 bits
      .m_axil_rdata_bram   ( dma0_m_axil_rdata_bram),   // block ram for AXI Lite is only 31 bits

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
      .h2c_byp_out_st_mm    (dma0_h2c_byp_out_st_mm),
      .h2c_byp_out_dsc_sz   (dma0_h2c_byp_out_dsc_sz),
      .h2c_byp_out_qid      (dma0_h2c_byp_out_qid),
      .h2c_byp_out_error    (dma0_h2c_byp_out_error),
      .h2c_byp_out_func     (dma0_h2c_byp_out_func),
      .h2c_byp_out_mm_chn   (dma0_h2c_byp_out_mm_chn),
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
  .leds() );

   

  // DMA taget application for DMA1
  qdma_app #(
    .C_M_AXI_ID_WIDTH  ( C_M_AXI_ID_WIDTH),
    .C_DATA_WIDTH       ( C_DATA_WIDTH),
    .TM_DSC_BITS        ( TM_DSC_BITS),
    .C_CNTR_WIDTH       ( C_CNTR_WIDTH),
    .QID_MAX             ( QID_MAX),
    .CRC_WIDTH           ( CRC_WIDTH          ),
    .BYTE_CREDIT        ( 2048 ),
    .TCQ                 ( TCQ)
  ) dma1_qdma_app_i (
    .user_clk           (user_clk),
    .user_resetn        (dma1_axi_aresetn),
    .gen_user_reset_n   (dma1_gen_user_reset_n),

      // AXI Lite Master Interface connections
      .m_axil_awaddr  ( dma1_m_axil_awaddr[31:0]),
      .m_axil_wdata   ( dma1_m_axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
      .m_axil_wvalid  ( dma1_m_axil_wvalid),
      .m_axil_wready  ( dma1_m_axil_wready),
      .m_axil_araddr  ( dma1_m_axil_araddr[31:0]),
      .m_axil_rdata   ( dma1_m_axil_rdata),   // block ram for AXI Lite is only 31 bits
      .m_axil_rdata_bram   ( dma1_m_axil_rdata_bram),   // block ram for AXI Lite is only 31 bits

      .c2h_byp_out_dsc      (dma1_c2h_byp_out_dsc),
      .c2h_byp_out_fmt      (dma1_c2h_byp_out_fmt),
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
      .h2c_byp_out_st_mm    (dma1_h2c_byp_out_st_mm),
      .h2c_byp_out_dsc_sz   (dma1_h2c_byp_out_dsc_sz),
      .h2c_byp_out_qid      (dma1_h2c_byp_out_qid),
      .h2c_byp_out_error    (dma1_h2c_byp_out_error),
      .h2c_byp_out_mm_chn   (dma1_h2c_byp_out_mm_chn),
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

