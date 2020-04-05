# ########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

#      http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]

source -notrace "$currentDir/zynq7000_preset.tcl"

# proc getConfigDesignInfo {} {
  # return [dict create name {CED 7_series} description {MicroBlaze system with peripherals including UART and DDR4}]
# }

proc getSupportedParts {} {
	 return ""
}

proc getSupportedBoards {} {
  #return [get_board_parts -filter {(PART_NAME!~"*xc7z*" &&  PART_NAME!~"*xczu*" && VENDOR_NAME=="xilinx.com") }  -latest_file_version]
   return [get_board_parts -filter {PART_NAME=~"*xc7z*" && VENDOR_NAME=="xilinx.com"} -latest_file_version]
}


proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "Preset" type "string" value "PS7_Only" value_list { "PS7_Only Processing_System(PS)" "PS7_PL Processing_System_and_Programmable_Logic_(PS+PL)_with_GPIO_and_Block_RAM" } enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]
        ced::add_param -name Preset -parent $page -designObject $designObj  -widget radioGroup
	set imageVar [ced::add_image -name Image -parent $page -designObject $designObj -width 500 -height 400 -layout vertical]
 }


updater {PROJECT_PARAM.BOARD_PART Preset.VALUE} {Image.IMAGE_PATH Preset.ENABLEMENT Preset.DISPLAYNAME} {
  set Preset.DISPLAYNAME "Preset Configurations"


  if { ${Preset.VALUE} == {PS7_Only}} {
     set Preset.ENABLEMENT true
     set Image.IMAGE_PATH "Zynq-7000-Preset-1.jpg"
} elseif { ${Preset.VALUE} == {PS7_PL} } {
	 set Preset.ENABLEMENT true
	 set Image.IMAGE_PATH "Zynq-7000-Preset-2.jpg"
} elseif { ${Preset.VALUE} == {PS7_Accelerated} } {
	 set preset.ENABLEMENT true
}
}


