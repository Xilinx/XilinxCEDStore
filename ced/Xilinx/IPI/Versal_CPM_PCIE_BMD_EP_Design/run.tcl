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
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_EP_MEM.v"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_EP_MEM_ACCESS.v"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_INTR_CTRL.v"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/pcie_app_versal_bmd.vh"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_CC_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_CQ_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_EP_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RC_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RQ_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RQ_MUX_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RQ_READ_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_RQ_WRITE_512.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/BMD_AXIST_TO_CTRL.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/pcie_app_versal_bmd.sv"] \
  [file normalize "${currentDir}/cpm4_bmd_ep/src/design_1_wrapper.v"] \
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

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports src design_1_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/cpm4_bmd_ep/constraints/top_impl.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/cpm4_bmd_ep/constraints/top_impl.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Set 'utils_1' fileset object
set obj [get_filesets utils_1]
set files [list \
 [file normalize "${currentDir}/cpm4_bmd_ep/pre_place.tcl"] \
]
add_files -norecurse -fileset $obj $files

# Set 'utils_1' fileset file properties for remote files
set file "$currentDir/cpm4_bmd_ep/pre_place.tcl"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets utils_1] [list "*$file"]]
set_property -name "file_type" -value "TCL" -objects $file_obj


# Set 'utils_1' fileset file properties for local files
# None
set_property STEPS.PLACE_DESIGN.TCL.PRE [get_files pre_place.tcl -of [get_fileset utils_1] ] [get_runs impl_1]

# Set 'utils_1' fileset properties
set obj [get_filesets utils_1]

} else {

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_EP_MEM.v"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_EP_MEM_ACCESS.v"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_INTR_CTRL.v"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/pcie_app_versal_bmd.vh"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/pcie_intf_defs_cpm5n.vh"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/pcie_intf_defs_legacy.vh"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_CC_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_CQ_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_EP_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RC_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RQ_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RQ_MUX_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RQ_READ_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_RQ_WRITE_512.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/BMD_AXIST_TO_CTRL.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/pcie_app_versal_bmd.sv"] \
 [file normalize "${currentDir}/cpm5_bmd_ep/src/design_1_wrapper.sv"] \
]
#add_files -norecurse -fileset $obj $files
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

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/cpm5_bmd_ep/constraints/io_assign_pcie_rstn.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/cpm5_bmd_ep/constraints/io_assign_pcie_rstn.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]


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
source -notrace "$currentDir/cpm4_bmd_ep/design_1_bd.tcl"
} else {
puts "INFO: CPM5 preset is selected."
source -notrace "$currentDir/cpm5_bmd_ep/design_1_bd.tcl"
}
open_bd_design [get_files $design_name.bd]

}


