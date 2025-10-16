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
proc createDesign {design_name options} {  

variable currentDir
puts $currentDir


if [regexp "CPM4" $options] {

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]

set files [list \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_EP_MEM.v"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_EP_MEM_ACCESS.v"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_INTR_CTRL.v"] \
 [file normalize "${currentDir}/cpm4_bmd/src/pcie_app_versal_bmd.vh"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_512.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_CC_512.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_CQ_512.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_EP_512.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_RC_512.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_RQ_512.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_RQ_MUX_512.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_RQ_READ_512.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_RQ_WRITE_512.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/BMD_AXIST_TO_CTRL.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/pcie_app_versal_bmd.sv"] \
 [file normalize "${currentDir}/cpm4_bmd/src/pcie_intf_defs_cpm5n.vh"] \
 [file normalize "${currentDir}/cpm4_bmd/src/pcie_intf_defs_legacy.vh"] \
 [file normalize "${currentDir}/cpm4_bmd/src/design_1_wrapper.v"] \
]
import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Import local files from the original project

set files [list \
 [file normalize "${currentDir}/cpm4_bmd/sim_files/board_common.vh"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/pci_exp_usrapp_cfg.v"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/pci_exp_expect_tasks.vh"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/pci_exp_usrapp_com.v"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/pci_exp_usrapp_rx.v"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/pci_exp_usrapp_top.v"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/sample_tests.vh"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/tests.vh"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/pci_exp_usrapp_tx.v"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/sys_clk_gen.v"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/sys_clk_gen_ds.v"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/design_rp_wrapper.sv"]\
 [file normalize "${currentDir}/cpm4_bmd/sim_files/board.v"]\
]

import_files -norecurse -fileset $obj $files

} else {

set board_part_name [get_property PART_NAME [current_board_part]]
if [regexp "xcvp1202-vsva2785-2MHP-e-S" $board_part_name] {

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_EP_MEM.v"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_EP_MEM_ACCESS.v"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_INTR_CTRL.v"]\
 [file normalize "${currentDir}/cpm5_bmd/src/pcie_app_uscale_bmd_1024.vh"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_1024.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_CC_512.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_CQ_512.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_CQ_CC_SHIM.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_EP_1024.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_RC_1024.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_RQ_1024.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_RQ_RW_1024.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/BMD_AXIST_TO_CTRL.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/pcie_app_uscale_bmd_1024.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/src/design_1_wrapper.v"]\
]

import_files -norecurse -fileset $obj $files
set prj [get_projects [current_project]]

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj

# Create 'constrs_1' fileset (if not found)
#if {[string equal [get_filesets -quiet constrs_1] ""]} {
#  create_fileset -constrset constrs_1
#}
#
## Set 'constrs_1' fileset object
#set obj [get_filesets constrs_1]
#
## Add/Import constrs file and set constrs file properties
#set file "[file normalize "$currentDir/cpm5_bmd/constraints/top_impl.xdc"]"
#set file_added [add_files -norecurse -fileset $obj [list $file]]
#set file "$currentDir/cpm5_bmd/constraints/top_impl.xdc"
#set file [file normalize $file]
#set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
#set_property -name "file_type" -value "XDC" -objects $file_obj
#
## Set 'constrs_1' fileset properties
#set obj [get_filesets constrs_1]

set xdc [file join $currentDir cpm5_bmd constraints top_impl.xdc]
import_files -fileset constrs_1 -norecurse $xdc

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile


# Set 'utils_1' fileset object
#set obj [get_filesets utils_1]
#set files [list \
# [file normalize "${currentDir}/cpm5_bmd/pre_place.tcl"] \
#]
#add_files -norecurse -fileset $obj $files
#
## Set 'utils_1' fileset file properties for remote files
#set file "$currentDir/cpm5_bmd/pre_place.tcl"
#set file [file normalize $file]
#set file_obj [get_files -of_objects [get_filesets utils_1] [list "*$file"]]
#set_property -name "file_type" -value "TCL" -objects $file_obj
#
#
## Set 'utils_1' fileset file properties for local files
#set obj [get_filesets utils_1]
#
set utils [file join $currentDir cpm5_bmd pre_place.tcl]
import_files -fileset utils_1 -norecurse $utils

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${currentDir}/cpm5_bmd/sim_files/board_common.vh"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/pci_exp_usrapp_cfg.v"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/tests.vh"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/sample_tests.vh"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/pci_exp_expect_tasks.vh"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/pci_exp_usrapp_com.v"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/pci_exp_usrapp_rx.v"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/pci_exp_usrapp_tx.v"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/sys_clk_gen.v"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/sys_clk_gen_ds.v"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/xilinx_pcie5_versal_rp.sv"]\
 [file normalize "${currentDir}/cpm5_bmd/sim_files/board.v"]\
]

import_files -norecurse -fileset $obj $files


} else {
puts "Warning: No design created as -2MP variant of VPK120 board is selected.
      The Gen5 speed is supported for -2MHP or above speed grade part.
      Please select VPK120 board with -2MHP speed grade variant under \"switch part\" selection while choosing the board part."
}
}

##################################################################
# DESIGN PROCs
##################################################################


#default option is CPM4
set cpm "Preset.VALUE"
set board_name [get_property BOARD_NAME [current_board]]
if [regexp "vck190" $board_name] {
puts "INFO: vck190 board selected"
set use_cpm "CPM4"
} else {
puts "INFO: vpk120 board selected"
set use_cpm "CPM5"
}

if { [dict exists $options $cpm] } {
set use_cpm [dict get $options $cpm ]
}
if [regexp "CPM4" $use_cpm] {
puts "INFO: CPM4 preset is selected."
source "$currentDir/cpm4_bmd/design_1_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"

source  "$currentDir/cpm4_bmd/design_rp_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files design_rp.bd]
generate_target all [get_files design_rp.bd]
puts "INFO: RP bd generated"

regenerate_bd_layout

set_property used_in simulation [get_files design_rp.bd]


} else {

set board_part_name [get_property PART_NAME [current_board_part]]
if [regexp "xcvp1202-vsva2785-2MHP-e-S" $board_part_name] {

puts "INFO: CPM5 preset is selected."
source "$currentDir/cpm5_bmd/design_1_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"

regenerate_bd_layout

source "$currentDir/cpm5_bmd/design_rp_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files design_rp.bd]
generate_target all [get_files design_rp.bd]
puts "INFO: RP bd generated"

set_property used_in simulation  [get_files  design_rp.bd]

regenerate_bd_layout

open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.2/ced/Xilinx/IPI/Versal_CPM_PCIE_BMD_Simulation_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.2/ced/Xilinx/IPI/Versal_CPM_PCIE_BMD_Simulation_Design/readme.txt",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
    #  -string -flagsOSRD
    preplace cgraphic comment_0 place right -1200 -130 textcolor 4 linecolor 3
    ",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }
 
validate_bd_design
save_bd_design
 
puts "INFO: design generation completed successfully"

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]

set_property target_simulator Questa [current_project]
set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

set_property -name "questa.elaborate.vopt.more_options" -value "+nospecify +notimingchecks" -objects $obj
set_property -name "questa.simulate.log_all_signals" -value "1" -objects $obj
set_property -name "questa.simulate.runtime" -value "all" -objects $obj
set_property -name "questa.simulate.vsim.more_options" -value "+notimingchecks" -objects $obj

} else {

open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Warning: No design created as -2MP variant of VPK120 board is selected.
    The Gen5 speed is supported for -2MHP or above speed grade part.
    Please select VPK120 board with -2MHP speed grade variant under switch part selection while choosing the board part.} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Warning: No design created as -2MP variant of VPK120 board is selected.
    The Gen5 speed is supported for -2MHP or above speed grade part.
    Please select VPK120 board with -2MHP speed grade variant under switch part selection while choosing the board part.",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
    #  -string -flagsOSRD
    preplace cgraphic comment_0 place right -1200 -130 textcolor 4 linecolor 3
    ",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }

generate_target all [get_files $design_name]

regenerate_bd_layout

validate_bd_design
save_bd_design

}

}

}

