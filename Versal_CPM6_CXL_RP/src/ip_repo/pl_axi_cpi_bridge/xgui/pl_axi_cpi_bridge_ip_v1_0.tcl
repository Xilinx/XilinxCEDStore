# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ARUSER_MEMINVNT_SUPP" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ARUSER_MEMINV_SUPP" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ARUSER_MEMSPECRD_SUPP" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXI_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BRDG_ID" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEBUG_EN_BCD" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEBUG_IF_EN" -parent ${Page_0}
  ipgui::add_param $IPINST -name "EMD_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "EN_ADR_PARITY" -parent ${Page_0}
  ipgui::add_param $IPINST -name "EN_BEN_PARITY" -parent ${Page_0}
  ipgui::add_param $IPINST -name "EN_CMD_PARITY" -parent ${Page_0}
  ipgui::add_param $IPINST -name "EN_DAT_PARITY" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RROB_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "USER_DEVLD_SUPP" -parent ${Page_0}
  ipgui::add_param $IPINST -name "USER_METAD_MODE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "USER_POISN_SUPP" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WROB_DEPTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.ARUSER_MEMINVNT_SUPP { PARAM_VALUE.ARUSER_MEMINVNT_SUPP } {
	# Procedure called to update ARUSER_MEMINVNT_SUPP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ARUSER_MEMINVNT_SUPP { PARAM_VALUE.ARUSER_MEMINVNT_SUPP } {
	# Procedure called to validate ARUSER_MEMINVNT_SUPP
	return true
}

proc update_PARAM_VALUE.ARUSER_MEMINV_SUPP { PARAM_VALUE.ARUSER_MEMINV_SUPP } {
	# Procedure called to update ARUSER_MEMINV_SUPP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ARUSER_MEMINV_SUPP { PARAM_VALUE.ARUSER_MEMINV_SUPP } {
	# Procedure called to validate ARUSER_MEMINV_SUPP
	return true
}

proc update_PARAM_VALUE.ARUSER_MEMSPECRD_SUPP { PARAM_VALUE.ARUSER_MEMSPECRD_SUPP } {
	# Procedure called to update ARUSER_MEMSPECRD_SUPP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ARUSER_MEMSPECRD_SUPP { PARAM_VALUE.ARUSER_MEMSPECRD_SUPP } {
	# Procedure called to validate ARUSER_MEMSPECRD_SUPP
	return true
}

proc update_PARAM_VALUE.AXI_ADDR_WIDTH { PARAM_VALUE.AXI_ADDR_WIDTH } {
	# Procedure called to update AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_ADDR_WIDTH { PARAM_VALUE.AXI_ADDR_WIDTH } {
	# Procedure called to validate AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.AXI_ID_WIDTH { PARAM_VALUE.AXI_ID_WIDTH } {
	# Procedure called to update AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_ID_WIDTH { PARAM_VALUE.AXI_ID_WIDTH } {
	# Procedure called to validate AXI_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.BRDG_ID { PARAM_VALUE.BRDG_ID } {
	# Procedure called to update BRDG_ID when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRDG_ID { PARAM_VALUE.BRDG_ID } {
	# Procedure called to validate BRDG_ID
	return true
}

proc update_PARAM_VALUE.DEBUG_EN_BCD { PARAM_VALUE.DEBUG_EN_BCD } {
	# Procedure called to update DEBUG_EN_BCD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEBUG_EN_BCD { PARAM_VALUE.DEBUG_EN_BCD } {
	# Procedure called to validate DEBUG_EN_BCD
	return true
}

proc update_PARAM_VALUE.DEBUG_IF_EN { PARAM_VALUE.DEBUG_IF_EN } {
	# Procedure called to update DEBUG_IF_EN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEBUG_IF_EN { PARAM_VALUE.DEBUG_IF_EN } {
	# Procedure called to validate DEBUG_IF_EN
	return true
}

proc update_PARAM_VALUE.EMD_BITS { PARAM_VALUE.EMD_BITS } {
	# Procedure called to update EMD_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.EMD_BITS { PARAM_VALUE.EMD_BITS } {
	# Procedure called to validate EMD_BITS
	return true
}

proc update_PARAM_VALUE.EN_ADR_PARITY { PARAM_VALUE.EN_ADR_PARITY } {
	# Procedure called to update EN_ADR_PARITY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.EN_ADR_PARITY { PARAM_VALUE.EN_ADR_PARITY } {
	# Procedure called to validate EN_ADR_PARITY
	return true
}

proc update_PARAM_VALUE.EN_BEN_PARITY { PARAM_VALUE.EN_BEN_PARITY } {
	# Procedure called to update EN_BEN_PARITY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.EN_BEN_PARITY { PARAM_VALUE.EN_BEN_PARITY } {
	# Procedure called to validate EN_BEN_PARITY
	return true
}

proc update_PARAM_VALUE.EN_CMD_PARITY { PARAM_VALUE.EN_CMD_PARITY } {
	# Procedure called to update EN_CMD_PARITY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.EN_CMD_PARITY { PARAM_VALUE.EN_CMD_PARITY } {
	# Procedure called to validate EN_CMD_PARITY
	return true
}

proc update_PARAM_VALUE.EN_DAT_PARITY { PARAM_VALUE.EN_DAT_PARITY } {
	# Procedure called to update EN_DAT_PARITY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.EN_DAT_PARITY { PARAM_VALUE.EN_DAT_PARITY } {
	# Procedure called to validate EN_DAT_PARITY
	return true
}

proc update_PARAM_VALUE.RROB_DEPTH { PARAM_VALUE.RROB_DEPTH } {
	# Procedure called to update RROB_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RROB_DEPTH { PARAM_VALUE.RROB_DEPTH } {
	# Procedure called to validate RROB_DEPTH
	return true
}

proc update_PARAM_VALUE.USER_DEVLD_SUPP { PARAM_VALUE.USER_DEVLD_SUPP } {
	# Procedure called to update USER_DEVLD_SUPP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USER_DEVLD_SUPP { PARAM_VALUE.USER_DEVLD_SUPP } {
	# Procedure called to validate USER_DEVLD_SUPP
	return true
}

proc update_PARAM_VALUE.USER_METAD_MODE { PARAM_VALUE.USER_METAD_MODE } {
	# Procedure called to update USER_METAD_MODE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USER_METAD_MODE { PARAM_VALUE.USER_METAD_MODE } {
	# Procedure called to validate USER_METAD_MODE
	return true
}

proc update_PARAM_VALUE.USER_POISN_SUPP { PARAM_VALUE.USER_POISN_SUPP } {
	# Procedure called to update USER_POISN_SUPP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USER_POISN_SUPP { PARAM_VALUE.USER_POISN_SUPP } {
	# Procedure called to validate USER_POISN_SUPP
	return true
}

proc update_PARAM_VALUE.WROB_DEPTH { PARAM_VALUE.WROB_DEPTH } {
	# Procedure called to update WROB_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WROB_DEPTH { PARAM_VALUE.WROB_DEPTH } {
	# Procedure called to validate WROB_DEPTH
	return true
}


proc update_MODELPARAM_VALUE.BRDG_ID { MODELPARAM_VALUE.BRDG_ID PARAM_VALUE.BRDG_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRDG_ID}] ${MODELPARAM_VALUE.BRDG_ID}
}

proc update_MODELPARAM_VALUE.DEBUG_IF_EN { MODELPARAM_VALUE.DEBUG_IF_EN PARAM_VALUE.DEBUG_IF_EN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEBUG_IF_EN}] ${MODELPARAM_VALUE.DEBUG_IF_EN}
}

proc update_MODELPARAM_VALUE.DEBUG_EN_BCD { MODELPARAM_VALUE.DEBUG_EN_BCD PARAM_VALUE.DEBUG_EN_BCD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEBUG_EN_BCD}] ${MODELPARAM_VALUE.DEBUG_EN_BCD}
}

proc update_MODELPARAM_VALUE.AXI_ADDR_WIDTH { MODELPARAM_VALUE.AXI_ADDR_WIDTH PARAM_VALUE.AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.USER_POISN_SUPP { MODELPARAM_VALUE.USER_POISN_SUPP PARAM_VALUE.USER_POISN_SUPP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USER_POISN_SUPP}] ${MODELPARAM_VALUE.USER_POISN_SUPP}
}

proc update_MODELPARAM_VALUE.USER_METAD_MODE { MODELPARAM_VALUE.USER_METAD_MODE PARAM_VALUE.USER_METAD_MODE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USER_METAD_MODE}] ${MODELPARAM_VALUE.USER_METAD_MODE}
}

proc update_MODELPARAM_VALUE.EMD_BITS { MODELPARAM_VALUE.EMD_BITS PARAM_VALUE.EMD_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EMD_BITS}] ${MODELPARAM_VALUE.EMD_BITS}
}

proc update_MODELPARAM_VALUE.USER_DEVLD_SUPP { MODELPARAM_VALUE.USER_DEVLD_SUPP PARAM_VALUE.USER_DEVLD_SUPP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USER_DEVLD_SUPP}] ${MODELPARAM_VALUE.USER_DEVLD_SUPP}
}

proc update_MODELPARAM_VALUE.ARUSER_MEMSPECRD_SUPP { MODELPARAM_VALUE.ARUSER_MEMSPECRD_SUPP PARAM_VALUE.ARUSER_MEMSPECRD_SUPP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ARUSER_MEMSPECRD_SUPP}] ${MODELPARAM_VALUE.ARUSER_MEMSPECRD_SUPP}
}

proc update_MODELPARAM_VALUE.ARUSER_MEMINV_SUPP { MODELPARAM_VALUE.ARUSER_MEMINV_SUPP PARAM_VALUE.ARUSER_MEMINV_SUPP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ARUSER_MEMINV_SUPP}] ${MODELPARAM_VALUE.ARUSER_MEMINV_SUPP}
}

proc update_MODELPARAM_VALUE.ARUSER_MEMINVNT_SUPP { MODELPARAM_VALUE.ARUSER_MEMINVNT_SUPP PARAM_VALUE.ARUSER_MEMINVNT_SUPP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ARUSER_MEMINVNT_SUPP}] ${MODELPARAM_VALUE.ARUSER_MEMINVNT_SUPP}
}

proc update_MODELPARAM_VALUE.EN_CMD_PARITY { MODELPARAM_VALUE.EN_CMD_PARITY PARAM_VALUE.EN_CMD_PARITY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EN_CMD_PARITY}] ${MODELPARAM_VALUE.EN_CMD_PARITY}
}

proc update_MODELPARAM_VALUE.EN_DAT_PARITY { MODELPARAM_VALUE.EN_DAT_PARITY PARAM_VALUE.EN_DAT_PARITY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EN_DAT_PARITY}] ${MODELPARAM_VALUE.EN_DAT_PARITY}
}

proc update_MODELPARAM_VALUE.EN_BEN_PARITY { MODELPARAM_VALUE.EN_BEN_PARITY PARAM_VALUE.EN_BEN_PARITY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EN_BEN_PARITY}] ${MODELPARAM_VALUE.EN_BEN_PARITY}
}

proc update_MODELPARAM_VALUE.EN_ADR_PARITY { MODELPARAM_VALUE.EN_ADR_PARITY PARAM_VALUE.EN_ADR_PARITY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EN_ADR_PARITY}] ${MODELPARAM_VALUE.EN_ADR_PARITY}
}

proc update_MODELPARAM_VALUE.WROB_DEPTH { MODELPARAM_VALUE.WROB_DEPTH PARAM_VALUE.WROB_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WROB_DEPTH}] ${MODELPARAM_VALUE.WROB_DEPTH}
}

proc update_MODELPARAM_VALUE.RROB_DEPTH { MODELPARAM_VALUE.RROB_DEPTH PARAM_VALUE.RROB_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RROB_DEPTH}] ${MODELPARAM_VALUE.RROB_DEPTH}
}

proc update_MODELPARAM_VALUE.AXI_ID_WIDTH { MODELPARAM_VALUE.AXI_ID_WIDTH PARAM_VALUE.AXI_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_ID_WIDTH}] ${MODELPARAM_VALUE.AXI_ID_WIDTH}
}

