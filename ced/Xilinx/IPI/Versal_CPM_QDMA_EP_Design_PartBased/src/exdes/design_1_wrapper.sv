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
// File       : xilinx_dma_pcie_ep.sv
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
    input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   PCIE1_GT_0_grx_p,
    input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   PCIE1_GT_0_grx_n,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   PCIE1_GT_0_gtx_p,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   PCIE1_GT_0_gtx_n,
    input          gt_refclk1_0_clk_n,
    input          gt_refclk1_0_clk_p,

    output [5:0]CH0_LPDDR4_0_0_ca_a,
    output [5:0]CH0_LPDDR4_0_0_ca_b,
    output [0:0]CH0_LPDDR4_0_0_ck_c_a,
    output [0:0]CH0_LPDDR4_0_0_ck_c_b,
    output [0:0]CH0_LPDDR4_0_0_ck_t_a,
    output [0:0]CH0_LPDDR4_0_0_ck_t_b,
    output [0:0]CH0_LPDDR4_0_0_cke_a,
    output [0:0]CH0_LPDDR4_0_0_cke_b,
    output [0:0]CH0_LPDDR4_0_0_cs_a,
    output [0:0]CH0_LPDDR4_0_0_cs_b,
    inout [1:0]CH0_LPDDR4_0_0_dmi_a,
    inout [1:0]CH0_LPDDR4_0_0_dmi_b,
    inout [15:0]CH0_LPDDR4_0_0_dq_a,
    inout [15:0]CH0_LPDDR4_0_0_dq_b,
    inout [1:0]CH0_LPDDR4_0_0_dqs_c_a,
    inout [1:0]CH0_LPDDR4_0_0_dqs_c_b,
    inout [1:0]CH0_LPDDR4_0_0_dqs_t_a,
    inout [1:0]CH0_LPDDR4_0_0_dqs_t_b,
    output [0:0]CH0_LPDDR4_0_0_reset_n,
    output [5:0]CH1_LPDDR4_0_0_ca_a,
    output [5:0]CH1_LPDDR4_0_0_ca_b,
    output [0:0]CH1_LPDDR4_0_0_ck_c_a,
    output [0:0]CH1_LPDDR4_0_0_ck_c_b,
    output [0:0]CH1_LPDDR4_0_0_ck_t_a,
    output [0:0]CH1_LPDDR4_0_0_ck_t_b,
    output [0:0]CH1_LPDDR4_0_0_cke_a,
    output [0:0]CH1_LPDDR4_0_0_cke_b,
    output [0:0]CH1_LPDDR4_0_0_cs_a,
    output [0:0]CH1_LPDDR4_0_0_cs_b,
    inout [1:0]CH1_LPDDR4_0_0_dmi_a,
    inout [1:0]CH1_LPDDR4_0_0_dmi_b,
    inout [15:0]CH1_LPDDR4_0_0_dq_a,
    inout [15:0]CH1_LPDDR4_0_0_dq_b,
    inout [1:0]CH1_LPDDR4_0_0_dqs_c_a,
    inout [1:0]CH1_LPDDR4_0_0_dqs_c_b,
    inout [1:0]CH1_LPDDR4_0_0_dqs_t_a,
    inout [1:0]CH1_LPDDR4_0_0_dqs_t_b,
    output [0:0]CH1_LPDDR4_0_0_reset_n,
    input [0:0]sys_clk0_0_clk_n,
    input [0:0]sys_clk0_0_clk_p

 );

   //-----------------------------------------------------------------------------------------------------------------------

   
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
   
   wire                user_lnk_up;
   //----------------------------------------------------------------------------------------------------------------//
   //  AXI Interface                                                                                                 //
   //----------------------------------------------------------------------------------------------------------------//
   
   wire                user_clk;
   wire                axi_aresetn;
   wire                phy_ready; // Not currently used
   
   //// Wires for Avery HOT/WARM and COLD RESET
   //wire                avy_sys_rst_n_c;
   //wire                avy_cfg_hot_reset_out;
   //reg                 avy_sys_rst_n_g;
   //reg                 avy_cfg_hot_reset_out_g;
   //
   //assign avy_sys_rst_n_c       = avy_sys_rst_n_g;
   //assign avy_cfg_hot_reset_out = avy_cfg_hot_reset_out_g;
   //
   //initial begin 
   //   avy_sys_rst_n_g = 1;
   //   avy_cfg_hot_reset_out_g =0;
   //end
 
   //----------------------------------------------------------------------------------------------------------------//
   //    System(SYS) Interface                                                                                       //
   //----------------------------------------------------------------------------------------------------------------//

   wire                              sys_clk;
   wire                              sys_rst_n_c;

   // User Clock LED Heartbeat
   reg [25:0]                        user_clk_heartbeat;

   //-- AXI Master Write Address Channel
   wire [C_M_AXI_ADDR_WIDTH-1:0]     m_axi_awaddr;
   wire [C_M_AXI_ID_WIDTH-1:0]       m_axi_awid;
   wire [2:0]                        m_axi_awprot;
   wire [1:0]                        m_axi_awburst;
   wire [2:0]                        m_axi_awsize;
   wire [3:0]                        m_axi_awcache;
   wire [7:0]                        m_axi_awlen;
   wire                              m_axi_awlock;
   wire                              m_axi_awvalid;
   wire                              m_axi_awready;

   //-- AXI Master Write Data Channel
   wire [C_M_AXI_DATA_WIDTH-1:0]     m_axi_wdata;
   wire [(C_M_AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb;
   wire                              m_axi_wlast;
   wire                              m_axi_wvalid;
   wire                              m_axi_wready;
   //-- AXI Master Write Response Channel
   wire                              m_axi_bvalid;
   wire                              m_axi_bready;
   wire [C_M_AXI_ID_WIDTH-1 : 0]     m_axi_bid ;
   wire [1:0]                        m_axi_bresp ;

   //-- AXI Master Read Address Channel
   wire [C_M_AXI_ID_WIDTH-1 : 0]     m_axi_arid;
   wire [C_M_AXI_ADDR_WIDTH-1:0]     m_axi_araddr;
   wire [7:0]                        m_axi_arlen;
   wire [2:0]                        m_axi_arsize;
   wire [1:0]                        m_axi_arburst;
   wire [2:0]                        m_axi_arprot;
   wire                              m_axi_arvalid;
   wire                              m_axi_arready;
   wire                              m_axi_arlock;
   wire [3:0]                        m_axi_arcache;

   //-- AXI Master Read Data Channel
   wire [C_M_AXI_ID_WIDTH-1 : 0]     m_axi_rid;
   wire [C_M_AXI_DATA_WIDTH-1:0]     m_axi_rdata;
   wire [1:0]                        m_axi_rresp;
   wire                              m_axi_rvalid;
   wire                              m_axi_rready;

//////////////////////////////////////////////////  LITE
   //-- AXI Master Write Address Channel
   wire [31:0]                       m_axil_awaddr;
   wire [2:0]                        m_axil_awprot;
   wire                              m_axil_awvalid;
   wire                              m_axil_awready;

   //-- AXI Master Write Data Channel
   wire [31:0]                       m_axil_wdata;
   wire [3:0]                        m_axil_wstrb;
   wire                              m_axil_wvalid;
   wire                              m_axil_wready;
   //-- AXI Master Write Response Channel
   wire                              m_axil_bvalid;
   wire                              m_axil_bready;
   //-- AXI Master Read Address Channel
   wire [31:0]                       m_axil_araddr;
   wire [2:0]                        m_axil_arprot;
   wire                              m_axil_arvalid;
   wire                              m_axil_arready;
   //-- AXI Master Read Data Channel
   wire [31:0]                       m_axil_rdata_bram;
   wire [31:0]                       m_axil_rdata;
   wire [1:0]                        m_axil_rresp;
   wire                              m_axil_rvalid;
   wire                              m_axil_rready;
   wire [1:0]                        m_axil_bresp;

   wire [2:0]                        msi_vector_width;
   wire                              msi_enable;

   wire [5:0]                        cfg_ltssm_state;
   // H2C checking
   wire                              stat_vld;
   wire [31:0]                       stat_err;
  
   // qid output signals
   wire                              qid_rdy;
   wire                              qid_vld;
   wire [11:0]                       qid;
   wire [16-1:0]                     qid_desc_avail;
   wire                              desc_cnt_dec;
   wire [10:0]                       desc_cnt_dec_qid;
   wire                              requeue_vld;
   wire [10:0]                       requeue_qid;
   wire                              requeue_rdy;
   wire [16-1:0]                     dbg_userctrl_credits;
  
   // Performance counter signals
   wire [C_CNTR_WIDTH-1:0]           user_cntr_max;
   wire                              user_cntr_rst;
   wire                              user_cntr_read;
   wire [C_CNTR_WIDTH-1:0]           free_cnts;
   wire [C_CNTR_WIDTH-1:0]           idle_cnts;
   wire [C_CNTR_WIDTH-1:0]           busy_cnts;
   wire [C_CNTR_WIDTH-1:0]           actv_cnts;

   wire [C_CNTR_WIDTH-1:0]           h2c_user_cntr_max;
   wire                              h2c_user_cntr_rst;
   wire                              h2c_user_cntr_read;
   wire [C_CNTR_WIDTH-1:0]           h2c_free_cnts;
   wire [C_CNTR_WIDTH-1:0]           h2c_idle_cnts;
   wire [C_CNTR_WIDTH-1:0]           h2c_busy_cnts;
   wire [C_CNTR_WIDTH-1:0]           h2c_actv_cnts;

   // l3fwd latency signals
   wire [C_CNTR_WIDTH-1:0]           user_l3fwd_max;
   wire                              user_l3fwd_en;
   wire                              user_l3fwd_mode;
   wire                              user_l3fwd_rst;
   wire                              user_l3fwd_read;

   wire [C_CNTR_WIDTH-1:0]           max_latency;
   wire [C_CNTR_WIDTH-1:0]           min_latency;
   wire [C_CNTR_WIDTH-1:0]           sum_latency;
   wire [C_CNTR_WIDTH-1:0]           num_pkt_rcvd;


   wire [7:0]                        c2h_sts_0;
   wire [7:0]                        h2c_sts_0;
   wire [7:0]                        c2h_sts_1;
   wire [7:0]                        h2c_sts_1;
   wire [7:0]                        c2h_sts_2;
   wire [7:0]                        h2c_sts_2;
   wire [7:0]                        c2h_sts_3;
   wire [7:0]                        h2c_sts_3;

   // MDMA signals
   wire [C_DATA_WIDTH-1:0]           m_axis_h2c_tdata;
 //  wire [C_DATA_WIDTH/8-1:0]         m_axis_h2c_dpar;
   (* mark_debug = "TRUE" *)wire                              m_axis_h2c_tvalid;
   (* mark_debug = "TRUE" *)wire                              m_axis_h2c_tready;
   (* mark_debug = "TRUE" *)wire                              m_axis_h2c_tlast;
   (* mark_debug = "TRUE" *)wire [11:0]                       m_axis_h2c_tuser_qid;
   wire [2:0]                        m_axis_h2c_tuser_port_id;
   wire                              m_axis_h2c_tuser_err;
   wire [31:0]                       m_axis_h2c_tuser_mdata;
   wire [5:0]                        m_axis_h2c_tuser_mty;
   wire                              m_axis_h2c_tuser_zero_byte;

   wire                              m_axis_h2c_tready_lpbk;
   wire                              m_axis_h2c_tready_int;
   // AXIS C2H packet wire
   wire [C_DATA_WIDTH-1:0]           s_axis_c2h_tdata;  
   wire [CRC_WIDTH-1:0]              s_axis_c2h_tcrc;
 //  wire [C_DATA_WIDTH/8-1:0]         s_axis_c2h_dpar;  
   wire                              s_axis_c2h_ctrl_marker;
   wire [2:0]                        s_axis_c2h_ctrl_port_id;
   (* mark_debug = "TRUE" *)wire [15:0]                       s_axis_c2h_ctrl_len;
   (* mark_debug = "TRUE" *)wire [11:0]                       s_axis_c2h_ctrl_qid ;
   wire                              s_axis_c2h_ctrl_user_trig ;
   wire                              s_axis_c2h_ctrl_has_cmpt ;
   wire                              s_axis_c2h_ctrl_imm_data ;
   wire [6:0]                        s_axis_c2h_ctrl_ecc ;
   wire [C_DATA_WIDTH-1:0]           s_axis_c2h_tdata_int;
   wire                              s_axis_c2h_ctrl_marker_int;
   wire [15:0]                       s_axis_c2h_ctrl_len_int;
   wire [11:0]                       s_axis_c2h_ctrl_qid_int ;
   wire                              s_axis_c2h_ctrl_user_trig_int ;
   wire                              s_axis_c2h_ctrl_has_cmpt_int ;
   wire                              s_axis_c2h_ctrl_imm_data_int ;
   wire [6:0]                        s_axis_c2h_ctrl_ecc_int ;
   wire [C_DATA_WIDTH/8-1:0]         s_axis_c2h_dpar_int;
   (* mark_debug = "TRUE" *)wire                              s_axis_c2h_tvalid;
   (* mark_debug = "TRUE" *)wire                              s_axis_c2h_tready;
   (* mark_debug = "TRUE" *)wire                              s_axis_c2h_tlast;
   wire [5:0]                        s_axis_c2h_mty; 
   wire                              s_axis_c2h_tvalid_lpbk;
   wire                              s_axis_c2h_tlast_lpbk;
   wire [5:0]                        s_axis_c2h_mty_lpbk;
   wire                              s_axis_c2h_tvalid_int;
   wire                              s_axis_c2h_tlast_int;
   wire [5:0]                        s_axis_c2h_mty_int;

   // AXIS C2H tuser wire 
   wire [C_DATA_WIDTH-1:0]           s_axis_c2h_cmpt_tdata;
   wire [1:0]                        s_axis_c2h_cmpt_size;
   wire [15:0]                       s_axis_c2h_cmpt_dpar;
   (* mark_debug = "TRUE" *)wire                              s_axis_c2h_cmpt_tvalid;
   (* mark_debug = "TRUE" *)wire                              s_axis_c2h_cmpt_tlast;
   (* mark_debug = "TRUE" *)wire                              s_axis_c2h_cmpt_tready;
   wire                              s_axis_c2h_cmpt_tvalid_lpbk;
   wire                              s_axis_c2h_cmpt_tlast_lpbk;
   wire                              s_axis_c2h_cmpt_tvalid_int;
   wire                              s_axis_c2h_cmpt_tlast_int;
   (* mark_debug = "TRUE" *)wire [12:0]                       s_axis_c2h_cmpt_ctrl_qid;
   wire [1:0]                        s_axis_c2h_cmpt_ctrl_cmpt_type;
   wire [15:0]                       s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
   wire [2:0]                        s_axis_c2h_cmpt_ctrl_port_id;
   wire                              s_axis_c2h_cmpt_ctrl_marker;
   wire                              s_axis_c2h_cmpt_ctrl_user_trig;
   wire [2:0]                        s_axis_c2h_cmpt_ctrl_col_idx;
   wire [2:0]                        s_axis_c2h_cmpt_ctrl_err_idx;

   (* mark_debug = "TRUE" *)wire                              tm_dsc_sts_vld;
   wire                              tm_dsc_sts_qen;
   wire                              tm_dsc_sts_byp;
   (* mark_debug = "TRUE" *)wire                              tm_dsc_sts_dir;
   wire                              tm_dsc_sts_mm;
   wire                              tm_dsc_sts_error;   // Not yet connected
   (* mark_debug = "TRUE" *)wire [11:0]                       tm_dsc_sts_qid;
   (* mark_debug = "TRUE" *)wire [15:0]                       tm_dsc_sts_avl;
   wire                              tm_dsc_sts_qinv;
   wire                              tm_dsc_sts_irq_arm;
   (* mark_debug = "TRUE" *)wire                              tm_dsc_sts_rdy;

   wire                              c2h_st_marker_rsp;

   // Descriptor credit In -- Not Used
   wire                              dsc_crdt_in_vld;
   wire                              dsc_crdt_in_rdy;
   wire                              dsc_crdt_in_dir;
   (* mark_debug = "TRUE" *)wire                              dsc_crdt_in_fence;
   wire [11:0]                       dsc_crdt_in_qid;
   wire [15:0]                       dsc_crdt_in_crdt;

   // Report the DROP case
   (* mark_debug = "TRUE" *)wire                              axis_c2h_status_drop; 
   wire                              axis_c2h_status_last; 
   (* mark_debug = "TRUE" *)wire                              axis_c2h_status_valid; 
//EQDMA update   wire                              axis_c2h_status_imm_or_marker; 
   wire                              axis_c2h_status_cmp; 
   (* mark_debug = "TRUE" *)wire [11:0]                       axis_c2h_status_qid;
   wire                              axis_c2h_dmawr_cmp;
   
   wire [7:0]                        qsts_out_op;
   wire [63:0]                       qsts_out_data;
   wire [2:0]                        qsts_out_port_id;
   wire [12:0]                       qsts_out_qid;
   wire                              qsts_out_vld;
   wire                              qsts_out_rdy;

   wire                              gen_user_reset_n;
   wire                              st_loopback;

   wire [10:0]                       c2h_num_pkt;
   wire [11:0]                       c2h_st_qid;
   wire [15:0]                       c2h_st_len;
   wire [31:0]                       h2c_count;
   wire                              h2c_match;
   wire                              clr_h2c_match;
   wire [31:0]                       control_reg_c2h;
   wire [31:0]                       control_reg_c2h2;
   wire [11:0]                       h2c_qid;
   wire [31:0]                       cmpt_size;
   wire [255:0]                      wb_dat;
   wire [TM_DSC_BITS-1:0]            credit_out;
   wire [TM_DSC_BITS-1:0]            credit_needed;
   wire [TM_DSC_BITS-1:0]            credit_perpkt_in;
   wire                              credit_updt;
   wire [15:0]                       buf_count;
   wire                              sys_clk_gt; 

  // Descriptor Bypass Out for qdma
  wire  [255:0] h2c_byp_out_dsc;
  wire  [3:0]   h2c_byp_out_fmt;
  wire          h2c_byp_out_st_mm;
  (* mark_debug = "TRUE" *)wire  [11:0]  h2c_byp_out_qid;
  wire  [1:0]   h2c_byp_out_dsc_sz;
  wire          h2c_byp_out_error;
  wire  [11:0]  h2c_byp_out_func;
  wire          h2c_byp_out_mm_chn;
  wire  [15:0]  h2c_byp_out_cidx;
  wire  [2:0]   h2c_byp_out_port_id;
  (* mark_debug = "TRUE" *)wire          h2c_byp_out_vld;
  (* mark_debug = "TRUE" *)wire          h2c_byp_out_rdy;

  wire  [255:0] c2h_byp_out_dsc;
  wire  [3:0]   c2h_byp_out_fmt;
  wire          c2h_byp_out_st_mm;
  wire  [1:0]   c2h_byp_out_dsc_sz;
  (* mark_debug = "TRUE" *)wire  [11:0]  c2h_byp_out_qid;
  (* mark_debug = "TRUE" *)wire          c2h_byp_out_error;
  wire  [11:0]  c2h_byp_out_func;
  wire          c2h_byp_out_mm_chn;
  (* mark_debug = "TRUE" *)wire  [15:0]  c2h_byp_out_cidx;
  wire  [2:0]   c2h_byp_out_port_id;
  (* mark_debug = "TRUE" *)wire  [6:0]   c2h_byp_out_pfch_tag;
  (* mark_debug = "TRUE" *)wire          c2h_byp_out_vld;
  (* mark_debug = "TRUE" *)wire          c2h_byp_out_rdy;

  // Descriptor Bypass In for qdma MM
  wire  [63:0]  h2c_byp_in_mm_radr;
  wire  [63:0]  h2c_byp_in_mm_wadr;
  wire  [15:0]  h2c_byp_in_mm_len;
  wire          h2c_byp_in_mm_mrkr_req;
  wire          h2c_byp_in_mm_sdi;
  wire  [11:0]  h2c_byp_in_mm_qid;
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
  wire  [11:0]  c2h_byp_in_mm_qid;
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
  (* mark_debug = "TRUE" *)wire          h2c_byp_in_st_sdi;
  (* mark_debug = "TRUE" *)wire  [11:0]  h2c_byp_in_st_qid;
  wire          h2c_byp_in_st_error;
  wire  [11:0]  h2c_byp_in_st_func;
  wire  [15:0]  h2c_byp_in_st_cidx;
  wire  [2:0]   h2c_byp_in_st_port_id;
  wire  [1:0]   h2c_byp_in_st_at;
  wire          h2c_byp_in_st_no_dma;
  (* mark_debug = "TRUE" *)wire          h2c_byp_in_st_vld;
  (* mark_debug = "TRUE" *)wire          h2c_byp_in_st_rdy;

  wire  [63:0]  c2h_byp_in_st_csh_addr;
  (* mark_debug = "TRUE" *)wire  [11:0]  c2h_byp_in_st_csh_qid;
  (* mark_debug = "TRUE" *)wire          c2h_byp_in_st_csh_error;
  (* mark_debug = "TRUE" *)wire  [11:0]  c2h_byp_in_st_csh_func;
  (* mark_debug = "TRUE" *)wire  [2:0]   c2h_byp_in_st_csh_port_id;
  (* mark_debug = "TRUE" *)wire  [6:0]   c2h_byp_in_st_csh_pfch_tag;
  wire  [1:0]   c2h_byp_in_st_csh_at;
  (* mark_debug = "TRUE" *)wire          c2h_byp_in_st_csh_vld;
  (* mark_debug = "TRUE" *)wire          c2h_byp_in_st_csh_rdy;
  wire [11:0]   usr_flr_fnc;
  wire          usr_flr_set;
  wire          usr_flr_clr;
  wire [11:0]   usr_flr_done_fnc;
  wire          usr_flr_done_vld;
  wire          usr_irq_in_vld;
  wire [10 : 0] usr_irq_in_vec;
  wire [11 : 0] usr_irq_in_fnc;
  wire          usr_irq_out_ack;
  wire          usr_irq_out_fail;

 design_1 design_1_i (
      .CH0_LPDDR4_0_0_ca_a(CH0_LPDDR4_0_0_ca_a),
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

      .gt_refclk1_0_clk_n(gt_refclk1_0_clk_n),
      .gt_refclk1_0_clk_p(gt_refclk1_0_clk_p),

      .PCIE1_GT_0_grx_n(PCIE1_GT_0_grx_n),
      .PCIE1_GT_0_grx_p(PCIE1_GT_0_grx_p),
      .PCIE1_GT_0_gtx_n(PCIE1_GT_0_gtx_n),
      .PCIE1_GT_0_gtx_p(PCIE1_GT_0_gtx_p),

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
      .S_AXIL_araddr  (m_axil_araddr[11:0]),
      .S_AXIL_arprot  (m_axil_arprot),
      .S_AXIL_arready (m_axil_arready),
      .S_AXIL_arvalid (m_axil_arvalid),
      .S_AXIL_awaddr  (m_axil_awaddr[11:0]),
      .S_AXIL_awprot  (m_axil_awprot),
      .S_AXIL_awready (m_axil_awready),
      .S_AXIL_awvalid (m_axil_awvalid),
      .S_AXIL_bready  (m_axil_bready),
      .S_AXIL_bresp   (m_axil_bresp),
      .S_AXIL_bvalid  (m_axil_bvalid),
      .S_AXIL_rdata   (m_axil_rdata_bram),
      .S_AXIL_rready  (m_axil_rready),
      .S_AXIL_rresp   (m_axil_rresp),
      .S_AXIL_rvalid  (m_axil_rvalid),
      .S_AXIL_wdata   (m_axil_wdata),
      .S_AXIL_wready  (m_axil_wready),
      .S_AXIL_wstrb   (m_axil_wstrb),
      .S_AXIL_wvalid  (m_axil_wvalid),

      .dma1_s_axis_c2h_0_tcrc         (s_axis_c2h_tcrc ), //TODO,
      .dma1_s_axis_c2h_0_mty          (s_axis_c2h_mty),
      .dma1_s_axis_c2h_0_tdata        (s_axis_c2h_tdata),
      .dma1_s_axis_c2h_0_tlast        (s_axis_c2h_tlast),
      .dma1_s_axis_c2h_0_tready       (s_axis_c2h_tready),
      .dma1_s_axis_c2h_0_tvalid       (s_axis_c2h_tvalid),
      .dma1_s_axis_c2h_0_ctrl_has_cmpt(s_axis_c2h_ctrl_has_cmpt ), // 1 = Sends write back. 0 = disable write back, write back not valid
      .dma1_s_axis_c2h_0_ctrl_len     (s_axis_c2h_ctrl_len),
      .dma1_s_axis_c2h_0_ctrl_marker  (s_axis_c2h_ctrl_marker),
      .dma1_s_axis_c2h_0_ctrl_port_id (3'b000), //s_axis_c2h_ctrl_port_id),
      .dma1_s_axis_c2h_0_ctrl_qid     (s_axis_c2h_ctrl_qid),

      .dma1_s_axis_c2h_cmpt_0_data     (s_axis_c2h_cmpt_tdata   ),
      .dma1_s_axis_c2h_cmpt_0_dpar     (s_axis_c2h_cmpt_dpar   ),
      .dma1_s_axis_c2h_cmpt_0_tready   (s_axis_c2h_cmpt_tready ),
      .dma1_s_axis_c2h_cmpt_0_tvalid   (s_axis_c2h_cmpt_tvalid ),
      .dma1_s_axis_c2h_cmpt_0_size            (s_axis_c2h_cmpt_size                  ),
      .dma1_s_axis_c2h_cmpt_0_cmpt_type       (s_axis_c2h_cmpt_ctrl_cmpt_type ),
      .dma1_s_axis_c2h_cmpt_0_err_idx         (s_axis_c2h_cmpt_ctrl_err_idx          ),
      .dma1_s_axis_c2h_cmpt_0_marker          (s_axis_c2h_cmpt_ctrl_marker           ),
      .dma1_s_axis_c2h_cmpt_0_col_idx         (s_axis_c2h_cmpt_ctrl_col_idx          ),
      .dma1_s_axis_c2h_cmpt_0_port_id         ('b00          ),
      .dma1_s_axis_c2h_cmpt_0_qid             (s_axis_c2h_cmpt_ctrl_qid       ),
      //.dma1_s_axis_c2h_cmpt_0_qid             ({s_axis_c2h_cmpt_ctrl_qid}       ),
      .dma1_s_axis_c2h_cmpt_0_no_wrb_marker   (1'b0     ),
      .dma1_s_axis_c2h_cmpt_0_user_trig       (s_axis_c2h_cmpt_ctrl_user_trig        ),
      .dma1_s_axis_c2h_cmpt_0_wait_pld_pkt_id (s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id  ),
      .dma1_s_axis_c2h_0_ecc                  (s_axis_c2h_ctrl_ecc),  

 
      .dma1_axis_c2h_status_0_drop (axis_c2h_status_drop  ),
      .dma1_axis_c2h_status_0_qid  (axis_c2h_status_qid   ),
      .dma1_axis_c2h_status_0_valid(axis_c2h_status_valid ),
      .dma1_axis_c2h_status_0_status_cmp  (axis_c2h_status_cmp   ),
      .dma1_axis_c2h_status_0_error(), // TODO
      //.dma1_axis_c2h_status_0_error('d0), //axis_c2h_status_error ), // TODO
      .dma1_axis_c2h_status_0_last (axis_c2h_status_last  ),

      .dma1_axis_c2h_dmawr_0_cmp    (axis_c2h_dmawr_cmp), 
      .dma1_axis_c2h_dmawr_0_port_id(axis_c2h_dmawr_port_id), //TODO

      .dma1_dsc_crdt_in_0_crdt     (dsc_crdt_in_crdt  ),
      .dma1_dsc_crdt_in_0_qid      (dsc_crdt_in_qid   ),
      .dma1_dsc_crdt_in_0_rdy      (dsc_crdt_in_rdy   ),
      .dma1_dsc_crdt_in_0_dir      (dsc_crdt_in_dir   ), 
      .dma1_dsc_crdt_in_0_valid    (dsc_crdt_in_vld ),
      .dma1_dsc_crdt_in_0_fence    (dsc_crdt_in_fence ),
      
      .dma1_m_axis_h2c_0_err       (m_axis_h2c_tuser_err      ),
      .dma1_m_axis_h2c_0_mdata     (m_axis_h2c_tuser_mdata    ),
      .dma1_m_axis_h2c_0_mty       (m_axis_h2c_tuser_mty      ),
      .dma1_m_axis_h2c_0_tcrc      (m_axis_h2c_tcrc      ),     //TODO crc or par?
      .dma1_m_axis_h2c_0_port_id   (m_axis_h2c_tuser_port_id  ),
      .dma1_m_axis_h2c_0_qid       (m_axis_h2c_tuser_qid      ),
      .dma1_m_axis_h2c_0_tdata     (m_axis_h2c_tdata    ),
      .dma1_m_axis_h2c_0_tlast     (m_axis_h2c_tlast    ),
      .dma1_m_axis_h2c_0_tready    (m_axis_h2c_tready   ),
      .dma1_m_axis_h2c_0_tvalid    (m_axis_h2c_tvalid   ),
      .dma1_m_axis_h2c_0_zero_byte (m_axis_h2c_tuser_zero_byte),

      //.dma1_mgmt_0_cpl_dat        (),
      //.dma1_mgmt_0_cpl_rdy        (),
      //.dma1_mgmt_0_cpl_sts        (),
      //.dma1_mgmt_0_cpl_vld        (),
      //  
      //.dma1_mgmt_0_req_adr        ( ),
      //.dma1_mgmt_0_req_cmd        ( ),
      //.dma1_mgmt_0_req_dat        ( ),
      //.dma1_mgmt_0_req_fnc        ( ),
      //.dma1_mgmt_0_req_msc        ( ),
      //.dma1_mgmt_0_req_rdy        ( ),
      //.dma1_mgmt_0_req_vld        ( ),

      .dma1_st_rx_msg_0_tdata    ( ),    //st_rx_msg_data  ),
      .dma1_st_rx_msg_0_tlast    ( ),    //st_rx_msg_last  ),
      .dma1_st_rx_msg_0_tready   (1'b1), //st_rx_msg_rdy 
      .dma1_st_rx_msg_0_tvalid   ( ),    //st_rx_msg_valid ),

      .dma1_tm_dsc_sts_0_pidx    (                   ),
      .dma1_tm_dsc_sts_0_avl     (tm_dsc_sts_avl     ),
      .dma1_tm_dsc_sts_0_byp     (tm_dsc_sts_byp     ),
      .dma1_tm_dsc_sts_0_dir     (tm_dsc_sts_dir     ),
      .dma1_tm_dsc_sts_0_error   (tm_dsc_sts_error   ),
      .dma1_tm_dsc_sts_0_irq_arm (tm_dsc_sts_irq_arm ),
      .dma1_tm_dsc_sts_0_mm      (tm_dsc_sts_mm      ),
      .dma1_tm_dsc_sts_0_port_id (tm_dsc_sts_port_id ),
      .dma1_tm_dsc_sts_0_qen     (tm_dsc_sts_qen     ),
      .dma1_tm_dsc_sts_0_qid     (tm_dsc_sts_qid     ),
      .dma1_tm_dsc_sts_0_qinv    (tm_dsc_sts_qinv    ),
      .dma1_tm_dsc_sts_0_rdy     (tm_dsc_sts_rdy     ),
      .dma1_tm_dsc_sts_0_valid   (tm_dsc_sts_vld     ),

      
      .dma1_c2h_byp_out_0_cidx            (c2h_byp_out_cidx),
      .dma1_c2h_byp_out_0_dsc             (c2h_byp_out_dsc),
      .dma1_c2h_byp_out_0_dsc_sz          (c2h_byp_out_dsc_sz),
      .dma1_c2h_byp_out_0_error           (c2h_byp_out_error),
      .dma1_c2h_byp_out_0_fmt             (c2h_byp_out_fmt),
      .dma1_c2h_byp_out_0_func            (c2h_byp_out_func),
      .dma1_c2h_byp_out_0_mm_chn          (c2h_byp_out_mm_chn),
      .dma1_c2h_byp_out_0_pfch_tag        (c2h_byp_out_pfch_tag),
      .dma1_c2h_byp_out_0_port_id         (c2h_byp_out_port_id),
      .dma1_c2h_byp_out_0_qid             (c2h_byp_out_qid),
      .dma1_c2h_byp_out_0_ready           (c2h_byp_out_rdy),
      .dma1_c2h_byp_out_0_st_mm           (c2h_byp_out_st_mm),
      .dma1_c2h_byp_out_0_valid           (c2h_byp_out_vld),
		      
      .dma1_h2c_byp_out_0_cidx            (h2c_byp_out_cidx),
      .dma1_h2c_byp_out_0_dsc             (h2c_byp_out_dsc),
      .dma1_h2c_byp_out_0_dsc_sz          (h2c_byp_out_dsc_sz),
      .dma1_h2c_byp_out_0_error           (h2c_byp_out_error),
      .dma1_h2c_byp_out_0_fmt             (h2c_byp_out_fmt),
      .dma1_h2c_byp_out_0_func            (h2c_byp_out_func),
      .dma1_h2c_byp_out_0_mm_chn          (h2c_byp_out_mm_chn),
      .dma1_h2c_byp_out_0_port_id         (h2c_byp_out_port_id),
      .dma1_h2c_byp_out_0_qid             (h2c_byp_out_qid),
      .dma1_h2c_byp_out_0_ready           (h2c_byp_out_rdy),
      .dma1_h2c_byp_out_0_st_mm           (h2c_byp_out_st_mm),
      .dma1_h2c_byp_out_0_valid           (h2c_byp_out_vld),
      
      .dma1_c2h_byp_in_st_csh_0_addr      (c2h_byp_in_st_csh_addr),
      .dma1_c2h_byp_in_st_csh_0_error     (c2h_byp_in_st_csh_error),
      .dma1_c2h_byp_in_st_csh_0_func      (c2h_byp_in_st_csh_func),
      .dma1_c2h_byp_in_st_csh_0_pfch_tag  (c2h_byp_in_st_csh_pfch_tag),
      .dma1_c2h_byp_in_st_csh_0_port_id   (c2h_byp_in_st_csh_port_id),
      .dma1_c2h_byp_in_st_csh_0_qid       (c2h_byp_in_st_csh_qid),
      .dma1_c2h_byp_in_st_csh_0_ready     (c2h_byp_in_st_csh_rdy),
      .dma1_c2h_byp_in_st_csh_0_valid     (c2h_byp_in_st_csh_vld),
      
      .dma1_h2c_byp_in_st_0_addr          (h2c_byp_in_st_addr),
      .dma1_h2c_byp_in_st_0_cidx          (h2c_byp_in_st_cidx),
      .dma1_h2c_byp_in_st_0_eop           (h2c_byp_in_st_eop),
      .dma1_h2c_byp_in_st_0_error         (h2c_byp_in_st_error),
      .dma1_h2c_byp_in_st_0_func          (h2c_byp_in_st_func),
      .dma1_h2c_byp_in_st_0_len           (h2c_byp_in_st_len),
      .dma1_h2c_byp_in_st_0_mrkr_req      (h2c_byp_in_st_mrkr_req),
      .dma1_h2c_byp_in_st_0_no_dma        (h2c_byp_in_st_no_dma),
      .dma1_h2c_byp_in_st_0_port_id       (h2c_byp_in_st_port_id),
      .dma1_h2c_byp_in_st_0_qid           (h2c_byp_in_st_qid),
      .dma1_h2c_byp_in_st_0_ready         (h2c_byp_in_st_rdy),
      .dma1_h2c_byp_in_st_0_sdi           (h2c_byp_in_st_sdi),
      .dma1_h2c_byp_in_st_0_sop           (h2c_byp_in_st_sop),
      .dma1_h2c_byp_in_st_0_valid         (h2c_byp_in_st_vld),

      .dma1_c2h_byp_in_mm_0_0_cidx        (c2h_byp_in_mm_cidx),
      .dma1_c2h_byp_in_mm_0_0_error       (c2h_byp_in_mm_error),
      .dma1_c2h_byp_in_mm_0_0_func        (c2h_byp_in_mm_func),
      .dma1_c2h_byp_in_mm_0_0_len         (c2h_byp_in_mm_len),
      .dma1_c2h_byp_in_mm_0_0_mrkr_req    (c2h_byp_in_mm_mrkr_req),
      .dma1_c2h_byp_in_mm_0_0_no_dma      (c2h_byp_in_mm_no_dma),
      .dma1_c2h_byp_in_mm_0_0_port_id     (c2h_byp_in_mm_port_id),
      .dma1_c2h_byp_in_mm_0_0_qid         (c2h_byp_in_mm_qid),
      .dma1_c2h_byp_in_mm_0_0_radr        (c2h_byp_in_mm_radr),
      .dma1_c2h_byp_in_mm_0_0_ready       (c2h_byp_in_mm_rdy),
      .dma1_c2h_byp_in_mm_0_0_sdi         (c2h_byp_in_mm_sdi),
      .dma1_c2h_byp_in_mm_0_0_valid       (c2h_byp_in_mm_vld),
      .dma1_c2h_byp_in_mm_0_0_wadr        (c2h_byp_in_mm_wadr),
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
      .dma1_h2c_byp_in_mm_0_0_cidx        (h2c_byp_in_mm_cidx),
      .dma1_h2c_byp_in_mm_0_0_error       (h2c_byp_in_mm_error),
      .dma1_h2c_byp_in_mm_0_0_func        (h2c_byp_in_mm_func),
      .dma1_h2c_byp_in_mm_0_0_len         (h2c_byp_in_mm_len),
      .dma1_h2c_byp_in_mm_0_0_mrkr_req    (h2c_byp_in_mm_mrkr_req),
      .dma1_h2c_byp_in_mm_0_0_no_dma      (h2c_byp_in_mm_no_dma),
      .dma1_h2c_byp_in_mm_0_0_port_id     (h2c_byp_in_mm_port_id),
      .dma1_h2c_byp_in_mm_0_0_qid         (h2c_byp_in_mm_qid),
      .dma1_h2c_byp_in_mm_0_0_radr        (h2c_byp_in_mm_radr),
      .dma1_h2c_byp_in_mm_0_0_ready       (h2c_byp_in_mm_rdy),
      .dma1_h2c_byp_in_mm_0_0_sdi         (h2c_byp_in_mm_sdi),
      .dma1_h2c_byp_in_mm_0_0_valid       (h2c_byp_in_mm_vld),
      .dma1_h2c_byp_in_mm_0_0_wadr        (h2c_byp_in_mm_wadr),
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

      .dma1_qsts_out_0_data     (qsts_out_data     ),
      .dma1_qsts_out_0_op       (qsts_out_op       ),
      .dma1_qsts_out_0_port_id  (qsts_out_port_id  ),
      .dma1_qsts_out_0_qid      (qsts_out_qid      ),
      .dma1_qsts_out_0_rdy      (qsts_out_rdy  ),
      .dma1_qsts_out_0_vld      (qsts_out_vld  ),

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

      .dma1_intrfc_resetn_0(gen_user_reset_n),
      .dma1_axi_aresetn_0(axi_aresetn),

      .cpm_cor_irq_0(),
      .cpm_misc_irq_0(),
      .cpm_uncor_irq_0(),
      .cpm_irq0_0('d0),
      .cpm_irq1_0('d0),
      .dma1_intrfc_clk_0(user_clk),
      .pcie0_user_lnk_up_0()

      );

  // DMA taget application for DMA0
  qdma_app #(
    .C_M_AXI_ID_WIDTH  ( C_M_AXI_ID_WIDTH),
    .C_DATA_WIDTH       ( C_DATA_WIDTH),
    .TM_DSC_BITS        ( TM_DSC_BITS),
    .C_CNTR_WIDTH       ( C_CNTR_WIDTH),
    .QID_MAX             ( QID_MAX),
    .CRC_WIDTH           ( CRC_WIDTH          ),
    .TCQ                 ( TCQ)
	     ) 
   dma1_qdma_app_i 
     (
      .user_clk            ( user_clk),
      .user_resetn         ( axi_aresetn),
      .gen_user_reset_n   ( gen_user_reset_n),
      
      // AXI Lite Master Interface connections
      .m_axil_awaddr  ( m_axil_awaddr[31:0]),
      .m_axil_wdata   ( m_axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
      .m_axil_wvalid  ( m_axil_wvalid),
      .m_axil_wready  ( m_axil_wready),
      .m_axil_araddr  ( m_axil_araddr[31:0]),
      .m_axil_rdata   ( m_axil_rdata),   // block ram for AXI Lite is only 31 bits
      .m_axil_rdata_bram   ( m_axil_rdata_bram),   // block ram for AXI Lite is only 31 bits

      .c2h_byp_out_dsc      ( c2h_byp_out_dsc),
      .c2h_byp_out_fmt      ( c2h_byp_out_fmt),
//      .c2h_byp_out_cnt      ('d1),
      .c2h_byp_out_st_mm    ( c2h_byp_out_st_mm),
      .c2h_byp_out_dsc_sz   ( c2h_byp_out_dsc_sz),
      .c2h_byp_out_qid      ( c2h_byp_out_qid),
      .c2h_byp_out_error    ( c2h_byp_out_error),
      .c2h_byp_out_func     ( c2h_byp_out_func),
      .c2h_byp_out_mm_chn   ( c2h_byp_out_mm_chn),
      .c2h_byp_out_cidx     ( c2h_byp_out_cidx),
      .c2h_byp_out_port_id  ( c2h_byp_out_port_id),
      .c2h_byp_out_pfch_tag ( c2h_byp_out_pfch_tag),
      .c2h_byp_out_vld      ( c2h_byp_out_vld),
      .c2h_byp_out_rdy      ( c2h_byp_out_rdy),

      .c2h_byp_in_mm_radr     ( c2h_byp_in_mm_radr),
      .c2h_byp_in_mm_wadr     ( c2h_byp_in_mm_wadr),
      .c2h_byp_in_mm_len      ( c2h_byp_in_mm_len),
      .c2h_byp_in_mm_mrkr_req ( c2h_byp_in_mm_mrkr_req),
      .c2h_byp_in_mm_sdi      ( c2h_byp_in_mm_sdi),
      .c2h_byp_in_mm_qid      ( c2h_byp_in_mm_qid),
      .c2h_byp_in_mm_error    ( c2h_byp_in_mm_error),
      .c2h_byp_in_mm_func     ( c2h_byp_in_mm_func),
      .c2h_byp_in_mm_cidx     ( c2h_byp_in_mm_cidx),
      .c2h_byp_in_mm_port_id  ( c2h_byp_in_mm_port_id),
      .c2h_byp_in_mm_at       ( c2h_byp_in_mm_at),
      .c2h_byp_in_mm_no_dma   ( c2h_byp_in_mm_no_dma),
      .c2h_byp_in_mm_vld      ( c2h_byp_in_mm_vld),
      .c2h_byp_in_mm_rdy      ( c2h_byp_in_mm_rdy),

      .c2h_byp_in_st_csh_addr    ( c2h_byp_in_st_csh_addr),
      .c2h_byp_in_st_csh_qid     ( c2h_byp_in_st_csh_qid),
      .c2h_byp_in_st_csh_error   ( c2h_byp_in_st_csh_error),
      .c2h_byp_in_st_csh_func    ( c2h_byp_in_st_csh_func),
      .c2h_byp_in_st_csh_port_id ( c2h_byp_in_st_csh_port_id),
      .c2h_byp_in_st_csh_pfch_tag( c2h_byp_in_st_csh_pfch_tag),
      .c2h_byp_in_st_csh_at      ( c2h_byp_in_st_csh_at),
      .c2h_byp_in_st_csh_vld     ( c2h_byp_in_st_csh_vld),
      .c2h_byp_in_st_csh_rdy     ( c2h_byp_in_st_csh_rdy),

      .h2c_byp_out_dsc      ( h2c_byp_out_dsc),
      .h2c_byp_out_fmt      ( h2c_byp_out_fmt),
      .h2c_byp_out_st_mm    ( h2c_byp_out_st_mm),
      .h2c_byp_out_dsc_sz   ( h2c_byp_out_dsc_sz),
      .h2c_byp_out_qid      ( h2c_byp_out_qid),
      .h2c_byp_out_error    ( h2c_byp_out_error),
      .h2c_byp_out_func     ( h2c_byp_out_func),
      .h2c_byp_out_mm_chn   ( h2c_byp_out_mm_chn),
      .h2c_byp_out_cidx     ( h2c_byp_out_cidx),
      .h2c_byp_out_port_id  ( h2c_byp_out_port_id),
      .h2c_byp_out_vld      ( h2c_byp_out_vld),
      .h2c_byp_out_rdy      ( h2c_byp_out_rdy),

      .h2c_byp_in_mm_radr     ( h2c_byp_in_mm_radr),
      .h2c_byp_in_mm_wadr     ( h2c_byp_in_mm_wadr),
      .h2c_byp_in_mm_len      ( h2c_byp_in_mm_len),
      .h2c_byp_in_mm_mrkr_req ( h2c_byp_in_mm_mrkr_req),
      .h2c_byp_in_mm_sdi      ( h2c_byp_in_mm_sdi),
      .h2c_byp_in_mm_qid      ( h2c_byp_in_mm_qid),
      .h2c_byp_in_mm_error    ( h2c_byp_in_mm_error),
      .h2c_byp_in_mm_func     ( h2c_byp_in_mm_func),
      .h2c_byp_in_mm_cidx     ( h2c_byp_in_mm_cidx),
      .h2c_byp_in_mm_port_id  ( h2c_byp_in_mm_port_id),
      .h2c_byp_in_mm_at       ( h2c_byp_in_mm_at),
      .h2c_byp_in_mm_no_dma   ( h2c_byp_in_mm_no_dma),
      .h2c_byp_in_mm_vld      ( h2c_byp_in_mm_vld),
      .h2c_byp_in_mm_rdy      ( h2c_byp_in_mm_rdy),

      .h2c_byp_in_st_addr     ( h2c_byp_in_st_addr),
      .h2c_byp_in_st_len      ( h2c_byp_in_st_len),
      .h2c_byp_in_st_eop      ( h2c_byp_in_st_eop),
      .h2c_byp_in_st_sop      ( h2c_byp_in_st_sop),
      .h2c_byp_in_st_mrkr_req ( h2c_byp_in_st_mrkr_req),
      .h2c_byp_in_st_sdi      ( h2c_byp_in_st_sdi),
      .h2c_byp_in_st_qid      ( h2c_byp_in_st_qid),
      .h2c_byp_in_st_error    ( h2c_byp_in_st_error),
      .h2c_byp_in_st_func     ( h2c_byp_in_st_func),
      .h2c_byp_in_st_cidx     ( h2c_byp_in_st_cidx),
      .h2c_byp_in_st_port_id  ( h2c_byp_in_st_port_id),
      .h2c_byp_in_st_at       ( h2c_byp_in_st_at),
      .h2c_byp_in_st_no_dma   ( h2c_byp_in_st_no_dma),
      .h2c_byp_in_st_vld      ( h2c_byp_in_st_vld),
      .h2c_byp_in_st_rdy      ( h2c_byp_in_st_rdy),


      .usr_flr_fnc ( usr_flr_fnc ),
      .usr_flr_set ( usr_flr_set ),
      .usr_flr_clr ( usr_flr_clr) ,
      .usr_flr_done_fnc ( usr_flr_done_fnc),
      .usr_flr_done_vld ( usr_flr_done_vld),
      

      .m_axis_h2c_tvalid         ( m_axis_h2c_tvalid),
      .m_axis_h2c_tready         ( m_axis_h2c_tready),
      .m_axis_h2c_tdata          ( m_axis_h2c_tdata),
      .m_axis_h2c_tcrc           ( m_axis_h2c_tcrc),
      .m_axis_h2c_tlast          ( m_axis_h2c_tlast),
      .m_axis_h2c_tuser_qid      ( m_axis_h2c_tuser_qid),
      .m_axis_h2c_tuser_port_id  ( m_axis_h2c_tuser_port_id),
      .m_axis_h2c_tuser_err      ( m_axis_h2c_tuser_err),
      .m_axis_h2c_tuser_mdata    ( m_axis_h2c_tuser_mdata),
      .m_axis_h2c_tuser_mty      ( m_axis_h2c_tuser_mty),
      .m_axis_h2c_tuser_zero_byte( m_axis_h2c_tuser_zero_byte),
      
      .s_axis_c2h_tdata          ( s_axis_c2h_tdata ),
      .s_axis_c2h_tcrc           ( s_axis_c2h_tcrc  ),
      .s_axis_c2h_ctrl_marker    ( s_axis_c2h_ctrl_marker),
      .s_axis_c2h_ctrl_len       ( s_axis_c2h_ctrl_len), // c2h_st_len,
      .s_axis_c2h_ctrl_port_id   ( s_axis_c2h_ctrl_port_id),
      .s_axis_c2h_ctrl_ecc       ( s_axis_c2h_ctrl_ecc),
      .s_axis_c2h_ctrl_qid       ( s_axis_c2h_ctrl_qid ), // st_qid,
      .s_axis_c2h_ctrl_has_cmpt  ( s_axis_c2h_ctrl_has_cmpt),   // write back is valid
      .s_axis_c2h_tvalid         ( s_axis_c2h_tvalid),
      .s_axis_c2h_tready         ( s_axis_c2h_tready),
      .s_axis_c2h_tlast          ( s_axis_c2h_tlast ),
      .s_axis_c2h_mty            ( s_axis_c2h_mty ),  // no empthy bytes at EOP
      
      .s_axis_c2h_cmpt_tdata               ( s_axis_c2h_cmpt_tdata),
      .s_axis_c2h_cmpt_size                ( s_axis_c2h_cmpt_size),
      .s_axis_c2h_cmpt_dpar                ( s_axis_c2h_cmpt_dpar),
      .s_axis_c2h_cmpt_tvalid              ( s_axis_c2h_cmpt_tvalid),
      .s_axis_c2h_cmpt_tready              ( s_axis_c2h_cmpt_tready),
      .s_axis_c2h_cmpt_ctrl_qid            ( s_axis_c2h_cmpt_ctrl_qid),
      .s_axis_c2h_cmpt_ctrl_cmpt_type      ( s_axis_c2h_cmpt_ctrl_cmpt_type),
      .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id( s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
      .s_axis_c2h_cmpt_ctrl_marker         ( s_axis_c2h_cmpt_ctrl_marker),
      .s_axis_c2h_cmpt_ctrl_user_trig      ( s_axis_c2h_cmpt_ctrl_user_trig),
      .s_axis_c2h_cmpt_ctrl_col_idx        ( s_axis_c2h_cmpt_ctrl_col_idx),
      .s_axis_c2h_cmpt_ctrl_err_idx        ( s_axis_c2h_cmpt_ctrl_err_idx),
      
      .axis_c2h_status_drop                ( axis_c2h_status_drop),
      .axis_c2h_status_valid               ( axis_c2h_status_valid),
      .axis_c2h_status_qid                 ( axis_c2h_status_qid),
      .axis_c2h_status_last                ( axis_c2h_status_last),
      .axis_c2h_status_cmp                 ( axis_c2h_status_cmp),
      .axis_c2h_status_error               ( axis_c2h_status_error),
      
      .axis_c2h_dmawr_cmp                  ( axis_c2h_dmawr_cmp), 
      .axis_c2h_dmawr_port_id              ( axis_c2h_dmawr_port_id),
      
      
      .qsts_out_op      ( qsts_out_op),
      .qsts_out_data    ( qsts_out_data),
      .qsts_out_port_id ( qsts_out_port_id),
      .qsts_out_qid     ( qsts_out_qid),
      .qsts_out_vld     ( qsts_out_vld),
      .qsts_out_rdy     ( qsts_out_rdy),
      
      .usr_irq_in_vld   ( usr_irq_in_vld),
      .usr_irq_in_vec   ( usr_irq_in_vec),
      .usr_irq_in_fnc   ( usr_irq_in_fnc),
      .usr_irq_out_ack  ( usr_irq_out_ack),
      .usr_irq_out_fail ( usr_irq_out_fail),
      
      .st_rx_msg_rdy   ( st_rx_msg_rdy),
      .st_rx_msg_valid ( st_rx_msg_valid),
      .st_rx_msg_last  ( st_rx_msg_last),
      .st_rx_msg_data  ( st_rx_msg_data),
      
      .tm_dsc_sts_vld     ( tm_dsc_sts_vld   ),
      .tm_dsc_sts_qen     ( tm_dsc_sts_qen   ),
      .tm_dsc_sts_byp     ( tm_dsc_sts_byp   ),
      .tm_dsc_sts_dir     ( tm_dsc_sts_dir   ),
      .tm_dsc_sts_mm      ( tm_dsc_sts_mm    ),
      .tm_dsc_sts_error   ( tm_dsc_sts_error ),
      .tm_dsc_sts_qid     ( tm_dsc_sts_qid   ),
      .tm_dsc_sts_avl     ( tm_dsc_sts_avl   ),
      .tm_dsc_sts_qinv    ( tm_dsc_sts_qinv  ),
      .tm_dsc_sts_irq_arm ( tm_dsc_sts_irq_arm),
      .tm_dsc_sts_rdy     ( tm_dsc_sts_rdy),
      
      .dsc_crdt_in_vld        ( dsc_crdt_in_vld),
      .dsc_crdt_in_rdy        ( dsc_crdt_in_rdy),
      .dsc_crdt_in_dir        ( dsc_crdt_in_dir),
      .dsc_crdt_in_fence      ( dsc_crdt_in_fence),
      .dsc_crdt_in_qid        ( dsc_crdt_in_qid),
      .dsc_crdt_in_crdt       ( dsc_crdt_in_crdt),


      .leds()
      
  );

   
/*
   user_control #(
    .C_DATA_WIDTH                   ( C_DATA_WIDTH_ST   ),
    .QID_MAX                        ( QID_MAX           ),
    .TM_DSC_BITS                    ( TM_DSC_BITS       ),
    .C_CNTR_WIDTH                   ( C_CNTR_WIDTH      )
   ) user_control_i (
    .user_clk                       ( user_clk          ),
    .user_reset_n                   ( axi_aresetn       ),
    .m_axil_wvalid                  ( m_axil_wvalid     ),
    .m_axil_wready                  ( m_axil_wready     ),
    .m_axil_awaddr                  ( m_axil_awaddr[11:0]),
    .m_axil_wdata                   ( m_axil_wdata      ),
    .m_axil_rdata                   ( m_axil_rdata      ),
    .m_axil_rdata_bram              ( m_axil_rdata_bram ),
    .m_axil_araddr                  ( m_axil_araddr[11:0]),
    // Need more AXI Lite
    .gen_user_reset_n               ( gen_user_reset_n    ),
    .axi_mm_h2c_valid               ( 1'b0                ), // Used when MM and Stream concurrent test is run
    .axi_mm_h2c_ready               ( 1'b0                ), // Used when MM and Stream concurrent test is run
    .axi_mm_c2h_valid               ( 1'b0                ), // Used when MM and Stream concurrent test is run
    .axi_mm_c2h_ready               ( 1'b0                ), // Used when MM and Stream concurrent test is run
    .axi_st_h2c_valid               ( m_axis_h2c_tvalid   ),
    .axi_st_h2c_ready               ( m_axis_h2c_tready   ),
    .axi_st_c2h_valid               ( s_axis_c2h_tvalid   ),
    .axi_st_c2h_ready               ( s_axis_c2h_tready   ),
    .c2h_st_qid                     ( c2h_st_qid          ),
    .control_reg_c2h                ( control_reg_c2h     ),
    .control_reg_c2h2               ( control_reg_c2h2    ),
    .c2h_num_pkt                    ( c2h_num_pkt         ),
    .clr_h2c_match                  ( clr_h2c_match       ),
    .c2h_st_len                     ( c2h_st_len          ),
    .h2c_count                      ( h2c_count           ),
    .h2c_match                      ( h2c_match           ),
    .h2c_qid                        ( h2c_qid             ),
    .wb_dat                         ( wb_dat              ),
    .credit_out                     ( credit_out          ),
    .credit_updt                    ( credit_updt         ),
    .credit_perpkt_in               ( credit_perpkt_in    ),
    .credit_needed                  ( credit_needed       ),
    .buf_count                      ( buf_count           ),
    .axis_c2h_drop                  ( axis_c2h_status_drop  ),
    .axis_c2h_drop_valid            ( axis_c2h_status_valid ),
    .cmpt_size                      ( cmpt_size           ),
    .c2h_st_marker_rsp              ( c2h_st_marker_rsp   ),

    // FLR   
    .usr_flr_fnc ( usr_flr_fnc ),
    .usr_flr_set ( usr_flr_set ),
    .usr_flr_clr ( usr_flr_clr) ,
    .usr_flr_done_fnc (usr_flr_done_fnc),
    .usr_flr_done_vld (usr_flr_done_vld),

   // IRQ		     
    .usr_irq_in_vld   (usr_irq_in_vld),
    .usr_irq_in_vec   (usr_irq_in_vec),
    .usr_irq_in_fnc   (usr_irq_in_fnc),
    .usr_irq_out_ack  (usr_irq_out_ack),
    .usr_irq_out_fail (usr_irq_out_fail),

		     
    // tm interface signals
    .tm_dsc_sts_vld                 ( tm_dsc_sts_vld      ),
    .tm_dsc_sts_qen                 ( tm_dsc_sts_qen      ),
    .tm_dsc_sts_byp                 ( tm_dsc_sts_byp      ),
    .tm_dsc_sts_dir                 ( tm_dsc_sts_dir      ),
    .tm_dsc_sts_mm                  ( tm_dsc_sts_mm       ), 
    .tm_dsc_sts_qid                 ( tm_dsc_sts_qid      ),
    .tm_dsc_sts_avl                 ( tm_dsc_sts_avl      ),
    .tm_dsc_sts_qinv                ( tm_dsc_sts_qinv     ),
    .tm_dsc_sts_irq_arm             ( tm_dsc_sts_irq_arm  ),
    .tm_dsc_sts_rdy                 ( tm_dsc_sts_rdy      ),
    
    .stat_vld                       ( stat_vld           ),
    .stat_err                       ( stat_err           ),
    
    // qid output signals
    .qid_rdy                        ( qid_rdy            ),
    .qid_vld                        ( qid_vld            ),
    .qid                            ( qid                ),
    .qid_desc_avail                 ( qid_desc_avail     ),
    .desc_cnt_dec                   ( desc_cnt_dec       ),
    .desc_cnt_dec_qid               ( desc_cnt_dec_qid   ),
    .requeue_vld                    ( requeue_vld        ),
    .requeue_qid                    ( requeue_qid        ),
    .requeue_rdy                    ( requeue_rdy        ),
    .dbg_userctrl_credits           ( dbg_userctrl_credits ),
    
    // Performance counter signals
    .user_cntr_max                  ( user_cntr_max      ),
    .user_cntr_rst                  ( user_cntr_rst      ),
    .user_cntr_read                 ( user_cntr_read     ),
    .free_cnts                      ( free_cnts          ),
    .idle_cnts                      ( idle_cnts          ),
    .busy_cnts                      ( busy_cnts          ),
    .actv_cnts                      ( actv_cnts          ),
    
    .h2c_user_cntr_max              ( h2c_user_cntr_max  ),
    .h2c_user_cntr_rst              ( h2c_user_cntr_rst  ),
    .h2c_user_cntr_read             ( h2c_user_cntr_read ),
    .h2c_free_cnts                  ( h2c_free_cnts      ),
    .h2c_idle_cnts                  ( h2c_idle_cnts      ),
    .h2c_busy_cnts                  ( h2c_busy_cnts      ),
    .h2c_actv_cnts                  ( h2c_actv_cnts      ),
    
    // l3fwd latency signals
    .user_l3fwd_max                 ( user_l3fwd_max     ),
    .user_l3fwd_en                  ( user_l3fwd_en      ),
    .user_l3fwd_mode                ( user_l3fwd_mode    ),
    .user_l3fwd_rst                 ( user_l3fwd_rst     ),
    .user_l3fwd_read                ( user_l3fwd_read    ),
    
    .max_latency                    ( max_latency        ),
    .min_latency                    ( min_latency        ),
    .sum_latency                    ( sum_latency        ),
    .num_pkt_rcvd                   ( num_pkt_rcvd       )
  );
  
  axi_st_module #(
    .C_DATA_WIDTH                   ( C_DATA_WIDTH_ST    ),
    .QID_MAX                        ( QID_MAX            ),
    .TM_DSC_BITS                    ( TM_DSC_BITS        ),
    .CRC_WIDTH                      ( CRC_WIDTH          ),
    .C_CNTR_WIDTH                   ( C_CNTR_WIDTH       )
  ) axi_st_module_i (
    .user_reset_n                   ( axi_aresetn & gen_user_reset_n ),
    .user_clk                       ( user_clk           ),
//    .c2h_st_qid                     ( c2h_st_qid         ), // Internally generated now
    .control_reg_c2h                ( control_reg_c2h    ),
    .control_reg_c2h2               ( control_reg_c2h2   ),
    .clr_h2c_match                  ( clr_h2c_match      ),
//    .c2h_st_len                     ( c2h_st_len         ), // Internally generated now
    .c2h_num_pkt                    ( c2h_num_pkt        ),
    .h2c_count                      ( h2c_count          ),
    .h2c_match                      ( h2c_match          ),
    .h2c_qid                        ( h2c_qid            ),
    .wb_dat                         ( wb_dat             ),
    .cmpt_size                      ( cmpt_size          ),
    .credit_in                      ( credit_out         ),
    .credit_updt                    ( credit_updt        ),
    .credit_perpkt_in               ( credit_perpkt_in   ),
    .credit_needed                  ( credit_needed      ),
    .buf_count                      ( buf_count          ),
    .m_axis_h2c_tvalid              ( m_axis_h2c_tvalid  ),
    .m_axis_h2c_tready              ( m_axis_h2c_tready  ),
    .m_axis_h2c_tdata               ( m_axis_h2c_tdata   ),
    .m_axis_h2c_tlast               ( m_axis_h2c_tlast   ),
  //  .m_axis_h2c_dpar                ( m_axis_h2c_dpar    ),
    .m_axis_h2c_tuser_qid           ( m_axis_h2c_tuser_qid        ),
    .m_axis_h2c_tuser_port_id       ( m_axis_h2c_tuser_port_id    ),
    .m_axis_h2c_tuser_err           ( m_axis_h2c_tuser_err        ),
    .m_axis_h2c_tuser_mdata         ( m_axis_h2c_tuser_mdata      ),
    .m_axis_h2c_tuser_mty           ( m_axis_h2c_tuser_mty        ),
    .m_axis_h2c_tuser_zero_byte     ( m_axis_h2c_tuser_zero_byte  ),
    .s_axis_c2h_tdata               ( s_axis_c2h_tdata            ),
 //   .s_axis_c2h_dpar                ( s_axis_c2h_dpar             ),
    .s_axis_c2h_tcrc                ( s_axis_c2h_tcrc             ),
    .s_axis_c2h_ctrl_marker         ( s_axis_c2h_ctrl_marker      ),
    .s_axis_c2h_ctrl_len            ( s_axis_c2h_ctrl_len         ),   // c2h_st_len,
    .s_axis_c2h_ctrl_qid            ( s_axis_c2h_ctrl_qid         ),   // st_qid,
    .s_axis_c2h_ctrl_user_trig      ( s_axis_c2h_ctrl_user_trig   ),
    .s_axis_c2h_ctrl_dis_cmpt       ( s_axis_c2h_ctrl_dis_cmpt    ),   // disable write back, write back not valid
    .s_axis_c2h_ctrl_imm_data       ( s_axis_c2h_ctrl_imm_data    ),   // immediate data, 1 = data in transfer, 0 = no data in transfer
    .s_axis_c2h_ctrl_ecc            ( s_axis_c2h_ctrl_ecc         ),
    .s_axis_c2h_tvalid              ( s_axis_c2h_tvalid           ),
    .s_axis_c2h_tready              ( s_axis_c2h_tready           ),
    .s_axis_c2h_tlast               ( s_axis_c2h_tlast            ),
    .s_axis_c2h_mty                 ( s_axis_c2h_mty              ),   // no empty bytes at EOP
    .s_axis_c2h_cmpt_tdata          ( s_axis_c2h_cmpt_tdata       ),
    .s_axis_c2h_cmpt_size           ( s_axis_c2h_cmpt_size        ),
    .s_axis_c2h_cmpt_dpar           ( s_axis_c2h_cmpt_dpar        ),
    .s_axis_c2h_cmpt_tvalid         ( s_axis_c2h_cmpt_tvalid      ),
    .s_axis_c2h_cmpt_tlast          ( s_axis_c2h_cmpt_tlast       ),
    .s_axis_c2h_cmpt_tready         ( s_axis_c2h_cmpt_tready      ),
    .s_axis_c2h_cmpt_ctrl_qid             ( s_axis_c2h_cmpt_ctrl_qid             ),
    .s_axis_c2h_cmpt_ctrl_cmpt_type       ( s_axis_c2h_cmpt_ctrl_cmpt_type       ),
    .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ( s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
    .s_axis_c2h_cmpt_ctrl_port_id         ( s_axis_c2h_cmpt_ctrl_port_id         ),
    .s_axis_c2h_cmpt_ctrl_marker          ( s_axis_c2h_cmpt_ctrl_marker          ),
    .s_axis_c2h_cmpt_ctrl_user_trig       ( s_axis_c2h_cmpt_ctrl_user_trig       ),
    .s_axis_c2h_cmpt_ctrl_col_idx         ( s_axis_c2h_cmpt_ctrl_col_idx         ),
    .s_axis_c2h_cmpt_ctrl_err_idx         ( s_axis_c2h_cmpt_ctrl_err_idx         ),
    
    .stat_vld                       ( stat_vld           ),
    .stat_err                       ( stat_err           ),
    
    // qid input signals
    .qid_rdy                        ( qid_rdy            ),
    .qid_vld                        ( qid_vld            ),
    .qid                            ( qid                ),
    .qid_desc_avail                 ( qid_desc_avail     ),
    .desc_cnt_dec                   ( desc_cnt_dec       ),
    .desc_cnt_dec_qid               ( desc_cnt_dec_qid   ),
    .requeue_vld                    ( requeue_vld        ),
    .requeue_qid                    ( requeue_qid        ),
    .requeue_rdy                    ( requeue_rdy        ),
    .dbg_userctrl_credits           ( dbg_userctrl_credits ),
    
    // Performance counter signals
    .user_cntr_max                  ( user_cntr_max      ),
    .user_cntr_rst                  ( user_cntr_rst      ),
    .user_cntr_read                 ( user_cntr_read     ),
    .free_cnts_o                    ( free_cnts          ),
    .idle_cnts_o                    ( idle_cnts          ),
    .busy_cnts_o                    ( busy_cnts          ),
    .actv_cnts_o                    ( actv_cnts          ),
    
    .h2c_user_cntr_max              ( h2c_user_cntr_max  ),
    .h2c_user_cntr_rst              ( h2c_user_cntr_rst  ),
    .h2c_user_cntr_read             ( h2c_user_cntr_read ),
    .h2c_free_cnts_o                ( h2c_free_cnts      ),
    .h2c_idle_cnts_o                ( h2c_idle_cnts      ),
    .h2c_busy_cnts_o                ( h2c_busy_cnts      ),
    .h2c_actv_cnts_o                ( h2c_actv_cnts      ),
    
    // l3fwd latency signals
    .user_l3fwd_max                 ( user_l3fwd_max     ),
    .user_l3fwd_en                  ( user_l3fwd_en      ),
    .user_l3fwd_mode                ( user_l3fwd_mode    ),
    .user_l3fwd_rst                 ( user_l3fwd_rst     ),
    .user_l3fwd_read                ( user_l3fwd_read    ),
    
    .max_latency                    ( max_latency        ),
    .min_latency                    ( min_latency        ),
    .sum_latency                    ( sum_latency        ),
    .num_pkt_rcvd                   ( num_pkt_rcvd       )
   );

  // Marker Response
  assign c2h_st_marker_rsp = (qsts_out_vld & (qsts_out_op == 8'b0)) ? 1'b1 : 1'b0;
*/
   
endmodule
