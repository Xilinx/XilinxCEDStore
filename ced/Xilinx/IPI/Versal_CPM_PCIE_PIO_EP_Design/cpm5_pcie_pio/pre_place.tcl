# These constraints are currently missing in the IP and should be integrated into the IP. 
# These are needed for write_device_image to work properly.
#set_property HD.TANDEM 1 [get_cells design_1_i/versal_cips_0/inst/IBUFDS_GTE5_inst]
##set_property -quiet HD.TANDEM 1 [get_cells -hierarchical -filter {PRIMITIVE_TYPE == I/O.INPUT_BUFFER.IBUFDS_GTE5}]

# Enable the Deskew logic in the DPLL so that designs with PCIE-A-to-PL connection can meet timing better
#set_property CLKOUT0_PHASE_CTRL 2'b01 [get_cells design_1_wrapper_i/design_1_i/versal_cips_0/inst/DPLL_PCIE0_inst]
#set_property CLKOUT0_PHASE_CTRL 2'b01 [get_cells get_cells */*/*/DPLL_PCIE*inst]

# Add hold time constraint to improve place and route result
#set_clock_uncertainty -hold 0.200 [get_clocks]

# Set clock root contraint
#set_property USER_CLOCK_ROOT X0Y2 [get_nets -of [get_pins design_1_i/versal_cips_0/inst/bufg_pcie_0/O]]

# set clock uncertainty for PL paths
##set_clock_uncertainty -hold 0.050 -from [get_clocks -of_objects [get_pins design_1_i/versal_cips_0/inst/DPLL_PCIE0_inst/CLKOUT0]] \
                                     -to [get_clocks -of_objects [get_pins design_1_i/versal_cips_0/inst/DPLL_PCIE0_inst/CLKOUT0]]

# Additional Skew delay and LOC constraint
##set_property DESKEW_DELAY_EN TRUE [get_cells design_1_i/versal_cips_0/inst/DPLL_PCIE0_inst]
##set_property DESKEW_DELAY_PATH TRUE [get_cells design_1_i/versal_cips_0/inst/DPLL_PCIE0_inst]
##set_property DESKEW_DELAY 4 [get_cells design_1_i/versal_cips_0/inst/DPLL_PCIE0_inst]
##set_property LOC DPLL_X1Y4 [get_cells design_1_i/versal_cips_0/inst/DPLL_PCIE0_inst]
