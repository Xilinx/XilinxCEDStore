# control.tcl - top-level loader for register transport (control::rd32/wr32)
# and PL reset-pin display/control. Requires design:: already loaded (for
# design::require_connected) -- source design.tcl first, or just source
# all.tcl.
#
#   source xsdb_scripts/all.tcl
#   design::connect
#   control::pl_rst_status

set control_script_dir [file dirname [file normalize [info script]]]

if {![llength [info commands ::design::require_connected]]} {
  error "control requires design to be loaded first -- run: source [file join $control_script_dir design.tcl]"
}

source [file join $control_script_dir pkg_help.tcl]
source [file join $control_script_dir control_pkg.tcl]
source [file join $control_script_dir control_xsdb.tcl]
source [file join $control_script_dir control_cmds.tcl]
source [file join $control_script_dir control_help.tcl]
unset control_script_dir

puts "INFO: control loaded."
puts "INFO: Run control::help (or control::h) for the command reference; control::help <cmd> for detailed help on one command."
