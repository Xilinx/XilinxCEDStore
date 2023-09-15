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
set scripts_vivado_version 2023.1
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
xilinx.com:ip:axi_noc2:*\
xilinx.com:ip:psx_wizard:*\
xilinx.com:ip:smartconnect:*\
xilinx.com:ip:xlconstant:*\
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
  set AXI4L_PL_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI4L_PL_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {42} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $AXI4L_PL_0

  set PCIE0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT_0 ]

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

  set pcie0_pipe_ep_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie_ext_pipe_rtl:1.0 pcie0_pipe_ep_0 ]


  # Create ports
  set cdx_bot_rst_n_0 [ create_bd_port -dir I -type rst cdx_bot_rst_n_0 ]
  set cpm_bot_user_clk_0 [ create_bd_port -dir I -type clk -freq_hz 250000000 cpm_bot_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {csi0_dst_crdt_0} \
 ] $cpm_bot_user_clk_0
  set pl0_ref_clk_0 [ create_bd_port -dir O -type clk pl0_ref_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {AXI4L_PL_0} \
 ] $pl0_ref_clk_0
  set pl0_resetn_0 [ create_bd_port -dir O -type rst pl0_resetn_0 ]

  # Create instance: axi_noc2_0, and set properties
  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_0 ]
  set_property -dict [list \
    CONFIG.MI_SIDEBAND_PINS {} \
    CONFIG.NUM_CLKS {6} \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {5} \
    CONFIG.SI_SIDEBAND_PINS {} \
  ] $axi_noc2_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x203_00A0_0000 1M}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc2_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc2_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc2_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc2_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc2_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk5]

  # Create instance: psx_wizard_0, and set properties
  set psx_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psx_wizard psx_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM_CONFIG(CPM_CDM0_MSGLDST_IF) {0} \
    CONFIG.CPM_CONFIG(CPM_CSI0_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_MPIO_BOT_PINMUX_MODE) {CDX} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MODES) {CDX} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MODE_SELECTION) {Advanced} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_SCALE) {Megabytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_SIZE) {128} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR1_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR1_SCALE) {Kilobytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR1_SIZE) {128} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_SCALE) {Kilobytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_SIZE) {32} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR3_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR3_SCALE) {Kilobytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR3_SIZE) {256} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR4_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR4_SCALE) {Kilobytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR4_SIZE) {512} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR5_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR5_SCALE) {Megabytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR5_SIZE) {64} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_INTERRUPT_PIN) {INTA} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PL_LINK_CAP_MAX_LINK_SPEED) {32.0_GT/s} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH) {X16} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PORT_TYPE) {PCI_Express_Endpoint_device} \
    CONFIG.CPM_CONFIG(CPM_PIPE_INTF_EN) {1} \
    CONFIG.CPM_CONFIG(PSX_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.CPM_CONFIG(PSX_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.CPM_CONFIG(PSX_USE_PCIE_AXI_NOC2) {1} \
    CONFIG.CPM_CONFIG(PSX_USE_PCIE_AXI_NOC3) {1} \
    CONFIG.CPM_CONFIG(CPM_PRESET_CDO) cdos/CSI0_User_Port.cdo \
    CONFIG.PSX_PMCX_CONFIG(PMCX_CRP_PL0_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_MIO39) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_MIO40) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_MIO41) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_USE_PMCX_AXI_NOC0) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_FPD_AXI_PL_DATA_WIDTH) {32} \
    CONFIG.PSX_PMCX_CONFIG(PSX_NUM_FABRIC_RESETS) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_EP_RESET1_IO) {PMCX_MIO_38} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_EP_RESET2_IO) {None} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_EP_RESET3_IO) {None} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_EP_RESET4_IO) {None} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_RESET) {ENABLE 1 IO PSX_MIO_18:21} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_ROOT_RESET1_IO_DIR) {input} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_ROOT_RESET2_IO_DIR) {input} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_ROOT_RESET3_IO_DIR) {input} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_ROOT_RESET4_IO_DIR) {input} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PL_AXI_FPD0_DATA_WIDTH) {32} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_FPD_AXI_PL) {0} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_LPD_AXI_PL) {0} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_PL_AXI_FPD0) {0} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_PMCPL_CLK0) {1} \
  ] $psx_wizard_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_0


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_0


  # Create interface connections
  connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins axi_noc2_0/M00_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net csi0_dst_crdt_0_1 [get_bd_intf_ports csi0_dst_crdt_0] [get_bd_intf_pins psx_wizard_0/csi0_dst_crdt]
  connect_bd_intf_net -intf_net csi0_npr_req_0_1 [get_bd_intf_ports csi0_npr_req_0] [get_bd_intf_pins psx_wizard_0/csi0_npr_req]
  connect_bd_intf_net -intf_net csi0_prcmpl_req0_0_1 [get_bd_intf_ports csi0_prcmpl_req0_0] [get_bd_intf_pins psx_wizard_0/csi0_prcmpl_req0]
  connect_bd_intf_net -intf_net csi0_prcmpl_req1_0_1 [get_bd_intf_ports csi0_prcmpl_req1_0] [get_bd_intf_pins psx_wizard_0/csi0_prcmpl_req1]
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins psx_wizard_0/gt_refclk0]
  connect_bd_intf_net -intf_net pcie0_pipe_ep_0_1 [get_bd_intf_ports pcie0_pipe_ep_0] [get_bd_intf_pins psx_wizard_0/pcie0_pipe_ep]
  connect_bd_intf_net -intf_net psx_wizard_0_CPM_PCIE_AXI_NOC0 [get_bd_intf_pins axi_noc2_0/S00_AXI] [get_bd_intf_pins psx_wizard_0/CPM_PCIE_AXI_NOC0]
  connect_bd_intf_net -intf_net psx_wizard_0_CPM_PCIE_AXI_NOC1 [get_bd_intf_pins axi_noc2_0/S01_AXI] [get_bd_intf_pins psx_wizard_0/CPM_PCIE_AXI_NOC1]
  connect_bd_intf_net -intf_net psx_wizard_0_CPM_PCIE_AXI_NOC2 [get_bd_intf_pins axi_noc2_0/S02_AXI] [get_bd_intf_pins psx_wizard_0/CPM_PCIE_AXI_NOC2]
  connect_bd_intf_net -intf_net psx_wizard_0_CPM_PCIE_AXI_NOC3 [get_bd_intf_pins axi_noc2_0/S03_AXI] [get_bd_intf_pins psx_wizard_0/CPM_PCIE_AXI_NOC3]
  connect_bd_intf_net -intf_net psx_wizard_0_PCIE0_GT [get_bd_intf_ports PCIE0_GT_0] [get_bd_intf_pins psx_wizard_0/PCIE0_GT]
  connect_bd_intf_net -intf_net psx_wizard_0_PMCX_AXI_NOC0 [get_bd_intf_pins axi_noc2_0/S04_AXI] [get_bd_intf_pins psx_wizard_0/PMCX_AXI_NOC0]
  connect_bd_intf_net -intf_net psx_wizard_0_csi0_local_crdt [get_bd_intf_ports csi0_local_crdts_0] [get_bd_intf_pins psx_wizard_0/csi0_local_crdt]
  connect_bd_intf_net -intf_net psx_wizard_0_csi0_resp0 [get_bd_intf_ports csi0_port_resp0_0] [get_bd_intf_pins psx_wizard_0/csi0_resp0]
  connect_bd_intf_net -intf_net psx_wizard_0_csi0_resp1 [get_bd_intf_ports csi0_port_resp1_0] [get_bd_intf_pins psx_wizard_0/csi0_resp1]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_ports AXI4L_PL_0] [get_bd_intf_pins smartconnect_0/M00_AXI]

  # Create port connections
  connect_bd_net -net cdx_bot_rst_n_0_1 [get_bd_ports cdx_bot_rst_n_0] [get_bd_pins psx_wizard_0/cdx_bot_rst_n] [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net cpm_bot_user_clk_0_1 [get_bd_ports cpm_bot_user_clk_0] [get_bd_pins psx_wizard_0/cpm_bot_user_clk]
  connect_bd_net -net psx_wizard_0_cpm_pcie_axi_noc0_clk [get_bd_pins axi_noc2_0/aclk0] [get_bd_pins psx_wizard_0/cpm_pcie_axi_noc0_clk]
  connect_bd_net -net psx_wizard_0_cpm_pcie_axi_noc1_clk [get_bd_pins axi_noc2_0/aclk1] [get_bd_pins psx_wizard_0/cpm_pcie_axi_noc1_clk]
  connect_bd_net -net psx_wizard_0_cpm_pcie_axi_noc2_clk [get_bd_pins axi_noc2_0/aclk2] [get_bd_pins psx_wizard_0/cpm_pcie_axi_noc2_clk]
  connect_bd_net -net psx_wizard_0_cpm_pcie_axi_noc3_clk [get_bd_pins axi_noc2_0/aclk3] [get_bd_pins psx_wizard_0/cpm_pcie_axi_noc3_clk]
  connect_bd_net -net psx_wizard_0_pl0_ref_clk [get_bd_ports pl0_ref_clk_0] [get_bd_pins axi_noc2_0/aclk4] [get_bd_pins psx_wizard_0/pl0_ref_clk] [get_bd_pins smartconnect_0/aclk]
  connect_bd_net -net psx_wizard_0_pl0_resetn [get_bd_ports pl0_resetn_0] [get_bd_pins psx_wizard_0/pl0_resetn]
  connect_bd_net -net psx_wizard_0_pmcx_axi_noc0_clk [get_bd_pins axi_noc2_0/aclk5] [get_bd_pins psx_wizard_0/pmcx_axi_noc0_clk]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins psx_wizard_0/cdm0_es1_wa_en] [get_bd_pins psx_wizard_0/csi0_es1_wa_en] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  assign_bd_address -offset 0x020300A00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs AXI4L_PL_0/Reg] -force
  assign_bd_address -offset 0x020300A00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs AXI4L_PL_0/Reg] -force
  assign_bd_address -offset 0x020300A00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs AXI4L_PL_0/Reg] -force
  assign_bd_address -offset 0x020300A00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs AXI4L_PL_0/Reg] -force
  assign_bd_address -offset 0x020300A00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs AXI4L_PL_0/Reg] -force


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



