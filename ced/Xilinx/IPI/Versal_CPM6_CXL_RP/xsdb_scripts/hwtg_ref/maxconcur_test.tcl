# This script loads the instruction RAM of all present CXL Datapaths to fully fill the
# performance monitors with write AND read traffic to accurately measure mixed traffic
# latency/bandwidth. Each performance monitor uses a single URAM, which holds up to 4096 
# entries.
#   - Command 0 : 4096 writes to the CXL EP, incrementing by 64B
#   - Command 1 : 4096 reads to the CXL EP, incrementing by 64B
perf::reset_all
for {set cpi 0} {$cpi < [llength [design::get_cxl_indices]]} {incr cpi} {
  set start_addr [expr {0x8000000000+0x40000*$cpi}]
  hwtg::soft_reset  $cpi
  hwtg::load_append $cpi "WRITE addr=$start_addr repeat=4095 addr_k=12 addr_stride=64 id=0 id_mode=0 id_stride=1 data_mode=1"
  hwtg::load_append $cpi "READ  addr=$start_addr repeat=4095 addr_k=12 addr_stride=64 id=0 id_mode=0 id_stride=1"
}

puts -nonewline "Launch the test now? (Y/N): "
flush stdout
set answer [string toupper [string trim [gets stdin]]]
if {$answer eq "Y"} {
  hwtg::ext_trigger_all
  foreach cpi [design::get_cxl_indices] { hwtg::wait_done $cpi }
} else {
  puts "INFO: not started -- run hwtg::ext_trigger_all (then hwtg::wait_done <cpi> per datapath) when ready."
}
