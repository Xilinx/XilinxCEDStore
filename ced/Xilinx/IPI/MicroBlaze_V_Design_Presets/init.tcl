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
variable currentDir [file dirname $currentFile]

source -notrace "$currentDir/run.tcl"

# proc getConfigDesignInfo {} {
  # return [dict create name {CED 7_series} description {MicroBlaze system with peripherals including UART and DDR4}]
# }

proc getSupportedParts {} {
	 return ""
}

proc getSupportedBoards {} {
  #return [get_board_parts -filter {(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com" ) || (BOARD_NAME =~"*vmk180*" && VENDOR_NAME=="xilinx.com" )}  -latest_file_version]
  # return [get_board_parts -filter {(PART_NAME!~"*xc7z*" && PART_NAME!~"*xcvc*" && PART_NAME!~"*xcvm*" && PART_NAME!~"*xcvp*" &&  PART_NAME!~"*xczu*" && VENDOR_NAME=="xilinx.com")} -latest_file_version]
  return [get_board_parts -filter {(DISPLAY_NAME =~"*Kintex*" || DISPLAY_NAME =~"*Artix*" || DISPLAY_NAME =~"*Virtex*" || DISPLAY_NAME =~"*Spartan*" && VENDOR_NAME=="xilinx.com" )} -latest_file_version]
}


# proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	# lappend x [dict create name "Preset" type "string" value "Microcontroller" value_list {"Microcontroller Microcontroller___Suitable_for_running_baremetal_code" "Real-time_Processor Real-time____________Deterministic_real-time_processing_on_RTOS" "Application_Processor Application_________Embedded_linux_capable"} enabled true]
	# return $x
# }

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {

	if {[regexp "ac701" ${PROJECT_PARAM.BOARD_PART}]||[regexp "sp701" ${PROJECT_PARAM.BOARD_PART}]} {
	lappend x [dict create name "Preset" type "string" value "Microcontroller" value_list {"Microcontroller Microcontroller___Suitable_for_running_baremetal_code"} enabled true]
	
	} else {
	
	lappend x [dict create name "Preset" type "string" value "Microcontroller" value_list {"Microcontroller Microcontroller___Suitable_for_running_baremetal_code" "Real-time_Processor Real-time____________Deterministic_real-time_processing_on_RTOS"} enabled true]
	}
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
	ced::add_param -name Preset -parent $page -designObject $designObj  -widget radioGroup 
    set imageVar [ced::add_image -name Image -parent $page -designObject $designObj -width 500 -height 300 -layout vertical]
}


 updater {PROJECT_PARAM.BOARD_PART Preset.VALUE} {Image.IMAGE_PATH Preset.ENABLEMENT Preset.DISPLAYNAME} {
  set Preset.DISPLAYNAME "Microblaze V Preset Configurations"
  if { ${Preset.VALUE} == "Application_Processor"} {
     set Preset.ENABLEMENT true
     set Image.IMAGE_PATH "mb_v_app.png"
  } elseif { ${Preset.VALUE} == "Microcontroller"} {
	 set Preset.ENABLEMENT true
	 set Image.IMAGE_PATH "mb_v_micro.png"
  } elseif { ${Preset.VALUE} == "Real-time_Processor" } {
	 set preset.ENABLEMENT true
	 set Image.IMAGE_PATH "mb_v_real.png"
  }
}


