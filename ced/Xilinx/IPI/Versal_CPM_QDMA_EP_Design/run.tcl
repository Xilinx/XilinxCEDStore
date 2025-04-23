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
puts "INFO: VCK190 Board is selected."
if {([lsearch $options CPM4_Preset.VALUE] == -1) || ([lsearch $options "CPM4_QDMA_Gen4x8_MM_ST_Design"] != -1)} {
puts "INFO: default CPM4_QDMA_Gen4x8_MM_ST_Design preset is selected."

set files [list \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/ST_c2h.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/ST_h2c.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/axi_st_module.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/dsc_byp_c2h.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/dsc_byp_h2c.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/h2c_slice.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_stm_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_fifo_lut.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_lpbk.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_stm_c2h_stub.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_stm_h2c_stub.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/qdma_stm_lpbk.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/user_control.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/pcie_dma_attr_defines.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/mdma_reg.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_defines.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/qdma_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_reg.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/qdma_defines.vh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/dma_debug_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_dma_defines.svh"] \
 [file normalize "${currentDir}/cpm4_qdma/src/exdes/design_1_wrapper.sv"] \
 [file normalize "${currentDir}/cpm4_qdma/src/include/pciecoredefines.vh"] \
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
 [file normalize "${currentDir}/cpm4_qdma/src/include/cpm_axi4mm_axi_bridge.vh"] \
]


#add_files -norecurse -fileset $obj $files

# Import local files from the original project

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

set xdc1 [file join $currentDir cpm4_qdma constraints top_impl.xdc]
import_files -fileset constrs_1 -norecurse $xdc1

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src exdes design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src exdes design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

} elseif {[regexp "CPM4_QDMA_Gen4x8_MM_ST_Performance_Design" $options]} {
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/ST_c2h.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/ST_c2h_cmpt.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/ST_h2c.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/axi_st_module.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/desc_cnt.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/dsc_byp_c2h.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/dsc_byp_h2c.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/l3fwd_cntr.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/next_queue_fifo.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/perf_cntr.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/queue_cnts.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/user_control.sv"] \
 [file normalize "${currentDir}/cpm4_qdma_perf/src/exdes/design_1_wrapper.sv"] \
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports exdes design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports  exdes design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

set xdc2 [file join $currentDir cpm4_qdma_perf constraints top_impl.xdc]
import_files -fileset constrs_1 -norecurse $xdc2
}

}

if [regexp "vpk120.*" $board_name] {
puts $board_name
puts "INFO: VPK120 Board is selected."
if {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen4x8_MM_ST_Design"] != -1)} {
puts "INFO: default CPM5_QDMA_Gen4x8_MM_ST_Design preset is selected."
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
set_property -name "top" -value "design_1_wrapper" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports exdes design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports  exdes design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

set xdc3 [file join $currentDir cpm5_qdma_mm_st constraints vpk120_schematic.xdc]
import_files -fileset constrs_1 -norecurse $xdc3

set_property strategy Performance_Explore [get_runs impl_1]

} elseif {[regexp "CPM5_QDMA_Dual_Gen4x8_MM_ST_Design" $options]} {
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
set_property -name "top" -value "design_1_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

set xdc4 [file join $currentDir cpm5_qdma_dual_ctrl constraints vpk120_schematic.xdc]
import_files -fileset constrs_1 -norecurse $xdc4


set xdc5 [file join $currentDir cpm5_qdma_dual_ctrl constraints config_v_bs_compress.xdc]
import_files -fileset constrs_1 -norecurse $xdc5

set utils [file join $currentDir cpm5_qdma_dual_ctrl scripts pre_place.tcl]
import_files -fileset utils_1 -norecurse $utils
 
} elseif {[regexp "CPM5_QDMA_Gen4x8_ST_Performance_Design" $options]} {
 set files [list \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/ST_c2h.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/ST_c2h_cmpt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/ST_h2c.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/ST_h2c_crdt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/axi_st_module.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/crc32_gen.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/desc_cnt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/l3fwd_cntr.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/next_queue_fifo.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/perf_cntr.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/qdma_app.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/queue_cnts.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/dsc_crdt_wrapper.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/dsc_byp_c2h.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/dsc_byp_h2c.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/dsc_crdt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/dsc_crdt_mux.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/qdma_ecc_enc.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/user_control.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/qdma_stm_defines.svh"] \
 [file normalize "${currentDir}/cpm5_qdma_st_only/src/design_1_wrapper.sv"] \
]

import_files -norecurse -fileset $obj $files



# Set 'sources_1' fileset file properties for local files
# None

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

set xdc6 [file join $currentDir cpm5_qdma_st_only constraints config_v_bs_compress.xdc]
import_files -fileset constrs_1 -norecurse $xdc6

set xdc7 [file join $currentDir cpm5_qdma_st_only constraints vpk120_schematic.xdc]
import_files -fileset constrs_1 -norecurse $xdc7

set xdc8 [file join $currentDir cpm5_qdma_st_only constraints constraint.xdc]
import_files -fileset constrs_1 -norecurse $xdc8

set xdcfile [file join [get_property directory [current_project]] [current_project].srcs constrs_1 imports constraints constraint.xdc]
set_property used_in_implementation false [get_files $xdcfile]



# Set 'utils_1' fileset object

set utils [file join $currentDir cpm5_qdma_st_only scripts pre_place.tcl]
import_files -fileset utils_1 -norecurse $utils

set_property STEPS.PLACE_DESIGN.TCL.PRE [get_files pre_place.tcl -of [get_fileset utils_1] ] [get_runs impl_1]

# Set 'utils_1' fileset file properties for local files
# None


} elseif {[regexp "CPM5_QDMA_Gen5x8_MM_Performance_Design" $options]} {
set board_part_name [get_property PART_NAME [current_board_part]]
if [regexp "xcvp1202-vsva2785-2MHP-e-S" $board_part_name] {
# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
# Import local files from the original project
set files [list \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_mm_perf/src/design_1_wrapper.v"]\
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "design_1_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1 " "$design_name "] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports  src design_1_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

set xdc9 [file join $currentDir cpm5_qdma_g5x8_mm_perf constraints vpk120_lpddr_3MC_no_interleave.xdc]
import_files -fileset constrs_1 -norecurse $xdc9


set xdc10 [file join $currentDir cpm5_qdma_g5x8_mm_perf constraints config_v_bs_compress.xdc]
import_files -fileset constrs_1 -norecurse $xdc10

} else {
puts "Warning: No design created as -2MP variant of VPK120 board is selected.
      The Gen5 speed is supported for -2MHP or above speed grade part.
      Please select VPK120 board with -2MHP speed grade variant under \"switch part\" selection while choosing the board part."
}
}
}

open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/Versal_CPM_QDMA_EP_Design/readme.txt} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
    1. Refer to https://github.com/Xilinx/XilinxCEDStore/tree/2025.1/ced/Xilinx/IPI/Versal_CPM_QDMA_EP_Design/readme.txt",
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
if {([lsearch $options CPM4_Preset.VALUE] == -1) || ([lsearch $options "CPM4_QDMA_Gen4x8_MM_ST_Design"] != -1)} {
puts "INFO: CPM4_QDMA_Gen4x8_MM_ST_Design preset is selected."
source -notrace "$currentDir/create_cpm4.tcl"
} elseif {([lsearch $options CPM4_Preset.VALUE] == -1) || ([lsearch $options "CPM4_QDMA_Gen4x8_MM_ST_Performance_Design"] != -1)} {
puts "INFO: CPM4_QDMA_Gen4x8_MM_ST_Performance_Design preset is selected."
source -notrace "$currentDir/cpm4_qdma_perf/design_1_bd.tcl"
}

} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen4x8_MM_ST_Design"] != -1)} {
puts "INFO: CPM5_QDMA_Gen4x8_MM_ST_Design preset is selected."
source -notrace "$currentDir/create_cpm5.tcl"
} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Dual_Gen4x8_MM_ST_Design"] != -1)} {
puts "INFO: CPM5_QDMA_Dual_Gen4x8_MM_ST_Design preset is selected."
source "$currentDir/cpm5_qdma_dual_ctrl/design_1_bd.tcl"
puts "INFO: EP bd generated"
regenerate_bd_layout

} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen4x8_ST_Performance_Design"] != -1)} {
puts "INFO: CPM5_QDMA_Gen4x8_ST_Performance_Design preset is selected."
source "$currentDir/cpm5_qdma_st_only/design_1_bd.tcl"
set_property synth_checkpoint_mode Hierarchical [get_files $design_name.bd]
#set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"
regenerate_bd_layout

} elseif {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen5x8_MM_Performance_Design"] != -1)} {

set board_part_name [get_property PART_NAME [current_board_part]]
if [regexp "xcvp1202-vsva2785-2MHP-e-S" $board_part_name] {
source "$currentDir/cpm5_qdma_g5x8_mm_perf/design_1_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"

regenerate_bd_layout

} else {

open_bd_design [get_bd_files $design_name]

    set_property USER_COMMENTS.comment_0 {} [current_bd_design]
    set_property USER_COMMENTS.comment0 {Warning: No design created as -2MP variant of VPK120 board is selected.
    The Gen5 speed is supported for -2MHP or above speed grade part.
    Please select VPK120 board with -2MHP speed grade variant under switch part selection while choosing the board part.} [current_bd_design]

    regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Warning: No design created as -2MP variant of VPK120 board is selected.
    The Gen5 speed is supported for -2MHP or above speed grade part.
    Please select VPK120 board with -2MHP speed grade variant under switch part selection while choosing the board part.",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
    #  -string -flagsOSRD
    preplace cgraphic comment_0 place right -1200 -130 textcolor 4 linecolor 3
    ",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }

generate_target all [get_files $design_name]

regenerate_bd_layout

validate_bd_design
save_bd_design

}

}

open_bd_design [get_files $design_name.bd]

}
