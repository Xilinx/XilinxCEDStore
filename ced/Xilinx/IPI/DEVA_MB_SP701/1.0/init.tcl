set currentFile [file normalize [info script]] 
set currentDir [file dirname $currentFile] 
proc getConfigDesignInfo {} { 
  return [dict create name {DEVA_MB_AC701} description {}]
}

proc getSupportedParts {} { 
}

proc getSupportedBoards {} { 
  return [list xilinx.com:ac701:1.3]
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
  catch {source -notrace "$currentDir/DEVA_MB_AC701_design.tcl"} retString 

  cd $curr_location
}

