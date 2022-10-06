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

# ########################################################################
# DDR
#
#tempset_property PACKAGE_PIN AN40 [get_ports {CH0_DDR4_0_dqs_t[4]}]
#tempset_property PACKAGE_PIN AP40 [get_ports {CH0_DDR4_0_dqs_c[4]}]
#tempset_property PACKAGE_PIN AT39 [get_ports {CH0_DDR4_0_dq[39]}]
#temp
#tempset_property PACKAGE_PIN AR41 [get_ports {CH0_DDR4_0_dq[38]}]
#temp
#temp
#tempset_property PACKAGE_PIN AP34 [get_ports {CH0_DDR4_0_dqs_t[5]}]
#tempset_property PACKAGE_PIN AP33 [get_ports {CH0_DDR4_0_dqs_c[5]}]
#temp
#tempset_property PACKAGE_PIN AR32 [get_ports {CH0_DDR4_0_dq[43]}]
#temp
#tempset_property PACKAGE_PIN AR35 [get_ports {CH0_DDR4_0_dq[42]}]
#temp
#tempset_property PACKAGE_PIN AP31 [get_ports {CH0_DDR4_0_dq[41]}]
#temp
#tempset_property PACKAGE_PIN AT34 [get_ports {CH0_DDR4_0_dq[40]}]
#temp
#tempset_property PACKAGE_PIN AT33 [get_ports {CH0_DDR4_0_dm_n[5]}]
#temp
#temp#set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_dqs_c[14]"] ;# Bank 703 VCCO - VCC1V2_DDR4 - IO_L9N_GC_XCC_N3P1_M1P19_703
#temp#
#tempset_property PACKAGE_PIN AP38 [get_ports {CH0_DDR4_0_dq[35]}]
#temp
#tempset_property PACKAGE_PIN AR31 [get_ports {CH0_DDR4_0_dq[45]}]
#temp
#tempset_property PACKAGE_PIN AT35 [get_ports {CH0_DDR4_0_dq[44]}]
#temp
#tempset_property PACKAGE_PIN AT31 [get_ports {CH0_DDR4_0_dq[47]}]
#temp
#tempset_property PACKAGE_PIN AP35 [get_ports {CH0_DDR4_0_dq[46]}]
#temp
#temp
#tempset_property PACKAGE_PIN AV41 [get_ports {CH0_DDR4_0_dqs_t[6]}]
#tempset_property PACKAGE_PIN AW42 [get_ports {CH0_DDR4_0_dqs_c[6]}]
#temp
#tempset_property PACKAGE_PIN AT42 [get_ports {CH0_DDR4_0_dq[51]}]
#temp
#tempset_property PACKAGE_PIN AY42 [get_ports {CH0_DDR4_0_dq[50]}]
#temp
#tempset_property PACKAGE_PIN AU41 [get_ports {CH0_DDR4_0_dq[49]}]
#temp
#tempset_property PACKAGE_PIN BA41 [get_ports {CH0_DDR4_0_dq[48]}]
#temp
#tempset_property PACKAGE_PIN AP39 [get_ports {CH0_DDR4_0_dq[34]}]
#temp
#tempset_property PACKAGE_PIN AY40 [get_ports {CH0_DDR4_0_dm_n[6]}]
#temp
#temp# set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_dqs_c[15]"] ;# Bank 703 VCCO - VCC1V2_DDR4 - IO_L15N_XCC_N5P1_M1P31_703
#temp#
#tempset_property PACKAGE_PIN BB40 [get_ports {CH0_DDR4_0_dq[52]}]
#temp
#tempset_property PACKAGE_PIN AT41 [get_ports {CH0_DDR4_0_dq[53]}]
#temp
#tempset_property PACKAGE_PIN AV42 [get_ports {CH0_DDR4_0_dq[55]}]
#temp
#tempset_property PACKAGE_PIN AY41 [get_ports {CH0_DDR4_0_dq[54]}]
#temp
#temp
#tempset_property PACKAGE_PIN AY39 [get_ports {CH0_DDR4_0_dqs_t[7]}]
#tempset_property PACKAGE_PIN AW38 [get_ports {CH0_DDR4_0_dqs_c[7]}]
#temp
#tempset_property PACKAGE_PIN AU38 [get_ports {CH0_DDR4_0_dq[59]}]
#temp
#tempset_property PACKAGE_PIN BA39 [get_ports {CH0_DDR4_0_dq[58]}]
#temp
#tempset_property PACKAGE_PIN AN38 [get_ports {CH0_DDR4_0_dq[33]}]
#temp
#tempset_property PACKAGE_PIN BA38 [get_ports {CH0_DDR4_0_dq[56]}]
#temp
#tempset_property PACKAGE_PIN AU39 [get_ports {CH0_DDR4_0_dq[57]}]
#temp
#tempset_property PACKAGE_PIN AV38 [get_ports {CH0_DDR4_0_dm_n[7]}]
#temp
#temp# set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_dqs_c[16]"] ;# Bank 703 VCCO - VCC1V2_DDR4 - IO_L21N_XCC_N7P1_M1P43_703
#temp#
#tempset_property PACKAGE_PIN BB38 [get_ports {CH0_DDR4_0_dq[60]}]
#temp
#tempset_property PACKAGE_PIN AU40 [get_ports {CH0_DDR4_0_dq[61]}]
#temp
#tempset_property PACKAGE_PIN AV40 [get_ports {CH0_DDR4_0_dq[63]}]
#temp
#tempset_property PACKAGE_PIN BB39 [get_ports {CH0_DDR4_0_dq[62]}]
#temp
#temp
#tempset_property PACKAGE_PIN AN35 [get_ports SYS_CLK0_IN_0_clk_p]
#tempset_property PACKAGE_PIN AN36 [get_ports SYS_CLK0_IN_0_clk_n]
#temp
#tempset_property PACKAGE_PIN AR42 [get_ports {CH0_DDR4_0_dq[32]}]
#temp
#tempset_property PACKAGE_PIN AL37 [get_ports CH0_DDR4_0_reset_n]
#temp
#tempset_property DRIVE 8 [get_ports CH0_DDR4_0_reset_n]
#temp#set_property PACKAGE_PIN AM37 [get_ports {CH0_DDR4_0_alert_n[0]}]
#temp#
#tempset_property PACKAGE_PIN AP42 [get_ports {CH0_DDR4_0_dm_n[4]}]
#temp
#temp#set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_dqs_c[13]"] ;# Bank 703 VCCO - VCC1V2_DDR4 - IO_L3N_XCC_N1P1_M1P7_703
#temp#
#tempset_property PACKAGE_PIN AR39 [get_ports {CH0_DDR4_0_dq[37]}]
#temp
#tempset_property PACKAGE_PIN AR40 [get_ports {CH0_DDR4_0_dq[36]}]
#temp
#temp#set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_odt[1]"] ;# Bank 704 VCCO - VCC1V2_DDR4 - IO_L0N_XCC_N0P1_M1P55_704
#temp#
#temp# set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_adr[17]"] ;# Bank 704 VCCO - VCC1V2_DDR4 - IO_L5P_N1P4_M1P64_704
#temp#
#tempset_property PACKAGE_PIN AD37 [get_ports {CH0_DDR4_0_adr[8]}]
#temp
#temp
#tempset_property PACKAGE_PIN AH34 [get_ports {CH0_DDR4_0_ck_t[0]}]
#tempset_property PACKAGE_PIN AG35 [get_ports {CH0_DDR4_0_ck_c[0]}]
#temp
#tempset_property PACKAGE_PIN AG38 [get_ports {CH0_DDR4_0_adr[7]}]
#temp
#tempset_property PACKAGE_PIN AE32 [get_ports {CH0_DDR4_0_adr[9]}]
#temp
#tempset_property PACKAGE_PIN AE34 [get_ports {CH0_DDR4_0_adr[1]}]
#temp
#temp#Remove - single bank group set_property PACKAGE_PIN <NONE> [get_ports {CH0_DDR4_0_bg[1]}]
#temp
#tempset_property PACKAGE_PIN AH32 [get_ports CH0_DDR4_0_act_n]
#temp
#tempset_property PACKAGE_PIN AG33 [get_ports {CH0_DDR4_0_adr[0]}]
#temp
#tempset_property PACKAGE_PIN AF37 [get_ports {CH0_DDR4_0_adr[13]}]
#temp
#temp#
#temp#set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_cke[1]"] ;# Bank 704 VCCO - VCC1V2_DDR4 - IO_L10N_N3P3_M1P75_704
#temp#
#tempset_property PACKAGE_PIN AD34 [get_ports {CH0_DDR4_0_adr[2]}]
#temp
#tempset_property PACKAGE_PIN AF32 [get_ports {CH0_DDR4_0_cke[0]}]
#temp
#tempset_property PACKAGE_PIN AH35 [get_ports {CH0_DDR4_0_adr[15]}]
#temp
#tempset_property PACKAGE_PIN AE36 [get_ports {CH0_DDR4_0_adr[11]}]
#temp
#tempset_property PACKAGE_PIN AF35 [get_ports {CH0_DDR4_0_adr[4]}]
#temp
#tempset_property PACKAGE_PIN AJ33 [get_ports {CH0_DDR4_0_adr[3]}]
#temp
#tempset_property PACKAGE_PIN AF34 [get_ports {CH0_DDR4_0_ba[1]}]
#temp
#tempset_property PACKAGE_PIN AK35 [get_ports {CH0_DDR4_0_adr[14]}]
#temp
#tempset_property PACKAGE_PIN AF33 [get_ports {CH0_DDR4_0_odt[0]}]
#temp
#temp#set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_cs_n[1]"] ;# Bank 704 VCCO - VCC1V2_DDR4 - IO_L16N_N5P3_M1P87_704
#temp#
#tempset_property PACKAGE_PIN AH36 [get_ports {CH0_DDR4_0_adr[5]}]
#temp
#tempset_property PACKAGE_PIN AF36 [get_ports {CH0_DDR4_0_adr[6]}]
#temp
#temp
#tempset_property PACKAGE_PIN AK39 [get_ports {CH0_DDR4_0_dqs_t[3]}]
#tempset_property PACKAGE_PIN AK40 [get_ports {CH0_DDR4_0_dqs_c[3]}]
#temp
#tempset_property PACKAGE_PIN AL41 [get_ports {CH0_DDR4_0_dq[24]}]
#temp
#tempset_property PACKAGE_PIN AL38 [get_ports {CH0_DDR4_0_dq[25]}]
#temp
#temp#set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_cs_n[3]"] ;# Bank 704 VCCO - VCC1V2_DDR4 - IO_L2P_N0P4_M1P58_704
#temp#
#tempset_property PACKAGE_PIN AM41 [get_ports {CH0_DDR4_0_dq[26]}]
#temp
#tempset_property PACKAGE_PIN AK41 [get_ports {CH0_DDR4_0_dq[27]}]
#temp
#tempset_property PACKAGE_PIN AM40 [get_ports {CH0_DDR4_0_dm_n[3]}]
#temp
#temp# set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_dqs_c[12]"] ;# Bank 704 VCCO - VCC1V2_DDR4 - IO_L21N_XCC_N7P1_M1P97_704
#temp#
#tempset_property PACKAGE_PIN AM39 [get_ports {CH0_DDR4_0_dq[28]}]
#temp
#tempset_property PACKAGE_PIN AM38 [get_ports {CH0_DDR4_0_dq[29]}]
#temp
#tempset_property PACKAGE_PIN AL42 [get_ports {CH0_DDR4_0_dq[30]}]
#temp
#tempset_property PACKAGE_PIN AL39 [get_ports {CH0_DDR4_0_dq[31]}]
#temp
#temp#set_property PACKAGE_PIN AD36 [get_ports {CH0_DDR4_0_par[0]}]
#temp#
#tempset_property PACKAGE_PIN AK33 [get_ports {CH0_DDR4_0_ba[0]}]
#temp
#temp#set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_cs_n[2]"] ;# Bank 704 VCCO - VCC1V2_DDR4 - IO_L2N_N0P5_M1P59_704
#temp#
#tempset_property PACKAGE_PIN AJ31 [get_ports {CH0_DDR4_0_adr[10]}]
#temp
#tempset_property PACKAGE_PIN AG40 [get_ports {CH0_DDR4_0_adr[12]}]
#temp
#tempset_property PACKAGE_PIN AK32 [get_ports {CH0_DDR4_0_bg[0]}]
#temp
#temp#set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_ck_t[1]"] ;# Bank 704 VCCO - VCC1V2_DDR4 - IO_L3P_XCC_N1P0_M1P60_704
#temp#
#temp#set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_ck_c[1]"] ;# Bank 704 VCCO - VCC1V2_DDR4 - IO_L3N_XCC_N1P1_M1P61_704
#temp#
#tempset_property PACKAGE_PIN AJ34 [get_ports {CH0_DDR4_0_cs_n[0]}]
#temp
#tempset_property PACKAGE_PIN AE33 [get_ports {CH0_DDR4_0_adr[16]}]
#temp
#temp#
#temp#set_property PACKAGE_PIN AY35 [get_ports {CH0_DDR4_0_dqs_t[8]}]
#temp#set_property PACKAGE_PIN AY34 [get_ports {CH0_DDR4_0_dqs_c[8]}]
#temp#
#temp#set_property PACKAGE_PIN AV33 [get_ports {CH0_DDR4_0_dq[71]}]
#temp#
#temp#set_property PACKAGE_PIN BB35 [get_ports {CH0_DDR4_0_dq[70]}]
#temp#
#temp
#tempset_property PACKAGE_PIN AL35 [get_ports {CH0_DDR4_0_dqs_t[2]}]
#tempset_property PACKAGE_PIN AM34 [get_ports {CH0_DDR4_0_dqs_c[2]}]
#temp
#tempset_property PACKAGE_PIN AL31 [get_ports {CH0_DDR4_0_dq[19]}]
#temp
#tempset_property PACKAGE_PIN AM36 [get_ports {CH0_DDR4_0_dq[18]}]
#temp
#tempset_property PACKAGE_PIN AM31 [get_ports {CH0_DDR4_0_dq[17]}]
#temp
#tempset_property PACKAGE_PIN AN32 [get_ports {CH0_DDR4_0_dq[16]}]
#temp
#tempset_property PACKAGE_PIN AL32 [get_ports {CH0_DDR4_0_dm_n[2]}]
#temp
#temp# set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_dqs_c[11]"] ;# Bank 705 VCCO - VCC1V2_DDR4 - IO_L9N_GC_XCC_N3P1_M1P127_705
#temp#
#temp#set_property PACKAGE_PIN AV35 [get_ports {CH0_DDR4_0_dq[67]}]
#temp#
#tempset_property PACKAGE_PIN AN31 [get_ports {CH0_DDR4_0_dq[20]}]
#temp
#tempset_property PACKAGE_PIN AM30 [get_ports {CH0_DDR4_0_dq[21]}]
#temp
#tempset_property PACKAGE_PIN AN33 [get_ports {CH0_DDR4_0_dq[23]}]
#temp
#tempset_property PACKAGE_PIN AM35 [get_ports {CH0_DDR4_0_dq[22]}]
#temp
#temp
#tempset_property PACKAGE_PIN AH42 [get_ports {CH0_DDR4_0_dqs_t[1]}]
#tempset_property PACKAGE_PIN AG41 [get_ports {CH0_DDR4_0_dqs_c[1]}]
#temp
#tempset_property PACKAGE_PIN AH40 [get_ports {CH0_DDR4_0_dq[10]}]
#temp
#tempset_property PACKAGE_PIN AF42 [get_ports {CH0_DDR4_0_dq[11]}]
#temp
#tempset_property PACKAGE_PIN AJ42 [get_ports {CH0_DDR4_0_dq[8]}]
#temp
#tempset_property PACKAGE_PIN AE42 [get_ports {CH0_DDR4_0_dq[9]}]
#temp
#temp#set_property PACKAGE_PIN BA34 [get_ports {CH0_DDR4_0_dq[66]}]
#temp#
#tempset_property PACKAGE_PIN AF41 [get_ports {CH0_DDR4_0_dm_n[1]}]
#temp
#temp# set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_dqs_c[10]"] ;# Bank 705 VCCO - VCC1V2_DDR4 - IO_L15N_XCC_N5P1_M1P139_705
#temp#
#tempset_property PACKAGE_PIN AE41 [get_ports {CH0_DDR4_0_dq[13]}]
#temp
#tempset_property PACKAGE_PIN AK42 [get_ports {CH0_DDR4_0_dq[12]}]
#temp
#tempset_property PACKAGE_PIN AE40 [get_ports {CH0_DDR4_0_dq[15]}]
#temp
#tempset_property PACKAGE_PIN AH41 [get_ports {CH0_DDR4_0_dq[14]}]
#temp
#temp
#tempset_property PACKAGE_PIN AH38 [get_ports {CH0_DDR4_0_dqs_t[0]}]
#tempset_property PACKAGE_PIN AG39 [get_ports {CH0_DDR4_0_dqs_c[0]}]
#temp
#tempset_property PACKAGE_PIN AE39 [get_ports {CH0_DDR4_0_dq[3]}]
#temp
#tempset_property PACKAGE_PIN AJ38 [get_ports {CH0_DDR4_0_dq[2]}]
#temp
#temp#set_property PACKAGE_PIN BB34 [get_ports {CH0_DDR4_0_dq[64]}]
#temp#
#tempset_property PACKAGE_PIN AJ39 [get_ports {CH0_DDR4_0_dq[0]}]
#temp
#tempset_property PACKAGE_PIN AF38 [get_ports {CH0_DDR4_0_dq[1]}]
#temp
#tempset_property PACKAGE_PIN AF39 [get_ports {CH0_DDR4_0_dm_n[0]}]
#temp
#temp# set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_dqs_c[9]"] ;# Bank 705 VCCO - VCC1V2_DDR4 - IO_L21N_XCC_N7P1_M1P151_705
#temp#
#tempset_property PACKAGE_PIN AK37 [get_ports {CH0_DDR4_0_dq[4]}]
#temp
#tempset_property PACKAGE_PIN AD39 [get_ports {CH0_DDR4_0_dq[5]}]
#temp
#tempset_property PACKAGE_PIN AD38 [get_ports {CH0_DDR4_0_dq[7]}]
#temp
#tempset_property PACKAGE_PIN AJ40 [get_ports {CH0_DDR4_0_dq[6]}]
#temp
#temp#set_property PACKAGE_PIN AU33 [get_ports {CH0_DDR4_0_dq[65]}]
#temp#
#temp#set_property PACKAGE_PIN AW34 [get_ports {CH0_DDR4_0_dm_n[8]}]
#temp#
#temp# set_property PACKAGE_PIN <NONE>     [get_ports "CH0_DDR4_0_dqs_c[17]"] ;# Bank 705 VCCO - VCC1V2_DDR4 - IO_L3N_XCC_N1P1_M1P115_705
#temp#
#temp#set_property PACKAGE_PIN BA33 [get_ports {CH0_DDR4_0_dq[68]}]
#temp#
#temp#set_property PACKAGE_PIN AU35 [get_ports {CH0_DDR4_0_dq[69]}]
#temp#
#temp
#set_property PACKAGE_PIN AN35 [get_ports SYS_CLK0_IN_0_clk_p]
#set_property PACKAGE_PIN AN36 [get_ports SYS_CLK0_IN_0_clk_n]
#
#create_clock -period 5.000 -name sys_clk0_0_clk_p [get_ports SYS_CLK0_IN_0_clk_p]

#set_clock_uncertainty -hold 0.050 [get_clocks]
set_property PACKAGE_PIN AK8 [get_ports CLK_IN1_D_0_clk_p]
set_property PACKAGE_PIN AK7 [get_ports CLK_IN1_D_0_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports CLK_IN1_D_0_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports CLK_IN1_D_0_clk_n]

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
