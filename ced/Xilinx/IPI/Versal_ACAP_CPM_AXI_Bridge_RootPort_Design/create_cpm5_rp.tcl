  # Create interface ports
  set PCIE0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT_0 ]

  set ch0_lpddr4_trip1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch0_lpddr4_trip1 ]

  set ch0_lpddr4_trip2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch0_lpddr4_trip2 ]

  set ch1_lpddr4_trip1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch1_lpddr4_trip1 ]

  set ch1_lpddr4_trip2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch1_lpddr4_trip2 ]

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]

  set lpddr4_clk1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 lpddr4_clk1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200321000} \
   ] $lpddr4_clk1

  set lpddr4_clk2 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 lpddr4_clk2 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200321000} \
   ] $lpddr4_clk2


  # Create ports

  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc axi_noc_0 ]
  set_property -dict [ list \
   CONFIG.CH0_LPDDR4_0_BOARD_INTERFACE {ch0_lpddr4_trip1} \
   CONFIG.CH0_LPDDR4_1_BOARD_INTERFACE {ch0_lpddr4_trip2} \
   CONFIG.CH1_LPDDR4_0_BOARD_INTERFACE {ch1_lpddr4_trip1} \
   CONFIG.CH1_LPDDR4_1_BOARD_INTERFACE {ch1_lpddr4_trip2} \
   CONFIG.CONTROLLERTYPE {LPDDR4_SDRAM} \
   CONFIG.LOGO_FILE {data/noc_mc.png} \
   CONFIG.MC0_CONFIG_NUM {config26} \
   CONFIG.MC0_FLIPPED_PINOUT {true} \
   CONFIG.MC1_CONFIG_NUM {config26} \
   CONFIG.MC1_FLIPPED_PINOUT {true} \
   CONFIG.MC2_CONFIG_NUM {config26} \
   CONFIG.MC3_CONFIG_NUM {config26} \
   CONFIG.MC_ADDR_BIT2 {CA0} \
   CONFIG.MC_ADDR_BIT3 {CA1} \
   CONFIG.MC_ADDR_BIT4 {CA2} \
   CONFIG.MC_ADDR_BIT5 {CA3} \
   CONFIG.MC_ADDR_BIT6 {CH_SEL} \
   CONFIG.MC_ADDR_BIT7 {CA4} \
   CONFIG.MC_ADDR_BIT8 {NC} \
   CONFIG.MC_ADDR_BIT14 {BA0} \
   CONFIG.MC_ADDR_BIT15 {BA1} \
   CONFIG.MC_ADDR_BIT16 {BA2} \
   CONFIG.MC_ADDR_WIDTH {6} \
   CONFIG.MC_BA_WIDTH {3} \
   CONFIG.MC_BG_WIDTH {0} \
   CONFIG.MC_BOARD_INTRF_EN {true} \
   CONFIG.MC_BURST_LENGTH {16} \
   CONFIG.MC_CASLATENCY {36} \
   CONFIG.MC_CASWRITELATENCY {18} \
   CONFIG.MC_CH0_LP4_CHA_ENABLE {true} \
   CONFIG.MC_CH0_LP4_CHB_ENABLE {true} \
   CONFIG.MC_CH1_LP4_CHA_ENABLE {true} \
   CONFIG.MC_CH1_LP4_CHB_ENABLE {true} \
   CONFIG.MC_CHANNEL_INTERLEAVING {true} \
   CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
   CONFIG.MC_CH_INTERLEAVING_SIZE {64_Bytes} \
   CONFIG.MC_CKE_WIDTH {0} \
   CONFIG.MC_CK_WIDTH {0} \
   CONFIG.MC_COMPONENT_DENSITY {16Gb} \
   CONFIG.MC_COMPONENT_WIDTH {x32} \
   CONFIG.MC_CONFIG_NUM {config26} \
   CONFIG.MC_DATAWIDTH {32} \
   CONFIG.MC_DDR_INIT_TIMEOUT {0x00036330} \
   CONFIG.MC_DM_WIDTH {4} \
   CONFIG.MC_DQS_WIDTH {4} \
   CONFIG.MC_DQ_WIDTH {32} \
   CONFIG.MC_ECC_SCRUB_PERIOD {0x004C4C} \
   CONFIG.MC_ECC_SCRUB_SIZE {4096} \
   CONFIG.MC_EN_BACKGROUND_SCRUBBING {true} \
   CONFIG.MC_F1_CASLATENCY {36} \
   CONFIG.MC_F1_CASWRITELATENCY {18} \
   CONFIG.MC_F1_LPDDR4_MR13 {0x00C0} \
   CONFIG.MC_F1_TCCD_L {0} \
   CONFIG.MC_F1_TCCD_L_MIN {0} \
   CONFIG.MC_F1_TFAW {30000} \
   CONFIG.MC_F1_TFAWMIN {30000} \
   CONFIG.MC_F1_TMOD {0} \
   CONFIG.MC_F1_TMOD_MIN {0} \
   CONFIG.MC_F1_TMRD {14000} \
   CONFIG.MC_F1_TMRDMIN {14000} \
   CONFIG.MC_F1_TMRW {10000} \
   CONFIG.MC_F1_TMRWMIN {10000} \
   CONFIG.MC_F1_TRAS {42000} \
   CONFIG.MC_F1_TRASMIN {42000} \
   CONFIG.MC_F1_TRCD {18000} \
   CONFIG.MC_F1_TRCDMIN {18000} \
   CONFIG.MC_F1_TRPAB {21000} \
   CONFIG.MC_F1_TRPABMIN {21000} \
   CONFIG.MC_F1_TRPPB {18000} \
   CONFIG.MC_F1_TRPPBMIN {18000} \
   CONFIG.MC_F1_TRRD {7500} \
   CONFIG.MC_F1_TRRDMIN {7500} \
   CONFIG.MC_F1_TRRD_L {0} \
   CONFIG.MC_F1_TRRD_L_MIN {0} \
   CONFIG.MC_F1_TRRD_S {0} \
   CONFIG.MC_F1_TRRD_S_MIN {0} \
   CONFIG.MC_F1_TWR {18000} \
   CONFIG.MC_F1_TWRMIN {18000} \
   CONFIG.MC_F1_TWTR {10000} \
   CONFIG.MC_F1_TWTRMIN {10000} \
   CONFIG.MC_F1_TWTR_L {0} \
   CONFIG.MC_F1_TWTR_L_MIN {0} \
   CONFIG.MC_F1_TWTR_S {0} \
   CONFIG.MC_F1_TWTR_S_MIN {0} \
   CONFIG.MC_F1_TZQLAT {30000} \
   CONFIG.MC_F1_TZQLATMIN {30000} \
   CONFIG.MC_INPUTCLK0_PERIOD {4992} \
   CONFIG.MC_INPUT_FREQUENCY0 {200.321} \
   CONFIG.MC_INTERLEAVE_SIZE {256} \
   CONFIG.MC_IP_TIMEPERIOD0_FOR_OP {1071} \
   CONFIG.MC_IP_TIMEPERIOD1 {512} \
   CONFIG.MC_LP4_CA_A_WIDTH {6} \
   CONFIG.MC_LP4_CA_B_WIDTH {6} \
   CONFIG.MC_LP4_CKE_A_WIDTH {1} \
   CONFIG.MC_LP4_CKE_B_WIDTH {1} \
   CONFIG.MC_LP4_CKT_A_WIDTH {1} \
   CONFIG.MC_LP4_CKT_B_WIDTH {1} \
   CONFIG.MC_LP4_CS_A_WIDTH {1} \
   CONFIG.MC_LP4_CS_B_WIDTH {1} \
   CONFIG.MC_LP4_DMI_A_WIDTH {2} \
   CONFIG.MC_LP4_DMI_B_WIDTH {2} \
   CONFIG.MC_LP4_DQS_A_WIDTH {2} \
   CONFIG.MC_LP4_DQS_B_WIDTH {2} \
   CONFIG.MC_LP4_DQ_A_WIDTH {16} \
   CONFIG.MC_LP4_DQ_B_WIDTH {16} \
   CONFIG.MC_LP4_RESETN_WIDTH {1} \
   CONFIG.MC_MEMORY_DENSITY {2GB} \
   CONFIG.MC_MEMORY_DEVICETYPE {Components} \
   CONFIG.MC_MEMORY_DEVICE_DENSITY {16Gb} \
   CONFIG.MC_MEMORY_SPEEDGRADE {LPDDR4-4267} \
   CONFIG.MC_MEMORY_TIMEPERIOD0 {512} \
   CONFIG.MC_MEMORY_TIMEPERIOD1 {512} \
   CONFIG.MC_MEM_DEVICE_WIDTH {x32} \
   CONFIG.MC_NO_CHANNELS {Dual} \
   CONFIG.MC_ODTLon {8} \
   CONFIG.MC_ODT_WIDTH {0} \
   CONFIG.MC_PER_RD_INTVL {0} \
   CONFIG.MC_PRE_DEF_ADDR_MAP_SEL {ROW_BANK_COLUMN} \
   CONFIG.MC_REFRESH_SPEED {1x} \
   CONFIG.MC_STACKHEIGHT {1} \
   CONFIG.MC_SYSTEM_CLOCK {Differential} \
   CONFIG.MC_TCCD {8} \
   CONFIG.MC_TCCD_L {0} \
   CONFIG.MC_TCCD_L_MIN {0} \
   CONFIG.MC_TCKE {15} \
   CONFIG.MC_TCKEMIN {15} \
   CONFIG.MC_TDQS2DQ_MAX {800} \
   CONFIG.MC_TDQS2DQ_MIN {200} \
   CONFIG.MC_TDQSCK_MAX {3500} \
   CONFIG.MC_TFAW {30000} \
   CONFIG.MC_TFAWMIN {30000} \
   CONFIG.MC_TFAW_nCK {0} \
   CONFIG.MC_TMOD {0} \
   CONFIG.MC_TMOD_MIN {0} \
   CONFIG.MC_TMPRR {0} \
   CONFIG.MC_TMRD {14000} \
   CONFIG.MC_TMRDMIN {14000} \
   CONFIG.MC_TMRD_div4 {10} \
   CONFIG.MC_TMRD_nCK {28} \
   CONFIG.MC_TMRW {10000} \
   CONFIG.MC_TMRWMIN {10000} \
   CONFIG.MC_TMRW_div4 {10} \
   CONFIG.MC_TMRW_nCK {20} \
   CONFIG.MC_TODTon_MIN {3} \
   CONFIG.MC_TOSCO {40000} \
   CONFIG.MC_TOSCOMIN {40000} \
   CONFIG.MC_TOSCO_nCK {79} \
   CONFIG.MC_TPAR_ALERT_ON {0} \
   CONFIG.MC_TPAR_ALERT_PW_MAX {0} \
   CONFIG.MC_TPBR2PBR {90000} \
   CONFIG.MC_TPBR2PBRMIN {90000} \
   CONFIG.MC_TRAS {42000} \
   CONFIG.MC_TRASMIN {42000} \
   CONFIG.MC_TRAS_nCK {83} \
   CONFIG.MC_TRC {63000} \
   CONFIG.MC_TRCD {18000} \
   CONFIG.MC_TRCDMIN {18000} \
   CONFIG.MC_TRCD_nCK {36} \
   CONFIG.MC_TRCMIN {0} \
   CONFIG.MC_TREFI {3904000} \
   CONFIG.MC_TREFIPB {488000} \
   CONFIG.MC_TRFC {0} \
   CONFIG.MC_TRFCAB {280000} \
   CONFIG.MC_TRFCABMIN {280000} \
   CONFIG.MC_TRFCMIN {0} \
   CONFIG.MC_TRFCPB {140000} \
   CONFIG.MC_TRFCPBMIN {140000} \
   CONFIG.MC_TRP {0} \
   CONFIG.MC_TRPAB {21000} \
   CONFIG.MC_TRPABMIN {21000} \
   CONFIG.MC_TRPAB_nCK {42} \
   CONFIG.MC_TRPMIN {0} \
   CONFIG.MC_TRPPB {18000} \
   CONFIG.MC_TRPPBMIN {18000} \
   CONFIG.MC_TRPPB_nCK {36} \
   CONFIG.MC_TRPRE {1.8} \
   CONFIG.MC_TRRD {7500} \
   CONFIG.MC_TRRDMIN {7500} \
   CONFIG.MC_TRRD_L {0} \
   CONFIG.MC_TRRD_L_MIN {0} \
   CONFIG.MC_TRRD_S {0} \
   CONFIG.MC_TRRD_S_MIN {0} \
   CONFIG.MC_TRRD_nCK {15} \
   CONFIG.MC_TRTP_nCK {16} \
   CONFIG.MC_TWPRE {1.8} \
   CONFIG.MC_TWPST {0.4} \
   CONFIG.MC_TWR {18000} \
   CONFIG.MC_TWRMIN {18000} \
   CONFIG.MC_TWR_nCK {36} \
   CONFIG.MC_TWTR {10000} \
   CONFIG.MC_TWTRMIN {10000} \
   CONFIG.MC_TWTR_L {0} \
   CONFIG.MC_TWTR_S {0} \
   CONFIG.MC_TWTR_S_MIN {0} \
   CONFIG.MC_TWTR_nCK {20} \
   CONFIG.MC_TXP {15} \
   CONFIG.MC_TXPMIN {15} \
   CONFIG.MC_TXPR {0} \
   CONFIG.MC_TZQCAL {1000000} \
   CONFIG.MC_TZQCAL_div4 {489} \
   CONFIG.MC_TZQCS_ITVL {0} \
   CONFIG.MC_TZQLAT {30000} \
   CONFIG.MC_TZQLATMIN {30000} \
   CONFIG.MC_TZQLAT_div4 {15} \
   CONFIG.MC_TZQLAT_nCK {59} \
   CONFIG.MC_TZQ_START_ITVL {1000000000} \
   CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-3BA-10CA} \
   CONFIG.MC_XPLL_CLKOUT1_PERIOD {1024} \
   CONFIG.NUM_CLKS {12} \
   CONFIG.NUM_MC {2} \
   CONFIG.NUM_MCP {4} \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {9} \
   CONFIG.sys_clk0_BOARD_INTERFACE {lpddr4_clk1} \
   CONFIG.sys_clk1_BOARD_INTERFACE {lpddr4_clk2} \
 ] $axi_noc_0

  set_property -dict [ list \
   CONFIG.CATEGORY {ps_nci_phy} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/M02_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M02_AXI:0x0} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M02_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_1 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M02_AXI:0x0} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M02_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_2 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M02_AXI:0x0} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M02_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} MC_3 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M02_AXI:0x0} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80:M02_AXI:0x0:M00_AXI:0x1c0} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M02_AXI:0x0} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M02_AXI:0x0} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80:M02_AXI:0x0:M00_AXI:0x1c0} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /axi_noc_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80:M02_AXI:0x0:M00_AXI:0x1c0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/S08_AXI]

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

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S08_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk9]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk10]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk11]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.CLOCK_MODE {Custom} \
   CONFIG.CPM_CONFIG {\
     CPM_AXI_SLV_ECAM0_BASE_ADDRR_L {0x0}\
     CPM_AXI_SLV_ECAM0_BASE_ADDRR_H {0x6}\
     CPM_PCIE0_BRIDGE_AXI_SLAVE_IF {1}\
     CPM_PCIE0_FUNCTIONAL_MODE {AXI_Bridge}\
     CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s}\
     CPM_PCIE0_MODES {DMA}\
     CPM_PCIE0_MODE_SELECTION {Advanced}\
     CPM_PCIE0_PCIE_REGION_0_EN {1}\
     CPM_PCIE0_PCIE_REGION_0_SCALE {Megabytes}\
     CPM_PCIE0_PCIE_REGION_0_SIZE {256}\
     CPM_PCIE0_PCIE_REGION_1_EN {1}\
     CPM_PCIE0_PCIE_REGION_1_SCALE {Gigabytes}\
     CPM_PCIE0_PCIE_REGION_1_SIZE {8}\
     CPM_PCIE0_PCIE_REGION_2_EN {1}\
     CPM_PCIE0_PCIE_REGION_2_SCALE {Gigabytes}\
     CPM_PCIE0_PCIE_REGION_2_SIZE {256}\
     CPM_PCIE0_PF0_BAR0_BRIDGE_64BIT {1}\
     CPM_PCIE0_PF0_BAR0_BRIDGE_SCALE {Terabytes}\
     CPM_PCIE0_PF0_BAR0_BRIDGE_SIZE {16}\
     CPM_PCIE0_PF0_CFG_DEV_ID {B348}\
     CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8}\
     CPM_PCIE0_PORT_TYPE {Root_Port_of_PCI_Express_Root_Complex}\
     PS_USE_PS_NOC_PCI_0 {1}\
   } \
   CONFIG.DDR_MEMORY_MODE {Custom} \
   CONFIG.DEBUG_MODE {JTAG} \
   CONFIG.DESIGN_MODE {1} \
   CONFIG.PS_BOARD_INTERFACE {Custom} \
   CONFIG.PS_PMC_CONFIG {\
     CLOCK_MODE {Custom}\
     DDR_MEMORY_MODE {Connectivity to DDR via NOC}\
     DEBUG_MODE {JTAG}\
     DESIGN_MODE {1}\
     PCIE_APERTURES_DUAL_ENABLE {0}\
     PCIE_APERTURES_SINGLE_ENABLE {1}\
     PMC_CRP_PL0_REF_CTRL_FREQMHZ {100}\
     PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}}\
     PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}}\
     PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high}\
{PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}}\
     PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}}\
     PMC_QSPI_PERIPHERAL_DATA_MODE {x4}\
     PMC_QSPI_PERIPHERAL_ENABLE {1}\
     PMC_QSPI_PERIPHERAL_MODE {Dual Parallel}\
     PMC_REF_CLK_FREQMHZ {33.3333}\
     PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}}\
{RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO\
1}}}\
     PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2}\
{CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3}\
{CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE\
1} {IO {PMC_MIO 26 .. 36}}}\
     PMC_SD1_SLOT_TYPE {SD 3.0}\
     PMC_USE_NOC_PMC_AXI0 {1}\
     PMC_USE_PMC_NOC_AXI0 {1}\
     PS_BOARD_INTERFACE {Custom}\
     PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}}\
     PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}}\
     PS_GEM0_ROUTE_THROUGH_FPD {1}\
     PS_GEM1_ROUTE_THROUGH_FPD {0}\
     PS_GEN_IPI0_ENABLE {1}\
     PS_GEN_IPI0_MASTER {A72}\
     PS_GEN_IPI1_ENABLE {1}\
     PS_GEN_IPI1_MASTER {A72}\
     PS_GEN_IPI2_ENABLE {1}\
     PS_GEN_IPI2_MASTER {A72}\
     PS_GEN_IPI3_ENABLE {1}\
     PS_GEN_IPI3_MASTER {A72}\
     PS_GEN_IPI4_ENABLE {1}\
     PS_GEN_IPI4_MASTER {A72}\
     PS_GEN_IPI5_ENABLE {1}\
     PS_GEN_IPI5_MASTER {A72}\
     PS_GEN_IPI6_ENABLE {1}\
     PS_GEN_IPI6_MASTER {A72}\
     PS_GEN_IPI_PMCNOBUF_ENABLE {1}\
     PS_GEN_IPI_PMC_ENABLE {1}\
     PS_GEN_IPI_PSM_ENABLE {1}\
     PS_HSDP_EGRESS_TRAFFIC {JTAG}\
     PS_HSDP_INGRESS_TRAFFIC {JTAG}\
     PS_HSDP_MODE {None}\
     PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}}\
     PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}}\
     PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 39 .. 40}}}\
     PS_LPDMA0_ROUTE_THROUGH_FPD {1}\
     PS_LPDMA1_ROUTE_THROUGH_FPD {1}\
     PS_LPDMA2_ROUTE_THROUGH_FPD {1}\
     PS_LPDMA3_ROUTE_THROUGH_FPD {1}\
     PS_LPDMA4_ROUTE_THROUGH_FPD {1}\
     PS_LPDMA5_ROUTE_THROUGH_FPD {1}\
     PS_LPDMA6_ROUTE_THROUGH_FPD {1}\
     PS_LPDMA7_ROUTE_THROUGH_FPD {1}\
     PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default}\
{PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}}\
     PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default}\
{PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}}\
     PS_NUM_FABRIC_RESETS {4}\
     PS_PCIE1_PERIPHERAL_ENABLE {2}\
     PS_PCIE2_PERIPHERAL_ENABLE {0}\
     PS_PCIE_RESET {{ENABLE 1}}\
     PS_PCIE_ROOT_RESET1_IO {PMC_MIO 38}\
     PS_TTC0_PERIPHERAL_ENABLE {1}\
     PS_TTC1_PERIPHERAL_ENABLE {1}\
     PS_TTC2_PERIPHERAL_ENABLE {1}\
     PS_TTC3_PERIPHERAL_ENABLE {1}\
     PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}}\
     PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}}\
     PS_USB_ROUTE_THROUGH_FPD {1}\
     PS_USE_FPD_AXI_NOC0 {1}\
     PS_USE_FPD_AXI_NOC1 {1}\
     PS_USE_FPD_CCI_NOC {1}\
     PS_USE_FPD_CCI_NOC0 {1}\
     PS_USE_NOC_FPD_AXI0 {1}\
     PS_USE_NOC_LPD_AXI0 {1}\
     PS_USE_PMCPL_CLK0 {1}\
     PS_USE_PMCPL_CLK1 {0}\
     PS_USE_PMCPL_CLK2 {0}\
     PS_USE_PMCPL_CLK3 {0}\
     PS_WWDT0_CLK {{ENABLE 1} {IO APB}}\
     PS_WWDT0_PERIPHERAL {{ENABLE 1} {IO EMIO}}\
     SMON_ALARMS {Set_Alarms_On}\
     SMON_ENABLE_TEMP_AVERAGING {0}\
     SMON_INTERFACE_TO_USE {I2C}\
     SMON_TEMP_AVERAGING_SAMPLES {0}\
   } \
   CONFIG.PS_PMC_CONFIG_APPLIED {1} \
 ] $versal_cips_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_1

  # Create interface connections
  connect_bd_intf_net -intf_net axi_noc_0_CH0_LPDDR4_0 [get_bd_intf_ports ch0_lpddr4_trip1] [get_bd_intf_pins axi_noc_0/CH0_LPDDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_CH0_LPDDR4_1 [get_bd_intf_ports ch0_lpddr4_trip2] [get_bd_intf_pins axi_noc_0/CH0_LPDDR4_1]
  connect_bd_intf_net -intf_net axi_noc_0_CH1_LPDDR4_0 [get_bd_intf_ports ch1_lpddr4_trip1] [get_bd_intf_pins axi_noc_0/CH1_LPDDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_CH1_LPDDR4_1 [get_bd_intf_ports ch1_lpddr4_trip2] [get_bd_intf_pins axi_noc_0/CH1_LPDDR4_1]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins versal_cips_0/NOC_FPD_AXI_0]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins versal_cips_0/NOC_PMC_AXI_0]
  connect_bd_intf_net -intf_net axi_noc_0_M02_AXI [get_bd_intf_pins axi_noc_0/M02_AXI] [get_bd_intf_pins versal_cips_0/NOC_CPM_PCIE_0]
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins versal_cips_0/gt_refclk0]
  connect_bd_intf_net -intf_net lpddr4_clk1_1 [get_bd_intf_ports lpddr4_clk1] [get_bd_intf_pins axi_noc_0/sys_clk0]
  connect_bd_intf_net -intf_net lpddr4_clk2_1 [get_bd_intf_ports lpddr4_clk2] [get_bd_intf_pins axi_noc_0/sys_clk1]
  connect_bd_intf_net -intf_net versal_cips_0_CPM_PCIE_NOC_0 [get_bd_intf_pins axi_noc_0/S08_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S06_AXI] [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_AXI_NOC_1 [get_bd_intf_pins axi_noc_0/S07_AXI] [get_bd_intf_pins versal_cips_0/FPD_AXI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_PCIE0_GT [get_bd_intf_ports PCIE0_GT_0] [get_bd_intf_pins versal_cips_0/PCIE0_GT]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]

  # Create port connections
  connect_bd_net -net versal_cips_0_cpm_pcie_noc_axi0_clk [get_bd_pins axi_noc_0/aclk8] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk6] [get_bd_pins versal_cips_0/fpd_axi_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_axi_noc_axi1_clk [get_bd_pins axi_noc_0/aclk7] [get_bd_pins versal_cips_0/fpd_axi_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk [get_bd_pins axi_noc_0/aclk2] [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk [get_bd_pins axi_noc_0/aclk3] [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins axi_noc_0/aclk4] [get_bd_pins versal_cips_0/lpd_axi_noc_clk]
  connect_bd_net -net versal_cips_0_noc_cpm_pcie_axi0_clk [get_bd_pins axi_noc_0/aclk11] [get_bd_pins versal_cips_0/noc_cpm_pcie_axi0_clk]
  connect_bd_net -net versal_cips_0_noc_fpd_axi_axi0_clk [get_bd_pins axi_noc_0/aclk9] [get_bd_pins versal_cips_0/noc_fpd_axi_axi0_clk]
  connect_bd_net -net versal_cips_0_noc_pmc_axi_axi0_clk [get_bd_pins axi_noc_0/aclk10] [get_bd_pins versal_cips_0/noc_pmc_axi_axi0_clk]
  connect_bd_net -net versal_cips_0_pl0_ref_clk [get_bd_pins versal_cips_0/dma0_intrfc_clk] [get_bd_pins versal_cips_0/pl0_ref_clk]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk5] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins versal_cips_0/dma0_intrfc_resetn] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins versal_cips_0/cpm_irq0] [get_bd_pins versal_cips_0/cpm_irq1] [get_bd_pins xlconstant_1/dout]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_LOW0x2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW0x2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs axi_noc_0/S08_AXI/C0_DDR_LOW0x2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0x2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW0x2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs axi_noc_0/S07_AXI/C0_DDR_LOW0x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW1x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_LOW1x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW1x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs axi_noc_0/S08_AXI/C0_DDR_LOW1x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs axi_noc_0/S07_AXI/C0_DDR_LOW1x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW1x2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_LOW0x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_LOW1x2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_LOW0x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_LOW1x2] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C3_DDR_LOW0x2] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C3_DDR_LOW1x2] -force
  assign_bd_address -offset 0xFFA80000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_0] -force
  assign_bd_address -offset 0xFFA88000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_0] -force
  assign_bd_address -offset 0xFFA90000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_1] -force
  assign_bd_address -offset 0xFFA98000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_1] -force
  assign_bd_address -offset 0xFFAA0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_2] -force
  assign_bd_address -offset 0xFFAA8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_2] -force
  assign_bd_address -offset 0xFFAB0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_3] -force
  assign_bd_address -offset 0xFFAB8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_3] -force
  assign_bd_address -offset 0xFFAC0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_4] -force
  assign_bd_address -offset 0xFFAC8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_4] -force
  assign_bd_address -offset 0xFFAD0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_5] -force
  assign_bd_address -offset 0xFFAD8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_5] -force
  assign_bd_address -offset 0xFFAE0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_6] -force
  assign_bd_address -offset 0xFFAE8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_6] -force
  assign_bd_address -offset 0xFFAF0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_7] -force
  assign_bd_address -offset 0xFFAF8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_7] -force
  assign_bd_address -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_apu_0] -force
  assign_bd_address -offset 0x000100800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_0] -force
  assign_bd_address -offset 0x000100800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_0] -force
  assign_bd_address -offset 0x000100B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_atm] -force
  assign_bd_address -offset 0x000100B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_atm] -force
  assign_bd_address -offset 0x000100B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_stm] -force
  assign_bd_address -offset 0x000100B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_stm] -force
  assign_bd_address -offset 0x000100980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_lpd_atm] -force
  assign_bd_address -offset 0x000100980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_lpd_atm] -force
  assign_bd_address -offset 0xFC000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_cpm] -force
  assign_bd_address -offset 0xFD1A0000 -range 0x00140000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crf_0] -force
  assign_bd_address -offset 0xFF5E0000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crl_0] -force
  assign_bd_address -offset 0xFF6E0000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crl_0] -force
  assign_bd_address -offset 0x000101260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crp_0] -force
  assign_bd_address -offset 0x000101260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crp_0] -force
  assign_bd_address -offset 0xFF0C0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ethernet_0] -force
  assign_bd_address -offset 0xFF0C8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ethernet_0] -force
  assign_bd_address -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_0] -force
  assign_bd_address -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_2] -force
  assign_bd_address -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_cci_0] -force
  assign_bd_address -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_gpv_0] -force
  assign_bd_address -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_maincci_0] -force
  assign_bd_address -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0] -force
  assign_bd_address -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_0] -force
  assign_bd_address -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_secure_0] -force
  assign_bd_address -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmu_0] -force
  assign_bd_address -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmutcu_0] -force
  assign_bd_address -offset 0xFF020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_i2c_0] -force
  assign_bd_address -offset 0xFF028000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_i2c_0] -force
  assign_bd_address -offset 0xFF030000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_i2c_1] -force
  assign_bd_address -offset 0xFF038000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_i2c_1] -force
  assign_bd_address -offset 0xFF330000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_0] -force
  assign_bd_address -offset 0xFF338000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_0] -force
  assign_bd_address -offset 0xFF340000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_1] -force
  assign_bd_address -offset 0xFF348000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_1] -force
  assign_bd_address -offset 0xFF350000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_2] -force
  assign_bd_address -offset 0xFF358000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_2] -force
  assign_bd_address -offset 0xFF360000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_3] -force
  assign_bd_address -offset 0xFF368000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_3] -force
  assign_bd_address -offset 0xFF370000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_4] -force
  assign_bd_address -offset 0xFF378000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_4] -force
  assign_bd_address -offset 0xFF380000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_5] -force
  assign_bd_address -offset 0xFF388000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_5] -force
  assign_bd_address -offset 0xFF3A0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_6] -force
  assign_bd_address -offset 0xFF3A8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_6] -force
  assign_bd_address -offset 0xFF320000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc] -force
  assign_bd_address -offset 0xFF328000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc] -force
  assign_bd_address -offset 0xFF390000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc_nobuf] -force
  assign_bd_address -offset 0xFF398000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc_nobuf] -force
  assign_bd_address -offset 0xFF310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_psm] -force
  assign_bd_address -offset 0xFF318000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_psm] -force
  assign_bd_address -offset 0xFF9B0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_afi_0] -force
  assign_bd_address -offset 0xFF9B8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_afi_0] -force
  assign_bd_address -offset 0xFF0A0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0] -force
  assign_bd_address -offset 0xFF0A8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0] -force
  assign_bd_address -offset 0xFF080000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_slcr_0] -force
  assign_bd_address -offset 0xFF090000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_slcr_0] -force
  assign_bd_address -offset 0xFF410000 -range 0x00080000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_0] -force
  assign_bd_address -offset 0xFF490000 -range 0x00080000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_0] -force
  assign_bd_address -offset 0xFF510000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_secure_0] -force
  assign_bd_address -offset 0xFF530000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_secure_0] -force
  assign_bd_address -offset 0xFF990000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_xppu_0] -force
  assign_bd_address -offset 0xFF998000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_xppu_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2] -force
  assign_bd_address -offset 0xFF960000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ctrl] -force
  assign_bd_address -offset 0xFF968000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ctrl] -force
  assign_bd_address -offset 0xFFFC0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ram_0] -force
  assign_bd_address -offset 0xFFFE0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ram_0] -force
  assign_bd_address -offset 0xFF980000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_xmpu_0] -force
  assign_bd_address -offset 0xFF988000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_xmpu_0] -force
  assign_bd_address -offset 0x0001011E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_aes] -force
  assign_bd_address -offset 0x0001011E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_aes] -force
  assign_bd_address -offset 0x0001011F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_bbram_ctrl] -force
  assign_bd_address -offset 0x0001011F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_bbram_ctrl] -force
  assign_bd_address -offset 0x0001012D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0] -force
  assign_bd_address -offset 0x0001012D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0] -force
  assign_bd_address -offset 0x0001012B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfu_apb_0] -force
  assign_bd_address -offset 0x0001012B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfu_apb_0] -force
  assign_bd_address -offset 0x0001011C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_0] -force
  assign_bd_address -offset 0x0001011C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_0] -force
  assign_bd_address -offset 0x0001011D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_1] -force
  assign_bd_address -offset 0x0001011D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_1] -force
  assign_bd_address -offset 0x000101250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_cache] -force
  assign_bd_address -offset 0x000101250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_cache] -force
  assign_bd_address -offset 0x000101240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_ctrl] -force
  assign_bd_address -offset 0x000101240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_ctrl] -force
  assign_bd_address -offset 0x000101110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_global_0] -force
  assign_bd_address -offset 0x000101110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_global_0] -force
  assign_bd_address -offset 0x000101020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_gpio_0] -force
  assign_bd_address -offset 0x000101020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_gpio_0] -force
  assign_bd_address -offset 0x000100280000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_iomodule_0] -force
  assign_bd_address -offset 0x000100280000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_iomodule_0] -force
  assign_bd_address -offset 0x000100310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0] -force
  assign_bd_address -offset 0x000100310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0] -force
  assign_bd_address -offset 0x000101030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_qspi_0] -force
  assign_bd_address -offset 0x000101030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_qspi_0] -force
  assign_bd_address -offset 0x000102000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram] -force
  assign_bd_address -offset 0x000102000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram] -force
  assign_bd_address -offset 0x000100240000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_data_cntlr] -force
  assign_bd_address -offset 0x000100240000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_data_cntlr] -force
  assign_bd_address -offset 0x000100200000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_instr_cntlr] -force
  assign_bd_address -offset 0x000100200000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_instr_cntlr] -force
  assign_bd_address -offset 0x000106000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_npi] -force
  assign_bd_address -offset 0x000106000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_npi] -force
  assign_bd_address -offset 0x000101200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rsa] -force
  assign_bd_address -offset 0x000101200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rsa] -force
  assign_bd_address -offset 0x0001012A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rtc_0] -force
  assign_bd_address -offset 0x0001012A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rtc_0] -force
  assign_bd_address -offset 0x000101050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sd_1] -force
  assign_bd_address -offset 0x000101050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sd_1] -force
  assign_bd_address -offset 0x000101210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sha] -force
  assign_bd_address -offset 0x000101210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sha] -force
  assign_bd_address -offset 0x000101220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot] -force
  assign_bd_address -offset 0x000101220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot] -force
  assign_bd_address -offset 0x000102100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot_stream] -force
  assign_bd_address -offset 0x000102100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot_stream] -force
  assign_bd_address -offset 0x000101270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sysmon_0] -force
  assign_bd_address -offset 0x000101270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sysmon_0] -force
  assign_bd_address -offset 0x000100083000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_inject_0] -force
  assign_bd_address -offset 0x000100083000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_inject_0] -force
  assign_bd_address -offset 0x000100283000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_manager_0] -force
  assign_bd_address -offset 0x000100283000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_manager_0] -force
  assign_bd_address -offset 0x000101230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_trng] -force
  assign_bd_address -offset 0x000101230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_trng] -force
  assign_bd_address -offset 0x0001012F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xmpu_0] -force
  assign_bd_address -offset 0x0001012F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xmpu_0] -force
  assign_bd_address -offset 0x000101310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_0] -force
  assign_bd_address -offset 0x000101310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_0] -force
  assign_bd_address -offset 0x000101300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_npi_0] -force
  assign_bd_address -offset 0x000101300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_npi_0] -force
  assign_bd_address -offset 0xFFC90000 -range 0x00004000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_psm_global_reg] -force
  assign_bd_address -offset 0xFFC94000 -range 0x00004000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_psm_global_reg] -force
  assign_bd_address -offset 0xFFE90000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_atcm_global] -force
  assign_bd_address -offset 0xFFE98000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_atcm_global] -force
  assign_bd_address -offset 0xFFEB0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_btcm_global] -force
  assign_bd_address -offset 0xFFEB8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_btcm_global] -force
  assign_bd_address -offset 0xFFE00000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_tcm_ram_global] -force
  assign_bd_address -offset 0xFFE20000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_tcm_ram_global] -force
  assign_bd_address -offset 0xFF9A0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_rpu_0] -force
  assign_bd_address -offset 0xFF9A8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_rpu_0] -force
  assign_bd_address -offset 0xFF000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_sbsauart_0] -force
  assign_bd_address -offset 0xFF008000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_sbsauart_0] -force
  assign_bd_address -offset 0xFF130000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntr_0] -force
  assign_bd_address -offset 0xFF138000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntr_0] -force
  assign_bd_address -offset 0xFF140000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntrs_0] -force
  assign_bd_address -offset 0xFF148000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntrs_0] -force
  assign_bd_address -offset 0xFF0E0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_0] -force
  assign_bd_address -offset 0xFF0E8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_0] -force
  assign_bd_address -offset 0xFF0F0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_1] -force
  assign_bd_address -offset 0xFF0F8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_1] -force
  assign_bd_address -offset 0xFF100000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_2] -force
  assign_bd_address -offset 0xFF108000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_2] -force
  assign_bd_address -offset 0xFF110000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_3] -force
  assign_bd_address -offset 0xFF118000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_3] -force
  assign_bd_address -offset 0xFF9D0000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_usb_0] -force
  assign_bd_address -offset 0xFF9D8000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_usb_0] -force
  assign_bd_address -offset 0xFE200000 -range 0x00080000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_usb_xhci_0] -force
  assign_bd_address -offset 0xFE280000 -range 0x00080000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_usb_xhci_0] -force
  assign_bd_address -offset 0xFF120000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_wwdt_0] -force
  assign_bd_address -offset 0xFF128000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_wwdt_0] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xF0800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0xF0B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0xF0B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0xF0980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00140000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xF1260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xF11E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0xF11F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0xF12D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0xF12B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0xF11C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0xF11D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0xF1250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0xF1240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0xF1110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0xF1020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -offset 0xF0310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0xF1030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0xF2000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram]
  exclude_bd_addr_seg -offset 0xF6000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0xF1200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0xF12A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0xF1050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sd_1]
  exclude_bd_addr_seg -offset 0xF1210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -offset 0xF1270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0xF1230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0xF12F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0xF1310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0xF1300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0]
  exclude_bd_addr_seg -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1]
  exclude_bd_addr_seg -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2]
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xF0800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0xF0B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0xF0B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0xF0980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0xFC000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_cpm]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00140000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00140000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00300000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00300000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0xF1260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFF0C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ethernet_0]
  exclude_bd_addr_seg -offset 0xFF0C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ethernet_0]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFF020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_i2c_0]
  exclude_bd_addr_seg -offset 0xFF020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_i2c_0]
  exclude_bd_addr_seg -offset 0xFF030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_i2c_1]
  exclude_bd_addr_seg -offset 0xFF030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_i2c_1]
  exclude_bd_addr_seg -offset 0xFF330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -offset 0xFF330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -offset 0xFF340000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -offset 0xFF340000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -offset 0xFF350000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -offset 0xFF350000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -offset 0xFF360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -offset 0xFF360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -offset 0xFF370000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -offset 0xFF370000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -offset 0xFF380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -offset 0xFF380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -offset 0xFF3A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -offset 0xFF3A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0]
  exclude_bd_addr_seg -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1]
  exclude_bd_addr_seg -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ram_0]
  exclude_bd_addr_seg -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ram_0]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xF11E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0xF11F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0xF12D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0xF12B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0xF11C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0xF11D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0xF1250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0xF1240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0xF1110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0xF1020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -offset 0xF0310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0xF1030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0xF2000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram]
  exclude_bd_addr_seg -offset 0xF6000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0xF1200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0xF12A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0xF1050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sd_1]
  exclude_bd_addr_seg -offset 0xF1210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -offset 0xF1270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0xF1230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0xF12F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0xF1310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0xF1300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg -offset 0xFF0E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_0]
  exclude_bd_addr_seg -offset 0xFF0E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_0]
  exclude_bd_addr_seg -offset 0xFF0F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_1]
  exclude_bd_addr_seg -offset 0xFF0F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_1]
  exclude_bd_addr_seg -offset 0xFF100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_2]
  exclude_bd_addr_seg -offset 0xFF100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_2]
  exclude_bd_addr_seg -offset 0xFF110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_3]
  exclude_bd_addr_seg -offset 0xFF110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_3]
  exclude_bd_addr_seg -offset 0xFF9D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_usb_0]
  exclude_bd_addr_seg -offset 0xFF9D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_usb_0]
  exclude_bd_addr_seg -offset 0xFE200000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_usb_xhci_0]
  exclude_bd_addr_seg -offset 0xFE200000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_usb_xhci_0]
  exclude_bd_addr_seg -offset 0xFF120000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_wwdt_0]
  exclude_bd_addr_seg -offset 0xFF120000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_AXI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_wwdt_0]
  exclude_bd_addr_seg -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0]
  exclude_bd_addr_seg -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1]
  exclude_bd_addr_seg -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2]
  exclude_bd_addr_seg -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0]
  exclude_bd_addr_seg -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1]
  exclude_bd_addr_seg -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2]
  exclude_bd_addr_seg -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0]
  exclude_bd_addr_seg -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1]
  exclude_bd_addr_seg -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2]
  exclude_bd_addr_seg -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_0]
  exclude_bd_addr_seg -offset 0x000600000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_1]
  exclude_bd_addr_seg -offset 0x008000000000 -range 0x004000000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs versal_cips_0/NOC_CPM_PCIE_0/pspmc_0_psv_noc_pcie_2]
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_0]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_1]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_2]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_3]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_4]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_5]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_6]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_adma_7]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_apu_0]
  exclude_bd_addr_seg -offset 0xF0800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0x000100800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_0]
  exclude_bd_addr_seg -offset 0xF0B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0x000100B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_atm]
  exclude_bd_addr_seg -offset 0xF0B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0x000100B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_fpd_stm]
  exclude_bd_addr_seg -offset 0xF0980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0x000100980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_coresight_lpd_atm]
  exclude_bd_addr_seg -offset 0xFC000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_cpm]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00140000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFD1A0000 -range 0x00140000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crf_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00300000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0xFF5E0000 -range 0x00300000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crl_0]
  exclude_bd_addr_seg -offset 0xF1260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0x000101260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_crp_0]
  exclude_bd_addr_seg -offset 0xFF0C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ethernet_0]
  exclude_bd_addr_seg -offset 0xFF0C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ethernet_0]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_0]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_afi_2]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_cci_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_gpv_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_maincci_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slave_xmpu_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_fpd_smmutcu_0]
  exclude_bd_addr_seg -offset 0xFF020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_i2c_0]
  exclude_bd_addr_seg -offset 0xFF020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_i2c_0]
  exclude_bd_addr_seg -offset 0xFF030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_i2c_1]
  exclude_bd_addr_seg -offset 0xFF030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_i2c_1]
  exclude_bd_addr_seg -offset 0xFF330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -offset 0xFF330000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_0]
  exclude_bd_addr_seg -offset 0xFF340000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -offset 0xFF340000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_1]
  exclude_bd_addr_seg -offset 0xFF350000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -offset 0xFF350000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_2]
  exclude_bd_addr_seg -offset 0xFF360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -offset 0xFF360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_3]
  exclude_bd_addr_seg -offset 0xFF370000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -offset 0xFF370000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_4]
  exclude_bd_addr_seg -offset 0xFF380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -offset 0xFF380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_5]
  exclude_bd_addr_seg -offset 0xFF3A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -offset 0xFF3A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_6]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_pmc_nobuf]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ipi_psm]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_afi_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_secure_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_iou_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF410000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF510000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_slcr_secure_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_lpd_xppu_0]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ctrl]
  exclude_bd_addr_seg -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_ram_0]
  exclude_bd_addr_seg -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_ram_0]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ocm_xmpu_0]
  exclude_bd_addr_seg -offset 0xF11E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0x0001011E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_aes]
  exclude_bd_addr_seg -offset 0xF11F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0x0001011F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_bbram_ctrl]
  exclude_bd_addr_seg -offset 0xF12D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0x0001012D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfi_cframe_0]
  exclude_bd_addr_seg -offset 0xF12B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0x0001012B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_cfu_apb_0]
  exclude_bd_addr_seg -offset 0xF11C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0x0001011C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_0]
  exclude_bd_addr_seg -offset 0xF11D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0x0001011D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_dma_1]
  exclude_bd_addr_seg -offset 0xF1250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0x000101250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_cache]
  exclude_bd_addr_seg -offset 0xF1240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0x000101240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_efuse_ctrl]
  exclude_bd_addr_seg -offset 0xF1110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0x000101110000 -range 0x00050000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_global_0]
  exclude_bd_addr_seg -offset 0xF1020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -offset 0x000101020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_gpio_0]
  exclude_bd_addr_seg -offset 0x000100280000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_iomodule_0]
  exclude_bd_addr_seg -offset 0xF0310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0x000100310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ppu1_mdm_0]
  exclude_bd_addr_seg -offset 0xF1030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0x000101030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_qspi_0]
  exclude_bd_addr_seg -offset 0xF2000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram]
  exclude_bd_addr_seg -offset 0x000102000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram]
  exclude_bd_addr_seg -offset 0x000100240000 -range 0x00020000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_data_cntlr]
  exclude_bd_addr_seg -offset 0x000100200000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_instr_cntlr]
  exclude_bd_addr_seg -offset 0xF6000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0x000106000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_ram_npi]
  exclude_bd_addr_seg -offset 0xF1200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0x000101200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rsa]
  exclude_bd_addr_seg -offset 0xF12A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0x0001012A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_rtc_0]
  exclude_bd_addr_seg -offset 0xF1050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sd_1]
  exclude_bd_addr_seg -offset 0x000101050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sd_1]
  exclude_bd_addr_seg -offset 0xF1210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0x000101210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sha]
  exclude_bd_addr_seg -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -offset 0x000101220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot]
  exclude_bd_addr_seg -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -offset 0x000102100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_slave_boot_stream]
  exclude_bd_addr_seg -offset 0xF1270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0x000101270000 -range 0x00030000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_sysmon_0]
  exclude_bd_addr_seg -offset 0x000100083000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_inject_0]
  exclude_bd_addr_seg -offset 0x000100283000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_tmr_manager_0]
  exclude_bd_addr_seg -offset 0xF1230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0x000101230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_trng]
  exclude_bd_addr_seg -offset 0xF12F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0x0001012F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xmpu_0]
  exclude_bd_addr_seg -offset 0xF1310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0x000101310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_0]
  exclude_bd_addr_seg -offset 0xF1300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0x000101300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_pmc_xppu_npi_0]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_psm_global_reg]
  exclude_bd_addr_seg -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_atcm_global]
  exclude_bd_addr_seg -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_1_btcm_global]
  exclude_bd_addr_seg -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_r5_tcm_ram_global]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_rpu_0]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_sbsauart_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntr_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_scntrs_0]
  exclude_bd_addr_seg -offset 0xFF0E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_0]
  exclude_bd_addr_seg -offset 0xFF0E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_0]
  exclude_bd_addr_seg -offset 0xFF0F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_1]
  exclude_bd_addr_seg -offset 0xFF0F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_1]
  exclude_bd_addr_seg -offset 0xFF100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_2]
  exclude_bd_addr_seg -offset 0xFF100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_2]
  exclude_bd_addr_seg -offset 0xFF110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_ttc_3]
  exclude_bd_addr_seg -offset 0xFF110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_ttc_3]
  exclude_bd_addr_seg -offset 0xFF9D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_usb_0]
  exclude_bd_addr_seg -offset 0xFF9D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_usb_0]
  exclude_bd_addr_seg -offset 0xFE200000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_usb_xhci_0]
  exclude_bd_addr_seg -offset 0xFE200000 -range 0x00100000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_usb_xhci_0]
  exclude_bd_addr_seg -offset 0xFF120000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_FPD_AXI_0/pspmc_0_psv_wwdt_0]
  exclude_bd_addr_seg -offset 0xFF120000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs versal_cips_0/NOC_PMC_AXI_0/pspmc_0_psv_wwdt_0]


  validate_bd_design
  save_bd_design





