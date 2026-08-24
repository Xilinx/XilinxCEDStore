
## ########################################################################
## Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
##
## Licensed under the Apache License, Version 2.0 (the "License"). You may
## not use this file except in compliance with the License. A copy of the
## License is located at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
## WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
## License for the specific language governing permissions and limitations
## under the License.
## ########################################################################
##
## Project    : Versal PCI Express Integrated Block
## File       : xilinx_pcie_versal_X1Y0.xdc
## Version    : 1.0
##-----------------------------------------------------------------------------
#
##########################################################################################################################
# Vivado - PCIe GUI / User Configuration
##########################################################################################################################
#
# Link Speed   - Gen3 - 8.0 Gb/s
# Link Width   - X8
# AXIST Width  - 256-bit
# AXIST Frequ  - 2
# AXIST Frequ  - 250
# Core Clock   - 500 MHz
# Pipe Clock   - 125 MHz (Gen1) / 250 MHz (Gen2/Gen3/Gen4) / 500 MHz (Gen4)
#
# Family       - versal
# Part         - xcvp1202
# Package      - vsva2785
# Speed grade  - -2MP
# PCIe Block   - X1Y0
# PCIe Block In- 10
# Silicon Rev  - ES1
# PLL TYPE     - LCPLL
# Xilinx RefBrd- None
#
# disable_double_pipe : false
# axist_reg_slice_en  : false
#####################################################################
# # # #  User Time Names / User Time Groups / Time Specs      # # # #
#####################################################################
create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]

set_property IOSTANDARD LVCMOS15 [get_ports sys_rst_n]
set_property PACKAGE_PIN T31 [get_ports sys_rst_n]
set_false_path -from [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]

##########################################################################################################################
# # # #                                                                                                            # # # #
##########################################################################################################################


########################################################################
#                                H10
########################################################################

#set_property LOC GTYP_REFCLK_X1Y2 [get_cells -hierarchical -filter REF_NAME==IBUFDS_GTE5]
set_property LOC GTYP_REFCLK_X1Y0 [get_cells -hierarchical -filter REF_NAME==IBUFDS_GTE5]
set_property LOC GTYP_QUAD_X1Y1 [get_cells [get_cells -hierarchical -filter PRIMITIVE_SUBGROUP==GT] -filter NAME=~*/gt_quad_1/*]
set_property LOC GTYP_QUAD_X1Y0 [get_cells [get_cells -hierarchical -filter PRIMITIVE_SUBGROUP==GT] -filter NAME=~*/gt_quad_0/*]
