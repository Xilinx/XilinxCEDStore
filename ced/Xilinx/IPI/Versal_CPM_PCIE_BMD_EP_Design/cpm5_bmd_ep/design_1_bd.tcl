
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
  set gt_refclk1_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk1_0 ]

  set pcie1_s_axis_rq_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie1_s_axis_rq_0 ]
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
   ] $pcie1_s_axis_rq_0

  set pcie1_s_axis_cc_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie1_s_axis_cc_0 ]
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
   ] $pcie1_s_axis_cc_0

  set pcie1_cfg_interrupt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie1_cfg_interrupt_0 ]

  set PCIE1_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE1_GT_0 ]

  set pcie1_cfg_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie5_cfg_status_rtl:1.0 pcie1_cfg_status_0 ]

  set pcie1_m_axis_cq_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie1_m_axis_cq_0 ]

  set pcie1_m_axis_rc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie1_m_axis_rc_0 ]

  set pcie1_cfg_msg_tx_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_mesg_tx_rtl:1.0 pcie1_cfg_msg_tx_0 ]

  set pcie1_cfg_fc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.1 pcie1_cfg_fc_0 ]

  set pcie1_cfg_control_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie5_cfg_control_rtl:1.0 pcie1_cfg_control_0 ]

  set pcie1_cfg_mgmt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie1_cfg_mgmt_0 ]

  set pcie1_transmit_fc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie1_transmit_fc_0 ]

  set pcie1_cfg_msg_recd_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie1_cfg_msg_recd_0 ]

  set pcie1_cfg_msix_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_msix_rtl:1.0 pcie1_cfg_msix_0 ]


  # Create ports
  set cpm_irq1_0 [ create_bd_port -dir I -type intr cpm_irq1_0 ]
  set cpm_irq0_0 [ create_bd_port -dir I -type intr cpm_irq0_0 ]
  set pcie1_user_lnk_up_0 [ create_bd_port -dir O pcie1_user_lnk_up_0 ]
  set pcie1_user_reset_0 [ create_bd_port -dir O -type rst pcie1_user_reset_0 ]
  set cpm_misc_irq_0 [ create_bd_port -dir O -type intr cpm_misc_irq_0 ]
  set cpm_uncor_irq_0 [ create_bd_port -dir O -type intr cpm_uncor_irq_0 ]
  set cpm_cor_irq_0 [ create_bd_port -dir O -type intr cpm_cor_irq_0 ]
  set pcie1_user_clk_0 [ create_bd_port -dir O -type clk pcie1_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {pcie1_s_axis_rq_0:pcie1_s_axis_cc_0:pcie1_m_axis_rc_0:pcie1_m_axis_cq_0} \
   CONFIG.ASSOCIATED_RESET {pcie1_user_reset_0} \
 ] $pcie1_user_clk_0

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [list \
    CONFIG.CPM_CONFIG { \
      CPM_PCIE0_MODES {None} \
      CPM_PCIE1_AXISTEN_IF_ENABLE_CLIENT_TAG {1} \
      CPM_PCIE1_CFG_CTL_IF {1} \
      CPM_PCIE1_CFG_FC_IF {1} \
      CPM_PCIE1_CFG_MGMT_IF {1} \
      CPM_PCIE1_CFG_STS_IF {1} \
      CPM_PCIE1_MAX_LINK_SPEED {16.0_GT/s} \
      CPM_PCIE1_MESG_RSVD_IF {1} \
      CPM_PCIE1_MESG_TRANSMIT_IF {1} \
      CPM_PCIE1_MODES {PCIE} \
      CPM_PCIE1_MODE_SELECTION {Advanced} \
      CPM_PCIE1_MSI_X_OPTIONS {MSI-X_Internal} \
      CPM_PCIE1_PF0_DEV_CAP_EXT_TAG_EN {1} \
      CPM_PCIE1_PF0_MSIX_CAP_PBA_OFFSET {2000} \
      CPM_PCIE1_PF0_MSIX_CAP_TABLE_OFFSET {1000} \
      CPM_PCIE1_PF0_MSI_ENABLED {0} \
      CPM_PCIE1_TX_FC_IF {1} \
      CPM_PIPE_INTF_EN {1} \
    } \
    CONFIG.PS_PMC_CONFIG { \
      DESIGN_MODE {1} \
      PCIE_APERTURES_DUAL_ENABLE {0} \
      PCIE_APERTURES_SINGLE_ENABLE {0} \
      PS_BOARD_INTERFACE {Custom} \
      PS_PCIE1_PERIPHERAL_ENABLE {0} \
      PS_PCIE2_PERIPHERAL_ENABLE {1} \
      PS_PCIE_EP_RESET2_IO {PMC_MIO 39} \
      PS_PCIE_RESET {{ENABLE 1}} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
    CONFIG.PS_PMC_CONFIG_APPLIED {1} \
  ] $versal_cips_0


  # Create interface connections
  connect_bd_intf_net -intf_net gt_refclk1_0_1 [get_bd_intf_ports gt_refclk1_0] [get_bd_intf_pins versal_cips_0/gt_refclk1]
  connect_bd_intf_net -intf_net pcie1_cfg_control_0_1 [get_bd_intf_ports pcie1_cfg_control_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_control]
  connect_bd_intf_net -intf_net pcie1_cfg_interrupt_0_1 [get_bd_intf_ports pcie1_cfg_interrupt_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_interrupt]
  connect_bd_intf_net -intf_net pcie1_cfg_mgmt_0_1 [get_bd_intf_ports pcie1_cfg_mgmt_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_mgmt]
  connect_bd_intf_net -intf_net pcie1_cfg_msix_0_1 [get_bd_intf_ports pcie1_cfg_msix_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_msix]
  connect_bd_intf_net -intf_net pcie1_s_axis_cc_0_1 [get_bd_intf_ports pcie1_s_axis_cc_0] [get_bd_intf_pins versal_cips_0/pcie1_s_axis_cc]
  connect_bd_intf_net -intf_net pcie1_s_axis_rq_0_1 [get_bd_intf_ports pcie1_s_axis_rq_0] [get_bd_intf_pins versal_cips_0/pcie1_s_axis_rq]
  connect_bd_intf_net -intf_net versal_cips_0_PCIE1_GT [get_bd_intf_ports PCIE1_GT_0] [get_bd_intf_pins versal_cips_0/PCIE1_GT]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_cfg_fc [get_bd_intf_ports pcie1_cfg_fc_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_fc]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_cfg_msg_recd [get_bd_intf_ports pcie1_cfg_msg_recd_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_msg_recd]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_cfg_msg_tx [get_bd_intf_ports pcie1_cfg_msg_tx_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_msg_tx]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_cfg_status [get_bd_intf_ports pcie1_cfg_status_0] [get_bd_intf_pins versal_cips_0/pcie1_cfg_status]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_m_axis_cq [get_bd_intf_ports pcie1_m_axis_cq_0] [get_bd_intf_pins versal_cips_0/pcie1_m_axis_cq]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_m_axis_rc [get_bd_intf_ports pcie1_m_axis_rc_0] [get_bd_intf_pins versal_cips_0/pcie1_m_axis_rc]
  connect_bd_intf_net -intf_net versal_cips_0_pcie1_transmit_fc [get_bd_intf_ports pcie1_transmit_fc_0] [get_bd_intf_pins versal_cips_0/pcie1_transmit_fc]

  # Create port connections
  connect_bd_net -net cpm_irq0_0_1 [get_bd_ports cpm_irq0_0] [get_bd_pins versal_cips_0/cpm_irq0]
  connect_bd_net -net cpm_irq1_0_1 [get_bd_ports cpm_irq1_0] [get_bd_pins versal_cips_0/cpm_irq1]
  connect_bd_net -net versal_cips_0_cpm_cor_irq [get_bd_pins versal_cips_0/cpm_cor_irq] [get_bd_ports cpm_cor_irq_0]
  connect_bd_net -net versal_cips_0_cpm_misc_irq [get_bd_pins versal_cips_0/cpm_misc_irq] [get_bd_ports cpm_misc_irq_0]
  connect_bd_net -net versal_cips_0_cpm_uncor_irq [get_bd_pins versal_cips_0/cpm_uncor_irq] [get_bd_ports cpm_uncor_irq_0]
  connect_bd_net -net versal_cips_0_pcie1_user_clk [get_bd_pins versal_cips_0/pcie1_user_clk] [get_bd_ports pcie1_user_clk_0]
  connect_bd_net -net versal_cips_0_pcie1_user_lnk_up [get_bd_pins versal_cips_0/pcie1_user_lnk_up] [get_bd_ports pcie1_user_lnk_up_0]
  connect_bd_net -net versal_cips_0_pcie1_user_reset [get_bd_pins versal_cips_0/pcie1_user_reset] [get_bd_ports pcie1_user_reset_0]

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


