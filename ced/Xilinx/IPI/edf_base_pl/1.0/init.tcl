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
   set V_board_unique [get_board_parts -filter {(BOARD_NAME =~"*vek386*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vpk360*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vek280*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vmk180*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vpk180*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vpk120*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vek385*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vrk160*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vrk165*" && VENDOR_NAME=="xilinx.com")} -latest_file_version -quiet]
   #set V_board_unique [get_board_parts -filter {(BOARD_NAME =~"*vek385*" && VENDOR_NAME=="xilinx.com")} -latest_file_version]
   return $V_board_unique
}
