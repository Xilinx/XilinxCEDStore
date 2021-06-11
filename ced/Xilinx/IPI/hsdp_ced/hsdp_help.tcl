

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
    set aurora_64b66b_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:aurora_64b66b:12.0 aurora_64b66b_0 ]
    set_property -dict [ list \
     CONFIG.C_LINE_RATE {10.0} \
     CONFIG.C_USE_BYTESWAP {true} \
     CONFIG.dataflow_config {TX/RX_Simplex} \
    ] $aurora_64b66b_0

    # Create instance: axi_dbg_hub_0, and set properties
    set axi_dbg_hub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dbg_hub:2.0 axi_dbg_hub_0 ]
    set_property -dict [ list \
     CONFIG.C_AXI_ADDR_WIDTH {44} \
     CONFIG.C_AXI_DATA_WIDTH {32} \
     CONFIG.C_AXI_ID_WIDTH {16} \
     CONFIG.C_NUM_DEBUG_CORES {0} \
    ] $axi_dbg_hub_0

    # Create instance: axis_vio_0, and set properties
    set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio:1.0 axis_vio_0 ]
    set_property -dict [ list \
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
    set_property -dict [ list \
      CONFIG.CHANNEL_ORDERING { \
       /aurora_64b66b_0/RX_LANE0 design_1_aurora_64b66b_0_0./gt_quad_base/RX0_GT_IP_Interface.0 \
       /aurora_64b66b_0/TX_LANE0 design_1_aurora_64b66b_0_0./gt_quad_base/TX0_GT_IP_Interface.0 \
      } \
      CONFIG.PORTS_INFO_DICT {LANE_SEL_DICT {PROT0 {RX0 RX1 RX2 RX3 TX0 TX1 TX2 TX3}} GT_TYPE GTY\
      REG_CONF_INTF APB3_INTF BOARD_PARAMETER { }}\
      CONFIG.PROT0_ENABLE {true} \
      CONFIG.PROT0_GT_DIRECTION {DUPLEX} \
      CONFIG.PROT0_LR0_SETTINGS { \
       GT_DIRECTION DUPLEX \
       INS_LOSS_NYQ 20 \
       INTERNAL_PRESET Aurora_64B66B \
       OOB_ENABLE false \
       PCIE_ENABLE false \
       PCIE_USERCLK2_FREQ 250 \
       PCIE_USERCLK_FREQ 250 \
       PRESET GTY-Aurora_64B66B \
       RESET_SEQUENCE_INTERVAL 0 \
       RXPROGDIV_FREQ_ENABLE false \
       RXPROGDIV_FREQ_SOURCE LCPLL \
       RXPROGDIV_FREQ_VAL 322.265625 \
       RX_64B66B_CRC false \
       RX_64B66B_DECODER false \
       RX_64B66B_DESCRAMBLER false \
       RX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 \
       RX_BUFFER_BYPASS_MODE Fast_Sync \
       RX_BUFFER_BYPASS_MODE_LANE MULTI \
       RX_BUFFER_MODE 1 \
       RX_BUFFER_RESET_ON_CB_CHANGE ENABLE \
       RX_BUFFER_RESET_ON_COMMAALIGN DISABLE \
       RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE \
       RX_CB_DISP 00000000 \
       RX_CB_DISP_0_0 false \
       RX_CB_DISP_0_1 false \
       RX_CB_DISP_0_2 false \
       RX_CB_DISP_0_3 false \
       RX_CB_DISP_1_0 false \
       RX_CB_DISP_1_1 false \
       RX_CB_DISP_1_2 false \
       RX_CB_DISP_1_3 false \
       RX_CB_K 00000000 \
       RX_CB_K_0_0 false \
       RX_CB_K_0_1 false \
       RX_CB_K_0_2 false \
       RX_CB_K_0_3 false \
       RX_CB_K_1_0 false \
       RX_CB_K_1_1 false \
       RX_CB_K_1_2 false \
       RX_CB_K_1_3 false \
       RX_CB_LEN_SEQ 1 \
       RX_CB_MASK 00000000 \
       RX_CB_MASK_0_0 false \
       RX_CB_MASK_0_1 false \
       RX_CB_MASK_0_2 false \
       RX_CB_MASK_0_3 false \
       RX_CB_MASK_1_0 false \
       RX_CB_MASK_1_1 false \
       RX_CB_MASK_1_2 false \
       RX_CB_MASK_1_3 false \
       RX_CB_MAX_LEVEL 1 \
       RX_CB_MAX_SKEW 1 \
       RX_CB_NUM_SEQ 0 \
       RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 \
       RX_CB_VAL_0_0 00000000 \
       RX_CB_VAL_0_1 00000000 \
       RX_CB_VAL_0_2 00000000 \
       RX_CB_VAL_0_3 00000000 \
       RX_CB_VAL_1_0 00000000 \
       RX_CB_VAL_1_1 00000000 \
       RX_CB_VAL_1_2 00000000 \
       RX_CB_VAL_1_3 00000000 \
       RX_CC_DISP 00000000 \
       RX_CC_DISP_0_0 false \
       RX_CC_DISP_0_1 false \
       RX_CC_DISP_0_2 false \
       RX_CC_DISP_0_3 false \
       RX_CC_DISP_1_0 false \
       RX_CC_DISP_1_1 false \
       RX_CC_DISP_1_2 false \
       RX_CC_DISP_1_3 false \
       RX_CC_K 00000000 \
       RX_CC_KEEP_IDLE DISABLE \
       RX_CC_K_0_0 false \
       RX_CC_K_0_1 false \
       RX_CC_K_0_2 false \
       RX_CC_K_0_3 false \
       RX_CC_K_1_0 false \
       RX_CC_K_1_1 false \
       RX_CC_K_1_2 false \
       RX_CC_K_1_3 false \
       RX_CC_LEN_SEQ 1 \
       RX_CC_MASK 00000000 \
       RX_CC_MASK_0_0 false \
       RX_CC_MASK_0_1 false \
       RX_CC_MASK_0_2 false \
       RX_CC_MASK_0_3 false \
       RX_CC_MASK_1_0 false \
       RX_CC_MASK_1_1 false \
       RX_CC_MASK_1_2 false \
       RX_CC_MASK_1_3 false \
       RX_CC_NUM_SEQ 0 \
       RX_CC_PERIODICITY 5000 \
       RX_CC_PRECEDENCE ENABLE \
       RX_CC_REPEAT_WAIT 0 \
       RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 \
       RX_CC_VAL_0_0 00000000 \
       RX_CC_VAL_0_1 00000000 \
       RX_CC_VAL_0_2 00000000 \
       RX_CC_VAL_0_3 00000000 \
       RX_CC_VAL_1_0 00000000 \
       RX_CC_VAL_1_1 00000000 \
       RX_CC_VAL_1_2 00000000 \
       RX_CC_VAL_1_3 00000000 \
       RX_COMMA_ALIGN_WORD 1 \
       RX_COMMA_DOUBLE_ENABLE false \
       RX_COMMA_MASK 0000000000 \
       RX_COMMA_M_ENABLE false \
       RX_COMMA_M_VAL 1010000011 \
       RX_COMMA_PRESET NONE \
       RX_COMMA_P_ENABLE false \
       RX_COMMA_P_VAL 0101111100 \
       RX_COMMA_SHOW_REALIGN_ENABLE true \
       RX_COMMA_VALID_ONLY 0 \
       RX_COUPLING AC \
       RX_DATA_DECODING 64B66B_SYNC \
       RX_EQ_MODE AUTO \
       RX_FRACN_ENABLED false \
       RX_FRACN_NUMERATOR 0 \
       RX_INT_DATA_WIDTH 64 \
       RX_JTOL_FC 5.9988002 \
       RX_JTOL_LF_SLOPE -20 \
       RX_LINE_RATE 10.0 \
       RX_OUTCLK_SOURCE RXOUTCLKPMA \
       RX_PLL_TYPE LCPLL \
       RX_PPM_OFFSET 0 \
       RX_RATE_GROUP A \
       RX_REFCLK_FREQUENCY 156.250 \
       RX_REFCLK_SOURCE R0 \
       RX_SLIDE_MODE OFF \
       RX_SSC_PPM 0 \
       RX_TERMINATION PROGRAMMABLE \
       RX_TERMINATION_PROG_VALUE 800 \
       RX_USER_DATA_WIDTH 64 \
       TXPROGDIV_FREQ_ENABLE false \
       TXPROGDIV_FREQ_SOURCE LCPLL \
       TXPROGDIV_FREQ_VAL 322.265625 \
       TX_64B66B_CRC false \
       TX_64B66B_ENCODER false \
       TX_64B66B_SCRAMBLER false \
       TX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 \
       TX_BUFFER_BYPASS_MODE Fast_Sync \
       TX_BUFFER_MODE 1 \
       TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE \
       TX_DATA_ENCODING 64B66B_SYNC \
       TX_DIFF_SWING_EMPH_MODE CUSTOM \
       TX_FRACN_ENABLED false \
       TX_FRACN_NUMERATOR 0 \
       TX_INT_DATA_WIDTH 64 \
       TX_LINE_RATE 10.0 \
       TX_OUTCLK_SOURCE TXOUTCLKPMA \
       TX_PIPM_ENABLE false \
       TX_PLL_TYPE LCPLL \
       TX_RATE_GROUP A \
       TX_REFCLK_FREQUENCY 156.250 \
       TX_REFCLK_SOURCE R0 \
       TX_USER_DATA_WIDTH 64 \
      } \
     CONFIG.PROT0_LR10_SETTINGS { } \
     CONFIG.PROT0_LR11_SETTINGS { } \
     CONFIG.PROT0_LR12_SETTINGS { } \
     CONFIG.PROT0_LR13_SETTINGS { } \
     CONFIG.PROT0_LR14_SETTINGS { } \
     CONFIG.PROT0_LR15_SETTINGS { } \
     CONFIG.PROT0_LR1_SETTINGS { } \
     CONFIG.PROT0_LR2_SETTINGS { } \
     CONFIG.PROT0_LR3_SETTINGS { } \
     CONFIG.PROT0_LR4_SETTINGS { } \
     CONFIG.PROT0_LR5_SETTINGS { } \
     CONFIG.PROT0_LR6_SETTINGS { } \
     CONFIG.PROT0_LR7_SETTINGS { } \
     CONFIG.PROT0_LR8_SETTINGS { } \
     CONFIG.PROT0_LR9_SETTINGS { } \
     CONFIG.PROT0_NO_OF_LANES {1} \
     CONFIG.PROT0_RX_MASTERCLK_SRC {RX0} \
     CONFIG.PROT0_TX_MASTERCLK_SRC {TX0} \
     CONFIG.PROT1_LR0_SETTINGS { } \
     CONFIG.PROT1_LR10_SETTINGS { } \
     CONFIG.PROT1_LR11_SETTINGS { } \
     CONFIG.PROT1_LR12_SETTINGS { } \
     CONFIG.PROT1_LR13_SETTINGS { } \
     CONFIG.PROT1_LR14_SETTINGS { } \
     CONFIG.PROT1_LR15_SETTINGS { } \
     CONFIG.PROT1_LR1_SETTINGS { } \
     CONFIG.PROT1_LR2_SETTINGS { } \
     CONFIG.PROT1_LR3_SETTINGS { } \
     CONFIG.PROT1_LR4_SETTINGS { } \
     CONFIG.PROT1_LR5_SETTINGS { } \
     CONFIG.PROT1_LR6_SETTINGS { } \
     CONFIG.PROT1_LR7_SETTINGS { } \
     CONFIG.PROT1_LR8_SETTINGS { } \
     CONFIG.PROT1_LR9_SETTINGS { } \
     CONFIG.PROT1_RX_MASTERCLK_SRC {None} \
     CONFIG.PROT1_TX_MASTERCLK_SRC {None} \
     CONFIG.PROT2_LR0_SETTINGS { } \
     CONFIG.PROT2_LR10_SETTINGS { } \
     CONFIG.PROT2_LR11_SETTINGS { } \
     CONFIG.PROT2_LR12_SETTINGS { } \
     CONFIG.PROT2_LR13_SETTINGS { } \
     CONFIG.PROT2_LR14_SETTINGS { } \
     CONFIG.PROT2_LR15_SETTINGS { } \
     CONFIG.PROT2_LR1_SETTINGS { } \
     CONFIG.PROT2_LR2_SETTINGS { } \
     CONFIG.PROT2_LR3_SETTINGS { } \
     CONFIG.PROT2_LR4_SETTINGS { } \
     CONFIG.PROT2_LR5_SETTINGS { } \
     CONFIG.PROT2_LR6_SETTINGS { } \
     CONFIG.PROT2_LR7_SETTINGS { } \
     CONFIG.PROT2_LR8_SETTINGS { } \
     CONFIG.PROT2_LR9_SETTINGS { } \
     CONFIG.PROT2_RX_MASTERCLK_SRC {None} \
     CONFIG.PROT2_TX_MASTERCLK_SRC {None} \
     CONFIG.PROT3_LR0_SETTINGS { } \
     CONFIG.PROT3_LR10_SETTINGS { } \
     CONFIG.PROT3_LR11_SETTINGS { } \
     CONFIG.PROT3_LR12_SETTINGS { } \
     CONFIG.PROT3_LR13_SETTINGS { } \
     CONFIG.PROT3_LR14_SETTINGS { } \
     CONFIG.PROT3_LR15_SETTINGS { } \
     CONFIG.PROT3_LR1_SETTINGS { } \
     CONFIG.PROT3_LR2_SETTINGS { } \
     CONFIG.PROT3_LR3_SETTINGS { } \
     CONFIG.PROT3_LR4_SETTINGS { } \
     CONFIG.PROT3_LR5_SETTINGS { } \
     CONFIG.PROT3_LR6_SETTINGS { } \
     CONFIG.PROT3_LR7_SETTINGS { } \
     CONFIG.PROT3_LR8_SETTINGS { } \
     CONFIG.PROT3_LR9_SETTINGS { } \
     CONFIG.PROT3_RX_MASTERCLK_SRC {None} \
     CONFIG.PROT3_TX_MASTERCLK_SRC {None} \
     CONFIG.PROT4_LR0_SETTINGS { } \
     CONFIG.PROT4_LR10_SETTINGS { } \
     CONFIG.PROT4_LR11_SETTINGS { } \
     CONFIG.PROT4_LR12_SETTINGS { } \
     CONFIG.PROT4_LR13_SETTINGS { } \
     CONFIG.PROT4_LR14_SETTINGS { } \
     CONFIG.PROT4_LR15_SETTINGS { } \
     CONFIG.PROT4_LR1_SETTINGS { } \
     CONFIG.PROT4_LR2_SETTINGS { } \
     CONFIG.PROT4_LR3_SETTINGS { } \
     CONFIG.PROT4_LR4_SETTINGS { } \
     CONFIG.PROT4_LR5_SETTINGS { } \
     CONFIG.PROT4_LR6_SETTINGS { } \
     CONFIG.PROT4_LR7_SETTINGS { } \
     CONFIG.PROT4_LR8_SETTINGS { } \
     CONFIG.PROT4_LR9_SETTINGS { } \
     CONFIG.PROT4_RX_MASTERCLK_SRC {None} \
     CONFIG.PROT4_TX_MASTERCLK_SRC {None} \
     CONFIG.PROT5_LR0_SETTINGS { } \
     CONFIG.PROT5_LR10_SETTINGS { } \
     CONFIG.PROT5_LR11_SETTINGS { } \
     CONFIG.PROT5_LR12_SETTINGS { } \
     CONFIG.PROT5_LR13_SETTINGS { } \
     CONFIG.PROT5_LR14_SETTINGS { } \
     CONFIG.PROT5_LR15_SETTINGS { } \
     CONFIG.PROT5_LR1_SETTINGS { } \
     CONFIG.PROT5_LR2_SETTINGS { } \
     CONFIG.PROT5_LR3_SETTINGS { } \
     CONFIG.PROT5_LR4_SETTINGS { } \
     CONFIG.PROT5_LR5_SETTINGS { } \
     CONFIG.PROT5_LR6_SETTINGS { } \
     CONFIG.PROT5_LR7_SETTINGS { } \
     CONFIG.PROT5_LR8_SETTINGS { } \
     CONFIG.PROT5_LR9_SETTINGS { } \
     CONFIG.PROT5_RX_MASTERCLK_SRC {None} \
     CONFIG.PROT5_TX_MASTERCLK_SRC {None} \
     CONFIG.PROT6_LR0_SETTINGS { } \
     CONFIG.PROT6_LR10_SETTINGS { } \
     CONFIG.PROT6_LR11_SETTINGS { } \
     CONFIG.PROT6_LR12_SETTINGS { } \
     CONFIG.PROT6_LR13_SETTINGS { } \
     CONFIG.PROT6_LR14_SETTINGS { } \
     CONFIG.PROT6_LR15_SETTINGS { } \
     CONFIG.PROT6_LR1_SETTINGS { } \
     CONFIG.PROT6_LR2_SETTINGS { } \
     CONFIG.PROT6_LR3_SETTINGS { } \
     CONFIG.PROT6_LR4_SETTINGS { } \
     CONFIG.PROT6_LR5_SETTINGS { } \
     CONFIG.PROT6_LR6_SETTINGS { } \
     CONFIG.PROT6_LR7_SETTINGS { } \
     CONFIG.PROT6_LR8_SETTINGS { } \
     CONFIG.PROT6_LR9_SETTINGS { } \
     CONFIG.PROT6_RX_MASTERCLK_SRC {None} \
     CONFIG.PROT6_TX_MASTERCLK_SRC {None} \
     CONFIG.PROT7_LR0_SETTINGS { } \
     CONFIG.PROT7_LR10_SETTINGS { } \
     CONFIG.PROT7_LR11_SETTINGS { } \
     CONFIG.PROT7_LR12_SETTINGS { } \
     CONFIG.PROT7_LR13_SETTINGS { } \
     CONFIG.PROT7_LR14_SETTINGS { } \
     CONFIG.PROT7_LR15_SETTINGS { } \
     CONFIG.PROT7_LR1_SETTINGS { } \
     CONFIG.PROT7_LR2_SETTINGS { } \
     CONFIG.PROT7_LR3_SETTINGS { } \
     CONFIG.PROT7_LR4_SETTINGS { } \
     CONFIG.PROT7_LR5_SETTINGS { } \
     CONFIG.PROT7_LR6_SETTINGS { } \
     CONFIG.PROT7_LR7_SETTINGS { } \
     CONFIG.PROT7_LR8_SETTINGS { } \
     CONFIG.PROT7_LR9_SETTINGS { } \
     CONFIG.PROT7_RX_MASTERCLK_SRC {None} \
     CONFIG.PROT7_TX_MASTERCLK_SRC {None} \
     CONFIG.PROT_OUTCLK_VALUES { \
       CH0_RXOUTCLK 156.25 \
       CH0_TXOUTCLK 156.25 \
       CH1_RXOUTCLK 390.625 \
       CH1_TXOUTCLK 390.625 \
       CH2_RXOUTCLK 390.625 \
       CH2_TXOUTCLK 390.625 \
       CH3_RXOUTCLK 390.625 \
       CH3_TXOUTCLK 390.625 \
     } \
     CONFIG.QUAD_USAGE {TX_QUAD_CH {TXQuad_0_/gt_quad_base {/gt_quad_base design_1_aurora_64b66b_0_0.IP_CH0,undef,undef,undef MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/gt_quad_base {/gt_quad_base design_1_aurora_64b66b_0_0.IP_CH0,undef,undef,undef MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1}}} \
     CONFIG.REFCLK_STRING { \
       HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_156.250000_MHz_unique1 \
     } \
     CONFIG.RX0_LANE_SEL {PROT0} \
     CONFIG.RX1_LANE_SEL {unconnected} \
     CONFIG.RX2_LANE_SEL {unconnected} \
     CONFIG.RX3_LANE_SEL {unconnected} \
     CONFIG.TX0_LANE_SEL {PROT0} \
     CONFIG.TX1_LANE_SEL {unconnected} \
     CONFIG.TX2_LANE_SEL {unconnected} \
     CONFIG.TX3_LANE_SEL {unconnected} \
    ] $gt_quad_base

    # Create instance: proc_sys_reset_0, and set properties
    set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

    # Create instance: proc_sys_reset_1, and set properties
    set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

    # Create instance: util_ds_buf, and set properties
    set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf ]
    set_property -dict [ list \
     CONFIG.C_BUF_TYPE {IBUFDSGTE} \
    ] $util_ds_buf

    # Create instance: util_ds_buf_0, and set properties
    set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0 ]
    set_property -dict [ list \
     CONFIG.C_BUF_TYPE {BUFG} \
    ] $util_ds_buf_0

    # Create instance: versal_cips_0, and set properties
    set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
    set_property -dict [list \
     CONFIG.CPM_CONFIG [dict create \
        CPM_PCIE0_ARI_CAP_ENABLED {0} \
        CPM_PCIE0_MODE0_FOR_POWER {NONE} \
        CPM_PCIE0_PF0_MSIX_CAP_TABLE_SIZE {001} \
        CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE {001} \
        CPM_PCIE0_PF2_MSIX_CAP_TABLE_SIZE {001} \
        CPM_PCIE0_PF3_MSIX_CAP_TABLE_SIZE {001} \
        CPM_PCIE1_ARI_CAP_ENABLED {0} \
        CPM_PCIE1_MODE1_FOR_POWER {NONE} \
        PS_HSDP_EGRESS_TRAFFIC {PL} \
        PS_HSDP_INGRESS_TRAFFIC {PL} \
      ] \
     CONFIG.PS_PMC_CONFIG [dict create \
        PMC_CRP_DFT_OSC_REF_CTRL_ACT_FREQMHZ {400} \
        PMC_CRP_EFUSE_REF_CTRL_ACT_FREQMHZ {100.000000} \
        PMC_CRP_EFUSE_REF_CTRL_FREQMHZ {100.000000} \
        PMC_CRP_NOC_REF_CTRL_ACT_FREQMHZ {949.990479} \
        PMC_CRP_NOC_REF_CTRL_FREQMHZ {950} \
        PMC_CRP_NPLL_CTRL_FBDIV {114} \
        PMC_CRP_PL0_REF_CTRL_ACT_FREQMHZ {149.998505} \
        PMC_CRP_PL0_REF_CTRL_DIVISOR0 {8} \
        PMC_CRP_PL0_REF_CTRL_FREQMHZ {156.25} \
        PMC_CRP_PL0_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_PL5_REF_CTRL_FREQMHZ {400} \
        PMC_CRP_SWITCH_TIMEOUT_CTRL_DIVISOR0 {100} \
        PMC_CRP_TEST_PATTERN_REF_CTRL_ACT_FREQMHZ {200} \
        PMC_CRP_USB_SUSPEND_CTRL_DIVISOR0 {500} \
        PMC_MIO37 {{DIRECTION out} {OUTPUT_DATA high} {PULL pulldown} {USAGE GPIO}} \
        PMC_MIO43 {{DIRECTION out} {SCHMITT 1}} \
        PMC_MIO_TREE_PERIPHERALS { #####################################GPIO 1#####UART 0#UART 0################################## } \
        PMC_MIO_TREE_SIGNALS {#####################################gpio_1_pin[37]#####rxd#txd##################################} \
        PS_CRL_CAN0_REF_CTRL_FREQMHZ {100} \
        PS_CRL_CAN0_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_CAN1_REF_CTRL_FREQMHZ {100} \
        PS_CRL_CAN1_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ {474.995239} \
        PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {475} \
        PS_CRL_CPM_TOPSW_REF_CTRL_SRCSEL {NPLL} \
        PS_CRL_IOU_SWITCH_CTRL_ACT_FREQMHZ {239.997604} \
        PS_CRL_IOU_SWITCH_CTRL_DIVISOR0 {5} \
        PS_CRL_IOU_SWITCH_CTRL_SRCSEL {PPLL} \
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
      ] \
    ] $versal_cips_0
    set_property -dict [list \
     CONFIG.PS_PMC_CONFIG [dict create PMC_MIO37 {{OUTPUT_DATA high} {DIRECTION out} {USAGE GPIO}} ] \
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
    connect_bd_net -net bufg_gt_1_usrclk [get_bd_pins aurora_64b66b_0/rxusrclk_in] [get_bd_pins bufg_gt_1/usrclk] [get_bd_pins gt_quad_base/ch0_rxusrclk] [get_bd_pins gt_quad_base/ch1_rxusrclk] [get_bd_pins gt_quad_base/ch2_rxusrclk] [get_bd_pins gt_quad_base/ch3_rxusrclk]
    connect_bd_net -net bufg_gt_usrclk [get_bd_pins aurora_64b66b_0/user_clk] [get_bd_pins bufg_gt/usrclk] [get_bd_pins gt_quad_base/ch0_txusrclk] [get_bd_pins gt_quad_base/ch1_txusrclk] [get_bd_pins gt_quad_base/ch2_txusrclk] [get_bd_pins gt_quad_base/ch3_txusrclk] [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins versal_cips_0/hsdp_ref_clk]
    connect_bd_net -net clk_wizard_0_clk_out1 [get_bd_pins aurora_64b66b_0/init_clk] [get_bd_pins axi_dbg_hub_0/aclk] [get_bd_pins axis_vio_0/clk] [get_bd_pins gt_quad_base/altclk] [get_bd_pins gt_quad_base/apb3clk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins util_ds_buf_0/BUFG_O] [get_bd_pins versal_cips_0/m_axi_lpd_aclk]
    connect_bd_net -net gt_quad_base_ch0_rxbyteisaligned [get_bd_pins axis_vio_0/probe_in2] [get_bd_pins gt_quad_base/ch0_rxbyteisaligned]
    connect_bd_net -net gt_quad_base_ch0_rxoutclk [get_bd_pins bufg_gt_1/outclk] [get_bd_pins gt_quad_base/ch0_rxoutclk]
    connect_bd_net -net gt_quad_base_ch0_txoutclk [get_bd_pins bufg_gt/outclk] [get_bd_pins gt_quad_base/ch0_txoutclk]
    connect_bd_net -net gt_quad_base_gtpowergood [get_bd_pins aurora_64b66b_0/gt_powergood_in] [get_bd_pins gt_quad_base/gtpowergood]
    connect_bd_net -net hsclk0_lcplllock [get_bd_pins axis_vio_0/probe_in3] [get_bd_pins gt_quad_base/hsclk0_lcplllock]
    connect_bd_net -net loopback [get_bd_pins axis_vio_0/probe_out1] [get_bd_pins gt_quad_base/ch0_loopback] [get_bd_pins gt_quad_base/ch1_loopback] [get_bd_pins gt_quad_base/ch2_loopback] [get_bd_pins gt_quad_base/ch3_loopback]
    connect_bd_net -net pma_init_1 [get_bd_pins aurora_64b66b_0/pma_init] [get_bd_pins axis_vio_0/probe_in0] [get_bd_pins axis_vio_0/probe_out0]
    connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins axis_vio_0/probe_in13] [get_bd_pins proc_sys_reset_0/mb_reset]
    connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dbg_hub_0/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
    connect_bd_net -net tx_rx_reset [get_bd_pins aurora_64b66b_0/rx_reset_pb] [get_bd_pins aurora_64b66b_0/tx_reset_pb] [get_bd_pins axis_vio_0/probe_out2]
    connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins gt_quad_base/GT_REFCLK0] [get_bd_pins util_ds_buf/IBUF_OUT]
    connect_bd_net -net versal_cips_0_pl_clk0 [get_bd_pins util_ds_buf_0/BUFG_I] [get_bd_pins versal_cips_0/pl0_ref_clk]
    connect_bd_net -net versal_cips_0_pl_resetn0 [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins proc_sys_reset_1/ext_reset_in] [get_bd_pins versal_cips_0/pl0_resetn]

    # Create address segments
    assign_bd_address -offset 0x80000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces versal_cips_0/Data1] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force


    puts $f "done!"
    close $f

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
    
    puts $outputfile "set_property LOC GTY_QUAD_${quad_loc} \[get_cells $inst\]"
    puts $outputfile "create_clock -period ${period} \[get_pins -hierarchical -regexp ${inst}/CH0_TXOUTCLK\]"
    puts $outputfile "create_clock -period ${period} \[get_pins -hierarchical -regexp ${inst}/CH0_RXOUTCLK\]"
    set inst "${design_name}_i/util_ds_buf/U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5\[0\].IBUFDS_GTE5_I"
    puts $outputfile "set_property LOC GTY_REFCLK_${ref_coord} \[get_cells  $inst\]"
    puts $outputfile ""
    #puts $outputfile "############ FILL IN CLOCK CONSTRAINTS BELOW #################"
    #puts $outputfile "# set_property PACKAGE_PIN A1 \[get_ports pl_hsdp_clk_0\]"
    #puts $outputfile "# set_property IOSTANDARD DIFF_SSTL12 \[get_ports pl_hsdp_clk_0\]"
    #puts $outputfile "# create_clock -period 10.0 \[get_ports pl_hsdp_clk_0\]"
    
    puts $outputfile "\nset_property BITSTREAM.GENERAL.COMPRESS TRUE \[current_design\]"
    puts $outputfile "\nset_false_path -to \[get_pins {versal_hdsp_i\/axis_vio_0\/inst/probe_in_inst\/probe_in_reg_reg\[*\]/D}\]"
    puts $outputfile "\nset_false_path -from \[get_clocks clk_pl_0\] -to \[get_clocks versal_hdsp_i\/gt_quad_base\/inst\/quad_inst\/CH0_TXOUTCLK\]"

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


