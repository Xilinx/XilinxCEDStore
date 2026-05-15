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
group_bd_cells hier_NOC [get_bd_cells NoC_C0_C1] [get_bd_cells aggr_noc] [get_bd_cells Master_NoC] [get_bd_cells NoC_C2_C3] [get_bd_cells NoC_C4] [get_bd_cells ai_engine_0] [get_bd_cells ConfigNoc] [get_bd_cells AIE_ConfigNoc]
######################## setting comments #######################
set_property USER_COMMENTS.comment_0 {MMI DPDC Bypass design with SST as Presentation mode and num of lanes is X4} [current_bd_design]
#####################################################################

# Hierarchical cell: frm_buf_rd_ss
proc create_hier_cell_frm_buf_rd_ss { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_frm_buf_rd_ss() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 M00_INI


  # Create pins
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -type clk vid_clk
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir O -type intr interrupt

  # Create instance: v_tc_0, and set properties
  set v_tc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc v_tc_0 ]
  set_property -dict [list \
    CONFIG.VIDEO_MODE {720p} \
    CONFIG.enable_detection {false} \
    CONFIG.max_clocks_per_line {8192} \
    CONFIG.max_lines_per_frame {8192} \
  ] $v_tc_0


  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ] 

  # Create instance: ilconstant_1, and set properties
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_1 ]
  set_property CONFIG.CONST_VAL {0} $ilconstant_1

  # Create instance: v_axi4s_vid_out_0, and set properties
  set v_axi4s_vid_out_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out v_axi4s_vid_out_0 ]
  set_property -dict [list \
    CONFIG.C_ADDR_WIDTH {13} \
    CONFIG.C_NATIVE_COMPONENT_WIDTH {12} \
    CONFIG.C_PIXELS_PER_CLOCK {4} \
    CONFIG.C_S_AXIS_VIDEO_DATA_WIDTH {12} \
  ] $v_axi4s_vid_out_0


  # Create instance: v_frmbuf_rd_0, and set properties
  set v_frmbuf_rd_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_frmbuf_rd v_frmbuf_rd_0 ]
  set_property -dict [list \
    CONFIG.AXIMM_ADDR_WIDTH {64} \
    CONFIG.AXIMM_DATA_WIDTH {256} \
    CONFIG.C_M_AXI_MM_VIDEO_DATA_WIDTH {256} \
    CONFIG.HAS_RGBX12 {1} \
    CONFIG.HAS_BGR8 {1} \
    CONFIG.HAS_RGB8 {1} \
    CONFIG.HAS_BGRX8 {1} \
    CONFIG.HAS_RGBX10 {1} \
    CONFIG.HAS_RGBX8 {1} \
    CONFIG.HAS_UYVY8 {1} \
    CONFIG.HAS_Y10_16LE {1} \
    CONFIG.HAS_Y12 {1} \
    CONFIG.HAS_Y12_16LE {1} \
    CONFIG.HAS_Y8 {1} \
    CONFIG.HAS_YUV8 {1} \
    CONFIG.HAS_YUVX10 {1} \
    CONFIG.HAS_YUVX12 {1} \
    CONFIG.HAS_YUVX8 {1} \
    CONFIG.HAS_YUYV8 {1} \
    CONFIG.HAS_Y_UV10 {1} \
    CONFIG.HAS_Y_UV10_16LE {1} \
    CONFIG.HAS_Y_UV10_420 {1} \
    CONFIG.HAS_Y_UV10_420_16LE {1} \
    CONFIG.HAS_Y_UV12 {1} \
    CONFIG.HAS_Y_UV12_16LE {1} \
    CONFIG.HAS_Y_UV12_420 {1} \
    CONFIG.HAS_Y_UV12_420_16LE {1} \
    CONFIG.HAS_Y_UV8 {1} \
    CONFIG.HAS_Y_U_V10 {1} \
    CONFIG.HAS_Y_U_V10_16LE {1} \
    CONFIG.HAS_Y_U_V12 {1} \
    CONFIG.HAS_Y_U_V12_16LE {1} \
    CONFIG.HAS_Y_U_V8 {1} \
    CONFIG.HAS_Y_U_V8_420 {1} \
    CONFIG.HAS_Y10 {1} \
    CONFIG.HAS_Y_UV8_420 {1} \
    CONFIG.MAX_COLS {7680} \
    CONFIG.MAX_DATA_WIDTH {12} \
    CONFIG.MAX_ROWS {4320} \
    CONFIG.SAMPLES_PER_CLOCK {4} \
  ] $v_frmbuf_rd_0


  # Create instance: axi_noc2_frmbuf_rd, and set properties
  set axi_noc2_frmbuf_rd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_frmbuf_rd ]
  set_property -dict [list \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {1} \
    CONFIG.NUM_NSI {0} \
    CONFIG.NUM_SI {1} \
  ] $axi_noc2_frmbuf_rd


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.R_TRAFFIC_CLASS {ISOCHRONOUS} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {8000} write_bw {500} read_avg_burst {4} write_avg_burst {4} }} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc2_frmbuf_rd/S00_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc2_frmbuf_rd/aclk0]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ctrl] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins v_frmbuf_rd_0/s_axi_CTRL] [get_bd_intf_pins s_axi_CTRL]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins axi_noc2_frmbuf_rd/M00_INI] [get_bd_intf_pins M00_INI]
  connect_bd_intf_net -intf_net v_axi4s_vid_out_0_vid_io_out [get_bd_intf_pins v_axi4s_vid_out_0/vid_io_out] [get_bd_intf_pins vid_intf]
  connect_bd_intf_net -intf_net v_frmbuf_rd_0_m_axi_mm_video [get_bd_intf_pins v_frmbuf_rd_0/m_axi_mm_video] [get_bd_intf_pins axi_noc2_frmbuf_rd/S00_AXI]
  connect_bd_intf_net -intf_net v_frmbuf_rd_0_m_axis_video [get_bd_intf_pins v_axi4s_vid_out_0/video_in] [get_bd_intf_pins v_frmbuf_rd_0/m_axis_video]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins v_tc_0/vtiming_out] [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in]

  # Create port connections
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins TPG_GEN_EN] \
  [get_bd_pins v_axi4s_vid_out_0/vid_io_out_ce]
  connect_bd_net -net ilconstant_1_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins v_tc_0/fsync_in] \
  [get_bd_pins v_axi4s_vid_out_0/fid]
  connect_bd_net -net net_mb_ss_0_clk_out2  [get_bd_pins av_axi_aclk] \
  [get_bd_pins v_tc_0/s_axi_aclk]
  connect_bd_net -net v_axi4s_vid_out_0_sof_state_out  [get_bd_pins v_axi4s_vid_out_0/sof_state_out] \
  [get_bd_pins v_tc_0/sof_state]
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins v_tc_0/clken] \
  [get_bd_pins v_tc_0/s_axi_aclken] \
  [get_bd_pins v_axi4s_vid_out_0/aclken]
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce1  [get_bd_pins v_axi4s_vid_out_0/vtg_ce] \
  [get_bd_pins v_tc_0/gen_clken]
  connect_bd_net -net v_frmbuf_rd_0_interrupt  [get_bd_pins v_frmbuf_rd_0/interrupt] \
  [get_bd_pins interrupt]
  connect_bd_net -net vid_out_axi4s_aclk_1  [get_bd_pins vid_clk] \
  [get_bd_pins v_tc_0/clk] \
  [get_bd_pins v_axi4s_vid_out_0/aclk] \
  [get_bd_pins v_frmbuf_rd_0/ap_clk] \
  [get_bd_pins axi_noc2_frmbuf_rd/aclk0]
  connect_bd_net -net vid_out_axi4s_aresetn_1  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins v_tc_0/resetn] \
  [get_bd_pins v_axi4s_vid_out_0/aresetn] \
  [get_bd_pins v_tc_0/s_axi_aresetn] \
  [get_bd_pins v_frmbuf_rd_0/ap_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: rst_module
proc create_hier_cell_rst_module { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_rst_module() - Empty argument(s)!"}
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

  # Create pins
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -type clk slowest_sync_clk
  create_bd_pin -dir I dcm_locked

  # Create instance: rst_proc_vid_clk, and set properties
  set rst_proc_vid_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_proc_vid_clk ]
  set_property CONFIG.C_NUM_PERP_ARESETN {1} $rst_proc_vid_clk


  # Create port connections
  connect_bd_net -net PS_0_pl0_resetn  [get_bd_pins ext_reset_in] \
  [get_bd_pins rst_proc_vid_clk/ext_reset_in]
  connect_bd_net -net clk_wiz_pl_vid_1x_clk  [get_bd_pins slowest_sync_clk] \
  [get_bd_pins rst_proc_vid_clk/slowest_sync_clk]
  connect_bd_net -net dcm_locked_1  [get_bd_pins dcm_locked] \
  [get_bd_pins rst_proc_vid_clk/dcm_locked]
  connect_bd_net -net rst_proc_vid_clk_peripheral_aresetn  [get_bd_pins rst_proc_vid_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Create ports

  # Create instance: ps_wizard_0, and set properties
  set_property -dict [list \
    CONFIG.MMI_CONFIG(DPDC_OPERATING_MODE) {DC_Bypass} \
    CONFIG.MMI_CONFIG(DPDC_PRESENTATION_MODE) {Live} \
    CONFIG.MMI_CONFIG(DPDC_STREAM00_SDP_EN) {0} \
    CONFIG.MMI_CONFIG(DPDC_STREAM0_MODE) {Video_only} \
    CONFIG.MMI_CONFIG(DPDC_STREAM0_PIXEL_MODE) {Quad} \
    CONFIG.MMI_CONFIG(MMI_DP_HPD) {PMC_MIO_48} \
    CONFIG.MMI_CONFIG(PL_MMI_INTERRUPTS_EN) {0} \
    CONFIG.MMI_CONFIG(RTL_DEBUG) {0} \
    CONFIG.MMI_CONFIG(UDH_GT) {DP_X4} \
    CONFIG.PS11_CONFIG(UDH_GT) {DP_X4} \
  ] [get_bd_cells ps_wizard_0]

  # Create port in NOC for frame buffer read to connect
  set_property -dict [list \
    CONFIG.NUM_NSI {6} \
  ] [get_bd_cells hier_NOC/NoC_C0_C1]
  set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true} }}] [get_bd_intf_pins /hier_NOC/NoC_C0_C1/S05_INI]

# Create instance: mmi_vid_clk_wiz, and set properties
  set mmi_vid_clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz mmi_vid_clk_wiz ]
  set_property -dict [list \
    CONFIG.CE_SYNC_EXT {true} \
    CONFIG.CE_TYPE {HARDSYNC} \
    CONFIG.CLKOUT_DRIVES {MBUFGCE,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {pl_vid_2x_clk,pl_vid_2x_clk,ps_cfg_clk,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {594.000,600.000,230.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.ENABLE_CLOCK_MONITOR {false} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.PRIMITIVE_TYPE {MMCM} \
    CONFIG.PRIM_SOURCE {No_buffer} \
    CONFIG.USE_DYN_RECONFIG {true} \
  ] $mmi_vid_clk_wiz


# Create instance: rst_module
  create_hier_cell_rst_module [current_bd_instance .] rst_module

  # Create instance: clk_wizard_enable, and set properties
  set clk_wizard_enable [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio clk_wizard_enable ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00000003} \
    CONFIG.C_GPIO_WIDTH {2} \
    CONFIG.C_IS_DUAL {0} \
  ] $clk_wizard_enable


  # Create instance: Live_input_gpio, and set properties
  set Live_input_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio Live_input_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_IS_DUAL {0} \
  ] $Live_input_gpio


  # Create instance: ilslice_8, and set properties
  set ilslice_8 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_8 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {0} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {2} \
  ] $ilslice_8


  # Create instance: ilslice_9, and set properties
  set ilslice_9 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_9 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {2} \
  ] $ilslice_9

# Create instance: ctrl_smc, and set properties
  set ctrl_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect ctrl_smc ]
  set_property -dict [list \
    CONFIG.ADVANCED_PROPERTIES {__experimental_features__ {legacy_low_area_mode 1}} \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {6} \
    CONFIG.NUM_SI {1} \
  ] $ctrl_smc
 
  # Create instance: vid_format_gpio, and set properties
  set vid_format_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio vid_format_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH {3} \
  ] $vid_format_gpio


  # Create instance: frm_buf_rd_ss
  create_hier_cell_frm_buf_rd_ss [current_bd_instance .] frm_buf_rd_ss

  # Create interface connections
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins frm_buf_rd_ss/M00_INI] [get_bd_intf_pins hier_NOC/NoC_C0_C1/S05_INI]
  connect_bd_intf_net -intf_net avtpg_s0_vid_intf [get_bd_intf_pins ps_wizard_0/video_s0] [get_bd_intf_pins frm_buf_rd_ss/vid_intf]
  connect_bd_intf_net -intf_net ctrl_smc_M00_AXI [get_bd_intf_pins ctrl_smc/M00_AXI] [get_bd_intf_pins frm_buf_rd_ss/ctrl]
  connect_bd_intf_net -intf_net ctrl_smc_M01_AXI [get_bd_intf_pins ctrl_smc/M01_AXI] [get_bd_intf_pins frm_buf_rd_ss/s_axi_CTRL]
  connect_bd_intf_net -intf_net ctrl_smc_M02_AXI [get_bd_intf_pins ctrl_smc/M02_AXI] [get_bd_intf_pins mmi_vid_clk_wiz/s_axi_lite]
  connect_bd_intf_net -intf_net ctrl_smc_M03_AXI [get_bd_intf_pins ctrl_smc/M03_AXI] [get_bd_intf_pins clk_wizard_enable/S_AXI]
  connect_bd_intf_net -intf_net ctrl_smc_M04_AXI [get_bd_intf_pins ctrl_smc/M04_AXI] [get_bd_intf_pins vid_format_gpio/S_AXI]
  connect_bd_intf_net -intf_net ctrl_smc_M05_AXI [get_bd_intf_pins ctrl_smc/M05_AXI] [get_bd_intf_pins Live_input_gpio/S_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_PL [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL] [get_bd_intf_pins ctrl_smc/S00_AXI]

  # Create port connections
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins Live_input_gpio/gpio_io_o] \
  [get_bd_pins frm_buf_rd_ss/TPG_GEN_EN]
  connect_bd_net -net axi_gpio_3_gpio_io_o  [get_bd_pins clk_wizard_enable/gpio_io_o] \
  [get_bd_pins ilslice_9/Din] \
  [get_bd_pins ilslice_8/Din]
  connect_bd_net -net clkx5_wiz_1_locked  [get_bd_pins mmi_vid_clk_wiz/locked] \
  [get_bd_pins rst_module/dcm_locked]
  connect_bd_net -net frm_buf_rd_ss_interrupt  [get_bd_pins frm_buf_rd_ss/interrupt] \
  [get_bd_pins ps_wizard_0/pl_lpd_irq0]
  connect_bd_net -net ilslice_8_Dout  [get_bd_pins ilslice_8/Dout] \
  [get_bd_pins mmi_vid_clk_wiz/pl_vid_2x_clk_ce]
  connect_bd_net -net ilslice_9_Dout  [get_bd_pins ilslice_9/Dout] \
  [get_bd_pins mmi_vid_clk_wiz/pl_vid_2x_clk_clr_n]
  connect_bd_net -net pl_mmi_clk_wiz_clk_out1_o1  [get_bd_pins mmi_vid_clk_wiz/pl_vid_2x_clk_o1] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk]
  connect_bd_net -net pl_mmi_clk_wiz_clk_out1_o2  [get_bd_pins mmi_vid_clk_wiz/pl_vid_2x_clk_o2] \
  [get_bd_pins rst_module/slowest_sync_clk] \
  [get_bd_pins clk_wizard_enable/s_axi_aclk] \
  [get_bd_pins Live_input_gpio/s_axi_aclk] \
  [get_bd_pins frm_buf_rd_ss/vid_clk] \
  [get_bd_pins vid_format_gpio/s_axi_aclk] \
  [get_bd_pins frm_buf_rd_ss/av_axi_aclk] \
  [get_bd_pins ctrl_smc/aclk1] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk] 
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins ctrl_smc/aclk] \
  [get_bd_pins mmi_vid_clk_wiz/s_axi_aclk] \
  [get_bd_pins mmi_vid_clk_wiz/clk_in1] \
  [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] \
  [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk] 
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins rst_module/ext_reset_in] \
  [get_bd_pins ctrl_smc/aresetn] \
  [get_bd_pins mmi_vid_clk_wiz/s_axi_aresetn]
  connect_bd_net -net rst_module_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn] \
  [get_bd_pins clk_wizard_enable/s_axi_aresetn] \
  [get_bd_pins Live_input_gpio/s_axi_aresetn] \
  [get_bd_pins frm_buf_rd_ss/vid_out_axi4s_aresetn] \
  [get_bd_pins vid_format_gpio/s_axi_aresetn]
  connect_bd_net -net vid_format_gpio_gpio_io_o  [get_bd_pins vid_format_gpio/gpio_io_o] \
  [get_bd_pins ps_wizard_0/video_format]
 

 # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces frm_buf_rd_ss/v_frmbuf_rd_0/Data_m_axi_mm_video] [get_bd_addr_segs hier_NOC/NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs frm_buf_rd_ss/v_frmbuf_rd_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs frm_buf_rd_ss/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs vid_format_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs frm_buf_rd_ss/v_frmbuf_rd_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs frm_buf_rd_ss/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs vid_format_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs frm_buf_rd_ss/v_frmbuf_rd_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs frm_buf_rd_ss/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs vid_format_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs frm_buf_rd_ss/v_frmbuf_rd_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs frm_buf_rd_ss/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs vid_format_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs frm_buf_rd_ss/v_frmbuf_rd_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs frm_buf_rd_ss/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs vid_format_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs frm_buf_rd_ss/v_frmbuf_rd_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs frm_buf_rd_ss/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs vid_format_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs frm_buf_rd_ss/v_frmbuf_rd_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs frm_buf_rd_ss/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs vid_format_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs mmi_vid_clk_wiz/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs frm_buf_rd_ss/v_frmbuf_rd_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs frm_buf_rd_ss/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs vid_format_gpio/S_AXI/Reg] -force
  assign_bd_address

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces frm_buf_rd_ss/v_frmbuf_rd_0/Data_m_axi_mm_video] [get_bd_addr_segs hier_NOC/NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg 
  
 
