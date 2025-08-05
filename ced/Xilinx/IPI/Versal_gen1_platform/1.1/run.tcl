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

# Updating the default options from the GUI
set design_typ "Design_type.VALUE"
set bd_typ Base

if { [dict exists $options $design_typ] } {
    set bd_typ [dict get $options $design_typ]
}

set sgc_param "seg_config.VALUE"
set sgc true
if { [dict exists $options $sgc_param] } {
	set sgc [dict get $options $sgc_param ] 
}

if {$sgc == "true"} {
puts "INFO: Segmented Configuration option is enbaled"
set_property SEGMENTED_CONFIGURATION 1 [current_project]
}

set aie "Include_AIE.VALUE"
set use_aie 1

if { [dict exists $options $aie] } {
	set use_aie [dict get $options $aie ]
}

open_bd_design [get_bd_files $design_name]
set board_name [get_property BOARD_NAME [current_board]]

puts "creating the root design"

if {[regexp "Base" $bd_typ]} {
	
	puts "INFO: Base design is selected"
	
	if {[regexp "vrk160" $board_name]||[regexp "vrk165" $board_name]} {

	source "$currentDir/vrk_base_board.tcl"
	
	} else {
	source "$currentDir/vck_vek_base.tcl" }
	
} else {

puts "INFO: Extensible design is selected"
set_property platform.extensible true [current_project]

	if {[regexp "vrk160" $board_name]||[regexp "vrk165" $board_name]} {

	source "$currentDir/vrk_ext_board.tcl"
	} else {
	source "$currentDir/vck_vek_ext_design.tcl" }

# 0 (no interrupts) / 15 (interrupt controller : default) / 32 (interrupt controller) / 63 (interrupt controller + cascade block)
set irqs_param "IRQS.VALUE"
set irqs 15

if { [dict exists $options $irqs_param] } {
	set irqs [dict get $options $irqs_param ]
}

if {[regexp "vck190" $board_name]||[regexp "vek280" $board_name]||[regexp "vrk160" $board_name]||[regexp "vrk165" $board_name]} {
	set clk_options { clk_out1 625 0 true clk_out2 100 1 false}
} else {
	set clk_options { clk_out1 200 0 true } 
}
set clk_defaut 0

set clk_options_param "Clock_Options.VALUE"
if { [dict exists $options $clk_options_param] } {
	set clk_options [ dict get $options $clk_options_param ]
} else {
set clk_defaut 1 
}

set board_part [get_property NAME [current_board_part]]
set fpga_part [get_property PART_NAME [current_board_part]]

puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"

puts "INFO: selected Interrupts:: $irqs"
puts "INFO: selected design_name:: $design_name"
puts "INFO: selected Clock_Options:: $clk_options"
puts "INFO: selected Include_AIE:: $use_aie"
puts "INFO: Using enhanced Versal extensible platform CED"

if {[regexp "vrk160" $board_name]||[regexp "vrk165" $board_name]} {
create_root_design $currentDir $design_name $clk_options $irqs $use_aie $clk_defaut
} else {
create_root_design $currentDir $design_name $clk_options $irqs $use_aie
}
}

# if {[regexp "Base" $bd_typ]} {
# set_property offset 0xA6020000 [get_bd_addr_segs {CIPS_0/M_AXI_FPD/SEG_axi_vip_0_Reg}]
# }

if {$sgc == "true"} {
set dir_path [file join $currentDir golden_ncr]

if {[regexp "vek280" $board_name]} {
set filePattern "vek280_*.ncr"
set noc_ncr [glob -nocomplain -directory $dir_path $filePattern]
} elseif {[regexp "vck190" $board_name]} {
set filePattern "vck190_*.ncr"
set noc_ncr [glob -nocomplain -directory $dir_path $filePattern]
} elseif {[regexp "vrk160" $board_name]} {
set filePattern "vrk160_*.ncr"
set noc_ncr [glob -nocomplain -directory $dir_path $filePattern]
} elseif {[regexp "vrk165" $board_name]} {
set filePattern "vrk165_*.ncr"
set noc_ncr [glob -nocomplain -directory $dir_path $filePattern]
} else {
puts "INFO: Golden NCR is not available for $board_name!!"
}

set file_name [ lindex [split $noc_ncr "/"] end]
puts "INFO: Importing the golden_noc $file_name to the design!"
import_files -fileset utils_1 $noc_ncr 
set ncr_path [file join [get_property directory [current_project]] [current_project].srcs utils_1 imports golden_ncr]
set_property NOC_SOLUTION_FILE $ncr_path/$file_name [get_runs impl_1]
}

assign_bd_address
validate_bd_design
regenerate_bd_layout
save_bd_design

make_wrapper -files [get_files $design_name.bd] -top -import

open_bd_design [get_files $design_name.bd]
puts "INFO: End of create_root_design"

}