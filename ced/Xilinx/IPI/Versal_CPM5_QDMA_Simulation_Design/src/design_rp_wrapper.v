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

module design_rp_wrapper
   (PCIE0_GT_0_grx_n,
    PCIE0_GT_0_grx_p,
    PCIE0_GT_0_gtx_n,
    PCIE0_GT_0_gtx_p,
    gt_refclk0_0_clk_n,
    gt_refclk0_0_clk_p,
    pcie0_cfg_control_0_err_cor_in,
    pcie0_cfg_control_0_err_uncor_in,
    pcie0_cfg_control_0_flr_done,
    pcie0_cfg_control_0_flr_done_function_number,
    pcie0_cfg_control_0_flr_in_process,
    pcie0_cfg_control_0_hot_reset_in,
    pcie0_cfg_control_0_hot_reset_out,
    pcie0_cfg_control_0_per_function_number,
    pcie0_cfg_control_0_per_function_req,
    pcie0_cfg_control_0_power_state_change_ack,
    pcie0_cfg_control_0_power_state_change_interrupt,
    pcie0_cfg_ext_0_function_number,
    pcie0_cfg_ext_0_read_data,
    pcie0_cfg_ext_0_read_data_valid,
    pcie0_cfg_ext_0_read_received,
    pcie0_cfg_ext_0_register_number,
    pcie0_cfg_ext_0_write_byte_enable,
    pcie0_cfg_ext_0_write_data,
    pcie0_cfg_ext_0_write_received,
    pcie0_cfg_fc_0_cpld,
    pcie0_cfg_fc_0_cpld_scale,
    pcie0_cfg_fc_0_cplh,
    pcie0_cfg_fc_0_cplh_scale,
    pcie0_cfg_fc_0_npd,
    pcie0_cfg_fc_0_npd_scale,
    pcie0_cfg_fc_0_nph,
    pcie0_cfg_fc_0_nph_scale,
    pcie0_cfg_fc_0_pd,
    pcie0_cfg_fc_0_pd_scale,
    pcie0_cfg_fc_0_ph,
    pcie0_cfg_fc_0_ph_scale,
    pcie0_cfg_fc_0_sel,
    pcie0_cfg_fc_0_vc_sel,
    pcie0_cfg_interrupt_0_intx_vector,
    pcie0_cfg_interrupt_0_pending,
    pcie0_cfg_interrupt_0_sent,
    pcie0_cfg_mgmt_0_addr,
    pcie0_cfg_mgmt_0_byte_en,
    pcie0_cfg_mgmt_0_debug_access,
    pcie0_cfg_mgmt_0_function_number,
    pcie0_cfg_mgmt_0_read_data,
    pcie0_cfg_mgmt_0_read_en,
    pcie0_cfg_mgmt_0_read_write_done,
    pcie0_cfg_mgmt_0_write_data,
    pcie0_cfg_mgmt_0_write_en,
    pcie0_cfg_msg_recd_0_recd,
    pcie0_cfg_msg_recd_0_recd_data,
    pcie0_cfg_msg_recd_0_recd_type,
    pcie0_cfg_msg_tx_0_transmit,
    pcie0_cfg_msg_tx_0_transmit_data,
    pcie0_cfg_msg_tx_0_transmit_done,
    pcie0_cfg_msg_tx_0_transmit_type,
    pcie0_cfg_status_0_10b_tag_requester_enable,
    pcie0_cfg_status_0_atomic_requester_enable,
    pcie0_cfg_status_0_bus_number,
    pcie0_cfg_status_0_cq_np_req,
    pcie0_cfg_status_0_cq_np_req_count,
    pcie0_cfg_status_0_current_speed,
    pcie0_cfg_status_0_err_cor_out,
    pcie0_cfg_status_0_err_fatal_out,
    pcie0_cfg_status_0_err_nonfatal_out,
    pcie0_cfg_status_0_ext_tag_enable,
    pcie0_cfg_status_0_function_power_state,
    pcie0_cfg_status_0_function_status,
    pcie0_cfg_status_0_link_power_state,
    pcie0_cfg_status_0_local_error_out,
    pcie0_cfg_status_0_local_error_valid,
    pcie0_cfg_status_0_ltssm_state,
    pcie0_cfg_status_0_max_payload,
    pcie0_cfg_status_0_max_read_req,
    pcie0_cfg_status_0_negotiated_width,
    pcie0_cfg_status_0_per_function_out,
    pcie0_cfg_status_0_per_function_vld,
    pcie0_cfg_status_0_phy_link_down,
    pcie0_cfg_status_0_phy_link_status,
    pcie0_cfg_status_0_pl_status_change,
    pcie0_cfg_status_0_rcb_status,
    pcie0_cfg_status_0_rq_seq_num0,
    pcie0_cfg_status_0_rq_seq_num1,
    pcie0_cfg_status_0_rq_seq_num2,
    pcie0_cfg_status_0_rq_seq_num3,
    pcie0_cfg_status_0_rq_seq_num_vld0,
    pcie0_cfg_status_0_rq_seq_num_vld1,
    pcie0_cfg_status_0_rq_seq_num_vld2,
    pcie0_cfg_status_0_rq_seq_num_vld3,
    pcie0_cfg_status_0_rq_tag0,
    pcie0_cfg_status_0_rq_tag1,
    pcie0_cfg_status_0_rq_tag_av,
    pcie0_cfg_status_0_rq_tag_vld0,
    pcie0_cfg_status_0_rq_tag_vld1,
    pcie0_cfg_status_0_rx_pm_state,
    pcie0_cfg_status_0_tph_requester_enable,
    pcie0_cfg_status_0_tph_st_mode,
    pcie0_cfg_status_0_tx_pm_state,
    pcie0_cfg_status_0_wrreq_bme_vld,
    pcie0_cfg_status_0_wrreq_flr_vld,
    pcie0_cfg_status_0_wrreq_function_number,
    pcie0_cfg_status_0_wrreq_msi_vld,
    pcie0_cfg_status_0_wrreq_msix_vld,
    pcie0_cfg_status_0_wrreq_out_value,
    pcie0_cfg_status_0_wrreq_vfe_vld,
    pcie0_m_axis_cq_0_tdata,
    pcie0_m_axis_cq_0_tkeep,
    pcie0_m_axis_cq_0_tlast,
    pcie0_m_axis_cq_0_tready,
    pcie0_m_axis_cq_0_tuser,
    pcie0_m_axis_cq_0_tvalid,
    pcie0_m_axis_rc_0_tdata,
    pcie0_m_axis_rc_0_tkeep,
    pcie0_m_axis_rc_0_tlast,
    pcie0_m_axis_rc_0_tready,
    pcie0_m_axis_rc_0_tuser,
    pcie0_m_axis_rc_0_tvalid,
    pcie0_s_axis_cc_0_tdata,
    pcie0_s_axis_cc_0_tkeep,
    pcie0_s_axis_cc_0_tlast,
    pcie0_s_axis_cc_0_tready,
    pcie0_s_axis_cc_0_tuser,
    pcie0_s_axis_cc_0_tvalid,
    pcie0_s_axis_rq_0_tdata,
    pcie0_s_axis_rq_0_tkeep,
    pcie0_s_axis_rq_0_tlast,
    pcie0_s_axis_rq_0_tready,
    pcie0_s_axis_rq_0_tuser,
    pcie0_s_axis_rq_0_tvalid,
    pcie0_transmit_fc_0_npd_av,
    pcie0_transmit_fc_0_nph_av,
    pcie0_user_clk_0,
    pcie0_user_lnk_up_0,
    pcie0_user_reset_0);
  input [7:0]PCIE0_GT_0_grx_n;
  input [7:0]PCIE0_GT_0_grx_p;
  output [7:0]PCIE0_GT_0_gtx_n;
  output [7:0]PCIE0_GT_0_gtx_p;
  input gt_refclk0_0_clk_n;
  input gt_refclk0_0_clk_p;
  input pcie0_cfg_control_0_err_cor_in;
  input pcie0_cfg_control_0_err_uncor_in;
  input pcie0_cfg_control_0_flr_done;
  input [15:0]pcie0_cfg_control_0_flr_done_function_number;
  output [3:0]pcie0_cfg_control_0_flr_in_process;
  input pcie0_cfg_control_0_hot_reset_in;
  output pcie0_cfg_control_0_hot_reset_out;
  input [15:0]pcie0_cfg_control_0_per_function_number;
  input pcie0_cfg_control_0_per_function_req;
  input pcie0_cfg_control_0_power_state_change_ack;
  output pcie0_cfg_control_0_power_state_change_interrupt;
  output [15:0]pcie0_cfg_ext_0_function_number;
  input [31:0]pcie0_cfg_ext_0_read_data;
  input pcie0_cfg_ext_0_read_data_valid;
  output pcie0_cfg_ext_0_read_received;
  output [9:0]pcie0_cfg_ext_0_register_number;
  output [3:0]pcie0_cfg_ext_0_write_byte_enable;
  output [31:0]pcie0_cfg_ext_0_write_data;
  output pcie0_cfg_ext_0_write_received;
  output [11:0]pcie0_cfg_fc_0_cpld;
  output [1:0]pcie0_cfg_fc_0_cpld_scale;
  output [7:0]pcie0_cfg_fc_0_cplh;
  output [1:0]pcie0_cfg_fc_0_cplh_scale;
  output [11:0]pcie0_cfg_fc_0_npd;
  output [1:0]pcie0_cfg_fc_0_npd_scale;
  output [7:0]pcie0_cfg_fc_0_nph;
  output [1:0]pcie0_cfg_fc_0_nph_scale;
  output [11:0]pcie0_cfg_fc_0_pd;
  output [1:0]pcie0_cfg_fc_0_pd_scale;
  output [7:0]pcie0_cfg_fc_0_ph;
  output [1:0]pcie0_cfg_fc_0_ph_scale;
  input [2:0]pcie0_cfg_fc_0_sel;
  input pcie0_cfg_fc_0_vc_sel;
  input [3:0]pcie0_cfg_interrupt_0_intx_vector;
  input [15:0]pcie0_cfg_interrupt_0_pending;
  output pcie0_cfg_interrupt_0_sent;
  input [9:0]pcie0_cfg_mgmt_0_addr;
  input [3:0]pcie0_cfg_mgmt_0_byte_en;
  input pcie0_cfg_mgmt_0_debug_access;
  input [15:0]pcie0_cfg_mgmt_0_function_number;
  output [31:0]pcie0_cfg_mgmt_0_read_data;
  input pcie0_cfg_mgmt_0_read_en;
  output pcie0_cfg_mgmt_0_read_write_done;
  input [31:0]pcie0_cfg_mgmt_0_write_data;
  input pcie0_cfg_mgmt_0_write_en;
  output pcie0_cfg_msg_recd_0_recd;
  output [7:0]pcie0_cfg_msg_recd_0_recd_data;
  output [4:0]pcie0_cfg_msg_recd_0_recd_type;
  input pcie0_cfg_msg_tx_0_transmit;
  input [31:0]pcie0_cfg_msg_tx_0_transmit_data;
  output pcie0_cfg_msg_tx_0_transmit_done;
  input [2:0]pcie0_cfg_msg_tx_0_transmit_type;
  output pcie0_cfg_status_0_10b_tag_requester_enable;
  output pcie0_cfg_status_0_atomic_requester_enable;
  output [7:0]pcie0_cfg_status_0_bus_number;
  input [1:0]pcie0_cfg_status_0_cq_np_req;
  output [5:0]pcie0_cfg_status_0_cq_np_req_count;
  output [2:0]pcie0_cfg_status_0_current_speed;
  output pcie0_cfg_status_0_err_cor_out;
  output pcie0_cfg_status_0_err_fatal_out;
  output pcie0_cfg_status_0_err_nonfatal_out;
  output pcie0_cfg_status_0_ext_tag_enable;
  output [2:0]pcie0_cfg_status_0_function_power_state;
  output [3:0]pcie0_cfg_status_0_function_status;
  output [1:0]pcie0_cfg_status_0_link_power_state;
  output [4:0]pcie0_cfg_status_0_local_error_out;
  output pcie0_cfg_status_0_local_error_valid;
  output [5:0]pcie0_cfg_status_0_ltssm_state;
  output [1:0]pcie0_cfg_status_0_max_payload;
  output [2:0]pcie0_cfg_status_0_max_read_req;
  output [2:0]pcie0_cfg_status_0_negotiated_width;
  output [23:0]pcie0_cfg_status_0_per_function_out;
  output pcie0_cfg_status_0_per_function_vld;
  output pcie0_cfg_status_0_phy_link_down;
  output [1:0]pcie0_cfg_status_0_phy_link_status;
  output pcie0_cfg_status_0_pl_status_change;
  output pcie0_cfg_status_0_rcb_status;
  output [5:0]pcie0_cfg_status_0_rq_seq_num0;
  output [5:0]pcie0_cfg_status_0_rq_seq_num1;
  output [5:0]pcie0_cfg_status_0_rq_seq_num2;
  output [5:0]pcie0_cfg_status_0_rq_seq_num3;
  output pcie0_cfg_status_0_rq_seq_num_vld0;
  output pcie0_cfg_status_0_rq_seq_num_vld1;
  output pcie0_cfg_status_0_rq_seq_num_vld2;
  output pcie0_cfg_status_0_rq_seq_num_vld3;
  output [19:0]pcie0_cfg_status_0_rq_tag0;
  output [19:0]pcie0_cfg_status_0_rq_tag1;
  output [3:0]pcie0_cfg_status_0_rq_tag_av;
  output [1:0]pcie0_cfg_status_0_rq_tag_vld0;
  output [1:0]pcie0_cfg_status_0_rq_tag_vld1;
  output [1:0]pcie0_cfg_status_0_rx_pm_state;
  output [3:0]pcie0_cfg_status_0_tph_requester_enable;
  output [11:0]pcie0_cfg_status_0_tph_st_mode;
  output [1:0]pcie0_cfg_status_0_tx_pm_state;
  output pcie0_cfg_status_0_wrreq_bme_vld;
  output pcie0_cfg_status_0_wrreq_flr_vld;
  output [15:0]pcie0_cfg_status_0_wrreq_function_number;
  output pcie0_cfg_status_0_wrreq_msi_vld;
  output pcie0_cfg_status_0_wrreq_msix_vld;
  output [3:0]pcie0_cfg_status_0_wrreq_out_value;
  output pcie0_cfg_status_0_wrreq_vfe_vld;
  output [1023:0]pcie0_m_axis_cq_0_tdata;
  output [31:0]pcie0_m_axis_cq_0_tkeep;
  output pcie0_m_axis_cq_0_tlast;
  input pcie0_m_axis_cq_0_tready;
  output [464:0]pcie0_m_axis_cq_0_tuser;
  output pcie0_m_axis_cq_0_tvalid;
  output [1023:0]pcie0_m_axis_rc_0_tdata;
  output [31:0]pcie0_m_axis_rc_0_tkeep;
  output pcie0_m_axis_rc_0_tlast;
  input pcie0_m_axis_rc_0_tready;
  output [336:0]pcie0_m_axis_rc_0_tuser;
  output pcie0_m_axis_rc_0_tvalid;
  input [1023:0]pcie0_s_axis_cc_0_tdata;
  input [31:0]pcie0_s_axis_cc_0_tkeep;
  input pcie0_s_axis_cc_0_tlast;
  output pcie0_s_axis_cc_0_tready;
  input [164:0]pcie0_s_axis_cc_0_tuser;
  input pcie0_s_axis_cc_0_tvalid;
  input [1023:0]pcie0_s_axis_rq_0_tdata;
  input [31:0]pcie0_s_axis_rq_0_tkeep;
  input pcie0_s_axis_rq_0_tlast;
  output pcie0_s_axis_rq_0_tready;
  input [372:0]pcie0_s_axis_rq_0_tuser;
  input pcie0_s_axis_rq_0_tvalid;
  output [3:0]pcie0_transmit_fc_0_npd_av;
  output [3:0]pcie0_transmit_fc_0_nph_av;
  output pcie0_user_clk_0;
  output pcie0_user_lnk_up_0;
  output pcie0_user_reset_0;

  wire [7:0]PCIE0_GT_0_grx_n;
  wire [7:0]PCIE0_GT_0_grx_p;
  wire [7:0]PCIE0_GT_0_gtx_n;
  wire [7:0]PCIE0_GT_0_gtx_p;
  wire gt_refclk0_0_clk_n;
  wire gt_refclk0_0_clk_p;
  wire pcie0_cfg_control_0_err_cor_in;
  wire pcie0_cfg_control_0_err_uncor_in;
  wire pcie0_cfg_control_0_flr_done;
  wire [15:0]pcie0_cfg_control_0_flr_done_function_number;
  wire [3:0]pcie0_cfg_control_0_flr_in_process;
  wire pcie0_cfg_control_0_hot_reset_in;
  wire pcie0_cfg_control_0_hot_reset_out;
  wire [15:0]pcie0_cfg_control_0_per_function_number;
  wire pcie0_cfg_control_0_per_function_req;
  wire pcie0_cfg_control_0_power_state_change_ack;
  wire pcie0_cfg_control_0_power_state_change_interrupt;
  wire [15:0]pcie0_cfg_ext_0_function_number;
  wire [31:0]pcie0_cfg_ext_0_read_data;
  wire pcie0_cfg_ext_0_read_data_valid;
  wire pcie0_cfg_ext_0_read_received;
  wire [9:0]pcie0_cfg_ext_0_register_number;
  wire [3:0]pcie0_cfg_ext_0_write_byte_enable;
  wire [31:0]pcie0_cfg_ext_0_write_data;
  wire pcie0_cfg_ext_0_write_received;
  wire [11:0]pcie0_cfg_fc_0_cpld;
  wire [1:0]pcie0_cfg_fc_0_cpld_scale;
  wire [7:0]pcie0_cfg_fc_0_cplh;
  wire [1:0]pcie0_cfg_fc_0_cplh_scale;
  wire [11:0]pcie0_cfg_fc_0_npd;
  wire [1:0]pcie0_cfg_fc_0_npd_scale;
  wire [7:0]pcie0_cfg_fc_0_nph;
  wire [1:0]pcie0_cfg_fc_0_nph_scale;
  wire [11:0]pcie0_cfg_fc_0_pd;
  wire [1:0]pcie0_cfg_fc_0_pd_scale;
  wire [7:0]pcie0_cfg_fc_0_ph;
  wire [1:0]pcie0_cfg_fc_0_ph_scale;
  wire [2:0]pcie0_cfg_fc_0_sel;
  wire pcie0_cfg_fc_0_vc_sel;
  wire [3:0]pcie0_cfg_interrupt_0_intx_vector;
  wire [15:0]pcie0_cfg_interrupt_0_pending;
  wire pcie0_cfg_interrupt_0_sent;
  wire [9:0]pcie0_cfg_mgmt_0_addr;
  wire [3:0]pcie0_cfg_mgmt_0_byte_en;
  wire pcie0_cfg_mgmt_0_debug_access;
  wire [15:0]pcie0_cfg_mgmt_0_function_number;
  wire [31:0]pcie0_cfg_mgmt_0_read_data;
  wire pcie0_cfg_mgmt_0_read_en;
  wire pcie0_cfg_mgmt_0_read_write_done;
  wire [31:0]pcie0_cfg_mgmt_0_write_data;
  wire pcie0_cfg_mgmt_0_write_en;
  wire pcie0_cfg_msg_recd_0_recd;
  wire [7:0]pcie0_cfg_msg_recd_0_recd_data;
  wire [4:0]pcie0_cfg_msg_recd_0_recd_type;
  wire pcie0_cfg_msg_tx_0_transmit;
  wire [31:0]pcie0_cfg_msg_tx_0_transmit_data;
  wire pcie0_cfg_msg_tx_0_transmit_done;
  wire [2:0]pcie0_cfg_msg_tx_0_transmit_type;
  wire pcie0_cfg_status_0_10b_tag_requester_enable;
  wire pcie0_cfg_status_0_atomic_requester_enable;
  wire [7:0]pcie0_cfg_status_0_bus_number;
  wire [1:0]pcie0_cfg_status_0_cq_np_req;
  wire [5:0]pcie0_cfg_status_0_cq_np_req_count;
  wire [2:0]pcie0_cfg_status_0_current_speed;
  wire pcie0_cfg_status_0_err_cor_out;
  wire pcie0_cfg_status_0_err_fatal_out;
  wire pcie0_cfg_status_0_err_nonfatal_out;
  wire pcie0_cfg_status_0_ext_tag_enable;
  wire [2:0]pcie0_cfg_status_0_function_power_state;
  wire [3:0]pcie0_cfg_status_0_function_status;
  wire [1:0]pcie0_cfg_status_0_link_power_state;
  wire [4:0]pcie0_cfg_status_0_local_error_out;
  wire pcie0_cfg_status_0_local_error_valid;
  wire [5:0]pcie0_cfg_status_0_ltssm_state;
  wire [1:0]pcie0_cfg_status_0_max_payload;
  wire [2:0]pcie0_cfg_status_0_max_read_req;
  wire [2:0]pcie0_cfg_status_0_negotiated_width;
  wire [23:0]pcie0_cfg_status_0_per_function_out;
  wire pcie0_cfg_status_0_per_function_vld;
  wire pcie0_cfg_status_0_phy_link_down;
  wire [1:0]pcie0_cfg_status_0_phy_link_status;
  wire pcie0_cfg_status_0_pl_status_change;
  wire pcie0_cfg_status_0_rcb_status;
  wire [5:0]pcie0_cfg_status_0_rq_seq_num0;
  wire [5:0]pcie0_cfg_status_0_rq_seq_num1;
  wire [5:0]pcie0_cfg_status_0_rq_seq_num2;
  wire [5:0]pcie0_cfg_status_0_rq_seq_num3;
  wire pcie0_cfg_status_0_rq_seq_num_vld0;
  wire pcie0_cfg_status_0_rq_seq_num_vld1;
  wire pcie0_cfg_status_0_rq_seq_num_vld2;
  wire pcie0_cfg_status_0_rq_seq_num_vld3;
  wire [19:0]pcie0_cfg_status_0_rq_tag0;
  wire [19:0]pcie0_cfg_status_0_rq_tag1;
  wire [3:0]pcie0_cfg_status_0_rq_tag_av;
  wire [1:0]pcie0_cfg_status_0_rq_tag_vld0;
  wire [1:0]pcie0_cfg_status_0_rq_tag_vld1;
  wire [1:0]pcie0_cfg_status_0_rx_pm_state;
  wire [3:0]pcie0_cfg_status_0_tph_requester_enable;
  wire [11:0]pcie0_cfg_status_0_tph_st_mode;
  wire [1:0]pcie0_cfg_status_0_tx_pm_state;
  wire pcie0_cfg_status_0_wrreq_bme_vld;
  wire pcie0_cfg_status_0_wrreq_flr_vld;
  wire [15:0]pcie0_cfg_status_0_wrreq_function_number;
  wire pcie0_cfg_status_0_wrreq_msi_vld;
  wire pcie0_cfg_status_0_wrreq_msix_vld;
  wire [3:0]pcie0_cfg_status_0_wrreq_out_value;
  wire pcie0_cfg_status_0_wrreq_vfe_vld;
  wire [1023:0]pcie0_m_axis_cq_0_tdata;
  wire [31:0]pcie0_m_axis_cq_0_tkeep;
  wire pcie0_m_axis_cq_0_tlast;
  wire pcie0_m_axis_cq_0_tready;
  wire [464:0]pcie0_m_axis_cq_0_tuser;
  wire pcie0_m_axis_cq_0_tvalid;
  wire [1023:0]pcie0_m_axis_rc_0_tdata;
  wire [31:0]pcie0_m_axis_rc_0_tkeep;
  wire pcie0_m_axis_rc_0_tlast;
  wire pcie0_m_axis_rc_0_tready;
  wire [336:0]pcie0_m_axis_rc_0_tuser;
  wire pcie0_m_axis_rc_0_tvalid;
  wire [1023:0]pcie0_s_axis_cc_0_tdata;
  wire [31:0]pcie0_s_axis_cc_0_tkeep;
  wire pcie0_s_axis_cc_0_tlast;
  wire pcie0_s_axis_cc_0_tready;
  wire [164:0]pcie0_s_axis_cc_0_tuser;
  wire pcie0_s_axis_cc_0_tvalid;
  wire [1023:0]pcie0_s_axis_rq_0_tdata;
  wire [31:0]pcie0_s_axis_rq_0_tkeep;
  wire pcie0_s_axis_rq_0_tlast;
  wire pcie0_s_axis_rq_0_tready;
  wire [372:0]pcie0_s_axis_rq_0_tuser;
  wire pcie0_s_axis_rq_0_tvalid;
  wire [3:0]pcie0_transmit_fc_0_npd_av;
  wire [3:0]pcie0_transmit_fc_0_nph_av;
  wire pcie0_user_clk_0;
  wire pcie0_user_lnk_up_0;
  wire pcie0_user_reset_0;

  design_rp design_rp_i
       (.PCIE0_GT_0_grx_n(PCIE0_GT_0_grx_n),
        .PCIE0_GT_0_grx_p(PCIE0_GT_0_grx_p),
        .PCIE0_GT_0_gtx_n(PCIE0_GT_0_gtx_n),
        .PCIE0_GT_0_gtx_p(PCIE0_GT_0_gtx_p),
        .gt_refclk0_0_clk_n(gt_refclk0_0_clk_n),
        .gt_refclk0_0_clk_p(gt_refclk0_0_clk_p),
        .pcie0_cfg_control_0_err_cor_in(pcie0_cfg_control_0_err_cor_in),
        .pcie0_cfg_control_0_err_uncor_in(pcie0_cfg_control_0_err_uncor_in),
        .pcie0_cfg_control_0_flr_done(pcie0_cfg_control_0_flr_done),
        .pcie0_cfg_control_0_flr_done_function_number(pcie0_cfg_control_0_flr_done_function_number),
        .pcie0_cfg_control_0_flr_in_process(pcie0_cfg_control_0_flr_in_process),
        .pcie0_cfg_control_0_hot_reset_in(pcie0_cfg_control_0_hot_reset_in),
        .pcie0_cfg_control_0_hot_reset_out(pcie0_cfg_control_0_hot_reset_out),
        .pcie0_cfg_control_0_per_function_number(pcie0_cfg_control_0_per_function_number),
        .pcie0_cfg_control_0_per_function_req(pcie0_cfg_control_0_per_function_req),
        .pcie0_cfg_control_0_power_state_change_ack(pcie0_cfg_control_0_power_state_change_ack),
        .pcie0_cfg_control_0_power_state_change_interrupt(pcie0_cfg_control_0_power_state_change_interrupt),
        .pcie0_cfg_ext_0_function_number(pcie0_cfg_ext_0_function_number),
        .pcie0_cfg_ext_0_read_data(pcie0_cfg_ext_0_read_data),
        .pcie0_cfg_ext_0_read_data_valid(pcie0_cfg_ext_0_read_data_valid),
        .pcie0_cfg_ext_0_read_received(pcie0_cfg_ext_0_read_received),
        .pcie0_cfg_ext_0_register_number(pcie0_cfg_ext_0_register_number),
        .pcie0_cfg_ext_0_write_byte_enable(pcie0_cfg_ext_0_write_byte_enable),
        .pcie0_cfg_ext_0_write_data(pcie0_cfg_ext_0_write_data),
        .pcie0_cfg_ext_0_write_received(pcie0_cfg_ext_0_write_received),
        .pcie0_cfg_fc_0_cpld(pcie0_cfg_fc_0_cpld),
        .pcie0_cfg_fc_0_cpld_scale(pcie0_cfg_fc_0_cpld_scale),
        .pcie0_cfg_fc_0_cplh(pcie0_cfg_fc_0_cplh),
        .pcie0_cfg_fc_0_cplh_scale(pcie0_cfg_fc_0_cplh_scale),
        .pcie0_cfg_fc_0_npd(pcie0_cfg_fc_0_npd),
        .pcie0_cfg_fc_0_npd_scale(pcie0_cfg_fc_0_npd_scale),
        .pcie0_cfg_fc_0_nph(pcie0_cfg_fc_0_nph),
        .pcie0_cfg_fc_0_nph_scale(pcie0_cfg_fc_0_nph_scale),
        .pcie0_cfg_fc_0_pd(pcie0_cfg_fc_0_pd),
        .pcie0_cfg_fc_0_pd_scale(pcie0_cfg_fc_0_pd_scale),
        .pcie0_cfg_fc_0_ph(pcie0_cfg_fc_0_ph),
        .pcie0_cfg_fc_0_ph_scale(pcie0_cfg_fc_0_ph_scale),
        .pcie0_cfg_fc_0_sel(pcie0_cfg_fc_0_sel),
        .pcie0_cfg_fc_0_vc_sel(pcie0_cfg_fc_0_vc_sel),
        .pcie0_cfg_interrupt_0_intx_vector(pcie0_cfg_interrupt_0_intx_vector),
        .pcie0_cfg_interrupt_0_pending(pcie0_cfg_interrupt_0_pending),
        .pcie0_cfg_interrupt_0_sent(pcie0_cfg_interrupt_0_sent),
        .pcie0_cfg_mgmt_0_addr(pcie0_cfg_mgmt_0_addr),
        .pcie0_cfg_mgmt_0_byte_en(pcie0_cfg_mgmt_0_byte_en),
        .pcie0_cfg_mgmt_0_debug_access(pcie0_cfg_mgmt_0_debug_access),
        .pcie0_cfg_mgmt_0_function_number(pcie0_cfg_mgmt_0_function_number),
        .pcie0_cfg_mgmt_0_read_data(pcie0_cfg_mgmt_0_read_data),
        .pcie0_cfg_mgmt_0_read_en(pcie0_cfg_mgmt_0_read_en),
        .pcie0_cfg_mgmt_0_read_write_done(pcie0_cfg_mgmt_0_read_write_done),
        .pcie0_cfg_mgmt_0_write_data(pcie0_cfg_mgmt_0_write_data),
        .pcie0_cfg_mgmt_0_write_en(pcie0_cfg_mgmt_0_write_en),
        .pcie0_cfg_msg_recd_0_recd(pcie0_cfg_msg_recd_0_recd),
        .pcie0_cfg_msg_recd_0_recd_data(pcie0_cfg_msg_recd_0_recd_data),
        .pcie0_cfg_msg_recd_0_recd_type(pcie0_cfg_msg_recd_0_recd_type),
        .pcie0_cfg_msg_tx_0_transmit(pcie0_cfg_msg_tx_0_transmit),
        .pcie0_cfg_msg_tx_0_transmit_data(pcie0_cfg_msg_tx_0_transmit_data),
        .pcie0_cfg_msg_tx_0_transmit_done(pcie0_cfg_msg_tx_0_transmit_done),
        .pcie0_cfg_msg_tx_0_transmit_type(pcie0_cfg_msg_tx_0_transmit_type),
        .pcie0_cfg_status_0_10b_tag_requester_enable(pcie0_cfg_status_0_10b_tag_requester_enable),
        .pcie0_cfg_status_0_atomic_requester_enable(pcie0_cfg_status_0_atomic_requester_enable),
        .pcie0_cfg_status_0_bus_number(pcie0_cfg_status_0_bus_number),
        .pcie0_cfg_status_0_cq_np_req(pcie0_cfg_status_0_cq_np_req),
        .pcie0_cfg_status_0_cq_np_req_count(pcie0_cfg_status_0_cq_np_req_count),
        .pcie0_cfg_status_0_current_speed(pcie0_cfg_status_0_current_speed),
        .pcie0_cfg_status_0_err_cor_out(pcie0_cfg_status_0_err_cor_out),
        .pcie0_cfg_status_0_err_fatal_out(pcie0_cfg_status_0_err_fatal_out),
        .pcie0_cfg_status_0_err_nonfatal_out(pcie0_cfg_status_0_err_nonfatal_out),
        .pcie0_cfg_status_0_ext_tag_enable(pcie0_cfg_status_0_ext_tag_enable),
        .pcie0_cfg_status_0_function_power_state(pcie0_cfg_status_0_function_power_state),
        .pcie0_cfg_status_0_function_status(pcie0_cfg_status_0_function_status),
        .pcie0_cfg_status_0_link_power_state(pcie0_cfg_status_0_link_power_state),
        .pcie0_cfg_status_0_local_error_out(pcie0_cfg_status_0_local_error_out),
        .pcie0_cfg_status_0_local_error_valid(pcie0_cfg_status_0_local_error_valid),
        .pcie0_cfg_status_0_ltssm_state(pcie0_cfg_status_0_ltssm_state),
        .pcie0_cfg_status_0_max_payload(pcie0_cfg_status_0_max_payload),
        .pcie0_cfg_status_0_max_read_req(pcie0_cfg_status_0_max_read_req),
        .pcie0_cfg_status_0_negotiated_width(pcie0_cfg_status_0_negotiated_width),
        .pcie0_cfg_status_0_per_function_out(pcie0_cfg_status_0_per_function_out),
        .pcie0_cfg_status_0_per_function_vld(pcie0_cfg_status_0_per_function_vld),
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
        .pcie0_cfg_status_0_tph_requester_enable(pcie0_cfg_status_0_tph_requester_enable),
        .pcie0_cfg_status_0_tph_st_mode(pcie0_cfg_status_0_tph_st_mode),
        .pcie0_cfg_status_0_tx_pm_state(pcie0_cfg_status_0_tx_pm_state),
        .pcie0_cfg_status_0_wrreq_bme_vld(pcie0_cfg_status_0_wrreq_bme_vld),
        .pcie0_cfg_status_0_wrreq_flr_vld(pcie0_cfg_status_0_wrreq_flr_vld),
        .pcie0_cfg_status_0_wrreq_function_number(pcie0_cfg_status_0_wrreq_function_number),
        .pcie0_cfg_status_0_wrreq_msi_vld(pcie0_cfg_status_0_wrreq_msi_vld),
        .pcie0_cfg_status_0_wrreq_msix_vld(pcie0_cfg_status_0_wrreq_msix_vld),
        .pcie0_cfg_status_0_wrreq_out_value(pcie0_cfg_status_0_wrreq_out_value),
        .pcie0_cfg_status_0_wrreq_vfe_vld(pcie0_cfg_status_0_wrreq_vfe_vld),
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
        .pcie0_transmit_fc_0_npd_av(pcie0_transmit_fc_0_npd_av),
        .pcie0_transmit_fc_0_nph_av(pcie0_transmit_fc_0_nph_av),
        .pcie0_user_clk_0(pcie0_user_clk_0),
        .pcie0_user_lnk_up_0(pcie0_user_lnk_up_0),
        .pcie0_user_reset_0(pcie0_user_reset_0));
endmodule
