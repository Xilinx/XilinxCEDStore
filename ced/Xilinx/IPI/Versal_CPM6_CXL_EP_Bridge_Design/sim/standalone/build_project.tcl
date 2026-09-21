# build_project.tcl - manual/standalone project creation driver (Path 1)
#
# Direct call into this design's own init.tcl/run.tcl (the "manual/console
# invocation" path run.tcl::get_opt already supports), replacing an external
# regression-test mechanism. design_name is fixed to "design_1" here, so the
# resulting wrapper is always design_1_wrapper.
#
# Usage:
#   cd Versal_CPM6_CXL_EP_Bridge_Design/sim/standalone
#   vivado -mode batch -source build_project.tcl \
#     -tclargs <workdir> [Controller_0|Controller_1] [CXL_3_1|CXL_2_0] [X4|X8]
#
# Produces <workdir>/design_1.xpr plus, via `launch_simulation -scripts_only`
# below, Vivado-generated DUT-only VCS sim scripts under
# <workdir>/design_1.sim/sim_1/behav/vcs/{compile.sh,elaborate.sh,simulate.sh}.
# Also copies this design's whole sim/ tree into <workdir>/sim - all
# subsequent make/compile/elaborate/simulate steps must run against
# <workdir>/sim/standalone/Makefile (the copy), not the original checkout,
# so a build never reads live from the CED checkout. That copy compiles
# the rest (Avery VIP + CPM6 SecureIP + UVM agents + our tb/verif) around
# this DUT compile.

set script_dir  [file dirname [file normalize [info script]]]
set design_root [file normalize [file join $script_dir .. ..]]

if {[llength $argv] < 1} {
  puts "ERROR: usage: vivado -mode batch -source build_project.tcl -tclargs <workdir> \[Controller_0|Controller_1\] \[CXL_3_1|CXL_2_0\] \[X4|X8\]"
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
set workdir       [lindex $argv 0]
set ctrl_config   [expr {[llength $argv] > 1 ? [lindex $argv 1] : "Controller_1"}]
set cxl_protocol  [expr {[llength $argv] > 2 ? [lindex $argv 2] : "CXL_3_1"}]
set cxl_width     [expr {[llength $argv] > 3 ? [lindex $argv 3] : "X8"}]

# --- Copy this design's sim/ tree into the workdir ---
# Compile/elaborate/simulate must never read live from the CED checkout -
# copy the whole sim/ tree (avery_vcs.f, cpm6_sip.f, run.sh,
# vcs_lib_map.setup, uvma_agents.f, lib/, uvma_agents/, tb/, verif/,
# standalone/, light_tb/) into $workdir/sim first, then run everything
# from there. Re-copied fresh on every invocation (delete-then-copy, not
# an in-place merge) so a stale prior copy never silently shadows a newer
# checkout. Guarded against copying sim/ into itself or a nested
# subdirectory of itself.
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

# init.tcl computes its own directory via [info script], so this works
# regardless of Vivado's current working directory.
source [file join $design_root init.tcl]

createDesign design_1 [dict create CTRL_CONFIG $ctrl_config CXL_PROTOCOL $cxl_protocol CXL_WIDTH $cxl_width]

# --- Generate DUT-only VCS simulation scripts ---
# `launch_simulation -scripts_only` needs an explicit top set on sim_1 (it
# doesn't auto-infer one from sources_1); design_name "design_1" means the
# generated wrapper is design_1_wrapper.
set_property target_simulator VCS [current_project]
set_property -name {vcs.compile.vlogan.more_options} -value {-full64} -objects [get_filesets sim_1]
set_property top design_1_wrapper [get_filesets sim_1]
# Precompiled Xilinx VCS simulation library dir, matching the exact VCS
# build Vivado's own clibs were compiled against - without it, Vivado's
# default lookup produces a broken synopsys_sim.setup.
set_property compxlib.vcs_compiled_library_dir $vcs_clibs_dir [current_project]
update_compile_order -fileset sim_1
launch_simulation -scripts_only

puts "INFO: DUT project + VCS sim scripts generated under $workdir/design_1.sim/sim_1/behav/vcs/"
puts "INFO: next: make -f $workdir/sim/standalone/Makefile compile PROJ_DIR=$workdir"
