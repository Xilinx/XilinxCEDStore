proc createDesign {} {   

variable currentDir
#set_property target_language VHDL [current_project]
#set_property "simulator_language" "Mixed" [current_project]

set arch_info [get_property ARCHITECTURE [get_property PART [current_project]]]
set part_info [get_property PART [current_project]]
##################################################################
# DESIGN PROCs
##################################################################
import_files [glob -type f [file join $currentDir Sources $arch_info *.v]] [glob -type f [file join $currentDir Sources *.vh]] 
import_files -fileset sim_1 [glob -type f [file join $currentDir Sources tb *.v]] 
import_files -fileset constrs_1 [file join $currentDir Sources $arch_info $part_info wave_gen_timing.xdc]
import_files -fileset constrs_1 [file join $currentDir Sources $arch_info $part_info wave_gen_pins.xdc]
set_property target_constrs_file [get_files wave_gen_timing.xdc] [current_fileset -constrset]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name char_fifo
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {8} CONFIG.Output_Data_Width {8} CONFIG.Full_Threshold_Assert_Value {1023} CONFIG.Full_Threshold_Negate_Value {1022} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips char_fifo]
generate_target {instantiation_template} [get_ips char_fifo]

create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_core
set_property -dict [list CONFIG.USE_PHASE_ALIGNMENT {true} CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} CONFIG.PRIM_IN_FREQ {200.000} CONFIG.CLKOUT2_USED {true} CONFIG.PRIMARY_PORT {clk_pin} CONFIG.CLK_OUT1_PORT {clk_rx} CONFIG.CLK_OUT2_PORT {clk_tx} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {166.667} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.MMCM_CLKFBOUT_MULT_F {5.000} CONFIG.MMCM_CLKIN1_PERIOD {5.0} CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000} CONFIG.MMCM_CLKOUT1_DIVIDE {6} CONFIG.NUM_OUT_CLKS {2} CONFIG.CLKOUT1_JITTER {98.146} CONFIG.CLKOUT1_PHASE_ERROR {89.971} CONFIG.CLKOUT2_JITTER {101.680} CONFIG.CLKOUT2_PHASE_ERROR {89.971}] [get_ips clk_core]
generate_target {instantiation_template} [get_ips clk_core]
update_compile_order
}
