# gpio.tcl - top-level loader for the external-GPIO control library: 8 LEDs
# (static/blink/PWM), 4 pushbuttons, 4 DIP switches, input events and a soft
# reset on gpio_ext_axil_0. Requires design:: and control:: already loaded
# (for the address map/clock discovery and the JTAG register transport
# respectively) -- source design.tcl and control.tcl first, or just source
# all.tcl.
#
#   source xsdb_scripts/all.tcl
#   design::discover [pwd]
#   design::connect
#   design::program                 ;# loads the PDI
#   gpio::connect
#   gpio::led_write 0x0F
#   gpio::led_blink 4 500ms
#   gpio::led_pwm 5 25%
#   gpio::read
#   gpio::irq_config btn both
#   gpio::irq_status btn

set gpio_script_dir [file dirname [file normalize [info script]]]

if {![llength [info commands ::design::get_ext_gpio_base]]} {
  error "gpio requires design to be loaded first -- run: source [file join $gpio_script_dir design.tcl]"
}
if {![llength [info commands ::control::rd32]]} {
  error "gpio requires control to be loaded first -- run: source [file join $gpio_script_dir control.tcl]"
}

source [file join $gpio_script_dir pkg_help.tcl]
source [file join $gpio_script_dir pkg_args.tcl]
source [file join $gpio_script_dir gpio_pkg.tcl]
source [file join $gpio_script_dir gpio_cmds.tcl]
source [file join $gpio_script_dir gpio_help.tcl]
unset gpio_script_dir

puts "INFO: gpio loaded."
puts "INFO: Run gpio::help (or gpio::h) for the command reference; gpio::help <cmd> for detailed help on one command."
