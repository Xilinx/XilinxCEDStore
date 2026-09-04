# control_cmds.tcl
#
# Display/control of the PMC's RST_PL fabric-reset register. This design
# has two independently resettable domains reachable through it (bits 0
# and 2); bits 1 and 3 exist in the register but aren't wired to anything
# here.

proc control::validate_rst_bit {bit} {
  variable RST_PL_BITS
  if {$bit < 0 || $bit > 3} {
    error "bit $bit out of range for RST_PL (valid: 0-3)"
  }
  if {$bit ni {0 2}} {
    puts "WARNING: RST_PL bit $bit is not wired to any net in this design ($RST_PL_BITS($bit)) -- this write will have no observable effect"
  }
}

proc control::pl_rst_status {} {
  variable RST_PL_ADDR
  variable RST_PL_BITS
  set val [rd32 $RST_PL_ADDR]
  puts [format "RST_PL (0x%X) = 0x%X" $RST_PL_ADDR $val]
  for {set i 0} {$i < 4} {incr i} {
    set state [expr {($val >> $i) & 1}]
    puts [format "  RESET%d: %d (%s) -- %s" $i $state [expr {$state ? "ASSERTED" : "deasserted"}] $RST_PL_BITS($i)]
  }
  return $val
}

proc control::pl_rst_set {args} {
  lassign $args bits
  variable RST_PL_ADDR
  wr32 $RST_PL_ADDR [expr {$bits & 0xF}]
  puts [format "INFO: RST_PL <= 0x%X" [expr {$bits & 0xF}]]
  return [pl_rst_status]
}

proc control::pl_rst_assert {args} {
  lassign $args bit
  variable RST_PL_ADDR
  validate_rst_bit $bit
  set cur [rd32 $RST_PL_ADDR]
  wr32 $RST_PL_ADDR [expr {$cur | (1 << $bit)}]
  set rb [rd32 $RST_PL_ADDR]
  if {!(($rb >> $bit) & 1)} { error "pl_rst_assert: bit $bit write did not take effect (readback=0x[format %X $rb])" }
  puts "INFO: RST_PL bit $bit asserted"
}

proc control::pl_rst_deassert {args} {
  lassign $args bit
  variable RST_PL_ADDR
  validate_rst_bit $bit
  set cur [rd32 $RST_PL_ADDR]
  wr32 $RST_PL_ADDR [expr {$cur & ~(1 << $bit)}]
  set rb [rd32 $RST_PL_ADDR]
  if {(($rb >> $bit) & 1)} { error "pl_rst_deassert: bit $bit write did not take effect (readback=0x[format %X $rb])" }
  puts "INFO: RST_PL bit $bit deasserted"
}

# No configurable pulse width: the JTAG round-trip between the assert and
# deassert writes is already slow enough relative to the reset logic to
# act as an adequate pulse.
proc control::pl_rst_pulse {args} {
  lassign $args bit
  pl_rst_assert $bit
  pl_rst_deassert $bit
  puts "INFO: RST_PL bit $bit pulsed"
}

# Pulses all 4 RST_PL bits together -- bits 0/2 (cxl1_rstn/axil_rstn) reset
# the traffic generator/perf-monitor datapath without a full design::program
# PDI reload; bits 1/3 are not wired to any net in this design, so pulsing
# them has no observable effect, but the register write still touches them.
# NOTE: unlike hwtg::ext_trigger_all's synchronous GPIO pulse, this does not
# guarantee the wired domains release on the same cycle -- each bit passes
# through its own independent xpm_cdc_gen (2 DEST_SYNC_FF stages); only the
# register WRITE is simultaneous.
proc control::pl_rst_pulse_all {} {
  variable RST_PL_ADDR
  set mask 0xF
  set cur [rd32 $RST_PL_ADDR]
  wr32 $RST_PL_ADDR [expr {$cur | $mask}]
  wr32 $RST_PL_ADDR [expr {$cur & ~$mask}]
  puts "INFO: RST_PL bits 0-3 pulsed together -- cxl1_rstn + axil_rstn wired,"
  puts "      bits 1/3 unwired in this design"
}
