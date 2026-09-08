# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

 # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################
proc createDesign {design_name options} {  

  variable currentDir

  ##################################################################
  # RTL MODULEs
  ##################################################################
  add_files -norecurse [glob $currentDir/src/*.sv]
  update_compile_order -fileset sources_1

  ##################################################################
  # IP REPOs
  ##################################################################
  set_property ip_repo_paths [list $currentDir/src/ip_repo] [current_project]
  update_ip_catalog -rebuild

  ##################################################################
  # DESIGN PROCs													 
  ##################################################################
  
  set_property target_language Verilog [current_project]

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\
  xilinx.com:ip:ps_wizard:*\
  xilinx.com:ip:xpm_cdc_gen:*\
  xilinx.com:ip:axi_noc2:*\
  xilinx.com:ip:smartconnect:*\
  xilinx.com:user:pl_axi_cpi_bridge:*\
  xilinx.com:user:custom_axi_tg:*\
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

  ##################################################################
  # CHECK Modules
  ##################################################################
  set bCheckModules 1
  if { $bCheckModules == 1 } {
     set list_check_mods "\
  axil_gpio4\
  freerun_cnt32\
  uram_sdp_4Kx44\
  cpi_f2a_req_passthrough\
  cpi_f2a_data_passthrough\
  cpi_a2f_data_passthrough\
  cpi_a2f_rsp_passthrough\
  cpi_perf_snapshot\
  axil_cxl_pm_viral\
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

  # Hierarchical cell: cxl_datapath_<brdg_id> (one per active CPI interface,
  # brdg_id 0..NUM_CPI-1)
  proc create_hier_cell_cxl_datapath { parentCell nameHier brdg_id } {

    variable script_folder

    if { $parentCell eq "" || $nameHier eq "" } {
       catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_cxl_datapath() - Empty argument(s)!"}
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
    create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_req_rtl:1.0 f2a_req

    create_bd_intf_pin -mode Master -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 f2a_dat

    create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_rsp_rtl:1.0 a2f_rsp

    create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_cpm6:cpi_data_rtl:1.0 a2f_dat

    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axil


    # Create pins
    create_bd_pin -dir I -type clk m_axi_aclk
    create_bd_pin -dir I -type rst s_axi_aresetn
    create_bd_pin -dir I -type clk axil_clk
    create_bd_pin -dir I -type rst axil_rstn
    create_bd_pin -dir I           tg_start

    # Create instance: pl_axi_cpi_bridge_<brdg_id>, and set properties
    set pl_axi_cpi_bridge [ create_bd_cell -type ip -vlnv xilinx.com:user:pl_axi_cpi_bridge pl_axi_cpi_bridge_${brdg_id} ]
    set_property -dict [list \
      CONFIG.AXI_ID_WIDTH {2} \
      CONFIG.BRDG_ID $brdg_id \
      CONFIG.RROB_DEPTH {16} \
      CONFIG.WROB_DEPTH {16} \
    ] $pl_axi_cpi_bridge

    # Create instance: ilconstant_0, and set properties (ties off the
    # unused a2f_dat_emd metadata input on the bridge)
    set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]
    set_property -dict [list \
      CONFIG.CONST_VAL {0} \
      CONFIG.CONST_WIDTH {32} \
    ] $ilconstant_0

    # Create instance: custom_axi_tg_<brdg_id>, and set properties
    set custom_axi_tg [ create_bd_cell -type ip -vlnv xilinx.com:user:custom_axi_tg custom_axi_tg_${brdg_id} ]
    set_property -dict [list \
      CONFIG.AXI_ID_WIDTH {2} \
      CONFIG.EXTERNAL_START_EN {1} \
    ] $custom_axi_tg

    # Create interface connections
    connect_bd_intf_net -intf_net custom_axi_tg_${brdg_id}_m_axi [get_bd_intf_pins custom_axi_tg_${brdg_id}/m_axi] [get_bd_intf_pins pl_axi_cpi_bridge_${brdg_id}/s_axi]
    connect_bd_intf_net -intf_net custom_axi_tg_${brdg_id}_s_axil [get_bd_intf_pins s_axil] [get_bd_intf_pins custom_axi_tg_${brdg_id}/s_axil]
    connect_bd_intf_net -intf_net pl_axi_cpi_bridge_${brdg_id}_f2a_dat [get_bd_intf_pins f2a_dat] [get_bd_intf_pins pl_axi_cpi_bridge_${brdg_id}/f2a_dat]
    connect_bd_intf_net -intf_net pl_axi_cpi_bridge_${brdg_id}_f2a_req [get_bd_intf_pins f2a_req] [get_bd_intf_pins pl_axi_cpi_bridge_${brdg_id}/f2a_req]
    connect_bd_intf_net -intf_net ps_wizard_0_cxl1_cpi${brdg_id}_a2f_data [get_bd_intf_pins a2f_dat] [get_bd_intf_pins pl_axi_cpi_bridge_${brdg_id}/a2f_dat]
    connect_bd_intf_net -intf_net ps_wizard_0_cxl1_cpi${brdg_id}_a2f_rsp [get_bd_intf_pins a2f_rsp] [get_bd_intf_pins pl_axi_cpi_bridge_${brdg_id}/a2f_rsp]

    # Create port connections
    connect_bd_net -net cxl1_clk  [get_bd_pins m_axi_aclk] \
    [get_bd_pins custom_axi_tg_${brdg_id}/m_axi_aclk] \
    [get_bd_pins pl_axi_cpi_bridge_${brdg_id}/s_axi_aclk]
    connect_bd_net -net cxl1_rstn  [get_bd_pins s_axi_aresetn] \
    [get_bd_pins pl_axi_cpi_bridge_${brdg_id}/s_axi_aresetn] \
    [get_bd_pins custom_axi_tg_${brdg_id}/m_axi_aresetn]
    connect_bd_net -net axil_clk  [get_bd_pins axil_clk] \
    [get_bd_pins custom_axi_tg_${brdg_id}/s_axil_aclk]
    connect_bd_net -net axil_rstn  [get_bd_pins axil_rstn] \
    [get_bd_pins custom_axi_tg_${brdg_id}/s_axil_aresetn]
    connect_bd_net -net ilconstant_0_dout  [get_bd_pins ilconstant_0/dout] \
    [get_bd_pins pl_axi_cpi_bridge_${brdg_id}/a2f_dat_emd]
    connect_bd_net -net tg_start  [get_bd_pins tg_start] \
    [get_bd_pins custom_axi_tg_${brdg_id}/i_start]

    # Restore current instance
    current_bd_instance $oldCurInst
  }

  # Adds a module-reference cell, reporting the same errors the
  # Vivado-generated instantiation blocks do on failure.
  proc add_module_ref { block_name cell_name } {
    if { [catch {set cell [create_bd_cell -type module -reference $block_name $cell_name] } errmsg] } {
       catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
       return ""
    } elseif { $cell eq "" } {
       catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
       return ""
    }
    return $cell
  }

  # Assigns the systematic per-CPI address ranges (custom_axi_tg_N/s_axil
  # and perf_measurement/uram_sdp_4Kx44_<idx>/s_axil) into one PS address
  # space, for cpi/idx 0..num_cpi-1 / 0..num_cpi*4-1. See the "Systematic
  # address scheme" comment above the first caller for the offset formulas.
  proc assign_cpi_addr_segs { addr_space num_cpi } {
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      set offset [expr {0x020100200000 + $cpi * 0x10000}]
      assign_bd_address -offset $offset -range 0x00010000 \
        -target_address_space [get_bd_addr_spaces $addr_space] \
        [get_bd_addr_segs cxl_datapath_${cpi}/custom_axi_tg_${cpi}/s_axil/reg0] -force
    }
    for {set idx 0} {$idx < [expr {$num_cpi * 4}]} {incr idx} {
      set offset [expr {0x020200000000 + ($idx / 4) * 0x100000 + ($idx % 4) * 0x10000}]
      assign_bd_address -offset $offset -range 0x00008000 \
        -target_address_space [get_bd_addr_spaces $addr_space] \
        [get_bd_addr_segs perf_measurement/uram_sdp_4Kx44_${idx}/s_axil/reg0] -force
    }
  }

  # Excludes the same per-CPI address ranges from a PS address space that
  # should not be able to reach them (companion to assign_cpi_addr_segs).
  proc exclude_cpi_addr_segs { addr_space num_cpi } {
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces $addr_space] \
        [get_bd_addr_segs cxl_datapath_${cpi}/custom_axi_tg_${cpi}/s_axil/reg0]
    }
    for {set idx 0} {$idx < [expr {$num_cpi * 4}]} {incr idx} {
      exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces $addr_space] \
        [get_bd_addr_segs perf_measurement/uram_sdp_4Kx44_${idx}/s_axil/reg0]
    }
  }

  # Hierarchical cell: perf_measurement
  # The whole CPI perf-monitor pipeline: cpi_passthrough (tap valid/tag)
  # -> cpi_perf_snapshot ({cnt,tag} concat) -> uram_sdp_4Kx44, fed by
  # smartconnect_1 on the AXI-Lite side. Each passthrough's two interface
  # sides are exposed at this hierarchy's own boundary as cpiN_<iface>_ps
  # (connects up to ps_wizard_0) and cpiN_<iface>_cxl (connects up to
  # cxl_datapath_N), so root only has to wire this hierarchy in between
  # the two, same as it always did directly.
  proc create_hier_cell_perf_measurement { parentCell nameHier num_cpi } {

    variable script_folder

    if { $parentCell eq "" || $nameHier eq "" } {
       catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_perf_measurement() - Empty argument(s)!"}
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

    # iface -> {passthrough_module vlnv intf_tag naming_offset cxl_is_master}
    #   naming_offset picks uram_sdp_4Kx44_<idx> (idx = cpi*4 + offset)
    #   cxl_is_master: cxl_datapath_N's own pin is -mode Master for
    #   f2a_req/f2a_data (bridge drives them) and -mode Slave for
    #   a2f_data/a2f_rsp (bridge receives them). This hierarchy's own
    #   boundary pins connect internally, not to cxl_datapath_N directly,
    #   so their mode must match the passthrough port wired to them
    #   (S_<tag> is always Slave, M_<tag> is always Master) - see below.
    set perf_iface_map {
      f2a_req  {cpi_f2a_req_passthrough  xilinx.com:display_cpm6:cpi_req_rtl:1.0  F2A_REQ  0 1}
      f2a_data {cpi_f2a_data_passthrough xilinx.com:display_cpm6:cpi_data_rtl:1.0 F2A_DATA 1 1}
      a2f_data {cpi_a2f_data_passthrough xilinx.com:display_cpm6:cpi_data_rtl:1.0 A2F_DATA 2 0}
      a2f_rsp  {cpi_a2f_rsp_passthrough  xilinx.com:display_cpm6:cpi_rsp_rtl:1.0  A2F_RSP  3 0}
    }

    # Create interface pins
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      foreach {iface spec} $perf_iface_map {
        lassign $spec pt_block vlnv intf_tag naming_offset cxl_is_master
        # Boundary pin mode must match whatever it's wired to internally
        # below: cxl_is_master -> _cxl gets S_<tag> (Slave), _ps gets
        # M_<tag> (Master); otherwise the reverse.
        set cxl_mode [expr {$cxl_is_master ? "Slave" : "Master"}]
        set ps_mode  [expr {$cxl_is_master ? "Master" : "Slave"}]
        create_bd_intf_pin -mode $cxl_mode -vlnv $vlnv "cpi${cpi}_${iface}_cxl"
        create_bd_intf_pin -mode $ps_mode  -vlnv $vlnv "cpi${cpi}_${iface}_ps"
      }
    }

    # Create pins
    create_bd_pin -dir I -type clk clk

    # Create instance: freerun_cnt32_0
    set freerun_cnt32_0 [add_module_ref freerun_cnt32 freerun_cnt32_0]

    # Create instance: smartconnect_1, and set properties
    set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_1 ]
    set_property -dict [list \
      CONFIG.HAS_ARESETN {0} \
      CONFIG.NUM_CLKS {1} \
      CONFIG.NUM_MI [expr {$num_cpi * 4}] \
      CONFIG.NUM_SI {1} \
    ] $smartconnect_1

    # Create instance: uram_sdp_4Kx44_0..15
    for {set i 0} {$i < [expr {$num_cpi * 4}]} {incr i} {
      add_module_ref uram_sdp_4Kx44 "uram_sdp_4Kx44_${i}"
    }

    # Create instance: cpiN_<iface>_passthrough / _snapshot
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      foreach {iface spec} $perf_iface_map {
        lassign $spec pt_block vlnv intf_tag naming_offset cxl_is_master
        add_module_ref $pt_block "cpi${cpi}_${iface}_passthrough"
        add_module_ref cpi_perf_snapshot "cpi${cpi}_${iface}_snapshot"
      }
    }

    # Create interface connections
    connect_bd_intf_net -intf_net perf_measurement_S00_AXI [get_bd_intf_pins S00_AXI] [get_bd_intf_pins smartconnect_1/S00_AXI]
    for {set i 0} {$i < [expr {$num_cpi * 4}]} {incr i} {
      connect_bd_intf_net -intf_net uram_sdp_4Kx44_${i}_s_axil \
        [get_bd_intf_pins smartconnect_1/M[format %02d $i]_AXI] \
        [get_bd_intf_pins uram_sdp_4Kx44_${i}/s_axil]
    }

    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      foreach {iface spec} $perf_iface_map {
        lassign $spec pt_block vlnv intf_tag naming_offset cxl_is_master
        set pt_name "cpi${cpi}_${iface}_passthrough"

        if { $cxl_is_master } {
          connect_bd_intf_net -intf_net ${pt_name}_s \
            [get_bd_intf_pins cpi${cpi}_${iface}_cxl] \
            [get_bd_intf_pins ${pt_name}/S_${intf_tag}]
          connect_bd_intf_net -intf_net ${pt_name}_m \
            [get_bd_intf_pins ${pt_name}/M_${intf_tag}] \
            [get_bd_intf_pins cpi${cpi}_${iface}_ps]
        } else {
          connect_bd_intf_net -intf_net ${pt_name}_s \
            [get_bd_intf_pins cpi${cpi}_${iface}_ps] \
            [get_bd_intf_pins ${pt_name}/S_${intf_tag}]
          connect_bd_intf_net -intf_net ${pt_name}_m \
            [get_bd_intf_pins ${pt_name}/M_${intf_tag}] \
            [get_bd_intf_pins cpi${cpi}_${iface}_cxl]
        }
      }
    }

    # Create port connections
    connect_bd_net [get_bd_pins clk] [get_bd_pins smartconnect_1/aclk]
    connect_bd_net [get_bd_pins clk] [get_bd_pins freerun_cnt32_0/clk]
    for {set i 0} {$i < [expr {$num_cpi * 4}]} {incr i} {
      connect_bd_net [get_bd_pins clk] [get_bd_pins uram_sdp_4Kx44_${i}/clk]
    }

    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      foreach {iface spec} $perf_iface_map {
        lassign $spec pt_block vlnv intf_tag naming_offset cxl_is_master
        set uram_idx [expr {$cpi * 4 + $naming_offset}]

        set pt_name   "cpi${cpi}_${iface}_passthrough"
        set snap_name "cpi${cpi}_${iface}_snapshot"
        set uram_name "uram_sdp_4Kx44_${uram_idx}"

        connect_bd_net [get_bd_pins ${pt_name}/is_valid] [get_bd_pins ${snap_name}/valid]
        connect_bd_net [get_bd_pins ${pt_name}/HDRtag]    [get_bd_pins ${snap_name}/tag]
        connect_bd_net [get_bd_pins freerun_cnt32_0/cnt]  [get_bd_pins ${snap_name}/cnt]
        connect_bd_net [get_bd_pins ${snap_name}/write]   [get_bd_pins ${uram_name}/write]
        connect_bd_net [get_bd_pins ${snap_name}/concat]  [get_bd_pins ${uram_name}/wdata]
      }
    }

    # Restore current instance
    current_bd_instance $oldCurInst
  }


  proc create_root_design { parentCell design_name temp_options} {
  
    puts "INFO: Start of create_root_design"
    set board_name [get_property BOARD_NAME [current_board]]
    set board_part [get_property NAME [current_board_part]]
    set fpga_part  [get_property PART_NAME [current_board_part]]
    set board_rev  [get_property COMPATIBLE_BOARD_REVISIONS [get_boards -of_objects [current_board_part]]]
    puts "INFO: BOARD_NAME $board_name is selected"
    puts "INFO: BOARD_PART $board_part is selected"
    puts "INFO: PART_NAME $fpga_part is selected"

    # Number of active CPI (CXL protocol agent) interfaces, driven by the
    # CED's "Number of CPI Interfaces" dropdown (NUM_CPI). Defaults to 4
    # (the prior fixed behavior) when not supplied.
    set num_cpi 4
    if { [dict exists $temp_options NUM_CPI.VALUE] } {
      set num_cpi [dict get $temp_options NUM_CPI.VALUE]
    }
    puts "INFO: NUM_CPI $num_cpi is selected"

    # CXL revision, driven by the CED's "CXL Revision" dropdown (CXL_REV).
    # Defaults to 3.1 (the prior fixed behavior) when not supplied. CXL 2.0
    # caps the link at Gen5x8 and needs a slower PL0/PL2 reference clock to
    # match the reduced link bandwidth and ease timing.
    set cxl_rev "3.1"
    if { [dict exists $temp_options CXL_REV.VALUE] } {
      set cxl_rev [dict get $temp_options CXL_REV.VALUE]
    }
    if { $cxl_rev eq "2.0" } {
      set cxl_protocol CXL_2_0
      set pl0_ref_freq 250
      set pl2_ref_freq 225
    } else {
      set cxl_protocol CXL_3_1
      set pl0_ref_freq 333.333
      set pl2_ref_freq 250
    }
    puts "INFO: CXL_REV $cxl_rev is selected ($cxl_protocol)"

  	set proj_dir  [get_property DIRECTORY [current_project]]
  	set proj_name [get_property NAME [current_project]]

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
    set CTRL1_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 CTRL1_GT_0 ]

    set ctrl1_gt_refclk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ctrl1_gt_refclk_0 ]


    # Create ports

    # Create instance: ps_wizard_0, and set properties
    set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0 ]
    set_property -dict [list \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_LINK_WIDTH) {X8} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_MODE) {BRIDGE} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_INBOUND_REGIONS) {0} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_MMIO_APERTURES) {0} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_OUTBOUND_REGIONS) {5} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_NUM_PS_APERTURES) {4} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION0_BASEADDR) {0x0000_E000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION0_LIMITADDR) {0x0000_E00F_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION0_MSG_CODE) {0x00} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION0_TARGET) {CFG_TYPE1} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION1_BASEADDR) {0x0000_E010_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION1_LIMITADDR) {0x0000_EFFF_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION1_TARGET) {CFG_TYPE0} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION2_BASEADDR) {0x0080_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION2_LIMITADDR) {0x008F_FFFF_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION2_TRGTADDR) {0x0080_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION3_BASEADDR) {0x0006_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION3_LIMITADDR) {0x0006_FFFF_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION3_TRGTADDR) {0x0006_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION4_BASEADDR) {0x0007_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION4_LIMITADDR) {0x0007_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_OUTBOUND_REGION4_TRGTADDR) {0x0007_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_BASE_CLASS) {Bridge_device} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_SUB_CLASS_INTF) {PCI_to_PCI_bridge} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PF0_USE_CODE_ASSISTANT) {1} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PORT_TYPE) {CXL_RP_T3} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PROTOCOL) $cxl_protocol \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE0_BASEADDR) {0x0000_E000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE0_DEST) {ECAM} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE0_LIMITADDR) {0x0000_EFFF_FFFF} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE1_BASEADDR) {0x0080_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE1_DEST) {DMA} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE1_LIMITADDR) {0x008F_FFFF_FFFF} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE2_BASEADDR) {0x0006_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE2_DEST) {DMA} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE2_LIMITADDR) {0x0006_FFFF_FFFF} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE3_BASEADDR) {0x0007_0000_0000} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE3_DEST) {DMA} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PS_APERTURE3_LIMITADDR) {0x0007_FFFF_FFFF} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_TYPE1_MEMBASE_MEMLIMIT_EN) {1} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT) {64bit_Enabled} \
      CONFIG.CPM6_CONFIG(CPM6_CXL1_INTF) {CPI} \
      CONFIG.CPM6_CONFIG(CPM6_CXL1_NUM_AGENTS) $num_cpi \
      CONFIG.CPM6_CONFIG(PS_USE_NOC_AXI_PCIE0) {1} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PERST) {PS_MIO_19} \
      CONFIG.CPM6_CONFIG(CPM6_CTRL1_PERST_DIR) {out} \
      CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_LINK_WIDTH) {X8} \
      CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_MODE) {BRIDGE} \
      CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_PERST) {PS_MIO_19} \
      CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_PERST_DIR) {out} \
      CONFIG.PS_PMC_CONFIG(CPM6_CTRL1_PROTOCOL) $cxl_protocol \
      CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) $pl0_ref_freq \
      CONFIG.PS_PMC_CONFIG(PMC_CRP_PL1_REF_CTRL_FREQMHZ) {200} \
      CONFIG.PS_PMC_CONFIG(PMC_CRP_PL2_REF_CTRL_FREQMHZ) $pl2_ref_freq \
      CONFIG.PS_PMC_CONFIG(PMC_MIO41) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA low DIRECTION out} \
      CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
      CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {3} \
      CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
      CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC0) {1} \
      CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {1} \
      CONFIG.PS_PMC_CONFIG(PS_USE_NOC_AXI_PCIE0) {1} \
      CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
      CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK1) {1} \
      CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK2) {1} \
    ] $ps_wizard_0


    # Create instance: xpm_cdc_gen_0, and set properties
    set xpm_cdc_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xpm_cdc_gen xpm_cdc_gen_0 ]
    set_property -dict [list \
      CONFIG.CDC_TYPE {xpm_cdc_async_rst} \
      CONFIG.DEST_SYNC_FF {2} \
      CONFIG.INIT_SYNC_FF {true} \
      CONFIG.RST_ACTIVE_HIGH {false} \
    ] $xpm_cdc_gen_0

    # Create instance: xpm_cdc_gen_2, and set properties (synchronizes the
    # same PL reset into the slow axil_clk domain used by the
    # custom_axi_tg_N/s_axil programming interfaces)
    set xpm_cdc_gen_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xpm_cdc_gen xpm_cdc_gen_2 ]
    set_property -dict [list \
      CONFIG.CDC_TYPE {xpm_cdc_async_rst} \
      CONFIG.DEST_SYNC_FF {2} \
      CONFIG.INIT_SYNC_FF {true} \
      CONFIG.RST_ACTIVE_HIGH {false} \
    ] $xpm_cdc_gen_2


    # Create instance: axi_noc2_0, and set properties
    set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_0 ]
    set_property -dict [list \
      CONFIG.NUM_CLKS {6} \
      CONFIG.NUM_MI {4} \
      CONFIG.NUM_SI {3} \
    ] $axi_noc2_0


    set_property -dict [ list \
     CONFIG.DATA_WIDTH {32} \
     CONFIG.APERTURES {{0x201_0000_0000 1G}} \
     CONFIG.CATEGORY {pl} \
   ] [get_bd_intf_pins $axi_noc2_0/M00_AXI]

    set_property -dict [ list \
     CONFIG.DATA_WIDTH {32} \
     CONFIG.APERTURES {{0x202_0000_0000 1G}} \
     CONFIG.CATEGORY {pl} \
   ] [get_bd_intf_pins $axi_noc2_0/M01_AXI]

    set_property -dict [ list \
     CONFIG.DATA_WIDTH {32} \
     CONFIG.CATEGORY {ps_pcie} \
   ] [get_bd_intf_pins $axi_noc2_0/M02_AXI]

    # M03_AXI: slow AXI4-Lite programming path for the 4
    # custom_axi_tg_N/s_axil interfaces, isolated onto its own clock
    # (axil_clk, see aclk5 below) via smartconnect_3.
    set_property -dict [ list \
     CONFIG.DATA_WIDTH {32} \
     CONFIG.APERTURES {{0x203_0000_0000 1G}} \
     CONFIG.CATEGORY {pl} \
   ] [get_bd_intf_pins $axi_noc2_0/M03_AXI]

    # NOTE: S00_AXI -> M02_AXI is deliberately NOT in CONNECTIONS below.
    # Vivado flags that path as illegal (BD 41-3287/BD 41-3129): PS_PCIE's
    # CPM_NOC_AXI_PCIE0 (routed here via M02_AXI) is a hardened physical
    # PS_PCIE<->NOC_NSU connection, and the PMC-to-CPM path is internal to
    # the PMC -- it must not be routed through the reconfigurable NoC from
    # S00_AXI. Removing this entry (and the now-unreachable psv_dpc_0/
    # psv_pmc_0 NOCPSPCIE_REGION0/1/2 address assignments below) matches
    # what Vivado's own BD editor did when prompted to fix the connection.
    set_property -dict [ list \
     CONFIG.DATA_WIDTH {128} \
     CONFIG.R_TRAFFIC_CLASS {BEST_EFFORT} \
     CONFIG.W_TRAFFIC_CLASS {BEST_EFFORT} \
     CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M03_AXI {read_bw {50} write_bw {50} read_avg_burst {4} write_avg_burst {4} }} \
     CONFIG.DEST_IDS {M01_AXI:0x0:M02_AXI:0x40:M00_AXI:0x80:M03_AXI:0xC0} \
     CONFIG.NOC_PARAMS {} \
     CONFIG.CATEGORY {ps_pmc} \
   ] [get_bd_intf_pins $axi_noc2_0/S00_AXI]

    set_property -dict [ list \
     CONFIG.DATA_WIDTH {128} \
     CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M02_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M03_AXI {read_bw {50} write_bw {50} read_avg_burst {4} write_avg_burst {4} }} \
     CONFIG.DEST_IDS {M01_AXI:0x0:M02_AXI:0x40:M00_AXI:0x80:M03_AXI:0xC0} \
     CONFIG.NOC_PARAMS {} \
     CONFIG.CATEGORY {ps_rpu} \
   ] [get_bd_intf_pins $axi_noc2_0/S01_AXI]

    set_property -dict [ list \
     CONFIG.CONNECTIONS {M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M02_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M03_AXI {read_bw {50} write_bw {50} read_avg_burst {4} write_avg_burst {4} }} \
     CONFIG.NOC_PARAMS {} \
   ] [get_bd_intf_pins $axi_noc2_0/S02_AXI]

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
     CONFIG.ASSOCIATED_BUSIF {M02_AXI} \
   ] [get_bd_pins $axi_noc2_0/aclk3]

    set_property -dict [ list \
     CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI} \
   ] [get_bd_pins $axi_noc2_0/aclk4]

    set_property -dict [ list \
     CONFIG.ASSOCIATED_BUSIF {M03_AXI} \
   ] [get_bd_pins $axi_noc2_0/aclk5]

    # Create instance: smartconnect_2, and set properties (fans the PMC
    # AXI-Lite control path out to the remaining cxl1_clk-domain
    # programming interfaces now that perf_axi_tg_access_brdg/sim_trig is
    # gone and axil_gpio4_0 has moved to smartconnect_3/axil_clk below)
    set smartconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_2 ]
    set_property -dict [list \
      CONFIG.NUM_MI {1} \
      CONFIG.NUM_SI {1} \
    ] $smartconnect_2

    # Create instance: smartconnect_3, and set properties (slow AXI4-Lite
    # programming crossbar for the NUM_CPI custom_axi_tg_N/s_axil interfaces
    # plus axil_gpio4_0, all clocked by axil_clk instead of cxl1_clk)
    set smartconnect_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_3 ]
    set_property -dict [list \
      CONFIG.NUM_MI [expr {$num_cpi + 1}] \
      CONFIG.NUM_SI {1} \
    ] $smartconnect_3


    # Create instance: cxl_datapath_0..<num_cpi-1>
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      create_hier_cell_cxl_datapath [current_bd_instance .] cxl_datapath_${cpi} $cpi
    }

    # Create instance: axil_gpio4_0 (replaces axil_gpio16_0 + ilslice_0..3;
    # has one individual output bit per custom_axi_tg_N, no slicing needed)
    set axil_gpio4_0 [add_module_ref axil_gpio4 axil_gpio4_0]

    # Create instance: axil_cxl_pm_viral_0, and set properties
    set axil_cxl_pm_viral_0 [add_module_ref axil_cxl_pm_viral axil_cxl_pm_viral_0]
    set_property -dict [list \
      CONFIG.ASSOCIATED_BUSIF {s_axil} \
    ] [get_bd_pins $axil_cxl_pm_viral_0/s_axi_aclk]

    # Create instance: ilconstant_0, and set properties (ties off the
    # unused viral rcvd/sent inputs on axil_cxl_pm_viral_0)
    set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]

    # Create instance: perf_measurement (the whole CPI perf-monitor
    # pipeline: freerun_cnt32_0 -> cpi_passthrough -> cpi_perf_snapshot ->
    # uram_sdp_4Kx44, fed by smartconnect_1 on the AXI-Lite side - see
    # create_hier_cell_perf_measurement)
    create_hier_cell_perf_measurement [current_bd_instance .] perf_measurement $num_cpi

    # perf_measurement exposes two interface pins per {cpi0..3} x
    # {f2a_req, f2a_data, a2f_data, a2f_rsp}: cpiN_<iface>_ps (wire up to
    # ps_wizard_0) and cpiN_<iface>_cxl (wire up to cxl_datapath_N's own
    # boundary pin, named differently for the *_dat interfaces below).
    set perf_cxl_pin_map {
      f2a_req  f2a_req
      f2a_data f2a_dat
      a2f_data a2f_dat
      a2f_rsp  a2f_rsp
    }

    # Create interface connections
    connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins smartconnect_2/S00_AXI] [get_bd_intf_pins axi_noc2_0/M00_AXI]
    connect_bd_intf_net -intf_net axi_noc2_0_M01_AXI [get_bd_intf_pins axi_noc2_0/M01_AXI] [get_bd_intf_pins perf_measurement/S00_AXI]
    connect_bd_intf_net -intf_net axi_noc2_0_M02_AXI [get_bd_intf_pins axi_noc2_0/M02_AXI] [get_bd_intf_pins ps_wizard_0/CPM_NOC_AXI_PCIE0]
    connect_bd_intf_net -intf_net ctrl1_gt_refclk_0_1 [get_bd_intf_ports ctrl1_gt_refclk_0] [get_bd_intf_pins ps_wizard_0/ctrl1_gt_refclk]
    connect_bd_intf_net -intf_net ps_wizard_0_CTRL1_GT [get_bd_intf_ports CTRL1_GT_0] [get_bd_intf_pins ps_wizard_0/CTRL1_GT]
    connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S02_AXI]
    connect_bd_intf_net -intf_net ps_wizard_0_LPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S01_AXI]
    connect_bd_intf_net -intf_net ps_wizard_0_PMC_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S00_AXI]
    connect_bd_intf_net -intf_net smartconnect_2_M00_AXI [get_bd_intf_pins smartconnect_2/M00_AXI] [get_bd_intf_pins axil_cxl_pm_viral_0/s_axil]
    connect_bd_intf_net -intf_net axi_noc2_0_M03_AXI [get_bd_intf_pins axi_noc2_0/M03_AXI] [get_bd_intf_pins smartconnect_3/S00_AXI]
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      connect_bd_intf_net -intf_net smartconnect_3_M[format %02d $cpi]_AXI \
        [get_bd_intf_pins smartconnect_3/M[format %02d $cpi]_AXI] \
        [get_bd_intf_pins cxl_datapath_${cpi}/s_axil]
    }
    connect_bd_intf_net -intf_net smartconnect_3_M[format %02d $num_cpi]_AXI \
      [get_bd_intf_pins smartconnect_3/M[format %02d $num_cpi]_AXI] \
      [get_bd_intf_pins axil_gpio4_0/S_AXI]

    # Wire perf_measurement in between ps_wizard_0 and cxl_datapath_N,
    # same two connections that used to go directly between them.
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      foreach {iface cxl_pin} $perf_cxl_pin_map {
        connect_bd_intf_net -intf_net perf_measurement_cpi${cpi}_${iface}_ps \
          [get_bd_intf_pins ps_wizard_0/cxl1_cpi${cpi}_${iface}] \
          [get_bd_intf_pins perf_measurement/cpi${cpi}_${iface}_ps]
        connect_bd_intf_net -intf_net perf_measurement_cpi${cpi}_${iface}_cxl \
          [get_bd_intf_pins cxl_datapath_${cpi}/${cxl_pin}] \
          [get_bd_intf_pins perf_measurement/cpi${cpi}_${iface}_cxl]
      }
    }

    # Create port connections
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      connect_bd_net -net axil_gpio4_0_gpio_out_${cpi} \
        [get_bd_pins axil_gpio4_0/gpio_out_${cpi}] \
        [get_bd_pins cxl_datapath_${cpi}/tg_start]
    }

    set cxl1_clk_pins [list \
      [get_bd_pins ps_wizard_0/pl0_ref_clk] \
      [get_bd_pins ps_wizard_0/cxl1_clk] \
      [get_bd_pins xpm_cdc_gen_0/dest_clk] \
      [get_bd_pins smartconnect_2/aclk] \
    ]
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      lappend cxl1_clk_pins [get_bd_pins cxl_datapath_${cpi}/m_axi_aclk]
    }
    lappend cxl1_clk_pins \
      [get_bd_pins perf_measurement/clk] \
      [get_bd_pins axi_noc2_0/aclk4] \
      [get_bd_pins axil_cxl_pm_viral_0/s_axi_aclk]
    connect_bd_net -net cxl1_clk {*}$cxl1_clk_pins

    set cxl1_rstn_pins [list \
      [get_bd_pins xpm_cdc_gen_0/dest_arst] \
      [get_bd_pins smartconnect_2/aresetn] \
    ]
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      lappend cxl1_rstn_pins [get_bd_pins cxl_datapath_${cpi}/s_axi_aresetn]
    }
    lappend cxl1_rstn_pins [get_bd_pins axil_cxl_pm_viral_0/s_axi_aresetn]
    connect_bd_net -net cxl1_rstn {*}$cxl1_rstn_pins

    set axil_clk_pins [list \
      [get_bd_pins ps_wizard_0/pl2_ref_clk] \
      [get_bd_pins xpm_cdc_gen_2/dest_clk] \
      [get_bd_pins smartconnect_3/aclk] \
    ]
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      lappend axil_clk_pins [get_bd_pins cxl_datapath_${cpi}/axil_clk]
    }
    lappend axil_clk_pins \
      [get_bd_pins axil_gpio4_0/s_axi_aclk] \
      [get_bd_pins axi_noc2_0/aclk5]
    connect_bd_net -net axil_clk {*}$axil_clk_pins

    set axil_rstn_pins [list \
      [get_bd_pins xpm_cdc_gen_2/dest_arst] \
      [get_bd_pins smartconnect_3/aresetn] \
    ]
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      lappend axil_rstn_pins [get_bd_pins cxl_datapath_${cpi}/axil_rstn]
    }
    lappend axil_rstn_pins [get_bd_pins axil_gpio4_0/s_axi_aresetn]
    connect_bd_net -net axil_rstn {*}$axil_rstn_pins
    connect_bd_net -net axil_cxl_pm_viral_0_cpm6_pm_in  [get_bd_pins axil_cxl_pm_viral_0/cpm6_pm_in] \
    [get_bd_pins ps_wizard_0/cxl1_pm_pm_in]
    connect_bd_net -net ilconstant_0_dout  [get_bd_pins ilconstant_0/dout] \
    [get_bd_pins axil_cxl_pm_viral_0/cpm6_rx_viral_rcvd] \
    [get_bd_pins axil_cxl_pm_viral_0/cpm6_tx_viral_sent]
    connect_bd_net -net ps_wizard_0_cxl1_pm_pm_out  [get_bd_pins ps_wizard_0/cxl1_pm_pm_out] \
    [get_bd_pins axil_cxl_pm_viral_0/cpm6_pm_out]
    connect_bd_net -net pcie1_clk  [get_bd_pins ps_wizard_0/pl1_ref_clk] \
    [get_bd_pins ps_wizard_0/pcie1_clk]
    connect_bd_net -net pl0_rstn  [get_bd_pins ps_wizard_0/pl0_resetn] \
    [get_bd_pins xpm_cdc_gen_0/src_arst] 
    connect_bd_net -net pl2_rstn  [get_bd_pins ps_wizard_0/pl2_resetn] \
    [get_bd_pins xpm_cdc_gen_2/src_arst]
    connect_bd_net -net ps_wizard_0_cpm_noc_axi_pcie0_clk  [get_bd_pins ps_wizard_0/cpm_noc_axi_pcie0_clk] \
    [get_bd_pins axi_noc2_0/aclk3]
    connect_bd_net -net ps_wizard_0_fpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] \
    [get_bd_pins axi_noc2_0/aclk2]
    connect_bd_net -net ps_wizard_0_lpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] \
    [get_bd_pins axi_noc2_0/aclk1]
    connect_bd_net -net ps_wizard_0_pmc_axi_noc0_clk  [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] \
    [get_bd_pins axi_noc2_0/aclk0]

    # Create address segments
    # Systematic address scheme (see assign_cpi_addr_segs/exclude_cpi_addr_segs):
    #   custom_axi_tg_N/s_axil  -> 0x0201_002N_0000
    #   axil_gpio4_0/S_AXI      -> 0x0201_0024_0000
    #   axil_cxl_pm_viral_0/s_axil -> 0x0201_0025_0000
    #   perf_measurement/uram_sdp_4Kx44_<cpi*4+n> -> 0x0202_00<cpi><n>_0000
    assign_cpi_addr_segs ps_wizard_0/pmcps_0_psv_dpc_0 $num_cpi
    assign_bd_address -offset 0x020100240000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs axil_gpio4_0/S_AXI/reg0] -force
    assign_bd_address -offset 0x020100250000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_dpc_0] [get_bd_addr_segs axil_cxl_pm_viral_0/s_axil/reg0] -force
    # NOCPSPCIE_REGION0/1/2 are no longer reachable from psv_pmc_0 now that
    # S00_AXI -> M02_AXI has been removed above (BD 41-3287/BD 41-3129).
    assign_cpi_addr_segs ps_wizard_0/pmcps_0_psv_pmc_0 $num_cpi
    assign_bd_address -offset 0x020100240000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs axil_gpio4_0/S_AXI/reg0] -force
    assign_bd_address -offset 0x020100250000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_pmc_0] [get_bd_addr_segs axil_cxl_pm_viral_0/s_axil/reg0] -force
    # NOCPSPCIE_REGION0 is no longer reachable from psv_psm_0 now that
    # S00_AXI -> M02_AXI has been removed above (BD 41-3287/BD 41-3129);
    # excluded here rather than assigned, matching REGION1/REGION2 below.
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION0/pmcps_0_psv_noc_pcie_0]
    for {set cpi 0} {$cpi < $num_cpi} {incr cpi} {
      assign_bd_address -offset 0x00000000 -range 0x0001000000000000 -target_address_space [get_bd_addr_spaces cxl_datapath_${cpi}/custom_axi_tg_${cpi}/m_axi] [get_bd_addr_segs cxl_datapath_${cpi}/pl_axi_cpi_bridge_${cpi}/s_axi/reg0] -force
    }

    # Exclude Address Segments
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs axil_cxl_pm_viral_0/s_axil/reg0]
    exclude_bd_addr_seg -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs axil_gpio4_0/S_AXI/reg0]
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/cpm6_0_CPM/cpm6_0_psv_cpm6]
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION0/pmcps_0_psv_noc_pcie_0]
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
    exclude_cpi_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_0 $num_cpi

    exclude_bd_addr_seg -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs axil_cxl_pm_viral_0/s_axil/reg0]
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs axil_gpio4_0/S_AXI/reg0]
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/cpm6_0_CPM/cpm6_0_psv_cpm6]
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cortexr5_1] [get_bd_addr_segs ps_wizard_0/pmcps_0_NOCPSPCIE_REGION0/pmcps_0_psv_noc_pcie_0]
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
    exclude_cpi_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_1 $num_cpi

    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axil_cxl_pm_viral_0/s_axil/reg0]
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs axil_gpio4_0/S_AXI/reg0]
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PMC_SLAVE_BOOT_INT/pmcps_0_psv_pmc_slave_boot]
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_cpm_0] [get_bd_addr_segs ps_wizard_0/pmcps_0_PMC_SLAVE_BOOT_STREAM_INT/pmcps_0_psv_pmc_slave_boot_stream]
    exclude_cpi_addr_segs ps_wizard_0/pmcps_0_psv_cpm_0 $num_cpi

    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs axil_cxl_pm_viral_0/s_axil/reg0]
    exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/pmcps_0_psv_psm_0] [get_bd_addr_segs axil_gpio4_0/S_AXI/reg0]
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
    exclude_cpi_addr_segs ps_wizard_0/pmcps_0_psv_psm_0 $num_cpi

    # Restore current instance
    current_bd_instance $oldCurInst
  
    puts "INFO: End of create_root_design"
  } ;# END: proc create_root_design

  ##################################################################
  # MAIN FLOW
  ##################################################################
  
  create_root_design "" $design_name $options

  save_bd_design
  # Set synthesis property to be non-OOC (whole design synthesizes
  # together instead of the BD/IP being cached as separate out-of-context
  # checkpoints).
  set_property synth_checkpoint_mode None [get_files $design_name.bd]
  validate_bd_design
  regenerate_bd_layout
  open_bd_design [get_bd_files $design_name]
  make_wrapper -files [get_files $design_name.bd] -top -import
  import_files -fileset utils_1 -flat $currentDir/hooks/soft_link_pdis.tcl

  # Copy the README.txt file into the generated project
  set proj_dir [get_property DIRECTORY [current_project]]
  set readme_src [file join $currentDir README.txt]
  file copy -force $readme_src [file join $proj_dir README.txt]
  puts "INFO: copied README.txt to [file join $proj_dir README.txt]"

  # Copy the hardware-exercise script library into the generated project so
  # it lives alongside p.gen/p.sim/... (not just in the CED source tree).
  set xsdb_scripts_src [file join $currentDir xsdb_scripts]
  if { [file isdirectory $xsdb_scripts_src] } {
    set proj_dir [get_property DIRECTORY [current_project]]
    file copy -force $xsdb_scripts_src [file join $proj_dir xsdb_scripts]
    puts "INFO: copied xsdb_scripts to [file join $proj_dir xsdb_scripts]"
  }

  ##################################################################
  # SYNTHESIS STRATEGY (Flow_PerfOptimized_High -> timing focused)
  ##################################################################
  set_property strategy Flow_PerfOptimized_High [get_runs synth_1]

  ##################################################################
  # ADDITIONAL IMPLEMENTATION RUNS
  ##################################################################
  set cur_part    [get_property PART [current_project]]
  # impl_1 (created by default with the project) uses Vivado's default
  # strategy. Add impl_2..impl_N, all based on synth_1/constrs_1, each
  # using a different timing-focused strategy.
  # create_run requires -flow, and the flow name is tied to the Vivado
  # release year -- grab it from [version] rather than hardcoding it.
  if {![regexp {Vivado v(\d*)} [version] -> impl_yr]} {
    error "Vivado release year could not be determined"
  }
  # -> Found that changing synthesis strategy had largest effect, but
  #    keeping these here commented in case the desire exists to 
  #    include these again in the "impl_strategies" variable
  # Performance_ExplorePostRoutePhysOpt
  # Performance_ExploreWithRemap
  # Performance_ExtraTimingOpt
  # Performance_NetDelay_medium
  # Performance_ExtraTimingOpt
  set impl_strategies {
    Performance_Explore
    Performance_AggressiveExplore
  }
  set impl_idx 2
  foreach strategy $impl_strategies {
    create_run impl_$impl_idx -parent_run synth_1 -constrset constrs_1 \
      -flow "Vivado Advanced Implementation $impl_yr" -strategy $strategy \
      -part $cur_part -quiet
    incr impl_idx
  }
  # Create implementation runs at fastest speed grade for comparison
  # Parts are named <device>-<package>-<speedgrade>-<tempgrade>-<option>
  # (e.g. xcvp1902-lsvc784-2MP-e-S-es1). Speed grade rank increases with
  # both the leading digit and the power/perf class (LP < MP < HP), so
  # e.g. 3HP is faster than 2MP. Find the fastest speed grade that (a)
  # actually exists in the part database and (b) is faster than the
  # part currently selected for this project.
  set speed_grade_rank [dict create \
    1LP 0 2LP 1 \
    1MP 2 2MP 3 \
    1HP 4 2HP 5 3HP 6 \
  ]

  set part_fields [split $cur_part "-"]
  set speed_idx -1
  set cur_speed ""
  for {set i 0} {$i < [llength $part_fields]} {incr i} {
    if { [regexp {^[0-9][A-Z]+$} [lindex $part_fields $i]] } {
      set speed_idx $i
      set cur_speed [lindex $part_fields $i]
      break
    }
  }

  set fast_part ""
  if { $speed_idx >= 0 && [dict exists $speed_grade_rank $cur_speed] } {
    set cur_rank  [dict get $speed_grade_rank $cur_speed]
    set best_speed $cur_speed
    set best_rank  $cur_rank
    dict for {speed rank} $speed_grade_rank {
      if { $rank > $best_rank } {
        set candidate_fields $part_fields
        lset candidate_fields $speed_idx $speed
        set candidate_part [join $candidate_fields "-"]
        if { [llength [get_parts -quiet $candidate_part]] > 0 } {
          set best_rank  $rank
          set best_speed $speed
        }
      }
    }
    if { $best_speed ne $cur_speed } {
      set candidate_fields $part_fields
      lset candidate_fields $speed_idx $best_speed
      set fast_part [join $candidate_fields "-"]
    }
  }

  if { $fast_part ne "" } {
    common::send_gid_msg -ssname BD::TCL -id 2099 -severity "INFO" "Adding fast-part implementation runs targeting $fast_part (faster than $cur_part)."
    set impl_strategies [concat [list "Implementation Defaults"] $impl_strategies]
    foreach strategy $impl_strategies {
      create_run impl_$impl_idx\_$best_speed -parent_run synth_1 -constrset constrs_1 \
        -flow "Vivado Advanced Implementation $impl_yr" -strategy $strategy \
        -part $fast_part -quiet
      incr impl_idx
    }
  } else {
    common::send_gid_msg -ssname BD::TCL -id 2100 -severity "INFO" "No faster speed grade available for part $cur_part; skipping fast-part implementation runs."
  }

  ##################################################################
  # WRITE_DEVICE_IMAGE POST HOOK (refresh boot.pdi/pld.pdi symlinks)
  ##################################################################
  set soft_link_pdis_tcl [get_files -of_objects [get_filesets utils_1] "soft_link_pdis.tcl"]
  foreach run [get_runs impl_*] {
    set_property STEPS.WRITE_DEVICE_IMAGE.TCL.POST $soft_link_pdis_tcl $run
  }

  puts "INFO: Design generation complete"
  puts "INFO: Refer to the README.txt file inside the project for information"
}
