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

variable currentDir

set_property target_language Verilog [current_project]
set_property "simulator_language" "Mixed" [current_project]

proc create_root_design {currentDir design_name temp_options } {

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

set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom DDR_MEMORY_MODE Custom PMC_USE_PMC_NOC_AXI0 1 PS_IRQ_USAGE {{CH0 0} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 1} {CH9 0}} PS_NUM_FABRIC_RESETS 1 PS_PL_CONNECTIVITY_MODE Custom PS_USE_FPD_CCI_NOC 1 PS_USE_M_AXI_FPD 1 PS_USE_M_AXI_LPD 1 PS_USE_NOC_LPD_AXI0 1 PS_USE_PMCPL_CLK0 1 PMC_CRP_PL0_REF_CTRL_FREQMHZ 200 PS_USE_S_AXI_LPD 1 PS_USE_BSCAN_USER2 1} CONFIG.CLOCK_MODE {Custom} CONFIG.DDR_MEMORY_MODE {Custom} CONFIG.PS_PL_CONNECTIVITY_MODE {Custom}] [get_bd_cells versal_cips_0]

set_property -dict [list CONFIG.PS_PMC_CONFIG {PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI0_MASTER A72 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI1_MASTER A72 PS_GEN_IPI2_ENABLE 1 PS_GEN_IPI2_MASTER A72 PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI3_MASTER A72 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI4_MASTER A72 PS_GEN_IPI5_ENABLE 1 PS_GEN_IPI5_MASTER A72 PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI6_MASTER A72} ] [get_bd_cells versal_cips_0]

# Create instance: axi_noc_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* axi_noc_0

if {[regexp vpk120 $board_name] } {
	apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "axi_noc_0/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "axi_noc_0/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "axi_noc_0/sys_clk0" -diagram $design_name 
} else {
apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "axi_noc_0/CH0_DDR4_0" -diagram $design_name
apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "axi_noc_0/sys_clk0" -diagram $design_name }

set_property -dict [list CONFIG.NUM_SI {7} CONFIG.NUM_MI {0} CONFIG.NUM_CLKS {7} CONFIG.NUM_MCP {4} ] [get_bd_cells axi_noc_0]
set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_1 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_2 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_3 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S05_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S06_AXI]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_AXI}] [get_bd_pins /axi_noc_0/aclk0]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S01_AXI}] [get_bd_pins /axi_noc_0/aclk1]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S02_AXI}] [get_bd_pins /axi_noc_0/aclk2]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S03_AXI}] [get_bd_pins /axi_noc_0/aclk3]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S04_AXI}] [get_bd_pins /axi_noc_0/aclk4]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S05_AXI}] [get_bd_pins /axi_noc_0/aclk5]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S06_AXI}] [get_bd_pins /axi_noc_0/aclk6]

# Create ports
set pl0_ref_clk [ create_bd_port -dir O -type clk pl0_ref_clk ]
set pl_gen_reset [ create_bd_port -dir O pl_gen_reset ]

# Create instance: axi_bram_ctrl_0, and set properties
set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]

# Create instance: axi_bram_ctrl_0_bram, and set properties
set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_0_bram ]
set_property -dict [ list CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} ] $axi_bram_ctrl_0_bram

# Create instance: axi_cdma_0, and set properties
set axi_cdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma axi_cdma_0 ]
set_property -dict [ list CONFIG.C_ADDR_WIDTH {64} CONFIG.C_INCLUDE_SG {0} CONFIG.C_M_AXI_DATA_WIDTH {128} CONFIG.C_M_AXI_MAX_BURST_LEN {4} ] $axi_cdma_0

# Create instance: axi_smc, and set properties
set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc ]
set_property -dict [ list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} ] $axi_smc

# Create instance: axi_smc_1, and set properties
set axi_smc_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc_1 ]
set_property -dict [ list CONFIG.NUM_SI {1} ] $axi_smc_1

# Create instance: axi_smc_2, and set properties
set axi_smc_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc_2 ]
set_property -dict [ list CONFIG.NUM_SI {1} ] $axi_smc_2

# Create instance: microblaze_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:* microblaze_0

apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {0} axi_periph {Enabled} cache {None} clk {/versal_cips_0/pl0_ref_clk (200 MHz)} cores {1} debug_module {Debug Only} ecc {None} local_mem {64KB} preset {None}}  [get_bd_cells microblaze_0]
#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/versal_cips_0/pl0_ref_clk (333 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/versal_cips_0/S_AXI_LPD} ddr_seg {Auto} intc_ip {/axi_smc_2} master_apm {0}}  [get_bd_intf_pins versal_cips_0/S_AXI_LPD]

set_property -dict [list CONFIG.C_USE_BSCAN {2}] [get_bd_cells mdm_1]

connect_bd_intf_net [get_bd_intf_pins axi_smc_2/M00_AXI] [get_bd_intf_pins versal_cips_0/S_AXI_LPD]
connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins axi_smc_2/S00_AXI]
connect_bd_net [get_bd_pins axi_smc_2/aclk] [get_bd_pins versal_cips_0/pl0_ref_clk]
#connect_bd_net [get_bd_pins rst_versal_cips_0_333M/peripheral_aresetn] [get_bd_pins axi_smc_2/aresetn]
connect_bd_net [get_bd_pins rst_versal_cips_0_199M/peripheral_aresetn] [get_bd_pins axi_smc_2/aresetn]
connect_bd_net [get_bd_pins versal_cips_0/s_axi_lpd_aclk] [get_bd_pins versal_cips_0/pl0_ref_clk]

apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
#apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/versal_cips_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins rst_versal_cips_0_333M/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/versal_cips_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins rst_versal_cips_0_199M/ext_reset_in]

connect_bd_intf_net [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S01_AXI]
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

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/versal_cips_0/M_AXI_LPD} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {/axi_smc_1} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/versal_cips_0/M_AXI_FPD} Slave {/axi_cdma_0/S_AXI_LITE} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_cdma_0/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_cdma_0/M_AXI} Slave {/axi_noc_0/S06_AXI} ddr_seg {Auto} intc_ip {/axi_noc_0} master_apm {0}}  [get_bd_intf_pins axi_noc_0/S06_AXI]

connect_bd_net [get_bd_ports pl_gen_reset] [get_bd_pins versal_cips_0/pl0_resetn]
connect_bd_net [get_bd_ports pl0_ref_clk] [get_bd_pins versal_cips_0/pl0_ref_clk]
connect_bd_net [get_bd_pins axi_cdma_0/cdma_introut] [get_bd_pins versal_cips_0/pl_ps_irq8]
connect_bd_intf_net [get_bd_intf_pins mdm_1/BSCAN] [get_bd_intf_pins versal_cips_0/BSCAN_USER2]
}
##################################################################
# MAIN FLOW
##################################################################

create_root_design  $currentDir $design_name "" 
	
	set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name ]
	set bdimportPath [file join [get_property directory [current_project]] [current_project].srcs ]
	
	open_bd_design [get_bd_files $design_name]
	
	set_property USER_COMMENTS.comment_0 {} [current_bd_design]
	set_property USER_COMMENTS.comment0 {Next Steps:
	1. Generate Block Design (Choose global for quick turnaround).
	2. Run Simulation.
	3. Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2021.1/ced/Xilinx/IPI/cips_vip/README.md} [current_bd_design]
	
	regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
	1. Generate Block Design (Choose global for quick turnaround).
	2. Run Simulation.
	3. Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2021.1/ced/Xilinx/IPI/cips_vip/README.md",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
	#  -string -flagsOSRD
									  
	preplace cgraphic comment_0 place top 1307 -119 textcolor 4 linecolor 3
	",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }
   
	#Bridge control through CONNECTIONS attribute of slave interface
	set_property CONFIG.CONNECTIONS [list M_AXI_FPD M_AXI_LPD] [get_bd_intf_pins /versal_cips_0/S_AXI_LPD]

	assign_bd_address
	#Workaround CR-1091929
	set_property range 512M [get_bd_addr_segs {axi_cdma_0/Data/SEG_axi_noc_0_C0_DDR_LOW0}]
	set_property offset 0x0000000020000000 [get_bd_addr_segs {axi_cdma_0/Data/SEG_axi_noc_0_C0_DDR_LOW0}]
	
	save_bd_design	
	validate_bd_design
	regenerate_bd_layout
	make_wrapper -files [get_files $design_name.bd] -top -import
	
	#Testbench file creation and import
	set board_name [get_property BOARD_NAME [current_board]]
	
	if {[regexp vpk120 $board_name] } {
	set originalTBFile [file join $currentDir vpk_testbench system.sv]
	set xdc [file join $currentDir vpk_constrs_1 top.xdc]
	} else {
	set originalTBFile [file join $currentDir testbench system.sv]
	set xdc [file join $currentDir constrs_1 top.xdc] }
	set mb_elf [file join $currentDir design_files mb_hello.elf]
	set tempTBFile [file join $bdDesignPath system.sv] 
	import_files -fileset constrs_1 -norecurse $xdc
	import_files -fileset sim_1 -norecurse $mb_elf
	set_property SCOPED_TO_REF $design_name [get_files -all -of_objects [get_fileset sim_1] $bdimportPath/sim_1/imports/design_files/mb_hello.elf]
	set_property SCOPED_TO_CELLS { microblaze_0 } [get_files -all -of_objects [get_fileset sim_1] $bdimportPath/sim_1/imports/design_files/mb_hello.elf]
 
	#file copy -force $originalTBFile $tempTBFile 
	set infile [open $originalTBFile]
	set contents [read $infile]
	close $infile
	set contents [string map [list "design_1" "$design_name"] $contents]

	set outfile [open $tempTBFile w]
	puts -nonewline $outfile $contents
	close $outfile

	import_files -fileset [get_filesets sim_1] -norecurse [list $tempTBFile]
	file delete -force $tempTBFile 
	set_property top tb [get_filesets sim_1]
	open_bd_design [get_bd_files $design_name]
	regenerate_bd_layout
	puts "INFO: End of create_root_design"
}