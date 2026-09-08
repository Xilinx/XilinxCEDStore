# ecam_cmds.tcl
#
# PCIe/CXL configuration-space access: BARs, standard capability list, PCIe
# extended capability list, CXL DVSEC discovery/decode. "ecam" here is two
# fixed flat config-space windows (rp/ep), NOT real {bus,device,function}-
# indexed ACPI/MCFG-style ECAM -- this design has a single fixed Root Port
# and a single attached downstream device, so there is no bus topology to
# enumerate.
#
# Every register read below is printed in one tabular line via print_cfg:
#   CFG | TAG    | 0xOFF = 0xVALUE : {description}
# TAG is "HEADER" for offset<0x40 (the standard config-space header, via
# cfg_tag), or an explicit CAP/ECAP/DVSEC tag for anything discovered by
# walking a capability/DVSEC list. id/read_bars/walk_caps/walk_ext_caps/
# report all take a target of "rp", "ep", or "both" (the default), printing
# a one-line section header ("RP : Local Access | ECAM Base: 0x..." / "EP :
# Remote Access | ECAM Base: 0x...") before each target's dump whenever more
# than one target is in play.

#----------------------------------------------------------------------------
# APU (Cortex-A72 #0) xsdb target connect
#----------------------------------------------------------------------------
# Selects the Cortex-A72 #0 xsdb target and clears its registers. Some
# ecam:: workflows on real hardware need the APU target specifically to
# reach EP config space / Component Registers via iATU. Independent of
# design::connect -- it's purely a board-specific target-selection step,
# not this package's shared register-access prerequisite.
proc ecam::connect {} {
  targets -set -filter {name =~ "*Cortex-A72 #0*"}
  puts "INFO: ecam connected to target [design::current_target_desc]"
  if {[catch {rst -proc -clear-registers} err]} {
    error "APU rst -proc failed: $err"
  }
  puts "INFO: APU registers cleared (rst -proc -clear-registers)"
}

#----------------------------------------------------------------------------
# Target resolution / address helpers
#----------------------------------------------------------------------------
proc ecam::get_base {target} {
  variable BASE
  if {[info exists BASE($target)]} { return $BASE($target) }
  error "unknown ecam target '$target' (expected one of: $::ecam::TARGET_NAMES)"
}

# Resolves the "target" argument shared by id/read_bars/walk_caps/
# walk_ext_caps: "rp" or "ep" alone, or "both" (also the default, i.e. "" --
# no argument given) for the two together.
proc ecam::resolve_targets {target} {
  if {$target eq "" || $target eq "both"} { return {rp ep} }
  if {$target eq "rp" || $target eq "ep"} { return [list $target] }
  error "unknown ecam target '$target' (expected one of: rp, ep, both)"
}

proc ecam::get_cfg_addr {target offset} { return [expr {[get_base $target] + $offset}] }

proc ecam::cfg_read {args} {
  lassign $args target offset
  return [control::rd32 [get_cfg_addr $target $offset]]
}

proc ecam::cfg_write {args} {
  lassign $args target offset value
  control::wr32 [get_cfg_addr $target $offset] $value
  puts "INFO: $target config offset 0x[format %03X $offset] <= 0x[format %08X $value]"
}

#----------------------------------------------------------------------------
# Display helpers -- every higher-level command below prints its reads in
# this tabular "CFG | TAG | offset = value : {desc}" style: TAG is "HEADER"
# for offset<0x40 (the standard config-space header), or an explicit tag
# (CAP/ECAP/DVSEC) for anything discovered by walking a list.
#----------------------------------------------------------------------------
proc ecam::print_cfg {tag offset val desc} {
  puts [format "CFG | %-6s | 0x%03X = %s : {%s}" $tag $offset $val $desc]
}

proc ecam::cfg_tag {offset} {
  return [expr {$offset < 0x40 ? "HEADER" : ""}]
}

# One-line section header + underline (with the target's ECAM base
# address), printed before each target's dump whenever id/read_bars/
# walk_caps/walk_ext_caps/report are scanning more than one target.
proc ecam::print_target_header {target} {
  switch -- $target {
    rp      { set label "RP : Local Access" }
    ep      { set label "EP : Remote Access" }
    default { set label "$target : Config Space" }
  }
  set header [format "%s | ECAM Base: 0x%08X" $label [get_base $target]]
  puts ""
  puts $header
  puts [string repeat "-" [string length $header]]
}

# All-Fs at offset 0 is the standard PCI "no device present" indicator. Every
# higher-level command below calls this first so a missing/unplugged ep
# fails fast instead of silently walking a garbage capability chain.
proc ecam::require_present {target} {
  set idw [control::rd32 [get_cfg_addr $target 0x0]]
  if {$idw == 0xFFFFFFFF} {
    error "ecam target '$target' reads all-Fs at offset 0 -- no device present (link down, or nothing attached for 'ep')"
  }
  return $idw
}

#----------------------------------------------------------------------------
# Vendor/Device ID
#----------------------------------------------------------------------------
proc ecam::id {args} {
  lassign $args target
  set targets [resolve_targets $target]
  set multi [expr {[llength $targets] > 1}]
  foreach t $targets {
    if {$multi} { print_target_header $t }
    if {$multi} {
      if {[catch {require_present $t} idw]} { puts "  (unavailable: $idw)"; continue }
    } else {
      set idw [require_present $t]
    }
    print_cfg [cfg_tag 0x0] 0x0 [format 0x%08X $idw] "Device ID, Vendor ID"
  }
  return
}

#----------------------------------------------------------------------------
# BARs
#----------------------------------------------------------------------------
proc ecam::decode_bar {raw} {
  if {($raw & 0x1) == 1} { return [list "IO" 0] }
  set type     [expr {($raw >> 1) & 0x3}]
  set prefetch [expr {($raw >> 3) & 0x1}]
  set width [expr {$type == 2 ? "64b" : ($type == 0 ? "32b" : [format "RSVD Type=0x%X" $type])}]
  set result "Memory, $width"
  if {$prefetch} { append result ", pre-fetchable" }
  return [list $result [expr {$type == 2}]]
}

# rp (Type 1) has 2 BAR slots; ep (Type 0) has 6 -- see ecam::BAR_COUNT.
# A 64-bit BAR consumes the following slot for its upper 32 bits, reported
# as "Upper" rather than re-decoded as its own BAR. NOTE: a Root Port's own
# BARs are of limited standalone interest (they map its own Component
# Registers, not CXL traffic) -- the genuinely useful CXL address data
# (HDM decoder ranges) lives in the CXL Device DVSEC on the ep side, via
# ecam::show_cxl, not here.
proc ecam::read_bars {args} {
  lassign $args target
  set targets [resolve_targets $target]
  set multi [expr {[llength $targets] > 1}]
  variable BAR_COUNT
  foreach t $targets {
    if {$multi} { print_target_header $t }
    if {$multi} {
      if {[catch {require_present $t} err]} { puts "  (unavailable: $err)"; continue }
    } else {
      require_present $t
    }
    set count [expr {[info exists BAR_COUNT($t)] ? $BAR_COUNT($t) : 6}]
    set skip_next 0
    for {set i 0} {$i < $count} {incr i} {
      set offset [expr {0x10 + $i * 4}]
      if {$skip_next} {
        set raw [cfg_read $t $offset]
        print_cfg [cfg_tag $offset] $offset [format 0x%08X $raw] [format "BAR%d: Upper" $i]
        set skip_next 0
        continue
      }
      set raw [cfg_read $t $offset]
      lassign [decode_bar $raw] details is64
      print_cfg [cfg_tag $offset] $offset [format 0x%08X $raw] [format "BAR%d: %s" $i $details]
      set skip_next $is64
    }
  }
  return
}

#----------------------------------------------------------------------------
# Standard PCI capability list (offset 0x34 -> linked list via next-ptr byte)
#----------------------------------------------------------------------------
proc ecam::walk_caps {args} {
  lassign $args target
  set targets [resolve_targets $target]
  set multi [expr {[llength $targets] > 1}]
  variable PCI_CAP_NAMES
  foreach t $targets {
    if {$multi} { print_target_header $t }
    if {$multi} {
      if {[catch {require_present $t} err]} { puts "  (unavailable: $err)"; continue }
    } else {
      require_present $t
    }
    set ptr [expr {[cfg_read $t 0x34] & 0xFC}]
    set seen {}
    while {$ptr != 0} {
      if {$ptr in $seen} {
        puts "WARNING: $t cap list loop detected at 0x[format %02X $ptr] -- stopping"
        break
      }
      lappend seen $ptr
      set hdr [cfg_read $t $ptr]
      set cap_id   [expr {$hdr & 0xFF}]
      set next_ptr [expr {($hdr >> 8) & 0xFC}]
      set key [format 0x%02X $cap_id]
      set name [expr {[info exists PCI_CAP_NAMES($key)] ? $PCI_CAP_NAMES($key) : "Unknown ($key)"}]
      print_cfg CAP $ptr [format 0x%08X $hdr] $name
      set ptr $next_ptr
    }
  }
  return
}

#----------------------------------------------------------------------------
# PCIe extended capability list (offset 0x100 -> linked list via 12-bit
# next-offset field in each 32-bit DW0 header)
#----------------------------------------------------------------------------
proc ecam::walk_ext_caps {args} {
  lassign $args target
  set targets [resolve_targets $target]
  set multi [expr {[llength $targets] > 1}]
  variable PCIE_EXT_CAP_NAMES
  variable DVSEC_EXT_CAP_ID
  variable CXL_VENDOR_ID
  variable CXL_DVSEC_ID_NAMES
  set result {}
  foreach t $targets {
    if {$multi} { print_target_header $t }
    if {$multi} {
      if {[catch {require_present $t} err]} { puts "  (unavailable: $err)"; continue }
    } else {
      require_present $t
    }
    set offset 0x100
    set seen {}
    set caps {}
    while {$offset != 0} {
      if {$offset in $seen} {
        puts "WARNING: $t ext cap list loop detected at 0x[format %03X $offset] -- stopping"
        break
      }
      lappend seen $offset
      set hdr [cfg_read $t $offset]
      set cap_id   [expr {$hdr & 0xFFFF}]
      set version  [expr {($hdr >> 16) & 0xF}]
      set next_off [expr {($hdr >> 20) & 0xFFF}]
      set key [format 0x%04X $cap_id]
      set name [expr {[info exists PCIE_EXT_CAP_NAMES($key)] ? $PCIE_EXT_CAP_NAMES($key) : "Unknown ($key)"}]
      # A DVSEC's generic "Designated Vendor-Specific Extended (DVSEC)" name
      # is useless on its own -- peek at its DVSEC Header 1/2 (+0x04/+0x08)
      # right here and print the specific CXL DVSEC name instead (find_cxl
      # still separately filters/returns the CXL subset, but doesn't print,
      # so each DVSEC is labeled exactly once).
      set print_name $name
      if {$cap_id == $DVSEC_EXT_CAP_ID} {
        set dvsec_vendor_id [expr {[cfg_read $t [expr {$offset + 0x04}]] & 0xFFFF}]
        if {$dvsec_vendor_id == $CXL_VENDOR_ID} {
          set dvsec_id [expr {[cfg_read $t [expr {$offset + 0x08}]] & 0xFFFF}]
          set dkey [format 0x%04X $dvsec_id]
          set dname [expr {[info exists CXL_DVSEC_ID_NAMES($dkey)] ? $CXL_DVSEC_ID_NAMES($dkey) : "Unknown CXL DVSEC ($dkey)"}]
          set print_name [format "%s (ID=0x%X)" $dname $dvsec_id]
        }
      }
      lappend caps [dict create offset $offset cap_id $cap_id version $version name $name next $next_off]
      print_cfg ECAP $offset [format 0x%08X $hdr] $print_name
      set offset $next_off
    }
    # Only a single, explicit target's caps list is ever returned -- the
    # only internal consumer (find_cxl's fallback) always calls this with
    # one literal target, never "both". Returning something meaningful for
    # a multi-target scan isn't needed and would just re-introduce the
    # dict/list auto-echo problem id/read_bars/walk_caps were fixed for.
    if {!$multi} { set result $caps }
  }
  return $result
}

#----------------------------------------------------------------------------
# CXL DVSEC discovery
#----------------------------------------------------------------------------
# A DVSEC is a PCIe Extended Capability with cap_id == DVSEC_EXT_CAP_ID
# (0x0023) whose DVSEC Header 1 Vendor ID field == CXL_VENDOR_ID (0x1E98).
# Layout (PCIe Base Spec 7.9.6): DW0 Ext Cap Header (+0x00), DW1 DVSEC
# Header 1 -- length[31:20] revision[19:16] vendor_id[15:0] (+0x04), DW2
# DVSEC Header 2 -- dvsec_id[15:0] (+0x08), DW3+ vendor-specific (+0x0C).
#
# Purely a data filter -- prints nothing. walk_ext_caps already prints every
# CXL DVSEC's specific name (e.g. "Register Locator DVSEC (ID=0x8)") inline
# as it walks the extended capability list; ecam::show_cxl does its own
# independent walk for its verbose dump rather than building on this.
proc ecam::find_cxl {args} {
  lassign $args target ext_caps
  variable DVSEC_EXT_CAP_ID
  variable CXL_VENDOR_ID
  variable CXL_DVSEC_ID_NAMES
  # ext_caps is an optional pre-fetched result from walk_ext_caps, to avoid
  # walking (and printing) the extended capability list a second time.
  if {$ext_caps eq ""} { set ext_caps [walk_ext_caps $target] }
  set found {}
  foreach cap $ext_caps {
    if {[dict get $cap cap_id] != $DVSEC_EXT_CAP_ID} { continue }
    set off [dict get $cap offset]
    set dw1 [cfg_read $target [expr {$off + 0x04}]]
    set vendor_id [expr {$dw1 & 0xFFFF}]
    if {$vendor_id != $CXL_VENDOR_ID} { continue }
    set revision [expr {($dw1 >> 16) & 0xF}]
    set length [expr {($dw1 >> 20) & 0xFFF}]
    set dw2 [cfg_read $target [expr {$off + 0x08}]]
    set dvsec_id [expr {$dw2 & 0xFFFF}]
    set key [format 0x%04X $dvsec_id]
    set name [expr {[info exists CXL_DVSEC_ID_NAMES($key)] ? $CXL_DVSEC_ID_NAMES($key) : "Unknown CXL DVSEC ($key)"}]
    lappend found [dict create offset $off dvsec_id $dvsec_id name $name revision $revision length $length]
  }
  return $found
}

#----------------------------------------------------------------------------
# CXL DVSEC verbose decode
#----------------------------------------------------------------------------
# Per-DWORD label for a CXL DVSEC, by DVSEC ID (CXL 3.x Sec. 8.1.3-8.1.10).
# Many CXL registers are 16-bit sub-registers packed two to a DWORD; DW2's
# lower word is always dvsec_id, its upper word the first vendor register.
proc ecam::cxl_dw_label {dvsec_id i} {
  switch [format 0x%04X $dvsec_id] {
    0x0000 {
      switch $i {
        2  { return "CXL Cap\[31:16\] | DVSEC_ID\[15:0\]" }
        3  { return "CXL Status\[31:16\] | CXL Control\[15:0\]" }
        4  { return "CXL Status2\[31:16\] | CXL Control2\[15:0\]" }
        5  { return "CXL Cap2\[31:16\] | CXL Lock\[15:0\]" }
        6  { return "Range 1 Size High\[31:0\]" }
        7  { return "Range 1 Size Low\[31:0\]" }
        8  { return "Range 1 Base High\[31:0\]" }
        9  { return "Range 1 Base Low\[31:0\]" }
        10 { return "Range 2 Size High\[31:0\]" }
        11 { return "Range 2 Size Low\[31:0\]" }
        12 { return "Range 2 Base High\[31:0\]" }
        13 { return "Range 2 Base Low\[31:0\]" }
        14 { return "CXL Cap3\[15:0\]" }
        default { return [format "Vendor DW%d" [expr {$i - 3}]] }
      }
    }
    0x0002 {
      if {$i == 2} { return "Reserved\[31:16\] | DVSEC_ID\[15:0\]" }
      set m [expr {$i - 3}]
      if {$m >= 0 && $m < 8} { return [format "Non-CXL Function Map Register %d" $m] }
      return [format "Vendor DW%d" [expr {$i - 3}]]
    }
    0x0003 {
      switch $i {
        2 { return "Port Ext Status\[31:16\] | DVSEC_ID\[15:0\]" }
        3 { return "Alt Bus Limit/Base\[31:16\] | Port Ctrl Ext\[15:0\]" }
        4 { return "Alt Mem Limit\[31:16\] | Alt Mem Base\[15:0\]" }
        5 { return "Alt PF Mem Limit\[31:16\] | Alt PF Mem Base\[15:0\]" }
        6 { return "Alt PF Mem Base High\[31:0\]" }
        7 { return "Alt PF Mem Limit High\[31:0\]" }
        8 { return "CXL RCRB Base Low\[31:0\]" }
        9 { return "CXL RCRB Base High\[31:0\]" }
        default { return [format "Vendor DW%d" [expr {$i - 3}]] }
      }
    }
    0x0004 {
      switch $i {
        2 { return "Reserved\[31:16\] | DVSEC_ID\[15:0\]" }
        3 { return "GPF Phase 2 Control\[31:16\] | GPF Phase 1 Control\[15:0\]" }
        default { return [format "Vendor DW%d" [expr {$i - 3}]] }
      }
    }
    0x0005 {
      switch $i {
        2 { return "GPF Phase 2 Duration\[31:16\] | DVSEC_ID\[15:0\]" }
        3 { return "GPF Phase 2 Power\[31:0\]" }
        default { return [format "Vendor DW%d" [expr {$i - 3}]] }
      }
    }
    0x0007 {
      switch $i {
        2 { return "FlexBus Port Cap\[31:16\] | DVSEC_ID\[15:0\]" }
        3 { return "FlexBus Port Status\[31:16\] | FlexBus Port Control\[15:0\]" }
        4 { return "FlexBus Port Status2\[31:16\] | FlexBus Port Control2\[15:0\]" }
        default { return [format "Vendor DW%d" [expr {$i - 3}]] }
      }
    }
    0x0008 {
      if {$i == 2} { return "Reserved\[31:16\] | DVSEC_ID\[15:0\]" }
      set pair_dw [expr {$i - 3}]
      set pair    [expr {$pair_dw / 2}]
      if {($pair_dw % 2) == 0} {
        return [format "Reg Block %d | Offset Low\[31:0\]" $pair]
      } else {
        return [format "Reg Block %d | Offset High\[31:0\]" $pair]
      }
    }
    0x0009 {
      switch $i {
        2 { return "Num LD Supported\[31:16\] | DVSEC_ID\[15:0\]" }
        3 { return "LD-ID Hot Reset Vector\[15:0\]" }
        default { return [format "Vendor DW%d" [expr {$i - 3}]] }
      }
    }
    default {
      if {$i == 2} { return "Reserved\[31:16\] | DVSEC_ID\[15:0\]" }
      return [format "Vendor DW%d" [expr {$i - 3}]]
    }
  }
}

proc ecam::dvsec_dw_label {dvsec_id i} {
  switch $i {
    0 { return "Ext Cap Hdr : NextOff\[31:20\] | Version\[19:16\] | ID\[15:0\]" }
    1 { return "DVSEC Hdr 1 : Length\[31:20\] | Revision\[19:16\] | VendorID\[15:0\]" }
    default { return [cxl_dw_label $dvsec_id $i] }
  }
}

# -- Register Locator DVSEC (0x0008) field-name helpers (CXL 3.x 8.1.9) --
proc ecam::bir_name {bir} {
  switch $bir {
    0 - 1 - 2 - 3 - 4 - 5 { return "BAR $bir" }
    default { return [format "Reserved (0x%X)" $bir] }
  }
}

proc ecam::reg_blk_type_name {id} {
  switch [format 0x%02X $id] {
    0x00 { return "Empty/Invalid" }
    0x01 { return "Component Registers" }
    0x02 { return "BAR Virtualization ACL Registers" }
    0x03 { return "CXL Device Registers" }
    0x04 { return "CPMU Registers" }
    0xFF { return "Designated Vendor Specific" }
    default { return [format "Reserved (0x%02X)" $id] }
  }
}

# Prints the decode for one {Offset Low, Offset High} register-block pair.
proc ecam::print_reg_block_decode {offset_low offset_high rel_low rel_high} {
  set bir      [expr {$offset_low & 0x7}]
  set blk_type [expr {($offset_low >> 8) & 0xFF}]
  set off_lo   [expr {($offset_low >> 16) & 0xFFFF}]
  if {$blk_type == 0} {
    puts [format "              0x%02X\[15: 8\]        || Block Type : Empty" $rel_low]
  } else {
    puts [format "              0x%02X\[15: 8\]        || Block Type : %s (0x%02X)" $rel_low [reg_blk_type_name $blk_type] $blk_type]
    puts [format "              0x%02X\[ 2: 0\]        || BIR        : %s" $rel_low [bir_name $bir]]
    puts [format "              {0x%02X,0x%02X\[31:16\]} || Offset     : 0x%08X_%04X0000" $rel_high $rel_low $offset_high $off_lo]
  }
}

# -- PCIe DVSEC for Flex Bus Port (0x0007) field decode (CXL 3.x 8.1.8) --
proc ecam::print_flexbus_cap_decode {dw_val rel_off} {
  set sub_off [expr {$rel_off + 2}]
  set cap     [expr {($dw_val >> 16) & 0xFFFF}]
  puts [format "              0x%02X\[0\] || Cache_Capable           : %d" $sub_off [expr {($cap >> 0) & 1}]]
  puts [format "              0x%02X\[1\] || IO_Capable              : %d" $sub_off [expr {($cap >> 1) & 1}]]
  puts [format "              0x%02X\[2\] || Mem_Capable             : %d" $sub_off [expr {($cap >> 2) & 1}]]
  puts [format "              0x%02X\[5\] || 68B Flit and VH Capable : %d" $sub_off [expr {($cap >> 5) & 1}]]
}

proc ecam::print_flexbus_status_decode {dw_val rel_off} {
  set sub_off [expr {$rel_off + 2}]
  set sts     [expr {($dw_val >> 16) & 0xFFFF}]
  puts [format "              0x%02X\[0\] || Cache_Enabled           : %d" $sub_off [expr {($sts >> 0) & 1}]]
  puts [format "              0x%02X\[1\] || IO_Enabled              : %d" $sub_off [expr {($sts >> 1) & 1}]]
  puts [format "              0x%02X\[2\] || Mem_Enabled             : %d" $sub_off [expr {($sts >> 2) & 1}]]
  puts [format "              0x%02X\[5\] || 68B Flit and VH Enabled : %d" $sub_off [expr {($sts >> 5) & 1}]]
}

# -- PCIe DVSEC for CXL Devices (0x0000) field decode (CXL 3.x 8.1.3) --
proc ecam::print_cxl_dev_cap_decode {dw_val rel_off} {
  set sub_off [expr {$rel_off + 2}]
  set cap     [expr {($dw_val >> 16) & 0xFFFF}]
  set hdm     [expr {($cap >> 4) & 0x3}]
  set hdm_str [lindex {"Zero ranges" "One HDM range" "Two HDM ranges" "Reserved"} $hdm]
  puts [format "              0x%02X\[0\]   || Cache_Capable                    : %d" $sub_off [expr {($cap >> 0) & 1}]]
  puts [format "              0x%02X\[1\]   || IO_Capable                       : %d" $sub_off [expr {($cap >> 1) & 1}]]
  puts [format "              0x%02X\[2\]   || Mem_Capable                      : %d" $sub_off [expr {($cap >> 2) & 1}]]
  puts [format "              0x%02X\[5:4\] || HDM_Count                        : %d (%s)" $sub_off $hdm $hdm_str]
  puts [format "              0x%02X\[7\]   || CXL Reset Capable                : %d" $sub_off [expr {($cap >> 7) & 1}]]
  puts [format "              0x%02X\[15\]  || PM Init Completion Reporting Cap : %d" $sub_off [expr {($cap >> 15) & 1}]]
}

proc ecam::print_cxl_dev_ctrl_decode {dw_val rel_off} {
  set ctrl [expr {$dw_val & 0xFFFF}]
  puts [format "              0x%02X\[0\]   || Cache_Enable                     : %d" $rel_off [expr {($ctrl >> 0) & 1}]]
  puts [format "              0x%02X\[1\]   || IO_Enable                        : %d" $rel_off [expr {($ctrl >> 1) & 1}]]
  puts [format "              0x%02X\[2\]   || Mem_Enable                       : %d" $rel_off [expr {($ctrl >> 2) & 1}]]
}

proc ecam::print_cxl_dev_status2_decode {dw_val rel_off} {
  set sub_off [expr {$rel_off + 2}]
  set sts2    [expr {($dw_val >> 16) & 0xFFFF}]
  puts [format "              0x%02X\[15\]  || PM Init Complete                 : %d" $sub_off [expr {($sts2 >> 15) & 1}]]
}

# Verbose DWORD-by-DWORD dump of every CXL DVSEC found on a target, or just
# a single one, if given: either its dvsec_offset, or its dvsec_id -- a
# value is treated as a dvsec_id when it's one of the entries CXL_DVSEC_ID_
# NAMES actually defines (0x0, 0x2-0x5, 0x7-0xA); any other value (real
# capability offsets are always >= 0x100, well outside that range, so
# there's no ambiguity) is treated as a raw dvsec_offset instead. Runs its
# own extended-capability-list walk rather than building on walk_ext_caps/
# find_cxl, since this prints in its own detailed per-DWORD-label style,
# not the CFG-table style the rest of ecam:: uses. Field-level decode is
# added for the 3 most useful DVSEC IDs; any other DVSEC ID gets the
# labeled DW dump only:
#   0x0000 PCIe DVSEC for CXL Devices  -- cache/io/mem capable+enable, plus
#          HDM decoder Range1/Range2 base+size (HDM ranges live HERE, not
#          in a BAR -- see ecam::read_bars's note)
#   0x0007 PCIe DVSEC for Flex Bus Port -- cache/io/mem capable+enable,
#          68B-Flit-and-VH capable/enabled (cross-references
#          design::check_link_status's Flit-mode print -- a different,
#          non-config-space register showing a related concept)
#   0x0008 Register Locator DVSEC -- BIR + block-type + offset per register
#          block (where CXL.io/cache/mem Component/Device registers live)
proc ecam::show_cxl {args} {
  lassign $args target dvsec_arg
  set targets [resolve_targets $target]
  set multi [expr {[llength $targets] > 1}]
  variable DVSEC_EXT_CAP_ID
  variable CXL_VENDOR_ID
  variable CXL_DVSEC_ID_NAMES
  set filter_mode ""
  set filter_val ""
  if {$dvsec_arg ne ""} {
    set filter_val [expr {$dvsec_arg}]
    set filter_mode [expr {[info exists CXL_DVSEC_ID_NAMES([format 0x%04X $filter_val])] ? "id" : "offset"}]
  }
  foreach t $targets {
    if {$multi} { print_target_header $t }
    if {$multi} {
      if {[catch {require_present $t} err]} { puts "  (unavailable: $err)"; continue }
    } else {
      require_present $t
    }
    set offset 0x100
    set seen {}
    set count 0
    while {$offset != 0} {
      if {$offset in $seen} {
        puts "WARNING: $t ext cap list loop detected at 0x[format %03X $offset] -- stopping"
        break
      }
      lappend seen $offset
      set hdr      [cfg_read $t $offset]
      set cap_id   [expr {$hdr & 0xFFFF}]
      set next_off [expr {($hdr >> 20) & 0xFFF}]
      if {$cap_id != $DVSEC_EXT_CAP_ID} { set offset $next_off; continue }
      set dw1       [cfg_read $t [expr {$offset + 0x04}]]
      set vendor_id [expr {$dw1 & 0xFFFF}]
      if {$vendor_id != $CXL_VENDOR_ID} { set offset $next_off; continue }
      set dw2      [cfg_read $t [expr {$offset + 0x08}]]
      set dvsec_id [expr {$dw2 & 0xFFFF}]
      if {$filter_mode eq "offset" && $offset != $filter_val} { set offset $next_off; continue }
      if {$filter_mode eq "id" && $dvsec_id != $filter_val} { set offset $next_off; continue }
      incr count
      set revision  [expr {($dw1 >> 16) & 0xF}]
      set dvsec_len [expr {($dw1 >> 20) & 0xFFF}]
      set key [format 0x%04X $dvsec_id]
      set name [expr {[info exists CXL_DVSEC_ID_NAMES($key)] ? $CXL_DVSEC_ID_NAMES($key) : "Unknown CXL DVSEC ($key)"}]

      puts ""
      puts [format "  DVSEC #%d @ offset 0x%03X" $count $offset]
      puts [format "    DVSEC ID : 0x%04X  (%s)" $dvsec_id $name]
      puts [format "    Revision : 0x%X" $revision]
      puts [format "    Length   : %d bytes (0x%03X) -- 3 mandatory header DWs + %d vendor DWs" \
        $dvsec_len $dvsec_len [expr {$dvsec_len > 12 ? ($dvsec_len - 12) / 4 : 0}]]
      puts ""

      if {$dvsec_len < 12} {
        puts "    ERROR: Length $dvsec_len < 12 minimum -- skipping DVSEC body"
        set offset $next_off
        continue
      }

      set num_dwords          [expr {($dvsec_len + 3) / 4}]
      set hdm_count           0
      set range_size_hi       0
      set range_size_hi_rel   0
      set range_size_lo_word  0
      set range_size_lo_rel   0
      set range_info_valid    0
      set range_mem_active    0
      set range_base_hi       0
      set range_base_hi_rel   0
      set reglocator_low_val  0
      set reglocator_low_rel  0

      for {set i 0} {$i < $num_dwords} {incr i} {
        set rel_off [expr {$i * 4}]
        set dw_val  [cfg_read $t [expr {$offset + $rel_off}]]
        set tag     [dvsec_dw_label $dvsec_id $i]

        set na_sfx ""
        if {$dvsec_id == 0x0000} {
          if {$i == 2} { set hdm_count [expr {($dw_val >> 20) & 0x3}] }
          if {$i >= 6 && $i <= 9} {
            if {$hdm_count == 0 || $hdm_count == 3} { set na_sfx " -- N/A" }
          }
          if {$i >= 10 && $i <= 13} {
            if {$hdm_count < 2 || $hdm_count == 3} { set na_sfx " -- N/A" }
          }
        }

        puts [format "    DW%2d (0x%02X) = 0x%08X  {%s}%s" $i $rel_off $dw_val $tag $na_sfx]

        if {$dvsec_id == 0x0000} {
          if {$i == 2} { print_cxl_dev_cap_decode     $dw_val $rel_off }
          if {$i == 3} { print_cxl_dev_ctrl_decode    $dw_val $rel_off }
          if {$i == 4} { print_cxl_dev_status2_decode $dw_val $rel_off }
          if {$i == 5} {
            puts [format "              0x%02X\[0\]   || Config_Lock : %d" $rel_off [expr {$dw_val & 1}]]
          }
          if {$na_sfx eq "" && (($i >= 6 && $i <= 9) || ($i >= 10 && $i <= 13))} {
            set range_i [expr {($i >= 10) ? ($i - 10) : ($i - 6)}]
            switch $range_i {
              0 {
                set range_size_hi     $dw_val
                set range_size_hi_rel $rel_off
              }
              1 {
                set range_info_valid   [expr {$dw_val & 1}]
                set range_mem_active   [expr {($dw_val >> 1) & 1}]
                set range_size_lo_word [expr {$dw_val & 0xF0000000}]
                set range_size_lo_rel  $rel_off
              }
              2 {
                set range_base_hi     $dw_val
                set range_base_hi_rel $rel_off
              }
              3 {
                set base_lo_word [expr {$dw_val & 0xF0000000}]
                puts [format "              0x%02X\[0\]                  || Memory_Info_Valid : %d" $range_size_lo_rel $range_info_valid]
                puts [format "              0x%02X\[1\]                  || Memory_Active     : %d" $range_size_lo_rel $range_mem_active]
                puts [format "              {0x%02X\[31:0\],0x%02X\[31:28\]} || Memory_Size       : 0x%08X_%08X" \
                  $range_size_hi_rel $range_size_lo_rel $range_size_hi $range_size_lo_word]
                puts [format "              {0x%02X\[31:0\],0x%02X\[31:28\]} || Memory_Base       : 0x%08X_%08X" \
                  $range_base_hi_rel $rel_off $range_base_hi $base_lo_word]
              }
            }
          }
        }

        if {$dvsec_id == 0x0007} {
          if {$i == 2} { print_flexbus_cap_decode    $dw_val $rel_off }
          if {$i == 3} { print_flexbus_status_decode $dw_val $rel_off }
        }

        if {$dvsec_id == 0x0008 && $i >= 3} {
          set pair_dw [expr {$i - 3}]
          if {($pair_dw % 2) == 0} {
            set reglocator_low_val $dw_val
            set reglocator_low_rel $rel_off
          } else {
            print_reg_block_decode $reglocator_low_val $dw_val $reglocator_low_rel $rel_off
          }
        }
      }

      set offset $next_off
    }
    if {$count == 0} {
      if {$filter_mode ne "" && !$multi} {
        if {$filter_mode eq "id"} {
          error [format "no CXL DVSEC with ID 0x%X found on target %s" $filter_val $t]
        } else {
          error "no CXL DVSEC found at offset $dvsec_arg on target $t"
        }
      }
      puts "  (no CXL DVSECs found)"
    } else {
      puts ""
      puts "  Total CXL DVSECs: $count"
    }
  }
  return
}

#----------------------------------------------------------------------------
# EP BAR sizing + placement
#----------------------------------------------------------------------------
# Performs the BAR sizing/assignment system firmware would normally do
# during PCIe enumeration: probes each of the EP's 6 BAR registers (cfg
# offset 0x10-0x24) to see which are implemented and how large they are,
# programs each with a base address carved out of a host MMIO window, then
# widens the RP's Type 1 prefetchable memory window to forward accesses to
# them. Must run before anything that accesses the EP's BAR-mapped memory
# (e.g. CXL Component Registers reached via a Register Locator DVSEC block
# -- see ecam::show_cxl).
proc ecam::human_size {bytes} {
  if {$bytes >= 0x40000000} {
    return [format "%.2f GB" [expr {double($bytes) / 0x40000000}]]
  } elseif {$bytes >= 0x100000} {
    return [format "%.2f MB" [expr {double($bytes) / 0x100000}]]
  } elseif {$bytes >= 0x400} {
    return [format "%.2f KB" [expr {double($bytes) / 0x400}]]
  } else {
    return [format "%d B" $bytes]
  }
}

# Sizes a single BAR at index bir on target. Returns {} if unimplemented,
# else {size prefetch}. Only 64-bit Memory BARs are supported -- the host
# MMIO windows handed out (ALLOC_BASE_LOW/HIGH) sit entirely above 4 GB, so
# a 32-bit BAR could never be programmed with an address in either one.
# Every implemented BAR's original value (and, for 64-bit, its upper
# DWORD's) is restored immediately after sizing, so this never leaves a BAR
# in its transient all-1s-probing state -- including on the error paths.
proc ecam::size_bar {target bir} {
  set bar_off  [expr {0x10 + 4 * $bir}]
  set orig_lo  [cfg_read $target $bar_off]

  cfg_write_quiet $target $bar_off 0xFFFFFFFF
  set sized_lo [cfg_read $target $bar_off]
  cfg_write_quiet $target $bar_off $orig_lo

  if {$sized_lo == 0} {
    puts [format "  BAR%d @ cfg offset 0x%02X : unimplemented" $bir $bar_off]
    return {}
  }

  set space    [expr {$sized_lo & 0x1}]
  set bar_type [expr {($sized_lo >> 1) & 0x3}]
  set prefetch [expr {($sized_lo >> 3) & 0x1}]

  if {$space == 1} {
    error [format "BAR%d @ cfg offset 0x%02X is an I/O BAR -- no I/O space has been allocated for EP BAR placement" $bir $bar_off]
  }
  if {$bar_type == 0} {
    error [format "BAR%d @ cfg offset 0x%02X is a 32-bit Memory BAR -- only 64-bit BARs are supported (the allocated window is entirely above 4 GB)" $bir $bar_off]
  }
  if {$bar_type != 2} {
    error [format "BAR%d @ cfg offset 0x%02X has reserved Type field (0x%X)" $bir $bar_off $bar_type]
  }
  if {$bir >= 5} {
    error [format "BAR%d is marked 64-bit but BAR%d does not exist" $bir [expr {$bir + 1}]]
  }

  set bar_hi_off [expr {0x10 + 4 * ($bir + 1)}]
  set orig_hi    [cfg_read $target $bar_hi_off]

  cfg_write_quiet $target $bar_hi_off 0xFFFFFFFF
  set sized_hi [cfg_read $target $bar_hi_off]
  cfg_write_quiet $target $bar_hi_off $orig_hi

  set size_mask [expr {(wide($sized_hi) << 32) | ($sized_lo & 0xFFFFFFF0)}]
  set size      [expr {(-$size_mask) & 0xFFFFFFFFFFFFFFFF}]

  if {$size == 0 || ($size & ($size - 1)) != 0} {
    error [format "BAR%d sizing produced a non-power-of-2 or zero size (0x%X) -- sizing failed" $bir $size]
  }

  puts [format "  BAR%d @ cfg offset 0x%02X : 64-bit Memory BAR%s, Size=0x%X (%s)" \
    $bir $bar_off [expr {$prefetch ? ", Prefetchable" : ""}] $size [human_size $size]]
  return [list $size $prefetch]
}

# A config-space write with no per-write print -- used for the transient
# all-1s sizing probe in size_bar, where cfg_write's own "INFO: ... <= ..."
# line would be noise (the value is reverted a line later and never a
# meaningful final state).
proc ecam::cfg_write_quiet {target offset value} {
  control::wr32 [get_cfg_addr $target $offset] $value
}

# Writes the RP's Type 1 Prefetchable Memory Base/Limit registers (cfg
# offsets 0x24/0x28/0x2C) to forward the given [base, limit] range. Both
# registers use the 64-bit decoder encoding (capability field = 1), since
# the EP BAR windows sit entirely above 4 GB.
proc ecam::set_prefetch_window {base limit} {
  set base_lo  [expr {(($base  >> 16) & 0xFFF0) | 0x1}]
  set limit_lo [expr {(($limit >> 16) & 0xFFF0) | 0x1}]
  set reg_24   [expr {($limit_lo << 16) | $base_lo}]
  set reg_28   [expr {($base  >> 32) & 0xFFFFFFFF}]
  set reg_2c   [expr {($limit >> 32) & 0xFFFFFFFF}]

  print_cfg WRITE 0x24 [format 0x%08X $reg_24] [format "Prefetchable Mem Base/Limit : Base=0x%016X, Limit=0x%016X" $base $limit]
  control::wr32 [get_cfg_addr rp 0x24] $reg_24
  print_cfg WRITE 0x28 [format 0x%08X $reg_28] "Prefetchable Base Upper 32"
  control::wr32 [get_cfg_addr rp 0x28] $reg_28
  print_cfg WRITE 0x2C [format 0x%08X $reg_2c] "Prefetchable Limit Upper 32"
  control::wr32 [get_cfg_addr rp 0x2C] $reg_2c
}

# Sets the Memory Space Enable bit (Command register, cfg offset 0x4, bit
# 1) on both the EP and the RP, now that the EP's BARs hold valid addresses
# the RP is set up to forward.
proc ecam::set_mse {} {
  foreach t {ep rp} {
    set cmd     [cfg_read $t 0x4]
    set new_cmd [expr {$cmd | 0x2}]
    print_cfg WRITE 0x4 [format 0x%08X $new_cmd] "Command Register : Mem Space Enable"
    control::wr32 [get_cfg_addr $t 0x4] $new_cmd
  }
}

proc ecam::setup_ep_bars {} {
  variable ALLOC_BASE_LOW
  variable ALLOC_SIZE_LOW
  variable ALLOC_BASE_HIGH
  variable ALLOC_SIZE_HIGH
  require_present ep

  puts [format "Low  window: 0x%016X - 0x%016X (%s)" \
    $ALLOC_BASE_LOW [expr {$ALLOC_BASE_LOW + $ALLOC_SIZE_LOW - 1}] [human_size $ALLOC_SIZE_LOW]]
  puts [format "High window: 0x%016X - 0x%016X (%s, fallback only)" \
    $ALLOC_BASE_HIGH [expr {$ALLOC_BASE_HIGH + $ALLOC_SIZE_HIGH - 1}] [human_size $ALLOC_SIZE_HIGH]]

  # Pass 1: discover and size every BAR. An implemented (always 64-bit)
  # BAR consumes its own slot plus the next one (its upper DWORD), so the
  # index advances by 2; an unimplemented slot only advances by 1, in case
  # a later BAR is used independently.
  puts ""
  set bar_list {}
  set total_size 0
  set bir 0
  while {$bir <= 5} {
    set result [size_bar ep $bir]
    if {[llength $result] == 0} {
      incr bir
      continue
    }
    lassign $result size prefetch
    lappend bar_list [list $bir $size $prefetch]
    incr total_size $size
    incr bir 2
  }

  puts ""
  puts [format "Total BAR footprint (before alignment padding) = 0x%X (%s) across %d BAR(s)" \
    $total_size [human_size $total_size] [llength $bar_list]]

  # Pick the window to place every BAR in (never split across the two):
  # prefer the low window, falling back to the high one only if the
  # footprint doesn't fit in the low one.
  if {$total_size <= $ALLOC_SIZE_LOW} {
    set alloc_base $ALLOC_BASE_LOW
    set alloc_size $ALLOC_SIZE_LOW
    puts [format "Footprint fits in the low window -- placing EP memory at 0x%016X" $alloc_base]
  } else {
    set alloc_base $ALLOC_BASE_HIGH
    set alloc_size $ALLOC_SIZE_HIGH
    puts [format "Footprint exceeds the low window -- placing EP memory at 0x%016X" $alloc_base]
  }
  set alloc_limit [expr {$alloc_base + $alloc_size}]

  if {$total_size > $alloc_size} {
    error [format "sum of all EP BAR sizes (0x%X, %s) exceeds the allocated window size (0x%X, %s) -- cannot place these BARs" \
      $total_size [human_size $total_size] $alloc_size [human_size $alloc_size]]
  }

  # Pass 2: assign addresses incrementally, each BAR naturally aligned to
  # its own size (a BAR's low address bits below its size are hardwired to
  # 0, so anything less than natural alignment can't be programmed anyway).
  puts ""
  set cursor $alloc_base
  foreach entry $bar_list {
    lassign $entry bir size prefetch

    set aligned [expr {($cursor + $size - 1) & ~($size - 1)}]
    if {($aligned + $size) > $alloc_limit} {
      error [format "BAR%d (Size=0x%X) does not fit in the allocated window after alignment padding -- next aligned address 0x%016X + Size exceeds limit 0x%016X" \
        $bir $size $aligned $alloc_limit]
    }

    set bar_off    [expr {0x10 + 4 * $bir}]
    set bar_hi_off [expr {$bar_off + 4}]
    set assign_lo  [expr {$aligned & 0xFFFFFFFF}]
    set assign_hi  [expr {($aligned >> 32) & 0xFFFFFFFF}]

    print_cfg WRITE $bar_off [format 0x%08X $assign_lo] [format "BAR%d Low" $bir]
    control::wr32 [get_cfg_addr ep $bar_off] $assign_lo
    print_cfg WRITE $bar_hi_off [format 0x%08X $assign_hi] [format "BAR%d High : Base=0x%016X" $bir $aligned]
    control::wr32 [get_cfg_addr ep $bar_hi_off] $assign_hi

    set cursor [expr {$aligned + $size}]
  }

  # Program the RP's prefetchable memory window to cover every assigned BAR.
  puts ""
  set pf_base  [expr {$alloc_base & ~0xFFFFF}]
  set pf_limit [expr {($cursor - 1) | 0xFFFFF}]
  puts [format "RP prefetchable window (1MB-aligned): 0x%016X - 0x%016X" $pf_base $pf_limit]
  set_prefetch_window $pf_base $pf_limit

  # Seat Mem Space Enable now that the BARs hold valid addresses.
  puts ""
  set_mse

  variable EP_BARS_SETUP
  set EP_BARS_SETUP 1

  puts ""
  puts [format "DONE: %d BAR(s) assigned. Next free address = 0x%016X (window ends at 0x%016X)" \
    [llength $bar_list] $cursor $alloc_limit]
  return
}

# Guard checked by ecam::setup_hdm's "decoder" mode: its Component Register
# block is only reachable via the ep's own BAR, so ecam::setup_ep_bars must
# have already run successfully (and set EP_BARS_SETUP) this session.
proc ecam::require_ep_bars_setup {} {
  variable EP_BARS_SETUP
  if {!$EP_BARS_SETUP} {
    error "the ep's BARs haven't been set up yet -- call ecam::setup_ep_bars first"
  }
}

#----------------------------------------------------------------------------
# Orchestrator
#----------------------------------------------------------------------------
# Purely a display command -- prints, returns nothing. Callers who want the
# underlying data should call id/read_bars/walk_caps/walk_ext_caps/find_cxl
# directly and capture their return values instead; call ecam::show_cxl for
# the verbose per-DWORD CXL DVSEC dump (walk_ext_caps below already prints
# each CXL DVSEC's specific name/ID inline as a one-line summary).
proc ecam::report {args} {
  lassign $args target
  set targets [resolve_targets $target]
  foreach t $targets {
    print_target_header $t
    if {[catch {require_present $t} err]} { puts "  (unavailable: $err)"; continue }
    id $t
    read_bars $t
    walk_caps $t
    walk_ext_caps $t
  }
  puts ""
  return
}
