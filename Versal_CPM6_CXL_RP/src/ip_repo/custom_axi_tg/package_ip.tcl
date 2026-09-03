##############################################################################
# package_ip.tcl
#
# Packages custom_axi_tg as a standalone Vivado IP for use in an IP Integrator
# block design.
#
# The packaged top is rtl/custom_axi_tg_ip.sv.  Unlike pl_axi_cpi_bridge the
# wrapper is NOT needed to unroll SystemVerilog interfaces - custom_axi_tg's
# boundary is already flat - it exists only because the IP Packager's
# port-width resolver cannot evaluate a localparam defined as an expression on
# another localparam, which is how the DUT derives its AXI ID and WSTRB port
# widths.  See the wrapper's header.
#
# Usage:
#   vivado -mode batch -source package_ip.tcl
#
# Re-running this script re-packages the IP in place.  component.xml is
# regenerated from scratch each run (m_axi/s_axil are auto-detected as
# AXI4/AXI4-Lite interfaces during packaging), but xgui/<ip_name>_v1_0.tcl --
# the hand-customizable GUI layout -- is preserved across re-runs; see the
# backup/restore step around ipx::create_xgui_files below.
##############################################################################

set script_dir [file normalize [file dirname [info script]]]
set part_name  xc2vp3602-vsvc3340-3HP-e-S
set ip_dir     $script_dir
set proj_dir   $script_dir/_pkg_proj
set ip_name    custom_axi_tg
set top_module custom_axi_tg_ip

set rtl_dir    [file normalize $script_dir/../../rtl]
set constr_dir [file normalize $script_dir/../../constr]

# Glob the RTL rather than hardcoding a file list, so this script does not rot
# when modules are added or removed.  The package is added first to keep the
# compile-order report clean; Vivado resolves the rest itself.
set pkg_file  $rtl_dir/custom_axi_tg_pkg.sv
set all_files [lsort [glob $rtl_dir/*.sv]]
set src_files [concat [list $pkg_file] \
                      [lsearch -all -inline -not -exact $all_files $pkg_file] \
                      [list $script_dir/rtl/custom_axi_tg_ip.sv]]

if {[file exists $proj_dir]} {
  file delete -force $proj_dir
}

create_project -force $ip_name $proj_dir -part $part_name

add_files -norecurse $src_files
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sources_1]]
set_property top $top_module [current_fileset]

# custom_axi_tg_iram.sv instantiates XPM_MEMORY_SDPRAM.  Recent Vivado
# auto-infers the XPM libraries, but declaring it explicitly keeps the packaged
# IP correct if it is ever consumed by a project that has auto-inference off.
set_property XPM_LIBRARIES {XPM_MEMORY} [current_project]

update_compile_order -fileset sources_1

# Scoped CDC constraints travel with the IP so a consumer does not have to
# remember to add them by hand.
add_files -fileset constrs_1 -norecurse \
  [list $constr_dir/custom_axi_tg_cdc.xdc $constr_dir/custom_axi_tg_start_cdc.xdc]
set_property USED_IN {synthesis implementation} \
  [get_files -of_objects [get_filesets constrs_1]]
set_property SCOPED_TO_REF custom_axi_tg_reg_space \
  [get_files custom_axi_tg_cdc.xdc]
set_property SCOPED_TO_REF custom_axi_tg \
  [get_files custom_axi_tg_start_cdc.xdc]
# Both files call get_clocks to pick up the periods they bound the quasi-static
# buses against.  If they are processed before the consuming design has created
# its clocks, that lookup yields nothing and -quiet SILENTLY DROPS the
# set_max_delay constraints, leaving the crossing bounded only by the
# false_paths.  PROCESSING_ORDER LATE guarantees they run after the user's
# clock definitions.
set_property PROCESSING_ORDER LATE \
  [get_files -of_objects [get_filesets constrs_1]]

ipx::package_project -root_dir $ip_dir -vendor xilinx.com -library user \
  -taxonomy /UserIP -import_files -force

set_property name         $ip_name [ipx::current_core]
set_property display_name $ip_name [ipx::current_core]
set_property description \
  "AXI4 traffic generator that programs a BRAM instruction RAM over AXI4-Lite\
   and issues single-beat 64 B transactions to pl_axi_cpi_bridge at up to one\
   per clock." [ipx::current_core]

# ipx::package_project already auto-detects the clocks/resets from naming
# convention and wires each clock's ASSOCIATED_RESET.  Asserting it explicitly
# is redundant but harmless, and it documents the intent.  Reset interfaces
# have no ASSOCIATED_CLOCK bus parameter of their own, so that half is skipped.
ipx::infer_bus_interface m_axi_aclk     xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface m_axi_aresetn  xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface s_axil_aclk    xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface s_axil_aresetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

##############################################################################
# Parameter presentation and validation
##############################################################################

proc set_range {name lo hi} {
  set core [ipx::current_core]
  set up [ipx::get_user_parameters  $name -of_objects $core]
  set mp [ipx::get_hdl_parameters $name -of_objects $core]
  if {$up eq ""} { return }
  foreach q [list $up $mp] {
    if {$q ne ""} { set_property value_format long $q }
  }
  set_property value_validation_type range_long $up
  set_property value_validation_range_minimum $lo $up
  set_property value_validation_range_maximum $hi $up
}

# AXI_ADDRESS_WIDTH is capped at 48 by the downstream bridge's address map.
set_range AXI_ADDRESS_WIDTH 1 48
# AXI_ID_WIDTH 0 means the AXI ID is hardcoded to 0 on a 1-bit tied-off port.
set_range AXI_ID_WIDTH 0 4

# Boolean knobs presented as labelled combo boxes rather than raw 0/1, so the
# block design shows what the setting actually means.
# A `parameter bit` in the HDL is inferred by the packager as bitString format
# with a quoted value.  Presenting it as a labelled combo box means switching to
# long format, and that switch must be applied to BOTH the user parameter and
# the underlying HDL parameter, with the stored value rewritten as a
# plain integer.  Changing only the user parameter leaves the model parameter
# holding a quoted bitString, and every attempt to instantiate the IP then fails
# with "Invalid long/float value '\"0\"'".
proc set_pairs {name pairs default} {
  set core [ipx::current_core]
  set up [ipx::get_user_parameters  $name -of_objects $core]
  set mp [ipx::get_hdl_parameters $name -of_objects $core]
  if {$up eq ""} { return }
  foreach q [list $up $mp] {
    if {$q eq ""} { continue }
    set_property value_format long $q
    set_property value $default    $q
  }
  set_property value_validation_type pairs   $up
  set_property value_validation_pairs $pairs $up
}

set_pairs AXI_AXIL_SYNC {{Asynchronous (CDC generated)} 0 {Synchronous (CDC bypassed)} 1} 0

# AXI_ADDRESS_WIDTH/AXI_ID_WIDTH are auto-humanized by the packager as
# "Axi Address Width"/"Axi Id Width" (it title-cases the HDL parameter name
# without knowing AXI is an acronym); the corrected "AXI ..." labels are set
# via -display_name in xgui/${ip_name}_v1_0.tcl instead, since display name is
# a GUI-layer (xgui) property, not a component.xml/ipx property.

# LFSR64_GALOIS/LFSR27_GALOIS/LFSR8_GALOIS and the LFSR seeds are wrapper
# localparams (see rtl/custom_axi_tg_ip.sv), not HDL parameters, so the
# packager never creates user parameters for them and there is nothing here
# to present or hide.

# i_start is hidden from the packaged IP's symbol by default: most consumers
# start the DUT through the AXI-Lite CSR bit and never wire this pin. The
# "External Start Enable" checkbox (EXTERNAL_START_EN, see xgui.tcl) reveals
# it. The dependency MUST be a full relational expression, not a bare
# parameter name: a bare `{EXTERNAL_START_EN}` was tried first and, although
# it packaged without error, Vivado never actually re-evaluated port
# visibility on it (empirically confirmed: toggling CONFIG.EXTERNAL_START_EN
# between true/false in a BD left i_start permanently hidden). Every working
# enablement_dependency in the reference pl_axi_cpi_bridge IP -- e.g.
# DEBUG_IF_EN == 1 || DEBUG_IF_EN == 3 -- is a comparison, never a bare
# token, so this now follows that same pattern. enablement_dependency is
# applied to the port itself, so this is the one representation of the
# signal that needs updating (i_start is a standalone pin, not part of a bus
# interface).
proc set_enablement {names expr core} {
  foreach name $names {
    set port [ipx::get_ports $name -of_objects $core]
    if {$port ne ""} { set_property enablement_dependency $expr $port }
  }
}

set_enablement {i_start} {EXTERNAL_START_EN == 1} [ipx::current_core]

# A checkBox widget (see xgui.tcl) stores "true"/"false", which is only valid
# against a "long" (plain decimal) parameter -- against the packager's
# default-inferred "bitString" format (which is what a `parameter bit X =
# 1'b0` declaration like EXTERNAL_START_EN's gets, same as AXI_AXIL_SYNC and
# the LFSR_GALOIS params above before their own set_pairs/set_bool call), a
# checkBox write fails in the Vivado GUI with "Invalid Hexadecimal Value
# 'true' for parameter ... Valid values are of type #1A10 or 0b1010 or 0x1A
# or "1010"". Confirmed empirically against pl_axi_cpi_bridge's own
# component.xml: its checkBox-bound bit parameters (USER_POISN_SUPP,
# DEBUG_EN_BCD, ...) are format="long", never bitString. Reusing set_pairs
# here would be wrong -- a checkBox has no pairs table -- so this is the
# plain-long-format half of that logic on its own.
proc set_bool {name default} {
  set core [ipx::current_core]
  set up [ipx::get_user_parameters  $name -of_objects $core]
  set mp [ipx::get_hdl_parameters $name -of_objects $core]
  if {$up eq ""} { return }
  foreach q [list $up $mp] {
    if {$q eq ""} { continue }
    set_property value_format long $q
    set_property value $default    $q
  }
}

set_bool EXTERNAL_START_EN 0

##############################################################################
# GUI generation
#
# ipx::create_xgui_files always overwrites xgui/<ip_name>_v1_0.tcl with a
# fresh, default-layout script, which would discard any hand-made GUI
# customization (groups, static text, per-field enablement).  Back the existing
# file up and restore it afterward so re-running this script reproduces the
# current GUI exactly; a brand-new checkout with no xgui.tcl yet still gets a
# sensible auto-generated default.
##############################################################################

set xgui_file   "$ip_dir/xgui/${ip_name}_v1_0.tcl"
set xgui_backup ""
if {[file exists $xgui_file]} {
  set fh [open $xgui_file r]
  set xgui_backup [read $fh]
  close $fh
}

ipx::create_xgui_files [ipx::current_core]

if {$xgui_backup ne ""} {
  set fh [open $xgui_file w]
  puts -nonewline $fh $xgui_backup
  close $fh
  puts "INFO: Restored hand-customized $xgui_file"
}

ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

close_project

puts "INFO: $ip_name packaged in $ip_dir (component.xml/xgui updated)"
