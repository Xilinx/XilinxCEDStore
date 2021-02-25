
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
set_param cips.enablePSVIPsimulation  1
source -notrace "$currentDir/cips_vip.tcl"

proc getSupportedParts {} {
}

proc getSupportedBoards {} {
   return [get_board_parts -filter {(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com" ) || (BOARD_NAME =~"*vmk180*" && VENDOR_NAME=="xilinx.com" )} -latest_file_version]
   #return [get_board_parts -filter {PART_NAME=~"*xcvc*" && PART_NAME=~"*xcvm*" && VENDOR_NAME=="xilinx.com"} -latest_file_version]
}

