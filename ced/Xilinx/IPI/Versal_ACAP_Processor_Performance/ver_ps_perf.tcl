
# ########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

set design_name Versal_APU_RPU_perf

proc createDesign {design_name options} {  
proc create_root_design { parentCell design_name temp_options} {
  
puts "create_root_design"
set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]
puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"

 #Create NoC IP
 create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.0 axi_noc_0
set_property -dict [list CONFIG.NUM_SI {8} CONFIG.NUM_MI {0} CONFIG.NUM_CLKS {8}] [get_bd_cells axi_noc_0]
set_property -dict [list CONFIG.CATEGORY {ps_cci}] [get_bd_intf_pins /axi_noc_0/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci}] [get_bd_intf_pins /axi_noc_0/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci}] [get_bd_intf_pins /axi_noc_0/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci}] [get_bd_intf_pins /axi_noc_0/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci}] [get_bd_intf_pins /axi_noc_0/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci}] [get_bd_intf_pins /axi_noc_0/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_pmc}] [get_bd_intf_pins /axi_noc_0/S06_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu}] [get_bd_intf_pins /axi_noc_0/S07_AXI]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_AXI}] [get_bd_pins /axi_noc_0/aclk0]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S01_AXI}] [get_bd_pins /axi_noc_0/aclk1]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S02_AXI}] [get_bd_pins /axi_noc_0/aclk2]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S03_AXI}] [get_bd_pins /axi_noc_0/aclk3]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S04_AXI}] [get_bd_pins /axi_noc_0/aclk4]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S05_AXI}] [get_bd_pins /axi_noc_0/aclk5]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S06_AXI}] [get_bd_pins /axi_noc_0/aclk6]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S07_AXI}] [get_bd_pins /axi_noc_0/aclk7]

 ##Customize NoC IP as per memory subsystem input
  if {([lsearch $temp_options Preset.VALUE] == -1) || ([lsearch $temp_options "DDR4*"] != -1)} {

  puts "DDR4 memory subsystem is selected \n"
        set_property -dict [list CONFIG.NUM_MC {1} CONFIG.NUM_MCP {1} CONFIG.MC_BOARD_INTRF_EN {true} CONFIG.MC0_CONFIG_NUM {config17} CONFIG.MC1_CONFIG_NUM {config17} CONFIG.MC2_CONFIG_NUM {config17} CONFIG.MC3_CONFIG_NUM {config17} CONFIG.CH0_DDR4_0_BOARD_INTERFACE {ddr4_dimm1} CONFIG.sys_clk0_BOARD_INTERFACE {ddr4_dimm1_sma_clk} CONFIG.LOGO_FILE {data/noc_mc.png} CONFIG.MC_INPUT_FREQUENCY0 {200.000} CONFIG.MC_INPUTCLK0_PERIOD {5000} CONFIG.MC_MEMORY_DEVICETYPE {UDIMMs} CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} CONFIG.MC_TRCD {13750} CONFIG.MC_TRP {13750} CONFIG.MC_DDR4_2T {Disable} CONFIG.MC_CASLATENCY {22} CONFIG.MC_TRC {45750} CONFIG.MC_TRPMIN {13750} CONFIG.MC_CONFIG_NUM {config17} CONFIG.MC_F1_TRCD {13750} CONFIG.MC_F1_TRCDMIN {13750} CONFIG.MC_F1_LPDDR4_MR1 {0x000} CONFIG.MC_F1_LPDDR4_MR2 {0x000} CONFIG.MC_F1_LPDDR4_MR3 {0x000} CONFIG.MC_F1_LPDDR4_MR11 {0x000} CONFIG.MC_F1_LPDDR4_MR13 {0x000} CONFIG.MC_F1_LPDDR4_MR22 {0x000}] [get_bd_cells axi_noc_0]
	
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {ddr4_dimm1 ( DDR4 DIMM1 ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {ddr4_dimm1_sma_clk ( DDR4 DIMM1 SMA Clock ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_noc_0/sys_clk0]

  }
 
 #if {$ddr_subsystem == "LPDDR4"} {}
if { ([lsearch $temp_options "LPDDR4*"] != -1 )} {
 	puts "LPDDR4 memory subsystem is selected \n"
set_property -dict [list CONFIG.NUM_MC {1} CONFIG.NUM_MCP {1} CONFIG.MC_BOARD_INTRF_EN {true} CONFIG.MC0_FLIPPED_PINOUT {true} CONFIG.MC1_FLIPPED_PINOUT {true} CONFIG.MC0_CONFIG_NUM {config26} CONFIG.MC1_CONFIG_NUM {config26} CONFIG.MC2_CONFIG_NUM {config26} CONFIG.MC3_CONFIG_NUM {config26} CONFIG.CH0_LPDDR4_0_BOARD_INTERFACE {ch0_lpddr4_c0} CONFIG.CH1_LPDDR4_0_BOARD_INTERFACE {ch1_lpddr4_c0} CONFIG.sys_clk0_BOARD_INTERFACE {lpddr4_sma_clk1} CONFIG.LOGO_FILE {data/noc_mc.png} CONFIG.CONTROLLERTYPE {LPDDR4_SDRAM} CONFIG.MC_XPLL_CLKOUT1_PERIOD {1024} CONFIG.MC_MEMORY_TIMEPERIOD0 {512} CONFIG.MC_MEMORY_TIMEPERIOD1 {512} CONFIG.MC_IP_TIMEPERIOD0_FOR_OP {1071} CONFIG.MC_INPUT_FREQUENCY0 {200.321} CONFIG.MC_INPUTCLK0_PERIOD {4992} CONFIG.MC_MEMORY_SPEEDGRADE {LPDDR4-4267} CONFIG.MC_COMPONENT_WIDTH {x32} CONFIG.MC_MEM_DEVICE_WIDTH {x32} CONFIG.MC_COMPONENT_DENSITY {16Gb} CONFIG.MC_MEMORY_DENSITY {2GB} CONFIG.MC_MEMORY_DEVICE_DENSITY {16Gb} CONFIG.MC_TCKEMIN {15} CONFIG.MC_TCKE {15} CONFIG.MC_TFAW {30000} CONFIG.MC_TMRD {14000} CONFIG.MC_TMRD_div4 {10} CONFIG.MC_TRPRE {1.8} CONFIG.MC_TPAR_ALERT_ON {0} CONFIG.MC_TPAR_ALERT_PW_MAX {0} CONFIG.MC_TRAS {42000} CONFIG.MC_TRCD {18000} CONFIG.MC_TREFI {3904000} CONFIG.MC_TRFC {0} CONFIG.MC_TRP {0} CONFIG.MC_TOSCO {40000} CONFIG.MC_TWPRE {1.8} CONFIG.MC_TWPST {0.4} CONFIG.MC_TRRD_S {0} CONFIG.MC_TRRD_L {0} CONFIG.MC_TRTP_nCK {16} CONFIG.MC_TMOD {0} CONFIG.MC_TMPRR {0} CONFIG.MC_TWR {18000} CONFIG.MC_TWTR_S {0} CONFIG.MC_TWTR_L {0} CONFIG.MC_TXPR {0} CONFIG.MC_TXPMIN {15} CONFIG.MC_TXP {15} CONFIG.MC_TZQCS_ITVL {0} CONFIG.MC_TZQ_START_ITVL {1000000000} CONFIG.MC_TZQLAT {30000} CONFIG.MC_TZQLAT_div4 {15} CONFIG.MC_TZQLAT_nCK {59} CONFIG.MC_TMRW {10000} CONFIG.MC_TMRW_div4 {10} CONFIG.MC_TREFIPB {488000} CONFIG.MC_TRFCAB {280000} CONFIG.MC_TRFCPB {140000} CONFIG.MC_TPBR2PBR {90000} CONFIG.MC_TRPAB {21000} CONFIG.MC_TRPPB {18000} CONFIG.MC_TRRD {7500} CONFIG.MC_TWTR {10000} CONFIG.MC_NO_CHANNELS {Dual} CONFIG.MC_DATAWIDTH {32} CONFIG.MC_BG_WIDTH {0} CONFIG.MC_BA_WIDTH {3} CONFIG.MC_ECC {false} CONFIG.MC_CASLATENCY {36} CONFIG.MC_CASWRITELATENCY {18} CONFIG.MC_TCCD_L {0} CONFIG.MC_TRC {63000} CONFIG.MC_REFRESH_SPEED {1x} CONFIG.MC_PRE_DEF_ADDR_MAP_SEL {ROW_BANK_COLUMN} CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-3BA-10CA} CONFIG.MC_ADDR_BIT9 {CA7} CONFIG.MC_DQ_WIDTH {32} CONFIG.MC_DQS_WIDTH {4} CONFIG.MC_DM_WIDTH {4} CONFIG.MC_ADDR_WIDTH {6} CONFIG.MC_BURST_LENGTH {16} CONFIG.MC_CH1_LP4_CHB_ENABLE {true} CONFIG.MC_LP4_RESETN_WIDTH {1} CONFIG.MC_TFAWMIN {30000} CONFIG.MC_TMRDMIN {14000} CONFIG.MC_TRPMIN {0} CONFIG.MC_TRRD_S_MIN {0} CONFIG.MC_TWTR_S_MIN {0} CONFIG.MC_TRFCMIN {0} CONFIG.MC_TZQCAL {1000000} CONFIG.MC_TZQCAL_div4 {489} CONFIG.MC_TZQLATMIN {30000} CONFIG.MC_TRFCPBMIN {140000} CONFIG.MC_EN_ECC_SCRUBBING {false} CONFIG.MC_EN_BACKGROUND_SCRUBBING {true} CONFIG.MC_ECC_SCRUB_PERIOD {0x004C4C} CONFIG.MC_PER_RD_INTVL {0} CONFIG.MC_INIT_MEM_USING_ECC_SCRUB {false} CONFIG.MC_ODTLon {8} CONFIG.MC_TODTon_MIN {3} CONFIG.MC_CONFIG_NUM {config26} CONFIG.MC_F1_CASLATENCY {36} CONFIG.MC_F1_CASWRITELATENCY {18} CONFIG.MC_F1_TFAW {30000} CONFIG.MC_F1_TFAWMIN {30000} CONFIG.MC_F1_TRRD_S {0} CONFIG.MC_F1_TRRD_S_MIN {0} CONFIG.MC_F1_TRRD_L {0} CONFIG.MC_F1_TRRD_L_MIN {0} CONFIG.MC_F1_TWTR_S {0} CONFIG.MC_F1_TWTR_S_MIN {0} CONFIG.MC_F1_TWTR_L {0} CONFIG.MC_F1_TWTR_L_MIN {0} CONFIG.MC_F1_TCCD_L {0} CONFIG.MC_F1_TCCD_L_MIN {0} CONFIG.MC_F1_TMOD {0} CONFIG.MC_F1_TMOD_MIN {0} CONFIG.MC_F1_TMRD {14000} CONFIG.MC_F1_TMRDMIN {14000} CONFIG.MC_F1_TRAS {42000} CONFIG.MC_F1_TRASMIN {42000} CONFIG.MC_F1_TRCD {18000} CONFIG.MC_F1_TRCDMIN {18000} CONFIG.MC_F1_TRPAB {21000} CONFIG.MC_F1_TRPABMIN {21000} CONFIG.MC_F1_TRPPB {18000} CONFIG.MC_F1_TRPPBMIN {18000} CONFIG.MC_F1_TRRD {7500} CONFIG.MC_F1_TRRDMIN {7500} CONFIG.MC_F1_TWR {18000} CONFIG.MC_F1_TWRMIN {18000} CONFIG.MC_F1_TWTR {10000} CONFIG.MC_F1_TWTRMIN {10000} CONFIG.MC_F1_TZQLAT {30000} CONFIG.MC_F1_TZQLATMIN {30000} CONFIG.MC_F1_TMRW {10000} CONFIG.MC_F1_TMRWMIN {10000} CONFIG.MC_F1_LPDDR4_MR1 {0x000} CONFIG.MC_F1_LPDDR4_MR2 {0x000} CONFIG.MC_F1_LPDDR4_MR3 {0x000} CONFIG.MC_F1_LPDDR4_MR11 {0x000} CONFIG.MC_F1_LPDDR4_MR13 {0x0C0} CONFIG.MC_F1_LPDDR4_MR22 {0x000} CONFIG.MC_ECC_SCRUB_SIZE {4096} CONFIG.MC_DDR_INIT_TIMEOUT {0x00036330}] [get_bd_cells axi_noc_0]

apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "ch0_lpddr4_c0" }  [get_bd_intf_pins axi_noc_0/CH0_LPDDR4_0]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "ch1_lpddr4_c0" }  [get_bd_intf_pins axi_noc_0/CH1_LPDDR4_0]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {lpddr4_sma_clk1 ( LPDDR4 SMA Clock 1 ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_noc_0/sys_clk0]
  }
  
  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [list \
   CONFIG.CPM_CONFIG [dict create \
      CPM_PCIE0_ARI_CAP_ENABLED {0} \
      CPM_PCIE0_MODE0_FOR_POWER {NONE} \
      CPM_PCIE1_ARI_CAP_ENABLED {0} \
      CPM_PCIE1_FUNCTIONAL_MODE {None} \
      CPM_PCIE1_MODE1_FOR_POWER {NONE} \
    ] \
   CONFIG.PS_PMC_CONFIG [dict create \
      PMC_EXTERNAL_TAMPER {{IO NONE}} \
      PMC_I2CPMC_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PMC_MIO0 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO10 {{DIRECTION inout}} \
      PMC_MIO11 {{DIRECTION inout}} \
      PMC_MIO12 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO13 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO14 {{DIRECTION inout}} \
      PMC_MIO15 {{DIRECTION inout}} \
      PMC_MIO16 {{DIRECTION inout}} \
      PMC_MIO17 {{DIRECTION inout}} \
      PMC_MIO19 {{DIRECTION inout}} \
      PMC_MIO1 {{DIRECTION inout}} \
      PMC_MIO20 {{DIRECTION inout}} \
      PMC_MIO21 {{DIRECTION inout}} \
      PMC_MIO22 {{DIRECTION inout}} \
      PMC_MIO24 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO26 {{DIRECTION inout}} \
      PMC_MIO27 {{DIRECTION inout}} \
      PMC_MIO29 {{DIRECTION inout}} \
      PMC_MIO2 {{DIRECTION inout}} \
      PMC_MIO30 {{DIRECTION inout}} \
      PMC_MIO31 {{DIRECTION inout}} \
      PMC_MIO32 {{DIRECTION inout}} \
      PMC_MIO33 {{DIRECTION inout}} \
      PMC_MIO34 {{DIRECTION inout}} \
      PMC_MIO35 {{DIRECTION inout}} \
      PMC_MIO36 {{DIRECTION inout}} \
      PMC_MIO37 {{OUTPUT_DATA high} {USAGE GPIO}} \
      PMC_MIO3 {{DIRECTION inout}} \
      PMC_MIO40 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO43 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO44 {{DIRECTION inout}} \
      PMC_MIO45 {{DIRECTION inout}} \
      PMC_MIO46 {{DIRECTION inout} {SCHMITT 1}} \
      PMC_MIO47 {{DIRECTION inout}} \
      PMC_MIO48 {{USAGE GPIO}} \
      PMC_MIO49 {{DIRECTION out} {USAGE GPIO}} \
      PMC_MIO4 {{DIRECTION inout}} \
      PMC_MIO51 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO5 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO6 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO7 {{DIRECTION out} {SCHMITT 1}} \
      PMC_MIO8 {{DIRECTION inout}} \
      PMC_MIO9 {{DIRECTION inout}} \
      PMC_MIO_TREE_PERIPHERALS {QSPI#QSPI#QSPI#QSPI#QSPI#QSPI#Loopback Clk#QSPI#QSPI#QSPI#QSPI#QSPI#QSPI#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#SD1/eMMC1#SD1/eMMC1#SD1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#external_tamper###CAN 1#CAN 1#UART 0#UART 0#I2C 1#I2C 1#i2c_pmc#i2c_pmc#GPIO 1#GPIO 1#SD1#SD1/eMMC1#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 1#Enet 1#Enet 1#Enet 1#Enet 1#Enet 1#Enet 1#Enet 1#Enet 1#Enet 1#Enet 1#Enet 1#Enet 0#Enet 0} \
      PMC_MIO_TREE_SIGNALS {qspi0_clk#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]#qspi0_io[0]#qspi0_cs_b#qspi_lpbk#qspi1_cs_b#qspi1_io[0]#qspi1_io[1]#qspi1_io[2]#qspi1_io[3]#qspi1_clk#usb2phy_reset#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_tx_data[2]#ulpi_tx_data[3]#ulpi_clk#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#ulpi_dir#ulpi_stp#ulpi_nxt#clk#dir1/data[7]#detect#cmd#data[0]#data[1]#data[2]#data[3]#sel/data[4]#dir_cmd/data[5]#dir0/data[6]#ext_tamper_trig###phy_tx#phy_rx#rxd#txd#scl#sda#scl#sda#gpio_1_pin[48]#gpio_1_pin[49]#wp#buspwr/rst#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#gem0_mdc#gem0_mdio} \
      PMC_QSPI_FBCLK {{ENABLE 1}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_SD1_DATA_TRANSFER_MODE {8Bit} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {WP_ENABLE 1} {WP_IO {PMC_MIO 50}}} \
      PMC_SD1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_SD1_SPEED_MODE {high speed} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_CAN1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 40 .. 41}}} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_ENET1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 12 .. 23}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_MIO0 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO12 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO13 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO14 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO15 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO16 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO17 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO1 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO24 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO25 {{DIRECTION inout}} \
      PS_MIO2 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO3 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO4 {{DIRECTION out} {SCHMITT 1}} \
      PS_MIO5 {{DIRECTION out} {SCHMITT 1}} \
      PS_NUM_FABRIC_RESETS {0} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_UART1_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 4 .. 5}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1}} \
      PS_TTC0_PERIPHERAL_ENABLE 1\
      PS_TTC1_PERIPHERAL_ENABLE 1\
      PS_TTC2_PERIPHERAL_ENABLE 1 \
      PS_TTC3_PERIPHERAL_ENABLE 1 \
      PS_USE_M_AXI_FPD {0} \
      PS_USE_M_AXI_LPD {0} \
      PS_USE_NOC_FPD_CCI0 {0} \
      PS_USE_NOC_FPD_CCI1 {0} \
      PS_USE_PMCPL_CLK0 {0} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_AXI_NOC0 {1} \
      PS_USE_FPD_AXI_NOC1 {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_MEAS37 {{ENABLE 1}} \
      SMON_MEAS40 {{ENABLE 1}} \
      SMON_MEAS41 {{ENABLE 1}} \
      SMON_MEAS42 {{ENABLE 1}} \
      SMON_MEAS61 {{ENABLE 1}} \
      SMON_MEAS62 {{ENABLE 1}} \
      SMON_MEAS63 {{ENABLE 1}} \
      SMON_MEAS64 {{ENABLE 1}} \
      SMON_MEAS65 {{ENABLE 1}} \
      SMON_MEAS66 {{ENABLE 1}} \
      SMON_OT {{THRESHOLD_LOWER -50} {THRESHOLD_UPPER 100}} \
      SMON_USER_TEMP {{THRESHOLD_LOWER -50} {THRESHOLD_UPPER 100}} \
    ] \
  ] $versal_cips_0

##Customize NoC 
set_property -dict [list CONFIG.NUM_MCP {4}] [get_bd_cells axi_noc_0]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S05_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S06_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S07_AXI]

#Creating interface connections
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0] [get_bd_intf_pins axi_noc_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1] [get_bd_intf_pins axi_noc_0/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2] [get_bd_intf_pins axi_noc_0/S02_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3] [get_bd_intf_pins axi_noc_0/S03_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S04_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_1] [get_bd_intf_pins axi_noc_0/S05_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_0/S06_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S07_AXI]

#Create port connections
connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk] [get_bd_pins axi_noc_0/aclk0]
connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk] [get_bd_pins axi_noc_0/aclk1]
connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk] [get_bd_pins axi_noc_0/aclk2]
connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk] [get_bd_pins axi_noc_0/aclk3]
connect_bd_net [get_bd_pins versal_cips_0/fpd_axi_noc_axi0_clk] [get_bd_pins axi_noc_0/aclk4]
connect_bd_net [get_bd_pins versal_cips_0/fpd_axi_noc_axi1_clk] [get_bd_pins axi_noc_0/aclk5]
connect_bd_net [get_bd_pins versal_cips_0/lpd_axi_noc_clk] [get_bd_pins axi_noc_0/aclk7]
connect_bd_net [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk] [get_bd_pins axi_noc_0/aclk6]


  assign_bd_address

  regenerate_bd_layout
  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################
create_root_design "" $design_name $options
open_bd_design [get_bd_files $design_name]
make_wrapper -files [get_files $design_name.bd] -top -import
}

