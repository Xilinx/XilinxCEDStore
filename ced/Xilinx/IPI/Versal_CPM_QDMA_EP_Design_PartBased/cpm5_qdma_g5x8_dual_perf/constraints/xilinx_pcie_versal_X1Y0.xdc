
##-----------------------------------------------------------------------------
##
## (c) Copyright 2017-2019 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
##-----------------------------------------------------------------------------
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



