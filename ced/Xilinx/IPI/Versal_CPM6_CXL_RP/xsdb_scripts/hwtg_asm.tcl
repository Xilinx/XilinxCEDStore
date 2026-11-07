# hwtg_asm.tcl
#
# Mnemonic <-> 6-slice instruction-word assembler/disassembler.
#
# Grammar: "OPCODE key=val key=val ..."  e.g.
#   WRITE addr=0x1000 id=0 id_stride=1 repeat=100 addr_k=4 addr_stride=64 be_k=7 data_start=0x0 data_stride=1
#   READ  addr=0x2000 repeat=50 aruser_cmd=0
#   WAIT
#
# "addr" is required for WRITE/READ (a hard error if omitted). Every other
# key is optional and defaults to 0, EXCEPT "be_k" on WRITE, which defaults
# to 7 (always full WSTRB) instead. Unknown keys/opcode are a hard error.
# Values may be plain decimal or 0x-prefixed hex. Single underscores may
# separate digits for readability (e.g. addr=0x800_0000_0000); they are
# stripped before parsing. A value that is negative or does not fit its
# field's bit width (addr 48, id 4, repeat 12, ... -- see hwtg_pkg.tcl FIELDS)
# is a hard error naming the field, never silently truncated.
#
# "addr" (48-bit) and "id" (4-bit) are user-facing aliases composed from the
# physical addr_hi/addr_lo and start_id fields respectively; every other key
# maps 1:1 to a hwtg_pkg.tcl FIELDS entry.

namespace eval hwtg {
  # user-facing keys valid per opcode, beyond the opcode token itself
  variable ASM_KEYS
  array set ASM_KEYS {
    WRITE {addr id id_stride repeat addr_k addr_stride be_k poison
           data_start data_stride addr_mode id_mode data_mode}
    READ  {addr id id_stride repeat addr_k addr_stride aruser_cmd
           addr_mode id_mode}
    WAIT  {}
  }
}

proc hwtg::parse_int {s} {
  if {[regexp {^0[xX]([0-9a-fA-F]+(_[0-9a-fA-F]+)*)$} $s -> hex]} {
    return [expr "0x[string map {_ {}} $hex]"]
  }
  # Decimal: strip leading zeros so "010" is ten (Tcl would read it as octal)
  # and "08" is not an invalid-octal error.
  if {[regexp {^(-?)0*([0-9]+(_[0-9]+)*)$} $s -> sign digits]} {
    return [expr {"$sign[string map {_ {}} $digits]" + 0}]
  }
  error "not an integer: '$s'"
}

# Bit width of a user-facing key: addr is the composed 48-bit address, id is
# the physical start_id field; every other key maps 1:1 onto FIELDS.
proc hwtg::key_width {key} {
  variable FIELDS
  switch -- $key {
    addr    { return 48 }
    id      { return [lindex $FIELDS(start_id) 2] }
    default { return [lindex $FIELDS($key) 2] }
  }
}

# Largest value for a width, formatted for an error message.
proc hwtg::fmt_max {width} {
  set max [expr {(1 << $width) - 1}]
  if {$max > 0xFFFF} { return [format 0x%X $max] }
  return $max
}

# Formats a non-negative integer as 0x-prefixed hex with an underscore
# between each 16-bit (4 hex digit) group, e.g. 0x800_0000_0000. parse_int
# accepts the result unchanged.
proc hwtg::format_hex16 {v} {
  set hex [format %X $v]
  set out ""
  while {[string length $hex] > 4} {
    set out "_[string range $hex end-3 end]$out"
    set hex [string range $hex 0 end-4]
  }
  return "0x$hex$out"
}

# Sets a physical field within a 6-element slice list (passed by name so the
# caller's list is updated in place).
proc hwtg::encode_field {slices_var field value} {
  upvar 1 $slices_var slices
  variable FIELDS
  lassign $FIELDS($field) widx lsb width
  set mask [expr {(1 << $width) - 1}]
  set value [expr {$value & $mask}]
  set word [lindex $slices $widx]
  set word [expr {($word & ~($mask << $lsb)) | ($value << $lsb)}]
  lset slices $widx $word
}

proc hwtg::decode_field {slices field} {
  variable FIELDS
  lassign $FIELDS($field) widx lsb width
  set mask [expr {(1 << $width) - 1}]
  set word [lindex $slices $widx]
  return [expr {($word >> $lsb) & $mask}]
}

# Returns a 6-element list of 32-bit slice values (slice 0 first, slice 5 --
# the committing write -- last), ready to be written in order by
# hwtg::commit_slices.
proc hwtg::assemble {line} {
  variable ASM_KEYS
  variable OPCODES

  set toks [regexp -all -inline {\S+} $line]
  if {[llength $toks] == 0} {
    error "empty command line -- expected an opcode (WRITE, READ or WAIT) followed by key=value fields"
  }
  set opcode [string toupper [lindex $toks 0]]
  if {![info exists ASM_KEYS($opcode)]} {
    error "unknown opcode '$opcode' (expected WRITE, READ or WAIT)"
  }

  array set kv {}
  foreach tok [lrange $toks 1 end] {
    if {![regexp {^([A-Za-z_]+)=(.+)$} $tok -> key val]} {
      error "malformed field '$tok' (expected key=value)"
    }
    if {[lsearch -exact $ASM_KEYS($opcode) $key] < 0} {
      error "field '$key' is not valid for opcode $opcode (valid: $ASM_KEYS($opcode))"
    }
    if {[catch {parse_int $val} num]} {
      error "field '$key'='$val' is not an integer -- use decimal or 0x hex (single '_' separators allowed)"
    }
    set width [key_width $key]
    if {$num < 0 || $num >= (1 << $width)} {
      error "field '$key'=$val does not fit in its $width-bit field (valid: 0..[fmt_max $width])"
    }
    set kv($key) $num
  }

  if {[lsearch -exact $ASM_KEYS($opcode) addr] >= 0 && ![info exists kv(addr)]} {
    error "addr is a required field for opcode $opcode"
  }

  set slices [lrepeat 6 0]
  encode_field slices opcode $OPCODES($opcode)
  # be_k's default is 7 (always full WSTRB), not 0 -- applied before the kv
  # loop below so an explicit be_k=... in the command line still overrides it.
  if {$opcode eq "WRITE"} { encode_field slices be_k 7 }

  foreach key [array names kv] {
    switch -- $key {
      addr {
        set a $kv(addr)
        encode_field slices addr_lo [expr {$a & 0xFFFFFFFF}]
        encode_field slices addr_hi [expr {($a >> 32) & 0xFFFF}]
      }
      id {
        encode_field slices start_id $kv(id)
      }
      default {
        encode_field slices $key $kv($key)
      }
    }
  }
  return $slices
}

# Inverse of assemble: given a 6-element slice list, returns the mnemonic
# line. Most fields are only printed when non-zero (their default), so
# output stays compact and still re-assembles to the same word -- EXCEPT
# "addr" (required, so always printed) and "be_k" on WRITE (defaults to 7,
# not 0, so it's always printed too; otherwise a be_k=0 command would
# disassemble to a line that reassembles back to be_k=7).
proc hwtg::disassemble {slices} {
  variable ASM_KEYS
  variable OPCODE_NAMES

  set op_val [decode_field $slices opcode]
  set opcode [lindex $OPCODE_NAMES $op_val]
  if {$opcode eq "RSVD"} {
    return "RSVD ;# reserved opcode -- was never a valid commit"
  }

  set parts [list $opcode]
  foreach key $ASM_KEYS($opcode) {
    switch -- $key {
      addr {
        set lo [decode_field $slices addr_lo]
        set hi [decode_field $slices addr_hi]
        set a [expr {($hi << 32) | $lo}]
        lappend parts "addr=[format_hex16 $a]"
      }
      id {
        set v [decode_field $slices start_id]
        if {$v != 0} { lappend parts "id=$v" }
      }
      be_k {
        lappend parts "be_k=[decode_field $slices be_k]"
      }
      default {
        set v [decode_field $slices $key]
        if {$v != 0} { lappend parts "$key=$v" }
      }
    }
  }
  return [join $parts " "]
}
