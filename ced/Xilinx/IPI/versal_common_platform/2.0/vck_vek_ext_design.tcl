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

proc board_memory_config { board_selected } {

	if {[regexp "vpk120" $board_selected]||[regexp "vek280" $board_selected]||[regexp "vpk180" $board_selected]} {
	
		set default_mem "noc_lpddr0"
		set additional_mem1 "noc_lpddr1"
		set additional_mem2 "noc_lpddr2"
		set bdc_ddr0 "LPDDRNoc0"
		set bdc_ddr1 "LPDDRNoc1"
				
	} elseif {[regexp "vhk158" $board_selected]} {
	
		set default_mem "noc_ddr0"
		set additional_mem1 "noc_ddr1"
		set additional_mem2 "noc_ddr2"
		set bdc_ddr0 "DDRNoc0"
		set bdc_ddr1 "DDRNoc1"
				
	} else {
				
		set default_mem "noc_ddr"
		set additional_mem1 "noc_lpddr0"
		set additional_mem2 "noc_lpddr1"
		set bdc_ddr0 "DDRNoc0"
		set bdc_ddr1 "LPDDRNoc1"
	}
	
return [ list $default_mem $additional_mem1 $additional_mem2 $bdc_ddr0 $bdc_ddr1]
}

proc create_root_design {currentDir design_name bufg_clk mbufgce_clk use_aie} {

set board_name [get_property BOARD_NAME [current_board]]

# Fetching memory configurations availale on the selected board
set mem_config [board_memory_config [get_property BOARD_NAME [current_board]]]

set default_mem [lindex $mem_config 0]
set additional_mem1 [lindex $mem_config 1]
set additional_mem2 [lindex $mem_config 2]
set bdc_ddr0 [lindex $mem_config 3]
set bdc_ddr1 [lindex $mem_config 4]

puts "INFO: Available memory types for $board_name board are :"
puts "\t -> Default memory type : $default_mem"
puts "\t -> Additional memory type : $additional_mem1 and additional_mem2"

# Create instance: CIPS_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:* CIPS_0

apply_board_connection -board_interface "ps_pmc_fixed_io" -ip_intf "CIPS_0/FIXED_IO" -diagram $design_name

set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom DDR_MEMORY_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 99.999992 PMC_USE_PMC_NOC_AXI0 1 PS_IRQ_USAGE {{CH0 1} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} PS_TTC0_PERIPHERAL_ENABLE {1} PS_TTC1_PERIPHERAL_ENABLE {1} PS_TTC2_PERIPHERAL_ENABLE {1} PS_TTC3_PERIPHERAL_ENABLE {1} PS_NUM_FABRIC_RESETS 1 PS_PL_CONNECTIVITY_MODE Custom PS_USE_FPD_AXI_NOC0 1 PS_USE_FPD_AXI_NOC1 1 PS_USE_FPD_CCI_NOC 1 PS_USE_M_AXI_FPD 1 PS_USE_NOC_LPD_AXI0 1 PS_USE_PMCPL_CLK0 1 } CONFIG.CLOCK_MODE {Custom} CONFIG.DDR_MEMORY_MODE {Custom} CONFIG.PS_PL_CONNECTIVITY_MODE {Custom}] [get_bd_cells CIPS_0]

set_property -dict [list CONFIG.PS_PMC_CONFIG {PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI0_MASTER A72 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI1_MASTER R5_0 PS_GEN_IPI2_ENABLE 1 PS_GEN_IPI2_MASTER R5_1 PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI3_MASTER A72 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI4_MASTER A72 PS_GEN_IPI5_ENABLE 1 PS_GEN_IPI5_MASTER A72 PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI6_MASTER A72} ] [get_bd_cells CIPS_0]

# Create instance: Master_NoC, and set properties
set Master_NoC [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc Master_NoC ]
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

set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M03_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S06_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S07_AXI]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* $default_mem

if {[regexp "vpk120" $board_name]||[regexp "vek280" $board_name]} {

	apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "$default_mem/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "$default_mem/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "$default_mem/sys_clk0" -diagram $design_name
	
} elseif {[regexp "vpk180" $board_name]} {

	apply_board_connection -board_interface "ch0_lpddr4_trip3" -ip_intf "/$default_mem/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip3" -ip_intf "/$default_mem/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk3" -ip_intf "/$default_mem/sys_clk0" -diagram $design_name
	
} elseif {[regexp "vhk158" $board_name]} {

	apply_board_connection -board_interface "ddr4_dimm0" -ip_intf "$default_mem/CH0_DDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ddr4_dimm0_sma_clk" -ip_intf "$default_mem/sys_clk0" -diagram $design_name 

} else {

	apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "$default_mem/CH0_DDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "$default_mem/sys_clk0" -diagram $design_name 

}

set_property -dict [list CONFIG.MC_CHAN_REGION1 {DDR_LOW1} CONFIG.NUM_MCP {4} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {5} CONFIG.NUM_SI {0} ] [get_bd_cells $default_mem]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$default_mem/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$default_mem/S01_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$default_mem/S02_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$default_mem/S03_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$default_mem/S04_INI]

if { [regexp "noc_lpddr0" $default_mem] } {
	set_property -dict [list \
	CONFIG.MC_CHANNEL_INTERLEAVING {true} \
	CONFIG.MC_CH_INTERLEAVING_SIZE {4K_Bytes} \
	] [get_bd_cells $default_mem]
}

connect_bd_intf_net [get_bd_intf_pins Master_NoC/M00_INI] [get_bd_intf_pins $default_mem/S00_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M01_INI] [get_bd_intf_pins $default_mem/S01_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M02_INI] [get_bd_intf_pins $default_mem/S02_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M03_INI] [get_bd_intf_pins $default_mem/S03_INI]

connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_0] [get_bd_intf_pins Master_NoC/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_1] [get_bd_intf_pins Master_NoC/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_2] [get_bd_intf_pins Master_NoC/S02_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_3] [get_bd_intf_pins Master_NoC/S03_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_0] [get_bd_intf_pins Master_NoC/S04_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_1] [get_bd_intf_pins Master_NoC/S05_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/LPD_AXI_NOC_0] [get_bd_intf_pins Master_NoC/S06_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/PMC_NOC_AXI_0] [get_bd_intf_pins Master_NoC/S07_AXI]
connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi0_clk] [get_bd_pins Master_NoC/aclk0]
connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi1_clk] [get_bd_pins Master_NoC/aclk1]
connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi2_clk] [get_bd_pins Master_NoC/aclk2]
connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi3_clk] [get_bd_pins Master_NoC/aclk3]
connect_bd_net [get_bd_pins CIPS_0/fpd_axi_noc_axi0_clk] [get_bd_pins Master_NoC/aclk4]
connect_bd_net [get_bd_pins CIPS_0/fpd_axi_noc_axi1_clk] [get_bd_pins Master_NoC/aclk5]
connect_bd_net [get_bd_pins CIPS_0/lpd_axi_noc_clk] 	 [get_bd_pins Master_NoC/aclk6]
connect_bd_net [get_bd_pins CIPS_0/pmc_axi_noc_axi0_clk] [get_bd_pins Master_NoC/aclk7]

if { $use_aie } {

set_property CONFIG.NUM_NMI {7} [get_bd_cells Master_NoC]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M06_INI]

set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} initial_boot {true}} M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true}} M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M03_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu}] [get_bd_intf_pins /Master_NoC/S06_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}} M04_INI {read_bw {500} write_bw {500} initial_boot {true}} M05_INI {read_bw {500} write_bw {500} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /Master_NoC/S07_AXI]

# Create instance: ai_engine_0, and set properties	
create_bd_cell -type ip -vlnv xilinx.com:ip:ai_engine:* ai_engine_0

# Create instance: ConfigNoc, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* ConfigNoc

set_property -dict [list CONFIG.MI_SIDEBAND_PINS {} CONFIG.NUM_NSI {1} CONFIG.NUM_SI {0} ] [get_bd_cells ConfigNoc]
set_property -dict [list CONFIG.CATEGORY {aie}] [get_bd_intf_pins /ConfigNoc/M00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /ConfigNoc/S00_INI]

connect_bd_intf_net [get_bd_intf_pins ConfigNoc/M00_AXI] [get_bd_intf_pins ai_engine_0/S00_AXI]
connect_bd_net [get_bd_pins ConfigNoc/aclk0] [get_bd_pins ai_engine_0/s00_axi_aclk]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M06_INI] [get_bd_intf_pins ConfigNoc/S00_INI]
}

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* $additional_mem1
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* $additional_mem2

if {[regexp "vpk120" $board_name]||[regexp "vek280" $board_name]} {

	apply_board_connection -board_interface "ch0_lpddr4_trip2" -ip_intf "$additional_mem1/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip2" -ip_intf "$additional_mem1/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk2" -ip_intf "$additional_mem1/sys_clk0" -diagram $design_name 

	apply_board_connection -board_interface "ch0_lpddr4_trip3" -ip_intf "/$additional_mem2/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip3" -ip_intf "/$additional_mem2/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk3" -ip_intf "/$additional_mem2/sys_clk0" -diagram $design_name 
	
} elseif {[regexp "vpk180" $board_name]} {

	apply_board_connection -board_interface "ch0_lpddr4_trip2" -ip_intf "$additional_mem1/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip2" -ip_intf "$additional_mem1/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk2" -ip_intf "$additional_mem1/sys_clk0" -diagram $design_name 

	apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "/$additional_mem2/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "/$additional_mem2/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "/$additional_mem2/sys_clk0" -diagram $design_name  

} elseif {[regexp "vhk158" $board_name]} {

	apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "$additional_mem/CH0_DDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "$additional_mem/sys_clk0" -diagram $design_name 

} else {

	apply_board_connection -board_interface "ch0_lpddr4_c0" -ip_intf "$additional_mem1/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_c0" -ip_intf "$additional_mem1/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_sma_clk1" -ip_intf "$additional_mem1/sys_clk0" -diagram $design_name 

	apply_board_connection -board_interface "ch0_lpddr4_c1" -ip_intf "/$additional_mem2/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_c1" -ip_intf "/$additional_mem2/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_sma_clk2" -ip_intf "/$additional_mem2/sys_clk0" -diagram $design_name 

} 

set_property -dict [list CONFIG.MC_CHAN_REGION0 {DDR_CH2} CONFIG.NUM_MCP {2} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {3} CONFIG.NUM_SI {0} ] [get_bd_cells $additional_mem2]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$additional_mem2/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$additional_mem2/S01_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$additional_mem2/S02_INI]

set_property -dict [list CONFIG.MC_CHAN_REGION0 {DDR_CH1} CONFIG.NUM_MCP {2} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {3} CONFIG.NUM_SI {0} ] [get_bd_cells $additional_mem1]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$additional_mem1/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$additional_mem1/S01_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /$additional_mem1/S02_INI]

# Create instance: aggr_noc, and set properties
set aggr_noc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc aggr_noc ]

set_property -dict [list CONFIG.NUM_MI {0} CONFIG.NUM_NMI {5} CONFIG.NUM_SI {0} ] [get_bd_cells aggr_noc]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M00_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M01_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M02_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M03_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M04_INI]

connect_bd_intf_net [get_bd_intf_pins Master_NoC/M04_INI] [get_bd_intf_pins $additional_mem1/S00_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M05_INI] [get_bd_intf_pins $additional_mem2/S00_INI]

connect_bd_intf_net [get_bd_intf_pins aggr_noc/M00_INI] [get_bd_intf_pins $default_mem/S04_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M01_INI] [get_bd_intf_pins $additional_mem1/S01_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M02_INI] [get_bd_intf_pins $additional_mem1/S02_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M03_INI] [get_bd_intf_pins $additional_mem2/S01_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M04_INI] [get_bd_intf_pins $additional_mem2/S02_INI]

# Create instance: ctrl_smc, and set properties
set ctrl_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect ctrl_smc ]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/M_AXI_FPD] [get_bd_intf_pins ctrl_smc/S00_AXI]
set_property HDL_ATTRIBUTE.DONT_TOUCH true [get_bd_intf_nets {CIPS_0_M_AXI_FPD}]

set clk_freqs [ list ${mbufgce_clk} ${bufg_clk} 100.000 100.000 100.000 100.000 100.000 ]

# Create instance: clk_wizard_0, and set properties
set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_0 ]
set_property -dict [ list \
CONFIG.CE_TYPE {HARDSYNC} \
   CONFIG.CLKOUT_DRIVES {MBUFGCE,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
   CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
   CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
   CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
   CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
   CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
   CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [join $clk_freqs ","] \
   CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
   CONFIG.CLKOUT_USED {true,true,false,false,false,false,false} \
   CONFIG.JITTER_SEL {Min_O_Jitter} \
   CONFIG.PRIM_SOURCE {No_buffer} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
   CONFIG.USE_PHASE_ALIGNMENT {true} \
   CONFIG.USE_LOCKED {true} \
   CONFIG.USE_RESET {true} \
 ] $clk_wizard_0

# Create instance: ilconstant_0, and set properties
set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]

connect_bd_net [get_bd_pins ilconstant_0/dout] [get_bd_pins clk_wizard_0/clk_out1_clr_n] [get_bd_pins clk_wizard_0/clk_out1_ce]

# Create instance: proc_sys_reset_o4, and set properties
set proc_sys_reset_o4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_o4 ]

# Create instance: proc_sys_reset_1, and set properties
set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_1 ]

# Create instance: axi_intc_0, and set properties
set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
set_property -dict [list CONFIG.C_ASYNC_INTR {0xFFFFFFFF} CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_0

connect_bd_intf_net [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins ctrl_smc/M00_AXI]
connect_bd_net [get_bd_pins axi_intc_0/irq] [get_bd_pins CIPS_0/pl_ps_irq0]

connect_bd_net [get_bd_pins CIPS_0/pl0_ref_clk] [get_bd_pins clk_wizard_0/clk_in1]
connect_bd_net [get_bd_pins CIPS_0/pl0_resetn] [get_bd_pins clk_wizard_0/resetn] [get_bd_pins proc_sys_reset_o4/ext_reset_in] [get_bd_pins proc_sys_reset_1/ext_reset_in]
connect_bd_net [get_bd_pins clk_wizard_0/clk_out1_o4] [get_bd_pins CIPS_0/m_axi_fpd_aclk] [get_bd_pins ctrl_smc/aclk] [get_bd_pins proc_sys_reset_o4/slowest_sync_clk] [get_bd_pins axi_intc_0/s_axi_aclk]
connect_bd_net [get_bd_pins clk_wizard_0/clk_out2] [get_bd_pins proc_sys_reset_1/slowest_sync_clk]
connect_bd_net [get_bd_pins clk_wizard_0/locked] [get_bd_pins proc_sys_reset_o4/dcm_locked] [get_bd_pins proc_sys_reset_1/dcm_locked]

connect_bd_net [get_bd_pins proc_sys_reset_o4/peripheral_aresetn] [get_bd_pins axi_intc_0/s_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_o4/interconnect_aresetn] [get_bd_pins ctrl_smc/aresetn]

assign_bd_address
set_param project.replaceDontTouchWithKeepHierarchySoft 0

set_property SELECTED_SIM_MODEL tlm [get_bd_cells /CIPS_0]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells /Master_NoC]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells /$additional_mem1]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells /$additional_mem2]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells /aggr_noc]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells /$default_mem]
set_property preferred_sim_model tlm [current_project]

source "$currentDir/vck_vek_pfm_decls.tcl"

if { $use_aie } {
set_property SELECTED_SIM_MODEL tlm [get_bd_cells /ConfigNoc] 
}

if {$use_aie} {
# Add USER_COMMENTS on $design_name
set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Embedded Common Platform <<<<<<<<< =======================
\t Note:
\t --> Board preset applied to CIPS and memory controller settings
\t --> AI Engine control path is connected to CIPS
\t --> V++ will connect AI Engine data path automatically
\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.2/ced/Xilinx/IPI/versal_common_platform/2.0/README.md}  [current_bd_design]

# Perform GUI Layout
regenerate_bd_layout -layout_string {
	"ActiveEmotionalView":"Default View",
	"comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Embedded Common Platform <<<<<<<<< =======================
	\t Note:
	\t --> Board preset applied to CIPS and memory controller
	\t --> AI Engine control path is connected to CIPS
	\t --> V++ will connect AI Engine data path automatically
	\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
	\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2025.2/ced/Xilinx/IPI/versal_common_platform/2.0/README.md",
	"commentid":"comment_0|",
	"font_comment_0":"14",
	"guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
	#  -string -flagsOSRD
	preplace cgraphic comment_0 place right -1750 -200 textcolor 4 linecolor 3
	",
	"linktoobj_comment_0":"",
	"linktotype_comment_0":"bd_design" }
} else {
# Add USER_COMMENTS on $design_name
set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Embedded Common Platform <<<<<<<<< =======================
\t Note:
\t --> Board preset applied to CIPS and memory controller settings }  [current_bd_design]

# Perform GUI Layout
regenerate_bd_layout -layout_string {
	"ActiveEmotionalView":"Default View",
	"comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Embedded Common Platform <<<<<<<<< =======================
	\t Note:
	\t --> Board preset applied to CIPS and memory controller",
	"commentid":"comment_0|",
	"font_comment_0":"14",
	"guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
	#  -string -flagsOSRD
	preplace cgraphic comment_0 place right -1750 -200 textcolor 4 linecolor 3
	",
	"linktoobj_comment_0":"",
	"linktotype_comment_0":"bd_design" }
} 

puts "INFO: Platform creation completed!"
}
