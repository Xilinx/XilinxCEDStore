# (c) Copyright 2023 Advanced Micro Devices, Inc. All rights reserved.
#
# This file contains confidential and proprietary information
# of AMD and is protected under U.S. and international copyright
# and other intellectual property laws.
#
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# AMD, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) AMD shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or AMD had been advised of the
# possibility of the same.
#
# CRITICAL APPLICATIONS
# AMD products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of AMD products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
#
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
############################################################
set devicefamily [get_project_property ARCHITECTURE]
set c_family $devicefamily
proc init_gui { IPINST } {
   set Component_Name [ipgui::add_param $IPINST -name Component_Name ]
   set Page0          [ipgui::add_page  $IPINST -name "Main Page" -layout vertical]
   set pTDATA_NUM_BYTES [ipgui::add_param $IPINST -parent $Page0 -name pTDATA_NUM_BYTES]
   set pCOLOROMETRY [ipgui::add_param $IPINST -parent $Page0 -name pCOLOROMETRY]
   set pBPC [ipgui::add_param $IPINST -parent $Page0 -name pBPC]
   set pPIXELS_PER_CLOCK [ipgui::add_param $IPINST -parent $Page0 -name pPIXELS_PER_CLOCK]
  puts "taaaaest"
}


proc update_MODELPARAM_VALUE.pTDATA_NUM_BYTES {MODELPARAM_VALUE.pTDATA_NUM_BYTES PARAM_VALUE.pTDATA_NUM_BYTES } {
  set tdata_width  [get_property value ${PARAM_VALUE.pTDATA_NUM_BYTES}]
  set_property value $tdata_width ${MODELPARAM_VALUE.pTDATA_NUM_BYTES}
}

proc update_MODELPARAM_VALUE.pCOLOROMETRY {MODELPARAM_VALUE.pCOLOROMETRY PARAM_VALUE.pCOLOROMETRY } {
  set color  [get_property value ${PARAM_VALUE.pCOLOROMETRY}]
  set_property value $color ${MODELPARAM_VALUE.pCOLOROMETRY}
}

proc update_MODELPARAM_VALUE.pBPC {MODELPARAM_VALUE.pBPC PARAM_VALUE.pBPC } {
  set max_bpc_gui  [get_property value ${PARAM_VALUE.pBPC}]
  set_property value $max_bpc_gui ${MODELPARAM_VALUE.pBPC}
}

proc update_MODELPARAM_VALUE.pPIXELS_PER_CLOCK {MODELPARAM_VALUE.pPIXELS_PER_CLOCK PARAM_VALUE.pPIXELS_PER_CLOCK } {
  set ppc  [get_property value ${PARAM_VALUE.pPIXELS_PER_CLOCK}]
  set_property value $ppc ${MODELPARAM_VALUE.pPIXELS_PER_CLOCK}
}

proc update_MODELPARAM_VALUE.C_FAMILY { MODELPARAM_VALUE.C_FAMILY} {
set c_family [string tolower [get_project_property ARCHITECTURE]]
set_property value $c_family  ${MODELPARAM_VALUE.C_FAMILY} 
   return true
}

proc update_PARAM_VALUE.pUG934_COMPLIANCE { PARAM_VALUE.pUG934_COMPLIANCE } {
	# Procedure called to update C_UG934_COMPLIANCE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.pUG934_COMPLIANCE { PARAM_VALUE.pUG934_COMPLIANCE } {
	# Procedure called to validate C_UG934_COMPLIANCE
	return true
}
proc update_MODELPARAM_VALUE.pUG934_COMPLIANCE { PARAM_VALUE.pUG934_COMPLIANCE MODELPARAM_VALUE.pUG934_COMPLIANCE} {
	set_property value [get_property value ${PARAM_VALUE.pUG934_COMPLIANCE}] ${MODELPARAM_VALUE.pUG934_COMPLIANCE}
}


proc update_PARAM_VALUE.pENABLE_DSC { PARAM_VALUE.pENABLE_DSC } {
	# Procedure called to update pENABLE_DSC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.pENABLE_DSC { PARAM_VALUE.pENABLE_DSC } {
	# Procedure called to validate pENABLE_DSC
	return true
}
proc update_MODELPARAM_VALUE.pENABLE_DSC { PARAM_VALUE.pENABLE_DSC MODELPARAM_VALUE.pENABLE_DSC} {
	set_property value [get_property value ${PARAM_VALUE.pENABLE_DSC}] ${MODELPARAM_VALUE.pENABLE_DSC}
}


proc update_PARAM_VALUE.pENABLE_420 { PARAM_VALUE.pENABLE_420 } {
	# Procedure called to update pENABLE_420 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.pENABLE_420 { PARAM_VALUE.pENABLE_420 } {
	# Procedure called to validate pENABLE_420
	return true
}
proc update_MODELPARAM_VALUE.pENABLE_420 { PARAM_VALUE.pENABLE_420 MODELPARAM_VALUE.pENABLE_420} {
	set_property value [get_property value ${PARAM_VALUE.pENABLE_420}] ${MODELPARAM_VALUE.pENABLE_420}
}

proc update_PARAM_VALUE.pARB_RES_EN { PARAM_VALUE.pARB_RES_EN } {
	# Procedure called to update pARB_RES_EN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.pARB_RES_EN { PARAM_VALUE.pARB_RES_EN } {
	# Procedure called to validate pARB_RES_EN
	return true
}
proc update_MODELPARAM_VALUE.pARB_RES_EN { PARAM_VALUE.pARB_RES_EN MODELPARAM_VALUE.pARB_RES_EN} {
	set_property value [get_property value ${PARAM_VALUE.pARB_RES_EN}] ${MODELPARAM_VALUE.pARB_RES_EN}
}

proc update_PARAM_VALUE.pINPUT_PIXELS_PER_CLOCK { PARAM_VALUE.pINPUT_PIXELS_PER_CLOCK } {
	# Procedure called to update pINPUT_PIXELS_PER_CLOCK when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.pINPUT_PIXELS_PER_CLOCK { PARAM_VALUE.pINPUT_PIXELS_PER_CLOCK } {
	# Procedure called to validate pINPUT_PIXELS_PER_CLOCK
	return true
}
proc update_MODELPARAM_VALUE.pINPUT_PIXELS_PER_CLOCK { PARAM_VALUE.pINPUT_PIXELS_PER_CLOCK MODELPARAM_VALUE.pINPUT_PIXELS_PER_CLOCK} {
	set_property value [get_property value ${PARAM_VALUE.pINPUT_PIXELS_PER_CLOCK}] ${MODELPARAM_VALUE.pINPUT_PIXELS_PER_CLOCK}
}

proc update_PARAM_VALUE.pPPC_CONVERT_EN { PARAM_VALUE.pPPC_CONVERT_EN } {
	# Procedure called to update pPPC_CONVERT_EN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.pPPC_CONVERT_EN { PARAM_VALUE.pPPC_CONVERT_EN } {
	# Procedure called to validate pPPC_CONVERT_EN
	return true
}
proc update_MODELPARAM_VALUE.pPPC_CONVERT_EN { PARAM_VALUE.pPPC_CONVERT_EN MODELPARAM_VALUE.pPPC_CONVERT_EN} {
	set_property value [get_property value ${PARAM_VALUE.pPPC_CONVERT_EN}] ${MODELPARAM_VALUE.pPPC_CONVERT_EN}
}

proc update_PARAM_VALUE.pSTART_DSC_BYTE_FROM_LSB { PARAM_VALUE.pSTART_DSC_BYTE_FROM_LSB } {
	# Procedure called to update pSTART_DSC_BYTE_FROM_LSB when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.pSTART_DSC_BYTE_FROM_LSB { PARAM_VALUE.pSTART_DSC_BYTE_FROM_LSB } {
	# Procedure called to validate pSTART_DSC_BYTE_FROM_LSB
	return true
}
proc update_MODELPARAM_VALUE.pSTART_DSC_BYTE_FROM_LSB { PARAM_VALUE.pSTART_DSC_BYTE_FROM_LSB MODELPARAM_VALUE.pSTART_DSC_BYTE_FROM_LSB} {
	set_property value [get_property value ${PARAM_VALUE.pSTART_DSC_BYTE_FROM_LSB}] ${MODELPARAM_VALUE.pSTART_DSC_BYTE_FROM_LSB}
}
