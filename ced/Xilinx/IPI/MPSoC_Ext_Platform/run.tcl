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

proc create_root_design {currentDir design_name use_ddr clk_options irqs_GIC} {

puts "create_root_design"
set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]
puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"

puts "INFO: selected irqs_GIC:: $irqs_GIC"
puts "INFO: selected design_name:: $design_name"
puts "INFO: selected use_ddr:: $use_ddr"
puts "INFO: selected clk_options:: $clk_options"

# set use_intc [set use_cascaded_irqs [set no_irqs ""]]
# set use_intc [ expr $irqs eq "16" ]
# set use_cascaded_irqs [ expr $irqs eq "32" ]
# set no_irqs [ expr $irqs eq "0" ]

# Create instance: axi_intc_0, and set properties
set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
set_property -dict [ list CONFIG.C_ASYNC_INTR {0xFFFFFFFF} CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_IRQ_IS_LEVEL {1} ] $axi_intc_0 

# Create instance: axi_interconnect_lpd, and set properties
set axi_interconnect_lpd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_lpd ]
set_property -dict [ list CONFIG.NUM_MI {1} ] $axi_interconnect_lpd

# Create instance: axi_register_slice_0, and set properties
set axi_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice axi_register_slice_0 ]
set_property -dict [ list CONFIG.DATA_WIDTH {128} ] $axi_register_slice_0

# Create instance: axi_vip_0, and set properties
set axi_vip_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip axi_vip_0 ]
set_property -dict [ list \
 CONFIG.ADDR_WIDTH {32} \
 CONFIG.ARUSER_WIDTH {0} \
 CONFIG.AWUSER_WIDTH {0} \
 CONFIG.BUSER_WIDTH {0} \
 CONFIG.DATA_WIDTH {32} \
 CONFIG.HAS_BRESP {1} \
 CONFIG.HAS_BURST {1} \
 CONFIG.HAS_CACHE {1} \
 CONFIG.HAS_LOCK {1} \
 CONFIG.HAS_PROT {1} \
 CONFIG.HAS_QOS {1} \
 CONFIG.HAS_REGION {1} \
 CONFIG.HAS_RRESP {1} \
 CONFIG.HAS_WSTRB {1} \
 CONFIG.ID_WIDTH {0} \
 CONFIG.INTERFACE_MODE {MASTER} \
 CONFIG.PROTOCOL {AXI4} \
 CONFIG.READ_WRITE_MODE {READ_WRITE} \
 CONFIG.RUSER_BITS_PER_BYTE {0} \
 CONFIG.RUSER_WIDTH {0} \
 CONFIG.SUPPORTS_NARROW {1} \
 CONFIG.WUSER_BITS_PER_BYTE {0} \
 CONFIG.WUSER_WIDTH {0} \
 ] $axi_vip_0

# Create instance: axi_vip_1, and set properties
set axi_vip_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip axi_vip_1 ]
set_property -dict [ list \
 CONFIG.ADDR_WIDTH {32} \
 CONFIG.ARUSER_WIDTH {0} \
 CONFIG.AWUSER_WIDTH {0} \
 CONFIG.BUSER_WIDTH {0} \
 CONFIG.DATA_WIDTH {32} \
 CONFIG.HAS_BRESP {1} \
 CONFIG.HAS_BURST {1} \
 CONFIG.HAS_CACHE {1} \
 CONFIG.HAS_LOCK {1} \
 CONFIG.HAS_PROT {1} \
 CONFIG.HAS_QOS {1} \
 CONFIG.HAS_REGION {1} \
 CONFIG.HAS_RRESP {1} \
 CONFIG.HAS_WSTRB {1} \
 CONFIG.ID_WIDTH {0} \
 CONFIG.INTERFACE_MODE {MASTER} \
 CONFIG.PROTOCOL {AXI4} \
 CONFIG.READ_WRITE_MODE {READ_WRITE} \
 CONFIG.RUSER_BITS_PER_BYTE {0} \
 CONFIG.RUSER_WIDTH {0} \
 CONFIG.SUPPORTS_NARROW {1} \
 CONFIG.WUSER_BITS_PER_BYTE {0} \
 CONFIG.WUSER_WIDTH {0} \
 ] $axi_vip_1


# Create instance: ps_e, and set properties
set ps_e [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e ps_e ]
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells ps_e]
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP5 {1} CONFIG.PSU__USE__S_AXI_GP6 {1} CONFIG.PSU__SAXIGP6__DATA_WIDTH {32} CONFIG.PSU__USE__M_AXI_GP1 {0} CONFIG.PSU__USE__M_AXI_GP2 {1} CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333333} ] [get_bd_cells ps_e]
#set_property -dict [list CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333333}] [get_bd_cells ps_e]
#set_property -dict [list CONFIG.PSU__USE__M_AXI_GP1 {0} CONFIG.PSU__USE__M_AXI_GP2 {1}] [get_bd_cells ps_e]

if {$irqs_GIC} {
set_property -dict [list CONFIG.PSU__USE__IRQ1 {1}] [get_bd_cells ps_e] }

# Cclocks optins, and set properties
set clk_freqs [ list 100.000 200.000 300.000 100.000 100.000 100.000 100.000 ]
set clk_used [list true false false false false false false ]
set clk_ports [list clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 ]
set default_clk_port clk_out1
set default_clk_num 0

set i 0
set clocks {}
foreach { port freq id is_default } $clk_options {
    lset clk_ports $i $port
    lset clk_freqs $i $freq
    lset clk_used $i true
    if { $is_default } {
      set default_clk_port $port
      set default_clk_num $i
    }
    dict append clocks clk_out$i { id $id is_default $is_default proc_sys_reset "proc_sys_reset$i" status "fixed" }
    incr i
}
set num_clks $i

# Create instance: clk_wiz_0, and set properties
set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0 ]
set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] [get_bd_cells clk_wiz_0]

# Creating clk frequenices  to instance: clk_wiz_0.
for {set i 0} {$i < $num_clks} {incr i} {  
set freq_hz$i [lindex $clk_freqs $i] }
  
  if { $num_clks == 1 } {
	set_property -dict [ list CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $freq_hz0 ] $clk_wiz_0 }
	
  if { $num_clks == 2 } {
	set_property -dict [ list CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $freq_hz0 CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $freq_hz1 ] $clk_wiz_0 }
  
  if { $num_clks == 3 } {
	set_property -dict [ list CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $freq_hz0 CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $freq_hz1 \
	CONFIG.CLKOUT3_USED {true} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $freq_hz2] $clk_wiz_0 } 
  
  if { $num_clks == 4 } {
	set_property -dict [ list CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $freq_hz0 CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $freq_hz1 \
	CONFIG.CLKOUT3_USED {true} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $freq_hz2 CONFIG.CLKOUT4_USED {true} CONFIG.CLKOUT4_REQUESTED_OUT_FREQ $freq_hz3 ] $clk_wiz_0 }
	
   if { $num_clks == 5 } {
	set_property -dict [ list CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $freq_hz0 CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $freq_hz1 \
	CONFIG.CLKOUT3_USED {true} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $freq_hz2 CONFIG.CLKOUT4_USED {true} CONFIG.CLKOUT4_REQUESTED_OUT_FREQ $freq_hz3 \
	CONFIG.CLKOUT5_USED {true} CONFIG.CLKOUT5_REQUESTED_OUT_FREQ $freq_hz4 ] $clk_wiz_0 }
	
   if { $num_clks == 6 } {
	set_property -dict [ list CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $freq_hz0 CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $freq_hz1 \
	CONFIG.CLKOUT3_USED {true} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $freq_hz2 CONFIG.CLKOUT4_USED {true} CONFIG.CLKOUT4_REQUESTED_OUT_FREQ $freq_hz3 \
	CONFIG.CLKOUT5_USED {true} CONFIG.CLKOUT5_REQUESTED_OUT_FREQ $freq_hz4 CONFIG.CLKOUT6_USED {true} CONFIG.CLKOUT6_REQUESTED_OUT_FREQ $freq_hz5 ] $clk_wiz_0 }

   if { $num_clks == 7 } {
	set_property -dict [ list CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $freq_hz0 CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $freq_hz1 \
	CONFIG.CLKOUT3_USED {true} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $freq_hz2 CONFIG.CLKOUT4_USED {true} CONFIG.CLKOUT4_REQUESTED_OUT_FREQ $freq_hz3 \
	CONFIG.CLKOUT5_USED {true} CONFIG.CLKOUT5_REQUESTED_OUT_FREQ $freq_hz4 CONFIG.CLKOUT6_USED {true} CONFIG.CLKOUT6_REQUESTED_OUT_FREQ $freq_hz5 \
	CONFIG.CLKOUT7_USED {true} CONFIG.CLKOUT7_REQUESTED_OUT_FREQ $freq_hz6] $clk_wiz_0 }	

for {set i 0} {$i < $num_clks} {incr i} {
  # Create instance: proc_sys_reset_N, and set properties
  set proc_sys_reset_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_$i ] } 

for {set i 0} {$i < $num_clks} {incr i} {
    set port [lindex $clk_ports $i]
    #connect_bd_net -net clk_wizard_0_$port [get_bd_pins clk_wizard_0/$port] [get_bd_pins proc_sys_reset_$i/slowest_sync_clk]
	connect_bd_net [get_bd_pins clk_wiz_0/$port] [get_bd_pins proc_sys_reset_$i/slowest_sync_clk]	}

for {set i 0} {$i < $num_clks} {incr i} {
  connect_bd_net -net Net [get_bd_pins clk_wiz_0/resetn] [get_bd_pins ps_e/pl_resetn0] [get_bd_pins proc_sys_reset_$i/ext_reset_in]
  connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins proc_sys_reset_$i/dcm_locked] }

#create default clock connection
set default_clock_net clk_wiz_0_$default_clk_port

# Create instance: interconnect_axifull, and set properties
set interconnect_axifull [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect interconnect_axifull ]
set_property -dict [ list CONFIG.NUM_MI {1} ] $interconnect_axifull
set_property HDL_ATTRIBUTE.DPA_TRACE_SLAVE {true} [get_bd_cells interconnect_axifull]

if {!$use_ddr } { 
# Create instance: interconnect_axihpm0fpd, and set properties
set interconnect_axihpm0fpd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect interconnect_axihpm0fpd ]
set_property -dict [ list CONFIG.NUM_MI {1} ] $interconnect_axihpm0fpd
set_property HDL_ATTRIBUTE.DPA_TRACE_MASTER {true} [get_bd_cells interconnect_axihpm0fpd] }

# Create instance: interconnect_axilite, and set properties
set interconnect_axilite [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect interconnect_axilite ]
set_property -dict [ list CONFIG.NUM_MI {1} ] $interconnect_axilite
set_property HDL_ATTRIBUTE.DPA_AXILITE_MASTER {fallback} [get_bd_cells interconnect_axilite]

if {$use_ddr } {
set ddr4_board_interface [board::get_board_part_interfaces *ddr4*]
set ddr4_board_interface_1 [lindex [split $ddr4_board_interface { }] 0]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc
set_property -dict [list CONFIG.NUM_MI {2} CONFIG.NUM_SI {1} CONFIG.NUM_CLKS {2}] [get_bd_cells axi_smc]
#set_property -dict [list CONFIG.NUM_CLKS {2}] [get_bd_cells axi_smc]

create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:* pl_ddr4
apply_board_connection -board_interface "$ddr4_board_interface_1" -ip_intf "pl_ddr4/C0_DDR4" -diagram $design_name

set rst_pl_ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pl_ddr4_0 ]
connect_bd_net -net pl_ddr4_c0_ddr4_ui_clk [get_bd_pins axi_smc/aclk1] [get_bd_pins pl_ddr4/c0_ddr4_ui_clk] [get_bd_pins rst_pl_ddr4_0/slowest_sync_clk]
connect_bd_net -net pl_ddr4_c0_ddr4_ui_clk_sync_rst [get_bd_pins pl_ddr4/c0_ddr4_ui_clk_sync_rst] [get_bd_pins rst_pl_ddr4_0/ext_reset_in]
connect_bd_net -net rst_pl_ddr4_0_peripheral_aresetn [get_bd_pins pl_ddr4/c0_ddr4_aresetn] [get_bd_pins rst_pl_ddr4_0/peripheral_aresetn]

connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins pl_ddr4/C0_DDR4_S_AXI]
connect_bd_intf_net -intf_net ps_e_M_AXI_HPM0_FPD [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins ps_e/M_AXI_HPM0_FPD]
#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_0/${default_clk_port} } Clk_slave {/pl_ddr4/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {/clk_wiz_0/${default_clk_port} } Master {/ps_e/M_AXI_HPM0_FPD} Slave {/pl_ddr4/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins pl_ddr4/C0_DDR4_S_AXI]

connect_bd_net -net $default_clock_net [get_bd_pins ps_e/maxihpm0_fpd_aclk] [get_bd_pins axi_smc/aclk]
connect_bd_net [get_bd_pins proc_sys_reset_${default_clk_num}/interconnect_aresetn] [get_bd_pins axi_smc/aresetn] 

set board_name [get_property BOARD_NAME [current_board]]
if {($board_name == "zcu104")||[regexp "vermeo" $board_name] } {
set def_clk [lindex [board::get_board_part_interfaces *clk*] 0] 
} else {
set def_clk [lindex [board::get_board_part_interfaces *syscl*] 0] }
apply_board_connection -board_interface "$def_clk" -ip_intf "pl_ddr4/C0_SYS_CLK" -diagram $design_name

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins pl_ddr4/sys_rst]
connect_bd_intf_net [get_bd_intf_pins axi_register_slice_0/S_AXI] [get_bd_intf_pins axi_smc/M01_AXI]
#connect_bd_net [get_bd_pins clk_wiz_0/resetn] [get_bd_pins ps_e/pl_resetn0]
catch {set S_AXI_CTRL [get_bd_intf_pins pl_ddr4/C0_DDR4_S_AXI_CTRL]}

if [regexp "C0_DDR4_S_AXI_CTRL" $S_AXI_CTRL] {
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_0/$default_clk_port (300 MHz)} Clk_slave {/pl_ddr4/c0_ddr4_ui_clk (333 MHz)} Clk_xbar {/clk_wiz_0/$default_clk_port (300 MHz)} Master {/ps_e/M_AXI_HPM0_FPD} Slave {/pl_ddr4/C0_DDR4_S_AXI_CTRL} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins pl_ddr4/C0_DDR4_S_AXI_CTRL]
} }

  # Create interface connections
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins interconnect_axilite/M00_AXI]
  connect_bd_net -net axi_intc_0_irq [get_bd_pins axi_intc_0/irq] [get_bd_pins ps_e/pl_ps_irq0] 
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI1 [get_bd_intf_pins axi_interconnect_lpd/M00_AXI] [get_bd_intf_pins ps_e/S_AXI_LPD]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins interconnect_axifull/M00_AXI] [get_bd_intf_pins ps_e/S_AXI_HP3_FPD]
  connect_bd_intf_net -intf_net axi_vip_0_M_AXI [get_bd_intf_pins axi_vip_0/M_AXI] [get_bd_intf_pins interconnect_axifull/S00_AXI]
  connect_bd_intf_net -intf_net axi_vip_1_M_AXI [get_bd_intf_pins axi_interconnect_lpd/S00_AXI] [get_bd_intf_pins axi_vip_1/M_AXI]
  connect_bd_intf_net -intf_net ps_e_M_AXI_HPM0_LPD [get_bd_intf_pins interconnect_axilite/S00_AXI] [get_bd_intf_pins ps_e/M_AXI_HPM0_LPD]

  # Create port connections
  connect_bd_net -net ps_e_pl_clk0 [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins ps_e/pl_clk0]
  connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_0/s_axi_aclk] [get_bd_pins axi_interconnect_lpd/ACLK] [get_bd_pins axi_interconnect_lpd/M00_ACLK] [get_bd_pins axi_interconnect_lpd/S00_ACLK] [get_bd_pins axi_register_slice_0/aclk] [get_bd_pins axi_vip_0/aclk] [get_bd_pins axi_vip_1/aclk] [get_bd_pins interconnect_axifull/ACLK] [get_bd_pins interconnect_axifull/M00_ACLK] [get_bd_pins interconnect_axifull/S00_ACLK] [get_bd_pins interconnect_axilite/ACLK] [get_bd_pins interconnect_axilite/M00_ACLK] [get_bd_pins interconnect_axilite/S00_ACLK] [get_bd_pins ps_e/maxihpm0_fpd_aclk] [get_bd_pins ps_e/maxihpm0_lpd_aclk] [get_bd_pins ps_e/saxi_lpd_aclk] [get_bd_pins ps_e/saxihp3_fpd_aclk]
  connect_bd_net -net proc_sys_reset_1_interconnect_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn] [get_bd_pins axi_interconnect_lpd/ARESETN] [get_bd_pins axi_interconnect_lpd/M00_ARESETN] [get_bd_pins axi_interconnect_lpd/S00_ARESETN] [get_bd_pins axi_vip_1/aresetn] [get_bd_pins interconnect_axifull/ARESETN] [get_bd_pins interconnect_axifull/M00_ARESETN] [get_bd_pins interconnect_axifull/S00_ARESETN] [get_bd_pins interconnect_axilite/ARESETN] [get_bd_pins interconnect_axilite/M00_ARESETN] [get_bd_pins interconnect_axilite/S00_ARESETN] 
  connect_bd_net [get_bd_pins proc_sys_reset_${default_clk_num}/interconnect_aresetn] [get_bd_pins axi_vip_1/aresetn]
  connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins axi_register_slice_0/aresetn] [get_bd_pins axi_vip_0/aresetn] 
  connect_bd_net [get_bd_pins proc_sys_reset_${default_clk_num}/peripheral_aresetn] [get_bd_pins axi_vip_0/aresetn] 
  

  if {!$use_ddr } { 
  connect_bd_intf_net -intf_net interconnect_axihpm0fpd_M00_AXI [get_bd_intf_pins axi_register_slice_0/S_AXI] [get_bd_intf_pins interconnect_axihpm0fpd/M00_AXI]
  connect_bd_intf_net -intf_net ps_e_M_AXI_HPM0_FPD [get_bd_intf_pins interconnect_axihpm0fpd/S00_AXI] [get_bd_intf_pins ps_e/M_AXI_HPM0_FPD]
  
  connect_bd_net -net $default_clock_net [get_bd_pins interconnect_axihpm0fpd/ACLK] [get_bd_pins interconnect_axihpm0fpd/M00_ACLK] [get_bd_pins interconnect_axihpm0fpd/S00_ACLK] [get_bd_pins ps_e/maxihpm0_fpd_aclk]
  connect_bd_net [get_bd_pins proc_sys_reset_${default_clk_num}/interconnect_aresetn] [get_bd_pins interconnect_axihpm0fpd/ARESETN] [get_bd_pins interconnect_axihpm0fpd/M00_ARESETN] [get_bd_pins interconnect_axihpm0fpd/S00_ARESETN]
}
  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_vip_0/Master_AXI] [get_bd_addr_segs ps_e/SAXIGP5/HP3_DDR_LOW] -force
  assign_bd_address -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces axi_vip_0/Master_AXI] [get_bd_addr_segs ps_e/SAXIGP5/HP3_LPS_OCM] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_vip_0/Master_AXI] [get_bd_addr_segs ps_e/SAXIGP5/HP3_QSPI] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_vip_1/Master_AXI] [get_bd_addr_segs ps_e/SAXIGP6/LPD_DDR_LOW] -force
  assign_bd_address -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces axi_vip_1/Master_AXI] [get_bd_addr_segs ps_e/SAXIGP6/LPD_LPS_OCM] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_vip_1/Master_AXI] [get_bd_addr_segs ps_e/SAXIGP6/LPD_QSPI] -force
  assign_bd_address -offset 0x80020000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs axi_intc_0/S_AXI/Reg] -force

  if {$use_ddr } {
  assign_bd_address -offset 0x000400000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs pl_ddr4/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  exclude_bd_addr_seg [get_bd_addr_segs ps_e/SAXIGP5/HP3_PCIE_LOW] -target_address_space [get_bd_addr_spaces axi_vip_0/Master_AXI]
  exclude_bd_addr_seg [get_bd_addr_segs ps_e/SAXIGP6/LPD_PCIE_LOW] -target_address_space [get_bd_addr_spaces axi_vip_1/Master_AXI]  }
  
  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces axi_vip_0/Master_AXI] [get_bd_addr_segs ps_e/SAXIGP5/HP3_DDR_HIGH]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces axi_vip_1/Master_AXI] [get_bd_addr_segs ps_e/SAXIGP6/LPD_DDR_HIGH]
}
##################################################################
# MAIN FLOW
##################################################################
# puts "INFO: design_name:: $design_name and options:: $options is selected from GUI"
# get the clock options

set clk_options_param "Clock_Options.VALUE"
set clk_options { clk_out1 75.000 0 true clk_out2 150.000 1 false clk_out3 300.000 2 false }
if { [dict exists $options $clk_options_param] } {
#puts "INFO: selected clk_options:: $clk_options from IF"
    set clk_options [ dict get $options $clk_options_param ]
}

#puts "INFO: selected clk_options:: $clk_options"
set pl_ddr "Include_DDR.VALUE"
set use_ddr 0
if { [dict exists $options $pl_ddr] } {
#puts "INFO: selected use_lpddr:: $use_lpddr  FROM IF"
    set use_ddr [dict get $options $pl_ddr ]
}

#  32 (interrupt controller) / 16 (interrupt controller)
set irqs_param "Include_IRQS16.VALUE"
set irqs_GIC 0
if { [dict exists $options $irqs_param] } {
#puts "INFO: selected irqs:: $irqs FROM IF"
    set irqs_GIC [dict get $options $irqs_param ]
}
#puts "INFO: selected irqs:: $irqs"

create_root_design $currentDir $design_name $use_ddr $clk_options $irqs_GIC
	
open_bd_design [get_bd_files $design_name]
puts "INFO: Block design generation completed, yet to set PFM properties"
set board_name [get_property BOARD_NAME [current_board]]

# Create PFM attributes
set_property PFM_NAME "xilinx.com:xd:${board_name}:1.0" [get_files [current_bd_design].bd]

set_property PFM.IRQ {intr {id 0 range 32}} [get_bd_cells /axi_intc_0]
if {$irqs_GIC} {
set_property PFM.IRQ {pl_ps_irq1 {id 1 range 7}} [get_bd_cells /ps_e] }

set clocks {}
       set i 0
       foreach { port freq id is_default } $clk_options {
           dict append clocks $port "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed\""
           incr i
       }
set_property PFM.CLOCK $clocks [get_bd_cells /clk_wiz_0]

set_property PFM.AXI_PORT {M_AXI_HPM1_FPD {memport "M_AXI_GP"} S_AXI_HPC0_FPD {memport "S_AXI_HPC" sptag "HPC0" memory "ps_e HPC0_DDR_LOW"}  S_AXI_HPC1_FPD {memport "S_AXI_HPC" sptag "HPC1" memory "ps_e HPC1_DDR_LOW"}  S_AXI_HP0_FPD {memport "S_AXI_HP" sptag "HP0" memory "ps_e HP0_DDR_LOW"}  S_AXI_HP1_FPD {memport "S_AXI_HP" sptag "HP1" memory "ps_e HP1_DDR_LOW"}  S_AXI_HP2_FPD {memport "S_AXI_HP" sptag "HP2" memory "ps_e HP2_DDR_LOW"}} [get_bd_cells /ps_e]

set parVal []
for {set i 1} {$i < 64} {incr i} {
  lappend parVal M[format %02d $i]_AXI {memport "M_AXI_GP"}
}
set_property PFM.AXI_PORT $parVal [get_bd_cells /interconnect_axilite]

set hp3Val []
for {set i 1} {$i < 16} {incr i} {
  lappend hp3Val S[format %02d $i]_AXI {memport "S_AXI_HP" sptag "HP3" memory "ps_e HP3_DDR_LOW"}
}
set_property PFM.AXI_PORT $hp3Val [get_bd_cells /interconnect_axifull]

set lpdVal []
for {set i 1} {$i < 16} {incr i} {
  lappend lpdVal S[format %02d $i]_AXI {memport "S_AXI_HP" sptag "LPD" memory "ps_e LPD_DDR_LOW"}
}
set_property PFM.AXI_PORT $lpdVal [get_bd_cells /axi_interconnect_lpd]

#Platform Properties
set_property platform.default_output_type "sd_card" [current_project]
set_property platform.design_intent.embedded "true" [current_project]
set_property platform.extensible "true" [current_project]
set_property platform.design_intent.server_managed "false" [current_project]
set_property platform.design_intent.external_host "false" [current_project]
set_property platform.design_intent.datacenter "false" [current_project]

validate_bd_design
save_bd_design
open_bd_design [get_bd_files $design_name]
regenerate_bd_layout
make_wrapper -files [get_files $design_name.bd] -top -import -quiet
puts "INFO: End of create_root_design"
}