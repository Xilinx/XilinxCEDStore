# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved

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
	 return [get_parts -quiet \
             -filter {(FAMILY=="versalpremium2" && (LICENSE=="Preproduction" || LICENSE=="Full"))}]
}

proc getSupportedBoards {} {
 return [get_board_parts -latest_file_version -quiet \
           -filter {(BOARD_NAME=~"*vpk360*")}]
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  lappend x [dict create name "NUM_CPI" type "string" value "4" \
    value_list {"1 1" "2 2" "3 3" "4 4"} enabled true]
  lappend x [dict create name "CXL_REV" type "string" value "3.1" \
    value_list {"2.0 2.0" "3.1 3.1"} enabled true]
  lappend x [dict create name "LINK_CONFIG" type "string" \
    value "Gen6x8 (64 GB/s/dir)" enabled false]
  return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  set designObj $DESIGNOBJ
  set page [ced::add_page -name "Page1" -display_name "Configuration" \
    -designObject $designObj -layout vertical]
  ced::add_param -name CXL_REV -display_name "CXL Revision" \
    -parent $page -designObject $designObj -widget comboBox
  ced::add_param -name LINK_CONFIG -display_name "Link Configuration" \
    -parent $page -designObject $designObj -widget textEdit
  ced::add_param -name NUM_CPI -display_name "Number of CPI Interfaces" \
    -parent $page -designObject $designObj -widget comboBox
  set text "<i>Higher counts increase throughput, but increase resources and timing challenges.</i>"
  ced::add_text -designObject $designObj -name NUM_CPI_HELP -tclproc $text -parent $page

}

# LINK_CONFIG is a read-only, derived display of the link speed/width implied
# by CXL_REV -- always disabled, its VALUE just tracks CXL_REV's selection.
gui_updater {CXL_REV.VALUE} {LINK_CONFIG.VALUE LINK_CONFIG.ENABLEMENT} {
  set LINK_CONFIG.ENABLEMENT false
  if { ${CXL_REV.VALUE} == "2.0" } {
    set LINK_CONFIG.VALUE "Gen5x8 (32 GB/s/dir)"
  } else {
    set LINK_CONFIG.VALUE "Gen6x8 (64 GB/s/dir)"
  }
}

