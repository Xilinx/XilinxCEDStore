set currentFile [file normalize [info script]] 
set currentDir [file dirname $currentFile] 
proc getConfigDesignInfo {} { 
  return [dict create name {arty-s7-50-RT} description {}]
}

proc getSupportedParts {} { 
  return [list spartan7{xc7s50csga324-1}]
}

proc getSupportedBoards {} { 
  return [list digilentinc.com:arty-s7-50:1.0]
}

#proc addOptions {DESIGNOBJ} { 
  #This proc is intended for declaring configurable options for this design
#}

#proc addGUILayout {DESIGNOBJ} { 
  #This proc is intended for gui layout information of configurable options
#}

#DO NOT MODIFY THIS PROC 
proc isGeneratedFromWriteProjectTcl {DESIGNOBJ} { 
  return true 
}

proc createDesign { project_name {project_location "."} {options ""}} { 
  variable currentDir
  set ::user_project_name $project_name
  set curr_location [pwd]
  cd $project_location
  #set ::user_project_location $project_location
  catch {source -notrace "$currentDir/arty-s7-50-RT_design.tcl"} retString 

  cd $curr_location
}




#############################


set origmeXHBS [get_param misc.enableXHubBoardStore]
set origgeXHBS [get_param gui.enableXHubBoardStore]
#disable XHUB settings
set_param misc.enableXHubBoardStore false
set_param gui.enableXHubBoardStore false

# Update board.repoPaths
set localBoardRepoPath "board_files"
set currentBoardRepoPaths [get_param board.repoPaths]
lappend currentBoardRepoPaths  [file normalize [file join  [file dirname [file normalize [info script]] ]  $localBoardRepoPath  ]]  
set_param board.repoPaths $currentBoardRepoPaths

#revert XHUB settings
set_param misc.enableXHubBoardStore $origmeXHBS
set_param gui.enableXHubBoardStore $origgeXHBS

	
