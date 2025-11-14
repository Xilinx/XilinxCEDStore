# Hierarchical cell: qdma_0_support
proc create_hier_cell_qdma_0_support { parentCell nameHier } {


  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_qdma_0_support() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_mgt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_cq

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_rc

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.1 pcie_cfg_fc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie_cfg_interrupt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie_cfg_mesg_rcvd

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_cfg_mesg_tx_rtl:1.0 pcie_cfg_mesg_tx

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_cc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_rq

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie5_cfg_control_rtl:1.0 pcie_cfg_control

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie_cfg_mgmt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie5_cfg_status_rtl:1.0 pcie_cfg_status

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie_transmit_fc


  # Create pins
  create_bd_pin -dir I -type rst sys_reset
  create_bd_pin -dir O phy_rdy_out
  create_bd_pin -dir O -type clk user_clk
  create_bd_pin -dir O user_lnk_up
  create_bd_pin -dir O -type rst user_reset
  create_bd_pin -dir O -from 5 -to 0 pcie_ltssm_state

  # Create instance: bufg_gt_sysclk, and set properties
  set bufg_gt_sysclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf bufg_gt_sysclk ]
  set_property -dict [list \
    CONFIG.C_BUFG_GT_SYNC {true} \
    CONFIG.C_BUF_TYPE {BUFG_GT} \
  ] $bufg_gt_sysclk


  # Create instance: ilconstant_1, and set properties
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_1 ]

  # Create instance: pcie_phy, and set properties
  set pcie_phy [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_phy_versal pcie_phy ]
  set_property -dict [list \
    CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {32.0_GT/s} \
    CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
    CONFIG.aspm {No_ASPM} \
    CONFIG.async_mode {SRNS} \
    CONFIG.disable_double_pipe {YES} \
    CONFIG.en_gt_pclk {false} \
    CONFIG.enable_gtwizard {true} \
    CONFIG.ins_loss_profile {Add-in_Card} \
    CONFIG.lane_order {Bottom} \
    CONFIG.lane_reversal {false} \
    CONFIG.phy_async_en {true} \
    CONFIG.phy_coreclk_freq {500_MHz} \
    CONFIG.phy_refclk_freq {100_MHz} \
    CONFIG.phy_userclk2_freq {250_MHz} \
    CONFIG.phy_userclk_freq {250_MHz} \
    CONFIG.pipeline_stages {4} \
    CONFIG.sim_model {NO} \
    CONFIG.tx_preset {4} \
  ] $pcie_phy


  # Create instance: pcie, and set properties
  set pcie [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_versal pcie ]
  set_property -dict [list \
    CONFIG.AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned} \
    CONFIG.AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
    CONFIG.PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE {false} \
    CONFIG.PF0_DEVICE_ID {B0D4} \
    CONFIG.PF0_INTERRUPT_PIN {INTA} \
    CONFIG.PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {true} \
    CONFIG.PF0_REVISION_ID {00} \
    CONFIG.PF0_SRIOV_VF_DEVICE_ID {C034} \
    CONFIG.PF0_SUBSYSTEM_ID {0007} \
    CONFIG.PF1_DEVICE_ID {913F} \
    CONFIG.PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF1_REVISION_ID {00} \
    CONFIG.PF1_SUBSYSTEM_ID {0007} \
    CONFIG.PF1_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF2_DEVICE_ID {B2D4} \
    CONFIG.PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF2_REVISION_ID {00} \
    CONFIG.PF2_SUBSYSTEM_ID {0007} \
    CONFIG.PF2_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF3_DEVICE_ID {B3D4} \
    CONFIG.PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF3_REVISION_ID {00} \
    CONFIG.PF3_SUBSYSTEM_ID {0007} \
    CONFIG.PF3_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF4_DEVICE_ID {B4D4} \
    CONFIG.PF5_DEVICE_ID {B5D4} \
    CONFIG.PF6_DEVICE_ID {B6D4} \
    CONFIG.PF7_DEVICE_ID {B7D4} \
    CONFIG.PL_DISABLE_LANE_REVERSAL {TRUE} \
    CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {32.0_GT/s} \
    CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
    CONFIG.REF_CLK_FREQ {100_MHz} \
    CONFIG.acs_ext_cap_enable {false} \
    CONFIG.all_speeds_all_sides {NO} \
    CONFIG.axisten_freq {250} \
    CONFIG.axisten_if_enable_client_tag {true} \
    CONFIG.axisten_if_enable_msg_route_override {TRUE} \
    CONFIG.axisten_if_width {512_bit} \
    CONFIG.cfg_ext_if {false} \
    CONFIG.cfg_mgmt_if {true} \
    CONFIG.copy_pf0 {true} \
    CONFIG.coreclk_freq {500} \
    CONFIG.dedicate_perst {false} \
    CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.en_dbg_descramble {false} \
    CONFIG.en_ext_clk {FALSE} \
    CONFIG.en_l23_entry {false} \
    CONFIG.en_parity {false} \
    CONFIG.en_transceiver_status_ports {false} \
    CONFIG.enable_auto_rxeq {False} \
    CONFIG.enable_ccix {FALSE} \
    CONFIG.enable_dvsec {FALSE} \
    CONFIG.enable_gen4 {true} \
    CONFIG.enable_gtwizard {true} \
    CONFIG.enable_ibert {false} \
    CONFIG.enable_jtag_dbg {false} \
    CONFIG.enable_more_clk {false} \
    CONFIG.ext_pcie_cfg_space_enabled {false} \
    CONFIG.extended_tag_field {true} \
    CONFIG.insert_cips {false} \
    CONFIG.lane_order {Bottom} \
    CONFIG.legacy_ext_pcie_cfg_space_enabled {false} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.pcie_blk_locn {X1Y0} \
    CONFIG.pcie_link_debug {false} \
    CONFIG.pcie_link_debug_axi4_st {false} \
    CONFIG.pf0_ari_enabled {false} \
    CONFIG.pf0_bar0_64bit {true} \
    CONFIG.pf0_bar0_enabled {true} \
    CONFIG.pf0_bar0_prefetchable {false} \
    CONFIG.pf0_bar0_scale {Terabytes} \
    CONFIG.pf0_bar0_size {16} \
    CONFIG.pf0_bar2_64bit {true} \
    CONFIG.pf0_bar2_enabled {true} \
    CONFIG.pf0_bar2_prefetchable {false} \
    CONFIG.pf0_bar2_scale {Kilobytes} \
    CONFIG.pf0_bar2_size {4} \
    CONFIG.pf0_bar2_type {Memory} \
    CONFIG.pf0_bar4_enabled {false} \
    CONFIG.pf0_base_class_menu {Bridge_device} \
    CONFIG.pf0_class_code_base {06} \
    CONFIG.pf0_class_code_interface {00} \
    CONFIG.pf0_class_code_sub {0A} \
    CONFIG.pf0_expansion_rom_enabled {false} \
    CONFIG.pf0_msi_enabled {false} \
    CONFIG.pf0_msix_enabled {false} \
    CONFIG.pf0_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf0_vc_cap_enabled {true} \
    CONFIG.pf1_base_class_menu {Bridge_device} \
    CONFIG.pf1_class_code_base {06} \
    CONFIG.pf1_class_code_interface {00} \
    CONFIG.pf1_class_code_sub {0A} \
    CONFIG.pf1_msix_enabled {false} \
    CONFIG.pf1_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf1_vendor_id {10EE} \
    CONFIG.pf2_base_class_menu {Bridge_device} \
    CONFIG.pf2_class_code_base {06} \
    CONFIG.pf2_class_code_interface {00} \
    CONFIG.pf2_class_code_sub {0A} \
    CONFIG.pf2_msix_enabled {false} \
    CONFIG.pf2_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf2_vendor_id {10EE} \
    CONFIG.pf3_base_class_menu {Bridge_device} \
    CONFIG.pf3_class_code_base {06} \
    CONFIG.pf3_class_code_interface {00} \
    CONFIG.pf3_class_code_sub {0A} \
    CONFIG.pf3_msix_enabled {false} \
    CONFIG.pf3_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf3_vendor_id {10EE} \
    CONFIG.pf4_base_class_menu {Bridge_device} \
    CONFIG.pf4_class_code_base {06} \
    CONFIG.pf4_class_code_sub {0A} \
    CONFIG.pf4_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf5_base_class_menu {Bridge_device} \
    CONFIG.pf5_class_code_base {06} \
    CONFIG.pf5_class_code_sub {0A} \
    CONFIG.pf5_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf6_base_class_menu {Bridge_device} \
    CONFIG.pf6_class_code_base {06} \
    CONFIG.pf6_class_code_sub {0A} \
    CONFIG.pf6_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf7_base_class_menu {Bridge_device} \
    CONFIG.pf7_class_code_base {06} \
    CONFIG.pf7_class_code_sub {0A} \
    CONFIG.pf7_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pipe_line_stage {2} \
    CONFIG.pipe_sim {false} \
    CONFIG.replace_uram_with_bram {false} \
    CONFIG.sys_reset_polarity {ACTIVE_LOW} \
    CONFIG.type1_membase_memlimit_enable {Enabled} \
    CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
    CONFIG.vendor_id {10EE} \
    CONFIG.warm_reboot_sbr_fix {false} \
    CONFIG.xlnx_ref_board {VPK120} \
  ] $pcie


  # Create instance: gtwiz_versal_0, and set properties
  set gtwiz_versal_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gtwiz_versal gtwiz_versal_0 ]
  set_property -dict [list \
    CONFIG.GT_TYPE {GTYP} \
    CONFIG.INTF0_GT_SETTINGS(GT_DIRECTION) {DUPLEX} \
    CONFIG.INTF0_GT_SETTINGS(GT_TYPE) {GTYP} \
    CONFIG.INTF0_GT_SETTINGS(LR0_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 8B10B TX_LINE_RATE 2.5 TX_USER_DATA_WIDTH 16 TX_INT_DATA_WIDTH 20 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE LPM RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 8B10B RX_LINE_RATE 2.5 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 16 RX_INT_DATA_WIDTH\
20 RX_REFCLK_FREQUENCY 100} \
    CONFIG.INTF0_GT_SETTINGS(LR1_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 8B10B TX_LINE_RATE 5.0 TX_USER_DATA_WIDTH 16 TX_INT_DATA_WIDTH 20 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE LPM RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 8B10B RX_LINE_RATE 5.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 16 RX_INT_DATA_WIDTH\
20 RX_REFCLK_FREQUENCY 100} \
    CONFIG.INTF0_GT_SETTINGS(LR2_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 8.0 TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 8.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH\
32 RX_REFCLK_FREQUENCY 100} \
    CONFIG.INTF0_GT_SETTINGS(LR3_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 16.0 TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
250 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 16.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH\
32 RX_REFCLK_FREQUENCY 100} \
    CONFIG.INTF0_GT_SETTINGS(LR4_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 32.0 TX_USER_DATA_WIDTH 64 TX_INT_DATA_WIDTH 64 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
250 TX_ACTUAL_REFCLK_FREQUENCY 100.0 TX_FRACN_ENABLED false TX_FRACN_NUMERATOR 0 TX_PIPM_ENABLE false TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_BUFFER_RESET_ON_RATE_CHANGE\
ENABLE PRESET None INTERNAL_PRESET None OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 false RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE\
ENABLE RX_COMMA_ALIGN_WORD 1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false\
RX_JTOL_FC 1 RX_PLL_TYPE LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 32.0 RX_PPM_OFFSET 0\
RX_USER_DATA_WIDTH 64 RX_INT_DATA_WIDTH 64 RX_REFCLK_FREQUENCY 100 RESET_SEQUENCE_INTERVAL 0 RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 322.265625 RX_64B66B_CRC false RX_64B66B_DECODER false RX_64B66B_DESCRAMBLER\
false RX_ACTUAL_REFCLK_FREQUENCY 100.0 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE\
ENABLE RX_CB_DISP 00000000 RX_CB_DISP_0_0 false RX_CB_DISP_0_1 false RX_CB_DISP_0_2 false RX_CB_DISP_0_3 false RX_CB_DISP_1_0 false RX_CB_DISP_1_1 false RX_CB_DISP_1_2 false RX_CB_DISP_1_3 false RX_CB_K\
00000000 RX_CB_K_0_0 false RX_CB_K_0_1 false RX_CB_K_0_2 false RX_CB_K_0_3 false RX_CB_K_1_0 false RX_CB_K_1_1 false RX_CB_K_1_2 false RX_CB_K_1_3 false RX_CB_LEN_SEQ 1 RX_CB_MASK 00000000 RX_CB_MASK_0_0\
false RX_CB_MASK_0_1 false RX_CB_MASK_0_2 false RX_CB_MASK_0_3 false RX_CB_MASK_1_0 false RX_CB_MASK_1_1 false RX_CB_MASK_1_2 false RX_CB_MASK_1_3 false RX_CB_MAX_LEVEL 1 RX_CB_MAX_SKEW 1 RX_CB_NUM_SEQ\
0 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_VAL_0_0 00000000 RX_CB_VAL_0_1 00000000 RX_CB_VAL_0_2 00000000 RX_CB_VAL_0_3 00000000 RX_CB_VAL_1_0 00000000\
RX_CB_VAL_1_1 00000000 RX_CB_VAL_1_2 00000000 RX_CB_VAL_1_3 00000000 RX_CC_DISP 00000000 RX_CC_DISP_0_0 false RX_CC_DISP_0_1 false RX_CC_DISP_0_2 false RX_CC_DISP_0_3 false RX_CC_DISP_1_0 false RX_CC_DISP_1_1\
false RX_CC_DISP_1_2 false RX_CC_DISP_1_3 false RX_CC_K 00000000 RX_CC_K_0_1 false RX_CC_K_0_2 false RX_CC_K_0_3 false RX_CC_K_1_0 false RX_CC_K_1_1 false RX_CC_K_1_2 false RX_CC_K_1_3 false RX_CC_MASK\
00000000 RX_CC_MASK_0_1 false RX_CC_MASK_0_2 false RX_CC_MASK_0_3 false RX_CC_MASK_1_0 false RX_CC_MASK_1_1 false RX_CC_MASK_1_2 false RX_CC_MASK_1_3 false RX_CC_PERIODICITY 5000 RX_CC_PRECEDENCE ENABLE\
RX_CC_REPEAT_WAIT 0 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000011100 RX_CC_VAL_0_1 00000000 RX_CC_VAL_0_2 00000000 RX_CC_VAL_0_3 00000000 RX_CC_VAL_1_0 00000000\
RX_CC_VAL_1_1 00000000 RX_CC_VAL_1_2 00000000 RX_CC_VAL_1_3 00000000 RX_COMMA_SHOW_REALIGN_ENABLE true RX_COMMA_VALID_ONLY 0 RX_COUPLING AC RX_FRACN_ENABLED false RX_FRACN_NUMERATOR 0 RX_JTOL_LF_SLOPE\
-20 RX_RATE_GROUP A RX_TERMINATION PROGRAMMABLE RX_TERMINATION_PROG_VALUE 800} \
    CONFIG.INTF0_PARENTID {design_1_pcie_phy_0} \
    CONFIG.INTF0_PCIE_ENABLE {true} \
    CONFIG.INTF_PARENT_PIN_LIST {QUAD0_RX0 /qdma_0_support/pcie_phy/GT_RX0 QUAD0_RX1 /qdma_0_support/pcie_phy/GT_RX1 QUAD0_RX2 /qdma_0_support/pcie_phy/GT_RX2 QUAD0_RX3 /qdma_0_support/pcie_phy/GT_RX3\
QUAD0_TX0 /qdma_0_support/pcie_phy/GT_TX0 QUAD0_TX1 /qdma_0_support/pcie_phy/GT_TX1 QUAD0_TX2 /qdma_0_support/pcie_phy/GT_TX2 QUAD0_TX3 /qdma_0_support/pcie_phy/GT_TX3} \
    CONFIG.QUAD0_CH0_PCIERSTB_EN {true} \
    CONFIG.QUAD0_CH0_PHYREADY_EN {true} \
    CONFIG.QUAD0_CH0_PHYSTATUS_EN {true} \
    CONFIG.QUAD0_CH1_PCIERSTB_EN {true} \
    CONFIG.QUAD0_CH1_PHYREADY_EN {true} \
    CONFIG.QUAD0_CH1_PHYSTATUS_EN {true} \
    CONFIG.QUAD0_CH2_PCIERSTB_EN {true} \
    CONFIG.QUAD0_CH2_PHYREADY_EN {true} \
    CONFIG.QUAD0_CH2_PHYSTATUS_EN {true} \
    CONFIG.QUAD0_CH3_PCIERSTB_EN {true} \
    CONFIG.QUAD0_CH3_PHYREADY_EN {true} \
    CONFIG.QUAD0_CH3_PHYSTATUS_EN {true} \
    CONFIG.QUAD0_GT0_BUFGT_EN {true} \
    CONFIG.QUAD0_GT1_BUFGT_EN {true} \
    CONFIG.QUAD0_GT2_BUFGT_EN {true} \
    CONFIG.QUAD0_GT3_BUFGT_EN {true} \
    CONFIG.QUAD0_GT_RXMARGIN_INTF_EN {true} \
    CONFIG.QUAD0_OUTCLK_VALUES {CH0_TXOUTCLK 500.000 CH0_RXOUTCLK 500.000000 CH1_TXOUTCLK 500.000 CH1_RXOUTCLK 500.000000 CH2_TXOUTCLK 500.000 CH2_RXOUTCLK 500.000000 CH3_TXOUTCLK 500.000 CH3_RXOUTCLK\
500.000000} \
    CONFIG.QUAD0_PCIELTSSM_EN {true} \
    CONFIG.QUAD0_REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK0_RPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_RPLLGTREFCLK0\
refclk_PROT0_R0_100_MHz_unique1} \
    CONFIG.QUAD0_USAGE {TX_QUAD_CH {TXQuad_0_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 design_1_pcie_phy_0.IP_CH0,design_1_pcie_phy_0.IP_CH1,design_1_pcie_phy_0.IP_CH2,design_1_pcie_phy_0.IP_CH3\
MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 design_1_pcie_phy_0.IP_CH0,design_1_pcie_phy_0.IP_CH1,design_1_pcie_phy_0.IP_CH2,design_1_pcie_phy_0.IP_CH3\
MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1}}} \
  ] $gtwiz_versal_0

  set_property -dict [list \
    CONFIG.INTF0_PARENTID.VALUE_MODE {auto} \
    CONFIG.INTF_PARENT_PIN_LIST.VALUE_MODE {auto} \
    CONFIG.QUAD0_USAGE.VALUE_MODE {auto} \
  ] $gtwiz_versal_0


  # Create instance: refclk_ibuf, and set properties
  set refclk_ibuf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf refclk_ibuf ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $refclk_ibuf


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins refclk_ibuf/CLK_IN_D] [get_bd_intf_pins pcie_refclk]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins pcie_phy/pcie_mgt] [get_bd_intf_pins pcie_mgt]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins pcie/m_axis_cq] [get_bd_intf_pins m_axis_cq]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins pcie/m_axis_rc] [get_bd_intf_pins m_axis_rc]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins pcie/pcie_cfg_fc] [get_bd_intf_pins pcie_cfg_fc]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins pcie/pcie_cfg_interrupt] [get_bd_intf_pins pcie_cfg_interrupt]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins pcie/pcie_cfg_mesg_rcvd] [get_bd_intf_pins pcie_cfg_mesg_rcvd]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins pcie/pcie_cfg_mesg_tx] [get_bd_intf_pins pcie_cfg_mesg_tx]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins pcie/s_axis_cc] [get_bd_intf_pins s_axis_cc]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins pcie/s_axis_rq] [get_bd_intf_pins s_axis_rq]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins pcie/pcie_cfg_control] [get_bd_intf_pins pcie_cfg_control]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins pcie/pcie_cfg_mgmt] [get_bd_intf_pins pcie_cfg_mgmt]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins pcie/pcie_cfg_status] [get_bd_intf_pins pcie_cfg_status]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins pcie/pcie_transmit_fc] [get_bd_intf_pins pcie_transmit_fc]
  connect_bd_intf_net -intf_net gt_quad_0_GT0_BUFGT [get_bd_intf_pins pcie_phy/GT_BUFGT] [get_bd_intf_pins gtwiz_versal_0/Quad0_GT0_BUFGT]
  connect_bd_intf_net -intf_net gt_quad_0_GT_Serial [get_bd_intf_pins pcie_phy/GT0_Serial] [get_bd_intf_pins gtwiz_versal_0/Quad0_GT_Serial]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX0 [get_bd_intf_pins pcie_phy/GT_RX0] [get_bd_intf_pins gtwiz_versal_0/INTF0_RX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX1 [get_bd_intf_pins pcie_phy/GT_RX1] [get_bd_intf_pins gtwiz_versal_0/INTF0_RX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX2 [get_bd_intf_pins pcie_phy/GT_RX2] [get_bd_intf_pins gtwiz_versal_0/INTF0_RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX3 [get_bd_intf_pins pcie_phy/GT_RX3] [get_bd_intf_pins gtwiz_versal_0/INTF0_RX3_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX0 [get_bd_intf_pins pcie_phy/GT_TX0] [get_bd_intf_pins gtwiz_versal_0/INTF0_TX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX1 [get_bd_intf_pins pcie_phy/GT_TX1] [get_bd_intf_pins gtwiz_versal_0/INTF0_TX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX2 [get_bd_intf_pins pcie_phy/GT_TX2] [get_bd_intf_pins gtwiz_versal_0/INTF0_TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX3 [get_bd_intf_pins pcie_phy/GT_TX3] [get_bd_intf_pins gtwiz_versal_0/INTF0_TX3_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_gt_rxmargin_q0 [get_bd_intf_pins pcie_phy/gt_rxmargin_q0] [get_bd_intf_pins gtwiz_versal_0/QUAD0_GT_RXMARGIN_INTF]
  connect_bd_intf_net -intf_net pcie_phy_mac_rx [get_bd_intf_pins pcie_phy/phy_mac_rx] [get_bd_intf_pins pcie/phy_mac_rx]
  connect_bd_intf_net -intf_net pcie_phy_mac_tx [get_bd_intf_pins pcie_phy/phy_mac_tx] [get_bd_intf_pins pcie/phy_mac_tx]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_command [get_bd_intf_pins pcie_phy/phy_mac_command] [get_bd_intf_pins pcie/phy_mac_command]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_rx_margining [get_bd_intf_pins pcie_phy/phy_mac_rx_margining] [get_bd_intf_pins pcie/phy_mac_rx_margining]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_status [get_bd_intf_pins pcie_phy/phy_mac_status] [get_bd_intf_pins pcie/phy_mac_status]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_drive [get_bd_intf_pins pcie_phy/phy_mac_tx_drive] [get_bd_intf_pins pcie/phy_mac_tx_drive]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_eq [get_bd_intf_pins pcie_phy/phy_mac_tx_eq] [get_bd_intf_pins pcie/phy_mac_tx_eq]

  # Create port connections
  connect_bd_net -net bufg_gt_sysclk_BUFG_GT_O  [get_bd_pins bufg_gt_sysclk/BUFG_GT_O] \
  [get_bd_pins gtwiz_versal_0/gtwiz_freerun_clk] \
  [get_bd_pins pcie/sys_clk] \
  [get_bd_pins pcie_phy/phy_refclk]
  connect_bd_net -net gt_quad_0_ch0_phyready  [get_bd_pins gtwiz_versal_0/QUAD0_ch0_phyready] \
  [get_bd_pins pcie_phy/ch0_phyready]
  connect_bd_net -net gt_quad_0_ch0_phystatus  [get_bd_pins gtwiz_versal_0/QUAD0_ch0_phystatus] \
  [get_bd_pins pcie_phy/ch0_phystatus]
  connect_bd_net -net gt_quad_0_ch0_rxoutclk  [get_bd_pins gtwiz_versal_0/QUAD0_RX0_outclk] \
  [get_bd_pins pcie_phy/gt_rxoutclk]
  connect_bd_net -net gt_quad_0_ch0_txoutclk  [get_bd_pins gtwiz_versal_0/QUAD0_TX0_outclk] \
  [get_bd_pins pcie_phy/gt_txoutclk]
  connect_bd_net -net gt_quad_0_ch1_phyready  [get_bd_pins gtwiz_versal_0/QUAD0_ch1_phyready] \
  [get_bd_pins pcie_phy/ch1_phyready]
  connect_bd_net -net gt_quad_0_ch1_phystatus  [get_bd_pins gtwiz_versal_0/QUAD0_ch1_phystatus] \
  [get_bd_pins pcie_phy/ch1_phystatus]
  connect_bd_net -net gt_quad_0_ch2_phyready  [get_bd_pins gtwiz_versal_0/QUAD0_ch2_phyready] \
  [get_bd_pins pcie_phy/ch2_phyready]
  connect_bd_net -net gt_quad_0_ch2_phystatus  [get_bd_pins gtwiz_versal_0/QUAD0_ch2_phystatus] \
  [get_bd_pins pcie_phy/ch2_phystatus]
  connect_bd_net -net gt_quad_0_ch3_phyready  [get_bd_pins gtwiz_versal_0/QUAD0_ch3_phyready] \
  [get_bd_pins pcie_phy/ch3_phyready]
  connect_bd_net -net gt_quad_0_ch3_phystatus  [get_bd_pins gtwiz_versal_0/QUAD0_ch3_phystatus] \
  [get_bd_pins pcie_phy/ch3_phystatus]
  connect_bd_net -net pcie_pcie_ltssm_state  [get_bd_pins pcie/pcie_ltssm_state] \
  [get_bd_pins pcie_ltssm_state] \
  [get_bd_pins pcie_phy/pcie_ltssm_state]
  connect_bd_net -net pcie_phy_gt_pcieltssm  [get_bd_pins pcie_phy/gt_pcieltssm] \
  [get_bd_pins gtwiz_versal_0/QUAD0_pcieltssm]
  connect_bd_net -net pcie_phy_gtrefclk  [get_bd_pins pcie_phy/gtrefclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_GTREFCLK0]
  connect_bd_net -net pcie_phy_pcierstb  [get_bd_pins pcie_phy/pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch0_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch1_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch2_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch3_pcierstb]
  connect_bd_net -net pcie_phy_phy_coreclk  [get_bd_pins pcie_phy/phy_coreclk] \
  [get_bd_pins pcie/phy_coreclk]
  connect_bd_net -net pcie_phy_phy_mcapclk  [get_bd_pins pcie_phy/phy_mcapclk] \
  [get_bd_pins pcie/phy_mcapclk]
  connect_bd_net -net pcie_phy_phy_pclk  [get_bd_pins pcie_phy/phy_pclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_TX0_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_TX1_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_TX2_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_TX3_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_RX0_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_RX1_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_RX2_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_RX3_usrclk] \
  [get_bd_pins pcie/phy_pclk]
  connect_bd_net -net pcie_phy_phy_userclk  [get_bd_pins pcie_phy/phy_userclk] \
  [get_bd_pins pcie/phy_userclk]
  connect_bd_net -net pcie_phy_phy_userclk2  [get_bd_pins pcie_phy/phy_userclk2] \
  [get_bd_pins pcie/phy_userclk2]
  connect_bd_net -net pcie_phy_rdy_out  [get_bd_pins pcie/phy_rdy_out] \
  [get_bd_pins phy_rdy_out]
  connect_bd_net -net pcie_user_clk  [get_bd_pins pcie/user_clk] \
  [get_bd_pins user_clk]
  connect_bd_net -net pcie_user_lnk_up  [get_bd_pins pcie/user_lnk_up] \
  [get_bd_pins user_lnk_up]
  connect_bd_net -net pcie_user_reset  [get_bd_pins pcie/user_reset] \
  [get_bd_pins user_reset]
  connect_bd_net -net refclk_ibuf_IBUF_DS_ODIV2  [get_bd_pins refclk_ibuf/IBUF_DS_ODIV2] \
  [get_bd_pins bufg_gt_sysclk/BUFG_GT_I]
  connect_bd_net -net refclk_ibuf_IBUF_OUT  [get_bd_pins refclk_ibuf/IBUF_OUT] \
  [get_bd_pins pcie/sys_clk_gt] \
  [get_bd_pins pcie_phy/phy_gtrefclk]
  connect_bd_net -net sys_reset_1  [get_bd_pins sys_reset] \
  [get_bd_pins pcie/sys_reset] \
  [get_bd_pins pcie_phy/phy_rst_n]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins bufg_gt_sysclk/BUFG_GT_CE]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {



  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Create interface ports
  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]

  set pcie_mgt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_mgt ]

  set CH0_LPDDR4_0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 CH0_LPDDR4_0_0 ]

  set CH1_LPDDR4_0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 CH1_LPDDR4_0_0 ]

  set sys_clk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $sys_clk0_0


  # Create ports

  # Create instance: qdma_0_support
  create_hier_cell_qdma_0_support [current_bd_instance .] qdma_0_support

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]
  set_property -dict [list \
    CONFIG.C_AUX_RESET_HIGH {0} \
    CONFIG.C_EXT_RST_WIDTH {4} \
  ] $proc_sys_reset_0


  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.CPM_CONFIG { \
      CPM_PCIE0_MODES {None} \
    } \
    CONFIG.DDR_MEMORY_MODE {Custom} \
    CONFIG.IO_CONFIG_MODE {Custom} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Custom} \
      DESIGN_MODE {1} \
      IO_CONFIG_MODE {Custom} \
      PMC_CRP_CFU_REF_CTRL_FREQMHZ {0.000000} \
      PMC_CRP_NOC_REF_CTRL_FREQMHZ {1000.000000} \
      PMC_CRP_PL0_REF_CTRL_DIVISOR0 {4} \
      PMC_CRP_PL0_REF_CTRL_SRCSEL {NPLL} \
      PMC_CRP_PL1_REF_CTRL_SRCSEL {NPLL} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PSPMC_MANUAL_CLK_ENABLE {1} \
      PS_BOARD_INTERFACE {Custom} \
      PS_CRF_ACPU_CTRL_FREQMHZ {0.000000} \
      PS_CRF_ACPU_CTRL_SRCSEL {APLL} \
      PS_CRF_FPD_LSBUS_CTRL_FREQMHZ {0.000000} \
      PS_CRF_FPD_TOP_SWITCH_CTRL_FREQMHZ {0.000000} \
      PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {0.000000} \
      PS_CRL_CPU_R5_CTRL_FREQMHZ {0.000000} \
      PS_CRL_LPD_TOP_SWITCH_CTRL_FREQMHZ {0.000000} \
      PS_CRL_UART0_REF_CTRL_FREQMHZ {0.000000} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 1} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
      PS_M_AXI_FPD_DATA_WIDTH {128} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USE_BSCAN_USER1 {1} \
      PS_USE_FPD_AXI_NOC0 {1} \
      PS_USE_FPD_AXI_NOC1 {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_M_AXI_FPD {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_FPD_AXI0 {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
    CONFIG.PS_PMC_CONFIG_APPLIED {1} \
  ] $versal_cips_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.ADVANCED_PROPERTIES {} \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_1 ]
  set_property -dict [list \
    CONFIG.ADVANCED_PROPERTIES {} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_1


  # Create instance: smartconnect_2, and set properties
  set smartconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_2 ]
  set_property -dict [list \
    CONFIG.ADVANCED_PROPERTIES {} \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_2


  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc axi_noc_0 ]
  set_property -dict [list \
    CONFIG.CONTROLLERTYPE {LPDDR4_SDRAM} \
    CONFIG.HBM_CHNL0_CONFIG {} \
    CONFIG.MC0_CONFIG_NUM {config26} \
    CONFIG.MC0_FLIPPED_PINOUT {true} \
    CONFIG.MC1_CONFIG_NUM {config26} \
    CONFIG.MC2_CONFIG_NUM {config26} \
    CONFIG.MC3_CONFIG_NUM {config26} \
    CONFIG.MC_ADDR_WIDTH {6} \
    CONFIG.MC_ADD_CMD_DELAY_EN {Disable} \
    CONFIG.MC_BURST_LENGTH {16} \
    CONFIG.MC_CASLATENCY {28} \
    CONFIG.MC_CASWRITELATENCY {14} \
    CONFIG.MC_CH0_LP4_CHA_ENABLE {true} \
    CONFIG.MC_CH0_LP4_CHB_ENABLE {true} \
    CONFIG.MC_CH1_LP4_CHA_ENABLE {true} \
    CONFIG.MC_CH1_LP4_CHB_ENABLE {true} \
    CONFIG.MC_CHANNEL_INTERLEAVING {true} \
    CONFIG.MC_CHAN_REGION1 {DDR_CH1} \
    CONFIG.MC_CH_INTERLEAVING_SIZE {64_Bytes} \
    CONFIG.MC_CKE_WIDTH {0} \
    CONFIG.MC_CK_WIDTH {0} \
    CONFIG.MC_COMPONENT_DENSITY {16Gb} \
    CONFIG.MC_COMPONENT_WIDTH {x32} \
    CONFIG.MC_CONFIG_NUM {config26} \
    CONFIG.MC_DATAWIDTH {32} \
    CONFIG.MC_DM_WIDTH {4} \
    CONFIG.MC_DQS_WIDTH {4} \
    CONFIG.MC_DQ_WIDTH {32} \
    CONFIG.MC_ECC {false} \
    CONFIG.MC_ECC_SCRUB_SIZE {4096} \
    CONFIG.MC_F1_CASLATENCY {28} \
    CONFIG.MC_F1_CASWRITELATENCY {14} \
    CONFIG.MC_F1_LPDDR4_MR1 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR11 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR13 {0x00C0} \
    CONFIG.MC_F1_LPDDR4_MR2 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR22 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR3 {0x0000} \
    CONFIG.MC_F1_TCCD_L {0} \
    CONFIG.MC_F1_TCCD_L_MIN {0} \
    CONFIG.MC_F1_TFAW {40000} \
    CONFIG.MC_F1_TFAWMIN {40000} \
    CONFIG.MC_F1_TMOD {0} \
    CONFIG.MC_F1_TMOD_MIN {0} \
    CONFIG.MC_F1_TMRD {14000} \
    CONFIG.MC_F1_TMRDMIN {14000} \
    CONFIG.MC_F1_TMRW {10000} \
    CONFIG.MC_F1_TMRWMIN {10000} \
    CONFIG.MC_F1_TRAS {42000} \
    CONFIG.MC_F1_TRASMIN {42000} \
    CONFIG.MC_F1_TRCD {18000} \
    CONFIG.MC_F1_TRCDMIN {18000} \
    CONFIG.MC_F1_TRPAB {21000} \
    CONFIG.MC_F1_TRPABMIN {21000} \
    CONFIG.MC_F1_TRPPB {18000} \
    CONFIG.MC_F1_TRPPBMIN {18000} \
    CONFIG.MC_F1_TRRD {10000} \
    CONFIG.MC_F1_TRRDMIN {10000} \
    CONFIG.MC_F1_TRRD_L {0} \
    CONFIG.MC_F1_TRRD_L_MIN {0} \
    CONFIG.MC_F1_TRRD_S {0} \
    CONFIG.MC_F1_TRRD_S_MIN {0} \
    CONFIG.MC_F1_TWR {18000} \
    CONFIG.MC_F1_TWRMIN {18000} \
    CONFIG.MC_F1_TWTR {10000} \
    CONFIG.MC_F1_TWTRMIN {10000} \
    CONFIG.MC_F1_TWTR_L {0} \
    CONFIG.MC_F1_TWTR_L_MIN {0} \
    CONFIG.MC_F1_TWTR_S {0} \
    CONFIG.MC_F1_TWTR_S_MIN {0} \
    CONFIG.MC_F1_TZQLAT {30000} \
    CONFIG.MC_F1_TZQLATMIN {30000} \
    CONFIG.MC_INPUTCLK0_PERIOD {5000} \
    CONFIG.MC_LP4_CA_A_WIDTH {6} \
    CONFIG.MC_LP4_CA_B_WIDTH {6} \
    CONFIG.MC_LP4_CKE_A_WIDTH {1} \
    CONFIG.MC_LP4_CKE_B_WIDTH {1} \
    CONFIG.MC_LP4_CKT_A_WIDTH {1} \
    CONFIG.MC_LP4_CKT_B_WIDTH {1} \
    CONFIG.MC_LP4_CS_A_WIDTH {1} \
    CONFIG.MC_LP4_CS_B_WIDTH {1} \
    CONFIG.MC_LP4_DMI_A_WIDTH {2} \
    CONFIG.MC_LP4_DMI_B_WIDTH {2} \
    CONFIG.MC_LP4_DQS_A_WIDTH {2} \
    CONFIG.MC_LP4_DQS_B_WIDTH {2} \
    CONFIG.MC_LP4_DQ_A_WIDTH {16} \
    CONFIG.MC_LP4_DQ_B_WIDTH {16} \
    CONFIG.MC_LP4_RESETN_WIDTH {1} \
    CONFIG.MC_MEMORY_SPEEDGRADE {LPDDR4X-3200} \
    CONFIG.MC_MEMORY_TIMEPERIOD0 {625} \
    CONFIG.MC_NO_CHANNELS {Dual} \
    CONFIG.MC_ODTLon {6} \
    CONFIG.MC_ODT_WIDTH {0} \
    CONFIG.MC_PER_RD_INTVL {0} \
    CONFIG.MC_PRE_DEF_ADDR_MAP_SEL {ROW_BANK_COLUMN} \
    CONFIG.MC_READ_BANDWIDTH {6400.0} \
    CONFIG.MC_SKIPCAL {Disable} \
    CONFIG.MC_TCCD {8} \
    CONFIG.MC_TCCD_L {0} \
    CONFIG.MC_TCCD_L_MIN {0} \
    CONFIG.MC_TCKE {12} \
    CONFIG.MC_TCKEMIN {12} \
    CONFIG.MC_TDQS2DQ_MAX {800} \
    CONFIG.MC_TDQS2DQ_MIN {200} \
    CONFIG.MC_TDQSCK_MAX {3500} \
    CONFIG.MC_TFAW {40000} \
    CONFIG.MC_TFAWMIN {40000} \
    CONFIG.MC_TMOD {0} \
    CONFIG.MC_TMOD_MIN {0} \
    CONFIG.MC_TMRD {14000} \
    CONFIG.MC_TMRDMIN {14000} \
    CONFIG.MC_TMRD_div4 {10} \
    CONFIG.MC_TMRD_nCK {23} \
    CONFIG.MC_TMRW {10000} \
    CONFIG.MC_TMRWMIN {10000} \
    CONFIG.MC_TMRW_div4 {10} \
    CONFIG.MC_TMRW_nCK {16} \
    CONFIG.MC_TODTon_MIN {3} \
    CONFIG.MC_TOSCO {40000} \
    CONFIG.MC_TOSCOMIN {40000} \
    CONFIG.MC_TOSCO_nCK {64} \
    CONFIG.MC_TPBR2PBR {90000} \
    CONFIG.MC_TPBR2PBRMIN {90000} \
    CONFIG.MC_TRAS {42000} \
    CONFIG.MC_TRASMIN {42000} \
    CONFIG.MC_TRAS_nCK {68} \
    CONFIG.MC_TRC {63000} \
    CONFIG.MC_TRCD {18000} \
    CONFIG.MC_TRCDMIN {18000} \
    CONFIG.MC_TRCD_nCK {29} \
    CONFIG.MC_TRCMIN {0} \
    CONFIG.MC_TREFI {3904000} \
    CONFIG.MC_TREFIPB {488000} \
    CONFIG.MC_TRFC {0} \
    CONFIG.MC_TRFCAB {280000} \
    CONFIG.MC_TRFCABMIN {280000} \
    CONFIG.MC_TRFCMIN {0} \
    CONFIG.MC_TRFCPB {140000} \
    CONFIG.MC_TRFCPBMIN {140000} \
    CONFIG.MC_TRP {0} \
    CONFIG.MC_TRPAB {21000} \
    CONFIG.MC_TRPABMIN {21000} \
    CONFIG.MC_TRPAB_nCK {34} \
    CONFIG.MC_TRPMIN {0} \
    CONFIG.MC_TRPPB {18000} \
    CONFIG.MC_TRPPBMIN {18000} \
    CONFIG.MC_TRPPB_nCK {29} \
    CONFIG.MC_TRPRE {1.8} \
    CONFIG.MC_TRRD {10000} \
    CONFIG.MC_TRRDMIN {10000} \
    CONFIG.MC_TRRD_L {0} \
    CONFIG.MC_TRRD_L_MIN {0} \
    CONFIG.MC_TRRD_S {0} \
    CONFIG.MC_TRRD_S_MIN {0} \
    CONFIG.MC_TRRD_nCK {16} \
    CONFIG.MC_TRTP {7500} \
    CONFIG.MC_TWPRE {1.8} \
    CONFIG.MC_TWPST {0.4} \
    CONFIG.MC_TWR {18000} \
    CONFIG.MC_TWRMIN {18000} \
    CONFIG.MC_TWR_nCK {29} \
    CONFIG.MC_TWTR {10000} \
    CONFIG.MC_TWTRMIN {10000} \
    CONFIG.MC_TWTR_L {0} \
    CONFIG.MC_TWTR_S {0} \
    CONFIG.MC_TWTR_S_MIN {0} \
    CONFIG.MC_TWTR_nCK {16} \
    CONFIG.MC_TXP {12} \
    CONFIG.MC_TXPMIN {12} \
    CONFIG.MC_TXPR {0} \
    CONFIG.MC_TZQCAL {1000000} \
    CONFIG.MC_TZQCAL_div4 {400} \
    CONFIG.MC_TZQCS_ITVL {0} \
    CONFIG.MC_TZQLAT {30000} \
    CONFIG.MC_TZQLATMIN {30000} \
    CONFIG.MC_TZQLAT_div4 {12} \
    CONFIG.MC_TZQLAT_nCK {48} \
    CONFIG.MC_TZQ_START_ITVL {1000000000} \
    CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-3BA-10CA} \
    CONFIG.MC_WRITE_BANDWIDTH {6400.0} \
    CONFIG.MC_XPLL_CLKOUT1_PERIOD {1250} \
    CONFIG.MC_XPLL_CLKOUT1_PHASE {238.176} \
    CONFIG.MC_XPLL_CLKOUT1_PH_CTRL {0x3} \
    CONFIG.MC_XPLL_CLKOUT2_PH_CTRL {0x1} \
    CONFIG.MC_XPLL_DIV4_CLKOUT12 {TRUE} \
    CONFIG.MC_XPLL_DSKW_DLY1 {12} \
    CONFIG.MC_XPLL_DSKW_DLY2 {15} \
    CONFIG.MC_XPLL_DSKW_DLY_EN1 {TRUE} \
    CONFIG.MC_XPLL_DSKW_DLY_EN2 {TRUE} \
    CONFIG.NUM_CLKS {10} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_SI {9} \
  ] $axi_noc_0


  set_property -dict [ list \
   CONFIG.CATEGORY {ps_nci_phy} \
 ] [get_bd_intf_pins $axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins $axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M00_AXI:0x140} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins $axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_2 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins $axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins $axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_2 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_3 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_3 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S08_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI} \
 ] [get_bd_pins $axi_noc_0/aclk9]

  # Create instance: qdma_0, and set properties
  set qdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:qdma qdma_0 ]
  set_property -dict [list \
    CONFIG.EGW_IS_PARENT_IP {1} \
    CONFIG.INS_LOSS_NYQ {15} \
    CONFIG.MAILBOX_ENABLE {false} \
    CONFIG.MSI_X_OPTIONS {None} \
    CONFIG.PCIE_BOARD_INTERFACE {Custom} \
    CONFIG.PF0_SRIOV_FUNC_DEP_LINK {0000} \
    CONFIG.PF0_SRIOV_VF_DEVICE_ID {C034} \
    CONFIG.PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PL_DISABLE_LANE_REVERSAL {TRUE} \
    CONFIG.PL_DISABLE_LANE_REVERSAL_NV {false} \
    CONFIG.RX_PPM_OFFSET {0} \
    CONFIG.RX_SSC_PPM {0} \
    CONFIG.SRIOV_CAP_ENABLE {false} \
    CONFIG.SRIOV_FIRST_VF_OFFSET {16} \
    CONFIG.SYS_RST_N_BOARD_INTERFACE {Custom} \
    CONFIG.Shared_Logic_Both {false} \
    CONFIG.Shared_Logic_Clk {false} \
    CONFIG.Shared_Logic_Gtc {false} \
    CONFIG.adv_int_usr {false} \
    CONFIG.alf_cap_enable {false} \
    CONFIG.all_speeds_all_sides {NO} \
    CONFIG.async_clk_enable {false} \
    CONFIG.axi_aclk_loopback {false} \
    CONFIG.axi_addr_width {64} \
    CONFIG.axi_data_width {512_bit} \
    CONFIG.axi_id_width {4} \
    CONFIG.axi_vip_in_exdes {false} \
    CONFIG.axibar2pciebar_0 {0x0000000000000000} \
    CONFIG.axibar_notranslate {true} \
    CONFIG.axibar_num {2} \
    CONFIG.axilite_master_en {false} \
    CONFIG.axist_bypass_en {false} \
    CONFIG.axisten_freq {250} \
    CONFIG.axisten_if_enable_msg_route {1EFFF} \
    CONFIG.bar0_indicator {1} \
    CONFIG.bar1_indicator {0} \
    CONFIG.bar2_indicator {0} \
    CONFIG.bar3_indicator {0} \
    CONFIG.bar4_indicator {0} \
    CONFIG.bar5_indicator {0} \
    CONFIG.bar_indicator {BAR_0} \
    CONFIG.barlite2 {7} \
    CONFIG.barlite_mb_pf0 {0} \
    CONFIG.barlite_mb_pf1 {0} \
    CONFIG.barlite_mb_pf2 {0} \
    CONFIG.barlite_mb_pf3 {0} \
    CONFIG.bridge_burst {TRUE} \
    CONFIG.bridge_register_access {false} \
    CONFIG.bridge_registers_offset_enable {false} \
    CONFIG.c2h_stream_cpl_col_bit_pos0 {1} \
    CONFIG.c2h_stream_cpl_col_bit_pos1 {0} \
    CONFIG.c2h_stream_cpl_col_bit_pos2 {0} \
    CONFIG.c2h_stream_cpl_col_bit_pos3 {0} \
    CONFIG.c2h_stream_cpl_col_bit_pos4 {0} \
    CONFIG.c2h_stream_cpl_col_bit_pos5 {0} \
    CONFIG.c2h_stream_cpl_col_bit_pos6 {0} \
    CONFIG.c2h_stream_cpl_col_bit_pos7 {0} \
    CONFIG.c2h_stream_cpl_data_size {8_Bytes} \
    CONFIG.c2h_stream_cpl_err_bit_pos0 {2} \
    CONFIG.c2h_stream_cpl_err_bit_pos1 {0} \
    CONFIG.c2h_stream_cpl_err_bit_pos2 {0} \
    CONFIG.c2h_stream_cpl_err_bit_pos3 {0} \
    CONFIG.c2h_stream_cpl_err_bit_pos4 {0} \
    CONFIG.c2h_stream_cpl_err_bit_pos5 {0} \
    CONFIG.c2h_stream_cpl_err_bit_pos6 {0} \
    CONFIG.c2h_stream_cpl_err_bit_pos7 {0} \
    CONFIG.c_ats_enable {false} \
    CONFIG.c_m_axi_num_write {32} \
    CONFIG.c_pri_enable {false} \
    CONFIG.cfg_ext_if {false} \
    CONFIG.cfg_mgmt_if {true} \
    CONFIG.cfg_space_enable {false} \
    CONFIG.comp_timeout {50ms} \
    CONFIG.copy_pf0 {true} \
    CONFIG.copy_sriov_pf0 {true} \
    CONFIG.csr_axilite_slave {true} \
    CONFIG.csr_module {1} \
    CONFIG.data_mover {false} \
    CONFIG.debug_mode {DEBUG_NONE} \
    CONFIG.descriptor_bypass_exdes {false} \
    CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.disable_bram_pipeline {false} \
    CONFIG.disable_eq_synchronizer {false} \
    CONFIG.disable_gt_loc {false} \
    CONFIG.disable_user_clock_root {true} \
    CONFIG.dma_2rp {false} \
    CONFIG.dma_intf_sel_qdma {AXI_MM_and_AXI_Stream_with_Completion} \
    CONFIG.dma_mode_en {false} \
    CONFIG.double_quad {false} \
    CONFIG.dsc_bypass_rd_out {false} \
    CONFIG.dsc_bypass_wr_out {false} \
    CONFIG.en_axi_master_if {true} \
    CONFIG.en_axi_mm_qdma {true} \
    CONFIG.en_axi_slave_if {true} \
    CONFIG.en_axi_st_qdma {true} \
    CONFIG.en_bridge {true} \
    CONFIG.en_coreclk_es1 {false} \
    CONFIG.en_debug_ports {false} \
    CONFIG.en_dma_and_bridge {false} \
    CONFIG.en_dma_completion {false} \
    CONFIG.en_ext_ch_gt_drp {false} \
    CONFIG.en_gt_selection {false} \
    CONFIG.en_l23_entry {false} \
    CONFIG.en_pcie_drp {false} \
    CONFIG.en_qdma {true} \
    CONFIG.en_transceiver_status_ports {false} \
    CONFIG.enable_64bit {false} \
    CONFIG.enable_at_ports {false} \
    CONFIG.enable_ats_switch {FALSE} \
    CONFIG.enable_auto_rxeq {False} \
    CONFIG.enable_ccix {FALSE} \
    CONFIG.enable_clock_delay_grp {true} \
    CONFIG.enable_dvsec {FALSE} \
    CONFIG.enable_error_injection {false} \
    CONFIG.enable_gen4 {true} \
    CONFIG.enable_gtwizard {false} \
    CONFIG.enable_ibert {false} \
    CONFIG.enable_jtag_dbg {false} \
    CONFIG.enable_mark_debug {false} \
    CONFIG.enable_more_clk {false} \
    CONFIG.enable_multi_pcie {false} \
    CONFIG.enable_pcie_debug {False} \
    CONFIG.enable_pcie_debug_ports {False} \
    CONFIG.enable_resource_reduction {false} \
    CONFIG.enable_x16 {false} \
    CONFIG.example_design_type {RTL} \
    CONFIG.ext_sys_clk_bufg {false} \
    CONFIG.flr_enable {false} \
    CONFIG.free_run_freq {100_MHz} \
    CONFIG.functional_mode {AXI_Bridge} \
    CONFIG.gen4_eieos_0s7 {true} \
    CONFIG.gt_loc_num {X99Y99} \
    CONFIG.gt_quad_sharing {false} \
    CONFIG.gtcom_in_core_usp {2} \
    CONFIG.gtwiz_in_core_us {1} \
    CONFIG.gtwiz_in_core_usp {1} \
    CONFIG.iep_enable {false} \
    CONFIG.ins_loss_profile {Add-in_Card} \
    CONFIG.insert_cips {false} \
    CONFIG.lane_order {Bottom} \
    CONFIG.lane_reversal {false} \
    CONFIG.last_core_cap_addr {0x1F0} \
    CONFIG.local_test {false} \
    CONFIG.master_cal_only {true} \
    CONFIG.mhost_en {false} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.msix_pcie_internal {false} \
    CONFIG.msix_preset {0} \
    CONFIG.mult_pf_des {false} \
    CONFIG.num_queues {512} \
    CONFIG.old_bridge_timeout {false} \
    CONFIG.parity_settings {None} \
    CONFIG.pcie_blk_locn {X1Y0} \
    CONFIG.pcie_extended_tag {true} \
    CONFIG.pcie_id_if {true} \
    CONFIG.performance {false} \
    CONFIG.performance_exdes {false} \
    CONFIG.pf0_Use_Class_Code_Lookup_Assistant_qdma {false} \
    CONFIG.pf0_aer_cap_ecrc_gen_and_check_capable {false} \
    CONFIG.pf0_ari_enabled {false} \
    CONFIG.pf0_ats_enabled {false} \
    CONFIG.pf0_bar0_64bit_qdma {true} \
    CONFIG.pf0_bar0_index {0} \
    CONFIG.pf0_bar0_prefetchable_qdma {false} \
    CONFIG.pf0_bar0_scale_qdma {Terabytes} \
    CONFIG.pf0_bar0_size_qdma {16} \
    CONFIG.pf0_bar0_type_qdma {AXI_Bridge_Master} \
    CONFIG.pf0_bar1_index {7} \
    CONFIG.pf0_bar2_index {7} \
    CONFIG.pf0_bar3_index {7} \
    CONFIG.pf0_bar4_index {7} \
    CONFIG.pf0_bar5_index {7} \
    CONFIG.pf0_bar5_prefetchable_qdma {false} \
    CONFIG.pf0_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf0_class_code_base_qdma {06} \
    CONFIG.pf0_class_code_interface_qdma {00} \
    CONFIG.pf0_class_code_sub_qdma {0A} \
    CONFIG.pf0_device_id {B0D4} \
    CONFIG.pf0_interrupt_pin {INTA} \
    CONFIG.pf0_link_status_slot_clock_config {true} \
    CONFIG.pf0_pciebar2axibar_0 {0x0000000000000000} \
    CONFIG.pf0_pri_enabled {false} \
    CONFIG.pf0_rbar_cap_bar0 {0x00000000fff0} \
    CONFIG.pf0_rbar_cap_bar1 {0x000000000000} \
    CONFIG.pf0_rbar_cap_bar2 {0x000000000000} \
    CONFIG.pf0_rbar_cap_bar3 {0x000000000000} \
    CONFIG.pf0_rbar_cap_bar4 {0x000000000000} \
    CONFIG.pf0_rbar_cap_bar5 {0x000000000000} \
    CONFIG.pf0_rbar_num {1} \
    CONFIG.pf0_revision_id {00} \
    CONFIG.pf0_sriov_bar0_64bit {true} \
    CONFIG.pf0_sriov_bar0_prefetchable {true} \
    CONFIG.pf0_sriov_bar0_scale {Kilobytes} \
    CONFIG.pf0_sriov_bar0_size {4} \
    CONFIG.pf0_sriov_bar0_type {AXI_Bridge_Master} \
    CONFIG.pf0_sriov_bar2_64bit {true} \
    CONFIG.pf0_sriov_bar2_enabled {true} \
    CONFIG.pf0_sriov_bar2_prefetchable {true} \
    CONFIG.pf0_sriov_bar2_scale {Kilobytes} \
    CONFIG.pf0_sriov_bar2_size {4} \
    CONFIG.pf0_sriov_bar2_type {AXI_Lite_Master} \
    CONFIG.pf0_sriov_bar4_enabled {false} \
    CONFIG.pf0_sriov_bar5_64bit {false} \
    CONFIG.pf0_sriov_bar5_prefetchable {false} \
    CONFIG.pf0_sriov_cap_ver {1} \
    CONFIG.pf0_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf0_subsystem_id {0007} \
    CONFIG.pf0_subsystem_vendor_id {10EE} \
    CONFIG.pf0_vc_cap_enabled {true} \
    CONFIG.pf0_vf_pciebar2axibar_0 {0x0000000000000000} \
    CONFIG.pf0_vf_pciebar2axibar_2 {0x0000000040000000} \
    CONFIG.pf1_Use_Class_Code_Lookup_Assistant_qdma {false} \
    CONFIG.pf1_bar0_index {0} \
    CONFIG.pf1_bar1_index {7} \
    CONFIG.pf1_bar2_index {7} \
    CONFIG.pf1_bar3_index {7} \
    CONFIG.pf1_bar4_index {7} \
    CONFIG.pf1_bar5_index {7} \
    CONFIG.pf1_bar5_prefetchable_qdma {false} \
    CONFIG.pf1_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf1_class_code_base_qdma {06} \
    CONFIG.pf1_class_code_interface_qdma {00} \
    CONFIG.pf1_class_code_sub_qdma {0A} \
    CONFIG.pf1_device_id {913F} \
    CONFIG.pf1_msi_enabled {false} \
    CONFIG.pf1_msix_enabled {true} \
    CONFIG.pf1_pciebar2axibar_0 {0x0000000000000000} \
    CONFIG.pf1_rbar_cap_bar0 {0x00000000fff0} \
    CONFIG.pf1_rbar_cap_bar1 {0x000000000000} \
    CONFIG.pf1_rbar_cap_bar2 {0x000000000000} \
    CONFIG.pf1_rbar_cap_bar3 {0x000000000000} \
    CONFIG.pf1_rbar_cap_bar4 {0x000000000000} \
    CONFIG.pf1_rbar_cap_bar5 {0x000000000000} \
    CONFIG.pf1_rbar_num {1} \
    CONFIG.pf1_revision_id {00} \
    CONFIG.pf1_sriov_bar5_64bit {false} \
    CONFIG.pf1_sriov_bar5_prefetchable {false} \
    CONFIG.pf1_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf1_subsystem_id {0007} \
    CONFIG.pf1_vf_pciebar2axibar_0 {0x0000000000000000} \
    CONFIG.pf1_vf_pciebar2axibar_2 {0x0000000050000000} \
    CONFIG.pf2_Use_Class_Code_Lookup_Assistant_qdma {false} \
    CONFIG.pf2_bar0_index {0} \
    CONFIG.pf2_bar1_index {7} \
    CONFIG.pf2_bar2_index {7} \
    CONFIG.pf2_bar3_index {7} \
    CONFIG.pf2_bar4_index {7} \
    CONFIG.pf2_bar5_index {7} \
    CONFIG.pf2_bar5_prefetchable_qdma {false} \
    CONFIG.pf2_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf2_class_code_base_qdma {06} \
    CONFIG.pf2_class_code_interface_qdma {00} \
    CONFIG.pf2_class_code_sub_qdma {0A} \
    CONFIG.pf2_device_id {B2D4} \
    CONFIG.pf2_msi_enabled {false} \
    CONFIG.pf2_pciebar2axibar_0 {0x0000000000000000} \
    CONFIG.pf2_rbar_cap_bar0 {0x00000000fff0} \
    CONFIG.pf2_rbar_cap_bar1 {0x000000000000} \
    CONFIG.pf2_rbar_cap_bar2 {0x000000000000} \
    CONFIG.pf2_rbar_cap_bar3 {0x000000000000} \
    CONFIG.pf2_rbar_cap_bar4 {0x000000000000} \
    CONFIG.pf2_rbar_cap_bar5 {0x000000000000} \
    CONFIG.pf2_rbar_num {1} \
    CONFIG.pf2_revision_id {00} \
    CONFIG.pf2_sriov_bar5_64bit {false} \
    CONFIG.pf2_sriov_bar5_prefetchable {false} \
    CONFIG.pf2_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf2_subsystem_id {0007} \
    CONFIG.pf2_vf_pciebar2axibar_0 {0x0000000000000000} \
    CONFIG.pf2_vf_pciebar2axibar_2 {0x0000000060000000} \
    CONFIG.pf3_Use_Class_Code_Lookup_Assistant_qdma {false} \
    CONFIG.pf3_bar0_index {0} \
    CONFIG.pf3_bar1_index {7} \
    CONFIG.pf3_bar2_index {7} \
    CONFIG.pf3_bar3_index {7} \
    CONFIG.pf3_bar4_index {7} \
    CONFIG.pf3_bar5_index {7} \
    CONFIG.pf3_bar5_prefetchable_qdma {false} \
    CONFIG.pf3_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf3_class_code_base_qdma {06} \
    CONFIG.pf3_class_code_interface_qdma {00} \
    CONFIG.pf3_class_code_sub_qdma {0A} \
    CONFIG.pf3_device_id {B3D4} \
    CONFIG.pf3_msi_enabled {false} \
    CONFIG.pf3_pciebar2axibar_0 {0x0000000000000000} \
    CONFIG.pf3_rbar_cap_bar0 {0x00000000fff0} \
    CONFIG.pf3_rbar_cap_bar1 {0x000000000000} \
    CONFIG.pf3_rbar_cap_bar2 {0x000000000000} \
    CONFIG.pf3_rbar_cap_bar3 {0x000000000000} \
    CONFIG.pf3_rbar_cap_bar4 {0x000000000000} \
    CONFIG.pf3_rbar_cap_bar5 {0x000000000000} \
    CONFIG.pf3_rbar_num {1} \
    CONFIG.pf3_revision_id {00} \
    CONFIG.pf3_sriov_bar5_64bit {false} \
    CONFIG.pf3_sriov_bar5_prefetchable {false} \
    CONFIG.pf3_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf3_subsystem_id {0007} \
    CONFIG.pf3_vf_pciebar2axibar_0 {0x0000000000000000} \
    CONFIG.pf3_vf_pciebar2axibar_2 {0x0000000070000000} \
    CONFIG.pfch_cache_depth {16} \
    CONFIG.pipe_line_stage {2} \
    CONFIG.pipe_sim {false} \
    CONFIG.pl_link_cap_max_link_speed {32.0_GT/s} \
    CONFIG.pl_link_cap_max_link_width {X4} \
    CONFIG.rbar_enable {false} \
    CONFIG.ref_clk_freq {100_MHz} \
    CONFIG.replace_uram_with_bram {false} \
    CONFIG.rq_rcfg_en {TRUE} \
    CONFIG.rx_detect {Default} \
    CONFIG.set_finite_credit {false} \
    CONFIG.silicon_rev {Pre-Production} \
    CONFIG.sim_model {NO} \
    CONFIG.soft_nic {false} \
    CONFIG.soft_nic_bridge {false} \
    CONFIG.split_dma {true} \
    CONFIG.tandem_enable_rfsoc {false} \
    CONFIG.testname {mm_st} \
    CONFIG.three_port_switch {false} \
    CONFIG.timeout0_sel {14} \
    CONFIG.timeout1_sel {15} \
    CONFIG.timeout_mult {3} \
    CONFIG.tl_credits_cd {15} \
    CONFIG.tl_credits_ch {15} \
    CONFIG.tl_pf_enable_reg {1} \
    CONFIG.tl_tx_mux_strict_priority {false} \
    CONFIG.two_port_switch {false} \
    CONFIG.usplus_es1_seqnum_bypass {false} \
    CONFIG.usr_irq_exdes {false} \
    CONFIG.usr_irq_xdma_type_interface {false} \
    CONFIG.vcu118_board {false} \
    CONFIG.vcu118_ddr_ex {false} \
    CONFIG.vdpa_exdes {false} \
    CONFIG.vendor_id {10EE} \
    CONFIG.virtio_en {false} \
    CONFIG.virtio_exdes {false} \
    CONFIG.virtio_perf_exdes {false} \
    CONFIG.vsec_cap_addr {0xE00} \
    CONFIG.vu9p_board {false} \
    CONFIG.vu9p_tul_ex {false} \
    CONFIG.warm_reboot_sbr_fix {false} \
    CONFIG.wrb_coal_loop_fix_disable {false} \
    CONFIG.wrb_coal_max_buf {16} \
    CONFIG.xdma_axi_intf_mm {AXI_Memory_Mapped} \
    CONFIG.xdma_dsc_bypass {false} \
    CONFIG.xdma_non_incremental_exdes {false} \
    CONFIG.xdma_num_usr_irq {16} \
    CONFIG.xdma_pcie_64bit_en {false} \
    CONFIG.xdma_rnum_chnl {4} \
    CONFIG.xdma_rnum_rids {32} \
    CONFIG.xdma_st_infinite_desc_exdes {false} \
    CONFIG.xdma_sts_ports {false} \
    CONFIG.xdma_wnum_chnl {4} \
    CONFIG.xdma_wnum_rids {32} \
    CONFIG.xlnx_ddr_ex {false} \
    CONFIG.xlnx_ref_board {VPK120} \
  ] $qdma_0


  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_noc_0_CH0_LPDDR4_0 [get_bd_intf_ports CH0_LPDDR4_0_0] [get_bd_intf_pins axi_noc_0/CH0_LPDDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_CH1_LPDDR4_0 [get_bd_intf_ports CH1_LPDDR4_0_0] [get_bd_intf_pins axi_noc_0/CH1_LPDDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins versal_cips_0/NOC_FPD_AXI_0]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins qdma_0_support/pcie_refclk]
  connect_bd_intf_net -intf_net qdma_0_M_AXI_BRIDGE [get_bd_intf_pins smartconnect_1/S00_AXI] [get_bd_intf_pins qdma_0/M_AXI_BRIDGE]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets qdma_0_M_AXI_BRIDGE]
  connect_bd_intf_net -intf_net qdma_0_pcie_cfg_control_if [get_bd_intf_pins qdma_0/pcie_cfg_control_if] [get_bd_intf_pins qdma_0_support/pcie_cfg_control]
  connect_bd_intf_net -intf_net qdma_0_pcie_cfg_interrupt [get_bd_intf_pins qdma_0/pcie_cfg_interrupt] [get_bd_intf_pins qdma_0_support/pcie_cfg_interrupt]
  connect_bd_intf_net -intf_net qdma_0_pcie_cfg_mgmt_if [get_bd_intf_pins qdma_0/pcie_cfg_mgmt_if] [get_bd_intf_pins qdma_0_support/pcie_cfg_mgmt]
  connect_bd_intf_net -intf_net qdma_0_s_axis_cc [get_bd_intf_pins qdma_0/s_axis_cc] [get_bd_intf_pins qdma_0_support/s_axis_cc]
  connect_bd_intf_net -intf_net qdma_0_support_m_axis_cq [get_bd_intf_pins qdma_0/m_axis_cq] [get_bd_intf_pins qdma_0_support/m_axis_cq]
  connect_bd_intf_net -intf_net qdma_0_support_m_axis_rc [get_bd_intf_pins qdma_0_support/m_axis_rc] [get_bd_intf_pins qdma_0/m_axis_rc]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_cfg_fc [get_bd_intf_pins qdma_0/pcie_cfg_fc] [get_bd_intf_pins qdma_0_support/pcie_cfg_fc]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_cfg_mesg_rcvd [get_bd_intf_pins qdma_0/pcie_cfg_mesg_rcvd] [get_bd_intf_pins qdma_0_support/pcie_cfg_mesg_rcvd]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_cfg_mesg_tx [get_bd_intf_pins qdma_0/pcie_cfg_mesg_tx] [get_bd_intf_pins qdma_0_support/pcie_cfg_mesg_tx]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_cfg_status [get_bd_intf_pins qdma_0/pcie_cfg_status_if] [get_bd_intf_pins qdma_0_support/pcie_cfg_status]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_mgt [get_bd_intf_ports pcie_mgt] [get_bd_intf_pins qdma_0_support/pcie_mgt]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_transmit_fc [get_bd_intf_pins qdma_0/pcie_transmit_fc_if] [get_bd_intf_pins qdma_0_support/pcie_transmit_fc]
  connect_bd_intf_net -intf_net s_axis_rq_1 [get_bd_intf_pins qdma_0_support/s_axis_rq] [get_bd_intf_pins qdma_0/s_axis_rq]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins qdma_0/S_AXI_LITE] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins qdma_0/S_AXI_LITE_CSR] [get_bd_intf_pins smartconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M00_AXI [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins axi_noc_0/S08_AXI]
  connect_bd_intf_net -intf_net smartconnect_2_M00_AXI [get_bd_intf_pins qdma_0/S_AXI_BRIDGE] [get_bd_intf_pins smartconnect_2/M00_AXI]
  connect_bd_intf_net -intf_net sys_clk0_0_1 [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins axi_noc_0/sys_clk0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_AXI_NOC_0 [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S03_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_AXI_NOC_1 [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_1] [get_bd_intf_pins axi_noc_0/S00_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0] [get_bd_intf_pins axi_noc_0/S04_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1] [get_bd_intf_pins axi_noc_0/S05_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2] [get_bd_intf_pins axi_noc_0/S06_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3] [get_bd_intf_pins axi_noc_0/S07_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S02_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_FPD [get_bd_intf_pins smartconnect_2/S00_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_FPD]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_LPD [get_bd_intf_pins smartconnect_0/S00_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_LPD]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_0/S01_AXI]

  # Create port connections
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_pins smartconnect_1/aresetn] \
  [get_bd_pins smartconnect_2/aresetn]
  connect_bd_net -net qdma_0_axi_aclk  [get_bd_pins qdma_0/axi_aclk] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
  [get_bd_pins axi_noc_0/aclk8] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins smartconnect_1/aclk] \
  [get_bd_pins smartconnect_2/aclk] \
  [get_bd_pins versal_cips_0/m_axi_fpd_aclk] \
  [get_bd_pins versal_cips_0/m_axi_lpd_aclk]
  connect_bd_net -net qdma_0_interrupt_out  [get_bd_pins qdma_0/interrupt_out] \
  [get_bd_pins versal_cips_0/pl_ps_irq0]
  connect_bd_net -net qdma_0_interrupt_out_msi_vec0to31  [get_bd_pins qdma_0/interrupt_out_msi_vec0to31] \
  [get_bd_pins versal_cips_0/pl_ps_irq1]
  connect_bd_net -net qdma_0_interrupt_out_msi_vec32to63  [get_bd_pins qdma_0/interrupt_out_msi_vec32to63] \
  [get_bd_pins versal_cips_0/pl_ps_irq2]
  connect_bd_net -net qdma_0_support_phy_rdy_out  [get_bd_pins qdma_0_support/phy_rdy_out] \
  [get_bd_pins qdma_0/phy_rdy_out_sd]
  connect_bd_net -net qdma_0_support_user_clk  [get_bd_pins qdma_0_support/user_clk] \
  [get_bd_pins qdma_0/user_clk_sd]
  connect_bd_net -net qdma_0_support_user_lnk_up  [get_bd_pins qdma_0_support/user_lnk_up] \
  [get_bd_pins qdma_0/user_lnk_up_sd]
  connect_bd_net -net qdma_0_support_user_reset  [get_bd_pins qdma_0_support/user_reset] \
  [get_bd_pins qdma_0/user_reset_sd]
  connect_bd_net -net versal_cips_0_fpd_axi_noc_axi0_clk  [get_bd_pins versal_cips_0/fpd_axi_noc_axi0_clk] \
  [get_bd_pins axi_noc_0/aclk3]
  connect_bd_net -net versal_cips_0_fpd_axi_noc_axi1_clk  [get_bd_pins versal_cips_0/fpd_axi_noc_axi1_clk] \
  [get_bd_pins axi_noc_0/aclk0]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk] \
  [get_bd_pins axi_noc_0/aclk4]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk] \
  [get_bd_pins axi_noc_0/aclk5]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk] \
  [get_bd_pins axi_noc_0/aclk6]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk] \
  [get_bd_pins axi_noc_0/aclk7]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk  [get_bd_pins versal_cips_0/lpd_axi_noc_clk] \
  [get_bd_pins axi_noc_0/aclk2]
  connect_bd_net -net versal_cips_0_noc_fpd_axi_axi0_clk  [get_bd_pins versal_cips_0/noc_fpd_axi_axi0_clk] \
  [get_bd_pins axi_noc_0/aclk9]
  connect_bd_net -net versal_cips_0_pl0_resetn  [get_bd_pins versal_cips_0/pl0_resetn] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk  [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk] \
  [get_bd_pins axi_noc_0/aclk1]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins qdma_0_support/sys_reset] \
  [get_bd_pins qdma_0/soft_reset_n]

  # Create address segments
  assign_bd_address -offset 0x050000000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S03_AXI/C0_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S03_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S05_AXI/C1_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S05_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S06_AXI/C2_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S06_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S07_AXI/C3_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S07_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0xA8000000 -range 0x08000000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs qdma_0/S_AXI_BRIDGE/BAR0] -force
  assign_bd_address -offset 0x000480000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs qdma_0/S_AXI_BRIDGE/BAR1] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_LPD] [get_bd_addr_segs qdma_0/S_AXI_LITE/CTL0] -force
  assign_bd_address -offset 0x90000000 -range 0x10000000 -with_name SEG_qdma_0_CTL0_1 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_LPD] [get_bd_addr_segs qdma_0/S_AXI_LITE_CSR/CTL0] -force
  assign_bd_address -offset 0x050000000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI_BRIDGE] [get_bd_addr_segs axi_noc_0/S08_AXI/C3_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI_BRIDGE] [get_bd_addr_segs axi_noc_0/S08_AXI/C3_DDR_LOW0] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_a720_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_a720_dbg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_a720_etm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_a720_pmu]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_a721_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_a721_dbg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_a721_etm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_a721_pmu]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_apu_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_apu_ela]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_apu_etf]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_apu_fun]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_cpm_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_cpm_cti2a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_cpm_cti2d]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_cpm_ela2a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_cpm_ela2b]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_cpm_ela2c]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_cpm_ela2d]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_cpm_fun]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_cpm_rom]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_cti1b]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_cti1c]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_cti1d]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_lpd_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_pmc_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_r50_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_r51_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ram_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_analog_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_tap]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntrs_0]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


