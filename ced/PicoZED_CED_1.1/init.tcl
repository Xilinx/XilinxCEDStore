set currentFile [file normalize [info script]] 
set currentDir [file dirname $currentFile] 
proc getConfigDesignInfo {} { 
  return [dict create name {supercoolpicoZED} description {An Example Design by Dan}]
}

proc getSupportedParts {} { 
  return [list zynq{xc7z010clg400-1}]
}

proc getSupportedBoards {} { 
  return [list em.avnet.com:picozed_7010_fmc2:1.2]
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
  catch {source -notrace "$currentDir/supercoolpicozed_design.tcl"} retString 

  cd $curr_location
}


# Modified / commented out in supercoolpicozed_design.tcl
# BYDEM - UNUSED, COMMENT OUT NEXT LINE
#set orig_proj_dir "C:/vipi/log/2018.1/microExampleBuilder"

#BYDEM - REMOVE Absolute to cache
#set_property -name "ip_output_repo" -value "C:/vipi/log/2018.1/${_xil_proj_name_}/${_xil_proj_name_}.cache/ip" -objects $obj

#BYDEM - REMOVE Absolute to xhub location
#set_property -name "xhub.board_store.root_dir" -value "C:/vipi/repo/boards4" -objects $obj

#BYDEM - Move to local repo (copy the following hdl folder into the CED folder)
#set files [list \
# "C:/vipi/log/2018.1/microExampleBuilder/microExampleBuilder.srcs/sources_1/bd/PicoZed_Example/hdl/PicoZed_Example_wrapper.v"\
#]
#BYDEM - Add the following
#set files [list \
# "[file dirname [file normalize [info script]]]/hdl/PicoZed_Example_wrapper.v"\
#]


# Modified in design.xml
#  <DisplayName>Super Cool PicoZED Design</DisplayName>
#<Description>
#This is a Zynq-7000 based system. 
#</Description>
#<Image>ced.png</Image>
#<Image>picozed_fmc2_carrier_card.jpg</Image>

#copied .jpg into directory, copied *wrapper.v into subdirectory


###########
# SIMON FIX
#proc getSupportedBoards {} { 
#  if {[get_board_parts "em.avnet.com:picozed_7010_fmc2:1.2"] eq 0} {
#	puts "ERROR: Board \"em.avnet.com:picozed_7010_fmc2:1.2\" is not installed, please install this board prior to launching the example project"
#  }
#  return [list em.avnet.com:picozed_7010_fmc2:1.2]
#}





