
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
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:emb_mem_gen:*\
xilinx.com:ip:xlconstant:*\
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
proc create_root_design { parentCell } {

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


  # Create ports

  # Create instance: cpm6_qdma_0, and set properties
  set cpm6_qdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:cpm6_qdma cpm6_qdma_0 ]
  set_property -dict [list \
    CONFIG.cpm6_ctrl {1} \
    CONFIG.dsc_ram_base_addr {0x201_0000_0000} \
    CONFIG.enable_dbg {true} \
    CONFIG.msix_en {true} \
    CONFIG.num_pfs {1} \
    CONFIG.num_queues {256} \
    CONFIG.num_vfs {8} \
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
   CONFIG.WRITE_BUFFER_SIZE {128} \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc2_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.W_TRAFFIC_CLASS {ISOCHRONOUS} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {9000} write_bw {9000} woc {relaxed} read_avg_burst {4} write_avg_burst {4} }} \
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

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_0


  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]
  set_property CONFIG.DATA_WIDTH {512} $axi_bram_ctrl_0


  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_1 ]
  set_property CONFIG.DATA_WIDTH {512} $axi_bram_ctrl_1


  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_0_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_0_bram


  # Create instance: axi_bram_ctrl_1_bram, and set properties
  set axi_bram_ctrl_1_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_1_bram ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_1_bram


  # Create instance: constant_1, and set properties
  set constant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant constant_1 ]

  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL1_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL3_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_CFG_STATUS_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_CPIPE_LANE_LOC) {6} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_CPIPE_LANE_REVERSAL_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE0_BASEADDR) {0x0000_0000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE0_INTERLEAVE) {None} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE0_LIMITADDR) {0x0000_0000_0000_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE1_BASEADDR) {0x0000_0000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE1_DEST) {CPM_AXI_PL1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE1_LIMITADDR) {0x0000_0000_0000_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE2_BASEADDR) {0x0000_0201_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE2_DEST) {PCIE_AXI_NOC0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE2_LIMITADDR) {0x0000_0201_003F_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_IDE_CAP_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_BAR_NUM) {BAR_1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_BASEADDR) {0x0000_0000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_FUNC) {PF_0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_LIMITADDR) {0x0000_0000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_TRGTADDR) {0x0000_0000_0200_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_BAR_NUM) {BAR_1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_BASEADDR) {0x0000_0000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_FUNC) {VFG_0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_LIMITADDR) {0x0000_0000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_TRGTADDR) {0x0000_0000_0200_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_LANE_RATE) {64.0_GT/s} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_LINK_IDE_STREAM_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_LINK_WIDTH) {X2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE0_BASEADDR) {0x0000_0000_0200_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE0_DEST) {CPM_AXI_PL3} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE0_LIMITADDR) {0x0000_0000_03FF_FFFF} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MODE) {DMA_BRIDGE} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_DMA_APERTURES) {3} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_INBOUND_REGIONS) {2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_MMIO_APERTURES) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PERST) {PS_MIO_19} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR0_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR1_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR1_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR2_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR2_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR3_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR3_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR4_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR4_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR5_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR5_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_BIR) {BAR_0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_PBA_OFFSET) {0x15000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_TABLE_OFFSET) {0x14000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_MSIX_VECTORS) {8} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PROTOCOL) {PCIE_6_1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_REFCLK) {QUAD3_REFCLK0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_SELECTIVE_IDE_STREAM_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_SRIOV_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR0_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR1_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR1_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR2_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR2_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR3_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR3_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR4_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR4_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR5_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_BAR5_SCALE) {Megabytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_VFG0_FIRST_VF_OFFSET) {4} \
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
    CONFIG.PS_PMC_CONFIG(BOOT_SECONDARY_PCIE_ENABLE) {0} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL1_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL3_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_LINK_WIDTH) {X2} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_MODE) {DMA_BRIDGE} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_PERST) {PS_MIO_19} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_PROTOCOL) {PCIE_6_1} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_NOC_AXI_PMC0) {1} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {0} \
    CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_RESET) {ENABLE 1 IO PS_MIO_18:19} \
    CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
    CONFIG.PS_PMC_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PMC_MIO_16:17 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
  ] $ps_wizard_0


  # Create instance: axis_ila_1, and set properties
  set axis_ila_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila axis_ila_1 ]
  set_property -dict [list \
    CONFIG.C_INPUT_PIPE_STAGES {4} \
    CONFIG.C_MON_TYPE {Mixed} \
    CONFIG.C_NUM_MONITOR_SLOTS {4} \
    CONFIG.C_NUM_OF_PROBES {2} \
    CONFIG.C_PROBE0_TYPE {0} \
    CONFIG.C_PROBE0_WIDTH {128} \
    CONFIG.C_PROBE1_TYPE {0} \
    CONFIG.C_PROBE1_WIDTH {1} \
    CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:display_cpm6:pcie_msix_rtl:1.0} \
    CONFIG.C_SLOT_0_TYPE {0} \
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
    CONFIG.C_SLOT_2_APC_EN {0} \
    CONFIG.C_SLOT_2_AXI_AR_SEL_DATA {1} \
    CONFIG.C_SLOT_2_AXI_AR_SEL_TRIG {1} \
    CONFIG.C_SLOT_2_AXI_AW_SEL_DATA {1} \
    CONFIG.C_SLOT_2_AXI_AW_SEL_TRIG {1} \
    CONFIG.C_SLOT_2_AXI_B_SEL_DATA {1} \
    CONFIG.C_SLOT_2_AXI_B_SEL_TRIG {1} \
    CONFIG.C_SLOT_2_AXI_R_SEL_DATA {1} \
    CONFIG.C_SLOT_2_AXI_R_SEL_TRIG {1} \
    CONFIG.C_SLOT_2_AXI_W_SEL_DATA {1} \
    CONFIG.C_SLOT_2_AXI_W_SEL_TRIG {1} \
    CONFIG.C_SLOT_3_APC_EN {0} \
    CONFIG.C_SLOT_3_AXI_AR_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_AR_SEL_TRIG {1} \
    CONFIG.C_SLOT_3_AXI_AW_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_AW_SEL_TRIG {1} \
    CONFIG.C_SLOT_3_AXI_B_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_B_SEL_TRIG {1} \
    CONFIG.C_SLOT_3_AXI_R_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_R_SEL_TRIG {1} \
    CONFIG.C_SLOT_3_AXI_W_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_W_SEL_TRIG {1} \
  ] $axis_ila_1


  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_1_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_1_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins axi_noc2_0/M00_AXI] [get_bd_intf_pins ps_wizard_0/NOC_AXI_PMC0]
  connect_bd_intf_net -intf_net cpm6_qdma_0_PCIE_MSIX [get_bd_intf_pins ps_wizard_0/pcie1_msix] [get_bd_intf_pins cpm6_qdma_0/PCIE_MSIX]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpm6_qdma_0_PCIE_MSIX] [get_bd_intf_pins ps_wizard_0/pcie1_msix] [get_bd_intf_pins axis_ila_1/SLOT_0_PCIE_MSIX]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpm6_qdma_0_PCIE_MSIX]
  connect_bd_intf_net -intf_net ctrl0_gt_refclk_0_1 [get_bd_intf_ports ctrl1_gt_refclk_0] [get_bd_intf_pins ps_wizard_0/ctrl1_gt_refclk]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S00_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC1] [get_bd_intf_pins axi_noc2_0/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_CTRL0_GT [get_bd_intf_ports CTRL1_GT_0] [get_bd_intf_pins ps_wizard_0/CTRL1_GT]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl0 [get_bd_intf_pins ps_wizard_0/cpm_axi_pl0] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl1 [get_bd_intf_pins ps_wizard_0/cpm_axi_pl1] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl3 [get_bd_intf_pins ps_wizard_0/cpm_axi_pl3] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net qdma_M_AXIL_DBI [get_bd_intf_pins cpm6_qdma_0/M_AXIL_DBI] [get_bd_intf_pins ps_wizard_0/pl_axil_dbi1]
connect_bd_intf_net -intf_net [get_bd_intf_nets qdma_M_AXIL_DBI] [get_bd_intf_pins cpm6_qdma_0/M_AXIL_DBI] [get_bd_intf_pins axis_ila_1/SLOT_1_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets qdma_M_AXIL_DBI]
  connect_bd_intf_net -intf_net qdma_s_axi_mem [get_bd_intf_pins axi_noc2_0/M01_AXI] [get_bd_intf_pins cpm6_qdma_0/S_AXI_MEM]
connect_bd_intf_net -intf_net [get_bd_intf_nets qdma_s_axi_mem] [get_bd_intf_pins axi_noc2_0/M01_AXI] [get_bd_intf_pins axis_ila_1/SLOT_2_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets qdma_s_axi_mem]
  connect_bd_intf_net -intf_net qdma_s_axi_reg [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins cpm6_qdma_0/S_AXI_REG]
connect_bd_intf_net -intf_net [get_bd_intf_nets qdma_s_axi_reg] [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins axis_ila_1/SLOT_3_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets qdma_s_axi_reg]

  # Create port connections
  connect_bd_net -net constant_1_dout  [get_bd_pins constant_1/dout] \
  [get_bd_pins cpm6_qdma_0/tm_dsc_sts_rdy]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] \
  [get_bd_pins cpm6_qdma_0/axi_aresetn] \
  [get_bd_pins axis_ila_1/probe1] \
  [get_bd_pins axis_ila_1/resetn]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets proc_sys_reset_0_peripheral_aresetn]
  connect_bd_net -net ps_wizard_0_cpm_pcie_axi_noc0_clk  [get_bd_pins ps_wizard_0/cpm_pcie_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk0]
  connect_bd_net -net ps_wizard_0_cpm_pcie_axi_noc1_clk  [get_bd_pins ps_wizard_0/cpm_pcie_axi_noc1_clk] \
  [get_bd_pins axi_noc2_0/aclk1]
  connect_bd_net -net ps_wizard_0_dma0_irq  [get_bd_pins ps_wizard_0/dma1_irq] \
  [get_bd_pins cpm6_qdma_0/hdma_irq] \
  [get_bd_pins axis_ila_1/probe0]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets ps_wizard_0_dma0_irq]
  connect_bd_net -net ps_wizard_0_noc_axi_pmc0_clk  [get_bd_pins ps_wizard_0/noc_axi_pmc0_clk] \
  [get_bd_pins axi_noc2_0/aclk2]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins axi_noc2_0/aclk3] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] \
  [get_bd_pins ps_wizard_0/dbi1_clk] \
  [get_bd_pins ps_wizard_0/pcie1_clk] \
  [get_bd_pins ps_wizard_0/aclk0] \
  [get_bd_pins ps_wizard_0/aclk1] \
  [get_bd_pins cpm6_qdma_0/axi_aclk] \
  [get_bd_pins axis_ila_1/clk]
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x0001000000000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x0001000002000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs cpm6_qdma_0/S_AXI_REG/Reg] -force
  assign_bd_address -offset 0x020100000000 -range 0x00400000 -with_name SEG_cpm6_qdma_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs cpm6_qdma_0/S_AXI_MEM/Reg] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs ps_wizard_0/cpm6_0_DBI1/cpm6_0_psv_dbi1] -force
  assign_bd_address -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PMC_SLAVE_BOOT_INT/pmcps_0_psv_pmc_slave_boot] -force
  assign_bd_address -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PMC_SLAVE_BOOT_STREAM_INT/pmcps_0_psv_pmc_slave_boot_stream] -force
  assign_bd_address -offset 0x020100000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs cpm6_qdma_0/S_AXI_MEM/Reg] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs ps_wizard_0/cpm6_0_DBI1/cpm6_0_psv_dbi1] -force


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


