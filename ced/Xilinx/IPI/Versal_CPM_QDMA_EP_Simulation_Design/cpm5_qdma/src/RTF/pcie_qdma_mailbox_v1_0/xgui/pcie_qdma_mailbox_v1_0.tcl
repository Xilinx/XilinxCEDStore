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
## pcie_qdma_mailbox_v1_0.tcl
##
###############################################################################

proc init_gui { IPINST } {
  set Component_Name [ ipgui::add_param $IPINST  -parent $IPINST -name Component_Name ]

#  set_property hide_disabled_pins true [ipgui::get_canvasspec -of $IPINST]
  #init create new page
  #page 1

  set Page1 [ipgui::add_page $IPINST -parent $IPINST -name Page1 -layout horizontal]
  set_property display_name "Basic" $Page1

  set num_pfs [ipgui::add_param $IPINST -parent $Page1 -name num_pfs -widget comboBox]
  set_property display_name "Number of PF's" $num_pfs
  set_property tooltip "Number of PF's" $num_pfs
  ipgui::add_row $IPINST -parent $Page1

  set newPanel_1 [ipgui::add_panel $IPINST -name newPanel_1 -parent $Page1]
  ipgui::add_row $IPINST -parent $Page1

  set num_vfs_pf [ipgui::add_group $IPINST -parent $Page1 -name num_vfs_pf -layout vertical]
  set_property display_name "Number of VFs per PF" $num_vfs_pf

  set num_vfs_pf0 [ipgui::add_param $IPINST -parent $num_vfs_pf -name num_vfs_pf0 -widget textEdit]
  set_property display_name "Number of PF0 VF's" $num_vfs_pf0
  set_property tooltip "Number of PF0 VF's (should be multiple of 4)" $num_vfs_pf0
  ipgui::add_row $IPINST -parent $num_vfs_pf0

  set num_vfs_pf1 [ipgui::add_param $IPINST -parent $num_vfs_pf -name num_vfs_pf1 -widget textEdit]
  set_property display_name "Number of PF1 VF's" $num_vfs_pf1
  set_property tooltip "Number of PF1 VF's (should be multiple of 4)" $num_vfs_pf1
  ipgui::add_row $IPINST -parent $num_vfs_pf1

  set num_vfs_pf2 [ipgui::add_param $IPINST -parent $num_vfs_pf -name num_vfs_pf2 -widget textEdit]
  set_property display_name "Number of PF2 VF's" $num_vfs_pf2
  set_property tooltip "Number of PF2 VF's (should be multiple of 4)" $num_vfs_pf2
  ipgui::add_row $IPINST -parent $num_vfs_pf2

  set num_vfs_pf3 [ipgui::add_param $IPINST -parent $num_vfs_pf -name num_vfs_pf3 -widget textEdit]
  set_property display_name "Number of PF3 VF's" $num_vfs_pf3
  set_property tooltip "Number of PF3 VF's (should be multiple of 4)" $num_vfs_pf3
  ipgui::add_row $IPINST -parent $num_vfs_pf3

}


#
# Procedures called when parameter value is changed
#

proc update_PARAM_VALUE.num_pfs { PARAM_VALUE.num_pfs PROJECT_PARAM.DEVICE} {
  # Procedure called to update PARAM_VALUE.num_vfs_pf0 when any of the dependent parameters in the arguments change
  set c_xdevice           [get_project_property DEVICE]
  set num_pfs ${PARAM_VALUE.num_pfs}

    set_property enabled true $num_pfs
  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
    set_property range "1,16" $num_pfs
  } else {
    set_property range "1,4" $num_pfs
  }
}

proc update_PARAM_VALUE.num_vfs_pf0 { PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_pfs PROJECT_PARAM.DEVICE} {
  # Procedure called to update PARAM_VALUE.num_vfs_pf0 when any of the dependent parameters in the arguments change
  set c_xdevice           [get_project_property DEVICE]
  set num_vfs_pf0 ${PARAM_VALUE.num_vfs_pf0}
  set num_pfs [get_property value ${PARAM_VALUE.num_pfs}]

  if {$num_pfs >= 1 } {
    set_property value 4 $num_vfs_pf0
    set_property enabled true $num_vfs_pf0
      if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
           set_property range "0,2032" $num_vfs_pf0
      } else {
           set_property range "0,252" $num_vfs_pf0
      }
  } else {
    set_property value 0 $num_vfs_pf0
    set_property enabled false $num_vfs_pf0
  }
}

proc update_PARAM_VALUE.num_vfs_pf1 { PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_pfs PROJECT_PARAM.DEVICE} {
  # Procedure called to update PARAM_VALUE.num_vfs_pf0 when any of the dependent parameters in the arguments change
  set c_xdevice           [get_project_property DEVICE]
  set num_vfs_pf1 ${PARAM_VALUE.num_vfs_pf1}
  set num_pfs [get_property value ${PARAM_VALUE.num_pfs}]

  if {$num_pfs >= 2 } {
    set_property value 4 $num_vfs_pf1
    set_property enabled true $num_vfs_pf1
      if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
           set_property range "0,2032" $num_vfs_pf1
      } else {
           set_property range "0,252" $num_vfs_pf1
      }
  } else {
    set_property value 0 $num_vfs_pf1
    set_property enabled false $num_vfs_pf1
  }
}

proc update_PARAM_VALUE.num_vfs_pf2 { PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_pfs PROJECT_PARAM.DEVICE} {
  # Procedure called to update PARAM_VALUE.num_vfs_pf0 when any of the dependent parameters in the arguments change
  set c_xdevice           [get_project_property DEVICE]
  set num_vfs_pf2 ${PARAM_VALUE.num_vfs_pf2}
  set num_pfs [get_property value ${PARAM_VALUE.num_pfs}]

  if {$num_pfs >= 3 } {
    set_property value 4 $num_vfs_pf2
    set_property enabled true $num_vfs_pf2
      if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
           set_property range "0,2032" $num_vfs_pf2
      } else {
           set_property range "0,252" $num_vfs_pf2
      }
  } else {
    set_property value 0 $num_vfs_pf2
    set_property enabled false $num_vfs_pf2
  }
}

proc update_PARAM_VALUE.num_vfs_pf3 { PARAM_VALUE.num_vfs_pf3 PARAM_VALUE.num_pfs PROJECT_PARAM.DEVICE} {
  # Procedure called to update PARAM_VALUE.num_vfs_pf0 when any of the dependent parameters in the arguments change
  set c_xdevice           [get_project_property DEVICE]
  set num_vfs_pf3 ${PARAM_VALUE.num_vfs_pf3}
  set num_pfs [get_property value ${PARAM_VALUE.num_pfs}]

  if {$num_pfs >= 4 } {
    set_property value 4 $num_vfs_pf3
    set_property enabled true $num_vfs_pf3
      if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
           set_property range "0,2032" $num_vfs_pf3
      } else {
           set_property range "0,252" $num_vfs_pf3
      }
  } else {
    set_property value 0 $num_vfs_pf3
    set_property enabled false $num_vfs_pf3
  }
}

proc validate_PARAM_VALUE.num_vfs_pf0 { PARAM_VALUE.num_vfs_pf0 PROJECT_PARAM.DEVICE PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_vfs_pf3} {
  # Procedure called to validate num_vfs_pf0
  set c_xdevice           [get_project_property DEVICE]
  set pf0  [get_property value ${PARAM_VALUE.num_vfs_pf0}]
  set pf1  [get_property value ${PARAM_VALUE.num_vfs_pf1}]
  set pf2  [get_property value ${PARAM_VALUE.num_vfs_pf2}]
  set pf3  [get_property value ${PARAM_VALUE.num_vfs_pf3}]

  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
         if {[ expr ( $pf0 + $pf1 + $pf2 + $pf3 ) > "2032" ]} {
             set_property errmsg "Total number of VFs (PF0+PF1+PF2+PF3) should be 2032 only" ${PARAM_VALUE.num_vfs_pf0}
             return false
         } else {
             return [RangeCheck4HexDec  0000 2048 ${PARAM_VALUE.num_vfs_pf0}]
         }
    } else {
         if {[ expr ( $pf0 + $pf1 + $pf2 + $pf3 ) > "252" ]} {
             set_property errmsg "Total number of VFs (PF0+PF1+PF2+PF3) should be 252 only" ${PARAM_VALUE.num_vfs_pf0}
             return false
         } else {
             return [RangeCheck4HexDec  0000 256 ${PARAM_VALUE.num_vfs_pf0}]
         }
    }
}

proc validate_PARAM_VALUE.num_vfs_pf1 { PARAM_VALUE.num_vfs_pf1 PROJECT_PARAM.DEVICE PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_vfs_pf3} {
  # Procedure called to validate num_vfs_pf1
  set c_xdevice           [get_project_property DEVICE]
  set pf0  [get_property value ${PARAM_VALUE.num_vfs_pf0}]
  set pf1  [get_property value ${PARAM_VALUE.num_vfs_pf1}]
  set pf2  [get_property value ${PARAM_VALUE.num_vfs_pf2}]
  set pf3  [get_property value ${PARAM_VALUE.num_vfs_pf3}]

  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
         if {[ expr ( $pf0 + $pf1 + $pf2 + $pf3 ) > "2032" ]} {
             set_property errmsg "Total number of VFs (PF0+PF1+PF2+PF3) should be 2032 only" ${PARAM_VALUE.num_vfs_pf1}
             return false
         } else {
             return [RangeCheck4HexDec  0000 2048 ${PARAM_VALUE.num_vfs_pf1}]
         }
    } else {
         if {[ expr ( $pf0 + $pf1 + $pf2 + $pf3 ) > "252" ]} {
             set_property errmsg "Total number of VFs (PF0+PF1+PF2+PF3) should be 252 only" ${PARAM_VALUE.num_vfs_pf1}
             return false
         } else {
             return [RangeCheck4HexDec  0000 256 ${PARAM_VALUE.num_vfs_pf1}]
         }
    }
}

proc validate_PARAM_VALUE.num_vfs_pf2 { PARAM_VALUE.num_vfs_pf2 PROJECT_PARAM.DEVICE PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_vfs_pf3} {
  # Procedure called to validate num_vfs_pf2
  set c_xdevice           [get_project_property DEVICE]
  set pf0  [get_property value ${PARAM_VALUE.num_vfs_pf0}]
  set pf1  [get_property value ${PARAM_VALUE.num_vfs_pf1}]
  set pf2  [get_property value ${PARAM_VALUE.num_vfs_pf2}]
  set pf3  [get_property value ${PARAM_VALUE.num_vfs_pf3}]

  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
         if {[ expr ( $pf0 + $pf1 + $pf2 + $pf3 ) > "2032" ]} {
             set_property errmsg "Total number of VFs (PF0+PF1+PF2+PF3) should be 2032 only" ${PARAM_VALUE.num_vfs_pf2}
             return false
         } else {
             return [RangeCheck4HexDec  0000 2048 ${PARAM_VALUE.num_vfs_pf2}]
         }
    } else {
         if {[ expr ( $pf0 + $pf1 + $pf2 + $pf3 ) > "252" ]} {
             set_property errmsg "Total number of VFs (PF0+PF1+PF2+PF3) should be 252 only" ${PARAM_VALUE.num_vfs_pf2}
             return false
         } else {
             return [RangeCheck4HexDec  0000 256 ${PARAM_VALUE.num_vfs_pf2}]
         }
    }
}

proc validate_PARAM_VALUE.num_vfs_pf3 { PARAM_VALUE.num_vfs_pf3 PROJECT_PARAM.DEVICE PARAM_VALUE.num_vfs_pf0 PARAM_VALUE.num_vfs_pf1 PARAM_VALUE.num_vfs_pf2 PARAM_VALUE.num_vfs_pf3} {
  # Procedure called to validate num_vfs_pf3
  set c_xdevice           [get_project_property DEVICE]
  set pf0  [get_property value ${PARAM_VALUE.num_vfs_pf0}]
  set pf1  [get_property value ${PARAM_VALUE.num_vfs_pf1}]
  set pf2  [get_property value ${PARAM_VALUE.num_vfs_pf2}]
  set pf3  [get_property value ${PARAM_VALUE.num_vfs_pf3}]

  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
         if {[ expr ( $pf0 + $pf1 + $pf2 + $pf3 ) > "2032" ]} {
             set_property errmsg "Total number of VFs (PF0+PF1+PF2+PF3) should be 2032 only" ${PARAM_VALUE.num_vfs_pf3}
             return false
         } else {
             return [RangeCheck4HexDec  0000 2048 ${PARAM_VALUE.num_vfs_pf3}]
         }
    } else {
         if {[ expr ( $pf0 + $pf1 + $pf2 + $pf3 ) > "252" ]} {
             set_property errmsg "Total number of VFs (PF0+PF1+PF2+PF3) should be 252 only" ${PARAM_VALUE.num_vfs_pf3}
             return false
         } else {
             return [RangeCheck4HexDec  0000 256 ${PARAM_VALUE.num_vfs_pf3}]
         }
    }
}


#
# update HDL Parameters 
#
proc update_MODELPARAM_VALUE.VERSAL {MODELPARAM_VALUE.VERSAL PROJECT_PARAM.ARCHITECTURE } {

    set c_xfamily  [string toupper ${PROJECT_PARAM.ARCHITECTURE} ]
    if {$c_xfamily eq "VERSAL"} {
        set val  true
    } else {
        set val  false
    }
    set_property value  [string toupper $val] ${MODELPARAM_VALUE.VERSAL}
}

proc update_MODELPARAM_VALUE.RTL_REVISION { MODELPARAM_VALUE.RTL_REVISION PROJECT_PARAM.DEVICE} {
  set c_xdevice           [get_project_property DEVICE]

  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
      set val 0x1fd32000
    } else {
      set val 0x1fd31000
    }
  set_property value $val ${MODELPARAM_VALUE.RTL_REVISION}
}

proc update_MODELPARAM_VALUE.PATCH_REVIVION { MODELPARAM_VALUE.PATCH_REVIVION PROJECT_PARAM.DEVICE} {
  set c_xdevice           [get_project_property DEVICE]

  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
      set val 0x00104104
    } else {
      set val 0x00104104
    }
  set_property value $val ${MODELPARAM_VALUE.PATCH_REVIVION}
}

proc update_MODELPARAM_VALUE.H10_DEVICE { MODELPARAM_VALUE.H10_DEVICE PROJECT_PARAM.DEVICE} {
  set c_xdevice           [get_project_property DEVICE]

  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
      set val 1
    } else {
      set val 0
    }
  set_property value $val ${MODELPARAM_VALUE.H10_DEVICE}
}

proc update_MODELPARAM_VALUE.VF_4KQ { MODELPARAM_VALUE.VF_4KQ PARAM_VALUE.enable_vf_4kq} {
  set enable_vf_4kq [get_property value ${PARAM_VALUE.enable_vf_4kq}]

  if { $enable_vf_4kq eq "true" } {
      set val 1
    } else {
      set val 0
    }
  set_property value $val ${MODELPARAM_VALUE.VF_4KQ}
}
proc update_MODELPARAM_VALUE.MAX_PF { MODELPARAM_VALUE.MAX_PF PROJECT_PARAM.DEVICE} {
  set c_xdevice           [get_project_property DEVICE]

  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
#      set val 16  # for now
      set val 4
    } else {
      set val 4
    }
  set_property value $val ${MODELPARAM_VALUE.MAX_PF}
}

proc update_MODELPARAM_VALUE.TOTAL_FNC { MODELPARAM_VALUE.TOTAL_FNC PROJECT_PARAM.DEVICE} {
  set c_xdevice           [get_project_property DEVICE]

  if {[string match -nocase "xcvp*" $c_xdevice] || [string match -nocase "xcvh*" $c_xdevice]} {
#      set val 2048   # for now
      set val 256
    } else {
      set val 256
    }
  set_property value $val ${MODELPARAM_VALUE.TOTAL_FNC}
}

proc update_MODELPARAM_VALUE.NUM_PFS {MODELPARAM_VALUE.NUM_PFS PARAM_VALUE.num_pfs} {
  set num_pfs [get_property value ${PARAM_VALUE.num_pfs}]
  set_property value $num_pfs ${MODELPARAM_VALUE.NUM_PFS}
}

proc update_MODELPARAM_VALUE.NUM_VFS_PF0 {MODELPARAM_VALUE.NUM_VFS_PF0 PARAM_VALUE.num_vfs_pf0 } {
   set_property value [get_property value ${PARAM_VALUE.num_vfs_pf0}] ${MODELPARAM_VALUE.NUM_VFS_PF0}
 }

proc update_MODELPARAM_VALUE.NUM_VFS_PF1 {MODELPARAM_VALUE.NUM_VFS_PF1 PARAM_VALUE.num_vfs_pf1 } {
   set_property value [get_property value ${PARAM_VALUE.num_vfs_pf1}] ${MODELPARAM_VALUE.NUM_VFS_PF1}
 }

proc update_MODELPARAM_VALUE.NUM_VFS_PF2 {MODELPARAM_VALUE.NUM_VFS_PF2 PARAM_VALUE.num_vfs_pf2 } {
   set_property value [get_property value ${PARAM_VALUE.num_vfs_pf2}] ${MODELPARAM_VALUE.NUM_VFS_PF2}
 }

proc update_MODELPARAM_VALUE.NUM_VFS_PF3 {MODELPARAM_VALUE.NUM_VFS_PF3 PARAM_VALUE.num_vfs_pf3 } {
   set_property value [get_property value ${PARAM_VALUE.num_vfs_pf3}] ${MODELPARAM_VALUE.NUM_VFS_PF3}
 }
 
proc update_MODELPARAM_VALUE.MAILBOX_OPT {MODELPARAM_VALUE.MAILBOX_OPT PARAM_VALUE.mailbox_opt} {
   set val [ string toupper [get_property value ${PARAM_VALUE.mailbox_opt}]]
   set_property value $val ${MODELPARAM_VALUE.MAILBOX_OPT}
 }
#proc scripts 

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
