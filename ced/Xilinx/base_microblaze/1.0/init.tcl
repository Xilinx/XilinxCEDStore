
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]

source -notrace "$currentDir/microblaze.tcl"

proc getSupportedParts {} {
}

proc getSupportedBoards {} {
  #return [get_board_parts -filter { (PART_NAME!~"*xc7z*") && (PART_NAME!~"*XCKU115*") && BOARD_NAME!~*adm-pcie-7v3* && VENDOR_NAME=="xilinx.com"} -latest_file_version] 
   return [get_board_parts -filter { (PART_NAME!~"*xc7z*") && VENDOR_NAME=="xilinx.com"} -latest_file_version] 
  
   } 

