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
#
# NOTE: Controller_0 and Dual_Controller are intentionally NOT offered
# yet -- only ctrl1/ has real design_1_bd.tcl + src content authored so
# far. The CED framework has no per-value "greyed out" mechanism for a
# value_list (confirmed by inspecting every init.tcl in this CEDStore
# checkout), so rather than list them as selectable and fail later, they
# are left out of value_list entirely until ctrl0/dual are implemented.
# Add them back here (and to run.tcl's ctrl_map) once ready.
#
# NOTE: CTRL_LINK_WIDTH is pinned to X2 -- ctrl1/design_1_bd.tcl (ported
# from a write_bd_tcl export of the reference cpm6_qdma design) hardcodes
# ps_wizard_0's CPM6_CTRL1_LINK_WIDTH to X2 and its BD-level CTRL1_GT_0
# port is only 2 bits wide. Offering X1/X4/X8 here (as BMD does) produced
# a real bitgen failure: ctrl1_qdma_ep.sv's LINK_WIDTH-sized port ended up
# wider than the BD's fixed 2-bit port, leaving bits [2]/[3] dangling at
# the top level with no I/O standard or LOC -> DRC NSTD-2/UCIO-1, bitgen
# refused (confirmed via a real synth+impl+write_device_image run). Do not
# widen this value_list until design_1_bd.tcl
# is made genuinely width-parameterized.
# --------------------------------------------------------------------
proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
  return [list \
    [dict create name "CTRL_CONFIG" type "string" value "Controller_1" enabled true \
      value_list {Controller_1}] \
    [dict create name "CTRL_LANE_RATE" type "string" value "64.0_GT/s" enabled true \
      value_list {64.0_GT/s 32.0_GT/s 16.0_GT/s} ] \
    [dict create name "CTRL_LINK_WIDTH" type "string" value "X2" enabled true \
      value_list {X2}] \
  ]
}

# --------------------------------------------------------------------
# addGUILayout
# --------------------------------------------------------------------
proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ
    set page [ced::add_page  -name "Configuration" -display_name "CPM6 QDMA Configuration" -designObject $designObj]
    ced::add_param -name CTRL_CONFIG -display_name "Controller selection" -parent $page -designObject $designObj -widget radioGroup -layout horizontal
    set panel [ced::add_panel -name panel -parent $page -designObject $designObj -layout horizontal]
    ced::add_param -name CTRL_LANE_RATE -display_name "Link Speed" -parent $panel -designObject $designObj -widget comboBox
    ced::add_param -name CTRL_LINK_WIDTH -display_name "Link width" -parent $panel -designObject $designObj -widget comboBox
}
