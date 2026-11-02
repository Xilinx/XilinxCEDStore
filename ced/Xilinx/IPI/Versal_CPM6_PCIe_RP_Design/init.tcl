########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
########################################################################
# Entry point for the Versal CPM6 PCIe Root Port CED. Source THIS file, not
# run.tcl - `currentDir` is set here and read by createDesign.
#
# Option values use underscores, NOT spaces - the GUI renders them verbatim
# and splits on whitespace, so "AXI BRIDGE" would show as just "BRIDGE".
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source "$currentDir/run.tcl"

proc getSupportedParts {} {
  return [get_parts {xc2vp3602-vsvc3340-3HP-e-S xc2vp3602-vsvc3340-2LHP-e-S}]
}

# Left empty - the DDR variant's pin constraints (constrs/ddr_vpk360.xdc)
# carry the board assumption instead.
proc getSupportedBoards {} {
}

# --------------------------------------------------------------------
# addOptions: design mode + controller config + DDR + lane rate + link width
# --------------------------------------------------------------------
proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    lappend x [dict create name "DESIGN_MODE" type "string" \
        value "AXI_Bridge" \
        value_list {AXI_Bridge PL_Streaming} \
        enabled true]
    lappend x [dict create name "CTRL_CONFIG" type "string" \
        value "Controller_1" \
        value_list {Controller_0 Controller_1} \
        enabled true]
    lappend x [dict create name "DDR_EN" type "boolean" \
        value "false" \
        enabled true]
    lappend x [dict create name "CTRL_LANE_RATE" type "string" \
        value "64.0_GT/s" \
        value_list {16.0_GT/s 32.0_GT/s 64.0_GT/s} \
        enabled true]
    lappend x [dict create name "CTRL_LINK_WIDTH" type "string" \
        value "X8" \
        value_list {X2 X4 X8} \
        enabled true]
    return $x
}

# --------------------------------------------------------------------
# addGUILayout
# --------------------------------------------------------------------
proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
    set designObj $DESIGNOBJ

    # Grey out LPDDR5 when the mode is PL_Streaming - there is no NoC/LPDDR5 leg.
    ced::utils::init_utils [namespace current] $designObj
    updater {DESIGN_MODE.VALUE} {DDR_EN.ENABLEMENT} {
        if {${DESIGN_MODE.VALUE} eq "PL_Streaming"} {
            set DDR_EN.ENABLEMENT false
        } else {
            set DDR_EN.ENABLEMENT true
        }
    }

    set page [ced::add_page -name "Configuration" \
                            -display_name "CPM6 PCIe Root Port Configuration" \
                            -designObject $designObj]

    ced::add_param -name DESIGN_MODE -display_name "Design mode" \
                   -parent $page -designObject $designObj \
                   -widget radioGroup -layout horizontal

    ced::add_param -name CTRL_CONFIG -display_name "Controller selection" \
                   -parent $page -designObject $designObj \
                   -widget radioGroup -layout horizontal

    set ddr [ced::add_panel -name ddr -parent $page -designObject $designObj \
                            -layout horizontal]
    ced::add_param -name DDR_EN -display_name "LPDDR5 via NoC" \
                   -parent $ddr -designObject $designObj -widget checkBox

    set link [ced::add_panel -name link -parent $page -designObject $designObj \
                             -layout horizontal]
    ced::add_param -name CTRL_LANE_RATE -display_name "Link Speed" \
                   -parent $link -designObject $designObj -widget comboBox
    ced::add_param -name CTRL_LINK_WIDTH -display_name "Link width" \
                   -parent $link -designObject $designObj -widget comboBox
}
