# design.tcl - top-level loader for board bring-up (PDI programming,
# PERSTN/MIO control, link-status checking), the one JTAG target-connect
# command, and the one .hwh-based address/clock discovery pass every other
# package reads from. No dependency on any other package -- this is the
# foundation everything else in xsdb_scripts/ builds on.
#
#   source xsdb_scripts/all.tcl
#   design::discover [pwd]
#   design::connect
#   design::program

set design_script_dir [file dirname [file normalize [info script]]]

source [file join $design_script_dir pkg_help.tcl]
source [file join $design_script_dir design_pkg.tcl]
source [file join $design_script_dir design_xsdb.tcl]
source [file join $design_script_dir design_addrmap.tcl]
source [file join $design_script_dir design_cmds.tcl]
source [file join $design_script_dir design_help.tcl]
unset design_script_dir

puts "INFO: design loaded."
puts "INFO: Run design::help (or design::h) for the command reference; design::help <cmd> for detailed help on one command."
