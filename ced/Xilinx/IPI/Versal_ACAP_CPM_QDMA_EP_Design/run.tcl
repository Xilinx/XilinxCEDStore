# ########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

 # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

proc createDesign {design_name options} {



    # Set the reference directory for source file relative paths (by default the value is script directory path)
    variable currentDir

    # Create 'sources_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sources_1] ""]} {
        create_fileset -srcset sources_1
    }

   # Set 'sources_1' fileset object
set obj [get_filesets sources_1]

set board_name [get_property BOARD_NAME [current_board]]
puts $board_name 
if [regexp "vck190" $board_name] {
puts "INFO: CPM4 QDMA preset is selected."
set files [list \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/ST_c2h.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/ST_h2c.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/axi_st_module.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/dsc_byp_c2h.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/dsc_byp_h2c.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/h2c_slice.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_axi4lite_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_event_queue.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_fsm.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_int_ctrl.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_msg_mem.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_top.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_usr_int_mux.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_xpm_sdpram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_xpm_sdpram_wrap.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/pciecoredefines.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_debug_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_defines.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/qdma_pcie_dma_attr_defines.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/qdma_defines.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_axi4mm_axi_bridge.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_reg.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/qdma_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/pcie_dma_attr_defines.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_reg.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/flr/mdma_pre_flr.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_stm_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_fifo_lut.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_lpbk.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_stm_c2h_stub.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_stm_h2c_stub.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_stm_lpbk.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/user_control.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_dma_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/design_1_wrapper.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/mailbox/mailbox_axi4l_mux.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_91bx16_91bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_80bx512_80bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_80bx256_80bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_76bx256_76bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_72bx512_72bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_512bx512_512bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_512bx32_64bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_48bx512_48bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_48bx2048_48bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_40bx512_40bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_32bx2048_32bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_264bx512_264bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_24bx2048_24bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_21bx512_21bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_18bx2048_18bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_128bx2048_128bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_misc_output_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_misc_input_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_pasid_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_dsc_cpli_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_dsc_cpld_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_8Bx2048_4Bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_6Bx4096_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_64Bx512_32Bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_64Bx256_32Bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_64Bx128_32Bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_4Bx256_4Bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_4Bx2048_4Bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_2Bx4096_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_2Bx2048_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_16Bx4096_4Bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mi_16Bx2048_4Bwe_ram_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mdma_h2c_axis_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mdma_h2c_axis_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mdma_c2h_axis_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mdma_c2h_axis_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mdma_byp_out_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mdma_byp_out_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mdma_byp_in_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_mdma_byp_in_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_h2c_crdt_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_h2c_byp_out_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_h2c_byp_in_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_h2c_axis_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_h2c_axis_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_gic_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_fabric_output_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_fabric_input_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_dsc_out_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_dsc_in_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_crdt_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_c2h_crdt_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_c2h_byp_out_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_c2h_byp_in_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_c2h_axis_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_c2h_axis_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_byp_out_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_byp_out_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_byp_in_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_byp_in_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_axis_rq_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_axis_rq_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_axis_rc_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_axis_rc_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_axis_cq_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_axis_cq_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_axis_cc_if.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_pcie_axis_cc_if.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_pcie_dma_attr_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_mdma_reg.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_mdma_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_interface.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_dma_reg.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_dma_pcie_xdma_fab.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_dma_pcie_mdma_fab.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_dma_defines.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_dma_debug_defines.svh"] \
]


#add_files -norecurse -fileset $obj $files

# Import local files from the original project

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "${design_name}_wrapper" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/cpm4_qdma/constraints/top_impl.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/cpm4_qdma/constraints/top_impl.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src exdes design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src exdes design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/pcie_4_0_rp.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/sys_clk_gen.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/sys_clk_gen_ds.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/board_common.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/usp_pci_exp_usrapp_cfg.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/pci_exp_expect_tasks.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/usp_pci_exp_usrapp_com.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/usp_pci_exp_usrapp_rx.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/sample_tests.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/tests.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/usp_pci_exp_usrapp_tx.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/xilinx_pcie_uscale_rp.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/xp4_usp_smsw_model_core_top.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/board.v"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/sample_tests_sriov.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/usp_pci_exp_usrapp_tx_sriov.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/simulation_files/RP_model/qdma_stm_defines.svh"] \
]
#add_files -norecurse -fileset $obj $files
import_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "board" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports RP_model board.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports RP_model board.v] w]
puts -nonewline $outfile $contents
close $outfile
} 

if [regexp "vpk120.*" $board_name] {
puts $board_name
puts "INFO: VPK120 Board is selected."
if {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen4x8_MM_ST"] != -1)} {
puts "INFO: default CPM5_QDMA_Gen4x8_MM_ST preset is selected."
set files [list \
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/axi_st_module.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/dsc_byp_c2h.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/dsc_byp_h2c.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/qdma_app.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/qdma_ecc_enc.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/qdma_fifo_lut.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/qdma_lpbk.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/qdma_qsts.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/qdma_stm_c2h_stub.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/qdma_stm_h2c_stub.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/qdma_stm_lpbk.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/st_c2h.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/st_h2c.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/user_control.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/design_1_wrapper.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_mm_st/src/exdes/qdma_stm_defines.svh" ]\
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "${design_name}_wrapper" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports exdes design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports  exdes design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

} elseif {[regexp "CPM5_QDMA_Dual_Ctrl_Gen4x8_MM_ST" $options]} {
set obj [get_filesets sources_1]
   set files [list \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/axi_st_module.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/dsc_byp_c2h.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/dsc_byp_h2c.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/qdma_stm_defines.svh"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/qdma_app.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/qdma_ecc_enc.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/qdma_fifo_lut.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/qdma_lpbk.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/qdma_qsts.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/qdma_stm_c2h_stub.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/qdma_stm_h2c_stub.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/qdma_stm_lpbk.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/st_c2h.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/st_h2c.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/user_control.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/src/design_1_wrapper.sv"] \
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for local files
# None

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

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/cpm5_qdma_dual_ctrl/constraints/h10_schematic.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/cpm5_qdma_dual_ctrl/constraints/h10_schematic.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/cpm5_qdma_dual_ctrl/constraints/config_v_bs_compress.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/cpm5_qdma_dual_ctrl/constraints/config_v_bs_compress.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/sim_files/design_1_wrapper_sim_wrapper.v"] \
 ]
#add_files -norecurse -fileset $obj $files
import_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "${design_name}_wrapper_sim_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files design_1_wrapper_sim_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files design_1_wrapper_sim_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

# Set 'utils_1' fileset object
set obj [get_filesets utils_1]
set files [list \
    [file normalize "${currentDir}/cpm5_qdma_dual_ctrl/scripts/pre_place.tcl"] \
]
add_files -norecurse -fileset $obj $files

# Set 'utils_1' fileset file properties for remote files
set file "$currentDir/cpm5_qdma_dual_ctrl/scripts/pre_place.tcl"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets utils_1] [list "*$file"]]
set_property -name "file_type" -value "TCL" -objects $file_obj

set_property STEPS.PLACE_DESIGN.TCL.PRE [get_files pre_place.tcl -of [get_fileset utils_1] ] [get_runs impl_1]

# Set 'utils_1' fileset file properties for local files
# None

# Set 'utils_1' fileset properties
set obj [get_filesets utils_1]
 
} elseif {[regexp "CPM5_QDMA_Gen4x8_MM_Only_Performance_Design" $options]} {
set files [list \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/ST_c2h.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/ST_c2h_cmpt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/ST_h2c.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/axi_st_module.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/crc32_gen.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/desc_cnt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/l3fwd_cntr.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/next_queue_fifo.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/perf_cntr.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/queue_cnts.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/user_control.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/qdma_stm_defines.svh"] \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/src/design_1_wrapper.sv"] \
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for local files
# None

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

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/cpm5_qdma_mm_only/constraints/config_v_bs_compress.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/cpm5_qdma_mm_only/constraints/config_v_bs_compress.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/cpm5_qdma_mm_only/constraints/vpk120_schematic.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/cpm5_qdma_mm_only/constraints/vpk120_schematic.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${currentDir}/cpm5_qdma_mm_only/sim_files/design_1_wrapper_sim_wrapper.v"] \
 ]
#add_files -norecurse -fileset $obj $files
import_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "${design_name}_wrapper_sim_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files design_1_wrapper_sim_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files design_1_wrapper_sim_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

# Set 'utils_1' fileset object
set obj [get_filesets utils_1]
set files [list \
    [file normalize "${currentDir}/cpm5_qdma_mm_only/scripts/pre_place.tcl"] \
]
add_files -norecurse -fileset $obj $files

# Set 'utils_1' fileset file properties for remote files
set file "$currentDir/cpm5_qdma_mm_only/scripts/pre_place.tcl"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets utils_1] [list "*$file"]]
set_property -name "file_type" -value "TCL" -objects $file_obj

set_property STEPS.PLACE_DESIGN.TCL.PRE [get_files pre_place.tcl -of [get_fileset utils_1] ] [get_runs impl_1]

# Set 'utils_1' fileset file properties for local files
# None

# Set 'utils_1' fileset properties
set obj [get_filesets utils_1]
} elseif {[regexp "CPM5_QDMA_Gen4x8_ST_Only_Performance_Design" $options]} {
 set files [list \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/ST_c2h.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/ST_c2h_cmpt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/ST_h2c.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/axi_st_module.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/crc32_gen.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/desc_cnt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/l3fwd_cntr.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/next_queue_fifo.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/perf_cntr.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/queue_cnts.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/user_control.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/qdma_stm_defines.svh"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/design_1_wrapper.sv"] \
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for local files
# None

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

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/cpm5_qdma_st_only/constraints/config_v_bs_compress.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/cpm5_qdma_st_only/constraints/config_v_bs_compress.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${currentDir}/cpm5_qdma_st_only/sim_files/design_1_wrapper_sim_wrapper.v"] \
 ]
#add_files -norecurse -fileset $obj $files
import_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "${design_name}_wrapper_sim_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files design_1_wrapper_sim_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sim_1 imports sim_files design_1_wrapper_sim_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

# Set 'utils_1' fileset object
set obj [get_filesets utils_1]
set files [list \
    [file normalize "${currentDir}/cpm5_qdma_st_only/scripts/pre_place.tcl"] \
]
add_files -norecurse -fileset $obj $files

# Set 'utils_1' fileset file properties for remote files
set file "$currentDir/cpm5_qdma_st_only/scripts/pre_place.tcl"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets utils_1] [list "*$file"]]
set_property -name "file_type" -value "TCL" -objects $file_obj

set_property STEPS.PLACE_DESIGN.TCL.PRE [get_files pre_place.tcl -of [get_fileset utils_1] ] [get_runs impl_1]

# Set 'utils_1' fileset file properties for local files
# None

# Set 'utils_1' fileset properties
set obj [get_filesets utils_1]
}

}


open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2022.2/ced/Xilinx/IPI/Versal_ACAP_CPM_QDMA_EP_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2022.2/ced/Xilinx/IPI/Versal_ACAP_CPM_QDMA_EP_Design/readme.txt",
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
 
##################################################################
# DESIGN PROCs
##################################################################

set board_name [get_property BOARD_NAME [current_board]]
if [regexp "vck190" $board_name] {
puts "INFO: vck190 board selected"
set use_cpm "CPM4"
} else {
puts "INFO: vpk120 board selected"
set use_cpm "CPM5"
}

if [regexp "CPM4" $use_cpm] {
puts "INFO: CPM4 preset is selected."
source -notrace "$currentDir/create_cpm4.tcl"
} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen4x8_MM_ST"] != -1)} {
puts "INFO: CPM5_QDMA_Gen4x8_MM_ST preset is selected."
source -notrace "$currentDir/create_cpm5.tcl"
} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Dual_Ctrl_Gen4x8_MM_ST"] != -1)} {
puts "INFO: CPM5_QDMA_Dual_Ctrl_Gen4x8_MM_ST preset is selected."
source "$currentDir/cpm5_qdma_dual_ctrl/design_1_bd.tcl"
puts "INFO: EP bd generated"
regenerate_bd_layout

source  "$currentDir/cpm5_qdma_dual_ctrl/xlnoc_bd.tcl"
puts "INFO: xlnoc bd generated"
regenerate_bd_layout

set_property used_in simulation  [get_files  xlnoc.bd]
} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen4x8_MM_Only_Performance_Design"] != -1)} {
puts "INFO: CPM5_QDMA_Gen4x8_MM_Only_Performance_Design preset is selected."
source "$currentDir/cpm5_qdma_mm_only/design_1_bd.tcl"
puts "INFO: EP bd generated"
regenerate_bd_layout

source  "$currentDir/cpm5_qdma_mm_only/xlnoc_bd.tcl"
puts "INFO: xlnoc bd generated"
regenerate_bd_layout
set_property used_in simulation  [get_files  xlnoc.bd]
} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen4x8_ST_Only_Performance_Design"] != -1)} {
puts "INFO: CPM5_QDMA_Gen4x8_ST_Only_Performance_Design preset is selected."
source "$currentDir/cpm5_qdma_st_only/design_1_bd.tcl"
puts "INFO: EP bd generated"
regenerate_bd_layout

source  "$currentDir/cpm5_qdma_st_only/xlnoc_bd.tcl"
puts "INFO: xlnoc bd generated"
regenerate_bd_layout
set_property used_in simulation  [get_files  xlnoc.bd]

} 
open_bd_design [get_files $design_name.bd]

}

