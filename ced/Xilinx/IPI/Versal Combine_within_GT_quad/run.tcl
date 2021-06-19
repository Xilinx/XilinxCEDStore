
################################################################
# This is a generated script based on design: pcie_jesd
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
# source pcie_jesd_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvc1902-vsva2197-2MP-e-S-es1
   set_property BOARD_PART xilinx.com:vck190_es:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name pcie_jesd

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
xilinx.com:ip:bufg_gt:*\
xilinx.com:ip:jesd204c:*\
xilinx.com:ip:pcie_phy_versal:*\
xilinx.com:ip:util_ds_buf:*\
xilinx.com:ip:versal_cips:*\
xilinx.com:ip:xlconstant:*\
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


# Hierarchical cell: pcie_phy_versal_0_support
proc create_hier_cell_pcie_phy_versal_0_support { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_pcie_phy_versal_0_support() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_bufgt_rtl:1.0 GT0_BUFGT

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:gt_rx_interface_rtl:1.0 RX0_GT_IP_Interface

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:gt_rx_interface_rtl:1.0 RX2_GT_IP_Interface

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:gt_tx_interface_rtl:1.0 TX0_GT_IP_Interface

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:gt_tx_interface_rtl:1.0 TX2_GT_IP_Interface

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:gt_rxmargin_intf_rtl:1.0 gt_rxmargin_intf

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type clk BUFG_GT_O
  create_bd_pin -dir I -type clk GT_REFCLK0
  create_bd_pin -dir I -type clk GT_REFCLK1
  create_bd_pin -dir O -from 0 -to 0 -type clk IBUF_OUT
  create_bd_pin -dir I ch0_pcierstb
  create_bd_pin -dir O ch0_phyready
  create_bd_pin -dir O ch0_phystatus
  create_bd_pin -dir O -type gt_outclk ch0_rxoutclk
  create_bd_pin -dir O -type gt_outclk ch0_txoutclk
  create_bd_pin -dir I -type gt_usrclk ch0_txusrclk
  create_bd_pin -dir O -type gt_outclk ch1_txoutclk
  create_bd_pin -dir O -type gt_outclk ch2_rxoutclk
  create_bd_pin -dir I -type gt_usrclk ch2_rxusrclk
  create_bd_pin -dir I -type gt_usrclk ch2_txusrclk
  create_bd_pin -dir I -from 5 -to 0 pcieltssm
  create_bd_pin -dir I -from 3 -to 0 rxn_0
  create_bd_pin -dir I -from 3 -to 0 rxp_0
  create_bd_pin -dir O -from 3 -to 0 txn_0
  create_bd_pin -dir O -from 3 -to 0 txp_0

  # Create instance: bufg_gt_sysclk, and set properties
  set bufg_gt_sysclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf bufg_gt_sysclk ]
  set_property -dict [ list \
   CONFIG.C_BUFG_GT_SYNC {true} \
   CONFIG.C_BUF_TYPE {BUFG_GT} \
 ] $bufg_gt_sysclk

  # Create instance: const_1b1, and set properties
  set const_1b1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_1b1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {1} \
   CONFIG.CONST_WIDTH {1} \
 ] $const_1b1

  # Create instance: gt_quad_0, and set properties
  set gt_quad_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gt_quad_base gt_quad_0 ]
  set_property -dict [ list \
   CONFIG.QUAD_USAGE {TX_QUAD_CH {TXQuad_0_/pcie_phy_versal_0_support/gt_quad_0 {/pcie_phy_versal_0_support/gt_quad_0 pcie_jesd_pcie_phy_versal_0_1.IP_CH0,undef,pcie_jesd_jesd204c_0_1.IP_CH0,undef MSTRCLK 1,0,1,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/pcie_phy_versal_0_support/gt_quad_0 {/pcie_phy_versal_0_support/gt_quad_0 pcie_jesd_pcie_phy_versal_0_1.IP_CH0,undef,pcie_jesd_jesd204c_0_2.IP_CH0,undef MSTRCLK 1,0,1,0 IS_CURRENT_QUAD 1}}} \
   CONFIG.REFCLK_STRING { \
     HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 \
     HSCLK0_RPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 \
     HSCLK1_RPLLGTREFCLK0 refclk_PROT1_R0_PROT2_R0_200_MHz_unique1 \
   } \
 ] $gt_quad_0

  # Create instance: refclk_ibuf, and set properties
  set refclk_ibuf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf refclk_ibuf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
 ] $refclk_ibuf

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins pcie_refclk] [get_bd_intf_pins refclk_ibuf/CLK_IN_D]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins GT0_BUFGT] [get_bd_intf_pins gt_quad_0/GT0_BUFGT]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins RX0_GT_IP_Interface] [get_bd_intf_pins gt_quad_0/RX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins TX0_GT_IP_Interface] [get_bd_intf_pins gt_quad_0/TX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins GT_Serial] [get_bd_intf_pins gt_quad_0/GT_Serial]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins gt_rxmargin_intf] [get_bd_intf_pins gt_quad_0/gt_rxmargin_intf]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins TX2_GT_IP_Interface] [get_bd_intf_pins gt_quad_0/TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins RX2_GT_IP_Interface] [get_bd_intf_pins gt_quad_0/RX2_GT_IP_Interface]

  # Create port connections
  connect_bd_net -net GT_REFCLK0_1 [get_bd_pins GT_REFCLK0] [get_bd_pins gt_quad_0/GT_REFCLK0]
  connect_bd_net -net GT_REFCLK1_1 [get_bd_pins GT_REFCLK1] [get_bd_pins gt_quad_0/GT_REFCLK1]
  connect_bd_net -net bufg_gt_sysclk_BUFG_GT_O [get_bd_pins BUFG_GT_O] [get_bd_pins bufg_gt_sysclk/BUFG_GT_O] [get_bd_pins gt_quad_0/apb3clk]
  connect_bd_net -net ch0_pcierstb_1 [get_bd_pins ch0_pcierstb] [get_bd_pins gt_quad_0/ch0_pcierstb] [get_bd_pins gt_quad_0/ch1_pcierstb] [get_bd_pins gt_quad_0/ch2_pcierstb] [get_bd_pins gt_quad_0/ch3_pcierstb]
  connect_bd_net -net ch0_txusrclk_1 [get_bd_pins ch0_txusrclk] [get_bd_pins gt_quad_0/ch0_rxusrclk] [get_bd_pins gt_quad_0/ch0_txusrclk]
  connect_bd_net -net ch2_rxusrclk_1 [get_bd_pins ch2_rxusrclk] [get_bd_pins gt_quad_0/ch2_rxusrclk]
  connect_bd_net -net ch2_txusrclk_1 [get_bd_pins ch2_txusrclk] [get_bd_pins gt_quad_0/ch2_txusrclk]
  connect_bd_net -net const_1b1_dout [get_bd_pins bufg_gt_sysclk/BUFG_GT_CE] [get_bd_pins const_1b1/dout]
  connect_bd_net -net gt_quad_0_ch0_phyready [get_bd_pins ch0_phyready] [get_bd_pins gt_quad_0/ch0_phyready]
  connect_bd_net -net gt_quad_0_ch0_phystatus [get_bd_pins ch0_phystatus] [get_bd_pins gt_quad_0/ch0_phystatus]
  connect_bd_net -net gt_quad_0_ch0_rxoutclk [get_bd_pins ch0_rxoutclk] [get_bd_pins gt_quad_0/ch0_rxoutclk]
  connect_bd_net -net gt_quad_0_ch0_txoutclk [get_bd_pins ch0_txoutclk] [get_bd_pins gt_quad_0/ch0_txoutclk]
  connect_bd_net -net gt_quad_0_ch1_txoutclk [get_bd_pins ch1_txoutclk] [get_bd_pins gt_quad_0/ch1_txoutclk]
  connect_bd_net -net gt_quad_0_ch2_rxoutclk [get_bd_pins ch2_rxoutclk] [get_bd_pins gt_quad_0/ch2_rxoutclk]
  connect_bd_net -net gt_quad_0_txn [get_bd_pins txn_0] [get_bd_pins gt_quad_0/txn]
  connect_bd_net -net gt_quad_0_txp [get_bd_pins txp_0] [get_bd_pins gt_quad_0/txp]
  connect_bd_net -net pcieltssm_1 [get_bd_pins pcieltssm] [get_bd_pins gt_quad_0/pcieltssm]
  connect_bd_net -net refclk_ibuf_IBUF_DS_ODIV2 [get_bd_pins bufg_gt_sysclk/BUFG_GT_I] [get_bd_pins refclk_ibuf/IBUF_DS_ODIV2]
  connect_bd_net -net refclk_ibuf_IBUF_OUT [get_bd_pins IBUF_OUT] [get_bd_pins refclk_ibuf/IBUF_OUT]
  connect_bd_net -net rxn_0_1 [get_bd_pins rxn_0] [get_bd_pins gt_quad_0/rxn]
  connect_bd_net -net rxp_0_1 [get_bd_pins rxp_0] [get_bd_pins gt_quad_0/rxp]

  # Restore current instance
  current_bd_instance $oldCurInst
}


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
  set jesd_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 jesd_refclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $jesd_refclk

  set pcie_mgt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_mgt ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]


  # Create ports
  set rxn_0 [ create_bd_port -dir I -from 3 -to 0 rxn_0 ]
  set rxp_0 [ create_bd_port -dir I -from 3 -to 0 rxp_0 ]
  set sys_reset [ create_bd_port -dir I -type rst sys_reset ]
  set txn_0 [ create_bd_port -dir O -from 3 -to 0 txn_0 ]
  set txp_0 [ create_bd_port -dir O -from 3 -to 0 txp_0 ]

  # Create instance: bufg_gt_0, and set properties
  set bufg_gt_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_0 ]

  # Create instance: bufg_gt_1, and set properties
  set bufg_gt_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_1 ]

  # Create instance: jesd204c_rx, and set properties
  set jesd204c_rx [ create_bd_cell -type ip -vlnv xilinx.com:ip:jesd204c jesd204c_rx ]
  set_property -dict [ list \
   CONFIG.C_ENCODING {0} \
   CONFIG.C_LANES {1} \
   CONFIG.C_NODE_IS_TRANSMIT {0} \
 ] $jesd204c_rx

  # Create instance: jesd204c_tx, and set properties
  set jesd204c_tx [ create_bd_cell -type ip -vlnv xilinx.com:ip:jesd204c jesd204c_tx ]
  set_property -dict [ list \
   CONFIG.C_ENCODING {0} \
   CONFIG.C_LANES {1} \
 ] $jesd204c_tx

  # Create instance: pcie_phy_versal_0, and set properties
  set pcie_phy_versal_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_phy_versal pcie_phy_versal_0 ]
  set_property -dict [ list \
   CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {5.0_GT/s} \
   CONFIG.phy_coreclk_freq {250_MHz} \
 ] $pcie_phy_versal_0

  # Create instance: pcie_phy_versal_0_support
  create_hier_cell_pcie_phy_versal_0_support [current_bd_instance .] pcie_phy_versal_0_support

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_0 ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $util_ds_buf_0

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.PS_BOARD_INTERFACE {cips_fixed_io} \
 ] $versal_cips_0

  # Create interface connections
  connect_bd_intf_net -intf_net diff_clock_rtl_1 [get_bd_intf_ports jesd_refclk] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net jesd204c_0_GT_TX0 [get_bd_intf_pins jesd204c_tx/GT_TX0] [get_bd_intf_pins pcie_phy_versal_0_support/TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net jesd204c_1_GT_RX0 [get_bd_intf_pins jesd204c_rx/GT_RX0] [get_bd_intf_pins pcie_phy_versal_0_support/RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_GT_RX0 [get_bd_intf_pins pcie_phy_versal_0/GT_RX0] [get_bd_intf_pins pcie_phy_versal_0_support/RX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_GT_TX0 [get_bd_intf_pins pcie_phy_versal_0/GT_TX0] [get_bd_intf_pins pcie_phy_versal_0_support/TX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_gt_rxmargin_q0 [get_bd_intf_pins pcie_phy_versal_0/gt_rxmargin_q0] [get_bd_intf_pins pcie_phy_versal_0_support/gt_rxmargin_intf]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_pcie_mgt [get_bd_intf_ports pcie_mgt] [get_bd_intf_pins pcie_phy_versal_0/pcie_mgt]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_support_GT0_BUFGT [get_bd_intf_pins pcie_phy_versal_0/GT_BUFGT] [get_bd_intf_pins pcie_phy_versal_0_support/GT0_BUFGT]
  connect_bd_intf_net -intf_net pcie_phy_versal_0_support_GT_Serial [get_bd_intf_pins pcie_phy_versal_0/GT0_Serial] [get_bd_intf_pins pcie_phy_versal_0_support/GT_Serial]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins pcie_phy_versal_0_support/pcie_refclk]

  # Create port connections
  connect_bd_net -net bufg_gt_0_usrclk [get_bd_pins bufg_gt_0/usrclk] [get_bd_pins pcie_phy_versal_0_support/ch2_txusrclk]
  connect_bd_net -net bufg_gt_1_usrclk [get_bd_pins bufg_gt_1/usrclk] [get_bd_pins pcie_phy_versal_0_support/ch2_rxusrclk]
  connect_bd_net -net pcie_phy_versal_0_gt_pcieltssm [get_bd_pins pcie_phy_versal_0/gt_pcieltssm] [get_bd_pins pcie_phy_versal_0_support/pcieltssm]
  connect_bd_net -net pcie_phy_versal_0_gtrefclk [get_bd_pins pcie_phy_versal_0/gtrefclk] [get_bd_pins pcie_phy_versal_0_support/GT_REFCLK0]
  connect_bd_net -net pcie_phy_versal_0_pcierstb [get_bd_pins pcie_phy_versal_0/pcierstb] [get_bd_pins pcie_phy_versal_0_support/ch0_pcierstb]
  connect_bd_net -net pcie_phy_versal_0_phy_pclk [get_bd_pins pcie_phy_versal_0/phy_pclk] [get_bd_pins pcie_phy_versal_0_support/ch0_txusrclk]
  connect_bd_net -net pcie_phy_versal_0_support_BUFG_GT_O [get_bd_pins jesd204c_rx/rx_core_clk] [get_bd_pins jesd204c_rx/s_axi_aclk] [get_bd_pins jesd204c_tx/s_axi_aclk] [get_bd_pins jesd204c_tx/tx_core_clk] [get_bd_pins pcie_phy_versal_0/phy_refclk] [get_bd_pins pcie_phy_versal_0_support/BUFG_GT_O]
  connect_bd_net -net pcie_phy_versal_0_support_IBUF_OUT [get_bd_pins pcie_phy_versal_0/phy_gtrefclk] [get_bd_pins pcie_phy_versal_0_support/IBUF_OUT]
  connect_bd_net -net pcie_phy_versal_0_support_ch0_phyready [get_bd_pins pcie_phy_versal_0/ch0_phyready] [get_bd_pins pcie_phy_versal_0_support/ch0_phyready]
  connect_bd_net -net pcie_phy_versal_0_support_ch0_phystatus [get_bd_pins pcie_phy_versal_0/ch0_phystatus] [get_bd_pins pcie_phy_versal_0_support/ch0_phystatus]
  connect_bd_net -net pcie_phy_versal_0_support_ch0_rxoutclk [get_bd_pins pcie_phy_versal_0/gt_rxoutclk] [get_bd_pins pcie_phy_versal_0_support/ch0_rxoutclk]
  connect_bd_net -net pcie_phy_versal_0_support_ch0_txoutclk [get_bd_pins pcie_phy_versal_0/gt_txoutclk] [get_bd_pins pcie_phy_versal_0_support/ch0_txoutclk]
  connect_bd_net -net pcie_phy_versal_0_support_ch1_txoutclk [get_bd_pins bufg_gt_0/outclk] [get_bd_pins pcie_phy_versal_0_support/ch1_txoutclk]
  connect_bd_net -net pcie_phy_versal_0_support_ch2_rxoutclk [get_bd_pins bufg_gt_1/outclk] [get_bd_pins pcie_phy_versal_0_support/ch2_rxoutclk]
  connect_bd_net -net pcie_phy_versal_0_support_txn_0 [get_bd_ports txn_0] [get_bd_pins pcie_phy_versal_0_support/txn_0]
  connect_bd_net -net pcie_phy_versal_0_support_txp_0 [get_bd_ports txp_0] [get_bd_pins pcie_phy_versal_0_support/txp_0]
  connect_bd_net -net rxn_0_1 [get_bd_ports rxn_0] [get_bd_pins pcie_phy_versal_0_support/rxn_0]
  connect_bd_net -net rxp_0_1 [get_bd_ports rxp_0] [get_bd_pins pcie_phy_versal_0_support/rxp_0]
  connect_bd_net -net sys_reset_1 [get_bd_ports sys_reset] [get_bd_pins pcie_phy_versal_0/phy_rst_n]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins pcie_phy_versal_0_support/GT_REFCLK1] [get_bd_pins util_ds_buf_0/IBUF_OUT]

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


