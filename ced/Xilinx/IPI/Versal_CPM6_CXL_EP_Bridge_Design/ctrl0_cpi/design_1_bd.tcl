
################################################################
# This is a generated script based on design: cpm6_cxl_ep_brg
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
#set scripts_vivado_version 2026.1
#set current_vivado_version [version -short]
#
#if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
#   puts ""
#   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
#      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}
#
#   } else {
#     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}
#
#   }
#
#   return 1
#}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source cpm6_cxl_ep_brg_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# ctrl_reg_ep

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc2vp3602-vsvc3340-3HP-e-S
}

# Use existing design_name if already set (CED context), else default to design_1
if {![info exists design_name]} {
    set design_name design_1
}


# CHANGE DESIGN NAME HERE
#variable design_name
#set design_name cpm6_cxl_ep_brg

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
xilinx.com:ip:ps_wizard:*\
xilinx.com:ip:proc_sys_reset:*\
xilinx.com:ip:smartconnect:*\
xilinx.com:inline_hdl:ilconstant:*\
xilinx.com:ip:axi_noc2:*\
xilinx.com:ip:ddrmc5_responder:*\
xilinx.com:ip:axi_bram_ctrl:*\
xilinx.com:ip:emb_mem_gen:*\
xilinx.com:ip:util_ds_buf:*\
user.org:user:cxl_mem_wrapper:*\
xilinx.com:ip:axi_memory_init:*\
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

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
ctrl_reg_ep\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
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


# Hierarchical cell: PA_3
proc create_hier_cell_PA_3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_PA_3() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_global_rtl:1.0 cpi_a2f_global

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_global_rtl:1.0 cpi_f2a_global

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_req_rtl:1.0 cpi_a2f_req

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 cpi_a2f_data

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_rsp_rtl:1.0 cpi_f2a_rsp

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 cpi_f2a_data

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI


  # Create pins
  create_bd_pin -dir I -type clk pl0_ref_clk_0
  create_bd_pin -dir I -type rst resetn
  create_bd_pin -dir I -from 63 -to 0 cxl_mem0_base
  create_bd_pin -dir O dbg_cpi_req_valid
  create_bd_pin -dir O dbg_cpi_data_valid
  create_bd_pin -dir I cxl_mem0_en
  create_bd_pin -dir I init_complete_in
  # Raw counter source, driven from cxl_mem_wrapper_0/cxl_debug_bus below -
  # see ctrl_reg_ep.v's pa_dbg_cxl_bus port comment for the per-bit layout.
  create_bd_pin -dir O -from 15 -to 0 dbg_cxl_bus

  # Create instance: cxl_mem_wrapper_0, and set properties
  set cxl_mem_wrapper_0 [ create_bd_cell -type ip -vlnv user.org:user:cxl_mem_wrapper:1.0 cxl_mem_wrapper_0 ]
  set_property -dict [list \
    CONFIG.C_DDR_BASE {0x000000C000000000} \
    CONFIG.C_M0_AXI_HDM_BASEADDR {0x000000C000000000} \
    CONFIG.C_M0_AXI_HDM_HIGHADDR {0x000000C3FFFFFFFF} \
    CONFIG.C_MEM0_CPI_A2F_MAX_CREDIT {256} \
    CONFIG.C_MEM0_CPI_F2A_MAX_CREDIT {256} \
    CONFIG.C_NUM_PA {4} \
  ] $cxl_mem_wrapper_0

  # m0_axi_hdm bus-interface metadata: only these 5 properties are
  # writable on this cell's m0_axi_hdm pin - everything else (widths,
  # HAS_*, PROTOCOL, ID_WIDTH, NUM_READ/WRITE_OUTSTANDING,
  # MAX_BURST_LENGTH, etc.) is locked read-only, derived from the RTL's
  # own port declarations at IP-packaging time (component.xml) -
  # attempting to set them threw CRITICAL WARNING [BD 41-737] "It is
  # read-only" (confirmed empirically against the full 28-property list
  # previously set here). Trimmed to the confirmed-writable subset to
  # eliminate that warning; no functional effect since the dropped
  # properties were already unconditionally ignored.
  set_property -dict [list \
    CONFIG.FREQ_HZ {320000000} \
    CONFIG.NUM_READ_THREADS {1} \
    CONFIG.NUM_WRITE_THREADS {1} \
    CONFIG.RUSER_BITS_PER_BYTE {0} \
    CONFIG.WUSER_BITS_PER_BYTE {0} \
  ] [get_bd_intf_pins $cxl_mem_wrapper_0/m0_axi_hdm]


  # Create instance: axi_memory_init_3, and set properties
  set axi_memory_init_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_memory_init:1.0 axi_memory_init_3 ]
  set_property -dict [list \
    CONFIG.ADDR_SIZE {32} \
    CONFIG.ADDR_WIDTH {40} \
    CONFIG.BASE_ADDR {0x000000C000000000} \
    CONFIG.DATA_WIDTH {512} \
  ] $axi_memory_init_3

  # SIM-ONLY: shrink the memory-init sweep to 1KB (matches
  # cxl_mem_wr_rd_4consec_seq's real traffic footprint - hdm_base+0..192,
  # see sim/verif/test/seq/cxl_mem_wr_rd_4consec_seq.sv) so sim doesn't
  # have to wait through the full 4GB real-HW sweep before real CXL.mem
  # traffic can pass through. Real HW/synthesis builds are unaffected -
  # this only fires when SIM_QUICK_MEM_INIT=1 is exported by the sim
  # launch script, never set for a synthesis/implementation run.
  if {[info exists ::env(SIM_QUICK_MEM_INIT)] && $::env(SIM_QUICK_MEM_INIT) eq "1"} {
    set_property CONFIG.ADDR_SIZE {10} $axi_memory_init_3
    puts "INFO: SIM_QUICK_MEM_INIT=1 - axi_memory_init_3 ADDR_SIZE -> 10 (1KB sweep, sim only)"
  }

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins axi_memory_init_3/M_AXI] [get_bd_intf_pins M_AXI]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_data [get_bd_intf_pins cpi_f2a_data] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_data]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_global [get_bd_intf_pins cpi_f2a_global] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_global]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_rsp [get_bd_intf_pins cpi_f2a_rsp] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_rsp]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_m0_axi_hdm [get_bd_intf_pins cxl_mem_wrapper_0/m0_axi_hdm] [get_bd_intf_pins axi_memory_init_3/S_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_data [get_bd_intf_pins cpi_a2f_data] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_data]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_global [get_bd_intf_pins cpi_a2f_global] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_global]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_req [get_bd_intf_pins cpi_a2f_req] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_req]

  # Create port connections
  connect_bd_net -net cxl_mem0_base_1  [get_bd_pins cxl_mem0_base] \
  [get_bd_pins cxl_mem_wrapper_0/cxl_mem0_base]
  connect_bd_net -net cxl_mem0_en_1  [get_bd_pins cxl_mem0_en] \
  [get_bd_pins cxl_mem_wrapper_0/cxl_mem0_en]
  connect_bd_net -net cxl_mem_wrapper_0_cxl_debug_bus [get_bd_pins cxl_mem_wrapper_0/cxl_debug_bus] [get_bd_pins dbg_cxl_bus]
  connect_bd_net -net init_complete_in_1  [get_bd_pins init_complete_in] \
  [get_bd_pins axi_memory_init_3/init_complete_in]
  connect_bd_net -net pl0_ref_clk_0_1  [get_bd_pins pl0_ref_clk_0] \
  [get_bd_pins cxl_mem_wrapper_0/clk] \
  [get_bd_pins axi_memory_init_3/aclk]
  connect_bd_net -net resetn_1  [get_bd_pins resetn] \
  [get_bd_pins cxl_mem_wrapper_0/resetn] \
  [get_bd_pins axi_memory_init_3/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: PA_2
proc create_hier_cell_PA_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_PA_2() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_global_rtl:1.0 cpi_a2f_global

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_global_rtl:1.0 cpi_f2a_global

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_req_rtl:1.0 cpi_a2f_req

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 cpi_a2f_data

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_rsp_rtl:1.0 cpi_f2a_rsp

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 cpi_f2a_data

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI


  # Create pins
  create_bd_pin -dir I -type clk pl0_ref_clk_0
  create_bd_pin -dir I -type rst resetn
  create_bd_pin -dir I -from 63 -to 0 cxl_mem0_base
  create_bd_pin -dir I cxl_mem0_en
  create_bd_pin -dir I init_complete_in
  # Raw counter source, driven from cxl_mem_wrapper_0/cxl_debug_bus below -
  # see ctrl_reg_ep.v's pa_dbg_cxl_bus port comment for the per-bit layout.
  create_bd_pin -dir O -from 15 -to 0 dbg_cxl_bus

  # Create instance: cxl_mem_wrapper_0, and set properties
  set cxl_mem_wrapper_0 [ create_bd_cell -type ip -vlnv user.org:user:cxl_mem_wrapper:1.0 cxl_mem_wrapper_0 ]
  set_property -dict [list \
    CONFIG.C_DDR_BASE {0x000000C000000000} \
    CONFIG.C_M0_AXI_HDM_BASEADDR {0x000000C000000000} \
    CONFIG.C_M0_AXI_HDM_HIGHADDR {0x000000C3FFFFFFFF} \
    CONFIG.C_MEM0_CPI_A2F_MAX_CREDIT {256} \
    CONFIG.C_MEM0_CPI_F2A_MAX_CREDIT {256} \
    CONFIG.C_NUM_PA {4} \
  ] $cxl_mem_wrapper_0

  # m0_axi_hdm bus-interface metadata: only these 5 properties are
  # writable on this cell's m0_axi_hdm pin - everything else (widths,
  # HAS_*, PROTOCOL, ID_WIDTH, NUM_READ/WRITE_OUTSTANDING,
  # MAX_BURST_LENGTH, etc.) is locked read-only, derived from the RTL's
  # own port declarations at IP-packaging time (component.xml) -
  # attempting to set them threw CRITICAL WARNING [BD 41-737] "It is
  # read-only" (confirmed empirically against the full 28-property list
  # previously set here). Trimmed to the confirmed-writable subset to
  # eliminate that warning; no functional effect since the dropped
  # properties were already unconditionally ignored.
  set_property -dict [list \
    CONFIG.FREQ_HZ {320000000} \
    CONFIG.NUM_READ_THREADS {1} \
    CONFIG.NUM_WRITE_THREADS {1} \
    CONFIG.RUSER_BITS_PER_BYTE {0} \
    CONFIG.WUSER_BITS_PER_BYTE {0} \
  ] [get_bd_intf_pins $cxl_mem_wrapper_0/m0_axi_hdm]


  # Create instance: axi_memory_init_2, and set properties
  set axi_memory_init_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_memory_init:1.0 axi_memory_init_2 ]
  set_property -dict [list \
    CONFIG.ADDR_SIZE {32} \
    CONFIG.ADDR_WIDTH {40} \
    CONFIG.BASE_ADDR {0x000000C000000000} \
    CONFIG.DATA_WIDTH {512} \
  ] $axi_memory_init_2

  # SIM-ONLY: shrink the memory-init sweep to 1KB (matches
  # cxl_mem_wr_rd_4consec_seq's real traffic footprint - hdm_base+0..192,
  # see sim/verif/test/seq/cxl_mem_wr_rd_4consec_seq.sv) so sim doesn't
  # have to wait through the full 4GB real-HW sweep before real CXL.mem
  # traffic can pass through. Real HW/synthesis builds are unaffected -
  # this only fires when SIM_QUICK_MEM_INIT=1 is exported by the sim
  # launch script, never set for a synthesis/implementation run.
  if {[info exists ::env(SIM_QUICK_MEM_INIT)] && $::env(SIM_QUICK_MEM_INIT) eq "1"} {
    set_property CONFIG.ADDR_SIZE {10} $axi_memory_init_2
    puts "INFO: SIM_QUICK_MEM_INIT=1 - axi_memory_init_2 ADDR_SIZE -> 10 (1KB sweep, sim only)"
  }

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins axi_memory_init_2/M_AXI] [get_bd_intf_pins M_AXI]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_data [get_bd_intf_pins cpi_f2a_data] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_data]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_global [get_bd_intf_pins cpi_f2a_global] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_global]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_rsp [get_bd_intf_pins cpi_f2a_rsp] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_rsp]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_m0_axi_hdm [get_bd_intf_pins cxl_mem_wrapper_0/m0_axi_hdm] [get_bd_intf_pins axi_memory_init_2/S_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_data [get_bd_intf_pins cpi_a2f_data] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_data]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_global [get_bd_intf_pins cpi_a2f_global] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_global]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_req [get_bd_intf_pins cpi_a2f_req] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_req]

  # Create port connections
  connect_bd_net -net cxl_mem0_base_1  [get_bd_pins cxl_mem0_base] \
  [get_bd_pins cxl_mem_wrapper_0/cxl_mem0_base]
  connect_bd_net -net cxl_mem0_en_1  [get_bd_pins cxl_mem0_en] \
  [get_bd_pins cxl_mem_wrapper_0/cxl_mem0_en]
  connect_bd_net -net cxl_mem_wrapper_0_cxl_debug_bus [get_bd_pins cxl_mem_wrapper_0/cxl_debug_bus] [get_bd_pins dbg_cxl_bus]
  connect_bd_net -net init_complete_in_1  [get_bd_pins init_complete_in] \
  [get_bd_pins axi_memory_init_2/init_complete_in]
  connect_bd_net -net pl0_ref_clk_0_1  [get_bd_pins pl0_ref_clk_0] \
  [get_bd_pins cxl_mem_wrapper_0/clk] \
  [get_bd_pins axi_memory_init_2/aclk]
  connect_bd_net -net resetn_1  [get_bd_pins resetn] \
  [get_bd_pins cxl_mem_wrapper_0/resetn] \
  [get_bd_pins axi_memory_init_2/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: PA_1
proc create_hier_cell_PA_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_PA_1() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_global_rtl:1.0 cpi_a2f_global

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_global_rtl:1.0 cpi_f2a_global

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_req_rtl:1.0 cpi_a2f_req

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 cpi_a2f_data

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_rsp_rtl:1.0 cpi_f2a_rsp

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 cpi_f2a_data

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI


  # Create pins
  create_bd_pin -dir I -type clk pl0_ref_clk_0
  create_bd_pin -dir I -type rst resetn
  create_bd_pin -dir I -from 63 -to 0 cxl_mem0_base
  create_bd_pin -dir I cxl_mem0_en
  create_bd_pin -dir I init_complete_in
  # Raw counter source, driven from cxl_mem_wrapper_0/cxl_debug_bus below -
  # see ctrl_reg_ep.v's pa_dbg_cxl_bus port comment for the per-bit layout.
  create_bd_pin -dir O -from 15 -to 0 dbg_cxl_bus

  # Create instance: cxl_mem_wrapper_0, and set properties
  set cxl_mem_wrapper_0 [ create_bd_cell -type ip -vlnv user.org:user:cxl_mem_wrapper:1.0 cxl_mem_wrapper_0 ]
  set_property -dict [list \
    CONFIG.C_DDR_BASE {0x000000C000000000} \
    CONFIG.C_M0_AXI_HDM_BASEADDR {0x000000C000000000} \
    CONFIG.C_M0_AXI_HDM_HIGHADDR {0x000000C3FFFFFFFF} \
    CONFIG.C_MEM0_CPI_A2F_MAX_CREDIT {256} \
    CONFIG.C_MEM0_CPI_F2A_MAX_CREDIT {256} \
    CONFIG.C_NUM_PA {4} \
  ] $cxl_mem_wrapper_0

  # m0_axi_hdm bus-interface metadata: only these 5 properties are
  # writable on this cell's m0_axi_hdm pin - everything else (widths,
  # HAS_*, PROTOCOL, ID_WIDTH, NUM_READ/WRITE_OUTSTANDING,
  # MAX_BURST_LENGTH, etc.) is locked read-only, derived from the RTL's
  # own port declarations at IP-packaging time (component.xml) -
  # attempting to set them threw CRITICAL WARNING [BD 41-737] "It is
  # read-only" (confirmed empirically against the full 28-property list
  # previously set here). Trimmed to the confirmed-writable subset to
  # eliminate that warning; no functional effect since the dropped
  # properties were already unconditionally ignored.
  set_property -dict [list \
    CONFIG.FREQ_HZ {320000000} \
    CONFIG.NUM_READ_THREADS {1} \
    CONFIG.NUM_WRITE_THREADS {1} \
    CONFIG.RUSER_BITS_PER_BYTE {0} \
    CONFIG.WUSER_BITS_PER_BYTE {0} \
  ] [get_bd_intf_pins $cxl_mem_wrapper_0/m0_axi_hdm]


  # Create instance: axi_memory_init_1, and set properties
  set axi_memory_init_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_memory_init:1.0 axi_memory_init_1 ]
  set_property -dict [list \
    CONFIG.ADDR_SIZE {32} \
    CONFIG.ADDR_WIDTH {40} \
    CONFIG.BASE_ADDR {0x000000C000000000} \
    CONFIG.DATA_WIDTH {512} \
  ] $axi_memory_init_1

  # SIM-ONLY: shrink the memory-init sweep to 1KB (matches
  # cxl_mem_wr_rd_4consec_seq's real traffic footprint - hdm_base+0..192,
  # see sim/verif/test/seq/cxl_mem_wr_rd_4consec_seq.sv) so sim doesn't
  # have to wait through the full 4GB real-HW sweep before real CXL.mem
  # traffic can pass through. Real HW/synthesis builds are unaffected -
  # this only fires when SIM_QUICK_MEM_INIT=1 is exported by the sim
  # launch script, never set for a synthesis/implementation run.
  if {[info exists ::env(SIM_QUICK_MEM_INIT)] && $::env(SIM_QUICK_MEM_INIT) eq "1"} {
    set_property CONFIG.ADDR_SIZE {10} $axi_memory_init_1
    puts "INFO: SIM_QUICK_MEM_INIT=1 - axi_memory_init_1 ADDR_SIZE -> 10 (1KB sweep, sim only)"
  }

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins axi_memory_init_1/M_AXI] [get_bd_intf_pins M_AXI]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_data [get_bd_intf_pins cpi_f2a_data] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_data]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_global [get_bd_intf_pins cpi_f2a_global] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_global]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_rsp [get_bd_intf_pins cpi_f2a_rsp] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_rsp]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_m0_axi_hdm [get_bd_intf_pins cxl_mem_wrapper_0/m0_axi_hdm] [get_bd_intf_pins axi_memory_init_1/S_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_data [get_bd_intf_pins cpi_a2f_data] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_data]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_global [get_bd_intf_pins cpi_a2f_global] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_global]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_req [get_bd_intf_pins cpi_a2f_req] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_req]

  # Create port connections
  connect_bd_net -net cxl_mem0_base_1  [get_bd_pins cxl_mem0_base] \
  [get_bd_pins cxl_mem_wrapper_0/cxl_mem0_base]
  connect_bd_net -net cxl_mem0_en_1  [get_bd_pins cxl_mem0_en] \
  [get_bd_pins cxl_mem_wrapper_0/cxl_mem0_en]
  connect_bd_net -net cxl_mem_wrapper_0_cxl_debug_bus [get_bd_pins cxl_mem_wrapper_0/cxl_debug_bus] [get_bd_pins dbg_cxl_bus]
  connect_bd_net -net init_complete_in_1  [get_bd_pins init_complete_in] \
  [get_bd_pins axi_memory_init_1/init_complete_in]
  connect_bd_net -net pl0_ref_clk_0_1  [get_bd_pins pl0_ref_clk_0] \
  [get_bd_pins cxl_mem_wrapper_0/clk] \
  [get_bd_pins axi_memory_init_1/aclk]
  connect_bd_net -net resetn_1  [get_bd_pins resetn] \
  [get_bd_pins cxl_mem_wrapper_0/resetn] \
  [get_bd_pins axi_memory_init_1/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: PA_0
proc create_hier_cell_PA_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_PA_0() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_global_rtl:1.0 cpi_a2f_global

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_global_rtl:1.0 cpi_f2a_global

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_req_rtl:1.0 cpi_a2f_req

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 cpi_a2f_data

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_rsp_rtl:1.0 cpi_f2a_rsp

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 cpi_f2a_data

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI


  # Create pins
  create_bd_pin -dir I -type clk pl0_ref_clk_0
  create_bd_pin -dir I -type rst resetn
  create_bd_pin -dir I -from 63 -to 0 cxl_mem0_base
  create_bd_pin -dir I cxl_mem0_en
  create_bd_pin -dir I init_complete_in
  # Raw counter source, driven from cxl_mem_wrapper_0/cxl_debug_bus below -
  # see ctrl_reg_ep.v's pa_dbg_cxl_bus port comment for the per-bit layout.
  create_bd_pin -dir O -from 15 -to 0 dbg_cxl_bus

  # Create instance: cxl_mem_wrapper_0, and set properties
  set cxl_mem_wrapper_0 [ create_bd_cell -type ip -vlnv user.org:user:cxl_mem_wrapper:1.0 cxl_mem_wrapper_0 ]
  set_property -dict [list \
    CONFIG.C_DDR_BASE {0x000000C000000000} \
    CONFIG.C_M0_AXI_HDM_BASEADDR {0x000000C000000000} \
    CONFIG.C_M0_AXI_HDM_HIGHADDR {0x000000C3FFFFFFFF} \
    CONFIG.C_MEM0_CPI_A2F_MAX_CREDIT {256} \
    CONFIG.C_MEM0_CPI_F2A_MAX_CREDIT {256} \
    CONFIG.C_NUM_PA {4} \
  ] $cxl_mem_wrapper_0

  # m0_axi_hdm bus-interface metadata: only these 5 properties are
  # writable on this cell's m0_axi_hdm pin - everything else (widths,
  # HAS_*, PROTOCOL, ID_WIDTH, NUM_READ/WRITE_OUTSTANDING,
  # MAX_BURST_LENGTH, etc.) is locked read-only, derived from the RTL's
  # own port declarations at IP-packaging time (component.xml) -
  # attempting to set them threw CRITICAL WARNING [BD 41-737] "It is
  # read-only" (confirmed empirically against the full 28-property list
  # previously set here). Trimmed to the confirmed-writable subset to
  # eliminate that warning; no functional effect since the dropped
  # properties were already unconditionally ignored.
  set_property -dict [list \
    CONFIG.FREQ_HZ {320000000} \
    CONFIG.NUM_READ_THREADS {1} \
    CONFIG.NUM_WRITE_THREADS {1} \
    CONFIG.RUSER_BITS_PER_BYTE {0} \
    CONFIG.WUSER_BITS_PER_BYTE {0} \
  ] [get_bd_intf_pins $cxl_mem_wrapper_0/m0_axi_hdm]


  # Create instance: axi_memory_init_0, and set properties
  set axi_memory_init_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_memory_init:1.0 axi_memory_init_0 ]
  set_property -dict [list \
    CONFIG.ADDR_SIZE {32} \
    CONFIG.ADDR_WIDTH {40} \
    CONFIG.BASE_ADDR {0x000000C000000000} \
    CONFIG.DATA_WIDTH {512} \
  ] $axi_memory_init_0

  # SIM-ONLY: shrink the memory-init sweep to 1KB (matches
  # cxl_mem_wr_rd_4consec_seq's real traffic footprint - hdm_base+0..192,
  # see sim/verif/test/seq/cxl_mem_wr_rd_4consec_seq.sv) so sim doesn't
  # have to wait through the full 4GB real-HW sweep before real CXL.mem
  # traffic can pass through. Real HW/synthesis builds are unaffected -
  # this only fires when SIM_QUICK_MEM_INIT=1 is exported by the sim
  # launch script, never set for a synthesis/implementation run.
  if {[info exists ::env(SIM_QUICK_MEM_INIT)] && $::env(SIM_QUICK_MEM_INIT) eq "1"} {
    set_property CONFIG.ADDR_SIZE {10} $axi_memory_init_0
    puts "INFO: SIM_QUICK_MEM_INIT=1 - axi_memory_init_0 ADDR_SIZE -> 10 (1KB sweep, sim only)"
  }

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins axi_memory_init_0/M_AXI] [get_bd_intf_pins M_AXI]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_data [get_bd_intf_pins cpi_f2a_data] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_data]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_global [get_bd_intf_pins cpi_f2a_global] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_global]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_rsp [get_bd_intf_pins cpi_f2a_rsp] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_f2a_rsp]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_m0_axi_hdm [get_bd_intf_pins cxl_mem_wrapper_0/m0_axi_hdm] [get_bd_intf_pins axi_memory_init_0/S_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_data [get_bd_intf_pins cpi_a2f_data] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_data]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_global [get_bd_intf_pins cpi_a2f_global] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_global]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_req [get_bd_intf_pins cpi_a2f_req] [get_bd_intf_pins cxl_mem_wrapper_0/cpi_a2f_req]

  # Create port connections
  connect_bd_net -net cxl_mem0_base_1  [get_bd_pins cxl_mem0_base] \
  [get_bd_pins cxl_mem_wrapper_0/cxl_mem0_base]
  connect_bd_net -net cxl_mem0_en_1  [get_bd_pins cxl_mem0_en] \
  [get_bd_pins cxl_mem_wrapper_0/cxl_mem0_en]
  connect_bd_net -net cxl_mem_wrapper_0_cxl_debug_bus [get_bd_pins cxl_mem_wrapper_0/cxl_debug_bus] [get_bd_pins dbg_cxl_bus]
  connect_bd_net -net init_complete_in_1  [get_bd_pins init_complete_in] \
  [get_bd_pins axi_memory_init_0/init_complete_in]
  connect_bd_net -net pl0_ref_clk_0_1  [get_bd_pins pl0_ref_clk_0] \
  [get_bd_pins cxl_mem_wrapper_0/clk] \
  [get_bd_pins axi_memory_init_0/aclk]
  connect_bd_net -net resetn_1  [get_bd_pins resetn] \
  [get_bd_pins cxl_mem_wrapper_0/resetn] \
  [get_bd_pins axi_memory_init_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
# Transport extension point: add a mode param + guard here and a sibling
# *_nfi BD folder if another transport is needed.
proc create_root_design { parentCell {cxl_protocol CXL_3_1} {cxl_width X8} } {

  variable script_folder
  variable design_name

  if {$cxl_protocol ne "CXL_3_1" && $cxl_protocol ne "CXL_2_0"} {
    error "ERROR: CXL_PROTOCOL must be exactly CXL_3_1 or CXL_2_0, got: $cxl_protocol"
  }
  if {$cxl_width ne "X4" && $cxl_width ne "X8"} {
    error "ERROR: CXL_WIDTH must be exactly X4 or X8, got: $cxl_width"
  }

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
  set CTRL0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 CTRL0_GT_0 ]

  set ctrl0_gt_refclk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ctrl0_gt_refclk_0 ]

  set cxl0_pm_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_cpm6:cxl_pm_rtl:1.0 cxl0_pm_0 ]

  set C0_CH0_LPDDR5_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C0_CH0_LPDDR5_0 ]

  set sys_clk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $sys_clk0_0

  set C1_CH0_LPDDR5_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C1_CH0_LPDDR5_0 ]

  set C5_CH0_LPDDR5_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C5_CH0_LPDDR5_0 ]

  set C4_CH0_LPDDR5_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C4_CH0_LPDDR5_0 ]

  set sys_clk4_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk4_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $sys_clk4_0


  # Create ports

  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:1.0 ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.CPM6_CONFIG(CPM6_BOARD) VPK360 \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_AXI_PL1_IF) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL1_PROTOCOL) {Disabled} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ACS_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ARI_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ASPM_L0P_SUPPORT) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ASPM_L1_SUPPORT) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ATS_PRI_CAP_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_CFG_STATUS_IF) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_DEV_SERIAL_NO) {0xabcd_0000_0000_5678} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_DMA_APERTURE0_BASEADDR) {0x0000_0201_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_DMA_APERTURE0_DEST) {CPM_AXI_PL0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_DMA_APERTURE0_LIMITADDR) {0x0000_0201_0001_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_DSN_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ECRC_CAP_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_ELBI_IF) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_EXT_CFG_SPACE_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_FLR_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_IDE_CAP_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION0_BAR_NUM) {BAR_2} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION0_FUNC) {PF_0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION0_LIMITADDR) {0x000_0001_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION0_MATCH_MODE) {BAR} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_INBOUND_REGION0_TRGTADDR) {0x201_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_LINK_WIDTH) $cxl_width \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MMIO_APERTURE0_BASEADDR) {0x0201_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MMIO_APERTURE0_DEST) {CPM_AXI_PL0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MMIO_APERTURE0_LIMITADDR) {0x0201_0000_ffff} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_MODE) {BRIDGE} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_NUM_INBOUND_REGIONS) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_NUM_MMIO_APERTURES) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PASID_CAP_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PERST) {PS_MIO_18} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_BAR2_64BIT) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_BAR2_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_BAR2_PREFETCHABLE) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_BAR2_SIZE) {64} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_BAR4_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_INTERFACE_VALUE) {10} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSIX_EN) {0} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSI_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_MSI_VECTORS) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PF0_SUB_CLASS_VALUE) {02} \
    CONFIG.CPM6_CONFIG(CPM6_CTRL0_PROTOCOL) $cxl_protocol \
    CONFIG.CPM6_CONFIG(CPM6_CXL0_HDM_DECODER_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CXL0_INTF) CPI \
    CONFIG.CPM6_CONFIG(CPM6_CXL0_MEM_HWINIT_MODE) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CXL0_NUM_AGENTS) {4} \
    CONFIG.CPM6_CONFIG(CPM6_CXL0_RANGE1_SIZE) {0x0000_0004_0000_0000} \
    CONFIG.CPM6_CONFIG(CPM6_CXL0_RESET_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CXL0_RST_MEMCLR_CAP_EN) {1} \
    CONFIG.CPM6_CONFIG(CPM6_CXL0_TX_PARITY) {Odd} \
    CONFIG.CPM6_CONFIG(CPM6_CXL0_VIRAL_CAP_EN) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL0_IF) {1} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL1_IF) {0} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL2_IF) {0} \
    CONFIG.PS_PMC_CONFIG(CPM6_AXI_PL3_IF) {0} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_LINK_WIDTH) $cxl_width \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_MODE) {BRIDGE} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_PERST) {PS_MIO_18} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL0_PROTOCOL) $cxl_protocol \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_LINK_WIDTH) {X8} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_MODE) {None} \
    CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_PROTOCOL) {Disabled} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {333} \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PL1_REF_CTRL_FREQMHZ) {250} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI0_MASTER) {R5_0} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_MASTER) {R5_1} \
    CONFIG.PS_PMC_CONFIG(PS_IRQ_USAGE) {CH0 1 CH1 0 CH2 0 CH3 0 CH4 0 CH5 0 CH6 0 CH7 0 CH8 0 CH9 0 CH10 0 CH11 0 CH12 0 CH13 0 CH14 0 CH15 0} \
    CONFIG.PS_PMC_CONFIG(PS_LPD_AXI_NOC_DATA_WIDTH) {128} \
    CONFIG.PS_PMC_CONFIG(PS_LPD_AXI_PL_DATA_WIDTH) {32} \
    CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {0} \
    CONFIG.PS_PMC_CONFIG(PS_OCM_ECC_ENABLE) {0} \
    CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
    CONFIG.PS_PMC_CONFIG(PS_TTC0_CLK) {ENABLE 0 IO PMC_MIO_6 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_TTC0_WAVEOUT) {ENABLE 0 IO PMC_MIO_7 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_TTC1_CLK) {ENABLE 0 IO PMC_MIO_12 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_TTC1_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_TTC1_WAVEOUT) {ENABLE 0 IO PMC_MIO_13 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_TTC2_CLK) {ENABLE 0 IO PMC_MIO_2 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_TTC2_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_TTC2_WAVEOUT) {ENABLE 0 IO PMC_MIO_3 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_TTC3_CLK) {ENABLE 0 IO PMC_MIO_16 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_TTC3_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_TTC3_WAVEOUT) {ENABLE 0 IO PMC_MIO_17 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PS_MIO_16:17 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_46:47 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_CCI_NOC) {0} \
    CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {0} \
    CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_PL) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK1) {1} \
  ] $ps_wizard_0


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [list \
    CONFIG.ADVANCED_PROPERTIES {__experimental_features__ {legacy_low_area_mode 1}} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: ctrl_reg_ep_0, and set properties
  set block_name ctrl_reg_ep
  set block_cell_name ctrl_reg_ep_0
  if { [catch {set ctrl_reg_ep_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ctrl_reg_ep_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  # CONFIG.NUM_PA must be set immediately after create_bd_cell, before any
  # other set_property/connect_bd_net touches this cell's NUM_PA-sized pins
  # (pa_dbg_cxl_bus) - confirmed empirically that a "-type module
  # -reference" cell's parameter-driven port widths only reflect their
  # final value AFTER this set_property succeeds (live re-elaboration, not
  # deferred) - anything wired beforehand would see the stale default
  # width. This design always instantiates exactly 4 PAs (PA_0..PA_3)
  # unconditionally below, so NUM_PA is 4 here regardless of any other
  # build option.
  set_property CONFIG.NUM_PA {4} $ctrl_reg_ep_0

  # Create instance: pa_dbg_cxl_concat_0 - combines all 4 PAs' own
  # dbg_cxl_bus (16 bits each, itself = cxl_mem_wrapper_0/cxl_debug_bus)
  # into the single NUM_PA*16-bit bus ctrl_reg_ep_0/pa_dbg_cxl_bus expects.
  # In0=PA_0 .. In3=PA_3, matching ctrl_reg_ep.v's pa_dbg_cxl_bus[gi*16+:16]
  # per-PA slice convention exactly.
  set pa_dbg_cxl_concat_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:1.0 pa_dbg_cxl_concat_0 ]
  set_property -dict [list \
    CONFIG.NUM_PORTS {4} \
    CONFIG.IN0_WIDTH {16} \
    CONFIG.IN1_WIDTH {16} \
    CONFIG.IN2_WIDTH {16} \
    CONFIG.IN3_WIDTH {16} \
  ] $pa_dbg_cxl_concat_0

  # Create instance: ep_status_concat_0 (+ 3 reserved-bit tie-offs) - packs
  # ps_wizard_0's cxl0_status_* pins into ctrl_reg_ep_0's EP_CTRL_STS layout
  # via a plain BD-level concat (was previously a custom RTL module,
  # src/ep_status_reg.v, that concatenated AND registered the bus itself -
  # replaced because ctrl_reg_ep_0 already registers ep_status once into
  # ep_ctrl_sts on its own s_axil_aclk/s_axil_aresetn - see ctrl_reg_ep.v -
  # so a second, separate register stage here was redundant; ilconcat is
  # purely combinational, no clk/aresetn pins needed). Reserved gaps at
  # bit[13] (previously mld_hot_rst_active - dropped, ps_wizard will not
  # expose this pin in a future release), bit[15], and bits[23:20] are
  # tied to 0 via ilconstant so the EP_CTRL_STS bit-map is unchanged for
  # everything at bit[14] and above (no bit-shifting/renumbering).
  set ep_status_concat_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:1.0 ep_status_concat_0 ]
  set_property -dict [list \
    CONFIG.NUM_PORTS {18} \
    CONFIG.IN0_WIDTH {1} \
    CONFIG.IN1_WIDTH {1} \
    CONFIG.IN2_WIDTH {1} \
    CONFIG.IN3_WIDTH {1} \
    CONFIG.IN4_WIDTH {2} \
    CONFIG.IN5_WIDTH {1} \
    CONFIG.IN6_WIDTH {1} \
    CONFIG.IN7_WIDTH {1} \
    CONFIG.IN8_WIDTH {1} \
    CONFIG.IN9_WIDTH {1} \
    CONFIG.IN10_WIDTH {1} \
    CONFIG.IN11_WIDTH {1} \
    CONFIG.IN12_WIDTH {1} \
    CONFIG.IN13_WIDTH {1} \
    CONFIG.IN14_WIDTH {1} \
    CONFIG.IN15_WIDTH {4} \
    CONFIG.IN16_WIDTH {4} \
    CONFIG.IN17_WIDTH {8} \
  ] $ep_status_concat_0

  set ep_status_rsvd13_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 ep_status_rsvd13_0 ]
  set_property CONFIG.CONST_VAL {0} $ep_status_rsvd13_0

  set ep_status_rsvd15_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 ep_status_rsvd15_0 ]
  set_property CONFIG.CONST_VAL {0} $ep_status_rsvd15_0

  set ep_status_rsvd23_20_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 ep_status_rsvd23_20_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {4} \
  ] $ep_status_rsvd23_20_0

  # Create instance: ilconstant_1, and set properties. Drives
  # ps_wizard_0/cxl0_status_pl_ready; created unconditionally since this
  # design is CPI-only.
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 ilconstant_1 ]
  set_property CONFIG.CONST_VAL {1} $ilconstant_1


  # Create instance: PA_0
  create_hier_cell_PA_0 [current_bd_instance .] PA_0

  # Create instance: PA_1
  create_hier_cell_PA_1 [current_bd_instance .] PA_1

  # Create instance: PA_2
  create_hier_cell_PA_2 [current_bd_instance .] PA_2

  # Create instance: PA_3
  create_hier_cell_PA_3 [current_bd_instance .] PA_3

  # pa_dbg_cxl_concat_0: gather each PA's dbg_cxl_bus into ctrl_reg_ep_0's
  # single pa_dbg_cxl_bus input (In0=PA_0 .. In3=PA_3).
  connect_bd_net -net PA_0_dbg_cxl_bus [get_bd_pins PA_0/dbg_cxl_bus] [get_bd_pins pa_dbg_cxl_concat_0/In0]
  connect_bd_net -net PA_1_dbg_cxl_bus [get_bd_pins PA_1/dbg_cxl_bus] [get_bd_pins pa_dbg_cxl_concat_0/In1]
  connect_bd_net -net PA_2_dbg_cxl_bus [get_bd_pins PA_2/dbg_cxl_bus] [get_bd_pins pa_dbg_cxl_concat_0/In2]
  connect_bd_net -net PA_3_dbg_cxl_bus [get_bd_pins PA_3/dbg_cxl_bus] [get_bd_pins pa_dbg_cxl_concat_0/In3]
  connect_bd_net -net pa_dbg_cxl_concat_0_dout [get_bd_pins pa_dbg_cxl_concat_0/dout] [get_bd_pins ctrl_reg_ep_0/pa_dbg_cxl_bus]

  # Create instance: ilconstant_num_pa, and set properties
  set ilconstant_num_pa [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 ilconstant_num_pa ]
  set_property -dict [list \
    CONFIG.CONST_VAL {3} \
    CONFIG.CONST_WIDTH {2} \
  ] $ilconstant_num_pa


  # Create instance: axi_noc2_0, and set properties
  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2:1.1 axi_noc2_0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {1} \
  ] $axi_noc2_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.APERTURES {{0x0201_0000_0000 128K}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc2_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x40} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc2_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:S00_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk0]

  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_1


  # Create instance: axi_bram_ctrl_1_bram, and set properties
  set axi_bram_ctrl_1_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 axi_bram_ctrl_1_bram ]
  set_property CONFIG.MEMORY_TYPE {Single_Port_RAM} $axi_bram_ctrl_1_bram


  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

  # Create instance: axi_noc2_c0, and set properties
  set axi_noc2_c0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2:1.1 axi_noc2_c0 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
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
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {46} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {46} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
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
    CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
    CONFIG.DDRMC5_NUM_CH {1} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH0_HIGH_0} \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_SI {1} \
  ] $axi_noc2_c0

  # DDRMC5_SKIPCAL skips the real DDR calibration/training sequence - this
  # must NEVER be set for a real hardware/PDI build (it broke real-board DDR
  # calibration when it was previously left unconditional). Only set it for
  # simulation, where skipping the multi-second calibration state machine
  # keeps the same fast-sim benefit as the SIM_QUICK_MEM_INIT axi_memory_init
  # ADDR_SIZE overrides elsewhere in this file - this only fires when
  # SIM_QUICK_MEM_INIT=1 is exported by the sim launch script, never set for
  # a synthesis/implementation run.
  if {[info exists ::env(SIM_QUICK_MEM_INIT)] && $::env(SIM_QUICK_MEM_INIT) eq "1"} {
    set_property CONFIG.DDRMC5_SKIPCAL {true} $axi_noc2_c0
    puts "INFO: SIM_QUICK_MEM_INIT=1 - axi_noc2_c0 DDRMC5_SKIPCAL -> true (skip DDR calibration, sim only)"
  }


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
 ] [get_bd_intf_pins $axi_noc2_c0/S00_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc2_c0/aclk0]

  # Create instance: axi_noc2_c1, and set properties
  set axi_noc2_c1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2:1.1 axi_noc2_c1 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
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
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {46} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {46} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
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
    CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
    CONFIG.DDRMC5_NUM_CH {1} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH0_HIGH_0} \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_SI {1} \
  ] $axi_noc2_c1

  # DDRMC5_SKIPCAL skips the real DDR calibration/training sequence - this
  # must NEVER be set for a real hardware/PDI build (it broke real-board DDR
  # calibration when it was previously left unconditional). Only set it for
  # simulation, where skipping the multi-second calibration state machine
  # keeps the same fast-sim benefit as the SIM_QUICK_MEM_INIT axi_memory_init
  # ADDR_SIZE overrides elsewhere in this file - this only fires when
  # SIM_QUICK_MEM_INIT=1 is exported by the sim launch script, never set for
  # a synthesis/implementation run.
  if {[info exists ::env(SIM_QUICK_MEM_INIT)] && $::env(SIM_QUICK_MEM_INIT) eq "1"} {
    set_property CONFIG.DDRMC5_SKIPCAL {true} $axi_noc2_c1
    puts "INFO: SIM_QUICK_MEM_INIT=1 - axi_noc2_c1 DDRMC5_SKIPCAL -> true (skip DDR calibration, sim only)"
  }


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
 ] [get_bd_intf_pins $axi_noc2_c1/S00_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc2_c1/aclk0]

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0 ]

  # Create instance: axi_noc2_c4, and set properties
  set axi_noc2_c4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2:1.1 axi_noc2_c4 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
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
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {46} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {46} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
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
    CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
    CONFIG.DDRMC5_NUM_CH {1} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH0_HIGH_0} \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_SI {1} \
  ] $axi_noc2_c4

  # DDRMC5_SKIPCAL skips the real DDR calibration/training sequence - this
  # must NEVER be set for a real hardware/PDI build (it broke real-board DDR
  # calibration when it was previously left unconditional). Only set it for
  # simulation, where skipping the multi-second calibration state machine
  # keeps the same fast-sim benefit as the SIM_QUICK_MEM_INIT axi_memory_init
  # ADDR_SIZE overrides elsewhere in this file - this only fires when
  # SIM_QUICK_MEM_INIT=1 is exported by the sim launch script, never set for
  # a synthesis/implementation run.
  if {[info exists ::env(SIM_QUICK_MEM_INIT)] && $::env(SIM_QUICK_MEM_INIT) eq "1"} {
    set_property CONFIG.DDRMC5_SKIPCAL {true} $axi_noc2_c4
    puts "INFO: SIM_QUICK_MEM_INIT=1 - axi_noc2_c4 DDRMC5_SKIPCAL -> true (skip DDR calibration, sim only)"
  }


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
 ] [get_bd_intf_pins $axi_noc2_c4/S00_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc2_c4/aclk0]

  # Create instance: axi_noc2_c5, and set properties
  set axi_noc2_c5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2:1.1 axi_noc2_c5 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
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
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {46} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {46} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
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
    CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
    CONFIG.DDRMC5_NUM_CH {1} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH0_HIGH_0} \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_SI {1} \
  ] $axi_noc2_c5

  # DDRMC5_SKIPCAL skips the real DDR calibration/training sequence - this
  # must NEVER be set for a real hardware/PDI build (it broke real-board DDR
  # calibration when it was previously left unconditional). Only set it for
  # simulation, where skipping the multi-second calibration state machine
  # keeps the same fast-sim benefit as the SIM_QUICK_MEM_INIT axi_memory_init
  # ADDR_SIZE overrides elsewhere in this file - this only fires when
  # SIM_QUICK_MEM_INIT=1 is exported by the sim launch script, never set for
  # a synthesis/implementation run.
  if {[info exists ::env(SIM_QUICK_MEM_INIT)] && $::env(SIM_QUICK_MEM_INIT) eq "1"} {
    set_property CONFIG.DDRMC5_SKIPCAL {true} $axi_noc2_c5
    puts "INFO: SIM_QUICK_MEM_INIT=1 - axi_noc2_c5 DDRMC5_SKIPCAL -> true (skip DDR calibration, sim only)"
  }


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
 ] [get_bd_intf_pins $axi_noc2_c5/S00_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc2_c5/aclk0]

  # Create instance: util_ds_buf_1, and set properties
  set util_ds_buf_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_1 ]

  # Create instance: ilconstant_4, and set properties
  set ilconstant_4 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 ilconstant_4 ]

  # Create interface connections
  connect_bd_intf_net -intf_net PA_0_M_AXI [get_bd_intf_pins axi_noc2_c0/S00_AXI] [get_bd_intf_pins PA_0/M_AXI]
  connect_bd_intf_net -intf_net PA_1_M_AXI [get_bd_intf_pins axi_noc2_c1/S00_AXI] [get_bd_intf_pins PA_1/M_AXI]
  connect_bd_intf_net -intf_net PA_2_M_AXI [get_bd_intf_pins axi_noc2_c4/S00_AXI] [get_bd_intf_pins PA_2/M_AXI]
  connect_bd_intf_net -intf_net PA_3_M_AXI [get_bd_intf_pins axi_noc2_c5/S00_AXI] [get_bd_intf_pins PA_3/M_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_1_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins axi_noc2_0/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]
  # Create instance: ddrmc5_responder_c{0,1,4,5} - one per LPDDR5 channel,
  # inserted INLINE between each axi_noc2_cN's C0_CH0_LPDDR5 intf pin and
  # the existing top-level C{n}_CH0_LPDDR5_0 port (which still goes to real
  # board pins - this IP is simulation-only and does not affect synthesis/
  # implementation). DDRMC5_NUM_CH is forced to {1} (Single) since each of
  # this design's axi_noc2_cN instances is single-channel
  # (component.xml choice_pairs_dfd4253e: 1=Single, 2=Dual).
  set ddrmc5_responder_c0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddrmc5_responder ddrmc5_responder_c0 ]
  set_property CONFIG.DDRMC5_CONTROLLERTYPE {LPDDR5_SDRAM} $ddrmc5_responder_c0
  set_property CONFIG.DDRMC5_NUM_CH {1} $ddrmc5_responder_c0
  set ddrmc5_responder_c1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddrmc5_responder ddrmc5_responder_c1 ]
  set_property CONFIG.DDRMC5_CONTROLLERTYPE {LPDDR5_SDRAM} $ddrmc5_responder_c1
  set_property CONFIG.DDRMC5_NUM_CH {1} $ddrmc5_responder_c1
  set ddrmc5_responder_c4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddrmc5_responder ddrmc5_responder_c4 ]
  set_property CONFIG.DDRMC5_CONTROLLERTYPE {LPDDR5_SDRAM} $ddrmc5_responder_c4
  set_property CONFIG.DDRMC5_NUM_CH {1} $ddrmc5_responder_c4
  set ddrmc5_responder_c5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddrmc5_responder ddrmc5_responder_c5 ]
  set_property CONFIG.DDRMC5_CONTROLLERTYPE {LPDDR5_SDRAM} $ddrmc5_responder_c5
  set_property CONFIG.DDRMC5_NUM_CH {1} $ddrmc5_responder_c5

  connect_bd_intf_net -intf_net axi_noc2_c0_C0_CH0_LPDDR5 [get_bd_intf_pins axi_noc2_c0/C0_CH0_LPDDR5] [get_bd_intf_pins ddrmc5_responder_c0/CH0_LPDDR5_IN]
  connect_bd_intf_net -intf_net ddrmc5_responder_c0_CH0_LPDDR5 [get_bd_intf_ports C0_CH0_LPDDR5_0] [get_bd_intf_pins ddrmc5_responder_c0/CH0_LPDDR5]
  connect_bd_intf_net -intf_net axi_noc2_c1_C0_CH0_LPDDR5 [get_bd_intf_pins axi_noc2_c1/C0_CH0_LPDDR5] [get_bd_intf_pins ddrmc5_responder_c1/CH0_LPDDR5_IN]
  connect_bd_intf_net -intf_net ddrmc5_responder_c1_CH0_LPDDR5 [get_bd_intf_ports C1_CH0_LPDDR5_0] [get_bd_intf_pins ddrmc5_responder_c1/CH0_LPDDR5]
  connect_bd_intf_net -intf_net axi_noc2_c4_C0_CH0_LPDDR5 [get_bd_intf_pins axi_noc2_c4/C0_CH0_LPDDR5] [get_bd_intf_pins ddrmc5_responder_c4/CH0_LPDDR5_IN]
  connect_bd_intf_net -intf_net ddrmc5_responder_c4_CH0_LPDDR5 [get_bd_intf_ports C4_CH0_LPDDR5_0] [get_bd_intf_pins ddrmc5_responder_c4/CH0_LPDDR5]
  connect_bd_intf_net -intf_net axi_noc2_c5_C0_CH0_LPDDR5 [get_bd_intf_pins axi_noc2_c5/C0_CH0_LPDDR5] [get_bd_intf_pins ddrmc5_responder_c5/CH0_LPDDR5_IN]
  connect_bd_intf_net -intf_net ddrmc5_responder_c5_CH0_LPDDR5 [get_bd_intf_ports C5_CH0_LPDDR5_0] [get_bd_intf_pins ddrmc5_responder_c5/CH0_LPDDR5]
  connect_bd_intf_net -intf_net ctrl0_gt_refclk_0_1 [get_bd_intf_ports ctrl0_gt_refclk_0] [get_bd_intf_pins ps_wizard_0/ctrl0_gt_refclk]
  connect_bd_intf_net -intf_net cxl0_pm_0_1 [get_bd_intf_ports cxl0_pm_0] [get_bd_intf_pins ps_wizard_0/cxl0_pm]
  connect_bd_intf_net -intf_net ps_wizard_0_CTRL0_GT [get_bd_intf_ports CTRL0_GT_0] [get_bd_intf_pins ps_wizard_0/CTRL0_GT]
  connect_bd_intf_net -intf_net ps_wizard_0_LPD_AXI_PL [get_bd_intf_pins smartconnect_0/S00_AXI] [get_bd_intf_pins ps_wizard_0/LPD_AXI_PL]
  connect_bd_intf_net -intf_net ps_wizard_0_cpm_axi_pl0 [get_bd_intf_pins ps_wizard_0/cpm_axi_pl0] [get_bd_intf_pins axi_noc2_0/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins ctrl_reg_ep_0/s_axil]
  connect_bd_intf_net -intf_net sys_clk0_0_1 [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net sys_clk4_0_1 [get_bd_intf_ports sys_clk4_0] [get_bd_intf_pins util_ds_buf_1/CLK_IN_D]

  # ===========================================================================
  # PA_N <-> ps_wizard_0 CPI connections (cxl0_cpiN_* pins). Grouped here as
  # a single block rather than scattered individually.
  # ===========================================================================
  connect_bd_intf_net -intf_net PA_1_cpi_f2a_data [get_bd_intf_pins PA_1/cpi_f2a_data] [get_bd_intf_pins ps_wizard_0/cxl0_cpi1_f2a_data]
  connect_bd_intf_net -intf_net PA_1_cpi_f2a_global [get_bd_intf_pins ps_wizard_0/cxl0_cpi1_f2a_global] [get_bd_intf_pins PA_1/cpi_f2a_global]
  connect_bd_intf_net -intf_net PA_1_cpi_f2a_rsp [get_bd_intf_pins ps_wizard_0/cxl0_cpi1_f2a_rsp] [get_bd_intf_pins PA_1/cpi_f2a_rsp]
  connect_bd_intf_net -intf_net PA_2_cpi_f2a_data [get_bd_intf_pins PA_2/cpi_f2a_data] [get_bd_intf_pins ps_wizard_0/cxl0_cpi2_f2a_data]
  connect_bd_intf_net -intf_net PA_2_cpi_f2a_global [get_bd_intf_pins ps_wizard_0/cxl0_cpi2_f2a_global] [get_bd_intf_pins PA_2/cpi_f2a_global]
  connect_bd_intf_net -intf_net PA_2_cpi_f2a_rsp [get_bd_intf_pins ps_wizard_0/cxl0_cpi2_f2a_rsp] [get_bd_intf_pins PA_2/cpi_f2a_rsp]
  connect_bd_intf_net -intf_net PA_3_cpi_f2a_data [get_bd_intf_pins PA_3/cpi_f2a_data] [get_bd_intf_pins ps_wizard_0/cxl0_cpi3_f2a_data]
  connect_bd_intf_net -intf_net PA_3_cpi_f2a_global [get_bd_intf_pins ps_wizard_0/cxl0_cpi3_f2a_global] [get_bd_intf_pins PA_3/cpi_f2a_global]
  connect_bd_intf_net -intf_net PA_3_cpi_f2a_rsp [get_bd_intf_pins ps_wizard_0/cxl0_cpi3_f2a_rsp] [get_bd_intf_pins PA_3/cpi_f2a_rsp]
  connect_bd_intf_net -intf_net cpi_a2f_data_1 [get_bd_intf_pins PA_1/cpi_a2f_data] [get_bd_intf_pins ps_wizard_0/cxl0_cpi1_a2f_data]
  connect_bd_intf_net -intf_net cpi_a2f_data_2 [get_bd_intf_pins PA_2/cpi_a2f_data] [get_bd_intf_pins ps_wizard_0/cxl0_cpi2_a2f_data]
  connect_bd_intf_net -intf_net cpi_a2f_data_3 [get_bd_intf_pins PA_3/cpi_a2f_data] [get_bd_intf_pins ps_wizard_0/cxl0_cpi3_a2f_data]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_data [get_bd_intf_pins PA_0/cpi_f2a_data] [get_bd_intf_pins ps_wizard_0/cxl0_cpi0_f2a_data]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_global [get_bd_intf_pins PA_0/cpi_f2a_global] [get_bd_intf_pins ps_wizard_0/cxl0_cpi0_f2a_global]
  connect_bd_intf_net -intf_net cxl_mem_wrapper_0_cpi_f2a_rsp [get_bd_intf_pins PA_0/cpi_f2a_rsp] [get_bd_intf_pins ps_wizard_0/cxl0_cpi0_f2a_rsp]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_data [get_bd_intf_pins ps_wizard_0/cxl0_cpi0_a2f_data] [get_bd_intf_pins PA_0/cpi_a2f_data]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_global [get_bd_intf_pins PA_0/cpi_a2f_global] [get_bd_intf_pins ps_wizard_0/cxl0_cpi0_a2f_global]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi0_a2f_req [get_bd_intf_pins ps_wizard_0/cxl0_cpi0_a2f_req] [get_bd_intf_pins PA_0/cpi_a2f_req]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi1_a2f_global [get_bd_intf_pins ps_wizard_0/cxl0_cpi1_a2f_global] [get_bd_intf_pins PA_1/cpi_a2f_global]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi1_a2f_req [get_bd_intf_pins ps_wizard_0/cxl0_cpi1_a2f_req] [get_bd_intf_pins PA_1/cpi_a2f_req]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi2_a2f_global [get_bd_intf_pins ps_wizard_0/cxl0_cpi2_a2f_global] [get_bd_intf_pins PA_2/cpi_a2f_global]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi2_a2f_req [get_bd_intf_pins ps_wizard_0/cxl0_cpi2_a2f_req] [get_bd_intf_pins PA_2/cpi_a2f_req]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi3_a2f_global [get_bd_intf_pins ps_wizard_0/cxl0_cpi3_a2f_global] [get_bd_intf_pins PA_3/cpi_a2f_global]
  connect_bd_intf_net -intf_net ps_wizard_0_cxl0_cpi3_a2f_req [get_bd_intf_pins ps_wizard_0/cxl0_cpi3_a2f_req] [get_bd_intf_pins PA_3/cpi_a2f_req]

  # Create port connections
  connect_bd_net -net ctrl_reg_ep_0_cxl_mem_base0  [get_bd_pins ctrl_reg_ep_0/cxl_mem_base0] \
  [get_bd_pins PA_0/cxl_mem0_base] \
  [get_bd_pins PA_1/cxl_mem0_base] \
  [get_bd_pins PA_3/cxl_mem0_base] \
  [get_bd_pins PA_2/cxl_mem0_base]
  connect_bd_net -net ctrl_reg_ep_0_cxl_pm_in  [get_bd_pins ctrl_reg_ep_0/cxl_pm_in] \
  [get_bd_pins ps_wizard_0/cxl0_pm_pm_in]
  connect_bd_net -net ctrl_reg_ep_0_irq_out  [get_bd_pins ctrl_reg_ep_0/irq_out] \
  [get_bd_pins ps_wizard_0/pl_ps_irq0]
  connect_bd_net -net ilconstant_1_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins ps_wizard_0/cxl0_status_pl_ready]
  connect_bd_net -net ilconstant_4_dout  [get_bd_pins ilconstant_4/dout] \
  [get_bd_pins PA_1/init_complete_in] \
  [get_bd_pins PA_2/init_complete_in] \
  [get_bd_pins PA_3/init_complete_in] \
  [get_bd_pins PA_0/init_complete_in]
  connect_bd_net -net ilconstant_num_pa_dout  [get_bd_pins ilconstant_num_pa/dout] \
  [get_bd_pins ctrl_reg_ep_0/num_pa]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn  [get_bd_pins proc_sys_reset_0/interconnect_aresetn] \
  [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins PA_0/resetn] \
  [get_bd_pins PA_1/resetn] \
  [get_bd_pins PA_2/resetn] \
  [get_bd_pins PA_3/resetn] \
  [get_bd_pins ctrl_reg_ep_0/s_axil_aresetn]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn  [get_bd_pins proc_sys_reset_1/peripheral_aresetn] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn]
  connect_bd_net -net ps_wizard_0_arstn0  [get_bd_pins ps_wizard_0/arstn0] \
  [get_bd_pins proc_sys_reset_1/ext_reset_in]
  connect_bd_net -net ps_wizard_0_cxl0_pm_pm_out  [get_bd_pins ps_wizard_0/cxl0_pm_pm_out] \
  [get_bd_pins ctrl_reg_ep_0/cxl_pm_out]
  connect_bd_net -net ps_wizard_0_cxl0_rstn  [get_bd_pins ps_wizard_0/cxl0_rstn] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net ps_wizard_0_cxl0_status_dev_mem_en  [get_bd_pins ps_wizard_0/cxl0_status_dev_mem_en] \
  [get_bd_pins ctrl_reg_ep_0/cxl1_status_dev_mem_en] \
  [get_bd_pins PA_0/cxl_mem0_en] \
  [get_bd_pins PA_1/cxl_mem0_en] \
  [get_bd_pins PA_2/cxl_mem0_en] \
  [get_bd_pins PA_3/cxl_mem0_en] \
  [get_bd_pins ep_status_concat_0/In2]

  # ep_status_concat_0: remaining CXL0 controller status inputs (from
  # ps_wizard_0's cxl0_status_* pins - see ctrl_reg_ep.v's ep_status port
  # comment for the bit-layout this feeds into ctrl_reg_ep_0/ep_status)
  connect_bd_net -net ps_wizard_0_cxl0_status_link_up [get_bd_pins ps_wizard_0/cxl0_status_link_up] [get_bd_pins ep_status_concat_0/In0]
  connect_bd_net -net ps_wizard_0_cxl0_status_io_en [get_bd_pins ps_wizard_0/cxl0_status_io_en] [get_bd_pins ep_status_concat_0/In1]
  connect_bd_net -net ps_wizard_0_cxl0_status_dev_cache_en [get_bd_pins ps_wizard_0/cxl0_status_dev_cache_en] [get_bd_pins ep_status_concat_0/In3]
  connect_bd_net -net ps_wizard_0_cxl0_status_flit_mode [get_bd_pins ps_wizard_0/cxl0_status_flit_mode] [get_bd_pins ep_status_concat_0/In4]
  connect_bd_net -net ps_wizard_0_cxl0_status_bi_enable [get_bd_pins ps_wizard_0/cxl0_status_bi_enable] [get_bd_pins ep_status_concat_0/In5]
  connect_bd_net -net ps_wizard_0_cxl0_status_emd_enable [get_bd_pins ps_wizard_0/cxl0_status_emd_enable] [get_bd_pins ep_status_concat_0/In6]
  connect_bd_net -net ps_wizard_0_cxl0_status_disable_caching [get_bd_pins ps_wizard_0/cxl0_status_disable_caching] [get_bd_pins ep_status_concat_0/In7]
  connect_bd_net -net ps_wizard_0_cxl0_status_mdh_disable [get_bd_pins ps_wizard_0/cxl0_status_mdh_disable] [get_bd_pins ep_status_concat_0/In8]
  connect_bd_net -net ps_wizard_0_cxl0_status_reset [get_bd_pins ps_wizard_0/cxl0_status_reset] [get_bd_pins ep_status_concat_0/In9]
  connect_bd_net -net ps_wizard_0_cxl0_status_initiate_cxl_rst [get_bd_pins ps_wizard_0/cxl0_status_initiate_cxl_rst] [get_bd_pins ep_status_concat_0/In10]
  connect_bd_net -net ps_wizard_0_cxl0_status_initiate_cache_wr_invld [get_bd_pins ps_wizard_0/cxl0_status_initiate_cache_wr_invld] [get_bd_pins ep_status_concat_0/In11]
  connect_bd_net -net ep_status_rsvd13_0_dout [get_bd_pins ep_status_rsvd13_0/dout] [get_bd_pins ep_status_concat_0/In12]
  connect_bd_net -net ps_wizard_0_cxl0_status_dev_rst_mem_clr_enable [get_bd_pins ps_wizard_0/cxl0_status_dev_rst_mem_clr_enable] [get_bd_pins ep_status_concat_0/In13]
  connect_bd_net -net ep_status_rsvd15_0_dout [get_bd_pins ep_status_rsvd15_0/dout] [get_bd_pins ep_status_concat_0/In14]
  connect_bd_net -net ps_wizard_0_cxl0_status_vlsm_mc_state [get_bd_pins ps_wizard_0/cxl0_status_vlsm_mc_state] [get_bd_pins ep_status_concat_0/In15]
  connect_bd_net -net ep_status_rsvd23_20_0_dout [get_bd_pins ep_status_rsvd23_20_0/dout] [get_bd_pins ep_status_concat_0/In16]
  connect_bd_net -net ps_wizard_0_cxl0_status_error [get_bd_pins ps_wizard_0/cxl0_status_error] [get_bd_pins ep_status_concat_0/In17]

  # ep_status_concat_0's combinational output -> ctrl_reg_ep_0's own
  # existing register stage (ep_ctrl_sts <= ep_status; see ctrl_reg_ep.v)
  connect_bd_net -net ep_status_concat_0_dout [get_bd_pins ep_status_concat_0/dout] [get_bd_pins ctrl_reg_ep_0/ep_status]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins PA_0/pl0_ref_clk_0] \
  [get_bd_pins PA_1/pl0_ref_clk_0] \
  [get_bd_pins PA_2/pl0_ref_clk_0] \
  [get_bd_pins PA_3/pl0_ref_clk_0] \
  [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk] \
  [get_bd_pins ps_wizard_0/cxl0_clk] \
  [get_bd_pins axi_noc2_c0/aclk0] \
  [get_bd_pins axi_noc2_c1/aclk0] \
  [get_bd_pins axi_noc2_c4/aclk0] \
  [get_bd_pins axi_noc2_c5/aclk0] \
  [get_bd_pins ctrl_reg_ep_0/s_axil_aclk]
  connect_bd_net -net ps_wizard_0_pl1_ref_clk  [get_bd_pins ps_wizard_0/pl1_ref_clk] \
  [get_bd_pins ps_wizard_0/pcie0_clk] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] \
  [get_bd_pins proc_sys_reset_1/slowest_sync_clk] \
  [get_bd_pins axi_noc2_0/aclk0] \
  [get_bd_pins ps_wizard_0/aclk0]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT  [get_bd_pins util_ds_buf_0/IBUF_OUT] \
  [get_bd_pins axi_noc2_c0/sys_clk0] \
  [get_bd_pins axi_noc2_c1/sys_clk0]
  connect_bd_net -net util_ds_buf_1_IBUF_OUT  [get_bd_pins util_ds_buf_1/IBUF_OUT] \
  [get_bd_pins axi_noc2_c4/sys_clk0] \
  [get_bd_pins axi_noc2_c5/sys_clk0]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexa72_0] [get_bd_addr_segs ctrl_reg_ep_0/s_axil/reg0] -force
  assign_bd_address -offset 0x80000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexa72_1] [get_bd_addr_segs ctrl_reg_ep_0/s_axil/reg0] -force
  assign_bd_address -offset 0x80000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ctrl_reg_ep_0/s_axil/reg0] -force
  assign_bd_address -offset 0x80000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ctrl_reg_ep_0/s_axil/reg0] -force
  assign_bd_address -offset 0x020100000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x80000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs ctrl_reg_ep_0/s_axil/reg0] -force
  assign_bd_address -offset 0x80000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs ctrl_reg_ep_0/s_axil/reg0] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ctrl_reg_ep_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00C000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces PA_0/cxl_mem_wrapper_0/m0_axi_hdm] [get_bd_addr_segs axi_noc2_c0/DDR_MC_PORTS/DDR_CH0_HIGH_0] -force
  assign_bd_address -offset 0x00C000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces PA_1/cxl_mem_wrapper_0/m0_axi_hdm] [get_bd_addr_segs axi_noc2_c1/DDR_MC_PORTS/DDR_CH0_HIGH_0] -force
  assign_bd_address -offset 0x00C000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces PA_2/cxl_mem_wrapper_0/m0_axi_hdm] [get_bd_addr_segs axi_noc2_c4/DDR_MC_PORTS/DDR_CH0_HIGH_0] -force
  assign_bd_address -offset 0x00C000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces PA_3/cxl_mem_wrapper_0/m0_axi_hdm] [get_bd_addr_segs axi_noc2_c5/DDR_MC_PORTS/DDR_CH0_HIGH_0] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs ctrl_reg_ep_0/s_axil/reg0]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

# Use existing cxl_protocol if already set (CED context), else default to CXL_3_1
if {![info exists cxl_protocol]} {
    set cxl_protocol CXL_3_1
}
if {![info exists cxl_width]} {
    set cxl_width X8
}

create_root_design "" $cxl_protocol $cxl_width


