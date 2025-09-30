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

proc getSupportedParts {} {
	 return ""
}

proc getSupportedBoards {} {
   set V_board_unique [get_board_parts -filter {(BOARD_NAME =~"*vek280*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vek385*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vrk160*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vrk165*" && VENDOR_NAME=="xilinx.com")} -latest_file_version]
	return $V_board_unique
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "Design_type" type "string" value "Base" value_list {"Base" "Extensible"} enabled true]
	#lappend x [dict create name "seg_config" type "bool" value "true" enabled true]
	lappend x [dict create name "Include_AIE" type "bool" value "true" enabled true]
	lappend x [dict create name "bufg_clk" type "string" value "100"  enabled true]
	lappend x [dict create name "mbufgce_clk" type "string" value "625"  enabled true]

	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page -name "Page1" -display_name "Configurations" -designObject $designObj -layout vertical]

	ced::add_param -name Design_type -display_name "Design Type" -parent $page -designObject $designObj -widget radioGroup
	
	#set scg [ced::add_group -name "Segmented Configuration" -display_name "Project is a Segmented Configuration project"  -parent $page -visible true -designObject $designObj ]
	#ced::add_param -name seg_config -display_name "Segmented Configuration" -parent $scg -designObject $designObj -widget checkbox
		
	set clocks [ced::add_group -name "clocks" -display_name "Clocks"  -parent $page -visible true -designObject $designObj ]
    ced::add_param -name bufg_clk -display_name "BUFG CLK" -parent $clocks -visible true -designObject $designObj -widget textEdit
	ced::add_param -name mbufgce_clk -display_name "MBUFGCE CLK" -parent $clocks -visible false -designObject $designObj -widget textEdit
	
	set text1 "Note: The requested clock frequencies are not validated until the design is generated. Any restrictions from Clocking Wizard will be applied 
	during generation. After design is created, please review the \"Message\" window to ensure the requested clock frequencies were properly generated. 
	Higher clock frequencies may pose challenges during Timing Closure."
    ced::add_text -visible true -name Note1 -tclproc $text1 -parent $clocks -designObject $designObj  
	
	set text2 "Note: The requested clock frequencies are not validated until the design is generated. Any restrictions from Clocking Wizard will be applied 
	during generation. After design is created, please review the \"Message\" window to ensure the requested clock frequencies were properly generated. 
	Higher clock frequencies may pose challenges during Timing Closure. In extensible design type multiple synchronous logical clocks are derived from 
	MBUFGCE output clock Ex - 625Mhz, 312.5MHz, 156.25 MHz and 78.125 MHz. clk_out1_o4 will drive all IPs."
	ced::add_text -visible false -name Note2 -tclproc $text2 -parent $clocks -designObject $designObj
	
	set aie [ced::add_group -name "AIE_Block" -display_name "AIE Block"  -parent $page -visible true -designObject $designObj ]
	ced::add_param -name Include_AIE -display_name "AIE" -parent $aie -designObject $designObj -widget checkbox
}

gui_updater {Design_type.VALUE} {clocks.VISIBLE bufg_clk.VISIBLE mbufgce_clk.VISIBLE Note1.VISIBLE Note2.VISIBLE} {
	if {[regexp "Base" ${Design_type.VALUE}]} {
		set mbufgce_clk.VISIBLE false
		set Note1.VISIBLE true
		set Note2.VISIBLE false
	} else {
		set mbufgce_clk.VISIBLE true
		set Note1.VISIBLE false
		set Note2.VISIBLE true
	}
}

gui_updater {PROJECT_PARAM.BOARD_PART} {Include_AIE.VISIBLE Include_AIE.ENABLEMENT Include_AIE.VALUE} {
	set gui_flag 0
	set board [lindex [split ${PROJECT_PARAM.BOARD_PART} ":"] 1]
	set part [get_property PART_NAME [lindex [get_board_parts *$board* -latest_file_version] 0]]
	set V_Part [debug::dump_part_properties [get_parts $part ]]
	
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
	}
}
}
