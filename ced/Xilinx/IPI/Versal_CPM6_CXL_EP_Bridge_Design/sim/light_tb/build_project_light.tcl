# build_project_light.tcl - Path 2 project + sim_1 fileset driver.
#
# Same DUT project creation as ../standalone/build_project.tcl, but wires
# this directory's own testbench (board.sv, sys_clk_gen*.v,
# csr_sanity_test.vh) directly into Vivado's sim_1 fileset as the sim top.
#
# Usage:
#   cd Versal_CPM6_CXL_EP_Bridge_Design/sim/light_tb
#   vivado -mode batch -source build_project_light.tcl \
#     -tclargs <workdir> [Controller_0|Controller_1] [CXL_3_1|CXL_2_0]
#
# Then: cd <workdir>/design_1.sim/sim_1/behav/vcs && ./compile.sh &&
# ./elaborate.sh && ./simulate.sh. No Avery VIP/uvma_agents/external
# Makefile needed - only Vivado + a licensed simulator + $CPM6_SECUREIP.

set script_dir  [file dirname [file normalize [info script]]]
set design_root [file normalize [file join $script_dir .. ..]]

if {[llength $argv] < 1} {
  puts "ERROR: usage: vivado -mode batch -source build_project_light.tcl -tclargs <workdir> \[Controller_0|Controller_1\] \[CXL_3_1|CXL_2_0\]"
  exit 1
}
if {![info exists ::env(VIVADO_CLIBS)]} {
  puts "ERROR: \$VIVADO_CLIBS is not set. Point it at this site's"
  puts "  precompiled Xilinx VCS simulation library dir (the same VCS build"
  puts "  Vivado's own clibs were compiled against - e.g. a path ending in"
  puts "  .../clibs/vcs/<vcs-version>/lin64/lib), then re-run."
  exit 1
}
set vcs_clibs_dir [set ::env(VIVADO_CLIBS)]
set workdir      [lindex $argv 0]
set ctrl_config  [expr {[llength $argv] > 1 ? [lindex $argv 1] : "Controller_1"}]
set cxl_protocol [expr {[llength $argv] > 2 ? [lindex $argv 2] : "CXL_3_1"}]

# --- Copy this design's sim/ tree into the workdir ---
# Compile/elaborate/simulate must never read live from the CED checkout -
# copy the whole sim/ tree into $workdir/sim first (delete-then-copy, not
# an in-place merge, so a stale prior copy never silently shadows a newer
# checkout), then reference the copy below instead of $design_root/sim.
# Guarded against copying sim/ into itself or a nested subdirectory of
# itself.
file mkdir $workdir
set sim_src [file normalize "$design_root/sim"]
set sim_dst [file normalize "$workdir/sim"]
if {[string equal $sim_dst $sim_src] ||
    [string equal [string range $sim_dst 0 [string length $sim_src]] "$sim_src/"]} {
  puts "INFO: $workdir/sim already exists - skipping copy."
} else {
  if {[file isdirectory $sim_dst]} {
    file delete -force $sim_dst
  }
  file copy $sim_src $sim_dst
  puts "INFO: copied sim/ into $sim_dst"
}

create_project design_1 $workdir -part xc2vp3602-vsvc3340-3HP-e-S -force
source [file join $design_root init.tcl]
createDesign design_1 [dict create CTRL_CONFIG $ctrl_config CXL_PROTOCOL $cxl_protocol]

# --- Wire this directory's testbench into sim_1 ---
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}
set sim_obj [get_filesets sim_1]

set tb_files [list \
  [file normalize "$sim_dst/light_tb/sys_clk_gen.v"] \
  [file normalize "$sim_dst/light_tb/sys_clk_gen_ds.v"] \
  [file normalize "$sim_dst/light_tb/board.sv"] \
]
import_files -norecurse -fileset $sim_obj $tb_files
# xlnoc_glue.v is deliberately NOT imported into this fileset: it's a
# parallel top with no structural reference from board.sv, so Vivado's
# dependency-based compile.sh generation would silently exclude it.
# Compiled instead by appending directly to compile.sh (see below).

# board.sv is .sv (not .v) since it uses SystemVerilog-only constructs
# (logic types, virtual interfaces, typedef struct, package imports).
# -ntb_opts uvm-1.2 is required: a custom sim_1 fileset doesn't automatically
# get UVM support the way Vivado's IP-driven flow does, and board.sv needs
# uvm_macros.svh/uvm_pkg.
set_property -name {vcs.compile.vlogan.more_options} \
  -value "-ntb_opts uvm-1.2 +define+LIGHT_TB_ROOT +incdir+$sim_dst/light_tb +incdir+$sim_dst/tb" \
  -objects $sim_obj

set_property target_simulator VCS [current_project]
# Both must be disabled BEFORE setting top, and in this order - otherwise
# Vivado's default BD-wrapper-sim auto-top detection silently overrides it.
set_property SIM_WRAPPER_TOP 0 [get_filesets sim_1]
set_property top_auto_set 0 [get_filesets sim_1]
set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "DEBUG: sim_1 top            = [get_property top [get_filesets sim_1]]"
puts "DEBUG: sim_1 top_lib        = [get_property top_lib [get_filesets sim_1]]"
puts "DEBUG: sim_1 top_auto_set   = [get_property top_auto_set [get_filesets sim_1]]"
puts "DEBUG: sim_1 file list      = [get_files -of_objects [get_filesets sim_1]]"

# Compiled library location - site-specific, so it comes from
# $VIVADO_CLIBS (checked above) rather than being hardcoded.
set_property compxlib.vcs_compiled_library_dir $vcs_clibs_dir [current_project]

puts "INFO: sim_1 fileset configured, top=board, target_simulator=VCS"
puts "INFO: generating simulation scripts only (no compile/elaborate/run here)..."
launch_simulation -scripts_only

# xlnoc.v (NoC sim model) only exists on disk after launch_simulation runs,
# and xlnoc_glue.v is a parallel top with no reference from board.sv, so
# neither can be wired in via a normal fileset import - append them to the
# already-generated compile.sh/elaborate.sh directly instead.
set xlnoc_sim_v "$workdir/design_1.gen/sim_1/bd/xlnoc/sim/xlnoc.v"
set compile_sh  "$workdir/design_1.sim/sim_1/behav/vcs/compile.sh"
if {![file exists $xlnoc_sim_v]} {
  puts "WARNING: $xlnoc_sim_v not found after launch_simulation - xlnoc (NoC sim model) not wired in; xlnoc_glue.v will fail to elaborate (undefined module 'xlnoc')."
} elseif {![file exists $compile_sh]} {
  puts "WARNING: $compile_sh not found - cannot append xlnoc/xlnoc_glue compilation."
} else {
  set fh [open $compile_sh r]
  set compile_content [read $fh]
  close $fh
  if {[string first "xlnoc_glue.v" $compile_content] == -1} {
    set xlnoc_glue_v [file normalize "$sim_dst/tb/xlnoc_glue.v"]
    append compile_content "\n# --- Appended: xlnoc (NoC Packet Switch sim model) + xlnoc_glue.v ---\n"
    append compile_content "vlogan -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps +define+LIGHT_TB_ROOT -work xil_defaultlib \"$xlnoc_sim_v\" \"$xlnoc_glue_v\" -l vlogan.xlnoc.log\n"
    set fh [open $compile_sh w]
    puts -nonewline $fh $compile_content
    close $fh
    puts "INFO: appended xlnoc.v + xlnoc_glue.v compilation to compile.sh"
  }
}

# xlnoc_glue.v is a parallel top with no ports - added as an additional
# VCS elaboration target alongside `board`, not nested inside it.
set elab_sh "$workdir/design_1.sim/sim_1/behav/vcs/elaborate.sh"
if {[file exists $elab_sh]} {
  set fh [open $elab_sh r]
  set elab_content [read $fh]
  close $fh
  if {[string first "xlnoc_glue" $elab_content] == -1} {
    set patched [string map {"xil_defaultlib.board xil_defaultlib.glbl" "xil_defaultlib.board xil_defaultlib.xlnoc_glue xil_defaultlib.glbl"} $elab_content]
    if {[string equal $patched $elab_content]} {
      puts "WARNING: could not patch elaborate.sh to add xlnoc_glue as a second -top - the expected 'xil_defaultlib.board xil_defaultlib.glbl' pattern was not found (Vivado may have changed its generated script format). Add 'xil_defaultlib.xlnoc_glue' to the vcs invocation's top-module list by hand."
    } else {
      set fh [open $elab_sh w]
      puts -nonewline $fh $patched
      close $fh
      puts "INFO: patched elaborate.sh - added xil_defaultlib.xlnoc_glue as a second elaboration top"
    }
  }
} else {
  puts "WARNING: $elab_sh not found - cannot patch in xlnoc_glue as a second top."
}

puts "INFO: DONE - scripts generated under $workdir/design_1.sim/sim_1/behav/vcs/"
