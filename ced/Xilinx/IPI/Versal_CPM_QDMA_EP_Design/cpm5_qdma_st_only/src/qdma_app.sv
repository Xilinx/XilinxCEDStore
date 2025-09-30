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
module qdma_app #(
  parameter TCQ                         = 1,
  parameter C_M_AXI_ID_WIDTH            = 4,
  parameter PL_LINK_CAP_MAX_LINK_WIDTH  = 16,
  parameter C_DATA_WIDTH                = 512,
  parameter C_M_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_RQ_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 137 : 62),
  parameter C_S_AXIS_CQP_USER_WIDTH     = ((C_DATA_WIDTH == 512) ? 183 : 88),
  parameter C_M_AXIS_RC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 161 : 75),
  parameter C_S_AXIS_CC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ?  81 : 33),
  parameter C_S_KEEP_WIDTH              = C_S_AXI_DATA_WIDTH / 32,
  parameter C_M_KEEP_WIDTH              = (C_M_AXI_DATA_WIDTH / 32),
  parameter C_XDMA_NUM_CHNL             = 4,

  parameter BYTE_CREDIT                 = 2048,  // DESCRIPTOR size from application
  parameter MAX_DATA_WIDTH              = 512,
  parameter C_H2C_TUSER_WIDTH           = 55,
  parameter CRC_WIDTH                   = 32,
  parameter C_CNTR_WIDTH                = 64,
  parameter QID_MAX                     = 256,
  parameter TM_DSC_BITS                 = 16
)
(

  // AXI Lite Master Interface connections
  input 			     m_axil_wvalid,
  input 			     m_axil_wready,
  input [31:0] 			     m_axil_awaddr,
  input [31:0] 			     m_axil_wdata,
  output [31:0] 		     m_axil_rdata,
  input [31:0] 			     m_axil_rdata_bram,
  input [31:0] 			     m_axil_araddr,

  // AXI Memory Mapped interface
  input [C_M_AXI_ID_WIDTH-1:0] 	     s_axi_awid,
  input [64-1:0] 		     s_axi_awaddr,
  input [7:0] 			     s_axi_awlen,
  input [2:0] 			     s_axi_awsize,
  input [1:0] 			     s_axi_awburst,
  input 			     s_axi_awvalid,
  output 			     s_axi_awready,
  input [C_M_AXI_DATA_WIDTH-1:0]     s_axi_wdata,
  input [(C_M_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
  input 			     s_axi_wlast,
  input 			     s_axi_wvalid,
  output 			     s_axi_wready,
  output [C_M_AXI_ID_WIDTH-1:0]      s_axi_bid,
  output [1:0] 			     s_axi_bresp,
  output 			     s_axi_bvalid,
  input 			     s_axi_bready,
  input [C_M_AXI_ID_WIDTH-1:0] 	     s_axi_arid,
  input [64-1:0] 		     s_axi_araddr,
  input [7:0] 			     s_axi_arlen,
  input [2:0] 			     s_axi_arsize,
  input [1:0] 			     s_axi_arburst,
  input 			     s_axi_arvalid,
  output 			     s_axi_arready,
  output [C_M_AXI_ID_WIDTH-1:0]      s_axi_rid,
  output [C_M_AXI_DATA_WIDTH-1:0]    s_axi_rdata,
  output [1:0] 			     s_axi_rresp,
  output 			     s_axi_rlast,
  output 			     s_axi_rvalid,
  input 			     s_axi_rready,

  // System IO signals
  input 			     user_clk,
  input 			     user_resetn,
  output 			     gen_user_reset_n,

  input [255:0] 		     c2h_byp_out_dsc,
  input [3:0] 			     c2h_byp_out_fmt,
  input 			     c2h_byp_out_st_mm,
  input [1:0] 			     c2h_byp_out_dsc_sz,
  input [11:0] 			     c2h_byp_out_qid,
  input 			     c2h_byp_out_error,
  input [11:0] 			     c2h_byp_out_func,
  input                              c2h_byp_out_mm_chn,
  input [15:0] 			     c2h_byp_out_cidx,
  input [2:0] 			     c2h_byp_out_port_id,
  input [6:0] 			     c2h_byp_out_pfch_tag,
  input 			     c2h_byp_out_vld,
  output 			     c2h_byp_out_rdy,

  output [63:0] 		     c2h_byp_in_mm_radr,
  output [63:0] 		     c2h_byp_in_mm_wadr,
  output [15:0] 		     c2h_byp_in_mm_len,
  output 			     c2h_byp_in_mm_mrkr_req,
  output 			     c2h_byp_in_mm_sdi,
  output [11:0] 		     c2h_byp_in_mm_qid,
  output 			     c2h_byp_in_mm_error,
  output [11:0] 		     c2h_byp_in_mm_func,
  output [15:0] 		     c2h_byp_in_mm_cidx,
  output [2:0] 			     c2h_byp_in_mm_port_id,
  output [1:0] 			     c2h_byp_in_mm_at,
  output 			     c2h_byp_in_mm_no_dma,
  output 			     c2h_byp_in_mm_vld,
  input 			     c2h_byp_in_mm_rdy,

  output [63:0] 		     c2h_byp_in_st_csh_addr,
  output [11:0] 		     c2h_byp_in_st_csh_qid,
  output 			     c2h_byp_in_st_csh_error,
  output [11:0] 		     c2h_byp_in_st_csh_func,
  output [2:0] 			     c2h_byp_in_st_csh_port_id,
  output [6:0] 			     c2h_byp_in_st_csh_pfch_tag,
  output [1:0] 			     c2h_byp_in_st_csh_at,
  output 			     c2h_byp_in_st_csh_vld,
  input 			     c2h_byp_in_st_csh_rdy,

  // Descriptor Bypass Out for mdma
  input [255:0] 		     h2c_byp_out_dsc,
  input [3:0] 			     h2c_byp_out_fmt,
  input 			     h2c_byp_out_st_mm,
  input [1:0] 			     h2c_byp_out_dsc_sz,
  input [11:0] 			     h2c_byp_out_qid,
  input 			     h2c_byp_out_error,
  input [11:0] 			     h2c_byp_out_func,
  input  			     h2c_byp_out_mm_chn,
  input [15:0] 			     h2c_byp_out_cidx,
  input [2:0] 			     h2c_byp_out_port_id,
  input 			     h2c_byp_out_vld,
  output 			     h2c_byp_out_rdy,

  // Desciptor Bypass for mdma
  output [63:0] 		     h2c_byp_in_mm_radr,
  output [63:0] 		     h2c_byp_in_mm_wadr,
  output [15:0] 		     h2c_byp_in_mm_len,
  output 			     h2c_byp_in_mm_mrkr_req,
  output 			     h2c_byp_in_mm_sdi,
  output [11:0] 		     h2c_byp_in_mm_qid,
  output 			     h2c_byp_in_mm_error,
  output [11:0] 		     h2c_byp_in_mm_func,
  output [15:0] 		     h2c_byp_in_mm_cidx,
  output [2:0] 			     h2c_byp_in_mm_port_id,
  output [1:0] 			     h2c_byp_in_mm_at,
  output 			     h2c_byp_in_mm_no_dma,
  output 			     h2c_byp_in_mm_vld,
  input 			     h2c_byp_in_mm_rdy,

  // Desciptor Bypass for mdma
  output [63:0] 		     h2c_byp_in_st_addr,
  output [15:0] 		     h2c_byp_in_st_len,
  output 			     h2c_byp_in_st_eop,
  output 			     h2c_byp_in_st_sop,
  output 			     h2c_byp_in_st_mrkr_req,
  output 			     h2c_byp_in_st_sdi,
  output [11:0] 		     h2c_byp_in_st_qid,
  output 			     h2c_byp_in_st_error,
  output [11:0] 		     h2c_byp_in_st_func,
  output [15:0] 		     h2c_byp_in_st_cidx,
  output [2:0] 			     h2c_byp_in_st_port_id,
  output [1:0] 			     h2c_byp_in_st_at,
  output 			     h2c_byp_in_st_no_dma,
  output 			     h2c_byp_in_st_vld,
  input 			     h2c_byp_in_st_rdy,

  input 			     usr_irq_out_fail,
  input 			     usr_irq_out_ack,
  output [10:0] 		     usr_irq_in_vec,
  output [11:0] 		     usr_irq_in_fnc,
  output reg 			     usr_irq_in_vld,
  output 			     st_rx_msg_rdy,
  input 			     st_rx_msg_valid,
  input 			     st_rx_msg_last,
  input [31:0] 			     st_rx_msg_data,

  input 			     tm_dsc_sts_vld,
  input 			     tm_dsc_sts_byp,
  input 			     tm_dsc_sts_qen,
  input 			     tm_dsc_sts_dir,
  input 			     tm_dsc_sts_mm,
  input 			     tm_dsc_sts_error,
  input [11:0] 			     tm_dsc_sts_qid,
  input [15:0] 			     tm_dsc_sts_avl,
  input 			     tm_dsc_sts_qinv,
  input 			     tm_dsc_sts_irq_arm,
  output 			     tm_dsc_sts_rdy,

  input [7:0] 			     qsts_out_op ,
  input [63:0] 			     qsts_out_data ,
  input [2:0] 			     qsts_out_port_id ,
  input [12:0] 			     qsts_out_qid ,
  input 			     qsts_out_vld ,
  output reg 			     qsts_out_rdy = 1'b1,

  input 			     axis_c2h_status_drop,
  input 			     axis_c2h_status_valid,
  input [11:0] 			     axis_c2h_status_qid,
  input 			     axis_c2h_status_last,
  input 			     axis_c2h_status_cmp,
  input 			     axis_c2h_status_error,

  input 			     axis_c2h_dmawr_cmp,
  input [2:0] 			     axis_c2h_dmawr_port_id,

  input 			     rst_n,

// Input from QDMA
//   input  [MAX_DATA_WIDTH-1:0]         in_axis_tdata,
//   input  mdma_h2c_axis_tuser_exdes_t  in_axis_tuser,
//   input                               in_axis_tlast,
//   input                               in_axis_tvalid,
//   output logic                        in_axis_tready,
  input [11:0] 			     usr_flr_fnc,
  input 			     usr_flr_set,
  input 			     usr_flr_clr,
  output reg [11:0] 		     usr_flr_done_fnc,
  output 			     usr_flr_done_vld,
  output [3:0] 			     cfg_tph_requester_enable,
  output [251:0] 		     cfg_vf_tph_requester_enable,

  input [C_DATA_WIDTH-1 :0] 	     m_axis_h2c_tdata /* synthesis syn_keep = 1 */,
  input [CRC_WIDTH-1 :0] 	     m_axis_h2c_tcrc /* synthesis syn_keep = 1 */,
  input [11:0] 			     m_axis_h2c_tuser_qid /* synthesis syn_keep = 1 */,
  input [2:0] 			     m_axis_h2c_tuser_port_id,
  input 			     m_axis_h2c_tuser_err,
  input [31:0] 			     m_axis_h2c_tuser_mdata,
  input [5:0] 			     m_axis_h2c_tuser_mty,
  input 			     m_axis_h2c_tuser_zero_byte,
  input 			     m_axis_h2c_tvalid /* synthesis syn_keep = 1 */,
  output 			     m_axis_h2c_tready /* synthesis syn_keep = 1 */,
  input 			     m_axis_h2c_tlast /* synthesis syn_keep = 1 */,

  output [C_DATA_WIDTH-1 :0] 	     s_axis_c2h_tdata /* synthesis syn_keep = 1 */,
  output [CRC_WIDTH-1 :0] 	     s_axis_c2h_tcrc /* synthesis syn_keep = 1 */,
  output 			     s_axis_c2h_ctrl_marker /* synthesis syn_keep = 1 */,
  output [15:0] 		     s_axis_c2h_ctrl_len /* synthesis syn_keep = 1 */,
  output [2:0] 			     s_axis_c2h_ctrl_port_id /* synthesis syn_keep = 1 */,
  output [11:0] 		     s_axis_c2h_ctrl_qid /* synthesis syn_keep = 1 */,
  output [6:0] 			     s_axis_c2h_ctrl_ecc /* synthesis syn_keep = 1 */,
  output 			     s_axis_c2h_ctrl_has_cmpt /* synthesis syn_keep = 1 */,
  output 			     s_axis_c2h_tvalid /* synthesis syn_keep = 1 */,
  input 			     s_axis_c2h_tready /* synthesis syn_keep = 1 */,
  output 			     s_axis_c2h_tlast /* synthesis syn_keep = 1 */,
  output [5:0] 			     s_axis_c2h_mty /* synthesis syn_keep = 1 */ ,
  output [511:0] 		     s_axis_c2h_cmpt_tdata,
  output [1:0] 			     s_axis_c2h_cmpt_size,
  output [15:0] 		     s_axis_c2h_cmpt_dpar,
  output 			     s_axis_c2h_cmpt_tvalid,

  output [12:0] 		     s_axis_c2h_cmpt_ctrl_qid,
  output [1:0] 			     s_axis_c2h_cmpt_ctrl_cmpt_type,
  output [15:0] 		     s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
  output 			     s_axis_c2h_cmpt_ctrl_marker,
  output 			     s_axis_c2h_cmpt_ctrl_user_trig,
  output [2:0] 			     s_axis_c2h_cmpt_ctrl_col_idx,
  output [2:0] 			     s_axis_c2h_cmpt_ctrl_err_idx,
  input 			     s_axis_c2h_cmpt_tready,

  output 			     dsc_crdt_in_vld,
  input 			     dsc_crdt_in_rdy,
  output 			     dsc_crdt_in_dir,
  output 			     dsc_crdt_in_fence,
  output [11:0] 		     dsc_crdt_in_qid,
  output [15:0] 		     dsc_crdt_in_crdt,

  output [3:0] 			     leds

);

  // wire/reg declarations
   wire 			     sys_reset;
   wire [31:0] 			     s_axil_rdata_bram;
   
  // MDMA signals
   wire 			     m_axis_h2c_tready_lpbk;
   wire 			     m_axis_h2c_tready_int;

  // AXIS C2H packet wire

   wire [10:0] 			     s_axis_c2h_ctrl_qid_int ;
   wire [10:0] 			     s_axis_c2h_cmpt_ctrl_qid_int;

   wire [10:0] 			       c2h_num_pkt;
   wire [11:0] 			       c2h_st_qid;
   wire [15:0] 			       c2h_st_len;
   wire [31:0] 			       h2c_count;
   wire 			       h2c_match;
   wire 			       h2c_crc_match;
   wire 			       clr_h2c_match;
   wire [31:0] 			       control_reg_c2h;
   wire [31:0] 			       control_reg_c2h2;
   wire [11:0] 			       h2c_qid_det;
   wire [31:0] 			       cmpt_size;
   wire [255:0] 		       wb_dat;
   
   wire [TM_DSC_BITS-1:0] 	       credit_out;
   wire [TM_DSC_BITS-1:0] 	       credit_needed;
   wire [TM_DSC_BITS-1:0] 	       credit_perpkt_in;
   wire 			       credit_updt;
   wire [15:0] 			       buf_count;
   
   wire 			       st_loopback;
   wire [1:0] 			       c2h_dsc_bypass;
   wire 			       h2c_dsc_bypass;
   wire [3:0] 			       dsc_bypass;
   wire [6:0]                          pfch_byp_tag;
   wire [11:0]                         pfch_byp_tag_qid;
   wire [15:0]                         sdi_count_reg;
   
  // c2h qid output signals
   wire                              c2h_qid_rdy;
   wire                              c2h_qid_vld;
   wire [11:0]                       c2h_qid;
   wire [16-1:0]                     c2h_qid_desc_avail;
   wire                              c2h_desc_cnt_dec;
   wire [10:0]                       c2h_desc_cnt_dec_qid;
   wire                              c2h_requeue_vld;
   wire [10:0]                       c2h_requeue_qid;
   wire                              c2h_requeue_rdy;
   wire [16-1:0]                     dbg_userctrl_credits;
    
  // h2c qid output signals
   wire                              h2c_qid_rdy;
   wire                              h2c_qid_vld;
   wire [11:0]                       h2c_qid;
   wire [16-1:0]                     h2c_qid_desc_avail;
   wire                              h2c_desc_cnt_dec;
   wire [10:0]                       h2c_desc_cnt_dec_qid;
   wire                              h2c_requeue_vld;
   wire [10:0]                       h2c_requeue_qid;
   wire                              h2c_requeue_rdy;
   wire 			     s_axis_c2h_ctrl_dis_cmpt;
   wire [10:0] 			     dsc_crdt_in_qid_int;

   (* mark_debug = "true" *) logic [10:0] c2h_data_cnt_q0, c2h_data_cnt_q1, c2h_data_cnt_q2, c2h_data_cnt_q3;
   (* mark_debug = "true" *) logic [10:0] c2h_cmpt_cnt_q0, c2h_cmpt_cnt_q1, c2h_cmpt_cnt_q2, c2h_cmpt_cnt_q3;
   (* mark_debug = "true" *) logic [10:0] c2h_bypin_cnt_q0, c2h_bypin_cnt_q1, c2h_bypin_cnt_q2, c2h_bypin_cnt_q3;

   assign s_axis_c2h_ctrl_has_cmpt = ~s_axis_c2h_ctrl_dis_cmpt;
   assign s_axis_c2h_cmpt_ctrl_qid = 13'h0 | s_axis_c2h_cmpt_ctrl_qid_int;
   assign s_axis_c2h_ctrl_qid      = 12'h0 | s_axis_c2h_ctrl_qid_int;
   assign dsc_crdt_in_qid          = 12'h0 | dsc_crdt_in_qid_int;
   
   
   user_control #(
    .C_DATA_WIDTH                   ( C_DATA_WIDTH      ),
    .QID_MAX                        ( QID_MAX           ),
    .TM_DSC_BITS                    ( TM_DSC_BITS       ),
    .C_CNTR_WIDTH                   ( C_CNTR_WIDTH      )
   ) user_control_i (
    .user_clk                       ( user_clk          ),
    .user_reset_n                   ( user_resetn       ),
    .m_axil_wvalid                  ( m_axil_wvalid     ),
    .m_axil_wready                  ( m_axil_wready     ),
    .m_axil_awaddr                  ( m_axil_awaddr     ),
    .m_axil_wdata                   ( m_axil_wdata      ),
    .m_axil_rdata                   ( m_axil_rdata      ),
    .m_axil_rdata_bram             ( m_axil_rdata_bram ),
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
    .h2c_qid                        ( h2c_qid_det         ),
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
    .dsc_bypass                      ( dsc_bypass         ),
    .pfch_byp_tag                    ( pfch_byp_tag        ),
    .pfch_byp_tag_qid               ( pfch_byp_tag_qid    ),
    .sdi_count_reg                  ( sdi_count_reg       ),
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
    .qid_rdy                        ( c2h_qid_rdy            ),
    .qid_vld                        ( c2h_qid_vld            ),
    .qid                             ( c2h_qid                ),
    .qid_desc_avail                 ( c2h_qid_desc_avail     ),
    .desc_cnt_dec                   ( c2h_desc_cnt_dec       ),
    .desc_cnt_dec_qid               ( c2h_desc_cnt_dec_qid   ),
    .requeue_vld                    ( c2h_requeue_vld        ),
    .requeue_qid                    ( c2h_requeue_qid        ),
    .requeue_rdy                    ( c2h_requeue_rdy        ),
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

    .c2h_data_cnt_q0                ( c2h_data_cnt_q0 ),
    .c2h_data_cnt_q1                ( c2h_data_cnt_q1 ),
    .c2h_data_cnt_q2                ( c2h_data_cnt_q2 ),
    .c2h_data_cnt_q3                ( c2h_data_cnt_q3 ),
    .c2h_cmpt_cnt_q0                ( c2h_cmpt_cnt_q0 ),
    .c2h_cmpt_cnt_q1                ( c2h_cmpt_cnt_q1 ),
    .c2h_cmpt_cnt_q2                ( c2h_cmpt_cnt_q2 ),
    .c2h_cmpt_cnt_q3                ( c2h_cmpt_cnt_q3 ),
    .c2h_bypin_cnt_q0               ( c2h_bypin_cnt_q0 ),
    .c2h_bypin_cnt_q1               ( c2h_bypin_cnt_q1 ),
    .c2h_bypin_cnt_q2               ( c2h_bypin_cnt_q2 ),
    .c2h_bypin_cnt_q3               ( c2h_bypin_cnt_q3 ),
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
    .C_DATA_WIDTH                   ( C_DATA_WIDTH       ),
    .QID_MAX                        ( QID_MAX            ),
    .TM_DSC_BITS                    ( TM_DSC_BITS        ),
    .CRC_WIDTH                      ( CRC_WIDTH          ),
    .BYTE_CREDIT                    ( BYTE_CREDIT        ),
    .C_CNTR_WIDTH                   ( C_CNTR_WIDTH       )
  ) axi_st_module_i (
    .user_reset_n                   ( user_resetn & gen_user_reset_n ),
    .user_clk                       ( user_clk           ),
//    .c2h_st_qid                     ( c2h_st_qid         ), // Internally generated now
    .control_reg_c2h                ( control_reg_c2h    ),
    .control_reg_c2h2               ( control_reg_c2h2   ),
    .fence_bit                       ( |dsc_bypass[2:0]   ), // Set fence bit in Bypass mode
    //  Simple bypass QID
    .sim_byp_qid                    ( pfch_byp_tag_qid   ),
    .sim_pyp_en                     ( dsc_bypass[2]      ),
    .clr_h2c_match                  ( clr_h2c_match      ),
//    .c2h_st_len                     ( c2h_st_len         ), // Internally generated now
    .c2h_num_pkt                    ( c2h_num_pkt        ),
    .h2c_count                      ( h2c_count          ),
    .h2c_match                      ( h2c_match          ),
    .h2c_qid_det                    ( h2c_qid_det        ),
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
    .s_axis_c2h_ctrl_qid            ( s_axis_c2h_ctrl_qid_int     ),   // st_qid,
    .s_axis_c2h_ctrl_user_trig      ( s_axis_c2h_ctrl_user_trig   ),
    .s_axis_c2h_ctrl_dis_cmpt       ( s_axis_c2h_ctrl_dis_cmpt    ),   // disable write back, write back not valid
    .s_axis_c2h_ctrl_imm_data       ( s_axis_c2h_ctrl_imm_data    ),   // immediate data, 1 = data in transfer, 0 = no data in transfer
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
    .s_axis_c2h_cmpt_ctrl_qid             ( s_axis_c2h_cmpt_ctrl_qid_int             ),
    .s_axis_c2h_cmpt_ctrl_cmpt_type       ( s_axis_c2h_cmpt_ctrl_cmpt_type       ),
    .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ( s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
    .s_axis_c2h_cmpt_ctrl_port_id         ( s_axis_c2h_cmpt_ctrl_port_id         ),
    .s_axis_c2h_cmpt_ctrl_marker          ( s_axis_c2h_cmpt_ctrl_marker          ),
    .s_axis_c2h_cmpt_ctrl_user_trig       ( s_axis_c2h_cmpt_ctrl_user_trig       ),
    .s_axis_c2h_cmpt_ctrl_col_idx         ( s_axis_c2h_cmpt_ctrl_col_idx         ),
    .s_axis_c2h_cmpt_ctrl_err_idx         ( s_axis_c2h_cmpt_ctrl_err_idx         ),

    .dsc_crdt_in_crdt                      ( dsc_crdt_in_crdt  ),
    .dsc_crdt_in_dir                       ( dsc_crdt_in_dir   ),
    .dsc_crdt_in_fence                     ( dsc_crdt_in_fence ),
    .dsc_crdt_in_qid                       ( dsc_crdt_in_qid_int   ),
    .dsc_crdt_in_rdy                       ( dsc_crdt_in_rdy   ),
    .dsc_crdt_in_valid                     ( dsc_crdt_in_vld   ),
		     
    .stat_vld                       ( stat_vld           ),
    .stat_err                       ( stat_err           ),
    // qid input signals for C2H
    .c2h_qid_rdy                    ( c2h_qid_rdy          ),
    .c2h_qid_vld                    ( c2h_qid_vld          ),
    .c2h_qid                         ( c2h_qid               ),
    .c2h_qid_desc_avail             ( c2h_qid_desc_avail    ),
    .c2h_desc_cnt_dec               ( c2h_desc_cnt_dec      ),
    .c2h_desc_cnt_dec_qid           ( c2h_desc_cnt_dec_qid  ),
    .c2h_requeue_vld                ( c2h_requeue_vld       ),
    .c2h_requeue_qid                ( c2h_requeue_qid       ),
    .c2h_requeue_rdy                ( c2h_requeue_rdy       ),
    .dbg_userctrl_credits           ( dbg_userctrl_credits ),
    
    // qid input signals for H2C
    .h2c_qid_rdy                    (           ),
    .h2c_qid_vld                    ( 'h0       ),
    .h2c_qid                         ( 'h0       ),
    .h2c_qid_desc_avail             ( 'h0      ),
    .h2c_desc_cnt_dec               (       ),
    .h2c_desc_cnt_dec_qid           (   ),
    .h2c_requeue_vld                (        ),
    .h2c_requeue_qid                (        ),
    .h2c_requeue_rdy                (  'h0      ),

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

  // C2H Control ECC genearation
   wire [56:0] 	ecc_gen_datain;
   wire [56:0] 	ecc_data_out;
   wire [6:0] 	ecc_gen_chkout_int;

   assign s_axis_c2h_ctrl_port_id = 3'h0;

   assign s_axis_c2h_ctrl_ecc = ecc_gen_chkout_int;

   assign ecc_gen_datain = { 17'h0,                             // reserved
			     1'b0,                              // var_desc
			     1'b0,                              // drop_req
			     1'b0,                              // num_buf_ov
			     4'b0,                              // host_id
			     s_axis_c2h_ctrl_has_cmpt,      //
			     s_axis_c2h_ctrl_marker,        // marker
			     s_axis_c2h_ctrl_port_id,       // port_id
			     s_axis_c2h_ctrl_qid,           // Qid is 12 bits
			     s_axis_c2h_ctrl_len};


  qdma_ecc_enc #(
    //.C_FAMILY("virtexuplus"),
    //.C_COMPONENT_NAME("ecc_0"),
    //.C_ECC_MODE(0),
    //.C_ECC_TYPE(0),
    .C_DATA_WIDTH(57),
    .C_CHK_BIT_WIDTH(7),
    .C_REG_INPUT(0),
    .C_REG_OUTPUT(0),
    .C_PIPELINE(0),
    .C_USE_CLKEN(0)
  ) c2h_ctrl_ecc_enc_int (
    .ecc_clk(1'b0),
    .ecc_reset(1'b0),
    .ecc_enc_clk_en_in(1'b1),
    .ecc_enc_data_in(ecc_gen_datain),           // input data
    .ecc_enc_data_out(ecc_data_out),            // output data
    .ecc_enc_chk_bits_out(ecc_gen_chkout_int)    // output check bits
    );


   // C2H data and CMPT counter for debug.
   //
   
   always @(posedge user_clk) begin
      if (~user_resetn & gen_user_reset_n) begin
	 c2h_data_cnt_q0 <= 0;
	 c2h_data_cnt_q1 <= 0;
	 c2h_data_cnt_q2 <= 0;
	 c2h_data_cnt_q3 <= 0;
      end
      else
	 if (s_axis_c2h_tvalid & s_axis_c2h_tready & s_axis_c2h_tlast) begin
	   case (s_axis_c2h_ctrl_qid)
	     12'h0 : c2h_data_cnt_q0 <= c2h_data_cnt_q0 + 1;
	     12'h1 : c2h_data_cnt_q1 <= c2h_data_cnt_q1 + 1;
	     12'h2 : c2h_data_cnt_q2 <= c2h_data_cnt_q2 + 1;
	     12'h3 : c2h_data_cnt_q3 <= c2h_data_cnt_q3 + 1;
	   endcase // case s_axis_c2h_ctrl_qid[2
	 end
   end // always @ (posedge usr_clk)

   always @(posedge user_clk) begin
      if (~user_resetn & gen_user_reset_n) begin
	 c2h_cmpt_cnt_q0 <= 0;
	 c2h_cmpt_cnt_q1 <= 0;
	 c2h_cmpt_cnt_q2 <= 0;
	 c2h_cmpt_cnt_q3 <= 0;
      end
      else
	 if (s_axis_c2h_cmpt_tvalid & s_axis_c2h_cmpt_tready) begin
	   case (s_axis_c2h_cmpt_ctrl_qid)
	     12'h0 : c2h_cmpt_cnt_q0 <= c2h_cmpt_cnt_q0 + 1;
	     12'h1 : c2h_cmpt_cnt_q1 <= c2h_cmpt_cnt_q1 + 1;
	     12'h2 : c2h_cmpt_cnt_q2 <= c2h_cmpt_cnt_q2 + 1;
	     12'h3 : c2h_cmpt_cnt_q3 <= c2h_cmpt_cnt_q3 + 1;
	   endcase // case s_axis_c2h_cmpt_ctrl_qid[2
	 end
   end // always @ (posedge usr_clk)

   always @(posedge user_clk) begin
      if (~user_resetn & gen_user_reset_n) begin
	 c2h_bypin_cnt_q0 <= 0;
	 c2h_bypin_cnt_q1 <= 0;
	 c2h_bypin_cnt_q2 <= 0;
	 c2h_bypin_cnt_q3 <= 0;
      end
      else
	 if (c2h_byp_in_st_csh_vld & c2h_byp_in_st_csh_rdy) begin
	   case (c2h_byp_in_st_csh_qid)
	     12'h0 : c2h_bypin_cnt_q0 <= c2h_bypin_cnt_q0 + 1;
	     12'h1 : c2h_bypin_cnt_q1 <= c2h_bypin_cnt_q1 + 1;
	     12'h2 : c2h_bypin_cnt_q2 <= c2h_bypin_cnt_q2 + 1;
	     12'h3 : c2h_bypin_cnt_q3 <= c2h_bypin_cnt_q3 + 1;
	   endcase // case (c2h_byp_in_st_csh_qid)
	 end
   end // always @ (posedge user_clk)
   
  dsc_byp_h2c dsc_byp_h2c_i
    (
     .clk                     (user_clk),
     .resetn                  (user_resetn & gen_user_reset_n),
    .h2c_dsc_bypass          (1'b1),                 //turn on bypass
    .sdi_count_reg           ( sdi_count_reg),
    .h2c_mm_marker_req       (1'b0),
    .h2c_st_marker_req       (1'b0),
    .h2c_byp_out_dsc         (h2c_byp_out_dsc),
    .h2c_byp_out_fmt         (h2c_byp_out_fmt[2:0]),
    .h2c_byp_out_st_mm       (h2c_byp_out_st_mm),
    .h2c_byp_out_dsc_sz      (h2c_byp_out_dsc_sz),
    .h2c_byp_out_qid         (h2c_byp_out_qid),
    .h2c_byp_out_error       (h2c_byp_out_error),
    .h2c_byp_out_func        (h2c_byp_out_func),
    .h2c_byp_out_mm_chn      (h2c_byp_out_mm_chn),
    .h2c_byp_out_cidx        (h2c_byp_out_cidx),
    .h2c_byp_out_port_id     (h2c_byp_out_port_id),
    .h2c_byp_out_vld         (h2c_byp_out_vld),
    .h2c_byp_out_rdy         (h2c_byp_out_rdy),

    .h2c_byp_in_mm_radr      (h2c_byp_in_mm_radr),
    .h2c_byp_in_mm_wadr      (h2c_byp_in_mm_wadr),
    .h2c_byp_in_mm_len       (h2c_byp_in_mm_len),
    .h2c_byp_in_mm_mrkr_req  (h2c_byp_in_mm_mrkr_req),
    .h2c_byp_in_mm_sdi       (h2c_byp_in_mm_sdi),
    .h2c_byp_in_mm_qid       (h2c_byp_in_mm_qid),
    .h2c_byp_in_mm_error     (h2c_byp_in_mm_error),
    .h2c_byp_in_mm_func      (h2c_byp_in_mm_func),
    .h2c_byp_in_mm_cidx      (h2c_byp_in_mm_cidx),
    .h2c_byp_in_mm_port_id   (h2c_byp_in_mm_port_id),
    .h2c_byp_in_mm_no_dma    (h2c_byp_in_mm_no_dma),
    .h2c_byp_in_mm_vld       (h2c_byp_in_mm_vld),
    .h2c_byp_in_mm_rdy       (h2c_byp_in_mm_rdy),

    .h2c_byp_in_st_addr      (h2c_byp_in_st_addr),
    .h2c_byp_in_st_len       (h2c_byp_in_st_len),
    .h2c_byp_in_st_eop       (h2c_byp_in_st_eop),
    .h2c_byp_in_st_sop       (h2c_byp_in_st_sop),
    .h2c_byp_in_st_mrkr_req  (h2c_byp_in_st_mrkr_req),
    .h2c_byp_in_st_sdi       (h2c_byp_in_st_sdi),
    .h2c_byp_in_st_qid       (h2c_byp_in_st_qid),
    .h2c_byp_in_st_error     (h2c_byp_in_st_error),
    .h2c_byp_in_st_func      (h2c_byp_in_st_func),
    .h2c_byp_in_st_cidx      (h2c_byp_in_st_cidx),
    .h2c_byp_in_st_port_id   (h2c_byp_in_st_port_id),
    .h2c_byp_in_st_no_dma    (h2c_byp_in_st_no_dma),
    .h2c_byp_in_st_vld       (h2c_byp_in_st_vld),
    .h2c_byp_in_st_rdy       (h2c_byp_in_st_rdy)
  );

  dsc_byp_c2h dsc_byp_c2h_i
  (
     .clk                     (user_clk),
     .resetn                  (user_resetn & gen_user_reset_n),
    .c2h_dsc_bypass          ({dsc_bypass[2],1'b1}), ////turn on bypass, 2 bit simple bypass
    .c2h_mm_marker_req       (1'b0),
    .c2h_byp_out_dsc         (c2h_byp_out_dsc),
    .c2h_byp_out_fmt         (c2h_byp_out_fmt[2:0]),
    .c2h_byp_out_st_mm       (c2h_byp_out_st_mm),
    .c2h_byp_out_dsc_sz      (c2h_byp_out_dsc_sz),
    .c2h_byp_out_qid         (c2h_byp_out_qid),
    .c2h_byp_out_error       (c2h_byp_out_error),
    .c2h_byp_out_func        (c2h_byp_out_func),
    .c2h_byp_out_mm_chn      (c2h_byp_out_mm_chn),
    .c2h_byp_out_cidx        (c2h_byp_out_cidx),
    .c2h_byp_out_port_id     (c2h_byp_out_port_id),
    .c2h_byp_out_pfch_tag    (c2h_byp_out_pfch_tag),
    .c2h_byp_out_vld         (c2h_byp_out_vld),
    .c2h_byp_out_rdy         (c2h_byp_out_rdy),

    .c2h_byp_in_mm_radr      (c2h_byp_in_mm_radr),
    .c2h_byp_in_mm_wadr      (c2h_byp_in_mm_wadr),
    .c2h_byp_in_mm_len       (c2h_byp_in_mm_len),
    .c2h_byp_in_mm_mrkr_req  (c2h_byp_in_mm_mrkr_req),
    .c2h_byp_in_mm_sdi       (c2h_byp_in_mm_sdi),
    .c2h_byp_in_mm_qid       (c2h_byp_in_mm_qid),
    .c2h_byp_in_mm_error     (c2h_byp_in_mm_error),
    .c2h_byp_in_mm_func      (c2h_byp_in_mm_func),
    .c2h_byp_in_mm_cidx      (c2h_byp_in_mm_cidx),
    .c2h_byp_in_mm_port_id   (c2h_byp_in_mm_port_id),
    .c2h_byp_in_mm_no_dma    (c2h_byp_in_mm_no_dma),
    .c2h_byp_in_mm_vld       (c2h_byp_in_mm_vld),
    .c2h_byp_in_mm_rdy       (c2h_byp_in_mm_rdy),

    .c2h_byp_in_st_csh_addr      (c2h_byp_in_st_csh_addr),
    .c2h_byp_in_st_csh_qid       (c2h_byp_in_st_csh_qid),
    .c2h_byp_in_st_csh_error     (c2h_byp_in_st_csh_error),
    .c2h_byp_in_st_csh_func      (c2h_byp_in_st_csh_func),
    .c2h_byp_in_st_csh_port_id   (c2h_byp_in_st_csh_port_id),
    .c2h_byp_in_st_csh_pfch_tag  (c2h_byp_in_st_csh_pfch_tag),
    .c2h_byp_in_st_csh_vld       (c2h_byp_in_st_csh_vld),
    .c2h_byp_in_st_csh_rdy       (c2h_byp_in_st_csh_rdy),
    .pfch_byp_tag                (pfch_byp_tag)

  );


endmodule
