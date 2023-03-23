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



proc createDesign {design_name options} {  

 ##################################################################
 # DESIGN PROCs													 
 ##################################################################
variable currentDir
set_property target_language Verilog [current_project]

set fpga_part [get_property PART [current_project ]]
set part_family [get_property FAMILY $fpga_part]
 if { $part_family == "versalnetes1" } {
} else {
source "$currentDir/run.tcl"
}

}




