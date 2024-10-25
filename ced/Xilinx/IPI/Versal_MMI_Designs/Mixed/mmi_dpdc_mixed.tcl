################################################################
# START
################################################################
##################################################################
# DESIGN PROCs
##################################################################
# Hierarchical cell: pl_video_s0p0
proc create_hier_cell_pl_video_s0p0 { parentCell nameHier } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mm_video_0


  # Create pins
  create_bd_pin -dir I -from 0 -to 0 Op2
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn1
  create_bd_pin -dir I -from 2 -to 0 bpc
  create_bd_pin -dir I -from 2 -to 0 color_format
  create_bd_pin -dir I -from 15 -to 0 dp_hres
  create_bd_pin -dir O -type intr interrupt
  create_bd_pin -dir I -from 2 -to 0 pixel_mode
  create_bd_pin -dir I vid_active_video1
  create_bd_pin -dir I vid_hsync1
  create_bd_pin -dir I -type rst vid_reset
  create_bd_pin -dir I vid_vsync1
  create_bd_pin -dir I -from 47 -to 0 vid_pixel0_0
  create_bd_pin -dir I -from 47 -to 0 vid_pixel1_0
  create_bd_pin -dir I -type rst ap_rst_n1

  # Create instance: axi_gpio_1, and set properties
  set axi_gpio_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_1 ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {17} \
    CONFIG.C_GPIO_WIDTH {17} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_1


  # Create instance: nativevideo_axis_bridge, and set properties
  set nativevideo_axis_bridge [ create_bd_cell -type ip -vlnv xilinx.com:ip:dp_videoaxi4s_bridge nativevideo_axis_bridge ]
  set_property -dict [list \
    CONFIG.C_MAX_BPC {12} \
    CONFIG.C_M_AXIS_VIDEO_TDATA_WIDTH {72} \
    CONFIG.C_PPC {2} \
  ] $nativevideo_axis_bridge


  # Create instance: util_vector_logic_3, and set properties
  set util_vector_logic_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_3 ]
  set_property CONFIG.C_SIZE {1} $util_vector_logic_3


  # Create instance: v_frmbuf_wr_0, and set properties
  set v_frmbuf_wr_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_frmbuf_wr v_frmbuf_wr_0 ]
  set_property -dict [list \
    CONFIG.AXIMM_ADDR_WIDTH {32} \
    CONFIG.HAS_BGR8 {0} \
    CONFIG.HAS_BGRX8 {0} \
    CONFIG.HAS_RGB8 {1} \
    CONFIG.HAS_RGBX10 {1} \
    CONFIG.HAS_RGBX12 {1} \
    CONFIG.HAS_RGBX8 {1} \
    CONFIG.HAS_UYVY8 {1} \
    CONFIG.HAS_Y10 {1} \
    CONFIG.HAS_Y12 {1} \
    CONFIG.HAS_Y8 {1} \
    CONFIG.HAS_YUV8 {1} \
    CONFIG.HAS_YUVX10 {1} \
    CONFIG.HAS_YUVX12 {1} \
    CONFIG.HAS_YUVX8 {1} \
    CONFIG.HAS_YUYV8 {0} \
    CONFIG.HAS_Y_UV10 {1} \
    CONFIG.HAS_Y_UV10_420 {1} \
    CONFIG.HAS_Y_UV12 {1} \
    CONFIG.HAS_Y_UV12_420 {1} \
    CONFIG.HAS_Y_UV8 {0} \
    CONFIG.HAS_Y_UV8_420 {1} \
    CONFIG.HAS_Y_U_V10 {0} \
    CONFIG.HAS_Y_U_V8 {0} \
    CONFIG.MAX_COLS {8192} \
    CONFIG.MAX_DATA_WIDTH {12} \
    CONFIG.MAX_ROWS {4096} \
    CONFIG.SAMPLES_PER_CLOCK {2} \
  ] $v_frmbuf_wr_0


  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_2 ]

  # Create instance: xlconcat_3, and set properties
  set xlconcat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_3 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_gpio_1/S_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins v_frmbuf_wr_0/m_axi_mm_video] [get_bd_intf_pins m_axi_mm_video_0]
  connect_bd_intf_net -intf_net nativevideo_axis_bridge_m_axis_video [get_bd_intf_pins nativevideo_axis_bridge/m_axis_video] [get_bd_intf_pins v_frmbuf_wr_0/s_axis_video]
  connect_bd_intf_net -intf_net smartconnect_gp0_M22_AXI [get_bd_intf_pins s_axi_CTRL] [get_bd_intf_pins v_frmbuf_wr_0/s_axi_CTRL]

  # Create port connections
  connect_bd_net -net Net1  [get_bd_pins aclk] \
  [get_bd_pins axi_gpio_1/s_axi_aclk] \
  [get_bd_pins nativevideo_axis_bridge/m_axis_aclk] \
  [get_bd_pins nativevideo_axis_bridge/vid_pixel_clk] \
  [get_bd_pins v_frmbuf_wr_0/ap_clk]
  connect_bd_net -net Op2_1  [get_bd_pins Op2] \
  [get_bd_pins util_vector_logic_3/Op2]
  connect_bd_net -net Video_out8_interrupt  [get_bd_pins v_frmbuf_wr_0/interrupt] \
  [get_bd_pins interrupt]
  connect_bd_net -net ap_rst_n1_1  [get_bd_pins ap_rst_n1] \
  [get_bd_pins v_frmbuf_wr_0/ap_rst_n]
  connect_bd_net -net bpc_1  [get_bd_pins bpc] \
  [get_bd_pins nativevideo_axis_bridge/bpc]
  connect_bd_net -net color_format_1  [get_bd_pins color_format] \
  [get_bd_pins nativevideo_axis_bridge/color_format]
  connect_bd_net -net dp_hres_1  [get_bd_pins dp_hres] \
  [get_bd_pins nativevideo_axis_bridge/dp_hres]
  connect_bd_net -net nativevideo_axis_bridge_hres_cntr_out  [get_bd_pins nativevideo_axis_bridge/hres_cntr_out] \
  [get_bd_pins xlconcat_2/In0]
  connect_bd_net -net nativevideo_axis_bridge_m_axis_video_tvalid  [get_bd_pins nativevideo_axis_bridge/m_axis_video_tvalid] \
  [get_bd_pins util_vector_logic_3/Op1]
  connect_bd_net -net nativevideo_axis_bridge_vres_cntr_out  [get_bd_pins nativevideo_axis_bridge/vres_cntr_out] \
  [get_bd_pins xlconcat_3/In0]
  connect_bd_net -net pixel_mode_1  [get_bd_pins pixel_mode] \
  [get_bd_pins nativevideo_axis_bridge/pixel_mode]
  connect_bd_net -net rst_proc_cfg_clk1_peripheral_aresetn  [get_bd_pins aresetn1] \
  [get_bd_pins axi_gpio_1/s_axi_aresetn]
  connect_bd_net -net util_vector_logic_4_Res  [get_bd_pins util_vector_logic_3/Res] \
  [get_bd_pins v_frmbuf_wr_0/s_axis_video_TVALID]
  connect_bd_net -net vid_active_video1_1  [get_bd_pins vid_active_video1] \
  [get_bd_pins nativevideo_axis_bridge/vid_active_video]
  connect_bd_net -net vid_hsync1_1  [get_bd_pins vid_hsync1] \
  [get_bd_pins nativevideo_axis_bridge/vid_hsync] \
  [get_bd_pins xlconcat_2/In1]
  connect_bd_net -net vid_pixel0_0_1  [get_bd_pins vid_pixel0_0] \
  [get_bd_pins nativevideo_axis_bridge/vid_pixel0]
  connect_bd_net -net vid_pixel1_0_1  [get_bd_pins vid_pixel1_0] \
  [get_bd_pins nativevideo_axis_bridge/vid_pixel1]
  connect_bd_net -net vid_reset_1  [get_bd_pins vid_reset] \
  [get_bd_pins nativevideo_axis_bridge/vid_reset]
  connect_bd_net -net vid_vsync1_1  [get_bd_pins vid_vsync1] \
  [get_bd_pins nativevideo_axis_bridge/vid_vsync] \
  [get_bd_pins xlconcat_3/In1]
  connect_bd_net -net xlconcat_2_dout  [get_bd_pins xlconcat_2/dout] \
  [get_bd_pins axi_gpio_1/gpio_io_i]
  connect_bd_net -net xlconcat_3_dout  [get_bd_pins xlconcat_3/dout] \
  [get_bd_pins axi_gpio_1/gpio2_io_i]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: pl_audio_out
proc create_hier_cell_pl_audio_out { parentCell nameHier } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_s2mm

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl


  # Create pins
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk aud_mclk
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir O -type intr irq
  create_bd_pin -dir I -type rst s_axi_ctrl_aresetn
  create_bd_pin -dir I -from 3 -to 0 sdata
  create_bd_pin -dir I -type clk ps_cfg_clk

  # Create instance: audio_formatter_0, and set properties
  set audio_formatter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:audio_formatter audio_formatter_0 ]
  set_property CONFIG.C_INCLUDE_MM2S {0} $audio_formatter_0


  # Create instance: i2s_receiver_0, and set properties
  set i2s_receiver_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:i2s_receiver i2s_receiver_0 ]
  set_property CONFIG.C_NUM_CHANNELS {8} $i2s_receiver_0


  # Create instance: sdata_0, and set properties
  set sdata_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice sdata_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {0} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {4} \
  ] $sdata_0


  # Create instance: sdata_1, and set properties
  set sdata_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice sdata_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {4} \
  ] $sdata_1


  # Create instance: sdata_2, and set properties
  set sdata_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice sdata_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {2} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {4} \
  ] $sdata_2


  # Create instance: sdata_3, and set properties
  set sdata_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice sdata_3 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {3} \
    CONFIG.DIN_TO {3} \
    CONFIG.DIN_WIDTH {4} \
  ] $sdata_3


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins m_axi_s2mm] [get_bd_intf_pins audio_formatter_0/m_axi_s2mm]
  connect_bd_intf_net -intf_net i2s_receiver_0_m_axis_aud [get_bd_intf_pins audio_formatter_0/s_axis_s2mm] [get_bd_intf_pins i2s_receiver_0/m_axis_aud]
  connect_bd_intf_net -intf_net smartconnect_2_M01_AXI [get_bd_intf_pins s_axi_ctrl] [get_bd_intf_pins i2s_receiver_0/s_axi_ctrl]

  # Create port connections
  connect_bd_net -net clk_wiz_clk_out_1  [get_bd_pins aud_mclk] \
  [get_bd_pins audio_formatter_0/s_axi_lite_aclk] \
  [get_bd_pins audio_formatter_0/s_axis_s2mm_aclk] \
  [get_bd_pins i2s_receiver_0/aud_mclk] \
  [get_bd_pins i2s_receiver_0/m_axis_aud_aclk]
  connect_bd_net -net i2s_receiver_0_irq  [get_bd_pins i2s_receiver_0/irq] \
  [get_bd_pins irq]
  connect_bd_net -net mmi_dc_wrap_ip_0_if_mmi_pl_i2s0_i2sdata_i  [get_bd_pins sdata] \
  [get_bd_pins sdata_0/Din] \
  [get_bd_pins sdata_1/Din] \
  [get_bd_pins sdata_2/Din] \
  [get_bd_pins sdata_3/Din]
  connect_bd_net -net ps_cfg_clk_1  [get_bd_pins ps_cfg_clk] \
  [get_bd_pins i2s_receiver_0/s_axi_ctrl_aclk]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins aresetn] \
  [get_bd_pins audio_formatter_0/s_axi_lite_aresetn] \
  [get_bd_pins audio_formatter_0/s_axis_s2mm_aresetn] \
  [get_bd_pins i2s_receiver_0/m_axis_aud_aresetn]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins aud_mrst] \
  [get_bd_pins i2s_receiver_0/aud_mrst]
  connect_bd_net -net rst_processor_150MHz_interconnect_aresetn  [get_bd_pins s_axi_ctrl_aresetn] \
  [get_bd_pins i2s_receiver_0/s_axi_ctrl_aresetn]
  connect_bd_net -net xlslice_2_Dout  [get_bd_pins sdata_0/Dout] \
  [get_bd_pins i2s_receiver_0/sdata_0_in]
  connect_bd_net -net xlslice_3_Dout  [get_bd_pins sdata_1/Dout] \
  [get_bd_pins i2s_receiver_0/sdata_1_in]
  connect_bd_net -net xlslice_4_Dout  [get_bd_pins sdata_2/Dout] \
  [get_bd_pins i2s_receiver_0/sdata_2_in]
  connect_bd_net -net xlslice_5_Dout  [get_bd_pins sdata_3/Dout] \
  [get_bd_pins i2s_receiver_0/sdata_3_in]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: avtpg_s0
proc create_hier_cell_avtpg_s0 { parentCell nameHier } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 av_axi

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl


  # Create pins
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -from 2 -to 0 bpc
  create_bd_pin -dir I -from 2 -to 0 color_format
  create_bd_pin -dir I -from 15 -to 0 dp_hres
  create_bd_pin -dir I ext_sdp00_ack_i_0
  create_bd_pin -dir O -from 71 -to 0 ext_sdp00_data_o_0
  create_bd_pin -dir I ext_sdp00_horizontal_blanking_i_0
  create_bd_pin -dir I -from 1 -to 0 ext_sdp00_line_cnt_mat_i_0
  create_bd_pin -dir O ext_sdp00_req_o_0
  create_bd_pin -dir I ext_sdp00_vertical_blanking_i_0
  create_bd_pin -dir I ext_sdp01_ack_i_0
  create_bd_pin -dir O -from 71 -to 0 ext_sdp01_data_o_0
  create_bd_pin -dir I ext_sdp01_horizontal_blanking_i_0
  create_bd_pin -dir I -from 1 -to 0 ext_sdp01_line_cnt_mat_i_0
  create_bd_pin -dir O ext_sdp01_req_o_0
  create_bd_pin -dir I ext_sdp01_vertical_blanking_i_0
  create_bd_pin -dir I -type clk i2s_clk
  create_bd_pin -dir O lrclk_out
  create_bd_pin -dir I -type rst peripheral_aresetn3
  create_bd_pin -dir I -from 2 -to 0 pixel_mode
  create_bd_pin -dir I -from 2 -to 0 ppc
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type rst s_axis_aud_aresetn
  create_bd_pin -dir O -from 3 -to 0 sdata_out
  create_bd_pin -dir I -type clk vid_clk
  create_bd_pin -dir I -from 2 -to 0 vid_format
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN_0
  create_bd_pin -dir I -type rst peripheral_aresetn2
  create_bd_pin -dir O sclk_out

  # Create instance: av_pat_gen_0, and set properties
  set av_pat_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:av_pat_gen av_pat_gen_0 ]
  set_property -dict [list \
    CONFIG.BPC {12} \
    CONFIG.PPC {4} \
  ] $av_pat_gen_0


  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {16} \
    CONFIG.C_GPIO_WIDTH {16} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_0


  # Create instance: axis_nativevideo_bridge, and set properties
  set axis_nativevideo_bridge [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi4svideo_bridge axis_nativevideo_bridge ]
  set_property -dict [list \
    CONFIG.pBPC {12} \
    CONFIG.pTDATA_NUM_BYTES {144} \
  ] $axis_nativevideo_bridge


  # Create instance: i2s_transmitter_0, and set properties
  set i2s_transmitter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:i2s_transmitter i2s_transmitter_0 ]
  set_property CONFIG.C_NUM_CHANNELS {8} $i2s_transmitter_0


  # Create instance: nativevideo_axis_bridge_1, and set properties
  set nativevideo_axis_bridge_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dp_videoaxi4s_bridge nativevideo_axis_bridge_1 ]
  set_property CONFIG.C_PPC {2} $nativevideo_axis_bridge_1


  # Create instance: v_tc_0, and set properties
  set v_tc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc v_tc_0 ]
  set_property -dict [list \
    CONFIG.VIDEO_MODE {1080p} \
    CONFIG.enable_detection {false} \
    CONFIG.max_clocks_per_line {8192} \
  ] $v_tc_0


  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_2 ]
  set_property CONFIG.NUM_PORTS {4} $xlconcat_2


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_1 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_1


  # Create instance: xlconstant_3, and set properties
  set xlconstant_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_3 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {1} \
  ] $xlconstant_3


  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {47} \
    CONFIG.DIN_WIDTH {144} \
  ] $xlslice_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ctrl] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins av_axi] [get_bd_intf_pins av_pat_gen_0/av_axi]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net av_pat_gen_0_aud_out_axi4s [get_bd_intf_pins av_pat_gen_0/aud_out_axi4s] [get_bd_intf_pins i2s_transmitter_0/s_axis_aud]
  connect_bd_intf_net -intf_net av_pat_gen_0_vid_out_axi4s [get_bd_intf_pins av_pat_gen_0/vid_out_axi4s] [get_bd_intf_pins axis_nativevideo_bridge/s_axis_video]
  connect_bd_intf_net -intf_net smartconnect_gp0_M03_AXI [get_bd_intf_pins s_axi_ctrl] [get_bd_intf_pins i2s_transmitter_0/s_axi_ctrl]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins axis_nativevideo_bridge/vid_timing_in] [get_bd_intf_pins v_tc_0/vtiming_out]

  # Create port connections
  connect_bd_net -net Net  [get_bd_pins axis_nativevideo_bridge/tx_vid_clk] \
  [get_bd_pins nativevideo_axis_bridge_1/m_axis_aclk] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_pixel_clk]
  connect_bd_net -net TPG_GEN_EN_0_1  [get_bd_pins TPG_GEN_EN_0] \
  [get_bd_pins av_pat_gen_0/TPG_GEN_EN]
  connect_bd_net -net aud_out_axi4s_aclk_1  [get_bd_pins i2s_clk] \
  [get_bd_pins av_pat_gen_0/aud_clk] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aclk] \
  [get_bd_pins i2s_transmitter_0/aud_mclk] \
  [get_bd_pins i2s_transmitter_0/s_axis_aud_aclk]
  connect_bd_net -net av_pat_gen_0_ext_sdp00_data_o  [get_bd_pins av_pat_gen_0/ext_sdp00_data_o] \
  [get_bd_pins ext_sdp00_data_o_0]
  connect_bd_net -net av_pat_gen_0_ext_sdp00_req_o  [get_bd_pins av_pat_gen_0/ext_sdp00_req_o] \
  [get_bd_pins ext_sdp00_req_o_0]
  connect_bd_net -net av_pat_gen_0_ext_sdp01_data_o  [get_bd_pins av_pat_gen_0/ext_sdp01_data_o] \
  [get_bd_pins ext_sdp01_data_o_0]
  connect_bd_net -net av_pat_gen_0_ext_sdp01_req_o  [get_bd_pins av_pat_gen_0/ext_sdp01_req_o] \
  [get_bd_pins ext_sdp01_req_o_0]
  connect_bd_net -net axis_nativevideo_bridge_sof_state_out  [get_bd_pins axis_nativevideo_bridge/sof_state_out] \
  [get_bd_pins v_tc_0/sof_state]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_enable  [get_bd_pins axis_nativevideo_bridge/tx_vid_enable] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_active_video]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_hsync  [get_bd_pins axis_nativevideo_bridge/tx_vid_hsync] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_hsync]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_pixel  [get_bd_pins axis_nativevideo_bridge/tx_vid_pixel] \
  [get_bd_pins xlslice_0/Din]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_reset  [get_bd_pins axis_nativevideo_bridge/tx_vid_reset] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_reset]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_vsync  [get_bd_pins axis_nativevideo_bridge/tx_vid_vsync] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_vsync]
  connect_bd_net -net axis_nativevideo_bridge_vtg_ce  [get_bd_pins axis_nativevideo_bridge/vtg_ce] \
  [get_bd_pins v_tc_0/gen_clken]
  connect_bd_net -net bpc_1  [get_bd_pins bpc] \
  [get_bd_pins nativevideo_axis_bridge_1/bpc]
  connect_bd_net -net color_format_1  [get_bd_pins color_format] \
  [get_bd_pins nativevideo_axis_bridge_1/color_format]
  connect_bd_net -net dp_hres_1  [get_bd_pins dp_hres] \
  [get_bd_pins nativevideo_axis_bridge_1/dp_hres]
  connect_bd_net -net ext_sdp00_ack_i_0_1  [get_bd_pins ext_sdp00_ack_i_0] \
  [get_bd_pins av_pat_gen_0/ext_sdp00_ack_i]
  connect_bd_net -net ext_sdp00_horizontal_blanking_i_0_1  [get_bd_pins ext_sdp00_horizontal_blanking_i_0] \
  [get_bd_pins av_pat_gen_0/ext_sdp00_horizontal_blanking_i]
  connect_bd_net -net ext_sdp00_line_cnt_mat_i_0_1  [get_bd_pins ext_sdp00_line_cnt_mat_i_0] \
  [get_bd_pins av_pat_gen_0/ext_sdp00_line_cnt_mat_i]
  connect_bd_net -net ext_sdp00_vertical_blanking_i_0_1  [get_bd_pins ext_sdp00_vertical_blanking_i_0] \
  [get_bd_pins av_pat_gen_0/ext_sdp00_vertical_blanking_i]
  connect_bd_net -net ext_sdp01_ack_i_0_1  [get_bd_pins ext_sdp01_ack_i_0] \
  [get_bd_pins av_pat_gen_0/ext_sdp01_ack_i]
  connect_bd_net -net ext_sdp01_horizontal_blanking_i_0_1  [get_bd_pins ext_sdp01_horizontal_blanking_i_0] \
  [get_bd_pins av_pat_gen_0/ext_sdp01_horizontal_blanking_i]
  connect_bd_net -net ext_sdp01_line_cnt_mat_i_0_1  [get_bd_pins ext_sdp01_line_cnt_mat_i_0] \
  [get_bd_pins av_pat_gen_0/ext_sdp01_line_cnt_mat_i]
  connect_bd_net -net ext_sdp01_vertical_blanking_i_0_1  [get_bd_pins ext_sdp01_vertical_blanking_i_0] \
  [get_bd_pins av_pat_gen_0/ext_sdp01_vertical_blanking_i]
  connect_bd_net -net i2s_transmitter_0_lrclk_out  [get_bd_pins i2s_transmitter_0/lrclk_out] \
  [get_bd_pins lrclk_out]
  connect_bd_net -net i2s_transmitter_0_sclk_out  [get_bd_pins i2s_transmitter_0/sclk_out] \
  [get_bd_pins sclk_out]
  connect_bd_net -net i2s_transmitter_0_sdata_0_out  [get_bd_pins i2s_transmitter_0/sdata_0_out] \
  [get_bd_pins xlconcat_2/In0]
  connect_bd_net -net i2s_transmitter_0_sdata_1_out  [get_bd_pins i2s_transmitter_0/sdata_1_out] \
  [get_bd_pins xlconcat_2/In1]
  connect_bd_net -net i2s_transmitter_0_sdata_2_out  [get_bd_pins i2s_transmitter_0/sdata_2_out] \
  [get_bd_pins xlconcat_2/In2]
  connect_bd_net -net i2s_transmitter_0_sdata_3_out  [get_bd_pins i2s_transmitter_0/sdata_3_out] \
  [get_bd_pins xlconcat_2/In3]
  connect_bd_net -net nativevideo_axis_bridge_1_hres_cntr_out  [get_bd_pins nativevideo_axis_bridge_1/hres_cntr_out] \
  [get_bd_pins axi_gpio_0/gpio_io_i]
  connect_bd_net -net nativevideo_axis_bridge_1_vres_cntr_out  [get_bd_pins nativevideo_axis_bridge_1/vres_cntr_out] \
  [get_bd_pins axi_gpio_0/gpio2_io_i]
  connect_bd_net -net net_mb_ss_0_clk_out2  [get_bd_pins av_axi_aclk] \
  [get_bd_pins av_pat_gen_0/av_axi_aclk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins i2s_transmitter_0/s_axi_ctrl_aclk] \
  [get_bd_pins v_tc_0/s_axi_aclk]
  connect_bd_net -net peripheral_aresetn2_1  [get_bd_pins peripheral_aresetn2] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aresetn] \
  [get_bd_pins i2s_transmitter_0/s_axis_aud_aresetn]
  connect_bd_net -net peripheral_aresetn3_1  [get_bd_pins peripheral_aresetn3] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn]
  connect_bd_net -net pixel_mode_1  [get_bd_pins pixel_mode] \
  [get_bd_pins nativevideo_axis_bridge_1/pixel_mode]
  connect_bd_net -net ppc_1  [get_bd_pins ppc] \
  [get_bd_pins axis_nativevideo_bridge/ppc]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins aud_mrst] \
  [get_bd_pins i2s_transmitter_0/aud_mrst]
  connect_bd_net -net rst_processor_150MHz_interconnect_aresetn  [get_bd_pins s_axi_aresetn] \
  [get_bd_pins av_pat_gen_0/av_axi_aresetn] \
  [get_bd_pins i2s_transmitter_0/s_axi_ctrl_aresetn] \
  [get_bd_pins v_tc_0/s_axi_aresetn]
  connect_bd_net -net vid_format_1  [get_bd_pins vid_format] \
  [get_bd_pins axis_nativevideo_bridge/vid_format]
  connect_bd_net -net vid_out_axi4s_aclk_1  [get_bd_pins vid_clk] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aclk] \
  [get_bd_pins axis_nativevideo_bridge/aclk] \
  [get_bd_pins axis_nativevideo_bridge/vid_io_out_clk] \
  [get_bd_pins v_tc_0/clk]
  connect_bd_net -net vid_out_axi4s_aresetn_1  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aresetn] \
  [get_bd_pins axis_nativevideo_bridge/aresetn] \
  [get_bd_pins v_tc_0/resetn]
  connect_bd_net -net xlconcat_2_dout  [get_bd_pins xlconcat_2/dout] \
  [get_bd_pins sdata_out]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins axis_nativevideo_bridge/aclken] \
  [get_bd_pins axis_nativevideo_bridge/vid_io_out_ce] \
  [get_bd_pins v_tc_0/clken] \
  [get_bd_pins v_tc_0/s_axi_aclken]
  connect_bd_net -net xlconstant_1_dout  [get_bd_pins xlconstant_1/dout] \
  [get_bd_pins axis_nativevideo_bridge/fid] \
  [get_bd_pins v_tc_0/fsync_in]
  connect_bd_net -net xlconstant_3_dout  [get_bd_pins xlconstant_3/dout] \
  [get_bd_pins axis_nativevideo_bridge/rst] \
  [get_bd_pins axis_nativevideo_bridge/soft_reset]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_pixel0]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: avtpg_vp1
proc create_hier_cell_avtpg_vp1 { parentCell nameHier } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 av_axi

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf


  # Create pins
  create_bd_pin -dir I Op1
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -from 2 -to 0 bpc
  create_bd_pin -dir I -type ce clken
  create_bd_pin -dir I -from 2 -to 0 color_format
  create_bd_pin -dir I -from 15 -to 0 dp_hres
  create_bd_pin -dir I -type clk i2s_clk
  create_bd_pin -dir I -type rst peripheral_aresetn3
  create_bd_pin -dir I -from 2 -to 0 pixel_mode
  create_bd_pin -dir I -from 2 -to 0 ppc
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type rst s_axis_aud_aresetn
  create_bd_pin -dir O -from 0 -to 0 tx_vid_enable
  create_bd_pin -dir O -from 71 -to 0 tx_vid_pixel
  create_bd_pin -dir I -type clk vid_clk
  create_bd_pin -dir I -from 2 -to 0 vid_format
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_active_video
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_hblank
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_hsync
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_vblank
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_vsync

  # Create instance: av_pat_gen_0, and set properties
  set av_pat_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:av_pat_gen av_pat_gen_0 ]
  set_property -dict [list \
    CONFIG.BPC {12} \
    CONFIG.PPC {2} \
  ] $av_pat_gen_0


  # Create instance: avtpg_tready_gated, and set properties
  set avtpg_tready_gated [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic avtpg_tready_gated ]
  set_property -dict [list \
    CONFIG.C_OPERATION {or} \
    CONFIG.C_SIZE {1} \
  ] $avtpg_tready_gated


  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {17} \
    CONFIG.C_GPIO_WIDTH {17} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_0


  # Create instance: axis2video_tvalid_gate, and set properties
  set axis2video_tvalid_gate [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic axis2video_tvalid_gate ]
  set_property CONFIG.C_SIZE {1} $axis2video_tvalid_gate


  # Create instance: axis_nativevideo_bridge, and set properties
  set axis_nativevideo_bridge [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi4svideo_bridge axis_nativevideo_bridge ]
  set_property -dict [list \
    CONFIG.pBPC {12} \
    CONFIG.pPIXELS_PER_CLOCK {2} \
    CONFIG.pTDATA_NUM_BYTES {72} \
  ] $axis_nativevideo_bridge


  # Create instance: c_shift_ram_1_delay, and set properties
  set c_shift_ram_1_delay [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram c_shift_ram_1_delay ]
  set_property -dict [list \
    CONFIG.Depth {1} \
    CONFIG.Width {1} \
  ] $c_shift_ram_1_delay


  # Create instance: c_shift_ram_4_delay, and set properties
  set c_shift_ram_4_delay [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_shift_ram c_shift_ram_4_delay ]
  set_property -dict [list \
    CONFIG.Depth {4} \
    CONFIG.Width {1} \
  ] $c_shift_ram_4_delay


  # Create instance: nativevideo_axis_bridge_2, and set properties
  set nativevideo_axis_bridge_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dp_videoaxi4s_bridge nativevideo_axis_bridge_2 ]
  set_property -dict [list \
    CONFIG.C_MAX_BPC {12} \
    CONFIG.C_PPC {2} \
  ] $nativevideo_axis_bridge_2


  # Create instance: tvalid_gate_control, and set properties
  set tvalid_gate_control [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic tvalid_gate_control ]
  set_property -dict [list \
    CONFIG.C_OPERATION {or} \
    CONFIG.C_SIZE {1} \
  ] $tvalid_gate_control


  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_0 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {and} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_0


  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_2 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {or} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_2


  # Create instance: util_vector_logic_4, and set properties
  set util_vector_logic_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_4 ]
  set_property CONFIG.C_SIZE {1} $util_vector_logic_4


  # Create instance: util_vector_logic_6, and set properties
  set util_vector_logic_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_6 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_6


  # Create instance: util_vector_logic_7, and set properties
  set util_vector_logic_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_7 ]
  set_property CONFIG.C_SIZE {1} $util_vector_logic_7


  # Create instance: v_tc_0, and set properties
  set v_tc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc v_tc_0 ]
  set_property -dict [list \
    CONFIG.VIDEO_MODE {1080p} \
    CONFIG.enable_detection {false} \
    CONFIG.max_clocks_per_line {8192} \
  ] $v_tc_0


  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_2 ]

  # Create instance: xlconcat_3, and set properties
  set xlconcat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_3 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_1 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_1


  # Create instance: xlconstant_2, and set properties
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_2 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_2


  # Create instance: xlconstant_3, and set properties
  set xlconstant_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_3 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {1} \
  ] $xlconstant_3


  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {47} \
    CONFIG.DIN_WIDTH {72} \
  ] $xlslice_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ctrl] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins av_axi] [get_bd_intf_pins av_pat_gen_0/av_axi]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins axis_nativevideo_bridge/vid_intf] [get_bd_intf_pins vid_intf]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net av_pat_gen_0_vid_out_axi4s [get_bd_intf_pins av_pat_gen_0/vid_out_axi4s] [get_bd_intf_pins axis_nativevideo_bridge/s_axis_video]

  # Create port connections
  connect_bd_net -net Net  [get_bd_pins axis_nativevideo_bridge/tx_vid_clk] \
  [get_bd_pins nativevideo_axis_bridge_2/m_axis_aclk] \
  [get_bd_pins nativevideo_axis_bridge_2/vid_pixel_clk]
  connect_bd_net -net Net1  [get_bd_pins xlconstant_3/dout] \
  [get_bd_pins axis_nativevideo_bridge/rst] \
  [get_bd_pins axis_nativevideo_bridge/soft_reset]
  connect_bd_net -net Op1_1  [get_bd_pins Op1] \
  [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins TPG_GEN_EN] \
  [get_bd_pins av_pat_gen_0/TPG_GEN_EN] \
  [get_bd_pins axis_nativevideo_bridge/vid_io_out_ce]
  connect_bd_net -net aud_out_axi4s_aclk_1  [get_bd_pins i2s_clk] \
  [get_bd_pins av_pat_gen_0/aud_clk] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aclk]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tdata  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tdata] \
  [get_bd_pins axis_nativevideo_bridge/video_in_tdata]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tlast  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tlast] \
  [get_bd_pins axis_nativevideo_bridge/video_in_tlast]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tuser  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tuser] \
  [get_bd_pins axis_nativevideo_bridge/video_in_tuser]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tvalid  [get_bd_pins axis2video_tvalid_gate/Res] \
  [get_bd_pins axis_nativevideo_bridge/video_in_tvalid]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tvalid1  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tvalid] \
  [get_bd_pins axis2video_tvalid_gate/Op1]
  connect_bd_net -net axis_nativevideo_bridge_sof_state_out  [get_bd_pins axis_nativevideo_bridge/sof_state_out] \
  [get_bd_pins v_tc_0/sof_state]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_enable  [get_bd_pins axis_nativevideo_bridge/tx_vid_enable] \
  [get_bd_pins tx_vid_enable] \
  [get_bd_pins nativevideo_axis_bridge_2/vid_active_video]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_hsync  [get_bd_pins axis_nativevideo_bridge/tx_vid_hsync] \
  [get_bd_pins nativevideo_axis_bridge_2/vid_hsync] \
  [get_bd_pins xlconcat_2/In1]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_pixel  [get_bd_pins axis_nativevideo_bridge/tx_vid_pixel] \
  [get_bd_pins tx_vid_pixel] \
  [get_bd_pins xlslice_0/Din]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_reset  [get_bd_pins axis_nativevideo_bridge/tx_vid_reset] \
  [get_bd_pins nativevideo_axis_bridge_2/vid_reset]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_vsync  [get_bd_pins axis_nativevideo_bridge/tx_vid_vsync] \
  [get_bd_pins nativevideo_axis_bridge_2/vid_vsync] \
  [get_bd_pins xlconcat_3/In1]
  connect_bd_net -net axis_nativevideo_bridge_video_in_tready  [get_bd_pins avtpg_tready_gated/Res] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tready]
  connect_bd_net -net axis_nativevideo_bridge_video_in_tready1  [get_bd_pins axis_nativevideo_bridge/video_in_tready] \
  [get_bd_pins c_shift_ram_4_delay/D] \
  [get_bd_pins util_vector_logic_4/Op2]
  connect_bd_net -net axis_nativevideo_bridge_vtg_ce  [get_bd_pins axis_nativevideo_bridge/vtg_ce] \
  [get_bd_pins v_tc_0/gen_clken]
  connect_bd_net -net bpc_1  [get_bd_pins bpc] \
  [get_bd_pins nativevideo_axis_bridge_2/bpc]
  connect_bd_net -net c_shift_ram_1_delay_Q  [get_bd_pins tvalid_gate_control/Res] \
  [get_bd_pins axis2video_tvalid_gate/Op2] \
  [get_bd_pins c_shift_ram_1_delay/D] \
  [get_bd_pins util_vector_logic_4/Op1] \
  [get_bd_pins util_vector_logic_6/Op1]
  connect_bd_net -net c_shift_ram_1_delay_Q1  [get_bd_pins c_shift_ram_1_delay/Q] \
  [get_bd_pins tvalid_gate_control/Op1] \
  [get_bd_pins util_vector_logic_2/Op2]
  connect_bd_net -net c_shift_ram_4_delay_Q  [get_bd_pins c_shift_ram_4_delay/Q] \
  [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net clken_1  [get_bd_pins clken] \
  [get_bd_pins v_tc_0/clken]
  connect_bd_net -net color_format_1  [get_bd_pins color_format] \
  [get_bd_pins nativevideo_axis_bridge_2/color_format]
  connect_bd_net -net dp_hres_1  [get_bd_pins dp_hres] \
  [get_bd_pins nativevideo_axis_bridge_2/dp_hres]
  connect_bd_net -net nativevideo_axis_bridge_2_hres_cntr_out  [get_bd_pins nativevideo_axis_bridge_2/hres_cntr_out] \
  [get_bd_pins xlconcat_2/In0]
  connect_bd_net -net nativevideo_axis_bridge_2_vres_cntr_out  [get_bd_pins nativevideo_axis_bridge_2/vres_cntr_out] \
  [get_bd_pins xlconcat_3/In0]
  connect_bd_net -net net_mb_ss_0_clk_out2  [get_bd_pins av_axi_aclk] \
  [get_bd_pins av_pat_gen_0/av_axi_aclk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins v_tc_0/s_axi_aclk]
  connect_bd_net -net pixel_mode_1  [get_bd_pins pixel_mode] \
  [get_bd_pins nativevideo_axis_bridge_2/pixel_mode]
  connect_bd_net -net ppc_1  [get_bd_pins ppc] \
  [get_bd_pins axis_nativevideo_bridge/ppc]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins s_axis_aud_aresetn] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aresetn]
  connect_bd_net -net util_vector_logic_0_Res  [get_bd_pins util_vector_logic_0/Res] \
  [get_bd_pins tvalid_gate_control/Op2]
  connect_bd_net -net util_vector_logic_2_Res  [get_bd_pins util_vector_logic_2/Res] \
  [get_bd_pins util_vector_logic_0/Op2]
  connect_bd_net -net util_vector_logic_4_Res  [get_bd_pins util_vector_logic_4/Res] \
  [get_bd_pins avtpg_tready_gated/Op1]
  connect_bd_net -net util_vector_logic_6_Res  [get_bd_pins util_vector_logic_6/Res] \
  [get_bd_pins util_vector_logic_7/Op1]
  connect_bd_net -net util_vector_logic_7_Res  [get_bd_pins util_vector_logic_7/Res] \
  [get_bd_pins avtpg_tready_gated/Op2]
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins axis_nativevideo_bridge/aclken] \
  [get_bd_pins v_tc_0/s_axi_aclken]
  connect_bd_net -net vid_format_1  [get_bd_pins vid_format] \
  [get_bd_pins axis_nativevideo_bridge/vid_format]
  connect_bd_net -net vid_out_axi4s_aclk_1  [get_bd_pins vid_clk] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aclk] \
  [get_bd_pins axis_nativevideo_bridge/aclk] \
  [get_bd_pins axis_nativevideo_bridge/vid_io_out_clk] \
  [get_bd_pins c_shift_ram_1_delay/CLK] \
  [get_bd_pins c_shift_ram_4_delay/CLK] \
  [get_bd_pins v_tc_0/clk]
  connect_bd_net -net vid_out_axi4s_aresetn_1  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aresetn] \
  [get_bd_pins axis_nativevideo_bridge/aresetn] \
  [get_bd_pins v_tc_0/resetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins v_tc_0/s_axi_aresetn] \
  [get_bd_pins av_pat_gen_0/av_axi_aresetn]
  connect_bd_net -net vtiming_in_active_video_1  [get_bd_pins vtiming_in_active_video] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_active_video]
  connect_bd_net -net vtiming_in_hblank_1  [get_bd_pins vtiming_in_hblank] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_hblank]
  connect_bd_net -net vtiming_in_hsync_1  [get_bd_pins vtiming_in_hsync] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_hsync]
  connect_bd_net -net vtiming_in_vblank_1  [get_bd_pins vtiming_in_vblank] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_vblank]
  connect_bd_net -net vtiming_in_vsync_1  [get_bd_pins vtiming_in_vsync] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_vsync]
  connect_bd_net -net xlconcat_2_dout  [get_bd_pins xlconcat_2/dout] \
  [get_bd_pins axi_gpio_0/gpio_io_i]
  connect_bd_net -net xlconcat_3_dout  [get_bd_pins xlconcat_3/dout] \
  [get_bd_pins axi_gpio_0/gpio2_io_i]
  connect_bd_net -net xlconstant_1_dout  [get_bd_pins xlconstant_1/dout] \
  [get_bd_pins axis_nativevideo_bridge/fid] \
  [get_bd_pins v_tc_0/fsync_in]
  connect_bd_net -net xlconstant_2_dout  [get_bd_pins xlconstant_2/dout] \
  [get_bd_pins util_vector_logic_7/Op2]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins nativevideo_axis_bridge_2/vid_pixel0]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: avtpg_vp0
proc create_hier_cell_avtpg_vp0 { parentCell nameHier } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 av_axi

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf


  # Create pins
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN
  create_bd_pin -dir O -from 0 -to 0 active_video_out
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -from 2 -to 0 bpc
  create_bd_pin -dir I -type ce clken
  create_bd_pin -dir I -from 2 -to 0 color_format
  create_bd_pin -dir I -from 15 -to 0 dp_hres
  create_bd_pin -dir O -from 0 -to 0 hblank_out
  create_bd_pin -dir O -from 0 -to 0 hsync_out
  create_bd_pin -dir I -type clk i2s_clk
  create_bd_pin -dir I -type rst peripheral_aresetn3
  create_bd_pin -dir I -from 2 -to 0 pixel_mode
  create_bd_pin -dir I -from 2 -to 0 ppc
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type rst s_axis_aud_aresetn
  create_bd_pin -dir I -from 0 -to 0 -type data tx_vid_enable1
  create_bd_pin -dir I -from 71 -to 0 -type data tx_vid_pixel1
  create_bd_pin -dir O -from 0 -to 0 vblank_out
  create_bd_pin -dir I -type clk vid_clk
  create_bd_pin -dir I -from 2 -to 0 vid_format
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir O vid_out_axi4s_tvalid
  create_bd_pin -dir O -from 0 -to 0 vsync_out

  # Create instance: av_pat_gen_0, and set properties
  set av_pat_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:av_pat_gen av_pat_gen_0 ]
  set_property -dict [list \
    CONFIG.BPC {12} \
    CONFIG.PPC {2} \
  ] $av_pat_gen_0


  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {17} \
    CONFIG.C_GPIO_WIDTH {17} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_0


  # Create instance: axis_nativevideo_bridge, and set properties
  set axis_nativevideo_bridge [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi4svideo_bridge axis_nativevideo_bridge ]
  set_property -dict [list \
    CONFIG.pBPC {12} \
    CONFIG.pPIXELS_PER_CLOCK {2} \
    CONFIG.pTDATA_NUM_BYTES {72} \
  ] $axis_nativevideo_bridge


  # Create instance: nativevideo_axis_bridge_1, and set properties
  set nativevideo_axis_bridge_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dp_videoaxi4s_bridge nativevideo_axis_bridge_1 ]
  set_property -dict [list \
    CONFIG.C_MAX_BPC {12} \
    CONFIG.C_PPC {2} \
  ] $nativevideo_axis_bridge_1


  # Create instance: v_tc_0, and set properties
  set v_tc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc v_tc_0 ]
  set_property -dict [list \
    CONFIG.VIDEO_MODE {1080p} \
    CONFIG.enable_detection {false} \
    CONFIG.max_clocks_per_line {8192} \
  ] $v_tc_0


  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_1 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_1 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_1


  # Create instance: xlconstant_3, and set properties
  set xlconstant_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_3 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {1} \
  ] $xlconstant_3


  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {47} \
    CONFIG.DIN_WIDTH {72} \
  ] $xlslice_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ctrl] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins av_axi] [get_bd_intf_pins av_pat_gen_0/av_axi]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins axis_nativevideo_bridge/vid_intf] [get_bd_intf_pins vid_intf]
  connect_bd_intf_net -intf_net av_pat_gen_0_vid_out_axi4s [get_bd_intf_pins av_pat_gen_0/vid_out_axi4s] [get_bd_intf_pins axis_nativevideo_bridge/s_axis_video]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins axis_nativevideo_bridge/vid_timing_in] [get_bd_intf_pins v_tc_0/vtiming_out]

  # Create port connections
  connect_bd_net -net Net  [get_bd_pins axis_nativevideo_bridge/tx_vid_clk] \
  [get_bd_pins nativevideo_axis_bridge_1/m_axis_aclk] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_pixel_clk]
  connect_bd_net -net Net1  [get_bd_pins axis_nativevideo_bridge/video_in_tready] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tready]
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins TPG_GEN_EN] \
  [get_bd_pins av_pat_gen_0/TPG_GEN_EN] \
  [get_bd_pins axis_nativevideo_bridge/vid_io_out_ce]
  connect_bd_net -net aud_out_axi4s_aclk_1  [get_bd_pins i2s_clk] \
  [get_bd_pins av_pat_gen_0/aud_clk] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aclk]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tdata  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tdata] \
  [get_bd_pins axis_nativevideo_bridge/video_in_tdata]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tlast  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tlast] \
  [get_bd_pins axis_nativevideo_bridge/video_in_tlast]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tuser  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tuser] \
  [get_bd_pins axis_nativevideo_bridge/video_in_tuser]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tvalid  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tvalid] \
  [get_bd_pins vid_out_axi4s_tvalid] \
  [get_bd_pins axis_nativevideo_bridge/video_in_tvalid]
  connect_bd_net -net axis_nativevideo_bridge_sof_state_out  [get_bd_pins axis_nativevideo_bridge/sof_state_out] \
  [get_bd_pins v_tc_0/sof_state]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_enable  [get_bd_pins axis_nativevideo_bridge/tx_vid_enable] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_active_video]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_hsync  [get_bd_pins axis_nativevideo_bridge/tx_vid_hsync] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_hsync] \
  [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_pixel  [get_bd_pins axis_nativevideo_bridge/tx_vid_pixel] \
  [get_bd_pins xlslice_0/Din]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_reset  [get_bd_pins axis_nativevideo_bridge/tx_vid_reset] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_reset]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_vsync  [get_bd_pins axis_nativevideo_bridge/tx_vid_vsync] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_vsync] \
  [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net axis_nativevideo_bridge_vtg_ce  [get_bd_pins axis_nativevideo_bridge/vtg_ce] \
  [get_bd_pins v_tc_0/gen_clken]
  connect_bd_net -net bpc_1  [get_bd_pins bpc] \
  [get_bd_pins nativevideo_axis_bridge_1/bpc]
  connect_bd_net -net clken_1  [get_bd_pins clken] \
  [get_bd_pins v_tc_0/clken]
  connect_bd_net -net color_format_1  [get_bd_pins color_format] \
  [get_bd_pins nativevideo_axis_bridge_1/color_format]
  connect_bd_net -net dp_hres_1  [get_bd_pins dp_hres] \
  [get_bd_pins nativevideo_axis_bridge_1/dp_hres]
  connect_bd_net -net nativevideo_axis_bridge_1_hres_cntr_out  [get_bd_pins nativevideo_axis_bridge_1/hres_cntr_out] \
  [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net nativevideo_axis_bridge_1_vres_cntr_out  [get_bd_pins nativevideo_axis_bridge_1/vres_cntr_out] \
  [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net net_mb_ss_0_clk_out2  [get_bd_pins av_axi_aclk] \
  [get_bd_pins av_pat_gen_0/av_axi_aclk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins v_tc_0/s_axi_aclk]
  connect_bd_net -net pixel_mode_1  [get_bd_pins pixel_mode] \
  [get_bd_pins nativevideo_axis_bridge_1/pixel_mode]
  connect_bd_net -net ppc_1  [get_bd_pins ppc] \
  [get_bd_pins axis_nativevideo_bridge/ppc]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins s_axis_aud_aresetn] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aresetn]
  connect_bd_net -net v_tc_0_active_video_out  [get_bd_pins v_tc_0/active_video_out] \
  [get_bd_pins active_video_out] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_active_video]
  connect_bd_net -net v_tc_0_hblank_out  [get_bd_pins v_tc_0/hblank_out] \
  [get_bd_pins hblank_out] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_hblank]
  connect_bd_net -net v_tc_0_hsync_out  [get_bd_pins v_tc_0/hsync_out] \
  [get_bd_pins hsync_out] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_hsync]
  connect_bd_net -net v_tc_0_vblank_out  [get_bd_pins v_tc_0/vblank_out] \
  [get_bd_pins vblank_out] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_vblank]
  connect_bd_net -net v_tc_0_vsync_out  [get_bd_pins v_tc_0/vsync_out] \
  [get_bd_pins vsync_out] \
  [get_bd_pins axis_nativevideo_bridge/vtiming_in_vsync]
  connect_bd_net -net vid_format_1  [get_bd_pins vid_format] \
  [get_bd_pins axis_nativevideo_bridge/vid_format]
  connect_bd_net -net vid_out_axi4s_aclk_1  [get_bd_pins vid_clk] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aclk] \
  [get_bd_pins axis_nativevideo_bridge/aclk] \
  [get_bd_pins axis_nativevideo_bridge/vid_io_out_clk] \
  [get_bd_pins v_tc_0/clk]
  connect_bd_net -net vid_out_axi4s_aresetn_1  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aresetn] \
  [get_bd_pins axis_nativevideo_bridge/aresetn] \
  [get_bd_pins v_tc_0/resetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins v_tc_0/s_axi_aresetn] \
  [get_bd_pins av_pat_gen_0/av_axi_aresetn]
  connect_bd_net -net xlconcat_0_dout  [get_bd_pins xlconcat_0/dout] \
  [get_bd_pins axi_gpio_0/gpio_io_i]
  connect_bd_net -net xlconcat_1_dout  [get_bd_pins xlconcat_1/dout] \
  [get_bd_pins axi_gpio_0/gpio2_io_i]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins axis_nativevideo_bridge/aclken] \
  [get_bd_pins v_tc_0/s_axi_aclken]
  connect_bd_net -net xlconstant_1_dout  [get_bd_pins xlconstant_1/dout] \
  [get_bd_pins axis_nativevideo_bridge/fid] \
  [get_bd_pins v_tc_0/fsync_in]
  connect_bd_net -net xlconstant_3_dout  [get_bd_pins xlconstant_3/dout] \
  [get_bd_pins axis_nativevideo_bridge/rst] \
  [get_bd_pins axis_nativevideo_bridge/soft_reset]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins nativevideo_axis_bridge_1/vid_pixel0]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: rst_module
proc create_hier_cell_rst_module { parentCell nameHier } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
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
  create_bd_pin -dir O -from 0 -to 0 -type rst interconnect_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn1
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn2
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn3
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_reset
  create_bd_pin -dir I -type clk slowest_sync_clk
  create_bd_pin -dir I -type clk slowest_sync_clk1
  create_bd_pin -dir I -type clk slowest_sync_clk2
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir I dcm_locked1
  create_bd_pin -dir I -type clk slowest_sync_clk3

  # Create instance: rst_proc_cfg_clk, and set properties
  set rst_proc_cfg_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_proc_cfg_clk ]
  set_property CONFIG.C_NUM_PERP_ARESETN {1} $rst_proc_cfg_clk


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
  [get_bd_pins rst_proc_cfg_clk/ext_reset_in] \
  [get_bd_pins rst_proc_i2s_clk/ext_reset_in] \
  [get_bd_pins rst_proc_pl_pixel_clk/ext_reset_in] \
  [get_bd_pins rst_proc_vid_clk/ext_reset_in]
  connect_bd_net -net clk_wiz_pl_vid_1x_clk  [get_bd_pins slowest_sync_clk] \
  [get_bd_pins rst_proc_vid_clk/slowest_sync_clk]
  connect_bd_net -net dcm_locked1_1  [get_bd_pins dcm_locked1] \
  [get_bd_pins rst_proc_i2s_clk/dcm_locked]
  connect_bd_net -net dcm_locked_1  [get_bd_pins dcm_locked] \
  [get_bd_pins rst_proc_vid_clk/dcm_locked] \
  [get_bd_pins rst_proc_pl_pixel_clk/dcm_locked] \
  [get_bd_pins rst_proc_cfg_clk/dcm_locked]
  connect_bd_net -net mmi_dc_wrap_ip_0_pl_pixel_clk  [get_bd_pins slowest_sync_clk1] \
  [get_bd_pins rst_proc_pl_pixel_clk/slowest_sync_clk]
  connect_bd_net -net ps_cfg_clk_1  [get_bd_pins slowest_sync_clk3] \
  [get_bd_pins rst_proc_cfg_clk/slowest_sync_clk]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins rst_proc_i2s_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn2]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins rst_proc_i2s_clk/peripheral_reset] \
  [get_bd_pins peripheral_reset]
  connect_bd_net -net rst_proc_cfg_clk1_peripheral_aresetn  [get_bd_pins rst_proc_pl_pixel_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn1]
  connect_bd_net -net rst_proc_vid_clk_peripheral_aresetn  [get_bd_pins rst_proc_vid_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn]
  connect_bd_net -net rst_processor_150MHz_interconnect_aresetn  [get_bd_pins rst_proc_cfg_clk/interconnect_aresetn] \
  [get_bd_pins interconnect_aresetn]
  connect_bd_net -net rst_processor_150MHz_peripheral_aresetn  [get_bd_pins rst_proc_cfg_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn3]
  connect_bd_net -net slowest_sync_clk2_1  [get_bd_pins slowest_sync_clk2] \
  [get_bd_pins rst_proc_i2s_clk/slowest_sync_clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: dc_pl_out_pipeline
proc create_hier_cell_dc_pl_out_pipeline { parentCell nameHier } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_s2mm

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_CTRL1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mm_video_0


  # Create pins
  create_bd_pin -dir I -from 0 -to 0 Op2
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type rst aresetn1
  create_bd_pin -dir I -type clk aud_mclk
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir I -from 2 -to 0 bpc
  create_bd_pin -dir I -from 2 -to 0 color_format
  create_bd_pin -dir I -from 15 -to 0 dp_hres
  create_bd_pin -dir O -type intr interrupt
  create_bd_pin -dir O -type intr irq
  create_bd_pin -dir I -from 2 -to 0 pixel_mode
  create_bd_pin -dir I -type rst s_axi_ctrl_aresetn
  create_bd_pin -dir I -from 3 -to 0 sdata
  create_bd_pin -dir I vid_active_video1
  create_bd_pin -dir I vid_hsync1
  create_bd_pin -dir I -type rst vid_reset
  create_bd_pin -dir I vid_vsync1
  create_bd_pin -dir I -from 71 -to 0 Din
  create_bd_pin -dir I -type rst ap_rst_n1
  create_bd_pin -dir I -type clk ps_cfg_clk

  # Create instance: pl_audio_out
  create_hier_cell_pl_audio_out $hier_obj pl_audio_out

  # Create instance: pl_video_s0p0
  create_hier_cell_pl_video_s0p0 $hier_obj pl_video_s0p0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {4} \
  ] $xlconstant_0


  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {11} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $xlslice_0


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {23} \
    CONFIG.DIN_TO {12} \
    CONFIG.DIN_WIDTH {72} \
  ] $xlslice_1


  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_2 ]
  set_property CONFIG.NUM_PORTS {6} $xlconcat_2


  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_1 ]
  set_property CONFIG.NUM_PORTS {6} $xlconcat_1


  # Create instance: xlslice_7, and set properties
  set xlslice_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_7 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {59} \
    CONFIG.DIN_TO {48} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $xlslice_7


  # Create instance: xlslice_8, and set properties
  set xlslice_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_8 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {71} \
    CONFIG.DIN_TO {60} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $xlslice_8


  # Create instance: xlslice_5, and set properties
  set xlslice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_5 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {35} \
    CONFIG.DIN_TO {24} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $xlslice_5


  # Create instance: xlslice_6, and set properties
  set xlslice_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_6 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {47} \
    CONFIG.DIN_TO {36} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $xlslice_6


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins pl_video_s0p0/S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins m_axi_s2mm] [get_bd_intf_pins pl_audio_out/m_axi_s2mm]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins pl_video_s0p0/m_axi_mm_video_0] [get_bd_intf_pins m_axi_mm_video_0]
  connect_bd_intf_net -intf_net smartconnect_gp0_M22_AXI [get_bd_intf_pins s_axi_CTRL1] [get_bd_intf_pins pl_video_s0p0/s_axi_CTRL]
  connect_bd_intf_net -intf_net smartconnect_gp0_M23_AXI [get_bd_intf_pins s_axi_ctrl] [get_bd_intf_pins pl_audio_out/s_axi_ctrl]

  # Create port connections
  connect_bd_net -net Din_1  [get_bd_pins Din] \
  [get_bd_pins xlslice_0/Din] \
  [get_bd_pins xlslice_1/Din] \
  [get_bd_pins xlslice_5/Din] \
  [get_bd_pins xlslice_7/Din] \
  [get_bd_pins xlslice_8/Din] \
  [get_bd_pins xlslice_6/Din]
  connect_bd_net -net Op2_1  [get_bd_pins Op2] \
  [get_bd_pins pl_video_s0p0/Op2]
  connect_bd_net -net Video_out8_interrupt  [get_bd_pins pl_video_s0p0/interrupt] \
  [get_bd_pins interrupt]
  connect_bd_net -net ap_rst_n1_1  [get_bd_pins ap_rst_n1] \
  [get_bd_pins pl_video_s0p0/ap_rst_n1]
  connect_bd_net -net bufg_mux_i2sclk_O  [get_bd_pins aud_mclk] \
  [get_bd_pins pl_audio_out/aud_mclk]
  connect_bd_net -net clk_wiz_pl_vid_1x_clk  [get_bd_pins aclk] \
  [get_bd_pins pl_video_s0p0/aclk]
  connect_bd_net -net pl_audio_out_irq  [get_bd_pins pl_audio_out/irq] \
  [get_bd_pins irq]
  connect_bd_net -net ps_cfg_clk_1  [get_bd_pins ps_cfg_clk] \
  [get_bd_pins pl_audio_out/ps_cfg_clk]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins aresetn] \
  [get_bd_pins pl_audio_out/aresetn]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins aud_mrst] \
  [get_bd_pins pl_audio_out/aud_mrst]
  connect_bd_net -net rst_proc_cfg_clk1_peripheral_aresetn  [get_bd_pins aresetn1] \
  [get_bd_pins pl_video_s0p0/aresetn1]
  connect_bd_net -net rst_processor_150MHz_interconnect_aresetn  [get_bd_pins s_axi_ctrl_aresetn] \
  [get_bd_pins pl_audio_out/s_axi_ctrl_aresetn]
  connect_bd_net -net sdata_1  [get_bd_pins sdata] \
  [get_bd_pins pl_audio_out/sdata]
  connect_bd_net -net vid_active_video1_1  [get_bd_pins vid_active_video1] \
  [get_bd_pins pl_video_s0p0/vid_active_video1]
  connect_bd_net -net vid_hsync1_1  [get_bd_pins vid_hsync1] \
  [get_bd_pins pl_video_s0p0/vid_hsync1]
  connect_bd_net -net vid_reset_1  [get_bd_pins vid_reset] \
  [get_bd_pins pl_video_s0p0/vid_reset]
  connect_bd_net -net vid_vsync1_1  [get_bd_pins vid_vsync1] \
  [get_bd_pins pl_video_s0p0/vid_vsync1]
  connect_bd_net -net xlconcat_1_dout  [get_bd_pins xlconcat_1/dout] \
  [get_bd_pins pl_video_s0p0/vid_pixel0_0]
  connect_bd_net -net xlconcat_2_dout  [get_bd_pins xlconcat_2/dout] \
  [get_bd_pins pl_video_s0p0/vid_pixel1_0]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins xlconcat_2/In0] \
  [get_bd_pins xlconcat_2/In2] \
  [get_bd_pins xlconcat_2/In4] \
  [get_bd_pins xlconcat_1/In0] \
  [get_bd_pins xlconcat_1/In2] \
  [get_bd_pins xlconcat_1/In4]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins dp_hres] \
  [get_bd_pins pl_video_s0p0/dp_hres]
  connect_bd_net -net xlslice_0_Dout1  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net xlslice_1_Dout  [get_bd_pins pixel_mode] \
  [get_bd_pins pl_video_s0p0/pixel_mode]
  connect_bd_net -net xlslice_1_Dout1  [get_bd_pins xlslice_1/Dout] \
  [get_bd_pins xlconcat_1/In3]
  connect_bd_net -net xlslice_2_Dout  [get_bd_pins bpc] \
  [get_bd_pins pl_video_s0p0/bpc]
  connect_bd_net -net xlslice_3_Dout  [get_bd_pins color_format] \
  [get_bd_pins pl_video_s0p0/color_format]
  connect_bd_net -net xlslice_5_Dout  [get_bd_pins xlslice_5/Dout] \
  [get_bd_pins xlconcat_1/In5]
  connect_bd_net -net xlslice_6_Dout  [get_bd_pins xlslice_6/Dout] \
  [get_bd_pins xlconcat_2/In1]
  connect_bd_net -net xlslice_7_Dout  [get_bd_pins xlslice_7/Dout] \
  [get_bd_pins xlconcat_2/In3]
  connect_bd_net -net xlslice_8_Dout  [get_bd_pins xlslice_8/Dout] \
  [get_bd_pins xlconcat_2/In5]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: dc_input_pipeline
proc create_hier_cell_dc_input_pipeline { parentCell nameHier } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 av_axi2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 av_axi4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 av_axi

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf1


  # Create pins
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -from 2 -to 0 bpc
  create_bd_pin -dir I -from 2 -to 0 color_format
  create_bd_pin -dir I -from 15 -to 0 dp_hres
  create_bd_pin -dir I -type clk i2s_clk
  create_bd_pin -dir I -type rst peripheral_aresetn3
  create_bd_pin -dir I -from 2 -to 0 pixel_mode
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type rst s_axis_aud_aresetn
  create_bd_pin -dir I -type clk vid_clk1
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN_0
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type clk vid_clk_0
  create_bd_pin -dir O lrclk_out
  create_bd_pin -dir O -from 3 -to 0 sdata_out_0
  create_bd_pin -dir O sclk_out
  create_bd_pin -dir O -from 71 -to 0 ext_sdp00_data_o_0
  create_bd_pin -dir O ext_sdp00_req_o_0
  create_bd_pin -dir I ext_sdp00_ack_i_0
  create_bd_pin -dir I ext_sdp00_horizontal_blanking_i_0
  create_bd_pin -dir I ext_sdp00_vertical_blanking_i_0
  create_bd_pin -dir I -from 1 -to 0 ext_sdp00_line_cnt_mat_i_0

  # Create instance: avtpg_vp0
  create_hier_cell_avtpg_vp0 $hier_obj avtpg_vp0

  # Create instance: avtpg_vp1
  create_hier_cell_avtpg_vp1 $hier_obj avtpg_vp1

  # Create instance: avtpg_s0
  create_hier_cell_avtpg_s0 $hier_obj avtpg_s0

  # Create instance: axi_gpio_dual_ppc, and set properties
  set axi_gpio_dual_ppc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_dual_ppc ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00000002} \
    CONFIG.C_GPIO_WIDTH {3} \
  ] $axi_gpio_dual_ppc


  # Create instance: axi_gpio_vidformat, and set properties
  set axi_gpio_vidformat [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_vidformat ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH {3} \
    CONFIG.C_IS_DUAL {0} \
  ] $axi_gpio_vidformat


  # Create instance: xlslice_8, and set properties
  set xlslice_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_8 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {16} \
    CONFIG.DIN_TO {16} \
  ] $xlslice_8


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI6] [get_bd_intf_pins avtpg_vp0/S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins avtpg_vp0/vid_intf] [get_bd_intf_pins vid_intf]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins avtpg_vp1/vid_intf] [get_bd_intf_pins vid_intf1]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins avtpg_s0/S_AXI] [get_bd_intf_pins S_AXI]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins avtpg_s0/av_axi] [get_bd_intf_pins av_axi]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins S_AXI1] [get_bd_intf_pins axi_gpio_vidformat/S_AXI]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins avtpg_s0/ctrl] [get_bd_intf_pins ctrl]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins avtpg_s0/s_axi_ctrl] [get_bd_intf_pins s_axi_ctrl]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins S_AXI2] [get_bd_intf_pins axi_gpio_dual_ppc/S_AXI]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins S_AXI5] [get_bd_intf_pins avtpg_vp1/S_AXI]
  connect_bd_intf_net -intf_net av_axi4_1 [get_bd_intf_pins av_axi4] [get_bd_intf_pins avtpg_vp0/av_axi]
  connect_bd_intf_net -intf_net ctrl4_1 [get_bd_intf_pins ctrl4] [get_bd_intf_pins avtpg_vp0/ctrl]
  connect_bd_intf_net -intf_net smartconnect_gp0_M06_AXI [get_bd_intf_pins ctrl2] [get_bd_intf_pins avtpg_vp1/ctrl]
  connect_bd_intf_net -intf_net smartconnect_gp0_M07_AXI [get_bd_intf_pins av_axi2] [get_bd_intf_pins avtpg_vp1/av_axi]

  # Create port connections
  connect_bd_net -net TPG_GEN_EN_0_1  [get_bd_pins TPG_GEN_EN_0] \
  [get_bd_pins avtpg_s0/TPG_GEN_EN_0]
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins TPG_GEN_EN] \
  [get_bd_pins avtpg_vp0/TPG_GEN_EN] \
  [get_bd_pins avtpg_vp1/TPG_GEN_EN] \
  [get_bd_pins xlslice_8/Din]
  connect_bd_net -net aud_mrst_1  [get_bd_pins aud_mrst] \
  [get_bd_pins avtpg_s0/aud_mrst]
  connect_bd_net -net av_axi_aclk_1  [get_bd_pins s_axi_aclk] \
  [get_bd_pins avtpg_s0/av_axi_aclk]
  connect_bd_net -net avtpg_s0_ext_sdp00_data_o_0  [get_bd_pins avtpg_s0/ext_sdp00_data_o_0] \
  [get_bd_pins ext_sdp00_data_o_0]
  connect_bd_net -net avtpg_s0_ext_sdp00_req_o_0  [get_bd_pins avtpg_s0/ext_sdp00_req_o_0] \
  [get_bd_pins ext_sdp00_req_o_0]
  connect_bd_net -net avtpg_s0_lrclk_out  [get_bd_pins avtpg_s0/lrclk_out] \
  [get_bd_pins lrclk_out]
  connect_bd_net -net avtpg_s0_sclk_out  [get_bd_pins avtpg_s0/sclk_out] \
  [get_bd_pins sclk_out]
  connect_bd_net -net avtpg_s0_sdata_out  [get_bd_pins avtpg_s0/sdata_out] \
  [get_bd_pins sdata_out_0]
  connect_bd_net -net avtpg_vp0_vid_out_axi4s_tvalid  [get_bd_pins avtpg_vp0/vid_out_axi4s_tvalid] \
  [get_bd_pins avtpg_vp1/Op1]
  connect_bd_net -net avtpg_vp1_tx_vid_enable  [get_bd_pins avtpg_vp1/tx_vid_enable] \
  [get_bd_pins avtpg_vp0/tx_vid_enable1]
  connect_bd_net -net avtpg_vp1_tx_vid_pixel  [get_bd_pins avtpg_vp1/tx_vid_pixel] \
  [get_bd_pins avtpg_vp0/tx_vid_pixel1]
  connect_bd_net -net axi_gpio_vidformat_gpio_io_o  [get_bd_pins axi_gpio_vidformat/gpio_io_o] \
  [get_bd_pins avtpg_vp0/vid_format] \
  [get_bd_pins avtpg_vp1/vid_format] \
  [get_bd_pins avtpg_s0/vid_format]
  connect_bd_net -net axi_gpio_vp0_vp1_ppc_gpio_io_o  [get_bd_pins axi_gpio_dual_ppc/gpio_io_o] \
  [get_bd_pins avtpg_vp0/ppc] \
  [get_bd_pins avtpg_vp1/ppc] \
  [get_bd_pins avtpg_s0/ppc]
  connect_bd_net -net bpc_1  [get_bd_pins bpc] \
  [get_bd_pins avtpg_vp0/bpc] \
  [get_bd_pins avtpg_vp1/bpc] \
  [get_bd_pins avtpg_s0/bpc]
  connect_bd_net -net bufg_mux_0_O  [get_bd_pins vid_clk1] \
  [get_bd_pins avtpg_vp0/vid_clk] \
  [get_bd_pins avtpg_vp1/vid_clk]
  connect_bd_net -net clk_wiz_cfg_clk  [get_bd_pins av_axi_aclk] \
  [get_bd_pins avtpg_vp0/av_axi_aclk] \
  [get_bd_pins avtpg_vp1/av_axi_aclk] \
  [get_bd_pins axi_gpio_dual_ppc/s_axi_aclk] \
  [get_bd_pins axi_gpio_vidformat/s_axi_aclk]
  connect_bd_net -net clk_wiz_i2s_clk  [get_bd_pins i2s_clk] \
  [get_bd_pins avtpg_vp0/i2s_clk] \
  [get_bd_pins avtpg_vp1/i2s_clk] \
  [get_bd_pins avtpg_s0/i2s_clk]
  connect_bd_net -net color_format_1  [get_bd_pins color_format] \
  [get_bd_pins avtpg_vp0/color_format] \
  [get_bd_pins avtpg_vp1/color_format] \
  [get_bd_pins avtpg_s0/color_format]
  connect_bd_net -net dp_hres_1  [get_bd_pins dp_hres] \
  [get_bd_pins avtpg_vp0/dp_hres] \
  [get_bd_pins avtpg_vp1/dp_hres] \
  [get_bd_pins avtpg_s0/dp_hres]
  connect_bd_net -net ext_sdp00_ack_i_0_1  [get_bd_pins ext_sdp00_ack_i_0] \
  [get_bd_pins avtpg_s0/ext_sdp00_ack_i_0]
  connect_bd_net -net ext_sdp00_horizontal_blanking_i_0_1  [get_bd_pins ext_sdp00_horizontal_blanking_i_0] \
  [get_bd_pins avtpg_s0/ext_sdp00_horizontal_blanking_i_0]
  connect_bd_net -net ext_sdp00_line_cnt_mat_i_0_1  [get_bd_pins ext_sdp00_line_cnt_mat_i_0] \
  [get_bd_pins avtpg_s0/ext_sdp00_line_cnt_mat_i_0]
  connect_bd_net -net ext_sdp00_vertical_blanking_i_0_1  [get_bd_pins ext_sdp00_vertical_blanking_i_0] \
  [get_bd_pins avtpg_s0/ext_sdp00_vertical_blanking_i_0]
  connect_bd_net -net peripheral_aresetn3_1  [get_bd_pins peripheral_aresetn3] \
  [get_bd_pins avtpg_vp0/peripheral_aresetn3] \
  [get_bd_pins avtpg_vp1/peripheral_aresetn3] \
  [get_bd_pins avtpg_s0/peripheral_aresetn3]
  connect_bd_net -net pixel_mode_1  [get_bd_pins pixel_mode] \
  [get_bd_pins avtpg_vp0/pixel_mode] \
  [get_bd_pins avtpg_vp1/pixel_mode] \
  [get_bd_pins avtpg_s0/pixel_mode]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins s_axis_aud_aresetn] \
  [get_bd_pins avtpg_vp0/s_axis_aud_aresetn] \
  [get_bd_pins avtpg_vp1/s_axis_aud_aresetn] \
  [get_bd_pins avtpg_s0/peripheral_aresetn2]
  connect_bd_net -net rst_proc_vid_clk_peripheral_aresetn  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins avtpg_vp0/vid_out_axi4s_aresetn] \
  [get_bd_pins avtpg_vp1/vid_out_axi4s_aresetn] \
  [get_bd_pins avtpg_s0/vid_out_axi4s_aresetn] \
  [get_bd_pins axi_gpio_dual_ppc/s_axi_aresetn] \
  [get_bd_pins axi_gpio_vidformat/s_axi_aresetn]
  connect_bd_net -net rst_processor_150MHz_interconnect_aresetn  [get_bd_pins s_axi_aresetn] \
  [get_bd_pins avtpg_vp0/s_axi_aresetn] \
  [get_bd_pins avtpg_vp1/s_axi_aresetn] \
  [get_bd_pins avtpg_s0/s_axi_aresetn] \
  [get_bd_pins avtpg_s0/s_axis_aud_aresetn]
  connect_bd_net -net vid_clk_1  [get_bd_pins vid_clk_0] \
  [get_bd_pins avtpg_s0/vid_clk]
  connect_bd_net -net vtiming_in_active_video_1  [get_bd_pins avtpg_vp0/active_video_out] \
  [get_bd_pins avtpg_vp1/vtiming_in_active_video]
  connect_bd_net -net vtiming_in_hblank_1  [get_bd_pins avtpg_vp0/hblank_out] \
  [get_bd_pins avtpg_vp1/vtiming_in_hblank]
  connect_bd_net -net vtiming_in_hsync_1  [get_bd_pins avtpg_vp0/hsync_out] \
  [get_bd_pins avtpg_vp1/vtiming_in_hsync]
  connect_bd_net -net vtiming_in_vblank_1  [get_bd_pins avtpg_vp0/vblank_out] \
  [get_bd_pins avtpg_vp1/vtiming_in_vblank]
  connect_bd_net -net vtiming_in_vsync_1  [get_bd_pins avtpg_vp0/vsync_out] \
  [get_bd_pins avtpg_vp1/vtiming_in_vsync]
  connect_bd_net -net xlslice_8_Dout  [get_bd_pins xlslice_8/Dout] \
  [get_bd_pins avtpg_vp0/clken] \
  [get_bd_pins avtpg_vp1/clken]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: dc_in_out
proc create_hier_cell_dc_in_out { parentCell nameHier } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_s2mm

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mm_video_0


  # Create pins
  create_bd_pin -dir O -type clk aud_mclk
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir O -type intr interrupt
  create_bd_pin -dir O -type intr irq
  create_bd_pin -dir I -type clk s_axi_aclk1
  create_bd_pin -dir I -from 3 -to 0 sdata
  create_bd_pin -dir I -from 0 -to 0 Op2_0
  create_bd_pin -dir I vid_active_video1_0
  create_bd_pin -dir I vid_hsync1_0
  create_bd_pin -dir I vid_vsync1_0
  create_bd_pin -dir I -from 71 -to 0 Din
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir O -from 10 -to 0 dout6
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type clk vid_clk_0
  create_bd_pin -dir O lrclk_out
  create_bd_pin -dir O -from 3 -to 0 sdata_out_0
  create_bd_pin -dir I -from 0 -to 0 -type data i2s_lrclk
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn3
  create_bd_pin -dir O sclk_out
  create_bd_pin -dir I dcm_locked1
  create_bd_pin -dir O -from 71 -to 0 ext_sdp00_data_o_0
  create_bd_pin -dir O ext_sdp00_req_o_0
  create_bd_pin -dir I ext_sdp00_ack_i_0
  create_bd_pin -dir I ext_sdp00_horizontal_blanking_i_0
  create_bd_pin -dir I ext_sdp00_vertical_blanking_i_0
  create_bd_pin -dir I -from 1 -to 0 ext_sdp00_line_cnt_mat_i_0

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00190280} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {0} \
  ] $axi_gpio_0


  # Create instance: axi_gpio_1, and set properties
  set axi_gpio_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_1 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_DOUT_DEFAULT_2 {0x00000005} \
    CONFIG.C_GPIO2_WIDTH {3} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_1


  # Create instance: dc_input_pipeline
  create_hier_cell_dc_input_pipeline $hier_obj dc_input_pipeline

  # Create instance: dc_pl_out_pipeline
  create_hier_cell_dc_pl_out_pipeline $hier_obj dc_pl_out_pipeline

  # Create instance: rst_module
  create_hier_cell_rst_module $hier_obj rst_module

  # Create instance: smartconnect_gp0, and set properties
  set smartconnect_gp0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_gp0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {15} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_gp0


  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {15} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {16} \
  ] $xlslice_0


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {18} \
    CONFIG.DIN_TO {16} \
  ] $xlslice_1


  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {21} \
    CONFIG.DIN_TO {19} \
  ] $xlslice_2


  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_3 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {24} \
    CONFIG.DIN_TO {22} \
  ] $xlslice_3


  # Create instance: axi_gpio_alpha_bypass_en, and set properties
  set axi_gpio_alpha_bypass_en [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_alpha_bypass_en ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {6} \
    CONFIG.C_GPIO_WIDTH {2} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_alpha_bypass_en


  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {2} \
    CONFIG.IN1_WIDTH {1} \
    CONFIG.IN2_WIDTH {5} \
    CONFIG.IN3_WIDTH {3} \
    CONFIG.NUM_PORTS {4} \
  ] $xlconcat_0


  # Create instance: xlslice_7, and set properties
  set xlslice_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_7 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {5} \
    CONFIG.DIN_TO {5} \
    CONFIG.DIN_WIDTH {6} \
  ] $xlslice_7


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MI {4} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: xlslice_8, and set properties
  set xlslice_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_8 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {4} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {6} \
  ] $xlslice_8


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dc_input_pipeline/vid_intf] [get_bd_intf_pins vid_intf]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins dc_pl_out_pipeline/m_axi_mm_video_0] [get_bd_intf_pins m_axi_mm_video_0]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins smartconnect_gp0/S00_AXI] [get_bd_intf_pins S00_AXI1]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins m_axi_s2mm] [get_bd_intf_pins dc_pl_out_pipeline/m_axi_s2mm]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins dc_input_pipeline/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins dc_input_pipeline/av_axi]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins smartconnect_0/M02_AXI] [get_bd_intf_pins dc_input_pipeline/ctrl]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins smartconnect_0/M03_AXI] [get_bd_intf_pins dc_input_pipeline/s_axi_ctrl]
  connect_bd_intf_net -intf_net smartconnect_gp0_M00_AXI [get_bd_intf_pins smartconnect_gp0/M00_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M01_AXI [get_bd_intf_pins axi_gpio_alpha_bypass_en/S_AXI] [get_bd_intf_pins smartconnect_gp0/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M02_AXI1 [get_bd_intf_pins smartconnect_gp0/M02_AXI] [get_bd_intf_pins dc_input_pipeline/S_AXI1]
  connect_bd_intf_net -intf_net smartconnect_gp0_M03_AXI1 [get_bd_intf_pins smartconnect_gp0/M03_AXI] [get_bd_intf_pins dc_pl_out_pipeline/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M04_AXI1 [get_bd_intf_pins smartconnect_gp0/M04_AXI] [get_bd_intf_pins dc_input_pipeline/S_AXI2]
  connect_bd_intf_net -intf_net smartconnect_gp0_M05_AXI [get_bd_intf_pins smartconnect_gp0/M05_AXI] [get_bd_intf_pins dc_input_pipeline/S_AXI5]
  connect_bd_intf_net -intf_net smartconnect_gp0_M06_AXI [get_bd_intf_pins dc_input_pipeline/ctrl2] [get_bd_intf_pins smartconnect_gp0/M06_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M07_AXI [get_bd_intf_pins dc_input_pipeline/av_axi2] [get_bd_intf_pins smartconnect_gp0/M07_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M08_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins smartconnect_gp0/M08_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M09_AXI [get_bd_intf_pins dc_pl_out_pipeline/s_axi_CTRL1] [get_bd_intf_pins smartconnect_gp0/M09_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M10_AXI [get_bd_intf_pins dc_pl_out_pipeline/s_axi_ctrl] [get_bd_intf_pins smartconnect_gp0/M10_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M11_AXI [get_bd_intf_pins smartconnect_gp0/M11_AXI] [get_bd_intf_pins dc_input_pipeline/S_AXI6]
  connect_bd_intf_net -intf_net smartconnect_gp0_M12_AXI [get_bd_intf_pins smartconnect_gp0/M12_AXI] [get_bd_intf_pins dc_input_pipeline/av_axi4]
  connect_bd_intf_net -intf_net smartconnect_gp0_M13_AXI [get_bd_intf_pins smartconnect_gp0/M13_AXI] [get_bd_intf_pins dc_input_pipeline/ctrl4]
  connect_bd_intf_net -intf_net smartconnect_gp0_M14_AXI [get_bd_intf_pins smartconnect_gp0/M14_AXI] [get_bd_intf_pins axi_gpio_1/S_AXI]

  # Create port connections
  connect_bd_net -net Din_1  [get_bd_pins Din] \
  [get_bd_pins dc_pl_out_pipeline/Din]
  connect_bd_net -net Op2_1  [get_bd_pins Op2_0] \
  [get_bd_pins dc_pl_out_pipeline/Op2]
  connect_bd_net -net PS_0_pl0_resetn  [get_bd_pins ext_reset_in] \
  [get_bd_pins rst_module/ext_reset_in]
  connect_bd_net -net Video_out8_interrupt  [get_bd_pins dc_pl_out_pipeline/interrupt] \
  [get_bd_pins interrupt]
  connect_bd_net -net aclk_1  [get_bd_pins s_axi_aclk] \
  [get_bd_pins smartconnect_gp0/aclk] \
  [get_bd_pins dc_input_pipeline/s_axi_aclk] \
  [get_bd_pins rst_module/slowest_sync_clk3] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins dc_pl_out_pipeline/ps_cfg_clk]
  connect_bd_net -net axi_gpio_0_gpio_io_o  [get_bd_pins axi_gpio_0/gpio_io_o] \
  [get_bd_pins xlslice_0/Din] \
  [get_bd_pins xlslice_1/Din] \
  [get_bd_pins xlslice_2/Din] \
  [get_bd_pins xlslice_3/Din]
  connect_bd_net -net axi_gpio_1_gpio2_io_o  [get_bd_pins axi_gpio_1/gpio2_io_o] \
  [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net axi_gpio_1_gpio_io_o1  [get_bd_pins axi_gpio_1/gpio_io_o] \
  [get_bd_pins dc_input_pipeline/TPG_GEN_EN] \
  [get_bd_pins dc_input_pipeline/TPG_GEN_EN_0]
  connect_bd_net -net axi_gpio_2_gpio2_io_o  [get_bd_pins axi_gpio_alpha_bypass_en/gpio2_io_o] \
  [get_bd_pins xlslice_7/Din] \
  [get_bd_pins xlslice_8/Din]
  connect_bd_net -net axi_gpio_2_gpio_io_o  [get_bd_pins axi_gpio_alpha_bypass_en/gpio_io_o] \
  [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net clk_wiz_pl_vid_1x_clk  [get_bd_pins s_axi_aclk1] \
  [get_bd_pins dc_input_pipeline/vid_clk1] \
  [get_bd_pins dc_pl_out_pipeline/aclk] \
  [get_bd_pins rst_module/slowest_sync_clk] \
  [get_bd_pins rst_module/slowest_sync_clk1] \
  [get_bd_pins smartconnect_gp0/aclk1] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins axi_gpio_1/s_axi_aclk] \
  [get_bd_pins dc_input_pipeline/av_axi_aclk] \
  [get_bd_pins axi_gpio_alpha_bypass_en/s_axi_aclk]
  connect_bd_net -net dc_input_pipeline_ext_sdp00_data_o_0  [get_bd_pins dc_input_pipeline/ext_sdp00_data_o_0] \
  [get_bd_pins ext_sdp00_data_o_0]
  connect_bd_net -net dc_input_pipeline_ext_sdp00_req_o_0  [get_bd_pins dc_input_pipeline/ext_sdp00_req_o_0] \
  [get_bd_pins ext_sdp00_req_o_0]
  connect_bd_net -net dc_input_pipeline_lrclk_out  [get_bd_pins dc_input_pipeline/lrclk_out] \
  [get_bd_pins lrclk_out]
  connect_bd_net -net dc_input_pipeline_sclk_out  [get_bd_pins dc_input_pipeline/sclk_out] \
  [get_bd_pins sclk_out]
  connect_bd_net -net dc_input_pipeline_sdata_out_0  [get_bd_pins dc_input_pipeline/sdata_out_0] \
  [get_bd_pins sdata_out_0]
  connect_bd_net -net dc_pl_out_pipeline_irq  [get_bd_pins dc_pl_out_pipeline/irq] \
  [get_bd_pins irq]
  connect_bd_net -net dcm_locked1_1  [get_bd_pins dcm_locked1] \
  [get_bd_pins rst_module/dcm_locked1]
  connect_bd_net -net dcm_locked_1  [get_bd_pins dcm_locked] \
  [get_bd_pins rst_module/dcm_locked]
  connect_bd_net -net ext_sdp00_ack_i_0_1  [get_bd_pins ext_sdp00_ack_i_0] \
  [get_bd_pins dc_input_pipeline/ext_sdp00_ack_i_0]
  connect_bd_net -net ext_sdp00_horizontal_blanking_i_0_1  [get_bd_pins ext_sdp00_horizontal_blanking_i_0] \
  [get_bd_pins dc_input_pipeline/ext_sdp00_horizontal_blanking_i_0]
  connect_bd_net -net ext_sdp00_line_cnt_mat_i_0_1  [get_bd_pins ext_sdp00_line_cnt_mat_i_0] \
  [get_bd_pins dc_input_pipeline/ext_sdp00_line_cnt_mat_i_0]
  connect_bd_net -net ext_sdp00_vertical_blanking_i_0_1  [get_bd_pins ext_sdp00_vertical_blanking_i_0] \
  [get_bd_pins dc_input_pipeline/ext_sdp00_vertical_blanking_i_0]
  connect_bd_net -net mmi_dpdc_core_0_if_mmi_pl_i2s0_i2slrclk_i  [get_bd_pins i2s_lrclk] \
  [get_bd_pins dc_pl_out_pipeline/aud_mclk] \
  [get_bd_pins rst_module/slowest_sync_clk2] \
  [get_bd_pins dc_input_pipeline/i2s_clk] \
  [get_bd_pins aud_mclk]
  connect_bd_net -net rst_module_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn] \
  [get_bd_pins dc_input_pipeline/vid_out_axi4s_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins axi_gpio_1/s_axi_aresetn] \
  [get_bd_pins axi_gpio_alpha_bypass_en/s_axi_aresetn] \
  [get_bd_pins dc_pl_out_pipeline/ap_rst_n1]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn2] \
  [get_bd_pins dc_input_pipeline/s_axis_aud_aresetn] \
  [get_bd_pins dc_pl_out_pipeline/aresetn]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins rst_module/peripheral_reset] \
  [get_bd_pins dc_pl_out_pipeline/aud_mrst] \
  [get_bd_pins dc_pl_out_pipeline/vid_reset] \
  [get_bd_pins dc_input_pipeline/aud_mrst]
  connect_bd_net -net rst_proc_cfg_clk1_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn1] \
  [get_bd_pins dc_pl_out_pipeline/aresetn1]
  connect_bd_net -net rst_processor_150MHz_interconnect_aresetn  [get_bd_pins rst_module/interconnect_aresetn] \
  [get_bd_pins dc_input_pipeline/s_axi_aresetn] \
  [get_bd_pins dc_pl_out_pipeline/s_axi_ctrl_aresetn] \
  [get_bd_pins smartconnect_gp0/aresetn] \
  [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net rst_processor_150MHz_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn3] \
  [get_bd_pins dc_input_pipeline/peripheral_aresetn3] \
  [get_bd_pins peripheral_aresetn3]
  connect_bd_net -net sdata_1  [get_bd_pins sdata] \
  [get_bd_pins dc_pl_out_pipeline/sdata]
  connect_bd_net -net vid_active_video1_1  [get_bd_pins vid_active_video1_0] \
  [get_bd_pins dc_pl_out_pipeline/vid_active_video1]
  connect_bd_net -net vid_clk_0_1  [get_bd_pins vid_clk_0] \
  [get_bd_pins dc_input_pipeline/vid_clk_0]
  connect_bd_net -net vid_hsync1_1  [get_bd_pins vid_hsync1_0] \
  [get_bd_pins dc_pl_out_pipeline/vid_hsync1]
  connect_bd_net -net vid_vsync1_1  [get_bd_pins vid_vsync1_0] \
  [get_bd_pins dc_pl_out_pipeline/vid_vsync1]
  connect_bd_net -net xlconcat_0_dout1  [get_bd_pins xlconcat_0/dout] \
  [get_bd_pins dout6]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins dc_input_pipeline/dp_hres] \
  [get_bd_pins dc_pl_out_pipeline/dp_hres]
  connect_bd_net -net xlslice_1_Dout  [get_bd_pins xlslice_1/Dout] \
  [get_bd_pins dc_input_pipeline/pixel_mode] \
  [get_bd_pins dc_pl_out_pipeline/pixel_mode]
  connect_bd_net -net xlslice_2_Dout  [get_bd_pins xlslice_2/Dout] \
  [get_bd_pins dc_input_pipeline/bpc] \
  [get_bd_pins dc_pl_out_pipeline/bpc]
  connect_bd_net -net xlslice_3_Dout  [get_bd_pins xlslice_3/Dout] \
  [get_bd_pins dc_input_pipeline/color_format] \
  [get_bd_pins dc_pl_out_pipeline/color_format]
  connect_bd_net -net xlslice_7_Dout  [get_bd_pins xlslice_7/Dout] \
  [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net xlslice_8_Dout  [get_bd_pins xlslice_8/Dout] \
  [get_bd_pins xlconcat_0/In2]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell design_name } {

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set sys_clk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $sys_clk0_0

  set C0_CH0_LPDDR5_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C0_CH0_LPDDR5_0 ]

  set C0_CH1_LPDDR5_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C0_CH1_LPDDR5_0 ]


  # Create ports

  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.MMI_CONFIG(DC_FEEDBACK_EN) {1} \
    CONFIG.MMI_CONFIG(DC_FEEDBACK_SDP_EN) {0} \
    CONFIG.MMI_CONFIG(DC_FEEDBACK_STREAM) {Audio_&_Video} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO01) {Audio_&_Video} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO01_ALPHA_EN) {1} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO01_SDP_EN) {1} \
    CONFIG.MMI_CONFIG(DPDC_PRESENTATION_MODE) {Mixed} \
    CONFIG.MMI_CONFIG(MDB5_GT) {None} \
    CONFIG.MMI_CONFIG(MMI_DP_HPD) {PS_MIO_12} \
    CONFIG.MMI_CONFIG(MMI_GPU_ENABLE) {1} \
    CONFIG.MMI_CONFIG(PL_MMI_INTERRUPTS_EN) {1} \
    CONFIG.MMI_CONFIG(RTL_DEBUG) {1} \
    CONFIG.MMI_CONFIG(UDH_GT) {DP_X2} \
    CONFIG.PS11_CONFIG(MDB5_GT) {None} \
    CONFIG.PS11_CONFIG(MMI_DP_HPD) {PS_MIO_12} \
    CONFIG.PS11_CONFIG(MMI_GPU_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {100} \
    CONFIG.PS11_CONFIG(PMC_EMMC) {CD_ENABLE 0 POW_ENABLE 0 WP_ENABLE 0 RESET_ENABLE 1 CD_IO PMC_MIO_2 POW_IO PMC_MIO_12 WP_IO PMC_MIO_1 RESET_IO PMC_MIO_51 CLK_50_SDR_ITAP_DLY 0x00 CLK_50_SDR_OTAP_DLY\
0x5 CLK_50_DDR_ITAP_DLY 0x3 CLK_50_DDR_OTAP_DLY 0x5 CLK_100_SDR_OTAP_DLY 0x00 CLK_200_SDR_OTAP_DLY 0x7 CLK_200_DDR_OTAP_DLY 0x4} \
    CONFIG.PS11_CONFIG(PMC_EMMC_DATA_TRANSFER_MODE) {8Bit} \
    CONFIG.PS11_CONFIG(PMC_EMMC_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 IO PMC_MIO_40:51 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PMC_MIO13) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PS11_CONFIG(PMC_QSPI_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 MODE Dual_Parallel} \
    CONFIG.PS11_CONFIG(PMC_SDIO_30) {CD_ENABLE 1 POW_ENABLE 1 WP_ENABLE 1 RESET_ENABLE 0 CD_IO PMC_MIO_37 POW_IO PMC_MIO_26 WP_IO PMC_MIO_38 RESET_IO PMC_MIO_17 CLK_50_SDR_ITAP_DLY 0x2C CLK_50_SDR_OTAP_DLY\
0x4 CLK_50_DDR_ITAP_DLY 0x36 CLK_50_DDR_OTAP_DLY 0x3 CLK_100_SDR_OTAP_DLY 0x3 CLK_200_SDR_OTAP_DLY 0x2} \
    CONFIG.PS11_CONFIG(PMC_SDIO_30AD) {CD_ENABLE 0 POW_ENABLE 0 WP_ENABLE 0 RESET_ENABLE 0 CD_IO PMC_MIO_24 POW_IO PMC_MIO_17 WP_IO PMC_MIO_25 RESET_IO PMC_MIO_17 CLK_50_SDR_ITAP_DLY 0x25 CLK_50_SDR_OTAP_DLY\
0x4 CLK_50_DDR_ITAP_DLY 0x2A CLK_50_DDR_OTAP_DLY 0x3 CLK_100_SDR_OTAP_DLY 0x3 CLK_200_SDR_OTAP_DLY 0x2} \
    CONFIG.PS11_CONFIG(PMC_SDIO_30AD_PERIPHERAL) {PRIMARY_ENABLE 0 SECONDARY_ENABLE 0 IO PMC_MIO_13:25 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PMC_SDIO_30_PERIPHERAL) {PRIMARY_ENABLE 0 SECONDARY_ENABLE 1 IO PMC_MIO_26:38 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
    CONFIG.PS11_CONFIG(PS_CAN0_PERIPHERAL) {ENABLE 1 IO PMC_MIO_16:17 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_CAN1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_18:19 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_CAN2_PERIPHERAL) {ENABLE 1 IO PMC_MIO_20:21 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_CAN3_PERIPHERAL) {ENABLE 1 IO PMC_MIO_14:15 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_ENET0_MDIO) {ENABLE 1 IO PS_MIO_24:25 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_ENET0_PERIPHERAL) {ENABLE 1 IO PS_MIO_0:11 IO_TYPE MIO MODE RGMII} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI1_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI2_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI3_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI4_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI5_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI6_NOBUF_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_I3C_I2C0_PERIPHERAL) {ENABLE 1 IO PS_MIO_18:19 IO_TYPE MIO TYPE I3C} \
    CONFIG.PS11_CONFIG(PS_MIO22) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PS11_CONFIG(PS_MIO23) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
    CONFIG.PS11_CONFIG(PS_TTC0_CLK) {ENABLE 0 IO PS_MIO_6 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_TTC0_WAVEOUT) {ENABLE 0 IO PS_MIO_7 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_TTC1_CLK) {ENABLE 1 IO PMC_MIO_22 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_TTC1_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC1_WAVEOUT) {ENABLE 1 IO PMC_MIO_23 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PS_MIO_16:17 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 1 IO PS_MIO_20:21 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_NOC) {1} \
    CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_PL) {1} \
    CONFIG.PS11_CONFIG(PS_USE_LPD_AXI_NOC) {1} \
    CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} \
    CONFIG.PS11_CONFIG(UDH_GT) {DP_X2} \
    CONFIG.PS11_CONFIG_APPLIED {1} \
    CONFIG.PS_PMC_CONFIG_APPLIED {1} \
  ] $ps_wizard_0


  # Create instance: axi_noc2_0, and set properties
  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_0 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG {DDRMC5_CONTROLLERTYPE LPDDR5_SDRAM DDRMC5_SPEED_GRADE LPDDR5-6400 DDRMC5_DEVICE_TYPE Components DDRMC5_F0_LP5_BANK_ARCH 16B DDRMC5_F1_LP5_BANK_ARCH 16B DDRMC5_DRAM_WIDTH x16 DDRMC5_DATA_WIDTH\
16 DDRMC5_ROW_ADDR_WIDTH 16 DDRMC5_COL_ADDR_WIDTH 6 DDRMC5_BA_ADDR_WIDTH 4 DDRMC5_BG_WIDTH 0 DDRMC5_BURST_ADDR_WIDTH 4 DDRMC5_NUM_RANKS 1 DDRMC5_LATENCY_MODE x16 DDRMC5_NUM_SLOTS 1 DDRMC5_NUM_CK 1 DDRMC5_NUM_CH\
2 DDRMC5_STACK_HEIGHT 1 DDRMC5_DRAM_SIZE 16Gb DDRMC5_MEMORY_DENSITY 2GB DDRMC5_DM_EN true DDRMC5_DQS_OSCI_EN DISABLE DDRMC5_SIDE_BAND_ECC false DDRMC5_INLINE_ECC false DDRMC5_DDR5_2T DISABLE DDRMC5_DDR5_RDIMM_ADDR_MODE\
DDR DDRMC5_REFRESH_MODE NORMAL DDRMC5_REFRESH_TYPE ALL_BANK DDRMC5_FREQ_SWITCHING false DDRMC5_BACKGROUND_SCRUB false DDRMC5_OTF_SCRUB false DDRMC5_SCRUB_SIZE 1 DDRMC5_MEM_FILL false DDRMC5_PERIODIC_READ\
ENABLE DDRMC5_USER_REFRESH false DDRMC5_WL_SET A DDRMC5_WR_DBI true DDRMC5_RD_DBI true DDRMC5_AUTO_PRECHARGE true DDRMC5_CRYPTO false DDRMC5_ON_DIE_ECC false DDRMC5_DDR5_PAR_RCD_EN false DDRMC5_OP_TEMPERATURE\
LOW DDRMC5_F0_TCK 2500 DDRMC5_INPUTCLK0_PERIOD 3125 DDRMC5_F0_TFAW 20000 DDRMC5_F0_DDR5_TRP 18000 DDRMC5_F0_TRTP 7500 DDRMC5_F0_TRTP_RU 24 DDRMC5_F1_TRTP_RU 24 DDRMC5_F0_TRCD 18000 DDRMC5_TREFI 3906000\
DDRMC5_DDR5_TRFC1 0 DDRMC5_DDR5_TRFC2 0 DDRMC5_DDR5_TRFCSB 0 DDRMC5_F0_TRAS 42000 DDRMC5_F0_TZQLAT 30000 DDRMC5_F0_DDR5_TCCD_L_WR 0 DDRMC5_F0_DDR5_TCCD_L_WR_RU 32 DDRMC5_F0_TXP 7500 DDRMC5_F0_DDR5_TPD\
0 DDRMC5_DDR5_TREFSBRD 0 DDRMC5_DDR5_TRFC1_DLR 0 DDRMC5_DDR5_TRFC1_DPR 0 DDRMC5_DDR5_TRFC2_DLR 0 DDRMC5_DDR5_TRFC2_DPR 0 DDRMC5_DDR5_TRFCSB_DLR 0 DDRMC5_DDR5_TREFSBRD_SLR 0 DDRMC5_DDR5_TREFSBRD_DLR 0 DDRMC5_F0_CL\
46 DDRMC5_F0_CWL 0 DDRMC5_F0_DDR5_TRRD_L 0 DDRMC5_F0_TCCD_L 0 DDRMC5_F0_DDR5_TCCD_L_WR2 0 DDRMC5_F0_DDR5_TCCD_L_WR2_RU 16 DDRMC5_DDR5_TFAW_DLR 0 DDRMC5_F1_TCK 2500 DDRMC5_F1_TFAW 20000 DDRMC5_F1_DDR5_TRP\
18000 DDRMC5_F1_TRTP 7500 DDRMC5_F1_TRCD 18000 DDRMC5_F1_TRAS 42000 DDRMC5_F1_TZQLAT 30000 DDRMC5_F1_DDR5_TCCD_L_WR 0 DDRMC5_F1_DDR5_TCCD_L_WR_RU 32 DDRMC5_F1_TXP 7500 DDRMC5_F1_DDR5_TPD 0 DDRMC5_F1_CL\
46 DDRMC5_F1_CWL 0 DDRMC5_F1_DDR5_TRRD_L 0 DDRMC5_F1_TCCD_L 0 DDRMC5_F1_DDR5_TCCD_L_WR2 0 DDRMC5_F1_DDR5_TCCD_L_WR2_RU 16 DDRMC5_LP5_TRFCAB 280000 DDRMC5_LP5_TRFCPB 140000 DDRMC5_LP5_TPBR2PBR 90000 DDRMC5_F0_LP5_TRPAB\
21000 DDRMC5_F0_LP5_TRPPB 18000 DDRMC5_F0_LP5_TRRD 5000 DDRMC5_LP5_TPBR2ACT 7500 DDRMC5_F0_LP5_TCSPD 12500 DDRMC5_F0_RL 10 DDRMC5_F0_WL 5 DDRMC5_F1_LP5_TRPAB 21000 DDRMC5_F1_LP5_TRPPB 18000 DDRMC5_F1_LP5_TRRD\
5000 DDRMC5_F1_LP5_TCSPD 12500 DDRMC5_F1_RL 10 DDRMC5_F1_WL 5 DDRMC5_LP5_TRFMAB 280000 DDRMC5_LP5_TRFMPB 190000 DDRMC5_SYSTEM_CLOCK Differential DDRMC5_UBLAZE_BLI_INTF false DDRMC5_REF_AND_PER_CAL_INTF\
false DDRMC5_PRE_DEF_ADDR_MAP_SEL ROW_BANK_COLUMN DDRMC5_USER_DEFINED_ADDRESS_MAP None DDRMC5_ADDRESS_MAP NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA3,BA2,BA1,BA0,CA5,CA4,CA3,CA2,NC,CA1,CA0,NC,NC,NC,NC,NA\
DDRMC5_MC0_CONFIG_SEL config9 DDRMC5_LOW_TRFC_DPR false DDRMC5_NUM_MC 1 DDRMC5_NUM_MCP 1 DDRMC5_MAIN_DEVICE_TYPE Components DDRMC5_INTERLEAVE_SIZE 128 DDRMC5_SILICON_REVISION NA DDRMC5_FPGA_DEVICE_TYPE\
NON_KSB DDRMC5_SELF_REFRESH DISABLE DDRMC5_LBDQ_SWAP false DDRMC5_CAL_MASK_POLL ENABLE DDRMC5_BOARD_INTRF_EN false} \
    CONFIG.MC_CHAN_REGION1 {DDR_CH0_MED} \
    CONFIG.NUM_CLKS {14} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_SI {13} \
  ] $axi_noc2_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc2_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc2_0/S09_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_0/S10_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_0/S11_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_mmi} \
 ] [get_bd_intf_pins /axi_noc2_0/S12_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S08_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S09_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk9]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {} \
 ] [get_bd_pins /axi_noc2_0/aclk10]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S11_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk11]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S10_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk12]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S12_AXI} \
 ] [get_bd_pins /axi_noc2_0/aclk13]

  # Create instance: dc_in_out
  create_hier_cell_dc_in_out [current_bd_instance .] dc_in_out

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {1} \
    CONFIG.IN1_WIDTH {1} \
    CONFIG.IN2_WIDTH {1} \
    CONFIG.IN3_WIDTH {16} \
    CONFIG.NUM_PORTS {4} \
  ] $xlconcat_0


  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {3} \
    CONFIG.C_GPIO_WIDTH {19} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: clkx5_wiz_1, and set properties
  set clkx5_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clkx5_wiz_1 ]
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {pl_vid_1x_clk,pl_vid_2x_clk,ps_cfg_clk,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {300.000,600.000,230.000,100.000,100.100,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,true,true,false,false,false,false} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
  ] $clkx5_wiz_1


  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {0} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {3} \
  ] $xlslice_2


  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_3 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {3} \
    CONFIG.DOUT_WIDTH {1} \
  ] $xlslice_3


  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_4 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {2} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {3} \
    CONFIG.DOUT_WIDTH {1} \
  ] $xlslice_4


  # Create instance: clkx5_wiz_0, and set properties
  set clkx5_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clkx5_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {i2s_clk,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {196.608,100.000,100.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
  ] $clkx5_wiz_0


  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins dc_in_out/S00_AXI1] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_noc2_0_C0_CH0_LPDDR5 [get_bd_intf_ports C0_CH0_LPDDR5_0] [get_bd_intf_pins axi_noc2_0/C0_CH0_LPDDR5]
  connect_bd_intf_net -intf_net axi_noc2_0_C0_CH1_LPDDR5 [get_bd_intf_ports C0_CH1_LPDDR5_0] [get_bd_intf_pins axi_noc2_0/C0_CH1_LPDDR5]
  connect_bd_intf_net -intf_net dc_in_out_m_axi_mm_video_0 [get_bd_intf_pins axi_noc2_0/S10_AXI] [get_bd_intf_pins dc_in_out/m_axi_mm_video_0]
  connect_bd_intf_net -intf_net dc_in_out_m_axi_s2mm [get_bd_intf_pins dc_in_out/m_axi_s2mm] [get_bd_intf_pins axi_noc2_0/S11_AXI]
  connect_bd_intf_net -intf_net dc_in_out_vid_intf [get_bd_intf_pins dc_in_out/vid_intf] [get_bd_intf_pins ps_wizard_0/live_video0]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S00_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins axi_noc2_0/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC2 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC2] [get_bd_intf_pins axi_noc2_0/S02_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC3 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC3] [get_bd_intf_pins axi_noc2_0/S03_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC4 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC4] [get_bd_intf_pins axi_noc2_0/S04_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC5 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC5] [get_bd_intf_pins axi_noc2_0/S05_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC6 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC6] [get_bd_intf_pins axi_noc2_0/S06_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC7 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC7] [get_bd_intf_pins axi_noc2_0/S07_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_PL [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_LPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S08_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_MMI_DC_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/MMI_DC_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S12_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_PMCX_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S09_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net sys_clk0_0_1 [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins axi_noc2_0/sys_clk0]

  # Create port connections
  connect_bd_net -net Op2_0_1  [get_bd_pins ps_wizard_0/strt_capture] \
  [get_bd_pins dc_in_out/Op2_0]
  connect_bd_net -net axi_gpio_0_gpio2_io_o  [get_bd_pins axi_gpio_0/gpio2_io_o] \
  [get_bd_pins xlslice_2/Din] \
  [get_bd_pins xlslice_3/Din] \
  [get_bd_pins xlslice_4/Din]
  connect_bd_net -net clkx5_wiz_0_i2s_clk  [get_bd_pins clkx5_wiz_0/i2s_clk] \
  [get_bd_pins dc_in_out/i2s_lrclk]
  connect_bd_net -net clkx5_wiz_0_locked  [get_bd_pins clkx5_wiz_0/locked] \
  [get_bd_pins dc_in_out/dcm_locked1]
  connect_bd_net -net clkx5_wiz_1_locked  [get_bd_pins clkx5_wiz_1/locked] \
  [get_bd_pins dc_in_out/dcm_locked]
  connect_bd_net -net clkx5_wiz_1_pl_vid_1x_clk  [get_bd_pins clkx5_wiz_1/pl_vid_1x_clk] \
  [get_bd_pins dc_in_out/s_axi_aclk1] \
  [get_bd_pins axi_noc2_0/aclk12] \
  [get_bd_pins dc_in_out/vid_clk_0] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk]
  connect_bd_net -net clkx5_wiz_1_pl_vid_2x_clk  [get_bd_pins clkx5_wiz_1/pl_vid_2x_clk] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk]
  connect_bd_net -net clkx5_wiz_1_ps_cfg_clk  [get_bd_pins clkx5_wiz_1/ps_cfg_clk] \
  [get_bd_pins dc_in_out/s_axi_aclk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk]
  connect_bd_net -net dc_in_out_aud_mclk  [get_bd_pins dc_in_out/aud_mclk] \
  [get_bd_pins axi_noc2_0/aclk11]
  connect_bd_net -net dc_in_out_dout6  [get_bd_pins dc_in_out/dout6] \
  [get_bd_pins ps_wizard_0/video_ctrl]
  connect_bd_net -net dc_in_out_ext_sdp00_data_o_0  [get_bd_pins dc_in_out/ext_sdp00_data_o_0] \
  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_data]
  connect_bd_net -net dc_in_out_ext_sdp00_req_o_0  [get_bd_pins dc_in_out/ext_sdp00_req_o_0] \
  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_req]
  connect_bd_net -net dc_in_out_interrupt  [get_bd_pins dc_in_out/interrupt] \
  [get_bd_pins ps_wizard_0/pl_mmi_irq0]
  connect_bd_net -net dc_in_out_irq  [get_bd_pins dc_in_out/irq] \
  [get_bd_pins ps_wizard_0/pl_mmi_irq1]
  connect_bd_net -net dc_in_out_lrclk_out  [get_bd_pins dc_in_out/lrclk_out] \
  [get_bd_pins ps_wizard_0/i2s_i2s0_lrclk_tx]
  connect_bd_net -net dc_in_out_peripheral_aresetn3  [get_bd_pins dc_in_out/peripheral_aresetn3] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn]
  connect_bd_net -net dc_in_out_sclk_out  [get_bd_pins dc_in_out/sclk_out] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_i2s_s0_clk]
  connect_bd_net -net dc_in_out_sdata_out_0  [get_bd_pins dc_in_out/sdata_out_0] \
  [get_bd_pins ps_wizard_0/i2s_i2s0_sdata_0]
  connect_bd_net -net ps_wizard_0_dataen_err  [get_bd_pins ps_wizard_0/dataen_err] \
  [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk0]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc1_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] \
  [get_bd_pins axi_noc2_0/aclk1]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc2_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc2_clk] \
  [get_bd_pins axi_noc2_0/aclk2]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc3_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc3_clk] \
  [get_bd_pins axi_noc2_0/aclk3]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc4_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc4_clk] \
  [get_bd_pins axi_noc2_0/aclk4]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc5_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc5_clk] \
  [get_bd_pins axi_noc2_0/aclk5]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc6_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc6_clk] \
  [get_bd_pins axi_noc2_0/aclk6]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc7_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc7_clk] \
  [get_bd_pins axi_noc2_0/aclk7]
  connect_bd_net -net ps_wizard_0_hsync_err  [get_bd_pins ps_wizard_0/hsync_err] \
  [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net ps_wizard_0_lpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk8]
  connect_bd_net -net ps_wizard_0_mmi_dc_axi_noc0_clk  [get_bd_pins ps_wizard_0/mmi_dc_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk13]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins axi_noc2_0/aclk10] \
  [get_bd_pins clkx5_wiz_1/clk_in1] \
  [get_bd_pins clkx5_wiz_0/clk_in1]
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins dc_in_out/ext_reset_in]
  connect_bd_net -net ps_wizard_0_pmcx_axi_noc0_clk  [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk9]
  connect_bd_net -net ps_wizard_0_sdp_sdp00_ext_sdp_ack  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_ack] \
  [get_bd_pins dc_in_out/ext_sdp00_ack_i_0]
  connect_bd_net -net ps_wizard_0_sdp_sdp00_ext_sdp_horizontal_blanking  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_horizontal_blanking] \
  [get_bd_pins dc_in_out/ext_sdp00_horizontal_blanking_i_0]
  connect_bd_net -net ps_wizard_0_sdp_sdp00_ext_sdp_line_cnt_mat  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_line_cnt_mat] \
  [get_bd_pins dc_in_out/ext_sdp00_line_cnt_mat_i_0]
  connect_bd_net -net ps_wizard_0_sdp_sdp00_ext_sdp_vertical_blanking  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_vertical_blanking] \
  [get_bd_pins dc_in_out/ext_sdp00_vertical_blanking_i_0]
  connect_bd_net -net ps_wizard_0_videofb_s0_data  [get_bd_pins ps_wizard_0/videofb_s0_data] \
  [get_bd_pins dc_in_out/Din]
  connect_bd_net -net ps_wizard_0_vsync0_cnt  [get_bd_pins ps_wizard_0/vsync0_cnt] \
  [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net ps_wizard_0_vsync_err  [get_bd_pins ps_wizard_0/vsync_err] \
  [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net sdata_1  [get_bd_pins ps_wizard_0/i2sfb_i2s0_sdata_0] \
  [get_bd_pins dc_in_out/sdata]
  connect_bd_net -net vid_active_video1_0_1  [get_bd_pins ps_wizard_0/videofb_s0_active_video] \
  [get_bd_pins dc_in_out/vid_active_video1_0]
  connect_bd_net -net vid_hsync1_0_1  [get_bd_pins ps_wizard_0/videofb_s0_hsync] \
  [get_bd_pins dc_in_out/vid_hsync1_0]
  connect_bd_net -net vid_vsync1_0_1  [get_bd_pins ps_wizard_0/videofb_s0_vsync] \
  [get_bd_pins dc_in_out/vid_vsync1_0]
  connect_bd_net -net xlconcat_0_dout  [get_bd_pins xlconcat_0/dout] \
  [get_bd_pins axi_gpio_0/gpio_io_i]
  connect_bd_net -net xlslice_2_Dout  [get_bd_pins xlslice_2/Dout] \
  [get_bd_pins ps_wizard_0/dp_external_vsync_event]
  connect_bd_net -net xlslice_3_Dout  [get_bd_pins xlslice_3/Dout] \
  [get_bd_pins ps_wizard_0/dp_external_custom_event1]
  connect_bd_net -net xlslice_4_Dout  [get_bd_pins xlslice_4/Dout] \
  [get_bd_pins ps_wizard_0/dp_external_custom_event2]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_dc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_dc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0430000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0520000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB04F0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0530000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB0510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dc_in_out/dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/m_axi_s2mm] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dc_in_out/dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/m_axi_s2mm] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/Data_m_axi_mm_video] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/Data_m_axi_mm_video] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/av_pat_gen_0/av_axi/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_dual_ppc/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/axi_gpio_vidformat/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_s0/v_tc_0/ctrl/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_input_pipeline/avtpg_vp1/v_tc_0/ctrl/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()
