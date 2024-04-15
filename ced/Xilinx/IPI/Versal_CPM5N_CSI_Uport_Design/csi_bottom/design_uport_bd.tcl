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
# This is a generated script based on design: uport_if
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
# source uport_if_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvn3716-vsvb2197-2MHP-e-S-es1
}


# CHANGE DESIGN NAME HERE
variable design_name_uport
set design_name_uport uport_if

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name_uport

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name_uport} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name_uport> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name_uport NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name_uport exists in project.

   if { $cur_design ne $design_name_uport } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name_uport> from <$design_name_uport> to <$cur_design> since current design is empty."
      set design_name_uport [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name_uport } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name_uport> already exists in your project, please set the variable <design_name_uport> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name_uport}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name_uport exists in project.
   #    7) No opened design, design_name_uport exists in project.

   set errMsg "Design <$design_name_uport> already exists in your project, please set the variable <design_name_uport> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name_uport not in project.
   #    9) Current opened design, has components, but diff names, design_name_uport not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name_uport> in project, so creating one..."

   create_bd_design $design_name_uport

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name_uport> as current_bd_design."
   current_bd_design $design_name_uport

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name_uport> is equal to \"$design_name_uport\"."

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
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:emb_mem_gen:*\
xilinx.com:ip:smartconnect:*\
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
  variable design_name_uport

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
  set M_AXI_CSI_UPORT_axil [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_CSI_UPORT_axil ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {31250000} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $M_AXI_CSI_UPORT_axil

  set S_AXI_UPORT [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_UPORT ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {31250000} \
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
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S_AXI_UPORT


  # Create ports
  set ACLK_UPORT [ create_bd_port -dir I -type clk -freq_hz 31250000 ACLK_UPORT ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S_AXI_UPORT:M_AXI_CSI_UPORT_axil} \
 ] $ACLK_UPORT
  set ARESETN_UPORT [ create_bd_port -dir I ARESETN_UPORT ]
  set addra_cmpl_cmd [ create_bd_port -dir I -from 8 -to 0 addra_cmpl_cmd ]
  set addrb_cmpl_check_seed [ create_bd_port -dir I -from 12 -to 0 addrb_cmpl_check_seed ]
  set addrb_cmpl_cmd [ create_bd_port -dir I -from 8 -to 0 addrb_cmpl_cmd ]
  set addrb_cmpl_data [ create_bd_port -dir I -from 12 -to 0 addrb_cmpl_data ]
  set addrb_npr_cmd [ create_bd_port -dir I -from 12 -to 0 addrb_npr_cmd ]
  set addrb_npr_data [ create_bd_port -dir I -from 12 -to 0 addrb_npr_data ]
  set addrb_pr_check_seed [ create_bd_port -dir I -from 12 -to 0 addrb_pr_check_seed ]
  set addrb_pr_cmd [ create_bd_port -dir I -from 12 -to 0 addrb_pr_cmd ]
  set addrb_pr_data [ create_bd_port -dir I -from 12 -to 0 addrb_pr_data ]
  set dina_cmpl_cmd [ create_bd_port -dir I -from 255 -to 0 dina_cmpl_cmd ]
  set dinb_cmpl_check_seed [ create_bd_port -dir I -from 63 -to 0 dinb_cmpl_check_seed ]
  set dinb_cmpl_data [ create_bd_port -dir I -from 31 -to 0 dinb_cmpl_data ]
  set dinb_npr_cmd [ create_bd_port -dir I -from 127 -to 0 dinb_npr_cmd ]
  set dinb_npr_data [ create_bd_port -dir I -from 127 -to 0 dinb_npr_data ]
  set dinb_pr_check_seed [ create_bd_port -dir I -from 63 -to 0 dinb_pr_check_seed ]
  set dinb_pr_cmd [ create_bd_port -dir I -from 127 -to 0 dinb_pr_cmd ]
  set dinb_pr_data [ create_bd_port -dir I -from 127 -to 0 dinb_pr_data ]
  set doutb_cmpl_check_seed [ create_bd_port -dir O -from 63 -to 0 doutb_cmpl_check_seed ]
  set doutb_cmpl_cmd [ create_bd_port -dir O -from 255 -to 0 doutb_cmpl_cmd ]
  set doutb_cmpl_data [ create_bd_port -dir O -from 31 -to 0 doutb_cmpl_data ]
  set doutb_npr_cmd [ create_bd_port -dir O -from 127 -to 0 doutb_npr_cmd ]
  set doutb_npr_data [ create_bd_port -dir O -from 127 -to 0 doutb_npr_data ]
  set doutb_pr_check_seed [ create_bd_port -dir O -from 63 -to 0 doutb_pr_check_seed ]
  set doutb_pr_cmd [ create_bd_port -dir O -from 127 -to 0 doutb_pr_cmd ]
  set doutb_pr_data [ create_bd_port -dir O -from 127 -to 0 doutb_pr_data ]
  set ena_cmpl_cmd [ create_bd_port -dir I ena_cmpl_cmd ]
  set enb_cmpl_check_seed [ create_bd_port -dir I enb_cmpl_check_seed ]
  set enb_cmpl_cmd [ create_bd_port -dir I enb_cmpl_cmd ]
  set enb_cmpl_data [ create_bd_port -dir I enb_cmpl_data ]
  set enb_npr_cmd [ create_bd_port -dir I enb_npr_cmd ]
  set enb_npr_data [ create_bd_port -dir I enb_npr_data ]
  set enb_pr_check_seed [ create_bd_port -dir I enb_pr_check_seed ]
  set enb_pr_cmd [ create_bd_port -dir I enb_pr_cmd ]
  set enb_pr_data [ create_bd_port -dir I enb_pr_data ]
  set rsta_cmpl_cmd [ create_bd_port -dir I -type rst rsta_cmpl_cmd ]
  set rstb_cmpl_check_seed [ create_bd_port -dir I -type rst rstb_cmpl_check_seed ]
  set rstb_cmpl_cmd [ create_bd_port -dir I -type rst rstb_cmpl_cmd ]
  set rstb_cmpl_data [ create_bd_port -dir I -type rst rstb_cmpl_data ]
  set rstb_npr_cmd [ create_bd_port -dir I -type rst rstb_npr_cmd ]
  set rstb_npr_data [ create_bd_port -dir I -type rst rstb_npr_data ]
  set rstb_pr_check_seed [ create_bd_port -dir I -type rst rstb_pr_check_seed ]
  set rstb_pr_cmd [ create_bd_port -dir I -type rst rstb_pr_cmd ]
  set rstb_pr_data [ create_bd_port -dir I -type rst rstb_pr_data ]
  set wea_cmpl_cmd [ create_bd_port -dir I -from 0 -to 0 wea_cmpl_cmd ]
  set web_cmpl_check_seed [ create_bd_port -dir I -from 7 -to 0 web_cmpl_check_seed ]
  set web_cmpl_data [ create_bd_port -dir I -from 3 -to 0 web_cmpl_data ]
  set web_npr_cmd [ create_bd_port -dir I -from 15 -to 0 web_npr_cmd ]
  set web_npr_data [ create_bd_port -dir I -from 15 -to 0 web_npr_data ]
  set web_pr_check_seed [ create_bd_port -dir I -from 7 -to 0 web_pr_check_seed ]
  set web_pr_cmd [ create_bd_port -dir I -from 15 -to 0 web_pr_cmd ]
  set web_pr_data [ create_bd_port -dir I -from 15 -to 0 web_pr_data ]

  # Create instance: axi_bram_ctrl_cmpl_check_seed, and set properties
  set axi_bram_ctrl_cmpl_check_seed [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_cmpl_check_seed ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {64} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_cmpl_check_seed


  # Create instance: axi_bram_ctrl_cmpl_check_seed_bram, and set properties
  set axi_bram_ctrl_cmpl_check_seed_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_cmpl_check_seed_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_cmpl_check_seed_bram


  # Create instance: axi_bram_ctrl_cmpl_cmd, and set properties
  set axi_bram_ctrl_cmpl_cmd [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_cmpl_cmd ]
  set_property -dict [list \
    CONFIG.ADDR_WIDTH_A {9} \
    CONFIG.ADDR_WIDTH_B {9} \
    CONFIG.ENABLE_32BIT_ADDRESS {false} \
    CONFIG.ENABLE_BYTE_WRITES_A {false} \
    CONFIG.MEMORY_DEPTH {512} \
    CONFIG.MEMORY_TYPE {Simple_Dual_Port_RAM} \
    CONFIG.READ_DATA_WIDTH_A {256} \
    CONFIG.READ_DATA_WIDTH_B {256} \
    CONFIG.READ_LATENCY_B {1} \
    CONFIG.USE_MEMORY_BLOCK {Stand_Alone} \
    CONFIG.WRITE_DATA_WIDTH_A {256} \
    CONFIG.WRITE_DATA_WIDTH_B {256} \
    CONFIG.WRITE_MODE_A {READ_FIRST} \
    CONFIG.WRITE_MODE_B {READ_FIRST} \
  ] $axi_bram_ctrl_cmpl_cmd


  # Create instance: axi_bram_ctrl_cmpl_data, and set properties
  set axi_bram_ctrl_cmpl_data [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_cmpl_data ]
  set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_cmpl_data


  # Create instance: axi_bram_ctrl_cmpl_data_bram, and set properties
  set axi_bram_ctrl_cmpl_data_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_cmpl_data_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_cmpl_data_bram


  # Create instance: axi_bram_ctrl_npr_cmd, and set properties
  set axi_bram_ctrl_npr_cmd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_npr_cmd ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {128} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_npr_cmd


  # Create instance: axi_bram_ctrl_npr_cmd_bram, and set properties
  set axi_bram_ctrl_npr_cmd_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_npr_cmd_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_npr_cmd_bram


  # Create instance: axi_bram_ctrl_npr_data, and set properties
  set axi_bram_ctrl_npr_data [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_npr_data ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {128} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_npr_data


  # Create instance: axi_bram_ctrl_npr_data_bram, and set properties
  set axi_bram_ctrl_npr_data_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_npr_data_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_npr_data_bram


  # Create instance: axi_bram_ctrl_pr_check_seed, and set properties
  set axi_bram_ctrl_pr_check_seed [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_pr_check_seed ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {64} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_pr_check_seed


  # Create instance: axi_bram_ctrl_pr_check_seed_bram, and set properties
  set axi_bram_ctrl_pr_check_seed_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_pr_check_seed_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_pr_check_seed_bram


  # Create instance: axi_bram_ctrl_pr_cmd, and set properties
  set axi_bram_ctrl_pr_cmd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_pr_cmd ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {128} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_pr_cmd


  # Create instance: axi_bram_ctrl_pr_cmd_bram, and set properties
  set axi_bram_ctrl_pr_cmd_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_pr_cmd_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_pr_cmd_bram


  # Create instance: axi_bram_ctrl_pr_data, and set properties
  set axi_bram_ctrl_pr_data [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_pr_data ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {128} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_pr_data


  # Create instance: axi_bram_ctrl_pr_data_bram, and set properties
  set axi_bram_ctrl_pr_data_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_pr_data_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_pr_data_bram


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {8} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_UPORT_1 [get_bd_intf_ports S_AXI_UPORT] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_cmpl_check_seed_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_cmpl_check_seed/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_cmpl_check_seed_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_cmpl_data_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_cmpl_data/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_cmpl_data_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_npr_cmd_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_npr_cmd/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_npr_cmd_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_npr_data_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_npr_data/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_npr_data_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_pr_check_seed_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_pr_check_seed/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_pr_check_seed_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_pr_cmd_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_pr_cmd/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_pr_cmd_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_pr_data_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_pr_data/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_pr_data_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins axi_bram_ctrl_pr_cmd/S_AXI] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins axi_bram_ctrl_npr_cmd/S_AXI] [get_bd_intf_pins smartconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins axi_bram_ctrl_pr_data/S_AXI] [get_bd_intf_pins smartconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins axi_bram_ctrl_npr_data/S_AXI] [get_bd_intf_pins smartconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins axi_bram_ctrl_cmpl_data/S_AXI] [get_bd_intf_pins smartconnect_0/M04_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M05_AXI [get_bd_intf_ports M_AXI_CSI_UPORT_axil] [get_bd_intf_pins smartconnect_0/M05_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M06_AXI [get_bd_intf_pins axi_bram_ctrl_pr_check_seed/S_AXI] [get_bd_intf_pins smartconnect_0/M06_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M07_AXI [get_bd_intf_pins axi_bram_ctrl_cmpl_check_seed/S_AXI] [get_bd_intf_pins smartconnect_0/M07_AXI]

  # Create port connections
  connect_bd_net -net ACLK_UPORT_1 [get_bd_ports ACLK_UPORT] [get_bd_pins axi_bram_ctrl_cmpl_check_seed/s_axi_aclk] [get_bd_pins axi_bram_ctrl_cmpl_check_seed_bram/clkb] [get_bd_pins axi_bram_ctrl_cmpl_cmd/clka] [get_bd_pins axi_bram_ctrl_cmpl_cmd/clkb] [get_bd_pins axi_bram_ctrl_cmpl_data/s_axi_aclk] [get_bd_pins axi_bram_ctrl_cmpl_data_bram/clkb] [get_bd_pins axi_bram_ctrl_npr_cmd/s_axi_aclk] [get_bd_pins axi_bram_ctrl_npr_cmd_bram/clkb] [get_bd_pins axi_bram_ctrl_npr_data/s_axi_aclk] [get_bd_pins axi_bram_ctrl_npr_data_bram/clkb] [get_bd_pins axi_bram_ctrl_pr_check_seed/s_axi_aclk] [get_bd_pins axi_bram_ctrl_pr_check_seed_bram/clkb] [get_bd_pins axi_bram_ctrl_pr_cmd/s_axi_aclk] [get_bd_pins axi_bram_ctrl_pr_cmd_bram/clkb] [get_bd_pins axi_bram_ctrl_pr_data/s_axi_aclk] [get_bd_pins axi_bram_ctrl_pr_data_bram/clkb] [get_bd_pins smartconnect_0/aclk]
  connect_bd_net -net ARESETN_UPORT_1 [get_bd_ports ARESETN_UPORT] [get_bd_pins axi_bram_ctrl_cmpl_check_seed/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_cmpl_data/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_npr_cmd/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_npr_data/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_pr_check_seed/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_pr_cmd/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_pr_data/s_axi_aresetn] [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net addra_0_1 [get_bd_ports addra_cmpl_cmd] [get_bd_pins axi_bram_ctrl_cmpl_cmd/addra]
  connect_bd_net -net addrb_0_1 [get_bd_ports addrb_cmpl_cmd] [get_bd_pins axi_bram_ctrl_cmpl_cmd/addrb]
  connect_bd_net -net addrb_0_2 [get_bd_ports addrb_cmpl_check_seed] [get_bd_pins axi_bram_ctrl_cmpl_check_seed_bram/addrb]
  connect_bd_net -net addrb_1_1 [get_bd_ports addrb_pr_check_seed] [get_bd_pins axi_bram_ctrl_pr_check_seed_bram/addrb]
  connect_bd_net -net addrb_cmpl_data_1 [get_bd_ports addrb_cmpl_data] [get_bd_pins axi_bram_ctrl_cmpl_data_bram/addrb]
  connect_bd_net -net addrb_npr_cmd_1 [get_bd_ports addrb_npr_cmd] [get_bd_pins axi_bram_ctrl_npr_cmd_bram/addrb]
  connect_bd_net -net addrb_npr_data_1 [get_bd_ports addrb_npr_data] [get_bd_pins axi_bram_ctrl_npr_data_bram/addrb]
  connect_bd_net -net addrb_pr_cmd_1 [get_bd_ports addrb_pr_cmd] [get_bd_pins axi_bram_ctrl_pr_cmd_bram/addrb]
  connect_bd_net -net addrb_pr_data_1 [get_bd_ports addrb_pr_data] [get_bd_pins axi_bram_ctrl_pr_data_bram/addrb]
  connect_bd_net -net axi_bram_ctrl_cmpl_check_seed_bram_doutb [get_bd_ports doutb_cmpl_check_seed] [get_bd_pins axi_bram_ctrl_cmpl_check_seed_bram/doutb]
  connect_bd_net -net axi_bram_ctrl_cmpl_data_bram1_doutb [get_bd_ports doutb_cmpl_cmd] [get_bd_pins axi_bram_ctrl_cmpl_cmd/doutb]
  connect_bd_net -net axi_bram_ctrl_cmpl_data_bram_doutb [get_bd_ports doutb_cmpl_data] [get_bd_pins axi_bram_ctrl_cmpl_data_bram/doutb]
  connect_bd_net -net axi_bram_ctrl_npr_cmd_bram_doutb [get_bd_ports doutb_npr_cmd] [get_bd_pins axi_bram_ctrl_npr_cmd_bram/doutb]
  connect_bd_net -net axi_bram_ctrl_npr_data_bram_doutb [get_bd_ports doutb_npr_data] [get_bd_pins axi_bram_ctrl_npr_data_bram/doutb]
  connect_bd_net -net axi_bram_ctrl_pr_check_seed_bram_doutb [get_bd_ports doutb_pr_check_seed] [get_bd_pins axi_bram_ctrl_pr_check_seed_bram/doutb]
  connect_bd_net -net axi_bram_ctrl_pr_cmd_bram_doutb [get_bd_ports doutb_pr_cmd] [get_bd_pins axi_bram_ctrl_pr_cmd_bram/doutb]
  connect_bd_net -net axi_bram_ctrl_pr_data_bram_doutb [get_bd_ports doutb_pr_data] [get_bd_pins axi_bram_ctrl_pr_data_bram/doutb]
  connect_bd_net -net dina_0_1 [get_bd_ports dina_cmpl_cmd] [get_bd_pins axi_bram_ctrl_cmpl_cmd/dina]
  connect_bd_net -net dinb_0_1 [get_bd_ports dinb_cmpl_check_seed] [get_bd_pins axi_bram_ctrl_cmpl_check_seed_bram/dinb]
  connect_bd_net -net dinb_cmpl_data_1 [get_bd_ports dinb_cmpl_data] [get_bd_pins axi_bram_ctrl_cmpl_data_bram/dinb]
  connect_bd_net -net dinb_npr_cmd_1 [get_bd_ports dinb_npr_cmd] [get_bd_pins axi_bram_ctrl_npr_cmd_bram/dinb]
  connect_bd_net -net dinb_npr_data_1 [get_bd_ports dinb_npr_data] [get_bd_pins axi_bram_ctrl_npr_data_bram/dinb]
  connect_bd_net -net dinb_pr_check_seed_1 [get_bd_ports dinb_pr_check_seed] [get_bd_pins axi_bram_ctrl_pr_check_seed_bram/dinb]
  connect_bd_net -net dinb_pr_cmd_1 [get_bd_ports dinb_pr_cmd] [get_bd_pins axi_bram_ctrl_pr_cmd_bram/dinb]
  connect_bd_net -net dinb_pr_data_1 [get_bd_ports dinb_pr_data] [get_bd_pins axi_bram_ctrl_pr_data_bram/dinb]
  connect_bd_net -net ena_0_1 [get_bd_ports ena_cmpl_cmd] [get_bd_pins axi_bram_ctrl_cmpl_cmd/ena]
  connect_bd_net -net enb_0_1 [get_bd_ports enb_cmpl_cmd] [get_bd_pins axi_bram_ctrl_cmpl_cmd/enb]
  connect_bd_net -net enb_0_2 [get_bd_ports enb_cmpl_check_seed] [get_bd_pins axi_bram_ctrl_cmpl_check_seed_bram/enb]
  connect_bd_net -net enb_1_1 [get_bd_ports enb_pr_check_seed] [get_bd_pins axi_bram_ctrl_pr_check_seed_bram/enb]
  connect_bd_net -net enb_cmpl_data_1 [get_bd_ports enb_cmpl_data] [get_bd_pins axi_bram_ctrl_cmpl_data_bram/enb]
  connect_bd_net -net enb_npr_cmd_1 [get_bd_ports enb_npr_cmd] [get_bd_pins axi_bram_ctrl_npr_cmd_bram/enb]
  connect_bd_net -net enb_npr_data_1 [get_bd_ports enb_npr_data] [get_bd_pins axi_bram_ctrl_npr_data_bram/enb]
  connect_bd_net -net enb_pr_cmd_1 [get_bd_ports enb_pr_cmd] [get_bd_pins axi_bram_ctrl_pr_cmd_bram/enb]
  connect_bd_net -net enb_pr_data_1 [get_bd_ports enb_pr_data] [get_bd_pins axi_bram_ctrl_pr_data_bram/enb]
  connect_bd_net -net rsta_0_1 [get_bd_ports rsta_cmpl_cmd] [get_bd_pins axi_bram_ctrl_cmpl_cmd/rsta]
  connect_bd_net -net rstb_0_1 [get_bd_ports rstb_cmpl_cmd] [get_bd_pins axi_bram_ctrl_cmpl_cmd/rstb]
  connect_bd_net -net rstb_0_2 [get_bd_ports rstb_cmpl_check_seed] [get_bd_pins axi_bram_ctrl_cmpl_check_seed_bram/rstb]
  connect_bd_net -net rstb_1_1 [get_bd_ports rstb_pr_check_seed] [get_bd_pins axi_bram_ctrl_pr_check_seed_bram/rstb]
  connect_bd_net -net rstb_cmpl_data_1 [get_bd_ports rstb_cmpl_data] [get_bd_pins axi_bram_ctrl_cmpl_data_bram/rstb]
  connect_bd_net -net rstb_npr_cmd_1 [get_bd_ports rstb_npr_cmd] [get_bd_pins axi_bram_ctrl_npr_cmd_bram/rstb]
  connect_bd_net -net rstb_npr_data_1 [get_bd_ports rstb_npr_data] [get_bd_pins axi_bram_ctrl_npr_data_bram/rstb]
  connect_bd_net -net rstb_pr_cmd_1 [get_bd_ports rstb_pr_cmd] [get_bd_pins axi_bram_ctrl_pr_cmd_bram/rstb]
  connect_bd_net -net rstb_pr_data_1 [get_bd_ports rstb_pr_data] [get_bd_pins axi_bram_ctrl_pr_data_bram/rstb]
  connect_bd_net -net wea_0_1 [get_bd_ports wea_cmpl_cmd] [get_bd_pins axi_bram_ctrl_cmpl_cmd/wea]
  connect_bd_net -net web_0_1 [get_bd_ports web_pr_check_seed] [get_bd_pins axi_bram_ctrl_pr_check_seed_bram/web]
  connect_bd_net -net web_1_1 [get_bd_ports web_cmpl_check_seed] [get_bd_pins axi_bram_ctrl_cmpl_check_seed_bram/web]
  connect_bd_net -net web_cmpl_data_1 [get_bd_ports web_cmpl_data] [get_bd_pins axi_bram_ctrl_cmpl_data_bram/web]
  connect_bd_net -net web_npr_cmd_1 [get_bd_ports web_npr_cmd] [get_bd_pins axi_bram_ctrl_npr_cmd_bram/web]
  connect_bd_net -net web_npr_data_1 [get_bd_ports web_npr_data] [get_bd_pins axi_bram_ctrl_npr_data_bram/web]
  connect_bd_net -net web_pr_cmd_1 [get_bd_ports web_pr_cmd] [get_bd_pins axi_bram_ctrl_pr_cmd_bram/web]
  connect_bd_net -net web_pr_data_1 [get_bd_ports web_pr_data] [get_bd_pins axi_bram_ctrl_pr_data_bram/web]

  # Create address segments
  assign_bd_address -offset 0x00A00000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXI_UPORT] [get_bd_addr_segs M_AXI_CSI_UPORT_axil/Reg] -force
  assign_bd_address -offset 0x00A90000 -range 0x00002000 -target_address_space [get_bd_addr_spaces S_AXI_UPORT] [get_bd_addr_segs axi_bram_ctrl_cmpl_check_seed/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00A40000 -range 0x00002000 -target_address_space [get_bd_addr_spaces S_AXI_UPORT] [get_bd_addr_segs axi_bram_ctrl_cmpl_data/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00A10000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXI_UPORT] [get_bd_addr_segs axi_bram_ctrl_npr_cmd/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00A80000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXI_UPORT] [get_bd_addr_segs axi_bram_ctrl_npr_data/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00AA0000 -range 0x00002000 -target_address_space [get_bd_addr_spaces S_AXI_UPORT] [get_bd_addr_segs axi_bram_ctrl_pr_check_seed/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00A20000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXI_UPORT] [get_bd_addr_segs axi_bram_ctrl_pr_cmd/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00AC0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXI_UPORT] [get_bd_addr_segs axi_bram_ctrl_pr_data/S_AXI/Mem0] -force


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


