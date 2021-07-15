proc createDesign {design_name options} {   

variable currentDir
set_property target_language Verilog [current_project]
set_property "simulator_language" "Mixed" [current_project]

# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen lmb_bram ]
  set_property -dict [ list \
   CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
   CONFIG.READ_LATENCY_A {1} \
   CONFIG.READ_LATENCY_B {1} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

proc create_root_design { currentDir parentCell design_name } {
	if { $parentCell eq "" } {
		set parentCell [get_bd_cells /]
	}

  # Get object for parentCell
	set parentObj [get_bd_cells $parentCell]
	if { $parentObj == "" } {
		puts "ERROR: Unable to find parent cell <$parentCell>!"
		return
	}

  # Make sure parentObj is hier blk
	set parentType [get_property TYPE $parentObj]
	if { $parentType ne "hier" } {
		puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
		return
	}

  # Save current instance; Restore later
	set oldCurInst [current_bd_instance .]

  # Set parent object as current
	current_bd_instance $parentObj

 # Create interface ports
  set ddr4_dimm1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_dimm1 ]

  set ddr4_dimm1_sma_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ddr4_dimm1_sma_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $ddr4_dimm1_sma_clk


  # Create ports
  set pl0_ref_clk [ create_bd_port -dir O -type clk pl0_ref_clk ]
  set pl_gen_reset [ create_bd_port -dir O pl_gen_reset ]

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0 ]

  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen axi_bram_ctrl_0_bram ]
  set_property -dict [ list \
   CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_0_bram

  # Create instance: axi_cdma_0, and set properties
  set axi_cdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma axi_cdma_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_WIDTH {64} \
   CONFIG.C_INCLUDE_SG {0} \
   CONFIG.C_M_AXI_DATA_WIDTH {128} \
   CONFIG.C_M_AXI_MAX_BURST_LEN {4} \
 ] $axi_cdma_0

  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc axi_noc_0 ]
  set_property -dict [ list \
   CONFIG.CH0_DDR4_0_BOARD_INTERFACE {ddr4_dimm1} \
   CONFIG.CONTROLLERTYPE {DDR4_SDRAM} \
   CONFIG.LOGO_FILE {data/noc_mc.png} \
   CONFIG.MC0_CONFIG_NUM {config17} \
   CONFIG.MC1_CONFIG_NUM {config17} \
   CONFIG.MC2_CONFIG_NUM {config17} \
   CONFIG.MC3_CONFIG_NUM {config17} \
   CONFIG.MC_ADDR_BIT7 {BG1} \
   CONFIG.MC_ADDR_BIT8 {BA0} \
   CONFIG.MC_ADDR_BIT9 {BA1} \
   CONFIG.MC_ADDR_BIT10 {CA3} \
   CONFIG.MC_ADDR_BIT11 {CA4} \
   CONFIG.MC_ADDR_BIT12 {CA5} \
   CONFIG.MC_ADDR_BIT13 {CA6} \
   CONFIG.MC_ADDR_BIT14 {CA7} \
   CONFIG.MC_ADDR_BIT15 {CA8} \
   CONFIG.MC_ADDR_BIT16 {CA9} \
   CONFIG.MC_BOARD_INTRF_EN {true} \
   CONFIG.MC_CASLATENCY {22} \
   CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
   CONFIG.MC_COMPONENT_WIDTH {x8} \
   CONFIG.MC_CONFIG_NUM {config17} \
   CONFIG.MC_DATAWIDTH {64} \
   CONFIG.MC_DDR4_2T {Disable} \
   CONFIG.MC_EN_INTR_RESP {TRUE} \
   CONFIG.MC_F1_TRCD {13750} \
   CONFIG.MC_F1_TRCDMIN {13750} \
   CONFIG.MC_INPUTCLK0_PERIOD {5000} \
   CONFIG.MC_INPUT_FREQUENCY0 {200.000} \
   CONFIG.MC_INTERLEAVE_SIZE {128} \
   CONFIG.MC_MEMORY_DEVICETYPE {UDIMMs} \
   CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
   CONFIG.MC_NO_CHANNELS {Single} \
   CONFIG.MC_PRE_DEF_ADDR_MAP_SEL {ROW_COLUMN_BANK} \
   CONFIG.MC_RANK {1} \
   CONFIG.MC_ROWADDRESSWIDTH {16} \
   CONFIG.MC_STACKHEIGHT {1} \
   CONFIG.MC_SYSTEM_CLOCK {Differential} \
   CONFIG.MC_TRC {45750} \
   CONFIG.MC_TRCD {13750} \
   CONFIG.MC_TRCDMIN {13750} \
   CONFIG.MC_TRCMIN {45750} \
   CONFIG.MC_TRP {13750} \
   CONFIG.MC_TRPMIN {13750} \
   CONFIG.NUM_CLKS {7} \
   CONFIG.NUM_MC {1} \
   CONFIG.NUM_MCP {4} \
   CONFIG.NUM_MI {0} \
   CONFIG.NUM_SI {7} \
   CONFIG.sys_clk0_BOARD_INTERFACE {ddr4_dimm1_sma_clk} \
 ] $axi_noc_0

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_1 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_3 { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
 ] $axi_smc

  # Create instance: axi_smc_1, and set properties
  set axi_smc_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc_1 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $axi_smc_1

  # Create instance: axi_smc_2, and set properties
  set axi_smc_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc_2 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $axi_smc_2

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm mdm_1 ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_I_LMB {1} \
 ] $microblaze_0

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: rst_versal_cips_0_333M, and set properties
  set rst_versal_cips_0_333M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_versal_cips_0_333M ]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.CPM_DMA_CREDIT_INIT_DEMUX {0} \
   CONFIG.CPM_PCIE0_AXISTEN_IF_WIDTH {64} \
   CONFIG.CPM_PCIE0_LANE_REVERSAL_EN {0} \
   CONFIG.CPM_PCIE0_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {0} \
   CONFIG.CPM_PCIE0_USER_CLK_FREQ {125_MHz} \
   CONFIG.CPM_PCIE1_AXISTEN_IF_WIDTH {64} \
   CONFIG.CPM_PCIE1_LANE_REVERSAL_EN {0} \
   CONFIG.CPM_PCIE1_PF0_CLASS_CODE {0} \
   CONFIG.CPM_PCIE1_PF0_USE_CLASS_CODE_LOOKUP_ASSISTANT {0} \
   CONFIG.CPM_PCIE1_USER_CLK_FREQ {125_MHz} \
   CONFIG.PMC_CRP_I2C_REF_CTRL_ACT_FREQMHZ {99.999001} \
   CONFIG.PMC_CRP_PL0_REF_CTRL_ACT_FREQMHZ {333.329987} \
   CONFIG.PMC_CRP_QSPI_REF_CTRL_ACT_FREQMHZ {299.997009} \
   CONFIG.PMC_CRP_SDIO1_REF_CTRL_ACT_FREQMHZ {199.998001} \
   CONFIG.PMC_CRP_SD_DLL_REF_CTRL_ACT_FREQMHZ {1199.988037} \
   CONFIG.PMC_GPIO0_MIO_PERIPHERAL_ENABLE {1} \
   CONFIG.PMC_GPIO1_MIO_PERIPHERAL_ENABLE {1} \
   CONFIG.PMC_I2CPMC_PERIPHERAL_ENABLE {1} \
   CONFIG.PMC_I2CPMC_PERIPHERAL_IO {PMC_MIO 46 .. 47} \
   CONFIG.PMC_MIO_0_DIRECTION {out} \
   CONFIG.PMC_MIO_0_SCHMITT {1} \
   CONFIG.PMC_MIO_10_DIRECTION {inout} \
   CONFIG.PMC_MIO_11_DIRECTION {inout} \
   CONFIG.PMC_MIO_12_DIRECTION {out} \
   CONFIG.PMC_MIO_12_SCHMITT {1} \
   CONFIG.PMC_MIO_13_DIRECTION {out} \
   CONFIG.PMC_MIO_13_SCHMITT {1} \
   CONFIG.PMC_MIO_14_DIRECTION {inout} \
   CONFIG.PMC_MIO_15_DIRECTION {inout} \
   CONFIG.PMC_MIO_16_DIRECTION {inout} \
   CONFIG.PMC_MIO_17_DIRECTION {inout} \
   CONFIG.PMC_MIO_19_DIRECTION {inout} \
   CONFIG.PMC_MIO_1_DIRECTION {inout} \
   CONFIG.PMC_MIO_20_DIRECTION {inout} \
   CONFIG.PMC_MIO_21_DIRECTION {inout} \
   CONFIG.PMC_MIO_22_DIRECTION {inout} \
   CONFIG.PMC_MIO_24_DIRECTION {out} \
   CONFIG.PMC_MIO_24_SCHMITT {1} \
   CONFIG.PMC_MIO_26_DIRECTION {inout} \
   CONFIG.PMC_MIO_27_DIRECTION {inout} \
   CONFIG.PMC_MIO_29_DIRECTION {inout} \
   CONFIG.PMC_MIO_2_DIRECTION {inout} \
   CONFIG.PMC_MIO_30_DIRECTION {inout} \
   CONFIG.PMC_MIO_31_DIRECTION {inout} \
   CONFIG.PMC_MIO_32_DIRECTION {inout} \
   CONFIG.PMC_MIO_33_DIRECTION {inout} \
   CONFIG.PMC_MIO_34_DIRECTION {inout} \
   CONFIG.PMC_MIO_35_DIRECTION {inout} \
   CONFIG.PMC_MIO_36_DIRECTION {inout} \
   CONFIG.PMC_MIO_37_DIRECTION {out} \
   CONFIG.PMC_MIO_37_OUTPUT_DATA {high} \
   CONFIG.PMC_MIO_37_USAGE {GPIO} \
   CONFIG.PMC_MIO_3_DIRECTION {inout} \
   CONFIG.PMC_MIO_40_DIRECTION {out} \
   CONFIG.PMC_MIO_40_SCHMITT {1} \
   CONFIG.PMC_MIO_43_DIRECTION {out} \
   CONFIG.PMC_MIO_43_SCHMITT {1} \
   CONFIG.PMC_MIO_44_DIRECTION {inout} \
   CONFIG.PMC_MIO_45_DIRECTION {inout} \
   CONFIG.PMC_MIO_46_DIRECTION {inout} \
   CONFIG.PMC_MIO_47_DIRECTION {inout} \
   CONFIG.PMC_MIO_4_DIRECTION {inout} \
   CONFIG.PMC_MIO_5_DIRECTION {out} \
   CONFIG.PMC_MIO_5_SCHMITT {1} \
   CONFIG.PMC_MIO_6_DIRECTION {out} \
   CONFIG.PMC_MIO_6_SCHMITT {1} \
   CONFIG.PMC_MIO_7_DIRECTION {out} \
   CONFIG.PMC_MIO_7_SCHMITT {1} \
   CONFIG.PMC_MIO_8_DIRECTION {inout} \
   CONFIG.PMC_MIO_9_DIRECTION {inout} \
   CONFIG.PMC_MIO_TREE_PERIPHERALS { \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#SD1/eMMC1#SD1/eMMC1#SD1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#SD1/eMMC1#GPIO 1###CAN \
     0#UART 0#I2C \
     0#USB 0#USB \
     0#USB 0#USB \
     0#USB 0#USB \
     0#USB 0#USB \
     0#USB 0#USB \
     0#USB 0#USB \
     1#CAN 1#UART \
     1#Enet 1#Enet \
     1#Enet 1#Enet \
     1#Enet 1#Enet \
     1#Enet 1#Enet \
     1#Enet 1#Enet \
     1#Enet 1#Enet \
     1#I2C 1#i2c_pmc#i2c_pmc#####Enet \
     QSPI#QSPI#QSPI#QSPI#QSPI#QSPI#Loopback Clk#QSPI#QSPI#QSPI#QSPI#QSPI#QSPI#USB \
   } \
   CONFIG.PMC_MIO_TREE_SIGNALS {qspi0_clk#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]#qspi0_io[0]#qspi0_cs_b#qspi_lpbk#qspi1_cs_b#qspi1_io[0]#qspi1_io[1]#qspi1_io[2]#qspi1_io[3]#qspi1_clk#usb2phy_reset#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_tx_data[2]#ulpi_tx_data[3]#ulpi_clk#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#ulpi_dir#ulpi_stp#ulpi_nxt#clk#dir1/data[7]#detect#cmd#data[0]#data[1]#data[2]#data[3]#sel/data[4]#dir_cmd/data[5]#dir0/data[6]#gpio_1_pin[37]###phy_tx#phy_rx#rxd#txd#scl#sda#scl#sda#####rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#gem0_mdc#gem0_mdio} \
   CONFIG.PMC_OSPI_PERIPHERAL_ENABLE {0} \
   CONFIG.PMC_QSPI_GRP_FBCLK_ENABLE {1} \
   CONFIG.PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
   CONFIG.PMC_QSPI_PERIPHERAL_ENABLE {1} \
   CONFIG.PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
   CONFIG.PMC_SD1_DATA_TRANSFER_MODE {8Bit} \
   CONFIG.PMC_SD1_GRP_CD_ENABLE {1} \
   CONFIG.PMC_SD1_GRP_CD_IO {PMC_MIO 28} \
   CONFIG.PMC_SD1_GRP_POW_ENABLE {0} \
   CONFIG.PMC_SD1_GRP_WP_ENABLE {0} \
   CONFIG.PMC_SD1_PERIPHERAL_ENABLE {1} \
   CONFIG.PMC_SD1_PERIPHERAL_IO {PMC_MIO 26 .. 36} \
   CONFIG.PMC_SD1_SLOT_TYPE {SD 3.0} \
   CONFIG.PMC_SD1_SPEED_MODE {high speed} \
   CONFIG.PMC_USE_PMC_NOC_AXI0 {1} \
   CONFIG.PS_CAN1_PERIPHERAL_ENABLE {1} \
   CONFIG.PS_CAN1_PERIPHERAL_IO {PMC_MIO 40 .. 41} \
   CONFIG.PS_CRF_FPD_TOP_SWITCH_CTRL_ACT_FREQMHZ {774.992249} \
   CONFIG.PS_CRL_CAN1_REF_CTRL_ACT_FREQMHZ {99.999001} \
   CONFIG.PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ {774.992249} \
   CONFIG.PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {775} \
   CONFIG.PS_CRL_GEM0_REF_CTRL_ACT_FREQMHZ {124.998749} \
   CONFIG.PS_CRL_GEM0_REF_CTRL_DIVISOR0 {8} \
   CONFIG.PS_CRL_GEM1_REF_CTRL_ACT_FREQMHZ {124.998749} \
   CONFIG.PS_CRL_GEM1_REF_CTRL_DIVISOR0 {8} \
   CONFIG.PS_CRL_GEM_TSU_REF_CTRL_ACT_FREQMHZ {249.997498} \
   CONFIG.PS_CRL_GEM_TSU_REF_CTRL_DIVISOR0 {4} \
   CONFIG.PS_CRL_I2C1_REF_CTRL_ACT_FREQMHZ {99.999001} \
   CONFIG.PS_CRL_RPLL_CTRL_FBDIV {93} \
   CONFIG.PS_CRL_UART0_REF_CTRL_ACT_FREQMHZ {99.999001} \
   CONFIG.PS_CRL_USB0_BUS_REF_CTRL_ACT_FREQMHZ {19.999800} \
   CONFIG.PS_CRL_USB3_DUAL_REF_CTRL_FREQMHZ {100} \
   CONFIG.PS_ENET0_GRP_MDIO_ENABLE {1} \
   CONFIG.PS_ENET0_GRP_MDIO_IO {PS_MIO 24 .. 25} \
   CONFIG.PS_ENET0_PERIPHERAL_ENABLE {1} \
   CONFIG.PS_ENET0_PERIPHERAL_IO {PS_MIO 0 .. 11} \
   CONFIG.PS_ENET1_PERIPHERAL_ENABLE {1} \
   CONFIG.PS_ENET1_PERIPHERAL_IO {PS_MIO 12 .. 23} \
   CONFIG.PS_GEN_IPI_0_ENABLE {1} \
   CONFIG.PS_GEN_IPI_1_ENABLE {1} \
   CONFIG.PS_GEN_IPI_2_ENABLE {1} \
   CONFIG.PS_GEN_IPI_3_ENABLE {1} \
   CONFIG.PS_GEN_IPI_4_ENABLE {1} \
   CONFIG.PS_GEN_IPI_5_ENABLE {1} \
   CONFIG.PS_GEN_IPI_6_ENABLE {1} \
   CONFIG.PS_GEN_IPI_PMCNOBUF_ENABLE {1} \
   CONFIG.PS_GEN_IPI_PMC_ENABLE {1} \
   CONFIG.PS_GEN_IPI_PSM_ENABLE {1} \
   CONFIG.PS_GPIO2_MIO_PERIPHERAL_ENABLE {0} \
   CONFIG.PS_I2C1_PERIPHERAL_ENABLE {1} \
   CONFIG.PS_I2C1_PERIPHERAL_IO {PMC_MIO 44 .. 45} \
   CONFIG.PS_MIO_0_DIRECTION {out} \
   CONFIG.PS_MIO_0_SCHMITT {1} \
   CONFIG.PS_MIO_12_DIRECTION {out} \
   CONFIG.PS_MIO_12_SCHMITT {1} \
   CONFIG.PS_MIO_13_DIRECTION {out} \
   CONFIG.PS_MIO_13_SCHMITT {1} \
   CONFIG.PS_MIO_14_DIRECTION {out} \
   CONFIG.PS_MIO_14_SCHMITT {1} \
   CONFIG.PS_MIO_15_DIRECTION {out} \
   CONFIG.PS_MIO_15_SCHMITT {1} \
   CONFIG.PS_MIO_16_DIRECTION {out} \
   CONFIG.PS_MIO_16_SCHMITT {1} \
   CONFIG.PS_MIO_17_DIRECTION {out} \
   CONFIG.PS_MIO_17_SCHMITT {1} \
   CONFIG.PS_MIO_1_DIRECTION {out} \
   CONFIG.PS_MIO_1_SCHMITT {1} \
   CONFIG.PS_MIO_24_DIRECTION {out} \
   CONFIG.PS_MIO_24_SCHMITT {1} \
   CONFIG.PS_MIO_25_DIRECTION {inout} \
   CONFIG.PS_MIO_2_DIRECTION {out} \
   CONFIG.PS_MIO_2_SCHMITT {1} \
   CONFIG.PS_MIO_3_DIRECTION {out} \
   CONFIG.PS_MIO_3_SCHMITT {1} \
   CONFIG.PS_MIO_4_DIRECTION {out} \
   CONFIG.PS_MIO_4_SCHMITT {1} \
   CONFIG.PS_MIO_5_DIRECTION {out} \
   CONFIG.PS_MIO_5_SCHMITT {1} \
   CONFIG.PS_M_AXI_GP0_DATA_WIDTH {128} \
   CONFIG.PS_NUM_FABRIC_RESETS {1} \
   CONFIG.PS_PCIE_RESET_ENABLE {1} \
   CONFIG.PS_PCIE_RESET_IO {PS_MIO 18 .. 19} \
   CONFIG.PS_PMC_CONFIG_APPLIED {1} \
   CONFIG.PS_TTC0_PERIPHERAL_ENABLE {1} \
   CONFIG.PS_TTC0_REF_CTRL_ACT_FREQMHZ {149.998505} \
   CONFIG.PS_TTC0_REF_CTRL_FREQMHZ {149.998505} \
   CONFIG.PS_TTC3_PERIPHERAL_ENABLE {0} \
   CONFIG.PS_UART0_PERIPHERAL_ENABLE {1} \
   CONFIG.PS_UART0_PERIPHERAL_IO {PMC_MIO 42 .. 43} \
   CONFIG.PS_USB3_PERIPHERAL_ENABLE {1} \
   CONFIG.PS_USE_IRQ_8 {1} \
   CONFIG.PS_USE_IRQ_9 {0} \
   CONFIG.PS_USE_M_AXI_GP0 {1} \
   CONFIG.PS_USE_M_AXI_GP2 {1} \
   CONFIG.PS_USE_NOC_PS_CCI_0 {0} \
   CONFIG.PS_USE_NOC_PS_NCI_0 {0} \
   CONFIG.PS_USE_NOC_PS_NCI_1 {0} \
   CONFIG.PS_USE_PMCPL_CLK0 {1} \
   CONFIG.PS_USE_PS_NOC_CCI {1} \
   CONFIG.PS_USE_PS_NOC_NCI_0 {0} \
   CONFIG.PS_USE_PS_NOC_NCI_1 {0} \
   CONFIG.PS_USE_PS_NOC_RPU_0 {1} \
   CONFIG.PS_USE_S_AXI_GP0 {0} \
   CONFIG.PS_USE_S_AXI_GP4 {1} \
 ] $versal_cips_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_cdma_0_M_AXI [get_bd_intf_pins axi_cdma_0/M_AXI] [get_bd_intf_pins axi_noc_0/S06_AXI]
  set_property SIM_ATTRIBUTE.MARK_SIM "true" [get_bd_intf_nets /axi_cdma_0_M_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_ports ddr4_dimm1] [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
  connect_bd_intf_net -intf_net axi_smc_1_M00_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_smc_1/M00_AXI]
  connect_bd_intf_net -intf_net axi_smc_2_M00_AXI [get_bd_intf_pins axi_smc_2/M00_AXI] [get_bd_intf_pins versal_cips_0/S_AXI_LPD]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_cdma_0/S_AXI_LITE] [get_bd_intf_pins axi_smc/M00_AXI]
  connect_bd_intf_net -intf_net ddr4_dimm1_sma_clk_1 [get_bd_intf_ports ddr4_dimm1_sma_clk] [get_bd_intf_pins axi_noc_0/sys_clk0]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins axi_smc_2/S00_AXI] [get_bd_intf_pins microblaze_0/M_AXI_DP]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]
  set_property SIM_ATTRIBUTE.MARK_SIM "true" [get_bd_intf_nets /versal_cips_0_FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]
  set_property SIM_ATTRIBUTE.MARK_SIM "true" [get_bd_intf_nets /versal_cips_0_FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]
  set_property SIM_ATTRIBUTE.MARK_SIM "true" [get_bd_intf_nets /versal_cips_0_FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]
  set_property SIM_ATTRIBUTE.MARK_SIM "true" [get_bd_intf_nets /versal_cips_0_FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_FPD [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_FPD]
  set_property SIM_ATTRIBUTE.MARK_SIM "true" [get_bd_intf_nets /versal_cips_0_M_AXI_FPD]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_LPD [get_bd_intf_pins axi_smc_1/S00_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_LPD]
  set_property SIM_ATTRIBUTE.MARK_SIM "true" [get_bd_intf_nets /versal_cips_0_M_AXI_LPD]
  connect_bd_intf_net -intf_net versal_cips_0_NOC_LPD_AXI_0 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/NOC_LPD_AXI_0]
  set_property SIM_ATTRIBUTE.MARK_SIM "true" [get_bd_intf_nets /versal_cips_0_NOC_LPD_AXI_0]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]

  # Create port connections
  connect_bd_net -net axi_cdma_0_cdma_introut [get_bd_pins axi_cdma_0/cdma_introut] [get_bd_pins versal_cips_0/pl_ps_irq8]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_versal_cips_0_333M/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_ports pl0_ref_clk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_cdma_0/m_axi_aclk] [get_bd_pins axi_cdma_0/s_axi_lite_aclk] [get_bd_pins axi_noc_0/aclk6] [get_bd_pins axi_smc/aclk] [get_bd_pins axi_smc_1/aclk] [get_bd_pins axi_smc_2/aclk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins rst_versal_cips_0_333M/slowest_sync_clk] [get_bd_pins versal_cips_0/m_axi_fpd_aclk] [get_bd_pins versal_cips_0/m_axi_lpd_aclk] [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins versal_cips_0/s_axi_lpd_aclk]
  connect_bd_net -net rst_versal_cips_0_333M_bus_struct_reset [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins rst_versal_cips_0_333M/bus_struct_reset]
  connect_bd_net -net rst_versal_cips_0_333M_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins rst_versal_cips_0_333M/mb_reset]
  connect_bd_net -net rst_versal_cips_0_333M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_cdma_0/s_axi_lite_aresetn] [get_bd_pins axi_smc/aresetn] [get_bd_pins axi_smc_1/aresetn] [get_bd_pins axi_smc_2/aresetn] [get_bd_pins rst_versal_cips_0_333M/peripheral_aresetn]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk [get_bd_pins axi_noc_0/aclk2] [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk [get_bd_pins axi_noc_0/aclk3] [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk [get_bd_pins axi_noc_0/aclk4] [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk [get_bd_pins axi_noc_0/aclk5] [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/lpd_axi_noc_clk]
  connect_bd_net -net versal_cips_0_pl0_resetn [get_bd_ports pl_gen_reset] [get_bd_pins rst_versal_cips_0_333M/ext_reset_in] [get_bd_pins versal_cips_0/pl0_resetn]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces axi_cdma_0/Data] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_LPD_AFI_FS] -force
  assign_bd_address -offset 0xFE000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_LPD_SLAVES] -force
  assign_bd_address -offset 0x80000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces versal_cips_0/Data1] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0xA4000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/Data1] [get_bd_addr_segs axi_cdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_CCI0] [get_bd_addr_segs axi_noc_0/S02_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_PMC] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_RPU0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_CCI0] [get_bd_addr_segs axi_noc_0/S02_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_PMC] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_RPU0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_CCI1] [get_bd_addr_segs axi_noc_0/S03_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_CCI1] [get_bd_addr_segs axi_noc_0/S03_AXI/C1_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_CCI2] [get_bd_addr_segs axi_noc_0/S04_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_CCI2] [get_bd_addr_segs axi_noc_0/S04_AXI/C2_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_CCI3] [get_bd_addr_segs axi_noc_0/S05_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces versal_cips_0/DATA_CCI3] [get_bd_addr_segs axi_noc_0/S05_AXI/C3_DDR_LOW1] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_AIE_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_DDR_256GB]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_DDR_32GB]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_DDR_734GB]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_DDR_CH1]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_DDR_CH2]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_DDR_CH3]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_DDR_LOWER_2GB]
  exclude_bd_addr_seg -offset 0xA4000000 -range 0x04000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_FPD_AFI_0]
  exclude_bd_addr_seg -offset 0xB0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_FPD_AFI_1]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_FPD_SLAVES]
  exclude_bd_addr_seg -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_PCIE_0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_PL1TB]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_PL8GB]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_PLNOC2TB]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_PLNOC8TB]
  exclude_bd_addr_seg -offset 0xF0000000 -range 0x08000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_PMC_SLAVES]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs versal_cips_0/s_axi_lpd/SAXILPD_QSPI]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  regenerate_bd_layout
  #add_files -fileset constrs_1 -norecurse ./top.XDC
  make_wrapper -files [get_files $design_name.bd] -top -import 
	
}
# End of create_root_design()

##################################################################
# MAIN FLOW
##################################################################
create_root_design $currentDir "" $design_name
	
	set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name ]
	set bdimportPath [file join [get_property directory [current_project]] [current_project].srcs ]
	
	open_bd_design [get_bd_files $design_name]
	
	set_property USER_COMMENTS.comment_0 {} [current_bd_design]
	set_property USER_COMMENTS.comment0 {Next Steps:
	1. Generate Block Design (Choose global for quick turnaround).
	2. Run Simulation.
	3. Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2020.2/ced/Xilinx/IPI/cips_vip/README.md} [current_bd_design]
	
	regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "comment_0":"Next Steps:
	1. Generate Block Design (Choose global for quick turnaround).
	2. Run Simulation.
	3. Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2020.2/ced/Xilinx/IPI/cips_vip/README.md",
   "commentid":"comment_0|",
   "font_comment_0":"18",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
	#  -string -flagsOSRD
									  
	preplace cgraphic comment_0 place top 1307 -119 textcolor 4 linecolor 3
	",
   "linktoobj_comment_0":"",
   "linktotype_comment_0":"bd_design" }
   
		#Testbench file creation and import
		set originalTBFile [file join $currentDir testbench system.sv]
		set xdc [file join $currentDir constrs_1 top.xdc]
		set mb_elf [file join $currentDir design_files mb_hello.elf]
		set tempTBFile [file join $bdDesignPath system.sv] 
		import_files -fileset constrs_1 -norecurse $xdc
		import_files -fileset sim_1 -norecurse $mb_elf
		set_property SCOPED_TO_REF $design_name [get_files -all -of_objects [get_fileset sim_1] $bdimportPath/sim_1/imports/design_files/mb_hello.elf]
		set_property SCOPED_TO_CELLS { microblaze_0 } [get_files -all -of_objects [get_fileset sim_1] $bdimportPath/sim_1/imports/design_files/mb_hello.elf]

		#file delete -force $tempTBFile 
		#file copy -force $originalTBFile $tempTBFile 
		set infile [open $originalTBFile]
		set contents [read $infile]
		close $infile
		set contents [string map [list "design_1" "$design_name"] $contents]

		set outfile [open $tempTBFile w]
		puts -nonewline $outfile $contents
		close $outfile

		import_files -fileset [get_filesets sim_1] -norecurse [list $tempTBFile]
		file delete -force $tempTBFile 
		set_property top tb [get_filesets sim_1] 
	# set_property -name {xsim.elaborate.xelab.more_options} -value {-cc gcc} -objects [current_fileset -simset]
}
