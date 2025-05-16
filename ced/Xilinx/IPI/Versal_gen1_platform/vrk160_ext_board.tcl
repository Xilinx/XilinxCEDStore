# ########################################################################
# Copyright (C) 2023, Advanced Micro Devices Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

 # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################
	
	# proc board_memory_config { board_selected } {
	
		# if {[regexp "vpk120" $board_selected]||[regexp "vek280" $board_selected]||[regexp "vpk180" $board_selected]} {
		
			# set default_mem "noc_lpddr4_0"
			# set additional_mem "noc_lpddr4_1"
			# set bdc_ddr0 "LPDDRNoc0"
			# set bdc_ddr1 "LPDDRNoc1"
					
		# } elseif {[regexp "vhk158" $board_selected]} {
		
			# set default_mem "noc_ddr4_0"
			# set additional_mem "noc_ddr4_1"
			# set bdc_ddr0 "DDRNoc0"
			# set bdc_ddr1 "DDRNoc1"
					
		# } else {
					
			# set default_mem "noc_ddr4"
			# set additional_mem "noc_lpddr4"
			# set bdc_ddr0 "DDRNoc0"
			# set bdc_ddr1 "LPDDRNoc1"
		# }
		
		# return [ list $default_mem $additional_mem $bdc_ddr0 $bdc_ddr1]
	# }
	
	# variable currentDir
	# set_property target_language Verilog [current_project]

#proc create_root_design {currentDir design_name clk_options irqs use_aie sgc} {

##################################################################
# MAIN FLOW
##################################################################

# By default all available memory will be used. Here user choice is disabled

set aie "Include_AIE.VALUE"
set use_aie 1
if { [dict exists $options $aie] } {
	set use_aie [dict get $options $aie ]
}
puts "INFO: selected use_aie:: $use_aie"

# 0 (no interrupts) / 15 (interrupt controller : default) / 32 (interrupt controller) / 63 (interrupt controller + cascade block)

set irqs_param "IRQS.VALUE"
set irqs 15
if { [dict exists $options $irqs_param] } {
	set irqs [dict get $options $irqs_param ]
}

# Fetching memory configurations availale on the selected board
#set board_name [get_property BOARD_NAME [current_board]]
#set mem_config [board_memory_config [get_property BOARD_NAME [current_board]]]
	
# set default_mem [lindex $mem_config 0]
# set additional_mem [lindex $mem_config 1]
# set bdc_ddr0 [lindex $mem_config 2]
# set bdc_ddr1 [lindex $mem_config 3]

# puts "INFO: Available memory types for $board_name board are :"
# puts "\t -> Default memory type : $default_mem"
# puts "\t -> Additional memory type : $additional_mem"

set use_intc_15 [set use_intc_32 [set use_cascaded_irqs [set no_irqs ""]]]

set use_intc_15 [ expr $irqs eq "15" ]
set use_intc_32 [ expr $irqs eq "32" ]
set use_cascaded_irqs [ expr $irqs eq "63" ]

set clk_options_param "Clock_Options.VALUE"
set clk_options { clk_out1 625 0 true clk_out2 100 1 false }
if { [dict exists $options $clk_options_param] } {
	set clk_options [ dict get $options $clk_options_param ]
}
	

puts "creating the root design"
open_bd_design [get_bd_files $design_name]
# set board_part [get_property NAME [current_board_part]]
# set board_name [get_property BOARD_NAME [current_board]]
#set fpga_part [get_property PART_NAME [current_board_part]]
set fpga_part [get_property PART [current_project ]]

#puts "INFO: $board_name is selected"
#puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"
puts "INFO: selected Interrupts:: $irqs"
puts "INFO: selected Clock_Options:: $clk_options"
puts "INFO: selected Include_AIE:: $use_aie"
puts "INFO: Using enhanced Versal extensible platform CED"

set use_intc_15 [set use_intc_32 [set use_cascaded_irqs [set no_irqs ""]]]
set use_intc_15 [ expr $irqs eq "15" ]
set use_intc_32 [ expr $irqs eq "32" ]
set use_cascaded_irqs [ expr $irqs eq "63" ]
set no_irqs [ expr $irqs eq "0" ]
 
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

 if {($use_intc_15)||($use_intc_32)} {
 
	# Create instance: axi_intc_0, and set properties
	set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
	set_property -dict [ list CONFIG.C_ASYNC_INTR {0xFFFFFFFF} CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_0

}

if { $use_cascaded_irqs } {
 
	# Create instance: axi_intc_cascaded_1, and set properties
	set axi_intc_cascaded_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_cascaded_1 ]
	set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_cascaded_1
  
	# Create instance: axi_intc_parent, and set properties
	set axi_intc_parent [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_parent ]
	set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_parent
	
	# Create instance: xlconcat_0, and set properties
	create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:* xlconcat_0
	set_property -dict [list CONFIG.NUM_PORTS {32} CONFIG.IN0_WIDTH {1}] [get_bd_cells xlconcat_0]
}

# Clocks options, and set properties
set clk_freqs [ list 100.000 150.000 300.000 100.000 100.000 100.000 100.000 ]
set clk_used [list true false false false false false false ]
set clk_ports [list clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 ]
set clk_driver [list BUFG BUFG BUFG BUFG BUFG BUFG BUFG ]
set default_clk_port clk_out1
set default_mbuf_port clk_out1
set default_clk_num 0
set default_mguf_num 0
set mbufgce [set mbufgce_freqs 0]

set i [set j 0]
set clocks {}

foreach { port freq id is_default } $clk_options {
	lset clk_ports $i $port
	lset clk_freqs $i $freq
	lset clk_used $i true
	
	if {($freq == 625) && ($is_default == "true") } {
	lset clk_driver $i MBUFGCE
	set mbuf_cklport ${port}_o
	set mbufgce 1
	set mbufgce_freqs $freq
	} 
	
	if { $is_default } {
		if { $mbufgce } {
		#set default_clk_port ${port}_o1
		set default_mbuf_port $port
		#set default_clk_num [expr ${i}+1]
		set default_clk_num 4
		} else {
		set default_clk_port $port
		set default_clk_num $i
		}
		#set default_clk_num $i
		}
	
	#dict append clocks clk_out$i { id $id is_default $is_default proc_sys_reset "proc_sys_reset$i" status "fixed" }
	incr i
}

if { $mbufgce } {
set num_clks [expr ${i}+3]
} else {
set num_clks $i }

# Create instance: clk_wizard_0, and set properties
set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clk_wizard_0 ]
set_property -dict [ list \
   CONFIG.CLKOUT_DRIVES [join $clk_driver ","] \
   CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
   CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
   CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
   CONFIG.CLKOUT_PORT [join $clk_ports ","] \
   CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
   CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [join $clk_freqs ","] \
   CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
   CONFIG.CLKOUT_USED [join $clk_used "," ]\
   CONFIG.PRIM_SOURCE {No_buffer} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
   CONFIG.USE_LOCKED {true} \
   CONFIG.USE_RESET {true} \
 ] $clk_wizard_0

if { $mbufgce } {

set_property CONFIG.CE_TYPE {HARDSYNC} [get_bd_cells clk_wizard_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins clk_wizard_0/${default_mbuf_port}_clr_n]
connect_bd_net [get_bd_pins clk_wizard_0/${default_mbuf_port}_ce] [get_bd_pins xlconstant_0/dout] }

for {set i 0} {$i < $num_clks} {incr i} {

# Create instance: proc_sys_reset_N, and set properties
set proc_sys_reset_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_$i ]

}

connect_bd_net -net ps_wizard_0_pl_clk0 [get_bd_pins ps_wizard_0/pl0_ref_clk] [get_bd_pins clk_wizard_0/clk_in1] [get_bd_pins pl_mmi_clk_wiz/clk_in1]
connect_bd_net -net ps_wizard_0_pl_resetn1 [get_bd_pins ps_wizard_0/pl0_resetn] [get_bd_pins clk_wizard_0/resetn] [get_bd_pins pl_mmi_clk_wiz/resetn]

for {set i 0} {$i < $num_clks} {incr i} {
	connect_bd_net -net ps_wizard_0_pl_resetn1 [get_bd_pins proc_sys_reset_$i/ext_reset_in]
}
  
# if { $mbufgce } {
# if {($mbufgce_freqs == 625) } {
	# set default_clk_port ${mbuf_cklport}2
# } else {
	# set default_clk_port ${mbuf_cklport}1
# }}

if { $mbufgce } {
	#set default_clk_port ${mbuf_cklport}2
	set default_clk_port clk_out2
}

set default_clock_net clk_wizard_0_$default_clk_port 
connect_bd_net -net $default_clock_net [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk] [get_bd_pins ctrl_smc/aclk] 
#connect_bd_net -net $default_clock_net [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] [get_bd_pins ctrl_smc/aclk] [get_bd_pins axi_register_slice_0/aclk]



if { $use_intc_15 } {

	# Using only 1 smartconnect to accomodate 15 AXI_Masters 

	set num_masters 1

	set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI $num_masters CONFIG.NUM_SI {1} ] $ctrl_smc
	

} else {

	# Adding multiple Smartconnects and dummy AXI_VIP to accomodate 32 or 63 AXI_Masters selected
	# Create instance: ctrl_smc, and set properties
	
	set num_masters [ expr "$use_cascaded_irqs ? 6 : 3" ]
	set num_kernal [ expr "$use_cascaded_irqs ? 4 : 2" ]
	set m_incr [ expr "$use_cascaded_irqs ? 2 : 1" ]
	
	set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI $num_masters CONFIG.NUM_SI {1} ] $ctrl_smc 

	for {set i 0} {$i < $num_kernal} {incr i} {
		set dummy_slave_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip dummy_slave_$i ]
		set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] [get_bd_cells dummy_slave_$i]
		set icn_ctrl_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_$i ]
		set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} ] [get_bd_cells icn_ctrl_$i]
		set m [expr $i+$m_incr]
		connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M0${m}_AXI] [get_bd_intf_pins icn_ctrl_$i/S00_AXI]
		connect_bd_intf_net [get_bd_intf_pins dummy_slave_$i/S_AXI] [get_bd_intf_pins icn_ctrl_$i/M00_AXI]
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins dummy_slave_$i/aresetn]
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins icn_ctrl_$i/aresetn]
		connect_bd_net -net $default_clock_net [get_bd_pins icn_ctrl_$i/aclk]
		connect_bd_net -net $default_clock_net [get_bd_pins dummy_slave_$i/aclk]
	} 
}
 
#connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL] [get_bd_intf_pins axi_register_slice_0/S_AXI]
#connect_bd_intf_net [get_bd_intf_pins axi_register_slice_0/M_AXI] [get_bd_intf_pins ctrl_smc/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL] [get_bd_intf_pins ctrl_smc/S00_AXI]
#set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {ps_wizard_0_FPD_AXI_PL}]
set_property HDL_ATTRIBUTE.DONT_TOUCH true [get_bd_intf_nets {ps_wizard_0_FPD_AXI_PL}]

set u 0
set p_id 0
if { $mbufgce } {
foreach clk_u $clk_used {
	if {$clk_u == "true"} {
	set port [lindex $clk_ports $p_id]
	#puts "$u before mbufg "
	if { $port == $default_mbuf_port} {
		set l 0
		for {set k 1} {$k < 5} {incr k} {
		#puts "***** ${mbuf_cklport}$k *****"
		connect_bd_net -net clk_wizard_0_${mbuf_cklport}$k [get_bd_pins clk_wizard_0/${mbuf_cklport}$k] [get_bd_pins proc_sys_reset_[expr $u+$l]/slowest_sync_clk]
		incr l
		#puts "connect_bd_net -net clk_wizard_0_${mbuf_cklport}$k [get_bd_pins clk_wizard_0/${mbuf_cklport}$k] [get_bd_pins proc_sys_reset_[expr $u+$l]/slowest_sync_clk]"
		}
	set u [expr $u+3]
	#puts "$u after mbufg in "
	} else {
	connect_bd_net -net clk_wizard_0_$port [get_bd_pins clk_wizard_0/$port] [get_bd_pins proc_sys_reset_$u/slowest_sync_clk]
	}
	incr u
	incr p_id
	} }
} else {

for {set i 0} {$i < $num_clks} {incr i} {
	set port [lindex $clk_ports $i]
	connect_bd_net -net clk_wizard_0_$port [get_bd_pins clk_wizard_0/$port] [get_bd_pins proc_sys_reset_$i/slowest_sync_clk]
} }

connect_bd_net -net clk_wizard_0_locked [get_bd_pins clk_wizard_0/locked]

for {set i 0} {$i < $num_clks} {incr i} {
	connect_bd_net -net clk_wizard_0_locked [get_bd_pins proc_sys_reset_$i/dcm_locked] 
}

#connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins proc_sys_reset_${default_clk_num}/peripheral_aresetn] [get_bd_pins ctrl_smc/aresetn] [get_bd_pins axi_register_slice_0/aresetn]
connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins proc_sys_reset_${default_clk_num}/peripheral_aresetn] [get_bd_pins ctrl_smc/aresetn]
  
if { $use_intc_15 } {
	#set_property -dict [list CONFIG.NUM_MI {4}] [get_bd_cells ctrl_smc]
	connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins ctrl_smc/M00_AXI]
	connect_bd_net -net axi_intc_0_irq [get_bd_pins ps_wizard_0/pl_ps_irq0] [get_bd_pins axi_intc_0/irq]
	connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_0/s_axi_aclk]
	connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn]
}

if { $use_intc_32 } {
	#set_property -dict [list CONFIG.NUM_MI {6}] [get_bd_cells ctrl_smc]
	connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins ctrl_smc/M00_AXI]
	connect_bd_net -net axi_intc_0_irq [get_bd_pins ps_wizard_0/pl_ps_irq0] [get_bd_pins axi_intc_0/irq]
	connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_0/s_axi_aclk]
	connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn]
}
  
if { $use_cascaded_irqs } {
	connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_cascaded_1/s_axi] [get_bd_intf_pins ctrl_smc/M00_AXI]
	connect_bd_intf_net -intf_net icn_ctrl_M01_AXI [get_bd_intf_pins axi_intc_parent/s_axi] [get_bd_intf_pins ctrl_smc/M01_AXI]
	connect_bd_net [get_bd_pins axi_intc_cascaded_1/irq] [get_bd_pins xlconcat_0/In31]
	connect_bd_net [get_bd_pins axi_intc_parent/intr] [get_bd_pins xlconcat_0/dout]
	#connect_bd_net [get_bd_pins axi_intc_cascaded_1/intr] [get_bd_pins xlconcat_1/dout]
	connect_bd_net -net axi_intc_0_irq [get_bd_pins ps_wizard_0/pl_ps_irq0] [get_bd_pins axi_intc_parent/irq]
	connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_cascaded_1/s_axi_aclk]
	connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_parent/s_axi_aclk]
	connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_cascaded_1/s_axi_aresetn]
	connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_parent/s_axi_aresetn]
}

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

assign_bd_address
set_param project.replaceDontTouchWithKeepHierarchySoft 0

if { ! $use_intc_15 } {
	group_bd_cells axi_smc_vip_hier [get_bd_cells dummy_slave_*] [get_bd_cells ctrl_smc] [get_bd_cells icn_ctrl_*]  
}

# #Creating NoC_hier
# group_bd_cells NoC_hier [get_bd_cells NoC_C2] [get_bd_cells util_ds_buf_1] [get_bd_cells NoC_C0_C1] [get_bd_cells NoC_C3_C4] [get_bd_cells Master_NoC] [get_bd_cells util_ds_buf_0]

# #Creating PL_hier
# group_bd_cells PL_hier [get_bd_cells proc_sys_reset_6] [get_bd_cells axi_bram_ctrl_0] [get_bd_cells ctrl_smc] [get_bd_cells axi_intc_parent] [get_bd_cells axi_intc_cascaded_1] [get_bd_cells axi_bram_ctrl_0_bram] [get_bd_cells clk_wizard_0] [get_bd_cells proc_sys_reset_0] [get_bd_cells axi_gpio_0] [get_bd_cells proc_sys_reset_1] [get_bd_cells axi_gpio_1] [get_bd_cells proc_sys_reset_2] [get_bd_cells proc_sys_reset_3] [get_bd_cells proc_sys_reset_4] [get_bd_cells proc_sys_reset_5] [get_bd_cells xlconcat_0] [get_bd_cells axi_smc_vip_hier] [get_bd_cells xlconstant_0] [get_bd_cells ctrl_smc] [get_bd_cells axi_intc_0]




	
#create_root_design $currentDir $design_name $clk_options $irqs $use_aie $sgc

# set mem_config [board_memory_config [get_property BOARD_NAME [current_board]]]

# set default_mem [lindex $mem_config 0]
# set additional_mem [lindex $mem_config 1]

#QoR script for vck190 production CED platforms

#set board_part [get_property NAME [current_board_part]]

open_bd_design [get_bd_files $design_name] 

puts "INFO: Block design generation completed, yet to set PFM properties"
# Create PFM attributes

puts "INFO: Creating extensible_platform for $board_name"
set pfmName "xilinx.com:${board_name}:versal_embedded_Common_platform_base:1.0"
#set pfmName "xilinx.com:VEK385:versal_gen2_platform_base:1.0"
set_property PFM_NAME $pfmName [get_files [current_bd_design].bd]
	
if { $irqs eq "15" } {
	set_property PFM.IRQ {intr {id 0 range 15}}  [get_bd_cells -hierarchical axi_intc_0]

	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M02_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M03_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M04_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M05_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M06_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M07_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M08_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M09_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M10_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M11_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M12_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M13_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M14_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"} M15_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "true"}} [get_bd_cells /ctrl_smc]
}


if { $irqs eq "32" } {

	set_property PFM.IRQ {intr {id 0 range 31}}  [get_bd_cells -hierarchical axi_intc_0]
	
	set_property PFM.AXI_PORT {M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} } [get_bd_cells -hierarchical ctrl_smc]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells -hierarchical icn_ctrl_0]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells -hierarchical icn_ctrl_1]
}
	
if { $irqs eq "63" } {

	set_property PFM.IRQ {intr {id 0 range 32}}  [get_bd_cells -hierarchical axi_intc_cascaded_1]
	
	set_property PFM.IRQ {In0 {id 32} In1 {id 33} In2 {id 34} In3 {id 35} In4 {id 36} In5 {id 37} In6 {id 38} In7 {id 39} In8 {id 40} \
	In9 {id 41} In10 {id 42} In11 {id 43} In12 {id 44} In13 {id 45} In14 {id 46} In15 {id 47} In16 {id 48} In17 {id 49} In18 {id 50} \
	In19 {id 51} In20 {id 52} In21 {id 53} In22 {id 54} In23 {id 55} In24 {id 56} In25 {id 57} In26 {id 58} In27 {id 59} In28 {id 60} \
	In29 {id 61} In30 {id 62} } [get_bd_cells -hierarchical xlconcat_0]
	
	set_property PFM.AXI_PORT {M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells -hierarchical ctrl_smc]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells -hierarchical icn_ctrl_0]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells -hierarchical icn_ctrl_1]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells -hierarchical icn_ctrl_2]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells -hierarchical icn_ctrl_3]

}
	
if { $use_aie } {
set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S01_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S02_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S03_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S04_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S05_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S06_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S07_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S08_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S09_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S10_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S11_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S12_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S13_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S14_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S15_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S16_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S17_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S18_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S19_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S20_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"} S21_AXI {memport "S_AXI_NOC" sptag "S_AXI_AIE" auto "false" memory "ai_engine_0 AIE_ARRAY_0" is_range "true"}} [get_bd_cells -hierarchical ConfigNoc] }

set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S01_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S02_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S03_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S04_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S05_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S06_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S07_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S08_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S09_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S10_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S11_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S12_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S13_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S14_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S15_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S16_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S17_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S18_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S19_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S20_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"} S21_AXI {memport "S_AXI_NOC" sptag "LPDDR01" memory "" is_range "true"}} [get_bd_cells /NoC_C0_C1]
	
set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S01_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S02_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S03_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S04_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S05_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S06_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S07_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S08_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S09_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S10_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S11_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S12_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S13_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S14_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S15_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S16_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S17_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S18_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S19_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S20_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"} S21_AXI {memport "S_AXI_NOC" sptag "LPDDR2" memory "" is_range "true"}} [get_bd_cells /NoC_C2]

set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S01_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S02_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S03_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S04_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S05_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S06_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S07_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S08_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S09_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S10_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S11_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S12_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S13_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S14_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S15_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S16_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S17_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S18_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S19_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S20_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"} S21_AXI {memport "S_AXI_NOC" sptag "LPDDR3" memory "" is_range "true"}} [get_bd_cells /NoC_C3]

set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S01_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S02_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S03_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S04_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S05_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S06_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S07_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S08_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S09_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S10_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S11_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S12_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S13_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S14_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S15_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S16_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S17_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S18_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S19_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S20_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"} S21_AXI {memport "S_AXI_NOC" sptag "LPDDR" memory "LPDDR" is_range "true"}} [get_bd_cells /aggr_noc]

set clocks {}
set i [set k 0]
set portl [get_property CONFIG.CLKOUT_PORT [get_ips *clk_wizard*]]
set driver [get_property CONFIG.CLKOUT_DRIVES [get_ips *clk_wizard*]]
set clk_used [get_property CONFIG.CLKOUT_USED [get_ips *clk_wizard*]]
set new_prtl [split $portl ","]
set new_d [split $driver ","]
set clk_u [split $clk_used ","]
#set freql [get_property CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [get_ips *clk_wizard*]]
set is_default false
set id_c [llength [lsearch -all $clk_u true]]
#set id_n [expr 	$id_c-1]


foreach { port freq id is_default} $clk_options {

	set clk_enb [lindex $clk_u $k]
	if { $clk_enb == "true"} {

		if {[regexp "MBUFGCE" $driver]} {
			
			if {($freq == 625) && ($is_default == "true" ) } {
			
			set is_default false
			set m_prt ${port}_o1
			dict append clocks ${m_prt} "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed_non_ref\""
		
			incr i
			for {set j 2} {$j < 5} {incr j} {
			set m_prt ${port}_o${j}
			if {$m_prt == "${port}_o2"} {
			set is_default true }
			dict append clocks ${m_prt} "id \"$id_c\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed_non_ref\""
			
			set is_default false
			incr id_c
			incr i
			}} else {
			
			dict append clocks ${port} "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed\""
			
			incr i
		}
	 } else {
		
		dict append clocks $port "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed\""
		
		incr i
	} 
	incr k 
	} }

set_property SELECTED_SIM_MODEL tlm [get_bd_cells /ps_wizard_0]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells -hierarchical Master_NoC]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells -hierarchical NoC_C0_C1]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells -hierarchical NoC_C3]
#set_property SELECTED_SIM_MODEL tlm [get_bd_cells -hierarchical NoC_C4]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells -hierarchical NoC_C2]
set_property preferred_sim_model tlm [current_project]
set_property PFM.CLOCK $clocks [get_bd_cells -hierarchical clk_wizard_0]
#puts "clocks :: $clocks  PFM properties"

#Platform Level Properties
set_property platform.default_output_type "sd_card" [current_project]
set_property platform.design_intent.embedded "true" [current_project]
set_property platform.num_compute_units $irqs [current_project]
set_property platform.design_intent.server_managed "false" [current_project]
set_property platform.design_intent.external_host "false" [current_project]
set_property platform.design_intent.datacenter "false" [current_project]
set_property platform.uses_pr  "false" [current_project]
set_property platform.extensible true [current_project]


# set_property platform.emu.dr_bd_inst_path /tb/DUT/${design_name}_wrapper_i/${design_name}_i [current_project]

#setting Platform level param to have PDI in hw xsa
#set_param platform.forceEnablePreSynthPDI true

puts "INFO: Platform creation completed!"


# Add USER_COMMENTS on $design_name
#set_property USER_COMMENTS.comment0 "An Example Versal Extensible Embedded Platform" [get_bd_designs $design_name]

if { $irqs eq "15" } {

	if { $use_aie } {
		
		set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
		\t Note:
		\t --> Board preset applied to PS_WIZARD and memory controller settings
		\t --> AI Engine control path is connected to PS_WIZARD
		\t --> V++ will connect AI Engine data path automatically
		\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
		\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/versal_gen2_platform/README.md}  [current_bd_design]
	} else {
		
		set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
		\t Note:
		\t --> Board preset applied to PS_WIZARD and memory controller settings
		\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
		\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/versal_gen2_platform/README.md}  [current_bd_design] 
	}

} else {

	if { $use_aie } {
		
		set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
		\t Note:
		\t --> Board preset applied to PS_WIZARD and memory controller settings
		\t --> AI Engine control path is connected to PS_WIZARD
		\t --> V++ will connect AI Engine data path automatically
		\t --> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
		\t \t \t \t \t \t \t Hence VIPs are there to have at least one slave on a smart connect
		\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
		\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/versal_gen2_platform/README.md}  [current_bd_design]
	} else {
		
		set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
		\t Note:
		\t --> Board preset applied to PS_WIZARD and memory controller settings
		\t --> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
		\t \t \t \t \t \t \t Hence VIPs are there to have at least one slave on a smart connect
		\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
		\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/versal_gen2_platform/README.md}  [current_bd_design] 
	}
}

# Perform GUI Layout

if { $irqs eq "15" } {

	if { $use_aie } {
	 
	   regenerate_bd_layout -layout_string {
		   "ActiveEmotionalView":"Default View",
		   "comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
			\t Note:
			\t --> Board preset applied to PS_WIZARD and memory controller
			\t --> AI Engine control path is connected to PS_WIZARD
			\t --> V++ will connect AI Engine data path automatically
			\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
			\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/versal_gen2_platform/README.md",
		   "commentid":"comment_0|",
		   "font_comment_0":"14",
		   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
			#  -string -flagsOSRD
			preplace cgraphic comment_0 place right -1750 -200 textcolor 4 linecolor 3
			",
		   "linktoobj_comment_0":"",
		   "linktotype_comment_0":"bd_design" }
	 
	 } else {
	  regenerate_bd_layout -layout_string {
		   "ActiveEmotionalView":"Default View",
		   "comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
			\t Note:
			\t --> Board preset applied to PS_WIZARD and memory controller
			\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
			\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/versal_gen2_platform/README.md",
		   "commentid":"comment_0|",
		   "font_comment_0":"14",
		   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
			#  -string -flagsOSRD
			preplace cgraphic comment_0 place right -1750 -185 textcolor 4 linecolor 3
			",
		   "linktoobj_comment_0":"",
		   "linktotype_comment_0":"bd_design" }
	}
	
} else {

	if { $use_aie } {
 	   regenerate_bd_layout -layout_string {
		   "ActiveEmotionalView":"Default View",
		   "comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
			\t Note:
			\t --> Board preset applied to PS_WIZARD and memory controller
			\t --> AI Engine control path is connected to PS_WIZARD
			\t --> V++ will connect AI Engine data path automatically
			\t --> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
			\t \t \t \t \t \t \t Hence VIPs are there to have at least one slave on a smart connect
			\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
			\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/versal_gen2_platform/README.md",
		   "commentid":"comment_0|",
		   "font_comment_0":"14",
		   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
			#  -string -flagsOSRD
			preplace cgraphic comment_0 place right -1750 -200 textcolor 4 linecolor 3
			",
		   "linktoobj_comment_0":"",
		   "linktotype_comment_0":"bd_design" }
	 
	 } else {
	  regenerate_bd_layout -layout_string {
		   "ActiveEmotionalView":"Default View",
		   "comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
			\tNote:
			\t --> Board preset applied to PS_WIZARD and memory controller.
			\t --> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
			\t \t \t \t \t \t \t Hence VIPs are there to have at least one slave on a smart connect
			\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
			\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/versal_gen2_platform/README.md",
		   "commentid":"comment_0|",
		   "font_comment_0":"14",
		   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
			#  -string -flagsOSRD
			preplace cgraphic comment_0 place right -1750 -185 textcolor 4 linecolor 3
			",
		   "linktoobj_comment_0":"",
		   "linktotype_comment_0":"bd_design" }
	}
}



open_bd_design [get_bd_files $design_name]
# validate_bd_design
# #make_wrapper -files [get_files $design_name.bd] -top -import -quiet
# save_bd_design
# set tb tb.v
# set TB_file [file join $currentDir test_bench tb.v] }
# set_property SOURCE_SET sources_1 [get_filesets sim_1]
# import_files -fileset  sim_1 -norecurse -flat $TB_file 
# set_property top tb [get_filesets sim_1]
# update_compile_order -fileset sim_1

# set infile [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports $tb]]
# set contents [read $infile]
# close $infile
# set contents [string map [list "ext_platform" "$design_name"] $contents]

# set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports $tb] w]
# puts -nonewline $outfile $contents
# close $outfile

# update_compile_order -fileset sim_1

# set xdc [file join $currentDir vek385_constrs vek385_ext.xdc]
# add_files -fileset constrs_1 -norecurse $xdc
# import_files -fileset constrs_1 $xdc 

#update_compile_order -fileset sources_1
#validate_bd_design
#regenerate_bd_layout

puts "INFO: End of create_root_design"
