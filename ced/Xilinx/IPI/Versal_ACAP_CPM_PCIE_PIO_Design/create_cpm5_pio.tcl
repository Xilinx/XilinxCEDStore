# Create interface ports
  set PCIE1_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE1_GT_0 ]

  set gt_refclk1_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk1_0 ]

  set pcie1_cfg_control_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie5_cfg_control_rtl:1.0 pcie1_cfg_control_0 ]

  set pcie1_cfg_ext_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_ext_rtl:1.0 pcie1_cfg_ext_0 ]

  set pcie1_cfg_fc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.1 pcie1_cfg_fc_0 ]

  set pcie1_cfg_interrupt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie1_cfg_interrupt_0 ]

  set pcie1_cfg_mgmt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie1_cfg_mgmt_0 ]

  set pcie1_cfg_msg_recd_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie1_cfg_msg_recd_0 ]

  set pcie1_cfg_msg_tx_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_mesg_tx_rtl:1.0 pcie1_cfg_msg_tx_0 ]

  set pcie1_cfg_msix_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_msix_rtl:1.0 pcie1_cfg_msix_0 ]

  set pcie1_cfg_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie5_cfg_status_rtl:1.0 pcie1_cfg_status_0 ]

  set pcie1_m_axis_cq_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie1_m_axis_cq_0 ]

  set pcie1_m_axis_rc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie1_m_axis_rc_0 ]

  set pcie1_s_axis_cc_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie1_s_axis_cc_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {81} \
   ] $pcie1_s_axis_cc_0

  set pcie1_s_axis_rq_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie1_s_axis_rq_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {179} \
   ] $pcie1_s_axis_rq_0

  set pcie1_transmit_fc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie1_transmit_fc_0 ]


  # Create ports
  set cpm_cor_irq_0 [ create_bd_port -dir O -type intr cpm_cor_irq_0 ]
  set cpm_irq0_0 [ create_bd_port -dir I -type intr cpm_irq0_0 ]
  set cpm_irq1_0 [ create_bd_port -dir I -type intr cpm_irq1_0 ]
  set cpm_misc_irq_0 [ create_bd_port -dir O -type intr cpm_misc_irq_0 ]
  set cpm_uncor_irq_0 [ create_bd_port -dir O -type intr cpm_uncor_irq_0 ]
  set pcie1_user_clk_0 [ create_bd_port -dir O -type clk pcie1_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {pcie1_m_axis_cq_0:pcie1_m_axis_rc_0:pcie1_s_axis_cc_0:pcie1_s_axis_rq_0} \
 ] $pcie1_user_clk_0
  set_property CONFIG.ASSOCIATED_BUSIF.VALUE_SRC DEFAULT $pcie1_user_clk_0

  set pcie1_user_lnk_up_0 [ create_bd_port -dir O pcie1_user_lnk_up_0 ]
  set pcie1_user_reset_0 [ create_bd_port -dir O -type rst pcie1_user_reset_0 ]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [list \
    CONFIG.BOOT_MODE {Custom} \
    CONFIG.CPM_CONFIG { \
      CPM_PCIE0_MODES {None} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_CLIENT_TAG {1} \
      CPM_PCIE1_CFG_CTL_IF {1} \
      CPM_PCIE1_CFG_EXT_IF {1} \
      CPM_PCIE1_CFG_FC_IF {1} \
      CPM_PCIE1_CFG_MGMT_IF {1} \
      CPM_PCIE1_CFG_STS_IF {1} \
      CPM_PCIE1_MAX_LINK_SPEED {16.0_GT/s} \
      CPM_PCIE1_MESG_RSVD_IF {1} \
      CPM_PCIE1_MESG_TRANSMIT_IF {1} \
      CPM_PCIE1_MODES {PCIE} \
      CPM_PCIE1_MODE_SELECTION {Advanced} \
      CPM_PCIE1_MSI_X_OPTIONS {MSI-X_Internal} \
      CPM_PCIE1_PASID_IF {1} \
      CPM_PCIE1_PF0_BAR0_SIZE {256} \
      CPM_PCIE1_PF0_BAR1_ENABLED {1} \
      CPM_PCIE1_PF0_BAR1_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR2_ENABLED {1} \
      CPM_PCIE1_PF0_BAR2_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR3_ENABLED {1} \
      CPM_PCIE1_PF0_BAR3_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR4_ENABLED {1} \
      CPM_PCIE1_PF0_BAR4_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR5_ENABLED {1} \
      CPM_PCIE1_PF0_BAR5_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_CFG_DEV_ID {B03F} \
      CPM_PCIE1_PF0_DEV_CAP_EXT_TAG_EN {1} \
      CPM_PCIE1_PF0_MSIX_CAP_PBA_OFFSET {280} \
      CPM_PCIE1_PF0_MSIX_CAP_TABLE_OFFSET {200} \
      CPM_PCIE1_PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
      CPM_PCIE1_RQ_STRADDLE_SIZE {2_TLP} \
      CPM_PCIE1_TX_FC_IF {1} \
    } \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.PS_PMC_CONFIG { \
      BOOT_MODE {Custom} \
      DESIGN_MODE {1} \
      PCIE_APERTURES_DUAL_ENABLE {0} \
      PCIE_APERTURES_SINGLE_ENABLE {0} \
      PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PS_BOARD_INTERFACE {Custom} \
      PS_PCIE1_PERIPHERAL_ENABLE {0} \
      PS_PCIE2_PERIPHERAL_ENABLE {1} \
      PS_PCIE_EP_RESET1_IO {None} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] $versal_cips_0

set board_part [get_property NAME [current_board_part]]
if [regexp "vpk120_es:part0:1.3" $board_part] {
set_property CONFIG.PS_PMC_CONFIG { PS_PCIE_EP_RESET2_IO {PMC_MIO 39} PS_PCIE_RESET {{ENABLE 1}} } [get_bd_cells versal_cips_0]
} else {
set_property CONFIG.PS_PMC_CONFIG { PS_PCIE_EP_RESET2_IO {PS_MIO 19} PS_PCIE_RESET {{ENABLE 1}} } [get_bd_cells versal_cips_0] }

  # Create interface connections
  connect_bd_intf_net -intf_net gt_refclk1_0_1 [get_bd_intf_ports gt_refclk1_0] [get_bd_intf_pins versal_cips_0/gt_refclk1]
  connect_bd_intf_net -intf_net pcie1_cfg_control_0_1 [get_bd_intf_ports pcie1_cfg_control_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_control]
  connect_bd_intf_net -intf_net pcie1_cfg_interrupt_0_1 [get_bd_intf_ports pcie1_cfg_interrupt_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_interrupt]
  connect_bd_intf_net -intf_net pcie1_cfg_mgmt_0_1 [get_bd_intf_ports pcie1_cfg_mgmt_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_mgmt]
  connect_bd_intf_net -intf_net pcie1_cfg_msix_0_1 [get_bd_intf_ports pcie1_cfg_msix_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_msix]
  connect_bd_intf_net -intf_net pcie1_s_axis_cc_0_1 [get_bd_intf_ports pcie1_s_axis_cc_0] [get_bd_intf_pins versal_cips_0/pcie1_s_axis_cc]
  connect_bd_intf_net -intf_net pcie1_s_axis_rq_0_1 [get_bd_intf_ports pcie1_s_axis_rq_0] [get_bd_intf_pins versal_cips_0/pcie1_s_axis_rq]
  connect_bd_intf_net -intf_net versal_cips_0_PCIE1_GT [get_bd_intf_ports PCIE1_GT_0] [get_bd_intf_pins versal_cips_0/PCIE1_GT]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_cfg_ext [get_bd_intf_ports pcie1_cfg_ext_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_ext]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_cfg_fc [get_bd_intf_ports pcie1_cfg_fc_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_fc]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_cfg_msg_recd [get_bd_intf_ports pcie1_cfg_msg_recd_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_msg_recd]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_cfg_msg_tx [get_bd_intf_ports pcie1_cfg_msg_tx_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_msg_tx]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_cfg_status [get_bd_intf_ports pcie1_cfg_status_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_status]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_m_axis_cq [get_bd_intf_ports pcie1_m_axis_cq_0] [get_bd_intf_pins versal_cips_0/pcie1_m_axis_cq]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_m_axis_rc [get_bd_intf_ports pcie1_m_axis_rc_0] [get_bd_intf_pins versal_cips_0/pcie1_m_axis_rc]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_transmit_fc [get_bd_intf_ports pcie1_transmit_fc_0] [get_bd_intf_pins versal_cips_0/pcie1_transmit_fc]

  # Create port connections
  connect_bd_net -net cpm_irq0_0_1 [get_bd_ports cpm_irq0_0] [get_bd_pins versal_cips_0/cpm_irq0]
  connect_bd_net -net cpm_irq1_0_1 [get_bd_ports cpm_irq1_0] [get_bd_pins versal_cips_0/cpm_irq1]
  connect_bd_net -net versal_cips_0_cpm_cor_irq [get_bd_pins versal_cips_0/cpm_cor_irq] [get_bd_ports cpm_cor_irq_0]
  connect_bd_net -net versal_cips_0_cpm_misc_irq [get_bd_pins versal_cips_0/cpm_misc_irq] [get_bd_ports cpm_misc_irq_0]
  connect_bd_net -net versal_cips_0_cpm_uncor_irq [get_bd_pins versal_cips_0/cpm_uncor_irq] [get_bd_ports cpm_uncor_irq_0]
  connect_bd_net -net versal_cips_0_pcie1_user_clk [get_bd_pins versal_cips_0/pcie1_user_clk] [get_bd_ports pcie1_user_clk_0]
  connect_bd_net -net versal_cips_0_pcie1_user_lnk_up [get_bd_pins versal_cips_0/pcie1_user_lnk_up] [get_bd_ports pcie1_user_lnk_up_0]
  connect_bd_net -net versal_cips_0_pcie1_user_reset [get_bd_pins versal_cips_0/pcie1_user_reset] [get_bd_ports pcie1_user_reset_0]

  # Create address segments



  validate_bd_design
  save_bd_design



