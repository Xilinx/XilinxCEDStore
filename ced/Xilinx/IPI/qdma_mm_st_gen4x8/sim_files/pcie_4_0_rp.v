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
// File       : pcie_4_0_rp.v
// Version    : 5.0
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// 
//      Root Port Model
//
//-----------------------------------------------------------------------------

`timescale 1ps/1ps


module pcie_4_0_rp #(

   parameter  integer     LANES = 16, 
   parameter [4:0]        PL_LINK_CAP_MAX_LINK_WIDTH=5'd16,
   parameter [3:0]        PL_LINK_CAP_MAX_LINK_SPEED=4'd4,
   parameter              KESTREL_512_HLF = "FALSE",
   parameter              AXI4_DATA_WIDTH = 512, 
   parameter              AXI4_TKEEP_WIDTH = 512/32, 
   parameter              AXISTEN_IF_EXT_512= (AXI4_DATA_WIDTH == 512) ? "TRUE" : "FALSE",
   parameter              IMPL_TARGET = "HARD",
   parameter [1:0]        PL_SIM_FAST_LINK_TRAINING=2'b11,
   parameter              PL_UPSTREAM_FACING="FALSE",
   parameter  [1:0]       CRM_USER_CLK_FREQ=2'd3,
   parameter              CRM_CORE_CLK_FREQ= 2,
   parameter              PL_DEEMPH_SOURCE_SELECT="TRUE",
   parameter              TL_COMPLETION_RAM_SIZE=2'b10,    
   parameter              AXISTEN_IF_RX_PARITY_EN="FALSE",    
   parameter              AXISTEN_IF_TX_PARITY_EN="FALSE",     
   parameter              LL_TX_TLP_PARITY_CHK="FALSE",      
   parameter              LL_RX_TLP_PARITY_GEN="FALSE",    
   parameter              AXISTEN_IF_ENABLE_CLIENT_TAG="FALSE",  
   parameter [15:0]    PL_USER_SPARE=16'h3,
   parameter              AXI4_CQ_TUSER_WIDTH = 183,
   parameter              AXI4_CC_TUSER_WIDTH = 81,
   parameter              AXI4_RQ_TUSER_WIDTH = 137,
   parameter              AXI4_RC_TUSER_WIDTH = 161,
   parameter              AXI4_CQ_TREADY_WIDTH = 22,
   parameter              AXI4_CC_TREADY_WIDTH = 4,
   parameter              AXI4_RQ_TREADY_WIDTH = 4,
   parameter              AXI4_RC_TREADY_WIDTH = 22
   )(
    input  wire           pl_gen2_upstream_prefer_deemph
   ,output wire           pl_eq_in_progress
   ,output wire [1:0]     pl_eq_phase
   ,input  wire           pl_eq_reset_eieos_count
   ,input  wire           pl_redo_eq
   ,input  wire           pl_redo_eq_speed
   ,output wire           pl_eq_mismatch
   ,output wire           pl_redo_eq_pending
   ,output wire [AXI4_DATA_WIDTH-1:0] m_axis_cq_tdata
   ,input  wire [AXI4_DATA_WIDTH-1:0] s_axis_cc_tdata
   ,input  wire [AXI4_DATA_WIDTH-1:0] s_axis_rq_tdata
   ,output wire [AXI4_DATA_WIDTH-1:0] m_axis_rc_tdata
   ,output wire [AXI4_CQ_TUSER_WIDTH-1:0] m_axis_cq_tuser
   ,input  wire [AXI4_CC_TUSER_WIDTH-1:0] s_axis_cc_tuser
   ,output wire           m_axis_cq_tlast
   ,input  wire           s_axis_rq_tlast
   ,output wire           m_axis_rc_tlast
   ,input  wire           s_axis_cc_tlast
   ,input  wire [1:0]     pcie_cq_np_req
   ,output wire [5:0]     pcie_cq_np_req_count
   ,input  wire [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser
   ,output wire [AXI4_RC_TUSER_WIDTH-1:0] m_axis_rc_tuser
   ,output wire [AXI4_TKEEP_WIDTH-1:0] m_axis_cq_tkeep
   ,input  wire [AXI4_TKEEP_WIDTH-1:0] s_axis_cc_tkeep
   ,input  wire [AXI4_TKEEP_WIDTH-1:0] s_axis_rq_tkeep
   ,output wire [AXI4_TKEEP_WIDTH-1:0] m_axis_rc_tkeep
   ,output wire           m_axis_cq_tvalid
   ,input  wire           s_axis_cc_tvalid
   ,input  wire           s_axis_rq_tvalid
   ,output wire           m_axis_rc_tvalid
   ,input  wire [AXI4_CQ_TREADY_WIDTH-1:0] m_axis_cq_tready
   ,output wire [AXI4_CC_TREADY_WIDTH-1:0] s_axis_cc_tready
   ,output wire [AXI4_RQ_TREADY_WIDTH-1:0] s_axis_rq_tready
   ,input  wire [AXI4_RC_TREADY_WIDTH-1:0] m_axis_rc_tready
   ,output wire [5:0]     pcie_rq_seq_num0
   ,output wire           pcie_rq_seq_num_vld0
   ,output wire [5:0]     pcie_rq_seq_num1
   ,output wire           pcie_rq_seq_num_vld1
   ,output wire [7:0]     pcie_rq_tag0
   ,output wire           pcie_rq_tag_vld0
   ,output wire [7:0]     pcie_rq_tag1
   ,output wire           pcie_rq_tag_vld1
   ,output wire [3:0]     pcie_tfc_nph_av
   ,output wire [3:0]     pcie_tfc_npd_av
   ,output wire [3:0]     pcie_rq_tag_av
   ,input  wire [9:0]     cfg_mgmt_addr
   ,input  wire [7:0]     cfg_mgmt_function_number
   ,input  wire           cfg_mgmt_write
   ,input  wire [31:0]    cfg_mgmt_write_data
   ,input  wire [3:0]     cfg_mgmt_byte_enable
   ,input  wire           cfg_mgmt_read
   ,output wire [31:0]    cfg_mgmt_read_data
   ,output wire           cfg_mgmt_read_write_done
   ,input  wire           cfg_mgmt_debug_access
   ,output wire           cfg_phy_link_down
   ,output wire [1:0]     cfg_phy_link_status
   ,output wire [2:0]     cfg_negotiated_width
   ,output wire [1:0]     cfg_current_speed
   ,output wire [1:0]     cfg_max_payload
   ,output wire [2:0]     cfg_max_read_req
   ,output wire [15:0]    cfg_function_status
   ,output wire [11:0]    cfg_function_power_state
   ,output wire [1:0]     cfg_link_power_state
   ,output wire           cfg_err_cor_out
   ,output wire           cfg_err_nonfatal_out
   ,output wire           cfg_err_fatal_out
   ,output wire           cfg_local_error_valid
   ,output wire [4:0]     cfg_local_error_out
   ,output wire [5:0]     cfg_ltssm_state
   ,output wire [1:0]     cfg_rx_pm_state
   ,output wire [1:0]     cfg_tx_pm_state
   ,output wire [3:0]     cfg_rcb_status
   ,output wire [1:0]     cfg_obff_enable
   ,output wire           cfg_pl_status_change
   ,output wire [3:0]     cfg_tph_requester_enable
   ,output wire [11:0]    cfg_tph_st_mode
   ,output wire           cfg_msg_received
   ,output wire [7:0]     cfg_msg_received_data
   ,output wire [4:0]     cfg_msg_received_type
   ,input  wire           cfg_msg_transmit
   ,input  wire [2:0]     cfg_msg_transmit_type
   ,input  wire [31:0]    cfg_msg_transmit_data
   ,output wire           cfg_msg_transmit_done
   ,output wire [7:0]     cfg_fc_ph
   ,output wire [11:0]    cfg_fc_pd
   ,output wire [7:0]     cfg_fc_nph
   ,output wire [11:0]    cfg_fc_npd
   ,output wire [7:0]     cfg_fc_cplh
   ,output wire [11:0]    cfg_fc_cpld
   ,input  wire [2:0]     cfg_fc_sel
   ,input  wire           cfg_hot_reset_in
   ,output wire           cfg_hot_reset_out
   ,input  wire           cfg_config_space_enable
   ,input  wire [63:0]    cfg_dsn
   ,input  wire [15:0]    cfg_dev_id_pf0
   ,input  wire [15:0]    cfg_dev_id_pf1
   ,input  wire [15:0]    cfg_dev_id_pf2
   ,input  wire [15:0]    cfg_dev_id_pf3
   ,input  wire [15:0]    cfg_vend_id
   ,input  wire [7:0]     cfg_rev_id_pf0
   ,input  wire [7:0]     cfg_rev_id_pf1
   ,input  wire [7:0]     cfg_rev_id_pf2
   ,input  wire [7:0]     cfg_rev_id_pf3
   ,input  wire [15:0]    cfg_subsys_id_pf0
   ,input  wire [15:0]    cfg_subsys_id_pf1
   ,input  wire [15:0]    cfg_subsys_id_pf2
   ,input  wire [15:0]    cfg_subsys_id_pf3
   ,input  wire [15:0]    cfg_subsys_vend_id
   ,input  wire [7:0]     cfg_ds_port_number
   ,input  wire [7:0]     cfg_ds_bus_number
   ,input  wire [4:0]     cfg_ds_device_number
   ,output wire [7:0]     cfg_bus_number
   ,input  wire           cfg_power_state_change_ack
   ,output wire           cfg_power_state_change_interrupt
   ,input  wire           cfg_err_cor_in
   ,input  wire           cfg_err_uncor_in
   ,input  wire [3:0]     cfg_flr_done
   ,output wire [3:0]     cfg_flr_in_process
   ,input  wire           cfg_req_pm_transition_l23_ready
   ,input  wire           cfg_link_training_enable
   ,input  wire [3:0]     cfg_interrupt_int
   ,output wire           cfg_interrupt_sent
   ,input  wire [3:0]     cfg_interrupt_pending
   ,output wire [3:0]     cfg_interrupt_msi_enable
   ,input  wire [31:0]    cfg_interrupt_msi_int
   ,output wire           cfg_interrupt_msi_sent
   ,output wire           cfg_interrupt_msi_fail
   ,output wire [11:0]    cfg_interrupt_msi_mmenable
   ,input  wire [31:0]    cfg_interrupt_msi_pending_status
   ,input  wire [1:0]     cfg_interrupt_msi_pending_status_function_num
   ,input  wire           cfg_interrupt_msi_pending_status_data_enable
   ,output wire           cfg_interrupt_msi_mask_update
   ,input  wire [1:0]     cfg_interrupt_msi_select
   ,output wire [31:0]    cfg_interrupt_msi_data
   ,output wire [3:0]     cfg_interrupt_msix_enable
   ,output wire [3:0]     cfg_interrupt_msix_mask
   ,input  wire [63:0]    cfg_interrupt_msix_address
   ,input  wire [31:0]    cfg_interrupt_msix_data
   ,input  wire           cfg_interrupt_msix_int
   ,input  wire [1:0]     cfg_interrupt_msix_vec_pending
   ,output wire           cfg_interrupt_msix_vec_pending_status
   ,input  wire [2:0]     cfg_interrupt_msi_attr
   ,input  wire           cfg_interrupt_msi_tph_present
   ,input  wire [1:0]     cfg_interrupt_msi_tph_type
   ,input  wire [7:0]     cfg_interrupt_msi_tph_st_tag
   ,input  wire [7:0]     cfg_interrupt_msi_function_number
   ,output wire           cfg_ext_read_received
   ,output wire           cfg_ext_write_received
   ,output wire [9:0]     cfg_ext_register_number
   ,output wire [7:0]     cfg_ext_function_number
   ,output wire [31:0]    cfg_ext_write_data
   ,output wire [3:0]     cfg_ext_write_byte_enable
   ,input  wire [31:0]    cfg_ext_read_data
   ,input  wire           cfg_ext_read_data_valid
   ,output wire [251:0]   cfg_vf_flr_in_process
   ,input  wire           cfg_vf_flr_done
   ,input  wire [7:0]     cfg_vf_flr_func_num
   ,output wire [503:0]   cfg_vf_status
   ,output wire [755:0]   cfg_vf_power_state 
   ,output wire [251:0]   cfg_vf_tph_requester_enable
   ,output wire [755:0]   cfg_vf_tph_st_mode
   ,output wire [251:0]   cfg_interrupt_msix_vf_enable
   ,output wire [251:0]   cfg_interrupt_msix_vf_mask
   ,input  wire           cfg_pm_aspm_l1_entry_reject
   ,input  wire           cfg_pm_aspm_tx_l0s_entry_disable
   ,input  wire [1:0]     conf_req_type
   ,input  wire [3:0]     conf_req_reg_num
   ,input  wire [31:0]    conf_req_data
   ,input  wire           conf_req_valid
   ,output wire           conf_req_ready
   ,output wire [31:0]    conf_resp_rdata
   ,output wire           conf_resp_valid
   ,output wire           conf_mcap_design_switch
   ,output wire           conf_mcap_eos
   ,output wire           conf_mcap_in_use_by_pcie
   ,input  wire           conf_mcap_request_by_conf

/*
   ,output wire [255:0]   dbg_data0_out
   ,output wire [31:0]    dbg_ctrl0_out
   ,input  wire [5:0]     dbg_sel0
   ,output wire [255:0]   dbg_data1_out
   ,output wire [31:0]    dbg_ctrl1_out
   ,input  wire [5:0]     dbg_sel1
   ,input  wire           drp_clk
   ,input  wire           drp_en
   ,input  wire           drp_we
   ,input  wire [9:0]     drp_addr
   ,input  wire [15:0]    drp_di
   ,output wire           drp_rdy
   ,output wire [15:0]    drp_do
   ,input  wire           scanmode_n
   ,input  wire           scanenable_n
   ,input  wire [149:0]   scanin
   ,output wire [149:0]   scanout
   ,output wire           pcie_perst0_b
   ,output wire           pcie_perst1_b
   ,input  wire           pmv_enable_n
   ,input  wire [2:0]     pmv_select
   ,input  wire [1:0]     pmv_divide
   ,output wire           pmv_out
   ,input  wire [31:0]    user_spare_in
   ,output wire [31:0]    user_spare_out
*/
   ,output wire           user_clk
   ,output wire           user_reset
   ,output wire           user_lnk_up
   ,input  wire           sys_clk
   ,input  wire           sys_clk_gt
   ,input  wire           sys_reset
   ,input  wire [LANES-1:0]     pci_exp_rxp
   ,input  wire [LANES-1:0]     pci_exp_rxn
   ,output wire [LANES-1:0]     pci_exp_txp
   ,output wire [LANES-1:0]     pci_exp_txn

  );

    localparam            TCQ = 100;
    localparam  integer   PHY_REFCLK_FREQ=0;                 // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz;
    localparam            AXISTEN_IF_EXT_512_INTFC_RAM_STYLE="BRAM";
    localparam            FPGA_FAMILY="USM";
    localparam            FPGA_XCVR="Y";
    localparam  integer   PIPE_PIPELINE_STAGES=0;
    localparam            CRM_MCAP_CLK_FREQ=1'b0;
    localparam  [1:0]     AXISTEN_IF_WIDTH=(AXI4_DATA_WIDTH == 64) ? 2'b00 : (AXI4_DATA_WIDTH == 128) ? 2'b01 : (AXI4_DATA_WIDTH == 256) ? 2'b10 : 2'b11;
    localparam            AXISTEN_IF_EXT_512_CQ_STRADDLE="FALSE";
    localparam            AXISTEN_IF_EXT_512_CC_STRADDLE="FALSE";
    localparam            AXISTEN_IF_EXT_512_RQ_STRADDLE="FALSE";
    localparam            AXISTEN_IF_EXT_512_RC_STRADDLE="FALSE";
    localparam  [1:0]     AXISTEN_IF_CQ_ALIGNMENT_MODE=2'b00;
    localparam  [1:0]     AXISTEN_IF_CC_ALIGNMENT_MODE=2'b00;
    localparam  [1:0]     AXISTEN_IF_RQ_ALIGNMENT_MODE=2'b00;
    localparam  [1:0]     AXISTEN_IF_RC_ALIGNMENT_MODE=2'b00;
    localparam            AXISTEN_IF_RC_STRADDLE="FALSE";
    localparam            AXISTEN_IF_ENABLE_RX_MSG_INTFC="FALSE";
    localparam  [17:0]    AXISTEN_IF_ENABLE_MSG_ROUTE=18'h3FFFF;
    localparam            AXISTEN_IF_ENABLE_256_TAGS="TRUE";
    localparam  [23:0]    AXISTEN_IF_COMPL_TIMEOUT_REG0=24'hBEBC20;
    localparam  [27:0]    AXISTEN_IF_COMPL_TIMEOUT_REG1=28'h2FAF080;
    localparam            AXISTEN_IF_LEGACY_MODE_ENABLE="FALSE";
    localparam            AXISTEN_IF_ENABLE_MESSAGE_RID_CHECK="TRUE";
    localparam            AXISTEN_IF_MSIX_TO_RAM_PIPELINE="FALSE";
    localparam            AXISTEN_IF_MSIX_FROM_RAM_PIPELINE="FALSE";

    localparam            AXISTEN_IF_MSIX_RX_PARITY_EN="TRUE";
    localparam            AXISTEN_IF_ENABLE_INTERNAL_MSIX_TABLE="FALSE";

    localparam            AXISTEN_IF_SIM_SHORT_CPL_TIMEOUT="FALSE";
    localparam            AXISTEN_IF_CQ_EN_POISONED_MEM_WR="FALSE";
    localparam            AXISTEN_IF_RQ_CC_REGISTERED_TREADY="TRUE";
    localparam  [15:0]    PM_ASPML0S_TIMEOUT=16'h1500;
    localparam  [31:0]    PM_L1_REENTRY_DELAY= (CRM_CORE_CLK_FREQ == 2) ? 32'hC350 :  32'h61A8;
    localparam  [19:0]    PM_ASPML1_ENTRY_DELAY=20'h0;
    localparam            PM_ENABLE_SLOT_POWER_CAPTURE="TRUE";
    localparam  [19:0]    PM_PME_SERVICE_TIMEOUT_DELAY=20'h0;
    localparam  [15:0]    PM_PME_TURNOFF_ACK_DELAY=16'h100;
    localparam            PL_DISABLE_DC_BALANCE="FALSE";
    localparam            PL_DISABLE_EI_INFER_IN_L0="FALSE";
    localparam  integer   PL_N_FTS=255;
    localparam            PL_DISABLE_UPCONFIG_CAPABLE="FALSE";
    localparam            PL_DISABLE_RETRAIN_ON_FRAMING_ERROR="FALSE";
    localparam            PL_DISABLE_RETRAIN_ON_EB_ERROR="FALSE";
    localparam  [15:0]    PL_DISABLE_RETRAIN_ON_SPECIFIC_FRAMING_ERROR=16'b0000000000000000;
    localparam  [7:0]     PL_REPORT_ALL_PHY_ERRORS=8'b00000000;
    localparam  [1:0]     PL_DISABLE_LFSR_UPDATE_ON_SKP=2'b00;
    localparam  [31:0]    PL_LANE0_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE1_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE2_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE3_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE4_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE5_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE6_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE7_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE8_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE9_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE10_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE11_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE12_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE13_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE14_EQ_CONTROL=32'h3400;
    localparam  [31:0]    PL_LANE15_EQ_CONTROL=32'h3400;
    localparam  [1:0]     PL_EQ_BYPASS_PHASE23=2'b01;
    localparam  [4:0]     PL_EQ_ADAPT_ITER_COUNT=5'h2;
    localparam  [1:0]     PL_EQ_ADAPT_REJECT_RETRY_COUNT=2'h1;
    localparam            PL_EQ_SHORT_ADAPT_PHASE="FALSE";
    localparam  [1:0]     PL_EQ_ADAPT_DISABLE_COEFF_CHECK=2'b0;
    localparam  [1:0]     PL_EQ_ADAPT_DISABLE_PRESET_CHECK=2'b0;
    localparam  [7:0]     PL_EQ_DEFAULT_TX_PRESET=8'h44;
    localparam  [5:0]     PL_EQ_DEFAULT_RX_PRESET_HINT=6'h33;
    localparam  [1:0]     PL_EQ_RX_ADAPT_EQ_PHASE0=2'b00;
    localparam  [1:0]     PL_EQ_RX_ADAPT_EQ_PHASE1=2'b00;
    localparam            PL_EQ_DISABLE_MISMATCH_CHECK ="TRUE";
    localparam  [1:0]     PL_RX_L0S_EXIT_TO_RECOVERY=2'b00;
    localparam            PL_EQ_TX_8G_EQ_TS2_ENABLE="FALSE";
    localparam            PL_DISABLE_AUTO_EQ_SPEED_CHANGE_TO_GEN4="FALSE";
    localparam            PL_DISABLE_AUTO_EQ_SPEED_CHANGE_TO_GEN3="FALSE";
    localparam            PL_DISABLE_AUTO_SPEED_CHANGE_TO_GEN2="FALSE";
    localparam            PL_DESKEW_ON_SKIP_IN_GEN12="FALSE";
    localparam            PL_INFER_EI_DISABLE_REC_RC="FALSE";
    localparam            PL_INFER_EI_DISABLE_REC_SPD="FALSE";
    localparam            PL_INFER_EI_DISABLE_LPBK_ACTIVE="TRUE";
    localparam  [3:0]     PL_RX_ADAPT_TIMER_RRL_GEN3=4'h0;
    localparam  [1:0]     PL_RX_ADAPT_TIMER_RRL_CLOBBER_TX_TS=2'b00;
    localparam  [3:0]     PL_RX_ADAPT_TIMER_RRL_GEN4=4'h0;
    localparam  [3:0]     PL_RX_ADAPT_TIMER_CLWS_GEN3=4'h0;
    localparam  [1:0]     PL_RX_ADAPT_TIMER_CLWS_CLOBBER_TX_TS=2'b00;
    localparam  [3:0]     PL_RX_ADAPT_TIMER_CLWS_GEN4=4'h0;
    localparam            PL_DISABLE_LANE_REVERSAL="FALSE";
    localparam            PL_CFG_STATE_ROBUSTNESS_ENABLE="FALSE";
    localparam            PL_REDO_EQ_SOURCE_SELECT="TRUE";
    localparam            PL_EXIT_LOOPBACK_ON_EI_ENTRY="TRUE";
    localparam            PL_QUIESCE_GUARANTEE_DISABLE="FALSE";
    localparam            PL_SRIS_ENABLE="FALSE";
    localparam  [6:0]     PL_SRIS_SKPOS_GEN_SPD_VEC=7'h0;
    localparam  [6:0]     PL_SRIS_SKPOS_REC_SPD_VEC=7'h0;
    localparam            LL_ACK_TIMEOUT_EN="FALSE";
    localparam  [8:0]     LL_ACK_TIMEOUT=9'h0;
    localparam  integer   LL_ACK_TIMEOUT_FUNC=0;
    localparam            LL_REPLAY_TIMEOUT_EN="FALSE";
    localparam  [8:0]     LL_REPLAY_TIMEOUT=9'h0;
    localparam  integer   LL_REPLAY_TIMEOUT_FUNC=0;
    localparam            LL_REPLAY_TO_RAM_PIPELINE="FALSE";
    localparam            LL_REPLAY_FROM_RAM_PIPELINE="FALSE";
    localparam            LL_DISABLE_SCHED_TX_NAK="FALSE";
    localparam  [15:0]    LL_USER_SPARE=16'h0;
    localparam            IS_SWITCH_PORT="FALSE";
    localparam            CFG_BYPASS_MODE_ENABLE="FALSE";
    localparam  [1:0]     TL_PF_ENABLE_REG=2'h0;
    localparam  [11:0]    TL_CREDITS_CD=12'h1C0;
    localparam  [7:0]     TL_CREDITS_CH=8'h20;
    localparam  [1:0]     TL_COMPLETION_RAM_NUM_TLPS=2'b00;
    localparam  [11:0]    TL_CREDITS_NPD=12'h4;
    localparam  [7:0]     TL_CREDITS_NPH=8'h20;
    localparam  [11:0]    TL_CREDITS_PD=12'h3e0;
    localparam  [7:0]     TL_CREDITS_PH=8'h20;
    localparam            TL_RX_COMPLETION_TO_RAM_WRITE_PIPELINE="FALSE";
    localparam            TL_RX_COMPLETION_TO_RAM_READ_PIPELINE="FALSE";
    localparam            TL_RX_COMPLETION_FROM_RAM_READ_PIPELINE="FALSE";
    localparam            TL_POSTED_RAM_SIZE=1'b1;
    localparam            TL_RX_POSTED_TO_RAM_WRITE_PIPELINE="FALSE";
    localparam            TL_RX_POSTED_TO_RAM_READ_PIPELINE="FALSE";
    localparam            TL_RX_POSTED_FROM_RAM_READ_PIPELINE="FALSE";
    localparam            TL_TX_MUX_STRICT_PRIORITY="TRUE";
    localparam            TL_TX_TLP_STRADDLE_ENABLE="FALSE";
    localparam            TL_TX_TLP_TERMINATE_PARITY="FALSE";
    localparam  [4:0]     TL_FC_UPDATE_MIN_INTERVAL_TLP_COUNT=5'h8;
    localparam  [4:0]     TL_FC_UPDATE_MIN_INTERVAL_TIME=5'h2;
    localparam  [15:0]    TL_USER_SPARE=16'h0;
    localparam  [23:0]    PF0_CLASS_CODE=24'h000000;
    localparam  [23:0]    PF1_CLASS_CODE=24'h000000;
    localparam  [23:0]    PF2_CLASS_CODE=24'h000000;
    localparam  [23:0]    PF3_CLASS_CODE=24'h000000;
    localparam  [2:0]     PF0_INTERRUPT_PIN=3'h1;
    localparam  [2:0]     PF1_INTERRUPT_PIN=3'h1;
    localparam  [2:0]     PF2_INTERRUPT_PIN=3'h1;
    localparam  [2:0]     PF3_INTERRUPT_PIN=3'h1;
    localparam  [7:0]     PF0_CAPABILITY_POINTER=8'h80;
    localparam  [7:0]     PF1_CAPABILITY_POINTER=8'h80;
    localparam  [7:0]     PF2_CAPABILITY_POINTER=8'h80;
    localparam  [7:0]     PF3_CAPABILITY_POINTER=8'h80;
    localparam  [7:0]     VF0_CAPABILITY_POINTER=8'h80;
    localparam            LEGACY_CFG_EXTEND_INTERFACE_ENABLE="FALSE";
    localparam            EXTENDED_CFG_EXTEND_INTERFACE_ENABLE="FALSE";
    localparam            TL2CFG_IF_PARITY_CHK="FALSE";
    localparam            HEADER_TYPE_OVERRIDE="FALSE";
    localparam  [2:0]     PF0_BAR0_CONTROL=3'b100;
    localparam  [2:0]     PF1_BAR0_CONTROL=3'b100;
    localparam  [2:0]     PF2_BAR0_CONTROL=3'b100;
    localparam  [2:0]     PF3_BAR0_CONTROL=3'b100;
    localparam  [5:0]     PF0_BAR0_APERTURE_SIZE=6'b000100;
    localparam  [5:0]     PF1_BAR0_APERTURE_SIZE=6'b000011;
    localparam  [5:0]     PF2_BAR0_APERTURE_SIZE=6'b000011;
    localparam  [5:0]     PF3_BAR0_APERTURE_SIZE=6'b000011;
    localparam  [2:0]     PF0_BAR1_CONTROL=3'b0;
    localparam  [2:0]     PF1_BAR1_CONTROL=3'b0;
    localparam  [2:0]     PF2_BAR1_CONTROL=3'b0;
    localparam  [2:0]     PF3_BAR1_CONTROL=3'b0;
    localparam  [4:0]     PF0_BAR1_APERTURE_SIZE=5'b0;
    localparam  [4:0]     PF1_BAR1_APERTURE_SIZE=5'b0;
    localparam  [4:0]     PF2_BAR1_APERTURE_SIZE=5'b0;
    localparam  [4:0]     PF3_BAR1_APERTURE_SIZE=5'b0;
    localparam  [2:0]     PF0_BAR2_CONTROL=3'b100;
    localparam  [2:0]     PF1_BAR2_CONTROL=3'b100;
    localparam  [2:0]     PF2_BAR2_CONTROL=3'b100;
    localparam  [2:0]     PF3_BAR2_CONTROL=3'b100;
    localparam  [4:0]     PF0_BAR2_APERTURE_SIZE=6'b00011;
    localparam  [4:0]     PF1_BAR2_APERTURE_SIZE=6'b00011;
    localparam  [4:0]     PF2_BAR2_APERTURE_SIZE=6'b00011;
    localparam  [4:0]     PF3_BAR2_APERTURE_SIZE=6'b00011;
    localparam  [2:0]     PF0_BAR3_CONTROL=3'b0;
    localparam  [2:0]     PF1_BAR3_CONTROL=3'b0;
    localparam  [2:0]     PF2_BAR3_CONTROL=3'b0;
    localparam  [2:0]     PF3_BAR3_CONTROL=3'b0;
    localparam  [4:0]     PF0_BAR3_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF1_BAR3_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF2_BAR3_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF3_BAR3_APERTURE_SIZE=5'b00011;
    localparam  [2:0]     PF0_BAR4_CONTROL=3'b100;
    localparam  [2:0]     PF1_BAR4_CONTROL=3'b100;
    localparam  [2:0]     PF2_BAR4_CONTROL=3'b100;
    localparam  [2:0]     PF3_BAR4_CONTROL=3'b100;
    localparam  [4:0]     PF0_BAR4_APERTURE_SIZE=6'b00011;
    localparam  [4:0]     PF1_BAR4_APERTURE_SIZE=6'b00011;
    localparam  [4:0]     PF2_BAR4_APERTURE_SIZE=6'b00011;
    localparam  [4:0]     PF3_BAR4_APERTURE_SIZE=6'b00011;
    localparam  [2:0]     PF0_BAR5_CONTROL=3'b0;
    localparam  [2:0]     PF1_BAR5_CONTROL=3'b0;
    localparam  [2:0]     PF2_BAR5_CONTROL=3'b0;
    localparam  [2:0]     PF3_BAR5_CONTROL=3'b0;
    localparam  [4:0]     PF0_BAR5_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF1_BAR5_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF2_BAR5_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF3_BAR5_APERTURE_SIZE=5'b00011;
    localparam            PF0_EXPANSION_ROM_ENABLE="FALSE";
    localparam            PF1_EXPANSION_ROM_ENABLE="FALSE";
    localparam            PF2_EXPANSION_ROM_ENABLE="FALSE";
    localparam            PF3_EXPANSION_ROM_ENABLE="FALSE";
    localparam  [4:0]     PF0_EXPANSION_ROM_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF1_EXPANSION_ROM_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF2_EXPANSION_ROM_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF3_EXPANSION_ROM_APERTURE_SIZE=5'b00011;
    localparam  [7:0]     PF0_PCIE_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF1_PCIE_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF2_PCIE_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF3_PCIE_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     VFG0_PCIE_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     VFG1_PCIE_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     VFG2_PCIE_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     VFG3_PCIE_CAP_NEXTPTR=8'h0;
    localparam  [2:0]     PF0_DEV_CAP_MAX_PAYLOAD_SIZE=3'b011;
    localparam  [2:0]     PF1_DEV_CAP_MAX_PAYLOAD_SIZE=3'b011;
    localparam  [2:0]     PF2_DEV_CAP_MAX_PAYLOAD_SIZE=3'b011;
    localparam  [2:0]     PF3_DEV_CAP_MAX_PAYLOAD_SIZE=3'b011;
    localparam            PF0_DEV_CAP_EXT_TAG_SUPPORTED="TRUE";
    localparam  integer   PF0_DEV_CAP_ENDPOINT_L0S_LATENCY=0;
    localparam  integer   PF0_DEV_CAP_ENDPOINT_L1_LATENCY=0;
    localparam            PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE="TRUE";
    localparam  integer   PF0_LINK_CAP_ASPM_SUPPORT=0;
    localparam  [0:0]     PF0_LINK_CONTROL_RCB=1'b0;
    localparam            PF0_LINK_STATUS_SLOT_CLOCK_CONFIG="TRUE";
    localparam  integer   PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1=7;
    localparam  integer   PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2=7;
    localparam  integer   PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN3=7;
    localparam  integer   PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN4=7;
    localparam  integer   PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN1=7;
    localparam  integer   PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN2=7;
    localparam  integer   PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN3=7;
    localparam  integer   PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN4=7;
    localparam  integer   PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1=7;
    localparam  integer   PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2=7;
    localparam  integer   PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN3=7;
    localparam  integer   PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN4=7;
    localparam  integer   PF0_LINK_CAP_L1_EXIT_LATENCY_GEN1=7;
    localparam  integer   PF0_LINK_CAP_L1_EXIT_LATENCY_GEN2=7;
    localparam  integer   PF0_LINK_CAP_L1_EXIT_LATENCY_GEN3=7;
    localparam  integer   PF0_LINK_CAP_L1_EXIT_LATENCY_GEN4=7;
    localparam            PF0_DEV_CAP2_CPL_TIMEOUT_DISABLE="TRUE";
    localparam            PF0_DEV_CAP2_32B_ATOMIC_COMPLETER_SUPPORT="TRUE";
    localparam            PF0_DEV_CAP2_64B_ATOMIC_COMPLETER_SUPPORT="TRUE";
    localparam            PF0_DEV_CAP2_128B_CAS_ATOMIC_COMPLETER_SUPPORT="TRUE";
    localparam            PF0_DEV_CAP2_LTR_SUPPORT="FALSE";
    localparam            PF0_DEV_CAP2_TPH_COMPLETER_SUPPORT="FALSE";
    localparam  [1:0]     PF0_DEV_CAP2_OBFF_SUPPORT=2'b00;
    localparam            PF0_DEV_CAP2_ARI_FORWARD_ENABLE="FALSE";
    localparam  [7:0]     PF0_MSI_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF1_MSI_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF2_MSI_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF3_MSI_CAP_NEXTPTR=8'h0;
    localparam            PF0_MSI_CAP_PERVECMASKCAP="FALSE";
    localparam            PF1_MSI_CAP_PERVECMASKCAP="FALSE";
    localparam            PF2_MSI_CAP_PERVECMASKCAP="FALSE";
    localparam            PF3_MSI_CAP_PERVECMASKCAP="FALSE";
    localparam  integer   PF0_MSI_CAP_MULTIMSGCAP=0;
    localparam  integer   PF1_MSI_CAP_MULTIMSGCAP=0;
    localparam  integer   PF2_MSI_CAP_MULTIMSGCAP=0;
    localparam  integer   PF3_MSI_CAP_MULTIMSGCAP=0;
    localparam  [7:0]     PF0_MSIX_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF1_MSIX_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF2_MSIX_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF3_MSIX_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     VFG0_MSIX_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     VFG1_MSIX_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     VFG2_MSIX_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     VFG3_MSIX_CAP_NEXTPTR=8'h0;
    localparam  integer   PF0_MSIX_CAP_PBA_BIR=0;
    localparam  integer   PF1_MSIX_CAP_PBA_BIR=0;
    localparam  integer   PF2_MSIX_CAP_PBA_BIR=0;
    localparam  integer   PF3_MSIX_CAP_PBA_BIR=0;
    localparam  integer   VFG0_MSIX_CAP_PBA_BIR=0;
    localparam  integer   VFG1_MSIX_CAP_PBA_BIR=0;
    localparam  integer   VFG2_MSIX_CAP_PBA_BIR=0;
    localparam  integer   VFG3_MSIX_CAP_PBA_BIR=0;
    localparam  [28:0]    PF0_MSIX_CAP_PBA_OFFSET=29'h50;
    localparam  [28:0]    PF1_MSIX_CAP_PBA_OFFSET=29'h50;
    localparam  [28:0]    PF2_MSIX_CAP_PBA_OFFSET=29'h50;
    localparam  [28:0]    PF3_MSIX_CAP_PBA_OFFSET=29'h50;
    localparam  [28:0]    VFG0_MSIX_CAP_PBA_OFFSET=29'h50;
    localparam  [28:0]    VFG1_MSIX_CAP_PBA_OFFSET=29'h50;
    localparam  [28:0]    VFG2_MSIX_CAP_PBA_OFFSET=29'h50;
    localparam  [28:0]    VFG3_MSIX_CAP_PBA_OFFSET=29'h50;
    localparam  integer   PF0_MSIX_CAP_TABLE_BIR=0;
    localparam  integer   PF1_MSIX_CAP_TABLE_BIR=0;
    localparam  integer   PF2_MSIX_CAP_TABLE_BIR=0;
    localparam  integer   PF3_MSIX_CAP_TABLE_BIR=0;
    localparam  integer   VFG0_MSIX_CAP_TABLE_BIR=0;
    localparam  integer   VFG1_MSIX_CAP_TABLE_BIR=0;
    localparam  integer   VFG2_MSIX_CAP_TABLE_BIR=0;
    localparam  integer   VFG3_MSIX_CAP_TABLE_BIR=0;
    localparam  [28:0]    PF0_MSIX_CAP_TABLE_OFFSET=29'h40;
    localparam  [28:0]    PF1_MSIX_CAP_TABLE_OFFSET=29'h40;
    localparam  [28:0]    PF2_MSIX_CAP_TABLE_OFFSET=29'h40;
    localparam  [28:0]    PF3_MSIX_CAP_TABLE_OFFSET=29'h40;
    localparam  [28:0]    VFG0_MSIX_CAP_TABLE_OFFSET=29'h40;
    localparam  [28:0]    VFG1_MSIX_CAP_TABLE_OFFSET=29'h40;
    localparam  [28:0]    VFG2_MSIX_CAP_TABLE_OFFSET=29'h40;
    localparam  [28:0]    VFG3_MSIX_CAP_TABLE_OFFSET=29'h40;
    localparam  [10:0]    PF0_MSIX_CAP_TABLE_SIZE=11'h0;
    localparam  [10:0]    PF1_MSIX_CAP_TABLE_SIZE=11'h0;
    localparam  [10:0]    PF2_MSIX_CAP_TABLE_SIZE=11'h0;
    localparam  [10:0]    PF3_MSIX_CAP_TABLE_SIZE=11'h0;
    localparam  [10:0]    VFG0_MSIX_CAP_TABLE_SIZE=11'h0;
    localparam  [10:0]    VFG1_MSIX_CAP_TABLE_SIZE=11'h0;
    localparam  [10:0]    VFG2_MSIX_CAP_TABLE_SIZE=11'h0;
    localparam  [10:0]    VFG3_MSIX_CAP_TABLE_SIZE=11'h0;
    localparam  [5:0]     PF0_MSIX_VECTOR_COUNT=6'h4;
    localparam  [7:0]     PF0_PM_CAP_ID=8'h1;
    localparam  [7:0]     PF0_PM_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF1_PM_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF2_PM_CAP_NEXTPTR=8'h0;
    localparam  [7:0]     PF3_PM_CAP_NEXTPTR=8'h0;
    localparam            PF0_PM_CAP_PMESUPPORT_D3HOT="TRUE";
    localparam            PF0_PM_CAP_PMESUPPORT_D1="TRUE";
    localparam            PF0_PM_CAP_PMESUPPORT_D0="TRUE";
    localparam            PF0_PM_CAP_SUPP_D1_STATE="TRUE";
    localparam  [2:0]     PF0_PM_CAP_VER_ID=3'h3;
    localparam            PF0_PM_CSR_NOSOFTRESET="TRUE";
    localparam            PM_ENABLE_L23_ENTRY="FALSE";
    localparam  [7:0]     DNSTREAM_LINK_NUM=8'h0;
    localparam            AUTO_FLR_RESPONSE="FALSE";
    localparam  [11:0]    PF0_DSN_CAP_NEXTPTR=12'h10C;
    localparam  [11:0]    PF1_DSN_CAP_NEXTPTR=12'h10C;
    localparam  [11:0]    PF2_DSN_CAP_NEXTPTR=12'h10C;
    localparam  [11:0]    PF3_DSN_CAP_NEXTPTR=12'h10C;
    localparam            DSN_CAP_ENABLE="FALSE";
    localparam  [3:0]     PF0_VC_CAP_VER=4'h1;
    localparam  [11:0]    PF0_VC_CAP_NEXTPTR=12'h0;
    localparam            PF0_VC_CAP_ENABLE="FALSE";
    localparam  [11:0]    PF0_SECONDARY_PCIE_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF0_AER_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF1_AER_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF2_AER_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF3_AER_CAP_NEXTPTR=12'h0;
    localparam            PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE="FALSE";
    localparam            ARI_CAP_ENABLE="TRUE";
    localparam  [11:0]    PF0_ARI_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF1_ARI_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF2_ARI_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF3_ARI_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    VFG0_ARI_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    VFG1_ARI_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    VFG2_ARI_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    VFG3_ARI_CAP_NEXTPTR=12'h0;
    localparam  [3:0]     PF0_ARI_CAP_VER=4'h1;
    localparam  [7:0]     PF0_ARI_CAP_NEXT_FUNC=8'h0;
    localparam  [7:0]     PF1_ARI_CAP_NEXT_FUNC=8'h0;
    localparam  [7:0]     PF2_ARI_CAP_NEXT_FUNC=8'h0;
    localparam  [7:0]     PF3_ARI_CAP_NEXT_FUNC=8'h0;
    localparam  [11:0]    PF0_LTR_CAP_NEXTPTR=12'h0;
    localparam  [3:0]     PF0_LTR_CAP_VER=4'h1;
    localparam  [9:0]     PF0_LTR_CAP_MAX_SNOOP_LAT=10'h0;
    localparam  [9:0]     PF0_LTR_CAP_MAX_NOSNOOP_LAT=10'h0;
    localparam            LTR_TX_MESSAGE_ON_LTR_ENABLE="FALSE";
    localparam            LTR_TX_MESSAGE_ON_FUNC_POWER_STATE_CHANGE="FALSE";
    localparam  [9:0]     LTR_TX_MESSAGE_MINIMUM_INTERVAL=10'h250;
    localparam  [3:0]     SRIOV_CAP_ENABLE=4'h0;
    localparam  [11:0]    PF0_SRIOV_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF1_SRIOV_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF2_SRIOV_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF3_SRIOV_CAP_NEXTPTR=12'h0;
    localparam  [3:0]     PF0_SRIOV_CAP_VER=4'h1;
    localparam  [3:0]     PF1_SRIOV_CAP_VER=4'h1;
    localparam  [3:0]     PF2_SRIOV_CAP_VER=4'h1;
    localparam  [3:0]     PF3_SRIOV_CAP_VER=4'h1;
    localparam            PF0_SRIOV_ARI_CAPBL_HIER_PRESERVED="FALSE";
    localparam            PF1_SRIOV_ARI_CAPBL_HIER_PRESERVED="FALSE";
    localparam            PF2_SRIOV_ARI_CAPBL_HIER_PRESERVED="FALSE";
    localparam            PF3_SRIOV_ARI_CAPBL_HIER_PRESERVED="FALSE";
    localparam  [15:0]    PF0_SRIOV_CAP_INITIAL_VF=16'h0;
    localparam  [15:0]    PF1_SRIOV_CAP_INITIAL_VF=16'h0;
    localparam  [15:0]    PF2_SRIOV_CAP_INITIAL_VF=16'h0;
    localparam  [15:0]    PF3_SRIOV_CAP_INITIAL_VF=16'h0;
    localparam  [15:0]    PF0_SRIOV_CAP_TOTAL_VF=16'h0;
    localparam  [15:0]    PF1_SRIOV_CAP_TOTAL_VF=16'h0;
    localparam  [15:0]    PF2_SRIOV_CAP_TOTAL_VF=16'h0;
    localparam  [15:0]    PF3_SRIOV_CAP_TOTAL_VF=16'h0;
    localparam  [15:0]    PF0_SRIOV_FUNC_DEP_LINK=16'h0;
    localparam  [15:0]    PF1_SRIOV_FUNC_DEP_LINK=16'h0;
    localparam  [15:0]    PF2_SRIOV_FUNC_DEP_LINK=16'h0;
    localparam  [15:0]    PF3_SRIOV_FUNC_DEP_LINK=16'h0;
    localparam  [15:0]    PF0_SRIOV_FIRST_VF_OFFSET=16'h0;
    localparam  [15:0]    PF1_SRIOV_FIRST_VF_OFFSET=16'h0;
    localparam  [15:0]    PF2_SRIOV_FIRST_VF_OFFSET=16'h0;
    localparam  [15:0]    PF3_SRIOV_FIRST_VF_OFFSET=16'h0;
    localparam  [15:0]    PF0_SRIOV_VF_DEVICE_ID=16'h0;
    localparam  [15:0]    PF1_SRIOV_VF_DEVICE_ID=16'h0;
    localparam  [15:0]    PF2_SRIOV_VF_DEVICE_ID=16'h0;
    localparam  [15:0]    PF3_SRIOV_VF_DEVICE_ID=16'h0;
    localparam  [31:0]    PF0_SRIOV_SUPPORTED_PAGE_SIZE=32'h0;
    localparam  [31:0]    PF1_SRIOV_SUPPORTED_PAGE_SIZE=32'h0;
    localparam  [31:0]    PF2_SRIOV_SUPPORTED_PAGE_SIZE=32'h0;
    localparam  [31:0]    PF3_SRIOV_SUPPORTED_PAGE_SIZE=32'h0;
    localparam  [2:0]     PF0_SRIOV_BAR0_CONTROL=3'b100;
    localparam  [2:0]     PF1_SRIOV_BAR0_CONTROL=3'b100;
    localparam  [2:0]     PF2_SRIOV_BAR0_CONTROL=3'b100;
    localparam  [2:0]     PF3_SRIOV_BAR0_CONTROL=3'b100;
    localparam  [4:0]     PF0_SRIOV_BAR0_APERTURE_SIZE=6'b000011;
    localparam  [4:0]     PF1_SRIOV_BAR0_APERTURE_SIZE=6'b000011;
    localparam  [4:0]     PF2_SRIOV_BAR0_APERTURE_SIZE=6'b000011;
    localparam  [4:0]     PF3_SRIOV_BAR0_APERTURE_SIZE=6'b000011;
    localparam  [2:0]     PF0_SRIOV_BAR1_CONTROL=3'b0;
    localparam  [2:0]     PF1_SRIOV_BAR1_CONTROL=3'b0;
    localparam  [2:0]     PF2_SRIOV_BAR1_CONTROL=3'b0;
    localparam  [2:0]     PF3_SRIOV_BAR1_CONTROL=3'b0;
    localparam  [4:0]     PF0_SRIOV_BAR1_APERTURE_SIZE=5'b0;
    localparam  [4:0]     PF1_SRIOV_BAR1_APERTURE_SIZE=5'b0;
    localparam  [4:0]     PF2_SRIOV_BAR1_APERTURE_SIZE=5'b0;
    localparam  [4:0]     PF3_SRIOV_BAR1_APERTURE_SIZE=5'b0;
    localparam  [2:0]     PF0_SRIOV_BAR2_CONTROL=3'b100;
    localparam  [2:0]     PF1_SRIOV_BAR2_CONTROL=3'b100;
    localparam  [2:0]     PF2_SRIOV_BAR2_CONTROL=3'b100;
    localparam  [2:0]     PF3_SRIOV_BAR2_CONTROL=3'b100;
    localparam  [4:0]     PF0_SRIOV_BAR2_APERTURE_SIZE=6'b000011;
    localparam  [4:0]     PF1_SRIOV_BAR2_APERTURE_SIZE=6'b000011;
    localparam  [4:0]     PF2_SRIOV_BAR2_APERTURE_SIZE=6'b000011;
    localparam  [4:0]     PF3_SRIOV_BAR2_APERTURE_SIZE=6'b000011;
    localparam  [2:0]     PF0_SRIOV_BAR3_CONTROL=3'b0;
    localparam  [2:0]     PF1_SRIOV_BAR3_CONTROL=3'b0;
    localparam  [2:0]     PF2_SRIOV_BAR3_CONTROL=3'b0;
    localparam  [2:0]     PF3_SRIOV_BAR3_CONTROL=3'b0;
    localparam  [4:0]     PF0_SRIOV_BAR3_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF1_SRIOV_BAR3_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF2_SRIOV_BAR3_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF3_SRIOV_BAR3_APERTURE_SIZE=5'b00011;
    localparam  [2:0]     PF0_SRIOV_BAR4_CONTROL=3'b100;
    localparam  [2:0]     PF1_SRIOV_BAR4_CONTROL=3'b100;
    localparam  [2:0]     PF2_SRIOV_BAR4_CONTROL=3'b100;
    localparam  [2:0]     PF3_SRIOV_BAR4_CONTROL=3'b100;
    localparam  [4:0]     PF0_SRIOV_BAR4_APERTURE_SIZE=6'b000011;
    localparam  [4:0]     PF1_SRIOV_BAR4_APERTURE_SIZE=6'b000011;
    localparam  [4:0]     PF2_SRIOV_BAR4_APERTURE_SIZE=6'b000011;
    localparam  [4:0]     PF3_SRIOV_BAR4_APERTURE_SIZE=6'b000011;
    localparam  [2:0]     PF0_SRIOV_BAR5_CONTROL=3'b0;
    localparam  [2:0]     PF1_SRIOV_BAR5_CONTROL=3'b0;
    localparam  [2:0]     PF2_SRIOV_BAR5_CONTROL=3'b0;
    localparam  [2:0]     PF3_SRIOV_BAR5_CONTROL=3'b0;
    localparam  [4:0]     PF0_SRIOV_BAR5_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF1_SRIOV_BAR5_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF2_SRIOV_BAR5_APERTURE_SIZE=5'b00011;
    localparam  [4:0]     PF3_SRIOV_BAR5_APERTURE_SIZE=5'b00011;
    localparam  [11:0]    PF0_TPHR_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF1_TPHR_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF2_TPHR_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    PF3_TPHR_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    VFG0_TPHR_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    VFG1_TPHR_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    VFG2_TPHR_CAP_NEXTPTR=12'h0;
    localparam  [11:0]    VFG3_TPHR_CAP_NEXTPTR=12'h0;
    localparam  [3:0]     PF0_TPHR_CAP_VER=4'h1;
    localparam            PF0_TPHR_CAP_INT_VEC_MODE="TRUE";
    localparam            PF0_TPHR_CAP_DEV_SPECIFIC_MODE="TRUE";
    localparam  [1:0]     PF0_TPHR_CAP_ST_TABLE_LOC=2'h0;
    localparam  [10:0]    PF0_TPHR_CAP_ST_TABLE_SIZE=11'h0;
    localparam  [2:0]     PF0_TPHR_CAP_ST_MODE_SEL=3'h0;
    localparam  [2:0]     PF1_TPHR_CAP_ST_MODE_SEL=3'h0;
    localparam  [2:0]     PF2_TPHR_CAP_ST_MODE_SEL=3'h0;
    localparam  [2:0]     PF3_TPHR_CAP_ST_MODE_SEL=3'h0;
    localparam  [2:0]     VFG0_TPHR_CAP_ST_MODE_SEL=3'h0;
    localparam  [2:0]     VFG1_TPHR_CAP_ST_MODE_SEL=3'h0;
    localparam  [2:0]     VFG2_TPHR_CAP_ST_MODE_SEL=3'h0;
    localparam  [2:0]     VFG3_TPHR_CAP_ST_MODE_SEL=3'h0;
    localparam            PF0_TPHR_CAP_ENABLE="FALSE";
    localparam            TPH_TO_RAM_PIPELINE="FALSE";
    localparam            TPH_FROM_RAM_PIPELINE="FALSE";
    localparam            MCAP_ENABLE="FALSE";
    localparam            MCAP_CONFIGURE_OVERRIDE="FALSE";
    localparam  [11:0]    MCAP_CAP_NEXTPTR=12'h0;
    localparam  [15:0]    MCAP_VSEC_ID=16'h0;
    localparam  [3:0]     MCAP_VSEC_REV=4'h0;
    localparam  [11:0]    MCAP_VSEC_LEN=12'h2C;
    localparam  [31:0]    MCAP_FPGA_BITSTREAM_VERSION=32'h0;
    localparam            MCAP_INTERRUPT_ON_MCAP_EOS="FALSE";
    localparam            MCAP_INTERRUPT_ON_MCAP_ERROR="FALSE";
    localparam            MCAP_INPUT_GATE_DESIGN_SWITCH="FALSE";
    localparam            MCAP_EOS_DESIGN_SWITCH="FALSE";
    localparam            MCAP_GATE_MEM_ENABLE_DESIGN_SWITCH="FALSE";
    localparam            MCAP_GATE_IO_ENABLE_DESIGN_SWITCH="FALSE";
    localparam  [31:0]    SIM_JTAG_IDCODE=32'h0;
    localparam  [7:0]     DEBUG_AXIST_DISABLE_FEATURE_BIT=8'h0;
    localparam            DEBUG_TL_DISABLE_RX_TLP_ORDER_CHECKS="FALSE";
    localparam            DEBUG_TL_DISABLE_FC_TIMEOUT="FALSE";
    localparam            DEBUG_PL_DISABLE_SCRAMBLING="FALSE";
    localparam            DEBUG_PL_DISABLE_REC_ENTRY_ON_DYNAMIC_DSKEW_FAIL ="FALSE";
    localparam            DEBUG_PL_DISABLE_REC_ENTRY_ON_RX_BUFFER_UNDER_OVER_FLOW ="FALSE";
    localparam            DEBUG_PL_DISABLE_LES_UPDATE_ON_SKP_ERROR="FALSE";
    localparam            DEBUG_PL_DISABLE_LES_UPDATE_ON_SKP_PARITY_ERROR="FALSE";
    localparam            DEBUG_PL_DISABLE_LES_UPDATE_ON_DEFRAMER_ERROR="FALSE";
    localparam            DEBUG_PL_SIM_RESET_LFSR="FALSE";
    localparam  [15:0]    DEBUG_PL_SPARE=16'h0;
    localparam  [15:0]    DEBUG_LL_SPARE=16'h0;
    localparam  [15:0]    DEBUG_TL_SPARE=16'h0;
    localparam  [15:0]    DEBUG_AXI4ST_SPARE=16'h0;
    localparam  [15:0]    DEBUG_CFG_SPARE=16'h0;
    localparam  [3:0]     DEBUG_CAR_SPARE=4'h0;
    localparam            TEST_MODE_PIN_CHAR="FALSE";
    localparam            SPARE_BIT0=1'b0;
    localparam            SPARE_BIT1=1'b0;
    localparam            SPARE_BIT2=1'b0;
    localparam            SPARE_BIT3="FALSE";
    localparam            SPARE_BIT4=1'b0;
    localparam            SPARE_BIT5=1'b0;
    localparam            SPARE_BIT6=1'b0;
    localparam            SPARE_BIT7=1'b0;
    localparam            SPARE_BIT8=1'b0;
    localparam  [7:0]     SPARE_BYTE0=8'h0;
    localparam  [7:0]     SPARE_BYTE1=8'h0;
    localparam  [7:0]     SPARE_BYTE2=8'h0;
    localparam  [7:0]     SPARE_BYTE3=8'h0;
    localparam  [31:0]    SPARE_WORD0=32'h0;
    localparam  [31:0]    SPARE_WORD1=32'h0;
    localparam  [31:0]    SPARE_WORD2=32'h0;
    localparam  [31:0]    SPARE_WORD3=32'h0;


xp4_usp_smsw_model_core_top #(

    .TCQ(TCQ)
   ,.IMPL_TARGET(IMPL_TARGET)
   ,.AXISTEN_IF_EXT_512_INTFC_RAM_STYLE(AXISTEN_IF_EXT_512_INTFC_RAM_STYLE)
   ,.FPGA_FAMILY(FPGA_FAMILY)
   ,.FPGA_XCVR(FPGA_XCVR)  
   ,.PL_EQ_BYPASS_PHASE23(PL_EQ_BYPASS_PHASE23)
   ,.AXISTEN_IF_EXT_512(AXISTEN_IF_EXT_512)
   ,.PL_SIM_FAST_LINK_TRAINING(PL_SIM_FAST_LINK_TRAINING)
   ,.PL_DEEMPH_SOURCE_SELECT(PL_DEEMPH_SOURCE_SELECT)
   ,.PL_UPSTREAM_FACING(PL_UPSTREAM_FACING)
   ,.PL_LINK_CAP_MAX_LINK_WIDTH(PL_LINK_CAP_MAX_LINK_WIDTH)
   ,.PL_LINK_CAP_MAX_LINK_SPEED(PL_LINK_CAP_MAX_LINK_SPEED)
   ,.PHY_REFCLK_FREQ(PHY_REFCLK_FREQ)
   ,.CRM_CORE_CLK_FREQ_500(CRM_CORE_CLK_FREQ == 2 ? "TRUE" : "FALSE")
   ,.CRM_USER_CLK_FREQ(CRM_USER_CLK_FREQ)
   ,.CRM_MCAP_CLK_FREQ(CRM_MCAP_CLK_FREQ)
   ,.AXISTEN_IF_WIDTH(AXISTEN_IF_WIDTH)
   ,.AXI4_DATA_WIDTH(AXI4_DATA_WIDTH)
   ,.AXI4_TKEEP_WIDTH(AXI4_TKEEP_WIDTH)
   ,.AXI4_CQ_TUSER_WIDTH(AXI4_CQ_TUSER_WIDTH)
   ,.AXI4_CC_TUSER_WIDTH(AXI4_CC_TUSER_WIDTH)
   ,.AXI4_RQ_TUSER_WIDTH(AXI4_RQ_TUSER_WIDTH)
   ,.AXI4_RC_TUSER_WIDTH(AXI4_RC_TUSER_WIDTH)
   ,.AXI4_CQ_TREADY_WIDTH(AXI4_CQ_TREADY_WIDTH)
   ,.AXI4_CC_TREADY_WIDTH(AXI4_CC_TREADY_WIDTH)
   ,.AXI4_RQ_TREADY_WIDTH(AXI4_RQ_TREADY_WIDTH)
   ,.AXI4_RC_TREADY_WIDTH(AXI4_RC_TREADY_WIDTH)

   ,.AXISTEN_IF_EXT_512_CQ_STRADDLE(AXISTEN_IF_EXT_512_CQ_STRADDLE)
   ,.AXISTEN_IF_EXT_512_CC_STRADDLE(AXISTEN_IF_EXT_512_CC_STRADDLE)
   ,.AXISTEN_IF_EXT_512_RQ_STRADDLE(AXISTEN_IF_EXT_512_RQ_STRADDLE)
   ,.AXISTEN_IF_EXT_512_RC_STRADDLE(AXISTEN_IF_EXT_512_RC_STRADDLE)
   ,.AXISTEN_IF_CQ_ALIGNMENT_MODE(AXISTEN_IF_CQ_ALIGNMENT_MODE)
   ,.AXISTEN_IF_CC_ALIGNMENT_MODE(AXISTEN_IF_CC_ALIGNMENT_MODE)
   ,.AXISTEN_IF_RQ_ALIGNMENT_MODE(AXISTEN_IF_RQ_ALIGNMENT_MODE)
   ,.AXISTEN_IF_RC_ALIGNMENT_MODE(AXISTEN_IF_RC_ALIGNMENT_MODE)
   ,.AXISTEN_IF_RC_STRADDLE(AXISTEN_IF_RC_STRADDLE)
   ,.AXISTEN_IF_ENABLE_RX_MSG_INTFC(AXISTEN_IF_ENABLE_RX_MSG_INTFC)
   ,.AXISTEN_IF_ENABLE_MSG_ROUTE(AXISTEN_IF_ENABLE_MSG_ROUTE)
   ,.AXISTEN_IF_RX_PARITY_EN(AXISTEN_IF_RX_PARITY_EN)
   ,.AXISTEN_IF_TX_PARITY_EN(AXISTEN_IF_TX_PARITY_EN)
   ,.AXISTEN_IF_ENABLE_CLIENT_TAG(AXISTEN_IF_ENABLE_CLIENT_TAG)
   ,.AXISTEN_IF_ENABLE_256_TAGS(AXISTEN_IF_ENABLE_256_TAGS)
   ,.AXISTEN_IF_COMPL_TIMEOUT_REG0(AXISTEN_IF_COMPL_TIMEOUT_REG0)
   ,.AXISTEN_IF_COMPL_TIMEOUT_REG1(AXISTEN_IF_COMPL_TIMEOUT_REG1)
   ,.AXISTEN_IF_LEGACY_MODE_ENABLE(AXISTEN_IF_LEGACY_MODE_ENABLE)
   ,.AXISTEN_IF_ENABLE_MESSAGE_RID_CHECK(AXISTEN_IF_ENABLE_MESSAGE_RID_CHECK)
   ,.AXISTEN_IF_MSIX_TO_RAM_PIPELINE(AXISTEN_IF_MSIX_TO_RAM_PIPELINE)
   ,.AXISTEN_IF_MSIX_FROM_RAM_PIPELINE(AXISTEN_IF_MSIX_FROM_RAM_PIPELINE)
   ,.AXISTEN_IF_MSIX_RX_PARITY_EN(AXISTEN_IF_MSIX_RX_PARITY_EN)
   ,.AXISTEN_IF_ENABLE_INTERNAL_MSIX_TABLE(AXISTEN_IF_ENABLE_INTERNAL_MSIX_TABLE)
   ,.AXISTEN_IF_SIM_SHORT_CPL_TIMEOUT(AXISTEN_IF_SIM_SHORT_CPL_TIMEOUT)
   ,.AXISTEN_IF_CQ_EN_POISONED_MEM_WR(AXISTEN_IF_CQ_EN_POISONED_MEM_WR)
   ,.AXISTEN_IF_RQ_CC_REGISTERED_TREADY(AXISTEN_IF_RQ_CC_REGISTERED_TREADY)
   ,.PM_ASPML0S_TIMEOUT(PM_ASPML0S_TIMEOUT)
   ,.PM_L1_REENTRY_DELAY(PM_L1_REENTRY_DELAY)
   ,.PM_ASPML1_ENTRY_DELAY(PM_ASPML1_ENTRY_DELAY)
   ,.PM_ENABLE_SLOT_POWER_CAPTURE(PM_ENABLE_SLOT_POWER_CAPTURE)
   ,.PM_PME_SERVICE_TIMEOUT_DELAY(PM_PME_SERVICE_TIMEOUT_DELAY)
   ,.PM_PME_TURNOFF_ACK_DELAY(PM_PME_TURNOFF_ACK_DELAY)
   ,.PL_DISABLE_DC_BALANCE(PL_DISABLE_DC_BALANCE)
   ,.PL_DISABLE_EI_INFER_IN_L0(PL_DISABLE_EI_INFER_IN_L0)
   ,.PL_N_FTS(PL_N_FTS)
   ,.PL_DISABLE_UPCONFIG_CAPABLE(PL_DISABLE_UPCONFIG_CAPABLE)
   ,.PL_DISABLE_RETRAIN_ON_FRAMING_ERROR(PL_DISABLE_RETRAIN_ON_FRAMING_ERROR)
   ,.PL_DISABLE_RETRAIN_ON_EB_ERROR(PL_DISABLE_RETRAIN_ON_EB_ERROR)
   ,.PL_DISABLE_RETRAIN_ON_SPECIFIC_FRAMING_ERROR(PL_DISABLE_RETRAIN_ON_SPECIFIC_FRAMING_ERROR)
   ,.PL_REPORT_ALL_PHY_ERRORS(PL_REPORT_ALL_PHY_ERRORS)
   ,.PL_DISABLE_LFSR_UPDATE_ON_SKP(PL_DISABLE_LFSR_UPDATE_ON_SKP)
   ,.PL_LANE0_EQ_CONTROL(PL_LANE0_EQ_CONTROL)
   ,.PL_LANE1_EQ_CONTROL(PL_LANE1_EQ_CONTROL)
   ,.PL_LANE2_EQ_CONTROL(PL_LANE2_EQ_CONTROL)
   ,.PL_LANE3_EQ_CONTROL(PL_LANE3_EQ_CONTROL)
   ,.PL_LANE4_EQ_CONTROL(PL_LANE4_EQ_CONTROL)
   ,.PL_LANE5_EQ_CONTROL(PL_LANE5_EQ_CONTROL)
   ,.PL_LANE6_EQ_CONTROL(PL_LANE6_EQ_CONTROL)
   ,.PL_LANE7_EQ_CONTROL(PL_LANE7_EQ_CONTROL)
   ,.PL_LANE8_EQ_CONTROL(PL_LANE8_EQ_CONTROL)
   ,.PL_LANE9_EQ_CONTROL(PL_LANE9_EQ_CONTROL)
   ,.PL_LANE10_EQ_CONTROL(PL_LANE10_EQ_CONTROL)
   ,.PL_LANE11_EQ_CONTROL(PL_LANE11_EQ_CONTROL)
   ,.PL_LANE12_EQ_CONTROL(PL_LANE12_EQ_CONTROL)
   ,.PL_LANE13_EQ_CONTROL(PL_LANE13_EQ_CONTROL)
   ,.PL_LANE14_EQ_CONTROL(PL_LANE14_EQ_CONTROL)
   ,.PL_LANE15_EQ_CONTROL(PL_LANE15_EQ_CONTROL)
   ,.PL_EQ_ADAPT_ITER_COUNT(PL_EQ_ADAPT_ITER_COUNT)
   ,.PL_EQ_ADAPT_REJECT_RETRY_COUNT(PL_EQ_ADAPT_REJECT_RETRY_COUNT)
   ,.PL_EQ_SHORT_ADAPT_PHASE(PL_EQ_SHORT_ADAPT_PHASE)
   ,.PL_EQ_ADAPT_DISABLE_COEFF_CHECK(PL_EQ_ADAPT_DISABLE_COEFF_CHECK)
   ,.PL_EQ_ADAPT_DISABLE_PRESET_CHECK(PL_EQ_ADAPT_DISABLE_PRESET_CHECK)
   ,.PL_EQ_DEFAULT_TX_PRESET(PL_EQ_DEFAULT_TX_PRESET)
   ,.PL_EQ_DEFAULT_RX_PRESET_HINT(PL_EQ_DEFAULT_RX_PRESET_HINT)
   ,.PL_EQ_RX_ADAPT_EQ_PHASE0(PL_EQ_RX_ADAPT_EQ_PHASE0)
   ,.PL_EQ_RX_ADAPT_EQ_PHASE1(PL_EQ_RX_ADAPT_EQ_PHASE1)
   ,.PL_EQ_DISABLE_MISMATCH_CHECK(PL_EQ_DISABLE_MISMATCH_CHECK)
   ,.PL_RX_L0S_EXIT_TO_RECOVERY(PL_RX_L0S_EXIT_TO_RECOVERY)
   ,.PL_EQ_TX_8G_EQ_TS2_ENABLE(PL_EQ_TX_8G_EQ_TS2_ENABLE)
   ,.PL_DISABLE_AUTO_EQ_SPEED_CHANGE_TO_GEN4(PL_DISABLE_AUTO_EQ_SPEED_CHANGE_TO_GEN4)
   ,.PL_DISABLE_AUTO_EQ_SPEED_CHANGE_TO_GEN3(PL_DISABLE_AUTO_EQ_SPEED_CHANGE_TO_GEN3)
   ,.PL_DISABLE_AUTO_SPEED_CHANGE_TO_GEN2(PL_DISABLE_AUTO_SPEED_CHANGE_TO_GEN2)
   ,.PL_DESKEW_ON_SKIP_IN_GEN12(PL_DESKEW_ON_SKIP_IN_GEN12)
   ,.PL_INFER_EI_DISABLE_REC_RC(PL_INFER_EI_DISABLE_REC_RC)
   ,.PL_INFER_EI_DISABLE_REC_SPD(PL_INFER_EI_DISABLE_REC_SPD)
   ,.PL_INFER_EI_DISABLE_LPBK_ACTIVE(PL_INFER_EI_DISABLE_LPBK_ACTIVE)
   ,.PL_RX_ADAPT_TIMER_RRL_GEN3(PL_RX_ADAPT_TIMER_RRL_GEN3)
   ,.PL_RX_ADAPT_TIMER_RRL_CLOBBER_TX_TS(PL_RX_ADAPT_TIMER_RRL_CLOBBER_TX_TS)
   ,.PL_RX_ADAPT_TIMER_RRL_GEN4(PL_RX_ADAPT_TIMER_RRL_GEN4)
   ,.PL_RX_ADAPT_TIMER_CLWS_GEN3(PL_RX_ADAPT_TIMER_CLWS_GEN3)
   ,.PL_RX_ADAPT_TIMER_CLWS_CLOBBER_TX_TS(PL_RX_ADAPT_TIMER_CLWS_CLOBBER_TX_TS)
   ,.PL_RX_ADAPT_TIMER_CLWS_GEN4(PL_RX_ADAPT_TIMER_CLWS_GEN4)
   ,.PL_DISABLE_LANE_REVERSAL(PL_DISABLE_LANE_REVERSAL)
   ,.PL_CFG_STATE_ROBUSTNESS_ENABLE(PL_CFG_STATE_ROBUSTNESS_ENABLE)
   ,.PL_REDO_EQ_SOURCE_SELECT(PL_REDO_EQ_SOURCE_SELECT)
   ,.PL_EXIT_LOOPBACK_ON_EI_ENTRY(PL_EXIT_LOOPBACK_ON_EI_ENTRY)
   ,.PL_QUIESCE_GUARANTEE_DISABLE(PL_QUIESCE_GUARANTEE_DISABLE)
   ,.PL_SRIS_ENABLE(PL_SRIS_ENABLE)
   ,.PL_SRIS_SKPOS_GEN_SPD_VEC(PL_SRIS_SKPOS_GEN_SPD_VEC)
   ,.PL_SRIS_SKPOS_REC_SPD_VEC(PL_SRIS_SKPOS_REC_SPD_VEC)
   ,.PL_USER_SPARE(PL_USER_SPARE)
   ,.LL_ACK_TIMEOUT_EN(LL_ACK_TIMEOUT_EN)
   ,.LL_ACK_TIMEOUT(LL_ACK_TIMEOUT)
   ,.LL_ACK_TIMEOUT_FUNC(LL_ACK_TIMEOUT_FUNC)
   ,.LL_REPLAY_TIMEOUT_EN(LL_REPLAY_TIMEOUT_EN)
   ,.LL_REPLAY_TIMEOUT(LL_REPLAY_TIMEOUT)
   ,.LL_REPLAY_TIMEOUT_FUNC(LL_REPLAY_TIMEOUT_FUNC)
   ,.LL_REPLAY_TO_RAM_PIPELINE(LL_REPLAY_TO_RAM_PIPELINE)
   ,.LL_REPLAY_FROM_RAM_PIPELINE(LL_REPLAY_FROM_RAM_PIPELINE)
   ,.LL_DISABLE_SCHED_TX_NAK(LL_DISABLE_SCHED_TX_NAK)
   ,.LL_TX_TLP_PARITY_CHK(LL_TX_TLP_PARITY_CHK)
   ,.LL_RX_TLP_PARITY_GEN(LL_RX_TLP_PARITY_GEN)
   ,.LL_USER_SPARE(LL_USER_SPARE)
   ,.IS_SWITCH_PORT(IS_SWITCH_PORT)
   ,.CFG_BYPASS_MODE_ENABLE(CFG_BYPASS_MODE_ENABLE)
   ,.TL_PF_ENABLE_REG(TL_PF_ENABLE_REG)
   ,.TL_CREDITS_CD(TL_CREDITS_CD)
   ,.TL_CREDITS_CH(TL_CREDITS_CH)
   ,.TL_COMPLETION_RAM_SIZE(TL_COMPLETION_RAM_SIZE)
   ,.TL_COMPLETION_RAM_NUM_TLPS(TL_COMPLETION_RAM_NUM_TLPS)
   ,.TL_CREDITS_NPD(TL_CREDITS_NPD)
   ,.TL_CREDITS_NPH(TL_CREDITS_NPH)
   ,.TL_CREDITS_PD(TL_CREDITS_PD)
   ,.TL_CREDITS_PH(TL_CREDITS_PH)
   ,.TL_RX_COMPLETION_TO_RAM_WRITE_PIPELINE(TL_RX_COMPLETION_TO_RAM_WRITE_PIPELINE)
   ,.TL_RX_COMPLETION_TO_RAM_READ_PIPELINE(TL_RX_COMPLETION_TO_RAM_READ_PIPELINE)
   ,.TL_RX_COMPLETION_FROM_RAM_READ_PIPELINE(TL_RX_COMPLETION_FROM_RAM_READ_PIPELINE)
   ,.TL_POSTED_RAM_SIZE(TL_POSTED_RAM_SIZE)
   ,.TL_RX_POSTED_TO_RAM_WRITE_PIPELINE(TL_RX_POSTED_TO_RAM_WRITE_PIPELINE)
   ,.TL_RX_POSTED_TO_RAM_READ_PIPELINE(TL_RX_POSTED_TO_RAM_READ_PIPELINE)
   ,.TL_RX_POSTED_FROM_RAM_READ_PIPELINE(TL_RX_POSTED_FROM_RAM_READ_PIPELINE)
   ,.TL_TX_MUX_STRICT_PRIORITY(TL_TX_MUX_STRICT_PRIORITY)
   ,.TL_TX_TLP_STRADDLE_ENABLE(TL_TX_TLP_STRADDLE_ENABLE)
   ,.TL_TX_TLP_TERMINATE_PARITY(TL_TX_TLP_TERMINATE_PARITY)
   ,.TL_FC_UPDATE_MIN_INTERVAL_TLP_COUNT(TL_FC_UPDATE_MIN_INTERVAL_TLP_COUNT)
   ,.TL_FC_UPDATE_MIN_INTERVAL_TIME(TL_FC_UPDATE_MIN_INTERVAL_TIME)
   ,.TL_USER_SPARE(TL_USER_SPARE)
   ,.PF0_CLASS_CODE(PF0_CLASS_CODE)
   ,.PF1_CLASS_CODE(PF1_CLASS_CODE)
   ,.PF2_CLASS_CODE(PF2_CLASS_CODE)
   ,.PF3_CLASS_CODE(PF3_CLASS_CODE)
   ,.PF0_INTERRUPT_PIN(PF0_INTERRUPT_PIN)
   ,.PF1_INTERRUPT_PIN(PF1_INTERRUPT_PIN)
   ,.PF2_INTERRUPT_PIN(PF2_INTERRUPT_PIN)
   ,.PF3_INTERRUPT_PIN(PF3_INTERRUPT_PIN)
   ,.PF0_CAPABILITY_POINTER(PF0_CAPABILITY_POINTER)
   ,.PF1_CAPABILITY_POINTER(PF1_CAPABILITY_POINTER)
   ,.PF2_CAPABILITY_POINTER(PF2_CAPABILITY_POINTER)
   ,.PF3_CAPABILITY_POINTER(PF3_CAPABILITY_POINTER)
   ,.VF0_CAPABILITY_POINTER(VF0_CAPABILITY_POINTER)
   ,.LEGACY_CFG_EXTEND_INTERFACE_ENABLE(LEGACY_CFG_EXTEND_INTERFACE_ENABLE)
   ,.EXTENDED_CFG_EXTEND_INTERFACE_ENABLE(EXTENDED_CFG_EXTEND_INTERFACE_ENABLE)
   ,.TL2CFG_IF_PARITY_CHK(TL2CFG_IF_PARITY_CHK)
   ,.HEADER_TYPE_OVERRIDE(HEADER_TYPE_OVERRIDE)
   ,.PF0_BAR0_CONTROL(PF0_BAR0_CONTROL)
   ,.PF1_BAR0_CONTROL(PF1_BAR0_CONTROL)
   ,.PF2_BAR0_CONTROL(PF2_BAR0_CONTROL)
   ,.PF3_BAR0_CONTROL(PF3_BAR0_CONTROL)
   ,.PF0_BAR0_APERTURE_SIZE(PF0_BAR0_APERTURE_SIZE)
   ,.PF1_BAR0_APERTURE_SIZE(PF1_BAR0_APERTURE_SIZE)
   ,.PF2_BAR0_APERTURE_SIZE(PF2_BAR0_APERTURE_SIZE)
   ,.PF3_BAR0_APERTURE_SIZE(PF3_BAR0_APERTURE_SIZE)
   ,.PF0_BAR1_CONTROL(PF0_BAR1_CONTROL)
   ,.PF1_BAR1_CONTROL(PF1_BAR1_CONTROL)
   ,.PF2_BAR1_CONTROL(PF2_BAR1_CONTROL)
   ,.PF3_BAR1_CONTROL(PF3_BAR1_CONTROL)
   ,.PF0_BAR1_APERTURE_SIZE(PF0_BAR1_APERTURE_SIZE)
   ,.PF1_BAR1_APERTURE_SIZE(PF1_BAR1_APERTURE_SIZE)
   ,.PF2_BAR1_APERTURE_SIZE(PF2_BAR1_APERTURE_SIZE)
   ,.PF3_BAR1_APERTURE_SIZE(PF3_BAR1_APERTURE_SIZE)
   ,.PF0_BAR2_CONTROL(PF0_BAR2_CONTROL)
   ,.PF1_BAR2_CONTROL(PF1_BAR2_CONTROL)
   ,.PF2_BAR2_CONTROL(PF2_BAR2_CONTROL)
   ,.PF3_BAR2_CONTROL(PF3_BAR2_CONTROL)
   ,.PF0_BAR2_APERTURE_SIZE(PF0_BAR2_APERTURE_SIZE)
   ,.PF1_BAR2_APERTURE_SIZE(PF1_BAR2_APERTURE_SIZE)
   ,.PF2_BAR2_APERTURE_SIZE(PF2_BAR2_APERTURE_SIZE)
   ,.PF3_BAR2_APERTURE_SIZE(PF3_BAR2_APERTURE_SIZE)
   ,.PF0_BAR3_CONTROL(PF0_BAR3_CONTROL)
   ,.PF1_BAR3_CONTROL(PF1_BAR3_CONTROL)
   ,.PF2_BAR3_CONTROL(PF2_BAR3_CONTROL)
   ,.PF3_BAR3_CONTROL(PF3_BAR3_CONTROL)
   ,.PF0_BAR3_APERTURE_SIZE(PF0_BAR3_APERTURE_SIZE)
   ,.PF1_BAR3_APERTURE_SIZE(PF1_BAR3_APERTURE_SIZE)
   ,.PF2_BAR3_APERTURE_SIZE(PF2_BAR3_APERTURE_SIZE)
   ,.PF3_BAR3_APERTURE_SIZE(PF3_BAR3_APERTURE_SIZE)
   ,.PF0_BAR4_CONTROL(PF0_BAR4_CONTROL)
   ,.PF1_BAR4_CONTROL(PF1_BAR4_CONTROL)
   ,.PF2_BAR4_CONTROL(PF2_BAR4_CONTROL)
   ,.PF3_BAR4_CONTROL(PF3_BAR4_CONTROL)
   ,.PF0_BAR4_APERTURE_SIZE(PF0_BAR4_APERTURE_SIZE)
   ,.PF1_BAR4_APERTURE_SIZE(PF1_BAR4_APERTURE_SIZE)
   ,.PF2_BAR4_APERTURE_SIZE(PF2_BAR4_APERTURE_SIZE)
   ,.PF3_BAR4_APERTURE_SIZE(PF3_BAR4_APERTURE_SIZE)
   ,.PF0_BAR5_CONTROL(PF0_BAR5_CONTROL)
   ,.PF1_BAR5_CONTROL(PF1_BAR5_CONTROL)
   ,.PF2_BAR5_CONTROL(PF2_BAR5_CONTROL)
   ,.PF3_BAR5_CONTROL(PF3_BAR5_CONTROL)
   ,.PF0_BAR5_APERTURE_SIZE(PF0_BAR5_APERTURE_SIZE)
   ,.PF1_BAR5_APERTURE_SIZE(PF1_BAR5_APERTURE_SIZE)
   ,.PF2_BAR5_APERTURE_SIZE(PF2_BAR5_APERTURE_SIZE)
   ,.PF3_BAR5_APERTURE_SIZE(PF3_BAR5_APERTURE_SIZE)
   ,.PF0_EXPANSION_ROM_ENABLE(PF0_EXPANSION_ROM_ENABLE)
   ,.PF1_EXPANSION_ROM_ENABLE(PF1_EXPANSION_ROM_ENABLE)
   ,.PF2_EXPANSION_ROM_ENABLE(PF2_EXPANSION_ROM_ENABLE)
   ,.PF3_EXPANSION_ROM_ENABLE(PF3_EXPANSION_ROM_ENABLE)
   ,.PF0_EXPANSION_ROM_APERTURE_SIZE(PF0_EXPANSION_ROM_APERTURE_SIZE)
   ,.PF1_EXPANSION_ROM_APERTURE_SIZE(PF1_EXPANSION_ROM_APERTURE_SIZE)
   ,.PF2_EXPANSION_ROM_APERTURE_SIZE(PF2_EXPANSION_ROM_APERTURE_SIZE)
   ,.PF3_EXPANSION_ROM_APERTURE_SIZE(PF3_EXPANSION_ROM_APERTURE_SIZE)
   ,.PF0_PCIE_CAP_NEXTPTR(PF0_PCIE_CAP_NEXTPTR)
   ,.PF1_PCIE_CAP_NEXTPTR(PF1_PCIE_CAP_NEXTPTR)
   ,.PF2_PCIE_CAP_NEXTPTR(PF2_PCIE_CAP_NEXTPTR)
   ,.PF3_PCIE_CAP_NEXTPTR(PF3_PCIE_CAP_NEXTPTR)
   ,.VFG0_PCIE_CAP_NEXTPTR(VFG0_PCIE_CAP_NEXTPTR)
   ,.VFG1_PCIE_CAP_NEXTPTR(VFG1_PCIE_CAP_NEXTPTR)
   ,.VFG2_PCIE_CAP_NEXTPTR(VFG2_PCIE_CAP_NEXTPTR)
   ,.VFG3_PCIE_CAP_NEXTPTR(VFG3_PCIE_CAP_NEXTPTR)
   ,.PF0_DEV_CAP_MAX_PAYLOAD_SIZE(PF0_DEV_CAP_MAX_PAYLOAD_SIZE)
   ,.PF1_DEV_CAP_MAX_PAYLOAD_SIZE(PF1_DEV_CAP_MAX_PAYLOAD_SIZE)
   ,.PF2_DEV_CAP_MAX_PAYLOAD_SIZE(PF2_DEV_CAP_MAX_PAYLOAD_SIZE)
   ,.PF3_DEV_CAP_MAX_PAYLOAD_SIZE(PF3_DEV_CAP_MAX_PAYLOAD_SIZE)
   ,.PF0_DEV_CAP_EXT_TAG_SUPPORTED(PF0_DEV_CAP_EXT_TAG_SUPPORTED)
   ,.PF0_DEV_CAP_ENDPOINT_L0S_LATENCY(PF0_DEV_CAP_ENDPOINT_L0S_LATENCY)
   ,.PF0_DEV_CAP_ENDPOINT_L1_LATENCY(PF0_DEV_CAP_ENDPOINT_L1_LATENCY)
   ,.PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE(PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE)
   ,.PF0_LINK_CAP_ASPM_SUPPORT(PF0_LINK_CAP_ASPM_SUPPORT)
   ,.PF0_LINK_CONTROL_RCB(PF0_LINK_CONTROL_RCB)
   ,.PF0_LINK_STATUS_SLOT_CLOCK_CONFIG(PF0_LINK_STATUS_SLOT_CLOCK_CONFIG)
   ,.PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1(PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1)
   ,.PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2(PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2)
   ,.PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN3(PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN3)
   ,.PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN4(PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN4)
   ,.PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN1(PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN1)
   ,.PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN2(PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN2)
   ,.PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN3(PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN3)
   ,.PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN4(PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN4)
   ,.PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1(PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1)
   ,.PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2(PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2)
   ,.PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN3(PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN3)
   ,.PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN4(PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN4)
   ,.PF0_LINK_CAP_L1_EXIT_LATENCY_GEN1(PF0_LINK_CAP_L1_EXIT_LATENCY_GEN1)
   ,.PF0_LINK_CAP_L1_EXIT_LATENCY_GEN2(PF0_LINK_CAP_L1_EXIT_LATENCY_GEN2)
   ,.PF0_LINK_CAP_L1_EXIT_LATENCY_GEN3(PF0_LINK_CAP_L1_EXIT_LATENCY_GEN3)
   ,.PF0_LINK_CAP_L1_EXIT_LATENCY_GEN4(PF0_LINK_CAP_L1_EXIT_LATENCY_GEN4)
   ,.PF0_DEV_CAP2_CPL_TIMEOUT_DISABLE(PF0_DEV_CAP2_CPL_TIMEOUT_DISABLE)
   ,.PF0_DEV_CAP2_32B_ATOMIC_COMPLETER_SUPPORT(PF0_DEV_CAP2_32B_ATOMIC_COMPLETER_SUPPORT)
   ,.PF0_DEV_CAP2_64B_ATOMIC_COMPLETER_SUPPORT(PF0_DEV_CAP2_64B_ATOMIC_COMPLETER_SUPPORT)
   ,.PF0_DEV_CAP2_128B_CAS_ATOMIC_COMPLETER_SUPPORT(PF0_DEV_CAP2_128B_CAS_ATOMIC_COMPLETER_SUPPORT)
   ,.PF0_DEV_CAP2_LTR_SUPPORT(PF0_DEV_CAP2_LTR_SUPPORT)
   ,.PF0_DEV_CAP2_TPH_COMPLETER_SUPPORT(PF0_DEV_CAP2_TPH_COMPLETER_SUPPORT)
   ,.PF0_DEV_CAP2_OBFF_SUPPORT(PF0_DEV_CAP2_OBFF_SUPPORT)
   ,.PF0_DEV_CAP2_ARI_FORWARD_ENABLE(PF0_DEV_CAP2_ARI_FORWARD_ENABLE)
   ,.PF0_MSI_CAP_NEXTPTR(PF0_MSI_CAP_NEXTPTR)
   ,.PF1_MSI_CAP_NEXTPTR(PF1_MSI_CAP_NEXTPTR)
   ,.PF2_MSI_CAP_NEXTPTR(PF2_MSI_CAP_NEXTPTR)
   ,.PF3_MSI_CAP_NEXTPTR(PF3_MSI_CAP_NEXTPTR)
   ,.PF0_MSI_CAP_PERVECMASKCAP(PF0_MSI_CAP_PERVECMASKCAP)
   ,.PF1_MSI_CAP_PERVECMASKCAP(PF1_MSI_CAP_PERVECMASKCAP)
   ,.PF2_MSI_CAP_PERVECMASKCAP(PF2_MSI_CAP_PERVECMASKCAP)
   ,.PF3_MSI_CAP_PERVECMASKCAP(PF3_MSI_CAP_PERVECMASKCAP)
   ,.PF0_MSI_CAP_MULTIMSGCAP(PF0_MSI_CAP_MULTIMSGCAP)
   ,.PF1_MSI_CAP_MULTIMSGCAP(PF1_MSI_CAP_MULTIMSGCAP)
   ,.PF2_MSI_CAP_MULTIMSGCAP(PF2_MSI_CAP_MULTIMSGCAP)
   ,.PF3_MSI_CAP_MULTIMSGCAP(PF3_MSI_CAP_MULTIMSGCAP)
   ,.PF0_MSIX_CAP_NEXTPTR(PF0_MSIX_CAP_NEXTPTR)
   ,.PF1_MSIX_CAP_NEXTPTR(PF1_MSIX_CAP_NEXTPTR)
   ,.PF2_MSIX_CAP_NEXTPTR(PF2_MSIX_CAP_NEXTPTR)
   ,.PF3_MSIX_CAP_NEXTPTR(PF3_MSIX_CAP_NEXTPTR)
   ,.VFG0_MSIX_CAP_NEXTPTR(VFG0_MSIX_CAP_NEXTPTR)
   ,.VFG1_MSIX_CAP_NEXTPTR(VFG1_MSIX_CAP_NEXTPTR)
   ,.VFG2_MSIX_CAP_NEXTPTR(VFG2_MSIX_CAP_NEXTPTR)
   ,.VFG3_MSIX_CAP_NEXTPTR(VFG3_MSIX_CAP_NEXTPTR)
   ,.PF0_MSIX_CAP_PBA_BIR(PF0_MSIX_CAP_PBA_BIR)
   ,.PF1_MSIX_CAP_PBA_BIR(PF1_MSIX_CAP_PBA_BIR)
   ,.PF2_MSIX_CAP_PBA_BIR(PF2_MSIX_CAP_PBA_BIR)
   ,.PF3_MSIX_CAP_PBA_BIR(PF3_MSIX_CAP_PBA_BIR)
   ,.VFG0_MSIX_CAP_PBA_BIR(VFG0_MSIX_CAP_PBA_BIR)
   ,.VFG1_MSIX_CAP_PBA_BIR(VFG1_MSIX_CAP_PBA_BIR)
   ,.VFG2_MSIX_CAP_PBA_BIR(VFG2_MSIX_CAP_PBA_BIR)
   ,.VFG3_MSIX_CAP_PBA_BIR(VFG3_MSIX_CAP_PBA_BIR)
   ,.PF0_MSIX_CAP_PBA_OFFSET(PF0_MSIX_CAP_PBA_OFFSET)
   ,.PF1_MSIX_CAP_PBA_OFFSET(PF1_MSIX_CAP_PBA_OFFSET)
   ,.PF2_MSIX_CAP_PBA_OFFSET(PF2_MSIX_CAP_PBA_OFFSET)
   ,.PF3_MSIX_CAP_PBA_OFFSET(PF3_MSIX_CAP_PBA_OFFSET)
   ,.VFG0_MSIX_CAP_PBA_OFFSET(VFG0_MSIX_CAP_PBA_OFFSET)
   ,.VFG1_MSIX_CAP_PBA_OFFSET(VFG1_MSIX_CAP_PBA_OFFSET)
   ,.VFG2_MSIX_CAP_PBA_OFFSET(VFG2_MSIX_CAP_PBA_OFFSET)
   ,.VFG3_MSIX_CAP_PBA_OFFSET(VFG3_MSIX_CAP_PBA_OFFSET)
   ,.PF0_MSIX_CAP_TABLE_BIR(PF0_MSIX_CAP_TABLE_BIR)
   ,.PF1_MSIX_CAP_TABLE_BIR(PF1_MSIX_CAP_TABLE_BIR)
   ,.PF2_MSIX_CAP_TABLE_BIR(PF2_MSIX_CAP_TABLE_BIR)
   ,.PF3_MSIX_CAP_TABLE_BIR(PF3_MSIX_CAP_TABLE_BIR)
   ,.VFG0_MSIX_CAP_TABLE_BIR(VFG0_MSIX_CAP_TABLE_BIR)
   ,.VFG1_MSIX_CAP_TABLE_BIR(VFG1_MSIX_CAP_TABLE_BIR)
   ,.VFG2_MSIX_CAP_TABLE_BIR(VFG2_MSIX_CAP_TABLE_BIR)
   ,.VFG3_MSIX_CAP_TABLE_BIR(VFG3_MSIX_CAP_TABLE_BIR)
   ,.PF0_MSIX_CAP_TABLE_OFFSET(PF0_MSIX_CAP_TABLE_OFFSET)
   ,.PF1_MSIX_CAP_TABLE_OFFSET(PF1_MSIX_CAP_TABLE_OFFSET)
   ,.PF2_MSIX_CAP_TABLE_OFFSET(PF2_MSIX_CAP_TABLE_OFFSET)
   ,.PF3_MSIX_CAP_TABLE_OFFSET(PF3_MSIX_CAP_TABLE_OFFSET)
   ,.VFG0_MSIX_CAP_TABLE_OFFSET(VFG0_MSIX_CAP_TABLE_OFFSET)
   ,.VFG1_MSIX_CAP_TABLE_OFFSET(VFG1_MSIX_CAP_TABLE_OFFSET)
   ,.VFG2_MSIX_CAP_TABLE_OFFSET(VFG2_MSIX_CAP_TABLE_OFFSET)
   ,.VFG3_MSIX_CAP_TABLE_OFFSET(VFG3_MSIX_CAP_TABLE_OFFSET)
   ,.PF0_MSIX_CAP_TABLE_SIZE(PF0_MSIX_CAP_TABLE_SIZE)
   ,.PF1_MSIX_CAP_TABLE_SIZE(PF1_MSIX_CAP_TABLE_SIZE)
   ,.PF2_MSIX_CAP_TABLE_SIZE(PF2_MSIX_CAP_TABLE_SIZE)
   ,.PF3_MSIX_CAP_TABLE_SIZE(PF3_MSIX_CAP_TABLE_SIZE)
   ,.VFG0_MSIX_CAP_TABLE_SIZE(VFG0_MSIX_CAP_TABLE_SIZE)
   ,.VFG1_MSIX_CAP_TABLE_SIZE(VFG1_MSIX_CAP_TABLE_SIZE)
   ,.VFG2_MSIX_CAP_TABLE_SIZE(VFG2_MSIX_CAP_TABLE_SIZE)
   ,.VFG3_MSIX_CAP_TABLE_SIZE(VFG3_MSIX_CAP_TABLE_SIZE)
   ,.PF0_MSIX_VECTOR_COUNT(PF0_MSIX_VECTOR_COUNT)
   ,.PF0_PM_CAP_ID(PF0_PM_CAP_ID)
   ,.PF0_PM_CAP_NEXTPTR(PF0_PM_CAP_NEXTPTR)
   ,.PF1_PM_CAP_NEXTPTR(PF1_PM_CAP_NEXTPTR)
   ,.PF2_PM_CAP_NEXTPTR(PF2_PM_CAP_NEXTPTR)
   ,.PF3_PM_CAP_NEXTPTR(PF3_PM_CAP_NEXTPTR)
   ,.PF0_PM_CAP_PMESUPPORT_D3HOT(PF0_PM_CAP_PMESUPPORT_D3HOT)
   ,.PF0_PM_CAP_PMESUPPORT_D1(PF0_PM_CAP_PMESUPPORT_D1)
   ,.PF0_PM_CAP_PMESUPPORT_D0(PF0_PM_CAP_PMESUPPORT_D0)
   ,.PF0_PM_CAP_SUPP_D1_STATE(PF0_PM_CAP_SUPP_D1_STATE)
   ,.PF0_PM_CAP_VER_ID(PF0_PM_CAP_VER_ID)
   ,.PF0_PM_CSR_NOSOFTRESET(PF0_PM_CSR_NOSOFTRESET)
   ,.PM_ENABLE_L23_ENTRY(PM_ENABLE_L23_ENTRY)
   ,.DNSTREAM_LINK_NUM(DNSTREAM_LINK_NUM)
   ,.AUTO_FLR_RESPONSE(AUTO_FLR_RESPONSE)
   ,.PF0_DSN_CAP_NEXTPTR(PF0_DSN_CAP_NEXTPTR)
   ,.PF1_DSN_CAP_NEXTPTR(PF1_DSN_CAP_NEXTPTR)
   ,.PF2_DSN_CAP_NEXTPTR(PF2_DSN_CAP_NEXTPTR)
   ,.PF3_DSN_CAP_NEXTPTR(PF3_DSN_CAP_NEXTPTR)
   ,.DSN_CAP_ENABLE(DSN_CAP_ENABLE)
   ,.PF0_VC_CAP_VER(PF0_VC_CAP_VER)
   ,.PF0_VC_CAP_NEXTPTR(PF0_VC_CAP_NEXTPTR)
   ,.PF0_VC_CAP_ENABLE(PF0_VC_CAP_ENABLE)
   ,.PF0_SECONDARY_PCIE_CAP_NEXTPTR(PF0_SECONDARY_PCIE_CAP_NEXTPTR)
   ,.PF0_AER_CAP_NEXTPTR(PF0_AER_CAP_NEXTPTR)
   ,.PF1_AER_CAP_NEXTPTR(PF1_AER_CAP_NEXTPTR)
   ,.PF2_AER_CAP_NEXTPTR(PF2_AER_CAP_NEXTPTR)
   ,.PF3_AER_CAP_NEXTPTR(PF3_AER_CAP_NEXTPTR)
   ,.PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE(PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE)
   ,.ARI_CAP_ENABLE(ARI_CAP_ENABLE)
   ,.PF0_ARI_CAP_NEXTPTR(PF0_ARI_CAP_NEXTPTR)
   ,.PF1_ARI_CAP_NEXTPTR(PF1_ARI_CAP_NEXTPTR)
   ,.PF2_ARI_CAP_NEXTPTR(PF2_ARI_CAP_NEXTPTR)
   ,.PF3_ARI_CAP_NEXTPTR(PF3_ARI_CAP_NEXTPTR)
   ,.VFG0_ARI_CAP_NEXTPTR(VFG0_ARI_CAP_NEXTPTR)
   ,.VFG1_ARI_CAP_NEXTPTR(VFG1_ARI_CAP_NEXTPTR)
   ,.VFG2_ARI_CAP_NEXTPTR(VFG2_ARI_CAP_NEXTPTR)
   ,.VFG3_ARI_CAP_NEXTPTR(VFG3_ARI_CAP_NEXTPTR)
   ,.PF0_ARI_CAP_VER(PF0_ARI_CAP_VER)
   ,.PF0_ARI_CAP_NEXT_FUNC(PF0_ARI_CAP_NEXT_FUNC)
   ,.PF1_ARI_CAP_NEXT_FUNC(PF1_ARI_CAP_NEXT_FUNC)
   ,.PF2_ARI_CAP_NEXT_FUNC(PF2_ARI_CAP_NEXT_FUNC)
   ,.PF3_ARI_CAP_NEXT_FUNC(PF3_ARI_CAP_NEXT_FUNC)
   ,.PF0_LTR_CAP_NEXTPTR(PF0_LTR_CAP_NEXTPTR)
   ,.PF0_LTR_CAP_VER(PF0_LTR_CAP_VER)
   ,.PF0_LTR_CAP_MAX_SNOOP_LAT(PF0_LTR_CAP_MAX_SNOOP_LAT)
   ,.PF0_LTR_CAP_MAX_NOSNOOP_LAT(PF0_LTR_CAP_MAX_NOSNOOP_LAT)
   ,.LTR_TX_MESSAGE_ON_LTR_ENABLE(LTR_TX_MESSAGE_ON_LTR_ENABLE)
   ,.LTR_TX_MESSAGE_ON_FUNC_POWER_STATE_CHANGE(LTR_TX_MESSAGE_ON_FUNC_POWER_STATE_CHANGE)
   ,.LTR_TX_MESSAGE_MINIMUM_INTERVAL(LTR_TX_MESSAGE_MINIMUM_INTERVAL)
   ,.SRIOV_CAP_ENABLE(SRIOV_CAP_ENABLE)
   ,.PF0_SRIOV_CAP_NEXTPTR(PF0_SRIOV_CAP_NEXTPTR)
   ,.PF1_SRIOV_CAP_NEXTPTR(PF1_SRIOV_CAP_NEXTPTR)
   ,.PF2_SRIOV_CAP_NEXTPTR(PF2_SRIOV_CAP_NEXTPTR)
   ,.PF3_SRIOV_CAP_NEXTPTR(PF3_SRIOV_CAP_NEXTPTR)
   ,.PF0_SRIOV_CAP_VER(PF0_SRIOV_CAP_VER)
   ,.PF1_SRIOV_CAP_VER(PF1_SRIOV_CAP_VER)
   ,.PF2_SRIOV_CAP_VER(PF2_SRIOV_CAP_VER)
   ,.PF3_SRIOV_CAP_VER(PF3_SRIOV_CAP_VER)
   ,.PF0_SRIOV_ARI_CAPBL_HIER_PRESERVED(PF0_SRIOV_ARI_CAPBL_HIER_PRESERVED)
   ,.PF1_SRIOV_ARI_CAPBL_HIER_PRESERVED(PF1_SRIOV_ARI_CAPBL_HIER_PRESERVED)
   ,.PF2_SRIOV_ARI_CAPBL_HIER_PRESERVED(PF2_SRIOV_ARI_CAPBL_HIER_PRESERVED)
   ,.PF3_SRIOV_ARI_CAPBL_HIER_PRESERVED(PF3_SRIOV_ARI_CAPBL_HIER_PRESERVED)
   ,.PF0_SRIOV_CAP_INITIAL_VF(PF0_SRIOV_CAP_INITIAL_VF)
   ,.PF1_SRIOV_CAP_INITIAL_VF(PF1_SRIOV_CAP_INITIAL_VF)
   ,.PF2_SRIOV_CAP_INITIAL_VF(PF2_SRIOV_CAP_INITIAL_VF)
   ,.PF3_SRIOV_CAP_INITIAL_VF(PF3_SRIOV_CAP_INITIAL_VF)
   ,.PF0_SRIOV_CAP_TOTAL_VF(PF0_SRIOV_CAP_TOTAL_VF)
   ,.PF1_SRIOV_CAP_TOTAL_VF(PF1_SRIOV_CAP_TOTAL_VF)
   ,.PF2_SRIOV_CAP_TOTAL_VF(PF2_SRIOV_CAP_TOTAL_VF)
   ,.PF3_SRIOV_CAP_TOTAL_VF(PF3_SRIOV_CAP_TOTAL_VF)
   ,.PF0_SRIOV_FUNC_DEP_LINK(PF0_SRIOV_FUNC_DEP_LINK)
   ,.PF1_SRIOV_FUNC_DEP_LINK(PF1_SRIOV_FUNC_DEP_LINK)
   ,.PF2_SRIOV_FUNC_DEP_LINK(PF2_SRIOV_FUNC_DEP_LINK)
   ,.PF3_SRIOV_FUNC_DEP_LINK(PF3_SRIOV_FUNC_DEP_LINK)
   ,.PF0_SRIOV_FIRST_VF_OFFSET(PF0_SRIOV_FIRST_VF_OFFSET)
   ,.PF1_SRIOV_FIRST_VF_OFFSET(PF1_SRIOV_FIRST_VF_OFFSET)
   ,.PF2_SRIOV_FIRST_VF_OFFSET(PF2_SRIOV_FIRST_VF_OFFSET)
   ,.PF3_SRIOV_FIRST_VF_OFFSET(PF3_SRIOV_FIRST_VF_OFFSET)
   ,.PF0_SRIOV_VF_DEVICE_ID(PF0_SRIOV_VF_DEVICE_ID)
   ,.PF1_SRIOV_VF_DEVICE_ID(PF1_SRIOV_VF_DEVICE_ID)
   ,.PF2_SRIOV_VF_DEVICE_ID(PF2_SRIOV_VF_DEVICE_ID)
   ,.PF3_SRIOV_VF_DEVICE_ID(PF3_SRIOV_VF_DEVICE_ID)
   ,.PF0_SRIOV_SUPPORTED_PAGE_SIZE(PF0_SRIOV_SUPPORTED_PAGE_SIZE)
   ,.PF1_SRIOV_SUPPORTED_PAGE_SIZE(PF1_SRIOV_SUPPORTED_PAGE_SIZE)
   ,.PF2_SRIOV_SUPPORTED_PAGE_SIZE(PF2_SRIOV_SUPPORTED_PAGE_SIZE)
   ,.PF3_SRIOV_SUPPORTED_PAGE_SIZE(PF3_SRIOV_SUPPORTED_PAGE_SIZE)
   ,.PF0_SRIOV_BAR0_CONTROL(PF0_SRIOV_BAR0_CONTROL)
   ,.PF1_SRIOV_BAR0_CONTROL(PF1_SRIOV_BAR0_CONTROL)
   ,.PF2_SRIOV_BAR0_CONTROL(PF2_SRIOV_BAR0_CONTROL)
   ,.PF3_SRIOV_BAR0_CONTROL(PF3_SRIOV_BAR0_CONTROL)
   ,.PF0_SRIOV_BAR0_APERTURE_SIZE(PF0_SRIOV_BAR0_APERTURE_SIZE)
   ,.PF1_SRIOV_BAR0_APERTURE_SIZE(PF1_SRIOV_BAR0_APERTURE_SIZE)
   ,.PF2_SRIOV_BAR0_APERTURE_SIZE(PF2_SRIOV_BAR0_APERTURE_SIZE)
   ,.PF3_SRIOV_BAR0_APERTURE_SIZE(PF3_SRIOV_BAR0_APERTURE_SIZE)
   ,.PF0_SRIOV_BAR1_CONTROL(PF0_SRIOV_BAR1_CONTROL)
   ,.PF1_SRIOV_BAR1_CONTROL(PF1_SRIOV_BAR1_CONTROL)
   ,.PF2_SRIOV_BAR1_CONTROL(PF2_SRIOV_BAR1_CONTROL)
   ,.PF3_SRIOV_BAR1_CONTROL(PF3_SRIOV_BAR1_CONTROL)
   ,.PF0_SRIOV_BAR1_APERTURE_SIZE(PF0_SRIOV_BAR1_APERTURE_SIZE)
   ,.PF1_SRIOV_BAR1_APERTURE_SIZE(PF1_SRIOV_BAR1_APERTURE_SIZE)
   ,.PF2_SRIOV_BAR1_APERTURE_SIZE(PF2_SRIOV_BAR1_APERTURE_SIZE)
   ,.PF3_SRIOV_BAR1_APERTURE_SIZE(PF3_SRIOV_BAR1_APERTURE_SIZE)
   ,.PF0_SRIOV_BAR2_CONTROL(PF0_SRIOV_BAR2_CONTROL)
   ,.PF1_SRIOV_BAR2_CONTROL(PF1_SRIOV_BAR2_CONTROL)
   ,.PF2_SRIOV_BAR2_CONTROL(PF2_SRIOV_BAR2_CONTROL)
   ,.PF3_SRIOV_BAR2_CONTROL(PF3_SRIOV_BAR2_CONTROL)
   ,.PF0_SRIOV_BAR2_APERTURE_SIZE(PF0_SRIOV_BAR2_APERTURE_SIZE)
   ,.PF1_SRIOV_BAR2_APERTURE_SIZE(PF1_SRIOV_BAR2_APERTURE_SIZE)
   ,.PF2_SRIOV_BAR2_APERTURE_SIZE(PF2_SRIOV_BAR2_APERTURE_SIZE)
   ,.PF3_SRIOV_BAR2_APERTURE_SIZE(PF3_SRIOV_BAR2_APERTURE_SIZE)
   ,.PF0_SRIOV_BAR3_CONTROL(PF0_SRIOV_BAR3_CONTROL)
   ,.PF1_SRIOV_BAR3_CONTROL(PF1_SRIOV_BAR3_CONTROL)
   ,.PF2_SRIOV_BAR3_CONTROL(PF2_SRIOV_BAR3_CONTROL)
   ,.PF3_SRIOV_BAR3_CONTROL(PF3_SRIOV_BAR3_CONTROL)
   ,.PF0_SRIOV_BAR3_APERTURE_SIZE(PF0_SRIOV_BAR3_APERTURE_SIZE)
   ,.PF1_SRIOV_BAR3_APERTURE_SIZE(PF1_SRIOV_BAR3_APERTURE_SIZE)
   ,.PF2_SRIOV_BAR3_APERTURE_SIZE(PF2_SRIOV_BAR3_APERTURE_SIZE)
   ,.PF3_SRIOV_BAR3_APERTURE_SIZE(PF3_SRIOV_BAR3_APERTURE_SIZE)
   ,.PF0_SRIOV_BAR4_CONTROL(PF0_SRIOV_BAR4_CONTROL)
   ,.PF1_SRIOV_BAR4_CONTROL(PF1_SRIOV_BAR4_CONTROL)
   ,.PF2_SRIOV_BAR4_CONTROL(PF2_SRIOV_BAR4_CONTROL)
   ,.PF3_SRIOV_BAR4_CONTROL(PF3_SRIOV_BAR4_CONTROL)
   ,.PF0_SRIOV_BAR4_APERTURE_SIZE(PF0_SRIOV_BAR4_APERTURE_SIZE)
   ,.PF1_SRIOV_BAR4_APERTURE_SIZE(PF1_SRIOV_BAR4_APERTURE_SIZE)
   ,.PF2_SRIOV_BAR4_APERTURE_SIZE(PF2_SRIOV_BAR4_APERTURE_SIZE)
   ,.PF3_SRIOV_BAR4_APERTURE_SIZE(PF3_SRIOV_BAR4_APERTURE_SIZE)
   ,.PF0_SRIOV_BAR5_CONTROL(PF0_SRIOV_BAR5_CONTROL)
   ,.PF1_SRIOV_BAR5_CONTROL(PF1_SRIOV_BAR5_CONTROL)
   ,.PF2_SRIOV_BAR5_CONTROL(PF2_SRIOV_BAR5_CONTROL)
   ,.PF3_SRIOV_BAR5_CONTROL(PF3_SRIOV_BAR5_CONTROL)
   ,.PF0_SRIOV_BAR5_APERTURE_SIZE(PF0_SRIOV_BAR5_APERTURE_SIZE)
   ,.PF1_SRIOV_BAR5_APERTURE_SIZE(PF1_SRIOV_BAR5_APERTURE_SIZE)
   ,.PF2_SRIOV_BAR5_APERTURE_SIZE(PF2_SRIOV_BAR5_APERTURE_SIZE)
   ,.PF3_SRIOV_BAR5_APERTURE_SIZE(PF3_SRIOV_BAR5_APERTURE_SIZE)
   ,.PF0_TPHR_CAP_NEXTPTR(PF0_TPHR_CAP_NEXTPTR)
   ,.PF1_TPHR_CAP_NEXTPTR(PF1_TPHR_CAP_NEXTPTR)
   ,.PF2_TPHR_CAP_NEXTPTR(PF2_TPHR_CAP_NEXTPTR)
   ,.PF3_TPHR_CAP_NEXTPTR(PF3_TPHR_CAP_NEXTPTR)
   ,.VFG0_TPHR_CAP_NEXTPTR(VFG0_TPHR_CAP_NEXTPTR)
   ,.VFG1_TPHR_CAP_NEXTPTR(VFG1_TPHR_CAP_NEXTPTR)
   ,.VFG2_TPHR_CAP_NEXTPTR(VFG2_TPHR_CAP_NEXTPTR)
   ,.VFG3_TPHR_CAP_NEXTPTR(VFG3_TPHR_CAP_NEXTPTR)
   ,.PF0_TPHR_CAP_VER(PF0_TPHR_CAP_VER)
   ,.PF0_TPHR_CAP_INT_VEC_MODE(PF0_TPHR_CAP_INT_VEC_MODE)
   ,.PF0_TPHR_CAP_DEV_SPECIFIC_MODE(PF0_TPHR_CAP_DEV_SPECIFIC_MODE)
   ,.PF0_TPHR_CAP_ST_TABLE_LOC(PF0_TPHR_CAP_ST_TABLE_LOC)
   ,.PF0_TPHR_CAP_ST_TABLE_SIZE(PF0_TPHR_CAP_ST_TABLE_SIZE)
   ,.PF0_TPHR_CAP_ST_MODE_SEL(PF0_TPHR_CAP_ST_MODE_SEL)
   ,.PF1_TPHR_CAP_ST_MODE_SEL(PF1_TPHR_CAP_ST_MODE_SEL)
   ,.PF2_TPHR_CAP_ST_MODE_SEL(PF2_TPHR_CAP_ST_MODE_SEL)
   ,.PF3_TPHR_CAP_ST_MODE_SEL(PF3_TPHR_CAP_ST_MODE_SEL)
   ,.VFG0_TPHR_CAP_ST_MODE_SEL(VFG0_TPHR_CAP_ST_MODE_SEL)
   ,.VFG1_TPHR_CAP_ST_MODE_SEL(VFG1_TPHR_CAP_ST_MODE_SEL)
   ,.VFG2_TPHR_CAP_ST_MODE_SEL(VFG2_TPHR_CAP_ST_MODE_SEL)
   ,.VFG3_TPHR_CAP_ST_MODE_SEL(VFG3_TPHR_CAP_ST_MODE_SEL)
   ,.PF0_TPHR_CAP_ENABLE(PF0_TPHR_CAP_ENABLE)
   ,.TPH_TO_RAM_PIPELINE(TPH_TO_RAM_PIPELINE)
   ,.TPH_FROM_RAM_PIPELINE(TPH_FROM_RAM_PIPELINE)
   ,.MCAP_ENABLE(MCAP_ENABLE)
   ,.MCAP_CONFIGURE_OVERRIDE(MCAP_CONFIGURE_OVERRIDE)
   ,.MCAP_CAP_NEXTPTR(MCAP_CAP_NEXTPTR)
   ,.MCAP_VSEC_ID(MCAP_VSEC_ID)
   ,.MCAP_VSEC_REV(MCAP_VSEC_REV)
   ,.MCAP_VSEC_LEN(MCAP_VSEC_LEN)
   ,.MCAP_FPGA_BITSTREAM_VERSION(MCAP_FPGA_BITSTREAM_VERSION)
   ,.MCAP_INTERRUPT_ON_MCAP_EOS(MCAP_INTERRUPT_ON_MCAP_EOS)
   ,.MCAP_INTERRUPT_ON_MCAP_ERROR(MCAP_INTERRUPT_ON_MCAP_ERROR)
   ,.MCAP_INPUT_GATE_DESIGN_SWITCH(MCAP_INPUT_GATE_DESIGN_SWITCH)
   ,.MCAP_EOS_DESIGN_SWITCH(MCAP_EOS_DESIGN_SWITCH)
   ,.MCAP_GATE_MEM_ENABLE_DESIGN_SWITCH(MCAP_GATE_MEM_ENABLE_DESIGN_SWITCH)
   ,.MCAP_GATE_IO_ENABLE_DESIGN_SWITCH(MCAP_GATE_IO_ENABLE_DESIGN_SWITCH)
   ,.SIM_JTAG_IDCODE(SIM_JTAG_IDCODE)
   ,.DEBUG_AXIST_DISABLE_FEATURE_BIT(DEBUG_AXIST_DISABLE_FEATURE_BIT)
   ,.DEBUG_TL_DISABLE_RX_TLP_ORDER_CHECKS(DEBUG_TL_DISABLE_RX_TLP_ORDER_CHECKS)
   ,.DEBUG_TL_DISABLE_FC_TIMEOUT(DEBUG_TL_DISABLE_FC_TIMEOUT)
   ,.DEBUG_PL_DISABLE_SCRAMBLING(DEBUG_PL_DISABLE_SCRAMBLING)
   ,.DEBUG_PL_DISABLE_REC_ENTRY_ON_DYNAMIC_DSKEW_FAIL (DEBUG_PL_DISABLE_REC_ENTRY_ON_DYNAMIC_DSKEW_FAIL )
   ,.DEBUG_PL_DISABLE_REC_ENTRY_ON_RX_BUFFER_UNDER_OVER_FLOW (DEBUG_PL_DISABLE_REC_ENTRY_ON_RX_BUFFER_UNDER_OVER_FLOW )
   ,.DEBUG_PL_DISABLE_LES_UPDATE_ON_SKP_ERROR(DEBUG_PL_DISABLE_LES_UPDATE_ON_SKP_ERROR)
   ,.DEBUG_PL_DISABLE_LES_UPDATE_ON_SKP_PARITY_ERROR(DEBUG_PL_DISABLE_LES_UPDATE_ON_SKP_PARITY_ERROR)
   ,.DEBUG_PL_DISABLE_LES_UPDATE_ON_DEFRAMER_ERROR(DEBUG_PL_DISABLE_LES_UPDATE_ON_DEFRAMER_ERROR)
   ,.DEBUG_PL_SIM_RESET_LFSR(DEBUG_PL_SIM_RESET_LFSR)
   ,.DEBUG_PL_SPARE(DEBUG_PL_SPARE)
   ,.DEBUG_LL_SPARE(DEBUG_LL_SPARE)
   ,.DEBUG_TL_SPARE(DEBUG_TL_SPARE)
   ,.DEBUG_AXI4ST_SPARE(DEBUG_AXI4ST_SPARE)
   ,.DEBUG_CFG_SPARE(DEBUG_CFG_SPARE)
   ,.DEBUG_CAR_SPARE(DEBUG_CAR_SPARE)
   ,.TEST_MODE_PIN_CHAR(TEST_MODE_PIN_CHAR)
   ,.SPARE_BIT0(SPARE_BIT0)
   ,.SPARE_BIT1(SPARE_BIT1)
   ,.SPARE_BIT2(SPARE_BIT2)
   ,.SPARE_BIT3(SPARE_BIT3)
   ,.SPARE_BIT4(SPARE_BIT4)
   ,.SPARE_BIT5(SPARE_BIT5)
   ,.SPARE_BIT6(SPARE_BIT6)
   ,.SPARE_BIT7(SPARE_BIT7)
   ,.SPARE_BIT8(SPARE_BIT8)
   ,.SPARE_BYTE0(SPARE_BYTE0)
   ,.SPARE_BYTE1(SPARE_BYTE1)
   ,.SPARE_BYTE2(SPARE_BYTE2)
   ,.SPARE_BYTE3(SPARE_BYTE3)
   ,.SPARE_WORD0(SPARE_WORD0)
   ,.SPARE_WORD1(SPARE_WORD1)
   ,.SPARE_WORD2(SPARE_WORD2)
   ,.SPARE_WORD3(SPARE_WORD3)

  ) pcie_4_0_int_inst ( 

    .common_commands_in ('h0), 
    .pipe_rx_0_sigs     ('h0),
    .pipe_rx_1_sigs     ('h0),
    .pipe_rx_2_sigs     ('h0),
    .pipe_rx_3_sigs     ('h0),
    .pipe_rx_4_sigs     ('h0),
    .pipe_rx_5_sigs     ('h0),
    .pipe_rx_6_sigs     ('h0),
    .pipe_rx_7_sigs     ('h0),
    .pipe_rx_8_sigs     ('h0),
    .pipe_rx_9_sigs     ('h0),
    .pipe_rx_10_sigs    ('h0),
    .pipe_rx_11_sigs    ('h0),
    .pipe_rx_12_sigs    ('h0),
    .pipe_rx_13_sigs    ('h0),
    .pipe_rx_14_sigs    ('h0),
    .pipe_rx_15_sigs    ('h0),

    .common_commands_out( ),  
    .pipe_tx_0_sigs     ( ),
    .pipe_tx_1_sigs     ( ),
    .pipe_tx_2_sigs     ( ),
    .pipe_tx_3_sigs     ( ),
    .pipe_tx_4_sigs     ( ),
    .pipe_tx_5_sigs     ( ),
    .pipe_tx_6_sigs     ( ),
    .pipe_tx_7_sigs     ( ),
    .pipe_tx_8_sigs     ( ),
    .pipe_tx_9_sigs     ( ),
    .pipe_tx_10_sigs    ( ),
    .pipe_tx_11_sigs    ( ),
    .pipe_tx_12_sigs    ( ),
    .pipe_tx_13_sigs    ( ),
    .pipe_tx_14_sigs    ( ),
    .pipe_tx_15_sigs    ( ),

    .pl_eq_in_progress(pl_eq_in_progress)
   ,.pl_eq_phase(pl_eq_phase[1:0])
   ,.pl_gen2_upstream_prefer_deemph(pl_gen2_upstream_prefer_deemph)
   ,.pl_redo_eq(pl_redo_eq)
   ,.pl_redo_eq_speed(pl_redo_eq_speed)
   ,.pl_eq_mismatch(pl_eq_mismatch)
   ,.pl_redo_eq_pending(pl_redo_eq_pending)

   ,.m_axis_cq_tdata(m_axis_cq_tdata)
   ,.s_axis_cc_tdata(s_axis_cc_tdata)
   ,.s_axis_rq_tdata(s_axis_rq_tdata)
   ,.m_axis_rc_tdata(m_axis_rc_tdata)
   ,.m_axis_cq_tuser(m_axis_cq_tuser)
   ,.s_axis_cc_tuser(s_axis_cc_tuser)
   ,.m_axis_cq_tlast(m_axis_cq_tlast)
   ,.s_axis_rq_tlast(s_axis_rq_tlast)
   ,.m_axis_rc_tlast(m_axis_rc_tlast)
   ,.s_axis_cc_tlast(s_axis_cc_tlast)
   ,.pcie_cq_np_req(pcie_cq_np_req[1:0])
   ,.pcie_cq_np_req_count(pcie_cq_np_req_count[5:0])
   ,.s_axis_rq_tuser(s_axis_rq_tuser)
   ,.m_axis_rc_tuser(m_axis_rc_tuser)
   ,.m_axis_cq_tkeep(m_axis_cq_tkeep)
   ,.s_axis_cc_tkeep(s_axis_cc_tkeep)
   ,.s_axis_rq_tkeep(s_axis_rq_tkeep)
   ,.m_axis_rc_tkeep(m_axis_rc_tkeep)
   ,.m_axis_cq_tvalid(m_axis_cq_tvalid)
   ,.s_axis_cc_tvalid(s_axis_cc_tvalid)
   ,.s_axis_rq_tvalid(s_axis_rq_tvalid)
   ,.m_axis_rc_tvalid(m_axis_rc_tvalid)
   ,.m_axis_cq_tready(m_axis_cq_tready)
   ,.s_axis_cc_tready(s_axis_cc_tready)
   ,.s_axis_rq_tready(s_axis_rq_tready)
   ,.m_axis_rc_tready(m_axis_rc_tready)
   ,.pcie_rq_seq_num0(pcie_rq_seq_num0[5:0])
   ,.pcie_rq_seq_num_vld0(pcie_rq_seq_num_vld0)
   ,.pcie_rq_seq_num1(pcie_rq_seq_num1[5:0])
   ,.pcie_rq_seq_num_vld1(pcie_rq_seq_num_vld1)
   ,.pcie_rq_tag0(pcie_rq_tag0[7:0])
   ,.pcie_rq_tag_vld0(pcie_rq_tag_vld0)
   ,.pcie_rq_tag1(pcie_rq_tag1[7:0])
   ,.pcie_rq_tag_vld1(pcie_rq_tag_vld1)
   ,.pcie_tfc_nph_av(pcie_tfc_nph_av[3:0])
   ,.pcie_tfc_npd_av(pcie_tfc_npd_av[3:0])
   ,.pcie_rq_tag_av(pcie_rq_tag_av[3:0])
   ,.cfg_mgmt_addr(cfg_mgmt_addr[9:0])
   ,.cfg_mgmt_function_number(cfg_mgmt_function_number[7:0])
   ,.cfg_mgmt_write(cfg_mgmt_write)
   ,.cfg_mgmt_write_data(cfg_mgmt_write_data[31:0])
   ,.cfg_mgmt_byte_enable(cfg_mgmt_byte_enable[3:0])
   ,.cfg_mgmt_read(cfg_mgmt_read)
   ,.cfg_mgmt_read_data(cfg_mgmt_read_data[31:0])
   ,.cfg_mgmt_read_write_done(cfg_mgmt_read_write_done)
   ,.cfg_mgmt_debug_access(cfg_mgmt_debug_access)
   ,.cfg_phy_link_down(cfg_phy_link_down)
   ,.cfg_phy_link_status(cfg_phy_link_status[1:0])
   ,.cfg_negotiated_width(cfg_negotiated_width[2:0])
   ,.cfg_current_speed(cfg_current_speed[1:0])
   ,.cfg_max_payload(cfg_max_payload[1:0])
   ,.cfg_max_read_req(cfg_max_read_req[2:0])
   ,.cfg_function_status(cfg_function_status[15:0])
   ,.cfg_function_power_state(cfg_function_power_state[11:0])
   ,.cfg_link_power_state(cfg_link_power_state[1:0])
   ,.cfg_err_cor_out(cfg_err_cor_out)
   ,.cfg_err_nonfatal_out(cfg_err_nonfatal_out)
   ,.cfg_err_fatal_out(cfg_err_fatal_out)
   ,.cfg_local_error_valid(cfg_local_error_valid)
   ,.cfg_local_error_out(cfg_local_error_out[4:0])
   ,.cfg_ltssm_state(cfg_ltssm_state[5:0])
   ,.cfg_rx_pm_state(cfg_rx_pm_state[1:0])
   ,.cfg_tx_pm_state(cfg_tx_pm_state[1:0])
   ,.cfg_rcb_status(cfg_rcb_status[3:0])
   ,.cfg_obff_enable(cfg_obff_enable[1:0])
   ,.cfg_pl_status_change(cfg_pl_status_change)
   ,.cfg_tph_requester_enable(cfg_tph_requester_enable[3:0])
   ,.cfg_tph_st_mode(cfg_tph_st_mode[11:0])
   ,.cfg_msg_received(cfg_msg_received)
   ,.cfg_msg_received_data(cfg_msg_received_data[7:0])
   ,.cfg_msg_received_type(cfg_msg_received_type[4:0])
   ,.cfg_msg_transmit(cfg_msg_transmit)
   ,.cfg_msg_transmit_type(cfg_msg_transmit_type[2:0])
   ,.cfg_msg_transmit_data(cfg_msg_transmit_data[31:0])
   ,.cfg_msg_transmit_done(cfg_msg_transmit_done)
   ,.cfg_fc_ph(cfg_fc_ph[7:0])
   ,.cfg_fc_pd(cfg_fc_pd[11:0])
   ,.cfg_fc_nph(cfg_fc_nph[7:0])
   ,.cfg_fc_npd(cfg_fc_npd[11:0])
   ,.cfg_fc_cplh(cfg_fc_cplh[7:0])
   ,.cfg_fc_cpld(cfg_fc_cpld[11:0])
   ,.cfg_fc_sel(cfg_fc_sel[2:0])
   ,.cfg_hot_reset_in(cfg_hot_reset_in)
   ,.cfg_hot_reset_out(cfg_hot_reset_out)
   ,.cfg_config_space_enable(cfg_config_space_enable)
   ,.cfg_dsn(cfg_dsn[63:0])
   ,.cfg_dev_id_pf0(cfg_dev_id_pf0[15:0])
   ,.cfg_dev_id_pf1(cfg_dev_id_pf1[15:0])
   ,.cfg_dev_id_pf2(cfg_dev_id_pf2[15:0])
   ,.cfg_dev_id_pf3(cfg_dev_id_pf3[15:0])
   ,.cfg_vend_id(cfg_vend_id[15:0])
   ,.cfg_rev_id_pf0(cfg_rev_id_pf0[7:0])
   ,.cfg_rev_id_pf1(cfg_rev_id_pf1[7:0])
   ,.cfg_rev_id_pf2(cfg_rev_id_pf2[7:0])
   ,.cfg_rev_id_pf3(cfg_rev_id_pf3[7:0])
   ,.cfg_subsys_id_pf0(cfg_subsys_id_pf0[15:0])
   ,.cfg_subsys_id_pf1(cfg_subsys_id_pf1[15:0])
   ,.cfg_subsys_id_pf2(cfg_subsys_id_pf2[15:0])
   ,.cfg_subsys_id_pf3(cfg_subsys_id_pf3[15:0])
   ,.cfg_subsys_vend_id(cfg_subsys_vend_id[15:0])
   ,.cfg_ds_port_number(cfg_ds_port_number[7:0])
   ,.cfg_ds_bus_number(cfg_ds_bus_number[7:0])
   ,.cfg_ds_device_number(cfg_ds_device_number[4:0])
   ,.cfg_bus_number(cfg_bus_number[7:0])
   ,.cfg_power_state_change_ack(cfg_power_state_change_ack)
   ,.cfg_power_state_change_interrupt(cfg_power_state_change_interrupt)
   ,.cfg_err_cor_in(cfg_err_cor_in)
   ,.cfg_err_uncor_in(cfg_err_uncor_in)
   ,.cfg_flr_done(cfg_flr_done[3:0])
   ,.cfg_vf_flr_in_process(cfg_vf_flr_in_process[251:0])
   ,.cfg_vf_flr_func_num(cfg_vf_flr_func_num[7:0])
   ,.cfg_vf_flr_done(cfg_vf_flr_done)
   ,.cfg_vf_status(cfg_vf_status[503:0])
   ,.cfg_vf_power_state(cfg_vf_power_state[755:0])
   ,.cfg_vf_tph_requester_enable( cfg_vf_tph_requester_enable[251:0])
   ,.cfg_vf_tph_st_mode(cfg_vf_tph_st_mode[755:0])
   ,.cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable[251:0])
   ,.cfg_interrupt_msix_vf_mask(cfg_interrupt_msix_vf_mask[251:0])
   ,.cfg_flr_in_process(cfg_flr_in_process[3:0])
   ,.cfg_req_pm_transition_l23_ready(cfg_req_pm_transition_l23_ready)
   ,.cfg_link_training_enable(cfg_link_training_enable)
   ,.cfg_interrupt_int(cfg_interrupt_int[3:0])
   ,.cfg_interrupt_sent(cfg_interrupt_sent)
   ,.cfg_interrupt_pending(cfg_interrupt_pending[3:0])
   ,.cfg_interrupt_msi_enable(cfg_interrupt_msi_enable[3:0])
   ,.cfg_interrupt_msi_int(cfg_interrupt_msi_int[31:0])
   ,.cfg_interrupt_msi_sent(cfg_interrupt_msi_sent)
   ,.cfg_interrupt_msi_fail(cfg_interrupt_msi_fail)
   ,.cfg_interrupt_msi_mmenable(cfg_interrupt_msi_mmenable[11:0])
   ,.cfg_interrupt_msi_pending_status(cfg_interrupt_msi_pending_status[31:0])
   ,.cfg_interrupt_msi_pending_status_function_num(cfg_interrupt_msi_pending_status_function_num[1:0])
   ,.cfg_interrupt_msi_pending_status_data_enable(cfg_interrupt_msi_pending_status_data_enable)
   ,.cfg_interrupt_msi_mask_update(cfg_interrupt_msi_mask_update)
   ,.cfg_interrupt_msi_select(cfg_interrupt_msi_select[1:0])
   ,.cfg_interrupt_msi_data(cfg_interrupt_msi_data[31:0])
   ,.cfg_interrupt_msix_enable(cfg_interrupt_msix_enable[3:0])
   ,.cfg_interrupt_msix_mask(cfg_interrupt_msix_mask[3:0])
   ,.cfg_interrupt_msix_address(cfg_interrupt_msix_address[63:0])
   ,.cfg_interrupt_msix_data(cfg_interrupt_msix_data[31:0])
   ,.cfg_interrupt_msix_int(cfg_interrupt_msix_int)
   ,.cfg_interrupt_msix_vec_pending(cfg_interrupt_msix_vec_pending[1:0])
   ,.cfg_interrupt_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status)
   ,.cfg_interrupt_msi_attr(cfg_interrupt_msi_attr[2:0])
   ,.cfg_interrupt_msi_tph_present(cfg_interrupt_msi_tph_present)
   ,.cfg_interrupt_msi_tph_type(cfg_interrupt_msi_tph_type[1:0])
   ,.cfg_interrupt_msi_tph_st_tag(cfg_interrupt_msi_tph_st_tag[7:0])
   ,.cfg_interrupt_msi_function_number(cfg_interrupt_msi_function_number[7:0])
   ,.cfg_ext_read_received(cfg_ext_read_received)
   ,.cfg_ext_write_received(cfg_ext_write_received)
   ,.cfg_ext_register_number(cfg_ext_register_number[9:0])
   ,.cfg_ext_function_number(cfg_ext_function_number[7:0])
   ,.cfg_ext_write_data(cfg_ext_write_data[31:0])
   ,.cfg_ext_write_byte_enable(cfg_ext_write_byte_enable[3:0])
   ,.cfg_ext_read_data(cfg_ext_read_data[31:0])
   ,.cfg_ext_read_data_valid(cfg_ext_read_data_valid)
   ,.cfg_pm_aspm_l1_entry_reject(cfg_pm_aspm_l1_entry_reject)
   ,.cfg_pm_aspm_tx_l0s_entry_disable(cfg_pm_aspm_tx_l0s_entry_disable)
   ,.conf_req_type(conf_req_type[1:0])
   ,.conf_req_reg_num(conf_req_reg_num[3:0])
   ,.conf_req_data(conf_req_data[31:0])
   ,.conf_req_valid(conf_req_valid)
   ,.conf_req_ready(conf_req_ready)
   ,.conf_resp_rdata(conf_resp_rdata[31:0])
   ,.conf_resp_valid(conf_resp_valid)
/*
   ,.conf_mcap_design_switch(conf_mcap_design_switch)
   ,.conf_mcap_eos(conf_mcap_eos)
   ,.conf_mcap_in_use_by_pcie(conf_mcap_in_use_by_pcie)
   ,.conf_mcap_request_by_conf(conf_mcap_request_by_conf)
   ,.dbg_data0_out(dbg_data0_out)
   ,.dbg_ctrl0_out(dbg_ctrl0_out)
   ,.dbg_sel0(dbg_sel0)
   ,.dbg_data1_out(dbg_data1_out)
   ,.dbg_ctrl1_out(dbg_ctrl1_out)
   ,.dbg_sel1(dbg_sel1)

   ,.scanmode_n(scanmode_n)
   ,.scanenable_n(scanenable_n)
   ,.scanin(scanin[149:0])
   ,.scanout(scanout[149:0])
   ,.pcie_perst0_b(pcie_perst0_b)
   ,.pcie_perst1_b(pcie_perst1_b)
   ,.pmv_enable_n(pmv_enable_n)
   ,.pmv_select(pmv_select [2:0])
   ,.pmv_divide(pmv_divide[1:0])
   ,.pmv_out(pmv_out)
   ,.user_spare_in(user_spare_in[31:0])
   ,.user_spare_out(user_spare_out[31:0])
   ,.drp_clk(drp_clk)
   ,.drp_en(drp_en)
   ,.drp_we(drp_we)
   ,.drp_addr(drp_addr[9:0])
   ,.drp_di(drp_di[15:0])
   ,.drp_rdy(drp_rdy)
   ,.drp_do(drp_do[15:0])
*/

   ,.user_clk(user_clk)
   ,.user_reset(user_reset)
   ,.user_lnk_up(user_lnk_up)
   ,.sys_clk(sys_clk)
   ,.sys_clk_gt(sys_clk_gt)
   ,.sys_reset(sys_reset)
   ,.pci_exp_rxp(pci_exp_rxp)
   ,.pci_exp_rxn(pci_exp_rxn)
   ,.pci_exp_txp(pci_exp_txp)
   ,.pci_exp_txn(pci_exp_txn)

  );

endmodule

