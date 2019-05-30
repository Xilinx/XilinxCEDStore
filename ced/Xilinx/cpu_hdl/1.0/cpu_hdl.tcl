proc createDesign {} {   

variable currentDir
add_files "[glob [file join $currentDir Sources *.v] ]" 
add_files [file join $currentDir Sources bftLib]
add_files [file join $currentDir Sources bft.vhdl]
add_files [file join $currentDir Sources mgt]
add_files [file join $currentDir Sources or1200]
add_files [file join $currentDir Sources usbf]
add_files [file join $currentDir Sources wb_conmax]
add_files -fileset sim_1 [file join $currentDir Sources tb cpu_tb.v]   

set arch_info [get_property ARCHITECTURE [get_property PART [current_project]]]
set_property library bftLib [get_files "[file join $currentDir Sources bftLib round_4.vhdl] [file join $currentDir Sources bftLib round_3.vhdl] [file join $currentDir Sources bftLib round_2.vhdl] [file join $currentDir Sources bftLib round_1.vhdl] [file join $currentDir Sources bftLib core_transform.vhdl] [file join $currentDir Sources bftLib bft_package.vhdl]" ]

set_property include_dirs "[file join $currentDir Sources]  [file join $currentDir Sources bftLib] [file join $currentDir Sources mgt] [file join $currentDir Sources or1200] [file join $currentDir Sources usbf] [file join $currentDir Sources wb_conmax]"  [current_fileset -simset ]

set_property file_type {Verilog Header} [get_files "[file join $currentDir Sources timescale.v]" ]
set_property IS_GLOBAL_INCLUDE true [get_files "[file join $currentDir Sources timescale.v]" ]

import_files -force

create_fileset -constrset constrs_2
import_files -fileset constrs_1 -force [file join $currentDir Sources $arch_info top.xdc]
import_files -fileset constrs_2 -force [file join $currentDir Sources $arch_info top_full.xdc]
set_property constrset constrs_2 [get_runs synth_1]
set_property constrset constrs_2 [get_runs impl_1]
set_property target_constrs_file [get_files top_full.xdc] [get_filesets constrs_2]
set_property target_constrs_file [get_files top.xdc] [get_filesets constrs_1]


update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
}
