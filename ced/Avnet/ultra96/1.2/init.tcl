set currentFile [file normalize [info script]] 
set currentDir [file dirname $currentFile] 
proc getConfigDesignInfo {} { 
  return [dict create name {ultra96} description {}]
}

proc getSupportedParts {} { 
  return [list zynquplus{xczu3eg-sbva484-1-e}]
}

proc getSupportedBoards {} { 
  return [list em.avnet.com:ultra96:1.2]
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
  catch {source -notrace "$currentDir/ultra96_design.tcl"} retString 

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

	
