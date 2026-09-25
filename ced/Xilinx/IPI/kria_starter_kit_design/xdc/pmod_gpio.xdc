# Copyright (C) 2022, Xilinx, Inc. 
# Copyright (C) 2022, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: Apache-2.0

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

#Fan Speed Enable
set_property PACKAGE_PIN A12 [get_ports {fan_en_b}]
set_property IOSTANDARD LVCMOS33 [get_ports {fan_en_b}]
set_property SLEW SLOW [get_ports {fan_en_b}]
set_property DRIVE 4 [get_ports {fan_en_b}]

#PMOD GPIO pin locks
set_property PACKAGE_PIN H12 [get_ports {pmod_gpio_tri_io[7]}]
set_property PACKAGE_PIN E10 [get_ports {pmod_gpio_tri_io[6]}]
set_property PACKAGE_PIN D10 [get_ports {pmod_gpio_tri_io[5]}]
set_property PACKAGE_PIN C11 [get_ports {pmod_gpio_tri_io[4]}]
set_property PACKAGE_PIN B10 [get_ports {pmod_gpio_tri_io[3]}]
set_property PACKAGE_PIN E12 [get_ports {pmod_gpio_tri_io[2]}]
set_property PACKAGE_PIN D11 [get_ports {pmod_gpio_tri_io[1]}]
set_property PACKAGE_PIN B11 [get_ports {pmod_gpio_tri_io[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_gpio_tri_io[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_gpio_tri_io[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_gpio_tri_io[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_gpio_tri_io[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_gpio_tri_io[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_gpio_tri_io[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_gpio_tri_io[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmod_gpio_tri_io[7]}]