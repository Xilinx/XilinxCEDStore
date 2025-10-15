proc createDesign {design_name options} {
variable currentDir
set_property SEGMENTED_CONFIGURATION 1 [current_project]
set proj_name [lindex [get_projects] 0]
set proj_dir [get_property DIRECTORY $proj_name]
set_property TARGET_LANGUAGE Verilog $proj_name
open_bd_design [get_bd_files $design_name]
set board_name [get_property BOARD_NAME [current_board]]
if {[regexp "vek385" $board_name]} {
set_param noc.enableRemapForDdrWithInterleaving 1 
}
##################################################################
# DESIGN PROCs
##################################################################
if { ([lsearch $options "USB*"] == -1) } {
source "$currentDir/base.tcl"
set dir_path [file join $currentDir golden_ncr]

if {[regexp "vek385_" $board_name]} {
set filePattern "vek385_revb_*.ncr"
} elseif {$board_name == "vek385"} {
set filePattern "vek385_reva_*.ncr"
} else {
puts "INFO: Golden NCR is not available for $board_name!!"
}

set noc_ncr [glob -nocomplain -directory $dir_path $filePattern]
set file_name [ lindex [split $noc_ncr "/"] end]
puts "INFO: Importing the golden_noc $file_name to the design!"
import_files -fileset utils_1 $noc_ncr 
set ncr_path [file join [get_property directory [current_project]] [current_project].srcs utils_1 imports golden_ncr]
set_property NOC_SOLUTION_FILE $ncr_path/$file_name [get_runs impl_1]
assign_bd_address
validate_bd_design
save_bd_design
}
if { ([lsearch $options "USB*"] != -1) } {
source "$currentDir/USB/mmi_usb.tcl"
add_files -fileset constrs_1 -norecurse $currentDir/USB/ddr.xdc
import_files -fileset constrs_1 $currentDir/USB/ddr.xdc
create_root_design "" $design_name
} elseif { ([lsearch $options "DC_Bypass*"] != -1) } {
if { ([lsearch $options "true*"] != -1) } {
if { ([lsearch $options "4"] != -1) } {
source "$currentDir/Bypass/mmi_dpdc_bypass4.tcl"
} else {
source "$currentDir/Bypass/mmi_dpdc_bypass2.tcl"
} 
} else {
source "$currentDir/Bypass/mmi_dpdc_bypass1.tcl"
}
} else {
if { ([lsearch $options "Live*"] != -1) && ([lsearch $options "Native*"] != -1) } {
source "$currentDir/Live/mmi_dpdc_live.tcl"
} elseif { ([lsearch $options "Live*"] != -1) && ([lsearch $options "AXI*"] != -1) } {
source "$currentDir/Live/mmi_dpdc_live_st.tcl"
} elseif { ([lsearch $options "Mixed*"] != -1)} {
source "$currentDir/Mixed/mmi_dpdc_mixed.tcl"
} else {
source "$currentDir/Non_Live/mmi_dpdc_nonlive.tcl"
}
}
validate_bd_design
save_bd_design
set_property generate_synth_checkpoint true [get_files -norecurse *.bd]
set_property synth_checkpoint_mode Hierarchical [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]
generate_target all [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]
set_property generate_synth_checkpoint true [get_files -norecurse *.bd]
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
}
