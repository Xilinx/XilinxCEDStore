
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
#set scripts_vivado_version 2026.1
set current_vivado_version [version -short]

if { $scripts_vivado_version ne "" && [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "CRITICAL WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been changes to the IP between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the functionality and configuration of the design."

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
   create_project project_1 myproj -part xc2vp3602-vsvc3340-2MHP-e-S
}


# CHANGE DESIGN NAME HERE
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

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
xilinx.com:ip:cpm6_qdma:*\
xilinx.com:ip:axi_noc2:*\
xilinx.com:ip:proc_sys_reset:*\
xilinx.com:ip:smartconnect:*\
xilinx.com:ip:ps_wizard:*\
xilinx.com:ip:axis_ila:*\
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
proc create_root_design { parentCell link_width } {

  variable script_folder
  variable design_name

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
  set ctrl1_gt_refclk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ctrl1_gt_refclk_0 ]

  set CTRL1_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 CTRL1_GT_0 ]

  set H2C_ST_PORT0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_eqdma:h2c_st_port_rtl:1.0 H2C_ST_PORT0_0 ]

  set H2C_ST_PORT1_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_eqdma:h2c_st_port_rtl:1.0 H2C_ST_PORT1_0 ]

  set H2C_ST_PORT2_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_eqdma:h2c_st_port_rtl:1.0 H2C_ST_PORT2_0 ]

  set H2C_ST_PORT3_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_eqdma:h2c_st_port_rtl:1.0 H2C_ST_PORT3_0 ]

  set C2H_ST_PORT0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:c2h_st_port_rtl:1.0 C2H_ST_PORT0_0 ]

  set C2H_ST_PORT1_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:c2h_st_port_rtl:1.0 C2H_ST_PORT1_0 ]

  set C2H_ST_PORT2_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:c2h_st_port_rtl:1.0 C2H_ST_PORT2_0 ]

  set C2H_ST_PORT3_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:c2h_st_port_rtl:1.0 C2H_ST_PORT3_0 ]

  set tm_dsc_sts_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_eqdma:tm_dsc_sts_rtl:1.0 tm_dsc_sts_0 ]

  set dsc_crdt_in_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm6_qdma:dsc_crdt_in_rtl:1.0 dsc_crdt_in_0 ]

  set C2H_CMPT_PORT0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:c2h_cmpt_port_rtl:1.0 C2H_CMPT_PORT0_0 ]

  set C2H_CMPT_PORT1_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:c2h_cmpt_port_rtl:1.0 C2H_CMPT_PORT1_0 ]

  set C2H_CMPT_PORT2_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:c2h_cmpt_port_rtl:1.0 C2H_CMPT_PORT2_0 ]

  set C2H_CMPT_PORT3_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:c2h_cmpt_port_rtl:1.0 C2H_CMPT_PORT3_0 ]

  set M_AXIL_C2H_CFG [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXIL_C2H_CFG ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {49} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $M_AXIL_C2H_CFG


  # Create ports
  set M_AXIL_C2H_CFG_aclk [ create_bd_port -dir O -type clk M_AXIL_C2H_CFG_aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M_AXIL_C2H_CFG} \
 ] $M_AXIL_C2H_CFG_aclk

  set axi_clk [ create_bd_port -dir O -type clk axi_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {axi_rst_n} \
 ] $axi_clk

  set axi_rst_n [ create_bd_port -dir O -type rst axi_rst_n ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $axi_rst_n

  # Create instance: cpm6_qdma_0, and set properties
  set cpm6_qdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:cpm6_qdma cpm6_qdma_0 ]
  set_property -dict [list \
    CONFIG.cpm6_ctrl {1} \
    CONFIG.dsc_ram_base_addr {0x201_0000_0000} \
    CONFIG.enable_dbg {true} \
    CONFIG.mode_selection {0} \
    CONFIG.msix_en {true} \
    CONFIG.num_pfs {1} \
    CONFIG.num_queues {256} \
    CONFIG.num_vfs {8} \
    CONFIG.num_vfs_pf0 {8} \
    CONFIG.traf_man_intf {true} \
  ] $cpm6_qdma_0


  # Create instance: axi_noc2_0, and set properties
  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {4} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {2} \
  ] $axi_noc2_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins $axi_noc2_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc2_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} }} \
   CONFIG.DEST_IDS {M01_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins $axi_noc2_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {M00_AXI:0x40} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins $axi_noc2_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M01_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk3]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]
  set_property CONFIG.C_NUM_PERP_ARESETN {1} $proc_sys_reset_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {3} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: ps_wizard_0, and set properties
  # Controller 1 lane placement. X2 uses CPIPE lane location 6 (lanes
  # reversed) with QUAD3_REFCLK0; for other widths the VPK360 board-aware
  # CPM6 configuration (CPM6_BOARD) selects the lanes and reference clock.
  set x2_lane_loc {}
  set x2_refclk   {}
  if {$link_width eq "X2"} {
    set x2_lane_loc [list \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_CPIPE_LANE_LOC) {6} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_CPIPE_LANE_REVERSAL_EN) {1} ]
    set x2_refclk [list \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_REFCLK) {QUAD3_REFCLK0} ]
  }
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL1_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL2_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL3_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_BOARD) {VPK360} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_CFG_STATUS_IF) {1} \
    {*}$x2_lane_loc \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE0_BASEADDR) {0x0000_0000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE0_DEST) {CPM_AXI_PL0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE0_LIMITADDR) {0x0000_0003_FFFF_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE1_BASEADDR) {0x0000_0004_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE1_DEST) {CPM_AXI_PL1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE1_LIMITADDR) {0x0000_0007_FFFF_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE2_BASEADDR) {0x0000_0008_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE2_DEST) {CPM_AXI_PL2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE2_LIMITADDR) {0x0000_000B_FFFF_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE3_BASEADDR) {0x0000_0201_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE3_DEST) {PCIE_AXI_NOC0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE3_LIMITADDR) {0x0000_0201_007F_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE4_BASEADDR) {0x0000_F210_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE4_DEST) {PCIE_AXI_NOC1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE4_LIMITADDR) {0x0000_F210_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_IDE_CAP_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_BAR_NUM) {BAR_1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_FUNC) {PF_0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_TRGTADDR) {0x0000_0000_0400_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_BAR_NUM) {BAR_1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_FUNC) {VFG_0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_TRGTADDR) {0x0000_0000_0400_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION2_BAR_NUM) {BAR_3} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION2_TRGTADDR) {0x000_F122_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION3_BAR_NUM) {BAR_4} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION3_TRGTADDR) {0x000_F210_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION4_BAR_NUM) {BAR_2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION4_FUNC) {PF*} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION4_TRGTADDR) {0x000_0600_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION5_BAR_NUM) {BAR_2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION5_FUNC) {VF*} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION5_TRGTADDR) {0x000_0600_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_LANE_RATE) {64.0_GT/s} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_LINK_IDE_STREAM_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_LINK_WIDTH) $link_width \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE0_BASEADDR) {0x0000_0000_0400_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE0_DEST) {CPM_AXI_PL3} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE0_LIMITADDR) {0x0000_0000_05FF_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE1_BASEADDR) {0x0000_F122_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE1_DEST) {PCIE_AXI_NOC1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE1_LIMITADDR) {0x0000_F122_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE2_BASEADDR) {0x0000_F210_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE2_DEST) {PCIE_AXI_NOC1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE2_LIMITADDR) {0x0000_F210_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE3_BASEADDR) {0x0000_0600_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE3_DEST) {CPM_AXI_PL3} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE3_LIMITADDR) {0x0000_0600_0FFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MODE) {DMA_BRIDGE} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_DMA_APERTURES) {5} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_INBOUND_REGIONS) {6} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_MMIO_APERTURES) {4} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PERST) {PS_MIO_19} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR0_SCALE) {Kilobytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR0_SIZE) {128} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR1_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR1_SCALE) {Kilobytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR1_SIZE) {256} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR2_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR2_SCALE) {Kilobytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR3_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR4_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR5_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_BIR) {BAR_0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_PBA_OFFSET) {0x15000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_TABLE_OFFSET) {0x14000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_VECTORS) {8} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PROTOCOL) {PCIE_6_1} \
    {*}$x2_refclk \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_SELECTIVE_IDE_STREAM_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_SRIOV_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR0_SCALE) {Kilobytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR0_SIZE) {128} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR1_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR1_SCALE) {Kilobytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR1_SIZE) {32} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR2_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR2_SCALE) {Kilobytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR3_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR4_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR5_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_MSIX_BIR) {BAR_0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_MSIX_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_MSIX_PBA_OFFSET) {0x15000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_MSIX_TABLE_OFFSET) {0x14000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_MSIX_VECTORS) {8} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_TOTAL_VFS) {8} \
    CONFIG.CPM6_CONFIG(CPM6_PL_AXIL_DBI1_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_PRESET_CDO) {qdma_overlay.cdo} \
    CONFIG.CPM6_CONFIG(PS_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.CPM6_CONFIG(PS_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL1_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL2_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL3_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_LINK_WIDTH) $link_width \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_MODE) {DMA_BRIDGE} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_PERST) {PS_MIO_19} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_PROTOCOL) {PCIE_6_1} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_NOC_AXI_PMC0) {1} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {0} \
    CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_RESET) {ENABLE 1 IO PS_MIO_18:19} \
    CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
  ] $ps_wizard_0


  # Create instance: axis_ila_1, and set properties
  set axis_ila_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila axis_ila_1 ]
  set_property -dict [list \
    CONFIG.ALL_PROBE_SAME_MU {true} \
    CONFIG.C_INPUT_PIPE_STAGES {3} \
    CONFIG.C_MON_TYPE {Interface_Monitor} \
    CONFIG.C_NUM_MONITOR_SLOTS {6} \
    CONFIG.C_SLOT_0_APC_EN {0} \
    CONFIG.C_SLOT_0_AXI_AR_SEL_DATA {1} \
    CONFIG.C_SLOT_0_AXI_AR_SEL_TRIG {1} \
    CONFIG.C_SLOT_0_AXI_AW_SEL_DATA {1} \
    CONFIG.C_SLOT_0_AXI_AW_SEL_TRIG {1} \
    CONFIG.C_SLOT_0_AXI_B_SEL_DATA {1} \
    CONFIG.C_SLOT_0_AXI_B_SEL_TRIG {1} \
    CONFIG.C_SLOT_0_AXI_R_SEL_DATA {1} \
    CONFIG.C_SLOT_0_AXI_R_SEL_TRIG {1} \
    CONFIG.C_SLOT_0_AXI_W_SEL_DATA {1} \
    CONFIG.C_SLOT_0_AXI_W_SEL_TRIG {1} \
    CONFIG.C_SLOT_1_APC_EN {0} \
    CONFIG.C_SLOT_1_AXI_AR_SEL_DATA {1} \
    CONFIG.C_SLOT_1_AXI_AR_SEL_TRIG {1} \
    CONFIG.C_SLOT_1_AXI_AW_SEL_DATA {1} \
    CONFIG.C_SLOT_1_AXI_AW_SEL_TRIG {1} \
    CONFIG.C_SLOT_1_AXI_B_SEL_DATA {1} \
    CONFIG.C_SLOT_1_AXI_B_SEL_TRIG {1} \
    CONFIG.C_SLOT_1_AXI_R_SEL_DATA {1} \
    CONFIG.C_SLOT_1_AXI_R_SEL_TRIG {1} \
    CONFIG.C_SLOT_1_AXI_W_SEL_DATA {1} \
    CONFIG.C_SLOT_1_AXI_W_SEL_TRIG {1} \
    CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:display_eqdma:c2h_st_port_rtl:1.0} \
    CONFIG.C_SLOT_2_TYPE {0} \
    CONFIG.C_SLOT_3_INTF_TYPE {xilinx.com:display_eqdma:c2h_st_port_rtl:1.0} \
    CONFIG.C_SLOT_3_TYPE {0} \
    CONFIG.C_SLOT_4_INTF_TYPE {xilinx.com:display_eqdma:c2h_st_port_rtl:1.0} \
    CONFIG.C_SLOT_4_TYPE {0} \
    CONFIG.C_SLOT_5_INTF_TYPE {xilinx.com:display_eqdma:c2h_st_port_rtl:1.0} \
    CONFIG.C_SLOT_5_TYPE {0} \
    CONFIG.C_SLOT_6_INTF_TYPE {xilinx.com:display_eqdma:h2c_st_port_rtl:1.0} \
    CONFIG.C_SLOT_6_TYPE {0} \
    CONFIG.C_SLOT_7_INTF_TYPE {xilinx.com:display_eqdma:h2c_st_port_rtl:1.0} \
    CONFIG.C_SLOT_7_TYPE {0} \
    CONFIG.C_SLOT_8_INTF_TYPE {xilinx.com:display_eqdma:h2c_st_port_rtl:1.0} \
    CONFIG.C_SLOT_8_TYPE {0} \
  ] $axis_ila_1


  # Create instance: axis_ila_0, and set properties
  set axis_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila axis_ila_0 ]
  set_property -dict [list \
    CONFIG.C_INPUT_PIPE_STAGES {3} \
    CONFIG.C_MON_TYPE {Interface_Monitor} \
    CONFIG.C_NUM_MONITOR_SLOTS {7} \
    CONFIG.C_SLOT {3} \
    CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:display_eqdma:h2c_st_port_rtl:1.0} \
    CONFIG.C_SLOT_0_TYPE {0} \
    CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:display_eqdma:h2c_st_port_rtl:1.0} \
    CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:display_eqdma:h2c_st_port_rtl:1.0} \
    CONFIG.C_SLOT_3_INTF_TYPE {xilinx.com:display_eqdma:h2c_st_port_rtl:1.0} \
    CONFIG.C_SLOT_4_INTF_TYPE {xilinx.com:display_cpm6:pcie_msix_rtl:1.0} \
    CONFIG.C_SLOT_4_TYPE {0} \
    CONFIG.C_SLOT_5_INTF_TYPE {xilinx.com:display_eqdma:tm_dsc_sts_rtl:1.0} \
    CONFIG.C_SLOT_5_TYPE {0} \
    CONFIG.C_SLOT_6_APC_EN {0} \
    CONFIG.C_SLOT_6_AXI_AR_SEL_DATA {1} \
    CONFIG.C_SLOT_6_AXI_AR_SEL_TRIG {1} \
    CONFIG.C_SLOT_6_AXI_AW_SEL_DATA {1} \
    CONFIG.C_SLOT_6_AXI_AW_SEL_TRIG {1} \
    CONFIG.C_SLOT_6_AXI_B_SEL_DATA {1} \
    CONFIG.C_SLOT_6_AXI_B_SEL_TRIG {1} \
    CONFIG.C_SLOT_6_AXI_R_SEL_DATA {1} \
    CONFIG.C_SLOT_6_AXI_R_SEL_TRIG {1} \
    CONFIG.C_SLOT_6_AXI_W_SEL_DATA {1} \
    CONFIG.C_SLOT_6_AXI_W_SEL_TRIG {1} \
  ] $axis_ila_0



  # Create interface connections
  connect_bd_intf_net -intf_net C2H_CMPT_PORT0_0_1 [get_bd_intf_pins cpm6_qdma_0/c2h_cmpt_port0] [get_bd_intf_ports C2H_CMPT_PORT0_0]
  connect_bd_intf_net -intf_net C2H_CMPT_PORT1_0_1 [get_bd_intf_pins cpm6_qdma_0/c2h_cmpt_port1] [get_bd_intf_ports C2H_CMPT_PORT1_0]
  connect_bd_intf_net -intf_net C2H_CMPT_PORT2_0_1 [get_bd_intf_pins cpm6_qdma_0/c2h_cmpt_port2] [get_bd_intf_ports C2H_CMPT_PORT2_0]
  connect_bd_intf_net -intf_net C2H_CMPT_PORT3_0_1 [get_bd_intf_pins cpm6_qdma_0/c2h_cmpt_port3] [get_bd_intf_ports C2H_CMPT_PORT3_0]
  connect_bd_intf_net -intf_net C2H_ST_PORT0_0_1 [get_bd_intf_ports C2H_ST_PORT0_0] [get_bd_intf_pins cpm6_qdma_0/c2h_st_port0]
connect_bd_intf_net -intf_net [get_bd_intf_nets C2H_ST_PORT0_0_1] [get_bd_intf_ports C2H_ST_PORT0_0] [get_bd_intf_pins axis_ila_1/SLOT_2_C2H_ST_PORT]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets C2H_ST_PORT0_0_1]
  connect_bd_intf_net -intf_net C2H_ST_PORT1_0_1 [get_bd_intf_ports C2H_ST_PORT1_0] [get_bd_intf_pins cpm6_qdma_0/c2h_st_port1]
connect_bd_intf_net -intf_net [get_bd_intf_nets C2H_ST_PORT1_0_1] [get_bd_intf_ports C2H_ST_PORT1_0] [get_bd_intf_pins axis_ila_1/SLOT_3_C2H_ST_PORT]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets C2H_ST_PORT1_0_1]
  connect_bd_intf_net -intf_net C2H_ST_PORT2_0_1 [get_bd_intf_ports C2H_ST_PORT2_0] [get_bd_intf_pins cpm6_qdma_0/c2h_st_port2]
connect_bd_intf_net -intf_net [get_bd_intf_nets C2H_ST_PORT2_0_1] [get_bd_intf_ports C2H_ST_PORT2_0] [get_bd_intf_pins axis_ila_1/SLOT_4_C2H_ST_PORT]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets C2H_ST_PORT2_0_1]
  connect_bd_intf_net -intf_net C2H_ST_PORT3_0_1 [get_bd_intf_ports C2H_ST_PORT3_0] [get_bd_intf_pins cpm6_qdma_0/c2h_st_port3]
connect_bd_intf_net -intf_net [get_bd_intf_nets C2H_ST_PORT3_0_1] [get_bd_intf_ports C2H_ST_PORT3_0] [get_bd_intf_pins axis_ila_1/SLOT_5_C2H_ST_PORT]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets C2H_ST_PORT3_0_1]
  connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins axi_noc2_0/M00_AXI] [get_bd_intf_pins ps_wizard_0/NOC_AXI_PMC0]
  connect_bd_intf_net -intf_net cpm6_qdma_0_H2C_ST_PORT0 [get_bd_intf_ports H2C_ST_PORT0_0] [get_bd_intf_pins cpm6_qdma_0/h2c_st_port0]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpm6_qdma_0_H2C_ST_PORT0] [get_bd_intf_ports H2C_ST_PORT0_0] [get_bd_intf_pins axis_ila_0/SLOT_0_H2C_ST_PORT]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpm6_qdma_0_H2C_ST_PORT0]
  connect_bd_intf_net -intf_net cpm6_qdma_0_H2C_ST_PORT1 [get_bd_intf_ports H2C_ST_PORT1_0] [get_bd_intf_pins cpm6_qdma_0/h2c_st_port1]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpm6_qdma_0_H2C_ST_PORT1] [get_bd_intf_ports H2C_ST_PORT1_0] [get_bd_intf_pins axis_ila_0/SLOT_1_H2C_ST_PORT]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpm6_qdma_0_H2C_ST_PORT1]
  connect_bd_intf_net -intf_net cpm6_qdma_0_H2C_ST_PORT2 [get_bd_intf_ports H2C_ST_PORT2_0] [get_bd_intf_pins cpm6_qdma_0/h2c_st_port2]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpm6_qdma_0_H2C_ST_PORT2] [get_bd_intf_ports H2C_ST_PORT2_0] [get_bd_intf_pins axis_ila_0/SLOT_2_H2C_ST_PORT]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpm6_qdma_0_H2C_ST_PORT2]
  connect_bd_intf_net -intf_net cpm6_qdma_0_H2C_ST_PORT3 [get_bd_intf_ports H2C_ST_PORT3_0] [get_bd_intf_pins cpm6_qdma_0/h2c_st_port3]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpm6_qdma_0_H2C_ST_PORT3] [get_bd_intf_ports H2C_ST_PORT3_0] [get_bd_intf_pins axis_ila_0/SLOT_3_H2C_ST_PORT]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpm6_qdma_0_H2C_ST_PORT3]
  connect_bd_intf_net -intf_net cpm6_qdma_0_PCIE_MSIX [get_bd_intf_pins ps_wizard_0/pcie1_msix] [get_bd_intf_pins cpm6_qdma_0/PCIE_MSIX]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpm6_qdma_0_PCIE_MSIX] [get_bd_intf_pins ps_wizard_0/pcie1_msix] [get_bd_intf_pins axis_ila_0/SLOT_4_PCIE_MSIX]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpm6_qdma_0_PCIE_MSIX]
  connect_bd_intf_net -intf_net cpm6_qdma_0_tm_dsc_sts [get_bd_intf_ports tm_dsc_sts_0] [get_bd_intf_pins cpm6_qdma_0/tm_dsc_sts]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpm6_qdma_0_tm_dsc_sts] [get_bd_intf_ports tm_dsc_sts_0] [get_bd_intf_pins axis_ila_0/SLOT_5_TM_DSC_STS]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpm6_qdma_0_tm_dsc_sts]
  connect_bd_intf_net -intf_net ctrl0_gt_refclk_0_1 [get_bd_intf_ports ctrl1_gt_refclk_0] [get_bd_intf_pins ps_wizard_0/ctrl1_gt_refclk]
  connect_bd_intf_net -intf_net dsc_crdt_in_0_1 [get_bd_intf_ports dsc_crdt_in_0] [get_bd_intf_pins cpm6_qdma_0/dsc_crdt_in]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S00_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC1] [get_bd_intf_pins axi_noc2_0/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_CTRL0_GT [get_bd_intf_ports CTRL1_GT_0] [get_bd_intf_pins ps_wizard_0/CTRL1_GT]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl0 [get_bd_intf_pins ps_wizard_0/cpm_axi_pl0] [get_bd_intf_pins cpm6_qdma_0/CPM_AXI_PL0]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl1 [get_bd_intf_pins ps_wizard_0/cpm_axi_pl1] [get_bd_intf_pins cpm6_qdma_0/CPM_AXI_PL1]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl2 [get_bd_intf_pins ps_wizard_0/cpm_axi_pl2] [get_bd_intf_pins cpm6_qdma_0/CPM_AXI_PL2]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl3 [get_bd_intf_pins ps_wizard_0/cpm_axi_pl3] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net qdma_M_AXIL_DBI [get_bd_intf_pins cpm6_qdma_0/M_AXIL_DBI] [get_bd_intf_pins ps_wizard_0/pl_axil_dbi1]
connect_bd_intf_net -intf_net [get_bd_intf_nets qdma_M_AXIL_DBI] [get_bd_intf_pins cpm6_qdma_0/M_AXIL_DBI] [get_bd_intf_pins axis_ila_0/SLOT_6_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets qdma_M_AXIL_DBI]
  connect_bd_intf_net -intf_net qdma_s_axi_mem [get_bd_intf_pins axi_noc2_0/M01_AXI] [get_bd_intf_pins cpm6_qdma_0/S_AXI_MEM]
connect_bd_intf_net -intf_net [get_bd_intf_nets qdma_s_axi_mem] [get_bd_intf_pins axi_noc2_0/M01_AXI] [get_bd_intf_pins axis_ila_1/SLOT_0_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets qdma_s_axi_mem]
  connect_bd_intf_net -intf_net qdma_s_axi_reg [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins cpm6_qdma_0/S_AXI_REG]
connect_bd_intf_net -intf_net [get_bd_intf_nets qdma_s_axi_reg] [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins axis_ila_1/SLOT_1_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets qdma_s_axi_reg]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins cpm6_qdma_0/CPM_AXI_PL3]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_ports M_AXIL_C2H_CFG] [get_bd_intf_pins smartconnect_0/M02_AXI]

  # Create port connections
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins cpm6_qdma_0/axi_aresetn] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_ports axi_rst_n]
  connect_bd_net -net ps_wizard_0_cpm_pcie_axi_noc0_clk  [get_bd_pins ps_wizard_0/cpm_pcie_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk0]
  connect_bd_net -net ps_wizard_0_cpm_pcie_axi_noc1_clk  [get_bd_pins ps_wizard_0/cpm_pcie_axi_noc1_clk] \
  [get_bd_pins axi_noc2_0/aclk1]
  connect_bd_net -net ps_wizard_0_dma0_irq  [get_bd_pins ps_wizard_0/dma1_irq] \
  [get_bd_pins cpm6_qdma_0/hdma_irq]
  connect_bd_net -net ps_wizard_0_noc_axi_pmc0_clk  [get_bd_pins ps_wizard_0/noc_axi_pmc0_clk] \
  [get_bd_pins axi_noc2_0/aclk2]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins cpm6_qdma_0/axi_aclk] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins axi_noc2_0/aclk3] \
  [get_bd_pins ps_wizard_0/dbi1_clk] \
  [get_bd_pins ps_wizard_0/pcie1_clk] \
  [get_bd_pins ps_wizard_0/aclk0] \
  [get_bd_pins ps_wizard_0/aclk1] \
  [get_bd_pins axis_ila_1/clk] \
  [get_bd_pins axis_ila_0/clk] \
  [get_bd_ports M_AXIL_C2H_CFG_aclk] \
  [get_bd_ports axi_clk]
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins proc_sys_reset_0/interconnect_aresetn] \
  [get_bd_pins axis_ila_1/resetn] \
  [get_bd_pins axis_ila_0/resetn]

  # Create address segments
  assign_bd_address -offset 0x0001000006000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs M_AXIL_C2H_CFG/Reg] -force
  assign_bd_address -offset 0x0001000004000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs cpm6_qdma_0/S_AXI_REG/Reg] -force
  assign_bd_address -offset 0x020100000000 -range 0x00800000 -with_name SEG_cpm6_qdma_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs cpm6_qdma_0/S_AXI_MEM/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -with_name SEG_cpm6_qdma_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs cpm6_qdma_0/CPM_AXI_PL0/Reg] -force
  assign_bd_address -offset 0x0001000000000000 -range 0x00010000 -with_name SEG_cpm6_qdma_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs cpm6_qdma_0/CPM_AXI_PL1/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -with_name SEG_cpm6_qdma_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs cpm6_qdma_0/CPM_AXI_PL2/Reg] -force
  assign_bd_address -offset 0x0001000000010000 -range 0x00010000 -with_name SEG_cpm6_qdma_0_Reg_5 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs cpm6_qdma_0/CPM_AXI_PL3/Reg] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs ps_wizard_0/cpm6_0_DBI1/cpm6_0_psv_dbi1] -force
  assign_bd_address -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PMC_SLAVE_BOOT_INT/pmcps_0_psv_pmc_slave_boot] -force
  assign_bd_address -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PMC_SLAVE_BOOT_STREAM_INT/pmcps_0_psv_pmc_slave_boot_stream] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs ps_wizard_0/cpm6_0_DBI1/cpm6_0_psv_dbi1] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs cpm6_qdma_0/S_AXI_MEM/Reg]


  # Restore current instance
  current_bd_instance $oldCurInst

  # Platform (PS peripherals and PS-to-NoC ports) is added by one shared file; this design has no DDR
  set ::platform_ddr 0
  set ::platform_auto_disable 1
  source [file join $script_folder .. platform run.tcl]
  set ps  [get_bd_cells ps_wizard_0]
  set noc [get_bd_cells axi_noc2_0]
  platform_apply_ps_props $ps
  platform_noc_attach $ps $noc
  # The PS processors do not use the QDMA S_AXI_MEM port; only the CPM reaches it
  foreach asp {cortexa72_0 cortexa72_1 cortexr5_0 cortexr5_1 pmc_0 psm_0} {
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_$asp] [get_bd_addr_segs cpm6_qdma_0/S_AXI_MEM/Reg]
  }

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

# Link width (X2 or X8) comes from the CED's CTRL_LINK_WIDTH option (run.tcl);
# X2 when this script is sourced on its own.
if {![info exists link_width]} { set link_width X2 }
create_root_design "" $link_width


