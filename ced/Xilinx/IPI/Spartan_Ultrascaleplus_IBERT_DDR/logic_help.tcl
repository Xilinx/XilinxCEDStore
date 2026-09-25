##################################################################
# DESIGN PROCs
##################################################################

# Hierarchical cell: counters
proc create_hier_cell_counters { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_counters() - Empty argument(s)!"}
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
  create_bd_pin -dir I -type clk clk100
  create_bd_pin -dir I -type clk clk200
  create_bd_pin -dir I -from 0 -to 0 -type data locked

  # Create instance: const1, and set properties
  set const1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 const1 ]

  # Create instance: fast_cosine, and set properties
  set fast_cosine [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice:1.0 fast_cosine ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {0} \
   CONFIG.DOUT_WIDTH {16} \
 ] $fast_cosine

  # Create instance: fast_counter_0, and set properties
  set fast_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary:12.0 fast_counter_0 ]
  set_property -dict [ list \
   CONFIG.CE {true} \
   CONFIG.Count_Mode {UPDOWN} \
   CONFIG.Load {true} \
   CONFIG.Output_Width {32} \
   CONFIG.SCLR {true} \
 ] $fast_counter_0

  # Create instance: fast_dds_compiler_0, and set properties
  set fast_dds_compiler_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dds_compiler:6.0 fast_dds_compiler_0 ]
  set_property -dict [ list \
   CONFIG.DATA_Has_TLAST {Not_Required} \
   CONFIG.Has_Phase_Out {false} \
   CONFIG.Latency {2} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Noise_Shaping {None} \
   CONFIG.Output_Frequency1 {0} \
   CONFIG.Output_Selection {Sine_and_Cosine} \
   CONFIG.Output_Width {16} \
   CONFIG.PINC1 {0} \
   CONFIG.Parameter_Entry {Hardware_Parameters} \
   CONFIG.PartsPresent {SIN_COS_LUT_only} \
   CONFIG.Phase_Width {10} \
   CONFIG.S_PHASE_Has_TUSER {Not_Required} \
 ] $fast_dds_compiler_0

  # Create instance: fast_phase, and set properties
  set fast_phase [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice:1.0 fast_phase ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {0} \
   CONFIG.DOUT_WIDTH {16} \
 ] $fast_phase

  # Create instance: fast_sine, and set properties
  set fast_sine [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice:1.0 fast_sine ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {16} \
   CONFIG.DOUT_WIDTH {16} \
 ] $fast_sine

  # Create instance: ila_fast_counter_0, and set properties 
  set ila_fast_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_fast_counter_0 ]
  set_property -dict [ list \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.ALL_PROBE_SAME_MU_CNT {4} \
   CONFIG.C_ADV_TRIGGER {true} \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_EN_STRG_QUAL {1} \
   CONFIG.C_INPUT_PIPE_STAGES {2} \
   CONFIG.C_NUM_OF_PROBES {13} \
   CONFIG.C_PROBE0_MU_CNT {4} \
   CONFIG.C_PROBE10_MU_CNT {4} \
   CONFIG.C_PROBE10_WIDTH {16} \
   CONFIG.C_PROBE11_MU_CNT {4} \
   CONFIG.C_PROBE11_WIDTH {16} \
   CONFIG.C_PROBE12_MU_CNT {4} \
   CONFIG.C_PROBE1_MU_CNT {4} \
   CONFIG.C_PROBE2_MU_CNT {4} \
   CONFIG.C_PROBE3_MU_CNT {4} \
   CONFIG.C_PROBE4_MU_CNT {4} \
   CONFIG.C_PROBE4_WIDTH {32} \
   CONFIG.C_PROBE5_MU_CNT {4} \
   CONFIG.C_PROBE5_WIDTH {32} \
   CONFIG.C_PROBE6_MU_CNT {4} \
   CONFIG.C_PROBE7_MU_CNT {4} \
   CONFIG.C_PROBE8_MU_CNT {4} \
   CONFIG.C_PROBE9_MU_CNT {4} \
   CONFIG.C_TRIGIN_EN {true} \
   CONFIG.C_TRIGOUT_EN {true} \
 ] $ila_fast_counter_0

  # Create instance: ila_slow_counter_0, and set properties
  set ila_slow_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_slow_counter_0 ]
  set_property -dict [ list \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.ALL_PROBE_SAME_MU_CNT {4} \
   CONFIG.C_ADV_TRIGGER {true} \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_EN_STRG_QUAL {1} \
   CONFIG.C_INPUT_PIPE_STAGES {2} \
   CONFIG.C_NUM_OF_PROBES {13} \
   CONFIG.C_PROBE0_MU_CNT {4} \
   CONFIG.C_PROBE10_MU_CNT {4} \
   CONFIG.C_PROBE10_WIDTH {16} \
   CONFIG.C_PROBE11_MU_CNT {4} \
   CONFIG.C_PROBE11_WIDTH {16} \
   CONFIG.C_PROBE12_MU_CNT {4} \
   CONFIG.C_PROBE1_MU_CNT {4} \
   CONFIG.C_PROBE2_MU_CNT {4} \
   CONFIG.C_PROBE3_MU_CNT {4} \
   CONFIG.C_PROBE4_MU_CNT {4} \
   CONFIG.C_PROBE4_WIDTH {32} \
   CONFIG.C_PROBE5_MU_CNT {4} \
   CONFIG.C_PROBE5_WIDTH {32} \
   CONFIG.C_PROBE6_MU_CNT {4} \
   CONFIG.C_PROBE7_MU_CNT {4} \
   CONFIG.C_PROBE8_MU_CNT {4} \
   CONFIG.C_PROBE9_MU_CNT {4} \
   CONFIG.C_TRIGIN_EN {true} \
   CONFIG.C_TRIGOUT_EN {true} \
 ] $ila_slow_counter_0

  # Create instance: slow_cosine, and set properties
  set slow_cosine [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice:1.0 slow_cosine ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {0} \
   CONFIG.DOUT_WIDTH {16} \
 ] $slow_cosine

  # Create instance: slow_counter_0, and set properties
  set slow_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary:12.0 slow_counter_0 ]
  set_property -dict [ list \
   CONFIG.CE {true} \
   CONFIG.Count_Mode {UPDOWN} \
   CONFIG.Load {true} \
   CONFIG.Output_Width {32} \
   CONFIG.SCLR {true} \
 ] $slow_counter_0

  # Create instance: slow_dds_compiler_0, and set properties
  set slow_dds_compiler_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dds_compiler:6.0 slow_dds_compiler_0 ]
  set_property -dict [ list \
   CONFIG.DATA_Has_TLAST {Not_Required} \
   CONFIG.Has_Phase_Out {false} \
   CONFIG.Latency {2} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.Noise_Shaping {None} \
   CONFIG.Output_Frequency1 {0} \
   CONFIG.Output_Selection {Sine_and_Cosine} \
   CONFIG.Output_Width {16} \
   CONFIG.PINC1 {0} \
   CONFIG.Parameter_Entry {Hardware_Parameters} \
   CONFIG.PartsPresent {SIN_COS_LUT_only} \
   CONFIG.Phase_Width {10} \
   CONFIG.S_PHASE_Has_TUSER {Not_Required} \
 ] $slow_dds_compiler_0

  # Create instance: slow_phase, and set properties
  set slow_phase [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice:1.0 slow_phase ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {0} \
   CONFIG.DOUT_WIDTH {16} \
 ] $slow_phase

  # Create instance: slow_sine, and set properties
  set slow_sine [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilslice:1.0 slow_sine ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {16} \
   CONFIG.DOUT_WIDTH {16} \
 ] $slow_sine

  # Create instance: vio_fast_counter_0, and set properties
  set vio_fast_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_fast_counter_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_OUT {5} \
   CONFIG.C_PROBE_IN0_WIDTH {32} \
   CONFIG.C_PROBE_OUT0_INIT_VAL {0x1} \
   CONFIG.C_PROBE_OUT2_INIT_VAL {0x1} \
   CONFIG.C_PROBE_OUT4_WIDTH {32} \
 ] $vio_fast_counter_0

  # Create instance: vio_slow_counter_0, and set properties
  set vio_slow_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_slow_counter_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_OUT {5} \
   CONFIG.C_PROBE_IN0_WIDTH {32} \
   CONFIG.C_PROBE_OUT0_INIT_VAL {0x1} \
   CONFIG.C_PROBE_OUT2_INIT_VAL {0x1} \
   CONFIG.C_PROBE_OUT4_WIDTH {32} \
 ] $vio_slow_counter_0

  # Create port connections
  connect_bd_net -net clk100 [get_bd_pins clk100] [get_bd_pins ila_slow_counter_0/clk] [get_bd_pins slow_counter_0/CLK] [get_bd_pins slow_dds_compiler_0/aclk] [get_bd_pins vio_slow_counter_0/clk]
  connect_bd_net -net clk200 [get_bd_pins clk200] [get_bd_pins fast_counter_0/CLK] [get_bd_pins fast_dds_compiler_0/aclk] [get_bd_pins ila_fast_counter_0/clk] [get_bd_pins vio_fast_counter_0/clk]
  connect_bd_net -net const1_dout [get_bd_pins const1/dout] [get_bd_pins fast_dds_compiler_0/s_axis_phase_tvalid] [get_bd_pins slow_dds_compiler_0/s_axis_phase_tvalid]
  connect_bd_net -net fast_cosine_Dout [get_bd_pins fast_cosine/Dout] [get_bd_pins ila_fast_counter_0/probe11]
  connect_bd_net -net fast_counter_0_CE [get_bd_pins fast_counter_0/CE] [get_bd_pins ila_fast_counter_0/probe0] [get_bd_pins vio_fast_counter_0/probe_out0]
  connect_bd_net -net fast_counter_0_L [get_bd_pins fast_counter_0/L] [get_bd_pins ila_fast_counter_0/probe4] [get_bd_pins vio_fast_counter_0/probe_out4]
  connect_bd_net -net fast_counter_0_LOAD [get_bd_pins fast_counter_0/LOAD] [get_bd_pins ila_fast_counter_0/probe3] [get_bd_pins vio_fast_counter_0/probe_out3]
  connect_bd_net -net fast_counter_0_Q [get_bd_pins fast_counter_0/Q] [get_bd_pins fast_phase/Din] [get_bd_pins ila_fast_counter_0/probe5] [get_bd_pins vio_fast_counter_0/probe_in0]
  connect_bd_net -net fast_counter_0_SCLR [get_bd_pins fast_counter_0/SCLR] [get_bd_pins ila_fast_counter_0/probe1] [get_bd_pins vio_fast_counter_0/probe_out1]
  connect_bd_net -net fast_counter_0_UP [get_bd_pins fast_counter_0/UP] [get_bd_pins ila_fast_counter_0/probe2] [get_bd_pins vio_fast_counter_0/probe_out2]
  connect_bd_net -net fast_dds_compiler_0_m_axis_data_tdata [get_bd_pins fast_cosine/Din] [get_bd_pins fast_dds_compiler_0/m_axis_data_tdata] [get_bd_pins fast_sine/Din]
  connect_bd_net -net fast_phase_Dout [get_bd_pins fast_dds_compiler_0/s_axis_phase_tdata] [get_bd_pins fast_phase/Dout]
  connect_bd_net -net fast_sine_Dout [get_bd_pins fast_sine/Dout] [get_bd_pins ila_fast_counter_0/probe10]
  connect_bd_net -net ila_fast_counter_0_TRIG_IN_ack [get_bd_pins ila_fast_counter_0/trig_in_ack] [get_bd_pins ila_fast_counter_0/probe9] [get_bd_pins ila_slow_counter_0/trig_out_ack] [get_bd_pins ila_slow_counter_0/probe7]
  connect_bd_net -net ila_fast_counter_0_TRIG_OUT_trig [get_bd_pins ila_fast_counter_0/trig_out] [get_bd_pins ila_fast_counter_0/probe6] [get_bd_pins ila_slow_counter_0/trig_in] [get_bd_pins ila_slow_counter_0/probe8]
  connect_bd_net -net ila_slow_counter_0_TRIG_IN_ack [get_bd_pins ila_fast_counter_0/trig_out_ack] [get_bd_pins ila_fast_counter_0/probe7] [get_bd_pins ila_slow_counter_0/trig_in_ack] [get_bd_pins ila_slow_counter_0/probe9]
  connect_bd_net -net ila_slow_counter_0_TRIG_OUT_trig [get_bd_pins ila_fast_counter_0/trig_in] [get_bd_pins ila_fast_counter_0/probe8] [get_bd_pins ila_slow_counter_0/trig_out] [get_bd_pins ila_slow_counter_0/probe6]
  connect_bd_net -net locked [get_bd_pins locked] [get_bd_pins ila_fast_counter_0/probe12] [get_bd_pins ila_slow_counter_0/probe12]
  connect_bd_net -net slow_cosine_Dout [get_bd_pins ila_slow_counter_0/probe11] [get_bd_pins slow_cosine/Dout]
  connect_bd_net -net slow_counter_0_CE [get_bd_pins ila_slow_counter_0/probe0] [get_bd_pins slow_counter_0/CE] [get_bd_pins vio_slow_counter_0/probe_out0]
  connect_bd_net -net slow_counter_0_L [get_bd_pins ila_slow_counter_0/probe4] [get_bd_pins slow_counter_0/L] [get_bd_pins vio_slow_counter_0/probe_out4]
  connect_bd_net -net slow_counter_0_LOAD [get_bd_pins ila_slow_counter_0/probe3] [get_bd_pins slow_counter_0/LOAD] [get_bd_pins vio_slow_counter_0/probe_out3]
  connect_bd_net -net slow_counter_0_Q [get_bd_pins ila_slow_counter_0/probe5] [get_bd_pins slow_counter_0/Q] [get_bd_pins slow_phase/Din] [get_bd_pins vio_slow_counter_0/probe_in0]
  connect_bd_net -net slow_counter_0_SCLR [get_bd_pins ila_slow_counter_0/probe1] [get_bd_pins slow_counter_0/SCLR] [get_bd_pins vio_slow_counter_0/probe_out1]
  connect_bd_net -net slow_counter_0_UP [get_bd_pins ila_slow_counter_0/probe2] [get_bd_pins slow_counter_0/UP] [get_bd_pins vio_slow_counter_0/probe_out2]
  connect_bd_net -net slow_dds_compiler_0_m_axis_data_tdata [get_bd_pins slow_cosine/Din] [get_bd_pins slow_dds_compiler_0/m_axis_data_tdata] [get_bd_pins slow_sine/Din]
  connect_bd_net -net slow_phase_0 [get_bd_pins slow_dds_compiler_0/s_axis_phase_tdata] [get_bd_pins slow_phase/Dout]
  connect_bd_net -net slow_sine_Dout [get_bd_pins ila_slow_counter_0/probe10] [get_bd_pins slow_sine/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tg_bc

proc create_hier_cell_tg_bc { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tg_bc() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 lpddr5_sdram

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_sysclk1_lpddrmc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk clk

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]

  # Create instance: lpddrmc_0, and set properties
  set lpddrmc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lpddrmc:1.0 lpddrmc_0 ]
  set_property -dict [list \
    CONFIG.LPDDR5_BOARD_INTERFACE {lpddr5_sdram} \
    CONFIG.USER_XSDB_INTF_EN {TRUE} \
    CONFIG.SYSCLK_BOARD_INTERFACE {default_sysclk1_lpddrmc} \
  ] $lpddrmc_0


  # Create instance: perf_axi_tg_0, and set properties
  set perf_axi_tg_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:perf_axi_tg:1.0 perf_axi_tg_0 ]
  set_property -dict [list \
    CONFIG.IS_CONN_SLAVE_AXI_NOC {false} \
    CONFIG.USER_C_AXI_CLK_PERIOD {4000} \
    CONFIG.USER_C_AXI_PROTOCOL {AXI4} \
    CONFIG.USER_C_AXI_READ_BASEADDR {0x0000000000000000} \
    CONFIG.USER_C_AXI_READ_HIGHADDR {0x000000007FFFFFFF} \
    CONFIG.USER_C_AXI_SLAVE_DATA_WIDTH {256} \
    CONFIG.USER_C_AXI_WDATA_WIDTH {256} \
    CONFIG.USER_C_AXI_WRITE_BASEADDR {0x0000000000000000} \
    CONFIG.USER_C_AXI_WRITE_BASEADDR_SLV {0x000000000000} \
    CONFIG.USER_C_AXI_WRITE_HIGHADDR {0x000000007FFFFFFF} \
    CONFIG.USER_C_AXI_WRITE_HIGHADDR_SLV {0x00007FFFFFFF} \
    CONFIG.USER_DEBUG_INTF {TRUE} \
    CONFIG.USER_NO_OF_SLAVE_CONNECTED {1} \
    CONFIG.USER_SYNTH_DEFINED_PATTERN_CSV ${script_folder}/empty_traffic_spec.csv \
    CONFIG.USER_TRAFFIC_SHAPING_EN {FALSE} \
  ] $perf_axi_tg_0

  set_property -dict [list \
    CONFIG.IS_CONN_SLAVE_AXI_NOC.VALUE_MODE {auto} \
    CONFIG.USER_C_AXI_CLK_PERIOD.VALUE_MODE {auto} \
    CONFIG.USER_C_AXI_READ_BASEADDR.VALUE_MODE {auto} \
    CONFIG.USER_C_AXI_READ_HIGHADDR.VALUE_MODE {auto} \
    CONFIG.USER_C_AXI_SLAVE_DATA_WIDTH.VALUE_MODE {auto} \
    CONFIG.USER_C_AXI_WRITE_BASEADDR.VALUE_MODE {auto} \
    CONFIG.USER_C_AXI_WRITE_BASEADDR_SLV.VALUE_MODE {auto} \
    CONFIG.USER_C_AXI_WRITE_HIGHADDR.VALUE_MODE {auto} \
    CONFIG.USER_C_AXI_WRITE_HIGHADDR_SLV.VALUE_MODE {auto} \
    CONFIG.USER_NO_OF_SLAVE_CONNECTED.VALUE_MODE {auto} \
  ] $perf_axi_tg_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {3} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_0_bram ]
  set_property CONFIG.Memory_Type {True_Dual_Port_RAM} $axi_bram_ctrl_0_bram


  # Create instance: sim_trig_0, and set properties
  set sim_trig_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:sim_trig:1.0 sim_trig_0 ]
  set_property -dict [list \
    CONFIG.USER_DEBUG_INTF {EXTERNAL_AXI4_LITE} \
    CONFIG.USER_TRAFFIC_SHAPING_EN {FALSE} \
  ] $sim_trig_0


  # Create instance: vio_0, and set properties
  set vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_0 ]
  set_property -dict [list \
    CONFIG.C_NUM_PROBE_IN {5} \
    CONFIG.C_NUM_PROBE_OUT {2} \
  ] $vio_0

  # Create instance: system_ila_0 and set properties
  set system_ila_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0]
  set_property -dict [list \
    CONFIG.C_DATA_DEPTH {2048} \
  ] $system_ila_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net default_sysclk1_lpddrmc_1 [get_bd_intf_pins default_sysclk1_lpddrmc] [get_bd_intf_pins lpddrmc_0/SYS_CLK]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins S00_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net lpddrmc_0_LPDDR5 [get_bd_intf_pins lpddr5_sdram] [get_bd_intf_pins lpddrmc_0/LPDDR5]
  connect_bd_intf_net -intf_net perf_axi_tg_0_M_AXI [get_bd_intf_pins perf_axi_tg_0/M_AXI] [get_bd_intf_pins lpddrmc_0/S1_AXI]
  connect_bd_intf_net -intf_net sim_trig_0_MCSIO_OUT_00 [get_bd_intf_pins sim_trig_0/MCSIO_OUT_00] [get_bd_intf_pins perf_axi_tg_0/MCSIO_IN]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins sim_trig_0/AXI4_LITE]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins smartconnect_0/M02_AXI] [get_bd_intf_pins lpddrmc_0/S0_AXI]
  connect_bd_intf_net [get_bd_intf_pins system_ila_0/SLOT_0_AXI] [get_bd_intf_pins sim_trig_0/AXI4_LITE]

  # Create port connections
  connect_bd_net -net clk_wiz_0_clk_out1  [get_bd_pins aclk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins lpddrmc_0/aclk0] \
  [get_bd_pins vio_0/clk] \
  [get_bd_pins sim_trig_0/pclk] \
  [get_bd_pins perf_axi_tg_0/pclk] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins lpddrmc_0/dbg_apb_clk] \
  [get_bd_pins system_ila_0/clk]
  connect_bd_net -net clk_wiz_0_clk_out2  [get_bd_pins clk] \
  [get_bd_pins perf_axi_tg_0/clk] \
  [get_bd_pins lpddrmc_0/aclk1]
  connect_bd_net -net lpddrmc_0_cal_done  [get_bd_pins lpddrmc_0/cal_done] \
  [get_bd_pins vio_0/probe_in2]
  connect_bd_net -net lpddrmc_0_cal_error  [get_bd_pins lpddrmc_0/cal_error] \
  [get_bd_pins vio_0/probe_in3]
  connect_bd_net -net lpddrmc_0_pll_lock  [get_bd_pins lpddrmc_0/pll_lock] \
  [get_bd_pins vio_0/probe_in4]
  connect_bd_net -net perf_axi_tg_0_axi_tg_done  [get_bd_pins perf_axi_tg_0/axi_tg_done] \
  [get_bd_pins sim_trig_0/all_done_00] \
  [get_bd_pins vio_0/probe_in0]
  connect_bd_net -net perf_axi_tg_0_axi_tg_error  [get_bd_pins perf_axi_tg_0/axi_tg_error] \
  [get_bd_pins vio_0/probe_in1]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins aresetn] \
  [get_bd_pins smartconnect_0/aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
  [get_bd_pins lpddrmc_0/apb_rst_n] \
  [get_bd_pins system_ila_0/resetn]
  connect_bd_net -net sim_trig_0_trig_00  [get_bd_pins sim_trig_0/trig_00] \
  [get_bd_pins perf_axi_tg_0/axi_tg_start]
  connect_bd_net -net vio_0_probe_out0  [get_bd_pins vio_0/probe_out0] \
  [get_bd_pins sim_trig_0/rst_n]
  connect_bd_net -net vio_0_probe_out1  [get_bd_pins vio_0/probe_out1] \
  [get_bd_pins perf_axi_tg_0/tg_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}
