
################################################################
# This is a generated script based on design: cdm_usr_ram
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
set scripts_vivado_version 2022.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been major IP version changes between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the parameter settings of the IPs."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source cdm_usr_ram_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvn3716-vsvb2197-2MHP-e-S-es1
}


# CHANGE DESIGN NAME HERE
variable design_name_usr_ram
set design_name_usr_ram cdm_usr_ram

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name_usr_ram

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name_usr_ram} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name_usr_ram> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name_usr_ram NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name_usr_ram exists in project.

   if { $cur_design ne $design_name_usr_ram } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name_usr_ram> from <$design_name_usr_ram> to <$cur_design> since current design is empty."
      set design_name_usr_ram [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name_usr_ram } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name_usr_ram> already exists in your project, please set the variable <design_name_usr_ram> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name_usr_ram}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name_usr_ram exists in project.
   #    7) No opened design, design_name_usr_ram exists in project.

   set errMsg "Design <$design_name_usr_ram> already exists in your project, please set the variable <design_name_usr_ram> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name_usr_ram not in project.
   #    9) Current opened design, has components, but diff names, design_name_usr_ram not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name_usr_ram> in project, so creating one..."

   create_bd_design $design_name_usr_ram

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name_usr_ram> as current_bd_design."
   current_bd_design $design_name_usr_ram

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name_usr_ram> is equal to \"$design_name_usr_ram\"."

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
xilinx.com:ip:emb_mem_gen:*\
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:smartconnect:*\
xilinx.com:ip:util_vector_logic:*\
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
  variable design_name_usr_ram

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
  set M_CDM_ADAPT_CTRL_REGS [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_CDM_ADAPT_CTRL_REGS ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $M_CDM_ADAPT_CTRL_REGS

  set S_AXI_CDM [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CDM ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S_AXI_CDM


  # Create ports
  set MSGLD_CMD_RAM_addrb [ create_bd_port -dir I -from 31 -to 0 MSGLD_CMD_RAM_addrb ]
  set MSGLD_CMD_RAM_doutb [ create_bd_port -dir O -from 31 -to 0 MSGLD_CMD_RAM_doutb ]
  set MSGLD_CMD_RAM_enb [ create_bd_port -dir I MSGLD_CMD_RAM_enb ]
  set MSGLD_Payload_RAM_addrb [ create_bd_port -dir I -from 31 -to 0 MSGLD_Payload_RAM_addrb ]
  set MSGLD_Payload_RAM_dinb [ create_bd_port -dir I -from 255 -to 0 MSGLD_Payload_RAM_dinb ]
  set MSGLD_Payload_RAM_web [ create_bd_port -dir I -from 31 -to 0 MSGLD_Payload_RAM_web ]
  set MSGST_CMD_RAM_addrb [ create_bd_port -dir I -from 31 -to 0 MSGST_CMD_RAM_addrb ]
  set MSGST_CMD_RAM_doutb [ create_bd_port -dir O -from 31 -to 0 MSGST_CMD_RAM_doutb ]
  set MSGST_CMD_RAM_enb [ create_bd_port -dir I MSGST_CMD_RAM_enb ]
  set MSGST_Payload_RAM_addrb [ create_bd_port -dir I -from 31 -to 0 MSGST_Payload_RAM_addrb ]
  set MSGST_Payload_RAM_dinb [ create_bd_port -dir I -from 255 -to 0 MSGST_Payload_RAM_dinb ]
  set MSGST_Payload_RAM_web [ create_bd_port -dir I -from 31 -to 0 MSGST_Payload_RAM_web ]
  set MSG_Response_RAM_addrb [ create_bd_port -dir I -from 31 -to 0 MSG_Response_RAM_addrb ]
  set MSG_Response_RAM_dinb [ create_bd_port -dir I -from 31 -to 0 MSG_Response_RAM_dinb ]
  set MSG_Response_RAM_web [ create_bd_port -dir I -from 3 -to 0 MSG_Response_RAM_web ]
  set clk_in [ create_bd_port -dir I -type clk clk_in ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S_AXI_CDM:M_CDM_ADAPT_CTRL_REGS} \
 ] $clk_in
  set rst_n [ create_bd_port -dir I -type rst rst_n ]

  # Create instance: MSGLD_CMD_RAM, and set properties
  set MSGLD_CMD_RAM [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen MSGLD_CMD_RAM ]
  set_property -dict [list \
    CONFIG.ENABLE_32BIT_ADDRESS {true} \
    CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
  ] $MSGLD_CMD_RAM


  # Create instance: MSGLD_CMD_bram_ctrl, and set properties
  set MSGLD_CMD_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl MSGLD_CMD_bram_ctrl ]
  set_property -dict [list \
    CONFIG.PROTOCOL {AXI4LITE} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $MSGLD_CMD_bram_ctrl


  # Create instance: MSGLD_Payload_RAM, and set properties
  set MSGLD_Payload_RAM [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen MSGLD_Payload_RAM ]
  set_property -dict [list \
    CONFIG.ENABLE_32BIT_ADDRESS {true} \
    CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
  ] $MSGLD_Payload_RAM


  # Create instance: MSGLD_Payload_bram_ctrl, and set properties
  set MSGLD_Payload_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl MSGLD_Payload_bram_ctrl ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {256} \
    CONFIG.PROTOCOL {AXI4} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $MSGLD_Payload_bram_ctrl


  # Create instance: MSGST_CMD_RAM, and set properties
  set MSGST_CMD_RAM [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen MSGST_CMD_RAM ]
  set_property -dict [list \
    CONFIG.ENABLE_32BIT_ADDRESS {true} \
    CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
  ] $MSGST_CMD_RAM


  # Create instance: MSGST_CMD_bram_ctrl, and set properties
  set MSGST_CMD_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl MSGST_CMD_bram_ctrl ]
  set_property -dict [list \
    CONFIG.PROTOCOL {AXI4LITE} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $MSGST_CMD_bram_ctrl


  # Create instance: MSGST_Payload_RAM, and set properties
  set MSGST_Payload_RAM [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen MSGST_Payload_RAM ]
  set_property -dict [list \
    CONFIG.ENABLE_32BIT_ADDRESS {true} \
    CONFIG.MEMORY_INIT_FILE {None} \
    CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
  ] $MSGST_Payload_RAM


  # Create instance: MSGST_Payload_bram_ctrl, and set properties
  set MSGST_Payload_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl MSGST_Payload_bram_ctrl ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {256} \
    CONFIG.PROTOCOL {AXI4} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $MSGST_Payload_bram_ctrl


  # Create instance: MSG_Response_RAM, and set properties
  set MSG_Response_RAM [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen MSG_Response_RAM ]
  set_property -dict [list \
    CONFIG.ENABLE_32BIT_ADDRESS {true} \
    CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
  ] $MSG_Response_RAM


  # Create instance: MSG_Response_bram_ctrl, and set properties
  set MSG_Response_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl MSG_Response_bram_ctrl ]
  set_property -dict [list \
    CONFIG.PROTOCOL {AXI4LITE} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $MSG_Response_bram_ctrl


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {6} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_0 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_0


  # Create interface connections
  connect_bd_intf_net -intf_net MSGLD_CMD_bram_ctrl_BRAM_PORTA [get_bd_intf_pins MSGLD_CMD_RAM/BRAM_PORTA] [get_bd_intf_pins MSGLD_CMD_bram_ctrl/BRAM_PORTA]
  connect_bd_intf_net -intf_net MSGLD_Payload_bram_ctrl_BRAM_PORTA [get_bd_intf_pins MSGLD_Payload_RAM/BRAM_PORTA] [get_bd_intf_pins MSGLD_Payload_bram_ctrl/BRAM_PORTA]
  connect_bd_intf_net -intf_net MSGST_CMD_bram_ctrl_BRAM_PORTA [get_bd_intf_pins MSGST_CMD_RAM/BRAM_PORTA] [get_bd_intf_pins MSGST_CMD_bram_ctrl/BRAM_PORTA]
  connect_bd_intf_net -intf_net MSGST_Payload_bram_ctrl_BRAM_PORTA [get_bd_intf_pins MSGST_Payload_RAM/BRAM_PORTA] [get_bd_intf_pins MSGST_Payload_bram_ctrl/BRAM_PORTA]
  connect_bd_intf_net -intf_net MSG_Response_bram_ctrl_BRAM_PORTA [get_bd_intf_pins MSG_Response_RAM/BRAM_PORTA] [get_bd_intf_pins MSG_Response_bram_ctrl/BRAM_PORTA]
  connect_bd_intf_net -intf_net S_AXI_CDM_1 [get_bd_intf_ports S_AXI_CDM] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins MSGST_Payload_bram_ctrl/S_AXI] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_ports M_CDM_ADAPT_CTRL_REGS] [get_bd_intf_pins smartconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins MSGST_CMD_bram_ctrl/S_AXI] [get_bd_intf_pins smartconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins MSGLD_CMD_bram_ctrl/S_AXI] [get_bd_intf_pins smartconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins MSGLD_Payload_bram_ctrl/S_AXI] [get_bd_intf_pins smartconnect_0/M04_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M05_AXI [get_bd_intf_pins MSG_Response_bram_ctrl/S_AXI] [get_bd_intf_pins smartconnect_0/M05_AXI]

  # Create port connections
  connect_bd_net -net MSGLD_CMD_RAM_addrb_1 [get_bd_ports MSGLD_CMD_RAM_addrb] [get_bd_pins MSGLD_CMD_RAM/addrb]
  connect_bd_net -net MSGLD_CMD_RAM_doutb1 [get_bd_ports MSGLD_CMD_RAM_doutb] [get_bd_pins MSGLD_CMD_RAM/doutb]
  connect_bd_net -net MSGLD_CMD_RAM_enb_1 [get_bd_ports MSGLD_CMD_RAM_enb] [get_bd_pins MSGLD_CMD_RAM/enb]
  connect_bd_net -net MSGLD_Payload_RAM_addrb_1 [get_bd_ports MSGLD_Payload_RAM_addrb] [get_bd_pins MSGLD_Payload_RAM/addrb]
  connect_bd_net -net MSGLD_Payload_RAM_dinb_1 [get_bd_ports MSGLD_Payload_RAM_dinb] [get_bd_pins MSGLD_Payload_RAM/dinb]
  connect_bd_net -net MSGLD_Payload_RAM_web_1 [get_bd_ports MSGLD_Payload_RAM_web] [get_bd_pins MSGLD_Payload_RAM/web]
  connect_bd_net -net MSGST_CMD_RAM_addrb_1 [get_bd_ports MSGST_CMD_RAM_addrb] [get_bd_pins MSGST_CMD_RAM/addrb]
  connect_bd_net -net MSGST_CMD_RAM_doutb1 [get_bd_ports MSGST_CMD_RAM_doutb] [get_bd_pins MSGST_CMD_RAM/doutb]
  connect_bd_net -net MSGST_CMD_RAM_enb_1 [get_bd_ports MSGST_CMD_RAM_enb] [get_bd_pins MSGST_CMD_RAM/enb]
  connect_bd_net -net MSGST_Payload_RAM_addrb_1 [get_bd_ports MSGST_Payload_RAM_addrb] [get_bd_pins MSGST_Payload_RAM/addrb]
  connect_bd_net -net MSGST_Payload_RAM_dinb_1 [get_bd_ports MSGST_Payload_RAM_dinb] [get_bd_pins MSGST_Payload_RAM/dinb]
  connect_bd_net -net MSGST_Payload_RAM_web_1 [get_bd_ports MSGST_Payload_RAM_web] [get_bd_pins MSGST_Payload_RAM/web]
  connect_bd_net -net MSG_Response_RAM_addrb_1 [get_bd_ports MSG_Response_RAM_addrb] [get_bd_pins MSG_Response_RAM/addrb]
  connect_bd_net -net MSG_Response_RAM_dinb_1 [get_bd_ports MSG_Response_RAM_dinb] [get_bd_pins MSG_Response_RAM/dinb]
  connect_bd_net -net MSG_Response_RAM_web_1 [get_bd_ports MSG_Response_RAM_web] [get_bd_pins MSG_Response_RAM/web]
  connect_bd_net -net clk_in_1 [get_bd_ports clk_in] [get_bd_pins MSGLD_CMD_RAM/clkb] [get_bd_pins MSGLD_CMD_bram_ctrl/s_axi_aclk] [get_bd_pins MSGLD_Payload_RAM/clkb] [get_bd_pins MSGLD_Payload_bram_ctrl/s_axi_aclk] [get_bd_pins MSGST_CMD_RAM/clkb] [get_bd_pins MSGST_CMD_bram_ctrl/s_axi_aclk] [get_bd_pins MSGST_Payload_RAM/clkb] [get_bd_pins MSGST_Payload_bram_ctrl/s_axi_aclk] [get_bd_pins MSG_Response_RAM/clkb] [get_bd_pins MSG_Response_bram_ctrl/s_axi_aclk] [get_bd_pins smartconnect_0/aclk]
  connect_bd_net -net rst_n_1 [get_bd_ports rst_n] [get_bd_pins MSGLD_CMD_bram_ctrl/s_axi_aresetn] [get_bd_pins MSGLD_Payload_bram_ctrl/s_axi_aresetn] [get_bd_pins MSGST_CMD_bram_ctrl/s_axi_aresetn] [get_bd_pins MSGST_Payload_bram_ctrl/s_axi_aresetn] [get_bd_pins MSG_Response_bram_ctrl/s_axi_aresetn] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins MSGLD_CMD_RAM/rstb] [get_bd_pins MSGLD_Payload_RAM/rstb] [get_bd_pins MSGST_CMD_RAM/rstb] [get_bd_pins MSGST_Payload_RAM/rstb] [get_bd_pins MSG_Response_RAM/rstb] [get_bd_pins util_vector_logic_0/Res]

  # Create address segments
  assign_bd_address -offset 0x00004000 -range 0x00002000 -target_address_space [get_bd_addr_spaces S_AXI_CDM] [get_bd_addr_segs MSGLD_CMD_bram_ctrl/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00010000 -range 0x00008000 -target_address_space [get_bd_addr_spaces S_AXI_CDM] [get_bd_addr_segs MSGLD_Payload_bram_ctrl/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces S_AXI_CDM] [get_bd_addr_segs MSGST_CMD_bram_ctrl/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00008000 -range 0x00008000 -target_address_space [get_bd_addr_spaces S_AXI_CDM] [get_bd_addr_segs MSGST_Payload_bram_ctrl/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00020000 -range 0x00002000 -target_address_space [get_bd_addr_spaces S_AXI_CDM] [get_bd_addr_segs MSG_Response_bram_ctrl/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S_AXI_CDM] [get_bd_addr_segs M_CDM_ADAPT_CTRL_REGS/Reg] -force


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


