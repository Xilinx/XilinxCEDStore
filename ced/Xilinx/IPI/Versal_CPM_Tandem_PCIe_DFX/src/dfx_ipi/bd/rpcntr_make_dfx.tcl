# Group cells into hierarchy
group_bd_cells cntr [get_bd_cells cntr16]
# Rename the hierarchy ports just for clarity
set_property name clk [get_bd_pins cntr/pl0_ref_clk]
set_property name l [get_bd_pins cntr/L]
set_property name ce [get_bd_pins cntr/CE]
set_property name load [get_bd_pins cntr/LOAD]
set_property name q [get_bd_pins cntr/Q]
set_property name up [get_bd_pins cntr/UP]
# We're forced to validate the design otherwise we get an error
validate_bd_design
# Convert the hierarchy into a BDC by creating a new BD
set curdes [current_bd_design]
create_bd_design -cell [get_bd_cells cntr] bd_cntr16
current_bd_design $curdes
set new_cell [create_bd_cell -type container -reference bd_cntr16 rp_cntr]
replace_bd_cell [get_bd_cells cntr] $new_cell
delete_bd_objs [get_bd_cells cntr]
# Turn the BDC into an RP; equiv. to checking "Enable Dynamic Function eXChange on this container"
set_property CONFIG.ENABLE_DFX {true} [get_bd_cells rp_cntr]
# Lock the ports of the RP; equiv. to checking "Freeze the boundary of this container"
set_property CONFIG.LOCK_PROPAGATE {true} [get_bd_cells rp_cntr]
# Create an additional BD for the secondary RM
source $currentDir/src/dfx_ipi/bd/cntr8_bd.tcl
validate_bd_design
save_bd_design
current_bd_design $curdes
# Add the additional BD to the RP
set_property -dict [list \
 CONFIG.LIST_SIM_BD {bd_cntr16.bd:bd_cntr8.bd} \
 CONFIG.LIST_SYNTH_BD {bd_cntr16.bd:bd_cntr8.bd} \
] [get_bd_cells rp_cntr]
validate_bd_design
save_bd_design
