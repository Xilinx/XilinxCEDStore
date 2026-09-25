# control_xsdb.tcl
#
# The one place mrd/mwr are actually issued from. Every other package's
# register access funnels through control::rd32/control::wr32, so there is
# exactly one place to change if the transport ever needs to move off xsdb.
# No connected-state gating here -- design::connect (or ecam::connect/
# hwtg::connect/perf::connect) still selects the actual xsdb target these
# rely on, but nothing checks that one of them was called first; an
# unselected/wrong target simply fails at the mrd/mwr call itself.
#
# NOTE: this parses mrd's printed output (last whitespace-separated token
# on its return value); confirm this matches your xsdb version's
# `mrd -force <addr> 1` output before relying on it, and adjust the parse
# below if it doesn't.

proc control::rd32 {addr} {
  set result [mrd -force $addr 1]
  set tok [lindex $result end]
  regsub {^0x} $tok {} tok
  return [expr "0x$tok"]
}

proc control::wr32 {addr value} {
  mwr -force $addr [format 0x%08X $value]
  return
}
