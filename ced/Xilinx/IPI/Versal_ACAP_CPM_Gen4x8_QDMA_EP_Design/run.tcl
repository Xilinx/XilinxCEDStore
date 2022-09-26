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

if [regexp "CPM4" $options] {

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

} else {
set files [list \
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/axi_st_module.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/dsc_byp_c2h.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/dsc_byp_h2c.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/qdma_app.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/qdma_ecc_enc.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/qdma_fifo_lut.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/qdma_lpbk.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/qdma_qsts.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/qdma_stm_c2h_stub.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/qdma_stm_h2c_stub.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/qdma_stm_lpbk.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/st_c2h.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/st_h2c.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/user_control.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/design_1_wrapper.sv"]\
 [file normalize "${currentDir}/cpm5_qdma/src/exdes/qdma_stm_defines.svh" ]\
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

}
##################################################################
# DESIGN PROCs
##################################################################
#variable currentDir
#
#
#
#
#default option is CPM4
set cpm "Preset.VALUE"
set board_name [get_property BOARD_NAME [current_board]]
if [regexp "vck190" $board_name] {
puts "INFO: vck190 board selected"
set use_cpm "CPM4"
} else {
puts "INFO: vpk120 board selected"
set use_cpm "CPM5"
}

if { [dict exists $options $cpm] } {
set use_cpm [dict get $options $cpm ]
}
if [regexp "CPM4" $use_cpm] {
puts "INFO: CPM4 preset is selected."
source -notrace "$currentDir/create_cpm4.tcl"
} else {
puts "INFO: CPM5 preset is selected."
source -notrace "$currentDir/create_cpm5.tcl"
}

open_bd_design [get_files $design_name.bd]

}
