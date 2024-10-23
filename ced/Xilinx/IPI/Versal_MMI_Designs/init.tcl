set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source -notrace "$currentDir/run.tcl"

proc getSupportedParts {} {
  return [get_parts xc2ve3858-ssva2112*]
}

proc getSupportedBoards {} {
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "MMI_Config" type "string" value "DC_Functional" value_list {"DC_Functional" "USB"} enabled true]
        lappend x [dict create name "DPDC_Presentation_Mode" type "string" value "Non_Live" value_list {"Non_Live Non_Live__-__Both(Two)_Video_Stream_are_from_DDR" "Mixed Mixed__-__One_Video_Stream_from_DDR_,_Second_Video_Stream_from_PL" "Live Live__-__Both(Two)_Video_Streams_from_PL"} enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
        set left_panel [ced::add_panel -name left_panel -parent $page -designObject $designObj]
        set right_panel [ced::add_panel -name right_panel -parent $page -designObject $designObj]

	ced::add_param -name MMI_Config -parent $left_panel -designObject $designObj  -widget comboBox

        #set combinedPanel [ced::add_panel -name combinedPanel -parent $right_panel -designObject $designObj]
        ced::add_param -name DPDC_Presentation_Mode -parent $right_panel -designObject $designObj -widget comboBox
	set imageVar [ced::add_image -name Image -parent $page -designObject $designObj -width 800 -height 350 -layout vertical]
}

gui_updater {PROJECT_PARAM.BOARD_PART} {MMI_Config.VISIBLE MMI_Config.ENABLEMENT} {
set MMI_Config.DISPLAYNAME "Versal MMI Configurations"
set MMI_Config.ENABLEMENT true
}

gui_updater {PROJECT_PARAM.BOARD_PART MMI_Config.VALUE DPDC_Presentation_Mode.VALUE} {DPDC_Presentation_Mode.VISIBLE DPDC_Presentation_Mode.ENABLEMENT Image.IMAGE_PATH} {
if { ${MMI_Config.VALUE} == "USB" } {
set DPDC_Config.DISPLAYNAME "MMI DC Configurations"
set DPDC_Presentation_Mode.ENABLEMENT false
set DPDC_Presentation_Mode.VISIBLE true
set Image.IMAGE_PATH "usb.png"
} else {
set DPDC_Config.DISPLAYNAME "MMI DC Configurations"
set DPDC_Presentation_Mode.ENABLEMENT true
set DPDC_Presentation_Mode.VISIBLE true
if { ${DPDC_Presentation_Mode.VALUE} == "Non_Live" } {
set Image.IMAGE_PATH "Non_Live.png"
} elseif { ${DPDC_Presentation_Mode.VALUE} == "Live" } {
set Image.IMAGE_PATH "Live.png"
} elseif { ${DPDC_Presentation_Mode.VALUE} == "Mixed" } {
set Image.IMAGE_PATH "Mixed.png"
}
}
}
