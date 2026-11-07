# Board GPIO: 8 LEDs, 4 pushbuttons, 4 DIP switches (LVCMOS12 bank)

set_property -dict {PACKAGE_PIN BK54 IOSTANDARD LVCMOS12} [get_ports {gpio_pb[0]}]
set_property -dict {PACKAGE_PIN BL54 IOSTANDARD LVCMOS12} [get_ports {gpio_pb[1]}]
set_property -dict {PACKAGE_PIN BL55 IOSTANDARD LVCMOS12} [get_ports {gpio_pb[2]}]
set_property -dict {PACKAGE_PIN BJ55 IOSTANDARD LVCMOS12} [get_ports {gpio_pb[3]}]

set_property -dict {PACKAGE_PIN BJ52 IOSTANDARD LVCMOS12} [get_ports {gpio_dip[0]}]
set_property -dict {PACKAGE_PIN BH52 IOSTANDARD LVCMOS12} [get_ports {gpio_dip[1]}]
set_property -dict {PACKAGE_PIN BL52 IOSTANDARD LVCMOS12} [get_ports {gpio_dip[2]}]
set_property -dict {PACKAGE_PIN BK53 IOSTANDARD LVCMOS12} [get_ports {gpio_dip[3]}]

set_property -dict {PACKAGE_PIN BK56 IOSTANDARD LVCMOS12} [get_ports {gpio_led[0]}]
set_property -dict {PACKAGE_PIN BL57 IOSTANDARD LVCMOS12} [get_ports {gpio_led[1]}]
set_property -dict {PACKAGE_PIN BK57 IOSTANDARD LVCMOS12} [get_ports {gpio_led[2]}]
set_property -dict {PACKAGE_PIN BJ58 IOSTANDARD LVCMOS12} [get_ports {gpio_led[3]}]
set_property -dict {PACKAGE_PIN BH57 IOSTANDARD LVCMOS12} [get_ports {gpio_led[4]}]
set_property -dict {PACKAGE_PIN BH58 IOSTANDARD LVCMOS12} [get_ports {gpio_led[5]}]
set_property -dict {PACKAGE_PIN BG56 IOSTANDARD LVCMOS12} [get_ports {gpio_led[6]}]
set_property -dict {PACKAGE_PIN BG57 IOSTANDARD LVCMOS12} [get_ports {gpio_led[7]}]

# Pushbuttons and DIP switches are asynchronous and go through
# synchronizers; LED outputs are static display signals.
set_false_path -from [get_ports {gpio_pb[*] gpio_dip[*]}]
set_false_path -to   [get_ports {gpio_led[*]}]

# Vivado issues a warning about set_false_path for ports that don't have
# an assigned input/output delay, so create a fake virtual clock. This
# is purely to quiet the warning and has no functional effect.
create_clock -name vclk_gpio -period 10
set_input_delay  0 -clock vclk_gpio [get_ports {gpio_pb[*] gpio_dip[*]}]
set_output_delay 0 -clock vclk_gpio [get_ports {gpio_led[*]}]

