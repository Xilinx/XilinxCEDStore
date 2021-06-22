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

proc get_quad_type {quad} {
  set toks [split $quad "_"]
  return [lindex $toks 0]
}

proc get_default_lr {quad} {
  set type [get_quad_type $quad]
  if {$type eq "GTM"} {
    return 56.42
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
  set idx 0
  set f [open "create_design2.txt" w]
  set systemTime [clock seconds]
  puts $f "options2protocols: [clock format $systemTime -format %H:%M:%S]"
  puts $f $options
  set protocols [dict create]
  set part [get_property PART [current_project]]
  set pkg [lindex [split $part -] 1]  
  set speedgrade [lindex [split $part -] 2] 

  puts $f "part/pkg: $part $pkg"
  foreach q [get_all_quads $pkg] {
    if {[dictDefault $options ${q}_en.VALUE false] == "true"} {
      set line_rate [dictDefault $options ${q}_lr.VALUE [get_default_lr $q]]
      puts $f "  linerate: $line_rate"
      
      set ref_freq [dictDefault $options ${q}_rr.VALUE [get_default_rr $q]]
      puts $f "  ref_freq: $ref_freq"
      set default_loc [lindex [get_reflocs $q] 0]
      puts $f "  default_loc: $q $default_loc"
      set ref_loc [dictDefault $options ${q}_ref.VALUE $default_loc]
      puts $f "  ref_loc: $ref_loc"
      
      # Find XY coordinate if refloc comes from other quad
      if {[regexp {X\d+Y\d+} $ref_loc] == 0} {
        set my_q $ref_loc
        set ref_loc [dictDefault $options ${my_q}_ref.VALUE [lindex [get_reflocs $my_q] 0]]
        puts $f "  located $ref_loc from $my_q"
      }
      
      set found [findProtocol refclk$ref_loc $protocols]
      #
      # name of each protocol is the refclk source.  If that protocol doesn't exist in the 
      # dict, create it
      #
      if {$found == -1} {
        puts $f "  new protocol: refclk$ref_loc"
        dict set protocols $idx name "refclk$ref_loc"
        dict set protocols $idx line_rate $line_rate 
        dict set protocols $idx ref_freq $ref_freq
        dict set protocols $idx ref_loc $ref_loc
        dict set protocols $idx num_quads 1
        dict set protocols $idx quad0 [get_gtloc $q]
        incr idx 
      } else {
        # otherwise add to the existing protocol
        puts $f "  adding to $ref_loc: found = $found"
        set num [dict get $protocols $found num_quads]
        dict set protocols $found num_quads [expr $num+1]
        dict set protocols $found quad${num} [get_gtloc $q]
        puts $f "  added q$num to $ref_loc"
      }
    }
  }
  
  pdict $protocols * $f
  pdict $protocols * stdout
  close $f
  return $protocols
}


proc createDesign {design_name options} {
  
  proc create_root_design { parentCell design_name protocols} {
    
    set f [open "create_design_bd.tcl" w]
    puts $f "# in create_root_design"
    puts $f "# options: $protocols"
    create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.0 versal_cips_0
    
    # CIPS v3.0 with automation build 0529
    #apply_bd_automation -rule xilinx.com:bd_rule:cips -config { board_preset {No} boot_config {Custom} configure_noc {Add new AXI NoC} debug_config {Custom} design_flow {PL Flow (no PS)} mc_type {None} num_mc {1} pl_clocks {1} pl_resets {None}}  [get_bd_cells versal_cips_0]
    apply_bd_automation -rule xilinx.com:bd_rule:cips -config { board_preset {No} boot_config {Custom} configure_noc {Add new AXI NoC} debug_config {Custom} design_flow {PL Subsystem} mc_type {None} num_mc {1} pl_clocks {1} pl_resets {None}}  [get_bd_cells versal_cips_0]

    
    set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 125} CONFIG.CLOCK_MODE {Custom}] [get_bd_cells versal_cips_0]

    
    
    puts $f "create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0"
    puts $f "apply_bd_automation -rule xilinx.com:bd_rule:cips -config { board_preset {No} boot_config {Custom} configure_noc {Add new AXI NoC} debug_config {Custom} design_flow {PL Only} mc_enable {No} mc_type {None} num_mc {1} pl_clocks {1} pl_resets {None}}  \[get_bd_cells versal_cips_0\]"
    puts $f "set_property -dict \[list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 125} CONFIG.CLOCK_MODE {Custom}] \[get_bd_cells versal_cips_0\]"
    # puts $f "set_property -dict \[list CONFIG.PMC_MIO_37_OUTPUT_DATA {high} CONFIG.PMC_MIO_37_DIRECTION {out} CONFIG.PMC_MIO_37_USAGE {GPIO}\] \[get_bd_cells versal_cips_0\]"
    
    flush $f
    
    puts $f "# CIPS created"
    
    for {set i 0} {$i < [dict size $protocols]} {incr i} {
      set name [dict get $protocols $i name]
      set lr [dict get $protocols $i line_rate]
      set num_lanes [expr [dict get $protocols $i num_quads] * 4]
      set ref_freq [dict get $protocols $i ref_freq]
      set type [get_quad_type [dict get $protocols $i quad0]]
      puts $f "# type = $type, name = $name"
      
      
      puts $f "create_bd_cell -type ip -vlnv xilinx.com:ip:gt_bridge_ip bridge_$name"
      flush $f
      create_bd_cell -type ip -vlnv xilinx.com:ip:gt_bridge_ip bridge_$name
      
      source [::bd::get_vlnv_dir xilinx.com:ip:gt_quad_base:1.1]/tcl/params.tcl
      puts $f "# got params.tcl"
      if {$type eq "GTM"} {
        set pam_sel [get_pam_sel $lr]
        set width [get_${type}_width $lr]
        set user_settings_dict [dict create TX_LINE_RATE $lr TX_REFCLK_FREQUENCY $ref_freq RX_LINE_RATE $lr RX_REFCLK_FREQUENCY $ref_freq GT_TYPE GTM RX_PAM_SEL $pam_sel TX_PAM_SEL $pam_sel TX_USER_DATA_WIDTH $width RX_USER_DATA_WIDTH $width TX_OUTCLK_SOURCE TXPROGDIVCLK RX_OUTCLK_SOURCE RXPROGDIVCLK]
      } else {
        set user_settings_dict [dict create TX_LINE_RATE $lr TX_REFCLK_FREQUENCY $ref_freq RX_LINE_RATE $lr RX_REFCLK_FREQUENCY $ref_freq ]
        
      }
      set settings_dict [dict create LR0 $user_settings_dict]
      set complete_settings [get_GT_string "None" $settings_dict ""]
      set values [dict create ]
      set values [dict get $complete_settings LR0_SETTINGS]
      puts $f "set_property -dict \[list CONFIG.IP_NO_OF_LANES $num_lanes CONFIG.IP_LR0_SETTINGS \"$values\"\] \[get_bd_cells bridge_$name\]"
      flush $f
      set_property -dict [list \
        CONFIG.IP_NO_OF_LANES $num_lanes \
        CONFIG.GT_TYPE $type \
        CONFIG.IP_LR0_SETTINGS $values \
        ] [get_bd_cells bridge_$name]
      
      puts $f "apply_bd_automation -rule xilinx.com:bd_rule:gt_ips -config {Auto_Connect_Refclk_ports {1} Auto_Connect_UsrClk_and_OutClks {1} DataPath_Interface_Connection {Start_With_New_Quad} Reset_Connection_Automation {1} }  \[get_bd_cells bridge_$name\]"
      flush $f

      apply_bd_automation -rule xilinx.com:bd_rule:gt_ips -config { \
        Auto_Connect_Refclk_ports {1} \
        Auto_Connect_UsrClk_and_OutClks {1} \
        DataPath_Interface_Connection {Start_With_New_Quad} \
        Reset_Connection_Automation {1}\
      }  [get_bd_cells bridge_$name]
      
      puts $f "delete_bd_objs \[get_bd_nets bridge_${name}_link_status_out\] \[get_bd_ports link_status_bridge_$name\]"
      puts $f "delete_bd_objs \[get_bd_nets bridge_${name}_tx_resetdone_out\] \[get_bd_ports tx_resetdone_out_bridge_$name\]"
      puts $f "delete_bd_objs \[get_bd_nets bridge_${name}_rx_resetdone_out\] \[get_bd_ports rx_resetdone_out_bridge_$name\]"
      puts $f "delete_bd_objs \[get_bd_nets bridge_${name}_txusrclk_out\] \[get_bd_ports txusrclk_bridge_$name\]"
      puts $f "delete_bd_objs \[get_bd_nets bridge_${name}_rxusrclk_out\] \[get_bd_ports rxusrclk_bridge_$name\]"
      puts $f "delete_bd_objs \[get_bd_nets bridge_${name}_rpll_lock_out\] \[get_bd_ports rpll_lock_bridge_$name\]"
      puts $f "delete_bd_objs \[get_bd_nets bridge_${name}_lcpll_lock_out\] \[get_bd_ports lcpll_lock_bridge_$name\]"
      puts $f "delete_bd_objs \[get_bd_nets gt_reset_bridge_${name}_1\] \[get_bd_ports gt_reset_bridge_$name\]"
      puts $f "delete_bd_objs \[get_bd_nets rate_sel_bridge_${name}_1\] \[get_bd_ports rate_sel_bridge_$name\]"
      puts $f "delete_bd_objs \[get_bd_nets apb3clk_bridge_${name}_1\] \[get_bd_ports apb3clk_bridge_${name}\]"
      puts $f "connect_bd_net \[get_bd_pins bridge_${name}/apb3clk\] \[get_bd_pins versal_cips_0/pl0_ref_clk\]"
      flush $f
      
      # trim unneeded ports, and reconnect apb clock to CIPS
      delete_bd_objs [get_bd_nets bridge_${name}_link_status_out] [get_bd_ports link_status_bridge_$name]
      delete_bd_objs [get_bd_nets bridge_${name}_tx_resetdone_out] [get_bd_ports tx_resetdone_out_bridge_$name]
      delete_bd_objs [get_bd_nets bridge_${name}_rx_resetdone_out] [get_bd_ports rx_resetdone_out_bridge_$name]
      delete_bd_objs [get_bd_nets bridge_${name}_txusrclk_out] [get_bd_ports txusrclk_bridge_$name]
      delete_bd_objs [get_bd_nets bridge_${name}_rxusrclk_out] [get_bd_ports rxusrclk_bridge_$name]
      delete_bd_objs [get_bd_nets bridge_${name}_rpll_lock_out] [get_bd_ports rpll_lock_bridge_$name]
      delete_bd_objs [get_bd_nets bridge_${name}_lcpll_lock_out] [get_bd_ports lcpll_lock_bridge_$name]
      delete_bd_objs [get_bd_nets gt_reset_bridge_${name}_1] [get_bd_ports gt_reset_bridge_$name]
      delete_bd_objs [get_bd_nets rate_sel_bridge_${name}_1] [get_bd_ports rate_sel_bridge_$name]
      delete_bd_objs [get_bd_nets apb3clk_bridge_${name}_1] [get_bd_ports apb3clk_bridge_${name}]
      connect_bd_net [get_bd_pins bridge_${name}/apb3clk] [get_bd_pins versal_cips_0/pl0_ref_clk]
      
    }
    
    # Re-wire global apb clock connected to all quad IPs
    delete_bd_objs [get_bd_ports apb3clk_quad]
    connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins gt_quad_base/apb3clk]
    validate_bd_design
    save_bd_design
    
    puts $f "delete_bd_objs \[get_bd_ports apb3clk_quad\]"
    puts $f "connect_bd_net \[get_bd_pins versal_cips_0/pl0_ref_clk\] \[get_bd_pins gt_quad_base/apb3clk\]"
    puts $f "validate_bd_design"
    puts $f "save_bd_design"
    close $f
  }
  
  #
  # Create XDC with location and timing constraints
  #
  proc make_xdc {design_name protocols} {
    load librdi_iptasks[info sharedlibextension]
    set f [open "make_xdc.txt" w]
    puts $f "make_xdc"
    flush $f
    set outputfile [open ${design_name}.xdc w]

    set idx 0
    for {set i 0} {$i < [dict size $protocols]} {incr i} {
      set name [dict get $protocols $i name]
      set line_rate [dict get $protocols $i line_rate]
      set refclk_freq [dict get $protocols $i ref_freq]
      set type [get_quad_type [dict get $protocols $i quad0]]
      set width [get_${type}_width $line_rate]
      puts $outputfile "# ${name} : ${line_rate} Gbps with $refclk_freq MHz"
      puts $f "name: ${name}"
      for {set j 0} {$j < [dict get $protocols $i num_quads]} {incr j} {
        set coord [dict get $protocols $i quad$j]
        puts $f "coord: $coord"
        set period [expr 1 / ($line_rate * 1.0 / $width) ]

        if {$idx == 0} {
          set inst "${design_name}_i/gt_quad_base/inst/quad_inst"
        } else {
          set inst "${design_name}_i/gt_quad_base_${idx}/inst/quad_inst"
        }
        puts $f "inst: $inst"
        puts $outputfile "set_property LOC ${coord} \[get_cells $inst\]"
        puts $outputfile "create_clock -period ${period} \[get_pins -hierarchical -regexp ${inst}/CH0_TXOUTCLK\]"
        puts $outputfile "create_clock -period ${period} \[get_pins -hierarchical -regexp ${inst}/CH0_RXOUTCLK\]"
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
        set inst "${design_name}_i/util_ds_buf/$instroot"
        puts $outputfile "set_property LOC ${ref_coord} \[get_cells  $inst\]"
        puts $f "set_property LOC ${ref_coord} \[get_cells $inst\]"

      } else {
        set inst "${design_name}_i/util_ds_buf_${i}/$instroot"
        puts $outputfile "set_property LOC ${ref_coord} \[get_cells $inst\]"
        puts $f  "set_property LOC ${ref_coord} \[get_cells $inst\]"

      }
      puts $f "  refclk"
      ##set ref_period [expr 1000.0 / [dict get $protocols $i ref_freq]]
      
      ########################################################################
      #  TEMPORARY WORKAROUND for https://jira.xilinx.com/browse/CR-1090336
      #  Just use refclk directly to calculate refclk period, as opposed
      #  to "actual" refclk created by dividers, Ip_gtwiz_calculateActualRefclk
      #  is broken
      ########################################################################
      
      #set pll_type "LCPLL"
      #set actual_ref [gtwiz::Ip_gtwiz_calculateActualRefclk $line_rate $refclk_freq $pll_type]
      puts $f "  actual_ref ${actual_ref}"
      flush $f
      set ref_period [expr 1000 / ($actual_ref)]
      
      #set ref_period [expr 1000 / ($refclk_freq)]
 
      puts $outputfile "create_clock -period ${ref_period} \[get_ports bridge_${name}_diff_gt_ref_clock_clk_p\[0\]\]"
      puts $outputfile ""
      flush $outputfile

    }

    puts $outputfile "\nset_property BITSTREAM.GENERAL.COMPRESS TRUE \[current_design\]"

    close $outputfile
    close $f

    import_files -fileset constrs_1 -norecurse "./${design_name}.xdc"
  }
  
  
  set f [open "create_design.txt" w]
  puts $f "in createDesign"
  set systemTime [clock seconds]
  puts $f "createDesign: [clock format $systemTime -format %H:%M:%S]"
  puts $f $options
  foreach k $options {
    puts $f "$k"
  }
  set protocols [options2protocols $options]
  puts $f "protocols: $protocols"
  create_root_design "" $design_name $protocols
  puts $f "created root design, about to run make_xdc"
  make_xdc $design_name $protocols
  set proj_name [lindex [get_projects] 0]
  set proj_dir [get_property DIRECTORY $proj_name]
  set_property TARGET_LANGUAGE Verilog $proj_name
  make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
	add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v

  # close_bd_design [get_bd_designs $design_name]
  # set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
  open_bd_design [get_bd_files $design_name]
  close $f
  
}

