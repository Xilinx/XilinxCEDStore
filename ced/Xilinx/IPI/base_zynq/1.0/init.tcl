
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]

source -notrace "$currentDir/zynq.tcl"

proc getSupportedParts {} {
}

proc getSupportedBoards {} {
   return [get_board_parts -filter {PART_NAME=~"*xc7z*" && VENDOR_NAME=="xilinx.com"} -latest_file_version]
}

