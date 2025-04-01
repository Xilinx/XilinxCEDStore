# ########################################################################
# Copyright (C) 2023, Advanced Micro Devices Inc - All rights reserved

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

#set design_name mb_preset
#set temp_options Application_Processor

# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.

proc create_root_design { parentCell design_name temp_options} {

puts "create_root_design"
set fpga_part [get_property PART [current_project ]]
puts "INFO: $fpga_part is selected"
puts "INFO: selected design_name:: $design_name"

create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:* microblaze_0

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:* axi_bram_ctrl_0

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:* axi_timer_0

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:* axi_uartlite_0


if {([lsearch $temp_options Preset.VALUE] == -1) || ([lsearch $temp_options "Microcontroller"] != -1)} {
	puts "INFO: Microcontroller preset enabled"

	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { all {1} axi_intc {1} axi_periph {Enabled} cache {None} clk {New Clocking Wizard} compress {1} cores {1} debug_module {Debug Only} disable {1} ecc {None} local_mem {64KB} preset {Microcontroller}}  [get_bd_cells microblaze_0]

	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]
	
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_intf_pins clk_wiz_1/CLK_IN1_D]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins clk_wiz_1/reset]
	
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/reset_rtl_0 (ACTIVE_HIGH)}}  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
	connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In0]
	
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_uartlite_0/S_AXI]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_intf_pins axi_uartlite_0/UART]

	assign_bd_address

} elseif { ([lsearch $temp_options "Real-time_Processor"] != -1 )} {
	puts "INFO: Real-time_Processor preset enabled"
	
	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { all {1} axi_intc {1} axi_periph {Enabled} cache {8KB} clk {New Clocking Wizard} compress {1} cores {1} debug_module {Debug Only} disable {1} ecc {None} local_mem {64KB} preset {Real-time}}  [get_bd_cells microblaze_0]

	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Cached)} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
	
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]
	
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_intf_pins clk_wiz_1/CLK_IN1_D]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins clk_wiz_1/reset]
	
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/reset_rtl_0 (ACTIVE_HIGH)}}  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
	connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In0]
	
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_uartlite_0/S_AXI]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_intf_pins axi_uartlite_0/UART]
	
	assign_bd_address
	set_property range 32K [get_bd_addr_segs {microblaze_0/Data/SEG_axi_bram_ctrl_0_Mem0}]
	set_property range 32K [get_bd_addr_segs {microblaze_0/Instruction/SEG_axi_bram_ctrl_0_Mem0}]

	#creating the top.xdc constraints
	set proj_dir [get_property DIRECTORY [current_project ]]
	set proj_name [get_property NAME [current_project ]]
	#set board_name [get_property NAME [current_board_part]]
	set fpga_part [get_property PART [current_project ]]
	file mkdir $proj_dir/$proj_name.srcs/constrs_1/constrs

	#set fd [ open $proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc w ]
	# if { $Include_ddr != {} } {
			# puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */addn_ui_clkout1}\]"
			# puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}\]"	  
	     # }
	# close $fd
	# add_files  -fileset constrs_1 [ list "$proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc" ]
		 
} elseif { ([lsearch $temp_options "Application_Processor"] != -1 )} {
	puts "INFO: Application_Processor preset enabled"
	
	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { all {1} axi_intc {1} axi_periph {Enabled} cache {32KB} clk {New Clocking Wizard} compress {1} cores {1} debug_module {Debug Only} disable {1} ecc {None} local_mem {64KB} preset {Application}}  [get_bd_cells microblaze_0]
	
	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Cached)} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]

	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_intf_pins clk_wiz_1/CLK_IN1_D]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins clk_wiz_1/reset]

	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/reset_rtl_0 (ACTIVE_HIGH)}}  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]

	connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In0]
	
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_uartlite_0/S_AXI]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_intf_pins axi_uartlite_0/UART]
	
	assign_bd_address
	set_property range 32K [get_bd_addr_segs {microblaze_0/Instruction/SEG_axi_bram_ctrl_0_Mem0}]
	set_property range 32K [get_bd_addr_segs {microblaze_0/Data/SEG_axi_bram_ctrl_0_Mem0}]
	}
	
	
	regenerate_bd_layout
	
	validate_bd_design
	save_bd_design
	make_wrapper -files [get_files $design_name.bd] -top -import
	
	puts "INFO: End of create_root_design"
}

##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $design_name $options 

	# close_bd_design [get_bd_designs $design_name]
	# set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
	open_bd_design [get_bd_files $design_name]
}
