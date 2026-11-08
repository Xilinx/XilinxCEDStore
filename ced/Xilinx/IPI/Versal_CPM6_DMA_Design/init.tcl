# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source "$currentDir/run.tcl"

proc getSupportedParts {} {
    return [get_parts {xc2vp3*} -quiet]
}

proc getSupportedBoards {} {
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    lappend x [dict create name "CTRL_CONFIG" type "string" \
        value "Controller_1" \
        value_list {Controller_0 Controller_1} \
        enabled true]
    lappend x [dict create name "DDR_EN" type "boolean" \
        value "false" \
        enabled true]
    lappend x [dict create name "IDE_CAP_EN" type "boolean" \
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

proc get_ddr_note_text1 {args} {
    return "Note: DDR option is supported only for VPK360 board parts (xc2vp3602-vsvc3340)."
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page -name "Configuration" -display_name "CPM6 DMA Configuration" -designObject $designObj]

    ced::add_param -name CTRL_CONFIG -display_name "Controller selection" -parent $page -designObject $designObj -widget radioGroup -layout horizontal

    # Panel for DDR option & note
    set dma [ced::add_panel -name dma -parent $page -designObject $designObj -layout vertical]
    ced::add_param -name DDR_EN -display_name "Use DDR (DDR + BRAM)" -parent $dma -designObject $designObj -widget checkBox

    # Text note using -tclproc
    ced::add_text -name "ddr_note" -tclproc [get_ddr_note_text1] -parent $dma -designObject $designObj
    
    set panel1 [ced::add_panel -name panel1 -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name IDE_CAP_EN -display_name "IDE (Integrity and Data Encryption)" -parent $panel1 -designObject $designObj -widget checkBox

    set panel2 [ced::add_panel -name panel2 -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name NUM_PFS -display_name "Num of PFs" -parent $panel2 -designObject $designObj -widget comboBox

    set panel3 [ced::add_panel -name panel3 -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name CTRL_LANE_RATE -display_name "Link Speed" -parent $panel3 -designObject $designObj -widget comboBox
    ced::add_param -name CTRL_LINK_WIDTH -display_name "Link width" -parent $panel3 -designObject $designObj -widget comboBox
}

# ========================================================================
# Dynamic Updaters
# Add any future conditions directly in these blocks
# ========================================================================

# Controls enablement and value reset
updater {PROJECT_PARAM.PART} {DDR_EN.ENABLEMENT DDR_EN.VALUE} {
    if {[string match -nocase "xc2vp3602-vsvc3340*" ${PROJECT_PARAM.PART}]} {
        set DDR_EN.ENABLEMENT true
    } else {
        set DDR_EN.ENABLEMENT false
        set DDR_EN.VALUE false
    }
}