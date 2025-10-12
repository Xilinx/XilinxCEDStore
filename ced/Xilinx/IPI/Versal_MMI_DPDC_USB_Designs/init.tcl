set currentFile [file normalize [info script]]
variable currentDir [file dirname $currentFile]
source -notrace "$currentDir/run.tcl"

proc getSupportedParts {} {
}

proc getSupportedBoards {} {
        set V_board_unique [get_board_parts -filter {(BOARD_NAME =~"*vek385*" && VENDOR_NAME=="xilinx.com")} -latest_file_version]
        return $V_board_unique
}

proc addOptions {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	lappend x [dict create name "MMI_Config" type "string" value "DC_Functional" value_list {"DC_Functional" "DC_Bypass" "USB"} enabled true]
    lappend x [dict create name "DPDC_Presentation_Mode" type "string" value "Non_Live" value_list {"Non_Live" "Mixed" "Live"} enabled true]
    lappend x [dict create name "Video_Interface" type "string" value "Native" value_list {"Native" "AXI_Stream"} enabled true]
    lappend x [dict create name "MST_ENABLE" type "bool" value "false" enabled true]
    lappend x [dict create name "Video_Streams" type "string" value "2" value_list {"2 2_Streams" "4 4_Streams"} enabled true]
	return $x
}

proc addGUILayout {DESIGNOBJ PROJECT_PARAM.BOARD_PART} {
	set designObj $DESIGNOBJ
	#place to define GUI layout for options
	set page [ced::add_page -name "Page1" -display_name "Configuration" -designObject $designObj -layout vertical]	
        set left_panel [ced::add_panel -name left_panel -parent $page -designObject $designObj]
        set right_panel [ced::add_panel -name right_panel -parent $page -designObject $designObj]

	ced::add_param -name MMI_Config -display_name "MMI Configuration" -parent $left_panel -designObject $designObj -widget comboBox

        #set combinedPanel [ced::add_panel -name combinedPanel -parent $right_panel -designObject $designObj]
        ced::add_param -name DPDC_Presentation_Mode -display_name "DPDC presentation mode" -parent $right_panel -designObject $designObj -widget comboBox
        ced::add_param -name Video_Interface -display_name "Video Interface Mode" -parent $right_panel -designObject $designObj -widget comboBox
        ced::add_param -name MST_ENABLE -display_name "Multi Video Stream Enable" -parent $right_panel -designObject $designObj -widget checkBox
        ced::add_param -name Video_Streams -display_name "Number of Video Streams" -parent $right_panel -designObject $designObj -widget comboBox
	set imageVar [ced::add_image -name Image -parent $page -designObject $designObj -width 800 -height 350 -layout vertical]
}

gui_updater {PROJECT_PARAM.BOARD_PART} {MMI_Config.VISIBLE MMI_Config.ENABLEMENT} {
set MMI_Config.ENABLEMENT true
set MMI_Config.VISIBLE true
}

gui_updater {PROJECT_PARAM.BOARD_PART MMI_Config.VALUE DPDC_Presentation_Mode.VALUE Video_Streams.VALUE Video_Interface.VALUE MST_ENABLE.VALUE} {DPDC_Presentation_Mode.VISIBLE Image.IMAGE_PATH} {
if { ${MMI_Config.VALUE} == "USB" } {
set DPDC_Config.DISPLAYNAME "MMI DC Configurations"
set DPDC_Presentation_Mode.VISIBLE false
set Image.IMAGE_PATH "usb.png"
} elseif { ${MMI_Config.VALUE} == "DC_Bypass" } {
set DPDC_Config.DISPLAYNAME "MMI DC Configurations"
set DPDC_Presentation_Mode.VISIBLE false
if { ${MST_ENABLE.VALUE} == "true" } {
if { ${Video_Streams.VALUE} == 2 } {
set Image.IMAGE_PATH "bypass2.png"
} else {
set Image.IMAGE_PATH "bypass4.png"
} 
} else {
set Image.IMAGE_PATH "bypass1.png"
}
} else {
set DPDC_Config.DISPLAYNAME "MMI DC Configurations"
set DPDC_Presentation_Mode.VISIBLE true
if { ${DPDC_Presentation_Mode.VALUE} == "Non_Live" } {
set Image.IMAGE_PATH "Non_Live.png"
} elseif { ${DPDC_Presentation_Mode.VALUE} == "Live" && ${Video_Interface.VALUE} == "Native" } {
set Image.IMAGE_PATH "Live.png"
} elseif { ${DPDC_Presentation_Mode.VALUE} == "Live" && ${Video_Interface.VALUE} == "AXI_Stream" } {
set Image.IMAGE_PATH "live_st.png"
} elseif { ${DPDC_Presentation_Mode.VALUE} == "Mixed" } {
set Image.IMAGE_PATH "Mixed.png"
}
}
}

gui_updater {PROJECT_PARAM.BOARD_PART MMI_Config.VALUE DPDC_Presentation_Mode.VALUE} {Video_Interface.VISIBLE Video_Interface.VALUE Image.IMAGE_PATH} {
if { ${MMI_Config.VALUE} == "DC_Functional" && ${DPDC_Presentation_Mode.VALUE} == "Live" } {
set Video_Interface.VISIBLE true
} else {
set Video_Interface.VALUE "Native"
set Video_Interface.VISIBLE false
}
}

gui_updater {PROJECT_PARAM.BOARD_PART MMI_Config.VALUE} {MST_ENABLE.VALUE MST_ENABLE.VISIBLE} {
if { ${MMI_Config.VALUE} == "DC_Bypass" } {
set MST_ENABLE.VISIBLE true
} else {
set MST_ENABLE.VALUE false
set MST_ENABLE.VISIBLE false
}
}

gui_updater {PROJECT_PARAM.BOARD_PART MMI_Config.VALUE MST_ENABLE.VALUE} {Video_Streams.VISIBLE} {
if { ${MMI_Config.VALUE} == "DC_Bypass" && ${MST_ENABLE.VALUE} == "true" } {
set Video_Streams.VISIBLE true
} else {
set Video_Streams.VISIBLE false
}
}