
################################################################
# This is a generated script based on design: msgld_fifos
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
#set scripts_vivado_version 2023.1
set current_vivado_version [version -short]

if { $scripts_vivado_version ne "" && [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been major IP version changes between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the parameter settings of the IPs."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source msgld_fifos_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvn3716-vsvb2197-2LHP-e-S-es1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name msgld_fifos

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
xilinx.com:ip:emb_fifo_gen:*\
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
  set FIFO_READ_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:fifo_read_rtl:1.0 FIFO_READ_0 ]

  set FIFO_READ_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:fifo_read_rtl:1.0 FIFO_READ_1 ]

  set FIFO_WRITE_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:fifo_write_rtl:1.0 FIFO_WRITE_0 ]

  set FIFO_WRITE_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:fifo_write_rtl:1.0 FIFO_WRITE_1 ]


  # Create ports
  set data_count_0 [ create_bd_port -dir O -from 8 -to 0 data_count_0 ]
  set data_count_1 [ create_bd_port -dir O -from 8 -to 0 data_count_1 ]
  set data_valid_0 [ create_bd_port -dir O data_valid_0 ]
  set overflow_0 [ create_bd_port -dir O overflow_0 ]
  set prog_empty_0 [ create_bd_port -dir O prog_empty_0 ]
  set prog_empty_1 [ create_bd_port -dir O prog_empty_1 ]
  set prog_full_0 [ create_bd_port -dir O prog_full_0 ]
  set prog_full_1 [ create_bd_port -dir O prog_full_1 ]
  set rd_data_count_0 [ create_bd_port -dir O -from 0 -to 0 rd_data_count_0 ]
  set rd_data_count_1 [ create_bd_port -dir O -from 0 -to 0 rd_data_count_1 ]
  set rd_rst_busy_0 [ create_bd_port -dir O rd_rst_busy_0 ]
  set rd_rst_busy_1 [ create_bd_port -dir O rd_rst_busy_1 ]
  set rst_0 [ create_bd_port -dir I rst_0 ]
  set rst_1 [ create_bd_port -dir I rst_1 ]
  set underflow_0 [ create_bd_port -dir O underflow_0 ]
  set wr_ack_0 [ create_bd_port -dir O wr_ack_0 ]
  set wr_clk_0 [ create_bd_port -dir I -type clk wr_clk_0 ]
  set wr_clk_1 [ create_bd_port -dir I -type clk wr_clk_1 ]
  set wr_data_count_0 [ create_bd_port -dir O -from 8 -to 0 wr_data_count_0 ]
  set wr_data_count_1 [ create_bd_port -dir O -from 8 -to 0 wr_data_count_1 ]
  set wr_rst_busy_0 [ create_bd_port -dir O wr_rst_busy_0 ]
  set wr_rst_busy_1 [ create_bd_port -dir O wr_rst_busy_1 ]

  # Create instance: length_fifo, and set properties
  set length_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_fifo_gen length_fifo ]
  set_property -dict [list \
    CONFIG.CASCADE_HEIGHT {1} \
    CONFIG.ENABLE_ALMOST_EMPTY {false} \
    CONFIG.ENABLE_ALMOST_FULL {false} \
    CONFIG.FIFO_MEMORY_TYPE {URAM} \
    CONFIG.FIFO_READ_LATENCY {2} \
    CONFIG.FIFO_WRITE_DEPTH {256} \
    CONFIG.WRITE_DATA_WIDTH {40} \
  ] $length_fifo


  # Create instance: msgld_fifo, and set properties
  set msgld_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_fifo_gen msgld_fifo ]
  set_property -dict [list \
    CONFIG.CASCADE_HEIGHT {1} \
    CONFIG.ENABLE_ALMOST_EMPTY {false} \
    CONFIG.ENABLE_ALMOST_FULL {false} \
    CONFIG.ENABLE_DATA_COUNT {true} \
    CONFIG.ENABLE_OVERFLOW {false} \
    CONFIG.ENABLE_READ_DATA_VALID {false} \
    CONFIG.ENABLE_UNDERFLOW {false} \
    CONFIG.ENABLE_WRITE_ACK {false} \
    CONFIG.FIFO_MEMORY_TYPE {URAM} \
    CONFIG.FIFO_READ_LATENCY {2} \
    CONFIG.FIFO_WRITE_DEPTH {256} \
    CONFIG.WRITE_DATA_WIDTH {256} \
  ] $msgld_fifo


  # Create interface connections
  connect_bd_intf_net -intf_net FIFO_READ_0_1 [get_bd_intf_ports FIFO_READ_0] [get_bd_intf_pins msgld_fifo/FIFO_READ]
  connect_bd_intf_net -intf_net FIFO_READ_1_1 [get_bd_intf_ports FIFO_READ_1] [get_bd_intf_pins length_fifo/FIFO_READ]
  connect_bd_intf_net -intf_net FIFO_WRITE_0_1 [get_bd_intf_ports FIFO_WRITE_0] [get_bd_intf_pins msgld_fifo/FIFO_WRITE]
  connect_bd_intf_net -intf_net FIFO_WRITE_1_1 [get_bd_intf_ports FIFO_WRITE_1] [get_bd_intf_pins length_fifo/FIFO_WRITE]

  # Create port connections
  connect_bd_net -net emb_fifo_gen_0_data_count [get_bd_ports data_count_1] [get_bd_pins length_fifo/data_count]
  connect_bd_net -net emb_fifo_gen_0_data_valid [get_bd_ports data_valid_0] [get_bd_pins length_fifo/data_valid]
  connect_bd_net -net emb_fifo_gen_0_overflow [get_bd_ports overflow_0] [get_bd_pins length_fifo/overflow]
  connect_bd_net -net emb_fifo_gen_0_prog_empty [get_bd_ports prog_empty_1] [get_bd_pins length_fifo/prog_empty]
  connect_bd_net -net emb_fifo_gen_0_prog_full [get_bd_ports prog_full_1] [get_bd_pins length_fifo/prog_full]
  connect_bd_net -net emb_fifo_gen_0_rd_data_count [get_bd_ports rd_data_count_1] [get_bd_pins length_fifo/rd_data_count]
  connect_bd_net -net emb_fifo_gen_0_rd_rst_busy [get_bd_ports rd_rst_busy_1] [get_bd_pins length_fifo/rd_rst_busy]
  connect_bd_net -net emb_fifo_gen_0_underflow [get_bd_ports underflow_0] [get_bd_pins length_fifo/underflow]
  connect_bd_net -net emb_fifo_gen_0_wr_ack [get_bd_ports wr_ack_0] [get_bd_pins length_fifo/wr_ack]
  connect_bd_net -net emb_fifo_gen_0_wr_data_count [get_bd_ports wr_data_count_1] [get_bd_pins length_fifo/wr_data_count]
  connect_bd_net -net emb_fifo_gen_0_wr_rst_busy [get_bd_ports wr_rst_busy_1] [get_bd_pins length_fifo/wr_rst_busy]
  connect_bd_net -net emb_fifo_gen_1_data_count [get_bd_ports data_count_0] [get_bd_pins msgld_fifo/data_count]
  connect_bd_net -net emb_fifo_gen_1_prog_empty [get_bd_ports prog_empty_0] [get_bd_pins msgld_fifo/prog_empty]
  connect_bd_net -net emb_fifo_gen_1_prog_full [get_bd_ports prog_full_0] [get_bd_pins msgld_fifo/prog_full]
  connect_bd_net -net emb_fifo_gen_1_rd_data_count [get_bd_ports rd_data_count_0] [get_bd_pins msgld_fifo/rd_data_count]
  connect_bd_net -net emb_fifo_gen_1_rd_rst_busy [get_bd_ports rd_rst_busy_0] [get_bd_pins msgld_fifo/rd_rst_busy]
  connect_bd_net -net emb_fifo_gen_1_wr_data_count [get_bd_ports wr_data_count_0] [get_bd_pins msgld_fifo/wr_data_count]
  connect_bd_net -net emb_fifo_gen_1_wr_rst_busy [get_bd_ports wr_rst_busy_0] [get_bd_pins msgld_fifo/wr_rst_busy]
  connect_bd_net -net rst_0_1 [get_bd_ports rst_0] [get_bd_pins msgld_fifo/rst]
  connect_bd_net -net rst_1_1 [get_bd_ports rst_1] [get_bd_pins length_fifo/rst]
  connect_bd_net -net wr_clk_0_1 [get_bd_ports wr_clk_0] [get_bd_pins msgld_fifo/wr_clk]
  connect_bd_net -net wr_clk_1_1 [get_bd_ports wr_clk_1] [get_bd_pins length_fifo/wr_clk]

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


