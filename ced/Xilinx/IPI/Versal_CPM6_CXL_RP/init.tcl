# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

 # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]

source -notrace "$currentDir/run.tcl"

# ! NOTE !
# The CED framework does not currently (10/30/26) support showing both raw
# part numbers AND board parts, you can only do one or the other. In this
# case, only the board part shows and I am just keeping this proc for future
# enhancements. If both procs are supported, then the GUI needs to limit
# selections of CXL3.1 (Gen6x8) iff the selected part is fast enough and 
# run.tcl needs to NOT generate VPK360-specific modules (like external GPIO)
# or constraints.
proc getSupportedParts {} {
  # xc2vp3602 in the vsvc3340 package, one -S part per speed/power grade.
  # The industrial (-i) part is preferred; the extended temperature (-e)
  # part is used only for grades that have no -i part. Grades with neither
  # simply contribute nothing. Maximum Gen6x8 supported from -2MP to -3H, 
  # maximum Gen6x4 supported from -1LHP to -2LHP, Gen5x8 supported by every
  # speed grade.
  set grades {1LHP 1MP 1MHP 2LHP 2MP 2MHP 3HP}
  set parts  {}
  foreach grade $grades {
    foreach temp {i e} {
      set match [get_parts -quiet xc2vp3602-vsvc3340-${grade}-${temp}-S \
                   -filter {(LICENSE=="Preproduction" || LICENSE=="Full")}]
      if {[llength $match]} {
        lappend parts {*}$match
        break
      }
    }
  }
  return $parts
}

proc getSupportedBoards {} {
 return [get_board_parts -latest_file_version -quiet \
           -filter {(BOARD_NAME=~"*vpk360*")}]
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  lappend x [dict create name "NUM_CPI" type "string" value "4" \
    value_list {"1 1" "2 2" "3 3" "4 4"} enabled true]
  lappend x [dict create name "CXL_REV" type "string" value "3.1" \
    value_list {"2.0 2.0" "3.1 3.1"} enabled true]
  lappend x [dict create name "LINK_CONFIG" type "string" \
    value "Gen6x8 (64 GB/s/dir)" enabled false]
  lappend x [dict create name "ENABLE_SIM" type "bool" value "false" \
    enabled true]
  lappend x [dict create name "SIMULATOR" type "string" value "QuestaSim" \
    value_list {"QuestaSim QuestaSim" "VCS VCS"} enabled false]
  lappend x [dict create name "SIM_LIBS_COMPILED" type "bool" value "false" \
    enabled false]
  lappend x [dict create name "SIM_LIBS_PATH" type "string" \
    value "/path/to/your/sim/libs" enabled false]
  return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  set designObj $DESIGNOBJ
  set page [ced::add_page -name "Page1" -display_name "Configuration" \
    -designObject $designObj -layout vertical]
  ced::add_param -name CXL_REV -display_name "CXL Revision" \
    -parent $page -designObject $designObj -widget comboBox
  ced::add_param -name LINK_CONFIG -display_name "Link Configuration" \
    -parent $page -designObject $designObj -widget textEdit
  ced::add_param -name NUM_CPI -display_name "Number of CPI Interfaces" \
    -parent $page -designObject $designObj -widget comboBox
  set text "<i>Higher counts can increase throughput, but increase resources and timing challenges.</i>"
  ced::add_text -designObject $designObj -name NUM_CPI_HELP -tclproc $text -parent $page

  set simPage [ced::add_page -name "Page2" -display_name "Simulation" \
    -designObject $designObj -layout vertical]
  set simText "NOTE: Enabling simulation will import a comprehensive SystemVerilog UVM testbench, framework, and set of tests with CPM6 connected to the Siemens Avery \nPCIe/CXL VIP alongside the generated Vivado project."
  ced::add_text -designObject $designObj -name SIM_HELP -tclproc $simText \
    -parent $simPage
  ced::add_param -name ENABLE_SIM -display_name "Enable Simulation" \
    -parent $simPage -designObject $designObj -widget checkBox
  ced::add_param -name SIMULATOR -display_name "Simulator" \
    -parent $simPage -designObject $designObj -widget comboBox
  ced::add_param -name SIM_LIBS_COMPILED \
    -display_name "Simulation Libraries Compiled?" \
    -parent $simPage -designObject $designObj -widget checkBox
  ced::add_param -name SIM_LIBS_PATH -display_name "Compiled Sim Libs Path" \
    -parent $simPage -designObject $designObj -widget textEdit
}

# LINK_CONFIG is a read-only, derived display of the link speed/width implied
# by CXL_REV -- always disabled, its VALUE just tracks CXL_REV's selection.
gui_updater {CXL_REV.VALUE} {LINK_CONFIG.VALUE LINK_CONFIG.ENABLEMENT} {
  set LINK_CONFIG.ENABLEMENT false
  if { ${CXL_REV.VALUE} == "2.0" } {
    set LINK_CONFIG.VALUE "Gen5x8 (32 GB/s/dir)"
  } else {
    set LINK_CONFIG.VALUE "Gen6x8 (64 GB/s/dir)"
  }
}

# Everything under the Simulation page is grayed out unless ENABLE_SIM is
# checked; SIM_LIBS_PATH is further gated on SIM_LIBS_COMPILED so a user
# can't point at a libs path until they've said the libs exist.
gui_updater {ENABLE_SIM.VALUE SIM_LIBS_COMPILED.VALUE} \
    {SIMULATOR.ENABLEMENT SIM_LIBS_COMPILED.ENABLEMENT SIM_LIBS_PATH.ENABLEMENT} {
  set SIMULATOR.ENABLEMENT ${ENABLE_SIM.VALUE}
  set SIM_LIBS_COMPILED.ENABLEMENT ${ENABLE_SIM.VALUE}
  set SIM_LIBS_PATH.ENABLEMENT \
    [expr {${ENABLE_SIM.VALUE} && ${SIM_LIBS_COMPILED.VALUE}}]
}

