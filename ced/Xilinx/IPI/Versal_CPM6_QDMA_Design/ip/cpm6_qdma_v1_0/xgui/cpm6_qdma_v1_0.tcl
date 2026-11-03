###############################################################################
##
## (c) Copyright 2020-2023 AMD, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of AMD, Inc. and is protected under U.S. and 
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## AMD, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) AMD shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or AMD had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## AMD products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of AMD products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
###############################################################################
##
## cpm6_qdma_v1_0.tcl
##
###############################################################################

proc init_gui { IPINST } {
  set Component_Name [ ipgui::add_param $IPINST  -parent $IPINST -name Component_Name ]

#  set_property hide_disabled_pins true [ipgui::get_canvasspec -of $IPINST]
  #init create new page
  #page 1

  set Page1 [ipgui::add_page $IPINST -parent $IPINST -name Page1 -layout horizontal]
  set_property display_name "Basic" $Page1

  set num_queues [ipgui::add_param $IPINST -parent $Page1 -name num_queues -layout horizontal -widget textEdit]
  set_property display_name "Number of Queue's" $num_queues
  set_property tooltip "Number of Queue's" $num_queues
  ipgui::add_row $IPINST -parent $Page1
  
  set mode_selection [ipgui::add_param  $IPINST -parent $Page1 -name mode_selection -layout horizontal -widget radioGroup ]
  set_property display_name  "Mode" $mode_selection
  set_property tooltip "This parameter is to select the Memory Mapped or Streaming mode user parameter options" $mode_selection
  ipgui::add_row $IPINST -parent $Page1
  
  set dsc_manage_mode [ipgui::add_param $IPINST -parent $Page1 -name "dsc_manage_mode" -layout horizontal -widget radioGroup]
  set_property display_name "Descriptor Management" $dsc_manage_mode
  set_property tooltip "Descriptor Management Internal Mode or Bypass Mode" $dsc_manage_mode
  ipgui::add_row $IPINST -parent $Page1
 
  set traf_man_intf [ipgui::add_param  $IPINST -parent $Page1 -name "traf_man_intf" -layout horizontal -widget checkBox]
  set_property tooltip "Traffic Management interface" $traf_man_intf
  set_property display_name "Traffic Management Interface" $traf_man_intf 
  ipgui::add_row $IPINST -parent $Page1
 
  set dsc_credit_intf [ipgui::add_param $IPINST -parent $Page1 -name "dsc_credit_intf" -layout horizontal -widget checkBox]
  set_property display_name "Descriptor Credit interface" $dsc_credit_intf
  set_property tooltip "Descriptor Credit interface. Always enabled in Streaming mode: the C2H prefetch engine sends its descriptor credits on this path." $dsc_credit_intf
  ipgui::add_row $IPINST -parent $Page1
 
  set dsc_ram_base_addr [ipgui::add_param $IPINST -parent $Page1 -name dsc_ram_base_addr -layout horizontal -widget textEdit]
  set_property display_name "Descriptor RAM Base address" $dsc_ram_base_addr
  set_property tooltip "up to 64-bit address" $dsc_ram_base_addr
  ipgui::add_row $IPINST -parent $Page1
 
  set num_pfs [ipgui::add_param $IPINST -parent $Page1 -name num_pfs -layout horizontal -widget textEdit]
  set_property display_name "Number of PFs" $num_pfs
  ipgui::add_row $IPINST -parent $Page1
  
  set num_vfs [ipgui::add_param $IPINST -parent $Page1 -name num_vfs -layout horizontal -widget textEdit]
  set_property display_name "Number of VFs" $num_vfs
  set_property tooltip "Total number of VFs across all PFs. The sum of Number of VFs for PF0-PF3 (for the PFs enabled by Number of PFs) must not exceed this value." $num_vfs
  ipgui::add_row $IPINST -parent $Page1

  set num_vfs_pf0 [ipgui::add_param $IPINST -parent $Page1 -name num_vfs_pf0 -layout horizontal -widget textEdit]
  set_property display_name "Number of VFs for PF0" $num_vfs_pf0
  set_property tooltip "VFs allocated to PF0. VF function numbers are assigned contiguously across PFs in order. Sum of VFs allocated with PF0-PF3 (enabled PFs only) must not exceed Number of VFs." $num_vfs_pf0
  ipgui::add_row $IPINST -parent $Page1

  set num_vfs_pf1 [ipgui::add_param $IPINST -parent $Page1 -name num_vfs_pf1 -layout horizontal -widget textEdit]
  set_property display_name "Number of VFs for PF1" $num_vfs_pf1
  set_property tooltip "VFs allocated to PF1. Sum of VFs allocated with PF0-PF3 (enabled PFs only) must not exceed Number of VFs." $num_vfs_pf1
  ipgui::add_row $IPINST -parent $Page1

  set num_vfs_pf2 [ipgui::add_param $IPINST -parent $Page1 -name num_vfs_pf2 -layout horizontal -widget textEdit]
  set_property display_name "Number of VFs for PF2" $num_vfs_pf2
  set_property tooltip "VFs allocated to PF2. Sum of VFs allocated with PF0-PF3 (enabled PFs only) must not exceed Number of VFs." $num_vfs_pf2
  ipgui::add_row $IPINST -parent $Page1

  set num_vfs_pf3 [ipgui::add_param $IPINST -parent $Page1 -name num_vfs_pf3 -layout horizontal -widget textEdit]
  set_property display_name "Number of VFs for PF3" $num_vfs_pf3
  set_property tooltip "VFs allocated to PF3. Sum of VFs allocated with PF0-PF3 (enabled PFs only) must not exceed Number of VFs." $num_vfs_pf3
  ipgui::add_row $IPINST -parent $Page1

  set msix_en [ipgui::add_param $IPINST -parent $Page1 -name "msix_en" -layout horizontal -widget checkBox]
  set_property display_name "MSI-X En" $msix_en
  set_property tooltip "Interrupt support, Maximum 8 vectors per function" $msix_en
  ipgui::add_row $IPINST -parent $Page1

  set flr_rpu_port_en [ipgui::add_param $IPINST -parent $Page1 -name "flr_rpu_port_en" -layout horizontal -widget checkBox]
  set_property display_name "FLR RPU Port En" $flr_rpu_port_en
  set_property tooltip "Backup dedicated AXI4-Lite port for RPU/firmware access to the FLR register bank; bypasses the shared ELBI path for FLR when enabled" $flr_rpu_port_en
  ipgui::add_row $IPINST -parent $Page1

  set enable_dbg [ipgui::add_param $IPINST -parent $Page1 -name "enable_dbg" -layout horizontal -widget checkBox]
  set_property display_name "Enable Debug Registers" $enable_dbg
  set_property tooltip "Enable on-chip debug register outputs" $enable_dbg
  ipgui::add_row $IPINST -parent $Page1

  set cpm6_ctrl [ipgui::add_param $IPINST -parent $Page1 -name "cpm6_ctrl" -layout horizontal -widget comboBox]
  set_property display_name "CPM6 Controller" $cpm6_ctrl
  set_property tooltip "Controller Selection as PS Wizad" $cpm6_ctrl
  ipgui::add_row $IPINST -parent $Page1
}

#
# Procedures called when parameter value is changed
#

proc update_PARAM_VALUE.num_pfs { PARAM_VALUE.num_pfs } {
  # Procedure called to update PARAM_VALUE.num_vfs_pf0 when any of the dependent parameters in the arguments change
  set num_pfs ${PARAM_VALUE.num_pfs}

    set_property enabled true $num_pfs
    set_property range "1,4" $num_pfs
    set_property value [get_property value $num_pfs] $num_pfs
}

proc update_PARAM_VALUE.num_vfs { PARAM_VALUE.num_vfs } {
  # Procedure called to update PARAM_VALUE.num_vfs_pf0 when any of the dependent parameters in the arguments change
  set num_vfs ${PARAM_VALUE.num_vfs}

    set_property enabled true $num_vfs
    set_property range "0,252" $num_vfs
    set_property value [get_property value $num_vfs] $num_vfs
}

proc update_PARAM_VALUE.num_vfs_pf0 { PARAM_VALUE.num_vfs_pf0 } {
  # VFs allocated to PF0. Per-PF counts may differ; the consumers derive each
  # PF's VF window as a running sum of these, so they must not be assumed equal.
  set num_vfs_pf0 ${PARAM_VALUE.num_vfs_pf0}

    set_property enabled true $num_vfs_pf0
    set_property range "0,252" $num_vfs_pf0
    set_property value [get_property value $num_vfs_pf0] $num_vfs_pf0
}

proc update_PARAM_VALUE.num_vfs_pf1 { PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_pfs } {
  # Always enabled; check_vf_pf_sum validates the PF1-exists-or-zero
  # constraint via an error message instead of disabling the field --
  # Vivado rejects "set_property enabled" from a validate/DRC proc
  # context, which is the only place a num_pfs-driven refresh could
  # otherwise live (update_PARAM_VALUE.num_pfs touching this field was
  # already rejected as a cyclic dependency, see CL 6612251).
  set num_vfs_pf1 ${PARAM_VALUE.num_vfs_pf1}

    set_property enabled true $num_vfs_pf1
    set_property range "0,252" $num_vfs_pf1
    set_property value [get_property value $num_vfs_pf1] $num_vfs_pf1
}

proc update_PARAM_VALUE.num_vfs_pf2 { PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_pfs } {
  # Always enabled -- see update_PARAM_VALUE.num_vfs_pf1 comment.
  set num_vfs_pf2 ${PARAM_VALUE.num_vfs_pf2}

    set_property enabled true $num_vfs_pf2
    set_property range "0,252" $num_vfs_pf2
    set_property value [get_property value $num_vfs_pf2] $num_vfs_pf2
}

proc update_PARAM_VALUE.num_vfs_pf3 { PARAM_VALUE.num_vfs_pf3 PARAM_VALUE.num_pfs } {
  # Always enabled -- see update_PARAM_VALUE.num_vfs_pf1 comment.
  set num_vfs_pf3 ${PARAM_VALUE.num_vfs_pf3}

    set_property enabled true $num_vfs_pf3
    set_property range "0,252" $num_vfs_pf3
    set_property value [get_property value $num_vfs_pf3] $num_vfs_pf3
}

proc update_PARAM_VALUE.num_queues { PARAM_VALUE.num_queues } {
  # Procedure called to update PARAM_VALUE.num_vfs_pf0 when any of the dependent parameters in the arguments change
  set num_queues ${PARAM_VALUE.num_queues}

    set_property enabled true $num_queues
    set_property range "1,2048" $num_queues
    set_property value [get_property value $num_queues] $num_queues

}

proc update_PARAM_VALUE.cpm6_ctrl { PARAM_VALUE.cpm6_ctrl } {
  # Procedure called to update PARAM_VALUE.num_vfs_pf0 when any of the dependent parameters in the arguments change
  set cpm6_ctrl ${PARAM_VALUE.cpm6_ctrl}

    set_property enabled true $cpm6_ctrl
    set_property range "0,1" $cpm6_ctrl
    set_property value [get_property value $cpm6_ctrl] $cpm6_ctrl
}

proc update_PARAM_VALUE.msix_en { PARAM_VALUE.msix_en } {
  set msix_en ${PARAM_VALUE.msix_en}
    set_property enabled true $msix_en
    set_property value [get_property value $msix_en] $msix_en
}

proc update_PARAM_VALUE.flr_rpu_port_en { PARAM_VALUE.flr_rpu_port_en } {
  set flr_rpu_port_en ${PARAM_VALUE.flr_rpu_port_en}
    set_property enabled true $flr_rpu_port_en
    set_property value [get_property value $flr_rpu_port_en] $flr_rpu_port_en
}

proc update_PARAM_VALUE.traf_man_intf { PARAM_VALUE.traf_man_intf } {
  set traf_man_intf ${PARAM_VALUE.traf_man_intf}
    set_property enabled true $traf_man_intf
    set_property value [get_property value $traf_man_intf] $traf_man_intf
}

proc update_PARAM_VALUE.mode_selection { PARAM_VALUE.mode_selection } {
  set mode_selection ${PARAM_VALUE.mode_selection}
    set_property enabled true $mode_selection
    set_property value [get_property value $mode_selection] $mode_selection
}

# DRC: sum of PER-PF VF counts assigned to PFs that actually exist (per
# Number of PFs) must not exceed Number of VFs. PF1/2/3 are always enabled
# (see update_PARAM_VALUE.num_vfs_pf{1,2,3}) -- a nonzero count on a PF
# that doesn't exist (num_pfs too small) is flagged here as an explicit
# error instead of being silently excluded, since the field can no longer
# be visually disabled to prevent that input.
#
# NOTE: do not add `set_property enabled ...` calls here. Vivado rejects
# "set enabled" from inside a validate/DRC proc (IP_Flow 19-4331); moving
# it to update_PARAM_VALUE.num_pfs is also rejected, as cyclic (CL 6612251).
proc check_vf_pf_sum { PARAM_VALUE.num_pfs PARAM_VALUE.num_vfs PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_vfs_pf3 ERR_HANDLE } {
  set num_pfs [get_property value ${PARAM_VALUE.num_pfs}]
  set num_vfs [get_property value ${PARAM_VALUE.num_vfs}]
  set pf_sum  [get_property value ${PARAM_VALUE.num_vfs_pf0}]
  set pf1     [get_property value ${PARAM_VALUE.num_vfs_pf1}]
  set pf2     [get_property value ${PARAM_VALUE.num_vfs_pf2}]
  set pf3     [get_property value ${PARAM_VALUE.num_vfs_pf3}]

  if { $num_pfs <= 1 && $pf1 > 0 } {
     set_property errmsg "Number of VFs for PF1 is $pf1 but Number of PFs is $num_pfs (PF1 does not exist)" ${ERR_HANDLE}
     return false
  }
  if { $num_pfs <= 2 && $pf2 > 0 } {
     set_property errmsg "Number of VFs for PF2 is $pf2 but Number of PFs is $num_pfs (PF2 does not exist)" ${ERR_HANDLE}
     return false
  }
  if { $num_pfs <= 3 && $pf3 > 0 } {
     set_property errmsg "Number of VFs for PF3 is $pf3 but Number of PFs is $num_pfs (PF3 does not exist)" ${ERR_HANDLE}
     return false
  }

  if { $num_pfs > 1 } { incr pf_sum $pf1 }
  if { $num_pfs > 2 } { incr pf_sum $pf2 }
  if { $num_pfs > 3 } { incr pf_sum $pf3 }
  if { $pf_sum > $num_vfs } {
     set_property errmsg "Sum of per-PF VF counts ($pf_sum) exceeds Number of VFs ($num_vfs)" ${ERR_HANDLE}
     return false
  }
  return true
}

proc validate_PARAM_VALUE.num_vfs { PARAM_VALUE.num_vfs PARAM_VALUE.num_pfs PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_vfs_pf3 } {
  set num_vfs [get_property value ${PARAM_VALUE.num_vfs}]
  if { $num_vfs > 252 } {
     set_property errmsg "Total number of VFs (PF0+PF1+PF2+PF3) should be 252 only" ${PARAM_VALUE.num_vfs}
	 return false
  } elseif { ![RangeCheck4HexDec  0000 256 ${PARAM_VALUE.num_vfs}] } {
      return false
  }
  return [check_vf_pf_sum ${PARAM_VALUE.num_pfs} ${PARAM_VALUE.num_vfs} ${PARAM_VALUE.num_vfs_pf0} ${PARAM_VALUE.num_vfs_pf1} ${PARAM_VALUE.num_vfs_pf2} ${PARAM_VALUE.num_vfs_pf3} ${PARAM_VALUE.num_vfs}]
}

proc validate_PARAM_VALUE.num_vfs_pf0 { PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_pfs PARAM_VALUE.num_vfs PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_vfs_pf3 } {
  return [check_vf_pf_sum ${PARAM_VALUE.num_pfs} ${PARAM_VALUE.num_vfs} ${PARAM_VALUE.num_vfs_pf0} ${PARAM_VALUE.num_vfs_pf1} ${PARAM_VALUE.num_vfs_pf2} ${PARAM_VALUE.num_vfs_pf3} ${PARAM_VALUE.num_vfs_pf0}]
}

proc validate_PARAM_VALUE.num_vfs_pf1 { PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_pfs PARAM_VALUE.num_vfs PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_vfs_pf3 } {
  return [check_vf_pf_sum ${PARAM_VALUE.num_pfs} ${PARAM_VALUE.num_vfs} ${PARAM_VALUE.num_vfs_pf0} ${PARAM_VALUE.num_vfs_pf1} ${PARAM_VALUE.num_vfs_pf2} ${PARAM_VALUE.num_vfs_pf3} ${PARAM_VALUE.num_vfs_pf1}]
}

proc validate_PARAM_VALUE.num_vfs_pf2 { PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_pfs PARAM_VALUE.num_vfs PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_vfs_pf3 } {
  return [check_vf_pf_sum ${PARAM_VALUE.num_pfs} ${PARAM_VALUE.num_vfs} ${PARAM_VALUE.num_vfs_pf0} ${PARAM_VALUE.num_vfs_pf1} ${PARAM_VALUE.num_vfs_pf2} ${PARAM_VALUE.num_vfs_pf3} ${PARAM_VALUE.num_vfs_pf2}]
}

proc validate_PARAM_VALUE.num_vfs_pf3 { PARAM_VALUE.num_vfs_pf3 PARAM_VALUE.num_pfs PARAM_VALUE.num_vfs PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_vfs_pf2 } {
  return [check_vf_pf_sum ${PARAM_VALUE.num_pfs} ${PARAM_VALUE.num_vfs} ${PARAM_VALUE.num_vfs_pf0} ${PARAM_VALUE.num_vfs_pf1} ${PARAM_VALUE.num_vfs_pf2} ${PARAM_VALUE.num_vfs_pf3} ${PARAM_VALUE.num_vfs_pf3}]
}
# Streaming (mode_selection 0): the C2H prefetch engine delivers its fetch
# credits through the descriptor credit path, so the path is always built and
# the option is fixed on. Memory Mapped: the credit interface stays optional.
proc update_PARAM_VALUE.dsc_credit_intf { PARAM_VALUE.dsc_credit_intf PARAM_VALUE.mode_selection } {
  set dsc_credit_intf ${PARAM_VALUE.dsc_credit_intf}
  if {[get_property value ${PARAM_VALUE.mode_selection}] == 0} {
    set_property value true $dsc_credit_intf
    set_property enabled false $dsc_credit_intf
  } else {
    set_property enabled true $dsc_credit_intf
    set_property value [get_property value $dsc_credit_intf] $dsc_credit_intf
  }
}

proc update_PARAM_VALUE.enable_dbg { PARAM_VALUE.enable_dbg } {
  set enable_dbg ${PARAM_VALUE.enable_dbg}
    set_property enabled true $enable_dbg
    set_property value [get_property value $enable_dbg] $enable_dbg
}

proc init_params {IPINST PARAM_VALUE.dsc_credit_intf PARAM_VALUE.mode_selection PARAM_VALUE.msix_en PARAM_VALUE.dsc_manage_mode PARAM_VALUE.enable_dbg } {
  set dsc_credit_intf ${PARAM_VALUE.dsc_credit_intf}
  set mode_selection ${PARAM_VALUE.mode_selection}
  set msix_en ${PARAM_VALUE.msix_en}
  set dsc_manage_mode ${PARAM_VALUE.dsc_manage_mode}
  
	set_property value [get_property value $mode_selection] $mode_selection
    set_property enabled true $mode_selection
	
	set_property value 1 $dsc_manage_mode
    set_property enabled false $dsc_manage_mode
	
    if {[get_property value $mode_selection] == 0} {
      set_property value true $dsc_credit_intf
      set_property enabled false $dsc_credit_intf
    } else {
      set_property value [get_property value $dsc_credit_intf] $dsc_credit_intf
      set_property enabled true $dsc_credit_intf
    }
	
    set_property value [get_property value $msix_en] $msix_en
    set_property enabled true $msix_en

    set enable_dbg ${PARAM_VALUE.enable_dbg}
    set_property value [get_property value $enable_dbg] $enable_dbg
    set_property enabled true $enable_dbg

}

proc update_MODELPARAM_VALUE.NUM_PF {MODELPARAM_VALUE.NUM_PF PARAM_VALUE.num_pfs IPINST} {
  set num_pfs [get_property value ${PARAM_VALUE.num_pfs}]
  set_property value $num_pfs ${MODELPARAM_VALUE.NUM_PF}
}
# dsc_ram_base_addr had no MODELPARAM proc, so the GUI value never reached the
# HDL. Underscores stripped (GUI shows 0x201_0000_0000).
proc update_MODELPARAM_VALUE.DSC_RAM_ADDR {MODELPARAM_VALUE.DSC_RAM_ADDR PARAM_VALUE.dsc_ram_base_addr IPINST} {
  set dsc_ram_base_addr [get_property value ${PARAM_VALUE.dsc_ram_base_addr}]
  set dsc_ram_base_addr [string map {_ {}} $dsc_ram_base_addr]
  # DSC_RAM_ADDR is a 64-bit bitString: zero-pad to the full 16 hex digits.
  set dsc_ram_base_addr [format 0x%016llx [expr {$dsc_ram_base_addr}]]
  set_property value $dsc_ram_base_addr ${MODELPARAM_VALUE.DSC_RAM_ADDR}
}
proc update_MODELPARAM_VALUE.NUM_VF {MODELPARAM_VALUE.NUM_VF PARAM_VALUE.num_vfs IPINST} {
  set num_vfs [get_property value ${PARAM_VALUE.num_vfs}]
  set_property value $num_vfs ${MODELPARAM_VALUE.NUM_VF}
}
proc update_MODELPARAM_VALUE.NUM_VFS_PF0 {MODELPARAM_VALUE.NUM_VFS_PF0 PARAM_VALUE.num_vfs_pf0 IPINST} {
  set num_vfs_pf0 [get_property value ${PARAM_VALUE.num_vfs_pf0}]
  set_property value $num_vfs_pf0 ${MODELPARAM_VALUE.NUM_VFS_PF0}
}
proc update_MODELPARAM_VALUE.NUM_VFS_PF1 {MODELPARAM_VALUE.NUM_VFS_PF1 PARAM_VALUE.num_vfs_pf1 IPINST} {
  set num_vfs_pf1 [get_property value ${PARAM_VALUE.num_vfs_pf1}]
  set_property value $num_vfs_pf1 ${MODELPARAM_VALUE.NUM_VFS_PF1}
}
proc update_MODELPARAM_VALUE.NUM_VFS_PF2 {MODELPARAM_VALUE.NUM_VFS_PF2 PARAM_VALUE.num_vfs_pf2 IPINST} {
  set num_vfs_pf2 [get_property value ${PARAM_VALUE.num_vfs_pf2}]
  set_property value $num_vfs_pf2 ${MODELPARAM_VALUE.NUM_VFS_PF2}
}
proc update_MODELPARAM_VALUE.NUM_VFS_PF3 {MODELPARAM_VALUE.NUM_VFS_PF3 PARAM_VALUE.num_vfs_pf3 IPINST} {
  set num_vfs_pf3 [get_property value ${PARAM_VALUE.num_vfs_pf3}]
  set_property value $num_vfs_pf3 ${MODELPARAM_VALUE.NUM_VFS_PF3}
}
proc update_MODELPARAM_VALUE.NUM_QIDS {MODELPARAM_VALUE.NUM_QIDS PARAM_VALUE.num_queues IPINST} {
  set num_queues [get_property value ${PARAM_VALUE.num_queues}]
  set_property value $num_queues ${MODELPARAM_VALUE.NUM_QIDS}
}

proc update_MODELPARAM_VALUE.CPM6_CTRL {MODELPARAM_VALUE.CPM6_CTRL PARAM_VALUE.cpm6_ctrl IPINST} {
  set cpm6_ctrl [get_property value ${PARAM_VALUE.cpm6_ctrl}]
  set_property value $cpm6_ctrl ${MODELPARAM_VALUE.CPM6_CTRL}
}

proc update_MODELPARAM_VALUE.MSIX_EN {MODELPARAM_VALUE.MSIX_EN PARAM_VALUE.msix_en IPINST} {
  set msix_en [get_property value ${PARAM_VALUE.msix_en}]
  if {$msix_en eq "true"} {
    set_property value 1 ${MODELPARAM_VALUE.MSIX_EN}
  } else {
    set_property value 0 ${MODELPARAM_VALUE.MSIX_EN}
  }
}

proc update_MODELPARAM_VALUE.FLR_RPU_PORT_EN {MODELPARAM_VALUE.FLR_RPU_PORT_EN PARAM_VALUE.flr_rpu_port_en IPINST} {
  set flr_rpu_port_en [get_property value ${PARAM_VALUE.flr_rpu_port_en}]
  if {$flr_rpu_port_en eq "true"} {
    set_property value 1 ${MODELPARAM_VALUE.FLR_RPU_PORT_EN}
  } else {
    set_property value 0 ${MODELPARAM_VALUE.FLR_RPU_PORT_EN}
  }
}

proc update_MODELPARAM_VALUE.P_DSC_CRDT_EN {MODELPARAM_VALUE.P_DSC_CRDT_EN PARAM_VALUE.dsc_credit_intf IPINST} {
  set dsc_credit_intf [get_property value ${PARAM_VALUE.dsc_credit_intf}]
  if {$dsc_credit_intf eq "true"} {
    set_property value 1 ${MODELPARAM_VALUE.P_DSC_CRDT_EN}
  } else {
    set_property value 0 ${MODELPARAM_VALUE.P_DSC_CRDT_EN}
  }
}

proc update_MODELPARAM_VALUE.P_ENABLE_DBG {MODELPARAM_VALUE.P_ENABLE_DBG PARAM_VALUE.enable_dbg IPINST} {
  set enable_dbg [get_property value ${PARAM_VALUE.enable_dbg}]
  if {$enable_dbg eq "true"} {
    set_property value 1 ${MODELPARAM_VALUE.P_ENABLE_DBG}
  } else {
    set_property value 0 ${MODELPARAM_VALUE.P_ENABLE_DBG}
  }
}

proc update_MODELPARAM_VALUE.DMA_ST {MODELPARAM_VALUE.DMA_ST PARAM_VALUE.mode_selection IPINST} {
  set mode [get_property value ${PARAM_VALUE.mode_selection}]
  # mode_selection: Memory_Mapped=1, Streaming=0
  set_property value [expr {$mode == 0 ? 1 : 0}] ${MODELPARAM_VALUE.DMA_ST}
}

proc update_MODELPARAM_VALUE.DMA_MM {MODELPARAM_VALUE.DMA_MM PARAM_VALUE.mode_selection IPINST} {
  set mode [get_property value ${PARAM_VALUE.mode_selection}]
  set_property value [expr {$mode == 1 ? 1 : 0}] ${MODELPARAM_VALUE.DMA_MM}
}

proc RangeCheck4HexDec { MinValue MaxValue PARAM_HANDLE} {
    set paramValue [get_property value  ${PARAM_HANDLE} ]
    if {( $paramValue % 4 ) != 0} {
        set_property errmsg "Entered value should be multiple of 4. your value is $paramValue" ${PARAM_HANDLE}
        return false
    } 
    if {[string toupper [string range  $paramValue  1 1] ]eq "X" } {
        set paramValue [string map { "_" "" } [string range $paramValue  2 end]]
    }
    if {[string toupper [string range  $MinValue  1 1] ]eq "X" } {
        set MinValue [string range $MinValue  2 end]
    }
    if {[string toupper [string range  $MaxValue  1 1] ]eq "X" } {
        set MaxValue [string range $MaxValue  2 end]
    }
   # send_msg INFO 123 " m:$MinValue M:$MinValue H:$PARAM_HANDLE V:$paramValue"

    if {[regexp -all {[a-fA-F0-9]} $paramValue] != [ string length $paramValue ]} {
        set_property errmsg "Entered invalid Hexadecimal value $paramValue" ${PARAM_HANDLE}
        return false
    }
    if {$paramValue  == ""} {
        set_property errmsg "Entered invalid Hexadecimal value $paramValue" ${PARAM_HANDLE}
        return false
    }

    if {[expr 0x$MaxValue ] < [expr 0x$paramValue ] ||  [expr 0x$paramValue ] < [expr 0x$MinValue]} {
        set_property errmsg "Entered  Hexadecimal value $paramValue is out of range." ${PARAM_HANDLE}
        return false
    }

    if {[string length $MaxValue]<[string length $paramValue]} {
        set_property errmsg "Entered  Hexadecimal value $paramValue is out of range." ${PARAM_HANDLE}
        return false
    }
    return true
}
