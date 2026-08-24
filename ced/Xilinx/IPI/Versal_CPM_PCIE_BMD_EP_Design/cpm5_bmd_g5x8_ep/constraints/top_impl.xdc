# Set bitstream properties
set_property CONFIG_VOLTAGE 1.8 [current_design]
# Enable bitstream compression
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]

#set_clock_uncertainty -hold 1.000 [get_clocks pcie0_user_clk]

#set_clock_uncertainty -1.000 [get_clocks pcie0_user_clk]
#set_clock_uncertainty -hold 0.200 [get_clocks pcie0_user_clk]
#create_generated_clock -name DIVOUT_forced_freq --source [get_pins design_1_i/versal_cips_0/inst/cpm_0/inst/CPM_INST/IFBUFGTQ0CLKBUFGT[1]] -master_clock [get_clocks ch0_txoutclk] [get_pins design_1_i/versal_cips_0/inst/cpm_0/inst/CPM_INST/CPM5DPLL0INT_DIVOUT]
#create_generated_clock -name DIVOUT_forced_freq -divide_by 4 -source [get_pins design_1_i/versal_cips_0/inst/cpm_0/inst/CPM_INST/IFBUFGTQ0CLKBUFGT[1]] -master_clock [get_clocks ch0_txoutclk] -add [get_pins design_1_i/versal_cips_0/inst/cpm_0/inst/CPM_INST/CPM5DPLL0INT_DIVOUT]
#create_clock -name DIVOUT_CLK_forced -period 4.000 [get_pins design_1_i/versal_cips_0/inst/cpm_0/inst/CPM_INST/CPM5DPLL0INT_DIVOUT]


















