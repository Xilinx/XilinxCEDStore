set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]

source -notrace "$currentDir/run.tcl"
  
proc getSupportedParts {} {
}

proc getSupportedBoards {} {
  return [get_board_parts -filter {(BOARD_NAME =~"*vck190*" && VENDOR_NAME=="xilinx.com" ) || (BOARD_NAME =~"*vpk120*" && VENDOR_NAME=="xilinx.com" )}  -latest_file_version]
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "Preset" type "string" value "CPM4" value_list {"CPM4" "CPM5"} enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
	ced::add_param -name Preset -parent $page -designObject $designObj  -widget radioGroup 
    set imageVar [ced::add_image -name Image -parent $page -designObject $designObj -width 500 -height 300 -layout vertical]
}

gui_updater {PROJECT_PARAM.BOARD_PART} {Preset.VISIBLE Preset.ENABLEMENT Preset.VALUE} {
set Preset.DISPLAYNAME "CIPS CPM Configurations"
if { [regexp "vck190" ${PROJECT_PARAM.BOARD_PART}]} {
#set Preset.VISIBLE true
set Preset.ENABLEMENT false
set Preset.VALUE CPM4
} else {
#set Preset.VISIBLE false
set Preset.ENABLEMENT false
set Preset.VALUE CPM5
}
}


