# This script loads the instruction RAM of all present CXL Datapaths to fully fill the
# performance monitors with write AND read traffic to accurately measure mixed traffic
# latency/bandwidth. Each performance monitor uses a single URAM, which holds up to 4096 
# entries.
#   - Command 0 : 4096 writes to the CXL EP, all to the same 64B address (no increment)
#   - Command 1 : 4096 reads to the CXL EP, all to the same 64B address (no increment)
# The 4096-transaction count can be overridden by setting a variable BEFORE
# sourcing this script (the value must be 1..4096, anything else is an error):
#   set OVERWRITE_NUM_WR <n>   ;# number of write transactions
#   set OVERWRITE_NUM_RD <n>   ;# number of read transactions
set num_wr 4096
if {[info exists ::OVERWRITE_NUM_WR]} {
  if {![string is integer -strict ${::OVERWRITE_NUM_WR}] || ${::OVERWRITE_NUM_WR} < 1 || ${::OVERWRITE_NUM_WR} > 4096} {
    error "OVERWRITE_NUM_WR='${::OVERWRITE_NUM_WR}' is invalid -- must be an integer in 1..4096 (each performance-monitor URAM holds 4096 entries)"
  }
  set num_wr ${::OVERWRITE_NUM_WR}
  puts "INFO: OVERWRITE_NUM_WR is set -- sending $num_wr write transactions instead of the default 4096"
}
set rep_wr [expr {$num_wr - 1}]
set num_rd 4096
if {[info exists ::OVERWRITE_NUM_RD]} {
  if {![string is integer -strict ${::OVERWRITE_NUM_RD}] || ${::OVERWRITE_NUM_RD} < 1 || ${::OVERWRITE_NUM_RD} > 4096} {
    error "OVERWRITE_NUM_RD='${::OVERWRITE_NUM_RD}' is invalid -- must be an integer in 1..4096 (each performance-monitor URAM holds 4096 entries)"
  }
  set num_rd ${::OVERWRITE_NUM_RD}
  puts "INFO: OVERWRITE_NUM_RD is set -- sending $num_rd read transactions instead of the default 4096"
}
set rep_rd [expr {$num_rd - 1}]
perf::reset_all
for {set cpi 0} {$cpi < [llength [design::get_cxl_indices]]} {incr cpi} {
  set start_addr [expr {$ecam::HDM_BASE+0x40000*$cpi}]
  hwtg::soft_reset  $cpi
  hwtg::load_append $cpi "WRITE addr=$start_addr repeat=$rep_wr id=0 id_mode=0 id_stride=1 data_mode=1"
  hwtg::load_append $cpi "READ  addr=$start_addr repeat=$rep_rd id=0 id_mode=0 id_stride=1"
}

puts -nonewline "Launch the test now? (Y/N): "
flush stdout
set answer [string toupper [string trim [gets stdin]]]
if {$answer eq "Y"} {
  hwtg::ext_trigger_all
  foreach cpi [design::get_cxl_indices] { hwtg::wait_done $cpi }
  foreach cpi [design::get_cxl_indices] {
    if {[hwtg::has_errors $cpi]} {
      puts "FAIL: datapath $cpi reported errors"
      hwtg::parse_errors $cpi
    } else {
      puts "PASS: datapath $cpi reported no errors"
    }
  }
} else {
  puts "INFO: not started -- run hwtg::ext_trigger_all (then hwtg::wait_done <cpi> per datapath) when ready."
}
