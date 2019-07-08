
set currentFile [file normalize [info script]]
set currentDir [file dirname $currentFile]

source -notrace "$currentDir/cpu_hdl.tcl"

proc getSupportedParts {} {
   return [list virtex7{xc7v585tffg1157-2} kintex7{xc7k70tfbg676-2} ] 
}

proc getSupportedBoards {} {
   return ""; 
}


