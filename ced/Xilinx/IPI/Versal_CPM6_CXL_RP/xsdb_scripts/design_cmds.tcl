# design_cmds.tcl
#
# Board bring-up: PDI programming, MIO-as-GPIO utilities (for PERSTN
# toggling), and CPM6 Ctrl1 link-status checking. check_link_status's
# controller is hardcoded to Ctrl1 since this CED never uses Ctrl0.

#-----------------------------------------------------------------------------
# Generic read-modify-write. addr/mask/value: bits set in mask are the ones
# being modified; the corresponding bits of value are written, all other
# bits of the register are preserved.
#-----------------------------------------------------------------------------
proc design::rmw {addr mask value} {
  set cur [mrd -force -value $addr]
  mwr -force $addr [expr {($cur & ~$mask) | ($value & $mask)}]
}

#-----------------------------------------------------------------------------
# MIO-as-GPIO utilities. Any generic MIO pin (0-51) can be set up as GPIO,
# verified, and driven hi/lo/pulsed.
#-----------------------------------------------------------------------------

# Sets up a MIO pin (0-51) as GPIO. If dir=out, dfault must be provided.
proc design::setup_mio_as_gpio {pin dir {dfault -1}} {
  if {$pin < 0 || $pin > 51} {
    error "setup_mio_as_gpio: pin $pin is out of range (valid: 0-51)"
  }
  if {$dir ne "in" && $dir ne "out"} {
    error "setup_mio_as_gpio: dir '$dir' is invalid (valid: in, out)"
  }
  if {$dir eq "out" && $dfault == -1} {
    error "setup_mio_as_gpio: dfault must be provided when dir=out"
  }

  # Setup Level 3 muxes to drive pin from GPIO
  # MIO_PIN_n is at PMC_IOU_SLCR base 0xf1060000 + n*4 | n inside {[0:51]}
  # L3_SEL[9:7]=0 (don't care)
  # L2_SEL[6:5]=3 (gpio1)
  # L1_SEL[4:3]=0 (use the L2 mux output)
  # L0_SEL[2:1]=0 (use the L1 mux output)
  set mio_reg [expr {0xf1060000 + $pin * 4}]
  mwr -force 0xf1060828 0x0; # PMC_IOU_SLCR WPROT0: disable write protection
  mwr -force $mio_reg 0x60

  # Setup GPIO
  # Bank 0: MIO 0-25, Bank 1: MIO 26-51 (26 pins per bank)
  # DIRM_0: 0xf1020204, DIRM_1: 0xf1020244 (stride 0x40 per bank)
  set bank     [expr {$pin < 26 ? 0 : 1}]
  set bit      [expr {$pin < 26 ? $pin : $pin - 26}]
  set dirm_reg [expr {0xf1020204 + $bank * 0x40}]
  set cur      [mrd -force -value $dirm_reg]
  set mask     [expr {1 << $bit}]
  if {$dir eq "out"} {
    mwr -force $dirm_reg [expr {$cur | $mask}]

    # OEN: enable output driver (RMW)
    # OEN_0: 0xf1020208, OEN_1: 0xf1020248 (stride 0x40 per bank)
    set oen_reg [expr {0xf1020208 + $bank * 0x40}]
    set cur     [mrd -force -value $oen_reg]
    mwr -force $oen_reg [expr {$cur | $mask}]

    # MASK_DATA: write initial output value (dfault)
    # [31:16]=mask (0=write bit, 1=keep), [15:0]=data
    # LSW covers bits  0-15, MSW covers bits 16-25 within each bank
    # MASK_DATA_0_LSW: 0xf1020000, MASK_DATA_0_MSW: 0xf1020004 (stride 0x8 per bank)
    set bit_in_word [expr {$bit % 16}]
    set lsw_or_msw  [expr {$bit < 16 ? 0 : 4}]
    set mdata_reg   [expr {0xf1020000 + $bank * 8 + $lsw_or_msw}]
    set mdata_mask  [expr {(0xFFFF ^ (1 << $bit_in_word)) << 16}]
    set mdata_data  [expr {($dfault & 0x1) << $bit_in_word}]
    mwr -force $mdata_reg [expr {$mdata_mask | $mdata_data}]

    # MIO_MST_TRI: clear pin's tristate bit to enable output driver (active high, reset=1)
    # MIO_MST_TRI0: 0xf1060200 covers pins  0-25, bit = pin
    # MIO_MST_TRI1: 0xf1060204 covers pins 26-51, bit = pin - 26
    set tri_reg [expr {$pin < 26 ? 0xf1060200 : 0xf1060204}]
    set cur     [mrd -force -value $tri_reg]
    mwr -force $tri_reg [expr {$cur & (0xFFFFFFFF ^ $mask)}]
  } else {
    mwr -force $dirm_reg [expr {$cur & (0xFFFFFFFF ^ $mask)}]
  }
  mwr -force 0xf1060828 0x1; # PMC_IOU_SLCR WPROT0: re-enable write protection
}

# Verifies a MIO pin is configured as the specified direction (input/output).
# Reads MIO_PIN_N (L2 mux), DIRM, and for output also OEN and MIO_MST_TRI.
# If value is 0 or 1, also checks the pin's DATA_RO bit against value,
# erroring out on a mismatch. value=-1 (default) skips this check. Returns 1
# if all checks pass, 0 on any failure (prints the reason to stdout).
proc design::verify_mio {pin dir {value -1}} {
  if {$pin < 0 || $pin > 51} {
    puts "verify_mio: pin $pin is out of range (valid: 0-51)"
    return 0
  }
  if {$dir ni {in out}} {
    puts "verify_mio: dir '$dir' is invalid (valid: in, out)"
    return 0
  }
  if {$value ni {-1 0 1}} {
    puts "verify_mio: value '$value' is invalid (valid: -1, 0, 1)"
    return 0
  }

  set bank [expr {$pin < 26 ? 0 : 1}]
  set bit  [expr {$pin < 26 ? $pin : $pin - 26}]
  set mask [expr {1 << $bit}]

  # Check MIO_PIN_n mux: L0_SEL=0, L1_SEL=0, L2_SEL=3 (route to gpio1)
  set mio_reg [expr {0xf1060000 + $pin * 4}]
  set mio_val [mrd -force -value $mio_reg]
  set l0_sel  [expr {($mio_val >> 1) & 0x3}]
  set l1_sel  [expr {($mio_val >> 3) & 0x3}]
  set l2_sel  [expr {($mio_val >> 5) & 0x3}]
  if {$l0_sel != 0} {
    puts "verify_mio: pin $pin L0_SEL=$l0_sel, expected 0 (pass to L1)"
    return 0
  }
  if {$l1_sel != 0} {
    puts "verify_mio: pin $pin L1_SEL=$l1_sel, expected 0 (pass to L2)"
    return 0
  }
  if {$l2_sel != 3} {
    puts "verify_mio: pin $pin L2_SEL=$l2_sel, expected 3 (gpio1)"
    return 0
  }

  # Check DIRM direction bit
  set dirm_reg [expr {0xf1020204 + $bank * 0x40}]
  set dirm_val [mrd -force -value $dirm_reg]
  if {$dir eq "out" && ($dirm_val & $mask) == 0} {
    puts "verify_mio: pin $pin DIRM not set to output"
    return 0
  }
  if {$dir eq "in" && ($dirm_val & $mask) != 0} {
    puts "verify_mio: pin $pin DIRM not set to input"
    return 0
  }

  if {$dir eq "out"} {
    # Check OEN (output driver must be enabled)
    set oen_reg [expr {0xf1020208 + $bank * 0x40}]
    set oen_val [mrd -force -value $oen_reg]
    if {($oen_val & $mask) == 0} {
      puts "verify_mio: pin $pin OEN not set (output driver not enabled)"
      return 0
    }

    # Check MIO_MST_TRI (must be clear to drive pin)
    set tri_reg [expr {$pin < 26 ? 0xf1060200 : 0xf1060204}]
    set tri_val [mrd -force -value $tri_reg]
    if {($tri_val & $mask) != 0} {
      puts "verify_mio: pin $pin is tristated (MIO_MST_TRI bit set)"
      return 0
    }
  }

  # Optionally verify the pin's DATA_RO value
  if {$value != -1} {
    set data_ro_reg [expr {0xf1020060 + $bank * 4}]
    set data_val [mrd -force -value $data_ro_reg]
    set bit_val  [expr {($data_val >> $bit) & 0x1}]
    if {$bit_val != $value} {
      error "verify_mio: pin $pin DATA_RO=$bit_val, expected $value"
    }
  }

  return 1
}

# Drives a MIO pin that has already been configured as a GPIO output via
# setup_mio_as_gpio. Calls verify_mio first to confirm the pin is ready.
# action: hi, lo, pulse_hi (lo->hi), pulse_lo (hi->lo)
proc design::drive_mio {pin action} {
  if {$pin < 0 || $pin > 51} {
    error "drive_mio: pin $pin is out of range (valid: 0-51)"
  }
  if {$action ni {hi lo pulse_hi pulse_lo}} {
    error "drive_mio: action '$action' is invalid (valid: hi, lo, pulse_hi, pulse_lo)"
  }

  if {![verify_mio $pin out]} {
    error "drive_mio: pin $pin is not properly configured as an output (see above)"
  }

  set bank [expr {$pin < 26 ? 0 : 1}]
  set bit  [expr {$pin < 26 ? $pin : $pin - 26}]
  set mask [expr {1 << $bit}]

  # Drive the pin via MASK_DATA
  # DATA_0_RO: 0xf1020060, DATA_1_RO: 0xf1020064 (stride 0x4 per bank)
  # MASK_DATA: [31:16]=mask (0=write, 1=keep), [15:0]=data
  set bit_in_word     [expr {$bit % 16}]
  set lsw_or_msw      [expr {$bit < 16 ? 0 : 4}]
  set mdata_reg       [expr {0xf1020000 + $bank * 8 + $lsw_or_msw}]
  set mdata_mask_keep [expr {(0xFFFF ^ (1 << $bit_in_word)) << 16}]
  set data_ro_reg     [expr {0xf1020060 + $bank * 4}]

  switch $action {
    hi {
      mwr -force $mdata_reg [expr {$mdata_mask_keep | (1 << $bit_in_word)}]
      set readback [mrd -force -value $data_ro_reg]
      if {($readback & $mask) == 0} {
        error "drive_mio: pin $pin hi write did not take effect (DATA_RO bit still low)"
      }
    }
    lo {
      mwr -force $mdata_reg $mdata_mask_keep
      set readback [mrd -force -value $data_ro_reg]
      if {($readback & $mask) != 0} {
        error "drive_mio: pin $pin lo write did not take effect (DATA_RO bit still high)"
      }
    }
    pulse_hi {
      mwr -force $mdata_reg [expr {$mdata_mask_keep | (1 << $bit_in_word)}]
      set readback [mrd -force -value $data_ro_reg]
      if {($readback & $mask) == 0} {
        error "drive_mio: pin $pin pulse_hi hi-phase did not take effect (DATA_RO bit still low)"
      }
      after 100
      mwr -force $mdata_reg $mdata_mask_keep
      set readback [mrd -force -value $data_ro_reg]
      if {($readback & $mask) != 0} {
        error "drive_mio: pin $pin pulse_hi lo-phase did not take effect (DATA_RO bit still high)"
      }
    }
    pulse_lo {
      mwr -force $mdata_reg $mdata_mask_keep
      set readback [mrd -force -value $data_ro_reg]
      if {($readback & $mask) != 0} {
        error "drive_mio: pin $pin pulse_lo lo-phase did not take effect (DATA_RO bit still high)"
      }
      after 100
      mwr -force $mdata_reg [expr {$mdata_mask_keep | (1 << $bit_in_word)}]
      set readback [mrd -force -value $data_ro_reg]
      if {($readback & $mask) == 0} {
        error "drive_mio: pin $pin pulse_lo hi-phase did not take effect (DATA_RO bit still low)"
      }
    }
  }
}

#-----------------------------------------------------------------------------
# Link status. This CED always instantiates CPM6 Controller 1 (design.xml:
# "utilizing Controller 1 within CPM6"), so the base addresses are fixed
# constants (base_addr array below), not arguments -- there is no Ctrl0 to
# select. Reads CPM6_PCIE_CORE MISC_STAT0/LTSSM_CS and the PF0 PCIe cap link
# status, prints a concise summary, and returns 1 if the link is up
# (smlh_link_up && rdlh_link_up), 0 otherwise.
#-----------------------------------------------------------------------------
proc design::check_link_status {} {
  array set ltssm_names {
    0x00 DETECT_QUIET       0x01 DETECT_ACT
    0x02 POLL_ACTIVE        0x03 POLL_COMPLIANCE
    0x04 POLL_CONFIG        0x05 PRE_DETECT_QUIET
    0x06 DETECT_WAIT        0x07 CFG_LINKWD_START
    0x08 CFG_LINKWD_ACEPT   0x09 CFG_LANENUM_WAIT
    0x0A CFG_LANENUM_ACEPT  0x0B CFG_COMPLETE
    0x0C CFG_IDLE           0x0D RCVRY_LOCK
    0x0E RCVRY_SPEED        0x0F RCVRY_RCVRCFG
    0x10 RCVRY_IDLE         0x11 L0
    0x12 L0S                0x13 L123_SEND_EIDLE
    0x14 L1_IDLE            0x15 L2_IDLE
    0x16 L2_WAKE            0x17 DISABLED_ENTRY
    0x18 DISABLED_IDLE      0x19 DISABLED
    0x1A LPBK_ENTRY         0x1B LPBK_ACTIVE
    0x1C LPBK_EXIT          0x1D LPBK_EXIT_TIMEOUT
    0x1E HOT_RESET_ENTRY    0x1F HOT_RESET
  }
  array set vlsm_names {0x0 RESET 0x1 ACTIVE 0x2 ACTIVE_L0S_PMNAK 0x3 DAPM
                         0x4 IDLE_L1_1 0x5 IDLE_L1_2 0x6 IDLE_L1_3 0x7 IDLE_L1_4
                         0x8 L2 0x9 LINKRESET 0xA LINKERROR 0xB RETRAIN 0xC DISABLED}
  array set speed_names {0x1 Gen1 0x2 Gen2 0x3 Gen3 0x4 Gen4 0x5 Gen5 0x6 Gen6}
  array set width_names {0x01 x1 0x02 x2 0x04 x4 0x08 x8 0x10 x16 0x20 x32}
  array set base_addr {pcie_core 0xfc940000 pf0_cap 0xfc400000}

  set ms0 [mrd -force -value [expr {$base_addr(pcie_core) + 0x688}]]  ;# MISC_STAT0
  set lcs [mrd -force -value [expr {$base_addr(pcie_core) + 0x1010}]] ;# LTSSM_CS
  set lst [mrd -force -value [expr {$base_addr(pf0_cap)   + 0x80}]]   ;# PF0 Link Ctrl/Status

  set smlh_link_up [expr {($ms0 >> 20) & 0x1}]
  set rdlh_link_up [expr {($ms0 >> 11) & 0x1}]
  set vlsm_mc      [expr {($ms0 >> 16) & 0xF}]
  set vlsm_io      [expr {($ms0 >> 12) & 0xF}]
  set cxl_68b_vh   [expr {($ms0 >> 25) & 0x1}]
  set ltssm_state  [expr {($lcs >>  3) & 0x3F}]
  set nego_width   [expr {($lst >> 20) & 0x3F}]
  set link_speed   [expr {($lst >> 16) & 0xF}]

  set vlsm_mc_key [format "0x%X" $vlsm_mc]
  set vlsm_io_key [format "0x%X" $vlsm_io]
  if {[info exists vlsm_names($vlsm_mc_key)]} { set vlsm_mc_str $vlsm_names($vlsm_mc_key) } else { set vlsm_mc_str $vlsm_mc_key }
  if {[info exists vlsm_names($vlsm_io_key)]} { set vlsm_io_str $vlsm_names($vlsm_io_key) } else { set vlsm_io_str $vlsm_io_key }

  set speed_key [format "0x%X"   $link_speed]
  set width_key [format "0x%02X" $nego_width]
  if {[info exists speed_names($speed_key)]} { set speed_str $speed_names($speed_key) } else { set speed_str "Gen?" }
  if {[info exists width_names($width_key)]} { set width_str $width_names($width_key) } else { set width_str "x?" }

  set ltssm_key [format "0x%02X" $ltssm_state]
  if {[info exists ltssm_names($ltssm_key)]} { set ltssm_name $ltssm_names($ltssm_key) } else { set ltssm_name "UNKNOWN" }
  if {$ltssm_state == 0x11} {
    set ltssm_str [format "%s at %s%s (smlh_link_up=%d)" $ltssm_name $speed_str $width_str $smlh_link_up]
  } else {
    set ltssm_str [format "%s (smlh_link_up=%d)" $ltssm_name $smlh_link_up]
  }

  if {$rdlh_link_up} { set dll_str "UP" } else { set dll_str "DOWN" }
  if {$cxl_68b_vh}   { set flit_str "68B Flit" } else { set flit_str "256B Flit" }

  puts "\[design:INFO\] Ctrlr1:"
  puts "\[design:INFO\]   Link state       : $ltssm_str"

  if {$ltssm_state == 0x11} {
    puts "\[design:INFO\]   Data link layer  : $dll_str (rdlh_link_up=$rdlh_link_up)"
    puts "\[design:INFO\]   VLSM mc/io       : mc=$vlsm_mc_str, io=$vlsm_io_str"
    puts "\[design:INFO\]   Flit mode        : $flit_str"
  }

  return [expr {$smlh_link_up && $rdlh_link_up}]
}

#-----------------------------------------------------------------------------
# Full bring-up: program boot.pdi + pld.pdi (cwd), toggle PERSTN externally
# (to the EP, MIO 41) and internally (to the RP, MIO 19 workaround), then
# check the CPM6 Ctrl1 link. Returns the link-up boolean from
# check_link_status; does NOT raise an error on link-down so the caller can
# decide how to react.
#-----------------------------------------------------------------------------
proc design::program {} {
  variable TARGET_INDEX
  foreach p {./boot.pdi ./pld.pdi} {
    if {![file exists $p]} {
      error "PDI not found: $p (relative to xsdb's current working directory, not this script's location -- check [pwd])"
    }
  }

  targets $TARGET_INDEX
  puts "INFO: selected target $TARGET_INDEX"
  puts "Programming the device..."
  device program ./boot.pdi
  device program ./pld.pdi
  after 100

  puts "Assert PERSTN externally (to EP)..."
  drive_mio 41 lo

  puts "Toggle PERSTN internally to initialize RP..."
  ############################################################
  # Drive dedicated external PERST pin that ties to PS IRQ
  # Note: this is actually an input on the VPK360, but we can
  #       still drive it so that we can trigger internal IRQ.
  #       even when we configure it as an output in Vivado, the
  #       generated PDI still sets as input
  ############################################################
  rmw 0xFF0B0204 0x80000 0x80000 ;# PS_GPIO.DIRM_0           (MIO[25:0])
  rmw 0xFF0B0208 0x80000 0x80000 ;# PS_GPIO.OEN_0            (MIO[25:0])
  rmw 0xFF0B0220 0x80000 0x80000 ;# PS_GPIO.INT_POLARITY_0   (MIO[25:0])
  rmw 0xFF0B0224 0x80000 0x00000 ;# PS_GPIO.INT_ANY_0        (MIO[25:0])
 #rmw 0xFF080204 0x80000 0x00000 ;# LPD_IO_SLCR.MIO_MST_TRI0 (MIO[25:0])
  ############################################################
  mwr -force 0xFF0B0004 0xFFF70000  ;# drive MIO19 LOW
  mwr -force 0xFF0B0004 0xFFF70008  ;# drive MIO19 HIGH -> IRQ on rising edge -> PLM ExecuteProc(0x2)
  after 2000 ;# alternatively: poll something

  puts "Deassert PERSTN externally (to EP)..."
  drive_mio 41 hi
  after 100

  puts "Check if the link is up..."
  return [check_link_status]
}
