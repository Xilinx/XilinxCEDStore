# Set bitstream properties
set_property CONFIG_VOLTAGE 1.8 [current_design]
# Enable bitstream compression
set_property bitstream.general.compress true [current_design]

#set_property PACKAGE_PIN H34 [get_ports led_0]
#set_property PACKAGE_PIN J33 [get_ports led_1]
#set_property PACKAGE_PIN K36 [get_ports led_2]
#set_property PACKAGE_PIN L35 [get_ports led_3]

#set_property IOSTANDARD LVCMOS18 [get_ports led_0]
#set_property IOSTANDARD LVCMOS18 [get_ports led_1]
#set_property IOSTANDARD LVCMOS18 [get_ports led_2]
#set_property IOSTANDARD LVCMOS18 [get_ports led_3]


##########################################################

###create_pblock pblock_1
###add_cells_to_pblock [get_pblocks pblock_1] -top
###resize_pblock [get_pblocks pblock_1] -add {SLICE_X40Y0:SLICE_X75Y43}
###resize_pblock [get_pblocks pblock_1] -add {RAMB18_X1Y0:RAMB18_X1Y23}
###resize_pblock [get_pblocks pblock_1] -add {RAMB36_X1Y0:RAMB36_X1Y11}
###resize_pblock [get_pblocks pblock_1] -add {URAM288_X1Y0:URAM288_X1Y11}
####more than half FSR
####resize_pblock pblock_1 -add {SLICE_X40Y0:SLICE_X75Y57 RAMB18_X1Y0:RAMB18_X1Y29 RAMB36_X1Y0:RAMB36_X1Y14 URAM288_X1Y0:URAM288_X1Y14}
####half FSR
####FSR
####resize_pblock pblock_1 -add {SLICE_X28Y0:SLICE_X75Y91 RAMB18_X1Y0:RAMB18_X1Y47 RAMB36_X1Y0:RAMB36_X1Y23 URAM288_X0Y0:URAM288_X1Y23}


#set_clock_uncertainty -hold 0.200 [get_clocks clkout1_primitive]


## LED4-1 ports
##set_property PACKAGE_PIN L35 [get_ports {led[3]}]
##set_property PACKAGE_PIN K36 [get_ports {led[2]}]
##set_property PACKAGE_PIN J33 [get_ports {led[1]}]
##set_property PACKAGE_PIN H34 [get_ports {led[0]}]

## 7SEG_[DP,G-A]_B_LS
#set_property PACKAGE_PIN AC22 [get_ports seven_seg_dp_n]
#set_property PACKAGE_PIN AC23 [get_ports {seven_seg_n[6]}]
#set_property PACKAGE_PIN AA22 [get_ports {seven_seg_n[5]}]
#set_property PACKAGE_PIN AB22 [get_ports {seven_seg_n[4]}]
#set_property PACKAGE_PIN AB25 [get_ports {seven_seg_n[3]}]
#set_property PACKAGE_PIN AB26 [get_ports {seven_seg_n[2]}]
#set_property PACKAGE_PIN AA27 [get_ports {seven_seg_n[1]}]
#set_property PACKAGE_PIN AB27 [get_ports {seven_seg_n[0]}]

# All LVCMOS12 Outputs
#set_property IOSTANDARD LVCMOS12 [get_ports {led[*] seven_seg_*}]
#set_property DRIVE 8 [get_ports {led[*] seven_seg_*}]


#set_property PACKAGE_PIN G37 [get_ports axi_rst_in_0_n_0]
#set_property IOSTANDARD LVCMOS25 [get_ports axi_rst_in_0_n_0]



#set_property LOC NOC_NMU512_X0Y0 [get_cells {design_1_i/axi_noc_0/inst/S00_AXI_nmu/*_nmu_0_top_INST/NOC_NMU512_INST}]

#set_false_path -from [get_clocks clk_pl_0] -to [get_clocks clkout1_primitive] 
#set_false_path -from [get_clocks clkout1_primitive] -to [get_clocks clk_pl_0] 