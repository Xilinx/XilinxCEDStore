
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]

source -notrace "$currentDir/zynq_mpsoc.tcl"

proc getSupportedParts {} {
}

proc getSupportedBoards {} {
   #return [get_board_parts -filter {(PART_NAME =~"*xczu9eg*") || (PART_NAME =~"*xczu7ev*")}  -latest_file_version]	
   return [get_board_parts -filter {(PART_NAME =~"*xczu*" && VENDOR_NAME=="xilinx.com" )}  -latest_file_version]
}

