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

proc getSupportedParts {} {
}

proc getSupportedBoards {} {
 return [get_board_parts -latest_file_version -filter {(BOARD_NAME =~"*vpk120*" && VENDOR_NAME=="xilinx.com")}]
}

# See Confluence page "CED Developers Reference Manual"
proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "CPM_Config" type "string" value "CPM5" value_list {"CPM5"} enabled true]
        lappend x [dict create name "CPM5_Preset" type "string" value "CPM5_QDMA_Gen5x8_Accel_sys_Design" value_list {CPM5_QDMA_Gen5x8_Accel_sys_Design} enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
#  ced::add_param -name "dfx" -display_name "Enable DFX" -parent $page -designObject $DESIGNOBJ -widget checkbox
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
        set left_panel [ced::add_panel -name left_panel -parent $page -designObject $designObj]
        set right_panel [ced::add_panel -name right_panel -parent $page -designObject $designObj]
	ced::add_param -name CPM_Config -parent $left_panel -designObject $designObj  -widget radioGroup 
    ced::add_param -name CPM5_Preset  -parent $right_panel -designObject $designObj -widget radioGroup  
}

source -notrace "$currentDir/run.tcl"
#gui_updater {PROJECT_PARAM.BOARD_PART} {CPM_Config.VISIBLE CPM_Config.ENABLEMENT CPM_Config.VALUE} {
#set CPM_Config.DISPLAYNAME "CIPS CPM Configurations"
#set CPM_Config.ENABLEMENT false
#set CPM_Config.VALUE CPM5
#}

#gui_updater {PROJECT_PARAM.BOARD_PART} {CPM5_Preset.VISIBLE CPM5_Preset.ENABLEMENT} {
#set CPM_Config.DISPLAYNAME "CIPS CPM Configurations"
#set CPM5_Preset.ENABLEMENT true
#set CPM5_Preset.VISIBLE true
#}


