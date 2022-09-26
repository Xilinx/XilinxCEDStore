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

`timescale 1ps / 1ps

module design_rp_wrapper # (
  parameter C_DATA_WIDTH = 1024,//512, // RX/TX interface data width

  parameter        PL_LINK_CAP_MAX_LINK_SPEED = 16,//4,   // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4. 16 - GEN5
  parameter  [4:0] PL_LINK_CAP_MAX_LINK_WIDTH = 8,//16,   // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16

  parameter  [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE   = 3'h0,
  parameter PL_DISABLE_EI_INFER_IN_L0      = "TRUE",
  parameter PL_DISABLE_UPCONFIG_CAPABLE    = "FALSE",

  parameter REF_CLK_FREQ                   = 0, // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE",
  parameter AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE",
  parameter AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter AXI4_CQ_TUSER_WIDTH = 533,
  parameter AXI4_CC_TUSER_WIDTH = 233,
  parameter AXI4_RQ_TUSER_WIDTH = 449,
  parameter AXI4_RC_TUSER_WIDTH = 473,
  parameter AXISTEN_IF_ENABLE_CLIENT_TAG   = "TRUE",
  parameter AXISTEN_IF_RQ_PARITY_CHECK = 0,
  parameter AXISTEN_IF_CC_PARITY_CHECK = 0,
  parameter AXISTEN_IF_RC_PARITY_CHECK = 0,
  parameter AXISTEN_IF_CQ_PARITY_CHECK = 0,
  parameter AXISTEN_IF_MC_RX_STRADDLE = "FALSE",
  parameter AXISTEN_IF_ENABLE_RX_MSG_INTFC = "FALSE",
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE = 18'h2FFFF,
  parameter KEEP_WIDTH = C_DATA_WIDTH / 32
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
  wire user_reset;
  wire user_lnk_up;

  //----------------------------------------------------//
  // 3. AXI Interface                                   //
  //----------------------------------------------------//
  wire                           s_axis_rq_tlast;
  wire     [C_DATA_WIDTH-1:0]    s_axis_rq_tdata;
  wire [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser;
  wire       [KEEP_WIDTH-1:0]    s_axis_rq_tkeep;
  wire                           s_axis_rq_tready;
  wire                           s_axis_rq_tvalid;

  wire     [C_DATA_WIDTH-1:0]    m_axis_rc_tdata;
  wire [AXI4_RC_TUSER_WIDTH-1:0] m_axis_rc_tuser;
  wire                           m_axis_rc_tlast;
  wire       [KEEP_WIDTH-1:0]    m_axis_rc_tkeep;
  wire                           m_axis_rc_tvalid;
  wire                           m_axis_rc_tready;

  wire     [C_DATA_WIDTH-1:0]    m_axis_cq_tdata;
  wire [AXI4_CQ_TUSER_WIDTH-1:0] m_axis_cq_tuser;
  wire                           m_axis_cq_tlast;
  wire       [KEEP_WIDTH-1:0]    m_axis_cq_tkeep;
  wire                           m_axis_cq_tvalid;
  wire                           m_axis_cq_tready;

  wire     [C_DATA_WIDTH-1:0]    s_axis_cc_tdata;
  wire [AXI4_CC_TUSER_WIDTH-1:0] s_axis_cc_tuser;
  wire                           s_axis_cc_tlast;
  wire       [KEEP_WIDTH-1:0]    s_axis_cc_tkeep;
  wire                           s_axis_cc_tvalid;
  wire                           s_axis_cc_tready;

  wire [3:0] pcie_tfc_nph_av;
  wire [3:0] pcie_tfc_npd_av;
  wire [3:0] pcie_rq_seq_num;
  wire       pcie_rq_seq_num_vld;
  wire [5:0] pcie_rq_tag;
  wire       pcie_rq_tag_vld;
  wire [1:0] pcie_rq_tag_av;

  wire       pcie_cq_np_req;
  wire [5:0] pcie_cq_np_req_count;

  //---------------------------------------------------//
  // 4. Configuration (CFG) Interface                  //
  //---------------------------------------------------//

  //---------------------------------------------------//
  // EP and RP                                         //
  //---------------------------------------------------//

  wire         cfg_phy_link_down;
  wire  [1:0]  cfg_phy_link_status;
  wire  [2:0]  cfg_negotiated_width;
  wire  [2:0]  cfg_current_speed;
  wire  [1:0]  cfg_max_payload;
  wire  [2:0]  cfg_max_read_req;
  wire [15:0]  cfg_function_status;
  wire [11:0]  cfg_function_power_state;
  wire [503:0] cfg_vf_status;
  wire [755:0] cfg_vf_power_state;
  wire  [1:0]  cfg_link_power_state;

  // Management Interface
  wire  [9:0] cfg_mgmt_addr;
  wire        cfg_mgmt_write;
  wire [31:0] cfg_mgmt_write_data;
  wire  [3:0] cfg_mgmt_byte_enable;
  wire        cfg_mgmt_read;
  wire [31:0] cfg_mgmt_read_data;
  wire        cfg_mgmt_read_write_done;
  wire        cfg_mgmt_type1_cfg_reg_access;

  // Error Reporting Interface
  wire cfg_err_cor_out;
  wire cfg_err_nonfatal_out;
  wire cfg_err_fatal_out;
  wire cfg_local_error;

  wire [5:0] cfg_ltssm_state;
  wire [3:0] cfg_rcb_status;
  wire [3:0] cfg_dpa_substate_change;
  wire [1:0] cfg_obff_enable;
  wire       cfg_pl_status_change;

  wire  [3:0]   cfg_tph_requester_enable;
  wire [11:0]   cfg_tph_st_mode;
  wire [251:0]  cfg_vf_tph_requester_enable;
  wire [755:0]  cfg_vf_tph_st_mode;

  wire         cfg_msg_received;
  wire  [7:0]  cfg_msg_received_data;
  wire  [4:0]  cfg_msg_received_type;

  wire         cfg_msg_transmit;
  wire  [2:0]  cfg_msg_transmit_type;
  wire [31:0]  cfg_msg_transmit_data;
  wire         cfg_msg_transmit_done;

  wire  [7:0]  cfg_fc_ph;
  wire [11:0]  cfg_fc_pd;
  wire  [7:0]  cfg_fc_nph;
  wire [11:0]  cfg_fc_npd;
  wire  [7:0]  cfg_fc_cplh;
  wire [11:0]  cfg_fc_cpld;
  wire  [2:0]  cfg_fc_sel;

  wire  [2:0]  cfg_per_func_status_control;
  wire [15:0]  cfg_per_func_status_data;
  wire  [2:0]  cfg_per_function_number;
  wire         cfg_per_function_output_request;
  wire         cfg_per_function_update_done;

  wire [63:0]  cfg_dsn;
  wire cfg_power_state_change_ack;
  wire cfg_power_state_change_interrupt;
  wire cfg_err_cor_in;
  wire cfg_err_uncor_in;

  wire  [3:0]    cfg_flr_in_process;
  wire  [1:0]    cfg_flr_done;
  wire  [251:0]  cfg_vf_flr_in_process;
  wire           cfg_vf_flr_done;

  wire        cfg_link_training_enable;
  wire  [7:0] cfg_ds_port_number;

  wire        cfg_ext_read_received;
  wire        cfg_ext_write_received;
  wire  [9:0] cfg_ext_register_number;
  wire  [7:0] cfg_ext_function_number;
  wire [31:0] cfg_ext_write_data;
  wire  [3:0] cfg_ext_write_byte_enable;
  wire [31:0] cfg_ext_read_data;
  wire        cfg_ext_read_data_valid;


  //-----------------------------------------//
  // EP Only                                 //
  //-----------------------------------------//

  // Interrupt Interface Signals
  wire  [3:0] cfg_interrupt_int;
  wire  [1:0] cfg_interrupt_pending;
  wire        cfg_interrupt_sent;

  wire  [3:0] cfg_interrupt_msi_enable;
  wire  [7:0] cfg_interrupt_msi_vf_enable;
  wire [11:0] cfg_interrupt_msi_mmenable;
  wire        cfg_interrupt_msi_mask_update;
  wire [31:0] cfg_interrupt_msi_data;
  wire  [3:0] cfg_interrupt_msi_select;
  wire [31:0] cfg_interrupt_msi_int;
  wire [63:0] cfg_interrupt_msi_pending_status;
  wire        cfg_interrupt_msi_sent;
  wire        cfg_interrupt_msi_fail;
  wire  [2:0] cfg_interrupt_msi_attr;
  wire        cfg_interrupt_msi_tph_present;
  wire  [1:0] cfg_interrupt_msi_tph_type;
  wire  [7:0] cfg_interrupt_msi_tph_st_tag;
  wire  [2:0] cfg_interrupt_msi_function_number;
  wire        cfg_interrupt_msi_pending_status_data_enable;
  wire  [3:0] cfg_interrupt_msi_pending_status_function_num;


// EP only
  wire cfg_hot_reset_out;
  wire cfg_config_space_enable;
  wire cfg_req_pm_transition_l23_ready;

// RP only
  wire cfg_hot_reset_in;

  wire [7:0]    cfg_ds_bus_number;
  wire [4:0]    cfg_ds_device_number;


  wire [15:0]  cfg_vend_id   = 16'h10EE; //16'h10EE;

  wire [15:0]  cfg_dev_id    = 16'hB03F; //16'h903F;
  wire [15:0]  cfg_subsys_id = 16'h0007; //16'h0007;
  wire [7:0]   cfg_rev_id    = 8'h00;    //8'h00;
  wire [15:0]  cfg_subsys_vend_id = 16'h10EE; //16'h10EE;

  //--------------------------------------------------------------------------------------------------------------------//
  // Instantiate Root Port wrapper
  //--------------------------------------------------------------------------------------------------------------------//
  // Core Top Level Wrapper
  design_rp design_rp_i (

    //-----------------------------------//
    //  System(SYS) Interface            //
    //-----------------------------------//
    .gt_refclk0_0_clk_n(sys_clk_n),
    .gt_refclk0_0_clk_p(sys_clk_p),

    .pcie0_user_clk_0(user_clk),
    .pcie0_user_lnk_up_0(user_lnk_up),
    .pcie0_user_reset_0(user_reset),
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
    .pcie0_s_axis_rq_0_tlast (s_axis_rq_tlast),
    .pcie0_s_axis_rq_0_tdata (s_axis_rq_tdata),
    .pcie0_s_axis_rq_0_tuser (s_axis_rq_tuser),
    .pcie0_s_axis_rq_0_tkeep (s_axis_rq_tkeep),
    .pcie0_s_axis_rq_0_tready(s_axis_rq_tready),
    .pcie0_s_axis_rq_0_tvalid(s_axis_rq_tvalid),

    .pcie0_m_axis_rc_0_tdata (m_axis_rc_tdata),
    .pcie0_m_axis_rc_0_tuser (m_axis_rc_tuser),
    .pcie0_m_axis_rc_0_tlast (m_axis_rc_tlast),
    .pcie0_m_axis_rc_0_tkeep (m_axis_rc_tkeep),
    .pcie0_m_axis_rc_0_tvalid(m_axis_rc_tvalid),
    .pcie0_m_axis_rc_0_tready(m_axis_rc_tready),


    .pcie0_m_axis_cq_0_tdata (m_axis_cq_tdata),
    .pcie0_m_axis_cq_0_tuser (m_axis_cq_tuser),
    .pcie0_m_axis_cq_0_tlast (m_axis_cq_tlast),
    .pcie0_m_axis_cq_0_tkeep (m_axis_cq_tkeep),
    .pcie0_m_axis_cq_0_tvalid(m_axis_cq_tvalid),
    .pcie0_m_axis_cq_0_tready(m_axis_cq_tready),

    .pcie0_s_axis_cc_0_tdata (s_axis_cc_tdata),
    .pcie0_s_axis_cc_0_tuser (s_axis_cc_tuser),
    .pcie0_s_axis_cc_0_tlast (s_axis_cc_tlast),
    .pcie0_s_axis_cc_0_tkeep (s_axis_cc_tkeep),
    .pcie0_s_axis_cc_0_tvalid(s_axis_cc_tvalid),
    .pcie0_s_axis_cc_0_tready(s_axis_cc_tready),

    //----------------------------------------//
    //  Configuration (CFG) Interface         //
    //----------------------------------------//

    .pcie0_cfg_status_0_cq_np_req       ({1'b0,pcie_cq_np_req}),
    .pcie0_cfg_status_0_cq_np_req_count (pcie_cq_np_req_count),
    .pcie0_cfg_status_0_phy_link_down   (cfg_phy_link_down),
    .pcie0_cfg_status_0_phy_link_status (cfg_phy_link_status),
    .pcie0_cfg_status_0_negotiated_width(cfg_negotiated_width),
    .pcie0_cfg_status_0_current_speed   (cfg_current_speed),
    .pcie0_cfg_status_0_max_payload     (cfg_max_payload),
    .pcie0_cfg_status_0_max_read_req    (cfg_max_read_req),
    .pcie0_cfg_status_0_function_status (cfg_function_status),
    .pcie0_cfg_status_0_function_power_state(cfg_function_power_state),
    .pcie0_cfg_status_0_link_power_state(cfg_link_power_state),

    // Error Reporting Interface
    .pcie0_cfg_status_0_err_cor_out     (cfg_err_cor_out),
    .pcie0_cfg_status_0_err_nonfatal_out(cfg_err_nonfatal_out),
    .pcie0_cfg_status_0_err_fatal_out   (cfg_err_fatal_out),
    .pcie0_cfg_status_0_local_error_out (),

    .pcie0_cfg_status_0_ltssm_state(cfg_ltssm_state),
    .pcie0_cfg_status_0_rcb_status (cfg_rcb_status),
    .pcie0_cfg_status_0_pl_status_change(cfg_pl_status_change),

    // Management Interface
    .pcie0_cfg_mgmt_0_addr      (cfg_mgmt_addr),
    .pcie0_cfg_mgmt_0_write_en  (cfg_mgmt_write),
    .pcie0_cfg_mgmt_0_write_data(cfg_mgmt_write_data),
    .pcie0_cfg_mgmt_0_byte_en   (cfg_mgmt_byte_enable),
    .pcie0_cfg_mgmt_0_read_en   (cfg_mgmt_read),
    .pcie0_cfg_mgmt_0_read_data (cfg_mgmt_read_data),
    .pcie0_cfg_mgmt_0_read_write_done(cfg_mgmt_read_write_done),
    .pcie0_cfg_mgmt_0_debug_access(1'b0),
    .pcie0_cfg_mgmt_0_function_number(8'b0),

    .pcie0_transmit_fc_0_nph_av(pcie_tfc_nph_av),
    .pcie0_transmit_fc_0_npd_av(pcie_tfc_npd_av),

    .pcie0_cfg_msg_recd_0_recd     (cfg_msg_received),
    .pcie0_cfg_msg_recd_0_recd_data(cfg_msg_received_data),
    .pcie0_cfg_msg_recd_0_recd_type(cfg_msg_received_type),

    .pcie0_cfg_msg_tx_0_transmit     (cfg_msg_transmit),
    .pcie0_cfg_msg_tx_0_transmit_type(cfg_msg_transmit_type),
    .pcie0_cfg_msg_tx_0_transmit_data(cfg_msg_transmit_data),
    .pcie0_cfg_msg_tx_0_transmit_done(cfg_msg_transmit_done),

    .pcie0_cfg_fc_0_ph  (cfg_fc_ph),
    .pcie0_cfg_fc_0_pd  (cfg_fc_pd),
    .pcie0_cfg_fc_0_nph (cfg_fc_nph),
    .pcie0_cfg_fc_0_npd (cfg_fc_npd),
    .pcie0_cfg_fc_0_cplh(cfg_fc_cplh),
    .pcie0_cfg_fc_0_cpld(cfg_fc_cpld),
    .pcie0_cfg_fc_0_sel (cfg_fc_sel),

    //-------------------------------------------------------------------------------//
    // EP and RP                                                                     //
    //-------------------------------------------------------------------------------//

    .pcie0_cfg_status_0_bus_number(),
    .pcie0_cfg_control_0_power_state_change_ack(cfg_power_state_change_ack),
    .pcie0_cfg_control_0_power_state_change_interrupt(cfg_power_state_change_interrupt),
    .pcie0_cfg_control_0_err_cor_in  (cfg_err_cor_in),
    .pcie0_cfg_control_0_err_uncor_in(cfg_err_uncor_in),

    .pcie0_cfg_control_0_flr_in_process(cfg_flr_in_process),
    .pcie0_cfg_control_0_flr_done({2'b0,cfg_flr_done}),

    .pcie0_cfg_control_0_hot_reset_out(cfg_hot_reset_out), // EP only
    .pcie0_cfg_control_0_hot_reset_in(cfg_hot_reset_in), // RP only

    .pcie0_cfg_ext_0_read_received  (cfg_ext_read_received),
    .pcie0_cfg_ext_0_write_received (cfg_ext_write_received),
    .pcie0_cfg_ext_0_register_number(cfg_ext_register_number),
    .pcie0_cfg_ext_0_function_number(cfg_ext_function_number),
    .pcie0_cfg_ext_0_write_data     (cfg_ext_write_data),
    .pcie0_cfg_ext_0_write_byte_enable(cfg_ext_write_byte_enable),
    .pcie0_cfg_ext_0_read_data      (cfg_ext_read_data),
    .pcie0_cfg_ext_0_read_data_valid(cfg_ext_read_data_valid)
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
    .s_axis_rq_tdata_o(s_axis_rq_tdata),
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

assign cfg_interrupt_msi_int = 32'b0;
assign cfg_interrupt_msi_attr = 3'b0;
assign cfg_interrupt_msi_select = 4'b0;
assign cfg_interrupt_msi_tph_type = 2'b0;
assign cfg_interrupt_msi_tph_present = 1'b0;
assign cfg_interrupt_msi_tph_st_tag = 8'h00;
assign cfg_interrupt_msi_pending_status = 64'b0;
assign cfg_interrupt_msi_function_number = 3'b0;

assign cfg_ext_read_data = 'h0;
assign cfg_ext_read_data_valid = 'h0;

assign user_lnk_up = (cfg_phy_link_status == 'h3) ? 1'b1 : 1'b0;

  // Common UsrApp
  pci_exp_usrapp_com com_usrapp();

endmodule
