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
  
proc getSupportedParts {} {
}

proc getSupportedBoards {} {
  return [get_board_parts -filter {(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com" ) || (BOARD_NAME =~"*vpk120*" && VENDOR_NAME=="xilinx.com" )}  -latest_file_version]
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "Preset" type "string" value "PL_PCIE4" value_list {"PL_PCIE4" "PL_PCIE5"} enabled true]
	return $x
}


proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
	ced::add_param -name Preset -parent $page -designObject $designObj  -widget radioGroup 
    set imageVar [ced::add_image -name Image -parent $page -designObject $designObj -width 500 -height 300 -layout vertical]
}

gui_updater {PROJECT_PARAM.BOARD_PART} {Preset.VISIBLE Preset.ENABLEMENT Preset.VALUE} {
set Preset.DISPLAYNAME "PL_PCIE Configurations"
if { [regexp "vck190" ${PROJECT_PARAM.BOARD_PART}]} {
#set Preset.VISIBLE true
set Preset.ENABLEMENT false
set Preset.VALUE PL_PCIE4
} else {
#set Preset.VISIBLE false
set Preset.ENABLEMENT false
set Preset.VALUE PL_PCIE5
}
}

