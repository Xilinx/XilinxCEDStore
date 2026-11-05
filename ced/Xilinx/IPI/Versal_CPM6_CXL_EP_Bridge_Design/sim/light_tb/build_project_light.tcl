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
# <workdir> must be outside this checkout.
#
# Then: cd <workdir>/design_1.sim/sim_1/behav/vcs && ./compile.sh &&
# ./elaborate.sh && ./simulate.sh. No Avery VIP/uvma_agents/external
# Makefile needed - only Vivado + VCS with UVM 1.2.

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

# board.sv is .sv (not .v) since it uses SystemVerilog-only constructs
# (logic types, virtual interfaces, typedef struct, package imports).
# -ntb_opts uvm-1.2 is required: a custom sim_1 fileset doesn't automatically
# get UVM support the way Vivado's IP-driven flow does, and board.sv needs
# uvm_macros.svh/uvm_pkg.
set_property -name {vcs.compile.vlogan.more_options} \
  -value "-ntb_opts uvm-1.2 +incdir+$sim_dst/light_tb +incdir+$sim_dst/tb" \
  -objects $sim_obj
set_property -name {vcs.elaborate.vcs.more_options} -value "-ntb_opts uvm-1.2" \
  -objects $sim_obj
# The TB ends itself with $finish; this is only a cap.
set_property -name {vcs.simulate.runtime} -value {500us} -objects $sim_obj

set_property target_simulator VCS [current_project]
# Both must be disabled BEFORE setting top, and in this order - otherwise
# Vivado's default BD-wrapper-sim auto-top detection silently overrides it.
set_property SIM_WRAPPER_TOP 0 [get_filesets sim_1]
set_property top_auto_set 0 [get_filesets sim_1]
set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

# Compiled library location - site-specific, so it comes from
# $VIVADO_CLIBS (checked above) rather than being hardcoded.
set_property compxlib.vcs_compiled_library_dir $vcs_clibs_dir [current_project]

puts "INFO: sim_1 fileset configured, top=board, target_simulator=VCS"
puts "INFO: generating simulation scripts only (no compile/elaborate/run here)..."
launch_simulation -scripts_only

# -ntb_opts doesn't compile uvm_pkg: add it to compile.sh ahead of the
# testbench ($VCS_HOME is set by compile.sh or the environment).
set compile_sh "$workdir/design_1.sim/sim_1/behav/vcs/compile.sh"
set fh [open $compile_sh r]
set compile_content [read $fh]
close $fh
if {![regexp -indices -line {^(\S*)vlogan \$vlogan_opts} $compile_content first prefix]} {
  puts "ERROR: no vlogan command found in $compile_sh"
  exit 1
}
set vlogan "[string range $compile_content {*}$prefix]vlogan"
set uvm_dir {$VCS_HOME/etc/uvm-1.2}
set uvm_cmd [join [list \
  "$vlogan -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps -work xil_defaultlib \\" \
  "  +incdir+$uvm_dir/vcs +incdir+$uvm_dir/verdi \\" \
  "  $uvm_dir/uvm_pkg.sv \\" \
  "  $uvm_dir/vcs/uvm_custom_install_vcs_recorder.sv \\" \
  "  $uvm_dir/verdi/uvm_custom_install_verdi_recorder.sv \\" \
  "  2>&1 | tee -a compile.log"] "\n"]
set at [lindex $first 0]
set fh [open $compile_sh w]
puts -nonewline $fh "[string range $compile_content 0 [expr {$at - 1}]]$uvm_cmd\n\n[string range $compile_content $at end]"
close $fh

puts "INFO: DONE - scripts generated under $workdir/design_1.sim/sim_1/behav/vcs/"
