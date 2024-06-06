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
   return [get_board_parts -filter {(BOARD_NAME =~"*_som*"&& VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*k26*"&& VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*k24*"&& VENDOR_NAME=="xilinx.com")} -latest_file_version]
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "Preset" type "string" value "Default_Bitstream" value_list {"Default_Bitstream" "BRAM_GPIO"} enabled true]
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
  set Preset.DISPLAYNAME "Kria SOM Starter Kit Configurations"
  if { ${Preset.VALUE} == "Default_Bitstream"} {
	if {[regexp "_som" ${PROJECT_PARAM.BOARD_PART}]} {
     set Preset.ENABLEMENT true
	 } else {
	 set Preset.ENABLEMENT false
	 set Preset.VALUE Default_Bitstream
	 }
     set Image.IMAGE_PATH "kria_option1.png"
  } elseif { ${Preset.VALUE} == "BRAM_GPIO"} {
	 set Preset.ENABLEMENT true
	 set Image.IMAGE_PATH "kria_option2.png"
  }
}