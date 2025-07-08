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
	 #return [get_parts -filter {NAME =~ xcvm2152-nfvm1369-1LP-e-S || NAME =~ xc2ve3858-ssva2112-1LP-e-S}]
}

proc getSupportedBoards {} {
   set V_board_unique [get_board_parts -filter {(BOARD_NAME =~"*vek280*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vrk160*" && VENDOR_NAME=="xilinx.com")} -latest_file_version]
	return $V_board_unique
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.PART} {
	lappend x [dict create name "Design_type" type "string" value "Base" value_list {"Base" "Extensible"} enabled true]
	lappend x [dict create name "seg_config" type "bool" value "true" enabled true]
	lappend x [dict create name "Clock_Options" type "string" value "clk_out1 625 0 true clk_out2 100 1 false" enabled true]
	lappend x [dict create name "Include_AIE" type "bool" value "true" enabled true]
	lappend x [dict create name "IRQS" type "string" value "15" value_list {"15 15_AXI_Masters_and_Interrupts,_Single_Interrupt_Controller" "32 32_AXI_Masters_and_Interrupts,_Single_Interrupt_Controller" "63 63_AXI_Masters_and_Interrupts,_Cascaded_Interrupt_Controller"} enabled true]

	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page -name "Page1" -display_name "Configurations" -designObject $designObj -layout vertical]

	ced::add_param -name Design_type -display_name "Design Type" -parent $page -designObject $designObj -widget radioGroup
	
	set scg [ced::add_group -name "Segmented Configuration" -display_name "Project is a Segmented Configuration project"  -parent $page -visible true -designObject $designObj ]
	ced::add_param -name seg_config -display_name "Segmented Configuration" -parent $scg -designObject $designObj -widget checkbox
	
	set clocks [ced::add_group -name "Clocks" -display_name "Clocks"  -parent $page -visible false -designObject $designObj ]
	ced::add_custom_widget -name widget_Clocks -hierParam Clock_Options -class_name PlatformClocksWidget -parent $clocks $designObj
   
	set text "Note: The requested clock frequencies are not validated until the design is generated. Any restrictions from the Clocking Wizard will be applied 
	during generation. After the design is created, please review the \"Message\" window to ensure the requested clock frequencies were properly generated. 
	The specified Default Clock will drive all IPs created by this wizard. Higher clock frequencies may pose challenges during Timing Closure. 
	For boards with an AI Engine, it\’s recommended to use clock frequencies derived from the AIE clock (1250 MHz) for the programmable logic (PL).
	On selecting 625MHz default clk, MBUFGCE is enabled in clocking wizard to generate 625Mhz, 312.5MHz, 156.25 MHz and 78.125 MHz as derived clocks.
	When 625MHz is default clk_out2 must be enabled."
    ced::add_text -designObject $designObj -name Note -tclproc $text  -parent $clocks
	
	ced::add_param -name IRQS -display_name "AXI Masters and Interrupts" -parent $page -visible false -designObject $designObj -widget radioGroup
	 
	set aie [ced::add_group -name "AIE_Block" -display_name "AIE Block"  -parent $page -visible true -designObject $designObj ]
	ced::add_param -name Include_AIE -display_name "AIE" -parent $aie -designObject $designObj -widget checkbox
}

gui_updater {Design_type.VALUE} {Clocks.VISIBLE IRQS.VISIBLE AIE_Block.VISIBLE} {
	if {[regexp "Base" ${Design_type.VALUE}]} {
		set Clocks.VISIBLE false
		set IRQS.VISIBLE false
		#set AIE_Block.VISIBLE true
	} else {
		set Clocks.VISIBLE true
		set IRQS.VISIBLE true
		#set AIE_Block.VISIBLE true
	}
}
