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

