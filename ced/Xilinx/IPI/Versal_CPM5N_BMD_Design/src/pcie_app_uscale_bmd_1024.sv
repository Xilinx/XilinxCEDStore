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
//
// PCIe App BMD 512-Bit Mode
//
`include "pcie_app_uscale_bmd_1024.vh"
`timescale 1ps / 1ps
//`define IGNORE_SEQ_NUM
(* DowngradeIPIdentifiedWarnings = "yes" *)
module  pcie_app_versal_bmd #(
   parameter         C_DATA_WIDTH                     = 1024,                              // RX/TX interface data width
   parameter         AXISTEN_IF_REQ_ALIGNMENT_MODE    = 2'b00,
   parameter         AXISTEN_IF_CMP_ALIGNMENT_MODE    = 2'b00,
   parameter         AXISTEN_IF_ENABLE_CLIENT_TAG     = 1,
   parameter         TAG_10B_SUPPORT_EN               = "FALSE",
   //parameter         RQ_AVAIL_TAG_IDX                 = TAG_10B_SUPPORT_EN == "TRUE" ? 9 : 8,
   //parameter         RQ_AVAIL_TAG                     = TAG_10B_SUPPORT_EN == "TRUE" ? 512 : 256,
   parameter         RQ_AVAIL_TAG_IDX                 = TAG_10B_SUPPORT_EN == "TRUE" ? 10 : 8,
   parameter         RQ_AVAIL_TAG                     = TAG_10B_SUPPORT_EN == "TRUE" ? 1024 : 256,
   parameter         AXISTEN_IF_REQ_PARITY_CHECK      = 0,
   parameter         AXISTEN_IF_CMP_PARITY_CHECK      = 0,
   parameter         AXISTEN_IF_RQ_STRADDLE           = 2'b10,
   parameter         AXISTEN_IF_RC_STRADDLE           = 2'b11,
   parameter         AXISTEN_IF_CQ_STRADDLE           = 0,
   parameter         AXISTEN_IF_CC_STRADDLE           = 0,
   parameter         AXISTEN_IF_ENABLE_RX_MSG_INTFC   = 0,
   parameter [17:0]  AXISTEN_IF_ENABLE_MSG_ROUTE      = 18'h2FFFF,
   // Switchable between 512b and 256b/128b/64b design
   parameter          AXI4_CQ_TUSER_WIDTH            = 465,
   parameter          AXI4_CC_TUSER_WIDTH            = 165,
   parameter          AXI4_RQ_TUSER_WIDTH            = 373,
   parameter          AXI4_RC_TUSER_WIDTH            = 337,
   parameter         KEEP_WIDTH                       = C_DATA_WIDTH / 32,
   //parameter         AXISTEN_IF_EXT_512               = (C_DATA_WIDTH == 512)? 1: 0,
   //parameter [1:0]   AXISTEN_IF_WIDTH                 = (C_DATA_WIDTH == 512)? 2'b11: 
   //                                                     (C_DATA_WIDTH == 256)? 2'b10:
   //                                                    (C_DATA_WIDTH == 128)? 2'b01: 2'b00,
   parameter         TCQ                              = 1
)(
   input wire                       user_clk,
   input wire                       user_reset,
   input wire                       user_lnk_up,
   input wire                       sys_rst,
   output wire            [7:0]     leds,

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

   output logic                           m_axis_cq_rts,
   output logic                           m_axis_rc_rts,

   // TODO: review width for non-axi related signals
   input       [5:0]                pcie_rq_seq_num0,
   input                            pcie_rq_seq_num_vld0,
   input       [5:0]                pcie_rq_seq_num1,
   input                            pcie_rq_seq_num_vld1,
   input       [5:0]                pcie_rq_tag,
   input                            pcie_rq_tag_vld,

   input       [1:0]                pcie_tfc_nph_av,
   input       [1:0]                pcie_tfc_npd_av,
   output logic                     pcie_cq_np_req,
   input       [5:0]                pcie_cq_np_req_count,

//--------------------------------------------------------------------//
//  Configuration (CFG) Interface                                     //
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// EP and RP                                                          //
//--------------------------------------------------------------------//
   input                            cfg_phy_link_down,
   input       [2:0]                cfg_negotiated_width,
   input       [2:0]                cfg_current_speed,
   input       [1:0]                cfg_max_payload,
   input       [2:0]                cfg_max_read_req,
   input       [7:0]                cfg_function_status,
   input       [5:0]                cfg_function_power_state,
   input       [503:0]              cfg_vf_status,
   input       [1:0]                cfg_link_power_state,

   // Management Interface
   output logic [9:0]               cfg_mgmt_addr,
   output logic                     cfg_mgmt_write,
   output logic [31:0]              cfg_mgmt_write_data,
   output logic [3:0]               cfg_mgmt_byte_enable,
   output logic                     cfg_mgmt_read,
   input       [31:0]               cfg_mgmt_read_data,
   input                            cfg_mgmt_read_write_done,
   output logic                     cfg_mgmt_type1_cfg_reg_access,

   // Error Reporting Interface
   input                            cfg_err_cor_out,
   input                            cfg_err_nonfatal_out,
   input                            cfg_err_fatal_out,
 
   input                            cfg_ltr_enable,
   input       [5:0]                cfg_ltssm_state,
   input       [1:0]                cfg_rcb_status,
   input       [1:0]                cfg_dpa_substate_change,
   input       [1:0]                cfg_obff_enable,
   input                            cfg_pl_status_change,
 
   input                            cfg_msg_received,
   input       [7:0]                cfg_msg_received_data,
   input       [4:0]                cfg_msg_received_type,
 
   output logic                     cfg_msg_transmit,
   output logic [2:0]               cfg_msg_transmit_type,
   output logic [31:0]              cfg_msg_transmit_data,
   input                            cfg_msg_transmit_done,
   input                            cfg_10b_tag_requester_enable,
 
   input       [7:0]                cfg_fc_ph,
   input       [11:0]               cfg_fc_pd,
   input       [7:0]                cfg_fc_nph,
   input       [11:0]               cfg_fc_npd,
   input       [7:0]                cfg_fc_cplh,
   input       [11:0]               cfg_fc_cpld,
   output logic [2:0]               cfg_fc_sel,
   output logic [63:0]              cfg_dsn,
   output logic                     cfg_power_state_change_ack,
   input                            cfg_power_state_change_interrupt,
   output logic                     cfg_err_cor_in,
   output logic                     cfg_err_uncor_in,
 
   input       [1:0]                cfg_flr_in_process,
   output logic [1:0]               cfg_flr_done,
   input       [251:0]              cfg_vf_flr_in_process,
   output logic                     cfg_vf_flr_done,
   output wire [7:0]                cfg_vf_flr_func_num,
 
   output logic                     cfg_link_training_enable,
 
   output logic [7:0]               cfg_ds_port_number,
   output logic [7:0]               cfg_ds_bus_number,
   output logic [4:0]               cfg_ds_device_number,
   output logic [2:0]               cfg_ds_function_number,
//--------------------------------------------------------------------//
// EP Only                                                            //
//--------------------------------------------------------------------//
   // Interrupt Interface Signals
   output                           interrupt_done,
   output logic [3:0]               cfg_interrupt_int,
   output logic [1:0]               cfg_interrupt_pending,
   input                            cfg_interrupt_sent,
 
   input       [3:0]                cfg_interrupt_msi_enable,
   input       [5:0]                cfg_interrupt_msi_vf_enable,
   input       [5:0]                cfg_interrupt_msi_mmenable,
   input                            cfg_interrupt_msi_mask_update,
   input       [31:0]               cfg_interrupt_msi_data,
   output logic [1:0]               cfg_interrupt_msi_select,
   output logic [31:0]              cfg_interrupt_msi_int,
   output logic [63:0]              cfg_interrupt_msi_pending_status,
   input                            cfg_interrupt_msi_sent,
   input                            cfg_interrupt_msi_fail,
   output logic [2:0]               cfg_interrupt_msi_attr,
   output logic                     cfg_interrupt_msi_tph_present,
   output logic [1:0]               cfg_interrupt_msi_tph_type,
   output logic [7:0]               cfg_interrupt_msi_tph_st_tag,
   output logic [7:0]               cfg_interrupt_msi_function_number,

   input        [3:0]               cfg_interrupt_msix_enable,
   input        [3:0]               cfg_interrupt_msix_mask,
   input        [251:0]             cfg_interrupt_msix_vf_mask,
   input        [251:0]             cfg_interrupt_msix_vf_enable,
   input                            cfg_interrupt_msix_vec_pending_status,
   output logic                     cfg_interrupt_msix_int,
   output logic [1:0]               cfg_interrupt_msix_vec_pending,

   // EP only
   input                            cfg_hot_reset_in,
   output logic                     cfg_config_space_enable,
   output logic                     cfg_req_pm_transition_l23_ready,

   // RP only
   output logic                     cfg_hot_reset_out
);

   logic                            cfg_flr_done_reg;

   logic                            m_axis_cq_tready_bit;
   logic                            m_axis_rc_tready_bit;
   logic                            user_reset_n;
   
   assign user_reset_n  = ~user_reset;
   `BMDREG(user_clk, user_reset_n, cfg_flr_done_reg, cfg_flr_in_process[0], 1'b0)

//--------------------------------------------------------------------//
// PCIe Block EP Tieoffs - Ex. PIO no support the following outputs   //
//--------------------------------------------------------------------//

   assign cfg_dsn                            = {`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1}; // Assign the input DSN
 
   assign cfg_mgmt_addr                      = 10'h0;                // Zero out CFG MGMT 10-bit address port
   assign cfg_mgmt_write                     = 1'b0;                 // Do not write CFG space
   assign cfg_mgmt_write_data                = 32'h0;                // Zero out CFG MGMT input data bus
   assign cfg_mgmt_byte_enable               = 4'h0;                 // Zero out CFG MGMT byte enables
   assign cfg_mgmt_read                      = 1'b0;                 // Do not read CFG space
   assign cfg_mgmt_type1_cfg_reg_access      = 1'b0;
   assign cfg_err_uncor_in                   = 1'b0;                 // Never report UnCorrectable Error
 
   assign cfg_flr_done                       = {1'b0,cfg_flr_done_reg}; // TODO: FIXME : how to drive this?
   assign cfg_vf_flr_done                    = 1'b0;                    // TODO: FIXME : how to drive this?
 
   assign cfg_link_training_enable           = 1'b1;                 // Always enable LTSSM to bring up the Link
 
   assign cfg_interrupt_pending              = 2'h0;
   assign cfg_interrupt_msi_pending_status   = 64'h0;
 
   assign cfg_interrupt_msi_attr             = 3'h0;
   assign cfg_interrupt_msi_tph_present      = 1'b0;
   assign cfg_interrupt_msi_tph_type         = 2'h0;
   assign cfg_interrupt_msi_tph_st_tag       = 8'h0;
 
   assign cfg_config_space_enable            = 1'b1;
   assign cfg_req_pm_transition_l23_ready    = 1'b0;
 
   assign cfg_hot_reset_out                  = 1'b0;
 
   assign cfg_ds_port_number                 = 8'h0;
   assign cfg_ds_bus_number                  = 8'h0;
   assign cfg_ds_device_number               = 5'h0;
   assign cfg_ds_function_number             = 3'h0;
 
   assign m_axis_cq_tready                   = m_axis_cq_tready_bit;
   assign m_axis_rc_tready                   = m_axis_rc_tready_bit;

   assign m_axis_cq_rts                   = 1'b1;
   assign m_axis_rc_rts                   = 1'b1;

////////////////////////////////////////////////////////////////////////
// Link width onehot encoding (Spec width encoding)
//  expanded for x16
wire   [5:0] negotiatedwidth;
assign negotiatedwidth = 6'h01 << cfg_negotiated_width; // 3'b100 is x16

// Register and cycle through the virtual fucntion function level reset.
// This counter will just loop over the virtual functions. Ths should be
// repliced by user logic to perform the actual function level reset as
// needed.
reg     [7:0]     cfg_vf_flr_func_num_reg;
always @(posedge user_clk) begin
  if(user_reset) begin
    cfg_vf_flr_func_num_reg <= 8'd0;
  end else begin
    cfg_vf_flr_func_num_reg <= cfg_vf_flr_func_num_reg + 1'b1;
  end
end
assign cfg_vf_flr_func_num = cfg_vf_flr_func_num_reg;

  // User clock heartbeat and LED connectivity
  reg    [25:0]     user_clk_heartbeat = 26'd0;
  // Create a Clock Heartbeat
  always @(posedge user_clk) begin
    if(!sys_rst) begin
      user_clk_heartbeat <= 26'd0;
    end else begin
      user_clk_heartbeat <= user_clk_heartbeat + 1'b1;
    end
  end
  // LED's enabled for Reference Board design
  // The LEDs are intentionally included in this module so they do not
  // get inferred by the tools for Tandem flows.
  OBUF led_0_obuf (.O(leds[0]), .I(sys_rst));
  OBUF led_1_obuf (.O(leds[1]), .I(user_lnk_up));
  OBUF led_2_obuf (.O(leds[2]), .I(user_clk_heartbeat[25]));
  OBUF led_3_obuf (.O(leds[3]), .I(cfg_current_speed[0]));
  OBUF led_4_obuf (.O(leds[4]), .I(cfg_current_speed[1]));
  OBUF led_5_obuf (.O(leds[5]), .I(cfg_negotiated_width[0]));
  OBUF led_6_obuf (.O(leds[6]), .I(cfg_negotiated_width[1]));
  OBUF led_7_obuf (.O(leds[7]), .I(cfg_negotiated_width[2]));

// TODO: Enable when combining 256 into 512
//   generate
//   if (AXISTEN_IF_EXT_512) begin: g_bmd_axist_512

      BMD_AXIST_1024 #(
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
      ) BMD_AXIST_1024 (
         .user_clk                                 ( user_clk ),
         .reset_n                                  ( user_reset_n ),
         .user_lnk_up                              ( user_lnk_up ),
         .cfg_current_speed                        ( cfg_current_speed ),
         .cfg_max_payload                          ( cfg_max_payload ),
         .cfg_function_status                      ( cfg_function_status ),
         .cfg_err_cor                              ( cfg_err_cor_in ),

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
         .pcie_tfc_np_pl_empty                     (  ),
         .pcie_rq_seq_num0                         ( pcie_rq_seq_num0     ) ,
         .pcie_rq_seq_num_vld0                     ( pcie_rq_seq_num_vld0 ) ,
         .pcie_rq_seq_num1                         ( pcie_rq_seq_num1     ) ,
         .pcie_rq_seq_num_vld1                     ( pcie_rq_seq_num_vld1 ) ,
       
         .cfg_fc_ph                                ( cfg_fc_ph ),
         .cfg_fc_nph                               ( cfg_fc_nph ),
         .cfg_fc_cplh                              ( cfg_fc_cplh ),
         .cfg_fc_pd                                ( cfg_fc_pd ),
         .cfg_fc_npd                               ( cfg_fc_npd ),
         .cfg_fc_cpld                              ( cfg_fc_cpld ),
         .cfg_fc_sel                               ( cfg_fc_sel ),
         .cfg_err_fatal_out                        ( cfg_err_fatal_out ),
         .cfg_negotiated_width                     ( negotiatedwidth ),
         .cfg_max_read_req                         ( cfg_max_read_req ),
	 .cfg_10b_tag_requester_enable             ( cfg_10b_tag_requester_enable ),
       
         .m_axis_cq_tvalid                         ( m_axis_cq_tvalid ),
         .m_axis_cq_tlast                          ( m_axis_cq_tlast ),
         .m_axis_cq_tuser                          ( m_axis_cq_tuser ),
         .m_axis_cq_tkeep                          ( m_axis_cq_tkeep ),
         .m_axis_cq_tdata                          ( m_axis_cq_tdata ),
         .m_axis_cq_tready                         ( m_axis_cq_tready_bit ),
         .pcie_cq_np_req_count                     ( pcie_cq_np_req_count ),
         .pcie_cq_np_req                           ( pcie_cq_np_req ),
       
         .m_axis_rc_tvalid                         ( m_axis_rc_tvalid ),
         .m_axis_rc_tlast                          ( m_axis_rc_tlast ),
         .m_axis_rc_tuser                          ( m_axis_rc_tuser ),
         .m_axis_rc_tkeep                          ( m_axis_rc_tkeep ),
         .m_axis_rc_tdata                          ( m_axis_rc_tdata ),
         .m_axis_rc_tready                         ( m_axis_rc_tready_bit ),
       
         .cfg_msg_received                         ( cfg_msg_received ),
         .cfg_msg_received_type                    ( cfg_msg_received_type ),
         .cfg_msg_data                             ( cfg_msg_received_data ),
       
         .interrupt_done                           ( interrupt_done ),
       
         .cfg_interrupt_sent                       ( cfg_interrupt_sent ),
         .cfg_interrupt_int                        ( cfg_interrupt_int ),
         //.cfg_interrupt_pending                    ( cfg_interrupt_pending),
       
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

         .cfg_power_state_change_interrupt         ( cfg_power_state_change_interrupt ),
         .cfg_power_state_change_ack               ( cfg_power_state_change_ack )
      );
//   end else begin: g_bmd_axist
//   end
//   endgenerate

endmodule
