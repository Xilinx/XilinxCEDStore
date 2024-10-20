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
// Project    : Everest FPGA PCI Express Integrated Block
// File       : BMD_AXIST_512.sv
// Version    : 1.0 
//-----------------------------------------------------------------------------

`include "pcie_app_versal_bmd.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_512 #(
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE    = "FALSE",
   parameter         AXISTEN_IF_CMP_ALIGNMENT_MODE    = "FALSE",
   parameter         AXISTEN_IF_ENABLE_CLIENT_TAG     = 0,
   parameter         RQ_AVAIL_TAG_IDX                 = 8,
   parameter         RQ_AVAIL_TAG                     = 256,
   parameter         AXISTEN_IF_REQ_PARITY_CHECK      = 0,
   parameter         AXISTEN_IF_CMP_PARITY_CHECK      = 0,
   parameter         AXISTEN_IF_RQ_STRADDLE           = 0,
   parameter         AXISTEN_IF_RC_STRADDLE           = 0,
   parameter         AXISTEN_IF_CQ_STRADDLE           = 0,
   parameter         AXISTEN_IF_CC_STRADDLE           = 0,
   parameter         AXI4_CQ_TUSER_WIDTH              = 183,
   parameter         AXI4_CC_TUSER_WIDTH              = 81,
   parameter         AXI4_RQ_TUSER_WIDTH              = 137,
   parameter         AXI4_RC_TUSER_WIDTH              = 161,
   parameter         AXISTEN_IF_ENABLE_RX_MSG_INTFC   = 0,
   parameter [17:0]  AXISTEN_IF_ENABLE_MSG_ROUTE      = 18'h2FFFF,
   parameter         COMPLETER_10B_TAG                = "TRUE",
   parameter         TCQ                              = 1,
   //CCIX
   parameter        CCIX_DIRECT_ATTACH_MODE           = "FALSE",
   parameter        AXISTEN_IF_CCIX_TX_CREDIT_LIMIT = 8,
   parameter        AXISTEN_IF_PARITY_CHECK         = 0,
   parameter [15:0] CCIX_VENDOR_ID                  = 16'h2692
)(
   input                            user_clk,
   input                            reset_n,
   input                            user_lnk_up,
   
   // BMD_AXIST TX Engine
   // AXI-S Completer Competion Interface
   output logic [511:0]             s_axis_cc_tdata,
   output logic [15:0]              s_axis_cc_tkeep,
   output logic                     s_axis_cc_tlast,
   output logic                     s_axis_cc_tvalid,
   output logic [80:0]              s_axis_cc_tuser,
   input                            s_axis_cc_tready,
           
   // AXI-S Requester Request Interface
   output logic                     s_axis_rq_tvalid,
   output logic                     s_axis_rq_tlast,
   output logic [182:0]             s_axis_rq_tuser,
   output logic [15:0]              s_axis_rq_tkeep,
   output logic [511:0]             s_axis_rq_tdata,
   input                            s_axis_rq_tready,
   
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
   input                            m_axis_cq_tvalid,
   input                            m_axis_cq_tlast,
   input       [182:0]              m_axis_cq_tuser,
   input       [15:0]               m_axis_cq_tkeep,
   input       [511:0]              m_axis_cq_tdata,
   output logic                     m_axis_cq_tready,
   input       [5:0]                pcie_cq_np_req_count,
   output logic                     pcie_cq_np_req,
   
   // Requester Completion Interface
   input                            m_axis_rc_tvalid,
   input                            m_axis_rc_tlast,
   input       [160:0]              m_axis_rc_tuser,
   input       [15:0]               m_axis_rc_tkeep,
   input       [511:0]              m_axis_rc_tdata,
   output logic                     m_axis_rc_tready,
   
   //RX Message Interface
   input                            cfg_msg_received,
   input       [4:0]                cfg_msg_received_type,
   input       [7:0]                cfg_msg_data,
   
   // BMD_AXIST Interrupt Interface
   output logic                     interrupt_done,   // Indicates whether interrupt is done or in process
   
   // Legacy Interrupt Interface
   input                            cfg_interrupt_sent,  // Core asserts this signal when it sends out a Legacy interrupt
   output logic [3:0]               cfg_interrupt_int,   // 4 Bits for INTA, INTB, INTC, INTD (assert or deassert)
   
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
   input        [251:0]             cfg_interrupt_msix_vf_enable,
   input        [251:0]             cfg_interrupt_msix_vf_mask,
   input                            cfg_interrupt_msix_vec_pending_status,
   output logic                     cfg_interrupt_msix_int,
   output logic [1:0]               cfg_interrupt_msix_vec_pending,
   
   input                            cfg_power_state_change_interrupt,
   output logic                     cfg_power_state_change_ack,
   
   input       [1:0]                cfg_current_speed, 
   input       [5:0]                cfg_negotiated_width,
   input       [1:0]                cfg_max_payload,
   input       [2:0]                cfg_max_read_req,
   input       [7:0]                cfg_function_status,
   output logic                     cfg_err_cor,
   // CCIX Interface
   input                            ccix_user_clk,
   input                            ccix_optimized_tlp_tx_and_rx_enable,

   // CCIX TX
   //input                            ccix_tx_credit,
   output                           s_axis_ccix_tx_tvalid,
   output                [100:0]    s_axis_ccix_tx_tuser,
   output                [511:0]    s_axis_ccix_tx_tdata,
   input                            ccix_tx_credit_gnt, // Flow control credits from CCIX protocol processing block
   output                           ccix_tx_credit_rtn, // Used to return unused credits to CCIX protocol processing block
   output                           ccix_tx_active_req, // Asserted by TL to request a transition from STOP to ACTIVATE
   input                            ccix_tx_active_ack, // Grant from CCIX block

   // CCIX RX
   input                 [511:0]    m_axis_ccix_rx_tdata,
   input                            m_axis_ccix_rx_tvalid,
   input                 [100:0]    m_axis_ccix_rx_tuser,
   output                           ccix_rx_credit_grant,  // Flow control credits from CCIX protocol processing block
   input                            ccix_rx_credit_return, // Used to return unused credits to CCIX protocol processing block
   input [7:0]                      ccix_rx_credit_av,     // Current value of available credit maintained by the bridge
   input                            ccix_rx_active_req,    // Asserted by TL to request a transition from STOP to ACTIVATE
   output                           ccix_rx_active_ack,     // Grant from CCIX block
   input                            cfg_vc1_enable
   //input                   [7:0]    ccix_rx_credit_av,
   //output                           ccix_rx_credit


); // synthesis syn_hier = "hard"

   // Local wires
   logic                            req_completion;
   logic                            bmd_reset_n;
   
   assign bmd_reset_n   = user_lnk_up && reset_n;
   
   //
   // BMD_AXIST instance
   //
   BMD_AXIST_EP_512 #(
      .TCQ                             ( TCQ ),
      .AXISTEN_IF_REQ_ALIGNMENT_MODE   ( AXISTEN_IF_REQ_ALIGNMENT_MODE ),
      .AXISTEN_IF_CMP_ALIGNMENT_MODE   ( AXISTEN_IF_CMP_ALIGNMENT_MODE ),
      .AXISTEN_IF_ENABLE_CLIENT_TAG    ( AXISTEN_IF_ENABLE_CLIENT_TAG ),
      .RQ_AVAIL_TAG_IDX                ( RQ_AVAIL_TAG_IDX       ),
      .RQ_AVAIL_TAG                    ( RQ_AVAIL_TAG           ),
      .AXISTEN_IF_REQ_PARITY_CHECK     ( AXISTEN_IF_REQ_PARITY_CHECK ),
      .AXISTEN_IF_CMP_PARITY_CHECK     ( AXISTEN_IF_CMP_PARITY_CHECK ),
      .AXISTEN_IF_ENABLE_RX_MSG_INTFC  ( AXISTEN_IF_ENABLE_RX_MSG_INTFC ),
      .AXISTEN_IF_ENABLE_MSG_ROUTE     ( AXISTEN_IF_ENABLE_MSG_ROUTE ),
      .AXI4_CQ_TUSER_WIDTH             ( AXI4_CQ_TUSER_WIDTH    ),
      .AXI4_CC_TUSER_WIDTH             ( AXI4_CC_TUSER_WIDTH    ),
      .AXI4_RQ_TUSER_WIDTH             ( AXI4_RQ_TUSER_WIDTH    ),
      .AXI4_RC_TUSER_WIDTH             ( AXI4_RC_TUSER_WIDTH    ),
      .AXISTEN_IF_RQ_STRADDLE          ( AXISTEN_IF_RQ_STRADDLE ),
      .AXISTEN_IF_RC_STRADDLE          ( AXISTEN_IF_RC_STRADDLE ),
      .AXISTEN_IF_CQ_STRADDLE          ( AXISTEN_IF_CQ_STRADDLE ),
      .AXISTEN_IF_CC_STRADDLE          ( AXISTEN_IF_CC_STRADDLE ),
      .COMPLETER_10B_TAG               ( COMPLETER_10B_TAG      ),
      // CCIX
      .CCIX_DIRECT_ATTACH_MODE         ( CCIX_DIRECT_ATTACH_MODE     ),
      .AXISTEN_IF_CCIX_TX_CREDIT_LIMIT         ( AXISTEN_IF_CCIX_TX_CREDIT_LIMIT ),
      .AXISTEN_IF_PARITY_CHECK                 ( AXISTEN_IF_PARITY_CHECK         ),
      .CCIX_VENDOR_ID                          ( CCIX_VENDOR_ID                  )

   ) BMD_AXIST_EP_512 (
      .user_clk                                 ( user_clk ),
      .reset_n                                  ( reset_n ),
      .s_axis_cc_tdata                          ( s_axis_cc_tdata ),
      .s_axis_cc_tkeep                          ( s_axis_cc_tkeep ),
      .s_axis_cc_tlast                          ( s_axis_cc_tlast ),
      .s_axis_cc_tvalid                         ( s_axis_cc_tvalid ),
      .s_axis_cc_tuser                          ( s_axis_cc_tuser ),
      .s_axis_cc_tready                         ( s_axis_cc_tready ),
      .s_axis_rq_tvalid                         ( s_axis_rq_tvalid ),
      .s_axis_rq_tlast                          ( s_axis_rq_tlast ),
      .s_axis_rq_tuser                          ( s_axis_rq_tuser ),
      .s_axis_rq_tkeep                          ( s_axis_rq_tkeep ),
      .s_axis_rq_tdata                          ( s_axis_rq_tdata ),
      .s_axis_rq_tready                         ( s_axis_rq_tready ),
      .cfg_msg_transmit_done                    ( cfg_msg_transmit_done ),
      .cfg_msg_transmit                         ( cfg_msg_transmit ),
      .cfg_msg_transmit_type                    ( cfg_msg_transmit_type ),
      .cfg_msg_transmit_data                    ( cfg_msg_transmit_data ),
      .pcie_rq_tag                              ( pcie_rq_tag ),
      .pcie_rq_tag_vld                          ( pcie_rq_tag_vld ),
      .pcie_tfc_nph_av                          ( pcie_tfc_nph_av ),
      .pcie_tfc_npd_av                          ( pcie_tfc_npd_av ),
      .pcie_tfc_np_pl_empty                     ( pcie_tfc_np_pl_empty ),
      .pcie_rq_seq_num0                         ( pcie_rq_seq_num0 ),
      .pcie_rq_seq_num_vld0                     ( pcie_rq_seq_num_vld0 ),
      .pcie_rq_seq_num1                         ( pcie_rq_seq_num1 ),
      .pcie_rq_seq_num_vld1                     ( pcie_rq_seq_num_vld1 ),
      .cfg_fc_ph                                ( cfg_fc_ph ),
      .cfg_fc_nph                               ( cfg_fc_nph ),
      .cfg_fc_cplh                              ( cfg_fc_cplh ),
      .cfg_fc_pd                                ( cfg_fc_pd ),
      .cfg_fc_npd                               ( cfg_fc_npd ),
      .cfg_fc_cpld                              ( cfg_fc_cpld ),
      .cfg_fc_sel                               ( cfg_fc_sel ),
      // CCIX Interface
      .ccix_user_clk                           ( ccix_user_clk ),
      .ccix_optimized_tlp_tx_and_rx_enable     ( ccix_optimized_tlp_tx_and_rx_enable ),
      // CCIX TX               
      .s_axis_ccix_tx_tdata                    ( s_axis_ccix_tx_tdata ),
      .s_axis_ccix_tx_tvalid                   ( s_axis_ccix_tx_tvalid ),
      .s_axis_ccix_tx_tuser                    ( s_axis_ccix_tx_tuser ),
      //.ccix_tx_credit                          ( ccix_tx_credit ),
      // CCIX RX
      .m_axis_ccix_rx_tdata                    ( m_axis_ccix_rx_tdata ),
      .m_axis_ccix_rx_tvalid                   ( m_axis_ccix_rx_tvalid ),
      .m_axis_ccix_rx_tuser                    ( m_axis_ccix_rx_tuser ),
      //.ccix_rx_credit                          ( ccix_rx_credit ),
      //.ccix_rx_credit_av                       ( ccix_rx_credit_av ),
      .ccix_tx_credit_rtn                       (ccix_tx_credit_rtn),
      .ccix_tx_credit_gnt                       (ccix_tx_credit_gnt),
      .ccix_tx_active_req                       (ccix_tx_active_req),
      .ccix_tx_active_ack                       (ccix_tx_active_ack),
      .ccix_rx_credit_grant                     (ccix_rx_credit_grant), 
      .ccix_rx_credit_return                    (ccix_rx_credit_return),
      .ccix_rx_credit_av                        (ccix_rx_credit_av),
      .ccix_rx_active_req                       (ccix_rx_active_req),
      .ccix_rx_active_ack                       (ccix_rx_active_ack),
      .cfg_vc1_enable                           (cfg_vc1_enable),

      .cfg_err_fatal_out                        ( cfg_err_fatal_out ),
      .m_axis_cq_tvalid                         ( m_axis_cq_tvalid ),
      .m_axis_cq_tlast                          ( m_axis_cq_tlast ),
      .m_axis_cq_tuser                          ( m_axis_cq_tuser ),
      .m_axis_cq_tkeep                          ( m_axis_cq_tkeep ),
      .m_axis_cq_tdata                          ( m_axis_cq_tdata ),
      .m_axis_cq_tready                         ( m_axis_cq_tready ),
      .pcie_cq_np_req                           ( pcie_cq_np_req ),
      .pcie_cq_np_req_count                     ( pcie_cq_np_req_count ),
      .m_axis_rc_tvalid                         ( m_axis_rc_tvalid ),
      .m_axis_rc_tlast                          ( m_axis_rc_tlast ),
      .m_axis_rc_tuser                          ( m_axis_rc_tuser ),
      .m_axis_rc_tkeep                          ( m_axis_rc_tkeep ),
      .m_axis_rc_tdata                          ( m_axis_rc_tdata ),
      .m_axis_rc_tready                         ( m_axis_rc_tready ),
      .cfg_msg_received                         ( cfg_msg_received ),
      .cfg_msg_received_type                    ( cfg_msg_received_type ),
      .cfg_msg_data                             ( cfg_msg_data ),
      .interrupt_done                           ( interrupt_done ),
      .cfg_interrupt_sent                       ( cfg_interrupt_sent ),
      .cfg_interrupt_int                        ( cfg_interrupt_int ),
      .cfg_interrupt_msi_enable                 ( cfg_interrupt_msi_enable ),
      .cfg_interrupt_msi_sent                   ( cfg_interrupt_msi_sent ),
      .cfg_interrupt_msi_fail                   ( cfg_interrupt_msi_fail ),

      .cfg_interrupt_msi_int                    ( cfg_interrupt_msi_int ),
      .cfg_interrupt_msi_function_number        ( cfg_interrupt_msi_function_number ),
      .cfg_interrupt_msi_select                 ( cfg_interrupt_msi_select ),

      .cfg_interrupt_msix_enable                ( cfg_interrupt_msix_enable ),
      .cfg_interrupt_msix_mask                  ( cfg_interrupt_msix_mask ),
      .cfg_interrupt_msix_vf_enable             ( cfg_interrupt_msix_vf_enable ),
      .cfg_interrupt_msix_vf_mask               ( cfg_interrupt_msix_vf_mask ),
      .cfg_interrupt_msix_vec_pending_status    ( cfg_interrupt_msix_vec_pending_status ),
      .cfg_interrupt_msix_int                   ( cfg_interrupt_msix_int ),
      .cfg_interrupt_msix_vec_pending           ( cfg_interrupt_msix_vec_pending ),

      .req_completion                           ( req_completion ),
      
      .cfg_current_speed                        ( cfg_current_speed ),
      .cfg_negotiated_width                     ( cfg_negotiated_width ),
      .cfg_max_payload                          ( cfg_max_payload ),
      .cfg_max_read_req                         ( cfg_max_read_req ),
      .cfg_function_status                      ( cfg_function_status ),
      .cfg_err_cor                              ( cfg_err_cor )
   );

   //
   // Turn-Off controller
   //
   BMD_AXIST_TO_CTRL BMD_AXIST_TO  (
      .clk                                      ( user_clk ),
      .rst_n                                    ( bmd_reset_n ),
      .req_compl                                ( req_completion ),
      .cfg_power_state_change_interrupt         ( cfg_power_state_change_interrupt ),
      .cfg_power_state_change_ack               (cfg_power_state_change_ack )
   );
   
endmodule
