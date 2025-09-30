#############################################################
# vrk160/vrk165 Extensible CED updates for 2025.2 release
#############################################################
puts "INFO: Block design generation completed, yet to set PFM properties"

# Create PFM attributes
set_property platform.extensible true [current_project]

puts "INFO: Creating extensible_platform for $board_name"
set pfmName "xilinx.com:${board_name}:${board_name}_base:1.0"
set_property PFM_NAME $pfmName [get_files [current_bd_design].bd]
	
set_property PFM.IRQ {intr {id 0 range 15}}  [get_bd_cells /axi_intc_0]
set_property PFM.AXI_PORT {M01_AXI {} M02_AXI {} M03_AXI {} M04_AXI {} M05_AXI {} M06_AXI {} M07_AXI {} M08_AXI {} M09_AXI {} M10_AXI {} M11_AXI {} M12_AXI {} M13_AXI {} M14_AXI {} M15_AXI {}} [get_bd_cells /ctrl_smc]

if { $use_aie } {
	set_property PFM.AXI_PORT {S00_AXI {sptag AIE auto false} S01_AXI {sptag AIE auto false} S02_AXI {sptag AIE auto false} S03_AXI {sptag AIE auto false} S04_AXI {sptag AIE auto false} S05_AXI {sptag AIE auto false} S06_AXI {sptag AIE auto false} S07_AXI {sptag AIE auto false} S08_AXI {sptag AIE auto false} S09_AXI {sptag AIE auto false} S10_AXI {sptag AIE auto false} S11_AXI {sptag AIE auto false} S12_AXI {sptag AIE auto false} S13_AXI {sptag AIE auto false} S14_AXI {sptag AIE auto false} S15_AXI {sptag AIE auto false} S16_AXI {sptag AIE auto false} S17_AXI {sptag AIE auto false} S18_AXI {sptag AIE auto false} S19_AXI {sptag AIE auto false} S20_AXI {sptag AIE auto false}} [get_bd_cells /ConfigNoc] 
}

if {[regexp "vek280" $board_name]} {

set_property PFM.AXI_PORT {S00_AXI {sptag LPDDR0 auto false} S01_AXI {sptag LPDDR0 auto false} S02_AXI {sptag LPDDR0 auto false} S03_AXI {sptag LPDDR0 auto false} S04_AXI {sptag LPDDR0 auto false} S05_AXI {sptag LPDDR0 auto false} S06_AXI {sptag LPDDR0 auto false} S07_AXI {sptag LPDDR0 auto false} S08_AXI {sptag LPDDR0 auto false} S09_AXI {sptag LPDDR0 auto false} S10_AXI {sptag LPDDR0 auto false} S11_AXI {sptag LPDDR0 auto false} S12_AXI {sptag LPDDR0 auto false} S13_AXI {sptag LPDDR0 auto false} S14_AXI {sptag LPDDR0 auto false} S15_AXI {sptag LPDDR0 auto false} S16_AXI {sptag LPDDR0 auto false} S17_AXI {sptag LPDDR0 auto false} S18_AXI {sptag LPDDR0 auto false} S19_AXI {sptag LPDDR0 auto false} S20_AXI {sptag LPDDR0 auto false} S21_AXI {sptag LPDDR0 auto false} S22_AXI {sptag LPDDR0 auto false} S23_AXI {sptag LPDDR0 auto false} S24_AXI {sptag LPDDR0 auto false} S25_AXI {sptag LPDDR0 auto false} S26_AXI {sptag LPDDR0 auto false} S27_AXI {sptag LPDDR0 auto false}} [get_bd_cells /$default_mem]

} else {

set_property PFM.AXI_PORT {S00_AXI {sptag DDR0 auto false} S01_AXI {sptag DDR0 auto false} S02_AXI {sptag DDR0 auto false} S03_AXI {sptag DDR0 auto false} S04_AXI {sptag DDR0 auto false} S05_AXI {sptag DDR0 auto false} S06_AXI {sptag DDR0 auto false} S07_AXI {sptag DDR0 auto false} S08_AXI {sptag DDR0 auto false} S09_AXI {sptag DDR0 auto false} S10_AXI {sptag DDR0 auto false} S11_AXI {sptag DDR0 auto false} S12_AXI {sptag DDR0 auto false} S13_AXI {sptag DDR0 auto false} S14_AXI {sptag DDR0 auto false} S15_AXI {sptag DDR0 auto false} S16_AXI {sptag DDR0 auto false} S17_AXI {sptag DDR0 auto false} S18_AXI {sptag DDR0 auto false} S19_AXI {sptag DDR0 auto false} S20_AXI {sptag DDR0 auto false} S21_AXI {sptag DDR0 auto false} S22_AXI {sptag DDR0 auto false} S23_AXI {sptag DDR0 auto false} S24_AXI {sptag DDR0 auto false} S25_AXI {sptag DDR0 auto false} S26_AXI {sptag DDR0 auto false} S27_AXI {sptag DDR0 auto false}} [get_bd_cells /$default_mem] }

set_property PFM.AXI_PORT {S00_AXI {sptag LPDDR1} S01_AXI {sptag LPDDR1} S02_AXI {sptag LPDDR1} S03_AXI {sptag LPDDR1} S04_AXI {sptag LPDDR1} S05_AXI {sptag LPDDR1} S06_AXI {sptag LPDDR1} S07_AXI {sptag LPDDR1} S08_AXI {sptag LPDDR1} S09_AXI {sptag LPDDR1} S10_AXI {sptag LPDDR1} S11_AXI {sptag LPDDR1} S12_AXI {sptag LPDDR1} S13_AXI {sptag LPDDR1} S14_AXI {sptag LPDDR1} S15_AXI {sptag LPDDR1} S16_AXI {sptag LPDDR1} S17_AXI {sptag LPDDR1} S18_AXI {sptag LPDDR1} S19_AXI {sptag LPDDR1} S20_AXI {sptag LPDDR1}} [get_bd_cells /$additional_mem1]
  
set_property PFM.AXI_PORT {S00_AXI {sptag LPDDR2} S01_AXI {sptag LPDDR2} S02_AXI {sptag LPDDR2} S03_AXI {sptag LPDDR2} S04_AXI {sptag LPDDR2} S05_AXI {sptag LPDDR2} S06_AXI {sptag LPDDR2} S07_AXI {sptag LPDDR2} S08_AXI {sptag LPDDR2} S09_AXI {sptag LPDDR2} S10_AXI {sptag LPDDR2} S11_AXI {sptag LPDDR2} S12_AXI {sptag LPDDR2} S13_AXI {sptag LPDDR2} S14_AXI {sptag LPDDR2} S15_AXI {sptag LPDDR2} S16_AXI {sptag LPDDR2} S17_AXI {sptag LPDDR2} S18_AXI {sptag LPDDR2} S19_AXI {sptag LPDDR2} S20_AXI {sptag LPDDR2}} [get_bd_cells /$additional_mem2]
	
set_property PFM.AXI_PORT {S00_AXI {sptag LPDDR} S01_AXI {sptag LPDDR} S02_AXI {sptag LPDDR} S03_AXI {sptag LPDDR} S04_AXI {sptag LPDDR} S05_AXI {sptag LPDDR} S06_AXI {sptag LPDDR} S07_AXI {sptag LPDDR} S08_AXI {sptag LPDDR} S09_AXI {sptag LPDDR} S10_AXI {sptag LPDDR} S11_AXI {sptag LPDDR} S12_AXI {sptag LPDDR} S13_AXI {sptag LPDDR} S14_AXI {sptag LPDDR} S15_AXI {sptag LPDDR} S16_AXI {sptag LPDDR} S17_AXI {sptag LPDDR} S18_AXI {sptag LPDDR} S19_AXI {sptag LPDDR} S20_AXI {sptag LPDDR}} [get_bd_cells /aggr_noc]

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