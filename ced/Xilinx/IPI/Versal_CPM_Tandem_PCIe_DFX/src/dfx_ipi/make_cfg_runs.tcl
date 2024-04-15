### These steps are usually applied through the "Dynamic Function eXchange Wizard"

set_property PR_FLOW true [current_project]

if {[get_pr_configurations] == ""} {
  # Create the configurations; each will be associated with an impl run
  create_pr_configuration -name config_1 -partitions [list \
    [get_bd_designs Versal*]_i/pl_bram_inst/rp_wrdata:bd_passthru_inst_0 \
    [get_bd_designs Versal*]_i/rp_cntr:bd_cntr16_inst_0 ]
  create_pr_configuration -name config_2 -partitions [list \
    [get_bd_designs Versal*]_i/pl_bram_inst/rp_wrdata:bd_reverse_inst_0 \
    [get_bd_designs Versal*]_i/rp_cntr:bd_cntr8_inst_0 ]
  # Set the default configuration to apply to impl_1 
  set_property PR_CONFIGURATION config_1 [get_runs impl_1]
  # Need to grab the release year for the -flow arg below
  if {![regexp {Vivado v(\d*)} [version] -> yr]} {
    error "Vivado release year could not be determined" 
  }
  # Create a child run of impl_1 for config_2 
  create_run child_0_impl_1 -parent_run impl_1 -flow "Vivado Implementation $yr" -pr_config config_2
}
