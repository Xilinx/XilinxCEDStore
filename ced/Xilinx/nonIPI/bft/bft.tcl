proc createDesign {} {   

variable currentDir
#set_property target_language VHDL [current_project]
#set_property "simulator_language" "Mixed" [current_project]

##################################################################
# DESIGN PROCs
##################################################################

# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
add_files "[file join $currentDir Sources FifoBuffer.v] [file join $currentDir Sources async_fifo.v]  [file join $currentDir Sources bft.vhdl]"
add_files -fileset sim_1 [file join $currentDir Sources bft_tb.v]   
add_files [file join $currentDir Sources bftLib]

set arch_info [get_property ARCHITECTURE [get_property PART [current_project]]]
set part_info [get_property PART [current_project]]
set_property library bftLib [get_files "[file join $currentDir Sources bftLib round_4.vhdl] [file join $currentDir Sources bftLib round_3.vhdl] [file join $currentDir Sources bftLib round_2.vhdl] [file join $currentDir Sources bftLib round_1.vhdl] [file join $currentDir Sources bftLib core_transform.vhdl] [file join $currentDir Sources bftLib bft_package.vhdl]" ]
import_files -force
import_files -fileset constrs_1 -force -norecurse [file join $currentDir Sources $arch_info $part_info bft_full.xdc]

}
