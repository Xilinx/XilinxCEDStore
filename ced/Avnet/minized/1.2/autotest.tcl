set _template em.avnet.com:examples:MiniZED_Redux:1.2
#auto test

set _checkProgress "100%"
set_param ced.repoPaths [file dirname [file normalize [info script]]]


set _project "project\_[clock seconds]"
set currentFileAutoTest [file normalize [info script]] 
set currentDirAutoTest [file dirname $currentFileAutoTest] 
set _project_location [file join $currentDirAutoTest REGRESS_PROJECTS $_project]


if {[ catch { 

	file mkdir $_project_location
#	create_project $_project $_project_location
	instantiate_example_design -template $_template -project $_project -project_location $_project_location
	update_compile_order -fileset sources_1
	launch_runs impl_1
	wait_on_run impl_1
	if {[get_property PROGRESS [get_runs impl_1]] != $_checkProgress} {
		error "ERROR: could not complete autotest of $_template"
	} else {

		launch_runs impl_1 -to_step write_bitstream
		after 1000
		if {[get_property CURRENT_STEP [get_runs impl_1]] eq "write_bitstream"} {
			wait_on_run impl_1
			if {[get_property STATUS [get_runs impl_1]] != "write_bitstream Complete!"} {
				error "ERROR: could not create bitstream for of $_template"
			}
		}
	}

} sError]} {
	puts "ERROR: regression failed: err:$sError"
	save_bd_design
#	close_project
} else {
	close_project
	catch { file delete -force $_project_location/$_project }
puts "###############################################################################"
puts "# Successful test: $_template "
lappend _successfully_tested $_template
puts "###############################################################################"
}
	
