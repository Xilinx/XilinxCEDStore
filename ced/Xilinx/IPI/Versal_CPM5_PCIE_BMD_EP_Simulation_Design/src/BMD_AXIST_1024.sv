// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

`include "pcie_app_uscale_bmd_1024.vh"
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_1024 #(
   parameter         TCQ                              = 1,
   parameter         C_DATA_WIDTH                     = 1024,                              // RX/TX interface data width
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE    = 2'b00,
   parameter         AXISTEN_IF_CMP_ALIGNMENT_MODE    = 2'b00,
   parameter         AXISTEN_IF_ENABLE_CLIENT_TAG     = 0,
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
   input                            user_lnk_up,
   
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
   
   input       [5:0]                pcie_cq_np_req_count,
   output logic                     pcie_cq_np_req,
   
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
   output       [2:0]               cfg_fc_sel,
   input                            cfg_err_fatal_out,
   
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
   
   input       [2:0]                cfg_current_speed, 
   input       [5:0]                cfg_negotiated_width,
   input       [1:0]                cfg_max_payload,
   input       [2:0]                cfg_max_read_req,
   input       [7:0]                cfg_function_status,
   input                            cfg_10b_tag_requester_enable,
   output logic                     cfg_err_cor
); // synthesis syn_hier = "hard"

   // Local wires
   logic                            req_completion;
   logic                            bmd_reset_n;
   
   assign bmd_reset_n   = user_lnk_up && reset_n;
   
   //
   // BMD_AXIST instance
   //
   BMD_AXIST_EP_1024 #(
      .TCQ                            ( TCQ                         ),
      .C_DATA_WIDTH                   (C_DATA_WIDTH                 ),
      .AXISTEN_IF_REQ_ALIGNMENT_MODE  (AXISTEN_IF_REQ_ALIGNMENT_MODE),
      .AXISTEN_IF_CMP_ALIGNMENT_MODE  (AXISTEN_IF_CMP_ALIGNMENT_MODE),
      .AXISTEN_IF_ENABLE_CLIENT_TAG   (AXISTEN_IF_ENABLE_CLIENT_TAG ),
      .RQ_AVAIL_TAG_IDX               (RQ_AVAIL_TAG_IDX             ),
      .RQ_AVAIL_TAG                   (RQ_AVAIL_TAG                 ),
      .AXISTEN_IF_REQ_PARITY_CHECK    (AXISTEN_IF_REQ_PARITY_CHECK  ),
      .AXISTEN_IF_CMP_PARITY_CHECK    (AXISTEN_IF_CMP_PARITY_CHECK  ),
      .AXISTEN_IF_RQ_STRADDLE         (AXISTEN_IF_RQ_STRADDLE       ),
      .AXISTEN_IF_RC_STRADDLE         (AXISTEN_IF_RC_STRADDLE       ),
      .AXISTEN_IF_CQ_STRADDLE         (AXISTEN_IF_CQ_STRADDLE       ),
      .AXISTEN_IF_CC_STRADDLE         (AXISTEN_IF_CC_STRADDLE       ),
      .AXISTEN_IF_ENABLE_RX_MSG_INTFC (AXISTEN_IF_ENABLE_RX_MSG_INTFC),
      .AXISTEN_IF_ENABLE_MSG_ROUTE    (AXISTEN_IF_ENABLE_MSG_ROUTE  ),
      .AXI4_CQ_TUSER_WIDTH            (AXI4_CQ_TUSER_WIDTH          ),
      .AXI4_CC_TUSER_WIDTH            (AXI4_CC_TUSER_WIDTH          ),
      .AXI4_RQ_TUSER_WIDTH            (AXI4_RQ_TUSER_WIDTH          ),
      .AXI4_RC_TUSER_WIDTH            (AXI4_RC_TUSER_WIDTH          ),
      .KEEP_WIDTH                     (KEEP_WIDTH                   )
   ) BMD_AXIST_EP_1024 (
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
      .cfg_10b_tag_requester_enable             ( cfg_10b_tag_requester_enable ),
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
