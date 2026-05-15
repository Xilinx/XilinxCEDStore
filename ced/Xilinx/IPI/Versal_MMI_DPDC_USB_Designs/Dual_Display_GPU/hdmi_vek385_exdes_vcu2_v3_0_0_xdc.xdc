





#####
## Constraints for VERSAL VEK385 HDMI 2.1
## Version 1.0
#####


#####
## Pins
#####
set_property PACKAGE_PIN B36 [get_ports {GT_Serial_grx_p[0]}]
set_property PACKAGE_PIN E37 [get_ports {GT_Serial_gtx_p[0]}]
set_property PACKAGE_PIN B34 [get_ports {GT_Serial_grx_p[1]}]
set_property PACKAGE_PIN E35 [get_ports {GT_Serial_gtx_p[1]}]
set_property PACKAGE_PIN B32 [get_ports {GT_Serial_grx_p[2]}]
set_property PACKAGE_PIN E33 [get_ports {GT_Serial_gtx_p[2]}]
set_property PACKAGE_PIN B30 [get_ports {GT_Serial_grx_p[3]}]
set_property PACKAGE_PIN E31 [get_ports {GT_Serial_gtx_p[3]}]

# HDMI RX
#SI570_8A34001_MUX_BUF0_C_P
set_property PACKAGE_PIN L40 [get_ports {GT_DRU_FRL_CLK_IN_clk_p[0]}]
create_clock -period 2.500 [get_ports GT_DRU_FRL_CLK_IN_clk_p]

# HDMI TX
#FMCP1_GBTCLK1_M2C_C_P
set_property PACKAGE_PIN G40 [get_ports {TX_REFCLK_P_IN_V_clk_p[0]}]
create_clock -period 3.367 [get_ports TX_REFCLK_P_IN_V_clk_p]

#HDMI_TX_SRC_HPD
#set_property PACKAGE_PIN AU15     [get_ports "HDMI_TX_SRC_HPD"] ;# Bank 706 VCCO - VADJ_FMC - IO_L15N_H0O3P7_706

set_property PACKAGE_PIN AU15 [get_ports TX_HPD_IN]
set_property IOSTANDARD LVCMOS12 [get_ports TX_HPD_IN]

#HDMI_TX_SRC_SCL
#set_property PACKAGE_PIN AT16     [get_ports "HDMI_TX_SRC_SCL"] ;# Bank 706 VCCO - VADJ_FMC - IO_L14P_H0O3P4_706

set_property PACKAGE_PIN AT16 [get_ports TX_DDC_OUT_scl_io]
set_property IOSTANDARD LVCMOS12 [get_ports TX_DDC_OUT_scl_io]


#HDMI_TX_SRC_SDA
#set_property PACKAGE_PIN AU17     [get_ports "HDMI_TX_SRC_SDA"] ;# Bank 706 VCCO - VADJ_FMC - IO_L14N_H0O3P5_706

set_property PACKAGE_PIN AU17 [get_ports TX_DDC_OUT_sda_io]
set_property IOSTANDARD LVCMOS12 [get_ports TX_DDC_OUT_sda_io]

# Misc
#GPIO_LED_0_LS
#set_property PACKAGE_PIN BF10     [get_ports "GPIO_LED0"] ;# Bank 705 VCCO - VADJ_FMC - IO_L23P_H1O1P6_M1P174_705

#set_property PACKAGE_PIN BF10 [get_ports LED0]
#set_property IOSTANDARD LVCMOS12 [get_ports LED0]

#HDMI_8T49N241_LOL_IN
#set_property PACKAGE_PIN BC18     [get_ports "HDMI_8T49N241_LOL_IN"] ;# Bank 706 VCCO - VADJ_FMC - IO_L7N_H0O1P7_706

set_property PACKAGE_PIN BC18 [get_ports IDT8T49N241_LOL_IN]
set_property IOSTANDARD LVCMOS12 [get_ports IDT8T49N241_LOL_IN]

# HDMI_RX_ENABLE_N
#set_property PACKAGE_PIN AW16     [get_ports "HDMI_RX_ENABLE_N"] ;# Bank 706 VCCO - VADJ_FMC - IO_L12N_H0O3P1_706

set_property PACKAGE_PIN AW16 [get_ports {RX_TI_ENABLE}]
set_property IOSTANDARD LVCMOS12 [get_ports {RX_TI_ENABLE}]

#HDMI_TX_ENABLE_N
#set_property PACKAGE_PIN AT15     [get_ports "HDMI_TX_ENABLE_N"] ;# Bank 706 VCCO - VADJ_FMC - IO_L15P_H0O3P6_706

set_property PACKAGE_PIN AT15 [get_ports {TX_TI_ENABLE}]
set_property IOSTANDARD LVCMOS12 [get_ports {TX_TI_ENABLE}]

# PL IIC
#set_property PACKAGE_PIN AW18     [get_ports "HDMI_CTL_VERSAL_SDA"] ;# Bank 706 VCCO - VADJ_FMC - IO_L11P_H0O2P6_706
#set_property PACKAGE_PIN BA17     [get_ports "HDMI_CTL_VERSAL_SCL"] ;# Bank 706 VCCO - VADJ_FMC - IO_L10N_H0O2P5_706

set_property PACKAGE_PIN AW18 [get_ports HDMI_CTRL_sda_io]
set_property PACKAGE_PIN BA17 [get_ports HDMI_CTRL_scl_io]
set_property IOSTANDARD LVCMOS12 [get_ports HDMI_CTRL_scl_io]
set_property IOSTANDARD LVCMOS12 [get_ports HDMI_CTRL_sda_io]








#####
## End
#####

