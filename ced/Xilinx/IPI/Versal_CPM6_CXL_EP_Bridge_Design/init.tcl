# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source "$currentDir/run.tcl"

proc getSupportedParts {} {
  return [get_parts {xc2vp3602-vsvc3340-3HP-e-S}]
}

proc getSupportedBoards {} {
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  return [list \
    [dict create name "CTRL_CONFIG" type "string" value "Controller_1" enabled true \
      value_list {Controller_0 Controller_1}] \
    [dict create name "CXL_PROTOCOL" type "string" value "256B_Flit" enabled true \
      value_list {256B_Flit 68B_Flit}] \
    [dict create name "CXL_WIDTH" type "string" value "x8" enabled true \
      value_list {x4 x8}] \
  ]
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page  -name "Configuration" -display_name "CXL EP Bridge Configuration" -designObject $designObj]
    ced::add_param -name CTRL_CONFIG  -display_name "Controller selection" -parent $page -designObject $designObj -widget radioGroup -layout horizontal
    ced::add_param -name CXL_PROTOCOL -display_name "CXL Protocol (Gen6=CXL3.1, Gen5=CXL2.0)" -parent $page -designObject $designObj -widget radioGroup -layout horizontal
    ced::add_param -name CXL_WIDTH -display_name "Link Width (x4 or x8)" -parent $page -designObject $designObj -widget radioGroup -layout horizontal
}
