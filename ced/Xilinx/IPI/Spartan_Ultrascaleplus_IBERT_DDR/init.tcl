# ########################################################################
# Copyright (C) 2021, Xilinx Inc - All rights reserved
# 
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################


set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
variable logStuff 1

source -notrace "$currentDir/logic_help.tcl"

#
#  required for CED, return all versal parts
#
proc getSupportedParts {} {
  return ""
}

#
#  Only allow latest VCK190/VMK180/VCK120
#
proc getSupportedBoards {} {
#  set boards [list vck190 vmk180 vpk120 vhk158]
  set boards [list]
  if {[string length [get_board_parts -filter {BOARD_NAME=~"*scu200" && VENDOR_NAME=="xilinx.com"}]] != 0 } {
    lappend boards "scu200"
  } 
  set r [list]
  foreach b $boards {
    set p [lindex [get_board_parts *${b}:* -latest_file_version] 0]
    lappend r [get_boards -of $p]
  }

  return $r
}

#
#  Helper function to get  
#  
proc range {from to} {
   if {$to>$from} {concat [range $from [incr to -1]] $to}
}

#
#  Conditional puts
#
proc log {args} {
  variable logStuff
  if {$logStuff == 1} {
    puts [join $args " "]
  }
}


#
# Required by CED, will create dict of all the options needed to configure the CED, will be tied to 
# gui controls in addGUILayout
#
proc addOptions {DESIGNOBJ PROJECT_PARAM.PART PROJECT_PARAM.PACKAGE PROJECT_PARAM.SPEEDGRADE} {
  variable currentDir 
  
  set systemTime [clock seconds]
  log "addOptions:: [clock format $systemTime -format %H:%M:%S]"
  log "$DESIGNOBJ ${PROJECT_PARAM.PART} ${PROJECT_PARAM.PACKAGE} ${PROJECT_PARAM.SPEEDGRADE}"

}

#
#  Required by CED, create parameters, which are GUI controls to be displayed in the CED
#
proc addGUILayout {DESIGNOBJ PROJECT_PARAM.PART PROJECT_PARAM.PACKAGE PROJECT_PARAM.SPEEDGRADE} {


}

proc createDesign {design_name options} {
  variable currentDir
  puts $currentDir
  puts "createDesign options: $options"
  set board [lindex [split [get_property board_part [current_project]] ":"] 1]
  log "board: $board"
  source ${currentDir}/chipscopy_ex_bd.tcl
  set proj_name [lindex [get_projects] 0]
  set proj_dir [get_property DIRECTORY $proj_name]
  set_property TARGET_LANGUAGE Verilog $proj_name

  switch $board {
    scu200 {
      create_ip -name ibert_ultrascale_gth -vendor xilinx.com -library ip -version 1.4 -module_name ibert_ultrascale_gth_0
      set_property -dict [list \
  	CONFIG.C_PROTOCOL_QUAD1 {Custom_1_/_5_Gbps} \
  	CONFIG.C_PROTOCOL_QUAD_COUNT_1 {2} \
  	CONFIG.C_PROTOCOL_REFCLK_FREQUENCY_1 {156.25} \
  	CONFIG.C_REFCLK_SOURCE_QUAD_0 {MGTREFCLK0_223} \
  	CONFIG.C_SYSCLK_FREQUENCY {200} \
  	CONFIG.C_SYSCLK_IO_PIN_LOC_P {V28} \
  	CONFIG.C_SYSCLK_IO_PIN_STD {LVDS} \
      ] [get_ips ibert_ultrascale_gth_0]
      add_files -norecurse "${currentDir}/ibert_design.v"	    
      create_root_design_scu200 ""
      import_files -fileset constrs_1 -norecurse -flat "${currentDir}/constraints/ibert.xdc"
      import_files -fileset constrs_1 -norecurse -flat "${currentDir}/constraints/ibert_only_impl.xdc"
      set_property used_in_synthesis false [get_files  ${proj_dir}/${proj_name}.srcs/constrs_1/imports/ibert_only_impl.xdc]
    }
  }
  
  make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
  add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
  set_property top spartan_ultrascaleplus_ibert_ddr_wrapper [current_fileset]
  open_bd_design [get_bd_designs -filter {NAME == "spartan_ultrascaleplus_ibert_ddr"}]
  # exec echo "PHASE_DONE" > ${proj_dir}/[current_project].srcs/[current_fileset]/bd/chipscopy/ip/chipscopy_noc_tg_0/chipscopy_noc_tg_0_synth_pattern.csv
}
