# ecam_hdm.tcl
#
# CXL Host-managed Device Memory (HDM) bring-up on the ep: ecam::setup_hdm
# programs either the PCIe DVSEC for CXL Devices' own Range registers
# ("range" mode, CXL 3.x Sec. 8.1.3) or the CXL HDM Decoder Capability
# structure behind a Component Register BAR ("decoder" mode, Sec. 8.2.4.20)
# -- the two alternative mechanisms a CXL device can use to advertise which
# host physical addresses map to its device-managed memory. Both write a
# fixed base of ecam::HDM_BASE (8 TB), well above the 1 TB a device
# typically advertises so the assigned range never overlaps host memory
# below that mark; if the device populates two ranges, both modes make
# them contiguous rather than leaving the second range unused.
#
# Must run after ecam::setup_ep_bars (Component Register access in
# "decoder" mode reads the ep's own BAR registers to find the block).
# Component Register / HDM Decoder accesses are raw BAR-mapped MMIO, not
# ep config space, so they go through control::rd32/wr32 directly (no
# get_cfg_addr/cfg_read/cfg_write, which are for the fixed ep/rp config
# windows only) -- printed as plain lines rather than the "CFG | TAG | ..."
# table style the rest of ecam:: uses for genuine config-space accesses.

#----------------------------------------------------------------------------
# Shared: find a specific CXL DVSEC, and enable CXL.mem on the device
#----------------------------------------------------------------------------
# Silent walk of the extended capability list on target for the CXL DVSEC
# (Vendor 0x1E98) whose DVSEC ID is dvsec_id. Returns {offset length} or
# {} if not found. Deliberately independent of ecam::walk_ext_caps/
# find_cxl (which print every entry as they walk) -- same reasoning as
# ecam::show_cxl doing its own walk.
proc ecam::find_dvsec_by_id {target dvsec_id} {
  variable DVSEC_EXT_CAP_ID
  variable CXL_VENDOR_ID
  set offset 0x100
  set seen {}
  while {$offset != 0} {
    if {$offset in $seen} { break }
    lappend seen $offset
    set hdr      [cfg_read $target $offset]
    set cap_id   [expr {$hdr & 0xFFFF}]
    set next_off [expr {($hdr >> 20) & 0xFFF}]
    if {$cap_id == $DVSEC_EXT_CAP_ID} {
      set dw1 [cfg_read $target [expr {$offset + 0x04}]]
      if {($dw1 & 0xFFFF) == $CXL_VENDOR_ID} {
        set dw2 [cfg_read $target [expr {$offset + 0x08}]]
        if {($dw2 & 0xFFFF) == $dvsec_id} {
          set length [expr {($dw1 >> 20) & 0xFFF}]
          return [list $offset $length]
        }
      }
    }
    set offset $next_off
  }
  return {}
}

# Sets Mem_Enable (CXL Control bit 2, DVSEC+0x0C) then Config_Lock (CXL
# Lock bit 0, DVSEC+0x14) on the CXL Device DVSEC at dvsec_off on target,
# enabling the device to participate in CXL.mem traffic. Config_Lock is
# write-once (RWO) -- once set it makes Mem_Enable, and every other RWL
# field in this DVSEC (including the Range Base registers), read-only
# until the next Conventional Reset, so Mem_Enable must be written first.
# A no-op if Config_Lock and Mem_Enable are already both set; errors if
# Config_Lock is set but Mem_Enable somehow isn't (should be unreachable
# via this proc, since it always writes Mem_Enable before Config_Lock).
proc ecam::enable_cxl_dvsec_mem {target dvsec_off} {
  set lock_addr [expr {$dvsec_off + 0x14}]
  set ctrl_addr [expr {$dvsec_off + 0x0C}]
  set lock_val  [cfg_read $target $lock_addr]
  set ctrl_val  [cfg_read $target $ctrl_addr]
  set config_lock [expr {$lock_val & 0x1}]
  set mem_enable  [expr {($ctrl_val >> 2) & 0x1}]

  if {$config_lock} {
    if {$mem_enable} {
      puts "  Mem_Enable=1 and Config_Lock=1 already -- nothing to do"
      return
    }
    error "Config_Lock is already set but Mem_Enable=0 -- Mem_Enable is now read-only and cannot be set until a Conventional Reset clears Config_Lock"
  }

  if {!$mem_enable} {
    set ctrl_val [expr {$ctrl_val | (1 << 2)}]
    print_cfg WRITE $ctrl_addr [format 0x%08X $ctrl_val] "CXL Control : Mem_Enable=1"
    control::wr32 [get_cfg_addr $target $ctrl_addr] $ctrl_val
  }

  set lock_val [expr {$lock_val | 0x1}]
  print_cfg WRITE $lock_addr [format 0x%08X $lock_val] "CXL Lock : Config_Lock=1 (WRITE-ONCE)"
  control::wr32 [get_cfg_addr $target $lock_addr] $lock_val
}

# Reads HDM_Count, then Range 1 Size (+ Range 2 Size if HDM_Count=2), from
# the CXL Device DVSEC on target, and returns their combined 64-bit size
# and hdm_count as {total_size hdm_count}. Used by "decoder" mode, where a
# single HDM decoder stands in for however many DVSEC ranges the device
# populates.
proc ecam::read_hdm_total_size {target} {
  set found [find_dvsec_by_id $target 0x0000]
  if {[llength $found] == 0} {
    error "PCIe DVSEC for CXL Devices (Vendor 0x1E98, ID 0x0000) not found on $target -- cannot read HDM_Count / Range Size registers"
  }
  lassign $found dvsec_off dvsec_len

  set cap_dw    [cfg_read $target [expr {$dvsec_off + 0x08}]]
  set hdm_count [expr {($cap_dw >> 20) & 0x3}]
  puts [format "CXL Device DVSEC @ ExtCap offset 0x%03X : HDM_Count=%d" $dvsec_off $hdm_count]

  if {$hdm_count == 0} { error "CXL Capability HDM_Count=0 -- device advertises no HDM ranges" }
  if {$hdm_count == 3} { error "CXL Capability HDM_Count=3 is Reserved -- cannot interpret Range registers" }

  set size1_hi    [cfg_read $target [expr {$dvsec_off + 0x18}]]
  set size1_lo_dw [cfg_read $target [expr {$dvsec_off + 0x1C}]]
  if {($size1_lo_dw & 0x1) == 0} { error "Range 1 Memory_Info_Valid=0 despite HDM_Count>=1 -- Range 1 is not populated" }
  set total [expr {(wide($size1_hi) << 32) | ($size1_lo_dw & 0xF0000000)}]
  puts [format "  Range 1 Size = 0x%016X (%s)" $total [human_size $total]]

  if {$hdm_count == 2} {
    set size2_hi    [cfg_read $target [expr {$dvsec_off + 0x28}]]
    set size2_lo_dw [cfg_read $target [expr {$dvsec_off + 0x2C}]]
    if {($size2_lo_dw & 0x1) == 0} { error "Range 2 Memory_Info_Valid=0 despite HDM_Count=2 -- Range 2 is not populated" }
    set size2 [expr {(wide($size2_hi) << 32) | ($size2_lo_dw & 0xF0000000)}]
    puts [format "  Range 2 Size = 0x%016X (%s)" $size2 [human_size $size2]]
    incr total $size2
  }
  return [list $total $hdm_count]
}

#----------------------------------------------------------------------------
# "range" mode: PCIe DVSEC for CXL Devices Range registers (Sec. 8.1.3)
#----------------------------------------------------------------------------
proc ecam::setup_hdm_range {} {
  variable HDM_BASE
  variable MAX_HDM_RANGE_SIZE

  set found [find_dvsec_by_id ep 0x0000]
  if {[llength $found] == 0} {
    error "PCIe DVSEC for CXL Devices (Vendor 0x1E98, ID 0x0000) not found on ep -- cannot set up HDM ranges"
  }
  lassign $found db dvsec_len

  set cap_dw    [cfg_read ep [expr {$db + 0x08}]]
  set mem_cap   [expr {($cap_dw >> 18) & 0x1}]
  set hdm_count [expr {($cap_dw >> 20) & 0x3}]
  puts [format "CXL Device DVSEC @ ExtCap offset 0x%03X : Mem_Capable=%d HDM_Count=%d" $db $mem_cap $hdm_count]

  if {$mem_cap != 1} { error "Mem_Capable is not set on ep -- device does not support CXL.mem" }
  if {$hdm_count != 1 && $hdm_count != 2} { error "HDM_Count=$hdm_count is not 1 or 2 -- no valid HDM range to set up" }

  set lock_dw [cfg_read ep [expr {$db + 0x14}]]
  if {($lock_dw & 0x1) == 1} {
    error "Config_Lock is already set on ep -- Range Base registers are read-only until a Conventional Reset"
  }

  # Range Size registers are device-reported and read-only -- only Base is
  # ever written here.
  set size1_hi    [cfg_read ep [expr {$db + 0x18}]]
  set size1_lo_dw [cfg_read ep [expr {$db + 0x1C}]]
  if {($size1_lo_dw & 0x1) == 0} { error "Range 1 Memory_Info_Valid=0 despite HDM_Count>=1 -- Range 1 is not populated" }
  set size1 [expr {(wide($size1_hi) << 32) | ($size1_lo_dw & 0xF0000000)}]
  puts [format "  Range 1 Size = 0x%016X (%s)" $size1 [human_size $size1]]
  if {$size1 > $MAX_HDM_RANGE_SIZE} {
    error [format "Range 1 Size 0x%016X exceeds the 8 TB limit (0x%016X)" $size1 $MAX_HDM_RANGE_SIZE]
  }

  set total_size $size1
  set size2 0
  if {$hdm_count == 2} {
    set size2_hi    [cfg_read ep [expr {$db + 0x28}]]
    set size2_lo_dw [cfg_read ep [expr {$db + 0x2C}]]
    if {($size2_lo_dw & 0x1) == 0} { error "Range 2 Memory_Info_Valid=0 despite HDM_Count=2 -- Range 2 is not populated" }
    set size2 [expr {(wide($size2_hi) << 32) | ($size2_lo_dw & 0xF0000000)}]
    puts [format "  Range 2 Size = 0x%016X (%s)" $size2 [human_size $size2]]
    incr total_size $size2
  }
  if {$total_size > $MAX_HDM_RANGE_SIZE} {
    error [format "combined Range Size 0x%016X exceeds the 8 TB limit (0x%016X)" $total_size $MAX_HDM_RANGE_SIZE]
  }

  # Range 1 Base = HDM_BASE. If the device populates a second range, its
  # Base continues immediately after Range 1's own size, so the two ranges
  # form one contiguous window instead of Range 2 sitting unused.
  set range1_base $HDM_BASE
  set range1_hi [expr {($range1_base >> 32) & 0xFFFFFFFF}]
  set range1_lo [expr {$range1_base & 0xF0000000}]
  print_cfg WRITE [expr {$db + 0x20}] [format 0x%08X $range1_hi] "Range 1 Base High"
  control::wr32 [get_cfg_addr ep [expr {$db + 0x20}]] $range1_hi
  print_cfg WRITE [expr {$db + 0x24}] [format 0x%08X $range1_lo] [format "Range 1 Base Low : Base=0x%016X" $range1_base]
  control::wr32 [get_cfg_addr ep [expr {$db + 0x24}]] $range1_lo

  set range2_base 0
  if {$hdm_count == 2} {
    set range2_base [expr {$range1_base + $size1}]
    set range2_hi [expr {($range2_base >> 32) & 0xFFFFFFFF}]
    set range2_lo [expr {$range2_base & 0xF0000000}]
    print_cfg WRITE [expr {$db + 0x30}] [format 0x%08X $range2_hi] "Range 2 Base High"
    control::wr32 [get_cfg_addr ep [expr {$db + 0x30}]] $range2_hi
    print_cfg WRITE [expr {$db + 0x34}] [format 0x%08X $range2_lo] \
      [format "Range 2 Base Low : Base=0x%016X (contiguous with Range 1)" $range2_base]
    control::wr32 [get_cfg_addr ep [expr {$db + 0x34}]] $range2_lo
  }

  enable_cxl_dvsec_mem ep $db

  puts ""
  if {$hdm_count == 2} {
    puts [format "DONE: Range 1 Base=0x%016X Size=0x%016X, Range 2 Base=0x%016X Size=0x%016X (contiguous, combined 0x%016X / %s), Mem_Enable=1, Config_Lock=1" \
      $range1_base $size1 $range2_base $size2 $total_size [human_size $total_size]]
  } else {
    puts [format "DONE: Range 1 Base=0x%016X Size=0x%016X (%s), Mem_Enable=1, Config_Lock=1" \
      $range1_base $size1 [human_size $size1]]
  }
  puts ""
  show_cxl ep 0x0
  return
}

#----------------------------------------------------------------------------
# "decoder" mode: CXL HDM Decoder Capability structure (Sec. 8.2.4.20)
#----------------------------------------------------------------------------
proc ecam::decoder_count_raw {enc} {
  switch $enc {
    0  { return 1 }  1  { return 2 }  2  { return 4 }  3  { return 6 }
    4  { return 8 }  5  { return 10 } 6  { return 12 } 7  { return 14 }
    8  { return 16 } 9  { return 20 } 10 { return 24 } 11 { return 28 }
    12 { return 32 }
    default { error [format "Decoder Count field has reserved encoding 0x%X" $enc] }
  }
}

# Target Range Type (0=Device Coherent/HDM-D or HDM-DB, 1=Host-only Coherent
# /HDM-H) chosen from the HDM Decoder Capability's Supported Coherency
# Models field (CXL 3.x Sec. 8.2.4.20.1).
proc ecam::choose_target_range_type {coherency_model} {
  switch $coherency_model {
    0 {
      puts "  WARNING: Supported_Coherency_Models=00b (Unknown) -- defaulting Target Range Type to Device Coherent (0)"
      return 0
    }
    2 { return 1 }
    default { return 0 }
  }
}

proc ecam::decode_ig {ig} {
  if {$ig <= 6} {
    set gran [expr {256 << $ig}]
    return [expr {$gran >= 1024 ? [format "%dKB" [expr {$gran / 1024}]] : [format "%dB" $gran]}]
  }
  return [format "Reserved(0x%X)" $ig]
}

proc ecam::decode_iw {iw} {
  switch -- $iw {
    0 { return 1 } 1 { return 2 } 2 { return 4 } 3 { return 8 } 4 { return 16 }
    8 { return 3 } 9 { return 6 } 10 { return 12 }
    default { return [format "Reserved(0x%X)" $iw] }
  }
}

# Parses the Register Locator DVSEC's Register Block entries (starting at
# dvsec_off+0x0C, 2 DWORDs each) for the one with Register Block
# Identifier=0x01 (Component Registers). Returns {bir block_offset} or {}.
proc ecam::find_component_reg_block {target dvsec_off dvsec_len} {
  if {$dvsec_len < 20 || (($dvsec_len - 12) % 8) != 0} {
    error [format "Register Locator DVSEC @ offset 0x%03X has malformed Length=%d (expected >=20 and (Length-12) a multiple of 8)" $dvsec_off $dvsec_len]
  }
  set num_entries [expr {($dvsec_len - 12) / 8}]
  for {set e 0} {$e < $num_entries} {incr e} {
    set entry_off [expr {$dvsec_off + 0x0C + $e * 8}]
    set lo [cfg_read $target $entry_off]
    set hi [cfg_read $target [expr {$entry_off + 4}]]
    set bir      [expr {$lo & 0x7}]
    set blk_id   [expr {($lo >> 8) & 0xFF}]
    set off_lo16 [expr {($lo >> 16) & 0xFFFF}]
    set block_offset [expr {(wide($hi) << 32) | ($off_lo16 << 16)}]
    puts [format "  Register Block %d : ID=0x%02X BIR=%d Offset=0x%016X" $e $blk_id $bir $block_offset]
    if {$blk_id == 0x01} { return [list $bir $block_offset] }
  }
  return {}
}

# Reads a BAR's programmed base address from ep config space (handles both
# 32-bit and 64-bit BARs, though ecam::setup_ep_bars only ever places
# 64-bit ones on this design).
proc ecam::read_bar_base {target bir} {
  set bar_off [expr {0x10 + 4 * $bir}]
  set bar_lo  [cfg_read $target $bar_off]
  if {($bar_lo & 0x1) != 0} {
    error [format "BAR%d (cfg offset 0x%02X) is an I/O BAR -- Component Registers require a Memory BAR" $bir $bar_off]
  }
  set bar_type [expr {($bar_lo >> 1) & 0x3}]
  set base_lo  [expr {$bar_lo & 0xFFFFFFF0}]
  if {$bar_type == 0} {
    puts [format "  BAR%d @ cfg offset 0x%02X : 32-bit, Base=0x%08X" $bir $bar_off $base_lo]
    return $base_lo
  } elseif {$bar_type == 2} {
    if {$bir >= 5} { error [format "BAR%d is marked 64-bit but BAR%d does not exist" $bir [expr {$bir + 1}]] }
    set bar_hi_off [expr {0x10 + 4 * ($bir + 1)}]
    set bar_hi     [cfg_read $target $bar_hi_off]
    set bar_base   [expr {(wide($bar_hi) << 32) | $base_lo}]
    puts [format "  BAR%d @ cfg offset 0x%02X : 64-bit, Base=0x%016X" $bir $bar_off $bar_base]
    return $bar_base
  } else {
    error [format "BAR%d (cfg offset 0x%02X) has reserved Type field (0x%X)" $bir $bar_off $bar_type]
  }
}

# Walks the CXL Capability array at cachemem_base (a raw BAR-mapped
# address, not ep config space) for CXL_Capability_ID=0x0005 (CXL HDM
# Decoder Capability). Returns its pointer (offset relative to
# cachemem_base) or -1 if not found.
proc ecam::find_hdm_decoder_cap {cachemem_base} {
  variable CXL_CAP_ID_NAMES
  set hdr    [control::rd32 $cachemem_base]
  set cap_id [expr {$hdr & 0xFFFF}]
  if {$cap_id != 0x0001} {
    error [format "CXL_Capability_Header @ 0x%016X has CXL_Capability_ID=0x%04X, expected 0x0001 -- Component Register block base is likely wrong" $cachemem_base $cap_id]
  }
  set array_size [expr {($hdr >> 24) & 0xFF}]
  puts [format "  CXL_Capability_Header @ 0x%016X : Array_Size=%d entries" $cachemem_base $array_size]
  for {set i 0} {$i < $array_size} {incr i} {
    set entry [control::rd32 [expr {$cachemem_base + 0x04 + $i * 4}]]
    set eid  [expr {$entry & 0xFFFF}]
    set ever [expr {($entry >> 16) & 0xF}]
    set eptr [expr {($entry >> 20) & 0xFFF}]
    set key [format 0x%04X $eid]
    set name [expr {[info exists CXL_CAP_ID_NAMES($key)] ? $CXL_CAP_ID_NAMES($key) : "Unknown/Reserved ($key)"}]
    puts [format "    Capability\[%d\] : ID=0x%04X (%s) Version=%d Pointer=0x%03X" $i $eid $name $ever $eptr]
    if {$eid == 0x0005} { return $eptr }
  }
  return -1
}

# Sets Control.Commit=1 for decoder n at hdm_base and polls Committed /
# Error_Not_Committed, which the device must resolve within 10ms (Sec.
# 8.2.4.20.12) -- polled with margin.
proc ecam::commit_decoder {hdm_base n label} {
  set dec_off   [expr {0x10 + $n * 0x20}]
  set ctrl_addr [expr {$hdm_base + $dec_off + 0x10}]

  set ctrl [control::rd32 $ctrl_addr]
  set ctrl [expr {$ctrl | (1 << 9)}]
  control::wr32 $ctrl_addr $ctrl

  set start_ms [clock milliseconds]
  set committed 0
  set err_flag  0
  set val       0
  while {1} {
    set val       [control::rd32 $ctrl_addr]
    set committed [expr {($val >> 10) & 1}]
    set err_flag  [expr {($val >> 11) & 1}]
    if {$committed || $err_flag} { break }
    if {([clock milliseconds] - $start_ms) > 50} { break }
    after 1
  }
  if {$err_flag} {
    error [format "Decoder %d (%s) reported Error_Not_Committed -- Control=0x%08X" $n $label $val]
  }
  if {!$committed} {
    error [format "Decoder %d (%s) did not report Committed within 50 ms of the Commit write -- Control=0x%08X" $n $label $val]
  }
  puts [format "  Decoder %d (%s) Committed=1" $n $label]
}

# Prints every implemented decoder's programmed state.
proc ecam::print_decoders {hdm_base decoder_count} {
  set gc_val    [control::rd32 [expr {$hdm_base + 0x04}]]
  set poison_en [expr {$gc_val & 0x1}]
  set hdm_en    [expr {($gc_val >> 1) & 0x1}]
  puts [format "HDM Decoder Summary (Decoder_Count=%d)" $decoder_count]
  puts [format "  Global Control=0x%08X Poison_On_Decode_Error_Enable=%d HDM_Decoder_Enable=%d" $gc_val $poison_en $hdm_en]
  for {set n 0} {$n < $decoder_count} {incr n} {
    set dec_off [expr {0x10 + $n * 0x20}]
    set base_lo [control::rd32 [expr {$hdm_base + $dec_off + 0x00}]]
    set base_hi [control::rd32 [expr {$hdm_base + $dec_off + 0x04}]]
    set size_lo [control::rd32 [expr {$hdm_base + $dec_off + 0x08}]]
    set size_hi [control::rd32 [expr {$hdm_base + $dec_off + 0x0C}]]
    set ctrl    [control::rd32 [expr {$hdm_base + $dec_off + 0x10}]]

    set base [expr {(wide($base_hi) << 32) | ($base_lo & 0xF0000000)}]
    set size [expr {(wide($size_hi) << 32) | ($size_lo & 0xF0000000)}]

    set ig                 [expr {$ctrl & 0xF}]
    set iw                 [expr {($ctrl >> 4) & 0xF}]
    set commit             [expr {($ctrl >> 9) & 0x1}]
    set committed          [expr {($ctrl >> 10) & 0x1}]
    set target_range_type  [expr {($ctrl >> 12) & 0x1}]

    set status [expr {($base == 0 && $size == 0) ? "PARKED" : "ACTIVE"}]
    puts [format "  Decoder %d : %s" $n $status]
    puts [format "    Base=0x%016X Size=0x%016X (%s)" $base $size [human_size $size]]
    puts [format "    IG=0x%X (%s) IW=0x%X (%s way(s)) Commit=%d Committed=%d Target_Range_Type=%d (%s)" \
      $ig [decode_ig $ig] $iw [decode_iw $iw] $commit $committed $target_range_type \
      [expr {$target_range_type == 0 ? "HDM-D/HDM-DB" : "HDM-H"}]]
  }
}

proc ecam::setup_hdm_decoder {} {
  variable HDM_BASE
  variable MAX_HDM_RANGE_SIZE
  variable CXL_CACHEMEM_OFFSET

  # Component Registers are reached via the ep's own BAR -- refuse to
  # proceed if ecam::setup_ep_bars hasn't sized/placed it yet.
  require_ep_bars_setup

  # Step 0: read HDM_Count + Range Size(s) from the CXL Device DVSEC to
  # size Decoder 0 (its Size is the combined size of every DVSEC range the
  # device populates -- one decoder standing in for however many ranges).
  lassign [read_hdm_total_size ep] total_size hdm_count
  puts [format "Decoder 0 combined Size = 0x%016X (%s)%s" $total_size [human_size $total_size] \
    [expr {$hdm_count == 2 ? " (Range 1 + Range 2, contiguous)" : " (Range 1)"}]]
  if {$total_size > $MAX_HDM_RANGE_SIZE} {
    error [format "combined HDM Size 0x%016X exceeds the 8 TB limit (0x%016X)" $total_size $MAX_HDM_RANGE_SIZE]
  }

  # Step 0c: enable Mem_Enable + Config_Lock on the CXL Device DVSEC so the
  # device is enabled to participate in CXL.mem traffic.
  set dev_found [find_dvsec_by_id ep 0x0000]
  if {[llength $dev_found] == 0} {
    error "PCIe DVSEC for CXL Devices (Vendor 0x1E98, ID 0x0000) not found on ep -- cannot enable Mem_Enable/Config_Lock"
  }
  enable_cxl_dvsec_mem ep [lindex $dev_found 0]

  # Steps 1-2: find the Register Locator DVSEC and its Component Registers
  # block (Block Identifier=0x01).
  set rl [find_dvsec_by_id ep 0x0008]
  if {[llength $rl] == 0} {
    error "Register Locator DVSEC (Vendor 0x1E98, ID 0x0008) not found on ep -- cannot locate Component Registers"
  }
  lassign $rl rl_off rl_len
  puts [format "Register Locator DVSEC @ ExtCap offset 0x%03X" $rl_off]
  set blk [find_component_reg_block ep $rl_off $rl_len]
  if {[llength $blk] == 0} {
    error "Register Locator DVSEC has no Register Block entry with Block Identifier=0x01 (Component Registers)"
  }
  lassign $blk comp_bir comp_blk_offset

  # Step 3: resolve the BAR base and the Component Register block address.
  set bar_base  [read_bar_base ep $comp_bir]
  set comp_base [expr {$bar_base + $comp_blk_offset}]
  puts [format "Component Register block base = 0x%016X (BAR%d=0x%016X + offset=0x%X)" \
    $comp_base $comp_bir $bar_base $comp_blk_offset]
  set cachemem_base [expr {$comp_base + $CXL_CACHEMEM_OFFSET}]
  puts [format "CXL.cachemem register base = 0x%016X" $cachemem_base]

  # Step 4: walk the CXL Capability array for the HDM Decoder Capability.
  set hdm_ptr [find_hdm_decoder_cap $cachemem_base]
  if {$hdm_ptr == -1} {
    error "CXL HDM Decoder Capability (ID 0x0005) not found -- device may not support HDM decode via Component Registers"
  }
  set hdm_base [expr {$cachemem_base + $hdm_ptr}]
  puts [format "CXL HDM Decoder Capability Structure base = 0x%016X" $hdm_base]

  set hdm_cap_dw    [control::rd32 $hdm_base]
  set decoder_enc   [expr {$hdm_cap_dw & 0xF}]
  set coherency     [expr {($hdm_cap_dw >> 21) & 0x3}]
  set decoder_count [decoder_count_raw $decoder_enc]
  puts [format "CXL HDM Decoder Capability : Decoder_Count=%d" $decoder_count]
  set target_range_type [choose_target_range_type $coherency]

  # Step 4c: program Decoder 0 with the real (combined) target range.
  set base_hi [expr {($HDM_BASE >> 32) & 0xFFFFFFFF}]
  set base_lo [expr {$HDM_BASE & 0xF0000000}]
  set size_hi [expr {($total_size >> 32) & 0xFFFFFFFF}]
  set size_lo [expr {$total_size & 0xF0000000}]

  control::wr32 [expr {$hdm_base + 0x10 + 0x04}] $base_hi
  control::wr32 [expr {$hdm_base + 0x10 + 0x00}] $base_lo
  control::wr32 [expr {$hdm_base + 0x10 + 0x0C}] $size_hi
  control::wr32 [expr {$hdm_base + 0x10 + 0x08}] $size_lo
  puts [format "  Decoder 0 : Base=0x%016X Size=0x%016X (%s)" $HDM_BASE $total_size [human_size $total_size]]

  set ctrl0 [expr {($target_range_type & 0x1) << 12}] ;# IG=0h IW=0h Lock_On_Commit=0
  control::wr32 [expr {$hdm_base + 0x10 + 0x10}] $ctrl0
  puts [format "  Decoder 0 Control=0x%08X (IG=0h IW=0h Target_Range_Type=%d)" $ctrl0 $target_range_type]
  commit_decoder $hdm_base 0 "real range"

  # Step 4d: park any remaining decoders (Base=Size=0, Committed) so every
  # implemented decoder ends up committed -- decoder m+1 can't commit
  # until decoder m is.
  for {set n 1} {$n < $decoder_count} {incr n} {
    set dec_off [expr {0x10 + $n * 0x20}]
    puts [format "  Parking unused Decoder %d (Base=Size=0)" $n]
    foreach o {0x00 0x04 0x08 0x0C 0x10} {
      control::wr32 [expr {$hdm_base + $dec_off + $o}] 0
    }
    commit_decoder $hdm_base $n "parked"
  }

  # Step 5: set HDM Decoder Enable in the Global Control Register.
  set gc_addr [expr {$hdm_base + 0x04}]
  set gc_val  [control::rd32 $gc_addr]
  set gc_val  [expr {$gc_val | (1 << 1)}]
  control::wr32 $gc_addr $gc_val
  puts [format "  HDM Decoder Global Control <= 0x%08X (HDM_Decoder_Enable=1)" $gc_val]

  puts ""
  print_decoders $hdm_base $decoder_count
  puts ""
  show_cxl ep 0x0
  return
}

#----------------------------------------------------------------------------
# Entry point
#----------------------------------------------------------------------------
proc ecam::setup_hdm {args} {
  lassign $args mode
  require_present ep
  switch -- $mode {
    range   { setup_hdm_range }
    decoder { setup_hdm_decoder }
    default { error "unknown ecam::setup_hdm mode '$mode' (expected one of: range, decoder)" }
  }
  return
}
