






#MIPI6
#LA17_N_CC MIPI6_D0N
#LA17_P_CC MIPI6_D0P
#LA25_N    MIPI6_D3P
#LA25_P    MIPI6_D3N
#LA24_N    MIPI6_D2P
#LA24_P    MIPI6_D2N
#LA18_N_CC MIPI6_CLKN
#LA18_P_CC MIPI6_CLKP
#LA23_N    MIPI6_D1N
#LA23_P    MIPI6_D1P

#CLK

#set_property PACKAGE_PIN BD22     [get_ports "FMCP1_LA18_CC_P"] ;# Bank 707 VCCO - VADJ_FMC - IO_L25P_XCC_H1O2P2_707
#set_property PACKAGE_PIN BD23     [get_ports "FMCP1_LA18_CC_N"] ;# Bank 707 VCCO - VADJ_FMC - IO_L25N_XCC_H1O2P3_707

set_property PACKAGE_PIN BD22     [get_ports "MIPI6_clk_p"]
set_property PACKAGE_PIN BD23     [get_ports "MIPI6_clk_n"]

#D0

#set_property PACKAGE_PIN BF20     [get_ports "FMCP1_LA17_CC_P"] ;# Bank 707 VCCO - VADJ_FMC - IO_L28P_H1O3P0_707
#set_property PACKAGE_PIN BF21     [get_ports "FMCP1_LA17_CC_N"] ;# Bank 707 VCCO - VADJ_FMC - IO_L28N_H1O3P1_707

set_property PACKAGE_PIN BF20     [get_ports "MIPI6_data_p[0]"]
set_property PACKAGE_PIN BF21     [get_ports "MIPI6_data_n[0]"]

#D1

#set_property PACKAGE_PIN BC23     [get_ports "FMCP1_LA23_P"] ;# Bank 707 VCCO - VADJ_FMC - IO_L24P_H1O2P0_707
#set_property PACKAGE_PIN BC24     [get_ports "FMCP1_LA23_N"] ;# Bank 707 VCCO - VADJ_FMC - IO_L24N_H1O2P1_707

set_property PACKAGE_PIN BC23     [get_ports "MIPI6_data_p[1]"]
set_property PACKAGE_PIN BC24     [get_ports "MIPI6_data_n[1]"]

#D2

#set_property PACKAGE_PIN BD19     [get_ports "FMCP1_LA24_P"] ;# Bank 707 VCCO - VADJ_FMC - IO_L26P_H1O2P4_707
#set_property PACKAGE_PIN BD20     [get_ports "FMCP1_LA24_N"] ;# Bank 707 VCCO - VADJ_FMC - IO_L26N_H1O2P5_707

set_property PACKAGE_PIN BD19     [get_ports "MIPI6_data_p[2]"]
set_property PACKAGE_PIN BD20     [get_ports "MIPI6_data_n[2]"]

#D3

#set_property PACKAGE_PIN BE19     [get_ports "FMCP1_LA25_P"] ;# Bank 707 VCCO - VADJ_FMC - IO_L27P_H1O2P6_707
#set_property PACKAGE_PIN BF19     [get_ports "FMCP1_LA25_N"] ;# Bank 707 VCCO - VADJ_FMC - IO_L27N_H1O2P7_707

set_property PACKAGE_PIN BE19     [get_ports "MIPI6_data_p[3]"]
set_property PACKAGE_PIN BF19     [get_ports "MIPI6_data_n[3]"]

set_property IOSTANDARD MIPI_DPHY [get_ports "MIPI6_*"]
set_property DIFF_TERM_ADV TERM_100 [get_ports "MIPI6_*"]
