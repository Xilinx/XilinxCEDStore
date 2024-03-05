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
  set const1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const1 ]

  # Create instance: fast_cosine, and set properties
  set fast_cosine [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 fast_cosine ]
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
  set fast_phase [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 fast_phase ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {0} \
   CONFIG.DOUT_WIDTH {16} \
 ] $fast_phase

  # Create instance: fast_sine, and set properties
  set fast_sine [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 fast_sine ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {16} \
   CONFIG.DOUT_WIDTH {16} \
 ] $fast_sine

  # Create instance: ila_fast_counter_0, and set properties 
  set ila_fast_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila:1.2 ila_fast_counter_0 ]
  set_property -dict [ list \
   CONFIG.ALL_PROBE_SAME_MU_CNT {4} \
   CONFIG.C_ADV_TRIGGER {true} \
   CONFIG.C_BRAM_CNT {12} \
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
  set ila_slow_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila:1.2 ila_slow_counter_0 ]
  set_property -dict [ list \
   CONFIG.ALL_PROBE_SAME_MU_CNT {4} \
   CONFIG.C_ADV_TRIGGER {true} \
   CONFIG.C_BRAM_CNT {12} \
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
  set slow_cosine [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slow_cosine ]
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
  set slow_phase [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slow_phase ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {0} \
   CONFIG.DOUT_WIDTH {16} \
 ] $slow_phase

  # Create instance: slow_sine, and set properties
  set slow_sine [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slow_sine ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {16} \
   CONFIG.DOUT_WIDTH {16} \
 ] $slow_sine

  # Create instance: vio_fast_counter_0, and set properties
  set vio_fast_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio:1.0 vio_fast_counter_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_OUT {5} \
   CONFIG.C_PROBE_IN0_WIDTH {32} \
   CONFIG.C_PROBE_OUT0_INIT_VAL {0x1} \
   CONFIG.C_PROBE_OUT2_INIT_VAL {0x1} \
   CONFIG.C_PROBE_OUT4_WIDTH {32} \
 ] $vio_fast_counter_0

  # Create instance: vio_slow_counter_0, and set properties
  set vio_slow_counter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio:1.0 vio_slow_counter_0 ]
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
  connect_bd_net -net ila_fast_counter_0_TRIG_IN_ack [get_bd_pins ila_fast_counter_0/TRIG_IN_ack] [get_bd_pins ila_fast_counter_0/probe9] [get_bd_pins ila_slow_counter_0/TRIG_OUT_ack] [get_bd_pins ila_slow_counter_0/probe7]
  connect_bd_net -net ila_fast_counter_0_TRIG_OUT_trig [get_bd_pins ila_fast_counter_0/TRIG_OUT_trig] [get_bd_pins ila_fast_counter_0/probe6] [get_bd_pins ila_slow_counter_0/TRIG_IN_trig] [get_bd_pins ila_slow_counter_0/probe8]
  connect_bd_net -net ila_slow_counter_0_TRIG_IN_ack [get_bd_pins ila_fast_counter_0/TRIG_OUT_ack] [get_bd_pins ila_fast_counter_0/probe7] [get_bd_pins ila_slow_counter_0/TRIG_IN_ack] [get_bd_pins ila_slow_counter_0/probe9]
  connect_bd_net -net ila_slow_counter_0_TRIG_OUT_trig [get_bd_pins ila_fast_counter_0/TRIG_IN_trig] [get_bd_pins ila_fast_counter_0/probe8] [get_bd_pins ila_slow_counter_0/TRIG_OUT_trig] [get_bd_pins ila_slow_counter_0/probe6]
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

# Hierarchical cell: noc_tg_bc
proc create_hier_cell_noc_tg_bc { parentCell nameHier } {
  

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_noc_tg_bc() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 SLOT_0_AXI


  # Create pins
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type clk pclk
  create_bd_pin -dir I -type rst rst_n

  # Create instance: axis_vio_0, and set properties
  set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio:1.0 axis_vio_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_IN {2} \
   CONFIG.C_NUM_PROBE_OUT {2} \
 ] $axis_vio_0

  # Create instance: noc_bc, and set properties
  set noc_bc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 noc_bc ]

  # Create instance: noc_bc_axis_ila_0, and set properties
  set noc_bc_axis_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila:1.2 noc_bc_axis_ila_0 ]
  set_property -dict [ list \
   CONFIG.ALL_PROBE_SAME_MU_CNT {2} \
   CONFIG.C_ADV_TRIGGER {true} \
   CONFIG.C_BRAM_CNT {0} \
   CONFIG.C_EN_STRG_QUAL {1} \
   CONFIG.C_INPUT_PIPE_STAGES {2} \
   CONFIG.C_MON_TYPE {Interface_Monitor} \
   CONFIG.C_PROBE0_MU_CNT {2} \
   CONFIG.C_SLOT_0_APC_EN {1} \
   CONFIG.C_SLOT_0_APC_STS_EN {1} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_TXN_CNTR_EN {1} \
 ] $noc_bc_axis_ila_0

  # Create instance: noc_bc_bram, and set properties
  set noc_bc_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 noc_bc_bram ]
  set_property -dict [ list \
   CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
 ] $noc_bc_bram

  # Create instance: noc_sim_trig, and set properties
  set noc_sim_trig [ create_bd_cell -type ip -vlnv xilinx.com:ip:sim_trig:1.0 noc_sim_trig ]
  set_property -dict [ list \
   CONFIG.USER_DEBUG_INTF {EXTERNAL_AXI4_LITE} \
   CONFIG.USER_TRAFFIC_SHAPING_EN {FALSE} \
 ] $noc_sim_trig

  # Create instance: noc_tg, and set properties
  set noc_tg [ create_bd_cell -type ip -vlnv xilinx.com:ip:perf_axi_tg:1.0 noc_tg ]
  set_property -dict [ list \
   CONFIG.USER_C_AXI_RDATA_WIDTH {512} \
   CONFIG.USER_C_AXI_READ_SIZE {1} \
   CONFIG.USER_C_AXI_WDATA_VALUE {\
0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000} \
   CONFIG.USER_C_AXI_WDATA_WIDTH {512} \
   CONFIG.USER_C_AXI_WRITE_SIZE {1} \
   CONFIG.USER_DEBUG_INTF {TRUE} \
   CONFIG.USER_PCLK_EN {TRUE} \
   CONFIG.USER_PERF_TG {SYNTHESIZABLE} \
   CONFIG.USER_SYNTH_DEFINED_PATTERN_CSV ${script_folder}/empty_traffic_spec.csv \
   CONFIG.USER_TRAFFIC_SHAPING_EN {FALSE} \
 ] $noc_tg

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net SLOT_0_AXI_1 [get_bd_intf_pins SLOT_0_AXI] [get_bd_intf_pins noc_bc/S_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets SLOT_0_AXI_1] [get_bd_intf_pins SLOT_0_AXI] [get_bd_intf_pins noc_bc_axis_ila_0/SLOT_0_AXI]
  connect_bd_intf_net -intf_net noc_bc_BRAM_PORTA [get_bd_intf_pins noc_bc/BRAM_PORTA] [get_bd_intf_pins noc_bc_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net noc_bc_BRAM_PORTB [get_bd_intf_pins noc_bc/BRAM_PORTB] [get_bd_intf_pins noc_bc_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net noc_sim_trig_MCSIO_OUT_00 [get_bd_intf_pins noc_sim_trig/MCSIO_OUT_00] [get_bd_intf_pins noc_tg/MCSIO_IN]
  connect_bd_intf_net -intf_net noc_tg_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins noc_tg/M_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins noc_sim_trig/AXI4_LITE] [get_bd_intf_pins smartconnect_0/M00_AXI]

  # Create port connections
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins noc_tg/clk]
  connect_bd_net -net noc_sim_trig_rst_n [get_bd_pins axis_vio_0/probe_out0] [get_bd_pins noc_sim_trig/rst_n]
  connect_bd_net -net noc_sim_trig_trig_00 [get_bd_pins noc_sim_trig/trig_00] [get_bd_pins noc_tg/axi_tg_start]
  connect_bd_net -net noc_tg_axi_tg_done [get_bd_pins axis_vio_0/probe_in0] [get_bd_pins noc_sim_trig/all_done_00] [get_bd_pins noc_tg/axi_tg_done]
  connect_bd_net -net noc_tg_axi_tg_error [get_bd_pins axis_vio_0/probe_in1] [get_bd_pins noc_tg/axi_tg_error]
  connect_bd_net -net noc_tg_tg_rst_n [get_bd_pins axis_vio_0/probe_out1] [get_bd_pins noc_tg/tg_rst_n]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins rst_n] [get_bd_pins noc_bc/s_axi_aresetn] [get_bd_pins noc_bc_axis_ila_0/resetn]
  connect_bd_net -net versal_cips_0_pl0_ref_clk [get_bd_pins pclk] [get_bd_pins axis_vio_0/clk] [get_bd_pins noc_bc/s_axi_aclk] [get_bd_pins noc_bc_axis_ila_0/clk] [get_bd_pins noc_sim_trig/pclk] [get_bd_pins noc_tg/pclk] [get_bd_pins smartconnect_0/aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: noc_tg_bc
proc create_hier_cell_hbm_noc_tg_bc { parentCell nameHier } {


  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_noc_tg_bc() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 SLOT_0_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 HBM00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 HBM01_AXI




  # Create pins
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type clk pclk
  create_bd_pin -dir I -type rst rst_n

  # Create instance: axis_vio_0, and set properties
  set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio:1.0 axis_vio_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_IN {6} \
   CONFIG.C_NUM_PROBE_OUT {4} \
 ] $axis_vio_0

  # Create instance: noc_bc, and set properties
  set noc_bc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 noc_bc ]

  # Create instance: noc_bc_axis_ila_0, and set properties
  set noc_bc_axis_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila:1.2 noc_bc_axis_ila_0 ]
  set_property -dict [ list \
   CONFIG.ALL_PROBE_SAME_MU_CNT {2} \
   CONFIG.C_ADV_TRIGGER {true} \
   CONFIG.C_BRAM_CNT {0} \
   CONFIG.C_EN_STRG_QUAL {1} \
   CONFIG.C_INPUT_PIPE_STAGES {2} \
   CONFIG.C_MON_TYPE {Interface_Monitor} \
   CONFIG.C_PROBE0_MU_CNT {2} \
   CONFIG.C_SLOT_0_APC_EN {1} \
   CONFIG.C_SLOT_0_APC_STS_EN {1} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_TXN_CNTR_EN {1} \
 ] $noc_bc_axis_ila_0

  # Create instance: noc_bc_bram, and set properties
  set noc_bc_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 noc_bc_bram ]
  set_property -dict [ list \
   CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
 ] $noc_bc_bram

  # Create instance: noc_sim_trig, and set properties
  set noc_sim_trig [ create_bd_cell -type ip -vlnv xilinx.com:ip:sim_trig:1.0 noc_sim_trig ]
  set_property -dict [ list \
   CONFIG.USER_DEBUG_INTF {EXTERNAL_AXI4_LITE} \
   CONFIG.USER_NUM_AXI_TG {3} \
   CONFIG.USER_TRAFFIC_SHAPING_EN {FALSE} \
 ] $noc_sim_trig


  # Create instance: ddr_tg, and set properties
  set ddr_tg [ create_bd_cell -type ip -vlnv xilinx.com:ip:perf_axi_tg:1.0 ddr_tg ]
  set_property -dict [list \
    CONFIG.USER_C_AXI_RDATA_WIDTH {512} \
    CONFIG.USER_C_AXI_READ_SIZE {1} \
    CONFIG.USER_C_AXI_WDATA_VALUE { 0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000} \
    CONFIG.USER_C_AXI_WDATA_WIDTH {512} \
    CONFIG.USER_C_AXI_WRITE_SIZE {1} \
    CONFIG.USER_DEBUG_INTF {TRUE} \
    CONFIG.USER_PERF_TG {SYNTHESIZABLE} \
    CONFIG.USER_SYNTH_DEFINED_PATTERN_CSV ${script_folder}/empty_traffic_spec.csv \
    CONFIG.USER_TRAFFIC_SHAPING_EN {FALSE} \
  ] $ddr_tg

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_0

  # Create instance: hbm_tg_0, and set properties
  set hbm_tg_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:perf_axi_tg:1.0 hbm_tg_0 ]
  set_property -dict [list \
    CONFIG.USER_C_AXI_RDATA_WIDTH {256} \
    CONFIG.USER_C_AXI_READ_SIZE {1} \
    CONFIG.USER_C_AXI_WDATA_VALUE { 0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000} \
    CONFIG.USER_C_AXI_WDATA_WIDTH {256} \
    CONFIG.USER_C_AXI_WRITE_SIZE {1} \
    CONFIG.USER_DEBUG_INTF {TRUE} \
    CONFIG.USER_EN_VIO_STATUS_MONITOR {TRUE} \
    CONFIG.USER_PERF_TG {SYNTHESIZABLE} \
    CONFIG.USER_SYNTH_DEFINED_PATTERN_CSV ${script_folder}/empty_traffic_spec.csv \
    CONFIG.USER_TRAFFIC_SHAPING_EN {FALSE} \
  ] $hbm_tg_0

  # Create instance: hbm_tg_1, and set properties
  set hbm_tg_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:perf_axi_tg:1.0 hbm_tg_1 ]
  set_property -dict [list \
    CONFIG.USER_C_AXI_RDATA_WIDTH {256} \
    CONFIG.USER_C_AXI_READ_SIZE {1} \
    CONFIG.USER_C_AXI_WDATA_VALUE { 0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000} \
    CONFIG.USER_C_AXI_WDATA_WIDTH {256} \
    CONFIG.USER_C_AXI_WRITE_SIZE {1} \
    CONFIG.USER_DEBUG_INTF {TRUE} \
    CONFIG.USER_PERF_TG {SYNTHESIZABLE} \
    CONFIG.USER_SYNTH_DEFINED_PATTERN_CSV ${script_folder}/empty_traffic_spec.csv \
    CONFIG.USER_TRAFFIC_SHAPING_EN {FALSE} \
  ] $hbm_tg_1

 # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net SLOT_0_AXI_1 [get_bd_intf_pins SLOT_0_AXI] [get_bd_intf_pins noc_bc/S_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets SLOT_0_AXI_1] [get_bd_intf_pins SLOT_0_AXI] [get_bd_intf_pins noc_bc_axis_ila_0/SLOT_0_AXI]
  connect_bd_intf_net -intf_net hbm_tg_0_M_AXI [get_bd_intf_pins HBM00_AXI] [get_bd_intf_pins hbm_tg_0/M_AXI]
  connect_bd_intf_net -intf_net hbm_tg_1_M_AXI [get_bd_intf_pins HBM01_AXI] [get_bd_intf_pins hbm_tg_1/M_AXI]
  connect_bd_intf_net -intf_net noc_bc_BRAM_PORTA [get_bd_intf_pins noc_bc/BRAM_PORTA] [get_bd_intf_pins noc_bc_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net noc_bc_BRAM_PORTB [get_bd_intf_pins noc_bc/BRAM_PORTB] [get_bd_intf_pins noc_bc_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net noc_sim_trig_MCSIO_OUT_00 [get_bd_intf_pins noc_sim_trig/MCSIO_OUT_00] [get_bd_intf_pins ddr_tg/MCSIO_IN]
  connect_bd_intf_net -intf_net noc_sim_trig_MCSIO_OUT_01 [get_bd_intf_pins noc_sim_trig/MCSIO_OUT_01] [get_bd_intf_pins hbm_tg_0/MCSIO_IN]
  connect_bd_intf_net -intf_net noc_sim_trig_MCSIO_OUT_02 [get_bd_intf_pins hbm_tg_1/MCSIO_IN] [get_bd_intf_pins noc_sim_trig/MCSIO_OUT_02]
  connect_bd_intf_net -intf_net noc_tg_M_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins ddr_tg/M_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins noc_sim_trig/AXI4_LITE] [get_bd_intf_pins smartconnect_0/M00_AXI]

  # Create port connections
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net axis_vio_0_probe_out2 [get_bd_pins axis_vio_0/probe_out2] [get_bd_pins hbm_tg_0/tg_rst_n]
  connect_bd_net -net axis_vio_0_probe_out3 [get_bd_pins axis_vio_0/probe_out3] [get_bd_pins hbm_tg_1/tg_rst_n]
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins ddr_tg/clk] [get_bd_pins hbm_tg_0/clk] [get_bd_pins hbm_tg_1/clk]
  connect_bd_net -net hbm_tg_0_axi_tg_done [get_bd_pins hbm_tg_0/axi_tg_done] [get_bd_pins axis_vio_0/probe_in2] [get_bd_pins noc_sim_trig/all_done_01]
  connect_bd_net -net hbm_tg_0_axi_tg_error [get_bd_pins hbm_tg_0/axi_tg_error] [get_bd_pins axis_vio_0/probe_in3]
  connect_bd_net -net hbm_tg_1_axi_tg_done [get_bd_pins hbm_tg_1/axi_tg_done] [get_bd_pins axis_vio_0/probe_in4] [get_bd_pins noc_sim_trig/all_done_02]
  connect_bd_net -net hbm_tg_1_axi_tg_error [get_bd_pins hbm_tg_1/axi_tg_error] [get_bd_pins axis_vio_0/probe_in5]
  connect_bd_net -net noc_sim_trig_rst_n [get_bd_pins axis_vio_0/probe_out0] [get_bd_pins noc_sim_trig/rst_n]
  connect_bd_net -net noc_sim_trig_trig_00 [get_bd_pins noc_sim_trig/trig_00] [get_bd_pins ddr_tg/axi_tg_start]
  connect_bd_net -net noc_sim_trig_trig_01 [get_bd_pins noc_sim_trig/trig_01] [get_bd_pins hbm_tg_0/axi_tg_start]
  connect_bd_net -net noc_sim_trig_trig_02 [get_bd_pins noc_sim_trig/trig_02] [get_bd_pins hbm_tg_1/axi_tg_start]
  connect_bd_net -net noc_tg_axi_tg_done [get_bd_pins ddr_tg/axi_tg_done] [get_bd_pins axis_vio_0/probe_in0] [get_bd_pins noc_sim_trig/all_done_00]
  connect_bd_net -net noc_tg_axi_tg_error [get_bd_pins ddr_tg/axi_tg_error] [get_bd_pins axis_vio_0/probe_in1]
  connect_bd_net -net noc_tg_tg_rst_n [get_bd_pins axis_vio_0/probe_out1] [get_bd_pins ddr_tg/tg_rst_n]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins rst_n] [get_bd_pins noc_bc/s_axi_aresetn] [get_bd_pins noc_bc_axis_ila_0/resetn]
  connect_bd_net -net versal_cips_0_pl0_ref_clk [get_bd_pins pclk] [get_bd_pins axis_vio_0/clk] [get_bd_pins noc_bc/s_axi_aclk] [get_bd_pins noc_bc_axis_ila_0/clk] [get_bd_pins noc_sim_trig/pclk] [get_bd_pins ddr_tg/pclk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins hbm_tg_0/pclk] [get_bd_pins hbm_tg_1/pclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}
