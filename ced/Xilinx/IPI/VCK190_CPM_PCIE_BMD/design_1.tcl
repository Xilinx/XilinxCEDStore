
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
set scripts_vivado_version 2022.1
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
   set_property BOARD_PART xilinx.com:vck190:part0:2.3 [current_project]
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
xilinx.com:ip:xlconstant:1.1\
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
  set PCIE0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT_0 ]

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]

  set pcie0_cfg_control_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_control_rtl:1.0 pcie0_cfg_control_0 ]

  set pcie0_cfg_ext_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_ext_rtl:1.0 pcie0_cfg_ext_0 ]

  set pcie0_cfg_interrupt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie0_cfg_interrupt_0 ]

  set pcie0_cfg_mgmt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie0_cfg_mgmt_0 ]

  set pcie0_cfg_msg_recd_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie0_cfg_msg_recd_0 ]

  set pcie0_cfg_msix_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_msix_rtl:1.0 pcie0_cfg_msix_0 ]

  set pcie0_cfg_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie4_cfg_status_rtl:1.0 pcie0_cfg_status_0 ]

  set pcie0_m_axis_cq_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_m_axis_cq_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $pcie0_m_axis_cq_0

  set pcie0_m_axis_rc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_m_axis_rc_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $pcie0_m_axis_rc_0

  set pcie0_s_axis_cc_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_s_axis_cc_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {81} \
   ] $pcie0_s_axis_cc_0

  set pcie0_s_axis_rq_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_s_axis_rq_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {179} \
   ] $pcie0_s_axis_rq_0

  set pcie0_transmit_fc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie0_transmit_fc_0 ]


  # Create ports
  set pcie0_cfg_10b_tag_requester_enable_0 [ create_bd_port -dir O -from 3 -to 0 pcie0_cfg_10b_tag_requester_enable_0 ]
  set pcie0_cfg_atomic_requester_enable_0 [ create_bd_port -dir O -from 3 -to 0 pcie0_cfg_atomic_requester_enable_0 ]
  set pcie0_cfg_ext_tag_enable_0 [ create_bd_port -dir O pcie0_cfg_ext_tag_enable_0 ]
  set pcie0_cfg_fc_cpld_0 [ create_bd_port -dir O -from 11 -to 0 pcie0_cfg_fc_cpld_0 ]
  set pcie0_cfg_fc_cpld_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_cpld_scale_0 ]
  set pcie0_cfg_fc_cplh_0 [ create_bd_port -dir O -from 7 -to 0 pcie0_cfg_fc_cplh_0 ]
  set pcie0_cfg_fc_cplh_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_cplh_scale_0 ]
  set pcie0_cfg_fc_npd_0 [ create_bd_port -dir O -from 11 -to 0 pcie0_cfg_fc_npd_0 ]
  set pcie0_cfg_fc_npd_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_npd_scale_0 ]
  set pcie0_cfg_fc_nph_0 [ create_bd_port -dir O -from 7 -to 0 pcie0_cfg_fc_nph_0 ]
  set pcie0_cfg_fc_nph_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_nph_scale_0 ]
  set pcie0_cfg_fc_pd_0 [ create_bd_port -dir O -from 11 -to 0 pcie0_cfg_fc_pd_0 ]
  set pcie0_cfg_fc_pd_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_pd_scale_0 ]
  set pcie0_cfg_fc_ph_0 [ create_bd_port -dir O -from 7 -to 0 pcie0_cfg_fc_ph_0 ]
  set pcie0_cfg_fc_ph_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_ph_scale_0 ]
  set pcie0_cfg_fc_sel_0 [ create_bd_port -dir I -from 2 -to 0 pcie0_cfg_fc_sel_0 ]
  set pcie0_cfg_fc_vc_sel_0 [ create_bd_port -dir I pcie0_cfg_fc_vc_sel_0 ]
  set pcie0_cfg_msix_function_number_0 [ create_bd_port -dir I -from 7 -to 0 pcie0_cfg_msix_function_number_0 ]
  set pcie0_cfg_msix_mint_vector_0 [ create_bd_port -dir I -from 31 -to 0 pcie0_cfg_msix_mint_vector_0 ]
  set pcie0_user_clk_0 [ create_bd_port -dir O -type clk pcie0_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {pcie0_m_axis_cq_0:pcie0_m_axis_rc_0:pcie0_s_axis_cc_0:pcie0_s_axis_rq_0} \
   CONFIG.FREQ_HZ {250000000} \
 ] $pcie0_user_clk_0
  set_property CONFIG.ASSOCIATED_BUSIF.VALUE_SRC DEFAULT $pcie0_user_clk_0

  set pcie0_user_lnk_up_0 [ create_bd_port -dir O pcie0_user_lnk_up_0 ]
  set pcie0_user_reset_0 [ create_bd_port -dir O -type rst pcie0_user_reset_0 ]
  set pl_ref_clk [ create_bd_port -dir O pl_ref_clk ]
  set xdma0_usr_irq_fnc_0 [ create_bd_port -dir I -from 7 -to 0 xdma0_usr_irq_fnc_0 ]

  # Create instance: logic0, and set properties
  set logic0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $logic0

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.1 versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.CPM_CONFIG {\
     CPM_PCIE0_CFG_CTL_IF {1}\
     CPM_PCIE0_CFG_EXT_IF {1}\
     CPM_PCIE0_CFG_FC_IF {1}\
     CPM_PCIE0_CFG_MGMT_IF {1}\
     CPM_PCIE0_CFG_STS_IF {1}\
     CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s}\
     CPM_PCIE0_MESG_RSVD_IF {1}\
     CPM_PCIE0_MODES {PCIE}\
     CPM_PCIE0_MODE_SELECTION {Advanced}\
     CPM_PCIE0_MSI_X_OPTIONS {MSI-X_Internal}\
     CPM_PCIE0_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller}\
     CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1}\
     CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8}\
     CPM_PCIE0_TX_FC_IF {1}\
     CPM_PCIE0_TANDEM {Tandem_PROM}\
   } \
   CONFIG.DESIGN_MODE {1} \
   CONFIG.PS_PMC_CONFIG {\
     PMC_CRP_OSPI_REF_CTRL_FREQMHZ {135}\
     PMC_OSPI_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 11}} {MODE Single}}\
     PS_CRL_UART0_REF_CTRL_DIVISOR0 {12}\
     PS_CRL_UART0_REF_CTRL_SRCSEL {PPLL}\
     PS_CRL_UART1_REF_CTRL_DIVISOR0 {12}\
     PS_CRL_UART1_REF_CTRL_SRCSEL {PPLL}\
     PS_UART0_BAUD_RATE {115200}\
     PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 16 .. 17}}}\
     PS_UART1_BAUD_RATE {115200}\
     PS_UART1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 20 .. 21}}}\
     PS_PCIE_EP_RESET1_IO {PMC_MIO 38}\
     PS_PCIE_RESET {{ENABLE 1} {IO {PS_MIO 18 .. 19}}}\
     PS_USE_M_AXI_FPD {0}\
     PS_USE_PMCPL_CLK0 {1}\
     PMC_CRP_PL0_REF_CTRL_FREQMHZ {250}\
     SMON_ALARMS {Set_Alarms_On}\
     SMON_ENABLE_TEMP_AVERAGING {0}\
     SMON_TEMP_AVERAGING_SAMPLES {0}\
     PS_BOARD_INTERFACE {Custom}\
     DESIGN_MODE {1}\
     PS_PCIE1_PERIPHERAL_ENABLE {1}\
     PS_PCIE2_PERIPHERAL_ENABLE {0}\
     PCIE_APERTURES_SINGLE_ENABLE {0}\
     PCIE_APERTURES_DUAL_ENABLE {0}\
   } \
 ] $versal_cips_0

  # Create interface connections
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins versal_cips_0/gt_refclk0]
  connect_bd_intf_net -intf_net pcie0_cfg_control_0_1 [get_bd_intf_ports pcie0_cfg_control_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_control]
  connect_bd_intf_net -intf_net pcie0_cfg_interrupt_0_1 [get_bd_intf_ports pcie0_cfg_interrupt_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_interrupt]
  connect_bd_intf_net -intf_net pcie0_cfg_mgmt_0_1 [get_bd_intf_ports pcie0_cfg_mgmt_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_mgmt]
  connect_bd_intf_net -intf_net pcie0_cfg_msix_0_1 [get_bd_intf_ports pcie0_cfg_msix_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_msix]
  connect_bd_intf_net -intf_net pcie0_s_axis_cc_0_1 [get_bd_intf_ports pcie0_s_axis_cc_0] [get_bd_intf_pins versal_cips_0/pcie0_s_axis_cc]
  connect_bd_intf_net -intf_net pcie0_s_axis_rq_0_1 [get_bd_intf_ports pcie0_s_axis_rq_0] [get_bd_intf_pins versal_cips_0/pcie0_s_axis_rq]
  connect_bd_intf_net -intf_net versal_cips_0_PCIE0_GT [get_bd_intf_ports PCIE0_GT_0] [get_bd_intf_pins versal_cips_0/PCIE0_GT]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_cfg_ext [get_bd_intf_ports pcie0_cfg_ext_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_ext]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_cfg_msg_recd [get_bd_intf_ports pcie0_cfg_msg_recd_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_msg_recd]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_cfg_status [get_bd_intf_ports pcie0_cfg_status_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_status]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_m_axis_cq [get_bd_intf_ports pcie0_m_axis_cq_0] [get_bd_intf_pins versal_cips_0/pcie0_m_axis_cq]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_m_axis_rc [get_bd_intf_ports pcie0_m_axis_rc_0] [get_bd_intf_pins versal_cips_0/pcie0_m_axis_rc]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_transmit_fc [get_bd_intf_ports pcie0_transmit_fc_0] [get_bd_intf_pins versal_cips_0/pcie0_transmit_fc]

  # Create port connections
  connect_bd_net -net pcie0_cfg_msix_function_number_0_1 [get_bd_ports pcie0_cfg_msix_function_number_0] [get_bd_pins versal_cips_0/pcie0_cfg_msix_function_number]
  connect_bd_net -net pcie0_cfg_msix_mint_vector_0_1 [get_bd_ports pcie0_cfg_msix_mint_vector_0]
  connect_bd_net -net versal_cips_0_pcie0_cfg_10b_tag_requester_enable [get_bd_ports pcie0_cfg_10b_tag_requester_enable_0] [get_bd_pins versal_cips_0/pcie0_cfg_status_10b_tag_requester_enable]
  connect_bd_net -net versal_cips_0_pcie0_cfg_atomic_requester_enable [get_bd_ports pcie0_cfg_atomic_requester_enable_0] [get_bd_pins versal_cips_0/pcie0_cfg_status_atomic_requester_enable]
  connect_bd_net -net versal_cips_0_pcie0_cfg_ext_tag_enable [get_bd_ports pcie0_cfg_ext_tag_enable_0] [get_bd_pins versal_cips_0/pcie0_cfg_status_ext_tag_enable]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_cpld [get_bd_ports pcie0_cfg_fc_cpld_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_cpld]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_cpldscale [get_bd_ports pcie0_cfg_fc_cpld_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_cpld_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_cplh [get_bd_ports pcie0_cfg_fc_cplh_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_cplh]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_cplhscale [get_bd_ports pcie0_cfg_fc_cplh_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_cplh_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_npd [get_bd_ports pcie0_cfg_fc_npd_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_npd]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_npdscale [get_bd_ports pcie0_cfg_fc_npd_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_npd_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_nph [get_bd_ports pcie0_cfg_fc_nph_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_nph]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_nphscale [get_bd_ports pcie0_cfg_fc_nph_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_nph_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_pd [get_bd_ports pcie0_cfg_fc_pd_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_pd]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_pdscale [get_bd_ports pcie0_cfg_fc_pd_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_pd_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_ph [get_bd_ports pcie0_cfg_fc_ph_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_ph]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_phscale [get_bd_ports pcie0_cfg_fc_ph_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_ph_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_sel [get_bd_ports pcie0_cfg_fc_sel_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_sel]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_vc_sel [get_bd_ports pcie0_cfg_fc_vc_sel_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_vc_sel]
  connect_bd_net -net versal_cips_0_pcie0_user_clk [get_bd_ports pcie0_user_clk_0] [get_bd_pins versal_cips_0/pcie0_user_clk]
  connect_bd_net -net versal_cips_0_pcie0_user_lnk_up [get_bd_ports pcie0_user_lnk_up_0] [get_bd_pins versal_cips_0/pcie0_user_lnk_up]
  connect_bd_net -net versal_cips_0_pcie0_user_reset [get_bd_ports pcie0_user_reset_0] [get_bd_pins versal_cips_0/pcie0_user_reset]
  connect_bd_net -net xdma0_usr_irq_fnc_0_1 [get_bd_ports xdma0_usr_irq_fnc_0]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins logic0/dout] [get_bd_pins versal_cips_0/cpm_irq0] [get_bd_pins versal_cips_0/cpm_irq1]

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


