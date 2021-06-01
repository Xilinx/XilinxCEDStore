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
set_param ips.useCIPSv3 1
set_property target_language Verilog [current_project]

proc create_root_design { parentCell design_name temp_options} {
puts "create_root_design"
set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]
puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"

# Create instance: CIPS_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:* CIPS_0
#apply_board_connection -board_interface "cips_fixed_io" -ip_intf "CIPS_0/FIXED_IO" -diagram $design_name
apply_board_connection -board_interface "ps_pmc_fixed_io" -ip_intf "CIPS_0/FIXED_IO" -diagram $design_name
set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom DDR_MEMORY_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 99.999992 PMC_USE_PMC_NOC_AXI0 1 PS_IRQ_USAGE {{CH0 1} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} PS_NUM_FABRIC_RESETS 1 PS_PL_CONNECTIVITY_MODE Custom PS_USE_FPD_AXI_NOC0 1 PS_USE_FPD_AXI_NOC1 1 PS_USE_FPD_CCI_NOC 1 PS_USE_M_AXI_FPD 1 PS_USE_NOC_LPD_AXI0 1 PS_USE_PMCPL_CLK0 1} CONFIG.CLOCK_MODE {Custom} CONFIG.DDR_MEMORY_MODE {Custom} CONFIG.PS_PL_CONNECTIVITY_MODE {Custom}] [get_bd_cells CIPS_0]

set_property -dict [list CONFIG.PS_PMC_CONFIG {PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI0_MASTER A72 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI1_MASTER A72 PS_GEN_IPI2_ENABLE 1 PS_GEN_IPI2_MASTER A72 PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI3_MASTER A72 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI4_MASTER A72 PS_GEN_IPI5_ENABLE 1 PS_GEN_IPI5_MASTER A72 PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI6_MASTER A72} ] [get_bd_cells CIPS_0]

 # Create instance: axi_intc_cascaded_1, and set properties
 set axi_intc_cascaded_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_cascaded_1 ]
 set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_cascaded_1
  
 set axi_intc_parent [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_parent ]
 set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_parent

 create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:* xlconcat_0
 set_property -dict [list CONFIG.NUM_PORTS {32} CONFIG.IN0_WIDTH {1}] [get_bd_cells xlconcat_0]

  # Create instance: clk_wizard_0, and set properties
  set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_0 ]
  set_property -dict [ list \
   CONFIG.CLKOUT2_DIVIDE {20.000000} \
   CONFIG.CLKOUT3_DIVIDE {10.000000} \
   CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
   CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
   CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
   CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
   CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
   CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {100.000,150,300,75,200,400,600} \
   CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
   CONFIG.CLKOUT_USED {true,true,true,true,true,true,true} \
   CONFIG.JITTER_SEL {Min_O_Jitter} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
   CONFIG.USE_LOCKED {true} \
   CONFIG.USE_PHASE_ALIGNMENT {true} \
   CONFIG.USE_RESET {true} \
 ] $clk_wizard_0

  # Create instance: psr_100mh, and set properties
  set psr_100mhz [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset psr_100mhz ]

  # Create instance: psr_150mh, and set properties
  set psr_150mhz [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset psr_150mhz ]

  # Create instance: psr_300mh, and set properties
  set psr_300mhz [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset psr_300mhz ]

  # Create instance: psr_75mh, and set properties
  set psr_75mhz [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset psr_75mhz ]

  # Create instance: psr_200mh, and set properties
  set psr_200mhz [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset psr_200mhz ]

  # Create instance: psr_400mh, and set properties
  set psr_400mhz [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset psr_400mhz ]

  # Create instance: psr_600mh, and set properties
  set psr_600mhz [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset psr_600mhz ]

  # Create instance: smartconnect_1, and set properties
  set icn_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_1 ]
  set_property -dict [ list CONFIG.NUM_CLKS {2} CONFIG.NUM_MI {6} CONFIG.NUM_SI {1} ] $icn_ctrl_1

  set icn_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_2 ]
  set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} ] $icn_ctrl_2

  set to_delete_kernel_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel_ctrl_0 ]
  set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] $to_delete_kernel_ctrl_0

  set to_delete_kernel_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel_ctrl_1 ]
  set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] $to_delete_kernel_ctrl_1

  set to_delete_kernel_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel_ctrl_2 ]
  set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] $to_delete_kernel_ctrl_2
  
  set to_delete_kernel_ctrl_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel_ctrl_3 ]
  set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] $to_delete_kernel_ctrl_3
  
  set icn_ctrl_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_3 ]
  set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} ] $icn_ctrl_3

  set icn_ctrl_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_4 ]
  set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} ] $icn_ctrl_4

  set icn_ctrl_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_5 ]
  set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} ] $icn_ctrl_5
 
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* cips_noc

set_property -dict [list CONFIG.NUM_SI {8} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {0} CONFIG.NUM_NMI {1} CONFIG.NUM_CLKS {9}] [get_bd_cells cips_noc]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S06_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S07_AXI]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S03_AXI:S02_AXI:S00_AXI:S01_AXI:S04_AXI:S07_AXI:S06_AXI:S05_AXI}] [get_bd_pins /cips_noc/aclk0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* noc_ddr4
apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "noc_ddr4/CH0_DDR4_0" -diagram $design_name 
apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "noc_ddr4/sys_clk0" -diagram $design_name 

set_property -dict [list CONFIG.NUM_SI {0} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {1} CONFIG.NUM_CLKS {0} CONFIG.NUM_MCP {4} CONFIG.MC_CHAN_REGION1 {DDR_LOW1}] [get_bd_cells noc_ddr4]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {128} write_bw {128} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /noc_ddr4/S00_INI]
connect_bd_intf_net [get_bd_intf_pins cips_noc/M00_INI] [get_bd_intf_pins noc_ddr4/S00_INI]

connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_0] [get_bd_intf_pins cips_noc/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_1] [get_bd_intf_pins cips_noc/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_2] [get_bd_intf_pins cips_noc/S02_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_3] [get_bd_intf_pins cips_noc/S03_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_0] [get_bd_intf_pins cips_noc/S04_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_1] [get_bd_intf_pins cips_noc/S05_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/LPD_AXI_NOC_0] [get_bd_intf_pins cips_noc/S06_AXI]
connect_bd_intf_net [get_bd_intf_pins CIPS_0/PMC_NOC_AXI_0] [get_bd_intf_pins cips_noc/S07_AXI]
connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi0_clk] [get_bd_pins cips_noc/aclk1]
connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi1_clk] [get_bd_pins cips_noc/aclk2]
connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi2_clk] [get_bd_pins cips_noc/aclk3]
connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi3_clk] [get_bd_pins cips_noc/aclk4]
connect_bd_net [get_bd_pins CIPS_0/fpd_axi_noc_axi0_clk] [get_bd_pins cips_noc/aclk5]
connect_bd_net [get_bd_pins CIPS_0/fpd_axi_noc_axi1_clk] [get_bd_pins cips_noc/aclk6]
connect_bd_net [get_bd_pins CIPS_0/lpd_axi_noc_clk] [get_bd_pins cips_noc/aclk7]
connect_bd_net [get_bd_pins CIPS_0/pmc_axi_noc_axi0_clk] [get_bd_pins cips_noc/aclk8]

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Clk {/CIPS_0/pl0_ref_clk (99 MHz)} Manual_Source {Auto}}  [get_bd_pins clk_wizard_0/clk_in1]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/CIPS_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins clk_wizard_0/resetn]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/CIPS_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins psr_75mhz/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out4 (75 MHz)} Freq {75} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins psr_75mhz/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/CIPS_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins psr_100mhz/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins psr_100mhz/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/CIPS_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins psr_150mhz/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out2 (150 MHz)} Freq {150} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins psr_150mhz/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/CIPS_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins psr_200mhz/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out5 (200 MHz)} Freq {200} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins psr_200mhz/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/CIPS_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins psr_300mhz/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out3 (300 MHz)} Freq {300} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins psr_300mhz/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/CIPS_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins psr_400mhz/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out6 (400 MHz)} Freq {400} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins psr_400mhz/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/CIPS_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins psr_600mhz/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out7 (600 MHz)} Freq {600} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins psr_600mhz/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/CIPS_0/M_AXI_FPD} Slave {/axi_intc_cascaded_1/s_axi} ddr_seg {Auto} intc_ip {/icn_ctrl_1} master_apm {0}}  [get_bd_intf_pins axi_intc_cascaded_1/s_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/CIPS_0/M_AXI_FPD} Slave {/axi_intc_parent/s_axi} ddr_seg {Auto} intc_ip {/icn_ctrl_1} master_apm {0}}  [get_bd_intf_pins axi_intc_parent/s_axi]
#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/CIPS_0/M_AXI_FPD} Slave {/to_delete_kernel_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {/icn_ctrl_2} master_apm {0}}  [get_bd_intf_pins to_delete_kernel_ctrl_0/S_AXI]

connect_bd_intf_net [get_bd_intf_pins icn_ctrl_1/M02_AXI] [get_bd_intf_pins icn_ctrl_2/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins icn_ctrl_1/M03_AXI] [get_bd_intf_pins icn_ctrl_3/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins icn_ctrl_1/M04_AXI] [get_bd_intf_pins icn_ctrl_4/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins icn_ctrl_1/M05_AXI] [get_bd_intf_pins icn_ctrl_5/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins icn_ctrl_2/M00_AXI] [get_bd_intf_pins to_delete_kernel_ctrl_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins icn_ctrl_3/M00_AXI] [get_bd_intf_pins to_delete_kernel_ctrl_1/S_AXI]
connect_bd_intf_net [get_bd_intf_pins icn_ctrl_4/M00_AXI] [get_bd_intf_pins to_delete_kernel_ctrl_2/S_AXI]
connect_bd_intf_net [get_bd_intf_pins icn_ctrl_5/M00_AXI] [get_bd_intf_pins to_delete_kernel_ctrl_3/S_AXI]

apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins to_delete_kernel_ctrl_0/aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins to_delete_kernel_ctrl_1/aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins to_delete_kernel_ctrl_2/aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins to_delete_kernel_ctrl_3/aclk]

connect_bd_net [get_bd_pins icn_ctrl_2/aresetn] [get_bd_pins psr_100mhz/peripheral_aresetn]
connect_bd_net [get_bd_pins icn_ctrl_3/aresetn] [get_bd_pins psr_100mhz/peripheral_aresetn]
connect_bd_net [get_bd_pins icn_ctrl_4/aresetn] [get_bd_pins psr_100mhz/peripheral_aresetn]
connect_bd_net [get_bd_pins icn_ctrl_5/aresetn] [get_bd_pins psr_100mhz/peripheral_aresetn]

connect_bd_net [get_bd_pins cips_noc/aclk0] [get_bd_pins clk_wizard_0/clk_out1]
connect_bd_net [get_bd_pins icn_ctrl_1/aclk1] [get_bd_pins clk_wizard_0/clk_out1]

connect_bd_net [get_bd_pins axi_intc_cascaded_1/irq] [get_bd_pins xlconcat_0/In31]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins axi_intc_parent/intr]
connect_bd_net [get_bd_pins axi_intc_parent/irq] [get_bd_pins CIPS_0/pl_ps_irq0]

connect_bd_net [get_bd_pins clk_wizard_0/locked] [get_bd_pins psr_150mhz/dcm_locked]
connect_bd_net [get_bd_pins psr_300mhz/dcm_locked] [get_bd_pins clk_wizard_0/locked]
connect_bd_net [get_bd_pins psr_200mhz/dcm_locked] [get_bd_pins clk_wizard_0/locked]
connect_bd_net [get_bd_pins psr_400mhz/dcm_locked] [get_bd_pins clk_wizard_0/locked]
connect_bd_net [get_bd_pins psr_600mhz/dcm_locked] [get_bd_pins clk_wizard_0/locked]
connect_bd_net [get_bd_pins psr_75mhz/dcm_locked] [get_bd_pins clk_wizard_0/locked]

if [regexp "vck" $board_name] {
set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_CLKS {10}] [get_bd_cells cips_noc]
set_property -dict [list CONFIG.CATEGORY {aie}] [get_bd_intf_pins /cips_noc/M00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S07_AXI]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {M00_AXI}] [get_bd_pins /cips_noc/aclk9]

# Create instance: ai_engine_0, and set properties
set ai_engine_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ai_engine ai_engine_0 ]
 set_property -dict [ list \
  CONFIG.CLK_NAMES {} \
  CONFIG.NAME_MI_AXI {} \
  CONFIG.NAME_MI_AXIS {} \
  CONFIG.NAME_SI_AXI {S00_AXI,} \
  CONFIG.NAME_SI_AXIS {} \
  CONFIG.NUM_CLKS {0} \
  CONFIG.NUM_MI_AXI {0} \
  CONFIG.NUM_MI_AXIS {0} \
  CONFIG.NUM_SI_AXI {1} \
  CONFIG.NUM_SI_AXIS {0} \
] $ai_engine_0
set_property -dict [ list CONFIG.CATEGORY {NOC} ] [get_bd_intf_pins /ai_engine_0/S00_AXI]
  
connect_bd_intf_net [get_bd_intf_pins cips_noc/M00_AXI] [get_bd_intf_pins ai_engine_0/S00_AXI]
connect_bd_net [get_bd_pins ai_engine_0/s00_axi_aclk] [get_bd_pins cips_noc/aclk9] 

assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
}

if { ([lsearch $temp_options "true"] != -1 )} {
puts "INFO: lpddr4 selected"
if [regexp "vck" $board_name] {
set_property -dict [list CONFIG.NUM_NMI {2}] [get_bd_cells cips_noc]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S05_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S06_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S07_AXI]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {}] [get_bd_pins /cips_noc/aclk9]
} else {
set_property -dict [list CONFIG.NUM_NMI {2}] [get_bd_cells cips_noc]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S05_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S06_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S07_AXI]
}
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* noc_lpddr4
apply_board_connection -board_interface "ch0_lpddr4_c0" -ip_intf "noc_lpddr4/CH0_LPDDR4_0" -diagram $design_name 
apply_board_connection -board_interface "ch1_lpddr4_c0" -ip_intf "noc_lpddr4/CH1_LPDDR4_0" -diagram $design_name 
apply_board_connection -board_interface "lpddr4_sma_clk1" -ip_intf "noc_lpddr4/sys_clk0" -diagram $design_name 

apply_board_connection -board_interface "ch0_lpddr4_c1" -ip_intf "/noc_lpddr4/CH0_LPDDR4_1" -diagram $design_name 
apply_board_connection -board_interface "ch1_lpddr4_c1" -ip_intf "/noc_lpddr4/CH1_LPDDR4_1" -diagram $design_name 
apply_board_connection -board_interface "lpddr4_sma_clk2" -ip_intf "/noc_lpddr4/sys_clk1" -diagram $design_name 

set_property -dict [list CONFIG.NUM_SI {0} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {1} CONFIG.NUM_CLKS {0} CONFIG.MC_CHAN_REGION0 {DDR_CH1}] [get_bd_cells noc_lpddr4]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /noc_lpddr4/S00_INI]

connect_bd_intf_net [get_bd_intf_pins cips_noc/M01_INI] [get_bd_intf_pins noc_lpddr4/S00_INI] 

assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
} 
assign_bd_address -offset 0xA4000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs axi_intc_cascaded_1/S_AXI/Reg] -force
assign_bd_address -offset 0xA5000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs axi_intc_parent/S_AXI/Reg] -force
assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW0] -force
assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW0] -force
assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW0] -force
assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW0] -force
assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW0] -force
assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW0] -force
assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW0] -force
assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW0] -force

assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW1] -force
assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW1] -force
assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW1] -force
assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW1] -force
assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW1] -force
assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW1] -force
assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW1] -force
assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs noc_ddr4/S00_INI/C0_DDR_LOW1] -force

exclude_bd_addr_seg [get_bd_addr_segs to_delete_kernel_ctrl_0/S_AXI/Reg] -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD]
exclude_bd_addr_seg [get_bd_addr_segs to_delete_kernel_ctrl_1/S_AXI/Reg] -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD]
exclude_bd_addr_seg [get_bd_addr_segs to_delete_kernel_ctrl_2/S_AXI/Reg] -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD]
exclude_bd_addr_seg [get_bd_addr_segs to_delete_kernel_ctrl_3/S_AXI/Reg] -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD]

set_param project.replaceDontTouchWithKeepHierarchySoft 0
}

##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $design_name $options 
	
	#open_bd_design [get_bd_files $design_name]
	set board_name [get_property BOARD_NAME [current_board]]
	
	# Create PFM attributes
	if [regexp "vmk" $board_name] {
	puts "INFO: Creating extensible_platform for VMK_180"
	set_property PFM_NAME {xilinx.com:xd:xilinx_vmk180_base:1.0} [get_files [current_bd_design].bd]
	} else {
	puts "INFO: Creating extensible_platform for VCK_190"
	set_property PFM_NAME {xilinx.com:xd:xilinx_vck190_base:1.0} [get_files [current_bd_design].bd] }
	
	set_property PFM.AXI_PORT {M00_AXI {memport "NOC_MASTER"}} [get_bd_cells /cips_noc]
	set_property PFM.IRQ {intr {id 0 range 32}}  [get_bd_cells /axi_intc_cascaded_1]
	set_property PFM.IRQ {In0 {id 32} In1 {id 33} In2 {id 34} In3 {id 35} In4 {id 36} In5 {id 37} In6 {id 38} In7 {id 39} In8 {id 40} \
	In9 {id 41} In10 {id 42} In11 {id 43} In12 {id 44} In13 {id 45} In14 {id 46} In15 {id 47} In16 {id 48} In17 {id 49} In18 {id 50} \
	In19 {id 51} In20 {id 52} In21 {id 53} In22 {id 54} In23 {id 55} In24 {id 56} In25 {id 57} In26 {id 58} In27 {id 59} In28 {id 60} \
	In29 {id 61} In30 {id 62}} [get_bd_cells /xlconcat_0]
	
	set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "DDR"} S01_AXI {memport "S_AXI_NOC" sptag "DDR"} S02_AXI {memport "S_AXI_NOC" sptag "DDR"} S03_AXI {memport "S_AXI_NOC" sptag "DDR"} S04_AXI {memport "S_AXI_NOC" sptag "DDR"} S05_AXI {memport "S_AXI_NOC" sptag "DDR"} S06_AXI {memport "S_AXI_NOC" sptag "DDR"} S07_AXI {memport "S_AXI_NOC" sptag "DDR"} S08_AXI {memport "S_AXI_NOC" sptag "DDR"} S09_AXI {memport "S_AXI_NOC" sptag "DDR"} S10_AXI {memport "S_AXI_NOC" sptag "DDR"} S11_AXI {memport "S_AXI_NOC" sptag "DDR"} S12_AXI {memport "S_AXI_NOC" sptag "DDR"} S13_AXI {memport "S_AXI_NOC" sptag "DDR"} S14_AXI {memport "S_AXI_NOC" sptag "DDR"} S15_AXI {memport "S_AXI_NOC" sptag "DDR"} S16_AXI {memport "S_AXI_NOC" sptag "DDR"} S17_AXI {memport "S_AXI_NOC" sptag "DDR"} S18_AXI {memport "S_AXI_NOC" sptag "DDR"} S19_AXI {memport "S_AXI_NOC" sptag "DDR"} S20_AXI {memport "S_AXI_NOC" sptag "DDR"} S21_AXI {memport "S_AXI_NOC" sptag "DDR"} S22_AXI {memport "S_AXI_NOC" sptag "DDR"} S23_AXI {memport "S_AXI_NOC" sptag "DDR"} S24_AXI {memport "S_AXI_NOC" sptag "DDR"} S25_AXI {memport "S_AXI_NOC" sptag "DDR"} S26_AXI {memport "S_AXI_NOC" sptag "DDR"} S27_AXI {memport "S_AXI_NOC" sptag "DDR"}} [get_bd_cells /noc_ddr4]
	
	set_property PFM.CLOCK {clk_out1 {id "1" is_default "false" proc_sys_reset "psr_100mhz" status "fixed"} clk_out2 {id "0" is_default "true" proc_sys_reset "/psr_150mhz" status "fixed"} clk_out3 {id "2" is_default "false" proc_sys_reset "/psr_300mhz" status "fixed"} clk_out4 {id "3" is_default "false" proc_sys_reset "psr_75mhz" status "fixed"} clk_out5 {id "4" is_default "false" proc_sys_reset "/psr_200mhz" status "fixed"} clk_out6 {id "5" is_default "false" proc_sys_reset "/psr_400mhz" status "fixed"} clk_out7 {id "6" is_default "false" proc_sys_reset "/psr_600mhz" status "fixed"}} [get_bd_cells /clk_wizard_0]
	
	set_property PFM.AXI_PORT {M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells /icn_ctrl_1]
	
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells /icn_ctrl_2]
	
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells /icn_ctrl_3]
	
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells /icn_ctrl_4]
	
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells /icn_ctrl_5]

	catch { set lpddr [get_bd_cells /noc_lpddr4]
	if { $lpddr == "/noc_lpddr4" } {
	puts "INFO: lpddr4 selected"
	set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S01_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S02_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S03_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S04_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S05_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S06_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S07_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S08_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S09_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S10_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S11_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S12_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S13_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S14_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S15_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S16_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S17_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S18_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S19_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S20_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S21_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S22_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S23_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S24_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S25_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S26_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S27_AXI {memport "S_AXI_NOC" sptag "LPDDR"}} [get_bd_cells /noc_lpddr4]
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells /noc_lpddr4] } }
	
	puts "INFO: Platform creation completed!"

	set_property platform.extensible true [current_project]
	# Add USER_COMMENTS on $design_name
	set_property USER_COMMENTS.comment0 "An example extendable platform design" [get_bd_designs $design_name]
	
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells /CIPS_0]
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells /cips_noc]
	#set_property SELECTED_SIM_MODEL tlm [get_bd_cells /noc_lpddr4]
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells /noc_ddr4]
	
	set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] [get_bd_cells clk_wizard_0]
	#assign_bd_address
	save_bd_design
	validate_bd_design
	regenerate_bd_layout
	open_bd_design [get_bd_files $design_name]
	make_wrapper -files [get_files $design_name.bd] -top -import -quiet
	puts "INFO: End of create_root_design"
}