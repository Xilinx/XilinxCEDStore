# gpio_cmds.tcl
#
# Controls the external GPIO block (gpio_ext_axil_0): 8 LEDs with static,
# blink and PWM modes, 4 debounced pushbuttons, 4 debounced DIP switches,
# programmable edge-event status for the inputs, and a soft reset. Every
# argument is validated before any register access.

#----------------------------------------------------------------------------
# DPC xsdb target connect
#----------------------------------------------------------------------------
# Selects the DPC (PMC Debug Packet Controller) xsdb target, printing which
# target got assigned. Independent of design::connect -- it's purely a
# board-specific target-selection step.
proc gpio::connect {} {
  targets -set -filter {name =~ "*DPC*"}
  puts "INFO: gpio connected to target [design::current_target_desc]"
}

#----------------------------------------------------------------------------
# Register access helpers (offsets are relative to the block's base address)
#----------------------------------------------------------------------------
proc gpio::rd {off} {
  return [control::rd32 [expr {[design::get_ext_gpio_base] + $off}]]
}

proc gpio::wr {off val} {
  control::wr32 [expr {[design::get_ext_gpio_base] + $off}] $val
}

# Bits set in mask are replaced by the same bits of val; all other bits are
# preserved.
proc gpio::rmw {off mask val} {
  set cur [rd $off]
  wr $off [expr {($cur & ~$mask & 0xFFFFFFFF) | ($val & $mask)}]
}

# 1.5 -> "1.5 s", 0.0005 -> "500 us"
proc gpio::fmt_time {secs} {
  if {$secs >= 1.0}  { return [format "%.4g s"  $secs] }
  if {$secs >= 1e-3} { return [format "%.4g ms" [expr {$secs * 1e3}]] }
  if {$secs >= 1e-6} { return [format "%.4g us" [expr {$secs * 1e6}]] }
  return [format "%.4g ns" [expr {$secs * 1e9}]]
}

# "<x>ms" or "<y>s" -> seconds. The unit is required.
proc gpio::parse_period {caller val} {
  set usage "expected <x>ms or <y>s (e.g. 250ms, 1.5s)"
  if {$val eq ""} {
    error "$caller: period is required -- $usage"
  }
  if {![regexp -nocase {^([0-9]+(\.[0-9]*)?|\.[0-9]+)(ms|s)$} $val -> num frac unit]} {
    if {[string is double -strict $val]} {
      error "$caller: period '$val' has no unit -- $usage"
    }
    error "$caller: period '$val' is not valid -- $usage"
  }
  # Strip leading zeros so Tcl does not read "08" as a bad octal literal
  regsub {^0+(?=[0-9])} $num {} num
  set secs [expr {[string tolower $unit] eq "ms" ? $num / 1000.0 : $num * 1.0}]
  if {$secs <= 0} {
    error "$caller: period '$val' must be > 0 -- $usage"
  }
  return $secs
}

#----------------------------------------------------------------------------
# Raw register dump
#----------------------------------------------------------------------------
proc gpio::dump {args} {
  variable REG_LED_VAL
  variable REG_LED_MODE
  variable REG_BTN
  variable REG_SW
  variable REG_LED_CNT0
  variable REG_BTN_IRQ_STATUS
  variable REG_BTN_IRQ_ENABLE
  variable REG_BTN_IRQ_EDGE
  variable REG_SW_IRQ_STATUS
  variable REG_SW_IRQ_ENABLE
  variable REG_SW_IRQ_EDGE
  variable NUM_LEDS
  chk::nargs gpio::dump $args 0 0 ""

  set regs [list \
    LED_VAL $REG_LED_VAL LED_MODE $REG_LED_MODE \
    BTN $REG_BTN SW $REG_SW]
  for {set i 0} {$i < $NUM_LEDS} {incr i} {
    lappend regs LED_CNT$i [expr {$REG_LED_CNT0 + 4 * $i}]
  }
  lappend regs \
    BTN_IRQ_STATUS $REG_BTN_IRQ_STATUS BTN_IRQ_ENABLE $REG_BTN_IRQ_ENABLE \
    BTN_IRQ_EDGE $REG_BTN_IRQ_EDGE \
    SW_IRQ_STATUS $REG_SW_IRQ_STATUS SW_IRQ_ENABLE $REG_SW_IRQ_ENABLE \
    SW_IRQ_EDGE $REG_SW_IRQ_EDGE

  set base [design::get_ext_gpio_base]
  puts [format "gpio_ext_axil_0 @ 0x%X" $base]
  puts [format "  %-6s  %-15s  %s" offset register value]
  foreach {name off} $regs {
    puts [format "  0x%03X   %-15s  0x%08X" $off $name [rd $off]]
  }
  puts "  (SOFT_RESET at 0x048 is write-only and is not read)"
}

#----------------------------------------------------------------------------
# LEDs
#----------------------------------------------------------------------------
# LED_VAL is the LED value in static mode, and the enable in blink/PWM modes.
proc gpio::led_write {args} {
  variable REG_LED_VAL
  chk::nargs gpio::led_write $args 1 1 value
  lassign $args value
  set value [chk::int gpio::led_write value $value 0 0xFF]
  wr $REG_LED_VAL $value
  puts [format "INFO: LED_VAL = 0x%02X" $value]
}

proc gpio::led_set {args} {
  variable REG_LED_VAL
  variable NUM_LEDS
  chk::nargs gpio::led_set $args 2 2 "led on|off"
  lassign $args led state
  set led [chk::int gpio::led_set led $led 0 [expr {$NUM_LEDS - 1}]]
  chk::oneof gpio::led_set state $state {on off}
  rmw $REG_LED_VAL [expr {1 << $led}] [expr {$state eq "on" ? 1 << $led : 0}]
  puts "INFO: LED $led $state"
}

proc gpio::led_mode {args} {
  variable REG_LED_MODE
  variable NUM_LEDS
  variable MODE_CODE
  chk::nargs gpio::led_mode $args 2 2 "led static|blink|pwm"
  lassign $args led mode
  set led [chk::int gpio::led_mode led $led 0 [expr {$NUM_LEDS - 1}]]
  chk::oneof gpio::led_mode mode $mode [lsort [array names MODE_CODE]]
  rmw $REG_LED_MODE [expr {0xF << (4 * $led)}] \
    [expr {$MODE_CODE($mode) << (4 * $led)}]
  puts "INFO: LED $led mode = $mode"
}

# Programs the blink counter, switches the LED to blink mode, then enables
# it. The LED toggles every (N+1) clocks, so one full period is 2*(N+1).
proc gpio::led_blink {args} {
  variable REG_LED_CNT0
  variable NUM_LEDS
  variable CNT_MAX
  chk::nargs gpio::led_blink $args 2 2 "led period"
  lassign $args led period
  set led [chk::int gpio::led_blink led $led 0 [expr {$NUM_LEDS - 1}]]
  set secs [parse_period gpio::led_blink $period]

  set clk  [design::get_ext_gpio_clk_hz]
  set tick [expr {int(round($secs * $clk / 2.0))}]   ;# clocks per toggle
  if {$tick < 1} {
    error "gpio::led_blink: period '$period' is too short -- minimum is 2 clocks ([fmt_time [expr {2.0 / $clk}]])"
  }
  if {$tick > $CNT_MAX + 1} {
    error "gpio::led_blink: period '$period' is too long -- maximum is [fmt_time [expr {2.0 * ($CNT_MAX + 1) / $clk}]]"
  }
  set n [expr {$tick - 1}]

  wr [expr {$REG_LED_CNT0 + 4 * $led}] $n
  led_mode $led blink
  led_set $led on
  puts "INFO: LED $led blinking, period [fmt_time [expr {2.0 * $tick / $clk}]] (requested $period, LED_CNT$led = $n)"
}

# "<n>%" -> integer percent. The % is required.
proc gpio::parse_duty {caller val} {
  variable PWM_MAX_DUTY
  set usage "expected <n>% with n a whole number 0..$PWM_MAX_DUTY (e.g. 62%)"
  if {$val eq ""} {
    error "$caller: duty is required -- $usage"
  }
  if {![string match {*%} $val]} {
    error "$caller: duty '$val' has no % -- $usage"
  }
  set num [string range $val 0 end-1]
  if {![regexp {^[0-9]+$} $num]} {
    error "$caller: duty '$val' is not valid -- $usage"
  }
  # Strip leading zeros so Tcl does not read "08" as a bad octal literal
  regsub {^0+(?=[0-9])} $num {} num
  if {$num > $PWM_MAX_DUTY} {
    error "$caller: duty '$val' is out of range -- $usage"
  }
  return $num
}

# Programs the duty cycle, switches the LED to PWM mode, then enables it.
proc gpio::led_pwm {args} {
  variable REG_LED_CNT0
  variable NUM_LEDS
  variable PWM_MAX_DUTY
  chk::nargs gpio::led_pwm $args 2 2 "led duty"
  lassign $args led duty
  set led  [chk::int gpio::led_pwm led $led 0 [expr {$NUM_LEDS - 1}]]
  set duty [parse_duty gpio::led_pwm $duty]

  wr [expr {$REG_LED_CNT0 + 4 * $led}] $duty
  led_mode $led pwm
  led_set $led on
  puts "INFO: LED $led PWM duty $duty%"
}

# All LEDs off and static
proc gpio::led_off {args} {
  variable REG_LED_VAL
  variable REG_LED_MODE
  chk::nargs gpio::led_off $args 0 0 ""
  wr $REG_LED_VAL 0
  wr $REG_LED_MODE 0
  puts "INFO: all LEDs off and static"
}

#----------------------------------------------------------------------------
# Pushbuttons and DIP switches
#----------------------------------------------------------------------------
proc gpio::btn {args} {
  variable REG_BTN
  chk::nargs gpio::btn $args 0 0 ""
  return [expr {[rd $REG_BTN] & 0xF}]
}

proc gpio::sw {args} {
  variable REG_SW
  chk::nargs gpio::sw $args 0 0 ""
  return [expr {[rd $REG_SW] & 0xF}]
}

# Prints the debounced inputs and pending (unmasked) event status
proc gpio::read {args} {
  variable REG_BTN
  variable REG_SW
  variable IRQ_STATUS
  chk::nargs gpio::read $args 0 0 ""
  set btn [expr {[rd $REG_BTN] & 0xF}]
  set sw  [expr {[rd $REG_SW]  & 0xF}]
  set bst [expr {[rd $IRQ_STATUS(btn)] & 0xF}]
  set sst [expr {[rd $IRQ_STATUS(sw)]  & 0xF}]
  puts [format "BTN = 0x%X (%s)  event status = 0x%X" $btn [bin4 $btn] $bst]
  puts [format "SW  = 0x%X (%s)  event status = 0x%X" $sw  [bin4 $sw]  $sst]
}

proc gpio::bin4 {v} {
  set s ""
  for {set b 3} {$b >= 0} {incr b -1} { append s [expr {($v >> $b) & 1}] }
  return $s
}

#----------------------------------------------------------------------------
# Input events
#----------------------------------------------------------------------------
# edges is one keyword applied to all 4 inputs, or a list of 4 keywords (one
# per input, input 0 first). Returns a list of 4 edge codes.
proc gpio::edge_codes {caller edges} {
  variable EDGE_CODE
  variable NUM_IN
  set choices [lsort [array names EDGE_CODE]]
  set n [llength $edges]
  if {$n == 0} {
    error "$caller: edges is required -- valid: one of [join $choices {, }], or a list of $NUM_IN of them"
  }
  if {$n != 1 && $n != $NUM_IN} {
    error "$caller: edges '$edges' has $n element(s) -- expected one keyword (applies to all inputs) or a list of $NUM_IN (one per input)"
  }
  if {$n == 1} { set edges [lrepeat $NUM_IN [lindex $edges 0]] }
  set codes {}
  foreach e $edges {
    chk::oneof $caller edge $e $choices
    lappend codes $EDGE_CODE($e)
  }
  return $codes
}

# Sets which edges latch a sticky event for each input, and optionally which
# status bits are enabled to drive the block's interrupt output.
proc gpio::irq_config {args} {
  variable IRQ_EDGE
  variable IRQ_ENABLE
  chk::nargs gpio::irq_config $args 2 3 "btn|sw edges ?enable_mask?"
  lassign $args grp edges enable
  chk::oneof gpio::irq_config grp $grp {btn sw}
  set codes [edge_codes gpio::irq_config $edges]
  if {$enable ne ""} {
    set enable [chk::int gpio::irq_config enable_mask $enable 0 0xF]
  }

  set val 0
  set i 0
  foreach c $codes { set val [expr {$val | ($c << (2 * $i))}]; incr i }
  wr $IRQ_EDGE($grp) $val
  if {$enable ne ""} { wr $IRQ_ENABLE($grp) $enable }
  puts [format "INFO: $grp edge control = 0x%02X%s" $val \
    [expr {$enable ne "" ? [format ", interrupt enable = 0x%X" $enable] : ""}]]
}

# Returns the sticky event status bits (does not clear them)
proc gpio::irq_status {args} {
  variable IRQ_STATUS
  chk::nargs gpio::irq_status $args 1 1 "btn|sw"
  lassign $args grp
  chk::oneof gpio::irq_status grp $grp {btn sw}
  return [expr {[rd $IRQ_STATUS($grp)] & 0xF}]
}

# The status register is write-1-to-clear
proc gpio::irq_clear {args} {
  variable IRQ_STATUS
  chk::nargs gpio::irq_clear $args 2 2 "btn|sw mask"
  lassign $args grp mask
  chk::oneof gpio::irq_clear grp $grp {btn sw}
  set mask [chk::int gpio::irq_clear mask $mask 0 0xF]
  wr $IRQ_STATUS($grp) $mask
  puts [format "INFO: cleared $grp event status bits 0x%X" $mask]
}

#----------------------------------------------------------------------------
# Soft reset
#----------------------------------------------------------------------------
# Resets the block's registers, LED/blink/PWM state, and debouncers (not the
# AXI interface logic). Independent of RST_PL bit 2.
proc gpio::soft_reset {args} {
  variable REG_SOFT_RESET
  chk::nargs gpio::soft_reset $args 0 0 ""
  wr $REG_SOFT_RESET 1
  puts "INFO: gpio soft reset issued"
}
