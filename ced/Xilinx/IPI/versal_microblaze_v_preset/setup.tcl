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

proc createDesign {design_name options} {  

variable currentDir
set_property target_language Verilog [current_project]

open_bd_design [get_bd_files $design_name]
set board_name [get_property BOARD_NAME [current_board]]

if {[regexp "vek385" $board_name]} {

puts "INFO : PS_wizard part selected"
source "$currentDir/ps_wizard_design.tcl"

} else {
	puts "INFO : CIPS PS part selected"
	source "$currentDir/cips_design.tcl"
}

create_root_design $currentDir $design_name $options 
	
# close_bd_design [get_bd_designs $design_name]
# set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
open_bd_design [get_bd_files $design_name]
regenerate_bd_layout
make_wrapper -files [get_files $design_name.bd] -top -import
puts "INFO: End of create_root_design"

}
