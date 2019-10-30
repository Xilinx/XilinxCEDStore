# ########################################################################
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

#      http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

set currentFile [file normalize [info script]] 
set currentDir [file dirname $currentFile] 
proc getConfigDesignInfo {} { 
  return [dict create name {MicroBlaze_Application_Configuration_for_SP701} description {}]
}

proc getSupportedParts {} { 
}

proc getSupportedBoards {} { 
  return [list xilinx.com:sp701:1.0]
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
  catch {source -notrace "$currentDir/MicroBlaze_Application_Configuration_for_SP701_design.tcl"} retString 

  cd $curr_location
}

