# ########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

 # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################
#

# Create interface ports
  set CH0_DDR4_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 CH0_DDR4_0 ]

  set CLK_IN1_D_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 CLK_IN1_D_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $CLK_IN1_D_0

  set M00_AXI_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {42} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $M00_AXI_0

  set PCIE0_GT [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT ]

  set S00_AXI_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {44} \
   CONFIG.ARUSER_WIDTH {16} \
   CONFIG.AWUSER_WIDTH {16} \
   CONFIG.BUSER_WIDTH {16} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {1} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {16} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {16} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {16} \
   ] $S00_AXI_0

  set SYS_CLK0_IN_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 SYS_CLK0_IN_0 ]

  set S_AXI_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {12} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S_AXI_0

  set dma0_axis_c2h_status_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_c2h_status_rtl:1.0 dma0_axis_c2h_status_0 ]

  set dma0_c2h_byp_in_mm_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_c2h_byp_in_mm_0 ]

  set dma0_c2h_byp_in_st_csh_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_c2h_byp_in_st_csh_0 ]

  set dma0_c2h_byp_in_st_sim_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_c2h_byp_in_st_sim_0 ]

  set dma0_c2h_byp_out_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_c2h_byp_out_0 ]

  set dma0_dsc_crdt_in_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_crdt_in_rtl:1.0 dma0_dsc_crdt_in_0 ]

  set dma0_h2c_byp_in_mm_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_h2c_byp_in_mm_0 ]

  set dma0_h2c_byp_in_st_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_h2c_byp_in_st_0 ]

  set dma0_h2c_byp_out_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_dsc_byp_rtl:1.0 dma0_h2c_byp_out_0 ]

  set dma0_m_axis_h2c_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_qdma:m_axis_h2c_rtl:1.0 dma0_m_axis_h2c_0 ]

  set dma0_mgmt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:cpm_dma_mgmt_rtl:1.0 dma0_mgmt_0 ]

  set dma0_s_axis_c2h_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_qdma:s_axis_c2h_rtl:1.0 dma0_s_axis_c2h_0 ]

  set dma0_s_axis_c2h_cmpt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_qdma:s_axis_c2h_cmpt_rtl:1.0 dma0_s_axis_c2h_cmpt_0 ]

  set dma0_st_rx_msg_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 dma0_st_rx_msg_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $dma0_st_rx_msg_0

  set dma0_tm_dsc_sts_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_tm_dsc_sts_rtl:1.0 dma0_tm_dsc_sts_0 ]

  set dma0_usr_flr_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_usr_flr_rtl:1.0 dma0_usr_flr_0 ]

  set dma0_usr_irq_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_usr_irq_rtl:1.0 dma0_usr_irq_0 ]

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]


  # Create ports
  set cpm_cor_irq_0 [ create_bd_port -dir O -type intr cpm_cor_irq_0 ]
  set cpm_misc_irq_0 [ create_bd_port -dir O -type intr cpm_misc_irq_0 ]
  set cpm_uncor_irq_0 [ create_bd_port -dir O -type intr cpm_uncor_irq_0 ]
  set dbg_araddr [ create_bd_port -dir I -from 41 -to 0 -type data dbg_araddr ]
  set dbg_arready [ create_bd_port -dir I -type data dbg_arready ]
  set dbg_aruser [ create_bd_port -dir I -from 28 -to 0 -type data dbg_aruser ]
  set dbg_arvalid [ create_bd_port -dir I -type data dbg_arvalid ]
  set dbg_csr_addr [ create_bd_port -dir I -from 11 -to 0 -type data dbg_csr_addr ]
  set dbg_debug_fsm [ create_bd_port -dir I -from 19 -to 0 -type data dbg_debug_fsm ]
  set dbg_rdata [ create_bd_port -dir I -from 31 -to 0 -type data dbg_rdata ]
  set dbg_rready [ create_bd_port -dir I -type data dbg_rready ]
  set dbg_rresp [ create_bd_port -dir I -from 1 -to 0 -type data dbg_rresp ]
  set dbg_rvalid [ create_bd_port -dir I -type data dbg_rvalid ]
  set dbg_tm_avl [ create_bd_port -dir I -from 7 -to 0 -type data dbg_tm_avl ]
  set dbg_tm_byp [ create_bd_port -dir I -type data dbg_tm_byp ]
  set dbg_tm_dir [ create_bd_port -dir I -type data dbg_tm_dir ]
  set dbg_tm_error [ create_bd_port -dir I -type data dbg_tm_error ]
  set dbg_tm_irq_arm [ create_bd_port -dir I -type data dbg_tm_irq_arm ]
  set dbg_tm_mm [ create_bd_port -dir I -type data dbg_tm_mm ]
  set dbg_tm_qen [ create_bd_port -dir I -type data dbg_tm_qen ]
  set dbg_tm_qid [ create_bd_port -dir I -from 10 -to 0 -type data dbg_tm_qid ]
  set dbg_tm_qinv [ create_bd_port -dir I -type data dbg_tm_qinv ]
  set dbg_tm_rdy [ create_bd_port -dir I -type data dbg_tm_rdy ]
  set dbg_tm_vld [ create_bd_port -dir I -type data dbg_tm_vld ]
  set dma0_axi_aresetn_0 [ create_bd_port -dir O dma0_axi_aresetn_0 ]
  set dma0_soft_resetn_0 [ create_bd_port -dir I -type rst dma0_soft_resetn_0 ]
  set pcie0_user_clk_0 [ create_bd_port -dir O -type clk pcie0_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI_0:S_AXI_0:S00_AXI_0:dma0_s_axis_c2h_0:dma0_m_axis_h2c_0:dma0_st_rx_msg_0} \
   CONFIG.FREQ_HZ {250000000} \
 ] $pcie0_user_clk_0
  set pcie0_user_lnk_up_0 [ create_bd_port -dir O pcie0_user_lnk_up_0 ]
  set send_slave_rd [ create_bd_port -dir O -from 0 -to 0 send_slave_rd ]
  set send_slave_wr [ create_bd_port -dir O -from 0 -to 0 send_slave_wr ]
  set set_smid [ create_bd_port -dir O -from 15 -to 0 set_smid ]

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.ECC_TYPE {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: axi_dbg_hub_0, and set properties
  set axi_dbg_hub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dbg_hub axi_dbg_hub_0 ]
  set_property -dict [ list \
   CONFIG.C_AXI_DATA_WIDTH {128} \
   CONFIG.C_NUM_DEBUG_CORES {2} \
 ] $axi_dbg_hub_0

  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc axi_noc_0 ]
  set_property -dict [ list \
   CONFIG.CH0_DDR4_0_BOARD_INTERFACE {ddr4_dimm1} \
   CONFIG.LOGO_FILE {data/noc_mc.png} \
   CONFIG.MC0_CONFIG_NUM {config17} \
   CONFIG.MC1_CONFIG_NUM {config17} \
   CONFIG.MC2_CONFIG_NUM {config17} \
   CONFIG.MC3_CONFIG_NUM {config17} \
   CONFIG.MC_ADDR_BIT7 {CA3} \
   CONFIG.MC_ADDR_BIT8 {CA4} \
   CONFIG.MC_ADDR_BIT9 {CA5} \
   CONFIG.MC_ADDR_BIT10 {CA6} \
   CONFIG.MC_ADDR_BIT11 {CA7} \
   CONFIG.MC_ADDR_BIT12 {CA8} \
   CONFIG.MC_ADDR_BIT13 {CA9} \
   CONFIG.MC_ADDR_BIT14 {BG1} \
   CONFIG.MC_ADDR_BIT15 {BA0} \
   CONFIG.MC_ADDR_BIT16 {BA1} \
   CONFIG.MC_ADDR_BIT17 {RA0} \
   CONFIG.MC_ADDR_BIT18 {RA1} \
   CONFIG.MC_ADDR_BIT19 {RA2} \
   CONFIG.MC_ADDR_BIT20 {RA3} \
   CONFIG.MC_ADDR_BIT21 {RA4} \
   CONFIG.MC_ADDR_BIT22 {RA5} \
   CONFIG.MC_ADDR_BIT23 {RA6} \
   CONFIG.MC_ADDR_BIT24 {RA7} \
   CONFIG.MC_ADDR_BIT25 {RA8} \
   CONFIG.MC_ADDR_BIT26 {RA9} \
   CONFIG.MC_ADDR_BIT27 {RA10} \
   CONFIG.MC_ADDR_BIT28 {RA11} \
   CONFIG.MC_ADDR_BIT29 {RA12} \
   CONFIG.MC_ADDR_BIT30 {RA13} \
   CONFIG.MC_ADDR_BIT31 {RA14} \
   CONFIG.MC_ADDR_BIT32 {RA15} \
   CONFIG.MC_BG_WIDTH {2} \
   CONFIG.MC_BOARD_INTRF_EN {true} \
   CONFIG.MC_CASLATENCY {22} \
   CONFIG.MC_COMPONENT_WIDTH {x8} \
   CONFIG.MC_CONFIG_NUM {config17} \
   CONFIG.MC_DDR4_2T {Disable} \
   CONFIG.MC_DDR_INIT_TIMEOUT {0x00079C3E} \
   CONFIG.MC_ECC_SCRUB_SIZE {8192} \
   CONFIG.MC_F1_LPDDR4_MR1 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR2 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR3 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR11 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR13 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR22 {0x0000} \
   CONFIG.MC_F1_TFAW {21000} \
   CONFIG.MC_F1_TFAWMIN {21000} \
   CONFIG.MC_F1_TRCD {13750} \
   CONFIG.MC_F1_TRCDMIN {13750} \
   CONFIG.MC_F1_TRRD_L {8} \
   CONFIG.MC_F1_TRRD_L_MIN {8} \
   CONFIG.MC_F1_TRRD_S {4} \
   CONFIG.MC_F1_TRRD_S_MIN {4} \
   CONFIG.MC_INPUTCLK0_PERIOD {5000} \
   CONFIG.MC_INPUT_FREQUENCY0 {200.000} \
   CONFIG.MC_MEMORY_DENSITY {8GB} \
   CONFIG.MC_MEMORY_DEVICETYPE {UDIMMs} \
   CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
   CONFIG.MC_MEM_DEVICE_WIDTH {x8} \
   CONFIG.MC_TFAW {21000} \
   CONFIG.MC_TFAWMIN {21000} \
   CONFIG.MC_TFAW_nCK {34} \
   CONFIG.MC_TRC {45750} \
   CONFIG.MC_TRCD {13750} \
   CONFIG.MC_TRCDMIN {13750} \
   CONFIG.MC_TRCMIN {45750} \
   CONFIG.MC_TRP {13750} \
   CONFIG.MC_TRPMIN {13750} \
   CONFIG.MC_TRRD_L {8} \
   CONFIG.MC_TRRD_L_MIN {8} \
   CONFIG.MC_TRRD_S {4} \
   CONFIG.MC_TRRD_S_MIN {4} \
   CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-2BA-2BG-10CA} \
   CONFIG.NUM_CLKS {3} \
   CONFIG.NUM_MC {1} \
   CONFIG.NUM_MCP {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.sys_clk0_BOARD_INTERFACE {ddr4_dimm1_sma_clk} \
 ] $axi_noc_0

  set_property -dict [ list \
   CONFIG.APERTURES {{0x20800000000 0x40000000}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x40} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x40} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  # Create instance: axi_noc_1, and set properties
  set axi_noc_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc axi_noc_1 ]
  set_property -dict [ list \
   CONFIG.NUM_CLKS {2} \
 ] $axi_noc_1

  set_property -dict [ list \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_1/M00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {5} write_bw {5}} } \
   CONFIG.DEST_IDS {M00_AXI:0x80} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_1/S00_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_1/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI} \
 ] [get_bd_pins /axi_noc_1/aclk1]

  # Create instance: axis_ila_0, and set properties
  set axis_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila axis_ila_0 ]
  set_property -dict [ list \
   CONFIG.C_BRAM_CNT {5} \
   CONFIG.C_EN_AXIS_IF {1} \
   CONFIG.C_NUM_OF_PROBES {21} \
   CONFIG.C_PROBE0_WIDTH {42} \
   CONFIG.C_PROBE16_WIDTH {11} \
   CONFIG.C_PROBE17_WIDTH {8} \
   CONFIG.C_PROBE1_WIDTH {29} \
   CONFIG.C_PROBE4_WIDTH {32} \
   CONFIG.C_PROBE5_WIDTH {2} \
   CONFIG.C_PROBE8_WIDTH {20} \
   CONFIG.C_PROBE9_WIDTH {12} \
 ] $axis_ila_0

  # Create instance: axis_vio_0, and set properties
  set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio axis_vio_0 ]
  set_property -dict [ list \
   CONFIG.C_EN_AXIS_IF {1} \
   CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
   CONFIG.C_NUM_PROBE_IN {0} \
   CONFIG.C_NUM_PROBE_OUT {3} \
   CONFIG.C_PROBE_OUT2_WIDTH {16} \
 ] $axis_vio_0

  # Create instance: clk_gen_sim_0, and set properties
  set clk_gen_sim_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_gen_sim clk_gen_sim_0 ]
  set_property -dict [ list \
   CONFIG.USER_NUM_OF_AXI_CLK {0} \
   CONFIG.USER_NUM_OF_RESET {0} \
   CONFIG.USER_NUM_OF_SYS_CLK {1} \
   CONFIG.USER_SYS_CLK0_FREQ {200.000} \
   CONFIG.USER_SYS_CLK1_FREQ {200.000} \
 ] $clk_gen_sim_0

  # Create instance: clk_wizard_0, and set properties
  set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_0 ]
  set_property -dict [ list \
   CONFIG.CLKFBOUT_MULT {30.000000} \
   CONFIG.JITTER_SEL {Min_O_Jitter} \
   CONFIG.PRIM_IN_FREQ {100.000} \
   CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
   CONFIG.USE_PHASE_ALIGNMENT {true} \
 ] $clk_wizard_0

  # Create instance: ddr_responder_0, and set properties
  set ddr_responder_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr_responder ddr_responder_0 ]

  # Create instance: emb_mem_gen_0, and set properties
  set emb_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen emb_mem_gen_0 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_0

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.CPM_CONFIG {\
     CPM_DESIGN_USE_MODE {4}\
     CPM_PCIE0_ACS_CAP_ON {1} \
     CPM_PCIE0_ARI_CAP_ENABLED {1}\
     CPM_PCIE0_AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned}\
     CPM_PCIE0_AXISTEN_IF_ENABLE_CLIENT_TAG {1}\
     CPM_PCIE0_AXISTEN_IF_EXT_512_RC_STRADDLE {1}\
     CPM_PCIE0_AXISTEN_IF_EXT_512_RQ_STRADDLE {1}\
     CPM_PCIE0_AXISTEN_IF_RC_STRADDLE {1}\
     CPM_PCIE0_AXISTEN_IF_WIDTH {512}\
     CPM_PCIE0_BRIDGE_AXI_SLAVE_IF {1}\
     CPM_PCIE0_CONTROLLER_ENABLE {1}\
     CPM_PCIE0_COPY_PF0_ENABLED {1}\
     CPM_PCIE0_COPY_PF0_QDMA_ENABLED {0}\
     CPM_PCIE0_COPY_PF0_SRIOV_QDMA_ENABLED {0}\
     CPM_PCIE0_COPY_XDMA_PF0_ENABLED {1}\
     CPM_PCIE0_DMA_INTF {AXI_MM_and_AXI_Stream}\
     CPM_PCIE0_DSC_BYPASS_RD {1}\
     CPM_PCIE0_DSC_BYPASS_WR {1}\
     CPM_PCIE0_FUNCTIONAL_MODE {QDMA}\
     CPM_PCIE0_LINK_SPEED0_FOR_POWER {GEN4}\
     CPM_PCIE0_LINK_WIDTH0_FOR_POWER {8}\
     CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s}\
     CPM_PCIE0_MODE0_FOR_POWER {CPM_STREAM_W_DMA}\
     CPM_PCIE0_MODES {DMA}\
     CPM_PCIE0_MODE_SELECTION {Advanced}\
     CPM_PCIE0_MSIX_RP_ENABLED {0}\
     CPM_PCIE0_MSI_X_OPTIONS {MSI-X_Internal}\
     CPM_PCIE0_NUM_USR_IRQ {0}\
     CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_0 {0x0000000000000fff}\
     CPM_PCIE0_PF0_BAR0_64BIT {0}\
     CPM_PCIE0_PF0_BAR0_PREFETCHABLE {0}\
     CPM_PCIE0_PF0_BAR0_QDMA_SIZE {128}\
     CPM_PCIE0_PF0_BAR0_SIZE {128}\
     CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_SIZE {16}\
     CPM_PCIE0_PF0_BAR0_XDMA_64BIT {0}\
     CPM_PCIE0_PF0_BAR0_XDMA_ENABLED {0}\
     CPM_PCIE0_PF0_BAR0_XDMA_PREFETCHABLE {0}\
     CPM_PCIE0_PF0_BAR0_XDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF0_BAR0_XDMA_TYPE {AXI_Bridge_Master}\
     CPM_PCIE0_PF0_BAR2_64BIT {1}\
     CPM_PCIE0_PF0_BAR2_ENABLED {1}\
     CPM_PCIE0_PF0_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF0_BAR2_QDMA_64BIT {1}\
     CPM_PCIE0_PF0_BAR2_QDMA_ENABLED {1}\
     CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF0_BAR2_QDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF0_BAR2_QDMA_SIZE {4}\
     CPM_PCIE0_PF0_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF0_BAR2_SIZE {4}\
     CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_64BIT {1}\
     CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_ENABLED {1}\
     CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SIZE {4}\
     CPM_PCIE0_PF0_CFG_DEV_ID {B03F}\
     CPM_PCIE0_PF0_CLASS_CODE {0x058000}\
     CPM_PCIE0_PF0_DEV_CAP_EXT_TAG_EN {1}\
     CPM_PCIE0_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {1}\
     CPM_PCIE0_PF0_INTERFACE_VALUE {00}\
     CPM_PCIE0_PF0_MSIX_CAP_PBA_OFFSET {1400}\
     CPM_PCIE0_PF0_MSIX_CAP_TABLE_OFFSET {2000}\
     CPM_PCIE0_PF0_MSI_ENABLED {0}\
     CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000}\
     CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x0000020808000000}\
     CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020804000000}\
     CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000020808004000}\
     CPM_PCIE0_PF0_SRIOV_BAR0_64BIT {0}\
     CPM_PCIE0_PF0_SRIOV_BAR0_PREFETCHABLE {0}\
     CPM_PCIE0_PF0_SRIOV_BAR0_SIZE {16}\
     CPM_PCIE0_PF0_SRIOV_BAR2_64BIT {1}\
     CPM_PCIE0_PF0_SRIOV_BAR2_ENABLED {1}\
     CPM_PCIE0_PF0_SRIOV_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF0_SRIOV_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF0_SRIOV_BAR2_SIZE {4}\
     CPM_PCIE0_PF0_SRIOV_CAP_ENABLE {0}\
     CPM_PCIE0_PF0_SRIOV_CAP_INITIAL_VF {64}\
     CPM_PCIE0_PF0_SRIOV_SUPPORTED_PAGE_SIZE {00000553}\
     CPM_PCIE0_PF0_SRIOV_VF_DEVICE_ID {C03F}\
     CPM_PCIE0_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller}\
     CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1}\
     CPM_PCIE0_PF1_BAR0_64BIT {1}\
     CPM_PCIE0_PF1_BAR0_PREFETCHABLE {1}\
     CPM_PCIE0_PF1_BAR0_QDMA_64BIT {1}\
     CPM_PCIE0_PF1_BAR0_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF1_BAR0_QDMA_SIZE {128}\
     CPM_PCIE0_PF1_BAR0_SIZE {128}\
     CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_64BIT {1}\
     CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_SIZE {16}\
     CPM_PCIE0_PF1_BAR2_64BIT {1}\
     CPM_PCIE0_PF1_BAR2_ENABLED {1}\
     CPM_PCIE0_PF1_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF1_BAR2_QDMA_64BIT {1}\
     CPM_PCIE0_PF1_BAR2_QDMA_ENABLED {1}\
     CPM_PCIE0_PF1_BAR2_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF1_BAR2_QDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF1_BAR2_QDMA_SIZE {4}\
     CPM_PCIE0_PF1_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF1_BAR2_SIZE {4}\
     CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_64BIT {1}\
     CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_ENABLED {1}\
     CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SIZE {4}\
     CPM_PCIE0_PF1_BASE_CLASS_VALUE {05}\
     CPM_PCIE0_PF1_CFG_DEV_ID {B13F}\
     CPM_PCIE0_PF1_CLASS_CODE {0x058000}\
     CPM_PCIE0_PF1_INTERFACE_VALUE {00}\
     CPM_PCIE0_PF1_MSIX_CAP_PBA_OFFSET {1400}\
     CPM_PCIE0_PF1_MSIX_CAP_TABLE_OFFSET {2000}\
     CPM_PCIE0_PF1_MSI_ENABLED {0}\
     CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_0 {0x0000020801000000}\
     CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_2 {0x0000020808001000}\
     CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020805000000}\
     CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000020808044000}\
     CPM_PCIE0_PF1_SRIOV_BAR0_64BIT {1}\
     CPM_PCIE0_PF1_SRIOV_BAR0_PREFETCHABLE {1}\
     CPM_PCIE0_PF1_SRIOV_BAR0_SIZE {16}\
     CPM_PCIE0_PF1_SRIOV_BAR2_64BIT {1}\
     CPM_PCIE0_PF1_SRIOV_BAR2_ENABLED {1}\
     CPM_PCIE0_PF1_SRIOV_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF1_SRIOV_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF1_SRIOV_BAR2_SIZE {4}\
     CPM_PCIE0_PF1_SRIOV_CAP_ENABLE {0}\
     CPM_PCIE0_PF1_SRIOV_CAP_INITIAL_VF {64}\
     CPM_PCIE0_PF1_SRIOV_FIRST_VF_OFFSET {67}\
     CPM_PCIE0_PF1_SRIOV_FUNC_DEP_LINK {1}\
     CPM_PCIE0_PF1_SRIOV_SUPPORTED_PAGE_SIZE {00000553}\
     CPM_PCIE0_PF1_SRIOV_VF_DEVICE_ID {C13F}\
     CPM_PCIE0_PF1_SUB_CLASS_INTF_MENU {Other_memory_controller}\
     CPM_PCIE0_PF1_SUB_CLASS_VALUE {80}\
     CPM_PCIE0_PF1_USE_CLASS_CODE_LOOKUP_ASSISTANT {1}\
     CPM_PCIE0_PF2_BAR0_64BIT {1}\
     CPM_PCIE0_PF2_BAR0_PREFETCHABLE {1}\
     CPM_PCIE0_PF2_BAR0_QDMA_64BIT {1}\
     CPM_PCIE0_PF2_BAR0_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF2_BAR0_QDMA_SIZE {128}\
     CPM_PCIE0_PF2_BAR0_SIZE {128}\
     CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_64BIT {1}\
     CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_SIZE {16}\
     CPM_PCIE0_PF2_BAR2_64BIT {1}\
     CPM_PCIE0_PF2_BAR2_ENABLED {1}\
     CPM_PCIE0_PF2_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF2_BAR2_QDMA_64BIT {1}\
     CPM_PCIE0_PF2_BAR2_QDMA_ENABLED {1}\
     CPM_PCIE0_PF2_BAR2_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF2_BAR2_QDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF2_BAR2_QDMA_SIZE {4}\
     CPM_PCIE0_PF2_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF2_BAR2_SIZE {4}\
     CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_64BIT {1}\
     CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_ENABLED {1}\
     CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SIZE {4}\
     CPM_PCIE0_PF2_BASE_CLASS_VALUE {05}\
     CPM_PCIE0_PF2_CFG_DEV_ID {B23F}\
     CPM_PCIE0_PF2_CFG_SUBSYS_ID {7}\
     CPM_PCIE0_PF2_CFG_SUBSYS_VEND_ID {10EE}\
     CPM_PCIE0_PF2_CLASS_CODE {0x058000}\
     CPM_PCIE0_PF2_INTERFACE_VALUE {00}\
     CPM_PCIE0_PF2_MSIX_CAP_PBA_OFFSET {1400}\
     CPM_PCIE0_PF2_MSIX_CAP_TABLE_OFFSET {2000}\
     CPM_PCIE0_PF2_MSI_ENABLED {0}\
     CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_0 {0x0000020802000000}\
     CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_2 {0x0000020808002000}\
     CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020806000000}\
     CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000020808084000}\
     CPM_PCIE0_PF2_SRIOV_BAR0_64BIT {1}\
     CPM_PCIE0_PF2_SRIOV_BAR0_PREFETCHABLE {1}\
     CPM_PCIE0_PF2_SRIOV_BAR0_SIZE {16}\
     CPM_PCIE0_PF2_SRIOV_BAR2_64BIT {1}\
     CPM_PCIE0_PF2_SRIOV_BAR2_ENABLED {1}\
     CPM_PCIE0_PF2_SRIOV_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF2_SRIOV_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF2_SRIOV_BAR2_SIZE {4}\
     CPM_PCIE0_PF2_SRIOV_CAP_ENABLE {0}\
     CPM_PCIE0_PF2_SRIOV_CAP_INITIAL_VF {64}\
     CPM_PCIE0_PF2_SRIOV_FIRST_VF_OFFSET {130}\
     CPM_PCIE0_PF2_SRIOV_FUNC_DEP_LINK {2}\
     CPM_PCIE0_PF2_SRIOV_SUPPORTED_PAGE_SIZE {00000553}\
     CPM_PCIE0_PF2_SRIOV_VF_DEVICE_ID {C23F}\
     CPM_PCIE0_PF2_SUB_CLASS_INTF_MENU {Other_memory_controller}\
     CPM_PCIE0_PF2_SUB_CLASS_VALUE {80}\
     CPM_PCIE0_PF2_USE_CLASS_CODE_LOOKUP_ASSISTANT {1}\
     CPM_PCIE0_PF3_BAR0_64BIT {1}\
     CPM_PCIE0_PF3_BAR0_PREFETCHABLE {1}\
     CPM_PCIE0_PF3_BAR0_QDMA_64BIT {1}\
     CPM_PCIE0_PF3_BAR0_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF3_BAR0_QDMA_SIZE {128}\
     CPM_PCIE0_PF3_BAR0_SIZE {128}\
     CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_64BIT {1}\
     CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_SIZE {16}\
     CPM_PCIE0_PF3_BAR2_64BIT {1}\
     CPM_PCIE0_PF3_BAR2_ENABLED {1}\
     CPM_PCIE0_PF3_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF3_BAR2_QDMA_64BIT {1}\
     CPM_PCIE0_PF3_BAR2_QDMA_ENABLED {1}\
     CPM_PCIE0_PF3_BAR2_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF3_BAR2_QDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF3_BAR2_QDMA_SIZE {4}\
     CPM_PCIE0_PF3_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF3_BAR2_SIZE {4}\
     CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_64BIT {1}\
     CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_ENABLED {1}\
     CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_PREFETCHABLE {1}\
     CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SIZE {4}\
     CPM_PCIE0_PF3_BASE_CLASS_VALUE {05}\
     CPM_PCIE0_PF3_CFG_DEV_ID {B33F}\
     CPM_PCIE0_PF3_CFG_SUBSYS_ID {7}\
     CPM_PCIE0_PF3_CFG_SUBSYS_VEND_ID {10EE}\
     CPM_PCIE0_PF3_CLASS_CODE {0x058000}\
     CPM_PCIE0_PF3_INTERFACE_VALUE {00}\
     CPM_PCIE0_PF3_MSIX_CAP_PBA_OFFSET {1400}\
     CPM_PCIE0_PF3_MSIX_CAP_TABLE_OFFSET {2000}\
     CPM_PCIE0_PF3_MSI_ENABLED {0}\
     CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_0 {0x0000020803000000}\
     CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_2 {0x0000020808003000}\
     CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020807000000}\
     CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x00000208080C4000}\
     CPM_PCIE0_PF3_SRIOV_BAR0_64BIT {1}\
     CPM_PCIE0_PF3_SRIOV_BAR0_PREFETCHABLE {1}\
     CPM_PCIE0_PF3_SRIOV_BAR0_SIZE {16}\
     CPM_PCIE0_PF3_SRIOV_BAR2_64BIT {1}\
     CPM_PCIE0_PF3_SRIOV_BAR2_ENABLED {1}\
     CPM_PCIE0_PF3_SRIOV_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF3_SRIOV_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF3_SRIOV_BAR2_SIZE {4}\
     CPM_PCIE0_PF3_SRIOV_CAP_ENABLE {0}\
     CPM_PCIE0_PF3_SRIOV_CAP_INITIAL_VF {60}\
     CPM_PCIE0_PF3_SRIOV_FIRST_VF_OFFSET {193}\
     CPM_PCIE0_PF3_SRIOV_FUNC_DEP_LINK {3}\
     CPM_PCIE0_PF3_SRIOV_SUPPORTED_PAGE_SIZE {00000553}\
     CPM_PCIE0_PF3_SRIOV_VF_DEVICE_ID {C33F}\
     CPM_PCIE0_PF3_SUB_CLASS_INTF_MENU {Other_memory_controller}\
     CPM_PCIE0_PF3_SUB_CLASS_VALUE {80}\
     CPM_PCIE0_PF3_USE_CLASS_CODE_LOOKUP_ASSISTANT {1}\
     CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8}\
     CPM_PCIE0_SRIOV_CAP_ENABLE {1}\
     CPM_PCIE0_TL_PF_ENABLE_REG {4}\
     CPM_PCIE0_USER_CLK_FREQ {250_MHz}\
     CPM_PCIE0_VFG0_MSIX_CAP_PBA_OFFSET {280}\
     CPM_PCIE0_VFG0_MSIX_CAP_TABLE_OFFSET {400}\
     CPM_PCIE0_VFG0_MSIX_CAP_TABLE_SIZE {7}\
     CPM_PCIE0_VFG1_MSIX_CAP_PBA_OFFSET {280}\
     CPM_PCIE0_VFG1_MSIX_CAP_TABLE_OFFSET {400}\
     CPM_PCIE0_VFG1_MSIX_CAP_TABLE_SIZE {7}\
     CPM_PCIE0_VFG2_MSIX_CAP_PBA_OFFSET {280}\
     CPM_PCIE0_VFG2_MSIX_CAP_TABLE_OFFSET {400}\
     CPM_PCIE0_VFG2_MSIX_CAP_TABLE_SIZE {7}\
     CPM_PCIE0_VFG3_MSIX_CAP_PBA_OFFSET {280}\
     CPM_PCIE0_VFG3_MSIX_CAP_TABLE_OFFSET {400}\
     CPM_PCIE0_VFG3_MSIX_CAP_TABLE_SIZE {7}\
     CPM_PCIE1_AXISTEN_IF_EXT_512_RQ_STRADDLE {0}\
     CPM_PCIE1_AXISTEN_IF_RC_STRADDLE {0}\
     CPM_PCIE1_CORE_CLK_FREQ {250}\
     CPM_PCIE1_FUNCTIONAL_MODE {None}\
     CPM_PCIE1_MSI_X_OPTIONS {MSI-X_External}\
     CPM_PCIE1_PF0_CLASS_CODE {0x058000}\
     CPM_PCIE1_PF1_VEND_ID {0}\
     CPM_PCIE1_PF2_VEND_ID {0}\
     CPM_PCIE1_PF3_VEND_ID {0}\
     CPM_PCIE1_VFG0_MSIX_CAP_TABLE_SIZE {1}\
     CPM_PCIE1_VFG0_MSIX_ENABLED {0}\
     CPM_PCIE1_VFG1_MSIX_CAP_TABLE_SIZE {1}\
     CPM_PCIE1_VFG1_MSIX_ENABLED {0}\
     CPM_PCIE1_VFG2_MSIX_CAP_TABLE_SIZE {1}\
     CPM_PCIE1_VFG2_MSIX_ENABLED {0}\
     CPM_PCIE1_VFG3_MSIX_CAP_TABLE_SIZE {1}\
     CPM_PCIE1_VFG3_MSIX_ENABLED {0}\
     CPM_PCIE_CHANNELS_FOR_POWER {1}\
     CPM_PERIPHERAL_EN {1}\
     PS_USE_NOC_PS_PCI_0 {1}\
     PS_USE_PS_NOC_PCI_0 {1}\
     PS_USE_PS_NOC_PCI_1 {1}\
   } \
   CONFIG.PS_PMC_CONFIG {\
     PMC_CRP_OSPI_REF_CTRL_FREQMHZ {135}\
     PMC_OSPI_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 11}} {MODE Single}}\
     PS_CRL_UART0_REF_CTRL_ACT_FREQMHZ {99.999001}\
     PS_CRL_UART0_REF_CTRL_DIVISOR0 {12}\
     PS_CRL_UART0_REF_CTRL_SRCSEL {PPLL}\
     PS_CRL_UART1_REF_CTRL_DIVISOR0 {12}\
     PS_CRL_UART1_REF_CTRL_SRCSEL {PPLL}\
     PS_NUM_FABRIC_RESETS {1}\
     PS_PCIE_RESET {{ENABLE 1}}\
     PS_PCIE_EP_RESET1_IO {PMC_MIO 38}\
     PS_UART0_BAUD_RATE {115200}\
     PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 16 .. 17}}}\
     PS_UART1_BAUD_RATE {115200}\
     PS_UART1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 20 .. 21}}}\
     PS_USE_M_AXI_FPD {0}\
     PS_USE_M_AXI_LPD {1}\
     PS_USE_NOC_PS_PCI_0 {1}\
     PS_USE_PMCPL_CLK0 {0}\
     PS_USE_PS_NOC_PCI_0 {1}\
     PS_USE_PS_NOC_PCI_1 {1}\
     SMON_ALARMS {Set_Alarms_On}\
     SMON_ENABLE_TEMP_AVERAGING {0}\
     SMON_TEMP_AVERAGING_SAMPLES {0}\
     PS_BOARD_INTERFACE {Custom}\
     DESIGN_MODE {1}\
     PS_PCIE1_PERIPHERAL_ENABLE {1}\
     PS_PCIE2_PERIPHERAL_ENABLE {0}\
     PCIE_APERTURES_SINGLE_ENABLE {1}\
     PCIE_APERTURES_DUAL_ENABLE {0}\
   } \
   CONFIG.PS_PMC_CONFIG_APPLIED {1} \
 ] $versal_cips_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN1_D_0_1 [get_bd_intf_ports CLK_IN1_D_0] [get_bd_intf_pins clk_wizard_0/CLK_IN1_D]
  connect_bd_intf_net -intf_net S00_AXI_0_1 [get_bd_intf_ports S00_AXI_0] [get_bd_intf_pins axi_noc_1/S00_AXI]
  connect_bd_intf_net -intf_net SYS_CLK0_IN_0_1 [get_bd_intf_ports SYS_CLK0_IN_0] [get_bd_intf_pins clk_gen_sim_0/SYS_CLK0_IN]
  connect_bd_intf_net -intf_net S_AXI_0_1 [get_bd_intf_ports S_AXI_0] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins emb_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_dbg_hub_0_M00_AXIS [get_bd_intf_pins axi_dbg_hub_0/M00_AXIS] [get_bd_intf_pins axis_ila_0/S_AXIS]
  connect_bd_intf_net -intf_net axi_dbg_hub_0_M01_AXIS [get_bd_intf_pins axi_dbg_hub_0/M01_AXIS] [get_bd_intf_pins axis_vio_0/S_AXIS]
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_pins axi_noc_0/CH0_DDR4_0] [get_bd_intf_pins ddr_responder_0/CH0_IN_DDR4]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_noc_1_M00_AXI [get_bd_intf_pins axi_noc_1/M00_AXI] [get_bd_intf_pins versal_cips_0/NOC_CPM_PCIE_0]
  connect_bd_intf_net -intf_net axis_ila_0_M_AXIS [get_bd_intf_pins axi_dbg_hub_0/S00_AXIS] [get_bd_intf_pins axis_ila_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_vio_0_M_AXIS [get_bd_intf_pins axi_dbg_hub_0/S01_AXIS] [get_bd_intf_pins axis_vio_0/M_AXIS]
  connect_bd_intf_net -intf_net clk_gen_sim_0_SYS_CLK0 [get_bd_intf_pins axi_noc_0/sys_clk0] [get_bd_intf_pins clk_gen_sim_0/SYS_CLK0]
  connect_bd_intf_net -intf_net ddr_responder_0_CH0_DDR4 [get_bd_intf_ports CH0_DDR4_0] [get_bd_intf_pins ddr_responder_0/CH0_DDR4]
  connect_bd_intf_net -intf_net dma0_c2h_byp_in_mm_0_1 [get_bd_intf_ports dma0_c2h_byp_in_mm_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_in_mm]
  connect_bd_intf_net -intf_net dma0_c2h_byp_in_st_csh_0_1 [get_bd_intf_ports dma0_c2h_byp_in_st_csh_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_in_st_csh]
  connect_bd_intf_net -intf_net dma0_c2h_byp_in_st_sim_0_1 [get_bd_intf_ports dma0_c2h_byp_in_st_sim_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_in_st_sim]
  connect_bd_intf_net -intf_net dma0_dsc_crdt_in_0_1 [get_bd_intf_ports dma0_dsc_crdt_in_0] [get_bd_intf_pins versal_cips_0/dma0_dsc_crdt_in]
  connect_bd_intf_net -intf_net dma0_h2c_byp_in_mm_0_1 [get_bd_intf_ports dma0_h2c_byp_in_mm_0] [get_bd_intf_pins versal_cips_0/dma0_h2c_byp_in_mm]
  connect_bd_intf_net -intf_net dma0_h2c_byp_in_st_0_1 [get_bd_intf_ports dma0_h2c_byp_in_st_0] [get_bd_intf_pins versal_cips_0/dma0_h2c_byp_in_st]
  connect_bd_intf_net -intf_net dma0_mgmt_0_1 [get_bd_intf_ports dma0_mgmt_0] [get_bd_intf_pins versal_cips_0/dma0_mgmt]
  connect_bd_intf_net -intf_net dma0_s_axis_c2h_0_1 [get_bd_intf_ports dma0_s_axis_c2h_0] [get_bd_intf_pins versal_cips_0/dma0_s_axis_c2h]
  connect_bd_intf_net -intf_net dma0_s_axis_c2h_cmpt_0_1 [get_bd_intf_ports dma0_s_axis_c2h_cmpt_0] [get_bd_intf_pins versal_cips_0/dma0_s_axis_c2h_cmpt]
  connect_bd_intf_net -intf_net dma0_usr_flr_0_1 [get_bd_intf_ports dma0_usr_flr_0] [get_bd_intf_pins versal_cips_0/dma0_usr_flr]
  connect_bd_intf_net -intf_net dma0_usr_irq_0_1 [get_bd_intf_ports dma0_usr_irq_0] [get_bd_intf_pins versal_cips_0/dma0_usr_irq]
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins versal_cips_0/gt_refclk0]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_ports M00_AXI_0] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_GT_Serial_TX [get_bd_intf_ports PCIE0_GT] [get_bd_intf_pins versal_cips_0/PCIE0_GT]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_LPD [get_bd_intf_pins axi_dbg_hub_0/S_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_LPD]
  connect_bd_intf_net -intf_net versal_cips_0_NOC_CPM_PCIE_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_NOC_CPM_PCIE_1 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_axis_c2h_status [get_bd_intf_ports dma0_axis_c2h_status_0] [get_bd_intf_pins versal_cips_0/dma0_axis_c2h_status]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_c2h_byp_out [get_bd_intf_ports dma0_c2h_byp_out_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_out]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_h2c_byp_out [get_bd_intf_ports dma0_h2c_byp_out_0] [get_bd_intf_pins versal_cips_0/dma0_h2c_byp_out]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_m_axis_h2c [get_bd_intf_ports dma0_m_axis_h2c_0] [get_bd_intf_pins versal_cips_0/dma0_m_axis_h2c]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_st_rx_msg [get_bd_intf_ports dma0_st_rx_msg_0] [get_bd_intf_pins versal_cips_0/dma0_st_rx_msg]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_tm_dsc_sts [get_bd_intf_ports dma0_tm_dsc_sts_0] [get_bd_intf_pins versal_cips_0/dma0_tm_dsc_sts]

  # Create port connections
  connect_bd_net -net axis_vio_0_probe_out0 [get_bd_ports send_slave_rd] [get_bd_pins axis_vio_0/probe_out0]
  connect_bd_net -net axis_vio_0_probe_out1 [get_bd_ports send_slave_wr] [get_bd_pins axis_vio_0/probe_out1]
  connect_bd_net -net axis_vio_0_probe_out2 [get_bd_ports set_smid] [get_bd_pins axis_vio_0/probe_out2]
  connect_bd_net -net clk_wizard_0_clk_out1 [get_bd_pins axi_dbg_hub_0/aclk] [get_bd_pins axis_ila_0/aclk] [get_bd_pins axis_vio_0/aclk] [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins versal_cips_0/m_axi_lpd_aclk]
  connect_bd_net -net dbg_araddr_1 [get_bd_ports dbg_araddr] [get_bd_pins axis_ila_0/probe0]
  connect_bd_net -net dbg_arready_1 [get_bd_ports dbg_arready] [get_bd_pins axis_ila_0/probe3]
  connect_bd_net -net dbg_aruser_1 [get_bd_ports dbg_aruser] [get_bd_pins axis_ila_0/probe1]
  connect_bd_net -net dbg_arvalid_1 [get_bd_ports dbg_arvalid] [get_bd_pins axis_ila_0/probe2]
  connect_bd_net -net dbg_csr_addr_1 [get_bd_ports dbg_csr_addr] [get_bd_pins axis_ila_0/probe9]
  connect_bd_net -net dbg_debug_fsm_1 [get_bd_ports dbg_debug_fsm] [get_bd_pins axis_ila_0/probe8]
  connect_bd_net -net dbg_rdata_1 [get_bd_ports dbg_rdata] [get_bd_pins axis_ila_0/probe4]
  connect_bd_net -net dbg_rready_1 [get_bd_ports dbg_rready] [get_bd_pins axis_ila_0/probe7]
  connect_bd_net -net dbg_rresp_1 [get_bd_ports dbg_rresp] [get_bd_pins axis_ila_0/probe5]
  connect_bd_net -net dbg_rvalid_1 [get_bd_ports dbg_rvalid] [get_bd_pins axis_ila_0/probe6]
  connect_bd_net -net dbg_tm_avl_1 [get_bd_ports dbg_tm_avl] [get_bd_pins axis_ila_0/probe17]
  connect_bd_net -net dbg_tm_byp_1 [get_bd_ports dbg_tm_byp] [get_bd_pins axis_ila_0/probe12]
  connect_bd_net -net dbg_tm_dir_1 [get_bd_ports dbg_tm_dir] [get_bd_pins axis_ila_0/probe13]
  connect_bd_net -net dbg_tm_error_1 [get_bd_ports dbg_tm_error] [get_bd_pins axis_ila_0/probe15]
  connect_bd_net -net dbg_tm_irq_arm_1 [get_bd_ports dbg_tm_irq_arm] [get_bd_pins axis_ila_0/probe19]
  connect_bd_net -net dbg_tm_mm_1 [get_bd_ports dbg_tm_mm] [get_bd_pins axis_ila_0/probe14]
  connect_bd_net -net dbg_tm_qen_1 [get_bd_ports dbg_tm_qen] [get_bd_pins axis_ila_0/probe11]
  connect_bd_net -net dbg_tm_qid_1 [get_bd_ports dbg_tm_qid] [get_bd_pins axis_ila_0/probe16]
  connect_bd_net -net dbg_tm_qinv_1 [get_bd_ports dbg_tm_qinv] [get_bd_pins axis_ila_0/probe18]
  connect_bd_net -net dbg_tm_rdy_1 [get_bd_ports dbg_tm_rdy] [get_bd_pins axis_ila_0/probe20]
  connect_bd_net -net dbg_tm_vld_1 [get_bd_ports dbg_tm_vld] [get_bd_pins axis_ila_0/probe10]
  connect_bd_net -net dma0_soft_resetn_0_1 [get_bd_ports dma0_soft_resetn_0] [get_bd_pins versal_cips_0/dma0_soft_resetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dbg_hub_0/aresetn] [get_bd_pins axis_ila_0/aresetn] [get_bd_pins axis_vio_0/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net versal_cips_0_cpm_cor_irq [get_bd_ports cpm_cor_irq_0] [get_bd_pins versal_cips_0/cpm_cor_irq]
  connect_bd_net -net versal_cips_0_cpm_misc_irq [get_bd_ports cpm_misc_irq_0] [get_bd_pins versal_cips_0/cpm_misc_irq]
  connect_bd_net -net versal_cips_0_cpm_pcie_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_cpm_pcie_noc_axi1_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_cpm_uncor_irq [get_bd_ports cpm_uncor_irq_0] [get_bd_pins versal_cips_0/cpm_uncor_irq]
  connect_bd_net -net versal_cips_0_dma0_axi_aresetn [get_bd_ports dma0_axi_aresetn_0] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins versal_cips_0/dma0_axi_aresetn]
  connect_bd_net -net versal_cips_0_noc_cpm_pcie_axi0_clk [get_bd_pins axi_noc_1/aclk1] [get_bd_pins versal_cips_0/noc_cpm_pcie_axi0_clk]
  connect_bd_net -net versal_cips_0_pcie0_user_clk [get_bd_ports pcie0_user_clk_0] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_noc_0/aclk2] [get_bd_pins axi_noc_1/aclk0] [get_bd_pins axis_ila_0/clk] [get_bd_pins axis_vio_0/clk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins versal_cips_0/pcie0_user_clk]
  connect_bd_net -net versal_cips_0_pcie0_user_lnk_up [get_bd_ports pcie0_user_lnk_up_0] [get_bd_pins versal_cips_0/pcie0_user_lnk_up]
  connect_bd_net -net versal_cips_0_pl0_resetn [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins versal_cips_0/pl0_resetn]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins versal_cips_0/cpm_irq0] [get_bd_pins versal_cips_0/cpm_irq1] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  assign_bd_address -offset 0x020800000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs M00_AXI_0/Reg] -force
  assign_bd_address -offset 0x020800000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs M00_AXI_0/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_LPD] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXI_0] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force


  validate_bd_design
  save_bd_design


