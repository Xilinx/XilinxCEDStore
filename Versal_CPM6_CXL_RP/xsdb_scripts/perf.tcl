# perf.tcl - top-level loader for the Performance URAM latency/bandwidth
# library. Requires design:: and control:: already loaded (for the address
# map/clock discovery and the JTAG register transport respectively) --
# source design.tcl and control.tcl first, or just source all.tcl.
#
#   source xsdb_scripts/all.tcl
#   design::discover [pwd]
#   design::connect
#   perf::capture 0
#   perf::report

set perf_script_dir [file dirname [file normalize [info script]]]

if {![llength [info commands ::design::get_uram_base]]} {
  error "perf requires design to be loaded first -- run: source [file join $perf_script_dir design.tcl]"
}
if {![llength [info commands ::control::rd32]]} {
  error "perf requires control to be loaded first -- run: source [file join $perf_script_dir control.tcl]"
}

source [file join $perf_script_dir pkg_help.tcl]
source [file join $perf_script_dir perf_pkg.tcl]
source [file join $perf_script_dir perf_cmds.tcl]
source [file join $perf_script_dir perf_help.tcl]
unset perf_script_dir

puts "INFO: perf loaded."
puts "INFO: Run perf::help (or perf::h) for the command reference; perf::help <cmd> for detailed help on one command."
