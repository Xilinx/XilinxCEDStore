#############################################################
# VEK385 Extensible PFM Properties
#############################################################

# Create PFM attributes
set board_name [get_property BOARD_NAME [current_board]]
puts "INFO: Creating extensible_platform for $board_name"
set pfmName "xilinx.com:${board_name}:${board_name}_base:1.0"
set_property PFM_NAME $pfmName [get_files [current_bd_design].bd]

# Provision /NoC_C0_C1 for up to AIE_NMU + PL_NMU
# set auto false to force user to opt in to share accelerator w/PS
set_property PFM.AXI_PORT { S00_AXI {sptag LPDDR01 auto false} S01_AXI {sptag LPDDR01 auto false} S02_AXI {sptag LPDDR01 auto false} S03_AXI {sptag LPDDR01 auto false} S04_AXI {sptag LPDDR01 auto false} S05_AXI {sptag LPDDR01 auto false} S06_AXI {sptag LPDDR01 auto false} S07_AXI {sptag LPDDR01 auto false} S08_AXI {sptag LPDDR01 auto false} S09_AXI {sptag LPDDR01 auto false} S10_AXI {sptag LPDDR01 auto false} S11_AXI {sptag LPDDR01 auto false} S12_AXI {sptag LPDDR01 auto false} S13_AXI {sptag LPDDR01 auto false} S14_AXI {sptag LPDDR01 auto false} S15_AXI {sptag LPDDR01 auto false} S16_AXI {sptag LPDDR01 auto false} S17_AXI {sptag LPDDR01 auto false} S18_AXI {sptag LPDDR01 auto false} S19_AXI {sptag LPDDR01 auto false} } [get_bd_cells /NoC_C0_C1]

# Provision /NoC_C2_C3 for up to AIE_NMU + PL_NMU
set_property PFM.AXI_PORT { S00_AXI {sptag LPDDR23} S01_AXI {sptag LPDDR23} S02_AXI {sptag LPDDR23} S03_AXI {sptag LPDDR23} S04_AXI {sptag LPDDR23} S05_AXI {sptag LPDDR23} S06_AXI {sptag LPDDR23} S07_AXI {sptag LPDDR23} S08_AXI {sptag LPDDR23} S09_AXI {sptag LPDDR23} S10_AXI {sptag LPDDR23} S11_AXI {sptag LPDDR23} S12_AXI {sptag LPDDR23} S13_AXI {sptag LPDDR23} S14_AXI {sptag LPDDR23} S15_AXI {sptag LPDDR23} S16_AXI {sptag LPDDR23} S17_AXI {sptag LPDDR23} S18_AXI {sptag LPDDR23} S19_AXI {sptag LPDDR23} S20_AXI {sptag LPDDR23} S21_AXI {sptag LPDDR23} S22_AXI {sptag LPDDR23} S23_AXI {sptag LPDDR23} S24_AXI {sptag LPDDR23} S25_AXI {sptag LPDDR23} S26_AXI {sptag LPDDR23} S27_AXI {sptag LPDDR23} S28_AXI {sptag LPDDR23} S29_AXI {sptag LPDDR23} S30_AXI {sptag LPDDR23} S31_AXI {sptag LPDDR23} S32_AXI {sptag LPDDR23} S33_AXI {sptag LPDDR23} S34_AXI {sptag LPDDR23} S35_AXI {sptag LPDDR23} S36_AXI {sptag LPDDR23} S37_AXI {sptag LPDDR23} S38_AXI {sptag LPDDR23} S39_AXI {sptag LPDDR23} S40_AXI {sptag LPDDR23} S41_AXI {sptag LPDDR23} S42_AXI {sptag LPDDR23} S43_AXI {sptag LPDDR23} S44_AXI {sptag LPDDR23} S45_AXI {sptag LPDDR23} S46_AXI {sptag LPDDR23} S47_AXI {sptag LPDDR23} S48_AXI {sptag LPDDR23} S49_AXI {sptag LPDDR23} S50_AXI {sptag LPDDR23} S51_AXI {sptag LPDDR23} S52_AXI {sptag LPDDR23} S53_AXI {sptag LPDDR23} S54_AXI {sptag LPDDR23} S55_AXI {sptag LPDDR23} } [get_bd_cells /NoC_C2_C3]

# Provision /NoC_C4 for up to AIE_NMU + PL_NMU
set_property PFM.AXI_PORT { S00_AXI {sptag LPDDR4} S01_AXI {sptag LPDDR4} S02_AXI {sptag LPDDR4} S03_AXI {sptag LPDDR4} S04_AXI {sptag LPDDR4} S05_AXI {sptag LPDDR4} S06_AXI {sptag LPDDR4} S07_AXI {sptag LPDDR4} S08_AXI {sptag LPDDR4} S09_AXI {sptag LPDDR4} S10_AXI {sptag LPDDR4} S11_AXI {sptag LPDDR4} S12_AXI {sptag LPDDR4} S13_AXI {sptag LPDDR4} S14_AXI {sptag LPDDR4} S15_AXI {sptag LPDDR4} S16_AXI {sptag LPDDR4} S17_AXI {sptag LPDDR4} S18_AXI {sptag LPDDR4} S19_AXI {sptag LPDDR4} S20_AXI {sptag LPDDR4} S21_AXI {sptag LPDDR4} S22_AXI {sptag LPDDR4} S23_AXI {sptag LPDDR4} S24_AXI {sptag LPDDR4} S25_AXI {sptag LPDDR4} S26_AXI {sptag LPDDR4} S27_AXI {sptag LPDDR4} S28_AXI {sptag LPDDR4} S29_AXI {sptag LPDDR4} S30_AXI {sptag LPDDR4} S31_AXI {sptag LPDDR4} S32_AXI {sptag LPDDR4} S33_AXI {sptag LPDDR4} S34_AXI {sptag LPDDR4} S35_AXI {sptag LPDDR4} S36_AXI {sptag LPDDR4} S37_AXI {sptag LPDDR4} S38_AXI {sptag LPDDR4} S39_AXI {sptag LPDDR4} S40_AXI {sptag LPDDR4} S41_AXI {sptag LPDDR4} S42_AXI {sptag LPDDR4} S43_AXI {sptag LPDDR4} S44_AXI {sptag LPDDR4} S45_AXI {sptag LPDDR4} S46_AXI {sptag LPDDR4} S47_AXI {sptag LPDDR4} S48_AXI {sptag LPDDR4} S49_AXI {sptag LPDDR4} S50_AXI {sptag LPDDR4} S51_AXI {sptag LPDDR4} S52_AXI {sptag LPDDR4} S53_AXI {sptag LPDDR4} S54_AXI {sptag LPDDR4} S55_AXI {sptag LPDDR4} } [get_bd_cells /NoC_C4]

# Provision aggr_noc for up to AIE_NMU + PL_NMU
set_property PFM.AXI_PORT { S00_AXI {sptag LPDDR auto preferred} S01_AXI {sptag LPDDR auto preferred} S02_AXI {sptag LPDDR auto preferred} S03_AXI {sptag LPDDR auto preferred} S04_AXI {sptag LPDDR auto preferred} S05_AXI {sptag LPDDR auto preferred} S06_AXI {sptag LPDDR auto preferred} S07_AXI {sptag LPDDR auto preferred} S08_AXI {sptag LPDDR auto preferred} S09_AXI {sptag LPDDR auto preferred} S10_AXI {sptag LPDDR auto preferred} S11_AXI {sptag LPDDR auto preferred} S12_AXI {sptag LPDDR auto preferred} S13_AXI {sptag LPDDR auto preferred} S14_AXI {sptag LPDDR auto preferred} S15_AXI {sptag LPDDR auto preferred} S16_AXI {sptag LPDDR auto preferred} S17_AXI {sptag LPDDR auto preferred} S18_AXI {sptag LPDDR auto preferred} S19_AXI {sptag LPDDR auto preferred} S20_AXI {sptag LPDDR auto preferred} S21_AXI {sptag LPDDR auto preferred} S22_AXI {sptag LPDDR auto preferred} S23_AXI {sptag LPDDR auto preferred} S24_AXI {sptag LPDDR auto preferred} S25_AXI {sptag LPDDR auto preferred} S26_AXI {sptag LPDDR auto preferred} S27_AXI {sptag LPDDR auto preferred} S28_AXI {sptag LPDDR auto preferred} S29_AXI {sptag LPDDR auto preferred} S30_AXI {sptag LPDDR auto preferred} S31_AXI {sptag LPDDR auto preferred} S32_AXI {sptag LPDDR auto preferred} S33_AXI {sptag LPDDR auto preferred} S34_AXI {sptag LPDDR auto preferred} S35_AXI {sptag LPDDR auto preferred} S36_AXI {sptag LPDDR auto preferred} S37_AXI {sptag LPDDR auto preferred} S38_AXI {sptag LPDDR auto preferred} S39_AXI {sptag LPDDR auto preferred} S40_AXI {sptag LPDDR auto preferred} S41_AXI {sptag LPDDR auto preferred} S42_AXI {sptag LPDDR auto preferred} S43_AXI {sptag LPDDR auto preferred} S44_AXI {sptag LPDDR auto preferred} S45_AXI {sptag LPDDR auto preferred} S46_AXI {sptag LPDDR auto preferred} S47_AXI {sptag LPDDR auto preferred} S48_AXI {sptag LPDDR auto preferred} S49_AXI {sptag LPDDR auto preferred} S50_AXI {sptag LPDDR auto preferred} S51_AXI {sptag LPDDR auto preferred} S52_AXI {sptag LPDDR auto preferred} S53_AXI {sptag LPDDR auto preferred} S54_AXI {sptag LPDDR auto preferred} S55_AXI {sptag LPDDR auto preferred} } [get_bd_cells /aggr_noc]

# Provision control bus Smartconnect
# only need to declare for /ctrl_smc as v++ link will automatically cascade additional as needed
set_property PFM.AXI_PORT { M01_AXI {} M02_AXI {} M03_AXI {} M04_AXI {} M05_AXI {} M06_AXI {} M07_AXI {} M08_AXI {} M09_AXI {} M10_AXI {} M11_AXI {} M12_AXI {} M13_AXI {} M14_AXI {} M15_AXI {} } [get_bd_cells /ctrl_smc]

if { $use_aie } {
# Provision /ConfigNoc for up to AIE_NSU
# set auto false to force user to opt in to access AIE memory-map
set_property PFM.AXI_PORT { S00_AXI {sptag AIE auto false} S01_AXI {sptag AIE auto false} S02_AXI {sptag AIE auto false} S03_AXI {sptag AIE auto false} S04_AXI {sptag AIE auto false} S05_AXI {sptag AIE auto false} S06_AXI {sptag AIE auto false} S07_AXI {sptag AIE auto false} S08_AXI {sptag AIE auto false} S09_AXI {sptag AIE auto false} S10_AXI {sptag AIE auto false} S11_AXI {sptag AIE auto false} S12_AXI {sptag AIE auto false} S13_AXI {sptag AIE auto false} S14_AXI {sptag AIE auto false} S15_AXI {sptag AIE auto false} S16_AXI {sptag AIE auto false} S17_AXI {sptag AIE auto false} S18_AXI {sptag AIE auto false} S19_AXI {sptag AIE auto false} S20_AXI {sptag AIE auto false} S21_AXI {sptag AIE auto false} } [get_bd_cells /ConfigNoc]
}

# /axi_intc supports up to 32 PL interrupts 
set_property PFM.IRQ {intr {id 0 range 31}} [get_bd_cells /axi_intc_0]

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
