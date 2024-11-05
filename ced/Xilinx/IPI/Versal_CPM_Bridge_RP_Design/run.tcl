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
make_wrapper -files [get_files $design_name.bd] -top -import -quiet
puts "INFO: End of create_root_design"

}
