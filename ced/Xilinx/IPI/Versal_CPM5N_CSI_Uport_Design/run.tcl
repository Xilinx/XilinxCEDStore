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
 [file normalize "${currentDir}/src/uport_if_wrapper.v"] \
 [file normalize "${currentDir}/src/cdx5n_csi_defines.svh"] \
 [file normalize "${currentDir}/src/ks_global_interfaces_def.sv"] \
 [file normalize "${currentDir}/src/cpm5n_interface.svh"] \
 [file normalize "${currentDir}/src/cdx5n_reg_slice.sv"] \
 [file normalize "${currentDir}/src/cdx5n_defines.svh"] \
 [file normalize "${currentDir}/src/cdx5n_defines.vh"] \
 [file normalize "${currentDir}/src/cdx5n_attr_defines.svh"] \
 [file normalize "${currentDir}/src/credit_manager.sv"] \
 [file normalize "${currentDir}/src/csi_uport.sv"] \
 [file normalize "${currentDir}/src/csi_uport_axil_reg.sv"] \
 [file normalize "${currentDir}/src/csi_uport_checker.sv"] \
 [file normalize "${currentDir}/src/csi_uport_decode.sv"] \
 [file normalize "${currentDir}/src/csi_uport_encode.sv"] \
 [file normalize "${currentDir}/src/csi_uport_req_gen.sv"] \
 [file normalize "${currentDir}/src/uport_counters.sv"] \
 [file normalize "${currentDir}/src/design_1_wrapper.sv"] \
 [file normalize "${currentDir}/src/cdx5n_attr_defines.vh"] \
]

import_files -norecurse -fileset $obj $files

set prj [get_projects [current_project]]

create_ip -name axi_vip -vendor xilinx.com -library ip -module_name axi_vip_0
set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} CONFIG.PROTOCOL {AXI4LITE} ] [get_ips axi_vip_0]
set_property synth_checkpoint_mode None [get_files $prj/$prj.srcs/sources_1/ip/axi_vip_0/axi_vip_0.xci]

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "${design_name}_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.sv] w]
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
 [file normalize "${currentDir}/sim_files/xilinx_pcie5_versal_rp.sv"] \
 [file normalize "${currentDir}/sim_files/design_rp_wrapper.v"] \
 [file normalize "${currentDir}/sim_files/axi_vip_master_agent.sv"] \
 [file normalize "${currentDir}/sim_files/board.v"] \
 [file normalize "${currentDir}/sim_files/tests.vh"] \
]

import_files -norecurse -fileset $obj $files

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files board.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files board.v] w]
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

source "$currentDir/design_uport_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files uport_if.bd]
generate_target all [get_files uport_if.bd]
puts "INFO: uport bd generated"

regenerate_bd_layout

open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to readme.txt",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
    #  -string -flagsOSRD
    preplace cgraphic comment_0 place right -1200 -130 textcolor 4 linecolor 3
    ",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }
 
validate_bd_design
save_bd_design
 
puts "INFO: design generation completed successfully"

set_property used_in simulation  [get_files  design_rp.bd]

set_property used_in simulation [get_files  $prj/$prj.srcs/sim_1/imports/sim_files/design_rp_wrapper.v]
set_property used_in simulation [get_files  $prj/$prj.srcs/sim_1/imports/sim_files/axi_vip_master_agent.sv]
set_property used_in simulation [get_files  $prj/$prj.srcs/sources_1/ip/axi_vip_0/axi_vip_0.xci]

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]

#set_property target_simulator Questa [current_project]
set_property target_simulator VCS [current_project]
set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

set_property -name "vcs.elaborate.vcs.more_options" -value "+nospecify +notimingchecks" -objects $obj
set_property -name {vcs.simulate.runtime} -value {400000ns} -objects [get_filesets sim_1]
set_property -name {vcs.simulate.vcs.more_options} -value {-gui} -objects [get_filesets sim_1]

}

