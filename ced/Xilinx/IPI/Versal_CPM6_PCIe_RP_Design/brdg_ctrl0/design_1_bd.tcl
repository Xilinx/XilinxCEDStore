
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
xilinx.com:ip:axi_noc2:1.1\
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


  # Create ports
  set pcie0_rstn_0 [ create_bd_port -dir O -type rst pcie0_rstn_0 ]
  set pl0_ref_clk [ create_bd_port -dir O -type clk pl0_ref_clk ]

  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_0 ]
  set_property -dict [list \
    CONFIG.INLINE_HDL {false} \
    CONFIG.NUM_CLKS {12} \
    CONFIG.NUM_MC {0} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {10} \
  ] $axi_noc2_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
 ] [get_bd_intf_pins $axi_noc2_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
 ] [get_bd_intf_pins $axi_noc2_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins $axi_noc2_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins $axi_noc2_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins $axi_noc2_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.R_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.W_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.REMAPS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins $axi_noc2_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
 ] [get_bd_intf_pins $axi_noc2_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40} \
   CONFIG.NOC_PARAMS {} \
 ] [get_bd_intf_pins $axi_noc2_0/S09_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S09_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk9]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S08_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk10]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M01_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk11]


  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:1.0 ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM6_CONFIG(CPM6_BOARD) {VPK360} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ASPM_L0P_SUPPORT) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ASPM_L1_SUPPORT) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_CFG_STATUS_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION0_BASEADDR) {0x000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION0_LIMITADDR) {0x000_ffff_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION0_MATCH_MODE) {Address} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION0_TRGTADDR) {0x000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_LANE_RATE) $lane_rate \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_LINK_WIDTH) $link_width \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MMIO_APERTURE0_BASEADDR) {0x0000_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MMIO_APERTURE0_DEST) {PCIE_AXI_NOC0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MMIO_APERTURE0_LIMITADDR) {0x0000_ffff_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MMIO_APERTURE1_BASEADDR) {0x0002_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MMIO_APERTURE1_DEST) {CPM_AXI_PL0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MMIO_APERTURE1_LIMITADDR) {0x0002_0001_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION1_BASEADDR) {0x002_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION1_LIMITADDR) {0x002_0001_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION1_MATCH_MODE) {Address} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION1_TRGTADDR) {0x002_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MODE) {BRIDGE} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_NUM_INBOUND_REGIONS) {2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_NUM_MMIO_APERTURES) {2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_NUM_OUTBOUND_REGIONS) {5} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_NUM_PS_APERTURES) {4} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION0_BASEADDR) {0x0000_e000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION0_LIMITADDR) {0x0000_e7ff_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION0_TRGTADDR) {0x0000_e000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION1_BASEADDR) {0x0006_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION1_LIMITADDR) {0x0006_001f_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION1_TARGET) {CFG_TYPE0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION1_TRGTADDR) {0x0006_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION2_BASEADDR) {0x0006_0020_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION2_LIMITADDR) {0x0006_ffff_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION2_TARGET) {CFG_TYPE1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION2_TRGTADDR) {0x0006_0020_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION3_BASEADDR) {0x0080_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION3_LIMITADDR) {0x009f_fffe_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION3_TRGTADDR) {0x0080_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION4_BASEADDR) {0x009f_ffff_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION4_LIMITADDR) {0x009f_ffff_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION4_MSG_CODE) {0x7e} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION4_TARGET) {MSG} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_OUTBOUND_REGION4_TRGTADDR) {0x009f_ffff_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PERST) {PS_MIO_18} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PERST_DIR) {out} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PME_D0_SUPPORT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PME_D1_SUPPORT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PME_D3COLD_SUPPORT) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PME_D3HOT_SUPPORT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PORT_TYPE) {PCIE_RP} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PROTOCOL) {PCIE_6_1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE0_BASEADDR) {0x0000_e000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE0_DEST) {DMA} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE0_LIMITADDR) {0x0000_e7ff_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE1_BASEADDR) {0x0006_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE1_DEST) {ECAM} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE1_LIMITADDR) {0x0006_ffff_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE2_BASEADDR) {0x0080_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE2_DEST) {DMA} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE2_LIMITADDR) {0x009f_fffe_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE3_BASEADDR) {0x009f_ffff_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE3_DEST) {DMA} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PS_APERTURE3_LIMITADDR) {0x009f_ffff_ffff} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_LINK_WIDTH) $link_width \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_MODE) {BRIDGE} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_PERST) {PS_MIO_18} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_PERST_DIR) {out} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_PROTOCOL) {PCIE_6_1} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO19) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE Unassigned OUTPUT_DATA default DIRECTION in} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO40) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION out} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO41) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION out} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_NOC_AXI_PMC0) {1} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_CCI_NOC) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_NOC_AXI_PCIE0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_RESET) {ENABLE 0 IO PS_MIO_18:19} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET1_IO) {PS_MIO_0} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET1_IO_DIR) {output} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET1_POLARITY) {Active_Low} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET2_IO) {PS_MIO_1} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET2_IO_DIR) {output} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET2_POLARITY) {Active_Low} \
    CONFIG.PS_PMC_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PS_MIO_16:17 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_46:47 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO_TREE_PERIPHERALS) {SD1(emmc)###SD1(emmc)#SD1(emmc)#SD1(emmc)#SD1(emmc)#SD1(emmc)######SD0(emmc)#SD0(emmc)#SD0(emmc)#SD0(emmc)##SD0(emmc)#####SD0(emmc)#################GPIO_1#GPIO_1#####UART_1#UART_1#####################UART_0#UART_0##PCIE######}\
    CONFIG.PS_PMC_CONFIG(PMC_MIO_TREE_SIGNALS) {clk###cmd#data[0]#data[1]#data[2]#data[3]######data[0]#data[1]#data[2]#data[3]##clk#####cmd#################gpio_1_pin[40]#gpio_1_pin[41]#####txd#rxd#####################rxd#txd##reset2_n######}\
    CONFIG.PS_PMC_CONFIG(PCIE_APERTURES_SINGLE_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PCIE_APERTURES_DUAL_ENABLE) {0} \
    CONFIG.PS_PMC_CONFIG(PS_TRISTATE_INVERTED) {1} \
    CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {0} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(CPM_PCIE0_TANDEM) {None} \
    CONFIG.PS_PMC_CONFIG(PS_BOARD_INTERFACE) {Custom} \
    CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
  ] $ps_wizard_0


  set emb_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 emb_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.MEMORY_TYPE {Single_Port_RAM} \
  ] $emb_mem_gen_0

  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SINGLE_PORT_BRAM {1} \
    CONFIG.ECC_TYPE {0} \
  ] $axi_bram_ctrl_0

  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl0 [get_bd_intf_pins ps_wizard_0/cpm_axi_pl0] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins emb_mem_gen_0/BRAM_PORTA]
  connect_bd_net -net ps_wizard_0_arstn0 [get_bd_pins ps_wizard_0/arstn0] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

  connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins axi_noc2_0/M00_AXI] [get_bd_intf_pins ps_wizard_0/CPM_NOC_AXI_PCIE0]
  connect_bd_intf_net -intf_net axi_noc2_0_M01_AXI [get_bd_intf_pins ps_wizard_0/NOC_AXI_PMC0] [get_bd_intf_pins axi_noc2_0/M01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_pcie0_cfg_status [get_bd_intf_ports pcie0_cfg_status_0] [get_bd_intf_pins ps_wizard_0/pcie0_cfg_status]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S09_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC1] [get_bd_intf_pins axi_noc2_0/S08_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins axi_noc2_0/S00_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC0] [get_bd_intf_pins axi_noc2_0/S07_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC1] [get_bd_intf_pins axi_noc2_0/S06_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC2 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC2] [get_bd_intf_pins axi_noc2_0/S05_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC3 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC3] [get_bd_intf_pins axi_noc2_0/S04_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_LPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S02_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_PMC_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S03_AXI]
  connect_bd_intf_net -intf_net ctrl0_gt_refclk_0_1 [get_bd_intf_ports ctrl0_gt_refclk_0] [get_bd_intf_pins ps_wizard_0/ctrl0_gt_refclk]
  connect_bd_intf_net -intf_net ps_wizard_0_CTRL0_GT [get_bd_intf_ports CTRL0_GT_0] [get_bd_intf_pins ps_wizard_0/CTRL0_GT]

  # Create port connections
  connect_bd_net -net ps_wizard_0_cpm_noc_axi_pcie0_clk  [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk2]
  connect_bd_net -net ps_wizard_0_cpm_pcie_axi_noc0_clk  [get_bd_pins ps_wizard_0/cpm_pcie_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk9]
  connect_bd_net -net ps_wizard_0_cpm_pcie_axi_noc1_clk  [get_bd_pins ps_wizard_0/cpm_pcie_axi_noc1_clk] \
  [get_bd_pins axi_noc2_0/aclk10]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] \
  [get_bd_pins axi_noc2_0/aclk0]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc1_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk1]
  connect_bd_net -net ps_wizard_0_fpd_cci_noc0_clk  [get_bd_pins ps_wizard_0/cpm_noc_axi_pcie0_clk] \
  [get_bd_pins axi_noc2_0/aclk8]
  connect_bd_net -net ps_wizard_0_fpd_cci_noc1_clk  [get_bd_pins ps_wizard_0/fpd_cci_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk7]
  connect_bd_net -net ps_wizard_0_fpd_cci_noc2_clk  [get_bd_pins ps_wizard_0/fpd_cci_noc1_clk] \
  [get_bd_pins axi_noc2_0/aclk6]
  connect_bd_net -net ps_wizard_0_fpd_cci_noc3_clk  [get_bd_pins ps_wizard_0/fpd_cci_noc2_clk] \
  [get_bd_pins axi_noc2_0/aclk5]
  connect_bd_net -net ps_wizard_0_lpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk3]
  connect_bd_net -net ps_wizard_0_noc_axi_pmc0_clk  [get_bd_pins ps_wizard_0/noc_axi_pmc0_clk] \
  [get_bd_pins axi_noc2_0/aclk11]
  connect_bd_net -net ps_wizard_0_pcie0_rstn  [get_bd_pins ps_wizard_0/pcie0_rstn] \
  [get_bd_ports pcie0_rstn_0]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_ports pl0_ref_clk] \
  [get_bd_pins ps_wizard_0/pcie0_clk] \
  [get_bd_pins ps_wizard_0/aclk0] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net ps_wizard_0_pmc_axi_noc0_clk  [get_bd_pins ps_wizard_0/fpd_cci_noc3_clk] \
  [get_bd_pins axi_noc2_0/aclk4]

  # Create address segments
  if {[llength [get_bd_addr_segs -quiet axi_bram_ctrl_0/S_AXI/Mem0]]} {
    assign_bd_address -force -offset 0x0000000200000000 -range 128K \
      [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0]
  }
  assign_bd_address
  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/cpm6_0_CPM/cpm6_0_psv_cpm6]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION1/pmcps_0_psv_noc_pcie_1]

  # Restore current instance
  current_bd_instance $oldCurInst

  # ---- Shared SoC platform (PS peripherals, address plan) ----------------
  # The design already has an axi_noc2, so platform_auto takes the ATTACH path:
  # it fills in PS properties left at the IP default and follows our addresses.
  # It never creates DDR in attach mode, so ::platform_ddr is ignored here.
  set ::platform_ddr 0
  source [file join [file dirname [file normalize [info script]]] .. platform run.tcl]
  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $link_width $lane_rate


