# ecam.tcl - top-level loader for PCIe/CXL configuration-space access (BARs,
# standard capability list, PCIe extended capability list, CXL DVSEC).
# Requires control:: already loaded (design:: is only needed indirectly, via
# design::connect having been called) -- source control.tcl first, or just
# source all.tcl.
#
# NOTE: "ecam" here is a fixed pair of flat config-space windows (rp/ep),
# NOT real {bus,device,function}-indexed ACPI/MCFG-style ECAM -- this design
# has a single fixed Root Port and a single attached downstream device, so
# there is no bus topology to enumerate.
#
#   source xsdb_scripts/all.tcl
#   design::connect
#   ecam::report

set ecam_script_dir [file dirname [file normalize [info script]]]

if {![llength [info commands ::control::rd32]]} {
  error "ecam requires control to be loaded first -- run: source [file join $ecam_script_dir control.tcl]"
}

source [file join $ecam_script_dir pkg_help.tcl]
source [file join $ecam_script_dir ecam_pkg.tcl]
source [file join $ecam_script_dir ecam_cmds.tcl]
source [file join $ecam_script_dir ecam_hdm.tcl]
source [file join $ecam_script_dir ecam_help.tcl]
unset ecam_script_dir

puts "INFO: ecam loaded."
puts "INFO: Run ecam::help (or ecam::h) for the command reference; ecam::help <cmd> for detailed help on one command."
