# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################
proc replace_file_contents {file string_map} {
    set fd [open $file];set contents [read $fd]; close $fd
    set contents [string map $string_map $contents]
    set fd [open $file w]; puts -nonewline $fd $contents; close $fd
}

# Recursively copy $src onto $dst, merging directories that already exist
# at the destination instead of erroring out (Tcl's `file copy -force` does
# NOT merge two same-named directories -- it errors if the destination
# directory already exists). Used to overlay a variant's sim/* files
# (e.g. dma/sim/verif/) on top of the base sim/ tree already copied into
# the project directory.
proc copy_overlay {src dst} {
  if {[file isdirectory $src]} {
    if {![file exists $dst]} {
      file mkdir $dst
    }
    foreach item [glob -nocomplain -directory $src *] {
      copy_overlay $item [file join $dst [file tail $item]]
    }
  } else {
    file copy -force $src $dst
  }
}

proc createDesign {design_name options} {
  variable currentDir
  puts "DEBUG: options dict = $options"
  # ----------------------------------------------------------------
  # Parse controller config, lane rate and link width
  # ----------------------------------------------------------------
  set ctrl_config "Controller_1" ; if {[dict exists $options CTRL_CONFIG]}   { set ctrl_config [dict get $options CTRL_CONFIG] }
  set dma_ddr_enabled false
  if {[dict exists $options DDR_EN.VALUE]} { set dma_ddr_enabled [dict get $options DDR_EN.VALUE] }
  set ddr_en [expr {$dma_ddr_enabled ? "DDR_ENABLED" : "DDR_DISABLED"}]
  set num_pfs 1                 ; if {[dict exists $options NUM_PFS]}   { set num_pfs [dict get $options NUM_PFS] }
  set lane_rate   "64.0_GT/s"   ; if {[dict exists $options CTRL_LANE_RATE]}  { set lane_rate   [dict get $options CTRL_LANE_RATE] }
  set link_width  "X8"          ; if {[dict exists $options CTRL_LINK_WIDTH]} { set link_width  [dict get $options CTRL_LINK_WIDTH] }
  set link_width_int [string index $link_width end]
  
  puts "INFO: DMA EN            = $dma_ddr_enabled"
  puts "INFO: Controller Config = $ctrl_config"
  puts "INFO: PCIe Link Width   = $link_width"
  puts "INFO: PCIe Lane Rate    = $lane_rate"
  puts "INFO: DDR Enablament    = $ddr_en"
  puts "INFO: Num of PF's       = $num_pfs"

  # ----------------------------------------------------------------
  # Set sub-design directory and top module based on controller config
  # ----------------------------------------------------------------
  switch "${ctrl_config}_${ddr_en}" {
    "Controller_0_DDR_ENABLED" { set sub_name "dma_ddr_ctrl0"; set g_top "dma_ddr_top" }
    "Controller_1_DDR_ENABLED" { set sub_name "dma_ddr";       set g_top "dma_ddr_top" }
    "Controller_0_DDR_DISABLED"  { set sub_name "dma_ctrl0";     set g_top "design_1_wrapper" }
    "Controller_1_DDR_DISABLED"  { set sub_name "dma";           set g_top "dma_top" }
    default {
      error "Unsupported combination CTRL_CONFIG=$ctrl_config DDR_EN=$ddr_en"
    }
  }
  set src_dir "${currentDir}/${sub_name}"

  if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
  }

  set src_fileset [get_filesets sources_1]
  # Import all source files from the selected sub-design
  import_files -norecurse -fileset sources_1 ${currentDir}/src
  import_files -norecurse -fileset sources_1 ${src_dir}/src
# Add DDR pin constraints for DDR_ENABLED (same pattern as Versal_MMI_PCIe_EP_Design)
if { $ddr_en eq "DDR_ENABLED" } {
    add_files -fileset constrs_1 -norecurse $currentDir/constrs/noc_ddr5_phy_phy.xdc
    import_files -fileset constrs_1 $currentDir/constrs/noc_ddr5_phy_phy.xdc
}
  # Regenerate the defines file in the PROJECT directory (not CED source dir)
  # This avoids permission issues when CED is shared/read-only
  set imported_defines [get_files -of_objects $src_fileset defines.sv]
  if {[llength $imported_defines] != 1} {
    error "Expected exactly one defines.sv in sources_1, found [llength $imported_defines]: $imported_defines"
  }
  set fd [open $imported_defines w]
  puts $fd "package dma_link_pkg;"
  puts $fd "    parameter LINK_WIDTH    = $link_width_int;"
  puts $fd "    parameter LANE_RATE = \"$lane_rate\";"
  puts $fd "    parameter NUM_PFS = $num_pfs;"
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
      copy_overlay $file [file join $sim_dst [file tail $file]]
    }
    puts "INFO: Simulation files copied to $sim_dst"
  } else {
    puts "INFO: sim/ already exists at $sim_dst -- skipping copy"
  }  
  if { [string equal -nocase $OS "Windows"] == 0 } {
    set_property target_simulator VCS [current_project]
    set_property -dict [dict create generate_scripts_only 1 top $g_top top_lib xil_defaultlib vcs.simulate.runtime -all] $obj_sim_fileset
  } else {
    puts "INFO: VCS simulator does not support Windows"
  }
}