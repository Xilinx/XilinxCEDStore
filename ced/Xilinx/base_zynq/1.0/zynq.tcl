proc createDesign {design_name options} {   

variable currentDir
set_property target_language VHDL [current_project]
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

  # Make sure parentObj is hier blk
	set parentType [get_property TYPE $parentObj]
	if { $parentType ne "hier" } {
		puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
		return
	}

  # Save current instance; Restore later
	set oldCurInst [current_bd_instance .]

  # Set parent object as current
	current_bd_instance $parentObj

	
		create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0
	
	apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
	if {[get_board_components -filter {SUB_TYPE==led}]!=""} { 
		
			set led_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==led}] 0]]
			create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0
			apply_board_connection -board_interface $led_interface -ip_intf "axi_gpio_0/GPIO" -diagram $design_name 
		
	}
	
		create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen_0
	
	
		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0
	
	set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_0]
	connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
	if {[get_board_components -filter {SUB_TYPE==led}]!=""} { 
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins axi_gpio_0/S_AXI]
		} else {
			set_property -dict [list CONFIG.PCW_USE_S_AXI_GP0 {1} CONFIG.Component_Name {base_zynq_design_processing_system7_0_0}] [get_bd_cells processing_system7_0]
	}
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] 
	current_bd_instance $oldCurInst
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
		set originalTBFile [file join $currentDir testbench $board_name zynq_tb.v] 
		set tempTBFile [file join $bdDesignPath zynq_tb.v] 

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
	# set_property -name {xsim.elaborate.xelab.more_options} -value {-cc gcc} -objects [current_fileset -simset]
}
