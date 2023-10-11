
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
#set scripts_vivado_version 2023.1
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
   create_project project_1 myproj -part xcvp1202-vsva2785-2MP-e-S
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
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:axi_noc:*\
xilinx.com:ip:emb_mem_gen:*\
xilinx.com:ip:pcie_qdma_mailbox:*\
xilinx.com:ip:smartconnect:*\
xilinx.com:ip:versal_cips:*\
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
  set PCIE1_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE1_GT_0 ]

  set S_AXIL [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXIL ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {15} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
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
   ] $S_AXIL

  set dma1_axis_c2h_dmawr_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_eqdma:axis_c2h_dmawr_rtl:1.0 dma1_axis_c2h_dmawr_0 ]

  set dma1_axis_c2h_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_c2h_status_rtl:1.0 dma1_axis_c2h_status_0 ]

  set dma1_dsc_crdt_in_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_crdt_in_rtl:1.0 dma1_dsc_crdt_in_0 ]

  set dma1_m_axis_h2c_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_eqdma:m_axis_h2c_rtl:1.0 dma1_m_axis_h2c_0 ]

  set dma1_qsts_out_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:eqdma_qsts_rtl:1.0 dma1_qsts_out_0 ]

  set dma1_s_axis_c2h_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:s_axis_c2h_rtl:1.0 dma1_s_axis_c2h_0 ]

  set dma1_s_axis_c2h_cmpt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:s_axis_c2h_cmpt_rtl:1.0 dma1_s_axis_c2h_cmpt_0 ]

  set dma1_st_rx_msg_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 dma1_st_rx_msg_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {249997498} \
   ] $dma1_st_rx_msg_0

  set dma1_tm_dsc_sts_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_tm_dsc_sts_rtl:1.0 dma1_tm_dsc_sts_0 ]

  set gt_refclk1_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk1_0 ]

  set usr_flr_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:usr_flr_rtl:1.0 usr_flr_0 ]

  set usr_irq_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_usr_irq_rtl:1.0 usr_irq_0 ]

  set M_AXIL [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXIL ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {42} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.NUM_READ_OUTSTANDING {32} \
   CONFIG.NUM_WRITE_OUTSTANDING {32} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $M_AXIL


  # Create ports
  set cpm_cor_irq_0 [ create_bd_port -dir O -type intr cpm_cor_irq_0 ]
  set cpm_irq0_0 [ create_bd_port -dir I -type intr cpm_irq0_0 ]
  set cpm_irq1_0 [ create_bd_port -dir I -type intr cpm_irq1_0 ]
  set cpm_misc_irq_0 [ create_bd_port -dir O -type intr cpm_misc_irq_0 ]
  set cpm_uncor_irq_0 [ create_bd_port -dir O -type intr cpm_uncor_irq_0 ]
  set dma1_axi_aresetn_0 [ create_bd_port -dir O -type rst dma1_axi_aresetn_0 ]
  set dma1_intrfc_resetn_0 [ create_bd_port -dir I -type rst dma1_intrfc_resetn_0 ]
  set pcie1_user_clk_0 [ create_bd_port -dir O -type clk pcie1_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S_AXIL:M_AXIL} \
 ] $pcie1_user_clk_0

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.PROTOCOL {AXI4LITE} \
    CONFIG.READ_LATENCY {2} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_0


  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc axi_noc_0 ]
  set_property -dict [list \
    CONFIG.CONTROLLERTYPE {LPDDR4_SDRAM} \
    CONFIG.MC0_CONFIG_NUM {config26} \
    CONFIG.MC0_FLIPPED_PINOUT {true} \
    CONFIG.MC1_CONFIG_NUM {config26} \
    CONFIG.MC2_CONFIG_NUM {config26} \
    CONFIG.MC3_CONFIG_NUM {config26} \
    CONFIG.MC_ADDR_WIDTH {6} \
    CONFIG.MC_BURST_LENGTH {16} \
    CONFIG.MC_CASLATENCY {28} \
    CONFIG.MC_CASWRITELATENCY {14} \
    CONFIG.MC_CH1_LP4_CHB_ENABLE {true} \
    CONFIG.MC_COMPONENT_DENSITY {16Gb} \
    CONFIG.MC_COMPONENT_WIDTH {x32} \
    CONFIG.MC_CONFIG_NUM {config26} \
    CONFIG.MC_DATAWIDTH {32} \
    CONFIG.MC_DM_WIDTH {4} \
    CONFIG.MC_DQS_WIDTH {4} \
    CONFIG.MC_DQ_WIDTH {32} \
    CONFIG.MC_ECC {false} \
    CONFIG.MC_ECC_SCRUB_SIZE {4096} \
    CONFIG.MC_F1_CASLATENCY {28} \
    CONFIG.MC_F1_CASWRITELATENCY {14} \
    CONFIG.MC_F1_LPDDR4_MR1 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR11 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR13 {0x00C0} \
    CONFIG.MC_F1_LPDDR4_MR2 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR22 {0x0000} \
    CONFIG.MC_F1_LPDDR4_MR3 {0x0000} \
    CONFIG.MC_F1_TCCD_L {0} \
    CONFIG.MC_F1_TCCD_L_MIN {0} \
    CONFIG.MC_F1_TFAW {40000} \
    CONFIG.MC_F1_TFAWMIN {40000} \
    CONFIG.MC_F1_TMOD {0} \
    CONFIG.MC_F1_TMOD_MIN {0} \
    CONFIG.MC_F1_TMRD {14000} \
    CONFIG.MC_F1_TMRDMIN {14000} \
    CONFIG.MC_F1_TMRW {10000} \
    CONFIG.MC_F1_TMRWMIN {10000} \
    CONFIG.MC_F1_TRAS {42000} \
    CONFIG.MC_F1_TRASMIN {42000} \
    CONFIG.MC_F1_TRCD {18000} \
    CONFIG.MC_F1_TRCDMIN {18000} \
    CONFIG.MC_F1_TRPAB {21000} \
    CONFIG.MC_F1_TRPABMIN {21000} \
    CONFIG.MC_F1_TRPPB {18000} \
    CONFIG.MC_F1_TRPPBMIN {18000} \
    CONFIG.MC_F1_TRRD {10000} \
    CONFIG.MC_F1_TRRDMIN {10000} \
    CONFIG.MC_F1_TRRD_L {0} \
    CONFIG.MC_F1_TRRD_L_MIN {0} \
    CONFIG.MC_F1_TRRD_S {0} \
    CONFIG.MC_F1_TRRD_S_MIN {0} \
    CONFIG.MC_F1_TWR {18000} \
    CONFIG.MC_F1_TWRMIN {18000} \
    CONFIG.MC_F1_TWTR {10000} \
    CONFIG.MC_F1_TWTRMIN {10000} \
    CONFIG.MC_F1_TWTR_L {0} \
    CONFIG.MC_F1_TWTR_L_MIN {0} \
    CONFIG.MC_F1_TWTR_S {0} \
    CONFIG.MC_F1_TWTR_S_MIN {0} \
    CONFIG.MC_F1_TZQLAT {30000} \
    CONFIG.MC_F1_TZQLATMIN {30000} \
    CONFIG.MC_INPUTCLK0_PERIOD {5000} \
    CONFIG.MC_LP4_RESETN_WIDTH {1} \
    CONFIG.MC_MEMORY_SPEEDGRADE {LPDDR4-3200} \
    CONFIG.MC_MEMORY_TIMEPERIOD0 {625} \
    CONFIG.MC_NO_CHANNELS {Dual} \
    CONFIG.MC_ODTLon {6} \
    CONFIG.MC_PER_RD_INTVL {0} \
    CONFIG.MC_PRE_DEF_ADDR_MAP_SEL {ROW_BANK_COLUMN} \
    CONFIG.MC_TCCD_L {0} \
    CONFIG.MC_TCKE {12} \
    CONFIG.MC_TCKEMIN {12} \
    CONFIG.MC_TFAW {40000} \
    CONFIG.MC_TFAWMIN {40000} \
    CONFIG.MC_TMOD {0} \
    CONFIG.MC_TMRD {14000} \
    CONFIG.MC_TMRDMIN {14000} \
    CONFIG.MC_TMRD_div4 {10} \
    CONFIG.MC_TMRW {10000} \
    CONFIG.MC_TMRW_div4 {10} \
    CONFIG.MC_TODTon_MIN {3} \
    CONFIG.MC_TOSCO {40000} \
    CONFIG.MC_TPBR2PBR {90000} \
    CONFIG.MC_TRAS {42000} \
    CONFIG.MC_TRC {63000} \
    CONFIG.MC_TRCD {18000} \
    CONFIG.MC_TREFI {3904000} \
    CONFIG.MC_TREFIPB {488000} \
    CONFIG.MC_TRFC {0} \
    CONFIG.MC_TRFCAB {280000} \
    CONFIG.MC_TRFCMIN {0} \
    CONFIG.MC_TRFCPB {140000} \
    CONFIG.MC_TRFCPBMIN {140000} \
    CONFIG.MC_TRP {0} \
    CONFIG.MC_TRPAB {21000} \
    CONFIG.MC_TRPMIN {0} \
    CONFIG.MC_TRPPB {18000} \
    CONFIG.MC_TRPRE {1.8} \
    CONFIG.MC_TRRD {10000} \
    CONFIG.MC_TRRD_L {0} \
    CONFIG.MC_TRRD_S {0} \
    CONFIG.MC_TRRD_S_MIN {0} \
    CONFIG.MC_TWPRE {1.8} \
    CONFIG.MC_TWPST {0.4} \
    CONFIG.MC_TWR {18000} \
    CONFIG.MC_TWTR {10000} \
    CONFIG.MC_TWTR_L {0} \
    CONFIG.MC_TWTR_S {0} \
    CONFIG.MC_TWTR_S_MIN {0} \
    CONFIG.MC_TXP {12} \
    CONFIG.MC_TXPMIN {12} \
    CONFIG.MC_TXPR {0} \
    CONFIG.MC_TZQCAL {1000000} \
    CONFIG.MC_TZQCAL_div4 {400} \
    CONFIG.MC_TZQCS_ITVL {0} \
    CONFIG.MC_TZQLAT {30000} \
    CONFIG.MC_TZQLATMIN {30000} \
    CONFIG.MC_TZQLAT_div4 {12} \
    CONFIG.MC_TZQLAT_nCK {48} \
    CONFIG.MC_TZQ_START_ITVL {1000000000} \
    CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-3BA-10CA} \
    CONFIG.MC_XPLL_CLKOUT1_PERIOD {1250} \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MC {0} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {1} \
  ] $axi_noc_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x208_0000_0000 2G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.APERTURES {{0x201_8000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {1720} write_bw {1720}}} \
   CONFIG.DEST_IDS {M01_AXI:0x0:M00_AXI:0x40} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  # Create instance: emb_mem_gen_0, and set properties
  set emb_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen emb_mem_gen_0 ]

  # Create instance: pcie_qdma_mailbox_0, and set properties
  set pcie_qdma_mailbox_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_qdma_mailbox pcie_qdma_mailbox_0 ]
  set_property -dict [list \
    CONFIG.num_pfs {4} \
    CONFIG.num_vfs_pf0 {64} \
    CONFIG.num_vfs_pf1 {64} \
    CONFIG.num_vfs_pf2 {64} \
    CONFIG.num_vfs_pf3 {48} \
  ] $pcie_qdma_mailbox_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [list \
    CONFIG.BOOT_MODE {Custom} \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.CPM_CONFIG { \
      CPM_PCIE0_MODES {None} \
      CPM_PCIE1_ACS_CAP_ON {1} \
      CPM_PCIE1_COPY_PF0_QDMA_ENABLED {0} \
      CPM_PCIE1_COPY_PF0_SRIOV_QDMA_ENABLED {0} \
      CPM_PCIE1_DMA_INTF {AXI4S} \
      CPM_PCIE1_FUNCTIONAL_MODE {QDMA} \
      CPM_PCIE1_MAILBOX_ENABLE {1} \
      CPM_PCIE1_MAX_LINK_SPEED {16.0_GT/s} \
      CPM_PCIE1_MODES {DMA} \
      CPM_PCIE1_MODE_SELECTION {Advanced} \
      CPM_PCIE1_PF0_BAR0_QDMA_64BIT {1} \
      CPM_PCIE1_PF0_BAR0_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF0_BAR0_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR0_QDMA_SIZE {512} \
      CPM_PCIE1_PF0_BAR0_QDMA_TYPE {DMA} \
      CPM_PCIE1_PF0_BAR0_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE1_PF0_BAR0_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE1_PF0_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF0_BAR0_SRIOV_QDMA_TYPE {DMA} \
      CPM_PCIE1_PF0_BAR2_QDMA_64BIT {1} \
      CPM_PCIE1_PF0_BAR2_QDMA_ENABLED {1} \
      CPM_PCIE1_PF0_BAR2_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF0_BAR2_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR2_QDMA_SIZE {4} \
      CPM_PCIE1_PF0_BAR2_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE1_PF0_BAR2_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE1_PF0_BAR2_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF0_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF0_BAR2_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE1_PF0_CFG_DEV_ID {B058} \
      CPM_PCIE1_PF0_DEV_CAP_10B_TAG_EN {1} \
      CPM_PCIE1_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {1} \
      CPM_PCIE1_PF0_PCIEBAR2AXIBAR_QDMA_0 {0x0000020800000000} \
      CPM_PCIE1_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x0000020180000000} \
      CPM_PCIE1_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020804000000} \
      CPM_PCIE1_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000020180004000} \
      CPM_PCIE1_PF0_SRIOV_CAP_INITIAL_VF {64} \
      CPM_PCIE1_PF0_SRIOV_VF_DEVICE_ID {C058} \
      CPM_PCIE1_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE1_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE1_PF1_BAR0_QDMA_64BIT {1} \
      CPM_PCIE1_PF1_BAR0_QDMA_ENABLED {1} \
      CPM_PCIE1_PF1_BAR0_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF1_BAR0_QDMA_TYPE {DMA} \
      CPM_PCIE1_PF1_BAR0_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE1_PF1_BAR0_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE1_PF1_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF1_BAR0_SRIOV_QDMA_TYPE {DMA} \
      CPM_PCIE1_PF1_BAR2_QDMA_64BIT {1} \
      CPM_PCIE1_PF1_BAR2_QDMA_ENABLED {1} \
      CPM_PCIE1_PF1_BAR2_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF1_BAR2_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_BAR2_QDMA_SIZE {4} \
      CPM_PCIE1_PF1_BAR2_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE1_PF1_BAR2_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE1_PF1_BAR2_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF1_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF1_BAR2_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE1_PF1_CFG_DEV_ID {B158} \
      CPM_PCIE1_PF1_PCIEBAR2AXIBAR_QDMA_0 {0x0000020801000000} \
      CPM_PCIE1_PF1_PCIEBAR2AXIBAR_QDMA_2 {0x0000020180001000} \
      CPM_PCIE1_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020805000000} \
      CPM_PCIE1_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000020180005000} \
      CPM_PCIE1_PF1_SRIOV_CAP_INITIAL_VF {64} \
      CPM_PCIE1_PF1_SRIOV_VF_DEVICE_ID {C158} \
      CPM_PCIE1_PF1_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE1_PF1_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE1_PF2_BAR0_QDMA_64BIT {1} \
      CPM_PCIE1_PF2_BAR0_QDMA_ENABLED {1} \
      CPM_PCIE1_PF2_BAR0_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF2_BAR0_QDMA_TYPE {DMA} \
      CPM_PCIE1_PF2_BAR0_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE1_PF2_BAR0_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE1_PF2_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF2_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_BAR0_SRIOV_QDMA_SIZE {32} \
      CPM_PCIE1_PF2_BAR0_SRIOV_QDMA_TYPE {DMA} \
      CPM_PCIE1_PF2_BAR2_QDMA_64BIT {1} \
      CPM_PCIE1_PF2_BAR2_QDMA_ENABLED {1} \
      CPM_PCIE1_PF2_BAR2_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF2_BAR2_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_BAR2_QDMA_SIZE {4} \
      CPM_PCIE1_PF2_BAR2_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE1_PF2_BAR2_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE1_PF2_BAR2_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF2_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF2_BAR2_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE1_PF2_CFG_DEV_ID {B258} \
      CPM_PCIE1_PF2_PCIEBAR2AXIBAR_QDMA_0 {0x0000020802000000} \
      CPM_PCIE1_PF2_PCIEBAR2AXIBAR_QDMA_2 {0x0000020180002000} \
      CPM_PCIE1_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020806000000} \
      CPM_PCIE1_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000020180006000} \
      CPM_PCIE1_PF2_SRIOV_CAP_INITIAL_VF {64} \
      CPM_PCIE1_PF2_SRIOV_VF_DEVICE_ID {C258} \
      CPM_PCIE1_PF2_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE1_PF2_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE1_PF3_BAR0_QDMA_64BIT {1} \
      CPM_PCIE1_PF3_BAR0_QDMA_ENABLED {1} \
      CPM_PCIE1_PF3_BAR0_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF3_BAR0_QDMA_TYPE {DMA} \
      CPM_PCIE1_PF3_BAR0_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE1_PF3_BAR0_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE1_PF3_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF3_BAR0_SRIOV_QDMA_SIZE {32} \
      CPM_PCIE1_PF3_BAR0_SRIOV_QDMA_TYPE {DMA} \
      CPM_PCIE1_PF3_BAR2_QDMA_64BIT {1} \
      CPM_PCIE1_PF3_BAR2_QDMA_ENABLED {1} \
      CPM_PCIE1_PF3_BAR2_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF3_BAR2_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_BAR2_QDMA_SIZE {4} \
      CPM_PCIE1_PF3_BAR2_SRIOV_QDMA_64BIT {1} \
      CPM_PCIE1_PF3_BAR2_SRIOV_QDMA_ENABLED {1} \
      CPM_PCIE1_PF3_BAR2_SRIOV_QDMA_PREFETCHABLE {1} \
      CPM_PCIE1_PF3_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
      CPM_PCIE1_PF3_BAR2_SRIOV_QDMA_SIZE {4} \
      CPM_PCIE1_PF3_CFG_DEV_ID {B358} \
      CPM_PCIE1_PF3_PCIEBAR2AXIBAR_QDMA_0 {0x0000020803000000} \
      CPM_PCIE1_PF3_PCIEBAR2AXIBAR_QDMA_2 {0x0000020180003000} \
      CPM_PCIE1_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020807000000} \
      CPM_PCIE1_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000020180007000} \
      CPM_PCIE1_PF3_SRIOV_CAP_INITIAL_VF {48} \
      CPM_PCIE1_PF3_SRIOV_VF_DEVICE_ID {C358} \
      CPM_PCIE1_PF3_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE1_PF3_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE1_PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
      CPM_PCIE1_SRIOV_CAP_ENABLE {1} \
      CPM_PCIE1_TL_PF_ENABLE_REG {4} \
      CPM_PCIE1_VFG0_MSIX_CAP_PBA_BIR {BAR_1:0} \
      CPM_PCIE1_VFG0_MSIX_CAP_TABLE_BIR {BAR_1:0} \
      CPM_PCIE1_VFG1_MSIX_CAP_PBA_BIR {BAR_1:0} \
      CPM_PCIE1_VFG1_MSIX_CAP_TABLE_BIR {BAR_1:0} \
      CPM_PCIE1_VFG2_MSIX_CAP_PBA_BIR {BAR_1:0} \
      CPM_PCIE1_VFG2_MSIX_CAP_TABLE_BIR {BAR_1:0} \
      CPM_PCIE1_VFG3_MSIX_CAP_PBA_BIR {BAR_1:0} \
      CPM_PCIE1_VFG3_MSIX_CAP_TABLE_BIR {BAR_1:0} \
      CPM_PL_AXI0_EN {0} \
      CPM_PL_AXI1_EN {0} \
      PS_USE_PS_NOC_PCI_1 {0} \
    } \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.PS_PMC_CONFIG { \
      BOOT_MODE {Custom} \
      CLOCK_MODE {Custom} \
      DESIGN_MODE {1} \
      PCIE_APERTURES_DUAL_ENABLE {0} \
      PCIE_APERTURES_SINGLE_ENABLE {1} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {250} \
      PMC_QSPI_FBCLK {{ENABLE 0} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PS_BOARD_INTERFACE {Custom} \
      PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {825} \
      PS_PCIE1_PERIPHERAL_ENABLE {0} \
      PS_PCIE2_PERIPHERAL_ENABLE {1} \
      PS_PCIE_EP_RESET1_IO {None} \
      PS_USE_PMCPL_CLK0 {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
    CONFIG.PS_PMC_CONFIG_APPLIED {1} \
  ] $versal_cips_0

set board_part [get_property NAME [current_board_part]]
if [regexp "vpk120_es:part0:1.3" $board_part] {
set_property CONFIG.PS_PMC_CONFIG { PS_PCIE_EP_RESET2_IO {PMC_MIO 39} PS_PCIE_RESET {{ENABLE 1}} } [get_bd_cells versal_cips_0]
} else {
set_property CONFIG.PS_PMC_CONFIG { PS_PCIE_EP_RESET2_IO {PS_MIO 19} PS_PCIE_RESET {{ENABLE 1}} } [get_bd_cells versal_cips_0]}

 

  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_1 ]
  set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_1


  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIL_1 [get_bd_intf_ports S_AXIL] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins emb_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins smartconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net dma1_dsc_crdt_in_0_1 [get_bd_intf_ports dma1_dsc_crdt_in_0] [get_bd_intf_pins versal_cips_0/dma1_dsc_crdt_in]
  connect_bd_intf_net -intf_net dma1_s_axis_c2h_0_1 [get_bd_intf_ports dma1_s_axis_c2h_0] [get_bd_intf_pins versal_cips_0/dma1_s_axis_c2h]
  connect_bd_intf_net -intf_net dma1_s_axis_c2h_cmpt_0_1 [get_bd_intf_ports dma1_s_axis_c2h_cmpt_0] [get_bd_intf_pins versal_cips_0/dma1_s_axis_c2h_cmpt]
  connect_bd_intf_net -intf_net gt_refclk0_1_0 [get_bd_intf_ports gt_refclk1_0] [get_bd_intf_pins versal_cips_0/gt_refclk1]
  connect_bd_intf_net -intf_net pcie_qdma_mailbox_0_dma_flr [get_bd_intf_pins pcie_qdma_mailbox_0/dma_flr] [get_bd_intf_pins versal_cips_0/dma1_usr_flr]
  connect_bd_intf_net -intf_net pcie_qdma_mailbox_0_dma_usr_irq [get_bd_intf_pins pcie_qdma_mailbox_0/dma_usr_irq] [get_bd_intf_pins versal_cips_0/dma1_usr_irq]
  connect_bd_intf_net -intf_net pcie_qdma_mailbox_0_pcie_mgmt [get_bd_intf_pins pcie_qdma_mailbox_0/pcie_mgmt] [get_bd_intf_pins versal_cips_0/dma1_mgmt]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins pcie_qdma_mailbox_0/S_AXI_LITE] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_2_M00_AXI [get_bd_intf_ports M_AXIL] [get_bd_intf_pins smartconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net usr_flr_0_1 [get_bd_intf_ports usr_flr_0] [get_bd_intf_pins pcie_qdma_mailbox_0/usr_flr]
  connect_bd_intf_net -intf_net usr_irq_0_1 [get_bd_intf_ports usr_irq_0] [get_bd_intf_pins pcie_qdma_mailbox_0/usr_irq]
  connect_bd_intf_net -intf_net versal_cips_0_CPM_PCIE_NOC_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_PCIE0_GT [get_bd_intf_ports PCIE1_GT_0] [get_bd_intf_pins versal_cips_0/PCIE1_GT]
  connect_bd_intf_net -intf_net versal_cips_0_dma1_axis_c2h_dmawr [get_bd_intf_ports dma1_axis_c2h_dmawr_0] [get_bd_intf_pins versal_cips_0/dma1_axis_c2h_dmawr]
  connect_bd_intf_net -intf_net versal_cips_0_dma1_axis_c2h_status [get_bd_intf_ports dma1_axis_c2h_status_0] [get_bd_intf_pins versal_cips_0/dma1_axis_c2h_status]
  connect_bd_intf_net -intf_net versal_cips_0_dma1_m_axis_h2c [get_bd_intf_ports dma1_m_axis_h2c_0] [get_bd_intf_pins versal_cips_0/dma1_m_axis_h2c]
  connect_bd_intf_net -intf_net versal_cips_0_dma1_qsts_out [get_bd_intf_ports dma1_qsts_out_0] [get_bd_intf_pins versal_cips_0/dma1_qsts_out]
  connect_bd_intf_net -intf_net versal_cips_0_dma1_st_rx_msg [get_bd_intf_ports dma1_st_rx_msg_0] [get_bd_intf_pins versal_cips_0/dma1_st_rx_msg]
  connect_bd_intf_net -intf_net versal_cips_0_dma1_tm_dsc_sts [get_bd_intf_ports dma1_tm_dsc_sts_0] [get_bd_intf_pins versal_cips_0/dma1_tm_dsc_sts]

  # Create port connections
  connect_bd_net -net cpm_irq0_0_1 [get_bd_ports cpm_irq0_0] [get_bd_pins versal_cips_0/cpm_irq0]
  connect_bd_net -net cpm_irq1_0_1 [get_bd_ports cpm_irq1_0] [get_bd_pins versal_cips_0/cpm_irq1]
  connect_bd_net -net dma1_intrfc_resetn_0_1 [get_bd_ports dma1_intrfc_resetn_0] [get_bd_pins versal_cips_0/dma1_intrfc_resetn]
  connect_bd_net -net versal_cips_0_cpm_cor_irq [get_bd_pins versal_cips_0/cpm_cor_irq] [get_bd_ports cpm_cor_irq_0]
  connect_bd_net -net versal_cips_0_cpm_misc_irq [get_bd_pins versal_cips_0/cpm_misc_irq] [get_bd_ports cpm_misc_irq_0]
  connect_bd_net -net versal_cips_0_cpm_pcie_noc_axi0_clk [get_bd_pins versal_cips_0/cpm_pcie_noc_axi0_clk] [get_bd_pins axi_noc_0/aclk0]
  connect_bd_net -net versal_cips_0_cpm_uncor_irq [get_bd_pins versal_cips_0/cpm_uncor_irq] [get_bd_ports cpm_uncor_irq_0]
  connect_bd_net -net versal_cips_0_dma1_axi_aresetn [get_bd_pins versal_cips_0/dma1_axi_aresetn] [get_bd_ports dma1_axi_aresetn_0] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins pcie_qdma_mailbox_0/axi_aresetn] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins smartconnect_1/aresetn] [get_bd_pins pcie_qdma_mailbox_0/ip_resetn]
  connect_bd_net -net versal_cips_0_pcie1_user_clk [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_ports pcie1_user_clk_0] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_noc_0/aclk1] [get_bd_pins pcie_qdma_mailbox_0/axi_aclk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins versal_cips_0/dma1_intrfc_clk] [get_bd_pins smartconnect_1/aclk] [get_bd_pins pcie_qdma_mailbox_0/ip_clk]

  # Create address segments
  assign_bd_address -offset 0x020180000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs M_AXIL/Reg] -force
  assign_bd_address -offset 0x020800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs pcie_qdma_mailbox_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXIL] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force


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


