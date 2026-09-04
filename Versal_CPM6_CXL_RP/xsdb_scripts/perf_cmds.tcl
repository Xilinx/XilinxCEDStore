# perf_cmds.tcl
#
# Reads the per-CPI, per-interface Performance URAMs and turns them into
# latency and bandwidth figures.

#----------------------------------------------------------------------------
# DPC xsdb target connect
#----------------------------------------------------------------------------
# Selects the DPC (PMC Debug Packet Controller) xsdb target, printing which
# target got assigned. Independent of design::connect -- it's purely a
# board-specific target-selection step.
proc perf::connect {} {
  targets -set -filter {name =~ "*DPC*"}
  puts "INFO: perf connected to target [design::current_target_desc]"
}

# Reads one 64-bit URAM entry as two 32-bit control::rd32 calls (addr,
# addr+4) reassembled (hi<<32)|lo, since the register bus is genuinely 64
# bits wide but the JTAG path only reads 32 bits at a time.
proc perf::rd64 {addr} {
  set lo [control::rd32 $addr]
  set hi [control::rd32 [expr {$addr + 4}]]
  return [expr {($hi << 32) | $lo}]
}

proc perf::get_entry_addr {cpi iface idx} {
  variable ENTRY_STRIDE
  return [expr {[design::get_uram_base $cpi $iface] + $idx * $ENTRY_STRIDE}]
}

proc perf::decode_entry {val} {
  variable CNT_SHIFT
  variable CNT_MASK
  variable TAG_MASK
  return [dict create \
    cnt [expr {($val >> $CNT_SHIFT) & $CNT_MASK}] \
    tag [expr {$val & $TAG_MASK}]]
}

# Human-readable interface label for print, e.g. f2a_req -> "F2A REQ".
proc perf::iface_label {iface} {
  return [string toupper [string map {_ " "} $iface]]
}

# Widest iface_label among IFACE_NAMES, so read_ram/read_datapath can pad
# every label to the same width and keep "| Entries" vertically aligned.
proc perf::iface_label_width {} {
  variable IFACE_NAMES
  set w 0
  foreach iface $IFACE_NAMES {
    set len [string length [iface_label $iface]]
    if {$len > $w} { set w $len }
  }
  return $w
}

#----------------------------------------------------------------------------
# Read / reset
#----------------------------------------------------------------------------
# Silent read -- no print. Used internally by compute_latency/bandwidth
# (which have their own, more meaningful summary lines) so a single
# datapath read doesn't also spam a "Datapath N | IFACE | Entries: n" line;
# perf::read_ram is the printing wrapper around this for direct/interactive use.
proc perf::read_ram_entries {cpi iface} {
  variable MAX_ENTRIES
  set entries {}
  for {set idx 0} {$idx < $MAX_ENTRIES} {incr idx} {
    set val [rd64 [get_entry_addr $cpi $iface $idx]]
    if {$val == 0} { break }    ;# hardware-forced OOR zero == end of data
    lappend entries [decode_entry $val]
  }
  return $entries
}

proc perf::read_ram {args} {
  lassign $args cpi iface chan
  if {$chan eq ""} { set chan stdout }
  puts stdout "INFO: This may take several minutes."
  set entries [read_ram_entries $cpi $iface]
  puts $chan [format "Datapath %d | %-*s | Entries: %d" $cpi [iface_label_width] [iface_label $iface] [llength $entries]]
  return $entries
}

# Reads all 4 interfaces for one cpi (silently, via read_ram_entries) into a
# single {iface -> entries} dict -- one read per interface. Used by
# perf::report to read each URAM exactly once per cpi and share it between
# the latency and bandwidth sections, instead of perf::compute_latency and
# perf::compute_path_bandwidth each independently re-reading the same
# interfaces.
proc perf::read_cpi_entries {cpi} {
  variable IFACE_NAMES
  set cache [dict create]
  foreach iface $IFACE_NAMES { dict set cache $iface [read_ram_entries $cpi $iface] }
  return $cache
}

# Reads and summarizes all 4 interfaces for one cpi (each via read_ram, so
# every interface prints its own "Datapath N | IFACE | Entries: n" line).
# Purely a display command -- prints only, returns nothing; call
# perf::capture instead if you need the entries back.
proc perf::read_datapath {args} {
  lassign $args cpi
  puts stdout "INFO: This may take several minutes."
  variable IFACE_NAMES
  foreach iface $IFACE_NAMES { read_ram $cpi $iface }
  return
}

# Binary search for the write-pointer boundary instead of a linear scan: at
# most ceil(log2(MAX_ENTRIES+1)) probes (12 for MAX_ENTRIES=4096) instead of
# up to MAX_ENTRIES reads, since this only needs the COUNT, not every
# entry's decoded value. Relies on the same hardware guarantee read_ram_entries
# does -- any index at/beyond the write pointer reads back all-zero -- PLUS
# the assumption that no legitimately-written entry ever decodes to raw 0
# itself (cnt=0 and tag=0 at once), since that would make the "is this index
# written" predicate non-monotonic and silently return the wrong count.
proc perf::binary_search_entry_count {cpi iface} {
  variable MAX_ENTRIES
  set lo 0
  set hi $MAX_ENTRIES
  while {$lo < $hi} {
    set mid [expr {($lo + $hi) / 2}]
    set val [rd64 [get_entry_addr $cpi $iface $mid]]
    if {$val == 0} {
      set hi $mid
    } else {
      set lo [expr {$mid + 1}]
    }
  }
  return $lo
}

# Fast entry-count query -- does NOT fetch/decode every entry like
# perf::read_ram does, only enough probes to binary-search the write-pointer
# boundary. Prints the same one-line summary as perf::read_ram, but returns
# just the count (an integer), not a list of {cnt tag} entries.
proc perf::get_ram_entries {args} {
  lassign $args cpi iface chan
  if {$chan eq ""} { set chan stdout }
  set n [binary_search_entry_count $cpi $iface]
  puts $chan [format "Datapath %d | %-*s | Entries: %d" $cpi [iface_label_width] [iface_label $iface] $n]
  return $n
}

# perf::get_ram_entries on all 4 interfaces for one cpi. Purely a display
# command -- prints only, returns nothing; call perf::get_ram_entries
# directly if you need a single interface's count back.
proc perf::get_datapath_entries {args} {
  lassign $args cpi
  variable IFACE_NAMES
  foreach iface $IFACE_NAMES { get_ram_entries $cpi $iface }
  return
}

proc perf::reset_ram {args} {
  lassign $args cpi iface
  control::wr32 [design::get_uram_base $cpi $iface] 0
  puts "INFO: reset write pointer for cpi=$cpi iface=$iface"
}

proc perf::reset_all {args} {
  lassign $args cpi_list
  variable IFACE_NAMES
  if {[llength $cpi_list] == 0} { set cpi_list [design::get_cxl_indices] }
  foreach cpi $cpi_list { foreach iface $IFACE_NAMES { reset_ram $cpi $iface } }
  puts "INFO: reset all perf URAMs for cpi(s) $cpi_list"
}

#----------------------------------------------------------------------------
# Capture (no start/stop/done register exists -- this is just a read across
# all 4 interfaces)
#----------------------------------------------------------------------------
proc perf::capture {args} {
  lassign $args cpi
  variable IFACE_NAMES
  set result [dict create]
  foreach iface $IFACE_NAMES { dict set result $iface [read_ram $cpi $iface] }
  return $result
}

# The multi-cpi form: reads all of them back-to-back (minimal skew), so
# bandwidth_all/report see data from one shared window instead of
# independently-timed ones.
proc perf::capture_all {args} {
  lassign $args cpi_list
  if {[llength $cpi_list] == 0} { set cpi_list [design::get_cxl_indices] }
  variable IFACE_NAMES
  set result [dict create]
  foreach cpi $cpi_list {
    set per_iface [dict create]
    foreach iface $IFACE_NAMES { dict set per_iface $iface [read_ram $cpi $iface] }
    dict set result $cpi $per_iface
  }
  return $result
}

#----------------------------------------------------------------------------
# Latency (FIFO-per-tag matching, rollover-aware)
#----------------------------------------------------------------------------
proc perf::pair_latency {src_entries dst_entries} {
  variable FREERUN_WIDTH
  variable ROLLOVER_REJECT_FRACTION
  set rollover [expr {1 << $FREERUN_WIDTH}]
  array set dst_by_tag {}
  foreach e $dst_entries { lappend dst_by_tag([dict get $e tag]) [dict get $e cnt] }
  set deltas {}
  set unmatched_src 0
  foreach e $src_entries {
    set tag [dict get $e tag]
    set src_cnt [dict get $e cnt]
    if {![info exists dst_by_tag($tag)] || [llength $dst_by_tag($tag)] == 0} {
      incr unmatched_src
      continue
    }
    set dst_cnt [lindex $dst_by_tag($tag) 0]
    set dst_by_tag($tag) [lrange $dst_by_tag($tag) 1 end]
    set delta [expr {$dst_cnt - $src_cnt}]
    if {$delta < 0} { set delta [expr {$delta + $rollover}] }
    if {$delta > ($rollover * $ROLLOVER_REJECT_FRACTION)} { incr unmatched_src; continue }
    lappend deltas $delta
  }
  return [dict create deltas $deltas unmatched_src $unmatched_src \
    unmatched_dst [expr {[llength $dst_entries] - [llength $src_entries] + $unmatched_src}]]
}

proc perf::median {values} {
  set sorted [lsort -real $values]
  set n [llength $sorted]
  set mid [expr {$n / 2}]
  if {$n % 2 == 1} { return [lindex $sorted $mid] }
  return [expr {([lindex $sorted [expr {$mid - 1}]] + [lindex $sorted $mid]) / 2.0}]
}

# Sample standard deviation (n-1 denominator); 0 for fewer than 2 values,
# since a single sample has no spread to measure.
proc perf::stddev {values} {
  set n [llength $values]
  if {$n < 2} { return 0.0 }
  set sum 0.0
  foreach v $values { set sum [expr {$sum + $v}] }
  set mean [expr {$sum / $n}]
  set sq 0.0
  foreach v $values { set d [expr {$v - $mean}]; set sq [expr {$sq + $d * $d}] }
  return [expr {sqrt($sq / ($n - 1))}]
}

# The data half of perf::latency -- prints nothing of its own (reads
# silently via read_ram_entries), so perf::report can build its own table
# from this without also triggering a read_ram entry-count line or
# latency's own one-line summary (see perf::latency below).
#
# entry_cache (optional): a {iface -> entries} dict, as built by
# perf::read_cpi_entries. When given, src/dst entries are pulled from it
# instead of issuing a fresh read_ram_entries -- perf::report uses this so
# each URAM is read once per cpi and shared with perf::compute_path_bandwidth,
# instead of both independently re-reading the same 4 interfaces.
proc perf::compute_latency {cpi path {entry_cache ""}} {
  variable LATENCY_PATHS
  if {![info exists LATENCY_PATHS($path)]} {
    error "unknown latency path '$path' (expected: [array names LATENCY_PATHS])"
  }
  lassign $LATENCY_PATHS($path) src_iface dst_iface
  if {$entry_cache ne ""} {
    set src_entries [dict get $entry_cache $src_iface]
    set dst_entries [dict get $entry_cache $dst_iface]
  } else {
    set src_entries [read_ram_entries $cpi $src_iface]
    set dst_entries [read_ram_entries $cpi $dst_iface]
  }
  if {[llength $src_entries] == 0 || [llength $dst_entries] == 0} {
    error "insufficient data for cpi=$cpi path=$path ($src_iface=[llength $src_entries], $dst_iface=[llength $dst_entries] entries) -- run perf::capture first"
  }
  set paired [pair_latency $src_entries $dst_entries]
  set deltas [dict get $paired deltas]
  if {[llength $deltas] == 0} {
    error "no tag-matched pairs found for cpi=$cpi path=$path -- capture window may be too short"
  }
  set hz [design::get_clk_hz]
  set ns_list {}
  foreach d $deltas { lappend ns_list [expr {$d * 1.0e9 / $hz}] }
  set n [llength $ns_list]
  set sum 0.0; set min [lindex $ns_list 0]; set max [lindex $ns_list 0]
  foreach v $ns_list {
    set sum [expr {$sum + $v}]
    if {$v < $min} { set min $v }
    if {$v > $max} { set max $v }
  }
  set avg [expr {$sum / $n}]
  return [dict create cpi $cpi path $path n $n min_ns $min max_ns $max avg_ns $avg \
    median_ns [median $ns_list] stddev_ns [stddev $ns_list] ns_list $ns_list \
    unmatched_src [dict get $paired unmatched_src] unmatched_dst [dict get $paired unmatched_dst]]
}

proc perf::latency {args} {
  lassign $args cpi path
  set result [compute_latency $cpi $path]
  puts "cpi $cpi $path latency: n=[dict get $result n] min=[format %.1f [dict get $result min_ns]]ns avg=[format %.1f [dict get $result avg_ns]]ns max=[format %.1f [dict get $result max_ns]]ns (unmatched: src=[dict get $result unmatched_src] dst=[dict get $result unmatched_dst])"
  return $result
}

#----------------------------------------------------------------------------
# Bandwidth (single-path, then combined via non-summing spanning window --
# traffic paths aren't guaranteed to overlap in time, so summing
# independent GB/s figures overstates aggregate throughput)
#----------------------------------------------------------------------------
proc perf::bandwidth {args} {
  lassign $args cpi iface chan
  if {$chan eq ""} { set chan stdout }
  variable BYTES_PER_XFER
  variable FREERUN_WIDTH
  set entries [read_ram_entries $cpi $iface]
  set n [llength $entries]
  if {$n < 2} {
    error "insufficient data for cpi=$cpi iface=$iface (n=$n; need >=2) -- run perf::capture first"
  }
  set first_cnt [dict get [lindex $entries 0] cnt]
  set last_cnt  [dict get [lindex $entries end] cnt]
  set rollover [expr {1 << $FREERUN_WIDTH}]
  set span [expr {$last_cnt - $first_cnt}]
  if {$span < 0} { set span [expr {$span + $rollover}] }
  if {$span == 0} { error "cpi=$cpi iface=$iface: span=0 ticks -- cannot compute a rate" }
  set hz [design::get_clk_hz]
  set bytes [expr {$n * $BYTES_PER_XFER}]
  set seconds [expr {$span * 1.0 / $hz}]
  set gbps [expr {($bytes / $seconds) / 1.0e9}]
  set result [dict create cpi $cpi iface $iface n $n bytes $bytes \
    span_ticks $span span_s $seconds gbps $gbps first_cnt $first_cnt last_cnt $last_cnt]
  puts $chan "cpi $cpi $iface bandwidth: n=$n bytes=$bytes span=[format %.3f [expr {$seconds*1e6}]]us -> [format %.3f $gbps] GB/s"
  return $result
}

# Spanning-window combine: total_bytes across all parts / one shared window
# (earliest first-tick .. latest last-tick), NOT a sum of per-path rates.
# Valid because every path shares the SAME freerun_cnt32 instance (one per
# design), so counter values are directly comparable with no cross-domain
# correction.
proc perf::combine_bandwidth {parts} {
  variable FREERUN_WIDTH
  set rollover [expr {1 << $FREERUN_WIDTH}]
  set hz [design::get_clk_hz]
  set total_bytes 0
  set firsts {}; set lasts {}
  foreach p $parts {
    incr total_bytes [dict get $p bytes]
    lappend firsts [dict get $p first_cnt]
    lappend lasts  [dict get $p last_cnt]
  }
  set earliest [lindex $firsts 0]; set latest [lindex $lasts 0]
  foreach f $firsts { if {$f < $earliest} { set earliest $f } }
  foreach l $lasts  { if {$l > $latest}   { set latest   $l } }
  set span [expr {$latest - $earliest}]
  if {$span < 0} { set span [expr {$span + $rollover}] }
  if {$span == 0} { error "combined span across [llength $parts] part(s) is 0 ticks" }
  set seconds [expr {$span * 1.0 / $hz}]
  set gbps [expr {($total_bytes / $seconds) / 1.0e9}]
  return [dict create n_parts [llength $parts] total_bytes $total_bytes \
    span_ticks $span span_s $seconds gbps $gbps]
}

# One logical (read or write) path's bandwidth -- NOT a raw single-interface
# reading. Pairs the path's request-side (src) and response-side (dst)
# interfaces the same way perf::compute_latency does: bytes counts completed
# transfers (dst entries -- what actually finished), while span runs from
# the first REQUEST (src's first entry) to the last RESPONSE (dst's last
# entry). Treating f2a_data/a2f_rsp (or f2a_req/a2f_data) as two independent
# bandwidth "parts" would double-count the same bytes once per side and mix
# incompatible request-side/response-side windows -- this is why
# perf::bandwidth_all no longer does that.
#
# entry_cache (optional): see perf::compute_latency -- same {iface ->
# entries} dict, so perf::report/perf::bandwidth_all can share one read per
# interface with the latency computation instead of re-reading it here.
proc perf::compute_path_bandwidth {cpi path {entry_cache ""}} {
  variable LATENCY_PATHS
  variable BYTES_PER_XFER
  variable FREERUN_WIDTH
  if {![info exists LATENCY_PATHS($path)]} {
    error "unknown bandwidth path '$path' (expected: [array names LATENCY_PATHS])"
  }
  lassign $LATENCY_PATHS($path) src_iface dst_iface
  if {$entry_cache ne ""} {
    set src_entries [dict get $entry_cache $src_iface]
    set dst_entries [dict get $entry_cache $dst_iface]
  } else {
    set src_entries [read_ram_entries $cpi $src_iface]
    set dst_entries [read_ram_entries $cpi $dst_iface]
  }
  if {[llength $src_entries] == 0 || [llength $dst_entries] == 0} {
    error "insufficient data for cpi=$cpi path=$path ($src_iface=[llength $src_entries], $dst_iface=[llength $dst_entries] entries) -- run perf::capture first"
  }
  set n [llength $dst_entries]
  set first_cnt [dict get [lindex $src_entries 0] cnt]
  set last_cnt  [dict get [lindex $dst_entries end] cnt]
  set rollover [expr {1 << $FREERUN_WIDTH}]
  set span [expr {$last_cnt - $first_cnt}]
  if {$span < 0} { set span [expr {$span + $rollover}] }
  if {$span == 0} { error "cpi=$cpi path=$path: span=0 ticks -- cannot compute a rate" }
  set hz [design::get_clk_hz]
  set bytes [expr {$n * $BYTES_PER_XFER}]
  set seconds [expr {$span * 1.0 / $hz}]
  set gbps [expr {($bytes / $seconds) / 1.0e9}]
  return [dict create cpi $cpi path $path n $n bytes $bytes \
    span_ticks $span span_s $seconds gbps $gbps first_cnt $first_cnt last_cnt $last_cnt]
}

# Data-only: computes every listed cpi's write+read bandwidth (see
# perf::compute_path_bandwidth) plus the overall spanning-window combined
# figure, WITHOUT printing anything. perf::bandwidth_all is the printing
# wrapper around this for direct/interactive use; perf::report calls this
# directly so it can present the same data as its own bandwidth table
# instead of bandwidth_all's per-line prints.
#
# cache_by_cpi (optional): a {cpi -> {iface -> entries}} dict, as built by
# perf::read_cpi_entries per cpi. When given, each cpi's 4 interfaces are
# read once and shared with the latency section instead of re-reading them
# here.
#
# Returns a dict: per_path ({cpi}_{path} -> compute_path_bandwidth result),
# parts (the same results as a flat list, in cpi/path order -- handy for
# filtering by path), and combined (the overall spanning-window figure
# across every part).
proc perf::compute_bandwidth_all {cpi_list {cache_by_cpi ""}} {
  set parts {}
  set per_path [dict create]
  foreach cpi $cpi_list {
    set entry_cache ""
    if {$cache_by_cpi ne "" && [dict exists $cache_by_cpi $cpi]} {
      set entry_cache [dict get $cache_by_cpi $cpi]
    }
    foreach path {write read} {
      if {[catch {compute_path_bandwidth $cpi $path $entry_cache} r]} { continue }
      lappend parts $r
      dict set per_path "${cpi}_${path}" $r
    }
  }
  if {[llength $parts] == 0} {
    error "no path had matched request/response entries across cpi(s) $cpi_list -- run perf::capture first"
  }
  set combined [combine_bandwidth $parts]
  return [dict create per_path $per_path parts $parts combined $combined]
}

proc perf::bandwidth_all {args} {
  lassign $args cpi_list chan cache_by_cpi
  if {$chan eq ""} { set chan stdout }
  if {[llength $cpi_list] == 0} { set cpi_list [design::get_cxl_indices] }
  set result [compute_bandwidth_all $cpi_list $cache_by_cpi]
  set per_path [dict get $result per_path]
  foreach key [dict keys $per_path] {
    set r [dict get $per_path $key]
    puts $chan "cpi [dict get $r cpi] [dict get $r path] bandwidth: n=[dict get $r n] bytes=[dict get $r bytes] span=[format %.3f [expr {[dict get $r span_s]*1e6}]]us -> [format %.3f [dict get $r gbps]] GB/s"
  }
  set combined [dict get $result combined]
  puts $chan "combined bandwidth across [dict get $combined n_parts] path(s): [format %.3f [dict get $combined gbps]] GB/s"
  return [dict create per_path $per_path combined $combined]
}

#----------------------------------------------------------------------------
# Orchestrator
#----------------------------------------------------------------------------
# Bins ns_list into up to 10 buckets spanning its min..max and prints one
# row per bucket, count first -- padded to entries_width (the same width
# print_latency_table used for its Entries column) and set off by the same
# "||", so the histogram's counts line up under the table's Entries column
# above it -- then a fixed-width "#" bar, then the bucket's ns range.
proc perf::print_latency_histogram {ns_list entries_width {chan stdout}} {
  set n [llength $ns_list]
  if {$n == 0} { return }
  set minv [lindex $ns_list 0]
  set maxv [lindex $ns_list 0]
  foreach v $ns_list {
    if {$v < $minv} { set minv $v }
    if {$v > $maxv} { set maxv $v }
  }

  set num_bins 10
  if {$n < $num_bins} { set num_bins $n }
  if {$num_bins < 1} { set num_bins 1 }

  set bins [lrepeat $num_bins 0]
  if {$maxv == $minv} {
    lset bins 0 $n
  } else {
    set width [expr {($maxv - $minv) / double($num_bins)}]
    foreach v $ns_list {
      set idx [expr {int(($v - $minv) / $width)}]
      if {$idx >= $num_bins} { set idx [expr {$num_bins - 1}] }
      lset bins $idx [expr {[lindex $bins $idx] + 1}]
    }
  }

  set maxcount 0
  foreach c $bins { if {$c > $maxcount} { set maxcount $c } }

  set bar_width 30
  for {set i 0} {$i < $num_bins} {incr i} {
    set c [lindex $bins $i]
    set bar_len [expr {$maxcount > 0 ? int(round(double($c) / $maxcount * $bar_width))
                                     : 0}]
    set bar [format "%-${bar_width}s" [string repeat "#" $bar_len]]
    if {$maxv == $minv} {
      set range_label [format "%.2f ns" $minv]
    } else {
      set lo [expr {$minv + $i * $width}]
      set hi [expr {$minv + ($i + 1) * $width}]
      set range_label [format "%6.2f - %6.2f ns" $lo $hi]
    }
    puts $chan "  | [format "%${entries_width}d" $c] || $bar $range_label"
  }
}

# Prints one subsection's latency table and histogram: a header line,
# underline, either a single-row ASCII table (Entries | Min | Max | Median
# | Std. Dev., all in ns -- Entries set off with a double "||" since it's a
# count, not a duration), a full-width "-" rule the same width as the table
# (visually separating it from the histogram below), and then the
# histogram of the underlying ns_list -- or "(no entries -- <reason>)" if
# stats isn't a valid compute_latency dict (report passes the caught error
# text straight through here instead of swallowing it, so a genuine bug
# doesn't masquerade as "just no data").
proc perf::print_latency_table {label stats {chan stdout}} {
  puts $chan "  $label"
  puts $chan "  [string repeat "-" [string length $label]]"
  if {[catch {dict get $stats n}]} {
    if {$stats eq ""} {
      puts $chan "    (no entries)"
    } else {
      # Strip the "-- run perf::capture first" suggestion perf::compute_latency
      # appends to its own error text -- redundant noise in a multi-cpi/path
      # report table; still shown in full via perf::latency's own error surfacing.
      regsub -- { -- run perf::capture first$} $stats {} reason
      puts $chan "    (no entries -- $reason)"
    }
    puts $chan ""
    return
  }

  set headers {Entries {Min (ns)} {Max (ns)} {Median (ns)} {Std. Dev. (ns)}}
  set cells [list \
    [dict get $stats n] \
    [format %.2f [dict get $stats min_ns]] \
    [format %.2f [dict get $stats max_ns]] \
    [format %.2f [dict get $stats median_ns]] \
    [format %.2f [dict get $stats stddev_ns]]]

  set widths {}
  foreach h $headers c $cells {
    set hw [string length $h]
    set cw [string length $c]
    lappend widths [expr {$hw > $cw ? $hw : $cw}]
  }

  set hdr_parts {}
  set sep_parts {}
  set row_parts {}
  foreach h $headers c $cells w $widths {
    lappend hdr_parts [format "%-${w}s" $h]
    lappend sep_parts [string repeat "-" $w]
    lappend row_parts [format "%${w}s" $c]
  }

  puts $chan "  | [lindex $hdr_parts 0] || [join [lrange $hdr_parts 1 end] { | }] |"
  puts $chan "  |-[lindex $sep_parts 0]-||-[join [lrange $sep_parts 1 end] {-|-}]-|"
  set row_line "  | [lindex $row_parts 0] || [join [lrange $row_parts 1 end] { | }] |"
  puts $chan $row_line
  puts $chan "  [string repeat "-" [expr {[string length $row_line] - 2}]]"
  print_latency_histogram [dict get $stats ns_list] [lindex $widths 0] $chan
  puts $chan ""
}

# Prints a bandwidth summary table: one row per cpi ("CPI instance N"),
# plus a final "Total" row, and two columns (Write/Read Bandwidth GB/s).
# Per-cpi cells come straight from compute_bandwidth_all's per_path dict;
# a path with no matched entries for that cpi shows "-" instead of erroring.
# The Total row is NOT the same figure as compute_bandwidth_all's single
# "combined" value (which spans BOTH write and read together) -- each
# column needs its own combine, so Total/Write combines only the write
# parts and Total/Read only the read parts, via two separate
# perf::combine_bandwidth calls over the filtered part lists.
proc perf::print_bandwidth_table {cpi_list result {chan stdout}} {
  set per_path [dict get $result per_path]
  set parts [dict get $result parts]

  set write_parts {}
  set read_parts {}
  foreach p $parts {
    switch -- [dict get $p path] {
      write { lappend write_parts $p }
      read  { lappend read_parts  $p }
    }
  }

  set headers {Datapath {Write Bandwidth (GB/s)} {Read Bandwidth (GB/s)}}
  set rows {}
  foreach cpi $cpi_list {
    set wcell "-"
    if {[dict exists $per_path "${cpi}_write"]} {
      set wcell [format "%.3f" [dict get $per_path "${cpi}_write" gbps]]
    }
    set rcell "-"
    if {[dict exists $per_path "${cpi}_read"]} {
      set rcell [format "%.3f" [dict get $per_path "${cpi}_read" gbps]]
    }
    lappend rows [list "CPI Instance $cpi" $wcell $rcell]
  }

  set wtotal "-"
  if {[llength $write_parts] > 0 && ![catch {combine_bandwidth $write_parts} wc]} {
    set wtotal [format "%.3f" [dict get $wc gbps]]
  }
  set rtotal "-"
  if {[llength $read_parts] > 0 && ![catch {combine_bandwidth $read_parts} rc]} {
    set rtotal [format "%.3f" [dict get $rc gbps]]
  }
  lappend rows [list "Total" $wtotal $rtotal]

  set widths {}
  foreach h $headers { lappend widths [string length $h] }
  foreach row $rows {
    for {set i 0} {$i < 3} {incr i} {
      set cw [string length [lindex $row $i]]
      if {$cw > [lindex $widths $i]} { lset widths $i $cw }
    }
  }

  set hdr_parts {}
  set sep_parts {}
  foreach h $headers w $widths {
    lappend hdr_parts [format "%-${w}s" $h]
    lappend sep_parts [string repeat "-" $w]
  }
  set hdr_line "  | [join $hdr_parts { | }] |"
  set sep_line "  |-[join $sep_parts {-|-}]-|"
  puts $chan $hdr_line
  puts $chan $sep_line
  set n_rows [llength $rows]
  for {set i 0} {$i < $n_rows} {incr i} {
    set row [lindex $rows $i]
    set row_parts [list [format "%-[lindex $widths 0]s" [lindex $row 0]]]
    lappend row_parts [format "%[lindex $widths 1]s" [lindex $row 1]]
    lappend row_parts [format "%[lindex $widths 2]s" [lindex $row 2]]
    if {$i == $n_rows - 1} { puts $chan $sep_line }
    puts $chan "  | [join $row_parts { | }] |"
  }
}

# Print-only orchestrator -- prints per-datapath latency tables/histograms
# and a bandwidth summary table; returns nothing. Call
# perf::compute_latency/perf::compute_bandwidth_all directly if you need
# the underlying data back. chan defaults to stdout; perf::report_to_file
# passes a file channel through instead so the whole report lands in the
# file. Reads happen silently (via read_ram_entries) -- no read_ram
# "Datapath N | IFACE | Entries: n" lines are printed here.
#
# Each cpi's 4 interfaces are read exactly ONCE (via read_cpi_entries) and
# the resulting cache is shared between the latency section and the
# compute_bandwidth_all call below -- without this, compute_latency and
# compute_path_bandwidth would each independently re-read the same 4 URAMs.
proc perf::report {args} {
  lassign $args cpi_list chan
  if {$chan eq ""} { set chan stdout }
  if {[catch {design::get_clk_hz} clk_err]} {
    error "perf::report: cannot compute latency without a clock frequency -- $clk_err"
  }
  puts stdout "INFO: This may take several minutes."
  if {[llength $cpi_list] == 0} { set cpi_list [design::get_cxl_indices] }
  set cache_by_cpi [dict create]
  foreach cpi $cpi_list {
    set entry_cache [read_cpi_entries $cpi]
    dict set cache_by_cpi $cpi $entry_cache
    set header "Datapath $cpi"
    puts $chan ""
    puts $chan $header
    puts $chan [string repeat "=" [string length $header]]
    foreach {path label} {
      write {Write Latency (f2a_data -> a2f_rsp)}
      read  {Read Latency (f2a_req -> a2f_data)}
    } {
      catch {compute_latency $cpi $path $entry_cache} stats
      print_latency_table $label $stats $chan
    }
  }
  puts $chan ""
  puts $chan "Bandwidth Summary"
  puts $chan "================="
  if {[catch {compute_bandwidth_all $cpi_list $cache_by_cpi} result]} {
    puts $chan "  (unavailable: $result)"
  } else {
    print_bandwidth_table $cpi_list $result $chan
  }
  puts $chan ""
  return
}

# Same report as perf::report, written to a file instead of stdout --
# handy for saving results. cpi_list defaults to every discovered cpi;
# filename defaults to "latency_report.txt".
proc perf::report_to_file {args} {
  lassign $args cpi_list filename
  if {[llength $cpi_list] == 0} { set cpi_list [design::get_cxl_indices] }
  if {$filename eq ""} { set filename "latency_report.txt" }
  set fh [open $filename w]
  report $cpi_list $fh
  close $fh
  puts "INFO: latency report for cpi(s) $cpi_list written to $filename"
  return
}

#----------------------------------------------------------------------------
# Raw data export
#----------------------------------------------------------------------------
# Returns the same nested {cpi -> {iface -> {entry list}}} dict as
# perf::capture_all (each entry a {cnt tag} dict), under a name suited to
# the raw-export workflow perf::raw_to_file builds on.
proc perf::get_raw {args} {
  lassign $args cpi_list
  if {[llength $cpi_list] == 0} { set cpi_list [design::get_cxl_indices] }
  return [capture_all $cpi_list]
}

proc perf::write_raw_txt {chan raw} {
  variable IFACE_NAMES
  foreach cpi [lsort -integer [dict keys $raw]] {
    set header "Datapath $cpi"
    puts $chan $header
    puts $chan [string repeat "-" [string length $header]]
    set per_iface [dict get $raw $cpi]
    foreach iface $IFACE_NAMES {
      set entries [dict get $per_iface $iface]
      puts $chan "[iface_label $iface] ([llength $entries] entries)"
      set idx 0
      foreach e $entries {
        puts $chan "  idx $idx: tag=[dict get $e tag] count=[dict get $e cnt]"
        incr idx
      }
    }
  }
}

proc perf::write_raw_csv {chan raw} {
  variable IFACE_NAMES
  puts $chan "cpi,iface,idx,tag,count"
  foreach cpi [lsort -integer [dict keys $raw]] {
    set per_iface [dict get $raw $cpi]
    foreach iface $IFACE_NAMES {
      set idx 0
      foreach e [dict get $per_iface $iface] {
        puts $chan "$cpi,$iface,$idx,[dict get $e tag],[dict get $e cnt]"
        incr idx
      }
    }
  }
}

proc perf::write_raw_yaml {chan raw} {
  variable IFACE_NAMES
  foreach cpi [lsort -integer [dict keys $raw]] {
    puts $chan "datapath_$cpi:"
    set per_iface [dict get $raw $cpi]
    foreach iface $IFACE_NAMES {
      set entries [dict get $per_iface $iface]
      if {[llength $entries] == 0} {
        puts $chan "  ${iface}: \[\]"
        continue
      }
      puts $chan "  ${iface}:"
      set idx 0
      foreach e $entries {
        puts $chan "    - {idx: $idx, tag: [dict get $e tag], count: [dict get $e cnt]}"
        incr idx
      }
    }
  }
}

# Writes perf::get_raw's data to fname.ftype (any "."-onward suffix already
# in fname is stripped first). ftype selects the format: "txt" (default),
# "csv", or "yaml"; errors immediately, without touching the filesystem, if
# ftype isn't one of those.
proc perf::raw_to_file {args} {
  lassign $args cpi_list ftype fname
  if {[llength $cpi_list] == 0} { set cpi_list [design::get_cxl_indices] }
  if {$ftype eq ""} { set ftype txt }
  if {$fname eq ""} { set fname raw_report }
  if {$ftype ni {txt csv yaml}} {
    error "unsupported ftype '$ftype' -- expected one of: txt, csv, yaml"
  }

  regsub {\..*$} $fname {} base
  set filename "${base}.${ftype}"
  set raw [get_raw $cpi_list]

  set fh [open $filename w]
  switch -- $ftype {
    txt  { write_raw_txt  $fh $raw }
    csv  { write_raw_csv  $fh $raw }
    yaml { write_raw_yaml $fh $raw }
  }
  close $fh
  puts "INFO: raw perf data for cpi(s) $cpi_list written to $filename"
  return
}
