# design_pkg.tcl
#
# Constants for board bring-up and JTAG target selection.

namespace eval design {
  # Target index for "the Versal root", used by design::program's own PDI
  # download step (via `targets <index>`). This is a JTAG-chain/hw_server-
  # session convention, independent of design::connect's pattern-based
  # target selection -- run `targets` yourself if this index doesn't select
  # the right target on your chain.
  variable TARGET_INDEX 1
}
