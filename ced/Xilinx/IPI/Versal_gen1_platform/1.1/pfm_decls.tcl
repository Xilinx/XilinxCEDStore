#############################################################
# vrk160 Extensible CED updates for 2025.1.1 release
#############################################################
puts "INFO: Block design generation completed, yet to set PFM properties"
# Create PFM attributes

set board_name [get_property BOARD_NAME [current_board]]
puts "INFO: Creating extensible_platform for $board_name"
set pfmName "xilinx.com:${board_name}:${board_name}_base:1.0"
#set pfmName "xilinx.com:VEK385:versal_gen2_platform_base:1.0"
set_property PFM_NAME $pfmName [get_files [current_bd_design].bd]

if { $irqs eq "15" } {

	set_property PFM.IRQ {intr {id 0 range 15}}  [get_bd_cells -hierarchical axi_intc_0]
	
	# only need to declare for /ctrl_smc as v++ link will automatically cascade additional as needed
	set_property PFM.AXI_PORT { M01_AXI {} M02_AXI {} M03_AXI {} M04_AXI {} M05_AXI {} M06_AXI {} M07_AXI {} M08_AXI {} M09_AXI {} M10_AXI {} M11_AXI {} M12_AXI {} M13_AXI {} M14_AXI {} M15_AXI {} } [get_bd_cells /ctrl_smc]
}

if { $irqs eq "32" } {

	set_property PFM.IRQ {intr {id 0 range 31}}  [get_bd_cells -hierarchical axi_intc_0]
	
	set_property PFM.AXI_PORT {M03_AXI { } M04_AXI { } } [get_bd_cells -hierarchical ctrl_smc]
	set_property PFM.AXI_PORT {M01_AXI { } M02_AXI { } M03_AXI { } M04_AXI { } M05_AXI { } M06_AXI { } M07_AXI { } M08_AXI { } M09_AXI { } M10_AXI { } M11_AXI { } M12_AXI { } M13_AXI { } M14_AXI { } M15_AXI { }} [get_bd_cells -hierarchical icn_ctrl_0]
	set_property PFM.AXI_PORT {M01_AXI { } M02_AXI { } M03_AXI { } M04_AXI { } M05_AXI { } M06_AXI { } M07_AXI { } M08_AXI { } M09_AXI { } M10_AXI { } M11_AXI { } M12_AXI { } M13_AXI { } M14_AXI { } M15_AXI { }} [get_bd_cells -hierarchical icn_ctrl_1]
}
	
if { $irqs eq "63" } {

	set_property PFM.IRQ {intr {id 0 range 31}}  [get_bd_cells -hierarchical axi_intc_cascaded_1]
	
	set_property PFM.IRQ {In0 {id 32} In1 {id 33} In2 {id 34} In3 {id 35} In4 {id 36} In5 {id 37} In6 {id 38} In7 {id 39} In8 {id 40} \
	In9 {id 41} In10 {id 42} In11 {id 43} In12 {id 44} In13 {id 45} In14 {id 46} In15 {id 47} In16 {id 48} In17 {id 49} In18 {id 50} \
	In19 {id 51} In20 {id 52} In21 {id 53} In22 {id 54} In23 {id 55} In24 {id 56} In25 {id 57} In26 {id 58} In27 {id 59} In28 {id 60} \
	In29 {id 61} In30 {id 62} } [get_bd_cells -hierarchical xlconcat_0]
	
	set_property PFM.AXI_PORT {M06_AXI { } M07_AXI { } M08_AXI { }} [get_bd_cells -hierarchical ctrl_smc]
	set_property PFM.AXI_PORT {M01_AXI { } M02_AXI { } M03_AXI { } M04_AXI { } M05_AXI { } M06_AXI { } M07_AXI { } M08_AXI { } M09_AXI { } M10_AXI { } M11_AXI { } M12_AXI { } M13_AXI { } M14_AXI { } M15_AXI { }} [get_bd_cells -hierarchical icn_ctrl_0]
	set_property PFM.AXI_PORT {M01_AXI { } M02_AXI { } M03_AXI { } M04_AXI { } M05_AXI { } M06_AXI { } M07_AXI { } M08_AXI { } M09_AXI { } M10_AXI { } M11_AXI { } M12_AXI { } M13_AXI { } M14_AXI { } M15_AXI { }} [get_bd_cells -hierarchical icn_ctrl_1]
	set_property PFM.AXI_PORT {M01_AXI { } M02_AXI { } M03_AXI { } M04_AXI { } M05_AXI { } M06_AXI { } M07_AXI { } M08_AXI { } M09_AXI { } M10_AXI { } M11_AXI { } M12_AXI { } M13_AXI { } M14_AXI { } M15_AXI { }} [get_bd_cells -hierarchical icn_ctrl_2]
	set_property PFM.AXI_PORT {M01_AXI { } M02_AXI { } M03_AXI { } M04_AXI { } M05_AXI { } M06_AXI { } M07_AXI { } M08_AXI { } M09_AXI { } M10_AXI { } M11_AXI { } M12_AXI { } M13_AXI { } M14_AXI { } M15_AXI { }} [get_bd_cells -hierarchical icn_ctrl_3]

}
	
if { $use_aie } {
 
# Provision /ConfigNoc for up to AIE_NSU
# set auto false to force user to opt in to access AIE memory-map
set_property PFM.AXI_PORT { S00_AXI {sptag AIE auto false} S01_AXI {sptag AIE auto false} S02_AXI {sptag AIE auto false} S03_AXI {sptag AIE auto false} S04_AXI {sptag AIE auto false} S05_AXI {sptag AIE auto false} S06_AXI {sptag AIE auto false} S07_AXI {sptag AIE auto false} S08_AXI {sptag AIE auto false} S09_AXI {sptag AIE auto false} S10_AXI {sptag AIE auto false} S11_AXI {sptag AIE auto false} S12_AXI {sptag AIE auto false} S13_AXI {sptag AIE auto false} S14_AXI {sptag AIE auto false} S15_AXI {sptag AIE auto false} } [get_bd_cells /ConfigNoc] }

# vrk160 connectivity to NoC_C0 should be enabled (as is possible in Vivado),
# but never automatically selected.  auto false forces user to opt in to share accelerator w/PS
set_property PFM.AXI_PORT { S00_AXI {sptag LPDDR0 auto false} S01_AXI {sptag LPDDR0 auto false} S02_AXI {sptag LPDDR0 auto false} S03_AXI {sptag LPDDR0 auto false} S04_AXI {sptag LPDDR0 auto false} S05_AXI {sptag LPDDR0 auto false} S06_AXI {sptag LPDDR0 auto false} S07_AXI {sptag LPDDR0 auto false} S08_AXI {sptag LPDDR0 auto false} S09_AXI {sptag LPDDR0 auto false} S10_AXI {sptag LPDDR0 auto false} S11_AXI {sptag LPDDR0 auto false} S12_AXI {sptag LPDDR0 auto false} S13_AXI {sptag LPDDR0 auto false} S14_AXI {sptag LPDDR0 auto false} S15_AXI {sptag LPDDR0 auto false} S16_AXI {sptag LPDDR0 auto false} S17_AXI {sptag LPDDR0 auto false} S18_AXI {sptag LPDDR0 auto false} S19_AXI {sptag LPDDR0 auto false} } [get_bd_cells /NoC_C0]

# Provision /NoC_C1 for up to AIE_NMU + PL_NMU
set_property PFM.AXI_PORT { S00_AXI {sptag LPDDR1} S01_AXI {sptag LPDDR1} S02_AXI {sptag LPDDR1} S03_AXI {sptag LPDDR1} S04_AXI {sptag LPDDR1} S05_AXI {sptag LPDDR1} S06_AXI {sptag LPDDR1} S07_AXI {sptag LPDDR1} S08_AXI {sptag LPDDR1} S09_AXI {sptag LPDDR1} S10_AXI {sptag LPDDR1} S11_AXI {sptag LPDDR1} S12_AXI {sptag LPDDR1} S13_AXI {sptag LPDDR1} S14_AXI {sptag LPDDR1} S15_AXI {sptag LPDDR1} S16_AXI {sptag LPDDR1} S17_AXI {sptag LPDDR1} S18_AXI {sptag LPDDR1} S19_AXI {sptag LPDDR1} S20_AXI {sptag LPDDR1} S21_AXI {sptag LPDDR1} S22_AXI {sptag LPDDR1} S23_AXI {sptag LPDDR1} S24_AXI {sptag LPDDR1} S25_AXI {sptag LPDDR1} S26_AXI {sptag LPDDR1} S27_AXI {sptag LPDDR1} S28_AXI {sptag LPDDR1} S29_AXI {sptag LPDDR1} S30_AXI {sptag LPDDR1} S31_AXI {sptag LPDDR1} S32_AXI {sptag LPDDR1} S33_AXI {sptag LPDDR1} S34_AXI {sptag LPDDR1} S35_AXI {sptag LPDDR1} S36_AXI {sptag LPDDR1} S37_AXI {sptag LPDDR1} } [get_bd_cells /NoC_C1]

# Provision /NoC_C2 for up to AIE_NMU + PL_NMU
set_property PFM.AXI_PORT { S00_AXI {sptag LPDDR2} S01_AXI {sptag LPDDR2} S02_AXI {sptag LPDDR2} S03_AXI {sptag LPDDR2} S04_AXI {sptag LPDDR2} S05_AXI {sptag LPDDR2} S06_AXI {sptag LPDDR2} S07_AXI {sptag LPDDR2} S08_AXI {sptag LPDDR2} S09_AXI {sptag LPDDR2} S10_AXI {sptag LPDDR2} S11_AXI {sptag LPDDR2} S12_AXI {sptag LPDDR2} S13_AXI {sptag LPDDR2} S14_AXI {sptag LPDDR2} S15_AXI {sptag LPDDR2} S16_AXI {sptag LPDDR2} S17_AXI {sptag LPDDR2} S18_AXI {sptag LPDDR2} S19_AXI {sptag LPDDR2} S20_AXI {sptag LPDDR2} S21_AXI {sptag LPDDR2} S22_AXI {sptag LPDDR2} S23_AXI {sptag LPDDR2} S24_AXI {sptag LPDDR2} S25_AXI {sptag LPDDR2} S26_AXI {sptag LPDDR2} S27_AXI {sptag LPDDR2} S28_AXI {sptag LPDDR2} S29_AXI {sptag LPDDR2} S30_AXI {sptag LPDDR2} S31_AXI {sptag LPDDR2} S32_AXI {sptag LPDDR2} S33_AXI {sptag LPDDR2} S34_AXI {sptag LPDDR2} S35_AXI {sptag LPDDR2} S36_AXI {sptag LPDDR2} S37_AXI {sptag LPDDR2} } [get_bd_cells /NoC_C2]

# Provision /NoC_C3 for up to AIE_NMU + PL_NMU
set_property PFM.AXI_PORT { S00_AXI {sptag LPDDR3} S01_AXI {sptag LPDDR3} S02_AXI {sptag LPDDR3} S03_AXI {sptag LPDDR3} S04_AXI {sptag LPDDR3} S05_AXI {sptag LPDDR3} S06_AXI {sptag LPDDR3} S07_AXI {sptag LPDDR3} S08_AXI {sptag LPDDR3} S09_AXI {sptag LPDDR3} S10_AXI {sptag LPDDR3} S11_AXI {sptag LPDDR3} S12_AXI {sptag LPDDR3} S13_AXI {sptag LPDDR3} S14_AXI {sptag LPDDR3} S15_AXI {sptag LPDDR3} S16_AXI {sptag LPDDR3} S17_AXI {sptag LPDDR3} S18_AXI {sptag LPDDR3} S19_AXI {sptag LPDDR3} S20_AXI {sptag LPDDR3} S21_AXI {sptag LPDDR3} S22_AXI {sptag LPDDR3} S23_AXI {sptag LPDDR3} S24_AXI {sptag LPDDR3} S25_AXI {sptag LPDDR3} S26_AXI {sptag LPDDR3} S27_AXI {sptag LPDDR3} S28_AXI {sptag LPDDR3} S29_AXI {sptag LPDDR3} S30_AXI {sptag LPDDR3} S31_AXI {sptag LPDDR3} S32_AXI {sptag LPDDR3} S33_AXI {sptag LPDDR3} S34_AXI {sptag LPDDR3} S35_AXI {sptag LPDDR3} S36_AXI {sptag LPDDR3} S37_AXI {sptag LPDDR3} } [get_bd_cells /NoC_C3]

# Provision aggr_noc for up to AIE_NMU + PL_NMU
set_property PFM.AXI_PORT { S00_AXI {sptag LPDDR auto preferred} S01_AXI {sptag LPDDR auto preferred} S02_AXI {sptag LPDDR auto preferred} S03_AXI {sptag LPDDR auto preferred} S04_AXI {sptag LPDDR auto preferred} S05_AXI {sptag LPDDR auto preferred} S06_AXI {sptag LPDDR auto preferred} S07_AXI {sptag LPDDR auto preferred} S08_AXI {sptag LPDDR auto preferred} S09_AXI {sptag LPDDR auto preferred} S10_AXI {sptag LPDDR auto preferred} S11_AXI {sptag LPDDR auto preferred} S12_AXI {sptag LPDDR auto preferred} S13_AXI {sptag LPDDR auto preferred} S14_AXI {sptag LPDDR auto preferred} S15_AXI {sptag LPDDR auto preferred} S16_AXI {sptag LPDDR auto preferred} S17_AXI {sptag LPDDR auto preferred} S18_AXI {sptag LPDDR auto preferred} S19_AXI {sptag LPDDR auto preferred} S20_AXI {sptag LPDDR auto preferred} S21_AXI {sptag LPDDR auto preferred} S22_AXI {sptag LPDDR auto preferred} S23_AXI {sptag LPDDR auto preferred} S24_AXI {sptag LPDDR auto preferred} S25_AXI {sptag LPDDR auto preferred} S26_AXI {sptag LPDDR auto preferred} S27_AXI {sptag LPDDR auto preferred} S28_AXI {sptag LPDDR auto preferred} S29_AXI {sptag LPDDR auto preferred} S30_AXI {sptag LPDDR auto preferred} S31_AXI {sptag LPDDR auto preferred} S32_AXI {sptag LPDDR auto preferred} S33_AXI {sptag LPDDR auto preferred} S34_AXI {sptag LPDDR auto preferred} S35_AXI {sptag LPDDR auto preferred} S36_AXI {sptag LPDDR auto preferred} S37_AXI {sptag LPDDR auto preferred} } [get_bd_cells /aggr_noc]

set clocks {}
set i [set k 0]
set portl [get_property CONFIG.CLKOUT_PORT [get_ips *clk_wizard*]]
set driver [get_property CONFIG.CLKOUT_DRIVES [get_ips *clk_wizard*]]
set clk_used [get_property CONFIG.CLKOUT_USED [get_ips *clk_wizard*]]
set new_prtl [split $portl ","]
set new_d [split $driver ","]
set clk_u [split $clk_used ","]
#set freql [get_property CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [get_ips *clk_wizard*]]
set is_default false
set id_c [llength [lsearch -all $clk_u true]]

foreach { port freq id is_default} $clk_options {

	set clk_enb [lindex $clk_u $k]
	if { $clk_enb == "true"} {

		if {[regexp "MBUFGCE" $driver]} {
			
			if {($freq == 625) && ($is_default == "true" ) } {
			
			set is_default false
			set m_prt ${port}_o1
			dict append clocks ${m_prt} "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_o4\" status \"fixed_non_ref\""
		
			#incr i
			for {set j 2} {$j < 5} {incr j} {
			set m_prt ${port}_o${j}
			if {$m_prt == "${port}_o2"} {
			set is_default true }
			dict append clocks ${m_prt} "id \"$id_c\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_o4\" status \"fixed_non_ref\""
			
			set is_default false
			incr id_c
			#incr i
			}} else {
			
			dict append clocks ${port} "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed\""
			
			
		}
		incr i
	 } else {
		
		dict append clocks $port "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed\""
		
		incr i
	} 
	incr k 
	} }


set_property PFM.CLOCK $clocks [get_bd_cells -hierarchical clk_wizard_0]
#puts "clocks :: $clocks  PFM properties"

# for default case only.
if {($irqs == "15") && ($clk_defaut == "1")} {
# Change IDs to clk_wiz pin order
puts "INFO:: default clks options enabled!!"
set_property PFM.CLOCK {clk_out1_o1 {id "0" is_default false proc_sys_reset "/proc_sys_reset_o4" status "fixed_non_ref"} clk_out1_o2 {id "1" is_default true proc_sys_reset "/proc_sys_reset_o4" status "fixed_non_ref"} clk_out1_o3 {id "2" is_default false proc_sys_reset "/proc_sys_reset_o4" status "fixed_non_ref"} clk_out1_o4 {id "3" is_default false proc_sys_reset "/proc_sys_reset_o4" status "fixed_non_ref"} clk_out2 {id "4" is_default false proc_sys_reset "/proc_sys_reset_1" status "fixed"}} [get_bd_cells /clk_wizard_0]
}

#Platform Level Properties
set_property platform.default_output_type "sd_card" [current_project]
set_property platform.design_intent.embedded "true" [current_project]
set_property platform.num_compute_units $irqs [current_project]
set_property platform.design_intent.server_managed "false" [current_project]
set_property platform.design_intent.external_host "false" [current_project]
set_property platform.design_intent.datacenter "false" [current_project]
set_property platform.uses_pr  "false" [current_project]
set_property platform.extensible true [current_project]

puts "INFO: Platform creation completed!"