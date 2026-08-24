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

# Create interface ports
set sys_clk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_0 ]
set_property -dict [ list \
  CONFIG.FREQ_HZ {400000000} \
 ] $sys_clk0_0

set CH0_DDR4_0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 CH0_DDR4_0_0 ]

if { $use_lpddr } {
  set CH0_LPDDR4_0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 CH0_LPDDR4_0_0 ]

  set sys_clk0_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_1 ]
  set_property -dict [ list \
    CONFIG.FREQ_HZ {100751000} \
  ] $sys_clk0_1

  set CH1_LPDDR4_0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 CH1_LPDDR4_0_0 ]
}

# Create ports

# Create instance: CIPS_0, and set properties
set CIPS_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips CIPS_0 ]
apply_bd_automation -rule xilinx.com:bd_rule:cips -config { board_preset {No} boot_config {JTAG} configure_noc {Add new AXI NoC} debug_config {Custom} design_flow {Full System} mc_type {None} num_mc {1} pl_clocks {None} pl_resets {None}}  [get_bd_cells CIPS_0]

set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom DDR_MEMORY_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 99.999992 PMC_USE_PMC_NOC_AXI0 1 PS_IRQ_USAGE {{CH0 1} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} PS_NUM_FABRIC_RESETS 1 PS_PL_CONNECTIVITY_MODE Custom PS_USE_FPD_AXI_NOC0 1 PS_USE_FPD_AXI_NOC1 1 PS_USE_FPD_CCI_NOC 1 PS_USE_M_AXI_FPD 1 PS_USE_NOC_LPD_AXI0 1 PS_USE_PMCPL_CLK0 1 } CONFIG.CLOCK_MODE {Custom} CONFIG.DDR_MEMORY_MODE {Custom} CONFIG.PS_PL_CONNECTIVITY_MODE {Custom}] [get_bd_cells CIPS_0]
set_property -dict [list CONFIG.PS_PMC_CONFIG {PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI0_MASTER A72 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI1_MASTER A72 PS_GEN_IPI2_ENABLE 1 PS_GEN_IPI2_MASTER A72 PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI3_MASTER A72 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI4_MASTER A72 PS_GEN_IPI5_ENABLE 1 PS_GEN_IPI5_MASTER A72 PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI6_MASTER A72} ] [get_bd_cells CIPS_0]
set_property -dict [list CONFIG.PS_PMC_CONFIG { PMC_SD1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 11}}} PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 1}}} PS_TTC0_PERIPHERAL_ENABLE {1}}] [get_bd_cells CIPS_0]


set slr_cnt [get_property SLRS [get_parts [get_property PART [current_project]]]]
if { $slr_cnt > 1 } {
  set_property CONFIG.PS_PMC_CONFIG [subst { PMC_USE_PMC_NOC_AXI[ format %d [expr $slr_cnt - 1]] {1} SLR[format %d [expr $slr_cnt - 1]]_PMC_CRP_HSM0_REF_CTRL_FREQMHZ {33.333} }] [get_bd_cells CIPS_0]
}

# Create instance: cips_noc, and set properties
set cips_noc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc cips_noc ]
set_property -dict [list CONFIG.NUM_SI {8} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {0} CONFIG.NUM_NMI {1} CONFIG.NUM_CLKS {9}] [get_bd_cells cips_noc]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S06_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S07_AXI]
#set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S03_AXI:S02_AXI:S00_AXI:S01_AXI:S04_AXI:S07_AXI:S06_AXI:S05_AXI}] [get_bd_pins /cips_noc/aclk0]

if { $slr_cnt > 1 } {
		
  set_property -dict [list CONFIG.NUM_CLKS {10} CONFIG.NUM_SI {9} ] [get_bd_cells cips_noc]
  set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /cips_noc/S08_AXI]

  connect_bd_intf_net [get_bd_intf_pins CIPS_0/PMC_NOC_AXI_[format %d [expr $slr_cnt - 1]]] [get_bd_intf_pins cips_noc/S08_AXI]
  connect_bd_net [get_bd_pins CIPS_0/pmc_axi_noc_axi[format %d [expr $slr_cnt - 1]]_clk] [get_bd_pins cips_noc/aclk9]

}


if {(($use_lpddr)&&(!$use_aie))||((!$use_lpddr)&&($use_aie)) } {
  set_property -dict [list CONFIG.NUM_CLKS {9} CONFIG.NUM_MI {0} CONFIG.NUM_NMI {2} CONFIG.NUM_NSI {0} CONFIG.NUM_SI {8} ] $cips_noc
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_cci} ] [get_bd_intf_pins /cips_noc/S00_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_cci} ] [get_bd_intf_pins /cips_noc/S01_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_cci} ] [get_bd_intf_pins /cips_noc/S02_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_cci} ] [get_bd_intf_pins /cips_noc/S03_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_nci} ] [get_bd_intf_pins /cips_noc/S04_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_nci} ] [get_bd_intf_pins /cips_noc/S05_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_rpu} ] [get_bd_intf_pins /cips_noc/S06_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_pmc} ] [get_bd_intf_pins /cips_noc/S07_AXI]
} 

if {($use_lpddr)&&($use_aie) } {
  set_property -dict [list CONFIG.NUM_CLKS {9} CONFIG.NUM_MI {0} CONFIG.NUM_NMI {3} CONFIG.NUM_NSI {0} CONFIG.NUM_SI {8} ] $cips_noc
  set_property -dict [ list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}  CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_cci} ] [get_bd_intf_pins cips_noc/S00_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_cci} ] [get_bd_intf_pins cips_noc/S01_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_cci} ] [get_bd_intf_pins /cips_noc/S02_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_cci} ] [get_bd_intf_pins /cips_noc/S03_AXI] 
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_nci} ] [get_bd_intf_pins /cips_noc/S04_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_nci} ] [get_bd_intf_pins /cips_noc/S05_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_rpu} ] [get_bd_intf_pins /cips_noc/S06_AXI]
  set_property -dict [ list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}} CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_pmc} ] [get_bd_intf_pins cips_noc/S07_AXI]
}

set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {} ] [get_bd_pins /cips_noc/aclk0]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S00_AXI} ] [get_bd_pins /cips_noc/aclk1]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S01_AXI} ] [get_bd_pins /cips_noc/aclk2]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S02_AXI} ] [get_bd_pins /cips_noc/aclk3]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S03_AXI} ] [get_bd_pins /cips_noc/aclk4]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S04_AXI}] [get_bd_pins /cips_noc/aclk5]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S05_AXI} ] [get_bd_pins /cips_noc/aclk6]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S06_AXI} ] [get_bd_pins /cips_noc/aclk7]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S07_AXI} ] [get_bd_pins /cips_noc/aclk8]

# Create instance: noc_ddr4, and set properties
set noc_ddr4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc noc_ddr4 ]
set_property -dict [list \
  CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
  CONFIG.NUM_CLKS {0} \
  CONFIG.NUM_MC {1} \
  CONFIG.NUM_MCP {4} \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {2} \
  CONFIG.NUM_SI {0} \
  ] $noc_ddr4


set_property -dict [ list \
  CONFIG.CONNECTIONS {MC_0 {read_bw {128} write_bw {128} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /noc_ddr4/S00_INI]

set_property -dict [ list \
  CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /noc_ddr4/S01_INI]

if { $use_lpddr } {
  # Create instance: noc_lpddr4, and set properties
  set noc_lpddr4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc noc_lpddr4 ]
  set_property -dict [list \
    CONFIG.CONTROLLERTYPE {LPDDR4_SDRAM} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH1} \
    CONFIG.MC_NO_CHANNELS {Dual} \
    CONFIG.NUM_CLKS {0} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NSI {2} \
    CONFIG.NUM_SI {0} \
  ] $noc_lpddr4


  set_property -dict [ list \
    CONFIG.CONNECTIONS {MC_0 {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} \
  ] [get_bd_intf_pins /noc_lpddr4/S00_INI]

  set_property -dict [ list \
    CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
  ] [get_bd_intf_pins /noc_lpddr4/S01_INI]
}

# Create instance: ext_bdc, and set properties
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
connect_bd_intf_net -intf_net bdc_M00_INI_0 [get_bd_intf_pins ext_bdc/M00_INI_0] [get_bd_intf_pins noc_ddr4/S01_INI]
connect_bd_intf_net -intf_net cips_noc_M00_INI [get_bd_intf_pins cips_noc/M00_INI] [get_bd_intf_pins noc_ddr4/S00_INI]

if { $use_lpddr } {
  connect_bd_intf_net -intf_net bdc_M00_INI_1 [get_bd_intf_pins ext_bdc/M00_INI_1] [get_bd_intf_pins noc_lpddr4/S01_INI]
  connect_bd_intf_net -intf_net cips_noc_M01_INI [get_bd_intf_pins cips_noc/M01_INI] [get_bd_intf_pins noc_lpddr4/S00_INI]
}
  
if {$use_aie} {
  if { $use_lpddr } {
    connect_bd_intf_net -intf_net cips_noc_M02_INI [get_bd_intf_pins cips_noc/M02_INI] [get_bd_intf_pins ext_bdc/S00_INI]
  } else {
    connect_bd_intf_net -intf_net cips_noc_M01_INI [get_bd_intf_pins cips_noc/M01_INI] [get_bd_intf_pins ext_bdc/S00_INI]
  }
}
  
connect_bd_intf_net -intf_net noc_ddr4_CH0_DDR4_0 [get_bd_intf_ports CH0_DDR4_0_0] [get_bd_intf_pins noc_ddr4/CH0_DDR4_0]
connect_bd_intf_net -intf_net sys_clk0_0_1 [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins noc_ddr4/sys_clk0]

if { $use_lpddr } {
  connect_bd_intf_net -intf_net noc_lpddr4_CH0_LPDDR4_0 [get_bd_intf_ports CH0_LPDDR4_0_0] [get_bd_intf_pins noc_lpddr4/CH0_LPDDR4_0]
  connect_bd_intf_net -intf_net noc_lpddr4_CH1_LPDDR4_0 [get_bd_intf_ports CH1_LPDDR4_0_0] [get_bd_intf_pins noc_lpddr4/CH1_LPDDR4_0]
  connect_bd_intf_net -intf_net sys_clk0_1_1 [get_bd_intf_ports sys_clk0_1] [get_bd_intf_pins noc_lpddr4/sys_clk0]
}
	
# Create port connections
connect_bd_net -net CIPS_0_fpd_axi_noc_axi0_clk [get_bd_pins CIPS_0/fpd_axi_noc_axi0_clk] [get_bd_pins cips_noc/aclk5]
connect_bd_net -net CIPS_0_fpd_axi_noc_axi1_clk [get_bd_pins CIPS_0/fpd_axi_noc_axi1_clk] [get_bd_pins cips_noc/aclk6]
connect_bd_net -net CIPS_0_fpd_cci_noc_axi0_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi0_clk] [get_bd_pins cips_noc/aclk1]
connect_bd_net -net CIPS_0_fpd_cci_noc_axi1_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi1_clk] [get_bd_pins cips_noc/aclk2]
connect_bd_net -net CIPS_0_fpd_cci_noc_axi2_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi2_clk] [get_bd_pins cips_noc/aclk3]
connect_bd_net -net CIPS_0_fpd_cci_noc_axi3_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi3_clk] [get_bd_pins cips_noc/aclk4]
connect_bd_net -net CIPS_0_lpd_axi_noc_clk [get_bd_pins CIPS_0/lpd_axi_noc_clk] [get_bd_pins cips_noc/aclk7]
connect_bd_net -net CIPS_0_pl_clk0 [get_bd_pins CIPS_0/pl0_ref_clk] [get_bd_pins cips_noc/aclk0] [get_bd_pins CIPS_0/m_axi_fpd_aclk] [get_bd_pins ext_bdc/clk_in1]
connect_bd_net -net CIPS_0_pl_resetn1 [get_bd_pins CIPS_0/pl0_resetn] [get_bd_pins ext_bdc/resetn]
connect_bd_net -net CIPS_0_pmc_axi_noc_axi0_clk [get_bd_pins CIPS_0/pmc_axi_noc_axi0_clk] [get_bd_pins cips_noc/aclk8]
connect_bd_net -net axi_intc_0_irq [get_bd_pins ext_bdc/irq] [get_bd_pins CIPS_0/pl_ps_irq0]

if { $slr_cnt > 1 } {
	
  set_property -dict [list CONFIG.NUM_CLKS {10} CONFIG.NUM_SI {9} ] [get_bd_cells cips_noc]
  set_property -dict [list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /cips_noc/S00_AXI]
  set_property -dict [list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /cips_noc/S01_AXI]
  set_property -dict [list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /cips_noc/S02_AXI]
  set_property -dict [list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /cips_noc/S03_AXI]
  set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /cips_noc/S04_AXI]
  set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /cips_noc/S05_AXI]
  set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /cips_noc/S06_AXI]
  set_property -dict [list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /cips_noc/S07_AXI]
  set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500}} M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /cips_noc/S08_AXI]
      

  connect_bd_intf_net [get_bd_intf_pins CIPS_0/PMC_NOC_AXI_[format %d [expr $slr_cnt - 1]]] [get_bd_intf_pins cips_noc/S08_AXI]
  connect_bd_net [get_bd_pins CIPS_0/pmc_axi_noc_axi[format %d [expr $slr_cnt - 1]]_clk] [get_bd_pins cips_noc/aclk9]

}

if { $use_aie && ($slr_cnt > 1) } {
  set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128} initial_boot {true}} M00_INI {read_bw {500} write_bw {500} initial_boot {true}}}] [get_bd_intf_pins /cips_noc/S07_AXI]
}

assign_bd_address
validate_bd_design
save_bd_design



