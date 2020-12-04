
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
set scripts_vivado_version 2020.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
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
   create_project project_1 myproj -part xcvm1802-vsva2197-2MP-e-S-es1
   set_property BOARD_PART xilinx.com:vmk180_es:part0:1.0 [current_project]
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
xilinx.com:ip:axis_vio:*\
xilinx.com:ip:bufg_gt:*\
xilinx.com:ip:gt_bridge_ip:*\
xilinx.com:ip:gt_quad_base:*\
xilinx.com:ip:util_reduced_logic:*\
xilinx.com:ip:util_ds_buf:*\
xilinx.com:ip:versal_cips:*\
xilinx.com:ip:xlconstant:*\
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
  set GT_Serial [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial ]

  set apb3clk_gt [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 apb3clk_gt ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $apb3clk_gt

  set gt_bridge_ip_0_diff_gt_ref_clock [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_bridge_ip_0_diff_gt_ref_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
   ] $gt_bridge_ip_0_diff_gt_ref_clock


  # Create ports

  # Create instance: axis_vio_0, and set properties
  set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio axis_vio_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_IN {4} \
   CONFIG.C_NUM_PROBE_OUT {2} \
   CONFIG.C_PROBE_OUT1_WIDTH {4} \
 ] $axis_vio_0

  # Create instance: bufg_gt, and set properties
  set bufg_gt [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt ]

  # Create instance: bufg_gt_1, and set properties
  set bufg_gt_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_1 ]

  # Create instance: gt_bridge_ip_0, and set properties
  set gt_bridge_ip_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gt_bridge_ip gt_bridge_ip_0 ]
  set_property -dict [ list \
   CONFIG.IP_LR0_SETTINGS { \
     GT_DIRECTION DUPLEX \
     GT_TYPE GTY \
     INS_LOSS_NYQ 20 \
     INTERNAL_PRESET None \
     OOB_ENABLE false \
     PCIE_ENABLE false \
     PCIE_USERCLK2_FREQ 250 \
     PCIE_USERCLK_FREQ 250 \
     PRESET None \
     RESET_SEQUENCE_INTERVAL 0 \
     RXPROGDIV_FREQ_ENABLE false \
     RXPROGDIV_FREQ_SOURCE LCPLL \
     RXPROGDIV_FREQ_VAL 322.265625 \
     RX_64B66B_CRC false \
     RX_64B66B_DECODER false \
     RX_64B66B_DESCRAMBLER false \
     RX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 \
     RX_BUFFER_BYPASS_MODE Fast_Sync \
     RX_BUFFER_BYPASS_MODE_LANE MULTI \
     RX_BUFFER_MODE 1 \
     RX_BUFFER_RESET_ON_CB_CHANGE ENABLE \
     RX_BUFFER_RESET_ON_COMMAALIGN DISABLE \
     RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE \
     RX_CB_DISP_0_0 false \
     RX_CB_DISP_0_1 false \
     RX_CB_DISP_0_2 false \
     RX_CB_DISP_0_3 false \
     RX_CB_DISP_1_0 false \
     RX_CB_DISP_1_1 false \
     RX_CB_DISP_1_2 false \
     RX_CB_DISP_1_3 false \
     RX_CB_K_0_0 false \
     RX_CB_K_0_1 false \
     RX_CB_K_0_2 false \
     RX_CB_K_0_3 false \
     RX_CB_K_1_0 false \
     RX_CB_K_1_1 false \
     RX_CB_K_1_2 false \
     RX_CB_K_1_3 false \
     RX_CB_LEN_SEQ 1 \
     RX_CB_MASK_0_0 false \
     RX_CB_MASK_0_1 false \
     RX_CB_MASK_0_2 false \
     RX_CB_MASK_0_3 false \
     RX_CB_MASK_1_0 false \
     RX_CB_MASK_1_1 false \
     RX_CB_MASK_1_2 false \
     RX_CB_MASK_1_3 false \
     RX_CB_MAX_LEVEL 1 \
     RX_CB_MAX_SKEW 1 \
     RX_CB_NUM_SEQ 0 \
     RX_CB_VAL_0_0 00000000 \
     RX_CB_VAL_0_1 00000000 \
     RX_CB_VAL_0_2 00000000 \
     RX_CB_VAL_0_3 00000000 \
     RX_CB_VAL_1_0 00000000 \
     RX_CB_VAL_1_1 00000000 \
     RX_CB_VAL_1_2 00000000 \
     RX_CB_VAL_1_3 00000000 \
     RX_CC_DISP_0_0 false \
     RX_CC_DISP_0_1 false \
     RX_CC_DISP_0_2 false \
     RX_CC_DISP_0_3 false \
     RX_CC_DISP_1_0 false \
     RX_CC_DISP_1_1 false \
     RX_CC_DISP_1_2 false \
     RX_CC_DISP_1_3 false \
     RX_CC_KEEP_IDLE DISABLE \
     RX_CC_K_0_0 false \
     RX_CC_K_0_1 false \
     RX_CC_K_0_2 false \
     RX_CC_K_0_3 false \
     RX_CC_K_1_0 false \
     RX_CC_K_1_1 false \
     RX_CC_K_1_2 false \
     RX_CC_K_1_3 false \
     RX_CC_LEN_SEQ 1 \
     RX_CC_MASK_0_0 false \
     RX_CC_MASK_0_1 false \
     RX_CC_MASK_0_2 false \
     RX_CC_MASK_0_3 false \
     RX_CC_MASK_1_0 false \
     RX_CC_MASK_1_1 false \
     RX_CC_MASK_1_2 false \
     RX_CC_MASK_1_3 false \
     RX_CC_NUM_SEQ 0 \
     RX_CC_PERIODICITY 5000 \
     RX_CC_PRECEDENCE ENABLE \
     RX_CC_REPEAT_WAIT 0 \
     RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 \
     RX_CC_VAL_0_0 00000000 \
     RX_CC_VAL_0_1 00000000 \
     RX_CC_VAL_0_2 00000000 \
     RX_CC_VAL_0_3 00000000 \
     RX_CC_VAL_1_0 00000000 \
     RX_CC_VAL_1_1 00000000 \
     RX_CC_VAL_1_2 00000000 \
     RX_CC_VAL_1_3 00000000 \
     RX_COMMA_ALIGN_WORD 1 \
     RX_COMMA_DOUBLE_ENABLE false \
     RX_COMMA_MASK 0000000000 \
     RX_COMMA_M_ENABLE false \
     RX_COMMA_M_VAL 1010000011 \
     RX_COMMA_PRESET NONE \
     RX_COMMA_P_ENABLE false \
     RX_COMMA_P_VAL 0101111100 \
     RX_COMMA_SHOW_REALIGN_ENABLE true \
     RX_COMMA_VALID_ONLY 0 \
     RX_COUPLING AC \
     RX_DATA_DECODING RAW \
     RX_EQ_MODE AUTO \
     RX_FRACN_ENABLED false \
     RX_FRACN_NUMERATOR 0 \
     RX_INT_DATA_WIDTH 32 \
     RX_JTOL_FC 6.1862627 \
     RX_JTOL_LF_SLOPE -20 \
     RX_LINE_RATE 10.3125 \
     RX_OUTCLK_SOURCE RXOUTCLKPMA \
     RX_PLL_TYPE LCPLL \
     RX_PPM_OFFSET 0 \
     RX_RATE_GROUP A \
     RX_REFCLK_FREQUENCY 156.25 \
     RX_REFCLK_SOURCE R0 \
     RX_SLIDE_MODE OFF \
     RX_SSC_PPM 0 \
     RX_TERMINATION PROGRAMMABLE \
     RX_TERMINATION_PROG_VALUE 800 \
     RX_USER_DATA_WIDTH 32 \
     TXPROGDIV_FREQ_ENABLE false \
     TXPROGDIV_FREQ_SOURCE LCPLL \
     TXPROGDIV_FREQ_VAL 322.265625 \
     TX_64B66B_CRC false \
     TX_64B66B_ENCODER false \
     TX_64B66B_SCRAMBLER false \
     TX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 \
     TX_BUFFER_BYPASS_MODE Fast_Sync \
     TX_BUFFER_MODE 1 \
     TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE \
     TX_DATA_ENCODING RAW \
     TX_DIFF_SWING_EMPH_MODE CUSTOM \
     TX_FRACN_ENABLED false \
     TX_FRACN_NUMERATOR 0 \
     TX_INT_DATA_WIDTH 32 \
     TX_LINE_RATE 10.3125 \
     TX_OUTCLK_SOURCE TXOUTCLKPMA \
     TX_PIPM_ENABLE false \
     TX_PLL_TYPE LCPLL \
     TX_RATE_GROUP A \
     TX_REFCLK_FREQUENCY 156.25 \
     TX_REFCLK_SOURCE R0 \
     TX_USER_DATA_WIDTH 32 \
   } \
   CONFIG.IP_LR1_SETTINGS { \
     GT_DIRECTION DUPLEX \
     GT_TYPE GTY \
     INS_LOSS_NYQ 20 \
     INTERNAL_PRESET None \
     OOB_ENABLE false \
     PCIE_ENABLE false \
     PCIE_USERCLK2_FREQ 250 \
     PCIE_USERCLK_FREQ 250 \
     PRESET None \
     RESET_SEQUENCE_INTERVAL 0 \
     RXPROGDIV_FREQ_ENABLE false \
     RXPROGDIV_FREQ_SOURCE LCPLL \
     RXPROGDIV_FREQ_VAL 322.265625 \
     RX_64B66B_CRC false \
     RX_64B66B_DECODER false \
     RX_64B66B_DESCRAMBLER false \
     RX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 \
     RX_BUFFER_BYPASS_MODE Fast_Sync \
     RX_BUFFER_BYPASS_MODE_LANE MULTI \
     RX_BUFFER_MODE 1 \
     RX_BUFFER_RESET_ON_CB_CHANGE ENABLE \
     RX_BUFFER_RESET_ON_COMMAALIGN DISABLE \
     RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE \
     RX_CB_DISP_0_0 false \
     RX_CB_DISP_0_1 false \
     RX_CB_DISP_0_2 false \
     RX_CB_DISP_0_3 false \
     RX_CB_DISP_1_0 false \
     RX_CB_DISP_1_1 false \
     RX_CB_DISP_1_2 false \
     RX_CB_DISP_1_3 false \
     RX_CB_K_0_0 false \
     RX_CB_K_0_1 false \
     RX_CB_K_0_2 false \
     RX_CB_K_0_3 false \
     RX_CB_K_1_0 false \
     RX_CB_K_1_1 false \
     RX_CB_K_1_2 false \
     RX_CB_K_1_3 false \
     RX_CB_LEN_SEQ 1 \
     RX_CB_MASK_0_0 false \
     RX_CB_MASK_0_1 false \
     RX_CB_MASK_0_2 false \
     RX_CB_MASK_0_3 false \
     RX_CB_MASK_1_0 false \
     RX_CB_MASK_1_1 false \
     RX_CB_MASK_1_2 false \
     RX_CB_MASK_1_3 false \
     RX_CB_MAX_LEVEL 1 \
     RX_CB_MAX_SKEW 1 \
     RX_CB_NUM_SEQ 0 \
     RX_CB_VAL_0_0 00000000 \
     RX_CB_VAL_0_1 00000000 \
     RX_CB_VAL_0_2 00000000 \
     RX_CB_VAL_0_3 00000000 \
     RX_CB_VAL_1_0 00000000 \
     RX_CB_VAL_1_1 00000000 \
     RX_CB_VAL_1_2 00000000 \
     RX_CB_VAL_1_3 00000000 \
     RX_CC_DISP_0_0 false \
     RX_CC_DISP_0_1 false \
     RX_CC_DISP_0_2 false \
     RX_CC_DISP_0_3 false \
     RX_CC_DISP_1_0 false \
     RX_CC_DISP_1_1 false \
     RX_CC_DISP_1_2 false \
     RX_CC_DISP_1_3 false \
     RX_CC_KEEP_IDLE DISABLE \
     RX_CC_K_0_0 false \
     RX_CC_K_0_1 false \
     RX_CC_K_0_2 false \
     RX_CC_K_0_3 false \
     RX_CC_K_1_0 false \
     RX_CC_K_1_1 false \
     RX_CC_K_1_2 false \
     RX_CC_K_1_3 false \
     RX_CC_LEN_SEQ 1 \
     RX_CC_MASK_0_0 false \
     RX_CC_MASK_0_1 false \
     RX_CC_MASK_0_2 false \
     RX_CC_MASK_0_3 false \
     RX_CC_MASK_1_0 false \
     RX_CC_MASK_1_1 false \
     RX_CC_MASK_1_2 false \
     RX_CC_MASK_1_3 false \
     RX_CC_NUM_SEQ 0 \
     RX_CC_PERIODICITY 5000 \
     RX_CC_PRECEDENCE ENABLE \
     RX_CC_REPEAT_WAIT 0 \
     RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 \
     RX_CC_VAL_0_0 00000000 \
     RX_CC_VAL_0_1 00000000 \
     RX_CC_VAL_0_2 00000000 \
     RX_CC_VAL_0_3 00000000 \
     RX_CC_VAL_1_0 00000000 \
     RX_CC_VAL_1_1 00000000 \
     RX_CC_VAL_1_2 00000000 \
     RX_CC_VAL_1_3 00000000 \
     RX_COMMA_ALIGN_WORD 1 \
     RX_COMMA_DOUBLE_ENABLE false \
     RX_COMMA_MASK 0000000000 \
     RX_COMMA_M_ENABLE false \
     RX_COMMA_M_VAL 1010000011 \
     RX_COMMA_PRESET NONE \
     RX_COMMA_P_ENABLE false \
     RX_COMMA_P_VAL 0101111100 \
     RX_COMMA_SHOW_REALIGN_ENABLE true \
     RX_COMMA_VALID_ONLY 0 \
     RX_COUPLING AC \
     RX_DATA_DECODING RAW \
     RX_EQ_MODE AUTO \
     RX_FRACN_ENABLED true \
     RX_FRACN_NUMERATOR 0 \
     RX_INT_DATA_WIDTH 64 \
     RX_JTOL_FC 10 \
     RX_JTOL_LF_SLOPE -20 \
     RX_LINE_RATE 25.78125 \
     RX_OUTCLK_SOURCE RXOUTCLKPMA \
     RX_PLL_TYPE LCPLL \
     RX_PPM_OFFSET 0 \
     RX_RATE_GROUP A \
     RX_REFCLK_FREQUENCY 156.25 \
     RX_REFCLK_SOURCE R0 \
     RX_SLIDE_MODE OFF \
     RX_SSC_PPM 0 \
     RX_TERMINATION PROGRAMMABLE \
     RX_TERMINATION_PROG_VALUE 800 \
     RX_USER_DATA_WIDTH 64 \
     TXPROGDIV_FREQ_ENABLE false \
     TXPROGDIV_FREQ_SOURCE LCPLL \
     TXPROGDIV_FREQ_VAL 322.265625 \
     TX_64B66B_CRC false \
     TX_64B66B_ENCODER false \
     TX_64B66B_SCRAMBLER false \
     TX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 \
     TX_BUFFER_BYPASS_MODE Fast_Sync \
     TX_BUFFER_MODE 1 \
     TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE \
     TX_DATA_ENCODING RAW \
     TX_DIFF_SWING_EMPH_MODE CUSTOM \
     TX_FRACN_ENABLED true \
     TX_FRACN_NUMERATOR 0 \
     TX_INT_DATA_WIDTH 64 \
     TX_LINE_RATE 25.78125 \
     TX_OUTCLK_SOURCE TXOUTCLKPMA \
     TX_PIPM_ENABLE false \
     TX_PLL_TYPE LCPLL \
     TX_RATE_GROUP A \
     TX_REFCLK_FREQUENCY 156.25 \
     TX_REFCLK_SOURCE R0 \
     TX_USER_DATA_WIDTH 64 \
   } \
   CONFIG.IP_NO_OF_LANES {1} \
 ] $gt_bridge_ip_0

  # Create instance: gt_quad_base_0, and set properties
  set gt_quad_base_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gt_quad_base gt_quad_base_0 ]
  set_property -dict [ list \
   CONFIG.QUAD_USAGE {TX_QUAD_CH {TXQuad_0_/gt_quad_base_0 {/gt_quad_base_0 undef,undef,design_1_gt_bridge_ip_0_0.IP_CH0,undef MSTRCLK 0,0,1,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/gt_quad_base_0 {/gt_quad_base_0 undef,undef,design_1_gt_bridge_ip_0_0.IP_CH0,undef MSTRCLK 0,0,1,0 IS_CURRENT_QUAD 1}}} \
   CONFIG.REFCLK_STRING { \
     HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_156.25_MHz_unique1 \
   } \
 ] $gt_quad_base_0

  # Create instance: urlp, and set properties
  set urlp [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic urlp ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $urlp

  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
 ] $util_ds_buf

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_0 ]
  set_property -dict [ list \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {lpddr4_sma_clk2} \
 ] $util_ds_buf_0

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.PS_BOARD_INTERFACE {cips_fixed_io} \
 ] $versal_cips_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create instance: xlcp, and set properties
  set xlcp [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlcp ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {1} \
 ] $xlcp

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN_D_0_1 [get_bd_intf_ports apb3clk_gt] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net gt_bridge_ip_0_GT_RX0 [get_bd_intf_pins gt_bridge_ip_0/GT_RX0] [get_bd_intf_pins gt_quad_base_0/RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net gt_bridge_ip_0_GT_TX0 [get_bd_intf_pins gt_bridge_ip_0/GT_TX0] [get_bd_intf_pins gt_quad_base_0/TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net gt_bridge_ip_0_diff_gt_ref_clock_1 [get_bd_intf_ports gt_bridge_ip_0_diff_gt_ref_clock] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  connect_bd_intf_net -intf_net gt_quad_base_0_GT_Serial [get_bd_intf_ports GT_Serial] [get_bd_intf_pins gt_quad_base_0/GT_Serial]

  # Create port connections
  connect_bd_net -net axis_vio_0_probe_out0 [get_bd_pins axis_vio_0/probe_out0] [get_bd_pins gt_bridge_ip_0/gtreset_in]
  connect_bd_net -net axis_vio_0_probe_out1 [get_bd_pins axis_vio_0/probe_out1] [get_bd_pins gt_bridge_ip_0/rate_sel]
  connect_bd_net -net bufg_gt_1_usrclk [get_bd_pins bufg_gt_1/usrclk] [get_bd_pins gt_bridge_ip_0/gt_txusrclk] [get_bd_pins gt_quad_base_0/ch2_txusrclk]
  connect_bd_net -net bufg_gt_usrclk [get_bd_pins bufg_gt/usrclk] [get_bd_pins gt_bridge_ip_0/gt_rxusrclk] [get_bd_pins gt_quad_base_0/ch2_rxusrclk]
  connect_bd_net -net gt_bridge_ip_0_link_status_out [get_bd_pins axis_vio_0/probe_in0] [get_bd_pins gt_bridge_ip_0/link_status_out]
  connect_bd_net -net gt_bridge_ip_0_rx_resetdone_out [get_bd_pins axis_vio_0/probe_in2] [get_bd_pins gt_bridge_ip_0/rx_resetdone_out]
  connect_bd_net -net gt_bridge_ip_0_tx_resetdone_out [get_bd_pins axis_vio_0/probe_in1] [get_bd_pins gt_bridge_ip_0/tx_resetdone_out]
  connect_bd_net -net gt_quad_base_0_ch2_rxoutclk [get_bd_pins bufg_gt/outclk] [get_bd_pins gt_quad_base_0/ch2_rxoutclk]
  connect_bd_net -net gt_quad_base_0_ch2_txoutclk [get_bd_pins bufg_gt_1/outclk] [get_bd_pins gt_quad_base_0/ch2_txoutclk]
  connect_bd_net -net gt_quad_base_0_gtpowergood [get_bd_pins gt_quad_base_0/gtpowergood] [get_bd_pins xlcp/In0]
  connect_bd_net -net gt_quad_base_0_hsclk1_lcplllock [get_bd_pins axis_vio_0/probe_in3] [get_bd_pins gt_quad_base_0/hsclk1_lcplllock]
  connect_bd_net -net urlp_Res [get_bd_pins gt_bridge_ip_0/gtpowergood] [get_bd_pins urlp/Res]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins axis_vio_0/clk] [get_bd_pins gt_bridge_ip_0/apb3clk] [get_bd_pins gt_quad_base_0/apb3clk] [get_bd_pins util_ds_buf_0/IBUF_OUT]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins gt_quad_base_0/GT_REFCLK0] [get_bd_pins util_ds_buf/IBUF_OUT]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins gt_quad_base_0/ch0_rxusrclk] [get_bd_pins gt_quad_base_0/ch0_txusrclk] [get_bd_pins gt_quad_base_0/ch1_rxusrclk] [get_bd_pins gt_quad_base_0/ch1_txusrclk] [get_bd_pins gt_quad_base_0/ch3_rxusrclk] [get_bd_pins gt_quad_base_0/ch3_txusrclk] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlcp_dout [get_bd_pins urlp/Op1] [get_bd_pins xlcp/dout]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  make_wrapper -files [get_files $design_name.bd] -top -import

puts "INFO: End of create_root_design"
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design "" 

	# close_bd_design [get_bd_designs $design_name]
	# set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
	open_bd_design [get_bd_files $design_name]
	# Add USER_COMMENTS on $design_name
	set_property USER_COMMENTS.comment_0 {} [current_bd_design]
	set_property USER_COMMENTS.comment0 {Next Steps:
1. Synthesize and open synthesized design
2. Add top level constraints. Refer to README.md in below url for list of constraints to add. 
https://github.com/Xilinx/XilinxCEDStore/tree/2020.2/ced/Xilinx/IPI/Multi-Rate_GTY
3. Select Generate Device Image in the Flow Navigator to create .pdi image.
4. Program pdi and refer to README.md for board bringup and enabling IBERT in hardware manager } [current_bd_design]


