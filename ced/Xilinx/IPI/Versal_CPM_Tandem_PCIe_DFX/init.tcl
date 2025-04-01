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
 return [get_board_parts -latest_file_version -filter {(BOARD_NAME =~"*vpk120*" && VENDOR_NAME=="xilinx.com") || \
                                                       (BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com")    \
 }]
}

# See Confluence page "CED Developers Reference Manual"
proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  lappend x [dict create name "dfx" type "bool" value "false" enabled true]
  return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $DESIGNOBJ]
  ced::add_param -name "dfx" -display_name "Enable DFX" -parent $page -designObject $DESIGNOBJ -widget checkbox
}

