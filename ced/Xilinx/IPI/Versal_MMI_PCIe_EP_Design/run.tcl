proc createDesign {design_name options} {  

variable currentDir
puts $currentDir
##################################################################
# DESIGN PROCs
##################################################################
source "$currentDir/mmi_pcie_ep.tcl"
create_root_design "" $design_name
set proj_name [lindex [get_projects] 0]
set proj_dir [get_property DIRECTORY $proj_name]
set proj_part [get_property PART [current_project]]
set_property TARGET_LANGUAGE Verilog $proj_name
if { [regexp "xc2ve3858" $proj_part] } {
add_files -fileset constrs_1 -norecurse $currentDir/ddr.xdc
import_files -fileset constrs_1 $currentDir/ddr.xdc
}
open_bd_design [get_bd_files $design_name]
generate_target all [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]
set_property generate_synth_checkpoint true [get_files -norecurse *.bd]
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
set_property synth_checkpoint_mode None [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]
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
