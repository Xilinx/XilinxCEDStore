
//-----------------------------------------------------------------------------
//
// (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Versal PCI Express Integrated Block
// File       : xilinx_pcie_versal_rp.v
// Version    : 1.0 
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//--
//-- Description:  PCI Express DSPORT Model Top for Endpoint example FPGA design
//--
//------------------------------------------------------------------------------

`timescale 1ps / 1ps

module xilinx_pcie_versal_rp # (
  parameter C_DATA_WIDTH = 512,     // RX/TX interface data width
  parameter        EXT_PIPE_SIM                   = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.

  parameter        PL_LINK_CAP_MAX_LINK_SPEED     = 4,  //16 // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter  [4:0] PL_LINK_CAP_MAX_LINK_WIDTH     = 16, //4 // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16

  parameter  [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE   = 3'h0,

  parameter        PL_DISABLE_EI_INFER_IN_L0      = "TRUE",
  parameter        PL_DISABLE_UPCONFIG_CAPABLE    = "FALSE",
 
  parameter        REF_CLK_FREQ                   = 0,                 // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXI4_CQ_TUSER_WIDTH = 229,
  parameter        AXI4_CC_TUSER_WIDTH = 81,
  parameter        AXI4_RC_TUSER_WIDTH = 161,
  parameter        AXI4_RQ_TUSER_WIDTH = 183,
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG   = "TRUE",
  parameter        AXISTEN_IF_RQ_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_RC_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_CQ_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_MC_RX_STRADDLE      = "FALSE",
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC = "FALSE",
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF,
  parameter          CCIX_ENABLE                    = "FALSE",
  parameter          AXIS_CCIX_RX_TDATA_WIDTH       = 256,
  parameter          AXIS_CCIX_TX_TDATA_WIDTH       = 256,
  parameter          AXIS_CCIX_RX_TUSER_WIDTH       = 47,
  parameter          AXIS_CCIX_TX_TUSER_WIDTH       = 47,
  
  parameter          PF0_DEV_CAP2_10B_TAG_REQUESTER_SUPPORTED       = "TRUE",
  parameter KEEP_WIDTH                            = C_DATA_WIDTH / 32
)
(
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txp,
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txn,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,
    // synthesis translate_off
  input  [25:0] common_commands_in,
  input  [83:0]  pipe_rx_0_sigs,
  input  [83:0]  pipe_rx_1_sigs,
  input  [83:0]  pipe_rx_2_sigs,
  input  [83:0]  pipe_rx_3_sigs,
  input  [83:0]  pipe_rx_4_sigs,
  input  [83:0]  pipe_rx_5_sigs,
  input  [83:0]  pipe_rx_6_sigs,
  input  [83:0]  pipe_rx_7_sigs,
  input  [83:0]  pipe_rx_8_sigs,
  input  [83:0]  pipe_rx_9_sigs,
  input  [83:0]  pipe_rx_10_sigs,
  input  [83:0]  pipe_rx_11_sigs,
  input  [83:0]  pipe_rx_12_sigs,
  input  [83:0]  pipe_rx_13_sigs,
  input  [83:0]  pipe_rx_14_sigs,
  input  [83:0]  pipe_rx_15_sigs,
                      
  output [25:0]  common_commands_out,
  output [83:0]  pipe_tx_0_sigs,
  output [83:0]  pipe_tx_1_sigs,
  output [83:0]  pipe_tx_2_sigs,
  output [83:0]  pipe_tx_3_sigs,
  output [83:0]  pipe_tx_4_sigs,
  output [83:0]  pipe_tx_5_sigs,
  output [83:0]  pipe_tx_6_sigs,
  output [83:0]  pipe_tx_7_sigs,
  output [83:0]  pipe_tx_8_sigs,
  output [83:0]  pipe_tx_9_sigs,
  output [83:0]  pipe_tx_10_sigs,
  output [83:0]  pipe_tx_11_sigs,
  output [83:0]  pipe_tx_12_sigs,
  output [83:0]  pipe_tx_13_sigs,
  output [83:0]  pipe_tx_14_sigs,
  output [83:0]  pipe_tx_15_sigs,
    // synthesis translate_on   
  input                                           sys_clk_p,
  input                                           sys_clk_n,
  input                                           sys_rst_n
);

  localparam         TCQ = 1;
  localparam         EP_DEV_ID = 16'hB34F;

  //----------------------------------------------------------------------------------------------------------------//
  // 3. AXI Interface                                                                                               //
  //----------------------------------------------------------------------------------------------------------------//

  wire                                       user_clk;
  wire                                       core_clk;
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
  wire                              [2:0]    cfg_current_speed;
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

  wire                             [63:0]    cfg_dsn;
  wire                                       cfg_power_state_change_ack;
  wire                                       cfg_power_state_change_interrupt;
  wire                                       cfg_err_cor_in;
  wire                                       cfg_err_uncor_in;

  wire                              [3:0]    cfg_flr_in_process;
  wire                              [3:0]    cfg_flr_done;
  wire                              [251:0]    cfg_vf_flr_in_process;
  wire                                  cfg_vf_flr_done;

  wire                                       cfg_link_training_enable;
  wire                              [7:0]    cfg_ds_port_number;

  wire                                       cfg_ext_read_received;
  wire                                       cfg_ext_write_received;
  wire                              [9:0]    cfg_ext_register_number;
  wire                              [7:0]    cfg_ext_function_number;
  wire                             [31:0]    cfg_ext_write_data;
  wire                              [3:0]    cfg_ext_write_byte_enable;
  wire                             [31:0]    cfg_ext_read_data;
  wire                                       cfg_ext_read_data_valid;


  //----------------------------------------------------------------------------------------------------------------//
  // EP Only                                                                                                        //
  //----------------------------------------------------------------------------------------------------------------//

  // Interrupt Interface Signals
  wire                              [3:0]    cfg_interrupt_int;
  wire                              [1:0]    cfg_interrupt_pending;
  wire                                       cfg_interrupt_sent;

  wire                              [7:0]    cfg_vf_flr_func_num = 'd0;

  wire                                       ccix_optimized_tlp_tx_and_rx_enable = 1'b0; // Enable/Disable CCIX Optimized TLP Header Format
  //-----------------------------------------------------------------------
  // CCIX TX Interface
  // Data from CCIX protocol processing block
  //-----------------------------------------------------------------------
  wire [AXIS_CCIX_TX_TDATA_WIDTH-1:0]   s_axis_ccix_tx_tdata; // 256-bit data
  wire                                  s_axis_ccix_tx_tvalid; // Valid
  wire [AXIS_CCIX_TX_TUSER_WIDTH-1:0]   s_axis_ccix_tx_tuser; // tuser bus
                         // [0] = is_sop0, [1] = is_sop0_ptr,
                         // [2] = is_sop1, [3] = is_sop1_ptr,
                         // [4] = is_eop0, [7:5] = is_eop0_ptr,
                         // [8] = is_eop1, [11:9] = is_eop1_ptr,
                         // [13:12] = discontinue, [45:14] = odd parity
      
  wire           ccix_tx_credit_gnt;// Flow control credits from CCIX protocol processing block
  wire           ccix_tx_credit_rtn;// Used to return unused credits to CCIX protocol processing block
  wire           ccix_tx_active_req; // Asserted by TL to request a transition from STOP to ACTIVATE
  wire           ccix_tx_active_ack; // Grant from CCIX block
  //-----------------------------------------------------------------------
  // CCIX RX Interface
  // Data to downstream CCIX protocol processing block
  //-----------------------------------------------------------------------
  wire [AXIS_CCIX_RX_TDATA_WIDTH-1:0]   m_axis_ccix_rx_tdata;// 256-bit data
  wire                                  m_axis_ccix_rx_tvalid;// Valid
  wire [AXIS_CCIX_RX_TUSER_WIDTH-1:0]   m_axis_ccix_rx_tuser;// tuser bus
  // Bit fields
  // [0] = is_sop0, [1] = is_sop0_ptr,
  // [2] = is_sop1, [3] = is_sop1_ptr,
  // [4] = is_eop0, [7:5] = is_eop0_ptr,
  // [8] = is_eop1, [11:9] = is_eop1_ptr,
  // [13:12] = discontinue, [45:14] = odd parity

  wire        ccix_rx_credit_grant;// Flow control credits from CCIX protocol processing block
  wire        ccix_rx_credit_return;// Used to return unused credits to CCIX protocol processing block
  wire  [7:0] ccix_rx_credit_av;// Current value of available credit maintained by the bridge
  wire        ccix_rx_active_req; // Asserted by TL to request a transition from STOP to ACTIVATE
  wire        ccix_rx_active_ack; // Grant from CCIX block
  wire        ccix_rx_deact_hint = 1'b0;
  wire        cfg_vc1_enable;
  wire        cfg_vc1_negotiation_pending;
  wire        cxs0_active_req_tx;
  wire        cxs0_active_ack_tx;
  wire        cxs0_deact_hint_tx;
  wire        cxs0_valid_tx;
  wire        cxs0_crdgnt_tx;
  wire        cxs0_crdrtn_tx;
  wire [AXIS_CCIX_TX_TUSER_WIDTH-(AXIS_CCIX_TX_TDATA_WIDTH/8)-2:0]   cxs0_cntl_tx;
  wire [AXIS_CCIX_TX_TDATA_WIDTH-1:0]   cxs0_data_tx;
  wire        cxs0_valid_chk_tx;
  wire        cxs0_crdgnt_chk_tx;
  wire        cxs0_crdrtn_chk_tx;
  wire        cxs0_cntl_chk_tx;
  wire [AXIS_CCIX_TX_TDATA_WIDTH/8-1:0] cxs0_data_chk_tx;
  wire        cxs0_active_req_rx;
  wire        cxs0_active_ack_rx;
  wire        cxs0_deact_hint_rx;
  wire        cxs0_valid_rx;
  wire        cxs0_crdgnt_rx;
  wire        cxs0_crdrtn_rx;
  wire [AXIS_CCIX_RX_TUSER_WIDTH-(AXIS_CCIX_RX_TDATA_WIDTH/8)-2:0]  cxs0_cntl_rx;
  wire [AXIS_CCIX_RX_TDATA_WIDTH-1:0]   cxs0_data_rx;
  wire        cxs0_valid_chk_rx;
  wire        cxs0_crdgnt_chk_rx;
  wire        cxs0_crdrtn_chk_rx;
  wire        cxs0_cntl_chk_rx;
  wire [AXIS_CCIX_RX_TDATA_WIDTH/8-1:0] cxs0_data_chk_rx;

  wire cfg_fc_vc_sel=1'b0;


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

  //IBUFDS_GTE4 refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));

   wire  [25:0]  common_commands_in_i;
   wire  [83:0]  pipe_rx_0_sigs_i;
   wire  [83:0]  pipe_rx_1_sigs_i;
   wire  [83:0]  pipe_rx_2_sigs_i;
   wire  [83:0]  pipe_rx_3_sigs_i;
   wire  [83:0]  pipe_rx_4_sigs_i;
   wire  [83:0]  pipe_rx_5_sigs_i;
   wire  [83:0]  pipe_rx_6_sigs_i;
   wire  [83:0]  pipe_rx_7_sigs_i;
   wire  [83:0]  pipe_rx_8_sigs_i;
   wire  [83:0]  pipe_rx_9_sigs_i;
   wire  [83:0]  pipe_rx_10_sigs_i;
   wire  [83:0]  pipe_rx_11_sigs_i;
   wire  [83:0]  pipe_rx_12_sigs_i;
   wire  [83:0]  pipe_rx_13_sigs_i;
   wire  [83:0]  pipe_rx_14_sigs_i;
   wire  [83:0]  pipe_rx_15_sigs_i;  
   
   wire  [25:0]  common_commands_out_i;
   wire  [83:0]  pipe_tx_0_sigs_i;
   wire  [83:0]  pipe_tx_1_sigs_i;
   wire  [83:0]  pipe_tx_2_sigs_i;
   wire  [83:0]  pipe_tx_3_sigs_i;
   wire  [83:0]  pipe_tx_4_sigs_i;
   wire  [83:0]  pipe_tx_5_sigs_i;
   wire  [83:0]  pipe_tx_6_sigs_i;
   wire  [83:0]  pipe_tx_7_sigs_i;
   wire  [83:0]  pipe_tx_8_sigs_i;
   wire  [83:0]  pipe_tx_9_sigs_i;
   wire  [83:0]  pipe_tx_10_sigs_i;
   wire  [83:0]  pipe_tx_11_sigs_i;
   wire  [83:0]  pipe_tx_12_sigs_i;
   wire  [83:0]  pipe_tx_13_sigs_i;
   wire  [83:0]  pipe_tx_14_sigs_i;
   wire  [83:0]  pipe_tx_15_sigs_i;

// synthesis translate_off
generate if (EXT_PIPE_SIM == "TRUE") 
begin
   assign common_commands_in_i = common_commands_in;  
   assign pipe_rx_0_sigs_i     = pipe_rx_0_sigs;   
   assign pipe_rx_1_sigs_i     = pipe_rx_1_sigs;   
   assign pipe_rx_2_sigs_i     = pipe_rx_2_sigs;   
   assign pipe_rx_3_sigs_i     = pipe_rx_3_sigs;   
   assign pipe_rx_4_sigs_i     = pipe_rx_4_sigs;   
   assign pipe_rx_5_sigs_i     = pipe_rx_5_sigs;   
   assign pipe_rx_6_sigs_i     = pipe_rx_6_sigs;   
   assign pipe_rx_7_sigs_i     = pipe_rx_7_sigs;   
   assign pipe_rx_8_sigs_i     = pipe_rx_8_sigs;   
   assign pipe_rx_9_sigs_i     = pipe_rx_9_sigs;   
   assign pipe_rx_10_sigs_i     = pipe_rx_10_sigs;   
   assign pipe_rx_11_sigs_i     = pipe_rx_11_sigs;   
   assign pipe_rx_12_sigs_i     = pipe_rx_12_sigs;   
   assign pipe_rx_13_sigs_i     = pipe_rx_13_sigs;   
   assign pipe_rx_14_sigs_i     = pipe_rx_14_sigs;   
   assign pipe_rx_15_sigs_i     = pipe_rx_15_sigs;   
   
   assign common_commands_out  = common_commands_out_i; 
   assign pipe_tx_0_sigs       = pipe_tx_0_sigs_i;      
   assign pipe_tx_1_sigs       = pipe_tx_1_sigs_i;      
   assign pipe_tx_2_sigs       = pipe_tx_2_sigs_i;      
   assign pipe_tx_3_sigs       = pipe_tx_3_sigs_i;      
   assign pipe_tx_4_sigs       = pipe_tx_4_sigs_i;      
   assign pipe_tx_5_sigs       = pipe_tx_5_sigs_i;      
   assign pipe_tx_6_sigs       = pipe_tx_6_sigs_i;      
   assign pipe_tx_7_sigs       = pipe_tx_7_sigs_i;    
   assign pipe_tx_8_sigs       = pipe_tx_8_sigs_i;      
   assign pipe_tx_9_sigs       = pipe_tx_9_sigs_i;      
   assign pipe_tx_10_sigs       = pipe_tx_10_sigs_i;      
   assign pipe_tx_11_sigs       = pipe_tx_11_sigs_i;      
   assign pipe_tx_12_sigs       = pipe_tx_12_sigs_i;      
   assign pipe_tx_13_sigs       = pipe_tx_13_sigs_i;      
   assign pipe_tx_14_sigs       = pipe_tx_14_sigs_i;      
   assign pipe_tx_15_sigs       = pipe_tx_15_sigs_i;     
 end
endgenerate
    // synthesis translate_on   

generate if (EXT_PIPE_SIM == "FALSE") 
begin
  assign common_commands_in_i = 26'h0;  
  assign pipe_rx_0_sigs_i     = 84'h0;
  assign pipe_rx_1_sigs_i     = 84'h0;
  assign pipe_rx_2_sigs_i     = 84'h0;
  assign pipe_rx_3_sigs_i     = 84'h0;
  assign pipe_rx_4_sigs_i     = 84'h0;
  assign pipe_rx_5_sigs_i     = 84'h0;
  assign pipe_rx_6_sigs_i     = 84'h0;
  assign pipe_rx_7_sigs_i     = 84'h0;
  assign pipe_rx_8_sigs_i     = 84'h0; 
  assign pipe_rx_9_sigs_i     = 84'h0; 
  assign pipe_rx_10_sigs_i    = 84'h0; 
  assign pipe_rx_11_sigs_i    = 84'h0;    
  assign pipe_rx_12_sigs_i    = 84'h0;    
  assign pipe_rx_13_sigs_i    = 84'h0;    
  assign pipe_rx_14_sigs_i    = 84'h0;    
  assign pipe_rx_15_sigs_i    = 84'h0;    
 end
endgenerate

  wire [15:0]  cfg_vend_id        = 16'h10EE; //16'h10EE;   

  wire [15:0]  cfg_dev_id         = 16'h903F; //16'hB054;   
  wire [15:0]  cfg_subsys_id      = 16'h0007; //16'h0007;                                
  wire [7:0]   cfg_rev_id         = 8'h00;    //8'h00; 
  wire [15:0]  cfg_subsys_vend_id = 16'h10EE; //16'h10EE;

  wire  [63:0] cfg_interrupt_msi_pending_status;
  wire  [3:0]  cfg_interrupt_msi_select;
  wire  [31:0] cfg_interrupt_msi_int;
  wire  [2:0]  cfg_interrupt_msi_attr;
  wire         cfg_interrupt_msi_tph_present;
  wire  [1:0]  cfg_interrupt_msi_tph_type;
  wire  [7:0]  cfg_interrupt_msi_tph_st_tag;
  wire  [7:0]  cfg_interrupt_msi_function_number;
  
//--------------------------------------------------------------------------//
//                         Support Level Wrapper                            //
//--------------------------------------------------------------------------//
  design_sim_rp design_rp_i (
    //---------------------------------------------------------------------//
    //  ID Ports
    //---------------------------------------------------------------------//

    .pcie_cfg_mgmt_debug_access     (1'b0),
    .pcie_cfg_mgmt_function_number  (8'b0),

    .pcie_cfg_control_vf_flr_func_num(cfg_vf_flr_func_num),

    //------------------------------------------------------//
    //  USER_CLK; USER_RESET; USER_LINK_UP; PHY_RDY         //
    //------------------------------------------------------//
    .user_clk    (user_clk),
    .core_clk    (core_clk),
    .user_reset  (user_reset),
    .user_lnk_up (user_lnk_up),
    .phy_rdy_out (phy_rdy_out),

    //------------------------------------------------------//
    //  PCI Express (pci_exp) Interface                     //
    //------------------------------------------------------//
    // Tx
    .pcie_mgt_gtx_n (pci_exp_txn),
    .pcie_mgt_gtx_p (pci_exp_txp),

    // Rx
    .pcie_mgt_grx_n (pci_exp_rxn),
    .pcie_mgt_grx_p (pci_exp_rxp),

    //------------------------------------------------------//
    //  AXI Interface                                       //
    //------------------------------------------------------//
    .s_axis_rq_tlast  (s_axis_rq_tlast),
    .s_axis_rq_tdata  (s_axis_rq_tdata),
    .s_axis_rq_tuser  (s_axis_rq_tuser),
    .s_axis_rq_tkeep  (s_axis_rq_tkeep),
    .s_axis_rq_tready (s_axis_rq_tready),
    .s_axis_rq_tvalid (s_axis_rq_tvalid),

    .m_axis_rc_tdata  (m_axis_rc_tdata),
    .m_axis_rc_tuser  (m_axis_rc_tuser),
    .m_axis_rc_tlast  (m_axis_rc_tlast),
    .m_axis_rc_tkeep  (m_axis_rc_tkeep),
    .m_axis_rc_tvalid (m_axis_rc_tvalid),
    .m_axis_rc_tready (m_axis_rc_tready),

    .m_axis_cq_tdata  (m_axis_cq_tdata),
    .m_axis_cq_tuser  (m_axis_cq_tuser),
    .m_axis_cq_tlast  (m_axis_cq_tlast),
    .m_axis_cq_tkeep  (m_axis_cq_tkeep),
    .m_axis_cq_tvalid (m_axis_cq_tvalid),
    .m_axis_cq_tready (m_axis_cq_tready),

    .s_axis_cc_tdata  (s_axis_cc_tdata),
    .s_axis_cc_tuser  (s_axis_cc_tuser),
    .s_axis_cc_tlast  (s_axis_cc_tlast),
    .s_axis_cc_tkeep  (s_axis_cc_tkeep),
    .s_axis_cc_tvalid (s_axis_cc_tvalid),
    .s_axis_cc_tready (s_axis_cc_tready),

    .pipe_rp_commands_in(common_commands_in_i),
    .pipe_rp_rx_0 (pipe_rx_0_sigs_i),
    .pipe_rp_rx_1 (pipe_rx_1_sigs_i),
    .pipe_rp_rx_2 (pipe_rx_2_sigs_i),
    .pipe_rp_rx_3 (pipe_rx_3_sigs_i),
    .pipe_rp_rx_4 (pipe_rx_4_sigs_i),
    .pipe_rp_rx_5 (pipe_rx_5_sigs_i),
    .pipe_rp_rx_6 (pipe_rx_6_sigs_i),
    .pipe_rp_rx_7 (pipe_rx_7_sigs_i),
    .pipe_rp_rx_8 (pipe_rx_8_sigs_i),
    .pipe_rp_rx_9 (pipe_rx_9_sigs_i),
    .pipe_rp_rx_10(pipe_rx_10_sigs_i),
    .pipe_rp_rx_11(pipe_rx_11_sigs_i),
    .pipe_rp_rx_12(pipe_rx_12_sigs_i),
    .pipe_rp_rx_13(pipe_rx_13_sigs_i),
    .pipe_rp_rx_14(pipe_rx_14_sigs_i),
    .pipe_rp_rx_15(pipe_rx_15_sigs_i),

    .pipe_rp_commands_out(common_commands_out_i),
    .pipe_rp_tx_0 (pipe_tx_0_sigs_i),
    .pipe_rp_tx_1 (pipe_tx_1_sigs_i),
    .pipe_rp_tx_2 (pipe_tx_2_sigs_i),
    .pipe_rp_tx_3 (pipe_tx_3_sigs_i),
    .pipe_rp_tx_4 (pipe_tx_4_sigs_i),
    .pipe_rp_tx_5 (pipe_tx_5_sigs_i),
    .pipe_rp_tx_6 (pipe_tx_6_sigs_i),
    .pipe_rp_tx_7 (pipe_tx_7_sigs_i),
    .pipe_rp_tx_8 (pipe_tx_8_sigs_i),
    .pipe_rp_tx_9 (pipe_tx_9_sigs_i),
    .pipe_rp_tx_10(pipe_tx_10_sigs_i),
    .pipe_rp_tx_11(pipe_tx_11_sigs_i),
    .pipe_rp_tx_12(pipe_tx_12_sigs_i),
    .pipe_rp_tx_13(pipe_tx_13_sigs_i),
    .pipe_rp_tx_14(pipe_tx_14_sigs_i),
    .pipe_rp_tx_15(pipe_tx_15_sigs_i),

    //--------------------------------------------------------------//
    //  Configuration (CFG) Interface                               //
    //--------------------------------------------------------------//
    .pcie_cfg_status_rq_seq_num0 (pcie_rq_seq_num0) ,
    .pcie_cfg_status_rq_seq_num_vld0(pcie_rq_seq_num_vld0) ,
    .pcie_cfg_status_rq_seq_num1 (pcie_rq_seq_num1) ,
    .pcie_cfg_status_rq_seq_num_vld1(pcie_rq_seq_num_vld1) ,
    .pcie_cfg_status_rq_tag0     ( ),
    .pcie_cfg_status_rq_tag1     ( ),
    .pcie_cfg_status_rq_tag_av   ( ),
    .pcie_cfg_status_rq_tag_vld0 ( ),
    .pcie_cfg_status_rq_tag_vld1 ( ),

    .pcie_cfg_status_cq_np_req        ({1'b1,pcie_cq_np_req}),
    .pcie_cfg_status_cq_np_req_count  (pcie_cq_np_req_count),
    .pcie_cfg_status_phy_link_down    (cfg_phy_link_down),
    .pcie_cfg_status_phy_link_status  ( ),
    .pcie_cfg_status_negotiated_width (cfg_negotiated_width),
    .pcie_cfg_status_current_speed    (cfg_current_speed),
    .pcie_cfg_status_max_payload      (cfg_max_payload),
    .pcie_cfg_status_max_read_req     (cfg_max_read_req),
    .pcie_cfg_status_function_status  (cfg_function_status),
    .pcie_cfg_status_function_power_state(cfg_function_power_state),
    .pcie_cfg_status_vf_status        (cfg_vf_status),
    .pcie_cfg_status_vf_power_state   (cfg_vf_power_state),
    .pcie_cfg_status_link_power_state (cfg_link_power_state),
    .pcie_cfg_status_err_cor_out      (cfg_err_cor_out),
    .pcie_cfg_status_err_nonfatal_out (cfg_err_nonfatal_out),
    .pcie_cfg_status_err_fatal_out    (cfg_err_fatal_out),
    .pcie_cfg_status_local_error_out  ( ),
    .pcie_cfg_status_local_error_valid( ),
    .pcie_cfg_status_ltssm_state      (cfg_ltssm_state),
    .pcie_cfg_status_rx_pm_state      ( ),
    .pcie_cfg_status_tx_pm_state      ( ),
    .pcie_cfg_status_rcb_status       (cfg_rcb_status),
    .pcie_cfg_status_obff_enable      (cfg_obff_enable),
    .pcie_cfg_status_pl_status_change (cfg_pl_status_change),
    .pcie_cfg_status_tph_requester_enable(cfg_tph_requester_enable),
    .pcie_cfg_status_tph_st_mode      (cfg_tph_st_mode),
    .pcie_cfg_status_vf_tph_requester_enable(cfg_vf_tph_requester_enable),
    .pcie_cfg_status_vf_tph_st_mode   (cfg_vf_tph_st_mode),

    .pcie_cfg_mgmt_addr      (cfg_mgmt_addr),
    .pcie_cfg_mgmt_write_en  (cfg_mgmt_write),
    .pcie_cfg_mgmt_write_data(cfg_mgmt_write_data),
    .pcie_cfg_mgmt_byte_en   (cfg_mgmt_byte_enable),
    .pcie_cfg_mgmt_read_en   (cfg_mgmt_read),
    .pcie_cfg_mgmt_read_data (cfg_mgmt_read_data),
    .pcie_cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),

    .pcie_cfg_mesg_rcvd_recd       (cfg_msg_received),
    .pcie_cfg_mesg_rcvd_recd_data  (cfg_msg_received_data),
    .pcie_cfg_mesg_rcvd_recd_type  (cfg_msg_received_type),
    .pcie_cfg_mesg_tx_transmit     (cfg_msg_transmit),
    .pcie_cfg_mesg_tx_transmit_type(cfg_msg_transmit_type),
    .pcie_cfg_mesg_tx_transmit_data(cfg_msg_transmit_data),
    .pcie_cfg_mesg_tx_transmit_done(cfg_msg_transmit_done),

    .pcie_cfg_fc_ph   (cfg_fc_ph),
    .pcie_cfg_fc_pd   (cfg_fc_pd),
    .pcie_cfg_fc_nph  (cfg_fc_nph),
    .pcie_cfg_fc_npd  (cfg_fc_npd),
    .pcie_cfg_fc_cplh (cfg_fc_cplh),
    .pcie_cfg_fc_cpld (cfg_fc_cpld),
    .pcie_cfg_fc_sel  (cfg_fc_sel),

    .pcie_transmit_fc_nph_av               (pcie_tfc_nph_av),
    .pcie_transmit_fc_npd_av               (pcie_tfc_npd_av),

    .pcie_cfg_control_bus_number            ( ),
    .pcie_cfg_control_dsn                   (cfg_dsn),
    .pcie_cfg_control_power_state_change_ack(cfg_power_state_change_ack),
    .pcie_cfg_control_power_state_change_interrupt (cfg_power_state_change_interrupt),
    .pcie_cfg_control_err_cor_in           (cfg_err_cor_in),
    .pcie_cfg_control_err_uncor_in         (cfg_err_uncor_in),
    .pcie_cfg_control_flr_in_process       (cfg_flr_in_process),
    .pcie_cfg_control_flr_done             (cfg_flr_done),
    .pcie_cfg_control_vf_flr_in_process    (cfg_vf_flr_in_process),
    .pcie_cfg_control_vf_flr_done          (cfg_vf_flr_done),
    .pcie_cfg_control_link_training_enable (cfg_link_training_enable),
    .pcie_cfg_control_hot_reset_out        (cfg_hot_reset_out),
    .pcie_cfg_control_config_space_enable  (cfg_config_space_enable),
    .pcie_cfg_control_req_pm_transition_l23_ready (cfg_req_pm_transition_l23_ready),
    .pcie_cfg_control_hot_reset_in         (cfg_hot_reset_in),
    .pcie_cfg_control_ds_bus_number        (cfg_ds_bus_number),
    .pcie_cfg_control_ds_device_number     (cfg_ds_device_number),
    .pcie_cfg_control_ds_port_number       (cfg_ds_port_number),

    .pcie_cfg_interrupt_intx_vector (cfg_interrupt_int),
    .pcie_cfg_interrupt_pending     ({2'b0,cfg_interrupt_pending}),
    .pcie_cfg_interrupt_sent        (cfg_interrupt_sent),




    .pcie_cfg_control_pm_aspm_l1entry_reject       (1'b0),
    .pcie_cfg_control_pm_aspm_tx_l0s_entry_disable (1'b1),


    //--------------------------------------------------------------------------------------//
    //  System(SYS) Interface                                                               //
    //--------------------------------------------------------------------------------------//
    .pcie_refclk_clk_n  (sys_clk_n),
    .pcie_refclk_clk_p  (sys_clk_p),

    .sys_reset (sys_rst_n_c)
  );

  pci_exp_usrapp_rx # (
    .AXISTEN_IF_CC_ALIGNMENT_MODE     ( AXISTEN_IF_CC_ALIGNMENT_MODE ),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE     ( AXISTEN_IF_CQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_ALIGNMENT_MODE     ( AXISTEN_IF_RC_ALIGNMENT_MODE ), 
    .AXISTEN_IF_RQ_ALIGNMENT_MODE     ( AXISTEN_IF_RQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_PARITY_CHECK       ( AXISTEN_IF_RC_PARITY_CHECK   ),
    .AXISTEN_IF_CQ_PARITY_CHECK       ( AXISTEN_IF_CQ_PARITY_CHECK   ),
    .AXI4_CQ_TUSER_WIDTH                    (AXI4_CQ_TUSER_WIDTH),
    .AXI4_RC_TUSER_WIDTH                    (AXI4_RC_TUSER_WIDTH),
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
    
    .m_axis_ccix_rx_tdata(m_axis_ccix_rx_tdata),
    .m_axis_ccix_rx_tvalid(m_axis_ccix_rx_tvalid),
    .m_axis_ccix_rx_tuser(m_axis_ccix_rx_tuser),
    
    .ccix_rx_credit_grant  (ccix_rx_credit_grant),
    .ccix_rx_credit_return (ccix_rx_credit_return),
    .ccix_rx_credit_av     (ccix_rx_credit_av),
    .ccix_rx_active_req    (ccix_rx_active_req),
    .ccix_rx_active_ack    (ccix_rx_active_ack),
    .pcie_cq_np_req(pcie_cq_np_req),
    .user_clk(user_clk),
    .core_clk(core_clk),
    .user_reset(user_reset),
    .user_lnk_up(user_lnk_up)

  );

  // Tx User Application Interface
  pci_exp_usrapp_tx # (
    .PF0_DEV_CAP2_10B_TAG_REQUESTER_SUPPORTED ( PF0_DEV_CAP2_10B_TAG_REQUESTER_SUPPORTED),
    .C_DATA_WIDTH                     ( C_DATA_WIDTH),
    .DEV_CAP_MAX_PAYLOAD_SUPPORTED    ( PF0_DEV_CAP_MAX_PAYLOAD_SIZE ),
    .AXISTEN_IF_CC_ALIGNMENT_MODE     ( AXISTEN_IF_CC_ALIGNMENT_MODE ),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE     ( AXISTEN_IF_CQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_ALIGNMENT_MODE     ( AXISTEN_IF_RC_ALIGNMENT_MODE ),
    .AXISTEN_IF_RQ_ALIGNMENT_MODE     ( AXISTEN_IF_RQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RQ_PARITY_CHECK       ( AXISTEN_IF_RQ_PARITY_CHECK   ),
    .AXISTEN_IF_CC_PARITY_CHECK       ( AXISTEN_IF_CC_PARITY_CHECK   ),
    .AXI4_CC_TUSER_WIDTH                    (AXI4_CC_TUSER_WIDTH),
    .AXI4_RQ_TUSER_WIDTH                    (AXI4_RQ_TUSER_WIDTH),
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

  .s_axis_ccix_tx_tdata  (s_axis_ccix_tx_tdata),
  .s_axis_ccix_tx_tvalid (s_axis_ccix_tx_tvalid),
  .s_axis_ccix_tx_tuser  (s_axis_ccix_tx_tuser),
  .cfg_vc1_negotiation_pending(cfg_vc1_negotiation_pending),
  .cfg_vc1_enable        (cfg_vc1_enable),
  .ccix_tx_credit_gnt    (ccix_tx_credit_gnt),
  .ccix_tx_credit_rtn    (ccix_tx_credit_rtn),
  .ccix_tx_active_req    (ccix_tx_active_req),
  .ccix_tx_active_ack    (ccix_tx_active_ack),

  .pcie_rq_seq_num    (pcie_rq_seq_num),
  .pcie_rq_seq_num_vld(pcie_rq_seq_num_vld),
  .pcie_rq_tag        (pcie_rq_tag),
  .pcie_rq_tag_vld    (pcie_rq_tag_vld),
  .pcie_tfc_nph_av    (pcie_tfc_nph_av),
  .pcie_tfc_npd_av    (pcie_tfc_npd_av),
  .speed_change_done_n(),
  .user_clk           (user_clk),
    .core_clk(core_clk),
  .reset            (user_reset),
  .user_lnk_up      (user_lnk_up)
  );

  // Cfg UsrApp
  pci_exp_usrapp_cfg cfg_usrapp (

 .user_clk                                  (user_clk),
 .user_reset                                (user_reset),
  //---------------------------------------//
  // 4. Configuration (CFG) Interface                                                          //
  //---------------------------------------//
  // EP and RP                                                                                 //
  //---------------------------------------//

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
 .cfg_ext_read_received                     (cfg_ext_read_received),
 .cfg_ext_write_received                    (cfg_ext_write_received),
 .cfg_ext_register_number                   (cfg_ext_register_number),
 .cfg_ext_function_number                   (cfg_ext_function_number),
 .cfg_ext_write_data                        (cfg_ext_write_data),
 .cfg_ext_write_byte_enable                 (cfg_ext_write_byte_enable),
 .cfg_ext_read_data                         (cfg_ext_read_data),
 .cfg_ext_read_data_valid                   (cfg_ext_read_data_valid),



 .cfg_hot_reset_out                         (cfg_hot_reset_out),
 .cfg_config_space_enable                   (cfg_config_space_enable),
 .cfg_req_pm_transition_l23_ready           (cfg_req_pm_transition_l23_ready),
  //------------------------------------------------------//
  // RP Only                                                                                  //
  //------------------------------------------------------//
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
assign  cfg_interrupt_msi_function_number = 'd0;

  // Common UsrApp
  pci_exp_usrapp_com com_usrapp   ();



endmodule
