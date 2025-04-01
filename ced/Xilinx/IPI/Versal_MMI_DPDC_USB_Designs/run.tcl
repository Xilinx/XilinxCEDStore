proc createDesign {design_name options} {
variable currentDir
##################################################################
# DESIGN PROCs
##################################################################
if { ([lsearch $options "USB*"] != -1) } {
source "$currentDir/USB/mmi_usb.tcl"
add_files -fileset constrs_1 -norecurse $currentDir/USB/ddr.xdc
import_files -fileset constrs_1 $currentDir/USB/ddr.xdc
} elseif { ([lsearch $options "DC_Bypass*"] != -1) } {
set_property ip_repo_paths "$currentDir/pcore" [current_project]
update_ip_catalog
if { ([lsearch $options "true*"] != -1) } {
if { ([lsearch $options "4"] != -1) } {
source "$currentDir/Bypass/mmi_dpdc_bypass4.tcl"
} else {
source "$currentDir/Bypass/mmi_dpdc_bypass2.tcl"
} 
} else {
source "$currentDir/Bypass/mmi_dpdc_bypass1.tcl"
}
add_files -fileset constrs_1 -norecurse $currentDir/Bypass/ddr.xdc
import_files -fileset constrs_1 $currentDir/Bypass/ddr.xdc
} else {
set_property ip_repo_paths "$currentDir/pcore" [current_project]
update_ip_catalog
if { ([lsearch $options "Live*"] != -1) && ([lsearch $options "Native*"] != -1) } {
source "$currentDir/Live/mmi_dpdc_live.tcl"
add_files -fileset constrs_1 -norecurse $currentDir/Live/ddr.xdc
import_files -fileset constrs_1 $currentDir/Live/ddr.xdc
} elseif { ([lsearch $options "Live*"] != -1) && ([lsearch $options "AXI*"] != -1) } {
source "$currentDir/Live/mmi_dpdc_live_st.tcl"
add_files -fileset constrs_1 -norecurse $currentDir/Live/ddr.xdc
import_files -fileset constrs_1 $currentDir/Live/ddr.xdc
} elseif { ([lsearch $options "Mixed*"] != -1)} {
source "$currentDir/Mixed/mmi_dpdc_mixed.tcl"
add_files -fileset constrs_1 -norecurse $currentDir/Mixed/ddr.xdc
import_files -fileset constrs_1 $currentDir/Mixed/ddr.xdc
} else {
source "$currentDir/Non_Live/mmi_dpdc_nonlive.tcl"
add_files -fileset constrs_1 -norecurse $currentDir/Non_Live/ddr.xdc
import_files -fileset constrs_1 $currentDir/Non_Live/ddr.xdc
}
}
create_root_design "" $design_name
set proj_name [lindex [get_projects] 0]
set proj_dir [get_property DIRECTORY $proj_name]
set_property TARGET_LANGUAGE Verilog $proj_name
open_bd_design [get_bd_files $design_name]
generate_target all [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]
set_property generate_synth_checkpoint true [get_files -norecurse *.bd]
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
set_property synth_checkpoint_mode None [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
}
