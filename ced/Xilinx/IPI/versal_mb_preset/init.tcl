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
variable currentDir [file dirname $currentFile]
source -notrace "$currentDir/run.tcl"

# proc getConfigDesignInfo {} {
  # return [dict create name {CED 7_series} description {MicroBlaze system with peripherals including UART and DDR4}]
# }
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
	lappend x [dict create name "Preset" type "string" value "Microcontroller" value_list {"Microcontroller" "Application"} enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
	ced::add_param -name Preset -parent $page -designObject $designObj  -widget radioGroup 
    set imageVar [ced::add_image -name Image -parent $page -designObject $designObj -width 780 -height 400 -layout vertical ]
}


 updater {PROJECT_PARAM.BOARD_PART Preset.VALUE} {Image.IMAGE_PATH Preset.ENABLEMENT Preset.DISPLAYNAME} {
  set Preset.DISPLAYNAME "Microblaze Versal Preset Configurations"
  if { ${Preset.VALUE} == "Application"} {
     set Preset.ENABLEMENT true
     set Image.IMAGE_PATH "versal_mb_app.png"
  } elseif { ${Preset.VALUE} == "Microcontroller"} {
	 set Preset.ENABLEMENT true
	set Image.IMAGE_PATH "versal_mb_micro.png"
  # } elseif { ${Preset.VALUE} == "Real-time/Application" } {
	 # set preset.ENABLEMENT true
	 # set Image.IMAGE_PATH "microblaze-real-time-processor.png"
  # }
}


