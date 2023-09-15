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
proc createDesign {design_name options} {  

  variable currentDir

##################################################################
# DESIGN PROCs													 
##################################################################
  
set_property target_language Verilog [current_project]

proc create_root_design { parentCell design_name temp_options} {

  puts "INFO: Start of create_root_design"
  set board_name [get_property BOARD_NAME [current_board]]
  set board_part [get_property NAME [current_board_part]]
  set fpga_part [get_property PART_NAME [current_board_part]]
  set board_rev [get_property COMPATIBLE_BOARD_REVISIONS [current_board]]
  puts "INFO: BOARD_NAME $board_name is selected"
  puts "INFO: BOARD_PART $board_part is selected"
  puts "INFO: PART_NAME $fpga_part is selected"

  ########################################################
  # START: Create all top level ports
  ########################################################

  # Create top level BD interface ports
  set M_AXIL [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXIL ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {42} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $M_AXIL

  if {[regexp "vpk120" $board_name]} { ;# CPM5
    set dma0_axis_c2h_dmawr [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_eqdma:axis_c2h_dmawr_rtl:1.0 dma0_axis_c2h_dmawr ]
    set dma0_qsts_out [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:eqdma_qsts_rtl:1.0 dma0_qsts_out ]
  }

  set dma0_axis_c2h_status [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_c2h_status_rtl:1.0 dma0_axis_c2h_status ]

  set dma0_dsc_crdt_in [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_dsc_crdt_in_rtl:1.0 dma0_dsc_crdt_in ]

  if {[regexp "vpk120" $board_name]} { ;# CPM5
    set dma0_m_axis_h2c [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_eqdma:m_axis_h2c_rtl:1.0 dma0_m_axis_h2c ]
    set dma0_s_axis_c2h [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:s_axis_c2h_rtl:1.0 dma0_s_axis_c2h ]
  set dma0_s_axis_c2h_cmpt [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:s_axis_c2h_cmpt_rtl:1.0 dma0_s_axis_c2h_cmpt ]
  } else { ;# CPM4
    set dma0_m_axis_h2c [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_qdma:m_axis_h2c_rtl:1.0 dma0_m_axis_h2c ]
    set dma0_s_axis_c2h [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_qdma:s_axis_c2h_rtl:1.0 dma0_s_axis_c2h ]
    set dma0_s_axis_c2h_cmpt [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_qdma:s_axis_c2h_cmpt_rtl:1.0 dma0_s_axis_c2h_cmpt ]
  }

  set dma0_st_rx_msg [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 dma0_st_rx_msg ]

  set dma0_tm_dsc_sts [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_tm_dsc_sts_rtl:1.0 dma0_tm_dsc_sts ]

  set pcie_gts [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_gts ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]

  # Create top level BD ports
  set dma0_axi_aresetn [ create_bd_port -dir O -type rst dma0_axi_aresetn ]
  if {[regexp "vpk120" $board_name]} { ;# CPM5
    set dma0_intrfc_resetn [ create_bd_port -dir I -type rst dma0_intrfc_resetn ]
    set peripheral_aresetn [ create_bd_port -dir O -type rst peripheral_aresetn ]
  } else { ;# CPM4
    set dma0_soft_resetn [ create_bd_port -dir I -type rst dma0_soft_resetn ]
    set pcie0_user_clk [ create_bd_port -dir O -type clk pcie0_user_clk ]
  }
  set pl0_ref_clk [ create_bd_port -dir O -type clk pl0_ref_clk ]
  if {[regexp "vpk120" $board_name]} { ;# CPM5
    set_property -dict [ list \
     CONFIG.ASSOCIATED_BUSIF {M_AXIL:dma0_st_rx_msg} \
    ] $pl0_ref_clk
  } else { ;# CPM4
    set_property -dict [ list \
     CONFIG.ASSOCIATED_BUSIF {M_AXIL:dma0_st_rx_msg} \
    ] $pcie0_user_clk
  }

  ########################################################
  # END: Create all top level ports
  ########################################################
  
  ########################################################
  # START: Create all instances and set their properties
  ########################################################

  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc axi_noc_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {4} \
    CONFIG.NUM_NMI {0} \
    CONFIG.NUM_SI {3} \
  ] $axi_noc_0

  if {[regexp "vpk120" $board_name]} { ;# CPM5
    set_property CONFIG.NUM_CLKS {5} $axi_noc_0
  } else { ;# CPM4
    set_property CONFIG.NUM_CLKS {6} $axi_noc_0
  }

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.APERTURES {{0x201_C000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
  ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.APERTURES {{0x202_4000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
  ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.APERTURES {{0x201_8000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
  ] [get_bd_intf_pins /axi_noc_0/M02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.CATEGORY {ps_pmc} \
  ] [get_bd_intf_pins /axi_noc_0/M03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.R_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.W_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.CONNECTIONS {M03_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {3000} write_bw {3000} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1000} write_bw {1000} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {3000} write_bw {3000}}} \
   CONFIG.DEST_IDS {M03_AXI:0x140:M01_AXI:0x40:M02_AXI:0x0:M00_AXI:0x80} \
   CONFIG.REMAPS {{ M00_AXI {{0x0 0x201_C000_0000 64K}}}} \
   CONFIG.CATEGORY {ps_pcie} \
  ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.R_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.W_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.CONNECTIONS {M03_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {3000} write_bw {3000} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1000} write_bw {1000} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {3000} write_bw {3000} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M03_AXI:0x140:M01_AXI:0x40:M02_AXI:0x0:M00_AXI:0x80} \
   CONFIG.REMAPS {{ M00_AXI {{0x0 0x201_C000_0000 64K}}}} \
   CONFIG.CATEGORY {ps_pcie} \
  ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x40:M02_AXI:0x0:M00_AXI:0x80} \
   CONFIG.REMAPS {{ M00_AXI {{0x0 0x201_C000_0000 64K}}}} \
   CONFIG.CATEGORY {ps_pmc} \
  ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
  ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
  ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
  ] [get_bd_pins /axi_noc_0/aclk2]

  if {[regexp "vpk120" $board_name]} { ;# CPM5
    set_property -dict [ list \
     CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI:M02_AXI} \
   ] [get_bd_pins /axi_noc_0/aclk3]
  } else { ;# CPM4
    set_property -dict [ list \
     CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI} \
   ] [get_bd_pins /axi_noc_0/aclk3]
    set_property -dict [ list \
     CONFIG.ASSOCIATED_BUSIF {M02_AXI} \
   ] [get_bd_pins /axi_noc_0/aclk5]
  }

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M03_AXI} \
  ] [get_bd_pins /axi_noc_0/aclk4]

  # Create instance: logic0, and set properties
  set logic0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant logic0 ]
  set_property CONFIG.CONST_VAL {0} $logic0

  # Create instance: logic1, and set properties
  set logic1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant logic1 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_1 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_1

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]

  # See schematic between VPK120 RevA01 vs RevB01
  # Only difference is PERST: PMC_MIO 38 vs PS_MIO 18
  if {[regexp "vpk120" $board_name]} { 
    if {[regexp "Rev B" $board_rev]} { ;# VPK120 Rev B
  
      set_property -dict [list \
        CONFIG.BOOT_MODE {Custom} \
        CONFIG.CLOCK_MODE {Custom} \
        CONFIG.CPM_CONFIG { \
          AURORA_LINE_RATE_GPBS {10.0} \
          BOOT_SECONDARY_PCIE_ENABLE {0} \
          CPM_A0_REFCLK {0} \
          CPM_A1_REFCLK {0} \
          CPM_AUX0_REF_CTRL_ACT_FREQMHZ {899.991028} \
          CPM_AUX0_REF_CTRL_DIVISOR0 {2} \
          CPM_AUX0_REF_CTRL_FREQMHZ {900} \
          CPM_AUX1_REF_CTRL_ACT_FREQMHZ {899.991028} \
          CPM_AUX1_REF_CTRL_DIVISOR0 {2} \
          CPM_AUX1_REF_CTRL_FREQMHZ {900} \
          CPM_AXI_SLV_BRIDGE_BASE_ADDRR_H {0x00000006} \
          CPM_AXI_SLV_BRIDGE_BASE_ADDRR_L {0x00000000} \
          CPM_AXI_SLV_MULTQ_BASE_ADDRR_H {0x00000006} \
          CPM_AXI_SLV_MULTQ_BASE_ADDRR_L {0x10000000} \
          CPM_AXI_SLV_XDMA_BASE_ADDRR_H {0x00000006} \
          CPM_AXI_SLV_XDMA_BASE_ADDRR_L {0x11000000} \
          CPM_CCIX_IS_MM_ONLY {0} \
          CPM_CCIX_PARTIAL_CACHELINE_SUPPORT {0} \
          CPM_CCIX_PORT_AGGREGATION_ENABLE {0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_0 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_1 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_2 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_3 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_4 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_5 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_6 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_7 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_0 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_1 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_2 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_3 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_4 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_5 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_6 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_7 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_0 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_1 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_2 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_3 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_4 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_5 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_6 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_7 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_REGION_0 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_1 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_2 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_3 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_4 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_5 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_6 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_7 {0} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_0 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_1 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_2 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_3 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_4 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_5 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_6 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_7 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_0 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_1 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_2 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_3 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_4 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_5 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_6 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_7 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_SELECT_AGENT {None} \
          CPM_CDO_EN {0} \
          CPM_CLRERR_LANE_MARGIN {0} \
          CPM_CORE_REF_CTRL_ACT_FREQMHZ {899.991028} \
          CPM_CORE_REF_CTRL_DIVISOR0 {2} \
          CPM_CORE_REF_CTRL_FREQMHZ {900} \
          CPM_CPLL_CTRL_FBDIV {108} \
          CPM_CPLL_CTRL_SRCSEL {REF_CLK} \
          CPM_DBG_REF_CTRL_ACT_FREQMHZ {299.997009} \
          CPM_DBG_REF_CTRL_DIVISOR0 {6} \
          CPM_DBG_REF_CTRL_FREQMHZ {300} \
          CPM_DESIGN_USE_MODE {4} \
          CPM_DMA_CREDIT_INIT_DEMUX {1} \
          CPM_DMA_IS_MM_ONLY {0} \
          CPM_LSBUS_REF_CTRL_ACT_FREQMHZ {149.998505} \
          CPM_LSBUS_REF_CTRL_DIVISOR0 {12} \
          CPM_LSBUS_REF_CTRL_FREQMHZ {150} \
          CPM_NUM_CCIX_CREDIT_LINKS {0} \
          CPM_NUM_HNF_AGENTS {0} \
          CPM_NUM_HOME_OR_SLAVE_AGENTS {0} \
          CPM_NUM_REQ_AGENTS {0} \
          CPM_NUM_SLAVE_AGENTS {0} \
          CPM_PCIE0_AER_CAP_ENABLED {1} \
          CPM_PCIE0_ARI_CAP_ENABLED {1} \
          CPM_PCIE0_ASYNC_MODE {SRNS} \
          CPM_PCIE0_ATS_PRI_CAP_ON {0} \
          CPM_PCIE0_AXIBAR_NUM {4} \
          CPM_PCIE0_AXISTEN_IF_CC_ALIGNMENT_MODE {Address_Aligned} \
          CPM_PCIE0_AXISTEN_IF_COMPL_TIMEOUT_REG0 {BEBC20} \
          CPM_PCIE0_AXISTEN_IF_COMPL_TIMEOUT_REG1 {2FAF080} \
          CPM_PCIE0_AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_256_TAGS {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_CLIENT_TAG {1} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_INTERNAL_MSIX_TABLE {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_MESSAGE_RID_CHECK {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_MSG_ROUTE {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_RX_MSG_INTFC {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_RX_TAG_SCALING {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_TX_TAG_SCALING {0} \
          CPM_PCIE0_AXISTEN_IF_EXTEND_CPL_TIMEOUT {16ms_to_1s} \
          CPM_PCIE0_AXISTEN_IF_EXT_512 {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_CC_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_CQ_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_RC_4TLP_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_RC_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_RQ_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_RC_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE0_AXISTEN_IF_RC_STRADDLE {1} \
          CPM_PCIE0_AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE0_AXISTEN_IF_RX_PARITY_EN {1} \
          CPM_PCIE0_AXISTEN_IF_SIM_SHORT_CPL_TIMEOUT {0} \
          CPM_PCIE0_AXISTEN_IF_TX_PARITY_EN {0} \
          CPM_PCIE0_AXISTEN_IF_WIDTH {512} \
          CPM_PCIE0_AXISTEN_MSIX_VECTORS_PER_FUNCTION {8} \
          CPM_PCIE0_AXISTEN_USER_SPARE {0} \
          CPM_PCIE0_BRIDGE_AXI_SLAVE_IF {0} \
          CPM_PCIE0_CCIX_EN {0} \
          CPM_PCIE0_CCIX_OPT_TLP_GEN_AND_RECEPT_EN_CONTROL_INTERNAL {0} \
          CPM_PCIE0_CCIX_VENDOR_ID {0} \
          CPM_PCIE0_CFG_CTL_IF {0} \
          CPM_PCIE0_CFG_EXT_IF {0} \
          CPM_PCIE0_CFG_FC_IF {0} \
          CPM_PCIE0_CFG_MGMT_IF {0} \
          CPM_PCIE0_CFG_SPEC_4_0 {0} \
          CPM_PCIE0_CFG_STS_IF {0} \
          CPM_PCIE0_CFG_VEND_ID {10EE} \
          CPM_PCIE0_CONTROLLER_ENABLE {1} \
          CPM_PCIE0_COPY_PF0_ENABLED {0} \
          CPM_PCIE0_COPY_PF0_QDMA_ENABLED {1} \
          CPM_PCIE0_COPY_PF0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_COPY_SRIOV_PF0_ENABLED {1} \
          CPM_PCIE0_COPY_XDMA_PF0_ENABLED {0} \
          CPM_PCIE0_CORE_CLK_FREQ {500} \
          CPM_PCIE0_CORE_EDR_CLK_FREQ {625} \
          CPM_PCIE0_DMA_DATA_WIDTH {512bits} \
          CPM_PCIE0_DMA_ENABLE_SECURE {0} \
          CPM_PCIE0_DMA_INTF {AXI_MM_and_AXI_Stream} \
          CPM_PCIE0_DMA_MASK {256bits} \
          CPM_PCIE0_DMA_METERING_ENABLE {1} \
          CPM_PCIE0_DMA_MSI_RX_PIN_ENABLED {FALSE} \
          CPM_PCIE0_DMA_ROOT_PORT {0} \
          CPM_PCIE0_DSC_BYPASS_RD {0} \
          CPM_PCIE0_DSC_BYPASS_WR {0} \
          CPM_PCIE0_EDR_IF {0} \
          CPM_PCIE0_EDR_LINK_SPEED {None} \
          CPM_PCIE0_EN_PARITY {0} \
          CPM_PCIE0_EXT_CFG_SPACE_MODE {None} \
          CPM_PCIE0_EXT_PCIE_CFG_SPACE_ENABLED {None} \
          CPM_PCIE0_FUNCTIONAL_MODE {QDMA} \
          CPM_PCIE0_LANE_REVERSAL_EN {1} \
          CPM_PCIE0_LEGACY_EXT_PCIE_CFG_SPACE_ENABLED {0} \
          CPM_PCIE0_LINK_DEBUG_AXIST_EN {0} \
          CPM_PCIE0_LINK_DEBUG_EN {0} \
          CPM_PCIE0_LINK_SPEED0_FOR_POWER {GEN4} \
          CPM_PCIE0_LINK_WIDTH0_FOR_POWER {8} \
          CPM_PCIE0_MAILBOX_ENABLE {0} \
          CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s} \
          CPM_PCIE0_MCAP_ENABLE {0} \
          CPM_PCIE0_MESG_RSVD_IF {0} \
          CPM_PCIE0_MESG_TRANSMIT_IF {0} \
          CPM_PCIE0_MODE0_FOR_POWER {CPM5_DMA} \
          CPM_PCIE0_MODES {DMA} \
          CPM_PCIE0_MODE_SELECTION {Advanced} \
          CPM_PCIE0_MSIX_RP_ENABLED {0} \
          CPM_PCIE0_MSI_X_OPTIONS {MSI-X_Internal} \
          CPM_PCIE0_NUM_USR_IRQ {0} \
          CPM_PCIE0_PASID_IF {0} \
          CPM_PCIE0_PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE {0} \
          CPM_PCIE0_PF0_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE0_PF0_ARI_CAP_VER {1} \
          CPM_PCIE0_PF0_ATS_CAP_ON {0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_0 {0x00000000E8000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_1 {0x0000000622000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_2 {0x0000000700000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_3 {0x0000008000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_0 {0x0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_1 {0x0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_2 {0x0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_3 {0x0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_0 {0x00000000EFFFFFFF} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_1 {0x0000000622FFFFFF} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_2 {0x000000070003FFFF} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_3 {0x0000008000000FFF} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE0_PF0_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE0_PF0_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE0_PF0_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE0_PF0_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE0_PF0_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE0_PF0_BAR0_64BIT {1} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_64BIT {0} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR0_ENABLED {1} \
          CPM_PCIE0_PF0_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR0_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_QDMA_SIZE {512} \
          CPM_PCIE0_PF0_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF0_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_SIZE {512} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_SIZE {32} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF0_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR0_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR0_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR1_64BIT {0} \
          CPM_PCIE0_PF0_BAR1_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR1_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR1_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR2_64BIT {1} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_64BIT {0} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR2_ENABLED {1} \
          CPM_PCIE0_PF0_BAR2_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF0_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_SIZE {64} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR2_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR3_64BIT {0} \
          CPM_PCIE0_PF0_BAR3_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR3_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR3_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR4_64BIT {1} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_64BIT {0} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR4_ENABLED {1} \
          CPM_PCIE0_PF0_BAR4_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF0_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_SIZE {64} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR4_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR4_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR4_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR4_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR5_64BIT {0} \
          CPM_PCIE0_PF0_BAR5_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR5_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR5_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR5_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR5_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE0_PF0_BASE_CLASS_VALUE {05} \
          CPM_PCIE0_PF0_CAPABILITY_POINTER {80} \
          CPM_PCIE0_PF0_CFG_DEV_ID {B03F} \
          CPM_PCIE0_PF0_CFG_REV_ID {0} \
          CPM_PCIE0_PF0_CFG_SUBSYS_ID {7} \
          CPM_PCIE0_PF0_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE0_PF0_CLASS_CODE {0x058000} \
          CPM_PCIE0_PF0_DEV_CAP_10B_TAG_EN {0} \
          CPM_PCIE0_PF0_DEV_CAP_ENDPOINT_L0S_LATENCY {less_than_64ns} \
          CPM_PCIE0_PF0_DEV_CAP_ENDPOINT_L1S_LATENCY {less_than_1us} \
          CPM_PCIE0_PF0_DEV_CAP_EXT_TAG_EN {1} \
          CPM_PCIE0_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {1} \
          CPM_PCIE0_PF0_DEV_CAP_MAX_PAYLOAD {512_bytes} \
          CPM_PCIE0_PF0_DLL_FEATURE_CAP_ID {0x0025} \
          CPM_PCIE0_PF0_DLL_FEATURE_CAP_ON {1} \
          CPM_PCIE0_PF0_DLL_FEATURE_CAP_VER {1} \
          CPM_PCIE0_PF0_DSN_CAP_ENABLE {0} \
          CPM_PCIE0_PF0_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE0_PF0_EXPANSION_ROM_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_EXPANSION_ROM_QDMA_SIZE {2} \
          CPM_PCIE0_PF0_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE0_PF0_INTERFACE_VALUE {00} \
          CPM_PCIE0_PF0_INTERRUPT_PIN {NONE} \
          CPM_PCIE0_PF0_LINK_CAP_ASPM_SUPPORT {No_ASPM} \
          CPM_PCIE0_PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {1} \
          CPM_PCIE0_PF0_MARGINING_CAP_ID {0} \
          CPM_PCIE0_PF0_MARGINING_CAP_ON {1} \
          CPM_PCIE0_PF0_MARGINING_CAP_VER {1} \
          CPM_PCIE0_PF0_MSIX_CAP_PBA_OFFSET {54000} \
          CPM_PCIE0_PF0_MSIX_CAP_TABLE_OFFSET {50000} \
          CPM_PCIE0_PF0_MSIX_CAP_TABLE_SIZE {7} \
          CPM_PCIE0_PF0_MSIX_ENABLED {1} \
          CPM_PCIE0_PF0_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE0_PF0_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE0_PF0_MSI_ENABLED {0} \
          CPM_PCIE0_PF0_PASID_CAP_MAX_PASID_WIDTH {1} \
          CPM_PCIE0_PF0_PASID_CAP_ON {0} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_0 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_1 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_2 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_3 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_2 {0xE0000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_4 {0x00000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_PL16_CAP_ID {0} \
          CPM_PCIE0_PF0_PL16_CAP_ON {1} \
          CPM_PCIE0_PF0_PL16_CAP_VER {1} \
          CPM_PCIE0_PF0_PM_CAP_ID {1} \
          CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D0 {1} \
          CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D1 {1} \
          CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D3COLD {1} \
          CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D3HOT {1} \
          CPM_PCIE0_PF0_PM_CAP_SUPP_D1_STATE {1} \
          CPM_PCIE0_PF0_PM_CAP_VER_ID {3} \
          CPM_PCIE0_PF0_PM_CSR_NOSOFTRESET {1} \
          CPM_PCIE0_PF0_PRI_CAP_ON {0} \
          CPM_PCIE0_PF0_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR0_64BIT {1} \
          CPM_PCIE0_PF0_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE0_PF0_SRIOV_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR0_SIZE {32} \
          CPM_PCIE0_PF0_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE0_PF0_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR1_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR2_64BIT {1} \
          CPM_PCIE0_PF0_SRIOV_BAR2_ENABLED {1} \
          CPM_PCIE0_PF0_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR2_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE0_PF0_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR3_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE0_PF0_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR4_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE0_PF0_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR5_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_PF0_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE0_PF0_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE0_PF0_SRIOV_CAP_VER {1} \
          CPM_PCIE0_PF0_SRIOV_FIRST_VF_OFFSET {16} \
          CPM_PCIE0_PF0_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE0_PF0_SRIOV_SUPPORTED_PAGE_SIZE {0x00000553} \
          CPM_PCIE0_PF0_SRIOV_VF_DEVICE_ID {C03F} \
          CPM_PCIE0_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE0_PF0_SUB_CLASS_VALUE {80} \
          CPM_PCIE0_PF0_TPHR_CAP_DEV_SPECIFIC_MODE {1} \
          CPM_PCIE0_PF0_TPHR_CAP_ENABLE {0} \
          CPM_PCIE0_PF0_TPHR_CAP_INT_VEC_MODE {1} \
          CPM_PCIE0_PF0_TPHR_CAP_ST_TABLE_LOC {ST_Table_not_present} \
          CPM_PCIE0_PF0_TPHR_CAP_ST_TABLE_SIZE {16} \
          CPM_PCIE0_PF0_TPHR_CAP_VER {1} \
          CPM_PCIE0_PF0_TPHR_ENABLE {0} \
          CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_PF0_VC_ARB_CAPABILITY {0} \
          CPM_PCIE0_PF0_VC_ARB_TBL_OFFSET {0} \
          CPM_PCIE0_PF0_VC_CAP_ENABLED {0} \
          CPM_PCIE0_PF0_VC_CAP_VER {1} \
          CPM_PCIE0_PF0_VC_EXTENDED_COUNT {0} \
          CPM_PCIE0_PF0_VC_LOW_PRIORITY_EXTENDED_COUNT {0} \
          CPM_PCIE0_PF0_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_XDMA_SIZE {128} \
          CPM_PCIE0_PF1_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE0_PF1_ATS_CAP_ON {0} \
          CPM_PCIE0_PF1_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE0_PF1_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE0_PF1_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE0_PF1_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE0_PF1_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE0_PF1_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE0_PF1_BAR0_64BIT {1} \
          CPM_PCIE0_PF1_BAR0_ENABLED {1} \
          CPM_PCIE0_PF1_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR0_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR0_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR0_QDMA_SIZE {512} \
          CPM_PCIE0_PF1_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF1_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR0_SIZE {512} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_SIZE {32} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF1_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR0_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR0_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR0_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR1_64BIT {0} \
          CPM_PCIE0_PF1_BAR1_ENABLED {0} \
          CPM_PCIE0_PF1_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR1_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR1_SIZE {4} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR1_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR1_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR2_64BIT {1} \
          CPM_PCIE0_PF1_BAR2_ENABLED {1} \
          CPM_PCIE0_PF1_BAR2_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR2_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF1_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR2_SIZE {64} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR2_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR2_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR3_64BIT {0} \
          CPM_PCIE0_PF1_BAR3_ENABLED {0} \
          CPM_PCIE0_PF1_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR3_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR3_SIZE {4} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR3_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR3_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR4_64BIT {1} \
          CPM_PCIE0_PF1_BAR4_ENABLED {1} \
          CPM_PCIE0_PF1_BAR4_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR4_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF1_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR4_SIZE {64} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR4_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR4_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR4_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR4_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR4_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR5_64BIT {0} \
          CPM_PCIE0_PF1_BAR5_ENABLED {0} \
          CPM_PCIE0_PF1_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR5_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR5_SIZE {4} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR5_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR5_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR5_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR5_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR5_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE0_PF1_BASE_CLASS_VALUE {05} \
          CPM_PCIE0_PF1_CAPABILITY_POINTER {80} \
          CPM_PCIE0_PF1_CFG_DEV_ID {B13F} \
          CPM_PCIE0_PF1_CFG_REV_ID {0} \
          CPM_PCIE0_PF1_CFG_SUBSYS_ID {7} \
          CPM_PCIE0_PF1_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE0_PF1_CLASS_CODE {0x000} \
          CPM_PCIE0_PF1_DSN_CAP_ENABLE {0} \
          CPM_PCIE0_PF1_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE0_PF1_EXPANSION_ROM_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_EXPANSION_ROM_QDMA_SIZE {2} \
          CPM_PCIE0_PF1_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE0_PF1_INTERFACE_VALUE {00} \
          CPM_PCIE0_PF1_INTERRUPT_PIN {NONE} \
          CPM_PCIE0_PF1_MSIX_CAP_PBA_BIR {BAR_1:0} \
          CPM_PCIE0_PF1_MSIX_CAP_PBA_OFFSET {54000} \
          CPM_PCIE0_PF1_MSIX_CAP_TABLE_BIR {BAR_1:0} \
          CPM_PCIE0_PF1_MSIX_CAP_TABLE_OFFSET {50000} \
          CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE {7} \
          CPM_PCIE0_PF1_MSIX_ENABLED {1} \
          CPM_PCIE0_PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE0_PF1_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE0_PF1_MSI_ENABLED {0} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF1_PRI_CAP_ON {0} \
          CPM_PCIE0_PF1_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR0_64BIT {1} \
          CPM_PCIE0_PF1_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE0_PF1_SRIOV_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR0_SIZE {32} \
          CPM_PCIE0_PF1_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE0_PF1_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR1_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR2_64BIT {1} \
          CPM_PCIE0_PF1_SRIOV_BAR2_ENABLED {1} \
          CPM_PCIE0_PF1_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR2_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE0_PF1_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR3_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE0_PF1_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR4_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE0_PF1_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR5_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_PF1_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE0_PF1_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE0_PF1_SRIOV_CAP_VER {1} \
          CPM_PCIE0_PF1_SRIOV_FIRST_VF_OFFSET {19} \
          CPM_PCIE0_PF1_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE0_PF1_SRIOV_SUPPORTED_PAGE_SIZE {0x00000553} \
          CPM_PCIE0_PF1_SRIOV_VF_DEVICE_ID {C13F} \
          CPM_PCIE0_PF1_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE0_PF1_SUB_CLASS_VALUE {80} \
          CPM_PCIE0_PF1_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_PF1_VEND_ID {0} \
          CPM_PCIE0_PF1_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_XDMA_SIZE {128} \
          CPM_PCIE0_PF2_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE0_PF2_ATS_CAP_ON {0} \
          CPM_PCIE0_PF2_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE0_PF2_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE0_PF2_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE0_PF2_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE0_PF2_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE0_PF2_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE0_PF2_BAR0_64BIT {1} \
          CPM_PCIE0_PF2_BAR0_ENABLED {1} \
          CPM_PCIE0_PF2_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR0_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR0_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR0_QDMA_SIZE {512} \
          CPM_PCIE0_PF2_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF2_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR0_SIZE {512} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_SIZE {32} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF2_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR0_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR0_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR0_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR1_64BIT {0} \
          CPM_PCIE0_PF2_BAR1_ENABLED {0} \
          CPM_PCIE0_PF2_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR1_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR1_SIZE {4} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR1_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR1_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR2_64BIT {1} \
          CPM_PCIE0_PF2_BAR2_ENABLED {1} \
          CPM_PCIE0_PF2_BAR2_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR2_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF2_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR2_SIZE {64} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR2_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR2_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR3_64BIT {0} \
          CPM_PCIE0_PF2_BAR3_ENABLED {0} \
          CPM_PCIE0_PF2_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR3_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR3_SIZE {4} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR3_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR3_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR4_64BIT {1} \
          CPM_PCIE0_PF2_BAR4_ENABLED {1} \
          CPM_PCIE0_PF2_BAR4_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR4_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF2_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR4_SIZE {64} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR4_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR4_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR4_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR4_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR4_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR5_64BIT {0} \
          CPM_PCIE0_PF2_BAR5_ENABLED {0} \
          CPM_PCIE0_PF2_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR5_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR5_SIZE {4} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR5_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR5_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR5_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR5_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR5_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE0_PF2_BASE_CLASS_VALUE {05} \
          CPM_PCIE0_PF2_CAPABILITY_POINTER {80} \
          CPM_PCIE0_PF2_CFG_DEV_ID {B23F} \
          CPM_PCIE0_PF2_CFG_REV_ID {0} \
          CPM_PCIE0_PF2_CFG_SUBSYS_ID {7} \
          CPM_PCIE0_PF2_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE0_PF2_CLASS_CODE {0x000} \
          CPM_PCIE0_PF2_DSN_CAP_ENABLE {0} \
          CPM_PCIE0_PF2_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE0_PF2_EXPANSION_ROM_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_EXPANSION_ROM_QDMA_SIZE {2} \
          CPM_PCIE0_PF2_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE0_PF2_INTERFACE_VALUE {00} \
          CPM_PCIE0_PF2_INTERRUPT_PIN {NONE} \
          CPM_PCIE0_PF2_MSIX_CAP_PBA_BIR {BAR_1:0} \
          CPM_PCIE0_PF2_MSIX_CAP_PBA_OFFSET {54000} \
          CPM_PCIE0_PF2_MSIX_CAP_TABLE_BIR {BAR_1:0} \
          CPM_PCIE0_PF2_MSIX_CAP_TABLE_OFFSET {50000} \
          CPM_PCIE0_PF2_MSIX_CAP_TABLE_SIZE {7} \
          CPM_PCIE0_PF2_MSIX_ENABLED {1} \
          CPM_PCIE0_PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE0_PF2_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE0_PF2_MSI_ENABLED {0} \
          CPM_PCIE0_PF2_PASID_CAP_MAX_PASID_WIDTH {1} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF2_PRI_CAP_ON {0} \
          CPM_PCIE0_PF2_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR0_64BIT {1} \
          CPM_PCIE0_PF2_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE0_PF2_SRIOV_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR0_SIZE {32} \
          CPM_PCIE0_PF2_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE0_PF2_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR1_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR2_64BIT {1} \
          CPM_PCIE0_PF2_SRIOV_BAR2_ENABLED {1} \
          CPM_PCIE0_PF2_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR2_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE0_PF2_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR3_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE0_PF2_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR4_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE0_PF2_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR5_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_PF2_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE0_PF2_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE0_PF2_SRIOV_CAP_VER {1} \
          CPM_PCIE0_PF2_SRIOV_FIRST_VF_OFFSET {22} \
          CPM_PCIE0_PF2_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE0_PF2_SRIOV_SUPPORTED_PAGE_SIZE {0x00000553} \
          CPM_PCIE0_PF2_SRIOV_VF_DEVICE_ID {C23F} \
          CPM_PCIE0_PF2_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE0_PF2_SUB_CLASS_VALUE {80} \
          CPM_PCIE0_PF2_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_PF2_VEND_ID {0} \
          CPM_PCIE0_PF2_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_XDMA_SIZE {128} \
          CPM_PCIE0_PF3_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE0_PF3_ATS_CAP_ON {0} \
          CPM_PCIE0_PF3_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE0_PF3_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE0_PF3_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE0_PF3_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE0_PF3_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE0_PF3_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE0_PF3_BAR0_64BIT {1} \
          CPM_PCIE0_PF3_BAR0_ENABLED {1} \
          CPM_PCIE0_PF3_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR0_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR0_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR0_QDMA_SIZE {512} \
          CPM_PCIE0_PF3_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF3_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR0_SIZE {512} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_SIZE {32} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF3_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR0_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR0_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR0_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR1_64BIT {0} \
          CPM_PCIE0_PF3_BAR1_ENABLED {0} \
          CPM_PCIE0_PF3_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR1_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR1_SIZE {4} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR1_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR1_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR2_64BIT {1} \
          CPM_PCIE0_PF3_BAR2_ENABLED {1} \
          CPM_PCIE0_PF3_BAR2_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR2_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF3_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR2_SIZE {64} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR2_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR2_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR3_64BIT {0} \
          CPM_PCIE0_PF3_BAR3_ENABLED {0} \
          CPM_PCIE0_PF3_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR3_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR3_SIZE {4} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR3_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR3_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR4_64BIT {1} \
          CPM_PCIE0_PF3_BAR4_ENABLED {1} \
          CPM_PCIE0_PF3_BAR4_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR4_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF3_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR4_SIZE {64} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR4_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR4_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR4_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR4_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR4_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR5_64BIT {0} \
          CPM_PCIE0_PF3_BAR5_ENABLED {0} \
          CPM_PCIE0_PF3_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR5_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR5_SIZE {4} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR5_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR5_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR5_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR5_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR5_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE0_PF3_BASE_CLASS_VALUE {05} \
          CPM_PCIE0_PF3_CAPABILITY_POINTER {80} \
          CPM_PCIE0_PF3_CFG_DEV_ID {B33F} \
          CPM_PCIE0_PF3_CFG_REV_ID {0} \
          CPM_PCIE0_PF3_CFG_SUBSYS_ID {7} \
          CPM_PCIE0_PF3_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE0_PF3_CLASS_CODE {0x000} \
          CPM_PCIE0_PF3_DSN_CAP_ENABLE {0} \
          CPM_PCIE0_PF3_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE0_PF3_EXPANSION_ROM_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_EXPANSION_ROM_QDMA_SIZE {2} \
          CPM_PCIE0_PF3_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE0_PF3_INTERFACE_VALUE {00} \
          CPM_PCIE0_PF3_INTERRUPT_PIN {NONE} \
          CPM_PCIE0_PF3_MSIX_CAP_PBA_BIR {BAR_1:0} \
          CPM_PCIE0_PF3_MSIX_CAP_PBA_OFFSET {54000} \
          CPM_PCIE0_PF3_MSIX_CAP_TABLE_BIR {BAR_1:0} \
          CPM_PCIE0_PF3_MSIX_CAP_TABLE_OFFSET {50000} \
          CPM_PCIE0_PF3_MSIX_CAP_TABLE_SIZE {7} \
          CPM_PCIE0_PF3_MSIX_ENABLED {1} \
          CPM_PCIE0_PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE0_PF3_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE0_PF3_MSI_ENABLED {0} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF3_PRI_CAP_ON {0} \
          CPM_PCIE0_PF3_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR0_64BIT {1} \
          CPM_PCIE0_PF3_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE0_PF3_SRIOV_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR0_SIZE {32} \
          CPM_PCIE0_PF3_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE0_PF3_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR1_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR2_64BIT {1} \
          CPM_PCIE0_PF3_SRIOV_BAR2_ENABLED {1} \
          CPM_PCIE0_PF3_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR2_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE0_PF3_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR3_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE0_PF3_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR4_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE0_PF3_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR5_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_PF3_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE0_PF3_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE0_PF3_SRIOV_CAP_VER {1} \
          CPM_PCIE0_PF3_SRIOV_FIRST_VF_OFFSET {25} \
          CPM_PCIE0_PF3_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE0_PF3_SRIOV_SUPPORTED_PAGE_SIZE {0x00000553} \
          CPM_PCIE0_PF3_SRIOV_VF_DEVICE_ID {C33F} \
          CPM_PCIE0_PF3_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE0_PF3_SUB_CLASS_VALUE {80} \
          CPM_PCIE0_PF3_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_PF3_VEND_ID {0} \
          CPM_PCIE0_PF3_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_XDMA_SIZE {128} \
          CPM_PCIE0_PL_LINK_CAP_MAX_LINK_SPEED {Gen3} \
          CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
          CPM_PCIE0_PL_UPSTREAM_FACING {1} \
          CPM_PCIE0_PL_USER_SPARE {0} \
          CPM_PCIE0_PM_ASPML0S_TIMEOUT {0} \
          CPM_PCIE0_PM_ASPML1_ENTRY_DELAY {0} \
          CPM_PCIE0_PM_ENABLE_L23_ENTRY {0} \
          CPM_PCIE0_PM_ENABLE_SLOT_POWER_CAPTURE {1} \
          CPM_PCIE0_PM_L1_REENTRY_DELAY {0} \
          CPM_PCIE0_PM_PME_TURNOFF_ACK_DELAY {0} \
          CPM_PCIE0_PORT_TYPE {PCI_Express_Endpoint_device} \
          CPM_PCIE0_QDMA_MULTQ_MAX {2048} \
          CPM_PCIE0_QDMA_PARITY_SETTINGS {None} \
          CPM_PCIE0_REF_CLK_FREQ {100_MHz} \
          CPM_PCIE0_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_SRIOV_FIRST_VF_OFFSET {16} \
          CPM_PCIE0_TANDEM {Tandem_PCIe} \
          CPM_PCIE0_TL2CFG_IF_PARITY_CHK {0} \
          CPM_PCIE0_TL_NP_FIFO_NUM_TLPS {0} \
          CPM_PCIE0_TL_PF_ENABLE_REG {1} \
          CPM_PCIE0_TL_POSTED_RAM_SIZE {0} \
          CPM_PCIE0_TL_USER_SPARE {0} \
          CPM_PCIE0_TX_FC_IF {0} \
          CPM_PCIE0_TYPE1_MEMBASE_MEMLIMIT_BRIDGE_ENABLE {Disabled} \
          CPM_PCIE0_TYPE1_MEMBASE_MEMLIMIT_ENABLE {Disabled} \
          CPM_PCIE0_TYPE1_PREFETCHABLE_MEMBASE_BRIDGE_MEMLIMIT {Disabled} \
          CPM_PCIE0_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT {Disabled} \
          CPM_PCIE0_USER_CLK2_FREQ {250_MHz} \
          CPM_PCIE0_USER_CLK_FREQ {250_MHz} \
          CPM_PCIE0_VC0_CAPABILITY_POINTER {80} \
          CPM_PCIE0_VC1_BASE_DISABLE {0} \
          CPM_PCIE0_VFG0_ATS_CAP_ON {0} \
          CPM_PCIE0_VFG0_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE0_VFG0_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE0_VFG0_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE0_VFG0_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE0_VFG0_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE0_VFG0_MSIX_ENABLED {0} \
          CPM_PCIE0_VFG0_PRI_CAP_ON {0} \
          CPM_PCIE0_VFG1_ATS_CAP_ON {0} \
          CPM_PCIE0_VFG1_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE0_VFG1_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE0_VFG1_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE0_VFG1_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE0_VFG1_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE0_VFG1_MSIX_ENABLED {0} \
          CPM_PCIE0_VFG1_PRI_CAP_ON {0} \
          CPM_PCIE0_VFG2_ATS_CAP_ON {0} \
          CPM_PCIE0_VFG2_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE0_VFG2_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE0_VFG2_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE0_VFG2_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE0_VFG2_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE0_VFG2_MSIX_ENABLED {0} \
          CPM_PCIE0_VFG2_PRI_CAP_ON {0} \
          CPM_PCIE0_VFG3_ATS_CAP_ON {0} \
          CPM_PCIE0_VFG3_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE0_VFG3_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE0_VFG3_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE0_VFG3_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE0_VFG3_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE0_VFG3_MSIX_ENABLED {0} \
          CPM_PCIE0_VFG3_PRI_CAP_ON {0} \
          CPM_PCIE0_XDMA_AXILITE_SLAVE_IF {0} \
          CPM_PCIE0_XDMA_AXI_ID_WIDTH {2} \
          CPM_PCIE0_XDMA_DSC_BYPASS_RD {0000} \
          CPM_PCIE0_XDMA_DSC_BYPASS_WR {0000} \
          CPM_PCIE0_XDMA_IRQ {1} \
          CPM_PCIE0_XDMA_PARITY_SETTINGS {None} \
          CPM_PCIE0_XDMA_RNUM_CHNL {4} \
          CPM_PCIE0_XDMA_RNUM_RIDS {2} \
          CPM_PCIE0_XDMA_STS_PORTS {0} \
          CPM_PCIE0_XDMA_WNUM_CHNL {4} \
          CPM_PCIE0_XDMA_WNUM_RIDS {2} \
          CPM_PCIE1_AER_CAP_ENABLED {1} \
          CPM_PCIE1_ARI_CAP_ENABLED {1} \
          CPM_PCIE1_ASYNC_MODE {SRNS} \
          CPM_PCIE1_ATS_PRI_CAP_ON {0} \
          CPM_PCIE1_AXIBAR_NUM {1} \
          CPM_PCIE1_AXISTEN_IF_CC_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE1_AXISTEN_IF_COMPL_TIMEOUT_REG0 {BEBC20} \
          CPM_PCIE1_AXISTEN_IF_COMPL_TIMEOUT_REG1 {2FAF080} \
          CPM_PCIE1_AXISTEN_IF_CQ_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_256_TAGS {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_CLIENT_TAG {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_INTERNAL_MSIX_TABLE {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_MESSAGE_RID_CHECK {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_MSG_ROUTE {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_RX_MSG_INTFC {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_RX_TAG_SCALING {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_TX_TAG_SCALING {0} \
          CPM_PCIE1_AXISTEN_IF_EXTEND_CPL_TIMEOUT {16ms_to_1s} \
          CPM_PCIE1_AXISTEN_IF_EXT_512 {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_CC_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_CQ_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_RC_4TLP_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_RC_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_RQ_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_RC_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE1_AXISTEN_IF_RC_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE1_AXISTEN_IF_RX_PARITY_EN {1} \
          CPM_PCIE1_AXISTEN_IF_SIM_SHORT_CPL_TIMEOUT {0} \
          CPM_PCIE1_AXISTEN_IF_TX_PARITY_EN {0} \
          CPM_PCIE1_AXISTEN_IF_WIDTH {64} \
          CPM_PCIE1_AXISTEN_MSIX_VECTORS_PER_FUNCTION {8} \
          CPM_PCIE1_AXISTEN_USER_SPARE {0} \
          CPM_PCIE1_CCIX_EN {0} \
          CPM_PCIE1_CCIX_OPT_TLP_GEN_AND_RECEPT_EN_CONTROL_INTERNAL {0} \
          CPM_PCIE1_CCIX_VENDOR_ID {0} \
          CPM_PCIE1_CFG_CTL_IF {0} \
          CPM_PCIE1_CFG_EXT_IF {0} \
          CPM_PCIE1_CFG_FC_IF {0} \
          CPM_PCIE1_CFG_MGMT_IF {0} \
          CPM_PCIE1_CFG_SPEC_4_0 {0} \
          CPM_PCIE1_CFG_STS_IF {0} \
          CPM_PCIE1_CFG_VEND_ID {10EE} \
          CPM_PCIE1_CONTROLLER_ENABLE {0} \
          CPM_PCIE1_COPY_PF0_ENABLED {0} \
          CPM_PCIE1_COPY_SRIOV_PF0_ENABLED {1} \
          CPM_PCIE1_CORE_CLK_FREQ {250} \
          CPM_PCIE1_CORE_EDR_CLK_FREQ {625} \
          CPM_PCIE1_DSC_BYPASS_RD {0} \
          CPM_PCIE1_DSC_BYPASS_WR {0} \
          CPM_PCIE1_EDR_IF {0} \
          CPM_PCIE1_EDR_LINK_SPEED {None} \
          CPM_PCIE1_EN_PARITY {0} \
          CPM_PCIE1_EXT_PCIE_CFG_SPACE_ENABLED {None} \
          CPM_PCIE1_FUNCTIONAL_MODE {None} \
          CPM_PCIE1_LANE_REVERSAL_EN {1} \
          CPM_PCIE1_LEGACY_EXT_PCIE_CFG_SPACE_ENABLED {0} \
          CPM_PCIE1_LINK_DEBUG_AXIST_EN {0} \
          CPM_PCIE1_LINK_DEBUG_EN {0} \
          CPM_PCIE1_LINK_SPEED1_FOR_POWER {GEN2} \
          CPM_PCIE1_LINK_WIDTH1_FOR_POWER {2} \
          CPM_PCIE1_MAX_LINK_SPEED {5.0_GT/s} \
          CPM_PCIE1_MCAP_ENABLE {0} \
          CPM_PCIE1_MESG_RSVD_IF {0} \
          CPM_PCIE1_MESG_TRANSMIT_IF {0} \
          CPM_PCIE1_MODE1_FOR_POWER {NONE} \
          CPM_PCIE1_MODES {None} \
          CPM_PCIE1_MODE_SELECTION {Basic} \
          CPM_PCIE1_MSIX_RP_ENABLED {1} \
          CPM_PCIE1_MSI_X_OPTIONS {MSI-X_External} \
          CPM_PCIE1_PASID_IF {0} \
          CPM_PCIE1_PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE {0} \
          CPM_PCIE1_PF0_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE1_PF0_ARI_CAP_VER {1} \
          CPM_PCIE1_PF0_ATS_CAP_ON {0} \
          CPM_PCIE1_PF0_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE1_PF0_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE1_PF0_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE1_PF0_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE1_PF0_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE1_PF0_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE1_PF0_BAR0_64BIT {0} \
          CPM_PCIE1_PF0_BAR0_ENABLED {1} \
          CPM_PCIE1_PF0_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR0_QDMA_AXCACHE {1} \
          CPM_PCIE1_PF0_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR0_SIZE {128} \
          CPM_PCIE1_PF0_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR0_XDMA_AXCACHE {1} \
          CPM_PCIE1_PF0_BAR1_64BIT {0} \
          CPM_PCIE1_PF0_BAR1_ENABLED {0} \
          CPM_PCIE1_PF0_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR1_SIZE {4} \
          CPM_PCIE1_PF0_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR2_64BIT {0} \
          CPM_PCIE1_PF0_BAR2_ENABLED {0} \
          CPM_PCIE1_PF0_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR2_SIZE {4} \
          CPM_PCIE1_PF0_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR3_64BIT {0} \
          CPM_PCIE1_PF0_BAR3_ENABLED {0} \
          CPM_PCIE1_PF0_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR3_SIZE {4} \
          CPM_PCIE1_PF0_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR4_64BIT {0} \
          CPM_PCIE1_PF0_BAR4_ENABLED {0} \
          CPM_PCIE1_PF0_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR4_SIZE {4} \
          CPM_PCIE1_PF0_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR5_64BIT {0} \
          CPM_PCIE1_PF0_BAR5_ENABLED {0} \
          CPM_PCIE1_PF0_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR5_SIZE {4} \
          CPM_PCIE1_PF0_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE1_PF0_BASE_CLASS_VALUE {05} \
          CPM_PCIE1_PF0_CAPABILITY_POINTER {80} \
          CPM_PCIE1_PF0_CFG_DEV_ID {B03F} \
          CPM_PCIE1_PF0_CFG_REV_ID {0} \
          CPM_PCIE1_PF0_CFG_SUBSYS_ID {7} \
          CPM_PCIE1_PF0_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE1_PF0_CLASS_CODE {0x058000} \
          CPM_PCIE1_PF0_DEV_CAP_10B_TAG_EN {0} \
          CPM_PCIE1_PF0_DEV_CAP_ENDPOINT_L0S_LATENCY {less_than_64ns} \
          CPM_PCIE1_PF0_DEV_CAP_ENDPOINT_L1S_LATENCY {less_than_1us} \
          CPM_PCIE1_PF0_DEV_CAP_EXT_TAG_EN {0} \
          CPM_PCIE1_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {0} \
          CPM_PCIE1_PF0_DEV_CAP_MAX_PAYLOAD {1024_bytes} \
          CPM_PCIE1_PF0_DLL_FEATURE_CAP_ID {0} \
          CPM_PCIE1_PF0_DLL_FEATURE_CAP_ON {0} \
          CPM_PCIE1_PF0_DLL_FEATURE_CAP_VER {1} \
          CPM_PCIE1_PF0_DSN_CAP_ENABLE {0} \
          CPM_PCIE1_PF0_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE1_PF0_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE1_PF0_INTERFACE_VALUE {00} \
          CPM_PCIE1_PF0_INTERRUPT_PIN {NONE} \
          CPM_PCIE1_PF0_LINK_CAP_ASPM_SUPPORT {No_ASPM} \
          CPM_PCIE1_PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {1} \
          CPM_PCIE1_PF0_MARGINING_CAP_ID {0} \
          CPM_PCIE1_PF0_MARGINING_CAP_ON {0} \
          CPM_PCIE1_PF0_MARGINING_CAP_VER {1} \
          CPM_PCIE1_PF0_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_PF0_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_PF0_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_PF0_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_PF0_MSIX_CAP_TABLE_SIZE {007} \
          CPM_PCIE1_PF0_MSIX_ENABLED {1} \
          CPM_PCIE1_PF0_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE1_PF0_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE1_PF0_MSI_ENABLED {1} \
          CPM_PCIE1_PF0_PASID_CAP_MAX_PASID_WIDTH {1} \
          CPM_PCIE1_PF0_PASID_CAP_ON {0} \
          CPM_PCIE1_PF0_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE1_PF0_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE1_PF0_PL16_CAP_ID {0} \
          CPM_PCIE1_PF0_PL16_CAP_ON {0} \
          CPM_PCIE1_PF0_PL16_CAP_VER {1} \
          CPM_PCIE1_PF0_PM_CAP_ID {1} \
          CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D0 {1} \
          CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D1 {1} \
          CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D3COLD {1} \
          CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D3HOT {1} \
          CPM_PCIE1_PF0_PM_CAP_SUPP_D1_STATE {1} \
          CPM_PCIE1_PF0_PM_CAP_VER_ID {3} \
          CPM_PCIE1_PF0_PM_CSR_NOSOFTRESET {1} \
          CPM_PCIE1_PF0_PRI_CAP_ON {0} \
          CPM_PCIE1_PF0_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR0_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE1_PF0_SRIOV_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR0_SIZE {2} \
          CPM_PCIE1_PF0_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR1_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR2_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR2_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR2_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR3_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR4_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR5_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_PF0_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE1_PF0_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE1_PF0_SRIOV_CAP_VER {1} \
          CPM_PCIE1_PF0_SRIOV_FIRST_VF_OFFSET {4} \
          CPM_PCIE1_PF0_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE1_PF0_SRIOV_SUPPORTED_PAGE_SIZE {553} \
          CPM_PCIE1_PF0_SRIOV_VF_DEVICE_ID {C03F} \
          CPM_PCIE1_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE1_PF0_SUB_CLASS_VALUE {80} \
          CPM_PCIE1_PF0_TPHR_CAP_DEV_SPECIFIC_MODE {1} \
          CPM_PCIE1_PF0_TPHR_CAP_ENABLE {0} \
          CPM_PCIE1_PF0_TPHR_CAP_INT_VEC_MODE {1} \
          CPM_PCIE1_PF0_TPHR_CAP_ST_TABLE_LOC {ST_Table_not_present} \
          CPM_PCIE1_PF0_TPHR_CAP_ST_TABLE_SIZE {16} \
          CPM_PCIE1_PF0_TPHR_CAP_VER {1} \
          CPM_PCIE1_PF0_TPHR_ENABLE {0} \
          CPM_PCIE1_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {0} \
          CPM_PCIE1_PF0_VC_ARB_CAPABILITY {0} \
          CPM_PCIE1_PF0_VC_ARB_TBL_OFFSET {0} \
          CPM_PCIE1_PF0_VC_CAP_ENABLED {0} \
          CPM_PCIE1_PF0_VC_CAP_VER {1} \
          CPM_PCIE1_PF0_VC_EXTENDED_COUNT {0} \
          CPM_PCIE1_PF0_VC_LOW_PRIORITY_EXTENDED_COUNT {0} \
          CPM_PCIE1_PF1_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE1_PF1_ATS_CAP_ON {0} \
          CPM_PCIE1_PF1_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE1_PF1_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE1_PF1_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE1_PF1_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE1_PF1_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE1_PF1_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE1_PF1_BAR0_64BIT {0} \
          CPM_PCIE1_PF1_BAR0_ENABLED {1} \
          CPM_PCIE1_PF1_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR0_QDMA_AXCACHE {1} \
          CPM_PCIE1_PF1_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR0_SIZE {128} \
          CPM_PCIE1_PF1_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR0_XDMA_AXCACHE {1} \
          CPM_PCIE1_PF1_BAR1_64BIT {0} \
          CPM_PCIE1_PF1_BAR1_ENABLED {0} \
          CPM_PCIE1_PF1_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR1_SIZE {4} \
          CPM_PCIE1_PF1_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR2_64BIT {0} \
          CPM_PCIE1_PF1_BAR2_ENABLED {0} \
          CPM_PCIE1_PF1_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR2_SIZE {4} \
          CPM_PCIE1_PF1_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR3_64BIT {0} \
          CPM_PCIE1_PF1_BAR3_ENABLED {0} \
          CPM_PCIE1_PF1_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR3_SIZE {4} \
          CPM_PCIE1_PF1_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR4_64BIT {0} \
          CPM_PCIE1_PF1_BAR4_ENABLED {0} \
          CPM_PCIE1_PF1_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR4_SIZE {4} \
          CPM_PCIE1_PF1_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR5_64BIT {0} \
          CPM_PCIE1_PF1_BAR5_ENABLED {0} \
          CPM_PCIE1_PF1_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR5_SIZE {4} \
          CPM_PCIE1_PF1_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE1_PF1_BASE_CLASS_VALUE {05} \
          CPM_PCIE1_PF1_CAPABILITY_POINTER {80} \
          CPM_PCIE1_PF1_CFG_DEV_ID {B13F} \
          CPM_PCIE1_PF1_CFG_REV_ID {0} \
          CPM_PCIE1_PF1_CFG_SUBSYS_ID {7} \
          CPM_PCIE1_PF1_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE1_PF1_CLASS_CODE {0x000} \
          CPM_PCIE1_PF1_DSN_CAP_ENABLE {0} \
          CPM_PCIE1_PF1_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE1_PF1_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE1_PF1_INTERFACE_VALUE {00} \
          CPM_PCIE1_PF1_INTERRUPT_PIN {NONE} \
          CPM_PCIE1_PF1_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_PF1_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_PF1_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_PF1_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_PF1_MSIX_CAP_TABLE_SIZE {007} \
          CPM_PCIE1_PF1_MSIX_ENABLED {1} \
          CPM_PCIE1_PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE1_PF1_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE1_PF1_MSI_ENABLED {0} \
          CPM_PCIE1_PF1_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE1_PF1_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE1_PF1_PRI_CAP_ON {0} \
          CPM_PCIE1_PF1_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR0_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE1_PF1_SRIOV_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR0_SIZE {2} \
          CPM_PCIE1_PF1_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR1_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR2_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR2_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR2_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR3_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR4_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR5_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_PF1_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE1_PF1_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE1_PF1_SRIOV_CAP_VER {1} \
          CPM_PCIE1_PF1_SRIOV_FIRST_VF_OFFSET {7} \
          CPM_PCIE1_PF1_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE1_PF1_SRIOV_SUPPORTED_PAGE_SIZE {553} \
          CPM_PCIE1_PF1_SRIOV_VF_DEVICE_ID {C13F} \
          CPM_PCIE1_PF1_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE1_PF1_SUB_CLASS_VALUE {80} \
          CPM_PCIE1_PF1_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE1_PF1_VEND_ID {0} \
          CPM_PCIE1_PF2_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE1_PF2_ATS_CAP_ON {0} \
          CPM_PCIE1_PF2_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE1_PF2_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE1_PF2_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE1_PF2_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE1_PF2_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE1_PF2_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE1_PF2_BAR0_64BIT {0} \
          CPM_PCIE1_PF2_BAR0_ENABLED {1} \
          CPM_PCIE1_PF2_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR0_QDMA_AXCACHE {1} \
          CPM_PCIE1_PF2_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR0_SIZE {128} \
          CPM_PCIE1_PF2_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR0_XDMA_AXCACHE {1} \
          CPM_PCIE1_PF2_BAR1_64BIT {0} \
          CPM_PCIE1_PF2_BAR1_ENABLED {0} \
          CPM_PCIE1_PF2_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR1_SIZE {4} \
          CPM_PCIE1_PF2_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR2_64BIT {0} \
          CPM_PCIE1_PF2_BAR2_ENABLED {0} \
          CPM_PCIE1_PF2_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR2_SIZE {4} \
          CPM_PCIE1_PF2_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR3_64BIT {0} \
          CPM_PCIE1_PF2_BAR3_ENABLED {0} \
          CPM_PCIE1_PF2_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR3_SIZE {4} \
          CPM_PCIE1_PF2_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR4_64BIT {0} \
          CPM_PCIE1_PF2_BAR4_ENABLED {0} \
          CPM_PCIE1_PF2_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR4_SIZE {4} \
          CPM_PCIE1_PF2_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR5_64BIT {0} \
          CPM_PCIE1_PF2_BAR5_ENABLED {0} \
          CPM_PCIE1_PF2_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR5_SIZE {4} \
          CPM_PCIE1_PF2_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE1_PF2_BASE_CLASS_VALUE {05} \
          CPM_PCIE1_PF2_CAPABILITY_POINTER {80} \
          CPM_PCIE1_PF2_CFG_DEV_ID {B23F} \
          CPM_PCIE1_PF2_CFG_REV_ID {0} \
          CPM_PCIE1_PF2_CFG_SUBSYS_ID {7} \
          CPM_PCIE1_PF2_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE1_PF2_CLASS_CODE {0x000} \
          CPM_PCIE1_PF2_DSN_CAP_ENABLE {0} \
          CPM_PCIE1_PF2_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE1_PF2_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE1_PF2_INTERFACE_VALUE {00} \
          CPM_PCIE1_PF2_INTERRUPT_PIN {NONE} \
          CPM_PCIE1_PF2_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_PF2_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_PF2_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_PF2_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_PF2_MSIX_CAP_TABLE_SIZE {007} \
          CPM_PCIE1_PF2_MSIX_ENABLED {1} \
          CPM_PCIE1_PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE1_PF2_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE1_PF2_MSI_ENABLED {0} \
          CPM_PCIE1_PF2_PASID_CAP_MAX_PASID_WIDTH {1} \
          CPM_PCIE1_PF2_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE1_PF2_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE1_PF2_PRI_CAP_ON {0} \
          CPM_PCIE1_PF2_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR0_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE1_PF2_SRIOV_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR0_SIZE {2} \
          CPM_PCIE1_PF2_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR1_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR2_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR2_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR2_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR3_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR4_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR5_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_PF2_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE1_PF2_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE1_PF2_SRIOV_CAP_VER {1} \
          CPM_PCIE1_PF2_SRIOV_FIRST_VF_OFFSET {10} \
          CPM_PCIE1_PF2_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE1_PF2_SRIOV_SUPPORTED_PAGE_SIZE {553} \
          CPM_PCIE1_PF2_SRIOV_VF_DEVICE_ID {C23F} \
          CPM_PCIE1_PF2_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE1_PF2_SUB_CLASS_VALUE {80} \
          CPM_PCIE1_PF2_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE1_PF2_VEND_ID {0} \
          CPM_PCIE1_PF3_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE1_PF3_ATS_CAP_ON {0} \
          CPM_PCIE1_PF3_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE1_PF3_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE1_PF3_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE1_PF3_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE1_PF3_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE1_PF3_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE1_PF3_BAR0_64BIT {0} \
          CPM_PCIE1_PF3_BAR0_ENABLED {1} \
          CPM_PCIE1_PF3_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR0_QDMA_AXCACHE {1} \
          CPM_PCIE1_PF3_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR0_SIZE {128} \
          CPM_PCIE1_PF3_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR0_XDMA_AXCACHE {1} \
          CPM_PCIE1_PF3_BAR1_64BIT {0} \
          CPM_PCIE1_PF3_BAR1_ENABLED {0} \
          CPM_PCIE1_PF3_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR1_SIZE {4} \
          CPM_PCIE1_PF3_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR2_64BIT {0} \
          CPM_PCIE1_PF3_BAR2_ENABLED {0} \
          CPM_PCIE1_PF3_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR2_SIZE {4} \
          CPM_PCIE1_PF3_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR3_64BIT {0} \
          CPM_PCIE1_PF3_BAR3_ENABLED {0} \
          CPM_PCIE1_PF3_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR3_SIZE {4} \
          CPM_PCIE1_PF3_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR4_64BIT {0} \
          CPM_PCIE1_PF3_BAR4_ENABLED {0} \
          CPM_PCIE1_PF3_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR4_SIZE {4} \
          CPM_PCIE1_PF3_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR5_64BIT {0} \
          CPM_PCIE1_PF3_BAR5_ENABLED {0} \
          CPM_PCIE1_PF3_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR5_SIZE {4} \
          CPM_PCIE1_PF3_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE1_PF3_BASE_CLASS_VALUE {05} \
          CPM_PCIE1_PF3_CAPABILITY_POINTER {80} \
          CPM_PCIE1_PF3_CFG_DEV_ID {B33F} \
          CPM_PCIE1_PF3_CFG_REV_ID {0} \
          CPM_PCIE1_PF3_CFG_SUBSYS_ID {7} \
          CPM_PCIE1_PF3_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE1_PF3_CLASS_CODE {0x000} \
          CPM_PCIE1_PF3_DSN_CAP_ENABLE {0} \
          CPM_PCIE1_PF3_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE1_PF3_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE1_PF3_INTERFACE_VALUE {00} \
          CPM_PCIE1_PF3_INTERRUPT_PIN {NONE} \
          CPM_PCIE1_PF3_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_PF3_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_PF3_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_PF3_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_PF3_MSIX_CAP_TABLE_SIZE {007} \
          CPM_PCIE1_PF3_MSIX_ENABLED {1} \
          CPM_PCIE1_PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE1_PF3_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE1_PF3_MSI_ENABLED {0} \
          CPM_PCIE1_PF3_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE1_PF3_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE1_PF3_PRI_CAP_ON {0} \
          CPM_PCIE1_PF3_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR0_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE1_PF3_SRIOV_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR0_SIZE {2} \
          CPM_PCIE1_PF3_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR1_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR2_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR2_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR2_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR3_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR4_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR5_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_PF3_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE1_PF3_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE1_PF3_SRIOV_CAP_VER {1} \
          CPM_PCIE1_PF3_SRIOV_FIRST_VF_OFFSET {13} \
          CPM_PCIE1_PF3_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE1_PF3_SRIOV_SUPPORTED_PAGE_SIZE {553} \
          CPM_PCIE1_PF3_SRIOV_VF_DEVICE_ID {C33F} \
          CPM_PCIE1_PF3_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE1_PF3_SUB_CLASS_VALUE {80} \
          CPM_PCIE1_PF3_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE1_PF3_VEND_ID {0} \
          CPM_PCIE1_PL_LINK_CAP_MAX_LINK_SPEED {Gen3} \
          CPM_PCIE1_PL_LINK_CAP_MAX_LINK_WIDTH {NONE} \
          CPM_PCIE1_PL_UPSTREAM_FACING {1} \
          CPM_PCIE1_PL_USER_SPARE {0} \
          CPM_PCIE1_PM_ASPML0S_TIMEOUT {0} \
          CPM_PCIE1_PM_ASPML1_ENTRY_DELAY {0} \
          CPM_PCIE1_PM_ENABLE_L23_ENTRY {0} \
          CPM_PCIE1_PM_ENABLE_SLOT_POWER_CAPTURE {1} \
          CPM_PCIE1_PM_L1_REENTRY_DELAY {0} \
          CPM_PCIE1_PM_PME_TURNOFF_ACK_DELAY {0} \
          CPM_PCIE1_PORT_TYPE {PCI_Express_Endpoint_device} \
          CPM_PCIE1_REF_CLK_FREQ {100_MHz} \
          CPM_PCIE1_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_SRIOV_FIRST_VF_OFFSET {4} \
          CPM_PCIE1_TL2CFG_IF_PARITY_CHK {0} \
          CPM_PCIE1_TL_NP_FIFO_NUM_TLPS {0} \
          CPM_PCIE1_TL_PF_ENABLE_REG {1} \
          CPM_PCIE1_TL_POSTED_RAM_SIZE {0} \
          CPM_PCIE1_TL_USER_SPARE {0} \
          CPM_PCIE1_TX_FC_IF {0} \
          CPM_PCIE1_TYPE1_MEMBASE_MEMLIMIT_ENABLE {Disabled} \
          CPM_PCIE1_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT {Disabled} \
          CPM_PCIE1_USER_CLK2_FREQ {125_MHz} \
          CPM_PCIE1_USER_CLK_FREQ {125_MHz} \
          CPM_PCIE1_VC0_CAPABILITY_POINTER {80} \
          CPM_PCIE1_VC1_BASE_DISABLE {0} \
          CPM_PCIE1_VFG0_ATS_CAP_ON {0} \
          CPM_PCIE1_VFG0_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_VFG0_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_VFG0_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_VFG0_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_VFG0_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE1_VFG0_MSIX_ENABLED {0} \
          CPM_PCIE1_VFG0_PRI_CAP_ON {0} \
          CPM_PCIE1_VFG1_ATS_CAP_ON {0} \
          CPM_PCIE1_VFG1_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_VFG1_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_VFG1_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_VFG1_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_VFG1_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE1_VFG1_MSIX_ENABLED {0} \
          CPM_PCIE1_VFG1_PRI_CAP_ON {0} \
          CPM_PCIE1_VFG2_ATS_CAP_ON {0} \
          CPM_PCIE1_VFG2_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_VFG2_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_VFG2_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_VFG2_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_VFG2_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE1_VFG2_MSIX_ENABLED {0} \
          CPM_PCIE1_VFG2_PRI_CAP_ON {0} \
          CPM_PCIE1_VFG3_ATS_CAP_ON {0} \
          CPM_PCIE1_VFG3_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_VFG3_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_VFG3_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_VFG3_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_VFG3_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE1_VFG3_MSIX_ENABLED {0} \
          CPM_PCIE1_VFG3_PRI_CAP_ON {0} \
          CPM_PCIE_CHANNELS_FOR_POWER {1} \
          CPM_PERIPHERAL_EN {1} \
          CPM_PERIPHERAL_TEST_EN {0} \
          CPM_REQ_AGENTS_0_ENABLE {0} \
          CPM_REQ_AGENTS_0_L2_ENABLE {0} \
          CPM_REQ_AGENTS_1_ENABLE {0} \
          CPM_SELECT_GTOUTCLK {TXOUTCLK} \
          CPM_TYPE1_MEMBASE_MEMLIMIT_ENABLE {Disabled} \
          CPM_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT {Disabled} \
          CPM_USE_MODES {None} \
          CPM_XDMA_2PF_INTERRUPT_ENABLE {0} \
          CPM_XDMA_TL_PF_VISIBLE {1} \
          CPM_XPIPE_0_CLKDLY_CFG {536870912} \
          CPM_XPIPE_0_CLK_CFG {1044480} \
          CPM_XPIPE_0_INSTANTIATED {1} \
          CPM_XPIPE_0_LINK0_CFG {X16} \
          CPM_XPIPE_0_LINK1_CFG {DISABLE} \
          CPM_XPIPE_0_LOC {QUAD0} \
          CPM_XPIPE_0_MODE {3} \
          CPM_XPIPE_0_REG_CFG {8164} \
          CPM_XPIPE_0_RSVD {16} \
          CPM_XPIPE_1_CLKDLY_CFG {570427392} \
          CPM_XPIPE_1_CLK_CFG {983040} \
          CPM_XPIPE_1_INSTANTIATED {1} \
          CPM_XPIPE_1_LINK0_CFG {X16} \
          CPM_XPIPE_1_LINK1_CFG {DISABLE} \
          CPM_XPIPE_1_LOC {QUAD0} \
          CPM_XPIPE_1_MODE {3} \
          CPM_XPIPE_1_REG_CFG {8155} \
          CPM_XPIPE_1_RSVD {16} \
          CPM_XPIPE_2_CLKDLY_CFG {50331778} \
          CPM_XPIPE_2_CLK_CFG {1044480} \
          CPM_XPIPE_2_INSTANTIATED {1} \
          CPM_XPIPE_2_LINK0_CFG {X16} \
          CPM_XPIPE_2_LINK1_CFG {DISABLE} \
          CPM_XPIPE_2_LOC {QUAD0} \
          CPM_XPIPE_2_MODE {3} \
          CPM_XPIPE_2_REG_CFG {8146} \
          CPM_XPIPE_2_RSVD {16} \
          CPM_XPIPE_3_CLKDLY_CFG {16777218} \
          CPM_XPIPE_3_CLK_CFG {1048320} \
          CPM_XPIPE_3_INSTANTIATED {1} \
          CPM_XPIPE_3_LINK0_CFG {X16} \
          CPM_XPIPE_3_LINK1_CFG {DISABLE} \
          CPM_XPIPE_3_LOC {QUAD0} \
          CPM_XPIPE_3_MODE {3} \
          CPM_XPIPE_3_REG_CFG {8137} \
          CPM_XPIPE_3_RSVD {16} \
          GT_REFCLK_MHZ {156.25} \
          PS_HSDP0_REFCLK {0} \
          PS_HSDP1_REFCLK {0} \
          PS_HSDP_EGRESS_TRAFFIC {JTAG} \
          PS_HSDP_INGRESS_TRAFFIC {JTAG} \
          PS_HSDP_MODE {NONE} \
          PS_USE_NOC_PS_PCI_0 {0} \
          PS_USE_PS_NOC_PCI_0 {1} \
          PS_USE_PS_NOC_PCI_1 {1} \
        } \
        CONFIG.DDR_MEMORY_MODE {Custom} \
        CONFIG.DEBUG_MODE {Custom} \
        CONFIG.DESIGN_MODE {1} \
        CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
        CONFIG.PS_PMC_CONFIG { \
          BOOT_MODE {Custom} \
          CLOCK_MODE {Custom} \
          DDR_MEMORY_MODE {Custom} \
          DEBUG_MODE {Custom} \
          DESIGN_MODE {1} \
          PCIE_APERTURES_DUAL_ENABLE {0} \
          PCIE_APERTURES_SINGLE_ENABLE {1} \
          PMC_CRP_PL0_REF_CTRL_FREQMHZ {200} \
          PMC_CRP_QSPI_REF_CTRL_FREQMHZ {150} \
          PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
          PMC_QSPI_PERIPHERAL_ENABLE {1} \
          PMC_QSPI_PERIPHERAL_MODE {Single} \
          PMC_USE_NOC_PMC_AXI0 {1} \
          PMC_USE_PMC_NOC_AXI0 {1} \
          PS_BOARD_INTERFACE {Custom} \
          PS_HSDP_INGRESS_TRAFFIC {JTAG} \
          PS_NUM_FABRIC_RESETS {1} \
          PS_PCIE1_PERIPHERAL_ENABLE {1} \
          PS_PCIE2_PERIPHERAL_ENABLE {0} \
          PS_PCIE_EP_RESET1_IO {PS_MIO 18} \
          PS_PCIE_RESET {{ENABLE 1}} \
          PS_PL_CONNECTIVITY_MODE {Custom} \
          PS_USE_M_AXI_LPD {0} \
          PS_USE_PMCPL_CLK0 {1} \
          SMON_ALARMS {Set_Alarms_On} \
          SMON_ENABLE_TEMP_AVERAGING {0} \
          SMON_TEMP_AVERAGING_SAMPLES {0} \
        } \
        CONFIG.PS_PMC_CONFIG_APPLIED {1} \
      ] $versal_cips_0
  
    } else { ;# VPK120 RevA
  
      set_property -dict [list \
        CONFIG.BOOT_MODE {Custom} \
        CONFIG.CLOCK_MODE {Custom} \
        CONFIG.CPM_CONFIG { \
          AURORA_LINE_RATE_GPBS {10.0} \
          BOOT_SECONDARY_PCIE_ENABLE {0} \
          CPM_A0_REFCLK {0} \
          CPM_A1_REFCLK {0} \
          CPM_AUX0_REF_CTRL_ACT_FREQMHZ {899.991028} \
          CPM_AUX0_REF_CTRL_DIVISOR0 {2} \
          CPM_AUX0_REF_CTRL_FREQMHZ {900} \
          CPM_AUX1_REF_CTRL_ACT_FREQMHZ {899.991028} \
          CPM_AUX1_REF_CTRL_DIVISOR0 {2} \
          CPM_AUX1_REF_CTRL_FREQMHZ {900} \
          CPM_AXI_SLV_BRIDGE_BASE_ADDRR_H {0x00000006} \
          CPM_AXI_SLV_BRIDGE_BASE_ADDRR_L {0x00000000} \
          CPM_AXI_SLV_MULTQ_BASE_ADDRR_H {0x00000006} \
          CPM_AXI_SLV_MULTQ_BASE_ADDRR_L {0x10000000} \
          CPM_AXI_SLV_XDMA_BASE_ADDRR_H {0x00000006} \
          CPM_AXI_SLV_XDMA_BASE_ADDRR_L {0x11000000} \
          CPM_CCIX_IS_MM_ONLY {0} \
          CPM_CCIX_PARTIAL_CACHELINE_SUPPORT {0} \
          CPM_CCIX_PORT_AGGREGATION_ENABLE {0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_0 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_1 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_2 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_3 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_4 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_5 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_6 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_AGENT_TYPE_7 {HA0} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_0 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_1 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_2 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_3 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_4 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_5 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_6 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_ATTRIB_7 {Normal_Non_Cacheable_Memory} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_0 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_1 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_2 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_3 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_4 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_5 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_6 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_BASEADDRESS_7 {0x00000000} \
          CPM_CCIX_RSVRD_MEMORY_REGION_0 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_1 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_2 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_3 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_4 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_5 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_6 {0} \
          CPM_CCIX_RSVRD_MEMORY_REGION_7 {0} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_0 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_1 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_2 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_3 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_4 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_5 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_6 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_SIZE_7 {4GB} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_0 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_1 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_2 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_3 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_4 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_5 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_6 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_RSVRD_MEMORY_TYPE_7 {Other_or_Non_Specified_Memory_Type} \
          CPM_CCIX_SELECT_AGENT {None} \
          CPM_CDO_EN {0} \
          CPM_CLRERR_LANE_MARGIN {0} \
          CPM_CORE_REF_CTRL_ACT_FREQMHZ {899.991028} \
          CPM_CORE_REF_CTRL_DIVISOR0 {2} \
          CPM_CORE_REF_CTRL_FREQMHZ {900} \
          CPM_CPLL_CTRL_FBDIV {108} \
          CPM_CPLL_CTRL_SRCSEL {REF_CLK} \
          CPM_DBG_REF_CTRL_ACT_FREQMHZ {299.997009} \
          CPM_DBG_REF_CTRL_DIVISOR0 {6} \
          CPM_DBG_REF_CTRL_FREQMHZ {300} \
          CPM_DESIGN_USE_MODE {4} \
          CPM_DMA_CREDIT_INIT_DEMUX {1} \
          CPM_DMA_IS_MM_ONLY {0} \
          CPM_LSBUS_REF_CTRL_ACT_FREQMHZ {149.998505} \
          CPM_LSBUS_REF_CTRL_DIVISOR0 {12} \
          CPM_LSBUS_REF_CTRL_FREQMHZ {150} \
          CPM_NUM_CCIX_CREDIT_LINKS {0} \
          CPM_NUM_HNF_AGENTS {0} \
          CPM_NUM_HOME_OR_SLAVE_AGENTS {0} \
          CPM_NUM_REQ_AGENTS {0} \
          CPM_NUM_SLAVE_AGENTS {0} \
          CPM_PCIE0_AER_CAP_ENABLED {1} \
          CPM_PCIE0_ARI_CAP_ENABLED {1} \
          CPM_PCIE0_ASYNC_MODE {SRNS} \
          CPM_PCIE0_ATS_PRI_CAP_ON {0} \
          CPM_PCIE0_AXIBAR_NUM {4} \
          CPM_PCIE0_AXISTEN_IF_CC_ALIGNMENT_MODE {Address_Aligned} \
          CPM_PCIE0_AXISTEN_IF_COMPL_TIMEOUT_REG0 {BEBC20} \
          CPM_PCIE0_AXISTEN_IF_COMPL_TIMEOUT_REG1 {2FAF080} \
          CPM_PCIE0_AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_256_TAGS {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_CLIENT_TAG {1} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_INTERNAL_MSIX_TABLE {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_MESSAGE_RID_CHECK {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_MSG_ROUTE {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_RX_MSG_INTFC {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_RX_TAG_SCALING {0} \
          CPM_PCIE0_AXISTEN_IF_ENABLE_TX_TAG_SCALING {0} \
          CPM_PCIE0_AXISTEN_IF_EXTEND_CPL_TIMEOUT {16ms_to_1s} \
          CPM_PCIE0_AXISTEN_IF_EXT_512 {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_CC_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_CQ_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_RC_4TLP_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_RC_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_EXT_512_RQ_STRADDLE {0} \
          CPM_PCIE0_AXISTEN_IF_RC_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE0_AXISTEN_IF_RC_STRADDLE {1} \
          CPM_PCIE0_AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE0_AXISTEN_IF_RX_PARITY_EN {1} \
          CPM_PCIE0_AXISTEN_IF_SIM_SHORT_CPL_TIMEOUT {0} \
          CPM_PCIE0_AXISTEN_IF_TX_PARITY_EN {0} \
          CPM_PCIE0_AXISTEN_IF_WIDTH {512} \
          CPM_PCIE0_AXISTEN_MSIX_VECTORS_PER_FUNCTION {8} \
          CPM_PCIE0_AXISTEN_USER_SPARE {0} \
          CPM_PCIE0_BRIDGE_AXI_SLAVE_IF {0} \
          CPM_PCIE0_CCIX_EN {0} \
          CPM_PCIE0_CCIX_OPT_TLP_GEN_AND_RECEPT_EN_CONTROL_INTERNAL {0} \
          CPM_PCIE0_CCIX_VENDOR_ID {0} \
          CPM_PCIE0_CFG_CTL_IF {0} \
          CPM_PCIE0_CFG_EXT_IF {0} \
          CPM_PCIE0_CFG_FC_IF {0} \
          CPM_PCIE0_CFG_MGMT_IF {0} \
          CPM_PCIE0_CFG_SPEC_4_0 {0} \
          CPM_PCIE0_CFG_STS_IF {0} \
          CPM_PCIE0_CFG_VEND_ID {10EE} \
          CPM_PCIE0_CONTROLLER_ENABLE {1} \
          CPM_PCIE0_COPY_PF0_ENABLED {0} \
          CPM_PCIE0_COPY_PF0_QDMA_ENABLED {1} \
          CPM_PCIE0_COPY_PF0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_COPY_SRIOV_PF0_ENABLED {1} \
          CPM_PCIE0_COPY_XDMA_PF0_ENABLED {0} \
          CPM_PCIE0_CORE_CLK_FREQ {500} \
          CPM_PCIE0_CORE_EDR_CLK_FREQ {625} \
          CPM_PCIE0_DMA_DATA_WIDTH {512bits} \
          CPM_PCIE0_DMA_ENABLE_SECURE {0} \
          CPM_PCIE0_DMA_INTF {AXI_MM_and_AXI_Stream} \
          CPM_PCIE0_DMA_MASK {256bits} \
          CPM_PCIE0_DMA_METERING_ENABLE {1} \
          CPM_PCIE0_DMA_MSI_RX_PIN_ENABLED {FALSE} \
          CPM_PCIE0_DMA_ROOT_PORT {0} \
          CPM_PCIE0_DSC_BYPASS_RD {0} \
          CPM_PCIE0_DSC_BYPASS_WR {0} \
          CPM_PCIE0_EDR_IF {0} \
          CPM_PCIE0_EDR_LINK_SPEED {None} \
          CPM_PCIE0_EN_PARITY {0} \
          CPM_PCIE0_EXT_CFG_SPACE_MODE {None} \
          CPM_PCIE0_EXT_PCIE_CFG_SPACE_ENABLED {None} \
          CPM_PCIE0_FUNCTIONAL_MODE {QDMA} \
          CPM_PCIE0_LANE_REVERSAL_EN {1} \
          CPM_PCIE0_LEGACY_EXT_PCIE_CFG_SPACE_ENABLED {0} \
          CPM_PCIE0_LINK_DEBUG_AXIST_EN {0} \
          CPM_PCIE0_LINK_DEBUG_EN {0} \
          CPM_PCIE0_LINK_SPEED0_FOR_POWER {GEN4} \
          CPM_PCIE0_LINK_WIDTH0_FOR_POWER {8} \
          CPM_PCIE0_MAILBOX_ENABLE {0} \
          CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s} \
          CPM_PCIE0_MCAP_ENABLE {0} \
          CPM_PCIE0_MESG_RSVD_IF {0} \
          CPM_PCIE0_MESG_TRANSMIT_IF {0} \
          CPM_PCIE0_MODE0_FOR_POWER {CPM5_DMA} \
          CPM_PCIE0_MODES {DMA} \
          CPM_PCIE0_MODE_SELECTION {Advanced} \
          CPM_PCIE0_MSIX_RP_ENABLED {0} \
          CPM_PCIE0_MSI_X_OPTIONS {MSI-X_Internal} \
          CPM_PCIE0_NUM_USR_IRQ {0} \
          CPM_PCIE0_PASID_IF {0} \
          CPM_PCIE0_PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE {0} \
          CPM_PCIE0_PF0_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE0_PF0_ARI_CAP_VER {1} \
          CPM_PCIE0_PF0_ATS_CAP_ON {0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_0 {0x00000000E8000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_1 {0x0000000622000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_2 {0x0000000700000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_3 {0x0000008000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_0 {0x0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_1 {0x0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_2 {0x0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_3 {0x0} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_BRIDGE_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_0 {0x00000000EFFFFFFF} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_1 {0x0000000622FFFFFF} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_2 {0x000000070003FFFF} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_3 {0x0000008000000FFF} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE0_PF0_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE0_PF0_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE0_PF0_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE0_PF0_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE0_PF0_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE0_PF0_BAR0_64BIT {1} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_64BIT {0} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR0_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR0_ENABLED {1} \
          CPM_PCIE0_PF0_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR0_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_QDMA_SIZE {512} \
          CPM_PCIE0_PF0_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF0_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_SIZE {512} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_SIZE {32} \
          CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF0_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR0_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR0_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR0_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR1_64BIT {0} \
          CPM_PCIE0_PF0_BAR1_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR1_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR1_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR1_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR1_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR2_64BIT {1} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_64BIT {0} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR2_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR2_ENABLED {1} \
          CPM_PCIE0_PF0_BAR2_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF0_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_SIZE {64} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR2_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR2_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR3_64BIT {0} \
          CPM_PCIE0_PF0_BAR3_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR3_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR3_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR3_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR3_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR4_64BIT {1} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_64BIT {0} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR4_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR4_ENABLED {1} \
          CPM_PCIE0_PF0_BAR4_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF0_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_SIZE {64} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR4_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR4_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR4_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR4_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR4_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR5_64BIT {0} \
          CPM_PCIE0_PF0_BAR5_BRIDGE_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_BRIDGE_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_BRIDGE_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_BRIDGE_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR5_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR5_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF0_BAR5_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR5_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_BAR5_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_BAR5_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_BAR5_XDMA_SIZE {4} \
          CPM_PCIE0_PF0_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF0_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE0_PF0_BASE_CLASS_VALUE {05} \
          CPM_PCIE0_PF0_CAPABILITY_POINTER {80} \
          CPM_PCIE0_PF0_CFG_DEV_ID {B03F} \
          CPM_PCIE0_PF0_CFG_REV_ID {0} \
          CPM_PCIE0_PF0_CFG_SUBSYS_ID {7} \
          CPM_PCIE0_PF0_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE0_PF0_CLASS_CODE {0x058000} \
          CPM_PCIE0_PF0_DEV_CAP_10B_TAG_EN {0} \
          CPM_PCIE0_PF0_DEV_CAP_ENDPOINT_L0S_LATENCY {less_than_64ns} \
          CPM_PCIE0_PF0_DEV_CAP_ENDPOINT_L1S_LATENCY {less_than_1us} \
          CPM_PCIE0_PF0_DEV_CAP_EXT_TAG_EN {1} \
          CPM_PCIE0_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {1} \
          CPM_PCIE0_PF0_DEV_CAP_MAX_PAYLOAD {512_bytes} \
          CPM_PCIE0_PF0_DLL_FEATURE_CAP_ID {0x0025} \
          CPM_PCIE0_PF0_DLL_FEATURE_CAP_ON {1} \
          CPM_PCIE0_PF0_DLL_FEATURE_CAP_VER {1} \
          CPM_PCIE0_PF0_DSN_CAP_ENABLE {0} \
          CPM_PCIE0_PF0_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE0_PF0_EXPANSION_ROM_QDMA_ENABLED {0} \
          CPM_PCIE0_PF0_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_EXPANSION_ROM_QDMA_SIZE {2} \
          CPM_PCIE0_PF0_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE0_PF0_INTERFACE_VALUE {00} \
          CPM_PCIE0_PF0_INTERRUPT_PIN {NONE} \
          CPM_PCIE0_PF0_LINK_CAP_ASPM_SUPPORT {No_ASPM} \
          CPM_PCIE0_PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {1} \
          CPM_PCIE0_PF0_MARGINING_CAP_ID {0} \
          CPM_PCIE0_PF0_MARGINING_CAP_ON {1} \
          CPM_PCIE0_PF0_MARGINING_CAP_VER {1} \
          CPM_PCIE0_PF0_MSIX_CAP_PBA_OFFSET {54000} \
          CPM_PCIE0_PF0_MSIX_CAP_TABLE_OFFSET {50000} \
          CPM_PCIE0_PF0_MSIX_CAP_TABLE_SIZE {7} \
          CPM_PCIE0_PF0_MSIX_ENABLED {1} \
          CPM_PCIE0_PF0_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE0_PF0_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE0_PF0_MSI_ENABLED {0} \
          CPM_PCIE0_PF0_PASID_CAP_MAX_PASID_WIDTH {1} \
          CPM_PCIE0_PF0_PASID_CAP_ON {0} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_0 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_1 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_2 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_3 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_BRIDGE_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_2 {0xE0000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_4 {0x00000000000000} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_XDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF0_PL16_CAP_ID {0} \
          CPM_PCIE0_PF0_PL16_CAP_ON {1} \
          CPM_PCIE0_PF0_PL16_CAP_VER {1} \
          CPM_PCIE0_PF0_PM_CAP_ID {1} \
          CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D0 {1} \
          CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D1 {1} \
          CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D3COLD {1} \
          CPM_PCIE0_PF0_PM_CAP_PMESUPPORT_D3HOT {1} \
          CPM_PCIE0_PF0_PM_CAP_SUPP_D1_STATE {1} \
          CPM_PCIE0_PF0_PM_CAP_VER_ID {3} \
          CPM_PCIE0_PF0_PM_CSR_NOSOFTRESET {1} \
          CPM_PCIE0_PF0_PRI_CAP_ON {0} \
          CPM_PCIE0_PF0_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR0_64BIT {1} \
          CPM_PCIE0_PF0_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE0_PF0_SRIOV_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR0_SIZE {32} \
          CPM_PCIE0_PF0_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE0_PF0_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR1_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR2_64BIT {1} \
          CPM_PCIE0_PF0_SRIOV_BAR2_ENABLED {1} \
          CPM_PCIE0_PF0_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR2_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE0_PF0_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR3_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE0_PF0_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR4_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE0_PF0_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE0_PF0_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_SRIOV_BAR5_SIZE {4} \
          CPM_PCIE0_PF0_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF0_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_PF0_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE0_PF0_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE0_PF0_SRIOV_CAP_VER {1} \
          CPM_PCIE0_PF0_SRIOV_FIRST_VF_OFFSET {16} \
          CPM_PCIE0_PF0_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE0_PF0_SRIOV_SUPPORTED_PAGE_SIZE {0x00000553} \
          CPM_PCIE0_PF0_SRIOV_VF_DEVICE_ID {C03F} \
          CPM_PCIE0_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE0_PF0_SUB_CLASS_VALUE {80} \
          CPM_PCIE0_PF0_TPHR_CAP_DEV_SPECIFIC_MODE {1} \
          CPM_PCIE0_PF0_TPHR_CAP_ENABLE {0} \
          CPM_PCIE0_PF0_TPHR_CAP_INT_VEC_MODE {1} \
          CPM_PCIE0_PF0_TPHR_CAP_ST_TABLE_LOC {ST_Table_not_present} \
          CPM_PCIE0_PF0_TPHR_CAP_ST_TABLE_SIZE {16} \
          CPM_PCIE0_PF0_TPHR_CAP_VER {1} \
          CPM_PCIE0_PF0_TPHR_ENABLE {0} \
          CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_PF0_VC_ARB_CAPABILITY {0} \
          CPM_PCIE0_PF0_VC_ARB_TBL_OFFSET {0} \
          CPM_PCIE0_PF0_VC_CAP_ENABLED {0} \
          CPM_PCIE0_PF0_VC_CAP_VER {1} \
          CPM_PCIE0_PF0_VC_EXTENDED_COUNT {0} \
          CPM_PCIE0_PF0_VC_LOW_PRIORITY_EXTENDED_COUNT {0} \
          CPM_PCIE0_PF0_XDMA_64BIT {0} \
          CPM_PCIE0_PF0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF0_XDMA_SIZE {128} \
          CPM_PCIE0_PF1_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE0_PF1_ATS_CAP_ON {0} \
          CPM_PCIE0_PF1_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE0_PF1_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE0_PF1_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE0_PF1_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE0_PF1_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE0_PF1_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE0_PF1_BAR0_64BIT {1} \
          CPM_PCIE0_PF1_BAR0_ENABLED {1} \
          CPM_PCIE0_PF1_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR0_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR0_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR0_QDMA_SIZE {512} \
          CPM_PCIE0_PF1_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF1_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR0_SIZE {512} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_SIZE {32} \
          CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF1_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR0_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR0_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR0_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR1_64BIT {0} \
          CPM_PCIE0_PF1_BAR1_ENABLED {0} \
          CPM_PCIE0_PF1_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR1_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR1_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR1_SIZE {4} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR1_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR1_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR2_64BIT {1} \
          CPM_PCIE0_PF1_BAR2_ENABLED {1} \
          CPM_PCIE0_PF1_BAR2_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR2_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF1_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR2_SIZE {64} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR2_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR2_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR3_64BIT {0} \
          CPM_PCIE0_PF1_BAR3_ENABLED {0} \
          CPM_PCIE0_PF1_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR3_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR3_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR3_SIZE {4} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR3_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR3_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR4_64BIT {1} \
          CPM_PCIE0_PF1_BAR4_ENABLED {1} \
          CPM_PCIE0_PF1_BAR4_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF1_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF1_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_BAR4_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF1_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR4_SIZE {64} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR4_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR4_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR4_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR4_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR4_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR5_64BIT {0} \
          CPM_PCIE0_PF1_BAR5_ENABLED {0} \
          CPM_PCIE0_PF1_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR5_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR5_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR5_SIZE {4} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF1_BAR5_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF1_BAR5_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_BAR5_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_BAR5_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_BAR5_XDMA_SIZE {4} \
          CPM_PCIE0_PF1_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF1_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE0_PF1_BASE_CLASS_VALUE {05} \
          CPM_PCIE0_PF1_CAPABILITY_POINTER {80} \
          CPM_PCIE0_PF1_CFG_DEV_ID {B13F} \
          CPM_PCIE0_PF1_CFG_REV_ID {0} \
          CPM_PCIE0_PF1_CFG_SUBSYS_ID {7} \
          CPM_PCIE0_PF1_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE0_PF1_CLASS_CODE {0x000} \
          CPM_PCIE0_PF1_DSN_CAP_ENABLE {0} \
          CPM_PCIE0_PF1_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE0_PF1_EXPANSION_ROM_QDMA_ENABLED {0} \
          CPM_PCIE0_PF1_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_EXPANSION_ROM_QDMA_SIZE {2} \
          CPM_PCIE0_PF1_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE0_PF1_INTERFACE_VALUE {00} \
          CPM_PCIE0_PF1_INTERRUPT_PIN {NONE} \
          CPM_PCIE0_PF1_MSIX_CAP_PBA_BIR {BAR_1:0} \
          CPM_PCIE0_PF1_MSIX_CAP_PBA_OFFSET {54000} \
          CPM_PCIE0_PF1_MSIX_CAP_TABLE_BIR {BAR_1:0} \
          CPM_PCIE0_PF1_MSIX_CAP_TABLE_OFFSET {50000} \
          CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE {7} \
          CPM_PCIE0_PF1_MSIX_ENABLED {1} \
          CPM_PCIE0_PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE0_PF1_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE0_PF1_MSI_ENABLED {0} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF1_PCIEBAR2AXIBAR_XDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF1_PRI_CAP_ON {0} \
          CPM_PCIE0_PF1_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR0_64BIT {1} \
          CPM_PCIE0_PF1_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE0_PF1_SRIOV_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF1_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR0_SIZE {32} \
          CPM_PCIE0_PF1_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE0_PF1_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR1_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR2_64BIT {1} \
          CPM_PCIE0_PF1_SRIOV_BAR2_ENABLED {1} \
          CPM_PCIE0_PF1_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR2_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE0_PF1_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR3_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE0_PF1_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR4_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE0_PF1_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE0_PF1_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_SRIOV_BAR5_SIZE {4} \
          CPM_PCIE0_PF1_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF1_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_PF1_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE0_PF1_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE0_PF1_SRIOV_CAP_VER {1} \
          CPM_PCIE0_PF1_SRIOV_FIRST_VF_OFFSET {19} \
          CPM_PCIE0_PF1_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE0_PF1_SRIOV_SUPPORTED_PAGE_SIZE {0x00000553} \
          CPM_PCIE0_PF1_SRIOV_VF_DEVICE_ID {C13F} \
          CPM_PCIE0_PF1_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE0_PF1_SUB_CLASS_VALUE {80} \
          CPM_PCIE0_PF1_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_PF1_VEND_ID {0} \
          CPM_PCIE0_PF1_XDMA_64BIT {0} \
          CPM_PCIE0_PF1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF1_XDMA_SIZE {128} \
          CPM_PCIE0_PF2_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE0_PF2_ATS_CAP_ON {0} \
          CPM_PCIE0_PF2_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE0_PF2_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE0_PF2_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE0_PF2_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE0_PF2_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE0_PF2_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE0_PF2_BAR0_64BIT {1} \
          CPM_PCIE0_PF2_BAR0_ENABLED {1} \
          CPM_PCIE0_PF2_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR0_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR0_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR0_QDMA_SIZE {512} \
          CPM_PCIE0_PF2_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF2_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR0_SIZE {512} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_SIZE {32} \
          CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF2_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR0_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR0_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR0_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR1_64BIT {0} \
          CPM_PCIE0_PF2_BAR1_ENABLED {0} \
          CPM_PCIE0_PF2_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR1_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR1_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR1_SIZE {4} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR1_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR1_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR2_64BIT {1} \
          CPM_PCIE0_PF2_BAR2_ENABLED {1} \
          CPM_PCIE0_PF2_BAR2_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR2_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF2_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR2_SIZE {64} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR2_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR2_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR3_64BIT {0} \
          CPM_PCIE0_PF2_BAR3_ENABLED {0} \
          CPM_PCIE0_PF2_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR3_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR3_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR3_SIZE {4} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR3_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR3_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR4_64BIT {1} \
          CPM_PCIE0_PF2_BAR4_ENABLED {1} \
          CPM_PCIE0_PF2_BAR4_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF2_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF2_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_BAR4_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF2_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR4_SIZE {64} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR4_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR4_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR4_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR4_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR4_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR5_64BIT {0} \
          CPM_PCIE0_PF2_BAR5_ENABLED {0} \
          CPM_PCIE0_PF2_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR5_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR5_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR5_SIZE {4} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF2_BAR5_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF2_BAR5_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_BAR5_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_BAR5_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_BAR5_XDMA_SIZE {4} \
          CPM_PCIE0_PF2_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF2_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE0_PF2_BASE_CLASS_VALUE {05} \
          CPM_PCIE0_PF2_CAPABILITY_POINTER {80} \
          CPM_PCIE0_PF2_CFG_DEV_ID {B23F} \
          CPM_PCIE0_PF2_CFG_REV_ID {0} \
          CPM_PCIE0_PF2_CFG_SUBSYS_ID {7} \
          CPM_PCIE0_PF2_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE0_PF2_CLASS_CODE {0x000} \
          CPM_PCIE0_PF2_DSN_CAP_ENABLE {0} \
          CPM_PCIE0_PF2_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE0_PF2_EXPANSION_ROM_QDMA_ENABLED {0} \
          CPM_PCIE0_PF2_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_EXPANSION_ROM_QDMA_SIZE {2} \
          CPM_PCIE0_PF2_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE0_PF2_INTERFACE_VALUE {00} \
          CPM_PCIE0_PF2_INTERRUPT_PIN {NONE} \
          CPM_PCIE0_PF2_MSIX_CAP_PBA_BIR {BAR_1:0} \
          CPM_PCIE0_PF2_MSIX_CAP_PBA_OFFSET {54000} \
          CPM_PCIE0_PF2_MSIX_CAP_TABLE_BIR {BAR_1:0} \
          CPM_PCIE0_PF2_MSIX_CAP_TABLE_OFFSET {50000} \
          CPM_PCIE0_PF2_MSIX_CAP_TABLE_SIZE {7} \
          CPM_PCIE0_PF2_MSIX_ENABLED {1} \
          CPM_PCIE0_PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE0_PF2_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE0_PF2_MSI_ENABLED {0} \
          CPM_PCIE0_PF2_PASID_CAP_MAX_PASID_WIDTH {1} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF2_PCIEBAR2AXIBAR_XDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF2_PRI_CAP_ON {0} \
          CPM_PCIE0_PF2_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR0_64BIT {1} \
          CPM_PCIE0_PF2_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE0_PF2_SRIOV_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF2_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR0_SIZE {32} \
          CPM_PCIE0_PF2_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE0_PF2_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR1_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR2_64BIT {1} \
          CPM_PCIE0_PF2_SRIOV_BAR2_ENABLED {1} \
          CPM_PCIE0_PF2_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR2_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE0_PF2_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR3_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE0_PF2_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR4_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE0_PF2_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE0_PF2_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_SRIOV_BAR5_SIZE {4} \
          CPM_PCIE0_PF2_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF2_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_PF2_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE0_PF2_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE0_PF2_SRIOV_CAP_VER {1} \
          CPM_PCIE0_PF2_SRIOV_FIRST_VF_OFFSET {22} \
          CPM_PCIE0_PF2_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE0_PF2_SRIOV_SUPPORTED_PAGE_SIZE {0x00000553} \
          CPM_PCIE0_PF2_SRIOV_VF_DEVICE_ID {C23F} \
          CPM_PCIE0_PF2_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE0_PF2_SUB_CLASS_VALUE {80} \
          CPM_PCIE0_PF2_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_PF2_VEND_ID {0} \
          CPM_PCIE0_PF2_XDMA_64BIT {0} \
          CPM_PCIE0_PF2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF2_XDMA_SIZE {128} \
          CPM_PCIE0_PF3_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE0_PF3_ATS_CAP_ON {0} \
          CPM_PCIE0_PF3_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE0_PF3_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE0_PF3_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE0_PF3_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE0_PF3_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE0_PF3_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE0_PF3_BAR0_64BIT {1} \
          CPM_PCIE0_PF3_BAR0_ENABLED {1} \
          CPM_PCIE0_PF3_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR0_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR0_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR0_QDMA_SIZE {512} \
          CPM_PCIE0_PF3_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF3_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR0_SIZE {512} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_SIZE {32} \
          CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF3_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR0_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR0_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR0_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR0_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR0_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR0_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR0_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR1_64BIT {0} \
          CPM_PCIE0_PF3_BAR1_ENABLED {0} \
          CPM_PCIE0_PF3_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR1_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR1_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR1_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR1_SIZE {4} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR1_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR1_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR1_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR1_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR1_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR1_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR1_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR2_64BIT {1} \
          CPM_PCIE0_PF3_BAR2_ENABLED {1} \
          CPM_PCIE0_PF3_BAR2_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR2_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF3_BAR2_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR2_SIZE {64} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR2_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR2_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR2_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR2_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR2_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR2_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR3_64BIT {0} \
          CPM_PCIE0_PF3_BAR3_ENABLED {0} \
          CPM_PCIE0_PF3_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR3_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR3_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR3_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR3_SIZE {4} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR3_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR3_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR3_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR3_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR4_64BIT {1} \
          CPM_PCIE0_PF3_BAR4_ENABLED {1} \
          CPM_PCIE0_PF3_BAR4_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF3_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF3_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_BAR4_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF3_BAR4_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR4_SIZE {64} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR4_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR4_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR4_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR4_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR4_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR4_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR4_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR5_64BIT {0} \
          CPM_PCIE0_PF3_BAR5_ENABLED {0} \
          CPM_PCIE0_PF3_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR5_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR5_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR5_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR5_SIZE {4} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR5_SRIOV_QDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF3_BAR5_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE0_PF3_BAR5_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_BAR5_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_BAR5_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_BAR5_XDMA_SIZE {4} \
          CPM_PCIE0_PF3_BAR5_XDMA_TYPE {AXI_Bridge_Master} \
          CPM_PCIE0_PF3_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE0_PF3_BASE_CLASS_VALUE {05} \
          CPM_PCIE0_PF3_CAPABILITY_POINTER {80} \
          CPM_PCIE0_PF3_CFG_DEV_ID {B33F} \
          CPM_PCIE0_PF3_CFG_REV_ID {0} \
          CPM_PCIE0_PF3_CFG_SUBSYS_ID {7} \
          CPM_PCIE0_PF3_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE0_PF3_CLASS_CODE {0x000} \
          CPM_PCIE0_PF3_DSN_CAP_ENABLE {0} \
          CPM_PCIE0_PF3_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE0_PF3_EXPANSION_ROM_QDMA_ENABLED {0} \
          CPM_PCIE0_PF3_EXPANSION_ROM_QDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_EXPANSION_ROM_QDMA_SIZE {2} \
          CPM_PCIE0_PF3_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE0_PF3_INTERFACE_VALUE {00} \
          CPM_PCIE0_PF3_INTERRUPT_PIN {NONE} \
          CPM_PCIE0_PF3_MSIX_CAP_PBA_BIR {BAR_1:0} \
          CPM_PCIE0_PF3_MSIX_CAP_PBA_OFFSET {54000} \
          CPM_PCIE0_PF3_MSIX_CAP_TABLE_BIR {BAR_1:0} \
          CPM_PCIE0_PF3_MSIX_CAP_TABLE_OFFSET {50000} \
          CPM_PCIE0_PF3_MSIX_CAP_TABLE_SIZE {7} \
          CPM_PCIE0_PF3_MSIX_ENABLED {1} \
          CPM_PCIE0_PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE0_PF3_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE0_PF3_MSI_ENABLED {0} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_0 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_1 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_2 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_3 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_4 {0x0000000000000000} \
          CPM_PCIE0_PF3_PCIEBAR2AXIBAR_XDMA_5 {0x0000000000000000} \
          CPM_PCIE0_PF3_PRI_CAP_ON {0} \
          CPM_PCIE0_PF3_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR0_64BIT {1} \
          CPM_PCIE0_PF3_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE0_PF3_SRIOV_BAR0_PREFETCHABLE {1} \
          CPM_PCIE0_PF3_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR0_SIZE {32} \
          CPM_PCIE0_PF3_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE0_PF3_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR1_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR2_64BIT {1} \
          CPM_PCIE0_PF3_SRIOV_BAR2_ENABLED {1} \
          CPM_PCIE0_PF3_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR2_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE0_PF3_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR3_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE0_PF3_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR4_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE0_PF3_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE0_PF3_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_SRIOV_BAR5_SIZE {4} \
          CPM_PCIE0_PF3_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE0_PF3_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_PF3_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE0_PF3_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE0_PF3_SRIOV_CAP_VER {1} \
          CPM_PCIE0_PF3_SRIOV_FIRST_VF_OFFSET {25} \
          CPM_PCIE0_PF3_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE0_PF3_SRIOV_SUPPORTED_PAGE_SIZE {0x00000553} \
          CPM_PCIE0_PF3_SRIOV_VF_DEVICE_ID {C33F} \
          CPM_PCIE0_PF3_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE0_PF3_SUB_CLASS_VALUE {80} \
          CPM_PCIE0_PF3_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_PF3_VEND_ID {0} \
          CPM_PCIE0_PF3_XDMA_64BIT {0} \
          CPM_PCIE0_PF3_XDMA_ENABLED {0} \
          CPM_PCIE0_PF3_XDMA_PREFETCHABLE {0} \
          CPM_PCIE0_PF3_XDMA_SCALE {Kilobytes} \
          CPM_PCIE0_PF3_XDMA_SIZE {128} \
          CPM_PCIE0_PL_LINK_CAP_MAX_LINK_SPEED {Gen3} \
          CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
          CPM_PCIE0_PL_UPSTREAM_FACING {1} \
          CPM_PCIE0_PL_USER_SPARE {0} \
          CPM_PCIE0_PM_ASPML0S_TIMEOUT {0} \
          CPM_PCIE0_PM_ASPML1_ENTRY_DELAY {0} \
          CPM_PCIE0_PM_ENABLE_L23_ENTRY {0} \
          CPM_PCIE0_PM_ENABLE_SLOT_POWER_CAPTURE {1} \
          CPM_PCIE0_PM_L1_REENTRY_DELAY {0} \
          CPM_PCIE0_PM_PME_TURNOFF_ACK_DELAY {0} \
          CPM_PCIE0_PORT_TYPE {PCI_Express_Endpoint_device} \
          CPM_PCIE0_QDMA_MULTQ_MAX {2048} \
          CPM_PCIE0_QDMA_PARITY_SETTINGS {None} \
          CPM_PCIE0_REF_CLK_FREQ {100_MHz} \
          CPM_PCIE0_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE0_SRIOV_FIRST_VF_OFFSET {16} \
          CPM_PCIE0_TANDEM {Tandem_PCIe} \
          CPM_PCIE0_TL2CFG_IF_PARITY_CHK {0} \
          CPM_PCIE0_TL_NP_FIFO_NUM_TLPS {0} \
          CPM_PCIE0_TL_PF_ENABLE_REG {1} \
          CPM_PCIE0_TL_POSTED_RAM_SIZE {0} \
          CPM_PCIE0_TL_USER_SPARE {0} \
          CPM_PCIE0_TX_FC_IF {0} \
          CPM_PCIE0_TYPE1_MEMBASE_MEMLIMIT_BRIDGE_ENABLE {Disabled} \
          CPM_PCIE0_TYPE1_MEMBASE_MEMLIMIT_ENABLE {Disabled} \
          CPM_PCIE0_TYPE1_PREFETCHABLE_MEMBASE_BRIDGE_MEMLIMIT {Disabled} \
          CPM_PCIE0_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT {Disabled} \
          CPM_PCIE0_USER_CLK2_FREQ {250_MHz} \
          CPM_PCIE0_USER_CLK_FREQ {250_MHz} \
          CPM_PCIE0_VC0_CAPABILITY_POINTER {80} \
          CPM_PCIE0_VC1_BASE_DISABLE {0} \
          CPM_PCIE0_VFG0_ATS_CAP_ON {0} \
          CPM_PCIE0_VFG0_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE0_VFG0_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE0_VFG0_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE0_VFG0_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE0_VFG0_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE0_VFG0_MSIX_ENABLED {0} \
          CPM_PCIE0_VFG0_PRI_CAP_ON {0} \
          CPM_PCIE0_VFG1_ATS_CAP_ON {0} \
          CPM_PCIE0_VFG1_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE0_VFG1_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE0_VFG1_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE0_VFG1_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE0_VFG1_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE0_VFG1_MSIX_ENABLED {0} \
          CPM_PCIE0_VFG1_PRI_CAP_ON {0} \
          CPM_PCIE0_VFG2_ATS_CAP_ON {0} \
          CPM_PCIE0_VFG2_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE0_VFG2_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE0_VFG2_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE0_VFG2_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE0_VFG2_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE0_VFG2_MSIX_ENABLED {0} \
          CPM_PCIE0_VFG2_PRI_CAP_ON {0} \
          CPM_PCIE0_VFG3_ATS_CAP_ON {0} \
          CPM_PCIE0_VFG3_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE0_VFG3_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE0_VFG3_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE0_VFG3_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE0_VFG3_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE0_VFG3_MSIX_ENABLED {0} \
          CPM_PCIE0_VFG3_PRI_CAP_ON {0} \
          CPM_PCIE0_XDMA_AXILITE_SLAVE_IF {0} \
          CPM_PCIE0_XDMA_AXI_ID_WIDTH {2} \
          CPM_PCIE0_XDMA_DSC_BYPASS_RD {0000} \
          CPM_PCIE0_XDMA_DSC_BYPASS_WR {0000} \
          CPM_PCIE0_XDMA_IRQ {1} \
          CPM_PCIE0_XDMA_PARITY_SETTINGS {None} \
          CPM_PCIE0_XDMA_RNUM_CHNL {4} \
          CPM_PCIE0_XDMA_RNUM_RIDS {2} \
          CPM_PCIE0_XDMA_STS_PORTS {0} \
          CPM_PCIE0_XDMA_WNUM_CHNL {4} \
          CPM_PCIE0_XDMA_WNUM_RIDS {2} \
          CPM_PCIE1_AER_CAP_ENABLED {1} \
          CPM_PCIE1_ARI_CAP_ENABLED {1} \
          CPM_PCIE1_ASYNC_MODE {SRNS} \
          CPM_PCIE1_ATS_PRI_CAP_ON {0} \
          CPM_PCIE1_AXIBAR_NUM {1} \
          CPM_PCIE1_AXISTEN_IF_CC_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE1_AXISTEN_IF_COMPL_TIMEOUT_REG0 {BEBC20} \
          CPM_PCIE1_AXISTEN_IF_COMPL_TIMEOUT_REG1 {2FAF080} \
          CPM_PCIE1_AXISTEN_IF_CQ_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_256_TAGS {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_CLIENT_TAG {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_INTERNAL_MSIX_TABLE {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_MESSAGE_RID_CHECK {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_MSG_ROUTE {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_RX_MSG_INTFC {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_RX_TAG_SCALING {0} \
          CPM_PCIE1_AXISTEN_IF_ENABLE_TX_TAG_SCALING {0} \
          CPM_PCIE1_AXISTEN_IF_EXTEND_CPL_TIMEOUT {16ms_to_1s} \
          CPM_PCIE1_AXISTEN_IF_EXT_512 {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_CC_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_CQ_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_RC_4TLP_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_RC_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_EXT_512_RQ_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_RC_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE1_AXISTEN_IF_RC_STRADDLE {0} \
          CPM_PCIE1_AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
          CPM_PCIE1_AXISTEN_IF_RX_PARITY_EN {1} \
          CPM_PCIE1_AXISTEN_IF_SIM_SHORT_CPL_TIMEOUT {0} \
          CPM_PCIE1_AXISTEN_IF_TX_PARITY_EN {0} \
          CPM_PCIE1_AXISTEN_IF_WIDTH {64} \
          CPM_PCIE1_AXISTEN_MSIX_VECTORS_PER_FUNCTION {8} \
          CPM_PCIE1_AXISTEN_USER_SPARE {0} \
          CPM_PCIE1_CCIX_EN {0} \
          CPM_PCIE1_CCIX_OPT_TLP_GEN_AND_RECEPT_EN_CONTROL_INTERNAL {0} \
          CPM_PCIE1_CCIX_VENDOR_ID {0} \
          CPM_PCIE1_CFG_CTL_IF {0} \
          CPM_PCIE1_CFG_EXT_IF {0} \
          CPM_PCIE1_CFG_FC_IF {0} \
          CPM_PCIE1_CFG_MGMT_IF {0} \
          CPM_PCIE1_CFG_SPEC_4_0 {0} \
          CPM_PCIE1_CFG_STS_IF {0} \
          CPM_PCIE1_CFG_VEND_ID {10EE} \
          CPM_PCIE1_CONTROLLER_ENABLE {0} \
          CPM_PCIE1_COPY_PF0_ENABLED {0} \
          CPM_PCIE1_COPY_SRIOV_PF0_ENABLED {1} \
          CPM_PCIE1_CORE_CLK_FREQ {250} \
          CPM_PCIE1_CORE_EDR_CLK_FREQ {625} \
          CPM_PCIE1_DSC_BYPASS_RD {0} \
          CPM_PCIE1_DSC_BYPASS_WR {0} \
          CPM_PCIE1_EDR_IF {0} \
          CPM_PCIE1_EDR_LINK_SPEED {None} \
          CPM_PCIE1_EN_PARITY {0} \
          CPM_PCIE1_EXT_PCIE_CFG_SPACE_ENABLED {None} \
          CPM_PCIE1_FUNCTIONAL_MODE {None} \
          CPM_PCIE1_LANE_REVERSAL_EN {1} \
          CPM_PCIE1_LEGACY_EXT_PCIE_CFG_SPACE_ENABLED {0} \
          CPM_PCIE1_LINK_DEBUG_AXIST_EN {0} \
          CPM_PCIE1_LINK_DEBUG_EN {0} \
          CPM_PCIE1_LINK_SPEED1_FOR_POWER {GEN2} \
          CPM_PCIE1_LINK_WIDTH1_FOR_POWER {2} \
          CPM_PCIE1_MAX_LINK_SPEED {5.0_GT/s} \
          CPM_PCIE1_MCAP_ENABLE {0} \
          CPM_PCIE1_MESG_RSVD_IF {0} \
          CPM_PCIE1_MESG_TRANSMIT_IF {0} \
          CPM_PCIE1_MODE1_FOR_POWER {NONE} \
          CPM_PCIE1_MODES {None} \
          CPM_PCIE1_MODE_SELECTION {Basic} \
          CPM_PCIE1_MSIX_RP_ENABLED {1} \
          CPM_PCIE1_MSI_X_OPTIONS {MSI-X_External} \
          CPM_PCIE1_PASID_IF {0} \
          CPM_PCIE1_PF0_AER_CAP_ECRC_GEN_AND_CHECK_CAPABLE {0} \
          CPM_PCIE1_PF0_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE1_PF0_ARI_CAP_VER {1} \
          CPM_PCIE1_PF0_ATS_CAP_ON {0} \
          CPM_PCIE1_PF0_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE1_PF0_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE1_PF0_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE1_PF0_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE1_PF0_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE1_PF0_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE1_PF0_BAR0_64BIT {0} \
          CPM_PCIE1_PF0_BAR0_ENABLED {1} \
          CPM_PCIE1_PF0_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR0_QDMA_AXCACHE {1} \
          CPM_PCIE1_PF0_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR0_SIZE {128} \
          CPM_PCIE1_PF0_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR0_XDMA_AXCACHE {1} \
          CPM_PCIE1_PF0_BAR1_64BIT {0} \
          CPM_PCIE1_PF0_BAR1_ENABLED {0} \
          CPM_PCIE1_PF0_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR1_SIZE {4} \
          CPM_PCIE1_PF0_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR2_64BIT {0} \
          CPM_PCIE1_PF0_BAR2_ENABLED {0} \
          CPM_PCIE1_PF0_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR2_SIZE {4} \
          CPM_PCIE1_PF0_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR3_64BIT {0} \
          CPM_PCIE1_PF0_BAR3_ENABLED {0} \
          CPM_PCIE1_PF0_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR3_SIZE {4} \
          CPM_PCIE1_PF0_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR4_64BIT {0} \
          CPM_PCIE1_PF0_BAR4_ENABLED {0} \
          CPM_PCIE1_PF0_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR4_SIZE {4} \
          CPM_PCIE1_PF0_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR5_64BIT {0} \
          CPM_PCIE1_PF0_BAR5_ENABLED {0} \
          CPM_PCIE1_PF0_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_BAR5_SIZE {4} \
          CPM_PCIE1_PF0_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF0_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF0_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE1_PF0_BASE_CLASS_VALUE {05} \
          CPM_PCIE1_PF0_CAPABILITY_POINTER {80} \
          CPM_PCIE1_PF0_CFG_DEV_ID {B03F} \
          CPM_PCIE1_PF0_CFG_REV_ID {0} \
          CPM_PCIE1_PF0_CFG_SUBSYS_ID {7} \
          CPM_PCIE1_PF0_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE1_PF0_CLASS_CODE {0x058000} \
          CPM_PCIE1_PF0_DEV_CAP_10B_TAG_EN {0} \
          CPM_PCIE1_PF0_DEV_CAP_ENDPOINT_L0S_LATENCY {less_than_64ns} \
          CPM_PCIE1_PF0_DEV_CAP_ENDPOINT_L1S_LATENCY {less_than_1us} \
          CPM_PCIE1_PF0_DEV_CAP_EXT_TAG_EN {0} \
          CPM_PCIE1_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {0} \
          CPM_PCIE1_PF0_DEV_CAP_MAX_PAYLOAD {1024_bytes} \
          CPM_PCIE1_PF0_DLL_FEATURE_CAP_ID {0} \
          CPM_PCIE1_PF0_DLL_FEATURE_CAP_ON {0} \
          CPM_PCIE1_PF0_DLL_FEATURE_CAP_VER {1} \
          CPM_PCIE1_PF0_DSN_CAP_ENABLE {0} \
          CPM_PCIE1_PF0_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE1_PF0_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE1_PF0_INTERFACE_VALUE {00} \
          CPM_PCIE1_PF0_INTERRUPT_PIN {NONE} \
          CPM_PCIE1_PF0_LINK_CAP_ASPM_SUPPORT {No_ASPM} \
          CPM_PCIE1_PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {1} \
          CPM_PCIE1_PF0_MARGINING_CAP_ID {0} \
          CPM_PCIE1_PF0_MARGINING_CAP_ON {0} \
          CPM_PCIE1_PF0_MARGINING_CAP_VER {1} \
          CPM_PCIE1_PF0_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_PF0_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_PF0_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_PF0_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_PF0_MSIX_CAP_TABLE_SIZE {007} \
          CPM_PCIE1_PF0_MSIX_ENABLED {1} \
          CPM_PCIE1_PF0_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE1_PF0_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE1_PF0_MSI_ENABLED {1} \
          CPM_PCIE1_PF0_PASID_CAP_MAX_PASID_WIDTH {1} \
          CPM_PCIE1_PF0_PASID_CAP_ON {0} \
          CPM_PCIE1_PF0_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE1_PF0_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE1_PF0_PL16_CAP_ID {0} \
          CPM_PCIE1_PF0_PL16_CAP_ON {0} \
          CPM_PCIE1_PF0_PL16_CAP_VER {1} \
          CPM_PCIE1_PF0_PM_CAP_ID {1} \
          CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D0 {1} \
          CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D1 {1} \
          CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D3COLD {1} \
          CPM_PCIE1_PF0_PM_CAP_PMESUPPORT_D3HOT {1} \
          CPM_PCIE1_PF0_PM_CAP_SUPP_D1_STATE {1} \
          CPM_PCIE1_PF0_PM_CAP_VER_ID {3} \
          CPM_PCIE1_PF0_PM_CSR_NOSOFTRESET {1} \
          CPM_PCIE1_PF0_PRI_CAP_ON {0} \
          CPM_PCIE1_PF0_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR0_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE1_PF0_SRIOV_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR0_SIZE {2} \
          CPM_PCIE1_PF0_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR1_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR2_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR2_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR2_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR3_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR4_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE1_PF0_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE1_PF0_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF0_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF0_SRIOV_BAR5_SIZE {128} \
          CPM_PCIE1_PF0_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF0_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_PF0_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE1_PF0_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE1_PF0_SRIOV_CAP_VER {1} \
          CPM_PCIE1_PF0_SRIOV_FIRST_VF_OFFSET {4} \
          CPM_PCIE1_PF0_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE1_PF0_SRIOV_SUPPORTED_PAGE_SIZE {553} \
          CPM_PCIE1_PF0_SRIOV_VF_DEVICE_ID {C03F} \
          CPM_PCIE1_PF0_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE1_PF0_SUB_CLASS_VALUE {80} \
          CPM_PCIE1_PF0_TPHR_CAP_DEV_SPECIFIC_MODE {1} \
          CPM_PCIE1_PF0_TPHR_CAP_ENABLE {0} \
          CPM_PCIE1_PF0_TPHR_CAP_INT_VEC_MODE {1} \
          CPM_PCIE1_PF0_TPHR_CAP_ST_TABLE_LOC {ST_Table_not_present} \
          CPM_PCIE1_PF0_TPHR_CAP_ST_TABLE_SIZE {16} \
          CPM_PCIE1_PF0_TPHR_CAP_VER {1} \
          CPM_PCIE1_PF0_TPHR_ENABLE {0} \
          CPM_PCIE1_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {0} \
          CPM_PCIE1_PF0_VC_ARB_CAPABILITY {0} \
          CPM_PCIE1_PF0_VC_ARB_TBL_OFFSET {0} \
          CPM_PCIE1_PF0_VC_CAP_ENABLED {0} \
          CPM_PCIE1_PF0_VC_CAP_VER {1} \
          CPM_PCIE1_PF0_VC_EXTENDED_COUNT {0} \
          CPM_PCIE1_PF0_VC_LOW_PRIORITY_EXTENDED_COUNT {0} \
          CPM_PCIE1_PF1_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE1_PF1_ATS_CAP_ON {0} \
          CPM_PCIE1_PF1_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE1_PF1_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE1_PF1_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE1_PF1_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE1_PF1_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE1_PF1_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE1_PF1_BAR0_64BIT {0} \
          CPM_PCIE1_PF1_BAR0_ENABLED {1} \
          CPM_PCIE1_PF1_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR0_QDMA_AXCACHE {1} \
          CPM_PCIE1_PF1_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR0_SIZE {128} \
          CPM_PCIE1_PF1_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR0_XDMA_AXCACHE {1} \
          CPM_PCIE1_PF1_BAR1_64BIT {0} \
          CPM_PCIE1_PF1_BAR1_ENABLED {0} \
          CPM_PCIE1_PF1_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR1_SIZE {4} \
          CPM_PCIE1_PF1_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR2_64BIT {0} \
          CPM_PCIE1_PF1_BAR2_ENABLED {0} \
          CPM_PCIE1_PF1_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR2_SIZE {4} \
          CPM_PCIE1_PF1_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR3_64BIT {0} \
          CPM_PCIE1_PF1_BAR3_ENABLED {0} \
          CPM_PCIE1_PF1_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR3_SIZE {4} \
          CPM_PCIE1_PF1_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR4_64BIT {0} \
          CPM_PCIE1_PF1_BAR4_ENABLED {0} \
          CPM_PCIE1_PF1_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR4_SIZE {4} \
          CPM_PCIE1_PF1_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR5_64BIT {0} \
          CPM_PCIE1_PF1_BAR5_ENABLED {0} \
          CPM_PCIE1_PF1_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_BAR5_SIZE {4} \
          CPM_PCIE1_PF1_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF1_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF1_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE1_PF1_BASE_CLASS_VALUE {05} \
          CPM_PCIE1_PF1_CAPABILITY_POINTER {80} \
          CPM_PCIE1_PF1_CFG_DEV_ID {B13F} \
          CPM_PCIE1_PF1_CFG_REV_ID {0} \
          CPM_PCIE1_PF1_CFG_SUBSYS_ID {7} \
          CPM_PCIE1_PF1_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE1_PF1_CLASS_CODE {0x000} \
          CPM_PCIE1_PF1_DSN_CAP_ENABLE {0} \
          CPM_PCIE1_PF1_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE1_PF1_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE1_PF1_INTERFACE_VALUE {00} \
          CPM_PCIE1_PF1_INTERRUPT_PIN {NONE} \
          CPM_PCIE1_PF1_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_PF1_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_PF1_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_PF1_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_PF1_MSIX_CAP_TABLE_SIZE {007} \
          CPM_PCIE1_PF1_MSIX_ENABLED {1} \
          CPM_PCIE1_PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE1_PF1_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE1_PF1_MSI_ENABLED {0} \
          CPM_PCIE1_PF1_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE1_PF1_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE1_PF1_PRI_CAP_ON {0} \
          CPM_PCIE1_PF1_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR0_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE1_PF1_SRIOV_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR0_SIZE {2} \
          CPM_PCIE1_PF1_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR1_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR2_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR2_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR2_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR3_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR4_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE1_PF1_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE1_PF1_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF1_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF1_SRIOV_BAR5_SIZE {128} \
          CPM_PCIE1_PF1_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF1_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_PF1_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE1_PF1_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE1_PF1_SRIOV_CAP_VER {1} \
          CPM_PCIE1_PF1_SRIOV_FIRST_VF_OFFSET {7} \
          CPM_PCIE1_PF1_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE1_PF1_SRIOV_SUPPORTED_PAGE_SIZE {553} \
          CPM_PCIE1_PF1_SRIOV_VF_DEVICE_ID {C13F} \
          CPM_PCIE1_PF1_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE1_PF1_SUB_CLASS_VALUE {80} \
          CPM_PCIE1_PF1_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE1_PF1_VEND_ID {0} \
          CPM_PCIE1_PF2_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE1_PF2_ATS_CAP_ON {0} \
          CPM_PCIE1_PF2_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE1_PF2_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE1_PF2_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE1_PF2_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE1_PF2_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE1_PF2_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE1_PF2_BAR0_64BIT {0} \
          CPM_PCIE1_PF2_BAR0_ENABLED {1} \
          CPM_PCIE1_PF2_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR0_QDMA_AXCACHE {1} \
          CPM_PCIE1_PF2_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR0_SIZE {128} \
          CPM_PCIE1_PF2_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR0_XDMA_AXCACHE {1} \
          CPM_PCIE1_PF2_BAR1_64BIT {0} \
          CPM_PCIE1_PF2_BAR1_ENABLED {0} \
          CPM_PCIE1_PF2_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR1_SIZE {4} \
          CPM_PCIE1_PF2_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR2_64BIT {0} \
          CPM_PCIE1_PF2_BAR2_ENABLED {0} \
          CPM_PCIE1_PF2_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR2_SIZE {4} \
          CPM_PCIE1_PF2_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR3_64BIT {0} \
          CPM_PCIE1_PF2_BAR3_ENABLED {0} \
          CPM_PCIE1_PF2_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR3_SIZE {4} \
          CPM_PCIE1_PF2_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR4_64BIT {0} \
          CPM_PCIE1_PF2_BAR4_ENABLED {0} \
          CPM_PCIE1_PF2_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR4_SIZE {4} \
          CPM_PCIE1_PF2_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR5_64BIT {0} \
          CPM_PCIE1_PF2_BAR5_ENABLED {0} \
          CPM_PCIE1_PF2_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_BAR5_SIZE {4} \
          CPM_PCIE1_PF2_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF2_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF2_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE1_PF2_BASE_CLASS_VALUE {05} \
          CPM_PCIE1_PF2_CAPABILITY_POINTER {80} \
          CPM_PCIE1_PF2_CFG_DEV_ID {B23F} \
          CPM_PCIE1_PF2_CFG_REV_ID {0} \
          CPM_PCIE1_PF2_CFG_SUBSYS_ID {7} \
          CPM_PCIE1_PF2_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE1_PF2_CLASS_CODE {0x000} \
          CPM_PCIE1_PF2_DSN_CAP_ENABLE {0} \
          CPM_PCIE1_PF2_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE1_PF2_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE1_PF2_INTERFACE_VALUE {00} \
          CPM_PCIE1_PF2_INTERRUPT_PIN {NONE} \
          CPM_PCIE1_PF2_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_PF2_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_PF2_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_PF2_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_PF2_MSIX_CAP_TABLE_SIZE {007} \
          CPM_PCIE1_PF2_MSIX_ENABLED {1} \
          CPM_PCIE1_PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE1_PF2_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE1_PF2_MSI_ENABLED {0} \
          CPM_PCIE1_PF2_PASID_CAP_MAX_PASID_WIDTH {1} \
          CPM_PCIE1_PF2_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE1_PF2_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE1_PF2_PRI_CAP_ON {0} \
          CPM_PCIE1_PF2_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR0_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE1_PF2_SRIOV_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR0_SIZE {2} \
          CPM_PCIE1_PF2_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR1_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR2_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR2_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR2_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR3_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR4_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE1_PF2_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE1_PF2_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF2_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF2_SRIOV_BAR5_SIZE {128} \
          CPM_PCIE1_PF2_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF2_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_PF2_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE1_PF2_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE1_PF2_SRIOV_CAP_VER {1} \
          CPM_PCIE1_PF2_SRIOV_FIRST_VF_OFFSET {10} \
          CPM_PCIE1_PF2_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE1_PF2_SRIOV_SUPPORTED_PAGE_SIZE {553} \
          CPM_PCIE1_PF2_SRIOV_VF_DEVICE_ID {C23F} \
          CPM_PCIE1_PF2_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE1_PF2_SUB_CLASS_VALUE {80} \
          CPM_PCIE1_PF2_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE1_PF2_VEND_ID {0} \
          CPM_PCIE1_PF3_ARI_CAP_NEXT_FUNC {0} \
          CPM_PCIE1_PF3_ATS_CAP_ON {0} \
          CPM_PCIE1_PF3_AXILITE_MASTER_64BIT {0} \
          CPM_PCIE1_PF3_AXILITE_MASTER_ENABLED {0} \
          CPM_PCIE1_PF3_AXILITE_MASTER_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_AXILITE_MASTER_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_AXILITE_MASTER_SIZE {128} \
          CPM_PCIE1_PF3_AXIST_BYPASS_64BIT {0} \
          CPM_PCIE1_PF3_AXIST_BYPASS_ENABLED {0} \
          CPM_PCIE1_PF3_AXIST_BYPASS_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_AXIST_BYPASS_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_AXIST_BYPASS_SIZE {128} \
          CPM_PCIE1_PF3_BAR0_64BIT {0} \
          CPM_PCIE1_PF3_BAR0_ENABLED {1} \
          CPM_PCIE1_PF3_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR0_QDMA_AXCACHE {1} \
          CPM_PCIE1_PF3_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR0_SIZE {128} \
          CPM_PCIE1_PF3_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR0_XDMA_AXCACHE {1} \
          CPM_PCIE1_PF3_BAR1_64BIT {0} \
          CPM_PCIE1_PF3_BAR1_ENABLED {0} \
          CPM_PCIE1_PF3_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR1_SIZE {4} \
          CPM_PCIE1_PF3_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR1_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR2_64BIT {0} \
          CPM_PCIE1_PF3_BAR2_ENABLED {0} \
          CPM_PCIE1_PF3_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR2_SIZE {4} \
          CPM_PCIE1_PF3_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR2_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR3_64BIT {0} \
          CPM_PCIE1_PF3_BAR3_ENABLED {0} \
          CPM_PCIE1_PF3_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR3_SIZE {4} \
          CPM_PCIE1_PF3_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR3_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR4_64BIT {0} \
          CPM_PCIE1_PF3_BAR4_ENABLED {0} \
          CPM_PCIE1_PF3_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR4_SIZE {4} \
          CPM_PCIE1_PF3_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR4_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR5_64BIT {0} \
          CPM_PCIE1_PF3_BAR5_ENABLED {0} \
          CPM_PCIE1_PF3_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_BAR5_SIZE {4} \
          CPM_PCIE1_PF3_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF3_BAR5_XDMA_AXCACHE {0} \
          CPM_PCIE1_PF3_BASE_CLASS_MENU {Memory_controller} \
          CPM_PCIE1_PF3_BASE_CLASS_VALUE {05} \
          CPM_PCIE1_PF3_CAPABILITY_POINTER {80} \
          CPM_PCIE1_PF3_CFG_DEV_ID {B33F} \
          CPM_PCIE1_PF3_CFG_REV_ID {0} \
          CPM_PCIE1_PF3_CFG_SUBSYS_ID {7} \
          CPM_PCIE1_PF3_CFG_SUBSYS_VEND_ID {10EE} \
          CPM_PCIE1_PF3_CLASS_CODE {0x000} \
          CPM_PCIE1_PF3_DSN_CAP_ENABLE {0} \
          CPM_PCIE1_PF3_EXPANSION_ROM_ENABLED {0} \
          CPM_PCIE1_PF3_EXPANSION_ROM_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_EXPANSION_ROM_SIZE {2} \
          CPM_PCIE1_PF3_INTERFACE_VALUE {00} \
          CPM_PCIE1_PF3_INTERRUPT_PIN {NONE} \
          CPM_PCIE1_PF3_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_PF3_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_PF3_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_PF3_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_PF3_MSIX_CAP_TABLE_SIZE {007} \
          CPM_PCIE1_PF3_MSIX_ENABLED {1} \
          CPM_PCIE1_PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
          CPM_PCIE1_PF3_MSI_CAP_PERVECMASKCAP {0} \
          CPM_PCIE1_PF3_MSI_ENABLED {0} \
          CPM_PCIE1_PF3_PCIEBAR2AXIBAR_AXIL_MASTER {0x0000000000000000} \
          CPM_PCIE1_PF3_PCIEBAR2AXIBAR_AXIST_BYPASS {0x0000000000000000} \
          CPM_PCIE1_PF3_PRI_CAP_ON {0} \
          CPM_PCIE1_PF3_SRIOV_ARI_CAPBL_HIER_PRESERVED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR0_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR0_ENABLED {1} \
          CPM_PCIE1_PF3_SRIOV_BAR0_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR0_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR0_SIZE {2} \
          CPM_PCIE1_PF3_SRIOV_BAR0_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR1_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR1_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR1_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR1_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR1_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR1_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR2_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR2_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR2_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR2_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR2_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR2_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR3_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR3_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR3_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR3_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR3_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR3_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR4_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR4_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR4_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR4_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR4_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR4_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_BAR5_64BIT {0} \
          CPM_PCIE1_PF3_SRIOV_BAR5_ENABLED {0} \
          CPM_PCIE1_PF3_SRIOV_BAR5_PREFETCHABLE {0} \
          CPM_PCIE1_PF3_SRIOV_BAR5_SCALE {Kilobytes} \
          CPM_PCIE1_PF3_SRIOV_BAR5_SIZE {128} \
          CPM_PCIE1_PF3_SRIOV_BAR5_TYPE {Memory} \
          CPM_PCIE1_PF3_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_PF3_SRIOV_CAP_INITIAL_VF {4} \
          CPM_PCIE1_PF3_SRIOV_CAP_TOTAL_VF {0} \
          CPM_PCIE1_PF3_SRIOV_CAP_VER {1} \
          CPM_PCIE1_PF3_SRIOV_FIRST_VF_OFFSET {13} \
          CPM_PCIE1_PF3_SRIOV_FUNC_DEP_LINK {0} \
          CPM_PCIE1_PF3_SRIOV_SUPPORTED_PAGE_SIZE {553} \
          CPM_PCIE1_PF3_SRIOV_VF_DEVICE_ID {C33F} \
          CPM_PCIE1_PF3_SUB_CLASS_INTF_MENU {Other_memory_controller} \
          CPM_PCIE1_PF3_SUB_CLASS_VALUE {80} \
          CPM_PCIE1_PF3_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE1_PF3_VEND_ID {0} \
          CPM_PCIE1_PL_LINK_CAP_MAX_LINK_SPEED {Gen3} \
          CPM_PCIE1_PL_LINK_CAP_MAX_LINK_WIDTH {NONE} \
          CPM_PCIE1_PL_UPSTREAM_FACING {1} \
          CPM_PCIE1_PL_USER_SPARE {0} \
          CPM_PCIE1_PM_ASPML0S_TIMEOUT {0} \
          CPM_PCIE1_PM_ASPML1_ENTRY_DELAY {0} \
          CPM_PCIE1_PM_ENABLE_L23_ENTRY {0} \
          CPM_PCIE1_PM_ENABLE_SLOT_POWER_CAPTURE {1} \
          CPM_PCIE1_PM_L1_REENTRY_DELAY {0} \
          CPM_PCIE1_PM_PME_TURNOFF_ACK_DELAY {0} \
          CPM_PCIE1_PORT_TYPE {PCI_Express_Endpoint_device} \
          CPM_PCIE1_REF_CLK_FREQ {100_MHz} \
          CPM_PCIE1_SRIOV_CAP_ENABLE {0} \
          CPM_PCIE1_SRIOV_FIRST_VF_OFFSET {4} \
          CPM_PCIE1_TL2CFG_IF_PARITY_CHK {0} \
          CPM_PCIE1_TL_NP_FIFO_NUM_TLPS {0} \
          CPM_PCIE1_TL_PF_ENABLE_REG {1} \
          CPM_PCIE1_TL_POSTED_RAM_SIZE {0} \
          CPM_PCIE1_TL_USER_SPARE {0} \
          CPM_PCIE1_TX_FC_IF {0} \
          CPM_PCIE1_TYPE1_MEMBASE_MEMLIMIT_ENABLE {Disabled} \
          CPM_PCIE1_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT {Disabled} \
          CPM_PCIE1_USER_CLK2_FREQ {125_MHz} \
          CPM_PCIE1_USER_CLK_FREQ {125_MHz} \
          CPM_PCIE1_VC0_CAPABILITY_POINTER {80} \
          CPM_PCIE1_VC1_BASE_DISABLE {0} \
          CPM_PCIE1_VFG0_ATS_CAP_ON {0} \
          CPM_PCIE1_VFG0_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_VFG0_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_VFG0_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_VFG0_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_VFG0_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE1_VFG0_MSIX_ENABLED {0} \
          CPM_PCIE1_VFG0_PRI_CAP_ON {0} \
          CPM_PCIE1_VFG1_ATS_CAP_ON {0} \
          CPM_PCIE1_VFG1_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_VFG1_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_VFG1_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_VFG1_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_VFG1_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE1_VFG1_MSIX_ENABLED {0} \
          CPM_PCIE1_VFG1_PRI_CAP_ON {0} \
          CPM_PCIE1_VFG2_ATS_CAP_ON {0} \
          CPM_PCIE1_VFG2_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_VFG2_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_VFG2_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_VFG2_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_VFG2_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE1_VFG2_MSIX_ENABLED {0} \
          CPM_PCIE1_VFG2_PRI_CAP_ON {0} \
          CPM_PCIE1_VFG3_ATS_CAP_ON {0} \
          CPM_PCIE1_VFG3_MSIX_CAP_PBA_BIR {BAR_0} \
          CPM_PCIE1_VFG3_MSIX_CAP_PBA_OFFSET {50} \
          CPM_PCIE1_VFG3_MSIX_CAP_TABLE_BIR {BAR_0} \
          CPM_PCIE1_VFG3_MSIX_CAP_TABLE_OFFSET {40} \
          CPM_PCIE1_VFG3_MSIX_CAP_TABLE_SIZE {1} \
          CPM_PCIE1_VFG3_MSIX_ENABLED {0} \
          CPM_PCIE1_VFG3_PRI_CAP_ON {0} \
          CPM_PCIE_CHANNELS_FOR_POWER {1} \
          CPM_PERIPHERAL_EN {1} \
          CPM_PERIPHERAL_TEST_EN {0} \
          CPM_REQ_AGENTS_0_ENABLE {0} \
          CPM_REQ_AGENTS_0_L2_ENABLE {0} \
          CPM_REQ_AGENTS_1_ENABLE {0} \
          CPM_SELECT_GTOUTCLK {TXOUTCLK} \
          CPM_TYPE1_MEMBASE_MEMLIMIT_ENABLE {Disabled} \
          CPM_TYPE1_PREFETCHABLE_MEMBASE_MEMLIMIT {Disabled} \
          CPM_USE_MODES {None} \
          CPM_XDMA_2PF_INTERRUPT_ENABLE {0} \
          CPM_XDMA_TL_PF_VISIBLE {1} \
          CPM_XPIPE_0_CLKDLY_CFG {536870912} \
          CPM_XPIPE_0_CLK_CFG {1044480} \
          CPM_XPIPE_0_INSTANTIATED {1} \
          CPM_XPIPE_0_LINK0_CFG {X16} \
          CPM_XPIPE_0_LINK1_CFG {DISABLE} \
          CPM_XPIPE_0_LOC {QUAD0} \
          CPM_XPIPE_0_MODE {3} \
          CPM_XPIPE_0_REG_CFG {8164} \
          CPM_XPIPE_0_RSVD {16} \
          CPM_XPIPE_1_CLKDLY_CFG {570427392} \
          CPM_XPIPE_1_CLK_CFG {983040} \
          CPM_XPIPE_1_INSTANTIATED {1} \
          CPM_XPIPE_1_LINK0_CFG {X16} \
          CPM_XPIPE_1_LINK1_CFG {DISABLE} \
          CPM_XPIPE_1_LOC {QUAD0} \
          CPM_XPIPE_1_MODE {3} \
          CPM_XPIPE_1_REG_CFG {8155} \
          CPM_XPIPE_1_RSVD {16} \
          CPM_XPIPE_2_CLKDLY_CFG {50331778} \
          CPM_XPIPE_2_CLK_CFG {1044480} \
          CPM_XPIPE_2_INSTANTIATED {1} \
          CPM_XPIPE_2_LINK0_CFG {X16} \
          CPM_XPIPE_2_LINK1_CFG {DISABLE} \
          CPM_XPIPE_2_LOC {QUAD0} \
          CPM_XPIPE_2_MODE {3} \
          CPM_XPIPE_2_REG_CFG {8146} \
          CPM_XPIPE_2_RSVD {16} \
          CPM_XPIPE_3_CLKDLY_CFG {16777218} \
          CPM_XPIPE_3_CLK_CFG {1048320} \
          CPM_XPIPE_3_INSTANTIATED {1} \
          CPM_XPIPE_3_LINK0_CFG {X16} \
          CPM_XPIPE_3_LINK1_CFG {DISABLE} \
          CPM_XPIPE_3_LOC {QUAD0} \
          CPM_XPIPE_3_MODE {3} \
          CPM_XPIPE_3_REG_CFG {8137} \
          CPM_XPIPE_3_RSVD {16} \
          GT_REFCLK_MHZ {156.25} \
          PS_HSDP0_REFCLK {0} \
          PS_HSDP1_REFCLK {0} \
          PS_HSDP_EGRESS_TRAFFIC {JTAG} \
          PS_HSDP_INGRESS_TRAFFIC {JTAG} \
          PS_HSDP_MODE {NONE} \
          PS_USE_NOC_PS_PCI_0 {0} \
          PS_USE_PS_NOC_PCI_0 {1} \
          PS_USE_PS_NOC_PCI_1 {1} \
        } \
        CONFIG.DDR_MEMORY_MODE {Custom} \
        CONFIG.DEBUG_MODE {Custom} \
        CONFIG.DESIGN_MODE {1} \
        CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
        CONFIG.PS_PMC_CONFIG { \
          BOOT_MODE {Custom} \
          CLOCK_MODE {Custom} \
          DDR_MEMORY_MODE {Custom} \
          DEBUG_MODE {Custom} \
          DESIGN_MODE {1} \
          PCIE_APERTURES_DUAL_ENABLE {0} \
          PCIE_APERTURES_SINGLE_ENABLE {1} \
          PMC_CRP_PL0_REF_CTRL_FREQMHZ {200} \
          PMC_CRP_QSPI_REF_CTRL_FREQMHZ {150} \
          PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
          PMC_QSPI_PERIPHERAL_ENABLE {1} \
          PMC_QSPI_PERIPHERAL_MODE {Single} \
          PMC_USE_NOC_PMC_AXI0 {1} \
          PMC_USE_PMC_NOC_AXI0 {1} \
          PS_BOARD_INTERFACE {Custom} \
          PS_HSDP_INGRESS_TRAFFIC {JTAG} \
          PS_NUM_FABRIC_RESETS {1} \
          PS_PCIE1_PERIPHERAL_ENABLE {1} \
          PS_PCIE2_PERIPHERAL_ENABLE {0} \
          PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
          PS_PCIE_RESET {{ENABLE 1}} \
          PS_PL_CONNECTIVITY_MODE {Custom} \
          PS_USE_M_AXI_LPD {0} \
          PS_USE_PMCPL_CLK0 {1} \
          SMON_ALARMS {Set_Alarms_On} \
          SMON_ENABLE_TEMP_AVERAGING {0} \
          SMON_TEMP_AVERAGING_SAMPLES {0} \
        } \
        CONFIG.PS_PMC_CONFIG_APPLIED {1} \
      ] $versal_cips_0
  
    }
  } else { ;# VCK190 

    set_property -dict [list \
      CONFIG.BOOT_MODE {Custom} \
      CONFIG.CLOCK_MODE {Custom} \
      CONFIG.CPM_CONFIG { \
        CPM_PCIE0_BRIDGE_AXI_SLAVE_IF {0} \
        CPM_PCIE0_DMA_INTF {AXI_MM_and_AXI_Stream} \
        CPM_PCIE0_FUNCTIONAL_MODE {QDMA} \
        CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s} \
        CPM_PCIE0_MODES {DMA} \
        CPM_PCIE0_MODE_SELECTION {Advanced} \
        CPM_PCIE0_MSI_X_OPTIONS {MSI-X_Internal} \
        CPM_PCIE0_PF0_BAR0_QDMA_64BIT {1} \
        CPM_PCIE0_PF0_BAR0_QDMA_AXCACHE {0} \
        CPM_PCIE0_PF0_BAR0_QDMA_PREFETCHABLE {1} \
        CPM_PCIE0_PF0_BAR0_QDMA_TYPE {DMA} \
        CPM_PCIE0_PF0_BAR2_QDMA_64BIT {1} \
        CPM_PCIE0_PF0_BAR2_QDMA_ENABLED {1} \
        CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE {1} \
        CPM_PCIE0_PF0_BAR2_QDMA_SCALE {Kilobytes} \
        CPM_PCIE0_PF0_BAR2_QDMA_SIZE {64} \
        CPM_PCIE0_PF0_BAR4_QDMA_64BIT {0} \
        CPM_PCIE0_PF0_BAR4_QDMA_ENABLED {1} \
        CPM_PCIE0_PF0_BAR4_QDMA_PREFETCHABLE {0} \
        CPM_PCIE0_PF0_BAR4_QDMA_SIZE {64} \
        CPM_PCIE0_PF0_BAR5_QDMA_ENABLED {0} \
        CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x20180000000} \
        CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
        CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
        CPM_PCIE0_TANDEM {Tandem_PCIe} \
        PS_USE_NOC_PS_PCI_0 {1} \
      } \
      CONFIG.DDR_MEMORY_MODE {Custom} \
      CONFIG.PS_PMC_CONFIG { \
        AURORA_LINE_RATE_GPBS {12.5} \
        BOOT_MODE {Custom} \
        BOOT_SECONDARY_PCIE_ENABLE {0} \
        CLOCK_MODE {Custom} \
        COHERENCY_MODE {Custom} \
        CPM_PCIE0_TANDEM {None} \
        DDR_MEMORY_MODE {Custom} \
        DEBUG_MODE {Custom} \
        DESIGN_MODE {1} \
        DEVICE_INTEGRITY_MODE {Custom} \
        DIS_AUTO_POL_CHECK {0} \
        GT_REFCLK_MHZ {156.25} \
        INIT_CLK_MHZ {125} \
        INV_POLARITY {0} \
        IO_CONFIG_MODE {Custom} \
        OT_EAM_RESP {SRST} \
        PCIE_APERTURES_DUAL_ENABLE {0} \
        PCIE_APERTURES_SINGLE_ENABLE {1} \
        PERFORMANCE_MODE {Custom} \
        PL_SEM_GPIO_ENABLE {0} \
        PMC_ALT_REF_CLK_FREQMHZ {33.333} \
        PMC_BANK_0_IO_STANDARD {LVCMOS1.8} \
        PMC_BANK_1_IO_STANDARD {LVCMOS1.8} \
        PMC_CIPS_MODE {ADVANCE} \
        PMC_CORE_SUBSYSTEM_LOAD {10} \
        PMC_CRP_CFU_REF_CTRL_ACT_FREQMHZ {399.996002} \
        PMC_CRP_CFU_REF_CTRL_DIVISOR0 {3} \
        PMC_CRP_CFU_REF_CTRL_FREQMHZ {400} \
        PMC_CRP_CFU_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_DFT_OSC_REF_CTRL_ACT_FREQMHZ {400} \
        PMC_CRP_DFT_OSC_REF_CTRL_DIVISOR0 {3} \
        PMC_CRP_DFT_OSC_REF_CTRL_FREQMHZ {400} \
        PMC_CRP_DFT_OSC_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_EFUSE_REF_CTRL_ACT_FREQMHZ {100.000000} \
        PMC_CRP_EFUSE_REF_CTRL_FREQMHZ {100.000000} \
        PMC_CRP_EFUSE_REF_CTRL_SRCSEL {IRO_CLK/4} \
        PMC_CRP_HSM0_REF_CTRL_ACT_FREQMHZ {33.333000} \
        PMC_CRP_HSM0_REF_CTRL_DIVISOR0 {36} \
        PMC_CRP_HSM0_REF_CTRL_FREQMHZ {33.333} \
        PMC_CRP_HSM0_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_HSM1_REF_CTRL_ACT_FREQMHZ {133.332001} \
        PMC_CRP_HSM1_REF_CTRL_DIVISOR0 {9} \
        PMC_CRP_HSM1_REF_CTRL_FREQMHZ {133.333} \
        PMC_CRP_HSM1_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_I2C_REF_CTRL_ACT_FREQMHZ {100} \
        PMC_CRP_I2C_REF_CTRL_DIVISOR0 {12} \
        PMC_CRP_I2C_REF_CTRL_FREQMHZ {100} \
        PMC_CRP_I2C_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_LSBUS_REF_CTRL_ACT_FREQMHZ {149.998505} \
        PMC_CRP_LSBUS_REF_CTRL_DIVISOR0 {8} \
        PMC_CRP_LSBUS_REF_CTRL_FREQMHZ {150} \
        PMC_CRP_LSBUS_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_NOC_REF_CTRL_ACT_FREQMHZ {999.989990} \
        PMC_CRP_NOC_REF_CTRL_FREQMHZ {1000} \
        PMC_CRP_NOC_REF_CTRL_SRCSEL {NPLL} \
        PMC_CRP_NPI_REF_CTRL_ACT_FREQMHZ {299.997009} \
        PMC_CRP_NPI_REF_CTRL_DIVISOR0 {4} \
        PMC_CRP_NPI_REF_CTRL_FREQMHZ {300} \
        PMC_CRP_NPI_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_NPLL_CTRL_CLKOUTDIV {4} \
        PMC_CRP_NPLL_CTRL_FBDIV {120} \
        PMC_CRP_NPLL_CTRL_SRCSEL {REF_CLK} \
        PMC_CRP_NPLL_TO_XPD_CTRL_DIVISOR0 {4} \
        PMC_CRP_OSPI_REF_CTRL_ACT_FREQMHZ {200} \
        PMC_CRP_OSPI_REF_CTRL_DIVISOR0 {4} \
        PMC_CRP_OSPI_REF_CTRL_FREQMHZ {200} \
        PMC_CRP_OSPI_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_PL0_REF_CTRL_ACT_FREQMHZ {249.997498} \
        PMC_CRP_PL0_REF_CTRL_DIVISOR0 {4} \
        PMC_CRP_PL0_REF_CTRL_FREQMHZ {250} \
        PMC_CRP_PL0_REF_CTRL_SRCSEL {NPLL} \
        PMC_CRP_PL1_REF_CTRL_ACT_FREQMHZ {100} \
        PMC_CRP_PL1_REF_CTRL_DIVISOR0 {3} \
        PMC_CRP_PL1_REF_CTRL_FREQMHZ {334} \
        PMC_CRP_PL1_REF_CTRL_SRCSEL {NPLL} \
        PMC_CRP_PL2_REF_CTRL_ACT_FREQMHZ {100} \
        PMC_CRP_PL2_REF_CTRL_DIVISOR0 {3} \
        PMC_CRP_PL2_REF_CTRL_FREQMHZ {334} \
        PMC_CRP_PL2_REF_CTRL_SRCSEL {NPLL} \
        PMC_CRP_PL3_REF_CTRL_ACT_FREQMHZ {100} \
        PMC_CRP_PL3_REF_CTRL_DIVISOR0 {3} \
        PMC_CRP_PL3_REF_CTRL_FREQMHZ {334} \
        PMC_CRP_PL3_REF_CTRL_SRCSEL {NPLL} \
        PMC_CRP_PL5_REF_CTRL_FREQMHZ {400} \
        PMC_CRP_PPLL_CTRL_CLKOUTDIV {2} \
        PMC_CRP_PPLL_CTRL_FBDIV {72} \
        PMC_CRP_PPLL_CTRL_SRCSEL {REF_CLK} \
        PMC_CRP_PPLL_TO_XPD_CTRL_DIVISOR0 {1} \
        PMC_CRP_QSPI_REF_CTRL_ACT_FREQMHZ {299.997009} \
        PMC_CRP_QSPI_REF_CTRL_DIVISOR0 {4} \
        PMC_CRP_QSPI_REF_CTRL_FREQMHZ {300} \
        PMC_CRP_QSPI_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_SDIO0_REF_CTRL_ACT_FREQMHZ {200} \
        PMC_CRP_SDIO0_REF_CTRL_DIVISOR0 {6} \
        PMC_CRP_SDIO0_REF_CTRL_FREQMHZ {200} \
        PMC_CRP_SDIO0_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_SDIO1_REF_CTRL_ACT_FREQMHZ {200} \
        PMC_CRP_SDIO1_REF_CTRL_DIVISOR0 {6} \
        PMC_CRP_SDIO1_REF_CTRL_FREQMHZ {200} \
        PMC_CRP_SDIO1_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_SD_DLL_REF_CTRL_ACT_FREQMHZ {1200} \
        PMC_CRP_SD_DLL_REF_CTRL_DIVISOR0 {1} \
        PMC_CRP_SD_DLL_REF_CTRL_FREQMHZ {1200} \
        PMC_CRP_SD_DLL_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_SWITCH_TIMEOUT_CTRL_ACT_FREQMHZ {1.000000} \
        PMC_CRP_SWITCH_TIMEOUT_CTRL_DIVISOR0 {100} \
        PMC_CRP_SWITCH_TIMEOUT_CTRL_FREQMHZ {1} \
        PMC_CRP_SWITCH_TIMEOUT_CTRL_SRCSEL {IRO_CLK/4} \
        PMC_CRP_SYSMON_REF_CTRL_ACT_FREQMHZ {299.997009} \
        PMC_CRP_SYSMON_REF_CTRL_FREQMHZ {299.997009} \
        PMC_CRP_SYSMON_REF_CTRL_SRCSEL {NPI_REF_CLK} \
        PMC_CRP_TEST_PATTERN_REF_CTRL_ACT_FREQMHZ {200} \
        PMC_CRP_TEST_PATTERN_REF_CTRL_DIVISOR0 {6} \
        PMC_CRP_TEST_PATTERN_REF_CTRL_FREQMHZ {200} \
        PMC_CRP_TEST_PATTERN_REF_CTRL_SRCSEL {PPLL} \
        PMC_CRP_USB_SUSPEND_CTRL_ACT_FREQMHZ {0.200000} \
        PMC_CRP_USB_SUSPEND_CTRL_DIVISOR0 {500} \
        PMC_CRP_USB_SUSPEND_CTRL_FREQMHZ {0.2} \
        PMC_CRP_USB_SUSPEND_CTRL_SRCSEL {IRO_CLK/4} \
        PMC_EXTERNAL_TAMPER {{ENABLE 0} {IO NONE}} \
        PMC_EXTERNAL_TAMPER_1 {{ENABLE 0} {IO None}} \
        PMC_EXTERNAL_TAMPER_2 {{ENABLE 0} {IO None}} \
        PMC_EXTERNAL_TAMPER_3 {{ENABLE 0} {IO None}} \
        PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 25}}} \
        PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 26 .. 51}}} \
        PMC_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
        PMC_GPIO_EMIO_WIDTH {64} \
        PMC_GPIO_EMIO_WIDTH_HDL {64} \
        PMC_GPI_ENABLE {0} \
        PMC_GPI_WIDTH {32} \
        PMC_GPO_ENABLE {0} \
        PMC_GPO_WIDTH {32} \
        PMC_HSM0_CLK_ENABLE {1} \
        PMC_HSM1_CLK_ENABLE {1} \
        PMC_I2CPMC_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 2 .. 3}}} \
        PMC_MIO0 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO1 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO10 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO11 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO12 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO13 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO14 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO15 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO16 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO17 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO18 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO2 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO20 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO22 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO23 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO24 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO25 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO26 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO27 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO28 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO29 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO3 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO30 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO31 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO32 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO33 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO34 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO35 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO36 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO37 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO38 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
        PMC_MIO39 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO4 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO40 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO41 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO42 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO43 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO44 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO45 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO46 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO47 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO48 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO49 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO5 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO50 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO51 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PMC_MIO6 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO7 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO8 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO9 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 12mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW fast} {USAGE Unassigned}} \
        PMC_MIO_EN_FOR_PL_PCIE {0} \
        PMC_MIO_TREE_PERIPHERALS {QSPI#QSPI#QSPI#QSPI#QSPI#QSPI#Loopback Clk#QSPI#QSPI#QSPI#QSPI#QSPI#QSPI##########################PCIE#######################################} \
        PMC_MIO_TREE_SIGNALS {qspi0_clk#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]#qspi0_io[0]#qspi0_cs_b#qspi_lpbk#qspi1_cs_b#qspi1_io[0]#qspi1_io[1]#qspi1_io[2]#qspi1_io[3]#qspi1_clk##########################reset1_n#######################################}\
  \
        PMC_NOC_PMC_ADDR_WIDTH {64} \
        PMC_NOC_PMC_DATA_WIDTH {128} \
        PMC_OSPI_COHERENCY {0} \
        PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
        PMC_OSPI_ROUTE_THROUGH_FPD {0} \
        PMC_PL_ALT_REF_CLK_FREQMHZ {33.333} \
        PMC_PMC_NOC_ADDR_WIDTH {64} \
        PMC_PMC_NOC_DATA_WIDTH {128} \
        PMC_QSPI_COHERENCY {0} \
        PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
        PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
        PMC_QSPI_PERIPHERAL_ENABLE {1} \
        PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
        PMC_QSPI_ROUTE_THROUGH_FPD {0} \
        PMC_REF_CLK_FREQMHZ {33.333} \
        PMC_SD0 {{CD_ENABLE 0} {CD_IO {PMC_MIO 24}} {POW_ENABLE 0} {POW_IO {PMC_MIO 17}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 17}} {WP_ENABLE 0} {WP_IO {PMC_MIO 25}}} \
        PMC_SD0_COHERENCY {0} \
        PMC_SD0_DATA_TRANSFER_MODE {4Bit} \
        PMC_SD0_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x00} {CLK_200_SDR_OTAP_DLY 0x00} {CLK_50_DDR_ITAP_DLY 0x00} {CLK_50_DDR_OTAP_DLY 0x00} {CLK_50_SDR_ITAP_DLY 0x00} {CLK_50_SDR_OTAP_DLY 0x00} {ENABLE 0}\
  {IO {PMC_MIO 13 .. 25}}} \
        PMC_SD0_ROUTE_THROUGH_FPD {0} \
        PMC_SD0_SLOT_TYPE {SD 2.0} \
        PMC_SD0_SPEED_MODE {default speed} \
        PMC_SD1 {{CD_ENABLE 0} {CD_IO {PMC_MIO 2}} {POW_ENABLE 0} {POW_IO {PMC_MIO 12}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
        PMC_SD1_COHERENCY {0} \
        PMC_SD1_DATA_TRANSFER_MODE {4Bit} \
        PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x00} {CLK_200_SDR_OTAP_DLY 0x00} {CLK_50_DDR_ITAP_DLY 0x00} {CLK_50_DDR_OTAP_DLY 0x00} {CLK_50_SDR_ITAP_DLY 0x00} {CLK_50_SDR_OTAP_DLY 0x00} {ENABLE 0}\
  {IO {PMC_MIO 0 .. 11}}} \
        PMC_SD1_ROUTE_THROUGH_FPD {0} \
        PMC_SD1_SLOT_TYPE {SD 2.0} \
        PMC_SD1_SPEED_MODE {default speed} \
        PMC_SHOW_CCI_SMMU_SETTINGS {0} \
        PMC_SMAP_PERIPHERAL {{ENABLE 0} {IO {32 Bit}}} \
        PMC_TAMPER_EXTMIO_ENABLE {0} \
        PMC_TAMPER_EXTMIO_ERASE_BBRAM {0} \
        PMC_TAMPER_EXTMIO_RESPONSE {SYS INTERRUPT} \
        PMC_TAMPER_GLITCHDETECT_ENABLE {0} \
        PMC_TAMPER_GLITCHDETECT_ENABLE_1 {0} \
        PMC_TAMPER_GLITCHDETECT_ENABLE_2 {0} \
        PMC_TAMPER_GLITCHDETECT_ENABLE_3 {0} \
        PMC_TAMPER_GLITCHDETECT_ERASE_BBRAM {0} \
        PMC_TAMPER_GLITCHDETECT_ERASE_BBRAM_1 {0} \
        PMC_TAMPER_GLITCHDETECT_ERASE_BBRAM_2 {0} \
        PMC_TAMPER_GLITCHDETECT_ERASE_BBRAM_3 {0} \
        PMC_TAMPER_GLITCHDETECT_RESPONSE {SYS INTERRUPT} \
        PMC_TAMPER_GLITCHDETECT_RESPONSE_1 {SYS INTERRUPT} \
        PMC_TAMPER_GLITCHDETECT_RESPONSE_2 {SYS INTERRUPT} \
        PMC_TAMPER_GLITCHDETECT_RESPONSE_3 {SYS INTERRUPT} \
        PMC_TAMPER_JTAGDETECT_ENABLE {0} \
        PMC_TAMPER_JTAGDETECT_ENABLE_1 {0} \
        PMC_TAMPER_JTAGDETECT_ENABLE_2 {0} \
        PMC_TAMPER_JTAGDETECT_ENABLE_3 {0} \
        PMC_TAMPER_JTAGDETECT_ERASE_BBRAM {0} \
        PMC_TAMPER_JTAGDETECT_ERASE_BBRAM_1 {0} \
        PMC_TAMPER_JTAGDETECT_ERASE_BBRAM_2 {0} \
        PMC_TAMPER_JTAGDETECT_ERASE_BBRAM_3 {0} \
        PMC_TAMPER_JTAGDETECT_RESPONSE {SYS INTERRUPT} \
        PMC_TAMPER_JTAGDETECT_RESPONSE_1 {SYS INTERRUPT} \
        PMC_TAMPER_JTAGDETECT_RESPONSE_2 {SYS INTERRUPT} \
        PMC_TAMPER_JTAGDETECT_RESPONSE_3 {SYS INTERRUPT} \
        PMC_TAMPER_SUP_0_31_ENABLE {0} \
        PMC_TAMPER_SUP_0_31_ERASE_BBRAM {0} \
        PMC_TAMPER_SUP_0_31_RESPONSE {SYS INTERRUPT} \
        PMC_TAMPER_TEMPERATURE_ENABLE {0} \
        PMC_TAMPER_TEMPERATURE_ENABLE_1 {0} \
        PMC_TAMPER_TEMPERATURE_ENABLE_2 {0} \
        PMC_TAMPER_TEMPERATURE_ENABLE_3 {0} \
        PMC_TAMPER_TEMPERATURE_ERASE_BBRAM {0} \
        PMC_TAMPER_TEMPERATURE_ERASE_BBRAM_1 {0} \
        PMC_TAMPER_TEMPERATURE_ERASE_BBRAM_2 {0} \
        PMC_TAMPER_TEMPERATURE_ERASE_BBRAM_3 {0} \
        PMC_TAMPER_TEMPERATURE_RESPONSE {SYS INTERRUPT} \
        PMC_TAMPER_TEMPERATURE_RESPONSE_1 {SYS INTERRUPT} \
        PMC_TAMPER_TEMPERATURE_RESPONSE_2 {SYS INTERRUPT} \
        PMC_TAMPER_TEMPERATURE_RESPONSE_3 {SYS INTERRUPT} \
        PMC_USE_CFU_SEU {0} \
        PMC_USE_NOC_PMC_AXI0 {1} \
        PMC_USE_NOC_PMC_AXI1 {0} \
        PMC_USE_NOC_PMC_AXI2 {0} \
        PMC_USE_NOC_PMC_AXI3 {0} \
        PMC_USE_PL_PMC_AUX_REF_CLK {0} \
        PMC_USE_PMC_NOC_AXI0 {1} \
        PMC_USE_PMC_NOC_AXI1 {0} \
        PMC_USE_PMC_NOC_AXI2 {0} \
        PMC_USE_PMC_NOC_AXI3 {0} \
        PMC_WDT_PERIOD {100} \
        PMC_WDT_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0}}} \
        POWER_REPORTING_MODE {Custom} \
        PSPMC_MANUAL_CLK_ENABLE {0} \
        PS_A72_ACTIVE_BLOCKS {2} \
        PS_A72_LOAD {90} \
        PS_BANK_2_IO_STANDARD {LVCMOS1.8} \
        PS_BANK_3_IO_STANDARD {LVCMOS1.8} \
        PS_BOARD_INTERFACE {Custom} \
        PS_CAN0_CLK {{ENABLE 0} {IO {PMC_MIO 0}}} \
        PS_CAN0_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 8 .. 9}}} \
        PS_CAN1_CLK {{ENABLE 0} {IO {PMC_MIO 0}}} \
        PS_CAN1_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 16 .. 17}}} \
        PS_CRF_ACPU_CTRL_ACT_FREQMHZ {1399.985962} \
        PS_CRF_ACPU_CTRL_DIVISOR0 {1} \
        PS_CRF_ACPU_CTRL_FREQMHZ {1400} \
        PS_CRF_ACPU_CTRL_SRCSEL {APLL} \
        PS_CRF_APLL_CTRL_CLKOUTDIV {2} \
        PS_CRF_APLL_CTRL_FBDIV {84} \
        PS_CRF_APLL_CTRL_SRCSEL {REF_CLK} \
        PS_CRF_APLL_TO_XPD_CTRL_DIVISOR0 {4} \
        PS_CRF_DBG_FPD_CTRL_ACT_FREQMHZ {399.996002} \
        PS_CRF_DBG_FPD_CTRL_DIVISOR0 {3} \
        PS_CRF_DBG_FPD_CTRL_FREQMHZ {400} \
        PS_CRF_DBG_FPD_CTRL_SRCSEL {PPLL} \
        PS_CRF_DBG_TRACE_CTRL_ACT_FREQMHZ {300} \
        PS_CRF_DBG_TRACE_CTRL_DIVISOR0 {3} \
        PS_CRF_DBG_TRACE_CTRL_FREQMHZ {300} \
        PS_CRF_DBG_TRACE_CTRL_SRCSEL {PPLL} \
        PS_CRF_FPD_LSBUS_CTRL_ACT_FREQMHZ {149.998505} \
        PS_CRF_FPD_LSBUS_CTRL_DIVISOR0 {8} \
        PS_CRF_FPD_LSBUS_CTRL_FREQMHZ {150} \
        PS_CRF_FPD_LSBUS_CTRL_SRCSEL {PPLL} \
        PS_CRF_FPD_TOP_SWITCH_CTRL_ACT_FREQMHZ {824.991760} \
        PS_CRF_FPD_TOP_SWITCH_CTRL_DIVISOR0 {1} \
        PS_CRF_FPD_TOP_SWITCH_CTRL_FREQMHZ {825} \
        PS_CRF_FPD_TOP_SWITCH_CTRL_SRCSEL {RPLL} \
        PS_CRL_CAN0_REF_CTRL_ACT_FREQMHZ {100} \
        PS_CRL_CAN0_REF_CTRL_DIVISOR0 {12} \
        PS_CRL_CAN0_REF_CTRL_FREQMHZ {100} \
        PS_CRL_CAN0_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_CAN1_REF_CTRL_ACT_FREQMHZ {100} \
        PS_CRL_CAN1_REF_CTRL_DIVISOR0 {12} \
        PS_CRL_CAN1_REF_CTRL_FREQMHZ {100} \
        PS_CRL_CAN1_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ {824.991760} \
        PS_CRL_CPM_TOPSW_REF_CTRL_DIVISOR0 {1} \
        PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {825} \
        PS_CRL_CPM_TOPSW_REF_CTRL_SRCSEL {RPLL} \
        PS_CRL_CPU_R5_CTRL_ACT_FREQMHZ {599.994019} \
        PS_CRL_CPU_R5_CTRL_DIVISOR0 {2} \
        PS_CRL_CPU_R5_CTRL_FREQMHZ {600} \
        PS_CRL_CPU_R5_CTRL_SRCSEL {PPLL} \
        PS_CRL_DBG_LPD_CTRL_ACT_FREQMHZ {399.996002} \
        PS_CRL_DBG_LPD_CTRL_DIVISOR0 {3} \
        PS_CRL_DBG_LPD_CTRL_FREQMHZ {400} \
        PS_CRL_DBG_LPD_CTRL_SRCSEL {PPLL} \
        PS_CRL_DBG_TSTMP_CTRL_ACT_FREQMHZ {399.996002} \
        PS_CRL_DBG_TSTMP_CTRL_DIVISOR0 {3} \
        PS_CRL_DBG_TSTMP_CTRL_FREQMHZ {400} \
        PS_CRL_DBG_TSTMP_CTRL_SRCSEL {PPLL} \
        PS_CRL_GEM0_REF_CTRL_ACT_FREQMHZ {125} \
        PS_CRL_GEM0_REF_CTRL_DIVISOR0 {4} \
        PS_CRL_GEM0_REF_CTRL_FREQMHZ {125} \
        PS_CRL_GEM0_REF_CTRL_SRCSEL {NPLL} \
        PS_CRL_GEM1_REF_CTRL_ACT_FREQMHZ {125} \
        PS_CRL_GEM1_REF_CTRL_DIVISOR0 {4} \
        PS_CRL_GEM1_REF_CTRL_FREQMHZ {125} \
        PS_CRL_GEM1_REF_CTRL_SRCSEL {NPLL} \
        PS_CRL_GEM_TSU_REF_CTRL_ACT_FREQMHZ {250} \
        PS_CRL_GEM_TSU_REF_CTRL_DIVISOR0 {2} \
        PS_CRL_GEM_TSU_REF_CTRL_FREQMHZ {250} \
        PS_CRL_GEM_TSU_REF_CTRL_SRCSEL {NPLL} \
        PS_CRL_I2C0_REF_CTRL_ACT_FREQMHZ {100} \
        PS_CRL_I2C0_REF_CTRL_DIVISOR0 {12} \
        PS_CRL_I2C0_REF_CTRL_FREQMHZ {100} \
        PS_CRL_I2C0_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_I2C1_REF_CTRL_ACT_FREQMHZ {100} \
        PS_CRL_I2C1_REF_CTRL_DIVISOR0 {12} \
        PS_CRL_I2C1_REF_CTRL_FREQMHZ {100} \
        PS_CRL_I2C1_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_IOU_SWITCH_CTRL_ACT_FREQMHZ {249.997498} \
        PS_CRL_IOU_SWITCH_CTRL_DIVISOR0 {1} \
        PS_CRL_IOU_SWITCH_CTRL_FREQMHZ {250} \
        PS_CRL_IOU_SWITCH_CTRL_SRCSEL {NPLL} \
        PS_CRL_LPD_LSBUS_CTRL_ACT_FREQMHZ {149.998505} \
        PS_CRL_LPD_LSBUS_CTRL_DIVISOR0 {8} \
        PS_CRL_LPD_LSBUS_CTRL_FREQMHZ {150} \
        PS_CRL_LPD_LSBUS_CTRL_SRCSEL {PPLL} \
        PS_CRL_LPD_TOP_SWITCH_CTRL_ACT_FREQMHZ {599.994019} \
        PS_CRL_LPD_TOP_SWITCH_CTRL_DIVISOR0 {2} \
        PS_CRL_LPD_TOP_SWITCH_CTRL_FREQMHZ {600} \
        PS_CRL_LPD_TOP_SWITCH_CTRL_SRCSEL {PPLL} \
        PS_CRL_PSM_REF_CTRL_ACT_FREQMHZ {399.996002} \
        PS_CRL_PSM_REF_CTRL_DIVISOR0 {3} \
        PS_CRL_PSM_REF_CTRL_FREQMHZ {400} \
        PS_CRL_PSM_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_RPLL_CTRL_CLKOUTDIV {4} \
        PS_CRL_RPLL_CTRL_FBDIV {99} \
        PS_CRL_RPLL_CTRL_SRCSEL {REF_CLK} \
        PS_CRL_RPLL_TO_XPD_CTRL_DIVISOR0 {1} \
        PS_CRL_SPI0_REF_CTRL_ACT_FREQMHZ {200} \
        PS_CRL_SPI0_REF_CTRL_DIVISOR0 {6} \
        PS_CRL_SPI0_REF_CTRL_FREQMHZ {200} \
        PS_CRL_SPI0_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_SPI1_REF_CTRL_ACT_FREQMHZ {200} \
        PS_CRL_SPI1_REF_CTRL_DIVISOR0 {6} \
        PS_CRL_SPI1_REF_CTRL_FREQMHZ {200} \
        PS_CRL_SPI1_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_TIMESTAMP_REF_CTRL_ACT_FREQMHZ {99.999001} \
        PS_CRL_TIMESTAMP_REF_CTRL_DIVISOR0 {12} \
        PS_CRL_TIMESTAMP_REF_CTRL_FREQMHZ {100} \
        PS_CRL_TIMESTAMP_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_UART0_REF_CTRL_ACT_FREQMHZ {100} \
        PS_CRL_UART0_REF_CTRL_DIVISOR0 {12} \
        PS_CRL_UART0_REF_CTRL_FREQMHZ {100} \
        PS_CRL_UART0_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_UART1_REF_CTRL_ACT_FREQMHZ {100} \
        PS_CRL_UART1_REF_CTRL_DIVISOR0 {12} \
        PS_CRL_UART1_REF_CTRL_FREQMHZ {100} \
        PS_CRL_UART1_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_USB0_BUS_REF_CTRL_ACT_FREQMHZ {20} \
        PS_CRL_USB0_BUS_REF_CTRL_DIVISOR0 {60} \
        PS_CRL_USB0_BUS_REF_CTRL_FREQMHZ {20} \
        PS_CRL_USB0_BUS_REF_CTRL_SRCSEL {PPLL} \
        PS_CRL_USB3_DUAL_REF_CTRL_ACT_FREQMHZ {20} \
        PS_CRL_USB3_DUAL_REF_CTRL_DIVISOR0 {60} \
        PS_CRL_USB3_DUAL_REF_CTRL_FREQMHZ {10} \
        PS_CRL_USB3_DUAL_REF_CTRL_SRCSEL {PPLL} \
        PS_DDRC_ENABLE {1} \
        PS_DDR_RAM_HIGHADDR_OFFSET {0x800000000} \
        PS_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
        PS_ENET0_MDIO {{ENABLE 0} {IO {PMC_MIO 50 .. 51}}} \
        PS_ENET0_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 26 .. 37}}} \
        PS_ENET1_MDIO {{ENABLE 0} {IO {PMC_MIO 50 .. 51}}} \
        PS_ENET1_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 38 .. 49}}} \
        PS_EN_AXI_STATUS_PORTS {0} \
        PS_EN_PORTS_CONTROLLER_BASED {0} \
        PS_EXPAND_CORESIGHT {0} \
        PS_EXPAND_FPD_SLAVES {0} \
        PS_EXPAND_GIC {0} \
        PS_EXPAND_LPD_SLAVES {0} \
        PS_FPD_INTERCONNECT_LOAD {90} \
        PS_FTM_CTI_IN0 {0} \
        PS_FTM_CTI_IN1 {0} \
        PS_FTM_CTI_IN2 {0} \
        PS_FTM_CTI_IN3 {0} \
        PS_FTM_CTI_OUT0 {0} \
        PS_FTM_CTI_OUT1 {0} \
        PS_FTM_CTI_OUT2 {0} \
        PS_FTM_CTI_OUT3 {0} \
        PS_GEM0_COHERENCY {0} \
        PS_GEM0_ROUTE_THROUGH_FPD {0} \
        PS_GEM1_COHERENCY {0} \
        PS_GEM1_ROUTE_THROUGH_FPD {0} \
        PS_GEM_TSU {{ENABLE 0} {IO {PS_MIO 24}}} \
        PS_GEM_TSU_CLK_PORT_PAIR {0} \
        PS_GEN_IPI0_ENABLE {0} \
        PS_GEN_IPI0_MASTER {A72} \
        PS_GEN_IPI1_ENABLE {0} \
        PS_GEN_IPI1_MASTER {A72} \
        PS_GEN_IPI2_ENABLE {0} \
        PS_GEN_IPI2_MASTER {A72} \
        PS_GEN_IPI3_ENABLE {0} \
        PS_GEN_IPI3_MASTER {A72} \
        PS_GEN_IPI4_ENABLE {0} \
        PS_GEN_IPI4_MASTER {A72} \
        PS_GEN_IPI5_ENABLE {0} \
        PS_GEN_IPI5_MASTER {A72} \
        PS_GEN_IPI6_ENABLE {0} \
        PS_GEN_IPI6_MASTER {A72} \
        PS_GEN_IPI_PMCNOBUF_ENABLE {1} \
        PS_GEN_IPI_PMCNOBUF_MASTER {PMC} \
        PS_GEN_IPI_PMC_ENABLE {1} \
        PS_GEN_IPI_PMC_MASTER {PMC} \
        PS_GEN_IPI_PSM_ENABLE {1} \
        PS_GEN_IPI_PSM_MASTER {PSM} \
        PS_GPIO2_MIO_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 0 .. 25}}} \
        PS_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
        PS_GPIO_EMIO_WIDTH {32} \
        PS_HSDP0_REFCLK {0} \
        PS_HSDP1_REFCLK {0} \
        PS_HSDP_EGRESS_TRAFFIC {JTAG} \
        PS_HSDP_INGRESS_TRAFFIC {JTAG} \
        PS_HSDP_MODE {NONE} \
        PS_HSDP_SAME_EGRESS_AS_INGRESS_TRAFFIC {1} \
        PS_I2C0_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 2 .. 3}}} \
        PS_I2C1_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 0 .. 1}}} \
        PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 23 .. 24}}} \
        PS_IRQ_USAGE {{CH0 0} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
        PS_LPDMA0_COHERENCY {0} \
        PS_LPDMA0_ROUTE_THROUGH_FPD {0} \
        PS_LPDMA1_COHERENCY {0} \
        PS_LPDMA1_ROUTE_THROUGH_FPD {0} \
        PS_LPDMA2_COHERENCY {0} \
        PS_LPDMA2_ROUTE_THROUGH_FPD {0} \
        PS_LPDMA3_COHERENCY {0} \
        PS_LPDMA3_ROUTE_THROUGH_FPD {0} \
        PS_LPDMA4_COHERENCY {0} \
        PS_LPDMA4_ROUTE_THROUGH_FPD {0} \
        PS_LPDMA5_COHERENCY {0} \
        PS_LPDMA5_ROUTE_THROUGH_FPD {0} \
        PS_LPDMA6_COHERENCY {0} \
        PS_LPDMA6_ROUTE_THROUGH_FPD {0} \
        PS_LPDMA7_COHERENCY {0} \
        PS_LPDMA7_ROUTE_THROUGH_FPD {0} \
        PS_LPD_DMA_CHANNEL_ENABLE {{CH0 0} {CH1 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0}} \
        PS_LPD_DMA_CH_TZ {{CH0 NonSecure} {CH1 NonSecure} {CH2 NonSecure} {CH3 NonSecure} {CH4 NonSecure} {CH5 NonSecure} {CH6 NonSecure} {CH7 NonSecure}} \
        PS_LPD_DMA_ENABLE {0} \
        PS_LPD_INTERCONNECT_LOAD {90} \
        PS_MIO0 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO1 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO10 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO11 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO12 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO13 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO14 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO15 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO16 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO17 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO18 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO2 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO20 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO22 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO23 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO24 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO25 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO3 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO4 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO5 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO6 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO8 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Unassigned}} \
        PS_M_AXI_FPD_DATA_WIDTH {128} \
        PS_M_AXI_GP4_DATA_WIDTH {128} \
        PS_M_AXI_LPD_DATA_WIDTH {128} \
        PS_NOC_PS_CCI_DATA_WIDTH {128} \
        PS_NOC_PS_NCI_DATA_WIDTH {128} \
        PS_NOC_PS_PCI_DATA_WIDTH {128} \
        PS_NOC_PS_PMC_DATA_WIDTH {128} \
        PS_NUM_F2P0_INTR_INPUTS {1} \
        PS_NUM_F2P1_INTR_INPUTS {1} \
        PS_NUM_FABRIC_RESETS {1} \
        PS_OCM_ACTIVE_BLOCKS {1} \
        PS_PCIE1_PERIPHERAL_ENABLE {1} \
        PS_PCIE2_PERIPHERAL_ENABLE {0} \
        PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
        PS_PCIE_EP_RESET2_IO {None} \
        PS_PCIE_PERIPHERAL_ENABLE {0} \
        PS_PCIE_RESET {{ENABLE 1}} \
        PS_PCIE_ROOT_RESET1_IO {None} \
        PS_PCIE_ROOT_RESET1_IO_DIR {output} \
        PS_PCIE_ROOT_RESET1_POLARITY {Active Low} \
        PS_PCIE_ROOT_RESET2_IO {None} \
        PS_PCIE_ROOT_RESET2_IO_DIR {output} \
        PS_PCIE_ROOT_RESET2_POLARITY {Active Low} \
        PS_PL_CONNECTIVITY_MODE {Custom} \
        PS_PL_DONE {0} \
        PS_PL_PASS_AXPROT_VALUE {0} \
        PS_PMCPL_CLK0_BUF {1} \
        PS_PMCPL_CLK1_BUF {1} \
        PS_PMCPL_CLK2_BUF {1} \
        PS_PMCPL_CLK3_BUF {1} \
        PS_PMCPL_IRO_CLK_BUF {1} \
        PS_PMU_PERIPHERAL_ENABLE {0} \
        PS_PS_ENABLE {0} \
        PS_PS_NOC_CCI_DATA_WIDTH {128} \
        PS_PS_NOC_NCI_DATA_WIDTH {128} \
        PS_PS_NOC_PCI_DATA_WIDTH {128} \
        PS_PS_NOC_PMC_DATA_WIDTH {128} \
        PS_PS_NOC_RPU_DATA_WIDTH {128} \
        PS_R5_ACTIVE_BLOCKS {2} \
        PS_R5_LOAD {90} \
        PS_RPU_COHERENCY {0} \
        PS_SLR_TYPE {master} \
        PS_SMON_PL_PORTS_ENABLE {0} \
        PS_SPI0 {{GRP_SS0_ENABLE 0} {GRP_SS0_IO {PMC_MIO 15}} {GRP_SS1_ENABLE 0} {GRP_SS1_IO {PMC_MIO 14}} {GRP_SS2_ENABLE 0} {GRP_SS2_IO {PMC_MIO 13}} {PERIPHERAL_ENABLE 0} {PERIPHERAL_IO {PMC_MIO 12 ..\
  17}}} \
        PS_SPI1 {{GRP_SS0_ENABLE 0} {GRP_SS0_IO {PS_MIO 9}} {GRP_SS1_ENABLE 0} {GRP_SS1_IO {PS_MIO 8}} {GRP_SS2_ENABLE 0} {GRP_SS2_IO {PS_MIO 7}} {PERIPHERAL_ENABLE 0} {PERIPHERAL_IO {PS_MIO 6 .. 11}}} \
        PS_S_AXI_ACE_DATA_WIDTH {128} \
        PS_S_AXI_ACP_DATA_WIDTH {128} \
        PS_S_AXI_FPD_DATA_WIDTH {128} \
        PS_S_AXI_GP2_DATA_WIDTH {128} \
        PS_S_AXI_LPD_DATA_WIDTH {128} \
        PS_TCM_ACTIVE_BLOCKS {2} \
        PS_TIE_MJTAG_TCK_TO_GND {1} \
        PS_TRACE_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 30 .. 47}}} \
        PS_TRACE_WIDTH {2Bit} \
        PS_TRISTATE_INVERTED {1} \
        PS_TTC0_CLK {{ENABLE 0} {IO {PS_MIO 6}}} \
        PS_TTC0_PERIPHERAL_ENABLE {0} \
        PS_TTC0_REF_CTRL_ACT_FREQMHZ {100} \
        PS_TTC0_REF_CTRL_FREQMHZ {100} \
        PS_TTC0_WAVEOUT {{ENABLE 0} {IO {PS_MIO 7}}} \
        PS_TTC1_CLK {{ENABLE 0} {IO {PS_MIO 12}}} \
        PS_TTC1_PERIPHERAL_ENABLE {0} \
        PS_TTC1_REF_CTRL_ACT_FREQMHZ {100} \
        PS_TTC1_REF_CTRL_FREQMHZ {100} \
        PS_TTC1_WAVEOUT {{ENABLE 0} {IO {PS_MIO 13}}} \
        PS_TTC2_CLK {{ENABLE 0} {IO {PS_MIO 2}}} \
        PS_TTC2_PERIPHERAL_ENABLE {0} \
        PS_TTC2_REF_CTRL_ACT_FREQMHZ {100} \
        PS_TTC2_REF_CTRL_FREQMHZ {100} \
        PS_TTC2_WAVEOUT {{ENABLE 0} {IO {PS_MIO 3}}} \
        PS_TTC3_CLK {{ENABLE 0} {IO {PS_MIO 16}}} \
        PS_TTC3_PERIPHERAL_ENABLE {0} \
        PS_TTC3_REF_CTRL_ACT_FREQMHZ {100} \
        PS_TTC3_REF_CTRL_FREQMHZ {100} \
        PS_TTC3_WAVEOUT {{ENABLE 0} {IO {PS_MIO 17}}} \
        PS_TTC_APB_CLK_TTC0_SEL {APB} \
        PS_TTC_APB_CLK_TTC1_SEL {APB} \
        PS_TTC_APB_CLK_TTC2_SEL {APB} \
        PS_TTC_APB_CLK_TTC3_SEL {APB} \
        PS_UART0_BAUD_RATE {115200} \
        PS_UART0_PERIPHERAL {{ENABLE 0} {IO {PS_MIO 0 .. 1}}} \
        PS_UART0_RTS_CTS {{ENABLE 0} {IO {PS_MIO 2 .. 3}}} \
        PS_UART1_BAUD_RATE {115200} \
        PS_UART1_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 4 .. 5}}} \
        PS_UART1_RTS_CTS {{ENABLE 0} {IO {PMC_MIO 6 .. 7}}} \
        PS_UNITS_MODE {Custom} \
        PS_USB3_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 13 .. 25}}} \
        PS_USB_COHERENCY {0} \
        PS_USB_ROUTE_THROUGH_FPD {0} \
        PS_USE_ACE_LITE {0} \
        PS_USE_APU_EVENT_BUS {0} \
        PS_USE_APU_INTERRUPT {0} \
        PS_USE_AXI4_EXT_USER_BITS {0} \
        PS_USE_BSCAN_USER1 {0} \
        PS_USE_BSCAN_USER2 {0} \
        PS_USE_BSCAN_USER3 {0} \
        PS_USE_BSCAN_USER4 {0} \
        PS_USE_CAPTURE {0} \
        PS_USE_CLK {0} \
        PS_USE_DEBUG_TEST {0} \
        PS_USE_DIFF_RW_CLK_S_AXI_FPD {0} \
        PS_USE_DIFF_RW_CLK_S_AXI_GP2 {0} \
        PS_USE_DIFF_RW_CLK_S_AXI_LPD {0} \
        PS_USE_ENET0_PTP {0} \
        PS_USE_ENET1_PTP {0} \
        PS_USE_FIFO_ENET0 {0} \
        PS_USE_FIFO_ENET1 {0} \
        PS_USE_FIXED_IO {0} \
        PS_USE_FPD_AXI_NOC0 {0} \
        PS_USE_FPD_AXI_NOC1 {0} \
        PS_USE_FPD_CCI_NOC {0} \
        PS_USE_FPD_CCI_NOC0 {0} \
        PS_USE_FPD_CCI_NOC1 {0} \
        PS_USE_FPD_CCI_NOC2 {0} \
        PS_USE_FPD_CCI_NOC3 {0} \
        PS_USE_FTM_GPI {0} \
        PS_USE_FTM_GPO {0} \
        PS_USE_HSDP_PL {0} \
        PS_USE_MJTAG_TCK_TIE_OFF {0} \
        PS_USE_M_AXI_FPD {0} \
        PS_USE_M_AXI_LPD {0} \
        PS_USE_NOC_FPD_AXI0 {0} \
        PS_USE_NOC_FPD_AXI1 {0} \
        PS_USE_NOC_FPD_CCI0 {0} \
        PS_USE_NOC_FPD_CCI1 {0} \
        PS_USE_NOC_LPD_AXI0 {0} \
        PS_USE_NOC_PS_PCI_0 {0} \
        PS_USE_NOC_PS_PMC_0 {0} \
        PS_USE_NPI_CLK {0} \
        PS_USE_NPI_RST {0} \
        PS_USE_PL_FPD_AUX_REF_CLK {0} \
        PS_USE_PL_LPD_AUX_REF_CLK {0} \
        PS_USE_PMC {0} \
        PS_USE_PMCPL_CLK0 {1} \
        PS_USE_PMCPL_CLK1 {0} \
        PS_USE_PMCPL_CLK2 {0} \
        PS_USE_PMCPL_CLK3 {0} \
        PS_USE_PMCPL_IRO_CLK {0} \
        PS_USE_PSPL_IRQ_FPD {0} \
        PS_USE_PSPL_IRQ_LPD {0} \
        PS_USE_PSPL_IRQ_PMC {0} \
        PS_USE_PS_NOC_PCI_0 {0} \
        PS_USE_PS_NOC_PCI_1 {0} \
        PS_USE_PS_NOC_PMC_0 {0} \
        PS_USE_PS_NOC_PMC_1 {0} \
        PS_USE_RPU_EVENT {0} \
        PS_USE_RPU_INTERRUPT {0} \
        PS_USE_RTC {0} \
        PS_USE_SMMU {0} \
        PS_USE_STARTUP {0} \
        PS_USE_STM {0} \
        PS_USE_S_ACP_FPD {0} \
        PS_USE_S_AXI_ACE {0} \
        PS_USE_S_AXI_FPD {0} \
        PS_USE_S_AXI_GP2 {0} \
        PS_USE_S_AXI_LPD {0} \
        PS_USE_TRACE_ATB {0} \
        PS_WDT0_REF_CTRL_ACT_FREQMHZ {100} \
        PS_WDT0_REF_CTRL_FREQMHZ {100} \
        PS_WDT0_REF_CTRL_SEL {NONE} \
        PS_WDT1_REF_CTRL_ACT_FREQMHZ {100} \
        PS_WDT1_REF_CTRL_FREQMHZ {100} \
        PS_WDT1_REF_CTRL_SEL {NONE} \
        PS_WWDT0_CLK {{ENABLE 0} {IO {PMC_MIO 0}}} \
        PS_WWDT0_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 5}}} \
        PS_WWDT1_CLK {{ENABLE 0} {IO {PMC_MIO 6}}} \
        PS_WWDT1_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 6 .. 11}}} \
        SEM_ERROR_HANDLE_OPTIONS {Detect & Correct} \
        SEM_EVENT_LOG_OPTIONS {Log & Notify} \
        SEM_MEM_BUILT_IN_SELF_TEST {0} \
        SEM_MEM_ENABLE_ALL_TEST_FEATURE {0} \
        SEM_MEM_ENABLE_SCAN_AFTER {Immediate Start} \
        SEM_MEM_GOLDEN_ECC {0} \
        SEM_MEM_GOLDEN_ECC_SW {0} \
        SEM_MEM_SCAN {0} \
        SEM_NPI_BUILT_IN_SELF_TEST {0} \
        SEM_NPI_ENABLE_ALL_TEST_FEATURE {0} \
        SEM_NPI_ENABLE_SCAN_AFTER {Immediate Start} \
        SEM_NPI_GOLDEN_CHECKSUM_SW {0} \
        SEM_NPI_SCAN {0} \
        SEM_TIME_INTERVAL_BETWEEN_SCANS {80} \
        SMON_ALARMS {Set_Alarms_On} \
        SMON_ENABLE_INT_VOLTAGE_MONITORING {0} \
        SMON_ENABLE_TEMP_AVERAGING {0} \
        SMON_INTERFACE_TO_USE {None} \
        SMON_INT_MEASUREMENT_ALARM_ENABLE {0} \
        SMON_INT_MEASUREMENT_AVG_ENABLE {0} \
        SMON_INT_MEASUREMENT_ENABLE {0} \
        SMON_INT_MEASUREMENT_MODE {0} \
        SMON_INT_MEASUREMENT_TH_HIGH {0} \
        SMON_INT_MEASUREMENT_TH_LOW {0} \
        SMON_MEAS0 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_103} {SUPPLY_NUM 0}} \
        SMON_MEAS1 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_104} {SUPPLY_NUM 0}} \
        SMON_MEAS10 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_206} {SUPPLY_NUM 0}} \
        SMON_MEAS100 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS101 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS102 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS103 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS104 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS105 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS106 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS107 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS108 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS109 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS11 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_103} {SUPPLY_NUM 0}} \
        SMON_MEAS110 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS111 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS112 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS113 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS114 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS115 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS116 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS117 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS118 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS119 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS12 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_104} {SUPPLY_NUM 0}} \
        SMON_MEAS120 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS121 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS122 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS123 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS124 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS125 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS126 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS127 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS128 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS129 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS13 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_105} {SUPPLY_NUM 0}} \
        SMON_MEAS130 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS131 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS132 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS133 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS134 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS135 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS136 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS137 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS138 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS139 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS14 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_106} {SUPPLY_NUM 0}} \
        SMON_MEAS140 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS141 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS142 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS143 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS144 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS145 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS146 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS147 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS148 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS149 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS15 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_200} {SUPPLY_NUM 0}} \
        SMON_MEAS150 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS151 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS152 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS153 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS154 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS155 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS156 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS157 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS158 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS159 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS16 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_201} {SUPPLY_NUM 0}} \
        SMON_MEAS160 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
        SMON_MEAS161 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
        SMON_MEAS162 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCINT}} \
        SMON_MEAS163 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX}} \
        SMON_MEAS164 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_RAM}} \
        SMON_MEAS165 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_SOC}} \
        SMON_MEAS166 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSFP}} \
        SMON_MEAS167 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSLP}} \
        SMON_MEAS168 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX_PMC}} \
        SMON_MEAS169 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PMC}} \
        SMON_MEAS17 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_202} {SUPPLY_NUM 0}} \
        SMON_MEAS170 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
        SMON_MEAS171 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
        SMON_MEAS172 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
        SMON_MEAS173 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
        SMON_MEAS174 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
        SMON_MEAS175 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103}} \
        SMON_MEAS18 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_203} {SUPPLY_NUM 0}} \
        SMON_MEAS19 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_204} {SUPPLY_NUM 0}} \
        SMON_MEAS2 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_105} {SUPPLY_NUM 0}} \
        SMON_MEAS20 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_205} {SUPPLY_NUM 0}} \
        SMON_MEAS21 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCC_206} {SUPPLY_NUM 0}} \
        SMON_MEAS22 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_103} {SUPPLY_NUM 0}} \
        SMON_MEAS23 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_104} {SUPPLY_NUM 0}} \
        SMON_MEAS24 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_105} {SUPPLY_NUM 0}} \
        SMON_MEAS25 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_106} {SUPPLY_NUM 0}} \
        SMON_MEAS26 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_200} {SUPPLY_NUM 0}} \
        SMON_MEAS27 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_201} {SUPPLY_NUM 0}} \
        SMON_MEAS28 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_202} {SUPPLY_NUM 0}} \
        SMON_MEAS29 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_203} {SUPPLY_NUM 0}} \
        SMON_MEAS3 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_106} {SUPPLY_NUM 0}} \
        SMON_MEAS30 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_204} {SUPPLY_NUM 0}} \
        SMON_MEAS31 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_205} {SUPPLY_NUM 0}} \
        SMON_MEAS32 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVTT_206} {SUPPLY_NUM 0}} \
        SMON_MEAS33 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX} {SUPPLY_NUM 0}} \
        SMON_MEAS34 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX_PMC} {SUPPLY_NUM 0}} \
        SMON_MEAS35 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX_SMON} {SUPPLY_NUM 0}} \
        SMON_MEAS36 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCINT} {SUPPLY_NUM 0}} \
        SMON_MEAS37 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_306} {SUPPLY_NUM 0}} \
        SMON_MEAS38 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_406} {SUPPLY_NUM 0}} \
        SMON_MEAS39 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_500} {SUPPLY_NUM 0}} \
        SMON_MEAS4 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_200} {SUPPLY_NUM 0}} \
        SMON_MEAS40 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_501} {SUPPLY_NUM 0}} \
        SMON_MEAS41 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_502} {SUPPLY_NUM 0}} \
        SMON_MEAS42 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_503} {SUPPLY_NUM 0}} \
        SMON_MEAS43 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_700} {SUPPLY_NUM 0}} \
        SMON_MEAS44 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_701} {SUPPLY_NUM 0}} \
        SMON_MEAS45 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_702} {SUPPLY_NUM 0}} \
        SMON_MEAS46 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_703} {SUPPLY_NUM 0}} \
        SMON_MEAS47 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_704} {SUPPLY_NUM 0}} \
        SMON_MEAS48 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_705} {SUPPLY_NUM 0}} \
        SMON_MEAS49 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_706} {SUPPLY_NUM 0}} \
        SMON_MEAS5 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_201} {SUPPLY_NUM 0}} \
        SMON_MEAS50 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_707} {SUPPLY_NUM 0}} \
        SMON_MEAS51 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_708} {SUPPLY_NUM 0}} \
        SMON_MEAS52 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_709} {SUPPLY_NUM 0}} \
        SMON_MEAS53 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_710} {SUPPLY_NUM 0}} \
        SMON_MEAS54 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_711} {SUPPLY_NUM 0}} \
        SMON_MEAS55 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_BATT} {SUPPLY_NUM 0}} \
        SMON_MEAS56 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PMC} {SUPPLY_NUM 0}} \
        SMON_MEAS57 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSFP} {SUPPLY_NUM 0}} \
        SMON_MEAS58 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSLP} {SUPPLY_NUM 0}} \
        SMON_MEAS59 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_RAM} {SUPPLY_NUM 0}} \
        SMON_MEAS6 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_202} {SUPPLY_NUM 0}} \
        SMON_MEAS60 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_SOC} {SUPPLY_NUM 0}} \
        SMON_MEAS61 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VP_VN} {SUPPLY_NUM 0}} \
        SMON_MEAS62 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS63 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS64 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS65 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS66 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS67 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS68 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS69 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS7 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_203} {SUPPLY_NUM 0}} \
        SMON_MEAS70 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS71 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS72 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS73 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS74 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS75 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS76 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS77 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS78 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS79 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS8 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_204} {SUPPLY_NUM 0}} \
        SMON_MEAS80 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS81 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS82 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS83 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS84 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS85 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS86 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS87 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS88 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS89 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS9 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE {2 V unipolar}} {NAME GTY_AVCCAUX_205} {SUPPLY_NUM 0}} \
        SMON_MEAS90 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS91 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS92 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS93 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS94 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS95 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS96 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS97 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS98 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEAS99 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 0} {MODE None} {NAME GT_AVAUX_PKG_103} {SUPPLY_NUM 0}} \
        SMON_MEASUREMENT_COUNT {62} \
        SMON_MEASUREMENT_LIST {BANK_VOLTAGE:GTY_AVTT-GTY_AVTT_103,GTY_AVTT_104,GTY_AVTT_105,GTY_AVTT_106,GTY_AVTT_200,GTY_AVTT_201,GTY_AVTT_202,GTY_AVTT_203,GTY_AVTT_204,GTY_AVTT_205,GTY_AVTT_206#VCC-GTY_AVCC_103,GTY_AVCC_104,GTY_AVCC_105,GTY_AVCC_106,GTY_AVCC_200,GTY_AVCC_201,GTY_AVCC_202,GTY_AVCC_203,GTY_AVCC_204,GTY_AVCC_205,GTY_AVCC_206#VCCAUX-GTY_AVCCAUX_103,GTY_AVCCAUX_104,GTY_AVCCAUX_105,GTY_AVCCAUX_106,GTY_AVCCAUX_200,GTY_AVCCAUX_201,GTY_AVCCAUX_202,GTY_AVCCAUX_203,GTY_AVCCAUX_204,GTY_AVCCAUX_205,GTY_AVCCAUX_206#VCCO-VCCO_306,VCCO_406,VCCO_500,VCCO_501,VCCO_502,VCCO_503,VCCO_700,VCCO_701,VCCO_702,VCCO_703,VCCO_704,VCCO_705,VCCO_706,VCCO_707,VCCO_708,VCCO_709,VCCO_710,VCCO_711|DEDICATED_PAD:VP-VP_VN|SUPPLY_VOLTAGE:VCC-VCC_BATT,VCC_PMC,VCC_PSFP,VCC_PSLP,VCC_RAM,VCC_SOC#VCCAUX-VCCAUX,VCCAUX_PMC,VCCAUX_SMON#VCCINT-VCCINT}\
  \
        SMON_OT {{THRESHOLD_LOWER 70} {THRESHOLD_UPPER 125}} \
        SMON_PMBUS_ADDRESS {0x0} \
        SMON_PMBUS_UNRESTRICTED {0} \
        SMON_REFERENCE_SOURCE {Internal} \
        SMON_TEMP_AVERAGING_SAMPLES {0} \
        SMON_TEMP_THRESHOLD {0} \
        SMON_USER_TEMP {{THRESHOLD_LOWER 70} {THRESHOLD_UPPER 125} {USER_ALARM_TYPE hysteresis}} \
        SMON_VAUX_CH0 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH0} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH1 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH1} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH10 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH10} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH11 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH11} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH12 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH12} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH13 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH13} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH14 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH14} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH15 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH15} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH2 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH2} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH3 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH3} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH4 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH4} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH5 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH5} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH6 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH6} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH7 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH7} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH8 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH8} {SUPPLY_NUM 0}} \
        SMON_VAUX_CH9 {{ALARM_ENABLE 0} {ALARM_LOWER 0} {ALARM_UPPER 0} {AVERAGE_EN 0} {ENABLE 0} {IO_N PMC_MIO1_500} {IO_P PMC_MIO0_500} {MODE {1 V unipolar}} {NAME VAUX_CH9} {SUPPLY_NUM 0}} \
        SMON_VAUX_IO_BANK {MIO_BANK0} \
        SMON_VOLTAGE_AVERAGING_SAMPLES {None} \
        SPP_PSPMC_FROM_CORE_WIDTH {12000} \
        SPP_PSPMC_TO_CORE_WIDTH {12000} \
        SUBPRESET1 {Custom} \
        USE_UART0_IN_DEVICE_BOOT {0} \
        preset {None} \
      } \
      CONFIG.PS_PMC_CONFIG_APPLIED {1} \
    ] $versal_cips_0
    
  }

  # Create instance: axi_dbg_hub_0, and set properties
  set axi_dbg_hub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dbg_hub axi_dbg_hub_0 ]
  set_property CONFIG.C_NUM_DEBUG_CORES {2} $axi_dbg_hub_0

  # Create instance: axis_ila_0, and set properties
  set axis_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila axis_ila_0 ]
  set_property -dict [list \
    CONFIG.C_ADV_TRIGGER {true} \
    CONFIG.C_EN_AXIS_IF {1} \
    CONFIG.C_INPUT_PIPE_STAGES {1} \
    CONFIG.C_NUM_OF_PROBES {1} \
    CONFIG.C_PROBE0_WIDTH {16} \
    CONFIG.C_PROBE2_WIDTH {1} \
    CONFIG.C_TRIGIN_EN {false} \
  ] $axis_ila_0

  # Create instance: vio_inst, and set properties
  set vio_inst [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio vio_inst ]
  set_property -dict [list \
    CONFIG.C_EN_AXIS_IF {1} \
    CONFIG.C_NUM_PROBE_OUT {4} \
    CONFIG.C_PROBE_IN0_WIDTH {16} \
    CONFIG.C_PROBE_OUT3_WIDTH {16} \
    CONFIG.C_PROBE_OUT4_WIDTH {1} \
  ] $vio_inst

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]

  # Create instance: bram_inst, and set properties
  set bram_inst [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen bram_inst ]
  set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $bram_inst

  # Create instance: user_cntr, and set properties
  set user_cntr [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary user_cntr ]
  set_property -dict [list \
    CONFIG.CE {true} \
    CONFIG.Count_Mode {UPDOWN} \
    CONFIG.Load {true} \
  ] $user_cntr

  ########################################################
  # END: Create all instances and set their properties
  ########################################################
  
  ########################################################
  # START: Connect all instances and top level ports
  ########################################################
  connect_bd_intf_net -intf_net m_axil_if [get_bd_intf_ports M_AXIL] [get_bd_intf_pins smartconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net st_rx_msg_if [get_bd_intf_ports dma0_st_rx_msg] [get_bd_intf_pins versal_cips_0/dma0_st_rx_msg]
  if {[regexp "vpk120" $board_name]} { ;# CPM5
    connect_bd_intf_net -intf_net axis_c2h_dmawr_if [get_bd_intf_pins dma0_axis_c2h_dmawr] [get_bd_intf_pins versal_cips_0/dma0_axis_c2h_dmawr]
    connect_bd_intf_net -intf_net qsts_out_if [get_bd_intf_ports dma0_qsts_out] [get_bd_intf_pins versal_cips_0/dma0_qsts_out]
  }
  connect_bd_intf_net -intf_net m_axis_h2c_if [get_bd_intf_ports dma0_m_axis_h2c] [get_bd_intf_pins versal_cips_0/dma0_m_axis_h2c]
  connect_bd_intf_net -intf_net axis_c2h_status_if [get_bd_intf_ports dma0_axis_c2h_status] [get_bd_intf_pins versal_cips_0/dma0_axis_c2h_status]
  connect_bd_intf_net -intf_net tm_dsc_sts_if [get_bd_intf_ports dma0_tm_dsc_sts] [get_bd_intf_pins versal_cips_0/dma0_tm_dsc_sts]
  connect_bd_intf_net -intf_net s_axis_c2h_it [get_bd_intf_ports dma0_s_axis_c2h] [get_bd_intf_pins versal_cips_0/dma0_s_axis_c2h]
  connect_bd_intf_net -intf_net s_axis_c2h_cmpt_if [get_bd_intf_ports dma0_s_axis_c2h_cmpt] [get_bd_intf_pins versal_cips_0/dma0_s_axis_c2h_cmpt]
  connect_bd_intf_net -intf_net dsc_crdt_in_if [get_bd_intf_ports dma0_dsc_crdt_in] [get_bd_intf_pins versal_cips_0/dma0_dsc_crdt_in]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_noc_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_dbg_hub_0/S_AXI] [get_bd_intf_pins axi_noc_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M02_AXI [get_bd_intf_pins axi_noc_0/M02_AXI] [get_bd_intf_pins smartconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M03_AXI [get_bd_intf_pins axi_noc_0/M03_AXI] [get_bd_intf_pins versal_cips_0/NOC_PMC_AXI_0]
  connect_bd_intf_net -intf_net cpm_axi_noc_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_0]
  connect_bd_intf_net -intf_net cpm_axi_noc_1 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_1]
  connect_bd_intf_net -intf_net pcie_gts [get_bd_intf_ports pcie_gts] [get_bd_intf_pins versal_cips_0/PCIE0_GT]
  connect_bd_intf_net -intf_net pcie_refclk [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins versal_cips_0/gt_refclk0]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]

  connect_bd_net -net tie1 [get_bd_pins logic1/dout] [get_bd_pins proc_sys_reset_0/aux_reset_in] [get_bd_pins proc_sys_reset_0/dcm_locked] 
  connect_bd_net -net tie0 [get_bd_pins logic0/dout] [get_bd_pins proc_sys_reset_0/mb_debug_sys_rst] [get_bd_pins versal_cips_0/cpm_irq0] [get_bd_pins versal_cips_0/cpm_irq1] 
  connect_bd_net -net cpm_axi_noc_aclk0 [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi0_clk] 
  connect_bd_net -net cpm_axi_noc_aclk1 [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi1_clk] 
  connect_bd_net -net pl0_ref_clk [get_bd_pins pl0_ref_clk] [get_bd_pins axi_noc_0/aclk3] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins versal_cips_0/pl0_ref_clk] 
  if {[regexp "vpk120" $board_name]} { ;# CPM5
    connect_bd_net -net dma0_intrfc_resetn_0_1 [get_bd_pins dma0_intrfc_resetn] [get_bd_pins versal_cips_0/dma0_intrfc_resetn] 
    connect_bd_net -net pl_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn] 
    connect_bd_net [get_bd_pins pl0_ref_clk] [get_bd_pins smartconnect_1/aclk] [get_bd_pins versal_cips_0/dma0_intrfc_clk]
  } else { ;# CPM4
    connect_bd_net -net dma0_soft_resetn_0_1 [get_bd_pins dma0_soft_resetn] [get_bd_pins versal_cips_0/dma0_soft_resetn] 
    connect_bd_net -net pcie0_user_clk_0_1 [get_bd_pins pcie0_user_clk] [get_bd_pins versal_cips_0/pcie0_user_clk]
    create_bd_net pl_aresetn 
    connect_bd_net -net pl_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] 
    connect_bd_net [get_bd_pins logic0/dout] [get_bd_pins versal_cips_0/dma0_usr_irq_valid]
    connect_bd_net [get_bd_pins axi_noc_0/aclk5] [get_bd_pins versal_cips_0/pcie0_user_clk] 
    connect_bd_net [get_bd_pins smartconnect_1/aclk] [get_bd_pins versal_cips_0/pcie0_user_clk] 
  }
  connect_bd_net -net pl_resetn [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins versal_cips_0/pl0_resetn] 
  connect_bd_net -net versal_cips_0_dma0_axi_aresetn [get_bd_pins dma0_axi_aresetn] [get_bd_pins smartconnect_1/aresetn] [get_bd_pins versal_cips_0/dma0_axi_aresetn] 
  connect_bd_net -net versal_cips_0_noc_pmc_axi_axi0_clk [get_bd_pins axi_noc_0/aclk4] [get_bd_pins versal_cips_0/noc_pmc_axi_axi0_clk] 
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk2] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk] 

  connect_bd_intf_net -intf_net hub_axis_ila [get_bd_intf_pins axi_dbg_hub_0/M00_AXIS] [get_bd_intf_pins axis_ila_0/S_AXIS]
  connect_bd_intf_net -intf_net hub_axis_vio [get_bd_intf_pins axi_dbg_hub_0/M01_AXIS] [get_bd_intf_pins vio_inst/S_AXIS]
  connect_bd_intf_net -intf_net ila_axis_hub [get_bd_intf_pins axi_dbg_hub_0/S00_AXIS] [get_bd_intf_pins axis_ila_0/M_AXIS]
  connect_bd_intf_net -intf_net vio_axis_hub [get_bd_intf_pins axi_dbg_hub_0/S01_AXIS] [get_bd_intf_pins vio_inst/M_AXIS]

  connect_bd_net -net pl0_ref_clk [get_bd_pins user_cntr/CLK] [get_bd_nets pl0_ref_clk]
  connect_bd_net -net cnt_ce [get_bd_pins user_cntr/CE] [get_bd_pins vio_inst/probe_out0]
  connect_bd_net -net cnt_up [get_bd_pins user_cntr/UP] [get_bd_pins vio_inst/probe_out1]
  connect_bd_net -net cnt_load [get_bd_pins user_cntr/LOAD] [get_bd_pins vio_inst/probe_out2]
  connect_bd_net -net cnt_in [get_bd_pins user_cntr/L] [get_bd_pins vio_inst/probe_out3]
  connect_bd_net -net cnt_out [get_bd_pins user_cntr/Q] [get_bd_pins axis_ila_0/probe0] [get_bd_pins vio_inst/probe_in0]
  connect_bd_net -net pl0_ref_clk [get_bd_nets pl0_ref_clk] [get_bd_pins axi_dbg_hub_0/aclk] [get_bd_pins axis_ila_0/aclk] [get_bd_pins axis_ila_0/clk] [get_bd_pins vio_inst/aclk] [get_bd_pins vio_inst/clk]
  connect_bd_net -net pl_aresetn [get_bd_nets pl_aresetn] [get_bd_pins axi_dbg_hub_0/aresetn] [get_bd_pins axis_ila_0/aresetn] [get_bd_pins vio_inst/aresetn]

  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins bram_inst/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins bram_inst/BRAM_PORTB]

  connect_bd_net -net pl0_ref_clk [get_bd_nets pl0_ref_clk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
  connect_bd_net -net pl_aresetn [get_bd_nets pl_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
  

  
  ########################################################
  # END: Connect all instances and top level ports
  ########################################################

  # Group cells together into subsystems
  group_bd_cells cips_noc_subsystem [get_bd_cells logic0] [get_bd_cells versal_cips_0] [get_bd_cells logic1] [get_bd_cells axi_noc_0] [get_bd_cells proc_sys_reset_0] [get_bd_cells smartconnect_1]
  group_bd_cells pl_bram_inst [get_bd_cells axi_bram_ctrl_0] [get_bd_cells bram_inst]
  group_bd_cells debug_inst [get_bd_cells axi_dbg_hub_0] [get_bd_cells vio_inst] [get_bd_cells axis_ila_0]

  ########################################################
  # START: Create address segments
  ########################################################

  # Create address segments
  assign_bd_address -offset 0x020180000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs M_AXIL/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs pl_bram_inst/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x000101220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot] -force
  assign_bd_address -offset 0x000102100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot_stream] -force
  assign_bd_address -offset 0x020180000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs M_AXIL/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs pl_bram_inst/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x000101220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot] -force
  assign_bd_address -offset 0x000102100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot_stream] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs pl_bram_inst/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020240000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs debug_inst/axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x020240000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs debug_inst/axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0]
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0x000100800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0x000100B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0x000100B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0x000100980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0xFC000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_cpm]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00140000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00300000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0x000101260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00100000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00040000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ram_0]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0x0001011E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0x0001011F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0x0001012D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0x0001012B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0x0001011C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0x0001011D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0x000101250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0x000101240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0x000101110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0x000100280000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_iomodule_0]
  exclude_bd_addr_seg -offset 0x000100310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0x000101030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0x000102000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram]
  exclude_bd_addr_seg -offset 0x000100240000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_data_cntlr]
  exclude_bd_addr_seg -offset 0x000100200000 -range 0x00040000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_instr_cntlr]
  exclude_bd_addr_seg -offset 0x000106000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0x000101200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0x0001012A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0x000101210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0x000101270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0x000100083000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_inject_0]
  exclude_bd_addr_seg -offset 0x000100283000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_manager_0]
  exclude_bd_addr_seg -offset 0x000101230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0x0001012F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0x000101310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0x000101300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_qspi_ospi_flash_0] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_apu_fun] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_apu_etf] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_apu_ela] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_apu_cti] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a720_dbg] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a720_cti] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a720_pmu] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a720_etm] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a721_dbg] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a721_cti] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a721_pmu] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a721_etm] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_rom] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_fun] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_ela2a] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_ela2b] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_ela2c] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_ela2d] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_atm] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_cti2a] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_cti2d] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_0]

  exclude_bd_addr_seg -offset 0x020240000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs debug_inst/axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0]
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0x000100800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0x000100B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0x000100B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0x000100980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0xFC000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_cpm]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00140000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00300000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0x000101260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00100000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00040000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ram_0]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0x0001011E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0x0001011F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0x0001012D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0x0001012B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0x0001011C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0x0001011D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0x000101250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0x000101240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0x000101110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0x000100280000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_iomodule_0]
  exclude_bd_addr_seg -offset 0x000100310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0x000101030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0x000102000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram]
  exclude_bd_addr_seg -offset 0x000100240000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_data_cntlr]
  exclude_bd_addr_seg -offset 0x000100200000 -range 0x00040000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_instr_cntlr]
  exclude_bd_addr_seg -offset 0x000106000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0x000101200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0x0001012A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0x000101210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0x000101270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0x000100083000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_inject_0]
  exclude_bd_addr_seg -offset 0x000100283000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_manager_0]
  exclude_bd_addr_seg -offset 0x000101230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0x0001012F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0x000101310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0x000101300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_qspi_ospi_flash_0] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_apu_fun] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_apu_etf] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_apu_ela] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_apu_cti] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a720_dbg] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a720_cti] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a720_pmu] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a720_etm] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a721_dbg] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a721_cti] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a721_pmu] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_a721_etm] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_rom] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_fun] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_ela2a] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_ela2b] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_ela2c] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_ela2d] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_atm] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_cti2a] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]
  exclude_bd_addr_seg [get_bd_addr_segs cips_noc_subsystem/versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_cpm_cti2d] -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/CPM_PCIE_NOC_1]

  exclude_bd_addr_seg -offset 0x020180000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cips_noc_subsystem/versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs M_AXIL/Reg]


  ########################################################
  # END: Create address segments
  ########################################################

	set proj_dir [get_property DIRECTORY [current_project ]]
	set proj_name [get_property NAME [current_project ]]
	file mkdir $proj_dir/$proj_name.srcs/constrs_1/constrs
	set fd [ open $proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc w ]
	puts $fd "# Set bitstream properties"
  puts $fd "set_property CONFIG_VOLTAGE 1.8 \[current_design\]"
	close $fd
	add_files -fileset constrs_1 [ list "$proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc" ]

  puts "INFO: End of create_root_design"
}
##################################################################
# MAIN FLOW
##################################################################

create_root_design "" $design_name $options 

if {[regexp "vpk120" [get_property BOARD_NAME [current_board]]]} { 
  import_files $currentDir/src/cpm5/
  set cpmN cpm5
} else {
  import_files $currentDir/src/cpm4/
  set cpmN cpm4
}
 
# The top RTL file has a string "<?BD_NAME>" in it that needs to be changed to what was used when
# create_bd_design "<var>" was called. In the GUI, this defaults to the project name, but the 
# Jenkins build hardcodes to "design_1".  So, we're doing a basic find and replace to handle this. 
set bdname [get_property NAME [current_bd_design]]
set topRtlFile [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports $cpmN Versal_CPM_Tandem_PCIe_top.sv]
# Read in whole file
set infile [open $topRtlFile]
set contents [read $infile]
close $infile
# Perform find and replace
set contents [string map [list "<?BD_NAME>" $bdname] $contents]
# Write to new file
set outfile [open $topRtlFile.tmp w]
puts -nonewline $outfile $contents
close $outfile
# Overwrite
file rename -force $topRtlFile.tmp $topRtlFile

open_bd_design [current_bd_design]
regenerate_bd_layout
validate_bd_design
save_bd_design

set_property top Versal_CPM_Tandem_PCIe_top [current_fileset]
import_files -fileset utils_1 -flat $currentDir/README.txt
import_files -fileset utils_1 -flat $currentDir/scripts.tar
puts "INFO: Design generation complete"
puts "INFO: Refer to the README.txt file inside the util_1 fileset for information"
}
