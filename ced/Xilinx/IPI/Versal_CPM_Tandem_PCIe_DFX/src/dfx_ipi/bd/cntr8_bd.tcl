
################################################################
# This is a generated script based on design: bd_cntr8
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
#
# NOTE - set scripts_vivado_version "" to ignore version check.
################################################################
set scripts_vivado_version ""
#set scripts_vivado_version 2024.1
set current_vivado_version [version -short]

if { $scripts_vivado_version ne "" && [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "CRITICAL WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been changes to the IP between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the functionality and configuration of the design."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source cntr8_bd.tcl

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   error "Source this file only when a project is already created"
}

# CHANGE DESIGN NAME HERE
variable des_name
set des_name bd_cntr8

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $des_name

# Creating design if needed
set errMsg ""
set nRet 0

create_bd_design $des_name
set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${des_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <des_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; des_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; des_name exists in project.

   if { $cur_design ne $des_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <des_name> from <$des_name> to <$cur_design> since current design is empty."
      set des_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $des_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$des_name> already exists in your project, please set the variable <des_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${des_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, des_name exists in project.
   #    7) No opened design, des_name exists in project.

   set errMsg "Design <$des_name> already exists in your project, please set the variable <des_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, des_name not in project.
   #    9) Current opened design, has components, but diff names, des_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$des_name> in project, so creating one..."

   create_bd_design $des_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$des_name> as current_bd_design."
   current_bd_design $des_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <des_name> is equal to \"$des_name\"."

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
xilinx.com:ip:c_counter_binary:*\
xilinx.com:inline_hdl:ilconcat:*\
xilinx.com:inline_hdl:ilconstant:*\
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
proc create_root_design_cnt8 { parentCell } {

  variable script_folder
  variable des_name

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

  # Create ports
  set clk [ create_bd_port -dir I -type clk -freq_hz 249997498 clk ]
  set ce [ create_bd_port -dir I -type ce ce ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $ce
  set up [ create_bd_port -dir I -type data up ]
  set load [ create_bd_port -dir I -type data load ]
  set l [ create_bd_port -dir I -from 15 -to 0 -type data l ]
  set q [ create_bd_port -dir O -from 15 -to 0 -type data q ]

  # Create instance: cntr8, and set properties
  set cntr8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary cntr8 ]
  set_property -dict [list \
    CONFIG.CE {true} \
    CONFIG.Count_Mode {UPDOWN} \
    CONFIG.Load {true} \
    CONFIG.Output_Width {8} \
  ] $cntr8


  # Create instance: ilconcat_0, and set properties
  set ilconcat_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {8} \
    CONFIG.IN1_WIDTH {8} \
  ] $ilconcat_0


  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {8} \
  ] $ilconstant_0

  # Create instance: ilslice_0, and set properties
  set ilslice_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {7} \
    CONFIG.DIN_WIDTH {16} \
  ] $ilslice_0


  # Create port connections
  connect_bd_net -net CE_0_1 [get_bd_ports ce] [get_bd_pins cntr8/CE]
  connect_bd_net -net CLK_0_1 [get_bd_ports clk] [get_bd_pins cntr8/CLK]
  connect_bd_net -net LOAD_0_1 [get_bd_ports load] [get_bd_pins cntr8/LOAD]
  connect_bd_net -net UP_0_1 [get_bd_ports up] [get_bd_pins cntr8/UP]
  connect_bd_net -net cntr8_Q [get_bd_pins cntr8/Q] [get_bd_pins ilconcat_0/In0]
  connect_bd_net -net ilconcat_0_dout [get_bd_pins ilconcat_0/dout] [get_bd_ports q]
  connect_bd_net -net ilconstant_0_dout [get_bd_pins ilconstant_0/dout] [get_bd_pins ilconcat_0/In1]
  connect_bd_net -net ilslice_0_dout [get_bd_pins ilslice_0/Dout] [get_bd_pins cntr8/L]
  connect_bd_net -net ilslice_0_din [get_bd_pins ilslice_0/Din] [get_bd_ports l]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design_cnt8()


##################################################################
# MAIN FLOW
##################################################################

create_root_design_cnt8 ""


