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
   puts $currentDir

    # Create 'sources_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sources_1] ""]} {
        create_fileset -srcset sources_1
    }

   # Set 'sources_1' fileset object
   set obj [get_filesets sources_1]
   
   set files [list \
    [file normalize "${currentDir}/src/design_1_wrapper.sv"] \
    [file normalize "${currentDir}/src/dsc_byp_c2h.sv"] \
    [file normalize "${currentDir}/src/axil_responder.sv"] \
    [file normalize "${currentDir}/src/PS2PL_ctrl.sv"] \
    [file normalize "${currentDir}/src/qdma_stm_defines.svh"] \
    [file normalize "${currentDir}/src/user_control.sv"] \
    [file normalize "${currentDir}/src/queue_cnts.sv"] \
    [file normalize "${currentDir}/src/next_queue_fifo.sv"] \
    [file normalize "${currentDir}/src/desc_cnt.sv"] \
    [file normalize "${currentDir}/src/qdma_accel_ced_axist.sv"] \
    [file normalize "${currentDir}/src/crc32_gen.sv"] \
    [file normalize "${currentDir}/src/qdma_accel_ced_axist_h2c_2_c2h.sv"] \
    [file normalize "${currentDir}/src/ST_c2h_cmpt.sv"] \
    [file normalize "${currentDir}/src/ipi_cdma_intr.elf"] \
    [file normalize "${currentDir}/src/qdma_accel_sys.bif"] \
   ]
   
   import_files -norecurse -fileset $obj $files
   puts "INFO: Design files are imported to the project"
   # Set 'sources_1' fileset properties -- Set top module 
   set obj [get_filesets sources_1]
   set_property -name "top" -value "design_1_wrapper" -objects $obj
   puts "INFO: design_1_wrapper.sv file is set as top module of the design"
   
   # Create 'constrs_1' fileset (if not found)
   if {[string equal [get_filesets -quiet constrs_1] ""]} {
     create_fileset -constrset constrs_1
   }
   
   set xdc1 [file join $currentDir constraints config_v_bs_compress.xdc]
   import_files -fileset constrs_1 -norecurse $xdc1
   
   set xdc2 [file join $currentDir constraints vpk120_lpddr_3MC_no_interleave.xdc]
   import_files -fileset constrs_1 -norecurse $xdc2    
   puts "INFO: Design constraints files are imported to the project"
   ##################################################################
   # DESIGN PROCs
   ##################################################################
   set board_name [get_property BOARD_NAME [current_board]]
   if [regexp "vpk120" $board_name] {
   puts "INFO: vpk120 board selected"
   set use_cpm "CPM5"
   }

   if [regexp "CPM5" $use_cpm] {
   puts "INFO: CPM5 preset is selected."

   set board_part_name [get_property PART_NAME [current_board_part]]
   if [regexp "xcvp1202-vsva2785-2MHP-e-S" $board_part_name] {
   set_property SEGMENTED_CONFIGURATION true [current_project]
   puts "INFO: Project is set to Segmented Configuration flow"
   source "$currentDir/scripts/design_1_bd.tcl"
   # Set synthesis property to be non-OOC
   set_property synth_checkpoint_mode None [get_files $design_name.bd]
   validate_bd_design
   puts "INFO: Block design validation completed"
   save_bd_design
   puts "INFO: Block design is saved"
   generate_target all [get_files $design_name.bd]      
   open_bd_design [get_bd_files $design_name]   
   regenerate_bd_layout     
   puts "INFO: File generation for the IPs in the block design is completed"
   puts "INFO: EP bd generated"
   puts "INFO: design generation completed successfully"
   } 
   }
}
