# design_xsdb.tcl
#
# The one JTAG target-connect command system-wide. Independent of
# design::program's own target-selection mechanism (design::TARGET_INDEX /
# `targets <index>`), which is used only for PDI programming. No
# connected-state is tracked or checked anywhere -- control::rd32/wr32
# issue mrd/mwr directly; an unselected/wrong target simply fails there.

# Parses xsdb's bare `targets` listing for the currently-selected target
# and returns "N (Name)", e.g. "4 (Cortex-A72 #0)". Every ::connect proc
# (design::/ecam::/hwtg::/perf::) calls this after selecting a target so
# its confirmation print always names the specific target and index
# actually landed on -- `targets -set -filter ...` itself returns nothing
# useful to print.
#
# The "*" marker TRAILS the index number (e.g. "6* PMC"), not leads it --
# confirmed against real xsdb output. An earlier version of this regex
# looked for a leading "*" (e.g. "* 6  PMC"), which never matches real
# xsdb formatting and always fell through to "(unknown ...)".
proc design::current_target_desc {} {
  set listing [targets]
  foreach line [split $listing "\n"] {
    if {[regexp {^\s*(\d+)\*\s+(.+?)\s*$} $line -> idx name]} {
      return "$idx ($name)"
    }
  }
  return "(unknown -- run 'targets' to check the current selection)"
}

# target is either a `targets -set -filter` name-match pattern (default
# {*Versal*xc2vp*}) or a plain integer target index -- in which case this
# does `targets -set <index>` directly, no filter. Both are BOARD/HW_SERVER-
# SESSION SPECIFIC: run `targets` yourself first to see what your chain
# actually enumerates and pass in whichever form matches it if the default
# pattern doesn't.
proc design::connect {args} {
  lassign $args target

  if {$target ne "" && [string is integer -strict $target]} {
    targets -set $target
    puts "INFO: design connected to target [current_target_desc]"
    puts "INFO: control::/hwtg::/perf::/ecam:: register accesses may now proceed."
    return
  }

  set pattern $target
  if {$pattern eq ""} { set pattern {*Versal*xc2vp*} }
  targets -set -filter "name =~ \"$pattern\""
  puts "INFO: design connected to target [current_target_desc] (matched pattern '$pattern')"
  puts "INFO: control::/hwtg::/perf::/ecam:: register accesses may now proceed."
}
