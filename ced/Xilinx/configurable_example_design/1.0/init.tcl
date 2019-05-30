
set currentFile [file normalize [info script]]
set currentDir [file dirname $currentFile]

source -notrace "$currentDir/microblaze.tcl"

proc getConfigDesignInfo {} {
  return [dict create name {Base MicroBlaze} description {MicroBlaze system with peripherals including UART and DDR4.}]
}

proc getSupportedParts {} {
   return ""
}

proc getSupportedBoards {} {
    #return [get_board_parts -filter { ((PART_NAME =~"*xc*u*" && PART_NAME !~"*xczu*") && (PART_NAME !~"*xcku115*")) || ((PART_NAME =~"*XC*U*" && PART_NAME !~"*XCZU*") && (PART_NAME !~"*XCKU115*")) && BOARD_NAME!~*adm-pcie-7v3*} -latest_file_version]
	return [get_board_parts -filter { (PART_NAME =~"*xc*u*" && PART_NAME !~"*xczu*" && VENDOR_NAME=="xilinx.com" ) || (PART_NAME =~"*XC*U*" && PART_NAME !~"*XCZU*" && VENDOR_NAME=="xilinx.com")} -latest_file_version]
    }
proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  
   lappend x [dict create name "Local_memory" type "string" value "64K" value_list { 4K 8K 16K 32K 64K 128K } enabled true] 
   lappend x [dict create name "Data_Cache" type "string" value "8" value_list { 4K 8K 16K 32K 64K } enabled true]
   lappend x [dict create name "Instruction_Cache" type "string" value "8" value_list { 4K 8K 16K 32K 64K } enabled true]
   lappend x [dict create name "Include_DDR4" type "bool" value "true" enabled true]
   lappend x [dict create name "Include_UART" type "bool" value "true" enabled true]
   lappend x [dict create name "Include_GPIO" type "bool" value "true" enabled true]
   lappend x [dict create name "Include_AXI_Type" type "string" value "Smartconnect" value_list {Smartconnect Interconnect} enabled true]

   lappend x [dict create name "Include_UART_BAUD" type "string" value "9600" value_list { 4800 9600 19200 38400 57600 115200 128000 230400 } enabled true]
   lappend x [dict create name "Include_UART_DATA" type "long" value "8" min_value "5" max_value "8" enabled true] 
   lappend x [dict create name "Include_UART_PARITY" type "string" value "No" value_list {No Odd Even}  enabled true] 
   if {${PROJECT_PARAM.BOARD_PART} != "" } {
	 puts ${PROJECT_PARAM.BOARD_PART}
   set gpio_switch_if [get_property DISPLAY_NAME [get_board_components -filter {SUB_TYPE==switch || SUB_TYPE==led || SUB_TYPE==push_button } -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]]
   foreach item $gpio_switch_if {
     lappend x [dict create name "Include_[regsub " " $item {_}]" type "bool" value "true" enabled true]
   }
	 lappend x [dict create name "Include_Ethernet" type "bool" value "true" enabled true]
	 lappend x [dict create name "Include_Ethernet_options" type "bool" value "true" enabled true]
   if { [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]] != ""} {
         set ethernet_component [get_property COMPONENT_NAME [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]]
         set ethernet_if [get_board_component_modes -of_objects [get_board_components *$ethernet_component* -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]]
	 lappend x [dict create name "Include_Ethernet_Interface" type "string" value [lindex $ethernet_if 0] value_list "$ethernet_if" enabled true] 
	 } else {
	 lappend x [dict create name "Include_Ethernet_Interface" type "string" value "NULL" enabled flase] 
	 }
	 lappend x [dict create name "Include_Ethernet_Mode" type "string" value "FIFO" value_list {DMA FIFO} enabled true]
   }
	 return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  set designObj $DESIGNOBJ
  #place to define GUI layout for options
  set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout horizontal]
  set left_panel [ced::add_panel -name left_panel -parent $page -designObject $designObj]
  set right_panel [ced::add_panel -name right_panel -parent $page -designObject $designObj]
   
  set group1 [ced::add_group -name "Microblaze_Options" -display_name "MicroBlaze"  -parent $left_panel -designObject $designObj]
  ced::add_param -name Local_memory -display_name "Local Memory" -parent $group1 -designObject $designObj -widget comboBox

  set group2 [ced::add_group -name "Cache_Options" -display_name "Cache"  -parent $group1 -designObject $designObj]
  ced::add_param -name Data_Cache -display_name "Data Cache" -parent $group2 -designObject $designObj -widget comboBox
  ced::add_param -name Instruction_Cache -display_name "Instruction Cache" -parent $group2 -designObject $designObj -widget comboBox
  
  set combinedPanel [ced::add_panel -name combinedPanel -parent $right_panel -designObject $designObj] 
  ced::add_param -name Include_DDR4  -parent $combinedPanel -designObject $designObj
  ced::add_param -name Include_AXI_Type  -parent $combinedPanel -designObject $designObj -layout horizontal

	set panel [ced::add_panel -name panel1 -parent $combinedPanel -designObject $designObj]
	#ced::add_param -name Include_Ethernet  -parent $panel -designObject $designObj
	#if { [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]] != ""} {
	set group3 [ced::add_group -name "Ethernet_Options" -display_name "Ethernet Options" -parent $panel -designObject $designObj -visible true -header_param "Include_Ethernet"]
	ced::add_param -name Include_Ethernet_Interface -display_name "Interface" -parent $group3 -designObject $designObj -widget comboBox
	ced::add_param -name Include_Ethernet_Mode -display_name "Mode" -parent $group3 -designObject $designObj -widget comboBox
	#}
		
	#set panel [ced::add_panel -name panel2 -parent $combinedPanel -designObject $designObj -layout horizontal]
 
	#set GPIOPanel [ced::add_panel -name combinedPanel -parent $page -designObject $designObj] 
	set gpioGroup [ced::add_group -name "General Purpose IOs" -display_name "General Purpose IOs"  -parent $left_panel -designObject $designObj ]	
  set gpio_switch_if [get_property DISPLAY_NAME [get_board_components -filter {SUB_TYPE==switch || SUB_TYPE==led || SUB_TYPE==push_button } -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]]
  foreach item $gpio_switch_if {
    ced::add_param -name Include_[regsub " " $item {_}]  -display_name "$item" -parent $gpioGroup -designObject $designObj
  }
 
  set group4 [ced::add_group -name "UART_Options" -display_name "UART Options"  -parent $right_panel -designObject $designObj -visible true -header_param "Include_UART"]
  ced::add_param -name Include_UART_BAUD -display_name "Baud Rate" -parent $group4 -designObject $designObj -widget comboBox
  ced::add_param -name Include_UART_DATA -display_name "Data Bits" -parent $group4 -designObject $designObj 
  ced::add_param -name Include_UART_PARITY -display_name "Parity" -parent $group4 -designObject $designObj -widget comboBox
	
}

updater {PROJECT_PARAM.BOARD_PART} {Include_UART.DISPLAYNAME Include_DDR4.DISPLAYNAME Include_Ethernet.DISPLAYNAME Include_AXI_Type.DISPLAYNAME} {
  set Include_UART.DISPLAYNAME "UART"
  set Include_DDR4.DISPLAYNAME "DDR4"
  set Include_Ethernet.DISPLAYNAME "Ethernet"
  set Include_AXI_Type.DISPLAYNAME "Interconnect IP"
}

updater {Include_UART.VALUE} {Include_UART_BAUD.ENABLEMENT Include_UART_DATA.ENABLEMENT Include_UART_PARITY.ENABLEMENT} {
  if { ${Include_UART.VALUE} == true } {
     set Include_UART_BAUD.ENABLEMENT true
     set Include_UART_DATA.ENABLEMENT true
     set Include_UART_PARITY.ENABLEMENT true
  } else {
    set Include_UART_BAUD.ENABLEMENT false 
    set Include_UART_DATA.ENABLEMENT false 
    set Include_UART_PARITY.ENABLEMENT false 
  }
}





updater {Include_Ethernet.VALUE Include_DDR4.VALUE} {Include_Ethernet_Interface.ENABLEMENT Include_Ethernet_Mode.VALUE Include_Ethernet_Mode.ENABLEMENT} {
  if { ${Include_Ethernet.VALUE} == true } {
     set Include_Ethernet_Interface.ENABLEMENT true
     set Include_Ethernet_Mode.ENABLEMENT true
     if { ${Include_DDR4.VALUE} == false } {
       set Include_Ethernet_Mode.VALUE FIFO
       set Include_Ethernet_Mode.ENABLEMENT false
       puts "Ethernet enablement mode"
     }

  } else {
    set Include_Ethernet_Interface.ENABLEMENT false 
    set Include_Ethernet_Mode.ENABLEMENT false
  }
}

updater {Include_DDR4.VALUE} {Data_Cache.ENABLEMENT Instruction_Cache.ENABLEMENT} {
  if { ${Include_DDR4.VALUE} == true } {
    set Data_Cache.ENABLEMENT true
    set Instruction_Cache.ENABLEMENT true
  } else {
    set Data_Cache.ENABLEMENT false
    set Instruction_Cache.ENABLEMENT false
  }
}


updater {Include_DDR4.VALUE} {Include_AXI_Type.ENABLEMENT} {
  if { ${Include_DDR4.VALUE} == true } {
    set Include_AXI_Type.ENABLEMENT true
  } else {
    set Include_AXI_Type.ENABLEMENT false
  }
}

#gui_updater {Include_DDR4.VALUE} {Include_Ethernet_Mode.ENABLEMENT} {
#  if { ${Include_DDR4.VALUE} == false } {
#    set ${Include_Ethernet_Mode.ENABLEMENT} false
#    puts "Ethernet enablement mode"
#  }
#}

#updater {Include_DDR4.VALUE} {Include_Ethernet_Mode.VALUE} {
#  if { ${Include_DDR4.VALUE} == false } {
#    set Include_Ethernet_Mode.VALUE FIFO
#  } 
#}
gui_updater {PROJECT_PARAM.BOARD_PART} {Include_DDR4.VISIBLE} {
if {${PROJECT_PARAM.BOARD_PART} != "" } {
  if { [get_board_components -filter {SUB_TYPE==ddr} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]] != ""} {
    if { [lindex [get_property PARAM.ddr_type [get_board_components -filter {SUB_TYPE==ddr} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]] 0] == "ddr4" } {
      set Include_DDR4.VISIBLE true
    } else {
      set Include_DDR4.VISIBLE false
    }
   } else {
     set Include_DDR4.VISIBLE false
   }
 }
}

updater {PROJECT_PARAM.BOARD_PART} {Include_DDR4.VALUE } {
if {${PROJECT_PARAM.BOARD_PART} != "" } {
  if { [get_board_components -filter {SUB_TYPE==ddr} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]] != ""} {
    if { [lindex [get_property PARAM.ddr_type [get_board_components -filter {SUB_TYPE==ddr} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]] 0] == "ddr4" } {
      set Include_DDR4.VALUE true
    } else {
      set Include_DDR4.VALUE false
    }
} else {
     set Include_DDR4.VALUE false
   }
 }
}

gui_updater {PROJECT_PARAM.BOARD_PART} { Include_UART.VISIBLE} {
if {${PROJECT_PARAM.BOARD_PART} != "" && [get_board_components -filter {SUB_TYPE==uart} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]] != ""} {
  if { [lindex [get_property SUB_TYPE [get_board_components -filter {SUB_TYPE==uart} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]] 0] == "uart" } {
    set Include_UART.VISIBLE true
  } else {
    set Include_UART.VISIBLE false
  }
 } else {
   set Include_UART.VISIBLE false
 }
 }

updater {PROJECT_PARAM.BOARD_PART} {Include_UART.VALUE } {
if {${PROJECT_PARAM.BOARD_PART} != "" && [get_board_components -filter {SUB_TYPE==uart} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]] != ""} {
  if { [lindex [get_property SUB_TYPE [get_board_components -filter {SUB_TYPE==uart} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]] 0] == "uart" } {
    set Include_UART.VALUE true
  } else {
    set Include_UART.VALUE false
  }
 } else {
   set Include_UART.VALUE false
 }
}

gui_updater {PROJECT_PARAM.BOARD_PART} { Include_Ethernet.VISIBLE} {
if {${PROJECT_PARAM.BOARD_PART} != "" && [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]] != ""} {
  if { [lindex [get_property SUB_TYPE [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]] 0] == "ethernet" } {
    set Include_Ethernet.VISIBLE true
  } else {
    set Include_Ethernet.VISIBLE false
  }
 } else {
   set Include_Ethernet.VISIBLE false
 }
 }

updater {PROJECT_PARAM.BOARD_PART} {Include_Ethernet.VALUE } {
if {${PROJECT_PARAM.BOARD_PART} != "" && [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]] != ""} {
  if { [lindex [get_property SUB_TYPE [get_board_components -filter {SUB_TYPE==ethernet} -of_objects [get_boards [regsub "(part.*:)" ${PROJECT_PARAM.BOARD_PART} {}]]]] 0] == "ethernet" } {
    set Include_Ethernet.VALUE true
  } else {
    set Include_Ethernet.VALUE false
  }
 } else {
   set Include_Ethernet.VALUE false
 }
}

 
