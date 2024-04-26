proc createDesign {design_name options} {

variable currentDir
puts "Creating example design in $currentDir"

if {([lsearch $options CPM5N_Preset.VALUE] == -1) || ([lsearch $options "CPM5N_CSI_Uport_Bottom_Design"] != -1)} {
puts "INFO: default CPM5N_CSI_Uport_Bottom_Design preset is selected."

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${currentDir}/csi_bottom/src/uport_if_wrapper.v"] \
 [file normalize "${currentDir}/csi_bottom/src/cdx5n_csi_defines.svh"] \
 [file normalize "${currentDir}/csi_bottom/src/ks_global_interfaces_def.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/cdx5n_reg_slice.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/cdx5n_defines.svh"] \
 [file normalize "${currentDir}/csi_bottom/src/cdx5n_defines.vh"] \
 [file normalize "${currentDir}/csi_bottom/src/cdx5n_attr_defines.svh"] \
 [file normalize "${currentDir}/csi_bottom/src/credit_manager.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/csi_uport.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/csi_uport_axil_reg.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/csi_uport_checker.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/csi_uport_decode.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/csi_uport_encode.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/csi_uport_req_gen.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/uport_counters.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/design_1_wrapper.sv"] \
 [file normalize "${currentDir}/csi_bottom/src/cdx5n_attr_defines.vh"] \
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj

# None
set infile [open [get_files design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [get_files design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]

set files [list \
 [file normalize "${currentDir}/csi_bottom/sim_files/board_common.vh"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/pci_exp_usrapp_cfg.v"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/pci_exp_expect_tasks.vh"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/pci_exp_usrapp_com.v"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/pci_exp_usrapp_rx.v"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/sample_tests_1024.vh"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/pci_exp_usrapp_tx.v"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/sys_clk_gen.v"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/sys_clk_gen_ds.v"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/xilinx_pcie5_versal_rp.sv"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/design_rp_wrapper.v"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/axi_vip_master_agent.sv"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/board.v"] \
 [file normalize "${currentDir}/csi_bottom/sim_files/tests.vh"] \
]

import_files -norecurse -fileset $obj $files

set core_rev [get_property CORE_REVISION [get_ipdefs -all   *cpm5n*]]

# None
set infile [open [get_files design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "cpm5n_v1_0_5_pkg" "cpm5n_v1_0_${core_rev}_pkg"] $contents]

set outfile  [open [get_files design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile
} elseif {[regexp "CPM5N_CSI_Uport_Top_Design" $options]} {

puts "INFO: CPM5N_CSI_Uport_Top_Design preset is selected."

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${currentDir}/csi_top/src/uport_if_wrapper.v"] \
 [file normalize "${currentDir}/csi_top/src/cpm5n_interface.svh"] \
 [file normalize "${currentDir}/csi_top/src/axis_throttle.sv"] \
 [file normalize "${currentDir}/csi_top/src/cdx5n_reg_slice.sv"] \
 [file normalize "${currentDir}/csi_top/src/ks_global_interfaces_def.sv"] \
 [file normalize "${currentDir}/csi_top/src/cdx5n_defines.vh"] \
 [file normalize "${currentDir}/csi_top/src/cdx5n_defines.svh"] \
 [file normalize "${currentDir}/csi_top/src/cdx5n_attr_defines.svh"] \
 [file normalize "${currentDir}/csi_top/src/cdx5n_csi_defines.svh"] \
 [file normalize "${currentDir}/csi_top/src/credit_manager.sv"] \
 [file normalize "${currentDir}/csi_top/src/csi_uport.sv"] \
 [file normalize "${currentDir}/csi_top/src/csi_uport_axil_reg.sv"] \
 [file normalize "${currentDir}/csi_top/src/csi_uport_checker.sv"] \
 [file normalize "${currentDir}/csi_top/src/csi_uport_decode.sv"] \
 [file normalize "${currentDir}/csi_top/src/csi_uport_encode.sv"] \
 [file normalize "${currentDir}/csi_top/src/csi_uport_req_gen.sv"] \
 [file normalize "${currentDir}/csi_top/src/uport_counters.sv"] \
 [file normalize "${currentDir}/csi_top/src/design_1_wrapper.sv"] \
 [file normalize "${currentDir}/csi_top/src/design_rp_wrapper.v"] \
 [file normalize "${currentDir}/csi_top/src/cdx5n_attr_defines.vh"] \
 [file normalize "${currentDir}/csi_top/src/axi_vip_master_agent.sv"] \
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj

# None
set infile [open [get_files design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [get_files design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]

set files [list \
 [file normalize "${currentDir}/csi_top/sim_files/board_common.vh"] \
 [file normalize "${currentDir}/csi_top/sim_files/pci_exp_usrapp_cfg.v"] \
 [file normalize "${currentDir}/csi_top/sim_files/pci_exp_expect_tasks.vh"] \
 [file normalize "${currentDir}/csi_top/sim_files/pci_exp_usrapp_com.v"] \
 [file normalize "${currentDir}/csi_top/sim_files/pci_exp_usrapp_rx.v"] \
 [file normalize "${currentDir}/csi_top/sim_files/sample_tests_1024.vh"] \
 [file normalize "${currentDir}/csi_top/sim_files/pci_exp_usrapp_tx.v"] \
 [file normalize "${currentDir}/csi_top/sim_files/sys_clk_gen.v"] \
 [file normalize "${currentDir}/csi_top/sim_files/sys_clk_gen_ds.v"] \
 [file normalize "${currentDir}/csi_top/sim_files/xilinx_pcie5_versal_rp.sv"] \
 [file normalize "${currentDir}/csi_top/sim_files/board.v"] \
 [file normalize "${currentDir}/csi_top/sim_files/tests.vh"] \
]

import_files -norecurse -fileset $obj $files

set core_rev [get_property CORE_REVISION [get_ipdefs -all   *cpm5n*]]

# None
set infile [open [get_files design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "cpm5n_v1_0_7_pkg" "cpm5n_v1_0_${core_rev}_pkg"] $contents]

set outfile  [open [get_files design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile
}
##################################################################
# DESIGN PROCs
##################################################################

if {([lsearch $options CPM5N_Preset.VALUE] == -1) || ([lsearch $options "CPM5N_CSI_Uport_Bottom_Design"] != -1)} {
puts "INFO: default CPM5N_CSI_Uport_Bottom_Design preset is selected."
source "$currentDir/csi_bottom/design_1_bd.tcl"
regenerate_bd_layout
validate_bd_design
save_bd_design
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"
close_bd_design [get_bd_designs $design_name]

source "$currentDir/csi_bottom/design_rp_bd.tcl"
regenerate_bd_layout
validate_bd_design
save_bd_design
set_property synth_checkpoint_mode None [get_files design_rp.bd]
generate_target all [get_files design_rp.bd]
puts "INFO: RP bd generated"
close_bd_design [get_bd_designs design_rp]

source "$currentDir/csi_bottom/design_uport_bd.tcl"
regenerate_bd_layout
validate_bd_design
save_bd_design
set_property synth_checkpoint_mode None [get_files uport_if.bd]
generate_target all [get_files uport_if.bd]
puts "INFO: uport bd generated"
close_bd_design [get_bd_designs uport_if]

# Generate a top level, specify a top module explicitly, or let Vivado manage it
if { [info exists top_module] } {
  set_property top $top_module [current_fileset]
}

create_ip -name axi_vip -vendor xilinx.com -library ip -module_name axi_vip_0
set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} CONFIG.PROTOCOL {AXI4LITE} ] [get_ips axi_vip_0]
set_property synth_checkpoint_mode None [get_files axi_vip_0.xci]
generate_target all [get_files axi_vip_0.xci]

set_property used_in simulation [get_files design_rp_wrapper.v]
set_property used_in simulation [get_files axi_vip_master_agent.sv]
set_property used_in simulation [get_files design_rp.bd]
set_property used_in simulation [get_files axi_vip_0.xci]
update_compile_order -fileset sources_1

} elseif {[regexp "CPM5N_CSI_Uport_Top_Design" $options]} {

puts "INFO: CPM5N_CSI_Uport_Top_Design preset is selected."

source "$currentDir/csi_top/design_1_bd.tcl"
regenerate_bd_layout
validate_bd_design
save_bd_design
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"
close_bd_design [get_bd_designs $design_name]

source "$currentDir/csi_top/design_rp_bd.tcl"
regenerate_bd_layout
validate_bd_design
save_bd_design
set_property synth_checkpoint_mode None [get_files design_rp.bd]
generate_target all [get_files design_rp.bd]
puts "INFO: RP bd generated"
close_bd_design [get_bd_designs design_rp]

source "$currentDir/csi_top/design_uport_bd.tcl"
regenerate_bd_layout
validate_bd_design
save_bd_design
set_property synth_checkpoint_mode None [get_files uport_if.bd]
generate_target all [get_files uport_if.bd]
puts "INFO: uport bd generated"
close_bd_design [get_bd_designs uport_if]

# Generate a top level, specify a top module explicitly, or let Vivado manage it
if { [info exists top_module] } {
  set_property top $top_module [current_fileset]
}

create_ip -name axi_vip -vendor xilinx.com -library ip -module_name axi_vip_0
set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} CONFIG.PROTOCOL {AXI4LITE} ] [get_ips axi_vip_0]
set_property synth_checkpoint_mode None [get_files axi_vip_0.xci]
generate_target all [get_files axi_vip_0.xci]

set_property used_in simulation [get_files design_rp_wrapper.v]
set_property used_in simulation [get_files axi_vip_master_agent.sv]
set_property used_in simulation [get_files design_rp.bd]
set_property used_in simulation [get_files axi_vip_0.xci]
update_compile_order -fileset sources_1

}

puts "Design Creation Complete"
append status_msg "Design Creation Complete\n"


open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2024.1/ced/Xilinx/IPI/Versal_CPM5N_CSI_Uport_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2024.1/ced/Xilinx/IPI/Versal_CPM5N_CSI_Uport_Design/readme.txt",
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

set OS [lindex $::tcl_platform(os) 0]

set_property top board [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

if { [string equal -nocase $OS "Windows"] == 0 } {
#set_property target_simulator Questa [current_project]
set_property target_simulator VCS [current_project]

set_property -name "vcs.elaborate.vcs.more_options" -value "+nospecify +notimingchecks" -objects $obj
set_property -name {vcs.simulate.runtime} -value {400000ns} -objects [get_filesets sim_1]
set_property -name {vcs.simulate.vcs.more_options} -value {} -objects [get_filesets sim_1]
set_property -name {vcs.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

} else {
puts "INFO: VCS simulator will not support on windows"

}

}

