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
  set dma_mode    [get_opt $options DMA_MODE       "Memory_Mapped"]
  set lane_rate   [get_opt $options CTRL_LANE_RATE "64.0_GT/s"]
  # Fallback default must match init.tcl's addOptions CTRL_LINK_WIDTH default
  # (X2). The selected width is passed to the block design script (which sets
  # CPM6_CTRL1_LINK_WIDTH) and written to defines.sv as LINK_WIDTH.
  set link_width  [get_opt $options CTRL_LINK_WIDTH "X2"]
  set link_width_int [string index $link_width end]

  puts "INFO: Controller Config = $ctrl_config"
  puts "INFO: DMA Mode          = $dma_mode"
  puts "INFO: PCIe Lane Rate    = $lane_rate"
  puts "INFO: PCIe Link Width   = $link_width"

  # ----------------------------------------------------------------
  # Set sub-design directory and top module based on controller config
  # ----------------------------------------------------------------
  set ctrl_map [dict create \
    Controller_1    {ctrl1 ctrl1_qdma_ep}     ]
  # Streaming: same controller, streaming sub-design and top
  set ctrl_st_map [dict create \
    Controller_1    {ctrl1_st ctrl1_qdma_st_ep} ]
  if {$dma_mode eq "Streaming"} {
    lassign [dict get $ctrl_st_map $ctrl_config] sub_name g_top
  } else {
    lassign [dict get $ctrl_map $ctrl_config] sub_name g_top
  }
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
  puts $fd "package qdma_link_pkg;"
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

  set_property -name "top" -value $g_top -objects $src_fileset

  # Create sim_1 fileset
  if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
  }
  set obj_sim_fileset [get_filesets sim_1]

  ##################################################################
  # Streaming: the QDMA and mailbox IP versions with the streaming
  # data path ship with this design under ip/. Register them before the
  # block design is built, and stop if either was not taken from there
  # (Vivado falls back to the installed IP when a repository entry cannot
  # be read).
  ##################################################################
  if {$dma_mode eq "Streaming"} {
    set local_ip_root [file normalize "${currentDir}/ip"]
    set_property ip_repo_paths [list $local_ip_root] [current_project]
    update_ip_catalog
    # Compile every IP from source for simulation: the local cpm6_qdma is not
    # the same version as the precompiled library that ships with Vivado.
    set_property sim.use_ip_compiled_libs 0 [current_project]
    foreach ip_name {cpm6_qdma pcie_qdma_mailbox} {
      set from_local 0
      foreach ipdef [get_ipdefs -quiet *:${ip_name}:*] {
        if {[string first $local_ip_root [file normalize [get_property REPOSITORY $ipdef]]] == 0} {
          set from_local 1
        }
      }
      if {!$from_local} {
        error "ERROR: ${ip_name} was not loaded from ${local_ip_root}; see the IP_Flow messages above"
      }
      puts "INFO: ${ip_name} loaded from ${local_ip_root}"
    }
  }

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
  # README and the images it links, next to the project
  foreach item {README.md design_architecture.png cpm6_qdma_g6x2_mm.png cpm6_qdma_g6x2_st.png} {
    if {![file exists ${proj_dir}/$item]} {
      file copy -force ${currentDir}/$item $proj_dir
      puts "INFO: $item copied to $proj_dir"
    } else {
      puts "INFO: $item already exists at $proj_dir -- skipping copy"
    }
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
