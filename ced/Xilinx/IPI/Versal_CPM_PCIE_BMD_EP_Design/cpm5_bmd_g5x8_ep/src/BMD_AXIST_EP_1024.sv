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
// Project    : UltraScale+ FPGA PCI Express v4.0 Integrated Block
// File       : BMD_AXIST_EP_1024.sv
// Version    : 1.3 
//-----------------------------------------------------------------------------

//`include "pcie_app_uscale_bmd.vh"
`include "pcie_app_uscale_bmd_1024.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_EP_1024 #(
   parameter         TCQ                              = 1,
   parameter         C_DATA_WIDTH                     = 1024,                              // RX/TX interface data width
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE    = 2'b00,
   parameter         AXISTEN_IF_CMP_ALIGNMENT_MODE    = 2'b00,
   parameter         AXISTEN_IF_ENABLE_CLIENT_TAG     = 0,
   parameter         COMPLETER_10B_TAG                = "TRUE",
   parameter         RQ_AVAIL_TAG_IDX                 = 8,
   parameter         RQ_AVAIL_TAG                     = 256,
   parameter         AXISTEN_IF_REQ_PARITY_CHECK      = 0,
   parameter         AXISTEN_IF_CMP_PARITY_CHECK      = 0,
   parameter         AXISTEN_IF_RQ_STRADDLE           = 0,
   parameter         AXISTEN_IF_RC_STRADDLE           = 0,
   parameter         AXISTEN_IF_CQ_STRADDLE           = 0,
   parameter         AXISTEN_IF_CC_STRADDLE           = 0,
   parameter         AXISTEN_IF_ENABLE_RX_MSG_INTFC   = 0,
   parameter [17:0]  AXISTEN_IF_ENABLE_MSG_ROUTE      = 18'h2FFFF,
   parameter         AXI4_CQ_TUSER_WIDTH              = 465,
   parameter         AXI4_CC_TUSER_WIDTH              = 165,
   parameter         AXI4_RQ_TUSER_WIDTH              = 373,
   parameter         AXI4_RC_TUSER_WIDTH              = 337,
   parameter         KEEP_WIDTH                       = C_DATA_WIDTH / 32
)(
   input                            user_clk,
   input                            reset_n,
          
//--------------------------------------------------------------------//
//  AXI Interface                                                     //
//--------------------------------------------------------------------//
   output logic                           s_axis_rq_tlast,
   output logic [C_DATA_WIDTH-1:0]        s_axis_rq_tdata,
   output logic [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser,
   output logic [KEEP_WIDTH-1:0]          s_axis_rq_tkeep,
   input                                  s_axis_rq_tready,
   output logic                           s_axis_rq_tvalid,

   input       [C_DATA_WIDTH-1:0]         m_axis_rc_tdata,
   input       [AXI4_RC_TUSER_WIDTH-1:0]  m_axis_rc_tuser,
   input       [KEEP_WIDTH-1:0]           m_axis_rc_tkeep,
   input                                  m_axis_rc_tlast,
   output logic                           m_axis_rc_tready,
   input                                  m_axis_rc_tvalid,

   input       [C_DATA_WIDTH-1:0]         m_axis_cq_tdata,
   input       [AXI4_CQ_TUSER_WIDTH-1:0]  m_axis_cq_tuser,
   input       [KEEP_WIDTH-1:0]           m_axis_cq_tkeep,
   input                                  m_axis_cq_tlast,
   output logic                           m_axis_cq_tready,
   input                                  m_axis_cq_tvalid,

   output logic                           s_axis_cc_tlast,
   output logic [C_DATA_WIDTH-1:0]        s_axis_cc_tdata,
   output logic [AXI4_CC_TUSER_WIDTH-1:0] s_axis_cc_tuser,
   output logic [KEEP_WIDTH-1:0]          s_axis_cc_tkeep,
   input                                  s_axis_cc_tready,
   output logic                           s_axis_cc_tvalid,

   // TX Message Interface
   input                            cfg_msg_transmit_done,
   output logic                     cfg_msg_transmit,
   output logic [2:0]               cfg_msg_transmit_type,
   output logic [31:0]              cfg_msg_transmit_data,
          
   //Tag availability and Flow control Information
   input       [5:0]                pcie_rq_tag,
   input                            pcie_rq_tag_vld,
   input       [1:0]                pcie_tfc_nph_av,
   input       [1:0]                pcie_tfc_npd_av,
   input                            pcie_tfc_np_pl_empty,
   input       [5:0]                pcie_rq_seq_num0,
   input                            pcie_rq_seq_num_vld0,
   input       [5:0]                pcie_rq_seq_num1,
   input                            pcie_rq_seq_num_vld1,
   input       [5:0]                pcie_rq_seq_num2,
   input                            pcie_rq_seq_num_vld2,
   input       [5:0]                pcie_rq_seq_num3,
   input                            pcie_rq_seq_num_vld3,
   
   //Cfg Flow Control Information
   input       [7:0]                cfg_fc_ph,
   input       [7:0]                cfg_fc_nph,
   input       [7:0]                cfg_fc_cplh,
   input       [11:0]               cfg_fc_pd,
   input       [11:0]               cfg_fc_npd,
   input       [11:0]               cfg_fc_cpld,
   output       [2:0]                cfg_fc_sel,
   input                            cfg_err_fatal_out,
   
   //BMD_AXIST RX Engine
   // Completer Request Interface
   input       [5:0]                pcie_cq_np_req_count,
   output logic                     pcie_cq_np_req,
   
   // Requester Completion Interface
   //RX Message Interface
   input                            cfg_msg_received,
   input       [4:0]                cfg_msg_received_type,
   input       [7:0]                cfg_msg_data,
   
   // BMD_AXIST Interrupt Interface
   output logic                     interrupt_done,  // Indicates whether interrupt is done or in process
   
   // Legacy Interrupt Interface
   input                            cfg_interrupt_sent, // Core asserts this signal when it sends out a Legacy interrupt
   output logic [3:0]               cfg_interrupt_int,  // 4 Bits for INTA, INTB, INTC, INTD (assert or deassert)
   output logic [3:0]               cfg_interrupt_pending, // For Legacy interrupts
   
   // MSI Interrupt Interface
   input        [3:0]               cfg_interrupt_msi_enable,
   input                            cfg_interrupt_msi_sent,
   input                            cfg_interrupt_msi_fail,
   
   output logic [31:0]              cfg_interrupt_msi_int,
   output logic [7:0]               cfg_interrupt_msi_function_number,
   output logic [1:0]               cfg_interrupt_msi_select,

   //MSI-X Interrupt Interface
   input        [3:0]               cfg_interrupt_msix_enable,
   input        [3:0]               cfg_interrupt_msix_mask,
   input        [251:0]             cfg_interrupt_msix_vf_mask,
   input        [251:0]             cfg_interrupt_msix_vf_enable,
   input                            cfg_interrupt_msix_vec_pending_status,
   output logic                     cfg_interrupt_msix_int,
   output logic [1:0]               cfg_interrupt_msix_vec_pending,
 
   output logic                     req_completion,
   input       [2:0]                cfg_current_speed,
   input       [5:0]                cfg_negotiated_width,
   input       [1:0]                cfg_max_payload,
   input       [2:0]                cfg_max_read_req,
   input       [7:0]                cfg_function_status,
   input                            cfg_10b_tag_requester_enable,
   output logic                     cfg_err_cor
);
   `STRUCT_AXI_RQ_IF_1024
   `STRUCT_AXI_RC_IF_1024
   `STRUCT_AXI_CQ_IF_1024
   `STRUCT_AXI_CC_IF_1024
   `STRUCT_AXI_CQ_IF_512
   `STRUCT_AXI_CC_IF_512

   // Local wires
   logic [10:0]                     rd_addr;
   logic [3:0]                      rd_be;
   logic [31:0]                     rd_data;
   
   logic [10:0]                     wr_addr;
   logic [7:0]                      wr_be;
   logic [63:0]                     wr_data;
   logic                            wr_en;
   logic                            wr_busy;
   
   logic                            req_compl;
   logic                            req_compl_wd;
   logic                            req_compl_ur;
   logic                            compl_done;
   
   logic [2:0]                      req_tc;
   logic                            req_td;
   logic                            req_ep;
   logic [2:0]                      req_attr;
   logic [10:0]                     req_len;
   logic [15:0]                     req_rid;
   logic [9:0]                      req_tag;
   logic [7:0]                      req_be;
   logic [12:0]                     req_addr;
   logic [1:0]                      req_at;
   logic                            trn_sent;
   
   logic [63:0]                     req_des_qword0;
   logic [63:0]                     req_des_qword1;
   logic                            req_des_tph_present;
   logic [1:0]                      req_des_tph_type;
   logic [7:0]                      req_des_tph_st_tag;
   
   logic                            req_mem_lock;
   logic                            req_mem;
   
   logic                            payload_len;
   logic [15:0]                     completer_id;
   
   logic                            init_rst;
   
   logic                            mwr_start;
   logic                            mwr_int_dis_o;
   logic                            mwr_done;
   logic [15:0]                     mwr_len;
   logic [7:0]                      mwr_tag;
   logic [3:0]                      mwr_lbe;
   logic [3:0]                      mwr_fbe;
   logic [31:0]                     mwr_addr;
   logic [15:0]                     mwr_count;
   logic [31:0]                     mwr_data;
   logic [2:0]                      mwr_tlp_tc_o;
   logic                            mwr_64b_en_o;
   logic                            mwr_phant_func_en1;
   logic [7:0]                      mwr_up_addr_o;
   logic                            mwr_relaxed_order;
   logic                            mwr_nosnoop;
   logic [7:0]                      mwr_wrr_cnt;
   
   logic                            mrd_start;
   logic                            mrd_int_dis_o;
(* mark_debug *)   logic                                  mrd_done_tx_engine_o;
(* mark_debug *)   logic                                  mrd_done_mem_access_o;
   logic                                                  mrd_done;
   logic [15:0]                     mrd_len;
   logic [7:0]                      mrd_tag;
   logic [3:0]                      mrd_lbe;
   logic [3:0]                      mrd_fbe;
   logic [31:0]                     mrd_addr;
   logic [15:0]                     mrd_count;
   logic [2:0]                      mrd_tlp_tc_o;
   logic                            mrd_64b_en_o;
   logic                            mrd_phant_func_en1;
   logic [7:0]                      mrd_up_addr_o;
   logic                            mrd_relaxed_order;
   logic                            mrd_nosnoop;
   logic [7:0]                      mrd_wrr_cnt;
   logic                            mwr_zerolen_en_o;
   
   logic [7:0]                      cpl_ur_found;
   logic [7:0]                      cpl_ur_tag;
   
   logic [31:0]                     cpld_data;
   logic [31:0]                     cpld_data_size;
   
   logic [31:0]                     cpld_found;
   logic [31:0]                     cpld_size;
   logic                            cpld_malformed;
   logic                            cpld_data_err;
   logic                            cpld_parity_err;
   logic                            req_parity_err;
  
   logic                            mrd_start_o;
   logic                            cpl_streaming;
   logic                            rd_metering;
   logic [3:0]                      trn_wait_count;

   logic                            gen_leg_intr_wr;
   logic                            gen_leg_intr_rd;

   //logic                            send_leg_intr;
   //logic                            send_msi_intr;
   //logic                            prev_gen_leg_intr_wr;
   //logic                            prev_gen_leg_intr_rd;

   logic                            client_tag_released_0;
   logic                            client_tag_released_1;
   logic                            client_tag_released_2;
   logic                            client_tag_released_3;
   logic                            client_tag_released_4;
   logic                            client_tag_released_5;
   logic                            client_tag_released_6;
   logic                            client_tag_released_7;

   logic [RQ_AVAIL_TAG_IDX-1:0]     client_tag_released_num_0;
   logic [RQ_AVAIL_TAG_IDX-1:0]     client_tag_released_num_1;
   logic [RQ_AVAIL_TAG_IDX-1:0]     client_tag_released_num_2;
   logic [RQ_AVAIL_TAG_IDX-1:0]     client_tag_released_num_3;
   logic [RQ_AVAIL_TAG_IDX-1:0]     client_tag_released_num_4;
   logic [RQ_AVAIL_TAG_IDX-1:0]     client_tag_released_num_5;
   logic [RQ_AVAIL_TAG_IDX-1:0]     client_tag_released_num_6;
   logic [RQ_AVAIL_TAG_IDX-1:0]     client_tag_released_num_7;

   logic                            tags_all_back;
   
   assign mrd_done   = mrd_done_tx_engine_o & mrd_done_mem_access_o;
   assign cfg_err_cor   = cpld_parity_err | req_parity_err;

   // SHIM logic between 1024b/512b
   s_axis_cc_tuser_512  s_axis_cc_tuser_512_int;
   logic [15:0]         s_axis_cc_tkeep_512_int;
   logic [511:0]        s_axis_cc_tdata_512_int;

   s_axis_cq_tuser_512  m_axis_cq_tuser_512_int;
   logic [15:0]         m_axis_cq_tkeep_512_int;
   logic [511:0]        m_axis_cq_tdata_512_int;

/********************************************************************************************************
    RC tready logic
 ********************************************************************************************************/
//   logic                           m_axis_rc_tready_int; // TODO for TEMP wire from RC module, need to be connected back to output
//
//   logic [2:0] rc_tready_cnt;
//// rc_tready drop/drive logic
//always @ (posedge user_clk) begin
//  if(user_reset) begin
//    rc_tready_cnt <= 0;
//    m_axis_rc_tready <= 1'b0;
//  end
//  else begin
//    if(m_axis_rc_tready_int & m_axis_rc_tvalid) begin
//      rc_tready_cnt <= 0;
//      m_axis_rc_tready <= 1'b0;
//    end
//    else begin
//      rc_tready_cnt <= (&rc_tready_cnt) ? 3'b111 : rc_tready_cnt + 1;
//      m_axis_rc_tready <= &rc_tready_cnt;
//    end
//  end
//end

//********************************************************************************************************
   logic cfg_10b_tag_requester_enable_reg, cfg_10b_tag_requester_enable_reg2;
  `BMDREG(user_clk, reset_n, cfg_10b_tag_requester_enable_reg,  cfg_10b_tag_requester_enable, 1'b0)          
  `BMDREG(user_clk, reset_n, cfg_10b_tag_requester_enable_reg2, cfg_10b_tag_requester_enable_reg, 1'b0)          


BMD_AXIST_CQ_CC_SHIM EP_CQ_CC_SHIM (
   //CQ: 1024b from hard block, 512 to user
   .m_axis_cq_tuser_1024 (m_axis_cq_tuser),
   .m_axis_cq_tkeep_1024 (m_axis_cq_tkeep),
   .m_axis_cq_tdata_1024 (m_axis_cq_tdata),
   .m_axis_cq_tuser_512  (m_axis_cq_tuser_512_int),
   .m_axis_cq_tkeep_512  (m_axis_cq_tkeep_512_int),
   .m_axis_cq_tdata_512  (m_axis_cq_tdata_512_int),
   //CC: 512b from user, 1024b to hard block
   .s_axis_cc_tdata_512  (s_axis_cc_tdata_512_int),
   .s_axis_cc_tkeep_512  (s_axis_cc_tkeep_512_int),
   .s_axis_cc_tuser_512  (s_axis_cc_tuser_512_int),
   .s_axis_cc_tdata_1024 (s_axis_cc_tdata),
   .s_axis_cc_tkeep_1024 (s_axis_cc_tkeep),
   .s_axis_cc_tuser_1024 (s_axis_cc_tuser)
); //CQ_CC_SHIM

   BMD_AXIST_EP_MEM_ACCESS EP_MEM (
      .clk                                      ( user_clk ),     
      .rst_n                                    ( reset_n ),   

      .addr_i                                   ( req_addr[8:2] ),
      .rd_be_i                                  ( rd_be ),      
      .rd_data_o                                ( rd_data ), 
               
      .wr_be_i                                  ( wr_be ),    
      .wr_data_i                                ( wr_data[31:0] ), 
      .wr_en_i                                  ( wr_en ),   
      .wr_busy_o                                ( wr_busy ),    
      
      .init_rst_o                               ( init_rst ),  
      
      .mrd_start_o                              ( mrd_start ),               // O
      .mrd_int_dis_o                            ( mrd_int_dis_o ),           // O
      .mrd_done_o                               ( mrd_done_mem_access_o ),   // O
      .mrd_addr_o                               ( mrd_addr ),                // O [31:0]
      .mrd_count_o                              ( mrd_count ),               // O [31:0]
      .mrd_done_i                               ( mrd_done ),                // I
      .mrd_len_o                                ( mrd_len ),                 // O
      .mrd_tlp_tc_o                             ( mrd_tlp_tc_o ),            // O [2:0]
      .mrd_64b_en_o                             ( mrd_64b_en_o ),            // O
      .mrd_phant_func_dis1_o                    ( mrd_phant_func_dis1 ), 
      .mrd_up_addr_o                            ( mrd_up_addr_o ),           // O [7:0]
      .mrd_relaxed_order_o                      ( mrd_relaxed_order ),
      .mrd_nosnoop_o                            ( mrd_nosnoop ),             // O
      .mrd_wrr_cnt_o                            ( mrd_wrr_cnt ),             // O [7:0]
      
      .mwr_start_o                              ( mwr_start ),               // O
      .mwr_int_dis_o                            ( mwr_int_dis_o ),           // O
      .mwr_done_i                               ( mwr_done ),                // I
      .mwr_addr_o                               ( mwr_addr ),                // O [31:0]
      .mwr_len_o                                ( mwr_len ),                 // O [31:0]
      .mwr_count_o                              ( mwr_count ),               // O [31:0]
      .mwr_data_o                               ( mwr_data ),                // O [31:0]
      .mwr_tlp_tc_o                             ( mwr_tlp_tc_o ),            // O [2:0]
      .mwr_64b_en_o                             ( mwr_64b_en_o ),            // O
      .mwr_phant_func_dis1_o                    ( mwr_phant_func_dis1 ), 
      .mwr_up_addr_o                            ( mwr_up_addr_o ),           // O [7:0]
      .mwr_relaxed_order_o                      ( mwr_relaxed_order ), 
      .mwr_nosnoop_o                            ( mwr_nosnoop ),             // O
      .mwr_wrr_cnt_o                            ( mwr_wrr_cnt ),             // O [7:0]
      .mwr_zerolen_en_o                         ( mwr_zerolen_en_o ),        // O
      
      .cpl_ur_found_i                           ( cpl_ur_found ),            // I [7:0]
      .cpl_ur_tag_i                             ( cpl_ur_tag ),              // I [7:0]
      .cpld_data_o                              ( cpld_data ),               // O [31:0]
      .cpld_found_i                             ( cpld_found ),              // I [31:0]
      .cpld_data_size_i                         ( cpld_data_size ),        // I [31:0]
      .cpld_malformed_i                         ( 1'b0 ),                    // I 
      .cpld_data_err_i                          ( cpld_data_err ),           // I
      .rd_metering_o                            ( rd_metering ),             // O
      .tags_all_back_i                          ( tags_all_back ),
      
      .trn_wait_count                           ( trn_wait_count ),
      
      .cfg_neg_max_link_width                   ( cfg_negotiated_width[3:0] ),
      .cfg_prg_max_payload_size                 ( cfg_max_payload ),
      .cfg_max_rd_req_size                      ( cfg_max_read_req ),
      .cfg_bus_mstr_enable                      ( cfg_function_status[2:2] )
   ); //EP_MEM

BMD_AXIST_RC_1024 #(
  .C_DATA_WIDTH                  (C_DATA_WIDTH                 ),
  .AXISTEN_IF_REQ_ALIGNMENT_MODE (AXISTEN_IF_REQ_ALIGNMENT_MODE),
  .AXISTEN_IF_RC_STRADDLE        (AXISTEN_IF_RC_STRADDLE       ),
  .AXISTEN_IF_REQ_PARITY_CHECK   (AXISTEN_IF_REQ_PARITY_CHECK  ),
  .AXI4_RC_TUSER_WIDTH           (AXI4_RC_TUSER_WIDTH          ),
  .AXISTEN_IF_ENABLE_CLIENT_TAG  (AXISTEN_IF_ENABLE_CLIENT_TAG ),
  .RQ_AVAIL_TAG_IDX              (RQ_AVAIL_TAG_IDX             ),
  .TCQ                           (TCQ                          )
) EP_RC_1024 (
   // Clock and Reset
   .user_clk   (user_clk  ),
   .reset_n    (reset_n   ),
   .init_rst_i (init_rst  ),

   // AXIST RC I/F
   .m_axis_rc_tvalid (m_axis_rc_tvalid),
   .m_axis_rc_tlast  (m_axis_rc_tlast ),
   .m_axis_rc_tuser  (m_axis_rc_tuser ),  //[336:0] 
   .m_axis_rc_tkeep  (m_axis_rc_tkeep ),  //[31:0]  
   .m_axis_rc_tdata  (m_axis_rc_tdata ),  //[1023:0]   
   .m_axis_rc_tready (m_axis_rc_tready),
   .cfg_10b_tag_requester_enable ( cfg_10b_tag_requester_enable_reg2 ),

   // Client Tag
   .client_tag_released_0 (client_tag_released_0),
   .client_tag_released_1 (client_tag_released_1),
   .client_tag_released_2 (client_tag_released_2),
   .client_tag_released_3 (client_tag_released_3),
   .client_tag_released_4 (client_tag_released_4),
   .client_tag_released_5 (client_tag_released_5),
   .client_tag_released_6 (client_tag_released_6),
   .client_tag_released_7 (client_tag_released_7),

   .client_tag_released_num_0 (client_tag_released_num_0),
   .client_tag_released_num_1 (client_tag_released_num_1),
   .client_tag_released_num_2 (client_tag_released_num_2),
   .client_tag_released_num_3 (client_tag_released_num_3),
   .client_tag_released_num_4 (client_tag_released_num_4),
   .client_tag_released_num_5 (client_tag_released_num_5),
   .client_tag_released_num_6 (client_tag_released_num_6),
   .client_tag_released_num_7 (client_tag_released_num_7),

   // CPLD I/F to EP_MEM
   .cpld_data_i      (cpld_data      ),
   .cpld_found_o     (cpld_found     ),
   .cpld_data_size_o (cpld_data_size ),
   .cpld_data_err_o  (cpld_data_err  ),
   .cpld_parity_err_o(cpld_parity_err)
); //RC_1024

   BMD_AXIST_CQ_512 #(
      .AXISTEN_IF_CMP_ALIGNMENT_MODE   ( AXISTEN_IF_CMP_ALIGNMENT_MODE ),
      .AXISTEN_IF_CQ_STRADDLE          ( AXISTEN_IF_CQ_STRADDLE ),
      .AXISTEN_IF_CMP_PARITY_CHECK     ( AXISTEN_IF_CMP_PARITY_CHECK ),
      .AXI4_CQ_TUSER_WIDTH             ( AXI4_CQ_TUSER_WIDTH    ),
      .AXI4_CC_TUSER_WIDTH             ( AXI4_CC_TUSER_WIDTH    ),
      .AXI4_RQ_TUSER_WIDTH             ( AXI4_RQ_TUSER_WIDTH    ),
      .AXI4_RC_TUSER_WIDTH             ( AXI4_RC_TUSER_WIDTH    ),
      .COMPLETER_10B_TAG               ( COMPLETER_10B_TAG      ),
      .TCQ                             ( TCQ )
   ) EP_CQ_512 (
              
      .user_clk                                 ( user_clk ),
      .reset_n                                  ( reset_n ),

      .m_axis_cq_tvalid                         ( m_axis_cq_tvalid ),
      .m_axis_cq_tlast                          ( m_axis_cq_tlast ),
      .m_axis_cq_tuser                          ( m_axis_cq_tuser_512_int ),
      .m_axis_cq_tkeep                          ( m_axis_cq_tkeep_512_int ),
      .m_axis_cq_tdata                          ( m_axis_cq_tdata_512_int ),
      .m_axis_cq_tready                         ( m_axis_cq_tready ),
      .pcie_cq_np_req                           ( pcie_cq_np_req ),
      
      .req_compl                                ( req_compl ),
      .req_compl_wd                             ( req_compl_wd ),
      .req_compl_ur                             ( req_compl_ur ),
      .compl_done                               ( compl_done ),
      
      .req_tc                                   ( req_tc ),
      .req_attr                                 ( req_attr ),
      .req_len                                  ( req_len ),
      .req_rid                                  ( req_rid ),
      .req_tag                                  ( req_tag ),
      .req_be                                   ( req_be ),
      .req_addr                                 ( req_addr ),
      .req_at                                   ( req_at ),
      
      .req_des_qword0                           ( req_des_qword0 ),
      .req_des_qword1                           ( req_des_qword1 ),
      .req_des_tph_present                      ( req_des_tph_present ),
      .req_des_tph_type                         ( req_des_tph_type ),
      .req_des_tph_st_tag                       ( req_des_tph_st_tag ),
      .req_mem_lock                             ( req_mem_lock ),
      .req_mem                                  ( req_mem ),
      
      .wr_addr                                  ( wr_addr ),
      .wr_be                                    ( wr_be ),
      .wr_data                                  ( wr_data ),
      .wr_en                                    ( wr_en ),
      .payload_len                              ( payload_len ),
      .wr_busy                                  ( wr_busy ),
      .req_parity_err                           ( req_parity_err )
   ); //CQ_512

   //
   // Transmit Controller
   //
   BMD_AXIST_RQ_1024 #(
      .C_DATA_WIDTH                    ( C_DATA_WIDTH                  ),
      .KEEP_WIDTH                      ( KEEP_WIDTH                    ),
      .AXISTEN_IF_REQ_ALIGNMENT_MODE   ( AXISTEN_IF_REQ_ALIGNMENT_MODE ),
      .AXISTEN_IF_RQ_STRADDLE          ( AXISTEN_IF_RQ_STRADDLE        ),
      .AXISTEN_IF_REQ_PARITY_CHECK     ( AXISTEN_IF_REQ_PARITY_CHECK   ),
      .AXI4_CQ_TUSER_WIDTH             ( AXI4_CQ_TUSER_WIDTH           ),
      .AXI4_CC_TUSER_WIDTH             ( AXI4_CC_TUSER_WIDTH           ),
      .AXI4_RQ_TUSER_WIDTH             ( AXI4_RQ_TUSER_WIDTH           ),
      .AXI4_RC_TUSER_WIDTH             ( AXI4_RC_TUSER_WIDTH           ),
      .AXISTEN_IF_ENABLE_CLIENT_TAG    ( AXISTEN_IF_ENABLE_CLIENT_TAG  ),
      .RQ_AVAIL_TAG_IDX                ( RQ_AVAIL_TAG_IDX              ),
      .RQ_AVAIL_TAG                    ( RQ_AVAIL_TAG                  ),      
      .TCQ                             ( TCQ                           )
   ) EP_RQ_1024 (
      .user_clk                                 ( user_clk ),
      .reset_n                                  ( reset_n ),
      .init_rst_i                               ( init_rst ),
            
      // AXI-S Master Request Interface
      .s_axis_rq_tdata                          ( s_axis_rq_tdata ),
      .s_axis_rq_tkeep                          ( s_axis_rq_tkeep ),
      .s_axis_rq_tlast                          ( s_axis_rq_tlast ),
      .s_axis_rq_tvalid                         ( s_axis_rq_tvalid ),
      .s_axis_rq_tuser                          ( s_axis_rq_tuser ),
      .s_axis_rq_tready                         ( s_axis_rq_tready ),

      // Client Tag
      .client_tag_released_0                    ( client_tag_released_0 ),
      .client_tag_released_1                    ( client_tag_released_1 ),
      .client_tag_released_2                    ( client_tag_released_2 ),
      .client_tag_released_3                    ( client_tag_released_3 ),
      .client_tag_released_4                    ( client_tag_released_4 ),
      .client_tag_released_5                    ( client_tag_released_5 ),
      .client_tag_released_6                    ( client_tag_released_6 ),
      .client_tag_released_7                    ( client_tag_released_7 ),

      .client_tag_released_num_0                ( client_tag_released_num_0 ),
      .client_tag_released_num_1                ( client_tag_released_num_1 ),
      .client_tag_released_num_2                ( client_tag_released_num_2 ),
      .client_tag_released_num_3                ( client_tag_released_num_3 ),
      .client_tag_released_num_4                ( client_tag_released_num_4 ),
      .client_tag_released_num_5                ( client_tag_released_num_5 ),
      .client_tag_released_num_6                ( client_tag_released_num_6 ),
      .client_tag_released_num_7                ( client_tag_released_num_7 ),

      .tags_all_back                            ( tags_all_back ),
      .pcie_rq_seq_num0                         ( pcie_rq_seq_num0 ),
      .pcie_rq_seq_num_vld0                     ( pcie_rq_seq_num_vld0 ),
      .pcie_rq_seq_num1                         ( pcie_rq_seq_num1 ),
      .pcie_rq_seq_num_vld1                     ( pcie_rq_seq_num_vld1 ),
      .pcie_rq_seq_num2                         ( pcie_rq_seq_num2 ),
      .pcie_rq_seq_num_vld2                     ( pcie_rq_seq_num_vld2 ),
      .pcie_rq_seq_num3                         ( pcie_rq_seq_num3 ),
      .pcie_rq_seq_num_vld3                     ( pcie_rq_seq_num_vld3 ),
      
      .cfg_10b_tag_requester_enable             ( cfg_10b_tag_requester_enable_reg2 ),
      
      .mrd_start_i                              ( mrd_start ),
      .mrd_done_o                               ( mrd_done_tx_engine_o ),
      .mrd_addr_i                               ( mrd_addr ),
      .mrd_len_i                                ( mrd_len[10:0] ),
      .mrd_count_i                              ( mrd_count ),
      .mrd_wrr_cnt_i                            ( mrd_wrr_cnt ),
      
      .mwr_start_i                              ( mwr_start ),
      .mwr_done_o                               ( mwr_done ),
      .mwr_addr_i                               ( mwr_addr ),
      .mwr_len_i                                ( mwr_len[10:0] ),
      .mwr_count_i                              ( mwr_count ),
      .mwr_data_i                               ( mwr_data ),
      .mwr_wrr_cnt_i                            ( mwr_wrr_cnt ),
      
      .wait_trn_time_i                          ( trn_wait_count )
   ); //RQ_1024

   BMD_AXIST_CC_512 #(
      .AXISTEN_IF_CMP_ALIGNMENT_MODE   ( AXISTEN_IF_CMP_ALIGNMENT_MODE ),
      .AXISTEN_IF_CC_STRADDLE          ( AXISTEN_IF_CC_STRADDLE ),
      .AXISTEN_IF_CMP_PARITY_CHECK     ( AXISTEN_IF_CMP_PARITY_CHECK ),
      .AXI4_CQ_TUSER_WIDTH             ( AXI4_CQ_TUSER_WIDTH    ),
      .AXI4_CC_TUSER_WIDTH             ( AXI4_CC_TUSER_WIDTH    ),
      .AXI4_RQ_TUSER_WIDTH             ( AXI4_RQ_TUSER_WIDTH    ),
      .AXI4_RC_TUSER_WIDTH             ( AXI4_RC_TUSER_WIDTH    ),
      .TCQ                             ( TCQ )
   ) EP_CC_512 (
      .user_clk                                 ( user_clk ),
      .reset_n                                  ( reset_n ),
            
      // AXI-S Target Competion Interface
      .s_axis_cc_tdata                          ( s_axis_cc_tdata_512_int ),
      .s_axis_cc_tkeep                          ( s_axis_cc_tkeep_512_int ),
      .s_axis_cc_tlast                          ( s_axis_cc_tlast ),
      .s_axis_cc_tvalid                         ( s_axis_cc_tvalid ),
      .s_axis_cc_tuser                          ( s_axis_cc_tuser_512_int ),
      .s_axis_cc_tready                         ( s_axis_cc_tready ),

      // TX Message Interface
      .cfg_msg_transmit                         ( cfg_msg_transmit ),
      .cfg_msg_transmit_type                    ( cfg_msg_transmit_type ),
      .cfg_msg_transmit_data                    ( cfg_msg_transmit_data ),
      
      // BMD_AXIST RX Engine Interface
      .req_compl                                ( req_compl ),
      .req_compl_wd                             ( req_compl_wd ),
      .req_compl_ur                             ( req_compl_ur ),      
      .payload_len                              ( payload_len ),
      .compl_done                               ( compl_done ),

      .req_tc                                   ( req_tc ),
      .req_attr                                 ( req_attr ),
      .req_rid                                  ( req_rid ),
      .req_tag                                  ( req_tag ),
      .req_be                                   ( req_be ),
      .req_addr                                 ( req_addr ),
      .req_at                                   ( req_at ),

      .req_des_qword0                           ( req_des_qword0 ),
      .req_des_qword1                           ( req_des_qword1 ),
      .req_des_tph_present                      ( req_des_tph_present ),
      .req_des_tph_type                         ( req_des_tph_type ),
      .req_des_tph_st_tag                       ( req_des_tph_st_tag ),
      .req_mem_lock                             ( req_mem_lock ),
      .req_mem                                  ( req_mem ),
      
      .rd_addr                                  ( rd_addr ),
      .rd_be                                    ( rd_be ),
      .rd_data                                  ( rd_data )
   ); //CC_512

   BMD_AXIST_INTR_CTRL EP_INTR_CTRL(
                
      .user_clk                                 ( user_clk ),
      .reset_n                                  ( reset_n ),
     
      // Trigger to generate interrupts (to / from Mem access Block)
      ////.send_leg_intr                            ( send_leg_intr ),
      ////.send_msi_intr                            ( send_msi_intr ),
      ////.gen_msix_intr                            ( 1'b0 ),
      .mrd_done_i                               ( mrd_done ), 
      .mwr_done_i                               ( mwr_done ),
      .interrupt_done                           ( interrupt_done ),
      
      // Legacy Interrupt Interface
      .cfg_interrupt_sent                       ( cfg_interrupt_sent ),
      .cfg_interrupt_int                        ( cfg_interrupt_int ),
      .cfg_interrupt_pending                    ( cfg_interrupt_pending),
      
      // MSI Interrupt Interface
      .cfg_interrupt_msi_enable                 ( cfg_interrupt_msi_enable ),
      .cfg_interrupt_msi_sent                   ( cfg_interrupt_msi_sent ),
      .cfg_interrupt_msi_fail                   ( cfg_interrupt_msi_fail ),
      .cfg_interrupt_msi_int                    ( cfg_interrupt_msi_int ),
      .cfg_interrupt_msi_function_number        ( cfg_interrupt_msi_function_number ),
      .cfg_interrupt_msi_select                 ( cfg_interrupt_msi_select ),
      
      //MSI-X Interrupt Interface
      .cfg_interrupt_msix_enable                ( cfg_interrupt_msix_enable ),
      .cfg_interrupt_msix_mask                  ( cfg_interrupt_msix_mask ),
      .cfg_interrupt_msix_vf_enable             ( cfg_interrupt_msix_vf_enable ),
      .cfg_interrupt_msix_vf_mask               ( cfg_interrupt_msix_vf_mask ),
      .cfg_interrupt_msix_vec_pending_status    ( cfg_interrupt_msix_vec_pending_status ),
      .cfg_interrupt_msix_int                   ( cfg_interrupt_msix_int ),
      .cfg_interrupt_msix_vec_pending           ( cfg_interrupt_msix_vec_pending )
   );

   assign req_completion   = req_compl | req_compl_wd | req_compl_ur;
   ////assign gen_leg_intr_wr  = mwr_done ;
   ////assign gen_leg_intr_rd  = mrd_done;
   // Temporarily tie to 0
   ////assign send_leg_intr = 1'b0;  
   assign cpl_ur_found = 8'b0; 
   assign cpl_ur_tag = 8'b0;
   assign cfg_fc_sel = 3'b0;   

//   `BMDREG(user_clk, reset_n, prev_gen_leg_intr_wr, gen_leg_intr_wr, 1'b0)
//   `BMDREG(user_clk, reset_n, prev_gen_leg_intr_rd, gen_leg_intr_rd, 1'b0)
//
//   // Single cycle pulse
//`ifdef MSI_INTR
//   `BMDREG(user_clk, reset_n, send_msi_intr, ((gen_leg_intr_wr & ~prev_gen_leg_intr_wr) | (gen_leg_intr_rd & ~prev_gen_leg_intr_rd)) & ~send_msi_intr, 1'b0)
//`else 
//   `BMDREG(user_clk, reset_n, send_leg_intr, ((gen_leg_intr_wr & ~prev_gen_leg_intr_wr) | (gen_leg_intr_rd & ~prev_gen_leg_intr_rd)) & ~send_leg_intr, 1'b0)
//`endif
endmodule // BMD_AXIST_EP
