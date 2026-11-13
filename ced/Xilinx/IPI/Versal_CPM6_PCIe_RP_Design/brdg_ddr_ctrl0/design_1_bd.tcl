
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
xilinx.com:ip:axi_noc2:*\
xilinx.com:ip:ddrmc5_responder:*\
xilinx.com:ip:ps_wizard:*\
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
proc create_root_design { parentCell link_width lane_rate ide } {

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
  set CH0_LPDDR5_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 CH0_LPDDR5_0 ]

  set ctrl0_gt_refclk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ctrl0_gt_refclk_0 ]

  set CTRL0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 CTRL0_GT_0 ]

  set sys_clk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $sys_clk0_0

  set pcie0_cfg_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cpm6:pcie_cfg_status_rtl:1.0 pcie0_cfg_status_0 ]


  # Create ports
  set pcie0_rstn_0 [ create_bd_port -dir O -type rst pcie0_rstn_0 ]
  set pl0_ref_clk [ create_bd_port -dir O -type clk pl0_ref_clk ]

  # Create instance: axi_noc2_0, and set properties
  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_0 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CONFIG13_OPT) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_EXTENDED_DDRMC5E) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BG_WIDTH) {2} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BA_ADDR_WIDTH) {2} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {11087} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {22} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {1087} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {11} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {11087} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {22} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {1087} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {11} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INIT_TIMEOUT) {0X0068CF0E} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3125} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_X64_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_RDIMM_DUAL_SLOT) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {Differential} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
    CONFIG.DDRMC5_NUM_CH {1} \
    CONFIG.INLINE_HDL {false} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH0_LEGACY} \
    CONFIG.NUM_CLKS {12} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {1} \
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
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins $axi_noc2_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins $axi_noc2_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins $axi_noc2_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.R_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.W_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.REMAPS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins $axi_noc2_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {M01_AXI:0x40:M00_AXI:0x0} \
   CONFIG.NOC_PARAMS {} \
 ] [get_bd_intf_pins $axi_noc2_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }} \
   CONFIG.DEST_IDS {} \
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

  # Create instance: ddrmc5_responder_0 — behavioural LPDDR5 DRAM for simulation.
  # Sits on the DDRMC PHY bus so the controller has a device to talk to in sim;
  # synthesises to a pass-through for hardware. CONFIG mirrors axi_noc2's DDRMC5.
  set ddrmc5_responder_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddrmc5_responder ddrmc5_responder_0 ]
  set_property -dict [list \
    CONFIG.DDRMC5_CONTROLLERTYPE {LPDDR5_SDRAM} \
    CONFIG.DDRMC5_NUM_CH {1} \
  ] $ddrmc5_responder_0


  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0 ]
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
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_IDE_CAP_EN) $ide \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_LINK_IDE_STREAM_EN) $ide \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_SELECTIVE_IDE_STREAM_EN) $ide \
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
    CONFIG.CPM6_CONFIG(PMC_REFCLK_FREQ) {33.333} \
    CONFIG.CPM6_CONFIG(PS_HSDP_PROTOCOL) {JTAG} \
    CONFIG.CPM6_CONFIG(PS_HSDP_REFCLK_FREQ) {156.25} \
    CONFIG.CPM6_CONFIG(PS_USE_NOC_AXI_PCIE0) {1} \
    CONFIG.CPM6_CONFIG(PS_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.CPM6_CONFIG(PS_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_LINK_WIDTH) $link_width \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_MODE) {BRIDGE} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_PERST) {PS_MIO_18} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_PERST_DIR) {out} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_PROTOCOL) {PCIE_6_1} \
    CONFIG.PS_PMC_CONFIG(CPM6_PERIPHERAL_EN) {1} \
    CONFIG.PS_PMC_CONFIG(CPM_PCIE0_TANDEM) {None} \
    CONFIG.PS_PMC_CONFIG(DESIGN_MODE) {1} \
    CONFIG.PS_PMC_CONFIG(DIS_AUTO_POL_CHECK) {0} \
    CONFIG.PS_PMC_CONFIG(GT_REFCLK_MHZ) {156.25} \
    CONFIG.PS_PMC_CONFIG(JTAG_USERCODE) {0x0} \
    CONFIG.PS_PMC_CONFIG(OT_EAM_RESP) {SRST} \
    CONFIG.PS_PMC_CONFIG(PCIE_APERTURES_DUAL_ENABLE) {0} \
    CONFIG.PS_PMC_CONFIG(PCIE_APERTURES_SINGLE_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PMC_ALT_REF_CLK_FREQMHZ) {33.333} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_CFU_REF_CTRL_FREQMHZ) {320} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_DFT_OSC_REF_CTRL_DIVISOR0) {3} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_DFT_OSC_REF_CTRL_FREQMHZ) {400} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_DFT_OSC_REF_CTRL_SRCSEL) {PPLL} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_EFUSE_REF_CTRL_SRCSEL) {IRO_CLK/4} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_HSM0_REF_CTRL_FREQMHZ) {33.333} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_HSM1_REF_CTRL_FREQMHZ) {133.333} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_LSBUS_REF_CTRL_FREQMHZ) {100} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_NOC_REF_CTRL_FREQMHZ) {960} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_NPLL_CTRL_SRCSEL) {REF_CLK} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PPLL_CTRL_SRCSEL) {REF_CLK} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_SWITCH_TIMEOUT_CTRL_FREQMHZ) {1} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_TEST_PATTERN_REF_CTRL_DIVISOR0) {6} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_TEST_PATTERN_REF_CTRL_FREQMHZ) {200} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_TEST_PATTERN_REF_CTRL_SRCSEL) {PPLL} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_USB_SUSPEND_CTRL_FREQMHZ) {0.2} \
    CONFIG.PS_PMC_CONFIG(PMC_ERROR_TO_PL) {0} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO19) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE Unassigned OUTPUT_DATA default DIRECTION in} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO40) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION out} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO41) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION out} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO_TREE_PERIPHERALS) {SD1(emmc)###SD1(emmc)#SD1(emmc)#SD1(emmc)#SD1(emmc)#SD1(emmc)######SD0(emmc)#SD0(emmc)#SD0(emmc)#SD0(emmc)##SD0(emmc)#####SD0(emmc)#################GPIO_1#GPIO_1#####UART_1#UART_1#####################UART_0#UART_0##PCIE######}\
\
    CONFIG.PS_PMC_CONFIG(PMC_MIO_TREE_SIGNALS) {clk###cmd#data[0]#data[1]#data[2]#data[3]######data[0]#data[1]#data[2]#data[3]##clk#####cmd#################gpio_1_pin[40]#gpio_1_pin[41]#####txd#rxd#####################rxd#txd##reset2_n######}\
\
    CONFIG.PS_PMC_CONFIG(PMC_PL_ALT_REF_CLK_FREQMHZ) {33.333} \
    CONFIG.PS_PMC_CONFIG(PMC_REF_CLK_FREQMHZ) {33.333} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_NOC_AXI_PMC0) {1} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_PL_PMC_AUX_REF_CLK) {0} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PSPMC_MANUAL_CLK_ENABLE) {0} \
    CONFIG.PS_PMC_CONFIG(PS_BOARD_INTERFACE) {Custom} \
    CONFIG.PS_PMC_CONFIG(PS_CRF_ACPU_CTRL_FREQMHZ) {1000} \
    CONFIG.PS_PMC_CONFIG(PS_CRF_APLL_CTRL_SRCSEL) {REF_CLK} \
    CONFIG.PS_PMC_CONFIG(PS_CRF_DBG_FPD_CTRL_FREQMHZ) {334} \
    CONFIG.PS_PMC_CONFIG(PS_CRF_FPD_LSBUS_CTRL_FREQMHZ) {100} \
    CONFIG.PS_PMC_CONFIG(PS_CRF_FPD_TOP_SWITCH_CTRL_FREQMHZ) {550} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ) {480} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_CPU_R5_CTRL_FREQMHZ) {400} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_DBG_LPD_CTRL_FREQMHZ) {333} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_DBG_TSTMP_CTRL_FREQMHZ) {333} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_IOU_SWITCH_CTRL_FREQMHZ) {250} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_LPD_LSBUS_CTRL_FREQMHZ) {100} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_LPD_TOP_SWITCH_CTRL_FREQMHZ) {400} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_PSM_REF_CTRL_FREQMHZ) {300} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_RPLL_CTRL_SRCSEL) {REF_CLK} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_TIMESTAMP_REF_CTRL_FREQMHZ) {100} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_UART0_REF_CTRL_FREQMHZ) {100} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_UART1_REF_CTRL_FREQMHZ) {100} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_USB3_DUAL_REF_CTRL_ACT_FREQMHZ) {20} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_USB3_DUAL_REF_CTRL_DIVISOR0) {60} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_USB3_DUAL_REF_CTRL_FREQMHZ) {10} \
    CONFIG.PS_PMC_CONFIG(PS_CRL_USB3_DUAL_REF_CTRL_SRCSEL) {PPLL} \
    CONFIG.PS_PMC_CONFIG(PS_DDRC_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_DDR_RAM_HIGHADDR_OFFSET) {0x800000000} \
    CONFIG.PS_PMC_CONFIG(PS_DDR_RAM_LOWADDR_OFFSET) {0x80000000} \
    CONFIG.PS_PMC_CONFIG(PS_EN_AXI_STATUS_PORTS) {0} \
    CONFIG.PS_PMC_CONFIG(PS_EN_PORTS_CONTROLLER_BASED) {0} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_HSDP0_REFCLK) {0} \
    CONFIG.PS_PMC_CONFIG(PS_HSDP1_REFCLK) {0} \
    CONFIG.PS_PMC_CONFIG(PS_HSDP_INGRESS_TRAFFIC) {JTAG} \
    CONFIG.PS_PMC_CONFIG(PS_HSDP_SAME_EGRESS_AS_INGRESS_TRAFFIC) {1} \
    CONFIG.PS_PMC_CONFIG(PS_IRQ_USAGE) {CH0 0 CH1 0 CH2 0 CH3 0 CH4 0 CH5 0 CH6 0 CH7 0 CH8 0 CH9 0 CH10 0 CH11 0 CH12 0 CH13 0 CH14 0 CH15 0} \
    CONFIG.PS_PMC_CONFIG(PS_KAT_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_NUM_F2P0_INTR_INPUTS) {1} \
    CONFIG.PS_PMC_CONFIG(PS_NUM_F2P1_INTR_INPUTS) {1} \
    CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {0} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_RESET) {ENABLE 0 IO PS_MIO_18:19} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET1_IO) {PS_MIO_0} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET1_IO_DIR) {output} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET1_POLARITY) {Active_Low} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET2_IO) {PS_MIO_1} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET2_IO_DIR) {output} \
    CONFIG.PS_PMC_CONFIG(PS_PCIE_ROOT_RESET2_POLARITY) {Active_Low} \
    CONFIG.PS_PMC_CONFIG(PS_PMCPL_CLK0_BUF) {1} \
    CONFIG.PS_PMC_CONFIG(PS_PS_ENABLE) {0} \
    CONFIG.PS_PMC_CONFIG(PS_RED_KEY_CLEAR_ENABLE) {0} \
    CONFIG.PS_PMC_CONFIG(PS_RPU_COHERENCY) {0} \
    CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
    CONFIG.PS_PMC_CONFIG(PS_SLR_TYPE) {master} \
    CONFIG.PS_PMC_CONFIG(PS_TIE_MJTAG_TCK_TO_GND) {1} \
    CONFIG.PS_PMC_CONFIG(PS_TRISTATE_INVERTED) {1} \
    CONFIG.PS_PMC_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PS_MIO_16:17 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_46:47 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_CCI_NOC) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_NOC_AXI_PCIE0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
\
    CONFIG.PS_PMC_CONFIG(SUBPRESET1) {Custom} \
    CONFIG.PS_PMC_CONFIG(preset) {None} \
  ] $ps_wizard_0

  # IDE: PS peripherals used by the SEC firmware on R5_0
  if {$ide} {
    set_property -dict [list \
      CONFIG.PS_PMC_CONFIG(PS_UART0_BAUD_RATE) {115200} \
      CONFIG.PS_PMC_CONFIG(PS_UART1_BAUD_RATE) {115200} \
      CONFIG.PS_PMC_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
      CONFIG.PS_PMC_CONFIG(PS_TTC1_PERIPHERAL_ENABLE) {1} \
      CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
      CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_MASTER) {R5_0} \
    ] $ps_wizard_0
  }


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

  connect_bd_intf_net -intf_net axi_noc2_0_C0_CH0_LPDDR5 [get_bd_intf_pins axi_noc2_0/C0_CH0_LPDDR5] [get_bd_intf_pins ddrmc5_responder_0/CH0_LPDDR5_IN]
  connect_bd_intf_net -intf_net ddrmc5_responder_0_CH0_LPDDR5 [get_bd_intf_ports CH0_LPDDR5_0] [get_bd_intf_pins ddrmc5_responder_0/CH0_LPDDR5]
  connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins axi_noc2_0/M00_AXI] [get_bd_intf_pins ps_wizard_0/CPM_NOC_AXI_PCIE0]
  connect_bd_intf_net -intf_net axi_noc2_0_M01_AXI [get_bd_intf_pins ps_wizard_0/NOC_AXI_PMC0] [get_bd_intf_pins axi_noc2_0/M01_AXI]
  connect_bd_intf_net -intf_net ctrl0_gt_refclk_0_1 [get_bd_intf_ports ctrl0_gt_refclk_0] [get_bd_intf_pins ps_wizard_0/ctrl0_gt_refclk]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S09_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_CPM_PCIE_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/CPM_PCIE_AXI_NOC1] [get_bd_intf_pins axi_noc2_0/S08_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_CTRL0_GT [get_bd_intf_ports CTRL0_GT_0] [get_bd_intf_pins ps_wizard_0/CTRL0_GT]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins axi_noc2_0/S00_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC0] [get_bd_intf_pins axi_noc2_0/S07_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC1] [get_bd_intf_pins axi_noc2_0/S06_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC2 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC2] [get_bd_intf_pins axi_noc2_0/S05_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC3 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC3] [get_bd_intf_pins axi_noc2_0/S04_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_LPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S02_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_PMC_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S03_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_pcie0_cfg_status [get_bd_intf_ports pcie0_cfg_status_0] [get_bd_intf_pins ps_wizard_0/pcie0_cfg_status]
  connect_bd_intf_net -intf_net sys_clk0_1_1 [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins axi_noc2_0/sys_clk0]

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
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets ps_wizard_0_pcie0_rstn]
  set_property HDL_ATTRIBUTE.KEEP {true} [get_bd_nets ps_wizard_0_pcie0_rstn]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_ports pl0_ref_clk] \
  [get_bd_pins ps_wizard_0/pcie0_clk] \
  [get_bd_pins ps_wizard_0/aclk0] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net ps_wizard_0_pmc_axi_noc0_clk  [get_bd_pins ps_wizard_0/fpd_cci_noc3_clk] \
  [get_bd_pins axi_noc2_0/aclk4]

  # IDE: map the R5 window 0xE000_0000 onto the PCIe ECAM (must follow the M00-to-CPM connection)
  if {$ide} {
    set_property CONFIG.REMAPS {M00_AXI {{0xE000_0000 0x6_0000_0000 256M}}} [get_bd_intf_pins $axi_noc2_0/S03_AXI]
  }

  # Create address segments
  if {[llength [get_bd_addr_segs -quiet axi_bram_ctrl_0/S_AXI/Mem0]]} {
    assign_bd_address -force -offset 0x0000000200000000 -range 128K \
      [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0]
  }
  assign_bd_address
  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/cpm6_0_CPM/cpm6_0_psv_cpm6]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION1/pmcps_0_psv_noc_pcie_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION2/pmcps_0_psv_noc_pcie_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_IOMODULE/pmcps_0_psv_psm_iomodule_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_RAM_DATA/pmcps_0_psv_psm_ram_data_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_RAM_INSTR/pmcps_0_psv_psm_ram_instr_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_TMR_INJECT/pmcps_0_psv_psm_tmr_inject_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_TMR_MANAGER/pmcps_0_psv_psm_tmr_manager_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_R5_1_ATCM/pmcps_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_R5_1_BTCM/pmcps_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_R5_TCM_GLOBAL/pmcps_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/cpm6_0_CPM/cpm6_0_psv_cpm6]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION1/pmcps_0_psv_noc_pcie_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION2/pmcps_0_psv_noc_pcie_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_IOMODULE/pmcps_0_psv_psm_iomodule_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_RAM_DATA/pmcps_0_psv_psm_ram_data_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_RAM_INSTR/pmcps_0_psv_psm_ram_instr_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_TMR_INJECT/pmcps_0_psv_psm_tmr_inject_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_TMR_MANAGER/pmcps_0_psv_psm_tmr_manager_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_R5_1_ATCM/pmcps_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_R5_1_BTCM/pmcps_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_R5_TCM_GLOBAL/pmcps_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_IOMODULE/pmcps_0_psv_psm_iomodule_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_RAM_DATA/pmcps_0_psv_psm_ram_data_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_RAM_INSTR/pmcps_0_psv_psm_ram_instr_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_TMR_INJECT/pmcps_0_psv_psm_tmr_inject_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_TMR_MANAGER/pmcps_0_psv_psm_tmr_manager_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_PMC_ROM_INT/pmcps_0_psv_coresight_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A720_CTI_INT/pmcps_0_psv_coresight_a720_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A720_DBG_INT/pmcps_0_psv_coresight_a720_dbg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A720_ETM_INT/pmcps_0_psv_coresight_a720_etm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A720_PMU_INT/pmcps_0_psv_coresight_a720_pmu]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A721_CTI_INT/pmcps_0_psv_coresight_a721_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A721_DBG_INT/pmcps_0_psv_coresight_a721_dbg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A721_ETM_INT/pmcps_0_psv_coresight_a721_etm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A721_PMU_INT/pmcps_0_psv_coresight_a721_pmu]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_APU_CTI_INT/pmcps_0_psv_coresight_apu_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_APU_ELA_INT/pmcps_0_psv_coresight_apu_ela]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_APU_ETF_INT/pmcps_0_psv_coresight_apu_etf]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_APU_FUN_INT/pmcps_0_psv_coresight_apu_fun]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ATM_INT/pmcps_0_psv_coresight_cpm_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_CTI2A_INT/pmcps_0_psv_coresight_cpm_cti2a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_CTI2D_INT/pmcps_0_psv_coresight_cpm_cti2d]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ELA2A_INT/pmcps_0_psv_coresight_cpm_ela2a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ELA2B_INT/pmcps_0_psv_coresight_cpm_ela2b]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ELA2C_INT/pmcps_0_psv_coresight_cpm_ela2c]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ELA2D_INT/pmcps_0_psv_coresight_cpm_ela2d]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_FUN_INT/pmcps_0_psv_coresight_cpm_fun]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ROM_INT/pmcps_0_psv_coresight_cpm_rom]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_FPD_ATM_INT/pmcps_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_FPD_STM_INT/pmcps_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_LPD_ATM_INT/pmcps_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_IOMODULE/pmcps_0_psv_psm_iomodule_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_RAM_DATA/pmcps_0_psv_psm_ram_data_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_RAM_INSTR/pmcps_0_psv_psm_ram_instr_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_TMR_INJECT/pmcps_0_psv_psm_tmr_inject_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PSM_TMR_MANAGER/pmcps_0_psv_psm_tmr_manager_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/cpm6_0_CPM/cpm6_0_psv_cpm6]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_PMC_ROM_INT/pmcps_0_psv_coresight_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A720_CTI_INT/pmcps_0_psv_coresight_a720_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A720_DBG_INT/pmcps_0_psv_coresight_a720_dbg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A720_ETM_INT/pmcps_0_psv_coresight_a720_etm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A720_PMU_INT/pmcps_0_psv_coresight_a720_pmu]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A721_CTI_INT/pmcps_0_psv_coresight_a721_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A721_DBG_INT/pmcps_0_psv_coresight_a721_dbg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A721_ETM_INT/pmcps_0_psv_coresight_a721_etm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_A721_PMU_INT/pmcps_0_psv_coresight_a721_pmu]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_APU_CTI_INT/pmcps_0_psv_coresight_apu_cti]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_APU_ELA_INT/pmcps_0_psv_coresight_apu_ela]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_APU_ETF_INT/pmcps_0_psv_coresight_apu_etf]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_APU_FUN_INT/pmcps_0_psv_coresight_apu_fun]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ATM_INT/pmcps_0_psv_coresight_cpm_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_CTI2A_INT/pmcps_0_psv_coresight_cpm_cti2a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_CTI2D_INT/pmcps_0_psv_coresight_cpm_cti2d]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ELA2A_INT/pmcps_0_psv_coresight_cpm_ela2a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ELA2B_INT/pmcps_0_psv_coresight_cpm_ela2b]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ELA2C_INT/pmcps_0_psv_coresight_cpm_ela2c]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ELA2D_INT/pmcps_0_psv_coresight_cpm_ela2d]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_FUN_INT/pmcps_0_psv_coresight_cpm_fun]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_CPM_ROM_INT/pmcps_0_psv_coresight_cpm_rom]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_FPD_ATM_INT/pmcps_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_FPD_STM_INT/pmcps_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_CoreSight_LPD_ATM_INT/pmcps_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION1/pmcps_0_psv_noc_pcie_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION2/pmcps_0_psv_noc_pcie_2]


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

create_root_design "" $link_width $lane_rate $::ide
