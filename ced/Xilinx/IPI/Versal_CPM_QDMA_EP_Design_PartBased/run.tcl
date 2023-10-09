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
# Import local files from the original project
set files [list \
 [file normalize "${currentDir}/src/exdes/ST_c2h.sv"]\
 [file normalize "${currentDir}/src/exdes/ST_c2h_cmpt.sv"]\
 [file normalize "${currentDir}/src/exdes/ST_h2c.sv"]\
 [file normalize "${currentDir}/src/exdes/ST_h2c_crdt.sv"]\
 [file normalize "${currentDir}/src/exdes/axi_st_module.sv"]\
 [file normalize "${currentDir}/src/exdes/crc32_gen.sv"]\
 [file normalize "${currentDir}/src/exdes/desc_cnt.sv"]\
 [file normalize "${currentDir}/src/exdes/dsc_byp_c2h.sv"]\
 [file normalize "${currentDir}/src/exdes/dsc_byp_h2c.sv"]\
 [file normalize "${currentDir}/src/exdes/dsc_crdt.sv"]\
 [file normalize "${currentDir}/src/exdes/dsc_crdt_mux.sv"]\
 [file normalize "${currentDir}/src/exdes/dsc_crdt_wrapper.sv"]\
 [file normalize "${currentDir}/src/exdes/l3fwd_cntr.sv"]\
 [file normalize "${currentDir}/src/exdes/next_queue_fifo.sv"]\
 [file normalize "${currentDir}/src/exdes/perf_cntr.sv"]\
 [file normalize "${currentDir}/src/exdes/qdma_stm_defines.svh"]\
 [file normalize "${currentDir}/src/exdes/qdma_app.sv"]\
 [file normalize "${currentDir}/src/exdes/queue_cnts.sv"]\
 [file normalize "${currentDir}/src/exdes/user_control.sv"]\
 [file normalize "${currentDir}/src/exdes/design_1_wrapper.sv"]\
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "${design_name}_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports exdes design_1_wrapper.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports  exdes design_1_wrapper.sv] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/constraints/config_v_bs_compress.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/constraints/config_v_bs_compress.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/constraints/vpk120_schematic.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/constraints/vpk120_schematic.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

##################################################################
# DESIGN PROCs
##################################################################


source "$currentDir/design_1_bd.tcl"
# Set synthesis property to be non-OOC
set_property synth_checkpoint_mode None [get_files $design_name.bd]
generate_target all [get_files $design_name.bd]
puts "INFO: EP bd generated"

regenerate_bd_layout

open_bd_design [get_bd_files $design_name.bd]

validate_bd_design
save_bd_design
 
puts "INFO: design generation completed successfully"


}


