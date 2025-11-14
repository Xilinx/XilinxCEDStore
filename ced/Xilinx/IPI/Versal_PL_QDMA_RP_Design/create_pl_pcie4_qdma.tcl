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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_cq

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_rc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_control_rtl:1.0 pcie_cfg_control

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.1 pcie_cfg_fc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie_cfg_interrupt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie_cfg_mesg_rcvd

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_cfg_mesg_tx_rtl:1.0 pcie_cfg_mesg_tx

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie_cfg_mgmt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie4_cfg_status_rtl:1.0 pcie_cfg_status

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_mgt_2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie_transmit_fc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_cc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_rq


  # Create pins
  create_bd_pin -dir O -from 5 -to 0 pcie_ltssm_state
  create_bd_pin -dir O phy_rdy_out
  create_bd_pin -dir I -type rst sys_reset
  create_bd_pin -dir O -type clk user_clk
  create_bd_pin -dir O user_lnk_up
  create_bd_pin -dir O -type rst user_reset

  # Create instance: bufg_gt_sysclk, and set properties
  set bufg_gt_sysclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf bufg_gt_sysclk ]
  set_property -dict [list \
    CONFIG.C_BUFG_GT_SYNC {true} \
    CONFIG.C_BUF_TYPE {BUFG_GT} \
  ] $bufg_gt_sysclk


  # Create instance: pcie, and set properties
  set pcie [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_versal pcie ]
  set_property -dict [list \
    CONFIG.AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned} \
    CONFIG.AXISTEN_IF_EXT_512_RQ_STRADDLE {true} \
    CONFIG.AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
    CONFIG.PF0_DEVICE_ID {B048} \
    CONFIG.PF0_INTERRUPT_PIN {INTA} \
    CONFIG.PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {true} \
    CONFIG.PF0_REVISION_ID {00} \
    CONFIG.PF0_SRIOV_VF_DEVICE_ID {C048} \
    CONFIG.PF0_SUBSYSTEM_ID {0007} \
    CONFIG.PF0_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF1_DEVICE_ID {9011} \
    CONFIG.PF1_REVISION_ID {00} \
    CONFIG.PF1_SUBSYSTEM_ID {0007} \
    CONFIG.PF1_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF1_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF2_DEVICE_ID {B248} \
    CONFIG.PF2_REVISION_ID {00} \
    CONFIG.PF2_SUBSYSTEM_ID {0007} \
    CONFIG.PF2_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF2_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF3_DEVICE_ID {B348} \
    CONFIG.PF3_REVISION_ID {00} \
    CONFIG.PF3_SUBSYSTEM_ID {0007} \
    CONFIG.PF3_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF3_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF4_DEVICE_ID {B448} \
    CONFIG.PF5_DEVICE_ID {B548} \
    CONFIG.PF6_DEVICE_ID {B648} \
    CONFIG.PF7_DEVICE_ID {B748} \
    CONFIG.PL_DISABLE_LANE_REVERSAL {false} \
    CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {16.0_GT/s} \
    CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
    CONFIG.REF_CLK_FREQ {100_MHz} \
    CONFIG.acs_ext_cap_enable {false} \
    CONFIG.axisten_freq {250} \
    CONFIG.axisten_if_enable_client_tag {true} \
    CONFIG.axisten_if_enable_msg_route_override {TRUE} \
    CONFIG.axisten_if_width {512_bit} \
    CONFIG.cfg_ext_if {false} \
    CONFIG.cfg_mgmt_if {true} \
    CONFIG.copy_pf0 {true} \
    CONFIG.dedicate_perst {false} \
    CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.disable_double_pipe {NO} \
    CONFIG.en_dbg_descramble {false} \
    CONFIG.en_ext_clk {FALSE} \
    CONFIG.en_l23_entry {false} \
    CONFIG.en_parity {false} \
    CONFIG.enable_auto_rxeq {False} \
    CONFIG.enable_ccix {FALSE} \
    CONFIG.enable_dvsec {FALSE} \
    CONFIG.enable_gen4 {true} \
    CONFIG.enable_gtwizard {true} \
    CONFIG.enable_ibert {false} \
    CONFIG.enable_jtag_dbg {false} \
    CONFIG.ext_pcie_cfg_space_enabled {false} \
    CONFIG.extended_tag_field {true} \
    CONFIG.insert_cips {false} \
    CONFIG.legacy_ext_pcie_cfg_space_enabled {false} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.pcie_blk_locn {X1Y0} \
    CONFIG.pf0_ari_enabled {false} \
    CONFIG.pf0_bar0_64bit {true} \
    CONFIG.pf0_bar0_enabled {true} \
    CONFIG.pf0_bar0_prefetchable {true} \
    CONFIG.pf0_bar0_scale {Terabytes} \
    CONFIG.pf0_bar0_size {16} \
    CONFIG.pf0_bar2_enabled {false} \
    CONFIG.pf0_bar4_enabled {false} \
    CONFIG.pf0_base_class_menu {Bridge_device} \
    CONFIG.pf0_class_code_base {06} \
    CONFIG.pf0_class_code_interface {00} \
    CONFIG.pf0_class_code_sub {04} \
    CONFIG.pf0_dll_feature_cap_enabled {true} \
    CONFIG.pf0_margining_cap_enabled {true} \
    CONFIG.pf0_msi_enabled {false} \
    CONFIG.pf0_msix_enabled {false} \
    CONFIG.pf0_pl16_cap_enabled {true} \
    CONFIG.pf0_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf1_base_class_menu {Bridge_device} \
    CONFIG.pf1_class_code_base {06} \
    CONFIG.pf1_class_code_interface {00} \
    CONFIG.pf1_class_code_sub {04} \
    CONFIG.pf1_msix_enabled {false} \
    CONFIG.pf1_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf1_vendor_id {10EE} \
    CONFIG.pf2_base_class_menu {Bridge_device} \
    CONFIG.pf2_class_code_base {06} \
    CONFIG.pf2_class_code_interface {00} \
    CONFIG.pf2_class_code_sub {04} \
    CONFIG.pf2_msix_enabled {false} \
    CONFIG.pf2_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf2_vendor_id {10EE} \
    CONFIG.pf3_base_class_menu {Bridge_device} \
    CONFIG.pf3_class_code_base {06} \
    CONFIG.pf3_class_code_interface {00} \
    CONFIG.pf3_class_code_sub {04} \
    CONFIG.pf3_msix_enabled {false} \
    CONFIG.pf3_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf3_vendor_id {10EE} \
    CONFIG.pf4_base_class_menu {Bridge_device} \
    CONFIG.pf4_class_code_base {06} \
    CONFIG.pf4_class_code_sub {04} \
    CONFIG.pf4_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf5_base_class_menu {Bridge_device} \
    CONFIG.pf5_class_code_base {06} \
    CONFIG.pf5_class_code_sub {04} \
    CONFIG.pf5_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf6_base_class_menu {Bridge_device} \
    CONFIG.pf6_class_code_base {06} \
    CONFIG.pf6_class_code_sub {04} \
    CONFIG.pf6_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf7_base_class_menu {Bridge_device} \
    CONFIG.pf7_class_code_base {06} \
    CONFIG.pf7_class_code_sub {04} \
    CONFIG.pf7_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pipe_line_stage {1} \
    CONFIG.pipe_sim {false} \
    CONFIG.plltype {LCPLL} \
    CONFIG.sys_reset_polarity {ACTIVE_LOW} \
    CONFIG.type1_membase_memlimit_enable {Enabled} \
    CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
    CONFIG.userclk2_freq {500} \
    CONFIG.vendor_id {10EE} \
  ] $pcie


  # Create instance: pcie_phy, and set properties
  set pcie_phy [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_phy_versal pcie_phy ]
  set_property -dict [list \
    CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {16.0_GT/s} \
    CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
    CONFIG.aspm {No_ASPM} \
    CONFIG.disable_double_pipe {YES} \
    CONFIG.en_gt_pclk {false} \
    CONFIG.enable_gtwizard {true} \
    CONFIG.enable_rpll {false} \
    CONFIG.ins_loss_profile {Add-in_Card} \
    CONFIG.lane_order {Bottom} \
    CONFIG.lane_reversal {false} \
    CONFIG.phy_async_en {true} \
    CONFIG.phy_coreclk_freq {500_MHz} \
    CONFIG.phy_refclk_freq {100_MHz} \
    CONFIG.phy_userclk2_freq {500_MHz} \
    CONFIG.phy_userclk_freq {250_MHz} \
    CONFIG.pipeline_stages {1} \
    CONFIG.tx_preset {4} \
  ] $pcie_phy


  # Create instance: refclk_ibuf, and set properties
  set refclk_ibuf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf refclk_ibuf ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $refclk_ibuf


  # Create instance: gtwiz_versal_0, and set properties
  set gtwiz_versal_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gtwiz_versal gtwiz_versal_0 ]
  set_property -dict [list \
    CONFIG.GT_TYPE {GTY} \
    CONFIG.INTF0_GT_SETTINGS(GT_DIRECTION) {DUPLEX} \
    CONFIG.INTF0_GT_SETTINGS(GT_TYPE) {GTY} \
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
500 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 8.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH\
32 RX_REFCLK_FREQUENCY 100} \
    CONFIG.INTF0_GT_SETTINGS(LR3_SETTINGS) {TX_BUFFER_MODE 0 PCIE_ENABLE true TX_PLL_TYPE LCPLL TX_REFCLK_SOURCE R0 TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TX_OUTCLK_SOURCE TXPROGDIVCLK TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_BUFFER_BYPASS_MODE Fast_Sync TX_DATA_ENCODING 128B130B TX_LINE_RATE 16.0 TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32 TX_REFCLK_FREQUENCY 100 PCIE_USERCLK_FREQ 250 TXPROGDIV_FREQ_VAL 500.000 PCIE_USERCLK2_FREQ\
500 OOB_ENABLE true RX_BUFFER_MODE 1 RXPROGDIV_FREQ_ENABLE false RX_CC_LEN_SEQ 1 RX_CC_NUM_SEQ 1 RX_CC_K_0_0 true RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_KEEP_IDLE ENABLE RX_COMMA_ALIGN_WORD\
1 RX_COMMA_PRESET K28.5 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_MASK 1111111111 RX_COMMA_M_VAL 0101111100 RX_COMMA_P_VAL 1010000011 RX_COMMA_DOUBLE_ENABLE false RX_JTOL_FC 1 RX_PLL_TYPE\
LCPLL RX_SLIDE_MODE OFF RX_REFCLK_SOURCE R0 RX_OUTCLK_SOURCE RXOUTCLKPMA RX_EQ_MODE DFE RX_SSC_PPM 0 INS_LOSS_NYQ 20 RX_DATA_DECODING 128B130B RX_LINE_RATE 16.0 RX_PPM_OFFSET 0 RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH\
32 RX_REFCLK_FREQUENCY 100} \
    CONFIG.INTF0_NO_OF_LANES {8} \
    CONFIG.INTF0_PARENTID {design_1_pcie_phy_0} \
    CONFIG.INTF0_PCIE_ENABLE {true} \
    CONFIG.INTF_PARENT_PIN_LIST {QUAD0_RX0 /qdma_0_support/pcie_phy/GT_RX0 QUAD0_RX1 /qdma_0_support/pcie_phy/GT_RX1 QUAD0_RX2 /qdma_0_support/pcie_phy/GT_RX2 QUAD0_RX3 /qdma_0_support/pcie_phy/GT_RX3\
QUAD1_RX0 /qdma_0_support/pcie_phy/GT_RX4 QUAD1_RX1 /qdma_0_support/pcie_phy/GT_RX5 QUAD1_RX2 /qdma_0_support/pcie_phy/GT_RX6 QUAD1_RX3 /qdma_0_support/pcie_phy/GT_RX7 QUAD0_TX0 /qdma_0_support/pcie_phy/GT_TX0\
QUAD0_TX1 /qdma_0_support/pcie_phy/GT_TX1 QUAD0_TX2 /qdma_0_support/pcie_phy/GT_TX2 QUAD0_TX3 /qdma_0_support/pcie_phy/GT_TX3 QUAD1_TX0 /qdma_0_support/pcie_phy/GT_TX4 QUAD1_TX1 /qdma_0_support/pcie_phy/GT_TX5\
QUAD1_TX2 /qdma_0_support/pcie_phy/GT_TX6 QUAD1_TX3 /qdma_0_support/pcie_phy/GT_TX7} \
    CONFIG.NO_OF_QUADS {2} \
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
    CONFIG.QUAD0_OUTCLK_VALUES {CH0_RXOUTCLK 500 CH0_TXOUTCLK 500 CH1_RXOUTCLK 500 CH1_TXOUTCLK 500 CH2_RXOUTCLK 500 CH2_TXOUTCLK 500 CH3_RXOUTCLK 500 CH3_TXOUTCLK 500} \
    CONFIG.QUAD0_PCIELTSSM_EN {true} \
    CONFIG.QUAD0_PROT0_LANES {4} \
    CONFIG.QUAD0_REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK0_RPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_RPLLGTREFCLK0\
refclk_PROT0_R0_100_MHz_unique1} \
    CONFIG.QUAD0_USAGE {TX_QUAD_CH {TXQuad_0_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 design_1_pcie_phy_0.IP_CH0,design_1_pcie_phy_0.IP_CH1,design_1_pcie_phy_0.IP_CH2,design_1_pcie_phy_0.IP_CH3\
MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1} TXQuad_1_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_1 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_1 design_1_pcie_phy_0.IP_CH4,design_1_pcie_phy_0.IP_CH5,design_1_pcie_phy_0.IP_CH6,design_1_pcie_phy_0.IP_CH7\
MSTRCLK 0,0,0,0 IS_CURRENT_QUAD 0}} RX_QUAD_CH {RXQuad_0_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 design_1_pcie_phy_0.IP_CH0,design_1_pcie_phy_0.IP_CH1,design_1_pcie_phy_0.IP_CH2,design_1_pcie_phy_0.IP_CH3\
MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1} RXQuad_1_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_1 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_1 design_1_pcie_phy_0.IP_CH4,design_1_pcie_phy_0.IP_CH5,design_1_pcie_phy_0.IP_CH6,design_1_pcie_phy_0.IP_CH7\
MSTRCLK 0,0,0,0 IS_CURRENT_QUAD 0}}} \
    CONFIG.QUAD1_CH0_PCIERSTB_EN {true} \
    CONFIG.QUAD1_CH0_PHYREADY_EN {true} \
    CONFIG.QUAD1_CH0_PHYSTATUS_EN {true} \
    CONFIG.QUAD1_CH1_PCIERSTB_EN {true} \
    CONFIG.QUAD1_CH1_PHYREADY_EN {true} \
    CONFIG.QUAD1_CH1_PHYSTATUS_EN {true} \
    CONFIG.QUAD1_CH2_PCIERSTB_EN {true} \
    CONFIG.QUAD1_CH2_PHYREADY_EN {true} \
    CONFIG.QUAD1_CH2_PHYSTATUS_EN {true} \
    CONFIG.QUAD1_CH3_PCIERSTB_EN {true} \
    CONFIG.QUAD1_CH3_PHYREADY_EN {true} \
    CONFIG.QUAD1_CH3_PHYSTATUS_EN {true} \
    CONFIG.QUAD1_GT0_BUFGT_EN {true} \
    CONFIG.QUAD1_GT1_BUFGT_EN {true} \
    CONFIG.QUAD1_GT2_BUFGT_EN {true} \
    CONFIG.QUAD1_GT3_BUFGT_EN {true} \
    CONFIG.QUAD1_GT_RXMARGIN_INTF_EN {true} \
    CONFIG.QUAD1_OUTCLK_VALUES {CH0_RXOUTCLK 500 CH0_TXOUTCLK 500 CH1_RXOUTCLK 500 CH1_TXOUTCLK 500 CH2_RXOUTCLK 500 CH2_TXOUTCLK 500 CH3_RXOUTCLK 500 CH3_TXOUTCLK 500} \
    CONFIG.QUAD1_PCIELTSSM_EN {true} \
    CONFIG.QUAD1_PROT0_LANES {4} \
    CONFIG.QUAD1_REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK0_RPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_RPLLGTREFCLK0\
refclk_PROT0_R0_100_MHz_unique1} \
    CONFIG.QUAD1_USAGE {TX_QUAD_CH {TXQuad_-1_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 design_1_pcie_phy_0.IP_CH0,design_1_pcie_phy_0.IP_CH1,design_1_pcie_phy_0.IP_CH2,design_1_pcie_phy_0.IP_CH3\
MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 0} TXQuad_0_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_1 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_1 design_1_pcie_phy_0.IP_CH4,design_1_pcie_phy_0.IP_CH5,design_1_pcie_phy_0.IP_CH6,design_1_pcie_phy_0.IP_CH7\
MSTRCLK 0,0,0,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_-1_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_0 design_1_pcie_phy_0.IP_CH0,design_1_pcie_phy_0.IP_CH1,design_1_pcie_phy_0.IP_CH2,design_1_pcie_phy_0.IP_CH3\
MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 0} RXQuad_0_/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_1 {/design_1_gtwiz_versal_0_0/design_1_gtwiz_versal_0_0_gt_quad_base_1 design_1_pcie_phy_0.IP_CH4,design_1_pcie_phy_0.IP_CH5,design_1_pcie_phy_0.IP_CH6,design_1_pcie_phy_0.IP_CH7\
MSTRCLK 0,0,0,0 IS_CURRENT_QUAD 1}}} \
  ] $gtwiz_versal_0

  set_property -dict [list \
    CONFIG.INTF0_PARENTID.VALUE_MODE {auto} \
    CONFIG.INTF_PARENT_PIN_LIST.VALUE_MODE {auto} \
    CONFIG.QUAD0_USAGE.VALUE_MODE {auto} \
    CONFIG.QUAD1_USAGE.VALUE_MODE {auto} \
  ] $gtwiz_versal_0


  # Create instance: ilconstant_1, and set properties
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_1 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins pcie_refclk_1] [get_bd_intf_pins refclk_ibuf/CLK_IN_D]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins pcie_mgt_2] [get_bd_intf_pins pcie_phy/pcie_mgt]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins m_axis_cq] [get_bd_intf_pins pcie/m_axis_cq]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins s_axis_cc] [get_bd_intf_pins pcie/s_axis_cc]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins s_axis_rq] [get_bd_intf_pins pcie/s_axis_rq]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins m_axis_rc] [get_bd_intf_pins pcie/m_axis_rc]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins pcie_cfg_mesg_tx] [get_bd_intf_pins pcie/pcie_cfg_mesg_tx]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins pcie_transmit_fc] [get_bd_intf_pins pcie/pcie_transmit_fc]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins pcie_cfg_mesg_rcvd] [get_bd_intf_pins pcie/pcie_cfg_mesg_rcvd]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins pcie_cfg_status] [get_bd_intf_pins pcie/pcie_cfg_status]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins pcie_cfg_control] [get_bd_intf_pins pcie/pcie_cfg_control]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins pcie_cfg_fc] [get_bd_intf_pins pcie/pcie_cfg_fc]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins pcie_cfg_interrupt] [get_bd_intf_pins pcie/pcie_cfg_interrupt]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins pcie_cfg_mgmt] [get_bd_intf_pins pcie/pcie_cfg_mgmt]
  connect_bd_intf_net -intf_net gt_quad_0_GT0_BUFGT [get_bd_intf_pins gtwiz_versal_0/Quad0_GT0_BUFGT] [get_bd_intf_pins pcie_phy/GT_BUFGT]
  connect_bd_intf_net -intf_net gt_quad_0_GT_Serial [get_bd_intf_pins gtwiz_versal_0/Quad0_GT_Serial] [get_bd_intf_pins pcie_phy/GT0_Serial]
  connect_bd_intf_net -intf_net gt_quad_1_GT_Serial [get_bd_intf_pins gtwiz_versal_0/Quad1_GT_Serial] [get_bd_intf_pins pcie_phy/GT1_Serial]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX0 [get_bd_intf_pins gtwiz_versal_0/INTF0_RX0_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX0]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX1 [get_bd_intf_pins gtwiz_versal_0/INTF0_RX1_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX1]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX2 [get_bd_intf_pins gtwiz_versal_0/INTF0_RX2_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX2]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX3 [get_bd_intf_pins gtwiz_versal_0/INTF0_RX3_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX3]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX4 [get_bd_intf_pins gtwiz_versal_0/INTF0_RX4_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX4]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX5 [get_bd_intf_pins gtwiz_versal_0/INTF0_RX5_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX5]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX6 [get_bd_intf_pins gtwiz_versal_0/INTF0_RX6_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX6]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX7 [get_bd_intf_pins gtwiz_versal_0/INTF0_RX7_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX7]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX0 [get_bd_intf_pins gtwiz_versal_0/INTF0_TX0_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX0]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX1 [get_bd_intf_pins gtwiz_versal_0/INTF0_TX1_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX1]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX2 [get_bd_intf_pins gtwiz_versal_0/INTF0_TX2_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX2]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX3 [get_bd_intf_pins gtwiz_versal_0/INTF0_TX3_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX3]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX4 [get_bd_intf_pins gtwiz_versal_0/INTF0_TX4_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX4]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX5 [get_bd_intf_pins gtwiz_versal_0/INTF0_TX5_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX5]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX6 [get_bd_intf_pins gtwiz_versal_0/INTF0_TX6_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX6]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX7 [get_bd_intf_pins gtwiz_versal_0/INTF0_TX7_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX7]
  connect_bd_intf_net -intf_net pcie_phy_gt_rxmargin_q0 [get_bd_intf_pins gtwiz_versal_0/QUAD0_GT_RXMARGIN_INTF] [get_bd_intf_pins pcie_phy/gt_rxmargin_q0]
  connect_bd_intf_net -intf_net pcie_phy_gt_rxmargin_q1 [get_bd_intf_pins gtwiz_versal_0/QUAD1_GT_RXMARGIN_INTF] [get_bd_intf_pins pcie_phy/gt_rxmargin_q1]
  connect_bd_intf_net -intf_net pcie_phy_mac_rx [get_bd_intf_pins pcie/phy_mac_rx] [get_bd_intf_pins pcie_phy/phy_mac_rx]
  connect_bd_intf_net -intf_net pcie_phy_mac_tx [get_bd_intf_pins pcie/phy_mac_tx] [get_bd_intf_pins pcie_phy/phy_mac_tx]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_command [get_bd_intf_pins pcie/phy_mac_command] [get_bd_intf_pins pcie_phy/phy_mac_command]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_rx_margining [get_bd_intf_pins pcie/phy_mac_rx_margining] [get_bd_intf_pins pcie_phy/phy_mac_rx_margining]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_status [get_bd_intf_pins pcie/phy_mac_status] [get_bd_intf_pins pcie_phy/phy_mac_status]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_drive [get_bd_intf_pins pcie/phy_mac_tx_drive] [get_bd_intf_pins pcie_phy/phy_mac_tx_drive]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_eq [get_bd_intf_pins pcie/phy_mac_tx_eq] [get_bd_intf_pins pcie_phy/phy_mac_tx_eq]

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
  connect_bd_net -net gt_quad_1_ch0_phyready  [get_bd_pins gtwiz_versal_0/QUAD1_ch0_phyready] \
  [get_bd_pins pcie_phy/ch4_phyready]
  connect_bd_net -net gt_quad_1_ch0_phystatus  [get_bd_pins gtwiz_versal_0/QUAD1_ch0_phystatus] \
  [get_bd_pins pcie_phy/ch4_phystatus]
  connect_bd_net -net gt_quad_1_ch1_phyready  [get_bd_pins gtwiz_versal_0/QUAD1_ch1_phyready] \
  [get_bd_pins pcie_phy/ch5_phyready]
  connect_bd_net -net gt_quad_1_ch1_phystatus  [get_bd_pins gtwiz_versal_0/QUAD1_ch1_phystatus] \
  [get_bd_pins pcie_phy/ch5_phystatus]
  connect_bd_net -net gt_quad_1_ch2_phyready  [get_bd_pins gtwiz_versal_0/QUAD1_ch2_phyready] \
  [get_bd_pins pcie_phy/ch6_phyready]
  connect_bd_net -net gt_quad_1_ch2_phystatus  [get_bd_pins gtwiz_versal_0/QUAD1_ch2_phystatus] \
  [get_bd_pins pcie_phy/ch6_phystatus]
  connect_bd_net -net gt_quad_1_ch3_phyready  [get_bd_pins gtwiz_versal_0/QUAD1_ch3_phyready] \
  [get_bd_pins pcie_phy/ch7_phyready]
  connect_bd_net -net gt_quad_1_ch3_phystatus  [get_bd_pins gtwiz_versal_0/QUAD1_ch3_phystatus] \
  [get_bd_pins pcie_phy/ch7_phystatus]
  connect_bd_net -net ilconstant_1_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins bufg_gt_sysclk/BUFG_GT_CE]
  connect_bd_net -net pcie_pcie_ltssm_state  [get_bd_pins pcie/pcie_ltssm_state] \
  [get_bd_pins pcie_ltssm_state] \
  [get_bd_pins pcie_phy/pcie_ltssm_state]
  connect_bd_net -net pcie_phy_gt_pcieltssm  [get_bd_pins pcie_phy/gt_pcieltssm] \
  [get_bd_pins gtwiz_versal_0/QUAD0_pcieltssm] \
  [get_bd_pins gtwiz_versal_0/QUAD1_pcieltssm]
  connect_bd_net -net pcie_phy_gtrefclk  [get_bd_pins pcie_phy/gtrefclk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_GTREFCLK0] \
  [get_bd_pins gtwiz_versal_0/QUAD1_GTREFCLK0]
  connect_bd_net -net pcie_phy_pcierstb  [get_bd_pins pcie_phy/pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch0_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch1_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch2_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch3_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD1_ch0_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD1_ch1_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD1_ch2_pcierstb] \
  [get_bd_pins gtwiz_versal_0/QUAD1_ch3_pcierstb]
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
  [get_bd_pins gtwiz_versal_0/QUAD1_TX0_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD1_TX1_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD1_TX2_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD1_TX3_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD1_RX0_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD1_RX1_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD1_RX2_usrclk] \
  [get_bd_pins gtwiz_versal_0/QUAD1_RX3_usrclk] \
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

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {



  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Create interface ports
  set CH0_DDR4_0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 CH0_DDR4_0_0 ]

  set pcie_mgt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_mgt ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]

  set sys_clk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $sys_clk0_0


  # Create ports

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: qdma_0_support
  create_hier_cell_qdma_0_support [current_bd_instance .] qdma_0_support

  # Create instance: qdma_0, and set properties
  set qdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:qdma qdma_0 ]
  set_property -dict [list \
    CONFIG.MSI_X_OPTIONS {None} \
    CONFIG.PF0_SRIOV_VF_DEVICE_ID {C048} \
    CONFIG.axi_data_width {512_bit} \
    CONFIG.axibar_notranslate {true} \
    CONFIG.axibar_num {2} \
    CONFIG.axilite_master_en {false} \
    CONFIG.axisten_freq {250} \
    CONFIG.bridge_burst {TRUE} \
    CONFIG.csr_axilite_slave {true} \
    CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.dma_reset_source_sel {Phy_Ready} \
    CONFIG.en_axi_master_if {true} \
    CONFIG.enable_64bit {false} \
    CONFIG.enable_gtwizard {true} \
    CONFIG.functional_mode {AXI_Bridge} \
    CONFIG.last_core_cap_addr {0x1F0} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.pcie_blk_locn {X1Y0} \
    CONFIG.pf0_bar0_prefetchable_qdma {true} \
    CONFIG.pf0_bar0_scale_qdma {Terabytes} \
    CONFIG.pf0_bar0_size_qdma {16} \
    CONFIG.pf0_bar0_type_qdma {AXI_Bridge_Master} \
    CONFIG.pf0_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf0_class_code_base_qdma {06} \
    CONFIG.pf0_class_code_sub_qdma {0A} \
    CONFIG.pf0_device_id {B0C8} \
    CONFIG.pf0_sriov_bar0_size {4} \
    CONFIG.pf0_sriov_bar0_type {AXI_Bridge_Master} \
    CONFIG.pf0_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf1_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf1_class_code_base_qdma {06} \
    CONFIG.pf1_class_code_sub_qdma {0A} \
    CONFIG.pf1_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf2_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf2_class_code_base_qdma {06} \
    CONFIG.pf2_class_code_sub_qdma {0A} \
    CONFIG.pf2_device_id {B2C8} \
    CONFIG.pf2_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf3_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf3_class_code_base_qdma {06} \
    CONFIG.pf3_class_code_sub_qdma {0A} \
    CONFIG.pf3_device_id {B3C8} \
    CONFIG.pf3_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pl_link_cap_max_link_speed {16.0_GT/s} \
    CONFIG.pl_link_cap_max_link_width {X8} \
  ] $qdma_0


  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [list \
    CONFIG.CPM_CONFIG { \
      AURORA_LINE_RATE_GPBS {10.0} \
      BOOT_SECONDARY_PCIE_ENABLE {0} \
      CPM_A0_REFCLK {0} \
      CPM_A1_REFCLK {0} \
      CPM_AUX0_REF_CTRL_ACT_FREQMHZ {899.991028} \
      CPM_AUX0_REF_CTRL_DIVISOR0 {2} \
      CPM_AUX0_REF_CTRL_FREQMHZ {900} \
      CPM_AUX1_REF_CTRL_ACT_FREQMHZ {899.991028} \
      CPM_AUX1_REF_CTRL_DIVISOR0 {2} \
      CPM_AUX1_REF_CTRL_FREQMHZ {900} \
      CPM_AXI_SLV_BRIDGE_BASE_ADDRR_H {0x00000006} \
      CPM_AXI_SLV_BRIDGE_BASE_ADDRR_L {0x00000000} \
      CPM_AXI_SLV_MULTQ_BASE_ADDRR_H {0x00000006} \
      CPM_AXI_SLV_MULTQ_BASE_ADDRR_L {0x10000000} \
      CPM_AXI_SLV_XDMA_BASE_ADDRR_H {0x00000006} \
      CPM_AXI_SLV_XDMA_BASE_ADDRR_L {0x11000000} \
      CPM_CCIX_IS_MM_ONLY {0} \
      CPM_CCIX_PARTIAL_CACHELINE_SUPPORT {0} \
      CPM_CCIX_PORT_AGGREGATION_ENABLE {0} \
      CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_0 {HA0} \
      CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_1 {HA0} \
      CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_2 {HA0} \
      CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_3 {HA0} \
      CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_4 {HA0} \
      CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_5 {HA0} \
      CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_6 {HA0} \
      CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_7 {HA0} \
      CPM_CCIX_RSVRD_MEMORY_ATTRIB_0 {Normal_Non_Cacheable_Memory} \
      CPM_CCIX_RSVRD_MEMORY_ATTRIB_1 {Normal_Non_Cacheable_Memory} \
      CPM_CCIX_RSVRD_MEMORY_ATTRIB_2 {Normal_Non_Cacheable_Memory} \
      CPM_CCIX_RSVRD_MEMORY_ATTRIB_3 {Normal_Non_Cacheable_Memory} \
      CPM_CCIX_RSVRD_MEMORY_ATTRIB_4 {Normal_Non_Cacheable_Memory} \
      CPM_CCIX_RSVRD_MEMORY_ATTRIB_5 {Normal_Non_Cacheable_Memory} \
      CPM_CCIX_RSVRD_MEMORY_ATTRIB_6 {Normal_Non_Cacheable_Memory} \
      CPM_CCIX_RSVRD_MEMORY_ATTRIB_7 {Normal_Non_Cacheable_Memory} \
      CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_0 {0x00000000} \
      CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_1 {0x00000000} \
      CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_2 {0x00000000} \
      CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_3 {0x00000000} \
      CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_4 {0x00000000} \
      CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_5 {0x00000000} \
      CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_6 {0x00000000} \
      CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_7 {0x00000000} \
      CPM_CCIX_RSVRD_MEMORY_REGION_0 {0} \
      CPM_CCIX_RSVRD_MEMORY_REGION_1 {0} \
      CPM_CCIX_RSVRD_MEMORY_REGION_2 {0} \
      CPM_CCIX_RSVRD_MEMORY_REGION_3 {0} \
      CPM_CCIX_RSVRD_MEMORY_REGION_4 {0} \
      CPM_CCIX_RSVRD_MEMORY_REGION_5 {0} \
      CPM_CCIX_RSVRD_MEMORY_REGION_6 {0} \
      CPM_CCIX_RSVRD_MEMORY_REGION_7 {0} \
      CPM_CCIX_RSVRD_MEMORY_SIZE_0 {4GB} \
      CPM_CCIX_RSVRD_MEMORY_SIZE_1 {4GB} \
      CPM_CCIX_RSVRD_MEMORY_SIZE_2 {4GB} \
      CPM_CCIX_RSVRD_MEMORY_SIZE_3 {4GB} \
      CPM_CCIX_RSVRD_MEMORY_SIZE_4 {4GB} \
      CPM_CCIX_RSVRD_MEMORY_SIZE_5 {4GB} \
      CPM_CCIX_RSVRD_MEMORY_SIZE_6 {4GB} \
      CPM_CCIX_RSVRD_MEMORY_SIZE_7 {4GB} \
      CPM_CCIX_RSVRD_MEMORY_TYPE_0 {Other_or_Non_Specified_Memory_Type} \
      CPM_CCIX_RSVRD_MEMORY_TYPE_1 {Other_or_Non_Specified_Memory_Type} \
      CPM_CCIX_RSVRD_MEMORY_TYPE_2 {Other_or_Non_Specified_Memory_Type} \
      CPM_CCIX_RSVRD_MEMORY_TYPE_3 {Other_or_Non_Specified_Memory_Type} \
      CPM_CCIX_RSVRD_MEMORY_TYPE_4 {Other_or_Non_Specified_Memory_Type} \
      CPM_CCIX_RSVRD_MEMORY_TYPE_5 {Other_or_Non_Specified_Memory_Type} \
      CPM_CCIX_RSVRD_MEMORY_TYPE_6 {Other_or_Non_Specified_Memory_Type} \
      CPM_CCIX_RSVRD_MEMORY_TYPE_7 {Other_or_Non_Specified_Memory_Type} \
      CPM_CCIX_SELECT_AGENT {HA} \
      CPM_CDO_EN {0} \
      CPM_CLRERR_LANE_MARGIN {0} \
      CPM_CORE_REF_CTRL_ACT_FREQMHZ {899.991028} \
      CPM_CORE_REF_CTRL_DIVISOR0 {2} \
      CPM_CORE_REF_CTRL_FREQMHZ {900} \
      CPM_CPLL_CTRL_FBDIV {108} \
      CPM_CPLL_CTRL_SRCSEL {REF_CLK} \
      CPM_DBG_REF_CTRL_ACT_FREQMHZ {299.997009} \
      CPM_DBG_REF_CTRL_DIVISOR0 {6} \
      CPM_DBG_REF_CTRL_FREQMHZ {300} \
      CPM_DESIGN_USE_MODE {4} \
      CPM_DMA_CREDIT_INIT_DEMUX {1} \
      CPM_DMA_IS_MM_ONLY {0} \
      CPM_LSBUS_REF_CTRL_ACT_FREQMHZ {149.998505} \
      CPM_LSBUS_REF_CTRL_DIVISOR0 {12} \
      CPM_LSBUS_REF_CTRL_FREQMHZ {150} \
      CPM_NUM_CCIX_CREDIT_LINKS {0} \
      CPM_NUM_HNF_AGENTS {0} \
      CPM_NUM_HOME_OR_SLAVE_AGENTS {2} \
      CPM_NUM_REQ_AGENTS {0} \
      CPM_NUM_SLAVE_AGENTS {0} \
      CPM_PCIE0_AER_CAP_ENABLED {1} \
      CPM_PCIE0_ARI_CAP_ENABLED {1} \
      CPM_PCIE0_ASYNC_MODE {SRNS} \
      CPM_PCIE0_ATS_PRI_CAP_ON {0} \
      CPM_PCIE0_AXIBAR_NUM {2} \
      CPM_PCIE0_AXISTEN_IF_CC_ALIGNMENT_MODE {DWORD_Aligned} \
      CPM_PCIE0_AXISTEN_IF_COMPL_TIMEOUT_REG0 {BEBC20} \
      CPM_PCIE0_AXISTEN_IF_COMPL_TIMEOUT_REG1 {2FAF080} \
      CPM_PCIE0_AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned} \
      CPM_PCIE0_AXISTEN_IF_ENABLE_256_TAGS {0} \
      CPM_PCIE0_AXISTEN_IF_ENABLE_CLIENT_TAG {0} \
      CPM_PCIE0_AXISTEN_IF_ENABLE_INTERNAL_MSIX_TABLE {0} \
      CPM_PCIE0_AXISTEN_IF_ENABLE_MESSAGE_RID_CHECK {1} \
      CPM_PCIE0_AXISTEN_IF_ENABLE_MSG_ROUTE {0} \
      CPM_PCIE0_AXISTEN_IF_ENABLE_RX_MSG_INTFC {0} \
      CPM_PCIE0_AXISTEN_IF_ENABLE_RX_TAG_SCALING {0} \
      CPM_PCIE0_AXISTEN_IF_ENABLE_TX_TAG_SCALING {0} \
      CPM_PCIE0_AXISTEN_IF_EXTEND_CPL_TIMEOUT {16ms_to_1s} \
      CPM_PCIE0_AXISTEN_IF_EXT_512 {0} \
      CPM_PCIE0_AXISTEN_IF_EXT_512_CC_STRADDLE {0} \
      CPM_PCIE0_AXISTEN_IF_EXT_512_CQ_STRADDLE {0} \
      CPM_PCIE0_AXISTEN_IF_EXT_512_RC_4TLP_STRADDLE {0} \
      CPM_PCIE0_AXISTEN_IF_EXT_512_RC_STRADDLE {1} \
      CPM_PCIE0_AXISTEN_IF_EXT_512_RQ_STRADDLE {0} \
      CPM_PCIE0_AXISTEN_IF_RC_ALIGNMENT_MODE {DWORD_Aligned} \
      CPM_PCIE0_AXISTEN_IF_RC_STRADDLE {0} \
      CPM_PCIE0_AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
      CPM_PCIE0_AXISTEN_IF_RX_PARITY_EN {1} \
      CPM_PCIE0_AXISTEN_IF_SIM_SHORT_CPL_TIMEOUT {0} \
      CPM_PCIE0_AXISTEN_IF_TX_PARITY_EN {0} \
      CPM_PCIE0_AXISTEN_IF_WIDTH {64} \
      CPM_PCIE0_AXISTEN_MSIX_VECTORS_PER_FUNCTION {8} \
      CPM_PCIE0_AXISTEN_USER_SPARE {0} \
      CPM_PCIE0_BRIDGE_AXI_SLAVE_IF {1} \
      CPM_PCIE0_CCIX_EN {0} \
      CPM_PCIE0_CCIX_OPT_TLP_GEN_AND_RECEPT_EN_CONTROL_INTERNAL {0} \
      CPM_PCIE0_CCIX_VENDOR_ID {0} \
      CPM_PCIE0_CFG_CTL_IF {0} \
      CPM_PCIE0_CFG_EXT_IF {0} \
      CPM_PCIE0_CFG_FC_IF {0} \
      CPM_PCIE0_CFG_MGMT_IF {0} \
      CPM_PCIE0_CFG_SPEC_4_0 {0} \
      CPM_PCIE0_CFG_STS_IF {0} \
      CPM_PCIE0_CFG_VEND_ID {10EE} \
      CPM_PCIE0_CONTROLLER_ENABLE {0} \
      CPM_PCIE0_COPY_PF0_ENABLED {0} \
      CPM_PCIE0_COPY_PF0_QDMA_ENABLED {1} \
      CPM_PCIE0_COPY_PF0_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE0_COPY_SRIOV_PF0_ENABLED {1} \
      CPM_PCIE0_COPY_XDMA_PF0_ENABLED {0} \
      CPM_PCIE0_CORE_CLK_FREQ {1000} \
      CPM_PCIE0_CORE_EDR_CLK_FREQ {625} \
      CPM_PCIE0_DMA_DATA_WIDTH {512bits} \
      CPM_PCIE0_DMA_ENABLE_SECURE {0} \
      CPM_PCIE0_DMA_INTF {AXI4} \
      CPM_PCIE0_DMA_MASK {256bits} \
      CPM_PCIE0_DMA_METERING_ENABLE {1} \
      CPM_PCIE0_DMA_MSI_RX_PIN_ENABLED {FALSE} \
      CPM_PCIE0_DMA_ROOT_PORT {0} \
      CPM_PCIE0_DSC_BYPASS_RD {0} \
      CPM_PCIE0_DSC_BYPASS_WR {0} \
      CPM_PCIE0_EDR_IF {0} \
      CPM_PCIE0_EDR_LINK_SPEED {None} \
      CPM_PCIE0_EN_PARITY {0} \
      CPM_PCIE0_EXT_PCIE_CFG_SPACE_ENABLED {Extended_Small} \
      CPM_PCIE0_FUNCTIONAL_MODE {None} \
      CPM_PCIE0_LANE_REVERSAL_EN {1} \
      CPM_PCIE0_LEGACY_EXT_PCIE_CFG_SPACE_ENABLED {0} \
      CPM_PCIE0_LINK_DEBUG_AXIST_EN {0} \
      CPM_PCIE0_LINK_DEBUG_EN {0} \
      CPM_PCIE0_LINK_SPEED0_FOR_POWER {GEN4} \
      CPM_PCIE0_LINK_WIDTH0_FOR_POWER {0} \
      CPM_PCIE0_MAILBOX_ENABLE {0} \
      CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s} \
      CPM_PCIE0_MCAP_ENABLE {0} \
      CPM_PCIE0_MESG_RSVD_IF {0} \
      CPM_PCIE0_MESG_TRANSMIT_IF {0} \
      CPM_PCIE0_MODE0_FOR_POWER {NONE} \
      CPM_PCIE0_MODES {None} \
      CPM_PCIE0_MODE_SELECTION {Advanced} \
      CPM_PCIE0_MSIX_RP_ENABLED {0} \
      CPM_PCIE0_MSI_X_OPTIONS {None} \
      CPM_PCIE0_NUM_USR_IRQ {1} \
      CPM_PCIE0_PASID_IF {0} \
      CPM_PCIE0_PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE {0} \
      CPM_PCIE0_PF0_ARI_CAP_NEXT_FUNC {0} \
      CPM_PCIE0_PF0_ARI_CAP_VER {1} \
      CPM_PCIE0_PF0_ATS_CAP_ON {0} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_0 {0x00000000e0000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_1 {0x0000008000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_2 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_3 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_4 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_5 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_0 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_1 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_2 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_3 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_4 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_5 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_0 {0x000000000efffffff} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_1 {0x00000081FFFFFFFF} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_2 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_3 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_4 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_5 {0x0000000000000000} \
      CPM_PCIE0_PF0_AXILITE_MASTER_64BIT {0} \
      CPM_PCIE0_PF0_AXILITE_MASTER_ENABLED {0} \
      CPM_PCIE0_PF0_AXILITE_MASTER_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_AXILITE_MASTER_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_AXILITE_MASTER_SIZE {128} \
      CPM_PCIE0_PF0_AXIST_BYPASS_64BIT {0} \
      CPM_PCIE0_PF0_AXIST_BYPASS_ENABLED {0} \
      CPM_PCIE0_PF0_AXIST_BYPASS_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_AXIST_BYPASS_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_AXIST_BYPASS_SIZE {128} \
      CPM_PCIE0_PF0_BAR0_64BIT {0} \
      CPM_PCIE0_PF0_BAR0_BRIDGE_64BIT {0} \
      CPM_PCIE0_PF0_BAR0_BRIDGE_ENABLED {1} \
      CPM_PCIE0_PF0_BAR0_BRIDGE_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR0_BRIDGE_SCALE {Gigabytes} \
      CPM_PCIE0_PF0_BAR0_BRIDGE_SIZE {1} \
      CPM_PCIE0_PF0_BAR0_BRIDGE_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR0_ENABLED {1} \
      CPM_PCIE0_PF0_BAR0_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR0_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR0_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR0_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR0_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR0_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR0_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR0_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR0_SCALE {Gigabytes} \
      CPM_PCIE0_PF0_BAR0_SIZE {1} \
      CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_SIZE {16} \
      CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_TYPE {DMA} \
      CPM_PCIE0_PF0_BAR0_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR0_XDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR0_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR0_XDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR0_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR0_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR0_XDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR1_64BIT {0} \
      CPM_PCIE0_PF0_BAR1_BRIDGE_ENABLED {0} \
      CPM_PCIE0_PF0_BAR1_BRIDGE_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR1_BRIDGE_SIZE {4} \
      CPM_PCIE0_PF0_BAR1_BRIDGE_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR1_ENABLED {0} \
      CPM_PCIE0_PF0_BAR1_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR1_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR1_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR1_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR1_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR1_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR1_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR1_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR1_SIZE {4} \
      CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR1_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR1_XDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR1_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR1_XDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR1_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR1_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR1_XDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR2_64BIT {0} \
      CPM_PCIE0_PF0_BAR2_BRIDGE_64BIT {0} \
      CPM_PCIE0_PF0_BAR2_BRIDGE_ENABLED {0} \
      CPM_PCIE0_PF0_BAR2_BRIDGE_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR2_BRIDGE_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR2_BRIDGE_SIZE {4} \
      CPM_PCIE0_PF0_BAR2_BRIDGE_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR2_ENABLED {0} \
      CPM_PCIE0_PF0_BAR2_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR2_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR2_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR2_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR2_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR2_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR2_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR2_SIZE {4} \
      CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR2_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR2_XDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR2_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR2_XDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR2_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR2_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR2_XDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR3_64BIT {0} \
      CPM_PCIE0_PF0_BAR3_BRIDGE_ENABLED {0} \
      CPM_PCIE0_PF0_BAR3_BRIDGE_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR3_BRIDGE_SIZE {4} \
      CPM_PCIE0_PF0_BAR3_BRIDGE_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR3_ENABLED {0} \
      CPM_PCIE0_PF0_BAR3_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR3_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR3_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR3_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR3_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR3_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR3_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR3_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR3_SIZE {4} \
      CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR3_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR3_XDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR3_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR3_XDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR3_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR3_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR3_XDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR4_64BIT {0} \
      CPM_PCIE0_PF0_BAR4_BRIDGE_64BIT {0} \
      CPM_PCIE0_PF0_BAR4_BRIDGE_ENABLED {0} \
      CPM_PCIE0_PF0_BAR4_BRIDGE_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR4_BRIDGE_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR4_BRIDGE_SIZE {4} \
      CPM_PCIE0_PF0_BAR4_BRIDGE_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR4_ENABLED {0} \
      CPM_PCIE0_PF0_BAR4_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR4_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR4_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR4_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR4_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR4_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR4_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR4_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR4_SIZE {4} \
      CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR4_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR4_XDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR4_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR4_XDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR4_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR4_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR4_XDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR5_64BIT {0} \
      CPM_PCIE0_PF0_BAR5_BRIDGE_ENABLED {0} \
      CPM_PCIE0_PF0_BAR5_BRIDGE_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR5_BRIDGE_SIZE {4} \
      CPM_PCIE0_PF0_BAR5_BRIDGE_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR5_ENABLED {0} \
      CPM_PCIE0_PF0_BAR5_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR5_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR5_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR5_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR5_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR5_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR5_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR5_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR5_SIZE {4} \
      CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BAR5_TYPE {Memory} \
      CPM_PCIE0_PF0_BAR5_XDMA_64BIT {0} \
      CPM_PCIE0_PF0_BAR5_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF0_BAR5_XDMA_ENABLED {0} \
      CPM_PCIE0_PF0_BAR5_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_BAR5_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_BAR5_XDMA_SIZE {4} \
      CPM_PCIE0_PF0_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF0_BASE_CLASS_MENU {Memory_controller} \
      CPM_PCIE0_PF0_BASE_CLASS_VALUE {06} \
      CPM_PCIE0_PF0_CAPABILITY_POINTER {80} \
      CPM_PCIE0_PF0_CFG_DEV_ID {B03F} \
      CPM_PCIE0_PF0_CFG_REV_ID {0} \
      CPM_PCIE0_PF0_CFG_SUBSYS_ID {7} \
      CPM_PCIE0_PF0_CFG_SUBSYS_VEND_ID {10EE} \
      CPM_PCIE0_PF0_CLASS_CODE {0x060400} \
      CPM_PCIE0_PF0_DEV_CAP_10B_TAG_EN {0} \
      CPM_PCIE0_PF0_DEV_CAP_ENDPOINT_L0S_LATENCY {less_than_64ns} \
      CPM_PCIE0_PF0_DEV_CAP_ENDPOINT_L1S_LATENCY {less_than_1us} \
      CPM_PCIE0_PF0_DEV_CAP_EXT_TAG_EN {0} \
      CPM_PCIE0_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {0} \
      CPM_PCIE0_PF0_DEV_CAP_MAX_PAYLOAD {1024_bytes} \
      CPM_PCIE0_PF0_DLL_FEATURE_CAP_ID {0x0025} \
      CPM_PCIE0_PF0_DLL_FEATURE_CAP_ON {1} \
      CPM_PCIE0_PF0_DLL_FEATURE_CAP_VER {1} \
      CPM_PCIE0_PF0_DSN_CAP_ENABLE {0} \
      CPM_PCIE0_PF0_EXPANSION_ROM_ENABLED {0} \
      CPM_PCIE0_PF0_EXPANSION_ROM_QDMA_ENABLED {0} \
      CPM_PCIE0_PF0_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_EXPANSION_ROM_QDMA_SIZE {2} \
      CPM_PCIE0_PF0_EXPANSION_ROM_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_EXPANSION_ROM_SIZE {2} \
      CPM_PCIE0_PF0_INTERFACE_VALUE {00} \
      CPM_PCIE0_PF0_INTERRUPT_PIN {NONE} \
      CPM_PCIE0_PF0_LINK_CAP_ASPM_SUPPORT {No_ASPM} \
      CPM_PCIE0_PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {1} \
      CPM_PCIE0_PF0_MARGINING_CAP_ID {0} \
      CPM_PCIE0_PF0_MARGINING_CAP_ON {1} \
      CPM_PCIE0_PF0_MARGINING_CAP_VER {1} \
      CPM_PCIE0_PF0_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE0_PF0_MSIX_CAP_PBA_OFFSET {8FE0} \
      CPM_PCIE0_PF0_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE0_PF0_MSIX_CAP_TABLE_OFFSET {8000} \
      CPM_PCIE0_PF0_MSIX_CAP_TABLE_SIZE {1F} \
      CPM_PCIE0_PF0_MSIX_ENABLED {1} \
      CPM_PCIE0_PF0_MSI_CAP_MULTIMSGCAP {1_vector} \
      CPM_PCIE0_PF0_MSI_CAP_PERVECMASKCAP {0} \
      CPM_PCIE0_PF0_MSI_ENABLED {1} \
      CPM_PCIE0_PF0_PASID_CAP_MAX_PASID_WIDTH {1} \
      CPM_PCIE0_PF0_PASID_CAP_ON {0} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_AXIL_MASTER {0} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_AXIST_BYPASS {0} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_0 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_1 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_2 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_3 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_4 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_5 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_0 {0} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_1 {0} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_2 {0} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_3 {0} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_4 {0} \
      CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_5 {0} \
      CPM_PCIE0_PF0_PL16_CAP_ID {0} \
      CPM_PCIE0_PF0_PL16_CAP_ON {1} \
      CPM_PCIE0_PF0_PL16_CAP_VER {1} \
      CPM_PCIE0_PF0_PM_CAP_ID {0} \
      CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D0 {1} \
      CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D1 {1} \
      CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D3COLD {1} \
      CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D3HOT {1} \
      CPM_PCIE0_PF0_PM_CAP_SUPP_D1_STATE {1} \
      CPM_PCIE0_PF0_PM_CAP_VER_ID {3} \
      CPM_PCIE0_PF0_PM_CSR_NOSOFTRESET {1} \
      CPM_PCIE0_PF0_PRI_CAP_ON {0} \
      CPM_PCIE0_PF0_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
      CPM_PCIE0_PF0_SRIOV_BAR0_64BIT {0} \
      CPM_PCIE0_PF0_SRIOV_BAR0_ENABLED {1} \
      CPM_PCIE0_PF0_SRIOV_BAR0_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_SRIOV_BAR0_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_SRIOV_BAR0_SIZE {4} \
      CPM_PCIE0_PF0_SRIOV_BAR0_TYPE {Memory} \
      CPM_PCIE0_PF0_SRIOV_BAR1_64BIT {0} \
      CPM_PCIE0_PF0_SRIOV_BAR1_ENABLED {0} \
      CPM_PCIE0_PF0_SRIOV_BAR1_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_SRIOV_BAR1_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_SRIOV_BAR1_SIZE {4} \
      CPM_PCIE0_PF0_SRIOV_BAR1_TYPE {Memory} \
      CPM_PCIE0_PF0_SRIOV_BAR2_64BIT {0} \
      CPM_PCIE0_PF0_SRIOV_BAR2_ENABLED {0} \
      CPM_PCIE0_PF0_SRIOV_BAR2_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_SRIOV_BAR2_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_SRIOV_BAR2_SIZE {4} \
      CPM_PCIE0_PF0_SRIOV_BAR2_TYPE {Memory} \
      CPM_PCIE0_PF0_SRIOV_BAR3_64BIT {0} \
      CPM_PCIE0_PF0_SRIOV_BAR3_ENABLED {0} \
      CPM_PCIE0_PF0_SRIOV_BAR3_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_SRIOV_BAR3_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_SRIOV_BAR3_SIZE {4} \
      CPM_PCIE0_PF0_SRIOV_BAR3_TYPE {Memory} \
      CPM_PCIE0_PF0_SRIOV_BAR4_64BIT {0} \
      CPM_PCIE0_PF0_SRIOV_BAR4_ENABLED {0} \
      CPM_PCIE0_PF0_SRIOV_BAR4_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_SRIOV_BAR4_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_SRIOV_BAR4_SIZE {4} \
      CPM_PCIE0_PF0_SRIOV_BAR4_TYPE {Memory} \
      CPM_PCIE0_PF0_SRIOV_BAR5_64BIT {0} \
      CPM_PCIE0_PF0_SRIOV_BAR5_ENABLED {0} \
      CPM_PCIE0_PF0_SRIOV_BAR5_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_SRIOV_BAR5_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_SRIOV_BAR5_SIZE {4} \
      CPM_PCIE0_PF0_SRIOV_BAR5_TYPE {Memory} \
      CPM_PCIE0_PF0_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE0_PF0_SRIOV_CAP_INITIAL_VF {4} \
      CPM_PCIE0_PF0_SRIOV_CAP_TOTAL_VF {0} \
      CPM_PCIE0_PF0_SRIOV_CAP_VER {1} \
      CPM_PCIE0_PF0_SRIOV_FIRST_VF_OFFSET {4} \
      CPM_PCIE0_PF0_SRIOV_FUNC_DEP_LINK {0} \
      CPM_PCIE0_PF0_SRIOV_SUPPORTED_PAGE_SIZE {553} \
      CPM_PCIE0_PF0_SRIOV_VF_DEVICE_ID {C03F} \
      CPM_PCIE0_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE0_PF0_SUB_CLASS_VALUE {04} \
      CPM_PCIE0_PF0_TPHR_CAP_DEV_SPECIFIC_MODE {1} \
      CPM_PCIE0_PF0_TPHR_CAP_ENABLE {0} \
      CPM_PCIE0_PF0_TPHR_CAP_INT_VEC_MODE {1} \
      CPM_PCIE0_PF0_TPHR_CAP_ST_TABLE_LOC {ST_Table_not_present} \
      CPM_PCIE0_PF0_TPHR_CAP_ST_TABLE_SIZE {16} \
      CPM_PCIE0_PF0_TPHR_CAP_VER {1} \
      CPM_PCIE0_PF0_TPHR_ENABLE {0} \
      CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE0_PF0_VC_ARB_CAPABILITY {0} \
      CPM_PCIE0_PF0_VC_ARB_TBL_OFFSET {0} \
      CPM_PCIE0_PF0_VC_CAP_ENABLED {0} \
      CPM_PCIE0_PF0_VC_CAP_VER {1} \
      CPM_PCIE0_PF0_VC_EXTENDED_COUNT {0} \
      CPM_PCIE0_PF0_VC_LOW_PRIORITY_EXTENDED_COUNT {0} \
      CPM_PCIE0_PF0_XDMA_64BIT {0} \
      CPM_PCIE0_PF0_XDMA_ENABLED {0} \
      CPM_PCIE0_PF0_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF0_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF0_XDMA_SIZE {128} \
      CPM_PCIE0_PF1_ARI_CAP_NEXT_FUNC {0} \
      CPM_PCIE0_PF1_ATS_CAP_ON {0} \
      CPM_PCIE0_PF1_AXILITE_MASTER_64BIT {0} \
      CPM_PCIE0_PF1_AXILITE_MASTER_ENABLED {0} \
      CPM_PCIE0_PF1_AXILITE_MASTER_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_AXILITE_MASTER_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_AXILITE_MASTER_SIZE {128} \
      CPM_PCIE0_PF1_AXIST_BYPASS_64BIT {0} \
      CPM_PCIE0_PF1_AXIST_BYPASS_ENABLED {0} \
      CPM_PCIE0_PF1_AXIST_BYPASS_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_AXIST_BYPASS_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_AXIST_BYPASS_SIZE {128} \
      CPM_PCIE0_PF1_BAR0_64BIT {0} \
      CPM_PCIE0_PF1_BAR0_ENABLED {1} \
      CPM_PCIE0_PF1_BAR0_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR0_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR0_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR0_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR0_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR0_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR0_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR0_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR0_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR0_SIZE {128} \
      CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_SIZE {16} \
      CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_TYPE {DMA} \
      CPM_PCIE0_PF1_BAR0_TYPE {Memory} \
      CPM_PCIE0_PF1_BAR0_XDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR0_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR0_XDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR0_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR0_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR0_XDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR1_64BIT {0} \
      CPM_PCIE0_PF1_BAR1_ENABLED {0} \
      CPM_PCIE0_PF1_BAR1_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR1_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR1_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR1_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR1_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR1_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR1_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR1_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR1_SIZE {4} \
      CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR1_TYPE {Memory} \
      CPM_PCIE0_PF1_BAR1_XDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR1_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR1_XDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR1_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR1_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR1_XDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR2_64BIT {0} \
      CPM_PCIE0_PF1_BAR2_ENABLED {0} \
      CPM_PCIE0_PF1_BAR2_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR2_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR2_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR2_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR2_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR2_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR2_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR2_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR2_SIZE {4} \
      CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR2_TYPE {Memory} \
      CPM_PCIE0_PF1_BAR2_XDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR2_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR2_XDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR2_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR2_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR2_XDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR3_64BIT {0} \
      CPM_PCIE0_PF1_BAR3_ENABLED {0} \
      CPM_PCIE0_PF1_BAR3_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR3_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR3_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR3_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR3_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR3_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR3_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR3_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR3_SIZE {4} \
      CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR3_TYPE {Memory} \
      CPM_PCIE0_PF1_BAR3_XDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR3_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR3_XDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR3_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR3_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR3_XDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR4_64BIT {0} \
      CPM_PCIE0_PF1_BAR4_ENABLED {0} \
      CPM_PCIE0_PF1_BAR4_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR4_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR4_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR4_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR4_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR4_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR4_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR4_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR4_SIZE {4} \
      CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR4_TYPE {Memory} \
      CPM_PCIE0_PF1_BAR4_XDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR4_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR4_XDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR4_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR4_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR4_XDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR5_64BIT {0} \
      CPM_PCIE0_PF1_BAR5_ENABLED {0} \
      CPM_PCIE0_PF1_BAR5_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR5_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR5_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR5_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR5_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR5_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR5_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR5_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR5_SIZE {4} \
      CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BAR5_TYPE {Memory} \
      CPM_PCIE0_PF1_BAR5_XDMA_64BIT {0} \
      CPM_PCIE0_PF1_BAR5_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF1_BAR5_XDMA_ENABLED {0} \
      CPM_PCIE0_PF1_BAR5_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_BAR5_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_BAR5_XDMA_SIZE {4} \
      CPM_PCIE0_PF1_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF1_BASE_CLASS_MENU {Memory_controller} \
      CPM_PCIE0_PF1_BASE_CLASS_VALUE {05} \
      CPM_PCIE0_PF1_CAPABILITY_POINTER {80} \
      CPM_PCIE0_PF1_CFG_DEV_ID {B13F} \
      CPM_PCIE0_PF1_CFG_REV_ID {0} \
      CPM_PCIE0_PF1_CFG_SUBSYS_ID {7} \
      CPM_PCIE0_PF1_CFG_SUBSYS_VEND_ID {10EE} \
      CPM_PCIE0_PF1_CLASS_CODE {0x058000} \
      CPM_PCIE0_PF1_DSN_CAP_ENABLE {0} \
      CPM_PCIE0_PF1_EXPANSION_ROM_ENABLED {0} \
      CPM_PCIE0_PF1_EXPANSION_ROM_QDMA_ENABLED {0} \
      CPM_PCIE0_PF1_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_EXPANSION_ROM_QDMA_SIZE {2} \
      CPM_PCIE0_PF1_EXPANSION_ROM_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_EXPANSION_ROM_SIZE {2} \
      CPM_PCIE0_PF1_INTERFACE_VALUE {00} \
      CPM_PCIE0_PF1_INTERRUPT_PIN {NONE} \
      CPM_PCIE0_PF1_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE0_PF1_MSIX_CAP_PBA_OFFSET {8FE0} \
      CPM_PCIE0_PF1_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE0_PF1_MSIX_CAP_TABLE_OFFSET {8000} \
      CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE {1F} \
      CPM_PCIE0_PF1_MSIX_ENABLED {1} \
      CPM_PCIE0_PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
      CPM_PCIE0_PF1_MSI_CAP_PERVECMASKCAP {0} \
      CPM_PCIE0_PF1_MSI_ENABLED {1} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_AXIL_MASTER {0} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_AXIST_BYPASS {0} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_2 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_0 {0} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_1 {0} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_2 {0} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_3 {0} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_4 {0} \
      CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_5 {0} \
      CPM_PCIE0_PF1_PRI_CAP_ON {0} \
      CPM_PCIE0_PF1_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
      CPM_PCIE0_PF1_SRIOV_BAR0_64BIT {0} \
      CPM_PCIE0_PF1_SRIOV_BAR0_ENABLED {1} \
      CPM_PCIE0_PF1_SRIOV_BAR0_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_SRIOV_BAR0_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_SRIOV_BAR0_SIZE {4} \
      CPM_PCIE0_PF1_SRIOV_BAR0_TYPE {Memory} \
      CPM_PCIE0_PF1_SRIOV_BAR1_64BIT {0} \
      CPM_PCIE0_PF1_SRIOV_BAR1_ENABLED {0} \
      CPM_PCIE0_PF1_SRIOV_BAR1_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_SRIOV_BAR1_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_SRIOV_BAR1_SIZE {4} \
      CPM_PCIE0_PF1_SRIOV_BAR1_TYPE {Memory} \
      CPM_PCIE0_PF1_SRIOV_BAR2_64BIT {0} \
      CPM_PCIE0_PF1_SRIOV_BAR2_ENABLED {0} \
      CPM_PCIE0_PF1_SRIOV_BAR2_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_SRIOV_BAR2_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_SRIOV_BAR2_SIZE {4} \
      CPM_PCIE0_PF1_SRIOV_BAR2_TYPE {Memory} \
      CPM_PCIE0_PF1_SRIOV_BAR3_64BIT {0} \
      CPM_PCIE0_PF1_SRIOV_BAR3_ENABLED {0} \
      CPM_PCIE0_PF1_SRIOV_BAR3_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_SRIOV_BAR3_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_SRIOV_BAR3_SIZE {4} \
      CPM_PCIE0_PF1_SRIOV_BAR3_TYPE {Memory} \
      CPM_PCIE0_PF1_SRIOV_BAR4_64BIT {0} \
      CPM_PCIE0_PF1_SRIOV_BAR4_ENABLED {0} \
      CPM_PCIE0_PF1_SRIOV_BAR4_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_SRIOV_BAR4_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_SRIOV_BAR4_SIZE {4} \
      CPM_PCIE0_PF1_SRIOV_BAR4_TYPE {Memory} \
      CPM_PCIE0_PF1_SRIOV_BAR5_64BIT {0} \
      CPM_PCIE0_PF1_SRIOV_BAR5_ENABLED {0} \
      CPM_PCIE0_PF1_SRIOV_BAR5_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_SRIOV_BAR5_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_SRIOV_BAR5_SIZE {4} \
      CPM_PCIE0_PF1_SRIOV_BAR5_TYPE {Memory} \
      CPM_PCIE0_PF1_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE0_PF1_SRIOV_CAP_INITIAL_VF {4} \
      CPM_PCIE0_PF1_SRIOV_CAP_TOTAL_VF {0} \
      CPM_PCIE0_PF1_SRIOV_CAP_VER {1} \
      CPM_PCIE0_PF1_SRIOV_FIRST_VF_OFFSET {7} \
      CPM_PCIE0_PF1_SRIOV_FUNC_DEP_LINK {0} \
      CPM_PCIE0_PF1_SRIOV_SUPPORTED_PAGE_SIZE {553} \
      CPM_PCIE0_PF1_SRIOV_VF_DEVICE_ID {C13F} \
      CPM_PCIE0_PF1_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE0_PF1_SUB_CLASS_VALUE {80} \
      CPM_PCIE0_PF1_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE0_PF1_VEND_ID {0} \
      CPM_PCIE0_PF1_XDMA_64BIT {0} \
      CPM_PCIE0_PF1_XDMA_ENABLED {0} \
      CPM_PCIE0_PF1_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF1_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF1_XDMA_SIZE {128} \
      CPM_PCIE0_PF2_ARI_CAP_NEXT_FUNC {0} \
      CPM_PCIE0_PF2_ATS_CAP_ON {0} \
      CPM_PCIE0_PF2_AXILITE_MASTER_64BIT {0} \
      CPM_PCIE0_PF2_AXILITE_MASTER_ENABLED {0} \
      CPM_PCIE0_PF2_AXILITE_MASTER_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_AXILITE_MASTER_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_AXILITE_MASTER_SIZE {128} \
      CPM_PCIE0_PF2_AXIST_BYPASS_64BIT {0} \
      CPM_PCIE0_PF2_AXIST_BYPASS_ENABLED {0} \
      CPM_PCIE0_PF2_AXIST_BYPASS_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_AXIST_BYPASS_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_AXIST_BYPASS_SIZE {128} \
      CPM_PCIE0_PF2_BAR0_64BIT {0} \
      CPM_PCIE0_PF2_BAR0_ENABLED {1} \
      CPM_PCIE0_PF2_BAR0_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR0_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR0_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR0_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR0_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR0_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR0_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR0_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR0_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR0_SIZE {128} \
      CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_SIZE {16} \
      CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_TYPE {DMA} \
      CPM_PCIE0_PF2_BAR0_TYPE {Memory} \
      CPM_PCIE0_PF2_BAR0_XDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR0_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR0_XDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR0_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR0_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR0_XDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR1_64BIT {0} \
      CPM_PCIE0_PF2_BAR1_ENABLED {0} \
      CPM_PCIE0_PF2_BAR1_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR1_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR1_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR1_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR1_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR1_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR1_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR1_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR1_SIZE {4} \
      CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR1_TYPE {Memory} \
      CPM_PCIE0_PF2_BAR1_XDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR1_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR1_XDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR1_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR1_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR1_XDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR2_64BIT {0} \
      CPM_PCIE0_PF2_BAR2_ENABLED {0} \
      CPM_PCIE0_PF2_BAR2_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR2_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR2_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR2_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR2_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR2_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR2_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR2_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR2_SIZE {4} \
      CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR2_TYPE {Memory} \
      CPM_PCIE0_PF2_BAR2_XDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR2_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR2_XDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR2_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR2_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR2_XDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR3_64BIT {0} \
      CPM_PCIE0_PF2_BAR3_ENABLED {0} \
      CPM_PCIE0_PF2_BAR3_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR3_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR3_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR3_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR3_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR3_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR3_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR3_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR3_SIZE {4} \
      CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR3_TYPE {Memory} \
      CPM_PCIE0_PF2_BAR3_XDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR3_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR3_XDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR3_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR3_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR3_XDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR4_64BIT {0} \
      CPM_PCIE0_PF2_BAR4_ENABLED {0} \
      CPM_PCIE0_PF2_BAR4_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR4_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR4_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR4_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR4_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR4_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR4_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR4_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR4_SIZE {4} \
      CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR4_TYPE {Memory} \
      CPM_PCIE0_PF2_BAR4_XDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR4_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR4_XDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR4_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR4_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR4_XDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR5_64BIT {0} \
      CPM_PCIE0_PF2_BAR5_ENABLED {0} \
      CPM_PCIE0_PF2_BAR5_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR5_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR5_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR5_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR5_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR5_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR5_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR5_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR5_SIZE {4} \
      CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BAR5_TYPE {Memory} \
      CPM_PCIE0_PF2_BAR5_XDMA_64BIT {0} \
      CPM_PCIE0_PF2_BAR5_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF2_BAR5_XDMA_ENABLED {0} \
      CPM_PCIE0_PF2_BAR5_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_BAR5_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_BAR5_XDMA_SIZE {4} \
      CPM_PCIE0_PF2_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF2_BASE_CLASS_MENU {Memory_controller} \
      CPM_PCIE0_PF2_BASE_CLASS_VALUE {05} \
      CPM_PCIE0_PF2_CAPABILITY_POINTER {80} \
      CPM_PCIE0_PF2_CFG_DEV_ID {B23F} \
      CPM_PCIE0_PF2_CFG_REV_ID {0} \
      CPM_PCIE0_PF2_CFG_SUBSYS_ID {7} \
      CPM_PCIE0_PF2_CFG_SUBSYS_VEND_ID {10EE} \
      CPM_PCIE0_PF2_CLASS_CODE {0x058000} \
      CPM_PCIE0_PF2_DSN_CAP_ENABLE {0} \
      CPM_PCIE0_PF2_EXPANSION_ROM_ENABLED {0} \
      CPM_PCIE0_PF2_EXPANSION_ROM_QDMA_ENABLED {0} \
      CPM_PCIE0_PF2_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_EXPANSION_ROM_QDMA_SIZE {2} \
      CPM_PCIE0_PF2_EXPANSION_ROM_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_EXPANSION_ROM_SIZE {2} \
      CPM_PCIE0_PF2_INTERFACE_VALUE {00} \
      CPM_PCIE0_PF2_INTERRUPT_PIN {NONE} \
      CPM_PCIE0_PF2_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE0_PF2_MSIX_CAP_PBA_OFFSET {8FE0} \
      CPM_PCIE0_PF2_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE0_PF2_MSIX_CAP_TABLE_OFFSET {8000} \
      CPM_PCIE0_PF2_MSIX_CAP_TABLE_SIZE {1F} \
      CPM_PCIE0_PF2_MSIX_ENABLED {1} \
      CPM_PCIE0_PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
      CPM_PCIE0_PF2_MSI_CAP_PERVECMASKCAP {0} \
      CPM_PCIE0_PF2_MSI_ENABLED {1} \
      CPM_PCIE0_PF2_PASID_CAP_MAX_PASID_WIDTH {1} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_AXIL_MASTER {0} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_AXIST_BYPASS {0} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_2 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_0 {0} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_1 {0} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_2 {0} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_3 {0} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_4 {0} \
      CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_5 {0} \
      CPM_PCIE0_PF2_PRI_CAP_ON {0} \
      CPM_PCIE0_PF2_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
      CPM_PCIE0_PF2_SRIOV_BAR0_64BIT {0} \
      CPM_PCIE0_PF2_SRIOV_BAR0_ENABLED {1} \
      CPM_PCIE0_PF2_SRIOV_BAR0_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_SRIOV_BAR0_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_SRIOV_BAR0_SIZE {4} \
      CPM_PCIE0_PF2_SRIOV_BAR0_TYPE {Memory} \
      CPM_PCIE0_PF2_SRIOV_BAR1_64BIT {0} \
      CPM_PCIE0_PF2_SRIOV_BAR1_ENABLED {0} \
      CPM_PCIE0_PF2_SRIOV_BAR1_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_SRIOV_BAR1_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_SRIOV_BAR1_SIZE {4} \
      CPM_PCIE0_PF2_SRIOV_BAR1_TYPE {Memory} \
      CPM_PCIE0_PF2_SRIOV_BAR2_64BIT {0} \
      CPM_PCIE0_PF2_SRIOV_BAR2_ENABLED {0} \
      CPM_PCIE0_PF2_SRIOV_BAR2_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_SRIOV_BAR2_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_SRIOV_BAR2_SIZE {4} \
      CPM_PCIE0_PF2_SRIOV_BAR2_TYPE {Memory} \
      CPM_PCIE0_PF2_SRIOV_BAR3_64BIT {0} \
      CPM_PCIE0_PF2_SRIOV_BAR3_ENABLED {0} \
      CPM_PCIE0_PF2_SRIOV_BAR3_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_SRIOV_BAR3_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_SRIOV_BAR3_SIZE {4} \
      CPM_PCIE0_PF2_SRIOV_BAR3_TYPE {Memory} \
      CPM_PCIE0_PF2_SRIOV_BAR4_64BIT {0} \
      CPM_PCIE0_PF2_SRIOV_BAR4_ENABLED {0} \
      CPM_PCIE0_PF2_SRIOV_BAR4_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_SRIOV_BAR4_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_SRIOV_BAR4_SIZE {4} \
      CPM_PCIE0_PF2_SRIOV_BAR4_TYPE {Memory} \
      CPM_PCIE0_PF2_SRIOV_BAR5_64BIT {0} \
      CPM_PCIE0_PF2_SRIOV_BAR5_ENABLED {0} \
      CPM_PCIE0_PF2_SRIOV_BAR5_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_SRIOV_BAR5_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_SRIOV_BAR5_SIZE {4} \
      CPM_PCIE0_PF2_SRIOV_BAR5_TYPE {Memory} \
      CPM_PCIE0_PF2_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE0_PF2_SRIOV_CAP_INITIAL_VF {4} \
      CPM_PCIE0_PF2_SRIOV_CAP_TOTAL_VF {0} \
      CPM_PCIE0_PF2_SRIOV_CAP_VER {1} \
      CPM_PCIE0_PF2_SRIOV_FIRST_VF_OFFSET {10} \
      CPM_PCIE0_PF2_SRIOV_FUNC_DEP_LINK {0} \
      CPM_PCIE0_PF2_SRIOV_SUPPORTED_PAGE_SIZE {553} \
      CPM_PCIE0_PF2_SRIOV_VF_DEVICE_ID {C23F} \
      CPM_PCIE0_PF2_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE0_PF2_SUB_CLASS_VALUE {80} \
      CPM_PCIE0_PF2_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE0_PF2_VEND_ID {0} \
      CPM_PCIE0_PF2_XDMA_64BIT {0} \
      CPM_PCIE0_PF2_XDMA_ENABLED {0} \
      CPM_PCIE0_PF2_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF2_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF2_XDMA_SIZE {128} \
      CPM_PCIE0_PF3_ARI_CAP_NEXT_FUNC {0} \
      CPM_PCIE0_PF3_ATS_CAP_ON {0} \
      CPM_PCIE0_PF3_AXILITE_MASTER_64BIT {0} \
      CPM_PCIE0_PF3_AXILITE_MASTER_ENABLED {0} \
      CPM_PCIE0_PF3_AXILITE_MASTER_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_AXILITE_MASTER_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_AXILITE_MASTER_SIZE {128} \
      CPM_PCIE0_PF3_AXIST_BYPASS_64BIT {0} \
      CPM_PCIE0_PF3_AXIST_BYPASS_ENABLED {0} \
      CPM_PCIE0_PF3_AXIST_BYPASS_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_AXIST_BYPASS_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_AXIST_BYPASS_SIZE {128} \
      CPM_PCIE0_PF3_BAR0_64BIT {0} \
      CPM_PCIE0_PF3_BAR0_ENABLED {1} \
      CPM_PCIE0_PF3_BAR0_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR0_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR0_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR0_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR0_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR0_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR0_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR0_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR0_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR0_SIZE {128} \
      CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_SIZE {16} \
      CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_TYPE {DMA} \
      CPM_PCIE0_PF3_BAR0_TYPE {Memory} \
      CPM_PCIE0_PF3_BAR0_XDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR0_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR0_XDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR0_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR0_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR0_XDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR1_64BIT {0} \
      CPM_PCIE0_PF3_BAR1_ENABLED {0} \
      CPM_PCIE0_PF3_BAR1_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR1_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR1_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR1_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR1_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR1_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR1_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR1_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR1_SIZE {4} \
      CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR1_TYPE {Memory} \
      CPM_PCIE0_PF3_BAR1_XDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR1_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR1_XDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR1_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR1_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR1_XDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR2_64BIT {0} \
      CPM_PCIE0_PF3_BAR2_ENABLED {0} \
      CPM_PCIE0_PF3_BAR2_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR2_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR2_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR2_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR2_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR2_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR2_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR2_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR2_SIZE {4} \
      CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR2_TYPE {Memory} \
      CPM_PCIE0_PF3_BAR2_XDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR2_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR2_XDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR2_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR2_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR2_XDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR3_64BIT {0} \
      CPM_PCIE0_PF3_BAR3_ENABLED {0} \
      CPM_PCIE0_PF3_BAR3_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR3_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR3_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR3_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR3_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR3_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR3_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR3_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR3_SIZE {4} \
      CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR3_TYPE {Memory} \
      CPM_PCIE0_PF3_BAR3_XDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR3_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR3_XDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR3_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR3_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR3_XDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR4_64BIT {0} \
      CPM_PCIE0_PF3_BAR4_ENABLED {0} \
      CPM_PCIE0_PF3_BAR4_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR4_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR4_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR4_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR4_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR4_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR4_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR4_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR4_SIZE {4} \
      CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR4_TYPE {Memory} \
      CPM_PCIE0_PF3_BAR4_XDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR4_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR4_XDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR4_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR4_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR4_XDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR5_64BIT {0} \
      CPM_PCIE0_PF3_BAR5_ENABLED {0} \
      CPM_PCIE0_PF3_BAR5_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR5_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR5_QDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR5_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR5_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR5_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR5_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR5_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR5_SIZE {4} \
      CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BAR5_TYPE {Memory} \
      CPM_PCIE0_PF3_BAR5_XDMA_64BIT {0} \
      CPM_PCIE0_PF3_BAR5_XDMA_AXCACHE {0} \
      CPM_PCIE0_PF3_BAR5_XDMA_ENABLED {0} \
      CPM_PCIE0_PF3_BAR5_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_BAR5_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_BAR5_XDMA_SIZE {4} \
      CPM_PCIE0_PF3_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
      CPM_PCIE0_PF3_BASE_CLASS_MENU {Memory_controller} \
      CPM_PCIE0_PF3_BASE_CLASS_VALUE {05} \
      CPM_PCIE0_PF3_CAPABILITY_POINTER {80} \
      CPM_PCIE0_PF3_CFG_DEV_ID {B33F} \
      CPM_PCIE0_PF3_CFG_REV_ID {0} \
      CPM_PCIE0_PF3_CFG_SUBSYS_ID {7} \
      CPM_PCIE0_PF3_CFG_SUBSYS_VEND_ID {10EE} \
      CPM_PCIE0_PF3_CLASS_CODE {0x058000} \
      CPM_PCIE0_PF3_DSN_CAP_ENABLE {0} \
      CPM_PCIE0_PF3_EXPANSION_ROM_ENABLED {0} \
      CPM_PCIE0_PF3_EXPANSION_ROM_QDMA_ENABLED {0} \
      CPM_PCIE0_PF3_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_EXPANSION_ROM_QDMA_SIZE {2} \
      CPM_PCIE0_PF3_EXPANSION_ROM_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_EXPANSION_ROM_SIZE {2} \
      CPM_PCIE0_PF3_INTERFACE_VALUE {00} \
      CPM_PCIE0_PF3_INTERRUPT_PIN {NONE} \
      CPM_PCIE0_PF3_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE0_PF3_MSIX_CAP_PBA_OFFSET {8FE0} \
      CPM_PCIE0_PF3_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE0_PF3_MSIX_CAP_TABLE_OFFSET {8000} \
      CPM_PCIE0_PF3_MSIX_CAP_TABLE_SIZE {1F} \
      CPM_PCIE0_PF3_MSIX_ENABLED {1} \
      CPM_PCIE0_PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
      CPM_PCIE0_PF3_MSI_CAP_PERVECMASKCAP {0} \
      CPM_PCIE0_PF3_MSI_ENABLED {1} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_AXIL_MASTER {0} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_AXIST_BYPASS {0} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_2 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_0 {0} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_1 {0} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_2 {0} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_3 {0} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_4 {0} \
      CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_5 {0} \
      CPM_PCIE0_PF3_PRI_CAP_ON {0} \
      CPM_PCIE0_PF3_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
      CPM_PCIE0_PF3_SRIOV_BAR0_64BIT {0} \
      CPM_PCIE0_PF3_SRIOV_BAR0_ENABLED {1} \
      CPM_PCIE0_PF3_SRIOV_BAR0_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_SRIOV_BAR0_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_SRIOV_BAR0_SIZE {4} \
      CPM_PCIE0_PF3_SRIOV_BAR0_TYPE {Memory} \
      CPM_PCIE0_PF3_SRIOV_BAR1_64BIT {0} \
      CPM_PCIE0_PF3_SRIOV_BAR1_ENABLED {0} \
      CPM_PCIE0_PF3_SRIOV_BAR1_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_SRIOV_BAR1_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_SRIOV_BAR1_SIZE {4} \
      CPM_PCIE0_PF3_SRIOV_BAR1_TYPE {Memory} \
      CPM_PCIE0_PF3_SRIOV_BAR2_64BIT {0} \
      CPM_PCIE0_PF3_SRIOV_BAR2_ENABLED {0} \
      CPM_PCIE0_PF3_SRIOV_BAR2_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_SRIOV_BAR2_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_SRIOV_BAR2_SIZE {4} \
      CPM_PCIE0_PF3_SRIOV_BAR2_TYPE {Memory} \
      CPM_PCIE0_PF3_SRIOV_BAR3_64BIT {0} \
      CPM_PCIE0_PF3_SRIOV_BAR3_ENABLED {0} \
      CPM_PCIE0_PF3_SRIOV_BAR3_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_SRIOV_BAR3_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_SRIOV_BAR3_SIZE {4} \
      CPM_PCIE0_PF3_SRIOV_BAR3_TYPE {Memory} \
      CPM_PCIE0_PF3_SRIOV_BAR4_64BIT {0} \
      CPM_PCIE0_PF3_SRIOV_BAR4_ENABLED {0} \
      CPM_PCIE0_PF3_SRIOV_BAR4_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_SRIOV_BAR4_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_SRIOV_BAR4_SIZE {4} \
      CPM_PCIE0_PF3_SRIOV_BAR4_TYPE {Memory} \
      CPM_PCIE0_PF3_SRIOV_BAR5_64BIT {0} \
      CPM_PCIE0_PF3_SRIOV_BAR5_ENABLED {0} \
      CPM_PCIE0_PF3_SRIOV_BAR5_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_SRIOV_BAR5_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_SRIOV_BAR5_SIZE {4} \
      CPM_PCIE0_PF3_SRIOV_BAR5_TYPE {Memory} \
      CPM_PCIE0_PF3_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE0_PF3_SRIOV_CAP_INITIAL_VF {4} \
      CPM_PCIE0_PF3_SRIOV_CAP_TOTAL_VF {0} \
      CPM_PCIE0_PF3_SRIOV_CAP_VER {1} \
      CPM_PCIE0_PF3_SRIOV_FIRST_VF_OFFSET {13} \
      CPM_PCIE0_PF3_SRIOV_FUNC_DEP_LINK {0} \
      CPM_PCIE0_PF3_SRIOV_SUPPORTED_PAGE_SIZE {553} \
      CPM_PCIE0_PF3_SRIOV_VF_DEVICE_ID {C33F} \
      CPM_PCIE0_PF3_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE0_PF3_SUB_CLASS_VALUE {80} \
      CPM_PCIE0_PF3_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE0_PF3_VEND_ID {0} \
      CPM_PCIE0_PF3_XDMA_64BIT {0} \
      CPM_PCIE0_PF3_XDMA_ENABLED {0} \
      CPM_PCIE0_PF3_XDMA_PREFETCHABLE {0} \
      CPM_PCIE0_PF3_XDMA_SCALE {Kilobytes} \
      CPM_PCIE0_PF3_XDMA_SIZE {128} \
      CPM_PCIE0_PL_LINK_CAP_MAX_LINK_SPEED {Gen3} \
      CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {NONE} \
      CPM_PCIE0_PL_UPSTREAM_FACING {1} \
      CPM_PCIE0_PL_USER_SPARE {0} \
      CPM_PCIE0_PM_ASPML0S_TIMEOUT {0} \
      CPM_PCIE0_PM_ASPML1_ENTRY_DELAY {0} \
      CPM_PCIE0_PM_ENABLE_L23_ENTRY {0} \
      CPM_PCIE0_PM_ENABLE_SLOT_POWER_CAPTURE {1} \
      CPM_PCIE0_PM_L1_REENTRY_DELAY {0} \
      CPM_PCIE0_PM_PME_TURNOFF_ACK_DELAY {0} \
      CPM_PCIE0_PORT_TYPE {Root_Port_of_PCI_Express_Root_Complex} \
      CPM_PCIE0_QDMA_MULTQ_MAX {2048} \
      CPM_PCIE0_QDMA_PARITY_SETTINGS {None} \
      CPM_PCIE0_REF_CLK_FREQ {100_MHz} \
      CPM_PCIE0_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE0_SRIOV_FIRST_VF_OFFSET {4} \
      CPM_PCIE0_TL2CFG_IF_PARITY_CHK {0} \
      CPM_PCIE0_TL_PF_ENABLE_REG {1} \
      CPM_PCIE0_TL_USER_SPARE {0} \
      CPM_PCIE0_TX_FC_IF {0} \
      CPM_PCIE0_TYPE1_MEMBASE_MEMLIMIT_BRIDGE_ENABLE {Disabled} \
      CPM_PCIE0_TYPE1_MEMBASE_MEMLIMIT_ENABLE {Disabled} \
      CPM_PCIE0_TYPE1_PREFETCHABLE_MEMBASE_BRIDGE_MEMLIMIT {Disabled} \
      CPM_PCIE0_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT {Disabled} \
      CPM_PCIE0_USER_CLK2_FREQ {1000_MHz} \
      CPM_PCIE0_USER_CLK_FREQ {125_MHz} \
      CPM_PCIE0_USER_EDR_CLK2_FREQ {312.5_MHz} \
      CPM_PCIE0_USER_EDR_CLK_FREQ {312.5_MHz} \
      CPM_PCIE0_VC0_CAPABILITY_POINTER {80} \
      CPM_PCIE0_VC1_BASE_DISABLE {0} \
      CPM_PCIE0_VFG0_ATS_CAP_ON {0} \
      CPM_PCIE0_VFG0_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE0_VFG0_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE0_VFG0_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE0_VFG0_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE0_VFG0_MSIX_CAP_TABLE_SIZE {1} \
      CPM_PCIE0_VFG0_MSIX_ENABLED {0} \
      CPM_PCIE0_VFG0_PRI_CAP_ON {0} \
      CPM_PCIE0_VFG1_ATS_CAP_ON {0} \
      CPM_PCIE0_VFG1_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE0_VFG1_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE0_VFG1_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE0_VFG1_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE0_VFG1_MSIX_CAP_TABLE_SIZE {1} \
      CPM_PCIE0_VFG1_MSIX_ENABLED {0} \
      CPM_PCIE0_VFG1_PRI_CAP_ON {0} \
      CPM_PCIE0_VFG2_ATS_CAP_ON {0} \
      CPM_PCIE0_VFG2_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE0_VFG2_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE0_VFG2_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE0_VFG2_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE0_VFG2_MSIX_CAP_TABLE_SIZE {1} \
      CPM_PCIE0_VFG2_MSIX_ENABLED {0} \
      CPM_PCIE0_VFG2_PRI_CAP_ON {0} \
      CPM_PCIE0_VFG3_ATS_CAP_ON {0} \
      CPM_PCIE0_VFG3_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE0_VFG3_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE0_VFG3_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE0_VFG3_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE0_VFG3_MSIX_CAP_TABLE_SIZE {1} \
      CPM_PCIE0_VFG3_MSIX_ENABLED {0} \
      CPM_PCIE0_VFG3_PRI_CAP_ON {0} \
      CPM_PCIE0_XDMA_AXILITE_SLAVE_IF {0} \
      CPM_PCIE0_XDMA_AXI_ID_WIDTH {2} \
      CPM_PCIE0_XDMA_DSC_BYPASS_RD {0000} \
      CPM_PCIE0_XDMA_DSC_BYPASS_WR {0000} \
      CPM_PCIE0_XDMA_IRQ {1} \
      CPM_PCIE0_XDMA_PARITY_SETTINGS {None} \
      CPM_PCIE0_XDMA_RNUM_CHNL {1} \
      CPM_PCIE0_XDMA_RNUM_RIDS {2} \
      CPM_PCIE0_XDMA_STS_PORTS {0} \
      CPM_PCIE0_XDMA_WNUM_CHNL {1} \
      CPM_PCIE0_XDMA_WNUM_RIDS {2} \
      CPM_PCIE1_AER_CAP_ENABLED {0} \
      CPM_PCIE1_ARI_CAP_ENABLED {1} \
      CPM_PCIE1_ASYNC_MODE {SRNS} \
      CPM_PCIE1_ATS_PRI_CAP_ON {0} \
      CPM_PCIE1_AXIBAR_NUM {1} \
      CPM_PCIE1_AXISTEN_IF_CC_ALIGNMENT_MODE {DWORD_Aligned} \
      CPM_PCIE1_AXISTEN_IF_COMPL_TIMEOUT_REG0 {BEBC20} \
      CPM_PCIE1_AXISTEN_IF_COMPL_TIMEOUT_REG1 {2FAF080} \
      CPM_PCIE1_AXISTEN_IF_CQ_ALIGNMENT_MODE {DWORD_Aligned} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_256_TAGS {0} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_CLIENT_TAG {0} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_INTERNAL_MSIX_TABLE {0} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_MESSAGE_RID_CHECK {1} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_MSG_ROUTE {0} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_RX_MSG_INTFC {0} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_RX_TAG_SCALING {0} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_TX_TAG_SCALING {0} \
      CPM_PCIE1_AXISTEN_IF_EXTEND_CPL_TIMEOUT {16ms_to_1s} \
      CPM_PCIE1_AXISTEN_IF_EXT_512 {0} \
      CPM_PCIE1_AXISTEN_IF_EXT_512_CC_STRADDLE {0} \
      CPM_PCIE1_AXISTEN_IF_EXT_512_CQ_STRADDLE {0} \
      CPM_PCIE1_AXISTEN_IF_EXT_512_RC_4TLP_STRADDLE {1} \
      CPM_PCIE1_AXISTEN_IF_EXT_512_RC_STRADDLE {1} \
      CPM_PCIE1_AXISTEN_IF_EXT_512_RQ_STRADDLE {0} \
      CPM_PCIE1_AXISTEN_IF_RC_ALIGNMENT_MODE {DWORD_Aligned} \
      CPM_PCIE1_AXISTEN_IF_RC_STRADDLE {1} \
      CPM_PCIE1_AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
      CPM_PCIE1_AXISTEN_IF_RX_PARITY_EN {1} \
      CPM_PCIE1_AXISTEN_IF_SIM_SHORT_CPL_TIMEOUT {0} \
      CPM_PCIE1_AXISTEN_IF_TX_PARITY_EN {0} \
      CPM_PCIE1_AXISTEN_IF_WIDTH {64} \
      CPM_PCIE1_AXISTEN_MSIX_VECTORS_PER_FUNCTION {8} \
      CPM_PCIE1_AXISTEN_USER_SPARE {0} \
      CPM_PCIE1_CCIX_EN {0} \
      CPM_PCIE1_CCIX_OPT_TLP_GEN_AND_RECEPT_EN_CONTROL_INTERNAL {0} \
      CPM_PCIE1_CCIX_VENDOR_ID {0} \
      CPM_PCIE1_CFG_CTL_IF {0} \
      CPM_PCIE1_CFG_EXT_IF {0} \
      CPM_PCIE1_CFG_FC_IF {0} \
      CPM_PCIE1_CFG_MGMT_IF {0} \
      CPM_PCIE1_CFG_SPEC_4_0 {0} \
      CPM_PCIE1_CFG_STS_IF {0} \
      CPM_PCIE1_CFG_VEND_ID {10EE} \
      CPM_PCIE1_CONTROLLER_ENABLE {0} \
      CPM_PCIE1_COPY_PF0_ENABLED {0} \
      CPM_PCIE1_COPY_SRIOV_PF0_ENABLED {1} \
      CPM_PCIE1_CORE_CLK_FREQ {250} \
      CPM_PCIE1_CORE_EDR_CLK_FREQ {625} \
      CPM_PCIE1_DSC_BYPASS_RD {0} \
      CPM_PCIE1_DSC_BYPASS_WR {0} \
      CPM_PCIE1_EDR_IF {0} \
      CPM_PCIE1_EDR_LINK_SPEED {None} \
      CPM_PCIE1_EN_PARITY {0} \
      CPM_PCIE1_EXT_PCIE_CFG_SPACE_ENABLED {None} \
      CPM_PCIE1_FUNCTIONAL_MODE {None} \
      CPM_PCIE1_LANE_REVERSAL_EN {1} \
      CPM_PCIE1_LEGACY_EXT_PCIE_CFG_SPACE_ENABLED {0} \
      CPM_PCIE1_LINK_DEBUG_AXIST_EN {0} \
      CPM_PCIE1_LINK_DEBUG_EN {0} \
      CPM_PCIE1_LINK_SPEED1_FOR_POWER {GEN1} \
      CPM_PCIE1_LINK_WIDTH1_FOR_POWER {0} \
      CPM_PCIE1_MAX_LINK_SPEED {2.5_GT/s} \
      CPM_PCIE1_MCAP_ENABLE {0} \
      CPM_PCIE1_MESG_RSVD_IF {0} \
      CPM_PCIE1_MESG_TRANSMIT_IF {0} \
      CPM_PCIE1_MODE1_FOR_POWER {NONE} \
      CPM_PCIE1_MODES {None} \
      CPM_PCIE1_MODE_SELECTION {Basic} \
      CPM_PCIE1_MSIX_RP_ENABLED {1} \
      CPM_PCIE1_MSI_X_OPTIONS {MSI-X_External} \
      CPM_PCIE1_PASID_IF {0} \
      CPM_PCIE1_PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE {0} \
      CPM_PCIE1_PF0_ARI_CAP_NEXT_FUNC {0} \
      CPM_PCIE1_PF0_ARI_CAP_VER {1} \
      CPM_PCIE1_PF0_ATS_CAP_ON {0} \
      CPM_PCIE1_PF0_AXILITE_MASTER_64BIT {0} \
      CPM_PCIE1_PF0_AXILITE_MASTER_ENABLED {0} \
      CPM_PCIE1_PF0_AXILITE_MASTER_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_AXILITE_MASTER_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_AXILITE_MASTER_SIZE {128} \
      CPM_PCIE1_PF0_AXIST_BYPASS_64BIT {0} \
      CPM_PCIE1_PF0_AXIST_BYPASS_ENABLED {0} \
      CPM_PCIE1_PF0_AXIST_BYPASS_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_AXIST_BYPASS_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_AXIST_BYPASS_SIZE {128} \
      CPM_PCIE1_PF0_BAR0_64BIT {0} \
      CPM_PCIE1_PF0_BAR0_ENABLED {1} \
      CPM_PCIE1_PF0_BAR0_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_BAR0_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR0_SIZE {128} \
      CPM_PCIE1_PF0_BAR0_TYPE {Memory} \
      CPM_PCIE1_PF0_BAR1_64BIT {0} \
      CPM_PCIE1_PF0_BAR1_ENABLED {0} \
      CPM_PCIE1_PF0_BAR1_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_BAR1_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR1_SIZE {4} \
      CPM_PCIE1_PF0_BAR1_TYPE {Memory} \
      CPM_PCIE1_PF0_BAR2_64BIT {0} \
      CPM_PCIE1_PF0_BAR2_ENABLED {0} \
      CPM_PCIE1_PF0_BAR2_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_BAR2_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR2_SIZE {4} \
      CPM_PCIE1_PF0_BAR2_TYPE {Memory} \
      CPM_PCIE1_PF0_BAR3_64BIT {0} \
      CPM_PCIE1_PF0_BAR3_ENABLED {0} \
      CPM_PCIE1_PF0_BAR3_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_BAR3_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR3_SIZE {4} \
      CPM_PCIE1_PF0_BAR3_TYPE {Memory} \
      CPM_PCIE1_PF0_BAR4_64BIT {0} \
      CPM_PCIE1_PF0_BAR4_ENABLED {0} \
      CPM_PCIE1_PF0_BAR4_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_BAR4_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR4_SIZE {4} \
      CPM_PCIE1_PF0_BAR4_TYPE {Memory} \
      CPM_PCIE1_PF0_BAR5_64BIT {0} \
      CPM_PCIE1_PF0_BAR5_ENABLED {0} \
      CPM_PCIE1_PF0_BAR5_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_BAR5_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR5_SIZE {4} \
      CPM_PCIE1_PF0_BAR5_TYPE {Memory} \
      CPM_PCIE1_PF0_BASE_CLASS_MENU {Memory_controller} \
      CPM_PCIE1_PF0_BASE_CLASS_VALUE {05} \
      CPM_PCIE1_PF0_CAPABILITY_POINTER {80} \
      CPM_PCIE1_PF0_CFG_DEV_ID {B034} \
      CPM_PCIE1_PF0_CFG_REV_ID {0} \
      CPM_PCIE1_PF0_CFG_SUBSYS_ID {7} \
      CPM_PCIE1_PF0_CFG_SUBSYS_VEND_ID {10EE} \
      CPM_PCIE1_PF0_CLASS_CODE {0x05800} \
      CPM_PCIE1_PF0_DEV_CAP_10B_TAG_EN {0} \
      CPM_PCIE1_PF0_DEV_CAP_ENDPOINT_L0S_LATENCY {less_than_64ns} \
      CPM_PCIE1_PF0_DEV_CAP_ENDPOINT_L1S_LATENCY {less_than_1us} \
      CPM_PCIE1_PF0_DEV_CAP_EXT_TAG_EN {0} \
      CPM_PCIE1_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {0} \
      CPM_PCIE1_PF0_DEV_CAP_MAX_PAYLOAD {1024_bytes} \
      CPM_PCIE1_PF0_DLL_FEATURE_CAP_ID {0} \
      CPM_PCIE1_PF0_DLL_FEATURE_CAP_ON {0} \
      CPM_PCIE1_PF0_DLL_FEATURE_CAP_VER {1} \
      CPM_PCIE1_PF0_DSN_CAP_ENABLE {0} \
      CPM_PCIE1_PF0_EXPANSION_ROM_ENABLED {0} \
      CPM_PCIE1_PF0_EXPANSION_ROM_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_EXPANSION_ROM_SIZE {2} \
      CPM_PCIE1_PF0_INTERFACE_VALUE {0} \
      CPM_PCIE1_PF0_INTERRUPT_PIN {NONE} \
      CPM_PCIE1_PF0_LINK_CAP_ASPM_SUPPORT {No_ASPM} \
      CPM_PCIE1_PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {1} \
      CPM_PCIE1_PF0_MARGINING_CAP_ID {0} \
      CPM_PCIE1_PF0_MARGINING_CAP_ON {0} \
      CPM_PCIE1_PF0_MARGINING_CAP_VER {1} \
      CPM_PCIE1_PF0_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE1_PF0_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE1_PF0_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE1_PF0_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE1_PF0_MSIX_CAP_TABLE_SIZE {001} \
      CPM_PCIE1_PF0_MSIX_ENABLED {1} \
      CPM_PCIE1_PF0_MSI_CAP_MULTIMSGCAP {1_vector} \
      CPM_PCIE1_PF0_MSI_CAP_PERVECMASKCAP {0} \
      CPM_PCIE1_PF0_MSI_ENABLED {1} \
      CPM_PCIE1_PF0_PASID_CAP_MAX_PASID_WIDTH {1} \
      CPM_PCIE1_PF0_PASID_CAP_ON {0} \
      CPM_PCIE1_PF0_PCIEBAR2AXIBAR_AXIL_MASTER {0} \
      CPM_PCIE1_PF0_PCIEBAR2AXIBAR_AXIST_BYPASS {0} \
      CPM_PCIE1_PF0_PL16_CAP_ID {0} \
      CPM_PCIE1_PF0_PL16_CAP_ON {0} \
      CPM_PCIE1_PF0_PL16_CAP_VER {1} \
      CPM_PCIE1_PF0_PM_CAP_ID {0} \
      CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D0 {1} \
      CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D1 {1} \
      CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D3COLD {1} \
      CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D3HOT {1} \
      CPM_PCIE1_PF0_PM_CAP_SUPP_D1_STATE {1} \
      CPM_PCIE1_PF0_PM_CAP_VER_ID {3} \
      CPM_PCIE1_PF0_PM_CSR_NOSOFTRESET {1} \
      CPM_PCIE1_PF0_PRI_CAP_ON {0} \
      CPM_PCIE1_PF0_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
      CPM_PCIE1_PF0_SRIOV_BAR0_64BIT {0} \
      CPM_PCIE1_PF0_SRIOV_BAR0_ENABLED {1} \
      CPM_PCIE1_PF0_SRIOV_BAR0_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_SRIOV_BAR0_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_SRIOV_BAR0_SIZE {4} \
      CPM_PCIE1_PF0_SRIOV_BAR0_TYPE {Memory} \
      CPM_PCIE1_PF0_SRIOV_BAR1_64BIT {0} \
      CPM_PCIE1_PF0_SRIOV_BAR1_ENABLED {0} \
      CPM_PCIE1_PF0_SRIOV_BAR1_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_SRIOV_BAR1_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_SRIOV_BAR1_SIZE {4} \
      CPM_PCIE1_PF0_SRIOV_BAR1_TYPE {Memory} \
      CPM_PCIE1_PF0_SRIOV_BAR2_64BIT {0} \
      CPM_PCIE1_PF0_SRIOV_BAR2_ENABLED {0} \
      CPM_PCIE1_PF0_SRIOV_BAR2_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_SRIOV_BAR2_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_SRIOV_BAR2_SIZE {4} \
      CPM_PCIE1_PF0_SRIOV_BAR2_TYPE {Memory} \
      CPM_PCIE1_PF0_SRIOV_BAR3_64BIT {0} \
      CPM_PCIE1_PF0_SRIOV_BAR3_ENABLED {0} \
      CPM_PCIE1_PF0_SRIOV_BAR3_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_SRIOV_BAR3_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_SRIOV_BAR3_SIZE {4} \
      CPM_PCIE1_PF0_SRIOV_BAR3_TYPE {Memory} \
      CPM_PCIE1_PF0_SRIOV_BAR4_64BIT {0} \
      CPM_PCIE1_PF0_SRIOV_BAR4_ENABLED {0} \
      CPM_PCIE1_PF0_SRIOV_BAR4_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_SRIOV_BAR4_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_SRIOV_BAR4_SIZE {4} \
      CPM_PCIE1_PF0_SRIOV_BAR4_TYPE {Memory} \
      CPM_PCIE1_PF0_SRIOV_BAR5_64BIT {0} \
      CPM_PCIE1_PF0_SRIOV_BAR5_ENABLED {0} \
      CPM_PCIE1_PF0_SRIOV_BAR5_PREFETCHABLE {0} \
      CPM_PCIE1_PF0_SRIOV_BAR5_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_SRIOV_BAR5_SIZE {4} \
      CPM_PCIE1_PF0_SRIOV_BAR5_TYPE {Memory} \
      CPM_PCIE1_PF0_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE1_PF0_SRIOV_CAP_INITIAL_VF {4} \
      CPM_PCIE1_PF0_SRIOV_CAP_TOTAL_VF {0} \
      CPM_PCIE1_PF0_SRIOV_CAP_VER {1} \
      CPM_PCIE1_PF0_SRIOV_FIRST_VF_OFFSET {4} \
      CPM_PCIE1_PF0_SRIOV_FUNC_DEP_LINK {0} \
      CPM_PCIE1_PF0_SRIOV_SUPPORTED_PAGE_SIZE {553} \
      CPM_PCIE1_PF0_SRIOV_VF_DEVICE_ID {C034} \
      CPM_PCIE1_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE1_PF0_SUB_CLASS_VALUE {80} \
      CPM_PCIE1_PF0_TPHR_CAP_DEV_SPECIFIC_MODE {1} \
      CPM_PCIE1_PF0_TPHR_CAP_ENABLE {0} \
      CPM_PCIE1_PF0_TPHR_CAP_INT_VEC_MODE {1} \
      CPM_PCIE1_PF0_TPHR_CAP_ST_TABLE_LOC {ST_Table_not_present} \
      CPM_PCIE1_PF0_TPHR_CAP_ST_TABLE_SIZE {16} \
      CPM_PCIE1_PF0_TPHR_CAP_VER {1} \
      CPM_PCIE1_PF0_TPHR_ENABLE {0} \
      CPM_PCIE1_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE1_PF0_VC_ARB_CAPABILITY {0} \
      CPM_PCIE1_PF0_VC_ARB_TBL_OFFSET {0} \
      CPM_PCIE1_PF0_VC_CAP_ENABLED {0} \
      CPM_PCIE1_PF0_VC_CAP_VER {1} \
      CPM_PCIE1_PF0_VC_EXTENDED_COUNT {0} \
      CPM_PCIE1_PF0_VC_LOW_PRIORITY_EXTENDED_COUNT {0} \
      CPM_PCIE1_PF1_ARI_CAP_NEXT_FUNC {0} \
      CPM_PCIE1_PF1_ATS_CAP_ON {0} \
      CPM_PCIE1_PF1_AXILITE_MASTER_64BIT {0} \
      CPM_PCIE1_PF1_AXILITE_MASTER_ENABLED {0} \
      CPM_PCIE1_PF1_AXILITE_MASTER_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_AXILITE_MASTER_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_AXILITE_MASTER_SIZE {128} \
      CPM_PCIE1_PF1_AXIST_BYPASS_64BIT {0} \
      CPM_PCIE1_PF1_AXIST_BYPASS_ENABLED {0} \
      CPM_PCIE1_PF1_AXIST_BYPASS_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_AXIST_BYPASS_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_AXIST_BYPASS_SIZE {128} \
      CPM_PCIE1_PF1_BAR0_64BIT {0} \
      CPM_PCIE1_PF1_BAR0_ENABLED {1} \
      CPM_PCIE1_PF1_BAR0_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_BAR0_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_BAR0_SIZE {128} \
      CPM_PCIE1_PF1_BAR0_TYPE {Memory} \
      CPM_PCIE1_PF1_BAR1_64BIT {0} \
      CPM_PCIE1_PF1_BAR1_ENABLED {0} \
      CPM_PCIE1_PF1_BAR1_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_BAR1_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_BAR1_SIZE {4} \
      CPM_PCIE1_PF1_BAR1_TYPE {Memory} \
      CPM_PCIE1_PF1_BAR2_64BIT {0} \
      CPM_PCIE1_PF1_BAR2_ENABLED {0} \
      CPM_PCIE1_PF1_BAR2_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_BAR2_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_BAR2_SIZE {4} \
      CPM_PCIE1_PF1_BAR2_TYPE {Memory} \
      CPM_PCIE1_PF1_BAR3_64BIT {0} \
      CPM_PCIE1_PF1_BAR3_ENABLED {0} \
      CPM_PCIE1_PF1_BAR3_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_BAR3_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_BAR3_SIZE {4} \
      CPM_PCIE1_PF1_BAR3_TYPE {Memory} \
      CPM_PCIE1_PF1_BAR4_64BIT {0} \
      CPM_PCIE1_PF1_BAR4_ENABLED {0} \
      CPM_PCIE1_PF1_BAR4_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_BAR4_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_BAR4_SIZE {4} \
      CPM_PCIE1_PF1_BAR4_TYPE {Memory} \
      CPM_PCIE1_PF1_BAR5_64BIT {0} \
      CPM_PCIE1_PF1_BAR5_ENABLED {0} \
      CPM_PCIE1_PF1_BAR5_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_BAR5_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_BAR5_SIZE {4} \
      CPM_PCIE1_PF1_BAR5_TYPE {Memory} \
      CPM_PCIE1_PF1_BASE_CLASS_MENU {Memory_controller} \
      CPM_PCIE1_PF1_BASE_CLASS_VALUE {05} \
      CPM_PCIE1_PF1_CAPABILITY_POINTER {80} \
      CPM_PCIE1_PF1_CFG_DEV_ID {B134} \
      CPM_PCIE1_PF1_CFG_REV_ID {0} \
      CPM_PCIE1_PF1_CFG_SUBSYS_ID {7} \
      CPM_PCIE1_PF1_CFG_SUBSYS_VEND_ID {10EE} \
      CPM_PCIE1_PF1_CLASS_CODE {0x058000} \
      CPM_PCIE1_PF1_DSN_CAP_ENABLE {0} \
      CPM_PCIE1_PF1_EXPANSION_ROM_ENABLED {0} \
      CPM_PCIE1_PF1_EXPANSION_ROM_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_EXPANSION_ROM_SIZE {2} \
      CPM_PCIE1_PF1_INTERFACE_VALUE {00} \
      CPM_PCIE1_PF1_INTERRUPT_PIN {NONE} \
      CPM_PCIE1_PF1_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE1_PF1_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE1_PF1_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE1_PF1_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE1_PF1_MSIX_CAP_TABLE_SIZE {001} \
      CPM_PCIE1_PF1_MSIX_ENABLED {1} \
      CPM_PCIE1_PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
      CPM_PCIE1_PF1_MSI_CAP_PERVECMASKCAP {0} \
      CPM_PCIE1_PF1_MSI_ENABLED {1} \
      CPM_PCIE1_PF1_PCIEBAR2AXIBAR_AXIL_MASTER {0} \
      CPM_PCIE1_PF1_PCIEBAR2AXIBAR_AXIST_BYPASS {0} \
      CPM_PCIE1_PF1_PRI_CAP_ON {0} \
      CPM_PCIE1_PF1_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
      CPM_PCIE1_PF1_SRIOV_BAR0_64BIT {0} \
      CPM_PCIE1_PF1_SRIOV_BAR0_ENABLED {1} \
      CPM_PCIE1_PF1_SRIOV_BAR0_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_SRIOV_BAR0_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_SRIOV_BAR0_SIZE {4} \
      CPM_PCIE1_PF1_SRIOV_BAR0_TYPE {Memory} \
      CPM_PCIE1_PF1_SRIOV_BAR1_64BIT {0} \
      CPM_PCIE1_PF1_SRIOV_BAR1_ENABLED {0} \
      CPM_PCIE1_PF1_SRIOV_BAR1_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_SRIOV_BAR1_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_SRIOV_BAR1_SIZE {4} \
      CPM_PCIE1_PF1_SRIOV_BAR1_TYPE {Memory} \
      CPM_PCIE1_PF1_SRIOV_BAR2_64BIT {0} \
      CPM_PCIE1_PF1_SRIOV_BAR2_ENABLED {0} \
      CPM_PCIE1_PF1_SRIOV_BAR2_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_SRIOV_BAR2_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_SRIOV_BAR2_SIZE {4} \
      CPM_PCIE1_PF1_SRIOV_BAR2_TYPE {Memory} \
      CPM_PCIE1_PF1_SRIOV_BAR3_64BIT {0} \
      CPM_PCIE1_PF1_SRIOV_BAR3_ENABLED {0} \
      CPM_PCIE1_PF1_SRIOV_BAR3_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_SRIOV_BAR3_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_SRIOV_BAR3_SIZE {4} \
      CPM_PCIE1_PF1_SRIOV_BAR3_TYPE {Memory} \
      CPM_PCIE1_PF1_SRIOV_BAR4_64BIT {0} \
      CPM_PCIE1_PF1_SRIOV_BAR4_ENABLED {0} \
      CPM_PCIE1_PF1_SRIOV_BAR4_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_SRIOV_BAR4_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_SRIOV_BAR4_SIZE {4} \
      CPM_PCIE1_PF1_SRIOV_BAR4_TYPE {Memory} \
      CPM_PCIE1_PF1_SRIOV_BAR5_64BIT {0} \
      CPM_PCIE1_PF1_SRIOV_BAR5_ENABLED {0} \
      CPM_PCIE1_PF1_SRIOV_BAR5_PREFETCHABLE {0} \
      CPM_PCIE1_PF1_SRIOV_BAR5_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_SRIOV_BAR5_SIZE {4} \
      CPM_PCIE1_PF1_SRIOV_BAR5_TYPE {Memory} \
      CPM_PCIE1_PF1_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE1_PF1_SRIOV_CAP_INITIAL_VF {4} \
      CPM_PCIE1_PF1_SRIOV_CAP_TOTAL_VF {0} \
      CPM_PCIE1_PF1_SRIOV_CAP_VER {1} \
      CPM_PCIE1_PF1_SRIOV_FIRST_VF_OFFSET {7} \
      CPM_PCIE1_PF1_SRIOV_FUNC_DEP_LINK {0} \
      CPM_PCIE1_PF1_SRIOV_SUPPORTED_PAGE_SIZE {553} \
      CPM_PCIE1_PF1_SRIOV_VF_DEVICE_ID {C134} \
      CPM_PCIE1_PF1_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE1_PF1_SUB_CLASS_VALUE {80} \
      CPM_PCIE1_PF1_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE1_PF1_VEND_ID {0} \
      CPM_PCIE1_PF2_ARI_CAP_NEXT_FUNC {0} \
      CPM_PCIE1_PF2_ATS_CAP_ON {0} \
      CPM_PCIE1_PF2_AXILITE_MASTER_64BIT {0} \
      CPM_PCIE1_PF2_AXILITE_MASTER_ENABLED {0} \
      CPM_PCIE1_PF2_AXILITE_MASTER_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_AXILITE_MASTER_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_AXILITE_MASTER_SIZE {128} \
      CPM_PCIE1_PF2_AXIST_BYPASS_64BIT {0} \
      CPM_PCIE1_PF2_AXIST_BYPASS_ENABLED {0} \
      CPM_PCIE1_PF2_AXIST_BYPASS_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_AXIST_BYPASS_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_AXIST_BYPASS_SIZE {128} \
      CPM_PCIE1_PF2_BAR0_64BIT {0} \
      CPM_PCIE1_PF2_BAR0_ENABLED {1} \
      CPM_PCIE1_PF2_BAR0_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_BAR0_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_BAR0_SIZE {128} \
      CPM_PCIE1_PF2_BAR0_TYPE {Memory} \
      CPM_PCIE1_PF2_BAR1_64BIT {0} \
      CPM_PCIE1_PF2_BAR1_ENABLED {0} \
      CPM_PCIE1_PF2_BAR1_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_BAR1_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_BAR1_SIZE {4} \
      CPM_PCIE1_PF2_BAR1_TYPE {Memory} \
      CPM_PCIE1_PF2_BAR2_64BIT {0} \
      CPM_PCIE1_PF2_BAR2_ENABLED {0} \
      CPM_PCIE1_PF2_BAR2_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_BAR2_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_BAR2_SIZE {4} \
      CPM_PCIE1_PF2_BAR2_TYPE {Memory} \
      CPM_PCIE1_PF2_BAR3_64BIT {0} \
      CPM_PCIE1_PF2_BAR3_ENABLED {0} \
      CPM_PCIE1_PF2_BAR3_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_BAR3_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_BAR3_SIZE {4} \
      CPM_PCIE1_PF2_BAR3_TYPE {Memory} \
      CPM_PCIE1_PF2_BAR4_64BIT {0} \
      CPM_PCIE1_PF2_BAR4_ENABLED {0} \
      CPM_PCIE1_PF2_BAR4_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_BAR4_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_BAR4_SIZE {4} \
      CPM_PCIE1_PF2_BAR4_TYPE {Memory} \
      CPM_PCIE1_PF2_BAR5_64BIT {0} \
      CPM_PCIE1_PF2_BAR5_ENABLED {0} \
      CPM_PCIE1_PF2_BAR5_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_BAR5_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_BAR5_SIZE {4} \
      CPM_PCIE1_PF2_BAR5_TYPE {Memory} \
      CPM_PCIE1_PF2_BASE_CLASS_MENU {Memory_controller} \
      CPM_PCIE1_PF2_BASE_CLASS_VALUE {05} \
      CPM_PCIE1_PF2_CAPABILITY_POINTER {80} \
      CPM_PCIE1_PF2_CFG_DEV_ID {B234} \
      CPM_PCIE1_PF2_CFG_REV_ID {0} \
      CPM_PCIE1_PF2_CFG_SUBSYS_ID {7} \
      CPM_PCIE1_PF2_CFG_SUBSYS_VEND_ID {10EE} \
      CPM_PCIE1_PF2_CLASS_CODE {0x058000} \
      CPM_PCIE1_PF2_DSN_CAP_ENABLE {0} \
      CPM_PCIE1_PF2_EXPANSION_ROM_ENABLED {0} \
      CPM_PCIE1_PF2_EXPANSION_ROM_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_EXPANSION_ROM_SIZE {2} \
      CPM_PCIE1_PF2_INTERFACE_VALUE {00} \
      CPM_PCIE1_PF2_INTERRUPT_PIN {NONE} \
      CPM_PCIE1_PF2_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE1_PF2_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE1_PF2_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE1_PF2_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE1_PF2_MSIX_CAP_TABLE_SIZE {001} \
      CPM_PCIE1_PF2_MSIX_ENABLED {1} \
      CPM_PCIE1_PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
      CPM_PCIE1_PF2_MSI_CAP_PERVECMASKCAP {0} \
      CPM_PCIE1_PF2_MSI_ENABLED {1} \
      CPM_PCIE1_PF2_PASID_CAP_MAX_PASID_WIDTH {1} \
      CPM_PCIE1_PF2_PCIEBAR2AXIBAR_AXIL_MASTER {0} \
      CPM_PCIE1_PF2_PCIEBAR2AXIBAR_AXIST_BYPASS {0} \
      CPM_PCIE1_PF2_PRI_CAP_ON {0} \
      CPM_PCIE1_PF2_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
      CPM_PCIE1_PF2_SRIOV_BAR0_64BIT {0} \
      CPM_PCIE1_PF2_SRIOV_BAR0_ENABLED {1} \
      CPM_PCIE1_PF2_SRIOV_BAR0_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_SRIOV_BAR0_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_SRIOV_BAR0_SIZE {4} \
      CPM_PCIE1_PF2_SRIOV_BAR0_TYPE {Memory} \
      CPM_PCIE1_PF2_SRIOV_BAR1_64BIT {0} \
      CPM_PCIE1_PF2_SRIOV_BAR1_ENABLED {0} \
      CPM_PCIE1_PF2_SRIOV_BAR1_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_SRIOV_BAR1_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_SRIOV_BAR1_SIZE {4} \
      CPM_PCIE1_PF2_SRIOV_BAR1_TYPE {Memory} \
      CPM_PCIE1_PF2_SRIOV_BAR2_64BIT {0} \
      CPM_PCIE1_PF2_SRIOV_BAR2_ENABLED {0} \
      CPM_PCIE1_PF2_SRIOV_BAR2_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_SRIOV_BAR2_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_SRIOV_BAR2_SIZE {4} \
      CPM_PCIE1_PF2_SRIOV_BAR2_TYPE {Memory} \
      CPM_PCIE1_PF2_SRIOV_BAR3_64BIT {0} \
      CPM_PCIE1_PF2_SRIOV_BAR3_ENABLED {0} \
      CPM_PCIE1_PF2_SRIOV_BAR3_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_SRIOV_BAR3_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_SRIOV_BAR3_SIZE {4} \
      CPM_PCIE1_PF2_SRIOV_BAR3_TYPE {Memory} \
      CPM_PCIE1_PF2_SRIOV_BAR4_64BIT {0} \
      CPM_PCIE1_PF2_SRIOV_BAR4_ENABLED {0} \
      CPM_PCIE1_PF2_SRIOV_BAR4_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_SRIOV_BAR4_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_SRIOV_BAR4_SIZE {4} \
      CPM_PCIE1_PF2_SRIOV_BAR4_TYPE {Memory} \
      CPM_PCIE1_PF2_SRIOV_BAR5_64BIT {0} \
      CPM_PCIE1_PF2_SRIOV_BAR5_ENABLED {0} \
      CPM_PCIE1_PF2_SRIOV_BAR5_PREFETCHABLE {0} \
      CPM_PCIE1_PF2_SRIOV_BAR5_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_SRIOV_BAR5_SIZE {4} \
      CPM_PCIE1_PF2_SRIOV_BAR5_TYPE {Memory} \
      CPM_PCIE1_PF2_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE1_PF2_SRIOV_CAP_INITIAL_VF {4} \
      CPM_PCIE1_PF2_SRIOV_CAP_TOTAL_VF {0} \
      CPM_PCIE1_PF2_SRIOV_CAP_VER {1} \
      CPM_PCIE1_PF2_SRIOV_FIRST_VF_OFFSET {10} \
      CPM_PCIE1_PF2_SRIOV_FUNC_DEP_LINK {0} \
      CPM_PCIE1_PF2_SRIOV_SUPPORTED_PAGE_SIZE {553} \
      CPM_PCIE1_PF2_SRIOV_VF_DEVICE_ID {C234} \
      CPM_PCIE1_PF2_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE1_PF2_SUB_CLASS_VALUE {80} \
      CPM_PCIE1_PF2_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE1_PF2_VEND_ID {0} \
      CPM_PCIE1_PF3_ARI_CAP_NEXT_FUNC {0} \
      CPM_PCIE1_PF3_ATS_CAP_ON {0} \
      CPM_PCIE1_PF3_AXILITE_MASTER_64BIT {0} \
      CPM_PCIE1_PF3_AXILITE_MASTER_ENABLED {0} \
      CPM_PCIE1_PF3_AXILITE_MASTER_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_AXILITE_MASTER_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_AXILITE_MASTER_SIZE {128} \
      CPM_PCIE1_PF3_AXIST_BYPASS_64BIT {0} \
      CPM_PCIE1_PF3_AXIST_BYPASS_ENABLED {0} \
      CPM_PCIE1_PF3_AXIST_BYPASS_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_AXIST_BYPASS_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_AXIST_BYPASS_SIZE {128} \
      CPM_PCIE1_PF3_BAR0_64BIT {0} \
      CPM_PCIE1_PF3_BAR0_ENABLED {1} \
      CPM_PCIE1_PF3_BAR0_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_BAR0_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_BAR0_SIZE {128} \
      CPM_PCIE1_PF3_BAR0_TYPE {Memory} \
      CPM_PCIE1_PF3_BAR1_64BIT {0} \
      CPM_PCIE1_PF3_BAR1_ENABLED {0} \
      CPM_PCIE1_PF3_BAR1_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_BAR1_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_BAR1_SIZE {4} \
      CPM_PCIE1_PF3_BAR1_TYPE {Memory} \
      CPM_PCIE1_PF3_BAR2_64BIT {0} \
      CPM_PCIE1_PF3_BAR2_ENABLED {0} \
      CPM_PCIE1_PF3_BAR2_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_BAR2_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_BAR2_SIZE {4} \
      CPM_PCIE1_PF3_BAR2_TYPE {Memory} \
      CPM_PCIE1_PF3_BAR3_64BIT {0} \
      CPM_PCIE1_PF3_BAR3_ENABLED {0} \
      CPM_PCIE1_PF3_BAR3_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_BAR3_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_BAR3_SIZE {4} \
      CPM_PCIE1_PF3_BAR3_TYPE {Memory} \
      CPM_PCIE1_PF3_BAR4_64BIT {0} \
      CPM_PCIE1_PF3_BAR4_ENABLED {0} \
      CPM_PCIE1_PF3_BAR4_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_BAR4_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_BAR4_SIZE {4} \
      CPM_PCIE1_PF3_BAR4_TYPE {Memory} \
      CPM_PCIE1_PF3_BAR5_64BIT {0} \
      CPM_PCIE1_PF3_BAR5_ENABLED {0} \
      CPM_PCIE1_PF3_BAR5_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_BAR5_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_BAR5_SIZE {4} \
      CPM_PCIE1_PF3_BAR5_TYPE {Memory} \
      CPM_PCIE1_PF3_BASE_CLASS_MENU {Memory_controller} \
      CPM_PCIE1_PF3_BASE_CLASS_VALUE {05} \
      CPM_PCIE1_PF3_CAPABILITY_POINTER {80} \
      CPM_PCIE1_PF3_CFG_DEV_ID {B334} \
      CPM_PCIE1_PF3_CFG_REV_ID {0} \
      CPM_PCIE1_PF3_CFG_SUBSYS_ID {7} \
      CPM_PCIE1_PF3_CFG_SUBSYS_VEND_ID {10EE} \
      CPM_PCIE1_PF3_CLASS_CODE {0x058000} \
      CPM_PCIE1_PF3_DSN_CAP_ENABLE {0} \
      CPM_PCIE1_PF3_EXPANSION_ROM_ENABLED {0} \
      CPM_PCIE1_PF3_EXPANSION_ROM_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_EXPANSION_ROM_SIZE {2} \
      CPM_PCIE1_PF3_INTERFACE_VALUE {00} \
      CPM_PCIE1_PF3_INTERRUPT_PIN {NONE} \
      CPM_PCIE1_PF3_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE1_PF3_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE1_PF3_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE1_PF3_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE1_PF3_MSIX_CAP_TABLE_SIZE {001} \
      CPM_PCIE1_PF3_MSIX_ENABLED {1} \
      CPM_PCIE1_PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
      CPM_PCIE1_PF3_MSI_CAP_PERVECMASKCAP {0} \
      CPM_PCIE1_PF3_MSI_ENABLED {1} \
      CPM_PCIE1_PF3_PCIEBAR2AXIBAR_AXIL_MASTER {0} \
      CPM_PCIE1_PF3_PCIEBAR2AXIBAR_AXIST_BYPASS {0} \
      CPM_PCIE1_PF3_PRI_CAP_ON {0} \
      CPM_PCIE1_PF3_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
      CPM_PCIE1_PF3_SRIOV_BAR0_64BIT {0} \
      CPM_PCIE1_PF3_SRIOV_BAR0_ENABLED {1} \
      CPM_PCIE1_PF3_SRIOV_BAR0_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_SRIOV_BAR0_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_SRIOV_BAR0_SIZE {4} \
      CPM_PCIE1_PF3_SRIOV_BAR0_TYPE {Memory} \
      CPM_PCIE1_PF3_SRIOV_BAR1_64BIT {0} \
      CPM_PCIE1_PF3_SRIOV_BAR1_ENABLED {0} \
      CPM_PCIE1_PF3_SRIOV_BAR1_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_SRIOV_BAR1_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_SRIOV_BAR1_SIZE {4} \
      CPM_PCIE1_PF3_SRIOV_BAR1_TYPE {Memory} \
      CPM_PCIE1_PF3_SRIOV_BAR2_64BIT {0} \
      CPM_PCIE1_PF3_SRIOV_BAR2_ENABLED {0} \
      CPM_PCIE1_PF3_SRIOV_BAR2_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_SRIOV_BAR2_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_SRIOV_BAR2_SIZE {4} \
      CPM_PCIE1_PF3_SRIOV_BAR2_TYPE {Memory} \
      CPM_PCIE1_PF3_SRIOV_BAR3_64BIT {0} \
      CPM_PCIE1_PF3_SRIOV_BAR3_ENABLED {0} \
      CPM_PCIE1_PF3_SRIOV_BAR3_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_SRIOV_BAR3_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_SRIOV_BAR3_SIZE {4} \
      CPM_PCIE1_PF3_SRIOV_BAR3_TYPE {Memory} \
      CPM_PCIE1_PF3_SRIOV_BAR4_64BIT {0} \
      CPM_PCIE1_PF3_SRIOV_BAR4_ENABLED {0} \
      CPM_PCIE1_PF3_SRIOV_BAR4_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_SRIOV_BAR4_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_SRIOV_BAR4_SIZE {4} \
      CPM_PCIE1_PF3_SRIOV_BAR4_TYPE {Memory} \
      CPM_PCIE1_PF3_SRIOV_BAR5_64BIT {0} \
      CPM_PCIE1_PF3_SRIOV_BAR5_ENABLED {0} \
      CPM_PCIE1_PF3_SRIOV_BAR5_PREFETCHABLE {0} \
      CPM_PCIE1_PF3_SRIOV_BAR5_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_SRIOV_BAR5_SIZE {4} \
      CPM_PCIE1_PF3_SRIOV_BAR5_TYPE {Memory} \
      CPM_PCIE1_PF3_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE1_PF3_SRIOV_CAP_INITIAL_VF {4} \
      CPM_PCIE1_PF3_SRIOV_CAP_TOTAL_VF {0} \
      CPM_PCIE1_PF3_SRIOV_CAP_VER {1} \
      CPM_PCIE1_PF3_SRIOV_FIRST_VF_OFFSET {13} \
      CPM_PCIE1_PF3_SRIOV_FUNC_DEP_LINK {0} \
      CPM_PCIE1_PF3_SRIOV_SUPPORTED_PAGE_SIZE {553} \
      CPM_PCIE1_PF3_SRIOV_VF_DEVICE_ID {C334} \
      CPM_PCIE1_PF3_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE1_PF3_SUB_CLASS_VALUE {80} \
      CPM_PCIE1_PF3_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE1_PF3_VEND_ID {0} \
      CPM_PCIE1_PL_LINK_CAP_MAX_LINK_SPEED {Gen3} \
      CPM_PCIE1_PL_LINK_CAP_MAX_LINK_WIDTH {NONE} \
      CPM_PCIE1_PL_UPSTREAM_FACING {1} \
      CPM_PCIE1_PL_USER_SPARE {0} \
      CPM_PCIE1_PM_ASPML0S_TIMEOUT {0} \
      CPM_PCIE1_PM_ASPML1_ENTRY_DELAY {0} \
      CPM_PCIE1_PM_ENABLE_L23_ENTRY {0} \
      CPM_PCIE1_PM_ENABLE_SLOT_POWER_CAPTURE {1} \
      CPM_PCIE1_PM_L1_REENTRY_DELAY {0} \
      CPM_PCIE1_PM_PME_TURNOFF_ACK_DELAY {0} \
      CPM_PCIE1_PORT_TYPE {PCI_Express_Endpoint_device} \
      CPM_PCIE1_REF_CLK_FREQ {100_MHz} \
      CPM_PCIE1_SRIOV_CAP_ENABLE {0} \
      CPM_PCIE1_SRIOV_FIRST_VF_OFFSET {4} \
      CPM_PCIE1_TL2CFG_IF_PARITY_CHK {0} \
      CPM_PCIE1_TL_PF_ENABLE_REG {1} \
      CPM_PCIE1_TL_USER_SPARE {0} \
      CPM_PCIE1_TX_FC_IF {0} \
      CPM_PCIE1_TYPE1_MEMBASE_MEMLIMIT_ENABLE {Disabled} \
      CPM_PCIE1_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT {Disabled} \
      CPM_PCIE1_USER_CLK2_FREQ {125_MHz} \
      CPM_PCIE1_USER_CLK_FREQ {125_MHz} \
      CPM_PCIE1_USER_EDR_CLK2_FREQ {312.5_MHz} \
      CPM_PCIE1_USER_EDR_CLK_FREQ {312.5_MHz} \
      CPM_PCIE1_VC0_CAPABILITY_POINTER {80} \
      CPM_PCIE1_VC1_BASE_DISABLE {0} \
      CPM_PCIE1_VFG0_ATS_CAP_ON {0} \
      CPM_PCIE1_VFG0_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE1_VFG0_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE1_VFG0_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE1_VFG0_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE1_VFG0_MSIX_CAP_TABLE_SIZE {1} \
      CPM_PCIE1_VFG0_MSIX_ENABLED {0} \
      CPM_PCIE1_VFG0_PRI_CAP_ON {0} \
      CPM_PCIE1_VFG1_ATS_CAP_ON {0} \
      CPM_PCIE1_VFG1_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE1_VFG1_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE1_VFG1_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE1_VFG1_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE1_VFG1_MSIX_CAP_TABLE_SIZE {1} \
      CPM_PCIE1_VFG1_MSIX_ENABLED {0} \
      CPM_PCIE1_VFG1_PRI_CAP_ON {0} \
      CPM_PCIE1_VFG2_ATS_CAP_ON {0} \
      CPM_PCIE1_VFG2_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE1_VFG2_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE1_VFG2_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE1_VFG2_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE1_VFG2_MSIX_CAP_TABLE_SIZE {1} \
      CPM_PCIE1_VFG2_MSIX_ENABLED {0} \
      CPM_PCIE1_VFG2_PRI_CAP_ON {0} \
      CPM_PCIE1_VFG3_ATS_CAP_ON {0} \
      CPM_PCIE1_VFG3_MSIX_CAP_PBA_BIR {BAR_0} \
      CPM_PCIE1_VFG3_MSIX_CAP_PBA_OFFSET {50} \
      CPM_PCIE1_VFG3_MSIX_CAP_TABLE_BIR {BAR_0} \
      CPM_PCIE1_VFG3_MSIX_CAP_TABLE_OFFSET {40} \
      CPM_PCIE1_VFG3_MSIX_CAP_TABLE_SIZE {1} \
      CPM_PCIE1_VFG3_MSIX_ENABLED {0} \
      CPM_PCIE1_VFG3_PRI_CAP_ON {0} \
      CPM_PCIE_CHANNELS_FOR_POWER {0} \
      CPM_PERIPHERAL_EN {0} \
      CPM_PERIPHERAL_TEST_EN {0} \
      CPM_REQ_AGENTS_0_ENABLE {0} \
      CPM_REQ_AGENTS_0_L2_ENABLE {0} \
      CPM_REQ_AGENTS_1_ENABLE {0} \
      CPM_SELECT_GTOUTCLK {TXOUTCLK} \
      CPM_TYPE1_MEMBASE_MEMLIMIT_ENABLE {Disabled} \
      CPM_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT {Disabled} \
      CPM_USE_MODES {None} \
      CPM_XDMA_2PF_INTERRUPT_ENABLE {0} \
      CPM_XDMA_TL_PF_VISIBLE {1} \
      CPM_XPIPE_0_CLKDLY_CFG {536870912} \
      CPM_XPIPE_0_CLK_CFG {0} \
      CPM_XPIPE_0_INSTANTIATED {0} \
      CPM_XPIPE_0_LINK0_CFG {DISABLE} \
      CPM_XPIPE_0_LINK1_CFG {DISABLE} \
      CPM_XPIPE_0_LOC {QUAD0} \
      CPM_XPIPE_0_MODE {0} \
      CPM_XPIPE_0_REG_CFG {0} \
      CPM_XPIPE_0_RSVD {16} \
      CPM_XPIPE_1_CLKDLY_CFG {570427392} \
      CPM_XPIPE_1_CLK_CFG {0} \
      CPM_XPIPE_1_INSTANTIATED {0} \
      CPM_XPIPE_1_LINK0_CFG {DISABLE} \
      CPM_XPIPE_1_LINK1_CFG {DISABLE} \
      CPM_XPIPE_1_LOC {QUAD1} \
      CPM_XPIPE_1_MODE {0} \
      CPM_XPIPE_1_REG_CFG {0} \
      CPM_XPIPE_1_RSVD {16} \
      CPM_XPIPE_2_CLKDLY_CFG {50331778} \
      CPM_XPIPE_2_CLK_CFG {0} \
      CPM_XPIPE_2_INSTANTIATED {0} \
      CPM_XPIPE_2_LINK0_CFG {DISABLE} \
      CPM_XPIPE_2_LINK1_CFG {DISABLE} \
      CPM_XPIPE_2_LOC {QUAD2} \
      CPM_XPIPE_2_MODE {0} \
      CPM_XPIPE_2_REG_CFG {0} \
      CPM_XPIPE_2_RSVD {16} \
      CPM_XPIPE_3_CLKDLY_CFG {16777218} \
      CPM_XPIPE_3_CLK_CFG {0} \
      CPM_XPIPE_3_INSTANTIATED {0} \
      CPM_XPIPE_3_LINK0_CFG {DISABLE} \
      CPM_XPIPE_3_LINK1_CFG {DISABLE} \
      CPM_XPIPE_3_LOC {QUAD3} \
      CPM_XPIPE_3_MODE {0} \
      CPM_XPIPE_3_REG_CFG {0} \
      CPM_XPIPE_3_RSVD {16} \
      GT_REFCLK_MHZ {156.25} \
      PS_HSDP0_REFCLK {0} \
      PS_HSDP1_REFCLK {0} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_USE_NOC_PS_PCI_0 {0} \
      PS_USE_PS_NOC_PCI_0 {0} \
      PS_USE_PS_NOC_PCI_1 {0} \
    } \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      AURORA_LINE_RATE_GPBS {10.0} \
      BOOT_MODE {Custom} \
      BOOT_SECONDARY_PCIE_ENABLE {0} \
      CLOCK_MODE {Custom} \
      COHERENCY_MODE {Custom} \
      CPM_PCIE0_TANDEM {None} \
      DDR_MEMORY_MODE {Custom} \
      DEBUG_MODE {Custom} \
      DESIGN_MODE {1} \
      DEVICE_INTEGRITY_MODE {Custom} \
      DIS_AUTO_POL_CHECK {0} \
      GT_REFCLK_MHZ {156.25} \
      INIT_CLK_MHZ {125} \
      INV_POLARITY {0} \
      IO_CONFIG_MODE {Custom} \
      JTAG_USERCODE {0x0} \
      OT_EAM_RESP {SRST} \
      PCIE_APERTURES_DUAL_ENABLE {0} \
      PCIE_APERTURES_SINGLE_ENABLE {0} \
      PERFORMANCE_MODE {Custom} \
      PL_SEM_GPIO_ENABLE {0} \
      PMC_ALT_REF_CLK_FREQMHZ {33.333} \
      PMC_BANK_0_IO_STANDARD {LVCMOS1.8} \
      PMC_BANK_1_IO_STANDARD {LVCMOS1.8} \
      PMC_CIPS_MODE {ADVANCE} \
      PMC_CORE_SUBSYSTEM_LOAD {10} \
      PMC_CRP_CFU_REF_CTRL_ACT_FREQMHZ {299.997009} \
      PMC_CRP_CFU_REF_CTRL_DIVISOR0 {4} \
      PMC_CRP_CFU_REF_CTRL_FREQMHZ {300} \
      PMC_CRP_CFU_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_DFT_OSC_REF_CTRL_ACT_FREQMHZ {400} \
      PMC_CRP_DFT_OSC_REF_CTRL_DIVISOR0 {3} \
      PMC_CRP_DFT_OSC_REF_CTRL_FREQMHZ {400} \
      PMC_CRP_DFT_OSC_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_EFUSE_REF_CTRL_ACT_FREQMHZ {100.000000} \
      PMC_CRP_EFUSE_REF_CTRL_FREQMHZ {100.000000} \
      PMC_CRP_EFUSE_REF_CTRL_SRCSEL {IRO_CLK/4} \
      PMC_CRP_HSM0_REF_CTRL_ACT_FREQMHZ {33.333000} \
      PMC_CRP_HSM0_REF_CTRL_DIVISOR0 {36} \
      PMC_CRP_HSM0_REF_CTRL_FREQMHZ {33.333} \
      PMC_CRP_HSM0_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_HSM1_REF_CTRL_ACT_FREQMHZ {133.332001} \
      PMC_CRP_HSM1_REF_CTRL_DIVISOR0 {9} \
      PMC_CRP_HSM1_REF_CTRL_FREQMHZ {133.333} \
      PMC_CRP_HSM1_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_I2C_REF_CTRL_ACT_FREQMHZ {100} \
      PMC_CRP_I2C_REF_CTRL_DIVISOR0 {12} \
      PMC_CRP_I2C_REF_CTRL_FREQMHZ {100} \
      PMC_CRP_I2C_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_LSBUS_REF_CTRL_ACT_FREQMHZ {149.998505} \
      PMC_CRP_LSBUS_REF_CTRL_DIVISOR0 {8} \
      PMC_CRP_LSBUS_REF_CTRL_FREQMHZ {150} \
      PMC_CRP_LSBUS_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_NOC_REF_CTRL_ACT_FREQMHZ {999.989990} \
      PMC_CRP_NOC_REF_CTRL_FREQMHZ {1000} \
      PMC_CRP_NOC_REF_CTRL_SRCSEL {NPLL} \
      PMC_CRP_NPI_REF_CTRL_ACT_FREQMHZ {299.997009} \
      PMC_CRP_NPI_REF_CTRL_DIVISOR0 {4} \
      PMC_CRP_NPI_REF_CTRL_FREQMHZ {300} \
      PMC_CRP_NPI_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_NPLL_CTRL_CLKOUTDIV {4} \
      PMC_CRP_NPLL_CTRL_FBDIV {120} \
      PMC_CRP_NPLL_CTRL_SRCSEL {REF_CLK} \
      PMC_CRP_NPLL_TO_XPD_CTRL_DIVISOR0 {4} \
      PMC_CRP_OSPI_REF_CTRL_ACT_FREQMHZ {200} \
      PMC_CRP_OSPI_REF_CTRL_DIVISOR0 {4} \
      PMC_CRP_OSPI_REF_CTRL_FREQMHZ {200} \
      PMC_CRP_OSPI_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_PL0_REF_CTRL_ACT_FREQMHZ {240} \
      PMC_CRP_PL0_REF_CTRL_DIVISOR0 {3} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {334} \
      PMC_CRP_PL0_REF_CTRL_SRCSEL {NPLL} \
      PMC_CRP_PL1_REF_CTRL_ACT_FREQMHZ {100} \
      PMC_CRP_PL1_REF_CTRL_DIVISOR0 {3} \
      PMC_CRP_PL1_REF_CTRL_FREQMHZ {334} \
      PMC_CRP_PL1_REF_CTRL_SRCSEL {NPLL} \
      PMC_CRP_PL2_REF_CTRL_ACT_FREQMHZ {100} \
      PMC_CRP_PL2_REF_CTRL_DIVISOR0 {3} \
      PMC_CRP_PL2_REF_CTRL_FREQMHZ {334} \
      PMC_CRP_PL2_REF_CTRL_SRCSEL {NPLL} \
      PMC_CRP_PL3_REF_CTRL_ACT_FREQMHZ {100} \
      PMC_CRP_PL3_REF_CTRL_DIVISOR0 {3} \
      PMC_CRP_PL3_REF_CTRL_FREQMHZ {334} \
      PMC_CRP_PL3_REF_CTRL_SRCSEL {NPLL} \
      PMC_CRP_PL5_REF_CTRL_FREQMHZ {400} \
      PMC_CRP_PPLL_CTRL_CLKOUTDIV {2} \
      PMC_CRP_PPLL_CTRL_FBDIV {72} \
      PMC_CRP_PPLL_CTRL_SRCSEL {REF_CLK} \
      PMC_CRP_PPLL_TO_XPD_CTRL_DIVISOR0 {1} \
      PMC_CRP_QSPI_REF_CTRL_ACT_FREQMHZ {300} \
      PMC_CRP_QSPI_REF_CTRL_DIVISOR0 {4} \
      PMC_CRP_QSPI_REF_CTRL_FREQMHZ {300} \
      PMC_CRP_QSPI_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_SDIO0_REF_CTRL_ACT_FREQMHZ {200} \
      PMC_CRP_SDIO0_REF_CTRL_DIVISOR0 {6} \
      PMC_CRP_SDIO0_REF_CTRL_FREQMHZ {200} \
      PMC_CRP_SDIO0_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_SDIO1_REF_CTRL_ACT_FREQMHZ {200} \
      PMC_CRP_SDIO1_REF_CTRL_DIVISOR0 {6} \
      PMC_CRP_SDIO1_REF_CTRL_FREQMHZ {200} \
      PMC_CRP_SDIO1_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_SD_DLL_REF_CTRL_ACT_FREQMHZ {1200} \
      PMC_CRP_SD_DLL_REF_CTRL_DIVISOR0 {1} \
      PMC_CRP_SD_DLL_REF_CTRL_FREQMHZ {1200} \
      PMC_CRP_SD_DLL_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_SWITCH_TIMEOUT_CTRL_ACT_FREQMHZ {1.000000} \
      PMC_CRP_SWITCH_TIMEOUT_CTRL_DIVISOR0 {100} \
      PMC_CRP_SWITCH_TIMEOUT_CTRL_FREQMHZ {1} \
      PMC_CRP_SWITCH_TIMEOUT_CTRL_SRCSEL {IRO_CLK/4} \
      PMC_CRP_SYSMON_REF_CTRL_ACT_FREQMHZ {299.997009} \
      PMC_CRP_SYSMON_REF_CTRL_FREQMHZ {299.997009} \
      PMC_CRP_SYSMON_REF_CTRL_SRCSEL {NPI_REF_CLK} \
      PMC_CRP_TEST_PATTERN_REF_CTRL_ACT_FREQMHZ {200} \
      PMC_CRP_TEST_PATTERN_REF_CTRL_DIVISOR0 {6} \
      PMC_CRP_TEST_PATTERN_REF_CTRL_FREQMHZ {200} \
      PMC_CRP_TEST_PATTERN_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_USB_SUSPEND_CTRL_ACT_FREQMHZ {0.200000} \
      PMC_CRP_USB_SUSPEND_CTRL_DIVISOR0 {500} \
      PMC_CRP_USB_SUSPEND_CTRL_FREQMHZ {0.2} \
      PMC_CRP_USB_SUSPEND_CTRL_SRCSEL {IRO_CLK/4} \
      PMC_EXTERNAL_TAMPER {{ENABLE 0} {IO {PMC_MIO 12}}} \
      PMC_EXTERNAL_TAMPER_1 {{ENABLE 0} {IO None}} \
      PMC_EXTERNAL_TAMPER_2 {{ENABLE 0} {IO None}} \
      PMC_EXTERNAL_TAMPER_3 {{ENABLE 0} {IO None}} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 26 .. 51}}} \
      PMC_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
      PMC_GPIO_EMIO_WIDTH {64} \
      PMC_GPIO_EMIO_WIDTH_HDL {64} \
      PMC_GPI_ENABLE {0} \
      PMC_GPI_WIDTH {32} \
      PMC_GPO_ENABLE {0} \
      PMC_GPO_WIDTH {32} \
      PMC_HSM0_CLK_ENABLE {1} \
      PMC_HSM1_CLK_ENABLE {1} \
      PMC_I2CPMC_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 2 .. 3}}} \
      PMC_MIO0 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO1 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO10 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO11 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO12 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO13 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO14 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO15 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO16 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO17 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO18 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO2 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO20 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO22 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO23 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO24 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO25 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO26 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO27 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO28 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO29 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO3 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO30 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO31 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO32 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO33 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO34 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO35 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO36 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pulldown} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_MIO38 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO39 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO4 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO40 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO41 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO42 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PMC_MIO43 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW slow} {USAGE Reserved}} \
      PMC_MIO44 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO45 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO46 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO47 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO48 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO49 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO5 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO50 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO51 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO6 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO8 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PMC_MIO_EN_FOR_PL_PCIE {0} \
      PMC_MIO_TREE_PERIPHERALS {#####################################GPIO 1#####UART 0#UART 0##################################} \
      PMC_MIO_TREE_SIGNALS {#####################################gpio_1_pin[37]#####rxd#txd##################################} \
      PMC_NOC_PMC_ADDR_WIDTH {64} \
      PMC_NOC_PMC_DATA_WIDTH {128} \
      PMC_OSPI_COHERENCY {0} \
      PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_OSPI_ROUTE_THROUGH_FPD {0} \
      PMC_OT_CHECK {{DELAY 0} {ENABLE 0}} \
      PMC_PL_ALT_REF_CLK_FREQMHZ {33.333} \
      PMC_PMC_NOC_ADDR_WIDTH {64} \
      PMC_PMC_NOC_DATA_WIDTH {128} \
      PMC_QSPI_COHERENCY {0} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x1} \
      PMC_QSPI_PERIPHERAL_ENABLE {0} \
      PMC_QSPI_PERIPHERAL_MODE {Single} \
      PMC_QSPI_ROUTE_THROUGH_FPD {0} \
      PMC_REF_CLK_FREQMHZ {33.333} \
      PMC_SD0 {{CD_ENABLE 0} {CD_IO {PMC_MIO 24}} {POW_ENABLE 0} {POW_IO {PMC_MIO 17}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 17}} {WP_ENABLE 0} {WP_IO {PMC_MIO 25}}} \
      PMC_SD0_COHERENCY {0} \
      PMC_SD0_DATA_TRANSFER_MODE {4Bit} \
      PMC_SD0_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x00} {CLK_200_SDR_OTAP_DLY 0x00} {CLK_50_DDR_ITAP_DLY 0x00} {CLK_50_DDR_OTAP_DLY 0x00} {CLK_50_SDR_ITAP_DLY 0x00} {CLK_50_SDR_OTAP_DLY 0x00} {ENABLE 0}\
{IO {PMC_MIO 13 .. 25}}} \
      PMC_SD0_ROUTE_THROUGH_FPD {0} \
      PMC_SD0_SLOT_TYPE {SD 2.0} \
      PMC_SD0_SPEED_MODE {default speed} \
      PMC_SD1 {{CD_ENABLE 0} {CD_IO {PMC_MIO 2}} {POW_ENABLE 0} {POW_IO {PMC_MIO 12}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_COHERENCY {0} \
      PMC_SD1_DATA_TRANSFER_MODE {4Bit} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x00} {CLK_200_SDR_OTAP_DLY 0x00} {CLK_50_DDR_ITAP_DLY 0x00} {CLK_50_DDR_OTAP_DLY 0x00} {CLK_50_SDR_ITAP_DLY 0x00} {CLK_50_SDR_OTAP_DLY 0x00} {ENABLE 0}\
{IO {PMC_MIO 0 .. 11}}} \
      PMC_SD1_ROUTE_THROUGH_FPD {0} \
      PMC_SD1_SLOT_TYPE {SD 2.0} \
      PMC_SD1_SPEED_MODE {default speed} \
      PMC_SHOW_CCI_SMMU_SETTINGS {0} \
      PMC_SMAP_PERIPHERAL {{ENABLE 0} {IO {32 Bit}}} \
      PMC_TAMPER_EXTMIO_ENABLE {0} \
      PMC_TAMPER_EXTMIO_ERASE_BBRAM {0} \
      PMC_TAMPER_EXTMIO_RESPONSE {SYS INTERRUPT} \
      PMC_TAMPER_GLITCHDETECT_ENABLE {0} \
      PMC_TAMPER_GLITCHDETECT_ENABLE_1 {0} \
      PMC_TAMPER_GLITCHDETECT_ENABLE_2 {0} \
      PMC_TAMPER_GLITCHDETECT_ENABLE_3 {0} \
      PMC_TAMPER_GLITCHDETECT_ERASE_BBRAM {0} \
      PMC_TAMPER_GLITCHDETECT_ERASE_BBRAM_1 {0} \
      PMC_TAMPER_GLITCHDETECT_ERASE_BBRAM_2 {0} \
      PMC_TAMPER_GLITCHDETECT_ERASE_BBRAM_3 {0} \
      PMC_TAMPER_GLITCHDETECT_RESPONSE {SYS INTERRUPT} \
      PMC_TAMPER_GLITCHDETECT_RESPONSE_1 {SYS INTERRUPT} \
      PMC_TAMPER_GLITCHDETECT_RESPONSE_2 {SYS INTERRUPT} \
      PMC_TAMPER_GLITCHDETECT_RESPONSE_3 {SYS INTERRUPT} \
      PMC_TAMPER_JTAGDETECT_ENABLE {0} \
      PMC_TAMPER_JTAGDETECT_ENABLE_1 {0} \
      PMC_TAMPER_JTAGDETECT_ENABLE_2 {0} \
      PMC_TAMPER_JTAGDETECT_ENABLE_3 {0} \
      PMC_TAMPER_JTAGDETECT_ERASE_BBRAM {0} \
      PMC_TAMPER_JTAGDETECT_ERASE_BBRAM_1 {0} \
      PMC_TAMPER_JTAGDETECT_ERASE_BBRAM_2 {0} \
      PMC_TAMPER_JTAGDETECT_ERASE_BBRAM_3 {0} \
      PMC_TAMPER_JTAGDETECT_RESPONSE {SYS INTERRUPT} \
      PMC_TAMPER_JTAGDETECT_RESPONSE_1 {SYS INTERRUPT} \
      PMC_TAMPER_JTAGDETECT_RESPONSE_2 {SYS INTERRUPT} \
      PMC_TAMPER_JTAGDETECT_RESPONSE_3 {SYS INTERRUPT} \
      PMC_TAMPER_SUP_0_31_ENABLE {0} \
      PMC_TAMPER_SUP_0_31_ERASE_BBRAM {0} \
      PMC_TAMPER_SUP_0_31_RESPONSE {SYS INTERRUPT} \
      PMC_TAMPER_TEMPERATURE_ENABLE {0} \
      PMC_TAMPER_TEMPERATURE_ENABLE_1 {0} \
      PMC_TAMPER_TEMPERATURE_ENABLE_2 {0} \
      PMC_TAMPER_TEMPERATURE_ENABLE_3 {0} \
      PMC_TAMPER_TEMPERATURE_ERASE_BBRAM {0} \
      PMC_TAMPER_TEMPERATURE_ERASE_BBRAM_1 {0} \
      PMC_TAMPER_TEMPERATURE_ERASE_BBRAM_2 {0} \
      PMC_TAMPER_TEMPERATURE_ERASE_BBRAM_3 {0} \
      PMC_TAMPER_TEMPERATURE_RESPONSE {SYS INTERRUPT} \
      PMC_TAMPER_TEMPERATURE_RESPONSE_1 {SYS INTERRUPT} \
      PMC_TAMPER_TEMPERATURE_RESPONSE_2 {SYS INTERRUPT} \
      PMC_TAMPER_TEMPERATURE_RESPONSE_3 {SYS INTERRUPT} \
      PMC_USE_CFU_SEU {0} \
      PMC_USE_NOC_PMC_AXI0 {0} \
      PMC_USE_NOC_PMC_AXI1 {0} \
      PMC_USE_NOC_PMC_AXI2 {0} \
      PMC_USE_NOC_PMC_AXI3 {0} \
      PMC_USE_PL_PMC_AUX_REF_CLK {0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PMC_USE_PMC_NOC_AXI1 {0} \
      PMC_USE_PMC_NOC_AXI2 {0} \
      PMC_USE_PMC_NOC_AXI3 {0} \
      PMC_WDT_PERIOD {100} \
      PMC_WDT_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0}}} \
      POWER_REPORTING_MODE {Custom} \
      PSPMC_MANUAL_CLK_ENABLE {0} \
      PS_A72_ACTIVE_BLOCKS {2} \
      PS_A72_LOAD {90} \
      PS_BANK_2_IO_STANDARD {LVCMOS1.8} \
      PS_BANK_3_IO_STANDARD {LVCMOS1.8} \
      PS_BOARD_INTERFACE {Custom} \
      PS_CAN0_CLK {{ENABLE 0} {IO {PMC_MIO 0}}} \
      PS_CAN0_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 8 .. 9}}} \
      PS_CAN1_CLK {{ENABLE 0} {IO {PMC_MIO 0}}} \
      PS_CAN1_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 16 .. 17}}} \
      PS_CRF_ACPU_CTRL_ACT_FREQMHZ {1349.986450} \
      PS_CRF_ACPU_CTRL_DIVISOR0 {1} \
      PS_CRF_ACPU_CTRL_FREQMHZ {1350} \
      PS_CRF_ACPU_CTRL_SRCSEL {APLL} \
      PS_CRF_APLL_CTRL_CLKOUTDIV {2} \
      PS_CRF_APLL_CTRL_FBDIV {81} \
      PS_CRF_APLL_CTRL_SRCSEL {REF_CLK} \
      PS_CRF_APLL_TO_XPD_CTRL_DIVISOR0 {4} \
      PS_CRF_DBG_FPD_CTRL_ACT_FREQMHZ {399.996002} \
      PS_CRF_DBG_FPD_CTRL_DIVISOR0 {3} \
      PS_CRF_DBG_FPD_CTRL_FREQMHZ {400} \
      PS_CRF_DBG_FPD_CTRL_SRCSEL {PPLL} \
      PS_CRF_DBG_TRACE_CTRL_ACT_FREQMHZ {300} \
      PS_CRF_DBG_TRACE_CTRL_DIVISOR0 {3} \
      PS_CRF_DBG_TRACE_CTRL_FREQMHZ {300} \
      PS_CRF_DBG_TRACE_CTRL_SRCSEL {PPLL} \
      PS_CRF_FPD_LSBUS_CTRL_ACT_FREQMHZ {149.998505} \
      PS_CRF_FPD_LSBUS_CTRL_DIVISOR0 {8} \
      PS_CRF_FPD_LSBUS_CTRL_FREQMHZ {150} \
      PS_CRF_FPD_LSBUS_CTRL_SRCSEL {PPLL} \
      PS_CRF_FPD_TOP_SWITCH_CTRL_ACT_FREQMHZ {774.992249} \
      PS_CRF_FPD_TOP_SWITCH_CTRL_DIVISOR0 {1} \
      PS_CRF_FPD_TOP_SWITCH_CTRL_FREQMHZ {825} \
      PS_CRF_FPD_TOP_SWITCH_CTRL_SRCSEL {RPLL} \
      PS_CRL_CAN0_REF_CTRL_ACT_FREQMHZ {100} \
      PS_CRL_CAN0_REF_CTRL_DIVISOR0 {6} \
      PS_CRL_CAN0_REF_CTRL_FREQMHZ {160} \
      PS_CRL_CAN0_REF_CTRL_SRCSEL {NPLL} \
      PS_CRL_CAN1_REF_CTRL_ACT_FREQMHZ {100} \
      PS_CRL_CAN1_REF_CTRL_DIVISOR0 {6} \
      PS_CRL_CAN1_REF_CTRL_FREQMHZ {160} \
      PS_CRL_CAN1_REF_CTRL_SRCSEL {NPLL} \
      PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ {774.992249} \
      PS_CRL_CPM_TOPSW_REF_CTRL_DIVISOR0 {1} \
      PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {775} \
      PS_CRL_CPM_TOPSW_REF_CTRL_SRCSEL {RPLL} \
      PS_CRL_CPU_R5_CTRL_ACT_FREQMHZ {599.994019} \
      PS_CRL_CPU_R5_CTRL_DIVISOR0 {2} \
      PS_CRL_CPU_R5_CTRL_FREQMHZ {600} \
      PS_CRL_CPU_R5_CTRL_SRCSEL {PPLL} \
      PS_CRL_DBG_LPD_CTRL_ACT_FREQMHZ {399.996002} \
      PS_CRL_DBG_LPD_CTRL_DIVISOR0 {3} \
      PS_CRL_DBG_LPD_CTRL_FREQMHZ {400} \
      PS_CRL_DBG_LPD_CTRL_SRCSEL {PPLL} \
      PS_CRL_DBG_TSTMP_CTRL_ACT_FREQMHZ {399.996002} \
      PS_CRL_DBG_TSTMP_CTRL_DIVISOR0 {3} \
      PS_CRL_DBG_TSTMP_CTRL_FREQMHZ {400} \
      PS_CRL_DBG_TSTMP_CTRL_SRCSEL {PPLL} \
      PS_CRL_GEM0_REF_CTRL_ACT_FREQMHZ {125} \
      PS_CRL_GEM0_REF_CTRL_DIVISOR0 {4} \
      PS_CRL_GEM0_REF_CTRL_FREQMHZ {125} \
      PS_CRL_GEM0_REF_CTRL_SRCSEL {NPLL} \
      PS_CRL_GEM1_REF_CTRL_ACT_FREQMHZ {125} \
      PS_CRL_GEM1_REF_CTRL_DIVISOR0 {4} \
      PS_CRL_GEM1_REF_CTRL_FREQMHZ {125} \
      PS_CRL_GEM1_REF_CTRL_SRCSEL {NPLL} \
      PS_CRL_GEM_TSU_REF_CTRL_ACT_FREQMHZ {250} \
      PS_CRL_GEM_TSU_REF_CTRL_DIVISOR0 {2} \
      PS_CRL_GEM_TSU_REF_CTRL_FREQMHZ {250} \
      PS_CRL_GEM_TSU_REF_CTRL_SRCSEL {NPLL} \
      PS_CRL_I2C0_REF_CTRL_ACT_FREQMHZ {100} \
      PS_CRL_I2C0_REF_CTRL_DIVISOR0 {12} \
      PS_CRL_I2C0_REF_CTRL_FREQMHZ {100} \
      PS_CRL_I2C0_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_I2C1_REF_CTRL_ACT_FREQMHZ {100} \
      PS_CRL_I2C1_REF_CTRL_DIVISOR0 {12} \
      PS_CRL_I2C1_REF_CTRL_FREQMHZ {100} \
      PS_CRL_I2C1_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_IOU_SWITCH_CTRL_ACT_FREQMHZ {249.997498} \
      PS_CRL_IOU_SWITCH_CTRL_DIVISOR0 {1} \
      PS_CRL_IOU_SWITCH_CTRL_FREQMHZ {250} \
      PS_CRL_IOU_SWITCH_CTRL_SRCSEL {NPLL} \
      PS_CRL_LPD_LSBUS_CTRL_ACT_FREQMHZ {149.998505} \
      PS_CRL_LPD_LSBUS_CTRL_DIVISOR0 {8} \
      PS_CRL_LPD_LSBUS_CTRL_FREQMHZ {150} \
      PS_CRL_LPD_LSBUS_CTRL_SRCSEL {PPLL} \
      PS_CRL_LPD_TOP_SWITCH_CTRL_ACT_FREQMHZ {599.994019} \
      PS_CRL_LPD_TOP_SWITCH_CTRL_DIVISOR0 {2} \
      PS_CRL_LPD_TOP_SWITCH_CTRL_FREQMHZ {600} \
      PS_CRL_LPD_TOP_SWITCH_CTRL_SRCSEL {PPLL} \
      PS_CRL_PSM_REF_CTRL_ACT_FREQMHZ {399.996002} \
      PS_CRL_PSM_REF_CTRL_DIVISOR0 {3} \
      PS_CRL_PSM_REF_CTRL_FREQMHZ {400} \
      PS_CRL_PSM_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_RPLL_CTRL_CLKOUTDIV {4} \
      PS_CRL_RPLL_CTRL_FBDIV {93} \
      PS_CRL_RPLL_CTRL_SRCSEL {REF_CLK} \
      PS_CRL_RPLL_TO_XPD_CTRL_DIVISOR0 {1} \
      PS_CRL_SPI0_REF_CTRL_ACT_FREQMHZ {200} \
      PS_CRL_SPI0_REF_CTRL_DIVISOR0 {6} \
      PS_CRL_SPI0_REF_CTRL_FREQMHZ {200} \
      PS_CRL_SPI0_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_SPI1_REF_CTRL_ACT_FREQMHZ {200} \
      PS_CRL_SPI1_REF_CTRL_DIVISOR0 {6} \
      PS_CRL_SPI1_REF_CTRL_FREQMHZ {200} \
      PS_CRL_SPI1_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_TIMESTAMP_REF_CTRL_ACT_FREQMHZ {99.999001} \
      PS_CRL_TIMESTAMP_REF_CTRL_DIVISOR0 {12} \
      PS_CRL_TIMESTAMP_REF_CTRL_FREQMHZ {100} \
      PS_CRL_TIMESTAMP_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_UART0_REF_CTRL_ACT_FREQMHZ {99.999001} \
      PS_CRL_UART0_REF_CTRL_DIVISOR0 {12} \
      PS_CRL_UART0_REF_CTRL_FREQMHZ {100} \
      PS_CRL_UART0_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_UART1_REF_CTRL_ACT_FREQMHZ {100} \
      PS_CRL_UART1_REF_CTRL_DIVISOR0 {12} \
      PS_CRL_UART1_REF_CTRL_FREQMHZ {100} \
      PS_CRL_UART1_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_USB0_BUS_REF_CTRL_ACT_FREQMHZ {20} \
      PS_CRL_USB0_BUS_REF_CTRL_DIVISOR0 {60} \
      PS_CRL_USB0_BUS_REF_CTRL_FREQMHZ {20} \
      PS_CRL_USB0_BUS_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_USB3_DUAL_REF_CTRL_ACT_FREQMHZ {100} \
      PS_CRL_USB3_DUAL_REF_CTRL_DIVISOR0 {100} \
      PS_CRL_USB3_DUAL_REF_CTRL_FREQMHZ {100} \
      PS_CRL_USB3_DUAL_REF_CTRL_SRCSEL {PPLL} \
      PS_DDRC_ENABLE {1} \
      PS_DDR_RAM_HIGHADDR_OFFSET {34359738368} \
      PS_DDR_RAM_LOWADDR_OFFSET {2147483648} \
      PS_ENET0_MDIO {{ENABLE 0} {IO {PMC_MIO 50 .. 51}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 26 .. 37}}} \
      PS_ENET1_MDIO {{ENABLE 0} {IO {PMC_MIO 50 .. 51}}} \
      PS_ENET1_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 38 .. 49}}} \
      PS_EN_AXI_STATUS_PORTS {0} \
      PS_EN_PORTS_CONTROLLER_BASED {0} \
      PS_EXPAND_CORESIGHT {0} \
      PS_EXPAND_FPD_SLAVES {0} \
      PS_EXPAND_GIC {0} \
      PS_EXPAND_LPD_SLAVES {0} \
      PS_FPD_INTERCONNECT_LOAD {90} \
      PS_FTM_CTI_IN0 {0} \
      PS_FTM_CTI_IN1 {0} \
      PS_FTM_CTI_IN2 {0} \
      PS_FTM_CTI_IN3 {0} \
      PS_FTM_CTI_OUT0 {0} \
      PS_FTM_CTI_OUT1 {0} \
      PS_FTM_CTI_OUT2 {0} \
      PS_FTM_CTI_OUT3 {0} \
      PS_GEM0_COHERENCY {0} \
      PS_GEM0_ROUTE_THROUGH_FPD {0} \
      PS_GEM1_COHERENCY {0} \
      PS_GEM1_ROUTE_THROUGH_FPD {0} \
      PS_GEM_TSU {{ENABLE 0} {IO {PS_MIO 24}}} \
      PS_GEM_TSU_CLK_PORT_PAIR {0} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI1_MASTER {A72} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI2_MASTER {A72} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI3_MASTER {A72} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI4_MASTER {A72} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI5_MASTER {A72} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_GEN_IPI6_MASTER {A72} \
      PS_GEN_IPI_PMCNOBUF_ENABLE {1} \
      PS_GEN_IPI_PMCNOBUF_MASTER {PMC} \
      PS_GEN_IPI_PMC_ENABLE {1} \
      PS_GEN_IPI_PMC_MASTER {PMC} \
      PS_GEN_IPI_PSM_ENABLE {1} \
      PS_GEN_IPI_PSM_MASTER {PSM} \
      PS_GPIO2_MIO_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 0 .. 25}}} \
      PS_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
      PS_GPIO_EMIO_WIDTH {32} \
      PS_HSDP0_REFCLK {0} \
      PS_HSDP1_REFCLK {0} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_HSDP_SAME_EGRESS_AS_INGRESS_TRAFFIC {1} \
      PS_I2C0_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 2 .. 3}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 0 .. 1}}} \
      PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 23 .. 24}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 1} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
      PS_LPDMA0_COHERENCY {0} \
      PS_LPDMA0_ROUTE_THROUGH_FPD {0} \
      PS_LPDMA1_COHERENCY {0} \
      PS_LPDMA1_ROUTE_THROUGH_FPD {0} \
      PS_LPDMA2_COHERENCY {0} \
      PS_LPDMA2_ROUTE_THROUGH_FPD {0} \
      PS_LPDMA3_COHERENCY {0} \
      PS_LPDMA3_ROUTE_THROUGH_FPD {0} \
      PS_LPDMA4_COHERENCY {0} \
      PS_LPDMA4_ROUTE_THROUGH_FPD {0} \
      PS_LPDMA5_COHERENCY {0} \
      PS_LPDMA5_ROUTE_THROUGH_FPD {0} \
      PS_LPDMA6_COHERENCY {0} \
      PS_LPDMA6_ROUTE_THROUGH_FPD {0} \
      PS_LPDMA7_COHERENCY {0} \
      PS_LPDMA7_ROUTE_THROUGH_FPD {0} \
      PS_LPD_DMA_CHANNEL_ENABLE {{CH0 0} {CH1 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0}} \
      PS_LPD_DMA_CH_TZ {{CH0 NonSecure} {CH1 NonSecure} {CH2 NonSecure} {CH3 NonSecure} {CH4 NonSecure} {CH5 NonSecure} {CH6 NonSecure} {CH7 NonSecure}} \
      PS_LPD_DMA_ENABLE {0} \
      PS_LPD_INTERCONNECT_LOAD {90} \
      PS_MIO0 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO1 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO10 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO11 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO12 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO13 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO14 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO15 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO16 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO17 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO18 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO2 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO20 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO22 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO23 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO24 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO25 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO3 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO4 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO5 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO6 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO8 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
      PS_M_AXI_FPD_DATA_WIDTH {128} \
      PS_M_AXI_GP4_DATA_WIDTH {128} \
      PS_M_AXI_LPD_DATA_WIDTH {128} \
      PS_NOC_PS_CCI_DATA_WIDTH {128} \
      PS_NOC_PS_NCI_DATA_WIDTH {128} \
      PS_NOC_PS_PCI_DATA_WIDTH {128} \
      PS_NOC_PS_PMC_DATA_WIDTH {128} \
      PS_NUM_F2P0_INTR_INPUTS {1} \
      PS_NUM_F2P1_INTR_INPUTS {1} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_OCM_ACTIVE_BLOCKS {1} \
      PS_PCIE1_PERIPHERAL_ENABLE {0} \
      PS_PCIE2_PERIPHERAL_ENABLE {0} \
      PS_PCIE_EP_RESET1_IO {None} \
      PS_PCIE_EP_RESET2_IO {None} \
      PS_PCIE_PERIPHERAL_ENABLE {0} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PCIE_ROOT_RESET1_IO {None} \
      PS_PCIE_ROOT_RESET1_IO_DIR {output} \
      PS_PCIE_ROOT_RESET1_POLARITY {Active Low} \
      PS_PCIE_ROOT_RESET2_IO {None} \
      PS_PCIE_ROOT_RESET2_IO_DIR {output} \
      PS_PCIE_ROOT_RESET2_POLARITY {Active Low} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_PL_DONE {0} \
      PS_PL_PASS_AXPROT_VALUE {0} \
      PS_PMCPL_CLK0_BUF {1} \
      PS_PMCPL_CLK1_BUF {1} \
      PS_PMCPL_CLK2_BUF {1} \
      PS_PMCPL_CLK3_BUF {1} \
      PS_PMCPL_IRO_CLK_BUF {1} \
      PS_PMU_PERIPHERAL_ENABLE {0} \
      PS_PS_ENABLE {0} \
      PS_PS_NOC_CCI_DATA_WIDTH {128} \
      PS_PS_NOC_NCI_DATA_WIDTH {128} \
      PS_PS_NOC_PCI_DATA_WIDTH {128} \
      PS_PS_NOC_PMC_DATA_WIDTH {128} \
      PS_PS_NOC_RPU_DATA_WIDTH {128} \
      PS_R5_ACTIVE_BLOCKS {2} \
      PS_R5_LOAD {90} \
      PS_RPU_COHERENCY {0} \
      PS_SLR_TYPE {master} \
      PS_SMON_PL_PORTS_ENABLE {0} \
      PS_SPI0 {{GRP_SS0_ENABLE 0} {GRP_SS0_IO {PMC_MIO 15}} {GRP_SS1_ENABLE 0} {GRP_SS1_IO {PMC_MIO 14}} {GRP_SS2_ENABLE 0} {GRP_SS2_IO {PMC_MIO 13}} {PERIPHERAL_ENABLE 0} {PERIPHERAL_IO {PMC_MIO 12 ..\
17}}} \
      PS_SPI1 {{GRP_SS0_ENABLE 0} {GRP_SS0_IO {PS_MIO 9}} {GRP_SS1_ENABLE 0} {GRP_SS1_IO {PS_MIO 8}} {GRP_SS2_ENABLE 0} {GRP_SS2_IO {PS_MIO 7}} {PERIPHERAL_ENABLE 0} {PERIPHERAL_IO {PS_MIO 6 .. 11}}} \
      PS_S_AXI_ACE_DATA_WIDTH {128} \
      PS_S_AXI_ACP_DATA_WIDTH {128} \
      PS_S_AXI_FPD_DATA_WIDTH {128} \
      PS_S_AXI_GP2_DATA_WIDTH {128} \
      PS_S_AXI_LPD_DATA_WIDTH {128} \
      PS_TCM_ACTIVE_BLOCKS {2} \
      PS_TIE_MJTAG_TCK_TO_GND {1} \
      PS_TRACE_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 30 .. 47}}} \
      PS_TRACE_WIDTH {2Bit} \
      PS_TRISTATE_INVERTED {0} \
      PS_TTC0_CLK {{ENABLE 0} {IO {PS_MIO 6}}} \
      PS_TTC0_PERIPHERAL_ENABLE {0} \
      PS_TTC0_REF_CTRL_ACT_FREQMHZ {50} \
      PS_TTC0_REF_CTRL_FREQMHZ {50} \
      PS_TTC0_WAVEOUT {{ENABLE 0} {IO {PS_MIO 7}}} \
      PS_TTC1_CLK {{ENABLE 0} {IO {PS_MIO 12}}} \
      PS_TTC1_PERIPHERAL_ENABLE {0} \
      PS_TTC1_REF_CTRL_ACT_FREQMHZ {50} \
      PS_TTC1_REF_CTRL_FREQMHZ {50} \
      PS_TTC1_WAVEOUT {{ENABLE 0} {IO {PS_MIO 13}}} \
      PS_TTC2_CLK {{ENABLE 0} {IO {PS_MIO 2}}} \
      PS_TTC2_PERIPHERAL_ENABLE {0} \
      PS_TTC2_REF_CTRL_ACT_FREQMHZ {50} \
      PS_TTC2_REF_CTRL_FREQMHZ {50} \
      PS_TTC2_WAVEOUT {{ENABLE 0} {IO {PS_MIO 3}}} \
      PS_TTC3_CLK {{ENABLE 0} {IO {PS_MIO 16}}} \
      PS_TTC3_PERIPHERAL_ENABLE {0} \
      PS_TTC3_REF_CTRL_ACT_FREQMHZ {50} \
      PS_TTC3_REF_CTRL_FREQMHZ {50} \
      PS_TTC3_WAVEOUT {{ENABLE 0} {IO {PS_MIO 17}}} \
      PS_TTC_APB_CLK_TTC0_SEL {APB} \
      PS_TTC_APB_CLK_TTC1_SEL {APB} \
      PS_TTC_APB_CLK_TTC2_SEL {APB} \
      PS_TTC_APB_CLK_TTC3_SEL {APB} \
      PS_UART0_BAUD_RATE {115200} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_UART0_RTS_CTS {{ENABLE 0} {IO {PS_MIO 2 .. 3}}} \
      PS_UART1_BAUD_RATE {115200} \
      PS_UART1_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 4 .. 5}}} \
      PS_UART1_RTS_CTS {{ENABLE 0} {IO {PMC_MIO 6 .. 7}}} \
      PS_UNITS_MODE {Custom} \
      PS_USB3_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 13 .. 25}}} \
      PS_USB_COHERENCY {0} \
      PS_USB_ROUTE_THROUGH_FPD {0} \
      PS_USE_ACE_LITE {0} \
      PS_USE_APU_EVENT_BUS {0} \
      PS_USE_APU_INTERRUPT {0} \
      PS_USE_AXI4_EXT_USER_BITS {0} \
      PS_USE_BSCAN_USER1 {1} \
      PS_USE_BSCAN_USER2 {0} \
      PS_USE_BSCAN_USER3 {0} \
      PS_USE_BSCAN_USER4 {0} \
      PS_USE_CAPTURE {0} \
      PS_USE_CLK {0} \
      PS_USE_DEBUG_TEST {0} \
      PS_USE_DIFF_RW_CLK_S_AXI_FPD {0} \
      PS_USE_DIFF_RW_CLK_S_AXI_GP2 {0} \
      PS_USE_DIFF_RW_CLK_S_AXI_LPD {0} \
      PS_USE_ENET0_PTP {0} \
      PS_USE_ENET1_PTP {0} \
      PS_USE_FIFO_ENET0 {0} \
      PS_USE_FIFO_ENET1 {0} \
      PS_USE_FIXED_IO {0} \
      PS_USE_FPD_AXI_NOC0 {1} \
      PS_USE_FPD_AXI_NOC1 {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_FPD_CCI_NOC1 {0} \
      PS_USE_FPD_CCI_NOC2 {0} \
      PS_USE_FPD_CCI_NOC3 {0} \
      PS_USE_FTM_GPI {0} \
      PS_USE_FTM_GPO {0} \
      PS_USE_HSDP_PL {0} \
      PS_USE_MJTAG_TCK_TIE_OFF {0} \
      PS_USE_M_AXI_FPD {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_FPD_AXI0 {1} \
      PS_USE_NOC_FPD_AXI1 {0} \
      PS_USE_NOC_FPD_CCI0 {0} \
      PS_USE_NOC_FPD_CCI1 {0} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_NOC_PS_PCI_0 {0} \
      PS_USE_NOC_PS_PMC_0 {0} \
      PS_USE_NPI_CLK {0} \
      PS_USE_NPI_RST {0} \
      PS_USE_PL_FPD_AUX_REF_CLK {0} \
      PS_USE_PL_LPD_AUX_REF_CLK {0} \
      PS_USE_PMC {0} \
      PS_USE_PMCPL_CLK0 {0} \
      PS_USE_PMCPL_CLK1 {0} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      PS_USE_PMCPL_IRO_CLK {0} \
      PS_USE_PSPL_IRQ_FPD {0} \
      PS_USE_PSPL_IRQ_LPD {0} \
      PS_USE_PSPL_IRQ_PMC {0} \
      PS_USE_PS_NOC_PCI_0 {0} \
      PS_USE_PS_NOC_PCI_1 {0} \
      PS_USE_PS_NOC_PMC_0 {0} \
      PS_USE_PS_NOC_PMC_1 {0} \
      PS_USE_RPU_EVENT {0} \
      PS_USE_RPU_INTERRUPT {0} \
      PS_USE_RTC {0} \
      PS_USE_SMMU {0} \
      PS_USE_STARTUP {0} \
      PS_USE_STM {0} \
      PS_USE_S_ACP_FPD {0} \
      PS_USE_S_AXI_ACE {0} \
      PS_USE_S_AXI_FPD {0} \
      PS_USE_S_AXI_GP2 {0} \
      PS_USE_S_AXI_LPD {0} \
      PS_USE_TRACE_ATB {0} \
      PS_WDT0_REF_CTRL_ACT_FREQMHZ {100} \
      PS_WDT0_REF_CTRL_FREQMHZ {100} \
      PS_WDT0_REF_CTRL_SEL {NONE} \
      PS_WDT1_REF_CTRL_ACT_FREQMHZ {100} \
      PS_WDT1_REF_CTRL_FREQMHZ {100} \
      PS_WDT1_REF_CTRL_SEL {NONE} \
      PS_WWDT0_CLK {{ENABLE 0} {IO {PMC_MIO 0}}} \
      PS_WWDT0_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 5}}} \
      PS_WWDT1_CLK {{ENABLE 0} {IO {PMC_MIO 6}}} \
      PS_WWDT1_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 6 .. 11}}} \
      SEM_ERROR_HANDLE_OPTIONS {Detect & Correct} \
      SEM_EVENT_LOG_OPTIONS {Log & Notify} \
      SEM_MEM_BUILT_IN_SELF_TEST {0} \
      SEM_MEM_ENABLE_ALL_TEST_FEATURE {0} \
      SEM_MEM_ENABLE_SCAN_AFTER {Immediate Start} \
      SEM_MEM_GOLDEN_ECC {0} \
      SEM_MEM_GOLDEN_ECC_SW {0} \
      SEM_MEM_SCAN {0} \
      SEM_NPI_BUILT_IN_SELF_TEST {0} \
      SEM_NPI_ENABLE_ALL_TEST_FEATURE {0} \
      SEM_NPI_ENABLE_SCAN_AFTER {Immediate Start} \
      SEM_NPI_GOLDEN_CHECKSUM_SW {0} \
      SEM_NPI_SCAN {0} \
      SEM_TIME_INTERVAL_BETWEEN_SCANS {80} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_INT_VOLTAGE_MONITORING {0} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_INTERFACE_TO_USE {None} \
      SMON_INT_MEASUREMENT_ALARM_ENABLE {0} \
      SMON_INT_MEASUREMENT_AVG_ENABLE {0} \
      SMON_INT_MEASUREMENT_ENABLE {0} \
      SMON_INT_MEASUREMENT_MODE {0} \
      SMON_INT_MEASUREMENT_TH_HIGH {0} \
      SMON_INT_MEASUREMENT_TH_LOW {0} \
      SMON_MEAS0 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_103} {SUPPLY_NUM 0}} \
      SMON_MEAS1 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_104} {SUPPLY_NUM 0}} \
      SMON_MEAS10 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_206} {SUPPLY_NUM 0}} \
      SMON_MEAS100 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS101 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS102 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS103 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS104 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS105 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS106 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS107 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS108 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS109 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS11 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_103} {SUPPLY_NUM 0}} \
      SMON_MEAS110 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS111 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS112 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS113 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS114 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS115 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS116 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS117 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS118 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS119 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS12 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_104} {SUPPLY_NUM 0}} \
      SMON_MEAS120 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS121 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS122 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS123 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS124 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS125 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS126 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS127 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS128 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS129 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS13 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_105} {SUPPLY_NUM 0}} \
      SMON_MEAS130 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS131 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS132 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS133 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS134 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS135 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS136 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS137 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS138 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS139 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS14 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_106} {SUPPLY_NUM 0}} \
      SMON_MEAS140 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS141 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS142 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS143 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS144 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS145 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS146 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS147 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS148 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS149 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS15 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_200} {SUPPLY_NUM 0}} \
      SMON_MEAS150 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS151 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS152 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS153 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS154 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS155 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS156 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS157 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS158 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS159 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS16 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_201} {SUPPLY_NUM 0}} \
      SMON_MEAS160 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
      SMON_MEAS161 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
      SMON_MEAS162 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCINT}} \
      SMON_MEAS163 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX}} \
      SMON_MEAS164 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_RAM}} \
      SMON_MEAS165 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_SOC}} \
      SMON_MEAS166 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSFP}} \
      SMON_MEAS167 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSLP}} \
      SMON_MEAS168 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX_PMC}} \
      SMON_MEAS169 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PMC}} \
      SMON_MEAS17 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_202} {SUPPLY_NUM 0}} \
      SMON_MEAS170 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
      SMON_MEAS171 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
      SMON_MEAS172 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
      SMON_MEAS173 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
      SMON_MEAS174 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
      SMON_MEAS175 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
      SMON_MEAS18 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_203} {SUPPLY_NUM 0}} \
      SMON_MEAS19 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_204} {SUPPLY_NUM 0}} \
      SMON_MEAS2 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_105} {SUPPLY_NUM 0}} \
      SMON_MEAS20 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_205} {SUPPLY_NUM 0}} \
      SMON_MEAS21 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_206} {SUPPLY_NUM 0}} \
      SMON_MEAS22 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_103} {SUPPLY_NUM 0}} \
      SMON_MEAS23 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_104} {SUPPLY_NUM 0}} \
      SMON_MEAS24 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_105} {SUPPLY_NUM 0}} \
      SMON_MEAS25 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_106} {SUPPLY_NUM 0}} \
      SMON_MEAS26 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_200} {SUPPLY_NUM 0}} \
      SMON_MEAS27 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_201} {SUPPLY_NUM 0}} \
      SMON_MEAS28 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_202} {SUPPLY_NUM 0}} \
      SMON_MEAS29 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_203} {SUPPLY_NUM 0}} \
      SMON_MEAS3 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_106} {SUPPLY_NUM 0}} \
      SMON_MEAS30 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_204} {SUPPLY_NUM 0}} \
      SMON_MEAS31 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_205} {SUPPLY_NUM 0}} \
      SMON_MEAS32 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_206} {SUPPLY_NUM 0}} \
      SMON_MEAS33 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX} {SUPPLY_NUM 0}} \
      SMON_MEAS34 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX_PMC} {SUPPLY_NUM 0}} \
      SMON_MEAS35 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX_SMON} {SUPPLY_NUM 0}} \
      SMON_MEAS36 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCINT} {SUPPLY_NUM 0}} \
      SMON_MEAS37 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_306} {SUPPLY_NUM 0}} \
      SMON_MEAS38 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_406} {SUPPLY_NUM 0}} \
      SMON_MEAS39 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_500} {SUPPLY_NUM 0}} \
      SMON_MEAS4 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_200} {SUPPLY_NUM 0}} \
      SMON_MEAS40 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_501} {SUPPLY_NUM 0}} \
      SMON_MEAS41 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_502} {SUPPLY_NUM 0}} \
      SMON_MEAS42 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_503} {SUPPLY_NUM 0}} \
      SMON_MEAS43 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_700} {SUPPLY_NUM 0}} \
      SMON_MEAS44 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_701} {SUPPLY_NUM 0}} \
      SMON_MEAS45 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_702} {SUPPLY_NUM 0}} \
      SMON_MEAS46 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_703} {SUPPLY_NUM 0}} \
      SMON_MEAS47 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_704} {SUPPLY_NUM 0}} \
      SMON_MEAS48 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_705} {SUPPLY_NUM 0}} \
      SMON_MEAS49 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_706} {SUPPLY_NUM 0}} \
      SMON_MEAS5 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_201} {SUPPLY_NUM 0}} \
      SMON_MEAS50 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_707} {SUPPLY_NUM 0}} \
      SMON_MEAS51 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_708} {SUPPLY_NUM 0}} \
      SMON_MEAS52 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_709} {SUPPLY_NUM 0}} \
      SMON_MEAS53 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_710} {SUPPLY_NUM 0}} \
      SMON_MEAS54 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_711} {SUPPLY_NUM 0}} \
      SMON_MEAS55 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_BATT} {SUPPLY_NUM 0}} \
      SMON_MEAS56 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PMC} {SUPPLY_NUM 0}} \
      SMON_MEAS57 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSFP} {SUPPLY_NUM 0}} \
      SMON_MEAS58 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSLP} {SUPPLY_NUM 0}} \
      SMON_MEAS59 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_RAM} {SUPPLY_NUM 0}} \
      SMON_MEAS6 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_202} {SUPPLY_NUM 0}} \
      SMON_MEAS60 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_SOC} {SUPPLY_NUM 0}} \
      SMON_MEAS61 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 1.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {1 V unipolar}} {NAME VP_VN} {SUPPLY_NUM 0}} \
      SMON_MEAS62 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS63 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS64 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS65 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS66 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS67 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS68 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS69 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS7 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_203} {SUPPLY_NUM 0}} \
      SMON_MEAS70 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS71 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS72 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS73 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS74 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS75 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS76 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS77 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS78 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS79 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS8 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_204} {SUPPLY_NUM 0}} \
      SMON_MEAS80 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS81 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS82 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS83 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS84 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS85 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS86 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS87 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS88 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS89 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS9 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_205} {SUPPLY_NUM 0}} \
      SMON_MEAS90 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS91 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS92 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS93 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS94 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS95 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS96 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS97 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS98 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEAS99 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
      SMON_MEASUREMENT_COUNT {62} \
      SMON_MEASUREMENT_LIST {BANK_VOLTAGE:GTY_AVTT-GTY_AVTT_103,GTY_AVTT_104,GTY_AVTT_105,GTY_AVTT_106,GTY_AVTT_200,GTY_AVTT_201,GTY_AVTT_202,GTY_AVTT_203,GTY_AVTT_204,GTY_AVTT_205,GTY_AVTT_206#VCC-GTY_AVCC_103,GTY_AVCC_104,GTY_AVCC_105,GTY_AVCC_106,GTY_AVCC_200,GTY_AVCC_201,GTY_AVCC_202,GTY_AVCC_203,GTY_AVCC_204,GTY_AVCC_205,GTY_AVCC_206#VCCAUX-GTY_AVCCAUX_103,GTY_AVCCAUX_104,GTY_AVCCAUX_105,GTY_AVCCAUX_106,GTY_AVCCAUX_200,GTY_AVCCAUX_201,GTY_AVCCAUX_202,GTY_AVCCAUX_203,GTY_AVCCAUX_204,GTY_AVCCAUX_205,GTY_AVCCAUX_206#VCCO-VCCO_306,VCCO_406,VCCO_500,VCCO_501,VCCO_502,VCCO_503,VCCO_700,VCCO_701,VCCO_702,VCCO_703,VCCO_704,VCCO_705,VCCO_706,VCCO_707,VCCO_708,VCCO_709,VCCO_710,VCCO_711|DEDICATED_PAD:VP-VP_VN|SUPPLY_VOLTAGE:VCC-VCC_BATT,VCC_PMC,VCC_PSFP,VCC_PSLP,VCC_RAM,VCC_SOC#VCCAUX-VCCAUX,VCCAUX_PMC,VCCAUX_SMON#VCCINT-VCCINT}\
\
      SMON_OT {{THRESHOLD_LOWER -55} {THRESHOLD_UPPER 125}} \
      SMON_PMBUS_ADDRESS {0x0} \
      SMON_PMBUS_UNRESTRICTED {0} \
      SMON_REFERENCE_SOURCE {Internal} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
      SMON_TEMP_THRESHOLD {0} \
      SMON_USER_TEMP {{THRESHOLD_LOWER 0} {THRESHOLD_UPPER 125} {USER_ALARM_TYPE window}} \
      SMON_VAUX_CH0 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH0} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH1 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH1} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH10 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH10} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH11 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH11} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH12 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH12} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH13 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH13} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH14 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH14} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH15 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH15} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH2 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH2} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH3 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH3} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH4 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH4} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH5 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH5} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH6 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH6} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH7 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH7} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH8 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH8} {SUPPLY_NUM 0}} \
      SMON_VAUX_CH9 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 1} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH9} {SUPPLY_NUM 0}} \
      SMON_VAUX_IO_BANK {MIO_BANK0} \
      SMON_VOLTAGE_AVERAGING_SAMPLES {None} \
      SPP_PSPMC_FROM_CORE_WIDTH {12000} \
      SPP_PSPMC_TO_CORE_WIDTH {12000} \
      SUBPRESET1 {Custom} \
      USE_UART0_IN_DEVICE_BOOT {0} \
      preset {None} \
    } \
    CONFIG.PS_PMC_CONFIG_APPLIED {0} \
  ] $versal_cips_0


  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc axi_noc_0 ]
  set_property -dict [list \
    CONFIG.BLI_DESTID_PINS {} \
    CONFIG.CH0_DDR4_0_BOARD_INTERFACE {ddr4_dimm1} \
    CONFIG.CLK_NAMES {} \
    CONFIG.HBM_CHNL0_CONFIG {HBM_REORDER_EN FALSE HBM_MAINTAIN_COHERENCY TRUE HBM_Q_AGE_LIMIT 0x7f HBM_CLOSE_PAGE_REORDER FALSE HBM_LOOKAHEAD_PCH TRUE HBM_COMMAND_PARITY FALSE HBM_DQ_WR_PARITY FALSE HBM_DQ_RD_PARITY\
FALSE HBM_RD_DBI FALSE HBM_WR_DBI FALSE HBM_REFRESH_MODE ALL_BANK_REFRESH HBM_PC0_ADDRESS_MAP SID,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA3,BA2,BA1,BA0,CA5,CA4,CA3,CA2,CA1,NC,NA,NA,NA,NA\
HBM_PC1_ADDRESS_MAP SID,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA3,BA2,BA HBM_PC0_PRE_DEFINED_ADDRESS_MAP ROW_BANK_COLUMN HBM_PC1_PRE_DEFINED_ADDRESS_MAP ROW_BANK_COLUMN HBM_PC0_USER_DEFINED_ADDRESS_MAP\
NONE HBM_PC1_USER_DEFINED_ADDRESS_MAP NONE HBM_WRITE_BACK_CORRECTED_DATA TRUE HBM_REF_PERIOD_TEMP_COMP FALSE} \
    CONFIG.HBM_MEMORY_FREQ0 {900} \
    CONFIG.HBM_MEMORY_FREQ1 {900} \
    CONFIG.HBM_SIDEBAND_PINS {} \
    CONFIG.HBM_STACK0_CONFIG { } \
    CONFIG.MC1_CONFIG_NUM {config17} \
    CONFIG.MC2_CONFIG_NUM {config17} \
    CONFIG.MC3_CONFIG_NUM {config17} \
    CONFIG.MC_BOARD_INTRF_EN {true} \
    CONFIG.MC_CASLATENCY {22} \
    CONFIG.MC_CASWRITELATENCY {16} \
    CONFIG.MC_CHAN_REGION1 {DDR_CH1} \
    CONFIG.MC_DDR4_2T {Disable} \
    CONFIG.MC_EN_INTR_RESP {FALSE} \
    CONFIG.MC_F1_LPDDR4_MR1 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR11 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR13 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR2 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR22 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR3 {0x0000} \
    CONFIG.MC_F1_TRCD {13750} \
    CONFIG.MC_F1_TRCDMIN {13750} \
    CONFIG.MC_READ_BANDWIDTH {4801.921} \
    CONFIG.MC_TCCD_L {8} \
    CONFIG.MC_TCCD_L_MIN {7} \
    CONFIG.MC_TCKE {8} \
    CONFIG.MC_TCKEMIN {8} \
    CONFIG.MC_TFAW {21000} \
    CONFIG.MC_TFAWMIN {21000} \
    CONFIG.MC_TRC {45750} \
    CONFIG.MC_TRCD {13750} \
    CONFIG.MC_TRCDMIN {13750} \
    CONFIG.MC_TRCMIN {45750} \
    CONFIG.MC_TRP {13750} \
    CONFIG.MC_TRPMIN {13750} \
    CONFIG.MC_TRRD_L {8} \
    CONFIG.MC_TRRD_L_MIN {6} \
    CONFIG.MC_TXP {10} \
    CONFIG.MC_TXPMIN {10} \
    CONFIG.MC_TXPR {576} \
    CONFIG.MC_WRITE_BANDWIDTH {4801.921} \
    CONFIG.MC_XPLL_CLKOUT1_PERIOD {1250} \
    CONFIG.MC_XPLL_CLKOUT1_PHASE {268.59543817527015} \
    CONFIG.MI_INFO_PINS {} \
    CONFIG.MI_NAMES {} \
    CONFIG.MI_SIDEBAND_PINS {} \
    CONFIG.MI_USR_INTR_PINS {} \
    CONFIG.NMI_NAMES {} \
    CONFIG.NOC_RD_RATE {} \
    CONFIG.NOC_WR_RATE {} \
    CONFIG.NSI_NAMES {} \
    CONFIG.NUM_CLKS {10} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {9} \
    CONFIG.SI_DESTID_PINS {} \
    CONFIG.SI_NAMES {} \
    CONFIG.SI_SIDEBAND_PINS {} \
    CONFIG.SI_USR_INTR_PINS {} \
    CONFIG.sys_clk0_BOARD_INTERFACE {ddr4_dimm1_sma_clk} \
  ] $axi_noc_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CATEGORY {ps_nci_phy} \
 ] [get_bd_intf_pins $axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins $axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M00_AXI:0x140} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins $axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins $axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins $axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_3 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_3 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
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

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.ADVANCED_PROPERTIES {__experimental_features__ {disable_low_area_mode 1}} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_1 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_1


  # Create instance: smartconnect_2, and set properties
  set smartconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_2 ]
  set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_2


  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_ports CH0_DDR4_0_0] [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins versal_cips_0/NOC_FPD_AXI_0]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins qdma_0_support/pcie_refclk_1]
  connect_bd_intf_net -intf_net qdma_0_M_AXI_BRIDGE [get_bd_intf_pins qdma_0/M_AXI_BRIDGE] [get_bd_intf_pins smartconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net qdma_0_pcie_cfg_control_if [get_bd_intf_pins qdma_0/pcie_cfg_control_if] [get_bd_intf_pins qdma_0_support/pcie_cfg_control]
  connect_bd_intf_net -intf_net qdma_0_pcie_cfg_interrupt [get_bd_intf_pins qdma_0/pcie_cfg_interrupt] [get_bd_intf_pins qdma_0_support/pcie_cfg_interrupt]
  connect_bd_intf_net -intf_net qdma_0_pcie_cfg_mgmt_if [get_bd_intf_pins qdma_0/pcie_cfg_mgmt_if] [get_bd_intf_pins qdma_0_support/pcie_cfg_mgmt]
  connect_bd_intf_net -intf_net qdma_0_s_axis_cc [get_bd_intf_pins qdma_0/s_axis_cc] [get_bd_intf_pins qdma_0_support/s_axis_cc]
  connect_bd_intf_net -intf_net qdma_0_s_axis_rq [get_bd_intf_pins qdma_0/s_axis_rq] [get_bd_intf_pins qdma_0_support/s_axis_rq]
  connect_bd_intf_net -intf_net qdma_0_support_m_axis_cq [get_bd_intf_pins qdma_0/m_axis_cq] [get_bd_intf_pins qdma_0_support/m_axis_cq]
  connect_bd_intf_net -intf_net qdma_0_support_m_axis_rc [get_bd_intf_pins qdma_0/m_axis_rc] [get_bd_intf_pins qdma_0_support/m_axis_rc]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_cfg_fc [get_bd_intf_pins qdma_0/pcie_cfg_fc] [get_bd_intf_pins qdma_0_support/pcie_cfg_fc]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_cfg_mesg_rcvd [get_bd_intf_pins qdma_0/pcie_cfg_mesg_rcvd] [get_bd_intf_pins qdma_0_support/pcie_cfg_mesg_rcvd]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_cfg_mesg_tx [get_bd_intf_pins qdma_0/pcie_cfg_mesg_tx] [get_bd_intf_pins qdma_0_support/pcie_cfg_mesg_tx]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_cfg_status [get_bd_intf_pins qdma_0/pcie_cfg_status_if] [get_bd_intf_pins qdma_0_support/pcie_cfg_status]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_mgt_2 [get_bd_intf_ports pcie_mgt] [get_bd_intf_pins qdma_0_support/pcie_mgt_2]
  connect_bd_intf_net -intf_net qdma_0_support_pcie_transmit_fc [get_bd_intf_pins qdma_0/pcie_transmit_fc_if] [get_bd_intf_pins qdma_0_support/pcie_transmit_fc]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins qdma_0/S_AXI_LITE] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins qdma_0/S_AXI_LITE_CSR] [get_bd_intf_pins smartconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M00_AXI [get_bd_intf_pins axi_noc_0/S08_AXI] [get_bd_intf_pins smartconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_2_M00_AXI [get_bd_intf_pins smartconnect_2/M00_AXI] [get_bd_intf_pins qdma_0/S_AXI_BRIDGE]
  connect_bd_intf_net -intf_net sys_clk0_0_1 [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins axi_noc_0/sys_clk0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_AXI_NOC_1 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins axi_noc_0/S06_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins axi_noc_0/S07_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_FPD [get_bd_intf_pins smartconnect_2/S00_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_FPD]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_LPD [get_bd_intf_pins smartconnect_0/S00_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_LPD]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]

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
  connect_bd_net -net sys_reset_1  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins qdma_0_support/sys_reset] \
  [get_bd_pins qdma_0/soft_reset_n]
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

  # Create address segments
  assign_bd_address -offset 0x050000000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI_BRIDGE] [get_bd_addr_segs axi_noc_0/S08_AXI/C3_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces qdma_0/M_AXI_BRIDGE] [get_bd_addr_segs axi_noc_0/S08_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S03_AXI/C0_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S03_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S05_AXI/C1_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S05_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S06_AXI/C2_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S06_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S07_AXI/C3_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S07_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x050000000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0xA8000000 -range 0x08000000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs qdma_0/S_AXI_BRIDGE/BAR0] -force
  assign_bd_address -offset 0x000480000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs qdma_0/S_AXI_BRIDGE/BAR1] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_LPD] [get_bd_addr_segs qdma_0/S_AXI_LITE/CTL0] -force
  assign_bd_address -offset 0x90000000 -range 0x10000000 -with_name SEG_qdma_0_CTL0_1 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_LPD] [get_bd_addr_segs qdma_0/S_AXI_LITE_CSR/CTL0] -force
  assign_bd_address -offset 0x050000000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_CH1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_LOW0] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xF0800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_0]
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
  exclude_bd_addr_seg -offset 0xF0B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_cti1b]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_cti1c]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_cti1d]
  exclude_bd_addr_seg -offset 0xF0B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0xF0980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_lpd_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_pmc_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_r50_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_r51_cti]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00140000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00300000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0xF1260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFF330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -offset 0xFF340000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -offset 0xFF350000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -offset 0xFF360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -offset 0xFF370000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -offset 0xFF380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -offset 0xFF3A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ram_0]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xF11E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_analog_0]
  exclude_bd_addr_seg -offset 0xF11F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0xF12D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0xF12B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0xF11C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0xF11D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0xF1240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0xF1110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0xF1020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -offset 0xF0310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0xF2000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram]
  exclude_bd_addr_seg -offset 0xF6000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0xF1200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0xF12A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0xF1210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -offset 0xF1270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_tap]
  exclude_bd_addr_seg -offset 0xF1230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0xF12F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0xF1310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0xF1300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntrs_0]


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


