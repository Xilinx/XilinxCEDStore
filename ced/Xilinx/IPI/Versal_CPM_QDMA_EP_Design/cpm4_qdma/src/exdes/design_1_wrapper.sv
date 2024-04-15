//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2.0 (lin64) Build 2604353 Mon Jul 29 21:08:51 MDT 2019
//Date        : Tue Jul 30 22:43:15 2019
//Host        : xsjrdevl100 running 64-bit CentOS Linux release 7.4.1708 (Core)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------

`ifndef QDMA_STM_DEFINES_SVH
    `define QDMA_STM_DEFINES_SVH
 
  typedef logic [511:0]                           mdma_int_tdata_exdes_t;
  typedef logic [10:0]                            mdma_qid_exdes_t;
  typedef logic [15:0]                            mdma_dma_buf_len_exdes_t;

    typedef struct packed {
        logic [15:0]            pld_len;
        logic                   req_wrb;
        logic                   eot;
        logic                   zero_cdh;
        logic [5:0]             rsv1;
        logic [3:0]             num_cdh;
        logic [2:0]             num_gl;
    } h2c_stub_tmh_t;

    typedef struct packed {
        logic [95:0]            cdh_data;
        h2c_stub_tmh_t          tmh;
    } h2c_stub_cdh_slot_0_t;

    typedef struct packed {
        logic [127:0]           cdh_slot_2;
        logic [127:0]           cdh_slot_1;
        h2c_stub_cdh_slot_0_t   cdh_slot_0;
        logic [63:0]            rsv4;
        logic [15:0]            rsv3;
        logic [15:0]            tdest;
        logic [9:0]             rsv2;
        logic [5:0]             flow_id;
        logic [4:0]             rsv1;
        logic [10:0]            qid;
    } h2c_stub_hdr_beat_t;

    typedef struct packed {
        logic [1:0]             rsv2;
        logic                   usr_int;
        logic                   eot;
        logic [3:0]             rsv1;
        logic [15:0]            pkt_len;
    } c2h_stub_tmh_t;

    typedef struct packed {
        logic [127:0]           cmp_data_1;
        logic [103:0]           cmp_data_0;
        c2h_stub_tmh_t          tmh;
    } c2h_stub_cmp_t;

    typedef struct packed {
        logic [127:0]           rsv5;
        c2h_stub_cmp_t          cmp;
        logic [63:0]            rsv4;
        logic [15:0]            rsv3;
        logic [15:0]            tdest;
        logic [9:0]             rsv2;
        logic [5:0]             flow_id;
        logic [4:0]             rsv1;
        logic [10:0]            qid;
    } c2h_stub_hdr_beat_t;

    typedef struct packed {
        logic [107:0]           usr_data;
        logic [7:0]             rsv1;
        logic [10:0]            qid;
        logic                   data_format;
    } c2h_stub_std_cmp_ent_t;

 typedef enum logic [1:0]    {
            WRB_DSC_8B_EXDES=0, WRB_DSC_16B_EXDES=1, WRB_DSC_32B_EXDES=2, WRB_DSC_UNKOWN_EXDES=3
        } mdma_c2h_wrb_type_exdes_e;


    typedef struct packed {
        c2h_stub_std_cmp_ent_t  cmp_ent;
        mdma_c2h_wrb_type_exdes_e     cmp_type;
        logic [$bits(c2h_stub_std_cmp_ent_t)/32-1:0] dpar;
    } c2h_stub_std_cmp_t;

// Newly added defines and struct 

   typedef struct packed {
        logic [5:0]                                     mty;        //[53:48]
        logic [31:0]                                    mdata;      //[47:16]
        logic                                           err;        //[15]
        logic [2:0]                                     port_id;    //[14:12]
        logic                                           wbc;        //[11]
        mdma_qid_exdes_t                                      qid;        //[10:0]
    } mdma_h2c_axis_tuser_exdes_t;
 
   typedef struct packed {
        logic               marker;        // Make sure the pipeline is completely flushed
        logic [2:0]         port_id;
        logic               imm_data;      // Immediate data
        logic               disable_wrb;
        logic               user_trig;     // User trigger 
        mdma_qid_exdes_t          qid;
        mdma_dma_buf_len_exdes_t  len;
    } mdma_c2h_axis_ctrl_exdes_t;

    typedef struct packed {
        mdma_int_tdata_exdes_t    tdata;
        logic [$bits(mdma_int_tdata_exdes_t)/8 - 1 :0]   par; 
    } mdma_c2h_axis_data_exdes_t;
    
   
 

`define XPREG_NORESET_EXDES(clk,q,d)			    \
    always @(posedge clk)			    \
    begin					    \
         `ifdef FOURVALCLKPROP			    \
	    q <= #(TCQ) clk? d : q;			    \
	  `else					    \
	    q <= #(TCQ) d;				    \
	  `endif				    \
     end
`define XSRREG_SYNC_EXDES(clk, reset_n, q,d,rstval)	\
         always @(posedge clk)                    \
         begin                    \
          if (reset_n == 1'b0)            \
              q <= #(TCQ) rstval;                \
          else                    \
          `ifdef FOURVALCLKPROP            \
             q <= #(TCQ) clk ? d : q;            \
           `else                    \
             q <= #(TCQ)  d;                \
           `endif                \
          end
 
 `define XSRREG_ASYNC_EXDES(clk, reset_n, q,d,rstval)	\
              always @(posedge clk or negedge reset_n)    \
              begin                    \
               if (reset_n == 1'b0)            \
                   q <= #(TCQ) rstval;                \
               else                    \
               `ifdef FOURVALCLKPROP            \
                  q <= #(TCQ) clk ? d : q;            \
                `else                    \
                  q <= #(TCQ)  d;                \
                `endif                \
               end
 
 `define XLREGS_SYNC_EXDES(clk, reset_n) \
                     always @(posedge clk)
 `define XLREGS_ASYNC_EXDES(clk, reset_n) \
                     always @(posedge clk or negedge reset_n)
 
               
 

`define XSRREG_XDMA_EXDES(clk, reset_n, q,d,rstval)        \
`ifdef SOFT_IP  \
`XSRREG_SYNC_EXDES (clk, reset_n, q,d,rstval) \
`else   \
`XSRREG_ASYNC_EXDES (clk, reset_n, q,d,rstval)  \
`endif

`define XSRREG_HARD_CLR_EXDES(clk, reset_n, q,d)        \
`ifdef SOFT_IP  \
`XPREG_NORESET_EXDES(clk, q,d) \
`else   \
`XSRREG_ASYNC_EXDES (clk, reset_n, q,d,'h0)  \
`endif

`define XLREG_XDMA_EXDES(clk, reset_n) \
`ifdef SOFT_IP \
`XLREGS_SYNC_EXDES(clk, reset_n) \
`else \
`XLREGS_ASYNC_EXDES(clk, reset_n)  \
`endif


`endif

//`include "mailbox_defines.svh"
// ref_axi256_if.sv for M/SAXIMM0/1
//Chris remove `include "ref_common_define.vh"
`include "dma_defines.svh"
`include "qdma_defines.vh"
`include "qdma_defines.svh"
`include "mdma_defines.svh"
//`include "mailbox_axi4lite_if.sv"
//`include "mailbox_xpm_sdpram_if.sv"
`include "pcie_dma_attr_defines.vh"
`include "cpm_dma_defines.svh"

`define PCIE4_NEW_PINS 1 




`timescale 1 ps / 1 ps
//`include "qdma_axi4mm_axi_bridge_exdes.vh"
//`include "pciedmacoredefines_exdes.vh"
//`include "qdma_defines_exdes.vh"
//`include "mdma_defines_exdes.svh"
`include "qdma_stm_defines.svh"
module design_1_wrapper #
  (
     parameter PL_LINK_CAP_MAX_LINK_WIDTH   = 8,           // 1- X1; 2 - X2; 4 - X4; 8 - X8
     parameter PL_SIM_FAST_LINK_TRAINING    = "FALSE",      // Simulation Speedup
     parameter PL_LINK_CAP_MAX_LINK_SPEED   = 4,            // 1- GEN1; 2 - GEN2; 4 - GEN3
     parameter C_DATA_WIDTH                 = 512 ,
     parameter EXT_PIPE_SIM                 = "FALSE",      // This Parameter has effect on selecting Enable External PIPE Interface in GUI.
     parameter C_ROOT_PORT                  = "FALSE",      // PCIe block is in root port mode
     parameter C_DEVICE_NUMBER              = 0,            // Device number for Root Port configurations only
     parameter AXIS_CCIX_RX_TDATA_WIDTH     = 256, 
     parameter AXIS_CCIX_TX_TDATA_WIDTH     = 256,
     parameter AXIS_CCIX_RX_TUSER_WIDTH     = 46,
     parameter AXIS_CCIX_TX_TUSER_WIDTH     = 46
   )
   (
     output         CH0_DDR4_0_act_n,
     output [16:0]  CH0_DDR4_0_adr,
     output [1:0]   CH0_DDR4_0_ba,
     output [1:0]   CH0_DDR4_0_bg,
     output [0:0]   CH0_DDR4_0_ck_c,
     output [0:0]   CH0_DDR4_0_ck_t,
     output [0:0]   CH0_DDR4_0_cke,
     output [0:0]   CH0_DDR4_0_cs_n,
     inout  [7:0]   CH0_DDR4_0_dm_n,
     inout  [63:0]  CH0_DDR4_0_dq,
     inout  [7:0]   CH0_DDR4_0_dqs_c,
     inout  [7:0]   CH0_DDR4_0_dqs_t,
     output [0:0]   CH0_DDR4_0_odt,
     output         CH0_DDR4_0_reset_n,
     
     input  [PL_LINK_CAP_MAX_LINK_WIDTH-1:0]   GT_Serial_RX_0_rxn,
     input  [PL_LINK_CAP_MAX_LINK_WIDTH-1:0]   GT_Serial_RX_0_rxp,
     output [PL_LINK_CAP_MAX_LINK_WIDTH-1:0]   GT_Serial_TX_0_txn,
     output [PL_LINK_CAP_MAX_LINK_WIDTH-1:0]   GT_Serial_TX_0_txp,
     
     input          GT_REFCLK0_D_0_clk_n,
     input          GT_REFCLK0_D_0_clk_p,
     input          SYS_CLK0_IN_0_clk_n,
     input          SYS_CLK0_IN_0_clk_p
//     input          CLK_IN1_D_0_clk_p,
//     input          CLK_IN1_D_0_clk_n
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
   localparam          C_DSC_MAGIC_EN         = 1;
   localparam          C_H2C_NUM_RIDS         = 64;
   localparam          C_H2C_NUM_CHNL         = MULTQ_EN ? 4 : 4;
   localparam          C_C2H_NUM_CHNL         = MULTQ_EN ? 4 : 4;
   localparam          C_C2H_NUM_RIDS         = 32;
   localparam          C_NUM_PCIE_TAGS        = 256;
   localparam          C_S_AXI_NUM_READ       = 32;
   localparam          C_S_AXI_NUM_WRITE      = 8;
   localparam          C_H2C_TUSER_WIDTH      = 55;
   localparam          C_C2H_TUSER_WIDTH      = 64;
   localparam          C_MDMA_DSC_IN_NUM_CHNL = 3;   // only 2 interface are userd. 0 is for MM and 2 is for ST. 1 is not used
   localparam          C_MAX_NUM_QUEUE        = 128;
   localparam          TM_DSC_BITS            = 16;
   
   wire                               user_lnk_up;
   
   //----------------------------------------------------------------------------------------------------------------//
   //  AXI Interface                                                                                                 //
   //----------------------------------------------------------------------------------------------------------------//
   
   wire                               user_clk;
   wire                               axi_aclk;
   wire                               axi_aresetn;
   
  // Wires for Avery HOT/WARM and COLD RESET
   wire                               avy_sys_rst_n_c;
   wire                               avy_cfg_hot_reset_out;
   reg                                avy_sys_rst_n_g;
   reg                                avy_cfg_hot_reset_out_g;
   
   assign avy_sys_rst_n_c       = avy_sys_rst_n_g;
   assign avy_cfg_hot_reset_out = avy_cfg_hot_reset_out_g;
   
   initial begin 
      avy_sys_rst_n_g         = 1;
      avy_cfg_hot_reset_out_g = 0;
   end
   
   assign user_clk            = axi_aclk;

   //----------------------------------------------------------------------------------------------------------------//
   //    System(SYS) Interface                                                                                       //
   //----------------------------------------------------------------------------------------------------------------//

   wire                               sys_clk;
   wire                               sys_rst_n_c;

   // User Clock LED Heartbeat
   reg [25:0]                         user_clk_heartbeat;

   wire [2:0]                         msi_vector_width;
   wire                               msi_enable;
   
   wire [3:0]                         leds;

   wire [5:0]                         cfg_ltssm_state;

   wire [7:0]                         c2h_sts_0;
   wire [7:0]                         h2c_sts_0;
   wire [7:0]                         c2h_sts_1;
   wire [7:0]                         h2c_sts_1;
   wire [7:0]                         c2h_sts_2;
   wire [7:0]                         h2c_sts_2;
   wire [7:0]                         c2h_sts_3;
   wire [7:0]                         h2c_sts_3;

   // MDMA signals
   wire [C_DATA_WIDTH-1:0]            m_axis_h2c_tdata;
   wire [C_DATA_WIDTH/8-1:0]          m_axis_h2c_dpar;
   wire [C_H2C_TUSER_WIDTH-1:0]       m_axis_h2c_tuser;
   //wire [5:0]                         m_axis_h2c_mty;
   wire                               m_axis_h2c_tvalid;
   wire                               m_axis_h2c_tready;
   wire                               m_axis_h2c_tlast;

   wire                               m_axis_h2c_tready_lpbk;
   wire                               m_axis_h2c_tready_int;
   // AXIS C2H packet wire
   wire [C_DATA_WIDTH-1:0]            s_axis_c2h_tdata;
   wire [C_DATA_WIDTH/8-1:0]          s_axis_c2h_dpar;
   wire                               s_axis_c2h_ctrl_marker;
   wire [2:0]                         s_axis_c2h_ctrl_port_id;
   wire [15:0]                        s_axis_c2h_ctrl_len;
   wire [10:0]                        s_axis_c2h_ctrl_qid;
   wire                               s_axis_c2h_ctrl_user_trig;
   wire                               s_axis_c2h_ctrl_dis_cmpt;
   wire                               s_axis_c2h_ctrl_imm_data;
   wire [C_DATA_WIDTH-1:0]            s_axis_c2h_tdata_int;
   wire                               s_axis_c2h_ctrl_marker_int;
   wire [15:0]                        s_axis_c2h_ctrl_len_int;
   wire [10:0]                        s_axis_c2h_ctrl_qid_int;
   wire                               s_axis_c2h_ctrl_user_trig_int;
   wire                               s_axis_c2h_ctrl_dis_cmpt_int;
   wire                               s_axis_c2h_ctrl_imm_data_int;
   wire [C_DATA_WIDTH/8-1:0]          s_axis_c2h_dpar_int;
   wire                               s_axis_c2h_tvalid;
   wire                               s_axis_c2h_tready;
   wire                               s_axis_c2h_tlast;
   wire [5:0]                         s_axis_c2h_mty; 
   wire                               s_axis_c2h_tvalid_lpbk;
   wire                               s_axis_c2h_tlast_lpbk;
   wire [5:0]                         s_axis_c2h_mty_lpbk;
   wire                               s_axis_c2h_tvalid_int;
   wire                               s_axis_c2h_tlast_int;
   wire [5:0]                         s_axis_c2h_mty_int;

   // AXIS C2H tuser wire 
   wire [127:0]                       s_axis_c2h_cmpt_tdata;
   wire [1:0]                         s_axis_c2h_cmpt_size;
   wire [15:0]                        s_axis_c2h_cmpt_dpar;
   wire                               s_axis_c2h_cmpt_tvalid;
   wire                               s_axis_c2h_cmpt_tlast;
   wire                               s_axis_c2h_cmpt_tready;
   wire                               s_axis_c2h_cmpt_tvalid_lpbk;
   wire                               s_axis_c2h_cmpt_tlast_lpbk;
   wire                               s_axis_c2h_cmpt_tvalid_int;
   wire                               s_axis_c2h_cmpt_tlast_int;
   wire [127:0]                       s_axis_c2h_cmpt_tdata_int;
   wire [1:0]                         s_axis_c2h_cmpt_size_int;
   wire [15:0]                        s_axis_c2h_cmpt_dpar_int;

   // Descriptor Bypass Out for qdma
(* mark_debug = "true" *)   wire [255:0]                       h2c_byp_out_dsc;
(* mark_debug = "true" *)   wire                               h2c_byp_out_mrkr_rsp;
(* mark_debug = "true" *)   wire                               h2c_byp_out_st_mm;
(* mark_debug = "true" *)   wire [10:0]                        h2c_byp_out_qid;
(* mark_debug = "true" *)   wire [1:0]                         h2c_byp_out_dsc_sz;
(* mark_debug = "true" *)   wire                               h2c_byp_out_error;
(* mark_debug = "true" *)   wire [7:0]                         h2c_byp_out_func;
(* mark_debug = "true" *)   wire [15:0]                        h2c_byp_out_cidx;
(* mark_debug = "true" *)   wire [2:0]                         h2c_byp_out_port_id;
 (* mark_debug = "true" *)  wire                               h2c_byp_out_vld;
(* mark_debug = "true" *)   wire                               h2c_byp_out_rdy;
(* mark_debug = "true" *)   wire                               h2c_dsc_bypass; 

   wire                               h2c_mm_marker_req;
   wire                               h2c_st_marker_req;
   wire                               h2c_mm_marker_rsp;
   wire                               h2c_st_marker_rsp;
   
(* mark_debug = "true" *)   wire [255:0]                       c2h_byp_out_dsc;
(* mark_debug = "true" *)   wire                               c2h_byp_out_mrkr_rsp;
(* mark_debug = "true" *)   wire                               c2h_byp_out_st_mm;
(* mark_debug = "true" *)   wire [1:0]                         c2h_byp_out_dsc_sz;
(* mark_debug = "true" *)   wire [10:0]                        c2h_byp_out_qid;
(* mark_debug = "true" *)   wire                               c2h_byp_out_error;
(* mark_debug = "true" *)   wire [7:0]                         c2h_byp_out_func;
 (* mark_debug = "true" *)  wire [15:0]                        c2h_byp_out_cidx;
(* mark_debug = "true" *)   wire [2:0]                         c2h_byp_out_port_id;
(* mark_debug = "true" *)   wire                               c2h_byp_out_vld;
(* mark_debug = "true" *)   wire                               c2h_byp_out_rdy;
(* mark_debug = "true" *)   wire [1:0]                         c2h_dsc_bypass; 

   wire                               c2h_mm_marker_req;
   wire                               c2h_mm_marker_rsp;
   wire                               c2h_st_marker_rsp;
   // Descriptor Bypass In for qdma MM
   wire [63:0]                        h2c_byp_in_mm_radr;
   wire [63:0]                        h2c_byp_in_mm_wadr;
   wire [27:0]                        h2c_byp_in_mm_len;
   wire                               h2c_byp_in_mm_mrkr_req;
   wire                               h2c_byp_in_mm_sdi;
   wire [10:0]                        h2c_byp_in_mm_qid;
   wire                               h2c_byp_in_mm_error;
   wire [7:0]                         h2c_byp_in_mm_func;
   wire [15:0]                        h2c_byp_in_mm_cidx;
   wire [2:0]                         h2c_byp_in_mm_port_id;
   wire                               h2c_byp_in_mm_no_dma;
   wire                               h2c_byp_in_mm_vld;
   wire                               h2c_byp_in_mm_rdy;

   wire [63:0]                        c2h_byp_in_mm_radr;
   wire [63:0]                        c2h_byp_in_mm_wadr;
   wire [27:0]                        c2h_byp_in_mm_len;
   wire                               c2h_byp_in_mm_mrkr_req;
   wire                               c2h_byp_in_mm_sdi;
   wire [10:0]                        c2h_byp_in_mm_qid;
   wire                               c2h_byp_in_mm_error;
   wire [7:0]                         c2h_byp_in_mm_func;
   wire [15:0]                        c2h_byp_in_mm_cidx;
   wire [2:0]                         c2h_byp_in_mm_port_id;
   wire                               c2h_byp_in_mm_no_dma;
   wire                               c2h_byp_in_mm_vld;
   wire                               c2h_byp_in_mm_rdy;

   // Descriptor Bypass In for qdma ST
(* mark_debug = "true" *)   wire [63:0]                        h2c_byp_in_st_addr;
(* mark_debug = "true" *)   wire [15:0]                        h2c_byp_in_st_len;
(* mark_debug = "true" *)   wire                               h2c_byp_in_st_eop;
 (* mark_debug = "true" *)  wire                               h2c_byp_in_st_sop;
(* mark_debug = "true" *)   wire                               h2c_byp_in_st_mrkr_req;
(* mark_debug = "true" *)   wire                               h2c_byp_in_st_sdi;
(* mark_debug = "true" *)   wire [10:0]                        h2c_byp_in_st_qid;
(* mark_debug = "true" *)   wire                               h2c_byp_in_st_error;
(* mark_debug = "true" *)   wire [7:0]                         h2c_byp_in_st_func;
(* mark_debug = "true" *)   wire [15:0]                        h2c_byp_in_st_cidx;
(* mark_debug = "true" *)   wire [2:0]                         h2c_byp_in_st_port_id;
(* mark_debug = "true" *)   wire                               h2c_byp_in_st_no_dma;
(* mark_debug = "true" *)   wire                               h2c_byp_in_st_vld;
(* mark_debug = "true" *)   wire                               h2c_byp_in_st_rdy;

(* mark_debug = "true" *)   wire [63:0]                        c2h_byp_in_st_csh_addr;
 (* mark_debug = "true" *)  wire [10:0]                        c2h_byp_in_st_csh_qid;
 (* mark_debug = "true" *)  wire                               c2h_byp_in_st_csh_error;
(* mark_debug = "true" *)   wire [7:0]                         c2h_byp_in_st_csh_func;
 (* mark_debug = "true" *)  wire [2:0]                         c2h_byp_in_st_csh_port_id;
 (* mark_debug = "true" *)  wire                               c2h_byp_in_st_csh_vld;
 (* mark_debug = "true" *)  wire                               c2h_byp_in_st_csh_rdy;

(* mark_debug = "true" *)   wire [63:0]                        c2h_byp_in_st_sim_addr;
(* mark_debug = "true" *)   wire [10:0]                        c2h_byp_in_st_sim_qid;
(* mark_debug = "true" *)   wire                               c2h_byp_in_st_sim_error;
(* mark_debug = "true" *)   wire [7:0]                         c2h_byp_in_st_sim_func;
 (* mark_debug = "true" *)  wire [2:0]                         c2h_byp_in_st_sim_port_id;
 (* mark_debug = "true" *)  wire                               c2h_byp_in_st_sim_vld;
 (* mark_debug = "true" *)  wire                               c2h_byp_in_st_sim_rdy;

   wire                               usr_irq_in_vld;
   wire [4:0]                         usr_irq_in_vec;
   wire [7:0]                         usr_irq_in_fnc;
   wire                               usr_irq_out_ack;
   wire                               usr_irq_out_fail;
  
   wire                               st_rx_msg_rdy;
   wire                               st_rx_msg_valid;
   wire                               st_rx_msg_last;
   wire [31:0]                        st_rx_msg_data;

   wire                               tm_dsc_sts_vld;
   wire                               tm_dsc_sts_qen;
   wire                               tm_dsc_sts_byp;
   wire                               tm_dsc_sts_dir;
   wire                               tm_dsc_sts_mm;
   wire                               tm_dsc_sts_error;
   wire [10:0]                        tm_dsc_sts_qid;
   wire [7:0]                         tm_dsc_sts_avl;
   wire                               tm_dsc_sts_qinv;
   wire                               tm_dsc_sts_irq_arm;
   wire                               tm_dsc_sts_rdy;

   // Descriptor credit In
   wire                               dsc_crdt_in_vld;
   wire                               dsc_crdt_in_rdy;
   wire                               dsc_crdt_in_dir;
   wire [10:0]                        dsc_crdt_in_qid;
   wire [15:0]                        dsc_crdt_in_crdt;

   // Report the DROP case
   wire                               axis_c2h_status_drop; 
   wire                               axis_c2h_status_last; 
   wire                               axis_c2h_status_valid; 
   wire                               axis_c2h_status_imm_or_marker; 
   wire                               axis_c2h_status_cmp; 
   wire [10:0]                        axis_c2h_status_qid; 
   // FLR
   wire [7:0]                         usr_flr_fnc;
   wire                               usr_flr_set;
   wire                               usr_flr_clr;
   wire [7:0]                         usr_flr_done_fnc;
   wire                               usr_flr_done_vld;

   wire                               soft_reset_n;
   wire                               st_loopback;
   
   wire [10:0]                        c2h_num_pkt;
   wire [10:0]                        c2h_st_qid;
   wire [15:0]                        c2h_st_len;
   wire [31:0]                        h2c_count;
   wire [1:0]                         h2c_match;
   wire                               clr_h2c_match;
   wire [31:0]                        control_reg_c2h;
   wire [10:0]                        h2c_qid;
   wire [31:0]                        cmpt_size;
   wire [255:0]                       wb_dat;
   wire [TM_DSC_BITS-1:0]             credit_out;
   wire [TM_DSC_BITS-1:0]             credit_needed;
   wire [TM_DSC_BITS-1:0]             credit_perpkt_in;
   wire                               credit_updt;
   wire [15:0] 	                      buf_count;
   wire                               sys_clk_gt; 

   wire [7:0]                         irq_in_fnc_0;
   wire [1:0]                         irq_in_pnd_0;
   wire [4:0]                         irq_in_vec_0;
   wire                               irq_in_vld_0;
   wire [4:0]                         irq_out_ack_0;
   wire                               irq_out_fail_0;

   wire                               mgmt_req_vld;
   wire [31:0]                        mgmt_req_dat;
   wire [31:0]                        mgmt_req_adr;
   wire [7:0]                         mgmt_req_fnc;
   wire [5:0]                         mgmt_req_msc;
   wire [1:0]                         mgmt_req_cmd;
   wire                               mgmt_req_rdy;

   wire                               mgmt_cpl_vld;
   wire [1:0]                         mgmt_cpl_sts;
   wire [31:0]                        mgmt_cpl_dat;
   wire                               mgmt_cpl_rdy; //    = 1'b1;
   
   // Mailbox Helper Signals
   reg [28:0]                         m_axi4l_awuser_mb, m_axi4l_aruser_mb;
   reg [7:0]                          vfg_offset_aw, vfg_offset_ar;
   reg [1:0]                          vfg_aw, vfg_ar;
   reg [2:0]                          bar_id_aw, bar_id_ar;
   reg [7:0]                          func_num_aw, func_num_ar; 
   
   wire [11:0]                        csr_addr;
   wire [19:0]                        debug_fsm;

   wire                               send_slave_rd;
   wire                               send_slave_wr;
   wire [15:0]                        set_smid;
   
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

   
(* mark_debug = "true" *)   wire [41:0]                        M00_AXI_0_araddr;
(* mark_debug = "true" *)   wire [2:0]                         M00_AXI_0_arprot;
(* mark_debug = "true" *)   wire                               M00_AXI_0_arready;
 (* mark_debug = "true" *)  wire                               M00_AXI_0_arvalid;
(* mark_debug = "true" *)   wire [41:0]                        M00_AXI_0_awaddr;
(* mark_debug = "true" *)   wire [2:0]                         M00_AXI_0_awprot;
(* mark_debug = "true" *)   wire                               M00_AXI_0_awready;
 (* mark_debug = "true" *)  wire                               M00_AXI_0_awvalid;
(* mark_debug = "true" *)   wire                               M00_AXI_0_bready;
(* mark_debug = "true" *)   reg  [1:0]                         M00_AXI_0_bresp;
(* mark_debug = "true" *)   reg                                M00_AXI_0_bvalid;
(* mark_debug = "true" *)   reg  [31:0]                        M00_AXI_0_rdata;
 (* mark_debug = "true" *)  wire                               M00_AXI_0_rready;
(* mark_debug = "true" *)   reg  [1:0]                         M00_AXI_0_rresp;
(* mark_debug = "true" *)   reg                                M00_AXI_0_rvalid;
(* mark_debug = "true" *)   wire [31:0]                        M00_AXI_0_wdata;
(* mark_debug = "true" *)   wire                               M00_AXI_0_wready;
(* mark_debug = "true" *)   wire [3:0]                         M00_AXI_0_wstrb;
(* mark_debug = "true" *)   wire                               M00_AXI_0_wvalid;
   
   wire [31:0]                        m_axil_rdata_bram;
   
   reg                                axil_in_progress; // 1: AXIL in Progress
   reg                                wr_or_rd;         // Valid when axil_in_progress 1: Write 0: Read
   wire                               byp_or_mb;        // Valid when axil_in_progress 1: byp 0: mb
   
  
  // To BRAM
  assign S_AXI_0_araddr        = M00_AXI_0_araddr[11:0];
  assign S_AXI_0_arprot        = M00_AXI_0_arprot;
  assign M00_AXI_0_arready     = S_AXI_0_arready;
  assign S_AXI_0_arvalid       = M00_AXI_0_arvalid;
  
  assign S_AXI_0_awaddr        = M00_AXI_0_awaddr[11:0];
  assign S_AXI_0_awprot        = M00_AXI_0_awprot;
  assign M00_AXI_0_awready     = S_AXI_0_awready;
  assign S_AXI_0_awvalid       = M00_AXI_0_awvalid;
  
  assign S_AXI_0_bready        = M00_AXI_0_bready;
  assign M00_AXI_0_bresp       = S_AXI_0_bresp;
  assign M00_AXI_0_bvalid      = S_AXI_0_bvalid;
  
  assign M00_AXI_0_rdata       = S_AXI_0_rdata;
  assign S_AXI_0_rready        = M00_AXI_0_rready;
  assign M00_AXI_0_rresp       = S_AXI_0_rresp;
  assign M00_AXI_0_rvalid      = S_AXI_0_rvalid;
  
  assign S_AXI_0_wdata         = M00_AXI_0_wdata;
  assign M00_AXI_0_wready      = S_AXI_0_wready;
  assign S_AXI_0_wstrb         = M00_AXI_0_wstrb;
  assign S_AXI_0_wvalid        = M00_AXI_0_wvalid;


  // Core Top Level Wrapper
  // Bypass 0 = MM
  // Bypass 1 = Simple
  // Bypass 2 = Cache
  design_1 design_1_i
       (.CH0_DDR4_0_act_n(CH0_DDR4_0_act_n),
        .CH0_DDR4_0_adr(CH0_DDR4_0_adr),
        .CH0_DDR4_0_ba(CH0_DDR4_0_ba),
        .CH0_DDR4_0_bg(CH0_DDR4_0_bg),
        .CH0_DDR4_0_ck_c(CH0_DDR4_0_ck_c),
        .CH0_DDR4_0_ck_t(CH0_DDR4_0_ck_t),
        .CH0_DDR4_0_cke(CH0_DDR4_0_cke),
        .CH0_DDR4_0_cs_n(CH0_DDR4_0_cs_n),
        .CH0_DDR4_0_dm_n(CH0_DDR4_0_dm_n),
        .CH0_DDR4_0_dq(CH0_DDR4_0_dq),
        .CH0_DDR4_0_dqs_c(CH0_DDR4_0_dqs_c),
        .CH0_DDR4_0_dqs_t(CH0_DDR4_0_dqs_t),
        .CH0_DDR4_0_odt(CH0_DDR4_0_odt),
        .CH0_DDR4_0_reset_n(CH0_DDR4_0_reset_n),

//        .CLK_IN1_D_0_clk_n(CLK_IN1_D_0_clk_n),
//        .CLK_IN1_D_0_clk_p(CLK_IN1_D_0_clk_p),

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

        .PCIE0_GT_grx_n(GT_Serial_RX_0_rxn),
        .PCIE0_GT_grx_p(GT_Serial_RX_0_rxp),
        .PCIE0_GT_gtx_n(GT_Serial_TX_0_txn),
        .PCIE0_GT_gtx_p(GT_Serial_TX_0_txp),

        .SYS_CLK0_IN_0_clk_n(SYS_CLK0_IN_0_clk_n),
        .SYS_CLK0_IN_0_clk_p(SYS_CLK0_IN_0_clk_p),

        .S_AXI_0_araddr(S_AXI_0_araddr),
        .S_AXI_0_arprot(S_AXI_0_arprot),
        .S_AXI_0_arready(S_AXI_0_arready),
        .S_AXI_0_arvalid(S_AXI_0_arvalid),
        .S_AXI_0_awaddr(S_AXI_0_awaddr),
        .S_AXI_0_awprot(S_AXI_0_awprot),
        .S_AXI_0_awready(S_AXI_0_awready),
        .S_AXI_0_awvalid(S_AXI_0_awvalid),
        .S_AXI_0_bready(S_AXI_0_bready),
        .S_AXI_0_bresp(S_AXI_0_bresp),
        .S_AXI_0_bvalid(S_AXI_0_bvalid),
        .S_AXI_0_rdata(m_axil_rdata_bram),
        .S_AXI_0_rready(S_AXI_0_rready),
        .S_AXI_0_rresp(S_AXI_0_rresp),
        .S_AXI_0_rvalid(S_AXI_0_rvalid),
        .S_AXI_0_wdata(S_AXI_0_wdata),
        .S_AXI_0_wready(S_AXI_0_wready),
        .S_AXI_0_wstrb(S_AXI_0_wstrb),
        .S_AXI_0_wvalid(S_AXI_0_wvalid),

        .cpm_cor_irq_0(),
        .cpm_misc_irq_0(),
        .cpm_uncor_irq_0(),
/*
        .dbg_araddr                  ( s_axis_c2h_cmpt_tdata[31:0]          ),
        .dbg_aruser                  ( {s_axis_c2h_cmpt_tdata[44:32], s_axis_c2h_ctrl_len[15:0]} ),
        .dbg_arvalid                 ( s_axis_c2h_cmpt_tvalid         ),
        .dbg_arready                 ( s_axis_c2h_cmpt_tready         ),
        .dbg_rdata                   ( s_axis_c2h_tdata[31:0]           ),
        .dbg_rresp                   ( {s_axis_c2h_cmpt_tlast, s_axis_c2h_tlast}           ),
        .dbg_rvalid                  ( s_axis_c2h_tvalid          ),
        .dbg_rready                  ( s_axis_c2h_tready          ),
        .dbg_debug_fsm               ( {s_axis_c2h_tdata[255:242], s_axis_c2h_mty[5:0]}     ),
        .dbg_csr_addr                ( {s_axis_c2h_cmpt_size[1:0],s_axis_c2h_ctrl_qid[9:0]}  ),
        .dbg_tm_vld                  ( tm_dsc_sts_vld            ),
        .dbg_tm_qen                  ( tm_dsc_sts_qen            ),
        .dbg_tm_byp                  ( tm_dsc_sts_byp            ),
        .dbg_tm_dir                  ( tm_dsc_sts_dir            ),
        .dbg_tm_mm                   ( tm_dsc_sts_mm             ),
        .dbg_tm_error                ( tm_dsc_sts_error          ),
        .dbg_tm_qid                  ( tm_dsc_sts_qid            ),
        .dbg_tm_avl                  ( tm_dsc_sts_avl            ),
        .dbg_tm_qinv                 ( tm_dsc_sts_qinv           ),
        .dbg_tm_irq_arm              ( tm_dsc_sts_irq_arm        ),
        .dbg_tm_rdy                  ( tm_dsc_sts_rdy            ),
*/
        .dma0_axi_aresetn_0(axi_aresetn),

        .dma0_axis_c2h_status_0_drop	(axis_c2h_status_drop),
        .dma0_axis_c2h_status_0_qid	(axis_c2h_status_qid),
        .dma0_axis_c2h_status_0_valid	(axis_c2h_status_valid),

        .dma0_c2h_byp_in_mm_0_cidx	(c2h_byp_in_mm_cidx),
        .dma0_c2h_byp_in_mm_0_error	(c2h_byp_in_mm_error),
        .dma0_c2h_byp_in_mm_0_func	(c2h_byp_in_mm_func),
        .dma0_c2h_byp_in_mm_0_len	(c2h_byp_in_mm_len),
        .dma0_c2h_byp_in_mm_0_mrkr_req	(c2h_byp_in_mm_mrkr_req),
        .dma0_c2h_byp_in_mm_0_port_id	(c2h_byp_in_mm_port_id),
        .dma0_c2h_byp_in_mm_0_qid	(c2h_byp_in_mm_qid),
        .dma0_c2h_byp_in_mm_0_radr	(c2h_byp_in_mm_radr),
        .dma0_c2h_byp_in_mm_0_ready	(c2h_byp_in_mm_rdy),
        .dma0_c2h_byp_in_mm_0_sdi	(c2h_byp_in_mm_sdi),
        .dma0_c2h_byp_in_mm_0_valid	(c2h_byp_in_mm_vld),
        .dma0_c2h_byp_in_mm_0_wadr	(c2h_byp_in_mm_wadr),

        .dma0_c2h_byp_in_st_csh_0_addr		(c2h_byp_in_st_csh_addr),
        .dma0_c2h_byp_in_st_csh_0_error		(c2h_byp_in_st_csh_error),
        .dma0_c2h_byp_in_st_csh_0_func		(c2h_byp_in_st_csh_func),
        .dma0_c2h_byp_in_st_csh_0_port_id	(c2h_byp_in_st_csh_port_id),
        .dma0_c2h_byp_in_st_csh_0_qid		(c2h_byp_in_st_csh_qid),
        .dma0_c2h_byp_in_st_csh_0_ready		(c2h_byp_in_st_csh_rdy),
        .dma0_c2h_byp_in_st_csh_0_valid		(c2h_byp_in_st_csh_vld),

        .dma0_c2h_byp_in_st_sim_0_addr		(c2h_byp_in_st_sim_addr),
        .dma0_c2h_byp_in_st_sim_0_error		(c2h_byp_in_st_sim_error),
        .dma0_c2h_byp_in_st_sim_0_func		(c2h_byp_in_st_sim_func),
        .dma0_c2h_byp_in_st_sim_0_port_id	(c2h_byp_in_st_sim_port_id),
        .dma0_c2h_byp_in_st_sim_0_qid		(c2h_byp_in_st_sim_qid),
        .dma0_c2h_byp_in_st_sim_0_ready		(c2h_byp_in_st_sim_rdy),
        .dma0_c2h_byp_in_st_sim_0_valid		(c2h_byp_in_st_sim_vld),

        .dma0_c2h_byp_out_0_cidx	(c2h_byp_out_cidx),
        .dma0_c2h_byp_out_0_dsc		(c2h_byp_out_dsc),
        .dma0_c2h_byp_out_0_dsc_sz	(c2h_byp_out_dsc_sz),
        .dma0_c2h_byp_out_0_error	(c2h_byp_out_error),
        .dma0_c2h_byp_out_0_func	(c2h_byp_out_func),
        .dma0_c2h_byp_out_0_mrkr_rsp	(c2h_byp_out_mrkr_rsp),
        .dma0_c2h_byp_out_0_port_id	(c2h_byp_out_port_id),
        .dma0_c2h_byp_out_0_qid		(c2h_byp_out_qid),
        .dma0_c2h_byp_out_0_ready	(c2h_byp_out_rdy),
        .dma0_c2h_byp_out_0_st_mm	(c2h_byp_out_st_mm),
        .dma0_c2h_byp_out_0_valid	(c2h_byp_out_vld),

        .dma0_dsc_crdt_in_0_crdt	(dsc_crdt_in_crdt),
        .dma0_dsc_crdt_in_0_qid		(dsc_crdt_in_qid),
        .dma0_dsc_crdt_in_0_rdy		(),
        .dma0_dsc_crdt_in_0_sel		(dsc_crdt_in_dir),
        .dma0_dsc_crdt_in_0_valid	(dsc_crdt_in_vld),

        .dma0_h2c_byp_in_mm_0_cidx	(h2c_byp_in_mm_cidx),
        .dma0_h2c_byp_in_mm_0_error	(h2c_byp_in_mm_error),
        .dma0_h2c_byp_in_mm_0_func	(h2c_byp_in_mm_func),
        .dma0_h2c_byp_in_mm_0_len	(h2c_byp_in_mm_len),
        .dma0_h2c_byp_in_mm_0_mrkr_req	(h2c_byp_in_mm_mrkr_req),
        .dma0_h2c_byp_in_mm_0_port_id	(h2c_byp_in_mm_port_id),
        .dma0_h2c_byp_in_mm_0_qid	(h2c_byp_in_mm_qid),
        .dma0_h2c_byp_in_mm_0_radr	(h2c_byp_in_mm_radr),
        .dma0_h2c_byp_in_mm_0_ready	(h2c_byp_in_mm_rdy),
        .dma0_h2c_byp_in_mm_0_sdi	(h2c_byp_in_mm_sdi),
        .dma0_h2c_byp_in_mm_0_valid	(h2c_byp_in_mm_vld),
        .dma0_h2c_byp_in_mm_0_wadr	(h2c_byp_in_mm_wadr),

        .dma0_h2c_byp_in_st_0_addr	(h2c_byp_in_st_addr),
        .dma0_h2c_byp_in_st_0_cidx	(h2c_byp_in_st_cidx),
        .dma0_h2c_byp_in_st_0_eop	(h2c_byp_in_st_eop),
        .dma0_h2c_byp_in_st_0_error	(h2c_byp_in_st_error),
        .dma0_h2c_byp_in_st_0_func	(h2c_byp_in_st_func),
        .dma0_h2c_byp_in_st_0_len	(h2c_byp_in_st_len),
        .dma0_h2c_byp_in_st_0_mrkr_req(h2c_byp_in_st_mrkr_req),
        .dma0_h2c_byp_in_st_0_no_dma	(h2c_byp_in_st_no_dma),
        .dma0_h2c_byp_in_st_0_port_id(h2c_byp_in_st_port_id),
        .dma0_h2c_byp_in_st_0_qid	(h2c_byp_in_st_qid),
        .dma0_h2c_byp_in_st_0_ready	(h2c_byp_in_st_rdy),
        .dma0_h2c_byp_in_st_0_sdi	(h2c_byp_in_st_sdi),
        .dma0_h2c_byp_in_st_0_sop	(h2c_byp_in_st_sop),
        .dma0_h2c_byp_in_st_0_valid	(h2c_byp_in_st_vld),

        .dma0_h2c_byp_out_0_cidx	(h2c_byp_out_cidx),
        .dma0_h2c_byp_out_0_dsc		(h2c_byp_out_dsc),
        .dma0_h2c_byp_out_0_dsc_sz	(h2c_byp_out_dsc_sz),
        .dma0_h2c_byp_out_0_error	(h2c_byp_out_error),
        .dma0_h2c_byp_out_0_func	(h2c_byp_out_func),
        .dma0_h2c_byp_out_0_mrkr_rsp	(h2c_byp_out_mrkr_rsp),
        .dma0_h2c_byp_out_0_port_id	(h2c_byp_out_port_id),
        .dma0_h2c_byp_out_0_qid		(h2c_byp_out_qid),
        .dma0_h2c_byp_out_0_ready	(h2c_byp_out_rdy),
        .dma0_h2c_byp_out_0_st_mm	(h2c_byp_out_st_mm),
        .dma0_h2c_byp_out_0_valid	(h2c_byp_out_vld),

        .dma0_m_axis_h2c_0_err		(m_axis_h2c_tuser[15]),
        .dma0_m_axis_h2c_0_mdata	(m_axis_h2c_tuser[47:16]),
        .dma0_m_axis_h2c_0_mty		(m_axis_h2c_tuser[53:48]),
        .dma0_m_axis_h2c_0_par		(m_axis_h2c_dpar),
        .dma0_m_axis_h2c_0_port_id	(m_axis_h2c_tuser[14:12]),
        .dma0_m_axis_h2c_0_qid		(m_axis_h2c_tuser[10:0]),
        .dma0_m_axis_h2c_0_tdata	(m_axis_h2c_tdata),
        .dma0_m_axis_h2c_0_tlast	(m_axis_h2c_tlast),
        .dma0_m_axis_h2c_0_tready	(m_axis_h2c_tready),
        .dma0_m_axis_h2c_0_tvalid	(m_axis_h2c_tvalid),
        .dma0_m_axis_h2c_0_zero_byte	(m_axis_h2c_tuser[54]),

/*
        .dma0_mgmt_0_cpl_dat(mgmt_cpl_dat),
        .dma0_mgmt_0_cpl_rdy(mgmt_cpl_rdy),
        .dma0_mgmt_0_cpl_sts(mgmt_cpl_sts),
        .dma0_mgmt_0_cpl_vld(mgmt_cpl_vld),

        .dma0_mgmt_0_req_adr(mgmt_req_adr),
        .dma0_mgmt_0_req_cmd(mgmt_req_cmd),
        .dma0_mgmt_0_req_dat(mgmt_req_dat),
        .dma0_mgmt_0_req_fnc(mgmt_req_fnc),
        .dma0_mgmt_0_req_msc(mgmt_req_msc),
        .dma0_mgmt_0_req_rdy(mgmt_req_rdy),
        .dma0_mgmt_0_req_vld(mgmt_req_vld),
*/
	
        .dma0_s_axis_c2h_0_ctrl_dis_cmpt	(s_axis_c2h_ctrl_dis_cmpt),
        .dma0_s_axis_c2h_0_ctrl_imm_data	(s_axis_c2h_ctrl_imm_data),
        .dma0_s_axis_c2h_0_ctrl_len		(s_axis_c2h_ctrl_len),
        .dma0_s_axis_c2h_0_ctrl_marker		(s_axis_c2h_ctrl_marker),
        .dma0_s_axis_c2h_0_ctrl_port_id		('h0),
        .dma0_s_axis_c2h_0_ctrl_qid		(s_axis_c2h_ctrl_qid),
        .dma0_s_axis_c2h_0_ctrl_user_trig	(s_axis_c2h_ctrl_user_trig),

        .dma0_s_axis_c2h_0_dpar			(s_axis_c2h_dpar),
        .dma0_s_axis_c2h_0_mty			(s_axis_c2h_mty),
        .dma0_s_axis_c2h_0_tdata		(s_axis_c2h_tdata),
        .dma0_s_axis_c2h_0_tlast		(s_axis_c2h_tlast),
        .dma0_s_axis_c2h_0_tready		(s_axis_c2h_tready),
        .dma0_s_axis_c2h_0_tvalid		(s_axis_c2h_tvalid),

        .dma0_s_axis_c2h_cmpt_0_size	(s_axis_c2h_cmpt_size),
        .dma0_s_axis_c2h_cmpt_0_data		(s_axis_c2h_cmpt_tdata),
        .dma0_s_axis_c2h_cmpt_0_dpar		(s_axis_c2h_cmpt_dpar),
        .dma0_s_axis_c2h_cmpt_0_tlast		(s_axis_c2h_cmpt_tlast),
        .dma0_s_axis_c2h_cmpt_0_tready		(s_axis_c2h_cmpt_tready),
        .dma0_s_axis_c2h_cmpt_0_tvalid		(s_axis_c2h_cmpt_tvalid),

        .dma0_soft_resetn_0                   (soft_reset_n),

        .dma0_st_rx_msg_0_tdata		(st_rx_msg_data),
        .dma0_st_rx_msg_0_tlast		(st_rx_msg_last),
        .dma0_st_rx_msg_0_tready	(st_rx_msg_rdy),
        .dma0_st_rx_msg_0_tvalid	(st_rx_msg_valid),

        .dma0_tm_dsc_sts_0_avl		(tm_dsc_sts_avl),
        .dma0_tm_dsc_sts_0_byp		(tm_dsc_sts_byp),
        .dma0_tm_dsc_sts_0_dir		(tm_dsc_sts_dir),
        .dma0_tm_dsc_sts_0_error	(tm_dsc_sts_error),
        .dma0_tm_dsc_sts_0_irq_arm	(tm_dsc_sts_irq_arm),
        .dma0_tm_dsc_sts_0_mm		(tm_dsc_sts_mm),
        .dma0_tm_dsc_sts_0_port_id	        (),
        .dma0_tm_dsc_sts_0_qen		(tm_dsc_sts_qen),
        .dma0_tm_dsc_sts_0_qid		(tm_dsc_sts_qid),
        .dma0_tm_dsc_sts_0_qinv		(tm_dsc_sts_qinv),
        .dma0_tm_dsc_sts_0_rdy		(tm_dsc_sts_rdy),
        .dma0_tm_dsc_sts_0_valid	(tm_dsc_sts_vld),

        .usr_flr_0_clear		(usr_flr_clr),
        .usr_flr_0_done_fnc	        (usr_flr_done_fnc),
        .usr_flr_0_done_vld	        (usr_flr_done_vld),
        .usr_flr_0_fnc		        (usr_flr_fnc),
        .usr_flr_0_set		        (usr_flr_set),

        .usr_irq_0_ack		(usr_irq_out_ack),
        .usr_irq_0_fail		(usr_irq_out_fail),
        .usr_irq_0_fnc		(usr_irq_in_fnc),
        .usr_irq_0_valid	(usr_irq_in_vld),
        .usr_irq_0_vec		(usr_irq_in_vec),

        .gt_refclk0_0_clk_n(GT_REFCLK0_D_0_clk_n),
        .gt_refclk0_0_clk_p(GT_REFCLK0_D_0_clk_p),

        .pcie0_user_clk_0	(axi_aclk),
        .pcie0_user_lnk_up_0	(user_lnk_up)
        );


  //
  // Descriptor Credit in logic
  //
  reg start_c2h_d, start_c2h_d1;
  always @(posedge axi_aclk) begin
    if(!axi_aresetn) begin
      start_c2h_d <= 1'b0;
      start_c2h_d1 <= 1'b0;
    end
    else begin
      start_c2h_d <= control_reg_c2h[1];
      start_c2h_d1 <= start_c2h_d;
    end
   end
  assign dsc_crdt_in_vld   = (start_c2h_d & ~start_c2h_d1) & (c2h_dsc_bypass == 2'b10);
  assign dsc_crdt_in_dir   = start_c2h_d;
//  assign dsc_crdt_in_fence = 1'b0;  // fix me
  assign dsc_crdt_in_qid   = c2h_st_qid;
  assign dsc_crdt_in_crdt  = credit_needed;
   
  // XDMA taget application
  user_control 
  #(
     .C_DATA_WIDTH                ( C_DATA_WIDTH              ),
     .QID_MAX                     ( 2048                      ),
     .PF0_M_AXILITE_ADDR_MSK      ( 32'h00000FFF              ),
     .PF1_M_AXILITE_ADDR_MSK      ( 32'h00000FFF              ),
     .PF2_M_AXILITE_ADDR_MSK      ( 32'h00000FFF              ),
     .PF3_M_AXILITE_ADDR_MSK      ( 32'h00000FFF              ),
     .PF0_VF_M_AXILITE_ADDR_MSK   ( 32'h00000FFF              ),
     .PF1_VF_M_AXILITE_ADDR_MSK   ( 32'h00000FFF              ),
     .PF2_VF_M_AXILITE_ADDR_MSK   ( 32'h00000FFF              ),
     .PF3_VF_M_AXILITE_ADDR_MSK   ( 32'h00000FFF              ),
     .PF0_PCIEBAR2AXIBAR          ( 32'h0000000002000000      ),
     .PF1_PCIEBAR2AXIBAR          ( 32'h0000000002001000      ),
     .PF2_PCIEBAR2AXIBAR          ( 32'h0000000002002000      ),
     .PF3_PCIEBAR2AXIBAR          ( 32'h0000000002003000      ),
     .PF0_VF_PCIEBAR2AXIBAR       ( 32'h0000000002040000      ),
     .PF1_VF_PCIEBAR2AXIBAR       ( 32'h0000000002080000      ),
     .PF2_VF_PCIEBAR2AXIBAR       ( 32'h00000000020C0000      ),
     .PF3_VF_PCIEBAR2AXIBAR       ( 32'h0000000002100000      ),
     .TM_DSC_BITS                 ( TM_DSC_BITS               )
  )
  user_control_i
  (
     .axi_aclk                    ( axi_aclk                  ),
     .axi_aresetn                 ( axi_aresetn               ),
     .m_axil_wvalid               ( M00_AXI_0_wvalid      ),
     .m_axil_wready               ( M00_AXI_0_wready      ),
     .m_axil_rvalid               ( M00_AXI_0_rvalid      ),
     .m_axil_rready               ( M00_AXI_0_rready      ),
     .m_axil_awaddr               ( M00_AXI_0_awaddr[31:0] ),
     .m_axil_wdata                ( M00_AXI_0_wdata       ),
     .m_axil_rdata                ( S_AXI_0_rdata             ),
     .m_axil_rdata_bram           ( m_axil_rdata_bram         ),
     .m_axil_araddr               ( M00_AXI_0_araddr[31:0] ),
     .m_axil_arvalid              ( M00_AXI_0_arvalid     ),
     .soft_reset_n                ( soft_reset_n              ),
     .st_loopback                 ( st_loopback               ),
     .axi_mm_h2c_valid            ( m_axi_wvalid              ),
     .axi_mm_h2c_ready            ( m_axi_wready              ),
     .axi_mm_c2h_valid            ( m_axi_rvalid              ),
     .axi_mm_c2h_ready            ( m_axi_rready              ),
     .axi_st_h2c_valid            ( m_axis_h2c_tvalid         ),
     .axi_st_h2c_ready            ( m_axis_h2c_tready         ),
     .axi_st_c2h_valid            ( s_axis_c2h_tvalid         ),
     .axi_st_c2h_ready            ( s_axis_c2h_tready         ),
     .c2h_st_qid                  ( c2h_st_qid                ),
     .control_reg_c2h             ( control_reg_c2h           ),
     .c2h_num_pkt                 ( c2h_num_pkt               ),
     .clr_h2c_match               ( clr_h2c_match             ),
     .c2h_st_len                  ( c2h_st_len                ),
     .h2c_count                   ( h2c_count                 ),
     .h2c_match                   ( h2c_match                 ),
     .h2c_qid                     ( h2c_qid                   ),
     .h2c_zero_byte               ( m_axis_h2c_tuser[54]      ),
     .wb_dat                      ( wb_dat                    ),
     .credit_out                  ( credit_out                ),
     .credit_updt                 ( credit_updt               ),
     .credit_perpkt_in            ( credit_perpkt_in          ),
     .credit_needed               ( credit_needed             ),
     .buf_count                   ( buf_count                 ),
     .axis_c2h_drop               ( axis_c2h_status_drop      ),
     .axis_c2h_drop_valid         ( axis_c2h_status_valid     ),
     .cmpt_size                   ( cmpt_size                 ),
     .h2c_dsc_bypass              ( h2c_dsc_bypass            ),
     .c2h_dsc_bypass              ( c2h_dsc_bypass            ),
     .usr_irq_in_vld              ( usr_irq_in_vld            ),
     .usr_irq_in_vec              ( usr_irq_in_vec            ),
     .usr_irq_in_fnc              ( usr_irq_in_fnc            ),
     .usr_irq_out_ack             ( usr_irq_out_ack           ),
     .usr_irq_out_fail            ( usr_irq_out_fail          ),
     .st_rx_msg_rdy               ( st_rx_msg_rdy             ),
     .st_rx_msg_valid             ( st_rx_msg_valid           ),
     .st_rx_msg_last              ( st_rx_msg_last            ),
     .st_rx_msg_data              ( st_rx_msg_data            ),
     .c2h_mm_marker_req           ( c2h_mm_marker_req         ),
     .c2h_mm_marker_rsp           ( c2h_mm_marker_rsp         ),
     .h2c_mm_marker_req           ( h2c_mm_marker_req         ),
     .h2c_mm_marker_rsp           ( h2c_mm_marker_rsp         ),
     .h2c_st_marker_req           ( h2c_st_marker_req         ),
     .h2c_st_marker_rsp           ( h2c_st_marker_rsp         ),
     .c2h_st_marker_rsp           ( c2h_st_marker_rsp         ),
     .usr_flr_fnc                 ( usr_flr_fnc               ),
     .usr_flr_set                 ( usr_flr_set               ),
     .usr_flr_clr                 ( usr_flr_clr               ),
     .usr_flr_done_fnc            ( usr_flr_done_fnc          ),
     .usr_flr_done_vld            ( usr_flr_done_vld          ),
     .tm_dsc_sts_vld              ( tm_dsc_sts_vld            ),
     .tm_dsc_sts_qen              ( tm_dsc_sts_qen            ),
     .tm_dsc_sts_byp              ( tm_dsc_sts_byp            ),
     .tm_dsc_sts_dir              ( tm_dsc_sts_dir            ),
     .tm_dsc_sts_mm               ( tm_dsc_sts_mm             ),
     .tm_dsc_sts_error            ( tm_dsc_sts_error          ),
     .tm_dsc_sts_qid              ( tm_dsc_sts_qid            ),
     .tm_dsc_sts_avl              ( tm_dsc_sts_avl            ),
     .tm_dsc_sts_qinv             ( tm_dsc_sts_qinv           ),
     .tm_dsc_sts_irq_arm          ( tm_dsc_sts_irq_arm        ),
     .tm_dsc_sts_rdy              ( tm_dsc_sts_rdy            )
  );

   mdma_c2h_axis_data_exdes_t         s_axis_c2h_tdata_net;
   mdma_c2h_axis_ctrl_exdes_t         s_axis_c2h_ctrl_net;
   c2h_stub_std_cmp_t                 s_axis_c2h_cmpt_tdata_net;
   mdma_h2c_axis_tuser_exdes_t        m_axis_h2c_tuser_net;

   assign m_axis_h2c_tuser_net       = m_axis_h2c_tuser;

   assign m_axis_h2c_tready          = (st_loopback == 1'b1) ? m_axis_h2c_tready_lpbk : m_axis_h2c_tready_int;

   assign s_axis_c2h_cmpt_tdata      = (st_loopback == 1'b1) ?  s_axis_c2h_cmpt_tdata_net.cmp_ent : s_axis_c2h_cmpt_tdata_int;
   assign s_axis_c2h_cmpt_size       = (st_loopback == 1'b1) ?  s_axis_c2h_cmpt_tdata_net.cmp_type : s_axis_c2h_cmpt_size_int;
   assign s_axis_c2h_cmpt_dpar       = (st_loopback == 1'b1) ?  s_axis_c2h_cmpt_tdata_net.dpar : s_axis_c2h_cmpt_dpar_int;
   assign s_axis_c2h_cmpt_tvalid     = (st_loopback == 1'b1) ? s_axis_c2h_cmpt_tvalid_lpbk : s_axis_c2h_cmpt_tvalid_int;
   assign s_axis_c2h_cmpt_tlast      = (st_loopback == 1'b1) ? s_axis_c2h_cmpt_tlast_lpbk : s_axis_c2h_cmpt_tlast_int;
   assign s_axis_c2h_mty             = (st_loopback == 1'b1) ? s_axis_c2h_mty_lpbk : s_axis_c2h_mty_int;
   assign s_axis_c2h_tlast           = (st_loopback == 1'b1) ? s_axis_c2h_tlast_lpbk : s_axis_c2h_tlast_int;
   assign s_axis_c2h_tvalid          = (st_loopback == 1'b1) ? s_axis_c2h_tvalid_lpbk : s_axis_c2h_tvalid_int;
   assign s_axis_c2h_tdata           = (st_loopback == 1'b1) ? s_axis_c2h_tdata_net.tdata : s_axis_c2h_tdata_int;
   assign s_axis_c2h_dpar            = (st_loopback == 1'b1) ? s_axis_c2h_tdata_net.par : s_axis_c2h_dpar_int;
   assign s_axis_c2h_ctrl_marker     = (st_loopback == 1'b1) ? s_axis_c2h_ctrl_net.marker : s_axis_c2h_ctrl_marker_int;
   assign s_axis_c2h_ctrl_len        = (st_loopback == 1'b1) ? s_axis_c2h_ctrl_net.len : s_axis_c2h_ctrl_len_int;
   assign s_axis_c2h_ctrl_qid        = (st_loopback == 1'b1) ? s_axis_c2h_ctrl_net.qid : s_axis_c2h_ctrl_qid_int;
   assign s_axis_c2h_ctrl_user_trig  = (st_loopback == 1'b1) ? s_axis_c2h_ctrl_net.user_trig : s_axis_c2h_ctrl_user_trig_int;
   assign s_axis_c2h_ctrl_dis_cmpt   = (st_loopback == 1'b1) ? s_axis_c2h_ctrl_net.disable_wrb : s_axis_c2h_ctrl_dis_cmpt_int;
   assign s_axis_c2h_ctrl_imm_data   = (st_loopback == 1'b1) ? s_axis_c2h_ctrl_net.imm_data : s_axis_c2h_ctrl_imm_data_int;

  qdma_lpbk #(
     .MAX_DATA_WIDTH(C_DATA_WIDTH),
     .TDEST_BITS(16),
     .TCQ(TCQ)
  )
  qdma_st_lpbk_inst
  (
     // Clock and Reset
     .clk                         ( axi_aclk                  ),
     .rst_n                       ( axi_aresetn               ),

     //Input from QDMA
     .in_axis_tdata               ( m_axis_h2c_tdata          ),
     .in_axis_tuser               ( m_axis_h2c_tuser_net      ),
     .in_axis_tlast               ( m_axis_h2c_tlast          ),
     .in_axis_tvalid              ( m_axis_h2c_tvalid         ),
     .in_axis_tready              ( m_axis_h2c_tready_lpbk    ),

     //HDR output to QDMA
     .out_axis_cmp_data           ( s_axis_c2h_cmpt_tdata_net   ),
     .out_axis_cmp_tlast          ( s_axis_c2h_cmpt_tlast_lpbk  ),
     .out_axis_cmp_tvalid         ( s_axis_c2h_cmpt_tvalid_lpbk ),
     .out_axis_cmp_tready         ( s_axis_c2h_cmpt_tready      ),

     //PLD output to QDMA
     .out_axis_pld_data           ( s_axis_c2h_tdata_net      ),
     .out_axis_pld_ctrl           ( s_axis_c2h_ctrl_net       ),
     .out_axis_pld_mty            ( s_axis_c2h_mty_lpbk       ),
     .out_axis_pld_tlast          ( s_axis_c2h_tlast_lpbk     ),
     .out_axis_pld_tvalid         ( s_axis_c2h_tvalid_lpbk    ),
     .out_axis_pld_tready         ( s_axis_c2h_tready         )
  );

  axi_st_module 
  #(
     .C_DATA_WIDTH                ( C_DATA_WIDTH              ),
     .C_H2C_TUSER_WIDTH           ( C_H2C_TUSER_WIDTH         ),
     .TM_DSC_BITS                 ( TM_DSC_BITS               )
  )
  axi_st_module_i 
  (
     .axi_aresetn                 ( axi_aresetn               ),
     .axi_aclk                    ( axi_aclk                  ),
     .c2h_st_qid                  ( c2h_st_qid                ),
     .control_reg_c2h             ( control_reg_c2h           ), 
     .clr_h2c_match               ( clr_h2c_match             ),
     .c2h_st_len                  ( c2h_st_len                ),
     .c2h_num_pkt                 ( c2h_num_pkt               ),
     .h2c_count                   ( h2c_count                 ),
     .h2c_match                   ( h2c_match                 ),
     .h2c_qid                     ( h2c_qid                   ),
     .wb_dat                      ( wb_dat                    ),
     .cmpt_size                   ( cmpt_size                 ),
     .credit_in                   ( credit_out                ),
     .credit_updt                 ( credit_updt               ),
     .credit_perpkt_in            ( credit_perpkt_in          ),
     .credit_needed               ( credit_needed             ),
     .buf_count                   ( buf_count                 ),
     .m_axis_h2c_tvalid           ( m_axis_h2c_tvalid         ),
     .m_axis_h2c_tready           ( m_axis_h2c_tready_int     ),
     .m_axis_h2c_tdata            ( m_axis_h2c_tdata          ),
     .m_axis_h2c_tlast            ( m_axis_h2c_tlast          ),
     .m_axis_h2c_tuser            ( m_axis_h2c_tuser          ),
     .s_axis_c2h_tdata            ( s_axis_c2h_tdata_int      ),
     .s_axis_c2h_dpar             ( s_axis_c2h_dpar_int       ),
     .s_axis_c2h_ctrl_marker      ( s_axis_c2h_ctrl_marker_int ),
     .s_axis_c2h_ctrl_len         ( s_axis_c2h_ctrl_len_int   ),      // c2h_st_len,
     .s_axis_c2h_ctrl_qid         ( s_axis_c2h_ctrl_qid_int   ),      // st_qid,
     .s_axis_c2h_ctrl_user_trig   ( s_axis_c2h_ctrl_user_trig_int ),
     .s_axis_c2h_ctrl_dis_cmpt    ( s_axis_c2h_ctrl_dis_cmpt_int ),   // disable write back, write back not valid
     .s_axis_c2h_ctrl_imm_data    ( s_axis_c2h_ctrl_imm_data_int ),   // immediate data, 1 = data in transfer, 0 = no data in transfer
     .s_axis_c2h_tvalid           ( s_axis_c2h_tvalid_int     ),
     .s_axis_c2h_tready           ( s_axis_c2h_tready         ),
     .s_axis_c2h_tlast            ( s_axis_c2h_tlast_int      ),
     .s_axis_c2h_mty              ( s_axis_c2h_mty_int        ),      // no empthy bytes at EOP
     .s_axis_c2h_cmpt_tdata       ( s_axis_c2h_cmpt_tdata_int ),
     .s_axis_c2h_cmpt_size        ( s_axis_c2h_cmpt_size_int  ),
     .s_axis_c2h_cmpt_dpar        ( s_axis_c2h_cmpt_dpar_int  ),
     .s_axis_c2h_cmpt_tvalid      ( s_axis_c2h_cmpt_tvalid_int ),
     .s_axis_c2h_cmpt_tlast       ( s_axis_c2h_cmpt_tlast_int ),
     .s_axis_c2h_cmpt_tready      ( s_axis_c2h_cmpt_tready    )
  );

  dsc_byp_h2c dsc_byp_h2c_i
  (
     .h2c_dsc_bypass              ( h2c_dsc_bypass            ),
     .h2c_mm_marker_req           ( h2c_mm_marker_req         ),
     .h2c_st_marker_req           ( h2c_st_marker_req         ),
     .h2c_mm_marker_rsp           ( h2c_mm_marker_rsp         ),
     .h2c_st_marker_rsp           ( h2c_st_marker_rsp         ),
     .h2c_byp_out_dsc             ( h2c_byp_out_dsc           ),
     .h2c_byp_out_mrkr_rsp        ( h2c_byp_out_mrkr_rsp      ),
     .h2c_byp_out_st_mm           ( h2c_byp_out_st_mm         ),
     .h2c_byp_out_dsc_sz          ( h2c_byp_out_dsc_sz        ),
     .h2c_byp_out_qid             ( h2c_byp_out_qid           ),
     .h2c_byp_out_error           ( h2c_byp_out_error         ),
     .h2c_byp_out_func            ( h2c_byp_out_func          ),
     .h2c_byp_out_cidx            ( h2c_byp_out_cidx          ),
     .h2c_byp_out_port_id         ( h2c_byp_out_port_id       ),
     .h2c_byp_out_vld             ( h2c_byp_out_vld           ),
     .h2c_byp_out_rdy             ( h2c_byp_out_rdy           ),

     .h2c_byp_in_mm_radr          ( h2c_byp_in_mm_radr        ),
     .h2c_byp_in_mm_wadr          ( h2c_byp_in_mm_wadr        ),
     .h2c_byp_in_mm_len           ( h2c_byp_in_mm_len         ),
     .h2c_byp_in_mm_mrkr_req      ( h2c_byp_in_mm_mrkr_req    ),
     .h2c_byp_in_mm_sdi           ( h2c_byp_in_mm_sdi         ),
     .h2c_byp_in_mm_qid           ( h2c_byp_in_mm_qid         ),
     .h2c_byp_in_mm_error         ( h2c_byp_in_mm_error       ),
     .h2c_byp_in_mm_func          ( h2c_byp_in_mm_func        ),
     .h2c_byp_in_mm_cidx          ( h2c_byp_in_mm_cidx        ),
     .h2c_byp_in_mm_port_id       ( h2c_byp_in_mm_port_id     ),
     .h2c_byp_in_mm_no_dma        ( h2c_byp_in_mm_no_dma      ),
     .h2c_byp_in_mm_vld           ( h2c_byp_in_mm_vld         ),
     .h2c_byp_in_mm_rdy           ( h2c_byp_in_mm_rdy         ),

     .h2c_byp_in_st_addr          ( h2c_byp_in_st_addr        ),
     .h2c_byp_in_st_len           ( h2c_byp_in_st_len         ),
     .h2c_byp_in_st_eop           ( h2c_byp_in_st_eop         ),
     .h2c_byp_in_st_sop           ( h2c_byp_in_st_sop         ),
     .h2c_byp_in_st_mrkr_req      ( h2c_byp_in_st_mrkr_req    ),
     .h2c_byp_in_st_sdi           ( h2c_byp_in_st_sdi         ),
     .h2c_byp_in_st_qid           ( h2c_byp_in_st_qid         ),
     .h2c_byp_in_st_error         ( h2c_byp_in_st_error       ),
     .h2c_byp_in_st_func          ( h2c_byp_in_st_func        ),
     .h2c_byp_in_st_cidx          ( h2c_byp_in_st_cidx        ),
     .h2c_byp_in_st_port_id       ( h2c_byp_in_st_port_id     ),
     .h2c_byp_in_st_no_dma        ( h2c_byp_in_st_no_dma      ),
     .h2c_byp_in_st_vld           ( h2c_byp_in_st_vld         ),
     .h2c_byp_in_st_rdy           ( h2c_byp_in_st_rdy         )
  );

  dsc_byp_c2h dsc_byp_c2h_i
  (
     .c2h_dsc_bypass              ( c2h_dsc_bypass            ),
     .c2h_mm_marker_req           ( c2h_mm_marker_req         ),
     .c2h_mm_marker_rsp           ( c2h_mm_marker_rsp         ),
     .c2h_st_marker_rsp           ( c2h_st_marker_rsp         ),
     .c2h_byp_out_dsc             ( c2h_byp_out_dsc           ),
     .c2h_byp_out_mrkr_rsp        ( c2h_byp_out_mrkr_rsp      ),
     .c2h_byp_out_st_mm           ( c2h_byp_out_st_mm         ),
     .c2h_byp_out_dsc_sz          ( c2h_byp_out_dsc_sz        ),
     .c2h_byp_out_qid             ( c2h_byp_out_qid           ),
     .c2h_byp_out_error           ( c2h_byp_out_error         ),
     .c2h_byp_out_func            ( c2h_byp_out_func          ),
     .c2h_byp_out_cidx            ( c2h_byp_out_cidx          ),
     .c2h_byp_out_port_id         ( c2h_byp_out_port_id       ),
     .c2h_byp_out_vld             ( c2h_byp_out_vld           ),
     .c2h_byp_out_rdy             ( c2h_byp_out_rdy           ),

     .c2h_byp_in_mm_radr          ( c2h_byp_in_mm_radr        ),
     .c2h_byp_in_mm_wadr          ( c2h_byp_in_mm_wadr        ),
     .c2h_byp_in_mm_len           ( c2h_byp_in_mm_len         ),
     .c2h_byp_in_mm_mrkr_req      ( c2h_byp_in_mm_mrkr_req    ),
     .c2h_byp_in_mm_sdi           ( c2h_byp_in_mm_sdi         ),
     .c2h_byp_in_mm_qid           ( c2h_byp_in_mm_qid         ),
     .c2h_byp_in_mm_error         ( c2h_byp_in_mm_error       ),
     .c2h_byp_in_mm_func          ( c2h_byp_in_mm_func        ),
     .c2h_byp_in_mm_cidx          ( c2h_byp_in_mm_cidx        ),
     .c2h_byp_in_mm_port_id       ( c2h_byp_in_mm_port_id     ),
     .c2h_byp_in_mm_vld           ( c2h_byp_in_mm_vld         ),
     .c2h_byp_in_mm_no_dma        ( c2h_byp_in_mm_no_dma      ),
     .c2h_byp_in_mm_rdy           ( c2h_byp_in_mm_rdy         ),

     .c2h_byp_in_st_csh_addr      ( c2h_byp_in_st_csh_addr    ),
     .c2h_byp_in_st_csh_qid       ( c2h_byp_in_st_csh_qid     ),
     .c2h_byp_in_st_csh_error     ( c2h_byp_in_st_csh_error   ),
     .c2h_byp_in_st_csh_func      ( c2h_byp_in_st_csh_func    ),
     .c2h_byp_in_st_csh_port_id   ( c2h_byp_in_st_csh_port_id ),
     .c2h_byp_in_st_csh_vld       ( c2h_byp_in_st_csh_vld     ),
     .c2h_byp_in_st_csh_rdy       ( c2h_byp_in_st_csh_rdy     ),

     .c2h_byp_in_st_sim_addr      ( c2h_byp_in_st_sim_addr    ),
     .c2h_byp_in_st_sim_qid       ( c2h_byp_in_st_sim_qid     ),
     .c2h_byp_in_st_sim_error     ( c2h_byp_in_st_sim_error   ),
     .c2h_byp_in_st_sim_func      ( c2h_byp_in_st_sim_func    ),
     .c2h_byp_in_st_sim_port_id   ( c2h_byp_in_st_sim_port_id ),
     .c2h_byp_in_st_sim_vld       ( c2h_byp_in_st_sim_vld     ),
     .c2h_byp_in_st_sim_rdy       ( c2h_byp_in_st_sim_rdy     )
  );




endmodule
