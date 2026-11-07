# This script loads the instruction RAM of all present CXL Datapaths to fully fill the
# performance monitors with write traffic to accurately measure write latency/bandwidth. 
# Each performance monitor uses a single URAM, which holds up to 4096 entries.
# NXM = Non-eXistent Memory. Every access targets an address ABOVE the HDM
# range that ecam::setup_hdm can assign (ecam::HDM_BASE + ecam::MAX_HDM_RANGE_SIZE,
# i.e. 16 TB), so no HDM decoder claims it and the device has no backing memory
# to touch. The device should be able to respond immediately instead of waiting on its
# memory, so this test should stress the CXL link bandwidth itself rather than 
# memory-controller pressure. Compare against the _incr_, _const_ and _rand_ variants, 
# which do hit HDM memory. It is expected that ::has_errors returns 1 since this is an 
# error case.
#   - Command 0 : 4096 writes to the CXL EP, incrementing by 64B
# The 4096-transaction count can be overridden by setting a variable BEFORE
# sourcing this script (the value must be 1..4096, anything else is an error):
#   set OVERWRITE_NUM_WR <n>   ;# number of write transactions
set num_wr 4096
if {[info exists ::OVERWRITE_NUM_WR]} {
  if {![string is integer -strict ${::OVERWRITE_NUM_WR}] || ${::OVERWRITE_NUM_WR} < 1 || ${::OVERWRITE_NUM_WR} > 4096} {
    error "OVERWRITE_NUM_WR='${::OVERWRITE_NUM_WR}' is invalid -- must be an integer in 1..4096 (each performance-monitor URAM holds 4096 entries)"
  }
  set num_wr ${::OVERWRITE_NUM_WR}
  puts "INFO: OVERWRITE_NUM_WR is set -- sending $num_wr write transactions instead of the default 4096"
}
set rep_wr [expr {$num_wr - 1}]
perf::reset_all
for {set cpi 0} {$cpi < [llength [design::get_cxl_indices]]} {incr cpi} {
  set start_addr [expr {$ecam::HDM_BASE+$ecam::MAX_HDM_RANGE_SIZE+0x40000*$cpi}]
  hwtg::soft_reset  $cpi
  hwtg::load_append $cpi "WRITE addr=$start_addr repeat=$rep_wr addr_k=12 addr_stride=64 id=0 id_mode=0 id_stride=1 data_mode=1"
}

puts -nonewline "Launch the test now? (Y/N): "
flush stdout
set answer [string toupper [string trim [gets stdin]]]
if {$answer eq "Y"} {
  hwtg::ext_trigger_all
  foreach cpi [design::get_cxl_indices] { hwtg::wait_done $cpi }
  foreach cpi [design::get_cxl_indices] {
    if {[hwtg::has_errors $cpi]} {
      puts "INFO: datapath $cpi flagged errors (may be the device's response to NXM accesses):"
      hwtg::parse_errors $cpi
    } else {
      puts "INFO: datapath $cpi reported no errors"
    }
  }
} else {
  puts "INFO: not started -- run hwtg::ext_trigger_all (then hwtg::wait_done <cpi> per datapath) when ready."
}
