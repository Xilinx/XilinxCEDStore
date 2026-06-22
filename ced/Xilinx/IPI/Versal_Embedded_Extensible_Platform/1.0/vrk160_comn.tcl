# ########################################################################
# Copyright (C) 2023, Advanced Micro Devices Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

 # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

proc create_root_design {currentDir design_name} {

open_bd_design [get_bd_files $design_name]

instantiate_example_design -template xilinx.com:design:edf_base:1.0 -design $design_name

open_bd_design [get_bd_files $design_name]


set board_name [get_property BOARD_NAME [current_board]]

source -notrace "$currentDir/vrk160_update_bd.tcl" 

}


