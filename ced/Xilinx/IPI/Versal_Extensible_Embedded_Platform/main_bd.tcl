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

open_bd_design [get_bd_files $design_name]

set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]
# Fetching memory configurations availale on the selected board

set mem_config [board_memory_config [get_property BOARD_NAME [current_board]]]

set default_mem [lindex $mem_config 0]
set additional_mem [lindex $mem_config 1]
set bdc_ddr0 [lindex $mem_config 2]
set bdc_ddr1 [lindex $mem_config 3]

# Create instance: CIPS_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:* CIPS_0

#apply_board_connection -board_interface "cips_fixed_io" -ip_intf "CIPS_0/FIXED_IO" -diagram $design_name
apply_board_connection -board_interface "ps_pmc_fixed_io" -ip_intf "CIPS_0/FIXED_IO" -diagram $design_name

set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom DDR_MEMORY_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 99.999992 PMC_USE_PMC_NOC_AXI0 1 PS_IRQ_USAGE {{CH0 1} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} PS_TTC0_PERIPHERAL_ENABLE {1} PS_NUM_FABRIC_RESETS 1 PS_PL_CONNECTIVITY_MODE Custom PS_USE_FPD_AXI_NOC0 1 PS_USE_FPD_AXI_NOC1 1 PS_USE_FPD_CCI_NOC 1 PS_USE_M_AXI_FPD 1 PS_USE_NOC_LPD_AXI0 1 PS_USE_PMCPL_CLK0 1 } CONFIG.CLOCK_MODE {Custom} CONFIG.DDR_MEMORY_MODE {Custom} CONFIG.PS_PL_CONNECTIVITY_MODE {Custom}] [get_bd_cells CIPS_0]

set_property -dict [list CONFIG.PS_PMC_CONFIG {PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI0_MASTER A72 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI1_MASTER A72 PS_GEN_IPI2_ENABLE 1 PS_GEN_IPI2_MASTER A72 PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI3_MASTER A72 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI4_MASTER A72 PS_GEN_IPI5_ENABLE 1 PS_GEN_IPI5_MASTER A72 PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI6_MASTER A72} ] [get_bd_cells CIPS_0]

  # Create instance: cips_noc, and set properties
  set cips_noc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc cips_noc ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {8} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {9} \
    CONFIG.NUM_NSI {0} \
    CONFIG.NUM_SI {8} \
  ] $cips_noc

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M08_INI {read_bw {500} write_bw {500}} M04_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /cips_noc/S00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M08_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {500} write_bw {500}} M05_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /cips_noc/S01_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M08_INI {read_bw {500} write_bw {500}} M06_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /cips_noc/S02_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500}} M08_INI {read_bw {500} write_bw {500}} M03_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /cips_noc/S03_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /cips_noc/S04_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /cips_noc/S05_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /cips_noc/S06_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M08_INI {read_bw {500} write_bw {500}} M04_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /cips_noc/S07_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /cips_noc/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /cips_noc/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /cips_noc/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /cips_noc/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /cips_noc/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /cips_noc/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /cips_noc/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins /cips_noc/aclk7]

if { ($use_aie == "false")||(!$use_aie) } {

set_property CONFIG.NUM_NMI {8} [get_bd_cells cips_noc]
set_property -dict [list CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /cips_noc/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M05_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /cips_noc/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M06_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /cips_noc/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500}} M03_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /cips_noc/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /cips_noc/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /cips_noc/S05_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /cips_noc/S06_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /cips_noc/S07_AXI] }


create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* $default_mem

if {[regexp "vpk120" $board_name]||[regexp "vek280" $board_name]} {

	apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "$default_mem/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "$default_mem/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "$default_mem/sys_clk0" -diagram $design_name
	
} elseif {[regexp "vpk180" $board_name]} {

	apply_board_connection -board_interface "ch0_lpddr4_trip3" -ip_intf "/$default_mem/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip3" -ip_intf "/$default_mem/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk3" -ip_intf "/$default_mem/sys_clk0" -diagram $design_name
	
} elseif {[regexp "vhk158" $board_name]} {

	apply_board_connection -board_interface "ddr4_dimm0" -ip_intf "$default_mem/CH0_DDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ddr4_dimm0_sma_clk" -ip_intf "$default_mem/sys_clk0" -diagram $design_name 

} else {

	apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "$default_mem/CH0_DDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "$default_mem/sys_clk0" -diagram $design_name 

}

set_property -dict [list CONFIG.NUM_SI {0} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {8} CONFIG.NUM_CLKS {0} CONFIG.NUM_MCP {4} CONFIG.MC_CHAN_REGION1 {DDR_LOW1}] [get_bd_cells $default_mem]
if { [regexp "noc_lpddr4" $default_mem] } {
	set_property -dict [list \
	CONFIG.MC_CHANNEL_INTERLEAVING {true} \
	CONFIG.MC_CH_INTERLEAVING_SIZE {4K_Bytes} \
	] [get_bd_cells $default_mem]
}

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {128} write_bw {128} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$default_mem/S00_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$default_mem/S01_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$default_mem/S02_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$default_mem/S03_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$default_mem/S04_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$default_mem/S05_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$default_mem/S06_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$default_mem/S07_INI]

#Cereating additional memory
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* $additional_mem

if {[regexp "vpk120" $board_name]||[regexp "vek280" $board_name]} {

	apply_board_connection -board_interface "ch0_lpddr4_trip2" -ip_intf "$additional_mem/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip2" -ip_intf "$additional_mem/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk2" -ip_intf "$additional_mem/sys_clk0" -diagram $design_name 

	apply_board_connection -board_interface "ch0_lpddr4_trip3" -ip_intf "/$additional_mem/CH0_LPDDR4_1" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip3" -ip_intf "/$additional_mem/CH1_LPDDR4_1" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk3" -ip_intf "/$additional_mem/sys_clk1" -diagram $design_name 
	
} elseif {[regexp "vpk180" $board_name]} {

	apply_board_connection -board_interface "ch0_lpddr4_trip2" -ip_intf "$additional_mem/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip2" -ip_intf "$additional_mem/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk2" -ip_intf "$additional_mem/sys_clk0" -diagram $design_name 

	apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "/$additional_mem/CH0_LPDDR4_1" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "/$additional_mem/CH1_LPDDR4_1" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "/$additional_mem/sys_clk1" -diagram $design_name  

} elseif {[regexp "vhk158" $board_name]} {

	apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "$additional_mem/CH0_DDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "$additional_mem/sys_clk0" -diagram $design_name 

} else {

	apply_board_connection -board_interface "ch0_lpddr4_c0" -ip_intf "$additional_mem/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_c0" -ip_intf "$additional_mem/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_sma_clk1" -ip_intf "$additional_mem/sys_clk0" -diagram $design_name 

	apply_board_connection -board_interface "ch0_lpddr4_c1" -ip_intf "/$additional_mem/CH0_LPDDR4_1" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_c1" -ip_intf "/$additional_mem/CH1_LPDDR4_1" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_sma_clk2" -ip_intf "/$additional_mem/sys_clk1" -diagram $design_name 

} 

set_property -dict [list CONFIG.NUM_SI {0} CONFIG.NUM_MI {0} CONFIG.NUM_MCP {4} CONFIG.NUM_NSI {8} CONFIG.NUM_CLKS {0} CONFIG.MC_CHAN_REGION0 {DDR_CH1}] [get_bd_cells $additional_mem]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$additional_mem/S00_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$additional_mem/S01_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$additional_mem/S02_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$additional_mem/S03_INI]

  set_property -dict [ list \
   CONFIG.INI_STRATEGY {load} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$additional_mem/S04_INI]

  set_property -dict [ list \
   CONFIG.INI_STRATEGY {load} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$additional_mem/S05_INI]

  set_property -dict [ list \
   CONFIG.INI_STRATEGY {load} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$additional_mem/S06_INI]

  set_property -dict [ list \
   CONFIG.INI_STRATEGY {load} \
   CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /$additional_mem/S07_INI]
 
   # # Create instance: clk_wizard_1, and set properties
  # set clk_wizard_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_1 ]
  # set_property -dict [list \
    # CONFIG.CLKOUT_DRIVES {BUFG} \
    # CONFIG.CLKOUT_DYN_PS {None} \
    # CONFIG.CLKOUT_MATCHED_ROUTING {false} \
    # CONFIG.CLKOUT_PORT {clk_out1} \
    # CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000} \
    # CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {100.000} \
    # CONFIG.CLKOUT_REQUESTED_PHASE {0.000} \
    # CONFIG.CLKOUT_USED {true} \
    # CONFIG.JITTER_SEL {Min_O_Jitter} \
    # CONFIG.PRIM_SOURCE {No_buffer} \
    # CONFIG.RESET_TYPE {ACTIVE_LOW} \
    # CONFIG.USE_LOCKED {true} \
    # CONFIG.USE_PHASE_ALIGNMENT {true} \
    # CONFIG.USE_RESET {true} \
  # ] $clk_wizard_1


  # # Create instance: IsoReset, and set properties
  # set IsoReset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset IsoReset ]

  # # Create instance: ext_bdc, and set properties
  set ext_bdc [ create_bd_cell -type container -reference ext_bdc ext_bdc ]
  set_property -dict [list \
    CONFIG.ACTIVE_SIM_BD {ext_bdc.bd} \
    CONFIG.ACTIVE_SYNTH_BD {ext_bdc.bd} \
    CONFIG.ENABLE_DFX {0} \
    CONFIG.LIST_SIM_BD {ext_bdc.bd} \
    CONFIG.LIST_SYNTH_BD {ext_bdc.bd} \
    CONFIG.LOCK_PROPAGATE {0} \
  ] $ext_bdc
  
  # Create interface connections
  connect_bd_intf_net -intf_net CIPS_0_FPD_AXI_NOC_0 [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_0] [get_bd_intf_pins cips_noc/S04_AXI]
  connect_bd_intf_net -intf_net CIPS_0_FPD_AXI_NOC_1 [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_1] [get_bd_intf_pins cips_noc/S05_AXI]
  connect_bd_intf_net -intf_net CIPS_0_FPD_CCI_NOC_0 [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_0] [get_bd_intf_pins cips_noc/S00_AXI]
  connect_bd_intf_net -intf_net CIPS_0_FPD_CCI_NOC_1 [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_1] [get_bd_intf_pins cips_noc/S01_AXI]
  connect_bd_intf_net -intf_net CIPS_0_FPD_CCI_NOC_2 [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_2] [get_bd_intf_pins cips_noc/S02_AXI]
  connect_bd_intf_net -intf_net CIPS_0_FPD_CCI_NOC_3 [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_3] [get_bd_intf_pins cips_noc/S03_AXI]
  connect_bd_intf_net -intf_net CIPS_0_LPD_AXI_NOC_0 [get_bd_intf_pins CIPS_0/LPD_AXI_NOC_0] [get_bd_intf_pins cips_noc/S06_AXI]
  connect_bd_intf_net -intf_net CIPS_0_M_AXI_GP0 [get_bd_intf_pins CIPS_0/M_AXI_FPD] [get_bd_intf_pins ext_bdc/S00_AXI]
  connect_bd_intf_net -intf_net CIPS_0_PMC_NOC_AXI_0 [get_bd_intf_pins CIPS_0/PMC_NOC_AXI_0] [get_bd_intf_pins cips_noc/S07_AXI]
  
  # connect_bd_intf_net -intf_net DDRNoc_M00_INI [get_bd_intf_pins ext_bdc/M00_INI1] [get_bd_intf_pins $default_mem/S04_INI]
  # connect_bd_intf_net -intf_net DDRNoc_M01_INI [get_bd_intf_pins ext_bdc/M01_INI1] [get_bd_intf_pins $default_mem/S05_INI]
  # connect_bd_intf_net -intf_net DDRNoc_M02_INI [get_bd_intf_pins ext_bdc/M02_INI1] [get_bd_intf_pins $default_mem/S06_INI]
  # connect_bd_intf_net -intf_net DDRNoc_M03_INI [get_bd_intf_pins ext_bdc/M03_INI1] [get_bd_intf_pins $default_mem/S07_INI]
  # connect_bd_intf_net -intf_net LPDDRNoc_M00_INI [get_bd_intf_pins ext_bdc/M00_INI] [get_bd_intf_pins $additional_mem/S04_INI]
  # connect_bd_intf_net -intf_net LPDDRNoc_M01_INI [get_bd_intf_pins ext_bdc/M01_INI] [get_bd_intf_pins $additional_mem/S05_INI]
  # connect_bd_intf_net -intf_net LPDDRNoc_M02_INI [get_bd_intf_pins ext_bdc/M02_INI] [get_bd_intf_pins $additional_mem/S06_INI]
  # connect_bd_intf_net -intf_net LPDDRNoc_M03_INI [get_bd_intf_pins ext_bdc/M03_INI] [get_bd_intf_pins $additional_mem/S07_INI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ext_bdc/M00_INI_1] [get_bd_intf_pins $additional_mem/S04_INI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ext_bdc/M01_INI_1] [get_bd_intf_pins $additional_mem/S05_INI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ext_bdc/M02_INI_1] [get_bd_intf_pins $additional_mem/S06_INI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ext_bdc/M03_INI_1] [get_bd_intf_pins $additional_mem/S07_INI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ext_bdc/M00_INI_0] [get_bd_intf_pins $default_mem/S04_INI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ext_bdc/M01_INI_0] [get_bd_intf_pins $default_mem/S05_INI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ext_bdc/M03_INI_0] [get_bd_intf_pins $default_mem/S07_INI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins ext_bdc/M02_INI_0] [get_bd_intf_pins $default_mem/S06_INI]
  
  
  
  connect_bd_intf_net -intf_net cips_noc_M00_INI [get_bd_intf_pins cips_noc/M00_INI] [get_bd_intf_pins $default_mem/S00_INI]
  connect_bd_intf_net -intf_net cips_noc_M01_INI [get_bd_intf_pins cips_noc/M01_INI] [get_bd_intf_pins $default_mem/S01_INI]
  connect_bd_intf_net -intf_net cips_noc_M02_INI [get_bd_intf_pins cips_noc/M02_INI] [get_bd_intf_pins $default_mem/S02_INI]
  connect_bd_intf_net -intf_net cips_noc_M03_INI [get_bd_intf_pins cips_noc/M03_INI] [get_bd_intf_pins $default_mem/S03_INI]
  connect_bd_intf_net -intf_net cips_noc_M04_INI [get_bd_intf_pins $additional_mem/S00_INI] [get_bd_intf_pins cips_noc/M04_INI]
  connect_bd_intf_net -intf_net cips_noc_M05_INI [get_bd_intf_pins $additional_mem/S01_INI] [get_bd_intf_pins cips_noc/M05_INI]
  connect_bd_intf_net -intf_net cips_noc_M06_INI [get_bd_intf_pins $additional_mem/S02_INI] [get_bd_intf_pins cips_noc/M06_INI]
  connect_bd_intf_net -intf_net cips_noc_M07_INI [get_bd_intf_pins $additional_mem/S03_INI] [get_bd_intf_pins cips_noc/M07_INI]
  if { $use_aie } {
  connect_bd_intf_net -intf_net cips_noc_M08_INI [get_bd_intf_pins cips_noc/M08_INI] [get_bd_intf_pins ext_bdc/S00_INI] }
  #connect_bd_intf_net -intf_net ddr4_dimm1_sma_clk_1 [get_bd_intf_ports ddr4_dimm1_sma_clk] [get_bd_intf_pins $default_mem/sys_clk0]
  #connect_bd_intf_net -intf_net lpddr4_sma_clk1_1 [get_bd_intf_ports lpddr4_sma_clk1] [get_bd_intf_pins $additional_mem/sys_clk0]
  #connect_bd_intf_net -intf_net lpddr4_sma_clk2_1 [get_bd_intf_ports lpddr4_sma_clk2] [get_bd_intf_pins $additional_mem/sys_clk1]
  #connect_bd_intf_net -intf_net noc_ddr4_CH0_DDR4_0 [get_bd_intf_ports ddr4_dimm1] [get_bd_intf_pins $default_mem/CH0_DDR4_0]
  #connect_bd_intf_net -intf_net noc_lpddr4_CH0_LPDDR4_0 [get_bd_intf_ports ch0_lpddr4_c0] [get_bd_intf_pins $additional_mem/CH0_LPDDR4_0]
  #connect_bd_intf_net -intf_net noc_lpddr4_CH0_LPDDR4_1 [get_bd_intf_ports ch0_lpddr4_c1] [get_bd_intf_pins $additional_mem/CH0_LPDDR4_1]
  #connect_bd_intf_net -intf_net noc_lpddr4_CH1_LPDDR4_0 [get_bd_intf_ports ch1_lpddr4_c0] [get_bd_intf_pins $additional_mem/CH1_LPDDR4_0]
  #connect_bd_intf_net -intf_net noc_lpddr4_CH1_LPDDR4_1 [get_bd_intf_ports ch1_lpddr4_c1] [get_bd_intf_pins $additional_mem/CH1_LPDDR4_1]

  # Create port connections
  connect_bd_net -net CIPS_0_fpd_axi_noc_axi0_clk [get_bd_pins CIPS_0/fpd_axi_noc_axi0_clk] [get_bd_pins cips_noc/aclk4]
  connect_bd_net -net CIPS_0_fpd_axi_noc_axi1_clk [get_bd_pins CIPS_0/fpd_axi_noc_axi1_clk] [get_bd_pins cips_noc/aclk5]
  connect_bd_net -net CIPS_0_fpd_cci_noc_axi0_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi0_clk] [get_bd_pins cips_noc/aclk0]
  connect_bd_net -net CIPS_0_fpd_cci_noc_axi1_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi1_clk] [get_bd_pins cips_noc/aclk1]
  connect_bd_net -net CIPS_0_fpd_cci_noc_axi2_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi2_clk] [get_bd_pins cips_noc/aclk2]
  connect_bd_net -net CIPS_0_fpd_cci_noc_axi3_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi3_clk] [get_bd_pins cips_noc/aclk3]
  connect_bd_net -net CIPS_0_lpd_axi_noc_clk [get_bd_pins CIPS_0/lpd_axi_noc_clk] [get_bd_pins cips_noc/aclk6]
  
  #connect_bd_net -net CIPS_0_pl0_ref_clk [get_bd_pins CIPS_0/pl0_ref_clk] [get_bd_pins clk_wizard_1/clk_in1]
  #connect_bd_net -net CIPS_0_pl_resetn1 [get_bd_pins CIPS_0/pl0_resetn] [get_bd_pins clk_wizard_1/resetn] [get_bd_pins IsoReset/ext_reset_in]
  
  connect_bd_net -net CIPS_0_pmc_axi_noc_axi0_clk [get_bd_pins CIPS_0/pmc_axi_noc_axi0_clk] [get_bd_pins cips_noc/aclk7]
  #connect_bd_net -net IsoReset_peripheral_aresetn [get_bd_pins IsoReset/peripheral_aresetn] [get_bd_pins ext_bdc/ext_reset_in]
  connect_bd_net -net axi_intc_0_irq [get_bd_pins ext_bdc/irq] [get_bd_pins CIPS_0/pl_ps_irq0]
  #connect_bd_net -net clk_wizard_1_clk_out1 [get_bd_pins clk_wizard_1/clk_out1] [get_bd_pins IsoReset/slowest_sync_clk] [get_bd_pins CIPS_0/m_axi_fpd_aclk] [get_bd_pins ext_bdc/clk_in1]
  #connect_bd_net -net clk_wizard_1_locked [get_bd_pins clk_wizard_1/locked] [get_bd_pins IsoReset/dcm_locked]
  connect_bd_net -net CIPS_0_pl_clk0 [get_bd_pins CIPS_0/pl0_ref_clk] [get_bd_pins CIPS_0/m_axi_fpd_aclk] [get_bd_pins ext_bdc/clk_in1]
  connect_bd_net -net CIPS_0_pl_resetn1 [get_bd_pins CIPS_0/pl0_resetn] [get_bd_pins ext_bdc/ext_reset_in]
  
   set_param project.replaceDontTouchWithKeepHierarchySoft 0
  #set_property CONFIG.LOCK_PROPAGATE {false} [get_bd_cells ext_bdc]
  assign_bd_address
  validate_bd_design
  save_bd_design
  #set_property CONFIG.LOCK_PROPAGATE {true} [get_bd_cells ext_bdc]
  #save_bd_design