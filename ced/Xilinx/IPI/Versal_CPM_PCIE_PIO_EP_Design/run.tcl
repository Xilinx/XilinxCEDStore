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
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/ep_mem.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/pcie_app_versal.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/pio.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/pio_ep.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/pio_ep_mem_access.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/pio_intr_ctrl.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/pio_rx_engine.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/pio_to_ctrl.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/pio_tx_engine.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/top_wrapper.v"] \
 [file normalize "${currentDir}/cpm4_pcie_pio/sources/tests.vh"] \
]

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for remote files
#set file "$currentDir/sources/tests.vh"
set file [get_files tests.vh]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "${design_name}_wrapper" -objects $obj

set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports sources top_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list  "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports sources top_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

set xdc [file join $currentDir cpm4_pcie_pio constraints top_impl.xdc]
import_files -fileset constrs_1 -norecurse $xdc

# Set 'utils_1' fileset object
set utils [file join $currentDir cpm4_pcie_pio pre_place.tcl]
import_files -fileset utils_1 -norecurse $utils

} else {

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/ep_mem.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/pcie_app_versal.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/pio.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/pio_ep.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/pio_ep_mem_access.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/pio_intr_ctrl.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/pio_rx_engine.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/pio_to_ctrl.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/pio_tx_engine.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/top_wrapper.v"] \
 [file normalize "${currentDir}/cpm5_pcie_pio/sources/tests.vh"] \
]
#add_files -norecurse -fileset $obj $files
import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for remote files
#set file "$currentDir/sources/tests.vh"
set file [get_files tests.vh]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "${design_name}_wrapper" -objects $obj

set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports sources top_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list  "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports sources top_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

set xdc [file join $currentDir cpm5_pcie_pio constraints top_impl.xdc]
import_files -fileset constrs_1 -norecurse $xdc

# Set 'utils_1' fileset object
set utils [file join $currentDir cpm5_pcie_pio pre_place.tcl]
import_files -fileset utils_1 -norecurse $utils
}

##################################################################
# DESIGN PROCs
##################################################################
#variable currentDir
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
source -notrace "$currentDir/create_cpm4_pio.tcl"
} else {
puts "INFO: CPM5 preset is selected."
source -notrace "$currentDir/create_cpm5_pio.tcl"
}
open_bd_design [get_files $design_name.bd]

}

