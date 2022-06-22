# ########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

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

source -notrace "$currentDir/run.tcl"
# *******************User defined proc (filter versal latest board parts )****************************
proc get_latest_board_parts {} {
set Versal_board [get_property BOARD_NAME [get_boards -filter {(DISPLAY_NAME =~"*Versal*" && VENDOR_NAME=="xilinx.com" )}]]
set Versal_board_unique [lsort -unique $Versal_board]
set Versal_boardparts ""



foreach v_part $Versal_board_unique {
lappend Versal_boardparts [get_board_parts *${v_part}:part0* -latest_file_version]
}
set V_board_unique [lsort -unique $Versal_boardparts]
return $V_board_unique
}
# ****************************************************************************************************

proc getSupportedParts {} {
	 return ""
}

proc getSupportedBoards {} {
  return [get_latest_board_parts]
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    lappend x [dict create name "Include_LPDDR" type "bool" value "false" enabled true]
	lappend x [dict create name "Include_DDR" type "bool" value "true" enabled true]
	lappend x [dict create name "Include_AIE" type "bool" value "false" enabled true]
    lappend x [dict create name "Clock_Options" type "string" value "clk_out1 200.000 0 true clk_out2 100.000 1 false clk_out3 300.000 2 false" enabled true]
    lappend x [dict create name "IRQS" type "string" value "32" value_list {"32 32_Interrupts,_single_interrupt_controller" "63 63_interrupts,_cascaded_interrupt_controller"} enabled true]
    return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page -name "Page1" -display_name "2021.1 Configuration" -designObject $designObj -layout vertical]

    set clocks [ced::add_group -name "Clocks" -display_name "Clocks"  -parent $page -visible true -designObject $designObj ]
    ced::add_custom_widget -name widget_Clocks -hierParam Clock_Options -class_name PlatformClocksWidget -parent $clocks $designObj
    set text "Note : The requested clock frequecies are not verified until the design is generated. Clocking wizard restrictions will be applied.
    User should check the 'Messages' window once the design is created to ensure that the supported clock frequencies are derived."
    ced::add_text -designObject $designObj -name Note -tclproc $text  -parent $clocks

    ced::add_param -name IRQS -display_name "Interrupts" -parent $page -designObject $designObj -widget radioGroup

    set ddr [ced::add_group -name "Versal Memory Configurations" -display_name "Memory"  -parent $page -visible true -designObject $designObj ]
    ced::add_param -name Include_DDR -display_name "Memory (Includes DDR4/LPDDR4 available on the board)" -parent $ddr -designObject $designObj -widget checkbox
	ced::add_param -name Include_LPDDR -display_name "Additional Memory (Includes remaining DDR4/LPDDR4 available on the board)" -parent $ddr -designObject $designObj -widget checkbox
	
	set aie [ced::add_group -name "AIE Block" -display_name "AIE Block"  -parent $page -visible true -designObject $designObj ]
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
set aie [get_property FAMILY [get_parts ${PROJECT_PARAM.PART}]]
if { [regexp "qrversalaicore" ${aie}]||[regexp "versalaicore" ${aie}]||[regexp "versalaiedge" ${aie}]||[regexp "qversalaicore" ${aie}]} {
      #set Include_AIE.VISIBLE true
	  set Include_AIE.ENABLEMENT true
	  set Include_AIE.VALUE true
    } else {
      #set Include_AIE.VISIBLE false	 
	  set Include_AIE.ENABLEMENT false
	  set Include_AIE.VALUE false
    }
}

gui_updater {PROJECT_PARAM.PART} {Include_DDR.VALUE Include_DDR.ENABLEMENT} {
  if { ${Include_DDR.VALUE} == true } {
    set Include_DDR.ENABLEMENT false
	set Include_DDR.VALUE true
  }
}