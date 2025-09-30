#############################################################
# vrk160/vrk165 Extensible CED updates for 2025.2 release
#############################################################
puts "INFO: Block design generation completed, yet to set PFM properties"
# Create PFM attributes

set board_name [get_property BOARD_NAME [current_board]]
puts "INFO: Creating extensible_platform for $board_name"
set pfmName "xilinx.com:${board_name}:${board_name}_base:1.0"
set_property PFM_NAME $pfmName [get_files [current_bd_design].bd]

# /axi_intc supports up to 32 PL interrupts 
set_property PFM.IRQ {intr {id 0 range 31}} [get_bd_cells /axi_intc_0]

# only need to declare for /ctrl_smc as v++ link will automatically cascade additional as needed
set_property PFM.AXI_PORT { M01_AXI {} M02_AXI {} M03_AXI {} M04_AXI {} M05_AXI {} M06_AXI {} M07_AXI {} M08_AXI {} M09_AXI {} M10_AXI {} M11_AXI {} M12_AXI {} M13_AXI {} M14_AXI {} M15_AXI {} } [get_bd_cells /ctrl_smc]
	
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

# Change IDs to clk_wiz pin order
set_property PFM.CLOCK {clk_out1_o1 {id "0" is_default false proc_sys_reset "/proc_sys_reset_o4" status "fixed_non_ref"} clk_out1_o2 {id "1" is_default true proc_sys_reset "/proc_sys_reset_o4" status "fixed_non_ref"} clk_out1_o3 {id "2" is_default false proc_sys_reset "/proc_sys_reset_o4" status "fixed_non_ref"} clk_out1_o4 {id "3" is_default false proc_sys_reset "/proc_sys_reset_o4" status "fixed_non_ref"} clk_out2 {id "4" is_default false proc_sys_reset "/proc_sys_reset_1" status "fixed"}} [get_bd_cells /clk_wizard_0]


#Platform Level Properties
set_property platform.default_output_type "sd_card" [current_project]
set_property platform.design_intent.embedded "true" [current_project]
set_property platform.num_compute_units 15 [current_project]
set_property platform.design_intent.server_managed "false" [current_project]
set_property platform.design_intent.external_host "false" [current_project]
set_property platform.design_intent.datacenter "false" [current_project]
set_property platform.uses_pr  "false" [current_project]
set_property platform.extensible true [current_project]
set_property platform.emu.dr_bd_inst_path ${design_name}_wrapper_sim_wrapper/${design_name}_wrapper_i/${design_name}_i [current_project]

puts "INFO: Platform creation completed!"