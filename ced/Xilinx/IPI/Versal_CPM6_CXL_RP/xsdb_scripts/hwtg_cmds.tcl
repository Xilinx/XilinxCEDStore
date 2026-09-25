# hwtg_cmds.tcl
#
# The user-facing verbs: load/read/dump commands, parse/clear errors,
# start/stop/soft-reset, status/poll, and a synchronized multi-datapath
# trigger built on axil_gpio4. Every proc here takes a datapath index (cpi)
# first and resolves it through design::get_tg_base, so a bad index is
# rejected before any hardware access is attempted.

#----------------------------------------------------------------------------
# DPC xsdb target connect
#----------------------------------------------------------------------------
# Selects the DPC (PMC Debug Packet Controller) xsdb target, printing which
# target got assigned. Independent of design::connect -- it's purely a
# board-specific target-selection step.
proc hwtg::connect {} {
  targets -set -filter {name =~ "*DPC*"}
  puts "INFO: hwtg connected to target [design::current_target_desc]"
}

#----------------------------------------------------------------------------
# Argument validation
#----------------------------------------------------------------------------
# Every public command below takes cpi as its first argument via a bare
# `lassign $args ...` (so a missing argument silently becomes ""), which
# would otherwise surface many calls deep as a confusing blank-cpi error
# from design::get_tg_base. Called as the first line of every such command,
# right after its own lassign, so a missing cpi is rejected immediately
# with a message naming the command that needs it.
proc hwtg::require_cpi {cpi caller} {
  if {$cpi ne ""} { return }
  set indices [design::get_cxl_indices]
  if {[llength $indices] == 0} {
    error "$caller requires a cpi (datapath index) argument -- no datapaths discovered yet, call design::discover first"
  }
  error "$caller requires a cpi (datapath index) argument -- valid indices: $indices"
}

#----------------------------------------------------------------------------
# Address helpers
#----------------------------------------------------------------------------
proc hwtg::get_csr_addr {cpi name} {
  variable CSR
  variable CSR_BASE
  return [expr {[design::get_tg_base $cpi] + $CSR_BASE + $CSR($name)}]
}

proc hwtg::csr_read {cpi name} {
  return [control::rd32 [get_csr_addr $cpi $name]]
}

proc hwtg::csr_write {cpi name value} {
  control::wr32 [get_csr_addr $cpi $name] $value
}

proc hwtg::get_iram_slice_addr {cpi idx slice} {
  variable CSR_IRAM_BASE
  return [expr {[design::get_tg_base $cpi] + $CSR_IRAM_BASE + $idx * 0x20 + $slice * 4}]
}

proc hwtg::get_stat_addr {cpi idx} {
  variable CSR_STAT_BASE
  return [expr {[design::get_tg_base $cpi] + $CSR_STAT_BASE + $idx * 4}]
}

#----------------------------------------------------------------------------
# Run-state / programmed-state helpers
#----------------------------------------------------------------------------
proc hwtg::run_state {cpi} {
  return [expr {[csr_read $cpi TG_STATUS] & 0x7}]
}

proc hwtg::run_state_name {cpi} {
  variable RUN_STATE_NAMES
  set s [run_state $cpi]
  if {$s < [llength $RUN_STATE_NAMES]} { return [lindex $RUN_STATE_NAMES $s] }
  return "UNKNOWN($s)"
}

proc hwtg::require_idle {cpi op} {
  set s [run_state_name $cpi]
  if {$s ne "IDLE"} {
    error "datapath $cpi is not IDLE (state=$s); cannot $op while the iRAM is busy"
  }
}

# bit4 of the per-command status word: set once a command has been
# committed, cleared only by a soft reset. The set of true bits is always a
# contiguous prefix starting at index 0 (enforced by the hardware's own
# ERR_GAP check), so the first false index IS the append point.
proc hwtg::programmed_valid {cpi idx} {
  return [expr {([control::rd32 [get_stat_addr $cpi $idx]] >> 4) & 1}]
}

proc hwtg::next_free_index {cpi} {
  variable MAX_COMMANDS
  for {set idx 0} {$idx < $MAX_COMMANDS} {incr idx} {
    if {![programmed_valid $cpi $idx]} { return $idx }
  }
  error "iRAM for datapath $cpi is full (MAX_COMMANDS=$MAX_COMMANDS)"
}

proc hwtg::warn_addr_k_clamp {slices} {
  variable ADDR_K_MAX
  set k [decode_field $slices addr_k]
  if {$k > $ADDR_K_MAX} {
    puts "WARNING: addr_k=$k will be silently clamped to $ADDR_K_MAX at commit (legal range 0..$ADDR_K_MAX)"
  }
}

#----------------------------------------------------------------------------
# Load / commit
#----------------------------------------------------------------------------
proc hwtg::commit_slices {cpi idx slices} {
  variable MAX_COMMANDS
  require_idle $cpi "program idx $idx"
  if {$idx >= $MAX_COMMANDS} {
    error "index $idx out of range for datapath $cpi (MAX_COMMANDS=$MAX_COMMANDS)"
  }
  if {$idx > 0 && ![programmed_valid $cpi [expr {$idx - 1}]]} {
    error "cannot program idx $idx on datapath $cpi: idx [expr {$idx - 1}] is not yet programmed (would be rejected with ERR_GAP)"
  }
  for {set s 0} {$s < 6} {incr s} {
    control::wr32 [get_iram_slice_addr $cpi $idx $s] [lindex $slices $s]
  }
  set err [csr_read $cpi TG_BRESP_ERROR]
  if {$err & (1 << 1)} {
    error "commit of idx $idx on datapath $cpi was rejected: ERR_RSVD_OPCODE (opcode 2'b11 is reserved). Sticky error left set -- see hwtg::parse_errors / hwtg::clear_errors."
  }
}

proc hwtg::load_at {args} {
  lassign $args cpi idx line
  require_cpi $cpi hwtg::load_at
  set slices [assemble $line]
  warn_addr_k_clamp $slices
  commit_slices $cpi $idx $slices
  puts "INFO: datapath $cpi idx $idx <= $line"
  return $idx
}

proc hwtg::load_append {args} {
  lassign $args cpi line
  require_cpi $cpi hwtg::load_append
  set idx [next_free_index $cpi]
  return [load_at $cpi $idx $line]
}

proc hwtg::load_from_file {args} {
  lassign $args cpi path
  require_cpi $cpi hwtg::load_from_file
  set fh [open $path r]
  set n 0
  while {[gets $fh line] >= 0} {
    set trimmed [string trim $line]
    if {$trimmed eq "" || [string index $trimmed 0] eq "#"} { continue }
    load_append $cpi $trimmed
    incr n
  }
  close $fh
  puts "INFO: loaded $n command(s) from $path onto datapath $cpi"
  return $n
}

# Prompts on stdin for an index (blank = append), an opcode, then each field
# valid for that opcode (blank = default 0).
proc hwtg::load_interactive {args} {
  lassign $args cpi
  require_cpi $cpi hwtg::load_interactive
  variable ASM_KEYS
  puts "Loading a command onto datapath $cpi (base [format 0x%X [design::get_tg_base $cpi]])"
  puts -nonewline "index (blank = append): "
  flush stdout
  set idx_str [string trim [gets stdin]]
  puts -nonewline "opcode (WRITE/READ/WAIT): "
  flush stdout
  set opcode [string toupper [string trim [gets stdin]]]
  if {![info exists ASM_KEYS($opcode)]} {
    error "unknown opcode '$opcode' (expected WRITE, READ or WAIT)"
  }
  set fields {}
  foreach key $ASM_KEYS($opcode) {
    puts -nonewline "  $key (blank = 0): "
    flush stdout
    set v [string trim [gets stdin]]
    if {$v ne ""} { lappend fields "$key=$v" }
  }
  set line [join [concat [list $opcode] $fields] " "]
  if {$idx_str eq ""} {
    return [load_append $cpi $line]
  }
  return [load_at $cpi $idx_str $line]
}

#----------------------------------------------------------------------------
# Read / dump
#----------------------------------------------------------------------------
proc hwtg::read_cmd {args} {
  lassign $args cpi idx
  require_cpi $cpi hwtg::read_cmd
  # Port B (the AXI-Lite readback path) is borrowed from the sequencer only
  # while IDLE -- see custom_axi_tg_csr.sv's header comment.
  require_idle $cpi "read idx $idx"
  set slices {}
  for {set s 0} {$s < 6} {incr s} {
    lappend slices [control::rd32 [get_iram_slice_addr $cpi $idx $s]]
  }
  return [disassemble $slices]
}

proc hwtg::read_all {args} {
  lassign $args cpi
  require_cpi $cpi hwtg::read_all
  set done [csr_read $cpi TG_DONE_PTR]
  set lines {}
  for {set idx 0} {$idx < $done} {incr idx} {
    set line [read_cmd $cpi $idx]
    puts "Command $idx: $line"
    lappend lines $line
  }
  return $lines
}

proc hwtg::dump_to_file {args} {
  lassign $args cpi path
  require_cpi $cpi hwtg::dump_to_file
  set lines [read_all $cpi]
  set fh [open $path w]
  foreach line $lines { puts $fh $line }
  close $fh
  puts "INFO: dumped [llength $lines] command(s) from datapath $cpi to $path"
  return [llength $lines]
}

#----------------------------------------------------------------------------
# Errors
#----------------------------------------------------------------------------
proc hwtg::parse_errors {args} {
  lassign $args cpi
  require_cpi $cpi hwtg::parse_errors
  variable ERR_NAMES
  set w [csr_read $cpi TG_BRESP_ERROR]
  set bits [expr {$w & 0x3FF}]
  set first_idx [expr {($w >> 12) & 0x1FF}]
  set first_code [expr {($w >> 21) & 0xF}]

  set active {}
  for {set b 0} {$b < 10} {incr b} {
    if {($bits >> $b) & 1} { lappend active [lindex $ERR_NAMES $b] }
  }
  if {[llength $active] == 0} {
    puts "datapath $cpi: no sticky TG_BRESP_ERROR bits set"
  } else {
    set first_name [lindex $ERR_NAMES $first_code]
    puts "datapath $cpi: sticky errors: $active (first: $first_name @ idx $first_idx)"
  }

  set done [csr_read $cpi TG_DONE_PTR]
  for {set idx 0} {$idx < $done} {incr idx} {
    set sw [control::rd32 [get_stat_addr $cpi $idx]]
    if {($sw >> 3) & 1} {
      set inv_num [expr {($sw >> 8) & 0xFFF}]
      set inv_id  [expr {($sw >> 20) & 0xF}]
      puts "  idx $idx: SLVERR seen (first invalid transaction #$inv_num, AXI ID $inv_id)"
    } elseif {($sw >> 2) & 1} {
      puts "  idx $idx: non-OKAY (EXOKAY) response seen"
    }
  }
  return $active
}

proc hwtg::clear_errors {args} {
  lassign $args cpi
  require_cpi $cpi hwtg::clear_errors
  csr_write $cpi TG_BRESP_ERROR 0x3FF
  puts "INFO: cleared sticky TG_BRESP_ERROR on datapath $cpi"
}

#----------------------------------------------------------------------------
# Start / stop / soft-reset
#----------------------------------------------------------------------------
proc hwtg::start {args} {
  lassign $args cpi
  require_cpi $cpi hwtg::start
  set state [run_state_name $cpi]
  if {$state ni {IDLE ALL_RESPONDED}} {
    error "datapath $cpi: cannot start from state $state (must be IDLE or ALL_RESPONDED)"
  }
  csr_write $cpi TG_CTRL 0x1
  puts "INFO: datapath $cpi started"
}

proc hwtg::stop {args} {
  lassign $args cpi
  require_cpi $cpi hwtg::stop
  csr_write $cpi TG_CTRL 0x0
  puts "INFO: datapath $cpi stop requested (state moves to STOPPING until the drain completes)"
}

proc hwtg::soft_reset {args} {
  lassign $args cpi
  require_cpi $cpi hwtg::soft_reset
  set state [run_state_name $cpi]
  if {$state ni {IDLE ALL_RESPONDED}} {
    error "datapath $cpi: cannot soft-reset from state $state (must be IDLE or ALL_RESPONDED, matches ERR_SOFT_RST_BUSY)"
  }
  csr_write $cpi TG_CTRL 0x2
  puts "INFO: datapath $cpi soft-reset (programmed state cleared; iRAM content untouched)"
}

#----------------------------------------------------------------------------
# Status / poll
#----------------------------------------------------------------------------
proc hwtg::status {args} {
  lassign $args cpi
  require_cpi $cpi hwtg::status
  set w [csr_read $cpi TG_STATUS]
  puts [join [list \
    "datapath $cpi: state=[run_state_name $cpi]" \
    "cur_cmd_ptr=[expr {($w >> 4) & 0x1FF}]" \
    "done_ptr=[csr_read $cpi TG_DONE_PTR]" \
    "wr_busy=[expr {($w >> 16) & 1}]" \
    "rd_busy=[expr {($w >> 17) & 1}]" \
    "wr_ring_empty=[expr {($w >> 18) & 1}]" \
    "rd_ring_empty=[expr {($w >> 19) & 1}]" \
    "wr_ring_full=[expr {($w >> 20) & 1}]" \
    "rd_ring_full=[expr {($w >> 21) & 1}]" \
    "start_busy_err=[expr {($w >> 22) & 1}]" \
    "any_cmd_err=[expr {($w >> 23) & 1}]" \
    ] " "]
  return $w
}

proc hwtg::wait_done {args} {
  lassign $args cpi timeout_s
  require_cpi $cpi hwtg::wait_done
  if {$timeout_s eq ""} { set timeout_s 5 }
  set deadline [expr {[clock seconds] + $timeout_s}]
  while {1} {
    set state [run_state_name $cpi]
    if {$state in {ALL_RESPONDED IDLE}} { return $state }
    if {[clock seconds] >= $deadline} {
      error "datapath $cpi: timed out after ${timeout_s}s waiting for completion (state=$state)"
    }
    after 50
  }
}

# Live read of TG_CFG, in case MAX_COMMANDS/AXI_ID_WIDTH/etc. ever diverge
# from the hwtg_pkg.tcl defaults.
proc hwtg::tg_cfg {args} {
  lassign $args cpi
  require_cpi $cpi hwtg::tg_cfg
  set w [csr_read $cpi TG_CFG]
  return [dict create \
    axi_address_width [expr {$w & 0xFF}] \
    axi_id_width      [expr {($w >> 8) & 0xF}] \
    axi_axil_sync     [expr {($w >> 12) & 0x1}] \
    max_commands      [expr {($w >> 16) & 0x3FF}] \
    ring_depth        [expr {($w >> 26) & 0xF}] \
    cpq_depth         [expr {($w >> 30) & 0x3}]]
}

#----------------------------------------------------------------------------
# Synchronized multi-datapath trigger, via axil_gpio4's external i_start pins
# (distinct from each TG's own AXI-Lite TG_CTRL.START -- one masked GPIO
# write pulses every listed tg_start on the SAME clock edge, instead of N
# separate, skewed AXI-Lite transactions).
#----------------------------------------------------------------------------
proc hwtg::ext_trigger {args} {
  lassign $args cpi_list
  variable GPIO_MODE
  variable GPIO_GPIO
  if {[llength $cpi_list] == 0} {
    error "hwtg::ext_trigger requires a cpi_list argument (e.g. {0 2}) -- use hwtg::ext_trigger_all to trigger every discovered datapath instead"
  }

  set mask 0
  foreach cpi $cpi_list {
    if {$cpi < 0 || $cpi > 3} {
      error "axil_gpio4 only has 4 output bits (0..3); got cpi=$cpi"
    }
    set mask [expr {$mask | (1 << $cpi)}]
  }

  set base [design::get_gpio_base]
  # Make sure the bits we're about to drive are in pulse mode (self-clearing
  # after STRETCH+1 cycles) so the caller doesn't need a separate "release
  # i_start" step. Bits outside $mask are left exactly as they were.
  set cur_mode [control::rd32 [expr {$base + $GPIO_MODE}]]
  set new_mode [expr {$cur_mode | $mask}]
  if {$new_mode != $cur_mode} {
    control::wr32 [expr {$base + $GPIO_MODE}] $new_mode
  }
  # GPIO reg: mask bits[19:16] select which gpio_out bits update this write,
  # data bits[3:0] are the new values.
  control::wr32 [expr {$base + $GPIO_GPIO}] [expr {($mask << 16) | $mask}]
  puts "INFO: pulsed tg_start simultaneously on datapath(s) $cpi_list"
}

# Convenience wrapper: same as ext_trigger, but defaults cpi_list to every
# discovered datapath instead of requiring one.
proc hwtg::ext_trigger_all {args} {
  lassign $args cpi_list
  if {[llength $cpi_list] == 0} { set cpi_list [design::get_cxl_indices] }
  ext_trigger $cpi_list
}
