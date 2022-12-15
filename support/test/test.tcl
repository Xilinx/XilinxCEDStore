proc install_all_conf_example_designs {} {
  puts "INFO: Available xstores..."
  xhub::get_xstores 
  set_param ced.repoPaths [get_property LOCAL_ROOT_DIR [xhub::get_xstores Vivado_example_project]]
  puts "INFO: CED repo path used is [get_param ced.repoPaths]"
  puts "INFO: Uninstalling all configurable example designs ..."
  xhub::uninstall [xhub::get_xitems -of_objects [xhub::get_xstores Vivado_example_project]]
  puts "INFO: Refreshing CED store catalog..."
  xhub::refresh_catalog [xhub::get_xstores Vivado_example_project]
  puts "INFO: Installing all configurable example designs ..."
  xhub::install [xhub::get_xitems -of_objects [xhub::get_xstores Vivado_example_project]]
}

proc create_dir {dir_name} {
  if { [file exists $dir_name] && [file isdirectory $dir_name] } {
    return
  }

  file mkdir $dir_name
}

proc delete_dir {dir_name} {
  if { [file exists $dir_name] && [file isdirectory $dir_name] } {
    file delete -force -- $dir_name
  }
}

proc test_conf_example_design {tmpDir ced_download_location example_design_obj} {
  puts "INFO: Going to test $example_design_obj"
  set example_download_location [get_property REPO_DIRECTORY $example_design_obj]  
  set index [string first $ced_download_location $example_download_location]   
 
  if {$index != 0} {
    return
  }

  puts "INFO: Testing $example_design_obj"

  if { [catch {
    puts "INFO: Trying to instantiate the example design $example_design_obj..."
    instantiate_example_design -template $example_design_obj -project project_tmp -project_location $tmpDir
   } result_1]} {
   
   puts "INFO: Unable to instantiate the example design with project option..."
   puts "INFO: Trying to create project and then instantiate the example design $example_design_obj..."

   if { [catch { 
    create_project project_tmp $tmpDir
    set supported_boards [get_property SUPPORTED_BOARDS $example_design_obj] 
    
    if {$supported_boards == ""} {
      puts "INFO: Setting part in project" 
      set supported_parts [get_property SUPPORTED_PARTS $example_design_obj]
	    set part_to_set [lindex $supported_parts 0]
	    set_property PART $part_to_set [current_project]
    } else {
	    puts "INFO: Setting board in project"
	    set board_to_set [lindex $supported_boards 0]
	    set_property board_part $board_to_set [current_project]
    }
    
    create_bd_design "design_1"
    instantiate_example_design   -design design_1  $example_design_obj
   } result_2] } {
    puts  "ERROR: Failed to instantiate example design $example_design_obj "  
    puts  "ERROR: $result_2"
    delete_dir $tmpDir
    return 1
   }
  } 
  
  update_compile_order -fileset sources_1
  #launch_runs impl_1 -to_step write_bitstream -jobs 8 
  #wait_on_run impl_1
  close_project 
  delete_dir $tmpDir
  puts "INFO: Test for configurable example design $example_design_obj passed successfully"
}


if {[catch {
  install_all_conf_example_designs
} result]} {
  puts "ERROR: Failed to download example designs from github."
  puts "ERROR: $result"
  return 1
} else {
  puts "INFO: Successfully downloaded example designs from github."
}

# set up a temporary directory
set currDir [pwd]
set tmpDir [file join $currDir tmp]
create_dir $tmpDir

if {[catch { 
    set examples_list [get_example_designs]
    set ced_download_location [get_property LOCAL_ROOT_DIR [xhub::get_xstores Vivado_example_project]]
    foreach example_design_obj $examples_list {
      test_conf_example_design $tmpDir $ced_download_location $example_design_obj
    }
  } result]} {
    xhub::uninstall [xhub::get_xitems -of_objects [xhub::get_xstores Vivado_example_project]]
    puts  "ERROR: Failed to execute basic flow on example designs  "  
    delete_dir $tmpDir
    puts  "ERROR: $result" 
    return 1	
} else {
    delete_dir $tmpDir
    xhub::uninstall [xhub::get_xitems -of_objects [xhub::get_xstores Vivado_example_project]]
    puts "INFO: Succesfully ran basic tool flow on all git example designs"
} 
