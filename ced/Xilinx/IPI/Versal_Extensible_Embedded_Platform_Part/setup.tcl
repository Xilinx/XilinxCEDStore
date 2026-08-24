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

	if { [regexp {xcvm2152|xc2v|xq2v|xcvr|xcvp1902|xa2ve} $fpga_part] } {

		puts "INFO : Selected PS-Core : PS_wizard"
		
		if { [regexp {xc2vp3422|xc2vp3622} $fpga_part] } {
			puts "INFO : Selected Memory on Package Device (MoP) - Gen 2"
			source "$currentDir/run_ps_wizard_mop.tcl"

		} elseif {[regexp {xcvp1902} $fpga_part]} {
			puts "INFO : Selected Versal Premium Series"
			source "$currentDir/run_ps_wizard_premium.tcl"

		} elseif {[regexp {xa2v} $fpga_part]} {
			puts "INFO : Selected XA Versal AI Edge Series - Gen 2"
			source "$currentDir/run_ps_wizard_xa2v.tcl"
		
		} elseif {[regexp {xq2v} $fpga_part]} {
			puts "INFO : Defense Grade Versal Prime - Gen 2"
			source "$currentDir/run_ps_wizard_defence.tcl"

		} else {
			puts "INFO : Selected Device Type : PS_wizard"
			source "$currentDir/run_ps_wizard.tcl"
		}


	} elseif {[regexp "versalnet" $part_family]} {

		puts "INFO : Selected Versal Net ACAP Devices : PSX_Wizard"
		source "$currentDir/run_psx_wizard.tcl"

	} else {

		puts "INFO : CIPS PS part selected"
		source "$currentDir/run_versal_cips.tcl"
			
	}

}
