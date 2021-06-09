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

proc createDesign {design_name options} {   

##################################################################
# DESIGN PROCs													 
##################################################################

# set design_name config_zynq7000
# set temp_options PS7_Only
variable currentDir
set_property target_language Verilog [current_project]
set_property "simulator_language" "Mixed" [current_project]
# Procedure to create entire design; Provide argument to make
proc create_root_design { currentDir design_name temp_options} {

#puts "creat_root_desing"
set board_part [get_property NAME [current_board_part]]
#set design_repo [get_property REPO_DIRECTORY [get_example_designs *$design_name*]]
#puts $design_repo
puts "INFO: $board_part selected"
#puts "INFO: $temp_options"

# source $design_repo/bd_7series/microcontroller_bd.tcl
# set file  "[file dirname [file normalize [info script]]]/repo2/bd_7series/microcontroller_bd.tcl"
# source $file

set led_board_interface ""
set iic_board_interface ""
set uart_board_interface ""
set ddr4_board_interface ""
set ddr4_board_interface_1 ""
set interrupt_interface ""

# set ddr4_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==ddr}] 0]]
set ddr4_board_interface [board::get_board_part_interfaces *ddr4*]
set ddr4_board_interface_1 [lindex [split $ddr4_board_interface { }] 0]


create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0

apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]

	

if {([lsearch $temp_options Preset.VALUE] == -1) || ([lsearch $temp_options MPSoC_Only] != -1)}   {
	puts "INFO: MPSoC_Only preset enabled"
	

} elseif { ([lsearch $temp_options MPSoC_PL] != -1 )} {

	puts "INFO: MPSoC_PL preset enabled"

	catch { set led_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==led}] 0]]
	if { $led_board_interface != "" } {
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0
	apply_board_connection -board_interface "$led_board_interface" -ip_intf "axi_gpio_0/GPIO" -diagram $design_name 
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_gpio_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_0/S_AXI]
	} }

	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0

	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
	
	if { $led_board_interface == "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]
	} else {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {Auto} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD} Slave {/axi_gpio_0/S_AXI} ddr_seg {Auto} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]
   }

} elseif { ([lsearch $temp_options MPSoC_Accelerated] != -1 )} {
	puts "INFO: MPSoC_Accelerated preset enabled"
	
	if { $ddr4_board_interface != "" } {
	create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0
	apply_board_connection -board_interface "ddr4_sdram" -ip_intf "ddr4_0/C0_DDR4" -diagram $design_name
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD} Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins ddr4_0/sys_rst]

	set sys_diff_clock [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==system_clock}] 0]]
	apply_board_connection -board_interface "$sys_diff_clock" -ip_intf "ddr4_0/C0_SYS_CLK" -diagram $design_name 
	}

}
	regenerate_bd_layout
	validate_bd_design
	make_wrapper -files [get_files $design_name.bd] -top -import

}
# End of create_root_design()
	
puts "INFO: End of create_root_design"


##################################################################
# MAIN FLOW
##################################################################

create_root_design $currentDir $design_name $options 

	# close_bd_design [get_bd_designs $design_name]
	set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]

	#Testbench file creation and import
	set board_name [get_property BOARD_NAME [current_board]]
	
	if {([lsearch $options Preset.VALUE] == -1) || ([lsearch $options MPSoC_Only] != -1)} {
	set originalTBFile [file join $currentDir testbench MPSoC_Only mpsoc_tb.v]
	} else {
	if {[regexp zcu104 $board_name] } {
	set originalTBFile [file join $currentDir testbench MPSoC_PL ZCU4bit mpsoc_tb.v]
	} elseif { [regexp zcu102 $board_name] ||[regexp zcu106 $board_name]||[regexp zcu111 $board_name]||[regexp zcu208 $board_name] } {
	set originalTBFile [file join $currentDir testbench MPSoC_PL ZCU8bit mpsoc_tb.v]
	} elseif { [regexp zcu1275 $board_name] ||[regexp zcu1285 $board_name]} {
	 set originalTBFile [file join $currentDir testbench MPSoC_PL ZCU12 mpsoc_tb.v]
	} elseif {[regexp vermeo $board_name] } {
	set originalTBFile [file join $currentDir testbench MPSoC_PL Vermeo mpsoc_tb.v] } }
	
	set tempTBFile [file join $bdDesignPath mpsoc_tb.v]
	#file copy -force $originalTBFile $tempTBFile 
	set infile [open $originalTBFile]
	set contents [read $infile]
	close $infile
	set contents [string map [list "Base_Zynq_MPSoC" "$design_name"] $contents]

	set outfile [open $tempTBFile w]
	puts -nonewline $outfile $contents
	close $outfile

	import_files -fileset [get_filesets sim_1] -norecurse [list $tempTBFile]
	file delete -force $tempTBFile 
	set_property top tb [get_filesets sim_1]
	
	open_bd_design [get_bd_files $design_name]
}
