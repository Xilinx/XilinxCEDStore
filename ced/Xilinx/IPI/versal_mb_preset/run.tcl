# ########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

#     http://www.apache.org/licenses/LICENSE-2.0

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

#set_param ips.useCIPSv3 1
set_property target_language Verilog [current_project]
#set design_name mb_preset
#set temp_options Application_Processor

proc create_root_design { parentCell design_name temp_options} {

puts "create_root_design"
set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]
puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"

create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:* versal_cips_0
apply_board_connection -board_interface "ps_pmc_fixed_io" -ip_intf "versal_cips_0/FIXED_IO" -diagram $design_name

set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom PS_NUM_FABRIC_RESETS 1 PS_PL_CONNECTIVITY_MODE Custom PS_USE_PMCPL_CLK0 1 PS_USE_S_AXI_LPD 1 PS_USE_BSCAN_USER2 1} CONFIG.CLOCK_MODE {Custom} CONFIG.PS_PL_CONNECTIVITY_MODE {Custom}] [get_bd_cells versal_cips_0]

set_property -dict [list CONFIG.PS_PMC_CONFIG {PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI0_MASTER A72 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI1_MASTER A72 PS_GEN_IPI2_ENABLE 1 PS_GEN_IPI2_MASTER A72 PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI3_MASTER A72 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI4_MASTER A72 PS_GEN_IPI5_ENABLE 1 PS_GEN_IPI5_MASTER A72 PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI6_MASTER A72} ] [get_bd_cells versal_cips_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard:* clk_wizard_0
set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer} CONFIG.USE_RESET {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {200,100.000,100.000,100.000,100.000,100.000,100.000} CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} ] [get_bd_cells clk_wizard_0]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Clk {/versal_cips_0/pl0_ref_clk (333 MHz)} Manual_Source {Auto}}  [get_bd_pins clk_wizard_0/clk_in1]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/versal_cips_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins clk_wizard_0/resetn]

create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:* microblaze_0

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:* axi_timer_0

set gpios_list ""
set gpios_list [ get_board_component_interfaces -filter {BUSDEF_NAME == gpio_rtl} ]
	set gpio_cnt 0
	foreach gpio $gpios_list {
		set gpio_cnt [expr $gpio_cnt + 1]
		if { $gpio_cnt % 2 == 1} {
			create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_[expr $gpio_cnt/2]
			apply_board_connection -board_interface "$gpio" -ip_intf "axi_gpio_[expr $gpio_cnt/2]/GPIO" -diagram $design_name
			} else {
			apply_board_connection -board_interface "$gpio" -ip_intf "axi_gpio_[expr (($gpio_cnt - 1)/2)]/GPIO2" -diagram $design_name
			}
	}

# create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0
# apply_board_connection -board_interface "dc_pl_gpio" -ip_intf "axi_gpio_0/GPIO" -diagram $design_name 
# apply_board_connection -board_interface "gpio_dp" -ip_intf "/axi_gpio_0/GPIO2" -diagram $design_name 

# create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:* axi_gpio_1
# apply_board_connection -board_interface "gpio_led" -ip_intf "axi_gpio_1/GPIO" -diagram $design_name 
# apply_board_connection -board_interface "gpio_pb" -ip_intf "/axi_gpio_1/GPIO2" -diagram $design_name 

# create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:* axi_gpio_2
# apply_board_connection -board_interface "sysctlr_gpio" -ip_intf "axi_gpio_2/GPIO" -diagram $design_name 

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:* axi_uart16550_0

if {[regexp "vpk120" $board_name]||[regexp "vpk180" $board_name]} {
apply_board_connection -board_interface "uart2_bank712" -ip_intf "axi_uart16550_0/UART" -diagram $design_name 
} else {
apply_board_connection -board_interface "uart2_bank306" -ip_intf "axi_uart16550_0/UART" -diagram $design_name }

if {([lsearch $temp_options Preset.VALUE] == -1) || ([lsearch $temp_options "Microcontroller"] != -1)} {
	puts "INFO: Microcontroller preset enabled"
	
	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {None} clk {/clk_wizard_0/clk_out1 (200 MHz)} cores {1} debug_module {Debug Only} ecc {None} local_mem {64KB} preset {Microcontroller}}  [get_bd_cells microblaze_0]
	
	set_property -dict [list CONFIG.C_USE_BSCAN {2}] [get_bd_cells mdm_1]
	connect_bd_intf_net [get_bd_intf_pins versal_cips_0/BSCAN_USER2] [get_bd_intf_pins mdm_1/BSCAN]
	
} elseif { ([lsearch $temp_options "Application"] != -1 )} {
	puts "INFO: Application_Processor preset enabled"
	
	set_property -dict [list CONFIG.PS_PMC_CONFIG { DDR_MEMORY_MODE Custom PMC_USE_PMC_NOC_AXI0 1} CONFIG.DDR_MEMORY_MODE {Custom}] [get_bd_cells versal_cips_0]
	
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* axi_noc_0
		
	if {[regexp "vpk120" $board_name]||[regexp "vpk180" $board_name]} {
	apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "axi_noc_0/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "axi_noc_0/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "axi_noc_0/sys_clk0" -diagram $design_name 
	} else {
	apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "axi_noc_0/CH0_DDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "axi_noc_0/sys_clk0" -diagram $design_name }
	
	set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {0} CONFIG.NUM_CLKS {2} CONFIG.MC_CHAN_REGION1 {DDR_LOW1}] [get_bd_cells axi_noc_0]
	set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S00_AXI]
	set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S01_AXI]
	set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_AXI}] [get_bd_pins /axi_noc_0/aclk0]
	set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S01_AXI}] [get_bd_pins /axi_noc_0/aclk1]
	
	connect_bd_intf_net [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_0/S01_AXI]
	connect_bd_net [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]
	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {32KB} clk {/clk_wizard_0/clk_out1 (200 MHz)} cores {1} debug_module {Debug Only} ecc {None} local_mem {64KB} preset {Application}}  [get_bd_cells microblaze_0]
	
	set_property -dict [list CONFIG.C_USE_BSCAN {2}] [get_bd_cells mdm_1]
	connect_bd_intf_net [get_bd_intf_pins versal_cips_0/BSCAN_USER2] [get_bd_intf_pins mdm_1/BSCAN]
	
	create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:* axi_smc_0
	connect_bd_intf_net [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins axi_smc_0/M00_AXI]
	connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_DC] [get_bd_intf_pins axi_smc_0/S00_AXI]
	connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_IC] [get_bd_intf_pins axi_smc_0/S01_AXI]
	connect_bd_net [get_bd_pins axi_smc_0/aresetn] [get_bd_pins rst_clk_wizard_0_200M/peripheral_aresetn]
	connect_bd_net [get_bd_pins axi_noc_0/aclk0] [get_bd_pins clk_wizard_0/clk_out1]
	connect_bd_net [get_bd_pins axi_smc_0/aclk] [get_bd_pins clk_wizard_0/clk_out1]
	 
} else {
	puts "ERROR: INVALID PRESET OPTION SELECTED" }
if {[regexp "vpk120" $board_name]||[regexp "vpk180" $board_name]} {
set_property -dict [list CONFIG.NUM_PORTS {4}] [get_bd_cells microblaze_0_xlconcat] 
} else {
set_property -dict [list CONFIG.NUM_PORTS {5}] [get_bd_cells microblaze_0_xlconcat] }

set gpios_list ""
set gpios_list [ get_board_component_interfaces -filter {BUSDEF_NAME == gpio_rtl} ]
	set gpio_cnt 0
	set i 2
	foreach gpio $gpios_list {
		set gpio_cnt [expr $gpio_cnt + 1]
		if { $gpio_cnt % 2 == 1} {
			#create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_[expr $gpio_cnt/2]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_gpio_[expr $gpio_cnt/2]/S_AXI]
			#apply_board_connection -board_interface "$gpio" -ip_intf "axi_gpio_[expr $gpio_cnt/2]/GPIO" -diagram $design_name
			set_property -dict [list CONFIG.C_INTERRUPT_PRESENT {1}] [get_bd_cells axi_gpio_[expr $gpio_cnt/2]]
			connect_bd_net [get_bd_pins axi_gpio_[expr $gpio_cnt/2]/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In$i]
			incr i
			} }
	
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wizard_0/clk_out1 (200 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wizard_0/clk_out1 (200 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wizard_0/clk_out1 (200 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wizard_0/clk_out1 (200 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_uart16550_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_uart16550_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wizard_0/clk_out1 (200 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wizard_0/clk_out1 (200 MHz)} Master {/microblaze_0 (Periph)} Slave {/versal_cips_0/S_AXI_LPD} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins versal_cips_0/S_AXI_LPD]

#set_property -dict [list CONFIG.C_INTERRUPT_PRESENT {1}] [get_bd_cells axi_gpio_0]
#set_property -dict [list CONFIG.C_INTERRUPT_PRESENT {1}] [get_bd_cells axi_gpio_1]
#set_property -dict [list CONFIG.C_INTERRUPT_PRESENT {1}] [get_bd_cells axi_gpio_2]

#set_property -dict [list CONFIG.NUM_PORTS {5}] [get_bd_cells microblaze_0_xlconcat]
connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In0]
connect_bd_net [get_bd_pins axi_uart16550_0/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In1]
# connect_bd_net [get_bd_pins axi_gpio_0/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In2]
# connect_bd_net [get_bd_pins axi_gpio_1/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In3]
# connect_bd_net [get_bd_pins axi_gpio_2/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In4]

delete_bd_objs [get_bd_addr_segs] [get_bd_addr_segs -excluded]
assign_bd_address
set_property range 64K [get_bd_addr_segs {microblaze_0/Instruction/SEG_ilmb_bram_if_cntlr_Mem}]
set_property range 64K [get_bd_addr_segs {microblaze_0/Data/SEG_dlmb_bram_if_cntlr_Mem}]
save_bd_design
validate_bd_design
}

##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $design_name $options 
	
	# close_bd_design [get_bd_designs $design_name]
	# set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
	open_bd_design [get_bd_files $design_name]
	regenerate_bd_layout
	make_wrapper -files [get_files $design_name.bd] -top -import
	puts "INFO: End of create_root_design"
}
