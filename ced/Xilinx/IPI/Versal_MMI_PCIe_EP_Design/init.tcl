set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source -notrace "$currentDir/run.tcl"

proc getSupportedParts {} {
  return [get_parts -filter {NAME =~ xc2ve3858-*-2* || NAME =~ xc2ve3558-*-2* || NAME =~ xc2vm3858-*-2* || NAME =~ xc2vm3558-*-2* || NAME =~ xc2ve3804-*-2* || NAME =~ xc2ve3504-*-2* || NAME =~ xc10T21-*-2*}]
}

proc getSupportedBoards {} {
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
}
