#create_property PF0_PL32_CAP_NEXTPTR cell -type string
# create_property PF0_CLASS_CODE cell -type string
###############################################################################
# User Time Names / User Time Groups / Time Specs
###############################################################################
create_clock -period 10.000 -name sys_clk_usp [get_ports {usp_pcie_refclk_clk_p}]
#create_clock -period 10.000 -name sys_clk_gt_usp [get_pins {gen_ext_pipe_sim_usp.switch_usp/refclk_ibuf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5[0].IBUFDS_GTE5_I/O}]

set_property PACKAGE_PIN T31 [get_ports sys_rst]
set_property PACKAGE_PIN K35 [get_ports sys_rst_o]

set_property IOSTANDARD LVCMOS15 [get_ports sys_rst]
set_property IOSTANDARD LVCMOS15 [get_ports sys_rst_o]

set_property PULLTYPE PULLUP [get_ports sys_rst]
set_false_path -from [get_ports sys_rst]

set_property LOC GTYP_REFCLK_X1Y0 [get_cells -hierarchical -filter {REF_NAME==IBUFDS_GTE5 && NAME=~ *switch_usp*}]
set_property LOC GTYP_QUAD_X1Y0 [get_cells -hierarchical -filter { PRIMITIVE_SUBGROUP==GT && NAME =~ *switch_usp*gt_quad_0*}]

set_property PACKAGE_PIN T33 [get_ports led_0]
set_property PACKAGE_PIN U33 [get_ports led_1]
set_property PACKAGE_PIN U37 [get_ports led_2]
set_property PACKAGE_PIN V37 [get_ports led_3]
set_property IOSTANDARD LVCMOS15 [get_ports led_*]
set_false_path -to [get_ports led_*]

set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~DIV[0]} -of_objects [get_cells -hierarchical bufg_gt_pclk -filter NAME=~*switch_usp/*]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~DIV[1]} -of_objects [get_cells -hierarchical bufg_gt_pclk -filter NAME=~*switch_usp/*]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~DIV[2]} -of_objects [get_cells -hierarchical bufg_gt_pclk -filter NAME=~*switch_usp/*]]

set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~DIV[0]} -of_objects [get_cells -hierarchical bufg_gt_coreclk -filter NAME=~*switch_usp/*]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~DIV[1]} -of_objects [get_cells -hierarchical bufg_gt_coreclk -filter NAME=~*switch_usp/*]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~DIV[2]} -of_objects [get_cells -hierarchical bufg_gt_coreclk -filter NAME=~*switch_usp/*]]

set_case_analysis 1 [get_pins -filter {REF_PIN_NAME=~DIV[0]} -of_objects [get_cells -hierarchical bufg_gt_userclk -filter NAME=~*switch_usp/*]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~DIV[1]} -of_objects [get_cells -hierarchical bufg_gt_userclk -filter NAME=~*switch_usp/*]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~DIV[2]} -of_objects [get_cells -hierarchical bufg_gt_userclk -filter NAME=~*switch_usp/*]]

set_false_path -through [get_pins -filter REF_PIN_NAME=~*RXELECIDLE -of_objects [get_cells -hierarchical -filter PRIMITIVE_SUBGROUP==GT]]
set_false_path -through [get_pins -filter REF_PIN_NAME=~*XRATE* -of_objects [get_cells -hierarchical -filter PRIMITIVE_SUBGROUP==GT]]
set_false_path -through [get_pins -filter REF_PIN_NAME=~GTPOWERGOOD -of_objects [get_cells -hierarchical -filter PRIMITIVE_SUBGROUP==GT]]

set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.GENERAL.WRITE0FRAMES No [current_design]
set_property BITSTREAM.GENERAL.PROCESSALLVEAMS true [current_design]

set_clock_groups -name async0 -asynchronous -group [get_clocks {sys_clk_usp }] -group [get_clocks GT_REFCLK0]

set_clock_groups -name async1 -asynchronous -group [get_clocks {sys_clk_usp }] -group [list [get_clocks -of [get_pins {gen_ext_pipe_sim_usp.switch_usp/pcie_phy/inst/diablo_gt_phy_wrapper/gt_top_i/diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_pclk/O gen_ext_pipe_sim_usp.switch_usp/pcie_phy/inst/diablo_gt_phy_wrapper/gt_top_i/diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O}]] [get_clocks ch0_txoutclk]]





# set_property PL_DISABLE_LANE_REVERSAL FALSE [get_cells gen_ext_pipe_sim_usp.switch_usp/pcie_versal_0/inst/serial_pcie_top.pcie_5_0_pipe_inst/pcie_5_0_e5_inst]
# set_property PF0_CLASS_CODE 24'h060400 [get_cells gen_ext_pipe_sim_usp.switch_usp/pcie_versal_0/inst/serial_pcie_top.pcie_5_0_pipe_inst/pcie_5_0_e5_inst]




#set_property PF0_PL32_CAP_NEXTPTR 12'h000 [get_cells gen_ext_pipe_sim_usp.switch_usp/pcie_versal_0/inst/serial_pcie_top.pcie_5_0_pipe_inst/pcie_5_0_e5_inst]









#create_property AXISTEN_IF_ENABLE_TAGS cell -type string
#set_property AXISTEN_IF_ENABLE_TAGS 2'h2 [get_cells gen_ext_pipe_sim_usp.switch_usp/pcie_versal_0/inst/serial_pcie_top.pcie_5_0_pipe_inst/pcie_5_0_e5_inst]
