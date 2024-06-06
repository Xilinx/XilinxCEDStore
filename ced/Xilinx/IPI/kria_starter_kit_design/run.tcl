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

proc createDesign {design_name options} {  

##################################################################
# DESIGN PROCs													 
##################################################################
variable currentDir
set_property target_language Verilog [current_project]

proc create_root_design {design_name prst} {

puts "create_root_design"
set board_part [get_property NAME [current_board_part]]
#set board_name [get_property BOARD_NAME [current_board]]
set board_name [lindex [split [get_property BASE_BOARD_PART [current_project]] ":"] 1]
#set fpga_part [get_property PART_NAME [current_board_part]]
puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
#puts "INFO: $fpga_part is selected"

#if {([lsearch $options Preset.VALUE] == -1) || ([lsearch $options "Default_Bitstream"] != -1)} 
if {$prst == "Default_Bitstream" } {

	puts "INFO: Default_Bitstream preset is enabled" 
} else {
	puts "INFO: BRAM_GPIO preset is enabled" }
	
  # Create ports
  set fan_en_b [ create_bd_port -dir O -from 0 -to 0 fan_en_b ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {3} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_0

  set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0 ] 
  
  apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1"} [get_bd_cells zynq_ultra_ps_e_0]
  set_property -dict [list \
  CONFIG.PSU__USE__M_AXI_GP0 {0} \
  CONFIG.PSU__USE__M_AXI_GP1 {0} \
  CONFIG.PSU__TTC0__WAVEOUT__ENABLE {1} \
  CONFIG.PSU__TTC0__WAVEOUT__IO {EMIO} ]  [get_bd_cells zynq_ultra_ps_e_0]
 
 if {($board_name == "k26c")||($board_name == "k26i")} {
  set_property -dict [list \
  CONFIG.PSU__UART0__PERIPHERAL__ENABLE {0} \
  CONFIG.PSU__UART1__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__UART1__PERIPHERAL__IO {MIO 36 .. 37} \
] [get_bd_cells zynq_ultra_ps_e_0] }
  
# Create port connections
  connect_bd_net -net xlslice_0_Dout [get_bd_ports fan_en_b] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net zynq_ultra_ps_e_0_emio_ttc0_wave_o [get_bd_pins xlslice_0/Din] [get_bd_pins zynq_ultra_ps_e_0/emio_ttc0_wave_o]

#if {[lsearch $options "BRAM_GPIO"] != -1} 
if {$prst == "BRAM_GPIO" } {

  set_property -dict [ list \
  CONFIG.PSU__USE__M_AXI_GP0  {1} \
  ] [get_bd_cells zynq_ultra_ps_e_0] 

# Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.ECC_TYPE {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen axi_bram_ctrl_0_bram ]

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
 
  if {$board_name == "kv260_som"} {
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {0} \
   CONFIG.C_ALL_OUTPUTS {0} \
   CONFIG.C_GPIO_WIDTH {8} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_gpio_0

  # Create interface ports
  set pmod_gpio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 pmod_gpio ]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports pmod_gpio] [get_bd_intf_pins axi_gpio_0/GPIO]

} elseif {$board_name == "kr260_som" } {
apply_board_connection -board_interface "som240_1_connector_pmod1_gpio" -ip_intf "axi_gpio_0/GPIO" -diagram $design_name

} elseif {$board_name == "kd240_som" } {
apply_board_connection -board_interface "som240_1_connector_pmod_gpio" -ip_intf "axi_gpio_0/GPIO" -diagram $design_name }

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc ]
  set_property -dict [ list \
   CONFIG.NUM_MI {2} \
   CONFIG.NUM_SI {1} \
 ] $axi_smc

  # Create instance: rst_ps8_0_99M, and set properties
  set rst_ps8_0_99M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ps8_0_99M ]

 # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_smc/M00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M01_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins axi_smc/M01_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_FPD [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]
 #connect_bd_net -net xlslice_0_Dout [get_bd_ports fan_en_b] [get_bd_pins xlslice_0/Dout]
  #connect_bd_net -net zynq_ultra_ps_e_0_emio_ttc0_wave_o [get_bd_pins xlslice_0/Din] [get_bd_pins zynq_ultra_ps_e_0/emio_ttc0_wave_o]

  # Create port connections
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] -boundary_type upper
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_smc/aresetn] -boundary_type upper
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_smc/aclk] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins rst_ps8_0_99M/slowest_sync_clk] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins rst_ps8_0_99M/ext_reset_in] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]
}

}
##################################################################
# MAIN FLOW
##################################################################

#set the default preset values 
set preset_param "Preset.VALUE"
set prst Default_Bitstream
if { [dict exists $options $preset_param] } {
	set prst [dict get $options $preset_param ]
}
puts "$prst is seletced!"

set board_name [get_property BOARD_NAME [current_board]]
#set board_name [lindex [split [get_property BASE_BOARD_PART [current_project]] ":"] 1]
if {$board_name == "kd240_som"} {
set_property board_connections {som240_1_connector xilinx.com:kd240_carrier:som240_1_connector:* som40_2_connector xilinx.com:kd240_carrier:som40_2_connector:*} [current_project]

} elseif {$board_name == "kr260_som"} { 
set_property board_connections {som240_1_connector xilinx.com:kr260_carrier:som240_1_connector:* som240_2_connector xilinx.com:kr260_carrier:som240_2_connector:*} [current_project]

} elseif {$board_name == "kv260_som"} {
#set connector [lindex [get_boards *kv260_carrier*] end] 
#set version [lindex [split $connector ":"] end]
set_property board_connections {som240_1_connector xilinx.com:kv260_carrier:som240_1_connector:*} [current_project]
}

create_root_design $design_name $prst 

# #Platform Properties
# set proj_dir [pwd]
# set fd [open $proj_dir/README.hw w]

# puts $fd "##########################################################################"
# puts $fd "This is a brief document containing design specific details for : ${board_name}"
# puts $fd "This is auto-generated by Petalinux ref-design builder created @ [clock format [clock seconds] -format {%a %b %d %H:%M:%S %Z %Y}]"
# puts $fd "##########################################################################"

# set board_part [get_board_parts [current_board_part -quiet]]
# if { $board_part != ""} {
	# puts $fd "BOARD: $board_part" 
# }

# set design_name [get_property NAME [get_bd_designs]]
# puts $fd "BLOCK DESIGN: $design_name" 

# set columns {%40s%30s%15s%50s}
# puts $fd [string repeat - 150]
# puts $fd [format $columns "MODULE INSTANCE NAME" "IP TYPE" "IP VERSION" "IP"]
# puts $fd [string repeat - 150]

# foreach ip [get_ips] {
	# set catlg_ip [get_ipdefs -all [get_property IPDEF $ip]]	
	# puts $fd [format $columns [get_property NAME $ip] [get_property NAME $catlg_ip] [get_property VERSION $catlg_ip] [get_property VLNV $catlg_ip]]
# }
# close $fd

#Adding PMOD pin constraints 
if {$board_name == "kv260_som"} {

if {$prst == "Default_Bitstream"} {
set xdc [file join $currentDir xdc default.xdc]
} else {
set xdc [file join $currentDir xdc pmod_gpio.xdc] }

} elseif {($board_name == "kd240_som")||($board_name == "k24c")||($board_name == "k24i")} {
set xdc [file join $currentDir xdc kd240_default.xdc]

} elseif {($board_name == "kr260_som")||($board_name == "k26c")||($board_name == "k26i")} {
set xdc [file join $currentDir xdc default.xdc]
}

import_files -fileset constrs_1 -norecurse $xdc

set_property platform.board_id $design_name [current_project]  
set_property platform.extensible false [current_project]
set_property platform.ip_cache_dir [get_property ip_output_repo [current_project]] [current_project]   
set_property platform.name $design_name [current_project]
set_property platform.vendor "xilinx" [current_project]
set_property platform.version "1.0" [current_project]

assign_bd_address
validate_bd_design
save_bd_design
make_wrapper -files [get_files $design_name.bd] -top -import
open_bd_design [get_bd_files $design_name]
regenerate_bd_layout
puts "INFO: End of create_root_design"
}