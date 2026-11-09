# gpio_help.tcl

namespace eval gpio {
  variable COMMANDS {
    connect dump
    led_write led_set led_mode led_blink led_pwm led_off
    btn sw read
    irq_config irq_status irq_clear
    soft_reset
  }

  array set CMD_SUMMARY {
    connect     "select the DPC xsdb target"
    dump        "print every readable register, by offset"
    led_write   "write all 8 LED values (or enables) at once"
    led_set     "turn one LED on or off (or enable/disable its blink/PWM)"
    led_mode    "set one LED's mode: static, blink, or pwm"
    led_blink   "blink one LED with a period given as <x>ms or <y>s"
    led_pwm     "drive one LED with a PWM duty cycle, <n>% with n 0..100"
    led_off     "all LEDs off and back to static mode"
    btn         "return the 4 debounced pushbuttons as an integer"
    sw          "return the 4 debounced DIP switches as an integer"
    read        "print the debounced inputs and their pending event status"
    irq_config  "choose which edges latch an event per input, and the interrupt enables"
    irq_status  "return a group's sticky event status bits (does not clear them)"
    irq_clear   "clear a group's sticky event status bits"
    soft_reset  "reset the GPIO block's registers, LED engine and debouncers"
  }

  array set CMD_HELP {}

  set CMD_HELP(connect) [join {
    {No args.}
    {}
    {Selects the DPC (PMC Debug Packet Controller) xsdb target, printing}
    {the specific target index and name landed on. Independent of}
    {design::connect -- it's purely a board-specific target-selection step.}
    {No register is read.}
  } "\n"]

  set CMD_HELP(dump) [join {
    {No args.}
    {}
    {Reads and prints every readable register of gpio_ext_axil_0 as}
    {offset, name and raw 32-bit value. SOFT_RESET is write-only and is not}
    {read. Requires design::discover to have found the block.}
  } "\n"]

  set CMD_HELP(led_write) [join {
    {Args:}
    {  value -- 8-bit value, one bit per LED (integer, 0..0xFF)}
    {}
    {Writes LED_VAL. In static mode each bit is the LED value; in blink or}
    {PWM mode it is that LED's enable.}
  } "\n"]

  set CMD_HELP(led_set) [join {
    {Args:}
    {  led   -- LED index (integer, 0..7)}
    {  state -- on or off}
    {}
    {Read-modify-write of one LED_VAL bit. In blink or PWM mode this}
    {enables or disables the pattern (disabled holds the LED off).}
  } "\n"]

  set CMD_HELP(led_mode) [join {
    {Args:}
    {  led  -- LED index (integer, 0..7)}
    {  mode -- one of: blink pwm static}
    {}
    {Read-modify-write of that LED's nibble in LED_MODE. Does not change}
    {LED_VAL or the LED's LED_CNT value.}
  } "\n"]

  set CMD_HELP(led_blink) [join {
    {Args:}
    {  led    -- LED index (integer, 0..7)}
    {  period -- full on+off period, <x>ms or <y>s (e.g. 250ms, 1.5s)}
    {            The unit is required.}
    {}
    {Writes the blink counter, sets the LED to blink mode, and enables it.}
    {The LED toggles every N+1 clocks, so the period is programmed in}
    {steps of 2 clocks of the block's clock (design::get_ext_gpio_clk_hz).}
    {The period actually programmed is printed.}
    {The shortest period is 2 clocks; the longest is 2*2^32 clocks.}
  } "\n"]

  set CMD_HELP(led_pwm) [join {
    {Args:}
    {  led  -- LED index (integer, 0..7)}
    {  duty -- duty cycle as <n>%, n a whole number 0..100 (e.g. 62%).}
    {          The % is required.}
    {}
    {Writes the duty cycle, sets the LED to PWM mode, and enables it.}
    {All PWM LEDs share one time base at the block's fixed PWM frequency.}
  } "\n"]

  set CMD_HELP(led_off) [join {
    {No args.}
    {}
    {Writes 0 to LED_VAL and LED_MODE: every LED off and in static mode.}
    {The LED_CNT values are left as they are.}
  } "\n"]

  set CMD_HELP(btn) [join {
    {No args.}
    {}
    {Returns the 4 debounced pushbuttons as an integer, bit i = pushbutton}
    {i (1 = pressed).}
  } "\n"]

  set CMD_HELP(sw) [join {
    {No args.}
    {}
    {Returns the 4 debounced DIP switches as an integer, bit i = switch i}
    {(1 = on).}
  } "\n"]

  set CMD_HELP(read) [join {
    {No args.}
    {}
    {Prints the debounced pushbuttons and DIP switches (hex and binary)}
    {along with each group's sticky event status.}
  } "\n"]

  set CMD_HELP(irq_config) [join {
    {Args:}
    {  grp         -- btn or sw}
    {  edges       -- one of: both fall off rise, applied to all 4 inputs;}
    {                or a list of 4 of them, one per input, input 0 first,}
    {                e.g. {rise off both fall}}
    {  enable_mask -- (optional) which status bits drive the interrupt}
    {                output (integer, 0..0xF). Left unchanged if omitted.}
    {}
    {Writes the group's edge control and, if given, interrupt enable. The}
    {interrupt outputs (btn_irq, switch_irq, any_irq) are not connected to}
    {anything in this design, so use irq_status to see events. The reset}
    {default is both edges, nothing enabled.}
  } "\n"]

  set CMD_HELP(irq_status) [join {
    {Args:}
    {  grp -- btn or sw}
    {}
    {Returns the group's sticky event status bits (integer, 0..0xF). Does}
    {not clear them; use irq_clear. The first sample after reset never}
    {sets a bit.}
  } "\n"]

  set CMD_HELP(irq_clear) [join {
    {Args:}
    {  grp  -- btn or sw}
    {  mask -- status bits to clear (integer, 0..0xF)}
    {}
    {Writes the group's status register; each 1 bit clears that event.}
  } "\n"]

  set CMD_HELP(soft_reset) [join {
    {No args.}
    {}
    {Writes the SOFT_RESET register. One clock later the block's registers}
    {return to their reset values (LEDs off and static, events and}
    {enables cleared, edge control back to both edges), the LED, blink and}
    {PWM state restarts, and the debouncers re-load their first sample}
    {without raising an event. The AXI interface is not reset.}
    {This is separate from RST_PL bit 2 (control::pl_rst_*), which resets}
    {the block through the PL reset pin.}
  } "\n"]

  proc help {{cmd ""}} { return [::pkg_help gpio $cmd] }
  proc h {{cmd ""}} { return [help $cmd] }
}
