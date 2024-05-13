
################################################################
# This is a generated script based on design: design_sim_rp
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
set scripts_vivado_version 2024.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "CRITICAL WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been changes to the IP between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the functionality and configuration of the design."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_sim_rp_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvp1202-vsva2785-2MHP-e-S
}


# CHANGE DESIGN NAME HERE
variable design_name_sim_rp
set design_name_sim_rp design_sim_rp

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name_sim_rp

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name_sim_rp} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name_sim_rp> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name_sim_rp NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name_sim_rp exists in project.

   if { $cur_design ne $design_name_sim_rp } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name_sim_rp> from <$design_name_sim_rp> to <$cur_design> since current design is empty."
      set design_name_sim_rp [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name_sim_rp } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name_sim_rp> already exists in your project, please set the variable <design_name_sim_rp> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name_sim_rp}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name_sim_rp exists in project.
   #    7) No opened design, design_name_sim_rp exists in project.

   set errMsg "Design <$design_name_sim_rp> already exists in your project, please set the variable <design_name_sim_rp> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name_sim_rp not in project.
   #    9) Current opened design, has components, but diff names, design_name_sim_rp not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name_sim_rp> in project, so creating one..."

   create_bd_design $design_name_sim_rp

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name_sim_rp> as current_bd_design."
   current_bd_design $design_name_sim_rp

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name_sim_rp> is equal to \"$design_name_sim_rp\"."

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
xilinx.com:ip:pcie_versal:*\
xilinx.com:ip:pcie_phy_versal:*\
xilinx.com:ip:xlconstant:*\
xilinx.com:ip:util_ds_buf:*\
xilinx.com:ip:gt_quad_base:*\
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
  variable design_name_sim_rp

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
  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]

  set pcie_mgt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_mgt ]

  set cxs_rx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:cxs_rtl:1.0 cxs_rx ]

  set cxs_tx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:cxs_rtl:1.0 cxs_tx ]

  set m_axis_cq [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_cq ]

  set m_axis_rc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_rc ]

  set pcie_cfg_control [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie5_cfg_control_rtl:1.0 pcie_cfg_control ]

  set pcie_cfg_fc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.1 pcie_cfg_fc ]

  set pcie_cfg_interrupt [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie_cfg_interrupt ]

  set pcie_cfg_mesg_rcvd [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie_cfg_mesg_rcvd ]

  set pcie_cfg_mesg_tx [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_mesg_tx_rtl:1.0 pcie_cfg_mesg_tx ]

  set pcie_cfg_mgmt [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie_cfg_mgmt ]

  set pcie_cfg_status [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie5_cfg_status_rtl:1.0 pcie_cfg_status ]

  set pipe_rp [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie_ext_pipe_rtl:1.0 pipe_rp ]

  set pcie_transmit_fc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie_transmit_fc ]

  set s_axis_cc [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_cc ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {81} \
   ] $s_axis_cc

  set s_axis_rq [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_rq ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {183} \
   ] $s_axis_rq


  # Create ports
  set sys_reset [ create_bd_port -dir I -type rst sys_reset ]
  set ccix_optimized_tlp_tx_and_rx_enable [ create_bd_port -dir I ccix_optimized_tlp_tx_and_rx_enable ]
  set ccix_rx_credit_av [ create_bd_port -dir O -from 7 -to 0 ccix_rx_credit_av ]
  set core_clk [ create_bd_port -dir O -type clk core_clk ]
  set phy_rdy_out [ create_bd_port -dir O phy_rdy_out ]
  set user_clk [ create_bd_port -dir O -type clk user_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {m_axis_cq:m_axis_rc:s_axis_cc:s_axis_rq} \
 ] $user_clk
  set_property CONFIG.ASSOCIATED_BUSIF.VALUE_SRC DEFAULT $user_clk

  set user_lnk_up [ create_bd_port -dir O user_lnk_up ]
  set user_reset [ create_bd_port -dir O -type rst user_reset ]

  # Create instance: pcie_versal_0, and set properties
  set pcie_versal_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_versal pcie_versal_0 ]
  set_property -dict [list \
    CONFIG.AXISTEN_IF_CQ_ALIGNMENT_MODE {DWORD_Aligned} \
    CONFIG.AXISTEN_IF_EXT_512_CC_STRADDLE {false} \
    CONFIG.AXISTEN_IF_EXT_512_CQ_STRADDLE {false} \
    CONFIG.AXISTEN_IF_EXT_512_RC_STRADDLE {true} \
    CONFIG.AXISTEN_IF_EXT_512_RQ_STRADDLE {false} \
    CONFIG.AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
    CONFIG.EGW_IS_PARENT_IP {1} \
    CONFIG.EXTENDED_DATA_RATE {None} \
    CONFIG.GT_TYPE {GTY} \
    CONFIG.INS_LOSS_NYQ {15} \
    CONFIG.PCIE_BOARD_INTERFACE {Custom} \
    CONFIG.PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE {false} \
    CONFIG.PF0_DEVICE_ID {B0D4} \
    CONFIG.PF0_DEV_CAP2_128B_CAS_ATOMIC_COMPLETER_SUPPORT {false} \
    CONFIG.PF0_DEV_CAP2_32B_ATOMIC_COMPLETER_SUPPORT {false} \
    CONFIG.PF0_DEV_CAP2_64B_ATOMIC_COMPLETER_SUPPORT {false} \
    CONFIG.PF0_DEV_CAP2_TPH_COMPLETER_SUPPORT {false} \
    CONFIG.PF0_INTERRUPT_PIN {INTA} \
    CONFIG.PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {true} \
    CONFIG.PF0_PM_CAP_PMESUPPORT_D0 {false} \
    CONFIG.PF0_PM_CAP_PMESUPPORT_D1 {false} \
    CONFIG.PF0_PM_CAP_PMESUPPORT_D3HOT {false} \
    CONFIG.PF0_PM_CAP_SUPP_D1_STATE {false} \
    CONFIG.PF0_REVISION_ID {00} \
    CONFIG.PF0_SRIOV_FUNC_DEP_LINK {0000} \
    CONFIG.PF0_SRIOV_VF_DEVICE_ID {C054} \
    CONFIG.PF0_SUBSYSTEM_ID {0007} \
    CONFIG.PF0_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF1_DEVICE_ID {9011} \
    CONFIG.PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF1_REVISION_ID {00} \
    CONFIG.PF1_SUBSYSTEM_ID {0007} \
    CONFIG.PF1_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF1_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF2_DEVICE_ID {0007} \
    CONFIG.PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF2_REVISION_ID {00} \
    CONFIG.PF2_SUBSYSTEM_ID {0007} \
    CONFIG.PF2_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF2_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF3_DEVICE_ID {0007} \
    CONFIG.PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF3_REVISION_ID {00} \
    CONFIG.PF3_SUBSYSTEM_ID {0007} \
    CONFIG.PF3_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF3_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF4_DEVICE_ID {0007} \
    CONFIG.PF4_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF4_REVISION_ID {00} \
    CONFIG.PF4_SUBSYSTEM_ID {0007} \
    CONFIG.PF4_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF4_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF5_DEVICE_ID {0007} \
    CONFIG.PF5_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF5_REVISION_ID {00} \
    CONFIG.PF5_SUBSYSTEM_ID {0007} \
    CONFIG.PF5_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF5_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF6_DEVICE_ID {0007} \
    CONFIG.PF6_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF6_REVISION_ID {00} \
    CONFIG.PF6_SUBSYSTEM_ID {0007} \
    CONFIG.PF6_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF6_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PF7_DEVICE_ID {0007} \
    CONFIG.PF7_MSI_CAP_MULTIMSGCAP {1_vector} \
    CONFIG.PF7_REVISION_ID {00} \
    CONFIG.PF7_SUBSYSTEM_ID {0007} \
    CONFIG.PF7_SUBSYSTEM_VENDOR_ID {10EE} \
    CONFIG.PF7_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.PHY_LP_TXPRESET {4} \
    CONFIG.PL_DISABLE_LANE_REVERSAL {TRUE} \
    CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {32.0_GT/s} \
    CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
    CONFIG.REF_CLK_FREQ {100_MHz} \
    CONFIG.SRIOV_CAP_ENABLE_EXT {false} \
    CONFIG.SYS_RST_N_BOARD_INTERFACE {Custom} \
    CONFIG.TX_RX_MASTER_CHANNEL {X0Y19} \
    CONFIG.X1_CH_EN {X0Y19} \
    CONFIG.X2_CH_EN {X0Y19} \
    CONFIG.X4_CH_EN {X0Y19} \
    CONFIG.X8_CH_EN {X0Y19} \
    CONFIG.XS_CH_EN {X0Y19} \
    CONFIG.acs_ext_cap_enable {false} \
    CONFIG.alignment_mode_256b {DWORD_Aligned} \
    CONFIG.all_speeds_all_sides {NO} \
    CONFIG.aspm_support {No_ASPM} \
    CONFIG.aspm_support_l1_en {false} \
    CONFIG.aws_mode_value {0} \
    CONFIG.axisten_freq {250} \
    CONFIG.axisten_if_enable_client_tag {false} \
    CONFIG.axisten_if_enable_msg_route {2FFFF} \
    CONFIG.axisten_if_enable_msg_route_override {false} \
    CONFIG.axisten_if_enable_rx_msg_intfc {FALSE} \
    CONFIG.axisten_if_width {512_bit} \
    CONFIG.board_flow {false} \
    CONFIG.cfg_ctl_if {true} \
    CONFIG.cfg_dbg_if {false} \
    CONFIG.cfg_ext_if {true} \
    CONFIG.cfg_fc_if {true} \
    CONFIG.cfg_mgmt_if {true} \
    CONFIG.cfg_pm_if {true} \
    CONFIG.cfg_status_if {true} \
    CONFIG.cfg_tx_msg_if {true} \
    CONFIG.copy_pf0 {true} \
    CONFIG.copy_sriov_pf0 {true} \
    CONFIG.coreclk_freq {500} \
    CONFIG.dbg_checker {false} \
    CONFIG.dedicate_perst {false} \
    CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.dis_gt_wizard {false} \
    CONFIG.disable_bram_pipeline {false} \
    CONFIG.disable_double_pipe {YES} \
    CONFIG.disable_eq_synchronizer {false} \
    CONFIG.en_dbg_descramble {false} \
    CONFIG.en_ext_clk {true} \
    CONFIG.en_gt_pclk {false} \
    CONFIG.en_l23_entry {false} \
    CONFIG.en_multiple_ClearErr_lane_margin {false} \
    CONFIG.en_parity {false} \
    CONFIG.en_pcie_apb3 {false} \
    CONFIG.en_pcie_conf {false} \
    CONFIG.en_pl_ifc {false} \
    CONFIG.en_transceiver_status_ports {false} \
    CONFIG.enable_auto_rxeq {False} \
    CONFIG.enable_axist_reg_slice {false} \
    CONFIG.enable_ccix {FALSE} \
    CONFIG.enable_dvsec {FALSE} \
    CONFIG.enable_gen4 {false} \
    CONFIG.enable_ibert {false} \
    CONFIG.enable_jtag_dbg {false} \
    CONFIG.enable_more_clk {false} \
    CONFIG.err_inj_g2 {false} \
    CONFIG.ext_pcie_cfg_space_enabled {false} \
    CONFIG.ext_startup_primitive {false} \
    CONFIG.ext_sys_clk_bufg {true} \
    CONFIG.free_run_freq {100_MHz} \
    CONFIG.gen4_eieos_0s7 {true} \
    CONFIG.gen_x0y0 {true} \
    CONFIG.gen_x0y1 {false} \
    CONFIG.gen_x0y2 {false} \
    CONFIG.gen_x0y3 {false} \
    CONFIG.gen_x0y4 {false} \
    CONFIG.gen_x0y5 {false} \
    CONFIG.gen_x1y0 {false} \
    CONFIG.gen_x1y1 {false} \
    CONFIG.gen_x1y2 {false} \
    CONFIG.gen_x1y3 {false} \
    CONFIG.gen_x1y4 {false} \
    CONFIG.gen_x1y5 {false} \
    CONFIG.gt_drp_clk_src {Internal} \
    CONFIG.gt_loc_num {X99Y99} \
    CONFIG.gt_quad_sharing {false} \
    CONFIG.ins_loss_profile {Add-in_Card} \
    CONFIG.insert_cips {false} \
    CONFIG.lane_order {Bottom} \
    CONFIG.lane_reversal {false} \
    CONFIG.lcl_testing_0 {false} \
    CONFIG.legacy_ext_pcie_cfg_space_enabled {false} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.pcie_blk_locn {X1Y0} \
    CONFIG.pcie_id_if {false} \
    CONFIG.pcie_link_debug {false} \
    CONFIG.pcie_link_debug_axi4_st {false} \
    CONFIG.perf_level {Extreme} \
    CONFIG.pf0_acs_enabled {false} \
    CONFIG.pf0_aer_enabled {true} \
    CONFIG.pf0_ari_enabled {false} \
    CONFIG.pf0_ats_enabled {false} \
    CONFIG.pf0_bar0_64bit {false} \
    CONFIG.pf0_bar0_enabled {true} \
    CONFIG.pf0_bar0_scale {Kilobytes} \
    CONFIG.pf0_bar0_size {128} \
    CONFIG.pf0_bar0_type {Memory} \
    CONFIG.pf0_bar2_enabled {false} \
    CONFIG.pf0_bar4_enabled {false} \
    CONFIG.pf0_base_class_menu {Bridge_device} \
    CONFIG.pf0_class_code_base {06} \
    CONFIG.pf0_class_code_interface {00} \
    CONFIG.pf0_class_code_sub {0A} \
    CONFIG.pf0_dev_cap2_10b_tag_requester_supported {true} \
    CONFIG.pf0_dev_cap_max_payload {1024_bytes} \
    CONFIG.pf0_dll_feature_cap_enabled {false} \
    CONFIG.pf0_dsn_enabled {false} \
    CONFIG.pf0_expansion_rom_enabled {false} \
    CONFIG.pf0_margining_cap_enabled {true} \
    CONFIG.pf0_msi_enabled {false} \
    CONFIG.pf0_msix_enabled {false} \
    CONFIG.pf0_pasid_cap_enabled {false} \
    CONFIG.pf0_pl16_cap_enabled {true} \
    CONFIG.pf0_pl32_cap_enabled {true} \
    CONFIG.pf0_pri_enabled {false} \
    CONFIG.pf0_sriov_bar0_64bit {false} \
    CONFIG.pf0_sriov_bar0_enabled {true} \
    CONFIG.pf0_sriov_bar0_scale {Kilobytes} \
    CONFIG.pf0_sriov_bar0_size {2} \
    CONFIG.pf0_sriov_bar0_type {Memory} \
    CONFIG.pf0_sriov_bar2_enabled {false} \
    CONFIG.pf0_sriov_bar4_enabled {false} \
    CONFIG.pf0_sriov_bar5_prefetchable {false} \
    CONFIG.pf0_sriov_cap_ver {1} \
    CONFIG.pf0_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf0_tphr_enable {false} \
    CONFIG.pf0_vc_cap_enabled {true} \
    CONFIG.pf1_base_class_menu {Bridge_device} \
    CONFIG.pf1_class_code_base {06} \
    CONFIG.pf1_class_code_interface {00} \
    CONFIG.pf1_class_code_sub {0A} \
    CONFIG.pf1_msix_enabled {false} \
    CONFIG.pf1_sriov_bar5_prefetchable {false} \
    CONFIG.pf1_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf1_vendor_id {10EE} \
    CONFIG.pf2_base_class_menu {Bridge_device} \
    CONFIG.pf2_class_code_base {06} \
    CONFIG.pf2_class_code_interface {00} \
    CONFIG.pf2_class_code_sub {0A} \
    CONFIG.pf2_msix_enabled {false} \
    CONFIG.pf2_sriov_bar5_prefetchable {false} \
    CONFIG.pf2_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf2_vendor_id {10EE} \
    CONFIG.pf3_base_class_menu {Bridge_device} \
    CONFIG.pf3_class_code_base {06} \
    CONFIG.pf3_class_code_interface {00} \
    CONFIG.pf3_class_code_sub {0A} \
    CONFIG.pf3_msix_enabled {false} \
    CONFIG.pf3_sriov_bar5_prefetchable {false} \
    CONFIG.pf3_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf3_vendor_id {10EE} \
    CONFIG.pf4_base_class_menu {Bridge_device} \
    CONFIG.pf4_class_code_base {06} \
    CONFIG.pf4_class_code_interface {00} \
    CONFIG.pf4_class_code_sub {0A} \
    CONFIG.pf4_msix_enabled {false} \
    CONFIG.pf4_sriov_bar5_prefetchable {false} \
    CONFIG.pf4_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf4_vendor_id {10EE} \
    CONFIG.pf5_base_class_menu {Bridge_device} \
    CONFIG.pf5_class_code_base {06} \
    CONFIG.pf5_class_code_interface {00} \
    CONFIG.pf5_class_code_sub {0A} \
    CONFIG.pf5_msix_enabled {false} \
    CONFIG.pf5_sriov_bar5_prefetchable {false} \
    CONFIG.pf5_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf5_vendor_id {10EE} \
    CONFIG.pf6_base_class_menu {Bridge_device} \
    CONFIG.pf6_class_code_base {06} \
    CONFIG.pf6_class_code_interface {00} \
    CONFIG.pf6_class_code_sub {0A} \
    CONFIG.pf6_msix_enabled {false} \
    CONFIG.pf6_sriov_bar5_prefetchable {false} \
    CONFIG.pf6_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf6_vendor_id {10EE} \
    CONFIG.pf7_base_class_menu {Bridge_device} \
    CONFIG.pf7_class_code_base {06} \
    CONFIG.pf7_class_code_interface {00} \
    CONFIG.pf7_class_code_sub {0A} \
    CONFIG.pf7_msix_enabled {false} \
    CONFIG.pf7_sriov_bar5_prefetchable {false} \
    CONFIG.pf7_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf7_vendor_id {10EE} \
    CONFIG.pipe_line_stage {1} \
    CONFIG.pipe_sim {true} \
    CONFIG.plltype {LCPLL} \
    CONFIG.rcv_msg_if {true} \
    CONFIG.replace_uram_with_bram {false} \
    CONFIG.set_finite_credit {false} \
    CONFIG.sim_model {YES} \
    CONFIG.sys_reset_polarity {ACTIVE_LOW} \
    CONFIG.tl_credits_cd {15} \
    CONFIG.tl_credits_ch {15} \
    CONFIG.tst_value {0} \
    CONFIG.two_port_config {X8G3} \
    CONFIG.two_port_ctlr {PCIE1} \
    CONFIG.two_port_switch {false} \
    CONFIG.tx_fc_if {true} \
    CONFIG.type1_membase_memlimit_enable {Enabled} \
    CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
    CONFIG.vendor_id {10EE} \
    CONFIG.vfg0_msix_enabled {false} \
    CONFIG.vfg1_msix_enabled {false} \
    CONFIG.vfg2_msix_enabled {false} \
    CONFIG.vfg3_msix_enabled {false} \
    CONFIG.vfg4_msix_enabled {false} \
    CONFIG.vfg5_msix_enabled {false} \
    CONFIG.vfg6_msix_enabled {false} \
    CONFIG.vfg7_msix_enabled {false} \
    CONFIG.warm_reboot_sbr_fix {false} \
    CONFIG.xlnx_ref_board {None} \
  ] $pcie_versal_0


  # Create instance: pcie_phy, and set properties
  set pcie_phy [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_phy_versal pcie_phy ]
  set_property -dict [list \
    CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {32.0_GT/s} \
    CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
    CONFIG.aspm {No_ASPM} \
    CONFIG.async_mode {SRNS} \
    CONFIG.disable_double_pipe {YES} \
    CONFIG.en_gt_pclk {false} \
    CONFIG.ins_loss_profile {Add-in_Card} \
    CONFIG.lane_order {Bottom} \
    CONFIG.lane_reversal {false} \
    CONFIG.phy_async_en {true} \
    CONFIG.phy_coreclk_freq {500_MHz} \
    CONFIG.phy_refclk_freq {100_MHz} \
    CONFIG.phy_userclk_freq {250_MHz} \
    CONFIG.pipeline_stages {1} \
    CONFIG.sim_model {YES} \
    CONFIG.tx_preset {4} \
  ] $pcie_phy


  # Create instance: const_1b1, and set properties
  set const_1b1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_1b1 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {1} \
    CONFIG.CONST_WIDTH {1} \
  ] $const_1b1


  # Create instance: const_1b0, and set properties
  set const_1b0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_1b0 ]

  # Create instance: bufg_gt_sysclk, and set properties
  set bufg_gt_sysclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf bufg_gt_sysclk ]
  set_property -dict [list \
    CONFIG.C_BUFG_GT_SYNC {true} \
    CONFIG.C_BUF_TYPE {BUFG_GT} \
  ] $bufg_gt_sysclk


  # Create instance: refclk_ibuf, and set properties
  set refclk_ibuf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf refclk_ibuf ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $refclk_ibuf


  # Create instance: gt_quad_0, and set properties
  set gt_quad_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gt_quad_base gt_quad_0 ]
  set_property -dict [list \
    CONFIG.APB3_CLK_FREQUENCY {200.0} \
    CONFIG.CHANNEL_ORDERING {/gt_quad_0/TX0_GT_IP_Interface design_sim_rp_pcie_phy_0./pcie_phy/GT_TX0.0 /gt_quad_0/TX1_GT_IP_Interface design_sim_rp_pcie_phy_0./pcie_phy/GT_TX1.1 /gt_quad_0/TX2_GT_IP_Interface\
design_sim_rp_pcie_phy_0./pcie_phy/GT_TX2.2 /gt_quad_0/TX3_GT_IP_Interface design_sim_rp_pcie_phy_0./pcie_phy/GT_TX3.3 /gt_quad_0/RX0_GT_IP_Interface design_sim_rp_pcie_phy_0./pcie_phy/GT_RX0.0 /gt_quad_0/RX1_GT_IP_Interface\
design_sim_rp_pcie_phy_0./pcie_phy/GT_RX1.1 /gt_quad_0/RX2_GT_IP_Interface design_sim_rp_pcie_phy_0./pcie_phy/GT_RX2.2 /gt_quad_0/RX3_GT_IP_Interface design_sim_rp_pcie_phy_0./pcie_phy/GT_RX3.3} \
    CONFIG.GT_TYPE {GTYP} \
    CONFIG.PORTS_INFO_DICT {LANE_SEL_DICT {PROT0 {RX0 RX1 RX2 RX3 TX0 TX1 TX2 TX3}} GT_TYPE GTYP REG_CONF_INTF APB3_INTF BOARD_PARAMETER { }} \
    CONFIG.PROT0_ENABLE {true} \
    CONFIG.PROT0_GT_DIRECTION {DUPLEX} \
    CONFIG.PROT0_LR0_SETTINGS {GT_DIRECTION DUPLEX TX_PAM_SEL NRZ TX_HD_EN 0 TX_GRAY_BYP true TX_GRAY_LITTLEENDIAN true TX_PRECODE_BYP true TX_PRECODE_LITTLEENDIAN false TX_LINE_RATE 2.5 TX_PLL_TYPE LCPLL\
TX_REFCLK_FREQUENCY 100 TX_ACTUAL_REFCLK_FREQUENCY 100.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING 8B10B TX_USER_DATA_WIDTH 16 TX_INT_DATA_WIDTH\
20 TX_BUFFER_MODE 0 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TXPROGDIV_FREQ_VAL 500.000 TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_LANE_DESKEW_HDMI_ENABLE false TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE GT_TYPE GTYP PRESET None RX_PAM_SEL NRZ\
RX_HD_EN 0 RX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None RX_LINE_RATE 2.5 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 100 RX_ACTUAL_REFCLK_FREQUENCY\
100.000000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING 8B10B RX_USER_DATA_WIDTH 16 RX_INT_DATA_WIDTH 20 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE\
RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 125.000000 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE LPM RX_COUPLING AC RX_TERMINATION\
PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE true RX_COMMA_ALIGN_WORD 1 RX_COMMA_SHOW_REALIGN_ENABLE\
true PCIE_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_M_ENABLE true RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 1010000011 RX_COMMA_M_VAL 0101111100 RX_COMMA_MASK 1111111111 RX_SLIDE_MODE OFF RX_SSC_PPM\
0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_K 00000000 RX_CB_DISP\
00000000 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false RX_CB_VAL_0_2\
00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0\
false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3\
00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 1 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE ENABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT 0 RX_CC_MASK 00000000 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000011100\
RX_CC_K 00000001 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_K_0_0 true RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false\
RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0\
00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2\
false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 1 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE\
MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET K28.5 RX_COMMA_VALID_ONLY 0} \
    CONFIG.PROT0_LR10_SETTINGS {NA NA} \
    CONFIG.PROT0_LR11_SETTINGS {NA NA} \
    CONFIG.PROT0_LR12_SETTINGS {NA NA} \
    CONFIG.PROT0_LR13_SETTINGS {NA NA} \
    CONFIG.PROT0_LR14_SETTINGS {NA NA} \
    CONFIG.PROT0_LR15_SETTINGS {NA NA} \
    CONFIG.PROT0_LR1_SETTINGS {GT_DIRECTION DUPLEX TX_PAM_SEL NRZ TX_HD_EN 0 TX_GRAY_BYP true TX_GRAY_LITTLEENDIAN true TX_PRECODE_BYP true TX_PRECODE_LITTLEENDIAN false TX_LINE_RATE 5.0 TX_PLL_TYPE LCPLL\
TX_REFCLK_FREQUENCY 100 TX_ACTUAL_REFCLK_FREQUENCY 100.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING 8B10B TX_USER_DATA_WIDTH 16 TX_INT_DATA_WIDTH\
20 TX_BUFFER_MODE 0 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TXPROGDIV_FREQ_VAL 500.000 TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_LANE_DESKEW_HDMI_ENABLE false TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE GT_TYPE GTYP PRESET None RX_PAM_SEL NRZ\
RX_HD_EN 0 RX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None RX_LINE_RATE 5.0 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 100 RX_ACTUAL_REFCLK_FREQUENCY\
100.000000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING 8B10B RX_USER_DATA_WIDTH 16 RX_INT_DATA_WIDTH 20 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE\
RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 250.000000 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE LPM RX_COUPLING AC RX_TERMINATION\
PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE true RX_COMMA_ALIGN_WORD 1 RX_COMMA_SHOW_REALIGN_ENABLE\
true PCIE_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_M_ENABLE true RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 1010000011 RX_COMMA_M_VAL 0101111100 RX_COMMA_MASK 1111111111 RX_SLIDE_MODE OFF RX_SSC_PPM\
0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_K 00000000 RX_CB_DISP\
00000000 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false RX_CB_VAL_0_2\
00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0\
false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3\
00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 1 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE ENABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT 0 RX_CC_MASK 00000000 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000011100\
RX_CC_K 00000001 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_K_0_0 true RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false\
RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0\
00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2\
false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 1 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE\
MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET K28.5 RX_COMMA_VALID_ONLY 0} \
    CONFIG.PROT0_LR2_SETTINGS {GT_DIRECTION DUPLEX TX_PAM_SEL NRZ TX_HD_EN 0 TX_GRAY_BYP true TX_GRAY_LITTLEENDIAN true TX_PRECODE_BYP true TX_PRECODE_LITTLEENDIAN false TX_LINE_RATE 8.0 TX_PLL_TYPE LCPLL\
TX_REFCLK_FREQUENCY 100 TX_ACTUAL_REFCLK_FREQUENCY 100.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING 128B130B TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH\
32 TX_BUFFER_MODE 0 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TXPROGDIV_FREQ_VAL 500.000 TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_LANE_DESKEW_HDMI_ENABLE false TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE GT_TYPE GTYP PRESET None RX_PAM_SEL NRZ\
RX_HD_EN 0 RX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None RX_LINE_RATE 8.0 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 100 RX_ACTUAL_REFCLK_FREQUENCY\
100.000000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING 128B130B RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH 32 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE\
RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 250.000000 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE DFE RX_COUPLING AC RX_TERMINATION\
PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE true RX_COMMA_ALIGN_WORD 1 RX_COMMA_SHOW_REALIGN_ENABLE\
true PCIE_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_M_ENABLE true RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 1010000011 RX_COMMA_M_VAL 0101111100 RX_COMMA_MASK 1111111111 RX_SLIDE_MODE OFF RX_SSC_PPM\
0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_K 00000000 RX_CB_DISP\
00000000 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false RX_CB_VAL_0_2\
00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0\
false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3\
00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 1 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE ENABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT 0 RX_CC_MASK 00000000 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000011100\
RX_CC_K 00000000 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_K_0_0 false RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false\
RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0\
00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2\
false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 1 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE\
MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET K28.5 RX_COMMA_VALID_ONLY 0} \
    CONFIG.PROT0_LR3_SETTINGS {GT_DIRECTION DUPLEX TX_PAM_SEL NRZ TX_HD_EN 0 TX_GRAY_BYP true TX_GRAY_LITTLEENDIAN true TX_PRECODE_BYP true TX_PRECODE_LITTLEENDIAN false TX_LINE_RATE 16.0 TX_PLL_TYPE LCPLL\
TX_REFCLK_FREQUENCY 100 TX_ACTUAL_REFCLK_FREQUENCY 100.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING 128B130B TX_USER_DATA_WIDTH 32 TX_INT_DATA_WIDTH\
32 TX_BUFFER_MODE 0 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TXPROGDIV_FREQ_VAL 500.000 TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_LANE_DESKEW_HDMI_ENABLE false TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE GT_TYPE GTYP PRESET None RX_PAM_SEL NRZ\
RX_HD_EN 0 RX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None RX_LINE_RATE 16.0 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 100 RX_ACTUAL_REFCLK_FREQUENCY\
100.000000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING 128B130B RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH 32 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE\
RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 500.000000 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE DFE RX_COUPLING AC RX_TERMINATION\
PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE true RX_COMMA_ALIGN_WORD 1 RX_COMMA_SHOW_REALIGN_ENABLE\
true PCIE_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_M_ENABLE true RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 1010000011 RX_COMMA_M_VAL 0101111100 RX_COMMA_MASK 1111111111 RX_SLIDE_MODE OFF RX_SSC_PPM\
0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_K 00000000 RX_CB_DISP\
00000000 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false RX_CB_VAL_0_2\
00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0\
false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3\
00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 1 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE ENABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT 0 RX_CC_MASK 00000000 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000011100\
RX_CC_K 00000000 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_K_0_0 false RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false\
RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0\
00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2\
false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 1 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE\
MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET K28.5 RX_COMMA_VALID_ONLY 0} \
    CONFIG.PROT0_LR4_SETTINGS {GT_DIRECTION DUPLEX TX_PAM_SEL NRZ TX_HD_EN 0 TX_GRAY_BYP true TX_GRAY_LITTLEENDIAN true TX_PRECODE_BYP true TX_PRECODE_LITTLEENDIAN false TX_LINE_RATE 32.0 TX_PLL_TYPE LCPLL\
TX_REFCLK_FREQUENCY 100 TX_ACTUAL_REFCLK_FREQUENCY 100.0 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING 128B130B TX_USER_DATA_WIDTH 64 TX_INT_DATA_WIDTH\
64 TX_BUFFER_MODE 0 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE RPLL TXPROGDIV_FREQ_VAL 500.000 TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_LANE_DESKEW_HDMI_ENABLE false TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE GT_TYPE GTYP PRESET None RX_PAM_SEL NRZ\
RX_HD_EN 0 RX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None RX_LINE_RATE 32.0 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 100 RX_ACTUAL_REFCLK_FREQUENCY\
100.0 RX_FRACN_ENABLED false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING 128B130B RX_USER_DATA_WIDTH 64 RX_INT_DATA_WIDTH 64 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE RXOUTCLKPMA\
RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 322.265625 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE DFE RX_COUPLING AC RX_TERMINATION PROGRAMMABLE\
RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE true RX_COMMA_ALIGN_WORD 1 RX_COMMA_SHOW_REALIGN_ENABLE\
true PCIE_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_M_ENABLE true RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 1010000011 RX_COMMA_M_VAL 0101111100 RX_COMMA_MASK 1111111111 RX_SLIDE_MODE OFF RX_SSC_PPM\
0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_K 00000000 RX_CB_DISP\
00000000 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false RX_CB_VAL_0_2\
00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0\
false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3\
00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 1 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE ENABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT 0 RX_CC_MASK 00000000 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000011100\
RX_CC_K 00000000 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00011100 RX_CC_K_0_0 false RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false\
RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0\
00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2\
false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 1 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE\
MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET K28.5 RX_COMMA_VALID_ONLY 0} \
    CONFIG.PROT0_LR5_SETTINGS {NA NA} \
    CONFIG.PROT0_LR6_SETTINGS {NA NA} \
    CONFIG.PROT0_LR7_SETTINGS {NA NA} \
    CONFIG.PROT0_LR8_SETTINGS {NA NA} \
    CONFIG.PROT0_LR9_SETTINGS {NA NA} \
    CONFIG.PROT0_NO_OF_LANES {4} \
    CONFIG.PROT0_RX_MASTERCLK_SRC {RX0} \
    CONFIG.PROT0_TX_MASTERCLK_SRC {TX0} \
    CONFIG.QUAD_USAGE {TX_QUAD_CH {TXQuad_0_/gt_quad_0 {/gt_quad_0 design_sim_rp_pcie_phy_0.IP_CH0,design_sim_rp_pcie_phy_0.IP_CH1,design_sim_rp_pcie_phy_0.IP_CH2,design_sim_rp_pcie_phy_0.IP_CH3 MSTRCLK\
1,0,0,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/gt_quad_0 {/gt_quad_0 design_sim_rp_pcie_phy_0.IP_CH0,design_sim_rp_pcie_phy_0.IP_CH1,design_sim_rp_pcie_phy_0.IP_CH2,design_sim_rp_pcie_phy_0.IP_CH3 MSTRCLK\
1,0,0,0 IS_CURRENT_QUAD 1}}} \
    CONFIG.REFCLK_LIST {} \
    CONFIG.REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK0_RPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK1_RPLLGTREFCLK0\
refclk_PROT0_R0_100_MHz_unique1} \
    CONFIG.RX0_LANE_SEL {PROT0} \
    CONFIG.RX1_LANE_SEL {PROT0} \
    CONFIG.RX2_LANE_SEL {PROT0} \
    CONFIG.RX3_LANE_SEL {PROT0} \
    CONFIG.TX0_LANE_SEL {PROT0} \
    CONFIG.TX1_LANE_SEL {PROT0} \
    CONFIG.TX2_LANE_SEL {PROT0} \
    CONFIG.TX3_LANE_SEL {PROT0} \
  ] $gt_quad_0

  set_property -dict [list \
    CONFIG.APB3_CLK_FREQUENCY.VALUE_MODE {auto} \
    CONFIG.CHANNEL_ORDERING.VALUE_MODE {auto} \
    CONFIG.GT_TYPE.VALUE_MODE {auto} \
    CONFIG.PROT0_ENABLE.VALUE_MODE {auto} \
    CONFIG.PROT0_GT_DIRECTION.VALUE_MODE {auto} \
    CONFIG.PROT0_LR0_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR10_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR11_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR12_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR13_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR14_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR15_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR1_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR2_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR3_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR4_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR5_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR6_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR7_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR8_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR9_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_NO_OF_LANES.VALUE_MODE {auto} \
    CONFIG.PROT0_RX_MASTERCLK_SRC.VALUE_MODE {auto} \
    CONFIG.PROT0_TX_MASTERCLK_SRC.VALUE_MODE {auto} \
    CONFIG.QUAD_USAGE.VALUE_MODE {auto} \
    CONFIG.RX0_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX1_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX2_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX3_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX0_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX1_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX2_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX3_LANE_SEL.VALUE_MODE {auto} \
  ] $gt_quad_0


  # Create interface connections
  connect_bd_intf_net -intf_net cxs_rx_1 [get_bd_intf_ports cxs_rx] [get_bd_intf_pins pcie_versal_0/cxs_rx]
  connect_bd_intf_net -intf_net cxs_tx_1 [get_bd_intf_ports cxs_tx] [get_bd_intf_pins pcie_versal_0/cxs_tx]
  connect_bd_intf_net -intf_net gt_quad_0_GT0_BUFGT [get_bd_intf_pins pcie_phy/GT_BUFGT] [get_bd_intf_pins gt_quad_0/GT0_BUFGT]
  connect_bd_intf_net -intf_net gt_quad_0_GT_Serial [get_bd_intf_pins pcie_phy/GT0_Serial] [get_bd_intf_pins gt_quad_0/GT_Serial]
  connect_bd_intf_net -intf_net pcie_cfg_control_1 [get_bd_intf_ports pcie_cfg_control] [get_bd_intf_pins pcie_versal_0/pcie_cfg_control]
  connect_bd_intf_net -intf_net pcie_cfg_interrupt_1 [get_bd_intf_ports pcie_cfg_interrupt] [get_bd_intf_pins pcie_versal_0/pcie_cfg_interrupt]
  connect_bd_intf_net -intf_net pcie_cfg_mgmt_1 [get_bd_intf_ports pcie_cfg_mgmt] [get_bd_intf_pins pcie_versal_0/pcie_cfg_mgmt]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX0 [get_bd_intf_pins pcie_phy/GT_RX0] [get_bd_intf_pins gt_quad_0/RX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX1 [get_bd_intf_pins pcie_phy/GT_RX1] [get_bd_intf_pins gt_quad_0/RX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX2 [get_bd_intf_pins pcie_phy/GT_RX2] [get_bd_intf_pins gt_quad_0/RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX3 [get_bd_intf_pins pcie_phy/GT_RX3] [get_bd_intf_pins gt_quad_0/RX3_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX0 [get_bd_intf_pins pcie_phy/GT_TX0] [get_bd_intf_pins gt_quad_0/TX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX1 [get_bd_intf_pins pcie_phy/GT_TX1] [get_bd_intf_pins gt_quad_0/TX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX2 [get_bd_intf_pins pcie_phy/GT_TX2] [get_bd_intf_pins gt_quad_0/TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX3 [get_bd_intf_pins pcie_phy/GT_TX3] [get_bd_intf_pins gt_quad_0/TX3_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_gt_rxmargin_q0 [get_bd_intf_pins pcie_phy/gt_rxmargin_q0] [get_bd_intf_pins gt_quad_0/gt_rxmargin_intf]
  connect_bd_intf_net -intf_net pcie_phy_pcie_mgt [get_bd_intf_ports pcie_mgt] [get_bd_intf_pins pcie_phy/pcie_mgt]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_command [get_bd_intf_pins pcie_phy/phy_mac_command] [get_bd_intf_pins pcie_versal_0/phy_mac_command]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_rx_margining [get_bd_intf_pins pcie_phy/phy_mac_rx_margining] [get_bd_intf_pins pcie_versal_0/phy_mac_rx_margining]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_status [get_bd_intf_pins pcie_phy/phy_mac_status] [get_bd_intf_pins pcie_versal_0/phy_mac_status]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_drive [get_bd_intf_pins pcie_phy/phy_mac_tx_drive] [get_bd_intf_pins pcie_versal_0/phy_mac_tx_drive]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_eq [get_bd_intf_pins pcie_phy/phy_mac_tx_eq] [get_bd_intf_pins pcie_versal_0/phy_mac_tx_eq]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins refclk_ibuf/CLK_IN_D]
  connect_bd_intf_net -intf_net pcie_versal_0_m_axis_cq [get_bd_intf_ports m_axis_cq] [get_bd_intf_pins pcie_versal_0/m_axis_cq]
  connect_bd_intf_net -intf_net pcie_versal_0_m_axis_rc [get_bd_intf_ports m_axis_rc] [get_bd_intf_pins pcie_versal_0/m_axis_rc]
  connect_bd_intf_net -intf_net pcie_versal_0_pcie_cfg_fc [get_bd_intf_ports pcie_cfg_fc] [get_bd_intf_pins pcie_versal_0/pcie_cfg_fc]
  connect_bd_intf_net -intf_net pcie_versal_0_pcie_cfg_mesg_rcvd [get_bd_intf_ports pcie_cfg_mesg_rcvd] [get_bd_intf_pins pcie_versal_0/pcie_cfg_mesg_rcvd]
  connect_bd_intf_net -intf_net pcie_versal_0_pcie_cfg_mesg_tx [get_bd_intf_ports pcie_cfg_mesg_tx] [get_bd_intf_pins pcie_versal_0/pcie_cfg_mesg_tx]
  connect_bd_intf_net -intf_net pcie_versal_0_pcie_cfg_status [get_bd_intf_ports pcie_cfg_status] [get_bd_intf_pins pcie_versal_0/pcie_cfg_status]
  connect_bd_intf_net -intf_net pcie_versal_0_pcie_transmit_fc [get_bd_intf_ports pcie_transmit_fc] [get_bd_intf_pins pcie_versal_0/pcie_transmit_fc]
  connect_bd_intf_net -intf_net pcie_versal_0_phy_mac_rx [get_bd_intf_pins pcie_phy/phy_mac_rx] [get_bd_intf_pins pcie_versal_0/phy_mac_rx]
  connect_bd_intf_net -intf_net pcie_versal_0_phy_mac_tx [get_bd_intf_pins pcie_phy/phy_mac_tx] [get_bd_intf_pins pcie_versal_0/phy_mac_tx]
  connect_bd_intf_net -intf_net pipe_rp_1 [get_bd_intf_ports pipe_rp] [get_bd_intf_pins pcie_versal_0/pcie_ext_pipe_rp]
  connect_bd_intf_net -intf_net s_axis_cc_1 [get_bd_intf_ports s_axis_cc] [get_bd_intf_pins pcie_versal_0/s_axis_cc]
  connect_bd_intf_net -intf_net s_axis_rq_1 [get_bd_intf_ports s_axis_rq] [get_bd_intf_pins pcie_versal_0/s_axis_rq]

  # Create port connections
  connect_bd_net -net bufg_gt_sysclk_BUFG_GT_O [get_bd_pins bufg_gt_sysclk/BUFG_GT_O] [get_bd_pins pcie_phy/phy_refclk] [get_bd_pins pcie_versal_0/sys_clk]
  connect_bd_net -net ccix_optimized_tlp_tx_and_rx_enable_1 [get_bd_ports ccix_optimized_tlp_tx_and_rx_enable] [get_bd_pins pcie_versal_0/ccix_optimized_tlp_tx_and_rx_enable]
  connect_bd_net -net const_1b0_dout [get_bd_pins const_1b0/dout] [get_bd_pins gt_quad_0/apb3clk]
  connect_bd_net -net const_1b1_dout [get_bd_pins const_1b1/dout] [get_bd_pins bufg_gt_sysclk/BUFG_GT_CE]
  connect_bd_net -net gt_quad_0_ch0_phyready [get_bd_pins gt_quad_0/ch0_phyready] [get_bd_pins pcie_phy/ch0_phyready]
  connect_bd_net -net gt_quad_0_ch0_phystatus [get_bd_pins gt_quad_0/ch0_phystatus] [get_bd_pins pcie_phy/ch0_phystatus]
  connect_bd_net -net gt_quad_0_ch0_rxoutclk [get_bd_pins gt_quad_0/ch0_rxoutclk] [get_bd_pins pcie_phy/gt_rxoutclk]
  connect_bd_net -net gt_quad_0_ch0_txoutclk [get_bd_pins gt_quad_0/ch0_txoutclk] [get_bd_pins pcie_phy/gt_txoutclk]
  connect_bd_net -net gt_quad_0_ch1_phyready [get_bd_pins gt_quad_0/ch1_phyready] [get_bd_pins pcie_phy/ch1_phyready]
  connect_bd_net -net gt_quad_0_ch1_phystatus [get_bd_pins gt_quad_0/ch1_phystatus] [get_bd_pins pcie_phy/ch1_phystatus]
  connect_bd_net -net gt_quad_0_ch2_phyready [get_bd_pins gt_quad_0/ch2_phyready] [get_bd_pins pcie_phy/ch2_phyready]
  connect_bd_net -net gt_quad_0_ch2_phystatus [get_bd_pins gt_quad_0/ch2_phystatus] [get_bd_pins pcie_phy/ch2_phystatus]
  connect_bd_net -net gt_quad_0_ch3_phyready [get_bd_pins gt_quad_0/ch3_phyready] [get_bd_pins pcie_phy/ch3_phyready]
  connect_bd_net -net gt_quad_0_ch3_phystatus [get_bd_pins gt_quad_0/ch3_phystatus] [get_bd_pins pcie_phy/ch3_phystatus]
  connect_bd_net -net pcie_phy_gt_pcieltssm [get_bd_pins pcie_phy/gt_pcieltssm] [get_bd_pins gt_quad_0/pcieltssm]
  connect_bd_net -net pcie_phy_gtrefclk [get_bd_pins pcie_phy/gtrefclk] [get_bd_pins gt_quad_0/GT_REFCLK0]
  connect_bd_net -net pcie_phy_pcierstb [get_bd_pins pcie_phy/pcierstb] [get_bd_pins gt_quad_0/ch0_pcierstb] [get_bd_pins gt_quad_0/ch1_pcierstb] [get_bd_pins gt_quad_0/ch2_pcierstb] [get_bd_pins gt_quad_0/ch3_pcierstb]
  connect_bd_net -net pcie_phy_phy_coreclk [get_bd_pins pcie_phy/phy_coreclk] [get_bd_pins pcie_versal_0/phy_coreclk]
  connect_bd_net -net pcie_phy_phy_mcapclk [get_bd_pins pcie_phy/phy_mcapclk] [get_bd_pins pcie_versal_0/phy_mcapclk]
  connect_bd_net -net pcie_phy_phy_pclk [get_bd_pins pcie_phy/phy_pclk] [get_bd_pins pcie_versal_0/phy_pclk] [get_bd_pins gt_quad_0/ch0_txusrclk] [get_bd_pins gt_quad_0/ch1_txusrclk] [get_bd_pins gt_quad_0/ch2_txusrclk] [get_bd_pins gt_quad_0/ch3_txusrclk] [get_bd_pins gt_quad_0/ch0_rxusrclk] [get_bd_pins gt_quad_0/ch1_rxusrclk] [get_bd_pins gt_quad_0/ch2_rxusrclk] [get_bd_pins gt_quad_0/ch3_rxusrclk]
  connect_bd_net -net pcie_phy_phy_userclk [get_bd_pins pcie_phy/phy_userclk] [get_bd_pins pcie_versal_0/phy_userclk]
  connect_bd_net -net pcie_phy_phy_userclk2 [get_bd_pins pcie_phy/phy_userclk2] [get_bd_pins pcie_versal_0/phy_userclk2]
  connect_bd_net -net pcie_versal_0_ccix_rx_credit_av [get_bd_pins pcie_versal_0/ccix_rx_credit_av] [get_bd_ports ccix_rx_credit_av]
  connect_bd_net -net pcie_versal_0_core_clk [get_bd_pins pcie_versal_0/core_clk] [get_bd_ports core_clk]
  connect_bd_net -net pcie_versal_0_pcie_ltssm_state [get_bd_pins pcie_versal_0/pcie_ltssm_state] [get_bd_pins pcie_phy/pcie_ltssm_state]
  connect_bd_net -net pcie_versal_0_phy_rdy_out [get_bd_pins pcie_versal_0/phy_rdy_out] [get_bd_ports phy_rdy_out]
  connect_bd_net -net pcie_versal_0_user_clk [get_bd_pins pcie_versal_0/user_clk] [get_bd_ports user_clk]
  connect_bd_net -net pcie_versal_0_user_lnk_up [get_bd_pins pcie_versal_0/user_lnk_up] [get_bd_ports user_lnk_up]
  connect_bd_net -net pcie_versal_0_user_reset [get_bd_pins pcie_versal_0/user_reset] [get_bd_ports user_reset]
  connect_bd_net -net refclk_ibuf_IBUF_DS_ODIV2 [get_bd_pins refclk_ibuf/IBUF_DS_ODIV2] [get_bd_pins bufg_gt_sysclk/BUFG_GT_I]
  connect_bd_net -net refclk_ibuf_IBUF_OUT [get_bd_pins refclk_ibuf/IBUF_OUT] [get_bd_pins pcie_phy/phy_gtrefclk] [get_bd_pins pcie_versal_0/sys_clk_gt]
  connect_bd_net -net sys_reset_1 [get_bd_ports sys_reset] [get_bd_pins pcie_phy/phy_rst_n] [get_bd_pins pcie_versal_0/sys_reset]

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


