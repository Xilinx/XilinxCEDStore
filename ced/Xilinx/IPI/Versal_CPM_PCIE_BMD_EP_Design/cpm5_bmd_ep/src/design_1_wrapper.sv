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
// File       : design_1_wrapper.sv
// Version    : 1.0 
//-----------------------------------------------------------------------------

`timescale 1 ps / 1 ps

module design_1_wrapper
   (gt_refclk1_0_clk_n,
    gt_refclk1_0_clk_p,
    PCIE1_GT_0_grx_n,
    PCIE1_GT_0_grx_p,
    PCIE1_GT_0_gtx_n,
    PCIE1_GT_0_gtx_p
   );
   parameter C_DATA_WIDTH                   = 512;
   parameter KEEP_WIDTH                     = C_DATA_WIDTH / 32;
   parameter AXI4_CQ_TUSER_WIDTH            = 232;
   parameter AXI4_CC_TUSER_WIDTH            = 81;
   parameter AXI4_RQ_TUSER_WIDTH            = 183;
   parameter AXI4_RC_TUSER_WIDTH            = 161;
   parameter AXISTEN_IF_RQ_STRADDLE         = 0;
   parameter AXISTEN_IF_RC_STRADDLE         = 0;
   parameter AXISTEN_IF_CQ_STRADDLE         = 0;
   parameter AXISTEN_IF_CC_STRADDLE         = 0;
   parameter AXISTEN_IF_ENABLE_CLIENT_TAG   = 1;
   parameter COMPLETER_10B_TAG              = "TRUE"; // When Completer 8-bit tag is used, this parameter can still be set to TRUE
                                                      // This parameter must be set to FALSE if AXISTEN_IF_CQ_POISON_DISCARD_DISABLE is TRUE

  input gt_refclk1_0_clk_n;
  input gt_refclk1_0_clk_p;
  input [7:0]PCIE1_GT_0_grx_n;
  input [7:0]PCIE1_GT_0_grx_p;
  output [7:0]PCIE1_GT_0_gtx_n;
  output [7:0]PCIE1_GT_0_gtx_p;
 

  wire gt_refclk1_0_clk_n;
  wire gt_refclk1_0_clk_p;
  wire [7:0]PCIE1_GT_0_grx_n;
  wire [7:0]PCIE1_GT_0_grx_p;
  wire [7:0]PCIE1_GT_0_gtx_n;
  wire [7:0]PCIE1_GT_0_gtx_p;
  wire [C_DATA_WIDTH-1:0]pcie1_m_axis_cq_0_tdata;
  wire [KEEP_WIDTH-1:0]pcie1_m_axis_cq_0_tkeep;
  wire pcie1_m_axis_cq_0_tlast;
  wire pcie1_m_axis_cq_0_tready;
  wire [AXI4_CQ_TUSER_WIDTH-1:0]pcie1_m_axis_cq_0_tuser;
  wire pcie1_m_axis_cq_0_tvalid;
(* mark_debug = "TRUE" *)  wire [C_DATA_WIDTH-1:0]pcie1_m_axis_rc_0_tdata;
(* mark_debug = "TRUE" *)  wire [KEEP_WIDTH-1:0]pcie1_m_axis_rc_0_tkeep;
(* mark_debug = "TRUE" *)  wire pcie1_m_axis_rc_0_tlast;
(* mark_debug = "TRUE" *)  wire pcie1_m_axis_rc_0_tready;
(* mark_debug = "TRUE" *)  wire [AXI4_RC_TUSER_WIDTH-1:0]pcie1_m_axis_rc_0_tuser;
(* mark_debug = "TRUE" *)  wire pcie1_m_axis_rc_0_tvalid;
  wire pcie1_cfg_control_0_err_cor_in;
  wire pcie1_cfg_control_0_err_uncor_in;
  wire [3:0]pcie1_cfg_control_0_flr_done;
  wire [3:0]pcie1_cfg_control_0_flr_in_process;
  wire pcie1_cfg_control_0_hot_reset_in;
  wire pcie1_cfg_control_0_hot_reset_out;
  wire pcie1_cfg_control_0_power_state_change_ack;
  wire pcie1_cfg_control_0_power_state_change_interrupt;
  wire [3:0]pcie1_cfg_interrupt_0_intx_vector;
  wire [3:0]pcie1_cfg_interrupt_0_pending;
  wire pcie1_cfg_interrupt_0_sent;
  wire [4:0]pcie1_cfg_msg_recd_0_recd_type;
  wire pcie1_cfg_msg_recd_0_recd;
  wire [7:0]pcie1_cfg_msg_recd_0_recd_data;
  wire [9:0]pcie1_cfg_mgmt_0_addr;
  wire [3:0]pcie1_cfg_mgmt_0_byte_en;
  wire [7:0]pcie1_cfg_mgmt_0_function_number;
  wire [31:0]pcie1_cfg_mgmt_0_read_data;
  wire pcie1_cfg_mgmt_0_read_en;
  wire pcie1_cfg_mgmt_0_read_write_done;
  wire pcie1_cfg_mgmt_0_debug_access;
  wire [31:0]pcie1_cfg_mgmt_0_write_data;
  wire pcie1_cfg_mgmt_0_write_en;
/* MSI is mutually exclusive with MSI-X
  wire [2:0]pcie1_cfg_msi_0_attr;
  wire [31:0]pcie1_cfg_msi_0_data;
  wire pcie1_cfg_msi_0_enable;
  wire pcie1_cfg_msi_0_fail;
  wire [15:0]pcie1_cfg_msi_0_function_number;
  wire [31:0]pcie1_cfg_msi_0_int_vector;
  wire pcie1_cfg_msi_0_mask_update;
  wire [5:0]pcie1_cfg_msi_0_mmenable;
  wire [31:0]pcie1_cfg_msi_0_pending_status;
  wire pcie1_cfg_msi_0_pending_status_data_enable;
  wire [3:0]pcie1_cfg_msi_0_pending_status_function_num;
  wire [3:0]pcie1_cfg_msi_0_select;
  wire pcie1_cfg_msi_0_sent;
  wire pcie1_cfg_msi_0_tph_present;
  wire [7:0]pcie1_cfg_msi_0_tph_st_tag;
  wire [1:0]pcie1_cfg_msi_0_tph_type;
*/
  wire pcie1_cfg_msi_0_enable        = 1'b0;
  wire [5:0]pcie1_cfg_msi_0_mmenable = 6'b0;
  wire pcie1_cfg_msi_0_mask_update   = 1'b0;
  wire [31:0]pcie1_cfg_msi_0_data    = 32'b0;
  wire pcie1_cfg_msi_0_sent          = 1'b0;
  wire pcie1_cfg_msi_0_fail          = 1'b0;
  wire [2:0]pcie1_cfg_msix_0_attr;
  wire [3:0]pcie1_cfg_msix_0_enable;
  wire pcie1_cfg_msix_0_fail;
  wire pcie1_cfg_msix_0_int_vector;
  wire [3:0]pcie1_cfg_msix_0_mask;
  wire pcie1_cfg_msix_0_sent;
  wire pcie1_cfg_msix_0_tph_present;
  wire [7:0]pcie1_cfg_msix_0_tph_st_tag;
  wire [1:0]pcie1_cfg_msix_0_tph_type;
  wire [1:0]pcie1_cfg_msix_0_vec_pending;
  wire pcie1_cfg_msix_0_vec_pending_status;
  wire [1:0]pcie1_cfg_status_0_cq_np_req;
  wire [5:0]pcie1_cfg_status_0_cq_np_req_count;
  wire [1:0]pcie1_cfg_status_0_current_speed;
  wire pcie1_cfg_status_0_err_cor_out;
  wire pcie1_cfg_status_0_err_fatal_out;
  wire pcie1_cfg_status_0_err_nonfatal_out;
  wire [11:0]pcie1_cfg_status_0_function_power_state;
  wire [15:0]pcie1_cfg_status_0_function_status;
  wire [1:0]pcie1_cfg_status_0_link_power_state;
  wire [4:0]pcie1_cfg_status_0_local_error_out;
  wire pcie1_cfg_status_0_local_error_valid;
  wire [5:0]pcie1_cfg_status_0_ltssm_state;
  wire [1:0]pcie1_cfg_status_0_max_payload;
  wire [2:0]pcie1_cfg_status_0_max_read_req;
  wire [2:0]pcie1_cfg_status_0_negotiated_width;
  wire pcie1_cfg_status_0_phy_link_down;
  wire [1:0]pcie1_cfg_status_0_phy_link_status;
  wire pcie1_cfg_status_0_pl_status_change;
  wire [3:0]pcie1_cfg_status_0_rcb_status;
  wire [5:0]pcie1_cfg_status_0_rq_seq_num0;
  wire [5:0]pcie1_cfg_status_0_rq_seq_num1;
  //wire [3:0]pcie1_cfg_status_0_rq_seq_num_vld;
  wire pcie1_cfg_status_0_rq_seq_num_vld0;
  wire pcie1_cfg_status_0_rq_seq_num_vld1;
  wire pcie1_cfg_status_0_rq_seq_num_vld2;
  wire pcie1_cfg_status_0_rq_seq_num_vld3;
  wire [9:0]pcie1_cfg_status_0_rq_tag0;
  wire [9:0]pcie1_cfg_status_0_rq_tag1;
  wire [3:0]pcie1_cfg_status_0_rq_tag_av;
  wire pcie1_cfg_status_0_rq_tag_vld0;
  wire pcie1_cfg_status_0_rq_tag_vld1;
  wire [1:0]pcie1_cfg_status_0_rx_pm_state;
  wire [3:0]pcie1_cfg_status_0_tph_requester_enable;
  wire [11:0]pcie1_cfg_status_0_tph_st_mode;
  wire [1:0]pcie1_cfg_status_0_tx_pm_state;
  wire [3:0]pcie1_transmit_fc_0_npd_av;
  wire [3:0]pcie1_transmit_fc_0_nph_av;
  wire [C_DATA_WIDTH-1:0]pcie1_s_axis_cc_0_tdata;
  wire [KEEP_WIDTH-1:0]pcie1_s_axis_cc_0_tkeep;
  wire pcie1_s_axis_cc_0_tlast;
  wire [3:0]pcie1_s_axis_cc_0_tready;
  wire [AXI4_CC_TUSER_WIDTH-1:0]pcie1_s_axis_cc_0_tuser;
  wire pcie1_s_axis_cc_0_tvalid;
(* mark_debug = "TRUE" *)  wire [C_DATA_WIDTH-1:0]pcie1_s_axis_rq_0_tdata;
(* mark_debug = "TRUE" *)  wire [KEEP_WIDTH-1:0]pcie1_s_axis_rq_0_tkeep;
(* mark_debug = "TRUE" *)  wire pcie1_s_axis_rq_0_tlast;
(* mark_debug = "TRUE" *)  wire [3:0]pcie1_s_axis_rq_0_tready;
(* mark_debug = "TRUE" *)  wire [AXI4_RQ_TUSER_WIDTH-1:0]pcie1_s_axis_rq_0_tuser;
(* mark_debug = "TRUE" *)  wire pcie1_s_axis_rq_0_tvalid;
  wire pcie1_user_clk_0;
  wire [7:0]pcie1_cfg_msix_function_number_0;
 // wire [31:0]pcie1_cfg_msix_mint_vector_0;
  wire [1:0]pcie1_cfg_fc_npd_scale_0;
  wire [1:0]pcie1_cfg_fc_nph_scale_0;
  wire [1:0]pcie1_cfg_fc_pd_scale_0;
  wire [1:0]pcie1_cfg_fc_ph_scale_0;
  wire [3:0]pcie1_cfg_10b_tag_requester_enable_0;
  wire [3:0]pcie1_cfg_atomic_requester_enable_0;
  wire pcie1_cfg_ext_tag_enable_0;
  wire [1:0]pcie1_cfg_fc_cpld_scale_0;
  wire [1:0]pcie1_cfg_fc_cplh_scale_0;
  wire [2:0]pcie1_cfg_fc_sel_0;
  wire pcie1_cfg_fc_vc_sel_0;
  wire [11:0]pcie1_cfg_fc_npd_0;
  wire [7:0]pcie1_cfg_fc_nph_0;
  wire [11:0]pcie1_cfg_fc_pd_0;
  wire [7:0]pcie1_cfg_fc_ph_0;
  wire [11:0]pcie1_cfg_fc_cpld_0;
  wire [7:0]pcie1_cfg_fc_cplh_0;
  wire pcie1_user_lnk_up_0;
  wire pcie1_user_reset_0;

  design_1 design_1_i
       (.gt_refclk1_0_clk_n(gt_refclk1_0_clk_n),
        .gt_refclk1_0_clk_p(gt_refclk1_0_clk_p),
        .PCIE1_GT_0_grx_n(PCIE1_GT_0_grx_n),
        .PCIE1_GT_0_grx_p(PCIE1_GT_0_grx_p),
        .PCIE1_GT_0_gtx_n(PCIE1_GT_0_gtx_n),
        .PCIE1_GT_0_gtx_p(PCIE1_GT_0_gtx_p),
        .pcie1_m_axis_cq_0_tdata(pcie1_m_axis_cq_0_tdata),
        .pcie1_m_axis_cq_0_tkeep(pcie1_m_axis_cq_0_tkeep),
        .pcie1_m_axis_cq_0_tlast(pcie1_m_axis_cq_0_tlast),
        .pcie1_m_axis_cq_0_tready(pcie1_m_axis_cq_0_tready),
        .pcie1_m_axis_cq_0_tuser(pcie1_m_axis_cq_0_tuser),
        .pcie1_m_axis_cq_0_tvalid(pcie1_m_axis_cq_0_tvalid),
        .pcie1_m_axis_rc_0_tdata(pcie1_m_axis_rc_0_tdata),
        .pcie1_m_axis_rc_0_tkeep(pcie1_m_axis_rc_0_tkeep),
        .pcie1_m_axis_rc_0_tlast(pcie1_m_axis_rc_0_tlast),
        .pcie1_m_axis_rc_0_tready(pcie1_m_axis_rc_0_tready),
        .pcie1_m_axis_rc_0_tuser(pcie1_m_axis_rc_0_tuser),
        .pcie1_m_axis_rc_0_tvalid(pcie1_m_axis_rc_0_tvalid),
        .pcie1_cfg_control_0_err_cor_in(pcie1_cfg_control_0_err_cor_in),
        .pcie1_cfg_control_0_err_uncor_in(pcie1_cfg_control_0_err_uncor_in),
        .pcie1_cfg_control_0_flr_done(pcie1_cfg_control_0_flr_done),
        .pcie1_cfg_control_0_flr_in_process(pcie1_cfg_control_0_flr_in_process),
        .pcie1_cfg_control_0_hot_reset_in(pcie1_cfg_control_0_hot_reset_in),
        .pcie1_cfg_control_0_hot_reset_out(pcie1_cfg_control_0_hot_reset_out),
        .pcie1_cfg_control_0_power_state_change_ack(pcie1_cfg_control_0_power_state_change_ack),
        .pcie1_cfg_control_0_power_state_change_interrupt(pcie1_cfg_control_0_power_state_change_interrupt),
        .pcie1_cfg_interrupt_0_intx_vector(pcie1_cfg_interrupt_0_intx_vector),
        .pcie1_cfg_interrupt_0_pending(pcie1_cfg_interrupt_0_pending),
        .pcie1_cfg_interrupt_0_sent(pcie1_cfg_interrupt_0_sent),
        .pcie1_cfg_msg_recd_0_recd(pcie1_cfg_msg_recd_0_recd),
        .pcie1_cfg_msg_recd_0_recd_data(pcie1_cfg_msg_recd_0_recd_data),
        .pcie1_cfg_mgmt_0_addr(pcie1_cfg_mgmt_0_addr),
        .pcie1_cfg_mgmt_0_byte_en(pcie1_cfg_mgmt_0_byte_en),
        .pcie1_cfg_mgmt_0_function_number(pcie1_cfg_mgmt_0_function_number),
        .pcie1_cfg_mgmt_0_read_data(pcie1_cfg_mgmt_0_read_data),
        .pcie1_cfg_mgmt_0_read_en(pcie1_cfg_mgmt_0_read_en),
        .pcie1_cfg_mgmt_0_read_write_done(pcie1_cfg_mgmt_0_read_write_done),
        .pcie1_cfg_mgmt_0_write_data(pcie1_cfg_mgmt_0_write_data),
        .pcie1_cfg_mgmt_0_write_en(pcie1_cfg_mgmt_0_write_en),
        .pcie1_cfg_msix_0_attr(pcie1_cfg_msix_0_attr),
        .pcie1_cfg_msix_0_enable(pcie1_cfg_msix_0_enable),
        .pcie1_cfg_msix_0_fail(pcie1_cfg_msix_0_fail),
        .pcie1_cfg_msix_0_int_vector(pcie1_cfg_msix_0_int_vector),
        .pcie1_cfg_msix_0_mask(pcie1_cfg_msix_0_mask),
        .pcie1_cfg_msix_0_sent(pcie1_cfg_msix_0_sent),
        .pcie1_cfg_msix_0_tph_present(pcie1_cfg_msix_0_tph_present),
        .pcie1_cfg_msix_0_tph_st_tag(pcie1_cfg_msix_0_tph_st_tag),
        .pcie1_cfg_msix_0_tph_type(pcie1_cfg_msix_0_tph_type),
        .pcie1_cfg_msix_0_vec_pending(pcie1_cfg_msix_0_vec_pending),
        .pcie1_cfg_msix_0_vec_pending_status(pcie1_cfg_msix_0_vec_pending_status),
/* MSI is mutually exclusive with MSI-X
        .pcie1_cfg_msi_0_attr(pcie1_cfg_msi_0_attr),
        .pcie1_cfg_msi_0_data(pcie1_cfg_msi_0_data),
        .pcie1_cfg_msi_0_enable(pcie1_cfg_msi_0_enable),
        .pcie1_cfg_msi_0_fail(pcie1_cfg_msi_0_fail),
        .pcie1_cfg_msi_0_function_number(pcie1_cfg_msi_0_function_number),
        .pcie1_cfg_msi_0_int_vector(pcie1_cfg_msi_0_int_vector),
        .pcie1_cfg_msi_0_mask_update(pcie1_cfg_msi_0_mask_update),
        .pcie1_cfg_msi_0_mmenable(pcie1_cfg_msi_0_mmenable),
        .pcie1_cfg_msi_0_pending_status(pcie1_cfg_msi_0_pending_status),
        .pcie1_cfg_msi_0_pending_status_data_enable(pcie1_cfg_msi_0_pending_status_data_enable),
        .pcie1_cfg_msi_0_pending_status_function_num(pcie1_cfg_msi_0_pending_status_function_num),
        .pcie1_cfg_msi_0_select(pcie1_cfg_msi_0_select),
        .pcie1_cfg_msi_0_sent(pcie1_cfg_msi_0_sent),
        .pcie1_cfg_msi_0_tph_present(pcie1_cfg_msi_0_tph_present),
        .pcie1_cfg_msi_0_tph_st_tag(pcie1_cfg_msi_0_tph_st_tag),
        .pcie1_cfg_msi_0_tph_type(pcie1_cfg_msi_0_tph_type),
*/
        .pcie1_cfg_status_0_cq_np_req({1'b0, pcie1_cfg_status_0_cq_np_req[0]}),
        .pcie1_cfg_status_0_cq_np_req_count(pcie1_cfg_status_0_cq_np_req_count),
        .pcie1_cfg_status_0_current_speed(pcie1_cfg_status_0_current_speed),
        .pcie1_cfg_status_0_err_cor_out(pcie1_cfg_status_0_err_cor_out),
        .pcie1_cfg_status_0_err_fatal_out(pcie1_cfg_status_0_err_fatal_out),
        .pcie1_cfg_status_0_err_nonfatal_out(pcie1_cfg_status_0_err_nonfatal_out),
        .pcie1_cfg_status_0_function_power_state(pcie1_cfg_status_0_function_power_state),
        .pcie1_cfg_status_0_function_status(pcie1_cfg_status_0_function_status),
        .pcie1_cfg_status_0_link_power_state(pcie1_cfg_status_0_link_power_state),
        .pcie1_cfg_status_0_local_error_out(pcie1_cfg_status_0_local_error_out),
        .pcie1_cfg_status_0_local_error_valid(pcie1_cfg_status_0_local_error_valid),
        .pcie1_cfg_status_0_ltssm_state(pcie1_cfg_status_0_ltssm_state),
        .pcie1_cfg_status_0_max_payload(pcie1_cfg_status_0_max_payload),
        .pcie1_cfg_status_0_max_read_req(pcie1_cfg_status_0_max_read_req),
        .pcie1_cfg_status_0_negotiated_width(pcie1_cfg_status_0_negotiated_width),
        .pcie1_cfg_status_0_phy_link_down(pcie1_cfg_status_0_phy_link_down),
        .pcie1_cfg_status_0_phy_link_status(pcie1_cfg_status_0_phy_link_status),
        .pcie1_cfg_status_0_pl_status_change(pcie1_cfg_status_0_pl_status_change),
        .pcie1_cfg_status_0_rcb_status(pcie1_cfg_status_0_rcb_status),
        .pcie1_cfg_status_0_rq_seq_num0(pcie1_cfg_status_0_rq_seq_num0),
        .pcie1_cfg_status_0_rq_seq_num1(pcie1_cfg_status_0_rq_seq_num1),
        //.pcie1_cfg_status_0_rq_seq_num_vld(pcie1_cfg_status_0_rq_seq_num_vld),
        .pcie1_cfg_status_0_rq_seq_num_vld0(pcie1_cfg_status_0_rq_seq_num_vld0),
        .pcie1_cfg_status_0_rq_seq_num_vld1(pcie1_cfg_status_0_rq_seq_num_vld1),
        .pcie1_cfg_status_0_rq_seq_num_vld2(pcie1_cfg_status_0_rq_seq_num_vld2),
        .pcie1_cfg_status_0_rq_seq_num_vld3(pcie1_cfg_status_0_rq_seq_num_vld3),
        .pcie1_cfg_status_0_rq_tag0(pcie1_cfg_status_0_rq_tag0),
        .pcie1_cfg_status_0_rq_tag1(pcie1_cfg_status_0_rq_tag1),
        .pcie1_cfg_status_0_rq_tag_av(pcie1_cfg_status_0_rq_tag_av),
        .pcie1_cfg_status_0_rq_tag_vld0(pcie1_cfg_status_0_rq_tag_vld0),
        .pcie1_cfg_status_0_rq_tag_vld1(pcie1_cfg_status_0_rq_tag_vld1),
        .pcie1_cfg_status_0_rx_pm_state(pcie1_cfg_status_0_rx_pm_state),
        .pcie1_cfg_status_0_tph_requester_enable(pcie1_cfg_status_0_tph_requester_enable),
        .pcie1_cfg_status_0_tph_st_mode(pcie1_cfg_status_0_tph_st_mode),
        .pcie1_cfg_status_0_tx_pm_state(pcie1_cfg_status_0_tx_pm_state),
        .pcie1_transmit_fc_0_npd_av(pcie1_transmit_fc_0_npd_av),
        .pcie1_transmit_fc_0_nph_av(pcie1_transmit_fc_0_nph_av),
        .pcie1_s_axis_cc_0_tdata(pcie1_s_axis_cc_0_tdata),
        .pcie1_s_axis_cc_0_tkeep(pcie1_s_axis_cc_0_tkeep),
        .pcie1_s_axis_cc_0_tlast(pcie1_s_axis_cc_0_tlast),
        .pcie1_s_axis_cc_0_tready(pcie1_s_axis_cc_0_tready),
        .pcie1_s_axis_cc_0_tuser(pcie1_s_axis_cc_0_tuser),
        .pcie1_s_axis_cc_0_tvalid(pcie1_s_axis_cc_0_tvalid),
        .pcie1_s_axis_rq_0_tdata(pcie1_s_axis_rq_0_tdata),
        .pcie1_s_axis_rq_0_tkeep(pcie1_s_axis_rq_0_tkeep),
        .pcie1_s_axis_rq_0_tlast(pcie1_s_axis_rq_0_tlast),
        .pcie1_s_axis_rq_0_tready(pcie1_s_axis_rq_0_tready),
        .pcie1_s_axis_rq_0_tuser(pcie1_s_axis_rq_0_tuser),
        .pcie1_s_axis_rq_0_tvalid(pcie1_s_axis_rq_0_tvalid),
        .pcie1_user_clk_0(pcie1_user_clk_0),
        .pcie1_cfg_msix_0_function_number(pcie1_cfg_msix_function_number_0),
        //.pcie1_cfg_msix_0_mint_vector(pcie1_cfg_msix_mint_vector_0),
        .pcie1_cfg_fc_0_npd_scale(pcie1_cfg_fc_npd_scale_0),
        .pcie1_cfg_fc_0_nph_scale(pcie1_cfg_fc_nph_scale_0),
        .pcie1_cfg_fc_0_pd_scale(pcie1_cfg_fc_pd_scale_0),
        .pcie1_cfg_fc_0_ph_scale(pcie1_cfg_fc_ph_scale_0),
        .pcie1_cfg_status_0_10b_tag_requester_enable(pcie1_cfg_10b_tag_requester_enable_0),
        .pcie1_cfg_status_0_atomic_requester_enable(pcie1_cfg_atomic_requester_enable_0),
        .pcie1_cfg_status_0_ext_tag_enable(pcie1_cfg_ext_tag_enable_0),
        .pcie1_cfg_fc_0_cpld_scale(pcie1_cfg_fc_cpld_scale_0),
        .pcie1_cfg_fc_0_cplh_scale(pcie1_cfg_fc_cplh_scale_0),
        .pcie1_cfg_fc_0_sel(pcie1_cfg_fc_sel_0),
        .pcie1_cfg_fc_0_vc_sel(pcie1_cfg_fc_vc_sel_0),	
	.pcie1_cfg_fc_0_npd(pcie1_cfg_fc_npd_0),
        .pcie1_cfg_fc_0_nph(pcie1_cfg_fc_nph_0),
        .pcie1_cfg_fc_0_pd(pcie1_cfg_fc_pd_0),
        .pcie1_cfg_fc_0_ph(pcie1_cfg_fc_ph_0),
        .pcie1_cfg_fc_0_cpld(pcie1_cfg_fc_cpld_0),
        .pcie1_cfg_fc_0_cplh(pcie1_cfg_fc_cplh_0),
	.cpm_irq0_0('d0),
	.cpm_irq1_0('d0),
        .pcie1_user_lnk_up_0(pcie1_user_lnk_up_0),
        .pcie1_user_reset_0(pcie1_user_reset_0));
        
                
        
//------------------------------------------------------------------------------------------------------------------//
//                                      BMD Example Design Top Level                                                //
//------------------------------------------------------------------------------------------------------------------//
  pcie_app_versal_bmd #(
    .C_DATA_WIDTH                                   ( C_DATA_WIDTH           ),
    .AXISTEN_IF_ENABLE_CLIENT_TAG                   ( AXISTEN_IF_ENABLE_CLIENT_TAG ),
    .AXISTEN_IF_RQ_STRADDLE                         ( AXISTEN_IF_RQ_STRADDLE ),
    .AXISTEN_IF_RC_STRADDLE                         ( AXISTEN_IF_RC_STRADDLE ),
    .AXISTEN_IF_CQ_STRADDLE                         ( AXISTEN_IF_CQ_STRADDLE ),
    .AXISTEN_IF_CC_STRADDLE                         ( AXISTEN_IF_CC_STRADDLE ),
    .AXI4_CQ_TUSER_WIDTH                            ( AXI4_CQ_TUSER_WIDTH    ),
    .AXI4_CC_TUSER_WIDTH                            ( AXI4_CC_TUSER_WIDTH    ),
    .AXI4_RQ_TUSER_WIDTH                            ( AXI4_RQ_TUSER_WIDTH    ),
    .AXI4_RC_TUSER_WIDTH                            ( AXI4_RC_TUSER_WIDTH    ),
    .COMPLETER_10B_TAG                              ( COMPLETER_10B_TAG      )
  ) pcie_app_versal_i (
    .user_clk                                       ( pcie1_user_clk_0    ),
    .user_reset                                     ( pcie1_user_reset_0  ),
    .user_lnk_up                                    ( pcie1_user_lnk_up_0 ),
    .sys_rst                                        ( 1'b1                ), //sys_rst_n_c

    
    
    //-------------------------------------------------------------------------------------//
    //  AXI Interface                                                                      //
    //-------------------------------------------------------------------------------------//

    .s_axis_rq_tlast                                ( pcie1_s_axis_rq_0_tlast  ),
    .s_axis_rq_tdata                                ( pcie1_s_axis_rq_0_tdata  ),
    .s_axis_rq_tuser                                ( pcie1_s_axis_rq_0_tuser  ),
    .s_axis_rq_tkeep                                ( pcie1_s_axis_rq_0_tkeep  ),
    .s_axis_rq_tready                               ( pcie1_s_axis_rq_0_tready ),
    .s_axis_rq_tvalid                               ( pcie1_s_axis_rq_0_tvalid ),

    .m_axis_rc_tdata                                ( pcie1_m_axis_rc_0_tdata  ),
    .m_axis_rc_tuser                                ( pcie1_m_axis_rc_0_tuser  ),
    .m_axis_rc_tlast                                ( pcie1_m_axis_rc_0_tlast  ),
    .m_axis_rc_tkeep                                ( pcie1_m_axis_rc_0_tkeep  ),
    .m_axis_rc_tvalid                               ( pcie1_m_axis_rc_0_tvalid ),
    .m_axis_rc_tready                               ( pcie1_m_axis_rc_0_tready ),

    .m_axis_cq_tdata                                ( pcie1_m_axis_cq_0_tdata  ),
    .m_axis_cq_tuser                                ( pcie1_m_axis_cq_0_tuser  ),
    .m_axis_cq_tlast                                ( pcie1_m_axis_cq_0_tlast  ),
    .m_axis_cq_tkeep                                ( pcie1_m_axis_cq_0_tkeep  ),
    .m_axis_cq_tvalid                               ( pcie1_m_axis_cq_0_tvalid ),
    .m_axis_cq_tready                               ( pcie1_m_axis_cq_0_tready ),

    .s_axis_cc_tdata                                ( pcie1_s_axis_cc_0_tdata  ),
    .s_axis_cc_tuser                                ( pcie1_s_axis_cc_0_tuser  ),
    .s_axis_cc_tlast                                ( pcie1_s_axis_cc_0_tlast  ),
    .s_axis_cc_tkeep                                ( pcie1_s_axis_cc_0_tkeep  ),
    .s_axis_cc_tvalid                               ( pcie1_s_axis_cc_0_tvalid ),
    .s_axis_cc_tready                               ( pcie1_s_axis_cc_0_tready ),


   
    .pcie_rq_seq_num0                               ( pcie1_cfg_status_0_rq_seq_num0     ),
    .pcie_rq_seq_num_vld0                           ( pcie1_cfg_status_0_rq_seq_num_vld0 ),
    .pcie_rq_seq_num1                               ( pcie1_cfg_status_0_rq_seq_num1     ),
    .pcie_rq_seq_num_vld1                           ( pcie1_cfg_status_0_rq_seq_num_vld1 ),
    .pcie_rq_tag                                    ( pcie1_cfg_status_0_rq_tag0         ),
    .pcie_rq_tag_vld                                ( pcie1_cfg_status_0_rq_tag_vld0     ),
    .pcie_tfc_nph_av                                ( pcie1_transmit_fc_0_nph_av[1:0]    ),
    .pcie_tfc_npd_av                                ( pcie1_transmit_fc_0_npd_av[1:0]    ),
    .pcie_cq_np_req                                 ( pcie1_cfg_status_0_cq_np_req[0]    ),
    .pcie_cq_np_req_count                           ( pcie1_cfg_status_0_cq_np_req_count ),
    //--------------------------------------------------------------------------------//
    //  Configuration (CFG) Interface                                                 //
    //--------------------------------------------------------------------------------//

    //--------------------------------------------------------------------------------//
    // EP and RP                                                                      //
    //--------------------------------------------------------------------------------//
    .cfg_phy_link_down                              ( pcie1_cfg_status_0_phy_link_down              ),
    .cfg_negotiated_width                           ( pcie1_cfg_status_0_negotiated_width           ),
    .cfg_current_speed                              ( pcie1_cfg_status_0_current_speed              ),
    .cfg_max_payload                                ( pcie1_cfg_status_0_max_payload                ),
    .cfg_max_read_req                               ( pcie1_cfg_status_0_max_read_req               ),
    .cfg_function_status                            ( pcie1_cfg_status_0_function_status [7:0]      ),
    .cfg_function_power_state                       ( pcie1_cfg_status_0_function_power_state [5:0] ),
    .cfg_vf_status                                  ( 'h0                                           ), //Needs VF decode
    .cfg_link_power_state                           ( pcie1_cfg_status_0_link_power_state           ),

    // Error Reporting Interface
    .cfg_err_cor_out                                ( pcie1_cfg_status_0_err_cor_out      ),
    .cfg_err_nonfatal_out                           ( pcie1_cfg_status_0_err_nonfatal_out ),
    .cfg_err_fatal_out                              ( pcie1_cfg_status_0_err_fatal_out    ),
    .cfg_ltr_enable                                 ( 1'b0                                ),
    .cfg_ltssm_state                                ( pcie1_cfg_status_0_ltssm_state      ),
    .cfg_rcb_status                                 ( pcie1_cfg_status_0_rcb_status [1:0] ),
//    .cfg_obff_enable                                ( cfg_obff_enable ),
    .cfg_pl_status_change                           ( pcie1_cfg_status_0_pl_status_change ),

    // Management Interface
    .cfg_mgmt_addr                                  ( pcie1_cfg_mgmt_0_addr            ),
    .cfg_mgmt_write                                 ( pcie1_cfg_mgmt_0_write_en        ),
    .cfg_mgmt_write_data                            ( pcie1_cfg_mgmt_0_write_data      ),
    .cfg_mgmt_byte_enable                           ( pcie1_cfg_mgmt_0_byte_en         ),
    .cfg_mgmt_read                                  ( pcie1_cfg_mgmt_0_read_en         ),
    .cfg_mgmt_read_data                             ( pcie1_cfg_mgmt_0_read_data       ),
    .cfg_mgmt_read_write_done                       ( pcie1_cfg_mgmt_0_read_write_done ),
    .cfg_mgmt_type1_cfg_reg_access                  ( pcie1_cfg_mgmt_0_debug_access    ),
    .cfg_msg_received                               ( pcie1_cfg_msg_recd_0_recd        ),
    .cfg_msg_received_data                          ( pcie1_cfg_msg_recd_0_recd_data   ),
    .cfg_msg_received_type                          ( pcie1_cfg_msg_recd_0_recd_type   ),
    .cfg_msg_transmit                               ( pcie1_cfg_msg_tx_0_transmit      ),
    .cfg_msg_transmit_type                          ( pcie1_cfg_msg_tx_0_transmit_type ),
    .cfg_msg_transmit_data                          ( pcie1_cfg_msg_tx_0_transmit_data ),
    .cfg_msg_transmit_done                          ( pcie1_cfg_msg_tx_0_transmit_done ),

    .cfg_fc_ph                                      ( pcie1_cfg_fc_ph_0   ),
    .cfg_fc_pd                                      ( pcie1_cfg_fc_pd_0   ),
    .cfg_fc_nph                                     ( pcie1_cfg_fc_nph_0  ),
    .cfg_fc_npd                                     ( pcie1_cfg_fc_npd_0  ),
    .cfg_fc_cplh                                    ( pcie1_cfg_fc_cplh_0 ),
    .cfg_fc_cpld                                    ( pcie1_cfg_fc_cpld_0 ),
    .cfg_fc_sel                                     ( pcie1_cfg_fc_sel_0  ),

//    .cfg_dsn                                        ( cfg_dsn ), // Register based
    .cfg_power_state_change_ack                     ( pcie1_cfg_control_0_power_state_change_ack       ),
    .cfg_power_state_change_interrupt               ( pcie1_cfg_control_0_power_state_change_interrupt ),
    .cfg_err_cor_in                                 ( pcie1_cfg_control_0_err_cor_in                   ),
    .cfg_err_uncor_in                               ( pcie1_cfg_control_0_err_uncor_in                 ),

    .cfg_flr_in_process                             ( pcie1_cfg_control_0_flr_in_process [1:0] ),
    .cfg_flr_done                                   ( pcie1_cfg_control_0_flr_done             ),
/*
    .cfg_vf_flr_in_process                          ( cfg_vf_flr_in_process ),
    .cfg_vf_flr_done                                ( cfg_vf_flr_done       ),
    .cfg_vf_flr_func_num                            ( cfg_vf_flr_func_num   ),
*/ //Needs VF decode
    .cfg_vf_flr_in_process                          ( 'h0 ),

/* // Register based
    .cfg_link_training_enable                       ( cfg_link_training_enable          ),
    .cfg_config_space_enable                        ( cfg_config_space_enable           ),
*/
    .cfg_hot_reset_in                               ( pcie1_cfg_control_0_hot_reset_out ),
//    .cfg_req_pm_transition_l23_ready                ( cfg_req_pm_transition_l23_ready   ),

  // RP only
    .cfg_hot_reset_out                              ( pcie1_cfg_control_0_hot_reset_in ),
/*
    .cfg_ds_bus_number                              ( cfg_ds_bus_number    ),
    .cfg_ds_device_number                           ( cfg_ds_device_number ),
    .cfg_ds_port_number                             ( cfg_ds_port_number   ),
    .cfg_ds_function_number                         ( ),
*/

    //-------------------------------------------------------------------------------------//
    // EP Only                                                                             //
    //-------------------------------------------------------------------------------------//

    .cfg_interrupt_msi_enable                       ( pcie1_cfg_msi_0_enable          ),
    .cfg_interrupt_msi_mmenable                     ( pcie1_cfg_msi_0_mmenable[5:0]   ),
    .cfg_interrupt_msi_mask_update                  ( pcie1_cfg_msi_0_mask_update     ),
    .cfg_interrupt_msi_data                         ( pcie1_cfg_msi_0_data            ),
    .cfg_interrupt_msi_select                       ( pcie1_cfg_msi_0_select          ),
    .cfg_interrupt_msi_int                          ( pcie1_cfg_msi_0_int_vector      ),
    .cfg_interrupt_msi_pending_status               ( pcie1_cfg_msi_0_pending_status  ),
    .cfg_interrupt_msi_sent                         ( pcie1_cfg_msi_0_sent            ),
    .cfg_interrupt_msi_fail                         ( pcie1_cfg_msi_0_fail            ),
    .cfg_interrupt_msi_attr                         ( pcie1_cfg_msi_0_attr            ),
    .cfg_interrupt_msi_tph_present                  ( pcie1_cfg_msi_0_tph_present     ),
    .cfg_interrupt_msi_tph_type                     ( pcie1_cfg_msi_0_tph_type        ),
    .cfg_interrupt_msi_tph_st_tag                   ( pcie1_cfg_msi_0_tph_st_tag      ),
    .cfg_interrupt_msi_function_number              ( pcie1_cfg_msi_0_function_number ),
    .cfg_interrupt_msi_vf_enable                    ( 6'b0                            ),
    .cfg_interrupt_msix_enable                      ( 4'b0                            ),
    .cfg_interrupt_msix_int                         ( ),
    .cfg_dpa_substate_change                        ( 2'b0                            ),
    // Interrupt Interface Signals
    .cfg_interrupt_int                              ( pcie1_cfg_interrupt_0_intx_vector ),
    .cfg_interrupt_pending                          ( pcie1_cfg_interrupt_0_pending     ),
    .cfg_interrupt_sent                             ( pcie1_cfg_interrupt_0_sent        )
);

endmodule
