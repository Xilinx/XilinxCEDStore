##################################################################
# DESIGN PROCs
##################################################################
# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell design_name } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
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


  # Create interface ports
  set C0_CH0_LPDDR5X [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C0_CH0_LPDDR5X ]

  set C0_CH1_LPDDR5X [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C0_CH1_LPDDR5X ]

  set C0_LPDDR5X_sys_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_LPDDR5X_sys_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $C0_LPDDR5X_sys_clk

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]

  set MMI_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 MMI_GT_0 ]


  # Create ports

  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.MMI_CONFIG(MDB5_GT) {PCIe0_x4} \
    CONFIG.MMI_CONFIG(MMI_GPU_ENABLE) {1} \
    CONFIG.MMI_CONFIG(MMI_PCIE0_PORT_TYPE) {PCIe_Endpoint_Express_Device} \
    CONFIG.MMI_CONFIG(PCIE0_LINK_SPEED) {32.0_GT/s} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR2_EN) {1} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR2_PCIE_TO_AXI_TRANSLATION) {0x0000000020000000} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR2_SCALE) {MegaBytes} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR2_SIZE) {4} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR3_EN) {1} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR3_PCIE_TO_AXI_TRANSLATION) {0x0000000030000000} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR3_SCALE) {MegaBytes} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR3_SIZE) {2} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR4_EN) {1} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR4_PCIE_TO_AXI_TRANSLATION) {0x0000000040000000} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR4_SIZE) {256} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR5_EN) {1} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR5_PCIE_TO_AXI_TRANSLATION) {0x0000000050000000} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR5_SCALE) {KiloBytes} \
    CONFIG.MMI_CONFIG(PCIE0_PF0_BAR5_SIZE) {128} \
    CONFIG.PS11_CONFIG(MDB5_GT) {PCIe0_x4} \
    CONFIG.PS11_CONFIG(MMI_GPU_ENABLE) {1} \
    CONFIG.PS11_CONFIG(MMI_PCIE0_PORT_TYPE) {PCIe_Endpoint_Express_Device} \
    CONFIG.PS11_CONFIG(PMC_EMMC) {RESET_ENABLE 1 RESET_IO PMC_MIO_51 CLK_50_SDR_ITAP_DLY 0x00 CLK_50_SDR_OTAP_DLY 0x5 CLK_50_DDR_ITAP_DLY 0x3 CLK_50_DDR_OTAP_DLY 0x5 CLK_100_SDR_OTAP_DLY 0x00 CLK_200_SDR_OTAP_DLY\
0x7 CLK_200_DDR_OTAP_DLY 0x4} \
    CONFIG.PS11_CONFIG(PMC_EMMC_DATA_TRANSFER_MODE) {8Bit} \
    CONFIG.PS11_CONFIG(PMC_EMMC_PERIPHERAL) {ENABLE 1 IO PMC_MIO_40:51 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PMC_MIO13) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 1 AUX_IO 0 USAGE Reserved OUTPUT_DATA default DIRECTION out} \
    CONFIG.PS11_CONFIG(PMC_MIO39) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PS11_CONFIG(PMC_SDIO_30) {CD_ENABLE 1 POW_ENABLE 1 WP_ENABLE 1 RESET_ENABLE 0 CD_IO PMC_MIO_37 POW_IO PMC_MIO_26 WP_IO PMC_MIO_38 RESET_IO PMC_MIO_17 CLK_50_SDR_ITAP_DLY 0x2C CLK_50_SDR_OTAP_DLY\
0x4 CLK_50_DDR_ITAP_DLY 0x36 CLK_50_DDR_OTAP_DLY 0x3 CLK_100_SDR_OTAP_DLY 0x3 CLK_200_SDR_OTAP_DLY 0x2} \
    CONFIG.PS11_CONFIG(PMC_SDIO_30AD) {CD_ENABLE 0 POW_ENABLE 0 WP_ENABLE 0 RESET_ENABLE 0 CD_IO PMC_MIO_24 POW_IO PMC_MIO_17 WP_IO PMC_MIO_25 RESET_IO PMC_MIO_17 CLK_50_SDR_ITAP_DLY 0x25 CLK_50_SDR_OTAP_DLY\
0x4 CLK_50_DDR_ITAP_DLY 0x2A CLK_50_DDR_OTAP_DLY 0x3 CLK_100_SDR_OTAP_DLY 0x3 CLK_200_SDR_OTAP_DLY 0x2} \
    CONFIG.PS11_CONFIG(PMC_SDIO_30_PERIPHERAL) {ENABLE 1 IO PMC_MIO_26:38 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
    CONFIG.PS11_CONFIG(PS_ASU_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_CAN0_PERIPHERAL) {ENABLE 0 IO PMC_MIO_8:9 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_CAN1_PERIPHERAL) {ENABLE 0 IO PMC_MIO_18:19 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_CAN2_PERIPHERAL) {ENABLE 0 IO PMC_MIO_30:31 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_CAN3_PERIPHERAL) {ENABLE 0 IO PMC_MIO_40:41 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_ENET0_MDIO) {ENABLE 1 IO PS_MIO_24:25 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_ENET0_PERIPHERAL) {ENABLE 1 IO PS_MIO_0:11 IO_TYPE MIO MODE RGMII} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI1_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI2_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI3_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI4_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI5_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI6_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_I2CSYSMON_PERIPHERAL) {ENABLE 0 IO PS_MIO_13:15} \
    CONFIG.PS11_CONFIG(PS_I3C_I2C0_PERIPHERAL) {ENABLE 1 IO PS_MIO_18:19 IO_TYPE MIO TYPE I2C} \
    CONFIG.PS11_CONFIG(PS_MIO22) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA high DIRECTION out} \
    CONFIG.PS11_CONFIG(PS_MIO23) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA high DIRECTION out} \
    CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {0} \
    CONFIG.PS11_CONFIG(PS_TTC0_CLK) {ENABLE 0 IO PS_MIO_6 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC0_WAVEOUT) {ENABLE 0 IO PS_MIO_7 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_TTC1_CLK) {ENABLE 0 IO PS_MIO_12 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_TTC1_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC1_WAVEOUT) {ENABLE 0 IO PS_MIO_13 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_TTC2_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC3_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC4_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC5_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC6_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC7_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PS_MIO_16:17 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 1 IO PS_MIO_20:21 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_USB0_PERIPHERAL) {ENABLE 1 IO PMC_MIO_13:25 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_NOC) {1} \
    CONFIG.PS11_CONFIG(PS_USE_LPD_AXI_NOC) {1} \
    CONFIG.PS11_CONFIG(SMON_INTERFACE_TO_USE) {PMBus} \
    CONFIG.PS11_CONFIG(SMON_OT) {THRESHOLD_LOWER -55 THRESHOLD_UPPER 125} \
    CONFIG.PS11_CONFIG(SMON_PMBUS_ADDRESS) {0x3A} \
    CONFIG.PS11_CONFIG(SMON_REFERENCE_SOURCE) {External} \
    CONFIG.PS11_CONFIG(SMON_USER_TEMP) {USER_ALARM_TYPE hysteresis THRESHOLD_LOWER -55 THRESHOLD_UPPER 125} \
  ] $ps_wizard_0


  # Create instance: axi_noc2_s0, and set properties
  set axi_noc2_s0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_s0 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG {DDRMC5_CONTROLLERTYPE LPDDR5_SDRAM DDRMC5_SPEED_GRADE LPDDR5X-8533 DDRMC5_DEVICE_TYPE Components DDRMC5_F0_LP5_BANK_ARCH 16B DDRMC5_F1_LP5_BANK_ARCH 16B DDRMC5_DRAM_WIDTH x16\
DDRMC5_DATA_WIDTH 16 DDRMC5_ROW_ADDR_WIDTH 16 DDRMC5_COL_ADDR_WIDTH 6 DDRMC5_BA_ADDR_WIDTH 4 DDRMC5_BG_WIDTH 0 DDRMC5_BURST_ADDR_WIDTH 4 DDRMC5_NUM_RANKS 1 DDRMC5_LATENCY_MODE x16 DDRMC5_NUM_SLOTS 1 DDRMC5_NUM_CK\
1 DDRMC5_NUM_CH 2 DDRMC5_STACK_HEIGHT 1 DDRMC5_DRAM_SIZE 16Gb DDRMC5_MEMORY_DENSITY 2GB DDRMC5_DM_EN true DDRMC5_DQS_OSCI_EN DISABLE DDRMC5_SIDE_BAND_ECC false DDRMC5_INLINE_ECC false DDRMC5_DDR5_2T DISABLE\
DDRMC5_DDR5_RDIMM_ADDR_MODE DDR DDRMC5_REFRESH_MODE NORMAL DDRMC5_REFRESH_TYPE ALL_BANK DDRMC5_FREQ_SWITCHING false DDRMC5_BACKGROUND_SCRUB false DDRMC5_OTF_SCRUB false DDRMC5_SCRUB_SIZE 1 DDRMC5_MEM_FILL\
false DDRMC5_PERIODIC_READ ENABLE DDRMC5_USER_REFRESH false DDRMC5_WL_SET A DDRMC5_WR_DBI true DDRMC5_RD_DBI true DDRMC5_AUTO_PRECHARGE true DDRMC5_CRYPTO false DDRMC5_ON_DIE_ECC false DDRMC5_DDR5_PAR_RCD_EN\
false DDRMC5_OP_TEMPERATURE LOW DDRMC5_F0_TCK 2500 DDRMC5_INPUTCLK0_PERIOD 3125 DDRMC5_F0_TFAW 15000 DDRMC5_F0_DDR5_TRP 18000 DDRMC5_F0_TRTP 7500 DDRMC5_F0_TRTP_RU 24 DDRMC5_F1_TRTP_RU 24 DDRMC5_F0_TRCD\
18000 DDRMC5_TREFI 3906000 DDRMC5_DDR5_TRFC1 0 DDRMC5_DDR5_TRFC2 0 DDRMC5_DDR5_TRFCSB 0 DDRMC5_F0_TRAS 42000 DDRMC5_F0_TZQLAT 30000 DDRMC5_F0_DDR5_TCCD_L_WR 0 DDRMC5_F0_DDR5_TCCD_L_WR_RU 32 DDRMC5_F0_TXP\
7500 DDRMC5_F0_DDR5_TPD 0 DDRMC5_DDR5_TREFSBRD 0 DDRMC5_DDR5_TRFC1_DLR 0 DDRMC5_DDR5_TRFC1_DPR 0 DDRMC5_DDR5_TRFC2_DLR 0 DDRMC5_DDR5_TRFC2_DPR 0 DDRMC5_DDR5_TRFCSB_DLR 0 DDRMC5_DDR5_TREFSBRD_SLR 0 DDRMC5_DDR5_TREFSBRD_DLR\
0 DDRMC5_F0_CL 64 DDRMC5_F0_CWL 0 DDRMC5_F0_DDR5_TRRD_L 0 DDRMC5_F0_TCCD_L 0 DDRMC5_F0_DDR5_TCCD_L_WR2 0 DDRMC5_F0_DDR5_TCCD_L_WR2_RU 16 DDRMC5_DDR5_TFAW_DLR 0 DDRMC5_F1_TCK 2500 DDRMC5_F1_TFAW 15000 DDRMC5_F1_DDR5_TRP\
18000 DDRMC5_F1_TRTP 7500 DDRMC5_F1_TRCD 18000 DDRMC5_F1_TRAS 42000 DDRMC5_F1_TZQLAT 30000 DDRMC5_F1_DDR5_TCCD_L_WR 0 DDRMC5_F1_DDR5_TCCD_L_WR_RU 32 DDRMC5_F1_TXP 7500 DDRMC5_F1_DDR5_TPD 0 DDRMC5_F1_CL\
64 DDRMC5_F1_CWL 0 DDRMC5_F1_DDR5_TRRD_L 0 DDRMC5_F1_TCCD_L 0 DDRMC5_F1_DDR5_TCCD_L_WR2 0 DDRMC5_F1_DDR5_TCCD_L_WR2_RU 16 DDRMC5_LP5_TRFCAB 280000 DDRMC5_LP5_TRFCPB 140000 DDRMC5_LP5_TPBR2PBR 90000 DDRMC5_F0_LP5_TRPAB\
21000 DDRMC5_F0_LP5_TRPPB 18000 DDRMC5_F0_LP5_TRRD 5000 DDRMC5_LP5_TPBR2ACT 7500 DDRMC5_F0_LP5_TCSPD 12500 DDRMC5_F0_RL 10 DDRMC5_F0_WL 5 DDRMC5_F1_LP5_TRPAB 21000 DDRMC5_F1_LP5_TRPPB 18000 DDRMC5_F1_LP5_TRRD\
5000 DDRMC5_F1_LP5_TCSPD 12500 DDRMC5_F1_RL 10 DDRMC5_F1_WL 5 DDRMC5_LP5_TRFMAB 280000 DDRMC5_LP5_TRFMPB 190000 DDRMC5_SYSTEM_CLOCK Differential DDRMC5_UBLAZE_BLI_INTF false DDRMC5_REF_AND_PER_CAL_INTF\
false DDRMC5_PRE_DEF_ADDR_MAP_SEL ROW_BANK_COLUMN DDRMC5_USER_DEFINED_ADDRESS_MAP None DDRMC5_ADDRESS_MAP NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA3,BA2,BA1,BA0,CA5,CA4,CA3,CA2,NC,CA1,CA0,NC,NC,NC,NC,NA\
DDRMC5_MC0_CONFIG_SEL config9 DDRMC5_MC1_CONFIG_SEL config9 DDRMC5_MC2_CONFIG_SEL config9 DDRMC5_MC3_CONFIG_SEL config9 DDRMC5_MC4_CONFIG_SEL config9 DDRMC5_MC5_CONFIG_SEL config9 DDRMC5_MC6_CONFIG_SEL\
config9 DDRMC5_MC7_CONFIG_SEL config9 DDRMC5_LOW_TRFC_DPR false DDRMC5_NUM_MC 1 DDRMC5_NUM_MCP 1 DDRMC5_MAIN_DEVICE_TYPE Components DDRMC5_INTERLEAVE_SIZE 128 DDRMC5_SILICON_REVISION NA DDRMC5_FPGA_DEVICE_TYPE\
NON_KSB DDRMC5_SELF_REFRESH DISABLE DDRMC5_LBDQ_SWAP false DDRMC5_CAL_MASK_POLL ENABLE DDRMC5_BOARD_INTRF_EN false} \
    CONFIG.DDRMC5_NUM_CH {2} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH0_LEGACY} \
    CONFIG.MC_CHAN_REGION1 {DDR_CH0_MED} \
    CONFIG.NUM_CLKS {10} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {0} \
    CONFIG.NUM_NSI {0} \
    CONFIG.NUM_SI {10} \
    CONFIG.SI_SIDEBAND_PINS {} \
  ] $axi_noc2_s0


  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_s0/S00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_s0/S01_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_s0/S02_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_s0/S03_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_s0/S04_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_s0/S05_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_s0/S06_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_s0/S07_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc2_s0/S08_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc2_s0/S09_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S08_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S09_AXI} \
 ] [get_bd_pins /axi_noc2_s0/aclk9]

  # Create interface connections
  connect_bd_intf_net -intf_net C0_LPDDR5X_sys_clk_1 [get_bd_intf_ports C0_LPDDR5X_sys_clk] [get_bd_intf_pins axi_noc2_s0/sys_clk0]
  connect_bd_intf_net -intf_net axi_noc2_s0_C0_CH0_LPDDR5 [get_bd_intf_ports C0_CH0_LPDDR5X] [get_bd_intf_pins axi_noc2_s0/C0_CH0_LPDDR5]
  connect_bd_intf_net -intf_net axi_noc2_s0_C0_CH1_LPDDR5 [get_bd_intf_ports C0_CH1_LPDDR5X] [get_bd_intf_pins axi_noc2_s0/C0_CH1_LPDDR5]
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins ps_wizard_0/gt_refclk0]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_s0/S00_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins axi_noc2_s0/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC2 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC2] [get_bd_intf_pins axi_noc2_s0/S02_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC3 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC3] [get_bd_intf_pins axi_noc2_s0/S03_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC4 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC4] [get_bd_intf_pins axi_noc2_s0/S04_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC5 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC5] [get_bd_intf_pins axi_noc2_s0/S05_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC6 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC6] [get_bd_intf_pins axi_noc2_s0/S06_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC7 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC7] [get_bd_intf_pins axi_noc2_s0/S07_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_LPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_s0/S09_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_MMI_GT [get_bd_intf_ports MMI_GT_0] [get_bd_intf_pins ps_wizard_0/MMI_GT]
  connect_bd_intf_net -intf_net ps_wizard_0_PMC_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins axi_noc2_s0/S08_AXI]

  # Create port connections
  connect_bd_net -net ps_wizard_0_fpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_s0/aclk0]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc1_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] \
  [get_bd_pins axi_noc2_s0/aclk1]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc2_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc2_clk] \
  [get_bd_pins axi_noc2_s0/aclk2]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc3_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc3_clk] \
  [get_bd_pins axi_noc2_s0/aclk3]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc4_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc4_clk] \
  [get_bd_pins axi_noc2_s0/aclk4]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc5_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc5_clk] \
  [get_bd_pins axi_noc2_s0/aclk5]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc6_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc6_clk] \
  [get_bd_pins axi_noc2_s0/aclk6]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc7_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc7_clk] \
  [get_bd_pins axi_noc2_s0/aclk7]
  connect_bd_net -net ps_wizard_0_lpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_s0/aclk9]
  connect_bd_net -net ps_wizard_0_pmc_axi_noc0_clk  [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] \
  [get_bd_pins axi_noc2_s0/aclk8]

  # Create address segments
assign_bd_address
  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()
