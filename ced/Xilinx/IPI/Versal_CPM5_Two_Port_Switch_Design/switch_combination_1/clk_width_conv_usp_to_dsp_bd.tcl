
################################################################
# This is a generated script based on design: clk_width_conv_usp_to_dsp
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
# source clk_width_conv_usp_to_dsp_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvp1202-vsva2785-2MHP-e-S
}


# CHANGE DESIGN NAME HERE
variable design_name_usp_to_dsp
set design_name_usp_to_dsp clk_width_conv_usp_to_dsp

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name_usp_to_dsp

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name_usp_to_dsp} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name_usp_to_dsp> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name_usp_to_dsp NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name_usp_to_dsp exists in project.

   if { $cur_design ne $design_name_usp_to_dsp } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name_usp_to_dsp> from <$design_name_usp_to_dsp> to <$cur_design> since current design is empty."
      set design_name_usp_to_dsp [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name_usp_to_dsp } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name_usp_to_dsp> already exists in your project, please set the variable <design_name_usp_to_dsp> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name_usp_to_dsp}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name_usp_to_dsp exists in project.
   #    7) No opened design, design_name_usp_to_dsp exists in project.

   set errMsg "Design <$design_name_usp_to_dsp> already exists in your project, please set the variable <design_name_usp_to_dsp> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name_usp_to_dsp not in project.
   #    9) Current opened design, has components, but diff names, design_name_usp_to_dsp not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name_usp_to_dsp> in project, so creating one..."

   create_bd_design $design_name_usp_to_dsp

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name_usp_to_dsp> as current_bd_design."
   current_bd_design $design_name_usp_to_dsp

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name_usp_to_dsp> is equal to \"$design_name_usp_to_dsp\"."

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
xilinx.com:ip:axis_clock_converter:*\
xilinx.com:ip:axis_dwidth_converter:*\
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
  variable design_name_usp_to_dsp

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
  set SRC_S_AXIS_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 SRC_S_AXIS_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {10000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {256} \
   ] $SRC_S_AXIS_0

  set DST_M_AXIS_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 DST_M_AXIS_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {10000000} \
   ] $DST_M_AXIS_0


  # Create ports
  set SRC_s_axis_aclk_0 [ create_bd_port -dir I -type clk -freq_hz 10000000 SRC_s_axis_aclk_0 ]
  set SRC_s_axis_aresetn_0 [ create_bd_port -dir I -type rst SRC_s_axis_aresetn_0 ]
  set dst_m_axis_aclk_0 [ create_bd_port -dir I -type clk -freq_hz 10000000 dst_m_axis_aclk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {dst_m_axis_aresetn_0:dst_user_aresetn_0} \
 ] $dst_m_axis_aclk_0
  set dst_m_axis_aresetn_0 [ create_bd_port -dir I -type rst dst_m_axis_aresetn_0 ]
  set dst_user_aresetn_0 [ create_bd_port -dir I -type rst dst_user_aresetn_0 ]

  # Create instance: axis_clock_converter_0, and set properties
  set axis_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter axis_clock_converter_0 ]
  set_property -dict [list \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.TDATA_NUM_BYTES {64} \
    CONFIG.TUSER_WIDTH {256} \
  ] $axis_clock_converter_0


  # Create instance: axis_dwidth_converter_0, and set properties
  set axis_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter axis_dwidth_converter_0 ]
  set_property -dict [list \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.M_TDATA_NUM_BYTES {64} \
    CONFIG.S_TDATA_NUM_BYTES {64} \
    CONFIG.TUSER_BITS_PER_BYTE {4} \
  ] $axis_dwidth_converter_0


  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_0_1 [get_bd_intf_ports SRC_S_AXIS_0] [get_bd_intf_pins axis_clock_converter_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_clock_converter_0_M_AXIS [get_bd_intf_pins axis_clock_converter_0/M_AXIS] [get_bd_intf_pins axis_dwidth_converter_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS [get_bd_intf_ports DST_M_AXIS_0] [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS]

  # Create port connections
  connect_bd_net -net Net [get_bd_ports dst_m_axis_aclk_0] [get_bd_pins axis_clock_converter_0/m_axis_aclk] [get_bd_pins axis_dwidth_converter_0/aclk]
  connect_bd_net -net aresetn_0_1 [get_bd_ports dst_user_aresetn_0] [get_bd_pins axis_dwidth_converter_0/aresetn]
  connect_bd_net -net dst_m_axis_aresetn_0_1 [get_bd_ports dst_m_axis_aresetn_0] [get_bd_pins axis_clock_converter_0/m_axis_aresetn]
  connect_bd_net -net s_axis_aclk_0_1 [get_bd_ports SRC_s_axis_aclk_0] [get_bd_pins axis_clock_converter_0/s_axis_aclk]
  connect_bd_net -net s_axis_aresetn_0_1 [get_bd_ports SRC_s_axis_aresetn_0] [get_bd_pins axis_clock_converter_0/s_axis_aresetn]

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


