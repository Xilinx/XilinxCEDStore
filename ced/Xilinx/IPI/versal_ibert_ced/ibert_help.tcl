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

proc get_GTY_width {linerate} {
    return 80
  }

proc get_GTM_width {linerate} {
  if {$linerate > 57.0} {
    return 320
  } else {
    return 160
  }
}

proc get_GTYP_width {linerate} {
  return 80
}

proc get_max_refclk_rate {speedgrade type} {
  return 820.0
}

proc get_max_refclk_sharing_linerate {type} {
  switch $type {
    GTY -
    GTYP {
      return 32.75
    }
    GTM {
      return 58.0
    }
  }
}

proc get_max_linerate {speedgrade type} {
  switch $type {
    GTY {
      switch $speedgrade {
        -3HP { 
          return 32.75
        }
        -2MP -
        -2MHP -
        -2HP -
        -2LP -
        -2LHP {
          return 28.21
        }
        -1MM -
        -1MP {
          return 26.5625
        }
        -1LP -
        -1LHP {
          return 25.78125
        }
        default {
          return 25.78125
        }
      }
    }
    GTYP {
      switch $speedgrade {
        -3HP -
        -2HP { 
          return 32.75
        }
        -2MP -
        -2MHP -
        -2LP -
        -2LHP {
          return 32.0
        }
        -1MM -
        -1MP {
          return 26.5625
        }
        -1LP -
        -1LHP {
          return 25.78125
        }
        default {
          return 25.78125
        }
      }
    }
    GTM {
      switch $speedgrade {
        -3HP {
          return 112.0
        }
        -2LP -
        -2LHP -
        -2MP -
        -2MHP {
          return 112.0
        }
        -1MM - 
        -1LP -
        -1MP -
        -1LHP {
          return 53.125
        }
        default {
          return 53.125
        }
      }
    }
  }
}

proc get_min_linerate {speedgrade type} {
  return 1.25
}

proc get_all_quads {pkg} {
  return [concat [get_left $pkg] [get_right $pkg]]
}


proc replace {st foo bar} {
  regsub -all $foo $st $bar st
  return $st
}

proc get_quad_type {quad} {
  set toks [split $quad "_"]
  return [lindex $toks 0]
}

proc get_default_lr {quad} {
  set type [get_quad_type $quad]
  if {$type eq "GTM"} {
    return 53.125
  } else {
    return 10.3125
  }
}

proc get_pam_sel {lr} {
  if {$lr < 19.0} {
    return "NRZ"
  } else {
    return "PAM4"
  }
}

proc get_default_rr {quad} {
  return 156.25
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

proc filter_by_type {quads type} {
  set r [list]
  foreach q $quads {
    if {$type eq [get_quad_type $q]} {
      lappend r $q
    }
  }
  return $r
}

proc get_GTM_width {linerate} {
    if {$linerate > 57.0} {
      return 320
    } else {
      return 160
    }
  }
  
proc get_GTYP_width {linerate} {
  return 80
}
  
proc get_GTY_width {linerate} {
    return 80
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

proc findProtocol {name protocols} {
  log "finding $name ..."
  for {set i 0} {$i < [dict size $protocols]} {incr i} {
    set n [dict get $protocols $i name]
    if {$n eq $name} {
      log "found! $i"
      return $i
    }
  }
  log "miss $name $protocols"
  return -1
}

#
# Translate the options list from CED to a protocols dict like the GTWiz example generator
#
proc options2protocols {options} {
  variable logStuff
  set idx 0
  set systemTime [clock seconds]
  log "options2protocols: [clock format $systemTime -format %H:%M:%S]"
  log $options
  set protocols [dict create]
  set part [get_property PART [current_project]]
  set pkg [lindex [split $part -] 1]  
  set speedgrade [lindex [split $part -] 2] 

  log "part/pkg: $part $pkg"
  foreach q [get_all_quads $pkg] {
    if {[dictDefault $options ${q}_en.VALUE false] == "true"} {
      log "  quad: $q"
      set line_rate [dictDefault $options ${q}_lr.VALUE [get_default_lr $q]]
      log "  linerate: $line_rate"
      
      set ref_freq [dictDefault $options ${q}_rr.VALUE [get_default_rr $q]]
      log "  ref_freq: $ref_freq"
      set default_loc [lindex [get_reflocs $q] 0]
      log "  default_loc: $q $default_loc"
      set ref_loc [dictDefault $options ${q}_ref.VALUE $default_loc]
      log "  ref_loc: $ref_loc"
      
      # Find XY coordinate if refloc comes from other quad, and set refclk frequency
      if {[regexp {X\d+Y\d+} $ref_loc] == 0} {
        set my_q $ref_loc
        set ref_loc [dictDefault $options ${my_q}_ref.VALUE [lindex [get_reflocs $my_q] 0]]
        set ref_freq [dictDefault $options ${my_q}_rr.VALUE [get_default_rr $my_q]]
        log "  located $ref_loc from $my_q"
      }
      
      set found [findProtocol refclk$ref_loc $protocols]
      #
      # name of each protocol is the refclk source.  If that protocol doesn't exist in the 
      # dict, create it
      #
      if {$found == -1} {
        log "  new protocol: refclk$ref_loc"
        dict set protocols $idx name "refclk$ref_loc"
        dict set protocols $idx line_rate $line_rate 
        dict set protocols $idx ref_freq $ref_freq
        dict set protocols $idx ref_loc $ref_loc
        dict set protocols $idx num_quads 1
        dict set protocols $idx quad0 [get_gtloc $q]
        incr idx 
      } else {
        # otherwise add to the existing protocol
        log "  adding to $ref_loc: found = $found"
        set num [dict get $protocols $found num_quads]
        dict set protocols $found num_quads [expr $num+1]
        dict set protocols $found quad${num} [get_gtloc $q]
        log "  added q$num to $ref_loc"
      }
    }
  }
  
  pdict $protocols * stdout
  return $protocols
}


proc createDesign {design_name options} {
  
  proc create_root_design { parentCell design_name protocols} {
    variable logStuff
    if {$logStuff} {
      set f [open "create_design_bd.tcl" w]
      puts $f "# in create_root_design"
      puts $f "# options: $protocols"
    }

    set part [get_property PART [current_project]]
    set device [lindex [split $part -] 0]
    set pkg [lindex [split $part -] 1]  

    if {$device eq "xcvp1902" || $device eq "xcvm2152" || $device eq "xcvr1602" || $device eq "xcvr1652" || $device eq "xc10S70"} {
      create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:1.0 versal_cips_0
      set_property -dict [list \
        CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {125} \
        CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {0} \
        CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
      ] [get_bd_cells versal_cips_0]

      if {$logStuff} { 
        puts $f "# PS Wiz created" 
        puts $f "create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:1.0 versal_cips_0"
        puts $f "set_property -dict \[list CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {125} \\"
        puts $f "  CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {0} CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \] \[get_bd_cells versal_cips_0\]"
      }
    } elseif {$device eq "xc2ve3504" || $device eq "xc2ve3558" || $device eq "xc2ve3804" || $device eq "xc2ve3858" || $device eq "xc2vm3558" || $device eq "xc2vm3858" || $device eq "xc2vm3358" || $device eq "xc2ve3304" || $device eq "xc2ve3358" } {
      create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:1.0 versal_cips_0
      set_property -dict [list \
        CONFIG.PS11_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {125} \
        CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {0} \
        CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} \
      ] [get_bd_cells versal_cips_0]

      if {$logStuff} { 
        puts $f "# PS Wiz created" 
        puts $f "create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:1.0 versal_cips_0"
        puts $f "set_property -dict \[list CONFIG.PS11_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {125} \\"
        puts $f "  CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {0} CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} \] \[get_bd_cells versal_cips_0\]"
      }
    } elseif {$device eq "xcvn3716"} {

      create_bd_cell -type ip -vlnv xilinx.com:ip:psx_wizard:1.0 versal_cips_0
      set_property -dict [list \
        CONFIG.PSX_PMCX_CONFIG(PMCX_CRP_PL0_REF_CTRL_FREQMHZ) {125} \
        CONFIG.PSX_PMCX_CONFIG(PSX_NUM_FABRIC_RESETS) {0} \
        CONFIG.PSX_PMCX_CONFIG(PSX_USE_PMCPL_CLK0) {1} \
      ] [get_bd_cells versal_cips_0]

      if {$logStuff} { 
        puts $f "# PSX created" 
        puts $f "create_bd_cell -type ip -vlnv xilinx.com:ip:psx_wizard:1.0 versal_cips_0"
        puts $f "set_property -dict \[list CONFIG.PSX_PMCX_CONFIG(PMCX_CRP_PL0_REF_CTRL_FREQMHZ) {125} \\"
        puts $f "  CONFIG.PSX_PMCX_CONFIG(PSX_NUM_FABRIC_RESETS) {0} CONFIG.PSX_PMCX_CONFIG(PSX_USE_PMCPL_CLK0) {1} \] \[get_bd_cells versal_cips_0\]"
      }
    } else {
    
      create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0
      
      # CIPS v3.0 with automation build 0529
      #apply_bd_automation -rule xilinx.com:bd_rule:cips -config { board_preset {No} boot_config {Custom} configure_noc {Add new AXI NoC} debug_config {Custom} design_flow {PL Flow (no PS)} mc_type {None} num_mc {1} pl_clocks {1} pl_resets {None}}  [get_bd_cells versal_cips_0]
      apply_bd_automation -rule xilinx.com:bd_rule:cips -config { board_preset {No} boot_config {Custom} configure_noc {Add new AXI NoC} debug_config {Custom} design_flow {PL Subsystem} mc_type {None} num_mc {1} pl_clocks {1} pl_resets {None}}  [get_bd_cells versal_cips_0]

      
      set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 125} CONFIG.CLOCK_MODE {Custom}] [get_bd_cells versal_cips_0]

      
      if {$logStuff} {
        puts $f "create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0"
        puts $f "apply_bd_automation -rule xilinx.com:bd_rule:cips -config { board_preset {No} boot_config {Custom} configure_noc {Add new AXI NoC} debug_config {Custom} design_flow {PL Only} mc_enable {No} mc_type {None} num_mc {1} pl_clocks {1} pl_resets {None}}  \[get_bd_cells versal_cips_0\]"
        puts $f "set_property -dict \[list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 125} CONFIG.CLOCK_MODE {Custom}] \[get_bd_cells versal_cips_0\]"
        # puts $f "set_property -dict \[list CONFIG.PMC_MIO_37_OUTPUT_DATA {high} CONFIG.PMC_MIO_37_DIRECTION {out} CONFIG.PMC_MIO_37_USAGE {GPIO}\] \[get_bd_cells versal_cips_0\]"
        flush $f
      
        puts $f "# CIPS created"
      }
    }

    
    
    for {set i 0} {$i < [dict size $protocols]} {incr i} {
      set name [dict get $protocols $i name]
      set lr [dict get $protocols $i line_rate]
      set num_lanes [expr [dict get $protocols $i num_quads] * 4]
      set num_quads [expr $num_lanes / 4]
      set ref_freq [dict get $protocols $i ref_freq]
      set type [get_quad_type [dict get $protocols $i quad0]]
      
      if {$logStuff} {
        puts $f "# type = $type, name = $name"
        puts $f "create_bd_cell -type ip -vlnv xilinx.com:ip:prbs_generator_checker bridge_$name"
        flush $f
      }
      create_bd_cell -type ip -vlnv xilinx.com:ip:prbs_generator_checker bridge_$name
      
      #source [::bd::get_vlnv_dir xilinx.com:ip:gtwiz_versal:1.0]/tcl/rtl_params.tcl
      #if {$logStuff} { puts $f "# got params.tcl" }
      if {$type eq "GTM"} {
	create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_$name
	set_property CONFIG.C_BUF_TYPE {IBUFDS_GTME5} [get_bd_cells util_ds_buf_$name]
	make_bd_intf_pins_external  [get_bd_intf_pins util_ds_buf_$name/CLK_IN_D1]
	set_property name gt_refclk_$name [get_bd_intf_ports CLK_IN_D1_0]
	create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant xlconstant_$name
	set_property CONFIG.CONST_VAL {0} [get_bd_cells xlconstant_$name]
	connect_bd_net [get_bd_pins xlconstant_$name/dout] [get_bd_pins util_ds_buf_$name/IBUFDS_GTME5_CEB]
        set pam_sel [get_pam_sel $lr]
        set width [get_${type}_width $lr]
        set user_settings_dict [dict create TX_LINE_RATE $lr TX_REFCLK_FREQUENCY $ref_freq RX_LINE_RATE $lr RX_REFCLK_FREQUENCY $ref_freq GT_TYPE GTM RX_PAM_SEL $pam_sel TX_PAM_SEL $pam_sel TX_USER_DATA_WIDTH $width RX_USER_DATA_WIDTH $width TX_OUTCLK_SOURCE TXPROGDIVCLK RX_OUTCLK_SOURCE RXPROGDIVCLK]
      } else {
	create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_$name
	set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} [get_bd_cells util_ds_buf_$name]
	make_bd_intf_pins_external  [get_bd_intf_pins util_ds_buf_$name/CLK_IN_D]
	set_property name gt_refclk_$name [get_bd_intf_ports CLK_IN_D_0]
        set user_settings_dict [dict create TX_LINE_RATE $lr TX_REFCLK_FREQUENCY $ref_freq RX_LINE_RATE $lr RX_REFCLK_FREQUENCY $ref_freq ]
        
      }
      set settings_dict [dict create LR0 $user_settings_dict]
      set complete_settings [get_GT_string "None" $settings_dict ""]
      set values [dict create ]
      set values [dict get $complete_settings LR0_SETTINGS]
      if {$logStuff} { 
        puts $f "set_property -dict \[list CONFIG.IP_NO_OF_LANES $num_lanes CONFIG.IP_LR0_SETTINGS \"$values\"\] \[get_bd_cells bridge_$name\]"
        flush $f
      }
      set_property -dict [list \
        CONFIG.IP_NO_OF_LANES $num_lanes \
        CONFIG.GT_TYPE $type \
        CONFIG.IP_LR0_SETTINGS $values \
        ] [get_bd_cells bridge_$name]

	 
      
      create_bd_cell -type ip -vlnv xilinx.com:ip:gtwiz_versal gtwiz_versal_$name
      create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_tx_$name
      create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_rx_$name
      
      if {$num_quads == 1} {     
        set_property -dict [list \
          CONFIG.INTF0_NO_OF_LANES $num_lanes \
          CONFIG.GT_TYPE $type \
          CONFIG.NO_OF_QUADS {1} \
          ] [get_bd_cells gtwiz_versal_$name]
	
	connect_bd_net [get_bd_pins bufg_gt_tx_$name/usrclk] [get_bd_pins bridge_$name/gt_txusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX3_usrclk]
	connect_bd_net [get_bd_pins bufg_gt_rx_$name/usrclk] [get_bd_pins bridge_$name/gt_rxusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX3_usrclk]

	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX3_GT_IP_Interface]

	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad0_GT_Serial]

        if {$type eq "GTM"} {
          connect_bd_net [get_bd_pins util_ds_buf_$name/IBUFDS_GTME5_O] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0]
	} else {
          connect_bd_net [get_bd_pins util_ds_buf_$name/IBUF_OUT] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0]
	}

      } elseif {$num_quads == 2} {   
        set_property -dict [list \
          CONFIG.INTF0_NO_OF_LANES $num_lanes \
          CONFIG.GT_TYPE $type \
          CONFIG.NO_OF_QUADS {2} \
	  CONFIG.QUAD1_PROT0_LANES {4} \
          ] [get_bd_cells gtwiz_versal_$name]

	connect_bd_net [get_bd_pins bufg_gt_tx_$name/usrclk] [get_bd_pins bridge_$name/gt_txusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX3_usrclk]
	connect_bd_net [get_bd_pins bufg_gt_rx_$name/usrclk] [get_bd_pins bridge_$name/gt_rxusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX3_usrclk]

	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX4] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX4_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX5] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX5_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX6] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX6_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX7] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX7_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX4] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX4_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX5] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX5_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX6] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX6_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX7] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX7_GT_IP_Interface]

	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad0_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad1_GT_Serial]

	if {$type eq "GTM"} {  
	  connect_bd_net [get_bd_pins util_ds_buf_$name/IBUFDS_GTME5_O] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD1_GTREFCLK0]
	} else {
          connect_bd_net [get_bd_pins util_ds_buf_$name/IBUF_OUT] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD1_GTREFCLK0]
        }

      } elseif {$num_quads == 3} {
        set_property -dict [list \
          CONFIG.INTF0_NO_OF_LANES $num_lanes \
          CONFIG.GT_TYPE $type \
          CONFIG.NO_OF_QUADS {3} \
	  CONFIG.QUAD1_PROT0_LANES {4} \
	  CONFIG.QUAD2_PROT0_LANES {4} \
          ] [get_bd_cells gtwiz_versal_$name]

	connect_bd_net [get_bd_pins bufg_gt_tx_$name/usrclk] [get_bd_pins bridge_$name/gt_txusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX3_usrclk]
	connect_bd_net [get_bd_pins bufg_gt_rx_$name/usrclk] [get_bd_pins bridge_$name/gt_rxusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX3_usrclk]

	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX4] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX4_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX5] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX5_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX6] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX6_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX7] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX7_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX4] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX4_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX5] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX5_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX6] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX6_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX7] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX7_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX8] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX8_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX9] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX9_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX10] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX10_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX11] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX11_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX8] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX8_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX9] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX9_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX10] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX10_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX11] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX11_GT_IP_Interface]

	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad0_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad1_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad2_GT_Serial]

	if {$type eq "GTM"} {
	  connect_bd_net [get_bd_pins util_ds_buf_$name/IBUFDS_GTME5_O] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD1_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD2_GTREFCLK0]
        } else {
          connect_bd_net [get_bd_pins util_ds_buf_$name/IBUF_OUT] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD1_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD2_GTREFCLK0]
        }

      } elseif {$num_quads == 4} {
        set_property -dict [list \
          CONFIG.INTF0_NO_OF_LANES $num_lanes \
          CONFIG.GT_TYPE $type \
          CONFIG.NO_OF_QUADS {4} \
	  CONFIG.QUAD1_PROT0_LANES {4} \
	  CONFIG.QUAD2_PROT0_LANES {4} \
	  CONFIG.QUAD3_PROT0_LANES {4} \
          ] [get_bd_cells gtwiz_versal_$name]

	connect_bd_net [get_bd_pins bufg_gt_tx_$name/usrclk] [get_bd_pins bridge_$name/gt_txusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_TX3_usrclk]
	connect_bd_net [get_bd_pins bufg_gt_rx_$name/usrclk] [get_bd_pins bridge_$name/gt_rxusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_RX3_usrclk]

	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX4] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX4_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX5] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX5_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX6] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX6_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX7] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX7_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX4] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX4_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX5] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX5_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX6] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX6_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX7] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX7_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX8] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX8_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX9] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX9_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX10] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX10_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX11] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX11_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX8] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX8_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX9] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX9_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX10] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX10_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX11] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX11_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX12] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX12_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX13] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX13_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX14] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX14_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX15] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX15_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX12] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX12_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX13] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX13_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX14] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX14_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX15] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX15_GT_IP_Interface]

	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad0_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad1_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad2_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad3_GT_Serial]

	if {$type eq "GTM"} {
	  connect_bd_net [get_bd_pins util_ds_buf_$name/IBUFDS_GTME5_O] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD1_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD2_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD3_GTREFCLK0]
        } else {
	  connect_bd_net [get_bd_pins util_ds_buf_$name/IBUF_OUT] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD1_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD2_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD3_GTREFCLK0LK0]
        }	  
	
      } elseif {$num_quads == 5} {
        set_property -dict [list \
          CONFIG.INTF0_NO_OF_LANES $num_lanes \
          CONFIG.GT_TYPE $type \
          CONFIG.NO_OF_QUADS {5} \
	  CONFIG.QUAD1_PROT0_LANES {4} \
	  CONFIG.QUAD2_PROT0_LANES {4} \
	  CONFIG.QUAD3_PROT0_LANES {4} \
	  CONFIG.QUAD4_PROT0_LANES {4} \
          ] [get_bd_cells gtwiz_versal_$name]

	connect_bd_net [get_bd_pins bufg_gt_tx_$name/usrclk] [get_bd_pins bridge_$name/gt_txusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_TX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD4_TX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD4_TX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD4_TX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD4_TX3_usrclk]
	connect_bd_net [get_bd_pins bufg_gt_rx_$name/usrclk] [get_bd_pins bridge_$name/gt_rxusrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD0_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD1_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD2_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD3_RX3_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD4_RX0_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD4_RX1_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD4_RX2_usrclk] [get_bd_pins gtwiz_versal_$name/QUAD4_RX3_usrclk]

	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX0] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX1] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX2] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX3] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX4] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX4_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX5] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX5_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX6] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX6_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX7] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX7_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX4] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX4_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX5] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX5_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX6] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX6_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX7] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX7_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX8] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX8_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX9] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX9_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX10] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX10_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX11] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX11_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX8] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX8_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX9] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX9_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX10] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX10_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX11] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX11_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX12] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX12_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX13] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX13_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX14] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX14_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX15] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX15_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX12] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX12_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX13] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX13_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX14] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX14_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX15] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX15_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX16] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX16_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX17] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX17_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX18] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX18_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_TX19] [get_bd_intf_pins gtwiz_versal_$name/INTF0_TX19_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX16] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX16_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX17] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX17_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX18] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX18_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge_$name/GT_RX19] [get_bd_intf_pins gtwiz_versal_$name/INTF0_RX19_GT_IP_Interface]

	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad0_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad1_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad2_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad3_GT_Serial]
	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal_$name/Quad4_GT_Serial]

	if {$type eq "GTM"} {  
	  connect_bd_net [get_bd_pins util_ds_buf_$name/IBUFDS_GTME5_O] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD1_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD2_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD3_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD4_GTREFCLK0]
	} else {
	  connect_bd_net [get_bd_pins util_ds_buf_$name/IBUF_OUT] [get_bd_pins gtwiz_versal_$name/QUAD0_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD1_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD2_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD3_GTREFCLK0] [get_bd_pins gtwiz_versal_$name/QUAD4_GTREFCLK0]
	}
      }      

      connect_bd_net [get_bd_pins gtwiz_versal_$name/QUAD0_TX0_outclk] [get_bd_pins bufg_gt_tx_$name/outclk]
      connect_bd_net [get_bd_pins gtwiz_versal_$name/QUAD0_RX0_outclk] [get_bd_pins bufg_gt_rx_$name/outclk]
      connect_bd_net [get_bd_pins gtwiz_versal_$name/INTF0_TX_clr_out] [get_bd_pins bufg_gt_tx_$name/gt_bufgtclr]
      connect_bd_net [get_bd_pins gtwiz_versal_$name/INTF0_TX_clr_out] [get_bd_pins bufg_gt_rx_$name/gt_bufgtclr]
      connect_bd_net [get_bd_pins gtwiz_versal_$name/INTF0_rst_tx_done_out] [get_bd_pins bridge_$name/tx_reset_in]
      connect_bd_net [get_bd_pins gtwiz_versal_$name/INTF0_rst_rx_done_out] [get_bd_pins bridge_$name/rx_reset_in]
      connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins bridge_$name/apb3clk] [get_bd_pins gtwiz_versal_$name/gtwiz_freerun_clk]
    }
    

    
    # Re-wire global apb clock connected to all quad IPs
    #if {[dict size $protocols] > 0} {
    #  delete_bd_objs [get_bd_ports apb3clk_quad]
    #  connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins gt_quad_base/apb3clk]
    #}
    
    validate_bd_design
    save_bd_design
    
    if {$logStuff} {
      puts $f "delete_bd_objs \[get_bd_ports apb3clk_quad\]"
      puts $f "connect_bd_net \[get_bd_pins versal_cips_0/pl0_ref_clk\] \[get_bd_pins gt_quad_base/apb3clk\]"
      puts $f "validate_bd_design"
      puts $f "save_bd_design"
      close $f
    }
  }
  
  #
  # Create XDC with location and timing constraints
  #
  proc make_xdc {design_name protocols} {
    load librdi_iptasks[info sharedlibextension]
    
    log "*** make_xdc ***"
    set outputfile [open ${design_name}.xdc w]

    set part [get_property PART [current_project]]
    set device [lindex [split $part -] 0]

    for {set i 0} {$i < [dict size $protocols]} {incr i} {
      set idx 0
      set name [dict get $protocols $i name]
      set line_rate [dict get $protocols $i line_rate]
      set refclk_freq [dict get $protocols $i ref_freq]
      set type [get_quad_type [dict get $protocols $i quad0]]
      set width [get_${type}_width $line_rate]
      puts $outputfile "# ${name} : ${line_rate} Gbps with $refclk_freq MHz"
      set slr_number [lindex [split $name _] 2]
      set slr_number [lindex [split $slr_number X] 0]
      log "name: ${name}"
      set total_quads [dict get $protocols $i num_quads]
      set total_quads_temp [dict get $protocols $i num_quads]
      for {set j 0} {$j < [dict get $protocols $i num_quads]} {incr j} {
        set coord [dict get $protocols $i quad$j]
        log "coord: $coord"
        set period [expr 1 / ($line_rate * 1.0 / $width) ]
	if {$device eq "xcvp1902" && ($slr_number eq "S1" || $slr_number eq "S2")} {
          set idx_p80 [expr $idx + [expr $total_quads_temp - 1]]
          if {$idx_p80 == 0} {
            set inst "${design_name}_i/gtwiz_versal_${name}/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst"
            #set inst "${design_name}_i/gt_quad_base/inst/quad_inst"
          } else {
            set inst "${design_name}_i/gtwiz_versal_${name}/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_${idx_p80}_inst/inst/quad_inst"
            #set inst "${design_name}_i/gt_quad_base_${idx_p80}/inst/quad_inst"
          }
          set total_quads_temp [expr $total_quads_temp - 2]
        } else {
          if {$idx == 0} {
            set inst "${design_name}_i/gtwiz_versal_${name}/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst"
            #set inst "${design_name}_i/gt_quad_base/inst/quad_inst"
          } else {
	    set inst "${design_name}_i/gtwiz_versal_${name}/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_${idx}_inst/inst/quad_inst"
            #set inst "${design_name}_i/gt_quad_base_${idx}/inst/quad_inst"
          }
        }
        log "inst: $inst"
        puts $outputfile "set_property LOC ${coord} \[get_cells $inst\]"
        # puts $outputfile "create_clock -period ${period} \[get_pins -hierarchical -regexp ${inst}/CH0_TXOUTCLK\]"
        # puts $outputfile "create_clock -period ${period} \[get_pins -hierarchical -regexp ${inst}/CH0_RXOUTCLK\]"
        puts $outputfile ""
        incr idx
      }

      set ref_coord [dict get $protocols $i ref_loc]
      
      if {$type == "GTM"} {
        set instroot "U0/USE_IBUFDS_GTME5.GEN_IBUFDS_GTME5\[0\].IBUFDS_GTME5_U"
        set pam_sel [get_pam_sel $line_rate] 
        set actual_ref [gtwiz::Ip_gtwiz_calculateActualRefclk_GTME5 $line_rate $refclk_freq 0 GTM $pam_sel]
      } else {
        set instroot "U0/USE_IBUFDS_GTE5.GEN_IBUFDS_GTE5\[0\].IBUFDS_GTE5_I"
        set actual_ref [gtwiz::Ip_gtwiz_calculateActualRefclk $line_rate $refclk_freq LCPLL]
      }

      if {$i == 0} {
        set inst "${design_name}_i/util_ds_buf_${name}/$instroot"
        puts $outputfile "set_property LOC ${ref_coord} \[get_cells  $inst\]"
        log "set_property LOC ${ref_coord} \[get_cells $inst\]"

      } else {
        set inst "${design_name}_i/util_ds_buf_${name}/$instroot"
        puts $outputfile "set_property LOC ${ref_coord} \[get_cells $inst\]"
        log  "set_property LOC ${ref_coord} \[get_cells $inst\]"

      }
      log "  refclk"
      ##set ref_period [expr 1000.0 / [dict get $protocols $i ref_freq]]
      
      ########################################################################
      #  TEMPORARY WORKAROUND for https://jira.xilinx.com/browse/CR-1090336
      #  Just use refclk directly to calculate refclk period, as opposed
      #  to "actual" refclk created by dividers, Ip_gtwiz_calculateActualRefclk
      #  is broken
      ########################################################################
      
      #set pll_type "LCPLL"
      #set actual_ref [gtwiz::Ip_gtwiz_calculateActualRefclk $line_rate $refclk_freq $pll_type]
      log "  actual_ref ${actual_ref}"
      set ref_period [expr 1000 / ($actual_ref)]
      
      #set ref_period [expr 1000 / ($refclk_freq)]
 
      puts $outputfile "create_clock -period ${ref_period} \[get_ports gt_refclk_${name}_clk_p\[0\]\]"
      puts $outputfile ""
      flush $outputfile

    }

    puts $outputfile "\nset_property BITSTREAM.GENERAL.COMPRESS TRUE \[current_design\]"

    close $outputfile

    import_files -fileset constrs_1 -norecurse "./${design_name}.xdc"
  }
  
  
  log "\n*** createDesign ***"
  set systemTime [clock seconds]
  log "createDesign: [clock format $systemTime -format %H:%M:%S]"
  log $options
  foreach k $options {
    log "$k"
  }
  set protocols [options2protocols $options]
  log "protocols: $protocols"
  create_root_design "" $design_name $protocols
  log "created root design, about to run make_xdc"
  make_xdc $design_name $protocols
  set proj_name [lindex [get_projects] 0]
  set proj_dir [get_property DIRECTORY $proj_name]
  set_property TARGET_LANGUAGE Verilog $proj_name
  make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
	add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v

  # close_bd_design [get_bd_designs $design_name]
  # set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
  open_bd_design [get_bd_files $design_name]
  
}

