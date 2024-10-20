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

    lappend x [dict create name "Include_LPDDR" type "bool" value "true" enabled false]
	lappend x [dict create name "Include_DDR" type "bool" value "true" enabled true]
	lappend x [dict create name "Include_AIE" type "bool" value "false" enabled true]
	
	if {[regexp "vck190" ${PROJECT_PARAM.BOARD_PART}]||[regexp "vek280" ${PROJECT_PARAM.BOARD_PART}]} {
    lappend x [dict create name "Clock_Options" type "string" value "clk_out1 625 0 true" enabled true]
	} else {
	    lappend x [dict create name "Clock_Options" type "string" value "clk_out1 200 0 true" enabled true]
	}
    lappend x [dict create name "IRQS" type "string" value "15" value_list {"15 15_AXI_Masters_and_Interrupts,_Single_Interrupt_Controller" "32 32_AXI_Masters_and_Interrupts,_Single_Interrupt_Controller" "63 63_AXI_Masters_and_Interrupts,_Cascaded_Interrupt_Controller"} enabled true]
	lappend x [dict create name "Include_BDC" type "bool" value "false" enabled true]
    return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page -name "Page1" -display_name "Versal_ext_platform Configuration" -designObject $designObj -layout vertical]

    set clocks [ced::add_group -name "Clocks" -display_name "Clocks"  -parent $page -visible true -designObject $designObj ]
	ced::add_custom_widget -name widget_Clocks -hierParam Clock_Options -class_name PlatformClocksWidget -parent $clocks $designObj

	set text "Note: The requested clock frequencies are not validated until the design is generated. Any restrictions from the Clocking Wizard will be applied 
	during generation. After the design is created, please review the \"Message\" window to ensure the requested clock frequencies were properly generated. 
	The specified Default Clock will drive all IPs created by this wizard. Higher clock frequencies may pose challenges during Timing Closure. 
	For boards with an AI Engine, it’s recommended to use clock frequencies derived from the AIE clock (1250 MHz) for the programmable logic (PL)
	When 625MHz is selected as default, MBUFGCE is enabled in clocking wizard and 312.5MHz derived clock is used for connecting all the blocks."
    ced::add_text -designObject $designObj -name Note -tclproc $text  -parent $clocks

	set bdc [ced::add_group -name "BDC Block" -display_name "Select \"BDC\" to create Block Design Container based design"  -parent $page -visible true -designObject $designObj ]
	ced::add_param -name Include_BDC -display_name "BDC" -parent $bdc -designObject $designObj -widget checkbox

    ced::add_param -name IRQS -display_name "AXI Masters and Interrupts" -parent $page -designObject $designObj -widget radioGroup

	# Disabling GUI option to choose additional memory. All available memories are chosen by default
   
	# set ddr [ced::add_group -name "Versal Memory Configurations" -display_name "Memory"  -parent $page -visible true -designObject $designObj ]
    # ced::add_param -name Include_DDR -display_name "Memory (Includes DDR4/LPDDR4 available on the board)" -parent $ddr -designObject $designObj -widget checkbox
	# ced::add_param -name Include_LPDDR -display_name "Additional Memory (Includes remaining DDR4/LPDDR4 available on the board)" -parent $ddr -designObject $designObj -widget checkbox
	
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
			set Clock_Options.ERRMSG "Found multiple clock ports with same port name. Please set unique name for each clock port."
        }
    }

    # check for repeated clock ids
    foreach { id } [ lsort -unique $clk_ids ] {
        set count [llength [lsearch -all $clk_ids $id]]
        if { $count > 1 } {
            puts "Clock ID is not unique: $id"
			set Clock_Options.ERRMSG "Found multiple clock ports with same clock ID. Please set unique clock ID for each clock port."
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

# gui_updater {PROJECT_PARAM.BOARD_PART} {Include_DDR.VALUE Include_DDR.ENABLEMENT} {

	# if { ${Include_DDR.VALUE} == true } {
		# set Include_DDR.ENABLEMENT false
		# set Include_DDR.VALUE true
	# }
	
# }

gui_updater {PROJECT_PARAM.BOARD_PART} {Include_BDC.VALUE Include_BDC.ENABLEMENT} {

	if {[regexp "vck190" ${PROJECT_PARAM.BOARD_PART}]||[regexp "vek280" ${PROJECT_PARAM.BOARD_PART}]} {
		set Include_BDC.ENABLEMENT true
		#set Include_BDC.VALUE true
	} else {
		set Include_BDC.ENABLEMENT false
	}	
	
}
