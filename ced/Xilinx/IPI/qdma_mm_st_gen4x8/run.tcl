
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
# source design_1_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvc1902-vsva2197-2MP-e-S
   set_property BOARD_PART xilinx.com:vck190:part0:2.2 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
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
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:emb_mem_gen:1.0\
xilinx.com:ip:axi_noc:1.0\
xilinx.com:ip:pcie_qdma_mailbox:1.0\
xilinx.com:ip:smartconnect:1.0\
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
  set M00_AXI_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {42} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $M00_AXI_0

  set PCIE0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT_0 ]

  set dma0_axis_c2h_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_c2h_status_rtl:1.0 dma0_axis_c2h_status_0 ]

  set dma0_c2h_byp_in_mm_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_c2h_byp_in_mm_0 ]

  set dma0_c2h_byp_in_st_csh_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_c2h_byp_in_st_csh_0 ]

  set dma0_c2h_byp_in_st_sim_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_c2h_byp_in_st_sim_0 ]

  set dma0_c2h_byp_out_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_c2h_byp_out_0 ]

  set dma0_dsc_crdt_in_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_crdt_in_rtl:1.0 dma0_dsc_crdt_in_0 ]

  set dma0_h2c_byp_in_mm_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_h2c_byp_in_mm_0 ]

  set dma0_h2c_byp_in_st_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_h2c_byp_in_st_0 ]

  set dma0_h2c_byp_out_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_h2c_byp_out_0 ]

  set dma0_m_axis_h2c_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_qdma:m_axis_h2c_rtl:1.0 dma0_m_axis_h2c_0 ]

  set dma0_s_axis_c2h_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_qdma:s_axis_c2h_rtl:1.0 dma0_s_axis_c2h_0 ]

  set dma0_s_axis_c2h_cmpt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_qdma:s_axis_c2h_cmpt_rtl:1.0 dma0_s_axis_c2h_cmpt_0 ]

  set dma0_st_rx_msg_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 dma0_st_rx_msg_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $dma0_st_rx_msg_0

  set dma0_tm_dsc_sts_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_tm_dsc_sts_rtl:1.0 dma0_tm_dsc_sts_0 ]

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]

  set usr_flr_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:usr_flr_rtl:1.0 usr_flr_0 ]

  set usr_irq_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_usr_irq_rtl:1.0 usr_irq_0 ]


  # Create ports
  set dma0_axi_aresetn_0 [ create_bd_port -dir O -type rst dma0_axi_aresetn_0 ]
  set dma0_soft_resetn_0 [ create_bd_port -dir I -type rst dma0_soft_resetn_0 ]
  set pcie0_user_clk_0 [ create_bd_port -dir O -type clk pcie0_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {dma0_st_rx_msg_0:M00_AXI_0} \
   CONFIG.FREQ_HZ {250000000} \
 ] $pcie0_user_clk_0
  set pcie0_user_lnk_up_0 [ create_bd_port -dir O pcie0_user_lnk_up_0 ]

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]

  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 axi_bram_ctrl_0_bram ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH_A {19} \
   CONFIG.ADDR_WIDTH_B {19} \
   CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_0_bram

  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.0 axi_noc_0 ]
  set_property -dict [ list \
   CONFIG.HBM_CHNL0_CONFIG { } \
   CONFIG.LOGO_FILE {data/noc.png} \
   CONFIG.MC_ADDR_BIT14 {BA0} \
   CONFIG.MC_ADDR_BIT15 {BA1} \
   CONFIG.MC_ADDR_BIT16 {RA0} \
   CONFIG.MC_ADDR_BIT17 {RA1} \
   CONFIG.MC_ADDR_BIT18 {RA2} \
   CONFIG.MC_ADDR_BIT19 {RA3} \
   CONFIG.MC_ADDR_BIT20 {RA4} \
   CONFIG.MC_ADDR_BIT21 {RA5} \
   CONFIG.MC_ADDR_BIT22 {RA6} \
   CONFIG.MC_ADDR_BIT23 {RA7} \
   CONFIG.MC_ADDR_BIT24 {RA8} \
   CONFIG.MC_ADDR_BIT25 {RA9} \
   CONFIG.MC_ADDR_BIT26 {RA10} \
   CONFIG.MC_ADDR_BIT27 {RA11} \
   CONFIG.MC_ADDR_BIT28 {RA12} \
   CONFIG.MC_ADDR_BIT29 {RA13} \
   CONFIG.MC_ADDR_BIT30 {RA14} \
   CONFIG.MC_ADDR_BIT31 {RA15} \
   CONFIG.MC_ADDR_BIT32 {NA} \
   CONFIG.MC_BG_WIDTH {1} \
   CONFIG.MC_CASLATENCY {22} \
   CONFIG.MC_COMPONENT_WIDTH {x16} \
   CONFIG.MC_DDR_INIT_TIMEOUT {0x000408B7} \
   CONFIG.MC_ECC_SCRUB_SIZE {4096} \
   CONFIG.MC_EN_INTR_RESP {FALSE} \
   CONFIG.MC_F1_LPDDR4_MR1 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR2 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR3 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR13 {0x0000} \
   CONFIG.MC_F1_TFAW {30000} \
   CONFIG.MC_F1_TFAWMIN {30000} \
   CONFIG.MC_F1_TRCD {13750} \
   CONFIG.MC_F1_TRCDMIN {13750} \
   CONFIG.MC_F1_TRRD_L {11} \
   CONFIG.MC_F1_TRRD_L_MIN {11} \
   CONFIG.MC_F1_TRRD_S {9} \
   CONFIG.MC_F1_TRRD_S_MIN {9} \
   CONFIG.MC_INPUTCLK0_PERIOD {5000} \
   CONFIG.MC_INPUT_FREQUENCY0 {200.000} \
   CONFIG.MC_MEMORY_DENSITY {4GB} \
   CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
   CONFIG.MC_MEM_DEVICE_WIDTH {x16} \
   CONFIG.MC_TFAW {30000} \
   CONFIG.MC_TFAWMIN {30000} \
   CONFIG.MC_TFAW_nCK {48} \
   CONFIG.MC_TRC {45750} \
   CONFIG.MC_TRCD {13750} \
   CONFIG.MC_TRCDMIN {13750} \
   CONFIG.MC_TRCMIN {45750} \
   CONFIG.MC_TRP {13750} \
   CONFIG.MC_TRPMIN {13750} \
   CONFIG.MC_TRRD_L {11} \
   CONFIG.MC_TRRD_L_MIN {11} \
   CONFIG.MC_TRRD_S {9} \
   CONFIG.MC_TRRD_S_MIN {9} \
   CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-2BA-1BG-10CA} \
   CONFIG.NUM_CLKS {3} \
   CONFIG.NUM_MC {0} \
   CONFIG.NUM_MCP {0} \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {2} \
 ] $axi_noc_0

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x208_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x210_4000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720}}} \
   CONFIG.DEST_IDS {M01_AXI:0x80:M02_AXI:0x40:M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M01_AXI:0x80:M02_AXI:0x40:M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI:M02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  # Create instance: pcie_qdma_mailbox_0, and set properties
  set pcie_qdma_mailbox_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_qdma_mailbox:1.0 pcie_qdma_mailbox_0 ]

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_0

  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_1

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.1 versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.CPM_CONFIG {CPM_AUX0_REF_CTRL_ACT_FREQMHZ 899.991028 CPM_AUX0_REF_CTRL_DIVISOR0 2\
CPM_AUX0_REF_CTRL_FREQMHZ 900 CPM_AUX1_REF_CTRL_ACT_FREQMHZ 899.991028\
CPM_AUX1_REF_CTRL_DIVISOR0 2 CPM_AUX1_REF_CTRL_FREQMHZ 900\
CPM_CORE_REF_CTRL_ACT_FREQMHZ 899.991028 CPM_CORE_REF_CTRL_DIVISOR0 2\
CPM_CORE_REF_CTRL_FREQMHZ 900 CPM_CPLL_CTRL_FBDIV 108\
CPM_DBG_REF_CTRL_ACT_FREQMHZ 299.997009 CPM_DBG_REF_CTRL_DIVISOR0 6\
CPM_DBG_REF_CTRL_FREQMHZ 300 CPM_DESIGN_USE_MODE 4 CPM_LSBUS_REF_CTRL_DIVISOR0\
12 CPM_PCIE0_AXISTEN_IF_CQ_ALIGNMENT_MODE Address_Aligned\
CPM_PCIE0_AXISTEN_IF_ENABLE_CLIENT_TAG 1 CPM_PCIE0_AXISTEN_IF_RC_STRADDLE 1\
CPM_PCIE0_AXISTEN_IF_WIDTH 512 CPM_PCIE0_CONTROLLER_ENABLE 1\
CPM_PCIE0_COPY_PF0_ENABLED 1 CPM_PCIE0_COPY_PF0_QDMA_ENABLED 0\
CPM_PCIE0_COPY_PF0_SRIOV_QDMA_ENABLED 0 CPM_PCIE0_COPY_XDMA_PF0_ENABLED 1\
CPM_PCIE0_DMA_DATA_WIDTH 512bits CPM_PCIE0_DMA_INTF AXI_MM_and_AXI_Stream\
CPM_PCIE0_DSC_BYPASS_RD 1 CPM_PCIE0_DSC_BYPASS_WR 1 CPM_PCIE0_FUNCTIONAL_MODE\
QDMA CPM_PCIE0_LINK_SPEED0_FOR_POWER GEN4 CPM_PCIE0_LINK_WIDTH0_FOR_POWER 8\
CPM_PCIE0_MAILBOX_ENABLE 1 CPM_PCIE0_MAX_LINK_SPEED 16.0_GT/s\
CPM_PCIE0_MODE0_FOR_POWER CPM_STREAM_W_DMA CPM_PCIE0_MODES DMA\
CPM_PCIE0_MODE_SELECTION Advanced CPM_PCIE0_MSIX_RP_ENABLED 0\
CPM_PCIE0_MSI_X_OPTIONS MSI-X_Internal CPM_PCIE0_NUM_USR_IRQ 0\
CPM_PCIE0_PF0_BAR0_64BIT 0 CPM_PCIE0_PF0_BAR0_PREFETCHABLE 0\
CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_SIZE 1 CPM_PCIE0_PF0_BAR0_XDMA_64BIT 0\
CPM_PCIE0_PF0_BAR0_XDMA_ENABLED 0 CPM_PCIE0_PF0_BAR0_XDMA_PREFETCHABLE 0\
CPM_PCIE0_PF0_BAR0_XDMA_SCALE Bytes CPM_PCIE0_PF0_BAR0_XDMA_TYPE\
AXI_Bridge_Master CPM_PCIE0_PF0_BAR2_64BIT 1 CPM_PCIE0_PF0_BAR2_ENABLED 1\
CPM_PCIE0_PF0_BAR2_PREFETCHABLE 1 CPM_PCIE0_PF0_BAR2_QDMA_64BIT 1\
CPM_PCIE0_PF0_BAR2_QDMA_ENABLED 1 CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE 1\
CPM_PCIE0_PF0_BAR2_QDMA_SCALE Kilobytes CPM_PCIE0_PF0_BAR2_QDMA_SIZE 4\
CPM_PCIE0_PF0_BAR2_SCALE Kilobytes CPM_PCIE0_PF0_BAR2_SIZE 4\
CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_64BIT 1 CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_ENABLED 1\
CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_PREFETCHABLE 1\
CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SCALE Kilobytes\
CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SIZE 4 CPM_PCIE0_PF0_CLASS_CODE 0x058000\
CPM_PCIE0_PF0_DEV_CAP_EXT_TAG_EN 1\
CPM_PCIE0_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE 1\
CPM_PCIE0_PF0_INTERFACE_VALUE 00 CPM_PCIE0_PF0_MSIX_CAP_PBA_BIR BAR_0\
CPM_PCIE0_PF0_MSIX_CAP_PBA_OFFSET 1400 CPM_PCIE0_PF0_MSIX_CAP_TABLE_BIR BAR_0\
CPM_PCIE0_PF0_MSIX_CAP_TABLE_OFFSET 2000 CPM_PCIE0_PF0_MSI_ENABLED 0\
CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_0 0x0000000000000000\
CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 0x0000021040000000\
CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_0 0x0000020804000000\
CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 0x0000021040004000\
CPM_PCIE0_PF0_SRIOV_BAR0_64BIT 0 CPM_PCIE0_PF0_SRIOV_BAR0_PREFETCHABLE 0\
CPM_PCIE0_PF0_SRIOV_BAR0_SIZE 128 CPM_PCIE0_PF0_SRIOV_BAR2_64BIT 1\
CPM_PCIE0_PF0_SRIOV_BAR2_ENABLED 1 CPM_PCIE0_PF0_SRIOV_BAR2_PREFETCHABLE 1\
CPM_PCIE0_PF0_SRIOV_BAR2_SCALE Kilobytes CPM_PCIE0_PF0_SRIOV_BAR2_SIZE 4\
CPM_PCIE0_PF0_SRIOV_CAP_ENABLE 0 CPM_PCIE0_PF0_SRIOV_CAP_INITIAL_VF 64\
CPM_PCIE0_PF0_SRIOV_SUPPORTED_PAGE_SIZE 00000553 CPM_PCIE0_PF1_BAR0_QDMA_64BIT\
0 CPM_PCIE0_PF1_BAR0_QDMA_PREFETCHABLE 0 CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_64BIT 0\
CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_PREFETCHABLE 0 CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_SIZE\
1 CPM_PCIE0_PF1_BAR2_64BIT 1 CPM_PCIE0_PF1_BAR2_ENABLED 1\
CPM_PCIE0_PF1_BAR2_PREFETCHABLE 1 CPM_PCIE0_PF1_BAR2_QDMA_64BIT 1\
CPM_PCIE0_PF1_BAR2_QDMA_ENABLED 1 CPM_PCIE0_PF1_BAR2_QDMA_PREFETCHABLE 1\
CPM_PCIE0_PF1_BAR2_QDMA_SCALE Kilobytes CPM_PCIE0_PF1_BAR2_QDMA_SIZE 4\
CPM_PCIE0_PF1_BAR2_SCALE Kilobytes CPM_PCIE0_PF1_BAR2_SIZE 4\
CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_64BIT 1 CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_ENABLED 1\
CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_PREFETCHABLE 1\
CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SCALE Kilobytes\
CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SIZE 4 CPM_PCIE0_PF1_CLASS_CODE 0x058000\
CPM_PCIE0_PF1_MSIX_CAP_PBA_OFFSET 1400 CPM_PCIE0_PF1_MSIX_CAP_TABLE_OFFSET 2000\
CPM_PCIE0_PF1_MSI_ENABLED 0 CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_0\
0x0000020801000000 CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_2 0x0000021040001000\
CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_0 0x0000020805000000\
CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_2 0x0000021040005000\
CPM_PCIE0_PF1_SRIOV_BAR0_64BIT 0 CPM_PCIE0_PF1_SRIOV_BAR0_PREFETCHABLE 0\
CPM_PCIE0_PF1_SRIOV_BAR0_SIZE 128 CPM_PCIE0_PF1_SRIOV_BAR2_64BIT 1\
CPM_PCIE0_PF1_SRIOV_BAR2_ENABLED 1 CPM_PCIE0_PF1_SRIOV_BAR2_PREFETCHABLE 1\
CPM_PCIE0_PF1_SRIOV_BAR2_SCALE Kilobytes CPM_PCIE0_PF1_SRIOV_BAR2_SIZE 4\
CPM_PCIE0_PF1_SRIOV_CAP_ENABLE 0 CPM_PCIE0_PF1_SRIOV_CAP_INITIAL_VF 64\
CPM_PCIE0_PF1_SRIOV_FIRST_VF_OFFSET 67 CPM_PCIE0_PF1_SRIOV_SUPPORTED_PAGE_SIZE\
00000553 CPM_PCIE0_PF2_BAR0_QDMA_64BIT 0 CPM_PCIE0_PF2_BAR0_QDMA_PREFETCHABLE 0\
CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_64BIT 0\
CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_PREFETCHABLE 0 CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_SIZE\
1 CPM_PCIE0_PF2_BAR2_64BIT 1 CPM_PCIE0_PF2_BAR2_ENABLED 1\
CPM_PCIE0_PF2_BAR2_PREFETCHABLE 1 CPM_PCIE0_PF2_BAR2_QDMA_64BIT 1\
CPM_PCIE0_PF2_BAR2_QDMA_ENABLED 1 CPM_PCIE0_PF2_BAR2_QDMA_PREFETCHABLE 1\
CPM_PCIE0_PF2_BAR2_QDMA_SCALE Kilobytes CPM_PCIE0_PF2_BAR2_QDMA_SIZE 4\
CPM_PCIE0_PF2_BAR2_SCALE Kilobytes CPM_PCIE0_PF2_BAR2_SIZE 4\
CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_64BIT 1 CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_ENABLED 1\
CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_PREFETCHABLE 1\
CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SCALE Kilobytes\
CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SIZE 4 CPM_PCIE0_PF2_CLASS_CODE 0x058000\
CPM_PCIE0_PF2_MSIX_CAP_PBA_OFFSET 1400 CPM_PCIE0_PF2_MSIX_CAP_TABLE_OFFSET 2000\
CPM_PCIE0_PF2_MSI_ENABLED 0 CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_0\
0x0000020802000000 CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_2 0x0000021040002000\
CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_0 0x0000020806000000\
CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_2 0x0000021040006000\
CPM_PCIE0_PF2_SRIOV_BAR0_64BIT 0 CPM_PCIE0_PF2_SRIOV_BAR0_PREFETCHABLE 0\
CPM_PCIE0_PF2_SRIOV_BAR0_SIZE 128 CPM_PCIE0_PF2_SRIOV_BAR2_64BIT 1\
CPM_PCIE0_PF2_SRIOV_BAR2_ENABLED 1 CPM_PCIE0_PF2_SRIOV_BAR2_PREFETCHABLE 1\
CPM_PCIE0_PF2_SRIOV_BAR2_SCALE Kilobytes CPM_PCIE0_PF2_SRIOV_BAR2_SIZE 4\
CPM_PCIE0_PF2_SRIOV_CAP_ENABLE 0 CPM_PCIE0_PF2_SRIOV_CAP_INITIAL_VF 64\
CPM_PCIE0_PF2_SRIOV_FIRST_VF_OFFSET 130 CPM_PCIE0_PF2_SRIOV_SUPPORTED_PAGE_SIZE\
00000553 CPM_PCIE0_PF3_BAR0_QDMA_64BIT 0 CPM_PCIE0_PF3_BAR0_QDMA_PREFETCHABLE 0\
CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_64BIT 0 CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_SIZE 1\
CPM_PCIE0_PF3_BAR2_64BIT 1 CPM_PCIE0_PF3_BAR2_ENABLED 1\
CPM_PCIE0_PF3_BAR2_PREFETCHABLE 1 CPM_PCIE0_PF3_BAR2_QDMA_64BIT 1\
CPM_PCIE0_PF3_BAR2_QDMA_ENABLED 1 CPM_PCIE0_PF3_BAR2_QDMA_PREFETCHABLE 1\
CPM_PCIE0_PF3_BAR2_QDMA_SCALE Kilobytes CPM_PCIE0_PF3_BAR2_QDMA_SIZE 4\
CPM_PCIE0_PF3_BAR2_SCALE Kilobytes CPM_PCIE0_PF3_BAR2_SIZE 4\
CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_64BIT 1 CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_ENABLED 1\
CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SCALE Kilobytes\
CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SIZE 4 CPM_PCIE0_PF3_CLASS_CODE 0x058000\
CPM_PCIE0_PF3_MSIX_CAP_PBA_OFFSET 1400 CPM_PCIE0_PF3_MSIX_CAP_TABLE_OFFSET 2000\
CPM_PCIE0_PF3_MSI_ENABLED 0 CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_0\
0x0000020803000000 CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_2 0x0000021040003000\
CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_0 0x0000020807000000\
CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_2 0x0000021040007000\
CPM_PCIE0_PF3_SRIOV_BAR0_64BIT 0 CPM_PCIE0_PF3_SRIOV_BAR0_SIZE 128\
CPM_PCIE0_PF3_SRIOV_BAR2_64BIT 1 CPM_PCIE0_PF3_SRIOV_BAR2_ENABLED 1\
CPM_PCIE0_PF3_SRIOV_BAR2_SCALE Kilobytes CPM_PCIE0_PF3_SRIOV_BAR2_SIZE 4\
CPM_PCIE0_PF3_SRIOV_CAP_ENABLE 0 CPM_PCIE0_PF3_SRIOV_CAP_INITIAL_VF 60\
CPM_PCIE0_PF3_SRIOV_FIRST_VF_OFFSET 193 CPM_PCIE0_PF3_SRIOV_SUPPORTED_PAGE_SIZE\
00000553 CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH X8 CPM_PCIE0_SRIOV_CAP_ENABLE 1\
CPM_PCIE0_TL_PF_ENABLE_REG 4 CPM_PCIE0_USER_CLK2_FREQ 500_MHz\
CPM_PCIE0_USER_CLK_FREQ 250_MHz CPM_PCIE0_VFG0_MSIX_CAP_PBA_OFFSET 280\
CPM_PCIE0_VFG0_MSIX_CAP_TABLE_OFFSET 400 CPM_PCIE0_VFG0_MSIX_CAP_TABLE_SIZE 7\
CPM_PCIE0_VFG1_MSIX_CAP_PBA_OFFSET 280 CPM_PCIE0_VFG1_MSIX_CAP_TABLE_OFFSET 400\
CPM_PCIE0_VFG1_MSIX_CAP_TABLE_SIZE 7 CPM_PCIE0_VFG2_MSIX_CAP_PBA_OFFSET 280\
CPM_PCIE0_VFG2_MSIX_CAP_TABLE_OFFSET 400 CPM_PCIE0_VFG2_MSIX_CAP_TABLE_SIZE 7\
CPM_PCIE0_VFG3_MSIX_CAP_PBA_OFFSET 280 CPM_PCIE0_VFG3_MSIX_CAP_TABLE_OFFSET 400\
CPM_PCIE0_VFG3_MSIX_CAP_TABLE_SIZE 7 CPM_PCIE1_AXISTEN_IF_EXT_512_RQ_STRADDLE 0\
CPM_PCIE1_CORE_CLK_FREQ 250 CPM_PCIE1_MSI_X_OPTIONS MSI-X_External\
CPM_PCIE1_PF0_CLASS_CODE 0x058000 CPM_PCIE1_PF0_INTERFACE_VALUE 00\
CPM_PCIE1_PF1_VEND_ID 0 CPM_PCIE1_PF2_VEND_ID 0 CPM_PCIE1_PF3_VEND_ID 0\
CPM_PCIE1_VFG0_MSIX_CAP_TABLE_SIZE 1 CPM_PCIE1_VFG0_MSIX_ENABLED 0\
CPM_PCIE1_VFG1_MSIX_CAP_TABLE_SIZE 1 CPM_PCIE1_VFG1_MSIX_ENABLED 0\
CPM_PCIE1_VFG2_MSIX_CAP_TABLE_SIZE 1 CPM_PCIE1_VFG2_MSIX_ENABLED 0\
CPM_PCIE1_VFG3_MSIX_CAP_TABLE_SIZE 1 CPM_PCIE1_VFG3_MSIX_ENABLED 0\
CPM_PCIE_CHANNELS_FOR_POWER 1 CPM_PERIPHERAL_EN 1 CPM_XPIPE_0_CLKDLY_CFG\
268485632 CPM_XPIPE_0_INSTANTIATED 1 CPM_XPIPE_0_LINK0_CFG X8 CPM_XPIPE_0_MODE\
1 CPM_XPIPE_0_REG_CFG 8146 CPM_XPIPE_1_CLKDLY_CFG 33557632 CPM_XPIPE_1_CLK_CFG\
1048320 CPM_XPIPE_1_INSTANTIATED 1 CPM_XPIPE_1_LINK0_CFG X8 CPM_XPIPE_1_MODE 1\
CPM_XPIPE_1_REG_CFG 8137 CPM_XPIPE_2_CLKDLY_CFG 0 CPM_XPIPE_2_CLK_CFG 0\
CPM_XPIPE_2_INSTANTIATED 0 CPM_XPIPE_2_LINK0_CFG DISABLE CPM_XPIPE_2_MODE 0\
CPM_XPIPE_2_REG_CFG 0 CPM_XPIPE_3_CLKDLY_CFG 0 CPM_XPIPE_3_CLK_CFG 0\
CPM_XPIPE_3_INSTANTIATED 0 CPM_XPIPE_3_LINK0_CFG DISABLE CPM_XPIPE_3_MODE 0\
CPM_XPIPE_3_REG_CFG 0 PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ 824.991760\
PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ 825 PS_USE_PS_NOC_PCI_0 1 PS_USE_PS_NOC_PCI_1\
1}\
   CONFIG.DESIGN_MODE {1} \
   CONFIG.PS_PMC_CONFIG {DESIGN_MODE 1 PCIE_APERTURES_DUAL_ENABLE 0 PCIE_APERTURES_SINGLE_ENABLE 1\
PMC_CRP_HSM0_REF_CTRL_FREQMHZ 33.333 PMC_CRP_NOC_REF_CTRL_ACT_FREQMHZ\
999.989990 PMC_CRP_NOC_REF_CTRL_FREQMHZ 1000 PMC_CRP_NPLL_CTRL_FBDIV 120\
PMC_CRP_PL0_REF_CTRL_FREQMHZ 334 PMC_CRP_PL0_REF_CTRL_SRCSEL NPLL\
PMC_CRP_PL1_REF_CTRL_FREQMHZ 334 PMC_CRP_PL1_REF_CTRL_SRCSEL NPLL\
PMC_CRP_PL2_REF_CTRL_FREQMHZ 334 PMC_CRP_PL2_REF_CTRL_SRCSEL NPLL\
PMC_CRP_PL3_REF_CTRL_FREQMHZ 334 PMC_CRP_PL3_REF_CTRL_SRCSEL NPLL\
PMC_MIO_TREE_PERIPHERALS\
######################################PCIE#######################################\
PMC_MIO_TREE_SIGNALS\
######################################reset1_n#######################################\
PS_BOARD_INTERFACE Custom PS_CRF_ACPU_CTRL_ACT_FREQMHZ 1349.986450\
PS_CRF_ACPU_CTRL_FREQMHZ 1350 PS_CRF_APLL_CTRL_FBDIV 81\
PS_CRF_DBG_FPD_CTRL_ACT_FREQMHZ 299.997009 PS_CRF_DBG_FPD_CTRL_DIVISOR0 4\
PS_CRF_DBG_FPD_CTRL_FREQMHZ 300 PS_CRF_DBG_TRACE_CTRL_FREQMHZ 300\
PS_CRF_FPD_TOP_SWITCH_CTRL_ACT_FREQMHZ 824.991760\
PS_CRF_FPD_TOP_SWITCH_CTRL_DIVISOR0 1 PS_CRF_FPD_TOP_SWITCH_CTRL_FREQMHZ 825\
PS_CRF_FPD_TOP_SWITCH_CTRL_SRCSEL RPLL PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ\
824.991760 PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ 825 PS_CRL_CPU_R5_CTRL_ACT_FREQMHZ\
599.994019 PS_CRL_CPU_R5_CTRL_FREQMHZ 600 PS_CRL_CPU_R5_CTRL_SRCSEL PPLL\
PS_CRL_DBG_LPD_CTRL_ACT_FREQMHZ 299.997009 PS_CRL_DBG_LPD_CTRL_DIVISOR0 4\
PS_CRL_DBG_LPD_CTRL_FREQMHZ 300 PS_CRL_DBG_TSTMP_CTRL_ACT_FREQMHZ 299.997009\
PS_CRL_DBG_TSTMP_CTRL_DIVISOR0 4 PS_CRL_DBG_TSTMP_CTRL_FREQMHZ 300\
PS_CRL_GEM0_REF_CTRL_DIVISOR0 4 PS_CRL_GEM0_REF_CTRL_SRCSEL NPLL\
PS_CRL_GEM1_REF_CTRL_DIVISOR0 4 PS_CRL_GEM1_REF_CTRL_SRCSEL NPLL\
PS_CRL_GEM_TSU_REF_CTRL_DIVISOR0 2 PS_CRL_GEM_TSU_REF_CTRL_SRCSEL NPLL\
PS_CRL_IOU_SWITCH_CTRL_ACT_FREQMHZ 249.997498 PS_CRL_IOU_SWITCH_CTRL_DIVISOR0 4\
PS_CRL_IOU_SWITCH_CTRL_SRCSEL NPLL PS_CRL_LPD_TOP_SWITCH_CTRL_ACT_FREQMHZ\
599.994019 PS_CRL_LPD_TOP_SWITCH_CTRL_FREQMHZ 600\
PS_CRL_LPD_TOP_SWITCH_CTRL_SRCSEL PPLL PS_CRL_RPLL_CTRL_FBDIV 99\
PS_CRL_USB3_DUAL_REF_CTRL_FREQMHZ 100 PS_PCIE1_PERIPHERAL_ENABLE 1\
PS_PCIE2_PERIPHERAL_ENABLE 0 PS_PCIE_EP_RESET1_IO {PMC_MIO 38} PS_PCIE_RESET\
{{ENABLE 1} {IO {PS_MIO 18 .. 19}}} PS_USE_PS_NOC_PCI_0 1 PS_USE_PS_NOC_PCI_1 1\
SMON_ALARMS Set_Alarms_On SMON_ENABLE_TEMP_AVERAGING 0 SMON_MEAS33\
{{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE\
0} {MODE {2 V unipolar}} {NAME VCCAUX}} SMON_MEAS34 {{ALARM_ENABLE 0}\
{ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V\
unipolar}} {NAME VCCAUX_PMC}} SMON_MEAS35 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00}\
{ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME\
VCCAUX_SMON}} SMON_MEAS36 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER\
2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCINT}}\
SMON_MEAS37 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_306}} SMON_MEAS38 {{ALARM_ENABLE\
0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V\
unipolar}} {NAME VCCO_406}} SMON_MEAS39 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00}\
{ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME\
VCCO_500}} SMON_MEAS40 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00}\
{AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_501}} SMON_MEAS41\
{{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE\
0} {MODE {4 V unipolar}} {NAME VCCO_502}} SMON_MEAS42 {{ALARM_ENABLE 0}\
{ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V\
unipolar}} {NAME VCCO_503}} SMON_MEAS43 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00}\
{ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME\
VCCO_700}} SMON_MEAS44 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00}\
{AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_701}} SMON_MEAS45\
{{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE\
0} {MODE {2 V unipolar}} {NAME VCCO_702}} SMON_MEAS46 {{ALARM_ENABLE 0}\
{ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V\
unipolar}} {NAME VCCO_703}} SMON_MEAS47 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00}\
{ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME\
VCCO_704}} SMON_MEAS48 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00}\
{AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_705}} SMON_MEAS49\
{{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE\
0} {MODE {2 V unipolar}} {NAME VCCO_706}} SMON_MEAS50 {{ALARM_ENABLE 0}\
{ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V\
unipolar}} {NAME VCCO_707}} SMON_MEAS51 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00}\
{ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME\
VCCO_708}} SMON_MEAS52 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00}\
{AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_709}} SMON_MEAS53\
{{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE\
0} {MODE {2 V unipolar}} {NAME VCCO_710}} SMON_MEAS54 {{ALARM_ENABLE 0}\
{ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V\
unipolar}} {NAME VCCO_711}} SMON_MEAS55 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00}\
{ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME\
VCC_BATT}} SMON_MEAS56 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00}\
{AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PMC}} SMON_MEAS57\
{{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE\
0} {MODE {2 V unipolar}} {NAME VCC_PSFP}} SMON_MEAS58 {{ALARM_ENABLE 0}\
{ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V\
unipolar}} {NAME VCC_PSLP}} SMON_MEAS59 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00}\
{ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME\
VCC_RAM}} SMON_MEAS60 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00}\
{AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_SOC}} SMON_MEAS61\
{{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE\
0} {MODE {2 V unipolar}} {NAME VP_VN}} SMON_MEAS62 {{ALARM_ENABLE 0}\
{ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None}\
{NAME VCC_PMC}} SMON_MEAS63 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER\
2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME VCC_PSFP}} SMON_MEAS64\
{{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE\
0} {MODE None} {NAME VCC_PSLP}} SMON_MEAS65 {{ALARM_ENABLE 0} {ALARM_LOWER\
0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME VCC_RAM}}\
SMON_MEAS66 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE None} {NAME VCC_SOC}} SMON_MEAS67 {{ALARM_ENABLE 0}\
{ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None}\
{NAME VP_VN}} SMON_MEASUREMENT_COUNT 62 SMON_MEASUREMENT_LIST\
BANK_VOLTAGE:GTY_AVTT-GTY_AVTT_103,GTY_AVTT_104,GTY_AVTT_105,GTY_AVTT_106,GTY_AVTT_200,GTY_AVTT_201,GTY_AVTT_202,GTY_AVTT_203,GTY_AVTT_204,GTY_AVTT_205,GTY_AVTT_206#VCC-GTY_AVCC_103,GTY_AVCC_104,GTY_AVCC_105,GTY_AVCC_106,GTY_AVCC_200,GTY_AVCC_201,GTY_AVCC_202,GTY_AVCC_203,GTY_AVCC_204,GTY_AVCC_205,GTY_AVCC_206#VCCAUX-GTY_AVCCAUX_103,GTY_AVCCAUX_104,GTY_AVCCAUX_105,GTY_AVCCAUX_106,GTY_AVCCAUX_200,GTY_AVCCAUX_201,GTY_AVCCAUX_202,GTY_AVCCAUX_203,GTY_AVCCAUX_204,GTY_AVCCAUX_205,GTY_AVCCAUX_206#VCCO-VCCO_306,VCCO_406,VCCO_500,VCCO_501,VCCO_502,VCCO_503,VCCO_700,VCCO_701,VCCO_702,VCCO_703,VCCO_704,VCCO_705,VCCO_706,VCCO_707,VCCO_708,VCCO_709,VCCO_710,VCCO_711|DEDICATED_PAD:VP-VP_VN|SUPPLY_VOLTAGE:VCC-VCC_BATT,VCC_PMC,VCC_PSFP,VCC_PSLP,VCC_RAM,VCC_SOC#VCCAUX-VCCAUX,VCCAUX_PMC,VCCAUX_SMON#VCCINT-VCCINT\
SMON_TEMP_AVERAGING_SAMPLES 8}\
   CONFIG.PS_PMC_CONFIG_APPLIED {1} \
 ] $versal_cips_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins smartconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M02_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_noc_0/M02_AXI]
  connect_bd_intf_net -intf_net dma0_c2h_byp_in_mm_0_1 [get_bd_intf_ports dma0_c2h_byp_in_mm_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_in_mm]
  connect_bd_intf_net -intf_net dma0_c2h_byp_in_st_csh_0_1 [get_bd_intf_ports dma0_c2h_byp_in_st_csh_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_in_st_csh]
  connect_bd_intf_net -intf_net dma0_c2h_byp_in_st_sim_0_1 [get_bd_intf_ports dma0_c2h_byp_in_st_sim_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_in_st_sim]
  connect_bd_intf_net -intf_net dma0_dsc_crdt_in_0_1 [get_bd_intf_ports dma0_dsc_crdt_in_0] [get_bd_intf_pins versal_cips_0/dma0_dsc_crdt_in]
  connect_bd_intf_net -intf_net dma0_h2c_byp_in_mm_0_1 [get_bd_intf_ports dma0_h2c_byp_in_mm_0] [get_bd_intf_pins versal_cips_0/dma0_h2c_byp_in_mm]
  connect_bd_intf_net -intf_net dma0_h2c_byp_in_st_0_1 [get_bd_intf_ports dma0_h2c_byp_in_st_0] [get_bd_intf_pins versal_cips_0/dma0_h2c_byp_in_st]
  connect_bd_intf_net -intf_net dma0_s_axis_c2h_0_1 [get_bd_intf_ports dma0_s_axis_c2h_0] [get_bd_intf_pins versal_cips_0/dma0_s_axis_c2h]
  connect_bd_intf_net -intf_net dma0_s_axis_c2h_cmpt_0_1 [get_bd_intf_ports dma0_s_axis_c2h_cmpt_0] [get_bd_intf_pins versal_cips_0/dma0_s_axis_c2h_cmpt]
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins versal_cips_0/gt_refclk0]
  connect_bd_intf_net -intf_net pcie_qdma_mailbox_0_dma_flr [get_bd_intf_pins pcie_qdma_mailbox_0/dma_flr] [get_bd_intf_pins versal_cips_0/dma0_usr_flr]
  connect_bd_intf_net -intf_net pcie_qdma_mailbox_0_dma_usr_irq [get_bd_intf_pins pcie_qdma_mailbox_0/dma_usr_irq] [get_bd_intf_pins versal_cips_0/dma0_usr_irq]
  connect_bd_intf_net -intf_net pcie_qdma_mailbox_0_pcie_mgmt [get_bd_intf_pins pcie_qdma_mailbox_0/pcie_mgmt] [get_bd_intf_pins versal_cips_0/dma0_mgmt]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_ports M00_AXI_0] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M00_AXI [get_bd_intf_pins pcie_qdma_mailbox_0/S_AXI_LITE] [get_bd_intf_pins smartconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net usr_flr_0_1 [get_bd_intf_ports usr_flr_0] [get_bd_intf_pins pcie_qdma_mailbox_0/usr_flr]
  connect_bd_intf_net -intf_net usr_irq_0_1 [get_bd_intf_ports usr_irq_0] [get_bd_intf_pins pcie_qdma_mailbox_0/usr_irq]
  connect_bd_intf_net -intf_net versal_cips_0_CPM_PCIE_NOC_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_CPM_PCIE_NOC_1 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_PCIE0_GT [get_bd_intf_ports PCIE0_GT_0] [get_bd_intf_pins versal_cips_0/PCIE0_GT]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_axis_c2h_status [get_bd_intf_ports dma0_axis_c2h_status_0] [get_bd_intf_pins versal_cips_0/dma0_axis_c2h_status]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_c2h_byp_out [get_bd_intf_ports dma0_c2h_byp_out_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_out]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_h2c_byp_out [get_bd_intf_ports dma0_h2c_byp_out_0] [get_bd_intf_pins versal_cips_0/dma0_h2c_byp_out]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_m_axis_h2c [get_bd_intf_ports dma0_m_axis_h2c_0] [get_bd_intf_pins versal_cips_0/dma0_m_axis_h2c]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_st_rx_msg [get_bd_intf_ports dma0_st_rx_msg_0] [get_bd_intf_pins versal_cips_0/dma0_st_rx_msg]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_tm_dsc_sts [get_bd_intf_ports dma0_tm_dsc_sts_0] [get_bd_intf_pins versal_cips_0/dma0_tm_dsc_sts]

  # Create port connections
  connect_bd_net -net dma0_soft_resetn_0_1 [get_bd_ports dma0_soft_resetn_0] [get_bd_pins versal_cips_0/dma0_soft_resetn]
  connect_bd_net -net versal_cips_0_cpm_pcie_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_cpm_pcie_noc_axi1_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_dma0_axi_aresetn [get_bd_ports dma0_axi_aresetn_0] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins pcie_qdma_mailbox_0/axi_aresetn] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins smartconnect_1/aresetn] [get_bd_pins versal_cips_0/dma0_axi_aresetn]
  connect_bd_net -net versal_cips_0_pcie0_user_clk [get_bd_ports pcie0_user_clk_0] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_noc_0/aclk2] [get_bd_pins pcie_qdma_mailbox_0/axi_aclk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins smartconnect_1/aclk] [get_bd_pins versal_cips_0/pcie0_user_clk]
  connect_bd_net -net versal_cips_0_pcie0_user_lnk_up [get_bd_ports pcie0_user_lnk_up_0] [get_bd_pins versal_cips_0/pcie0_user_lnk_up]

  # Create address segments
  assign_bd_address -offset 0x021040000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs M00_AXI_0/Reg] -force
  assign_bd_address -offset 0x021040000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs M00_AXI_0/Reg] -force
  assign_bd_address -offset 0x020100000000 -range 0x00080000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020100000000 -range 0x00080000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020800000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs pcie_qdma_mailbox_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x020800000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs pcie_qdma_mailbox_0/S_AXI_LITE/Reg] -force


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
set_property synth_checkpoint_mode None [get_files ${design_name}.bd]

# Add files
add_files -fileset sources_1 exdes
add_files -fileset sim_1 sim_files
add_files -fileset constrs_1 top_impl.xdc

# Set top module for simulation
set_property top board [get_filesets sim_1]

update_compile_order -fileset sim_1
update_compile_order -fileset sources_1
