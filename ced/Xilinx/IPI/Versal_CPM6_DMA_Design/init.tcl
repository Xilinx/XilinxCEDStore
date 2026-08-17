# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source "$currentDir/run.tcl"

proc getSupportedParts {} {
  return [get_parts {xc2vp3602-vsvc3340-3HP-e-S xc2vp3602-vsvc3340-2LHP-e-S}]
}

proc getSupportedBoards {} {
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    lappend x [dict create name "CTRL_CONFIG" type "string" \
        value "CONTROLLER1" \
        value_list {CONTROLLER0 CONTROLLER1} \
        enabled true]
    lappend x [dict create name "DDR_EN" type "boolean" \
        value "false" \
        enabled true]
    lappend x [dict create name "NUM_PFS" type "string" \
        value "1" \
        value_list {1 8} \
        enabled true]
    lappend x [dict create name "CTRL_LANE_RATE" type "string" \
        value "64.0_GT/s" \
        value_list {16.0_GT/s 32.0_GT/s 64.0_GT/s} \
        enabled true]
    lappend x [dict create name "CTRL_LINK_WIDTH" type "string" \
        value "X8" \
        value_list {X1 X2 X4 X8} \
        enabled true]
    return $x
}


proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page  -name "Configuration" -display_name "CPM6 DMA Configuration" -designObject $designObj]    
    ced::add_param -name CTRL_CONFIG -display_name "Controller selection" -parent $page -designObject $designObj -widget radioGroup -layout horizontal
    set hdma [ced::add_panel -name hdma -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name DDR_EN -display_name "DDR Mode" -parent $hdma -designObject $designObj -widget checkBox
    set panel2 [ced::add_panel -name panel2 -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name NUM_PFS -display_name "Num of PFs" -parent $panel2 -designObject $designObj -widget comboBox
    set panel3 [ced::add_panel -name panel3 -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name CTRL_LANE_RATE -display_name "Link Speed" -parent $panel3 -designObject $designObj -widget comboBox
    ced::add_param -name CTRL_LINK_WIDTH -display_name "Link width" -parent $panel3 -designObject $designObj -widget comboBox
}

