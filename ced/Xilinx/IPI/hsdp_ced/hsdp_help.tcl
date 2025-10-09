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
  
  proc create_soft_design { parentCell design_name options} {
    
    set f [open "create_soft.txt" a]
    puts $f "in create_soft"
    set systemTime [clock seconds]
    puts $f "create_soft: [clock format $systemTime -format %H:%M:%S]"

  set part [get_property PART [current_project]]
  set device [lindex [split $part -] 0]
  set pkg [lindex [split $part -] 1] 
  set toks [split $part "-"]
  set default_quad [lindex [get_all_quads $pkg] 0]
  set quad [dictDefault $options Quad.VALUE $default_quad]
  set gttype [lindex [split $quad "_"] 0]    


  # Create interface ports
  set aurora_64b66b_0_diff_gt_ref_clock [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 aurora_64b66b_0_diff_gt_ref_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
   ] $aurora_64b66b_0_diff_gt_ref_clock

  set Quad0_GT_Serial_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 Quad0_GT_Serial_0 ]


  # Create ports

  # Create instance: aurora_64b66b_0, and set properties
  set aurora_64b66b_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:aurora_64b66b aurora_64b66b_0 ]
  set_property -dict [list \
    CONFIG.C_LINE_RATE {10.0} \
    CONFIG.C_GT_TYPE $gttype  \
    CONFIG.C_NEW_WIZ_MODE {true} \
    CONFIG.C_USE_BYTESWAP {true} \
    CONFIG.dataflow_config {TX/RX_Simplex} \
  ] $aurora_64b66b_0


  # Create instance: axi_dbg_hub_0, and set properties
  set axi_dbg_hub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dbg_hub axi_dbg_hub_0 ]
  set_property CONFIG.C_NUM_DEBUG_CORES {0} $axi_dbg_hub_0


  # Create instance: axis_vio_0, and set properties
  set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio axis_vio_0 ]
  set_property -dict [list \
    CONFIG.C_EN_AXIS_IF {0} \
    CONFIG.C_NUM_PROBE_IN {13} \
    CONFIG.C_NUM_PROBE_OUT {3} \
    CONFIG.C_PROBE_IN10_WIDTH {1} \
    CONFIG.C_PROBE_IN11_WIDTH {1} \
    CONFIG.C_PROBE_IN12_WIDTH {1} \
    CONFIG.C_PROBE_OUT0_WIDTH {1} \
    CONFIG.C_PROBE_OUT1_WIDTH {3} \
  ] $axis_vio_0


  # Create instance: bufg_gt, and set properties
  set bufg_gt [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt ]

  # Create instance: bufg_gt_1, and set properties
  set bufg_gt_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_1 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: util_ds_buf, and set properties
  if {$gttype eq "GTM"} {	  
    set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf ]
    set_property CONFIG.C_BUF_TYPE {IBUFDS_GTME5} $util_ds_buf   
    create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant xlconstant
    set_property CONFIG.CONST_VAL {0} [get_bd_cells xlconstant]
    connect_bd_net [get_bd_pins xlconstant/dout] [get_bd_pins util_ds_buf/IBUFDS_GTME5_CEB]    
  } else {
    set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf ]
    set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $util_ds_buf
  }

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_0 ]
  set_property CONFIG.C_BUF_TYPE {BUFG} $util_ds_buf_0

  # Create instance: gtwiz_versal_0, and set properties
  set gtwiz_versal_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gtwiz_versal gtwiz_versal_0 ]
set_property -dict [list \
  CONFIG.GT_TYPE $gttype \
  CONFIG.INTF0_NO_OF_LANES {1} \
  CONFIG.QUAD0_CH0_LOOPBACK_EN {true} \
  CONFIG.QUAD0_CH1_LOOPBACK_EN {true} \
  CONFIG.QUAD0_CH2_LOOPBACK_EN {true} \
  CONFIG.QUAD0_CH3_LOOPBACK_EN {true} \
  CONFIG.QUAD0_PROT0_LANES {1} \
  CONFIG.QUAD0_PROT0_RX1_EN {false} \
  CONFIG.QUAD0_PROT0_RX2_EN {false} \
  CONFIG.QUAD0_PROT0_RX3_EN {false} \
  CONFIG.QUAD0_PROT0_TX1_EN {false} \
  CONFIG.QUAD0_PROT0_TX2_EN {false} \
  CONFIG.QUAD0_PROT0_TX3_EN {false} \
] [get_bd_cells gtwiz_versal_0]

  set_property -dict [list \
    CONFIG.INTF0_GT_SETTINGS.VALUE_MODE {auto} \
    CONFIG.INTF0_PARENTID.VALUE_MODE {auto} \
    CONFIG.INTF_PARENT_PIN_LIST.VALUE_MODE {auto} \
  ] $gtwiz_versal_0

  # Create instance: versal_cips_0, and set properties  
  if {$device eq "xcvp1902" || $device eq "xcvm2152" || $device eq "xcvr1602" || $device eq "xcvr1652" || $device eq "xc10S70"} {
    set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard versal_cips_0 ]
      set_property -dict [list \
        CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {150} \
        CONFIG.PS_PMC_CONFIG(PS_HSDP_INGRESS_TRAFFIC) {PL} \
        CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
        CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
        CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_PL) {1} \
        CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
      ] $versal_cips_0
    connect_bd_intf_net -intf_net versal_cips_0_M_AXI_FPD [get_bd_intf_pins versal_cips_0/FPD_AXI_PL] [get_bd_intf_pins axi_dbg_hub_0/S_AXI]
    connect_bd_intf_net -intf_net aurora_64b66b_0_USER_DATA_M_AXIS_RX [get_bd_intf_pins aurora_64b66b_0/USER_DATA_M_AXIS_RX] [get_bd_intf_pins versal_cips_0/S_AXIS_HSDP_INGRESS]
    connect_bd_intf_net -intf_net versal_cips_0_S_AXIS_HSDP_EGRESS [get_bd_intf_pins versal_cips_0/S_AXIS_HSDP_EGRESS] [get_bd_intf_pins aurora_64b66b_0/USER_DATA_S_AXIS_TX]
    connect_bd_net -net clk_wizard_0_clk_out1  [get_bd_pins util_ds_buf_0/BUFG_O] \
    [get_bd_pins aurora_64b66b_0/init_clk] \
    [get_bd_pins axi_dbg_hub_0/aclk] \
    [get_bd_pins axis_vio_0/clk] \
    [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
    [get_bd_pins versal_cips_0/fpd_axi_pl_aclk] \
    [get_bd_pins gtwiz_versal_0/gtwiz_freerun_clk]
  } elseif {$device eq "xc2ve3504" || $device eq "xc2ve3558" || $device eq "xc2ve3804" || $device eq "xc2ve3858" || $device eq "xc2vm3558" || $device eq "xc2vm3858" } {
    set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard versal_cips_0 ]
      set_property -dict [list \
        CONFIG.PS11_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {150} \
        CONFIG.PS11_CONFIG(PS_HSDP_INGRESS_TRAFFIC) {PL} \
        CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
        CONFIG.PS11_CONFIG(PS_SLR_ID) {0} \
        CONFIG.PS11_CONFIG(PS_USE_LPD_AXI_PL) {1} \
        CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} \
      ] $versal_cips_0
    connect_bd_intf_net -intf_net versal_cips_0_M_AXI_FPD [get_bd_intf_pins versal_cips_0/LPD_AXI_PL] [get_bd_intf_pins axi_dbg_hub_0/S_AXI]  
    connect_bd_intf_net -intf_net aurora_64b66b_0_USER_DATA_M_AXIS_RX [get_bd_intf_pins aurora_64b66b_0/USER_DATA_M_AXIS_RX] [get_bd_intf_pins versal_cips_0/HSDP_INGRESS_AXIS]
    connect_bd_intf_net -intf_net versal_cips_0_S_AXIS_HSDP_EGRESS [get_bd_intf_pins versal_cips_0/HSDP_EGRESS_AXIS] [get_bd_intf_pins aurora_64b66b_0/USER_DATA_S_AXIS_TX]    
    connect_bd_net -net clk_wizard_0_clk_out1  [get_bd_pins util_ds_buf_0/BUFG_O] \
    [get_bd_pins aurora_64b66b_0/init_clk] \
    [get_bd_pins axi_dbg_hub_0/aclk] \
    [get_bd_pins axis_vio_0/clk] \
    [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
    [get_bd_pins versal_cips_0/lpd_axi_pl_aclk] \
    [get_bd_pins gtwiz_versal_0/gtwiz_freerun_clk]
  } elseif {$device eq "xcvn3716"} {
    set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psx_wizard versal_cips_0 ]
      set_property -dict [list \
        CONFIG.PSX_PMCX_CONFIG(PMCX_CRP_PL0_REF_CTRL_FREQMHZ) {150} \
        CONFIG.PS11_CONFIG(PSX_HSDP_INGRESS_TRAFFIC) {PL} \
        CONFIG.PS11_CONFIG(PSX_NUM_FABRIC_RESETS) {1} \
        CONFIG.PS11_CONFIG(PSX_SLR_ID) {0} \
        CONFIG.PS11_CONFIG(PSX_USE_FPD_AXI_PL) {1} \
        CONFIG.PS11_CONFIG(PSX_USE_PMCPL_CLK0) {1} \
      ] $versal_cips_0
    connect_bd_intf_net -intf_net versal_cips_0_M_AXI_FPD [get_bd_intf_pins versal_cips_0/FPD_AXI_PL] [get_bd_intf_pins axi_dbg_hub_0/S_AXI]
    connect_bd_intf_net -intf_net aurora_64b66b_0_USER_DATA_M_AXIS_RX [get_bd_intf_pins aurora_64b66b_0/USER_DATA_M_AXIS_RX] [get_bd_intf_pins versal_cips_0/HSDP_INGRESS_AXIS]
    connect_bd_intf_net -intf_net versal_cips_0_S_AXIS_HSDP_EGRESS [get_bd_intf_pins versal_cips_0/HSDP_EGRESS_AXIS] [get_bd_intf_pins aurora_64b66b_0/USER_DATA_S_AXIS_TX]    
    connect_bd_net -net clk_wizard_0_clk_out1  [get_bd_pins util_ds_buf_0/BUFG_O] \
    [get_bd_pins aurora_64b66b_0/init_clk] \
    [get_bd_pins axi_dbg_hub_0/aclk] \
    [get_bd_pins axis_vio_0/clk] \
    [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
    [get_bd_pins versal_cips_0/fpd_axi_pl_aclk] \
    [get_bd_pins gtwiz_versal_0/gtwiz_freerun_clk]
  } else {
      set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
        set_property -dict [list \
          CONFIG.CLOCK_MODE {Custom} \
          CONFIG.DEBUG_MODE {Custom} \
          CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
          CONFIG.PS_PMC_CONFIG { \
            CLOCK_MODE {Custom} \
            DEBUG_MODE {Custom} \
            PMC_CRP_PL0_REF_CTRL_FREQMHZ {150} \
            PS_HSDP_INGRESS_TRAFFIC {PL} \
            PS_M_AXI_FPD_DATA_WIDTH {32} \
            PS_NUM_FABRIC_RESETS {1} \
            PS_PL_CONNECTIVITY_MODE {Custom} \
            PS_USE_M_AXI_FPD {1} \
            PS_USE_PMCPL_CLK0 {1} \
            SMON_ALARMS {Set_Alarms_On} \
            SMON_ENABLE_TEMP_AVERAGING {0} \
            SMON_TEMP_AVERAGING_SAMPLES {0} \
         } \
       ] $versal_cips_0

      connect_bd_intf_net -intf_net versal_cips_0_M_AXI_FPD [get_bd_intf_pins versal_cips_0/M_AXI_FPD] [get_bd_intf_pins axi_dbg_hub_0/S_AXI]
      connect_bd_intf_net -intf_net aurora_64b66b_0_USER_DATA_M_AXIS_RX [get_bd_intf_pins aurora_64b66b_0/USER_DATA_M_AXIS_RX] [get_bd_intf_pins versal_cips_0/S_AXIS_HSDP_INGRESS]
      connect_bd_intf_net -intf_net versal_cips_0_S_AXIS_HSDP_EGRESS [get_bd_intf_pins versal_cips_0/S_AXIS_HSDP_EGRESS] [get_bd_intf_pins aurora_64b66b_0/USER_DATA_S_AXIS_TX]      
      connect_bd_net -net clk_wizard_0_clk_out1  [get_bd_pins util_ds_buf_0/BUFG_O] \
      [get_bd_pins aurora_64b66b_0/init_clk] \
      [get_bd_pins axi_dbg_hub_0/aclk] \
      [get_bd_pins axis_vio_0/clk] \
      [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
      [get_bd_pins versal_cips_0/m_axi_fpd_aclk] \
      [get_bd_pins gtwiz_versal_0/gtwiz_freerun_clk]
    }

  # Create interface connections
  connect_bd_intf_net -intf_net aurora_64b66b_0_RX_LANE0 [get_bd_intf_pins aurora_64b66b_0/RX_LANE0] [get_bd_intf_pins gtwiz_versal_0/INTF0_RX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net aurora_64b66b_0_TX_LANE0 [get_bd_intf_pins aurora_64b66b_0/TX_LANE0] [get_bd_intf_pins gtwiz_versal_0/INTF0_TX0_GT_IP_Interface]
  if {$gttype eq "GTM"} {
  connect_bd_intf_net -intf_net aurora_64b66b_0_diff_gt_ref_clock_1 [get_bd_intf_ports aurora_64b66b_0_diff_gt_ref_clock] [get_bd_intf_pins util_ds_buf/CLK_IN_D1]
  } else {
  connect_bd_intf_net -intf_net aurora_64b66b_0_diff_gt_ref_clock_1 [get_bd_intf_ports aurora_64b66b_0_diff_gt_ref_clock] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  }
  connect_bd_intf_net -intf_net gtwiz_versal_0_Quad0_GT_Serial [get_bd_intf_ports Quad0_GT_Serial_0] [get_bd_intf_pins gtwiz_versal_0/Quad0_GT_Serial]

  # Create port connections
  connect_bd_net -net aurora_64b66b_0_link_reset_out  [get_bd_pins aurora_64b66b_0/link_reset_out] \
  [get_bd_pins axis_vio_0/probe_in6] [get_bd_pins gtwiz_versal_0/INTF0_rst_all_in]
  connect_bd_net -net aurora_64b66b_0_reset2fg  [get_bd_pins aurora_64b66b_0/reset2fg] \
  [get_bd_pins axis_vio_0/probe_in11]
  connect_bd_net -net aurora_64b66b_0_rx_channel_up  [get_bd_pins aurora_64b66b_0/rx_channel_up] \
  [get_bd_pins axis_vio_0/probe_in1]
  connect_bd_net -net aurora_64b66b_0_rx_hard_err  [get_bd_pins aurora_64b66b_0/rx_hard_err] \
  [get_bd_pins axis_vio_0/probe_in3]
  connect_bd_net -net aurora_64b66b_0_rx_lane_up  [get_bd_pins aurora_64b66b_0/rx_lane_up] \
  [get_bd_pins axis_vio_0/probe_in4]
  connect_bd_net -net aurora_64b66b_0_rx_soft_err  [get_bd_pins aurora_64b66b_0/rx_soft_err] \
  [get_bd_pins axis_vio_0/probe_in5]
  connect_bd_net -net aurora_64b66b_0_rx_sys_reset_out  [get_bd_pins aurora_64b66b_0/rx_sys_reset_out] \
  [get_bd_pins axis_vio_0/probe_in10]
  connect_bd_net -net aurora_64b66b_0_tx_channel_up  [get_bd_pins aurora_64b66b_0/tx_channel_up] \
  [get_bd_pins axis_vio_0/probe_in7]
  connect_bd_net -net aurora_64b66b_0_tx_lane_up  [get_bd_pins aurora_64b66b_0/tx_lane_up] \
  [get_bd_pins axis_vio_0/probe_in8]
  connect_bd_net -net aurora_64b66b_0_tx_sys_reset_out  [get_bd_pins aurora_64b66b_0/tx_sys_reset_out] \
  [get_bd_pins axis_vio_0/probe_in9]
  connect_bd_net -net ch_loopback  [get_bd_pins axis_vio_0/probe_out1] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch0_loopback] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch1_loopback] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch2_loopback] \
  [get_bd_pins gtwiz_versal_0/QUAD0_ch3_loopback]
  connect_bd_net -net bufg_gt_1_usrclk  [get_bd_pins bufg_gt_1/usrclk] \
  [get_bd_pins aurora_64b66b_0/rxusrclk_in] \
  [get_bd_pins gtwiz_versal_0/QUAD0_RX0_usrclk]
  connect_bd_net -net bufg_gt_usrclk  [get_bd_pins bufg_gt/usrclk] \
  [get_bd_pins aurora_64b66b_0/user_clk] \
  [get_bd_pins versal_cips_0/hsdp_ref_clk] \
  [get_bd_pins gtwiz_versal_0/QUAD0_TX0_usrclk]
  #connect_bd_net -net clk_wizard_0_clk_out1  [get_bd_pins util_ds_buf_0/BUFG_O]   [get_bd_pins aurora_64b66b_0/init_clk]   [get_bd_pins axi_dbg_hub_0/aclk]   [get_bd_pins axis_vio_0/clk]   [get_bd_pins proc_sys_reset_0/slowest_sync_clk]   [get_bd_pins versal_cips_0/m_axi_fpd_aclk]   [get_bd_pins gtwiz_versal_0/gtwiz_freerun_clk]
  #connect_bd_net -net gtwiz_versal_0_INTF0_RX0_ch_rxbyteisaligned  [get_bd_pins gtwiz_versal_0/INTF0_RX0_ch_rxbyteisaligned]  [get_bd_pins axis_vio_0/probe_in2]
  connect_bd_net -net gtwiz_versal_0_resetfc  [get_bd_pins aurora_64b66b_0/reset2fc]  [get_bd_pins axis_vio_0/probe_in2]
  connect_bd_net -net gtwiz_versal_0_INTF0_rst_rx_done_out  [get_bd_pins gtwiz_versal_0/INTF0_rst_rx_done_out] \
  [get_bd_pins aurora_64b66b_0/rx_reset_done]
  connect_bd_net -net gtwiz_versal_0_INTF0_rst_tx_done_out  [get_bd_pins gtwiz_versal_0/INTF0_rst_tx_done_out] \
  [get_bd_pins aurora_64b66b_0/tx_reset_done]
  connect_bd_net -net gtwiz_versal_0_QUAD0_RX0_outclk  [get_bd_pins gtwiz_versal_0/QUAD0_RX0_outclk] \
  [get_bd_pins bufg_gt_1/outclk]
  connect_bd_net -net gtwiz_versal_0_QUAD0_TX0_outclk  [get_bd_pins gtwiz_versal_0/QUAD0_TX0_outclk] \
  [get_bd_pins bufg_gt/outclk]
  connect_bd_net -net gtwiz_versal_0_gtpowergood  [get_bd_pins gtwiz_versal_0/gtpowergood] \
  [get_bd_pins aurora_64b66b_0/gt_powergood_in]
  connect_bd_net -net pma_init_1  [get_bd_pins axis_vio_0/probe_out0] \
  [get_bd_pins aurora_64b66b_0/pma_init] \
  [get_bd_pins axis_vio_0/probe_in0]
  connect_bd_net -net proc_sys_reset_0_mb_reset  [get_bd_pins proc_sys_reset_0/mb_reset] \
  [get_bd_pins axis_vio_0/probe_in12]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins axi_dbg_hub_0/aresetn]
  connect_bd_net -net tx_rx_reset  [get_bd_pins axis_vio_0/probe_out2] \
  [get_bd_pins aurora_64b66b_0/rx_reset_pb] \
  [get_bd_pins aurora_64b66b_0/tx_reset_pb]
  if {$gttype eq "GTM"} {
  connect_bd_net -net util_ds_buf_IBUF_OUT  [get_bd_pins util_ds_buf/IBUFDS_GTME5_O] [get_bd_pins gtwiz_versal_0/QUAD0_GTREFCLK0]
  } else {
  connect_bd_net -net util_ds_buf_IBUF_OUT  [get_bd_pins util_ds_buf/IBUF_OUT] [get_bd_pins gtwiz_versal_0/QUAD0_GTREFCLK0]
  }
  connect_bd_net -net versal_cips_0_pl0_ref_clk  [get_bd_pins versal_cips_0/pl0_ref_clk] \
  [get_bd_pins util_ds_buf_0/BUFG_I]
  connect_bd_net -net versal_cips_0_pl0_resetn  [get_bd_pins versal_cips_0/pl0_resetn] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in]

  # Create address segments
  #assign_bd_address -offset 0xA4000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force
  assign_bd_address


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
    set gttype [lindex [split $quad "_"] 0]
    puts $f "quad_loc: $quad_loc , $refclk"
    set inst "${design_name}_i/gtwiz_versal_0/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst"
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
    if {$gttype eq "GTM"} {
      set inst "${design_name}_i/util_ds_buf/U0/USE_IBUFDS_GTME5.GEN_IBUFDS_GTME5\[0\].IBUFDS_GTME5_U"
    } else {
      set inst "${design_name}_i/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5\[0\].IBUFDS_GTE5_I"
    }
    puts $outputfile "set_property LOC ${ref_coord} \[get_cells  $inst\]"
    puts $outputfile ""
    #puts $outputfile "############ FILL IN CLOCK CONSTRAINTS BELOW #################"
    #puts $outputfile "# set_property PACKAGE_PIN A1 \[get_ports pl_hsdp_clk_0\]"
    #puts $outputfile "# set_property IOSTANDARD DIFF_SSTL12 \[get_ports pl_hsdp_clk_0\]"
    #puts $outputfile "# create_clock -period 10.0 \[get_ports pl_hsdp_clk_0\]"
    
    puts $outputfile "\nset_property BITSTREAM.GENERAL.COMPRESS TRUE \[current_design\]"
    puts $outputfile "\nset_false_path -to \[get_pins {${design_name}_i\/axis_vio_0\/inst/probe_in_inst\/probe_in_reg_reg\[*\]/D}\]"
    puts $outputfile "\nset_false_path -from \[get_clocks clk_pl_0\] -to \[get_clocks ${design_name}_i\/gtwiz_versal_0\/inst\/intf_quad_map_inst\/quad_top_inst\/gt_quad_base_0_inst\/inst\/quad_inst\/CH0_TXOUTCLK\]"

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
  create_soft_design "" $design_name $options
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