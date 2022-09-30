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

set_property target_language Verilog [current_project]

proc create_root_design { parentCell design_name temp_options} {

puts "create_root_design"
set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]
puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"

# Create instance: versal_cips_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:* versal_cips_0
#apply_board_connection -board_interface "cips_fixed_io" -ip_intf "versal_cips_0/FIXED_IO" -diagram $design_name
apply_board_connection -board_interface "ps_pmc_fixed_io" -ip_intf "versal_cips_0/FIXED_IO" -diagram $design_name 

set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom DDR_MEMORY_MODE Custom PMC_USE_PMC_NOC_AXI0 1 PS_NUM_FABRIC_RESETS 1 PS_USE_FPD_CCI_NOC 1 PS_USE_NOC_LPD_AXI0 1 PS_USE_PMCPL_CLK0 1} CONFIG.CLOCK_MODE {Custom} CONFIG.DDR_MEMORY_MODE {Custom}] [get_bd_cells versal_cips_0]

set_property -dict [list CONFIG.PS_PMC_CONFIG {PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI0_MASTER A72 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI1_MASTER A72 PS_GEN_IPI2_ENABLE 1 PS_GEN_IPI2_MASTER A72 PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI3_MASTER A72 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI4_MASTER A72 PS_GEN_IPI5_ENABLE 1 PS_GEN_IPI5_MASTER A72 PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI6_MASTER A72} ] [get_bd_cells versal_cips_0]

# Create instance: axi_noc_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* axi_noc_0
if {[regexp "vpk120" $board_name]||[regexp "vpk180" $board_name]||[regexp "vek280" $board_name]} {
	
	apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "axi_noc_0/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "axi_noc_0/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "axi_noc_0/sys_clk0" -diagram $design_name 
	} else {
apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "axi_noc_0/CH0_DDR4_0" -diagram $design_name 
apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "axi_noc_0/sys_clk0" -diagram $design_name }

set_property -dict [list CONFIG.NUM_SI {6} CONFIG.NUM_MI {2} CONFIG.NUM_CLKS {7}] [get_bd_cells axi_noc_0]
set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {5} write_bw {5}} }] [get_bd_intf_pins /axi_noc_0/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S05_AXI]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_AXI}] [get_bd_pins /axi_noc_0/aclk0]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S01_AXI}] [get_bd_pins /axi_noc_0/aclk1]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S02_AXI}] [get_bd_pins /axi_noc_0/aclk2]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S03_AXI}] [get_bd_pins /axi_noc_0/aclk3]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S04_AXI}] [get_bd_pins /axi_noc_0/aclk4]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S05_AXI}] [get_bd_pins /axi_noc_0/aclk5]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {M01_AXI:M00_AXI}] [get_bd_pins /axi_noc_0/aclk6]

# Create instance: axi_bram_ctrl_0, and set properties
set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]

# Create instance: axi_bram_ctrl_0_bram, and set properties
set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_0_bram ]
set_property -dict [ list CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} ] $axi_bram_ctrl_0_bram
  
# Create instance: axi_dbg_hub_0, and set properties
set axi_dbg_hub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dbg_hub axi_dbg_hub_0 ]
set_property -dict [ list CONFIG.C_AXI_DATA_WIDTH {128} CONFIG.C_NUM_DEBUG_CORES {0} ] $axi_dbg_hub_0

# Create instance: axis_ila_0, and set properties
set axis_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila axis_ila_0 ]
set_property -dict [ list \
 CONFIG.C_MON_TYPE {Interface_Monitor} \
 CONFIG.C_SLOT_0_APC_EN {0} \
 CONFIG.C_SLOT_0_AXI_AR_SEL_DATA {1} \
 CONFIG.C_SLOT_0_AXI_AR_SEL_TRIG {1} \
 CONFIG.C_SLOT_0_AXI_AW_SEL_DATA {1} \
 CONFIG.C_SLOT_0_AXI_AW_SEL_TRIG {1} \
 CONFIG.C_SLOT_0_AXI_B_SEL_DATA {1} \
 CONFIG.C_SLOT_0_AXI_B_SEL_TRIG {1} \
 CONFIG.C_SLOT_0_AXI_R_SEL_DATA {1} \
 CONFIG.C_SLOT_0_AXI_R_SEL_TRIG {1} \
 CONFIG.C_SLOT_0_AXI_W_SEL_DATA {1} \
 CONFIG.C_SLOT_0_AXI_W_SEL_TRIG {1} \
 ] $axis_ila_0
 
# Create instance: c_counter_binary_0, and set properties
set c_counter_binary_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary c_counter_binary_0 ]
set_property -dict [ list CONFIG.Load {true} CONFIG.SSET {true} ] $c_counter_binary_0
  
# Create instance: clk_wizard_0, and set properties
set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_0 ]

# Create instance: proc_sys_reset_0, and set properties
set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

# Create instance: axis_vio_0, and set properties
set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio axis_vio_0 ]
set_property -dict [ list CONFIG.C_NUM_PROBE_OUT {3} CONFIG.C_PROBE_IN0_WIDTH {16} CONFIG.C_PROBE_OUT2_WIDTH {16} ] $axis_vio_0

connect_bd_intf_net [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_0/S00_AXI]

connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0] [get_bd_intf_pins axi_noc_0/S02_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1] [get_bd_intf_pins axi_noc_0/S03_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2] [get_bd_intf_pins axi_noc_0/S04_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3] [get_bd_intf_pins axi_noc_0/S05_AXI]

connect_bd_net [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk] [get_bd_pins axi_noc_0/aclk0]
connect_bd_net [get_bd_pins versal_cips_0/lpd_axi_noc_clk] [get_bd_pins axi_noc_0/aclk1]
connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk] [get_bd_pins axi_noc_0/aclk2]
connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk] [get_bd_pins axi_noc_0/aclk3]
connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk] [get_bd_pins axi_noc_0/aclk4]
connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk] [get_bd_pins axi_noc_0/aclk5]

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Clk {/versal_cips_0/pl0_ref_clk (333 MHz)} Manual_Source {Auto}}  [get_bd_pins clk_wizard_0/clk_in1]
apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/versal_cips_0/pmc_axi_noc_axi0_clk (400 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/versal_cips_0/PMC_NOC_AXI_0} Slave {/axi_dbg_hub_0/S_AXI} ddr_seg {Auto} intc_ip {/axi_noc_0} master_apm {0}}  [get_bd_intf_pins axi_dbg_hub_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/versal_cips_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins c_counter_binary_0/CLK]

connect_bd_net [get_bd_pins axis_vio_0/probe_in0] [get_bd_pins c_counter_binary_0/Q]
connect_bd_net [get_bd_pins axis_vio_0/probe_out0] [get_bd_pins c_counter_binary_0/SSET]
connect_bd_net [get_bd_pins axis_vio_0/probe_out1] [get_bd_pins c_counter_binary_0/LOAD]
connect_bd_net [get_bd_pins axis_vio_0/probe_out2] [get_bd_pins c_counter_binary_0/L]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_noc_0/M01_AXI]
connect_bd_intf_net [get_bd_intf_pins axis_ila_0/SLOT_0_AXI] [get_bd_intf_pins axi_noc_0/M01_AXI]

apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axis_vio_0/clk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axis_ila_0/clk]

set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {axi_noc_0_M01_AXI}]
set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] [get_bd_cells clk_wizard_0]

}
##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $design_name $options 

assign_bd_address
save_bd_design
validate_bd_design
regenerate_bd_layout
open_bd_design [get_bd_files $design_name]
make_wrapper -files [get_files $design_name.bd] -top -import
puts "INFO: End of create_root_design"
}