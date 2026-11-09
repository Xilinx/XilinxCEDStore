# gpio_pkg.tcl
#
# Constants mirrored from the external-GPIO RTL. Keep in sync by hand with:
# src/gpio_ext_axil_slave.sv (register map, mode encoding, field widths).

namespace eval gpio {
  # Register byte offsets from design::get_ext_gpio_base
  variable REG_LED_VAL        0x000
  variable REG_LED_MODE       0x004
  variable REG_BTN            0x008
  variable REG_SW             0x00C
  variable REG_LED_CNT0       0x010   ;# LED_CNTi is at REG_LED_CNT0 + 4*i
  variable REG_BTN_IRQ_STATUS 0x030
  variable REG_BTN_IRQ_ENABLE 0x034
  variable REG_BTN_IRQ_EDGE   0x038
  variable REG_SW_IRQ_STATUS  0x03C
  variable REG_SW_IRQ_ENABLE  0x040
  variable REG_SW_IRQ_EDGE    0x044
  variable REG_SOFT_RESET     0x048   ;# write-only, self-clearing

  variable NUM_LEDS 8
  variable NUM_IN   4                 ;# pushbuttons, and DIP switches

  # LED_MODE: one nibble per LED, LED i at [4i+3:4i]; nibble[1:0] is the
  # mode and nibble[3:2] is reserved. Code 3 is reserved (acts as static).
  variable MODE_CODE
  array set MODE_CODE {static 0 blink 1 pwm 2}
  variable MODE_NAME
  array set MODE_NAME {0 static 1 blink 2 pwm 3 reserved}

  # <grp>_IRQ_EDGE: two bits per input, bit0 = rising, bit1 = falling
  variable EDGE_CODE
  array set EDGE_CODE {off 0 rise 1 fall 2 both 3}

  # Per-group register offsets, keyed by group name
  variable IRQ_STATUS
  array set IRQ_STATUS {btn 0x030 sw 0x03C}
  variable IRQ_ENABLE
  array set IRQ_ENABLE {btn 0x034 sw 0x040}
  variable IRQ_EDGE
  array set IRQ_EDGE   {btn 0x038 sw 0x044}

  variable PWM_MAX_DUTY 100            ;# percent
  variable CNT_MAX      0xFFFFFFFF     ;# LED_CNTi is 32 bits

  # Blink toggles the LED every (LED_CNTi + 1) clocks, so one full period
  # (on + off) is 2 * (LED_CNTi + 1) clocks.
}
