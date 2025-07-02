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

# create_root_design $currentDir $design_name $part

 ##################################################################
 # DESIGN PROCs													 
 ##################################################################
proc createDesign {design_name options} {  

variable currentDir
set_property target_language Verilog [current_project]

set fpga_part [get_property PART [current_project ]]
set part_family [get_property FAMILY $fpga_part]

# Updating the default options from the GUI
set part_selection "Board_selection.VALUE"
if {[regexp "xcvm2152" $fpga_part]} {
set part L20_processor_board
} else {
set part VEK385
}

if { [dict exists $options $part_selection] } {
    set part [dict get $options $part_selection]
}

set design_typ "Design_type.VALUE"
set bd_typ Base

if { [dict exists $options $design_typ] } {
    set bd_typ [dict get $options $design_typ]
}

set sgc_param "seg_config.VALUE"
set sgc true
if { [dict exists $options $sgc_param] } {
	set sgc [dict get $options $sgc_param ] }

if {$sgc == "true"} {
puts "INFO: Segmented Configuration option is enbaled"
set_property SEGMENTED_CONFIGURATION 1 [current_project]
}

puts "INFO: selected design_name:: $design_name"

# Creating the design based on the options selected in GUI
puts "INFO: VEK385 part is selected"
if {[regexp "Base" $bd_typ]} {
	puts "INFO: Base design is selected"
	source "$currentDir/vek385_base.tcl"
} else {
puts "INFO: Extensible design is selected"
source "$currentDir/vek385_ext.tcl"
}

if {$sgc == "true"} {
puts "INFO: Importing the golden_noc_solution.ncr to the design!"
set noc_ncr [file join $currentDir vek385_golden_ncr vek385_6140274_0xe2261acc.ncr]

import_files -fileset utils_1 $noc_ncr 
set ncr_file [file join [get_property directory [current_project]] [current_project].srcs utils_1 imports vek385_golden_ncr]
set_property NOC_SOLUTION_FILE $ncr_file/vek385_6140274_0xe2261acc.ncr [get_runs impl_1]
}

open_bd_design [get_files $design_name.bd]
puts "INFO: End of root design"

}
