##**************************************************************************
##
## Icon Constraints
##
create_clock -name D_CLK -period 5.0 [get_ports gth_sysclkp_i_0]
set_clock_groups -group [get_clocks D_CLK -include_generated_clocks] -asynchronous
set_property C_CLK_INPUT_FREQ_HZ 200000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER true [get_debug_cores dbg_hub]

##gth_refclk lock constraints
##
set_property PACKAGE_PIN AA10 [get_ports gth_refclk0p_i_0[0]]
set_property PACKAGE_PIN AA9 [get_ports gth_refclk0n_i_0[0]]
set_property PACKAGE_PIN Y8 [get_ports gth_refclk1p_i_0[0]]
set_property PACKAGE_PIN Y7 [get_ports gth_refclk1n_i_0[0]]
##
## Refclk constraints
##
create_clock -name gth_refclk0_1 -period 6.4 [get_ports gth_refclk0p_i_0[0]]
create_clock -name gth_refclk1_1 -period 6.4 [get_ports gth_refclk1p_i_0[0]]
set_clock_groups -group [get_clocks gth_refclk0_1 -include_generated_clocks] -asynchronous
set_clock_groups -group [get_clocks gth_refclk1_1 -include_generated_clocks] -asynchronous
##
## System clock pin locs and timing constraints
##
set_property PACKAGE_PIN V28 [get_ports gth_sysclkp_i_0]
set_property IOSTANDARD LVDS [get_ports gth_sysclkp_i_0]
