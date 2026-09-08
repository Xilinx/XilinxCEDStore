# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "AXI_ADDRESS_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXI_AXIL_SYNC" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXI_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "EXTERNAL_START_EN" -parent ${Page_0}


}

proc update_PARAM_VALUE.AXI_ADDRESS_WIDTH { PARAM_VALUE.AXI_ADDRESS_WIDTH } {
	# Procedure called to update AXI_ADDRESS_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_ADDRESS_WIDTH { PARAM_VALUE.AXI_ADDRESS_WIDTH } {
	# Procedure called to validate AXI_ADDRESS_WIDTH
	return true
}

proc update_PARAM_VALUE.AXI_AXIL_SYNC { PARAM_VALUE.AXI_AXIL_SYNC } {
	# Procedure called to update AXI_AXIL_SYNC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_AXIL_SYNC { PARAM_VALUE.AXI_AXIL_SYNC } {
	# Procedure called to validate AXI_AXIL_SYNC
	return true
}

proc update_PARAM_VALUE.AXI_ID_WIDTH { PARAM_VALUE.AXI_ID_WIDTH } {
	# Procedure called to update AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_ID_WIDTH { PARAM_VALUE.AXI_ID_WIDTH } {
	# Procedure called to validate AXI_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.EXTERNAL_START_EN { PARAM_VALUE.EXTERNAL_START_EN } {
	# Procedure called to update EXTERNAL_START_EN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.EXTERNAL_START_EN { PARAM_VALUE.EXTERNAL_START_EN } {
	# Procedure called to validate EXTERNAL_START_EN
	return true
}


proc update_MODELPARAM_VALUE.AXI_ADDRESS_WIDTH { MODELPARAM_VALUE.AXI_ADDRESS_WIDTH PARAM_VALUE.AXI_ADDRESS_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_ADDRESS_WIDTH}] ${MODELPARAM_VALUE.AXI_ADDRESS_WIDTH}
}

proc update_MODELPARAM_VALUE.AXI_ID_WIDTH { MODELPARAM_VALUE.AXI_ID_WIDTH PARAM_VALUE.AXI_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_ID_WIDTH}] ${MODELPARAM_VALUE.AXI_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.AXI_AXIL_SYNC { MODELPARAM_VALUE.AXI_AXIL_SYNC PARAM_VALUE.AXI_AXIL_SYNC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_AXIL_SYNC}] ${MODELPARAM_VALUE.AXI_AXIL_SYNC}
}

proc update_MODELPARAM_VALUE.EXTERNAL_START_EN { MODELPARAM_VALUE.EXTERNAL_START_EN PARAM_VALUE.EXTERNAL_START_EN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EXTERNAL_START_EN}] ${MODELPARAM_VALUE.EXTERNAL_START_EN}
}

