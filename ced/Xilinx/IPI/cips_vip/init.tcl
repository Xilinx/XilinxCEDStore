
set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
#set_param ips.useCIPSv3 1
#set_param cips.enablePSVIPsimulation  1
source -notrace "$currentDir/run.tcl"
# *******************User defined proc (filter versal latest board parts )****************************
proc get_latest_board_parts {} {
set Versal_board [get_property BOARD_NAME [get_boards -filter {(DISPLAY_NAME =~"*Versal*" && VENDOR_NAME=="xilinx.com" )}]]
set Versal_board_unique [lsort -unique $Versal_board]
set Versal_boardparts ""



foreach v_part $Versal_board_unique {
lappend Versal_boardparts [get_board_parts *${v_part}:part0* -latest_file_version]
}
set V_board_unique [lsort -unique $Versal_boardparts]
return $V_board_unique
}
# ****************************************************************************************************

proc getSupportedParts {} {
	 return ""
}

proc getSupportedBoards {} {
  return [get_latest_board_parts]
   #return [get_board_parts -filter {PART_NAME=~"*xcvc*" && PART_NAME=~"*xcvm*" && VENDOR_NAME=="xilinx.com"} -latest_file_version]
}

