# ============================================================================
# pre_compile_hook.tcl
# Vivado pre-compile hook  (common for CPM4 + CPM5)
#
# Registered via sim_1 fileset properties:
#   xsim.compile.tcl.pre    = <path>/pre_compile_hook.tcl
#   xcelium.compile.tcl.pre = <path>/pre_compile_hook.tcl
#   (and all other simulators)
#
# Vivado calls this BEFORE compile.sh runs — for BOTH GUI launch_simulation
# AND batch-mode launch_simulation. It survives compile.sh regeneration
# because it is stored in the .xpr project file, not in compile.sh itself.
#
# PART 1: PIPESIM sync
#   Calls update_pipesim.sh which reads C_CPM_PIPESIM from the regenerated
#   EP IP (.gen/) and updates board.v localparam PIPESIM to match.
#   This ensures board.v is always in sync with the IP before HDL compile.
# ============================================================================

set proj_dir  [get_property DIRECTORY [current_project]]
set proj_name [get_property NAME [current_project]]
set update_sh "$proj_dir/${proj_name}.sim/sim_1/behav/update_pipesim.sh"

puts "INFO: Pre-compile hook invoked"

# ============================================================
# PART 1: board.v PIPESIM sync
# ============================================================
puts "INFO: PART 1 — PIPESIM sync..."

if {[file exists $update_sh]} {
    puts "INFO:   running: bash $update_sh"
    if {[catch {exec bash $update_sh} result options]} {
        puts "WARNING: update_pipesim.sh reported an issue:"
        puts $result
    } else {
        if {$result ne ""} { puts $result }
        puts "INFO: board.v PIPESIM synced — compilation proceeds"
    }
} else {
    puts "WARNING: update_pipesim.sh not found: $update_sh"
}
