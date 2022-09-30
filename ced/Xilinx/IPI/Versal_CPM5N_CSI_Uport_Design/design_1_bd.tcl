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
#
# NOTE - set scripts_vivado_version "" to ignore version check.
################################################################
set scripts_vivado_version ""
#set scripts_vivado_version 2022.2
set current_vivado_version [version -short]

if { $scripts_vivado_version ne "" && [string first $scripts_vivado_version $current_vivado_version] == -1 } {
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
   create_project project_1 myproj -part xcvn3716-vsvb2197-2MHP-e-S-es1
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
  set FPD_AXI_PL_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 FPD_AXI_PL_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $FPD_AXI_PL_0

  set PCIE0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT_0 ]

  set PL_AXI_FPD0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 PL_AXI_FPD0_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {50} \
   CONFIG.ARUSER_WIDTH {12} \
   CONFIG.AWUSER_WIDTH {12} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {11} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $PL_AXI_FPD0_0

  set csi0_dst_crdt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 csi0_dst_crdt_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {2} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $csi0_dst_crdt_0

  set csi0_local_crdts_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cpm5n:csi_local_crdt_rtl:1.0 csi0_local_crdts_0 ]

  set csi0_npr_req_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi0_npr_req_0 ]

  set csi0_port_resp0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi0_port_resp0_0 ]

  set csi0_port_resp1_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi0_port_resp1_0 ]

  set csi0_prcmpl_req0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi0_prcmpl_req0_0 ]

  set csi0_prcmpl_req1_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi0_prcmpl_req1_0 ]

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]

  set m_axi_hah_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_hah_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {48} \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $m_axi_hah_0

  set pcie0_pipe_ep_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie_ext_pipe_rtl:1.0 pcie0_pipe_ep_0 ]

  set s_axi_flr_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_flr_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {13} \
   CONFIG.AWUSER_WIDTH {13} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $s_axi_flr_0


  # Create ports
  set cdx_bot_rst_n_0 [ create_bd_port -dir I -type rst cdx_bot_rst_n_0 ]
  set cdx_gic_0 [ create_bd_port -dir O -from 3 -to 0 cdx_gic_0 ]
  set cpm_bot_user_clk_0 [ create_bd_port -dir I -type clk -freq_hz 250000000 cpm_bot_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {m_axi_hah_0:s_axi_flr_0:csi0_dst_crdt_0} \
 ] $cpm_bot_user_clk_0
  set cpm_cor_irq_0 [ create_bd_port -dir O -type intr cpm_cor_irq_0 ]
  set cpm_gpi_0 [ create_bd_port -dir I -from 31 -to 0 cpm_gpi_0 ]
  set cpm_gpo_0 [ create_bd_port -dir O -from 31 -to 0 cpm_gpo_0 ]
  set cpm_misc_irq_0 [ create_bd_port -dir O -type intr cpm_misc_irq_0 ]
  set cpm_uncor_irq_0 [ create_bd_port -dir O -type intr cpm_uncor_irq_0 ]
  set fpd_axi_pl_aclk_0 [ create_bd_port -dir I -type clk -freq_hz 250000000 fpd_axi_pl_aclk_0 ]
  set pl0_ref_clk_0 [ create_bd_port -dir O -type clk pl0_ref_clk_0 ]
  set pl0_resetn_0 [ create_bd_port -dir O -type rst pl0_resetn_0 ]
  set pl_axi_fpd0_aclk_0 [ create_bd_port -dir I -type clk -freq_hz 250000000 pl_axi_fpd0_aclk_0 ]
  set tstamp_pps_in_0 [ create_bd_port -dir I tstamp_pps_in_0 ]
  set tstamp_pps_out_0 [ create_bd_port -dir O tstamp_pps_out_0 ]

  # Create instance: psx_wizard_0, and set properties
  set psx_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psx_wizard psx_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM_CONFIG(CPM_MPIO_BOT_PINMUX_MODE) {CDX} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_BRIDGE_AXI_SLAVE_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MODES) {CDX} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MODE_SELECTION) {Advanced} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_SCALE) {Megabytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_SIZE) {8} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_SIZE) {256} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_INTERRUPT_PIN) {INTA} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PL_LINK_CAP_MAX_LINK_SPEED) {32.0_GT/s} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH) {X16} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PORT_TYPE) {PCI_Express_Endpoint_device} \
    CONFIG.CPM_CONFIG(CPM_PIPE_INTF_EN) {1} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_CRP_PL0_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PSX_PMCX_CONFIG(PSX_NUM_FABRIC_RESETS) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_RESET) {ENABLE 0 IO PSX_MIO_18:21} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_FPD_AXI_PL) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_PL_AXI_FPD0) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_PMCPL_CLK0) {1} \
  ] $psx_wizard_0


  # Create interface connections
  connect_bd_intf_net -intf_net PL_AXI_FPD0_0_1 [get_bd_intf_ports PL_AXI_FPD0_0] [get_bd_intf_pins psx_wizard_0/PL_AXI_FPD0]
  connect_bd_intf_net -intf_net csi0_dst_crdt_0_1 [get_bd_intf_ports csi0_dst_crdt_0] [get_bd_intf_pins psx_wizard_0/csi0_dst_crdt]
  connect_bd_intf_net -intf_net csi0_npr_req_0_1 [get_bd_intf_ports csi0_npr_req_0] [get_bd_intf_pins psx_wizard_0/csi0_npr_req]
  connect_bd_intf_net -intf_net csi0_prcmpl_req0_0_1 [get_bd_intf_ports csi0_prcmpl_req0_0] [get_bd_intf_pins psx_wizard_0/csi0_prcmpl_req0]
  connect_bd_intf_net -intf_net csi0_prcmpl_req1_0_1 [get_bd_intf_ports csi0_prcmpl_req1_0] [get_bd_intf_pins psx_wizard_0/csi0_prcmpl_req1]
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins psx_wizard_0/gt_refclk0]
  connect_bd_intf_net -intf_net pcie0_pipe_ep_0_1 [get_bd_intf_ports pcie0_pipe_ep_0] [get_bd_intf_pins psx_wizard_0/pcie0_pipe_ep]
  connect_bd_intf_net -intf_net psx_wizard_0_FPD_AXI_PL [get_bd_intf_ports FPD_AXI_PL_0] [get_bd_intf_pins psx_wizard_0/FPD_AXI_PL]
  connect_bd_intf_net -intf_net psx_wizard_0_PCIE0_GT [get_bd_intf_ports PCIE0_GT_0] [get_bd_intf_pins psx_wizard_0/PCIE0_GT]
  connect_bd_intf_net -intf_net psx_wizard_0_cdx_m_axi_hah [get_bd_intf_ports m_axi_hah_0] [get_bd_intf_pins psx_wizard_0/cdx_m_axi_hah]
  connect_bd_intf_net -intf_net psx_wizard_0_csi0_local_crdt [get_bd_intf_ports csi0_local_crdts_0] [get_bd_intf_pins psx_wizard_0/csi0_local_crdt]
  connect_bd_intf_net -intf_net psx_wizard_0_csi0_resp0 [get_bd_intf_ports csi0_port_resp0_0] [get_bd_intf_pins psx_wizard_0/csi0_resp0]
  connect_bd_intf_net -intf_net psx_wizard_0_csi0_resp1 [get_bd_intf_ports csi0_port_resp1_0] [get_bd_intf_pins psx_wizard_0/csi0_resp1]
  connect_bd_intf_net -intf_net s_axi_flr_0_1 [get_bd_intf_ports s_axi_flr_0] [get_bd_intf_pins psx_wizard_0/cdx_s_axi_flr]

  # Create port connections
  connect_bd_net -net cdx_bot_rst_n_0_1 [get_bd_ports cdx_bot_rst_n_0] [get_bd_pins psx_wizard_0/cdx_bot_rst_n]
  connect_bd_net -net cpm_bot_user_clk_0_1 [get_bd_ports cpm_bot_user_clk_0] [get_bd_pins psx_wizard_0/cpm_bot_user_clk]
  connect_bd_net -net cpm_gpi_0_1 [get_bd_ports cpm_gpi_0] [get_bd_pins psx_wizard_0/cpm_gpi]
  connect_bd_net -net fpd_axi_pl_aclk_0_1 [get_bd_ports fpd_axi_pl_aclk_0] [get_bd_pins psx_wizard_0/fpd_axi_pl_aclk]
  connect_bd_net -net pl_axi_fpd0_aclk_0_1 [get_bd_ports pl_axi_fpd0_aclk_0] [get_bd_pins psx_wizard_0/pl_axi_fpd0_aclk]
  connect_bd_net -net psx_wizard_0_cdx_gic [get_bd_ports cdx_gic_0] [get_bd_pins psx_wizard_0/cdx_gic]
  connect_bd_net -net psx_wizard_0_cdx_tstamp_pps_out [get_bd_ports tstamp_pps_out_0] [get_bd_pins psx_wizard_0/cdx_tstamp_pps_out]
  connect_bd_net -net psx_wizard_0_cpm_cor_irq [get_bd_ports cpm_cor_irq_0] [get_bd_pins psx_wizard_0/cpm_cor_irq]
  connect_bd_net -net psx_wizard_0_cpm_gpo [get_bd_ports cpm_gpo_0] [get_bd_pins psx_wizard_0/cpm_gpo]
  connect_bd_net -net psx_wizard_0_cpm_misc_irq [get_bd_ports cpm_misc_irq_0] [get_bd_pins psx_wizard_0/cpm_misc_irq]
  connect_bd_net -net psx_wizard_0_cpm_uncor_irq [get_bd_ports cpm_uncor_irq_0] [get_bd_pins psx_wizard_0/cpm_uncor_irq]
  connect_bd_net -net psx_wizard_0_pl0_ref_clk [get_bd_ports pl0_ref_clk_0] [get_bd_pins psx_wizard_0/pl0_ref_clk]
  connect_bd_net -net psx_wizard_0_pl0_resetn [get_bd_ports pl0_resetn_0] [get_bd_pins psx_wizard_0/pl0_resetn]
  connect_bd_net -net tstamp_pps_in_0_1 [get_bd_ports tstamp_pps_in_0] [get_bd_pins psx_wizard_0/cdx_tstamp_pps_in]

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


