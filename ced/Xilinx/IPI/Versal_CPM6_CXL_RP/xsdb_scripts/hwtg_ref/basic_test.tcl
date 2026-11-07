# This script is the most basic data transfer possible to confirm functionality:
#   - Command 0 : a single write to the CXL EP
#   - Command 1 : a single read to the CXL EP
perf::reset_all
hwtg::soft_reset  0
hwtg::load_append 0 "WRITE addr=$ecam::HDM_BASE"
hwtg::load_append 0 "READ  addr=$ecam::HDM_BASE"

puts -nonewline "Launch the test now? (Y/N): "
flush stdout
set answer [string toupper [string trim [gets stdin]]]
if {$answer eq "Y"} {
  hwtg::start 0
  hwtg::wait_done 0
  if {[hwtg::has_errors 0]} {
    puts "FAIL: datapath 0 reported errors"
    hwtg::parse_errors 0
  } else {
    puts "PASS: datapath 0 reported no errors"
  }
} else {
  puts "INFO: not started -- run hwtg::start 0 (then hwtg::wait_done 0) when ready."
}
