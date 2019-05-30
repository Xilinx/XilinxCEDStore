proc createDesign {design_name options} {   

variable currentDir
set_property target_language Verilog [current_project]
set_property "simulator_language" "Mixed" [current_project]

proc create_root_design { currentDir parentCell design_name } {
	if { $parentCell eq "" } {
		set parentCell [get_bd_cells /]
	}

	# Get object for parentCell
	set parentObj [get_bd_cells $parentCell]
	if { $parentObj == "" } {
		puts "ERROR: Unable to find parent cell <$parentCell>!"
		return
	}

	#	Make sure parentObj is hier blk
	set parentType [get_property TYPE $parentObj]
	if { $parentType ne "hier" } {
		puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
		return
	}

	# Save current instance; Restore later
	set oldCurInst [current_bd_instance .]

	# Set parent object as current
	current_bd_instance $parentObj



	
		create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
	

	apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]

	connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
	connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]


	#set gpio_if [get_property DISPLAY_NAME [get_board_components -filter {SUB_TYPE==switch || SUB_TYPE==led || SUB_TYPE==push_button } -of_objects [current_board]]]
	set gpio_if [get_property DISPLAY_NAME [get_board_components -filter {SUB_TYPE==led} -of_objects [current_board]]]

	set gpio_if_cnt 0
	foreach item $gpio_if {

	  #if { ([lsearch $temp_options Include_[regsub " " $item {_}].VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_[regsub " " $item {_}].VALUE] + 1]] == true) } { 
		set item_temp "DISPLAY_NAME==\"$item\""
		set new_item [subst $item_temp]
		set gpio_if_cnt [expr $gpio_if_cnt + 1]
		if { $gpio_if_cnt % 2 == 1} {
		  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_[expr $gpio_if_cnt/2]
		  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" }  [get_bd_intf_pins axi_gpio_[expr $gpio_if_cnt/2]/S_AXI] 
		  apply_board_connection -board_interface [get_board_part_interfaces -filter OF_COMPONENT==[get_property COMPONENT_NAME [get_board_components -filter ${new_item} -of_objects [current_board]] ]] -ip_intf "axi_gpio_[expr $gpio_if_cnt/2]/GPIO" -diagram $design_name
		} else {

		apply_board_connection -board_interface [get_board_part_interfaces -filter OF_COMPONENT==[get_property COMPONENT_NAME [get_board_components -filter ${new_item} -of_objects [current_board]] ]] -ip_intf "axi_gpio_[expr (($gpio_if_cnt - 1)/2)]/GPIO2" -diagram $design_name
		}
	 # }
	}

# if {[get_board_components -filter {SUB_TYPE==led}]!=""} { 
# 
	# set led_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==led}] 0]]
	# create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0
	
		# #apply_board_connection -board_interface "$led_interface" -ip_intf "ddr4_0/C0_SYS_CLK" -diagram $design_name 
	# apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "led_8bits ( LED ) " }  [get_bd_intf_pins axi_gpio_0/GPIO]
	# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_gpio_0/S_AXI]
# 
# }

	
	create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen_0
	

	
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0
	

	set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_0]

	connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

	if {[get_board_components -filter {SUB_TYPE==led}]!=""} { 
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
	}  

	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/axi_bram_ctrl_0/S_AXI" intc_ip "/ps8_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]

	current_bd_instance $oldCurInst

	delete_bd_objs [get_bd_addr_segs zynq_ultra_ps_e_0/Data/SEG_axi_bram_ctrl_0_Mem0] [get_bd_addr_segs zynq_ultra_ps_e_0/Data/SEG_axi_gpio_0_Reg]
	assign_bd_address [get_bd_addr_segs {axi_gpio_0/S_AXI/Reg }]
	assign_bd_address [get_bd_addr_segs {axi_bram_ctrl_0/S_AXI/Mem0 }]
	set_property offset 0x00A0000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_gpio_0_Reg}]
	set_property offset 0x00B0000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_bram_ctrl_0_Mem0}]

	set wrapper_file [make_wrapper -files [get_bd_files $design_name] -top]
	add_files [list $wrapper_file]
	save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################
create_root_design $currentDir "" $design_name

set board_info [get_property BOARD_PART [current_project]]
set board_name [string toupper [lindex [split $board_info ":"] 1]]

#set uiFile [file join $currentDir ui $board_name bd_cf78a2d4.ui]

close_bd_design [get_bd_designs $design_name]
set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
#open_bd_design [file join $bdDesignPath $design_name.bd]
open_bd_design [get_bd_files $design_name]

set wrapper_name "${design_name}_wrapper"
if {[get_property VENDOR_NAME [current_board]] == {xilinx.com}} {
#Testbench file creation and import
set originalTBFile [file join $currentDir testbench $board_name mpsoc_tb.v] 
set tempTBFile [file join $bdDesignPath mpsoc_tb.v] 

#file delete -force $tempTBFile 
#file copy -force $originalTBFile $tempTBFile 
set infile [open $originalTBFile]
set contents [read $infile]
close $infile
#set contents [string map [list "module tb" "module $wrapper_name"] $contents]
set contents [string map [list "zynq_design" "$design_name"] $contents]

set outfile [open $tempTBFile w]
puts  -nonewline $outfile $contents
close $outfile

import_files -fileset [get_filesets sim_1] -norecurse [list $tempTBFile]

file delete -force $tempTBFile 
set_property top tb [get_filesets sim_1]
#regenerate_bd_layout -layout_file $uiFile 
regenerate_bd_layout
save_bd_design
 }
 #set_property -name {xsim.elaborate.xelab.more_options} -value {-cc gcc} -objects [current_fileset -simset]
}
