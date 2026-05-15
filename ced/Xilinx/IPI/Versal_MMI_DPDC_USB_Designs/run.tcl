proc createDesign {design_name options} {
variable currentDir
set_property SEGMENTED_CONFIGURATION 1 [current_project]
set proj_name [lindex [get_projects] 0]
set proj_dir [get_property DIRECTORY $proj_name]
set_property TARGET_LANGUAGE Verilog $proj_name
remove_files [get_files ${design_name}.bd]
file delete -force [file normalize "${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}"]
set board_name [get_property BOARD_NAME [current_board]]
if {[regexp "vek385" $board_name]} {
set_param noc.enableRemapForDdrWithInterleaving 1 
}
##################################################################
# DESIGN PROCs
##################################################################
if { ([lsearch $options "USB*"] != -1) } {
set design mmi_usb
source "$currentDir/USB/mmi_usb.tcl"
add_files -fileset constrs_1 -norecurse $currentDir/USB/ddr.xdc
import_files -fileset constrs_1 $currentDir/USB/ddr.xdc
create_root_design "" $design

validate_bd_design
save_bd_design
set_property synth_checkpoint_mode Hierarchical [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd]
generate_target all [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd]
set_property generate_synth_checkpoint true [get_files -norecurse *.bd]
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd] -top
add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/hdl/${design}_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

} elseif { ([lsearch $options "Dual_Display_GPU*"] != -1) } {
set design mmi_dual_display_gpu_hdmi_dp
source "$currentDir/Dual_Display_GPU/dual_display_GPU_hdmi_dp.tcl"

remove_files ${proj_dir}/${proj_name}.srcs/sources_1/ip/*/*xci
file delete -force {*}[glob -nocomplain ${proj_dir}/${proj_name}.srcs/sources_1/ip/*]

remove_files ${proj_dir}/${proj_name}.srcs/sources_1/imports/hdl/${design}_wrapper.v
file delete -force ${proj_dir}/${proj_name}.srcs/sources_1/imports/hdl/${design}_wrapper.v
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd] -top -force
add_files -norecurse ${proj_dir}/${proj_name}.gen/sources_1/bd/$design/hdl/${design}_wrapper.v
validate_bd_design
save_bd_design
generate_target all [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

} elseif { ([lsearch $options "DC_Bypass*"] != -1) } {
# Check Stream_Source value
if { ([lsearch $options "DDR_(SST)*"] != -1) } {
# Single Stream from DDR
set design mmi_dpdc_bypass_1st_ddr
source "$currentDir/Bypass/mmi_dpdc_bypass1_ddr.tcl"
} elseif { ([lsearch $options "AVTPG_and_DDR_(MST)*"] != -1) } {
# 2 Streams - One from DDR and other from AVTPG
set design mmi_dpdc_bypass_2st_ddr_avtpg
source "$currentDir/Bypass/mmi_dpdc_bypass2_ddr_avtpg.tcl"
} else {
# AVTPG stream source path (existing logic)
if { ([lsearch $options "true*"] != -1) } {
if { ([lsearch $options "4"] != -1) } {
set design mmi_dpdc_bypass_4st
source "$currentDir/Bypass/mmi_dpdc_bypass4.tcl"
} else {
set design mmi_dpdc_bypass_2st
source "$currentDir/Bypass/mmi_dpdc_bypass2.tcl"
} 
} else {
set design mmi_dpdc_bypass_1st
source "$currentDir/Bypass/mmi_dpdc_bypass1.tcl"
}
}

validate_bd_design
save_bd_design
set_property synth_checkpoint_mode Hierarchical [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd]
generate_target all [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd]
set_property generate_synth_checkpoint true [get_files -norecurse *.bd]
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd] -top -force
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

} else {
if { ([lsearch $options "Live*"] != -1) && ([lsearch $options "Native*"] != -1) } {
set design mmi_dpdc_live_native_st
source "$currentDir/Live/mmi_dpdc_live.tcl"
} elseif { ([lsearch $options "Live*"] != -1) && ([lsearch $options "AXI*"] != -1) } {
set design mmi_dpdc_live_axi_st
source "$currentDir/Live/mmi_dpdc_live_st.tcl"
} elseif { ([lsearch $options "Mixed*"] != -1)} {
set design mmi_dpdc_mixed
source "$currentDir/Mixed/mmi_dpdc_mixed.tcl"
} else {
set design mmi_dpdc_nonlive
source "$currentDir/Non_Live/mmi_dpdc_nonlive.tcl"
}
validate_bd_design
save_bd_design
set_property synth_checkpoint_mode Hierarchical [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd]
generate_target all [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd]
set_property generate_synth_checkpoint true [get_files -norecurse *.bd]
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design}/${design}.bd] -top -force
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
}
}
