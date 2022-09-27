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

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
# Import local files from the original project
set files [list \
 [file normalize "${currentDir}/src/design_1_wrapper.v"]\
]
import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "${design_name}_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

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
 [file normalize "${currentDir}/sim_files/design_1_wrapper_sim_wrapper.v" ]\
 [file normalize "${currentDir}/sim_files/sys_clk_gen.v"]\
 [file normalize "${currentDir}/sim_files/sys_clk_gen_ds.v"]\
 [file normalize "${currentDir}/sim_files/board_common.vh"]\
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_cfg.v"]\
 [file normalize "${currentDir}/sim_files/pci_exp_expect_tasks.vh"]\
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_com.v"]\
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_rx.v"]\
 [file normalize "${currentDir}/sim_files/sample_tests.vh"]\
 [file normalize "${currentDir}/sim_files/tests.vh"]\
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_tx.v"]\
 [file normalize "${currentDir}/sim_files/xilinx_pcie5_versal_rp.sv"]\
 [file normalize "${currentDir}/sim_files/board.v"]\
 [file normalize "${currentDir}/sim_files/sample_tests_sriov.vh"]\
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_tx_sriov.sv"]\
]
import_files -norecurse -fileset $obj $files

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files board.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files board.v] w]
puts -nonewline $outfile $contents
close $outfile

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files design_1_wrapper_sim_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files design_1_wrapper_sim_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files usp_pci_exp_usrapp_tx.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files usp_pci_exp_usrapp_tx.v] w]
puts -nonewline $outfile $contents
close $outfile
##################################################################
# DESIGN PROCs
##################################################################


source "$currentDir/design_1_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"

regenerate_bd_layout

set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2022.2/ced/Xilinx/IPI/Versal_CPM5_QDMA_Simulation_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2022.2/ced/Xilinx/IPI/Versal_CPM5_QDMA_Simulation_Design/readme.txt",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
    #  -string -flagsOSRD
    preplace cgraphic comment_0 place right -1200 -130 textcolor 4 linecolor 3
    ",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }

source  "$currentDir/design_rp_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files design_rp.bd]
generate_target all [get_files design_rp.bd]
puts "INFO: RP bd generated"

regenerate_bd_layout

source  "$currentDir/xlnoc_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files xlnoc.bd]
generate_target all [get_files xlnoc.bd]
puts "INFO: xlnoc bd generated"

regenerate_bd_layout

puts $design_name
 
open_bd_design [get_bd_files $design_name.bd]

       
validate_bd_design
save_bd_design
 
puts "INFO: design generation completed successfully"

#set_property USED_IN "simulation" [get_files xlnoc.bd ] 
#set_property USED_IN_IMPLEMENTATION "0" [get_files xlnoc.bd ] 
#set_property USED_IN_SYNTHESIS "0" [get_files xlnoc.bd ]

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]

set_property target_simulator VCS [current_project]
set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

set_property -name "vcs.elaborate.vcs.more_options" -value "+nospecify +notimingchecks" -objects $obj
set_property -name {vcs.simulate.runtime} -value {600000ns} -objects [get_filesets sim_1]
set_property -name {vcs.simulate.vcs.more_options} -value {-gui} -objects [get_filesets sim_1]

#set_property target_simulator Questa [current_project]
#set_property top board [get_filesets sim_1]
#set_property top_lib xil_defaultlib [get_filesets sim_1]
#
#set_property -name "questa.elaborate.vopt.more_options" -value "+nospecify +notimingchecks" -objects $obj
#set_property -name "questa.simulate.log_all_signals" -value "1" -objects $obj
#set_property -name "questa.simulate.runtime" -value "all" -objects $obj
#set_property -name "questa.simulate.vsim.more_options" -value "+notimingchecks" -objects $obj

}


