proc createDesign {design_name options} {

    # Set the reference directory for source file relative paths (by default the value is script directory path)
    variable currentDir

    # Create 'sources_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sources_1] ""]} {
        create_fileset -srcset sources_1
    }

    # Set 'sources_1' fileset object
    set obj [get_filesets sources_1]
    set files [list \
        [file normalize "${currentDir}/imports/BMD_AXIST_EP_MEM.v"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_EP_MEM_ACCESS.v"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_INTR_CTRL.v"] \
        [file normalize "${currentDir}/imports/pcie_app_versal_bmd.vh"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_512.sv"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_CC_512.sv"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_CQ_512.sv"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_EP_512.sv"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_RC_512.sv"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_RQ_512.sv"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_RQ_MUX_512.sv"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_RQ_READ_512.sv"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_RQ_WRITE_512.sv"] \
        [file normalize "${currentDir}/imports/BMD_AXIST_TO_CTRL.sv"] \
        [file normalize "${currentDir}/imports/pcie_app_versal_bmd.sv"] \
        [file normalize "${currentDir}/imports/design_1_wrapper.v"] \
    ]
import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for local files
# None

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "${design_name}_wrapper" -objects $obj

# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports imports design_1_wrapper.v]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports imports design_1_wrapper.v] w]
puts -nonewline $outfile $contents
close $outfile


# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/imports/top_impl.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/imports/top_impl.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "${design_name}_wrapper" -objects $obj

# Set 'utils_1' fileset object
set obj [get_filesets utils_1]
set files [list \
    [file normalize "${currentDir}/imports/pre_place.tcl"] \
]
add_files -norecurse -fileset $obj $files

# Set 'utils_1' fileset file properties for remote files
set file "$currentDir/imports/pre_place.tcl"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets utils_1] [list "*$file"]]
set_property -name "file_type" -value "TCL" -objects $file_obj

set_property STEPS.PLACE_DESIGN.TCL.PRE [get_files pre_place.tcl -of [get_fileset utils_1] ] [get_runs impl_1]

# Set 'utils_1' fileset file properties for local files
# None

# Set 'utils_1' fileset properties
set obj [get_filesets utils_1]


# Adding sources referenced in BDs, if not already added

##################################################################
# DESIGN PROCs
##################################################################
proc create_root_design { parentCell } {

  # Create interface ports
  set PCIE0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT_0 ]

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]

  set pcie0_cfg_control_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_control_rtl:1.0 pcie0_cfg_control_0 ]

  set pcie0_cfg_ext_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_ext_rtl:1.0 pcie0_cfg_ext_0 ]

  set pcie0_cfg_interrupt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie0_cfg_interrupt_0 ]

  set pcie0_cfg_mgmt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie0_cfg_mgmt_0 ]

  set pcie0_cfg_msg_recd_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie0_cfg_msg_recd_0 ]

  set pcie0_cfg_msix_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_msix_rtl:1.0 pcie0_cfg_msix_0 ]

  set pcie0_cfg_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie4_cfg_status_rtl:1.0 pcie0_cfg_status_0 ]

  set pcie0_m_axis_cq_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_m_axis_cq_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $pcie0_m_axis_cq_0

  set pcie0_m_axis_rc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_m_axis_rc_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $pcie0_m_axis_rc_0

  set pcie0_s_axis_cc_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_s_axis_cc_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {81} \
   ] $pcie0_s_axis_cc_0

  set pcie0_s_axis_rq_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie0_s_axis_rq_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {179} \
   ] $pcie0_s_axis_rq_0

  set pcie0_transmit_fc_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie0_transmit_fc_0 ]


  # Create ports
  set pcie0_cfg_10b_tag_requester_enable_0 [ create_bd_port -dir O -from 3 -to 0 pcie0_cfg_10b_tag_requester_enable_0 ]
  set pcie0_cfg_atomic_requester_enable_0 [ create_bd_port -dir O -from 3 -to 0 pcie0_cfg_atomic_requester_enable_0 ]
  set pcie0_cfg_ext_tag_enable_0 [ create_bd_port -dir O pcie0_cfg_ext_tag_enable_0 ]
  set pcie0_cfg_fc_cpld_0 [ create_bd_port -dir O -from 11 -to 0 pcie0_cfg_fc_cpld_0 ]
  set pcie0_cfg_fc_cpld_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_cpld_scale_0 ]
  set pcie0_cfg_fc_cplh_0 [ create_bd_port -dir O -from 7 -to 0 pcie0_cfg_fc_cplh_0 ]
  set pcie0_cfg_fc_cplh_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_cplh_scale_0 ]
  set pcie0_cfg_fc_npd_0 [ create_bd_port -dir O -from 11 -to 0 pcie0_cfg_fc_npd_0 ]
  set pcie0_cfg_fc_npd_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_npd_scale_0 ]
  set pcie0_cfg_fc_nph_0 [ create_bd_port -dir O -from 7 -to 0 pcie0_cfg_fc_nph_0 ]
  set pcie0_cfg_fc_nph_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_nph_scale_0 ]
  set pcie0_cfg_fc_pd_0 [ create_bd_port -dir O -from 11 -to 0 pcie0_cfg_fc_pd_0 ]
  set pcie0_cfg_fc_pd_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_pd_scale_0 ]
  set pcie0_cfg_fc_ph_0 [ create_bd_port -dir O -from 7 -to 0 pcie0_cfg_fc_ph_0 ]
  set pcie0_cfg_fc_ph_scale_0 [ create_bd_port -dir O -from 1 -to 0 pcie0_cfg_fc_ph_scale_0 ]
  set pcie0_cfg_fc_sel_0 [ create_bd_port -dir I -from 2 -to 0 pcie0_cfg_fc_sel_0 ]
  set pcie0_cfg_fc_vc_sel_0 [ create_bd_port -dir I pcie0_cfg_fc_vc_sel_0 ]
  set pcie0_cfg_msix_function_number_0 [ create_bd_port -dir I -from 7 -to 0 pcie0_cfg_msix_function_number_0 ]
  set pcie0_cfg_msix_mint_vector_0 [ create_bd_port -dir I -from 31 -to 0 pcie0_cfg_msix_mint_vector_0 ]
  set pcie0_user_clk_0 [ create_bd_port -dir O -type clk pcie0_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {pcie0_m_axis_cq_0:pcie0_m_axis_rc_0:pcie0_s_axis_cc_0:pcie0_s_axis_rq_0} \
   CONFIG.FREQ_HZ {250000000} \
 ] $pcie0_user_clk_0
  set_property CONFIG.ASSOCIATED_BUSIF.VALUE_SRC DEFAULT $pcie0_user_clk_0

  set pcie0_user_lnk_up_0 [ create_bd_port -dir O pcie0_user_lnk_up_0 ]
  set pcie0_user_reset_0 [ create_bd_port -dir O -type rst pcie0_user_reset_0 ]
  set pl_ref_clk [ create_bd_port -dir O pl_ref_clk ]
  set xdma0_usr_irq_fnc_0 [ create_bd_port -dir I -from 7 -to 0 xdma0_usr_irq_fnc_0 ]

  # Create instance: logic0, and set properties
  set logic0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant logic0 ]
  set_property CONFIG.CONST_VAL {0} $logic0


 # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [list \
    CONFIG.CPM_CONFIG { \
      CPM_PCIE0_CFG_CTL_IF {1} \
      CPM_PCIE0_CFG_EXT_IF {1} \
      CPM_PCIE0_CFG_FC_IF {1} \
      CPM_PCIE0_CFG_MGMT_IF {1} \
      CPM_PCIE0_CFG_STS_IF {1} \
      CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s} \
      CPM_PCIE0_MESG_RSVD_IF {1} \
      CPM_PCIE0_MODES {PCIE} \
      CPM_PCIE0_MODE_SELECTION {Advanced} \
      CPM_PCIE0_MSI_X_OPTIONS {MSI-X_Internal} \
      CPM_PCIE0_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller} \
      CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
      CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
      CPM_PCIE0_TX_FC_IF {1} \
    } \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.PS_PMC_CONFIG { \
      DESIGN_MODE {1} \
      PMC_CRP_OSPI_REF_CTRL_FREQMHZ {135} \
      PMC_OSPI_PERIPHERAL {ENABLE 1} \
      PS_CRL_UART0_REF_CTRL_DIVISOR0 {6} \
      PS_CRL_UART0_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_UART1_REF_CTRL_DIVISOR0 {6} \
      PS_CRL_UART1_REF_CTRL_SRCSEL {PPLL} \
      PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
      PS_PCIE_RESET {{ENABLE 1}} \
      PS_UART0_BAUD_RATE {115200} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 16 .. 17}}} \
      PS_UART1_BAUD_RATE {115200} \
      PS_UART1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 20 .. 21}}} \
      PS_USE_M_AXI_FPD {0} \
} \
] $versal_cips_0 

  # Create interface connections
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins versal_cips_0/gt_refclk0]
  connect_bd_intf_net -intf_net pcie0_cfg_control_0_1 [get_bd_intf_ports pcie0_cfg_control_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_control]
  connect_bd_intf_net -intf_net pcie0_cfg_interrupt_0_1 [get_bd_intf_ports pcie0_cfg_interrupt_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_interrupt]
  connect_bd_intf_net -intf_net pcie0_cfg_mgmt_0_1 [get_bd_intf_ports pcie0_cfg_mgmt_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_mgmt]
  connect_bd_intf_net -intf_net pcie0_cfg_msix_0_1 [get_bd_intf_ports pcie0_cfg_msix_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_msix]
  connect_bd_intf_net -intf_net pcie0_s_axis_cc_0_1 [get_bd_intf_ports pcie0_s_axis_cc_0] [get_bd_intf_pins versal_cips_0/pcie0_s_axis_cc]
  connect_bd_intf_net -intf_net pcie0_s_axis_rq_0_1 [get_bd_intf_ports pcie0_s_axis_rq_0] [get_bd_intf_pins versal_cips_0/pcie0_s_axis_rq]
  connect_bd_intf_net -intf_net versal_cips_0_PCIE0_GT [get_bd_intf_ports PCIE0_GT_0] [get_bd_intf_pins versal_cips_0/PCIE0_GT]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_cfg_ext [get_bd_intf_ports pcie0_cfg_ext_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_ext]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_cfg_msg_recd [get_bd_intf_ports pcie0_cfg_msg_recd_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_msg_recd]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_cfg_status [get_bd_intf_ports pcie0_cfg_status_0] [get_bd_intf_pins versal_cips_0/pcie0_cfg_status]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_m_axis_cq [get_bd_intf_ports pcie0_m_axis_cq_0] [get_bd_intf_pins versal_cips_0/pcie0_m_axis_cq]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_m_axis_rc [get_bd_intf_ports pcie0_m_axis_rc_0] [get_bd_intf_pins versal_cips_0/pcie0_m_axis_rc]
  connect_bd_intf_net -intf_net versal_cips_0_pcie0_transmit_fc [get_bd_intf_ports pcie0_transmit_fc_0] [get_bd_intf_pins versal_cips_0/pcie0_transmit_fc]

  # Create port connections
  connect_bd_net -net pcie0_cfg_msix_function_number_0_1 [get_bd_ports pcie0_cfg_msix_function_number_0] [get_bd_pins versal_cips_0/pcie0_cfg_msix_function_number]
  connect_bd_net -net pcie0_cfg_msix_mint_vector_0_1 [get_bd_ports pcie0_cfg_msix_mint_vector_0]
  connect_bd_net -net versal_cips_0_pcie0_cfg_10b_tag_requester_enable [get_bd_ports pcie0_cfg_10b_tag_requester_enable_0] [get_bd_pins versal_cips_0/pcie0_cfg_status_10b_tag_requester_enable]
  connect_bd_net -net versal_cips_0_pcie0_cfg_atomic_requester_enable [get_bd_ports pcie0_cfg_atomic_requester_enable_0] [get_bd_pins versal_cips_0/pcie0_cfg_status_atomic_requester_enable]
  connect_bd_net -net versal_cips_0_pcie0_cfg_ext_tag_enable [get_bd_ports pcie0_cfg_ext_tag_enable_0] [get_bd_pins versal_cips_0/pcie0_cfg_status_ext_tag_enable]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_cpld [get_bd_ports pcie0_cfg_fc_cpld_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_cpld]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_cpldscale [get_bd_ports pcie0_cfg_fc_cpld_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_cpld_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_cplh [get_bd_ports pcie0_cfg_fc_cplh_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_cplh]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_cplhscale [get_bd_ports pcie0_cfg_fc_cplh_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_cplh_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_npd [get_bd_ports pcie0_cfg_fc_npd_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_npd]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_npdscale [get_bd_ports pcie0_cfg_fc_npd_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_npd_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_nph [get_bd_ports pcie0_cfg_fc_nph_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_nph]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_nphscale [get_bd_ports pcie0_cfg_fc_nph_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_nph_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_pd [get_bd_ports pcie0_cfg_fc_pd_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_pd]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_pdscale [get_bd_ports pcie0_cfg_fc_pd_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_pd_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_ph [get_bd_ports pcie0_cfg_fc_ph_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_ph]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_phscale [get_bd_ports pcie0_cfg_fc_ph_scale_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_ph_scale]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_sel [get_bd_ports pcie0_cfg_fc_sel_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_sel]
  connect_bd_net -net versal_cips_0_pcie0_cfg_fc_vc_sel [get_bd_ports pcie0_cfg_fc_vc_sel_0] [get_bd_pins versal_cips_0/pcie0_cfg_fc_vc_sel]
  connect_bd_net -net versal_cips_0_pcie0_user_clk [get_bd_ports pcie0_user_clk_0] [get_bd_pins versal_cips_0/pcie0_user_clk]
  connect_bd_net -net versal_cips_0_pcie0_user_lnk_up [get_bd_ports pcie0_user_lnk_up_0] [get_bd_pins versal_cips_0/pcie0_user_lnk_up]
  connect_bd_net -net versal_cips_0_pcie0_user_reset [get_bd_ports pcie0_user_reset_0] [get_bd_pins versal_cips_0/pcie0_user_reset]
  connect_bd_net -net xdma0_usr_irq_fnc_0_1 [get_bd_ports xdma0_usr_irq_fnc_0]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins logic0/dout] [get_bd_pins versal_cips_0/cpm_irq0] [get_bd_pins versal_cips_0/cpm_irq1]

  # Create address segments

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

open_bd_design [get_bd_files $design_name]
}
