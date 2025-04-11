##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: avtpg_vp1
proc create_hier_cell_avtpg_vp1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_avtpg_vp1() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 av_axi

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf


  # Create pins
  create_bd_pin -dir I Op1
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -type clk i2s_clk
  create_bd_pin -dir I -type rst s_axis_aud_aresetn
  create_bd_pin -dir I -type clk vid_clk
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_active_video
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_hblank
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_hsync
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_vblank
  create_bd_pin -dir I -from 0 -to 0 vtiming_in_vsync
  create_bd_pin -dir O -from 71 -to 0 tx_vid_pixel
  create_bd_pin -dir O -from 0 -to 0 tx_vid_enable
  create_bd_pin -dir O -from 0 -to 0 tx_vid_hsync
  create_bd_pin -dir O -from 0 -to 0 tx_vid_vsync

  # Create instance: av_pat_gen_0, and set properties
  set av_pat_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psdpdc_av_pat_gen av_pat_gen_0 ]
  set_property -dict [list \
    CONFIG.Alpha {0} \
    CONFIG.BPC {12} \
    CONFIG.PART_EN {1} \
    CONFIG.PPC {2} \
    CONFIG.SDP_EN {0} \
  ] $av_pat_gen_0


  # Create instance: avtpg_tready_gated, and set properties
  set avtpg_tready_gated [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic avtpg_tready_gated ]
  set_property -dict [list \
    CONFIG.C_OPERATION {or} \
    CONFIG.C_SIZE {1} \
  ] $avtpg_tready_gated


  # Create instance: axis2video_tvalid_gate, and set properties
  set axis2video_tvalid_gate [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic axis2video_tvalid_gate ]
  set_property CONFIG.C_SIZE {1} $axis2video_tvalid_gate


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


  # Create instance: tvalid_gate_control, and set properties
  set tvalid_gate_control [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic tvalid_gate_control ]
  set_property -dict [list \
    CONFIG.C_OPERATION {or} \
    CONFIG.C_SIZE {1} \
  ] $tvalid_gate_control


  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic util_vector_logic_0 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {and} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_0


  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic util_vector_logic_2 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {or} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_2


  # Create instance: util_vector_logic_4, and set properties
  set util_vector_logic_4 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic util_vector_logic_4 ]
  set_property CONFIG.C_SIZE {1} $util_vector_logic_4


  # Create instance: util_vector_logic_6, and set properties
  set util_vector_logic_6 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic util_vector_logic_6 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_6


  # Create instance: util_vector_logic_7, and set properties
  set util_vector_logic_7 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic util_vector_logic_7 ]
  set_property CONFIG.C_SIZE {1} $util_vector_logic_7


  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]

  # Create instance: ilconstant_1, and set properties
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_1 ]
  set_property CONFIG.CONST_VAL {0} $ilconstant_1


  # Create instance: ilconstant_2, and set properties
  set ilconstant_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_2 ]
  set_property CONFIG.CONST_VAL {0} $ilconstant_2


  # Create instance: v_axi4s_vid_out_0, and set properties
  set v_axi4s_vid_out_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out v_axi4s_vid_out_0 ]
  set_property -dict [list \
    CONFIG.C_NATIVE_COMPONENT_WIDTH {12} \
    CONFIG.C_PIXELS_PER_CLOCK {2} \
    CONFIG.C_S_AXIS_VIDEO_DATA_WIDTH {12} \
    CONFIG.C_S_AXIS_VIDEO_FORMAT {2} \
  ] $v_axi4s_vid_out_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins av_axi] [get_bd_intf_pins av_pat_gen_0/av_axi]
  connect_bd_intf_net -intf_net av_pat_gen_0_vid_out_axi4s [get_bd_intf_pins av_pat_gen_0/vid_out_axi4s] [get_bd_intf_pins v_axi4s_vid_out_0/video_in]
  connect_bd_intf_net -intf_net v_axi4s_vid_out_0_vid_io_out [get_bd_intf_pins vid_intf] [get_bd_intf_pins v_axi4s_vid_out_0/vid_io_out]

  # Create port connections
  connect_bd_net -net Op1_1  [get_bd_pins Op1] \
  [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins TPG_GEN_EN] \
  [get_bd_pins v_axi4s_vid_out_0/vid_io_out_ce] \
  [get_bd_pins av_pat_gen_0/TPG_GEN_EN]
  connect_bd_net -net aud_out_axi4s_aclk_1  [get_bd_pins i2s_clk] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aclk] \
  [get_bd_pins av_pat_gen_0/aud_clk]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tdata  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tdata] \
  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tdata]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tlast  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tlast] \
  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tlast]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tuser  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tuser] \
  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tuser]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tvalid  [get_bd_pins axis2video_tvalid_gate/Res] \
  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tvalid]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tvalid1  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tvalid] \
  [get_bd_pins axis2video_tvalid_gate/Op1]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_enable  [get_bd_pins v_axi4s_vid_out_0/vid_active_video] \
  [get_bd_pins tx_vid_enable]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_hsync  [get_bd_pins v_axi4s_vid_out_0/vid_hsync] \
  [get_bd_pins tx_vid_hsync]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_pixel  [get_bd_pins v_axi4s_vid_out_0/vid_data] \
  [get_bd_pins tx_vid_pixel]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_vsync  [get_bd_pins v_axi4s_vid_out_0/vid_vsync] \
  [get_bd_pins tx_vid_vsync]
  connect_bd_net -net axis_nativevideo_bridge_video_in_tready  [get_bd_pins avtpg_tready_gated/Res] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tready]
  connect_bd_net -net axis_nativevideo_bridge_video_in_tready1  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tready] \
  [get_bd_pins c_shift_ram_4_delay/D] \
  [get_bd_pins util_vector_logic_4/Op2]
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
  connect_bd_net -net ilconstant_1_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins v_axi4s_vid_out_0/fid]
  connect_bd_net -net ilconstant_2_dout  [get_bd_pins ilconstant_2/dout] \
  [get_bd_pins util_vector_logic_7/Op2]
  connect_bd_net -net net_mb_ss_0_clk_out2  [get_bd_pins av_axi_aclk] \
  [get_bd_pins av_pat_gen_0/av_axi_aclk]
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
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins v_axi4s_vid_out_0/aclken]
  connect_bd_net -net vid_out_axi4s_aclk_1  [get_bd_pins vid_clk] \
  [get_bd_pins c_shift_ram_1_delay/CLK] \
  [get_bd_pins c_shift_ram_4_delay/CLK] \
  [get_bd_pins v_axi4s_vid_out_0/aclk] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aclk]
  connect_bd_net -net vid_out_axi4s_aresetn_1  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins v_axi4s_vid_out_0/aresetn] \
  [get_bd_pins av_pat_gen_0/av_axi_aresetn] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aresetn]
  connect_bd_net -net vtiming_in_active_video_1  [get_bd_pins vtiming_in_active_video] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_active_video]
  connect_bd_net -net vtiming_in_hblank_1  [get_bd_pins vtiming_in_hblank] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_hblank]
  connect_bd_net -net vtiming_in_hsync_1  [get_bd_pins vtiming_in_hsync] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_hsync]
  connect_bd_net -net vtiming_in_vblank_1  [get_bd_pins vtiming_in_vblank] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_vblank]
  connect_bd_net -net vtiming_in_vsync_1  [get_bd_pins vtiming_in_vsync] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_vsync]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: avtpg_vp0
proc create_hier_cell_avtpg_vp0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_avtpg_vp0() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 av_axi

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl_0


  # Create pins
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN
  create_bd_pin -dir O -from 0 -to 0 active_video_out
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -type ce clken
  create_bd_pin -dir O -from 0 -to 0 hblank_out
  create_bd_pin -dir O -from 0 -to 0 hsync_out
  create_bd_pin -dir I -type clk i2s_clk
  create_bd_pin -dir I -type rst s_axis_aud_aresetn
  create_bd_pin -dir O -from 0 -to 0 vblank_out
  create_bd_pin -dir I -type clk vid_clk
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir O vid_out_axi4s_tvalid
  create_bd_pin -dir O -from 0 -to 0 vsync_out
  create_bd_pin -dir O lrclk_out
  create_bd_pin -dir O sclk_out
  create_bd_pin -dir O -from 3 -to 0 dout
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir O -from 95 -to 0 dout1
  create_bd_pin -dir O -from 0 -to 0 tx_vid_hsync
  create_bd_pin -dir O -from 0 -to 0 tx_vid_vsync
  create_bd_pin -dir O -from 0 -to 0 tx_vid_enable
  create_bd_pin -dir O ext_sdp00_req_o
  create_bd_pin -dir O -from 71 -to 0 ext_sdp00_data_o
  create_bd_pin -dir O ext_sdp01_req_o
  create_bd_pin -dir O -from 71 -to 0 ext_sdp01_data_o
  create_bd_pin -dir I ext_sdp01_ack_i
  create_bd_pin -dir I ext_sdp01_horizontal_blanking_i
  create_bd_pin -dir I -from 1 -to 0 ext_sdp01_line_cnt_mat_i
  create_bd_pin -dir I ext_sdp01_vertical_blanking_i
  create_bd_pin -dir I ext_sdp00_ack_i
  create_bd_pin -dir I ext_sdp00_horizontal_blanking_i
  create_bd_pin -dir I -from 1 -to 0 ext_sdp00_line_cnt_mat_i
  create_bd_pin -dir I ext_sdp00_vertical_blanking_i

  # Create instance: av_pat_gen_0, and set properties
  set av_pat_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psdpdc_av_pat_gen av_pat_gen_0 ]
  set_property -dict [list \
    CONFIG.Alpha {1} \
    CONFIG.BPC {12} \
    CONFIG.PART_EN {1} \
    CONFIG.PPC {2} \
    CONFIG.SDP_EN {1} \
  ] $av_pat_gen_0


  # Create instance: v_tc_0, and set properties
  set v_tc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc v_tc_0 ]
  set_property -dict [list \
    CONFIG.VIDEO_MODE {1080p} \
    CONFIG.enable_detection {false} \
    CONFIG.max_clocks_per_line {8192} \
  ] $v_tc_0


  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]

  # Create instance: ilconstant_1, and set properties
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_1 ]
  set_property CONFIG.CONST_VAL {0} $ilconstant_1


  # Create instance: i2s_transmitter_0, and set properties
  set i2s_transmitter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psdpdc_i2s_transmitter i2s_transmitter_0 ]
  set_property CONFIG.C_NUM_CHANNELS {8} $i2s_transmitter_0


  # Create instance: ilconcat_4, and set properties
  set ilconcat_4 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_4 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {1} \
    CONFIG.IN1_WIDTH {1} \
    CONFIG.IN2_WIDTH {1} \
    CONFIG.IN3_WIDTH {1} \
    CONFIG.NUM_PORTS {4} \
  ] $ilconcat_4


  # Create instance: v_axi4s_vid_out_0, and set properties
  set v_axi4s_vid_out_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out v_axi4s_vid_out_0 ]
  set_property -dict [list \
    CONFIG.C_NATIVE_COMPONENT_WIDTH {12} \
    CONFIG.C_PIXELS_PER_CLOCK {2} \
    CONFIG.C_S_AXIS_VIDEO_DATA_WIDTH {12} \
    CONFIG.C_S_AXIS_VIDEO_FORMAT {6} \
  ] $v_axi4s_vid_out_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ctrl] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins av_axi] [get_bd_intf_pins av_pat_gen_0/av_axi]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins i2s_transmitter_0/s_axi_ctrl] [get_bd_intf_pins s_axi_ctrl_0]
  connect_bd_intf_net -intf_net av_pat_gen_0_aud_out_axi4s [get_bd_intf_pins i2s_transmitter_0/s_axis_aud] [get_bd_intf_pins av_pat_gen_0/aud_out_axi4s]
  connect_bd_intf_net -intf_net av_pat_gen_0_vid_out_axi4s [get_bd_intf_pins av_pat_gen_0/vid_out_axi4s] [get_bd_intf_pins v_axi4s_vid_out_0/video_in]
  connect_bd_intf_net -intf_net v_axi4s_vid_out_0_vid_io_out [get_bd_intf_pins vid_intf] [get_bd_intf_pins v_axi4s_vid_out_0/vid_io_out]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in] [get_bd_intf_pins v_tc_0/vtiming_out]

  # Create port connections
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins TPG_GEN_EN] \
  [get_bd_pins v_axi4s_vid_out_0/vid_io_out_ce] \
  [get_bd_pins av_pat_gen_0/TPG_GEN_EN]
  connect_bd_net -net aud_mrst_1  [get_bd_pins aud_mrst] \
  [get_bd_pins i2s_transmitter_0/aud_mrst]
  connect_bd_net -net aud_out_axi4s_aclk_1  [get_bd_pins i2s_clk] \
  [get_bd_pins i2s_transmitter_0/aud_mclk] \
  [get_bd_pins i2s_transmitter_0/s_axis_aud_aclk] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aclk] \
  [get_bd_pins av_pat_gen_0/aud_clk]
  connect_bd_net -net av_pat_gen_0_ext_sdp00_data_o  [get_bd_pins av_pat_gen_0/ext_sdp00_data_o] \
  [get_bd_pins ext_sdp00_data_o]
  connect_bd_net -net av_pat_gen_0_ext_sdp00_req_o  [get_bd_pins av_pat_gen_0/ext_sdp00_req_o] \
  [get_bd_pins ext_sdp00_req_o]
  connect_bd_net -net av_pat_gen_0_ext_sdp01_data_o  [get_bd_pins av_pat_gen_0/ext_sdp01_data_o] \
  [get_bd_pins ext_sdp01_data_o]
  connect_bd_net -net av_pat_gen_0_ext_sdp01_req_o  [get_bd_pins av_pat_gen_0/ext_sdp01_req_o] \
  [get_bd_pins ext_sdp01_req_o]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tdata  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tdata] \
  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tdata]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tlast  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tlast] \
  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tlast]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tuser  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tuser] \
  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tuser]
  connect_bd_net -net av_pat_gen_0_vid_out_axi4s_tvalid  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tvalid] \
  [get_bd_pins vid_out_axi4s_tvalid] \
  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tvalid]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_enable  [get_bd_pins v_axi4s_vid_out_0/vid_active_video] \
  [get_bd_pins tx_vid_enable]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_hsync  [get_bd_pins v_axi4s_vid_out_0/vid_hsync] \
  [get_bd_pins tx_vid_hsync]
  connect_bd_net -net axis_nativevideo_bridge_tx_vid_vsync  [get_bd_pins v_axi4s_vid_out_0/vid_vsync] \
  [get_bd_pins tx_vid_vsync]
  connect_bd_net -net clken_1  [get_bd_pins clken] \
  [get_bd_pins v_tc_0/clken]
  connect_bd_net -net ext_sdp00_ack_i_1  [get_bd_pins ext_sdp00_ack_i] \
  [get_bd_pins av_pat_gen_0/ext_sdp00_ack_i]
  connect_bd_net -net ext_sdp00_horizontal_blanking_i_1  [get_bd_pins ext_sdp00_horizontal_blanking_i] \
  [get_bd_pins av_pat_gen_0/ext_sdp00_horizontal_blanking_i]
  connect_bd_net -net ext_sdp00_line_cnt_mat_i_1  [get_bd_pins ext_sdp00_line_cnt_mat_i] \
  [get_bd_pins av_pat_gen_0/ext_sdp00_line_cnt_mat_i]
  connect_bd_net -net ext_sdp00_vertical_blanking_i_1  [get_bd_pins ext_sdp00_vertical_blanking_i] \
  [get_bd_pins av_pat_gen_0/ext_sdp00_vertical_blanking_i]
  connect_bd_net -net ext_sdp01_ack_i_1  [get_bd_pins ext_sdp01_ack_i] \
  [get_bd_pins av_pat_gen_0/ext_sdp01_ack_i]
  connect_bd_net -net ext_sdp01_horizontal_blanking_i_1  [get_bd_pins ext_sdp01_horizontal_blanking_i] \
  [get_bd_pins av_pat_gen_0/ext_sdp01_horizontal_blanking_i]
  connect_bd_net -net ext_sdp01_line_cnt_mat_i_1  [get_bd_pins ext_sdp01_line_cnt_mat_i] \
  [get_bd_pins av_pat_gen_0/ext_sdp01_line_cnt_mat_i]
  connect_bd_net -net ext_sdp01_vertical_blanking_i_1  [get_bd_pins ext_sdp01_vertical_blanking_i] \
  [get_bd_pins av_pat_gen_0/ext_sdp01_vertical_blanking_i]
  connect_bd_net -net i2s_transmitter_0_lrclk_out  [get_bd_pins i2s_transmitter_0/lrclk_out] \
  [get_bd_pins lrclk_out]
  connect_bd_net -net i2s_transmitter_0_sclk_out  [get_bd_pins i2s_transmitter_0/sclk_out] \
  [get_bd_pins sclk_out]
  connect_bd_net -net i2s_transmitter_0_sdata_0_out  [get_bd_pins i2s_transmitter_0/sdata_0_out] \
  [get_bd_pins ilconcat_4/In0]
  connect_bd_net -net i2s_transmitter_0_sdata_1_out  [get_bd_pins i2s_transmitter_0/sdata_1_out] \
  [get_bd_pins ilconcat_4/In1]
  connect_bd_net -net i2s_transmitter_0_sdata_2_out  [get_bd_pins i2s_transmitter_0/sdata_2_out] \
  [get_bd_pins ilconcat_4/In2]
  connect_bd_net -net i2s_transmitter_0_sdata_3_out  [get_bd_pins i2s_transmitter_0/sdata_3_out] \
  [get_bd_pins ilconcat_4/In3]
  connect_bd_net -net ilconcat_4_dout  [get_bd_pins ilconcat_4/dout] \
  [get_bd_pins dout]
  connect_bd_net -net ilconstant_0_dout  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins v_tc_0/s_axi_aclken] \
  [get_bd_pins v_axi4s_vid_out_0/aclken]
  connect_bd_net -net ilconstant_1_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins v_tc_0/fsync_in] \
  [get_bd_pins v_axi4s_vid_out_0/fid]
  connect_bd_net -net net_mb_ss_0_clk_out2  [get_bd_pins av_axi_aclk] \
  [get_bd_pins v_tc_0/s_axi_aclk] \
  [get_bd_pins i2s_transmitter_0/s_axi_ctrl_aclk] \
  [get_bd_pins av_pat_gen_0/av_axi_aclk]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins s_axis_aud_aresetn] \
  [get_bd_pins i2s_transmitter_0/s_axis_aud_aresetn] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aresetn]
  connect_bd_net -net v_axi4s_vid_out_0_s_axis_video_tready  [get_bd_pins v_axi4s_vid_out_0/s_axis_video_tready] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_tready]
  connect_bd_net -net v_axi4s_vid_out_0_sof_state_out  [get_bd_pins v_axi4s_vid_out_0/sof_state_out] \
  [get_bd_pins v_tc_0/sof_state]
  connect_bd_net -net v_axi4s_vid_out_0_vid_data  [get_bd_pins v_axi4s_vid_out_0/vid_data] \
  [get_bd_pins dout1]
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce  [get_bd_pins v_axi4s_vid_out_0/vtg_ce] \
  [get_bd_pins v_tc_0/gen_clken]
  connect_bd_net -net v_tc_0_active_video_out  [get_bd_pins v_tc_0/active_video_out] \
  [get_bd_pins active_video_out] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_active_video]
  connect_bd_net -net v_tc_0_hblank_out  [get_bd_pins v_tc_0/hblank_out] \
  [get_bd_pins hblank_out] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_hblank]
  connect_bd_net -net v_tc_0_hsync_out  [get_bd_pins v_tc_0/hsync_out] \
  [get_bd_pins hsync_out] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_hsync]
  connect_bd_net -net v_tc_0_vblank_out  [get_bd_pins v_tc_0/vblank_out] \
  [get_bd_pins vblank_out] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_vblank]
  connect_bd_net -net v_tc_0_vsync_out  [get_bd_pins v_tc_0/vsync_out] \
  [get_bd_pins vsync_out] \
  [get_bd_pins v_axi4s_vid_out_0/vtg_vsync]
  connect_bd_net -net vid_out_axi4s_aclk_1  [get_bd_pins vid_clk] \
  [get_bd_pins v_tc_0/clk] \
  [get_bd_pins v_axi4s_vid_out_0/aclk] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aclk]
  connect_bd_net -net vid_out_axi4s_aresetn_1  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins v_tc_0/s_axi_aresetn] \
  [get_bd_pins v_axi4s_vid_out_0/aresetn] \
  [get_bd_pins v_tc_0/resetn] \
  [get_bd_pins i2s_transmitter_0/s_axi_ctrl_aresetn] \
  [get_bd_pins av_pat_gen_0/av_axi_aresetn] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

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
    CONFIG.C_M_AXIS_VIDEO_TDATA_WIDTH_BRIDGE_OUTPUT {72} \
    CONFIG.C_PPC {2} \
  ] $nativevideo_axis_bridge


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


  # Create instance: ilconcat_2, and set properties
  set ilconcat_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {16} \
    CONFIG.IN1_WIDTH {1} \
  ] $ilconcat_2


  # Create instance: ilconcat_3, and set properties
  set ilconcat_3 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {16} \
    CONFIG.IN1_WIDTH {1} \
  ] $ilconcat_3


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
  connect_bd_net -net ilconcat_2_dout  [get_bd_pins ilconcat_2/dout] \
  [get_bd_pins axi_gpio_1/gpio_io_i]
  connect_bd_net -net ilconcat_3_dout  [get_bd_pins ilconcat_3/dout] \
  [get_bd_pins axi_gpio_1/gpio2_io_i]
  connect_bd_net -net nativevideo_axis_bridge_hres_cntr_out  [get_bd_pins nativevideo_axis_bridge/hres_cntr_out] \
  [get_bd_pins ilconcat_2/In0]
  connect_bd_net -net nativevideo_axis_bridge_vres_cntr_out  [get_bd_pins nativevideo_axis_bridge/vres_cntr_out] \
  [get_bd_pins ilconcat_3/In0]
  connect_bd_net -net pixel_mode_1  [get_bd_pins pixel_mode] \
  [get_bd_pins nativevideo_axis_bridge/pixel_mode]
  connect_bd_net -net s_axi_aresetn_1  [get_bd_pins s_axi_aresetn] \
  [get_bd_pins axi_gpio_1/s_axi_aresetn]
  connect_bd_net -net vid_active_video1_1  [get_bd_pins vid_active_video1] \
  [get_bd_pins nativevideo_axis_bridge/vid_active_video]
  connect_bd_net -net vid_hsync1_1  [get_bd_pins vid_hsync1] \
  [get_bd_pins nativevideo_axis_bridge/vid_hsync] \
  [get_bd_pins ilconcat_2/In1]
  connect_bd_net -net vid_pixel0_0_1  [get_bd_pins vid_pixel0_0] \
  [get_bd_pins nativevideo_axis_bridge/vid_pixel0]
  connect_bd_net -net vid_pixel1_0_1  [get_bd_pins vid_pixel1_0] \
  [get_bd_pins nativevideo_axis_bridge/vid_pixel1]
  connect_bd_net -net vid_reset_1  [get_bd_pins vid_reset] \
  [get_bd_pins nativevideo_axis_bridge/vid_reset]
  connect_bd_net -net vid_vsync1_1  [get_bd_pins vid_vsync1] \
  [get_bd_pins nativevideo_axis_bridge/vid_vsync] \
  [get_bd_pins ilconcat_3/In1]

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

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_lite


  # Create pins
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk aud_mclk
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir O -type intr irq
  create_bd_pin -dir I -from 3 -to 0 sdata
  create_bd_pin -dir I -type clk ps_cfg_clk
  create_bd_pin -dir I -type rst peripheral_aresetn3
  create_bd_pin -dir I lrclk_in
  create_bd_pin -dir I sclk_in

  # Create instance: audio_formatter_0, and set properties
  set audio_formatter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:audio_formatter audio_formatter_0 ]
  set_property -dict [list \
    CONFIG.C_INCLUDE_MM2S {0} \
    CONFIG.C_MAX_NUM_CHANNELS_S2MM {8} \
    CONFIG.C_S2MM_DATAFORMAT {2} \
  ] $audio_formatter_0


  # Create instance: i2s_receiver_0, and set properties
  set i2s_receiver_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:i2s_receiver i2s_receiver_0 ]
  set_property -dict [list \
    CONFIG.C_IS_MASTER {0} \
    CONFIG.C_NUM_CHANNELS {8} \
  ] $i2s_receiver_0


  # Create instance: sdata_0, and set properties
  set sdata_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice sdata_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {0} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {4} \
  ] $sdata_0


  # Create instance: sdata_1, and set properties
  set sdata_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice sdata_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {4} \
  ] $sdata_1


  # Create instance: sdata_2, and set properties
  set sdata_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice sdata_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {2} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {4} \
  ] $sdata_2


  # Create instance: sdata_3, and set properties
  set sdata_3 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice sdata_3 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {3} \
    CONFIG.DIN_TO {3} \
    CONFIG.DIN_WIDTH {4} \
  ] $sdata_3


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins m_axi_s2mm] [get_bd_intf_pins audio_formatter_0/m_axi_s2mm]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins audio_formatter_0/s_axi_lite] [get_bd_intf_pins s_axi_lite]
  connect_bd_intf_net -intf_net i2s_receiver_0_m_axis_aud [get_bd_intf_pins audio_formatter_0/s_axis_s2mm] [get_bd_intf_pins i2s_receiver_0/m_axis_aud]
  connect_bd_intf_net -intf_net smartconnect_2_M01_AXI [get_bd_intf_pins s_axi_ctrl] [get_bd_intf_pins i2s_receiver_0/s_axi_ctrl]

  # Create port connections
  connect_bd_net -net clk_wiz_clk_out_1  [get_bd_pins aud_mclk] \
  [get_bd_pins audio_formatter_0/s_axis_s2mm_aclk] \
  [get_bd_pins i2s_receiver_0/aud_mclk] \
  [get_bd_pins i2s_receiver_0/m_axis_aud_aclk]
  connect_bd_net -net i2s_receiver_0_irq  [get_bd_pins i2s_receiver_0/irq] \
  [get_bd_pins irq]
  connect_bd_net -net ilslice_2_Dout  [get_bd_pins sdata_0/Dout] \
  [get_bd_pins i2s_receiver_0/sdata_0_in]
  connect_bd_net -net ilslice_3_Dout  [get_bd_pins sdata_1/Dout] \
  [get_bd_pins i2s_receiver_0/sdata_1_in]
  connect_bd_net -net ilslice_4_Dout  [get_bd_pins sdata_2/Dout] \
  [get_bd_pins i2s_receiver_0/sdata_2_in]
  connect_bd_net -net ilslice_5_Dout  [get_bd_pins sdata_3/Dout] \
  [get_bd_pins i2s_receiver_0/sdata_3_in]
  connect_bd_net -net lrclk_in_1  [get_bd_pins lrclk_in] \
  [get_bd_pins i2s_receiver_0/lrclk_in]
  connect_bd_net -net mmi_dc_wrap_ip_0_if_mmi_pl_i2s0_i2sdata_i  [get_bd_pins sdata] \
  [get_bd_pins sdata_0/Din] \
  [get_bd_pins sdata_1/Din] \
  [get_bd_pins sdata_2/Din] \
  [get_bd_pins sdata_3/Din]
  connect_bd_net -net peripheral_aresetn3_1  [get_bd_pins peripheral_aresetn3] \
  [get_bd_pins i2s_receiver_0/s_axi_ctrl_aresetn] \
  [get_bd_pins audio_formatter_0/s_axi_lite_aresetn]
  connect_bd_net -net ps_cfg_clk_1  [get_bd_pins ps_cfg_clk] \
  [get_bd_pins i2s_receiver_0/s_axi_ctrl_aclk] \
  [get_bd_pins audio_formatter_0/s_axi_lite_aclk]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins aresetn] \
  [get_bd_pins audio_formatter_0/s_axis_s2mm_aresetn] \
  [get_bd_pins i2s_receiver_0/m_axis_aud_aresetn]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins aud_mrst] \
  [get_bd_pins i2s_receiver_0/aud_mrst]
  connect_bd_net -net sclk_in_1  [get_bd_pins sclk_in] \
  [get_bd_pins i2s_receiver_0/sclk_in]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: dc_input_pipeline
proc create_hier_cell_dc_input_pipeline { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_dc_input_pipeline() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI


  # Create pins
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -type clk i2s_clk
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type rst s_axis_aud_aresetn
  create_bd_pin -dir I -type clk vid_clk1
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir O lrclk_out
  create_bd_pin -dir O sclk_out1
  create_bd_pin -dir O -from 3 -to 0 dout
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN
  create_bd_pin -dir O -from 95 -to 0 dout1
  create_bd_pin -dir O -from 0 -to 0 tx_vid_hsync
  create_bd_pin -dir O -from 0 -to 0 tx_vid_vsync
  create_bd_pin -dir O -from 0 -to 0 tx_vid_enable
  create_bd_pin -dir O -from 71 -to 0 tx_vid_pixel
  create_bd_pin -dir O -from 0 -to 0 tx_vid_enable1
  create_bd_pin -dir O -from 0 -to 0 tx_vid_hsync1
  create_bd_pin -dir O -from 0 -to 0 tx_vid_vsync1
  create_bd_pin -dir O ext_sdp00_req_o
  create_bd_pin -dir O -from 71 -to 0 ext_sdp00_data_o
  create_bd_pin -dir O ext_sdp01_req_o
  create_bd_pin -dir O -from 71 -to 0 ext_sdp01_data_o
  create_bd_pin -dir I ext_sdp01_ack_i
  create_bd_pin -dir I ext_sdp01_horizontal_blanking_i
  create_bd_pin -dir I -from 1 -to 0 ext_sdp01_line_cnt_mat_i
  create_bd_pin -dir I ext_sdp01_vertical_blanking_i
  create_bd_pin -dir I ext_sdp00_ack_i
  create_bd_pin -dir I ext_sdp00_horizontal_blanking_i
  create_bd_pin -dir I -from 1 -to 0 ext_sdp00_line_cnt_mat_i
  create_bd_pin -dir I ext_sdp00_vertical_blanking_i

  # Create instance: avtpg_vp0
  create_hier_cell_avtpg_vp0 $hier_obj avtpg_vp0

  # Create instance: avtpg_vp1
  create_hier_cell_avtpg_vp1 $hier_obj avtpg_vp1

  # Create instance: ilslice_8, and set properties
  set ilslice_8 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_8 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {16} \
    CONFIG.DIN_TO {16} \
  ] $ilslice_8


  # Create instance: smartconnect_gp0, and set properties
  set smartconnect_gp0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_gp0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {4} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_gp0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins avtpg_vp0/vid_intf] [get_bd_intf_pins vid_intf]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins avtpg_vp1/vid_intf] [get_bd_intf_pins vid_intf1]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins smartconnect_gp0/S00_AXI] [get_bd_intf_pins S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M00_AXI [get_bd_intf_pins smartconnect_gp0/M00_AXI] [get_bd_intf_pins avtpg_vp0/s_axi_ctrl_0]
  connect_bd_intf_net -intf_net smartconnect_gp0_M01_AXI1 [get_bd_intf_pins smartconnect_gp0/M01_AXI] [get_bd_intf_pins avtpg_vp0/av_axi]
  connect_bd_intf_net -intf_net smartconnect_gp0_M02_AXI [get_bd_intf_pins smartconnect_gp0/M02_AXI] [get_bd_intf_pins avtpg_vp1/av_axi]
  connect_bd_intf_net -intf_net smartconnect_gp0_M03_AXI1 [get_bd_intf_pins smartconnect_gp0/M03_AXI] [get_bd_intf_pins avtpg_vp0/ctrl]

  # Create port connections
  connect_bd_net -net TPG_GEN_EN_0_1  [get_bd_pins TPG_GEN_EN] \
  [get_bd_pins avtpg_vp0/TPG_GEN_EN] \
  [get_bd_pins avtpg_vp1/TPG_GEN_EN] \
  [get_bd_pins ilslice_8/Din]
  connect_bd_net -net aud_mrst_1  [get_bd_pins aud_mrst] \
  [get_bd_pins avtpg_vp0/aud_mrst]
  connect_bd_net -net av_axi_aclk_1  [get_bd_pins s_axi_aclk] \
  [get_bd_pins smartconnect_gp0/aclk]
  connect_bd_net -net avtpg_vp0_dout  [get_bd_pins avtpg_vp0/dout] \
  [get_bd_pins dout]
  connect_bd_net -net avtpg_vp0_dout1  [get_bd_pins avtpg_vp0/dout1] \
  [get_bd_pins dout1]
  connect_bd_net -net avtpg_vp0_ext_sdp00_data_o  [get_bd_pins avtpg_vp0/ext_sdp00_data_o] \
  [get_bd_pins ext_sdp00_data_o]
  connect_bd_net -net avtpg_vp0_ext_sdp00_req_o  [get_bd_pins avtpg_vp0/ext_sdp00_req_o] \
  [get_bd_pins ext_sdp00_req_o]
  connect_bd_net -net avtpg_vp0_ext_sdp01_data_o  [get_bd_pins avtpg_vp0/ext_sdp01_data_o] \
  [get_bd_pins ext_sdp01_data_o]
  connect_bd_net -net avtpg_vp0_ext_sdp01_req_o  [get_bd_pins avtpg_vp0/ext_sdp01_req_o] \
  [get_bd_pins ext_sdp01_req_o]
  connect_bd_net -net avtpg_vp0_lrclk_out  [get_bd_pins avtpg_vp0/lrclk_out] \
  [get_bd_pins lrclk_out]
  connect_bd_net -net avtpg_vp0_sclk_out  [get_bd_pins avtpg_vp0/sclk_out] \
  [get_bd_pins sclk_out1]
  connect_bd_net -net avtpg_vp0_tx_vid_enable  [get_bd_pins avtpg_vp0/tx_vid_enable] \
  [get_bd_pins tx_vid_enable]
  connect_bd_net -net avtpg_vp0_tx_vid_hsync  [get_bd_pins avtpg_vp0/tx_vid_hsync] \
  [get_bd_pins tx_vid_hsync]
  connect_bd_net -net avtpg_vp0_tx_vid_vsync  [get_bd_pins avtpg_vp0/tx_vid_vsync] \
  [get_bd_pins tx_vid_vsync]
  connect_bd_net -net avtpg_vp0_vid_out_axi4s_tvalid  [get_bd_pins avtpg_vp0/vid_out_axi4s_tvalid] \
  [get_bd_pins avtpg_vp1/Op1]
  connect_bd_net -net avtpg_vp1_tx_vid_enable  [get_bd_pins avtpg_vp1/tx_vid_enable] \
  [get_bd_pins tx_vid_enable1]
  connect_bd_net -net avtpg_vp1_tx_vid_hsync  [get_bd_pins avtpg_vp1/tx_vid_hsync] \
  [get_bd_pins tx_vid_hsync1]
  connect_bd_net -net avtpg_vp1_tx_vid_pixel  [get_bd_pins avtpg_vp1/tx_vid_pixel] \
  [get_bd_pins tx_vid_pixel]
  connect_bd_net -net avtpg_vp1_tx_vid_vsync  [get_bd_pins avtpg_vp1/tx_vid_vsync] \
  [get_bd_pins tx_vid_vsync1]
  connect_bd_net -net bufg_mux_0_O  [get_bd_pins vid_clk1] \
  [get_bd_pins avtpg_vp0/vid_clk] \
  [get_bd_pins avtpg_vp1/vid_clk] \
  [get_bd_pins smartconnect_gp0/aclk1]
  connect_bd_net -net clk_wiz_cfg_clk  [get_bd_pins av_axi_aclk] \
  [get_bd_pins avtpg_vp0/av_axi_aclk] \
  [get_bd_pins avtpg_vp1/av_axi_aclk]
  connect_bd_net -net clk_wiz_i2s_clk  [get_bd_pins i2s_clk] \
  [get_bd_pins avtpg_vp0/i2s_clk] \
  [get_bd_pins avtpg_vp1/i2s_clk]
  connect_bd_net -net ext_sdp00_ack_i_1  [get_bd_pins ext_sdp00_ack_i] \
  [get_bd_pins avtpg_vp0/ext_sdp00_ack_i]
  connect_bd_net -net ext_sdp00_horizontal_blanking_i_1  [get_bd_pins ext_sdp00_horizontal_blanking_i] \
  [get_bd_pins avtpg_vp0/ext_sdp00_horizontal_blanking_i]
  connect_bd_net -net ext_sdp00_line_cnt_mat_i_1  [get_bd_pins ext_sdp00_line_cnt_mat_i] \
  [get_bd_pins avtpg_vp0/ext_sdp00_line_cnt_mat_i]
  connect_bd_net -net ext_sdp00_vertical_blanking_i_1  [get_bd_pins ext_sdp00_vertical_blanking_i] \
  [get_bd_pins avtpg_vp0/ext_sdp00_vertical_blanking_i]
  connect_bd_net -net ext_sdp01_ack_i_1  [get_bd_pins ext_sdp01_ack_i] \
  [get_bd_pins avtpg_vp0/ext_sdp01_ack_i]
  connect_bd_net -net ext_sdp01_horizontal_blanking_i_1  [get_bd_pins ext_sdp01_horizontal_blanking_i] \
  [get_bd_pins avtpg_vp0/ext_sdp01_horizontal_blanking_i]
  connect_bd_net -net ext_sdp01_line_cnt_mat_i_1  [get_bd_pins ext_sdp01_line_cnt_mat_i] \
  [get_bd_pins avtpg_vp0/ext_sdp01_line_cnt_mat_i]
  connect_bd_net -net ext_sdp01_vertical_blanking_i_1  [get_bd_pins ext_sdp01_vertical_blanking_i] \
  [get_bd_pins avtpg_vp0/ext_sdp01_vertical_blanking_i]
  connect_bd_net -net ilslice_8_Dout  [get_bd_pins ilslice_8/Dout] \
  [get_bd_pins avtpg_vp0/clken]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins s_axis_aud_aresetn] \
  [get_bd_pins avtpg_vp0/s_axis_aud_aresetn] \
  [get_bd_pins avtpg_vp1/s_axis_aud_aresetn]
  connect_bd_net -net rst_proc_vid_clk_peripheral_aresetn  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins avtpg_vp0/vid_out_axi4s_aresetn] \
  [get_bd_pins avtpg_vp1/vid_out_axi4s_aresetn]
  connect_bd_net -net rst_processor_150MHz_interconnect_aresetn  [get_bd_pins s_axi_aresetn] \
  [get_bd_pins smartconnect_gp0/aresetn]
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

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_lite


  # Create pins
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
  create_bd_pin -dir I -from 3 -to 0 sdata
  create_bd_pin -dir I vid_active_video1
  create_bd_pin -dir I vid_hsync1
  create_bd_pin -dir I -type rst vid_reset
  create_bd_pin -dir I vid_vsync1
  create_bd_pin -dir I -from 71 -to 0 Din
  create_bd_pin -dir I -type clk ps_cfg_clk
  create_bd_pin -dir I -type rst peripheral_aresetn3
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I lrclk_in
  create_bd_pin -dir I sclk_in

  # Create instance: pl_audio_out
  create_hier_cell_pl_audio_out $hier_obj pl_audio_out

  # Create instance: pl_video_s0p0
  create_hier_cell_pl_video_s0p0 $hier_obj pl_video_s0p0

  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {4} \
  ] $ilconstant_0


  # Create instance: ilslice_0, and set properties
  set ilslice_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {11} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $ilslice_0


  # Create instance: ilslice_1, and set properties
  set ilslice_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {23} \
    CONFIG.DIN_TO {12} \
    CONFIG.DIN_WIDTH {72} \
  ] $ilslice_1


  # Create instance: ilconcat_2, and set properties
  set ilconcat_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {4} \
    CONFIG.IN1_WIDTH {12} \
    CONFIG.IN2_WIDTH {4} \
    CONFIG.IN3_WIDTH {12} \
    CONFIG.IN4_WIDTH {4} \
    CONFIG.IN5_WIDTH {12} \
    CONFIG.NUM_PORTS {6} \
  ] $ilconcat_2


  # Create instance: ilconcat_1, and set properties
  set ilconcat_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {4} \
    CONFIG.IN1_WIDTH {12} \
    CONFIG.IN2_WIDTH {4} \
    CONFIG.IN3_WIDTH {12} \
    CONFIG.IN4_WIDTH {4} \
    CONFIG.IN5_WIDTH {12} \
    CONFIG.NUM_PORTS {6} \
  ] $ilconcat_1


  # Create instance: ilslice_7, and set properties
  set ilslice_7 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_7 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {59} \
    CONFIG.DIN_TO {48} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $ilslice_7


  # Create instance: ilslice_8, and set properties
  set ilslice_8 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_8 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {71} \
    CONFIG.DIN_TO {60} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $ilslice_8


  # Create instance: ilslice_5, and set properties
  set ilslice_5 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_5 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {35} \
    CONFIG.DIN_TO {24} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $ilslice_5


  # Create instance: ilslice_6, and set properties
  set ilslice_6 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_6 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {47} \
    CONFIG.DIN_TO {36} \
    CONFIG.DIN_WIDTH {72} \
    CONFIG.DOUT_WIDTH {12} \
  ] $ilslice_6


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins pl_video_s0p0/S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins m_axi_s2mm] [get_bd_intf_pins pl_audio_out/m_axi_s2mm]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins pl_video_s0p0/m_axi_mm_video_0] [get_bd_intf_pins m_axi_mm_video_0]
  connect_bd_intf_net -intf_net s_axi_lite_1 [get_bd_intf_pins s_axi_lite] [get_bd_intf_pins pl_audio_out/s_axi_lite]
  connect_bd_intf_net -intf_net smartconnect_gp0_M22_AXI [get_bd_intf_pins s_axi_CTRL1] [get_bd_intf_pins pl_video_s0p0/s_axi_CTRL]
  connect_bd_intf_net -intf_net smartconnect_gp0_M23_AXI [get_bd_intf_pins s_axi_ctrl] [get_bd_intf_pins pl_audio_out/s_axi_ctrl]

  # Create port connections
  connect_bd_net -net Din_1  [get_bd_pins Din] \
  [get_bd_pins ilslice_0/Din] \
  [get_bd_pins ilslice_1/Din] \
  [get_bd_pins ilslice_5/Din] \
  [get_bd_pins ilslice_7/Din] \
  [get_bd_pins ilslice_8/Din] \
  [get_bd_pins ilslice_6/Din]
  connect_bd_net -net Video_out8_interrupt  [get_bd_pins pl_video_s0p0/interrupt] \
  [get_bd_pins interrupt]
  connect_bd_net -net ap_rst_n_1  [get_bd_pins ap_rst_n] \
  [get_bd_pins pl_video_s0p0/ap_rst_n]
  connect_bd_net -net bufg_mux_i2sclk_O  [get_bd_pins aud_mclk] \
  [get_bd_pins pl_audio_out/aud_mclk]
  connect_bd_net -net clk_wiz_pl_vid_1x_clk  [get_bd_pins aclk] \
  [get_bd_pins pl_video_s0p0/aclk]
  connect_bd_net -net ilconcat_1_dout  [get_bd_pins ilconcat_1/dout] \
  [get_bd_pins pl_video_s0p0/vid_pixel0_0]
  connect_bd_net -net ilconcat_2_dout  [get_bd_pins ilconcat_2/dout] \
  [get_bd_pins pl_video_s0p0/vid_pixel1_0]
  connect_bd_net -net ilconstant_0_dout  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins ilconcat_2/In0] \
  [get_bd_pins ilconcat_2/In2] \
  [get_bd_pins ilconcat_2/In4] \
  [get_bd_pins ilconcat_1/In0] \
  [get_bd_pins ilconcat_1/In2] \
  [get_bd_pins ilconcat_1/In4]
  connect_bd_net -net ilslice_0_Dout  [get_bd_pins dp_hres] \
  [get_bd_pins pl_video_s0p0/dp_hres]
  connect_bd_net -net ilslice_0_Dout1  [get_bd_pins ilslice_0/Dout] \
  [get_bd_pins ilconcat_1/In1]
  connect_bd_net -net ilslice_1_Dout  [get_bd_pins pixel_mode] \
  [get_bd_pins pl_video_s0p0/pixel_mode]
  connect_bd_net -net ilslice_1_Dout1  [get_bd_pins ilslice_1/Dout] \
  [get_bd_pins ilconcat_1/In3]
  connect_bd_net -net ilslice_2_Dout  [get_bd_pins bpc] \
  [get_bd_pins pl_video_s0p0/bpc]
  connect_bd_net -net ilslice_3_Dout  [get_bd_pins color_format] \
  [get_bd_pins pl_video_s0p0/color_format]
  connect_bd_net -net ilslice_5_Dout  [get_bd_pins ilslice_5/Dout] \
  [get_bd_pins ilconcat_1/In5]
  connect_bd_net -net ilslice_6_Dout  [get_bd_pins ilslice_6/Dout] \
  [get_bd_pins ilconcat_2/In1]
  connect_bd_net -net ilslice_7_Dout  [get_bd_pins ilslice_7/Dout] \
  [get_bd_pins ilconcat_2/In3]
  connect_bd_net -net ilslice_8_Dout  [get_bd_pins ilslice_8/Dout] \
  [get_bd_pins ilconcat_2/In5]
  connect_bd_net -net lrclk_in_1  [get_bd_pins lrclk_in] \
  [get_bd_pins pl_audio_out/lrclk_in]
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
  connect_bd_net -net sclk_in_1  [get_bd_pins sclk_in] \
  [get_bd_pins pl_audio_out/sclk_in]
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
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_reset1
  create_bd_pin -dir I -type clk slowest_sync_clk4
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn4

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


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create port connections
  connect_bd_net -net PS_0_pl0_resetn  [get_bd_pins ext_reset_in] \
  [get_bd_pins rst_proc_cfg_clk/ext_reset_in] \
  [get_bd_pins rst_proc_i2s_clk/ext_reset_in] \
  [get_bd_pins rst_proc_pl_pixel_clk/ext_reset_in] \
  [get_bd_pins rst_proc_vid_clk/ext_reset_in] \
  [get_bd_pins proc_sys_reset_0/aux_reset_in] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in]
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
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn4]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins rst_proc_i2s_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn2]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins rst_proc_i2s_clk/peripheral_reset] \
  [get_bd_pins peripheral_reset]
  connect_bd_net -net rst_proc_cfg_clk1_peripheral_aresetn  [get_bd_pins rst_proc_pl_pixel_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn1]
  connect_bd_net -net rst_proc_vid_clk_peripheral_aresetn  [get_bd_pins rst_proc_vid_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn]
  connect_bd_net -net rst_proc_vid_clk_peripheral_reset  [get_bd_pins rst_proc_vid_clk/peripheral_reset] \
  [get_bd_pins peripheral_reset1]
  connect_bd_net -net rst_processor_150MHz_interconnect_aresetn  [get_bd_pins rst_proc_cfg_clk/interconnect_aresetn] \
  [get_bd_pins interconnect_aresetn]
  connect_bd_net -net rst_processor_150MHz_peripheral_aresetn  [get_bd_pins rst_proc_cfg_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn3]
  connect_bd_net -net slowest_sync_clk3_1  [get_bd_pins slowest_sync_clk3] \
  [get_bd_pins rst_proc_cfg_clk/slowest_sync_clk]
  connect_bd_net -net slowest_sync_clk4_1  [get_bd_pins slowest_sync_clk4] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

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
  set C0_LPDDR5X [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C0_LPDDR5X ]

  set C1_LPDDR5X [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 C1_LPDDR5X ]

  set C0_C1_LPDDR5X_sys_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_C1_LPDDR5X_sys_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $C0_C1_LPDDR5X_sys_clk


  # Create ports

  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.MMI_CONFIG(DC_FEEDBACK_EN) {1} \
    CONFIG.MMI_CONFIG(DC_FEEDBACK_STREAM) {Audio_&_Video} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO01) {Audio_&_Video} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO01_ALPHA_EN) {1} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO01_SDP_EN) {1} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO_SELECT) {Both} \
    CONFIG.MMI_CONFIG(DPDC_PRESENTATION_MODE) {Live} \
    CONFIG.MMI_CONFIG(MMI_DP_HPD) {PMC_MIO_48} \
    CONFIG.MMI_CONFIG(MMI_GPU_ENABLE) {1} \
    CONFIG.MMI_CONFIG(PL_MMI_INTERRUPTS_EN) {1} \
    CONFIG.MMI_CONFIG(UDH_GT) {DP_X4} \
    CONFIG.PS11_CONFIG(MMI_DP_HPD) {PMC_MIO_48} \
    CONFIG.PS11_CONFIG(MMI_GPU_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PL_MMI_INTERRUPTS_EN) {1} \
    CONFIG.PS11_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {100} \
    CONFIG.PS11_CONFIG(PMC_MIO13) {DRIVE_STRENGTH 12mA SLEW fast PULL pullup SCHMITT 1 AUX_IO 0 USAGE Reserved OUTPUT_DATA default DIRECTION inout} \
    CONFIG.PS11_CONFIG(PMC_OSPI_ECC_FAIL_IO) {PMC_MIO_26} \
    CONFIG.PS11_CONFIG(PMC_OSPI_PERIPHERAL) {ENABLE 1 IO PMC_MIO_0:13 MODE Single} \
    CONFIG.PS11_CONFIG(PMC_SDIO_30AD) {CD_ENABLE 0 POW_ENABLE 1 WP_ENABLE 0 RESET_ENABLE 0 CD_IO PMC_MIO_24 POW_IO PMC_MIO_17 WP_IO PMC_MIO_25 RESET_IO PMC_MIO_17 CLK_50_SDR_ITAP_DLY 0x25 CLK_50_SDR_OTAP_DLY\
0x4 CLK_50_DDR_ITAP_DLY 0x2A CLK_50_DDR_OTAP_DLY 0x3 CLK_100_SDR_OTAP_DLY 0x3 CLK_200_SDR_OTAP_DLY 0x2} \
    CONFIG.PS11_CONFIG(PMC_SDIO_30AD_PERIPHERAL) {ENABLE 1 IO PMC_MIO_13:25 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PMC_UFS_PERIPHERAL) {ENABLE 1 IO PMC_MIO_24:26 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
    CONFIG.PS11_CONFIG(PS_ASU_ENABLE) {0} \
    CONFIG.PS11_CONFIG(PS_CAN0_PERIPHERAL) {ENABLE 1 IO PS_MIO_18:19 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_CAN1_PERIPHERAL) {ENABLE 1 IO PS_MIO_20:21 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_CAN2_PERIPHERAL) {ENABLE 1 IO PMC_MIO_20:21 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_CAN3_PERIPHERAL) {ENABLE 1 IO PS_MIO_12:13 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_ENET0_MDIO) {ENABLE 1 IO PMC_MIO_50:51 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_ENET0_PERIPHERAL) {ENABLE 1 IO PS_MIO_0:11 IO_TYPE MIO MODE RGMII} \
    CONFIG.PS11_CONFIG(PS_FPD_AXI_PL_DATA_WIDTH) {64} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI0_MASTER) {A78_0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI1_MASTER) {R52_0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI1_NOBUF_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI2_MASTER) {R52_1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI2_NOBUF_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI3_MASTER) {R52_2} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI3_NOBUF_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI4_MASTER) {R52_3} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI4_NOBUF_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI5_MASTER) {A78_0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI5_NOBUF_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI6_MASTER) {A78_0} \
    CONFIG.PS11_CONFIG(PS_GEN_IPI6_NOBUF_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_I3C_I2C0_PERIPHERAL) {ENABLE 1 IO PMC_MIO_42:43 IO_TYPE MIO TYPE I2C} \
    CONFIG.PS11_CONFIG(PS_I3C_I2C1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_44:45 IO_TYPE MIO TYPE I2C} \
    CONFIG.PS11_CONFIG(PS_MIO22) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PS11_CONFIG(PS_MIO23) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PS11_CONFIG(PS_MIO25) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION in} \
    CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
    CONFIG.PS11_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC1_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC2_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC3_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC4_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC5_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC6_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_TTC7_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_46:47 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_USB1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_27:39 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_NOC) {1} \
    CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_NOC8) {1} \
    CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_PL) {1} \
    CONFIG.PS11_CONFIG(PS_USE_LPD_AXI_NOC) {1} \
    CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} \
    CONFIG.PS11_CONFIG(UDH_GT) {DP_X4} \
  ] $ps_wizard_0


  # Create instance: axi_noc2_m, and set properties
  set axi_noc2_m [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_m ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {12} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {14} \
    CONFIG.NUM_NSI {2} \
    CONFIG.NUM_SI {12} \
  ] $axi_noc2_m


  set_property -dict [ list \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_m/S00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M12_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_m/S00_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_m/S01_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M13_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_m/S01_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M02_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_m/S02_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M03_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_m/S03_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M04_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_m/S04_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M05_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_m/S05_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M06_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_m/S06_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M07_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc2_m/S07_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M08_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc2_m/S08_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M09_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc2_m/S09_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M10_INI {read_bw {500} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_isoc} \
 ] [get_bd_intf_pins /axi_noc2_m/S10_AXI]

  set_property -dict [ list \
   CONFIG.R_TRAFFIC_CLASS {ISOCHRONOUS} \
   CONFIG.CONNECTIONS {M11_INI {read_bw {8000} write_bw {500} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_mmi} \
 ] [get_bd_intf_pins /axi_noc2_m/S11_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S08_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S09_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk9]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S10_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk10]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S11_AXI} \
 ] [get_bd_pins /axi_noc2_m/aclk11]

  # Create instance: axi_noc2_s0, and set properties
  set axi_noc2_s0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_s0 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG {DDRMC5_CONTROLLERTYPE LPDDR5_SDRAM DDRMC5_SPEED_GRADE LPDDR5X-8533 DDRMC5_DEVICE_TYPE Components DDRMC5_F0_LP5_BANK_ARCH BG DDRMC5_F1_LP5_BANK_ARCH BG DDRMC5_DRAM_WIDTH x16 DDRMC5_DATA_WIDTH\
32 DDRMC5_ROW_ADDR_WIDTH 15 DDRMC5_COL_ADDR_WIDTH 6 DDRMC5_BA_ADDR_WIDTH 2 DDRMC5_BG_WIDTH 2 DDRMC5_BURST_ADDR_WIDTH 4 DDRMC5_NUM_RANKS 1 DDRMC5_LATENCY_MODE x16 DDRMC5_NUM_SLOTS 1 DDRMC5_NUM_CK 1 DDRMC5_NUM_CH\
1 DDRMC5_STACK_HEIGHT 1 DDRMC5_DRAM_SIZE 8Gb DDRMC5_MEMORY_DENSITY 2GB DDRMC5_DM_EN true DDRMC5_DQS_OSCI_EN DISABLE DDRMC5_SIDE_BAND_ECC false DDRMC5_INLINE_ECC false DDRMC5_DDR5_2T DISABLE DDRMC5_DDR5_RDIMM_ADDR_MODE\
DDR DDRMC5_REFRESH_MODE NORMAL DDRMC5_REFRESH_TYPE ALL_BANK DDRMC5_FREQ_SWITCHING false DDRMC5_BACKGROUND_SCRUB false DDRMC5_OTF_SCRUB false DDRMC5_SCRUB_SIZE 1 DDRMC5_MEM_FILL false DDRMC5_PERIODIC_READ\
ENABLE DDRMC5_USER_REFRESH false DDRMC5_WL_SET A DDRMC5_WR_DBI true DDRMC5_RD_DBI true DDRMC5_AUTO_PRECHARGE true DDRMC5_CRYPTO false DDRMC5_ON_DIE_ECC false DDRMC5_DDR5_PAR_RCD_EN false DDRMC5_OP_TEMPERATURE\
LOW DDRMC5_F0_TCK 938 DDRMC5_INPUTCLK0_PERIOD 3127 DDRMC5_F0_TFAW 15000 DDRMC5_F0_DDR5_TRP 18000 DDRMC5_F0_TRTP 7500 DDRMC5_F0_TRTP_RU 24 DDRMC5_F1_TRTP_RU 24 DDRMC5_F0_TRCD 18000 DDRMC5_TREFI 3906000\
DDRMC5_DDR5_TRFC1 0 DDRMC5_DDR5_TRFC2 0 DDRMC5_DDR5_TRFCSB 0 DDRMC5_F0_TRAS 42000 DDRMC5_F0_TZQLAT 30000 DDRMC5_F0_DDR5_TCCD_L_WR 0 DDRMC5_F0_DDR5_TCCD_L_WR_RU 32 DDRMC5_F0_TXP 7000 DDRMC5_F0_DDR5_TPD\
0 DDRMC5_DDR5_TREFSBRD 0 DDRMC5_DDR5_TRFC1_DLR 0 DDRMC5_DDR5_TRFC1_DPR 0 DDRMC5_DDR5_TRFC2_DLR 0 DDRMC5_DDR5_TRFC2_DPR 0 DDRMC5_DDR5_TRFCSB_DLR 0 DDRMC5_DDR5_TREFSBRD_SLR 0 DDRMC5_DDR5_TREFSBRD_DLR 0 DDRMC5_F0_CL\
46 DDRMC5_F0_CWL 0 DDRMC5_F0_DDR5_TRRD_L 0 DDRMC5_F0_TCCD_L 4 DDRMC5_F0_DDR5_TCCD_L_WR2 0 DDRMC5_F0_DDR5_TCCD_L_WR2_RU 16 DDRMC5_DDR5_TFAW_DLR 0 DDRMC5_F1_TCK 938 DDRMC5_F1_TFAW 15000 DDRMC5_F1_DDR5_TRP\
18000 DDRMC5_F1_TRTP 7500 DDRMC5_F1_TRCD 18000 DDRMC5_F1_TRAS 42000 DDRMC5_F1_TZQLAT 30000 DDRMC5_F1_DDR5_TCCD_L_WR 0 DDRMC5_F1_DDR5_TCCD_L_WR_RU 32 DDRMC5_F1_TXP 7000 DDRMC5_F1_DDR5_TPD 0 DDRMC5_F1_CL\
46 DDRMC5_F1_CWL 0 DDRMC5_F1_DDR5_TRRD_L 0 DDRMC5_F1_TCCD_L 4 DDRMC5_F1_DDR5_TCCD_L_WR2 0 DDRMC5_F1_DDR5_TCCD_L_WR2_RU 16 DDRMC5_LP5_TRFCAB 210000 DDRMC5_LP5_TRFCPB 120000 DDRMC5_LP5_TPBR2PBR 90000 DDRMC5_F0_LP5_TRPAB\
21000 DDRMC5_F0_LP5_TRPPB 18000 DDRMC5_F0_LP5_TRRD 3750 DDRMC5_LP5_TPBR2ACT 7500 DDRMC5_F0_LP5_TCSPD 10938 DDRMC5_F0_RL 25 DDRMC5_F0_WL 12 DDRMC5_F1_LP5_TRPAB 21000 DDRMC5_F1_LP5_TRPPB 18000 DDRMC5_F1_LP5_TRRD\
3750 DDRMC5_F1_LP5_TCSPD 10938 DDRMC5_F1_RL 25 DDRMC5_F1_WL 12 DDRMC5_LP5_TRFMAB 210000 DDRMC5_LP5_TRFMPB 170000 DDRMC5_SYSTEM_CLOCK No_Buffer DDRMC5_UBLAZE_BLI_INTF false DDRMC5_REF_AND_PER_CAL_INTF false\
DDRMC5_PRE_DEF_ADDR_MAP_SEL ROW_BANK_COLUMN DDRMC5_USER_DEFINED_ADDRESS_MAP None DDRMC5_ADDRESS_MAP NA,NA,NA,NA,NA,NA,NA,NA,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,NC,CA0,NC,NC,NC,NC,NA,NA\
DDRMC5_MC0_CONFIG_SEL config13 DDRMC5_MC1_CONFIG_SEL config12_opt DDRMC5_MC2_CONFIG_SEL config13_opt DDRMC5_MC3_CONFIG_SEL config13_opt DDRMC5_MC4_CONFIG_SEL config13_opt DDRMC5_MC5_CONFIG_SEL config13_opt\
DDRMC5_MC6_CONFIG_SEL config13_opt DDRMC5_MC7_CONFIG_SEL config13_opt DDRMC5_LOW_TRFC_DPR false DDRMC5_NUM_MC 2 DDRMC5_NUM_MCP 1 DDRMC5_MAIN_DEVICE_TYPE Components DDRMC5_INTERLEAVE_SIZE 128 DDRMC5_SILICON_REVISION\
NA DDRMC5_FPGA_DEVICE_TYPE NON_KSB DDRMC5_SELF_REFRESH DISABLE DDRMC5_LBDQ_SWAP false DDRMC5_CAL_MASK_POLL ENABLE DDRMC5_BOARD_INTRF_EN false} \
    CONFIG.DDRMC5_INTERLEAVE_SIZE {128} \
    CONFIG.DDRMC5_NUM_CH {1} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH0_LEGACY} \
    CONFIG.MC_CHAN_REGION1 {DDR_CH0_MED} \
    CONFIG.NUM_CLKS {0} \
    CONFIG.NUM_MC {2} \
    CONFIG.NUM_MCP {2} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {0} \
    CONFIG.NUM_NSI {14} \
    CONFIG.NUM_SI {0} \
  ] $axi_noc2_s0


  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S00_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S01_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S02_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S03_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S04_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S05_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S06_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S07_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S08_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S09_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S10_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S11_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S12_INI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
 ] [get_bd_intf_pins /axi_noc2_s0/S13_INI]

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_0 ]

  # Create instance: axi_noc2_dc_fb_ss, and set properties
  set axi_noc2_dc_fb_ss [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 axi_noc2_dc_fb_ss ]
  set_property -dict [list \
    CONFIG.MI_SIDEBAND_PINS {} \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {2} \
    CONFIG.NUM_NSI {0} \
    CONFIG.NUM_SI {2} \
    CONFIG.SI_SIDEBAND_PINS {} \
  ] $axi_noc2_dc_fb_ss


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {  M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_dc_fb_ss/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.CONNECTIONS {  M01_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc2_dc_fb_ss/S01_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc2_dc_fb_ss/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc2_dc_fb_ss/aclk1]

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {3} \
    CONFIG.NUM_MI {11} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: clkx5_wiz_0, and set properties
  set clkx5_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clkx5_wiz_0 ]
  set_property -dict [list \
    CONFIG.CE_SYNC_EXT {true} \
    CONFIG.CLKOUT_DRIVES {MBUFGCE,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {pl_vid_2x_clk,pl_vid_2x_clk,ps_cfg_clk,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {600.000,600.000,230.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.ENABLE_CLOCK_MONITOR {true} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.PRIMITIVE_TYPE {DPLL} \
    CONFIG.USE_DYN_RECONFIG {true} \
  ] $clkx5_wiz_0


  # Create instance: ilslice_0, and set properties
  set ilslice_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {29} \
    CONFIG.DIN_TO {29} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $ilslice_0


  # Create instance: ilslice_1, and set properties
  set ilslice_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {31} \
    CONFIG.DIN_TO {31} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $ilslice_1


  # Create instance: ilslice_2, and set properties
  set ilslice_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {30} \
    CONFIG.DIN_TO {30} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {1} \
  ] $ilslice_2


  # Create instance: clkx5_wiz_1, and set properties
  set clkx5_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clkx5_wiz_1 ]
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
    CONFIG.ENABLE_CLOCK_MONITOR {true} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.PRIMITIVE_TYPE {MMCM} \
    CONFIG.USE_DYN_RECONFIG {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
  ] $clkx5_wiz_1


  # Create instance: ilconcat_1, and set properties
  set ilconcat_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {4} \
    CONFIG.IN1_WIDTH {4} \
    CONFIG.IN2_WIDTH {4} \
    CONFIG.NUM_PORTS {3} \
  ] $ilconcat_1


  # Create instance: ilconcat_2, and set properties
  set ilconcat_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {4} \
    CONFIG.IN1_WIDTH {4} \
    CONFIG.IN2_WIDTH {4} \
    CONFIG.NUM_PORTS {3} \
  ] $ilconcat_2


  # Create instance: rd_clk_wiz_status_gpio, and set properties
  set rd_clk_wiz_status_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio rd_clk_wiz_status_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {12} \
    CONFIG.C_GPIO_WIDTH {12} \
    CONFIG.C_IS_DUAL {1} \
  ] $rd_clk_wiz_status_gpio


  # Create instance: FB_Video_config_gpio, and set properties
  set FB_Video_config_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio FB_Video_config_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00190280} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {0} \
  ] $FB_Video_config_gpio


  # Create instance: ilslice_3, and set properties
  set ilslice_3 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_3 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {24} \
    CONFIG.DIN_TO {22} \
    CONFIG.DOUT_WIDTH {3} \
  ] $ilslice_3


  # Create instance: Live_input_gpio, and set properties
  set Live_input_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio Live_input_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {0} \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00000000} \
    CONFIG.C_GPIO_WIDTH {32} \
    CONFIG.C_IS_DUAL {0} \
  ] $Live_input_gpio


  # Create instance: ilslice_5, and set properties
  set ilslice_5 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_5 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {21} \
    CONFIG.DIN_TO {19} \
    CONFIG.DOUT_WIDTH {3} \
  ] $ilslice_5


  # Create instance: ilslice_6, and set properties
  set ilslice_6 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_6 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {15} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {32} \
    CONFIG.DOUT_WIDTH {16} \
  ] $ilslice_6


  # Create instance: ilslice_7, and set properties
  set ilslice_7 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_7 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {18} \
    CONFIG.DIN_TO {16} \
    CONFIG.DOUT_WIDTH {3} \
  ] $ilslice_7


  # Create instance: rst_module
  create_hier_cell_rst_module [current_bd_instance .] rst_module

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


  # Create instance: dc_pl_out_pipeline
  create_hier_cell_dc_pl_out_pipeline [current_bd_instance .] dc_pl_out_pipeline

  # Create instance: dc_input_pipeline
  create_hier_cell_dc_input_pipeline [current_bd_instance .] dc_input_pipeline

  # Create interface connections
  connect_bd_intf_net -intf_net C0_C1_LPDDR5X_sys_clk_1 [get_bd_intf_ports C0_C1_LPDDR5X_sys_clk] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net axi_noc2_0_M00_INI [get_bd_intf_pins axi_noc2_m/M00_INI] [get_bd_intf_pins axi_noc2_s0/S00_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M01_INI [get_bd_intf_pins axi_noc2_m/M01_INI] [get_bd_intf_pins axi_noc2_s0/S01_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M02_INI [get_bd_intf_pins axi_noc2_m/M02_INI] [get_bd_intf_pins axi_noc2_s0/S02_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M03_INI [get_bd_intf_pins axi_noc2_m/M03_INI] [get_bd_intf_pins axi_noc2_s0/S03_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M04_INI [get_bd_intf_pins axi_noc2_m/M04_INI] [get_bd_intf_pins axi_noc2_s0/S04_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M05_INI [get_bd_intf_pins axi_noc2_m/M05_INI] [get_bd_intf_pins axi_noc2_s0/S05_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M06_INI [get_bd_intf_pins axi_noc2_m/M06_INI] [get_bd_intf_pins axi_noc2_s0/S06_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M07_INI [get_bd_intf_pins axi_noc2_m/M07_INI] [get_bd_intf_pins axi_noc2_s0/S07_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M08_INI [get_bd_intf_pins axi_noc2_m/M08_INI] [get_bd_intf_pins axi_noc2_s0/S08_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M09_INI [get_bd_intf_pins axi_noc2_m/M09_INI] [get_bd_intf_pins axi_noc2_s0/S09_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M10_INI [get_bd_intf_pins axi_noc2_m/M10_INI] [get_bd_intf_pins axi_noc2_s0/S10_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M11_INI [get_bd_intf_pins axi_noc2_m/M11_INI] [get_bd_intf_pins axi_noc2_s0/S11_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M12_INI [get_bd_intf_pins axi_noc2_m/M12_INI] [get_bd_intf_pins axi_noc2_s0/S12_INI]
  connect_bd_intf_net -intf_net axi_noc2_0_M13_INI [get_bd_intf_pins axi_noc2_m/M13_INI] [get_bd_intf_pins axi_noc2_s0/S13_INI]
  connect_bd_intf_net -intf_net axi_noc2_dc_fb_ss_M00_INI [get_bd_intf_pins axi_noc2_dc_fb_ss/M00_INI] [get_bd_intf_pins axi_noc2_m/S00_INI]
  connect_bd_intf_net -intf_net axi_noc2_dc_fb_ss_M01_INI [get_bd_intf_pins axi_noc2_dc_fb_ss/M01_INI] [get_bd_intf_pins axi_noc2_m/S01_INI]
  connect_bd_intf_net -intf_net axi_noc2_s0_C0_CH0_LPDDR5 [get_bd_intf_ports C0_LPDDR5X] [get_bd_intf_pins axi_noc2_s0/C0_CH0_LPDDR5]
  connect_bd_intf_net -intf_net axi_noc2_s0_C1_CH0_LPDDR5 [get_bd_intf_ports C1_LPDDR5X] [get_bd_intf_pins axi_noc2_s0/C1_CH0_LPDDR5]
  connect_bd_intf_net -intf_net dc_input_pipeline_vid_intf [get_bd_intf_pins ps_wizard_0/live_video0] [get_bd_intf_pins dc_input_pipeline/vid_intf]
  connect_bd_intf_net -intf_net dc_input_pipeline_vid_intf1 [get_bd_intf_pins ps_wizard_0/live_video1] [get_bd_intf_pins dc_input_pipeline/vid_intf1]
  connect_bd_intf_net -intf_net dc_pl_out_pipeline_m_axi_mm_video_0 [get_bd_intf_pins dc_pl_out_pipeline/m_axi_mm_video_0] [get_bd_intf_pins axi_noc2_dc_fb_ss/S00_AXI]
  connect_bd_intf_net -intf_net dc_pl_out_pipeline_m_axi_s2mm [get_bd_intf_pins dc_pl_out_pipeline/m_axi_s2mm] [get_bd_intf_pins axi_noc2_dc_fb_ss/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_m/S00_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins axi_noc2_m/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC2 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC2] [get_bd_intf_pins axi_noc2_m/S02_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC3 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC3] [get_bd_intf_pins axi_noc2_m/S03_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC4 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC4] [get_bd_intf_pins axi_noc2_m/S04_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC5 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC5] [get_bd_intf_pins axi_noc2_m/S05_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC6 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC6] [get_bd_intf_pins axi_noc2_m/S06_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC7 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC7] [get_bd_intf_pins axi_noc2_m/S07_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC8 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC8] [get_bd_intf_pins axi_noc2_m/S10_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_PL [get_bd_intf_pins smartconnect_0/S00_AXI] [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL]
  connect_bd_intf_net -intf_net ps_wizard_0_LPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_m/S09_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_MMI_DC_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/MMI_DC_AXI_NOC0] [get_bd_intf_pins axi_noc2_m/S11_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_PMC_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins axi_noc2_m/S08_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins dc_pl_out_pipeline/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins dc_pl_out_pipeline/s_axi_lite]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins smartconnect_0/M02_AXI] [get_bd_intf_pins FB_Video_config_gpio/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins smartconnect_0/M03_AXI] [get_bd_intf_pins dc_pl_out_pipeline/s_axi_CTRL1]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins smartconnect_0/M04_AXI] [get_bd_intf_pins dc_pl_out_pipeline/s_axi_ctrl]
  connect_bd_intf_net -intf_net smartconnect_0_M05_AXI [get_bd_intf_pins smartconnect_0/M05_AXI] [get_bd_intf_pins dc_input_pipeline/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M06_AXI [get_bd_intf_pins smartconnect_0/M06_AXI] [get_bd_intf_pins Live_input_gpio/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M07_AXI [get_bd_intf_pins clkx5_wiz_0/s_axi_lite] [get_bd_intf_pins smartconnect_0/M07_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M08_AXI [get_bd_intf_pins clkx5_wiz_1/s_axi_lite] [get_bd_intf_pins smartconnect_0/M08_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M09_AXI [get_bd_intf_pins rd_clk_wiz_status_gpio/S_AXI] [get_bd_intf_pins smartconnect_0/M09_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M10_AXI [get_bd_intf_pins smartconnect_0/M10_AXI] [get_bd_intf_pins clk_wizard_enable/S_AXI]

  # Create port connections
  connect_bd_net -net axi_gpio_2_gpio_io_o  [get_bd_pins FB_Video_config_gpio/gpio_io_o] \
  [get_bd_pins ilslice_3/Din] \
  [get_bd_pins ilslice_6/Din] \
  [get_bd_pins ilslice_5/Din] \
  [get_bd_pins ilslice_7/Din]
  connect_bd_net -net axi_gpio_3_gpio2_io_o  [get_bd_pins Live_input_gpio/gpio_io_o] \
  [get_bd_pins dc_input_pipeline/TPG_GEN_EN] \
  [get_bd_pins ilslice_0/Din] \
  [get_bd_pins ilslice_1/Din] \
  [get_bd_pins ilslice_2/Din]
  connect_bd_net -net axi_gpio_3_gpio_io_o  [get_bd_pins clk_wizard_enable/gpio_io_o] \
  [get_bd_pins ilslice_8/Din] \
  [get_bd_pins ilslice_9/Din]
  connect_bd_net -net clkx5_wiz_0_clk_glitch  [get_bd_pins clkx5_wiz_0/clk_glitch] \
  [get_bd_pins ilconcat_1/In1]
  connect_bd_net -net clkx5_wiz_0_clk_oor  [get_bd_pins clkx5_wiz_0/clk_oor] \
  [get_bd_pins ilconcat_1/In2]
  connect_bd_net -net clkx5_wiz_0_clk_stop  [get_bd_pins clkx5_wiz_0/clk_stop] \
  [get_bd_pins ilconcat_1/In0]
  connect_bd_net -net clkx5_wiz_0_i2s_clk  [get_bd_pins clkx5_wiz_1/i2s_clk_x2] \
  [get_bd_pins axi_noc2_dc_fb_ss/aclk1] \
  [get_bd_pins rst_module/slowest_sync_clk2] \
  [get_bd_pins dc_input_pipeline/i2s_clk] \
  [get_bd_pins dc_pl_out_pipeline/aud_mclk]
  connect_bd_net -net clkx5_wiz_0_locked  [get_bd_pins clkx5_wiz_0/locked] \
  [get_bd_pins rst_module/dcm_locked]
  connect_bd_net -net clkx5_wiz_0_pl_vid_1x_clk  [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_o2] \
  [get_bd_pins dc_input_pipeline/vid_clk1] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk] \
  [get_bd_pins clk_wizard_enable/s_axi_aclk] \
  [get_bd_pins axi_noc2_dc_fb_ss/aclk0] \
  [get_bd_pins smartconnect_0/aclk1] \
  [get_bd_pins rd_clk_wiz_status_gpio/s_axi_aclk] \
  [get_bd_pins FB_Video_config_gpio/s_axi_aclk] \
  [get_bd_pins Live_input_gpio/s_axi_aclk] \
  [get_bd_pins dc_input_pipeline/av_axi_aclk] \
  [get_bd_pins dc_pl_out_pipeline/aclk] \
  [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins dc_input_pipeline/s_axi_aclk] \
  [get_bd_pins dc_pl_out_pipeline/ps_cfg_clk] \
  [get_bd_pins rst_module/slowest_sync_clk] \
  [get_bd_pins rst_module/slowest_sync_clk1] \
  [get_bd_pins rst_module/slowest_sync_clk3]
  connect_bd_net -net clkx5_wiz_0_pl_vid_2x_clk_o1  [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_o1] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk]
  connect_bd_net -net clkx5_wiz_1_clk_glitch  [get_bd_pins clkx5_wiz_1/clk_glitch] \
  [get_bd_pins ilconcat_2/In1]
  connect_bd_net -net clkx5_wiz_1_clk_oor  [get_bd_pins clkx5_wiz_1/clk_oor] \
  [get_bd_pins ilconcat_2/In2]
  connect_bd_net -net clkx5_wiz_1_clk_stop  [get_bd_pins clkx5_wiz_1/clk_stop] \
  [get_bd_pins ilconcat_2/In0]
  connect_bd_net -net clkx5_wiz_1_locked  [get_bd_pins clkx5_wiz_1/locked] \
  [get_bd_pins rst_module/dcm_locked1]
  connect_bd_net -net dc_in_out_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn] \
  [get_bd_pins rd_clk_wiz_status_gpio/s_axi_aresetn] \
  [get_bd_pins FB_Video_config_gpio/s_axi_aresetn] \
  [get_bd_pins Live_input_gpio/s_axi_aresetn] \
  [get_bd_pins dc_input_pipeline/vid_out_axi4s_aresetn] \
  [get_bd_pins dc_pl_out_pipeline/ap_rst_n] \
  [get_bd_pins clk_wizard_enable/s_axi_aresetn]
  connect_bd_net -net dc_input_pipeline_dout  [get_bd_pins dc_input_pipeline/dout] \
  [get_bd_pins ps_wizard_0/i2s_i2s0_sdata_0]
  connect_bd_net -net dc_input_pipeline_dout1  [get_bd_pins dc_input_pipeline/dout1] \
  [get_bd_pins ps_wizard_0/live_video0_data]
  connect_bd_net -net dc_input_pipeline_ext_sdp00_data_o  [get_bd_pins dc_input_pipeline/ext_sdp00_data_o] \
  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_data]
  connect_bd_net -net dc_input_pipeline_ext_sdp00_req_o  [get_bd_pins dc_input_pipeline/ext_sdp00_req_o] \
  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_req]
  connect_bd_net -net dc_input_pipeline_ext_sdp01_data_o  [get_bd_pins dc_input_pipeline/ext_sdp01_data_o] \
  [get_bd_pins ps_wizard_0/sdp_sdp01_ext_sdp_data]
  connect_bd_net -net dc_input_pipeline_ext_sdp01_req_o  [get_bd_pins dc_input_pipeline/ext_sdp01_req_o] \
  [get_bd_pins ps_wizard_0/sdp_sdp01_ext_sdp_req]
  connect_bd_net -net dc_input_pipeline_lrclk_out  [get_bd_pins dc_input_pipeline/lrclk_out] \
  [get_bd_pins ps_wizard_0/i2s_i2s0_lrclk_tx]
  connect_bd_net -net dc_input_pipeline_sclk_out1  [get_bd_pins dc_input_pipeline/sclk_out1] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_i2s_s0_clk] \
  [get_bd_pins dc_pl_out_pipeline/sclk_in]
  connect_bd_net -net dc_input_pipeline_tx_vid_enable  [get_bd_pins dc_input_pipeline/tx_vid_enable] \
  [get_bd_pins ps_wizard_0/live_video0_active_video]
  connect_bd_net -net dc_input_pipeline_tx_vid_enable1  [get_bd_pins dc_input_pipeline/tx_vid_enable1] \
  [get_bd_pins ps_wizard_0/live_video1_active_video]
  connect_bd_net -net dc_input_pipeline_tx_vid_hsync  [get_bd_pins dc_input_pipeline/tx_vid_hsync] \
  [get_bd_pins ps_wizard_0/live_video0_hsync]
  connect_bd_net -net dc_input_pipeline_tx_vid_hsync1  [get_bd_pins dc_input_pipeline/tx_vid_hsync1] \
  [get_bd_pins ps_wizard_0/live_video1_hsync]
  connect_bd_net -net dc_input_pipeline_tx_vid_pixel  [get_bd_pins dc_input_pipeline/tx_vid_pixel] \
  [get_bd_pins ps_wizard_0/live_video1_data]
  connect_bd_net -net dc_input_pipeline_tx_vid_vsync  [get_bd_pins dc_input_pipeline/tx_vid_vsync] \
  [get_bd_pins ps_wizard_0/live_video0_vsync]
  connect_bd_net -net dc_input_pipeline_tx_vid_vsync1  [get_bd_pins dc_input_pipeline/tx_vid_vsync1] \
  [get_bd_pins ps_wizard_0/live_video1_vsync]
  connect_bd_net -net dc_pl_out_pipeline_interrupt  [get_bd_pins dc_pl_out_pipeline/interrupt] \
  [get_bd_pins ps_wizard_0/pl_mmi_irq0]
  connect_bd_net -net dc_pl_out_pipeline_irq  [get_bd_pins dc_pl_out_pipeline/irq] \
  [get_bd_pins ps_wizard_0/pl_mmi_irq1]
  connect_bd_net -net ilconcat_1_dout  [get_bd_pins ilconcat_1/dout] \
  [get_bd_pins rd_clk_wiz_status_gpio/gpio_io_i]
  connect_bd_net -net ilconcat_2_dout  [get_bd_pins ilconcat_2/dout] \
  [get_bd_pins rd_clk_wiz_status_gpio/gpio2_io_i]
  connect_bd_net -net ilslice_0_Dout  [get_bd_pins ilslice_0/Dout] \
  [get_bd_pins ps_wizard_0/dp_external_vsync_event]
  connect_bd_net -net ilslice_1_Dout  [get_bd_pins ilslice_1/Dout] \
  [get_bd_pins ps_wizard_0/dp_external_custom_event1]
  connect_bd_net -net ilslice_2_Dout  [get_bd_pins ilslice_2/Dout] \
  [get_bd_pins ps_wizard_0/dp_external_custom_event2]
  connect_bd_net -net ilslice_3_Dout  [get_bd_pins ilslice_3/Dout] \
  [get_bd_pins dc_pl_out_pipeline/color_format]
  connect_bd_net -net ilslice_5_Dout  [get_bd_pins ilslice_5/Dout] \
  [get_bd_pins dc_pl_out_pipeline/bpc]
  connect_bd_net -net ilslice_6_Dout  [get_bd_pins ilslice_6/Dout] \
  [get_bd_pins dc_pl_out_pipeline/dp_hres]
  connect_bd_net -net ilslice_7_Dout  [get_bd_pins ilslice_7/Dout] \
  [get_bd_pins dc_pl_out_pipeline/pixel_mode]
  connect_bd_net -net ilslice_8_Dout  [get_bd_pins ilslice_8/Dout] \
  [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_ce]
  connect_bd_net -net ilslice_9_Dout  [get_bd_pins ilslice_9/Dout] \
  [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_clr_n]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn4] \
  [get_bd_pins clkx5_wiz_0/s_axi_aresetn] \
  [get_bd_pins clkx5_wiz_1/s_axi_aresetn]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_m/aclk0]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc1_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] \
  [get_bd_pins axi_noc2_m/aclk1]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc2_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc2_clk] \
  [get_bd_pins axi_noc2_m/aclk2]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc3_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc3_clk] \
  [get_bd_pins axi_noc2_m/aclk3]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc4_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc4_clk] \
  [get_bd_pins axi_noc2_m/aclk4]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc5_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc5_clk] \
  [get_bd_pins axi_noc2_m/aclk5]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc6_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc6_clk] \
  [get_bd_pins axi_noc2_m/aclk6]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc7_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc7_clk] \
  [get_bd_pins axi_noc2_m/aclk7]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc8_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc8_clk] \
  [get_bd_pins axi_noc2_m/aclk10]
  connect_bd_net -net ps_wizard_0_i2sfb_i2s0_lrclk_tx  [get_bd_pins ps_wizard_0/i2sfb_i2s0_lrclk_tx] \
  [get_bd_pins dc_pl_out_pipeline/lrclk_in]
  connect_bd_net -net ps_wizard_0_i2sfb_i2s0_sdata_0  [get_bd_pins ps_wizard_0/i2sfb_i2s0_sdata_0] \
  [get_bd_pins dc_pl_out_pipeline/sdata]
  connect_bd_net -net ps_wizard_0_lpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_m/aclk9]
  connect_bd_net -net ps_wizard_0_mmi_dc_axi_noc0_clk  [get_bd_pins ps_wizard_0/mmi_dc_axi_noc0_clk] \
  [get_bd_pins axi_noc2_m/aclk11]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins clkx5_wiz_0/clk_in1] \
  [get_bd_pins clkx5_wiz_0/ref_clk] \
  [get_bd_pins clkx5_wiz_0/s_axi_aclk] \
  [get_bd_pins clkx5_wiz_1/ref_clk] \
  [get_bd_pins clkx5_wiz_1/clk_in1] \
  [get_bd_pins clkx5_wiz_1/s_axi_aclk] \
  [get_bd_pins smartconnect_0/aclk2] \
  [get_bd_pins rst_module/slowest_sync_clk4]
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins rst_module/ext_reset_in]
  connect_bd_net -net ps_wizard_0_pmc_axi_noc0_clk  [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] \
  [get_bd_pins axi_noc2_m/aclk8]
  connect_bd_net -net ps_wizard_0_sdp_sdp00_ext_sdp_ack  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_ack] \
  [get_bd_pins dc_input_pipeline/ext_sdp00_ack_i]
  connect_bd_net -net ps_wizard_0_sdp_sdp00_ext_sdp_horizontal_blanking  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_horizontal_blanking] \
  [get_bd_pins dc_input_pipeline/ext_sdp00_horizontal_blanking_i]
  connect_bd_net -net ps_wizard_0_sdp_sdp00_ext_sdp_line_cnt_mat  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_line_cnt_mat] \
  [get_bd_pins dc_input_pipeline/ext_sdp00_line_cnt_mat_i]
  connect_bd_net -net ps_wizard_0_sdp_sdp00_ext_sdp_vertical_blanking  [get_bd_pins ps_wizard_0/sdp_sdp00_ext_sdp_vertical_blanking] \
  [get_bd_pins dc_input_pipeline/ext_sdp00_vertical_blanking_i]
  connect_bd_net -net ps_wizard_0_sdp_sdp01_ext_sdp_ack  [get_bd_pins ps_wizard_0/sdp_sdp01_ext_sdp_ack] \
  [get_bd_pins dc_input_pipeline/ext_sdp01_ack_i]
  connect_bd_net -net ps_wizard_0_sdp_sdp01_ext_sdp_horizontal_blanking  [get_bd_pins ps_wizard_0/sdp_sdp01_ext_sdp_horizontal_blanking] \
  [get_bd_pins dc_input_pipeline/ext_sdp01_horizontal_blanking_i]
  connect_bd_net -net ps_wizard_0_sdp_sdp01_ext_sdp_line_cnt_mat  [get_bd_pins ps_wizard_0/sdp_sdp01_ext_sdp_line_cnt_mat] \
  [get_bd_pins dc_input_pipeline/ext_sdp01_line_cnt_mat_i]
  connect_bd_net -net ps_wizard_0_sdp_sdp01_ext_sdp_vertical_blanking  [get_bd_pins ps_wizard_0/sdp_sdp01_ext_sdp_vertical_blanking] \
  [get_bd_pins dc_input_pipeline/ext_sdp01_vertical_blanking_i]
  connect_bd_net -net ps_wizard_0_videofb_s0_active_video  [get_bd_pins ps_wizard_0/videofb_s0_active_video] \
  [get_bd_pins dc_pl_out_pipeline/vid_active_video1]
  connect_bd_net -net ps_wizard_0_videofb_s0_data  [get_bd_pins ps_wizard_0/videofb_s0_data] \
  [get_bd_pins dc_pl_out_pipeline/Din]
  connect_bd_net -net ps_wizard_0_videofb_s0_hsync  [get_bd_pins ps_wizard_0/videofb_s0_hsync] \
  [get_bd_pins dc_pl_out_pipeline/vid_hsync1]
  connect_bd_net -net ps_wizard_0_videofb_s0_vsync  [get_bd_pins ps_wizard_0/videofb_s0_vsync] \
  [get_bd_pins dc_pl_out_pipeline/vid_vsync1]
  connect_bd_net -net rst_module_interconnect_aresetn  [get_bd_pins rst_module/interconnect_aresetn] \
  [get_bd_pins dc_input_pipeline/s_axi_aresetn] \
  [get_bd_pins dc_pl_out_pipeline/peripheral_aresetn3] \
  [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net rst_module_peripheral_aresetn1  [get_bd_pins rst_module/peripheral_aresetn1] \
  [get_bd_pins dc_pl_out_pipeline/s_axi_aresetn]
  connect_bd_net -net rst_module_peripheral_aresetn2  [get_bd_pins rst_module/peripheral_aresetn2] \
  [get_bd_pins dc_input_pipeline/s_axis_aud_aresetn] \
  [get_bd_pins dc_pl_out_pipeline/aresetn]
  connect_bd_net -net rst_module_peripheral_reset  [get_bd_pins rst_module/peripheral_reset] \
  [get_bd_pins dc_input_pipeline/aud_mrst] \
  [get_bd_pins dc_pl_out_pipeline/aud_mrst]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT  [get_bd_pins util_ds_buf_0/IBUF_OUT] \
  [get_bd_pins axi_noc2_s0/sys_clk0] \
  [get_bd_pins axi_noc2_s0/sys_clk1]
  connect_bd_net -net vid_reset_1  [get_bd_pins rst_module/peripheral_reset1] \
  [get_bd_pins dc_pl_out_pipeline/vid_reset]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_dc_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_dc_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05D0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_4 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0580000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/m_axi_s2mm] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/m_axi_s2mm] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/Data_m_axi_mm_video] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/Data_m_axi_mm_video] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0xB05D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs FB_Video_config_gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/audio_formatter_0/s_axi_lite/reg0]
  exclude_bd_addr_seg -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg]
  exclude_bd_addr_seg -offset 0xB0500000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg]
  exclude_bd_addr_seg -offset 0xB0580000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg]
  exclude_bd_addr_seg -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg]
  exclude_bd_addr_seg -offset 0xB0570000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_audio_out/i2s_receiver_0/s_axi_ctrl/Reg]
  exclude_bd_addr_seg -offset 0xB0020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg]
  exclude_bd_addr_seg -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0xB0590000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_pl_out_pipeline/pl_video_s0p0/v_frmbuf_wr_0/s_axi_CTRL/Reg]
  exclude_bd_addr_seg -offset 0xB04E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_LEGACYx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs axi_noc2_s0/DDR_MC_PORTS/DDR_CH0_MEDx2]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


