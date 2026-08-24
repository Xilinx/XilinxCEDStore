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

#delete_bd_objs [get_bd_cells ilconstant_0] [get_bd_nets ilconstant_0_dout]
disconnect_bd_net /ilconstant_0_dout [get_bd_pins CIPS_0/m_axi_fpd_aclk]

# Create instance: ctrl_smc, and set properties
set ctrl_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect ctrl_smc ]
set_property -dict [list \
  CONFIG.NUM_MI {4} \
  CONFIG.NUM_SI {1} \
] [get_bd_cells ctrl_smc]

connect_bd_intf_net [get_bd_intf_pins CIPS_0/M_AXI_FPD] [get_bd_intf_pins ctrl_smc/S00_AXI]
set_property HDL_ATTRIBUTE.DONT_TOUCH true [get_bd_intf_nets {CIPS_0_M_AXI_FPD}]

set clk_freqs [ list 100.000 100.000 100.000 100.000 100.000 100.000 100.000 ]

# Create instance: clk_wizard_0, and set properties
set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_0 ]
set_property -dict [ list \
CONFIG.CE_TYPE {HARDSYNC} \
   CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
   CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
   CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
   CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
   CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
   CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
   CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [join $clk_freqs ","] \
   CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
   CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
   CONFIG.JITTER_SEL {Min_O_Jitter} \
   CONFIG.PRIM_SOURCE {No_buffer} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
   CONFIG.USE_PHASE_ALIGNMENT {true} \
   CONFIG.USE_LOCKED {true} \
   CONFIG.USE_RESET {true} \
 ] $clk_wizard_0

# Create instance: axi_gpio_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:* axi_gpio_0
apply_board_connection -board_interface "gpio_led" -ip_intf "axi_gpio_0/GPIO" -diagram $design_name 

# Create instance: axi_gpio_1, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:* axi_gpio_1
apply_board_connection -board_interface "gpio_pb" -ip_intf "axi_gpio_1/GPIO" -diagram $design_name 

catch {set dip [get_board_part_interfaces  *gpio_dp*]}

if {$dip == "gpio_dp"} {
# Create instance: axi_gpio_2, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:* axi_gpio_2
apply_board_connection -board_interface "gpio_dp" -ip_intf "axi_gpio_2/GPIO" -diagram $design_name 
}
# Create instance: axi_bram_ctrl_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:* axi_bram_ctrl_0

apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto" }  [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]

connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M01_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M02_AXI] [get_bd_intf_pins axi_gpio_1/S_AXI]
connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M03_AXI] [get_bd_intf_pins axi_gpio_2/S_AXI] 

if {[regexp "vek280" $board_name]} {
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550 axi_uart16550_0
#apply_board_connection -board_interface "uart1_bank401" -ip_intf "axi_uart16550_0/UART" -diagram $design_name 
apply_board_connection -board_interface "sysctrl_uart" -ip_intf "axi_uart16550_0/UART" -diagram $design_name 
} elseif {[regexp "vpk180" $board_name]||[regexp "vpk120" $board_name]} {
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550 axi_uart16550_0
#apply_board_connection -board_interface "uart2_bank712" -ip_intf "axi_uart16550_0/UART" -diagram $design_name 
apply_board_connection -board_interface "sysctrl_uart" -ip_intf "axi_uart16550_0/UART" -diagram $design_name 
} 


if {[regexp "vek280" $board_name]||[regexp "vpk180" $board_name]||[regexp "vpk120" $board_name]} {
set_property -dict [list CONFIG.NUM_MI {5} ] [get_bd_cells ctrl_smc]
connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M04_AXI] [get_bd_intf_pins axi_uart16550_0/S_AXI] }

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_clk_wizard

# Create port connections
connect_bd_net [get_bd_pins CIPS_0/pl0_ref_clk] [get_bd_pins clk_wizard_0/clk_in1]
connect_bd_net [get_bd_pins CIPS_0/pl0_resetn] [get_bd_pins clk_wizard_0/resetn] [get_bd_pins rst_clk_wizard/ext_reset_in]

connect_bd_net [get_bd_pins clk_wizard_0/clk_out1] \
[get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
[get_bd_pins ctrl_smc/aclk] \
[get_bd_pins rst_clk_wizard/slowest_sync_clk] \
[get_bd_pins axi_gpio_0/s_axi_aclk] \
[get_bd_pins axi_gpio_1/s_axi_aclk] \
[get_bd_pins CIPS_0/m_axi_fpd_aclk] \
[get_bd_pins axi_gpio_2/s_axi_aclk] 
#[get_bd_pins axi_uart16550_0/s_axi_aclk]

connect_bd_net [get_bd_pins clk_wizard_0/locked] [get_bd_pins rst_clk_wizard/dcm_locked]
connect_bd_net [get_bd_pins rst_clk_wizard/peripheral_aresetn] \
[get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
[get_bd_pins axi_gpio_0/s_axi_aresetn] \
[get_bd_pins axi_gpio_1/s_axi_aresetn] \
[get_bd_pins axi_gpio_2/s_axi_aresetn] \
[get_bd_pins ctrl_smc/aresetn] 
#[get_bd_pins axi_uart16550_0/s_axi_aresetn]

if {[regexp "vek280" $board_name]||[regexp "vpk180" $board_name]||[regexp "vpk120" $board_name]} {
connect_bd_net [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins axi_uart16550_0/s_axi_aclk]
connect_bd_net [get_bd_pins clk_wizard_0/locked] [get_bd_pins axi_uart16550_0/s_axi_aresetn]
}