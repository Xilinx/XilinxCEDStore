# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  # C_CXL_HDM_COUNT and C_MEM0_CPI_CXL_MODE are intentionally hidden here -
  # both are threaded through as parameters (cxl_mem_wrapper.v -> cxl_mem.sv
  # -> cxl_axi_mapper.sv / cxl_mem_decode.sv / cxl_mem_encode.sv) but never
  # actually consumed by any conditional/generate logic in the RTL, so their
  # value has no effect on functionality. Still fully settable via
  # CONFIG.C_CXL_HDM_COUNT / CONFIG.C_MEM0_CPI_CXL_MODE in Tcl.
  ipgui::add_param $IPINST -name "C_DDR_BASE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M0_AXI_HDM_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M0_AXI_HDM_HIGHADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_MEM0_CPI_A2F_MAX_CREDIT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_MEM0_CPI_F2A_MAX_CREDIT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_NUM_PA" -parent ${Page_0}


}

proc update_PARAM_VALUE.C_CXL_HDM_COUNT { PARAM_VALUE.C_CXL_HDM_COUNT } {
	# Procedure called to update C_CXL_HDM_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_CXL_HDM_COUNT { PARAM_VALUE.C_CXL_HDM_COUNT } {
	# Procedure called to validate C_CXL_HDM_COUNT
	return true
}

proc update_PARAM_VALUE.C_DDR_BASE { PARAM_VALUE.C_DDR_BASE } {
	# Procedure called to update C_DDR_BASE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_DDR_BASE { PARAM_VALUE.C_DDR_BASE } {
	# Procedure called to validate C_DDR_BASE
	return true
}

proc update_PARAM_VALUE.C_M0_AXI_HDM_BASEADDR { PARAM_VALUE.C_M0_AXI_HDM_BASEADDR } {
	# Procedure called to update C_M0_AXI_HDM_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M0_AXI_HDM_BASEADDR { PARAM_VALUE.C_M0_AXI_HDM_BASEADDR } {
	# Procedure called to validate C_M0_AXI_HDM_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_M0_AXI_HDM_HIGHADDR { PARAM_VALUE.C_M0_AXI_HDM_HIGHADDR } {
	# Procedure called to update C_M0_AXI_HDM_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M0_AXI_HDM_HIGHADDR { PARAM_VALUE.C_M0_AXI_HDM_HIGHADDR } {
	# Procedure called to validate C_M0_AXI_HDM_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_MEM0_CPI_A2F_MAX_CREDIT { PARAM_VALUE.C_MEM0_CPI_A2F_MAX_CREDIT } {
	# Procedure called to update C_MEM0_CPI_A2F_MAX_CREDIT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_MEM0_CPI_A2F_MAX_CREDIT { PARAM_VALUE.C_MEM0_CPI_A2F_MAX_CREDIT } {
	# Procedure called to validate C_MEM0_CPI_A2F_MAX_CREDIT
	return true
}

proc update_PARAM_VALUE.C_MEM0_CPI_CXL_MODE { PARAM_VALUE.C_MEM0_CPI_CXL_MODE } {
	# Procedure called to update C_MEM0_CPI_CXL_MODE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_MEM0_CPI_CXL_MODE { PARAM_VALUE.C_MEM0_CPI_CXL_MODE } {
	# Procedure called to validate C_MEM0_CPI_CXL_MODE
	return true
}

proc update_PARAM_VALUE.C_MEM0_CPI_F2A_MAX_CREDIT { PARAM_VALUE.C_MEM0_CPI_F2A_MAX_CREDIT } {
	# Procedure called to update C_MEM0_CPI_F2A_MAX_CREDIT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_MEM0_CPI_F2A_MAX_CREDIT { PARAM_VALUE.C_MEM0_CPI_F2A_MAX_CREDIT } {
	# Procedure called to validate C_MEM0_CPI_F2A_MAX_CREDIT
	return true
}

proc update_PARAM_VALUE.C_NUM_PA { PARAM_VALUE.C_NUM_PA } {
	# Procedure called to update C_NUM_PA when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_NUM_PA { PARAM_VALUE.C_NUM_PA } {
	# Procedure called to validate C_NUM_PA
	return true
}


proc update_MODELPARAM_VALUE.C_NUM_PA { MODELPARAM_VALUE.C_NUM_PA PARAM_VALUE.C_NUM_PA } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_NUM_PA}] ${MODELPARAM_VALUE.C_NUM_PA}
}

proc update_MODELPARAM_VALUE.C_DDR_BASE { MODELPARAM_VALUE.C_DDR_BASE PARAM_VALUE.C_DDR_BASE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_DDR_BASE}] ${MODELPARAM_VALUE.C_DDR_BASE}
}

proc update_MODELPARAM_VALUE.C_EN_DEBUG { MODELPARAM_VALUE.C_EN_DEBUG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_EN_DEBUG". Setting updated value from the model parameter.
set_property value 0 ${MODELPARAM_VALUE.C_EN_DEBUG}
}

proc update_MODELPARAM_VALUE.C_CVA_MODE { MODELPARAM_VALUE.C_CVA_MODE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_CVA_MODE". Setting updated value from the model parameter.
set_property value 0 ${MODELPARAM_VALUE.C_CVA_MODE}
}

proc update_MODELPARAM_VALUE.C_MEM0_CPI_A2F_DATAHDRSEP { MODELPARAM_VALUE.C_MEM0_CPI_A2F_DATAHDRSEP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_MEM0_CPI_A2F_DATAHDRSEP". Setting updated value from the model parameter.
set_property value 0 ${MODELPARAM_VALUE.C_MEM0_CPI_A2F_DATAHDRSEP}
}

proc update_MODELPARAM_VALUE.C_MEM0_CPI_F2A_DATAHDRSEP { MODELPARAM_VALUE.C_MEM0_CPI_F2A_DATAHDRSEP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_MEM0_CPI_F2A_DATAHDRSEP". Setting updated value from the model parameter.
set_property value 0 ${MODELPARAM_VALUE.C_MEM0_CPI_F2A_DATAHDRSEP}
}

proc update_MODELPARAM_VALUE.C_MEM0_CPI_AGENTBLOCKING { MODELPARAM_VALUE.C_MEM0_CPI_AGENTBLOCKING } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_MEM0_CPI_AGENTBLOCKING". Setting updated value from the model parameter.
set_property value 0 ${MODELPARAM_VALUE.C_MEM0_CPI_AGENTBLOCKING}
}

proc update_MODELPARAM_VALUE.C_MEM0_CPI_FABRICBLOCKING { MODELPARAM_VALUE.C_MEM0_CPI_FABRICBLOCKING } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_MEM0_CPI_FABRICBLOCKING". Setting updated value from the model parameter.
set_property value 0 ${MODELPARAM_VALUE.C_MEM0_CPI_FABRICBLOCKING}
}

proc update_MODELPARAM_VALUE.C_MEM0_CPI_DATACMD_PARITY { MODELPARAM_VALUE.C_MEM0_CPI_DATACMD_PARITY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_MEM0_CPI_DATACMD_PARITY". Setting updated value from the model parameter.
set_property value 0 ${MODELPARAM_VALUE.C_MEM0_CPI_DATACMD_PARITY}
}

proc update_MODELPARAM_VALUE.C_MEM0_CPI_CXL_MODE { MODELPARAM_VALUE.C_MEM0_CPI_CXL_MODE PARAM_VALUE.C_MEM0_CPI_CXL_MODE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_MEM0_CPI_CXL_MODE}] ${MODELPARAM_VALUE.C_MEM0_CPI_CXL_MODE}
}

proc update_MODELPARAM_VALUE.C_MEM0_CPI_DATA_WIDTH { MODELPARAM_VALUE.C_MEM0_CPI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_MEM0_CPI_DATA_WIDTH". Setting updated value from the model parameter.
set_property value 512 ${MODELPARAM_VALUE.C_MEM0_CPI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_MEM0_CPI_A2F_MAX_CREDIT { MODELPARAM_VALUE.C_MEM0_CPI_A2F_MAX_CREDIT PARAM_VALUE.C_MEM0_CPI_A2F_MAX_CREDIT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_MEM0_CPI_A2F_MAX_CREDIT}] ${MODELPARAM_VALUE.C_MEM0_CPI_A2F_MAX_CREDIT}
}

proc update_MODELPARAM_VALUE.C_MEM0_CPI_F2A_MAX_CREDIT { MODELPARAM_VALUE.C_MEM0_CPI_F2A_MAX_CREDIT PARAM_VALUE.C_MEM0_CPI_F2A_MAX_CREDIT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_MEM0_CPI_F2A_MAX_CREDIT}] ${MODELPARAM_VALUE.C_MEM0_CPI_F2A_MAX_CREDIT}
}

proc update_MODELPARAM_VALUE.C_CACHE_WIDTH { MODELPARAM_VALUE.C_CACHE_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_CACHE_WIDTH". Setting updated value from the model parameter.
set_property value 512 ${MODELPARAM_VALUE.C_CACHE_WIDTH}
}

proc update_MODELPARAM_VALUE.C_CXL_HDM_COUNT { MODELPARAM_VALUE.C_CXL_HDM_COUNT PARAM_VALUE.C_CXL_HDM_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_CXL_HDM_COUNT}] ${MODELPARAM_VALUE.C_CXL_HDM_COUNT}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_BASEADDR { MODELPARAM_VALUE.C_M0_AXI_HDM_BASEADDR PARAM_VALUE.C_M0_AXI_HDM_BASEADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M0_AXI_HDM_BASEADDR}] ${MODELPARAM_VALUE.C_M0_AXI_HDM_BASEADDR}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_HIGHADDR { MODELPARAM_VALUE.C_M0_AXI_HDM_HIGHADDR PARAM_VALUE.C_M0_AXI_HDM_HIGHADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M0_AXI_HDM_HIGHADDR}] ${MODELPARAM_VALUE.C_M0_AXI_HDM_HIGHADDR}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_ADDR_WIDTH { MODELPARAM_VALUE.C_M0_AXI_HDM_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_M0_AXI_HDM_ADDR_WIDTH". Setting updated value from the model parameter.
set_property value 64 ${MODELPARAM_VALUE.C_M0_AXI_HDM_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_DATA_WIDTH { MODELPARAM_VALUE.C_M0_AXI_HDM_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_M0_AXI_HDM_DATA_WIDTH". Setting updated value from the model parameter.
set_property value 512 ${MODELPARAM_VALUE.C_M0_AXI_HDM_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_ID_WIDTH { MODELPARAM_VALUE.C_M0_AXI_HDM_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_M0_AXI_HDM_ID_WIDTH". Setting updated value from the model parameter.
set_property value 6 ${MODELPARAM_VALUE.C_M0_AXI_HDM_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_AWUSER_WIDTH { MODELPARAM_VALUE.C_M0_AXI_HDM_AWUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# No longer a customizable user parameter - hardcoded to what this design's
	# M0_AXI_HDM bus-interface pin declares (see design_1_bd.tcl), not the RTL's
	# own bare default, since this proc (not the component.xml default alone) is
	# what actually feeds the generated Verilog instantiation.
set_property value 24 ${MODELPARAM_VALUE.C_M0_AXI_HDM_AWUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_WUSER_WIDTH { MODELPARAM_VALUE.C_M0_AXI_HDM_WUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# No longer a customizable user parameter - hardcoded to what this design's
	# M0_AXI_HDM bus-interface pin declares (see design_1_bd.tcl), not the RTL's
	# own bare default, since this proc (not the component.xml default alone) is
	# what actually feeds the generated Verilog instantiation.
set_property value 4 ${MODELPARAM_VALUE.C_M0_AXI_HDM_WUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_BUSER_WIDTH { MODELPARAM_VALUE.C_M0_AXI_HDM_BUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# No longer a customizable user parameter - hardcoded to what this design's
	# M0_AXI_HDM bus-interface pin declares (see design_1_bd.tcl), not the RTL's
	# own bare default, since this proc (not the component.xml default alone) is
	# what actually feeds the generated Verilog instantiation.
set_property value 4 ${MODELPARAM_VALUE.C_M0_AXI_HDM_BUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_ARUSER_WIDTH { MODELPARAM_VALUE.C_M0_AXI_HDM_ARUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# No longer a customizable user parameter - hardcoded to what this design's
	# M0_AXI_HDM bus-interface pin declares (see design_1_bd.tcl), not the RTL's
	# own bare default, since this proc (not the component.xml default alone) is
	# what actually feeds the generated Verilog instantiation.
set_property value 24 ${MODELPARAM_VALUE.C_M0_AXI_HDM_ARUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M0_AXI_HDM_RUSER_WIDTH { MODELPARAM_VALUE.C_M0_AXI_HDM_RUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# No longer a customizable user parameter - hardcoded to what this design's
	# M0_AXI_HDM bus-interface pin declares (see design_1_bd.tcl), not the RTL's
	# own bare default, since this proc (not the component.xml default alone) is
	# what actually feeds the generated Verilog instantiation.
set_property value 5 ${MODELPARAM_VALUE.C_M0_AXI_HDM_RUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_CVA_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_CVA_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_S_CVA_AXI_ADDR_WIDTH". Setting updated value from the model parameter.
set_property value 32 ${MODELPARAM_VALUE.C_S_CVA_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_CVA_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_CVA_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_S_CVA_AXI_DATA_WIDTH". Setting updated value from the model parameter.
set_property value 32 ${MODELPARAM_VALUE.C_S_CVA_AXI_DATA_WIDTH}
}

