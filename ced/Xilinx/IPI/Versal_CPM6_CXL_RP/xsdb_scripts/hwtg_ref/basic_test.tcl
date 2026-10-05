# This script is the most basic data transfer possible to confirm functionality:
#   - Command 0 : a single write to the CXL EP
#   - Command 1 : a single read to the CXL EP
perf::reset_all
hwtg::soft_reset  0
hwtg::load_append 0 "WRITE addr=0x8000000000"
hwtg::load_append 0 "READ  addr=0x8000000000"

puts -nonewline "Launch the test now? (Y/N): "
flush stdout
set answer [string toupper [string trim [gets stdin]]]
if {$answer eq "Y"} {
  hwtg::start 0
  hwtg::wait_done 0
} else {
  puts "INFO: not started -- run hwtg::start 0 (then hwtg::wait_done 0) when ready."
}
