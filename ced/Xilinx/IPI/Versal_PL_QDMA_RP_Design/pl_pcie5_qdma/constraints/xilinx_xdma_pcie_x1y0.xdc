# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################
##
## Project    : The PCI Express DMA
## File       : xilinx_xdma_pcie_x1y0.xdc
## Version    : 5.0
##-----------------------------------------------------------------------------
#
##########################################################################################################################
# Vivado - PCIe GUI / User Configuration
##########################################################################################################################
#
# Link Speed   - Gen4 - 16.0 Gb/s
# Link Width   - X8
# AXIST Width  - 512-bit
# AXIST Frequ  - 250
# Core Clock   - 500 MHz
# Pipe Clock   - 125 MHz (Gen1) / 250 MHz (Gen2/Gen3/Gen4) / 500 MHz (Gen4)
#
# Family       - versal
# Part         - xcvp1202
# Package      - vsva2785
# Speed grade  - -2MHP
# Xilinx RefBrd- None
#
##########################################################################################################################
# # # #                            User Time Names / User Time Groups / Time Specs                                 # # # #
##########################################################################################################################
#create_clock -name sys_clk -period 5 [get_ports sys_clk0_0_clk_p]
create_clock -period 10.000 -name pcie_ref_clk [get_ports pcie_refclk_clk_p]
#create_clock -name pl_ref_clk -period 5 [get_pins {bridge_rp_i/versal_cips_0/pl0_ref_clk}]

#set_clock_groups -asynchronous -group {pl_ref_clk} -group {pcie_ref_clk}
#set_clock_groups -asynchronous -group {pcie_ref_clk} -group {pl_ref_clk}
#
#set_property IOSTANDARD LVCMOS15 [get_ports sys_reset_0]
#set_property PACKAGE_PIN N35 [get_ports sys_reset_0]
#set_property PULLUP true [get_ports sys_reset_0]
##set_false_path -from [get_ports sys_rst_n]
##########################################################################################################################
# # # #                                                                                                            # # # #
##########################################################################################################################
#

#set_property LOC GTYP_REFCLK_X1Y3 [get_cells -hierarchical -filter REF_NAME==IBUFDS_GTE5]
set_property LOC GTYP_REFCLK_X1Y1 [get_cells -hierarchical -filter REF_NAME==IBUFDS_GTE5]
#set_property LOC GTYP_QUAD_X1Y1   [get_cells $gt_quads -filter NAME=~*/gt_quad_1/*]
set_property LOC GTYP_QUAD_X1Y0 [get_cells [get_cells -hierarchical -filter PRIMITIVE_SUBGROUP==GT] -filter NAME=~*/gt_quad_base_0*/*]

#

#########################################################################
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.GENERAL.WRITE0FRAMES No [current_design]
set_property BITSTREAM.GENERAL.PROCESSALLVEAMS true [current_design]
########################################################################
set_multicycle_path -setup -to [get_pins -filter {REF_PIN_NAME=~PCIELTSSM[*]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]] 2
set_multicycle_path -hold -to [get_pins -filter {REF_PIN_NAME=~PCIELTSSM[*]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]] 1
#


