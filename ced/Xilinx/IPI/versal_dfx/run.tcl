proc createDesign {design_name options} {

# Set the reference directory for source file relative paths (by default the value is script directory path)
variable currentDir

##################################################################
# DESIGN PROCs
##################################################################
set_param bd.addr.smcx_func.route_dfx_apertures true
set_property PREFERRED_SIM_MODEL "tlm" [current_project]

#puts "INFO: design_name:: $design_name and options:: $options is selected from GUI"
puts "create_root_design"
set board_part [get_property NAME [current_board_part]]
set board_name [get_property BOARD_NAME [current_board]]
set fpga_part [get_property PART_NAME [current_board_part]]
puts "INFO: $board_name board is selected"
puts "INFO: $board_part board_part is selected"
puts "INFO: $fpga_part fpga_part is selected"

set clk_options_param "Clock_Options.VALUE"
set clk_options { clk_out1 156.25 0 true clk_out2 104.167 1 false clk_out3 312.5 2 false }
if { [dict exists $options $clk_options_param] } {
    set clk_options [ dict get $options $clk_options_param ]
}
#puts "INFO: selected clk_options:: $clk_options"

set lpddr "Include_LPDDR.VALUE"
set use_lpddr 0
if { [dict exists $options $lpddr] } {
    set use_lpddr [dict get $options $lpddr ]
}
#puts "INFO: selected use_lpddr:: $use_lpddr"

set aie "Include_AIE.VALUE"
set use_aie 0
if { [dict exists $options $aie] } {
    set use_aie [dict get $options $aie ] }
#puts "INFO: selected use_aie:: $use_aie"

# 0 (no interrupts) / 32 (interrupt controller) / 63 (interrupt controller + cascade block)
set irqs_param "IRQS.VALUE"
set irqs 32
if { [dict exists $options $irqs_param] } {
    set irqs [dict get $options $irqs_param ]
}
#puts "INFO: selected irqs:: $irqs"

set use_intc [set use_cascaded_irqs  ""]
set use_intc [ expr $irqs eq "32" ]
set use_cascaded_irqs [ expr $irqs eq "63" ]

puts "INFO: selected Interrupts:: $irqs"
puts "INFO: selected design_name:: $design_name"
puts "INFO: selected Include_LPDDR:: $use_lpddr"
puts "INFO: selected Clock_Options:: $clk_options"
puts "INFO: selected Include_AIE:: $use_aie"

#creates Vitis block design
source -notrace "$currentDir/vitis_bd.tcl"

source -notrace "$currentDir/main_bd.tcl"

puts "INFO: Adding PFM attributes!! "
source -notrace "$currentDir/pfm_decls.tcl"
save_bd_design

open_bd_design [get_files $design_name.bd]
upgrade_bd_cells [get_bd_cells VitisRegion]
make_wrapper -files [get_files $design_name.bd] -top -import
set_property top ${design_name}_wrapper [current_fileset]
open_bd_design [get_bd_files $design_name]

set_property USER_COMMENTS.comment0 {An Example Versal DFX Extensible Embedded Platform
	Note:
	--> Board preset applied to CIPS and memory controller settings
	--> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
			Hence VIPs are there to have at least one slave on a smart connect.
	--> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.2/ced/Xilinx/IPI/versal_dfx/README.md}  [current_bd_design] 
regenerate_bd_layout -layout_string {
		   "ActiveEmotionalView":"Default View",
		   "comment_0":"An Example Versal DFX Extensible Embedded Platform
			Note:
			--> Board preset applied to CIPS and memory controller.
			--> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
					Hence VIPs are there to have at least one slave on a smart connect.
			--> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.2/ced/Xilinx/IPI/versal_dfx/README.md ",
		   "commentid":"comment_0|",
		   "font_comment_0":"14",
		   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
			#  -string -flagsOSRD
			preplace cgraphic comment_0 place top -154 -166 textcolor 4 linecolor 3
			",
		   "linktoobj_comment_0":"",
		   "linktotype_comment_0":"bd_design" }
regenerate_bd_layout
validate_bd_design
save_bd_design
puts "INFO: End of create_root_design"

# set_property PR_FLOW 1 [current_project]
# set_property synth_checkpoint_mode None [get_files $design_name.bd]
# generate_target all [get_files $design_name.bd]
# update_compile_order -fileset sources_1

# set_property platform.platform_state "impl" [current_project]
# #create_pr_configuration -name config_1 -partitions [list versal_dfx_platform_i/VitisRegion:VitisRegion_inst_0 ]
# create_pr_configuration -name config_1 -partitions [list ${design_name}_i/VitisRegion:VitisRegion_inst_0 ]
# set_property PR_CONFIGURATION config_1 [get_runs impl_1]
}
