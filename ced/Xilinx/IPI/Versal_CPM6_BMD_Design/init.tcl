# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source "$currentDir/run.tcl"

proc getSupportedParts {} { return [get_parts xc2vp3602*] }

proc getSupportedBoards {} { }

# --------------------------------------------------------------------
# addOptions: Controller config + lane rate + link width
# --------------------------------------------------------------------
proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  return [list \
    [dict create name "CTRL_CONFIG" type "string" value "Controller_1" enabled true \
      value_list {Controller_0 Controller_1 Dual_Controller}] \
    [dict create name "CTRL_LANE_RATE" type "string" value "64.0_GT/s" enabled true \
      value_list {64.0_GT/s 32.0_GT/s 16.0_GT/s} ] \
    [dict create name "CTRL_LINK_WIDTH" type "string" value "X4" enabled true \
      value_list {X1 X2 X4 X8}] \
  ]
}

# --------------------------------------------------------------------
# addGUILayout
# --------------------------------------------------------------------
proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page  -name "Configuration" -display_name "CPM6 BMD Configuration" -designObject $designObj]    
    ced::add_param -name CTRL_CONFIG -display_name "Controller selection" -parent $page -designObject $designObj -widget radioGroup -layout horizontal
    set panel [ced::add_panel -name panel -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name CTRL_LANE_RATE -display_name "Link Speed" -parent $panel -designObject $designObj -widget comboBox
    ced::add_param -name CTRL_LINK_WIDTH -display_name "Link width" -parent $panel -designObject $designObj -widget comboBox
}
