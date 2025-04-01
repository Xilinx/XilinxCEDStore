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

variable currentDir
puts $currentDir

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]

if {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen5x8_ST_Performance_Design"] != -1)} {
puts "INFO: default CPM5_QDMA_Gen5x8_ST_Performance_Design preset is selected."
set files [list \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/ST_c2h.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/ST_c2h_cmpt.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/ST_h2c.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/ST_h2c_crdt.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/axi_st_module.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/crc32_gen.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/desc_cnt.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/dsc_byp_c2h.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/dsc_byp_h2c.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/dsc_crdt.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/dsc_crdt_mux.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/dsc_crdt_wrapper.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/l3fwd_cntr.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/next_queue_fifo.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/perf_cntr.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/qdma_stm_defines.svh"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/qdma_app.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/qdma_ecc_enc.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/queue_cnts.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/user_control.sv"]\
 [file normalize "${currentDir}/cpm5_qdma_g5x8_st_perf/src/exdes/design_1_wrapper.sv"]\
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

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

set xdc1 [file join $currentDir cpm5_qdma_g5x8_st_perf constraints config_v_bs_compress.xdc]
import_files -fileset constrs_1 -norecurse $xdc1

set xdc2 [file join $currentDir cpm5_qdma_g5x8_st_perf constraints vpk120_schematic.xdc]
import_files -fileset constrs_1 -norecurse $xdc2


set xdc3 [file join $currentDir cpm5_qdma_g5x8_st_perf constraints constraint.xdc]
import_files -fileset constrs_1 -norecurse $xdc3

set xdcfile1 [file join [get_property directory [current_project]] [current_project].srcs constrs_1 imports constraints constraint.xdc]
set_property used_in_implementation false [get_files $xdcfile1]

} elseif {[regexp "CPM5_QDMA_Dual_Gen5x8_ST_Performance_Design" $options]} {

puts "INFO: default CPM5_QDMA_Dual_Gen5x8_ST_Performance_Design preset is selected."
set files [list \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/ST_c2h.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/ST_c2h_cmpt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/ST_h2c.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/ST_h2c_crdt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/axi_st_module.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/crc32_gen.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/desc_cnt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/dsc_byp_c2h.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/dsc_byp_h2c.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/dsc_crdt.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/dsc_crdt_mux.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/dsc_crdt_wrapper.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/l3fwd_cntr.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/next_queue_fifo.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/perf_cntr.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/qdma_stm_defines.svh"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/qdma_app.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/qdma_ecc_enc.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/queue_cnts.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/user_control.sv"] \
 [file normalize "${currentDir}/cpm5_qdma_g5x8_dual_perf/src/design_1_wrapper.sv"] \
 
]

import_files -norecurse -fileset $obj $files



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

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

set xdc4 [file join $currentDir cpm5_qdma_g5x8_dual_perf constraints config_v_bs_compress.xdc]
import_files -fileset constrs_1 -norecurse $xdc4

set xdc5 [file join $currentDir cpm5_qdma_g5x8_dual_perf constraints vpk120_schematic.xdc]
import_files -fileset constrs_1 -norecurse $xdc5

set xdc6 [file join $currentDir cpm5_qdma_g5x8_dual_perf constraints constraint.xdc]
import_files -fileset constrs_1 -norecurse $xdc6

set xdcfile2 [file join [get_property directory [current_project]] [current_project].srcs constrs_1 imports constraints constraint.xdc]
set_property used_in_implementation false [get_files $xdcfile2]

}
##################################################################
# DESIGN PROCs
##################################################################

if {([lsearch $options CPM5_Preset.VALUE] == -1) || ([lsearch $options "CPM5_QDMA_Gen5x8_ST_Performance_Design"] != -1)} {
puts "INFO: default CPM5_QDMA_Gen5x8_ST_Performance_Design preset is selected."

source "$currentDir/cpm5_qdma_g5x8_st_perf/design_1_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode Hierarchical [get_files $design_name.bd]
#set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"

regenerate_bd_layout

open_bd_design [get_bd_files $design_name.bd]

validate_bd_design
save_bd_design
 
puts "INFO: design generation completed successfully"

set_property strategy Performance_Explore [get_runs impl_*]

} elseif {[regexp "CPM5_QDMA_Dual_Gen5x8_ST_Performance_Design" $options]} {

puts "INFO: default CPM5_QDMA_Dual_Gen5x8_ST_Performance_Design preset is selected."
source "$currentDir/cpm5_qdma_g5x8_dual_perf/design_1_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode Hierarchical [get_files $design_name.bd]
#set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"

regenerate_bd_layout

open_bd_design [get_bd_files $design_name.bd]

validate_bd_design
save_bd_design

set_property strategy Performance_Explore [get_runs impl_*]

puts "INFO: design generation completed successfully"


}

}
