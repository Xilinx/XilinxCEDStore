# ########################################################################
# Copyright (C) 2023, Advanced Micro Devices Inc - All rights reserved

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
proc create_root_design {currentDir design_name} {

# Create instance: ps_wizard_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0

apply_bd_automation -rule xilinx.com:bd_rule:ps_wizard -config { board_preset {Yes} boot_config {Custom} configure_noc {Add new AXI NoC} debug_config {JTAG} mc_type {None} num_mc_ddr {None} num_mc_lpddr {None} pl_clocks {None} pl_resets {None}}  [get_bd_cells ps_wizard_0]

set_property -dict [list \
  CONFIG.MMI_CONFIG(DPDC_PRESENTATION_MODE) {Non_Live} \
  CONFIG.MMI_CONFIG(MMI_DP_ENABLE_BEFORE_PL) {1} \
  CONFIG.PS11_CONFIG(PL_FPD_IRQ_USAGE) {CH0 1 CH1 1 CH2 1 CH3 1 CH4 0 CH5 0 CH6 0 CH7 0} \
  CONFIG.PS11_CONFIG(PL_LPD_IRQ_USAGE) {CH0 1 CH1 1 CH2 1 CH3 1 CH4 0 CH5 0 CH6 0 CH7 0 CH8 0 CH9 0 CH10 0 CH11 0 CH12 0 CH13 0 CH14 0 CH15 0 CH16 0 CH17 0 CH18 0 CH19 0 CH20 0 CH21 0 CH22 0 CH23 0} \
  CONFIG.PS11_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {100} \
  CONFIG.PS11_CONFIG(PMC_CRP_PL1_REF_CTRL_FREQMHZ) {134} \
  CONFIG.PS11_CONFIG(PMC_CRP_PL2_REF_CTRL_FREQMHZ) {250} \
  CONFIG.PS11_CONFIG(PMC_HSM1_CLK_OUT_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
  CONFIG.PS11_CONFIG(PS_GEM_TSU_CLK_PORT_PAIR) {1} \
  CONFIG.PS11_CONFIG(PS_FPD_AXI_PL_DATA_WIDTH) {64} \
  CONFIG.PS11_CONFIG(PS_LPD_AXI_PL_DATA_WIDTH) {64} \
  CONFIG.PS11_CONFIG(PS_TTC1_PERIPHERAL_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_TTC2_PERIPHERAL_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_TTC3_PERIPHERAL_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_TTC4_PERIPHERAL_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_TTC5_PERIPHERAL_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_TTC6_PERIPHERAL_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_TTC7_PERIPHERAL_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI1_NOBUF_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI2_MASTER) {R52_1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI2_NOBUF_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI2_NOBUF_MASTER) {R52_0} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI3_NOBUF_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI3_NOBUF_MASTER) {R52_6} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI4_NOBUF_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI4_NOBUF_MASTER) {R52_7} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI5_NOBUF_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI5_NOBUF_MASTER) {R52_8} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI6_NOBUF_ENABLE) {1} \
  CONFIG.PS11_CONFIG(PS_GEN_IPI6_NOBUF_MASTER) {R52_9} \
  CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
  CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_NOC) {1} \
  CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_PL) {1} \
  CONFIG.PS11_CONFIG(PS_USE_LPD_AXI_NOC) {1} \
  CONFIG.PS11_CONFIG(PS_USE_LPD_AXI_PL) {1} \
  CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} \
  CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK1) {1} \
  CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK2) {1} \
  CONFIG.PS11_CONFIG(SMON_MEAS18) {ENABLE 1 MODE 2V_unipolar NAME VCCAUX AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 32} \
  CONFIG.PS11_CONFIG(SMON_MEAS19) {ENABLE 1 MODE 2V_unipolar NAME VCCAUX_LPD AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 33} \
  CONFIG.PS11_CONFIG(SMON_MEAS21) {ENABLE 1 MODE 2V_unipolar NAME VCCINT AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 40} \
  CONFIG.PS11_CONFIG(SMON_MEAS22) {ENABLE 1 MODE 2V_unipolar NAME VCCINT_MMI_MMI AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 41} \
  CONFIG.PS11_CONFIG(SMON_MEAS39) {ENABLE 1 MODE 2V_unipolar NAME VCC_PMC AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 34} \
  CONFIG.PS11_CONFIG(SMON_MEAS40) {ENABLE 1 MODE 2V_unipolar NAME VCC_PSFP AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 35} \
  CONFIG.PS11_CONFIG(SMON_MEAS41) {ENABLE 1 MODE 2V_unipolar NAME VCC_PSLP AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 36} \
  CONFIG.PS11_CONFIG(SMON_MEAS42) {ENABLE 1 MODE 2V_unipolar NAME VCC_RAM AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 37} \
  CONFIG.PS11_CONFIG(SMON_MEAS43) {ENABLE 1 MODE 2V_unipolar NAME VCC_SOC AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 38} \
  CONFIG.PS11_CONFIG(SMON_MEAS44) {ENABLE 1 MODE 1V_unipolar NAME VP_VN AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 1.00 SUPPLY_NUM 39} \
] [get_bd_cells ps_wizard_0]

set_property -dict [list CONFIG.MMI_CONFIG(PCIE0_TYPE1_MEMBASE_MEMLIMIT) {Enabled}] [get_bd_cells ps_wizard_0]

connect_bd_net [get_bd_pins ps_wizard_0/pl2_ref_clk] [get_bd_pins ps_wizard_0/emio_gem_tsu_clk_from_pl]

# Create instance: Master_NoC, and set properties
set Master_NoC [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 Master_NoC ]

set_property -dict [list \
  CONFIG.NUM_CLKS {11} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NMI {11} \
  CONFIG.NUM_SI {11} \
  CONFIG.SI_SIDEBAND_PINS {} \
] [get_bd_cells Master_NoC]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M00_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M01_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M02_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M03_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M04_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M05_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M06_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M07_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M08_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M09_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /Master_NoC/M10_INI]

puts "INFO:: Segmented Configuration is enbaled on Master_NoC!"

# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S00_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M01_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S01_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true} } M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S02_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M03_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S03_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S04_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M01_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S05_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true} } M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S06_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M03_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S07_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S08_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S09_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_mmi} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S10_AXI]

#only QOS fix
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M01_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true} } M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M03_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M01_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true} } M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S06_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M03_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S07_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S08_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {true} } M08_INI {read_bw {100} write_bw {100} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {true} } M10_INI {read_bw {100} write_bw {100} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S09_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_mmi} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true} } M08_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {true} } M10_INI {read_bw {500} write_bw {500} initial_boot {true} }}] [get_bd_intf_pins /Master_NoC/S10_AXI]


# QOS fix_vcu_isp_AIE disablemnet
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S00_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M01_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S01_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true} } M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S02_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M03_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S03_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S04_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M01_INI {read_bw {500} write_bw {500} initial_boot {true} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S05_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true} } M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S06_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M03_INI {read_bw {500} write_bw {500} initial_boot {true} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S07_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S08_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M07_INI {read_bw {100} write_bw {100} initial_boot {false} } M08_INI {read_bw {100} write_bw {100} initial_boot {false} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {100} write_bw {100} initial_boot {false} } M10_INI {read_bw {100} write_bw {100} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S09_AXI]
# set_property -dict [list CONFIG.CATEGORY {ps_mmi} CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {false} } M08_INI {read_bw {500} write_bw {500} initial_boot {false} } M06_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {true} } M05_INI {read_bw {500} write_bw {500} initial_boot {true} } M00_INI {read_bw {500} write_bw {500} initial_boot {true} } M09_INI {read_bw {500} write_bw {500} initial_boot {false} } M10_INI {read_bw {500} write_bw {500} initial_boot {false} }}] [get_bd_intf_pins /Master_NoC/S10_AXI]

# Create interface connections
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins Master_NoC/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins Master_NoC/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC2] [get_bd_intf_pins Master_NoC/S02_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC3] [get_bd_intf_pins Master_NoC/S03_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC4] [get_bd_intf_pins Master_NoC/S04_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC5] [get_bd_intf_pins Master_NoC/S05_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC6] [get_bd_intf_pins Master_NoC/S06_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC7] [get_bd_intf_pins Master_NoC/S07_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins Master_NoC/S08_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins Master_NoC/S09_AXI]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/MMI_DC_AXI_NOC0] [get_bd_intf_pins Master_NoC/S10_AXI]

connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] [get_bd_pins Master_NoC/aclk0]
connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] [get_bd_pins Master_NoC/aclk1]
connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc2_clk] [get_bd_pins Master_NoC/aclk2]
connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc3_clk] [get_bd_pins Master_NoC/aclk3]
connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc4_clk] [get_bd_pins Master_NoC/aclk4]
connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc5_clk] [get_bd_pins Master_NoC/aclk5]
connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc6_clk] [get_bd_pins Master_NoC/aclk6]
connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc7_clk] [get_bd_pins Master_NoC/aclk7]
connect_bd_net [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] [get_bd_pins Master_NoC/aclk8]
connect_bd_net [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] [get_bd_pins Master_NoC/aclk9]
connect_bd_net [get_bd_pins ps_wizard_0/mmi_dc_axi_noc0_clk] [get_bd_pins Master_NoC/aclk10]

# Create instance: NoC_C0_C1, and set properties
set NoC_C0_C1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 NoC_C0_C1 ]

# Create instance: NoC_C2_C3, and set properties
set NoC_C2_C3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 NoC_C2_C3 ]

# Create instance: NoC_C4, and set properties
set NoC_C4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 NoC_C4 ]

set board_name [get_property BOARD_NAME [current_board]]

if {[regexp "vek385_" $board_name]} {

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c0} \
  CONFIG.C1_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,NC,CA0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {128} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config12_opt} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION1 {DDR_CH0_MED} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {5} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C0_C1]

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c2_int} \
  CONFIG.C1_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c3_int} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,NC,CA0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BA_ADDR_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BG_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FPGA_DEVICE_TYPE) {NON_KSB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {4998} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {128} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEM_FILL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_SLOTS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SIDE_BAND_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_STACK_HEIGHT) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {Internal} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_DEFINED_ADDRESS_MAP) {None} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION0 {DDR_CH1} \
  CONFIG.NUM_MCP {2} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {3} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C2_C3]

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c4_int} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BA_ADDR_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BG_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FPGA_DEVICE_TYPE) {NON_KSB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {4998} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEM_FILL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_SLOTS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SIDE_BAND_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_STACK_HEIGHT) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {Internal} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_DEFINED_ADDRESS_MAP) {None} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION0 {DDR_CH2} \
  CONFIG.NUM_MCP {2} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {3} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C4]

} elseif {[regexp "vek386" $board_name]} {

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c0} \
  CONFIG.C1_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,NC,CA0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BA_ADDR_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BG_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CLAMSHELL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CLOCK_STOPPED_SR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONFIG12_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONFIG13_OPT) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_EXTENDED_DDRMC5E) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FPGA_DEVICE_TYPE) {NON_KSB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INIT_TIMEOUT) {0X00645703} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {128} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config12_opt} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEM_FILL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_SLOTS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RDIMM_DUAL_SLOT) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SIDE_BAND_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_STACK_HEIGHT) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_DEFINED_ADDRESS_MAP) {None} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION1 {DDR_CH0_MED} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {5} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C0_C1]

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c2_int} \
  CONFIG.C1_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c3_int} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,NC,CA0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BA_ADDR_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BG_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CLAMSHELL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CLOCK_STOPPED_SR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONFIG12_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONFIG13_OPT) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_EXTENDED_DDRMC5E) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FPGA_DEVICE_TYPE) {NON_KSB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INIT_TIMEOUT) {0X00646144} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {4998} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {128} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEM_FILL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_SLOTS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RDIMM_DUAL_SLOT) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SIDE_BAND_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_STACK_HEIGHT) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {Internal} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_DEFINED_ADDRESS_MAP) {None} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION0 {DDR_CH1} \
  CONFIG.NUM_MCP {2} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {3} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C2_C3]

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c4_int} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BA_ADDR_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BG_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CLAMSHELL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CLOCK_STOPPED_SR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONFIG12_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONFIG13_OPT) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_EXTENDED_DDRMC5E) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FPGA_DEVICE_TYPE) {NON_KSB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INIT_TIMEOUT) {0X00646144} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {4998} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEM_FILL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_SLOTS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RDIMM_DUAL_SLOT) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SIDE_BAND_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_STACK_HEIGHT) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {Internal} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_DEFINED_ADDRESS_MAP) {None} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION0 {DDR_CH2} \
  CONFIG.NUM_MCP {2} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {3} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C4]

} else {
set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c0} \
  CONFIG.C1_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,NC,CA0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BA_ADDR_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BG_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {8Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FPGA_DEVICE_TYPE) {NON_KSB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {128} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {210000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {120000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {210000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {170000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config12_opt} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {2GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEM_FILL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_SLOTS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {15} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SIDE_BAND_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_STACK_HEIGHT) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_DEFINED_ADDRESS_MAP) {None} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION1 {DDR_CH0_MED} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {5} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C0_C1]

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c2_int} \
  CONFIG.C1_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c3_int} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA14,RA13,RA12,RA11,BA1,BA0,BG1,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,CA5,CA4,CA3,CA2,CA1,CA0,NC,BG0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BA_ADDR_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BG_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {8Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FPGA_DEVICE_TYPE) {NON_KSB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {4998} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {128} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {210000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {120000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {210000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {170000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {2GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEM_FILL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_SLOTS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {15} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SIDE_BAND_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_STACK_HEIGHT) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {Internal} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_DEFINED_ADDRESS_MAP) {None} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION0 {DDR_CH1} \
  CONFIG.NUM_MCP {2} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {3} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C2_C3]

set_property -dict [list \
  CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c4_int} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,NA,RA14,RA13,RA12,RA11,BA1,BA0,BG1,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,CA5,CA4,CA3,CA2,CA1,CA0,BG0,NC,NC,NC,NC,NA,NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BA_ADDR_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BG_WIDTH) {2} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {8Gb} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CWL) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {952} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FPGA_DEVICE_TYPE) {NON_KSB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {4998} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {0} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {210000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {120000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {210000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {170000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {2GB} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_MEM_FILL) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_SLOTS) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {15} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SIDE_BAND_ECC) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_STACK_HEIGHT) {1} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {Internal} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_DEFINED_ADDRESS_MAP) {None} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
  CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
  CONFIG.MC_CHAN_REGION0 {DDR_CH2} \
  CONFIG.NUM_MCP {2} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {3} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells NoC_C4]
}

set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S01_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S02_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S03_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C0_C1/S04_INI]

set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C2_C3/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C2_C3/S01_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C2_C3/S02_INI]

set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C4/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C4/S01_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /NoC_C4/S02_INI]

set C0_LPDDR5X_bank700_701 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C0_LPDDR5X_bank700_701 ]
set C1_LPDDR5X_bank703_704 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C1_LPDDR5X_bank703_704 ]
set C2_LPDDR5X_bank708_709 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C2_LPDDR5X_bank708_709 ]
set C3_LPDDR5X_bank710_711 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C3_LPDDR5X_bank710_711 ]
set C4_LPDDR5X_bank714_715 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C4_LPDDR5X_bank714_715 ]

connect_bd_intf_net [get_bd_intf_ports C0_LPDDR5X_bank700_701] [get_bd_intf_pins NoC_C0_C1/C0_CH0_LPDDR5]
connect_bd_intf_net [get_bd_intf_ports C1_LPDDR5X_bank703_704] [get_bd_intf_pins NoC_C0_C1/C1_CH0_LPDDR5]
connect_bd_intf_net [get_bd_intf_ports C2_LPDDR5X_bank708_709] [get_bd_intf_pins NoC_C2_C3/C0_CH0_LPDDR5]
connect_bd_intf_net [get_bd_intf_ports C3_LPDDR5X_bank710_711] [get_bd_intf_pins NoC_C2_C3/C1_CH0_LPDDR5]
connect_bd_intf_net [get_bd_intf_ports C4_LPDDR5X_bank714_715] [get_bd_intf_pins NoC_C4/C0_CH0_LPDDR5]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_0
apply_board_connection -board_interface "lpddr5_clk0_1" -ip_intf "util_ds_buf_0/CLK_IN_D" -diagram $design_name 

connect_bd_net [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins NoC_C0_C1/sys_clk0] [get_bd_pins NoC_C0_C1/sys_clk1]

connect_bd_net [get_bd_pins ps_wizard_0/hsm1_ref_clk] [get_bd_pins NoC_C2_C3/sys_clk0] [get_bd_pins NoC_C4/sys_clk0] [get_bd_pins NoC_C2_C3/sys_clk1]

connect_bd_intf_net [get_bd_intf_pins Master_NoC/M00_INI] [get_bd_intf_pins NoC_C0_C1/S00_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M01_INI] [get_bd_intf_pins NoC_C0_C1/S01_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M02_INI] [get_bd_intf_pins NoC_C0_C1/S02_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M03_INI] [get_bd_intf_pins NoC_C0_C1/S03_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M04_INI] [get_bd_intf_pins NoC_C2_C3/S00_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M05_INI] [get_bd_intf_pins NoC_C4/S00_INI]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 aggr_noc
set_property -dict [list \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NMI {5} \
  CONFIG.NUM_NSI {0} \
  CONFIG.NUM_SI {0} \
] [get_bd_cells aggr_noc]

set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M00_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M01_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M02_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M03_INI]
set_property -dict [list CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /aggr_noc/M04_INI]

connect_bd_intf_net [get_bd_intf_pins aggr_noc/M00_INI] [get_bd_intf_pins NoC_C0_C1/S04_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M01_INI] [get_bd_intf_pins NoC_C2_C3/S01_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M02_INI] [get_bd_intf_pins NoC_C2_C3/S02_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M03_INI] [get_bd_intf_pins NoC_C4/S01_INI]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/M04_INI] [get_bd_intf_pins NoC_C4/S02_INI]

# Create instance: ai_engine_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:ai_engine ai_engine_0

# Create instance: AIE_ConfigNoc, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 AIE_ConfigNoc
set_property -dict [list CONFIG.MI_SIDEBAND_PINS {} CONFIG.NUM_NSI {1} CONFIG.NUM_SI {0} ] [get_bd_cells AIE_ConfigNoc]
set_property -dict [list CONFIG.CATEGORY {aie}] [get_bd_intf_pins /AIE_ConfigNoc/M00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /AIE_ConfigNoc/S00_INI]

connect_bd_intf_net [get_bd_intf_pins AIE_ConfigNoc/M00_AXI] [get_bd_intf_pins ai_engine_0/S00_AXI]
connect_bd_net [get_bd_pins ai_engine_0/s00_axi_aclk] [get_bd_pins AIE_ConfigNoc/aclk0]
connect_bd_intf_net [get_bd_intf_pins AIE_ConfigNoc/S00_INI] [get_bd_intf_pins Master_NoC/M06_INI]

# Create instance: vcu2_0, and set properties
set vcu2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vcu2 vcu2_0 ]
set_property CONFIG.NSU_ONLY {true} [get_bd_cells vcu2_0]

# Create instance: ilconstant_0, and set properties
set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]
set_property -dict [list CONFIG.CONST_VAL {3} CONFIG.CONST_WIDTH {2} ] $ilconstant_0

# Create instance: ilconstant_1, and set properties
set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_1 ]
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {5} ] $ilconstant_1

# Create instance: VCU_ConfigNoc, and set properties
set VCU_ConfigNoc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 VCU_ConfigNoc ]
set_property -dict [list CONFIG.MI_SIDEBAND_PINS {} CONFIG.NUM_NSI {1} CONFIG.NUM_SI {0} ] $VCU_ConfigNoc
set_property -dict [ list CONFIG.DATA_WIDTH {128} CONFIG.CATEGORY {vcu} ] [get_bd_intf_pins $VCU_ConfigNoc/M00_AXI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} ] [get_bd_intf_pins $VCU_ConfigNoc/S00_INI]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {M00_AXI} ] [get_bd_pins $VCU_ConfigNoc/aclk0]

# Create instance: visp_ss_tile0, and set properties
set visp_ss_tile0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:visp_ss visp_ss_tile0 ]

set_property CONFIG.C_CONFIG_ONLY {true} $visp_ss_tile0
set_property -dict [ list CONFIG.ADDR_WIDTH {32} CONFIG.CATEGORY {noc} CONFIG.MY_CATEGORY {isp} CONFIG.TILE_INDEX {0} CONFIG.INDEX {0} ] [get_bd_intf_pins $visp_ss_tile0/TILE0_ISP_NSU]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {TILE0_ISP_NSU} ] [get_bd_pins $visp_ss_tile0/tile0_nsu_axi_clk]

# Create instance: ISP_Tile2_ConfigNoc, and set properties
set ISP_Tile2_ConfigNoc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 ISP_Tile2_ConfigNoc ]

set_property -dict [list CONFIG.MI_SIDEBAND_PINS {} CONFIG.NUM_NSI {1} CONFIG.NUM_SI {0} ] $ISP_Tile2_ConfigNoc
set_property -dict [ list CONFIG.DATA_WIDTH {128} CONFIG.CATEGORY {isp} ] [get_bd_intf_pins $ISP_Tile2_ConfigNoc/M00_AXI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} ] [get_bd_intf_pins $ISP_Tile2_ConfigNoc/S00_INI]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {M00_AXI} ] [get_bd_pins $ISP_Tile2_ConfigNoc/aclk0]

# Create instance: visp_ss_tile1, and set properties
set visp_ss_tile1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:visp_ss visp_ss_tile1 ]

set_property -dict [list CONFIG.C_CONFIG_ONLY {true} CONFIG.C_TILE0_ENABLE {false} CONFIG.C_TILE1_ENABLE {true} ] $visp_ss_tile1
set_property -dict [ list CONFIG.ADDR_WIDTH {32} CONFIG.CATEGORY {noc} CONFIG.MY_CATEGORY {isp} CONFIG.TILE_INDEX {1} CONFIG.INDEX {0} ] [get_bd_intf_pins $visp_ss_tile1/TILE1_ISP_NSU]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {TILE1_ISP_NSU} ] [get_bd_pins $visp_ss_tile1/tile1_nsu_axi_clk]

# Create instance: ISP_Tile1_ConfigNoc, and set properties
set ISP_Tile1_ConfigNoc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 ISP_Tile1_ConfigNoc ]

set_property -dict [list CONFIG.MI_SIDEBAND_PINS {} CONFIG.NUM_NSI {1} CONFIG.NUM_SI {0} ] $ISP_Tile1_ConfigNoc
set_property -dict [ list CONFIG.DATA_WIDTH {128} CONFIG.CATEGORY {isp} ] [get_bd_intf_pins $ISP_Tile1_ConfigNoc/M00_AXI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} ] [get_bd_intf_pins $ISP_Tile1_ConfigNoc/S00_INI]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {M00_AXI} ] [get_bd_pins $ISP_Tile1_ConfigNoc/aclk0]

# Create instance: ISP_Tile0_ConfigNoc, and set properties
set ISP_Tile0_ConfigNoc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 ISP_Tile0_ConfigNoc ]

set_property -dict [list CONFIG.MI_SIDEBAND_PINS {} CONFIG.NUM_NSI {1} CONFIG.NUM_SI {0} ] $ISP_Tile0_ConfigNoc
set_property -dict [ list CONFIG.DATA_WIDTH {128} CONFIG.CATEGORY {isp} ] [get_bd_intf_pins $ISP_Tile0_ConfigNoc/M00_AXI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} ] [get_bd_intf_pins $ISP_Tile0_ConfigNoc/S00_INI]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {M00_AXI} ] [get_bd_pins $ISP_Tile0_ConfigNoc/aclk0]

# Create instance: visp_ss_tile2, and set properties
set visp_ss_tile2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:visp_ss visp_ss_tile2 ]
set_property -dict [list CONFIG.C_CONFIG_ONLY {true} CONFIG.C_TILE0_ENABLE {false} CONFIG.C_TILE2_ENABLE {true} ] $visp_ss_tile2
set_property -dict [ list CONFIG.ADDR_WIDTH {32} CONFIG.CATEGORY {noc} CONFIG.MY_CATEGORY {isp} CONFIG.TILE_INDEX {2} CONFIG.INDEX {0} ] [get_bd_intf_pins $visp_ss_tile2/TILE2_ISP_NSU]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {TILE2_ISP_NSU} ] [get_bd_pins $visp_ss_tile2/tile2_nsu_axi_clk]

connect_bd_intf_net [get_bd_intf_pins vcu2_0/C0_S_AXI_NOC] [get_bd_intf_pins VCU_ConfigNoc/M00_AXI]
connect_bd_intf_net [get_bd_intf_pins ISP_Tile0_ConfigNoc/M00_AXI] [get_bd_intf_pins visp_ss_tile0/TILE0_ISP_NSU]
connect_bd_intf_net [get_bd_intf_pins ISP_Tile1_ConfigNoc/M00_AXI] [get_bd_intf_pins visp_ss_tile1/TILE1_ISP_NSU]
connect_bd_intf_net [get_bd_intf_pins ISP_Tile2_ConfigNoc/M00_AXI] [get_bd_intf_pins visp_ss_tile2/TILE2_ISP_NSU]

connect_bd_intf_net [get_bd_intf_pins Master_NoC/M07_INI] [get_bd_intf_pins VCU_ConfigNoc/S00_INI] 
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M08_INI] [get_bd_intf_pins ISP_Tile0_ConfigNoc/S00_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M09_INI] [get_bd_intf_pins ISP_Tile1_ConfigNoc/S00_INI]
connect_bd_intf_net [get_bd_intf_pins Master_NoC/M10_INI] [get_bd_intf_pins ISP_Tile2_ConfigNoc/S00_INI]

connect_bd_net [get_bd_pins visp_ss_tile0/tile0_nsu_axi_clk] [get_bd_pins ISP_Tile0_ConfigNoc/aclk0]
connect_bd_net [get_bd_pins visp_ss_tile1/tile1_nsu_axi_clk] [get_bd_pins ISP_Tile1_ConfigNoc/aclk0]
connect_bd_net [get_bd_pins visp_ss_tile2/tile2_nsu_axi_clk] [get_bd_pins ISP_Tile2_ConfigNoc/aclk0]

connect_bd_net [get_bd_pins vcu2_0/c0_s_axi_noc_clk] [get_bd_pins VCU_ConfigNoc/aclk0]

connect_bd_net [get_bd_pins ilconstant_0/dout] [get_bd_pins ps_wizard_0/gem0_tsu_inc_ctrl]
connect_bd_net [get_bd_pins ilconstant_1/dout] [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk]
connect_bd_net [get_bd_pins ilconstant_1/dout] [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk]
connect_bd_net [get_bd_pins ilconstant_1/dout] [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk]
connect_bd_net [get_bd_pins ilconstant_1/dout] [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk]
connect_bd_net [get_bd_pins ilconstant_1/dout] [get_bd_pins ps_wizard_0/pl_mmi_dc_i2s_s0_clk]

group_bd_cells ISP_hier [get_bd_cells visp_ss_tile0] [get_bd_cells visp_ss_tile1] [get_bd_cells visp_ss_tile2] [get_bd_cells ISP_Tile1_ConfigNoc] [get_bd_cells ISP_Tile0_ConfigNoc] [get_bd_cells ISP_Tile2_ConfigNoc]
group_bd_cells VCU_hier [get_bd_cells VCU_ConfigNoc] [get_bd_cells vcu2_0]

# Add USER_COMMENTS on $design_name
set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example EDF Base Design <<<<<<<<< =======================
\t Note:
\t --> Board preset applied to PS_WIZARD and memory controller settings
\t --> AI Engine control path is connected to PS_WIZARD
\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.}  [current_bd_design]

# Perform GUI Layout
regenerate_bd_layout -layout_string {
	"ActiveEmotionalView":"Default View",
	"comment_0":"\t \t ======================= >>>>>>>>> An Example EDF Base Design <<<<<<<<< =======================
	\t Note:
	\t --> Board preset applied to PS_WIZARD and memory controller
	\t --> AI Engine control path is connected to PS_WIZARD
	\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.",
	"commentid":"comment_0|",
	"font_comment_0":"14",
	"guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
	#  -string -flagsOSRD
	preplace cgraphic comment_0 place right -1750 -200 textcolor 4 linecolor 3
	",
	"linktoobj_comment_0":"",
	"linktotype_comment_0":"bd_design" }
}
