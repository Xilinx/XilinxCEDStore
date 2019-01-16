set _template digilentinc.com:examples:zybo-z7-20:1.0
#auto build
set_param ced.repoPaths [file dirname [file normalize [info script]]]


set _project "project\_[clock seconds]"
set currentFileAutoTest [file normalize [info script]] 
set currentDirAutoTest [file dirname $currentFileAutoTest] 
set _project_location [file join $currentDirAutoTest REGRESS_PROJECTS $_project]

file mkdir $_project_location
instantiate_example_design -template $_template -project $_project -project_location $_project_location
update_compile_order -fileset sources_1
#save_bd_design
	
