##################################################################
# DESIGN PROCs
##################################################################
set_property name clkx5_wiz_0 [get_bd_cells pl_mmi_clk_wiz]
delete_bd_objs [get_bd_nets pl_mmi_clk_wiz_clk_out1] [get_bd_nets pl_mmi_clk_wiz_clk_out2] [get_bd_nets pl_mmi_clk_wiz_clk_out3]
delete_bd_objs [get_bd_nets clkx5_wiz_0_locked]
disconnect_bd_net /ps_wizard_0_pl0_ref_clk [get_bd_pins clk_wizard_0/clk_in1]
disconnect_bd_net /ps_wizard_0_pl0_ref_clk [get_bd_pins clkx5_wiz_0/clk_in1]


# Hierarchical cell: avtpg_s1
proc create_hier_cell_avtpg_s1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_avtpg_s1() - Empty argument(s)!"}
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

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:sdp_rtl:1.0 sdp01


  # Create pins
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -type clk i2s_clk
  create_bd_pin -dir O lrclk_out
  create_bd_pin -dir I -type rst s_axis_aud_aresetn
  create_bd_pin -dir O sclk_out
  create_bd_pin -dir O -from 3 -to 0 sdata_out
  create_bd_pin -dir I -type clk vid_clk
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir O -from 71 -to 0 vid_data
  create_bd_pin -dir O vid_active_video
  create_bd_pin -dir O vid_hsync
  create_bd_pin -dir O vid_vsync

  # Create instance: av_pat_gen_0, and set properties
  set av_pat_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psdpdc_av_pat_gen av_pat_gen_0 ]
  set_property -dict [list \
    CONFIG.BPC {12} \
    CONFIG.PPC {2} \
    CONFIG.SDP_EN {1} \
  ] $av_pat_gen_0


  # Create instance: i2s_transmitter_0, and set properties
  set i2s_transmitter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psdpdc_i2s_transmitter i2s_transmitter_0 ]
  set_property CONFIG.C_NUM_CHANNELS {8} $i2s_transmitter_0


  # Create instance: v_tc_0, and set properties
  set v_tc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc v_tc_0 ]
  set_property -dict [list \
    CONFIG.VIDEO_MODE {1080p} \
    CONFIG.enable_detection {false} \
    CONFIG.max_clocks_per_line {8192} \
  ] $v_tc_0


  # Create instance: ilconcat_2, and set properties
  set ilconcat_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_2 ]
  set_property CONFIG.NUM_PORTS {4} $ilconcat_2


  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]

  # Create instance: ilconstant_1, and set properties
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_1 ]
  set_property CONFIG.CONST_VAL {0} $ilconstant_1


  # Create instance: v_axi4s_vid_out_0, and set properties
  set v_axi4s_vid_out_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out v_axi4s_vid_out_0 ]
  set_property -dict [list \
    CONFIG.C_NATIVE_COMPONENT_WIDTH {12} \
    CONFIG.C_PIXELS_PER_CLOCK {2} \
    CONFIG.C_S_AXIS_VIDEO_DATA_WIDTH {12} \
  ] $v_axi4s_vid_out_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ctrl] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins av_axi] [get_bd_intf_pins av_pat_gen_0/av_axi]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins av_pat_gen_0/sdp01] [get_bd_intf_pins sdp01]
  connect_bd_intf_net -intf_net av_pat_gen_0_aud_out_axi4s [get_bd_intf_pins av_pat_gen_0/aud_out_axi4s] [get_bd_intf_pins i2s_transmitter_0/s_axis_aud]
  connect_bd_intf_net -intf_net av_pat_gen_0_vid_out_axi4s [get_bd_intf_pins av_pat_gen_0/vid_out_axi4s] [get_bd_intf_pins v_axi4s_vid_out_0/video_in]
  connect_bd_intf_net -intf_net smartconnect_gp0_M03_AXI [get_bd_intf_pins s_axi_ctrl] [get_bd_intf_pins i2s_transmitter_0/s_axi_ctrl]
  connect_bd_intf_net -intf_net v_axi4s_vid_out_0_vid_io_out [get_bd_intf_pins v_axi4s_vid_out_0/vid_io_out] [get_bd_intf_pins vid_intf]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins v_tc_0/vtiming_out] [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in]

  # Create port connections
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins TPG_GEN_EN] \
  [get_bd_pins av_pat_gen_0/TPG_GEN_EN] \
  [get_bd_pins v_axi4s_vid_out_0/vid_io_out_ce]
  connect_bd_net -net aud_out_axi4s_aclk_1  [get_bd_pins i2s_clk] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aclk] \
  [get_bd_pins av_pat_gen_0/aud_clk] \
  [get_bd_pins i2s_transmitter_0/aud_mclk] \
  [get_bd_pins i2s_transmitter_0/s_axis_aud_aclk]
  connect_bd_net -net i2s_transmitter_0_lrclk_out  [get_bd_pins i2s_transmitter_0/lrclk_out] \
  [get_bd_pins lrclk_out]
  connect_bd_net -net i2s_transmitter_0_sclk_out  [get_bd_pins i2s_transmitter_0/sclk_out] \
  [get_bd_pins sclk_out]
  connect_bd_net -net i2s_transmitter_0_sdata_0_out  [get_bd_pins i2s_transmitter_0/sdata_0_out] \
  [get_bd_pins ilconcat_2/In0]
  connect_bd_net -net i2s_transmitter_0_sdata_1_out  [get_bd_pins i2s_transmitter_0/sdata_1_out] \
  [get_bd_pins ilconcat_2/In1]
  connect_bd_net -net i2s_transmitter_0_sdata_2_out  [get_bd_pins i2s_transmitter_0/sdata_2_out] \
  [get_bd_pins ilconcat_2/In2]
  connect_bd_net -net i2s_transmitter_0_sdata_3_out  [get_bd_pins i2s_transmitter_0/sdata_3_out] \
  [get_bd_pins ilconcat_2/In3]
  connect_bd_net -net net_mb_ss_0_clk_out2  [get_bd_pins av_axi_aclk] \
  [get_bd_pins v_tc_0/s_axi_aclk] \
  [get_bd_pins av_pat_gen_0/av_axi_aclk] \
  [get_bd_pins i2s_transmitter_0/s_axi_ctrl_aclk]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins s_axis_aud_aresetn] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aresetn] \
  [get_bd_pins i2s_transmitter_0/s_axis_aud_aresetn]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins aud_mrst] \
  [get_bd_pins i2s_transmitter_0/aud_mrst]
  connect_bd_net -net v_axi4s_vid_out_0_sof_state_out  [get_bd_pins v_axi4s_vid_out_0/sof_state_out] \
  [get_bd_pins v_tc_0/sof_state]
  connect_bd_net -net v_axi4s_vid_out_0_vid_active_video  [get_bd_pins v_axi4s_vid_out_0/vid_active_video] \
  [get_bd_pins vid_active_video]
  connect_bd_net -net v_axi4s_vid_out_0_vid_data  [get_bd_pins v_axi4s_vid_out_0/vid_data] \
  [get_bd_pins vid_data]
  connect_bd_net -net v_axi4s_vid_out_0_vid_hsync  [get_bd_pins v_axi4s_vid_out_0/vid_hsync] \
  [get_bd_pins vid_hsync]
  connect_bd_net -net v_axi4s_vid_out_0_vid_vsync  [get_bd_pins v_axi4s_vid_out_0/vid_vsync] \
  [get_bd_pins vid_vsync]
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins v_tc_0/clken] \
  [get_bd_pins v_tc_0/s_axi_aclken] \
  [get_bd_pins v_axi4s_vid_out_0/aclken]
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce1  [get_bd_pins v_axi4s_vid_out_0/vtg_ce] \
  [get_bd_pins v_tc_0/gen_clken]
  connect_bd_net -net vid_out_axi4s_aclk_1  [get_bd_pins vid_clk] \
  [get_bd_pins v_tc_0/clk] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aclk] \
  [get_bd_pins v_axi4s_vid_out_0/aclk]
  connect_bd_net -net vid_out_axi4s_aresetn_1  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins v_tc_0/resetn] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aresetn] \
  [get_bd_pins v_axi4s_vid_out_0/aresetn] \
  [get_bd_pins av_pat_gen_0/av_axi_aresetn] \
  [get_bd_pins v_tc_0/s_axi_aresetn] \
  [get_bd_pins i2s_transmitter_0/s_axi_ctrl_aresetn]
  connect_bd_net -net ilconcat_2_dout  [get_bd_pins ilconcat_2/dout] \
  [get_bd_pins sdata_out]
  connect_bd_net -net ilconstant_1_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins v_tc_0/fsync_in] \
  [get_bd_pins v_axi4s_vid_out_0/fid]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: avtpg_s0
proc create_hier_cell_avtpg_s0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_avtpg_s0() - Empty argument(s)!"}
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

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:vid_io_rtl:1.0 vid_intf

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:sdp_rtl:1.0 sdp01


  # Create pins
  create_bd_pin -dir I -from 31 -to 0 TPG_GEN_EN
  create_bd_pin -dir I -type rst aud_mrst
  create_bd_pin -dir I -type clk av_axi_aclk
  create_bd_pin -dir I -type clk i2s_clk
  create_bd_pin -dir O lrclk_out
  create_bd_pin -dir I -type rst s_axis_aud_aresetn
  create_bd_pin -dir O sclk_out
  create_bd_pin -dir O -from 3 -to 0 sdata_out
  create_bd_pin -dir I -type clk vid_clk
  create_bd_pin -dir I -type rst vid_out_axi4s_aresetn
  create_bd_pin -dir O -from 71 -to 0 vid_data
  create_bd_pin -dir O vid_active_video
  create_bd_pin -dir O vid_hsync
  create_bd_pin -dir O vid_vsync

  # Create instance: av_pat_gen_0, and set properties
  set av_pat_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psdpdc_av_pat_gen av_pat_gen_0 ]
  set_property -dict [list \
    CONFIG.BPC {12} \
    CONFIG.PPC {2} \
    CONFIG.SDP_EN {1} \
  ] $av_pat_gen_0


  # Create instance: i2s_transmitter_0, and set properties
  set i2s_transmitter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:psdpdc_i2s_transmitter i2s_transmitter_0 ]
  set_property CONFIG.C_NUM_CHANNELS {8} $i2s_transmitter_0


  # Create instance: v_tc_0, and set properties
  set v_tc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc v_tc_0 ]
  set_property -dict [list \
    CONFIG.VIDEO_MODE {1080p} \
    CONFIG.enable_detection {false} \
    CONFIG.max_clocks_per_line {8192} \
  ] $v_tc_0


  # Create instance: ilconcat_2, and set properties
  set ilconcat_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_2 ]
  set_property CONFIG.NUM_PORTS {4} $ilconcat_2


  # Create instance: ilconstant_0, and set properties
  set ilconstant_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_0 ]

  # Create instance: ilconstant_1, and set properties
  set ilconstant_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant ilconstant_1 ]
  set_property CONFIG.CONST_VAL {0} $ilconstant_1


  # Create instance: v_axi4s_vid_out_0, and set properties
  set v_axi4s_vid_out_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out v_axi4s_vid_out_0 ]
  set_property -dict [list \
    CONFIG.C_NATIVE_COMPONENT_WIDTH {12} \
    CONFIG.C_PIXELS_PER_CLOCK {2} \
    CONFIG.C_S_AXIS_VIDEO_DATA_WIDTH {12} \
  ] $v_axi4s_vid_out_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ctrl] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins av_axi] [get_bd_intf_pins av_pat_gen_0/av_axi]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins av_pat_gen_0/sdp01] [get_bd_intf_pins sdp01]
  connect_bd_intf_net -intf_net av_pat_gen_0_aud_out_axi4s [get_bd_intf_pins av_pat_gen_0/aud_out_axi4s] [get_bd_intf_pins i2s_transmitter_0/s_axis_aud]
  connect_bd_intf_net -intf_net av_pat_gen_0_vid_out_axi4s [get_bd_intf_pins av_pat_gen_0/vid_out_axi4s] [get_bd_intf_pins v_axi4s_vid_out_0/video_in]
  connect_bd_intf_net -intf_net smartconnect_gp0_M03_AXI [get_bd_intf_pins s_axi_ctrl] [get_bd_intf_pins i2s_transmitter_0/s_axi_ctrl]
  connect_bd_intf_net -intf_net v_axi4s_vid_out_0_vid_io_out [get_bd_intf_pins v_axi4s_vid_out_0/vid_io_out] [get_bd_intf_pins vid_intf]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins v_tc_0/vtiming_out] [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in]

  # Create port connections
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins TPG_GEN_EN] \
  [get_bd_pins av_pat_gen_0/TPG_GEN_EN] \
  [get_bd_pins v_axi4s_vid_out_0/vid_io_out_ce]
  connect_bd_net -net aud_out_axi4s_aclk_1  [get_bd_pins i2s_clk] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aclk] \
  [get_bd_pins av_pat_gen_0/aud_clk] \
  [get_bd_pins i2s_transmitter_0/aud_mclk] \
  [get_bd_pins i2s_transmitter_0/s_axis_aud_aclk]
  connect_bd_net -net i2s_transmitter_0_lrclk_out  [get_bd_pins i2s_transmitter_0/lrclk_out] \
  [get_bd_pins lrclk_out]
  connect_bd_net -net i2s_transmitter_0_sclk_out  [get_bd_pins i2s_transmitter_0/sclk_out] \
  [get_bd_pins sclk_out]
  connect_bd_net -net i2s_transmitter_0_sdata_0_out  [get_bd_pins i2s_transmitter_0/sdata_0_out] \
  [get_bd_pins ilconcat_2/In0]
  connect_bd_net -net i2s_transmitter_0_sdata_1_out  [get_bd_pins i2s_transmitter_0/sdata_1_out] \
  [get_bd_pins ilconcat_2/In1]
  connect_bd_net -net i2s_transmitter_0_sdata_2_out  [get_bd_pins i2s_transmitter_0/sdata_2_out] \
  [get_bd_pins ilconcat_2/In2]
  connect_bd_net -net i2s_transmitter_0_sdata_3_out  [get_bd_pins i2s_transmitter_0/sdata_3_out] \
  [get_bd_pins ilconcat_2/In3]
  connect_bd_net -net net_mb_ss_0_clk_out2  [get_bd_pins av_axi_aclk] \
  [get_bd_pins v_tc_0/s_axi_aclk] \
  [get_bd_pins av_pat_gen_0/av_axi_aclk] \
  [get_bd_pins i2s_transmitter_0/s_axi_ctrl_aclk]
  connect_bd_net -net rst_proc_1_peripheral_aresetn  [get_bd_pins s_axis_aud_aresetn] \
  [get_bd_pins av_pat_gen_0/aud_out_axi4s_aresetn] \
  [get_bd_pins i2s_transmitter_0/s_axis_aud_aresetn]
  connect_bd_net -net rst_proc_1_peripheral_reset  [get_bd_pins aud_mrst] \
  [get_bd_pins i2s_transmitter_0/aud_mrst]
  connect_bd_net -net v_axi4s_vid_out_0_sof_state_out  [get_bd_pins v_axi4s_vid_out_0/sof_state_out] \
  [get_bd_pins v_tc_0/sof_state]
  connect_bd_net -net v_axi4s_vid_out_0_vid_active_video  [get_bd_pins v_axi4s_vid_out_0/vid_active_video] \
  [get_bd_pins vid_active_video]
  connect_bd_net -net v_axi4s_vid_out_0_vid_data  [get_bd_pins v_axi4s_vid_out_0/vid_data] \
  [get_bd_pins vid_data]
  connect_bd_net -net v_axi4s_vid_out_0_vid_hsync  [get_bd_pins v_axi4s_vid_out_0/vid_hsync] \
  [get_bd_pins vid_hsync]
  connect_bd_net -net v_axi4s_vid_out_0_vid_vsync  [get_bd_pins v_axi4s_vid_out_0/vid_vsync] \
  [get_bd_pins vid_vsync]
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce  [get_bd_pins ilconstant_0/dout] \
  [get_bd_pins v_tc_0/clken] \
  [get_bd_pins v_tc_0/s_axi_aclken] \
  [get_bd_pins v_axi4s_vid_out_0/aclken]
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce1  [get_bd_pins v_axi4s_vid_out_0/vtg_ce] \
  [get_bd_pins v_tc_0/gen_clken]
  connect_bd_net -net vid_out_axi4s_aclk_1  [get_bd_pins vid_clk] \
  [get_bd_pins v_tc_0/clk] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aclk] \
  [get_bd_pins v_axi4s_vid_out_0/aclk]
  connect_bd_net -net vid_out_axi4s_aresetn_1  [get_bd_pins vid_out_axi4s_aresetn] \
  [get_bd_pins v_tc_0/resetn] \
  [get_bd_pins av_pat_gen_0/vid_out_axi4s_aresetn] \
  [get_bd_pins v_axi4s_vid_out_0/aresetn] \
  [get_bd_pins av_pat_gen_0/av_axi_aresetn] \
  [get_bd_pins v_tc_0/s_axi_aresetn] \
  [get_bd_pins i2s_transmitter_0/s_axi_ctrl_aresetn]
  connect_bd_net -net ilconcat_2_dout  [get_bd_pins ilconcat_2/dout] \
  [get_bd_pins sdata_out]
  connect_bd_net -net ilconstant_1_dout  [get_bd_pins ilconstant_1/dout] \
  [get_bd_pins v_tc_0/fsync_in] \
  [get_bd_pins v_axi4s_vid_out_0/fid]

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
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn1
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_reset
  create_bd_pin -dir I -type clk slowest_sync_clk
  create_bd_pin -dir I -type clk slowest_sync_clk2
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir I -type clk slowest_sync_clk3
  create_bd_pin -dir I dcm_locked1

  # Create instance: rst_proc_cfg_clk, and set properties
  set rst_proc_cfg_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_proc_cfg_clk ]
  set_property CONFIG.C_NUM_PERP_ARESETN {1} $rst_proc_cfg_clk


  # Create instance: rst_proc_i2s_clk, and set properties
  set rst_proc_i2s_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_proc_i2s_clk ]
  set_property CONFIG.C_NUM_PERP_ARESETN {1} $rst_proc_i2s_clk




  # Create instance: rst_proc_vid_clk, and set properties
  set rst_proc_vid_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_proc_vid_clk ]
  set_property CONFIG.C_NUM_PERP_ARESETN {1} $rst_proc_vid_clk


  # Create port connections
  connect_bd_net -net PS_0_pl0_resetn  [get_bd_pins ext_reset_in] \
  [get_bd_pins rst_proc_cfg_clk/ext_reset_in] \
  [get_bd_pins rst_proc_i2s_clk/ext_reset_in] \
  [get_bd_pins rst_proc_vid_clk/ext_reset_in]
  connect_bd_net -net clk_wiz_pl_vid_1x_clk  [get_bd_pins slowest_sync_clk] \
  [get_bd_pins rst_proc_vid_clk/slowest_sync_clk]
  connect_bd_net -net dcm_locked1_1  [get_bd_pins dcm_locked1] \
  [get_bd_pins rst_proc_i2s_clk/dcm_locked]
  connect_bd_net -net dcm_locked_1  [get_bd_pins dcm_locked] \
  [get_bd_pins rst_proc_vid_clk/dcm_locked] \
  [get_bd_pins rst_proc_cfg_clk/dcm_locked]
  connect_bd_net -net ps_cfg_clk_1  [get_bd_pins slowest_sync_clk3] \
  [get_bd_pins rst_proc_cfg_clk/slowest_sync_clk]
  connect_bd_net -net rst_proc_i2s_clk_peripheral_aresetn  [get_bd_pins rst_proc_i2s_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn1]
  connect_bd_net -net rst_proc_i2s_clk_peripheral_reset  [get_bd_pins rst_proc_i2s_clk/peripheral_reset] \
  [get_bd_pins peripheral_reset]
  connect_bd_net -net rst_proc_cfg_clk1_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn1]
  connect_bd_net -net rst_proc_vid_clk_peripheral_aresetn  [get_bd_pins rst_proc_vid_clk/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn]
  connect_bd_net -net rst_proc_vid_clk_peripheral_reset  [get_bd_pins rst_proc_vid_clk/peripheral_reset] \
  [get_bd_pins peripheral_reset1]
  connect_bd_net -net slowest_sync_clk2_1  [get_bd_pins slowest_sync_clk2] \
  [get_bd_pins rst_proc_i2s_clk/slowest_sync_clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

  # Create ports

  # Create instance: ps_wizard_0, and set properties
  set_property -dict [list \
    CONFIG.MMI_CONFIG(DPDC_OPERATING_MODE) {DC_Bypass} \
    CONFIG.MMI_CONFIG(DPDC_PRESENTATION_MODE) {Live} \
    CONFIG.MMI_CONFIG(DPDC_STREAM00_SDP_EN) {1} \
    CONFIG.MMI_CONFIG(DPDC_STREAM0_PIXEL_MODE) {Dual} \
    CONFIG.MMI_CONFIG(DPDC_STREAM1_PIXEL_MODE) {Dual} \
    CONFIG.MMI_CONFIG(DPDC_STREAM1_SDP_EN) {1} \
    CONFIG.MMI_CONFIG(DPDC_STREAMS) {2} \
    CONFIG.MMI_CONFIG(MMI_DP_HPD) {PMC_MIO_48} \
    CONFIG.MMI_CONFIG(MST_MODE_EN) {1} \
    CONFIG.MMI_CONFIG(PL_MMI_INTERRUPTS_EN) {1} \
    CONFIG.MMI_CONFIG(UDH_GT) {DP_X4} \
    CONFIG.PS11_CONFIG(MMI_DP_HPD) {PMC_MIO_48} \
    CONFIG.PS11_CONFIG(PL_MMI_INTERRUPTS_EN) {1} \
    CONFIG.PS11_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 0 IO PMC_MIO_16:17 IO_TYPE MIO} \
    CONFIG.PS11_CONFIG(UDH_GT) {DP_X4} \
  ] [get_bd_cells ps_wizard_0]



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
    CONFIG.CLKOUT_PORT {i2s_clk,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {196.608,100.000,100.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.ENABLE_CLOCK_MONITOR {true} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.USE_DYN_RECONFIG {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
  ] $clkx5_wiz_1


  # Create instance: ilslice_0, and set properties
  set ilslice_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {29} \
    CONFIG.DIN_TO {29} \
    CONFIG.DIN_WIDTH {32} \
  ] $ilslice_0


  # Create instance: ilslice_1, and set properties
  set ilslice_1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {31} \
    CONFIG.DIN_TO {31} \
    CONFIG.DIN_WIDTH {32} \
  ] $ilslice_1


  # Create instance: ilslice_2, and set properties
  set ilslice_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice ilslice_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {30} \
    CONFIG.DIN_TO {30} \
    CONFIG.DIN_WIDTH {32} \
  ] $ilslice_2


  # Create instance: rst_module
  create_hier_cell_rst_module [current_bd_instance .] rst_module

  # Create instance: smartconnect_gp0, and set properties
  set smartconnect_gp0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_gp0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {6} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_gp0


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
    CONFIG.C_IS_DUAL {0} \
  ] $clk_wizard_enable


  # Create instance: Live_input_gpio, and set properties
  set Live_input_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio Live_input_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_IS_DUAL {0} \
  ] $Live_input_gpio


  # Create instance: rd_clk_wiz_status_gpio, and set properties
  set rd_clk_wiz_status_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio rd_clk_wiz_status_gpio ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {12} \
    CONFIG.C_GPIO_WIDTH {12} \
    CONFIG.C_IS_DUAL {1} \
  ] $rd_clk_wiz_status_gpio


  # Create instance: ilconcat_2, and set properties
  set ilconcat_2 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {4} \
    CONFIG.IN1_WIDTH {4} \
    CONFIG.IN2_WIDTH {4} \
    CONFIG.NUM_PORTS {3} \
  ] $ilconcat_2


  # Create instance: ilconcat_3, and set properties
  set ilconcat_3 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat ilconcat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {4} \
    CONFIG.IN1_WIDTH {4} \
    CONFIG.IN2_WIDTH {4} \
    CONFIG.NUM_PORTS {3} \
  ] $ilconcat_3


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


  # Create instance: avtpg_s0
  create_hier_cell_avtpg_s0 [current_bd_instance .] avtpg_s0

  # Create instance: avtpg_s1
  create_hier_cell_avtpg_s1 [current_bd_instance .] avtpg_s1

  # Create interface connections
  connect_bd_intf_net -intf_net avtpg_s0_sdp01 [get_bd_intf_pins ps_wizard_0/sdp_sdp0] [get_bd_intf_pins avtpg_s0/sdp01]
  connect_bd_intf_net -intf_net avtpg_s0_vid_intf [get_bd_intf_pins ps_wizard_0/video_s0] [get_bd_intf_pins avtpg_s0/vid_intf]
  connect_bd_intf_net -intf_net avtpg_s1_sdp01 [get_bd_intf_pins ps_wizard_0/sdp_sdp1] [get_bd_intf_pins avtpg_s1/sdp01]
  connect_bd_intf_net -intf_net avtpg_s1_vid_intf [get_bd_intf_pins ps_wizard_0/video_s1] [get_bd_intf_pins avtpg_s1/vid_intf]
  connect_bd_intf_net -intf_net ctrl_smc_M06_AXI [get_bd_intf_pins ctrl_smc/M06_AXI] [get_bd_intf_pins clkx5_wiz_1/s_axi_lite]
  connect_bd_intf_net -intf_net ctrl_smc_M07_AXI [get_bd_intf_pins ctrl_smc/M07_AXI] [get_bd_intf_pins Live_input_gpio/S_AXI]
  connect_bd_intf_net -intf_net ctrl_smc_M08_AXI [get_bd_intf_pins ctrl_smc/M08_AXI] [get_bd_intf_pins rd_clk_wiz_status_gpio/S_AXI]
  connect_bd_intf_net -intf_net ctrl_smc_M09_AXI [get_bd_intf_pins ctrl_smc/M09_AXI] [get_bd_intf_pins clk_wizard_enable/S_AXI]
  connect_bd_intf_net -intf_net ctrl_smc_M10_AXI [get_bd_intf_pins ctrl_smc/M10_AXI] [get_bd_intf_pins smartconnect_gp0/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_gp0_M00_AXI [get_bd_intf_pins smartconnect_gp0/M00_AXI] [get_bd_intf_pins avtpg_s0/av_axi]
  connect_bd_intf_net -intf_net smartconnect_gp0_M01_AXI [get_bd_intf_pins smartconnect_gp0/M01_AXI] [get_bd_intf_pins avtpg_s0/ctrl]
  connect_bd_intf_net -intf_net smartconnect_gp0_M02_AXI [get_bd_intf_pins smartconnect_gp0/M02_AXI] [get_bd_intf_pins avtpg_s0/s_axi_ctrl]
  connect_bd_intf_net -intf_net smartconnect_gp0_M03_AXI [get_bd_intf_pins smartconnect_gp0/M03_AXI] [get_bd_intf_pins avtpg_s1/av_axi]
  connect_bd_intf_net -intf_net smartconnect_gp0_M04_AXI [get_bd_intf_pins smartconnect_gp0/M04_AXI] [get_bd_intf_pins avtpg_s1/ctrl]
  connect_bd_intf_net -intf_net smartconnect_gp0_M05_AXI [get_bd_intf_pins smartconnect_gp0/M05_AXI] [get_bd_intf_pins avtpg_s1/s_axi_ctrl]


  # Create port connections
  connect_bd_net -net TPG_GEN_EN_1  [get_bd_pins Live_input_gpio/gpio_io_o] \
  [get_bd_pins avtpg_s1/TPG_GEN_EN] \
  [get_bd_pins avtpg_s0/TPG_GEN_EN] \
  [get_bd_pins ilslice_0/Din] \
  [get_bd_pins ilslice_1/Din] \
  [get_bd_pins ilslice_2/Din]
  connect_bd_net -net avtpg_s0_lrclk_out  [get_bd_pins avtpg_s0/lrclk_out] \
  [get_bd_pins ps_wizard_0/i2s_i2s0_lrclk_tx]
  connect_bd_net -net avtpg_s0_sclk_out  [get_bd_pins avtpg_s0/sclk_out] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_i2s_s0_clk]
  connect_bd_net -net avtpg_s0_sdata_out  [get_bd_pins avtpg_s0/sdata_out] \
  [get_bd_pins ps_wizard_0/i2s_i2s0_sdata_0]
  connect_bd_net -net avtpg_s0_vid_active_video  [get_bd_pins avtpg_s0/vid_active_video] \
  [get_bd_pins ps_wizard_0/video_s0_active_video]
  connect_bd_net -net avtpg_s0_vid_data  [get_bd_pins avtpg_s0/vid_data] \
  [get_bd_pins ps_wizard_0/video_s0_data]
  connect_bd_net -net avtpg_s0_vid_hsync  [get_bd_pins avtpg_s0/vid_hsync] \
  [get_bd_pins ps_wizard_0/video_s0_hsync]
  connect_bd_net -net avtpg_s0_vid_vsync  [get_bd_pins avtpg_s0/vid_vsync] \
  [get_bd_pins ps_wizard_0/video_s0_vsync]
  connect_bd_net -net avtpg_s1_lrclk_out  [get_bd_pins avtpg_s1/lrclk_out] \
  [get_bd_pins ps_wizard_0/i2s_i2s1_lrclk_tx]
  connect_bd_net -net avtpg_s1_sclk_out  [get_bd_pins avtpg_s1/sclk_out] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_i2s_s1_clk]
  connect_bd_net -net avtpg_s1_sdata_out  [get_bd_pins avtpg_s1/sdata_out] \
  [get_bd_pins ps_wizard_0/i2s_i2s1_sdata_0]
  connect_bd_net -net avtpg_s1_vid_active_video  [get_bd_pins avtpg_s1/vid_active_video] \
  [get_bd_pins ps_wizard_0/video_s1_active_video]
  connect_bd_net -net avtpg_s1_vid_data  [get_bd_pins avtpg_s1/vid_data] \
  [get_bd_pins ps_wizard_0/video_s1_data]
  connect_bd_net -net avtpg_s1_vid_hsync  [get_bd_pins avtpg_s1/vid_hsync] \
  [get_bd_pins ps_wizard_0/video_s1_hsync]
  connect_bd_net -net avtpg_s1_vid_vsync  [get_bd_pins avtpg_s1/vid_vsync] \
  [get_bd_pins ps_wizard_0/video_s1_vsync]
  connect_bd_net -net axi_gpio_3_gpio_io_o  [get_bd_pins clk_wizard_enable/gpio_io_o] \
  [get_bd_pins ilslice_9/Din] \
  [get_bd_pins ilslice_8/Din]
  connect_bd_net -net ps_wizard_0_pl0_ref_clk  [get_bd_pins ps_wizard_0/pl0_ref_clk] \
  [get_bd_pins clk_wizard_0/clk_in1]
  connect_bd_net [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins clkx5_wiz_0/clk_in1] \
  [get_bd_pins clkx5_wiz_1/clk_in1] \
  [get_bd_pins clkx5_wiz_1/ref_clk] \
  [get_bd_pins clkx5_wiz_1/s_axi_aclk] \
  [get_bd_pins clkx5_wiz_0/ref_clk] \
  [get_bd_pins clkx5_wiz_0/s_axi_aclk] \
  [get_bd_pins smartconnect_gp0/aclk] \
  [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins axi_gpio_1/s_axi_aclk] \
  [get_bd_pins axi_gpio_2/s_axi_aclk] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins rst_clk/slowest_sync_clk] \
  [get_bd_pins ctrl_smc/aclk] \
  [get_bd_pins ps_wizard_0/lpd_axi_pl_aclk] \
  [get_bd_pins axi_uart16550_0/s_axi_aclk] 
  connect_bd_net -net clkx5_wiz_0_clk_glitch  [get_bd_pins clkx5_wiz_1/clk_glitch] \
  [get_bd_pins ilconcat_2/In1]
  connect_bd_net -net clkx5_wiz_0_clk_oor  [get_bd_pins clkx5_wiz_1/clk_oor] \
  [get_bd_pins ilconcat_2/In2]
  connect_bd_net -net clkx5_wiz_0_clk_stop  [get_bd_pins clkx5_wiz_1/clk_stop] \
  [get_bd_pins ilconcat_2/In0]
  connect_bd_net -net clkx5_wiz_0_locked  [get_bd_pins clkx5_wiz_1/locked] \
  [get_bd_pins rst_module/dcm_locked1]
  connect_bd_net [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_o1] [get_bd_pins ps_wizard_0/pl_mmi_dc_2x_clk]
  connect_bd_net -net clkx5_wiz_1_clk_glitch  [get_bd_pins clkx5_wiz_0/clk_glitch] \
  [get_bd_pins ilconcat_3/In1]
  connect_bd_net -net clkx5_wiz_1_clk_oor  [get_bd_pins clkx5_wiz_0/clk_oor] \
  [get_bd_pins ilconcat_3/In2]
  connect_bd_net -net clkx5_wiz_1_clk_stop  [get_bd_pins clkx5_wiz_0/clk_stop] \
  [get_bd_pins ilconcat_3/In0]
  connect_bd_net -net clkx5_wiz_1_locked  [get_bd_pins clkx5_wiz_0/locked] \
  [get_bd_pins rst_module/dcm_locked]
  connect_bd_net [get_bd_pins clkx5_wiz_0/pl_vid_2x_clk_o2] [get_bd_pins ps_wizard_0/pl_mmi_dc_1x_clk] \
  [get_bd_pins ps_wizard_0/pl_mmi_dc_s1_clk] \
  [get_bd_pins rst_module/slowest_sync_clk] \
  [get_bd_pins smartconnect_gp0/aclk1] \
  [get_bd_pins ctrl_smc/aclk1] \
  [get_bd_pins clk_wizard_enable/s_axi_aclk] \
  [get_bd_pins Live_input_gpio/s_axi_aclk] \
  [get_bd_pins avtpg_s1/vid_clk] \
  [get_bd_pins avtpg_s0/vid_clk] \
  [get_bd_pins rd_clk_wiz_status_gpio/s_axi_aclk] \
  [get_bd_pins rst_module/slowest_sync_clk3] \
  [get_bd_pins avtpg_s1/av_axi_aclk] \
  [get_bd_pins avtpg_s0/av_axi_aclk]
  connect_bd_net -net i2s_lrclk_1  [get_bd_pins clkx5_wiz_1/i2s_clk] \
  [get_bd_pins rst_module/slowest_sync_clk2] \
  [get_bd_pins avtpg_s1/i2s_clk] \
  [get_bd_pins avtpg_s0/i2s_clk]
  connect_bd_net -net ilconcat_2_dout  [get_bd_pins ilconcat_2/dout] \
  [get_bd_pins rd_clk_wiz_status_gpio/gpio_io_i]
  connect_bd_net -net ilconcat_3_dout  [get_bd_pins ilconcat_3/dout] \
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
  connect_bd_net -net ps_wizard_0_pl0_resetn  [get_bd_pins ps_wizard_0/pl0_resetn] \
  [get_bd_pins clk_wizard_0/resetn] \
  [get_bd_pins rst_clk/ext_reset_in] \
  [get_bd_pins rst_module/ext_reset_in]
  connect_bd_net -net rst_ps_wizard_0_99M_peripheral_aresetn [get_bd_pins rst_clk/peripheral_aresetn] \
  [get_bd_pins axi_gpio_2/s_axi_aresetn] \
  [get_bd_pins axi_gpio_1/s_axi_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
  [get_bd_pins ctrl_smc/aresetn] \
  [get_bd_pins smartconnect_gp0/aresetn] \
  [get_bd_pins clkx5_wiz_1/s_axi_aresetn] \
  [get_bd_pins clkx5_wiz_0/s_axi_aresetn]
  connect_bd_net -net rst_module_peripheral_aresetn  [get_bd_pins rst_module/peripheral_aresetn] \
  [get_bd_pins clk_wizard_enable/s_axi_aresetn] \
  [get_bd_pins Live_input_gpio/s_axi_aresetn] \
  [get_bd_pins avtpg_s1/vid_out_axi4s_aresetn] \
  [get_bd_pins avtpg_s0/vid_out_axi4s_aresetn] \
  [get_bd_pins rd_clk_wiz_status_gpio/s_axi_aresetn]
  connect_bd_net [get_bd_pins rst_module/peripheral_aresetn1] [get_bd_pins avtpg_s1/s_axis_aud_aresetn] \
  [get_bd_pins avtpg_s0/s_axis_aud_aresetn]
  connect_bd_net -net rst_module_peripheral_reset  [get_bd_pins rst_module/peripheral_reset] \
  [get_bd_pins avtpg_s1/aud_mrst] \
  [get_bd_pins avtpg_s0/aud_mrst]

  # Create address segments
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -with_name SEG_axi_gpio_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -with_name SEG_axi_gpio_1_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -with_name SEG_axi_gpio_3_Reg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_2 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_3 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB05E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs Live_input_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0440000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs avtpg_s1/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0400000 -range 0x00010000 -with_name SEG_av_pat_gen_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs avtpg_s0/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0xB0560000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs clk_wizard_enable/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs clkx5_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs clkx5_wiz_1/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xB0460000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs avtpg_s1/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB0420000 -range 0x00010000 -with_name SEG_i2s_transmitter_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs avtpg_s0/i2s_transmitter_0/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0xB05B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs rd_clk_wiz_status_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0xB0410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs avtpg_s0/v_tc_0/ctrl/Reg] -force
  assign_bd_address -offset 0xB0450000 -range 0x00010000 -with_name SEG_v_tc_0_Reg_1 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs avtpg_s1/v_tc_0/ctrl/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg 
