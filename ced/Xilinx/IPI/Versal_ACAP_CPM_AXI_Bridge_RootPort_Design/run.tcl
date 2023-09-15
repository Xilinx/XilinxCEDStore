proc createDesign {design_name options} {


    # Set the reference directory for source file relative paths (by default the value is script directory path)
    variable currentDir

   
if [regexp "CPM4" $options] {

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/xdc/cpm_rc.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/xdc/cpm_rc.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

} else {

# Create 'constrs_1' fileset (if not found)
#if {[string equal [get_filesets -quiet constrs_1] ""]} {
#  create_fileset -constrset constrs_1
#}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/xdc/default.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
#set file_imported [import_files -fileset constrs_1 [list $file]]
set file "$currentDir/xdc/default.xdc"
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Add/Import constrs file and set constrs file properties
#set file "[file normalize "$currentDir/xdc/h10_ps_loc.xdc"]"
#set file_imported [import_files -fileset constrs_1 [list $file]]
#set file "$currentDir/xdc/h10_ps_loc.xdc"
#set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
#set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]



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
} else {
puts "INFO: CPM5 preset is selected."
source -notrace "$currentDir/create_cpm5_rp.tcl"
}

open_bd_design [get_files $design_name.bd]

regenerate_bd_layout
make_wrapper -files [get_files $design_name.bd] -top -import -quiet
puts "INFO: End of create_root_design"

}
