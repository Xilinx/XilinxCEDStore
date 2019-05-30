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
  
  if {[get_property BOARD_NAME [current_board]] == {kcu105}} { 
  set sys_diff_clock [get_board_part_interfaces default_sysclk_300]
  } else {
  set sys_diff_clock [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==system_clock}] 0]]
  }
  if {[get_board_components -filter {SUB_TYPE==system_reset}] != ""} {
	set reset [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==system_reset}] 0]]
	} else {
	  puts "External Reset is not available on the Board"
	}
	
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0
if { ([lsearch $temp_options Include_DDR4.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_DDR4.VALUE] + 1]] == true) } {
  set_property -dict [list CONFIG.C_USE_ICACHE {1} CONFIG.C_USE_DCACHE {1}] [get_bd_cells microblaze_0]
  create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0
  #apply_board_connection -board_interface "ddr4_sdram" -ip_intf "/ddr4_0/C0_DDR4" -diagram $design_name 
	apply_board_connection -board_interface [lindex [get_property COMPONENT_NAME [get_board_components -filter {SUB_TYPE==ddr} -of_objects [current_board] ]] 0] -ip_intf "/ddr4_0/C0_DDR4" -diagram $design_name
	if { [get_property CONFIG.System_Clock [get_bd_cells ddr4_0]] == "No_Buffer" } { 
	  set_property -dict [list CONFIG.System_Clock {Differential}] [get_bd_cells ddr4_0]
	} 
	apply_board_connection -board_interface "$sys_diff_clock" -ip_intf "ddr4_0/C0_SYS_CLK" -diagram $design_name 
  apply_board_connection -board_interface "$reset" -ip_intf "/ddr4_0/SYSTEM_RESET" -diagram $design_name  
  set mul [get_property CONFIG.C0.DDR4_CLKOUT0_DIVIDE [get_bd_cells ddr4_0]]
  set ui_clk_freq [get_property CONFIG.FREQ_HZ [get_bd_pins /ddr4_0/c0_ddr4_ui_clk]]
	set divisor_for_100MHz [expr {$ui_clk_freq * $mul / 100}]
	set addn_ui_clk_freq [expr {$ui_clk_freq * $mul / $divisor_for_100MHz}]
  set need_another_ui_addn_clk 1
	set addn_ui_clk "/ddr4_0/addn_ui_clkout1"	
	if { [get_bd_pins /ddr4_0/addn_ui_clkout1] == ""}  {
     set_property -dict [list CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ $addn_ui_clk_freq] [get_bd_cells ddr4_0]
		 set mb_bd_config_list {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/ddr4_0/addn_ui_clkout1" }
	} else {
      if {[get_property CONFIG.FREQ_HZ [get_bd_pins /ddr4_0/addn_ui_clkout1]] <= 110000000} {
         set mb_bd_config_list {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/ddr4_0/addn_ui_clkout1" }
      } else {
			 set need_another_ui_addn_clk 2
			}
	}
  if {$need_another_ui_addn_clk == 2} {
	   set addn_ui_clk "/ddr4_0/addn_ui_clkout2"
	   if { [get_bd_pins /ddr4_0/addn_ui_clkout2] == ""}  {
       set_property -dict [list CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ $addn_ui_clk_freq] [get_bd_cells ddr4_0]
		   set mb_bd_config_list {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/ddr4_0/addn_ui_clkout2" }
	   } else {
        if {[get_property CONFIG.FREQ_HZ [get_bd_pins /ddr4_0/addn_ui_clkout2]] <= 110000000} {
           set mb_bd_config_list {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/ddr4_0/addn_ui_clkout2" }
        } else {
			    set need_another_ui_addn_clk 3
		    }
	   }	
  }
	if {$need_another_ui_addn_clk == 3} {
	   set addn_ui_clk "/ddr4_0/addn_ui_clkout3"	
	   if { [get_bd_pins /ddr4_0/addn_ui_clkout3] == ""}  {
       set_property -dict [list CONFIG.ADDN_UI_CLKOUT3_FREQ_HZ $addn_ui_clk_freq] [get_bd_cells ddr4_0]
		   set mb_bd_config_list {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/ddr4_0/addn_ui_clkout3" }
	   } else {
        if {[get_property CONFIG.FREQ_HZ [get_bd_pins /ddr4_0/addn_ui_clkout3]] <= 110000000} {
           set mb_bd_config_list {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/ddr4_0/addn_ui_clkout3" }
        } else {
			    set need_another_ui_addn_clk 4
		    }
	   }	
  }
	if {$need_another_ui_addn_clk == 4} {
		 set addn_ui_clk "/ddr4_0/addn_ui_clkout4"
	   if { [get_bd_pins /ddr4_0/addn_ui_clkout4] == ""}  {
       set_property -dict [list CONFIG.ADDN_UI_CLKOUT4_FREQ_HZ $addn_ui_clk_freq] [get_bd_cells ddr4_0]
		   set mb_bd_config_list {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/ddr4_0/addn_ui_clkout4" }
	   } else {
        if {[get_property CONFIG.FREQ_HZ [get_bd_pins /ddr4_0/addn_ui_clkout3]] <= 110000000} {
           set mb_bd_config_list {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/ddr4_0/addn_ui_clkout4" }
        } else {
			     puts "All UI additional clocks are used by the user and are above 110 MHz"
				   puts "Design needs at least one UI additional clock from DDR"
				   puts "Error"				    
		    }
	   }	
  }	

	
	if { ([lsearch $temp_options Include_Ethernet.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_Ethernet.VALUE] + 1]] == true) } {
    apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config $mb_bd_config_list  [get_bd_cells microblaze_0]
	} else {
	  apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config $mb_bd_config_list  [get_bd_cells microblaze_0]
		create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0
    connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins microblaze_0_xlconcat/In0]
    connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins microblaze_0_xlconcat/In1]
	}
	
	if { ([lsearch $temp_options Include_AXI_Type.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_AXI_Type.VALUE] + 1]] == {Smartconnect}) } {
	  #apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Cached)" Clk "Auto" }  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
	  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Cached)" intc_ip "New AXI SmartConnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
       } else {
	  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Cached)" intc_ip "New AXI InterConnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
	  set_property -dict [list CONFIG.M00_HAS_REGSLICE {4}] [get_bd_cells axi_mem_intercon]
		      }
	
    # if {[get_property BOARD_NAME [current_board]] == {kcu1500}} { 	
		# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI_CTRL]
       # }
  
  #set freqM [string range [get_property CONFIG.FREQ_HZ [get_bd_pins $addn_ui_clk]] 0 2]M 
  set freqM [expr [get_property CONFIG.FREQ_HZ [get_bd_pins $addn_ui_clk]] / 1000000]M
  apply_board_connection -board_interface "$reset" -ip_intf "/rst_ddr4_0_$freqM/ext_reset" -diagram $design_name
#  apply_board_connection -board_interface "$reset" -ip_intf "/rst_ddr4_0_100M/ext_reset" -diagram $design_name

  #set_property -dict [list CONFIG.M00_HAS_REGSLICE {4}] [get_bd_cells axi_mem_intercon]
} else {

	if { ([lsearch $temp_options Include_Ethernet.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_Ethernet.VALUE] + 1]] == true) } {
     apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "New Clocking Wizard (100 MHz)" }  [get_bd_cells microblaze_0]
	} else {
	   apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config {local_mem "64KB" ecc "None" cache "None" debug_module "Debug Only" axi_periph "Enabled" axi_intc "0" clk "New Clocking Wizard (100 MHz)" }  [get_bd_cells microblaze_0]
	}
   apply_board_connection -board_interface "$sys_diff_clock" -ip_intf "/clk_wiz_1/CLK_IN1_D" -diagram $design_name 
	 if {[get_board_components -filter {SUB_TYPE==system_reset}] != ""} {
      apply_board_connection -board_interface "$reset" -ip_intf "/clk_wiz_1/reset" -diagram $design_name 
      apply_board_connection -board_interface "$reset" -ip_intf "/rst_clk_wiz_1_100M/ext_reset" -diagram $design_name
	 } else {
	    set_property -dict [list CONFIG.USE_RESET {false}] [get_bd_cells clk_wiz_1]
	 }
}

if { ([lsearch $temp_options Include_UART.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_UART.VALUE] + 1]] == true) } {
   create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0
	 set rs232_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==uart}] 0]]
	
	
   apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_uartlite_0/S_AXI]
   
   
   
   
   apply_board_connection -board_interface $rs232_interface -ip_intf "axi_uartlite_0/UART" -diagram $design_name 

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
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_gpio_[expr $gpio_if_cnt/2]/S_AXI]
      apply_board_connection -board_interface [get_board_part_interfaces -filter OF_COMPONENT==[get_property COMPONENT_NAME [get_board_components -filter ${new_item} -of_objects [current_board]] ]] -ip_intf "axi_gpio_[expr $gpio_if_cnt/2]/GPIO" -diagram $design_name
    } else {

    apply_board_connection -board_interface [get_board_part_interfaces -filter OF_COMPONENT==[get_property COMPONENT_NAME [get_board_components -filter ${new_item} -of_objects [current_board]] ]] -ip_intf "axi_gpio_[expr (($gpio_if_cnt - 1)/2)]/GPIO2" -diagram $design_name
    }
  }
}

if { ([lsearch $temp_options Local_memory.VALUE] != -1) } {
   set local_memory [lindex $temp_options [expr [lsearch $temp_options Local_memory.VALUE] + 1]]
   set_property range $local_memory [get_bd_addr_segs {microblaze_0/Data/SEG_dlmb_bram_if_cntlr_Mem}]
   set_property range $local_memory [get_bd_addr_segs {microblaze_0/Instruction/SEG_ilmb_bram_if_cntlr_Mem}]
}
if { ([lsearch $temp_options Instruction_Cache.VALUE] != -1) } {
set_property CONFIG.C_CACHE_BYTE_SIZE [expr [string trim [lindex $temp_options [expr [lsearch $temp_options Instruction_Cache.VALUE] + 1]] K]*1024] [get_bd_cells microblaze_0]
}

if { ([lsearch $temp_options Data_Cache.VALUE] != -1) } {
set_property CONFIG.C_DCACHE_BYTE_SIZE [expr [string trim [lindex $temp_options [expr [lsearch $temp_options Data_Cache.VALUE] + 1]] K]*1024] [get_bd_cells microblaze_0]
}

if { ([lsearch $temp_options Include_Ethernet.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_Ethernet.VALUE] + 1]] == true) } {
  if { [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [current_board]] != ""} {
	   create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_0
		 set ethernet_component [get_property COMPONENT_NAME [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [current_board]]]
		 set ethernet_if [get_board_component_modes -of_objects [get_board_components *$ethernet_component* -of_objects [current_board]]]
		 puts "$ethernet_if"
		 if { ([lsearch $temp_options Include_Ethernet_Interface.VALUE] != -1) } {
		 set board_interfaces_all [get_property INTERFACES [get_board_component_modes -of_objects [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [current_boar]]]]
		 puts "$board_interfaces_all"
		 if { [llength [lindex $board_interfaces_all 0] ] > 1} {
				set board_interfaces [lindex $board_interfaces_all [lsearch $ethernet_if [lindex $temp_options [expr [lsearch $temp_options Include_Ethernet_Interface.VALUE] + 1]]]]
				} else {
				set board_interfaces $board_interfaces_all
				}     				
     puts "$board_interfaces"	
     } else {
		 set board_interfaces_all [get_property INTERFACES [get_board_component_modes -of_objects [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [current_board]]]]
		 
		 set board_interfaces [lindex [get_property INTERFACES [get_board_component_modes -of_objects [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [current_board]]]] 0]
     puts "$board_interfaces_all"
		 if { [llength [lindex $board_interfaces_all 0] ] > 1} {
				set board_interfaces [lindex $board_interfaces_all 0]
				} else {
				set board_interfaces $board_interfaces_all
				} 
		 puts "$board_interfaces"	
		 }
		 set_property CONFIG.ETHERNET_BOARD_INTERFACE [lindex $board_interfaces 0] [get_bd_cells axi_ethernet_0]
     foreach connection $board_interfaces {
		   set myvlnv_temp [get_property VLNV [get_board_part_interfaces $connection]]
		   set myvlnv_temp1 "VLNV==\"$myvlnv_temp\""
       set myvlnv [subst $myvlnv_temp1]
			 if { [regexp $connection phy_reset_out] == 1 } {		
         apply_board_connection -board_interface $connection -ip_intf [get_bd_pins  axi_ethernet_0/phy_rst_n] -diagram $design_name
       } else {
				 if { [get_bd_intf_pins -of_objects [get_bd_cells axi_ethernet_0] -filter ${myvlnv}] !="" } {
			     apply_board_connection -board_interface $connection -ip_intf [get_bd_intf_pins -of_objects [get_bd_cells axi_ethernet_0] -filter ${myvlnv}] -diagram $design_name
			   }
       }
    }
		if { ([lsearch $temp_options Include_Ethernet_Mode.VALUE] != -1) } {
		set mode [lindex $temp_options [expr [lsearch $temp_options Include_Ethernet_Mode.VALUE] + 1]]
                #puts "$mode"
		   if { [regexp $mode "FIFO"] == 1 } {
		      apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config {FIFO_DMA "FIFO"}  [get_bd_cells axi_ethernet_0]

		      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_ethernet_0_fifo/S_AXI]
          puts "Configuring Ethernet subsystem in FIFO mode"
					set signal_detect [get_bd_pins /axi_ethernet_0/*] 
          if { [lsearch $signal_detect /axi_ethernet_0/signal_detect] != -1 } {
					
            create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0
            connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_ethernet_0/signal_detect]
						
				  } 
          set_property -dict [list CONFIG.NUM_PORTS {3}] [get_bd_cells microblaze_0_xlconcat]
          connect_bd_net [get_bd_pins microblaze_0_xlconcat/In0] [get_bd_pins axi_ethernet_0/interrupt]
          connect_bd_net [get_bd_pins microblaze_0_xlconcat/In1] [get_bd_pins axi_ethernet_0/mac_irq]
          connect_bd_net [get_bd_pins microblaze_0_xlconcat/In2] [get_bd_pins axi_ethernet_0_fifo/interrupt]				
					
       } else {
		      apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config {FIFO_DMA "DMA"}  [get_bd_cells axi_ethernet_0]
          apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_ethernet_0_dma/S_AXI_LITE]
          apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/ddr4_0/C0_DDR4_S_AXI" Clk "Auto" }  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_SG]
          apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/ddr4_0/C0_DDR4_S_AXI" Clk "Auto" }  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_MM2S]
          apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/ddr4_0/C0_DDR4_S_AXI" Clk "Auto" }  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_S2MM]
					set signal_detect [get_bd_pins /axi_ethernet_0/*] 
          if { [lsearch $signal_detect /axi_ethernet_0/signal_detect] != -1 } {				
            create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0
            connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_ethernet_0/signal_detect]						
				  }
				  set_property -dict [list CONFIG.NUM_PORTS {4}] [get_bd_cells microblaze_0_xlconcat]
          connect_bd_net [get_bd_pins microblaze_0_xlconcat/In0] [get_bd_pins axi_ethernet_0/interrupt]
          connect_bd_net [get_bd_pins microblaze_0_xlconcat/In1] [get_bd_pins axi_ethernet_0/mac_irq]
          connect_bd_net [get_bd_pins microblaze_0_xlconcat/In2] [get_bd_pins axi_ethernet_0_dma/mm2s_introut]
          connect_bd_net [get_bd_pins microblaze_0_xlconcat/In3] [get_bd_pins axi_ethernet_0_dma/s2mm_introut]		
					
		   }
    } else {
        apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config {FIFO_DMA "FIFO"}  [get_bd_cells axi_ethernet_0]
        apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_ethernet_0_fifo/S_AXI]
				set signal_detect [get_bd_pins /axi_ethernet_0/*] 
        if { [lsearch $signal_detect /axi_ethernet_0/signal_detect] != -1 } {
				  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0
          connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_ethernet_0/signal_detect]	
				}
				set_property -dict [list CONFIG.NUM_PORTS {3}] [get_bd_cells microblaze_0_xlconcat]
        connect_bd_net [get_bd_pins microblaze_0_xlconcat/In0] [get_bd_pins axi_ethernet_0/interrupt]
        connect_bd_net [get_bd_pins microblaze_0_xlconcat/In1] [get_bd_pins axi_ethernet_0/mac_irq]
        connect_bd_net [get_bd_pins microblaze_0_xlconcat/In2] [get_bd_pins axi_ethernet_0_fifo/interrupt]
					
				
    }
    if { ([lsearch $temp_options Include_Ethernet.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_Ethernet.VALUE] + 1]] == true) } {
		   if { ([lsearch $temp_options Include_DDR4.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_DDR4.VALUE] + 1]] == true) } {
		      set clock_cells [get_bd_cells /*/]
		      foreach clock_cell  $clock_cells {
					  if {[get_bd_pins -filter {TYPE==clk && DIR==I} -of_objects [get_bd_cells $clock_cell]] != ""} {
		          set clock_net [get_bd_nets -of_objects [get_bd_pins -filter {TYPE==clk && DIR==I} -of_objects [get_bd_cells $clock_cell]]]
			        if { $clock_net == ""} {
			          connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins -filter {TYPE==clk && DIR==I} -of_objects [get_bd_cells $clock_cell]]
			        }
            }					 
		    }			 
			 
			 } else {
          set clock_cells [get_bd_cells /*/]
		      foreach clock_cell  $clock_cells {
					  if {[get_bd_pins -filter {TYPE==clk && DIR==I} -of_objects [get_bd_cells $clock_cell]] != ""} {
		          set clock_net [get_bd_nets -of_objects [get_bd_pins -filter {TYPE==clk && DIR==I} -of_objects [get_bd_cells $clock_cell]]]
			        if { $clock_net == ""} {
                connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins -filter {TYPE==clk && DIR==I} -of_objects [get_bd_cells $clock_cell]]
			        }
            }					 
		    }		      			 
			 }
			 
		
		}
	


	
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_ethernet_0/s_axi]

	} else {
	puts "Ethernet Interface is not available on Board"
	}
}

if { ([lsearch $temp_options Include_DDR4.VALUE] == -1) || ([lindex $temp_options [expr [lsearch $temp_options Include_DDR4.VALUE] + 1]] == true) } {
	
	set ddr_component_intf [board::get_board_component_interfaces ddr4_sdram*]
 
	
	
	set ddr_preset_name [get_property PRESETS $ddr_component_intf]
	set preset [xilinx::board::get_board_presets $ddr_preset_name]

	foreach preset_0 $preset {
		set p [list_property $preset_0 CONFIG.C0.DDR4_DataWidth]
		set data_width_c0 [get_property  $p $preset_0]
		puts $data_width_c0
		break
	}

	if {$data_width_c0 == 72} {
	puts $data_width_c0
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (333 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/ddr4_0/C0_DDR4_S_AXI_CTRL} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI_CTRL]
	}
}




validate_bd_design
set wrapper_file [make_wrapper -files [get_bd_files $design_name] -top]
add_files [list $wrapper_file]
update_compile_order -fileset sources_1 
  
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


	  set proj_dir [get_property DIRECTORY [current_project ]]
	  set proj_name [get_property NAME [current_project ]]
	  set board_name [get_property NAME [current_board_part]]
	  
	  file mkdir $proj_dir/$proj_name.srcs/constrs_1/new
	  set fd [ open $proj_dir/$proj_name.srcs/constrs_1/new/toplevel.xdc w ]

	  if { ([lsearch $options Include_DDR4.VALUE] == -1) || ([lindex $options [expr [lsearch $options Include_DDR4.VALUE] + 1]] == true) } {
				  
				  # puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */u_ddr4_infrastructure/addn_ui_clkout1}\]"	
				  # puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */u_ddr4_infrastructure/c0_ddr4_ui_clk}\]"	
				  
				  puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */addn_ui_clkout1}\]"	
				  puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}\]"					  
	     }
	

	  if { ([lsearch $options Include_Ethernet.VALUE] == -1) || ([lindex $options [expr [lsearch $options Include_Ethernet.VALUE] + 1]] == true) } {
			  
			 if {[regexp vcu108 $board_name] || [regexp kcu105 $board_name] || [regexp vcu110 $board_name]} {
					puts $fd "create_clock -period 1.6 \[get_ports sgmii_phyclk_clk_p\]"
				}
				 
			 if {[regexp vcu110 $board_name]} {
				puts $fd "set_property LOC BITSLICE_RX_TX_X1Y347 \[get_cells -hier -filter {name =~ */pcs_pma_block_i/lvds_transceiver_mw/serdes_1_to_10_ser8_i/idelay_cal}\]"
				}
			
			 if {[regexp vcu108 $board_name]} {
				puts $fd "set_property LOC BITSLICE_RX_TX_X1Y25  \[get_cells -hier -filter {name =~ */pcs_pma_block_i/lvds_transceiver_mw/serdes_1_to_10_ser8_i/idelay_cal}\]"
				}
			
			 if {[regexp kcu105 $board_name]} {
				puts $fd "set_property LOC BITSLICE_RX_TX_X1Y79  \[get_cells -hier -filter {name =~ */pcs_pma_block_i/lvds_transceiver_mw/serdes_1_to_10_ser8_i/idelay_cal}\]"
				}
				
	    }  
		close $fd
		add_files  -fileset constrs_1 [ list "$proj_dir/$proj_name.srcs/constrs_1/new/toplevel.xdc" ] 


}
