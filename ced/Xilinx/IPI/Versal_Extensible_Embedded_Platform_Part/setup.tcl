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

	if { [regexp "xcvm2152" $fpga_part] || [regexp "xc2v" $fpga_part] || [regexp "xcvr1652" $fpga_part]|| [regexp "xcvr1602" $fpga_part] || [regexp "xc10S70" $fpga_part] || [regexp "xc10T21" $fpga_part] } {

		puts "INFO : PS_wizard part selected"
		source "$currentDir/run_ps_wizard.tcl"

	} elseif {[regexp "xcvp1902" $fpga_part]} {

		puts "INFO : PS_wizard part selected : Versal Premium Series"
		source "$currentDir/run_p.tcl"
	} else {

		source "$currentDir/run.tcl"
		puts "INFO : CIPS PS part selected"
		
	}

}
