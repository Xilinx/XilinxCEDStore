########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
########################################################################
# Versal CPM6 PCIe Root Port CED - design generation.
# Source init.tcl, not this file: createDesign needs the currentDir it sets.

proc get_opt {options key default} {
  if {[dict exists $options "${key}.VALUE"]} { return [dict get $options "${key}.VALUE"] }
  if {[dict exists $options $key]}           { return [dict get $options $key] }
  return $default
}

proc copy_overlay {src dst} {
  if {[file isdirectory $src]} {
    if {![file exists $dst]} { file mkdir $dst }
    foreach item [glob -nocomplain -directory $src *] {
      copy_overlay $item [file join $dst [file tail $item]]
    }
  } else {
    file copy -force $src $dst
  }
}

proc createDesign {design_name options} {
  variable currentDir

  # ----------------------------------------------------------------
  # Options
  # ----------------------------------------------------------------
  set mode        [get_opt $options DESIGN_MODE     "AXI_Bridge"]
  set ctrl_config [get_opt $options CTRL_CONFIG     "Controller_1"]
  set ddr_raw     [get_opt $options DDR_EN          "false"]
  set lane_rate   [get_opt $options CTRL_LANE_RATE  "64.0_GT/s"]
  set link_width  [get_opt $options CTRL_LINK_WIDTH "X8"]

  set known_opts {DESIGN_MODE CTRL_CONFIG DDR_EN CTRL_LANE_RATE CTRL_LINK_WIDTH}
  foreach k [dict keys $options] {
    set base [regsub {\.VALUE$} $k ""]
    if {[lsearch -exact $known_opts $base] < 0} {
      error "createDesign: unrecognised option '$k'.\n\
             Supported: $known_opts\n\
             If this looks like several options run together, the dict is\
             malformed - a backslash followed by spaces rather than a newline\
             joins words into a single key."
    }
  }

  set ddr_en [expr {[string is true -strict $ddr_raw] ? "DDR_ENABLED" : "DDR_DISABLED"}]
  set link_width_int [string index $link_width end]

  puts "INFO: Design Mode        = $mode"
  puts "INFO: Controller Config  = $ctrl_config"
  puts "INFO: DDR Enablement     = $ddr_en"
  puts "INFO: PCIe Lane Rate     = $lane_rate"
  puts "INFO: PCIe Link Width    = $link_width"

  # ----------------------------------------------------------------
  # Capability guards - fail early, naming what is unsupported
  # ----------------------------------------------------------------
  if {$mode ni {AXI_Bridge PL_Streaming}} {
    error "DESIGN_MODE=$mode is not recognised.\
           Supported: AXI_Bridge, PL_Streaming."
  }
  if {$ctrl_config ni {Controller_0 Controller_1}} {
    error "CTRL_CONFIG=$ctrl_config is not recognised.\
           Supported: Controller_0, Controller_1."
  }
  if {$mode eq "PL_Streaming" && $ddr_en eq "DDR_ENABLED"} {
    error "DDR_EN is not available with DESIGN_MODE=PL_Streaming - there is\
           no PL streaming variant with LPDDR5 via NoC. The GUI greys the option
           out in this mode; a scripted createDesign can still reach here."
  }
  if {$link_width ni {X2 X4 X8}} {
    error "CTRL_LINK_WIDTH=$link_width is not supported.\
           Available: X2, X4, X8."
  }
  if {$lane_rate ni {16.0_GT/s 32.0_GT/s 64.0_GT/s}} {
    error "CTRL_LANE_RATE=$lane_rate is not supported. Available: 16.0_GT/s,\
           32.0_GT/s, 64.0_GT/s."
  }

  # ----------------------------------------------------------------
  # Variant resolution
  # ----------------------------------------------------------------
  set mode_tag [dict get {AXI_Bridge BRDG PL_Streaming PL_STR} $mode]

  switch "${mode_tag}_${ctrl_config}_${ddr_en}" {
    "BRDG_Controller_0_DDR_DISABLED" {
      set sub_name "brdg_ctrl0"
      set g_top    "rp_axi_mmbr_top_wrapper_ctrl0"
    }
    "BRDG_Controller_0_DDR_ENABLED" {
      set sub_name "brdg_ddr_ctrl0"
      set g_top    "rp_axi_mmbr_ddr_top_wrapper_ctrl0"
    }
    "BRDG_Controller_1_DDR_DISABLED" {
      set sub_name "brdg_ctrl1"
      set g_top    "rp_axi_mmbr_top_wrapper_ctrl1"
    }
    "BRDG_Controller_1_DDR_ENABLED" {
      set sub_name "brdg_ddr_ctrl1"
      set g_top    "rp_axi_mmbr_ddr_top_wrapper_ctrl1"
    }
    "PL_STR_Controller_0_DDR_DISABLED" {
      set sub_name "plstr_ctrl0"
      set g_top    "rp_plstr_top_wrapper_ctrl0"
    }
    "PL_STR_Controller_1_DDR_DISABLED" {
      set sub_name "plstr_ctrl1"
      set g_top    "rp_plstr_top_wrapper_ctrl1"
    }
    default {
      error "Internal error: capability guards passed but no variant matched\
             (${mode_tag}_${ctrl_config}_${ddr_en})."
    }
  }

  set src_dir "${currentDir}/${sub_name}"
  if {![file isdirectory $src_dir]} {
    error "Variant directory missing: $src_dir"
  }

  set mode_dir [expr {$mode_tag eq "BRDG" ? "brdg_sim_common" : "plstr_sim_common"}]

  puts "INFO: Variant directory  = $sub_name"
  puts "INFO: Top module         = $g_top"

  # ----------------------------------------------------------------
  # Sources
  # ----------------------------------------------------------------
  if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
  }
  set src_fileset [get_filesets sources_1]

  import_files -norecurse -fileset sources_1 ${currentDir}/src
  import_files -norecurse -fileset sources_1 ${src_dir}/src

  if {$mode_tag eq "PL_STR"} {
    import_files -norecurse -fileset sources_1 ${currentDir}/plstr_src
    import_files -norecurse -fileset sources_1 ${currentDir}/plstr_src/intf
    import_files -norecurse -fileset sources_1 ${currentDir}/plstr_src/src
  }

  if {$ddr_en eq "DDR_ENABLED"} {
    add_files    -fileset constrs_1 -norecurse ${currentDir}/constrs/ddr_vpk360.xdc
    import_files -fileset constrs_1            ${currentDir}/constrs/ddr_vpk360.xdc
  }

  # ----------------------------------------------------------------
  # defines.sv - regenerated in the PROJECT directory, never in the CED source
  # tree, which may be shared or read-only.
  # ----------------------------------------------------------------
  set imported_defines [get_files -of_objects $src_fileset defines.sv]
  if {[llength $imported_defines] != 1} {
    error "Expected exactly one defines.sv in sources_1, found\
           [llength $imported_defines]: $imported_defines"
  }
  set ctrl_int [expr {$ctrl_config eq "Controller_0" ? 0 : 1}]

  set fd [open $imported_defines w]
  puts $fd "package rp_link_pkg;"
  puts $fd "    parameter LINK_WIDTH = $link_width_int;"
  puts $fd "    parameter LANE_RATE  = \"$lane_rate\";"
  puts $fd "    parameter CTRL       = $ctrl_int;"
  puts $fd "endpackage"
  close $fd
  puts "INFO: defines.sv regenerated in project with LINK_WIDTH = $link_width_int,\
        CTRL = $ctrl_int ($ctrl_config)"

  set file_type_map [dict create .sv SystemVerilog .svh {Verilog Header}]
  foreach f [get_files -of_objects $src_fileset] {
    set ext [file extension $f]
    if {[dict exists $file_type_map $ext]} {
      set_property file_type [dict get $file_type_map $ext] [get_files $f]
    }
  }
  set_property -name "top" -value $g_top -objects $src_fileset

  if {$mode_tag eq "PL_STR"} {
    set cmh [get_files -quiet -of_objects $src_fileset config_mem_handler.sv]
    if {[llength $cmh] != 1} {
      error "Expected exactly one config_mem_handler.sv in sources_1, found\
             [llength $cmh]: $cmh"
    }
    set mem_dst [file join [file dirname [file dirname [file normalize $cmh]]] mem]
    file mkdir $mem_dst
    foreach f [glob -nocomplain ${currentDir}/plstr_src/mem/*] {
      file copy -force $f $mem_dst
    }
    puts "INFO: config ROM copied to $mem_dst ([llength [glob -nocomplain $mem_dst/*.hex]] .hex files)"
  }

  if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
  }
  set obj_sim_fileset [get_filesets sim_1]

  # ----------------------------------------------------------------
  # Block design
  # ----------------------------------------------------------------
  set ::link_width $link_width
  set ::lane_rate  $lane_rate

  switch -- [get_property SPEED [get_parts [get_property PART [current_project]]]] {
    -2LHP   { set ::pl0_freq_mhz 300 ; set ::pl0_freq_hz 299997009 }
    default { set ::pl0_freq_mhz 384 ; set ::pl0_freq_hz 383329498 }
  }

  uplevel #0 [list source "${src_dir}/design_1_bd.tcl"]

  set bd_name [set ::design_name]
  if {$bd_name ne $design_name} {
    puts "INFO: block design is named '$bd_name' (createDesign was given '$design_name')"
  }

  set_property synth_checkpoint_mode None [get_files ${bd_name}.bd]
  open_bd_design [get_bd_files $bd_name]

  set cn [string index $ctrl_config end]

  validate_bd_design
  puts "INFO: BD set to CTRL${cn} $link_width @ $lane_rate"

  regenerate_bd_layout
  puts "INFO: block design generated"

  make_wrapper -files [get_files ${bd_name}.bd] -top -import
  set_property -name "top" -value $g_top -objects $src_fileset
  puts "INFO: ${bd_name}_wrapper generated; top re-set to $g_top"

  # ----------------------------------------------------------------
  # Bind our top to the generated wrapper
  # ----------------------------------------------------------------
  if {$bd_name ne "design_1"} {
    set topf [get_files -quiet -of_objects $src_fileset ${g_top}.sv]
    if {[llength $topf] != 1} {
      error "Expected exactly one ${g_top}.sv in sources_1, found\
             [llength $topf]: $topf"
    }
    set topf [file normalize $topf]
    set fh [open $topf r]; set body [read $fh]; close $fh
    set n [regsub -all {design_1_wrapper} $body "${bd_name}_wrapper" body]
    if {$n == 0} {
      error "No design_1_wrapper reference found in $topf - cannot bind the top\
             to the generated wrapper ${bd_name}_wrapper."
    }
    set fh [open $topf w]; puts -nonewline $fh $body; close $fh
    puts "INFO: $g_top rebound to ${bd_name}_wrapper ($n reference(s) rewritten)"
  }

  # ----------------------------------------------------------------
  # Simulation tree - THREE layers, each overlaid on the last:
  #   1. sim/              universal - framework snapshot, agents, tb, filelists
  #   2. <mode>_sim_common shared by every variant of this design mode - and
  #                        where the testlists live, when a mode has them
  #   3. <variant>/sim/    variant-specific verif and filelist
  # ----------------------------------------------------------------
  set proj_dir [get_property directory [current_project]]
  set sim_dst  ${proj_dir}/sim

  if {![file exists $sim_dst]} {
    file copy -force ${currentDir}/sim $proj_dir
    foreach f [glob -nocomplain ${currentDir}/${mode_dir}/*] {
      copy_overlay $f [file join $sim_dst [file tail $f]]
    }
    foreach f [glob -nocomplain ${src_dir}/sim/*] {
      copy_overlay $f [file join $sim_dst [file tail $f]]
    }
    puts "INFO: simulation files copied to $sim_dst (universal + $mode_dir + $sub_name)"
  } else {
    puts "INFO: sim/ already exists at $sim_dst -- skipping copy"
  }

  # ----------------------------------------------------------------
  # Bring-up scripts and the README, alongside sim/
  # ----------------------------------------------------------------
  foreach item {hw README.md} {
    if {![file exists ${proj_dir}/$item]} {
      file copy -force ${currentDir}/$item $proj_dir
      puts "INFO: $item copied to $proj_dir"
    } else {
      puts "INFO: $item already exists at $proj_dir -- skipping copy"
    }
  }

  # ----------------------------------------------------------------
  # Simulation script generation
  # ----------------------------------------------------------------
  set OS [lindex $::tcl_platform(os) 0]
  if {[string equal -nocase $OS "Windows"] == 0} {
    set_property target_simulator VCS [current_project]
    set_property -dict [dict create generate_scripts_only 1 \
                                    top $g_top \
                                    top_lib xil_defaultlib \
                                    vcs.simulate.runtime -all] $obj_sim_fileset

    generate_target all [get_files ${bd_name}.bd]
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1

    if {[info exists ::env(VIVADO_CLIBS)]} {
      set_property compxlib.vcs_compiled_library_dir $::env(VIVADO_CLIBS) [current_project]
    } else {
      puts "WARNING: \$VIVADO_CLIBS is not set -- Vivado will fall back to its default\
            compiled library path"
    }
    launch_simulation -scripts_only
  } else {
    puts "INFO: the VCS simulator is not supported on Windows"
  }

  puts "INFO: design generation completed successfully"
}
