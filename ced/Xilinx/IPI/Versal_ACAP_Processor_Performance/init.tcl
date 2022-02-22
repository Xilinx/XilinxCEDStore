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

source -notrace "$currentDir/ver_ps_perf.tcl"

proc getSupportedParts {} {
	 return ""
	 }

proc getSupportedBoards {} {
# return [get_board_parts -filter {(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com") || (BOARD_NAME =~"*vmk180*" && VENDOR_NAME=="xilinx.com")}  -latest_file_version]
 
 return [get_board_parts -filter {(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com" && PART_NAME=~"xcvc1902-vsva2197-2MP-e-S") || (BOARD_NAME =~"*vmk180*" && VENDOR_NAME=="xilinx.com" && PART_NAME=~"xcvm1802-vsva2197-2MP-e-S")}  -latest_file_version]
}

proc addOptions {DESIGNOBJ} {
	lappend x [dict create name "Preset" type "string" value "DDR Subsystem" value_list {"DDR4_______Design_will_use_DDR4_controller" "LPDDR4___Design_will_use_LPDDR4_controller"} enabled true]
	return $x
	}

proc addGUILayout {DESIGNOBJ} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Memory Configuration" -designObject $designObj -layout vertical]	
	ced::add_param -name Preset -parent $page -designObject $designObj  -widget radioGroup 
        set imageVar [ced::add_image -name Image -parent $page -designObject $designObj -width 500 -height 300 -layout vertical]
}


 updater {} {Image.IMAGE_PATH Preset.ENABLEMENT Preset.DISPLAYNAME} {
  set Preset.DISPLAYNAME "Memory Configuration"
  if { ${Preset.VALUE} == "DDR4"} {
     set Preset.ENABLEMENT true
  } elseif { ${Preset.VALUE} == "LPDDR4"} {
	 set Preset.ENABLEMENT true
  }
}


