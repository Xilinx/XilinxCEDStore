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
# addOptions: Controller config + DMA mode + lane rate + link width
#
# DMA_MODE selects the QDMA data path. Memory_Mapped builds ctrl1/ (H2C/C2H
# to AXI memory); Streaming builds ctrl1_st/ (H2C/C2H AXI4-Stream with the
# streaming example design). The QDMA IP supports one mode per instance.
#
# NOTE: CTRL_LINK_WIDTH offers X2 and X8. The block designs set
# CPM6_CTRL1_LINK_WIDTH from this option, and the controller-1 GT port and
# the top-level GT ports (LINK_WIDTH in defines.sv) follow it.
# --------------------------------------------------------------------
proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  return [list \
    [dict create name "CTRL_CONFIG" type "string" value "Controller_1" enabled true \
      value_list {Controller_1}] \
    [dict create name "DMA_MODE" type "string" value "Memory_Mapped" enabled true \
      value_list {Memory_Mapped Streaming}] \
    [dict create name "CTRL_LANE_RATE" type "string" value "64.0_GT/s" enabled true \
      value_list {64.0_GT/s 32.0_GT/s 16.0_GT/s} ] \
    [dict create name "CTRL_LINK_WIDTH" type "string" value "X2" enabled true \
      value_list {X2 X8}] \
  ]
}

# --------------------------------------------------------------------
# addGUILayout
# --------------------------------------------------------------------
proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page  -name "Configuration" -display_name "CPM6 QDMA Configuration" -designObject $designObj]
    ced::add_param -name CTRL_CONFIG -display_name "Controller selection" -parent $page -designObject $designObj -widget radioGroup -layout horizontal
    ced::add_param -name DMA_MODE -display_name "DMA mode" -parent $page -designObject $designObj -widget radioGroup -layout horizontal
    set panel [ced::add_panel -name panel -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name CTRL_LANE_RATE -display_name "Link Speed" -parent $panel -designObject $designObj -widget comboBox
    ced::add_param -name CTRL_LINK_WIDTH -display_name "Link width" -parent $panel -designObject $designObj -widget comboBox
    ced::add_image -name Image -parent $page -designObject $designObj -width 600 -height 280 -layout vertical
}

# Block design picture for the selected DMA mode
updater {PROJECT_PARAM.BOARD_PART DMA_MODE.VALUE} {Image.IMAGE_PATH} {
  if { ${DMA_MODE.VALUE} == "Streaming" } {
    set Image.IMAGE_PATH "cpm6_qdma_g6x2_st.png"
  } else {
    set Image.IMAGE_PATH "cpm6_qdma_g6x2_mm.png"
  }
}
