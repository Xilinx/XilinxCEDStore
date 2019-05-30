proc createDesign {design_name options} {   

variable currentDir
set_property target_language Verilog [current_project]
set_property "simulator_language" "Mixed" [current_project]

##################################################################
# DESIGN PROCs
##################################################################

# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell design_name temp_options} {
  
	set sys_diff_clock [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==system_clock}] 0]]
  
	if {[get_board_components -filter {SUB_TYPE==system_reset}] != ""} {
		set reset [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==system_reset}] 0]]
		} else {
			puts "External Reset is not available on the Board"
		}
	
	create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
	apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]


	if { ([lsearch $temp_options Include_DDR4.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_DDR4.VALUE] + 1]] == true) } {
   		create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0
		apply_board_connection -board_interface [lindex [get_property COMPONENT_NAME [get_board_components -filter {SUB_TYPE==ddr} -of_objects [current_board] ]] 0] -ip_intf "/ddr4_0/C0_DDR4" -diagram $design_name
		if { [get_property CONFIG.System_Clock [get_bd_cells ddr4_0]] == "No_Buffer" } { 
			set_property -dict [list CONFIG.System_Clock {Differential}] [get_bd_cells ddr4_0]
		} 
		apply_board_connection -board_interface "$sys_diff_clock" -ip_intf "ddr4_0/C0_SYS_CLK" -diagram $design_name 
		apply_board_connection -board_interface "$reset" -ip_intf "/ddr4_0/SYSTEM_RESET" -diagram $design_name 
	
		if { ([lsearch $temp_options Include_AXI_Type.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_AXI_Type.VALUE] + 1]] == {Smartconnect}) } {
		#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" }  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" intc_ip "New AXI Smartconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]		
		}
	
		if { ([lindex $temp_options [expr [lsearch $temp_options Include_AXI_Type.VALUE] + 1]] == {Interconnect}) } {
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
		}
	
		
		#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/ddr4_0/C0_DDR4_S_AXI" Clk "Auto" }  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]
		#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/ddr4_0/C0_DDR4_S_AXI" intc_ip "/axi_mem_intercon" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]
	}


	if { ([lsearch $temp_options Include_UART.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_UART.VALUE] + 1]] == true) } {
		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0
		set rs232_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==uart}] 0]]
	   #apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" }  [get_bd_intf_pins axi_uartlite_0/S_AXI]
	   #apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_uartlite_0/S_AXI]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_uartlite_0/S_AXI]
   
		apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "uart2_pl ( UART ) " }  [get_bd_intf_pins axi_uartlite_0/UART]

		if { ([lsearch $temp_options Include_UART_PARITY.VALUE] != -1)} {
			set parity [lindex $temp_options [expr [lsearch $temp_options Include_UART_PARITY.VALUE] + 1]]
			} else {
			set parity No_Parity
			set odd_parity 0
			set use_parity 0
		}
	 
		if { ([lsearch $temp_options Include_UART_BAUD.VALUE] != -1)} {
			set baud_rate [lindex $temp_options [expr [lsearch $temp_options Include_UART_BAUD.VALUE] + 1]]
			} else {
			set baud_rate 9600
		}

		if { ([lsearch $temp_options Include_UART_DATA.VALUE] != -1)} {
			set data_bits [lindex $temp_options [expr [lsearch $temp_options Include_UART_DATA.VALUE] + 1]]
		} else {
			set data_bits 8
		}
	 
		if { $parity == "No"} {
			set use_parity 0
			set parity No_Parity
			set odd_parity 0
		}
 
		if { $parity == "Even"} {
			 set use_parity 1
			 set parity Even
			 set odd_parity 0
		} 
 
		if { $parity == "Odd"} {
			 set use_parity 1
			 set parity Odd
			 set odd_parity 1
		}
		set_property -dict [list CONFIG.PARITY $parity CONFIG.C_BAUDRATE $baud_rate CONFIG.C_DATA_BITS $data_bits CONFIG.C_USE_PARITY $use_parity CONFIG.C_ODD_PARITY $odd_parity] [get_bd_cells axi_uartlite_0]
	}


	set gpio_if [get_property DISPLAY_NAME [get_board_components -filter {SUB_TYPE==switch || SUB_TYPE==led || SUB_TYPE==push_button } -of_objects [current_board]]]
	set gpio_if_cnt 0
	
	foreach item $gpio_if {
		if { ([lsearch $temp_options Include_[regsub " " $item {_}].VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_[regsub " " $item {_}].VALUE] + 1]] == true) } { 
			set item_temp "DISPLAY_NAME==\"$item\""
			set new_item [subst $item_temp]
			set gpio_if_cnt [expr $gpio_if_cnt + 1]
		if { $gpio_if_cnt % 2 == 1} {
			create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_[expr $gpio_if_cnt/2]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD" Clk "Auto" }  [get_bd_intf_pins axi_gpio_[expr $gpio_if_cnt/2]/S_AXI] 
		  #apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_gpio_[expr $gpio_if_cnt/2]/S_AXI]
		  #apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD" intc_ip "/ps8_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_gpio_[expr $gpio_if_cnt/2]/S_AXI]
			apply_board_connection -board_interface [get_board_part_interfaces -filter OF_COMPONENT==[get_property COMPONENT_NAME [get_board_components -filter ${new_item} -of_objects [current_board]] ]] -ip_intf "axi_gpio_[expr $gpio_if_cnt/2]/GPIO" -diagram $design_name
			} else {

				apply_board_connection -board_interface [get_board_part_interfaces -filter OF_COMPONENT==[get_property COMPONENT_NAME [get_board_components -filter ${new_item} -of_objects [current_board]] ]] -ip_intf "axi_gpio_[expr (($gpio_if_cnt - 1)/2)]/GPIO2" -diagram $design_name
			}	
		}
	}

	if { ([lsearch $temp_options Local_memory.VALUE] != -1) } {
		set local_memory [lindex $temp_options [expr [lsearch $temp_options Local_memory.VALUE] + 1]]
		set_property range $local_memory [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_dlmb_bram_if_cntlr_Mem}]
		set_property range $local_memory [get_bd_addr_segs {zynq_ultra_ps_e_0/Instruction/SEG_ilmb_bram_if_cntlr_Mem}]
		}
	if { ([lsearch $temp_options Instruction_Cache.VALUE] != -1) } {
		set_property CONFIG.C_CACHE_BYTE_SIZE [expr [string trim [lindex $temp_options [expr [lsearch $temp_options Instruction_Cache.VALUE] + 1]] K]*1024] [get_bd_cells 	zynq_ultra_ps_e_0]
		}

	if { ([lsearch $temp_options Data_Cache.VALUE] != -1) } {
		set_property CONFIG.C_DCACHE_BYTE_SIZE [expr [string trim [lindex $temp_options [expr [lsearch $temp_options Data_Cache.VALUE] + 1]] K]*1024] [get_bd_cells zynq_ultra_ps_e_0]
		}


	if { ([lindex $temp_options [expr [lsearch $temp_options Include_DDR4.VALUE] + 1]] == false) } {

		if { ([lsearch $temp_options Include_UART.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_UART.VALUE] + 1]] == true) } {
			#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/axi_uartlite_0/S_AXI" intc_ip "/ps8_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/axi_uartlite_0/S_AXI" intc_ip "/ps8_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]
		}	
	  
		if { ([lindex $temp_options [expr [lsearch $temp_options Include_UART.VALUE] + 1]] == false) } {
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/axi_gpio_0/S_AXI" intc_ip "/ps8_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]
		}	
    } 
	if { ([lindex $temp_options [expr [lsearch $temp_options Include_DDR4.VALUE] + 1]] == true) } {
		if { ([lindex $temp_options [expr [lsearch $temp_options Include_AXI_Type.VALUE] + 1]] == {Interconnect}) } {
			#puts "Before STRATEGY"	
			set_property -dict [list CONFIG.S00_HAS_REGSLICE {4}] [get_bd_cells axi_mem_intercon]
			#	set_property -dict [list CONFIG.STRATEGY {1}] [get_bd_cells axi_mem_intercon]
	   }
    }

	save_bd_design
	validate_bd_design
	set wrapper_file [make_wrapper -files [get_bd_files $design_name] -top]
	add_files [list $wrapper_file]
	update_compile_order -fileset sources_1 

	# if { ([lsearch $temp_options Include_DDR4.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_DDR4.VALUE] + 1]] == true) } {
	   # set board_name [get_property NAME [current_board_part]]
	   # if { [regexp zcu106 $board_name] } {
		  # set proj_dir [get_property DIRECTORY [current_project ]]
		  # set proj_name [get_property NAME [current_project ]]
		  # file mkdir $proj_dir/$proj_name.srcs/constrs_1/new
		  # set fd [ open $proj_dir/$proj_name.srcs/constrs_1/new/toplevel.xdc w ]
		  # puts $fd "set_property DCI_CASCADE 66 \[get_iobanks 65\]"
		  # close $fd
		  # add_files -fileset constrs_1 $proj_dir/$proj_name.srcs/constrs_1/new/toplevel.xdc 
		# }
	# }
  
}

# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################
set_property target_language Verilog [current_project]
create_root_design "" $design_name $options
regenerate_bd_layout
close_bd_design [get_bd_designs $design_name]
set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
#open_bd_design [file join $bdDesignPath $design_name.bd]
open_bd_design [get_bd_files $design_name]

regenerate_bd_layout
save_bd_design

}
