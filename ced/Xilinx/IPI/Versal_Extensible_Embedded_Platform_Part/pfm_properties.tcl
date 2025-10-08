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

set fpga_part [get_property PART [current_project ]]
set part1 [split $fpga_part "-"]
set part [lindex $part1 0]

puts "INFO: Creating extensible_platform for part:: $fpga_part"
set pfmName "xilinx.com:${fpga_part}:extensible_platform_base:1.0"

# Set PFM properties for M_AXI ports
if { $irqs eq "15" } {

	puts "PFM_INFO: 15 IRQs selected"
	set_property PFM.IRQ {intr {id 0 range 15}} [get_bd_cells /axi_intc_0]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells /icn_ctrl]
}

if { $irqs eq "32" } {
	
	puts "PFM_INFO: 32 IRQs selected"
	set_property PFM.IRQ {intr {id 0 range 31}} [get_bd_cells /axi_intc_0]
	
	set_property PFM.AXI_PORT {M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} } [get_bd_cells axi_smc_vip_hier/icn_ctrl]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_0]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_1]
}

if { $irqs eq "63" } {

	puts "PFM_INFO: 63 IRQs selected"
	set_property PFM.IRQ {intr {id 0 range 32}} [get_bd_cells /axi_intc_cascaded_1]
	
	set_property PFM.IRQ {In0 {id 32} In1 {id 33} In2 {id 34} In3 {id 35} In4 {id 36} In5 {id 37} In6 {id 38} In7 {id 39} In8 {id 40} \
	In9 {id 41} In10 {id 42} In11 {id 43} In12 {id 44} In13 {id 45} In14 {id 46} In15 {id 47} In16 {id 48} In17 {id 49} In18 {id 50} \
	In19 {id 51} In20 {id 52} In21 {id 53} In22 {id 54} In23 {id 55} In24 {id 56} In25 {id 57} In26 {id 58} In27 {id 59} In28 {id 60} \
	In29 {id 61} In30 {id 62} } [get_bd_cells /xlconcat_0]
	
	set_property PFM.AXI_PORT {M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_0]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_1]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_2]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_3]
	
}

# Get the number of PL NMU from noc model
set num_pl_nmu [get_propert NUM_PL_NMU [get_noc_model]]

#  Note : Hard-coding num_pl_nmu for listed parts
if { ([regexp "xcvp1902" $fpga_part]) || ([regexp "xcvp2802" $fpga_part]) || ([regexp "xcvp1802" $fpga_part]) } {
	set num_pl_nmu 97
}

# Dynamically set PFM.AXI_PORT for /noc2_ddr5 based on num_pl_nmu
set ddr_axi_ports {}

for {set i 0} {$i < $num_pl_nmu} {incr i} {
	append ddr_axi_ports "S[format "%02d" $i]_AXI {memport \"S_AXI_NOC\" sptag \"DDR\"} "
}

set_property PFM.AXI_PORT $ddr_axi_ports [get_bd_cells $noc_ddr]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells $noc_ddr]

if { $use_lpddr } {
	
	puts "PFM_INFO: LPDDR selected"

	# Dynamically set PFM.AXI_PORT for /noc2_lpddr5 based on num_pl_nmu
	set lpddr_axi_ports {}
	
	for {set i 0} {$i < $num_pl_nmu} {incr i} {
		append lpddr_axi_ports "S[format "%02d" $i]_AXI {memport \"S_AXI_NOC\" sptag \"LPDDR\"} "
	}

	set_property PFM.AXI_PORT $lpddr_axi_ports [get_bd_cells $noc_lpddr]
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells $noc_lpddr]

}

set_property PFM_NAME $pfmName [get_files ${pfm_bd_name}.bd]


set clocks {}

set i 0

if {[regexp "xc2v" $fpga_part]} {
	foreach { port freq id is_default } $clk_options {
		dict append clocks $port "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed_non_ref\""
		incr i
	} 
} else {
	foreach { port freq id is_default } $clk_options {
		dict append clocks $port "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed\""
		incr i
	} 
}


set_property PFM.CLOCK $clocks [get_bd_cells /clk_wizard_0]
#puts "clocks :: $clocksPFM properties"


# Platform Level Properties
set_property platform.default_output_type "sd_card" [current_project]
set_property platform.design_intent.embedded "true" [current_project]
set_property platform.num_compute_units $irqs [current_project]
set_property platform.design_intent.server_managed "false" [current_project]
set_property platform.design_intent.external_host "false" [current_project]
set_property platform.design_intent.datacenter "false" [current_project]
set_property platform.uses_pr "false" [current_project]
set_property platform.extensible true [current_project]

puts "INFO: Platform creation completed!"


if { $bdc eq "true" } {
	open_bd_design [get_bd_files $design_name] 
}

# Add USER_COMMENTS on $design_name
# set_property USER_COMMENTS.comment0 "An Example Versal Extensible Embedded Platform" [get_bd_designs $design_name]

if { $use_aie eq "true" } {
	
	set_property USER_COMMENTS.comment0 {\t \t \t =============== >>>> An Example Versal Extensible Embedded Platform <<<< ===============
	\t Note: 
	\t --> SD boot mode and UART are enabled in the CIPS / PS Wizard
	\t --> AI Engine control path is connected to CIPS / PS Wizard
	\t --> V++ will connect AI Engine data path automatically
	\t --> Execute TCL command: launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation} [current_bd_design]

} else {
	
	set_property USER_COMMENTS.comment0 {\t \t \t =============== >>>> An Example Versal Extensible Embedded Platform <<<< ===============
	\t Note: 
	\t --> SD boot mode and UART are enabled in the CIPS / PS Wizard
	\t --> Execute TCL command: launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation} [current_bd_design]
}

# Perform GUI Layout

if { $use_aie == "true" } {
 
	regenerate_bd_layout -layout_string {
		"ActiveEmotionalView":"Default View",
		"comment_0":"\t \t \t =============== >>>> An Example Versal Extensible Embedded Platform <<<< ===============
			\t Note: 
			\t --> SD boot mode and UART are enabled in the CIPS / PS Wizard
			\t --> AI Engine control path is connected to CIPS / PS Wizard
			\t --> V++ will connect AI Engine data path automatically
			\t --> Execute TCL command: launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.",
		"commentid":"comment_0|",
		"font_comment_0":"14",
		"guistr":"# # String gsaved with Nlview 7.0r42019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
			#-string -flagsOSRD
			preplace cgraphic comment_0 place right -1500 -145 textcolor 4 linecolor 3
			",
		"linktoobj_comment_0":"",
		"linktotype_comment_0":"bd_design" }
 
 } else {
 
	regenerate_bd_layout -layout_string {
		"ActiveEmotionalView":"Default View",
		"comment_0":"\t \t \t =============== >>>> An Example Versal Extensible Embedded Platform <<<< ===============
			\t Note: 
			\t --> SD boot mode and UART are enabled in the CIPS / PS Wizard
			\t --> Execute TCL command: launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.",
		"commentid":"comment_0|",
		"font_comment_0":"14",
		"guistr":"# # String gsaved with Nlview 7.0r42019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
			#-string -flagsOSRD
			preplace cgraphic comment_0 place right -1500 -130 textcolor 4 linecolor 3
			",
		"linktoobj_comment_0":"",
		"linktotype_comment_0":"bd_design" }
}