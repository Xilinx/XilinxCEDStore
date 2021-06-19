
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



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell design_name temp_options} {

# puts "creat_root_desing"

set board_part [get_property NAME [current_board_part]]

set board_name [get_property BOARD_NAME [current_board]]

set fpga_part [get_property PART_NAME [current_board_part]]

puts "INFO: $board_name is selected"
puts "INFO: $board_part is selected"
puts "INFO: $fpga_part is selected"

  # Create interface ports
  set jesd_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 jesd_refclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $jesd_refclk

  set pcie_mgt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_mgt ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]


  # Create ports
  set rxn_0 [ create_bd_port -dir I -from 3 -to 0 rxn_0 ]
  set rxp_0 [ create_bd_port -dir I -from 3 -to 0 rxp_0 ]
  set sys_reset [ create_bd_port -dir I -type rst sys_reset ]
  set txn_0 [ create_bd_port -dir O -from 3 -to 0 txn_0 ]
  set txp_0 [ create_bd_port -dir O -from 3 -to 0 txp_0 ]

  # Create instance: bufg_gt_0, and set properties
  set bufg_gt_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_0 ]

  # Create instance: bufg_gt_1, and set properties
  set bufg_gt_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_1 ]

  # Create instance: jesd204c_rx, and set properties
  set jesd204c_rx [ create_bd_cell -type ip -vlnv xilinx.com:ip:jesd204c jesd204c_rx ]
  set_property -dict [ list \
   CONFIG.C_ENCODING {0} \
   CONFIG.C_LANES {1} \
   CONFIG.C_NODE_IS_TRANSMIT {0} \
 ] $jesd204c_rx

  # Create instance: jesd204c_tx, and set properties
  set jesd204c_tx [ create_bd_cell -type ip -vlnv xilinx.com:ip:jesd204c jesd204c_tx ]
  set_property -dict [ list \
   CONFIG.C_ENCODING {0} \
   CONFIG.C_LANES {1} \
 ] $jesd204c_tx

  # Create instance: pcie_phy_versal_0, and set properties
  set pcie_phy_versal_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_phy_versal pcie_phy_versal_0 ]
  set_property -dict [ list \
   CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {5.0_GT/s} \
   CONFIG.phy_coreclk_freq {250_MHz} \
 ] $pcie_phy_versal_0

  # Create instance: pcie_phy_versal_0_support
  create_hier_cell_pcie_phy_versal_0_support [current_bd_instance .] pcie_phy_versal_0_support

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_0 ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $util_ds_buf_0

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.PS_BOARD_INTERFACE {cips_fixed_io} \
 ] $versal_cips_0

  # Create interface connections
  connect_bd_intf_net -intf_net diff_clock_rtl_1 [get_bd_intf_ports jesd_refclk] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net jesd204c_0_GT_TX0 [get_bd_intf_pins jesd204c_tx/GT_TX0] [get_bd_intf_pins pcie_phy_versal_0_support/TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net jesd204c_1_GT_RX0 [get_bd_intf_pins jesd204c_rx/GT_RX0] [get_bd_intf_pins pcie_phy_versal_0_support/RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_GT_RX0 [get_bd_intf_pins pcie_phy_versal_0/GT_RX0] [get_bd_intf_pins pcie_phy_versal_0_support/RX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_GT_TX0 [get_bd_intf_pins pcie_phy_versal_0/GT_TX0] [get_bd_intf_pins pcie_phy_versal_0_support/TX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_gt_rxmargin_q0 [get_bd_intf_pins pcie_phy_versal_0/gt_rxmargin_q0] [get_bd_intf_pins pcie_phy_versal_0_support/gt_rxmargin_intf]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_pcie_mgt [get_bd_intf_ports pcie_mgt] [get_bd_intf_pins pcie_phy_versal_0/pcie_mgt]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_support_GT0_BUFGT [get_bd_intf_pins pcie_phy_versal_0/GT_BUFGT] [get_bd_intf_pins pcie_phy_versal_0_support/GT0_BUFGT]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_support_GT_Serial [get_bd_intf_pins pcie_phy_versal_0/GT0_Serial] [get_bd_intf_pins pcie_phy_versal_0_support/GT_Serial]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins pcie_phy_versal_0_support/pcie_refclk]

  # Create port connections
  connect_bd_net -net bufg_gt_0_usrclk [get_bd_pins bufg_gt_0/usrclk] [get_bd_pins pcie_phy_versal_0_support/ch2_txusrclk]
  connect_bd_net -net bufg_gt_1_usrclk [get_bd_pins bufg_gt_1/usrclk] [get_bd_pins pcie_phy_versal_0_support/ch2_rxusrclk]
  connect_bd_net -net pcie_phy_versal_0_gt_pcieltssm [get_bd_pins pcie_phy_versal_0/gt_pcieltssm] [get_bd_pins pcie_phy_versal_0_support/pcieltssm]
  connect_bd_net -net pcie_phy_versal_0_gtrefclk [get_bd_pins pcie_phy_versal_0/gtrefclk] [get_bd_pins pcie_phy_versal_0_support/GT_REFCLK0]
  connect_bd_net -net pcie_phy_versal_0_pcierstb [get_bd_pins pcie_phy_versal_0/pcierstb] [get_bd_pins pcie_phy_versal_0_support/ch0_pcierstb]
  connect_bd_net -net pcie_phy_versal_0_phy_pclk [get_bd_pins pcie_phy_versal_0/phy_pclk] [get_bd_pins pcie_phy_versal_0_support/ch0_txusrclk]
  connect_bd_net -net pcie_phy_versal_0_support_BUFG_GT_O [get_bd_pins jesd204c_rx/rx_core_clk] [get_bd_pins jesd204c_rx/s_axi_aclk] [get_bd_pins jesd204c_tx/s_axi_aclk] [get_bd_pins jesd204c_tx/tx_core_clk] [get_bd_pins pcie_phy_versal_0/phy_refclk] [get_bd_pins pcie_phy_versal_0_support/BUFG_GT_O]
  connect_bd_net -net pcie_phy_versal_0_support_IBUF_OUT [get_bd_pins pcie_phy_versal_0/phy_gtrefclk] [get_bd_pins pcie_phy_versal_0_support/IBUF_OUT]
  connect_bd_net -net pcie_phy_versal_0_support_ch0_phyready [get_bd_pins pcie_phy_versal_0/ch0_phyready] [get_bd_pins pcie_phy_versal_0_support/ch0_phyready]
  connect_bd_net -net pcie_phy_versal_0_support_ch0_phystatus [get_bd_pins pcie_phy_versal_0/ch0_phystatus] [get_bd_pins pcie_phy_versal_0_support/ch0_phystatus]
  connect_bd_net -net pcie_phy_versal_0_support_ch0_rxoutclk [get_bd_pins pcie_phy_versal_0/gt_rxoutclk] [get_bd_pins pcie_phy_versal_0_support/ch0_rxoutclk]
  connect_bd_net -net pcie_phy_versal_0_support_ch0_txoutclk [get_bd_pins pcie_phy_versal_0/gt_txoutclk] [get_bd_pins pcie_phy_versal_0_support/ch0_txoutclk]
  connect_bd_net -net pcie_phy_versal_0_support_ch1_txoutclk [get_bd_pins bufg_gt_0/outclk] [get_bd_pins pcie_phy_versal_0_support/ch1_txoutclk]
  connect_bd_net -net pcie_phy_versal_0_support_ch2_rxoutclk [get_bd_pins bufg_gt_1/outclk] [get_bd_pins pcie_phy_versal_0_support/ch2_rxoutclk]
  connect_bd_net -net pcie_phy_versal_0_support_txn_0 [get_bd_ports txn_0] [get_bd_pins pcie_phy_versal_0_support/txn_0]
  connect_bd_net -net pcie_phy_versal_0_support_txp_0 [get_bd_ports txp_0] [get_bd_pins pcie_phy_versal_0_support/txp_0]
  connect_bd_net -net rxn_0_1 [get_bd_ports rxn_0] [get_bd_pins pcie_phy_versal_0_support/rxn_0]
  connect_bd_net -net rxp_0_1 [get_bd_ports rxp_0] [get_bd_pins pcie_phy_versal_0_support/rxp_0]
  connect_bd_net -net sys_reset_1 [get_bd_ports sys_reset] [get_bd_pins pcie_phy_versal_0/phy_rst_n]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins pcie_phy_versal_0_support/GT_REFCLK1] [get_bd_pins util_ds_buf_0/IBUF_OUT]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  make_wrapper -files [get_files $design_name.bd] -top -import
 
  puts "INFO: End of create_root_design"
}



# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $design_name $options 
	# close_bd_design [get_bd_designs $design_name]
	# set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
	open_bd_design [get_bd_files $design_name]
	# Add USER_COMMENTS on $design_name
	set_property USER_COMMENTS.comment_0 {} [current_bd_design]
	set_property USER_COMMENTS.comment0 {Next Steps:
1. Synthesize and open synthesized design
2. Add top level constraints. Refer to README.md in below url for list of constraints to add. 
https://github.com/Xilinx/XilinxCEDStore/tree/2020.2/ced/Xilinx/IPI/Versal%20Combine_within_GT_quad
}
}