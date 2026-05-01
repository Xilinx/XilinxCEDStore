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

 ##################################################################
 # DESIGN PROCs													 
 ##################################################################
proc createDesign {design_name options} {  

variable currentDir
set_property target_language Verilog [current_project]

open_bd_design [get_bd_files $design_name]
set board_name [get_property BOARD_NAME [current_board]]
puts "creating the root design"

set board_part [get_property NAME [current_board_part]]
set fpga_part [get_property PART_NAME [current_board_part]]

puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"


if {[regexp "vrk160" $board_name]||[regexp "vrk165" $board_name]} {

source "$currentDir/vrk16_comn.tcl"

} elseif {[regexp "vek385" $board_name]||[regexp "vek386" $board_name]} {

source "$currentDir/vek38_comn.tcl" 

}  elseif {[regexp "vpk360" $board_name]} {

source "$currentDir/vpk36_comn.tcl"

} else {

source "$currentDir/gen1_comn.tcl" }

create_root_design $currentDir $design_name

if {[regexp "vek385" $board_name]||[regexp "vek386" $board_name]||[regexp "vpk360" $board_name]} {

set dir_path [file join $currentDir golden_ncr]
set ncr 1

if {[regexp "vek385_" $board_name]} {
set filePattern "vek385_revb_*.ncr"
} elseif {$board_name == "vek385"} {
set filePattern "vek385_reva_*.ncr"
} elseif {$board_name == "vpk360"} {
set filePattern "vpk360_*.ncr"
} elseif {$board_name == "vek386"} {
set filePattern "vek386_*.ncr"
} else {
puts "INFO: Golden NCR is not available for $board_name!!"
set ncr 0
}

if {$ncr==1} {
set noc_ncr [glob -nocomplain -directory $dir_path $filePattern]
set file_name [ lindex [split $noc_ncr "/"] end]
puts "INFO: Importing the golden_noc $file_name to the design!"
import_files -fileset utils_1 $noc_ncr 
set ncr_path [file join [get_property directory [current_project]] [current_project].srcs utils_1 imports golden_ncr]
set_property NOC_SOLUTION_FILE $ncr_path/$file_name [get_runs impl_1]
} }

assign_bd_address
validate_bd_design
regenerate_bd_layout
save_bd_design

set prj [current_project]
make_wrapper -files [get_files $design_name.bd] -top -import -force
#add_files -norecurse ./$prj/${prj}.gen/sources_1/bd/$design_name/hdl/${design_name}_wrapper.v

open_bd_design [get_files $design_name.bd]
regenerate_bd_layout
puts "INFO: End of create_root_design"

}