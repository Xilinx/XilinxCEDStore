# all.tcl - sources every xsdb_scripts package in dependency order:
# design -> control -> hwtg -> perf -> ecam. This is the only file you need
# to source to load everything.
#
#   xsdb% source xsdb_scripts/all.tcl
#   xsdb% design::discover [pwd]
#   xsdb% design::connect
#   xsdb% design::program           ;# optional: full board bring-up
#   xsdb% hwtg::load_append 0 "WRITE addr=0x1000 repeat=10"
#   xsdb% perf::capture 0
#   xsdb% ecam::report

set all_script_dir [file dirname [file normalize [info script]]]
source [file join $all_script_dir design.tcl]
source [file join $all_script_dir control.tcl]
source [file join $all_script_dir hwtg.tcl]
source [file join $all_script_dir perf.tcl]
source [file join $all_script_dir ecam.tcl]
unset all_script_dir
