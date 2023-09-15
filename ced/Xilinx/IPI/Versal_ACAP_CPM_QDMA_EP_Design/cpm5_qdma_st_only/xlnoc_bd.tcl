
################################################################
# This is a generated script based on design: xlnoc
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
set scripts_vivado_version ""
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been major IP version changes between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the parameter settings of the IPs."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source xlnoc_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvp1202-vsva2785-2MHP-e-S-es1
}


# CHANGE DESIGN NAME HERE
variable design_name_xlnoc
set design_name_xlnoc xlnoc

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name_xlnoc

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name_xlnoc} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name_xlnoc> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name_xlnoc NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name_xlnoc exists in project.

   if { $cur_design ne $design_name_xlnoc } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name_xlnoc> from <$design_name_xlnoc> to <$cur_design> since current design is empty."
      set design_name_xlnoc [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name_xlnoc } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name_xlnoc> already exists in your project, please set the variable <design_name_xlnoc> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name_xlnoc}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name_xlnoc exists in project.
   #    7) No opened design, design_name_xlnoc exists in project.

   set errMsg "Design <$design_name_xlnoc> already exists in your project, please set the variable <design_name_xlnoc> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name_xlnoc not in project.
   #    9) Current opened design, has components, but diff names, design_name_xlnoc not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name_xlnoc> in project, so creating one..."

   create_bd_design -bdsource IPI $design_name_xlnoc

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name_xlnoc> as current_bd_design."
   current_bd_design $design_name_xlnoc

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name_xlnoc> is equal to \"$design_name_xlnoc\"."

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
xilinx.com:ip:noc_nps:*\
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
  variable design_name_xlnoc

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
  set nps_2_MNPP_S [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:npp_rtl:1.0 nps_2_MNPP_S ]

  set nps_2_SNPP_S [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:npp_rtl:1.0 nps_2_SNPP_S ]

  set nps_5_MNPP_N [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:npp_rtl:1.0 nps_5_MNPP_N ]

  set nps_5_SNPP_N [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:npp_rtl:1.0 nps_5_SNPP_N ]


  # Create ports

  # Create instance: nps_0, and set properties
  set nps_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:noc_nps nps_0 ]
  set_property -dict [list \
    CONFIG.USER_MNORTH_PORT_EN {FALSE} \
    CONFIG.USER_MWEST_PORT_EN {FALSE} \
    CONFIG.USER_SNORTH_PORT_EN {FALSE} \
    CONFIG.USER_SWEST_PORT_EN {FALSE} \
  ] $nps_0


  # Create instance: nps_1, and set properties
  set nps_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:noc_nps nps_1 ]
  set_property -dict [list \
    CONFIG.USER_MEAST_PORT_EN {FALSE} \
    CONFIG.USER_MSOUTH_PORT_EN {FALSE} \
    CONFIG.USER_SEAST_PORT_EN {FALSE} \
    CONFIG.USER_SSOUTH_PORT_EN {FALSE} \
  ] $nps_1


  # Create instance: nps_2, and set properties
  set nps_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:noc_nps nps_2 ]
  set_property -dict [list \
    CONFIG.USER_MEAST_PORT_EN {FALSE} \
    CONFIG.USER_MNORTH_PORT_EN {FALSE} \
    CONFIG.USER_SEAST_PORT_EN {FALSE} \
    CONFIG.USER_SNORTH_PORT_EN {FALSE} \
  ] $nps_2


  # Create instance: nps_3, and set properties
  set nps_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:noc_nps nps_3 ]
  set_property -dict [list \
    CONFIG.USER_MNORTH_PORT_EN {FALSE} \
    CONFIG.USER_MSOUTH_PORT_EN {FALSE} \
    CONFIG.USER_SNORTH_PORT_EN {FALSE} \
    CONFIG.USER_SSOUTH_PORT_EN {FALSE} \
  ] $nps_3


  # Create instance: nps_4, and set properties
  set nps_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:noc_nps nps_4 ]
  set_property -dict [list \
    CONFIG.USER_MNORTH_PORT_EN {FALSE} \
    CONFIG.USER_MSOUTH_PORT_EN {FALSE} \
    CONFIG.USER_SNORTH_PORT_EN {FALSE} \
    CONFIG.USER_SSOUTH_PORT_EN {FALSE} \
  ] $nps_4


  # Create instance: nps_5, and set properties
  set nps_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:noc_nps nps_5 ]
  set_property -dict [list \
    CONFIG.USER_MSOUTH_PORT_EN {FALSE} \
    CONFIG.USER_MWEST_PORT_EN {FALSE} \
    CONFIG.USER_SSOUTH_PORT_EN {FALSE} \
    CONFIG.USER_SWEST_PORT_EN {FALSE} \
  ] $nps_5


  # Create interface connections
  connect_bd_intf_net -intf_net nps_0_MNPP_E [get_bd_intf_pins nps_0/MNPP_E] [get_bd_intf_pins nps_2/SNPP_W]
  connect_bd_intf_net -intf_net nps_0_MNPP_S [get_bd_intf_pins nps_0/MNPP_S] [get_bd_intf_pins nps_1/SNPP_N]
  connect_bd_intf_net -intf_net nps_1_MNPP_N [get_bd_intf_pins nps_0/SNPP_S] [get_bd_intf_pins nps_1/MNPP_N]
  connect_bd_intf_net -intf_net nps_1_MNPP_W [get_bd_intf_pins nps_1/MNPP_W] [get_bd_intf_pins nps_4/SNPP_E]
  connect_bd_intf_net -intf_net nps_2_MNPP_S1 [get_bd_intf_ports nps_2_MNPP_S] [get_bd_intf_pins nps_2/MNPP_S]
  connect_bd_intf_net -intf_net nps_2_MNPP_W [get_bd_intf_pins nps_0/SNPP_E] [get_bd_intf_pins nps_2/MNPP_W]
  connect_bd_intf_net -intf_net nps_2_SNPP_S_1 [get_bd_intf_ports nps_2_SNPP_S] [get_bd_intf_pins nps_2/SNPP_S]
  connect_bd_intf_net -intf_net nps_3_MNPP_E [get_bd_intf_pins nps_3/MNPP_E] [get_bd_intf_pins nps_4/SNPP_W]
  connect_bd_intf_net -intf_net nps_3_MNPP_W [get_bd_intf_pins nps_3/MNPP_W] [get_bd_intf_pins nps_5/SNPP_E]
  connect_bd_intf_net -intf_net nps_4_MNPP_E [get_bd_intf_pins nps_1/SNPP_W] [get_bd_intf_pins nps_4/MNPP_E]
  connect_bd_intf_net -intf_net nps_4_MNPP_W [get_bd_intf_pins nps_3/SNPP_E] [get_bd_intf_pins nps_4/MNPP_W]
  connect_bd_intf_net -intf_net nps_5_MNPP_E [get_bd_intf_pins nps_3/SNPP_W] [get_bd_intf_pins nps_5/MNPP_E]
  connect_bd_intf_net -intf_net nps_5_MNPP_N1 [get_bd_intf_ports nps_5_MNPP_N] [get_bd_intf_pins nps_5/MNPP_N]
  connect_bd_intf_net -intf_net nps_5_SNPP_N_1 [get_bd_intf_ports nps_5_SNPP_N] [get_bd_intf_pins nps_5/SNPP_N]

  # Create port connections

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


