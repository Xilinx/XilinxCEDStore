# ########################################################################
# Copyright (C) 2021, Xilinx Inc - All rights reserved
# 
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

proc get_all_quads {pkg} {
  return [concat [get_left $pkg] [get_right $pkg]]
}


proc replace {st foo bar} {
  regsub -all $foo $st $bar st
  return $st
}


proc get_refclk_range {q args} {
  set l [get_reflocs $q]
  set r ""
  foreach c $l {
    lappend r "$c $c"
  }
  foreach c $args {
    lappend r "$c $c"
  }
  return $r
}

proc get_max_refclk_sharing_linerate {} {
  return 16.375
}

proc get_max_linerate {speedgrade} {
  switch $speedgrade {
    -3HP { 
      return 32.75
    }
    -2MP -
    -2HP -
    -2LP {
      return 28.21
    }
    -1MM -
    -1MP {
      return 26.5625
    }
    -1LP {
      return 25.78125
    }
    -1LP {
      return 16.0
    }
    default {
      return 16.0
    }
  }
}

proc pdict {dict {pattern *} f} {
   set longest 0
   dict for {key -} $dict {
      if {[string match $pattern $key]} {
         set longest [expr {max($longest, [string length $key])}]
      }
   }
   dict for {key value} [dict filter $dict key $pattern] {
      puts $f [format "%-${longest}s = %s" $key $value]
   }
}

#
# simplifies handing of non-existent keys in a dict by returning a default value
#
proc dictDefault {d key default} {
  if {[dict exists $d $key]} {
    return [dict get $d $key]
  } else {
    return $default
  }
}


proc createDesign {design_name options} {
  
  proc create_soft_design { parentCell design_name } {
    
    set f [open "create_soft.txt" a]
    puts $f "in create_soft"
    set systemTime [clock seconds]
    puts $f "create_soft: [clock format $systemTime -format %H:%M:%S]"
    
    # Create interface ports
    set GT_Serial_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial_0 ]
   
    set aurora_64b66b_0_diff_gt_ref_clock [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 aurora_64b66b_0_diff_gt_ref_clock ]
    set_property -dict [ list \
     CONFIG.FREQ_HZ {156250000} \
     ] $aurora_64b66b_0_diff_gt_ref_clock
   
   
    # Create ports
   
    # Create instance: aurora_64b66b_0, and set properties
    set aurora_64b66b_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:aurora_64b66b:13.0 aurora_64b66b_0 ]
    set_property -dict [list \
      CONFIG.C_LINE_RATE {10.0} \
      CONFIG.C_USE_BYTESWAP {true} \
      CONFIG.C_NEW_WIZ_MODE {false} \
      CONFIG.dataflow_config {TX/RX_Simplex} \
    ] $aurora_64b66b_0
   
   
    # Create instance: axi_dbg_hub_0, and set properties
    set axi_dbg_hub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dbg_hub:2.0 axi_dbg_hub_0 ]
    set_property -dict [list \
      CONFIG.C_AXI_ADDR_WIDTH {44} \
      CONFIG.C_AXI_DATA_WIDTH {32} \
      CONFIG.C_AXI_ID_WIDTH {16} \
      CONFIG.C_NUM_DEBUG_CORES {0} \
    ] $axi_dbg_hub_0
   
   
    # Create instance: axis_vio_0, and set properties
    set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio:1.0 axis_vio_0 ]
    set_property -dict [list \
      CONFIG.C_EN_AXIS_IF {0} \
      CONFIG.C_NUM_PROBE_IN {14} \
      CONFIG.C_NUM_PROBE_OUT {3} \
      CONFIG.C_PROBE_IN10_WIDTH {1} \
      CONFIG.C_PROBE_IN11_WIDTH {1} \
      CONFIG.C_PROBE_IN12_WIDTH {1} \
      CONFIG.C_PROBE_OUT0_WIDTH {1} \
      CONFIG.C_PROBE_OUT1_WIDTH {3} \
    ] $axis_vio_0
   
   
    # Create instance: bufg_gt, and set properties
    set bufg_gt [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt ]
   
    # Create instance: bufg_gt_1, and set properties
    set bufg_gt_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_1 ]
   
    # Create instance: gt_quad_base, and set properties
    set gt_quad_base [ create_bd_cell -type ip -vlnv xilinx.com:ip:gt_quad_base:1.1 gt_quad_base ]
    set_property -dict [list \
      CONFIG.PORTS_INFO_DICT {LANE_SEL_DICT {PROT0 {RX0 TX0} unconnected {RX1 RX2 RX3 TX1 TX2 TX3}} GT_TYPE GTY REG_CONF_INTF APB3_INTF BOARD_PARAMETER { }} \
      CONFIG.REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_156.25_MHz_unique1} \
    ] $gt_quad_base
   
   
    # Create instance: proc_sys_reset_0, and set properties
    set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
   
    # Create instance: util_ds_buf, and set properties
    set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf ]
    set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $util_ds_buf
   
   
    # Create instance: util_ds_buf_0, and set properties
    set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0 ]
    set_property CONFIG.C_BUF_TYPE {BUFG} $util_ds_buf_0
   
   
    # Create instance: versal_cips_0, and set properties
    set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
    set_property -dict [list \
      CONFIG.CPM_CONFIG { \
        CPM_PCIE0_ARI_CAP_ENABLED {0} \
        CPM_PCIE0_MODE0_FOR_POWER {NONE} \
        CPM_PCIE0_MODES {None} \
        CPM_PCIE0_PF0_MSIX_CAP_TABLE_SIZE {001} \
        CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE {001} \
        CPM_PCIE0_PF2_MSIX_CAP_TABLE_SIZE {001} \
        CPM_PCIE0_PF3_MSIX_CAP_TABLE_SIZE {001} \
        CPM_PCIE1_ARI_CAP_ENABLED {0} \
        CPM_PCIE1_MODE1_FOR_POWER {NONE} \
        PS_HSDP_EGRESS_TRAFFIC {PL} \
        PS_HSDP_INGRESS_TRAFFIC {PL} \
      } \
      CONFIG.PS_PMC_CONFIG { \
        DESIGN_MODE {1} \
        PMC_CRP_DFT_OSC_REF_CTRL_ACT_FREQMHZ {400} \
        PMC_CRP_EFUSE_REF_CTRL_ACT_FREQMHZ {80.000000} \
        PMC_CRP_EFUSE_REF_CTRL_FREQMHZ {80.000000} \
        PMC_CRP_NOC_REF_CTRL_ACT_FREQMHZ {949.990479} \
        PMC_CRP_NOC_REF_CTRL_FREQMHZ {950} \
        PMC_CRP_NPLL_CTRL_FBDIV {114} \
        PMC_CRP_PL0_REF_CTRL_ACT_FREQMHZ {149.998505} \
        PMC_CRP_PL0_REF_CTRL_DIVISOR0 {8} \
        PMC_CRP_PL0_REF_CTRL_FREQMHZ {156.25} \
        PMC_CRP_PL0_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_PL5_REF_CTRL_FREQMHZ {400} \
        PMC_CRP_SWITCH_TIMEOUT_CTRL_DIVISOR0 {80} \
        PMC_CRP_TEST_PATTERN_REF_CTRL_ACT_FREQMHZ {200} \
        PMC_CRP_USB_SUSPEND_CTRL_DIVISOR0 {400} \
        PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pulldown} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO43 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW slow} {USAGE Reserved}} \
        PMC_MIO_TREE_PERIPHERALS {#####################################GPIO 1#####UART 0#UART 0##################################} \
        PMC_MIO_TREE_SIGNALS {#####################################gpio_1_pin[37]#####rxd#txd##################################} \
        PS_BOARD_INTERFACE {Custom} \
        PS_CRL_CAN0_REF_CTRL_FREQMHZ {160} \
        PS_CRL_CAN0_REF_CTRL_SRCSEL {NPLL} \
        PS_CRL_CAN1_REF_CTRL_FREQMHZ {160} \
        PS_CRL_CAN1_REF_CTRL_SRCSEL {NPLL} \
        PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ {474.995239} \
        PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {475} \
        PS_CRL_CPM_TOPSW_REF_CTRL_SRCSEL {NPLL} \
        PS_CRL_IOU_SWITCH_CTRL_ACT_FREQMHZ {239.997604} \
        PS_CRL_IOU_SWITCH_CTRL_DIVISOR0 {5} \
        PS_CRL_IOU_SWITCH_CTRL_SRCSEL {RPLL} \
        PS_CRL_UART0_REF_CTRL_ACT_FREQMHZ {99.999001} \
        PS_CRL_USB3_DUAL_REF_CTRL_ACT_FREQMHZ {100} \
        PS_CRL_USB3_DUAL_REF_CTRL_DIVISOR0 {100} \
        PS_CRL_USB3_DUAL_REF_CTRL_FREQMHZ {100} \
        PS_HSDP_EGRESS_TRAFFIC {PL} \
        PS_HSDP_INGRESS_TRAFFIC {PL} \
        PS_M_AXI_LPD_DATA_WIDTH {32} \
        PS_NUM_FABRIC_RESETS {1} \
        PS_TTC0_PERIPHERAL_ENABLE {0} \
        PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
        PS_USE_M_AXI_FPD {0} \
        PS_USE_M_AXI_LPD {1} \
        PS_USE_PMCPL_CLK0 {1} \
        PS_USE_S_AXI_FPD {0} \
        PS_USE_S_AXI_GP2 {0} \
        PS_USE_S_AXI_LPD {0} \
        SMON_ALARMS {Set_Alarms_On} \
        SMON_ENABLE_TEMP_AVERAGING {0} \
        SMON_TEMP_AVERAGING_SAMPLES {0} \
      } \
    ] $versal_cips_0
   
   
    # Create interface connections
    connect_bd_intf_net -intf_net aurora_64b66b_0_RX_LANE0 [get_bd_intf_pins aurora_64b66b_0/RX_LANE0] [get_bd_intf_pins gt_quad_base/RX0_GT_IP_Interface]
    connect_bd_intf_net -intf_net aurora_64b66b_0_TX_LANE0 [get_bd_intf_pins aurora_64b66b_0/TX_LANE0] [get_bd_intf_pins gt_quad_base/TX0_GT_IP_Interface]
    connect_bd_intf_net -intf_net aurora_64b66b_0_USER_DATA_M_AXIS_RX [get_bd_intf_pins aurora_64b66b_0/USER_DATA_M_AXIS_RX] [get_bd_intf_pins versal_cips_0/S_AXIS_HSDP_INGRESS]
    connect_bd_intf_net -intf_net aurora_64b66b_0_diff_gt_ref_clock_1 [get_bd_intf_ports aurora_64b66b_0_diff_gt_ref_clock] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
    connect_bd_intf_net -intf_net gt_quad_base_GT_Serial [get_bd_intf_ports GT_Serial_0] [get_bd_intf_pins gt_quad_base/GT_Serial]
    connect_bd_intf_net -intf_net versal_cips_0_M_AXI_GP2 [get_bd_intf_pins axi_dbg_hub_0/S_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_LPD]
    connect_bd_intf_net -intf_net versal_cips_0_S_AXIS_HSDP_EGRESS [get_bd_intf_pins aurora_64b66b_0/USER_DATA_S_AXIS_TX] [get_bd_intf_pins versal_cips_0/S_AXIS_HSDP_EGRESS]
   
    # Create port connections
    connect_bd_net -net aurora_64b66b_0_link_reset_out [get_bd_pins aurora_64b66b_0/link_reset_out] [get_bd_pins axis_vio_0/probe_in7]
    connect_bd_net -net aurora_64b66b_0_reset2fg [get_bd_pins aurora_64b66b_0/reset2fg] [get_bd_pins axis_vio_0/probe_in12]
    connect_bd_net -net aurora_64b66b_0_rx_channel_up [get_bd_pins aurora_64b66b_0/rx_channel_up] [get_bd_pins axis_vio_0/probe_in1]
    connect_bd_net -net aurora_64b66b_0_rx_hard_err [get_bd_pins aurora_64b66b_0/rx_hard_err] [get_bd_pins axis_vio_0/probe_in4]
    connect_bd_net -net aurora_64b66b_0_rx_lane_up [get_bd_pins aurora_64b66b_0/rx_lane_up] [get_bd_pins axis_vio_0/probe_in5]
    connect_bd_net -net aurora_64b66b_0_rx_soft_err [get_bd_pins aurora_64b66b_0/rx_soft_err] [get_bd_pins axis_vio_0/probe_in6]
    connect_bd_net -net aurora_64b66b_0_rx_sys_reset_out [get_bd_pins aurora_64b66b_0/rx_sys_reset_out] [get_bd_pins axis_vio_0/probe_in11]
    connect_bd_net -net aurora_64b66b_0_tx_channel_up [get_bd_pins aurora_64b66b_0/tx_channel_up] [get_bd_pins axis_vio_0/probe_in8]
    connect_bd_net -net aurora_64b66b_0_tx_lane_up [get_bd_pins aurora_64b66b_0/tx_lane_up] [get_bd_pins axis_vio_0/probe_in9]
    connect_bd_net -net aurora_64b66b_0_tx_sys_reset_out [get_bd_pins aurora_64b66b_0/tx_sys_reset_out] [get_bd_pins axis_vio_0/probe_in10]
    connect_bd_net -net bufg_gt_1_usrclk [get_bd_pins bufg_gt_1/usrclk] [get_bd_pins aurora_64b66b_0/rxusrclk_in] [get_bd_pins gt_quad_base/ch0_rxusrclk] [get_bd_pins gt_quad_base/ch1_rxusrclk] [get_bd_pins gt_quad_base/ch2_rxusrclk] [get_bd_pins gt_quad_base/ch3_rxusrclk]
    connect_bd_net -net bufg_gt_usrclk [get_bd_pins bufg_gt/usrclk] [get_bd_pins aurora_64b66b_0/user_clk] [get_bd_pins gt_quad_base/ch0_txusrclk] [get_bd_pins gt_quad_base/ch1_txusrclk] [get_bd_pins gt_quad_base/ch2_txusrclk] [get_bd_pins gt_quad_base/ch3_txusrclk] [get_bd_pins versal_cips_0/hsdp_ref_clk]
    connect_bd_net -net clk_wizard_0_clk_out1 [get_bd_pins util_ds_buf_0/BUFG_O] [get_bd_pins aurora_64b66b_0/init_clk] [get_bd_pins axi_dbg_hub_0/aclk] [get_bd_pins axis_vio_0/clk] [get_bd_pins gt_quad_base/altclk] [get_bd_pins gt_quad_base/apb3clk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins versal_cips_0/m_axi_lpd_aclk]
    connect_bd_net -net gt_quad_base_ch0_rxbyteisaligned [get_bd_pins gt_quad_base/ch0_rxbyteisaligned] [get_bd_pins axis_vio_0/probe_in2]
    connect_bd_net -net gt_quad_base_ch0_rxoutclk [get_bd_pins gt_quad_base/ch0_rxoutclk] [get_bd_pins bufg_gt_1/outclk]
    connect_bd_net -net gt_quad_base_ch0_txoutclk [get_bd_pins gt_quad_base/ch0_txoutclk] [get_bd_pins bufg_gt/outclk]
    connect_bd_net -net gt_quad_base_gtpowergood [get_bd_pins gt_quad_base/gtpowergood] [get_bd_pins aurora_64b66b_0/gt_powergood_in]
    connect_bd_net -net hsclk0_lcplllock [get_bd_pins gt_quad_base/hsclk0_lcplllock] [get_bd_pins axis_vio_0/probe_in3]
    connect_bd_net -net loopback [get_bd_pins axis_vio_0/probe_out1] [get_bd_pins gt_quad_base/ch0_loopback] [get_bd_pins gt_quad_base/ch1_loopback] [get_bd_pins gt_quad_base/ch2_loopback] [get_bd_pins gt_quad_base/ch3_loopback]
    connect_bd_net -net pma_init_1 [get_bd_pins axis_vio_0/probe_out0] [get_bd_pins aurora_64b66b_0/pma_init] [get_bd_pins axis_vio_0/probe_in0]
    connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins proc_sys_reset_0/mb_reset] [get_bd_pins axis_vio_0/probe_in13]
    connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_dbg_hub_0/aresetn]
    connect_bd_net -net tx_rx_reset [get_bd_pins axis_vio_0/probe_out2] [get_bd_pins aurora_64b66b_0/rx_reset_pb] [get_bd_pins aurora_64b66b_0/tx_reset_pb]
    connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins util_ds_buf/IBUF_OUT] [get_bd_pins gt_quad_base/GT_REFCLK0]
    connect_bd_net -net versal_cips_0_pl_clk0 [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins util_ds_buf_0/BUFG_I]
    connect_bd_net -net versal_cips_0_pl_resetn0 [get_bd_pins versal_cips_0/pl0_resetn] [get_bd_pins proc_sys_reset_0/ext_reset_in]
   
    # Create address segments
    assign_bd_address -offset 0x80000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_LPD] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force


    puts $f "done!"
    close $f
    
    validate_bd_design
    save_bd_design
  }
  
  #
  # Create XDC with location and timing constraints
  #
  proc make_xdc {design_name options} {
    set f [open "make_xdc.txt" w]
    puts $f "make_xdc"
    set outputfile [open ${design_name}.xdc w]
    

    
    set part [get_property PART [current_project]]
    set toks [split $part "-"]
    set pkg [lindex $toks 1]
    set default_quad [lindex [get_all_quads $pkg] 0]
    puts $f "default quad: $default_quad"
    set quad [dictDefault $options Quad.VALUE $default_quad]
    set refclk [dictDefault $options Clk.VALUE REFCLK0]
    set quad_loc [get_gtloc $quad]
    puts $f "quad_loc: $quad_loc , $refclk"
    set inst "${design_name}_i/gt_quad_base/inst/quad_inst"
    set line_rate 10.0
    set period [expr 1 / ($line_rate * 1.0 / 80.0) ]
    if {$refclk eq "REFCLK0"} {
      set ref_idx 0
    } else {
      set ref_idx 1
    }
    
    set ref_coord [lindex [get_reflocs $quad] $ref_idx]
    puts $f "ref_coord: $ref_coord"
    
    puts $outputfile "set_property LOC ${quad_loc} \[get_cells $inst\]"
    puts $outputfile "create_clock -period ${period} \[get_pins -hierarchical -regexp ${inst}/CH0_TXOUTCLK\]"
    puts $outputfile "create_clock -period ${period} \[get_pins -hierarchical -regexp ${inst}/CH0_RXOUTCLK\]"
    set inst "${design_name}_i/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5\[0\].IBUFDS_GTE5_I"
    puts $outputfile "set_property LOC ${ref_coord} \[get_cells  $inst\]"
    puts $outputfile ""
    #puts $outputfile "############ FILL IN CLOCK CONSTRAINTS BELOW #################"
    #puts $outputfile "# set_property PACKAGE_PIN A1 \[get_ports pl_hsdp_clk_0\]"
    #puts $outputfile "# set_property IOSTANDARD DIFF_SSTL12 \[get_ports pl_hsdp_clk_0\]"
    #puts $outputfile "# create_clock -period 10.0 \[get_ports pl_hsdp_clk_0\]"
    
    puts $outputfile "\nset_property BITSTREAM.GENERAL.COMPRESS TRUE \[current_design\]"
    puts $outputfile "\nset_false_path -to \[get_pins {versal_hsdp_i\/axis_vio_0\/inst/probe_in_inst\/probe_in_reg_reg\[*\]/D}\]"
    puts $outputfile "\nset_false_path -from \[get_clocks clk_pl_0\] -to \[get_clocks versal_hsdp_i\/gt_quad_base\/inst\/quad_inst\/CH0_TXOUTCLK\]"

    close $outputfile
    puts $f "done!"
    close $f

    import_files -fileset constrs_1 -norecurse "./${design_name}.xdc"
  }
  
  
  set f [open "create_design.txt" a]
  puts $f "in createDesign"
  set systemTime [clock seconds]
  puts $f "createDesign: [clock format $systemTime -format %H:%M:%S]"
  puts $f $options
  foreach k $options {
    puts $f "$k"
  }
  flush $f
  set type [dictDefault $options Type.VALUE "Soft_Aurora"]
  puts $f "type: $type"
  flush $f
  
  puts $f "creating soft design"
  create_soft_design "" $design_name
  puts $f "created soft design, about to run make_xdc"
  make_xdc $design_name $options  
  flush $f
  puts $f "about to make wrapper for $design_name"
  flush $f
  set proj_name [lindex [get_projects] 0]
  set proj_dir [get_property DIRECTORY $proj_name]
  set_property TARGET_LANGUAGE Verilog $proj_name
  make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
	add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
  puts $f "made wrapper"
  # close_bd_design [get_bd_designs $design_name]
  # set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
  open_bd_design [get_bd_files $design_name]
  close $f
  
}


