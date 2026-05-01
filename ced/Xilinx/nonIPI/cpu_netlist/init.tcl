
set currentFile [file normalize [info script]]
set currentDir [file dirname $currentFile]

source -notrace "$currentDir/cpu_netlist.tcl"

proc getSupportedParts {} {
   return [list kintex7{xc7k70tfbg676-2} ] 
}

proc getSupportedBoards {} {
   return ""; 
}

