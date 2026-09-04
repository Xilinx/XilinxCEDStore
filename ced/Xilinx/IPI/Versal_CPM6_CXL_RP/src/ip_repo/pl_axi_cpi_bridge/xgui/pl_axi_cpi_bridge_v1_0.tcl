# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  set Pg0 [ipgui::add_page $IPINST -name "Page 0"]
  ## FUNCTIONAL PARAMETERS
  ipgui::add_static_text $IPINST -parent ${Pg0} -name static_brdg_id -text "IMPORTANT: Bridge ID must be unique and match the proper interface when paired with the CXL Txn. Layer IP"
  ipgui::add_param $IPINST -parent ${Pg0} -name "BRDG_ID" -display_name "Bridge ID"
  ipgui::add_param $IPINST -parent ${Pg0} -name "AXI_ADDR_WIDTH" -display_name "AXI Addr. Width"
  ipgui::add_param $IPINST -parent ${Pg0} -name "AXI_ID_WIDTH" -display_name "AXI ID Width"
  ipgui::add_param $IPINST -parent ${Pg0} -name "RROB_DEPTH" -display_name "Read Re-order Buffer Depth (per ID)"
  ipgui::add_param $IPINST -parent ${Pg0} -name "WROB_DEPTH" -display_name "Write Re-order Buffer Depth (per ID)"
  ## DEBUG PARAMETERS
  set grp_debug [ipgui::add_group $IPINST -parent ${Pg0} -name grp_debug -display_name "Debug Support" -layout vertical]
  ipgui::add_param $IPINST -parent ${grp_debug} -name "DEBUG_IF_EN" -display_name "Debug Interface Enable" -widget comboBox
  ipgui::add_param $IPINST -parent ${grp_debug} -name "DEBUG_EN_BCD" -display_name "Add Debug Binary Coded Decimal" -widget checkBox
  ### AXI SIDEBAND PARAMETERS
  set grp_aximisc [ipgui::add_group $IPINST -parent ${Pg0} -name grp_aximisc -display_name "AXI Sideband / User Bit Support" -layout vertical]
  ipgui::add_static_text $IPINST -parent ${grp_aximisc} -name aruser_bits -text "Note: M2S Req Opcode Support -> ARUSER[1:0]=0(MemRd),=1(MemSpecRd),=2(MemInv),=3(MemInvNT)."
  ipgui::add_static_text $IPINST -parent ${grp_aximisc} -name devload_bits -text "Note: RUSER[1:0]/BUSER[1:0]=DevLoad."
  ipgui::add_static_text $IPINST -parent ${grp_aximisc} -name poison_bits -text "Note: Downstream Poison transmitted on WUSER[0] and Upstream Poison returns AXI RRESP=SLVERR."
  ipgui::add_static_text $IPINST -parent ${grp_aximisc} -name metad_bits -text "Note: When 2 bit MetaData is selected, WUSER[2:1] and ARUSER[4:3] corresponds to Downstream MetaValue. For M2S Reqs, ARUSER[2] is a flag bit to send MetaField=MS0. For Upstream, RUSER[3:2]=MetaValue."
  ipgui::add_static_text $IPINST -parent ${grp_aximisc} -name metad_bits -text "Note: When Extended MetaData is selected, WUSER[1+:EMD_BITS] and RUSER[4+:EMD_BITS] corresponds to Ext. MetaValue."
  ipgui::add_param $IPINST -parent ${grp_aximisc} -name "ARUSER_MEMINVNT_SUPP" -display_name "M2S Req MemInvNT Opcode Support" -widget checkBox
  ipgui::add_param $IPINST -parent ${grp_aximisc} -name "ARUSER_MEMINV_SUPP" -display_name "M2S Req MemInv Opcode Support" -widget checkBox
  ipgui::add_param $IPINST -parent ${grp_aximisc} -name "ARUSER_MEMSPECRD_SUPP" -display_name "M2S Req MemSpecRd Opcode Support" -widget checkBox
  ipgui::add_param $IPINST -parent ${grp_aximisc} -name "USER_DEVLD_SUPP" -display_name "S2M DevLoad Support" -widget checkBox
  ipgui::add_param $IPINST -parent ${grp_aximisc} -name "USER_POISN_SUPP" -display_name "M2S RwD/S2M DRS Poison Support" -widget checkBox
  ipgui::add_param $IPINST -parent ${grp_aximisc} -name "USER_METAD_MODE" -display_name "MetaData Support" -widget comboBox
  ipgui::add_param $IPINST -parent ${grp_aximisc} -name "EMD_BITS" -display_name "EMD Bits"
  # EN_ADR_PARITY/EN_BEN_PARITY/EN_CMD_PARITY/EN_DAT_PARITY remain real,
  # settable parameters (e.g. via CONFIG.EN_CMD_PARITY on the BD cell) but
  # are hidden from the customization GUI.
  set en_adr_parity [ipgui::add_param $IPINST -parent ${Pg0} -name "EN_ADR_PARITY"]
  set_property visible false $en_adr_parity
  set en_ben_parity [ipgui::add_param $IPINST -parent ${Pg0} -name "EN_BEN_PARITY"]
  set_property visible false $en_ben_parity
  set en_cmd_parity [ipgui::add_param $IPINST -parent ${Pg0} -name "EN_CMD_PARITY"]
  set_property visible false $en_cmd_parity
  set en_dat_parity [ipgui::add_param $IPINST -parent ${Pg0} -name "EN_DAT_PARITY"]
  set_property visible false $en_dat_parity
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
	set value [get_property value ${PARAM_VALUE.AXI_ADDR_WIDTH}]
	if {![string is integer -strict $value] || $value < 32 || $value > 48} {
		set_property errmsg "AXI Addr. Width must be an integer between 32 and 48." ${PARAM_VALUE.AXI_ADDR_WIDTH}
		return false
	}
	return true
}

proc update_PARAM_VALUE.AXI_ID_WIDTH { PARAM_VALUE.AXI_ID_WIDTH } {
	# Procedure called to update AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_ID_WIDTH { PARAM_VALUE.AXI_ID_WIDTH } {
	# Procedure called to validate AXI_ID_WIDTH
	set value [get_property value ${PARAM_VALUE.AXI_ID_WIDTH}]
	if {![string is integer -strict $value] || $value < 1 || $value > 4} {
		set_property errmsg "AXI ID Width must be an integer between 1 and 4 (AXI_IDS_SUPP supports up to 16 outstanding IDs, i.e. \$clog2(16)=4 bits)." ${PARAM_VALUE.AXI_ID_WIDTH}
		return false
	}
	return true
}

proc update_PARAM_VALUE.BRDG_ID { PARAM_VALUE.BRDG_ID } {
	# Procedure called to update BRDG_ID when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRDG_ID { PARAM_VALUE.BRDG_ID } {
	# Procedure called to validate BRDG_ID
	set value [get_property value ${PARAM_VALUE.BRDG_ID}]
	if {![string is integer -strict $value] || $value < 0 || $value > 3} {
		set_property errmsg "Bridge ID must be an integer between 0 and 3 (BRDG_ID is a 2-bit field)." ${PARAM_VALUE.BRDG_ID}
		return false
	}
	return true
}

proc update_PARAM_VALUE.DEBUG_EN_BCD { PARAM_VALUE.DEBUG_EN_BCD PARAM_VALUE.DEBUG_IF_EN } {
	# Procedure called to update DEBUG_EN_BCD when any of the dependent parameters in the arguments change
	# Gray out Debug En Bcd until Debug Interface Enable is not None (0).
	set debug_if_en [get_property value ${PARAM_VALUE.DEBUG_IF_EN}]
	if {$debug_if_en == 0} {
		set_property enabled false ${PARAM_VALUE.DEBUG_EN_BCD}
	} else {
		set_property enabled true ${PARAM_VALUE.DEBUG_EN_BCD}
	}
}

proc validate_PARAM_VALUE.DEBUG_EN_BCD { PARAM_VALUE.DEBUG_EN_BCD } {
	# Procedure called to validate DEBUG_EN_BCD
	return true
}

proc update_PARAM_VALUE.DEBUG_IF_EN { PARAM_VALUE.DEBUG_IF_EN } {
	# Procedure called to update DEBUG_IF_EN when any of the dependent parameters in the arguments change
	# Presents DEBUG_IF_EN as a None/GPIO/AXI-Lite/Both combo box while the
	# underlying value stays the [1]=AXI-L,[0]=GPIO bit-encoded 0-3 the HDL expects.
	set value [get_property value ${PARAM_VALUE.DEBUG_IF_EN}]
	set_property -dict [dict create \
		enabled true \
		value $value \
		range "0,1,2,3" \
		range_labels [join [dict create 0 {None} 1 {GPIO} 2 {AXI-Lite} 3 {Both}] ,] \
	] ${PARAM_VALUE.DEBUG_IF_EN}
}

proc validate_PARAM_VALUE.DEBUG_IF_EN { PARAM_VALUE.DEBUG_IF_EN } {
	# Procedure called to validate DEBUG_IF_EN
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
	set value [get_property value ${PARAM_VALUE.RROB_DEPTH}]
	if {![string is integer -strict $value] || $value < 1 || $value > 256 || ($value & ($value - 1)) != 0} {
		set_property errmsg "Read Re-order Buffer Depth must be a power of 2 between 1 and 256 (1,2,4,8,...,256)." ${PARAM_VALUE.RROB_DEPTH}
		return false
	}
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

proc update_PARAM_VALUE.EMD_BITS { PARAM_VALUE.EMD_BITS PARAM_VALUE.USER_METAD_MODE } {
	# Procedure called to update EMD_BITS when any of the dependent parameters in the arguments change
	# EMD Bits is only meaningful when MetaData Support is "Extended MetaData" (2).
	set metad_mode [get_property value ${PARAM_VALUE.USER_METAD_MODE}]
	if {$metad_mode == 2} {
		set_property enabled true ${PARAM_VALUE.EMD_BITS}
	} else {
		set_property enabled false ${PARAM_VALUE.EMD_BITS}
	}
}

proc validate_PARAM_VALUE.EMD_BITS { PARAM_VALUE.EMD_BITS } {
	# Procedure called to validate EMD_BITS
	set value [get_property value ${PARAM_VALUE.EMD_BITS}]
	if {![string is integer -strict $value] || $value < 1 || $value > 32} {
		set_property errmsg "EMD Bits must be an integer between 1 and 32." ${PARAM_VALUE.EMD_BITS}
		return false
	}
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
	set value [get_property value ${PARAM_VALUE.WROB_DEPTH}]
	if {![string is integer -strict $value] || $value < 1 || $value > 256 || ($value & ($value - 1)) != 0} {
		set_property errmsg "Write Re-order Buffer Depth must be a power of 2 between 1 and 256 (1,2,4,8,...,256)." ${PARAM_VALUE.WROB_DEPTH}
		return false
	}
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

