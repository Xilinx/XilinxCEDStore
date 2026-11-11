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
# Bring up the CPM6 Root Port link over JTAG, then enumerate what is
# downstream of it.
#
# Usage:
#   connect
#   source bringup.tcl
#   bringup -controller ctrl0
#
# Options:
#   -controller ctrl0|ctrl1  required, matching the CED variant that was built.
#   -perst 0                 skip both PERST pulses. The link will not come up
#                            from cold without them; use only when the device
#                            has already been released.
#   -perst-ms <n>            how long each PERST is held low, default 50.
#   -settle-ms <n>           wait after PERST before checking, default 3000.
#   -poll-ms <n>             interval between the checks, default 100.
#   -checks <n>              link reads taken after the settle wait, default 5.
#                            All must be up; a lower count means it is flapping.
#   -enumerate 0             stop after the link check.
#   -read-only               passed to enumerate_downstream; do not place BAR0.
#
########################################################################

# PERST pins, endpoint and controller. VPK360 pin numbers.
set ::BRINGUP_EP_PERST_ADDR 0xF1020008
array set ::BRINGUP_EP_PERST_LO {ctrl0 0xBFFF0000 ctrl1 0x7FFF0000}
array set ::BRINGUP_EP_PERST_HI {ctrl0 0xBFFF4000 ctrl1 0x7FFF8000}

set ::BRINGUP_PERST_ADDR 0xFF0B0004
array set ::BRINGUP_PERST_LO {ctrl0 0xFFFB0000 ctrl1 0xFFF70000}
array set ::BRINGUP_PERST_HI {ctrl0 0xFFFB0004 ctrl1 0xFFF70008}

array set ::BRINGUP_STATUS_REG {ctrl0 0xFC84078C ctrl1 0xFC94078C}
array set ::BRINGUP_LINK_REG   {ctrl0 0xFC000080 ctrl1 0xFC400080}

set ::BRINGUP_LTSSM_L0 0x11

# PCIe-defined encoding of LINK_STATUS[19:16].
array set ::BRINGUP_SPEED {1 "Gen1" 2 "Gen2" 3 "Gen3" 4 "Gen4" 5 "Gen5" 6 "Gen6"}

set ::BRINGUP_DIR [file dirname [file normalize [info script]]]

proc _bu_rd {addr} { return [mrd -force -value [format 0x%x $addr]] }
proc _bu_wr {addr val} { mwr -force [format 0x%x $addr] [format 0x%x $val] }

proc bringup_target {} {
    if {[catch {targets -set -filter {name =~ "Versal*"}} e]} {
        error "could not select the Versal target: $e\
             \n  Run 'connect' first, then 'targets' to see what is visible."
    }
}

proc bringup_perst {ctrl width_ms} {
    global BRINGUP_EP_PERST_ADDR BRINGUP_EP_PERST_LO BRINGUP_EP_PERST_HI
    global BRINGUP_PERST_ADDR BRINGUP_PERST_LO BRINGUP_PERST_HI
    puts "  PERST        endpoint, then $ctrl"
    _bu_wr $BRINGUP_EP_PERST_ADDR $BRINGUP_EP_PERST_LO($ctrl)
    after $width_ms
    _bu_wr $BRINGUP_EP_PERST_ADDR $BRINGUP_EP_PERST_HI($ctrl)
    _bu_wr $BRINGUP_PERST_ADDR $BRINGUP_PERST_LO($ctrl)
    after $width_ms
    _bu_wr $BRINGUP_PERST_ADDR $BRINGUP_PERST_HI($ctrl)
}

proc bringup_sample {ctrl} {
    global BRINGUP_STATUS_REG BRINGUP_LINK_REG
    set s [_bu_rd $BRINGUP_STATUS_REG($ctrl)]
    set l [_bu_rd $BRINGUP_LINK_REG($ctrl)]
    return [list \
        [expr {$s & 0x3f}] \
        [expr {($l >> 16) & 0xf}] \
        [expr {($l >> 20) & 0x3f}] \
        [expr {($l >> 29) & 1}] \
        [expr {($l >> 27) & 1}] \
        $s]
}

proc _bu_speed_name {code} {
    global BRINGUP_SPEED
    if {[info exists BRINGUP_SPEED($code)]} { return $BRINGUP_SPEED($code) }
    return "speed?$code"
}

proc bringup_check_link {ctrl checks poll_ms} {
    global BRINGUP_LTSSM_L0
    set up 0
    set sample {}
    for {set i 0} {$i < $checks} {incr i} {
        set sample [bringup_sample $ctrl]
        lassign $sample ltssm speed width dll
        if {$ltssm == $BRINGUP_LTSSM_L0 && $dll == 1} { incr up }
        if {$i < $checks - 1} { after $poll_ms }
    }
    return [list $up $sample]
}

proc bringup {args} {
    global BRINGUP_LTSSM_L0

    array set o {-controller "" -perst 1 -perst-ms 50 -settle-ms 3000 \
                 -poll-ms 100 -checks 5 -enumerate 1 -read-only 0}
    foreach {k v} $args {
        if {![info exists o($k)]} { error "unknown option $k" }
        set o($k) $v
    }
    if {[lsearch -exact $args "-read-only"] >= 0} { set o(-read-only) 1 }

    if {![info exists ::BRINGUP_STATUS_REG($o(-controller))]} {
        error "-controller must be ctrl0 or ctrl1, got '$o(-controller)'.\
             \n  It must match the CED variant that was built:\
             \n    plstr_ctrl0 / brdg_ctrl0 / brdg_ddr_ctrl0 -> ctrl0\
             \n    plstr_ctrl1 / brdg_ctrl1 / brdg_ddr_ctrl1 -> ctrl1"
    }
    set ctrl $o(-controller)

    puts "=== CPM6 Root Port bring-up, $ctrl ==="
    bringup_target

    if {$o(-perst)} {
        bringup_perst $ctrl $o(-perst-ms)
    } else {
        puts "  PERST        skipped by request"
    }

    after $o(-settle-ms)

    lassign [bringup_check_link $ctrl $o(-checks) $o(-poll-ms)] up sample
    lassign $sample ltssm speed width dll training raw

    puts [format "  Link         %s x%d  LTSSM 0x%02X  DLL=%d   up %d/%d" \
                 [_bu_speed_name $speed] $width $ltssm $dll $up $o(-checks)]

    if {$up < $o(-checks)} {
        if {$up == 0} {
            puts [format "  FAILED       link is down%s" \
                         [expr {$training ? " (LINK_TRAINING set - still training)" : ""}]]
        } else {
            puts "  FAILED       link is not stable"
        }
        puts [format "               status 0x%08X, not enumerating" $raw]
        puts "               to enumerate anyway: source enumerate_downstream.tcl"
        puts "                                    enumerate_downstream -controller $ctrl"
        return 0
    }

    if {!$o(-enumerate)} { return 1 }

    puts ""
    if {[info commands enumerate_downstream] eq ""} {
        uplevel #0 [list source [file join $::BRINGUP_DIR enumerate_downstream.tcl]]
    }
    if {$o(-read-only)} {
        enumerate_downstream -controller $ctrl -read-only
    } else {
        enumerate_downstream -controller $ctrl
    }
    return 1
}

puts "bringup.tcl loaded."
puts "  run: bringup -controller ctrl0|ctrl1 \[-perst 0\] \[-enumerate 0\] \[-read-only\]"
