// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
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

//
// Project    : Versal PCI Express Integrated Block
// File       : pio_ep.v
// Version    : 1.0 
//-----------------------------------------------------------------------------
//
// Description: Endpoint Programmed I/O module.
//
//--------------------------------------------------------------------------------

`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module pio_ep #(
  parameter        TCQ = 1,
  parameter [1:0]  AXISTEN_IF_WIDTH = 00,
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE    = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE    = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE    = 0,
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE    = 0,
   parameter              AXI4_CQ_TUSER_WIDTH = 183,
   parameter              AXI4_CC_TUSER_WIDTH = 81,
   parameter              AXI4_RQ_TUSER_WIDTH = 137,
   parameter              AXI4_RC_TUSER_WIDTH = 161,
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG    = 0,
  parameter        AXISTEN_IF_RQ_PARITY_CHECK      = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK      = 0,
  parameter        AXISTEN_IF_RC_PARITY_CHECK      = 0,
  parameter        AXISTEN_IF_CQ_PARITY_CHECK      = 0,
  parameter        AXISTEN_IF_RC_STRADDLE          = 0,
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC  = 0,
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE     = 18'h2FFFF,
  parameter        COMPLETER_10B_TAG               = "TRUE", // When Completer 8-bit tag is used, this parameter can still be set to TRUE

  //Do not modify the parameters below this line
  //parameter C_DATA_WIDTH = (AXISTEN_IF_WIDTH[1]) ? 256 : (AXISTEN_IF_WIDTH[0])? 128 : 64,
  parameter C_DATA_WIDTH = 512,
  parameter PARITY_WIDTH = C_DATA_WIDTH /8,
  parameter KEEP_WIDTH   = C_DATA_WIDTH /32
) (

  input                            user_clk,
  input                            reset_n,


  // PIO TX Engine

  // AXI-S Completer Competion Interface

  output wire        [C_DATA_WIDTH-1:0]   s_axis_cc_tdata,
  output wire          [KEEP_WIDTH-1:0]   s_axis_cc_tkeep,
  output wire                             s_axis_cc_tlast,
  output wire                             s_axis_cc_tvalid,
  output wire [AXI4_CC_TUSER_WIDTH-1:0]   s_axis_cc_tuser,
  input                                   s_axis_cc_tready,

  // AXI-S Requester Request Interface

  output wire        [C_DATA_WIDTH-1:0]   s_axis_rq_tdata,
  output wire          [KEEP_WIDTH-1:0]   s_axis_rq_tkeep,
  output wire                             s_axis_rq_tlast,
  output wire                             s_axis_rq_tvalid,
  output wire [AXI4_RQ_TUSER_WIDTH-1:0]   s_axis_rq_tuser,
  input                                   s_axis_rq_tready,

  // TX Message Interface

  input                            cfg_msg_transmit_done,
  output wire                      cfg_msg_transmit,
  output wire              [2:0]   cfg_msg_transmit_type,
  output wire             [31:0]   cfg_msg_transmit_data,

  //Tag availability and Flow control Information

  input                    [5:0]   pcie_rq_tag,
  input                            pcie_rq_tag_vld,
  input                    [1:0]   pcie_tfc_nph_av,
  input                    [1:0]   pcie_tfc_npd_av,
  input                            pcie_tfc_np_pl_empty,
  input                    [3:0]   pcie_rq_seq_num,
  input                            pcie_rq_seq_num_vld,

  //Cfg Flow Control Information

  input                    [7:0]   cfg_fc_ph,
  input                    [7:0]   cfg_fc_nph,
  input                    [7:0]   cfg_fc_cplh,
  input                   [11:0]   cfg_fc_pd,
  input                   [11:0]   cfg_fc_npd,
  input                   [11:0]   cfg_fc_cpld,
  output                    [2:0]   cfg_fc_sel,


  //PIO RX Engine
  // Completer Request Interface

  input        [C_DATA_WIDTH-1:0]   m_axis_cq_tdata,
  input                             m_axis_cq_tlast,
  input                             m_axis_cq_tvalid,
  input [AXI4_CQ_TUSER_WIDTH-1:0]   m_axis_cq_tuser,
  input          [KEEP_WIDTH-1:0]   m_axis_cq_tkeep,
  input                     [5:0]   pcie_cq_np_req_count,
  output wire                       m_axis_cq_tready,
  output wire                       pcie_cq_np_req,

  // Requester Completion Interface

  input        [C_DATA_WIDTH-1:0]   m_axis_rc_tdata,
  input                             m_axis_rc_tlast,
  input                             m_axis_rc_tvalid,
  input          [KEEP_WIDTH-1:0]   m_axis_rc_tkeep,
  input [AXI4_RC_TUSER_WIDTH-1:0]   m_axis_rc_tuser,
  output wire                       m_axis_rc_tready,

  // RX Message Interface

  input                            cfg_msg_received,
  input                    [4:0]   cfg_msg_received_type,
  input                    [7:0]   cfg_msg_data,

  // PIO Interrupt Interface

  output wire                      interrupt_done,  // Indicates whether interrupt is done or in process

  // Legacy Interrupt Interface

  input                            cfg_interrupt_sent, // Core asserts this signal when it sends out a Legacy interrupt
  output wire              [3:0]   cfg_interrupt_int,  // 4 Bits for INTA, INTB, INTC, INTD (assert or deassert)

  // MSI Interrupt Interface

  input                            cfg_interrupt_msi_enable,
  input                            cfg_interrupt_msi_sent,
  input                            cfg_interrupt_msi_fail,

  output wire             [31:0]   cfg_interrupt_msi_int,

  //MSI-X Interrupt Interface

  input                            cfg_interrupt_msix_enable,
  input                            cfg_interrupt_msix_sent,
  input                            cfg_interrupt_msix_fail,

  output wire                      cfg_interrupt_msix_int,
  output wire             [63:0]   cfg_interrupt_msix_address,
  output wire             [31:0]   cfg_interrupt_msix_data,

  output                           req_completion,
  output                           completion_done

);

  // Local wires

  wire  [10:0]      rd_addr;
  wire  [3:0]       rd_be;
  wire  [31:0]      rd_data;

  wire  [10:0]      wr_addr;
  wire  [7:0]       wr_be;
  wire  [63:0]      wr_data;
  wire              wr_en;
  wire              wr_busy;

  wire              req_compl;
  wire              req_compl_wd;
  wire              req_compl_ur;
  wire              compl_done;

  wire  [2:0]       req_tc;
  wire  [2:0]       req_attr;
  wire  [10:0]      req_len;
  wire  [15:0]      req_rid;
  wire  [9:0]       req_tag;
  wire  [7:0]       req_be;
  wire  [12:0]      req_addr;
  wire  [1:0]       req_at;
  wire              trn_sent;

  wire [63:0]       req_des_qword0;
  wire [63:0]       req_des_qword1;
  wire              req_des_tph_present;
  wire [1:0]        req_des_tph_type;
  wire [7:0]        req_des_tph_st_tag;

  wire              req_mem_lock;
  wire              req_mem;

  wire              payload_len;

  wire              gen_transaction;
  wire              gen_leg_intr;
  wire              gen_msi_intr;
  wire              gen_msix_intr;


  //
  // ENDPOINT MEMORY : 8KB memory aperture implemented in FPGA BlockRAM(*)
  //

  pio_ep_mem_access ep_mem (

    .user_clk(user_clk),     // I
    .reset_n(reset_n),       // I

    // Read Port

    .rd_addr(rd_addr),     // I [10:0]
    .rd_be(rd_be),         // I [3:0]
    .rd_data(rd_data),     // O [31:0]
    .trn_sent( trn_sent ),

    // Write Port

    .wr_addr(wr_addr),     // I [10:0]
    .wr_be(wr_be),         // I [7:0]
    .wr_data(wr_data),     // I [63:0]
    .wr_en(wr_en),         // I
    .wr_busy(wr_busy),     // O

    .payload_len(payload_len),
    .gen_msix_intr(gen_msix_intr),
    .gen_msi_intr(gen_msi_intr),
    .gen_leg_intr(gen_leg_intr),
    .gen_transaction(gen_transaction)

  );

  //
  // Local-Link Receive Controller
  //

  pio_rx_engine #(
    .TCQ(TCQ),
    .AXISTEN_IF_WIDTH               ( AXISTEN_IF_WIDTH ),
    .C_DATA_WIDTH                   ( C_DATA_WIDTH ),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE   ( AXISTEN_IF_CQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_ALIGNMENT_MODE   ( AXISTEN_IF_RC_ALIGNMENT_MODE ),
    .AXI4_CQ_TUSER_WIDTH            ( AXI4_CQ_TUSER_WIDTH),
    .AXI4_RC_TUSER_WIDTH            ( AXI4_RC_TUSER_WIDTH),
    .AXISTEN_IF_RC_PARITY_CHECK     ( AXISTEN_IF_RC_PARITY_CHECK ),
    .AXISTEN_IF_CQ_PARITY_CHECK     ( AXISTEN_IF_CQ_PARITY_CHECK ),
    .AXISTEN_IF_RC_STRADDLE         ( AXISTEN_IF_RC_STRADDLE ),
    .AXISTEN_IF_ENABLE_RX_MSG_INTFC ( AXISTEN_IF_ENABLE_RX_MSG_INTFC ),
    .AXISTEN_IF_ENABLE_MSG_ROUTE    ( AXISTEN_IF_ENABLE_MSG_ROUTE ),
    .COMPLETER_10B_TAG              ( COMPLETER_10B_TAG )
  ) ep_rx (

    .user_clk( user_clk ),
    .reset_n( reset_n ),

    // Target Request Interface
    .m_axis_cq_tdata( m_axis_cq_tdata ),
    .m_axis_cq_tlast( m_axis_cq_tlast ),
    .m_axis_cq_tvalid( m_axis_cq_tvalid ),
    .m_axis_cq_tuser( m_axis_cq_tuser ),
    .m_axis_cq_tkeep( m_axis_cq_tkeep ),
    .m_axis_cq_tready( m_axis_cq_tready ),
    .pcie_cq_np_req_count ( pcie_cq_np_req_count ),
    .pcie_cq_np_req ( pcie_cq_np_req ),

    // Master Completion Interface

    .m_axis_rc_tdata( m_axis_rc_tdata ),
    .m_axis_rc_tkeep( m_axis_rc_tkeep ),
    .m_axis_rc_tlast( m_axis_rc_tlast ),
    .m_axis_rc_tvalid( m_axis_rc_tvalid ),
    .m_axis_rc_tuser( m_axis_rc_tuser ),
    .m_axis_rc_tready( m_axis_rc_tready ),

     // RX Message Interface

    .cfg_msg_received( cfg_msg_received ),
    .cfg_msg_received_type( cfg_msg_received_type ),
    .cfg_msg_data( cfg_msg_data ),

    .req_compl( req_compl ),
    .req_compl_wd( req_compl_wd ),
    .req_compl_ur( req_compl_ur ),
    .compl_done( compl_done ),

    .req_tc( req_tc ),
    .req_attr( req_attr ),
    .req_len( req_len ),
    .req_rid( req_rid ),
    .req_tag( req_tag ),
    .req_be( req_be ),
    .req_addr( req_addr ),
    .req_at( req_at ),

    .req_des_qword0( req_des_qword0 ),
    .req_des_qword1( req_des_qword1 ),
    .req_des_tph_present( req_des_tph_present ),
    .req_des_tph_type( req_des_tph_type ),
    .req_des_tph_st_tag( req_des_tph_st_tag ),
    .req_mem_lock( req_mem_lock ),
    .req_mem( req_mem ),

    .wr_addr( wr_addr ),
    .wr_be( wr_be ),
    .wr_data( wr_data ),
    .wr_en( wr_en ),
    .payload_len( payload_len ),
    .wr_busy( wr_busy)
  );

    //
    // Local-Link Transmit Controller
    //

  pio_tx_engine #(
    .TCQ( TCQ ),
    .AXISTEN_IF_WIDTH             ( AXISTEN_IF_WIDTH ),
    .C_DATA_WIDTH                 ( C_DATA_WIDTH     ),
    .AXISTEN_IF_RQ_ALIGNMENT_MODE ( AXISTEN_IF_RQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_CC_ALIGNMENT_MODE ( AXISTEN_IF_CC_ALIGNMENT_MODE ),
    .AXI4_CC_TUSER_WIDTH          ( AXI4_CC_TUSER_WIDTH),
    .AXI4_RQ_TUSER_WIDTH          ( AXI4_RQ_TUSER_WIDTH),
    .AXISTEN_IF_ENABLE_CLIENT_TAG ( AXISTEN_IF_ENABLE_CLIENT_TAG ),
    .AXISTEN_IF_RQ_PARITY_CHECK   ( AXISTEN_IF_RQ_PARITY_CHECK ),
    .AXISTEN_IF_CC_PARITY_CHECK   ( AXISTEN_IF_CC_PARITY_CHECK ),
    .COMPLETER_10B_TAG            ( COMPLETER_10B_TAG )
  ) ep_tx (
    .user_clk( user_clk ),
    .reset_n( reset_n ),

    // AXI-S Target Competion Interface

    .s_axis_cc_tdata( s_axis_cc_tdata ),
    .s_axis_cc_tkeep ( s_axis_cc_tkeep ),
    .s_axis_cc_tlast( s_axis_cc_tlast ),
    .s_axis_cc_tvalid( s_axis_cc_tvalid ),
    .s_axis_cc_tuser( s_axis_cc_tuser ),
    .s_axis_cc_tready( s_axis_cc_tready ),

    // AXI-S Master Request Interface

    .s_axis_rq_tdata( s_axis_rq_tdata ),
    .s_axis_rq_tkeep( s_axis_rq_tkeep ),
    .s_axis_rq_tlast( s_axis_rq_tlast ),
    .s_axis_rq_tvalid( s_axis_rq_tvalid ),
    .s_axis_rq_tuser( s_axis_rq_tuser ),
    .s_axis_rq_tready( s_axis_rq_tready ),

    // TX Message Interface

    .cfg_msg_transmit_done( cfg_msg_transmit_done ),
    .cfg_msg_transmit( cfg_msg_transmit ),
    .cfg_msg_transmit_type( cfg_msg_transmit_type ),
    .cfg_msg_transmit_data( cfg_msg_transmit_data ),

    // Tag availability and Flow control Information

    .pcie_rq_tag( pcie_rq_tag ),
    .pcie_rq_tag_vld( pcie_rq_tag_vld ),
    .pcie_tfc_nph_av( pcie_tfc_nph_av ),
    .pcie_tfc_npd_av( pcie_tfc_npd_av ),
    .pcie_tfc_np_pl_empty( pcie_tfc_np_pl_empty ),
    .pcie_rq_seq_num( pcie_rq_seq_num ),
    .pcie_rq_seq_num_vld( pcie_rq_seq_num_vld ),

     // Cfg Flow Control Information

    .cfg_fc_ph( cfg_fc_ph ),
    .cfg_fc_nph( cfg_fc_nph ),
    .cfg_fc_cplh( cfg_fc_cplh ),
    .cfg_fc_pd( cfg_fc_pd ),
    .cfg_fc_npd( cfg_fc_npd ),
    .cfg_fc_cpld( cfg_fc_cpld ),
    .cfg_fc_sel( cfg_fc_sel ),


    // PIO RX Engine Interface

    .req_compl( req_compl ),
    .req_compl_wd( req_compl_wd ),
    .req_compl_ur( req_compl_ur ),
    .payload_len ( payload_len ),
    .compl_done( compl_done ),

    .req_tc( req_tc ),
    .req_td(1'b0),
    .req_ep(1'b0),
    .req_attr( req_attr[1:0] ),
    .req_len( req_len ),
    .req_rid( req_rid ),
    .req_tag( req_tag ),
    .req_be( req_be ),
    .req_addr( req_addr ),
    .req_at( req_at ),

    .req_des_qword0( req_des_qword0 ),
    .req_des_qword1( req_des_qword1 ),
    .req_des_tph_present( req_des_tph_present ),
    .req_des_tph_type( req_des_tph_type ),
    .req_des_tph_st_tag( req_des_tph_st_tag ),
    .req_mem_lock( req_mem_lock ),
    .req_mem( req_mem ),

    .completer_id(16'h0),

    // PIO Memory Access Control Interface

    .rd_addr( rd_addr ),
    .rd_be( rd_be ),
    .rd_data( rd_data ),
    .trn_sent( trn_sent ),
    .gen_transaction( gen_transaction )

    );

  pio_intr_ctrl ep_intr_ctrl(

    .user_clk( user_clk ),
    .reset_n( reset_n ),

    // Trigger to generate interrupts (to / from Mem access Block)

    .gen_leg_intr( gen_leg_intr ),
    .gen_msi_intr( gen_msi_intr ),
    .gen_msix_intr( gen_msix_intr ),
    .interrupt_done( interrupt_done ),

    // Legacy Interrupt Interface

    .cfg_interrupt_sent( cfg_interrupt_sent ),
    .cfg_interrupt_int( cfg_interrupt_int ),

    // MSI Interrupt Interface

    .cfg_interrupt_msi_enable( cfg_interrupt_msi_enable ),
    .cfg_interrupt_msi_sent( cfg_interrupt_msi_sent ),
    .cfg_interrupt_msi_fail( cfg_interrupt_msi_fail ),

    .cfg_interrupt_msi_int( cfg_interrupt_msi_int ),

    //MSI-X Interrupt Interface

    .cfg_interrupt_msix_enable( cfg_interrupt_msix_enable ),
    .cfg_interrupt_msix_sent( cfg_interrupt_msix_sent ),
    .cfg_interrupt_msix_fail( cfg_interrupt_msix_fail ),

    .cfg_interrupt_msix_int( cfg_interrupt_msix_int ),
    .cfg_interrupt_msix_address( cfg_interrupt_msix_address ),
    .cfg_interrupt_msix_data( cfg_interrupt_msix_data )

    );

    assign req_completion = req_compl || req_compl_wd || req_compl_ur;
    assign completion_done = compl_done || interrupt_done ;

endmodule // pio_ep



