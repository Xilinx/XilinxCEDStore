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

#set design_name mb_preset
#set temp_options Application_Processor

# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.



proc create_root_design { parentCell design_name temp_options} {

# create_bd_design "mb_preset"

# puts "creat_root_desing"
set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]
set mem_ctrl [set mem_int ""]
if { [regexp "xcvu" $fpga_part]||[regexp "xcku" $fpga_part] } {
	set mem_ctrl ddr4
	set mem_int /ddr4_0/addn_ui_clkout1
	} else {
	set mem_ctrl ddr3
    set mem_int /mig_7series_0/ui_addn_clk_0 }
puts "INFO: $board_part is selected"
#puts "INFO: $temp_options"

# source $design_repo/bd_7series/microcontroller_bd.tcl
# set file  "[file dirname [file normalize [info script]]]/repo2/bd_7series/microcontroller_bd.tcl"
# source $file

#set design_name config_mb

set uart_board_interface ""
set iic_board_interface ""
set qspi_flash_board_interface ""
set bpi_flash_board_interface ""
set ddr3_board_interface [set ddr4_board_interface [set ddr3_board_interface_1 [set ddr4_board_interface_1 ""]]]
set ddr3_board_interface_1 ""
set ethenet_board_interface ""
set sfp_board_interface ""
set rgmii_board_interface ""
set inpt [set phy_rst ""]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0
lappend inpt axi_timer_0/interrupt

catch { set uart_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==uart}] 0]]
if { $uart_board_interface != "" } {
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0
apply_board_connection -board_interface "$uart_board_interface" -ip_intf "axi_uartlite_0/UART" -diagram $design_name 
set_property -dict [list CONFIG.C_BAUDRATE {115200}] [get_bd_cells axi_uartlite_0]
lappend inpt axi_uartlite_0/interrupt
}}

catch { set iic_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==mux}] 0]]
if { $iic_board_interface != "" } {
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0
apply_board_connection -board_interface "$iic_board_interface" -ip_intf "axi_iic_0/IIC" -diagram $design_name 

lappend inpt axi_iic_0/iic2intc_irpt
}}

catch { set qspi_flash_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==memory_flash_qspi}] 0]]
if { $qspi_flash_board_interface != "" } {
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi axi_quad_spi_0
	if { $board_name != "vcu118" } {
	apply_board_connection -board_interface "$qspi_flash_board_interface" -ip_intf "axi_quad_spi_0/SPI_0" -diagram $design_name 
	} else {
		apply_board_connection -board_interface "$qspi_flash_board_interface" -ip_intf "axi_quad_spi_0/SPI_1" -diagram $design_name }
lappend inpt axi_quad_spi_0/ip2intc_irpt
}}

catch { set bpi_flash_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==memory_flash_bpi}] 0]]
if { $bpi_flash_board_interface != "" } {
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_emc axi_emc_0
	apply_board_connection -board_interface "$bpi_flash_board_interface" -ip_intf "axi_emc_0/EMC_INTF" -diagram $design_name 
}}

create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0


set ddr3_board_interface [board::get_board_part_interfaces *ddr3*]
set ddr3_board_interface_1 [lindex [split $ddr3_board_interface { }] 0]

set ddr4_board_interface [board::get_board_part_interfaces *ddr4*]
set ddr4_board_interface_1 [lindex [split $ddr4_board_interface { }] 0]



if {([lsearch $temp_options Preset.VALUE] == -1) || ([lsearch $temp_options "Microcontroller"] != -1)} {
	puts "INFO: Microcontroller preset enabled"

	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {None} clk {New Clocking Wizard} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {Microcontroller}}  [get_bd_cells microblaze_0]

	set sys_diff_clock [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==system_clock}] 0]]
	apply_board_connection -board_interface "$sys_diff_clock" -ip_intf "/clk_wiz_1/CLK_IN1_D" -diagram $design_name 

	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins clk_wiz_1/reset]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
	set_property -dict [list CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50} CONFIG.MMCM_CLKOUT1_DIVIDE {20} CONFIG.NUM_OUT_CLKS {2} CONFIG.CLKOUT2_JITTER {129.198} CONFIG.CLKOUT2_PHASE_ERROR {89.971}] [get_bd_cells clk_wiz_1]

	if { $qspi_flash_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out2 (50 MHz)} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins axi_quad_spi_0/ext_spi_clk]
	}

	if { $bpi_flash_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_emc_0/S_AXI_MEM} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_emc_0/S_AXI_MEM]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_emc_0/rdclk]
	} 

	if { $iic_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_iic_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_iic_0/S_AXI]
	}

	if { $uart_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_uartlite_0/S_AXI]
	}

	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]

} elseif { ([lsearch $temp_options "Real-time_Processor"] != -1 )} {
	puts "INFO: Real-time_Processor preset enabled"
	
	if { $mem_ctrl != "ddr4" } {
	if { $ddr3_board_interface != "" } {
	create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series mig_7series_0
	apply_board_connection -board_interface "$ddr3_board_interface_1" -ip_intf "mig_7series_0/mig_ddr_interface" -diagram $design_name 
	}
	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {8KB} clk {/mig_7series_0/ui_addn_clk_0 (100 MHz)} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {Real-time}}  [get_bd_cells microblaze_0]
	set_property -dict [list CONFIG.C_USE_MMU {2}] [get_bd_cells microblaze_0]
	
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_slave {/mig_7series_0/ui_clk (200 MHz)} Clk_xbar {Auto} Master {/microblaze_0 (Cached)} Slave {/mig_7series_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins mig_7series_0/S_AXI]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins mig_7series_0/sys_rst]
	connect_bd_net [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins rst_mig_7series_0_100M/ext_reset_in]
	
    } else {
		if { $ddr4_board_interface_1 != "" } {
		create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0
		apply_board_connection -board_interface "$ddr4_board_interface_1" -ip_intf "ddr4_0/C0_DDR4" -diagram $design_name
		
		apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {8KB} clk {/ddr4_0/addn_ui_clkout1 (100 MHz)} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {Real-time}}  [get_bd_cells microblaze_0]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {Auto} Master {/microblaze_0 (Cached)} Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
		set_property -dict [list CONFIG.C_USE_MMU {2}] [get_bd_cells microblaze_0]
		
		set ddr_sys_clk [get_property CONFIG.System_Clock [ get_ips ${design_name}_ddr4_0_0]]
		if { $ddr_sys_clk == "No_Buffer" } {
			set_property -dict [list CONFIG.System_Clock {Differential}] [get_bd_cells ddr4_0]
		}
		set def_clk [lindex [board::get_board_part_interfaces *default*] 0]
		apply_board_connection -board_interface "$def_clk" -ip_intf "ddr4_0/C0_SYS_CLK*" -diagram $design_name 
		
		apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins ddr4_0/sys_rst]
		apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {Custom} Manual_Source {/ddr4_0/c0_ddr4_ui_clk_sync_rst (ACTIVE_HIGH)}}  [get_bd_pins rst_ddr4_0_100M/ext_reset_in]
		
		set s_axi_ctrl [get_property CONFIG.C0.DDR4_Ecc [ get_ips ${design_name}_ddr4_0_0]]
		if { $s_axi_ctrl == "true" } {
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (333 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/ddr4_0/C0_DDR4_S_AXI_CTRL} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI_CTRL]
		}
		} else {
		
		set mem_int /clk_wiz_1/clk_out1
		
		apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {8KB} clk {New Clocking Wizard} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {Real-time}}  [get_bd_cells microblaze_0]
		set_property -dict [list CONFIG.C_USE_ICACHE {0} CONFIG.C_ADDR_TAG_BITS {0} CONFIG.C_USE_DCACHE {0} CONFIG.C_DCACHE_ADDR_TAG {0}] [get_bd_cells microblaze_0]
		apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {default_sysclk1_300 ( 300 MHz System differential clock1 ) } Manual_Source {Auto}}  [get_bd_intf_pins clk_wiz_1/CLK_IN1_D]
		apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins clk_wiz_1/reset]
		apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
		#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {/clk_wiz_1/clk_out1 (100 MHz)} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0/M_AXI_DC} Slave {/microblaze_0_axi_intc/s_axi} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins microblaze_0/M_AXI_DC]
		#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {/clk_wiz_1/clk_out1 (100 MHz)} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0/M_AXI_IC} Slave {/microblaze_0_axi_intc/s_axi} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins microblaze_0/M_AXI_IC]

		} 
	}

	if { $qspi_flash_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {$mem_int (100 MHz)} Clk_slave {Auto} Clk_xbar {$mem_int (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
	if { $mem_ctrl != "ddr4" } {
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {New Clocking Wizard} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins axi_quad_spi_0/ext_spi_clk]
	set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} CONFIG.MMCM_CLKOUT0_DIVIDE_F {20.000} CONFIG.CLKOUT1_JITTER {151.636}] [get_bd_cells clk_wiz]
	set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] [get_bd_cells clk_wiz]
	connect_bd_net [get_bd_pins clk_wiz/reset] [get_bd_pins mig_7series_0/ui_clk_sync_rst]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Clk {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Manual_Source {Auto}}  [get_bd_pins clk_wiz/clk_in1]
	} else {
		if { $ddr4_board_interface_1 != "" } {
		set_property -dict [list CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {50}] [get_bd_cells ddr4_0]
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
		apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/ddr4_0/addn_ui_clkout2 (50 MHz)} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins axi_quad_spi_0/ext_spi_clk]
		} else {
		set_property -dict [list CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50.000} CONFIG.MMCM_CLKOUT1_DIVIDE {20} CONFIG.NUM_OUT_CLKS {2} CONFIG.CLKOUT2_JITTER {148.677} CONFIG.CLKOUT2_PHASE_ERROR {98.575}] [get_bd_cells clk_wiz_1]
		}
	} }

	if { $bpi_flash_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_7series_0/ui_clk (100 MHz)} Clk_slave {Auto} Clk_xbar {/mig_7series_0/ui_clk (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_emc_0/S_AXI_MEM} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_emc_0/S_AXI_MEM]
	connect_bd_net [get_bd_pins axi_emc_0/rdclk] [get_bd_pins mig_7series_0/ui_addn_clk_0]
	} 

	if { $iic_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {$mem_int (100 MHz)} Clk_slave {Auto} Clk_xbar {$mem_int (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_iic_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_iic_0/S_AXI]
	}

	if { $uart_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {$mem_int (100 MHz)} Clk_slave {Auto} Clk_xbar {$mem_int (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_uartlite_0/S_AXI]
	}

	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {$mem_int (100 MHz)} Clk_slave {Auto} Clk_xbar {$mem_int (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]
	
	#creating the top.xdc constraints
	set proj_dir [get_property DIRECTORY [current_project ]]
	set proj_name [get_property NAME [current_project ]]
	set board_name [get_property NAME [current_board_part]]
	file mkdir $proj_dir/$proj_name.srcs/constrs_1/constrs
	set Include_Ethernet [set Include_ddr ""]
	set Include_Ethernet [get_ips ${design_name}_axi_ethernet_0_0]
	set Include_ddr [get_ips ${design_name}_ddr4_0_0]
	set fd [ open $proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc w ]
	if { $Include_ddr != {} } {
	
			puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */addn_ui_clkout1}\]"
			puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}\]"	  
	     }
	close $fd
	add_files  -fileset constrs_1 [ list "$proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc" ]
		 
} elseif { ([lsearch $temp_options "Application_Processor"] != -1 )} {
	puts "INFO: Application_Processor preset enabled"
	
	if { $mem_ctrl != "ddr4" } {
	if { $ddr3_board_interface != "" } {
	create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series mig_7series_0
	apply_board_connection -board_interface "$ddr3_board_interface_1" -ip_intf "mig_7series_0/mig_ddr_interface" -diagram $design_name 
	}
	
	apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {32KB} clk {/mig_7series_0/ui_addn_clk_0 (100 MHz)} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {Application}}  [get_bd_cells microblaze_0]
	
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_slave {/mig_7series_0/ui_clk (200 MHz)} Clk_xbar {Auto} Master {/microblaze_0 (Cached)} Slave {/mig_7series_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins mig_7series_0/S_AXI]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins mig_7series_0/sys_rst]
	connect_bd_net [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins rst_mig_7series_0_100M/ext_reset_in]
	
	if { $board_name != "vc709"} {						   
	set ethenet_board_interface [board::get_board_component_interfaces *rgmii*]
	set sfp_board_interface [board::get_board_component_interfaces *sfp*]
	set var [set var1 ""]
	set var [lindex $sfp_board_interface 0]
	set var1 [lindex $ethenet_board_interface 0]
	if { ([lsearch $ethenet_board_interface $var1] != -1 )} {
	set ethenet_board_interface $var1
	} elseif { ([lsearch $sfp_board_interface $var] != -1 )} {
	set sfp_board_interface $var
	}
	#puts $ethenet_board_interface
	#puts $sfp_board_interface
	
	if { ( $ethenet_board_interface != "" ) || ( $sfp_board_interface != "" )} {
	
		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_0
		
		lappend inpt axi_ethernet_0/mac_irq
		lappend inpt axi_ethernet_0/interrupt
		
		set mdio_mdc_board_interface [board::get_board_component_interfaces *mdio_mdc*]
		set mdio_mdc_board_interface_1 [lindex [split $mdio_mdc_board_interface { }] 0]
		
		set phy_reset_out_board_interface [board::get_board_component_interfaces *phy_reset_out*]
		set phy_reset_out_board_interface_1 [lindex [split $phy_reset_out_board_interface { }] 0]
		
		set rgmii_board_interface [board::get_board_component_interfaces rgmii*]
		set rgmii_board_interface_1 [lindex [split $rgmii_board_interface { }] 0]
		
		if { $mdio_mdc_board_interface_1 != "" } {
		apply_board_connection -board_interface "$mdio_mdc_board_interface_1" -ip_intf "axi_ethernet_0/mdio" -diagram $design_name }
		
		if { $phy_reset_out_board_interface_1 != "" } {
		apply_board_connection -board_interface "$phy_reset_out_board_interface_1" -ip_intf "axi_ethernet_0/phy_rst_n" -diagram $design_name }

		if { $rgmii_board_interface != "" } {
			apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config {PHY_TYPE "RGMII" FIFO_DMA "DMA" }  [get_bd_cells axi_ethernet_0]
			apply_board_connection -board_interface "$rgmii_board_interface_1" -ip_intf "axi_ethernet_0/rgmii" -diagram $design_name 
		
			lappend inpt axi_ethernet_0_dma/mm2s_introut
			lappend inpt axi_ethernet_0_dma/s2mm_introut
		
		} else {
			apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config {PHY_TYPE "SGMII" FIFO_DMA "DMA" }  [get_bd_cells axi_ethernet_0]
			
			if { $board_name == "vc707"} { 
				set_property -dict [list CONFIG.ETHERNET_BOARD_INTERFACE {sgmii} CONFIG.DIFFCLK_BOARD_INTERFACE {Custom} CONFIG.ENABLE_LVDS {false}] [get_bd_cells axi_ethernet_0]
				delete_bd_objs [get_bd_intf_nets axi_ethernet_0_sgmii] [get_bd_intf_ports sfp_sgmii]
				apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sgmii ( Onboard PHY ) } Manual_Source {Auto}} [get_bd_intf_pins axi_ethernet_0/sgmii] 
				}
			
			lappend inpt axi_ethernet_0_dma/mm2s_introut
			lappend inpt axi_ethernet_0_dma/s2mm_introut
			
			if { $mdio_mdc_board_interface_1 == "" } {
				delete_bd_objs [get_bd_intf_nets axi_ethernet_0_mdio] [get_bd_intf_ports mdio_rtl]
			}
			
			if { $ethenet_board_interface != "" } {
				apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sgmii_mgt_clk ( SGMII MGT clock ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernet_0/mgt_clk] 
				}
			
			if { $sfp_board_interface != "" } {
				set mgt_clk [board::get_board_component_interfaces *sfp_mgt_clk*]
				if { $mgt_clk == "sfp_mgt_clk" } {
					apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sfp_mgt_clk ( SFP MGT clock ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernet_0/mgt_clk]	
				} else {
					apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sgmii_mgt_clk ( SGMII MGT clock ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernet_0/mgt_clk]
				}
			}				
	}
	}
	catch {
		if { [get_bd_cells axi_ethernet_0_gtxclk] != "" } {
			set_property name axi_ethernet_0_refclk [get_bd_cells axi_ethernet_0_gtxclk]
			}
		 }	

	catch {
	  if { [get_bd_cells axi_ethernet_0_refclk] != "" } {
			set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}  CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT3_USED {true} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {50} CONFIG.MMCM_CLKOUT2_DIVIDE {20} CONFIG.NUM_OUT_CLKS {3} CONFIG.CLKOUT3_JITTER {151.636} CONFIG.CLKOUT3_PHASE_ERROR {98.575}] [get_bd_cells axi_ethernet_0_refclk]
			apply_bd_automation -rule xilinx.com:bd_rule:board -config { Clk {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Manual_Source {Auto}}  [get_bd_pins axi_ethernet_0_refclk/clk_in1]
			}
	    }
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Freq {100} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins axi_ethernet_0/axis_clk]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_slave {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_xbar {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_ethernet_0/s_axi} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0/s_axi]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_slave {/mig_7series_0/ui_clk } Clk_xbar {/mig_7series_0/ui_clk (200 MHz)} Master {/axi_ethernet_0_dma/M_AXI_MM2S} Slave {/mig_7series_0/S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_MM2S]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_slave {/mig_7series_0/ui_clk } Clk_xbar {/mig_7series_0/ui_clk (200 MHz)} Master {/axi_ethernet_0_dma/M_AXI_S2MM} Slave {/mig_7series_0/S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_S2MM]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_slave {/mig_7series_0/ui_clk } Clk_xbar {/mig_7series_0/ui_clk (200 MHz)} Master {/axi_ethernet_0_dma/M_AXI_SG} Slave {/mig_7series_0/S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_SG]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_slave {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_xbar {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_ethernet_0_dma/S_AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/S_AXI_LITE]
    }
	} else {
		if { $ddr4_board_interface_1 != "" } {
			create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0
			apply_board_connection -board_interface "$ddr4_board_interface_1" -ip_intf "ddr4_0/C0_DDR4" -diagram $design_name
			
			apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {32KB} clk {/ddr4_0/addn_ui_clkout1 (100 MHz)} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {Application}}  [get_bd_cells microblaze_0]
	
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {Auto} Master {/microblaze_0 (Cached)} Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
			
			set ddr_sys_clk [get_property CONFIG.System_Clock [ get_ips ${design_name}_ddr4_0_0]]
			if { $ddr_sys_clk == "No_Buffer" } {
				set_property -dict [list CONFIG.System_Clock {Differential}] [get_bd_cells ddr4_0]
			}
			
			set def_clk [lindex [board::get_board_part_interfaces *default*] 0]
			apply_board_connection -board_interface "$def_clk" -ip_intf "ddr4_0/C0_SYS_CLK" -diagram $design_name
			
			set s_axi_ctrl [get_property CONFIG.C0.DDR4_Ecc [ get_ips ${design_name}_ddr4_0_0]]
			if { $s_axi_ctrl == "true" } {
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (333 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/ddr4_0/C0_DDR4_S_AXI_CTRL} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI_CTRL]
			}
			
			apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins ddr4_0/sys_rst]
			apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {Custom} Manual_Source {/ddr4_0/c0_ddr4_ui_clk_sync_rst (ACTIVE_HIGH)}}  [get_bd_pins rst_ddr4_0_100M/ext_reset_in]
		} else {
			apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {32KB} clk {New Clocking Wizard} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {Application}}  [get_bd_cells microblaze_0]
			set_property -dict [list CONFIG.C_USE_ICACHE {0} CONFIG.C_ADDR_TAG_BITS {0} CONFIG.C_USE_DCACHE {0} CONFIG.C_DCACHE_ADDR_TAG {0}] [get_bd_cells microblaze_0]
			apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {default_sysclk1_300 ( 300 MHz System differential clock1 ) } Manual_Source {Auto}}  [get_bd_intf_pins clk_wiz_1/CLK_IN1_D]
			apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins clk_wiz_1/reset]
			#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {/clk_wiz_1/clk_out1 (100 MHz)} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0/M_AXI_DC} Slave {/microblaze_0_axi_intc/s_axi} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins microblaze_0/M_AXI_DC]
			#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {/clk_wiz_1/clk_out1 (100 MHz)} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0/M_AXI_IC} Slave {/microblaze_0_axi_intc/s_axi} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins microblaze_0/M_AXI_IC]
			apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
			}
		set usl_ethernet [lindex [board::get_board_component_interfaces *sgmii*] 0]
			if { $usl_ethernet != "" } {
			create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_0
			apply_board_connection -board_interface "sgmii_lvds" -ip_intf "axi_ethernet_0/sgmii" -diagram $design_name 
			apply_board_connection -board_interface "mdio_mdc" -ip_intf "axi_ethernet_0/mdio" -diagram $design_name
			apply_board_connection -board_interface "sgmii_phyclk" -ip_intf "axi_ethernet_0/lvds_clk" -diagram $design_name
			
			set phy_rst [get_property CONFIG.PHYRST_BOARD_INTERFACE [lindex [get_ips ${design_name}_axi_ethernet_0_0] 0]]
			set dummy_port [get_property CONFIG.PHYRST_BOARD_INTERFACE_DUMMY_PORT [lindex [get_ips ${design_name}_axi_ethernet_0_0] 0]]
			if { ($phy_rst != "Custom")&&($phy_rst != "") } {
			apply_board_connection -board_interface "phy_reset_out" -ip_intf "axi_ethernet_0/phy_rst_n" -diagram $design_name 
			} elseif { ($dummy_port != "Custom")&&($dummy_port != "") } {
			apply_board_connection -board_interface "dummy_port_in" -ip_intf "axi_ethernet_0/dummy_port_in" -diagram $design_name
			}
			apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config {PHY_TYPE "SGMII" FIFO_DMA "DMA" }  [get_bd_cells axi_ethernet_0]
			
			if { $ddr4_board_interface_1 != "" } {
			apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_ethernet_0/axis_clk]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_ethernet_0/s_axi} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0/s_axi]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Master {/axi_ethernet_0_dma/M_AXI_MM2S} Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_MM2S]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Master {/axi_ethernet_0_dma/M_AXI_S2MM} Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_S2MM]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Master {/axi_ethernet_0_dma/M_AXI_SG} Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_SG]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_ethernet_0_dma/S_AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/S_AXI_LITE]
			} else {
			apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_ethernet_0/axis_clk]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_ethernet_0/s_axi} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0/s_axi]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_ethernet_0_dma/S_AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/S_AXI_LITE] 
			connect_bd_net [get_bd_pins axi_ethernet_0_dma/m_axi_sg_aclk] [get_bd_pins clk_wiz_1/clk_out1]  }
			
			lappend inpt axi_ethernet_0/mac_irq
			lappend inpt axi_ethernet_0/interrupt
			lappend inpt axi_ethernet_0_dma/mm2s_introut
			lappend inpt axi_ethernet_0_dma/s2mm_introut }
		}
	if { $qspi_flash_board_interface != "" } {
	
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {$mem_int (100 MHz)} Clk_slave {Auto} Clk_xbar {$mem_int (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
	if { $mem_ctrl != "ddr4" } {
		if { $ethenet_board_interface != "" } {
		connect_bd_net [get_bd_pins axi_quad_spi_0/ext_spi_clk] [get_bd_pins axi_ethernet_0_refclk/clk_out3]
		} else {
		apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {New Clocking Wizard} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins axi_quad_spi_0/ext_spi_clk]
		set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} CONFIG.MMCM_CLKOUT0_DIVIDE_F {20.000} CONFIG.CLKOUT1_JITTER {151.636}] [get_bd_cells clk_wiz]
		set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] [get_bd_cells clk_wiz]
		connect_bd_net [get_bd_pins clk_wiz/reset] [get_bd_pins mig_7series_0/ui_clk_sync_rst]
		apply_bd_automation -rule xilinx.com:bd_rule:board -config { Clk {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Manual_Source {Auto}}  [get_bd_pins clk_wiz/clk_in1]
		} 
	} else {
	set_property -dict [list CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {50}] [get_bd_cells ddr4_0]
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/ddr4_0/addn_ui_clkout2 (50 MHz)} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}}  [get_bd_pins axi_quad_spi_0/ext_spi_clk] }
	}
	
	if { $bpi_flash_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {$mem_int (100 MHz)} Clk_slave {Auto} Clk_xbar {$mem_int (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_emc_0/S_AXI_MEM} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_emc_0/S_AXI_MEM]
	connect_bd_net [get_bd_pins axi_emc_0/rdclk] [get_bd_pins mig_7series_0/ui_addn_clk_0]
	} 

	if { $iic_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {$mem_int (100 MHz)} Clk_slave {Auto} Clk_xbar {$mem_int (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_iic_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_iic_0/S_AXI]
	}

	if { $uart_board_interface != "" } {
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {$mem_int (100 MHz)} Clk_slave {Auto} Clk_xbar {$mem_int (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_uartlite_0/S_AXI]
	}
	#timer connection
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {$mem_int (100 MHz)} Clk_slave {Auto} Clk_xbar {$mem_int (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]
	
	if {($ddr3_board_interface_1 == "") &&($ddr4_board_interface_1 == "")} {
	
	set_property -dict [list CONFIG.C_USE_ICACHE {1} CONFIG.C_ADDR_TAG_BITS {15} CONFIG.C_USE_DCACHE {1} CONFIG.C_DCACHE_ADDR_TAG {15}] [get_bd_cells microblaze_0]
	
	
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0
	
	
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0
	
	
	set_property -dict [list CONFIG.NUM_SI {5} CONFIG.NUM_MI {1} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
	connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_DC] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
	connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_IC] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S01_AXI]
	connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_SG] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S02_AXI]
	connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_MM2S] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S03_AXI]
	connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_S2MM] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S04_AXI]
	
	connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
	
	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
	apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/ACLK]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/S00_ACLK]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/S01_ACLK]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/S02_ACLK]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/S03_ACLK]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/S04_ACLK]
	
	
	assign_bd_address
	
	set_property range 1M [get_bd_addr_segs {axi_ethernet_0_dma/Data_MM2S/SEG_axi_bram_ctrl_0_Mem0}]
	set_property range 1M [get_bd_addr_segs {axi_ethernet_0_dma/Data_S2MM/SEG_axi_bram_ctrl_0_Mem0}]
	set_property range 1M [get_bd_addr_segs {axi_ethernet_0_dma/Data_SG/SEG_axi_bram_ctrl_0_Mem0}]
	set_property range 1M [get_bd_addr_segs {microblaze_0/Data/SEG_axi_bram_ctrl_0_Mem0}]
	set_property range 1M [get_bd_addr_segs {microblaze_0/Instruction/SEG_axi_bram_ctrl_0_Mem0}]
	}
	
	if { ($board_name == "vcu128") || ($board_name == "vcu129") || ($board_name == "vcu129_es") } {
	
	set_property -dict [list CONFIG.M01_HAS_REGSLICE {1}] [get_bd_cells microblaze_0_axi_periph] } 
	
	#creating the top.xdc constraints
	set proj_dir [get_property DIRECTORY [current_project ]]
	set proj_name [get_property NAME [current_project ]]
	set board_name [get_property NAME [current_board_part]]
	file mkdir $proj_dir/$proj_name.srcs/constrs_1/constrs
	set Include_Ethernet [set Include_ddr ""]
	set Include_Ethernet [get_ips ${design_name}_axi_ethernet_0_0]
	set Include_ddr [get_ips ${design_name}_ddr4_0_0]
	set fd [ open $proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc w ]
	if { $Include_ddr != {}} {
			
			puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */addn_ui_clkout1}\]"
			puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}\]"
	     }
	
	  if { $Include_Ethernet != ""} {
			  
			if {[regexp vcu108 $board_name] || [regexp kcu105 $board_name] || [regexp vcu110 $board_name]} {
				puts $fd "create_clock -period 1.6 \[get_ports sgmii_phyclk_clk_p\]"
			}
				 
			if {[regexp vcu110 $board_name]} {
				puts $fd "set_property LOC BITSLICE_RX_TX_X1Y347 \[get_cells -hier -filter {name =~ */pcs_pma_block_i/lvds_transceiver_mw/serdes_1_to_10_ser8_i/idelay_cal}\]"
			}
			
			if {[regexp vcu108 $board_name]} {
				puts $fd "set_property LOC BITSLICE_RX_TX_X1Y25  \[get_cells -hier -filter {name =~ */pcs_pma_block_i/lvds_transceiver_mw/serdes_1_to_10_ser8_i/idelay_cal}\]"
			}
			
			if {[regexp kcu105 $board_name]} {
				puts $fd "set_property LOC BITSLICE_RX_TX_X1Y79  \[get_cells -hier -filter {name =~ */pcs_pma_block_i/lvds_transceiver_mw/serdes_1_to_10_ser8_i/idelay_cal}\]"
			}				
	    }
	  if {[regexp vcu118 $board_name]} {
			puts $fd "set_property BITSTREAM.GENERAL.COMPRESS TRUE \[current_design\]"
		}
          if {[regexp vc707 $board_name]} {
			puts $fd "create_clock -period 8 \[get_ports sgmii_mgt_clk_clk_p\]"
		}
		
          if {[regexp vc709 $board_name]} {
			puts $fd "create_clock -period 8 \[get_ports sfp_mgt_clk_clk_p\]"
		}
		
      if {[regexp ac701 $board_name]||[regexp sp701 $board_name]} {

			puts $fd "# All the delay numbers have to provided by the user"
			puts $fd "# CCLK delay is 0.5, 6.7 ns min/max for K7-2; refer Datasheet"
			puts $fd "# We need to consider the max delay for worst case analysis"
			
			puts $fd "set cclk_delay 6.7"
			puts $fd "# Following are the SPI device parameters"
			puts $fd "# Max Tco"
			puts $fd "set tco_max 7"
			puts $fd "# Min Tco"
			puts $fd "set tco_min 1"
			
			puts $fd "# Setup time requirement"
			puts $fd "set tsu 2"
			
			puts $fd "# Hold time requirement"
			puts $fd "set th 3"
			
			puts $fd "# Following are the board/trace delay numbers"
			puts $fd "# Assumption is that all Data lines are matched"
			puts $fd "set tdata_trace_delay_max 0.25"
			puts $fd "set tdata_trace_delay_min 0.25"
			puts $fd "set tclk_trace_delay_max 0.2"
			puts $fd "set tclk_trace_delay_min 0.2"
			
			puts $fd "### End of user provided delay numbers"
			
			
			puts $fd "# This is to ensure min routing delay from SCK generation to STARTUP input"
			puts $fd "# User should change this value based on the results"
			puts $fd "# Having more delay on this net reduces the Fmax"
			
			puts $fd "set_max_delay 1.5 -from \[get_pins -hier *SCK_O_reg_reg/C\] -to \[get_pins -hier *USRCCLKO\] -datapath_only"
			puts $fd "set_min_delay 0.1 -from \[get_pins -hier *SCK_O_reg_reg/C\] -to \[get_pins -hier *USRCCLKO\]"
			
			puts $fd "# Following command creates a divide by 2 clock"
			puts $fd "# It also takes into account the delay added by STARTUP block to route the CCLK"
			puts $fd "# This constraint is not needed when STARTUP block is disabled"
			
			puts $fd "create_generated_clock  -name clk_sck -source \[get_pins -hierarchical *axi_quad_spi_0/ext_spi_clk\] \[get_pins -hierarchical *USRCCLKO\] -edges {3 5 7} -edge_shift \[list \$cclk_delay \$cclk_delay \$cclk_delay\]"
			
			puts $fd "# Data is captured into FPGA on the second rising edge of ext_spi_clk after the SCK falling edge"
			puts $fd "# Data is driven by the FPGA on every alternate rising_edge of ext_spi_clk"
			
			puts $fd "#spi_flash_io0_io"
			
			puts $fd "set_input_delay -clock clk_sck -max \[expr \$tco_max + \$tdata_trace_delay_max + \$tclk_trace_delay_max\] \[get_ports spi_flash_io*io\] -clock_fall;"
			
			puts $fd "set_input_delay -clock clk_sck -min \[expr \$tco_min + \$tdata_trace_delay_min + \$tclk_trace_delay_min\] \[get_ports spi_flash_io*io\] -clock_fall;"
			
			puts $fd "set_multicycle_path 2 -setup -from clk_sck -to \[get_clocks -of_objects \[get_pins -hierarchical */ext_spi_clk\]\]"
			puts $fd "set_multicycle_path 1 -hold -end -from clk_sck -to \[get_clocks -of_objects \[get_pins -hierarchical */ext_spi_clk\]\]"
			
			puts $fd "# Data is captured into SPI on the following rising edge of SCK"
			puts $fd "# Data is driven by the IP on alternate rising_edge of the ext_spi_clk"
			
			puts $fd "set_output_delay -clock clk_sck -max \[expr \$tsu + \$tdata_trace_delay_max - \$tclk_trace_delay_min\] \[get_ports spi_flash_io*io\];"
			puts $fd "set_output_delay -clock clk_sck -min \[expr \$tdata_trace_delay_min -\$th - \$tclk_trace_delay_max\] \[get_ports spi_flash_io*io\];"
			
			puts $fd "set_multicycle_path 2 -setup -start -from \[get_clocks -of_objects \[get_pins -hierarchical */ext_spi_clk\]\] -to clk_sck"
			puts $fd "set_multicycle_path 1 -hold -from \[get_clocks -of_objects \[get_pins -hierarchical */ext_spi_clk\]\] -to clk_sck"
		}

		
	close $fd
	add_files  -fileset constrs_1 [ list "$proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc" ] 
	
  } else {
	puts "ERROR: INVALID PRESET OPTION SELECTED" }

	set int_num [llength $inpt]
	set i 0
	set_property -dict [list CONFIG.NUM_PORTS "$int_num"] [get_bd_cells microblaze_0_xlconcat]
	foreach item $inpt {
	 puts "connect_bd_net [get_bd_pins $item] [get_bd_pins /microblaze_0_xlconcat/In$i]"
	 puts "[connect_bd_net [get_bd_pins $item] [get_bd_pins /microblaze_0_xlconcat/In$i]]"
	 incr i
	}
	
	set gpios_list [ get_board_component_interfaces -filter {BUSDEF_NAME == gpio_rtl} ]
	set gpio_cnt 0
	foreach gpio $gpios_list {
		set gpio_cnt [expr $gpio_cnt + 1]
		if { $gpio_cnt % 2 == 1} {
			create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_[expr $gpio_cnt/2]
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_gpio_[expr $gpio_cnt/2]/S_AXI]
			apply_board_connection -board_interface "$gpio" -ip_intf "axi_gpio_[expr $gpio_cnt/2]/GPIO" -diagram $design_name
			} else {
			apply_board_connection -board_interface "$gpio" -ip_intf "axi_gpio_[expr (($gpio_cnt - 1)/2)]/GPIO2" -diagram $design_name
			}
	}
	regenerate_bd_layout
	validate_bd_design
	make_wrapper -files [get_files $design_name.bd] -top -import
}

puts "INFO: End of create_root_design"

##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $design_name $options 

	# close_bd_design [get_bd_designs $design_name]
	# set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
	open_bd_design [get_bd_files $design_name]
}