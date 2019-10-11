if {[catch {
  xhub::get_xstores 
  set_param ced.repoPaths [get_property LOCAL_ROOT_DIR [xhub::get_xstores Vivado_example_project]]
  xhub::uninstall [xhub::get_xitems -of_objects [xhub::get_xstores Vivado_example_project]]
  xhub::refresh_catalog [xhub::get_xstores Vivado_example_project]
  xhub::install [xhub::get_xitems -of_objects [xhub::get_xstores Vivado_example_project]]
} result]} {
  puts "Failed to download example designs from github."
  puts "error : $result"
} else {
  puts "Successfully downloaded example designs from github."
}

exec mkdir ./tmp
if {[catch { 
  set examples_list [get_example_designs]
  foreach example_design_obj $examples_list {
  
  if { [catch {
    instantiate_example_design -template xilinx.com:design:MicroBlaze_Application_Configuration_for_AC701:1.0 -project project_tmp -project_location ./tmp
   } result_1]} {
   
   if { [catch { 
   create_project project_tmp ./tmp   
   set supported_boards [get_property SUPPORTED_BOARDS $example_design_obj] 
   set board_to_set [lindex $supported_boards 0]
   set_property board_part $board_to_set [current_project]
   create_bd_design "design_1"
   instantiate_example_design   -design design_1  $example_design_obj
   } result_2] } {
    puts  "Failed to instantiate example design $example_design_obj "  
    puts  "error : $result_2"
	exec rm -rf ./tmp  
    return 	
   }
  } 
  
  update_compile_order -fileset sources_1
  launch_runs impl_1 -to_step write_bitstream -jobs 8 
  wait_on_run impl_1
  close_project 
  exec rm -rf ./tmp/project_tmp
   
}} result]} {
    xhub::uninstall [xhub::get_xitems -of_objects [xhub::get_xstores Vivado_example_project]]
    puts  "Failed to execute basic flow on example designs  "  
    exec rm -rf ./tmp
    puts  "error : $result"	
} else {
    exec rm -rf ./tmp
    xhub::uninstall [xhub::get_xitems -of_objects [xhub::get_xstores Vivado_example_project]]
    puts "Succesfully ran basic tool flow  on all git example designs"
} 

