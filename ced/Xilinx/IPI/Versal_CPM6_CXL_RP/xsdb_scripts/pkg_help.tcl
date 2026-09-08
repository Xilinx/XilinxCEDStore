# pkg_help.tcl
#
# Shared, namespace-parameterized command-reference printer used by every
# xsdb_scripts package (design::, control::, hwtg::, perf::, ecam::). Each
# package defines its own COMMANDS (display order), CMD_SUMMARY (one-liner
# per command), and CMD_HELP (detailed Args/Notes text per command, keyed
# by command name -- an entry is optional; a command with no CMD_HELP entry
# just shows its one-line summary). ::pkg_help does the actual printing;
# each package's own <pkg>::help/<pkg>::h are one-line wrappers around it.

proc ::pkg_help {ns {cmd ""}} {
  upvar #0 ${ns}::COMMANDS commands
  upvar #0 ${ns}::CMD_SUMMARY summary
  upvar #0 ${ns}::CMD_HELP detail

  if {$cmd eq ""} {
    puts "${ns}:: available commands:"
    puts ""
    set name_width 0
    foreach c $commands {
      set len [string length "${ns}::${c}"]
      if {$len > $name_width} { set name_width $len }
    }
    foreach c $commands {
      puts [format "  %-*s -- %s" $name_width "${ns}::${c}" $summary($c)]
    }
    puts ""
    puts "Run \"${ns}::help <command>\" (or ${ns}::h <command>) for detailed help on one command."
    return
  }

  if {![info exists summary($cmd)]} {
    puts "${ns}::$cmd is not a recognized command -- run ${ns}::help for the full list"
    return
  }

  puts "${ns}::$cmd -- $summary($cmd)"
  if {[info exists detail($cmd)]} {
    puts ""
    puts $detail($cmd)
  }
  return
}
