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

instantiate_example_design -template xilinx.com:design:edf_base:1.0 -design $design_name

open_bd_design [get_bd_files $design_name]

set board_name [get_property BOARD_NAME [current_board]]

if {[regexp "vek385" $board_name]||[regexp "vek386" $board_name]||[regexp "vpk360" $board_name]} {
source "$currentDir/vek38_pl.tcl" 
} elseif {[regexp "vrk160" $board_name]||[regexp "vrk165" $board_name]} {
source "$currentDir/vrk16_pl.tcl"
} else {
source "$currentDir/gen1_pl.tcl" }

set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example EDF base + Simple PL Payload <<<<<<<<< =======================
	\t Note:
	\t --> Board preset applied to PS WIZARD/CIPS and memory controller
	\t --> AI Engine control path is connected to PS WIZARD/CIPS
	\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.}  [current_bd_design]

assign_bd_address
validate_bd_design
save_bd_design

make_wrapper -files [get_files ${design_name}.bd] -top -import -force 

# set prj [current_project]
# make_wrapper -files [get_files $design_name.bd] -top
#add_files -norecurse ./$prj/${prj}.gen/sources_1/bd/$design_name/hdl/${design_name}_wrapper.v

open_bd_design [get_bd_files $design_name]
regenerate_bd_layout

puts "INFO: End of create_root_design"
}