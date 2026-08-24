
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
   create_project project_1 myproj -part xc2vp3602-vsvc3340-2LHP-e-S
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
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:emb_mem_gen:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:axi_noc2:1.1\
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
  set CTRL1_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 CTRL1_GT_0 ]

  set ctrl1_gt_refclk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ctrl1_gt_refclk_0 ]


  # Create ports
  set dma1_irq_0 [ create_bd_port -dir O -from 127 -to 0 dma1_irq_0 ]

  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:1.0 ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL1_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL2_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL3_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE0_BASEADDR) {0x0500_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE0_LIMITADDR) {0x0500_0001_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE1_BASEADDR) {0x0500_0002_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE1_DEST) {CPM_AXI_PL1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE1_LIMITADDR) {0x0500_0003_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE2_BASEADDR) {0x0500_0004_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE2_DEST) {CPM_AXI_PL2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE2_LIMITADDR) {0x0500_0005_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE3_BASEADDR) {0x0500_0006_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE3_LIMITADDR) {0x0500_0007_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE4_BASEADDR) {0x0500_0008_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE4_DEST) {PCIE_AXI_NOC0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_DMA_APERTURE4_LIMITADDR) {0x0500_0009_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_BAR_NUM) {BAR_1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_FUNC) {PF*} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION0_TRGTADDR) {0x500_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_BAR_NUM) {BAR_2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_FUNC) {PF*} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION1_TRGTADDR) {0x500_0002_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION2_BAR_NUM) {BAR_3} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION2_TRGTADDR) {0x500_0004_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION3_BAR_NUM) {BAR_4} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION3_TRGTADDR) {0x500_0006_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION4_BAR_NUM) {BAR_5} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_INBOUND_REGION4_TRGTADDR) {0x500_0008_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_LANE_RATE) $lane_rate \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_LINK_WIDTH) $link_width \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE0_BASEADDR) {0x0500_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE0_LIMITADDR) {0x0500_0001_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE1_BASEADDR) {0x0500_0002_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE1_DEST) {CPM_AXI_PL1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE1_LIMITADDR) {0x500_0003_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE2_BASEADDR) {0x0500_0004_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE2_DEST) {CPM_AXI_PL2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE2_LIMITADDR) {0x0500_0005_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE3_BASEADDR) {0x0500_0006_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE3_DEST) {CPM_AXI_PL3} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE3_LIMITADDR) {0x0500_0006_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE4_BASEADDR) {0x0500_0008_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE4_DEST) {PCIE_AXI_NOC0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MMIO_APERTURE4_LIMITADDR) {0x0500_0009_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_MODE) {DMA_BRIDGE} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_DMA_APERTURES) {5} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_INBOUND_REGIONS) {5} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_MMIO_APERTURES) {5} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR0_SCALE) {Kilobytes} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR0_SIZE) {256} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR1_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR1_SIZE) {256} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR2_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR2_SIZE) {256} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR3_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR3_SIZE) {256} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR4_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR4_SIZE) {256} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR5_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BAR5_SIZE) {256} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PROTOCOL) {PCIE_6_1} \
    CONFIG.CPM6_CONFIG(CPM6_PL_AXIL_DBI1_IF) {0} \
    CONFIG.CPM6_CONFIG(PS_USE_NOC_AXI_PCIE0) {0} \
    CONFIG.CPM6_CONFIG(PS_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.CPM6_CONFIG(PS_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL1_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL2_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL3_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_LINK_WIDTH) $link_width \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_MODE) {DMA_BRIDGE} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_PROTOCOL) {PCIE_6_1} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PL1_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
    CONFIG.PS_PMC_CONFIG(PS_USE_NOC_AXI_PCIE0) {0} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK1) {1} \
  ] $ps_wizard_0


  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_0


  # Create instance: emb_mem_gen_0, and set properties
  set emb_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 emb_mem_gen_0 ]

  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_1


  # Create instance: emb_mem_gen_1, and set properties
  set emb_mem_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 emb_mem_gen_1 ]

  # Create instance: axi_bram_ctrl_2, and set properties
  set axi_bram_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_2 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_2


  # Create instance: emb_mem_gen_2, and set properties
  set emb_mem_gen_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 emb_mem_gen_2 ]

  # Create instance: axi_bram_ctrl_3, and set properties
  set axi_bram_ctrl_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_3 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_3


  # Create instance: emb_mem_gen_3, and set properties
  set emb_mem_gen_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 emb_mem_gen_3 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

  # Create instance: axi_noc2_0, and set properties
  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2:1.1 axi_noc2_0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {3} \
    CONFIG.NUM_SI {2} \
  ] $axi_noc2_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc2_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins $axi_noc2_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} }} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
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

  # Create instance: axi_bram_ctrl_4, and set properties
  set axi_bram_ctrl_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_4 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_4


  # Create instance: emb_mem_gen_4, and set properties
  set emb_mem_gen_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 emb_mem_gen_4 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins emb_mem_gen_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins emb_mem_gen_1/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins emb_mem_gen_2/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_3_BRAM_PORTA [get_bd_intf_pins emb_mem_gen_3/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_3/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_4_BRAM_PORTA [get_bd_intf_pins emb_mem_gen_4/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_4/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins axi_bram_ctrl_4/S_AXI] [get_bd_intf_pins axi_noc2_0/M00_AXI]
  connect_bd_intf_net -intf_net ctrl1_gt_refclk_0_1 [get_bd_intf_ports ctrl1_gt_refclk_0] [get_bd_intf_pins ps_wizard_0/ctrl1_gt_refclk]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S00_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC1] [get_bd_intf_pins axi_noc2_0/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_CTRL1_GT [get_bd_intf_ports CTRL1_GT_0] [get_bd_intf_pins ps_wizard_0/CTRL1_GT]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl0 [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins ps_wizard_0/cpm_axi_pl0]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl1 [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins ps_wizard_0/cpm_axi_pl1]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl2 [get_bd_intf_pins axi_bram_ctrl_2/S_AXI] [get_bd_intf_pins ps_wizard_0/cpm_axi_pl2]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl3 [get_bd_intf_pins axi_bram_ctrl_3/S_AXI] [get_bd_intf_pins ps_wizard_0/cpm_axi_pl3]

  # Create port connections
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_4/s_axi_aresetn]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn  [get_bd_pins proc_sys_reset_1/peripheral_aresetn] \
  [get_bd_pins axi_bram_ctrl_3/s_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn]
  connect_bd_net -net ps_wizard_0_arstn0  [get_bd_pins ps_wizard_0/arstn0] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net ps_wizard_0_arstn1  [get_bd_pins ps_wizard_0/arstn1] \
  [get_bd_pins proc_sys_reset_1/ext_reset_in]
  connect_bd_net -net ps_wizard_0_cpm_pcie_axi_noc0_clk  [get_bd_pins ps_wizard_0/cpm_pcie_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk0]
  connect_bd_net -net ps_wizard_0_cpm_pcie_axi_noc1_clk  [get_bd_pins ps_wizard_0/cpm_pcie_axi_noc1_clk] \
  [get_bd_pins axi_noc2_0/aclk1]
  connect_bd_net -net ps_wizard_0_dma1_irq  [get_bd_pins ps_wizard_0/dma1_irq] \
  [get_bd_ports dma1_irq_0]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] \
  [get_bd_pins ps_wizard_0/aclk0] \
  [get_bd_pins ps_wizard_0/pcie1_clk] \
  [get_bd_pins axi_bram_ctrl_4/s_axi_aclk] \
  [get_bd_pins axi_noc2_0/aclk2]
  connect_bd_net -net ps_wizard_0_pl1_ref_clk  [get_bd_pins ps_wizard_0/pl1_ref_clk] \
  [get_bd_pins axi_bram_ctrl_3/s_axi_aclk] \
  [get_bd_pins axi_bram_ctrl_2/s_axi_aclk] \
  [get_bd_pins proc_sys_reset_1/slowest_sync_clk] \
  [get_bd_pins ps_wizard_0/aclk1]

  # Create address segments
  assign_bd_address -offset 0xC0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x0001000000000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] -force
  assign_bd_address -offset 0x0001000002000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axi_bram_ctrl_3/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020100000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axi_bram_ctrl_4/S_AXI/Mem0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################


common::send_gid_msg -ssname BD::TCL -id 2052 -severity "CRITICAL WARNING" "This Tcl script was generated from a block design that is out-of-date/locked. It is possible that design <$design_name> may result in errors during construction."

create_root_design "" $link_width $lane_rate


