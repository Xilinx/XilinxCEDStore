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
  return [get_parts xcvn3716-vsvb2197-2LHP-*]
}

proc getSupportedBoards {} {
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
        lappend x [dict create name "CPM5N_Preset" type "string" value "CPM5N_CSI_Uport_Bottom_Design" value_list {CPM5N_CSI_Uport_Top_Design CPM5N_CSI_Uport_Bottom_Design} enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
        set left_panel [ced::add_panel -name left_panel -parent $page -designObject $designObj]
        set right_panel [ced::add_panel -name right_panel -parent $page -designObject $designObj]


        #set combinedPanel [ced::add_panel -name combinedPanel -parent $right_panel -designObject $designObj]
        ced::add_param -name CPM5N_Preset  -parent $right_panel -designObject $designObj -widget radioGroup  

}


gui_updater {PROJECT_PARAM.BOARD_PART} {CPM5N_Preset.VISIBLE CPM5N_Preset.ENABLEMENT} {
set CPM5N_Preset.ENABLEMENT true
set CPM5N_Preset.VISIBLE true
}

