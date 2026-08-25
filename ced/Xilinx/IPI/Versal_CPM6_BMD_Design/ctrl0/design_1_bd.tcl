
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
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc2vp3602-vsvc3340-3HP-e-S
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
xilinx.com:ip:ps_wizard:1.0\
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
proc create_root_design { parentCell link_width lane_rate } {

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







  set CTRL0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 CTRL0_GT_0 ]

  set ctrl0_gt_refclk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ctrl0_gt_refclk_0 ]

  set pcie0_cfg_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cpm6:pcie_cfg_status_rtl:1.0 pcie0_cfg_status_0 ]

  set pcie0_flr_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm6:pcie_flr_rtl:1.0 pcie0_flr_0 ]

  set pcie0_msi_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm6:pcie_msi_rtl:1.0 pcie0_msi_0 ]

  set pcie0_msix_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm6:pcie_msix_rtl:1.0 pcie0_msix_0 ]

  set pcie0_strm_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm6:pcie_strm_rtl:1.0 pcie0_strm_0 ]


  # Create ports
  set pl0_ref_clk_0 [ create_bd_port -dir O -type clk pl0_ref_clk_0 ]
  set pl0_resetn_0 [ create_bd_port -dir O -type rst pl0_resetn_0 ]
  set pcie0_rstn_0 [ create_bd_port -dir O -type rst pcie0_rstn_0 ]

  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:1.0 ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ASPM_L0P_SUPPORT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ASPM_L1_SUPPORT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ATS_PRI_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_CFG_STATUS_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_DEV_SERIAL_NO) {0xabcd_0000_0000_1234} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_DSN_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ECRC_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_FLR_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_IDE_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_LANE_RATE) $lane_rate \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_LINK_IDE_STREAM_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_LINK_WIDTH) $link_width \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MCAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PASID_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_BAR0_SIZE) {64} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_BAR1_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_BAR1_SIZE) {64} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_INTX_PIN) {INTA} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSIX_BIR) {BAR_1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSIX_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSIX_PBA_OFFSET) {0x8000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSIX_TABLE_OFFSET) {0x0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSIX_VECTORS) {2048} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSI_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSI_VECTORS) {32} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PME_D0_SUPPORT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PME_D1_SUPPORT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PME_D3COLD_SUPPORT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PME_D3HOT_SUPPORT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PRI_OST_PR_CAPACITY) {4} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PROTOCOL) PCIE_6_1 \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PTM_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_SELECTIVE_IDE_STREAM_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_TPH_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_VPD_CAP_EN) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_LINK_WIDTH) $link_width \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_PROTOCOL) PCIE_6_1 \
    CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
    CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
  ] $ps_wizard_0


  # Create interface connections
  connect_bd_intf_net -intf_net ctrl0_gt_refclk_0_1 [get_bd_intf_ports ctrl0_gt_refclk_0] [get_bd_intf_pins ps_wizard_0/ctrl0_gt_refclk]
  connect_bd_intf_net -intf_net pcie0_flr_0_1 [get_bd_intf_ports pcie0_flr_0] [get_bd_intf_pins ps_wizard_0/pcie0_flr]
  connect_bd_intf_net -intf_net pcie0_msi_0_1 [get_bd_intf_ports pcie0_msi_0] [get_bd_intf_pins ps_wizard_0/pcie0_msi]
  connect_bd_intf_net -intf_net pcie0_msix_0_1 [get_bd_intf_ports pcie0_msix_0] [get_bd_intf_pins ps_wizard_0/pcie0_msix]
  connect_bd_intf_net -intf_net pcie0_strm_0_1 [get_bd_intf_ports pcie0_strm_0] [get_bd_intf_pins ps_wizard_0/pcie0_strm]
  connect_bd_intf_net -intf_net ps_wizard_0_CTRL0_GT [get_bd_intf_ports CTRL0_GT_0] [get_bd_intf_pins ps_wizard_0/CTRL0_GT]
  connect_bd_intf_net -intf_net ps_wizard_0_pcie0_cfg_status [get_bd_intf_ports pcie0_cfg_status_0] [get_bd_intf_pins ps_wizard_0/pcie0_cfg_status]

  # Create port connections
  connect_bd_net -net ps_wizard_0_pcie0_rstn  [get_bd_pins ps_wizard_0/pcie0_rstn] \
  [get_bd_ports pcie0_rstn_0]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_ports pl0_ref_clk_0] \
  [get_bd_pins ps_wizard_0/pcie0_clk]
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_ports pl0_resetn_0]

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

create_root_design "" $link_width $lane_rate


