set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]

source -notrace "$currentDir/run.tcl"
  
proc getSupportedParts {} {
}

proc getSupportedBoards {} {
  return [get_board_parts -filter {(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com" ) || (BOARD_NAME =~"*vpk120*" && VENDOR_NAME=="xilinx.com" )}  -latest_file_version]
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "CPM_Config" type "string" value "CPM4" value_list {"CPM4" "CPM5"} enabled true]
        lappend x [dict create name "CPM5_Preset" type "string" value "CPM5_PCIe_Controller0_Gen4x8_RootPort_Design" value_list {CPM5_PCIe_Controller0_Gen4x8_RootPort_Design CPM5_PCIe_Controller1_Gen4x8_RootPort_Design} enabled true]
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
if { [regexp "vck190" ${PROJECT_PARAM.BOARD_PART}]} {
#set CPM_Config.VISIBLE true
set CPM_Config.ENABLEMENT false
set CPM_Config.VALUE CPM4
} else {
#set CPM_Config.VISIBLE false
set CPM_Config.ENABLEMENT false
set CPM_Config.VALUE CPM5
}
}

gui_updater {PROJECT_PARAM.BOARD_PART} {CPM5_Preset.VISIBLE CPM5_Preset.ENABLEMENT} {
set CPM_Config.DISPLAYNAME "CIPS CPM Configurations"
if { [regexp "vck190" ${PROJECT_PARAM.BOARD_PART}]} {
set CPM5_Preset.ENABLEMENT false
set CPM5_Preset.VISIBLE false
} else {
set CPM5_Preset.ENABLEMENT true
set CPM5_Preset.VISIBLE true
}
}

