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
   CONFIG.CONNECTIONS {M03_AXI { read_bw {1000} write_bw {1000} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1000} write_bw {1000} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1000} write_bw {1000}}} \
   CONFIG.DEST_IDS {M03_AXI:0x140:M01_AXI:0x40:M02_AXI:0x0:M00_AXI:0x80} \
   CONFIG.REMAPS { M00_AXI {{0x0 0x201_C000_0000 64K}}} \
   CONFIG.CATEGORY {ps_pcie} \
  ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.R_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.W_TRAFFIC_CLASS {BEST_EFFORT} \
   CONFIG.CONNECTIONS {M03_AXI { read_bw {1000} write_bw {1000} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1000} write_bw {1000} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1000} write_bw {1000} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M03_AXI:0x140:M01_AXI:0x40:M02_AXI:0x0:M00_AXI:0x80} \
   CONFIG.REMAPS { M00_AXI {{0x0 0x201_C000_0000 64K}}} \
   CONFIG.CATEGORY {ps_pcie} \
  ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI { read_bw {1500} write_bw {1500} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1000} write_bw {1000} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x40:M02_AXI:0x0:M00_AXI:0x80} \
   CONFIG.REMAPS { M00_AXI {{0x0 0x201_C000_0000 64K}}} \
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
  set logic0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant logic0 ]
  set_property CONFIG.CONST_VAL {0} $logic0

  # Create instance: logic1, and set properties
  set logic1 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant logic1 ]

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
          CPM_PCIE0_DMA_INTF {AXI_MM_and_AXI_Stream} \
          CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s} \
          CPM_PCIE0_MODES {DMA} \
          CPM_PCIE0_MODE_SELECTION {Advanced} \
          CPM_PCIE0_PF0_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF0_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF0_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF0_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {1} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_TANDEM {Tandem_PCIe} \
        } \
        CONFIG.PS_PMC_CONFIG { \
          BOOT_MODE {Custom} \
          CLOCK_MODE {Custom} \
          DESIGN_MODE {1} \
          PCIE_APERTURES_DUAL_ENABLE {0} \
          PCIE_APERTURES_SINGLE_ENABLE {1} \
          PMC_CRP_PL0_REF_CTRL_FREQMHZ {200} \
          PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
          PMC_QSPI_PERIPHERAL_ENABLE {1} \
          PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
          PMC_USE_NOC_PMC_AXI0 {1} \
          PMC_USE_PMC_NOC_AXI0 {1} \
          PS_BOARD_INTERFACE {Custom} \
          PS_NUM_FABRIC_RESETS {1} \
          PS_PCIE1_PERIPHERAL_ENABLE {1} \
          PS_PCIE2_PERIPHERAL_ENABLE {0} \
          PS_PCIE_EP_RESET1_IO {PS_MIO 18} \
          PS_PCIE_RESET {{ENABLE 1}} \
          PS_USE_PMCPL_CLK0 {1} \
          SMON_ALARMS {Set_Alarms_On} \
          SMON_ENABLE_TEMP_AVERAGING {0} \
          SMON_TEMP_AVERAGING_SAMPLES {0} \
        } \
      ] $versal_cips_0
  
    } else { ;# VPK120 RevA
  
     set_property -dict [list \
        CONFIG.BOOT_MODE {Custom} \
        CONFIG.CLOCK_MODE {Custom} \
        CONFIG.CPM_CONFIG { \
          CPM_PCIE0_DMA_INTF {AXI_MM_and_AXI_Stream} \
          CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s} \
          CPM_PCIE0_MODES {DMA} \
          CPM_PCIE0_MODE_SELECTION {Advanced} \
          CPM_PCIE0_PF0_BAR0_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR0_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR0_QDMA_TYPE {DMA} \
          CPM_PCIE0_PF0_BAR1_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR2_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR2_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR2_QDMA_SIZE {64} \
          CPM_PCIE0_PF0_BAR3_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR4_QDMA_64BIT {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_BAR4_QDMA_ENABLED {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_PREFETCHABLE {1} \
          CPM_PCIE0_PF0_BAR4_QDMA_SIZE {64} \
          CPM_PCIE0_PF0_BAR5_QDMA_AXCACHE {0} \
          CPM_PCIE0_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {1} \
          CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x020180000000} \
          CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
          CPM_PCIE0_TANDEM {Tandem_PCIe} \
        } \
        CONFIG.PS_PMC_CONFIG { \
          BOOT_MODE {Custom} \
          CLOCK_MODE {Custom} \
          DESIGN_MODE {1} \
          PCIE_APERTURES_DUAL_ENABLE {0} \
          PCIE_APERTURES_SINGLE_ENABLE {1} \
          PMC_CRP_PL0_REF_CTRL_FREQMHZ {200} \
          PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
          PMC_QSPI_PERIPHERAL_ENABLE {1} \
          PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
          PMC_USE_NOC_PMC_AXI0 {1} \
          PMC_USE_PMC_NOC_AXI0 {1} \
          PS_BOARD_INTERFACE {Custom} \
          PS_NUM_FABRIC_RESETS {1} \
          PS_PCIE1_PERIPHERAL_ENABLE {1} \
          PS_PCIE2_PERIPHERAL_ENABLE {0} \
          PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
          PS_PCIE_RESET {{ENABLE 1}} \
          PS_USE_PMCPL_CLK0 {1} \
          SMON_ALARMS {Set_Alarms_On} \
          SMON_ENABLE_TEMP_AVERAGING {0} \
          SMON_TEMP_AVERAGING_SAMPLES {0} \
        } \
      ] $versal_cips_0
  
    }
  } else { ;# VCK190 

    set_property -dict [list \
      CONFIG.BOOT_MODE {Custom} \
      CONFIG.CLOCK_MODE {Custom} \
      CONFIG.CPM_CONFIG { \
        CPM_PCIE0_DMA_INTF {AXI_MM_and_AXI_Stream} \
        CPM_PCIE0_FUNCTIONAL_MODE {QDMA} \
        CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s} \
        CPM_PCIE0_MODES {DMA} \
        CPM_PCIE0_MODE_SELECTION {Advanced} \
        CPM_PCIE0_MSI_X_OPTIONS {MSI-X_Internal} \
        CPM_PCIE0_PF0_BAR0_QDMA_64BIT {1} \
        CPM_PCIE0_PF0_BAR0_QDMA_PREFETCHABLE {1} \
        CPM_PCIE0_PF0_BAR0_QDMA_TYPE {DMA} \
        CPM_PCIE0_PF0_BAR2_QDMA_64BIT {1} \
        CPM_PCIE0_PF0_BAR2_QDMA_ENABLED {1} \
        CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE {1} \
        CPM_PCIE0_PF0_BAR2_QDMA_SIZE {64} \
        CPM_PCIE0_PF0_BAR4_QDMA_ENABLED {1} \
        CPM_PCIE0_PF0_BAR4_QDMA_SIZE {64} \
        CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x20180000000} \
        CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {1} \
        CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
        CPM_PCIE0_TANDEM {Tandem_PCIe} \
        PS_USE_NOC_PS_PCI_0 {1} \
      } \
      CONFIG.PS_PMC_CONFIG { \
        BOOT_MODE {Custom} \
        CLOCK_MODE {Custom} \
        DESIGN_MODE {1} \
        PCIE_APERTURES_DUAL_ENABLE {0} \
        PCIE_APERTURES_SINGLE_ENABLE {1} \
        PMC_CRP_PL0_REF_CTRL_FREQMHZ {200} \
        PMC_QSPI_PERIPHERAL_ENABLE {1} \
        PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
        PMC_USE_NOC_PMC_AXI0 {1} \
        PMC_USE_PMC_NOC_AXI0 {1} \
        PS_BOARD_INTERFACE {Custom} \
        PS_NUM_FABRIC_RESETS {1} \
        PS_PCIE1_PERIPHERAL_ENABLE {1} \
        PS_PCIE2_PERIPHERAL_ENABLE {0} \
        PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
        PS_PCIE_RESET {{ENABLE 1}} \
        PS_USE_PMCPL_CLK0 {1} \
        SMON_ALARMS {Set_Alarms_On} \
        SMON_ENABLE_TEMP_AVERAGING {0} \
        SMON_TEMP_AVERAGING_SAMPLES {0} \
      } \
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

  # Create instance: cntr16, and set properties
  set cntr16 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary cntr16 ]
  set_property -dict [list \
    CONFIG.CE {true} \
    CONFIG.Count_Mode {UPDOWN} \
    CONFIG.Load {true} \
  ] $cntr16

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

  connect_bd_net -net pl0_ref_clk [get_bd_pins cntr16/CLK] [get_bd_nets pl0_ref_clk]
  connect_bd_net -net cnt_ce [get_bd_pins cntr16/CE] [get_bd_pins vio_inst/probe_out0]
  connect_bd_net -net cnt_up [get_bd_pins cntr16/UP] [get_bd_pins vio_inst/probe_out1]
  connect_bd_net -net cnt_load [get_bd_pins cntr16/LOAD] [get_bd_pins vio_inst/probe_out2]
  connect_bd_net -net cnt_in [get_bd_pins cntr16/L] [get_bd_pins vio_inst/probe_out3]
  connect_bd_net -net cnt_out [get_bd_pins cntr16/Q] [get_bd_pins axis_ila_0/probe0] [get_bd_pins vio_inst/probe_in0]
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

# Some files have a string "<?BD_NAME>" in it that needs to be changed to what was used when
# create_bd_design "<var>" was called. In the GUI, this defaults to the project name, but the 
# Jenkins build hardcodes to "design_1".  So, we're doing a basic find and replace to handle this. 
proc replace_bd_name {fin} {
  set bdname [get_property NAME [current_bd_design]]
  # Read in whole file
  set infile [open $fin]
  set contents [read $infile]
  close $infile
  # Perform find and replace
  set contents [string map [list "<?BD_NAME>" $bdname] $contents]
  # Write to new file
  set outfile [open $fin.tmp w]
  puts -nonewline $outfile $contents
  close $outfile
  # Overwrite
  file rename -force $fin.tmp $fin
}
 
# Some files have a string "<?BD_NAME>" in it that needs to be changed to what was used when
# create_bd_design "<var>" was called. In the GUI, this defaults to the project name, but the 
# Jenkins build hardcodes to "design_1".  So, we're doing a basic find and replace to handle this. 
set bdname [get_property NAME [current_bd_design]]
set topRtlFile [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports $cpmN Versal_CPM_Tandem_PCIe_top.sv]
replace_bd_name $topRtlFile

open_bd_design [current_bd_design]
regenerate_bd_layout
validate_bd_design
save_bd_design

set_property top Versal_CPM_Tandem_PCIe_top [current_fileset]
import_files -fileset utils_1 -flat $currentDir/README.txt
import_files -fileset utils_1 -flat $currentDir/scripts.tar

# DFX enablement
if {[dict size $options] && [dict get $options dfx.VALUE]} {
  puts "INFO: DFX enabled for this design"
  # Make this DFX and add pblock constraint
  source -notrace "$currentDir/src/dfx_ipi/bd/rpcntr_make_dfx.tcl"
  import_files -fileset constrs_1 $currentDir/src/dfx_ipi/bd/rpcntr_pblock.xdc
  set pblockxdc [file join [get_property directory [current_project]] [current_project].srcs constrs_1 imports bd rpcntr_pblock.xdc]
  replace_bd_name $pblockxdc
  # Make this DFX and add pblock constraint
  import_files [glob $currentDir/src/dfx_ipi/rtl/*v]
  source -notrace "$currentDir/src/dfx_ipi/rtl/rpwrdata_make_dfx.tcl"
  import_files -fileset constrs_1 $currentDir/src/dfx_ipi/rtl/rpwrdata_pblock.xdc
  set pblockxdc [file join [get_property directory [current_project]] [current_project].srcs constrs_1 imports rtl rpwrdata_pblock.xdc]
  replace_bd_name $pblockxdc
  # Import the TCL file to create PR configuration runs, needs to be sourced 
  # after synthesis or user can use the DFX Wizard
  import_files -fileset utils_1 $currentDir/src/dfx_ipi/make_cfg_runs.tcl
}

# Completion printing
puts "// ---------------------------------------------------------------------------- //"
puts "INFO: Design generation complete"
puts "INFO: Refer to the README.txt file inside the util_1 fileset for information"
if {[dict size $options] && [dict get $options dfx.VALUE]} {
  puts "INFO: After synthesis, source make_cfg_runs.tcl of utils_1 OR use the Dynamic Function eXchange Wizard"
}
puts "// ---------------------------------------------------------------------------- //"
}
