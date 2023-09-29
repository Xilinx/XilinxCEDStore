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
// Project    : The Xilinx PCI Express DMA 
// File       : xilinx_pcie_uscale_rp.v
// Version    : 5.0
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//--
//-- Description:  PCI Express DSPORT Model Top for Endpoint example FPGA design
//--
//------------------------------------------------------------------------------

`timescale 1ps / 1ps

module xilinx_pcie4_uscale_rp # (
  parameter        C_DATA_WIDTH                   = 512,    // RX/TX interface data width
  parameter        EXT_PIPE_SIM                   = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.

  parameter        PL_LINK_CAP_MAX_LINK_SPEED     = 8,   // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter  [4:0] PL_LINK_CAP_MAX_LINK_WIDTH     = 8,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16

  parameter  [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE   = 3'h0,
  parameter        PL_DISABLE_EI_INFER_IN_L0      = "TRUE",
  parameter        PL_DISABLE_UPCONFIG_CAPABLE    = "FALSE",
 
  parameter        REF_CLK_FREQ                   = 0,                 // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXI4_CQ_TUSER_WIDTH = 183,
  parameter        AXI4_CC_TUSER_WIDTH = 81,
  parameter        AXI4_RQ_TUSER_WIDTH = 137,
  parameter        AXI4_RC_TUSER_WIDTH = 161,
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG   = "TRUE",
  parameter        AXISTEN_IF_RQ_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_RC_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_CQ_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_MC_RX_STRADDLE      = "FALSE",
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC = "FALSE",
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF,
  parameter KEEP_WIDTH                            = C_DATA_WIDTH / 32
)
(
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txp,
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txn,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,
  input                                           sys_clk_p,
  input                                           sys_clk_n,
  input                                           sys_rst_n,

  input [13:0]pcie0_pipe_rp_0_commands_in,
  output [13:0]pcie0_pipe_rp_0_commands_out,
  input [41:0]pcie0_pipe_rp_0_rx_0,
  input [41:0]pcie0_pipe_rp_0_rx_1,
  input [41:0]pcie0_pipe_rp_0_rx_10,
  input [41:0]pcie0_pipe_rp_0_rx_11,
  input [41:0]pcie0_pipe_rp_0_rx_12,
  input [41:0]pcie0_pipe_rp_0_rx_13,
  input [41:0]pcie0_pipe_rp_0_rx_14,
  input [41:0]pcie0_pipe_rp_0_rx_15,
  input [41:0]pcie0_pipe_rp_0_rx_2,
  input [41:0]pcie0_pipe_rp_0_rx_3,
  input [41:0]pcie0_pipe_rp_0_rx_4,
  input [41:0]pcie0_pipe_rp_0_rx_5,
  input [41:0]pcie0_pipe_rp_0_rx_6,
  input [41:0]pcie0_pipe_rp_0_rx_7,
  input [41:0]pcie0_pipe_rp_0_rx_8,
  input [41:0]pcie0_pipe_rp_0_rx_9,
  output [41:0]pcie0_pipe_rp_0_tx_0,
  output [41:0]pcie0_pipe_rp_0_tx_1,
  output [41:0]pcie0_pipe_rp_0_tx_10,
  output [41:0]pcie0_pipe_rp_0_tx_11,
  output [41:0]pcie0_pipe_rp_0_tx_12,
  output [41:0]pcie0_pipe_rp_0_tx_13,
  output [41:0]pcie0_pipe_rp_0_tx_14,
  output [41:0]pcie0_pipe_rp_0_tx_15,
  output [41:0]pcie0_pipe_rp_0_tx_2,
  output [41:0]pcie0_pipe_rp_0_tx_3,
  output [41:0]pcie0_pipe_rp_0_tx_4,
  output [41:0]pcie0_pipe_rp_0_tx_5,
  output [41:0]pcie0_pipe_rp_0_tx_6,
  output [41:0]pcie0_pipe_rp_0_tx_7,
  output [41:0]pcie0_pipe_rp_0_tx_8,
  output [41:0]pcie0_pipe_rp_0_tx_9
);

  localparam         TCQ = 1;
  localparam         EP_DEV_ID = 16'h9034;

  //----------------------------------------------------------------------------------------------------------------//
  // 3. AXI Interface                                                                                               //
  //----------------------------------------------------------------------------------------------------------------//

  wire                                       user_clk;
  wire                                       user_reset;
  wire                                       user_lnk_up;

  wire                                       s_axis_rq_tlast;
  wire                 [C_DATA_WIDTH-1:0]    s_axis_rq_tdata;
  wire             [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser;
  wire                   [KEEP_WIDTH-1:0]    s_axis_rq_tkeep;
  wire                                       s_axis_rq_tready;
  wire                                       s_axis_rq_tvalid;

  wire                 [C_DATA_WIDTH-1:0]    m_axis_rc_tdata;
  wire             [AXI4_RC_TUSER_WIDTH-1:0] m_axis_rc_tuser;
  wire                                       m_axis_rc_tlast;
  wire                   [KEEP_WIDTH-1:0]    m_axis_rc_tkeep;
  wire                                       m_axis_rc_tvalid;
  wire                                       m_axis_rc_tready;

  wire                 [C_DATA_WIDTH-1:0]    m_axis_cq_tdata;
  wire             [AXI4_CQ_TUSER_WIDTH-1:0] m_axis_cq_tuser;
  wire                                       m_axis_cq_tlast;
  wire                   [KEEP_WIDTH-1:0]    m_axis_cq_tkeep;
  wire                                       m_axis_cq_tvalid;
  wire                                       m_axis_cq_tready;

  wire                 [C_DATA_WIDTH-1:0]    s_axis_cc_tdata;
  wire             [AXI4_CC_TUSER_WIDTH-1:0] s_axis_cc_tuser;
  wire                                       s_axis_cc_tlast;
  wire                   [KEEP_WIDTH-1:0]    s_axis_cc_tkeep;
  wire                                       s_axis_cc_tvalid;
  wire                                       s_axis_cc_tready;

  wire                              [3:0]    pcie_tfc_nph_av;
  wire                              [3:0]    pcie_tfc_npd_av;
  wire                              [3:0]    pcie_rq_seq_num;
  wire                                       pcie_rq_seq_num_vld;
  wire                              [5:0]    pcie_rq_tag;
  wire                                       pcie_rq_tag_vld;
  wire                              [1:0]    pcie_rq_tag_av;

  wire                                       pcie_cq_np_req;
  wire                              [5:0]    pcie_cq_np_req_count;

  //----------------------------------------------------------------------------------------------------------------//
  // 4. Configuration (CFG) Interface                                                                               //
  //----------------------------------------------------------------------------------------------------------------//

  //----------------------------------------------------------------------------------------------------------------//
  // EP and RP                                                                                                      //
  //----------------------------------------------------------------------------------------------------------------//

  wire                                       cfg_phy_link_down;
  wire                              [1:0]    cfg_phy_link_status;
  wire                              [2:0]    cfg_negotiated_width;
  wire                              [1:0]    cfg_current_speed;
  wire                              [1:0]    cfg_max_payload;
  wire                              [2:0]    cfg_max_read_req;
  wire                             [15:0]    cfg_function_status;
  wire                             [11:0]    cfg_function_power_state;
  wire                             [503:0]    cfg_vf_status;
  wire                             [755:0]    cfg_vf_power_state;
  wire                              [1:0]    cfg_link_power_state;

  // Management Interface
  wire                             [9:0]    cfg_mgmt_addr;
  wire                                       cfg_mgmt_write;
  wire                             [31:0]    cfg_mgmt_write_data;
  wire                              [3:0]    cfg_mgmt_byte_enable;
  wire                                       cfg_mgmt_read;
  wire                             [31:0]    cfg_mgmt_read_data;
  wire                                       cfg_mgmt_read_write_done;
  wire                                       cfg_mgmt_type1_cfg_reg_access;

  // Error Reporting Interface
  wire                                       cfg_err_cor_out;
  wire                                       cfg_err_nonfatal_out;
  wire                                       cfg_err_fatal_out;
  wire                                       cfg_local_error;

  wire                              [5:0]    cfg_ltssm_state;
  wire                              [3:0]    cfg_rcb_status;
  wire                              [3:0]    cfg_dpa_substate_change;
  wire                              [1:0]    cfg_obff_enable;
  wire                                       cfg_pl_status_change;

  wire                              [3:0]    cfg_tph_requester_enable;
  wire                             [11:0]    cfg_tph_st_mode;
  wire                              [251:0]    cfg_vf_tph_requester_enable;
  wire                             [755:0]    cfg_vf_tph_st_mode;

  wire                                       cfg_msg_received;
  wire                              [7:0]    cfg_msg_received_data;
  wire                              [4:0]    cfg_msg_received_type;

  wire                                       cfg_msg_transmit;
  wire                              [2:0]    cfg_msg_transmit_type;
  wire                             [31:0]    cfg_msg_transmit_data;
  wire                                       cfg_msg_transmit_done;

  wire                              [7:0]    cfg_fc_ph;
  wire                             [11:0]    cfg_fc_pd;
  wire                              [7:0]    cfg_fc_nph;
  wire                             [11:0]    cfg_fc_npd;
  wire                              [7:0]    cfg_fc_cplh;
  wire                             [11:0]    cfg_fc_cpld;
  wire                              [2:0]    cfg_fc_sel;

  wire                              [2:0]    cfg_per_func_status_control;
  wire                             [15:0]    cfg_per_func_status_data;
  wire                              [2:0]    cfg_per_function_number;
  wire                                       cfg_per_function_output_request;
  wire                                       cfg_per_function_update_done;

  wire                             [63:0]    cfg_dsn;
  wire                                       cfg_power_state_change_ack;
  wire                                       cfg_power_state_change_interrupt;
  wire                                       cfg_err_cor_in;
  wire                                       cfg_err_uncor_in;

  wire                              [3:0]    cfg_flr_in_process;
  wire                              [1:0]    cfg_flr_done;
  wire                              [251:0]    cfg_vf_flr_in_process;
  wire                                  cfg_vf_flr_done;

  wire                                       cfg_link_training_enable;
  wire                              [7:0]    cfg_ds_port_number;



  //----------------------------------------------------------------------------------------------------------------//
  // EP Only                                                                                                        //
  //----------------------------------------------------------------------------------------------------------------//

  // Interrupt Interface Signals
  wire                              [3:0]    cfg_interrupt_int;
  wire                              [1:0]    cfg_interrupt_pending;
  wire                                       cfg_interrupt_sent;

  wire                              [1:0]    cfg_interrupt_msix_enable;
  wire                              [1:0]    cfg_interrupt_msix_mask;
  wire                              [5:0]    cfg_interrupt_msix_vf_enable;
  wire                              [5:0]    cfg_interrupt_msix_vf_mask;
  wire                             [31:0]    cfg_interrupt_msix_data;
  wire                             [63:0]    cfg_interrupt_msix_address;
  wire                                       cfg_interrupt_msix_int;
  wire                                       cfg_interrupt_msix_sent;
  wire                                       cfg_interrupt_msix_fail;


// EP only
  wire                                       cfg_hot_reset_out;
  wire                                       cfg_config_space_enable;
  wire                                       cfg_req_pm_transition_l23_ready;

// RP only
  wire                                       cfg_hot_reset_in;

  wire                              [7:0]    cfg_ds_bus_number;
  wire                              [4:0]    cfg_ds_device_number;

  //----------------------------------------------------------------------------------------------------------------//
  // 8. System(SYS) Interface                                                                                       //
  //----------------------------------------------------------------------------------------------------------------//

  wire                                       sys_clk;
  wire                                       sys_clk_gt;
  wire                                       sys_rst_n_c;

  //-----------------------------------------------------------------------------------------------------------------------

  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));

  IBUFDS_GTE4 refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));


  wire [15:0]  cfg_vend_id        = 16'h10EE; 

  wire [15:0]  cfg_dev_id         = 16'h903F; 
  wire [15:0]  cfg_subsys_id      = 16'h0007; 
  wire [7:0]   cfg_rev_id         = 8'h00;    
  wire [15:0]  cfg_subsys_vend_id = 16'h10EE; 

  wire  [63:0] cfg_interrupt_msi_pending_status;
  wire  [3:0]  cfg_interrupt_msi_select;
  wire  [31:0] cfg_interrupt_msi_int;
  wire  [2:0]  cfg_interrupt_msi_attr;
  wire         cfg_interrupt_msi_tph_present;
  wire  [1:0]  cfg_interrupt_msi_tph_type;
  wire  [7:0]  cfg_interrupt_msi_tph_st_tag;
  wire  [2:0]  cfg_interrupt_msi_function_number;

   // new module
design_rp_wrapper design_rp_wrapper_i
   (.PCIE0_GT_0_grx_n  ( pci_exp_rxn ),
    .PCIE0_GT_0_grx_p  ( pci_exp_rxp ),
    .PCIE0_GT_0_gtx_n  ( pci_exp_txn ),
    .PCIE0_GT_0_gtx_p  ( pci_exp_txp ),
    .cpm_cor_irq_0  ( ),
    .cpm_irq0_0  ( 'h0),
    .cpm_irq1_0  ( 'h0),
    .cpm_misc_irq_0  ( ),
    .cpm_uncor_irq_0  ( ),
    .gt_refclk0_0_clk_n  ( ~sys_clk_gt),
    .gt_refclk0_0_clk_p  ( sys_clk_gt),
    .pcie0_cfg_control_0_err_cor_in  ( cfg_err_cor_in),
    .pcie0_cfg_control_0_err_uncor_in  ( cfg_err_uncor_in),
    .pcie0_cfg_control_0_flr_done  ( {2'b0,cfg_flr_done}),
    .pcie0_cfg_control_0_flr_in_process  ( cfg_flr_in_process),
    .pcie0_cfg_control_0_hot_reset_in  ( cfg_hot_reset_in),
    .pcie0_cfg_control_0_hot_reset_out  ( cfg_hot_reset_out),
    .pcie0_cfg_control_0_power_state_change_ack  ( cfg_power_state_change_ack),
    .pcie0_cfg_control_0_power_state_change_interrupt  ( cfg_power_state_change_interrupt),
    .pcie0_cfg_ext_0_function_number  ( cfg_ext_function_number),
    .pcie0_cfg_ext_0_read_data  ( cfg_ext_read_data),
    .pcie0_cfg_ext_0_read_data_valid  ( cfg_ext_read_data_valid),
    .pcie0_cfg_ext_0_read_received  ( cfg_ext_read_received),
    .pcie0_cfg_ext_0_register_number  ( cfg_ext_register_number),
    .pcie0_cfg_ext_0_write_byte_enable  ( cfg_ext_write_byte_enable),
    .pcie0_cfg_ext_0_write_data  (cfg_ext_write_data ),
    .pcie0_cfg_ext_0_write_received  ( cfg_ext_write_received),
    .pcie0_cfg_fc_0_cpld  ( cfg_fc_cpld),
    .pcie0_cfg_fc_0_cpld_scale  ( ),
    .pcie0_cfg_fc_0_cplh  ( cfg_fc_cplh),
    .pcie0_cfg_fc_0_cplh_scale  ( ),
    .pcie0_cfg_fc_0_npd  ( cfg_fc_npd),
    .pcie0_cfg_fc_0_npd_scale  ( ),
    .pcie0_cfg_fc_0_nph  ( cfg_fc_nph),
    .pcie0_cfg_fc_0_nph_scale  ( ),
    .pcie0_cfg_fc_0_pd  ( cfg_fc_pd),
    .pcie0_cfg_fc_0_pd_scale  ( ),
    .pcie0_cfg_fc_0_ph  ( cfg_fc_ph),
    .pcie0_cfg_fc_0_ph_scale  ( ),
    .pcie0_cfg_fc_0_sel  ( cfg_fc_sel),
    .pcie0_cfg_fc_0_vc_sel  ( 'h0),
    .pcie0_cfg_interrupt_0_intx_vector  ( cfg_interrupt_int),
    .pcie0_cfg_interrupt_0_pending  ({2'b0,cfg_interrupt_pending} ),
    .pcie0_cfg_interrupt_0_sent  ( cfg_interrupt_sent),
    .pcie0_cfg_mgmt_0_addr  ( cfg_mgmt_addr ),
    .pcie0_cfg_mgmt_0_byte_en  ( cfg_mgmt_byte_enable ),
    .pcie0_cfg_mgmt_0_debug_access  ( 1'b0 ),
    .pcie0_cfg_mgmt_0_function_number  (8'b0 ),
    .pcie0_cfg_mgmt_0_read_data  (cfg_mgmt_read_data ),
    .pcie0_cfg_mgmt_0_read_en  ( cfg_mgmt_read ),
    .pcie0_cfg_mgmt_0_read_write_done  ( cfg_mgmt_read_write_done ),
    .pcie0_cfg_mgmt_0_write_data  ( cfg_mgmt_write_data ),
    .pcie0_cfg_mgmt_0_write_en  ( cfg_mgmt_write ),
    .pcie0_cfg_msg_recd_0_recd  ( cfg_msg_received),
    .pcie0_cfg_msg_recd_0_recd_data  (cfg_msg_received_data ),
    .pcie0_cfg_msg_recd_0_recd_type  ( cfg_msg_received_type),
    .pcie0_cfg_msg_tx_0_transmit  ( cfg_msg_transmit),
    .pcie0_cfg_msg_tx_0_transmit_data  ( cfg_msg_transmit_data),
    .pcie0_cfg_msg_tx_0_transmit_done  ( cfg_msg_transmit_done),
    .pcie0_cfg_msg_tx_0_transmit_type  ( cfg_msg_transmit_type),
    .pcie0_cfg_status_0_10b_tag_requester_enable  ( ),
    .pcie0_cfg_status_0_atomic_requester_enable  ( ),
    .pcie0_cfg_status_0_cq_np_req  ({1'b0,pcie_cq_np_req} ),
    .pcie0_cfg_status_0_cq_np_req_count  ( pcie_cq_np_req_count),
    .pcie0_cfg_status_0_current_speed  ( cfg_current_speed),
    .pcie0_cfg_status_0_err_cor_out  ( cfg_err_cor_out),
    .pcie0_cfg_status_0_err_fatal_out  ( cfg_err_fatal_out),
    .pcie0_cfg_status_0_err_nonfatal_out  ( cfg_err_nonfatal_out),
    .pcie0_cfg_status_0_ext_tag_enable  ( ),
    .pcie0_cfg_status_0_function_power_state  ( cfg_function_power_state),
    .pcie0_cfg_status_0_function_status  ( cfg_function_status),
    .pcie0_cfg_status_0_link_power_state  ( cfg_link_power_state),
    .pcie0_cfg_status_0_local_error_out  ( ),
    .pcie0_cfg_status_0_local_error_valid  ( ),
    .pcie0_cfg_status_0_ltssm_state  ( cfg_ltssm_state),
    .pcie0_cfg_status_0_max_payload  ( cfg_max_payload),
    .pcie0_cfg_status_0_max_read_req  ( cfg_max_read_req),
    .pcie0_cfg_status_0_negotiated_width  ( cfg_negotiated_width),
    .pcie0_cfg_status_0_phy_link_down  ( cfg_phy_link_down),
    .pcie0_cfg_status_0_phy_link_status  ( ),
    .pcie0_cfg_status_0_pl_status_change  ( cfg_pl_status_change),
    .pcie0_cfg_status_0_rcb_status  ( cfg_rcb_status),
    .pcie0_cfg_status_0_rq_seq_num0  ( ),
    .pcie0_cfg_status_0_rq_seq_num1  ( ),
    .pcie0_cfg_status_0_rq_seq_num_vld0  ( ),
    .pcie0_cfg_status_0_rq_seq_num_vld1  ( ),
    .pcie0_cfg_status_0_rq_tag0  ( ),
    .pcie0_cfg_status_0_rq_tag1  ( ),
    .pcie0_cfg_status_0_rq_tag_av  ( ),
    .pcie0_cfg_status_0_rq_tag_vld0  ( ),
    .pcie0_cfg_status_0_rq_tag_vld1  ( ),
    .pcie0_cfg_status_0_rx_pm_state  ( ),
    .pcie0_cfg_status_0_tph_requester_enable  (cfg_tph_requester_enable ),
    .pcie0_cfg_status_0_tph_st_mode  ( cfg_tph_st_mode),
    .pcie0_cfg_status_0_tx_pm_state  ( ),
    .pcie0_m_axis_cq_0_tdata  ( m_axis_cq_tdata),
    .pcie0_m_axis_cq_0_tkeep  ( m_axis_cq_tkeep),
    .pcie0_m_axis_cq_0_tlast  ( m_axis_cq_tlast),
    .pcie0_m_axis_cq_0_tready  ( m_axis_cq_tready),
    .pcie0_m_axis_cq_0_tuser  ( m_axis_cq_tuser),
    .pcie0_m_axis_cq_0_tvalid  (m_axis_cq_tvalid ),
    .pcie0_m_axis_rc_0_tdata  ( m_axis_rc_tdata),
    .pcie0_m_axis_rc_0_tkeep  ( m_axis_rc_tkeep),
    .pcie0_m_axis_rc_0_tlast  ( m_axis_rc_tlast),
    .pcie0_m_axis_rc_0_tready  ( m_axis_rc_tready),
    .pcie0_m_axis_rc_0_tuser  (m_axis_rc_tuser ),
    .pcie0_m_axis_rc_0_tvalid  ( m_axis_rc_tvalid),
    .pcie0_pipe_rp_0_commands_in  ( pcie0_pipe_rp_0_commands_in),
    .pcie0_pipe_rp_0_commands_out  ( pcie0_pipe_rp_0_commands_out),
    .pcie0_pipe_rp_0_rx_0   ( pcie0_pipe_rp_0_rx_0 ),
    .pcie0_pipe_rp_0_rx_1   ( pcie0_pipe_rp_0_rx_1 ),
    .pcie0_pipe_rp_0_rx_10  ( pcie0_pipe_rp_0_rx_10 ),
    .pcie0_pipe_rp_0_rx_11  ( pcie0_pipe_rp_0_rx_11 ),
    .pcie0_pipe_rp_0_rx_12  ( pcie0_pipe_rp_0_rx_12 ),
    .pcie0_pipe_rp_0_rx_13  ( pcie0_pipe_rp_0_rx_13 ),
    .pcie0_pipe_rp_0_rx_14  ( pcie0_pipe_rp_0_rx_14 ),
    .pcie0_pipe_rp_0_rx_15  ( pcie0_pipe_rp_0_rx_15 ),
    .pcie0_pipe_rp_0_rx_2   ( pcie0_pipe_rp_0_rx_2 ),
    .pcie0_pipe_rp_0_rx_3   ( pcie0_pipe_rp_0_rx_3 ),
    .pcie0_pipe_rp_0_rx_4   ( pcie0_pipe_rp_0_rx_4 ),
    .pcie0_pipe_rp_0_rx_5   ( pcie0_pipe_rp_0_rx_5 ),
    .pcie0_pipe_rp_0_rx_6   ( pcie0_pipe_rp_0_rx_6 ),
    .pcie0_pipe_rp_0_rx_7   ( pcie0_pipe_rp_0_rx_7 ),
    .pcie0_pipe_rp_0_rx_8   ( pcie0_pipe_rp_0_rx_8 ),
    .pcie0_pipe_rp_0_rx_9   ( pcie0_pipe_rp_0_rx_9 ),
    .pcie0_pipe_rp_0_tx_0   ( pcie0_pipe_rp_0_tx_0 ),
    .pcie0_pipe_rp_0_tx_1   ( pcie0_pipe_rp_0_tx_1 ),
    .pcie0_pipe_rp_0_tx_10  ( pcie0_pipe_rp_0_tx_10 ),
    .pcie0_pipe_rp_0_tx_11  ( pcie0_pipe_rp_0_tx_11 ),
    .pcie0_pipe_rp_0_tx_12  ( pcie0_pipe_rp_0_tx_12 ),
    .pcie0_pipe_rp_0_tx_13  ( pcie0_pipe_rp_0_tx_13 ),
    .pcie0_pipe_rp_0_tx_14  ( pcie0_pipe_rp_0_tx_14 ),
    .pcie0_pipe_rp_0_tx_15  ( pcie0_pipe_rp_0_tx_15 ),
    .pcie0_pipe_rp_0_tx_2   ( pcie0_pipe_rp_0_tx_2 ),
    .pcie0_pipe_rp_0_tx_3   ( pcie0_pipe_rp_0_tx_3 ),
    .pcie0_pipe_rp_0_tx_4   ( pcie0_pipe_rp_0_tx_4 ),
    .pcie0_pipe_rp_0_tx_5   ( pcie0_pipe_rp_0_tx_5 ),
    .pcie0_pipe_rp_0_tx_6   ( pcie0_pipe_rp_0_tx_6 ),
    .pcie0_pipe_rp_0_tx_7   ( pcie0_pipe_rp_0_tx_7 ),
    .pcie0_pipe_rp_0_tx_8   ( pcie0_pipe_rp_0_tx_8 ),
    .pcie0_pipe_rp_0_tx_9   ( pcie0_pipe_rp_0_tx_9 ),
    .pcie0_s_axis_cc_0_tdata  ( s_axis_cc_tdata),
    .pcie0_s_axis_cc_0_tkeep  ( s_axis_cc_tkeep),
    .pcie0_s_axis_cc_0_tlast  ( s_axis_cc_tlast),
    .pcie0_s_axis_cc_0_tready  ( s_axis_cc_tready),
    .pcie0_s_axis_cc_0_tuser  ( s_axis_cc_tuser),
    .pcie0_s_axis_cc_0_tvalid  ( s_axis_cc_tvalid),
    .pcie0_s_axis_rq_0_tdata  ( s_axis_rq_tdata),
    .pcie0_s_axis_rq_0_tkeep  ( s_axis_rq_tkeep),
    .pcie0_s_axis_rq_0_tlast  ( s_axis_rq_tlast),
    .pcie0_s_axis_rq_0_tready  ( s_axis_rq_tready),
    .pcie0_s_axis_rq_0_tuser  ( s_axis_rq_tuser),
    .pcie0_s_axis_rq_0_tvalid  ( s_axis_rq_tvalid),
    .pcie0_transmit_fc_0_npd_av  ( pcie_tfc_npd_av),
    .pcie0_transmit_fc_0_nph_av  ( pcie_tfc_nph_av),
    .pcie0_user_clk_0  (  user_clk),
    .pcie0_user_lnk_up_0  (user_lnk_up ),
    .pcie0_user_reset_0  ( user_reset)
    );

/*
  //--------------------------------------------------------------------------------------------------------------------//
  // Instantiate Root Port wrapper
  //--------------------------------------------------------------------------------------------------------------------//
  // Core Top Level Wrapper
 pcie_4_0_rp pcie_4_0_rport (
    //---------------------------------------------------------------------------------------//
    //  PCI Express (pci_exp) Interface                                                      //
    //---------------------------------------------------------------------------------------//
    .cfg_vend_id                                    (cfg_vend_id),  
    .cfg_dev_id_pf0                                 (cfg_dev_id),
    .cfg_dev_id_pf1                                 (cfg_dev_id),
    .cfg_dev_id_pf2                                 (cfg_dev_id),
    .cfg_dev_id_pf3                                 (cfg_dev_id),
    .cfg_rev_id_pf0                                 (cfg_rev_id),
    .cfg_rev_id_pf1                                 (cfg_rev_id),
    .cfg_rev_id_pf2                                 (cfg_rev_id),
    .cfg_rev_id_pf3                                 (cfg_rev_id),
    .cfg_subsys_id_pf0                              (cfg_subsys_id),
    .cfg_subsys_id_pf1                              (cfg_subsys_id),
    .cfg_subsys_id_pf2                              (cfg_subsys_id),
    .cfg_subsys_id_pf3                              (cfg_subsys_id),
    .cfg_subsys_vend_id                             (cfg_subsys_vend_id),

    .cfg_mgmt_debug_access                          (1'b0),
    .cfg_mgmt_function_number                       (8'b0),

    .cfg_vf_flr_func_num                            (8'b0),
    .conf_mcap_request_by_conf                      (1'b0),
    .conf_req_type                                  (2'b0),
    .conf_req_reg_num                               (4'b0),
    .conf_req_data                                  (32'b0),
    .conf_req_valid                                 (1'b0),

    .pl_gen2_upstream_prefer_deemph                 (1'b0),
    .pl_redo_eq                                     (1'b0),
    .pl_redo_eq_speed                               (1'b0),

    //---------------------------------------------------------------------------------------//
    //  PCI Express (pci_exp) Interface                                                      //
    //---------------------------------------------------------------------------------------//

    // Tx
    .pci_exp_txn                                    ( pci_exp_txn ),
    .pci_exp_txp                                    ( pci_exp_txp ),

    // Rx
    .pci_exp_rxn                                    ( pci_exp_rxn ),
    .pci_exp_rxp                                    ( pci_exp_rxp ),


   //---------------------------------------------------------------------------------------//
    //  AXI Interface                                                                        //
    //---------------------------------------------------------------------------------------//

    .user_clk                                       ( user_clk ),
    .user_reset                                     ( user_reset ),
    .user_lnk_up                                    ( user_lnk_up ),

    .s_axis_rq_tlast                                ( s_axis_rq_tlast ),
    .s_axis_rq_tdata                                ( s_axis_rq_tdata ),
    .s_axis_rq_tuser                                ( s_axis_rq_tuser ),
    .s_axis_rq_tkeep                                ( s_axis_rq_tkeep ),
    .s_axis_rq_tready                               ( s_axis_rq_tready ),
    .s_axis_rq_tvalid                               ( s_axis_rq_tvalid ),

    .m_axis_rc_tdata                                ( m_axis_rc_tdata ),
    .m_axis_rc_tuser                                ( m_axis_rc_tuser ),
    .m_axis_rc_tlast                                ( m_axis_rc_tlast ),
    .m_axis_rc_tkeep                                ( m_axis_rc_tkeep ),
    .m_axis_rc_tvalid                               ( m_axis_rc_tvalid ),
    .m_axis_rc_tready                               ( {22{m_axis_rc_tready}} ),


    .m_axis_cq_tdata                                ( m_axis_cq_tdata ),
    .m_axis_cq_tuser                                ( m_axis_cq_tuser ),
    .m_axis_cq_tlast                                ( m_axis_cq_tlast ),
    .m_axis_cq_tkeep                                ( m_axis_cq_tkeep ),
    .m_axis_cq_tvalid                               ( m_axis_cq_tvalid ),
    .m_axis_cq_tready                               ( {22{m_axis_cq_tready}} ),

    .s_axis_cc_tdata                                ( s_axis_cc_tdata ),
    .s_axis_cc_tuser                                ( s_axis_cc_tuser ),
    .s_axis_cc_tlast                                ( s_axis_cc_tlast ),
    .s_axis_cc_tkeep                                ( s_axis_cc_tkeep ),
    .s_axis_cc_tvalid                               ( s_axis_cc_tvalid ),
    .s_axis_cc_tready                               ( s_axis_cc_tready ),

    //---------------------------------------------------------------------------------------//
    //  Configuration (CFG) Interface                                                        //
    //---------------------------------------------------------------------------------------//

    .pcie_cq_np_req                                 ( {1'b0,pcie_cq_np_req} ),
    .pcie_cq_np_req_count                           ( pcie_cq_np_req_count ),
    .cfg_phy_link_down                              ( cfg_phy_link_down ),
    .cfg_phy_link_status                            ( ),
    .cfg_negotiated_width                           ( cfg_negotiated_width ),
    .cfg_current_speed                              ( cfg_current_speed ),
    .cfg_max_payload                                ( cfg_max_payload ),
    .cfg_max_read_req                               ( cfg_max_read_req ),
    .cfg_function_status                            ( cfg_function_status ),
    .cfg_function_power_state                       ( cfg_function_power_state ),
    .cfg_vf_status                                  ( cfg_vf_status ),
    .cfg_vf_power_state                             ( cfg_vf_power_state ),
    .cfg_link_power_state                           ( cfg_link_power_state ),
    // Error Reporting Interface
    .cfg_err_cor_out                                ( cfg_err_cor_out ),
    .cfg_err_nonfatal_out                           ( cfg_err_nonfatal_out ),
    .cfg_err_fatal_out                              ( cfg_err_fatal_out ),

    .cfg_local_error_out                                ( ),

    .cfg_ltssm_state                                ( cfg_ltssm_state ),
    .cfg_rcb_status                                 ( cfg_rcb_status ),

    .cfg_obff_enable                                ( cfg_obff_enable ),
    .cfg_pl_status_change                           ( cfg_pl_status_change ),

    .cfg_tph_requester_enable                       ( cfg_tph_requester_enable ),
    .cfg_tph_st_mode                                ( cfg_tph_st_mode ),
    .cfg_vf_tph_requester_enable                    ( cfg_vf_tph_requester_enable ),
    .cfg_vf_tph_st_mode                             ( cfg_vf_tph_st_mode ),


    // Management Interface
    .cfg_mgmt_addr                                  ( cfg_mgmt_addr ),
    .cfg_mgmt_write                                 ( cfg_mgmt_write ),
    .cfg_mgmt_write_data                            ( cfg_mgmt_write_data ),
    .cfg_mgmt_byte_enable                           ( cfg_mgmt_byte_enable ),
    .cfg_mgmt_read                                  ( cfg_mgmt_read ),
    .cfg_mgmt_read_data                             ( cfg_mgmt_read_data ),
    .cfg_mgmt_read_write_done                       ( cfg_mgmt_read_write_done ),
    //.cfg_mgmt_type1_cfg_reg_access                  ( cfg_mgmt_type1_cfg_reg_access ),//Additional
    .pcie_tfc_nph_av                                ( pcie_tfc_nph_av ),
    .pcie_tfc_npd_av                                ( pcie_tfc_npd_av ),
    .cfg_msg_received                               ( cfg_msg_received ),
    .cfg_msg_received_data                          ( cfg_msg_received_data ),
    .cfg_msg_received_type                          ( cfg_msg_received_type ),

    .cfg_msg_transmit                               ( cfg_msg_transmit ),
    .cfg_msg_transmit_type                          ( cfg_msg_transmit_type ),
    .cfg_msg_transmit_data                          ( cfg_msg_transmit_data ),
    .cfg_msg_transmit_done                          ( cfg_msg_transmit_done ),

    .cfg_fc_ph                                      ( cfg_fc_ph ),
    .cfg_fc_pd                                      ( cfg_fc_pd ),
    .cfg_fc_nph                                     ( cfg_fc_nph ),
    .cfg_fc_npd                                     ( cfg_fc_npd ),
    .cfg_fc_cplh                                    ( cfg_fc_cplh ),
    .cfg_fc_cpld                                    ( cfg_fc_cpld ),
    .cfg_fc_sel                                     ( cfg_fc_sel ),

  //-------------------------------------------------------------------------------//
    // EP and RP                                                                     //
    //-------------------------------------------------------------------------------//

    .cfg_bus_number                                 ( ),
    .cfg_dsn                                        ( cfg_dsn ),
    .cfg_power_state_change_ack                     ( cfg_power_state_change_ack ),
    .cfg_power_state_change_interrupt               ( cfg_power_state_change_interrupt ),
    .cfg_err_cor_in                                 ( cfg_err_cor_in ),
    .cfg_err_uncor_in                               ( cfg_err_uncor_in ),

    .cfg_flr_in_process                             ( cfg_flr_in_process ),
    .cfg_flr_done                                   ( {2'b0,cfg_flr_done} ),
    .cfg_vf_flr_in_process                          ( cfg_vf_flr_in_process ),
    .cfg_vf_flr_done                                ( cfg_vf_flr_done ),
    .cfg_link_training_enable                       ( cfg_link_training_enable ),
  // EP only
    .cfg_hot_reset_out                              ( cfg_hot_reset_out ),
    .cfg_config_space_enable                        ( cfg_config_space_enable ),
    .cfg_req_pm_transition_l23_ready                ( cfg_req_pm_transition_l23_ready ),

  // RP only
    .cfg_hot_reset_in                               ( cfg_hot_reset_in ),

    .cfg_ds_bus_number                              ( cfg_ds_bus_number ),
    .cfg_ds_device_number                           ( cfg_ds_device_number ),
    .cfg_ds_port_number                             ( cfg_ds_port_number ),
    .cfg_ext_read_received                          ( cfg_ext_read_received ),
    .cfg_ext_write_received                         ( cfg_ext_write_received ),
    .cfg_ext_register_number                        ( cfg_ext_register_number ),
    .cfg_ext_function_number                        ( cfg_ext_function_number ),
    .cfg_ext_write_data                             ( cfg_ext_write_data ),
    .cfg_ext_write_byte_enable                      ( cfg_ext_write_byte_enable ),
    .cfg_ext_read_data                              ( cfg_ext_read_data ),
    .cfg_ext_read_data_valid                        ( cfg_ext_read_data_valid ),


    //-------------------------------------------------------------------------------//
    // EP Only                                                                       //
    //-------------------------------------------------------------------------------//

    // Interrupt Interface Signals
    .cfg_interrupt_int                              ( cfg_interrupt_int ),
    .cfg_interrupt_pending                          ( {2'b0,cfg_interrupt_pending} ),
    .cfg_interrupt_sent                             ( cfg_interrupt_sent ),

    .cfg_interrupt_msi_enable                       ( cfg_interrupt_msi_enable ),
    .cfg_interrupt_msi_mmenable                     ( cfg_interrupt_msi_mmenable ),
    .cfg_interrupt_msi_mask_update                  ( cfg_interrupt_msi_mask_update ),
    .cfg_interrupt_msi_data                         ( cfg_interrupt_msi_data ),
    .cfg_interrupt_msi_select                       ( cfg_interrupt_msi_select ),
    .cfg_interrupt_msi_int                          ( cfg_interrupt_msi_int ),
    .cfg_interrupt_msi_pending_status               ( cfg_interrupt_msi_pending_status[31:0]),
    .cfg_interrupt_msi_sent                         ( cfg_interrupt_msi_sent ),
    .cfg_interrupt_msi_fail                         ( cfg_interrupt_msi_fail ),
    .cfg_interrupt_msi_attr                         ( cfg_interrupt_msi_attr ),
    .cfg_interrupt_msi_tph_present                  ( cfg_interrupt_msi_tph_present ),
    .cfg_interrupt_msi_tph_type                     ( cfg_interrupt_msi_tph_type ),
    .cfg_interrupt_msi_tph_st_tag                   ( cfg_interrupt_msi_tph_st_tag ),
    .cfg_interrupt_msi_function_number              (8'b0 ),
    .cfg_interrupt_msi_pending_status_function_num  (4'b0),
    .cfg_interrupt_msi_pending_status_data_enable   (1'b0),

    .cfg_pm_aspm_l1_entry_reject                    (1'b0),
    .cfg_pm_aspm_tx_l0s_entry_disable               (1'b1),

    //--------------------------------------------------------------------------------------//
    //  System(SYS) Interface                                                               //
    //--------------------------------------------------------------------------------------//

    .sys_clk                                        ( sys_clk ),
    .sys_clk_gt                                     ( sys_clk_gt ),
    .sys_reset                                      ( sys_rst_n_c )


  );
*/
  pci_exp_usrapp_rx # (
    .AXISTEN_IF_CC_ALIGNMENT_MODE     ( AXISTEN_IF_CC_ALIGNMENT_MODE ),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE     ( AXISTEN_IF_CQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_ALIGNMENT_MODE     ( AXISTEN_IF_RC_ALIGNMENT_MODE ), 
    .AXISTEN_IF_RQ_ALIGNMENT_MODE     ( AXISTEN_IF_RQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_PARITY_CHECK       ( AXISTEN_IF_RC_PARITY_CHECK   ),
    .AXISTEN_IF_CQ_PARITY_CHECK       ( AXISTEN_IF_CQ_PARITY_CHECK   ),
    .C_DATA_WIDTH                     ( C_DATA_WIDTH                 )
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
//  pci_exp_usrapp_tx_sriov # (
    .C_DATA_WIDTH                     ( C_DATA_WIDTH),
    .DEV_CAP_MAX_PAYLOAD_SUPPORTED    ( PF0_DEV_CAP_MAX_PAYLOAD_SIZE ),
    .AXISTEN_IF_CC_ALIGNMENT_MODE     ( AXISTEN_IF_CC_ALIGNMENT_MODE ),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE     ( AXISTEN_IF_CQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_ALIGNMENT_MODE     ( AXISTEN_IF_RC_ALIGNMENT_MODE ),
    .AXISTEN_IF_RQ_ALIGNMENT_MODE     ( AXISTEN_IF_RQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RQ_PARITY_CHECK       ( AXISTEN_IF_RQ_PARITY_CHECK   ),
    .AXISTEN_IF_CC_PARITY_CHECK       ( AXISTEN_IF_CC_PARITY_CHECK   ),
    .EP_DEV_ID                        ( EP_DEV_ID                    )
  ) tx_usrapp (
  .s_axis_rq_tlast    (s_axis_rq_tlast),
  .s_axis_rq_tdata    (s_axis_rq_tdata),
  .s_axis_rq_tuser    (s_axis_rq_tuser),
  .s_axis_rq_tkeep    (s_axis_rq_tkeep),
  .s_axis_rq_tready   (s_axis_rq_tready),
  .s_axis_rq_tvalid   (s_axis_rq_tvalid),
  .s_axis_cc_tdata    (s_axis_cc_tdata),
  .s_axis_cc_tuser    (s_axis_cc_tuser),
  .s_axis_cc_tlast    (s_axis_cc_tlast),
  .s_axis_cc_tkeep    (s_axis_cc_tkeep),
  .s_axis_cc_tvalid   (s_axis_cc_tvalid),
  .s_axis_cc_tready   (s_axis_cc_tready),
  .pcie_rq_seq_num    (pcie_rq_seq_num),
  .pcie_rq_seq_num_vld(pcie_rq_seq_num_vld),
  .pcie_rq_tag        (pcie_rq_tag),
  .pcie_rq_tag_vld    (pcie_rq_tag_vld),
  .pcie_tfc_nph_av    (pcie_tfc_nph_av),
  .pcie_tfc_npd_av    (pcie_tfc_npd_av),
  .speed_change_done_n(),
  .user_clk           (user_clk),
  .reset            (user_reset),
  .user_lnk_up      (user_lnk_up)


  );

  // Cfg UsrApp

  pci_exp_usrapp_cfg cfg_usrapp (

 .user_clk                                  (user_clk),
 .user_reset                                (user_reset),
  //-------------------------------------------------------------------------------------------//
  // 4. Configuration (CFG) Interface                                                          //
  //-------------------------------------------------------------------------------------------//
  // EP and RP                                                                                 //
  //-------------------------------------------------------------------------------------------//

 .cfg_phy_link_down                         (cfg_phy_link_down),
 .cfg_phy_link_status                       (cfg_phy_link_status),
 .cfg_negotiated_width                      (cfg_negotiated_width),
 .cfg_current_speed                         (cfg_current_speed),
 .cfg_max_payload                           (cfg_max_payload),
 .cfg_max_read_req                          (cfg_max_read_req),
 .cfg_function_status                       (cfg_function_status),
 .cfg_function_power_state                  (cfg_function_power_state),
 .cfg_vf_status                             (cfg_vf_status),
 .cfg_vf_power_state                        (cfg_vf_power_state),
 .cfg_link_power_state                      (cfg_link_power_state),


  // Error Reporting Interface
 .cfg_err_cor_out                           (cfg_err_cor_out),
 .cfg_err_nonfatal_out                      (cfg_err_nonfatal_out),
 .cfg_err_fatal_out                         (cfg_err_fatal_out),

 .cfg_ltr_enable                            (1'b0),
 .cfg_ltssm_state                           (cfg_ltssm_state),
 .cfg_rcb_status                            (cfg_rcb_status),
 .cfg_dpa_substate_change                   (cfg_dpa_substate_change),
 .cfg_obff_enable                           (cfg_obff_enable),
 .cfg_pl_status_change                      (cfg_pl_status_change),

 .cfg_tph_requester_enable                  (cfg_tph_requester_enable),
 .cfg_tph_st_mode                           (cfg_tph_st_mode),
 .cfg_vf_tph_requester_enable               (cfg_vf_tph_requester_enable),
 .cfg_vf_tph_st_mode                        (cfg_vf_tph_st_mode),
  // Management Interface
 .cfg_mgmt_addr                             (cfg_mgmt_addr),
 .cfg_mgmt_write                            (cfg_mgmt_write),
 .cfg_mgmt_write_data                       (cfg_mgmt_write_data),
 .cfg_mgmt_byte_enable                      (cfg_mgmt_byte_enable),

 .cfg_mgmt_read                             (cfg_mgmt_read),
 .cfg_mgmt_read_data                        (cfg_mgmt_read_data),
 .cfg_mgmt_read_write_done                  (cfg_mgmt_read_write_done),
 .cfg_mgmt_type1_cfg_reg_access             (cfg_mgmt_type1_cfg_reg_access),
 .cfg_msg_received                          (cfg_msg_received),
 .cfg_msg_received_data                     (cfg_msg_received_data),
 .cfg_msg_received_type                     (cfg_msg_received_type),
 .cfg_msg_transmit                          (cfg_msg_transmit),
 .cfg_msg_transmit_type                     (cfg_msg_transmit_type),
 .cfg_msg_transmit_data                     (cfg_msg_transmit_data),
 .cfg_msg_transmit_done                     (cfg_msg_transmit_done),
 .cfg_fc_ph                                 (cfg_fc_ph),
 .cfg_fc_pd                                 (cfg_fc_pd),
 .cfg_fc_nph                                (cfg_fc_nph),
 .cfg_fc_npd                                (cfg_fc_npd),
 .cfg_fc_cplh                               (cfg_fc_cplh),
 .cfg_fc_cpld                               (cfg_fc_cpld),
 .cfg_fc_sel                                (cfg_fc_sel),

 .cfg_per_func_status_control               (cfg_per_func_status_control),
 .cfg_per_func_status_data                  (cfg_per_func_status_data),
 .cfg_per_function_number                   (cfg_per_function_number),
 .cfg_per_function_output_request           (cfg_per_function_output_request),
 .cfg_per_function_update_done              (cfg_per_function_update_done),

 .cfg_dsn                                   (cfg_dsn),
 .cfg_power_state_change_ack                (cfg_power_state_change_ack),
 .cfg_power_state_change_interrupt          (cfg_power_state_change_interrupt),
 .cfg_err_cor_in                            (cfg_err_cor_in),
 .cfg_err_uncor_in                          (cfg_err_uncor_in),

 .cfg_flr_in_process                        (cfg_flr_in_process),
 .cfg_flr_done                              (cfg_flr_done),
 .cfg_vf_flr_in_process                     (cfg_vf_flr_in_process),
 .cfg_vf_flr_done                           (cfg_vf_flr_done),

 .cfg_link_training_enable                  (cfg_link_training_enable),
 .cfg_ds_port_number                        (cfg_ds_port_number),


 .cfg_interrupt_msix_enable                 (cfg_interrupt_msix_enable),
 .cfg_interrupt_msix_mask                   (cfg_interrupt_msix_mask),
 .cfg_interrupt_msix_vf_enable              (cfg_interrupt_msix_vf_enable),
 .cfg_interrupt_msix_vf_mask                (cfg_interrupt_msix_vf_mask),
 .cfg_interrupt_msix_data                   (cfg_interrupt_msix_data),
 .cfg_interrupt_msix_address                (cfg_interrupt_msix_address),
 .cfg_interrupt_msix_int                    (cfg_interrupt_msix_int),
 .cfg_interrupt_msix_sent                   (cfg_interrupt_msix_sent),
 .cfg_interrupt_msix_fail                   (cfg_interrupt_msix_fail),

 .cfg_hot_reset_out                         (cfg_hot_reset_out),
 .cfg_config_space_enable                   (cfg_config_space_enable),
 .cfg_req_pm_transition_l23_ready           (cfg_req_pm_transition_l23_ready),
  //------------------------------------------------------------------------------------------//
  // RP Only                                                                                  //
  //------------------------------------------------------------------------------------------//
 .cfg_hot_reset_in                          (cfg_hot_reset_in),

 .cfg_ds_bus_number                         (cfg_ds_bus_number),
 .cfg_ds_device_number                      (cfg_ds_device_number),
 .cfg_ds_function_number                    (),

  // Interrupt Interface Signals
 .cfg_interrupt_int                         (cfg_interrupt_int),
 .cfg_interrupt_pending                     (cfg_interrupt_pending),
 .cfg_interrupt_sent                        (cfg_interrupt_sent)

  );


assign  cfg_interrupt_msi_pending_status = 64'b0;
assign  cfg_interrupt_msi_select = 4'b0;
assign  cfg_interrupt_msi_int = 32'b0;
assign  cfg_interrupt_msi_attr = 3'b0;
assign  cfg_interrupt_msi_tph_present = 1'b0;
assign  cfg_interrupt_msi_tph_type = 2'b0;
assign  cfg_interrupt_msi_tph_st_tag = 8'h00;
assign  cfg_interrupt_msi_function_number = 3'b0;


  // Common UsrApp

  pci_exp_usrapp_com com_usrapp   ();






endmodule
