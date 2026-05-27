##################################################################
# EDF BASE 
##################################################################
create_bd_design "$design" -mode batch
instantiate_example_design -template xilinx.com:design:edf_base:1.0 -design $design
 
##################################################################
# DESIGN PROCs
################################################################## 
delete_bd_objs [get_bd_cells ilconstant_1]
disconnect_bd_net /ilconstant_1_dout [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk] [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk] [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk] [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] [get_bd_pins ps_wizard_0/pl_mmi_dc_i2s_s0_clk]

######################## setting comments #######################
set_property USER_COMMENTS.comment_0 {Dual Display (HDMI + DP)- GPU based with num of lanes is X4} [current_bd_design]
#####################################################################


if { [get_files [list hdmi_iob_gnd.v]] == "" } {
  import_files -quiet -fileset sources_1 $currentDir/Dual_Display_GPU/hdmi_iob_gnd.v
}


##################################################################
# DESIGN PROCs DC Non Live
##################################################################


# Hierarchical cell: rst_module
proc create_hier_cell_rst_module { parentCell nameHier } {

  variable script_folder

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -type clk slowest_sync_clk
  create_bd_pin -dir I -type clk slowest_sync_clk1
  create_bd_pin -dir I -type clk slowest_sync_clk2
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir I dcm_locked1

  # Create instance: rst_proc_i2s_clk, and set properties
  set rst_proc_i2s_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_proc_i2s_clk ]
  set_property CONFIG.C_NUM_PERP_ARESETN {1} $rst_proc_i2s_clk


  # Create instance: rst_proc_pl_pixel_clk, and set properties
  set rst_proc_pl_pixel_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_proc_pl_pixel_clk ]
  set_property CONFIG.C_NUM_PERP_ARESETN {1} $rst_proc_pl_pixel_clk


  # Create instance: rst_proc_vid_clk, and set properties
  set rst_proc_vid_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_proc_vid_clk ]
  set_property CONFIG.C_NUM_PERP_ARESETN {1} $rst_proc_vid_clk


  # Create port connections
  connect_bd_net -net PS_0_pl0_resetn  [get_bd_pins ext_reset_in] \
  [get_bd_pins rst_proc_i2s_clk/ext_reset_in] \
  [get_bd_pins rst_proc_pl_pixel_clk/ext_reset_in] \
  [get_bd_pins rst_proc_vid_clk/ext_reset_in]
  connect_bd_net -net clk_wiz_i2s_clk  [get_bd_pins slowest_sync_clk2] \
  [get_bd_pins rst_proc_i2s_clk/slowest_sync_clk]
  connect_bd_net -net clk_wiz_pl_vid_1x_clk  [get_bd_pins slowest_sync_clk] \
  [get_bd_pins rst_proc_vid_clk/slowest_sync_clk]
  connect_bd_net -net dcm_locked1_1  [get_bd_pins dcm_locked1] \
  [get_bd_pins rst_proc_i2s_clk/dcm_locked]
  connect_bd_net -net dcm_locked_1  [get_bd_pins dcm_locked] \
  [get_bd_pins rst_proc_vid_clk/dcm_locked] \
  [get_bd_pins rst_proc_pl_pixel_clk/dcm_locked] 
  connect_bd_net -net mmi_dc_wrap_ip_0_pl_pixel_clk  [get_bd_pins slowest_sync_clk1] \
  [get_bd_pins rst_proc_pl_pixel_clk/slowest_sync_clk]
  connect_bd_net -net rst_proc_vid_clk_peripheral_aresetn  [get_bd_pins rst_proc_vid_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

  # Create ports

  # Create instance: ps_wizard_0, and set properties
  set_property -dict [list \
    CONFIG.MMI_CONFIG(DPDC_PRESENTATION_MODE) {Non_Live} \
    CONFIG.MMI_CONFIG(UDH_GT) {DP_X4} \
    CONFIG.PS11_CONFIG(UDH_GT) {DP_X4} \
  ] [get_bd_cells ps_wizard_0]


  # Create instance: rst_module
  create_hier_cell_rst_module [current_bd_instance .] rst_module

  # Create instance: mmi_vid_clk_wiz, and set properties
  set mmi_vid_clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz mmi_vid_clk_wiz ]
  set_property -dict [list \
    CONFIG.CE_SYNC_EXT {true} \
    CONFIG.CLKOUT_DRIVES {MBUFGCE,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {pl_vid_2x_clk,pl_vid_2x_clk,ps_cfg_clk,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {594,594,230.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.ENABLE_CLOCK_MONITOR {false} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.PRIMITIVE_TYPE {MMCM} \
    CONFIG.USE_DYN_RECONFIG {true} \
  ] $mmi_vid_clk_wiz 

  # Create instance: mmi_aud_clk_wiz, and set properties
  set mmi_aud_clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz mmi_aud_clk_wiz ]
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {i2s_clk_x2,i2s_clk_x1,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {196.608,98.304,100.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,true,false,false,false,false,false} \
    CONFIG.ENABLE_CLOCK_MONITOR {false} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.PRIMITIVE_TYPE {MMCM} \
    CONFIG.USE_DYN_RECONFIG {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
  ] $mmi_aud_clk_wiz


  # Create instance: clk_wizard_enable, and set properties
  set clk_wizard_enable [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio clk_wizard_enable ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00000003} \
    CONFIG.C_GPIO_WIDTH {2} \
  ] $clk_wizard_enable


  # Create instance: ilslice_8, and set properties
  set ilslice_8 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_8 ]
  set_property CONFIG.DIN_WIDTH {2} $ilslice_8


  # Create instance: ilslice_9, and set properties
  set ilslice_9 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_9 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {2} \
  ] $ilslice_9

 
  # Create port connections
  connect_bd_net -net axi_gpio_3_gpio_io_o  [get_bd_pins clk_wizard_enable/gpio_io_o] \
  [get_bd_pins ilslice_9/Din] \
  [get_bd_pins ilslice_8/Din]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] \
  [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk] \
  [get_bd_pins rst_clk/slowest_sync_clk] \
  [get_bd_pins mmi_vid_clk_wiz/s_axi_aclk] \
  [get_bd_pins mmi_vid_clk_wiz/ref_clk] \
  [get_bd_pins mmi_vid_clk_wiz/clk_in1] \
  [get_bd_pins mmi_aud_clk_wiz/s_axi_aclk] \
  [get_bd_pins mmi_aud_clk_wiz/ref_clk] \
  [get_bd_pins mmi_aud_clk_wiz/clk_in1]
  connect_bd_net -net clkx5_wiz_0_locked  [get_bd_pins mmi_vid_clk_wiz/locked] \
  [get_bd_pins rst_module/dcm_locked]
  connect_bd_net [get_bd_pins mmi_vid_clk_wiz/pl_vid_2x_clk_o2] [get_bd_pins rst_module/slowest_sync_clk1] \
  [get_bd_pins rst_module/slowest_sync_clk] \
  [get_bd_pins rst_module/slowest_sync_clk3] \
  [get_bd_pins clk_wizard_enable/s_axi_aclk] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk] 
  connect_bd_net [get_bd_pins mmi_vid_clk_wiz/pl_vid_2x_clk_o1] [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk]
  connect_bd_net -net clkx5_wiz_1_i2s_clk_x1  [get_bd_pins mmi_aud_clk_wiz/i2s_clk_x1] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_i2s_s0_clk]
  connect_bd_net -net dcm_locked1_1  [get_bd_pins mmi_aud_clk_wiz/locked] \
  [get_bd_pins rst_module/dcm_locked1]
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins rst_module/ext_reset_in] \
  [get_bd_pins mmi_aud_clk_wiz/s_axi_aresetn] \
  [get_bd_pins mmi_vid_clk_wiz/s_axi_aresetn]
  connect_bd_net -net ilslice_8_Dout  [get_bd_pins ilslice_8/Dout] \
  [get_bd_pins mmi_vid_clk_wiz/pl_vid_2x_clk_ce]
  connect_bd_net -net ilslice_9_Dout  [get_bd_pins ilslice_9/Dout] \
  [get_bd_pins mmi_vid_clk_wiz/pl_vid_2x_clk_clr_n]
  connect_bd_net -net rst_module_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn] \
  [get_bd_pins clk_wizard_enable/s_axi_aresetn]
  connect_bd_net -net slowest_sync_clk2_1  [get_bd_pins mmi_aud_clk_wiz/i2s_clk_x2] \
  [get_bd_pins rst_module/slowest_sync_clk2]


##################################################################
# DESIGN PROCs
##################################################################
 
 
# Hierarchical cell: vfmc_ctlr_ss_0
proc create_hier_cell_vfmc_ctlr_ss_0 { parentCell nameHier } {
 
  variable script_folder
 
  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_vfmc_ctlr_ss_0() - Empty argument(s)!"}
     return
  }
 
  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }
 
  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }
 
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
 
  # Set parent object as current
  current_bd_instance $parentObj
 
  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj
 
  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
 
 
  # Create pins
  create_bd_pin -dir O -from 0 -to 0 VFMC_TX_CH4_FRLSELn
  create_bd_pin -dir O -from 0 -to 0 VFMC_TX_LED0
  create_bd_pin -dir O -from 0 -to 0 VFMC_TX_LED1
  create_bd_pin -dir O -from 0 -to 0 VFMC_RX_CH4_FRLSELn
  create_bd_pin -dir O -from 0 -to 0 VFMC_RX_LED0
  create_bd_pin -dir O -from 0 -to 0 VFMC_RX_LED1
  create_bd_pin -dir O -from 0 -to 0 VFMC_RX_ONSEMI_ENABLE
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn
 
  # Create instance: vfmc_gpio, and set properties
  set vfmc_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio vfmc_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH {32} \
  ] $vfmc_gpio
 
 
  # Create instance: vfmc_slice_bit0, and set properties
  set vfmc_slice_bit0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice vfmc_slice_bit0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {0} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $vfmc_slice_bit0
 
 
  # Create instance: vfmc_slice_bit1, and set properties
  set vfmc_slice_bit1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice vfmc_slice_bit1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $vfmc_slice_bit1
 
 
  # Create instance: vfmc_slice_bit2, and set properties
  set vfmc_slice_bit2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice vfmc_slice_bit2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {2} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $vfmc_slice_bit2
 
 
  # Create instance: vfmc_slice_bit16, and set properties
  set vfmc_slice_bit16 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice vfmc_slice_bit16 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {16} \
    CONFIG.DIN_TO {16} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $vfmc_slice_bit16
 
 
  # Create instance: vfmc_slice_bit17, and set properties
  set vfmc_slice_bit17 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice vfmc_slice_bit17 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {17} \
    CONFIG.DIN_TO {17} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $vfmc_slice_bit17
 
 
  # Create instance: vfmc_slice_bit18, and set properties
  set vfmc_slice_bit18 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice vfmc_slice_bit18 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {18} \
    CONFIG.DIN_TO {18} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $vfmc_slice_bit18
 
 
  # Create instance: vfmc_slice_bit19, and set properties
  set vfmc_slice_bit19 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice vfmc_slice_bit19 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {19} \
    CONFIG.DIN_TO {19} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $vfmc_slice_bit19
 
 
  # Create interface connections
  connect_bd_intf_net -intf_net intf_net_bdry_in_S_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins vfmc_gpio/S_AXI]
 
  # Create port connections
  connect_bd_net -net net_bdry_in_s_axi_aclk  [get_bd_pins s_axi_aclk] \
  [get_bd_pins vfmc_gpio/s_axi_aclk]
  connect_bd_net -net net_bdry_in_s_axi_aresetn  [get_bd_pins s_axi_aresetn] \
  [get_bd_pins vfmc_gpio/s_axi_aresetn]
  connect_bd_net -net net_vfmc_gpio_gpio_io_o  [get_bd_pins vfmc_gpio/gpio_io_o] \
  [get_bd_pins vfmc_slice_bit0/Din] \
  [get_bd_pins vfmc_slice_bit1/Din] \
  [get_bd_pins vfmc_slice_bit2/Din] \
  [get_bd_pins vfmc_slice_bit16/Din] \
  [get_bd_pins vfmc_slice_bit17/Din] \
  [get_bd_pins vfmc_slice_bit18/Din] \
  [get_bd_pins vfmc_slice_bit19/Din]
  connect_bd_net -net net_vfmc_slice_bit0_Dout  [get_bd_pins vfmc_slice_bit0/Dout] \
  [get_bd_pins VFMC_TX_LED0]
  connect_bd_net -net net_vfmc_slice_bit16_Dout  [get_bd_pins vfmc_slice_bit16/Dout] \
  [get_bd_pins VFMC_RX_LED0]
  connect_bd_net -net net_vfmc_slice_bit17_Dout  [get_bd_pins vfmc_slice_bit17/Dout] \
  [get_bd_pins VFMC_RX_LED1]
  connect_bd_net -net net_vfmc_slice_bit18_Dout  [get_bd_pins vfmc_slice_bit18/Dout] \
  [get_bd_pins VFMC_RX_CH4_FRLSELn]
  connect_bd_net -net net_vfmc_slice_bit19_Dout  [get_bd_pins vfmc_slice_bit19/Dout] \
  [get_bd_pins VFMC_RX_ONSEMI_ENABLE]
  connect_bd_net -net net_vfmc_slice_bit1_Dout  [get_bd_pins vfmc_slice_bit1/Dout] \
  [get_bd_pins VFMC_TX_LED1]
  connect_bd_net -net net_vfmc_slice_bit2_Dout  [get_bd_pins vfmc_slice_bit2/Dout] \
  [get_bd_pins VFMC_TX_CH4_FRLSELn]
 
  # Restore current instance
  current_bd_instance $oldCurInst
}
 
# Hierarchical cell: hdmiphy_ss_0
proc create_hier_cell_hdmiphy_ss_0 { parentCell nameHier } {
 
  variable script_folder
 
  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_hdmiphy_ss_0() - Empty argument(s)!"}
     return
  }
 
  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }
 
  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }
 
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
 
  # Set parent object as current
  current_bd_instance $parentObj
 
  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj
 
  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 phy_data
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_tx_axi4s_ch0
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_tx_axi4s_ch1
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_tx_axi4s_ch2
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_tx_axi4s_ch3
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 vid_phy_axi4lite
 
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_status_sb_tx
 
 
  # Create pins
  create_bd_pin -dir I -type clk tx_ref_clk_in
  create_bd_pin -dir I -type clk tx_ref_clk_odiv2_in
  create_bd_pin -dir I tx_refclk_rdy
  create_bd_pin -dir I -type clk vid_phy_axi4lite_aclk
  create_bd_pin -dir I -type rst vid_phy_axi4lite_aresetn
  create_bd_pin -dir I -type clk drpclk
  create_bd_pin -dir I -type clk vid_phy_sb_aclk
  create_bd_pin -dir I -type rst vid_phy_sb_aresetn
  create_bd_pin -dir I -type rst vid_phy_tx_axi4s_aresetn
  create_bd_pin -dir O -type clk tx_tmds_clk
  create_bd_pin -dir O -type clk tx_video_clk
  create_bd_pin -dir O -type gt_usrclk txoutclk
  create_bd_pin -dir O irq
  create_bd_pin -dir I -type clk dru_ref_clk_in
  create_bd_pin -dir I -type clk dru_ref_clk_odiv2_in
 
  # Create instance: hdmi_gt_controller, and set properties
  set hdmi_gt_controller [ create_bd_cell -type ip -vlnv xilinx.com:ip:hdmi_gt_controller hdmi_gt_controller ]
  set_property -dict [list \
    CONFIG.C_GT_DIRECTION {SIMPLEX_TX} \
    CONFIG.C_NEW_WIZ {1} \
    CONFIG.C_RX_PLL_SELECTION {8} \
    CONFIG.C_RX_REFCLK_SEL {0} \
    CONFIG.C_Rx_Protocol {None} \
    CONFIG.C_TX_FRL_REFCLK_SEL {2} \
    CONFIG.C_TX_PLL_SELECTION {7} \
    CONFIG.C_TX_REFCLK_SEL {1} \
    CONFIG.C_Tx_Protocol {HDMI 2.1} \
    CONFIG.C_Txrefclk_Rdy_Invert {true} \
    CONFIG.Rx_GT_Line_Rate {6.0} \
    CONFIG.Rx_GT_Ref_Clock_Freq {400} \
    CONFIG.Tx_GT_Line_Rate {8.0} \
    CONFIG.Tx_GT_Ref_Clock_Freq {400} \
    CONFIG.Tx_Max_GT_Line_Rate {8.0} \
    CONFIG.check_refclk_selection {0} \
  ] $hdmi_gt_controller
 
 
  # Create instance: urlp, and set properties
  set urlp [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilreduced_logic urlp ]
  set_property CONFIG.C_SIZE {1} $urlp
 
 
  # Create instance: ilcp, and set properties
  set ilcp [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilcp ]
  set_property CONFIG.NUM_PORTS {1} $ilcp
 
 
  # Create instance: bufg_gt_tx, and set properties
  set bufg_gt_tx [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_tx ]
  set_property CONFIG.FREQ_HZ {297000000.0} $bufg_gt_tx
 
 
  # Create instance: gtwiz_versal, and set properties
  set gtwiz_versal [ create_bd_cell -type ip -vlnv xilinx.com:ip:gtwiz_versal gtwiz_versal ]
  set_property -dict [list \
    CONFIG.ENABLE_REG_INTERFACE {false} \
    CONFIG.INTF0_GT_DIRECTION {SIMPLEX_TX} \
    CONFIG.INTF0_GT_SETTINGS(GT_DIRECTION) {SIMPLEX_TX} \
    CONFIG.INTF0_GT_SETTINGS(GT_TYPE) {GTYP} \
    CONFIG.INTF0_GT_SETTINGS(LR0_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R2 TX_USER_DATA_WIDTH 20 TX_INT_DATA_WIDTH 20 TX_LINE_RATE 2.5 TX_REFCLK_FREQUENCY 400.00} \
    CONFIG.INTF0_GT_SETTINGS(LR1_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R1 TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_LINE_RATE 1.625 TX_REFCLK_FREQUENCY 162.5} \
    CONFIG.INTF0_GT_SETTINGS(LR2_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R1 TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_LINE_RATE 2.485 TX_REFCLK_FREQUENCY 248.5} \
    CONFIG.INTF0_GT_SETTINGS(LR3_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R1 TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_LINE_RATE 3.700 TX_REFCLK_FREQUENCY 92.5} \
    CONFIG.INTF0_GT_SETTINGS(LR4_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R1 TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_LINE_RATE 5.94 TX_REFCLK_FREQUENCY 148.5} \
    CONFIG.INTF0_GT_SETTINGS(LR5_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R2 TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_LINE_RATE 3.0 TX_REFCLK_FREQUENCY 400.0} \
    CONFIG.INTF0_GT_SETTINGS(LR6_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R2 TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_LINE_RATE 6.0 TX_REFCLK_FREQUENCY 400.0} \
    CONFIG.INTF0_GT_SETTINGS(LR7_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R2 TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_LINE_RATE 8.0 TX_REFCLK_FREQUENCY 400.0} \
    CONFIG.INTF0_GT_SETTINGS(LR8_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R2 TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_LINE_RATE 8.0 TX_REFCLK_FREQUENCY 400.0} \
    CONFIG.INTF0_GT_SETTINGS(LR9_SETTINGS) {PRESET None GT_DIRECTION SIMPLEX_TX TX_PLL_TYPE LCPLL TX_DATA_ENCODING RAW TX_BUFFER_MODE 1 TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE\
LCPLL TX_LANE_DESKEW_HDMI_ENABLE true TX_REFCLK_SOURCE R2 TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_LINE_RATE 8.0 TX_REFCLK_FREQUENCY 400.0} \
    CONFIG.INTF0_PARENTID {versal_gen2_platform_hdmi_gt_controller_2} \
    CONFIG.INTF_PARENT_PIN_LIST {QUAD0_TX0 /hdmi_ss/hdmiphy_ss_0/hdmi_gt_controller/gt_tx0 QUAD0_TX1 /hdmi_ss/hdmiphy_ss_0/hdmi_gt_controller/gt_tx1 QUAD0_TX2 /hdmi_ss/hdmiphy_ss_0/hdmi_gt_controller/gt_tx2\
QUAD0_TX3 /hdmi_ss/hdmiphy_ss_0/hdmi_gt_controller/gt_tx3} \
    CONFIG.NO_OF_INTERFACE {1} \
    CONFIG.QUAD0_CH0_DEBUG_EN {true} \
    CONFIG.QUAD0_CH0_ILORESETDONE_EN {true} \
    CONFIG.QUAD0_CH1_DEBUG_EN {true} \
    CONFIG.QUAD0_CH1_ILORESETDONE_EN {true} \
    CONFIG.QUAD0_CH2_DEBUG_EN {true} \
    CONFIG.QUAD0_CH2_ILORESETDONE_EN {true} \
    CONFIG.QUAD0_CH3_DEBUG_EN {true} \
    CONFIG.QUAD0_CH3_ILORESETDONE_EN {true} \
    CONFIG.QUAD0_GT_DEBUG_EN {true} \
    CONFIG.QUAD0_HSCLK0_LCPLLRESET_EN {true} \
    CONFIG.QUAD0_HSCLK0_LCPLL_LOCK_EN {true} \
    CONFIG.QUAD0_HSCLK0_RPLLRESET_EN {true} \
    CONFIG.QUAD0_HSCLK0_RPLL_LOCK_EN {true} \
    CONFIG.QUAD0_HSCLK1_LCPLLRESET_EN {true} \
    CONFIG.QUAD0_HSCLK1_LCPLL_LOCK_EN {true} \
    CONFIG.QUAD0_HSCLK1_RPLLRESET_EN {true} \
    CONFIG.QUAD0_HSCLK1_RPLL_LOCK_EN {true} \
    CONFIG.QUAD0_NO_PROT {1} \
    CONFIG.QUAD0_PROT0_TX1_EN {true} \
    CONFIG.QUAD0_PROT0_TX2_EN {true} \
    CONFIG.QUAD0_PROT0_TX3_EN {true} \
    CONFIG.QUAD0_REFCLK_STRING {HSCLK0_LCPLLGTREFCLK1 refclk_PROT0_R1_multiple_ext_freq HSCLK0_LCPLLNORTHREFCLK0 refclk_PROT0_R2_400_MHz_unique1 HSCLK1_LCPLLGTREFCLK1 refclk_PROT0_R1_multiple_ext_freq\
HSCLK1_LCPLLNORTHREFCLK0 refclk_PROT0_R2_400_MHz_unique1} \
  ] $gtwiz_versal
 
  set_property -dict [list \
    CONFIG.INTF0_GT_SETTINGS.VALUE_MODE {auto} \
    CONFIG.INTF0_PARENTID.VALUE_MODE {auto} \
    CONFIG.INTF_PARENT_PIN_LIST.VALUE_MODE {auto} \
  ] $gtwiz_versal
 
 
  # Create interface connections
  connect_bd_intf_net -intf_net intf_net_bdry_in_vid_phy_axi4lite [get_bd_intf_pins vid_phy_axi4lite] [get_bd_intf_pins hdmi_gt_controller/axi4lite]
  connect_bd_intf_net -intf_net intf_net_bdry_in_vid_phy_tx_axi4s_ch0 [get_bd_intf_pins vid_phy_tx_axi4s_ch0] [get_bd_intf_pins hdmi_gt_controller/tx_axi4s_ch0]
  connect_bd_intf_net -intf_net intf_net_bdry_in_vid_phy_tx_axi4s_ch1 [get_bd_intf_pins vid_phy_tx_axi4s_ch1] [get_bd_intf_pins hdmi_gt_controller/tx_axi4s_ch1]
  connect_bd_intf_net -intf_net intf_net_bdry_in_vid_phy_tx_axi4s_ch2 [get_bd_intf_pins vid_phy_tx_axi4s_ch2] [get_bd_intf_pins hdmi_gt_controller/tx_axi4s_ch2]
  connect_bd_intf_net -intf_net intf_net_bdry_in_vid_phy_tx_axi4s_ch3 [get_bd_intf_pins vid_phy_tx_axi4s_ch3] [get_bd_intf_pins hdmi_gt_controller/tx_axi4s_ch3]
  connect_bd_intf_net -intf_net intf_net_gtwiz_versal_Quad0_GT_Serial [get_bd_intf_pins gtwiz_versal/Quad0_GT_Serial] [get_bd_intf_pins phy_data]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_ch0_debug [get_bd_intf_pins hdmi_gt_controller/ch0_debug] [get_bd_intf_pins gtwiz_versal/Quad0_CH0_DEBUG]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_ch1_debug [get_bd_intf_pins hdmi_gt_controller/ch1_debug] [get_bd_intf_pins gtwiz_versal/Quad0_CH1_DEBUG]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_ch2_debug [get_bd_intf_pins hdmi_gt_controller/ch2_debug] [get_bd_intf_pins gtwiz_versal/Quad0_CH2_DEBUG]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_ch3_debug [get_bd_intf_pins hdmi_gt_controller/ch3_debug] [get_bd_intf_pins gtwiz_versal/Quad0_CH3_DEBUG]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_gt_debug [get_bd_intf_pins hdmi_gt_controller/gt_debug] [get_bd_intf_pins gtwiz_versal/QUAD0_GT_DEBUG]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_gt_tx0 [get_bd_intf_pins hdmi_gt_controller/gt_tx0] [get_bd_intf_pins gtwiz_versal/INTF0_TX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_gt_tx1 [get_bd_intf_pins hdmi_gt_controller/gt_tx1] [get_bd_intf_pins gtwiz_versal/INTF0_TX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_gt_tx2 [get_bd_intf_pins hdmi_gt_controller/gt_tx2] [get_bd_intf_pins gtwiz_versal/INTF0_TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_gt_tx3 [get_bd_intf_pins hdmi_gt_controller/gt_tx3] [get_bd_intf_pins gtwiz_versal/INTF0_TX3_GT_IP_Interface]
  connect_bd_intf_net -intf_net intf_net_hdmi_gt_controller_status_sb_tx [get_bd_intf_pins hdmi_gt_controller/status_sb_tx] [get_bd_intf_pins vid_phy_status_sb_tx]
 
  # Create port connections
  connect_bd_net -net net_bdry_in_drpclk  [get_bd_pins drpclk] \
  [get_bd_pins hdmi_gt_controller/apb_clk] \
  [get_bd_pins gtwiz_versal/gtwiz_freerun_clk]
  connect_bd_net -net net_bdry_in_dru_ref_clk_in  [get_bd_pins dru_ref_clk_in] \
  [get_bd_pins gtwiz_versal/QUAD0_GTREFCLK1]
  connect_bd_net -net net_bdry_in_dru_ref_clk_odiv2_in  [get_bd_pins dru_ref_clk_odiv2_in] \
  [get_bd_pins hdmi_gt_controller/gt_refclk2_odiv2]
  connect_bd_net -net net_bdry_in_tx_ref_clk_in  [get_bd_pins tx_ref_clk_in] \
  [get_bd_pins gtwiz_versal/QUAD0_GTREFCLK0]
  connect_bd_net -net net_bdry_in_tx_ref_clk_odiv2_in  [get_bd_pins tx_ref_clk_odiv2_in] \
  [get_bd_pins hdmi_gt_controller/gt_refclk1_odiv2]
  connect_bd_net -net net_bdry_in_tx_refclk_rdy  [get_bd_pins tx_refclk_rdy] \
  [get_bd_pins hdmi_gt_controller/tx_refclk_rdy]
  connect_bd_net -net net_bdry_in_vid_phy_axi4lite_aclk  [get_bd_pins vid_phy_axi4lite_aclk] \
  [get_bd_pins hdmi_gt_controller/axi4lite_aclk]
  connect_bd_net -net net_bdry_in_vid_phy_axi4lite_aresetn  [get_bd_pins vid_phy_axi4lite_aresetn] \
  [get_bd_pins hdmi_gt_controller/axi4lite_aresetn]
  connect_bd_net -net net_bdry_in_vid_phy_sb_aclk  [get_bd_pins vid_phy_sb_aclk] \
  [get_bd_pins hdmi_gt_controller/sb_aclk]
  connect_bd_net -net net_bdry_in_vid_phy_sb_aresetn  [get_bd_pins vid_phy_sb_aresetn] \
  [get_bd_pins hdmi_gt_controller/sb_aresetn]
  connect_bd_net -net net_bdry_in_vid_phy_tx_axi4s_aresetn  [get_bd_pins vid_phy_tx_axi4s_aresetn] \
  [get_bd_pins hdmi_gt_controller/tx_axi4s_aresetn]
  connect_bd_net -net net_bufg_gt_tx_usrclk  [get_bd_pins bufg_gt_tx/usrclk] \
  [get_bd_pins txoutclk] \
  [get_bd_pins gtwiz_versal/QUAD0_TX0_usrclk] \
  [get_bd_pins gtwiz_versal/QUAD0_TX1_usrclk] \
  [get_bd_pins gtwiz_versal/QUAD0_TX2_usrclk] \
  [get_bd_pins gtwiz_versal/QUAD0_TX3_usrclk] \
  [get_bd_pins hdmi_gt_controller/tx_axi4s_aclk] \
  [get_bd_pins hdmi_gt_controller/gt_txusrclk]
  connect_bd_net -net net_gtwiz_versal_INTF0_rst_tx_done_out  [get_bd_pins gtwiz_versal/INTF0_rst_tx_done_out] \
  [get_bd_pins hdmi_gt_controller/tx_full_rst_done]
  connect_bd_net -net net_gtwiz_versal_QUAD0_TX0_outclk  [get_bd_pins gtwiz_versal/QUAD0_TX0_outclk] \
  [get_bd_pins bufg_gt_tx/outclk]
  connect_bd_net -net net_gtwiz_versal_QUAD0_ch0_iloresetdone  [get_bd_pins gtwiz_versal/QUAD0_ch0_iloresetdone] \
  [get_bd_pins hdmi_gt_controller/gt_ch0_ilo_resetdone]
  connect_bd_net -net net_gtwiz_versal_QUAD0_ch1_iloresetdone  [get_bd_pins gtwiz_versal/QUAD0_ch1_iloresetdone] \
  [get_bd_pins hdmi_gt_controller/gt_ch1_ilo_resetdone]
  connect_bd_net -net net_gtwiz_versal_QUAD0_ch2_iloresetdone  [get_bd_pins gtwiz_versal/QUAD0_ch2_iloresetdone] \
  [get_bd_pins hdmi_gt_controller/gt_ch2_ilo_resetdone]
  connect_bd_net -net net_gtwiz_versal_QUAD0_ch3_iloresetdone  [get_bd_pins gtwiz_versal/QUAD0_ch3_iloresetdone] \
  [get_bd_pins hdmi_gt_controller/gt_ch3_ilo_resetdone]
  connect_bd_net -net net_gtwiz_versal_QUAD0_hsclk0_lcplllock  [get_bd_pins gtwiz_versal/QUAD0_hsclk0_lcplllock] \
  [get_bd_pins hdmi_gt_controller/gt_lcpll0_lock]
  connect_bd_net -net net_gtwiz_versal_QUAD0_hsclk1_lcplllock  [get_bd_pins gtwiz_versal/QUAD0_hsclk1_lcplllock] \
  [get_bd_pins hdmi_gt_controller/gt_lcpll1_lock]
  connect_bd_net -net net_gtwiz_versal_gtpowergood  [get_bd_pins gtwiz_versal/gtpowergood] \
  [get_bd_pins ilcp/In0]
  connect_bd_net -net net_hdmi_gt_controller_gt_lcpll0_reset  [get_bd_pins hdmi_gt_controller/gt_lcpll0_reset] \
  [get_bd_pins gtwiz_versal/QUAD0_hsclk0_lcpllreset]
  connect_bd_net -net net_hdmi_gt_controller_gt_lcpll1_reset  [get_bd_pins hdmi_gt_controller/gt_lcpll1_reset] \
  [get_bd_pins gtwiz_versal/QUAD0_hsclk1_lcpllreset]
  connect_bd_net -net net_hdmi_gt_controller_irq  [get_bd_pins hdmi_gt_controller/irq] \
  [get_bd_pins irq]
  connect_bd_net -net net_hdmi_gt_controller_reset_tx_datapath  [get_bd_pins hdmi_gt_controller/reset_tx_datapath] \
  [get_bd_pins gtwiz_versal/INTF0_rst_tx_datapath_in]
  connect_bd_net -net net_hdmi_gt_controller_reset_tx_pll_and_datapath  [get_bd_pins hdmi_gt_controller/reset_tx_pll_and_datapath] \
  [get_bd_pins gtwiz_versal/INTF0_rst_tx_pll_and_datapath_in]
  connect_bd_net -net net_hdmi_gt_controller_tx_full_rst  [get_bd_pins hdmi_gt_controller/tx_full_rst] \
  [get_bd_pins gtwiz_versal/INTF0_rst_all_in]
  connect_bd_net -net net_hdmi_gt_controller_tx_tmds_clk  [get_bd_pins hdmi_gt_controller/tx_tmds_clk] \
  [get_bd_pins tx_tmds_clk]
  connect_bd_net -net net_hdmi_gt_controller_tx_video_clk  [get_bd_pins hdmi_gt_controller/tx_video_clk] \
  [get_bd_pins tx_video_clk]
  connect_bd_net -net net_urlp_Res  [get_bd_pins urlp/Res] \
  [get_bd_pins hdmi_gt_controller/gtpowergood]
  connect_bd_net -net net_ilcp_dout  [get_bd_pins ilcp/dout] \
  [get_bd_pins urlp/Op1]
 
  # Restore current instance
  current_bd_instance $oldCurInst
}
 
# Hierarchical cell: gt_refclk_buf_ss_1
proc create_hier_cell_gt_refclk_buf_ss_1 { parentCell nameHier } {
 
  variable script_folder
 
  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_gt_refclk_buf_ss_1() - Empty argument(s)!"}
     return
  }
 
  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }
 
  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }
 
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
 
  # Set parent object as current
  current_bd_instance $parentObj
 
  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj
 
  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 IBUFDSGT_IN
 
 
  # Create pins
  create_bd_pin -dir O -from 0 -to 0 IBUFDSGT_OUT
  create_bd_pin -dir O -from 0 -to 0 IBUFDSGT_ODIV2_OUT
 
  # Create instance: bufg_gt, and set properties
  set bufg_gt [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf bufg_gt ]
  set_property CONFIG.C_BUF_TYPE {BUFG_GT} $bufg_gt
 
 
  # Create instance: ibufdsgte, and set properties
  set ibufdsgte [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ibufdsgte ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $ibufdsgte
 
 
  # Create instance: vcc_const, and set properties
  set vcc_const [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant vcc_const ]
  set_property CONFIG.CONST_VAL {1} $vcc_const
 
 
  # Create interface connections
  connect_bd_intf_net -intf_net intf_net_bdry_in_IBUFDSGT_IN [get_bd_intf_pins IBUFDSGT_IN] [get_bd_intf_pins ibufdsgte/CLK_IN_D]
 
  # Create port connections
  connect_bd_net -net net_bufg_gt_BUFG_GT_O  [get_bd_pins bufg_gt/BUFG_GT_O] \
  [get_bd_pins IBUFDSGT_ODIV2_OUT]
  connect_bd_net -net net_ibufdsgte_IBUF_DS_ODIV2  [get_bd_pins ibufdsgte/IBUF_DS_ODIV2] \
  [get_bd_pins bufg_gt/BUFG_GT_I]
  connect_bd_net -net net_ibufdsgte_IBUF_OUT  [get_bd_pins ibufdsgte/IBUF_OUT] \
  [get_bd_pins IBUFDSGT_OUT]
  connect_bd_net -net net_vcc_const_dout  [get_bd_pins vcc_const/dout] \
  [get_bd_pins bufg_gt/BUFG_GT_CE]
 
  # Restore current instance
  current_bd_instance $oldCurInst
}
 
# Hierarchical cell: gt_refclk_buf_ss_0
proc create_hier_cell_gt_refclk_buf_ss_0 { parentCell nameHier } {
 
  variable script_folder
 
  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_gt_refclk_buf_ss_0() - Empty argument(s)!"}
     return
  }
 
  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }
 
  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }
 
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
 
  # Set parent object as current
  current_bd_instance $parentObj
 
  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj
 
  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 IBUFDSGT_IN
 
 
  # Create pins
  create_bd_pin -dir O -from 0 -to 0 IBUFDSGT_OUT
  create_bd_pin -dir O -from 0 -to 0 IBUFDSGT_ODIV2_OUT
 
  # Create instance: bufg_gt, and set properties
  set bufg_gt [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf bufg_gt ]
  set_property CONFIG.C_BUF_TYPE {BUFG_GT} $bufg_gt
 
 
  # Create instance: ibufdsgte, and set properties
  set ibufdsgte [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ibufdsgte ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $ibufdsgte
 
 
  # Create instance: vcc_const, and set properties
  set vcc_const [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant vcc_const ]
  set_property CONFIG.CONST_VAL {1} $vcc_const
 
 
  # Create interface connections
  connect_bd_intf_net -intf_net intf_net_bdry_in_IBUFDSGT_IN [get_bd_intf_pins IBUFDSGT_IN] [get_bd_intf_pins ibufdsgte/CLK_IN_D]
 
  # Create port connections
  connect_bd_net -net net_bufg_gt_BUFG_GT_O  [get_bd_pins bufg_gt/BUFG_GT_O] \
  [get_bd_pins IBUFDSGT_ODIV2_OUT]
  connect_bd_net -net net_ibufdsgte_IBUF_DS_ODIV2  [get_bd_pins ibufdsgte/IBUF_DS_ODIV2] \
  [get_bd_pins bufg_gt/BUFG_GT_I]
  connect_bd_net -net net_ibufdsgte_IBUF_OUT  [get_bd_pins ibufdsgte/IBUF_OUT] \
  [get_bd_pins IBUFDSGT_OUT]
  connect_bd_net -net net_vcc_const_dout  [get_bd_pins vcc_const/dout] \
  [get_bd_pins bufg_gt/BUFG_GT_CE]
 
  # Restore current instance
  current_bd_instance $oldCurInst
}
 
# Hierarchical cell: vmix_ss
proc create_hier_cell_vmix_ss { parentCell nameHier } {
 
  variable script_folder
 
  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_vmix_ss() - Empty argument(s)!"}
     return
  }
 
  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }
 
  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }
 
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
 
  # Set parent object as current
  current_bd_instance $parentObj
 
  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj
 
  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axit_ctrl_vmix_gpio
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl_vmix
 
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 vmix_M00_INI
 
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 vmix_M01_INI
 
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_vmix_video_out
 
 
  # Create pins
  create_bd_pin -dir I -type clk s_axis_video_aclk
  create_bd_pin -dir I -type rst s_axis_video_aresetn
  create_bd_pin -dir O -type intr mixer_irq
 
  # Create instance: ilconstant_1, and set properties
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_1 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {96} \
  ] $ilconstant_1
 
 
  # Create instance: vmix_rst_gpio, and set properties
  set vmix_rst_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio vmix_rst_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00000003} \
    CONFIG.C_GPIO_WIDTH {2} \
  ] $vmix_rst_gpio
 
 
  # Create instance: v_mix, and set properties
  set v_mix [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_mix v_mix ]
  set_property -dict [list \
    CONFIG.AXIMM_ADDR_WIDTH {64} \
    CONFIG.AXIMM_DATA_WIDTH {256} \
    CONFIG.LAYER1_ALPHA {true} \
    CONFIG.LAYER1_INTF_TYPE {0} \
    CONFIG.LAYER1_VIDEO_FORMAT {20} \
    CONFIG.LAYER2_ALPHA {true} \
    CONFIG.LAYER2_INTF_TYPE {0} \
    CONFIG.LAYER2_VIDEO_FORMAT {27} \
    CONFIG.LAYER3_ALPHA {true} \
    CONFIG.LAYER3_INTF_TYPE {0} \
    CONFIG.LAYER3_VIDEO_FORMAT {20} \
    CONFIG.LAYER4_ALPHA {true} \
    CONFIG.LAYER4_INTF_TYPE {0} \
    CONFIG.LAYER4_VIDEO_FORMAT {20} \
    CONFIG.LAYER5_ALPHA {true} \
    CONFIG.LAYER5_INTF_TYPE {0} \
    CONFIG.LAYER5_VIDEO_FORMAT {20} \
    CONFIG.LAYER6_ALPHA {true} \
    CONFIG.LAYER6_INTF_TYPE {0} \
    CONFIG.LAYER6_VIDEO_FORMAT {20} \
    CONFIG.MAX_DATA_WIDTH {8} \
    CONFIG.NR_LAYERS {3} \
    CONFIG.SAMPLES_PER_CLOCK {4} \
    CONFIG.VIDEO_FORMAT {0} \
  ] $v_mix
 
 
  # Create instance: ilslice_vmix_gpio, and set properties
  set ilslice_vmix_gpio [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_vmix_gpio ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {2} \
  ] $ilslice_vmix_gpio
 
 
  # Create instance: axi_noc2_frmbuf, and set properties
  set axi_noc2_frmbuf [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_frmbuf ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {2} \
    CONFIG.NUM_SI {2} \
  ] $axi_noc2_frmbuf
 
 
  set_property -dict [ list \
   CONFIG.R_TRAFFIC_CLASS {ISOCHRONOUS} \
   CONFIG.CONNECTIONS {  M00_INI {read_bw {2000} write_bw {100}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /vmix_ss/axi_noc2_frmbuf/S00_AXI]
 
  set_property -dict [ list \
   CONFIG.R_TRAFFIC_CLASS {ISOCHRONOUS} \
   CONFIG.CONNECTIONS {  M01_INI {read_bw {2000} write_bw {100}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /vmix_ss/axi_noc2_frmbuf/S01_AXI]
 
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI:S01_AXI} \
 ] [get_bd_pins /vmix_ss/axi_noc2_frmbuf/aclk0]
 
  # Create interface connections
  connect_bd_intf_net -intf_net Conn0 [get_bd_intf_pins axi_noc2_frmbuf/M00_INI] [get_bd_intf_pins vmix_M00_INI]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins axi_noc2_frmbuf/M01_INI] [get_bd_intf_pins vmix_M01_INI]
  connect_bd_intf_net -intf_net s_axi_ctrl_vmix_1 [get_bd_intf_pins s_axi_ctrl_vmix] [get_bd_intf_pins v_mix/s_axi_CTRL]
  connect_bd_intf_net -intf_net s_axit_ctrl_vmix_gpio_1 [get_bd_intf_pins s_axit_ctrl_vmix_gpio] [get_bd_intf_pins vmix_rst_gpio/S_AXI]
  connect_bd_intf_net -intf_net v_mix_m_axi_mm_video1 [get_bd_intf_pins v_mix/m_axi_mm_video1] [get_bd_intf_pins axi_noc2_frmbuf/S00_AXI]
  connect_bd_intf_net -intf_net v_mix_m_axi_mm_video2 [get_bd_intf_pins v_mix/m_axi_mm_video2] [get_bd_intf_pins axi_noc2_frmbuf/S01_AXI]
  connect_bd_intf_net -intf_net v_mix_m_axis_video [get_bd_intf_pins m_axis_vmix_video_out] [get_bd_intf_pins v_mix/m_axis_video]
 
  # Create port connections
  connect_bd_net -net s_axis_video_aclk_1  [get_bd_pins s_axis_video_aclk] \
  [get_bd_pins axi_noc2_frmbuf/aclk0] \
  [get_bd_pins v_mix/ap_clk] \
  [get_bd_pins vmix_rst_gpio/s_axi_aclk]
  connect_bd_net -net s_axis_video_aresetn_1  [get_bd_pins s_axis_video_aresetn] \
  [get_bd_pins vmix_rst_gpio/s_axi_aresetn]
  connect_bd_net -net v_mix_interrupt  [get_bd_pins v_mix/interrupt] \
  [get_bd_pins mixer_irq]
  connect_bd_net -net vmix_rst_gpio_gpio_io_o  [get_bd_pins vmix_rst_gpio/gpio_io_o] \
  [get_bd_pins ilslice_vmix_gpio/Din]
  connect_bd_net -net ilconstant_1_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins v_mix/s_axis_video_TVALID] \
  [get_bd_pins v_mix/s_axis_video_TDATA]
  connect_bd_net -net ilslice_vmix_gpio_Dout  [get_bd_pins ilslice_vmix_gpio/Dout] \
  [get_bd_pins v_mix/ap_rst_n]
 
  # Restore current instance
  current_bd_instance $oldCurInst
}
 
# Hierarchical cell: hdmi_ss
proc create_hier_cell_hdmi_ss { parentCell nameHier } {
 
  variable script_folder
 
  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_hdmi_ss() - Empty argument(s)!"}
     return
  }
 
  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }
 
  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }
 
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
 
  # Set parent object as current
  current_bd_instance $parentObj
 
  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj
 
  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CPU_IN
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 VIDEO_IN
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_IIC
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 GT_DRU_FRL_CLK_IN
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 TX_REFCLK_P_IN_V
 
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 vid_phy_axi4lite
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_VFMC
 
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_TIMER
 
 
  # Create pins
  create_bd_pin -dir I -type clk vid_phy_sb_aclk
  create_bd_pin -dir I -type rst vid_phy_sb_aresetn
  create_bd_pin -dir I TX_HPD_IN
  create_bd_pin -dir O -type intr hdmi_tx_irq
  create_bd_pin -dir O LED0
  create_bd_pin -dir I -type clk s_axis_video_aclk
  create_bd_pin -dir I -type rst s_axis_video_aresetn
  create_bd_pin -dir I IDT8T49N241_LOL_IN
  create_bd_pin -dir O vphy_irq
  create_bd_pin -dir O -from 0 -to 0 TX_TI_ENABLE
  create_bd_pin -dir O -from 0 -to 0 RX_TI_ENABLE
  create_bd_pin -dir O -type intr timer_irq
  create_bd_pin -dir O -type intr iic_irq
  create_bd_pin -dir IO TX_DDC_OUT_scl_io
  create_bd_pin -dir IO TX_DDC_OUT_sda_io
  create_bd_pin -dir IO HDMI_CTRL_scl_io
  create_bd_pin -dir IO HDMI_CTRL_sda_io
 
  # Create instance: v_hdmi_txss1, and set properties
  set v_hdmi_txss1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_hdmi_txss1 v_hdmi_txss1 ]
  set_property -dict [list \
    CONFIG.C_ADDR_WIDTH {10} \
    CONFIG.C_ADD_CORE_DBG {0} \
    CONFIG.C_ADD_MARK_DBG {false} \
    CONFIG.C_DYNAMIC_HDR {0} \
    CONFIG.C_EXDES_RX_PLL_SELECTION {8} \
    CONFIG.C_EXDES_TX_PLL_SELECTION {7} \
    CONFIG.C_HDMI_VERSION {4} \
    CONFIG.C_HPD_INVERT {true} \
    CONFIG.C_HYSTERESIS_LEVEL {511} \
    CONFIG.C_INCLUDE_HDCP {false} \
    CONFIG.C_INCLUDE_HDCP_1_4 {false} \
    CONFIG.C_INCLUDE_HDCP_2_2 {false} \
    CONFIG.C_INCLUDE_LOW_RESO_VID {true} \
    CONFIG.C_INCLUDE_YUV420_SUP {true} \
    CONFIG.C_INPUT_PIXELS_PER_CLOCK {4} \
    CONFIG.C_MAX_BITS_PER_COMPONENT {8} \
    CONFIG.C_NUM_OF_GT_LANE {4} \
    CONFIG.C_VALIDATION_ENABLE {false} \
    CONFIG.C_VIDEO_MASK_ENABLE {1} \
    CONFIG.C_VID_INTERFACE {0} \
    CONFIG.C_VRR_SUPPORT {1} \
  ] $v_hdmi_txss1
 
 
  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]
  set_property CONFIG.CONST_VAL {0} $ilconstant_0
 
 
  # Create instance: vcc_const, and set properties
  set vcc_const [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant vcc_const ]
  set_property CONFIG.CONST_VAL {1} $vcc_const
 
 
  # Create instance: axi_iic_hdmi, and set properties
  set axi_iic_hdmi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_hdmi ]
  set_property CONFIG.TEN_BIT_ADR {7_bit} $axi_iic_hdmi
 
 
  # Create instance: gt_refclk_buf_ss_0
  create_hier_cell_gt_refclk_buf_ss_0 $hier_obj gt_refclk_buf_ss_0
 
  # Create instance: gt_refclk_buf_ss_1
  create_hier_cell_gt_refclk_buf_ss_1 $hier_obj gt_refclk_buf_ss_1
 
  # Create instance: hdmiphy_ss_0
  create_hier_cell_hdmiphy_ss_0 $hier_obj hdmiphy_ss_0
 
  # Create instance: vfmc_ctlr_ss_0
  create_hier_cell_vfmc_ctlr_ss_0 $hier_obj vfmc_ctlr_ss_0
 
  # Create instance: axi_timer_hdmi, and set properties
  set axi_timer_hdmi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_hdmi ]
  set_property CONFIG.COUNT_WIDTH {32} $axi_timer_hdmi
 
 
  # Create instance: clkx5_wiz_hdmi, and set properties
  set clkx5_wiz_hdmi [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clkx5_wiz_hdmi ]
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {450,100.000,100.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.PRIM_SOURCE {No_buffer} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.USE_RESET {true} \
  ] $clkx5_wiz_hdmi
 
 
  # Create instance: hdmi_iob_gnd_0, and set properties
  set block_name hdmi_iob_gnd
  set block_cell_name hdmi_iob_gnd_0
  if { [catch {set hdmi_iob_gnd_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hdmi_iob_gnd_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins S_AXI_TIMER] [get_bd_intf_pins axi_timer_hdmi/S_AXI]
  connect_bd_intf_net -intf_net cips_ss_0_M07_AXI1 [get_bd_intf_pins S_AXI_IIC] [get_bd_intf_pins axi_iic_hdmi/S_AXI]
  connect_bd_intf_net -intf_net intf_net_bdry_in_GT_DRU_FRL_CLK_IN [get_bd_intf_pins GT_DRU_FRL_CLK_IN] [get_bd_intf_pins gt_refclk_buf_ss_0/IBUFDSGT_IN]
  connect_bd_intf_net -intf_net intf_net_bdry_in_TX_REFCLK_P_IN_V [get_bd_intf_pins TX_REFCLK_P_IN_V] [get_bd_intf_pins gt_refclk_buf_ss_1/IBUFDSGT_IN]
  connect_bd_intf_net -intf_net intf_net_cips_ss_0_M00_AXI [get_bd_intf_pins vid_phy_axi4lite] [get_bd_intf_pins hdmiphy_ss_0/vid_phy_axi4lite]
  connect_bd_intf_net -intf_net intf_net_cips_ss_0_M02_AXI [get_bd_intf_pins S_AXI_CPU_IN] [get_bd_intf_pins v_hdmi_txss1/S_AXI_CPU_IN]
  connect_bd_intf_net -intf_net intf_net_cips_ss_0_M08_AXI [get_bd_intf_pins S_AXI_VFMC] [get_bd_intf_pins vfmc_ctlr_ss_0/S_AXI]
  connect_bd_intf_net -intf_net intf_net_hdmiphy_ss_0_phy_data [get_bd_intf_pins GT_Serial] [get_bd_intf_pins hdmiphy_ss_0/phy_data]
  connect_bd_intf_net -intf_net intf_net_hdmiphy_ss_0_vid_phy_status_sb_tx [get_bd_intf_pins hdmiphy_ss_0/vid_phy_status_sb_tx] [get_bd_intf_pins v_hdmi_txss1/SB_STATUS_IN]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_txss1_LINK_DATA0_OUT [get_bd_intf_pins v_hdmi_txss1/LINK_DATA0_OUT] [get_bd_intf_pins hdmiphy_ss_0/vid_phy_tx_axi4s_ch0]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_txss1_LINK_DATA1_OUT [get_bd_intf_pins v_hdmi_txss1/LINK_DATA1_OUT] [get_bd_intf_pins hdmiphy_ss_0/vid_phy_tx_axi4s_ch1]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_txss1_LINK_DATA2_OUT [get_bd_intf_pins v_hdmi_txss1/LINK_DATA2_OUT] [get_bd_intf_pins hdmiphy_ss_0/vid_phy_tx_axi4s_ch2]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_txss1_LINK_DATA3_OUT [get_bd_intf_pins v_hdmi_txss1/LINK_DATA3_OUT] [get_bd_intf_pins hdmiphy_ss_0/vid_phy_tx_axi4s_ch3]
  connect_bd_intf_net -intf_net vmix_ss_m_axis_video [get_bd_intf_pins VIDEO_IN] [get_bd_intf_pins v_hdmi_txss1/VIDEO_IN]
 
  # Create port connections
  connect_bd_net -net Net  [get_bd_pins TX_DDC_OUT_scl_io] \
  [get_bd_pins hdmi_iob_gnd_0/TX_DDC_OUT_scl_io]
  connect_bd_net -net Net1  [get_bd_pins TX_DDC_OUT_sda_io] \
  [get_bd_pins hdmi_iob_gnd_0/TX_DDC_OUT_sda_io]
  connect_bd_net -net Net2  [get_bd_pins HDMI_CTRL_scl_io] \
  [get_bd_pins hdmi_iob_gnd_0/HDMI_CTRL_scl_io]
  connect_bd_net -net Net3  [get_bd_pins HDMI_CTRL_sda_io] \
  [get_bd_pins hdmi_iob_gnd_0/HDMI_CTRL_sda_io]
  connect_bd_net -net axi_iic_hdmi_iic2intc_irpt  [get_bd_pins axi_iic_hdmi/iic2intc_irpt] \
  [get_bd_pins iic_irq]
  connect_bd_net -net axi_iic_hdmi_scl_t  [get_bd_pins axi_iic_hdmi/scl_t] \
  [get_bd_pins hdmi_iob_gnd_0/HDMI_CTRL_scl_t]
  connect_bd_net -net axi_iic_hdmi_sda_t  [get_bd_pins axi_iic_hdmi/sda_t] \
  [get_bd_pins hdmi_iob_gnd_0/HDMI_CTRL_sda_t]
  connect_bd_net -net axi_timer_hdmi_interrupt  [get_bd_pins axi_timer_hdmi/interrupt] \
  [get_bd_pins timer_irq]
  connect_bd_net -net clkx5_wiz_hdmi_clk_out1  [get_bd_pins clkx5_wiz_hdmi/clk_out1] \
  [get_bd_pins v_hdmi_txss1/frl_clk]
  connect_bd_net -net hdmi_iob_gnd_0_HDMI_CTRL_scl_i  [get_bd_pins hdmi_iob_gnd_0/HDMI_CTRL_scl_i] \
  [get_bd_pins axi_iic_hdmi/scl_i]
  connect_bd_net -net hdmi_iob_gnd_0_HDMI_CTRL_sda_i  [get_bd_pins hdmi_iob_gnd_0/HDMI_CTRL_sda_i] \
  [get_bd_pins axi_iic_hdmi/sda_i]
  connect_bd_net -net hdmi_iob_gnd_0_TX_DDC_OUT_scl_i  [get_bd_pins hdmi_iob_gnd_0/TX_DDC_OUT_scl_i] \
  [get_bd_pins v_hdmi_txss1/DDC_OUT_scl_i]
  connect_bd_net -net hdmi_iob_gnd_0_TX_DDC_OUT_sda_i  [get_bd_pins hdmi_iob_gnd_0/TX_DDC_OUT_sda_i] \
  [get_bd_pins v_hdmi_txss1/DDC_OUT_sda_i]
  connect_bd_net -net net_bdry_in_IDT8T49N241_LOL_IN  [get_bd_pins IDT8T49N241_LOL_IN] \
  [get_bd_pins hdmiphy_ss_0/tx_refclk_rdy]
  connect_bd_net -net net_bdry_in_TX_HPD_IN  [get_bd_pins TX_HPD_IN] \
  [get_bd_pins v_hdmi_txss1/hpd]
 
  connect_bd_net -net net_cips_ss_0_clk_out2  [get_bd_pins s_axis_video_aclk] \
  [get_bd_pins v_hdmi_txss1/s_axis_video_aclk]
  connect_bd_net -net net_cips_ss_0_dcm_locked  [get_bd_pins s_axis_video_aresetn] \
  [get_bd_pins v_hdmi_txss1/s_axis_video_aresetn]
  connect_bd_net -net net_cips_ss_0_peripheral_aresetn  [get_bd_pins vid_phy_sb_aresetn] \
  [get_bd_pins hdmiphy_ss_0/vid_phy_sb_aresetn] \
  [get_bd_pins hdmiphy_ss_0/vid_phy_axi4lite_aresetn] \
  [get_bd_pins vfmc_ctlr_ss_0/s_axi_aresetn] \
  [get_bd_pins axi_iic_hdmi/s_axi_aresetn] \
  [get_bd_pins axi_timer_hdmi/s_axi_aresetn] \
  [get_bd_pins clkx5_wiz_hdmi/resetn] \
  [get_bd_pins v_hdmi_txss1/s_axi_cpu_aresetn]
  connect_bd_net -net net_cips_ss_0_s_axi_aclk  [get_bd_pins vid_phy_sb_aclk] \
  [get_bd_pins hdmiphy_ss_0/vid_phy_sb_aclk] \
  [get_bd_pins hdmiphy_ss_0/vid_phy_axi4lite_aclk] \
  [get_bd_pins vfmc_ctlr_ss_0/s_axi_aclk] \
  [get_bd_pins hdmiphy_ss_0/drpclk] \
  [get_bd_pins axi_iic_hdmi/s_axi_aclk] \
  [get_bd_pins axi_timer_hdmi/s_axi_aclk] \
  [get_bd_pins clkx5_wiz_hdmi/clk_in1] \
  [get_bd_pins v_hdmi_txss1/s_axi_cpu_aclk]
  connect_bd_net -net net_gt_refclk_buf_ss_0_IBUFDSGT_ODIV2_OUT  [get_bd_pins gt_refclk_buf_ss_0/IBUFDSGT_ODIV2_OUT] \
  [get_bd_pins hdmiphy_ss_0/dru_ref_clk_odiv2_in]
  connect_bd_net -net net_gt_refclk_buf_ss_0_IBUFDSGT_OUT  [get_bd_pins gt_refclk_buf_ss_0/IBUFDSGT_OUT] \
  [get_bd_pins hdmiphy_ss_0/dru_ref_clk_in]
  connect_bd_net -net net_gt_refclk_buf_ss_1_IBUFDSGT_ODIV2_OUT  [get_bd_pins gt_refclk_buf_ss_1/IBUFDSGT_ODIV2_OUT] \
  [get_bd_pins hdmiphy_ss_0/tx_ref_clk_odiv2_in]
  connect_bd_net -net net_gt_refclk_buf_ss_1_IBUFDSGT_OUT  [get_bd_pins gt_refclk_buf_ss_1/IBUFDSGT_OUT] \
  [get_bd_pins hdmiphy_ss_0/tx_ref_clk_in]
  connect_bd_net -net net_hdmiphy_ss_0_irq  [get_bd_pins hdmiphy_ss_0/irq] \
  [get_bd_pins vphy_irq]
  connect_bd_net -net net_hdmiphy_ss_0_tx_video_clk  [get_bd_pins hdmiphy_ss_0/tx_video_clk] \
  [get_bd_pins v_hdmi_txss1/video_clk]
  connect_bd_net -net net_hdmiphy_ss_0_txoutclk  [get_bd_pins hdmiphy_ss_0/txoutclk] \
  [get_bd_pins v_hdmi_txss1/link_clk]
  connect_bd_net -net net_v_hdmi_txss1_irq  [get_bd_pins v_hdmi_txss1/irq] \
  [get_bd_pins hdmi_tx_irq]
  connect_bd_net -net net_v_hdmi_txss1_locked  [get_bd_pins v_hdmi_txss1/locked] \
  [get_bd_pins LED0]
  connect_bd_net -net net_vcc_const_dout  [get_bd_pins vcc_const/dout] \
  [get_bd_pins hdmiphy_ss_0/vid_phy_tx_axi4s_aresetn] \
  [get_bd_pins v_hdmi_txss1/video_cke_in]
  connect_bd_net -net net_vfmc_ctlr_ss_0_VFMC_RX_ONSEMI_ENABLE  [get_bd_pins vfmc_ctlr_ss_0/VFMC_RX_ONSEMI_ENABLE] \
  [get_bd_pins TX_TI_ENABLE] \
  [get_bd_pins RX_TI_ENABLE]
  connect_bd_net -net v_hdmi_txss1_DDC_OUT_scl_t  [get_bd_pins v_hdmi_txss1/DDC_OUT_scl_t] \
  [get_bd_pins hdmi_iob_gnd_0/TX_DDC_OUT_scl_t]
  connect_bd_net -net v_hdmi_txss1_DDC_OUT_sda_t  [get_bd_pins v_hdmi_txss1/DDC_OUT_sda_t] \
  [get_bd_pins hdmi_iob_gnd_0/TX_DDC_OUT_sda_t]
  connect_bd_net -net ilconstant_0_dout  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins v_hdmi_txss1/s_axis_audio_aclk] \
  [get_bd_pins v_hdmi_txss1/fid]
 
  # Restore current instance
  current_bd_instance $oldCurInst
}
 
 
# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {
 
  variable script_folder
  variable design_name
  variable currentDir
 
  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }
 
  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }
 
  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }
 
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
 
  # Set parent object as current
  current_bd_instance $parentObj
 
# VCU connections 
#VCU configuraton 
set_property CONFIG.NSU_ONLY {false} [get_bd_cells VCU_hier/vcu2_0]
set_property CONFIG.C0_ENC_ENABLE_LOW_LATENCY_MODE {true} [get_bd_cells VCU_hier/vcu2_0]
 
 
##axi gpio 
 
 set vcu_gpio_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio vcu_gpio_reset ]
 set_property -dict [list \
  CONFIG.C_ALL_OUTPUTS {1} \
  CONFIG.C_DOUT_DEFAULT {0x0000000F} \
  CONFIG.C_GPIO_WIDTH {4} \
] [get_bd_cells vcu_gpio_reset]
 
  # Create instance: ilslice_vcu_dpll_rst_n, and set properties
  set ilslice_vcu_dpll_rst_n [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_vcu_dpll_rst_n ]
  set_property -dict [list \
    CONFIG.DIN_FROM {3} \
    CONFIG.DIN_TO {3} \
    CONFIG.DIN_WIDTH {4} \
  ] $ilslice_vcu_dpll_rst_n
 
 
  # Create instance: ilslice_vcu_enc_rst_n, and set properties
  set ilslice_vcu_enc_rst_n [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_vcu_enc_rst_n ]
  set_property CONFIG.DIN_WIDTH {4} $ilslice_vcu_enc_rst_n
 
 
  # Create instance: ilslice_vcu_raw_rst_n, and set properties
  set ilslice_vcu_raw_rst_n [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_vcu_raw_rst_n ]
  set_property -dict [list \
    CONFIG.DIN_FROM {2} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {4} \
  ] $ilslice_vcu_raw_rst_n
 
 # Create instance: ilslice_vcu_dec_rst_n, and set properties
  set ilslice_vcu_dec_rst_n [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_vcu_dec_rst_n ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {4} \
  ] $ilslice_vcu_dec_rst_n
 
#Smart connect instantiation 
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
set_property name vcu_smc [get_bd_cells smartconnect_0]
set_property CONFIG.NUM_MI {2} [get_bd_cells vcu_smc]
set_property CONFIG.NUM_SI {1} [get_bd_cells vcu_smc]
 
# clocking wizard
  set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clk_wizard_0 ]
set_property -dict [list \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.USE_PHASE_ALIGNMENT {true} \
  CONFIG.USE_RESET {true} \
] [get_bd_cells clk_wizard_0]
 
# Processing system reset
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
set_property name rst_clk [get_bd_cells proc_sys_reset_0]
 
#agggr_noc
set_property -dict [list \
  CONFIG.NUM_CLKS {6} \
  CONFIG.NUM_SI {6} \
  CONFIG.NUM_NSI {0} \
] [get_bd_cells aggr_noc]
set_property -dict [list CONFIG.CATEGORY {vcu} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /aggr_noc/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {vcu} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /aggr_noc/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {vcu} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /aggr_noc/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {vcu} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /aggr_noc/S03_AXI]
#set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} initial_boot {false} } M03_INI {read_bw {500} write_bw {500} initial_boot {false} } M00_INI {read_bw {500} write_bw {500} initial_boot {false} }}] [get_bd_intf_pins /aggr_noc/S00_INI]
#set_property -dict [list CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {false} } M04_INI {read_bw {500} write_bw {500} initial_boot {false} } M00_INI {read_bw {500} write_bw {500} initial_boot {false} }}] [get_bd_intf_pins /aggr_noc/S01_INI]
set_property -dict [list CONFIG.CATEGORY {isp} CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M03_INI {read_bw {500} write_bw {500} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /aggr_noc/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {isp} CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} } M04_INI {read_bw {500} write_bw {500} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /aggr_noc/S05_AXI]

#N0C C0_C1
set_property -dict [list \
CONFIG.NUM_NSI {7} \
] [get_bd_cells NoC_C0_C1] 

set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /NoC_C0_C1/S05_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /NoC_C0_C1/S06_INI]

# placing gpio and slicing inside vcu hier
move_bd_cells [get_bd_cells VCU_hier] [get_bd_cells vcu_gpio_reset]
move_bd_cells [get_bd_cells VCU_hier] [get_bd_cells ilslice_vcu_dec_rst_n]
move_bd_cells [get_bd_cells VCU_hier] [get_bd_cells ilslice_vcu_dpll_rst_n]
move_bd_cells [get_bd_cells VCU_hier] [get_bd_cells ilslice_vcu_raw_rst_n]
move_bd_cells [get_bd_cells VCU_hier] [get_bd_cells ilslice_vcu_enc_rst_n]
 
 
 
 
 
 
 
# connections 
connect_bd_intf_net [get_bd_intf_pins VCU_hier/vcu2_0/S_AXI_LITE] [get_bd_intf_pins vcu_smc/M00_AXI]
connect_bd_intf_net [get_bd_intf_pins vcu_smc/M01_AXI] [get_bd_intf_pins VCU_hier/vcu_gpio_reset/S_AXI]
connect_bd_net [get_bd_pins VCU_hier/vcu2_0/c0_irq_error] [get_bd_pins ps_wizard_0/pl_fpd_irq1]
connect_bd_net [get_bd_pins VCU_hier/vcu2_0/c0_irq_dec_pintreq] [get_bd_pins ps_wizard_0/pl_fpd_irq2]
connect_bd_net [get_bd_pins VCU_hier/vcu2_0/c0_irq_enc_pintreq] [get_bd_pins ps_wizard_0/pl_fpd_irq3]
connect_bd_net [get_bd_pins VCU_hier/vcu2_0/dpll_ref_clk] [get_bd_pins ps_wizard_0/pl1_ref_clk]
connect_bd_net [get_bd_pins VCU_hier/ilslice_vcu_dec_rst_n/Dout] [get_bd_pins VCU_hier/vcu2_0/c0_pl_dec_rst_n]
connect_bd_net [get_bd_pins VCU_hier/ilslice_vcu_dpll_rst_n/Dout] [get_bd_pins VCU_hier/vcu2_0/c0_dpll_rst_n]
connect_bd_net [get_bd_pins VCU_hier/ilslice_vcu_raw_rst_n/Dout] [get_bd_pins VCU_hier/vcu2_0/c0_raw_rst_n]
connect_bd_net [get_bd_pins VCU_hier/ilslice_vcu_enc_rst_n/Dout] [get_bd_pins VCU_hier/vcu2_0/c0_pl_enc_rst_n]
connect_bd_net [get_bd_pins VCU_hier/vcu_gpio_reset/gpio_io_o] [get_bd_pins VCU_hier/ilslice_vcu_enc_rst_n/Din]
connect_bd_net [get_bd_pins VCU_hier/vcu_gpio_reset/gpio_io_o] [get_bd_pins VCU_hier/ilslice_vcu_raw_rst_n/Din]
connect_bd_net [get_bd_pins VCU_hier/vcu_gpio_reset/gpio_io_o] [get_bd_pins VCU_hier/ilslice_vcu_dec_rst_n/Din]
connect_bd_net [get_bd_pins VCU_hier/vcu_gpio_reset/gpio_io_o] [get_bd_pins VCU_hier/ilslice_vcu_dpll_rst_n/Din]
connect_bd_net [get_bd_pins clk_wizard_0/clk_in1] [get_bd_pins ps_wizard_0/pl0_ref_clk]
connect_bd_net [get_bd_pins clk_wizard_0/resetn] [get_bd_pins ps_wizard_0/pl0_resetn]
connect_bd_net [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins VCU_hier/vcu_gpio_reset/s_axi_aclk]
connect_bd_net [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins vcu_smc/aclk]
connect_bd_net [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins VCU_hier/vcu2_0/s_axi_lite_clk]
connect_bd_net [get_bd_pins rst_clk/slowest_sync_clk] [get_bd_pins clk_wizard_0/clk_out1]
connect_bd_net [get_bd_pins rst_clk/ext_reset_in] [get_bd_pins ps_wizard_0/pl0_resetn]
connect_bd_net [get_bd_pins rst_clk/dcm_locked] [get_bd_pins clk_wizard_0/locked]
connect_bd_net [get_bd_pins rst_clk/peripheral_aresetn] [get_bd_pins VCU_hier/vcu_gpio_reset/s_axi_aresetn]
connect_bd_net [get_bd_pins rst_clk/peripheral_aresetn] [get_bd_pins vcu_smc/aresetn]
connect_bd_net [get_bd_pins rst_clk/peripheral_aresetn] [get_bd_pins VCU_hier/vcu2_0/s_axi_lite_rst_n]
#disconnect_bd_net /ilconstant_1_dout [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk]
#connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] [get_bd_pins clk_wizard_0/clk_out1]
#connect_bd_net [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk] [get_bd_pins clk_wizard_0/clk_out1]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/S00_AXI] [get_bd_intf_pins VCU_hier/vcu2_0/C0_DEC_M_AXI_NOC]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/S01_AXI] [get_bd_intf_pins VCU_hier/vcu2_0/C0_DEC_MCU_M_AXI_NOC]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/S02_AXI] [get_bd_intf_pins VCU_hier/vcu2_0/C0_ENC_M_AXI_NOC]
connect_bd_intf_net [get_bd_intf_pins aggr_noc/S03_AXI] [get_bd_intf_pins VCU_hier/vcu2_0/C0_ENC_MCU_M_AXI_NOC]
 
 
connect_bd_net [get_bd_pins VCU_hier/vcu2_0/c0_dec_m_axi_noc_clk] [get_bd_pins aggr_noc/aclk0]
connect_bd_net [get_bd_pins VCU_hier/vcu2_0/c0_enc_m_axi_noc_clk] [get_bd_pins aggr_noc/aclk1]
connect_bd_net [get_bd_pins VCU_hier/vcu2_0/c0_dec_mcu_m_axi_noc_clk] [get_bd_pins aggr_noc/aclk2]
connect_bd_net [get_bd_pins VCU_hier/vcu2_0/c0_enc_mcu_m_axi_noc_clk] [get_bd_pins aggr_noc/aclk3]
 
 
  # Create interface ports
 
  set MIPI2 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 MIPI2 ]
 
  set MIPI6 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 MIPI6 ]
 
  set GT_DRU_FRL_CLK_IN [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 GT_DRU_FRL_CLK_IN ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {400000000} \
   ] $GT_DRU_FRL_CLK_IN
 
  set TX_REFCLK_P_IN_V [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 TX_REFCLK_P_IN_V ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $TX_REFCLK_P_IN_V
 
  set GT_Serial [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial ]
 
 
  # Create ports
  set TX_HPD_IN [ create_bd_port -dir I TX_HPD_IN ]
  set RX_TI_ENABLE [ create_bd_port -dir O -from 0 -to 0 RX_TI_ENABLE ]
  set TX_TI_ENABLE [ create_bd_port -dir O -from 0 -to 0 TX_TI_ENABLE ]
  set IDT8T49N241_LOL_IN [ create_bd_port -dir I IDT8T49N241_LOL_IN ]
  set TX_DDC_OUT_scl_io [ create_bd_port -dir IO TX_DDC_OUT_scl_io ]
  set TX_DDC_OUT_sda_io [ create_bd_port -dir IO TX_DDC_OUT_sda_io ]
  set HDMI_CTRL_scl_io [ create_bd_port -dir IO HDMI_CTRL_scl_io ]
  set HDMI_CTRL_sda_io [ create_bd_port -dir IO HDMI_CTRL_sda_io ]
 
  # Create instance: ps_wizard_0, and set properties
  set_property -dict [list \
    CONFIG.PS11_CONFIG(PL_FPD_IRQ_USAGE) {CH0 1 CH1 1 CH2 1 CH3 1 CH4 1 CH5 1 CH6 1 CH7 1} \
    CONFIG.PS11_CONFIG(PL_LPD_IRQ_USAGE) {CH0 1 CH1 1 CH2 1 CH3 1 CH4 1 CH5 1 CH6 1 CH7 1 CH8 1 CH9 1 CH10 1 CH11 1 CH12 1 CH13 1 CH14 1 CH15 1 CH16 1 CH17 1 CH18 1 CH19 1 CH20 1 CH21 1 CH22 1 CH23 1} \
  ] [get_bd_cells ps_wizard_0]
 
 
#Isp Smartconnect 
set isp_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect isp_smc ]
set_property -dict [list \
    CONFIG.NUM_MI {10} \
    CONFIG.NUM_SI {1} \
    CONFIG.NUM_CLKS {3} \
  ] $isp_smc
 
 
# Create instance: ISP_hier/visp_ss_tile0, and set properties
 set_property -dict [list \
  CONFIG.C_CONFIG_ONLY {false} \
  CONFIG.C_ENABLE_OVERDRIVE {1} \
  CONFIG.C_LLPATH0_DELAY {2000} \
  CONFIG.C_LLPATH0_TILE {0} \
  CONFIG.C_LLPATH1_DELAY {2000} \
  CONFIG.C_LLPATH1_IBA {4} \
  CONFIG.C_LLPATH1_TILE {0} \
  CONFIG.C_TILE0_CONFIG {1} \
  CONFIG.C_TILE0_ISP0_CORE_CLK {600.1} \
  CONFIG.C_TILE0_ISP0_GPIO_PS_CHECK {true} \
  CONFIG.C_TILE0_ISP0_GPIO_SELECT {0} \
  CONFIG.C_TILE0_ISP0_IIC_PS_CHECK {true} \
  CONFIG.C_TILE0_ISP0_IIC_SELECT {0} \
  CONFIG.C_TILE0_ISP0_IO_TYPE {2} \
  CONFIG.C_TILE0_ISP0_LIVE_INPUTS {1} \
  CONFIG.C_TILE0_ISP1_CORE_CLK {600.1} \
  CONFIG.C_TILE0_ISP1_GPIO_PS_CHECK {true} \
  CONFIG.C_TILE0_ISP1_GPIO_SELECT {0} \
  CONFIG.C_TILE0_ISP1_IIC_PS_CHECK {true} \
  CONFIG.C_TILE0_ISP1_IIC_SELECT {0} \
  CONFIG.C_TILE0_ISP1_IO_TYPE {2} \
] [get_bd_cells ISP_hier/visp_ss_tile0]
 
 
 
  # Create instance: proc_sys_reset_150, and set properties
  set proc_sys_reset_150 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_150 ]
 
  # Create instance: proc_sys_reset_300, and set properties
  set proc_sys_reset_300 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_300 ]
 
  # Create instance: ilxconstant_dcm_locked, and set properties
  set ilxconstant_dcm_locked [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilxconstant_dcm_locked ]
 
  # Create instance: hdmi_ss
  create_hier_cell_hdmi_ss [current_bd_instance .] hdmi_ss
 
  # Create instance: mipi_csi2_rx_subsyst_0, and set properties
  set mipi_csi2_rx_subsyst_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem mipi_csi2_rx_subsyst_0 ]
  set_property -dict [list \
    CONFIG.CMN_NUM_LANES {4} \
    CONFIG.CMN_NUM_PIXELS {4} \
    CONFIG.CMN_PXL_FORMAT {RAW12} \
    CONFIG.CMN_VC {All} \
    CONFIG.CSI_BUF_DEPTH {4096} \
    CONFIG.C_CSI_EN_ACTIVELANES {true} \
    CONFIG.C_CSI_FILTER_USERDATATYPE {true} \
    CONFIG.C_SPRT_ISP_BRIDGE {true} \
    CONFIG.DPY_EN_REG_IF {true} \
    CONFIG.DPY_LINE_RATE {1500} \
    CONFIG.SupportLevel {1} \
  ] $mipi_csi2_rx_subsyst_0
 
 
  # Create instance: mipi_csi2_rx_subsyst_1, and set properties
  set mipi_csi2_rx_subsyst_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem mipi_csi2_rx_subsyst_1 ]
  set_property -dict [list \
    CONFIG.CMN_NUM_LANES {4} \
    CONFIG.CMN_NUM_PIXELS {4} \
    CONFIG.CMN_PXL_FORMAT {RAW12} \
    CONFIG.CMN_VC {All} \
    CONFIG.CSI_BUF_DEPTH {4096} \
    CONFIG.C_CSI_EN_ACTIVELANES {true} \
    CONFIG.C_CSI_FILTER_USERDATATYPE {true} \
    CONFIG.C_SPRT_ISP_BRIDGE {true} \
    CONFIG.DPY_EN_REG_IF {true} \
    CONFIG.DPY_LINE_RATE {1500} \
    CONFIG.SupportLevel {1} \
  ] $mipi_csi2_rx_subsyst_1
 
 
  # Create instance: vmix_ss
  create_hier_cell_vmix_ss [current_bd_instance .] vmix_ss
 
  # Create instance: axi_intc_0, and set properties
  set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
  set_property -dict [list \
    CONFIG.C_IRQ_CONNECTION {1} \
    CONFIG.C_IRQ_IS_LEVEL {1} \
  ] $axi_intc_0
 
 
  # Create instance: ilconcat_0, and set properties
  set ilconcat_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_0 ]
 
 
 
  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_1 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_1
 
 
 
  # Create instance: clk_wizard_1, and set properties
  set clk_wizard_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clk_wizard_1 ]
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {150,200.000,300.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,true,true,false,false,false,false} \
    CONFIG.PRIM_SOURCE {No_buffer} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
    CONFIG.USE_RESET {true} \
  ] $clk_wizard_1
 
 
 
 
 
  # Create interface connections
 
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/eol_path0] [get_bd_pins VCU_hier/vcu2_0/c0_enc_sync_eol_path0]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/eof_path0] [get_bd_pins VCU_hier/vcu2_0/c0_enc_sync_eof_path0]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/eol_path1] [get_bd_pins VCU_hier/vcu2_0/c0_enc_sync_eol_path1]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/eof_path1] [get_bd_pins VCU_hier/vcu2_0/c0_enc_sync_eof_path1]
 
 
  set ctrl_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 ctrl_smc ]
  set_property -dict [list \
  CONFIG.NUM_MI {5} \
  CONFIG.NUM_SI {1} \
  CONFIG.NUM_CLKS {3}
  ] [get_bd_cells ctrl_smc]
 
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_pl_isp_vidout0_clk] [get_bd_pins clk_wizard_1/clk_out3]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_pl_isp_vidout1_clk] [get_bd_pins clk_wizard_1/clk_out3]
 
  connect_bd_intf_net [get_bd_intf_pins ctrl_smc/M00_AXI] [get_bd_intf_pins vcu_smc/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL] [get_bd_intf_pins ctrl_smc/S00_AXI]
  
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins ctrl_smc/M02_AXI] [get_bd_intf_pins mmi_vid_clk_wiz/s_axi_lite]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins ctrl_smc/M03_AXI] [get_bd_intf_pins mmi_aud_clk_wiz/s_axi_lite]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins ctrl_smc/M04_AXI] [get_bd_intf_pins clk_wizard_enable/S_AXI]

  
 
  connect_bd_intf_net -intf_net MIPI2_1 [get_bd_intf_ports MIPI2] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/mipi_phy_if]
  connect_bd_intf_net -intf_net MIPI6_1 [get_bd_intf_ports MIPI6] [get_bd_intf_pins mipi_csi2_rx_subsyst_1/mipi_phy_if]
 
  connect_bd_intf_net -intf_net ctrl_smc_M01_AXI [get_bd_intf_pins isp_smc/S00_AXI] [get_bd_intf_pins ctrl_smc/M01_AXI]
  connect_bd_net [get_bd_pins isp_smc/aclk] [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins ctrl_smc/aclk]
  connect_bd_net [get_bd_pins ctrl_smc/aclk1] [get_bd_pins ps_wizard_0/pl0_ref_clk]
  connect_bd_net [get_bd_pins ctrl_smc/aclk2] [get_bd_pins mmi_vid_clk_wiz/pl_vid_2x_clk_o2]

  connect_bd_net [get_bd_pins isp_smc/aresetn] [get_bd_pins rst_clk/peripheral_aresetn] [get_bd_pins ctrl_smc/aresetn]
  connect_bd_net [get_bd_pins isp_smc/aclk1] [get_bd_pins clk_wizard_1/clk_out1]
  connect_bd_net [get_bd_pins isp_smc/aclk2] [get_bd_pins clk_wizard_1/clk_out3]
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M00_AXI] [get_bd_intf_pins ISP_hier/visp_ss_tile0/S_AXI_LITE]
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M01_AXI] -boundary_type upper [get_bd_intf_pins vmix_ss/s_axi_ctrl_vmix]
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M02_AXI] -boundary_type upper [get_bd_intf_pins vmix_ss/s_axit_ctrl_vmix_gpio]
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M03_AXI] [get_bd_intf_pins smartconnect_1/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M04_AXI] [get_bd_intf_pins axi_intc_0/s_axi]  
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M05_AXI] -boundary_type upper [get_bd_intf_pins hdmi_ss/S_AXI_CPU_IN]
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M06_AXI] -boundary_type upper [get_bd_intf_pins hdmi_ss/S_AXI_IIC]
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M07_AXI] -boundary_type upper [get_bd_intf_pins hdmi_ss/S_AXI_TIMER]
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M08_AXI] -boundary_type upper [get_bd_intf_pins hdmi_ss/S_AXI_VFMC]
  connect_bd_intf_net [get_bd_intf_pins isp_smc/M09_AXI] -boundary_type upper [get_bd_intf_pins hdmi_ss/vid_phy_axi4lite]
 
  connect_bd_intf_net -intf_net intf_net_bdry_in_GT_DRU_FRL_CLK_IN [get_bd_intf_ports GT_DRU_FRL_CLK_IN] [get_bd_intf_pins hdmi_ss/GT_DRU_FRL_CLK_IN]
  connect_bd_intf_net -intf_net intf_net_bdry_in_TX_REFCLK_P_IN_V [get_bd_intf_ports TX_REFCLK_P_IN_V] [get_bd_intf_pins hdmi_ss/TX_REFCLK_P_IN_V]
  connect_bd_intf_net -intf_net intf_net_hdmiphy_ss_0_phy_data [get_bd_intf_pins hdmi_ss/GT_Serial] [get_bd_intf_ports GT_Serial]
  connect_bd_intf_net  [get_bd_intf_pins mipi_csi2_rx_subsyst_0/video_out] [get_bd_intf_pins ISP_hier/visp_ss_tile0/TILE0_ISP_MIPI_VIDIN0]
  connect_bd_intf_net  [get_bd_intf_pins mipi_csi2_rx_subsyst_1/video_out] [get_bd_intf_pins ISP_hier/visp_ss_tile0/TILE0_ISP_MIPI_VIDIN4]
  connect_bd_intf_net -intf_net smartconnect_1_M00_AXI [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/csirxss_s_axi]
  connect_bd_intf_net -intf_net smartconnect_1_M01_AXI [get_bd_intf_pins smartconnect_1/M01_AXI] [get_bd_intf_pins mipi_csi2_rx_subsyst_1/csirxss_s_axi]
  connect_bd_intf_net [get_bd_intf_pins ISP_hier/visp_ss_tile0/TILE0_ISP0_NMU] [get_bd_intf_pins aggr_noc/S04_AXI]
  connect_bd_intf_net [get_bd_intf_pins ISP_hier/visp_ss_tile0/TILE0_ISP1_NMU] [get_bd_intf_pins aggr_noc/S05_AXI]
 
  connect_bd_intf_net -intf_net vmix_frmbuf_rd_ss_m_axis_vmix_video_out [get_bd_intf_pins vmix_ss/m_axis_vmix_video_out] [get_bd_intf_pins hdmi_ss/VIDEO_IN]
#connect_bd_intf_net [get_bd_intf_pins aggr_noc/S00_INI] -boundary_type upper [get_bd_intf_pins vmix_ss/vmix_M00_INI]
#connect_bd_intf_net [get_bd_intf_pins aggr_noc/S01_INI] -boundary_type upper [get_bd_intf_pins vmix_ss/vmix_M01_INI]
 connect_bd_intf_net [get_bd_intf_pins NoC_C0_C1/S05_INI] -boundary_type upper [get_bd_intf_pins vmix_ss/vmix_M00_INI]
 connect_bd_intf_net [get_bd_intf_pins NoC_C0_C1/S06_INI] -boundary_type upper [get_bd_intf_pins vmix_ss/vmix_M01_INI] 
 
  # Create port connections
  connect_bd_net -net Net  [get_bd_ports TX_DDC_OUT_scl_io] \
  [get_bd_pins hdmi_ss/TX_DDC_OUT_scl_io]
  connect_bd_net -net Net1  [get_bd_ports TX_DDC_OUT_sda_io] \
  [get_bd_pins hdmi_ss/TX_DDC_OUT_sda_io]
  connect_bd_net -net Net2  [get_bd_ports HDMI_CTRL_scl_io] \
  [get_bd_pins hdmi_ss/HDMI_CTRL_scl_io]
  connect_bd_net -net Net3  [get_bd_ports HDMI_CTRL_sda_io] \
  [get_bd_pins hdmi_ss/HDMI_CTRL_sda_io]
  connect_bd_net -net axi_intc_0_irq  [get_bd_pins axi_intc_0/irq] \
  [get_bd_pins ps_wizard_0/pl_fpd_irq0]
  connect_bd_net [get_bd_pins clk_wizard_0/clk_out1] \
  [get_bd_pins smartconnect_1/aclk]
  
  connect_bd_net [get_bd_pins clk_wizard_1/clk_out2] [get_bd_pins mipi_csi2_rx_subsyst_0/dphy_clk_200M]
  connect_bd_net [get_bd_pins clk_wizard_1/clk_out2] [get_bd_pins mipi_csi2_rx_subsyst_1/dphy_clk_200M]
  
  connect_bd_net -net hdmi_ss_RX_TI_ENABLE  [get_bd_pins hdmi_ss/RX_TI_ENABLE] \
  [get_bd_ports RX_TI_ENABLE]
  connect_bd_net -net hdmi_ss_hdmi_tx_irq  [get_bd_pins hdmi_ss/hdmi_tx_irq] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq22]
  connect_bd_net -net hdmi_ss_iic_irq  [get_bd_pins hdmi_ss/iic_irq] \
  [get_bd_pins ps_wizard_0/pl_fpd_irq6]
  connect_bd_net -net hdmi_ss_timer_irq  [get_bd_pins hdmi_ss/timer_irq] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq21]
  connect_bd_net -net hdmi_ss_vphy_irq  [get_bd_pins hdmi_ss/vphy_irq] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq23]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_csirxss_csi_irq  [get_bd_pins mipi_csi2_rx_subsyst_0/csirxss_csi_irq] \
  [get_bd_pins ilconcat_0/In0]
  connect_bd_net  [get_bd_pins mipi_csi2_rx_subsyst_0/header_data] \
  [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp_mipi_vidin0_header_data]
  connect_bd_net  [get_bd_pins mipi_csi2_rx_subsyst_0/header_valid] \
  [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp_mipi_vidin0_header_valid]
  connect_bd_net [get_bd_pins mipi_csi2_rx_subsyst_1/csirxss_csi_irq] \
  [get_bd_pins ilconcat_0/In1]
  connect_bd_net [get_bd_pins mipi_csi2_rx_subsyst_1/header_data] \
  [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp_mipi_vidin4_header_data]
  connect_bd_net [get_bd_pins mipi_csi2_rx_subsyst_1/header_valid] \
  [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp_mipi_vidin4_header_valid]
  connect_bd_net -net net_bdry_in_IDT8T49N241_LOL_IN  [get_bd_ports IDT8T49N241_LOL_IN] \
  [get_bd_pins hdmi_ss/IDT8T49N241_LOL_IN]
  connect_bd_net -net net_bdry_in_TX_HPD_IN  [get_bd_ports TX_HPD_IN] \
  [get_bd_pins hdmi_ss/TX_HPD_IN]
  connect_bd_net -net net_vfmc_ctlr_ss_0_VFMC_RX_ONSEMI_ENABLE  [get_bd_pins hdmi_ss/TX_TI_ENABLE] \
  [get_bd_ports TX_TI_ENABLE]
  
connect_bd_net -net proc_sys_reset_300_peripheral_aresetn  [get_bd_pins proc_sys_reset_300/peripheral_aresetn] \
  [get_bd_pins hdmi_ss/s_axis_video_aresetn] \
  [get_bd_pins vmix_ss/s_axis_video_aresetn]
    
  # for resets 
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins proc_sys_reset_150/ext_reset_in] \
  [get_bd_pins proc_sys_reset_300/ext_reset_in] \
  [get_bd_pins clk_wizard_1/resetn]
 
  #clk_wizard_1 clkin1
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins clk_wizard_1/clk_in1]
 
  connect_bd_net [get_bd_pins ps_wizard_0/pl1_ref_clk] \
  [get_bd_pins ISP_hier/visp_ss_tile0/tile0_ref_dpll_clk] 
 
  connect_bd_net [get_bd_pins clk_wizard_1/clk_out1] \
  [get_bd_pins proc_sys_reset_150/slowest_sync_clk] \
  [get_bd_pins ISP_hier/visp_ss_tile0/s_axi_lite_aclk] \
  [get_bd_pins hdmi_ss/vid_phy_sb_aclk] \
  [get_bd_pins ISP_hier/visp_ss_tile0/tile0_pl_isp_vidin0_clk] \
  [get_bd_pins ISP_hier/visp_ss_tile0/tile0_pl_isp_vidin4_clk] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aclk] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/video_aclk] \
  [get_bd_pins mipi_csi2_rx_subsyst_1/lite_aclk] \
  [get_bd_pins mipi_csi2_rx_subsyst_1/video_aclk] \
  [get_bd_pins axi_intc_0/s_axi_aclk] \
  [get_bd_pins smartconnect_1/aclk1]
 
 
  connect_bd_net -net clk_wizard_1_clk_out3  [get_bd_pins clk_wizard_1/clk_out3] \
  [get_bd_pins hdmi_ss/s_axis_video_aclk] \
  [get_bd_pins proc_sys_reset_300/slowest_sync_clk] \
  [get_bd_pins vmix_ss/s_axis_video_aclk] \
 
  connect_bd_net [get_bd_pins proc_sys_reset_150/peripheral_aresetn] \
  [get_bd_pins ISP_hier/visp_ss_tile0/s_axi_lite_rstn] \
  [get_bd_pins ISP_hier/visp_ss_tile0/tile0_pl_isp_rstn] \
  [get_bd_pins hdmi_ss/vid_phy_sb_aresetn] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aresetn] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/video_aresetn] \
  [get_bd_pins mipi_csi2_rx_subsyst_1/lite_aresetn] \
  [get_bd_pins mipi_csi2_rx_subsyst_1/video_aresetn] \
  [get_bd_pins axi_intc_0/s_axi_aresetn] \
  [get_bd_pins smartconnect_1/aresetn]
  delete_bd_objs [get_bd_nets axi_gpio_1_ip2intc_irpt] [get_bd_nets axi_gpio_2_ip2intc_irpt]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp0_fusa_irq] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq2]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp0_isp_irq] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq3]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp1_fusa_irq] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq4]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp1_isp_irq] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq5]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp_isr_irq] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq0]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_isp_xmpu_interrupt] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq1]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_nmu0_axi_clk] \
  [get_bd_pins aggr_noc/aclk4]
  connect_bd_net [get_bd_pins ISP_hier/visp_ss_tile0/tile0_nmu1_axi_clk] \
  [get_bd_pins aggr_noc/aclk5]
  connect_bd_net -net vmix_frmbuf_rd_ss_mixer_irq  [get_bd_pins vmix_ss/mixer_irq] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq20]
  connect_bd_net -net ilconcat_0_dout  [get_bd_pins ilconcat_0/dout] \
  [get_bd_pins axi_intc_0/intr]
  connect_bd_net -net ilxconstant_dcm_locked_dout  [get_bd_pins ilxconstant_dcm_locked/dout] \
  [get_bd_pins proc_sys_reset_150/dcm_locked] \
  [get_bd_pins proc_sys_reset_300/dcm_locked]
 
  # Create address segments

  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs mmi_aud_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs mmi_aud_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs mmi_aud_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs mmi_aud_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs mmi_aud_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs mmi_aud_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs mmi_aud_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs mmi_aud_clk_wiz/s_axi_lite/Reg] -force



  assign_bd_address -offset 0xB0140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs hdmi_ss/axi_iic_hdmi/S_AXI/Reg] -force
  assign_bd_address -offset 0xB1400000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_intc_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0150000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs hdmi_ss/axi_timer_hdmi/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0180000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs hdmi_ss/hdmiphy_ss_0/hdmi_gt_controller/axi4lite/Reg] -force
  assign_bd_address -offset 0xB0160000 -range 0x00020000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs hdmi_ss/v_hdmi_txss1/S_AXI_CPU_IN/Reg] -force
  assign_bd_address -offset 0xB0100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs vmix_ss/v_mix/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0190000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs hdmi_ss/vfmc_ctlr_ss_0/vfmc_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xE8500000 -range 0x00100000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs ISP_hier/visp_ss_tile0/TILE0_ISP_NSU/Reg] -force
  assign_bd_address -offset 0xB1300000 -range 0x00001000 -with_name SEG_visp_ss_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs ISP_hier/visp_ss_tile0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xB0110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs vmix_ss/vmix_rst_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB1000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0xB1060000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs mipi_csi2_rx_subsyst_1/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0xE8500000 -range 0x00100000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs ISP_hier/visp_ss_tile0/TILE0_ISP_NSU/Reg] -force
 
 
assign_bd_address
 
set_property offset 0xB0F50000 [get_bd_addr_segs {ps_wizard_0/ps11_0_cortexa78_0/SEG_vcu_gpio_reset_Reg}]
set_property offset 0xB0F50000 [get_bd_addr_segs {ps_wizard_0/ps11_0_cortexa78_1/SEG_vcu_gpio_reset_Reg}]
set_property offset 0xB0F50000 [get_bd_addr_segs {ps_wizard_0/ps11_0_cortexa78_2/SEG_vcu_gpio_reset_Reg}]
set_property offset 0xB0F50000 [get_bd_addr_segs {ps_wizard_0/ps11_0_cortexa78_3/SEG_vcu_gpio_reset_Reg}]
set_property offset 0xB0F50000 [get_bd_addr_segs {ps_wizard_0/ps11_0_cortexa78_4/SEG_vcu_gpio_reset_Reg}]
set_property offset 0xB0F50000 [get_bd_addr_segs {ps_wizard_0/ps11_0_cortexa78_5/SEG_vcu_gpio_reset_Reg}]
set_property offset 0xB0F50000 [get_bd_addr_segs {ps_wizard_0/ps11_0_cortexa78_6/SEG_vcu_gpio_reset_Reg}]
set_property offset 0xB0F50000 [get_bd_addr_segs {ps_wizard_0/ps11_0_cortexa78_7/SEG_vcu_gpio_reset_Reg}]
 
  assign_bd_address
  
  # Restore current instance
  current_bd_instance $oldCurInst

add_files -fileset constrs_1 $currentDir/Dual_Display_GPU/hdmi_vek385_exdes_vcu2_v3_0_0_xdc.xdc
add_files -fileset constrs_1 $currentDir/Dual_Display_GPU/xylon_gmsl2_exdes_vcu2_v3_0_0_xdc.xdc
add_files -fileset constrs_1 $currentDir/Dual_Display_GPU/xylon_gmsl6_exdes_vcu2_v3_0_0_xdc.xdc

}
# End of create_root_design()
 
 
##################################################################
# MAIN FLOW
##################################################################
 
create_root_design ""


