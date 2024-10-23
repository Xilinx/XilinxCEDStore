proc createDesign {design_name options} {  

variable currentDir
puts $currentDir
##################################################################
# DESIGN PROCs
##################################################################
set f [open "create_design.txt" a]
puts $f "in createDesign"
if {([lsearch $options "Live*"] != -1)} {
puts $f "Options used to create design: $options"
set_property ip_repo_paths "$currentDir/pcore" [current_project]
update_ip_catalog
source "$currentDir/Live/mmi_dpdc_live.tcl"
} elseif {([lsearch $options "Mixed*"] != -1)} {
puts $f "Options used to create design: $options"
set_property ip_repo_paths "$currentDir/pcore" [current_project]
update_ip_catalog
source "$currentDir/Mixed/mmi_dpdc_mixed.tcl"
} elseif {([lsearch $options "USB"] != -1)} {
puts $f "Options used to create design: $options"
source "$currentDir/usb/mmi_usb.tcl"
} else {
puts $f "Options used to create design: DPDC_Presentation_Mode Non_Live"
set_property ip_repo_paths "$currentDir/pcore" [current_project]
update_ip_catalog
source "$currentDir/Non_Live/mmi_dpdc_nonlive.tcl"
}
set systemTime [clock seconds]
puts $f "createDesign: [clock format $systemTime -format %H:%M:%S]"
flush $f
puts $f "creating root design"
create_root_design "" $design_name
puts $f "created root design completed"
puts $f "about to make wrapper for $design_name"
flush $f
set proj_name [lindex [get_projects] 0]
set proj_dir [get_property DIRECTORY $proj_name]
set_property TARGET_LANGUAGE Verilog $proj_name
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
puts $f "INFO:Design Creation completed successfully"
open_bd_design [get_bd_files $design_name]
save_bd_design
close $f
}
