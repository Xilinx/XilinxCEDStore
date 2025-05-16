# Updating the default options from the GUI
set aie "Include_AIE.VALUE"
set use_aie 1
if { [dict exists $options $aie] } {
	set use_aie [dict get $options $aie ]
}
puts "INFO: selected use_aie:: $use_aie"

puts "creating the root design"
#open_bd_design [get_bd_files $design_name]

# Create interface ports
  #set C0_C1_LPDDR5X_sys_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_C1_LPDDR5X_sys_clk ]
  #set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $C0_C1_LPDDR5X_sys_clk

  set C0_CH0_LPDDR5X_bank700_702 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C0_CH0_LPDDR5X_bank700_702 ]

  set C1_CH0_LPDDR5X_bank703_705 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C1_CH0_LPDDR5X_bank703_705 ]

  set C2_LPDDR5X_bank706_707 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C2_LPDDR5X_bank706_707 ]

  #set C2_C3_LPDDR5X_sys_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C2_C3_LPDDR5X_sys_clk ]
  #set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $C2_C3_LPDDR5X_sys_clk

  set C3_LPDDR5X_bank710_711 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C3_LPDDR5X_bank710_711 ]

  # set gpio_led [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_led ]

  # set gpio_pb [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_pb ]

  # set gpio_dip [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_dip ]

  set C0_CH1_LPDDR5X_bank700_702 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C0_CH1_LPDDR5X_bank700_702 ]

  set C1_CH1_LPDDR5X_bank703_705 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C1_CH1_LPDDR5X_bank703_705 ]

# Create ports

# Create instance: ps_wizard_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:* ps_wizard_0

apply_bd_automation -rule xilinx.com:bd_rule:ps_wizard -config { board_preset {Yes} boot_config {Custom} configure_noc {Add new AXI NoC} debug_config {JTAG} mc_type {None} num_mc_ddr {None} num_mc_lpddr {None} pl_clocks {None} pl_resets {None}}  [get_bd_cells ps_wizard_0]

set_property -dict [list \
  CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {100} \
  CONFIG.PS_PMC_CONFIG(PMC_MIO12) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION out} \
  CONFIG.PS_PMC_CONFIG(PMC_OSPI_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 IO PMC_MIO_0:13 MODE Single} \
  CONFIG.PS_PMC_CONFIG(PMC_SD0_30AD) {CD_ENABLE 0 POW_ENABLE 0 WP_ENABLE 0 RESET_ENABLE 0 CD_IO PMC_MIO_24 POW_IO PMC_MIO_17 WP_IO PMC_MIO_25 RESET_IO PMC_MIO_17 CLK_50_SDR_ITAP_DLY 0x00 CLK_50_SDR_OTAP_DLY 0x00 CLK_50_DDR_ITAP_DLY 0x00 CLK_50_DDR_OTAP_DLY 0x00 CLK_100_SDR_OTAP_DLY 0x00 CLK_200_SDR_OTAP_DLY 0x00} \
  CONFIG.PS_PMC_CONFIG(PMC_SD0_30AD_PERIPHERAL) {PRIMARY_ENABLE 0 SECONDARY_ENABLE 0 IO PMC_MIO_13:25 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PMC_SD0_30_PERIPHERAL) {PRIMARY_ENABLE 0 SECONDARY_ENABLE 0 IO PMC_MIO_13:25 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PMC_SD1_30AD) {CD_ENABLE 1 POW_ENABLE 1 WP_ENABLE 0 RESET_ENABLE 0 CD_IO PMC_MIO_28 POW_IO PMC_MIO_51 WP_IO PMC_MIO_1 RESET_IO PMC_MIO_12 CLK_50_SDR_ITAP_DLY 0x25 CLK_50_SDR_OTAP_DLY 0x4 CLK_50_DDR_ITAP_DLY 0x2A CLK_50_DDR_OTAP_DLY 0x3 CLK_100_SDR_OTAP_DLY 0x3 CLK_200_SDR_OTAP_DLY 0x2} \
  CONFIG.PS_PMC_CONFIG(PMC_SD1_30AD_PERIPHERAL) {PRIMARY_ENABLE 0 SECONDARY_ENABLE 1 IO PMC_MIO_26:36 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
  CONFIG.PS_PMC_CONFIG(PS_ENET0_MDIO) {ENABLE 1 IO PS_MIO_24:25 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PS_ENET0_PERIPHERAL) {ENABLE 1 IO PS_MIO_0:11 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
  CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
  CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_MASTER) {R5_0} \
  CONFIG.PS_PMC_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
  CONFIG.PS_PMC_CONFIG(PS_GEN_IPI2_MASTER) {R5_1} \
  CONFIG.PS_PMC_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
  CONFIG.PS_PMC_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
  CONFIG.PS_PMC_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
  CONFIG.PS_PMC_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
  CONFIG.PS_PMC_CONFIG(PS_I2C0_PERIPHERAL) {ENABLE 1 IO PMC_MIO_46:47 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PS_I2C1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_44:45 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PS_I2CSYSMON_PERIPHERAL) {ENABLE 0 IO_TYPE MIO IO PS_MIO_13:14} \
  CONFIG.PS_PMC_CONFIG(PS_IRQ_USAGE) {CH0 1 CH1 0 CH2 0 CH3 0 CH4 0 CH5 0 CH6 0 CH7 0 CH8 0 CH9 0 CH10 0 CH11 0 CH12 0 CH13 0 CH14 0 CH15 0} \
  CONFIG.PS_PMC_CONFIG(PS_MIO12) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION out} \
  CONFIG.PS_PMC_CONFIG(PS_MIO15) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
  CONFIG.PS_PMC_CONFIG(PS_MIO22) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION out} \
  CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
  CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
  CONFIG.PS_PMC_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
  CONFIG.PS_PMC_CONFIG(PS_TTC0_WAVEOUT) {ENABLE 1 IO PS_MIO_23 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PMC_MIO_42:43 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_38:39 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PS_USB3_PERIPHERAL) {ENABLE 1 IO PMC_MIO_13:25 IO_TYPE MIO} \
  CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC0) {1} \
  CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC1) {1} \
  CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_PL) {1} \
  CONFIG.PS_PMC_CONFIG(PS_USE_FPD_CCI_NOC) {1} \
  CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {1} \
  CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
  CONFIG.PS_PMC_CONFIG(SMON_INTERFACE_TO_USE) {I2C} \
  CONFIG.PS_PMC_CONFIG(SMON_PMBUS_ADDRESS) {0x18} \
] [get_bd_cells ps_wizard_0]

# Create instance: Master_NoC, and set properties
set Master_NoC [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 Master_NoC ]

set_property -dict [list \
  CONFIG.NUM_CLKS {8} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NMI {6} \
  CONFIG.NUM_SI {8} \
  CONFIG.SI_SIDEBAND_PINS {} \
] [get_bd_cells Master_NoC]

set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M00_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M01_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M02_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M03_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M04_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M05_INI]

#puts "INFO:: Segmented Configuration is enbaled on Master_NoC!"

set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M03_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S06_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S07_AXI]

connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC0] [get_bd_intf_pins Master_NoC/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC1] [get_bd_intf_pins Master_NoC/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC2] [get_bd_intf_pins Master_NoC/S02_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC3] [get_bd_intf_pins Master_NoC/S03_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins Master_NoC/S04_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins Master_NoC/S05_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins Master_NoC/S06_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins Master_NoC/S07_AXI]

connect_bd_net [get_bd_pins Master_NoC/aclk0] [get_bd_pins ps_wizard_0/fpd_cci_noc0_clk]
connect_bd_net [get_bd_pins Master_NoC/aclk1] [get_bd_pins ps_wizard_0/fpd_cci_noc1_clk]
connect_bd_net [get_bd_pins Master_NoC/aclk2] [get_bd_pins ps_wizard_0/fpd_cci_noc2_clk]
connect_bd_net [get_bd_pins Master_NoC/aclk3] [get_bd_pins ps_wizard_0/fpd_cci_noc3_clk]
connect_bd_net [get_bd_pins Master_NoC/aclk4] [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk]
connect_bd_net [get_bd_pins Master_NoC/aclk5] [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk]
connect_bd_net [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] [get_bd_pins Master_NoC/aclk6]
connect_bd_net [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] [get_bd_pins Master_NoC/aclk7]

# Create instance: NoC_C0_C1, and set properties
set NoC_C0_C1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 NoC_C0_C1 ]

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {c0_ch0_lpddr5_Controller} \
  CONFIG.C0_CH1_LPDDR5_BOARD_INTERFACE {c0_ch1_lpddr5_Controller} \
  CONFIG.C1_CH0_LPDDR5_BOARD_INTERFACE {c1_ch0_lpddr5_Controller} \
  CONFIG.C1_CH1_LPDDR5_BOARD_INTERFACE {c1_ch1_lpddr5_Controller} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,NC,NC,CA1,CA0,NC,NC,NC,NC,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {128} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config9} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config9} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {2GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION1 {DDR_CH0_MED} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {5} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C0_C1]

set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S01_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S02_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S03_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S04_INI]

# Create instance: NoC_C2, and set properties
set NoC_C2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 NoC_C2 ]

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {c2_lpddr5_Controller} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION0 {DDR_CH1} \
  CONFIG.NUM_MCP {2} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {2} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C2]

set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C2/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C2/S01_INI]

# Create instance: NoC_C3, and set properties
set NoC_C3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 NoC_C3 ]

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {c3_lpddr5_Controller} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION0 {DDR_CH2} \
  CONFIG.NUM_MCP {2} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {2} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C3]

set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C3/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C3/S01_INI]

# Create instance: util_ds_buf_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:* util_ds_buf_0
apply_board_connection -board_interface "lpddr5_clk0_1" -ip_intf "util_ds_buf_0/CLK_IN_D" -diagram $design_name 

# Create instance: util_ds_buf_1, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:* util_ds_buf_1
apply_board_connection -board_interface "lpddr5_clk2_3" -ip_intf "util_ds_buf_1/CLK_IN_D" -diagram $design_name 

connect_bd_net [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins NoC_C0_C1/sys_clk0] [get_bd_pins NoC_C0_C1/sys_clk1]
connect_bd_net [get_bd_pins util_ds_buf_1/IBUF_OUT] [get_bd_pins NoC_C3/sys_clk0] [get_bd_pins NoC_C2/sys_clk0]

connect_bd_intf_net [get_bd_intf_pins Master_NoC/M00_INI] [get_bd_intf_pins NoC_C0_C1/S00_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M01_INI] [get_bd_intf_pins NoC_C0_C1/S01_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M02_INI] [get_bd_intf_pins NoC_C0_C1/S02_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M03_INI] [get_bd_intf_pins NoC_C0_C1/S03_INI]

connect_bd_intf_net [get_bd_intf_ports C0_CH0_LPDDR5X_bank700_702] [get_bd_intf_pins NoC_C0_C1/C0_CH0_LPDDR5]
connect_bd_intf_net [get_bd_intf_ports C0_CH1_LPDDR5X_bank700_702] [get_bd_intf_pins NoC_C0_C1/C0_CH1_LPDDR5]
connect_bd_intf_net [get_bd_intf_ports C1_CH0_LPDDR5X_bank703_705] [get_bd_intf_pins NoC_C0_C1/C1_CH0_LPDDR5]
connect_bd_intf_net [get_bd_intf_ports C1_CH1_LPDDR5X_bank703_705] [get_bd_intf_pins NoC_C0_C1/C1_CH1_LPDDR5]

#connect_bd_intf_net [get_bd_intf_ports C0_C1_LPDDR5X_sys_clk] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
#connect_bd_intf_net [get_bd_intf_ports C2_C3_LPDDR5X_sys_clk] [get_bd_intf_pins util_ds_buf_1/CLK_IN_D]

connect_bd_intf_net [get_bd_intf_ports C2_LPDDR5X_bank706_707] [get_bd_intf_pins NoC_C2/C0_CH0_LPDDR5]
connect_bd_intf_net [get_bd_intf_ports C3_LPDDR5X_bank710_711] [get_bd_intf_pins NoC_C3/C0_CH0_LPDDR5]

# Create instance: ctrl_smc, and set properties
set ctrl_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect ctrl_smc ]
set_property -dict [list \
  CONFIG.NUM_CLKS {1} \
  CONFIG.NUM_MI {1} \
  CONFIG.NUM_SI {1} \
] $ctrl_smc

# Create instance: aggr_noc, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 aggr_noc
set_property -dict [list \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NMI {3} \
  CONFIG.NUM_NSI {0} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells aggr_noc]

set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M00_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M01_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M02_INI]
#set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M03_INI]

connect_bd_intf_net [get_bd_intf_pins aggr_noc/M00_INI] [get_bd_intf_pins NoC_C2/S00_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M01_INI] [get_bd_intf_pins NoC_C3/S00_INI]
#connect_bd_intf_net [get_bd_intf_pins aggr_noc/M02_INI] [get_bd_intf_pins NoC_C4/S00_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M02_INI] [get_bd_intf_pins NoC_C0_C1/S04_INI]

connect_bd_intf_net [get_bd_intf_pins NoC_C2/S01_INI] [get_bd_intf_pins Master_NoC/M04_INI]
connect_bd_intf_net [get_bd_intf_pins NoC_C3/S01_INI] [get_bd_intf_pins Master_NoC/M05_INI]
#connect_bd_intf_net [get_bd_intf_pins NoC_C4/S01_INI] [get_bd_intf_pins Master_NoC/M06_INI]

#connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL] [get_bd_intf_pins axi_register_slice_0/S_AXI]
#connect_bd_intf_net [get_bd_intf_pins axi_register_slice_0/M_AXI] [get_bd_intf_pins ctrl_smc/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL] [get_bd_intf_pins ctrl_smc/S00_AXI]
#set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {ps_wizard_0_FPD_AXI_PL}]
set_property HDL_ATTRIBUTE.DONT_TOUCH true [get_bd_intf_nets {ps_wizard_0_FPD_AXI_PL}]

#use_aie
if { $use_aie } {

set_property CONFIG.NUM_NMI {7} [get_bd_cells Master_NoC]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M06_INI]

set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} initial_boot {true}} M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true}} M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M03_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S05_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S07_AXI]

# Create instance: ai_engine_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:ai_engine ai_engine_0

# Create instance: ConfigNoc, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 ConfigNoc
set_property -dict [list CONFIG.MI_SIDEBAND_PINS {} CONFIG.NUM_NSI {1} CONFIG.NUM_SI {0} ] [get_bd_cells ConfigNoc]
set_property -dict [list CONFIG.CATEGORY {aie}] [get_bd_intf_pins /ConfigNoc/M00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /ConfigNoc/S00_INI]

connect_bd_intf_net [get_bd_intf_pins ConfigNoc/M00_AXI] [get_bd_intf_pins ai_engine_0/S00_AXI]
connect_bd_net [get_bd_pins ai_engine_0/s00_axi_aclk] [get_bd_pins ConfigNoc/aclk0]
connect_bd_intf_net [get_bd_intf_pins ConfigNoc/S00_INI] [get_bd_intf_pins Master_NoC/M06_INI]
}

# Create instance: axi_bram_ctrl_0, and set properties
set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]

# Create instance: axi_bram_ctrl_0_bram, and set properties
set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_0_bram ]
set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_0_bram


# # Create instance: axi_gpio_0, and set properties
# set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
# set_property -dict [list \
  # CONFIG.C_ALL_OUTPUTS {1} \
  # CONFIG.C_GPIO_WIDTH {4} \
# ] $axi_gpio_0


# # Create instance: axi_gpio_1, and set properties
# set axi_gpio_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_1 ]
# set_property -dict [list \
  # CONFIG.C_ALL_INPUTS {1} \
  # CONFIG.C_GPIO_WIDTH {2} \
# ] $axi_gpio_1

  # # Create instance: axi_gpio_2, and set properties
  # set axi_gpio_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_2 ]
  # set_property -dict [list \
    # CONFIG.C_ALL_INPUTS {1} \
    # CONFIG.C_GPIO_WIDTH {4} \
  # ] $axi_gpio_2

# Create instance: rst_clk, and set properties
set rst_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_clk ]

# Create instance: clkx5_wiz_0, and set properties
set clkx5_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clkx5_wiz_0 ]
set_property -dict [list \
  CONFIG.PRIM_SOURCE {Global_buffer} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.USE_RESET {true} \
] $clkx5_wiz_0

set_property -dict [list \
  CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
  CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
  CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
  CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
  CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
  CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
  CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {100,100.000,100.000,100.000,100.000,100.000,100.000} \
  CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
  CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
] [get_bd_cells clkx5_wiz_0]

# # Create instance: axi_vip_0, and set properties
# set axi_vip_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip axi_vip_0 ]
# set_property CONFIG.INTERFACE_MODE {SLAVE} $axi_vip_0

connect_bd_intf_net  [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
connect_bd_intf_net  [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]

connect_bd_net -net clkx5_wiz_0_clk_out1  [get_bd_pins clkx5_wiz_0/clk_out1] \
  [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] \
  [get_bd_pins ctrl_smc/aclk] \
  [get_bd_pins rst_clk/slowest_sync_clk] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins /ps_wizard_0/lpd_axi_pl_aclk]
  # [get_bd_pins axi_gpio_0/s_axi_aclk] \
  # [get_bd_pins axi_gpio_1/s_axi_aclk] \
  # [get_bd_pins axi_gpio_2/s_axi_aclk] \
  #[get_bd_pins axi_vip_0/aclk]

connect_bd_net -net rst_ps_wizard_0_99M_peripheral_aresetn  [get_bd_pins rst_clk/peripheral_aresetn] \
  [get_bd_pins ctrl_smc/aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
  # [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  # [get_bd_pins axi_gpio_1/s_axi_aresetn] \
  # [get_bd_pins axi_gpio_2/s_axi_aresetn]
  #[get_bd_pins axi_vip_0/aresetn]

connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
# connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M01_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
# connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M02_AXI] [get_bd_intf_pins axi_gpio_1/S_AXI]
# connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M03_AXI] [get_bd_intf_pins axi_gpio_2/S_AXI]
#connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M04_AXI] [get_bd_intf_pins axi_vip_0/S_AXI]
# connect_bd_intf_net [get_bd_intf_ports gpio_led] [get_bd_intf_pins axi_gpio_0/GPIO]
# connect_bd_intf_net [get_bd_intf_ports gpio_pb] [get_bd_intf_pins axi_gpio_1/GPIO]
# connect_bd_intf_net [get_bd_intf_ports gpio_dip] [get_bd_intf_pins axi_gpio_2/GPIO]

connect_bd_net [get_bd_pins clkx5_wiz_0/locked] [get_bd_pins rst_clk/dcm_locked]
connect_bd_net [get_bd_pins ps_wizard_0/pl0_ref_clk] [get_bd_pins clkx5_wiz_0/clk_in1] [get_bd_pins pl_mmi_clk_wiz/clk_in1]
connect_bd_net [get_bd_pins ps_wizard_0/pl0_resetn] [get_bd_pins clkx5_wiz_0/resetn] [get_bd_pins pl_mmi_clk_wiz/resetn]
connect_bd_net [get_bd_pins ps_wizard_0/pl0_resetn] [get_bd_pins rst_clk/ext_reset_in]


# set xdc [file join $currentDir vek385_constrs vek385_base.xdc]
# add_files -fileset constrs_1 -norecurse $xdc
# import_files -fileset constrs_1 $xdc 

assign_bd_address

# validate_bd_design
# save_bd_design

#make_wrapper -files [get_files $design_name.bd] -top -import