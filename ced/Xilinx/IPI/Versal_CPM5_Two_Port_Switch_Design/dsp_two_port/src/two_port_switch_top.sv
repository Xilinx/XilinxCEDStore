`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AMD
// Engineer: Agastya Sampath
// 
// Create Date: 10/10/2023 05:55:43 PM
// Design Name: Two Port Switch Top
// Module Name: two_port_switch_top
// Project Name: Two Port Switch (CPM5 DSP, PL-PCIe5 USP)
// Target Devices: xcvp1202-vsva2785-2MHP-e-S
// Tool Versions: 2023.2
// Description: Top module for Two-Port PCIe Switch using CPM5 and PL-PCIe5
// 
// Dependencies: -
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module two_port_switch_top #(
    parameter EXT_PIPE_SIM = "FALSE"
) (
    // DSP GTs
    dsp_PCIE0_GT_grx_n,
    dsp_PCIE0_GT_gtx_n,
    dsp_PCIE0_GT_grx_p,
    dsp_PCIE0_GT_gtx_p,
    // USP GTs
    usp_pcie_mgt_grx_n,
    usp_pcie_mgt_grx_p,
    usp_pcie_mgt_gtx_n,
    usp_pcie_mgt_gtx_p,
    // USP Sys Clk
    usp_pcie_refclk_clk_n,
    usp_pcie_refclk_clk_p,
    // DSP Sys Clk
    dsp_gt_refclk0_clk_n,
    dsp_gt_refclk0_clk_p,
    // PIPE signals
    // synthesis translate_off
    usp_common_commands_in_0,
    usp_common_commands_out_0,
    usp_pipe_rx_0_sigs_0,
    usp_pipe_rx_1_sigs_0,
    usp_pipe_rx_2_sigs_0,
    usp_pipe_rx_3_sigs_0,
    usp_pipe_rx_4_sigs_0,
    usp_pipe_rx_5_sigs_0,
    usp_pipe_rx_6_sigs_0,
    usp_pipe_rx_7_sigs_0,
    usp_pipe_rx_8_sigs_0,
    usp_pipe_rx_9_sigs_0,
    usp_pipe_rx_10_sigs_0,
    usp_pipe_rx_11_sigs_0,
    usp_pipe_rx_12_sigs_0,
    usp_pipe_rx_13_sigs_0,
    usp_pipe_rx_14_sigs_0,
    usp_pipe_rx_15_sigs_0,
    usp_pipe_tx_0_sigs_0,
    usp_pipe_tx_1_sigs_0,
    usp_pipe_tx_2_sigs_0,
    usp_pipe_tx_3_sigs_0,
    usp_pipe_tx_4_sigs_0,
    usp_pipe_tx_5_sigs_0,
    usp_pipe_tx_6_sigs_0,
    usp_pipe_tx_7_sigs_0,
    usp_pipe_tx_8_sigs_0,
    usp_pipe_tx_9_sigs_0,
    usp_pipe_tx_10_sigs_0,
    usp_pipe_tx_11_sigs_0,
    usp_pipe_tx_12_sigs_0,
    usp_pipe_tx_13_sigs_0,
    usp_pipe_tx_14_sigs_0,
    usp_pipe_tx_15_sigs_0,
    dsp_pcie0_pipe_rp_0_commands_in,
    dsp_pcie0_pipe_rp_0_commands_out,
    dsp_pcie0_pipe_rp_0_rx_0,
    dsp_pcie0_pipe_rp_0_rx_1,
    dsp_pcie0_pipe_rp_0_rx_2,
    dsp_pcie0_pipe_rp_0_rx_3,
    dsp_pcie0_pipe_rp_0_rx_4,
    dsp_pcie0_pipe_rp_0_rx_5,
    dsp_pcie0_pipe_rp_0_rx_6,
    dsp_pcie0_pipe_rp_0_rx_7,
    dsp_pcie0_pipe_rp_0_rx_8,
    dsp_pcie0_pipe_rp_0_rx_9,
    dsp_pcie0_pipe_rp_0_rx_10,
    dsp_pcie0_pipe_rp_0_rx_11,
    dsp_pcie0_pipe_rp_0_rx_12,
    dsp_pcie0_pipe_rp_0_rx_13,
    dsp_pcie0_pipe_rp_0_rx_14,
    dsp_pcie0_pipe_rp_0_rx_15,
    dsp_pcie0_pipe_rp_0_tx_0,
    dsp_pcie0_pipe_rp_0_tx_1,
    dsp_pcie0_pipe_rp_0_tx_2,
    dsp_pcie0_pipe_rp_0_tx_3,
    dsp_pcie0_pipe_rp_0_tx_4,
    dsp_pcie0_pipe_rp_0_tx_5,
    dsp_pcie0_pipe_rp_0_tx_6,
    dsp_pcie0_pipe_rp_0_tx_7,
    dsp_pcie0_pipe_rp_0_tx_8,
    dsp_pcie0_pipe_rp_0_tx_9,
    dsp_pcie0_pipe_rp_0_tx_10,
    dsp_pcie0_pipe_rp_0_tx_11,
    dsp_pcie0_pipe_rp_0_tx_12,
    dsp_pcie0_pipe_rp_0_tx_13,
    dsp_pcie0_pipe_rp_0_tx_14,
    dsp_pcie0_pipe_rp_0_tx_15,
    // synthesis translate_on
    // Sys Reset
    sys_rst,
    sys_rst_o,
    // LEDs
    led_0,
    led_1,
    led_2,
    led_3
);
  // Local Parameters - Switch
  localparam TCQ = 1;

  // Local Parameters - USP
  localparam USP_IF_WIDTH = 512;
  localparam USP_RQ_TUSER_WIDTH = ((USP_IF_WIDTH == 512) ? 183 : 85); //<256b and 512b are the only supported IF widths for PL-PCIe5
  localparam USP_RC_TUSER_WIDTH = ((USP_IF_WIDTH == 512) ? 161 : 75);
  localparam USP_CQ_TUSER_WIDTH = ((USP_IF_WIDTH == 512) ? 231 : 109);
  localparam USP_CC_TUSER_WIDTH = ((USP_IF_WIDTH == 512) ? 81 : 33);
  localparam USP_TKEEP_WIDTH = (USP_IF_WIDTH / 32);

  // Local Parameters - DSP
  localparam DSP_IF_WIDTH = 512;
  localparam DSP_RQ_TUSER_WIDTH = ((DSP_IF_WIDTH == 512) ? 183 : ((DSP_IF_WIDTH == 1024) ? 373 : 85)); //<256b, 512b and 1024b are the only supported IF widths for CPM5
  localparam DSP_RC_TUSER_WIDTH = ((DSP_IF_WIDTH == 512) ? 161 : ((DSP_IF_WIDTH == 1024) ? 471 : 75));
  localparam DSP_CQ_TUSER_WIDTH = ((DSP_IF_WIDTH == 512) ? 232 : ((DSP_IF_WIDTH == 1024) ? 465 : 109));
  localparam DSP_CC_TUSER_WIDTH = ((DSP_IF_WIDTH == 512) ? 81 : ((DSP_IF_WIDTH == 1024) ? 233 : 33));
  localparam DSP_TKEEP_WIDTH = (DSP_IF_WIDTH / 32);

  // I/O Signals
  // DSP GTs
  input wire [3 : 0] dsp_PCIE0_GT_grx_n;
  output wire [3 : 0] dsp_PCIE0_GT_gtx_n;
  input wire [3 : 0] dsp_PCIE0_GT_grx_p;
  output wire [3 : 0] dsp_PCIE0_GT_gtx_p;
  // USP GTs
  input wire [3 : 0] usp_pcie_mgt_grx_n;
  input wire [3 : 0] usp_pcie_mgt_grx_p;
  output wire [3 : 0] usp_pcie_mgt_gtx_n;
  output wire [3 : 0] usp_pcie_mgt_gtx_p;
  // USP Sys Clk
  input wire usp_pcie_refclk_clk_n;
  input wire usp_pcie_refclk_clk_p;
  // DSP Sys Clk
  input wire dsp_gt_refclk0_clk_n;
  input wire dsp_gt_refclk0_clk_p;
  // Sys Reset
  input wire sys_rst;
  output wire sys_rst_o;
  // PIPE signals
  // synthesis translate_off
  input wire [13:0] dsp_pcie0_pipe_rp_0_commands_in;
  output wire [13:0] dsp_pcie0_pipe_rp_0_commands_out;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_0;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_1;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_2;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_3;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_4;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_5;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_6;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_7;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_8;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_9;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_10;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_11;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_12;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_13;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_14;
  input wire [41:0] dsp_pcie0_pipe_rp_0_rx_15;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_0;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_1;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_2;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_3;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_4;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_5;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_6;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_7;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_8;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_9;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_10;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_11;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_12;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_13;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_14;
  output wire [41:0] dsp_pcie0_pipe_rp_0_tx_15;
  input wire [25:0] usp_common_commands_in_0;
  output wire [25:0] usp_common_commands_out_0;
  input wire [83:0] usp_pipe_rx_0_sigs_0;
  input wire [83:0] usp_pipe_rx_1_sigs_0;
  input wire [83:0] usp_pipe_rx_2_sigs_0;
  input wire [83:0] usp_pipe_rx_3_sigs_0;
  input wire [83:0] usp_pipe_rx_4_sigs_0;
  input wire [83:0] usp_pipe_rx_5_sigs_0;
  input wire [83:0] usp_pipe_rx_6_sigs_0;
  input wire [83:0] usp_pipe_rx_7_sigs_0;
  input wire [83:0] usp_pipe_rx_8_sigs_0;
  input wire [83:0] usp_pipe_rx_9_sigs_0;
  input wire [83:0] usp_pipe_rx_10_sigs_0;
  input wire [83:0] usp_pipe_rx_11_sigs_0;
  input wire [83:0] usp_pipe_rx_12_sigs_0;
  input wire [83:0] usp_pipe_rx_13_sigs_0;
  input wire [83:0] usp_pipe_rx_14_sigs_0;
  input wire [83:0] usp_pipe_rx_15_sigs_0;
  output wire [83:0] usp_pipe_tx_0_sigs_0;
  output wire [83:0] usp_pipe_tx_1_sigs_0;
  output wire [83:0] usp_pipe_tx_2_sigs_0;
  output wire [83:0] usp_pipe_tx_3_sigs_0;
  output wire [83:0] usp_pipe_tx_4_sigs_0;
  output wire [83:0] usp_pipe_tx_5_sigs_0;
  output wire [83:0] usp_pipe_tx_6_sigs_0;
  output wire [83:0] usp_pipe_tx_7_sigs_0;
  output wire [83:0] usp_pipe_tx_8_sigs_0;
  output wire [83:0] usp_pipe_tx_9_sigs_0;
  output wire [83:0] usp_pipe_tx_10_sigs_0;
  output wire [83:0] usp_pipe_tx_11_sigs_0;
  output wire [83:0] usp_pipe_tx_12_sigs_0;
  output wire [83:0] usp_pipe_tx_13_sigs_0;
  output wire [83:0] usp_pipe_tx_14_sigs_0;
  output wire [83:0] usp_pipe_tx_15_sigs_0;
  // synthesis translate_on

  // LED pins
  output wire led_0;
  output wire led_1;
  output wire led_2;
  output wire led_3;

  // Internal Signals for DSP
  wire dsp_cpm_cor_irq_0;
  wire dsp_cpm_irq0_0;
  wire dsp_cpm_irq1_0;
  wire dsp_cpm_misc_irq_0;
  wire dsp_cpm_uncor_irq_0;
  wire dsp_pcie0_cfg_control_0_err_cor_in;
  wire dsp_pcie0_cfg_control_0_err_uncor_in;
  wire dsp_pcie0_cfg_control_0_flr_done;
  wire [15:0] dsp_pcie0_cfg_control_0_flr_done_function_number;
  wire [3:0] dsp_pcie0_cfg_control_0_flr_in_process;
  wire dsp_pcie0_cfg_control_0_hot_reset_in;
  wire dsp_pcie0_cfg_control_0_hot_reset_out;
  wire [15:0] dsp_pcie0_cfg_control_0_per_function_number;
  wire dsp_pcie0_cfg_control_0_per_function_req;
  wire dsp_pcie0_cfg_control_0_power_state_change_ack;
  wire dsp_pcie0_cfg_control_0_power_state_change_interrupt;
  wire [15:0] dsp_pcie0_cfg_ext_0_function_number;
  wire [31:0] dsp_pcie0_cfg_ext_0_read_data;
  wire dsp_pcie0_cfg_ext_0_read_data_valid;
  wire dsp_pcie0_cfg_ext_0_read_received;
  wire [9:0] dsp_pcie0_cfg_ext_0_register_number;
  wire [3:0] dsp_pcie0_cfg_ext_0_write_byte_enable;
  wire [31:0] dsp_pcie0_cfg_ext_0_write_data;
  wire dsp_pcie0_cfg_ext_0_write_received;
  wire [11:0] dsp_pcie0_cfg_fc_0_cpld;
  wire [1:0] dsp_pcie0_cfg_fc_0_cpld_scale;
  wire [7:0] dsp_pcie0_cfg_fc_0_cplh;
  wire [1:0] dsp_pcie0_cfg_fc_0_cplh_scale;
  wire [11:0] dsp_pcie0_cfg_fc_0_npd;
  wire [1:0] dsp_pcie0_cfg_fc_0_npd_scale;
  wire [7:0] dsp_pcie0_cfg_fc_0_nph;
  wire [1:0] dsp_pcie0_cfg_fc_0_nph_scale;
  wire [11:0] dsp_pcie0_cfg_fc_0_pd;
  wire [1:0] dsp_pcie0_cfg_fc_0_pd_scale;
  wire [7:0] dsp_pcie0_cfg_fc_0_ph;
  wire [1:0] dsp_pcie0_cfg_fc_0_ph_scale;
  wire [2:0] dsp_pcie0_cfg_fc_0_sel;
  wire dsp_pcie0_cfg_fc_0_vc_sel;
  wire [3:0] dsp_pcie0_cfg_interrupt_0_intx_vector;
  wire [15:0] dsp_pcie0_cfg_interrupt_0_pending;
  wire dsp_pcie0_cfg_interrupt_0_sent;
  wire [9:0] dsp_pcie0_cfg_mgmt_0_addr;
  wire [3:0] dsp_pcie0_cfg_mgmt_0_byte_en;
  wire dsp_pcie0_cfg_mgmt_0_debug_access;
  wire [15:0] dsp_pcie0_cfg_mgmt_0_function_number;
  wire [31:0] dsp_pcie0_cfg_mgmt_0_read_data;
  wire dsp_pcie0_cfg_mgmt_0_read_en;
  wire dsp_pcie0_cfg_mgmt_0_read_write_done;
  wire [31:0] dsp_pcie0_cfg_mgmt_0_write_data;
  wire dsp_pcie0_cfg_mgmt_0_write_en;
  wire dsp_pcie0_cfg_msg_recd_0_recd;
  wire [7:0] dsp_pcie0_cfg_msg_recd_0_recd_data;
  wire [4:0] dsp_pcie0_cfg_msg_recd_0_recd_type;
  wire dsp_pcie0_cfg_msg_tx_0_transmit;
  wire [31:0] dsp_pcie0_cfg_msg_tx_0_transmit_data;
  wire dsp_pcie0_cfg_msg_tx_0_transmit_done;
  wire [2:0] dsp_pcie0_cfg_msg_tx_0_transmit_type;
  wire [2:0] dsp_pcie0_cfg_msi_0_attr;
  wire [31:0] dsp_pcie0_cfg_msi_0_data;
  wire dsp_pcie0_cfg_msi_0_enable;
  wire dsp_pcie0_cfg_msi_0_fail;
  wire [15:0] dsp_pcie0_cfg_msi_0_function_number;
  wire [31:0] dsp_pcie0_cfg_msi_0_int_vector;
  wire dsp_pcie0_cfg_msi_0_mask_update;
  wire [2:0] dsp_pcie0_cfg_msi_0_mmenable;
  wire [31:0] dsp_pcie0_cfg_msi_0_pending_status;
  wire dsp_pcie0_cfg_msi_0_pending_status_data_enable;
  wire [3:0] dsp_pcie0_cfg_msi_0_pending_status_function_num;
  wire [3:0] dsp_pcie0_cfg_msi_0_select;
  wire dsp_pcie0_cfg_msi_0_sent;
  wire dsp_pcie0_cfg_msi_0_tph_present;
  wire [7:0] dsp_pcie0_cfg_msi_0_tph_st_tag;
  wire [1:0] dsp_pcie0_cfg_msi_0_tph_type;
  wire dsp_pcie0_cfg_status_0_10b_tag_requester_enable;
  wire dsp_pcie0_cfg_status_0_atomic_requester_enable;
  wire [7:0] dsp_pcie0_cfg_status_0_bus_number;
  wire [1:0] dsp_pcie0_cfg_status_0_cq_np_req;
  wire [5:0] dsp_pcie0_cfg_status_0_cq_np_req_count;
  wire [2:0] dsp_pcie0_cfg_status_0_current_speed;
  wire dsp_pcie0_cfg_status_0_err_cor_out;
  wire dsp_pcie0_cfg_status_0_err_fatal_out;
  wire dsp_pcie0_cfg_status_0_err_nonfatal_out;
  wire dsp_pcie0_cfg_status_0_ext_tag_enable;
  wire [2:0] dsp_pcie0_cfg_status_0_function_power_state;
  wire [3:0] dsp_pcie0_cfg_status_0_function_status;
  wire [1:0] dsp_pcie0_cfg_status_0_link_power_state;
  wire [4:0] dsp_pcie0_cfg_status_0_local_error_out;
  wire dsp_pcie0_cfg_status_0_local_error_valid;
  wire [5:0] dsp_pcie0_cfg_status_0_ltssm_state;
  wire [1:0] dsp_pcie0_cfg_status_0_max_payload;
  wire [2:0] dsp_pcie0_cfg_status_0_max_read_req;
  wire [2:0] dsp_pcie0_cfg_status_0_negotiated_width;
  wire dsp_pcie0_cfg_status_0_pasid_enable;
  wire dsp_pcie0_cfg_status_0_pasid_exec_permission_enable;
  wire dsp_pcie0_cfg_status_0_pasid_privil_mode_enable;
  wire [23:0] dsp_pcie0_cfg_status_0_per_function_out;
  wire dsp_pcie0_cfg_status_0_per_function_vld;
  wire dsp_pcie0_cfg_status_0_phy_link_down;
  wire [1:0] dsp_pcie0_cfg_status_0_phy_link_status;
  wire dsp_pcie0_cfg_status_0_pl_status_change;
  wire dsp_pcie0_cfg_status_0_rcb_status;
  wire [5:0] dsp_pcie0_cfg_status_0_rq_seq_num0;
  wire [5:0] dsp_pcie0_cfg_status_0_rq_seq_num1;
  wire [5:0] dsp_pcie0_cfg_status_0_rq_seq_num2;
  wire [5:0] dsp_pcie0_cfg_status_0_rq_seq_num3;
  wire dsp_pcie0_cfg_status_0_rq_seq_num_vld0;
  wire dsp_pcie0_cfg_status_0_rq_seq_num_vld1;
  wire dsp_pcie0_cfg_status_0_rq_seq_num_vld2;
  wire dsp_pcie0_cfg_status_0_rq_seq_num_vld3;
  wire [19:0] dsp_pcie0_cfg_status_0_rq_tag0;
  wire [19:0] dsp_pcie0_cfg_status_0_rq_tag1;
  wire [3:0] dsp_pcie0_cfg_status_0_rq_tag_av;
  wire [1:0] dsp_pcie0_cfg_status_0_rq_tag_vld0;
  wire [1:0] dsp_pcie0_cfg_status_0_rq_tag_vld1;
  wire [1:0] dsp_pcie0_cfg_status_0_rx_pm_state;
  wire [3:0] dsp_pcie0_cfg_status_0_tph_requester_enable;
  wire [11:0] dsp_pcie0_cfg_status_0_tph_st_mode;
  wire [1:0] dsp_pcie0_cfg_status_0_tx_pm_state;
  wire dsp_pcie0_cfg_status_0_wrreq_bme_vld;
  wire dsp_pcie0_cfg_status_0_wrreq_flr_vld;
  wire [15:0] dsp_pcie0_cfg_status_0_wrreq_function_number;
  wire dsp_pcie0_cfg_status_0_wrreq_msi_vld;
  wire dsp_pcie0_cfg_status_0_wrreq_msix_vld;
  wire [3:0] dsp_pcie0_cfg_status_0_wrreq_out_value;
  wire dsp_pcie0_cfg_status_0_wrreq_vfe_vld;
  wire [DSP_IF_WIDTH-1:0] dsp_pcie0_m_axis_cq_0_tdata;
  wire [DSP_TKEEP_WIDTH-1:0] dsp_pcie0_m_axis_cq_0_tkeep;
  wire dsp_pcie0_m_axis_cq_0_tlast;
  wire dsp_pcie0_m_axis_cq_0_tready;
  wire [DSP_CQ_TUSER_WIDTH-1:0] dsp_pcie0_m_axis_cq_0_tuser;
  wire dsp_pcie0_m_axis_cq_0_tvalid;
  wire [DSP_IF_WIDTH-1:0] dsp_pcie0_m_axis_rc_0_tdata;
  wire [DSP_TKEEP_WIDTH-1:0] dsp_pcie0_m_axis_rc_0_tkeep;
  wire dsp_pcie0_m_axis_rc_0_tlast;
  wire dsp_pcie0_m_axis_rc_0_tready;
  wire [DSP_RC_TUSER_WIDTH-1:0] dsp_pcie0_m_axis_rc_0_tuser;
  wire dsp_pcie0_m_axis_rc_0_tvalid;
  wire [DSP_IF_WIDTH-1:0] dsp_pcie0_s_axis_cc_0_tdata;
  wire [DSP_TKEEP_WIDTH-1:0] dsp_pcie0_s_axis_cc_0_tkeep;
  wire dsp_pcie0_s_axis_cc_0_tlast;
  wire dsp_pcie0_s_axis_cc_0_tready;
  wire [DSP_CC_TUSER_WIDTH-1:0] dsp_pcie0_s_axis_cc_0_tuser;
  wire dsp_pcie0_s_axis_cc_0_tvalid;
  wire [DSP_IF_WIDTH-1:0] dsp_pcie0_s_axis_rq_0_tdata;
  wire [DSP_TKEEP_WIDTH-1:0] dsp_pcie0_s_axis_rq_0_tkeep;
  wire dsp_pcie0_s_axis_rq_0_tlast;
  wire dsp_pcie0_s_axis_rq_0_tready;
  wire [DSP_RQ_TUSER_WIDTH-1:0] dsp_pcie0_s_axis_rq_0_tuser;
  wire dsp_pcie0_s_axis_rq_0_tvalid;
  wire [3:0] dsp_pcie0_transmit_fc_0_npd_av;
  wire [3:0] dsp_pcie0_transmit_fc_0_nph_av;
  wire dsp_pcie0_user_clk_0;
  wire dsp_pcie0_user_lnk_up_0;
  wire dsp_pcie0_user_reset_0;

  // Internal Signals for Switch Logic


  // Internal Signals for USP
  wire usp_ccix_optimized_tlp_tx_and_rx_enable;
  wire [7:0] usp_ccix_rx_credit_av;
  wire usp_core_clk;
  wire usp_cxs_rx_active_ack;
  wire usp_cxs_rx_active_req;
  wire [35:0] usp_cxs_rx_cntl;
  wire usp_cxs_rx_cntl_chk;
  wire usp_cxs_rx_crdgnt;
  wire usp_cxs_rx_crdgnt_chk;
  wire usp_cxs_rx_crdrtn;
  wire usp_cxs_rx_crdrtn_chk;
  wire [511:0] usp_cxs_rx_data;
  wire [63:0] usp_cxs_rx_data_chk;
  wire usp_cxs_rx_deact_hint;
  wire usp_cxs_rx_valid;
  wire usp_cxs_rx_valid_chk;
  wire usp_cxs_tx_active_ack;
  wire usp_cxs_tx_active_req;
  wire [35:0] usp_cxs_tx_cntl;
  wire usp_cxs_tx_cntl_chk;
  wire usp_cxs_tx_crdgnt;
  wire usp_cxs_tx_crdgnt_chk;
  wire usp_cxs_tx_crdrtn;
  wire usp_cxs_tx_crdrtn_chk;
  wire [511:0] usp_cxs_tx_data;
  wire [63:0] usp_cxs_tx_data_chk;
  wire usp_cxs_tx_deact_hint;
  wire usp_cxs_tx_valid;
  wire usp_cxs_tx_valid_chk;
  wire [USP_IF_WIDTH-1:0] usp_m_axis_cq_tdata;
  wire [USP_TKEEP_WIDTH-1:0] usp_m_axis_cq_tkeep;
  wire usp_m_axis_cq_tlast;
  wire usp_m_axis_cq_tready;
  wire [USP_CQ_TUSER_WIDTH-1:0] usp_m_axis_cq_tuser;
  wire usp_m_axis_cq_tvalid;
  wire [USP_IF_WIDTH-1:0] usp_m_axis_rc_tdata;
  wire [USP_TKEEP_WIDTH-1:0] usp_m_axis_rc_tkeep;
  wire usp_m_axis_rc_tlast;
  wire usp_m_axis_rc_tready;
  wire [USP_RC_TUSER_WIDTH-1:0] usp_m_axis_rc_tuser;
  wire usp_m_axis_rc_tvalid;
  wire [7:0] usp_pcie_cfg_control_bus_number;
  wire usp_pcie_cfg_control_config_space_enable;
  wire [7:0] usp_pcie_cfg_control_ds_bus_number;
  wire [4:0] usp_pcie_cfg_control_ds_device_number;
  wire [7:0] usp_pcie_cfg_control_ds_port_number;
  wire [63:0] usp_pcie_cfg_control_dsn;
  wire usp_pcie_cfg_control_err_cor_in;
  wire usp_pcie_cfg_control_err_uncor_in;
  wire [0:0] usp_pcie_cfg_control_flr_done;
  wire [15:0] usp_pcie_cfg_control_flr_done_function_number;
  wire [3:0] usp_pcie_cfg_control_flr_in_process;
  wire usp_pcie_cfg_control_hot_reset_in;
  wire usp_pcie_cfg_control_hot_reset_out;
  wire usp_pcie_cfg_control_link_training_enable;
  wire [15:0] usp_pcie_cfg_control_per_function_func_num;
  wire usp_pcie_cfg_control_per_function_req;
  wire usp_pcie_cfg_control_pm_aspm_l1entry_reject;
  wire usp_pcie_cfg_control_pm_aspm_tx_l0s_entry_disable;
  wire usp_pcie_cfg_control_power_state_change_ack;
  wire usp_pcie_cfg_control_power_state_change_interrupt;
  wire usp_pcie_cfg_control_req_pm_transition_l23_ready;
  wire [0:0] usp_pcie_cfg_control_vf_flr_done;
  wire [7:0] usp_pcie_cfg_control_vf_flr_func_num;
  wire [251:0] usp_pcie_cfg_control_vf_flr_in_process;
  wire [7:0] usp_pcie_cfg_ext_function_number;
  wire [31:0] usp_pcie_cfg_ext_read_data;
  wire usp_pcie_cfg_ext_read_data_valid;
  wire usp_pcie_cfg_ext_read_received;
  wire [9:0] usp_pcie_cfg_ext_register_number;
  wire [3:0] usp_pcie_cfg_ext_write_byte_enable;
  wire [31:0] usp_pcie_cfg_ext_write_data;
  wire usp_pcie_cfg_ext_write_received;
  wire [11:0] usp_pcie_cfg_fc_cpld;
  wire [1:0] usp_pcie_cfg_fc_cpld_scale;
  wire [7:0] usp_pcie_cfg_fc_cplh;
  wire [1:0] usp_pcie_cfg_fc_cplh_scale;
  wire [11:0] usp_pcie_cfg_fc_npd;
  wire [1:0] usp_pcie_cfg_fc_npd_scale;
  wire [7:0] usp_pcie_cfg_fc_nph;
  wire [1:0] usp_pcie_cfg_fc_nph_scale;
  wire [11:0] usp_pcie_cfg_fc_pd;
  wire [1:0] usp_pcie_cfg_fc_pd_scale;
  wire [7:0] usp_pcie_cfg_fc_ph;
  wire [1:0] usp_pcie_cfg_fc_ph_scale;
  wire [2:0] usp_pcie_cfg_fc_sel;
  wire usp_pcie_cfg_fc_vc_sel;
  wire [3:0] usp_pcie_cfg_interrupt_intx_vector;
  wire [7:0] usp_pcie_cfg_interrupt_pending;
  wire usp_pcie_cfg_interrupt_sent;
  wire usp_pcie_cfg_mesg_rcvd_recd;
  wire [7:0] usp_pcie_cfg_mesg_rcvd_recd_data;
  wire [4:0] usp_pcie_cfg_mesg_rcvd_recd_type;
  wire usp_pcie_cfg_mesg_tx_transmit;
  wire [31:0] usp_pcie_cfg_mesg_tx_transmit_data;
  wire usp_pcie_cfg_mesg_tx_transmit_done;
  wire [2:0] usp_pcie_cfg_mesg_tx_transmit_type;
  wire [9:0] usp_pcie_cfg_mgmt_addr;
  wire [3:0] usp_pcie_cfg_mgmt_byte_en;
  wire usp_pcie_cfg_mgmt_debug_access;
  wire [7:0] usp_pcie_cfg_mgmt_function_number;
  wire [31:0] usp_pcie_cfg_mgmt_read_data;
  wire usp_pcie_cfg_mgmt_read_en;
  wire usp_pcie_cfg_mgmt_read_write_done;
  wire [31:0] usp_pcie_cfg_mgmt_write_data;
  wire usp_pcie_cfg_mgmt_write_en;
  wire [2:0] usp_pcie_cfg_msix_internal_attr;
  wire [0:0] usp_pcie_cfg_msix_internal_enable;
  wire usp_pcie_cfg_msix_internal_fail;
  wire [15:0] usp_pcie_cfg_msix_internal_function_number;
  wire usp_pcie_cfg_msix_internal_int_vector;
  wire [0:0] usp_pcie_cfg_msix_internal_mask;
  wire [7:0] usp_pcie_cfg_msix_internal_mint_vector;
  wire usp_pcie_cfg_msix_internal_sent;
  wire usp_pcie_cfg_msix_internal_tph_present;
  wire [7:0] usp_pcie_cfg_msix_internal_tph_st_tag;
  wire [1:0] usp_pcie_cfg_msix_internal_tph_type;
  wire [1:0] usp_pcie_cfg_msix_internal_vec_pending;
  wire [0:0] usp_pcie_cfg_msix_internal_vec_pending_status;
  wire [251:0] usp_pcie_cfg_msix_internal_vf_enable;
  wire [251:0] usp_pcie_cfg_msix_internal_vf_mask;
  wire [0:0] usp_pcie_cfg_status_10b_tag_requester_enable;
  wire [0:0] usp_pcie_cfg_status_atomic_requester_enable;
  wire [1:0] usp_pcie_cfg_status_cq_np_req;
  wire [5:0] usp_pcie_cfg_status_cq_np_req_count;
  wire [2:0] usp_pcie_cfg_status_current_speed;
  wire usp_pcie_cfg_status_err_cor_out;
  wire usp_pcie_cfg_status_err_fatal_out;
  wire usp_pcie_cfg_status_err_nonfatal_out;
  wire usp_pcie_cfg_status_ext_tag_enable;
  wire [2:0] usp_pcie_cfg_status_function_power_state;
  wire [3:0] usp_pcie_cfg_status_function_status;
  wire [1:0] usp_pcie_cfg_status_link_power_state;
  wire [4:0] usp_pcie_cfg_status_local_error_out;
  wire usp_pcie_cfg_status_local_error_valid;
  wire [5:0] usp_pcie_cfg_status_ltssm_state;
  wire [1:0] usp_pcie_cfg_status_max_payload;
  wire [2:0] usp_pcie_cfg_status_max_read_req;
  wire [2:0] usp_pcie_cfg_status_negotiated_width;
  wire [1:0] usp_pcie_cfg_status_obff_enable;
  wire [0:0] usp_pcie_cfg_status_pasid_enable;
  wire [0:0] usp_pcie_cfg_status_pasid_exec_permission_enable;
  wire [0:0] usp_pcie_cfg_status_pasid_privil_mode_enable;
  wire [23:0] usp_pcie_cfg_status_per_function_out;
  wire usp_pcie_cfg_status_per_function_vld;
  wire usp_pcie_cfg_status_phy_link_down;
  wire [1:0] usp_pcie_cfg_status_phy_link_status;
  wire usp_pcie_cfg_status_pl_status_change;
  wire [0:0] usp_pcie_cfg_status_rcb_status;
  wire [5:0] usp_pcie_cfg_status_rq_seq_num0;
  wire [5:0] usp_pcie_cfg_status_rq_seq_num1;
  wire usp_pcie_cfg_status_rq_seq_num_vld0;
  wire usp_pcie_cfg_status_rq_seq_num_vld1;
  wire [9:0] usp_pcie_cfg_status_rq_tag0;
  wire [9:0] usp_pcie_cfg_status_rq_tag1;
  wire [3:0] usp_pcie_cfg_status_rq_tag_av;
  wire usp_pcie_cfg_status_rq_tag_vld0;
  wire usp_pcie_cfg_status_rq_tag_vld1;
  wire [1:0] usp_pcie_cfg_status_rx_pm_state;
  wire [3:0] usp_pcie_cfg_status_tph_requester_enable;
  wire [11:0] usp_pcie_cfg_status_tph_st_mode;
  wire [1:0] usp_pcie_cfg_status_tx_pm_state;
  wire usp_pcie_cfg_status_vc1_enable;
  wire usp_pcie_cfg_status_vc1_negotiation_pending;
  wire [755:0] usp_pcie_cfg_status_vf_power_state;
  wire [503:0] usp_pcie_cfg_status_vf_status;
  wire [251:0] usp_pcie_cfg_status_vf_tph_requester_enable;
  wire [755:0] usp_pcie_cfg_status_vf_tph_st_mode;
  wire usp_pcie_cfg_status_wrreq_bme_vld;
  wire usp_pcie_cfg_status_wrreq_flr_vld;
  wire [15:0] usp_pcie_cfg_status_wrreq_function_number;
  wire usp_pcie_cfg_status_wrreq_msi_vld;
  wire usp_pcie_cfg_status_wrreq_msix_vld;
  wire [3:0] usp_pcie_cfg_status_wrreq_out_value;
  wire usp_pcie_cfg_status_wrreq_vfe_vld;
  wire [3:0] usp_pcie_transmit_fc_npd_av;
  wire [3:0] usp_pcie_transmit_fc_nph_av;
  wire usp_phy_rdy_out;
  wire [USP_IF_WIDTH-1:0] usp_s_axis_cc_tdata;
  wire [USP_TKEEP_WIDTH-1:0] usp_s_axis_cc_tkeep;
  wire usp_s_axis_cc_tlast;
  wire [3:0] usp_s_axis_cc_tready;
  wire [USP_CC_TUSER_WIDTH-1:0] usp_s_axis_cc_tuser;
  wire usp_s_axis_cc_tvalid;
  wire [USP_IF_WIDTH-1:0] usp_s_axis_rq_tdata;
  wire [USP_TKEEP_WIDTH-1:0] usp_s_axis_rq_tkeep;
  wire usp_s_axis_rq_tlast;
  wire [3:0] usp_s_axis_rq_tready;
  wire [USP_RQ_TUSER_WIDTH-1:0] usp_s_axis_rq_tuser;
  wire usp_s_axis_rq_tvalid;
  wire usp_sys_reset;
  wire usp_user_clk;
  wire usp_user_lnk_up;
  wire usp_user_reset;

  /* LED Setup START */

  // LED Signals
  reg [31:0] dsp_clk_heartbeat;
  reg [31:0] usp_clk_heartbeat;
  wire flicker_dsp_0;
  wire flicker_usp_0;

  assign flicker_dsp_0 = dsp_clk_heartbeat[31] ? dsp_pcie0_user_reset_0 : 1'b1;
  assign flicker_usp_0 = usp_clk_heartbeat[31] ? usp_user_reset : usp_phy_rdy_out;

  OBUF led_0_obuf (
      .O(led_0),
      .I(sys_rst_user)
  );
  OBUF led_1_obuf (
      .O(led_1),
      .I(flicker_dsp_0)
  );
  OBUF led_2_obuf (
      .O(led_2),
      .I(usp_user_lnk_up)
  );
  OBUF led_3_obuf (
      .O(led_3),
      .I(flicker_usp_0)
  );

  // Create a Clock Heartbeat for UpStream Port
  always @(posedge dsp_pcie0_user_clk_0) begin
    if (!sys_rst_user) begin
      dsp_clk_heartbeat <= #TCQ 32'd0;
    end else begin
      dsp_clk_heartbeat <= #TCQ dsp_clk_heartbeat + 1'b1;
    end
  end

  // Create a Clock Heartbeat for DownStream Port
  always @(posedge usp_user_clk or negedge sys_rst_user) begin
    if (!sys_rst_user) begin
      usp_clk_heartbeat <= #TCQ 32'd0;
    end else begin
      usp_clk_heartbeat <= #TCQ usp_clk_heartbeat + 1'b1;
    end
  end

  /* LED Setup END */

  // Reset generation
  IBUF sys_reset_n_ibuf (
      .O(sys_rst_user),
      .I(sys_rst)
  );
  OBUF sys_reset_n_obuf (
      .O(sys_rst_o),
      .I(sys_rst_user)
  );

  // DSP BD Instantiate
  generate
    if (EXT_PIPE_SIM == "TRUE") begin : gen_ext_pipe_sim_dsp
      dsp_cips switch_dsp (
          .PCIE0_GT_0_grx_n(),
          .PCIE0_GT_0_grx_p(),
          .PCIE0_GT_0_gtx_n(),
          .PCIE0_GT_0_gtx_p(),
          .cpm_cor_irq_0(dsp_cpm_cor_irq_0),
          .cpm_irq0_0(dsp_cpm_irq0_0),
          .cpm_irq1_0(dsp_cpm_irq1_0),
          .cpm_misc_irq_0(dsp_cpm_misc_irq_0),
          .cpm_uncor_irq_0(dsp_cpm_uncor_irq_0),
          .gt_refclk0_0_clk_n(dsp_gt_refclk0_clk_n),
          .gt_refclk0_0_clk_p(dsp_gt_refclk0_clk_p),
          .pcie0_cfg_control_0_err_cor_in(dsp_pcie0_cfg_control_0_err_cor_in),
          .pcie0_cfg_control_0_err_uncor_in(dsp_pcie0_cfg_control_0_err_uncor_in),
          .pcie0_cfg_control_0_flr_done(dsp_pcie0_cfg_control_0_flr_done),
          .pcie0_cfg_control_0_flr_done_function_number(dsp_pcie0_cfg_control_0_flr_done_function_number),
          .pcie0_cfg_control_0_flr_in_process(dsp_pcie0_cfg_control_0_flr_in_process),
          .pcie0_cfg_control_0_hot_reset_in(dsp_pcie0_cfg_control_0_hot_reset_in),
          .pcie0_cfg_control_0_hot_reset_out(dsp_pcie0_cfg_control_0_hot_reset_out),
          .pcie0_cfg_control_0_per_function_number(dsp_pcie0_cfg_control_0_per_function_number),
          .pcie0_cfg_control_0_per_function_req(dsp_pcie0_cfg_control_0_per_function_req),
          .pcie0_cfg_control_0_power_state_change_ack(dsp_pcie0_cfg_control_0_power_state_change_ack),
          .pcie0_cfg_control_0_power_state_change_interrupt(dsp_pcie0_cfg_control_0_power_state_change_interrupt),
          .pcie0_cfg_ext_0_function_number(dsp_pcie0_cfg_ext_0_function_number),
          .pcie0_cfg_ext_0_read_data(dsp_pcie0_cfg_ext_0_read_data),
          .pcie0_cfg_ext_0_read_data_valid(dsp_pcie0_cfg_ext_0_read_data_valid),
          .pcie0_cfg_ext_0_read_received(dsp_pcie0_cfg_ext_0_read_received),
          .pcie0_cfg_ext_0_register_number(dsp_pcie0_cfg_ext_0_register_number),
          .pcie0_cfg_ext_0_write_byte_enable(dsp_pcie0_cfg_ext_0_write_byte_enable),
          .pcie0_cfg_ext_0_write_data(dsp_pcie0_cfg_ext_0_write_data),
          .pcie0_cfg_ext_0_write_received(dsp_pcie0_cfg_ext_0_write_received),
          .pcie0_cfg_fc_0_cpld(dsp_pcie0_cfg_fc_0_cpld),
          .pcie0_cfg_fc_0_cpld_scale(dsp_pcie0_cfg_fc_0_cpld_scale),
          .pcie0_cfg_fc_0_cplh(dsp_pcie0_cfg_fc_0_cplh),
          .pcie0_cfg_fc_0_cplh_scale(dsp_pcie0_cfg_fc_0_cplh_scale),
          .pcie0_cfg_fc_0_npd(dsp_pcie0_cfg_fc_0_npd),
          .pcie0_cfg_fc_0_npd_scale(dsp_pcie0_cfg_fc_0_npd_scale),
          .pcie0_cfg_fc_0_nph(dsp_pcie0_cfg_fc_0_nph),
          .pcie0_cfg_fc_0_nph_scale(dsp_pcie0_cfg_fc_0_nph_scale),
          .pcie0_cfg_fc_0_pd(dsp_pcie0_cfg_fc_0_pd),
          .pcie0_cfg_fc_0_pd_scale(dsp_pcie0_cfg_fc_0_pd_scale),
          .pcie0_cfg_fc_0_ph(dsp_pcie0_cfg_fc_0_ph),
          .pcie0_cfg_fc_0_ph_scale(dsp_pcie0_cfg_fc_0_ph_scale),
          .pcie0_cfg_fc_0_sel(dsp_pcie0_cfg_fc_0_sel),
          .pcie0_cfg_fc_0_vc_sel(dsp_pcie0_cfg_fc_0_vc_sel),
          .pcie0_cfg_interrupt_0_intx_vector(dsp_pcie0_cfg_interrupt_0_intx_vector),
          .pcie0_cfg_interrupt_0_pending(dsp_pcie0_cfg_interrupt_0_pending),
          .pcie0_cfg_interrupt_0_sent(dsp_pcie0_cfg_interrupt_0_sent),
          .pcie0_cfg_mgmt_0_addr(dsp_pcie0_cfg_mgmt_0_addr),
          .pcie0_cfg_mgmt_0_byte_en(dsp_pcie0_cfg_mgmt_0_byte_en),
          .pcie0_cfg_mgmt_0_debug_access(dsp_pcie0_cfg_mgmt_0_debug_access),
          .pcie0_cfg_mgmt_0_function_number(dsp_pcie0_cfg_mgmt_0_function_number),
          .pcie0_cfg_mgmt_0_read_data(dsp_pcie0_cfg_mgmt_0_read_data),
          .pcie0_cfg_mgmt_0_read_en(dsp_pcie0_cfg_mgmt_0_read_en),
          .pcie0_cfg_mgmt_0_read_write_done(dsp_pcie0_cfg_mgmt_0_read_write_done),
          .pcie0_cfg_mgmt_0_write_data(dsp_pcie0_cfg_mgmt_0_write_data),
          .pcie0_cfg_mgmt_0_write_en(dsp_pcie0_cfg_mgmt_0_write_en),
          .pcie0_cfg_msg_recd_0_recd(dsp_pcie0_cfg_msg_recd_0_recd),
          .pcie0_cfg_msg_recd_0_recd_data(dsp_pcie0_cfg_msg_recd_0_recd_data),
          .pcie0_cfg_msg_recd_0_recd_type(dsp_pcie0_cfg_msg_recd_0_recd_type),
          .pcie0_cfg_msg_tx_0_transmit(dsp_pcie0_cfg_msg_tx_0_transmit),
          .pcie0_cfg_msg_tx_0_transmit_data(dsp_pcie0_cfg_msg_tx_0_transmit_data),
          .pcie0_cfg_msg_tx_0_transmit_done(dsp_pcie0_cfg_msg_tx_0_transmit_done),
          .pcie0_cfg_msg_tx_0_transmit_type(dsp_pcie0_cfg_msg_tx_0_transmit_type),
          .pcie0_cfg_msi_0_attr(dsp_pcie0_cfg_msi_0_attr),
          .pcie0_cfg_msi_0_data(dsp_pcie0_cfg_msi_0_data),
          .pcie0_cfg_msi_0_enable(dsp_pcie0_cfg_msi_0_enable),
          .pcie0_cfg_msi_0_fail(dsp_pcie0_cfg_msi_0_fail),
          .pcie0_cfg_msi_0_function_number(dsp_pcie0_cfg_msi_0_function_number),
          .pcie0_cfg_msi_0_int_vector(dsp_pcie0_cfg_msi_0_int_vector),
          .pcie0_cfg_msi_0_mask_update(dsp_pcie0_cfg_msi_0_mask_update),
          .pcie0_cfg_msi_0_mmenable(dsp_pcie0_cfg_msi_0_mmenable),
          .pcie0_cfg_msi_0_pending_status(dsp_pcie0_cfg_msi_0_pending_status),
          .pcie0_cfg_msi_0_pending_status_data_enable(dsp_pcie0_cfg_msi_0_pending_status_data_enable),
          .pcie0_cfg_msi_0_pending_status_function_num(dsp_pcie0_cfg_msi_0_pending_status_function_num),
          .pcie0_cfg_msi_0_select(dsp_pcie0_cfg_msi_0_select),
          .pcie0_cfg_msi_0_sent(dsp_pcie0_cfg_msi_0_sent),
          .pcie0_cfg_msi_0_tph_present(dsp_pcie0_cfg_msi_0_tph_present),
          .pcie0_cfg_msi_0_tph_st_tag(dsp_pcie0_cfg_msi_0_tph_st_tag),
          .pcie0_cfg_msi_0_tph_type(dsp_pcie0_cfg_msi_0_tph_type),
          .pcie0_cfg_status_0_10b_tag_requester_enable(dsp_pcie0_cfg_status_0_10b_tag_requester_enable),
          .pcie0_cfg_status_0_atomic_requester_enable(dsp_pcie0_cfg_status_0_atomic_requester_enable),
          .pcie0_cfg_status_0_bus_number(dsp_pcie0_cfg_status_0_bus_number),
          .pcie0_cfg_status_0_cq_np_req(dsp_pcie0_cfg_status_0_cq_np_req),
          .pcie0_cfg_status_0_cq_np_req_count(dsp_pcie0_cfg_status_0_cq_np_req_count),
          .pcie0_cfg_status_0_current_speed(dsp_pcie0_cfg_status_0_current_speed),
          .pcie0_cfg_status_0_err_cor_out(dsp_pcie0_cfg_status_0_err_cor_out),
          .pcie0_cfg_status_0_err_fatal_out(dsp_pcie0_cfg_status_0_err_fatal_out),
          .pcie0_cfg_status_0_err_nonfatal_out(dsp_pcie0_cfg_status_0_err_nonfatal_out),
          .pcie0_cfg_status_0_ext_tag_enable(dsp_pcie0_cfg_status_0_ext_tag_enable),
          .pcie0_cfg_status_0_function_power_state(dsp_pcie0_cfg_status_0_function_power_state),
          .pcie0_cfg_status_0_function_status(dsp_pcie0_cfg_status_0_function_status),
          .pcie0_cfg_status_0_link_power_state(dsp_pcie0_cfg_status_0_link_power_state),
          .pcie0_cfg_status_0_local_error_out(dsp_pcie0_cfg_status_0_local_error_out),
          .pcie0_cfg_status_0_local_error_valid(dsp_pcie0_cfg_status_0_local_error_valid),
          .pcie0_cfg_status_0_ltssm_state(dsp_pcie0_cfg_status_0_ltssm_state),
          .pcie0_cfg_status_0_max_payload(dsp_pcie0_cfg_status_0_max_payload),
          .pcie0_cfg_status_0_max_read_req(dsp_pcie0_cfg_status_0_max_read_req),
          .pcie0_cfg_status_0_negotiated_width(dsp_pcie0_cfg_status_0_negotiated_width),
          .pcie0_cfg_status_0_pasid_enable(dsp_pcie0_cfg_status_0_pasid_enable),
          .pcie0_cfg_status_0_pasid_exec_permission_enable(dsp_pcie0_cfg_status_0_pasid_exec_permission_enable),
          .pcie0_cfg_status_0_pasid_privil_mode_enable(dsp_pcie0_cfg_status_0_pasid_privil_mode_enable),
          .pcie0_cfg_status_0_per_function_out(dsp_pcie0_cfg_status_0_per_function_out),
          .pcie0_cfg_status_0_per_function_vld(dsp_pcie0_cfg_status_0_per_function_vld),
          .pcie0_cfg_status_0_phy_link_down(dsp_pcie0_cfg_status_0_phy_link_down),
          .pcie0_cfg_status_0_phy_link_status(dsp_pcie0_cfg_status_0_phy_link_status),
          .pcie0_cfg_status_0_pl_status_change(dsp_pcie0_cfg_status_0_pl_status_change),
          .pcie0_cfg_status_0_rcb_status(dsp_pcie0_cfg_status_0_rcb_status),
          .pcie0_cfg_status_0_rq_seq_num0(dsp_pcie0_cfg_status_0_rq_seq_num0),
          .pcie0_cfg_status_0_rq_seq_num1(dsp_pcie0_cfg_status_0_rq_seq_num1),
          .pcie0_cfg_status_0_rq_seq_num2(dsp_pcie0_cfg_status_0_rq_seq_num2),
          .pcie0_cfg_status_0_rq_seq_num3(dsp_pcie0_cfg_status_0_rq_seq_num3),
          .pcie0_cfg_status_0_rq_seq_num_vld0(dsp_pcie0_cfg_status_0_rq_seq_num_vld0),
          .pcie0_cfg_status_0_rq_seq_num_vld1(dsp_pcie0_cfg_status_0_rq_seq_num_vld1),
          .pcie0_cfg_status_0_rq_seq_num_vld2(dsp_pcie0_cfg_status_0_rq_seq_num_vld2),
          .pcie0_cfg_status_0_rq_seq_num_vld3(dsp_pcie0_cfg_status_0_rq_seq_num_vld3),
          .pcie0_cfg_status_0_rq_tag0(dsp_pcie0_cfg_status_0_rq_tag0),
          .pcie0_cfg_status_0_rq_tag1(dsp_pcie0_cfg_status_0_rq_tag1),
          .pcie0_cfg_status_0_rq_tag_av(dsp_pcie0_cfg_status_0_rq_tag_av),
          .pcie0_cfg_status_0_rq_tag_vld0(dsp_pcie0_cfg_status_0_rq_tag_vld0),
          .pcie0_cfg_status_0_rq_tag_vld1(dsp_pcie0_cfg_status_0_rq_tag_vld1),
          .pcie0_cfg_status_0_rx_pm_state(dsp_pcie0_cfg_status_0_rx_pm_state),
          .pcie0_cfg_status_0_tph_requester_enable(dsp_pcie0_cfg_status_0_tph_requester_enable),
          .pcie0_cfg_status_0_tph_st_mode(dsp_pcie0_cfg_status_0_tph_st_mode),
          .pcie0_cfg_status_0_tx_pm_state(dsp_pcie0_cfg_status_0_tx_pm_state),
          .pcie0_cfg_status_0_wrreq_bme_vld(dsp_pcie0_cfg_status_0_wrreq_bme_vld),
          .pcie0_cfg_status_0_wrreq_flr_vld(dsp_pcie0_cfg_status_0_wrreq_flr_vld),
          .pcie0_cfg_status_0_wrreq_function_number(dsp_pcie0_cfg_status_0_wrreq_function_number),
          .pcie0_cfg_status_0_wrreq_msi_vld(dsp_pcie0_cfg_status_0_wrreq_msi_vld),
          .pcie0_cfg_status_0_wrreq_msix_vld(dsp_pcie0_cfg_status_0_wrreq_msix_vld),
          .pcie0_cfg_status_0_wrreq_out_value(dsp_pcie0_cfg_status_0_wrreq_out_value),
          .pcie0_cfg_status_0_wrreq_vfe_vld(dsp_pcie0_cfg_status_0_wrreq_vfe_vld),
          .pcie0_m_axis_cq_0_tdata(dsp_pcie0_m_axis_cq_0_tdata),
          .pcie0_m_axis_cq_0_tkeep(dsp_pcie0_m_axis_cq_0_tkeep),
          .pcie0_m_axis_cq_0_tlast(dsp_pcie0_m_axis_cq_0_tlast),
          .pcie0_m_axis_cq_0_tready(dsp_pcie0_m_axis_cq_0_tready),
          .pcie0_m_axis_cq_0_tuser(dsp_pcie0_m_axis_cq_0_tuser),
          .pcie0_m_axis_cq_0_tvalid(dsp_pcie0_m_axis_cq_0_tvalid),
          .pcie0_m_axis_rc_0_tdata(dsp_pcie0_m_axis_rc_0_tdata),
          .pcie0_m_axis_rc_0_tkeep(dsp_pcie0_m_axis_rc_0_tkeep),
          .pcie0_m_axis_rc_0_tlast(dsp_pcie0_m_axis_rc_0_tlast),
          .pcie0_m_axis_rc_0_tready(dsp_pcie0_m_axis_rc_0_tready),
          .pcie0_m_axis_rc_0_tuser(dsp_pcie0_m_axis_rc_0_tuser),
          .pcie0_m_axis_rc_0_tvalid(dsp_pcie0_m_axis_rc_0_tvalid),
          .pcie0_s_axis_cc_0_tdata(dsp_pcie0_s_axis_cc_0_tdata),
          .pcie0_s_axis_cc_0_tkeep(dsp_pcie0_s_axis_cc_0_tkeep),
          .pcie0_s_axis_cc_0_tlast(dsp_pcie0_s_axis_cc_0_tlast),
          .pcie0_s_axis_cc_0_tready(dsp_pcie0_s_axis_cc_0_tready),
          .pcie0_s_axis_cc_0_tuser(dsp_pcie0_s_axis_cc_0_tuser),
          .pcie0_s_axis_cc_0_tvalid(dsp_pcie0_s_axis_cc_0_tvalid),
          .pcie0_s_axis_rq_0_tdata(dsp_pcie0_s_axis_rq_0_tdata),
          .pcie0_s_axis_rq_0_tkeep(dsp_pcie0_s_axis_rq_0_tkeep),
          .pcie0_s_axis_rq_0_tlast(dsp_pcie0_s_axis_rq_0_tlast),
          .pcie0_s_axis_rq_0_tready(dsp_pcie0_s_axis_rq_0_tready),
          .pcie0_s_axis_rq_0_tuser(dsp_pcie0_s_axis_rq_0_tuser),
          .pcie0_s_axis_rq_0_tvalid(dsp_pcie0_s_axis_rq_0_tvalid),
          .pcie0_transmit_fc_0_npd_av(dsp_pcie0_transmit_fc_0_npd_av),
          .pcie0_transmit_fc_0_nph_av(dsp_pcie0_transmit_fc_0_nph_av),
          .pcie0_user_clk_0(dsp_pcie0_user_clk_0),
          .pcie0_user_lnk_up_0(dsp_pcie0_user_lnk_up_0),
          .pcie0_user_reset_0(dsp_pcie0_user_reset_0),
          .pcie0_pipe_rp_0_commands_in(dsp_pcie0_pipe_rp_0_commands_out),
          .pcie0_pipe_rp_0_commands_out(dsp_pcie0_pipe_rp_0_commands_in),
          .pcie0_pipe_rp_0_rx_0(dsp_pcie0_pipe_rp_0_tx_0),
          .pcie0_pipe_rp_0_rx_1(dsp_pcie0_pipe_rp_0_tx_1),
          .pcie0_pipe_rp_0_rx_10(dsp_pcie0_pipe_rp_0_tx_10),
          .pcie0_pipe_rp_0_rx_11(dsp_pcie0_pipe_rp_0_tx_11),
          .pcie0_pipe_rp_0_rx_12(dsp_pcie0_pipe_rp_0_tx_12),
          .pcie0_pipe_rp_0_rx_13(dsp_pcie0_pipe_rp_0_tx_13),
          .pcie0_pipe_rp_0_rx_14(dsp_pcie0_pipe_rp_0_tx_14),
          .pcie0_pipe_rp_0_rx_15(dsp_pcie0_pipe_rp_0_tx_15),
          .pcie0_pipe_rp_0_rx_2(dsp_pcie0_pipe_rp_0_tx_2),
          .pcie0_pipe_rp_0_rx_3(dsp_pcie0_pipe_rp_0_tx_3),
          .pcie0_pipe_rp_0_rx_4(dsp_pcie0_pipe_rp_0_tx_4),
          .pcie0_pipe_rp_0_rx_5(dsp_pcie0_pipe_rp_0_tx_5),
          .pcie0_pipe_rp_0_rx_6(dsp_pcie0_pipe_rp_0_tx_6),
          .pcie0_pipe_rp_0_rx_7(dsp_pcie0_pipe_rp_0_tx_7),
          .pcie0_pipe_rp_0_rx_8(dsp_pcie0_pipe_rp_0_tx_8),
          .pcie0_pipe_rp_0_rx_9(dsp_pcie0_pipe_rp_0_tx_9),
          .pcie0_pipe_rp_0_tx_0(dsp_pcie0_pipe_rp_0_rx_0),
          .pcie0_pipe_rp_0_tx_1(dsp_pcie0_pipe_rp_0_rx_1),
          .pcie0_pipe_rp_0_tx_10(dsp_pcie0_pipe_rp_0_rx_10),
          .pcie0_pipe_rp_0_tx_11(dsp_pcie0_pipe_rp_0_rx_11),
          .pcie0_pipe_rp_0_tx_12(dsp_pcie0_pipe_rp_0_rx_12),
          .pcie0_pipe_rp_0_tx_13(dsp_pcie0_pipe_rp_0_rx_13),
          .pcie0_pipe_rp_0_tx_14(dsp_pcie0_pipe_rp_0_rx_14),
          .pcie0_pipe_rp_0_tx_15(dsp_pcie0_pipe_rp_0_rx_15),
          .pcie0_pipe_rp_0_tx_2(dsp_pcie0_pipe_rp_0_rx_2),
          .pcie0_pipe_rp_0_tx_3(dsp_pcie0_pipe_rp_0_rx_3),
          .pcie0_pipe_rp_0_tx_4(dsp_pcie0_pipe_rp_0_rx_4),
          .pcie0_pipe_rp_0_tx_5(dsp_pcie0_pipe_rp_0_rx_5),
          .pcie0_pipe_rp_0_tx_6(dsp_pcie0_pipe_rp_0_rx_6),
          .pcie0_pipe_rp_0_tx_7(dsp_pcie0_pipe_rp_0_rx_7),
          .pcie0_pipe_rp_0_tx_8(dsp_pcie0_pipe_rp_0_rx_8),
          .pcie0_pipe_rp_0_tx_9(dsp_pcie0_pipe_rp_0_rx_9)
      );
    end else begin : gen_ext_pipe_sim_dsp
      dsp_cips switch_dsp (
          .PCIE0_GT_0_grx_n(dsp_PCIE0_GT_grx_n),
          .PCIE0_GT_0_grx_p(dsp_PCIE0_GT_grx_p),
          .PCIE0_GT_0_gtx_n(dsp_PCIE0_GT_gtx_n),
          .PCIE0_GT_0_gtx_p(dsp_PCIE0_GT_gtx_p),
          .cpm_cor_irq_0(dsp_cpm_cor_irq_0),
          .cpm_irq0_0(dsp_cpm_irq0_0),
          .cpm_irq1_0(dsp_cpm_irq1_0),
          .cpm_misc_irq_0(dsp_cpm_misc_irq_0),
          .cpm_uncor_irq_0(dsp_cpm_uncor_irq_0),
          .gt_refclk0_0_clk_n(dsp_gt_refclk0_clk_n),
          .gt_refclk0_0_clk_p(dsp_gt_refclk0_clk_p),
          .pcie0_cfg_control_0_err_cor_in(dsp_pcie0_cfg_control_0_err_cor_in),
          .pcie0_cfg_control_0_err_uncor_in(dsp_pcie0_cfg_control_0_err_uncor_in),
          .pcie0_cfg_control_0_flr_done(dsp_pcie0_cfg_control_0_flr_done),
          .pcie0_cfg_control_0_flr_done_function_number(dsp_pcie0_cfg_control_0_flr_done_function_number),
          .pcie0_cfg_control_0_flr_in_process(dsp_pcie0_cfg_control_0_flr_in_process),
          .pcie0_cfg_control_0_hot_reset_in(dsp_pcie0_cfg_control_0_hot_reset_in),
          .pcie0_cfg_control_0_hot_reset_out(dsp_pcie0_cfg_control_0_hot_reset_out),
          .pcie0_cfg_control_0_per_function_number(dsp_pcie0_cfg_control_0_per_function_number),
          .pcie0_cfg_control_0_per_function_req(dsp_pcie0_cfg_control_0_per_function_req),
          .pcie0_cfg_control_0_power_state_change_ack(dsp_pcie0_cfg_control_0_power_state_change_ack),
          .pcie0_cfg_control_0_power_state_change_interrupt(dsp_pcie0_cfg_control_0_power_state_change_interrupt),
          .pcie0_cfg_ext_0_function_number(dsp_pcie0_cfg_ext_0_function_number),
          .pcie0_cfg_ext_0_read_data(dsp_pcie0_cfg_ext_0_read_data),
          .pcie0_cfg_ext_0_read_data_valid(dsp_pcie0_cfg_ext_0_read_data_valid),
          .pcie0_cfg_ext_0_read_received(dsp_pcie0_cfg_ext_0_read_received),
          .pcie0_cfg_ext_0_register_number(dsp_pcie0_cfg_ext_0_register_number),
          .pcie0_cfg_ext_0_write_byte_enable(dsp_pcie0_cfg_ext_0_write_byte_enable),
          .pcie0_cfg_ext_0_write_data(dsp_pcie0_cfg_ext_0_write_data),
          .pcie0_cfg_ext_0_write_received(dsp_pcie0_cfg_ext_0_write_received),
          .pcie0_cfg_fc_0_cpld(dsp_pcie0_cfg_fc_0_cpld),
          .pcie0_cfg_fc_0_cpld_scale(dsp_pcie0_cfg_fc_0_cpld_scale),
          .pcie0_cfg_fc_0_cplh(dsp_pcie0_cfg_fc_0_cplh),
          .pcie0_cfg_fc_0_cplh_scale(dsp_pcie0_cfg_fc_0_cplh_scale),
          .pcie0_cfg_fc_0_npd(dsp_pcie0_cfg_fc_0_npd),
          .pcie0_cfg_fc_0_npd_scale(dsp_pcie0_cfg_fc_0_npd_scale),
          .pcie0_cfg_fc_0_nph(dsp_pcie0_cfg_fc_0_nph),
          .pcie0_cfg_fc_0_nph_scale(dsp_pcie0_cfg_fc_0_nph_scale),
          .pcie0_cfg_fc_0_pd(dsp_pcie0_cfg_fc_0_pd),
          .pcie0_cfg_fc_0_pd_scale(dsp_pcie0_cfg_fc_0_pd_scale),
          .pcie0_cfg_fc_0_ph(dsp_pcie0_cfg_fc_0_ph),
          .pcie0_cfg_fc_0_ph_scale(dsp_pcie0_cfg_fc_0_ph_scale),
          .pcie0_cfg_fc_0_sel(dsp_pcie0_cfg_fc_0_sel),
          .pcie0_cfg_fc_0_vc_sel(dsp_pcie0_cfg_fc_0_vc_sel),
          .pcie0_cfg_interrupt_0_intx_vector(dsp_pcie0_cfg_interrupt_0_intx_vector),
          .pcie0_cfg_interrupt_0_pending(dsp_pcie0_cfg_interrupt_0_pending),
          .pcie0_cfg_interrupt_0_sent(dsp_pcie0_cfg_interrupt_0_sent),
          .pcie0_cfg_mgmt_0_addr(dsp_pcie0_cfg_mgmt_0_addr),
          .pcie0_cfg_mgmt_0_byte_en(dsp_pcie0_cfg_mgmt_0_byte_en),
          .pcie0_cfg_mgmt_0_debug_access(dsp_pcie0_cfg_mgmt_0_debug_access),
          .pcie0_cfg_mgmt_0_function_number(dsp_pcie0_cfg_mgmt_0_function_number),
          .pcie0_cfg_mgmt_0_read_data(dsp_pcie0_cfg_mgmt_0_read_data),
          .pcie0_cfg_mgmt_0_read_en(dsp_pcie0_cfg_mgmt_0_read_en),
          .pcie0_cfg_mgmt_0_read_write_done(dsp_pcie0_cfg_mgmt_0_read_write_done),
          .pcie0_cfg_mgmt_0_write_data(dsp_pcie0_cfg_mgmt_0_write_data),
          .pcie0_cfg_mgmt_0_write_en(dsp_pcie0_cfg_mgmt_0_write_en),
          .pcie0_cfg_msg_recd_0_recd(dsp_pcie0_cfg_msg_recd_0_recd),
          .pcie0_cfg_msg_recd_0_recd_data(dsp_pcie0_cfg_msg_recd_0_recd_data),
          .pcie0_cfg_msg_recd_0_recd_type(dsp_pcie0_cfg_msg_recd_0_recd_type),
          .pcie0_cfg_msg_tx_0_transmit(dsp_pcie0_cfg_msg_tx_0_transmit),
          .pcie0_cfg_msg_tx_0_transmit_data(dsp_pcie0_cfg_msg_tx_0_transmit_data),
          .pcie0_cfg_msg_tx_0_transmit_done(dsp_pcie0_cfg_msg_tx_0_transmit_done),
          .pcie0_cfg_msg_tx_0_transmit_type(dsp_pcie0_cfg_msg_tx_0_transmit_type),
          .pcie0_cfg_msi_0_attr(dsp_pcie0_cfg_msi_0_attr),
          .pcie0_cfg_msi_0_data(dsp_pcie0_cfg_msi_0_data),
          .pcie0_cfg_msi_0_enable(dsp_pcie0_cfg_msi_0_enable),
          .pcie0_cfg_msi_0_fail(dsp_pcie0_cfg_msi_0_fail),
          .pcie0_cfg_msi_0_function_number(dsp_pcie0_cfg_msi_0_function_number),
          .pcie0_cfg_msi_0_int_vector(dsp_pcie0_cfg_msi_0_int_vector),
          .pcie0_cfg_msi_0_mask_update(dsp_pcie0_cfg_msi_0_mask_update),
          .pcie0_cfg_msi_0_mmenable(dsp_pcie0_cfg_msi_0_mmenable),
          .pcie0_cfg_msi_0_pending_status(dsp_pcie0_cfg_msi_0_pending_status),
          .pcie0_cfg_msi_0_pending_status_data_enable(dsp_pcie0_cfg_msi_0_pending_status_data_enable),
          .pcie0_cfg_msi_0_pending_status_function_num(dsp_pcie0_cfg_msi_0_pending_status_function_num),
          .pcie0_cfg_msi_0_select(dsp_pcie0_cfg_msi_0_select),
          .pcie0_cfg_msi_0_sent(dsp_pcie0_cfg_msi_0_sent),
          .pcie0_cfg_msi_0_tph_present(dsp_pcie0_cfg_msi_0_tph_present),
          .pcie0_cfg_msi_0_tph_st_tag(dsp_pcie0_cfg_msi_0_tph_st_tag),
          .pcie0_cfg_msi_0_tph_type(dsp_pcie0_cfg_msi_0_tph_type),
          .pcie0_cfg_status_0_10b_tag_requester_enable(dsp_pcie0_cfg_status_0_10b_tag_requester_enable),
          .pcie0_cfg_status_0_atomic_requester_enable(dsp_pcie0_cfg_status_0_atomic_requester_enable),
          .pcie0_cfg_status_0_bus_number(dsp_pcie0_cfg_status_0_bus_number),
          .pcie0_cfg_status_0_cq_np_req(dsp_pcie0_cfg_status_0_cq_np_req),
          .pcie0_cfg_status_0_cq_np_req_count(dsp_pcie0_cfg_status_0_cq_np_req_count),
          .pcie0_cfg_status_0_current_speed(dsp_pcie0_cfg_status_0_current_speed),
          .pcie0_cfg_status_0_err_cor_out(dsp_pcie0_cfg_status_0_err_cor_out),
          .pcie0_cfg_status_0_err_fatal_out(dsp_pcie0_cfg_status_0_err_fatal_out),
          .pcie0_cfg_status_0_err_nonfatal_out(dsp_pcie0_cfg_status_0_err_nonfatal_out),
          .pcie0_cfg_status_0_ext_tag_enable(dsp_pcie0_cfg_status_0_ext_tag_enable),
          .pcie0_cfg_status_0_function_power_state(dsp_pcie0_cfg_status_0_function_power_state),
          .pcie0_cfg_status_0_function_status(dsp_pcie0_cfg_status_0_function_status),
          .pcie0_cfg_status_0_link_power_state(dsp_pcie0_cfg_status_0_link_power_state),
          .pcie0_cfg_status_0_local_error_out(dsp_pcie0_cfg_status_0_local_error_out),
          .pcie0_cfg_status_0_local_error_valid(dsp_pcie0_cfg_status_0_local_error_valid),
          .pcie0_cfg_status_0_ltssm_state(dsp_pcie0_cfg_status_0_ltssm_state),
          .pcie0_cfg_status_0_max_payload(dsp_pcie0_cfg_status_0_max_payload),
          .pcie0_cfg_status_0_max_read_req(dsp_pcie0_cfg_status_0_max_read_req),
          .pcie0_cfg_status_0_negotiated_width(dsp_pcie0_cfg_status_0_negotiated_width),
          .pcie0_cfg_status_0_pasid_enable(dsp_pcie0_cfg_status_0_pasid_enable),
          .pcie0_cfg_status_0_pasid_exec_permission_enable(dsp_pcie0_cfg_status_0_pasid_exec_permission_enable),
          .pcie0_cfg_status_0_pasid_privil_mode_enable(dsp_pcie0_cfg_status_0_pasid_privil_mode_enable),
          .pcie0_cfg_status_0_per_function_out(dsp_pcie0_cfg_status_0_per_function_out),
          .pcie0_cfg_status_0_per_function_vld(dsp_pcie0_cfg_status_0_per_function_vld),
          .pcie0_cfg_status_0_phy_link_down(dsp_pcie0_cfg_status_0_phy_link_down),
          .pcie0_cfg_status_0_phy_link_status(dsp_pcie0_cfg_status_0_phy_link_status),
          .pcie0_cfg_status_0_pl_status_change(dsp_pcie0_cfg_status_0_pl_status_change),
          .pcie0_cfg_status_0_rcb_status(dsp_pcie0_cfg_status_0_rcb_status),
          .pcie0_cfg_status_0_rq_seq_num0(dsp_pcie0_cfg_status_0_rq_seq_num0),
          .pcie0_cfg_status_0_rq_seq_num1(dsp_pcie0_cfg_status_0_rq_seq_num1),
          .pcie0_cfg_status_0_rq_seq_num2(dsp_pcie0_cfg_status_0_rq_seq_num2),
          .pcie0_cfg_status_0_rq_seq_num3(dsp_pcie0_cfg_status_0_rq_seq_num3),
          .pcie0_cfg_status_0_rq_seq_num_vld0(dsp_pcie0_cfg_status_0_rq_seq_num_vld0),
          .pcie0_cfg_status_0_rq_seq_num_vld1(dsp_pcie0_cfg_status_0_rq_seq_num_vld1),
          .pcie0_cfg_status_0_rq_seq_num_vld2(dsp_pcie0_cfg_status_0_rq_seq_num_vld2),
          .pcie0_cfg_status_0_rq_seq_num_vld3(dsp_pcie0_cfg_status_0_rq_seq_num_vld3),
          .pcie0_cfg_status_0_rq_tag0(dsp_pcie0_cfg_status_0_rq_tag0),
          .pcie0_cfg_status_0_rq_tag1(dsp_pcie0_cfg_status_0_rq_tag1),
          .pcie0_cfg_status_0_rq_tag_av(dsp_pcie0_cfg_status_0_rq_tag_av),
          .pcie0_cfg_status_0_rq_tag_vld0(dsp_pcie0_cfg_status_0_rq_tag_vld0),
          .pcie0_cfg_status_0_rq_tag_vld1(dsp_pcie0_cfg_status_0_rq_tag_vld1),
          .pcie0_cfg_status_0_rx_pm_state(dsp_pcie0_cfg_status_0_rx_pm_state),
          .pcie0_cfg_status_0_tph_requester_enable(dsp_pcie0_cfg_status_0_tph_requester_enable),
          .pcie0_cfg_status_0_tph_st_mode(dsp_pcie0_cfg_status_0_tph_st_mode),
          .pcie0_cfg_status_0_tx_pm_state(dsp_pcie0_cfg_status_0_tx_pm_state),
          .pcie0_cfg_status_0_wrreq_bme_vld(dsp_pcie0_cfg_status_0_wrreq_bme_vld),
          .pcie0_cfg_status_0_wrreq_flr_vld(dsp_pcie0_cfg_status_0_wrreq_flr_vld),
          .pcie0_cfg_status_0_wrreq_function_number(dsp_pcie0_cfg_status_0_wrreq_function_number),
          .pcie0_cfg_status_0_wrreq_msi_vld(dsp_pcie0_cfg_status_0_wrreq_msi_vld),
          .pcie0_cfg_status_0_wrreq_msix_vld(dsp_pcie0_cfg_status_0_wrreq_msix_vld),
          .pcie0_cfg_status_0_wrreq_out_value(dsp_pcie0_cfg_status_0_wrreq_out_value),
          .pcie0_cfg_status_0_wrreq_vfe_vld(dsp_pcie0_cfg_status_0_wrreq_vfe_vld),
          .pcie0_m_axis_cq_0_tdata(dsp_pcie0_m_axis_cq_0_tdata),
          .pcie0_m_axis_cq_0_tkeep(dsp_pcie0_m_axis_cq_0_tkeep),
          .pcie0_m_axis_cq_0_tlast(dsp_pcie0_m_axis_cq_0_tlast),
          .pcie0_m_axis_cq_0_tready(dsp_pcie0_m_axis_cq_0_tready),
          .pcie0_m_axis_cq_0_tuser(dsp_pcie0_m_axis_cq_0_tuser),
          .pcie0_m_axis_cq_0_tvalid(dsp_pcie0_m_axis_cq_0_tvalid),
          .pcie0_m_axis_rc_0_tdata(dsp_pcie0_m_axis_rc_0_tdata),
          .pcie0_m_axis_rc_0_tkeep(dsp_pcie0_m_axis_rc_0_tkeep),
          .pcie0_m_axis_rc_0_tlast(dsp_pcie0_m_axis_rc_0_tlast),
          .pcie0_m_axis_rc_0_tready(dsp_pcie0_m_axis_rc_0_tready),
          .pcie0_m_axis_rc_0_tuser(dsp_pcie0_m_axis_rc_0_tuser),
          .pcie0_m_axis_rc_0_tvalid(dsp_pcie0_m_axis_rc_0_tvalid),
          .pcie0_s_axis_cc_0_tdata(dsp_pcie0_s_axis_cc_0_tdata),
          .pcie0_s_axis_cc_0_tkeep(dsp_pcie0_s_axis_cc_0_tkeep),
          .pcie0_s_axis_cc_0_tlast(dsp_pcie0_s_axis_cc_0_tlast),
          .pcie0_s_axis_cc_0_tready(dsp_pcie0_s_axis_cc_0_tready),
          .pcie0_s_axis_cc_0_tuser(dsp_pcie0_s_axis_cc_0_tuser),
          .pcie0_s_axis_cc_0_tvalid(dsp_pcie0_s_axis_cc_0_tvalid),
          .pcie0_s_axis_rq_0_tdata(dsp_pcie0_s_axis_rq_0_tdata),
          .pcie0_s_axis_rq_0_tkeep(dsp_pcie0_s_axis_rq_0_tkeep),
          .pcie0_s_axis_rq_0_tlast(dsp_pcie0_s_axis_rq_0_tlast),
          .pcie0_s_axis_rq_0_tready(dsp_pcie0_s_axis_rq_0_tready),
          .pcie0_s_axis_rq_0_tuser(dsp_pcie0_s_axis_rq_0_tuser),
          .pcie0_s_axis_rq_0_tvalid(dsp_pcie0_s_axis_rq_0_tvalid),
          .pcie0_transmit_fc_0_npd_av(dsp_pcie0_transmit_fc_0_npd_av),
          .pcie0_transmit_fc_0_nph_av(dsp_pcie0_transmit_fc_0_nph_av),
          .pcie0_user_clk_0(dsp_pcie0_user_clk_0),
          .pcie0_user_lnk_up_0(dsp_pcie0_user_lnk_up_0),
          .pcie0_user_reset_0(dsp_pcie0_user_reset_0)
      );
    end
  endgenerate

  // Switch Logic
  switch_logic #(
      .TCQ(TCQ),
      .DSP_IF_WIDTH(DSP_IF_WIDTH),
      .DSP_RQ_TUSER_WIDTH(DSP_RQ_TUSER_WIDTH),
      .DSP_RC_TUSER_WIDTH(DSP_RC_TUSER_WIDTH),
      .DSP_CQ_TUSER_WIDTH(DSP_CQ_TUSER_WIDTH),
      .DSP_CC_TUSER_WIDTH(DSP_CC_TUSER_WIDTH),
      .DSP_TKEEP_WIDTH(DSP_TKEEP_WIDTH),
      .USP_RQ_TUSER_WIDTH(USP_RQ_TUSER_WIDTH),
      .USP_RC_TUSER_WIDTH(USP_RC_TUSER_WIDTH),
      .USP_CQ_TUSER_WIDTH(USP_CQ_TUSER_WIDTH),
      .USP_CC_TUSER_WIDTH(USP_CC_TUSER_WIDTH),
      .USP_TKEEP_WIDTH(USP_TKEEP_WIDTH)
  ) switch_logic_main (
      // Downstream Port Connections
      .dsp_s_axis_rq_tdata (dsp_pcie0_s_axis_rq_0_tdata),
      .dsp_s_axis_rq_tkeep (dsp_pcie0_s_axis_rq_0_tkeep),
      .dsp_s_axis_rq_tlast (dsp_pcie0_s_axis_rq_0_tlast),
      .dsp_s_axis_rq_tready(dsp_pcie0_s_axis_rq_0_tready),
      .dsp_s_axis_rq_tuser (dsp_pcie0_s_axis_rq_0_tuser),
      .dsp_s_axis_rq_tvalid(dsp_pcie0_s_axis_rq_0_tvalid),

      .dsp_m_axis_rc_tdata (dsp_pcie0_m_axis_rc_0_tdata),
      .dsp_m_axis_rc_tkeep (dsp_pcie0_m_axis_rc_0_tkeep),
      .dsp_m_axis_rc_tlast (dsp_pcie0_m_axis_rc_0_tlast),
      .dsp_m_axis_rc_tready(dsp_pcie0_m_axis_rc_0_tready),
      .dsp_m_axis_rc_tuser (dsp_pcie0_m_axis_rc_0_tuser),
      .dsp_m_axis_rc_tvalid(dsp_pcie0_m_axis_rc_0_tvalid),

      .dsp_m_axis_cq_tdata (dsp_pcie0_m_axis_cq_0_tdata),
      .dsp_m_axis_cq_tkeep (dsp_pcie0_m_axis_cq_0_tkeep),
      .dsp_m_axis_cq_tlast (dsp_pcie0_m_axis_cq_0_tlast),
      .dsp_m_axis_cq_tready(dsp_pcie0_m_axis_cq_0_tready),
      .dsp_m_axis_cq_tuser (dsp_pcie0_m_axis_cq_0_tuser),
      .dsp_m_axis_cq_tvalid(dsp_pcie0_m_axis_cq_0_tvalid),

      .dsp_s_axis_cc_tdata (dsp_pcie0_s_axis_cc_0_tdata),
      .dsp_s_axis_cc_tkeep (dsp_pcie0_s_axis_cc_0_tkeep),
      .dsp_s_axis_cc_tlast (dsp_pcie0_s_axis_cc_0_tlast),
      .dsp_s_axis_cc_tready(dsp_pcie0_s_axis_cc_0_tready),
      .dsp_s_axis_cc_tuser (dsp_pcie0_s_axis_cc_0_tuser),
      .dsp_s_axis_cc_tvalid(dsp_pcie0_s_axis_cc_0_tvalid),

      // Upstream Port Connections
      .usp_s_axis_rq_tready(usp_s_axis_rq_tready),
      .usp_s_axis_rq_tdata (usp_s_axis_rq_tdata),
      .usp_s_axis_rq_tkeep (usp_s_axis_rq_tkeep),
      .usp_s_axis_rq_tlast (usp_s_axis_rq_tlast),
      .usp_s_axis_rq_tuser (usp_s_axis_rq_tuser),
      .usp_s_axis_rq_tvalid(usp_s_axis_rq_tvalid),

      .usp_s_axis_cc_tready(usp_s_axis_cc_tready),
      .usp_s_axis_cc_tdata (usp_s_axis_cc_tdata),
      .usp_s_axis_cc_tkeep (usp_s_axis_cc_tkeep),
      .usp_s_axis_cc_tlast (usp_s_axis_cc_tlast),
      .usp_s_axis_cc_tuser (usp_s_axis_cc_tuser),
      .usp_s_axis_cc_tvalid(usp_s_axis_cc_tvalid),

      .usp_m_axis_rc_tdata (usp_m_axis_rc_tdata),
      .usp_m_axis_rc_tkeep (usp_m_axis_rc_tkeep),
      .usp_m_axis_rc_tlast (usp_m_axis_rc_tlast),
      .usp_m_axis_rc_tready(usp_m_axis_rc_tready),
      .usp_m_axis_rc_tuser (usp_m_axis_rc_tuser),
      .usp_m_axis_rc_tvalid(usp_m_axis_rc_tvalid),

      .usp_m_axis_cq_tdata (usp_m_axis_cq_tdata),
      .usp_m_axis_cq_tkeep (usp_m_axis_cq_tkeep),
      .usp_m_axis_cq_tlast (usp_m_axis_cq_tlast),
      .usp_m_axis_cq_tready(usp_m_axis_cq_tready),
      .usp_m_axis_cq_tuser (usp_m_axis_cq_tuser),
      .usp_m_axis_cq_tvalid(usp_m_axis_cq_tvalid),

      // Configuration Extended Interface (USP) (for snooping bus numbers)
      .cfg_ext_write_received(usp_pcie_cfg_ext_write_received),
      .cfg_ext_register_number(usp_pcie_cfg_ext_register_number),
      .cfg_ext_function_number(usp_pcie_cfg_ext_function_number),
      .cfg_ext_write_data(usp_pcie_cfg_ext_write_data),
      .cfg_ext_write_byte_enable(usp_pcie_cfg_ext_write_byte_enable),

      // Configuration Management Interface (DSP) (for Config Requests)
      .cfg_mgmt_addr(dsp_pcie0_cfg_mgmt_0_addr),
      .cfg_mgmt_function_number(dsp_pcie0_cfg_mgmt_0_function_number),
      .cfg_mgmt_write(dsp_pcie0_cfg_mgmt_0_write_en),
      .cfg_mgmt_write_data(dsp_pcie0_cfg_mgmt_0_write_data),
      .cfg_mgmt_byte_enable(dsp_pcie0_cfg_mgmt_0_byte_en),
      .cfg_mgmt_read(dsp_pcie0_cfg_mgmt_0_read_en),
      .cfg_mgmt_read_data(dsp_pcie0_cfg_mgmt_0_read_data),
      .cfg_mgmt_read_write_done(dsp_pcie0_cfg_mgmt_0_read_write_done),
      .cfg_mgmt_debug_access(dsp_pcie0_cfg_mgmt_0_debug_access),

      // Clocks and Reset - Global
      .sys_reset_n(sys_rst_user),

      // Clocks and Reset - USP
      .usp_user_clk  (usp_user_clk),
      .usp_user_reset(usp_user_reset),

      // Clocks and Reset - DSP
      .dsp_user_clk  (dsp_pcie0_user_clk_0),
      .dsp_user_reset(dsp_pcie0_user_reset_0),

      // Misc - DSP
      .dsp_user_lnk_up(&(dsp_pcie0_cfg_status_0_ltssm_state == 6'h10))  // Might need it to check if link is/was up if we need to preserve values to write to DSP. Currently unused
  );

  // USP BD Instantiate
  generate
    if (EXT_PIPE_SIM == "TRUE") begin : gen_ext_pipe_sim_usp
      usp_plpcie switch_usp (
          .ccix_optimized_tlp_tx_and_rx_enable(usp_ccix_optimized_tlp_tx_and_rx_enable),
          .ccix_rx_credit_av(usp_ccix_rx_credit_av),
          .core_clk(usp_core_clk),
          .cxs_rx_active_ack(usp_cxs_rx_active_ack),
          .cxs_rx_active_req(usp_cxs_rx_active_req),
          .cxs_rx_cntl(usp_cxs_rx_cntl),
          .cxs_rx_cntl_chk(usp_cxs_rx_cntl_chk),
          .cxs_rx_crdgnt(usp_cxs_rx_crdgnt),
          .cxs_rx_crdgnt_chk(usp_cxs_rx_crdgnt_chk),
          .cxs_rx_crdrtn(usp_cxs_rx_crdrtn),
          .cxs_rx_crdrtn_chk(usp_cxs_rx_crdrtn_chk),
          .cxs_rx_data(usp_cxs_rx_data),
          .cxs_rx_data_chk(usp_cxs_rx_data_chk),
          .cxs_rx_deact_hint(usp_cxs_rx_deact_hint),
          .cxs_rx_valid(usp_cxs_rx_valid),
          .cxs_rx_valid_chk(usp_cxs_rx_valid_chk),
          .cxs_tx_active_ack(usp_cxs_tx_active_ack),
          .cxs_tx_active_req(usp_cxs_tx_active_req),
          .cxs_tx_cntl(usp_cxs_tx_cntl),
          .cxs_tx_cntl_chk(usp_cxs_tx_cntl_chk),
          .cxs_tx_crdgnt(usp_cxs_tx_crdgnt),
          .cxs_tx_crdgnt_chk(usp_cxs_tx_crdgnt_chk),
          .cxs_tx_crdrtn(usp_cxs_tx_crdrtn),
          .cxs_tx_crdrtn_chk(usp_cxs_tx_crdrtn_chk),
          .cxs_tx_data(usp_cxs_tx_data),
          .cxs_tx_data_chk(usp_cxs_tx_data_chk),
          .cxs_tx_deact_hint(usp_cxs_tx_deact_hint),
          .cxs_tx_valid(usp_cxs_tx_valid),
          .cxs_tx_valid_chk(usp_cxs_tx_valid_chk),
          .m_axis_cq_tdata(usp_m_axis_cq_tdata),
          .m_axis_cq_tkeep(usp_m_axis_cq_tkeep),
          .m_axis_cq_tlast(usp_m_axis_cq_tlast),
          .m_axis_cq_tready(usp_m_axis_cq_tready),
          .m_axis_cq_tuser(usp_m_axis_cq_tuser),
          .m_axis_cq_tvalid(usp_m_axis_cq_tvalid),
          .m_axis_rc_tdata(usp_m_axis_rc_tdata),
          .m_axis_rc_tkeep(usp_m_axis_rc_tkeep),
          .m_axis_rc_tlast(usp_m_axis_rc_tlast),
          .m_axis_rc_tready(usp_m_axis_rc_tready),
          .m_axis_rc_tuser(usp_m_axis_rc_tuser),
          .m_axis_rc_tvalid(usp_m_axis_rc_tvalid),
          .pcie_cfg_control_bus_number(usp_pcie_cfg_control_bus_number),
          .pcie_cfg_control_config_space_enable(usp_pcie_cfg_control_config_space_enable),
          .pcie_cfg_control_ds_bus_number(usp_pcie_cfg_control_ds_bus_number),
          .pcie_cfg_control_ds_device_number(usp_pcie_cfg_control_ds_device_number),
          .pcie_cfg_control_ds_port_number(usp_pcie_cfg_control_ds_port_number),
          .pcie_cfg_control_dsn(usp_pcie_cfg_control_dsn),
          .pcie_cfg_control_err_cor_in(usp_pcie_cfg_control_err_cor_in),
          .pcie_cfg_control_err_uncor_in(usp_pcie_cfg_control_err_uncor_in),
          .pcie_cfg_control_flr_done(usp_pcie_cfg_control_flr_done),
          .pcie_cfg_control_flr_done_function_number(usp_pcie_cfg_control_flr_done_function_number),
          .pcie_cfg_control_flr_in_process(usp_pcie_cfg_control_flr_in_process),
          .pcie_cfg_control_hot_reset_in(usp_pcie_cfg_control_hot_reset_in),
          .pcie_cfg_control_hot_reset_out(usp_pcie_cfg_control_hot_reset_out),
          .pcie_cfg_control_link_training_enable(usp_pcie_cfg_control_link_training_enable),
          .pcie_cfg_control_per_function_func_num(usp_pcie_cfg_control_per_function_func_num),
          .pcie_cfg_control_per_function_req(usp_pcie_cfg_control_per_function_req),
          .pcie_cfg_control_pm_aspm_l1entry_reject(usp_pcie_cfg_control_pm_aspm_l1entry_reject),
          .pcie_cfg_control_pm_aspm_tx_l0s_entry_disable(usp_pcie_cfg_control_pm_aspm_tx_l0s_entry_disable),
          .pcie_cfg_control_power_state_change_ack(usp_pcie_cfg_control_power_state_change_ack),
          .pcie_cfg_control_power_state_change_interrupt(usp_pcie_cfg_control_power_state_change_interrupt),
          .pcie_cfg_control_req_pm_transition_l23_ready(usp_pcie_cfg_control_req_pm_transition_l23_ready),
          .pcie_cfg_control_vf_flr_done(usp_pcie_cfg_control_vf_flr_done),
          .pcie_cfg_control_vf_flr_func_num(usp_pcie_cfg_control_vf_flr_func_num),
          .pcie_cfg_control_vf_flr_in_process(usp_pcie_cfg_control_vf_flr_in_process),
          .pcie_cfg_ext_function_number(usp_pcie_cfg_ext_function_number),
          .pcie_cfg_ext_read_data(usp_pcie_cfg_ext_read_data),
          .pcie_cfg_ext_read_data_valid(usp_pcie_cfg_ext_read_data_valid),
          .pcie_cfg_ext_read_received(usp_pcie_cfg_ext_read_received),
          .pcie_cfg_ext_register_number(usp_pcie_cfg_ext_register_number),
          .pcie_cfg_ext_write_byte_enable(usp_pcie_cfg_ext_write_byte_enable),
          .pcie_cfg_ext_write_data(usp_pcie_cfg_ext_write_data),
          .pcie_cfg_ext_write_received(usp_pcie_cfg_ext_write_received),
          .pcie_cfg_fc_cpld(usp_pcie_cfg_fc_cpld),
          .pcie_cfg_fc_cpld_scale(usp_pcie_cfg_fc_cpld_scale),
          .pcie_cfg_fc_cplh(usp_pcie_cfg_fc_cplh),
          .pcie_cfg_fc_cplh_scale(usp_pcie_cfg_fc_cplh_scale),
          .pcie_cfg_fc_npd(usp_pcie_cfg_fc_npd),
          .pcie_cfg_fc_npd_scale(usp_pcie_cfg_fc_npd_scale),
          .pcie_cfg_fc_nph(usp_pcie_cfg_fc_nph),
          .pcie_cfg_fc_nph_scale(usp_pcie_cfg_fc_nph_scale),
          .pcie_cfg_fc_pd(usp_pcie_cfg_fc_pd),
          .pcie_cfg_fc_pd_scale(usp_pcie_cfg_fc_pd_scale),
          .pcie_cfg_fc_ph(usp_pcie_cfg_fc_ph),
          .pcie_cfg_fc_ph_scale(usp_pcie_cfg_fc_ph_scale),
          .pcie_cfg_fc_sel(usp_pcie_cfg_fc_sel),
          .pcie_cfg_fc_vc_sel(usp_pcie_cfg_fc_vc_sel),
          .pcie_cfg_interrupt_intx_vector(usp_pcie_cfg_interrupt_intx_vector),
          .pcie_cfg_interrupt_pending(usp_pcie_cfg_interrupt_pending),
          .pcie_cfg_interrupt_sent(usp_pcie_cfg_interrupt_sent),
          .pcie_cfg_mesg_rcvd_recd(usp_pcie_cfg_mesg_rcvd_recd),
          .pcie_cfg_mesg_rcvd_recd_data(usp_pcie_cfg_mesg_rcvd_recd_data),
          .pcie_cfg_mesg_rcvd_recd_type(usp_pcie_cfg_mesg_rcvd_recd_type),
          .pcie_cfg_mesg_tx_transmit(usp_pcie_cfg_mesg_tx_transmit),
          .pcie_cfg_mesg_tx_transmit_data(usp_pcie_cfg_mesg_tx_transmit_data),
          .pcie_cfg_mesg_tx_transmit_done(usp_pcie_cfg_mesg_tx_transmit_done),
          .pcie_cfg_mesg_tx_transmit_type(usp_pcie_cfg_mesg_tx_transmit_type),
          .pcie_cfg_mgmt_addr(usp_pcie_cfg_mgmt_addr),
          .pcie_cfg_mgmt_byte_en(usp_pcie_cfg_mgmt_byte_en),
          .pcie_cfg_mgmt_debug_access(usp_pcie_cfg_mgmt_debug_access),
          .pcie_cfg_mgmt_function_number(usp_pcie_cfg_mgmt_function_number),
          .pcie_cfg_mgmt_read_data(usp_pcie_cfg_mgmt_read_data),
          .pcie_cfg_mgmt_read_en(usp_pcie_cfg_mgmt_read_en),
          .pcie_cfg_mgmt_read_write_done(usp_pcie_cfg_mgmt_read_write_done),
          .pcie_cfg_mgmt_write_data(usp_pcie_cfg_mgmt_write_data),
          .pcie_cfg_mgmt_write_en(usp_pcie_cfg_mgmt_write_en),
          .pcie_cfg_msix_internal_attr(usp_pcie_cfg_msix_internal_attr),
          .pcie_cfg_msix_internal_enable(usp_pcie_cfg_msix_internal_enable),
          .pcie_cfg_msix_internal_fail(usp_pcie_cfg_msix_internal_fail),
          .pcie_cfg_msix_internal_function_number(usp_pcie_cfg_msix_internal_function_number),
          .pcie_cfg_msix_internal_int_vector(usp_pcie_cfg_msix_internal_int_vector),
          .pcie_cfg_msix_internal_mask(usp_pcie_cfg_msix_internal_mask),
          .pcie_cfg_msix_internal_mint_vector(usp_pcie_cfg_msix_internal_mint_vector),
          .pcie_cfg_msix_internal_sent(usp_pcie_cfg_msix_internal_sent),
          .pcie_cfg_msix_internal_tph_present(usp_pcie_cfg_msix_internal_tph_present),
          .pcie_cfg_msix_internal_tph_st_tag(usp_pcie_cfg_msix_internal_tph_st_tag),
          .pcie_cfg_msix_internal_tph_type(usp_pcie_cfg_msix_internal_tph_type),
          .pcie_cfg_msix_internal_vec_pending(usp_pcie_cfg_msix_internal_vec_pending),
          .pcie_cfg_msix_internal_vec_pending_status(usp_pcie_cfg_msix_internal_vec_pending_status),
          .pcie_cfg_msix_internal_vf_enable(usp_pcie_cfg_msix_internal_vf_enable),
          .pcie_cfg_msix_internal_vf_mask(usp_pcie_cfg_msix_internal_vf_mask),
          .pcie_cfg_status_10b_tag_requester_enable(usp_pcie_cfg_status_10b_tag_requester_enable),
          .pcie_cfg_status_atomic_requester_enable(usp_pcie_cfg_status_atomic_requester_enable),
          .pcie_cfg_status_cq_np_req(usp_pcie_cfg_status_cq_np_req),
          .pcie_cfg_status_cq_np_req_count(usp_pcie_cfg_status_cq_np_req_count),
          .pcie_cfg_status_current_speed(usp_pcie_cfg_status_current_speed),
          .pcie_cfg_status_err_cor_out(usp_pcie_cfg_status_err_cor_out),
          .pcie_cfg_status_err_fatal_out(usp_pcie_cfg_status_err_fatal_out),
          .pcie_cfg_status_err_nonfatal_out(usp_pcie_cfg_status_err_nonfatal_out),
          .pcie_cfg_status_ext_tag_enable(usp_pcie_cfg_status_ext_tag_enable),
          .pcie_cfg_status_function_power_state(usp_pcie_cfg_status_function_power_state),
          .pcie_cfg_status_function_status(usp_pcie_cfg_status_function_status),
          .pcie_cfg_status_link_power_state(usp_pcie_cfg_status_link_power_state),
          .pcie_cfg_status_local_error_out(usp_pcie_cfg_status_local_error_out),
          .pcie_cfg_status_local_error_valid(usp_pcie_cfg_status_local_error_valid),
          .pcie_cfg_status_ltssm_state(usp_pcie_cfg_status_ltssm_state),
          .pcie_cfg_status_max_payload(usp_pcie_cfg_status_max_payload),
          .pcie_cfg_status_max_read_req(usp_pcie_cfg_status_max_read_req),
          .pcie_cfg_status_negotiated_width(usp_pcie_cfg_status_negotiated_width),
          .pcie_cfg_status_obff_enable(usp_pcie_cfg_status_obff_enable),
          .pcie_cfg_status_pasid_enable(usp_pcie_cfg_status_pasid_enable),
          .pcie_cfg_status_pasid_exec_permission_enable(usp_pcie_cfg_status_pasid_exec_permission_enable),
          .pcie_cfg_status_pasid_privil_mode_enable(usp_pcie_cfg_status_pasid_privil_mode_enable),
          .pcie_cfg_status_per_function_out(usp_pcie_cfg_status_per_function_out),
          .pcie_cfg_status_per_function_vld(usp_pcie_cfg_status_per_function_vld),
          .pcie_cfg_status_phy_link_down(usp_pcie_cfg_status_phy_link_down),
          .pcie_cfg_status_phy_link_status(usp_pcie_cfg_status_phy_link_status),
          .pcie_cfg_status_pl_status_change(usp_pcie_cfg_status_pl_status_change),
          .pcie_cfg_status_rcb_status(usp_pcie_cfg_status_rcb_status),
          .pcie_cfg_status_rq_seq_num0(usp_pcie_cfg_status_rq_seq_num0),
          .pcie_cfg_status_rq_seq_num1(usp_pcie_cfg_status_rq_seq_num1),
          .pcie_cfg_status_rq_seq_num_vld0(usp_pcie_cfg_status_rq_seq_num_vld0),
          .pcie_cfg_status_rq_seq_num_vld1(usp_pcie_cfg_status_rq_seq_num_vld1),
          .pcie_cfg_status_rq_tag0(usp_pcie_cfg_status_rq_tag0),
          .pcie_cfg_status_rq_tag1(usp_pcie_cfg_status_rq_tag1),
          .pcie_cfg_status_rq_tag_av(usp_pcie_cfg_status_rq_tag_av),
          .pcie_cfg_status_rq_tag_vld0(usp_pcie_cfg_status_rq_tag_vld0),
          .pcie_cfg_status_rq_tag_vld1(usp_pcie_cfg_status_rq_tag_vld1),
          .pcie_cfg_status_rx_pm_state(usp_pcie_cfg_status_rx_pm_state),
          .pcie_cfg_status_tph_requester_enable(usp_pcie_cfg_status_tph_requester_enable),
          .pcie_cfg_status_tph_st_mode(usp_pcie_cfg_status_tph_st_mode),
          .pcie_cfg_status_tx_pm_state(usp_pcie_cfg_status_tx_pm_state),
          .pcie_cfg_status_vc1_enable(usp_pcie_cfg_status_vc1_enable),
          .pcie_cfg_status_vc1_negotiation_pending(usp_pcie_cfg_status_vc1_negotiation_pending),
          .pcie_cfg_status_vf_power_state(usp_pcie_cfg_status_vf_power_state),
          .pcie_cfg_status_vf_status(usp_pcie_cfg_status_vf_status),
          .pcie_cfg_status_vf_tph_requester_enable(usp_pcie_cfg_status_vf_tph_requester_enable),
          .pcie_cfg_status_vf_tph_st_mode(usp_pcie_cfg_status_vf_tph_st_mode),
          .pcie_cfg_status_wrreq_bme_vld(usp_pcie_cfg_status_wrreq_bme_vld),
          .pcie_cfg_status_wrreq_flr_vld(usp_pcie_cfg_status_wrreq_flr_vld),
          .pcie_cfg_status_wrreq_function_number(usp_pcie_cfg_status_wrreq_function_number),
          .pcie_cfg_status_wrreq_msi_vld(usp_pcie_cfg_status_wrreq_msi_vld),
          .pcie_cfg_status_wrreq_msix_vld(usp_pcie_cfg_status_wrreq_msix_vld),
          .pcie_cfg_status_wrreq_out_value(usp_pcie_cfg_status_wrreq_out_value),
          .pcie_cfg_status_wrreq_vfe_vld(usp_pcie_cfg_status_wrreq_vfe_vld),
          .pcie_mgt_grx_n(),
          .pcie_mgt_grx_p(),
          .pcie_mgt_gtx_n(),
          .pcie_mgt_gtx_p(),
          .pcie_refclk_clk_n(usp_pcie_refclk_clk_n),
          .pcie_refclk_clk_p(usp_pcie_refclk_clk_p),
          .pcie_transmit_fc_npd_av(usp_pcie_transmit_fc_npd_av),
          .pcie_transmit_fc_nph_av(usp_pcie_transmit_fc_nph_av),
          .phy_rdy_out(usp_phy_rdy_out),
          .s_axis_cc_tdata(usp_s_axis_cc_tdata),
          .s_axis_cc_tkeep(usp_s_axis_cc_tkeep),
          .s_axis_cc_tlast(usp_s_axis_cc_tlast),
          .s_axis_cc_tready(usp_s_axis_cc_tready),
          .s_axis_cc_tuser(usp_s_axis_cc_tuser),
          .s_axis_cc_tvalid(usp_s_axis_cc_tvalid),
          .s_axis_rq_tdata(usp_s_axis_rq_tdata),
          .s_axis_rq_tkeep(usp_s_axis_rq_tkeep),
          .s_axis_rq_tlast(usp_s_axis_rq_tlast),
          .s_axis_rq_tready(usp_s_axis_rq_tready),
          .s_axis_rq_tuser(usp_s_axis_rq_tuser),
          .s_axis_rq_tvalid(usp_s_axis_rq_tvalid),
          .sys_reset(usp_sys_reset),
          .user_clk(usp_user_clk),
          .user_lnk_up(usp_user_lnk_up),
          .user_reset(usp_user_reset),
          .common_commands_in_0(usp_common_commands_in_0),
          .common_commands_out_0(usp_common_commands_out_0),
          .pipe_rx_0_sigs_0(usp_pipe_rx_0_sigs_0),
          .pipe_rx_10_sigs_0(usp_pipe_rx_10_sigs_0),
          .pipe_rx_11_sigs_0(usp_pipe_rx_11_sigs_0),
          .pipe_rx_12_sigs_0(usp_pipe_rx_12_sigs_0),
          .pipe_rx_13_sigs_0(usp_pipe_rx_13_sigs_0),
          .pipe_rx_14_sigs_0(usp_pipe_rx_14_sigs_0),
          .pipe_rx_15_sigs_0(usp_pipe_rx_15_sigs_0),
          .pipe_rx_1_sigs_0(usp_pipe_rx_1_sigs_0),
          .pipe_rx_2_sigs_0(usp_pipe_rx_2_sigs_0),
          .pipe_rx_3_sigs_0(usp_pipe_rx_3_sigs_0),
          .pipe_rx_4_sigs_0(usp_pipe_rx_4_sigs_0),
          .pipe_rx_5_sigs_0(usp_pipe_rx_5_sigs_0),
          .pipe_rx_6_sigs_0(usp_pipe_rx_6_sigs_0),
          .pipe_rx_7_sigs_0(usp_pipe_rx_7_sigs_0),
          .pipe_rx_8_sigs_0(usp_pipe_rx_8_sigs_0),
          .pipe_rx_9_sigs_0(usp_pipe_rx_9_sigs_0),
          .pipe_tx_0_sigs_0(usp_pipe_tx_0_sigs_0),
          .pipe_tx_10_sigs_0(usp_pipe_tx_10_sigs_0),
          .pipe_tx_11_sigs_0(usp_pipe_tx_11_sigs_0),
          .pipe_tx_12_sigs_0(usp_pipe_tx_12_sigs_0),
          .pipe_tx_13_sigs_0(usp_pipe_tx_13_sigs_0),
          .pipe_tx_14_sigs_0(usp_pipe_tx_14_sigs_0),
          .pipe_tx_15_sigs_0(usp_pipe_tx_15_sigs_0),
          .pipe_tx_1_sigs_0(usp_pipe_tx_1_sigs_0),
          .pipe_tx_2_sigs_0(usp_pipe_tx_2_sigs_0),
          .pipe_tx_3_sigs_0(usp_pipe_tx_3_sigs_0),
          .pipe_tx_4_sigs_0(usp_pipe_tx_4_sigs_0),
          .pipe_tx_5_sigs_0(usp_pipe_tx_5_sigs_0),
          .pipe_tx_6_sigs_0(usp_pipe_tx_6_sigs_0),
          .pipe_tx_7_sigs_0(usp_pipe_tx_7_sigs_0),
          .pipe_tx_8_sigs_0(usp_pipe_tx_8_sigs_0),
          .pipe_tx_9_sigs_0(usp_pipe_tx_9_sigs_0)
      );
    end else begin : gen_ext_pipe_sim_usp
      usp_plpcie switch_usp (
          .ccix_optimized_tlp_tx_and_rx_enable(usp_ccix_optimized_tlp_tx_and_rx_enable),
          .ccix_rx_credit_av(usp_ccix_rx_credit_av),
          .core_clk(usp_core_clk),
          .cxs_rx_active_ack(usp_cxs_rx_active_ack),
          .cxs_rx_active_req(usp_cxs_rx_active_req),
          .cxs_rx_cntl(usp_cxs_rx_cntl),
          .cxs_rx_cntl_chk(usp_cxs_rx_cntl_chk),
          .cxs_rx_crdgnt(usp_cxs_rx_crdgnt),
          .cxs_rx_crdgnt_chk(usp_cxs_rx_crdgnt_chk),
          .cxs_rx_crdrtn(usp_cxs_rx_crdrtn),
          .cxs_rx_crdrtn_chk(usp_cxs_rx_crdrtn_chk),
          .cxs_rx_data(usp_cxs_rx_data),
          .cxs_rx_data_chk(usp_cxs_rx_data_chk),
          .cxs_rx_deact_hint(usp_cxs_rx_deact_hint),
          .cxs_rx_valid(usp_cxs_rx_valid),
          .cxs_rx_valid_chk(usp_cxs_rx_valid_chk),
          .cxs_tx_active_ack(usp_cxs_tx_active_ack),
          .cxs_tx_active_req(usp_cxs_tx_active_req),
          .cxs_tx_cntl(usp_cxs_tx_cntl),
          .cxs_tx_cntl_chk(usp_cxs_tx_cntl_chk),
          .cxs_tx_crdgnt(usp_cxs_tx_crdgnt),
          .cxs_tx_crdgnt_chk(usp_cxs_tx_crdgnt_chk),
          .cxs_tx_crdrtn(usp_cxs_tx_crdrtn),
          .cxs_tx_crdrtn_chk(usp_cxs_tx_crdrtn_chk),
          .cxs_tx_data(usp_cxs_tx_data),
          .cxs_tx_data_chk(usp_cxs_tx_data_chk),
          .cxs_tx_deact_hint(usp_cxs_tx_deact_hint),
          .cxs_tx_valid(usp_cxs_tx_valid),
          .cxs_tx_valid_chk(usp_cxs_tx_valid_chk),
          .m_axis_cq_tdata(usp_m_axis_cq_tdata),
          .m_axis_cq_tkeep(usp_m_axis_cq_tkeep),
          .m_axis_cq_tlast(usp_m_axis_cq_tlast),
          .m_axis_cq_tready(usp_m_axis_cq_tready),
          .m_axis_cq_tuser(usp_m_axis_cq_tuser),
          .m_axis_cq_tvalid(usp_m_axis_cq_tvalid),
          .m_axis_rc_tdata(usp_m_axis_rc_tdata),
          .m_axis_rc_tkeep(usp_m_axis_rc_tkeep),
          .m_axis_rc_tlast(usp_m_axis_rc_tlast),
          .m_axis_rc_tready(usp_m_axis_rc_tready),
          .m_axis_rc_tuser(usp_m_axis_rc_tuser),
          .m_axis_rc_tvalid(usp_m_axis_rc_tvalid),
          .pcie_cfg_control_bus_number(usp_pcie_cfg_control_bus_number),
          .pcie_cfg_control_config_space_enable(usp_pcie_cfg_control_config_space_enable),
          .pcie_cfg_control_ds_bus_number(usp_pcie_cfg_control_ds_bus_number),
          .pcie_cfg_control_ds_device_number(usp_pcie_cfg_control_ds_device_number),
          .pcie_cfg_control_ds_port_number(usp_pcie_cfg_control_ds_port_number),
          .pcie_cfg_control_dsn(usp_pcie_cfg_control_dsn),
          .pcie_cfg_control_err_cor_in(usp_pcie_cfg_control_err_cor_in),
          .pcie_cfg_control_err_uncor_in(usp_pcie_cfg_control_err_uncor_in),
          .pcie_cfg_control_flr_done(usp_pcie_cfg_control_flr_done),
          .pcie_cfg_control_flr_done_function_number(usp_pcie_cfg_control_flr_done_function_number),
          .pcie_cfg_control_flr_in_process(usp_pcie_cfg_control_flr_in_process),
          .pcie_cfg_control_hot_reset_in(usp_pcie_cfg_control_hot_reset_in),
          .pcie_cfg_control_hot_reset_out(usp_pcie_cfg_control_hot_reset_out),
          .pcie_cfg_control_link_training_enable(usp_pcie_cfg_control_link_training_enable),
          .pcie_cfg_control_per_function_func_num(usp_pcie_cfg_control_per_function_func_num),
          .pcie_cfg_control_per_function_req(usp_pcie_cfg_control_per_function_req),
          .pcie_cfg_control_pm_aspm_l1entry_reject(usp_pcie_cfg_control_pm_aspm_l1entry_reject),
          .pcie_cfg_control_pm_aspm_tx_l0s_entry_disable(usp_pcie_cfg_control_pm_aspm_tx_l0s_entry_disable),
          .pcie_cfg_control_power_state_change_ack(usp_pcie_cfg_control_power_state_change_ack),
          .pcie_cfg_control_power_state_change_interrupt(usp_pcie_cfg_control_power_state_change_interrupt),
          .pcie_cfg_control_req_pm_transition_l23_ready(usp_pcie_cfg_control_req_pm_transition_l23_ready),
          .pcie_cfg_control_vf_flr_done(usp_pcie_cfg_control_vf_flr_done),
          .pcie_cfg_control_vf_flr_func_num(usp_pcie_cfg_control_vf_flr_func_num),
          .pcie_cfg_control_vf_flr_in_process(usp_pcie_cfg_control_vf_flr_in_process),
          .pcie_cfg_ext_function_number(usp_pcie_cfg_ext_function_number),
          .pcie_cfg_ext_read_data(usp_pcie_cfg_ext_read_data),
          .pcie_cfg_ext_read_data_valid(usp_pcie_cfg_ext_read_data_valid),
          .pcie_cfg_ext_read_received(usp_pcie_cfg_ext_read_received),
          .pcie_cfg_ext_register_number(usp_pcie_cfg_ext_register_number),
          .pcie_cfg_ext_write_byte_enable(usp_pcie_cfg_ext_write_byte_enable),
          .pcie_cfg_ext_write_data(usp_pcie_cfg_ext_write_data),
          .pcie_cfg_ext_write_received(usp_pcie_cfg_ext_write_received),
          .pcie_cfg_fc_cpld(usp_pcie_cfg_fc_cpld),
          .pcie_cfg_fc_cpld_scale(usp_pcie_cfg_fc_cpld_scale),
          .pcie_cfg_fc_cplh(usp_pcie_cfg_fc_cplh),
          .pcie_cfg_fc_cplh_scale(usp_pcie_cfg_fc_cplh_scale),
          .pcie_cfg_fc_npd(usp_pcie_cfg_fc_npd),
          .pcie_cfg_fc_npd_scale(usp_pcie_cfg_fc_npd_scale),
          .pcie_cfg_fc_nph(usp_pcie_cfg_fc_nph),
          .pcie_cfg_fc_nph_scale(usp_pcie_cfg_fc_nph_scale),
          .pcie_cfg_fc_pd(usp_pcie_cfg_fc_pd),
          .pcie_cfg_fc_pd_scale(usp_pcie_cfg_fc_pd_scale),
          .pcie_cfg_fc_ph(usp_pcie_cfg_fc_ph),
          .pcie_cfg_fc_ph_scale(usp_pcie_cfg_fc_ph_scale),
          .pcie_cfg_fc_sel(usp_pcie_cfg_fc_sel),
          .pcie_cfg_fc_vc_sel(usp_pcie_cfg_fc_vc_sel),
          .pcie_cfg_interrupt_intx_vector(usp_pcie_cfg_interrupt_intx_vector),
          .pcie_cfg_interrupt_pending(usp_pcie_cfg_interrupt_pending),
          .pcie_cfg_interrupt_sent(usp_pcie_cfg_interrupt_sent),
          .pcie_cfg_mesg_rcvd_recd(usp_pcie_cfg_mesg_rcvd_recd),
          .pcie_cfg_mesg_rcvd_recd_data(usp_pcie_cfg_mesg_rcvd_recd_data),
          .pcie_cfg_mesg_rcvd_recd_type(usp_pcie_cfg_mesg_rcvd_recd_type),
          .pcie_cfg_mesg_tx_transmit(usp_pcie_cfg_mesg_tx_transmit),
          .pcie_cfg_mesg_tx_transmit_data(usp_pcie_cfg_mesg_tx_transmit_data),
          .pcie_cfg_mesg_tx_transmit_done(usp_pcie_cfg_mesg_tx_transmit_done),
          .pcie_cfg_mesg_tx_transmit_type(usp_pcie_cfg_mesg_tx_transmit_type),
          .pcie_cfg_mgmt_addr(usp_pcie_cfg_mgmt_addr),
          .pcie_cfg_mgmt_byte_en(usp_pcie_cfg_mgmt_byte_en),
          .pcie_cfg_mgmt_debug_access(usp_pcie_cfg_mgmt_debug_access),
          .pcie_cfg_mgmt_function_number(usp_pcie_cfg_mgmt_function_number),
          .pcie_cfg_mgmt_read_data(usp_pcie_cfg_mgmt_read_data),
          .pcie_cfg_mgmt_read_en(usp_pcie_cfg_mgmt_read_en),
          .pcie_cfg_mgmt_read_write_done(usp_pcie_cfg_mgmt_read_write_done),
          .pcie_cfg_mgmt_write_data(usp_pcie_cfg_mgmt_write_data),
          .pcie_cfg_mgmt_write_en(usp_pcie_cfg_mgmt_write_en),
          .pcie_cfg_msix_internal_attr(usp_pcie_cfg_msix_internal_attr),
          .pcie_cfg_msix_internal_enable(usp_pcie_cfg_msix_internal_enable),
          .pcie_cfg_msix_internal_fail(usp_pcie_cfg_msix_internal_fail),
          .pcie_cfg_msix_internal_function_number(usp_pcie_cfg_msix_internal_function_number),
          .pcie_cfg_msix_internal_int_vector(usp_pcie_cfg_msix_internal_int_vector),
          .pcie_cfg_msix_internal_mask(usp_pcie_cfg_msix_internal_mask),
          .pcie_cfg_msix_internal_mint_vector(usp_pcie_cfg_msix_internal_mint_vector),
          .pcie_cfg_msix_internal_sent(usp_pcie_cfg_msix_internal_sent),
          .pcie_cfg_msix_internal_tph_present(usp_pcie_cfg_msix_internal_tph_present),
          .pcie_cfg_msix_internal_tph_st_tag(usp_pcie_cfg_msix_internal_tph_st_tag),
          .pcie_cfg_msix_internal_tph_type(usp_pcie_cfg_msix_internal_tph_type),
          .pcie_cfg_msix_internal_vec_pending(usp_pcie_cfg_msix_internal_vec_pending),
          .pcie_cfg_msix_internal_vec_pending_status(usp_pcie_cfg_msix_internal_vec_pending_status),
          .pcie_cfg_msix_internal_vf_enable(usp_pcie_cfg_msix_internal_vf_enable),
          .pcie_cfg_msix_internal_vf_mask(usp_pcie_cfg_msix_internal_vf_mask),
          .pcie_cfg_status_10b_tag_requester_enable(usp_pcie_cfg_status_10b_tag_requester_enable),
          .pcie_cfg_status_atomic_requester_enable(usp_pcie_cfg_status_atomic_requester_enable),
          .pcie_cfg_status_cq_np_req(usp_pcie_cfg_status_cq_np_req),
          .pcie_cfg_status_cq_np_req_count(usp_pcie_cfg_status_cq_np_req_count),
          .pcie_cfg_status_current_speed(usp_pcie_cfg_status_current_speed),
          .pcie_cfg_status_err_cor_out(usp_pcie_cfg_status_err_cor_out),
          .pcie_cfg_status_err_fatal_out(usp_pcie_cfg_status_err_fatal_out),
          .pcie_cfg_status_err_nonfatal_out(usp_pcie_cfg_status_err_nonfatal_out),
          .pcie_cfg_status_ext_tag_enable(usp_pcie_cfg_status_ext_tag_enable),
          .pcie_cfg_status_function_power_state(usp_pcie_cfg_status_function_power_state),
          .pcie_cfg_status_function_status(usp_pcie_cfg_status_function_status),
          .pcie_cfg_status_link_power_state(usp_pcie_cfg_status_link_power_state),
          .pcie_cfg_status_local_error_out(usp_pcie_cfg_status_local_error_out),
          .pcie_cfg_status_local_error_valid(usp_pcie_cfg_status_local_error_valid),
          .pcie_cfg_status_ltssm_state(usp_pcie_cfg_status_ltssm_state),
          .pcie_cfg_status_max_payload(usp_pcie_cfg_status_max_payload),
          .pcie_cfg_status_max_read_req(usp_pcie_cfg_status_max_read_req),
          .pcie_cfg_status_negotiated_width(usp_pcie_cfg_status_negotiated_width),
          .pcie_cfg_status_obff_enable(usp_pcie_cfg_status_obff_enable),
          .pcie_cfg_status_pasid_enable(usp_pcie_cfg_status_pasid_enable),
          .pcie_cfg_status_pasid_exec_permission_enable(usp_pcie_cfg_status_pasid_exec_permission_enable),
          .pcie_cfg_status_pasid_privil_mode_enable(usp_pcie_cfg_status_pasid_privil_mode_enable),
          .pcie_cfg_status_per_function_out(usp_pcie_cfg_status_per_function_out),
          .pcie_cfg_status_per_function_vld(usp_pcie_cfg_status_per_function_vld),
          .pcie_cfg_status_phy_link_down(usp_pcie_cfg_status_phy_link_down),
          .pcie_cfg_status_phy_link_status(usp_pcie_cfg_status_phy_link_status),
          .pcie_cfg_status_pl_status_change(usp_pcie_cfg_status_pl_status_change),
          .pcie_cfg_status_rcb_status(usp_pcie_cfg_status_rcb_status),
          .pcie_cfg_status_rq_seq_num0(usp_pcie_cfg_status_rq_seq_num0),
          .pcie_cfg_status_rq_seq_num1(usp_pcie_cfg_status_rq_seq_num1),
          .pcie_cfg_status_rq_seq_num_vld0(usp_pcie_cfg_status_rq_seq_num_vld0),
          .pcie_cfg_status_rq_seq_num_vld1(usp_pcie_cfg_status_rq_seq_num_vld1),
          .pcie_cfg_status_rq_tag0(usp_pcie_cfg_status_rq_tag0),
          .pcie_cfg_status_rq_tag1(usp_pcie_cfg_status_rq_tag1),
          .pcie_cfg_status_rq_tag_av(usp_pcie_cfg_status_rq_tag_av),
          .pcie_cfg_status_rq_tag_vld0(usp_pcie_cfg_status_rq_tag_vld0),
          .pcie_cfg_status_rq_tag_vld1(usp_pcie_cfg_status_rq_tag_vld1),
          .pcie_cfg_status_rx_pm_state(usp_pcie_cfg_status_rx_pm_state),
          .pcie_cfg_status_tph_requester_enable(usp_pcie_cfg_status_tph_requester_enable),
          .pcie_cfg_status_tph_st_mode(usp_pcie_cfg_status_tph_st_mode),
          .pcie_cfg_status_tx_pm_state(usp_pcie_cfg_status_tx_pm_state),
          .pcie_cfg_status_vc1_enable(usp_pcie_cfg_status_vc1_enable),
          .pcie_cfg_status_vc1_negotiation_pending(usp_pcie_cfg_status_vc1_negotiation_pending),
          .pcie_cfg_status_vf_power_state(usp_pcie_cfg_status_vf_power_state),
          .pcie_cfg_status_vf_status(usp_pcie_cfg_status_vf_status),
          .pcie_cfg_status_vf_tph_requester_enable(usp_pcie_cfg_status_vf_tph_requester_enable),
          .pcie_cfg_status_vf_tph_st_mode(usp_pcie_cfg_status_vf_tph_st_mode),
          .pcie_cfg_status_wrreq_bme_vld(usp_pcie_cfg_status_wrreq_bme_vld),
          .pcie_cfg_status_wrreq_flr_vld(usp_pcie_cfg_status_wrreq_flr_vld),
          .pcie_cfg_status_wrreq_function_number(usp_pcie_cfg_status_wrreq_function_number),
          .pcie_cfg_status_wrreq_msi_vld(usp_pcie_cfg_status_wrreq_msi_vld),
          .pcie_cfg_status_wrreq_msix_vld(usp_pcie_cfg_status_wrreq_msix_vld),
          .pcie_cfg_status_wrreq_out_value(usp_pcie_cfg_status_wrreq_out_value),
          .pcie_cfg_status_wrreq_vfe_vld(usp_pcie_cfg_status_wrreq_vfe_vld),
          .pcie_mgt_grx_n(usp_pcie_mgt_grx_n),
          .pcie_mgt_grx_p(usp_pcie_mgt_grx_p),
          .pcie_mgt_gtx_n(usp_pcie_mgt_gtx_n),
          .pcie_mgt_gtx_p(usp_pcie_mgt_gtx_p),
          .pcie_refclk_clk_n(usp_pcie_refclk_clk_n),
          .pcie_refclk_clk_p(usp_pcie_refclk_clk_p),
          .pcie_transmit_fc_npd_av(usp_pcie_transmit_fc_npd_av),
          .pcie_transmit_fc_nph_av(usp_pcie_transmit_fc_nph_av),
          .phy_rdy_out(usp_phy_rdy_out),
          .s_axis_cc_tdata(usp_s_axis_cc_tdata),
          .s_axis_cc_tkeep(usp_s_axis_cc_tkeep),
          .s_axis_cc_tlast(usp_s_axis_cc_tlast),
          .s_axis_cc_tready(usp_s_axis_cc_tready),
          .s_axis_cc_tuser(usp_s_axis_cc_tuser),
          .s_axis_cc_tvalid(usp_s_axis_cc_tvalid),
          .s_axis_rq_tdata(usp_s_axis_rq_tdata),
          .s_axis_rq_tkeep(usp_s_axis_rq_tkeep),
          .s_axis_rq_tlast(usp_s_axis_rq_tlast),
          .s_axis_rq_tready(usp_s_axis_rq_tready),
          .s_axis_rq_tuser(usp_s_axis_rq_tuser),
          .s_axis_rq_tvalid(usp_s_axis_rq_tvalid),
          .sys_reset(usp_sys_reset),
          .user_clk(usp_user_clk),
          .user_lnk_up(usp_user_lnk_up),
          .user_reset(usp_user_reset),
          .common_commands_in_0(),
          .common_commands_out_0(),
          .pipe_rx_0_sigs_0(),
          .pipe_rx_10_sigs_0(),
          .pipe_rx_11_sigs_0(),
          .pipe_rx_12_sigs_0(),
          .pipe_rx_13_sigs_0(),
          .pipe_rx_14_sigs_0(),
          .pipe_rx_15_sigs_0(),
          .pipe_rx_1_sigs_0(),
          .pipe_rx_2_sigs_0(),
          .pipe_rx_3_sigs_0(),
          .pipe_rx_4_sigs_0(),
          .pipe_rx_5_sigs_0(),
          .pipe_rx_6_sigs_0(),
          .pipe_rx_7_sigs_0(),
          .pipe_rx_8_sigs_0(),
          .pipe_rx_9_sigs_0(),
          .pipe_tx_0_sigs_0(),
          .pipe_tx_10_sigs_0(),
          .pipe_tx_11_sigs_0(),
          .pipe_tx_12_sigs_0(),
          .pipe_tx_13_sigs_0(),
          .pipe_tx_14_sigs_0(),
          .pipe_tx_15_sigs_0(),
          .pipe_tx_1_sigs_0(),
          .pipe_tx_2_sigs_0(),
          .pipe_tx_3_sigs_0(),
          .pipe_tx_4_sigs_0(),
          .pipe_tx_5_sigs_0(),
          .pipe_tx_6_sigs_0(),
          .pipe_tx_7_sigs_0(),
          .pipe_tx_8_sigs_0(),
          .pipe_tx_9_sigs_0()
      );
    end
  endgenerate

  assign usp_sys_reset = sys_rst_user;

  // Flow Control - Set to 11 to indicate no flow control
  assign usp_pcie_cfg_status_cq_np_req = 2'b11;  // Always one cycle delivery so could be 00 too. 
  assign dsp_pcie0_cfg_status_0_cq_np_req = 2'b11;

  // Set attributes for USP and DSP
  assign usp_pcie_cfg_control_link_training_enable = 1'b1;
  assign usp_pcie_cfg_control_config_space_enable = 1'b1;
  assign usp_pcie_cfg_control_power_state_change_ack = 1'b1;
  assign dsp_pcie0_cfg_control_0_power_state_change_ack = 1'b1;
  assign usp_pcie_cfg_control_pm_aspm_tx_l0s_entry_disable = 1'b1;

  // Pass USP hot reset and link disable info to DSP
  one_signal_cdc #(
      .SIGNAL_WIDTH(1)
  ) hot_reset_usp_to_dsp (
      .src_clk(usp_user_clk),
      .dst_clk(dsp_pcie0_user_clk_0),
      .sys_rst(sys_rst_user),
      .sig_in (usp_pcie_cfg_control_hot_reset_out || ((usp_pcie_cfg_status_ltssm_state == 6'h20) ? 1'b1 : 1'b0)),
      .sig_out(dsp_pcie0_cfg_control_0_hot_reset_in)
  );

endmodule
