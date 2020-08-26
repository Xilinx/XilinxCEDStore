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
	 return ""
}

proc getSupportedBoards {} {
  return [get_board_parts -filter {(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com" ) || (BOARD_NAME =~"*vmk180*" && VENDOR_NAME=="xilinx.com" )}  -latest_file_version]
}


proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "Include_LPDDR" type "bool" value "false" enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
	set ddr [ced::add_group -name "Versal LPDDR Configurations" -display_name "Versal LPDDR Configurations"  -parent $page -visible true -designObject $designObj ]
	ced::add_param -name Include_LPDDR -display_name "Include_LPDDR" -parent $ddr -designObject $designObj -widget checkbox
    set imageVar [ced::add_image -name Image -parent $ddr -designObject $designObj -width 500 -height 300 -layout vertical]
}

 updater {Include_LPDDR.VALUE} {Include_LPDDR.ENABLEMENT} {
  if { ${Include_LPDDR.VALUE} == true } {
     set Include_LPDDR.ENABLEMENT true
  } else {
	 set Include_LPDDR.ENABLEMENT true
	 }
}

gui_updater {PROJECT_PARAM.BOARD_PART Include_LPDDR.VALUE} {Image.IMAGE_PATH} {
 if { ${Include_LPDDR.VALUE} == true } {
   set Image.IMAGE_PATH "" 
   } else {
	 set Image.IMAGE_PATH ""
	 }
}
