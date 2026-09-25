set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source -notrace "$currentDir/run.tcl"

proc getSupportedParts {} {
}

proc getSupportedBoards {} {
  set V_board_unique [get_board_parts -filter {(BOARD_NAME =~"*vek385*" && VENDOR_NAME=="xilinx.com")||(BOARD_NAME =~"*vmk365*" && VENDOR_NAME=="xilinx.com")} -latest_file_version -quiet]
  return $V_board_unique
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
}
