########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
########################################################################
#
# Enumerate the PCIe device downstream of the CPM6 Root Port, over JTAG.
# All configuration access is through the ECAM aperture.
#
# Usage:
#   connect
#   targets -set -filter {name =~ "Versal*"}
#   source enumerate_downstream.tcl
#   enumerate_downstream -controller ctrl1
#
# Options:
#   -controller ctrl0|ctrl1   required. brdg_ctrl0 and brdg_ddr_ctrl0 are
#                             ctrl0; brdg_ctrl1 and brdg_ddr_ctrl1 are ctrl1.
#   -ecam_base 0x<addr>       ECAM base override, for a design outside this CED.
#   -bdf <bus>:<dev>.<fn>     target device, default 1:0.0.
#   -read-only                skip BAR0 configuration and the Command writes.
#
# Writes:
#   BAR sizing     each BAR written all-ones, read back, then restored.
#   BAR0           left programmed at the outbound memory window base, not
#                  restored. For a 64-bit BAR0, BAR1 is left at zero.
#   Command        Memory Space Enable and Bus Master Enable set on the Root
#                  Port and on the device, after the BARs are placed.
#
# Requires the link to be up. The script checks and stops if it is not.
########################################################################

# ---- Per-controller address map, from the block design --------------------
array set ECAM_BASE {ctrl0 0x600000000 ctrl1 0x700000000}
array set MEM_BASE  {ctrl0 0xE0000000  ctrl1 0xE8000000}
array set MEM_LIMIT {ctrl0 0xE7FFFFFF  ctrl1 0xEFFFFFFF}

set RP_VID 0x10EE

# PCIe extended capability ID -> short name
array set EXTCAP_NAME {
    0x0001 AER         0x0002 VC          0x0003 DSN          0x0004 PowerBudget
    0x0005 RC-Link     0x0006 RC-IntLink  0x0007 RCEC-Assoc   0x0008 MFVC
    0x0009 VC2         0x000a RCRB        0x000b VSEC         0x000d ACS
    0x000e ARI         0x000f ATS         0x0010 SR-IOV       0x0012 Multicast
    0x0013 PRI         0x0014 EnhAlloc    0x0015 ResizableBAR 0x0016 DPA
    0x0017 TPH         0x0018 LTR         0x0019 SecPCIe      0x001b PASID
    0x001d DPC         0x001e L1SS        0x001f PTM          0x0021 FRS-Q
    0x0022 RTR         0x0023 DVSEC       0x0024 VF-ResBAR    0x0025 DLF
    0x0026 PL16G       0x0027 LaneMargin  0x0028 HierarchyID  0x0029 NPEM
    0x002a PL32G       0x002b AltProto    0x002c SFI          0x002e DOE
    0x002f Device3     0x0030 IDE         0x0031 PL64G        0x0032 FlitLog
    0x0033 FlitPerf    0x0034 FlitErrInj  0x0035 StreamVC     0x0036 MRBL
}

# ---- Resolved from the options at run time --------------------------------
set CUR_ECAM  ""
set CUR_MBASE ""
set CUR_MLIM  ""

# ---- Raw access -----------------------------------------------------------
proc _rd {addr} { return [mrd -force -value [format 0x%x $addr]] }
proc _wr {addr val} { mwr -force [format 0x%x $addr] [format 0x%x $val] }

# ---- Configuration access -------------------------------------------------
proc cfg_addr {bus dev fn reg} {
    global CUR_ECAM
    if {$CUR_ECAM eq ""} { error "internal: ECAM base not resolved" }
    if {$bus < 0 || $bus > 255} { error "bus $bus out of range 0-255" }
    if {$dev < 0 || $dev > 31}  { error "device $dev out of range 0-31" }
    if {$fn  < 0 || $fn  > 7}   { error "function $fn out of range 0-7" }
    return [expr {wide($CUR_ECAM) + ($bus<<20) + ($dev<<15) + ($fn<<12) + ($reg & 0xfff)}]
}
proc cfg_read  {bus dev fn reg}     { return [_rd [cfg_addr $bus $dev $fn $reg]] }
proc cfg_write {bus dev fn reg val} { _wr [cfg_addr $bus $dev $fn $reg] $val }

# ---- Formatting -----------------------------------------------------------
proc fmt_size {sz} {
    if {$sz <= 0} { return "0" }
    set units {B KiB MiB GiB TiB PiB}
    set i 0
    while {$sz >= 1024 && $i < 5} { set sz [expr {$sz / 1024}] ; incr i }
    return "$sz[lindex $units $i]"
}

proc fmt_bdf {bus dev fn} { return [format "%02x:%02x.%x" $bus $dev $fn] }

# ---- Link state -----------------------------------------------------------
proc dl_active_hits {{samples 30} {interval_ms 100}} {
    set hits 0
    for {set i 0} {$i < $samples} {incr i} {
        if {(([cfg_read 0 0 0 0x80] >> 29) & 1) == 1} { incr hits }
        if {$i < $samples - 1} { after $interval_ms }
    }
    return $hits
}

# ---- Step 1: check the Root Port and the link -----------------------------
proc check_rp {} {
    global RP_VID
    set v [cfg_read 0 0 0 0x00]
    set vid [expr {$v & 0xffff}]
    set did [expr {($v >> 16) & 0xffff}]
    puts [format "  Root Port    %04X:%04X" $vid $did]
    if {$vid != $RP_VID || $did == 0x0000 || $did == 0xffff} { return [list norp $v] }

    set lcs  [cfg_read 0 0 0 0x80]
    set lcap [cfg_read 0 0 0 0x7c]
    puts [format "  Link         Gen%d x%d   (max Gen%d x%d)" \
                 [expr {($lcs >> 16) & 0xf}] [expr {($lcs >> 20) & 0x3f}] \
                 [expr {$lcap & 0xf}] [expr {($lcap >> 4) & 0x3f}]]
    set hits [dl_active_hits 30]
    if {$hits == 0} { return [list linkdown $lcs] }
    if {$hits < 30} {
        puts "  WARNING      link is intermittent, Data Link Layer Link Active $hits/30 -- continuing"
    }
    return [list ok $lcs]
}

# ---- Step 2: find the device ---------------------------------------------
proc probe_device {bus dev fn {attempts 5} {timeout_s 5}} {
    set deadline [expr {[clock seconds] + $timeout_s}]
    set last 0xffffffff
    for {set n 1} {$n <= $attempts} {incr n} {
        set v [cfg_read $bus $dev $fn 0x00]
        if {$v != 0x00000000 && $v != 0xffffffff} {
            return [list ok $v $n]
        }
        set last $v
        if {[clock seconds] > $deadline} { return [list timeout $last $n] }
        if {$n < $attempts} { after 100 }
    }
    return [list none $last $attempts]
}

proc no_device_reason {raw} {
    if {$raw == 0x00000000} { return "configuration space reads back all zero" }
    return "no response -- check the link and the target BDF"
}

# ---- Step 3: BAR sizing ---------------------------------------------------
proc size_bars {bus dev fn nbar} {
    set orig {} ; set probe {}
    for {set i 0} {$i < $nbar} {incr i} {
        lappend orig [cfg_read $bus $dev $fn [expr {0x10 + $i*4}]]
    }
    for {set i 0} {$i < $nbar} {incr i} {
        set reg [expr {0x10 + $i*4}]
        if {[catch {cfg_write $bus $dev $fn $reg 0xffffffff} msg]} {
            puts "  WARNING      BAR$i probe write failed: $msg"
            lappend probe 0
            continue
        }
        lappend probe [cfg_read $bus $dev $fn $reg]
        cfg_write $bus $dev $fn $reg [lindex $orig $i]
    }
    for {set i 0} {$i < $nbar} {incr i} {
        set back [cfg_read $bus $dev $fn [expr {0x10 + $i*4}]]
        set want [lindex $orig $i]
        if {$back != $want} {
            set m [format "  WARNING      BAR%d did not restore: 0x%08x, expected 0x%08x" $i $back $want]
            puts $m
        }
    }

    set bars {}
    for {set i 0} {$i < $nbar} {incr i} {
        set p [lindex $probe $i]
        if {$p == 0 || $p == 0xffffffff && [lindex $orig $i] == 0} {
            lappend bars [dict create idx $i kind none]
            continue
        }
        if {$p == 0} { lappend bars [dict create idx $i kind none] ; continue }

        if {$p & 0x1} {
            set sz [expr {((~(wide($p) & 0xfffffffc)) + 1) & 0xffffffff}]
            lappend bars [dict create idx $i kind io sz $sz base [expr {[lindex $orig $i] & 0xfffffffc}]]
        } elseif {(($p >> 1) & 0x3) == 0x2} {
            set hi [expr {$i + 1 < $nbar ? [lindex $probe [expr {$i+1}]] : 0}]
            set comb [expr {(wide($hi) << 32) | (wide($p) & 0xffffffff)}]
            set sz [expr {(~(wide($comb) & wide(-16))) + 1}]
            set bs [expr {((wide([lindex $orig [expr {$i+1}]]) << 32) | \
                           (wide([lindex $orig $i]) & 0xffffffff)) & wide(-16)}]
            lappend bars [dict create idx $i kind mem64 sz $sz base $bs \
                                     pftch [expr {($p >> 3) & 1}]]
            lappend bars [dict create idx [expr {$i+1}] kind upper]
            incr i
        } else {
            set sz [expr {((~(wide($p) & 0xfffffff0)) + 1) & 0xffffffff}]
            lappend bars [dict create idx $i kind mem32 sz $sz \
                                     base [expr {[lindex $orig $i] & 0xfffffff0}] \
                                     pftch [expr {($p >> 3) & 1}]]
        }
    }
    return $bars
}

proc print_bars {bars} {
    foreach b $bars {
        set i    [dict get $b idx]
        set kind [dict get $b kind]
        set lbl  "BAR$i"
        if {$kind eq "none"} {
            puts [format "  %-13s%s" $lbl "not implemented"] ; continue
        }
        if {$kind eq "upper"} {
            set prev [expr {$i - 1}]
            puts [format "  %-13s%s" $lbl "upper half of BAR$prev"] ; continue
        }
        set sz   [fmt_size [dict get $b sz]]
        set base [dict get $b base]
        if {$kind eq "io"} {
            set v [format "I/O     size %-8s base 0x%08x" $sz $base]
        } else {
            set pf [expr {[dict get $b pftch] ? "  prefetchable" : ""}]
            if {$kind eq "mem32"} {
                set v [format "mem 32  size %-8s base 0x%08x%s" $sz $base $pf]
            } else {
                set v [format "mem 64  size %-8s base 0x%x%s" $sz $base $pf]
            }
        }
        puts [format "  %-13s%s" $lbl $v]
    }
}

# ---- Step 4: configure BAR0 ----------------------------------------------
proc configure_bar0 {bus dev fn bars} {
    global CUR_MBASE CUR_MLIM
    set b0 [lindex $bars 0]
    set win [expr {wide($CUR_MLIM) - wide($CUR_MBASE) + 1}]

    set kind [dict get $b0 kind]
    if {$kind eq "none"} {
        puts "  BAR0         not implemented -- nothing to configure"
        return -1
    }
    if {$kind eq "io"} {
        puts "  BAR0         is an I/O BAR -- the memory window does not apply, skipping"
        return -1
    }
    set sz [dict get $b0 sz]
    if {$sz > $win} {
        set m [format "  BAR0         size %s exceeds the %s memory window at 0x%08x -- skipping" \
                      [fmt_size $sz] [fmt_size $win] $CUR_MBASE]
        puts $m
        return -1
    }

    set base [expr {wide($CUR_MBASE) & wide(-16)}]
    cfg_write $bus $dev $fn 0x10 [expr {$base & 0xffffffff}]
    if {$kind eq "mem64"} {
        cfg_write $bus $dev $fn 0x14 0x00000000
        set m [format "  BAR0         configured at 0x%08x (64-bit; BAR1 set to 0 as its upper half)" $base]
    } else {
        set m [format "  BAR0         configured at 0x%08x (32-bit)" $base]
    }
    puts $m
    return $base
}

# ---- Step 5: capabilities -------------------------------------------------
proc walk_caps {bus dev fn} {
    set ptr [expr {[cfg_read $bus $dev $fn 0x34] & 0xff}]
    set seen {} ; set out {} ; set iter 0
    while {$ptr >= 0x40 && $ptr != 0xff && [lsearch -exact -integer $seen $ptr] < 0 && $iter < 48} {
        incr iter
        lappend seen $ptr
        set w [cfg_read $bus $dev $fn $ptr]
        lappend out [list $ptr [expr {$w & 0xff}] $w]
        set ptr [expr {($w >> 8) & 0xff}]
    }
    return $out
}

proc extcap_name {id} {
    global EXTCAP_NAME
    set k [format 0x%04x $id]
    if {[info exists EXTCAP_NAME($k)]} { return $EXTCAP_NAME($k) }
    return "(unknown)"
}

proc walk_ext_caps {bus dev fn} {
    set off 0x100 ; set seen {} ; set out {} ; set iter 0
    while {$off != 0 && $iter < 40} {
        incr iter
        set off [expr {$off & 0xfff}]
        if {$off == 0} break
        if {[lsearch -exact -integer $seen $off] >= 0} break
        if {$off < 0x100 || $off > 0xffc || ($off & 0x3) != 0} {
            puts [format "  WARNING      extended capability offset 0x%x is invalid, stopping" $off]
            break
        }
        lappend seen $off
        if {[catch {cfg_read $bus $dev $fn $off} hdr]} {
            puts [format "  WARNING      read failed at extended capability offset 0x%x, stopping" $off]
            break
        }
        if {$hdr == 0xffffffff || $hdr == 0} break
        lappend out [list $off [expr {$hdr & 0xffff}] [expr {($hdr >> 16) & 0xf}]]
        set off [expr {(($hdr >> 20) & 0xfff) & 0xffc}]
    }
    return $out
}

# ---- Enable Memory Space and Bus Master ----------------------------------
proc enable_bme_mse {bus dev fn what} {
    set cmd [expr {[cfg_read $bus $dev $fn 0x04] & 0xffff}]
    set new [expr {$cmd | 0x6}]
    cfg_write $bus $dev $fn 0x04 $new
    set back [expr {[cfg_read $bus $dev $fn 0x04] & 0xffff}]
    puts [format "  %-12s Command 0x%04x -> 0x%04x  (MSE, BME set)" $what $cmd $back]
    if {($back & 0x6) != 0x6} {
        puts [format "  %-12s WARNING  Command readback 0x%04x, MSE/BME did not take" $what $back]
    }
}

# ---- Enumerate one function ----------------------------------------------
proc enum_function {bus dev fn rp_lcs do_bar0 attempts} {
    lassign [probe_device $bus $dev $fn $attempts] st raw tries
    if {$st ne "ok"} {
        return [dict create status $st bus $bus dev $dev fn $fn raw $raw tries $tries]
    }

    set vid [expr {$raw & 0xffff}] ; set did [expr {($raw >> 16) & 0xffff}]
    set hdr [expr {([cfg_read $bus $dev $fn 0x0c] >> 16) & 0xff}]
    set multifn [expr {($hdr & 0x80) ? 1 : 0}]
    set bridge  [expr {($hdr & 0x7f) == 1 ? 1 : 0}]

    if {!$bridge} {
        puts ""
        puts [format "  %-13s%s  %04X:%04X%s" "EP" [fmt_bdf $bus $dev $fn] $vid $did \
                     [expr {$multifn ? "  (multi-function)" : ""}]]
    }
    set bars {} ; set bar0_base "" ; set bar0_done 0
    if {!$bridge} {
        set sub [cfg_read $bus $dev $fn 0x2c]
        puts [format "  Subsystem    %04X:%04X" [expr {$sub & 0xffff}] [expr {($sub >> 16) & 0xffff}]]

        set bars [size_bars $bus $dev $fn 6]
        print_bars $bars
        foreach b $bars {
            if {[dict get $b idx] == 0 && [dict get $b kind] ni {none upper}} {
                set bar0_base [dict get $b base]
            }
        }
        if {$do_bar0} {
            set w [configure_bar0 $bus $dev $fn $bars]
            if {$w >= 0} { set bar0_done 1 ; set bar0_base $w }
        }
    }

    set link "" ; set lmax "" ; set ptype ""
    foreach c [walk_caps $bus $dev $fn] {
        lassign $c off id w
        if {$id == 0x10} {
            set pc  [cfg_read $bus $dev $fn $off]
            set ptype [format "0x%x" [expr {($pc >> 20) & 0xf}]]
            set lcap [cfg_read $bus $dev $fn [expr {$off + 0x0c}]]
            set lmax [format "Gen%d x%d" [expr {$lcap & 0xf}] [expr {($lcap >> 4) & 0x3f}]]
            set lcs [cfg_read $bus $dev $fn [expr {$off + 0x10}]]
            set esp [expr {($lcs >> 16) & 0xf}] ; set ewd [expr {($lcs >> 20) & 0x3f}]
            set rsp [expr {($rp_lcs >> 16) & 0xf}] ; set rwd [expr {($rp_lcs >> 20) & 0x3f}]
            set link [format "Gen%d x%d" $esp $ewd]
            if {!$bridge} {
                puts [format "  Link         %s   (device max %s)" $link $lmax]
            }
            if {$esp != $rsp || $ewd != $rwd} {
                append link [format " (Root Port reports Gen%d x%d -- MISMATCH)" $rsp $rwd]
            }
        }
    }

    set ext {}
    foreach c [walk_ext_caps $bus $dev $fn] {
        lassign $c off id ver
        lappend ext [extcap_name $id]
        if {$bridge} { continue }
        if {$id == 0x0001} {
            set ue [cfg_read $bus $dev $fn [expr {$off + 0x04}]]
            set ce [cfg_read $bus $dev $fn [expr {$off + 0x10}]]
            puts [format "  AER          uncorrectable 0x%08x  correctable 0x%08x" $ue $ce]
        } elseif {$id == 0x0003} {
            set lo [cfg_read $bus $dev $fn [expr {$off + 0x04}]]
            set hi [cfg_read $bus $dev $fn [expr {$off + 0x08}]]
            puts [format "  Serial       %08x%08x" $hi $lo]
        } elseif {$id == 0x0010} {
            set vf [cfg_read $bus $dev $fn [expr {$off + 0x0c}]]
            puts [format "  SR-IOV       InitialVFs %d  TotalVFs %d" \
                         [expr {$vf & 0xffff}] [expr {($vf >> 16) & 0xffff}]]
        }
    }

    return [dict create status ok bus $bus dev $dev fn $fn vid $vid did $did \
            hdr $hdr multifn $multifn bridge $bridge bars $bars \
            link $link lmax $lmax ptype $ptype ext $ext bar0 $bar0_done bar0base $bar0_base \
            tries $tries]
}

# ---- Report ---------------------------------------------------------------
proc emit_report {findings} {
    puts ""
    puts "========================================================================"
    puts " ENUMERATION REPORT"
    puts "========================================================================"
    set n 0
    foreach s $findings {
        if {[dict get $s status] ne "ok"} { continue }
        incr n
        set bar0 ""
        if {[dict get $s bar0base] ne ""} {
            set bar0 [format "  BAR0 0x%x" [dict get $s bar0base]]
        }
        set m [format "  => BDF %s  VID %04X  DID %04X%s" \
                      [fmt_bdf [dict get $s bus] [dict get $s dev] [dict get $s fn]] \
                      [dict get $s vid] [dict get $s did] $bar0]
        puts $m
        if {[dict get $s link] ne ""} {
            set parts [split [dict get $s link]]
            set m [format "     LinkSpeed %s  Width %s" [lindex $parts 0] [lindex $parts 1]]
            if {[llength $parts] > 2} {
                append m "  " [join [lrange $parts 2 end] " "]
            }
            puts $m
        }
        if {[llength [dict get $s ext]]} {
            set m [format "     ExtCaps   %s" [join [dict get $s ext] ", "]]
            puts $m
        }
        if {[dict get $s bar0]} {
            puts         "     Note      BAR0 left configured, not restored"
        }
    }
    puts "  ----------------------------------------------------------------------"
    puts [format "  ENUMERATED %d function(s)" $n]
    puts "========================================================================"
}

# ---- Main -----------------------------------------------------------------
proc enumerate_downstream {args} {
    global ECAM_BASE MEM_BASE MEM_LIMIT CUR_ECAM CUR_MBASE CUR_MLIM RP_VID

    array set o {-controller "" -ecam_base "" -bdf "1:0.0" -read-only 0}
    foreach {k v} $args {
        if {![info exists o($k)]} { error "unknown option $k" }
        set o($k) $v
    }
    if {[lsearch -exact $args "-read-only"] >= 0} { set o(-read-only) 1 }

    if {$o(-controller) eq "" && $o(-ecam_base) eq ""} {
        error "-controller is required. Use -controller ctrl0 or -controller ctrl1,\
\n  matching the CED variant that was built:\
\n    brdg_ctrl0 / brdg_ddr_ctrl0 -> -controller ctrl0\
\n    brdg_ctrl1 / brdg_ddr_ctrl1 -> -controller ctrl1\
\n  For a design outside this CED, pass -ecam_base 0x<addr> instead."
    }
    if {$o(-controller) ne "" && ![info exists ECAM_BASE($o(-controller))]} {
        error "-controller must be ctrl0 or ctrl1, got '$o(-controller)'"
    }

    if {$o(-controller) ne ""} {
        set CUR_ECAM  $ECAM_BASE($o(-controller))
        set CUR_MBASE $MEM_BASE($o(-controller))
        set CUR_MLIM  $MEM_LIMIT($o(-controller))
    }
    if {$o(-ecam_base) ne ""} { set CUR_ECAM $o(-ecam_base) }
    if {$CUR_MBASE eq ""} {
        set o(-read-only) 1
    }

    if {![regexp {^(0[xX])?([0-9a-fA-F]+):([0-9]+)\.([0-9]+)$} $o(-bdf) -> _p b d f]} {
        error "-bdf must be <bus>:<dev>.<fn>, for example 1:0.0 -- got '$o(-bdf)'"
    }
    set bus [expr {"0x$b"}] ; set dev [expr {$d}] ; set fn [expr {$f}]

    puts ""
    puts "========================================================================"
    puts " CPM6 Root Port downstream enumeration"
    puts "========================================================================"
    puts [format "  ECAM base    0x%x%s" $CUR_ECAM \
                 [expr {$o(-controller) ne "" ? " ($o(-controller))" : " (override)"}]]
    if {$CUR_MBASE ne ""} {
        puts [format "  Mem window   0x%08x - 0x%08x  (%s)" $CUR_MBASE $CUR_MLIM \
                     [fmt_size [expr {wide($CUR_MLIM) - wide($CUR_MBASE) + 1}]]]
    }
    puts [format "  Target       %s" [fmt_bdf $bus $dev $fn]]
    puts [format "  Mode         %s" [expr {$o(-read-only) ? "read-only (no BAR0 or Command writes)" \
                                                           : "configure BAR0, set MSE and BME"}]]
    puts ""

    lassign [check_rp] rp_st rp_lcs
    if {$rp_st eq "norp"} {
        puts ""
        puts [format "  RESULT: no Root Port at ECAM base 0x%x" $CUR_ECAM]
        puts [format "          read 0x%08x; expected Vendor ID 0x%04x with a valid Device ID" $rp_lcs $RP_VID]
        puts         "          Check that -controller matches the CED variant that was built:"
        puts         "            brdg_ctrl0 / brdg_ddr_ctrl0 -> -controller ctrl0"
        puts         "            brdg_ctrl1 / brdg_ddr_ctrl1 -> -controller ctrl1"
        puts         "          For a design outside this CED, pass -ecam_base 0x<addr>."
        return 0
    }
    if {$rp_st eq "linkdown"} {
        puts ""
        puts         "  RESULT: link is down"
        puts         "          Data Link Layer Link Active was never set over 30 samples (~3 s)."
        puts         "          Bring the link up before enumerating."
        return 0
    }

    set findings {}
    set s0 [enum_function $bus $dev $fn $rp_lcs [expr {!$o(-read-only)}] 5]
    if {[dict get $s0 status] ne "ok"} {
        puts ""
        puts [format "  RESULT: no EP found at %s after %d attempts" \
                     [fmt_bdf $bus $dev $fn] [dict get $s0 tries]]
        puts [format "          last read 0x%08x -- %s" \
                     [dict get $s0 raw] [no_device_reason [dict get $s0 raw]]]
        set ::LAST_FINDINGS [list $s0]
        return 0
    }
    lappend findings $s0

    if {[dict get $s0 multifn]} {
        for {set f 1} {$f < 8} {incr f} {
            set sf [enum_function $bus $dev $f $rp_lcs 0 1]
            if {[dict get $sf status] eq "ok"} { lappend findings $sf }
        }
    }

    if {!$o(-read-only)} {
        puts ""
        enable_bme_mse 0 0 0 "Root Port"
        enable_bme_mse $bus $dev $fn [expr {[dict get $s0 bridge] ? "Bridge" : "EP"}]
    }

    set ::LAST_FINDINGS $findings
    emit_report $findings
    return [llength $findings]
}

puts "enumerate_downstream.tcl loaded."
puts "  run: enumerate_downstream -controller ctrl0|ctrl1 \[-bdf 1:0.0\] \[-read-only\]"
