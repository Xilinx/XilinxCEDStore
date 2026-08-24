set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]

source -notrace "$currentDir/run.tcl"
  
proc getSupportedParts {} {
     return [get_parts xcvp1202-vsva2785-2MHP-e-S]
}

proc getSupportedBoards {} {
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "CPM_Config" type "string" value "CPM5" value_list {"CPM5"} enabled true]
        lappend x [dict create name "CPM5_Preset" type "string" value "Gen5x4_Switch_Combination_1" value_list {"Gen5x4_Switch_Combination_1 Gen5x4_Switch_Combination_1__-__CPM5_as_Upstream_Port,_PCIe_Versal_as_Downstream_Port" "Gen5x4_Switch_Combination_2 Gen5x4_Switch_Combination_2__-__CPM5_as_Downstream_Port,_PCIe_Versal_as_Upstream_Port"} enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
        set left_panel [ced::add_panel -name left_panel -parent $page -designObject $designObj]
        set right_panel [ced::add_panel -name right_panel -parent $page -designObject $designObj]

	ced::add_param -name CPM_Config -parent $left_panel -designObject $designObj  -widget radioGroup 

        #set combinedPanel [ced::add_panel -name combinedPanel -parent $right_panel -designObject $designObj]
        ced::add_param -name CPM5_Preset  -parent $right_panel -designObject $designObj -widget radioGroup  

}

gui_updater {PROJECT_PARAM.BOARD_PART} {CPM_Config.VISIBLE CPM_Config.ENABLEMENT CPM_Config.VALUE} {
set CPM_Config.DISPLAYNAME "CIPS CPM Configurations"
set CPM_Config.ENABLEMENT false
set CPM_Config.VALUE CPM5
}

gui_updater {PROJECT_PARAM.BOARD_PART} {CPM5_Preset.VISIBLE CPM5_Preset.ENABLEMENT} {
set CPM_Config.DISPLAYNAME "CIPS CPM Configurations"
set CPM5_Preset.ENABLEMENT true
set CPM5_Preset.VISIBLE true
}

