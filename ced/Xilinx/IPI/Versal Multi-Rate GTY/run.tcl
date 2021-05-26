
# ########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

 # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

proc createDesign {design_name options} { 

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell design_name temp_options} {

# puts "create_root_design"

set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]

puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"

  # Create interface ports
  set GT_Serial [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial ]

  set apb3clk_gt [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 apb3clk_gt ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $apb3clk_gt

  set gt_bridge_ip_0_diff_gt_ref_clock [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_bridge_ip_0_diff_gt_ref_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
   ] $gt_bridge_ip_0_diff_gt_ref_clock


  # Create ports

  # Create instance: axis_vio_0, and set properties
  set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio axis_vio_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_IN {4} \
   CONFIG.C_NUM_PROBE_OUT {2} \
   CONFIG.C_PROBE_OUT1_WIDTH {4} \
 ] $axis_vio_0

  # Create instance: bufg_gt, and set properties
  set bufg_gt [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt ]

  # Create instance: bufg_gt_1, and set properties
  set bufg_gt_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_1 ]

  # Create instance: gt_bridge_ip_0, and set properties
  set gt_bridge_ip_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gt_bridge_ip gt_bridge_ip_0 ]
  set_property -dict [ list \
   CONFIG.IP_LR0_SETTINGS {PRESET None RX_PAM_SEL NRZ TX_PAM_SEL NRZ RX_GRAY_BYP true TX_GRAY_BYP true\
RX_GRAY_LITTLEENDIAN true TX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true\
TX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false TX_PRECODE_LITTLEENDIAN false\
INTERNAL_PRESET None GT_TYPE GTY GT_DIRECTION DUPLEX TX_LINE_RATE 10.3125\
TX_PLL_TYPE LCPLL TX_REFCLK_FREQUENCY 156.25 TX_ACTUAL_REFCLK_FREQUENCY\
156.250000000000 TX_FRACN_ENABLED false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE\
R0 TX_DATA_ENCODING RAW TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH 32\
TX_BUFFER_MODE 1 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false\
TX_OUTCLK_SOURCE TXOUTCLKPMA TXPROGDIV_FREQ_ENABLE false TXPROGDIV_FREQ_SOURCE\
LCPLL TXPROGDIV_FREQ_VAL 322.265625 TX_DIFF_SWING_EMPH_MODE CUSTOM\
TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false\
TX_RATE_GROUP A RX_LINE_RATE 10.3125 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY\
156.25 RX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 RX_FRACN_ENABLED false\
RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING RAW\
RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH 32 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE\
RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE LCPLL\
RXPROGDIV_FREQ_VAL 322.265625 INS_LOSS_NYQ 20 RX_EQ_MODE AUTO RX_COUPLING AC\
RX_TERMINATION PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800\
RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false\
RX_64B66B_CRC false OOB_ENABLE false RX_COMMA_ALIGN_WORD 1\
RX_COMMA_SHOW_REALIGN_ENABLE true PCIE_ENABLE false TX_LANE_DESKEW_HDMI_ENABLE\
false RX_COMMA_P_ENABLE false RX_COMMA_M_ENABLE false RX_COMMA_DOUBLE_ENABLE\
false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL 1010000011 RX_COMMA_MASK\
0000000000 RX_SLIDE_MODE OFF RX_SSC_PPM 0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1\
RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000\
RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1\
00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false\
RX_CB_VAL_0_2 00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3\
false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false\
RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0\
false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false\
RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2\
false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3 00000000\
RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 0 RX_CC_LEN_SEQ 1\
RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE ENABLE\
RX_CC_REPEAT_WAIT 0 RX_CC_VAL\
00000000000000000000000000000000000000000000000000000000000000000000000000000000\
RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00000000 RX_CC_K_0_0 false RX_CC_DISP_0_0\
false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false\
RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2\
false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3 00000000\
RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0\
00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false\
RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1 false RX_CC_MASK_1_2\
false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false\
RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3\
false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 6.1862627\
RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE\
MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE\
RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE\
RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET NONE RX_COMMA_VALID_ONLY 0}\
   CONFIG.IP_LR1_SETTINGS {PRESET None RX_PAM_SEL NRZ TX_PAM_SEL NRZ RX_GRAY_BYP true TX_GRAY_BYP true\
RX_GRAY_LITTLEENDIAN true TX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true\
TX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false TX_PRECODE_LITTLEENDIAN false\
INTERNAL_PRESET None GT_TYPE GTY GT_DIRECTION DUPLEX TX_LINE_RATE 25.78125\
TX_PLL_TYPE LCPLL TX_REFCLK_FREQUENCY 156.25 TX_ACTUAL_REFCLK_FREQUENCY\
156.250000000000 TX_FRACN_ENABLED true TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0\
TX_DATA_ENCODING RAW TX_USER_DATA_WIDTH 64 TX_INT_DATA_WIDTH 64 TX_BUFFER_MODE\
1 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE\
TXOUTCLKPMA TXPROGDIV_FREQ_ENABLE false TXPROGDIV_FREQ_SOURCE LCPLL\
TXPROGDIV_FREQ_VAL 322.265625 TX_DIFF_SWING_EMPH_MODE CUSTOM\
TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false\
TX_RATE_GROUP A RX_LINE_RATE 25.78125 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY\
156.25 RX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 RX_FRACN_ENABLED true\
RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING RAW\
RX_USER_DATA_WIDTH 64 RX_INT_DATA_WIDTH 64 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE\
RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE LCPLL\
RXPROGDIV_FREQ_VAL 322.265625 INS_LOSS_NYQ 20 RX_EQ_MODE AUTO RX_COUPLING AC\
RX_TERMINATION PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800\
RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false\
RX_64B66B_CRC false OOB_ENABLE false RX_COMMA_ALIGN_WORD 1\
RX_COMMA_SHOW_REALIGN_ENABLE true PCIE_ENABLE false TX_LANE_DESKEW_HDMI_ENABLE\
false RX_COMMA_P_ENABLE false RX_COMMA_M_ENABLE false RX_COMMA_DOUBLE_ENABLE\
false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL 1010000011 RX_COMMA_MASK\
0000000000 RX_SLIDE_MODE OFF RX_SSC_PPM 0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1\
RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000\
RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1\
00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false\
RX_CB_VAL_0_2 00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3\
false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false\
RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0\
false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false\
RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2\
false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3 00000000\
RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 0 RX_CC_LEN_SEQ 1\
RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE ENABLE\
RX_CC_REPEAT_WAIT 0 RX_CC_VAL\
00000000000000000000000000000000000000000000000000000000000000000000000000000000\
RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00000000 RX_CC_K_0_0 false RX_CC_DISP_0_0\
false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false\
RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2\
false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3 00000000\
RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0\
00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false\
RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1 false RX_CC_MASK_1_2\
false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false\
RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3\
false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 10\
RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE\
MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE\
RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE\
RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET NONE RX_COMMA_VALID_ONLY 0}\
   CONFIG.IP_NO_OF_LANES {1} \
 ] $gt_bridge_ip_0

  # Create instance: gt_quad_base_0, and set properties
  set gt_quad_base_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gt_quad_base gt_quad_base_0 ]
  set_property -dict [ list \
   CONFIG.APB3_CLK_FREQUENCY {200} \
   CONFIG.PORTS_INFO_DICT {LANE_SEL_DICT {unconnected {RX0 RX1 RX3 TX0 TX1 TX3} PROT0 {RX2 TX2}} GT_TYPE\
GTY REG_CONF_INTF APB3_INTF BOARD_PARAMETER { }}\
   CONFIG.QUAD_USAGE {TX_QUAD_CH {TXQuad_0_/gt_quad_base_0 {/gt_quad_base_0\
undef,undef,design_1_gt_bridge_ip_0_4.IP_CH0,undef MSTRCLK 0,0,1,0\
IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/gt_quad_base_0 {/gt_quad_base_0\
undef,undef,design_1_gt_bridge_ip_0_4.IP_CH0,undef MSTRCLK 0,0,1,0\
IS_CURRENT_QUAD 1}}}\
   CONFIG.REFCLK_STRING {HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_156.25_MHz_unique1} \
 ] $gt_quad_base_0

  # Create instance: urlp, and set properties
  set urlp [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic urlp ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $urlp

  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
 ] $util_ds_buf

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_0 ]
  set_property -dict [ list \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {lpddr4_sma_clk2} \
 ] $util_ds_buf_0

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [list \
   CONFIG.DDR_MEMORY_MODE {Custom} \
   CONFIG.DEBUG_MODE {JTAG} \
   CONFIG.DESIGN_MODE {2} \
   CONFIG.PS_BOARD_INTERFACE {cips_fixed_io} \
   CONFIG.PS_PMC_CONFIG {PS_USE_PMCPL_CLK0 0 PS_USE_PMCPL_CLK1 0 PS_USE_PMCPL_CLK2 0 PS_USE_PMCPL_CLK3 0\
PS_NUM_FABRIC_RESETS 0 PS_HSDP_EGRESS_TRAFFIC JTAG PS_HSDP_INGRESS_TRAFFIC JTAG\
PS_HSDP_MODE None DEBUG_MODE JTAG PS_MIO7 {{AUX_IO 0} {DIRECTION in}\
{DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW\
slow} {USAGE Reserved}} PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA}\
{OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}}\
PS_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default}\
{PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} PS_MIO21 {{AUX_IO 0}\
{DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable}\
{SCHMITT 0} {SLEW slow} {USAGE Reserved}} PMC_MIO37 {{AUX_IO 0} {DIRECTION out}\
{DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow}\
{USAGE GPIO}} PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1}\
{POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 1}} {WP_ENABLE 0}\
{WP_IO {PMC_MIO 1}}} PMC_SD1_COHERENCY 0 PMC_SD1_DATA_TRANSFER_MODE 8Bit\
PMC_SD1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 36}}} PMC_SD1_SLOT_TYPE {SD\
3.0} PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}}\
PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}}\
PMC_I2CPMC_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} PMC_OSPI_PERIPHERAL\
{{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} PMC_QSPI_COHERENCY 0\
PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} PMC_QSPI_PERIPHERAL_DATA_MODE x4\
PMC_QSPI_PERIPHERAL_ENABLE 1 PMC_QSPI_PERIPHERAL_MODE {Dual Parallel}\
PS_CAN1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 40 .. 41}}} PS_ENET0_MDIO {{ENABLE\
1} {IO {PS_MIO 24 .. 25}}} PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 ..\
11}}} PS_ENET1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 12 .. 23}}}\
PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} PS_UART0_PERIPHERAL\
{{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} PS_USB3_PERIPHERAL {{ENABLE 1} {IO\
{PMC_MIO 13 .. 25}}} PMC_REF_CLK_FREQMHZ 33.3333 PS_PCIE_RESET {{ENABLE 1} {IO\
{PMC_MIO 38 .. 39}}} PS_BOARD_INTERFACE cips_fixed_io SMON_ALARMS Set_Alarms_On\
SMON_ENABLE_TEMP_AVERAGING 0 SMON_TEMP_AVERAGING_SAMPLES 8 DESIGN_MODE 2\
PS_PCIE1_PERIPHERAL_ENABLE 0 PS_PCIE2_PERIPHERAL_ENABLE 0\
PCIE_APERTURES_SINGLE_ENABLE 0 PCIE_APERTURES_DUAL_ENABLE 0}\
  ] $versal_cips_0


  # Create instance: xlcp, and set properties
  set xlcp [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlcp ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {1} \
 ] $xlcp

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN_D_0_1 [get_bd_intf_ports apb3clk_gt] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net gt_bridge_ip_0_GT_RX0 [get_bd_intf_pins gt_bridge_ip_0/GT_RX0] [get_bd_intf_pins gt_quad_base_0/RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net gt_bridge_ip_0_GT_TX0 [get_bd_intf_pins gt_bridge_ip_0/GT_TX0] [get_bd_intf_pins gt_quad_base_0/TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net gt_bridge_ip_0_diff_gt_ref_clock_1 [get_bd_intf_ports gt_bridge_ip_0_diff_gt_ref_clock] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  connect_bd_intf_net -intf_net gt_quad_base_0_GT_Serial [get_bd_intf_ports GT_Serial] [get_bd_intf_pins gt_quad_base_0/GT_Serial]

  # Create port connections
  connect_bd_net -net axis_vio_0_probe_out0 [get_bd_pins axis_vio_0/probe_out0] [get_bd_pins gt_bridge_ip_0/gtreset_in]
  connect_bd_net -net axis_vio_0_probe_out1 [get_bd_pins axis_vio_0/probe_out1] [get_bd_pins gt_bridge_ip_0/rate_sel]
  connect_bd_net -net bufg_gt_1_usrclk [get_bd_pins bufg_gt_1/usrclk] [get_bd_pins gt_bridge_ip_0/gt_txusrclk] [get_bd_pins gt_quad_base_0/ch2_txusrclk]
  connect_bd_net -net bufg_gt_usrclk [get_bd_pins bufg_gt/usrclk] [get_bd_pins gt_bridge_ip_0/gt_rxusrclk] [get_bd_pins gt_quad_base_0/ch2_rxusrclk]
  connect_bd_net -net gt_bridge_ip_0_link_status_out [get_bd_pins axis_vio_0/probe_in0] [get_bd_pins gt_bridge_ip_0/link_status_out]
  connect_bd_net -net gt_bridge_ip_0_rx_resetdone_out [get_bd_pins axis_vio_0/probe_in2] [get_bd_pins gt_bridge_ip_0/rx_resetdone_out]
  connect_bd_net -net gt_bridge_ip_0_tx_resetdone_out [get_bd_pins axis_vio_0/probe_in1] [get_bd_pins gt_bridge_ip_0/tx_resetdone_out]
  connect_bd_net -net gt_quad_base_0_ch2_rxoutclk [get_bd_pins bufg_gt/outclk] [get_bd_pins gt_quad_base_0/ch2_rxoutclk]
  connect_bd_net -net gt_quad_base_0_ch2_txoutclk [get_bd_pins bufg_gt_1/outclk] [get_bd_pins gt_quad_base_0/ch2_txoutclk]
  connect_bd_net -net gt_quad_base_0_gtpowergood [get_bd_pins gt_quad_base_0/gtpowergood] [get_bd_pins xlcp/In0]
  connect_bd_net -net gt_quad_base_0_hsclk1_lcplllock [get_bd_pins axis_vio_0/probe_in3] [get_bd_pins gt_quad_base_0/hsclk1_lcplllock]
  connect_bd_net -net urlp_Res [get_bd_pins gt_bridge_ip_0/gtpowergood] [get_bd_pins urlp/Res]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins axis_vio_0/clk] [get_bd_pins gt_bridge_ip_0/apb3clk] [get_bd_pins gt_quad_base_0/apb3clk] [get_bd_pins util_ds_buf_0/IBUF_OUT]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins gt_quad_base_0/GT_REFCLK0] [get_bd_pins util_ds_buf/IBUF_OUT]
  connect_bd_net -net xlcp_dout [get_bd_pins urlp/Op1] [get_bd_pins xlcp/dout]

  # Create address segments

  assign_bd_address
  validate_bd_design
  regenerate_bd_layout
  make_wrapper -files [get_files $design_name.bd] -top -import -quiet

  puts "INFO: End of create_root_design"
}


##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $design_name $options 

	# close_bd_design [get_bd_designs $design_name]
	# set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
	open_bd_design [get_bd_files $design_name]
	# Add USER_COMMENTS on $design_name
	set_property USER_COMMENTS.comment_0 {} [current_bd_design]
	set_property USER_COMMENTS.comment0 {Next Steps:
1. Create top level xdc and add REFCLK create_clock and vio set_false_path constraints. Refer to README.md in below url for list of constraints to add. 
https://github.com/Xilinx/XilinxCEDStore/tree/2021.1/ced/Xilinx/IPI/Multi-Rate_GTY
2. Synthesize and open synthesized design to do pin planning to lock MGTREFCLK and TX/RX pin locations.
3. Select Generate Device Image in the Flow Navigator to create .pdi image.
4. Program pdi and refer to README.md for board bringup and enabling IBERT in hardware manager.
 } [current_bd_design]
}
