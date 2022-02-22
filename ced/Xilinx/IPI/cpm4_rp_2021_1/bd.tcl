
################################################################
# This is a generated script based on design: design_rc
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
set scripts_vivado_version 2021.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_rc_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvc1902-vsva2197-3HP-e-S
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name design_rc

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
xilinx.com:ip:axi_noc:1.0\
xilinx.com:ip:versal_cips:3.1\
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
  set CH0_DDR4_0_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 CH0_DDR4_0_0 ]

  set GT_Serial_TX_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial_TX_0 ]

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]

  set sys_clk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $sys_clk0_0


  # Create ports

  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.0 axi_noc_0 ]
  set_property -dict [ list \
   CONFIG.LOGO_FILE {data/noc_mc.png} \
   CONFIG.MC_CASLATENCY {18} \
   CONFIG.MC_CASWRITELATENCY {16} \
   CONFIG.MC_CONFIG_NUM {config17} \
   CONFIG.MC_DDR4_2T {Disable} \
   CONFIG.MC_ECC_SCRUB_PERIOD {0x002EE5} \
   CONFIG.MC_EN_INTR_RESP {FALSE} \
   CONFIG.MC_F1_TRCD {13750} \
   CONFIG.MC_F1_TRCDMIN {13750} \
   CONFIG.MC_INPUTCLK0_PERIOD {4998} \
   CONFIG.MC_INPUT_FREQUENCY0 {200.080} \
   CONFIG.MC_MEMORY_DEVICETYPE {UDIMMs} \
   CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
   CONFIG.MC_MEMORY_TIMEPERIOD0 {833} \
   CONFIG.MC_READ_BANDWIDTH {4801.921} \
   CONFIG.MC_TCCD_L {7} \
   CONFIG.MC_TCCD_L_MIN {7} \
   CONFIG.MC_TCKE {7} \
   CONFIG.MC_TCKEMIN {7} \
   CONFIG.MC_TFAW {21000} \
   CONFIG.MC_TFAWMIN {21000} \
   CONFIG.MC_TFAW_nCK {26} \
   CONFIG.MC_TRC {45750} \
   CONFIG.MC_TRCD {13750} \
   CONFIG.MC_TRCDMIN {13750} \
   CONFIG.MC_TRCMIN {45750} \
   CONFIG.MC_TRP {13750} \
   CONFIG.MC_TRPMIN {13750} \
   CONFIG.MC_TRRD_L {6} \
   CONFIG.MC_TRRD_L_MIN {6} \
   CONFIG.MC_TRTP_nCK {10} \
   CONFIG.MC_TXP {8} \
   CONFIG.MC_TXPMIN {8} \
   CONFIG.MC_TXPR {433} \
   CONFIG.MC_WRITE_BANDWIDTH {4801.921} \
   CONFIG.MC_XPLL_CLKOUT1_PERIOD {1666} \
   CONFIG.MC_XPLL_CLKOUT1_PHASE {268.59543817527015} \
   CONFIG.NUM_CLKS {10} \
   CONFIG.NUM_MC {1} \
   CONFIG.NUM_MCP {4} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {9} \
 ] $axi_noc_0

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5}} } \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_1 { read_bw {5} write_bw {5}} } \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_1 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_2 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_2 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_3 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_3 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /axi_noc_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_3 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /axi_noc_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S08_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk9]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.CPM_CONFIG {CPM_CCIX_IS_MM_ONLY 1 CPM_PCIE0_AXIBAR_NUM 2\
CPM_PCIE0_AXISTEN_IF_CQ_ALIGNMENT_MODE Address_Aligned\
CPM_PCIE0_AXISTEN_IF_ENABLE_CLIENT_TAG 1\
CPM_PCIE0_AXISTEN_IF_EXT_512_RC_STRADDLE 1\
CPM_PCIE0_AXISTEN_IF_EXT_512_RQ_STRADDLE 1 CPM_PCIE0_AXISTEN_IF_RC_STRADDLE 1\
CPM_PCIE0_AXISTEN_IF_WIDTH 512 CPM_PCIE0_BRIDGE_AXI_SLAVE_IF 1\
CPM_PCIE0_CONTROLLER_ENABLE 1 CPM_PCIE0_CORE_CLK_FREQ 500\
CPM_PCIE0_DMA_DATA_WIDTH 512bits CPM_PCIE0_EXT_PCIE_CFG_SPACE_ENABLED\
Extended_Small CPM_PCIE0_FUNCTIONAL_MODE AXI_Bridge\
CPM_PCIE0_LINK_SPEED0_FOR_POWER GEN4 CPM_PCIE0_LINK_WIDTH0_FOR_POWER 8\
CPM_PCIE0_MAX_LINK_SPEED 16.0_GT/s CPM_PCIE0_MODE0_FOR_POWER CPM_STREAM_W_DMA\
CPM_PCIE0_MODES DMA CPM_PCIE0_MODE_SELECTION Advanced CPM_PCIE0_MSIX_RP_ENABLED\
0 CPM_PCIE0_NUM_USR_IRQ 0 CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_0\
0x00000000e0000000 CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_1 0x0000008000000000\
CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_0 0x0000000000000000\
CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_1 0x0000000000000000\
CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_0 0x000000000efffffff\
CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_1 0x00000081FFFFFFFF\
CPM_PCIE0_PF0_BAR0_BRIDGE_ENABLED 1 CPM_PCIE0_PF0_BAR0_BRIDGE_SCALE Gigabytes\
CPM_PCIE0_PF0_BAR0_BRIDGE_SIZE 2 CPM_PCIE0_PF0_BAR0_QDMA_64BIT 0\
CPM_PCIE0_PF0_BAR0_QDMA_ENABLED 0 CPM_PCIE0_PF0_BAR0_QDMA_PREFETCHABLE 0\
CPM_PCIE0_PF0_BAR0_QDMA_SCALE Bytes CPM_PCIE0_PF0_BAR0_QDMA_TYPE\
AXI_Bridge_Master CPM_PCIE0_PF0_BAR0_SCALE Gigabytes CPM_PCIE0_PF0_BAR0_SIZE 2\
CPM_PCIE0_PF0_BAR0_XDMA_64BIT 0 CPM_PCIE0_PF0_BAR0_XDMA_ENABLED 0\
CPM_PCIE0_PF0_BAR0_XDMA_PREFETCHABLE 0 CPM_PCIE0_PF0_BAR0_XDMA_SCALE Bytes\
CPM_PCIE0_PF0_BAR0_XDMA_TYPE AXI_Bridge_Master CPM_PCIE0_PF0_BASE_CLASS_MENU\
Bridge_device CPM_PCIE0_PF0_BASE_CLASS_VALUE 06 CPM_PCIE0_PF0_CLASS_CODE\
0x060400 CPM_PCIE0_PF0_INTERFACE_VALUE 00 CPM_PCIE0_PF0_INTERRUPT_PIN INTA\
CPM_PCIE0_PF0_MARGINING_CAP_ON 1 CPM_PCIE0_PF0_MSIX_CAP_PBA_OFFSET 8FE0\
CPM_PCIE0_PF0_MSIX_CAP_TABLE_OFFSET 8000 CPM_PCIE0_PF0_MSIX_CAP_TABLE_SIZE 1F\
CPM_PCIE0_PF0_PL16_CAP_ON 1 CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D0 1\
CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D1 1 CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D3COLD 1\
CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D3HOT 1 CPM_PCIE0_PF0_PM_CAP_SUPP_D1_STATE 1\
CPM_PCIE0_PF0_SUB_CLASS_INTF_MENU PCI_to_PCI_bridge\
CPM_PCIE0_PF0_SUB_CLASS_VALUE 04 CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT\
1 CPM_PCIE0_PF1_BAR0_QDMA_64BIT 0 CPM_PCIE0_PF1_BAR0_QDMA_ENABLED 0\
CPM_PCIE0_PF1_BAR0_QDMA_PREFETCHABLE 0 CPM_PCIE0_PF1_BAR0_QDMA_SCALE Bytes\
CPM_PCIE0_PF1_BAR0_QDMA_TYPE AXI_Bridge_Master CPM_PCIE0_PF1_INTERRUPT_PIN INTA\
CPM_PCIE0_PF1_MSIX_CAP_PBA_OFFSET 8FE0 CPM_PCIE0_PF1_MSIX_CAP_TABLE_OFFSET 8000\
CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE 1F CPM_PCIE0_PF1_VEND_ID 0\
CPM_PCIE0_PF2_BAR0_QDMA_64BIT 0 CPM_PCIE0_PF2_BAR0_QDMA_ENABLED 0\
CPM_PCIE0_PF2_BAR0_QDMA_PREFETCHABLE 0 CPM_PCIE0_PF2_BAR0_QDMA_SCALE Bytes\
CPM_PCIE0_PF2_BAR0_QDMA_TYPE AXI_Bridge_Master CPM_PCIE0_PF2_INTERRUPT_PIN INTA\
CPM_PCIE0_PF2_MSIX_CAP_PBA_OFFSET 8FE0 CPM_PCIE0_PF2_MSIX_CAP_TABLE_OFFSET 8000\
CPM_PCIE0_PF2_MSIX_CAP_TABLE_SIZE 1F CPM_PCIE0_PF2_VEND_ID 0\
CPM_PCIE0_PF3_BAR0_QDMA_64BIT 0 CPM_PCIE0_PF3_BAR0_QDMA_ENABLED 0\
CPM_PCIE0_PF3_BAR0_QDMA_PREFETCHABLE 0 CPM_PCIE0_PF3_BAR0_QDMA_SCALE Bytes\
CPM_PCIE0_PF3_BAR0_QDMA_TYPE AXI_Bridge_Master CPM_PCIE0_PF3_INTERRUPT_PIN INTA\
CPM_PCIE0_PF3_MSIX_CAP_PBA_OFFSET 8FE0 CPM_PCIE0_PF3_MSIX_CAP_TABLE_OFFSET 8000\
CPM_PCIE0_PF3_MSIX_CAP_TABLE_SIZE 1F CPM_PCIE0_PF3_VEND_ID 0\
CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH X8 CPM_PCIE0_PORT_TYPE\
Root_Port_of_PCI_Express_Root_Complex\
CPM_PCIE0_TYPE1_MEMBASE_MEMLIMIT_BRIDGE_ENABLE Enabled\
CPM_PCIE0_TYPE1_PREFETCHABLE_MEMBASE_BRIDGE_MEMLIMIT 64bit_Enabled\
CPM_PCIE0_USER_CLK2_FREQ 500_MHz CPM_PCIE0_USER_CLK_FREQ 250_MHz\
CPM_PCIE0_VFG0_MSIX_CAP_TABLE_SIZE 1 CPM_PCIE0_VFG0_MSIX_ENABLED 0\
CPM_PCIE0_VFG1_MSIX_CAP_TABLE_SIZE 1 CPM_PCIE0_VFG1_MSIX_ENABLED 0\
CPM_PCIE0_VFG2_MSIX_CAP_TABLE_SIZE 1 CPM_PCIE0_VFG2_MSIX_ENABLED 0\
CPM_PCIE0_VFG3_MSIX_CAP_TABLE_SIZE 1 CPM_PCIE0_VFG3_MSIX_ENABLED 0\
CPM_PCIE_CHANNELS_FOR_POWER 1 CPM_PERIPHERAL_EN 1 CPM_REQ_AGENTS_0_ENABLE 0\
CPM_REQ_AGENTS_1_ENABLE 0 PS_USE_NOC_PS_PCI_0 1 PS_USE_PS_NOC_PCI_0 1\
PS_USE_PS_NOC_PCI_1 0}\
   CONFIG.PS_PMC_CONFIG {DESIGN_MODE 1 PCIE_APERTURES_DUAL_ENABLE 0 PCIE_APERTURES_SINGLE_ENABLE 1\
PMC_CRP_CFU_REF_CTRL_FREQMHZ 300 PMC_CRP_PL0_REF_CTRL_ACT_FREQMHZ 239.997604\
PMC_CRP_PL0_REF_CTRL_DIVISOR0 5 PMC_CRP_PL0_REF_CTRL_FREQMHZ 250 PMC_MIO43\
{{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL\
pullup} {SCHMITT 1} {SLEW slow} {USAGE Reserved}} PMC_MIO_TREE_PERIPHERALS\
{##########################SD1/eMMC1#SD1/eMMC1#SD1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1##PCIE####UART\
0#UART 0#######SD1#SD1/eMMC1##########################} PMC_MIO_TREE_SIGNALS\
##########################clk#dir1/data[7]#detect#cmd#data[0]#data[1]#data[2]#data[3]#sel/data[4]#dir_cmd/data[5]#dir0/data[6]##reset1_n####rxd#txd#######wp#buspwr/rst##########################\
PMC_SD0_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 13 .. 25}}} PMC_SD1 {{CD_ENABLE 1}\
{CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0}\
{RESET_IO {PMC_MIO 1}} {WP_ENABLE 1} {WP_IO {PMC_MIO 50}}}\
PMC_SD1_DATA_TRANSFER_MODE 8Bit PMC_SD1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26\
.. 36}}} PMC_SD1_SLOT_TYPE {SD 3.0} PMC_USE_PMC_NOC_AXI0 1 PS_BOARD_INTERFACE\
Custom PS_CRF_FPD_TOP_SWITCH_CTRL_ACT_FREQMHZ 849.991516\
PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ 749.992493\
PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ 775 PS_CRL_CPM_TOPSW_REF_CTRL_SRCSEL RPLL\
PS_CRL_RPLL_CTRL_FBDIV 90 PS_CRL_UART0_REF_CTRL_ACT_FREQMHZ 99.999001\
PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI2_ENABLE 1\
PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI5_ENABLE 1\
PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI_PMCNOBUF_ENABLE 1 PS_GEN_IPI_PMC_ENABLE 1\
PS_GEN_IPI_PSM_ENABLE 1 PS_IRQ_USAGE {{CH0 1} {CH1 0} {CH10 0} {CH11 0} {CH12\
0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0}\
{CH8 0} {CH9 0}} PS_MIO0 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA}\
{OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW slow} {USAGE Unassigned}}\
PS_NUM_FABRIC_RESETS 1 PS_PCIE1_PERIPHERAL_ENABLE 2 PS_PCIE2_PERIPHERAL_ENABLE\
0 PS_PCIE_RESET {{ENABLE 1} {IO {PS_MIO 18 .. 19}}} PS_PCIE_ROOT_RESET1_IO\
{PMC_MIO 38} PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}}\
PS_USE_BSCAN_USER1 0 PS_USE_FPD_AXI_NOC0 1 PS_USE_FPD_AXI_NOC1 1\
PS_USE_FPD_CCI_NOC 1 PS_USE_FPD_CCI_NOC0 1 PS_USE_M_AXI_FPD 0\
PS_USE_NOC_LPD_AXI0 1 PS_USE_NOC_PS_PCI_0 1 PS_USE_PMCPL_CLK0 1\
PS_USE_PS_NOC_PCI_0 1 PS_USE_PS_NOC_PCI_1 0 SMON_ALARMS Set_Alarms_On\
SMON_ENABLE_TEMP_AVERAGING 0 SMON_TEMP_AVERAGING_SAMPLES 8}\
   CONFIG.PS_PMC_CONFIG_APPLIED {1} \
 ] $versal_cips_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_ports CH0_DDR4_0_0] [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins versal_cips_0/NOC_CPM_PCIE_0]
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins versal_cips_0/gt_refclk0]
  connect_bd_intf_net -intf_net sys_clk0_0_1 [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins axi_noc_0/sys_clk0]
  connect_bd_intf_net -intf_net versal_cips_0_CPM_PCIE_NOC_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_GT_Serial_TX [get_bd_intf_ports GT_Serial_TX_0] [get_bd_intf_pins versal_cips_0/PCIE0_GT]
  connect_bd_intf_net -intf_net versal_cips_0_IF_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]
  connect_bd_intf_net -intf_net versal_cips_0_IF_PS_NOC_CCI_0 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_IF_PS_NOC_CCI_1 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_IF_PS_NOC_CCI_2 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net versal_cips_0_IF_PS_NOC_CCI_3 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net versal_cips_0_IF_PS_NOC_NCI_0 [get_bd_intf_pins axi_noc_0/S07_AXI] [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_IF_PS_NOC_NCI_1 [get_bd_intf_pins axi_noc_0/S08_AXI] [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S06_AXI] [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0]

  # Create port connections
  connect_bd_net -net versal_cips_0_cpm_pcie_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk7] [get_bd_pins versal_cips_0/fpd_axi_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_axi_noc_axi1_clk [get_bd_pins axi_noc_0/aclk8] [get_bd_pins versal_cips_0/fpd_axi_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk [get_bd_pins axi_noc_0/aclk2] [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk [get_bd_pins axi_noc_0/aclk3] [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk [get_bd_pins axi_noc_0/aclk4] [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk [get_bd_pins axi_noc_0/aclk5] [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins axi_noc_0/aclk6] [get_bd_pins versal_cips_0/lpd_axi_noc_clk]
  connect_bd_net -net versal_cips_0_noc_cpm_pcie_axi0_clk [get_bd_pins axi_noc_0/aclk9] [get_bd_pins versal_cips_0/noc_cpm_pcie_axi0_clk]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S03_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S02_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S05_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S04_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S07_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs axi_noc_0/S08_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force


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


