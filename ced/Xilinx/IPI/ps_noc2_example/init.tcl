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
	 #return [get_parts xcvm2152-nfvm1369-1LP-e-S]
	 return [get_parts -filter {NAME =~ xcvm2152-nfvm1369-1LP-e-S || NAME =~ xc2ve3858-die-0x-e-S}]
}

proc getSupportedBoards {} {
   return ""
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.PART} {
    lappend x [dict create name "Board_selection" type "string" value "Board_list" value_list {"L20_MemChar1" "VEK385"} enabled true]
    return $x
}
 
proc addGUILayout {DESIGNOBJ PROJECT_PARAM.PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page -name "Page1" -display_name "Configurations" -designObject $designObj -layout vertical]
 
    ced::add_param -name Board_selection -display_name "Board_selection" -parent $page -designObject $designObj -widget radioGroup
}



gui_updater {PROJECT_PARAM.PART} {Board_selection.VALUE Board_selection.ENABLEMENT} {

	if {[regexp "xcvm2152-nfvm1369-1LP-e-S" ${PROJECT_PARAM.PART}]} {
		set Board_selection.ENABLEMENT false
		set Board_selection.VALUE L20_MemChar1
	} elseif {[regexp "xc2ve3858-die-0x-e-S" ${PROJECT_PARAM.PART}]} {
		set Board_selection.ENABLEMENT false
		set Board_selection.VALUE VEK385
	} else {
		set Board_selection.ENABLEMENT false
		set Board_selection.VALUE T20
	}	
	
}