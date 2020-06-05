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

# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.



proc create_root_design { parentCell design_name temp_options} {


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
set ddr3_board_interface ""
set ddr3_board_interface_1 ""
set interrupt_interface ""

# set ddr3_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==ddr}] 0]]
set ddr3_board_interface [board::get_board_part_interfaces *ddr3*]
set ddr3_board_interface_1 [lindex [split $ddr3_board_interface { }] 0]

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
	

if {([lsearch $temp_options Preset.VALUE] == -1) || ([lsearch $temp_options PS7_Only] != -1)}   {
	puts "INFO: PS7_Only preset enabled"
	

} elseif { ([lsearch $temp_options PS7_PL] != -1 )} {

	puts "INFO: PS7_PL preset enabled"

	set led_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==led}] 0]]
	if { $led_board_interface != "" } {
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0
	apply_board_connection -board_interface "$led_board_interface" -ip_intf "axi_gpio_0/GPIO" -diagram $design_name 
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (50 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_gpio_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_0/S_AXI]
	}

	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0

	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (50 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]


} elseif { ([lsearch $temp_options PS7_Accelerated] != -1 )} {
	puts "INFO: PS7_Accelerated preset enabled"
	
	if { $ddr3_board_interface != "" } {
	create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series mig_7series_0
	apply_board_connection -board_interface "$ddr3_board_interface_1" -ip_intf "mig_7series_0/mig_ddr_interface" -diagram $design_name 
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins mig_7series_0/sys_rst]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (50 MHz)} Clk_slave {/mig_7series_0/ui_clk (200 MHz)} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/mig_7series_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins mig_7series_0/S_AXI]
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

create_root_design "" $design_name $options 

	# close_bd_design [get_bd_designs $design_name]
	# set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
	open_bd_design [get_bd_files $design_name]
}