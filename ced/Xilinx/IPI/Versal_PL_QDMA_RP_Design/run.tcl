proc createDesign {design_name options} {

    # Set the reference directory for source file relative paths (by default the value is script directory path)
    variable currentDir

    # Create 'sources_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sources_1] ""]} {
        create_fileset -srcset sources_1
    }

   # Set 'sources_1' fileset object
set obj [get_filesets sources_1]

if [regexp "PL_PCIE4" $options] {

set xdc [file join $currentDir pl_pcie4_qdma constraints xilinx_pcie_versal_x1y0.xdc]
import_files -fileset constrs_1 -norecurse $xdc

} else {

#set xdc [file join $currentDir pl_pcie5_qdma constraints xilinx_xdma_pcie_x1y0.xdc]

# Create a list containing both XDC files
set xdc_files [list \
    [file join $currentDir pl_pcie5_qdma constraints xilinx_xdma_pcie_x1y0.xdc] \
    [file join $currentDir pl_pcie5_qdma constraints VP-X-A2785-00_C0.xdc ]]
import_files -fileset constrs_1 -norecurse $xdc_files

}

##################################################################
# DESIGN PROCs
##################################################################
#variable currentDir
#
#default option is PL_PCIE4
set pl_pcie "Preset.VALUE"
set board_name [get_property BOARD_NAME [current_board]]
if [regexp "vck190" $board_name] {
puts "INFO: vck190 board selected"
set use_pl_pcie "PL_PCIE4"
} else {
puts "INFO: vpk120 board selected"
set use_pl_pcie "PL_PCIE5"
}

if { [dict exists $options $pl_pcie] } {
set use_pl_pcie [dict get $options $pl_pcie ]
}
if [regexp "PL_PCIE4" $use_pl_pcie] {
puts "INFO: PL_PCIE4 preset is selected."
source -notrace "$currentDir/create_pl_pcie4_qdma.tcl"
} else {
puts "INFO: PL_PCIE5 preset is selected."
source -notrace "$currentDir/create_pl_pcie5_qdma.tcl"
}

open_bd_design [get_files $design_name.bd]
set bd_file [get_files $design_name.bd]
set wrapper_file [make_wrapper -files $bd_file -top -force]
# Add the wrapper file to the project
add_files -norecurse $wrapper_file
update_compile_order -fileset sources_1

}

