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
// Project    : Versal CPM5N Root port
// File       : design_rp_wrapper.v
// Version    : 2.0
// Note       : This design_rp_wrapper supports multi-controllers
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module design_rp_wrapper # (
  parameter PCIE_CTRL_MODE                      = 1,        // 0 - PCIE0(x16), 1 - PCIE0+2(x8x8) -- Add more when other configuration is supported
  parameter C_DATA_WIDTH                        = 512,     //512, // RX/TX interface data width

  parameter        PL_LINK_CAP_MAX_LINK_SPEED   = 16,//4,   // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4. 16 - GEN5
  parameter  [4:0] PL_LINK_CAP_MAX_LINK_WIDTH   = 16,//16,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16

  parameter  [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'h0,
  parameter PL_DISABLE_EI_INFER_IN_L0           = "TRUE",
  parameter PL_DISABLE_UPCONFIG_CAPABLE         = "FALSE",

  parameter REF_CLK_FREQ                        = 0,        // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter AXISTEN_IF_RQ_ALIGNMENT_MODE        = "FALSE",
  parameter AXISTEN_IF_CC_ALIGNMENT_MODE        = "FALSE",
  parameter AXISTEN_IF_CQ_ALIGNMENT_MODE        = "FALSE",
  parameter AXISTEN_IF_RC_ALIGNMENT_MODE        = "FALSE",
  parameter AXI4_CQ_TUSER_WIDTH                 = 285,
  parameter AXI4_CC_TUSER_WIDTH                 = 135,
  parameter AXI4_RQ_TUSER_WIDTH                 = 223,
  parameter AXI4_RC_TUSER_WIDTH                 = 229,
  parameter AXISTEN_IF_ENABLE_CLIENT_TAG        = "TRUE",
  parameter AXISTEN_IF_RQ_PARITY_CHECK          = 0,
  parameter AXISTEN_IF_CC_PARITY_CHECK          = 0,
  parameter AXISTEN_IF_RC_PARITY_CHECK          = 0,
  parameter AXISTEN_IF_CQ_PARITY_CHECK          = 0,
  parameter AXISTEN_IF_MC_RX_STRADDLE           = "FALSE",
  parameter AXISTEN_IF_ENABLE_RX_MSG_INTFC      = "FALSE",
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE  = 18'h2FFFF,
  parameter KEEP_WIDTH                          = C_DATA_WIDTH / 32
)
(
  output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txp,
  output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txn,
  input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
  input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,
  input  sys_clk_p,
  input  sys_clk_n,
  input  sys_rst_n
);

  localparam         TCQ = 1;
  localparam         EP_DEV_ID = 16'hB03F;

  wire user_clk;
  wire user_reset_n;
  wire user_reset = !user_reset_n;

  // NOTE: All wire declarations are now expanded with an array of [3:0]
  //       to support up to 4 controllers.
  wire user_lnk_up[3:0];
  //----------------------------------------------------//
  // 3. AXI Interface                                   //
  //----------------------------------------------------//
  wire                           s_axis_rq_tlast[3:0];
  wire     [C_DATA_WIDTH-1:0]    s_axis_rq_tdata[3:0];
  wire [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser[3:0];
  wire       [KEEP_WIDTH-1:0]    s_axis_rq_tkeep[3:0];
  wire                           s_axis_rq_tready[3:0];
  wire                           s_axis_rq_tvalid[3:0];

  wire     [C_DATA_WIDTH-1:0]    m_axis_rc_tdata[3:0];
  wire [AXI4_RC_TUSER_WIDTH-1:0] m_axis_rc_tuser[3:0];
  wire                           m_axis_rc_tlast[3:0];
  wire       [KEEP_WIDTH-1:0]    m_axis_rc_tkeep[3:0];
  wire                           m_axis_rc_tvalid[3:0];
  wire                           m_axis_rc_tready[3:0];

  wire     [C_DATA_WIDTH-1:0]    m_axis_cq_tdata[3:0];
  wire [AXI4_CQ_TUSER_WIDTH-1:0] m_axis_cq_tuser[3:0];
  wire                           m_axis_cq_tlast[3:0];
  wire       [KEEP_WIDTH-1:0]    m_axis_cq_tkeep[3:0];
  wire                           m_axis_cq_tvalid[3:0];
  wire                           m_axis_cq_tready[3:0];

  wire     [C_DATA_WIDTH-1:0]    s_axis_cc_tdata[3:0];
  wire [AXI4_CC_TUSER_WIDTH-1:0] s_axis_cc_tuser[3:0];
  wire                           s_axis_cc_tlast[3:0];
  wire       [KEEP_WIDTH-1:0]    s_axis_cc_tkeep[3:0];
  wire                           s_axis_cc_tvalid[3:0];
  wire                           s_axis_cc_tready[3:0];

  wire [3:0] pcie_tfc_nph_av[3:0];
  wire [3:0] pcie_tfc_npd_av[3:0];
  wire [3:0] pcie_rq_seq_num[3:0];
  wire       pcie_rq_seq_num_vld[3:0];
  wire [5:0] pcie_rq_tag[3:0];
  wire       pcie_rq_tag_vld[3:0];
  wire [1:0] pcie_rq_tag_av[3:0];

  wire       pcie_cq_np_req[3:0];
  wire [5:0] pcie_cq_np_req_count[3:0];

  //---------------------------------------------------//
  // 4. Configuration (CFG) Interface                  //
  //---------------------------------------------------//

  //---------------------------------------------------//
  // EP and RP                                         //
  //---------------------------------------------------//

  wire         cfg_phy_link_down[3:0];
  wire  [1:0]  cfg_phy_link_status[3:0];
  wire  [2:0]  cfg_negotiated_width[3:0];
  wire  [1:0]  cfg_current_speed[3:0];
  wire  [1:0]  cfg_max_payload[3:0];
  wire  [2:0]  cfg_max_read_req[3:0];
  wire [15:0]  cfg_function_status[3:0];
  wire [11:0]  cfg_function_power_state[3:0];
  wire [503:0] cfg_vf_status[3:0];
  wire [755:0] cfg_vf_power_state[3:0];
  wire  [1:0]  cfg_link_power_state[3:0];

  // Management Interface
  wire  [9:0] cfg_mgmt_addr[3:0];
  wire        cfg_mgmt_write[3:0];
  wire [31:0] cfg_mgmt_write_data[3:0];
  wire  [3:0] cfg_mgmt_byte_enable[3:0];
  wire        cfg_mgmt_read[3:0];
  wire [31:0] cfg_mgmt_read_data[3:0];
  wire        cfg_mgmt_read_write_done[3:0];
  wire        cfg_mgmt_type1_cfg_reg_access[3:0];

  // Error Reporting Interface
  wire cfg_err_cor_out[3:0];
  wire cfg_err_nonfatal_out[3:0];
  wire cfg_err_fatal_out[3:0];
  wire cfg_local_error[3:0];

  wire [5:0] cfg_ltssm_state[3:0];
  wire [3:0] cfg_rcb_status[3:0];
  wire [3:0] cfg_dpa_substate_change[3:0];
  wire [1:0] cfg_obff_enable[3:0];
  wire       cfg_pl_status_change[3:0];

  wire  [3:0]   cfg_tph_requester_enable[3:0];
  wire [11:0]   cfg_tph_st_mode[3:0];
  wire [251:0]  cfg_vf_tph_requester_enable[3:0];
  wire [755:0]  cfg_vf_tph_st_mode[3:0];

  wire         cfg_msg_received[3:0];
  wire  [7:0]  cfg_msg_received_data[3:0];
  wire  [4:0]  cfg_msg_received_type[3:0];

  wire         cfg_msg_transmit[3:0];
  wire  [2:0]  cfg_msg_transmit_type[3:0];
  wire [31:0]  cfg_msg_transmit_data[3:0];
  wire         cfg_msg_transmit_done[3:0];

  wire  [7:0]  cfg_fc_ph[3:0];
  wire [11:0]  cfg_fc_pd[3:0];
  wire  [7:0]  cfg_fc_nph[3:0];
  wire [11:0]  cfg_fc_npd[3:0];
  wire  [7:0]  cfg_fc_cplh[3:0];
  wire [11:0]  cfg_fc_cpld[3:0];
  wire  [2:0]  cfg_fc_sel[3:0];

  wire  [2:0]  cfg_per_func_status_control[3:0];
  wire [15:0]  cfg_per_func_status_data[3:0];
  wire  [2:0]  cfg_per_function_number[3:0];
  wire         cfg_per_function_output_request[3:0];
  wire         cfg_per_function_update_done[3:0];

  wire [63:0]  cfg_dsn[3:0];
  wire cfg_power_state_change_ack[3:0];
  wire cfg_power_state_change_interrupt[3:0];
  wire cfg_err_cor_in[3:0];
  wire cfg_err_uncor_in[3:0];

  wire  [3:0]    cfg_flr_in_process[3:0];
  wire  [1:0]    cfg_flr_done[3:0];
  wire  [251:0]  cfg_vf_flr_in_process[3:0];
  wire           cfg_vf_flr_done[3:0];

  wire        cfg_link_training_enable[3:0];
  wire  [7:0] cfg_ds_port_number[3:0];

  wire        cfg_ext_read_received[3:0];
  wire        cfg_ext_write_received[3:0];
  wire  [9:0] cfg_ext_register_number[3:0];
  wire  [7:0] cfg_ext_function_number[3:0];
  wire [31:0] cfg_ext_write_data[3:0];
  wire  [3:0] cfg_ext_write_byte_enable[3:0];
  wire [31:0] cfg_ext_read_data[3:0];
  wire        cfg_ext_read_data_valid[3:0];


  //-----------------------------------------//
  // EP Only                                 //
  //-----------------------------------------//

  // Interrupt Interface Signals
  wire  [3:0] cfg_interrupt_int[3:0];
  wire  [1:0] cfg_interrupt_pending[3:0];
  wire        cfg_interrupt_sent[3:0];

  wire  [3:0] cfg_interrupt_msi_enable[3:0];
  wire  [7:0] cfg_interrupt_msi_vf_enable[3:0];
  wire [11:0] cfg_interrupt_msi_mmenable[3:0];
  wire        cfg_interrupt_msi_mask_update[3:0];
  wire [31:0] cfg_interrupt_msi_data[3:0];
  wire  [3:0] cfg_interrupt_msi_select[3:0];
  wire [31:0] cfg_interrupt_msi_int[3:0];
  wire [63:0] cfg_interrupt_msi_pending_status[3:0];
  wire        cfg_interrupt_msi_sent[3:0];
  wire        cfg_interrupt_msi_fail[3:0];
  wire  [2:0] cfg_interrupt_msi_attr[3:0];
  wire        cfg_interrupt_msi_tph_present[3:0];
  wire  [1:0] cfg_interrupt_msi_tph_type[3:0];
  wire  [7:0] cfg_interrupt_msi_tph_st_tag[3:0];
  wire  [2:0] cfg_interrupt_msi_function_number[3:0];
  wire        cfg_interrupt_msi_pending_status_data_enable[3:0];
  wire  [3:0] cfg_interrupt_msi_pending_status_function_num[3:0];


// EP only
  wire cfg_hot_reset_out[3:0];
  wire cfg_config_space_enable[3:0];
  wire cfg_req_pm_transition_l23_ready[3:0];

// RP only
  wire cfg_hot_reset_in[3:0];

  wire [7:0]    cfg_ds_bus_number[3:0];
  wire [4:0]    cfg_ds_device_number[3:0];

  wire [15:0]  cfg_vend_id[3:0];

  wire [15:0]  cfg_dev_id[3:0];
  wire [15:0]  cfg_subsys_id[3:0];
  wire [7:0]   cfg_rev_id[3:0];
  wire [15:0]  cfg_subsys_vend_id[3:0];
  
// NOTE: Assign all controllers to same IDs.
//       Edit this section if they're required to be different.
genvar ids;
generate
for (ids = 0; ids < 4; ids++) begin: ctrl_pcie_ids
  assign cfg_vend_id[ids]        = 16'h10EE; //16'h10EE;

  assign cfg_dev_id[ids]         = 16'hB03F; //16'h903F;
  assign cfg_subsys_id[ids]      = 16'h0007; //16'h0007;
  assign cfg_rev_id[ids]         = 8'h00;    //8'h00;
  assign cfg_subsys_vend_id[ids] = 16'h10EE; //16'h10EE;
end
endgenerate

// NOTE: Generate Tie-Off on Unused Signals
//       Edit this section if they're required to be different.
generate
for (ids = 0; ids < 4; ids++) begin: ctrl_tie_offs
  assign cfg_interrupt_msi_int[ids] = 32'b0;
  assign cfg_interrupt_msi_attr[ids] = 3'b0;
  assign cfg_interrupt_msi_select[ids] = 4'b0;
  assign cfg_interrupt_msi_tph_type[ids] = 2'b0;
  assign cfg_interrupt_msi_tph_present[ids] = 1'b0;
  assign cfg_interrupt_msi_tph_st_tag[ids] = 8'h00;
  assign cfg_interrupt_msi_pending_status[ids] = 64'b0;
  assign cfg_interrupt_msi_function_number[ids] = 3'b0;

  assign cfg_ext_read_data[ids] = 'h0;
  assign cfg_ext_read_data_valid[ids] = 'h0;

  assign user_lnk_up[ids] = (cfg_phy_link_status[ids] == 'h3) ? 1'b1 : 1'b0;
end
endgenerate

  //--------------------------------------------------------------------------------------------------------------------//
  // Instantiate Root Port wrapper
  //--------------------------------------------------------------------------------------------------------------------//
generate
if (PCIE_CTRL_MODE == 0) begin : Single_CTRL // CTRL 0 x16
  // Core Top Level Wrapper
  design_rp design_rp_i (

    //-----------------------------------//
    //  System(SYS) Interface            //
    //-----------------------------------//
    .gt_refclk0_0_clk_n(sys_clk_n),
    .gt_refclk0_0_clk_p(sys_clk_p),

    .cpm_user_clk(user_clk),
    .cpm_user_rstn(user_reset_n),

    //---------------------------------------//
    //  PCI Express (pci_exp) Interface      //
    //---------------------------------------//
    .PCIE0_GT_0_gtx_n(pci_exp_txn),
    .PCIE0_GT_0_gtx_p(pci_exp_txp),
    .PCIE0_GT_0_grx_n(pci_exp_rxn),
    .PCIE0_GT_0_grx_p(pci_exp_rxp),

    //------------------------------------------//
    //  AXI Interface                           //
    //------------------------------------------//
    .pcie0_s_axis_rq_0_tlast (s_axis_rq_tlast[0]),
    .pcie0_s_axis_rq_0_tdata (s_axis_rq_tdata[0]),
    .pcie0_s_axis_rq_0_tuser (s_axis_rq_tuser[0]),
    .pcie0_s_axis_rq_0_tkeep (s_axis_rq_tkeep[0]),
    .pcie0_s_axis_rq_0_tready(s_axis_rq_tready[0]),
    .pcie0_s_axis_rq_0_tvalid(s_axis_rq_tvalid[0]),

    .pcie0_m_axis_rc_0_tdata (m_axis_rc_tdata[0]),
    .pcie0_m_axis_rc_0_tuser (m_axis_rc_tuser[0]),
    .pcie0_m_axis_rc_0_tlast (m_axis_rc_tlast[0]),
    .pcie0_m_axis_rc_0_tkeep (m_axis_rc_tkeep[0]),
    .pcie0_m_axis_rc_0_tvalid(m_axis_rc_tvalid[0]),
    .pcie0_m_axis_rc_0_tready(m_axis_rc_tready[0]),


    .pcie0_m_axis_cq_0_tdata (m_axis_cq_tdata[0]),
    .pcie0_m_axis_cq_0_tuser (m_axis_cq_tuser[0]),
    .pcie0_m_axis_cq_0_tlast (m_axis_cq_tlast[0]),
    .pcie0_m_axis_cq_0_tkeep (m_axis_cq_tkeep[0]),
    .pcie0_m_axis_cq_0_tvalid(m_axis_cq_tvalid[0]),
    .pcie0_m_axis_cq_0_tready(m_axis_cq_tready[0]),

    .pcie0_s_axis_cc_0_tdata (s_axis_cc_tdata[0]),
    .pcie0_s_axis_cc_0_tuser (s_axis_cc_tuser[0]),
    .pcie0_s_axis_cc_0_tlast (s_axis_cc_tlast[0]),
    .pcie0_s_axis_cc_0_tkeep (s_axis_cc_tkeep[0]),
    .pcie0_s_axis_cc_0_tvalid(s_axis_cc_tvalid[0]),
    .pcie0_s_axis_cc_0_tready(s_axis_cc_tready[0]),

    //----------------------------------------//
    //  Configuration (CFG) Interface         //
    //----------------------------------------//

    .pcie0_cfg_status_0_cq_np_req       ({1'b0,pcie_cq_np_req[0]}),
    .pcie0_cfg_status_0_cq_np_req_count (pcie_cq_np_req_count[0]),
    .pcie0_cfg_status_0_phy_link_down   (cfg_phy_link_down[0]),
    .pcie0_cfg_status_0_phy_link_status (cfg_phy_link_status[0]),
    .pcie0_cfg_status_0_negotiated_width(cfg_negotiated_width[0]),
    .pcie0_cfg_status_0_current_speed   (cfg_current_speed[0]),
    .pcie0_cfg_status_0_max_payload     (cfg_max_payload[0]),
    .pcie0_cfg_status_0_max_read_req    (cfg_max_read_req[0]),
    .pcie0_cfg_status_0_function_status (cfg_function_status[0]),
    .pcie0_cfg_status_0_function_power_state(cfg_function_power_state[0]),
    .pcie0_cfg_status_0_link_power_state(cfg_link_power_state[0]),

    // Error Reporting Interface
    .pcie0_cfg_status_0_err_cor_out     (cfg_err_cor_out[0]),
    .pcie0_cfg_status_0_err_nonfatal_out(cfg_err_nonfatal_out[0]),
    .pcie0_cfg_status_0_err_fatal_out   (cfg_err_fatal_out[0]),
    .pcie0_cfg_status_0_local_error_out (),

    .pcie0_cfg_status_0_ltssm_state(cfg_ltssm_state[0]),
    .pcie0_cfg_status_0_rcb_status (cfg_rcb_status[0]),
    .pcie0_cfg_status_0_pl_status_change(cfg_pl_status_change[0]),

    // Management Interface
    .pcie0_cfg_mgmt_0_addr      (cfg_mgmt_addr[0]),
    .pcie0_cfg_mgmt_0_write_en  (cfg_mgmt_write[0]),
    .pcie0_cfg_mgmt_0_write_data(cfg_mgmt_write_data[0]),
    .pcie0_cfg_mgmt_0_byte_en   (cfg_mgmt_byte_enable[0]),
    .pcie0_cfg_mgmt_0_read_en   (cfg_mgmt_read[0]),
    .pcie0_cfg_mgmt_0_read_data (cfg_mgmt_read_data[0]),
    .pcie0_cfg_mgmt_0_read_write_done(cfg_mgmt_read_write_done[0]),
    .pcie0_cfg_mgmt_0_debug_access(1'b0),
    .pcie0_cfg_mgmt_0_function_number(8'b0),

    .pcie0_transmit_fc_0_nph_av(pcie_tfc_nph_av[0]),
    .pcie0_transmit_fc_0_npd_av(pcie_tfc_npd_av[0]),

    .pcie0_cfg_msg_recd_0_recd     (cfg_msg_received[0]),
    .pcie0_cfg_msg_recd_0_recd_data(cfg_msg_received_data[0]),
    .pcie0_cfg_msg_recd_0_recd_type(cfg_msg_received_type[0]),

    .pcie0_cfg_msg_tx_0_transmit     (cfg_msg_transmit[0]),
    .pcie0_cfg_msg_tx_0_transmit_type(cfg_msg_transmit_type[0]),
    .pcie0_cfg_msg_tx_0_transmit_data(cfg_msg_transmit_data[0]),
    .pcie0_cfg_msg_tx_0_transmit_done(cfg_msg_transmit_done[0]),

    .pcie0_cfg_fc_0_ph  (cfg_fc_ph[0]),
    .pcie0_cfg_fc_0_pd  (cfg_fc_pd[0]),
    .pcie0_cfg_fc_0_nph (cfg_fc_nph[0]),
    .pcie0_cfg_fc_0_npd (cfg_fc_npd[0]),
    .pcie0_cfg_fc_0_cplh(cfg_fc_cplh[0]),
    .pcie0_cfg_fc_0_cpld(cfg_fc_cpld[0]),
    .pcie0_cfg_fc_0_sel (cfg_fc_sel[0]),

    //-------------------------------------------------------------------------------//
    // EP and RP                                                                     //
    //-------------------------------------------------------------------------------//

    .pcie0_cfg_control_0_power_state_change_ack(cfg_power_state_change_ack[0]),
    .pcie0_cfg_control_0_power_state_change_interrupt(cfg_power_state_change_interrupt[0]),
    .pcie0_cfg_control_0_err_cor_in  (cfg_err_cor_in[0]),
    .pcie0_cfg_control_0_err_uncor_in(cfg_err_uncor_in[0]),

//  .pcie0_cfg_control_0_flr_in_process(cfg_flr_in_process[0]),
    .pcie0_cfg_control_0_flr_done({2'b0,cfg_flr_done[0]}),

    .pcie0_cfg_control_0_hot_reset_out(cfg_hot_reset_out[0]), // EP only
    .pcie0_cfg_control_0_hot_reset_in(cfg_hot_reset_in[0]), // RP only

    .pcie0_cfg_ext_0_read_received  (cfg_ext_read_received[0]),
    .pcie0_cfg_ext_0_write_received (cfg_ext_write_received[0]),
    .pcie0_cfg_ext_0_register_number(cfg_ext_register_number[0]),
    .pcie0_cfg_ext_0_function_number(cfg_ext_function_number[0]),
    .pcie0_cfg_ext_0_write_data     (cfg_ext_write_data[0]),
    .pcie0_cfg_ext_0_write_byte_enable(cfg_ext_write_byte_enable[0]),
    .pcie0_cfg_ext_0_read_data      (cfg_ext_read_data[0]),
    .pcie0_cfg_ext_0_read_data_valid(cfg_ext_read_data_valid[0])
   );
end
else if (PCIE_CTRL_MODE == 1) begin : Dual_Ctrl // CTRL 0+2 x8x8
  // Core Top Level Wrapper
  design_rp design_rp_i (

    //-----------------------------------//
    //  System(SYS) Interface            //
    //-----------------------------------//
    .gt_refclk0_0_clk_n(sys_clk_n),
    .gt_refclk0_0_clk_p(sys_clk_p),
    
    .gt_refclk2_0_clk_n(sys_clk_n),
    .gt_refclk2_0_clk_p(sys_clk_p),

    .cpm_user_clk(user_clk),
    .cpm_user_rstn(user_reset_n),

    //---------------------------------------//
    //  PCI Express (pci_exp) Interface      //
    //---------------------------------------//
    .PCIE0_GT_0_gtx_n(pci_exp_txn[7:0]),
    .PCIE0_GT_0_gtx_p(pci_exp_txp[7:0]),
    .PCIE0_GT_0_grx_n(pci_exp_rxn[7:0]),
    .PCIE0_GT_0_grx_p(pci_exp_rxp[7:0]),
    
    .PCIE2_GT_0_gtx_n(pci_exp_txn[15:8]),
    .PCIE2_GT_0_gtx_p(pci_exp_txp[15:8]),
    .PCIE2_GT_0_grx_n(pci_exp_rxn[15:8]),
    .PCIE2_GT_0_grx_p(pci_exp_rxp[15:8]),

    //------------------------------------------//
    //  AXI Interface                           //
    //------------------------------------------//
    .pcie0_s_axis_rq_0_tlast (s_axis_rq_tlast[0]),
    .pcie0_s_axis_rq_0_tdata (s_axis_rq_tdata[0]),
    .pcie0_s_axis_rq_0_tuser (s_axis_rq_tuser[0]),
    .pcie0_s_axis_rq_0_tkeep (s_axis_rq_tkeep[0]),
    .pcie0_s_axis_rq_0_tready(s_axis_rq_tready[0]),
    .pcie0_s_axis_rq_0_tvalid(s_axis_rq_tvalid[0]),

    .pcie0_m_axis_rc_0_tdata (m_axis_rc_tdata[0]),
    .pcie0_m_axis_rc_0_tuser (m_axis_rc_tuser[0]),
    .pcie0_m_axis_rc_0_tlast (m_axis_rc_tlast[0]),
    .pcie0_m_axis_rc_0_tkeep (m_axis_rc_tkeep[0]),
    .pcie0_m_axis_rc_0_tvalid(m_axis_rc_tvalid[0]),
    .pcie0_m_axis_rc_0_tready(m_axis_rc_tready[0]),

    .pcie0_m_axis_cq_0_tdata (m_axis_cq_tdata[0]),
    .pcie0_m_axis_cq_0_tuser (m_axis_cq_tuser[0]),
    .pcie0_m_axis_cq_0_tlast (m_axis_cq_tlast[0]),
    .pcie0_m_axis_cq_0_tkeep (m_axis_cq_tkeep[0]),
    .pcie0_m_axis_cq_0_tvalid(m_axis_cq_tvalid[0]),
    .pcie0_m_axis_cq_0_tready(m_axis_cq_tready[0]),

    .pcie0_s_axis_cc_0_tdata (s_axis_cc_tdata[0]),
    .pcie0_s_axis_cc_0_tuser (s_axis_cc_tuser[0]),
    .pcie0_s_axis_cc_0_tlast (s_axis_cc_tlast[0]),
    .pcie0_s_axis_cc_0_tkeep (s_axis_cc_tkeep[0]),
    .pcie0_s_axis_cc_0_tvalid(s_axis_cc_tvalid[0]),
    .pcie0_s_axis_cc_0_tready(s_axis_cc_tready[0]),
    
    .pcie2_s_axis_rq_0_tlast (s_axis_rq_tlast[2]),
    .pcie2_s_axis_rq_0_tdata (s_axis_rq_tdata[2]),
    .pcie2_s_axis_rq_0_tuser (s_axis_rq_tuser[2]),
    .pcie2_s_axis_rq_0_tkeep (s_axis_rq_tkeep[2]),
    .pcie2_s_axis_rq_0_tready(s_axis_rq_tready[2]),
    .pcie2_s_axis_rq_0_tvalid(s_axis_rq_tvalid[2]),

    .pcie2_m_axis_rc_0_tdata (m_axis_rc_tdata[2]),
    .pcie2_m_axis_rc_0_tuser (m_axis_rc_tuser[2]),
    .pcie2_m_axis_rc_0_tlast (m_axis_rc_tlast[2]),
    .pcie2_m_axis_rc_0_tkeep (m_axis_rc_tkeep[2]),
    .pcie2_m_axis_rc_0_tvalid(m_axis_rc_tvalid[2]),
    .pcie2_m_axis_rc_0_tready(m_axis_rc_tready[2]),

    .pcie2_m_axis_cq_0_tdata (m_axis_cq_tdata[2]),
    .pcie2_m_axis_cq_0_tuser (m_axis_cq_tuser[2]),
    .pcie2_m_axis_cq_0_tlast (m_axis_cq_tlast[2]),
    .pcie2_m_axis_cq_0_tkeep (m_axis_cq_tkeep[2]),
    .pcie2_m_axis_cq_0_tvalid(m_axis_cq_tvalid[2]),
    .pcie2_m_axis_cq_0_tready(m_axis_cq_tready[2]),

    .pcie2_s_axis_cc_0_tdata (s_axis_cc_tdata[2]),
    .pcie2_s_axis_cc_0_tuser (s_axis_cc_tuser[2]),
    .pcie2_s_axis_cc_0_tlast (s_axis_cc_tlast[2]),
    .pcie2_s_axis_cc_0_tkeep (s_axis_cc_tkeep[2]),
    .pcie2_s_axis_cc_0_tvalid(s_axis_cc_tvalid[2]),
    .pcie2_s_axis_cc_0_tready(s_axis_cc_tready[2]),

    //----------------------------------------//
    //  Configuration (CFG) Interface         //
    //----------------------------------------//

    .pcie0_cfg_status_0_cq_np_req       ({1'b0,pcie_cq_np_req[0]}),
    .pcie0_cfg_status_0_cq_np_req_count (pcie_cq_np_req_count[0]),
    .pcie0_cfg_status_0_phy_link_down   (cfg_phy_link_down[0]),
    .pcie0_cfg_status_0_phy_link_status (cfg_phy_link_status[0]),
    .pcie0_cfg_status_0_negotiated_width(cfg_negotiated_width[0]),
    .pcie0_cfg_status_0_current_speed   (cfg_current_speed[0]),
    .pcie0_cfg_status_0_max_payload     (cfg_max_payload[0]),
    .pcie0_cfg_status_0_max_read_req    (cfg_max_read_req[0]),
    .pcie0_cfg_status_0_function_status (cfg_function_status[0]),
    .pcie0_cfg_status_0_function_power_state(cfg_function_power_state[0]),
    .pcie0_cfg_status_0_link_power_state(cfg_link_power_state[0]),
    
    .pcie2_cfg_status_0_cq_np_req       ({1'b0,pcie_cq_np_req[2]}),
    .pcie2_cfg_status_0_cq_np_req_count (pcie_cq_np_req_count[2]),
    .pcie2_cfg_status_0_phy_link_down   (cfg_phy_link_down[2]),
    .pcie2_cfg_status_0_phy_link_status (cfg_phy_link_status[2]),
    .pcie2_cfg_status_0_negotiated_width(cfg_negotiated_width[2]),
    .pcie2_cfg_status_0_current_speed   (cfg_current_speed[2]),
    .pcie2_cfg_status_0_max_payload     (cfg_max_payload[2]),
    .pcie2_cfg_status_0_max_read_req    (cfg_max_read_req[2]),
    .pcie2_cfg_status_0_function_status (cfg_function_status[2]),
    .pcie2_cfg_status_0_function_power_state(cfg_function_power_state[2]),
    .pcie2_cfg_status_0_link_power_state(cfg_link_power_state[2]),

    // Error Reporting Interface
    .pcie0_cfg_status_0_err_cor_out     (cfg_err_cor_out[0]),
    .pcie0_cfg_status_0_err_nonfatal_out(cfg_err_nonfatal_out[0]),
    .pcie0_cfg_status_0_err_fatal_out   (cfg_err_fatal_out[0]),
    .pcie0_cfg_status_0_local_error_out (),

    .pcie0_cfg_status_0_ltssm_state(cfg_ltssm_state[0]),
    .pcie0_cfg_status_0_rcb_status (cfg_rcb_status[0]),
    .pcie0_cfg_status_0_pl_status_change(cfg_pl_status_change[0]),
    
    .pcie2_cfg_status_0_err_cor_out     (cfg_err_cor_out[2]),
    .pcie2_cfg_status_0_err_nonfatal_out(cfg_err_nonfatal_out[2]),
    .pcie2_cfg_status_0_err_fatal_out   (cfg_err_fatal_out[2]),
    .pcie2_cfg_status_0_local_error_out (),

    .pcie2_cfg_status_0_ltssm_state(cfg_ltssm_state[2]),
    .pcie2_cfg_status_0_rcb_status (cfg_rcb_status[2]),
    .pcie2_cfg_status_0_pl_status_change(cfg_pl_status_change[2]),

    // Management Interface
    .pcie0_cfg_mgmt_0_addr      (cfg_mgmt_addr[0]),
    .pcie0_cfg_mgmt_0_write_en  (cfg_mgmt_write[0]),
    .pcie0_cfg_mgmt_0_write_data(cfg_mgmt_write_data[0]),
    .pcie0_cfg_mgmt_0_byte_en   (cfg_mgmt_byte_enable[0]),
    .pcie0_cfg_mgmt_0_read_en   (cfg_mgmt_read[0]),
    .pcie0_cfg_mgmt_0_read_data (cfg_mgmt_read_data[0]),
    .pcie0_cfg_mgmt_0_read_write_done(cfg_mgmt_read_write_done[0]),
    .pcie0_cfg_mgmt_0_debug_access(1'b0),
    .pcie0_cfg_mgmt_0_function_number(8'b0),

    .pcie0_transmit_fc_0_nph_av(pcie_tfc_nph_av[0]),
    .pcie0_transmit_fc_0_npd_av(pcie_tfc_npd_av[0]),

    .pcie0_cfg_msg_recd_0_recd     (cfg_msg_received[0]),
    .pcie0_cfg_msg_recd_0_recd_data(cfg_msg_received_data[0]),
    .pcie0_cfg_msg_recd_0_recd_type(cfg_msg_received_type[0]),

    .pcie0_cfg_msg_tx_0_transmit     (cfg_msg_transmit[0]),
    .pcie0_cfg_msg_tx_0_transmit_type(cfg_msg_transmit_type[0]),
    .pcie0_cfg_msg_tx_0_transmit_data(cfg_msg_transmit_data[0]),
    .pcie0_cfg_msg_tx_0_transmit_done(cfg_msg_transmit_done[0]),

    .pcie0_cfg_fc_0_ph  (cfg_fc_ph[0]),
    .pcie0_cfg_fc_0_pd  (cfg_fc_pd[0]),
    .pcie0_cfg_fc_0_nph (cfg_fc_nph[0]),
    .pcie0_cfg_fc_0_npd (cfg_fc_npd[0]),
    .pcie0_cfg_fc_0_cplh(cfg_fc_cplh[0]),
    .pcie0_cfg_fc_0_cpld(cfg_fc_cpld[0]),
    .pcie0_cfg_fc_0_sel (cfg_fc_sel[0]),
    
    .pcie2_cfg_mgmt_0_addr      (cfg_mgmt_addr[2]),
    .pcie2_cfg_mgmt_0_write_en  (cfg_mgmt_write[2]),
    .pcie2_cfg_mgmt_0_write_data(cfg_mgmt_write_data[2]),
    .pcie2_cfg_mgmt_0_byte_en   (cfg_mgmt_byte_enable[2]),
    .pcie2_cfg_mgmt_0_read_en   (cfg_mgmt_read[2]),
    .pcie2_cfg_mgmt_0_read_data (cfg_mgmt_read_data[2]),
    .pcie2_cfg_mgmt_0_read_write_done(cfg_mgmt_read_write_done[2]),
    .pcie2_cfg_mgmt_0_debug_access(1'b0),
    .pcie2_cfg_mgmt_0_function_number(8'b0),

    .pcie2_transmit_fc_0_nph_av(pcie_tfc_nph_av[2]),
    .pcie2_transmit_fc_0_npd_av(pcie_tfc_npd_av[2]),

    .pcie2_cfg_msg_recd_0_recd     (cfg_msg_received[2]),
    .pcie2_cfg_msg_recd_0_recd_data(cfg_msg_received_data[2]),
    .pcie2_cfg_msg_recd_0_recd_type(cfg_msg_received_type[2]),

    .pcie2_cfg_msg_tx_0_transmit     (cfg_msg_transmit[2]),
    .pcie2_cfg_msg_tx_0_transmit_type(cfg_msg_transmit_type[2]),
    .pcie2_cfg_msg_tx_0_transmit_data(cfg_msg_transmit_data[2]),
    .pcie2_cfg_msg_tx_0_transmit_done(cfg_msg_transmit_done[2]),

    .pcie2_cfg_fc_0_ph  (cfg_fc_ph[2]),
    .pcie2_cfg_fc_0_pd  (cfg_fc_pd[2]),
    .pcie2_cfg_fc_0_nph (cfg_fc_nph[2]),
    .pcie2_cfg_fc_0_npd (cfg_fc_npd[2]),
    .pcie2_cfg_fc_0_cplh(cfg_fc_cplh[2]),
    .pcie2_cfg_fc_0_cpld(cfg_fc_cpld[2]),
    .pcie2_cfg_fc_0_sel (cfg_fc_sel[2]),

    //-------------------------------------------------------------------------------//
    // EP and RP                                                                     //
    //-------------------------------------------------------------------------------//


    .pcie0_cfg_control_0_power_state_change_ack(cfg_power_state_change_ack[0]),
    .pcie0_cfg_control_0_power_state_change_interrupt(cfg_power_state_change_interrupt[0]),
    .pcie0_cfg_control_0_err_cor_in  (cfg_err_cor_in[0]),
    .pcie0_cfg_control_0_err_uncor_in(cfg_err_uncor_in[0]),

//  .pcie0_cfg_control_0_flr_in_process(cfg_flr_in_process[0]),
    .pcie0_cfg_control_0_flr_done({2'b0,cfg_flr_done[0]}),

    .pcie0_cfg_control_0_hot_reset_out(cfg_hot_reset_out[0]), // EP only
    .pcie0_cfg_control_0_hot_reset_in(cfg_hot_reset_in[0]), // RP only

    .pcie0_cfg_ext_0_read_received  (cfg_ext_read_received[0]),
    .pcie0_cfg_ext_0_write_received (cfg_ext_write_received[0]),
    .pcie0_cfg_ext_0_register_number(cfg_ext_register_number[0]),
    .pcie0_cfg_ext_0_function_number(cfg_ext_function_number[0]),
    .pcie0_cfg_ext_0_write_data     (cfg_ext_write_data[0]),
    .pcie0_cfg_ext_0_write_byte_enable(cfg_ext_write_byte_enable[0]),
    .pcie0_cfg_ext_0_read_data      (cfg_ext_read_data[0]),
    .pcie0_cfg_ext_0_read_data_valid(cfg_ext_read_data_valid[0]),
    
    .pcie2_cfg_status_0_bus_number(),
    .pcie2_cfg_control_0_power_state_change_ack(cfg_power_state_change_ack[2]),
    .pcie2_cfg_control_0_power_state_change_interrupt(cfg_power_state_change_interrupt[2]),
    .pcie2_cfg_control_0_err_cor_in  (cfg_err_cor_in[2]),
    .pcie2_cfg_control_0_err_uncor_in(cfg_err_uncor_in[2]),

//  .pcie2_cfg_control_0_flr_in_process(cfg_flr_in_process[2]),
    .pcie2_cfg_control_0_flr_done({2'b0,cfg_flr_done[2]}),

    .pcie2_cfg_control_0_hot_reset_out(cfg_hot_reset_out[2]), // EP only
    .pcie2_cfg_control_0_hot_reset_in(cfg_hot_reset_in[2]), // RP only

    .pcie2_cfg_ext_0_read_received  (cfg_ext_read_received[2]),
    .pcie2_cfg_ext_0_write_received (cfg_ext_write_received[2]),
    .pcie2_cfg_ext_0_register_number(cfg_ext_register_number[2]),
    .pcie2_cfg_ext_0_function_number(cfg_ext_function_number[2]),
    .pcie2_cfg_ext_0_write_data     (cfg_ext_write_data[2]),
    .pcie2_cfg_ext_0_write_byte_enable(cfg_ext_write_byte_enable[2]),
    .pcie2_cfg_ext_0_read_data      (cfg_ext_read_data[2]),
    .pcie2_cfg_ext_0_read_data_valid(cfg_ext_read_data_valid[2])
   );
  
end

// NOTE: Generate RP Testbench for each CTRL
for (ids = 0; ids < 4; ids++) begin: RP_testbench
  // CTRL 0 x16 ||
  // CTRL 0+2 x8x8 ||
  // NOTE: Add more configuration as needed here
  if ( ((PCIE_CTRL_MODE == 0) && (ids == 0)) ||
       ((PCIE_CTRL_MODE == 1) && ((ids == 0) || (ids == 2))) ||
       ((PCIE_CTRL_MODE != 0) || (PCIE_CTRL_MODE != 1)) ) begin

   //  Testbench App
   pci_exp_usrapp_top #(
    .C_DATA_WIDTH                   ( C_DATA_WIDTH ),
    .KEEP_WIDTH                     ( KEEP_WIDTH ),
  
    .LINK_CAP_MAX_LINK_WIDTH        ( PL_LINK_CAP_MAX_LINK_WIDTH   ),
    .LINK_CAP_MAX_LINK_SPEED        ( PL_LINK_CAP_MAX_LINK_SPEED   ),
    .PF0_DEV_CAP_MAX_PAYLOAD_SIZE   ( PF0_DEV_CAP_MAX_PAYLOAD_SIZE ),

    .AXISTEN_IF_RQ_ALIGNMENT_MODE   ( AXISTEN_IF_RQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_CC_ALIGNMENT_MODE   ( AXISTEN_IF_CC_ALIGNMENT_MODE ),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE   ( AXISTEN_IF_CQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_ALIGNMENT_MODE   ( AXISTEN_IF_RC_ALIGNMENT_MODE ),
    .AXI4_CQ_TUSER_WIDTH            ( AXI4_CQ_TUSER_WIDTH ),
    .AXI4_CC_TUSER_WIDTH            ( AXI4_CC_TUSER_WIDTH ),
    .AXI4_RQ_TUSER_WIDTH            ( AXI4_RQ_TUSER_WIDTH ),
    .AXI4_RC_TUSER_WIDTH            ( AXI4_RC_TUSER_WIDTH ),
    .AXISTEN_IF_RQ_PARITY_CHECK     ( AXISTEN_IF_RQ_PARITY_CHECK ),
    .AXISTEN_IF_CC_PARITY_CHECK     ( AXISTEN_IF_CC_PARITY_CHECK ),
    .AXISTEN_IF_RC_PARITY_CHECK     ( AXISTEN_IF_RC_PARITY_CHECK ),
    .AXISTEN_IF_CQ_PARITY_CHECK     ( AXISTEN_IF_CQ_PARITY_CHECK ),
  
    .EP_DEV_ID                      ( EP_DEV_ID ),
  
    .TCQ                            ( TCQ )
   ) pci_exp_usrapp_top_i (
     .user_clk             ( user_clk ),
     .user_reset           ( user_reset ),
     .user_lnk_up          ( user_lnk_up[ids] ),
  
     //----------------------------------------------------//
     // 3. AXI Interface                                   //
     //----------------------------------------------------//
     .s_axis_rq_tlast      ( s_axis_rq_tlast[ids] ),
     .s_axis_rq_tdata      ( s_axis_rq_tdata[ids] ),
     .s_axis_rq_tuser      ( s_axis_rq_tuser[ids] ),
     .s_axis_rq_tkeep      ( s_axis_rq_tkeep[ids] ),
     .s_axis_rq_tready     ( s_axis_rq_tready[ids] ),
     .s_axis_rq_tvalid     ( s_axis_rq_tvalid[ids] ),

     .m_axis_rc_tdata      ( m_axis_rc_tdata[ids] ),
     .m_axis_rc_tuser      ( m_axis_rc_tuser[ids] ),
     .m_axis_rc_tlast      ( m_axis_rc_tlast[ids] ),
     .m_axis_rc_tkeep      ( m_axis_rc_tkeep[ids] ),
     .m_axis_rc_tvalid     ( m_axis_rc_tvalid[ids] ),
     .m_axis_rc_tready     ( m_axis_rc_tready[ids] ),

     .m_axis_cq_tdata      ( m_axis_cq_tdata[ids] ),
     .m_axis_cq_tuser      ( m_axis_cq_tuser[ids] ),
     .m_axis_cq_tlast      ( m_axis_cq_tlast[ids] ),
     .m_axis_cq_tkeep      ( m_axis_cq_tkeep[ids] ),
     .m_axis_cq_tvalid     ( m_axis_cq_tvalid[ids] ),
     .m_axis_cq_tready     ( m_axis_cq_tready[ids] ),

     .s_axis_cc_tdata      ( s_axis_cc_tdata[ids] ),
     .s_axis_cc_tuser      ( s_axis_cc_tuser[ids] ),
     .s_axis_cc_tlast      ( s_axis_cc_tlast[ids] ),
     .s_axis_cc_tkeep      ( s_axis_cc_tkeep[ids] ),
     .s_axis_cc_tvalid     ( s_axis_cc_tvalid[ids] ),
     .s_axis_cc_tready     ( s_axis_cc_tready[ids] ),
  
     .pcie_tfc_nph_av      ( pcie_tfc_nph_av[ids] ),
     .pcie_tfc_npd_av      ( pcie_tfc_npd_av[ids] ),
     .pcie_rq_seq_num      ( pcie_rq_seq_num[ids] ),
     .pcie_rq_seq_num_vld  ( pcie_rq_seq_num_vld[ids] ),
     .pcie_rq_tag          ( pcie_rq_tag[ids] ),
     .pcie_rq_tag_vld      ( pcie_rq_tag_vld[ids] ),
     .pcie_rq_tag_av       ( pcie_rq_tag_av[ids] ),

     .pcie_cq_np_req       ( pcie_cq_np_req[ids] ),
     .pcie_cq_np_req_count ( pcie_cq_np_req_count[ids] ),
  
     //---------------------------------------------------//
     // 4. Configuration (CFG) Interface                  //
     //---------------------------------------------------//

     //---------------------------------------------------//
     // EP and RP                                         //
     //---------------------------------------------------//
     .cfg_phy_link_down        ( cfg_phy_link_down[ids] ),
     .cfg_phy_link_status      ( cfg_phy_link_status[ids] ),
     .cfg_negotiated_width     ( cfg_negotiated_width[ids] ),
     .cfg_current_speed        ( cfg_current_speed[ids] ),
     .cfg_max_payload          ( cfg_max_payload[ids] ),
     .cfg_max_read_req         ( cfg_max_read_req[ids] ),
     .cfg_function_status      ( cfg_function_status[ids] ),
     .cfg_function_power_state ( cfg_function_power_state[ids] ),
     .cfg_vf_status            ( cfg_vf_status[ids] ),
     .cfg_vf_power_state       ( cfg_vf_power_state[ids] ),
     .cfg_link_power_state     ( cfg_link_power_state[ids] ),

     // Management Interface
     .cfg_mgmt_addr            ( cfg_mgmt_addr[ids] ),
     .cfg_mgmt_write           ( cfg_mgmt_write[ids] ),
     .cfg_mgmt_write_data      ( cfg_mgmt_write_data[ids] ),
     .cfg_mgmt_byte_enable     ( cfg_mgmt_byte_enable[ids] ),
     .cfg_mgmt_read            ( cfg_mgmt_read[ids] ),
     .cfg_mgmt_read_data       ( cfg_mgmt_read_data[ids] ),
     .cfg_mgmt_read_write_done ( cfg_mgmt_read_write_done[ids] ),
     .cfg_mgmt_type1_cfg_reg_access ( cfg_mgmt_type1_cfg_reg_access[ids] ),

     // Error Reporting Interface
     .cfg_err_cor_out          ( cfg_err_cor_out[ids] ),
     .cfg_err_nonfatal_out     ( cfg_err_nonfatal_out[ids] ),
     .cfg_err_fatal_out        ( cfg_err_fatal_out[ids] ),
     .cfg_local_error          ( cfg_local_error[ids] ),

     .cfg_ltssm_state          ( cfg_ltssm_state[ids] ),
     .cfg_rcb_status           ( cfg_rcb_status[ids] ),
     .cfg_dpa_substate_change  ( cfg_dpa_substate_change[ids] ),
     .cfg_obff_enable          ( cfg_obff_enable[ids] ),
     .cfg_pl_status_change     ( cfg_pl_status_change[ids] ),

     .cfg_tph_requester_enable ( cfg_tph_requester_enable[ids] ),
     .cfg_tph_st_mode          ( cfg_tph_st_mode[ids] ),
     .cfg_vf_tph_requester_enable ( cfg_vf_tph_requester_enable[ids] ),
     .cfg_vf_tph_st_mode       ( cfg_vf_tph_st_mode[ids] ),

     .cfg_msg_received         ( cfg_msg_received[ids] ),
     .cfg_msg_received_data    ( cfg_msg_received_data[ids] ),
     .cfg_msg_received_type    ( cfg_msg_received_type[ids] ),

     .cfg_msg_transmit         ( cfg_msg_transmit[ids] ),
     .cfg_msg_transmit_type    ( cfg_msg_transmit_type[ids] ),
     .cfg_msg_transmit_data    ( cfg_msg_transmit_data[ids] ),
     .cfg_msg_transmit_done    ( cfg_msg_transmit_done[ids] ),

     .cfg_fc_ph                ( cfg_fc_ph[ids] ),
     .cfg_fc_pd                ( cfg_fc_pd[ids] ),
     .cfg_fc_nph               ( cfg_fc_nph[ids] ),
     .cfg_fc_npd               ( cfg_fc_npd[ids] ),
     .cfg_fc_cplh              ( cfg_fc_cplh[ids] ),
     .cfg_fc_cpld              ( cfg_fc_cpld[ids] ),
     .cfg_fc_sel               ( cfg_fc_sel[ids] ),

     .cfg_per_func_status_control      ( cfg_per_func_status_control[ids] ),
     .cfg_per_func_status_data         ( cfg_per_func_status_data[ids] ),
     .cfg_per_function_number          ( cfg_per_function_number[ids] ),
     .cfg_per_function_output_request  ( cfg_per_function_output_request[ids] ),
     .cfg_per_function_update_done     ( cfg_per_function_update_done[ids] ),

     .cfg_dsn                          ( cfg_dsn[ids] ),
     .cfg_power_state_change_ack       ( cfg_power_state_change_ack[ids] ),
     .cfg_power_state_change_interrupt ( cfg_power_state_change_interrupt[ids] ),
     .cfg_err_cor_in                   ( cfg_err_cor_in[ids] ),
     .cfg_err_uncor_in                 ( cfg_err_uncor_in[ids] ),

     .cfg_flr_in_process               ( cfg_flr_in_process[ids] ),
     .cfg_flr_done                     ( cfg_flr_done[ids] ),
     .cfg_vf_flr_in_process            ( cfg_vf_flr_in_process[ids] ),
     .cfg_vf_flr_done                  ( cfg_vf_flr_done[ids] ),

     .cfg_link_training_enable         ( cfg_link_training_enable[ids] ),
     .cfg_ds_port_number               ( cfg_ds_port_number[ids] ),

     .cfg_ext_read_received            ( cfg_ext_read_received[ids] ),
     .cfg_ext_write_received           ( cfg_ext_write_received[ids] ),
     .cfg_ext_register_number          ( cfg_ext_register_number[ids] ),
     .cfg_ext_function_number          ( cfg_ext_function_number[ids] ),
     .cfg_ext_write_data               ( cfg_ext_write_data[ids] ),
     .cfg_ext_write_byte_enable        ( cfg_ext_write_byte_enable[ids] ),
     .cfg_ext_read_data                ( cfg_ext_read_data[ids] ),
     .cfg_ext_read_data_valid          ( cfg_ext_read_data_valid[ids] ),

     //-----------------------------------------//
     // EP Only                                 //
     //-----------------------------------------//

     // Interrupt Interface Signals
     .cfg_interrupt_int                ( cfg_interrupt_int[ids] ),
     .cfg_interrupt_pending            ( cfg_interrupt_pending[ids] ),
     .cfg_interrupt_sent               ( cfg_interrupt_sent[ids] ),

     .cfg_interrupt_msi_enable         ( cfg_interrupt_msi_enable[ids] ),
     .cfg_interrupt_msi_vf_enable      ( cfg_interrupt_msi_vf_enable[ids] ),
     .cfg_interrupt_msi_mmenable       ( cfg_interrupt_msi_mmenable[ids] ),
     .cfg_interrupt_msi_mask_update    ( cfg_interrupt_msi_mask_update[ids] ),
     .cfg_interrupt_msi_data           ( cfg_interrupt_msi_data[ids] ),
     .cfg_interrupt_msi_select         ( cfg_interrupt_msi_select[ids] ),
     .cfg_interrupt_msi_int            ( cfg_interrupt_msi_int[ids] ),
     .cfg_interrupt_msi_pending_status ( cfg_interrupt_msi_pending_status[ids] ),
     .cfg_interrupt_msi_sent           ( cfg_interrupt_msi_sent[ids] ),
     .cfg_interrupt_msi_fail           ( cfg_interrupt_msi_fail[ids] ),
     .cfg_interrupt_msi_attr           ( cfg_interrupt_msi_attr[ids] ),
     .cfg_interrupt_msi_tph_present    ( cfg_interrupt_msi_tph_present[ids] ),
     .cfg_interrupt_msi_tph_type       ( cfg_interrupt_msi_tph_type[ids] ),
     .cfg_interrupt_msi_tph_st_tag     ( cfg_interrupt_msi_tph_st_tag[ids] ),
     .cfg_interrupt_msi_function_number ( cfg_interrupt_msi_function_number[ids] ),
     .cfg_interrupt_msi_pending_status_data_enable ( cfg_interrupt_msi_pending_status_data_enable[ids] ),
     .cfg_interrupt_msi_pending_status_function_num ( cfg_interrupt_msi_pending_status_function_num[ids] ),

     // EP only
     .cfg_hot_reset_out                ( cfg_hot_reset_out[ids] ),
     .cfg_config_space_enable          ( cfg_config_space_enable[ids] ),
     .cfg_req_pm_transition_l23_ready  ( cfg_req_pm_transition_l23_ready[ids] ),

     // RP only
     .cfg_hot_reset_in                 ( cfg_hot_reset_in[ids] ),

     .cfg_ds_bus_number                ( cfg_ds_bus_number[ids] ),
     .cfg_ds_device_number             ( cfg_ds_device_number[ids] ),

     .cfg_vend_id                      ( cfg_vend_id[ids] ),

     .cfg_dev_id                       ( cfg_dev_id[ids] ),
     .cfg_subsys_id                    ( cfg_subsys_id[ids] ),
     .cfg_rev_id                       ( cfg_rev_id[ids] ),
     .cfg_subsys_vend_id               ( cfg_subsys_vend_id[ids] )
   );
  end // if
end // for

endgenerate

endmodule
