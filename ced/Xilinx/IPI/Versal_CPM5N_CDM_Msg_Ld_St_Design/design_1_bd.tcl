
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
   create_project project_1 myproj -part xcvn3716-vsvb2197-2LHP-e-S
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
xilinx.com:ip:smartconnect:*\
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:axi_dbg_hub:*\
xilinx.com:ip:axi_noc2:*\
xilinx.com:ip:axis_ila:*\
xilinx.com:ip:axis_noc:*\
xilinx.com:ip:ddrmc5_responder:*\
xilinx.com:ip:emb_mem_gen:*\
xilinx.com:ip:proc_sys_reset:*\
xilinx.com:ip:psx_wizard:*\
xilinx.com:ip:xlconstant:*\
xilinx.com:ip:xlslice:*\
xilinx.com:ip:c_counter_binary:*\
xilinx.com:ip:xlconcat:*\
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


# Hierarchical cell: gpio_dbg
proc create_hier_cell_gpio_dbg { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_gpio_dbg() - Empty argument(s)!"}
     return
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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir O -from 31 -to 0 dout
  create_bd_pin -dir I -type clk pl0_ref_clk_0

  # Create instance: c_counter_binary_0, and set properties
  set c_counter_binary_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary c_counter_binary_0 ]
  set_property CONFIG.Load {false} $c_counter_binary_0


  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {16} \
  ] $xlconstant_0


  # Create port connections
  connect_bd_net -net c_counter_binary_0_Q [get_bd_pins c_counter_binary_0/Q] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net psx_wizard_0_pl0_ref_clk1 [get_bd_pins pl0_ref_clk_0] [get_bd_pins c_counter_binary_0/CLK]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins xlconcat_0/dout] [get_bd_pins dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconstant_0/dout] [get_bd_pins xlconcat_0/In1]

  # Restore current instance
  current_bd_instance $oldCurInst
}


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
  set CH0_LPDDR5 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 CH0_LPDDR5 ]

  set CH1_LPDDR5 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 CH1_LPDDR5 ]

  set PCIE0_GT [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT ]

  set atg_axi [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 atg_axi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.ARUSER_WIDTH {8} \
   CONFIG.AWUSER_WIDTH {8} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {1} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {7} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {7} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $atg_axi

  set axil_cmdram [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 axil_cmdram ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {42} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $axil_cmdram

  set axil_csi_exdes [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 axil_csi_exdes ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {42} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $axil_csi_exdes

  set cdm_top_msgld_dat [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cpm5n:msgld_dat_rtl:1.0 cdm_top_msgld_dat ]

  set cdm_top_msgld_req [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm5n:msgld_req_rtl:1.0 cdm_top_msgld_req ]

  set cdm_top_msgst [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm5n:msgst_rtl:1.0 cdm_top_msgst ]

  set csi1_dst_crdt [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 csi1_dst_crdt ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {2} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $csi1_dst_crdt

  set csi1_local_crdt [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cpm5n:csi_local_crdt_rtl:1.0 csi1_local_crdt ]

  set csi1_npr_req [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi1_npr_req ]

  set csi1_prcmpl_req0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi1_prcmpl_req0 ]

  set csi1_prcmpl_req1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi1_prcmpl_req1 ]

  set csi1_resp0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi1_resp0 ]

  set csi1_resp1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_cpm5n:csi_seg_rtl:1.0 csi1_resp1 ]

  set gt_refclk0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0 ]

  set sys_clk_ddr [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk_ddr ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $sys_clk_ddr


  # Create ports
  set cpm_gpo [ create_bd_port -dir O -from 31 -to 0 cpm_gpo ]
  set csi1_es1_wa_en [ create_bd_port -dir I csi1_es1_wa_en ]
  set pl0_ref_clk_0 [ create_bd_port -dir O -type clk pl0_ref_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {axil_cmdram:atg_axi:csi1_dst_crdt:axil_csi_exdes} \
 ] $pl0_ref_clk_0
  set pl0_resetn_0 [ create_bd_port -dir O -type rst pl0_resetn_0 ]

  # Create instance: axi4_2axi4lite, and set properties
  set axi4_2axi4lite [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi4_2axi4lite ]
  set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {1} \
  ] $axi4_2axi4lite


  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_1 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SUPPORTS_NARROW_BURST {0} \
  ] $axi_bram_ctrl_1


  # Create instance: axi_bram_ctrl_2, and set properties
  set axi_bram_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_2 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SUPPORTS_NARROW_BURST {0} \
  ] $axi_bram_ctrl_2


  # Create instance: axi_dbg_hub_0, and set properties
  set axi_dbg_hub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dbg_hub axi_dbg_hub_0 ]

  # Create instance: axi_noc2_0, and set properties
  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_0 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG {DDRMC5_CONTROLLERTYPE LPDDR5_SDRAM DDRMC5_SPEED_GRADE LPDDR5-6400 DDRMC5_DEVICE_TYPE Components DDRMC5_F0_LP5_BANK_ARCH 16B DDRMC5_F1_LP5_BANK_ARCH 16B DDRMC5_DRAM_WIDTH x16 DDRMC5_DATA_WIDTH\
16 DDRMC5_ROW_ADDR_WIDTH 16 DDRMC5_COL_ADDR_WIDTH 6 DDRMC5_BA_ADDR_WIDTH 4 DDRMC5_BG_WIDTH 0 DDRMC5_BURST_ADDR_WIDTH 4 DDRMC5_NUM_RANKS 1 DDRMC5_LATENCY_MODE x16 DDRMC5_NUM_SLOTS 1 DDRMC5_NUM_CK 1 DDRMC5_NUM_CH\
2 DDRMC5_STACK_HEIGHT 1 DDRMC5_DRAM_SIZE 16Gb DDRMC5_MEMORY_DENSITY 2GB DDRMC5_DM_EN true DDRMC5_DQS_OSCI_EN ENABLE DDRMC5_SIDE_BAND_ECC false DDRMC5_INLINE_ECC false DDRMC5_DDR5_2T DISABLE DDRMC5_REFRESH_MODE\
NORMAL DDRMC5_REFRESH_TYPE ALL_BANK DDRMC5_FREQ_SWITCHING false DDRMC5_BACKGROUND_SCRUB false DDRMC5_SCRUB_SIZE 1 DDRMC5_MEM_FILL false DDRMC5_PERIODIC_READ ENABLE DDRMC5_USER_REFRESH false DDRMC5_WL_SET\
A DDRMC5_WR_DBI false DDRMC5_RD_DBI false DDRMC5_AUTO_PRECHARGE false DDRMC5_CRYPTO false DDRMC5_ON_DIE_ECC false DDRMC5_F0_TCK 2500 DDRMC5_INPUTCLK0_PERIOD 3125 DDRMC5_F0_TFAW 20000 DDRMC5_F0_DDR5_TRP\
18000 DDRMC5_F0_TRTP 7500 DDRMC5_F0_TRCD 18000 DDRMC5_TREFI 3906000 DDRMC5_DDR5_TRFC1 0 DDRMC5_DDR5_TRFC2 0 DDRMC5_DDR5_TRFCSB 0 DDRMC5_F0_TRAS 42000 DDRMC5_F0_TZQLAT 30000 DDRMC5_F0_DDR5_TCCD_L_WR 0 DDRMC5_F0_TXP\
7500 DDRMC5_F0_DDR5_TPD 0 DDRMC5_DDR5_TREFSBRD 0 DDRMC5_DDR5_TRFC1_DLR 0 DDRMC5_DDR5_TRFC1_DPR 0 DDRMC5_DDR5_TRFC2_DLR 0 DDRMC5_DDR5_TRFC2_DPR 0 DDRMC5_DDR5_TRFCSB_DLR 0 DDRMC5_DDR5_TREFSBRD_SLR 0 DDRMC5_DDR5_TREFSBRD_DLR\
0 DDRMC5_F0_CL 46 DDRMC5_F0_CWL 0 DDRMC5_F0_DDR5_TRRD_L 0 DDRMC5_F0_TCCD_L 17 DDRMC5_F0_DDR5_TCCD_L_WR2 0 DDRMC5_DDR5_TFAW_DLR 0 DDRMC5_F1_TCK 2500 DDRMC5_F1_TFAW 20000 DDRMC5_F1_DDR5_TRP 18000 DDRMC5_F1_TRTP\
7500 DDRMC5_F1_TRCD 18000 DDRMC5_F1_TRAS 42000 DDRMC5_F1_TZQLAT 30000 DDRMC5_F1_DDR5_TCCD_L_WR 0 DDRMC5_F1_TXP 7500 DDRMC5_F1_DDR5_TPD 0 DDRMC5_F1_CL 46 DDRMC5_F1_CWL 0 DDRMC5_F1_DDR5_TRRD_L 0 DDRMC5_F1_TCCD_L\
17 DDRMC5_F1_DDR5_TCCD_L_WR2 0 DDRMC5_LP5_TRFCAB 280000 DDRMC5_LP5_TRFCPB 140000 DDRMC5_LP5_TPBR2PBR 90000 DDRMC5_F0_LP5_TRPAB 21000 DDRMC5_F0_LP5_TRPPB 18000 DDRMC5_F0_LP5_TRRD 5000 DDRMC5_LP5_TPBR2ACT\
7500 DDRMC5_F0_LP5_TCSPD 12500 DDRMC5_F0_RL 9 DDRMC5_F0_WL 5 DDRMC5_F1_LP5_TRPAB 21000 DDRMC5_F1_LP5_TRPPB 18000 DDRMC5_F1_LP5_TRRD 5000 DDRMC5_F1_LP5_TCSPD 12500 DDRMC5_F1_RL 9 DDRMC5_F1_WL 5 DDRMC5_LP5_TRFMAB\
280000 DDRMC5_LP5_TRFMPB 190000 DDRMC5_SYSTEM_CLOCK Differential DDRMC5_UBLAZE_BLI_INTF false DDRMC5_REF_AND_PER_CAL_INTF false DDRMC5_PRE_DEF_ADDR_MAP_SEL ROW_BANK_COLUMN DDRMC5_USER_DEFINED_ADDRESS_MAP\
None DDRMC5_ADDRESS_MAP NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA3,BA2,BA1,BA0,CA5,CA4,CA3,CA2,NC,CA1,CA0,NC,NC,NC,NC,NA DDRMC5_MC0_CONFIG_SEL config9\
DDRMC5_LOW_TRFC_DPR false DDRMC5_NUM_MC 1 DDRMC5_NUM_MCP 1 DDRMC5_MAIN_DEVICE_TYPE Components DDRMC5_INTERLEAVE_SIZE 128 } \
    CONFIG.DDRMC5_INTERLEAVE_SIZE {128} \
    CONFIG.DDRMC5_NUM_CH {2} \
    CONFIG.NUM_CLKS {17} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MI {7} \
    CONFIG.NUM_SI {15} \
    CONFIG.SI_SIDEBAND_PINS {} \
  ] $axi_noc2_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.APERTURES {{0x203_0000_0000 1M}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.APERTURES {{0x203_00A0_0000 1M}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x203_0010_0000 1M}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_0/M02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc2_0/M03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc2_0/M04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.APERTURES {{0x203_0020_0000 2M}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_0/M05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x203_00B0_0000 1M}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_0/M06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M03_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M04_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M02_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M05_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M06_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M03_AXI:0x240:M04_AXI:0x180:M01_AXI:0x0:M02_AXI:0x100:M00_AXI:0x80:M05_AXI:0x40:M06_AXI:0xc0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc2_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M03_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M04_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M02_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M05_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M06_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M03_AXI:0x240:M04_AXI:0x180:M01_AXI:0x0:M02_AXI:0x100:M00_AXI:0x80:M05_AXI:0x40:M06_AXI:0xc0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc2_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M03_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M04_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M01_AXI {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M05_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M06_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M03_AXI:0x240:M04_AXI:0x180:M01_AXI:0x0:M02_AXI:0x100:M00_AXI:0x80:M05_AXI:0x40:M06_AXI:0xc0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc2_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M03_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M04_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M01_AXI {read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M05_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M06_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M03_AXI:0x240:M04_AXI:0x180:M01_AXI:0x0:M02_AXI:0x100:M00_AXI:0x80:M05_AXI:0x40:M06_AXI:0xc0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc2_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M03_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M04_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M02_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M05_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M06_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M03_AXI:0x240:M04_AXI:0x180:M01_AXI:0x0:M02_AXI:0x100:M00_AXI:0x80:M05_AXI:0x40:M06_AXI:0xc0} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc2_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {M04_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M04_AXI:0x180} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S09_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S10_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S11_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S12_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S13_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc2_0/S14_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M04_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI:M02_AXI:M05_AXI:M06_AXI:S05_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M03_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk9]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S08_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk10]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S09_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk11]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S10_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk12]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S11_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk13]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S12_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk14]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S13_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk15]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S14_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk16]

  # Create instance: axis_ila_0, and set properties
  set axis_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila axis_ila_0 ]
  set_property -dict [list \
    CONFIG.C_MON_TYPE {Interface_Monitor} \
    CONFIG.C_NUM_MONITOR_SLOTS {3} \
    CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:display_cpm5n:msgld_req_rtl:1.0} \
    CONFIG.C_SLOT_0_TYPE {0} \
    CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:display_cpm5n:msgst_rtl:1.0} \
    CONFIG.C_SLOT_1_TYPE {0} \
    CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:display_cpm5n:msgld_dat_rtl:1.0} \
    CONFIG.C_SLOT_2_TYPE {0} \
    CONFIG.C_SLOT_3_APC_EN {0} \
    CONFIG.C_SLOT_3_AXI_AR_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_AR_SEL_TRIG {1} \
    CONFIG.C_SLOT_3_AXI_AW_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_AW_SEL_TRIG {1} \
    CONFIG.C_SLOT_3_AXI_B_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_B_SEL_TRIG {1} \
    CONFIG.C_SLOT_3_AXI_R_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_R_SEL_TRIG {1} \
    CONFIG.C_SLOT_3_AXI_W_SEL_DATA {1} \
    CONFIG.C_SLOT_3_AXI_W_SEL_TRIG {1} \
  ] $axis_ila_0


  # Create instance: axis_noc_0, and set properties
  set axis_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_noc axis_noc_0 ]
  set_property -dict [list \
    CONFIG.MI_TDEST_VALS {,,,} \
    CONFIG.NUM_CLKS {8} \
    CONFIG.NUM_MI {4} \
    CONFIG.NUM_SI {4} \
  ] $axis_noc_0


  set_property -dict [ list \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.CATEGORY {dpu} \
 ] [get_bd_intf_pins /axis_noc_0/M00_AXIS]

  set_property -dict [ list \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.CATEGORY {dpu} \
 ] [get_bd_intf_pins /axis_noc_0/M01_AXIS]

  set_property -dict [ list \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.CATEGORY {dpu} \
 ] [get_bd_intf_pins /axis_noc_0/M02_AXIS]

  set_property -dict [ list \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.CATEGORY {dpu} \
 ] [get_bd_intf_pins /axis_noc_0/M03_AXIS]

  set_property -dict [ list \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.CONNECTIONS {M00_AXIS { write_bw {500} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {dpu} \
 ] [get_bd_intf_pins /axis_noc_0/S00_AXIS]

  set_property -dict [ list \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.CONNECTIONS {M01_AXIS { write_bw {500} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {dpu} \
 ] [get_bd_intf_pins /axis_noc_0/S01_AXIS]

  set_property -dict [ list \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.CONNECTIONS {M02_AXIS { write_bw {500} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {dpu} \
 ] [get_bd_intf_pins /axis_noc_0/S02_AXIS]

  set_property -dict [ list \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.CONNECTIONS {M03_AXIS { write_bw {500} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {dpu} \
 ] [get_bd_intf_pins /axis_noc_0/S03_AXIS]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXIS} \
 ] [get_bd_pins /axis_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXIS} \
 ] [get_bd_pins /axis_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXIS} \
 ] [get_bd_pins /axis_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXIS} \
 ] [get_bd_pins /axis_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXIS} \
 ] [get_bd_pins /axis_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M01_AXIS} \
 ] [get_bd_pins /axis_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M02_AXIS} \
 ] [get_bd_pins /axis_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M03_AXIS} \
 ] [get_bd_pins /axis_noc_0/aclk7]

  # Create instance: ddrmc5_responder_0, and set properties
  set ddrmc5_responder_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddrmc5_responder ddrmc5_responder_0 ]
  set_property CONFIG.DDRMC5_CONTROLLERTYPE {LPDDR5_SDRAM} $ddrmc5_responder_0


  # Create instance: emb_mem_gen_1, and set properties
  set emb_mem_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen emb_mem_gen_1 ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $emb_mem_gen_1


  # Create instance: emb_mem_gen_2, and set properties
  set emb_mem_gen_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen emb_mem_gen_2 ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $emb_mem_gen_2


  # Create instance: gpio_dbg
  create_hier_cell_gpio_dbg [current_bd_instance .] gpio_dbg

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: psx_wizard_0, and set properties
  set psx_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psx_wizard psx_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM_CONFIG(CPM_CDX_AXI_NOC_EN) {0} \
    CONFIG.CPM_CONFIG(CPM_CSI1_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_AXIS_NOC0_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_AXIS_NOC1_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_AXIS_NOC2_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_AXIS_NOC3_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_CMD1_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_CMD2_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_CMD3_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_CMD4_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_CMD6_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_CMD7_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_CMD8_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA10_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA11_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA12_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA13_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA1_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA2_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA3_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA4_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA5_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA6_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA7_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_DPU_DATA9_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_FLR_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_GPIO_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_HAH_IF) {1} \
    CONFIG.CPM_CONFIG(CPM_MPIO_BOT_PINMUX_MODE) {DPU} \
    CONFIG.CPM_CONFIG(CPM_MPIO_TOP_PINMUX_MODE) {DPU} \
    CONFIG.CPM_CONFIG(CPM_NOC_AXIS_DPU0_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_NOC_AXIS_DPU1_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_NOC_AXIS_DPU2_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_NOC_AXIS_DPU3_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_NOC_AXI_CDX_EN) {0} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_ATS_PRI_CAP_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_DEV_CAP_FLR_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MODES) {CDX} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MODE_SELECTION) {Advanced} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_MSI_X_OPTIONS) {MSI-X_Internal} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_64BIT) {0} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_PREFETCHABLE) {0} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_SCALE) {Megabytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR0_SIZE) {128} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR1_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR1_SIZE) {128} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_64BIT) {0} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_PREFETCHABLE) {0} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_SCALE) {Kilobytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR2_SIZE) {32} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR3_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR3_SIZE) {256} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR4_64BIT) {0} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR4_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR4_PREFETCHABLE) {0} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR4_SCALE) {Kilobytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR4_SIZE) {512} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR5_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR5_SCALE) {Megabytes} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_BAR5_SIZE) {64} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_MSIX_CAP_PBA_BIR) {BAR_2} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_MSIX_CAP_TABLE_BIR) {BAR_2} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PF0_SRIOV_BAR0_EN) {0} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PL_LINK_CAP_MAX_LINK_SPEED) {32.0_GT/s} \
    CONFIG.CPM_CONFIG(CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH) {X16} \
    CONFIG.CPM_CONFIG(CPM_PIPE_INTF_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_PRESET) {DPU_Hybrid_Top_PCIe0_G5x16} \
    CONFIG.CPM_CONFIG(CPM_TOP_HYBRID_MODE_EN) {1} \
    CONFIG.CPM_CONFIG(CPM_USE_MODE) {DPU} \
    CONFIG.CPM_CONFIG(PSX_USE_NOC_AXI_PCIE0) {1} \
    CONFIG.CPM_CONFIG(PSX_USE_PCIE_AXI_NOC0) {1} \
    CONFIG.CPM_CONFIG(PSX_USE_PCIE_AXI_NOC1) {1} \
    CONFIG.CPM_CONFIG(PSX_USE_PCIE_AXI_NOC2) {1} \
    CONFIG.CPM_CONFIG(PSX_USE_PCIE_AXI_NOC3) {1} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_CRP_OSPI_REF_CTRL_FREQMHZ) {100} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_CRP_PL0_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_EMMC) {CD_ENABLE 0 POW_ENABLE 0 WP_ENABLE 0 RESET_ENABLE 0 CD_IO PMCX_MIO_2 POW_IO PMCX_MIO_12 WP_IO PMCX_MIO_1 RESET_IO PMCX_MIO_25 CLK_50_SDR_ITAP_DLY 0x00 CLK_50_SDR_OTAP_DLY\
0x00 CLK_50_DDR_ITAP_DLY 0x00 CLK_50_DDR_OTAP_DLY 0x00 CLK_100_SDR_OTAP_DLY 0x00 CLK_200_SDR_OTAP_DLY 0x00} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_EMMC_DATA_TRANSFER_MODE) {4Bit} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_EMMC_PERIPHERAL) {PRIMARY_ENABLE 0 SECONDARY_ENABLE 0 IO PMCX_MIO_14:25 IO_TYPE MIO} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_MIO39) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_MIO40) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_MIO41) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_OSPI_ECC_FAIL_IO) {PMCX_MIO_13} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_OSPI_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 IO PMCX_MIO_0:13 MODE Single} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_REF_CLK_FREQMHZ) {33.33} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_USE_NOC_AXI_PMCX0) {1} \
    CONFIG.PSX_PMCX_CONFIG(PMCX_USE_PMCX_AXI_NOC0) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_FPD_AXI_PL_DATA_WIDTH) {32} \
    CONFIG.PSX_PMCX_CONFIG(PSX_NUM_FABRIC_RESETS) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_EP_RESET1_IO) {PMCX_MIO_38} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_EP_RESET2_IO) {None} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_EP_RESET3_IO) {None} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_EP_RESET4_IO) {None} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_RESET) {ENABLE 1 IO PSX_MIO_18:21} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_ROOT_RESET1_IO_DIR) {input} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_ROOT_RESET2_IO) {PMCX_MIO_1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_ROOT_RESET2_IO_DIR) {input} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_ROOT_RESET3_IO_DIR) {input} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PCIE_ROOT_RESET4_IO_DIR) {input} \
    CONFIG.PSX_PMCX_CONFIG(PSX_PL_AXI_FPD0_DATA_WIDTH) {32} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_FPD_AXI_NOC) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_FPD_AXI_PL) {0} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_LPD_AXI_NOC) {1} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_LPD_AXI_PL) {0} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_PL_AXI_FPD0) {0} \
    CONFIG.PSX_PMCX_CONFIG(PSX_USE_PMCPL_CLK0) {1} \
  ] $psx_wizard_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_0


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_0


  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net S05_AXI_0_1 [get_bd_intf_ports atg_axi] [get_bd_intf_pins axi_noc2_0/S05_AXI]
  connect_bd_intf_net -intf_net axi4_2axi4lite_M00_AXI [get_bd_intf_ports axil_cmdram] [get_bd_intf_pins axi4_2axi4lite/M00_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins emb_mem_gen_1/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTB] [get_bd_intf_pins emb_mem_gen_1/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTA] [get_bd_intf_pins emb_mem_gen_2/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTB] [get_bd_intf_pins emb_mem_gen_2/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_noc2_0_C0_CH0_LPDDR5 [get_bd_intf_pins axi_noc2_0/C0_CH0_LPDDR5] [get_bd_intf_pins ddrmc5_responder_0/CH0_LPDDR5_IN]
  connect_bd_intf_net -intf_net axi_noc2_0_C0_CH1_LPDDR5 [get_bd_intf_pins axi_noc2_0/C0_CH1_LPDDR5] [get_bd_intf_pins ddrmc5_responder_0/CH1_LPDDR5_IN]
  connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins axi_noc2_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_noc2_0_M01_AXI [get_bd_intf_pins axi_bram_ctrl_2/S_AXI] [get_bd_intf_pins axi_noc2_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_noc2_0_M02_AXI [get_bd_intf_pins axi4_2axi4lite/S00_AXI] [get_bd_intf_pins axi_noc2_0/M02_AXI]
  connect_bd_intf_net -intf_net axi_noc2_0_M03_AXI [get_bd_intf_pins axi_noc2_0/M03_AXI] [get_bd_intf_pins psx_wizard_0/NOC_AXI_PMCX0]
  connect_bd_intf_net -intf_net axi_noc2_0_M04_AXI [get_bd_intf_pins axi_noc2_0/M04_AXI] [get_bd_intf_pins psx_wizard_0/CPM_NOC_AXI_PCIE0]
  connect_bd_intf_net -intf_net axi_noc2_0_M05_AXI [get_bd_intf_pins axi_dbg_hub_0/S_AXI] [get_bd_intf_pins axi_noc2_0/M05_AXI]
  connect_bd_intf_net -intf_net axi_noc2_0_M06_AXI [get_bd_intf_pins axi_noc2_0/M06_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axis_noc_0_M00_AXIS [get_bd_intf_pins axis_noc_0/M00_AXIS] [get_bd_intf_pins psx_wizard_0/NOC_AXIS_DPU0]
  connect_bd_intf_net -intf_net axis_noc_0_M01_AXIS [get_bd_intf_pins axis_noc_0/M01_AXIS] [get_bd_intf_pins psx_wizard_0/NOC_AXIS_DPU1]
  connect_bd_intf_net -intf_net axis_noc_0_M02_AXIS [get_bd_intf_pins axis_noc_0/M02_AXIS] [get_bd_intf_pins psx_wizard_0/NOC_AXIS_DPU2]
  connect_bd_intf_net -intf_net axis_noc_0_M03_AXIS [get_bd_intf_pins axis_noc_0/M03_AXIS] [get_bd_intf_pins psx_wizard_0/NOC_AXIS_DPU3]
  connect_bd_intf_net -intf_net cdm_top_msgld_req_1 [get_bd_intf_ports cdm_top_msgld_req] [get_bd_intf_pins psx_wizard_0/cdm1_msgld_req]
connect_bd_intf_net -intf_net [get_bd_intf_nets cdm_top_msgld_req_1] [get_bd_intf_ports cdm_top_msgld_req] [get_bd_intf_pins axis_ila_0/SLOT_0_MSGLD_REQ]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cdm_top_msgld_req_1]
  connect_bd_intf_net -intf_net cdm_top_msgst_1 [get_bd_intf_ports cdm_top_msgst] [get_bd_intf_pins psx_wizard_0/cdm1_msgst]
connect_bd_intf_net -intf_net [get_bd_intf_nets cdm_top_msgst_1] [get_bd_intf_ports cdm_top_msgst] [get_bd_intf_pins axis_ila_0/SLOT_1_MSGST]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cdm_top_msgst_1]
  connect_bd_intf_net -intf_net csi1_dst_crdt_0_1 [get_bd_intf_ports csi1_dst_crdt] [get_bd_intf_pins psx_wizard_0/csi1_dst_crdt]
  connect_bd_intf_net -intf_net csi1_npr_req_0_1 [get_bd_intf_ports csi1_npr_req] [get_bd_intf_pins psx_wizard_0/csi1_npr_req]
  connect_bd_intf_net -intf_net csi1_prcmpl_req0_0_1 [get_bd_intf_ports csi1_prcmpl_req0] [get_bd_intf_pins psx_wizard_0/csi1_prcmpl_req0]
  connect_bd_intf_net -intf_net csi1_prcmpl_req1_0_1 [get_bd_intf_ports csi1_prcmpl_req1] [get_bd_intf_pins psx_wizard_0/csi1_prcmpl_req1]
  connect_bd_intf_net -intf_net ddrmc5_responder_0_CH0_LPDDR5 [get_bd_intf_ports CH0_LPDDR5] [get_bd_intf_pins ddrmc5_responder_0/CH0_LPDDR5]
  connect_bd_intf_net -intf_net ddrmc5_responder_0_CH1_LPDDR5 [get_bd_intf_ports CH1_LPDDR5] [get_bd_intf_pins ddrmc5_responder_0/CH1_LPDDR5]
  connect_bd_intf_net -intf_net gt_refclk0_1 [get_bd_intf_ports gt_refclk0] [get_bd_intf_pins psx_wizard_0/gt_refclk0]
  connect_bd_intf_net -intf_net psx_wizard_0_CPM_PCIE_AXI_NOC0 [get_bd_intf_pins axi_noc2_0/S00_AXI] [get_bd_intf_pins psx_wizard_0/CPM_PCIE_AXI_NOC0]
  connect_bd_intf_net -intf_net psx_wizard_0_CPM_PCIE_AXI_NOC1 [get_bd_intf_pins axi_noc2_0/S01_AXI] [get_bd_intf_pins psx_wizard_0/CPM_PCIE_AXI_NOC1]
  connect_bd_intf_net -intf_net psx_wizard_0_CPM_PCIE_AXI_NOC2 [get_bd_intf_pins axi_noc2_0/S02_AXI] [get_bd_intf_pins psx_wizard_0/CPM_PCIE_AXI_NOC2]
  connect_bd_intf_net -intf_net psx_wizard_0_CPM_PCIE_AXI_NOC3 [get_bd_intf_pins axi_noc2_0/S03_AXI] [get_bd_intf_pins psx_wizard_0/CPM_PCIE_AXI_NOC3]
  connect_bd_intf_net -intf_net psx_wizard_0_DPU_AXIS_NOC0 [get_bd_intf_pins axis_noc_0/S00_AXIS] [get_bd_intf_pins psx_wizard_0/DPU_AXIS_NOC0]
  connect_bd_intf_net -intf_net psx_wizard_0_DPU_AXIS_NOC1 [get_bd_intf_pins axis_noc_0/S01_AXIS] [get_bd_intf_pins psx_wizard_0/DPU_AXIS_NOC1]
  connect_bd_intf_net -intf_net psx_wizard_0_DPU_AXIS_NOC2 [get_bd_intf_pins axis_noc_0/S02_AXIS] [get_bd_intf_pins psx_wizard_0/DPU_AXIS_NOC2]
  connect_bd_intf_net -intf_net psx_wizard_0_DPU_AXIS_NOC3 [get_bd_intf_pins axis_noc_0/S03_AXIS] [get_bd_intf_pins psx_wizard_0/DPU_AXIS_NOC3]
  connect_bd_intf_net -intf_net psx_wizard_0_FPD_AXI_NOC0 [get_bd_intf_pins axi_noc2_0/S06_AXI] [get_bd_intf_pins psx_wizard_0/FPD_AXI_NOC0]
  connect_bd_intf_net -intf_net psx_wizard_0_FPD_AXI_NOC1 [get_bd_intf_pins axi_noc2_0/S07_AXI] [get_bd_intf_pins psx_wizard_0/FPD_AXI_NOC1]
  connect_bd_intf_net -intf_net psx_wizard_0_FPD_AXI_NOC2 [get_bd_intf_pins axi_noc2_0/S08_AXI] [get_bd_intf_pins psx_wizard_0/FPD_AXI_NOC2]
  connect_bd_intf_net -intf_net psx_wizard_0_FPD_AXI_NOC3 [get_bd_intf_pins axi_noc2_0/S09_AXI] [get_bd_intf_pins psx_wizard_0/FPD_AXI_NOC3]
  connect_bd_intf_net -intf_net psx_wizard_0_FPD_AXI_NOC4 [get_bd_intf_pins axi_noc2_0/S10_AXI] [get_bd_intf_pins psx_wizard_0/FPD_AXI_NOC4]
  connect_bd_intf_net -intf_net psx_wizard_0_FPD_AXI_NOC5 [get_bd_intf_pins axi_noc2_0/S11_AXI] [get_bd_intf_pins psx_wizard_0/FPD_AXI_NOC5]
  connect_bd_intf_net -intf_net psx_wizard_0_FPD_AXI_NOC6 [get_bd_intf_pins axi_noc2_0/S12_AXI] [get_bd_intf_pins psx_wizard_0/FPD_AXI_NOC6]
  connect_bd_intf_net -intf_net psx_wizard_0_FPD_AXI_NOC7 [get_bd_intf_pins axi_noc2_0/S13_AXI] [get_bd_intf_pins psx_wizard_0/FPD_AXI_NOC7]
  connect_bd_intf_net -intf_net psx_wizard_0_LPD_AXI_NOC0 [get_bd_intf_pins psx_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S14_AXI]
  connect_bd_intf_net -intf_net psx_wizard_0_PCIE0_GT [get_bd_intf_ports PCIE0_GT] [get_bd_intf_pins psx_wizard_0/PCIE0_GT]
  connect_bd_intf_net -intf_net psx_wizard_0_PMCX_AXI_NOC0 [get_bd_intf_pins axi_noc2_0/S04_AXI] [get_bd_intf_pins psx_wizard_0/PMCX_AXI_NOC0]
  connect_bd_intf_net -intf_net psx_wizard_0_cdm1_msgld_dat [get_bd_intf_ports cdm_top_msgld_dat] [get_bd_intf_pins psx_wizard_0/cdm1_msgld_dat]
connect_bd_intf_net -intf_net [get_bd_intf_nets psx_wizard_0_cdm1_msgld_dat] [get_bd_intf_ports cdm_top_msgld_dat] [get_bd_intf_pins axis_ila_0/SLOT_2_MSGLD_DAT]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets psx_wizard_0_cdm1_msgld_dat]
  connect_bd_intf_net -intf_net psx_wizard_0_csi1_local_crdt [get_bd_intf_ports csi1_local_crdt] [get_bd_intf_pins psx_wizard_0/csi1_local_crdt]
  connect_bd_intf_net -intf_net psx_wizard_0_csi1_resp0 [get_bd_intf_ports csi1_resp0] [get_bd_intf_pins psx_wizard_0/csi1_resp0]
  connect_bd_intf_net -intf_net psx_wizard_0_csi1_resp1 [get_bd_intf_ports csi1_resp1] [get_bd_intf_pins psx_wizard_0/csi1_resp1]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_ports axil_csi_exdes] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net sys_clk0_0_1 [get_bd_intf_ports sys_clk_ddr] [get_bd_intf_pins axi_noc2_0/sys_clk0]

  # Create port connections
  connect_bd_net -net csi1_es1_wa_en_0_1 [get_bd_ports csi1_es1_wa_en]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn] [get_bd_pins axi_dbg_hub_0/aresetn]
  connect_bd_net -net psx_wizard_0_cpm_gpo [get_bd_pins psx_wizard_0/cpm_gpo] [get_bd_ports cpm_gpo] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net psx_wizard_0_cpm_noc_axi_pcie0_clk [get_bd_pins psx_wizard_0/cpm_pcie_axi_noc3_clk] [get_bd_pins axi_noc2_0/aclk7]
  connect_bd_net -net psx_wizard_0_cpm_pcie_axi_noc0_clk [get_bd_pins psx_wizard_0/cpm_noc_axi_pcie0_clk] [get_bd_pins axi_noc2_0/aclk0]
  connect_bd_net -net psx_wizard_0_cpm_pcie_axi_noc1_clk [get_bd_pins psx_wizard_0/cpm_pcie_axi_noc0_clk] [get_bd_pins axi_noc2_0/aclk1]
  connect_bd_net -net psx_wizard_0_cpm_pcie_axi_noc2_clk [get_bd_pins psx_wizard_0/cpm_pcie_axi_noc1_clk] [get_bd_pins axi_noc2_0/aclk2]
  connect_bd_net -net psx_wizard_0_cpm_pcie_axi_noc3_clk [get_bd_pins psx_wizard_0/cpm_pcie_axi_noc2_clk] [get_bd_pins axi_noc2_0/aclk3]
  connect_bd_net -net psx_wizard_0_dpu_axis_noc0_clk [get_bd_pins psx_wizard_0/dpu_axis_noc0_clk] [get_bd_pins axis_noc_0/aclk0]
  connect_bd_net -net psx_wizard_0_dpu_axis_noc1_clk [get_bd_pins psx_wizard_0/dpu_axis_noc1_clk] [get_bd_pins axis_noc_0/aclk1]
  connect_bd_net -net psx_wizard_0_dpu_axis_noc2_clk [get_bd_pins psx_wizard_0/dpu_axis_noc2_clk] [get_bd_pins axis_noc_0/aclk2]
  connect_bd_net -net psx_wizard_0_dpu_axis_noc3_clk [get_bd_pins psx_wizard_0/dpu_axis_noc3_clk] [get_bd_pins axis_noc_0/aclk3]
  connect_bd_net -net psx_wizard_0_fpd_axi_noc0_clk [get_bd_pins psx_wizard_0/fpd_axi_noc0_clk] [get_bd_pins axi_noc2_0/aclk8]
  connect_bd_net -net psx_wizard_0_fpd_axi_noc1_clk [get_bd_pins psx_wizard_0/fpd_axi_noc1_clk] [get_bd_pins axi_noc2_0/aclk9]
  connect_bd_net -net psx_wizard_0_fpd_axi_noc2_clk [get_bd_pins psx_wizard_0/fpd_axi_noc2_clk] [get_bd_pins axi_noc2_0/aclk10]
  connect_bd_net -net psx_wizard_0_fpd_axi_noc3_clk [get_bd_pins psx_wizard_0/fpd_axi_noc3_clk] [get_bd_pins axi_noc2_0/aclk11]
  connect_bd_net -net psx_wizard_0_fpd_axi_noc4_clk [get_bd_pins psx_wizard_0/fpd_axi_noc4_clk] [get_bd_pins axi_noc2_0/aclk12]
  connect_bd_net -net psx_wizard_0_fpd_axi_noc5_clk [get_bd_pins psx_wizard_0/fpd_axi_noc5_clk] [get_bd_pins axi_noc2_0/aclk13]
  connect_bd_net -net psx_wizard_0_fpd_axi_noc6_clk [get_bd_pins psx_wizard_0/fpd_axi_noc6_clk] [get_bd_pins axi_noc2_0/aclk14]
  connect_bd_net -net psx_wizard_0_fpd_axi_noc7_clk [get_bd_pins psx_wizard_0/fpd_axi_noc7_clk] [get_bd_pins axi_noc2_0/aclk15]
  connect_bd_net -net psx_wizard_0_lpd_axi_noc0_clk [get_bd_pins psx_wizard_0/lpd_axi_noc0_clk] [get_bd_pins axi_noc2_0/aclk16]
  connect_bd_net -net psx_wizard_0_noc_axi_pmcx0_clk [get_bd_pins psx_wizard_0/noc_axi_pmcx0_clk] [get_bd_pins axi_noc2_0/aclk6]
  connect_bd_net -net psx_wizard_0_noc_axis_dpu0_clk [get_bd_pins psx_wizard_0/noc_axis_dpu0_clk] [get_bd_pins axis_noc_0/aclk4]
  connect_bd_net -net psx_wizard_0_noc_axis_dpu1_clk [get_bd_pins psx_wizard_0/noc_axis_dpu1_clk] [get_bd_pins axis_noc_0/aclk5]
  connect_bd_net -net psx_wizard_0_noc_axis_dpu2_clk [get_bd_pins psx_wizard_0/noc_axis_dpu2_clk] [get_bd_pins axis_noc_0/aclk6]
  connect_bd_net -net psx_wizard_0_noc_axis_dpu3_clk [get_bd_pins psx_wizard_0/noc_axis_dpu3_clk] [get_bd_pins axis_noc_0/aclk7]
  connect_bd_net -net psx_wizard_0_pl0_ref_clk1 [get_bd_pins psx_wizard_0/pl0_ref_clk] [get_bd_ports pl0_ref_clk_0] [get_bd_pins axi4_2axi4lite/aclk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins axi_bram_ctrl_2/s_axi_aclk] [get_bd_pins axi_dbg_hub_0/aclk] [get_bd_pins axi_noc2_0/aclk4] [get_bd_pins axis_ila_0/clk] [get_bd_pins gpio_dbg/pl0_ref_clk_0] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins psx_wizard_0/cpm_bot_user_clk] [get_bd_pins psx_wizard_0/cpm_top_user_clk] [get_bd_pins smartconnect_0/aclk]
  connect_bd_net -net psx_wizard_0_pl0_resetn1 [get_bd_pins psx_wizard_0/pl0_resetn] [get_bd_ports pl0_resetn_0] [get_bd_pins axi4_2axi4lite/aresetn] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins psx_wizard_0/cdx_bot_rst_n] [get_bd_pins psx_wizard_0/cdx_top_rst_n] [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net psx_wizard_0_pmcx_axi_noc0_clk [get_bd_pins psx_wizard_0/pmcx_axi_noc0_clk] [get_bd_pins axi_noc2_0/aclk5]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins gpio_dbg/dout] [get_bd_pins psx_wizard_0/cpm_gpi]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconstant_0/dout] [get_bd_pins emb_mem_gen_1/regcea] [get_bd_pins emb_mem_gen_1/regceb] [get_bd_pins emb_mem_gen_2/regcea] [get_bd_pins emb_mem_gen_2/regceb]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins xlslice_0/Dout]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_NOCPSPCIE_REGION0/psxl_0_psx_noc_pcie_0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_10] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_11] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_12] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_13] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_14] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_15] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_8] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexa78_9] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexr52_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexr52_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexr52_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cortexr52_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x020300000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300200000 -range 0x00200000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x020300100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs axil_cmdram/Reg] -force
  assign_bd_address -offset 0x020300B00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs axil_csi_exdes/Reg] -force
  assign_bd_address -offset 0x020380800000 -range 0x00004000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_PMC_ROM_EXT/psxl_0_psx_coresight_0] -force
  assign_bd_address -offset 0x020380A40000 -range 0x00004000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_FPD_STM_EXT/psxl_0_psx_coresight_fpd_stm] -force
  assign_bd_address -offset 0x0203808F0000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_LPD_ATM_EXT/psxl_0_psx_coresight_lpd_atm] -force
  assign_bd_address -offset 0xE4000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CPM/psxl_0_psx_cpm] -force
  assign_bd_address -offset 0x100000000000 -range 0x080000000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CPM_CDX_DPU_HIGH/psxl_0_psx_cpm_cdx_dpu_high] -force
  assign_bd_address -offset 0x020381260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CRP_EXT/psxl_0_psx_crp_0] -force
  assign_bd_address -offset 0xEB5B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_LPD_SYSTMR_CTRL/psxl_0_psx_lpd_systmr_ctrl] -force
  assign_bd_address -offset 0xEB5A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_LPD_SYSTMR_READ/psxl_0_psx_lpd_systmr_read] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_NOCPSPCIE_REGION0/psxl_0_psx_noc_pcie_0] -force
  assign_bd_address -offset 0xBBF00000 -range 0x00080000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OCM0_MEM/psxl_0_psx_ocm_ram_0] -force
  assign_bd_address -offset 0xBBF80000 -range 0x00080000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OCM1_MEM/psxl_0_psx_ocm_ram_1] -force
  assign_bd_address -offset 0x0203811E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_AES_EXT/psxl_0_psx_pmc_aes] -force
  assign_bd_address -offset 0x0203811F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_BBRAM_CTRL_EXT/psxl_0_psx_pmc_bbram_ctrl] -force
  assign_bd_address -offset 0x0203812D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFRAME0_REG_EXT/psxl_0_psx_pmc_cfi_cframe_0] -force
  assign_bd_address -offset 0x0203812B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFU_APB_EXT/psxl_0_psx_pmc_cfu_apb_0] -force
  assign_bd_address -offset 0x0203811C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA0_EXT/psxl_0_psx_pmc_dma_0] -force
  assign_bd_address -offset 0x0203811D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA1_EXT/psxl_0_psx_pmc_dma_1] -force
  assign_bd_address -offset 0x020381250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CACHE_EXT/psxl_0_psx_pmc_efuse_cache] -force
  assign_bd_address -offset 0x020381240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CTRL_EXT/psxl_0_psx_pmc_efuse_ctrl] -force
  assign_bd_address -offset 0x020381110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_GLOBAL_EXT/psxl_0_psx_pmc_global_0] -force
  assign_bd_address -offset 0x020380300000 -range 0x00001000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_IOMODULE_EXT/psxl_0_psx_pmc_iomodule_0] -force
  assign_bd_address -offset 0x020380310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_MDM_HSD_EXT/psxl_0_psx_pmc_ppu1_mdm_0] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OSPI_QSPI_FLASH/psxl_0_psx_pmc_qspi_ospi_flash_0] -force
  assign_bd_address -offset 0x020382000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_EXT/psxl_0_psx_pmc_ram] -force
  assign_bd_address -offset 0x020380280000 -range 0x00020000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_DATA_EXT/psxl_0_psx_pmc_ram_data_cntlr] -force
  assign_bd_address -offset 0x020380200000 -range 0x00040000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_INSTR_EXT/psxl_0_psx_pmc_ram_instr_cntlr] -force
  assign_bd_address -offset 0x020386000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_NPI_EXT/psxl_0_psx_pmc_ram_npi] -force
  assign_bd_address -offset 0x020381200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ECDSA_RSA_EXT/psxl_0_psx_pmc_rsa] -force
  assign_bd_address -offset 0x0203812A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RTC_EXT/psxl_0_psx_pmc_rtc_0] -force
  assign_bd_address -offset 0x020381210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_SHA3_EXT/psxl_0_psx_pmc_sha] -force
  assign_bd_address -offset 0x020381220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_EXT/psxl_0_psx_pmc_slave_boot] -force
  assign_bd_address -offset 0x020382100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_STREAM_EXT/psxl_0_psx_pmc_slave_boot_stream] -force
  assign_bd_address -offset 0x020381270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SYSMON_EXT/psxl_0_psx_pmc_sysmon_0] -force
  assign_bd_address -offset 0x020380083000 -range 0x00001000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU0_TMR_INJECT_EXT/psxl_0_psx_pmc_tmr_inject_0] -force
  assign_bd_address -offset 0x020380303000 -range 0x00001000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_TMR_MANAGER_EXT/psxl_0_psx_pmc_tmr_manager_0] -force
  assign_bd_address -offset 0x020381230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PSX_PMC_TRNG_EXT/psxl_0_psx_pmc_trng] -force
  assign_bd_address -offset 0x0203812F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XMPU_EXT/psxl_0_psx_pmc_xmpu_0] -force
  assign_bd_address -offset 0x020381310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_EXT/psxl_0_psx_pmc_xppu_0] -force
  assign_bd_address -offset 0x020381300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_NPI_EXT/psxl_0_psx_pmc_xppu_npi_0] -force
  assign_bd_address -offset 0x020300000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300200000 -range 0x00200000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x020300100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs axil_cmdram/Reg] -force
  assign_bd_address -offset 0x020300B00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs axil_csi_exdes/Reg] -force
  assign_bd_address -offset 0x100000000000 -range 0x080000000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CPM_CDX_DPU_HIGH/psxl_0_psx_cpm_cdx_dpu_high] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_NOCPSPCIE_REGION0/psxl_0_psx_noc_pcie_0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_lpd_dma_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x020300000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300200000 -range 0x00200000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x020300100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs axil_cmdram/Reg] -force
  assign_bd_address -offset 0x020300B00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs axil_csi_exdes/Reg] -force
  assign_bd_address -offset 0x100000000000 -range 0x080000000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CPM_CDX_DPU_HIGH/psxl_0_psx_cpm_cdx_dpu_high] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_NOCPSPCIE_REGION0/psxl_0_psx_noc_pcie_0] -force
  assign_bd_address -offset 0x020300000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300200000 -range 0x00200000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x020300100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs axil_cmdram/Reg] -force
  assign_bd_address -offset 0x020300B00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs axil_csi_exdes/Reg] -force
  assign_bd_address -offset 0x100000000000 -range 0x080000000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CPM_CDX_DPU_HIGH/psxl_0_psx_cpm_cdx_dpu_high] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_NOCPSPCIE_REGION0/psxl_0_psx_noc_pcie_0] -force
  assign_bd_address -offset 0x020300000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020300200000 -range 0x00200000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x020300100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs axil_cmdram/Reg] -force
  assign_bd_address -offset 0x020300B00000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs axil_csi_exdes/Reg] -force
  assign_bd_address -offset 0x100000000000 -range 0x080000000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_CPM_CDX_DPU_HIGH/psxl_0_psx_cpm_cdx_dpu_high] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_NOCPSPCIE_REGION0/psxl_0_psx_noc_pcie_0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_psm_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORT01/C0_DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x100000000000 -range 0x080000000000 -target_address_space [get_bd_addr_spaces atg_axi] [get_bd_addr_segs psx_wizard_0/psxl_0_CPM_CDX_DPU_HIGH/psxl_0_psx_cpm_cdx_dpu_high] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces atg_axi] [get_bd_addr_segs psx_wizard_0/psxl_0_NOCPSPCIE_REGION0/psxl_0_psx_noc_pcie_0] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces atg_axi] [get_bd_addr_segs psx_wizard_0/psxl_0_IPI_BUFFER/psxl_0_psx_ipi_buffer]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs axil_cmdram/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs axil_csi_exdes/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER0/psxl_0_psx_apu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER1/psxl_0_psx_apu_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER2/psxl_0_psx_apu_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER3/psxl_0_psx_apu_3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_PMC_ROM_EXT/psxl_0_psx_coresight_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_FPD_STM_EXT/psxl_0_psx_coresight_fpd_stm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_LPD_ATM_EXT/psxl_0_psx_coresight_lpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CPM_CDX_DPU_HIGH/psxl_0_psx_cpm_cdx_dpu_high]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CRP_EXT/psxl_0_psx_crp_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_AES_EXT/psxl_0_psx_pmc_aes]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_BBRAM_CTRL_EXT/psxl_0_psx_pmc_bbram_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFRAME0_REG_EXT/psxl_0_psx_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFU_APB_EXT/psxl_0_psx_pmc_cfu_apb_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA0_EXT/psxl_0_psx_pmc_dma_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA1_EXT/psxl_0_psx_pmc_dma_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CACHE_EXT/psxl_0_psx_pmc_efuse_cache]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CTRL_EXT/psxl_0_psx_pmc_efuse_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_GLOBAL_EXT/psxl_0_psx_pmc_global_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_IOMODULE_EXT/psxl_0_psx_pmc_iomodule_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OSPI_EXT/psxl_0_psx_pmc_ospi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_MDM_HSD_EXT/psxl_0_psx_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_EXT/psxl_0_psx_pmc_ram]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_DATA_EXT/psxl_0_psx_pmc_ram_data_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_INSTR_EXT/psxl_0_psx_pmc_ram_instr_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_NPI_EXT/psxl_0_psx_pmc_ram_npi]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ECDSA_RSA_EXT/psxl_0_psx_pmc_rsa]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RTC_EXT/psxl_0_psx_pmc_rtc_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_SHA3_EXT/psxl_0_psx_pmc_sha]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_EXT/psxl_0_psx_pmc_slave_boot]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_STREAM_EXT/psxl_0_psx_pmc_slave_boot_stream]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SYSMON_EXT/psxl_0_psx_pmc_sysmon_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU0_TMR_INJECT_EXT/psxl_0_psx_pmc_tmr_inject_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_TMR_MANAGER_EXT/psxl_0_psx_pmc_tmr_manager_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PSX_PMC_TRNG_EXT/psxl_0_psx_pmc_trng]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XMPU_EXT/psxl_0_psx_pmc_xmpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_EXT/psxl_0_psx_pmc_xppu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_NPI_EXT/psxl_0_psx_pmc_xppu_npi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_A/psxl_0_psx_rpu_a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_pmc_ppu_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_B/psxl_0_psx_rpu_b]
  exclude_bd_addr_seg -offset 0xEBD00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ADMA_CH0/psxl_0_psx_adma_0]
  exclude_bd_addr_seg -offset 0xEBD10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ADMA_CH1/psxl_0_psx_adma_1]
  exclude_bd_addr_seg -offset 0xEBD20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ADMA_CH2/psxl_0_psx_adma_2]
  exclude_bd_addr_seg -offset 0xEBD30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ADMA_CH3/psxl_0_psx_adma_3]
  exclude_bd_addr_seg -offset 0xEBD40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ADMA_CH4/psxl_0_psx_adma_4]
  exclude_bd_addr_seg -offset 0xEBD50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ADMA_CH5/psxl_0_psx_adma_5]
  exclude_bd_addr_seg -offset 0xEBD60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ADMA_CH6/psxl_0_psx_adma_6]
  exclude_bd_addr_seg -offset 0xEBD70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ADMA_CH7/psxl_0_psx_adma_7]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER0/psxl_0_psx_apu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER1/psxl_0_psx_apu_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER2/psxl_0_psx_apu_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER3/psxl_0_psx_apu_3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CRF/psxl_0_psx_crf_0]
  exclude_bd_addr_seg -offset 0xEB5E0000 -range 0x00300000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CRL/psxl_0_psx_crl_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_AFIFM0/psxl_0_psx_fpd_afi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_AFIFM1/psxl_0_psx_fpd_afi_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_AFIFM2/psxl_0_psx_fpd_afi_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_AFIFM3/psxl_0_psx_fpd_afi_3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_CMN/psxl_0_psx_fpd_cmn]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_GPV/psxl_0_psx_fpd_gpv_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_SLAVE_XMPU/psxl_0_psx_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_SLCR/psxl_0_psx_fpd_slcr_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_SLCR_SECURE/psxl_0_psx_fpd_slcr_secure_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_SYSTMR_CTRL/psxl_0_psx_fpd_systmr_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_SYSTMR_READ/psxl_0_psx_fpd_systmr_read]
  exclude_bd_addr_seg -offset 0xEB320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_IPI/psxl_0_psx_ipi_pmc]
  exclude_bd_addr_seg -offset 0xEB390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_NOBUF/psxl_0_psx_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xEB310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PSM_IPI/psxl_0_psx_ipi_psm]
  exclude_bd_addr_seg -offset 0xEB9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_LPD_AFIFM4/psxl_0_psx_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xF19C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_LPD_IOU_SECURE_SLCR/psxl_0_psx_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xF19A0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_LPD_IOU_SLCR/psxl_0_psx_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xEB410000 -range 0x00100000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_LPD_SLCR/psxl_0_psx_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xEB510000 -range 0x00040000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_LPD_SLCR_SECURE/psxl_0_psx_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xEB990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_LPD_XPPU/psxl_0_psx_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xEB5D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OCM0_REGS/psxl_0_psx_ocm_ctrl_0]
  exclude_bd_addr_seg -offset 0xEB960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OCM1_REGS/psxl_0_psx_ocm_ctrl_1]
  exclude_bd_addr_seg -offset 0xEB400000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OCM0_XMPU/psxl_0_psx_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xEB980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OCM1_XMPU/psxl_0_psx_ocm_xmpu_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OSPI_EXT/psxl_0_psx_pmc_ospi_0]
  exclude_bd_addr_seg -offset 0xEBC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PSM_GLOBAL_REG/psxl_0_psx_psm_global_reg]
  exclude_bd_addr_seg -offset 0xEBA00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_0A_ATCM/psxl_0_psx_r52_0a_atcm_global]
  exclude_bd_addr_seg -offset 0xEBA10000 -range 0x00008000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_0A_BTCM/psxl_0_psx_r52_0a_btcm_global]
  exclude_bd_addr_seg -offset 0xEBA20000 -range 0x00008000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_0A_CTCM/psxl_0_psx_r52_0a_ctcm_global]
  exclude_bd_addr_seg -offset 0xEBA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_0B_ATCM/psxl_0_psx_r52_0b_atcm_global]
  exclude_bd_addr_seg -offset 0xEBA90000 -range 0x00008000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_0B_BTCM/psxl_0_psx_r52_0b_btcm_global]
  exclude_bd_addr_seg -offset 0xEBAA0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_0B_CTCM/psxl_0_psx_r52_0b_ctcm_global]
  exclude_bd_addr_seg -offset 0xEBA40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_1A_ATCM/psxl_0_psx_r52_1a_atcm_global]
  exclude_bd_addr_seg -offset 0xEBA50000 -range 0x00008000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_1A_BTCM/psxl_0_psx_r52_1a_btcm_global]
  exclude_bd_addr_seg -offset 0xEBA60000 -range 0x00008000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_1A_CTCM/psxl_0_psx_r52_1a_ctcm_global]
  exclude_bd_addr_seg -offset 0xEBAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_1B_ATCM/psxl_0_psx_r52_1b_atcm_global]
  exclude_bd_addr_seg -offset 0xEBAD0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_1B_BTCM/psxl_0_psx_r52_1b_btcm_global]
  exclude_bd_addr_seg -offset 0xEBAE0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_R52_1B_CTCM/psxl_0_psx_r52_1b_ctcm_global]
  exclude_bd_addr_seg -offset 0xEB580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_A/psxl_0_psx_rpu_a]
  exclude_bd_addr_seg -offset 0xEB590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_cpm_pcie_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_B/psxl_0_psx_rpu_b]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER0/psxl_0_psx_apu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER1/psxl_0_psx_apu_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER2/psxl_0_psx_apu_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER3/psxl_0_psx_apu_3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_PMC_ROM_EXT/psxl_0_psx_coresight_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_FPD_STM_EXT/psxl_0_psx_coresight_fpd_stm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_LPD_ATM_EXT/psxl_0_psx_coresight_lpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CRP_EXT/psxl_0_psx_crp_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_AES_EXT/psxl_0_psx_pmc_aes]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_BBRAM_CTRL_EXT/psxl_0_psx_pmc_bbram_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFRAME0_REG_EXT/psxl_0_psx_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFU_APB_EXT/psxl_0_psx_pmc_cfu_apb_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA0_EXT/psxl_0_psx_pmc_dma_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA1_EXT/psxl_0_psx_pmc_dma_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CACHE_EXT/psxl_0_psx_pmc_efuse_cache]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CTRL_EXT/psxl_0_psx_pmc_efuse_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_GLOBAL_EXT/psxl_0_psx_pmc_global_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_IOMODULE_EXT/psxl_0_psx_pmc_iomodule_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OSPI_EXT/psxl_0_psx_pmc_ospi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_MDM_HSD_EXT/psxl_0_psx_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_EXT/psxl_0_psx_pmc_ram]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_DATA_EXT/psxl_0_psx_pmc_ram_data_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_INSTR_EXT/psxl_0_psx_pmc_ram_instr_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_NPI_EXT/psxl_0_psx_pmc_ram_npi]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ECDSA_RSA_EXT/psxl_0_psx_pmc_rsa]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RTC_EXT/psxl_0_psx_pmc_rtc_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_SHA3_EXT/psxl_0_psx_pmc_sha]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_EXT/psxl_0_psx_pmc_slave_boot]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_STREAM_EXT/psxl_0_psx_pmc_slave_boot_stream]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SYSMON_EXT/psxl_0_psx_pmc_sysmon_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU0_TMR_INJECT_EXT/psxl_0_psx_pmc_tmr_inject_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_TMR_MANAGER_EXT/psxl_0_psx_pmc_tmr_manager_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PSX_PMC_TRNG_EXT/psxl_0_psx_pmc_trng]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XMPU_EXT/psxl_0_psx_pmc_xmpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_EXT/psxl_0_psx_pmc_xppu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_NPI_EXT/psxl_0_psx_pmc_xppu_npi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_A/psxl_0_psx_rpu_a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_dpc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_B/psxl_0_psx_rpu_b]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER0/psxl_0_psx_apu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER1/psxl_0_psx_apu_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER2/psxl_0_psx_apu_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER3/psxl_0_psx_apu_3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_PMC_ROM_EXT/psxl_0_psx_coresight_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_FPD_STM_EXT/psxl_0_psx_coresight_fpd_stm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_LPD_ATM_EXT/psxl_0_psx_coresight_lpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CRP_EXT/psxl_0_psx_crp_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_AES_EXT/psxl_0_psx_pmc_aes]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_BBRAM_CTRL_EXT/psxl_0_psx_pmc_bbram_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFRAME0_REG_EXT/psxl_0_psx_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFU_APB_EXT/psxl_0_psx_pmc_cfu_apb_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA0_EXT/psxl_0_psx_pmc_dma_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA1_EXT/psxl_0_psx_pmc_dma_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CACHE_EXT/psxl_0_psx_pmc_efuse_cache]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CTRL_EXT/psxl_0_psx_pmc_efuse_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_GLOBAL_EXT/psxl_0_psx_pmc_global_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_IOMODULE_EXT/psxl_0_psx_pmc_iomodule_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OSPI_EXT/psxl_0_psx_pmc_ospi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_MDM_HSD_EXT/psxl_0_psx_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_EXT/psxl_0_psx_pmc_ram]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_DATA_EXT/psxl_0_psx_pmc_ram_data_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_INSTR_EXT/psxl_0_psx_pmc_ram_instr_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_NPI_EXT/psxl_0_psx_pmc_ram_npi]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ECDSA_RSA_EXT/psxl_0_psx_pmc_rsa]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RTC_EXT/psxl_0_psx_pmc_rtc_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_SHA3_EXT/psxl_0_psx_pmc_sha]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_EXT/psxl_0_psx_pmc_slave_boot]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_STREAM_EXT/psxl_0_psx_pmc_slave_boot_stream]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SYSMON_EXT/psxl_0_psx_pmc_sysmon_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU0_TMR_INJECT_EXT/psxl_0_psx_pmc_tmr_inject_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_TMR_MANAGER_EXT/psxl_0_psx_pmc_tmr_manager_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PSX_PMC_TRNG_EXT/psxl_0_psx_pmc_trng]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XMPU_EXT/psxl_0_psx_pmc_xmpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_EXT/psxl_0_psx_pmc_xppu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_NPI_EXT/psxl_0_psx_pmc_xppu_npi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_A/psxl_0_psx_rpu_a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmc_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_B/psxl_0_psx_rpu_b]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER0/psxl_0_psx_apu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER1/psxl_0_psx_apu_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER2/psxl_0_psx_apu_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER3/psxl_0_psx_apu_3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_PMC_ROM_EXT/psxl_0_psx_coresight_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_FPD_STM_EXT/psxl_0_psx_coresight_fpd_stm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_LPD_ATM_EXT/psxl_0_psx_coresight_lpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CRP_EXT/psxl_0_psx_crp_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_AES_EXT/psxl_0_psx_pmc_aes]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_BBRAM_CTRL_EXT/psxl_0_psx_pmc_bbram_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFRAME0_REG_EXT/psxl_0_psx_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_CFU_APB_EXT/psxl_0_psx_pmc_cfu_apb_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA0_EXT/psxl_0_psx_pmc_dma_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA1_EXT/psxl_0_psx_pmc_dma_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CACHE_EXT/psxl_0_psx_pmc_efuse_cache]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CTRL_EXT/psxl_0_psx_pmc_efuse_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_GLOBAL_EXT/psxl_0_psx_pmc_global_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_IOMODULE_EXT/psxl_0_psx_pmc_iomodule_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_OSPI_EXT/psxl_0_psx_pmc_ospi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_MDM_HSD_EXT/psxl_0_psx_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_EXT/psxl_0_psx_pmc_ram]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_DATA_EXT/psxl_0_psx_pmc_ram_data_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_INSTR_EXT/psxl_0_psx_pmc_ram_instr_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_NPI_EXT/psxl_0_psx_pmc_ram_npi]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_ECDSA_RSA_EXT/psxl_0_psx_pmc_rsa]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RTC_EXT/psxl_0_psx_pmc_rtc_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_SHA3_EXT/psxl_0_psx_pmc_sha]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_EXT/psxl_0_psx_pmc_slave_boot]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_STREAM_EXT/psxl_0_psx_pmc_slave_boot_stream]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SYSMON_EXT/psxl_0_psx_pmc_sysmon_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU0_TMR_INJECT_EXT/psxl_0_psx_pmc_tmr_inject_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_TMR_MANAGER_EXT/psxl_0_psx_pmc_tmr_manager_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PSX_PMC_TRNG_EXT/psxl_0_psx_pmc_trng]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XMPU_EXT/psxl_0_psx_pmc_xmpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_EXT/psxl_0_psx_pmc_xppu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_NPI_EXT/psxl_0_psx_pmc_xppu_npi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_A/psxl_0_psx_rpu_a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_0] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_B/psxl_0_psx_rpu_b]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER0/psxl_0_psx_apu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER1/psxl_0_psx_apu_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER2/psxl_0_psx_apu_2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_FPD_APU_CLUSTER3/psxl_0_psx_apu_3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_PMC_ROM_EXT/psxl_0_psx_coresight_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_FPD_STM_EXT/psxl_0_psx_coresight_fpd_stm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_CoreSight_LPD_ATM_EXT/psxl_0_psx_coresight_lpd_atm]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_CRP_EXT/psxl_0_psx_crp_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_AES_EXT/psxl_0_psx_pmc_aes]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_BBRAM_CTRL_EXT/psxl_0_psx_pmc_bbram_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_CFRAME0_REG_EXT/psxl_0_psx_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_CFU_APB_EXT/psxl_0_psx_pmc_cfu_apb_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA0_EXT/psxl_0_psx_pmc_dma_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_DMA1_EXT/psxl_0_psx_pmc_dma_1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CACHE_EXT/psxl_0_psx_pmc_efuse_cache]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_EFUSE_CTRL_EXT/psxl_0_psx_pmc_efuse_ctrl]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_GLOBAL_EXT/psxl_0_psx_pmc_global_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_IOMODULE_EXT/psxl_0_psx_pmc_iomodule_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_OSPI_EXT/psxl_0_psx_pmc_ospi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_MDM_HSD_EXT/psxl_0_psx_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_EXT/psxl_0_psx_pmc_ram]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_DATA_EXT/psxl_0_psx_pmc_ram_data_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_RAM_INSTR_EXT/psxl_0_psx_pmc_ram_instr_cntlr]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_RAM_NPI_EXT/psxl_0_psx_pmc_ram_npi]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_ECDSA_RSA_EXT/psxl_0_psx_pmc_rsa]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_RTC_EXT/psxl_0_psx_pmc_rtc_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_SHA3_EXT/psxl_0_psx_pmc_sha]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_EXT/psxl_0_psx_pmc_slave_boot]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SLAVE_BOOT_STREAM_EXT/psxl_0_psx_pmc_slave_boot_stream]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_SYSMON_EXT/psxl_0_psx_pmc_sysmon_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU0_TMR_INJECT_EXT/psxl_0_psx_pmc_tmr_inject_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PPU1_TMR_MANAGER_EXT/psxl_0_psx_pmc_tmr_manager_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PSX_PMC_TRNG_EXT/psxl_0_psx_pmc_trng]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XMPU_EXT/psxl_0_psx_pmc_xmpu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_EXT/psxl_0_psx_pmc_xppu_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_PMC_XPPU_NPI_EXT/psxl_0_psx_pmc_xppu_npi_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_A/psxl_0_psx_rpu_a]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces psx_wizard_0/psxl_0_psx_pmcx_dma_1] [get_bd_addr_segs psx_wizard_0/psxl_0_RPU_CLUSTER_B/psxl_0_psx_rpu_b]


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


