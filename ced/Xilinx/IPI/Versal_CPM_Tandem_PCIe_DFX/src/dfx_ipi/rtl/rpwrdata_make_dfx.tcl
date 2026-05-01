# Create default cells
create_bd_cell -type module -reference passthrough pl_bram_inst/rm_passthrough_0
create_bd_cell -type module -reference passthrough pl_bram_inst/rm_passthrough_1
# Wire them up between AXI BRAM Controller and Embedded Memory Generator
connect_bd_net [get_bd_pins pl_bram_inst/axi_bram_ctrl_0/bram_wrdata_a] [get_bd_pins pl_bram_inst/rm_passthrough_0/din]
connect_bd_net [get_bd_pins pl_bram_inst/axi_bram_ctrl_0/bram_wrdata_b] [get_bd_pins pl_bram_inst/rm_passthrough_1/din]
connect_bd_net [get_bd_pins pl_bram_inst/rm_passthrough_0/dout] [get_bd_pins pl_bram_inst/bram_inst/dina]
connect_bd_net [get_bd_pins pl_bram_inst/rm_passthrough_1/dout] [get_bd_pins pl_bram_inst/bram_inst/dinb]
# Group cells into hierarchy
group_bd_cells passthru [get_bd_cells pl_bram_inst/rm_*]
# Rename the hierarchy ports just for clarity
set_property name din_a [get_bd_pins pl_bram_inst/passthru/din]
set_property name din_b [get_bd_pins pl_bram_inst/passthru/din1]
set_property name dout_a [get_bd_pins pl_bram_inst/passthru/dout]
set_property name dout_b [get_bd_pins pl_bram_inst/passthru/dout1]
# We're forced to validate the design otherwise we get an error
validate_bd_design
# Convert the hierarchy into a BDC by creating a new BD
set curdes [current_bd_design]
create_bd_design -cell [get_bd_cells /pl_bram_inst/passthru] bd_passthru
current_bd_design $curdes
set new_cell [create_bd_cell -type container -reference bd_passthru pl_bram_inst/rp_wrdata]
replace_bd_cell [get_bd_cells /pl_bram_inst/passthru] $new_cell
delete_bd_objs [get_bd_cells /pl_bram_inst/passthru]
# Turn the BDC into an RP; equiv. to checking "Enable Dynamic Function eXChange on this container"
set_property CONFIG.ENABLE_DFX {true} [get_bd_cells pl_bram_inst/rp_wrdata]
# Lock the ports of the RP; equiv. to checking "Freeze the boundary of this container"
set_property CONFIG.LOCK_PROPAGATE {true} [get_bd_cells pl_bram_inst/rp_wrdata]
# Create an additional BD for the secondary RM
create_bd_design bd_reverse
create_bd_cell -type module -reference reverse rm_reverse_0
create_bd_cell -type module -reference reverse rm_reverse_1
create_bd_port -dir I -from 31 -to 0 -type data din_a
create_bd_port -dir I -from 31 -to 0 -type data din_b
create_bd_port -dir O -from 31 -to 0 -type data dout_a
create_bd_port -dir O -from 31 -to 0 -type data dout_b
connect_bd_net [get_bd_ports din_a] [get_bd_pins rm_reverse_0/din]
connect_bd_net [get_bd_ports din_b] [get_bd_pins rm_reverse_1/din]
connect_bd_net [get_bd_ports dout_a] [get_bd_pins rm_reverse_0/dout]
connect_bd_net [get_bd_ports dout_b] [get_bd_pins rm_reverse_1/dout]
validate_bd_design
save_bd_design
current_bd_design $curdes
# Add the additional BD to the RP
set_property -dict [list \
 CONFIG.LIST_SIM_BD {bd_passthru.bd:bd_reverse.bd} \
 CONFIG.LIST_SYNTH_BD {bd_passthru.bd:bd_reverse.bd} \
] [get_bd_cells pl_bram_inst/rp_wrdata]
validate_bd_design
save_bd_design
