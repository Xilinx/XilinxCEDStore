# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source "$currentDir/run.tcl"

proc getSupportedParts {} { }

proc getSupportedBoards {} {
	return [get_board_parts -filter {(BOARD_NAME =~"*vpk360*" && VENDOR_NAME=="xilinx.com")} -latest_file_version -quiet]
}

# --------------------------------------------------------------------
# addOptions: per-controller CPM6 port type (CTRL0 / CTRL1)
# --------------------------------------------------------------------
proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  return [list \
    [dict create name "CTRL0_CONFIG" type "string" value "Disabled" enabled true \
      value_list {Disabled Endpoint Rootport}] \
    [dict create name "CTRL1_CONFIG" type "string" value "Disabled" enabled true \
      value_list {Disabled Endpoint Rootport}] \
    [dict create name "DDR_EN" type "boolean" value "false" enabled true] \
    [dict create name "CTRL0_LANE_RATE" type "string" value "64.0_GT/s" enabled true \
      value_list {64.0_GT/s 32.0_GT/s 16.0_GT/s}] \
    [dict create name "CTRL0_LINK_WIDTH" type "string" value "X8" enabled true \
      value_list {X1 X2 X4 X8}] \
    [dict create name "CTRL1_LANE_RATE" type "string" value "64.0_GT/s" enabled true \
      value_list {64.0_GT/s 32.0_GT/s 16.0_GT/s}] \
    [dict create name "CTRL1_LINK_WIDTH" type "string" value "X8" enabled true \
      value_list {X1 X2 X4 X8}] \
  ]
}

# --------------------------------------------------------------------
# addGUILayout
# --------------------------------------------------------------------
proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page  -name "Configuration" -display_name "CPM6 SoC Platform Configuration" -designObject $designObj]

    # Grouped by controller, not by parameter -- each row is one
    # controller's complete parameter set (Port Type, Link Speed, Link
    # Width together), rather than one parameter across both controllers.
    # This framework has no nested/vertical panel container (confirmed
    # against every other CED in this store), so each controller's group
    # is one horizontal row.
    set ctrl0_panel [ced::add_panel -name ctrl0_panel -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name CTRL0_CONFIG -display_name "CTRL0 Port Type" -parent $ctrl0_panel -designObject $designObj -widget comboBox
    ced::add_param -name CTRL0_LANE_RATE -display_name "CTRL0 Link Speed" -parent $ctrl0_panel -designObject $designObj -widget comboBox
    ced::add_param -name CTRL0_LINK_WIDTH -display_name "CTRL0 Link Width" -parent $ctrl0_panel -designObject $designObj -widget comboBox

    set ctrl1_panel [ced::add_panel -name ctrl1_panel -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name CTRL1_CONFIG -display_name "CTRL1 Port Type" -parent $ctrl1_panel -designObject $designObj -widget comboBox
    ced::add_param -name CTRL1_LANE_RATE -display_name "CTRL1 Link Speed" -parent $ctrl1_panel -designObject $designObj -widget comboBox
    ced::add_param -name CTRL1_LINK_WIDTH -display_name "CTRL1 Link Width" -parent $ctrl1_panel -designObject $designObj -widget comboBox

    set ddr_panel [ced::add_panel -name ddr_panel -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name DDR_EN -display_name "Use DDR" -parent $ddr_panel -designObject $designObj -widget checkBox
}
