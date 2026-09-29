proc createDesign {design_name options} {


    # Set the reference directory for source file relative paths (by default the value is script directory path)
    variable currentDir

   
if [regexp "CPM4" $options] {

set xdc [file join $currentDir xdc cpm_rc.xdc]
import_files -fileset constrs_1 -norecurse $xdc

} else {

set xdc [file join $currentDir xdc default.xdc]
import_files -fileset constrs_1 -norecurse $xdc

}

##################################################################
# DESIGN PROCs
##################################################################
#variable currentDir
#
#
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
source -notrace "$currentDir/create_cpm4_rp.tcl"
} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_PCIe_Controller0_Gen4x8_RootPort_Design"] != -1)} {
puts "INFO: CPM5_PCIe_Controller0_Gen4x8_RootPort_Design preset is selected."
source -notrace "$currentDir/create_cpm5_ctrl0_rp.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: ctrl0 bd generated"

} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_PCIe_Controller1_Gen4x8_RootPort_Design"] != -1)} {
puts "INFO: CPM5_PCIe_Controller1_Gen4x8_RootPort_Design preset is selected."
source -notrace "$currentDir/create_cpm5_ctrl1_rp.tcl"

# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: ctrl1 bd generated"
}

open_bd_design [get_files $design_name.bd]

regenerate_bd_layout

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2026.2/ced/Xilinx/IPI/Versal_CPM_Bridge_RP_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2026.2/ced/Xilinx/IPI/Versal_CPM_Bridge_RP_Design/readme.txt",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
    #  -string -flagsOSRD
    preplace cgraphic comment_0 place right -1200 -130 textcolor 4 linecolor 3
    ",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }

save_bd_design
make_wrapper -files [get_files $design_name.bd] -top -import -quiet
puts "INFO: End of create_root_design"

}
