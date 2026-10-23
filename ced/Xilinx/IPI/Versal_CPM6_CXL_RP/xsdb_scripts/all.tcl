# all.tcl - sources every xsdb_scripts package in dependency order:
# design -> control -> hwtg -> perf -> ecam. This is the only file you need
# to source to load everything.
#
#   xsdb% source xsdb_scripts/all.tcl
#   xsdb% design::discover [pwd]
#   xsdb% design::connect
#   xsdb% design::program           ;# programs boot.pdi/pld.pdi, brings up link
#   xsdb% ecam::connect
#   xsdb% ecam::setup_ep_bars       ;# REQUIRED before any real traffic: sizes/
#                                   ;# places the link partner's BARs
#   xsdb% ecam::setup_hdm decoder   ;# REQUIRED before any real traffic: enables
#                                   ;# the link partner's HDM decoder range
#   xsdb% hwtg::connect
#   xsdb% hwtg::load_append 0 "WRITE addr=0x8000000000 repeat=7 addr_k=12 addr_stride=64"
#   xsdb% hwtg::load_append 0 "READ  addr=0x8000000000 repeat=7 addr_k=12 addr_stride=64"
#   xsdb% hwtg::start 0
#   xsdb% hwtg::wait_done 0
#   xsdb% perf::connect
#   xsdb% perf::report
#
# NOTE: the hardware cannot issue transactions to a link partner that hasn't
# had its BARs sized/placed and its HDM decoder range enabled -- hwtg:: WRITE/
# READ traffic MUST come after ecam::setup_ep_bars/ecam::setup_hdm, not before.
#
# NOTE: design::connect/hwtg::connect/perf::connect/ecam::connect are four
# INDEPENDENT commands, each selecting whichever xsdb target that
# package's own register accesses need (a board/root pattern for design::,
# the DPC for hwtg::/perf::, the Cortex-A72 #0/APU for ecam::). xsdb only
# has ONE current target at a time, so call whichever package's ::connect
# you need immediately before using that package's commands.

set all_script_dir [file dirname [file normalize [info script]]]
source [file join $all_script_dir design.tcl]
source [file join $all_script_dir control.tcl]
source [file join $all_script_dir hwtg.tcl]
source [file join $all_script_dir perf.tcl]
source [file join $all_script_dir ecam.tcl]
unset all_script_dir

puts ""
puts "INFO: xsdb_scripts fully loaded -- 5 packages ready:"
puts "  design::  board bring-up + shared discovery    (design::help)"
puts "  control:: register transport + PL reset pins   (control::help)"
puts "  hwtg::    traffic-generator control            (hwtg::help)"
puts "  perf::    performance URAM latency/bandwidth   (perf::help)"
puts "  ecam::    PCIe/CXL configuration-space access  (ecam::help)"
