proc createDesign {} {   

variable currentDir
set_property design_mode GateLvl [current_fileset]
import_files [file join $currentDir Sources top.edif]
import_files -fileset sim_1 [file join $currentDir Sources tb cpu_tb.v]   

set arch_info [get_property ARCHITECTURE [get_property PART [current_project]]]

create_fileset -constrset constrs_2
import_files -fileset constrs_1 -force [file join $currentDir Sources $arch_info top.xdc]
import_files -fileset constrs_2 -force [file join $currentDir Sources $arch_info top_full.xdc]
set_property constrset constrs_2 [get_runs impl_1]
set_property target_constrs_file [get_files top_full.xdc] [get_filesets constrs_2]
set_property target_constrs_file [get_files top.xdc] [get_filesets constrs_1]
set_property top test [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
}
