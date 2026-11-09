# pkg_args.tcl
#
# Shared argument validators used by every xsdb_scripts package (design::,
# control::, hwtg::, perf::, ecam::). Each validator either returns the
# checked value or raises an error of the form
#   "<caller>: <what is wrong> -- <what was expected>"
# so a user can see which command rejected which argument and why. Every
# validator is meant to run BEFORE any hardware access or other side effect.
#
#   chk::nargs      argc range / unexpected extra arguments
#   chk::int        integer (decimal or 0x hex, "_" separators), optional range
#   chk::posnum     number > 0
#   chk::oneof      value must be one of a fixed list
#   chk::cpi        value must be a discovered datapath index
#   chk::cpi_list   every element must be a discovered datapath index
#   chk::file_readable / chk::file_writable
#   chk::channel    value must be an open Tcl channel

namespace eval ::chk {}

# Formats a bound for an error message: small values in decimal, larger in hex.
proc ::chk::fmt {v} {
  if {$v > 0xFFFF || $v < -0xFFFF} { return [format 0x%X $v] }
  return $v
}

# argv is the proc's $args list; usage is the argument synopsis, e.g.
# "cpi ?timeout_s?". min/max are the allowed number of arguments.
proc ::chk::nargs {caller argv min max usage} {
  set n [llength $argv]
  if {$n < $min} {
    error "$caller: missing argument(s) (got $n, need at least $min) -- usage: $caller $usage"
  }
  if {$n > $max} {
    error "$caller: unexpected extra argument(s) '[lrange $argv $max end]' -- usage: $caller $usage"
  }
}

# Returns the value as a plain integer. Accepts decimal and 0x hex, with
# optional single "_" separators between digits (0x800_0000_0000).
proc ::chk::int {caller name val {min ""} {max ""}} {
  set range ""
  if {$min ne "" && $max ne ""} {
    set range " (valid: [fmt $min]..[fmt $max])"
  } elseif {$min ne ""} {
    set range " (valid: >= [fmt $min])"
  } elseif {$max ne ""} {
    set range " (valid: <= [fmt $max])"
  }
  if {$val eq ""} {
    error "$caller: $name is required -- expected an integer$range"
  }
  if {[regexp {^[+-]?[0-9]+(_[0-9]+)*$} $val]} {
    set n [expr {[string map {_ {}} [string trimleft $val +]] + 0}]
  } elseif {[regexp {^0[xX][0-9a-fA-F]+(_[0-9a-fA-F]+)*$} $val]} {
    set n [expr {[string map {_ {}} $val] + 0}]
  } else {
    error "$caller: $name must be an integer, got '$val'$range"
  }
  if {($min ne "" && $n < $min) || ($max ne "" && $n > $max)} {
    error "$caller: $name $val is out of range$range"
  }
  return $n
}

# Number strictly greater than zero (clock rates, timeouts).
proc ::chk::posnum {caller name val} {
  if {$val eq ""} {
    error "$caller: $name is required -- expected a number > 0"
  }
  if {![string is double -strict $val]} {
    error "$caller: $name must be a number, got '$val' -- expected a number > 0"
  }
  if {$val <= 0} {
    error "$caller: $name must be > 0, got '$val'"
  }
  return $val
}

proc ::chk::oneof {caller name val choices} {
  if {$val eq ""} {
    error "$caller: $name is required -- valid: [join $choices {, }]"
  }
  if {$val ni $choices} {
    error "$caller: $name '$val' is invalid -- valid: [join $choices {, }]"
  }
  return $val
}

# A datapath index: must be one of the indices design::discover found.
proc ::chk::cpi {caller val} {
  set indices [design::get_cxl_indices]
  if {[llength $indices] == 0} {
    error "$caller: no datapaths discovered yet -- call design::discover first"
  }
  if {$val eq ""} {
    error "$caller: cpi (datapath index) is required -- valid: $indices"
  }
  if {$val ni $indices} {
    error "$caller: cpi '$val' is not a valid datapath index -- valid: $indices"
  }
  return $val
}

# Validates every element BEFORE the caller acts on any of them, so a bad
# element never leaves earlier elements half-processed.
proc ::chk::cpi_list {caller cpi_list} {
  foreach c $cpi_list { cpi $caller $c }
  return $cpi_list
}

proc ::chk::file_readable {caller name path} {
  if {$path eq ""} {
    error "$caller: $name is required -- expected the path of an existing file"
  }
  if {![file exists $path]} {
    error "$caller: $name '$path' does not exist"
  }
  if {![file isfile $path] || ![file readable $path]} {
    error "$caller: $name '$path' is not a readable file"
  }
  return $path
}

proc ::chk::file_writable {caller name path} {
  if {$path eq ""} {
    error "$caller: $name is required -- expected a file path to write"
  }
  set dir [file dirname $path]
  if {![file isdirectory $dir]} {
    error "$caller: $name '$path' cannot be written -- directory '$dir' does not exist"
  }
  if {[file exists $path] ? ![file writable $path] : ![file writable $dir]} {
    error "$caller: $name '$path' cannot be written -- permission denied"
  }
  return $path
}

proc ::chk::channel {caller name chan} {
  if {$chan eq "" || [lsearch -exact [file channels] $chan] < 0} {
    error "$caller: $name '$chan' is not an open Tcl channel -- expected stdout or a handle returned by open"
  }
  return $chan
}
