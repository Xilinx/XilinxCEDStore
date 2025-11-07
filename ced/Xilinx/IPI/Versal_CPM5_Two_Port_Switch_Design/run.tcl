proc createDesign {design_name options} {


    # Set the reference directory for source file relative paths (by default the value is script directory path)
    variable currentDir

    # Create 'sources_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sources_1] ""]} {
        create_fileset -srcset sources_1
    }

   # Set 'sources_1' fileset object
set obj [get_filesets sources_1]

if {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "Gen5x4_Switch_Combination_1*"] != -1)} {

puts "INFO: Gen5x4_Switch_Combination_1* preset is selected."

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${currentDir}/switch_combination_1/src/completion_fwd_generator.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/cq_to_rq_converter.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/cqt1_to_cfg_mgmt_converter.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/one_signal_cdc.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/rc_to_cc_converter.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/routing_checker.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/routing_checker_usp.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/rqt1_to_rqt0_converter.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/snoop_ext_bus_numbers.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/snoop_mgmt_bus_numbers.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/switch_logic.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/switch_state_machine.sv"] \
 [file normalize "${currentDir}/switch_combination_1/src/two_port_switch_top.sv"] \
]
#add_files -norecurse -fileset $obj $files
import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "two_port_switch_top" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src two_port_switch_top.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "usp_cips" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src two_port_switch_top.sv] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'constrs_1' fileset (if not found)
#if {[string equal [get_filesets -quiet constrs_1] ""]} {
#  create_fileset -constrset constrs_1
#}
#
## Set 'constrs_1' fileset object
#set obj [get_filesets constrs_1]
#
## Add/Import constrs file and set constrs file properties
#set file "[file normalize "$currentDir/switch_combination_1/constraints/two_port_constraints.xdc"]"
#set file_added [add_files -norecurse -fileset $obj [list $file]]
#set file "$currentDir/switch_combination_1/constraints/two_port_constraints.xdc"
#set file [file normalize $file]
#set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
#set_property -name "file_type" -value "XDC" -objects $file_obj
#
## Set 'constrs_1' fileset properties
#set obj [get_filesets constrs_1]
puts $obj

set xdc [file join $currentDir switch_combination_1 constraints two_port_constraints.xdc]
import_files -fileset constrs_1 -norecurse $xdc

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Import local files from the original project

set files [list \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_EP_MEM.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_EP_MEM_ACCESS.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/validation_defines.vh"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_INTR_CTRL.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/board_common.vh"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/pci_exp_usrapp_cfg.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/pci_exp_expect_tasks.vh"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/pci_exp_usrapp_com.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/pci_exp_usrapp_rx.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/two_port_tasks.vh"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/tests.vh"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/sample_tests.vh"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/pci_exp_usrapp_tx.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/sys_clk_gen.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/sys_clk_gen_ds.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/xilinx_pcie_versal_ep.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/xilinx_pcie_versal_rp.v"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/pcie_app_versal_bmd.vh"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_512.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_CC_512.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_CQ_512.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_EP_512.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_RC_512.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_RQ_512.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_RQ_MUX_512.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_RQ_READ_512.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_RQ_WRITE_512.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/BMD_AXIST_TO_CTRL.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/pcie_app_versal_bmd.sv"] \
 [file normalize "${currentDir}/switch_combination_1/sim_files/board.v"] \
]
import_files -norecurse -fileset $obj $files
} elseif {[regexp "Gen5x4_Switch_Combination_2*" $options]} {
puts "INFO: default Gen5x4_Switch_Combination_2 preset is selected."
puts "Warning: DSP Design"
set files [list \
 [file normalize "${currentDir}/switch_combination_2/src/completion_fwd_generator.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/cq_to_rq_converter.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/cqt1_to_cfg_mgmt_converter.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/one_signal_cdc.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/rc_to_cc_converter.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/routing_checker.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/routing_checker_usp.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/rqt1_to_rqt0_converter.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/snoop_ext_bus_numbers.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/snoop_mgmt_bus_numbers.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/switch_logic.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/switch_state_machine.sv"] \
 [file normalize "${currentDir}/switch_combination_2/src/two_port_switch_top.sv"] \
]
#add_files -norecurse -fileset $obj $files
import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "two_port_switch_top" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src two_port_switch_top.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "dsp_cips" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src two_port_switch_top.sv] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'constrs_1' fileset (if not found)
#if {[string equal [get_filesets -quiet constrs_1] ""]} {
#  create_fileset -constrset constrs_1
#}
#
## Set 'constrs_1' fileset object
#set obj [get_filesets constrs_1]
#
## Add/Import constrs file and set constrs file properties
#set file "[file normalize "$currentDir/switch_combination_2/constraints/two_port_constraints.xdc"]"
#set file_added [add_files -norecurse -fileset $obj [list $file]]
#set file "$currentDir/switch_combination_2/constraints/two_port_constraints.xdc"
#set file [file normalize $file]
#set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
#set_property -name "file_type" -value "XDC" -objects $file_obj
#
## Set 'constrs_1' fileset properties
#set obj [get_filesets constrs_1]
puts $obj

set xdc [file join $currentDir switch_combination_2 constraints two_port_constraints.xdc]
import_files -fileset constrs_1 -norecurse $xdc

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Import local files from the original project

set files [list \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_EP_MEM.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_EP_MEM_ACCESS.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/validation_defines.vh"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_INTR_CTRL.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/board_common.vh"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/pci_exp_usrapp_cfg.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/pci_exp_expect_tasks.vh"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/pci_exp_usrapp_com.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/pci_exp_usrapp_rx.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/sample_tests.vh"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/tests.vh"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/two_port_tasks.vh"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/pci_exp_usrapp_tx.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/sys_clk_gen.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/sys_clk_gen_ds.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/xilinx_pcie_versal_ep.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/xilinx_pcie_versal_rp.v"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/pcie_app_versal_bmd.vh"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_512.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_CC_512.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_CQ_512.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_EP_512.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_RC_512.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_RQ_512.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_RQ_MUX_512.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_RQ_READ_512.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_RQ_WRITE_512.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/BMD_AXIST_TO_CTRL.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/pcie_app_versal_bmd.sv"] \
 [file normalize "${currentDir}/switch_combination_2/sim_files/board.v"] \
]

import_files -norecurse -fileset $obj $files

}
##################################################################
# DESIGN PROCs
##################################################################

if {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "Gen5x4_Switch_Combination_1*"] != -1)} {
puts "INFO: Gen5x4_Switch_Combination_1* preset is selected."

source  "$currentDir/switch_combination_1/usp_cips_bd.tcl"
puts "usp_cips_bd generated"

source  "$currentDir/switch_combination_1/clk_width_conv_usp_to_dsp_bd.tcl"
puts "clk_width_conv_usp_to_dsp_bd generated"
 
source  "$currentDir/switch_combination_1/clk_width_conv_dsp_to_usp_bd.tcl"
puts "clk_width_conv_dsp_to_usp_bd generated"  

source  "$currentDir/switch_combination_1/design_ep_bd.tcl"
puts "design_ep_bd generated" 

source  "$currentDir/switch_combination_1/design_sim_rp_bd.tcl"
puts "design_sim_rp_bd generated"
 
source  "$currentDir/switch_combination_1/dsp_plpcie_bd.tcl"
puts "dsp_plpcie_bd generated" 

#set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
#set_property strategy Performance_ExploreWithRemap [get_runs impl_1]

set_property used_in simulation [get_files design_ep.bd]
set_property used_in simulation [get_files design_sim_rp.bd]

open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.2/ced/Xilinx/IPI/Versal_CPM5_Two_Port_Switch_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.2/ced/Xilinx/IPI/Versal_CPM5_Two_Port_Switch_Design/readme.txt",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
    #  -string -flagsOSRD
    preplace cgraphic comment_0 place right -1200 -130 textcolor 4 linecolor 3
    ",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }

generate_target all [get_files $design_name]

validate_bd_design
save_bd_design

puts "INFO: usp cips design generation completed successfully"
} elseif {[regexp "Gen5x4_Switch_Combination_2*" $options]} {
puts "INFO: default Gen5x4_Switch_Combination_2 preset is selected."

source  "$currentDir/switch_combination_2/dsp_cips_bd.tcl"
puts "dsp_cips_bd generated"

source  "$currentDir/switch_combination_2/clk_width_conv_usp_to_dsp_bd.tcl"
puts "clk_width_conv_usp_to_dsp_bd generated"
 
source  "$currentDir/switch_combination_2/clk_width_conv_dsp_to_usp_bd.tcl"
puts "clk_width_conv_dsp_to_usp_bd generated"  

source  "$currentDir/switch_combination_2/design_ep_bd.tcl"
puts "design_ep_bd generated" 

source  "$currentDir/switch_combination_2/design_sim_rp_bd.tcl"
puts "design_sim_rp_bd generated"

source  "$currentDir/switch_combination_2/usp_plpcie_bd.tcl"
puts "usp_plpcie_bd generated" 

set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_Explore [get_runs impl_1]

set_property used_in simulation [get_files design_ep.bd]
set_property used_in simulation [get_files design_sim_rp.bd]

open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.2/ced/Xilinx/IPI/Versal_CPM5_Two_Port_Switch_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.2/ced/Xilinx/IPI/Versal_CPM5_Two_Port_Switch_Design/readme.txt",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
    #  -string -flagsOSRD
    preplace cgraphic comment_0 place right -1200 -130 textcolor 4 linecolor 3
    ",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }

generate_target all [get_files $design_name]

validate_bd_design
save_bd_design

puts "INFO: dsp cips design generation completed successfully"

}


set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

set_property target_simulator Questa [current_project]

set_property -name {questa.elaborate.vopt.more_options} -value {+nospecify +notimingchecks} -objects [get_filesets sim_1]
set_property -name {questa.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
set_property -name {questa.simulate.runtime} -value {-all} -objects [get_filesets sim_1]
set_property -name {questa.simulate.vsim.more_options} -value {+notimingchecks} -objects [get_filesets sim_1]


}


