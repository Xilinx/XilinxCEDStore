################################################################
# START
################################################################
##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: pl_video_s0p0
proc create_hier_cell_pl_video_s0p0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_pl_video_s0p0() - Empty argument(s)!"}
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

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_CTRL

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mm_video_0


  # Create pins
  create_bd_pin -dir I -from 0 -to 0 Op2
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst ap_rst_n
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
  create_bd_pin -dir I -type rst s_axi_aresetn

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
    CONFIG.MAX_NR_PLANES {2} \
    CONFIG.MAX_ROWS {4096} \
    CONFIG.SAMPLES_PER_CLOCK {2} \
  ] $v_frmbuf_wr_0


  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {16} \
    CONFIG.IN1_WIDTH {1} \
  ] $xlconcat_2


  # Create instance: xlconcat_3, and set properties
  set xlconcat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {16} \
    CONFIG.IN1_WIDTH {1} \
  ] $xlconcat_3


  # Create interface connections
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_gpio_1/S_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins v_frmbuf_wr_0/m_axi_mm_video] [get_bd_intf_pins m_axi_mm_video_0]
  connect_bd_intf_net -intf_net nativevideo_axis_bridge_m_axis_video [get_bd_intf_pins nativevideo_axis_bridge/m_axis_video] [get_bd_intf_pins v_frmbuf_wr_0/s_axis_video]
  connect_bd_intf_net -intf_net smartconnect_gp0_M22_AXI [get_bd_intf_pins s_axi_CTRL] [get_bd_intf_pins v_frmbuf_wr_0/s_axi_CTRL]

  # Create port connections
  connect_bd_net -net Net1  [get_bd_pins aclk] \
  [get_bd_pins axi_gpio_1/s_axi_aclk] \
  [get_bd_pins nativevideo_axis_bridge/vid_pixel_clk] \
  [get_bd_pins nativevideo_axis_bridge/m_axis_aclk] \
  [get_bd_pins v_frmbuf_wr_0/ap_clk]
  connect_bd_net -net Op2_1  [get_bd_pins Op2] \
  [get_bd_pins util_vector_logic_3/Op2]
  connect_bd_net -net Video_out8_interrupt  [get_bd_pins v_frmbuf_wr_0/interrupt] \
  [get_bd_pins interrupt]
  connect_bd_net -net ap_rst_n_1  [get_bd_pins ap_rst_n] \
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
  connect_bd_net -net s_axi_aresetn_1  [get_bd_pins s_axi_aresetn] \
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

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_pl_audio_out() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_s2mm

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl


  # Create pins
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk aud_mclk
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir O -type intr irq
  create_bd_pin -dir I -from 3 -to 0 sdata
  create_bd_pin -dir I -type clk ps_cfg_clk
  create_bd_pin -dir I -type rst peripheral_aresetn3

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
  connect_bd_net -net peripheral_aresetn3_1  [get_bd_pins peripheral_aresetn3] \
  [get_bd_pins i2s_receiver_0/s_axi_ctrl_aresetn]
  connect_bd_net -net ps_cfg_clk_1  [get_bd_pins ps_cfg_clk] \
  [get_bd_pins i2s_receiver_0/s_axi_ctrl_aclk]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins aresetn] \
  [get_bd_pins audio_formatter_0/s_axi_lite_aresetn] \
  [get_bd_pins audio_formatter_0/s_axis_s2mm_aresetn] \
  [get_bd_pins i2s_receiver_0/m_axis_aud_aresetn]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins aud_mrst] \
  [get_bd_pins i2s_receiver_0/aud_mrst]
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
  create_bd_pin -dir O -from 0 -to 0 -type rst interconnect_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn1
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn2
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn3
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_reset
  create_bd_pin -dir I -type clk slowest_sync_clk
  create_bd_pin -dir I -type clk slowest_sync_clk1
  create_bd_pin -dir I -type clk slowest_sync_clk2
  create_bd_pin -dir I -type clk slowest_sync_clk3
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir I dcm_locked1

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
  connect_bd_net -net clk_wiz_i2s_clk  [get_bd_pins slowest_sync_clk2] \
  [get_bd_pins rst_proc_i2s_clk/slowest_sync_clk]
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
  connect_bd_net -net slowest_sync_clk3_1  [get_bd_pins slowest_sync_clk3] \
  [get_bd_pins rst_proc_cfg_clk/slowest_sync_clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: dc_pl_out_pipeline
proc create_hier_cell_dc_pl_out_pipeline { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_dc_pl_out_pipeline() - Empty argument(s)!"}
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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_s2mm

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_CTRL1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mm_video_0


  # Create pins
  create_bd_pin -dir I -from 0 -to 0 Op2
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst ap_rst_n
  create_bd_pin -dir I -type rst aresetn
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
  create_bd_pin -dir I -type clk ps_cfg_clk
  create_bd_pin -dir I -type rst peripheral_aresetn3
  create_bd_pin -dir I -type rst s_axi_aresetn

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
  connect_bd_net -net ap_rst_n_1  [get_bd_pins ap_rst_n] \
  [get_bd_pins pl_video_s0p0/ap_rst_n]
  connect_bd_net -net bufg_mux_i2sclk_O  [get_bd_pins aud_mclk] \
  [get_bd_pins pl_audio_out/aud_mclk]
  connect_bd_net -net clk_wiz_pl_vid_1x_clk  [get_bd_pins aclk] \
  [get_bd_pins pl_video_s0p0/aclk]
  connect_bd_net -net peripheral_aresetn3_1  [get_bd_pins peripheral_aresetn3] \
  [get_bd_pins pl_audio_out/peripheral_aresetn3]
  connect_bd_net -net pl_audio_out_irq  [get_bd_pins pl_audio_out/irq] \
  [get_bd_pins irq]
  connect_bd_net -net ps_cfg_clk_1  [get_bd_pins ps_cfg_clk] \
  [get_bd_pins pl_audio_out/ps_cfg_clk]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins aresetn] \
  [get_bd_pins pl_audio_out/aresetn]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins aud_mrst] \
  [get_bd_pins pl_audio_out/aud_mrst]
  connect_bd_net -net s_axi_aresetn_1  [get_bd_pins s_axi_aresetn] \
  [get_bd_pins pl_video_s0p0/s_axi_aresetn]
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

# Hierarchical cell: dc_in_out
proc create_hier_cell_dc_in_out { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_dc_in_out() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_s2mm

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mm_video_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_CTRL1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2


  # Create pins
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir I -from 0 -to 0 -type data i2s_lrclk
  create_bd_pin -dir I -type clk s_axi_aclk1
  create_bd_pin -dir I -from 3 -to 0 sdata
  create_bd_pin -dir I vid_active_video1_0
  create_bd_pin -dir I vid_hsync1_0
  create_bd_pin -dir I vid_vsync1_0
  create_bd_pin -dir I -from 71 -to 0 Din
  create_bd_pin -dir O -type intr irq
  create_bd_pin -dir O -type intr interrupt
  create_bd_pin -dir I -from 0 -to 0 Op2_0
  create_bd_pin -dir O -from 10 -to 0 dout_0
  create_bd_pin -dir I -type clk s_axi_aclk_0
  create_bd_pin -dir I -type clk slowest_sync_clk
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn3
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir I dcm_locked1

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00190280} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {0} \
  ] $axi_gpio_0


  # Create instance: dc_pl_out_pipeline
  create_hier_cell_dc_pl_out_pipeline $hier_obj dc_pl_out_pipeline

  # Create instance: rst_module
  create_hier_cell_rst_module $hier_obj rst_module

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
    CONFIG.DOUT_WIDTH {3} \
  ] $xlslice_1


  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {21} \
    CONFIG.DIN_TO {19} \
    CONFIG.DOUT_WIDTH {3} \
  ] $xlslice_2


  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_3 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {24} \
    CONFIG.DIN_TO {22} \
    CONFIG.DOUT_WIDTH {3} \
  ] $xlslice_3


  # Create instance: axi_gpio_alpha_bypass_en, and set properties
  set axi_gpio_alpha_bypass_en [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_alpha_bypass_en ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {5} \
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


  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_4 ]
  set_property CONFIG.DIN_WIDTH {5} $xlslice_4


  # Create instance: axi_gpio_1, and set properties
  set axi_gpio_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_1 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00190280} \
    CONFIG.C_GPIO_WIDTH {3} \
    CONFIG.C_IS_DUAL {0} \
  ] $axi_gpio_1


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dc_pl_out_pipeline/S_AXI] [get_bd_intf_pins S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins S_AXI1]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins dc_pl_out_pipeline/s_axi_CTRL1] [get_bd_intf_pins s_axi_CTRL1]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins axi_gpio_alpha_bypass_en/S_AXI] [get_bd_intf_pins S_AXI_0]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins dc_pl_out_pipeline/m_axi_mm_video_0] [get_bd_intf_pins m_axi_mm_video_0]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins dc_pl_out_pipeline/s_axi_ctrl] [get_bd_intf_pins s_axi_ctrl]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins axi_gpio_1/S_AXI] [get_bd_intf_pins S_AXI2]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins m_axi_s2mm] [get_bd_intf_pins dc_pl_out_pipeline/m_axi_s2mm]

  # Create port connections
  connect_bd_net -net Din_1  [get_bd_pins Din] \
  [get_bd_pins dc_pl_out_pipeline/Din]
  connect_bd_net -net Net  [get_bd_pins axi_gpio_alpha_bypass_en/gpio2_io_o] \
  [get_bd_pins xlslice_4/Din] \
  [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net Op2_1  [get_bd_pins Op2_0] \
  [get_bd_pins dc_pl_out_pipeline/Op2]
  connect_bd_net -net PS_0_pl0_resetn  [get_bd_pins ext_reset_in] \
  [get_bd_pins rst_module/ext_reset_in]
  connect_bd_net -net Video_out8_interrupt  [get_bd_pins dc_pl_out_pipeline/interrupt] \
  [get_bd_pins interrupt]
  connect_bd_net -net ap_rst_n_1  [get_bd_pins rst_module/peripheral_aresetn] \
  [get_bd_pins dc_pl_out_pipeline/ap_rst_n] \
  [get_bd_pins axi_gpio_alpha_bypass_en/s_axi_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins axi_gpio_1/s_axi_aresetn]
  connect_bd_net -net axi_gpio_0_gpio_io_o  [get_bd_pins axi_gpio_0/gpio_io_o] \
  [get_bd_pins xlslice_0/Din] \
  [get_bd_pins xlslice_1/Din] \
  [get_bd_pins xlslice_2/Din] \
  [get_bd_pins xlslice_3/Din]
  connect_bd_net -net axi_gpio_1_gpio_io_o  [get_bd_pins axi_gpio_1/gpio_io_o] \
  [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net axi_gpio_alpha_bypass_en_gpio_io_o  [get_bd_pins axi_gpio_alpha_bypass_en/gpio_io_o] \
  [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net clk_wiz_pl_vid_1x_clk  [get_bd_pins s_axi_aclk1] \
  [get_bd_pins dc_pl_out_pipeline/aclk] \
  [get_bd_pins rst_module/slowest_sync_clk] \
  [get_bd_pins rst_module/slowest_sync_clk1] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins axi_gpio_1/s_axi_aclk]
  connect_bd_net -net dc_pl_out_pipeline_irq  [get_bd_pins dc_pl_out_pipeline/irq] \
  [get_bd_pins irq]
  connect_bd_net -net dcm_locked1_1  [get_bd_pins dcm_locked1] \
  [get_bd_pins rst_module/dcm_locked1]
  connect_bd_net -net dcm_locked_1  [get_bd_pins dcm_locked] \
  [get_bd_pins rst_module/dcm_locked]
  connect_bd_net -net mmi_dpdc_core_0_if_mmi_pl_i2s0_i2slrclk_i  [get_bd_pins i2s_lrclk] \
  [get_bd_pins rst_module/slowest_sync_clk2] \
  [get_bd_pins dc_pl_out_pipeline/aud_mclk]
  connect_bd_net -net rst_module_peripheral_aresetn1  [get_bd_pins rst_module/peripheral_aresetn1] \
  [get_bd_pins dc_pl_out_pipeline/s_axi_aresetn]
  connect_bd_net -net rst_module_peripheral_aresetn3  [get_bd_pins rst_module/peripheral_aresetn3] \
  [get_bd_pins peripheral_aresetn3] \
  [get_bd_pins dc_pl_out_pipeline/peripheral_aresetn3]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn2] \
  [get_bd_pins dc_pl_out_pipeline/aresetn]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins rst_module/peripheral_reset] \
  [get_bd_pins dc_pl_out_pipeline/aud_mrst] \
  [get_bd_pins dc_pl_out_pipeline/vid_reset]
  connect_bd_net -net rst_processor_150MHz_interconnect_aresetn  [get_bd_pins rst_module/interconnect_aresetn] \
  [get_bd_pins dc_pl_out_pipeline/s_axi_ctrl_aresetn]
  connect_bd_net -net s_axi_aclk_0_1  [get_bd_pins s_axi_aclk_0] \
  [get_bd_pins axi_gpio_alpha_bypass_en/s_axi_aclk]
  connect_bd_net -net sdata_1  [get_bd_pins sdata] \
  [get_bd_pins dc_pl_out_pipeline/sdata]
  connect_bd_net -net slowest_sync_clk3_1  [get_bd_pins slowest_sync_clk] \
  [get_bd_pins rst_module/slowest_sync_clk3] \
  [get_bd_pins dc_pl_out_pipeline/ps_cfg_clk]
  connect_bd_net -net vid_active_video1_1  [get_bd_pins vid_active_video1_0] \
  [get_bd_pins dc_pl_out_pipeline/vid_active_video1]
  connect_bd_net -net vid_hsync1_1  [get_bd_pins vid_hsync1_0] \
  [get_bd_pins dc_pl_out_pipeline/vid_hsync1]
  connect_bd_net -net vid_vsync1_1  [get_bd_pins vid_vsync1_0] \
  [get_bd_pins dc_pl_out_pipeline/vid_vsync1]
  connect_bd_net -net xlconcat_0_dout  [get_bd_pins xlconcat_0/dout] \
  [get_bd_pins dout_0]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins dc_pl_out_pipeline/dp_hres]
  connect_bd_net -net xlslice_1_Dout  [get_bd_pins xlslice_1/Dout] \
  [get_bd_pins dc_pl_out_pipeline/pixel_mode]
  connect_bd_net -net xlslice_2_Dout  [get_bd_pins xlslice_2/Dout] \
  [get_bd_pins dc_pl_out_pipeline/bpc]
  connect_bd_net -net xlslice_3_Dout  [get_bd_pins xlslice_3/Dout] \
  [get_bd_pins dc_pl_out_pipeline/color_format]
  connect_bd_net -net xlslice_4_Dout  [get_bd_pins xlslice_4/Dout] \
  [get_bd_pins xlconcat_0/In1]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell design_name } {

  variable script_folder

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
    CONFIG.MMI_CONFIG(DPDC_PRESENTATION_MODE) {Non_Live} \
    CONFIG.MMI_CONFIG(MDB5_GT) {None} \
    CONFIG.MMI_CONFIG(MMI_DP_HPD) {PS_MIO_12} \
    CONFIG.MMI_CONFIG(MMI_GPU_ENABLE) {1} \
    CONFIG.MMI_CONFIG(PL_MMI_INTERRUPTS_EN) {1} \
    CONFIG.MMI_CONFIG(RTL_DEBUG) {1} \
    CONFIG.MMI_CONFIG(UDH_GT) {DP_X1} \
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
    CONFIG.PS11_CONFIG(UDH_GT) {DP_X1} \
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

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {7} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: clkx5_wiz_0, and set properties
  set clkx5_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clkx5_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {pl_vid_1x_clk,pl_vid_2x_clk,ps_cfg_clk,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {300.000,600.000,230.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,true,true,false,false,false,false} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
  ] $clkx5_wiz_0


  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {1} \
    CONFIG.IN1_WIDTH {1} \
    CONFIG.IN2_WIDTH {1} \
    CONFIG.IN3_WIDTH {16} \
    CONFIG.IN4_WIDTH {15} \
    CONFIG.NUM_PORTS {4} \
  ] $xlconcat_0


  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {0} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {3} \
    CONFIG.C_GPIO_WIDTH {19} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_0


  # Create instance: clkx5_wiz_1, and set properties
  set clkx5_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clkx5_wiz_1 ]
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
  ] $clkx5_wiz_1


  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]
  set_property CONFIG.DIN_WIDTH {3} $xlslice_0


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {3} \
  ] $xlslice_1


  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {2} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {3} \
  ] $xlslice_2


  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_0_1 [get_bd_intf_pins dc_in_out/S_AXI_0] [get_bd_intf_pins smartconnect_0/M05_AXI]
  connect_bd_intf_net -intf_net axi_noc2_0_C0_CH0_LPDDR5 [get_bd_intf_ports C0_CH0_LPDDR5_0] [get_bd_intf_pins axi_noc2_0/C0_CH0_LPDDR5]
  connect_bd_intf_net -intf_net axi_noc2_0_C0_CH1_LPDDR5 [get_bd_intf_ports C0_CH1_LPDDR5_0] [get_bd_intf_pins axi_noc2_0/C0_CH1_LPDDR5]
  connect_bd_intf_net -intf_net dc_in_out_m_axi_mm_video_0 [get_bd_intf_pins axi_noc2_0/S10_AXI] [get_bd_intf_pins dc_in_out/m_axi_mm_video_0]
  connect_bd_intf_net -intf_net dc_in_out_m_axi_s2mm [get_bd_intf_pins dc_in_out/m_axi_s2mm] [get_bd_intf_pins axi_noc2_0/S11_AXI]
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
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins dc_in_out/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins smartconnect_0/M02_AXI] [get_bd_intf_pins dc_in_out/S_AXI1]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins smartconnect_0/M03_AXI] [get_bd_intf_pins dc_in_out/s_axi_CTRL1]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins smartconnect_0/M04_AXI] [get_bd_intf_pins dc_in_out/s_axi_ctrl]
  connect_bd_intf_net -intf_net smartconnect_0_M06_AXI [get_bd_intf_pins smartconnect_0/M06_AXI] [get_bd_intf_pins dc_in_out/S_AXI2]
  connect_bd_intf_net -intf_net sys_clk0_0_1 [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins axi_noc2_0/sys_clk0]

  # Create port connections
  connect_bd_net -net axi_gpio_0_gpio2_io_o  [get_bd_pins axi_gpio_0/gpio2_io_o] \
  [get_bd_pins xlslice_0/Din] \
  [get_bd_pins xlslice_1/Din] \
  [get_bd_pins xlslice_2/Din]
  connect_bd_net -net clkx5_wiz_0_i2s_clk  [get_bd_pins clkx5_wiz_1/i2s_clk] \
  [get_bd_pins dc_in_out/i2s_lrclk] \
  [get_bd_pins axi_noc2_0/aclk11]
  connect_bd_net -net clkx5_wiz_0_locked  [get_bd_pins clkx5_wiz_0/locked] \
  [get_bd_pins dc_in_out/dcm_locked]
  connect_bd_net -net clkx5_wiz_0_pl_vid_2x_clk  [get_bd_pins clkx5_wiz_0/pl_vid_1x_clk] \
  [get_bd_pins dc_in_out/s_axi_aclk1] \
  [get_bd_pins axi_noc2_0/aclk12] \
  [get_bd_pins smartconnect_0/aclk1] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk] \
  [get_bd_pins dc_in_out/s_axi_aclk_0]
  connect_bd_net -net clkx5_wiz_0_pl_vid_2x_clk1  [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk]
  connect_bd_net -net clkx5_wiz_0_ps_cfg_clk  [get_bd_pins clkx5_wiz_0/ps_cfg_clk] \
  [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins dc_in_out/slowest_sync_clk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk]
  connect_bd_net -net clkx5_wiz_1_locked  [get_bd_pins clkx5_wiz_1/locked] \
  [get_bd_pins dc_in_out/dcm_locked1]
  connect_bd_net -net dc_in_out_dout_0  [get_bd_pins dc_in_out/dout_0] \
  [get_bd_pins ps_wizard_0/video_ctrl]
  connect_bd_net -net dc_in_out_interrupt  [get_bd_pins dc_in_out/interrupt] \
  [get_bd_pins ps_wizard_0/pl_mmi_irq0]
  connect_bd_net -net dc_in_out_irq  [get_bd_pins dc_in_out/irq] \
  [get_bd_pins ps_wizard_0/pl_mmi_irq1]
  connect_bd_net -net dc_in_out_peripheral_aresetn3  [get_bd_pins dc_in_out/peripheral_aresetn3] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn]
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
  connect_bd_net -net ps_wizard_0_i2sfb_i2s0_sdata_0  [get_bd_pins ps_wizard_0/i2sfb_i2s0_sdata_0] \
  [get_bd_pins dc_in_out/sdata]
  connect_bd_net -net ps_wizard_0_lpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk8]
  connect_bd_net -net ps_wizard_0_mmi_dc_axi_noc0_clk  [get_bd_pins ps_wizard_0/mmi_dc_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk13]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins axi_noc2_0/aclk10] \
  [get_bd_pins clkx5_wiz_0/clk_in1] \
  [get_bd_pins clkx5_wiz_1/clk_in1]
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_pins dc_in_out/ext_reset_in]
  connect_bd_net -net ps_wizard_0_pmcx_axi_noc0_clk  [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk9]
  connect_bd_net -net ps_wizard_0_strt_capture  [get_bd_pins ps_wizard_0/strt_capture] \
  [get_bd_pins dc_in_out/Op2_0]
  connect_bd_net -net ps_wizard_0_videofb_s0_active_video  [get_bd_pins ps_wizard_0/videofb_s0_active_video] \
  [get_bd_pins dc_in_out/vid_active_video1_0]
  connect_bd_net -net ps_wizard_0_videofb_s0_data  [get_bd_pins ps_wizard_0/videofb_s0_data] \
  [get_bd_pins dc_in_out/Din]
  connect_bd_net -net ps_wizard_0_videofb_s0_hsync  [get_bd_pins ps_wizard_0/videofb_s0_hsync] \
  [get_bd_pins dc_in_out/vid_hsync1_0]
  connect_bd_net -net ps_wizard_0_videofb_s0_vsync  [get_bd_pins ps_wizard_0/videofb_s0_vsync] \
  [get_bd_pins dc_in_out/vid_vsync1_0]
  connect_bd_net -net ps_wizard_0_vsync0_cnt  [get_bd_pins ps_wizard_0/vsync0_cnt] \
  [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net ps_wizard_0_vsync_err  [get_bd_pins ps_wizard_0/vsync_err] \
  [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net xlconcat_0_dout  [get_bd_pins xlconcat_0/dout] \
  [get_bd_pins axi_gpio_0/gpio_io_i]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins ps_wizard_0/dp_external_vsync_event]
  connect_bd_net -net xlslice_1_Dout  [get_bd_pins xlslice_1/Dout] \
  [get_bd_pins ps_wizard_0/dp_external_custom_event1]
  connect_bd_net -net xlslice_2_Dout  [get_bd_pins xlslice_2/Dout] \
  [get_bd_pins ps_wizard_0/dp_external_custom_event2]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_dc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_dc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0550000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dc_in_out/dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/m_axi_s2mm] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dc_in_out/dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/m_axi_s2mm] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/Data_m_axi_mm_video] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/Data_m_axi_mm_video] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_MED]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/axi_gpio_alpha_bypass_en/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg]
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
  set_msg_config -suppress -id {BD 41-237} -string {{CRITICAL WARNING: [BD 41-237] Bus Interface property TDATA_NUM_BYTES does not match between /dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axis_video(9) and /dc_in_out/dc_pl_out_pipeline/pl_video_s0p0/nativevideo_axis_bridge/m_axis_video(24)} }

  validate_bd_design
  save_bd_design
}
# End of create_root_design()
