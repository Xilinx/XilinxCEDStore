#########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
###########################################################################

set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */addn_ui_clkout1}]
set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}]



set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# ### uncomment below constraints for using Dual flash #######
# set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
# set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
# set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
# set_property BITSTREAM.CONFIG.SPI_OPCODE 8'h6B [current_design]
# set_property CONFIG_MODE SPIx8 [current_design]
# set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
# set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]
# set_property CONFIG_VOLTAGE 1.8 [current_design]  