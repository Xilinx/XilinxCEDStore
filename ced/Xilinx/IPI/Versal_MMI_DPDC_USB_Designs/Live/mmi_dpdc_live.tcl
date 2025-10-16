
##################################################################
# DESIGN PROCs
##################################################################
set_property name clkx5_wiz_0 [get_bd_cells pl_mmi_clk_wiz]
delete_bd_objs [get_bd_nets pl_mmi_clk_wiz_clk_out1] [get_bd_nets pl_mmi_clk_wiz_clk_out2] [get_bd_nets pl_mmi_clk_wiz_clk_out3]
delete_bd_objs [get_bd_nets clkx5_wiz_0_locked]
disconnect_bd_net /ps_wizard_0_pl0_ref_clk [get_bd_pins clk_wizard_0/clk_in1]
disconnect_bd_net /ps_wizard_0_pl0_ref_clk [get_bd_pins clkx5_wiz_0/clk_in1]
# Hierarchical cell: avtpg_vp1
proc create_hier_cell_avtpg_vp1 { parentCell nameHier } {

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
  create_bd_pin -dir I -type clk slowest_sync_clk1
  create_bd_pin -dir I -type clk slowest_sync_clk2
  create_bd_pin -dir I -type clk slowest_sync_clk3
  create_bd_pin -dir I dcm_locked1
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_reset
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn1

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
  connect_bd_net -net rst_proc_i2s_clk_peripheral_aresetn  [get_bd_pins rst_proc_i2s_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn1]
  connect_bd_net -net rst_proc_i2s_clk_peripheral_reset  [get_bd_pins rst_proc_i2s_clk/peripheral_reset] \
  [get_bd_pins peripheral_reset]
  connect_bd_net -net rst_proc_vid_clk_peripheral_aresetn  [get_bd_pins rst_proc_vid_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn]
  connect_bd_net -net slowest_sync_clk3_1  [get_bd_pins slowest_sync_clk3] \
  [get_bd_pins rst_proc_cfg_clk/slowest_sync_clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


  # Create ports

  # Create instance: ps_wizard_0, and set properties
  set_property -dict [list \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO01) {Audio_&_Video} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO01_ALPHA_EN) {1} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO01_SDP_EN) {1} \
    CONFIG.MMI_CONFIG(DC_LIVE_VIDEO_SELECT) {Both} \
    CONFIG.MMI_CONFIG(DPDC_PRESENTATION_MODE) {Live} \
    CONFIG.MMI_CONFIG(PL_MMI_INTERRUPTS_EN) {1} \
    CONFIG.PS11_CONFIG(PL_MMI_INTERRUPTS_EN) {1} \
    CONFIG.PS11_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 0 IO PS_MIO_16:17 IO_TYPE MIO} \
  ] [get_bd_cells ps_wizard_0]



  # Create instance: ctrl_smc, and set properties
  set_property -dict [list \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {11} \
    CONFIG.NUM_SI {1} \
  ] [get_bd_cells ctrl_smc]

  # Create instance: clk_wizard_enable, and set properties
  set clk_wizard_enable [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio clk_wizard_enable ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00000003} \
    CONFIG.C_GPIO_WIDTH {2} \
  ] $clk_wizard_enable


  # Create instance: rst_module
  create_hier_cell_rst_module [current_bd_instance .] rst_module

  # Create instance: rd_clk_wiz_status_gpio, and set properties
  set rd_clk_wiz_status_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio rd_clk_wiz_status_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {12} \
    CONFIG.C_GPIO_WIDTH {12} \
    CONFIG.C_IS_DUAL {1} \
  ] $rd_clk_wiz_status_gpio


  # Create instance: live_input_gpio, and set properties
  set live_input_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio live_input_gpio ]
  set_property CONFIG.C_ALL_OUTPUTS {1} $live_input_gpio


  # Create instance: clkx5_wiz_0, and set properties
  set_property -dict [list \
    CONFIG.CE_SYNC_EXT {true} \
    CONFIG.CLKOUT_DRIVES {MBUFGCE,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {pl_vid_2x_clk,pl_vid_2x_clk,ps_cfg_clk,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {594.000,600.000,230.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.ENABLE_CLOCK_MONITOR {true} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.PRIMITIVE_TYPE {MMCM} \
    CONFIG.USE_DYN_RECONFIG {true} \
  ] [get_bd_cells clkx5_wiz_0]


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


  # Create instance: dc_input_pipeline
  create_hier_cell_dc_input_pipeline [current_bd_instance .] dc_input_pipeline

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


  # Create interface connections
  connect_bd_intf_net -intf_net ctrl_smc_M05_AXI [get_bd_intf_pins ctrl_smc/M05_AXI] [get_bd_intf_pins clkx5_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net ctrl_smc_M06_AXI [get_bd_intf_pins ctrl_smc/M06_AXI] [get_bd_intf_pins clk_wizard_enable/S_AXI]
  connect_bd_intf_net -intf_net ctrl_smc_M07_AXI [get_bd_intf_pins ctrl_smc/M07_AXI] [get_bd_intf_pins clkx5_wiz_1/s_axi_lite]
  connect_bd_intf_net -intf_net ctrl_smc_M08_AXI [get_bd_intf_pins ctrl_smc/M08_AXI] [get_bd_intf_pins rd_clk_wiz_status_gpio/S_AXI]
  connect_bd_intf_net -intf_net ctrl_smc_M09_AXI [get_bd_intf_pins ctrl_smc/M09_AXI] [get_bd_intf_pins live_input_gpio/S_AXI]
  connect_bd_intf_net -intf_net ctrl_smc_M10_AXI [get_bd_intf_pins ctrl_smc/M10_AXI] [get_bd_intf_pins dc_input_pipeline/S00_AXI]
  connect_bd_intf_net -intf_net dc_input_pipeline_vid_intf [get_bd_intf_pins ps_wizard_0/live_video0] [get_bd_intf_pins dc_input_pipeline/vid_intf]

  # Create port connections
  connect_bd_net -net axi_gpio_3_gpio2_io_o  [get_bd_pins live_input_gpio/gpio_io_o] \
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
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins clk_wizard_0/clk_in1]
  connect_bd_net [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] \
  [get_bd_pins ctrl_smc/aclk] \
  [get_bd_pins rst_clk/slowest_sync_clk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins axi_gpio_1/s_axi_aclk] \
  [get_bd_pins axi_gpio_2/s_axi_aclk] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk] \
  [get_bd_pins axi_uart16550_0/s_axi_aclk] \
  [get_bd_pins clkx5_wiz_0/clk_in1] \
  [get_bd_pins clkx5_wiz_0/ref_clk] \
  [get_bd_pins clkx5_wiz_1/ref_clk] \
  [get_bd_pins clkx5_wiz_1/clk_in1] \
  [get_bd_pins clkx5_wiz_1/s_axi_aclk] \
  [get_bd_pins clkx5_wiz_0/s_axi_aclk]
  connect_bd_net -net clkx5_wiz_0_clk_stop  [get_bd_pins clkx5_wiz_0/clk_stop] \
  [get_bd_pins ilconcat_1/In0]
  connect_bd_net -net clkx5_wiz_0_i2s_clk  [get_bd_pins clkx5_wiz_1/i2s_clk_x2] \
  [get_bd_pins rst_module/slowest_sync_clk2] \
  [get_bd_pins dc_input_pipeline/i2s_clk]
  connect_bd_net -net clkx5_wiz_0_locked  [get_bd_pins clkx5_wiz_0/locked] \
  [get_bd_pins rst_module/dcm_locked]
  connect_bd_net [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_o1] [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk]
  connect_bd_net -net clkx5_wiz_1_clk_glitch  [get_bd_pins clkx5_wiz_1/clk_glitch] \
  [get_bd_pins ilconcat_2/In1]
  connect_bd_net -net clkx5_wiz_1_clk_oor  [get_bd_pins clkx5_wiz_1/clk_oor] \
  [get_bd_pins ilconcat_2/In2]
  connect_bd_net -net clkx5_wiz_1_clk_stop  [get_bd_pins clkx5_wiz_1/clk_stop] \
  [get_bd_pins ilconcat_2/In0]
  connect_bd_net -net clkx5_wiz_1_locked  [get_bd_pins clkx5_wiz_1/locked] \
  [get_bd_pins rst_module/dcm_locked1]
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
  [get_bd_pins ps_wizard_0/pl_mmi_dc_i2s_s0_clk]
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
  connect_bd_net -net ilslice_8_Dout  [get_bd_pins ilslice_8/Dout] \
  [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_ce]
  connect_bd_net -net ilslice_9_Dout  [get_bd_pins ilslice_9/Dout] \
  [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_clr_n]
  connect_bd_net [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_o2] [get_bd_pins rst_module/slowest_sync_clk] \
  [get_bd_pins rst_module/slowest_sync_clk1] \
  [get_bd_pins rst_module/slowest_sync_clk3] \
  [get_bd_pins rd_clk_wiz_status_gpio/s_axi_aclk] \
  [get_bd_pins live_input_gpio/s_axi_aclk] \
  [get_bd_pins clk_wizard_enable/s_axi_aclk] \
  [get_bd_pins ctrl_smc/aclk1] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk] \
  [get_bd_pins dc_input_pipeline/vid_clk1] \
  [get_bd_pins dc_input_pipeline/av_axi_aclk] \
  [get_bd_pins dc_input_pipeline/s_axi_aclk]
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins clk_wizard_0/resetn] \
  [get_bd_pins rst_clk/ext_reset_in] \
  [get_bd_pins rst_module/ext_reset_in]
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
  connect_bd_net -net rst_module_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn] \
  [get_bd_pins rd_clk_wiz_status_gpio/s_axi_aresetn] \
  [get_bd_pins clk_wizard_enable/s_axi_aresetn] \
  [get_bd_pins live_input_gpio/s_axi_aresetn] \
  [get_bd_pins dc_input_pipeline/vid_out_axi4s_aresetn]
  connect_bd_net -net rst_module_peripheral_aresetn2  [get_bd_pins rst_module/peripheral_aresetn1] \
  [get_bd_pins dc_input_pipeline/s_axis_aud_aresetn]
  connect_bd_net -net rst_ps_wizard_0_99M_peripheral_aresetn [get_bd_pins rst_clk/peripheral_aresetn] \
  [get_bd_pins axi_gpio_2/s_axi_aresetn] \
  [get_bd_pins axi_gpio_1/s_axi_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
  [get_bd_pins axi_uart16550_0/s_axi_aresetn] \
  [get_bd_pins ctrl_smc/aresetn] \
  [get_bd_pins clkx5_wiz_1/s_axi_aresetn] \
  [get_bd_pins dc_input_pipeline/s_axi_aresetn] \
  [get_bd_pins clkx5_wiz_0/s_axi_aresetn]
  connect_bd_net -net rst_module_peripheral_reset  [get_bd_pins rst_module/peripheral_reset] \
  [get_bd_pins dc_input_pipeline/aud_mrst]


  # Create address segments
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB04D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0500000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_input_pipeline/avtpg_vp1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB04E0000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs dc_input_pipeline/avtpg_vp0/v_tc_0/ctrl/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_asu] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_asu] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_asu] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_asu] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs NoC_C0_C1/DDR_MC_PORTS/DDR_CH0_MEDx2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs NoC_C2/DDR_MC_PORTS/DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs NoC_C3/DDR_MC_PORTS/DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs NoC_C4/DDR_MC_PORTS/DDR_CH3]