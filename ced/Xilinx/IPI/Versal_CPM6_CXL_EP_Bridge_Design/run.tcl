# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################

proc get_opt {options key default} {
  # CED framework passes option keys suffixed with ".VALUE" (e.g. "CTRL_CONFIG.VALUE").
  # Check that form first, then fall back to a bare key for manual/console invocation.
  if {[dict exists $options "${key}.VALUE"]} { return [dict get $options "${key}.VALUE"] }
  if {[dict exists $options $key]}           { return [dict get $options $key] }
  return $default
}

# Translates the GUI's human-friendly value_list strings ("256B_Flit"/
# "68B_Flit", "x4"/"x8") back to the canonical CXL_3_1/CXL_2_0/X4/X8 tokens
# the rest of the build system expects; canonical values pass through unchanged.
proc normalize_cxl_protocol {val} {
  # GUI-driven instantiate_example_design can return the token with its
  # underscore rendered as a space ("256B Flit") - normalize before matching.
  set val [string map {" " "_"} $val]
  switch -exact -- $val {
    "256B_Flit" { return "CXL_3_1" }
    "68B_Flit"  { return "CXL_2_0" }
    "CXL_3_1"   { return "CXL_3_1" }
    "CXL_2_0"   { return "CXL_2_0" }
    default     { error "ERROR: Unrecognized CXL_PROTOCOL value: $val" }
  }
}
proc normalize_cxl_width {val} {
  switch -exact -- $val {
    "x4" { return "X4" }
    "x8" { return "X8" }
    "X4" { return "X4" }
    "X8" { return "X8" }
    default { error "ERROR: Unrecognized CXL_WIDTH value: $val" }
  }
}

proc createDesign {design_name options} {
  variable currentDir

  # ----------------------------------------------------------------
  # Parse controller selection and CXL protocol/generation
  # ----------------------------------------------------------------
  set ctrl_config   [get_opt $options CTRL_CONFIG   "Controller_1"]
  set cxl_protocol  [normalize_cxl_protocol [get_opt $options CXL_PROTOCOL  "256B Flit"]]
  set cxl_width     [normalize_cxl_width [get_opt $options CXL_WIDTH "x8"]]

  # Reject a stale caller still requesting NFI explicitly rather than
  # silently building CPI instead.
  set cxl_flit_mode [get_opt $options CXL_FLIT_MODE "CPI"]
  if {$cxl_flit_mode ne "CPI"} {
    error "Unsupported CXL_FLIT_MODE=$cxl_flit_mode (this design is CPI-only)"
  }

  puts "INFO: Controller Config = $ctrl_config"
  puts "INFO: CXL Protocol      = $cxl_protocol"
  puts "INFO: CXL Width         = $cxl_width"

  # Each controller gets its own dedicated BD source folder.
  # Transport extension point: key this dict by (ctrl_config,mode) and add
  # a sibling BD folder per mode if another transport is needed.
  set ctrl_dir_map [dict create \
    Controller_0 ctrl0_cpi \
    Controller_1 ctrl1_cpi ]
  if {![dict exists $ctrl_dir_map $ctrl_config]} {
    error "Unsupported CTRL_CONFIG=$ctrl_config"
  }
  set sub_name [dict get $ctrl_dir_map $ctrl_config]

  set local_ip_root "${currentDir}/ip"
  set src_dir     "${currentDir}/${sub_name}"
  puts "INFO: Sourcing BD from ${src_dir}/design_1_bd.tcl"

  if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
  }

  # Register the local IP repository so cxl_mem_wrapper:1.0 is discoverable
  set_property ip_repo_paths [list $local_ip_root] [current_project]
  update_ip_catalog

  # Add ctrl_reg_ep RTL (module-referenced in the block design)
  import_files -norecurse -fileset sources_1 ${currentDir}/src/ctrl_reg_ep.v

  # Add DDR PHY pin constraints
  add_files    -fileset constrs_1 -norecurse ${currentDir}/constrs/ddr_c0c1c4c5.xdc
  import_files -fileset constrs_1            ${currentDir}/constrs/ddr_c0c1c4c5.xdc

  # parameter overrides for TOP/BOT_PL_MUX_MODE for timing arc (implementation only)
  set cxl_mode_xdc [dict get [dict create Controller_0 ctrl0_timings.xdc Controller_1 ctrl1_timings.xdc] $ctrl_config]
  import_files -fileset constrs_1 ${currentDir}/constrs/${cxl_mode_xdc}
  set cxl_mode_xdc_obj [get_files -of_objects [get_filesets constrs_1] -filter "NAME =~ *${cxl_mode_xdc}"]
  if {[llength $cxl_mode_xdc_obj] != 1} { error "ERROR: expected exactly one ${cxl_mode_xdc} in constrs_1, found: $cxl_mode_xdc_obj" }
  set_property USED_IN_SYNTHESIS false $cxl_mode_xdc_obj
  set_property USED_IN_IMPLEMENTATION true $cxl_mode_xdc_obj
  puts "INFO: CPM6 PL mux mode constraints ${cxl_mode_xdc} added: USED_IN_SYNTHESIS=[get_property USED_IN_SYNTHESIS $cxl_mode_xdc_obj] USED_IN_IMPLEMENTATION=[get_property USED_IN_IMPLEMENTATION $cxl_mode_xdc_obj]"

  # Build the block design
  source "${src_dir}/design_1_bd.tcl"

  set_property synth_checkpoint_mode None [get_files ${design_name}.bd]
  puts "INFO: CXL EP Bridge block design generated"

  open_bd_design [get_bd_files $design_name]
  regenerate_bd_layout

  # Generate the HDL wrapper, import it, and set it as the synthesis top
  make_wrapper -files [get_files ${design_name}.bd] -top -import
  set_property top ${design_name}_wrapper [get_filesets sources_1]
  update_compile_order -fileset sources_1

  set_property strategy Performance_AggressiveExplore [get_runs impl_1]

  set cxl_part [get_property PART [current_project]]
  set cxl_vdef [get_property verilog_define [get_filesets sources_1]]
  if {[string match "*-3HP-*" $cxl_part]} {
    puts "INFO: Part $cxl_part: CXL_PIPELINE_EN not set"
  } else {
    if {[lsearch -exact $cxl_vdef CXL_PIPELINE_EN] < 0} { lappend cxl_vdef CXL_PIPELINE_EN }
    set_property verilog_define $cxl_vdef [get_filesets sources_1]
    puts "INFO: Part $cxl_part: CXL_PIPELINE_EN set"
  }

  # -2 parts with 256B flit (Gen6) and x8 need these strategies to meet timing.
  if {![string match "*-3HP-*" $cxl_part] && $cxl_protocol eq "CXL_3_1" && $cxl_width eq "X8"} {
    set cxl_strats {synth_1 Flow_PerfThresholdCarry}
    if {[string match "*-2MP-*" $cxl_part]} { lappend cxl_strats impl_1 Performance_ExplorePostRoutePhysOpt }
    foreach {cxl_run cxl_strat} $cxl_strats {
      if {[lsearch -exact [list_property_value strategy [get_runs $cxl_run]] $cxl_strat] >= 0} {
        set_property strategy $cxl_strat [get_runs $cxl_run]
        puts "INFO: Part $cxl_part: $cxl_run strategy set to $cxl_strat"
      } else {
        puts "WARNING: strategy $cxl_strat is not available for $cxl_run, keeping [get_property strategy [get_runs $cxl_run]]"
      }
    }
  }

  puts "INFO: CXL EP Bridge design generation completed successfully"
}
