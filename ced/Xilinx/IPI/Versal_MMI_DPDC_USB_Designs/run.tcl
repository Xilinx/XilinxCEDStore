proc createDesign {design_name options} {
variable currentDir
##################################################################
# DESIGN PROCs
##################################################################
set proj_part [get_property PART [current_project]]
if { ([lsearch $options "USB*"] != -1) } {
source "$currentDir/USB/mmi_usb.tcl"
if { [regexp "xc2ve3858" $proj_part] } {
add_files -fileset constrs_1 -norecurse $currentDir/USB/ddr.xdc
import_files -fileset constrs_1 $currentDir/USB/ddr.xdc
}
} elseif { ([lsearch $options "DC_Bypass*"] != -1) } {
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
if { [regexp "xc2ve3858" $proj_part] } {
add_files -fileset constrs_1 -norecurse $currentDir/Bypass/ddr.xdc
import_files -fileset constrs_1 $currentDir/Bypass/ddr.xdc
}
} else {
update_ip_catalog
if { ([lsearch $options "Live*"] != -1) && ([lsearch $options "Native*"] != -1) } {
source "$currentDir/Live/mmi_dpdc_live.tcl"
if { [regexp "xc2ve3858" $proj_part] } {
add_files -fileset constrs_1 -norecurse $currentDir/Live/ddr.xdc
import_files -fileset constrs_1 $currentDir/Live/ddr.xdc
}
} elseif { ([lsearch $options "Live*"] != -1) && ([lsearch $options "AXI*"] != -1) } {
source "$currentDir/Live/mmi_dpdc_live_st.tcl"
if { [regexp "xc2ve3858" $proj_part] } {
add_files -fileset constrs_1 -norecurse $currentDir/Live/ddr.xdc
import_files -fileset constrs_1 $currentDir/Live/ddr.xdc
}
} elseif { ([lsearch $options "Mixed*"] != -1)} {
source "$currentDir/Mixed/mmi_dpdc_mixed.tcl"
if { [regexp "xc2ve3858" $proj_part] } {
add_files -fileset constrs_1 -norecurse $currentDir/Mixed/ddr.xdc
import_files -fileset constrs_1 $currentDir/Mixed/ddr.xdc
}
} else {
source "$currentDir/Non_Live/mmi_dpdc_nonlive.tcl"
if { [regexp "xc2ve3858" $proj_part] } {
add_files -fileset constrs_1 -norecurse $currentDir/Non_Live/ddr.xdc
import_files -fileset constrs_1 $currentDir/Non_Live/ddr.xdc
}
}
}
create_root_design "" $design_name
set proj_name [lindex [get_projects] 0]
set proj_dir [get_property DIRECTORY $proj_name]
set_property TARGET_LANGUAGE Verilog $proj_name
open_bd_design [get_bd_files $design_name]
set_property generate_synth_checkpoint true [get_files -norecurse *.bd]
set_property synth_checkpoint_mode Hierarchical [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]
generate_target all [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]
set_property generate_synth_checkpoint true [get_files -norecurse *.bd]
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
save_bd_design
launch_runs synth_1 -jobs 28
wait_on_runs synth_1
open_run synth_1
if { ![regexp "xc2ve3858" $proj_part] } {
xphy::generate_constraints
set ddr_xdc [file join $proj_dir ddr.xdc]
close [ open $ddr_xdc w ]
add_files -fileset constrs_1 $ddr_xdc
set_property target_constrs_file $ddr_xdc [current_fileset -constrset]
save_constraints -force
set_property needs_refresh false [get_runs synth_1]
}
}
