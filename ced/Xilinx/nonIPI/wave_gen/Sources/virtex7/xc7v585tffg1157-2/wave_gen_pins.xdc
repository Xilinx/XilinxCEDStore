

set_property IOB TRUE [all_fanin -only_cells -startpoints_only -flat [all_outputs]]

set_property IOSTANDARD LVCMOS18 [get_ports dac_clr_n_pin]
set_property IOSTANDARD LVCMOS18 [get_ports dac_cs_n_pin]
set_property IOSTANDARD LVCMOS18 [get_ports lb_sel_pin]
set_property IOSTANDARD LVCMOS18 [get_ports {led_pins[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_pins[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_pins[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_pins[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_pins[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_pins[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_pins[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_pins[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports rst_pin]
set_property IOSTANDARD LVCMOS18 [get_ports rxd_pin]
set_property IOSTANDARD LVCMOS18 [get_ports spi_clk_pin]
set_property IOSTANDARD LVCMOS18 [get_ports spi_mosi_pin]
set_property IOSTANDARD LVCMOS18 [get_ports txd_pin]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports clk_pin_p]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports clk_pin_n]
set_property PACKAGE_PIN G22 [get_ports spi_clk_pin]
set_property PACKAGE_PIN N28 [get_ports lb_sel_pin]
set_property PACKAGE_PIN R23 [get_ports rst_pin]
set_property PACKAGE_PIN R24 [get_ports rxd_pin]
set_property PACKAGE_PIN AJ10 [get_ports clk_pin_n]
set_property PACKAGE_PIN AH10 [get_ports clk_pin_p]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

set_property PACKAGE_PIN L20 [get_ports {led_pins[7]}]
set_property PACKAGE_PIN L18 [get_ports {led_pins[1]}]
set_property PACKAGE_PIN K18 [get_ports {led_pins[6]}]
set_property PACKAGE_PIN J20 [get_ports {led_pins[4]}]
set_property PACKAGE_PIN J19 [get_ports {led_pins[5]}]
set_property PACKAGE_PIN H20 [get_ports {led_pins[3]}]
set_property PACKAGE_PIN L19 [get_ports {led_pins[0]}]
set_property PACKAGE_PIN M18 [get_ports {led_pins[2]}]
set_property LOC OLOGIC_X0Y340 [get_cells lb_ctl_i0/txd_o_reg]
set_property LOC OLOGIC_X0Y341 [get_cells dac_spi_i0/spi_mosi_o_reg]
set_property LOC OLOGIC_X0Y346 [get_cells dac_spi_i0/dac_cs_n_o_reg]
set_property LOC OLOGIC_X0Y349 [get_cells dac_spi_i0/dac_clr_n_o_reg]
set_property PACKAGE_PIN N23 [get_ports dac_clr_n_pin]
set_property PACKAGE_PIN N27 [get_ports dac_cs_n_pin]
set_property PACKAGE_PIN P25 [get_ports spi_mosi_pin]
set_property PACKAGE_PIN T24 [get_ports txd_pin]


