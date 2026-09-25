proc createDesign {design_name options} {


    # Set the reference directory for source file relative paths (by default the value is script directory path)
    variable currentDir

    # Create 'sources_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sources_1] ""]} {
        create_fileset -srcset sources_1
    }

   # Set 'sources_1' fileset object
set obj [get_filesets sources_1]

set board_name [get_property BOARD_NAME [current_board]]
puts $board_name

if [regexp "vck190" $board_name] {
puts "INFO: VCK190 Board is selected."

set files [list \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_EP_MEM.v"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_EP_MEM_ACCESS.v"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_INTR_CTRL.v"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/pcie_app_versal_bmd.vh"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_CC_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_CQ_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_EP_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RC_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RQ_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RQ_MUX_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RQ_READ_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RQ_WRITE_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_TO_CTRL.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/pcie_app_versal_bmd.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/design_1_wrapper.v"] \
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

# Create 'constrs_1' fileset (if not found)
#if {[string equal [get_filesets -quiet constrs_1] ""]} {
#  create_fileset -constrset constrs_1
#}

# Set 'constrs_1' fileset object
#set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
#set file "[file normalize "$currentDir/cpm4_bmd_ep/constraints/top_impl.xdc"]"
#set file_added [add_files -norecurse -fileset $obj [list $file]]
#set file "$currentDir/cpm4_bmd_ep/constraints/top_impl.xdc"
#set file [file normalize $file]
#set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
#set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
#set obj [get_filesets constrs_1]

set xdc [file join $currentDir cpm4_bmd_ep constraints top_impl.xdc]
import_files -fileset constrs_1 -norecurse $xdc

# Set 'utils_1' fileset object
set utils [file join $currentDir cpm4_bmd_ep pre_place.tcl]
import_files -fileset utils_1 -norecurse $utils

# Set 'utils_1' fileset file properties for remote files
#set file "$currentDir/cpm4_bmd_ep/pre_place.tcl"
#set file [file normalize $file]
#set file_obj [get_files -of_objects [get_filesets utils_1] [list "*$file"]]
#set_property -name "file_type" -value "TCL" -objects $file_obj

# Set 'utils_1' fileset file properties for local files
# None
set_property STEPS.PLACE_DESIGN.TCL.PRE [get_files pre_place.tcl -of [get_fileset utils_1] ] [get_runs impl_1]

# Set 'utils_1' fileset properties
#set obj [get_filesets utils_1]

} 

if [regexp "vpk120.*" $board_name] {
puts $board_name
puts "INFO: VPK120 Board is selected."
if {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_PCIE_Gen4x8_BMD_Design"] != -1)} {
puts "INFO: default CPM5_PCIE_Gen4x8_BMD_Design preset is selected."

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]

set files [list \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_EP_MEM.v"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_EP_MEM_ACCESS.v"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_INTR_CTRL.v"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/pcie_app_versal_bmd.vh"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/pcie_intf_defs_cpm5n.vh"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/pcie_intf_defs_legacy.vh"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_CC_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_CQ_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_EP_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RC_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RQ_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RQ_MUX_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RQ_READ_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RQ_WRITE_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_TO_CTRL.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/pcie_app_versal_bmd.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/design_1_wrapper.sv"] \
]
#add_files -norecurse -fileset $obj $files
import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'constrs_1' fileset (if not found)
#if {[string equal [get_filesets -quiet constrs_1] ""]} {
#  create_fileset -constrset constrs_1
#}

# Set 'constrs_1' fileset object
#set obj [get_filesets constrs_1]
#
## Add/Import constrs file and set constrs file properties
#set file "[file normalize "$currentDir/cpm5_bmd_ep/constraints/io_assign_pcie_rstn.xdc"]"
#set file_added [add_files -norecurse -fileset $obj [list $file]]
#set file "$currentDir/cpm5_bmd_ep/constraints/io_assign_pcie_rstn.xdc"
#set file [file normalize $file]
#set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
#set_property -name "file_type" -value "XDC" -objects $file_obj
#
## Set 'constrs_1' fileset properties
#set obj [get_filesets constrs_1]

set xdc [file join $currentDir cpm5_bmd_ep constraints io_assign_pcie_rstn.xdc]
import_files -fileset constrs_1 -norecurse $xdc

} elseif {[regexp "CPM5_PCIE_Gen5x8_BMD_Design" $options]} {

puts "INFO: default CPM5_PCIE_Gen5x8_BMD_Design preset is selected."

set board_part_name [get_property PART_NAME [current_board_part]]
if [regexp "xcvp1202-vsva2785-2MHP-e-S" $board_part_name] {

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]

set files [list \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_EP_MEM.v"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_EP_MEM_ACCESS.v"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_INTR_CTRL.v"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/pcie_app_uscale_bmd_1024.vh"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_1024.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_CC_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_CQ_CC_SHIM.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_CQ_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_EP_1024.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_RC_1024.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_RQ_1024.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_RQ_RW_1024.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/BMD_AXIST_TO_CTRL.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/pcie_app_uscale_bmd_1024.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/src/design_1_wrapper.v"] \
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

# Create 'constrs_1' fileset (if not found)
#if {[string equal [get_filesets -quiet constrs_1] ""]} {
#  create_fileset -constrset constrs_1
#}

# Set 'constrs_1' fileset object
#set obj [get_filesets constrs_1]
#
## Add/Import constrs file and set constrs file properties
#set file "[file normalize "$currentDir/cpm5_bmd_g5x8_ep/constraints/top_impl.xdc"]"
#set file_added [add_files -norecurse -fileset $obj [list $file]]
#set file "$currentDir/cpm5_bmd_g5x8_ep/constraints/top_impl.xdc"
#set file [file normalize $file]
#set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
#set_property -name "file_type" -value "XDC" -objects $file_obj
#
## Set 'constrs_1' fileset properties
#set obj [get_filesets constrs_1]

set xdc [file join $currentDir cpm5_bmd_g5x8_ep constraints top_impl.xdc]
import_files -fileset constrs_1 -norecurse $xdc

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Import local files from the original project

set files [list \
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/board_common.vh"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/pci_exp_usrapp_cfg.v"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/pci_exp_expect_tasks.vh"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/pci_exp_usrapp_com.v"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/pci_exp_usrapp_rx.v"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/sample_tests.vh"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/tests.vh"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/pci_exp_usrapp_tx.v"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/sys_clk_gen.v"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/sys_clk_gen_ds.v"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/xilinx_pcie5_versal_rp.sv"]\
 [file normalize "${currentDir}/cpm5_bmd_g5x8_ep/sim_files/board.v"]\
]

import_files -norecurse -fileset $obj $files

} else {
puts "Warning: No design created as -2MP variant of VPK120 board is selected.
      The Gen5 speed is supported for -2MHP or above speed grade part.
      Please select VPK120 board with -2MHP speed grade variant under \"switch part\" selection while choosing the board part."
}

}

}
##################################################################
# DESIGN PROCs
##################################################################
set board_name [get_property BOARD_NAME [current_board]]
if [regexp "vck190" $board_name] {
puts "INFO: vck190 board selected"
set use_cpm "CPM4"
} else {
puts "INFO: vpk120 board selected"
set use_cpm "CPM5"
}

if [regexp "CPM4" $use_cpm] {
puts "INFO: CPM4 preset is selected."
source -notrace "$currentDir/cpm4_bmd_ep/design_1_bd.tcl"

open_bd_design [get_bd_files $design_name]

} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_PCIE_Gen4x8_BMD_Design"] != -1)} {
puts "INFO: CPM5_PCIE_Gen4x8_BMD_Design preset is selected."
source -notrace "$currentDir/cpm5_bmd_ep/design_1_bd.tcl"

open_bd_design [get_bd_files $design_name]

} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_PCIE_Gen5x8_BMD_Design"] != -1)} {

set board_part_name [get_property PART_NAME [current_board_part]]
if [regexp "xcvp1202-vsva2785-2MHP-e-S" $board_part_name] {
source "$currentDir/cpm5_bmd_g5x8_ep/design_1_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]

set_property strategy Performance_RefinePlacement [get_runs impl_1]

open_bd_design [get_bd_files $design_name]

regenerate_bd_layout

validate_bd_design
save_bd_design

puts "INFO: EP bd generated"

source  "$currentDir/cpm5_bmd_g5x8_ep/design_rp_bd.tcl"
regenerate_bd_layout
validate_bd_design
save_bd_design
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files design_rp.bd]
generate_target all [get_files design_rp.bd]
puts "INFO: RP bd generated"
close_bd_design [get_bd_designs design_rp]

set_property used_in simulation [get_files design_rp.bd]

regenerate_bd_layout

open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/Versal_CPM_PCIE_BMD_EP_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/Versal_CPM_PCIE_BMD_EP_Design/readme.txt",
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
