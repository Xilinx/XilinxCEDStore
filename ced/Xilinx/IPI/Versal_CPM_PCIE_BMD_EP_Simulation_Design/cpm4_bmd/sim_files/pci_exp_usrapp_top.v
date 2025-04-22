//-----------------------------------------------------------------------------
//
// (c) Copyright 2020-2024 Xilinx, Inc. All rights reserved.
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
// Project    : Versal CPM5N BMD Test bench 
// File       : pci_exp_usrapp_top.v
// Version    : 1.0 
//-----------------------------------------------------------------------------
//--------------------------------------------------------------------------------
`timescale 1ps / 1ps

module pci_exp_usrapp_top # (
  parameter C_DATA_WIDTH                        = 1024,     //512, // RX/TX interface data width
  parameter KEEP_WIDTH                          = C_DATA_WIDTH / 32,
  
  parameter  [4:0] LINK_CAP_MAX_LINK_WIDTH      = 5'h8,
  parameter  [4:0] LINK_CAP_MAX_LINK_SPEED      = 5'h8,
  parameter  [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'h0,

  parameter AXISTEN_IF_RQ_ALIGNMENT_MODE        = "FALSE",
  parameter AXISTEN_IF_CC_ALIGNMENT_MODE        = "FALSE",
  parameter AXISTEN_IF_CQ_ALIGNMENT_MODE        = "FALSE",
  parameter AXISTEN_IF_RC_ALIGNMENT_MODE        = "FALSE",
  parameter AXI4_CQ_TUSER_WIDTH                 = 533,
  parameter AXI4_CC_TUSER_WIDTH                 = 233,
  parameter AXI4_RQ_TUSER_WIDTH                 = 449,
  parameter AXI4_RC_TUSER_WIDTH                 = 473,
  parameter AXISTEN_IF_RQ_PARITY_CHECK          = 0,
  parameter AXISTEN_IF_CC_PARITY_CHECK          = 0,
  parameter AXISTEN_IF_RC_PARITY_CHECK          = 0,
  parameter AXISTEN_IF_CQ_PARITY_CHECK          = 0,
  
  parameter EP_DEV_ID                           = 16'hB03F,
  
  parameter TCQ                                 = 1
)
(
  input user_clk,
  input user_reset,
  input user_lnk_up,
  
  //----------------------------------------------------//
  // 3. AXI Interface                                   //
  //----------------------------------------------------//
  output                           s_axis_rq_tlast,
  output        [C_DATA_WIDTH-1:0] s_axis_rq_tdata,
  output [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser,
  output          [KEEP_WIDTH-1:0] s_axis_rq_tkeep,
  input                            s_axis_rq_tready,
  output                           s_axis_rq_tvalid,

  input        [C_DATA_WIDTH-1:0]  m_axis_rc_tdata,
  input [AXI4_RC_TUSER_WIDTH-1:0]  m_axis_rc_tuser,
  input                            m_axis_rc_tlast,
  input          [KEEP_WIDTH-1:0]  m_axis_rc_tkeep,
  input                            m_axis_rc_tvalid,
  output                           m_axis_rc_tready,

  input         [C_DATA_WIDTH-1:0] m_axis_cq_tdata,
  input  [AXI4_CQ_TUSER_WIDTH-1:0] m_axis_cq_tuser,
  input                            m_axis_cq_tlast,
  input           [KEEP_WIDTH-1:0] m_axis_cq_tkeep,
  input                            m_axis_cq_tvalid,
  output                           m_axis_cq_tready,

  output        [C_DATA_WIDTH-1:0] s_axis_cc_tdata,
  output [AXI4_CC_TUSER_WIDTH-1:0] s_axis_cc_tuser,
  output                           s_axis_cc_tlast,
  output          [KEEP_WIDTH-1:0] s_axis_cc_tkeep,
  output                           s_axis_cc_tvalid,
  input                            s_axis_cc_tready,
  
  input                      [3:0] pcie_tfc_nph_av,
  input                      [3:0] pcie_tfc_npd_av,
  input                      [3:0] pcie_rq_seq_num,
  input                            pcie_rq_seq_num_vld,
  input                      [5:0] pcie_rq_tag,
  input                            pcie_rq_tag_vld,
  input                      [1:0] pcie_rq_tag_av,

  output                           pcie_cq_np_req,
  input                      [5:0] pcie_cq_np_req_count,
  
  //---------------------------------------------------//
  // 4. Configuration (CFG) Interface                  //
  //---------------------------------------------------//

  //---------------------------------------------------//
  // EP and RP                                         //
  //---------------------------------------------------//
  input                            cfg_phy_link_down,
  input                      [1:0] cfg_phy_link_status,
  input                      [2:0] cfg_negotiated_width,
  input                      [1:0] cfg_current_speed,
  input                      [1:0] cfg_max_payload,
  input                      [2:0] cfg_max_read_req,
  input                     [15:0] cfg_function_status,
  input                     [11:0] cfg_function_power_state,
  input                    [503:0] cfg_vf_status,
  input                    [755:0] cfg_vf_power_state,
  input                      [1:0] cfg_link_power_state,

  // Management Interface
  output                     [9:0] cfg_mgmt_addr,
  output                           cfg_mgmt_write,
  output                    [31:0] cfg_mgmt_write_data,
  output                     [3:0] cfg_mgmt_byte_enable,
  output                           cfg_mgmt_read,
  input                     [31:0] cfg_mgmt_read_data,
  input                            cfg_mgmt_read_write_done,
  output                           cfg_mgmt_type1_cfg_reg_access,

  // Error Reporting Interface
  input                            cfg_err_cor_out,
  input                            cfg_err_nonfatal_out,
  input                            cfg_err_fatal_out,
  input                            cfg_local_error,

  input                      [5:0] cfg_ltssm_state,
  input                      [3:0] cfg_rcb_status,
  input                      [3:0] cfg_dpa_substate_change,
  input                      [1:0] cfg_obff_enable,
  input                            cfg_pl_status_change,

  input                      [3:0] cfg_tph_requester_enable,
  input                     [11:0] cfg_tph_st_mode,
  input                    [251:0] cfg_vf_tph_requester_enable,
  input                    [755:0] cfg_vf_tph_st_mode,

  input                            cfg_msg_received,
  input                      [7:0] cfg_msg_received_data,
  input                      [4:0] cfg_msg_received_type,

  output                           cfg_msg_transmit,
  output                     [2:0] cfg_msg_transmit_type,
  output                    [31:0] cfg_msg_transmit_data,
  input                            cfg_msg_transmit_done,

  input                      [7:0] cfg_fc_ph,
  input                     [11:0] cfg_fc_pd,
  input                      [7:0] cfg_fc_nph,
  input                     [11:0] cfg_fc_npd,
  input                      [7:0] cfg_fc_cplh,
  input                     [11:0] cfg_fc_cpld,
  output                     [2:0] cfg_fc_sel,

  output                     [2:0] cfg_per_func_status_control,
  input                     [15:0] cfg_per_func_status_data,
  output                     [2:0] cfg_per_function_number,
  output                           cfg_per_function_output_request,
  input                            cfg_per_function_update_done,

  output                    [63:0] cfg_dsn,
  output                           cfg_power_state_change_ack,
  output                           cfg_power_state_change_interrupt,
  output                           cfg_err_cor_in,
  output                           cfg_err_uncor_in,

  input                      [3:0] cfg_flr_in_process,
  output                     [1:0] cfg_flr_done,
  input                    [251:0] cfg_vf_flr_in_process,
  output                           cfg_vf_flr_done,

  output                           cfg_link_training_enable,
  output                     [7:0] cfg_ds_port_number,

  input                            cfg_ext_read_received,
  input                            cfg_ext_write_received,
  input                      [9:0] cfg_ext_register_number,
  input                      [7:0] cfg_ext_function_number,
  input                     [31:0] cfg_ext_write_data,
  input                      [3:0] cfg_ext_write_byte_enable,
  output                    [31:0] cfg_ext_read_data,
  output                           cfg_ext_read_data_valid,

  //-----------------------------------------//
  // EP Only                                 //
  //-----------------------------------------//

  // Interrupt Interface Signals
  output                     [3:0] cfg_interrupt_int,
  output                     [1:0] cfg_interrupt_pending,
  input                            cfg_interrupt_sent,

  input                      [3:0] cfg_interrupt_msi_enable,
  input                      [7:0] cfg_interrupt_msi_vf_enable,
  input                     [11:0] cfg_interrupt_msi_mmenable,
  input                            cfg_interrupt_msi_mask_update,
  input                     [31:0] cfg_interrupt_msi_data,
  output                     [3:0] cfg_interrupt_msi_select,
  output                    [31:0] cfg_interrupt_msi_int,
  output                    [63:0] cfg_interrupt_msi_pending_status,
  input                            cfg_interrupt_msi_sent,
  input                            cfg_interrupt_msi_fail,
  output                     [2:0] cfg_interrupt_msi_attr,
  output                           cfg_interrupt_msi_tph_present,
  output                     [1:0] cfg_interrupt_msi_tph_type,
  output                     [7:0] cfg_interrupt_msi_tph_st_tag,
  output                     [2:0] cfg_interrupt_msi_function_number,
  output                           cfg_interrupt_msi_pending_status_data_enable,
  output                     [3:0] cfg_interrupt_msi_pending_status_function_num,

// EP only
  input                            cfg_hot_reset_out,
  output                           cfg_config_space_enable,
  output                           cfg_req_pm_transition_l23_ready,

// RP only
  output                           cfg_hot_reset_in,

  output                     [7:0] cfg_ds_bus_number,
  output                     [4:0] cfg_ds_device_number,

  input                     [15:0] cfg_vend_id,

  input                     [15:0] cfg_dev_id,
  input                     [15:0] cfg_subsys_id,
  input                      [7:0] cfg_rev_id,
  input                     [15:0] cfg_subsys_vend_id
);
  
  pci_exp_usrapp_rx # (
    .AXISTEN_IF_CC_ALIGNMENT_MODE(AXISTEN_IF_CC_ALIGNMENT_MODE),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE(AXISTEN_IF_CQ_ALIGNMENT_MODE),
    .AXISTEN_IF_RC_ALIGNMENT_MODE(AXISTEN_IF_RC_ALIGNMENT_MODE),
    .AXISTEN_IF_RQ_ALIGNMENT_MODE(AXISTEN_IF_RQ_ALIGNMENT_MODE),
    .AXISTEN_IF_RC_PARITY_CHECK(AXISTEN_IF_RC_PARITY_CHECK),
    .AXISTEN_IF_CQ_PARITY_CHECK(AXISTEN_IF_CQ_PARITY_CHECK),
    .C_DATA_WIDTH(C_DATA_WIDTH)
  ) rx_usrapp (
    .m_axis_cq_tdata(m_axis_cq_tdata),
    .m_axis_cq_tlast(m_axis_cq_tlast),
    .m_axis_cq_tvalid(m_axis_cq_tvalid),
    .m_axis_cq_tuser(m_axis_cq_tuser),
    .m_axis_cq_tkeep(m_axis_cq_tkeep),
    .pcie_cq_np_req_count(pcie_cq_np_req_count),

    .m_axis_cq_tready(m_axis_cq_tready),
    .m_axis_rc_tdata(m_axis_rc_tdata),
    .m_axis_rc_tlast(m_axis_rc_tlast),
    .m_axis_rc_tvalid(m_axis_rc_tvalid),
    .m_axis_rc_tuser(m_axis_rc_tuser),
    .m_axis_rc_tkeep(m_axis_rc_tkeep),
    .m_axis_rc_tready(m_axis_rc_tready),
    .pcie_cq_np_req(pcie_cq_np_req),

    .user_clk(user_clk),
    .user_reset(user_reset),
    .user_lnk_up(user_lnk_up)
  );

  // Tx User Application Interface
  pci_exp_usrapp_tx # (
    .LINK_CAP_MAX_LINK_WIDTH(LINK_CAP_MAX_LINK_WIDTH),
    .LINK_CAP_MAX_LINK_SPEED(LINK_CAP_MAX_LINK_SPEED),
    .EP_DEV_ID(EP_DEV_ID),
    .C_DATA_WIDTH(C_DATA_WIDTH),
    .AXISTEN_IF_RQ_PARITY_CHECK(AXISTEN_IF_RQ_PARITY_CHECK),
    .AXISTEN_IF_CC_PARITY_CHECK(AXISTEN_IF_CC_PARITY_CHECK),
    .AXISTEN_IF_CC_ALIGNMENT_MODE(AXISTEN_IF_CC_ALIGNMENT_MODE),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE(AXISTEN_IF_CQ_ALIGNMENT_MODE),
    .AXISTEN_IF_RC_ALIGNMENT_MODE(AXISTEN_IF_RC_ALIGNMENT_MODE),
    .AXISTEN_IF_RQ_ALIGNMENT_MODE(AXISTEN_IF_RQ_ALIGNMENT_MODE),
    .DEV_CAP_MAX_PAYLOAD_SUPPORTED(PF0_DEV_CAP_MAX_PAYLOAD_SIZE)
  ) tx_usrapp (
    .s_axis_rq_tlast  (s_axis_rq_tlast),
    .s_axis_rq_tdata  (s_axis_rq_tdata),
    .s_axis_rq_tuser  (s_axis_rq_tuser),
    .s_axis_rq_tkeep  (s_axis_rq_tkeep),
    .s_axis_rq_tready (s_axis_rq_tready),
    .s_axis_rq_tvalid (s_axis_rq_tvalid),
    .s_axis_cc_tdata  (s_axis_cc_tdata),
    .s_axis_cc_tuser  (s_axis_cc_tuser),
    .s_axis_cc_tlast  (s_axis_cc_tlast),
    .s_axis_cc_tkeep  (s_axis_cc_tkeep),
    .s_axis_cc_tvalid (s_axis_cc_tvalid),
    .s_axis_cc_tready (s_axis_cc_tready),
    .pcie_rq_seq_num  (pcie_rq_seq_num),
    .pcie_rq_seq_num_vld(pcie_rq_seq_num_vld),
    .pcie_rq_tag      (pcie_rq_tag),
    .pcie_rq_tag_vld  (pcie_rq_tag_vld),
    .pcie_tfc_nph_av  (pcie_tfc_nph_av),
    .pcie_tfc_npd_av  (pcie_tfc_npd_av),
    .speed_change_done_n(),

    .reset(user_reset),
    .user_clk(user_clk),
    .user_lnk_up(user_lnk_up)
  );

  // Cfg UsrApp

  pci_exp_usrapp_cfg cfg_usrapp (

 .user_clk(user_clk),
 .user_reset(user_reset),
  //--------------------------------------------//
  // 4. Configuration (CFG) Interface           //
  //--------------------------------------------//
  // EP and RP                                  //
  //--------------------------------------------//
 .cfg_vf_status(cfg_vf_status),
 .cfg_max_payload (cfg_max_payload),
 .cfg_current_speed(cfg_current_speed),
 .cfg_phy_link_down(cfg_phy_link_down),
 .cfg_max_read_req(cfg_max_read_req),
 .cfg_vf_power_state(cfg_vf_power_state),
 .cfg_phy_link_status(cfg_phy_link_status),
 .cfg_function_status(cfg_function_status),
 .cfg_link_power_state(cfg_link_power_state),
 .cfg_negotiated_width(cfg_negotiated_width),
 .cfg_function_power_state(cfg_function_power_state),


  // Error Reporting Interface
 .cfg_err_cor_out(cfg_err_cor_out),
 .cfg_err_fatal_out(cfg_err_fatal_out),
 .cfg_err_nonfatal_out(cfg_err_nonfatal_out),

 .cfg_ltr_enable (1'b0),
 .cfg_ltssm_state(cfg_ltssm_state),
 .cfg_rcb_status (cfg_rcb_status),
 .cfg_obff_enable(cfg_obff_enable),
 .cfg_pl_status_change(cfg_pl_status_change),
 .cfg_dpa_substate_change(cfg_dpa_substate_change),

 .cfg_tph_st_mode(cfg_tph_st_mode),
 .cfg_vf_tph_st_mode(cfg_vf_tph_st_mode),
 .cfg_tph_requester_enable(cfg_tph_requester_enable),
 .cfg_vf_tph_requester_enable(cfg_vf_tph_requester_enable),

  // Management Interface
 .cfg_mgmt_addr (cfg_mgmt_addr),
 .cfg_mgmt_write(cfg_mgmt_write),
 .cfg_mgmt_write_data (cfg_mgmt_write_data),
 .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),

 .cfg_mgmt_read(cfg_mgmt_read),
 .cfg_mgmt_read_data(cfg_mgmt_read_data),
 .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),
 .cfg_mgmt_type1_cfg_reg_access(cfg_mgmt_type1_cfg_reg_access),

 .cfg_msg_received(cfg_msg_received),
 .cfg_msg_received_data(cfg_msg_received_data),
 .cfg_msg_received_type(cfg_msg_received_type),

 .cfg_msg_transmit(cfg_msg_transmit),
 .cfg_msg_transmit_type(cfg_msg_transmit_type),
 .cfg_msg_transmit_data(cfg_msg_transmit_data),
 .cfg_msg_transmit_done(cfg_msg_transmit_done),

 .cfg_fc_ph  (cfg_fc_ph),
 .cfg_fc_pd  (cfg_fc_pd),
 .cfg_fc_nph (cfg_fc_nph),
 .cfg_fc_npd (cfg_fc_npd),
 .cfg_fc_cplh(cfg_fc_cplh),
 .cfg_fc_cpld(cfg_fc_cpld),
 .cfg_fc_sel (cfg_fc_sel),

 .cfg_per_func_status_data(cfg_per_func_status_data),
 .cfg_per_function_number (cfg_per_function_number),
 .cfg_per_func_status_control(cfg_per_func_status_control),
 .cfg_per_function_update_done(cfg_per_function_update_done),
 .cfg_per_function_output_request(cfg_per_function_output_request),

 .cfg_dsn(cfg_dsn),
 .cfg_err_cor_in(cfg_err_cor_in),
 .cfg_err_uncor_in(cfg_err_uncor_in),
 .cfg_power_state_change_ack(cfg_power_state_change_ack),
 .cfg_power_state_change_interrupt(cfg_power_state_change_interrupt),

 .cfg_flr_done(cfg_flr_done),
 .cfg_vf_flr_done(cfg_vf_flr_done),
 .cfg_flr_in_process(cfg_flr_in_process),
 .cfg_vf_flr_in_process(cfg_vf_flr_in_process),

 .cfg_ds_port_number(cfg_ds_port_number),
 .cfg_link_training_enable(cfg_link_training_enable),

 .cfg_hot_reset_out(cfg_hot_reset_out),
 .cfg_config_space_enable(cfg_config_space_enable),
 .cfg_req_pm_transition_l23_ready(cfg_req_pm_transition_l23_ready),

  //------------------------------------------------------------------------------------------//
  // RP Only                                                                                  //
  //------------------------------------------------------------------------------------------//
 .cfg_hot_reset_in(cfg_hot_reset_in),

 .cfg_ds_function_number(),
 .cfg_ds_bus_number(cfg_ds_bus_number),
 .cfg_ds_device_number(cfg_ds_device_number),

  // Interrupt Interface Signals
 .cfg_interrupt_int(cfg_interrupt_int),
 .cfg_interrupt_sent(cfg_interrupt_sent),
 .cfg_interrupt_pending(cfg_interrupt_pending)

  );

  // Common UsrApp
  pci_exp_usrapp_com com_usrapp();
  
endmodule
