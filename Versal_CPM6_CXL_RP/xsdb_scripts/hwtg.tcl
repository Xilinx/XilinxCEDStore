# hwtg.tcl - top-level loader for the custom_axi_tg hardware-exercise
# library. See README.md for the full command reference.
#
# Requires design:: and control:: already loaded (for the address map/
# clock discovery and the JTAG register transport respectively) --
# source design.tcl and control.tcl first, or just source all.tcl.
#
#   source xsdb_scripts/all.tcl
#   design::discover [pwd]
#   design::connect
#   hwtg::load_append 0 "WRITE addr=0x1000 repeat=10 addr_stride=64"
#   hwtg::load_append 0 "WAIT"
#   hwtg::start 0
#   hwtg::wait_done 0
#   hwtg::status 0
#   hwtg::parse_errors 0

set hwtg_script_dir [file dirname [file normalize [info script]]]

if {![llength [info commands ::design::get_tg_base]]} {
  error "hwtg requires design to be loaded first -- run: source [file join $hwtg_script_dir design.tcl]"
}
if {![llength [info commands ::control::rd32]]} {
  error "hwtg requires control to be loaded first -- run: source [file join $hwtg_script_dir control.tcl]"
}

source [file join $hwtg_script_dir pkg_help.tcl]
source [file join $hwtg_script_dir hwtg_pkg.tcl]
source [file join $hwtg_script_dir hwtg_asm.tcl]
source [file join $hwtg_script_dir hwtg_cmds.tcl]
source [file join $hwtg_script_dir hwtg_help.tcl]
unset hwtg_script_dir

puts "INFO: hwtg loaded."
puts "INFO: Run hwtg::help (or hwtg::h) for the command reference; hwtg::help <cmd> for detailed help on one command."
