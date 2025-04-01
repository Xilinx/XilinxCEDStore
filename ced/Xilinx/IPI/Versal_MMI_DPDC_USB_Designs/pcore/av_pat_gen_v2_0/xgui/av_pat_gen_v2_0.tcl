# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]

  set BPC [ipgui::add_param $IPINST -name "BPC" -parent ${Page_0}]
  set_property tooltip {Bits Per Color} ${BPC}

  set PPC [ipgui::add_param $IPINST -name "PPC" -parent ${Page_0}]
  set_property tooltip {Bits Per Color} ${PPC}

  set Alpha [ipgui::add_param $IPINST -name "Alpha" -parent ${Page_0}]
  set_property tooltip {Alpha value added as another pixel component} ${Alpha}

  set SDP_EN [ipgui::add_param $IPINST -name "SDP_EN" -parent ${Page_0}]
  set_property tooltip {SDP Interface enable} ${SDP_EN}
 
  set PART_EN [ipgui::add_param $IPINST -name "PART_EN" -parent ${Page_0}]
  set_property tooltip {Enabling Telluride related changes} ${PART_EN}

  #set Mode [ipgui::add_param $IPINST -name "Mode" -parent ${Page_0}]
  #set_property tooltip {Coloromitry Mode} ${Mode}
}

proc update_MODELPARAM_VALUE.C_vid_out_BPC { MODELPARAM_VALUE.C_vid_out_BPC PARAM_VALUE.BPC } {
  set BPC [get_property value ${PARAM_VALUE.BPC}]
  set_property value $BPC ${MODELPARAM_VALUE.C_vid_out_BPC}
}

proc update_MODELPARAM_VALUE.C_vid_out_Alpha { MODELPARAM_VALUE.C_vid_out_Alpha PARAM_VALUE.Alpha } {
  set Alpha [get_property value ${PARAM_VALUE.Alpha}]
  set_property value $Alpha ${MODELPARAM_VALUE.C_vid_out_Alpha}
}

proc update_MODELPARAM_VALUE.PART { MODELPARAM_VALUE.PART PARAM_VALUE.PART_EN } {
  set PART_EN [get_property value ${PARAM_VALUE.PART_EN}]
  set_property value $PART_EN ${MODELPARAM_VALUE.PART}
}


proc update_MODELPARAM_VALUE.C_vid_out_PPC { MODELPARAM_VALUE.C_vid_out_PPC PARAM_VALUE.PPC } {
  set PPC [get_property value ${PARAM_VALUE.PPC}]
  set_property value $PPC ${MODELPARAM_VALUE.C_vid_out_PPC}
}

proc update_MODELPARAM_VALUE.C_vid_out_axi4s_TDATA_WIDTH { MODELPARAM_VALUE.C_vid_out_axi4s_TDATA_WIDTH PARAM_VALUE.BPC PARAM_VALUE.PPC PARAM_VALUE.Alpha} {
  set BPC [get_property value ${PARAM_VALUE.BPC}]
  set PPC [get_property value ${PARAM_VALUE.PPC}]
  set Alpha [get_property value ${PARAM_VALUE.Alpha}]
  # BPC * 3 Components * 4 Pixels per clock
  if {$Alpha == 0} {
    set Components_per_pixel 3
  } else {
    set Components_per_pixel 4
  }
  set_property value [expr {$BPC * $Components_per_pixel *$PPC}] ${MODELPARAM_VALUE.C_vid_out_axi4s_TDATA_WIDTH}
}
