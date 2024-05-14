proc createDesign {design_name options} {  

variable currentDir
puts $currentDir

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${currentDir}/src/cdm_adapt_ctrl_regs.v"] \
 [file normalize "${currentDir}/src/cdm_usr_ram_wrapper.v"] \
 [file normalize "${currentDir}/src/design_1_wrapper.v"] \
 [file normalize "${currentDir}/src/msgld_fifos_wrapper.v"] \
 [file normalize "${currentDir}/src/uport_if_wrapper.v"] \
 [file normalize "${currentDir}/src/CDM_accumulator.sv"] \
 [file normalize "${currentDir}/src/CDM_order_enforcer.sv"] \
 [file normalize "${currentDir}/src/CDM_throttle.sv"] \
 [file normalize "${currentDir}/src/cdm_msgld_msgst.sv"] \
 [file normalize "${currentDir}/src/cdx5n_reg_slice.sv"] \
 [file normalize "${currentDir}/src/ks_global_interfaces_def.sv"] \
 [file normalize "${currentDir}/src/cdx5n_attr_defines.svh"] \
 [file normalize "${currentDir}/src/cdx5n_defines.svh"] \
 [file normalize "${currentDir}/src/cdx5n_defines.vh"] \
 [file normalize "${currentDir}/src/cdx5n_csi_defines.svh"] \
 [file normalize "${currentDir}/src/credit_manager.sv"] \
 [file normalize "${currentDir}/src/csi_uport.sv"] \
 [file normalize "${currentDir}/src/csi_uport_axil_reg.sv"] \
 [file normalize "${currentDir}/src/csi_uport_checker.sv"] \
 [file normalize "${currentDir}/src/csi_uport_decode.sv"] \
 [file normalize "${currentDir}/src/csi_uport_encode.sv"] \
 [file normalize "${currentDir}/src/csi_uport_req_gen.sv"] \
 [file normalize "${currentDir}/src/msgld_engine.sv"] \
 [file normalize "${currentDir}/src/msgst_engine.sv"] \
 [file normalize "${currentDir}/src/msgst_ld_tg.sv"] \
 [file normalize "${currentDir}/src/msgstld_perf.sv"] \
 [file normalize "${currentDir}/src/slave_bridge_tg.sv"] \
 [file normalize "${currentDir}/src/uport_counters.sv"] \
 [file normalize "${currentDir}/src/cdm_msgst_msgld_top.sv"] \
 [file normalize "${currentDir}/src/ks_global_interfaces_def.svh"] \
 [file normalize "${currentDir}/src/cdx5n_fab_2s_seg_if.svh"] \
 [file normalize "${currentDir}/src/cdx5n_fab_1s_seg_if.svh"] \
 [file normalize "${currentDir}/src/cdx5n_csi_snk_sched_ser_ing_if.svh"] \
 [file normalize "${currentDir}/src/cdx5n_csi_local_crdt_if.svh"] \
 [file normalize "${currentDir}/src/cdx5n_attr_defines.vh"] \
]


import_files -norecurse -fileset $obj $files

create_ip -name axis_vio -vendor xilinx.com -library ip -module_name msgld_st_vio
set_property -dict [list \
  CONFIG.C_NUM_PROBE_IN {3} \
  CONFIG.C_NUM_PROBE_OUT {19} \
  CONFIG.C_PROBE_OUT11_INIT_VAL {0x04} \
  CONFIG.C_PROBE_OUT11_WIDTH {5} \
  CONFIG.C_PROBE_OUT12_INIT_VAL {0x080} \
  CONFIG.C_PROBE_OUT12_WIDTH {9} \
  CONFIG.C_PROBE_OUT13_WIDTH {12} \
  CONFIG.C_PROBE_OUT14_WIDTH {12} \
  CONFIG.C_PROBE_OUT16_WIDTH {3} \
  CONFIG.C_PROBE_OUT17_WIDTH {3} \
  CONFIG.C_PROBE_OUT1_WIDTH {15} \
  CONFIG.C_PROBE_OUT2_WIDTH {32} \
  CONFIG.C_PROBE_OUT4_WIDTH {15} \
  CONFIG.C_PROBE_OUT5_WIDTH {32} \
] [get_ips msgld_st_vio]

generate_target all [get_files msgld_st_vio.xci]

create_ip -name c_counter_binary -vendor xilinx.com -library ip -module_name c_counter_binary_0
set_property -dict [list \
  CONFIG.CE {true} \
  CONFIG.Final_Count_Value {FFFFFFFFFFFFFFFE} \
  CONFIG.Output_Width {64} \
  CONFIG.Restrict_Count {true} \
  CONFIG.SCLR {true} \
] [get_ips c_counter_binary_0]

generate_target all [get_files c_counter_binary_0.xci]

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "cdm_msgld_msgst_top" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]

set files [list \
 [file normalize "${currentDir}/sim_files/board_common.vh"] \
 [file normalize "${currentDir}/sim_files/pci_exp_usrapp_cfg.v"] \
 [file normalize "${currentDir}/sim_files/pci_exp_expect_tasks.vh"] \
 [file normalize "${currentDir}/sim_files/pci_exp_usrapp_com.v"] \
 [file normalize "${currentDir}/sim_files/pci_exp_usrapp_rx.v"] \
 [file normalize "${currentDir}/sim_files/sample_tests_1024.vh"] \
 [file normalize "${currentDir}/sim_files/pci_exp_usrapp_tx.v"] \
 [file normalize "${currentDir}/sim_files/sys_clk_gen.v"] \
 [file normalize "${currentDir}/sim_files/sys_clk_gen_ds.v"] \
 [file normalize "${currentDir}/sim_files/design_rp_wrapper.sv"] \
 [file normalize "${currentDir}/sim_files/board.v"] \
 [file normalize "${currentDir}/sim_files/axi_vip_master_agent.sv"] \
]


import_files -norecurse -fileset $obj $files

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/constraints/LPDDR5_CH0_CH1_VNX.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
#set file_imported [import_files -fileset constrs_1 [list $file]]
set file "$currentDir/constraints/LPDDR5_CH0_CH1_VNX.xdc"
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

set core_rev [get_property CORE_REVISION [get_ipdefs -all   *cpm5n*]]

# None
set infile [open [get_files cdm_msgst_msgld_top.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "cpm5n_v1_0_7_pkg" "cpm5n_v1_0_${core_rev}_pkg"] $contents]

set outfile  [open [get_files cdm_msgst_msgld_top.sv] w]
puts -nonewline $outfile $contents
close $outfile

##################################################################
# DESIGN PROCs
##################################################################

source "$currentDir/design_1_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"

regenerate_bd_layout

source "$currentDir/design_rp_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files design_rp.bd]
generate_target all [get_files design_rp.bd]
puts "INFO: RP bd generated"

regenerate_bd_layout

source "$currentDir/msgld_fifos_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files msgld_fifos.bd]
generate_target all [get_files msgld_fifos.bd]
puts "INFO: msgldst bd generated"

regenerate_bd_layout

source "$currentDir/uport_ram_if_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files uport_if.bd]
generate_target all [get_files uport_if.bd]
puts "INFO: cdm usr ram bd generated"

source "$currentDir/cdm_usr_ram_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files cdm_usr_ram.bd]
generate_target all [get_files cdm_usr_ram.bd]
puts "INFO: cdm usr ram bd generated"
regenerate_bd_layout

open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2024.1/ced/Xilinx/IPI/Versal_CPM5N_CDM_Msg_Ld_St_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2024.1/ced/Xilinx/IPI/Versal_CPM5N_CDM_Msg_Ld_St_Design/readme.txt",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
    #  -string -flagsOSRD
    preplace cgraphic comment_0 place right -1200 -130 textcolor 4 linecolor 3
    ",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }

generate_target all [get_files $design_name.bd]
 
validate_bd_design
save_bd_design
 
puts "INFO: design generation completed successfully"

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]

#set_property target_simulator Questa [current_project]
set_property target_simulator VCS [current_project]
set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

set_property -name "vcs.elaborate.vcs.more_options" -value "+nospecify +notimingchecks" -objects $obj
set_property -name {vcs.simulate.runtime} -value {500000ns} -objects [get_filesets sim_1]
set_property -name {vcs.simulate.vcs.more_options} -value {+TESTNAME=msgld_msgst_test} -objects [get_filesets sim_1]
set_property -name {vcs.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

}

