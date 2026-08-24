





#MIPI2
#LA29_N	MIPI2_D1N
#LA29_P	MIPI2_D1P
#LA33_N	MIPI2_D2N
#LA33_P	MIPI2_D2P
#LA32_N	MIPI2_D3N
#LA32_P	MIPI2_D3P
#LA31_N	MIPI2_CLKN
#LA31_P	MIPI2_CLKP
#LA30_N	MIPI2_D0N
#LA30_P	MIPI2_D0P

#CLK
#set_property PACKAGE_PIN AL42     [get_ports "FMCP1_LA31_P"] ;# Bank 713 VCCO - VADJ_FMC - IO_L25P_XCC_H1O2P2_M3P114_713
#set_property PACKAGE_PIN AM43     [get_ports "FMCP1_LA31_N"] ;# Bank 713 VCCO - VADJ_FMC - IO_L25N_XCC_H1O2P3_M3P115_713
set_property PACKAGE_PIN AL42     [get_ports "MIPI2_clk_p"]
set_property PACKAGE_PIN AM43     [get_ports "MIPI2_clk_n"]

#D0
#set_property PACKAGE_PIN AM41     [get_ports "FMCP1_LA30_P"] ;# Bank 713 VCCO - VADJ_FMC - IO_L24P_H1O2P0_M3P112_713
#set_property PACKAGE_PIN AL41     [get_ports "FMCP1_LA30_N"] ;# Bank 713 VCCO - VADJ_FMC - IO_L24N_H1O2P1_M3P113_713
set_property PACKAGE_PIN AM41     [get_ports "MIPI2_data_p[0]"]
set_property PACKAGE_PIN AL41     [get_ports "MIPI2_data_n[0]"]

#D1
#set_property PACKAGE_PIN AM44     [get_ports "FMCP1_LA29_P"] ;# Bank 713 VCCO - VADJ_FMC - IO_L28P_H1O3P0_M3P120_713
#set_property PACKAGE_PIN AL44     [get_ports "FMCP1_LA29_N"] ;# Bank 713 VCCO - VADJ_FMC - IO_L28N_H1O3P1_M3P121_713
set_property PACKAGE_PIN AM44     [get_ports "MIPI2_data_p[1]"]
set_property PACKAGE_PIN AL44     [get_ports "MIPI2_data_n[1]"]

#D2
#set_property PACKAGE_PIN AP44     [get_ports "FMCP1_LA33_P"] ;# Bank 713 VCCO - VADJ_FMC - IO_L27P_H1O2P6_M3P118_713
#set_property PACKAGE_PIN AP45     [get_ports "FMCP1_LA33_N"] ;# Bank 713 VCCO - VADJ_FMC - IO_L27N_H1O2P7_M3P119_713
set_property PACKAGE_PIN AP44     [get_ports "MIPI2_data_p[2]"]
set_property PACKAGE_PIN AP45     [get_ports "MIPI2_data_n[2]"]

#D3
#set_property PACKAGE_PIN AN42     [get_ports "FMCP1_LA32_P"] ;# Bank 713 VCCO - VADJ_FMC - IO_L26P_H1O2P4_M3P116_713
#set_property PACKAGE_PIN AN43     [get_ports "FMCP1_LA32_N"] ;# Bank 713 VCCO - VADJ_FMC - IO_L26N_H1O2P5_M3P117_713
set_property PACKAGE_PIN AN42     [get_ports "MIPI2_data_p[3]"]
set_property PACKAGE_PIN AN43     [get_ports "MIPI2_data_n[3]"]

set_property IOSTANDARD MIPI_DPHY [get_ports "MIPI2_*"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "MIPI2_*"]
