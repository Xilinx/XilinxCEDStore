# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]

  set BPC [ipgui::add_param $IPINST -name "BPC" -parent ${Page_0}]
  set_property tooltip {Bits Per Color} ${BPC}

  set PPC [ipgui::add_param $IPINST -name "PPC" -parent ${Page_0}]
  set_property tooltip {Bits Per Color} ${PPC}

  #set Mode [ipgui::add_param $IPINST -name "Mode" -parent ${Page_0}]
  #set_property tooltip {Coloromitry Mode} ${Mode}
}

proc update_MODELPARAM_VALUE.C_vid_out_BPC { MODELPARAM_VALUE.C_vid_out_BPC PARAM_VALUE.BPC } {
  set BPC [get_property value ${PARAM_VALUE.BPC}]
  set_property value $BPC ${MODELPARAM_VALUE.C_vid_out_BPC}
}

proc update_MODELPARAM_VALUE.C_vid_out_PPC { MODELPARAM_VALUE.C_vid_out_PPC PARAM_VALUE.PPC } {
  set PPC [get_property value ${PARAM_VALUE.PPC}]
  set_property value $PPC ${MODELPARAM_VALUE.C_vid_out_PPC}
}

proc update_MODELPARAM_VALUE.C_vid_out_axi4s_TDATA_WIDTH { MODELPARAM_VALUE.C_vid_out_axi4s_TDATA_WIDTH PARAM_VALUE.BPC PARAM_VALUE.PPC} {
  set BPC [get_property value ${PARAM_VALUE.BPC}]
  set PPC [get_property value ${PARAM_VALUE.PPC}]
  # BPC * 3 Components * 4 Pixels per clock
  set_property value [expr {$BPC * 3 *$PPC}] ${MODELPARAM_VALUE.C_vid_out_axi4s_TDATA_WIDTH}
}


proc update_PARAM_VALUE.BPC {IPINST PARAM_VALUE.BPC } {
}

proc update_PARAM_VALUE.PPC {IPINST PARAM_VALUE.PPC } {
}




