set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source -notrace "$currentDir/create.tcl"

proc getSupportedParts {} {
}

proc getSupportedBoards {} {
    return [get_board_parts -latest_file_version]
}