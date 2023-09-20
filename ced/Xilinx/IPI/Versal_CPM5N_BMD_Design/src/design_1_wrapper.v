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

`timescale 1 ps / 1 ps

module design_1_wrapper
   (gt_refclk0_0_clk_n,
    gt_refclk0_0_clk_p,
    PCIE0_GT_0_grx_n,
    PCIE0_GT_0_grx_p,
    PCIE0_GT_0_gtx_n,
    PCIE0_GT_0_gtx_p
   );
   parameter C_DATA_WIDTH = 1024; // RX/TX interface data width
   parameter KEEP_WIDTH = C_DATA_WIDTH / 32;
   parameter AXI4_CQ_TUSER_WIDTH = 465;
   parameter AXI4_CC_TUSER_WIDTH = 165;
   parameter AXI4_RQ_TUSER_WIDTH = 373;
   parameter AXI4_RC_TUSER_WIDTH = 337;

  input gt_refclk0_0_clk_n;
  input gt_refclk0_0_clk_p;
  input [15:0]PCIE0_GT_0_grx_n;
  input [15:0]PCIE0_GT_0_grx_p;
  output [15:0]PCIE0_GT_0_gtx_n;
  output [15:0]PCIE0_GT_0_gtx_p;

  wire gt_refclk0_0_clk_n;
  wire gt_refclk0_0_clk_p;
  wire [15:0]PCIE0_GT_0_grx_n;
  wire [15:0]PCIE0_GT_0_grx_p;
  wire [15:0]PCIE0_GT_0_gtx_n;
  wire [15:0]PCIE0_GT_0_gtx_p;
  wire [C_DATA_WIDTH-1:0]pcie0_m_axis_cq_0_tdata;
  wire [KEEP_WIDTH-1:0]pcie0_m_axis_cq_0_tkeep;
  wire pcie0_m_axis_cq_0_tlast;
  wire pcie0_m_axis_cq_0_tready;
  wire [AXI4_CQ_TUSER_WIDTH-1:0]pcie0_m_axis_cq_0_tuser;
  wire pcie0_m_axis_cq_0_tvalid;
  wire [C_DATA_WIDTH-1:0]pcie0_m_axis_rc_0_tdata;
  wire [KEEP_WIDTH-1:0]pcie0_m_axis_rc_0_tkeep;
  wire pcie0_m_axis_rc_0_tlast;
  wire pcie0_m_axis_rc_0_tready;
  wire [AXI4_RC_TUSER_WIDTH-1:0]pcie0_m_axis_rc_0_tuser;
  wire pcie0_m_axis_rc_0_tvalid;
  wire pcie0_cfg_control_0_err_cor_in;
  wire pcie0_cfg_control_0_err_uncor_in;
  wire [3:0]pcie0_cfg_control_0_flr_done = 4'h0;
  wire [3:0]pcie0_cfg_control_0_flr_in_process = 4'h0;
  wire [15:0] pcie0_cfg_control_0_flr_done_function_number;
  wire pcie0_cfg_control_0_hot_reset_in = 1'b0;
  wire pcie0_cfg_control_0_hot_reset_out;
  wire pcie0_cfg_control_0_power_state_change_ack;
  wire pcie0_cfg_control_0_power_state_change_interrupt;
  wire [15:0]pcie0_cfg_ext_0_function_number;
  wire [31:0]pcie0_cfg_ext_0_read_data = 32'h0;
  wire pcie0_cfg_ext_0_read_data_valid = 1'b0;
  wire pcie0_cfg_ext_0_read_received;
  wire [9:0]pcie0_cfg_ext_0_register_number;
  wire [3:0]pcie0_cfg_ext_0_write_byte_enable;
  wire [31:0]pcie0_cfg_ext_0_write_data;
  wire pcie0_cfg_ext_0_write_received;
  wire [3:0]pcie0_cfg_interrupt_0_intx_vector;
  wire [31:0]pcie0_cfg_interrupt_0_pending ='h0;
  wire [1:0] w_cfg_interrupt_0_pending;
  wire [31:0] w_pcie0_cfg_interrupt_0_pending;
  wire pcie0_cfg_interrupt_0_sent;
  wire [4:0]pcie0_cfg_msg_recd_0_recd_type;
  wire pcie0_cfg_msg_recd_0_recd;
  wire [7:0]pcie0_cfg_msg_recd_0_recd_data;
  wire pcie0_cfg_msg_tx_0_transmit;
  wire [31:0] pcie0_cfg_msg_tx_0_transmit_data;
  wire pcie0_cfg_msg_tx_0_transmit_done;
  wire [2:0] pcie0_cfg_msg_tx_0_transmit_type;
  wire [9:0]pcie0_cfg_mgmt_0_addr;
  wire [3:0]pcie0_cfg_mgmt_0_byte_en;
  wire [7:0]pcie0_cfg_mgmt_0_function_number;
  wire [31:0]pcie0_cfg_mgmt_0_read_data;
  wire pcie0_cfg_mgmt_0_read_en;
  wire pcie0_cfg_mgmt_0_read_write_done;
  wire pcie0_cfg_mgmt_0_debug_access;
  wire [31:0]pcie0_cfg_mgmt_0_write_data;
  wire pcie0_cfg_mgmt_0_write_en;
  wire [2:0]pcie0_cfg_status_0_cq_np_req;
  wire [7:0]pcie0_cfg_status_0_cq_np_req_count;
  wire [2:0]pcie0_cfg_status_0_current_speed;
  wire pcie0_cfg_status_0_err_cor_out;
  wire pcie0_cfg_status_0_err_fatal_out;
  wire pcie0_cfg_status_0_err_nonfatal_out;
  wire [11:0]pcie0_cfg_status_0_function_power_state;
  wire [15:0]pcie0_cfg_status_0_function_status;
  wire [1:0]pcie0_cfg_status_0_link_power_state;
  wire [5:0]pcie0_cfg_status_0_local_error_out;
  wire pcie0_cfg_status_0_local_error_valid;
  wire [5:0]pcie0_cfg_status_0_ltssm_state;
  wire [1:0]pcie0_cfg_status_0_max_payload;
  wire [2:0]pcie0_cfg_status_0_max_read_req;
  wire [2:0]pcie0_cfg_status_0_negotiated_width;
  wire pcie0_cfg_status_0_phy_link_down;
  wire [1:0]pcie0_cfg_status_0_phy_link_status;
  wire pcie0_cfg_status_0_pl_status_change;
  wire [3:0]pcie0_cfg_status_0_rcb_status;
  wire [7:0]pcie0_cfg_status_0_rq_seq_num0;
  wire [7:0]pcie0_cfg_status_0_rq_seq_num1;
  wire [7:0]pcie0_cfg_status_0_rq_seq_num2;
  wire [7:0]pcie0_cfg_status_0_rq_seq_num3;
  wire pcie0_cfg_status_0_rq_seq_num_vld0;
  wire pcie0_cfg_status_0_rq_seq_num_vld1;
  wire pcie0_cfg_status_0_rq_seq_num_vld2;
  wire pcie0_cfg_status_0_rq_seq_num_vld3;
  wire [19:0]pcie0_cfg_status_0_rq_tag0;
  wire [19:0]pcie0_cfg_status_0_rq_tag1;
  wire [7:0]pcie0_cfg_status_0_rq_tag_av;
  wire [1:0]pcie0_cfg_status_0_rq_tag_vld0;
  wire [1:0]pcie0_cfg_status_0_rq_tag_vld1;
  wire [1:0]pcie0_cfg_status_0_rx_pm_state;
  wire [3:0]pcie0_cfg_status_0_tph_requester_enable;
  wire [11:0]pcie0_cfg_status_0_tph_st_mode;
  wire [1:0]pcie0_cfg_status_0_tx_pm_state;
  wire [7:0]pcie0_transmit_fc_0_npd_av;
  wire [7:0]pcie0_transmit_fc_0_nph_av;
  wire [C_DATA_WIDTH-1:0]pcie0_s_axis_cc_0_tdata;
  wire [KEEP_WIDTH-1:0]pcie0_s_axis_cc_0_tkeep;
  wire pcie0_s_axis_cc_0_tlast;
  wire [3:0]pcie0_s_axis_cc_0_tready;
  wire [AXI4_CC_TUSER_WIDTH-1:0]pcie0_s_axis_cc_0_tuser;
  wire pcie0_s_axis_cc_0_tvalid;
  wire [C_DATA_WIDTH-1:0]pcie0_s_axis_rq_0_tdata;
  wire [KEEP_WIDTH-1:0]pcie0_s_axis_rq_0_tkeep;
  wire pcie0_s_axis_rq_0_tlast;
  wire [3:0]pcie0_s_axis_rq_0_tready;
  wire [AXI4_RQ_TUSER_WIDTH-1:0]pcie0_s_axis_rq_0_tuser;
  wire pcie0_s_axis_rq_0_tvalid;
  wire pcie0_user_clk_0;
  wire [1:0]pcie0_cfg_fc_npd_scale_0;
  wire [1:0]pcie0_cfg_fc_nph_scale_0;
  wire [1:0]pcie0_cfg_fc_pd_scale_0;
  wire [1:0]pcie0_cfg_fc_ph_scale_0;
  wire [3:0]pcie0_cfg_10b_tag_requester_enable_0;
  wire [3:0]pcie0_cfg_atomic_requester_enable_0;
  wire pcie0_cfg_ext_tag_enable_0;
  wire [1:0]pcie0_cfg_fc_cpld_scale_0;
  wire [1:0]pcie0_cfg_fc_cplh_scale_0;
  wire [2:0]pcie0_cfg_fc_sel_0;
  wire pcie0_cfg_fc_vc_sel_0 = 1'b0;
  wire [11:0]pcie0_cfg_fc_npd_0;
  wire [7:0]pcie0_cfg_fc_nph_0;
  wire [11:0]pcie0_cfg_fc_pd_0;
  wire [7:0]pcie0_cfg_fc_ph_0;
  wire [11:0]pcie0_cfg_fc_cpld_0;
  wire [7:0]pcie0_cfg_fc_cplh_0;
  wire pcie0_user_lnk_up_0 = (pcie0_cfg_status_0_function_status == 'h3) ? 1'b1 : 1'b0;
  wire pcie0_user_reset_0;

  wire [11:0] cpm5rclk0;

assign w_pcie0_cfg_interrupt_0_pending = pcie0_cfg_interrupt_0_pending | w_cfg_interrupt_0_pending;
 
  design_1 design_1_i (

    // Global Signals
    .cpm_bot_user_clk_0(pcie0_user_clk_0),

    .gt_refclk0_0_clk_n(gt_refclk0_0_clk_n),
    .gt_refclk0_0_clk_p(gt_refclk0_0_clk_p),

    .pcie0_user_reset_0(pcie0_user_reset_0),

    // GT Serial Lines
    .PCIE0_GT_0_grx_n(PCIE0_GT_0_grx_n),
    .PCIE0_GT_0_grx_p(PCIE0_GT_0_grx_p),
    .PCIE0_GT_0_gtx_n(PCIE0_GT_0_gtx_n),
    .PCIE0_GT_0_gtx_p(PCIE0_GT_0_gtx_p),

    // AXIST
    .pcie0_m_axis_cq_0_tdata(pcie0_m_axis_cq_0_tdata),
    .pcie0_m_axis_cq_0_tkeep(pcie0_m_axis_cq_0_tkeep),
    .pcie0_m_axis_cq_0_tlast(pcie0_m_axis_cq_0_tlast),
    .pcie0_m_axis_cq_0_tready(pcie0_m_axis_cq_0_tready),
    .pcie0_m_axis_cq_0_tuser(pcie0_m_axis_cq_0_tuser),
    .pcie0_m_axis_cq_0_tvalid(pcie0_m_axis_cq_0_tvalid),

    .pcie0_m_axis_rc_0_tdata(pcie0_m_axis_rc_0_tdata),
    .pcie0_m_axis_rc_0_tkeep(pcie0_m_axis_rc_0_tkeep),
    .pcie0_m_axis_rc_0_tlast(pcie0_m_axis_rc_0_tlast),
    .pcie0_m_axis_rc_0_tready(pcie0_m_axis_rc_0_tready),
    .pcie0_m_axis_rc_0_tuser(pcie0_m_axis_rc_0_tuser),
    .pcie0_m_axis_rc_0_tvalid(pcie0_m_axis_rc_0_tvalid),

    .pcie0_s_axis_cc_0_tdata(pcie0_s_axis_cc_0_tdata),
    .pcie0_s_axis_cc_0_tkeep(pcie0_s_axis_cc_0_tkeep),
    .pcie0_s_axis_cc_0_tlast(pcie0_s_axis_cc_0_tlast),
    .pcie0_s_axis_cc_0_tready(pcie0_s_axis_cc_0_tready),
    .pcie0_s_axis_cc_0_tuser(pcie0_s_axis_cc_0_tuser),
    .pcie0_s_axis_cc_0_tvalid(pcie0_s_axis_cc_0_tvalid),

    .pcie0_s_axis_rq_0_tdata(pcie0_s_axis_rq_0_tdata),
    .pcie0_s_axis_rq_0_tkeep(pcie0_s_axis_rq_0_tkeep),
    .pcie0_s_axis_rq_0_tlast(pcie0_s_axis_rq_0_tlast),
    .pcie0_s_axis_rq_0_tready(pcie0_s_axis_rq_0_tready),
    .pcie0_s_axis_rq_0_tuser(pcie0_s_axis_rq_0_tuser),
    .pcie0_s_axis_rq_0_tvalid(pcie0_s_axis_rq_0_tvalid),

    // PCIe CFG ERR
    .pcie0_cfg_control_0_err_cor_in(pcie0_cfg_control_0_err_cor_in),
    .pcie0_cfg_control_0_err_uncor_in(pcie0_cfg_control_0_err_uncor_in),

    // PCIe CFG FLR - Need conversion for more functions on PF and VFs. This is temporary hack
    // Hack: Convert PF one hot done signal to 'valid' and 'function number' mechanism.
    .pcie0_cfg_control_0_flr_done(|pcie0_cfg_control_0_flr_done),
    //.pcie0_cfg_control_0_flr_in_process(pcie0_cfg_control_0_flr_in_process),
    .pcie0_cfg_control_0_flr_done_function_number(pcie0_cfg_control_0_flr_done[3]? 'h3 :
                                                  pcie0_cfg_control_0_flr_done[2]? 'h2 :
                                                  pcie0_cfg_control_0_flr_done[1]? 'h1 : 'h0),

    // PCIe Hot Reset
    .pcie0_cfg_control_0_hot_reset_in(pcie0_cfg_control_0_hot_reset_in), // Tie Off
    .pcie0_cfg_control_0_hot_reset_out(pcie0_cfg_control_0_hot_reset_out),

    // PCIe CFG CTRL
    .pcie0_cfg_control_0_per_function_number('h0),
    .pcie0_cfg_control_0_per_function_req(1'b0),

    // PCIe Power State Change
    .pcie0_cfg_control_0_power_state_change_ack(pcie0_cfg_control_0_power_state_change_ack),
    .pcie0_cfg_control_0_power_state_change_interrupt(pcie0_cfg_control_0_power_state_change_interrupt),

    // PCIe CFG Ext
    // Tie-Off for now. If enabled, we can swap it out with VSEC-NULL
    .pcie0_cfg_ext_0_function_number(pcie0_cfg_ext_0_function_number),
    .pcie0_cfg_ext_0_read_data(pcie0_cfg_ext_0_read_data),
    .pcie0_cfg_ext_0_read_data_valid(pcie0_cfg_ext_0_read_data_valid),
    .pcie0_cfg_ext_0_read_received(pcie0_cfg_ext_0_read_received),
    .pcie0_cfg_ext_0_register_number(pcie0_cfg_ext_0_register_number),
    .pcie0_cfg_ext_0_write_byte_enable(pcie0_cfg_ext_0_write_byte_enable),
    .pcie0_cfg_ext_0_write_data(pcie0_cfg_ext_0_write_data),
    .pcie0_cfg_ext_0_write_received(pcie0_cfg_ext_0_write_received),

    // PCIe INTx
    .pcie0_cfg_interrupt_0_intx_vector(pcie0_cfg_interrupt_0_intx_vector),
    //.pcie0_cfg_interrupt_0_pending(pcie0_cfg_interrupt_0_pending),
    .pcie0_cfg_interrupt_0_pending(w_pcie0_cfg_interrupt_0_pending),
    .pcie0_cfg_interrupt_0_sent(pcie0_cfg_interrupt_0_sent),

    // PCIe CFG MSG
    .pcie0_cfg_msg_recd_0_recd(pcie0_cfg_msg_recd_0_recd),
    .pcie0_cfg_msg_recd_0_recd_data(pcie0_cfg_msg_recd_0_recd_data),
    .pcie0_cfg_msg_recd_0_recd_type(pcie0_cfg_msg_recd_0_recd_type),

    .pcie0_cfg_msg_tx_0_transmit (pcie0_cfg_msg_tx_0_transmit),
    .pcie0_cfg_msg_tx_0_transmit_data (pcie0_cfg_msg_tx_0_transmit_data),
    .pcie0_cfg_msg_tx_0_transmit_done (pcie0_cfg_msg_tx_0_transmit_done),
    .pcie0_cfg_msg_tx_0_transmit_type (pcie0_cfg_msg_tx_0_transmit_type),

    // PCIe CFG MGMT
    .pcie0_cfg_mgmt_0_addr(pcie0_cfg_mgmt_0_addr),
    .pcie0_cfg_mgmt_0_byte_en(pcie0_cfg_mgmt_0_byte_en),
    .pcie0_cfg_mgmt_0_debug_access(pcie0_cfg_mgmt_0_debug_access),
    .pcie0_cfg_mgmt_0_function_number('h0),
    .pcie0_cfg_mgmt_0_read_data(pcie0_cfg_mgmt_0_read_data),
    .pcie0_cfg_mgmt_0_read_en(pcie0_cfg_mgmt_0_read_en),
    .pcie0_cfg_mgmt_0_read_write_done(pcie0_cfg_mgmt_0_read_write_done),
    .pcie0_cfg_mgmt_0_write_data(pcie0_cfg_mgmt_0_write_data),
    .pcie0_cfg_mgmt_0_write_en(pcie0_cfg_mgmt_0_write_en),

    // PCIe CFG Status - Unused ports may be available but not instantiated.
    .pcie0_cfg_status_0_cq_np_req({2'b0, pcie0_cfg_status_0_cq_np_req[0]}),
    .pcie0_cfg_status_0_cq_np_req_count(pcie0_cfg_status_0_cq_np_req_count),
    .pcie0_cfg_status_0_current_speed(pcie0_cfg_status_0_current_speed),
    .pcie0_cfg_status_0_err_cor_out(pcie0_cfg_status_0_err_cor_out),
    .pcie0_cfg_status_0_err_fatal_out(pcie0_cfg_status_0_err_fatal_out),
    .pcie0_cfg_status_0_err_nonfatal_out(pcie0_cfg_status_0_err_nonfatal_out),
    .pcie0_cfg_status_0_function_power_state(pcie0_cfg_status_0_function_power_state[2:0]),
    .pcie0_cfg_status_0_function_status(pcie0_cfg_status_0_function_status[3:0]),
    .pcie0_cfg_status_0_link_power_state(pcie0_cfg_status_0_link_power_state),
    .pcie0_cfg_status_0_local_error_out(pcie0_cfg_status_0_local_error_out),
    .pcie0_cfg_status_0_local_error_valid(pcie0_cfg_status_0_local_error_valid),
    .pcie0_cfg_status_0_ltssm_state(pcie0_cfg_status_0_ltssm_state),
    .pcie0_cfg_status_0_max_payload(pcie0_cfg_status_0_max_payload),
    .pcie0_cfg_status_0_max_read_req(pcie0_cfg_status_0_max_read_req),
    .pcie0_cfg_status_0_negotiated_width(pcie0_cfg_status_0_negotiated_width),
    .pcie0_cfg_status_0_phy_link_down(pcie0_cfg_status_0_phy_link_down),
    .pcie0_cfg_status_0_phy_link_status(pcie0_cfg_status_0_phy_link_status),
    .pcie0_cfg_status_0_pl_status_change(pcie0_cfg_status_0_pl_status_change),
    .pcie0_cfg_status_0_rcb_status(pcie0_cfg_status_0_rcb_status),
    .pcie0_cfg_status_0_rq_seq_num0(pcie0_cfg_status_0_rq_seq_num0),
    .pcie0_cfg_status_0_rq_seq_num1(pcie0_cfg_status_0_rq_seq_num1),
    .pcie0_cfg_status_0_rq_seq_num2(pcie0_cfg_status_0_rq_seq_num2),
    .pcie0_cfg_status_0_rq_seq_num3(pcie0_cfg_status_0_rq_seq_num3),
    .pcie0_cfg_status_0_rq_seq_num_vld0(pcie0_cfg_status_0_rq_seq_num_vld0),
    .pcie0_cfg_status_0_rq_seq_num_vld1(pcie0_cfg_status_0_rq_seq_num_vld1),
    .pcie0_cfg_status_0_rq_seq_num_vld2(pcie0_cfg_status_0_rq_seq_num_vld2),
    .pcie0_cfg_status_0_rq_seq_num_vld3(pcie0_cfg_status_0_rq_seq_num_vld3),
    .pcie0_cfg_status_0_rq_tag0(pcie0_cfg_status_0_rq_tag0),
    .pcie0_cfg_status_0_rq_tag1(pcie0_cfg_status_0_rq_tag1),
    .pcie0_cfg_status_0_rq_tag_av(pcie0_cfg_status_0_rq_tag_av),
    .pcie0_cfg_status_0_rq_tag_vld0(pcie0_cfg_status_0_rq_tag_vld0),
    .pcie0_cfg_status_0_rq_tag_vld1(pcie0_cfg_status_0_rq_tag_vld1),
    .pcie0_cfg_status_0_rx_pm_state(pcie0_cfg_status_0_rx_pm_state),
  //.pcie0_cfg_status_0_tph_requester_enable(pcie0_cfg_status_0_tph_requester_enable),
  //.pcie0_cfg_status_0_tph_st_mode(pcie0_cfg_status_0_tph_st_mode),
    .pcie0_cfg_status_0_tx_pm_state(pcie0_cfg_status_0_tx_pm_state),
    .pcie0_cfg_status_0_10b_tag_requester_enable(pcie0_cfg_10b_tag_requester_enable_0),
    .pcie0_cfg_status_0_atomic_requester_enable(pcie0_cfg_atomic_requester_enable_0),
    .pcie0_cfg_status_0_ext_tag_enable(pcie0_cfg_ext_tag_enable_0),

    // PCIe Transmit FC
    .pcie0_transmit_fc_0_npd_av(pcie0_transmit_fc_0_npd_av),
    .pcie0_transmit_fc_0_nph_av(pcie0_transmit_fc_0_nph_av),

    // PCIe CFG FC
    .pcie0_cfg_fc_0_npd_scale(pcie0_cfg_fc_npd_scale_0),
    .pcie0_cfg_fc_0_nph_scale(pcie0_cfg_fc_nph_scale_0),
    .pcie0_cfg_fc_0_pd_scale(pcie0_cfg_fc_pd_scale_0),
    .pcie0_cfg_fc_0_ph_scale(pcie0_cfg_fc_ph_scale_0),
    .pcie0_cfg_fc_0_cpld_scale(pcie0_cfg_fc_cpld_scale_0),
    .pcie0_cfg_fc_0_cplh_scale(pcie0_cfg_fc_cplh_scale_0),
    .pcie0_cfg_fc_0_sel(pcie0_cfg_fc_sel_0),
    .pcie0_cfg_fc_0_vc_sel(pcie0_cfg_fc_vc_sel_0), // New - Tie off to 0
    .pcie0_cfg_fc_0_npd(pcie0_cfg_fc_npd_0),
    .pcie0_cfg_fc_0_nph(pcie0_cfg_fc_nph_0),
    .pcie0_cfg_fc_0_pd(pcie0_cfg_fc_pd_0),
    .pcie0_cfg_fc_0_ph(pcie0_cfg_fc_ph_0),
    .pcie0_cfg_fc_0_cpld(pcie0_cfg_fc_cpld_0),
    .pcie0_cfg_fc_0_cplh(pcie0_cfg_fc_cplh_0)

  );


//------------------------------------------------------------------------------------------------------------------//
//                                      BMD Example Design Top Level                                                //
//------------------------------------------------------------------------------------------------------------------//
  pcie_app_versal_bmd # (
    .C_DATA_WIDTH(1024),
  //.AXISTEN_IF_ENABLE_CLIENT_TAG (0),
  //.TAG_10B_SUPPORT_EN("FALSE"),
    .AXISTEN_IF_ENABLE_CLIENT_TAG (1)
   ,.TAG_10B_SUPPORT_EN("TRUE")
  ) pcie_app_versal_i (
    .user_clk  (pcie0_user_clk_0),
    .user_reset(pcie0_user_reset_0),
    .user_lnk_up(pcie0_user_lnk_up_0),
  //.sys_rst(ch0_phyready_0), //sys_rst_n_c

    //--------------------------------------------//
    //  AXI Interface                             //
    //--------------------------------------------//
    .s_axis_rq_tlast (pcie0_s_axis_rq_0_tlast),
    .s_axis_rq_tdata (pcie0_s_axis_rq_0_tdata),
    .s_axis_rq_tuser (pcie0_s_axis_rq_0_tuser),
    .s_axis_rq_tkeep (pcie0_s_axis_rq_0_tkeep),
    .s_axis_rq_tready(pcie0_s_axis_rq_0_tready),
    .s_axis_rq_tvalid(pcie0_s_axis_rq_0_tvalid),

    .m_axis_rc_tdata (pcie0_m_axis_rc_0_tdata),
    .m_axis_rc_tuser (pcie0_m_axis_rc_0_tuser),
    .m_axis_rc_tlast (pcie0_m_axis_rc_0_tlast),
    .m_axis_rc_tkeep (pcie0_m_axis_rc_0_tkeep),
    .m_axis_rc_tvalid(pcie0_m_axis_rc_0_tvalid),
    .m_axis_rc_tready(pcie0_m_axis_rc_0_tready),

    .m_axis_cq_tdata (pcie0_m_axis_cq_0_tdata),
    .m_axis_cq_tuser (pcie0_m_axis_cq_0_tuser),
    .m_axis_cq_tlast (pcie0_m_axis_cq_0_tlast),
    .m_axis_cq_tkeep (pcie0_m_axis_cq_0_tkeep),
    .m_axis_cq_tvalid(pcie0_m_axis_cq_0_tvalid),
    .m_axis_cq_tready(pcie0_m_axis_cq_0_tready),

    .s_axis_cc_tdata (pcie0_s_axis_cc_0_tdata),
    .s_axis_cc_tuser (pcie0_s_axis_cc_0_tuser),
    .s_axis_cc_tlast (pcie0_s_axis_cc_0_tlast),
    .s_axis_cc_tkeep (pcie0_s_axis_cc_0_tkeep),
    .s_axis_cc_tvalid(pcie0_s_axis_cc_0_tvalid),
    .s_axis_cc_tready(pcie0_s_axis_cc_0_tready),

    .pcie_rq_seq_num0(pcie0_cfg_status_0_rq_seq_num0[5:0]) ,
    .pcie_rq_seq_num_vld0(pcie0_cfg_status_0_rq_seq_num_vld0) ,
    .pcie_rq_seq_num1(pcie0_cfg_status_0_rq_seq_num1[5:0]) ,
    .pcie_rq_seq_num_vld1(pcie0_cfg_status_0_rq_seq_num_vld1) ,
    .pcie_rq_tag    (pcie0_cfg_status_0_rq_tag0[5:0]),
    .pcie_rq_tag_vld(pcie0_cfg_status_0_rq_tag_vld0[0]),
    .pcie_tfc_nph_av(pcie0_transmit_fc_0_nph_av[1:0]),
    .pcie_tfc_npd_av(pcie0_transmit_fc_0_npd_av[1:0]),
    .pcie_cq_np_req (pcie0_cfg_status_0_cq_np_req[0]),
    .pcie_cq_np_req_count(pcie0_cfg_status_0_cq_np_req_count),

    //--------------------------------------------------------------------------------//
    //  Configuration (CFG) Interface                                                 //
    //--------------------------------------------------------------------------------//

    //--------------------------------------------------------------------------------//
    // EP and RP                                                                      //
    //--------------------------------------------------------------------------------//
    .cfg_phy_link_down   (pcie0_cfg_status_0_phy_link_down),
    .cfg_negotiated_width(pcie0_cfg_status_0_negotiated_width),
    .cfg_current_speed   (pcie0_cfg_status_0_current_speed),
    .cfg_max_payload     (pcie0_cfg_status_0_max_payload),
    .cfg_max_read_req    (pcie0_cfg_status_0_max_read_req),
    .cfg_function_status (pcie0_cfg_status_0_function_status [7:0]),
    .cfg_function_power_state(pcie0_cfg_status_0_function_power_state [5:0]),
  //.cfg_vf_status       (cfg_vf_status), //need to add vf_decode
  //.cfg_vf_power_state  (cfg_vf_power_state),
    .cfg_link_power_state(pcie0_cfg_status_0_link_power_state),

    // Error Reporting Interface
    .cfg_err_cor_out  (pcie0_cfg_status_0_err_cor_out),
    .cfg_err_nonfatal_out(pcie0_cfg_status_0_err_nonfatal_out),
    .cfg_err_fatal_out(pcie0_cfg_status_0_err_fatal_out),
    .cfg_ltr_enable   (1'b0),
    .cfg_ltssm_state  (pcie0_cfg_status_0_ltssm_state),
    .cfg_rcb_status   (pcie0_cfg_status_0_rcb_status [1:0]),
  //.cfg_obff_enable  (cfg_obff_enable),
    .cfg_pl_status_change(pcie0_cfg_status_0_pl_status_change),


  //.cfg_tph_st_mode(cfg_tph_st_mode),
  //.cfg_vf_tph_st_mode(cfg_vf_tph_st_mode),
  //.cfg_tph_requester_enable(cfg_tph_requester_enable [1:0]),
  //.cfg_vf_tph_requester_enable(cfg_vf_tph_requester_enable),

    // Management Interface
    .cfg_mgmt_addr(pcie0_cfg_mgmt_0_addr),
    .cfg_mgmt_write(pcie0_cfg_mgmt_0_write_en),
    .cfg_mgmt_write_data(pcie0_cfg_mgmt_0_write_data),
    .cfg_mgmt_byte_enable(pcie0_cfg_mgmt_0_byte_en),
    .cfg_mgmt_read(pcie0_cfg_mgmt_0_read_en),
    .cfg_mgmt_read_data(pcie0_cfg_mgmt_0_read_data),
    .cfg_mgmt_read_write_done(pcie0_cfg_mgmt_0_read_write_done),
    .cfg_mgmt_type1_cfg_reg_access(pcie0_cfg_mgmt_0_debug_access),

    .cfg_msg_received(pcie0_cfg_msg_recd_0_recd),
    .cfg_msg_received_data(pcie0_cfg_msg_recd_0_recd_data),
    .cfg_msg_received_type(pcie0_cfg_msg_recd_0_recd_type),

    .cfg_msg_transmit(pcie0_cfg_msg_tx_0_transmit),
    .cfg_msg_transmit_type(pcie0_cfg_msg_tx_0_transmit_type),
    .cfg_msg_transmit_data(pcie0_cfg_msg_tx_0_transmit_data),
    .cfg_msg_transmit_done(pcie0_cfg_msg_tx_0_transmit_done),
    .cfg_10b_tag_requester_enable(pcie0_cfg_10b_tag_requester_enable_0),


    .cfg_fc_ph  (pcie0_cfg_fc_ph_0),
    .cfg_fc_pd  (pcie0_cfg_fc_pd_0),
    .cfg_fc_nph (pcie0_cfg_fc_nph_0),
    .cfg_fc_npd (pcie0_cfg_fc_npd_0),
    .cfg_fc_cplh(pcie0_cfg_fc_cplh_0),
    .cfg_fc_cpld(pcie0_cfg_fc_cpld_0),
    .cfg_fc_sel (pcie0_cfg_fc_sel_0),


    //.cfg_dsn(cfg_dsn), //VG- Register based
    .cfg_power_state_change_ack(pcie0_cfg_control_0_power_state_change_ack),
    .cfg_power_state_change_interrupt(pcie0_cfg_control_0_power_state_change_interrupt),
    .cfg_err_cor_in(pcie0_cfg_control_0_err_cor_in),
    .cfg_err_uncor_in(pcie0_cfg_control_0_err_uncor_in),

    .cfg_flr_in_process(pcie0_cfg_control_0_flr_in_process [1:0]),
    .cfg_flr_done(pcie0_cfg_control_0_flr_done[1:0]),
  /*.cfg_vf_flr_in_process(cfg_vf_flr_in_process),
    .cfg_vf_flr_done(cfg_vf_flr_done),
    .cfg_vf_flr_func_num(cfg_vf_flr_func_num), //VG Needs VF decode logic

    .cfg_link_training_enable(cfg_link_training_enable), //VG Register based

    .cfg_ds_port_number(cfg_ds_port_number),
    .cfg_hot_reset_in  (cfg_hot_reset_out),
    .cfg_config_space_enable(cfg_config_space_enable),*/
  //.cfg_req_pm_transition_l23_ready(cfg_req_pm_transition_l23_ready), //VG to check

  // RP only
/*.cfg_hot_reset_out(cfg_hot_reset_in),

  .cfg_ds_bus_number(cfg_ds_bus_number),
  .cfg_ds_device_number(cfg_ds_device_number),
  .cfg_ds_function_number(),*/

    //-------------------------------------------------------------------------------------//
    // EP Only                                                                             //
    //-------------------------------------------------------------------------------------//

  /*.cfg_interrupt_msi_enable  (pcie0_cfg_msi_0_enable),
    .cfg_interrupt_msi_mmenable(pcie0_cfg_msi_0_mmenable[5:0]),
    .cfg_interrupt_msi_mask_update(pcie0_cfg_msi_0_mask_update),
    .cfg_interrupt_msi_data  (pcie0_cfg_msi_0_data),
    .cfg_interrupt_msi_select(pcie0_cfg_msi_0_select),
    .cfg_interrupt_msi_int   (pcie0_cfg_msi_0_int_vector),
    .cfg_interrupt_msi_pending_status (pcie0_cfg_msi_0_pending_status),
    .cfg_interrupt_msi_sent  (pcie0_cfg_msi_0_sent),
    .cfg_interrupt_msi_fail  (pcie0_cfg_msi_0_fail),
    .cfg_interrupt_msi_attr  (pcie0_cfg_msi_0_attr),
    .cfg_interrupt_msi_tph_present(pcie0_cfg_msi_0_tph_present),
    .cfg_interrupt_msi_tph_type   (pcie0_cfg_msi_0_tph_type),
    .cfg_interrupt_msi_tph_st_tag (pcie0_cfg_msi_0_tph_st_tag),
    .cfg_interrupt_msi_function_number(pcie0_cfg_msi_0_function_number),*/

    .cfg_interrupt_msi_vf_enable(6'b0),
    .cfg_interrupt_msix_enable  (4'b0),
    .cfg_interrupt_msix_int     (),

    .cfg_dpa_substate_change    (2'b0),

    // Interrupt Interface Signals
    .cfg_interrupt_int    (pcie0_cfg_interrupt_0_intx_vector),
    //.cfg_interrupt_pending(pcie0_cfg_interrupt_0_pending[1:0]),
    .cfg_interrupt_pending(w_cfg_interrupt_0_pending),
    .cfg_interrupt_sent   (pcie0_cfg_interrupt_0_sent)
);

/*
axis_ila_0 my_ila (
  .clk(pcie0_user_clk_0),                     // input wire clk
  .probe0(pcie0_cfg_mgmt_0_addr),             // input wire [9 : 0] probe0
  .probe1(pcie0_cfg_mgmt_0_byte_en),          // input wire [3 : 0] probe1
  .probe2(pcie0_cfg_mgmt_0_function_number),  // input wire [7 : 0] probe2
  .probe3(pcie0_cfg_mgmt_0_read_data),        // input wire [31 : 0] probe3
  .probe4(pcie0_cfg_mgmt_0_read_en),          // input wire [0 : 0] probe4
  .probe5(pcie0_cfg_mgmt_0_read_write_done),  // input wire [0 : 0] probe5
  .probe6(pcie0_cfg_mgmt_0_debug_access),     // input wire [0 : 0] probe6
  .probe7(pcie0_cfg_mgmt_0_write_data),       // input wire [31 : 0] probe7
  .probe8(pcie0_cfg_mgmt_0_write_en)          // input wire [0 : 0] probe8
);

axis_vio_0 my_vio (
  .probe_out0(pcie0_cfg_mgmt_0_addr),          // output wire [9 : 0] probe_out0
  .probe_out1(pcie0_cfg_mgmt_0_write_en),      // output wire [0 : 0] probe_out1
  .probe_out2(pcie0_cfg_mgmt_0_write_data),    // output wire [31 : 0] probe_out2
  .probe_out3(pcie0_cfg_mgmt_0_byte_en),       // output wire [3 : 0] probe_out3
  .probe_out4(pcie0_cfg_mgmt_0_read_en),       // output wire [0 : 0] probe_out4
  .probe_out5(pcie0_cfg_mgmt_0_debug_access),  // output wire [0 : 0] probe_out5
  .clk(pcie0_user_clk_0)                       // input wire clk
);
*/

reg [9:0] cpm5rclk0_reg0 = 0;
reg [9:0] cpm5rclk0_reg1 = 0;
reg [9:0] cpm5rclk0_reg2 = 0;
reg [9:0] cpm5rclk0_reg3 = 0;
reg [9:0] cpm5rclk0_reg4 = 0;
reg [9:0] cpm5rclk0_reg5 = 0;
reg [9:0] cpm5rclk0_reg6 = 0;
reg [9:0] cpm5rclk0_reg7 = 0;
reg [9:0] cpm5rclk0_reg8 = 0;
reg [9:0] cpm5rclk0_reg9 = 0;
reg [9:0] cpm5rclk0_reg10 = 0;
reg [9:0] cpm5rclk0_reg11 = 0;

/*
axis_ila_1 my_ila_2 (
  .clk(pcie0_user_clk_0),          // input wire clk
  .probe0(10'b0),    // input wire [9 : 0] probe0
  .probe1(10'b11_1111_1111),    // input wire [9 : 0] probe1
  .probe2(cpm5rclk0_reg2),    // input wire [9 : 0] probe2
  .probe3(cpm5rclk0_reg3),    // input wire [9 : 0] probe3
  .probe4(cpm5rclk0_reg4),    // input wire [9 : 0] probe4
  .probe5(cpm5rclk0_reg5),    // input wire [9 : 0] probe5
  .probe6(cpm5rclk0_reg6),    // input wire [9 : 0] probe6
  .probe7(cpm5rclk0_reg7),    // input wire [9 : 0] probe7
  .probe8(cpm5rclk0_reg8),    // input wire [9 : 0] probe8
  .probe9(cpm5rclk0_reg9),    // input wire [9 : 0] probe9
  .probe10(cpm5rclk0_reg10),  // input wire [9 : 0] probe10
  .probe11(cpm5rclk0_reg11)  // input wire [9 : 0] probe11
);
*/

//always @(posedge cpm5rclk0[0]) begin
//  if (pcie0_user_reset_0)
//    cpm5rclk0_reg0 <= 0;
//  else
//    cpm5rclk0_reg0  <= cpm5rclk0_reg0 + 1;
//end

//always @(posedge cpm5rclk0[1]) begin
//  if (pcie0_user_reset_0)
//    cpm5rclk0_reg1 <= 0;
//  else
//    cpm5rclk0_reg1  <= cpm5rclk0_reg1 + 1;
//end

always @(posedge cpm5rclk0[2]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg2 <= 0;
  else
    cpm5rclk0_reg2  <= cpm5rclk0_reg2 + 1;
end

always @(posedge cpm5rclk0[3]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg3 <= 0;
  else
    cpm5rclk0_reg3  <= cpm5rclk0_reg3 + 1;
end

always @(posedge cpm5rclk0[4]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg4 <= 0;
  else
    cpm5rclk0_reg4  <= cpm5rclk0_reg4 + 1;
end

always @(posedge cpm5rclk0[5]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg5 <= 0;
  else
    cpm5rclk0_reg5  <= cpm5rclk0_reg5 + 1;
end

always @(posedge cpm5rclk0[6]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg6 <= 0;
  else
    cpm5rclk0_reg6  <= cpm5rclk0_reg6 + 1;
end

always @(posedge cpm5rclk0[7]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg7 <= 0;
  else
    cpm5rclk0_reg7  <= cpm5rclk0_reg7 + 1;
end

always @(posedge cpm5rclk0[8]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg8 <= 0;
  else
    cpm5rclk0_reg8  <= cpm5rclk0_reg8 + 1;
end

always @(posedge cpm5rclk0[9]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg9 <= 0;
  else
    cpm5rclk0_reg9  <= cpm5rclk0_reg9 + 1;
end

always @(posedge cpm5rclk0[10]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg10 <= 0;
  else
    cpm5rclk0_reg10  <= cpm5rclk0_reg10 + 1;
end

always @(posedge cpm5rclk0[11]) begin
  if (pcie0_user_reset_0)
    cpm5rclk0_reg11 <= 0;
  else
    cpm5rclk0_reg11  <= cpm5rclk0_reg11 + 1;
end

endmodule

