//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//-----------------------------------------------------------------------------
//
// Project    : CPM5-QDMA based Acceleration system design 
// File       : design_1_wrapper.sv
// Version    : 1.0
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
    input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   PCIE0_GT_0_grx_p,
    input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   PCIE0_GT_0_grx_n,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   PCIE0_GT_0_gtx_p,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   PCIE0_GT_0_gtx_n,
    input          gt_refclk0_0_clk_n,
    input          gt_refclk0_0_clk_p,
	
	output [5:0]	CH0_LPDDR4_0_0_ca_a,
    output [5:0]	CH0_LPDDR4_0_0_ca_b,
    output [0:0]	CH0_LPDDR4_0_0_ck_c_a,
    output [0:0]	CH0_LPDDR4_0_0_ck_c_b,
    output [0:0]	CH0_LPDDR4_0_0_ck_t_a,
    output [0:0]	CH0_LPDDR4_0_0_ck_t_b,
    output [0:0]	CH0_LPDDR4_0_0_cke_a,
    output [0:0]	CH0_LPDDR4_0_0_cke_b,
    output [0:0]	CH0_LPDDR4_0_0_cs_a,
    output [0:0]	CH0_LPDDR4_0_0_cs_b,
    inout  [1:0]	CH0_LPDDR4_0_0_dmi_a,
    inout  [1:0]	CH0_LPDDR4_0_0_dmi_b,
    inout  [15:0]	CH0_LPDDR4_0_0_dq_a,
    inout  [15:0]	CH0_LPDDR4_0_0_dq_b,
    inout  [1:0]	CH0_LPDDR4_0_0_dqs_c_a,
    inout  [1:0]	CH0_LPDDR4_0_0_dqs_c_b,
    inout  [1:0]	CH0_LPDDR4_0_0_dqs_t_a,
    inout  [1:0]	CH0_LPDDR4_0_0_dqs_t_b,
    output [0:0]	CH0_LPDDR4_0_0_reset_n,
    output [5:0]	CH0_LPDDR4_0_1_ca_a,
    output [5:0]	CH0_LPDDR4_0_1_ca_b,
    output [0:0]	CH0_LPDDR4_0_1_ck_c_a,
    output [0:0]	CH0_LPDDR4_0_1_ck_c_b,
    output [0:0]	CH0_LPDDR4_0_1_ck_t_a,
    output [0:0]	CH0_LPDDR4_0_1_ck_t_b,
    output [0:0]	CH0_LPDDR4_0_1_cke_a,
    output [0:0]	CH0_LPDDR4_0_1_cke_b,
    output [0:0]	CH0_LPDDR4_0_1_cs_a,
    output [0:0]	CH0_LPDDR4_0_1_cs_b,
    inout  [1:0]	CH0_LPDDR4_0_1_dmi_a,
    inout  [1:0]	CH0_LPDDR4_0_1_dmi_b,
    inout  [15:0]	CH0_LPDDR4_0_1_dq_a,
    inout  [15:0]	CH0_LPDDR4_0_1_dq_b,
    inout  [1:0]	CH0_LPDDR4_0_1_dqs_c_a,
    inout  [1:0]	CH0_LPDDR4_0_1_dqs_c_b,
    inout  [1:0]	CH0_LPDDR4_0_1_dqs_t_a,
    inout  [1:0]	CH0_LPDDR4_0_1_dqs_t_b,
    output [0:0]	CH0_LPDDR4_0_1_reset_n,
    output [5:0]	CH0_LPDDR4_0_2_ca_a,
    output [5:0]	CH0_LPDDR4_0_2_ca_b,
    output [0:0]	CH0_LPDDR4_0_2_ck_c_a,
    output [0:0]	CH0_LPDDR4_0_2_ck_c_b,
    output [0:0]	CH0_LPDDR4_0_2_ck_t_a,
    output [0:0]	CH0_LPDDR4_0_2_ck_t_b,
    output [0:0]	CH0_LPDDR4_0_2_cke_a,
    output [0:0]	CH0_LPDDR4_0_2_cke_b,
    output [0:0]	CH0_LPDDR4_0_2_cs_a,
    output [0:0]	CH0_LPDDR4_0_2_cs_b,
    inout  [1:0]	CH0_LPDDR4_0_2_dmi_a,
    inout  [1:0]	CH0_LPDDR4_0_2_dmi_b,
    inout  [15:0]	CH0_LPDDR4_0_2_dq_a,
    inout  [15:0]	CH0_LPDDR4_0_2_dq_b,
    inout  [1:0]	CH0_LPDDR4_0_2_dqs_c_a,
    inout  [1:0]	CH0_LPDDR4_0_2_dqs_c_b,
    inout  [1:0]	CH0_LPDDR4_0_2_dqs_t_a,
    inout  [1:0]	CH0_LPDDR4_0_2_dqs_t_b,
    output [0:0]	CH0_LPDDR4_0_2_reset_n,
    output [5:0]	CH1_LPDDR4_0_0_ca_a,
    output [5:0]	CH1_LPDDR4_0_0_ca_b,
    output [0:0]	CH1_LPDDR4_0_0_ck_c_a,
    output [0:0]	CH1_LPDDR4_0_0_ck_c_b,
    output [0:0]	CH1_LPDDR4_0_0_ck_t_a,
    output [0:0]	CH1_LPDDR4_0_0_ck_t_b,
    output [0:0]	CH1_LPDDR4_0_0_cke_a,
    output [0:0]	CH1_LPDDR4_0_0_cke_b,
    output [0:0]	CH1_LPDDR4_0_0_cs_a,
    output [0:0]	CH1_LPDDR4_0_0_cs_b,
    inout  [1:0]	CH1_LPDDR4_0_0_dmi_a,
    inout  [1:0]	CH1_LPDDR4_0_0_dmi_b,
    inout  [15:0]	CH1_LPDDR4_0_0_dq_a,
    inout  [15:0]	CH1_LPDDR4_0_0_dq_b,
    inout  [1:0]	CH1_LPDDR4_0_0_dqs_c_a,
    inout  [1:0]	CH1_LPDDR4_0_0_dqs_c_b,
    inout  [1:0]	CH1_LPDDR4_0_0_dqs_t_a,
    inout  [1:0]	CH1_LPDDR4_0_0_dqs_t_b,
    output [0:0]	CH1_LPDDR4_0_0_reset_n,
    output [5:0]	CH1_LPDDR4_0_1_ca_a,
    output [5:0]	CH1_LPDDR4_0_1_ca_b,
    output [0:0]	CH1_LPDDR4_0_1_ck_c_a,
    output [0:0]	CH1_LPDDR4_0_1_ck_c_b,
    output [0:0]	CH1_LPDDR4_0_1_ck_t_a,
    output [0:0]	CH1_LPDDR4_0_1_ck_t_b,
    output [0:0]	CH1_LPDDR4_0_1_cke_a,
    output [0:0]	CH1_LPDDR4_0_1_cke_b,
    output [0:0]	CH1_LPDDR4_0_1_cs_a,
    output [0:0]	CH1_LPDDR4_0_1_cs_b,
    inout  [1:0]	CH1_LPDDR4_0_1_dmi_a,
    inout  [1:0]	CH1_LPDDR4_0_1_dmi_b,
    inout  [15:0]	CH1_LPDDR4_0_1_dq_a,
    inout  [15:0]	CH1_LPDDR4_0_1_dq_b,
    inout  [1:0]	CH1_LPDDR4_0_1_dqs_c_a,
    inout  [1:0]	CH1_LPDDR4_0_1_dqs_c_b,
    inout  [1:0]	CH1_LPDDR4_0_1_dqs_t_a,
    inout  [1:0]	CH1_LPDDR4_0_1_dqs_t_b,
    output [0:0]	CH1_LPDDR4_0_1_reset_n,
    output [5:0]	CH1_LPDDR4_0_2_ca_a,
    output [5:0]	CH1_LPDDR4_0_2_ca_b,
    output [0:0]	CH1_LPDDR4_0_2_ck_c_a,
    output [0:0]	CH1_LPDDR4_0_2_ck_c_b,
    output [0:0]	CH1_LPDDR4_0_2_ck_t_a,
    output [0:0]	CH1_LPDDR4_0_2_ck_t_b,
    output [0:0]	CH1_LPDDR4_0_2_cke_a,
    output [0:0]	CH1_LPDDR4_0_2_cke_b,
    output [0:0]	CH1_LPDDR4_0_2_cs_a,
    output [0:0]	CH1_LPDDR4_0_2_cs_b,
    inout  [1:0]	CH1_LPDDR4_0_2_dmi_a,
    inout  [1:0]	CH1_LPDDR4_0_2_dmi_b,
    inout  [15:0]	CH1_LPDDR4_0_2_dq_a,
    inout  [15:0]	CH1_LPDDR4_0_2_dq_b,
    inout  [1:0]	CH1_LPDDR4_0_2_dqs_c_a,
    inout  [1:0]	CH1_LPDDR4_0_2_dqs_c_b,
    inout  [1:0]	CH1_LPDDR4_0_2_dqs_t_a,
    inout  [1:0]	CH1_LPDDR4_0_2_dqs_t_b,
    output [0:0]	CH1_LPDDR4_0_2_reset_n,
	input  [0:0]	sys_clk0_0_clk_n,
	input  [0:0]	sys_clk0_0_clk_p,
	input  [0:0]	sys_clk0_1_clk_n,
	input  [0:0]	sys_clk0_1_clk_p,
	input  [0:0]	sys_clk0_2_clk_n,
	input  [0:0]	sys_clk0_2_clk_p
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
   localparam          QID_MAX                = 8;
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
   wire [41:0]                       m_axil_awaddr;
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
   wire [41:0]                       m_axil_araddr;
   wire [2:0]                        m_axil_arprot;
   wire                              m_axil_arvalid;
   wire                              m_axil_arready;
   //-- AXI Master Read Data Channel
   wire [31:0]                       m_axil_rdata_bram;
   wire [31:0]                       ps_pl_axil_rdata_bram;
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
   wire [10:0]                       qid;
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
   wire                              m_axis_h2c_tvalid;
   wire                              m_axis_h2c_tready;
   wire                              m_axis_h2c_tlast;
   wire [11:0]                       m_axis_h2c_tuser_qid;
   wire [2:0]                        m_axis_h2c_tuser_port_id;
   wire                              m_axis_h2c_tuser_err;
   wire [31:0]                       m_axis_h2c_tuser_mdata;
   wire [5:0]                        m_axis_h2c_tuser_mty;
   wire                              m_axis_h2c_tuser_zero_byte;
   
   wire [2:0]						 tm_dsc_sts_port_id;

   wire                              m_axis_h2c_tready_lpbk;
   wire                              m_axis_h2c_tready_int;
   // AXIS C2H packet wire
   wire [C_DATA_WIDTH-1:0]           s_axis_c2h_tdata;  
   wire [CRC_WIDTH-1:0]              s_axis_c2h_tcrc;
   //wire [C_DATA_WIDTH/8-1:0]         s_axis_c2h_dpar;  
   wire                              s_axis_c2h_ctrl_marker;
   wire [2:0]                        s_axis_c2h_ctrl_port_id;
   wire [15:0]                       s_axis_c2h_ctrl_len;
   wire [11:0]                       s_axis_c2h_ctrl_qid ;
   wire                              s_axis_c2h_ctrl_user_trig ;
   wire                              s_axis_c2h_ctrl_dis_cmpt ;
   wire                              s_axis_c2h_ctrl_imm_data ;
   wire [6:0]                        s_axis_c2h_ctrl_ecc ;
   wire [C_DATA_WIDTH-1:0]           s_axis_c2h_tdata_int;
   wire                              s_axis_c2h_ctrl_marker_int;
   wire [15:0]                       s_axis_c2h_ctrl_len_int;
   wire [10:0]                       s_axis_c2h_ctrl_qid_int ;
   wire                              s_axis_c2h_ctrl_user_trig_int ;
   wire                              s_axis_c2h_ctrl_dis_cmpt_int ;
   wire                              s_axis_c2h_ctrl_imm_data_int ;
   wire [6:0]                        s_axis_c2h_ctrl_ecc_int ;
   //wire [C_DATA_WIDTH/8-1:0]         s_axis_c2h_dpar_int;
   wire                              s_axis_c2h_tvalid;
   wire                              s_axis_c2h_tready;
   wire                              s_axis_c2h_tlast;
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
   wire                              s_axis_c2h_cmpt_tvalid;
   wire                              s_axis_c2h_cmpt_tlast;
   wire                              s_axis_c2h_cmpt_tready;
   wire                              s_axis_c2h_cmpt_tvalid_lpbk;
   wire                              s_axis_c2h_cmpt_tlast_lpbk;
   wire                              s_axis_c2h_cmpt_tvalid_int;
   wire                              s_axis_c2h_cmpt_tlast_int;
   wire [12:0]                       s_axis_c2h_cmpt_ctrl_qid;
   wire [1:0]                        s_axis_c2h_cmpt_ctrl_cmpt_type;
   wire [15:0]                       s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
   wire [2:0]                        s_axis_c2h_cmpt_ctrl_port_id;
   wire                              s_axis_c2h_cmpt_ctrl_marker;
   wire                              s_axis_c2h_cmpt_ctrl_no_wrb_marker;
   wire                              s_axis_c2h_cmpt_ctrl_user_trig;
   wire [2:0]                        s_axis_c2h_cmpt_ctrl_col_idx;
   wire [2:0]                        s_axis_c2h_cmpt_ctrl_err_idx;
   
   wire                              usr_irq_in_valid;
   wire [4:0]                        usr_irq_in_vec = 5'b1;//Driver maps user_irq to vector1 by default.
   wire [12:0]                       usr_irq_in_fnc = 8'h0;
   wire                              usr_irq_out_ack;
   wire                              usr_irq_out_fail;

   wire                              tm_dsc_sts_vld;
   wire                              tm_dsc_sts_qen;
   wire                              tm_dsc_sts_byp;
   wire                              tm_dsc_sts_dir;
   wire                              tm_dsc_sts_mm;
   wire                              tm_dsc_sts_error;   // Not yet connected
   wire [11:0]                       tm_dsc_sts_qid;
   wire [15:0]                       tm_dsc_sts_avl;
   wire                              tm_dsc_sts_qinv;
   wire                              tm_dsc_sts_irq_arm;
   wire                              tm_dsc_sts_rdy;

   wire                              c2h_st_marker_rsp;

   // Descriptor credit In 
   (* MARK_DEBUG="true" *) logic                              dsc_crdt_in_vld;
   (* MARK_DEBUG="true" *) logic                              dsc_crdt_in_rdy;
   (* MARK_DEBUG="true" *) logic                              dsc_crdt_in_dir; //C2H
   (* MARK_DEBUG="true" *) logic                              dsc_crdt_in_fence; //coalesced
   (* MARK_DEBUG="true" *) logic [11:0]                       dsc_crdt_in_qid;
   (* MARK_DEBUG="true" *) logic [15:0]                       dsc_crdt_in_crdt;
   
   wire [31:0]						 m_axis_h2c_tcrc;

   // Report the DROP case
   wire                              axis_c2h_status_drop; 
   wire                              axis_c2h_status_last; 
   wire                              axis_c2h_status_valid; 
//EQDMA update   wire                              axis_c2h_status_imm_or_marker; 
   wire                              axis_c2h_status_cmp; 
   wire [11:0]                       axis_c2h_status_qid;
   wire                              axis_c2h_dmawr_cmp;
   wire  [2:0]                       axis_c2h_dmawr_port_id;
   
   wire [7:0]                        qsts_out_op;
   wire [63:0]                       qsts_out_data;
   wire [2:0]                        qsts_out_port_id;
   wire [12:0]                       qsts_out_qid;
   wire                              qsts_out_vld;
   wire                              qsts_out_rdy = 1'b1;

   wire                              gen_user_reset_n;
   wire                              st_loopback;

   wire [10:0]                       c2h_num_pkt;
   wire [10:0]                       c2h_st_qid;
   wire [15:0]                       c2h_st_len;
   wire [31:0]                       h2c_count;
   wire                              h2c_match;
   wire                              clr_h2c_match;
   wire [31:0]                       control_reg_c2h;
   wire [31:0]                       control_reg_c2h2;
   wire [10:0]                       h2c_qid;
   wire [31:0]                       cmpt_size;
   wire [255:0]                      wb_dat;
   wire [TM_DSC_BITS-1:0]            credit_out;
   wire [TM_DSC_BITS-1:0]            credit_needed;
   wire [TM_DSC_BITS-1:0]            credit_perpkt_in;
   wire                              credit_updt;
   wire [15:0]                       buf_count;
   wire                              sys_clk_gt; 
 
   
   wire [41:0]	ps_pl_axil_araddr;
   wire [2:0]	ps_pl_axil_arprot;
   wire 		ps_pl_axil_arready;
   wire 		ps_pl_axil_arvalid;
   wire [41:0]	ps_pl_axil_awaddr;
   wire [2:0]	ps_pl_axil_awprot;
   wire 		ps_pl_axil_awready;
   wire 		ps_pl_axil_awvalid;
   wire 		ps_pl_axil_bready;
   wire [1:0]	ps_pl_axil_bresp;
   wire		    ps_pl_axil_bvalid;
   wire [31:0]	ps_pl_axil_rdata;
   wire 		ps_pl_axil_rready;
   wire [1:0]	ps_pl_axil_rresp;
   wire 		ps_pl_axil_rvalid;
   wire [31:0]	ps_pl_axil_wdata;
   wire 		ps_pl_axil_wready;
   wire [3:0]	ps_pl_axil_wstrb;
   wire 		ps_pl_axil_wvalid;
   
   wire [15:0]	dma0_c2h_byp_in_mm_0_0_cidx;
   wire 		dma0_c2h_byp_in_mm_0_0_error;
   wire [11:0]	dma0_c2h_byp_in_mm_0_0_func;
   wire [15:0]	dma0_c2h_byp_in_mm_0_0_len;
   wire 		dma0_c2h_byp_in_mm_0_0_mrkr_req;
   wire 		dma0_c2h_byp_in_mm_0_0_no_dma;
   wire [2:0]	dma0_c2h_byp_in_mm_0_0_port_id;
   wire [11:0]	dma0_c2h_byp_in_mm_0_0_qid;
   wire [63:0]	dma0_c2h_byp_in_mm_0_0_radr;
   wire 		dma0_c2h_byp_in_mm_0_0_ready;
   wire 		dma0_c2h_byp_in_mm_0_0_sdi;
   wire 		dma0_c2h_byp_in_mm_0_0_valid;
   wire [63:0]	dma0_c2h_byp_in_mm_0_0_wadr;
   wire [15:0]	dma0_c2h_byp_in_mm_1_0_cidx;
   wire 		dma0_c2h_byp_in_mm_1_0_error;
   wire [11:0]	dma0_c2h_byp_in_mm_1_0_func;
   wire [15:0]	dma0_c2h_byp_in_mm_1_0_len;
   wire 		dma0_c2h_byp_in_mm_1_0_mrkr_req;
   wire 		dma0_c2h_byp_in_mm_1_0_no_dma;
   wire [2:0]	dma0_c2h_byp_in_mm_1_0_port_id;
   wire [11:0]	dma0_c2h_byp_in_mm_1_0_qid;
   wire [63:0]	dma0_c2h_byp_in_mm_1_0_radr;
   wire 		dma0_c2h_byp_in_mm_1_0_ready;
   wire 		dma0_c2h_byp_in_mm_1_0_sdi;
   wire 		dma0_c2h_byp_in_mm_1_0_valid;
   wire [63:0]	dma0_c2h_byp_in_mm_1_0_wadr;
   wire [63:0]	dma0_c2h_byp_in_st_csh_0_addr;
   wire 		dma0_c2h_byp_in_st_csh_0_error;
   wire [11:0]	dma0_c2h_byp_in_st_csh_0_func;
   wire [6:0]	dma0_c2h_byp_in_st_csh_0_pfch_tag;
   wire [2:0]	dma0_c2h_byp_in_st_csh_0_port_id;
   wire [11:0]	dma0_c2h_byp_in_st_csh_0_qid;
   wire 		dma0_c2h_byp_in_st_csh_0_ready;
   wire 		dma0_c2h_byp_in_st_csh_0_valid;
   
   wire [15:0]	dma0_c2h_byp_out_0_cidx;
   wire [255:0]	dma0_c2h_byp_out_0_dsc;
   wire [1:0]	dma0_c2h_byp_out_0_dsc_sz;
   wire 		dma0_c2h_byp_out_0_error;
   wire [2:0]	dma0_c2h_byp_out_0_fmt;
   wire [11:0]	dma0_c2h_byp_out_0_func;
   wire 		dma0_c2h_byp_out_0_mm_chn;
   wire [6:0]	dma0_c2h_byp_out_0_pfch_tag;
   wire [2:0]	dma0_c2h_byp_out_0_port_id;
   wire [11:0]	dma0_c2h_byp_out_0_qid;
   //wire 		dma0_c2h_byp_out_0_ready_st;
   wire 		dma0_c2h_byp_out_0_ready;
   wire 		dma0_c2h_byp_out_0_st_mm;
   wire 		dma0_c2h_byp_out_0_valid;
   
   wire [31:0] qdma_c2h_dsc_byp_ctrl; 
   wire		   cdma_introut;
   logic [31:0] BTT;
   (* MARK_DEBUG="true" *)  logic [31:0] cdma_trfr_sz;
   (* MARK_DEBUG="true" *)  logic		c2h_mm_data_rdy_intr;
   (* MARK_DEBUG="true" *)  logic		c2h_mm_data_rdy_intr_clr;
   //(* MARK_DEBUG="true" *) logic 		h2c_sop;
   logic		c2h_sop;   
   
   logic [63:0] dma0_c2h_byp_in_st_csh_addr;
   logic [11:0] dma0_c2h_byp_in_st_csh_qid;
   logic        dma0_c2h_byp_in_st_csh_error;
   logic [11:0] dma0_c2h_byp_in_st_csh_func;
   logic [2:0]  dma0_c2h_byp_in_st_csh_port_id;
   logic [6:0]  dma0_c2h_byp_in_st_csh_pfch_tag;
   logic        dma0_c2h_byp_in_st_csh_vld;
   logic        dma0_c2h_byp_in_st_csh_rdy;

   
   logic [31:0] ps_pl_axil_awaddr_bd;
   logic [31:0] ps_pl_axil_awaddr_reg;
   logic [31:0] ps_pl_axil_araddr_bd;
   logic [31:0] ps_pl_axil_araddr_reg;
   logic [31:0] m_axil_awaddr_bd;
   logic [31:0] m_axil_awaddr_reg;
   logic [31:0] m_axil_araddr_bd;
   logic [31:0] m_axil_araddr_reg;
   
   logic [1:0] c2h_dsc_byp_mode;
   
dsc_byp_c2h dsc_byp_c2h_i
  (
    
	.user_clk				 (user_clk),
	.user_reset_n			 (gen_user_reset_n),
	
	.BTT					 (BTT),
	//.c2h_byp_qid			 (qdma_c2h_dsc_byp_ctrl[31:20]),//(c2h_byp_qid),
	.qdma_c2h_dsc_byp_ctrl	 (qdma_c2h_dsc_byp_ctrl),
	
    .c2h_dsc_bypass          (c2h_dsc_byp_mode),//(2'b10),//(c2h_dsc_bypass), -- Simple bypass
    .c2h_mm_marker_req       (1'b0),//(c2h_mm_marker_req),
    .c2h_mm_marker_rsp       (),
    .c2h_mm_channel_sel	     (qdma_c2h_dsc_byp_ctrl[17]),
	.cdma_trfr_sz			 (cdma_trfr_sz),
	.cdma_introut			 (cdma_introut),
		
    .c2h_byp_out_dsc         (dma0_c2h_byp_out_0_dsc),
    .c2h_byp_out_fmt         (dma0_c2h_byp_out_0_fmt),
    .c2h_byp_out_st_mm       (dma0_c2h_byp_out_0_st_mm),
    .c2h_byp_out_dsc_sz      (dma0_c2h_byp_out_0_dsc_sz),
    .c2h_byp_out_qid         (dma0_c2h_byp_out_0_qid),
    .c2h_byp_out_error       (dma0_c2h_byp_out_0_error),
    .c2h_byp_out_func        (dma0_c2h_byp_out_0_func),
    .c2h_byp_out_cidx        (dma0_c2h_byp_out_0_cidx),
    .c2h_byp_out_port_id     (dma0_c2h_byp_out_0_port_id),
    .c2h_byp_out_pfch_tag    (dma0_c2h_byp_out_0_pfch_tag),
    .c2h_byp_out_vld         (dma0_c2h_byp_out_0_valid),
    .c2h_byp_out_rdy         (dma0_c2h_byp_out_0_ready),
//    .c2h_st_marker_rsp       (c2h_st_marker_rsp),
    .c2h_st_marker_rsp       (),
	
    .c2h_byp_in_mm_0_radr      (),
    .c2h_byp_in_mm_0_wadr      (dma0_c2h_byp_in_mm_0_0_wadr),
    .c2h_byp_in_mm_0_len       (dma0_c2h_byp_in_mm_0_0_len),
    .c2h_byp_in_mm_0_mrkr_req  (dma0_c2h_byp_in_mm_0_0_mrkr_req),
    .c2h_byp_in_mm_0_sdi       (dma0_c2h_byp_in_mm_0_0_sdi),
    .c2h_byp_in_mm_0_qid       (dma0_c2h_byp_in_mm_0_0_qid),
    .c2h_byp_in_mm_0_error     (dma0_c2h_byp_in_mm_0_0_error),
    .c2h_byp_in_mm_0_func      (dma0_c2h_byp_in_mm_0_0_func),
    .c2h_byp_in_mm_0_cidx      (dma0_c2h_byp_in_mm_0_0_cidx),
    .c2h_byp_in_mm_0_port_id   (dma0_c2h_byp_in_mm_0_0_port_id),
    .c2h_byp_in_mm_0_no_dma    (dma0_c2h_byp_in_mm_0_0_no_dma),
    .c2h_byp_in_mm_0_vld       (dma0_c2h_byp_in_mm_0_0_valid),
    .c2h_byp_in_mm_0_rdy       (dma0_c2h_byp_in_mm_0_0_ready),
		
	.c2h_byp_in_mm_1_radr      (),
    .c2h_byp_in_mm_1_wadr      (dma0_c2h_byp_in_mm_1_0_wadr),
    .c2h_byp_in_mm_1_len       (dma0_c2h_byp_in_mm_1_0_len),
    .c2h_byp_in_mm_1_mrkr_req  (dma0_c2h_byp_in_mm_1_0_mrkr_req),
    .c2h_byp_in_mm_1_sdi       (dma0_c2h_byp_in_mm_1_0_sdi),
    .c2h_byp_in_mm_1_qid       (dma0_c2h_byp_in_mm_1_0_qid),
    .c2h_byp_in_mm_1_error     (dma0_c2h_byp_in_mm_1_0_error),
    .c2h_byp_in_mm_1_func      (dma0_c2h_byp_in_mm_1_0_func),
    .c2h_byp_in_mm_1_cidx      (dma0_c2h_byp_in_mm_1_0_cidx),
    .c2h_byp_in_mm_1_port_id   (dma0_c2h_byp_in_mm_1_0_port_id),
    .c2h_byp_in_mm_1_no_dma    (dma0_c2h_byp_in_mm_1_0_no_dma),
    .c2h_byp_in_mm_1_vld       (dma0_c2h_byp_in_mm_1_0_valid),
    .c2h_byp_in_mm_1_rdy       (dma0_c2h_byp_in_mm_1_0_ready),

    .c2h_byp_in_st_csh_addr      (dma0_c2h_byp_in_st_csh_0_addr),
    .c2h_byp_in_st_csh_qid       (dma0_c2h_byp_in_st_csh_0_qid),
    .c2h_byp_in_st_csh_error     (dma0_c2h_byp_in_st_csh_0_error),
    .c2h_byp_in_st_csh_func      (dma0_c2h_byp_in_st_csh_0_func),
    .c2h_byp_in_st_csh_port_id   (dma0_c2h_byp_in_st_csh_0_port_id),
    .c2h_byp_in_st_csh_pfch_tag  (dma0_c2h_byp_in_st_csh_0_pfch_tag),
    .c2h_byp_in_st_csh_vld       (dma0_c2h_byp_in_st_csh_0_valid),
    .c2h_byp_in_st_csh_rdy       (dma0_c2h_byp_in_st_csh_0_ready),
    .pfch_byp_tag                (7'h00),//(pfch_byp_tag),
	
	.c2h_mm_data_rdy_intr		 (c2h_mm_data_rdy_intr),
	.c2h_mm_data_rdy_intr_clr	 (c2h_mm_data_rdy_intr_clr)
  );
  
  
  
  
  assign usr_irq_in_valid  = c2h_mm_data_rdy_intr ? 1'b1 : 1'b0;
  
 design_1 design_1_i (
      .gt_refclk0_0_clk_n			(gt_refclk0_0_clk_n),
      .gt_refclk0_0_clk_p			(gt_refclk0_0_clk_p),

      .PCIE0_GT_0_grx_n				(PCIE0_GT_0_grx_n),
      .PCIE0_GT_0_grx_p				(PCIE0_GT_0_grx_p),
      .PCIE0_GT_0_gtx_n				(PCIE0_GT_0_gtx_n),
      .PCIE0_GT_0_gtx_p				(PCIE0_GT_0_gtx_p),

      .M_AXIL_araddr  				(m_axil_araddr),
      .M_AXIL_arprot  				(m_axil_arprot),
      .M_AXIL_arready 				(m_axil_arready),
      .M_AXIL_arvalid 				(m_axil_arvalid),
      .M_AXIL_awaddr  				(m_axil_awaddr),
      .M_AXIL_awprot  				(m_axil_awprot),
      .M_AXIL_awready 				(m_axil_awready),
      .M_AXIL_awvalid 				(m_axil_awvalid),
      .M_AXIL_bready  				(m_axil_bready),
      .M_AXIL_bresp   				(m_axil_bresp),
      .M_AXIL_bvalid  				(m_axil_bvalid),
      .M_AXIL_rdata   				(m_axil_rdata),
      .M_AXIL_rready  				(m_axil_rready),
      .M_AXIL_rresp   				(m_axil_rresp),
      .M_AXIL_rvalid  				(m_axil_rvalid),
      .M_AXIL_wdata   				(m_axil_wdata),
      .M_AXIL_wready  				(m_axil_wready),
      .M_AXIL_wstrb   				(m_axil_wstrb),
      .M_AXIL_wvalid  				(m_axil_wvalid),  
	  
      .ps_pl_axil_araddr			(ps_pl_axil_araddr),
      .ps_pl_axil_arprot			(ps_pl_axil_arprot),
      .ps_pl_axil_arready			(ps_pl_axil_arready),
      .ps_pl_axil_arvalid			(ps_pl_axil_arvalid),
      .ps_pl_axil_awaddr			(ps_pl_axil_awaddr),
      .ps_pl_axil_awprot			(ps_pl_axil_awprot),
      .ps_pl_axil_awready			(ps_pl_axil_awready),
      .ps_pl_axil_awvalid			(ps_pl_axil_awvalid),
      .ps_pl_axil_bready			(ps_pl_axil_bready),
      .ps_pl_axil_bresp				(ps_pl_axil_bresp),
      .ps_pl_axil_bvalid			(ps_pl_axil_bvalid),
      .ps_pl_axil_rdata				(ps_pl_axil_rdata),
      .ps_pl_axil_rready			(ps_pl_axil_rready),
      .ps_pl_axil_rresp				(ps_pl_axil_rresp),
      .ps_pl_axil_rvalid			(ps_pl_axil_rvalid),
      .ps_pl_axil_wdata				(ps_pl_axil_wdata),
      .ps_pl_axil_wready			(ps_pl_axil_wready),
      .ps_pl_axil_wstrb				(ps_pl_axil_wstrb),
      .ps_pl_axil_wvalid			(ps_pl_axil_wvalid),
	  
      .dma0_c2h_byp_in_mm_0_0_cidx		(dma0_c2h_byp_in_mm_0_0_cidx),
      .dma0_c2h_byp_in_mm_0_0_error		(dma0_c2h_byp_in_mm_0_0_error),
      .dma0_c2h_byp_in_mm_0_0_func		(dma0_c2h_byp_in_mm_0_0_func),
      .dma0_c2h_byp_in_mm_0_0_len		(dma0_c2h_byp_in_mm_0_0_len),
      .dma0_c2h_byp_in_mm_0_0_mrkr_req	(dma0_c2h_byp_in_mm_0_0_mrkr_req),
      .dma0_c2h_byp_in_mm_0_0_no_dma	(dma0_c2h_byp_in_mm_0_0_no_dma),
      .dma0_c2h_byp_in_mm_0_0_port_id	(dma0_c2h_byp_in_mm_0_0_port_id),
      .dma0_c2h_byp_in_mm_0_0_qid		(dma0_c2h_byp_in_mm_0_0_qid),
      .dma0_c2h_byp_in_mm_0_0_radr		(dma0_c2h_byp_in_mm_0_0_radr),
      .dma0_c2h_byp_in_mm_0_0_ready		(dma0_c2h_byp_in_mm_0_0_ready),
      .dma0_c2h_byp_in_mm_0_0_sdi		(dma0_c2h_byp_in_mm_0_0_sdi),
      .dma0_c2h_byp_in_mm_0_0_valid		(dma0_c2h_byp_in_mm_0_0_valid),
      .dma0_c2h_byp_in_mm_0_0_wadr		(dma0_c2h_byp_in_mm_0_0_wadr),
      .dma0_c2h_byp_in_mm_1_0_cidx		(dma0_c2h_byp_in_mm_1_0_cidx),
      .dma0_c2h_byp_in_mm_1_0_error		(dma0_c2h_byp_in_mm_1_0_error),
      .dma0_c2h_byp_in_mm_1_0_func		(dma0_c2h_byp_in_mm_1_0_func),
      .dma0_c2h_byp_in_mm_1_0_len		(dma0_c2h_byp_in_mm_1_0_len),
      .dma0_c2h_byp_in_mm_1_0_mrkr_req	(dma0_c2h_byp_in_mm_1_0_mrkr_req),
      .dma0_c2h_byp_in_mm_1_0_no_dma	(dma0_c2h_byp_in_mm_1_0_no_dma),
      .dma0_c2h_byp_in_mm_1_0_port_id	(dma0_c2h_byp_in_mm_1_0_port_id),
      .dma0_c2h_byp_in_mm_1_0_qid		(dma0_c2h_byp_in_mm_1_0_qid),
      .dma0_c2h_byp_in_mm_1_0_radr		(dma0_c2h_byp_in_mm_1_0_radr),
      .dma0_c2h_byp_in_mm_1_0_ready		(dma0_c2h_byp_in_mm_1_0_ready),
      .dma0_c2h_byp_in_mm_1_0_sdi		(dma0_c2h_byp_in_mm_1_0_sdi),
      .dma0_c2h_byp_in_mm_1_0_valid		(dma0_c2h_byp_in_mm_1_0_valid),
      .dma0_c2h_byp_in_mm_1_0_wadr		(dma0_c2h_byp_in_mm_1_0_wadr),
      .dma0_c2h_byp_in_st_csh_0_addr	(dma0_c2h_byp_in_st_csh_0_addr),
      .dma0_c2h_byp_in_st_csh_0_error	(dma0_c2h_byp_in_st_csh_0_error),
      .dma0_c2h_byp_in_st_csh_0_func	(dma0_c2h_byp_in_st_csh_0_func),
      .dma0_c2h_byp_in_st_csh_0_pfch_tag(dma0_c2h_byp_in_st_csh_0_pfch_tag),
      .dma0_c2h_byp_in_st_csh_0_port_id	(dma0_c2h_byp_in_st_csh_0_port_id),
      .dma0_c2h_byp_in_st_csh_0_qid		(dma0_c2h_byp_in_st_csh_0_qid),
      .dma0_c2h_byp_in_st_csh_0_ready	(dma0_c2h_byp_in_st_csh_0_ready),
      .dma0_c2h_byp_in_st_csh_0_valid	(dma0_c2h_byp_in_st_csh_0_valid),
	  
	  
      .dma0_c2h_byp_out_0_cidx			(dma0_c2h_byp_out_0_cidx),
      .dma0_c2h_byp_out_0_dsc			(dma0_c2h_byp_out_0_dsc),
      .dma0_c2h_byp_out_0_dsc_sz		(dma0_c2h_byp_out_0_dsc_sz),
      .dma0_c2h_byp_out_0_error			(dma0_c2h_byp_out_0_error),
      .dma0_c2h_byp_out_0_fmt			(dma0_c2h_byp_out_0_fmt),
      .dma0_c2h_byp_out_0_func			(dma0_c2h_byp_out_0_func),
      .dma0_c2h_byp_out_0_mm_chn		(dma0_c2h_byp_out_0_mm_chn),
      .dma0_c2h_byp_out_0_pfch_tag		(dma0_c2h_byp_out_0_pfch_tag),
      .dma0_c2h_byp_out_0_port_id		(dma0_c2h_byp_out_0_port_id),
      .dma0_c2h_byp_out_0_qid			(dma0_c2h_byp_out_0_qid),
      .dma0_c2h_byp_out_0_ready			(dma0_c2h_byp_out_0_ready),
      .dma0_c2h_byp_out_0_st_mm			(dma0_c2h_byp_out_0_st_mm),
      .dma0_c2h_byp_out_0_valid			(dma0_c2h_byp_out_0_valid),
		
      .dma0_s_axis_c2h_0_tcrc         	(s_axis_c2h_tcrc ), 
      .dma0_s_axis_c2h_0_mty          	(s_axis_c2h_mty),
      .dma0_s_axis_c2h_0_ecc          	(s_axis_c2h_ctrl_ecc),
      .dma0_s_axis_c2h_0_tdata        	(s_axis_c2h_tdata),
      .dma0_s_axis_c2h_0_tlast        	(s_axis_c2h_tlast),
      .dma0_s_axis_c2h_0_tready       	(s_axis_c2h_tready),
      .dma0_s_axis_c2h_0_tvalid       	(s_axis_c2h_tvalid),
      .dma0_s_axis_c2h_0_ctrl_has_cmpt	(~s_axis_c2h_ctrl_dis_cmpt ), // 1 = Sends write back. 0 = disable write back, write back not valid
      .dma0_s_axis_c2h_0_ctrl_len     	(s_axis_c2h_ctrl_len),
      .dma0_s_axis_c2h_0_ctrl_marker  	(s_axis_c2h_ctrl_marker),
      .dma0_s_axis_c2h_0_ctrl_port_id 	(3'b000), //s_axis_c2h_ctrl_port_id),
      .dma0_s_axis_c2h_0_ctrl_qid     	(s_axis_c2h_ctrl_qid),

      .dma0_s_axis_c2h_cmpt_0_data     		  (s_axis_c2h_cmpt_tdata),
      .dma0_s_axis_c2h_cmpt_0_dpar     		  (s_axis_c2h_cmpt_dpar),
      .dma0_s_axis_c2h_cmpt_0_tready   		  (s_axis_c2h_cmpt_tready),
      .dma0_s_axis_c2h_cmpt_0_tvalid   		  (s_axis_c2h_cmpt_tvalid),
      .dma0_s_axis_c2h_cmpt_0_size            (s_axis_c2h_cmpt_size),
      .dma0_s_axis_c2h_cmpt_0_cmpt_type       (s_axis_c2h_cmpt_ctrl_cmpt_type),
      .dma0_s_axis_c2h_cmpt_0_err_idx         (s_axis_c2h_cmpt_ctrl_err_idx),
      .dma0_s_axis_c2h_cmpt_0_marker          (s_axis_c2h_cmpt_ctrl_marker),
      .dma0_s_axis_c2h_cmpt_0_col_idx         (s_axis_c2h_cmpt_ctrl_col_idx),
      .dma0_s_axis_c2h_cmpt_0_port_id         ('b00),
      //.dma0_s_axis_c2h_cmpt_0_qid             ({2'b0,s_axis_c2h_cmpt_ctrl_qid}       ),
      .dma0_s_axis_c2h_cmpt_0_qid             (s_axis_c2h_cmpt_ctrl_qid),
      .dma0_s_axis_c2h_cmpt_0_user_trig       (s_axis_c2h_cmpt_ctrl_user_trig),
      .dma0_s_axis_c2h_cmpt_0_wait_pld_pkt_id (s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id),
      .dma0_s_axis_c2h_cmpt_0_no_wrb_marker   (s_axis_c2h_cmpt_ctrl_no_wrb_marker),

 
      .dma0_axis_c2h_status_0_drop 		  (axis_c2h_status_drop  ),
      .dma0_axis_c2h_status_0_qid  		  (axis_c2h_status_qid   ),
      .dma0_axis_c2h_status_0_valid		  (axis_c2h_status_valid ),
      .dma0_axis_c2h_status_0_status_cmp  (axis_c2h_status_cmp   ),
      .dma0_axis_c2h_status_0_error		  (), //axis_c2h_status_error ), // TODO
      .dma0_axis_c2h_status_0_last 		  (axis_c2h_status_last  ),

      .dma0_axis_c2h_dmawr_0_cmp    	(axis_c2h_dmawr_cmp), 
      .dma0_axis_c2h_dmawr_0_port_id	(axis_c2h_dmawr_port_id), //TODO

      .dma0_dsc_crdt_in_0_crdt     (dsc_crdt_in_crdt ),
      .dma0_dsc_crdt_in_0_qid      (dsc_crdt_in_qid  ),
      .dma0_dsc_crdt_in_0_rdy      (dsc_crdt_in_rdy  ),
      .dma0_dsc_crdt_in_0_dir      (dsc_crdt_in_dir  ), 
      .dma0_dsc_crdt_in_0_valid    (dsc_crdt_in_vld  ),
      .dma0_dsc_crdt_in_0_fence    (dsc_crdt_in_fence),     
      
      .dma0_m_axis_h2c_0_err       (m_axis_h2c_tuser_err      ),
      .dma0_m_axis_h2c_0_mdata     (m_axis_h2c_tuser_mdata    ),
      .dma0_m_axis_h2c_0_mty       (m_axis_h2c_tuser_mty      ),
      .dma0_m_axis_h2c_0_tcrc      (m_axis_h2c_tcrc      ),     //TODO crc or par?
      .dma0_m_axis_h2c_0_port_id   (m_axis_h2c_tuser_port_id  ),
      .dma0_m_axis_h2c_0_qid       (m_axis_h2c_tuser_qid      ),
      .dma0_m_axis_h2c_0_tdata     (m_axis_h2c_tdata    ),
      .dma0_m_axis_h2c_0_tlast     (m_axis_h2c_tlast    ),
      .dma0_m_axis_h2c_0_tready    (m_axis_h2c_tready   ),
      .dma0_m_axis_h2c_0_tvalid    (m_axis_h2c_tvalid   ),
      .dma0_m_axis_h2c_0_zero_byte (m_axis_h2c_tuser_zero_byte),
	  
	  .CH0_LPDDR4_0_0_ca_a			(CH0_LPDDR4_0_0_ca_a),
      .CH0_LPDDR4_0_0_ca_b			(CH0_LPDDR4_0_0_ca_b),
      .CH0_LPDDR4_0_0_ck_c_a		(CH0_LPDDR4_0_0_ck_c_a),
      .CH0_LPDDR4_0_0_ck_c_b		(CH0_LPDDR4_0_0_ck_c_b),
      .CH0_LPDDR4_0_0_ck_t_a		(CH0_LPDDR4_0_0_ck_t_a),
      .CH0_LPDDR4_0_0_ck_t_b		(CH0_LPDDR4_0_0_ck_t_b),
      .CH0_LPDDR4_0_0_cke_a			(CH0_LPDDR4_0_0_cke_a),
      .CH0_LPDDR4_0_0_cke_b			(CH0_LPDDR4_0_0_cke_b),
      .CH0_LPDDR4_0_0_cs_a			(CH0_LPDDR4_0_0_cs_a),
      .CH0_LPDDR4_0_0_cs_b			(CH0_LPDDR4_0_0_cs_b),
      .CH0_LPDDR4_0_0_dmi_a			(CH0_LPDDR4_0_0_dmi_a),
      .CH0_LPDDR4_0_0_dmi_b			(CH0_LPDDR4_0_0_dmi_b),
      .CH0_LPDDR4_0_0_dq_a			(CH0_LPDDR4_0_0_dq_a),
      .CH0_LPDDR4_0_0_dq_b			(CH0_LPDDR4_0_0_dq_b),
      .CH0_LPDDR4_0_0_dqs_c_a		(CH0_LPDDR4_0_0_dqs_c_a),
      .CH0_LPDDR4_0_0_dqs_c_b		(CH0_LPDDR4_0_0_dqs_c_b),
      .CH0_LPDDR4_0_0_dqs_t_a		(CH0_LPDDR4_0_0_dqs_t_a),
      .CH0_LPDDR4_0_0_dqs_t_b		(CH0_LPDDR4_0_0_dqs_t_b),
      .CH0_LPDDR4_0_0_reset_n		(CH0_LPDDR4_0_0_reset_n),
      .CH0_LPDDR4_0_1_ca_a			(CH0_LPDDR4_0_1_ca_a),
      .CH0_LPDDR4_0_1_ca_b			(CH0_LPDDR4_0_1_ca_b),
      .CH0_LPDDR4_0_1_ck_c_a		(CH0_LPDDR4_0_1_ck_c_a),
      .CH0_LPDDR4_0_1_ck_c_b		(CH0_LPDDR4_0_1_ck_c_b),
      .CH0_LPDDR4_0_1_ck_t_a		(CH0_LPDDR4_0_1_ck_t_a),
      .CH0_LPDDR4_0_1_ck_t_b		(CH0_LPDDR4_0_1_ck_t_b),
      .CH0_LPDDR4_0_1_cke_a			(CH0_LPDDR4_0_1_cke_a),
      .CH0_LPDDR4_0_1_cke_b			(CH0_LPDDR4_0_1_cke_b),
      .CH0_LPDDR4_0_1_cs_a			(CH0_LPDDR4_0_1_cs_a),
      .CH0_LPDDR4_0_1_cs_b			(CH0_LPDDR4_0_1_cs_b),
      .CH0_LPDDR4_0_1_dmi_a			(CH0_LPDDR4_0_1_dmi_a),
      .CH0_LPDDR4_0_1_dmi_b			(CH0_LPDDR4_0_1_dmi_b),
      .CH0_LPDDR4_0_1_dq_a			(CH0_LPDDR4_0_1_dq_a),
      .CH0_LPDDR4_0_1_dq_b			(CH0_LPDDR4_0_1_dq_b),
      .CH0_LPDDR4_0_1_dqs_c_a		(CH0_LPDDR4_0_1_dqs_c_a),
      .CH0_LPDDR4_0_1_dqs_c_b		(CH0_LPDDR4_0_1_dqs_c_b),
      .CH0_LPDDR4_0_1_dqs_t_a		(CH0_LPDDR4_0_1_dqs_t_a),
      .CH0_LPDDR4_0_1_dqs_t_b		(CH0_LPDDR4_0_1_dqs_t_b),
      .CH0_LPDDR4_0_1_reset_n		(CH0_LPDDR4_0_1_reset_n),
      .CH0_LPDDR4_0_2_ca_a			(CH0_LPDDR4_0_2_ca_a),
      .CH0_LPDDR4_0_2_ca_b			(CH0_LPDDR4_0_2_ca_b),
      .CH0_LPDDR4_0_2_ck_c_a		(CH0_LPDDR4_0_2_ck_c_a),
      .CH0_LPDDR4_0_2_ck_c_b		(CH0_LPDDR4_0_2_ck_c_b),
      .CH0_LPDDR4_0_2_ck_t_a		(CH0_LPDDR4_0_2_ck_t_a),
      .CH0_LPDDR4_0_2_ck_t_b		(CH0_LPDDR4_0_2_ck_t_b),
      .CH0_LPDDR4_0_2_cke_a			(CH0_LPDDR4_0_2_cke_a),
      .CH0_LPDDR4_0_2_cke_b			(CH0_LPDDR4_0_2_cke_b),
      .CH0_LPDDR4_0_2_cs_a			(CH0_LPDDR4_0_2_cs_a),
      .CH0_LPDDR4_0_2_cs_b			(CH0_LPDDR4_0_2_cs_b),
      .CH0_LPDDR4_0_2_dmi_a			(CH0_LPDDR4_0_2_dmi_a),
      .CH0_LPDDR4_0_2_dmi_b			(CH0_LPDDR4_0_2_dmi_b),
      .CH0_LPDDR4_0_2_dq_a			(CH0_LPDDR4_0_2_dq_a),
      .CH0_LPDDR4_0_2_dq_b			(CH0_LPDDR4_0_2_dq_b),
      .CH0_LPDDR4_0_2_dqs_c_a		(CH0_LPDDR4_0_2_dqs_c_a),
      .CH0_LPDDR4_0_2_dqs_c_b		(CH0_LPDDR4_0_2_dqs_c_b),
      .CH0_LPDDR4_0_2_dqs_t_a		(CH0_LPDDR4_0_2_dqs_t_a),
      .CH0_LPDDR4_0_2_dqs_t_b		(CH0_LPDDR4_0_2_dqs_t_b),
      .CH0_LPDDR4_0_2_reset_n		(CH0_LPDDR4_0_2_reset_n),
      .CH1_LPDDR4_0_0_ca_a			(CH1_LPDDR4_0_0_ca_a),
      .CH1_LPDDR4_0_0_ca_b			(CH1_LPDDR4_0_0_ca_b),
      .CH1_LPDDR4_0_0_ck_c_a		(CH1_LPDDR4_0_0_ck_c_a),
      .CH1_LPDDR4_0_0_ck_c_b		(CH1_LPDDR4_0_0_ck_c_b),
      .CH1_LPDDR4_0_0_ck_t_a		(CH1_LPDDR4_0_0_ck_t_a),
      .CH1_LPDDR4_0_0_ck_t_b		(CH1_LPDDR4_0_0_ck_t_b),
      .CH1_LPDDR4_0_0_cke_a			(CH1_LPDDR4_0_0_cke_a),
      .CH1_LPDDR4_0_0_cke_b			(CH1_LPDDR4_0_0_cke_b),
      .CH1_LPDDR4_0_0_cs_a			(CH1_LPDDR4_0_0_cs_a),
      .CH1_LPDDR4_0_0_cs_b			(CH1_LPDDR4_0_0_cs_b),
      .CH1_LPDDR4_0_0_dmi_a			(CH1_LPDDR4_0_0_dmi_a),
      .CH1_LPDDR4_0_0_dmi_b			(CH1_LPDDR4_0_0_dmi_b),
      .CH1_LPDDR4_0_0_dq_a			(CH1_LPDDR4_0_0_dq_a),
      .CH1_LPDDR4_0_0_dq_b			(CH1_LPDDR4_0_0_dq_b),
      .CH1_LPDDR4_0_0_dqs_c_a		(CH1_LPDDR4_0_0_dqs_c_a),
      .CH1_LPDDR4_0_0_dqs_c_b		(CH1_LPDDR4_0_0_dqs_c_b),
      .CH1_LPDDR4_0_0_dqs_t_a		(CH1_LPDDR4_0_0_dqs_t_a),
      .CH1_LPDDR4_0_0_dqs_t_b		(CH1_LPDDR4_0_0_dqs_t_b),
      .CH1_LPDDR4_0_0_reset_n		(CH1_LPDDR4_0_0_reset_n),
      .CH1_LPDDR4_0_1_ca_a			(CH1_LPDDR4_0_1_ca_a),
      .CH1_LPDDR4_0_1_ca_b			(CH1_LPDDR4_0_1_ca_b),
      .CH1_LPDDR4_0_1_ck_c_a		(CH1_LPDDR4_0_1_ck_c_a),
      .CH1_LPDDR4_0_1_ck_c_b		(CH1_LPDDR4_0_1_ck_c_b),
      .CH1_LPDDR4_0_1_ck_t_a		(CH1_LPDDR4_0_1_ck_t_a),
      .CH1_LPDDR4_0_1_ck_t_b		(CH1_LPDDR4_0_1_ck_t_b),
      .CH1_LPDDR4_0_1_cke_a			(CH1_LPDDR4_0_1_cke_a),
      .CH1_LPDDR4_0_1_cke_b			(CH1_LPDDR4_0_1_cke_b),
      .CH1_LPDDR4_0_1_cs_a			(CH1_LPDDR4_0_1_cs_a),
      .CH1_LPDDR4_0_1_cs_b			(CH1_LPDDR4_0_1_cs_b),
      .CH1_LPDDR4_0_1_dmi_a			(CH1_LPDDR4_0_1_dmi_a),
      .CH1_LPDDR4_0_1_dmi_b			(CH1_LPDDR4_0_1_dmi_b),
      .CH1_LPDDR4_0_1_dq_a			(CH1_LPDDR4_0_1_dq_a),
      .CH1_LPDDR4_0_1_dq_b			(CH1_LPDDR4_0_1_dq_b),
      .CH1_LPDDR4_0_1_dqs_c_a		(CH1_LPDDR4_0_1_dqs_c_a),
      .CH1_LPDDR4_0_1_dqs_c_b		(CH1_LPDDR4_0_1_dqs_c_b),
      .CH1_LPDDR4_0_1_dqs_t_a		(CH1_LPDDR4_0_1_dqs_t_a),
      .CH1_LPDDR4_0_1_dqs_t_b		(CH1_LPDDR4_0_1_dqs_t_b),
      .CH1_LPDDR4_0_1_reset_n		(CH1_LPDDR4_0_1_reset_n),
      .CH1_LPDDR4_0_2_ca_a			(CH1_LPDDR4_0_2_ca_a),
      .CH1_LPDDR4_0_2_ca_b			(CH1_LPDDR4_0_2_ca_b),
      .CH1_LPDDR4_0_2_ck_c_a		(CH1_LPDDR4_0_2_ck_c_a),
      .CH1_LPDDR4_0_2_ck_c_b		(CH1_LPDDR4_0_2_ck_c_b),
      .CH1_LPDDR4_0_2_ck_t_a		(CH1_LPDDR4_0_2_ck_t_a),
      .CH1_LPDDR4_0_2_ck_t_b		(CH1_LPDDR4_0_2_ck_t_b),
      .CH1_LPDDR4_0_2_cke_a			(CH1_LPDDR4_0_2_cke_a),
      .CH1_LPDDR4_0_2_cke_b			(CH1_LPDDR4_0_2_cke_b),
      .CH1_LPDDR4_0_2_cs_a			(CH1_LPDDR4_0_2_cs_a),
      .CH1_LPDDR4_0_2_cs_b			(CH1_LPDDR4_0_2_cs_b),
      .CH1_LPDDR4_0_2_dmi_a			(CH1_LPDDR4_0_2_dmi_a),
      .CH1_LPDDR4_0_2_dmi_b			(CH1_LPDDR4_0_2_dmi_b),
      .CH1_LPDDR4_0_2_dq_a			(CH1_LPDDR4_0_2_dq_a),
      .CH1_LPDDR4_0_2_dq_b			(CH1_LPDDR4_0_2_dq_b),
      .CH1_LPDDR4_0_2_dqs_c_a		(CH1_LPDDR4_0_2_dqs_c_a),
      .CH1_LPDDR4_0_2_dqs_c_b		(CH1_LPDDR4_0_2_dqs_c_b),
      .CH1_LPDDR4_0_2_dqs_t_a		(CH1_LPDDR4_0_2_dqs_t_a),
      .CH1_LPDDR4_0_2_dqs_t_b		(CH1_LPDDR4_0_2_dqs_t_b),
      .CH1_LPDDR4_0_2_reset_n		(CH1_LPDDR4_0_2_reset_n),
      .sys_clk0_0_clk_n				(sys_clk0_0_clk_n),
      .sys_clk0_0_clk_p				(sys_clk0_0_clk_p),
      .sys_clk0_1_clk_n				(sys_clk0_1_clk_n),
      .sys_clk0_1_clk_p				(sys_clk0_1_clk_p),
      .sys_clk0_2_clk_n				(sys_clk0_2_clk_n),
      .sys_clk0_2_clk_p				(sys_clk0_2_clk_p),

      //.dma0_mgmt_0_cpl_dat        (),
      //.dma0_mgmt_0_cpl_rdy        (),
      //.dma0_mgmt_0_cpl_sts        (),
      //.dma0_mgmt_0_cpl_vld        (),
      //  
      //.dma0_mgmt_0_req_adr        ( ),
      //.dma0_mgmt_0_req_cmd        ( ),
      //.dma0_mgmt_0_req_dat        ( ),
      //.dma0_mgmt_0_req_fnc        ( ),
      //.dma0_mgmt_0_req_msc        ( ),
      //.dma0_mgmt_0_req_rdy        ( ),
      //.dma0_mgmt_0_req_vld        ( ),

      .dma0_st_rx_msg_0_tdata    ( ),    //st_rx_msg_data  ),
      .dma0_st_rx_msg_0_tlast    ( ),    //st_rx_msg_last  ),
      .dma0_st_rx_msg_0_tready   (1'b1), //st_rx_msg_rdy 
      .dma0_st_rx_msg_0_tvalid   ( ),    //st_rx_msg_valid ),

      .dma0_tm_dsc_sts_0_pidx    (                   ),
      .dma0_tm_dsc_sts_0_avl     (tm_dsc_sts_avl     ),
      .dma0_tm_dsc_sts_0_byp     (tm_dsc_sts_byp     ),
      .dma0_tm_dsc_sts_0_dir     (tm_dsc_sts_dir     ),
      .dma0_tm_dsc_sts_0_error   (tm_dsc_sts_error   ),
      .dma0_tm_dsc_sts_0_irq_arm (tm_dsc_sts_irq_arm ),
      .dma0_tm_dsc_sts_0_mm      (tm_dsc_sts_mm      ),
      .dma0_tm_dsc_sts_0_port_id (tm_dsc_sts_port_id ),
      .dma0_tm_dsc_sts_0_qen     (tm_dsc_sts_qen     ),
      .dma0_tm_dsc_sts_0_qid     (tm_dsc_sts_qid     ),
      .dma0_tm_dsc_sts_0_qinv    (tm_dsc_sts_qinv    ),
      .dma0_tm_dsc_sts_0_rdy     (tm_dsc_sts_rdy     ),
      .dma0_tm_dsc_sts_0_valid   (tm_dsc_sts_vld     ),

      //.dma0_usr_flr_0_clear     (usr_flr_clear    ),
      //.dma0_usr_flr_0_done_fnc  (usr_flr_done_fnc ),
      //.dma0_usr_flr_0_done_vld  (usr_flr_done_vld ),
      //.dma0_usr_flr_0_fnc       (usr_flr_fnc      ),
      //.dma0_usr_flr_0_set       (usr_flr_set      ),

      .usr_irq_0_ack      (usr_irq_out_ack   ),
      .usr_irq_0_fail     (usr_irq_out_fail  ),
      .usr_irq_0_fnc      (usr_irq_in_fnc   ),
      .usr_irq_0_valid    (usr_irq_in_valid ),
      .usr_irq_0_vec      ({6'b0,usr_irq_in_vec}),
	  
	  .cdma_introut_0		  (cdma_introut),
      
      .dma0_qsts_out_0_data     (qsts_out_data     ),
      .dma0_qsts_out_0_op       (qsts_out_op       ),
      .dma0_qsts_out_0_port_id  (qsts_out_port_id  ),
      .dma0_qsts_out_0_qid      (qsts_out_qid      ),
      .dma0_qsts_out_0_rdy      (qsts_out_rdy  ),
      .dma0_qsts_out_0_vld      (qsts_out_vld  ),

      .dma0_intrfc_resetn_0(gen_user_reset_n),
      .dma0_axi_aresetn_0(axi_aresetn),

      .cpm_cor_irq_0(),
      .cpm_misc_irq_0(),
      .cpm_uncor_irq_0(),
      .cpm_irq0_0('d0),
      .cpm_irq1_0('d0),
      .pcie0_user_clk_0(user_clk)
      );
	  
	  assign ps_pl_axil_awaddr_bd = ps_pl_axil_awaddr;
	  assign ps_pl_axil_araddr_bd = ps_pl_axil_araddr;
	  
	  axil_responder ps_pl_axil_i (
  
		.axil_aclk			(user_clk),
		.axil_aresetn		(axi_aresetn),
		.axil_awready		(ps_pl_axil_awready),
		.axil_awvalid		(ps_pl_axil_awvalid),
		.axil_awaddr_i		(ps_pl_axil_awaddr_bd),
		.axil_arready		(ps_pl_axil_arready),
		.axil_arvalid		(ps_pl_axil_arvalid),
		.axil_araddr_i		(ps_pl_axil_araddr_bd),
		.axil_wready		(ps_pl_axil_wready),
		.axil_wvalid		(ps_pl_axil_wvalid),
		.axil_rresp			(ps_pl_axil_rresp),
		.axil_rready		(ps_pl_axil_rready),
		.axil_rvalid		(ps_pl_axil_rvalid),
		.axil_bresp			(ps_pl_axil_bresp),
		.axil_bready		(ps_pl_axil_bready),
		.axil_bvalid		(ps_pl_axil_bvalid),
		.axil_awaddr_o		(ps_pl_axil_awaddr_reg),
		.axil_araddr_o		(ps_pl_axil_araddr_reg)
  
		);
	  

	  
	  PS2PL_ctrl #()
	   ps2pl_ctrl_i (
	   .user_clk                       ( user_clk ),
       .user_reset_n                   ( axi_aresetn ),
       .ps_pl_axil_wvalid              ( ps_pl_axil_wvalid ),
       .ps_pl_axil_wready              ( ps_pl_axil_wready ),
       .ps_pl_axil_awaddr              ( {16'h0, ps_pl_axil_awaddr_reg[15:0]} ),
       .ps_pl_axil_wdata               ( ps_pl_axil_wdata ),
       .ps_pl_axil_rdata               ( ps_pl_axil_rdata ),
       .qdma_c2h_dsc_byp_ctrl          ( qdma_c2h_dsc_byp_ctrl ),
       .ps_pl_axil_araddr              ( {16'h0, ps_pl_axil_araddr_reg[15:0]} ),
	   .pl_to_ddr_axi4_awaddr		   ( pl_to_ddr_axi4_awaddr ),
	   .BTT							   ( BTT ),
	   .cdma_trfr_sz				   ( cdma_trfr_sz )
	   );
	   
	   assign dma0_c2h_byp_in_mm_0_0_radr = qdma_c2h_dsc_byp_ctrl[17] ? 64'h0 : pl_to_ddr_axi4_awaddr;
	   assign dma0_c2h_byp_in_mm_1_0_radr = qdma_c2h_dsc_byp_ctrl[17] ? pl_to_ddr_axi4_awaddr : 64'h0;
	  
	  assign m_axil_awaddr_bd = m_axil_awaddr;
	  assign m_axil_araddr_bd = m_axil_araddr;
  
		axil_responder M_AXIL_i (
		
		.axil_aclk			(user_clk),
		.axil_aresetn		(axi_aresetn),
		.axil_awready		(m_axil_awready),
		.axil_awvalid		(m_axil_awvalid),
		.axil_awaddr_i		(m_axil_awaddr_bd),
		.axil_arready		(m_axil_arready),
		.axil_arvalid		(m_axil_arvalid),
		.axil_araddr_i		(m_axil_araddr_bd),
		.axil_wready		(m_axil_wready),
		.axil_wvalid		(m_axil_wvalid),
		.axil_rresp			(m_axil_rresp),
		.axil_rready		(m_axil_rready),
		.axil_rvalid		(m_axil_rvalid),
		.axil_bresp			(m_axil_bresp),
		.axil_bready		(m_axil_bready),
		.axil_bvalid		(m_axil_bvalid),
		.axil_awaddr_o		(m_axil_awaddr_reg),
		.axil_araddr_o		(m_axil_araddr_reg)
		
		); 

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
    .m_axil_awaddr                  ( {16'h0, m_axil_awaddr_reg[15:0]}),
    .m_axil_wdata                   ( m_axil_wdata      ),
    .m_axil_rdata                   ( m_axil_rdata      ),
    .m_axil_rdata_bram              ( m_axil_rdata_bram ),
    .m_axil_araddr                  ( {16'h0, m_axil_araddr_reg[15:0]}),
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
    .num_pkt_rcvd                   ( num_pkt_rcvd       ),
	.c2h_mm_data_rdy_intr_clr		( c2h_mm_data_rdy_intr_clr ),
	.c2h_dsc_byp_mode		        ( c2h_dsc_byp_mode )
  );
  
  qdma_accel_ced_axist #(
    .C_DATA_WIDTH                   ( C_DATA_WIDTH_ST    ),
    .QID_MAX                        ( QID_MAX            ),
    .TM_DSC_BITS                    ( TM_DSC_BITS        ),
    .CRC_WIDTH                      ( CRC_WIDTH          ),
    .C_CNTR_WIDTH                   ( C_CNTR_WIDTH       )
  ) qdma_accel_ced_axist_i (
    .user_reset_n                   ( axi_aresetn & gen_user_reset_n ),
    .user_clk                       ( user_clk           ),
//    .c2h_st_qid                     ( c2h_st_qid         ), // Internally generated now
    .control_reg_c2h                ( control_reg_c2h    ),
    .control_reg_c2h2               ( control_reg_c2h2   ),
    .clr_h2c_match                  ( clr_h2c_match      ),
//    .c2h_st_len                     ( c2h_st_len         ), // Internally generated now
    .c2h_num_pkt                    ( c2h_num_pkt        ),
    .wb_dat                         ( wb_dat             ),
    .cmpt_size                      ( cmpt_size          ),
	//.h2c_sop						(h2c_sop),
	.c2h_sop						(c2h_sop),
	.c2h_dsc_byp_mode				(c2h_dsc_byp_mode),
	
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
    //.s_axis_c2h_dpar                ( s_axis_c2h_dpar             ),
    .s_axis_c2h_tcrc                ( s_axis_c2h_tcrc             ),
    .s_axis_c2h_ctrl_marker         ( s_axis_c2h_ctrl_marker      ),
    .s_axis_c2h_ctrl_len            ( s_axis_c2h_ctrl_len         ),   // c2h_st_len,
    .s_axis_c2h_ctrl_qid            ( s_axis_c2h_ctrl_qid         ),   // st_qid,
    //.s_axis_c2h_ctrl_user_trig      ( s_axis_c2h_ctrl_user_trig   ),
    .s_axis_c2h_ctrl_dis_cmpt       ( s_axis_c2h_ctrl_dis_cmpt    ),   // disable write back, write back not valid
    //.s_axis_c2h_ctrl_imm_data       ( s_axis_c2h_ctrl_imm_data    ),   // immediate data, 1 = data in transfer, 0 = no data in transfer
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
    .s_axis_c2h_cmpt_ctrl_no_wrb_marker   ( s_axis_c2h_cmpt_ctrl_no_wrb_marker         ),
	
	.dsc_crdt_in_vld			(dsc_crdt_in_vld),
    .dsc_crdt_in_rdy			(dsc_crdt_in_rdy),
    .dsc_crdt_in_dir			(dsc_crdt_in_dir), //C2H
    .dsc_crdt_in_fence			(dsc_crdt_in_fence), //not coalesced
    .dsc_crdt_in_qid			(dsc_crdt_in_qid),
    .dsc_crdt_in_crdt			(dsc_crdt_in_crdt)
   );

  // Marker Response
  assign c2h_st_marker_rsp = (qsts_out_vld & (qsts_out_op == 8'b0)) ? 1'b1 : 1'b0;

endmodule
