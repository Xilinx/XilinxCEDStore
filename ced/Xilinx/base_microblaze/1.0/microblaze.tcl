proc createDesign {design_name options} {   

variable currentDir
set_property target_language VHDL [current_project]
set_property "simulator_language" "Mixed" [current_project]

##################################################################
# DESIGN PROCs
##################################################################

# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell design_name} {
	set led_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==led}] 0]]
	set rs232_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==uart}] 0]]
	if {[get_property BOARD_NAME [current_board]] == {kcu105}} { 
		set sys_diff_clock [get_board_part_interfaces default_sysclk_300]
		} else {
		set sys_diff_clock [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==system_clock}] 0]]
	}	
	set reset [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==system_reset}] 0]]
	
		create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0
	
	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config {local_mem "8KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "0" clk "New Clocking Wizard (100 MHz)" }  [get_bd_cells microblaze_0]
	
		apply_board_connection -board_interface "$sys_diff_clock" -ip_intf "/clk_wiz_1/CLK_IN1_D" -diagram $design_name 
	
	
		apply_board_connection -board_interface "$reset" -ip_intf "/clk_wiz_1/reset" -diagram $design_name 
		apply_board_connection -board_interface "$reset" -ip_intf "/rst_clk_wiz_1_100M/ext_reset" -diagram $design_name 
	
	
		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0
		set_property -dict [list CONFIG.C_BAUDRATE {115200}] [get_bd_cells axi_uartlite_0]
		apply_board_connection -board_interface $rs232_interface -ip_intf "axi_uartlite_0/UART" -diagram $design_name 
	
	
		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0
		apply_board_connection -board_interface $led_interface -ip_intf "axi_gpio_0/GPIO" -diagram $design_name 
	
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_uartlite_0/S_AXI]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_gpio_0/S_AXI]
		set_property range 32K [get_bd_addr_segs {microblaze_0/Data/SEG_dlmb_bram_if_cntlr_Mem}]
		set_property range 32K [get_bd_addr_segs {microblaze_0/Instruction/SEG_ilmb_bram_if_cntlr_Mem}]
	set wrapper_file [make_wrapper -files [get_bd_files $design_name] -top]
	add_files [list $wrapper_file]
	save_bd_design
}

# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $design_name

	set uiFile [file join $currentDir bd_cb6338ff.ui]
	close_bd_design [get_bd_designs $design_name]
	set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
	#open_bd_design [file join $bdDesignPath $design_name.bd]
	open_bd_design [get_bd_files $design_name]

	if {[get_property VENDOR_NAME [current_board]] == {xilinx.com}} {
		#Import elf files and associate them
		set elfFile [file join $currentDir executable.elf]
		import_files -fileset [get_filesets sim_1] -norecurse $elfFile 
		set_property SCOPED_TO_REF "${design_name}" [get_files -all -of_objects [get_fileset sim_1] executable.elf]
		set_property SCOPED_TO_CELLS { microblaze_0 } [get_files -all -of_objects [get_fileset sim_1] executable.elf]

		#Import wrapper files
		set wrapper_file1 [file join $currentDir uart_rcvr_wrapper.v]
		set wrapper_file2 [file join $currentDir uart_rcvr.v]
		import_files -fileset [get_filesets sim_1] -norecurse $wrapper_file1 
		import_files -fileset [get_filesets sim_1] -norecurse $wrapper_file2

		set board_info [get_property BOARD_PART [current_project]]
		set board_name [string toupper [lindex [split $board_info ":"] 1]]
		set wrapper_name "${design_name}_wrapper"

		#Testbench file creation and import
		set originalTBFile [file join $currentDir testbench $board_name system_tb.v] 
		set tempTBFile [file join $bdDesignPath system_tb.v] 

		#file delete -force $tempTBFile 
		#file copy -force $originalTBFile $tempTBFile 
		set infile [open $originalTBFile]
		set contents [read $infile]
		close $infile
		#set contents [string map [list "module system_tb" "module $wrapper_name"] $contents]
		set contents [string map [list "microblaze_design" "$design_name"] $contents]

		set outfile [open $tempTBFile w]
		puts  -nonewline $outfile $contents
		close $outfile

		import_files -fileset [get_filesets sim_1] -norecurse [list $tempTBFile]

		file delete -force $tempTBFile 
		set_property top system_tb [get_filesets sim_1]
		regenerate_bd_layout -layout_file $uiFile
		save_bd_design 
	}
}
