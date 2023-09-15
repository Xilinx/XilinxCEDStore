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

set currentFile [file normalize [info script]]
set currentDir [file dirname $currentFile]

source -notrace "$currentDir/setup.tcl"

proc getSupportedParts {} {
	set mylist [get_parts -filter {C_FAMILY =~ versal}]
	set newitem ""
	
	foreach item $mylist {
	
		if {![regexp "1" [[regexp "xcvp1402-vsvd2197" $item]||[regexp "xcvp1902-vsva6865" $item]]]} {
			lappend newitem $item 
		}
	}
	return $newitem
}

proc getSupportedBoards {} {
  #return [get_board_parts -filter {(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com" ) || (BOARD_NAME =~"*vmk180*" && VENDOR_NAME=="xilinx.com" )}  -latest_file_version]
  return ""; 
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.PART} {
    lappend x [dict create name "Include_LPDDR" type "bool" value "true" enabled false]
	lappend x [dict create name "Include_DDR" type "bool" value "true" enabled false]
	lappend x [dict create name "Include_AIE" type "bool" value "false" enabled true]
    lappend x [dict create name "Clock_Options" type "string" value "clk_out1 156.250000 0 true" enabled true]
    lappend x [dict create name "IRQS" type "string" value "15" value_list {"15 15_AXI_Masters_and_Interrupts,_Single_Interrupt_Controller" "32 32_AXI_Masters_and_Interrupts,_Single_Interrupt_Controller" "63 63_AXI_Masters_and_Interrupts,_Cascaded_Interrupt_Controller"} enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.PART} {

    set designObj $DESIGNOBJ
    set page [ced::add_page -name "Page1" -display_name "2021.1 Configuration" -designObject $designObj -layout vertical]

    set clocks [ced::add_group -name "Clocks" -display_name "Clocks"  -parent $page -visible true -designObject $designObj ]
    ced::add_custom_widget -name widget_Clocks -hierParam Clock_Options -class_name PlatformClocksWidget -parent $clocks $designObj
    set text "Note : The requested clock frequencies are not verified until the design is generated. Clocking wizard restrictions will be applied.
	User should check the 'Messages' window once the design is created to ensure that the selected clock frequencies are derived."
    ced::add_text -designObject $designObj -name Note -tclproc $text  -parent $clocks
	
    ced::add_param -name IRQS -display_name "AXI Masters and Interrupts" -parent $page -designObject $designObj -widget radioGroup

	# Disabling GUI option to choose additional memory. All available memories are chosen by default
	
    # set ddr [ced::add_group -name "Versal Memory Configurations" -display_name "Memory"  -parent $page -visible true -designObject $designObj ]
    # ced::add_param -name Include_DDR -display_name "DDR4(default)" -parent $ddr -designObject $designObj -widget checkbox
	# ced::add_param -name Include_LPDDR -display_name "LPDDR4" -parent $ddr -designObject $designObj -widget checkbox
	
	set aie [ced::add_group -name "AIE Block" -display_name "AIE Block"  -parent $page -visible true -designObject $designObj]
	ced::add_param -name Include_AIE -display_name "AIE" -parent $aie -designObject $designObj -widget checkbox
	
	
}

# validater { parameters_used } { parameters_modified} { functionality }
validater { Clock_Options.VALUE } { Clock_Options.ERRMSG } {
    set clk_options ${Clock_Options.VALUE}
    set clk_ports {}
    set clk_freqs {}
    set clk_ids {}
    set clk_defaults {}

    set i 0
    foreach { port freq id is_default } $clk_options {
        lappend clk_ports $port
        lappend clk_freqs $freq
        lappend clk_ids $id
        lappend clk_defaults $is_default
        incr i
    }

    # check for well-formed port names
    foreach { port } [ lsort -unique $clk_ports ] {
        set result [regexp -nocase -- {^[a-z0-9_]+$} $port]
        if { !$result } {
            puts "The clock port name must be alphanumeric: $port"
        }
    }

    # check for repeated clock ports
    foreach { port } [ lsort -unique $clk_ports ] {
        set count [llength [lsearch -all $clk_ports $port]]
        if { $count > 1 } {
            puts "The clock port name is not unique: $port"
        }
    }

    # check for repeated clock ids
    foreach { id } [ lsort -unique $clk_ids ] {
        set count [llength [lsearch -all $clk_ids $id]]
        if { $count > 1 } {
            puts "Clock ID is not unique: $id"
        }
    }

    # check for repeated clock frequencies
    # UI enforces formatting (100 vs 100.000) so we can use direct string compare
    foreach { freq } [ lsort -unique $clk_freqs ] {
        set count [llength [lsearch -all $clk_freqs $freq]]
        if { $count > 1 } {
            puts "Clock frequency used more than once: $freq"
        }
    }

    # check for min/max freqs. per clocking wizard 6.0 docs PG065, this is 10-1066 MHz
    foreach { freq } $clk_freqs {
        if { [expr $freq < 10 || $freq > 1066] } {
            puts "Clock frequency $freq out of range. It must be between 10-1066 MHz."
        }
    }

    # check for exactly one default clock
    if {[ lsearch $clk_defaults true ] == -1} {
        puts "No default clock is selected."
    } elseif {[llength [lsearch -all $clk_defaults true]] > 1} {
        puts "Multiple default clocks are selected. There can be only one default clock."
    }
}

# updater {Include_LPDDR.VALUE} {Include_LPDDR.ENABLEMENT} {
  # if { ${Include_LPDDR.VALUE} == true } {
    # set Include_LPDDR.ENABLEMENT true
  # } else {
    # set Include_LPDDR.ENABLEMENT false
  # }
# }

# updater {Include_AIE.VALUE} {Include_AIE.ENABLEMENT} {
  # if { ${Include_AIE.VALUE} == true } {
    # set Include_AIE.ENABLEMENT true
  # } else {
    # set Include_AIE.ENABLEMENT false
  # }
# }

gui_updater {PROJECT_PARAM.PART} {Include_AIE.VISIBLE Include_AIE.ENABLEMENT Include_AIE.VALUE} {
	set gui_flag 0
	set V_Part [debug::dump_part_properties [get_parts ${PROJECT_PARAM.PART}]]
	
	foreach get_aie_prop $V_Part {
		if {([regexp "AIE_ENGINE" [lindex $get_aie_prop 1 ]] == 1) && ([lindex $get_aie_prop 3 ] != 0) } {
			#set Include_AIE.VISIBLE true
			set Include_AIE.ENABLEMENT true
			set Include_AIE.VALUE true
			set gui_flag 1
		} elseif {$gui_flag == 0} {
			#set Include_AIE.VISIBLE false
			set Include_AIE.ENABLEMENT false
			set Include_AIE.VALUE false
			set gui_flag 0
		}
	}
}

#gui_updater {PROJECT_PARAM.PART} {Include_AIE.VISIBLE Include_AIE.ENABLEMENT Include_AIE.VALUE} {
#set aie [get_property FAMILY [get_parts ${PROJECT_PARAM.PART}]]
#if { [regexp "qrversalaicore" ${aie}]||[regexp "versalaicore" ${aie}]||[regexp "versalaiedge" ${aie}]||[regexp "qversalaicore" ${aie}]} {
#      #set Include_AIE.VISIBLE true
#	  set Include_AIE.ENABLEMENT true
#	  set Include_AIE.VALUE true
#    } else {
#      #set Include_AIE.VISIBLE false	 
#	  set Include_AIE.ENABLEMENT false
#	  set Include_AIE.VALUE false
#   }
#
#}

gui_updater {PROJECT_PARAM.PART} {Include_DDR.VALUE Include_DDR.ENABLEMENT} {
	if { ${Include_DDR.VALUE} == true } {
		set Include_DDR.ENABLEMENT false
		set Include_DDR.VALUE true
		set Include_LPDDR.VALUE true
	}
}