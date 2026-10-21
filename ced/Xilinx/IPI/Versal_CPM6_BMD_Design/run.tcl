# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################
proc replace_file_contents {file string_map} {    
    set fd [open $file];set contents [read $fd]; close $fd
    set contents [string map $string_map $contents]
    set fd [open $file w]; puts -nonewline $fd $contents; close $fd  
}
proc get_opt {options key default} {
  # CED framework passes option keys suffixed with ".VALUE" (e.g. "CTRL_CONFIG.VALUE").
  # Check that form first, then fall back to a bare key for manual/console invocation.
  if {[dict exists $options "${key}.VALUE"]} { return [dict get $options "${key}.VALUE"] }
  if {[dict exists $options $key]}           { return [dict get $options $key] }
  return $default
}

proc createDesign {design_name options} {
  variable currentDir
  # ----------------------------------------------------------------
  # Parse controller config, lane rate and link width
  # ----------------------------------------------------------------
  set ctrl_config [get_opt $options CTRL_CONFIG    "Controller_1"]
  set lane_rate   [get_opt $options CTRL_LANE_RATE "64.0_GT/s"]
  set link_width  [get_opt $options CTRL_LINK_WIDTH "X4"]
  set link_width_int [string index $link_width end]

  puts "INFO: Controller Config = $ctrl_config"
  puts "INFO: PCIe Lane Rate    = $lane_rate"
  puts "INFO: PCIe Link Width   = $link_width"

  # ----------------------------------------------------------------
  # Set sub-design directory and top module based on controller config
  # ----------------------------------------------------------------
  set ctrl_map [dict create \
    Dual_Controller {dual  dual_ctrl_bmd_ep} \
    Controller_0    {ctrl0 ctrl0_bmd_ep}     \
    Controller_1    {ctrl1 ctrl1_bmd_ep}     ]
  lassign [dict get $ctrl_map $ctrl_config] sub_name g_top
  set src_dir "${currentDir}/${sub_name}"

  # Create 'sources_1' fileset
  if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
  }
  set src_fileset [get_filesets sources_1]
  # Import all source files from the selected sub-design
  import_files -norecurse -fileset sources_1 ${currentDir}/src
  import_files -norecurse -fileset sources_1 ${src_dir}/src
  
  # Regenerate the defines file in the PROJECT directory (not CED source dir)
  # This avoids permission issues when CED is shared/read-only
  set imported_defines [get_files -of_objects $src_fileset defines.sv]
  set fd [open $imported_defines w]
  puts $fd "package bmd_link_pkg;"
  puts $fd "    parameter LINK_WIDTH = $link_width_int;"
  puts $fd "    parameter LANE_RATE = \"$lane_rate\";"
  puts $fd "endpackage"
  close $fd
  puts "INFO: defines.sv updated in project with width = $link_width_int"

  # Set file types
  set file_type_map [dict create .sv SystemVerilog .svh {Verilog Header}]
  foreach f [get_files -of_objects $src_fileset] {
    set ext [file extension $f]
    if {[dict exists $file_type_map $ext]} {
      set_property file_type [dict get $file_type_map $ext] [get_files $f]
    }
  }
  
  # Update CPM6 Package revision
  set cpm6_rev [get_property CORE_REVISION [get_ipdefs -all *:cpm6:*]]
  set pkg_rev_map [list cpm6_v1_0_pkg cpm6_v1_0_${cpm6_rev}_pkg]  
  foreach file {BMD_AXIST.sv BMD_AXIST_CFG.sv BMD_AXIST_EP.sv pcie_app_versal_bmd.sv} {
    replace_file_contents [get_files $file] $pkg_rev_map
  }
  set_property -name "top" -value $g_top -objects $src_fileset

  # Create sim_1 fileset
  if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
  }
  set obj_sim_fileset [get_filesets sim_1]

  ##################################################################
  # DESIGN PROCs — source the correct BD TCL
  ##################################################################
  source "${src_dir}/design_1_bd.tcl"
  set_property synth_checkpoint_mode None [get_files $design_name.bd]
  puts "INFO: EP bd generated"
  open_bd_design [get_bd_files $design_name]
  regenerate_bd_layout  

  puts "INFO: design generation completed successfully"

  set OS [lindex $::tcl_platform(os) 0]
  # Copy simulation infrastructure alongside the Vivado project
  set proj_dir [get_property directory [current_project]]
  set sim_dst ${proj_dir}/sim
  if {![file exists $sim_dst]} {    
    file copy -force ${currentDir}/sim $proj_dir
    foreach file [glob -nocomplain ${src_dir}/sim/*] {
      file copy -force $file $sim_dst
    }
    puts "INFO: Simulation files copied to $sim_dst"
  } else {
    puts "INFO: sim/ already exists at $sim_dst -- skipping copy"
  }  
  if { [string equal -nocase $OS "Windows"] == 0 } {
    set_property target_simulator VCS [current_project]
    set_property -dict [dict create generate_scripts_only 1 top $g_top top_lib xil_defaultlib vcs.simulate.runtime -all] $obj_sim_fileset

    generate_target all [get_files $design_name.bd]
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
    if {[info exists ::env(VIVADO_CLIBS)]} {
      set_property compxlib.vcs_compiled_library_dir $::env(VIVADO_CLIBS) [current_project]
    } else {
      puts "WARNING: \$VIVADO_CLIBS is not set -- Vivado will fall back to its default compiled library path"
    }
    launch_simulation -scripts_only
  } else {
    puts "INFO: VCS simulator does not support Windows"
  }
}
