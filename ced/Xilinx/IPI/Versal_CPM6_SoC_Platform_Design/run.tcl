# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################
proc get_opt {options key default} {
  # CED framework passes option keys suffixed with ".VALUE" (e.g. "CTRL1_CONFIG.VALUE").
  # Check that form first, then fall back to a bare key for manual/console invocation.
  if {[dict exists $options "${key}.VALUE"]} { return [dict get $options "${key}.VALUE"] }
  if {[dict exists $options $key]}           { return [dict get $options $key] }
  return $default
}

proc createDesign {design_name options} {
  variable currentDir
  # ----------------------------------------------------------------
  # Parse per-controller CPM6 port type
  # ----------------------------------------------------------------
  set ctrl0_config [get_opt $options CTRL0_CONFIG "Disabled"]
  set ctrl1_config [get_opt $options CTRL1_CONFIG "Disabled"]
  set ddr_enabled [get_opt $options DDR_EN "false"]
  set ctrl0_lane_rate [get_opt $options CTRL0_LANE_RATE "64.0_GT/s"]
  set ctrl0_link_width [get_opt $options CTRL0_LINK_WIDTH "X8"]
  set ctrl1_lane_rate [get_opt $options CTRL1_LANE_RATE "64.0_GT/s"]
  set ctrl1_link_width [get_opt $options CTRL1_LINK_WIDTH "X8"]

  puts "INFO: CTRL0 Config = $ctrl0_config"
  puts "INFO: CTRL1 Config = $ctrl1_config"
  puts "INFO: DDR Enabled  = $ddr_enabled"
  puts "INFO: CTRL0 Link Speed/Width = $ctrl0_lane_rate / $ctrl0_link_width"
  puts "INFO: CTRL1 Link Speed/Width = $ctrl1_lane_rate / $ctrl1_link_width"

  if { $ctrl0_config eq "Disabled" && $ctrl1_config eq "Disabled" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" \
      "At least one of CTRL0_CONFIG/CTRL1_CONFIG must be Rootport or Endpoint."}
    return 1
  }

  ##################################################################
  # DESIGN PROCs — source the single parameterized BD TCL. Controller
  # presence/mode (Rootport/Endpoint/Disabled per side), DDR, and per-controller
  # link speed/width are all branched on internally via if/else inside
  # create_root_design, rather than one pre-built folder per combination.
  ##################################################################
  source "${currentDir}/design_1_bd.tcl"
  set_property synth_checkpoint_mode None [get_files $design_name.bd]
  puts "INFO: CPM6 SoC Platform BD generated (CTRL0=$ctrl0_config, CTRL1=$ctrl1_config, DDR=$ddr_enabled)"

  # This design has no custom top-level RTL wrapping the BD (unlike BMD's ctrl0/ctrl1_bmd_ep),
  # so a synthesizable HDL wrapper must be generated and set as the design top explicitly.
  make_wrapper -files [get_files $design_name.bd] -top -import

  open_bd_design [get_files $design_name.bd]
  regenerate_bd_layout

  puts "INFO: design generation completed successfully"
}
