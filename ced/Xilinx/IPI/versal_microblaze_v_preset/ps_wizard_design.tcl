# ########################################################################
# Copyright (C) 2023, Advanced Micro Devices Inc - All rights reserved

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

##################################################################
# DESIGN PROCs													 
##################################################################

# Hierarchical cell: microblaze_riscv_0_local_memory
proc create_hier_cell_microblaze_riscv_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_riscv_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 dlmb_v10 ]

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 ilmb_v10 ]

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr dlmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $dlmb_bram_if_cntlr


  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr ilmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $ilmb_bram_if_cntlr


  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen lmb_bram ]
  set_property -dict [list \
    CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
    CONFIG.READ_LATENCY_A {1} \
    CONFIG.READ_LATENCY_B {1} \
  ] $lmb_bram


  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_riscv_0_dlmb [get_bd_intf_pins dlmb_v10/LMB_M] [get_bd_intf_pins DLMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_dlmb_bus [get_bd_intf_pins dlmb_v10/LMB_Sl_0] [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_riscv_0_ilmb [get_bd_intf_pins ilmb_v10/LMB_M] [get_bd_intf_pins ILMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_ilmb_bus [get_bd_intf_pins ilmb_v10/LMB_Sl_0] [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1  [get_bd_pins SYS_Rst] \
  [get_bd_pins dlmb_v10/SYS_Rst] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] \
  [get_bd_pins ilmb_v10/SYS_Rst] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst]
  connect_bd_net -net microblaze_riscv_0_Clk  [get_bd_pins LMB_Clk] \
  [get_bd_pins dlmb_v10/LMB_Clk] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] \
  [get_bd_pins ilmb_v10/LMB_Clk] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

variable currentDir

proc create_root_design {currentDir design_name temp_options} {

puts "create_root_design"
set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]
puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"

create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:* ps_wizard_0

apply_bd_automation -rule xilinx.com:bd_rule:ps_wizard -config { board_preset {Yes} boot_config {Custom} configure_noc {Add new AXI NoC} debug_config {JTAG} mc_type {None} num_mc_ddr {None} num_mc_lpddr {None} pl_clocks {None} pl_resets {None}}  [get_bd_cells ps_wizard_0]


set_property -dict [list CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {1} CONFIG.PS11_CONFIG(PS_USE_BSCAN_USER2) {1} CONFIG.PS11_CONFIG(PS_USE_PL_AXI_LPD) {1} CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} ] [get_bd_cells ps_wizard_0]
  
create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:* ilconstant_0

connect_bd_net [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk] [get_bd_pins ilconstant_0/dout]
connect_bd_net [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk] [get_bd_pins ilconstant_0/dout]

create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze_riscv:* microblaze_riscv_0

create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz:1.0 clkx5_wiz_0

set_property -dict [list \
  CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
  CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
  CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
  CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
  CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
  CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
  CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {200.000,100.000,100.000,100.000,100.000,100.000,100.000} \
  CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
  CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.USE_RESET {true} \
] [get_bd_cells clkx5_wiz_0]

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Clk {/ps_wizard_0/pl0_ref_clk (333 MHz)} Manual_Source {Auto}}  [get_bd_pins clkx5_wiz_0/clk_in1]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {/ps_wizard_0/pl0_resetn (ACTIVE_LOW)}}  [get_bd_pins clkx5_wiz_0/resetn]

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


create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:* axi_uart16550_0

if {[regexp "vek385" $board_name]} {
apply_board_connection -board_interface "pl_uart_bank705" -ip_intf "axi_uart16550_0/UART" -diagram $design_name  
}

if {([lsearch $temp_options Preset.VALUE] == -1) || ([lsearch $temp_options "Microcontroller"] != -1)} {

puts "INFO: Microcontroller preset enabled"

# Create instance: microblaze_riscv_0, and set properties
set_property -dict [list \
  CONFIG.C_DEBUG_ENABLED {1} \
  CONFIG.C_D_AXI {1} \
  CONFIG.C_D_LMB {1} \
  CONFIG.C_I_LMB {1} \
  CONFIG.G_TEMPLATE_LIST {1} \
] [get_bd_cells microblaze_riscv_0]

# Create instance: microblaze_riscv_0_local_memory
create_hier_cell_microblaze_riscv_0_local_memory [current_bd_instance .] microblaze_riscv_0_local_memory

# Create instance: microblaze_riscv_0_axi_periph, and set properties
set microblaze_riscv_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect microblaze_riscv_0_axi_periph ]
set_property CONFIG.NUM_SI {1} $microblaze_riscv_0_axi_periph


# Create instance: microblaze_riscv_0_axi_intc, and set properties
set microblaze_riscv_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc microblaze_riscv_0_axi_intc ]
set_property CONFIG.C_HAS_FAST {1} $microblaze_riscv_0_axi_intc


# Create instance: microblaze_riscv_0_xlconcat, and set properties
set microblaze_riscv_0_xlconcat [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat microblaze_riscv_0_xlconcat ]

# Create instance: mdm_1, and set properties
set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm_riscv mdm_1 ]

# Create instance: rst_clkx5_wiz_0_200M, and set properties
set rst_clkx5_wiz_0_200M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_clkx5_wiz_0_200M ]

# Create interface connections
connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_periph/S00_AXI] [get_bd_intf_pins microblaze_riscv_0/M_AXI_DP]
connect_bd_intf_net [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_riscv_0/DEBUG]
connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/DLMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/DLMB]
connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/ILMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/ILMB]
connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_periph/M00_AXI] [get_bd_intf_pins microblaze_riscv_0_axi_intc/s_axi]
connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_intc/interrupt] [get_bd_intf_pins microblaze_riscv_0/INTERRUPT]

# Create port connections
connect_bd_net [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_clkx5_wiz_0_200M/mb_debug_sys_rst]
connect_bd_net [get_bd_pins clkx5_wiz_0/clk_out1] \
[get_bd_pins microblaze_riscv_0/Clk] \
[get_bd_pins microblaze_riscv_0_axi_periph/aclk] \
[get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] \
[get_bd_pins microblaze_riscv_0_axi_intc/processor_clk] \
[get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk] \
[get_bd_pins rst_clkx5_wiz_0_200M/slowest_sync_clk]

connect_bd_net [get_bd_pins microblaze_riscv_0_xlconcat/dout] [get_bd_pins microblaze_riscv_0_axi_intc/intr]
connect_bd_net [get_bd_pins rst_clkx5_wiz_0_200M/ext_reset_in] [get_bd_pins ps_wizard_0/pl0_resetn]
connect_bd_net [get_bd_pins rst_clkx5_wiz_0_200M/bus_struct_reset] [get_bd_pins microblaze_riscv_0_local_memory/SYS_Rst]
connect_bd_net [get_bd_pins rst_clkx5_wiz_0_200M/mb_reset] [get_bd_pins microblaze_riscv_0/Reset] [get_bd_pins microblaze_riscv_0_axi_intc/processor_rst]
connect_bd_net [get_bd_pins rst_clkx5_wiz_0_200M/peripheral_aresetn] [get_bd_pins microblaze_riscv_0_axi_periph/aresetn] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aresetn]

set_property -dict [list CONFIG.C_USE_BSCAN {2}] [get_bd_cells mdm_1]
connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/BSCAN_USER2] [get_bd_intf_pins mdm_1/BSCAN]

} elseif { ([lsearch $temp_options "Application"] != -1 )} {
	puts "INFO: Application_Processor preset enabled"
	
	set_property -dict [list CONFIG.PS_PMC_CONFIG { DDR_MEMORY_MODE Custom PMC_USE_PMC_NOC_AXI0 1} CONFIG.DDR_MEMORY_MODE {Custom}] [get_bd_cells versal_cips_0]
	
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* axi_noc_0
		
	if {[regexp "vpk120" $board_name]||[regexp "vpk180" $board_name]||[regexp "vek280" $board_name]} {
	apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "axi_noc_0/CH0_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "axi_noc_0/CH1_LPDDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "axi_noc_0/sys_clk0" -diagram $design_name 
	} else {
	apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "axi_noc_0/CH0_DDR4_0" -diagram $design_name 
	apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "axi_noc_0/sys_clk0" -diagram $design_name }
	
	if { [regexp "vpk120" $board_name]||[regexp "vpk180" $board_name]||[regexp "vek280" $board_name] } {
	set_property -dict [list CONFIG.MC_CHANNEL_INTERLEAVING {true} CONFIG.MC_CH_INTERLEAVING_SIZE {4K_Bytes} ] [get_bd_cells axi_noc_0]}
	
	set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {0} CONFIG.NUM_CLKS {2} CONFIG.MC_CHAN_REGION1 {DDR_LOW1}] [get_bd_cells axi_noc_0]
	set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S00_AXI]
	set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S01_AXI]
	set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_AXI}] [get_bd_pins /axi_noc_0/aclk0]
	set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S01_AXI}] [get_bd_pins /axi_noc_0/aclk1]
	
	connect_bd_intf_net [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_0/S01_AXI]
	connect_bd_net [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]
	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {32KB} clk {/clkx5_wiz_0/clk_out1 (200 MHz)} cores {1} debug_module {Debug Only} ecc {None} local_mem {64KB} preset {Application}}  [get_bd_cells microblaze_0]
	
	set_property -dict [list CONFIG.C_USE_BSCAN {2}] [get_bd_cells mdm_1]
	connect_bd_intf_net [get_bd_intf_pins versal_cips_0/BSCAN_USER2] [get_bd_intf_pins mdm_1/BSCAN]
	
	create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:* axi_smc_0
	connect_bd_intf_net [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins axi_smc_0/M00_AXI]
	connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_DC] [get_bd_intf_pins axi_smc_0/S00_AXI]
	connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_IC] [get_bd_intf_pins axi_smc_0/S01_AXI]
	connect_bd_net [get_bd_pins axi_smc_0/aresetn] [get_bd_pins rst_clk_wizard_0_200M/peripheral_aresetn]
	connect_bd_net [get_bd_pins axi_noc_0/aclk0] [get_bd_pins clkx5_wiz_0/clk_out1]
	connect_bd_net [get_bd_pins axi_smc_0/aclk] [get_bd_pins clkx5_wiz_0/clk_out1]
	 
} else {
	puts "ERROR: INVALID PRESET OPTION SELECTED" }
if {[regexp "vek385" $board_name]} {
set_property -dict [list CONFIG.NUM_PORTS {4}] [get_bd_cells microblaze_riscv_0_xlconcat] 
} else {
set_property -dict [list CONFIG.NUM_PORTS {4}] [get_bd_cells microblaze_riscv_0_xlconcat] }

set gpios_list ""
set gpios_list [ get_board_component_interfaces -filter {BUSDEF_NAME == gpio_rtl} ]
	set gpio_cnt 0
	set i 2
	foreach gpio $gpios_list {
		set gpio_cnt [expr $gpio_cnt + 1]
		if { $gpio_cnt % 2 == 1} {
			#create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_[expr $gpio_cnt/2]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_riscv_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_gpio_[expr $gpio_cnt/2]/S_AXI]
			#apply_board_connection -board_interface "$gpio" -ip_intf "axi_gpio_[expr $gpio_cnt/2]/GPIO" -diagram $design_name
			set_property -dict [list CONFIG.C_INTERRUPT_PRESENT {1}] [get_bd_cells axi_gpio_[expr $gpio_cnt/2]]
			connect_bd_net [get_bd_pins axi_gpio_[expr $gpio_cnt/2]/ip2intc_irpt] [get_bd_pins microblaze_riscv_0_xlconcat/In$i]
			incr i
			} }
			
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clkx5_wiz_0/clk_out1 (200 MHz)} Clk_slave {Auto} Clk_xbar {/clkx5_wiz_0/clk_out1 (200 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clkx5_wiz_0/clk_out1 (200 MHz)} Clk_slave {Auto} Clk_xbar {/clkx5_wiz_0/clk_out1 (200 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_uart16550_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_uart16550_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clkx5_wiz_0/clk_out1 (200 MHz)} Clk_slave {Auto} Clk_xbar {/clkx5_wiz_0/clk_out1 (200 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/ps_wizard_0/PL_AXI_LPD} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}}  [get_bd_intf_pins ps_wizard_0/PL_AXI_LPD]

connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_riscv_0_xlconcat/In0]
connect_bd_net [get_bd_pins axi_uart16550_0/ip2intc_irpt] [get_bd_pins microblaze_riscv_0_xlconcat/In1]

delete_bd_objs [get_bd_addr_segs] [get_bd_addr_segs -excluded]
assign_bd_address
set_property range 64K [get_bd_addr_segs {microblaze_riscv_0/Instruction/SEG_ilmb_bram_if_cntlr_Mem}]
set_property range 64K [get_bd_addr_segs {microblaze_riscv_0/Data/SEG_dlmb_bram_if_cntlr_Mem}]
save_bd_design
validate_bd_design

}