



#####
## Constraints for VERSAL VMK365 HDMI (TX-only)
## Version 1.0
## Pin data sourced from verified working design:
## /everest/ps_sival2_nobkup/zakir/mbufg_updates/t40_ced/test/vmk365_4mc_hdmitxrx_single/constrs_1/hdmi_top.xdc
#####


#####
## Pins
#####
set_property PACKAGE_PIN B4 [get_ports {GT_Serial_grx_p[0]}]
set_property PACKAGE_PIN E5 [get_ports {GT_Serial_gtx_p[0]}]
set_property PACKAGE_PIN B6 [get_ports {GT_Serial_grx_p[1]}]
set_property PACKAGE_PIN E7 [get_ports {GT_Serial_gtx_p[1]}]
set_property PACKAGE_PIN B8 [get_ports {GT_Serial_grx_p[2]}]
set_property PACKAGE_PIN G8 [get_ports {GT_Serial_gtx_p[2]}]
set_property PACKAGE_PIN B10 [get_ports {GT_Serial_grx_p[3]}]
set_property PACKAGE_PIN E9 [get_ports {GT_Serial_gtx_p[3]}]

# HDMI RX
set_property PACKAGE_PIN J13 [get_ports {GT_DRU_FRL_CLK_IN_clk_p[0]}]
create_clock -period 2.500 [get_ports GT_DRU_FRL_CLK_IN_clk_p]

# HDMI TX
set_property PACKAGE_PIN J9 [get_ports {TX_REFCLK_P_IN_V_clk_p[0]}]
set_property PACKAGE_PIN H9 [get_ports {TX_REFCLK_P_IN_V_clk_n[0]}]
create_clock -period 3.367 [get_ports TX_REFCLK_P_IN_V_clk_p]
create_clock -period 3.367 [get_ports TX_REFCLK_P_IN_V_clk_n]

#HDMI_TX_SRC_HPD
set_property PACKAGE_PIN AP22 [get_ports TX_HPD_IN]
set_property IOSTANDARD LVCMOS10 [get_ports TX_HPD_IN]

#HDMI_TX_SRC_SCL
set_property PACKAGE_PIN AR19 [get_ports TX_DDC_OUT_scl_io]
set_property IOSTANDARD LVCMOS10 [get_ports TX_DDC_OUT_scl_io]

#HDMI_TX_SRC_SDA
set_property PACKAGE_PIN AT20 [get_ports TX_DDC_OUT_sda_io]
set_property IOSTANDARD LVCMOS10 [get_ports TX_DDC_OUT_sda_io]

# Misc
#GPIO_LED_0_LS
set_property PACKAGE_PIN J36 [get_ports LED0]
set_property IOSTANDARD LVCMOS33 [get_ports LED0]

#HDMI_8T49N241_LOL_IN
set_property PACKAGE_PIN M36 [get_ports IDT8T49N241_LOL_IN]
set_property IOSTANDARD LVCMOS33 [get_ports IDT8T49N241_LOL_IN]

#HDMI_RX_ENABLE_N
set_property PACKAGE_PIN AN18 [get_ports {RX_TI_ENABLE}]
set_property IOSTANDARD LVCMOS10 [get_ports {RX_TI_ENABLE}]

#HDMI_TX_ENABLE_N
set_property PACKAGE_PIN AR22 [get_ports {TX_TI_ENABLE}]
set_property IOSTANDARD LVCMOS10 [get_ports {TX_TI_ENABLE}]

# PL IIC
set_property PACKAGE_PIN AN21 [get_ports HDMI_CTRL_sda_io]
set_property PACKAGE_PIN AM22 [get_ports HDMI_CTRL_scl_io]
set_property IOSTANDARD LVCMOS10 [get_ports HDMI_CTRL_scl_io]
set_property IOSTANDARD LVCMOS10 [get_ports HDMI_CTRL_sda_io]
set_property PULLTYPE PULLUP [get_ports HDMI_CTRL_scl_io]
set_property PULLTYPE PULLUP [get_ports HDMI_CTRL_sda_io]
set_property DRIVE 8 [get_ports HDMI_CTRL_scl_io]
set_property DRIVE 8 [get_ports HDMI_CTRL_sda_io]




#####
## End
#####
