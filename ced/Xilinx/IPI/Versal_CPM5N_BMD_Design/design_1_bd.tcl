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
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version ""
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been major IP version changes between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the parameter settings of the IPs."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvn3716-vsvb2197-2LHP-e-S-es1
}


# CHANGE DESIGN NAME HERE
variable design_name_1
set design_name_1 design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name_1

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name_1} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name_1> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name_1 NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name_1 exists in project.

   if { $cur_design ne $design_name_1 } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name_1> from <$design_name_1> to <$cur_design> since current design is empty."
      set design_name_1 [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name_1 } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name_1> already exists in your project, please set the variable <design_name_1> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name_1}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name_1 exists in project.
   #    7) No opened design, design_name_1 exists in project.

   set errMsg "Design <$design_name_1> already exists in your project, please set the variable <design_name_1> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name_1 not in project.
   #    9) Current opened design, has components, but diff names, design_name_1 not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name_1> in project, so creating one..."

   create_bd_design $design_name_1

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name_1> as current_bd_design."
   current_bd_design $design_name_1

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name_1> is equal to \"$design_name_1\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:psx_wizard:*\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name_1

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
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


  # Create interface ports
  set PCIE0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT_0 ]

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]

  set pcie0_cfg_control_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie5_cfg_control_rtl:1.0 pcie0_cfg_control_0 ]

  set pcie0_cfg_ext_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_ext_rtl:1.0 pcie0_cfg_ext_0 ]

  set pcie0_cfg_fc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.1 pcie0_cfg_fc_0 ]

  set pcie0_cfg_interrupt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie0_cfg_interrupt_0 ]

  set pcie0_cfg_mgmt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie0_cfg_mgmt_0 ]

  set pcie0_cfg_msg_recd_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie0_cfg_msg_recd_0 ]

  set pcie0_cfg_msg_tx_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_mesg_tx_rtl:1.0 pcie0_cfg_msg_tx_0 ]

  set pcie0_cfg_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie5_cfg_status_rtl:1.0 pcie0_cfg_status_0 ]

  set pcie0_m_axis_cq_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_m_axis_cq_0 ]

  set pcie0_m_axis_rc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_m_axis_rc_0 ]

  set pcie0_s_axis_cc_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_s_axis_cc_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {128} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {165} \
   ] $pcie0_s_axis_cc_0

  set pcie0_s_axis_rq_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_s_axis_rq_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {128} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {373} \
   ] $pcie0_s_axis_rq_0

  set pcie0_transmit_fc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie0_transmit_fc_0 ]


  # Create ports
  set cpm_bot_user_clk_0 [ create_bd_port -dir O -type clk cpm_bot_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {pcie0_s_axis_cc_0:pcie0_s_axis_rq_0:pcie0_m_axis_rc_0:pcie0_m_axis_cq_0} \
 ] $cpm_bot_user_clk_0
  set pcie0_user_reset_0 [ create_bd_port -dir O -from 0 -to 0 -type rst pcie0_user_reset_0 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: psx_wizard_0, and set properties
  set psx_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psx_wizard psx_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM_CONFIG(CPM_PCIE0_CFG_CTL_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_CFG_EXT_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_CFG_FC_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_CFG_MGMT_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_CFG_STS_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MESG_RCVD_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MESG_TRANSMIT_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MODES) {PCIE} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MODE_SELECTION) {Advanced} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_64BIT) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_PREFETCHABLE) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_SIZE) {256} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PL_LINK_CAP_MAX_LINK_SPEED) {32.0_GT/s} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH) {X16} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_RC_STRADDLE_SIZE) {8_TLP} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_RQ_STRADDLE_SIZE) {4_TLP} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_TX_FC_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_PIPE_INTF_EN) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_RESET) {{ENABLE 1} {IO {PSX_MIO 18 .. 21}}} \
    CONFIG.PSX_PMCX_CONFIG(PSX_NUM_FABRIC_RESETS) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_EP_RESET1_IO) {PMCX_MIO_38} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_PMCPL_CLK0) {1} \
  ] $psx_wizard_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins psx_wizard_0/gt_refclk0]
  connect_bd_intf_net -intf_net pcie0_cfg_control_0_1 [get_bd_intf_ports pcie0_cfg_control_0] [get_bd_intf_pins psx_wizard_0/pcie0_cfg_control]
  connect_bd_intf_net -intf_net pcie0_cfg_interrupt_0_1 [get_bd_intf_ports pcie0_cfg_interrupt_0] [get_bd_intf_pins psx_wizard_0/pcie0_cfg_interrupt]
  connect_bd_intf_net -intf_net pcie0_cfg_mgmt_0_1 [get_bd_intf_ports pcie0_cfg_mgmt_0] [get_bd_intf_pins psx_wizard_0/pcie0_cfg_mgmt]
  connect_bd_intf_net -intf_net pcie0_s_axis_cc_0_1 [get_bd_intf_ports pcie0_s_axis_cc_0] [get_bd_intf_pins psx_wizard_0/pcie0_s_axis_cc]
  connect_bd_intf_net -intf_net pcie0_s_axis_rq_0_1 [get_bd_intf_ports pcie0_s_axis_rq_0] [get_bd_intf_pins psx_wizard_0/pcie0_s_axis_rq]
  connect_bd_intf_net -intf_net psx_wizard_0_PCIE0_GT [get_bd_intf_ports PCIE0_GT_0] [get_bd_intf_pins psx_wizard_0/PCIE0_GT]
  connect_bd_intf_net -intf_net psx_wizard_0_pcie0_cfg_ext [get_bd_intf_ports pcie0_cfg_ext_0] [get_bd_intf_pins psx_wizard_0/pcie0_cfg_ext]
  connect_bd_intf_net -intf_net psx_wizard_0_pcie0_cfg_fc [get_bd_intf_ports pcie0_cfg_fc_0] [get_bd_intf_pins psx_wizard_0/pcie0_cfg_fc]
  connect_bd_intf_net -intf_net psx_wizard_0_pcie0_cfg_msg_recd [get_bd_intf_ports pcie0_cfg_msg_recd_0] [get_bd_intf_pins psx_wizard_0/pcie0_cfg_msg_recd]
  connect_bd_intf_net -intf_net psx_wizard_0_pcie0_cfg_msg_tx [get_bd_intf_ports pcie0_cfg_msg_tx_0] [get_bd_intf_pins psx_wizard_0/pcie0_cfg_msg_tx]
  connect_bd_intf_net -intf_net psx_wizard_0_pcie0_cfg_status [get_bd_intf_ports pcie0_cfg_status_0] [get_bd_intf_pins psx_wizard_0/pcie0_cfg_status]
  connect_bd_intf_net -intf_net psx_wizard_0_pcie0_m_axis_cq [get_bd_intf_ports pcie0_m_axis_cq_0] [get_bd_intf_pins psx_wizard_0/pcie0_m_axis_cq]
  connect_bd_intf_net -intf_net psx_wizard_0_pcie0_m_axis_rc [get_bd_intf_ports pcie0_m_axis_rc_0] [get_bd_intf_pins psx_wizard_0/pcie0_m_axis_rc]
  connect_bd_intf_net -intf_net psx_wizard_0_pcie0_transmit_fc [get_bd_intf_ports pcie0_transmit_fc_0] [get_bd_intf_pins psx_wizard_0/pcie0_transmit_fc]

  # Create port connections
  connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_ports pcie0_user_reset_0] [get_bd_pins proc_sys_reset_0/peripheral_reset]
  connect_bd_net -net psx_wizard_0_pl0_ref_clk [get_bd_ports cpm_bot_user_clk_0] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins psx_wizard_0/cpm_bot_user_clk] [get_bd_pins psx_wizard_0/pl0_ref_clk]
  connect_bd_net -net psx_wizard_0_pl0_resetn [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins psx_wizard_0/pl0_resetn]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins proc_sys_reset_0/aux_reset_in] [get_bd_pins xlconstant_0/dout]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


