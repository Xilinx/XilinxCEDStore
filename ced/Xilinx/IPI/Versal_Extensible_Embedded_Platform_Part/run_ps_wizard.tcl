proc create_root_design {currentDir design_name use_lpddr clk_options irqs use_aie} {

	puts "create_root_design"

	set fpga_part [get_property PART [current_project ]]

	puts "INFO: $fpga_part is selected"

	puts "INFO: selected design_name:: $design_name"
	puts "INFO: selected Interrupts:: $irqs"
	puts "INFO: selected Include_LPDDR:: $use_lpddr"
	puts "INFO: selected Clock_Options:: $clk_options"
	puts "INFO: selected Include_AIE:: $use_aie"
	
	puts "INFO: Using enhanced Versal extensible platform CED (part based)"

	set use_intc_15 [set use_intc_32 [set use_cascaded_irqs [set no_irqs ""]]]

	set use_intc_15 [ expr $irqs eq "15" ]
	set use_intc_32 [ expr $irqs eq "32" ]
	set use_cascaded_irqs [ expr $irqs eq "63" ]
	set no_irqs [ expr $irqs eq "0" ]

	# Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {100} \
	CONFIG.PS_PMC_CONFIG(PMC_QSPI_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 MODE Single} \
	CONFIG.PS_PMC_CONFIG(PMC_QSPI_PERIPHERAL_DATA_MODE) {x4} \
	CONFIG.PS_PMC_CONFIG(PMC_SD0_30_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 IO PMC_MIO_37:49 IO_TYPE MIO} \
	CONFIG.PS_PMC_CONFIG(PMC_SD1_20_PERIPHERAL) {PRIMARY_ENABLE 0 SECONDARY_ENABLE 0 IO PMC_MIO_0:11 IO_TYPE MIO} \
	CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
	CONFIG.PS_PMC_CONFIG(PS_ENET0_PERIPHERAL) {ENABLE 0 IO PMC_MIO_26:37 IO_TYPE MIO} \
	CONFIG.PS_PMC_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
	CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
	CONFIG.PS_PMC_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
	CONFIG.PS_PMC_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
	CONFIG.PS_PMC_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
	CONFIG.PS_PMC_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
	CONFIG.PS_PMC_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
	CONFIG.PS_PMC_CONFIG(PS_IRQ_USAGE) {CH0 1 CH1 0 CH2 0 CH3 0 CH4 0 CH5 0 CH6 0 CH7 0 CH8 0 CH9 0 CH10 0 CH11 0 CH12 0 CH13 0 CH14 0 CH15 0} \
	CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
	CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
	CONFIG.PS_PMC_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
	CONFIG.PS_PMC_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 0 IO PMC_MIO_0:1 IO_TYPE MIO} \
	CONFIG.PS_PMC_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 0 IO PMC_MIO_4:5 IO_TYPE MIO} \
	CONFIG.PS_PMC_CONFIG(PS_USB3_PERIPHERAL) {ENABLE 0 IO PMC_MIO_13:25 IO_TYPE MIO} \
	CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC0) {1} \
	CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC1) {1} \
	CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_PL) {1} \
	CONFIG.PS_PMC_CONFIG(PS_USE_FPD_CCI_NOC) {1} \
	CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {1} \
	CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
	CONFIG.PS_PMC_CONFIG(PS_USE_PSPL_IRQ_LPD) {0} \
  ] $ps_wizard_0
  
	if {$use_intc_15} {

		# Create instance: axi_intc_0, and set properties
		set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
		set_property -dict [ list CONFIG.C_ASYNC_INTR {0xFFFFFFFF} CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_0
			
	}


	if {$use_intc_32} {

		# Create instance: axi_intc_0, and set properties
		set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
		set_property -dict [ list CONFIG.C_ASYNC_INTR {0xFFFFFFFF} CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_0
	}

	if { $use_cascaded_irqs } {
		# Create instance: axi_intc_cascaded_1, and set properties
		set axi_intc_cascaded_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_cascaded_1 ]
		set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_cascaded_1
	  
		# Create instance: axi_intc_parent, and set properties
		set axi_intc_parent [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_parent ]
		set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_parent
		
		# Create instance: xlconcat_0, and set properties
		create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:* xlconcat_0
		set_property -dict [list CONFIG.NUM_PORTS {32} CONFIG.IN0_WIDTH {1}] [get_bd_cells xlconcat_0]
	}


	# Clocks options, and set properties

	set clk_freqs [ list 156.250000 104.166666 312.500000 100.000 100.000 100.000 100.000 ]
	set clk_used [list true false false false false false false ]
	set clk_ports [list clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 ]
	set default_clk_port clk_out1
	set default_clk_num 0

	set i 0
	set clocks {}

	foreach { port freq id is_default } $clk_options {

		lset clk_ports $i $port
		lset clk_freqs $i $freq
		lset clk_used $i true
		
		if { $is_default } {
			set default_clk_port $port
			set default_clk_num $i
		}
		
		dict append clocks clk_out$i { id $id is_default $is_default proc_sys_reset "proc_sys_reset$i" status "fixed" }
		incr i
		
	}

	set num_clks $i

	# Create instance: clk_wizard_0, and set properties
	set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clk_wizard_0 ]
	set_property -dict [list \
	CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
	CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
	CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
	CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
	CONFIG.CLKOUT_PORT [join $clk_ports ","] \
	CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
	CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [join $clk_freqs ","] \
	CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
	CONFIG.CLKOUT_USED [join $clk_used "," ]\
	CONFIG.JITTER_SEL {Min_O_Jitter} \
	CONFIG.PRIM_SOURCE {No_buffer} \
	CONFIG.RESET_TYPE {ACTIVE_LOW} \
	CONFIG.USE_LOCKED {true} \
	CONFIG.USE_PHASE_ALIGNMENT {true} \
	CONFIG.USE_RESET {true} \
	] $clk_wizard_0
	# set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_0 ]
	# set_property -dict [ list \
		# CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
		# CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
		# CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
		# CONFIG.CLKOUT_PORT [join $clk_ports ","] \
		# CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
		# CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [join $clk_freqs ","] \
		# CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
		# CONFIG.CLKOUT_USED [join $clk_used "," ]\
		# CONFIG.JITTER_SEL {Min_O_Jitter} \
		# CONFIG.RESET_TYPE {ACTIVE_LOW} \
		# CONFIG.USE_LOCKED {true} \
		# CONFIG.USE_PHASE_ALIGNMENT {true} \
		# CONFIG.USE_RESET {true} \
	# ] $clk_wizard_0
	 
	# Create instance: ps_wiz_noc2, and set properties
  set ps_wiz_noc2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 ps_wiz_noc2 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {9} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {1} \
    CONFIG.NUM_NSI {0} \
    CONFIG.NUM_SI {8} \
    CONFIG.SI_SIDEBAND_PINS {} \
  ] $ps_wiz_noc2


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /ps_wiz_noc2/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /ps_wiz_noc2/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /ps_wiz_noc2/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /ps_wiz_noc2/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /ps_wiz_noc2/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /ps_wiz_noc2/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /ps_wiz_noc2/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins /ps_wiz_noc2/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {} \
 ] [get_bd_pins /ps_wiz_noc2/aclk8]
 
	#L20
	# Create instance: noc2_ddr5, and set properties
  set noc2_ddr5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 noc2_ddr5 ]
  
  # DIMM is working for DIE parts in 2024.1_INT but not for prod in 2023.2.1 
  # set_property -dict [list \
    # CONFIG.DDR5_DEVICE_TYPE {DIMMs} \
    # CONFIG.DDRMC5_CONFIG {DDRMC5_CONTROLLERTYPE DDR5_SDRAM DDRMC5_SPEED_GRADE DDR5-5600AN(40-40-40) DDRMC5_DEVICE_TYPE UDIMMs DDRMC5_F0_LP5_BANK_ARCH NA DDRMC5_F1_LP5_BANK_ARCH NA DDRMC5_DRAM_WIDTH x8\
# DDRMC5_DATA_WIDTH 32 DDRMC5_ROW_ADDR_WIDTH 16 DDRMC5_COL_ADDR_WIDTH 10 DDRMC5_BA_ADDR_WIDTH 2 DDRMC5_BG_WIDTH 3 DDRMC5_BURST_ADDR_WIDTH 0 DDRMC5_NUM_RANKS 1 DDRMC5_LATENCY_MODE NA DDRMC5_NUM_SLOTS 1 DDRMC5_NUM_CK\
# 1 DDRMC5_NUM_CH 1 DDRMC5_STACK_HEIGHT 1 DDRMC5_DRAM_SIZE 16Gb DDRMC5_MEMORY_DENSITY 8GB DDRMC5_DM_EN true DDRMC5_DQS_OSCI_EN DISABLE DDRMC5_SIDE_BAND_ECC false DDRMC5_INLINE_ECC false DDRMC5_DDR5_2T DISABLE\
# DDRMC5_DDR5_RDIMM_ADDR_MODE DDR DDRMC5_REFRESH_MODE NORMAL DDRMC5_REFRESH_TYPE ALL_BANK DDRMC5_FREQ_SWITCHING false DDRMC5_BACKGROUND_SCRUB false DDRMC5_SCRUB_SIZE 1 DDRMC5_MEM_FILL false DDRMC5_PERIODIC_READ\
# ENABLE DDRMC5_USER_REFRESH false DDRMC5_WL_SET A DDRMC5_WR_DBI false DDRMC5_RD_DBI false DDRMC5_AUTO_PRECHARGE false DDRMC5_CRYPTO false DDRMC5_ON_DIE_ECC false DDRMC5_F0_TCK 357 DDRMC5_INPUTCLK0_PERIOD\
# 9996 DDRMC5_F0_TFAW 11428 DDRMC5_F0_DDR5_TRP 16428 DDRMC5_F0_TRTP 23 DDRMC5_F0_TRCD 16428 DDRMC5_TREFI 3900000 DDRMC5_DDR5_TRFC1 295000 DDRMC5_DDR5_TRFC2 160000 DDRMC5_DDR5_TRFCSB 130000 DDRMC5_F0_TRAS\
# 32000 DDRMC5_F0_TZQLAT 30000 DDRMC5_F0_DDR5_TCCD_L_WR 60 DDRMC5_F0_TXP 7500 DDRMC5_F0_DDR5_TPD 7500 DDRMC5_DDR5_TREFSBRD 30000 DDRMC5_DDR5_TRFC1_DLR 0 DDRMC5_DDR5_TRFC1_DPR 0 DDRMC5_DDR5_TRFC2_DLR 0 DDRMC5_DDR5_TRFC2_DPR\
# 0 DDRMC5_DDR5_TRFCSB_DLR 0 DDRMC5_DDR5_TREFSBRD_SLR 0 DDRMC5_DDR5_TREFSBRD_DLR 0 DDRMC5_F0_CL 46 DDRMC5_F0_CWL 44 DDRMC5_F0_DDR5_TRRD_L 15 DDRMC5_F0_TCCD_L 15 DDRMC5_F0_DDR5_TCCD_L_WR2 30 DDRMC5_DDR5_TFAW_DLR\
# 0 DDRMC5_F1_TCK 357 DDRMC5_F1_TFAW 11428 DDRMC5_F1_DDR5_TRP 16428 DDRMC5_F1_TRTP 23 DDRMC5_F1_TRCD 16428 DDRMC5_F1_TRAS 32000 DDRMC5_F1_TZQLAT 30000 DDRMC5_F1_DDR5_TCCD_L_WR 60 DDRMC5_F1_TXP 7500 DDRMC5_F1_DDR5_TPD\
# 7500 DDRMC5_F1_CL 46 DDRMC5_F1_CWL 44 DDRMC5_F1_DDR5_TRRD_L 15 DDRMC5_F1_TCCD_L 15 DDRMC5_F1_DDR5_TCCD_L_WR2 30 DDRMC5_LP5_TRFCAB 0 DDRMC5_LP5_TRFCPB 0 DDRMC5_LP5_TPBR2PBR 0 DDRMC5_F0_LP5_TRPAB 0 DDRMC5_F0_LP5_TRPPB\
# 0 DDRMC5_F0_LP5_TRRD 0 DDRMC5_LP5_TPBR2ACT 0 DDRMC5_F0_LP5_TCSPD 0 DDRMC5_F0_RL 0 DDRMC5_F0_WL 0 DDRMC5_F1_LP5_TRPAB 0 DDRMC5_F1_LP5_TRPPB 0 DDRMC5_F1_LP5_TRRD 0 DDRMC5_F1_LP5_TCSPD 0 DDRMC5_F1_RL 0 DDRMC5_F1_WL\
# 0 DDRMC5_LP5_TRFMAB 0 DDRMC5_LP5_TRFMPB 0 DDRMC5_SYSTEM_CLOCK Differential DDRMC5_UBLAZE_BLI_INTF false DDRMC5_REF_AND_PER_CAL_INTF false DDRMC5_PRE_DEF_ADDR_MAP_SEL ROW_BANK_COLUMN DDRMC5_USER_DEFINED_ADDRESS_MAP\
# None DDRMC5_ADDRESS_MAP NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG2,BG1,BG0,CA9,CA8,CA7,CA6,CA5,NC,CA4,NC,NC,NC,NC,NA,NA DDRMC5_MC0_CONFIG_SEL config4\
# DDRMC5_LOW_TRFC_DPR false DDRMC5_NUM_MC 2 DDRMC5_NUM_MCP 1 DDRMC5_MAIN_DEVICE_TYPE DIMMs DDRMC5_INTERLEAVE_SIZE 128 } \
    # CONFIG.NUM_MI {0} \
    # CONFIG.NUM_NSI {1} \
    # CONFIG.NUM_SI {0} \
  # ] $noc2_ddr5
  # set_property -dict [ list \
   # CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 # ] [get_bd_intf_pins /noc2_ddr5/S00_INI]
 
 # Modified for 2023.2.1
set_property -dict [list \
  CONFIG.DDR5_DEVICE_TYPE {Components} \
  CONFIG.DDRMC5_CONFIG {DDRMC5_CONTROLLERTYPE LPDDR5_SDRAM DDRMC5_SPEED_GRADE LPDDR5-6400 DDRMC5_DEVICE_TYPE Components DDRMC5_F0_LP5_BANK_ARCH BG DDRMC5_F1_LP5_BANK_ARCH BG DDRMC5_DRAM_WIDTH x16 DDRMC5_DATA_WIDTH 16 DDRMC5_ROW_ADDR_WIDTH 15 DDRMC5_COL_ADDR_WIDTH 6 DDRMC5_BA_ADDR_WIDTH 2 DDRMC5_BG_WIDTH 2 DDRMC5_BURST_ADDR_WIDTH 4 DDRMC5_NUM_RANKS 1 DDRMC5_LATENCY_MODE x16 DDRMC5_NUM_SLOTS 1 DDRMC5_NUM_CK 1 DDRMC5_NUM_CH 2 DDRMC5_STACK_HEIGHT 1 DDRMC5_DRAM_SIZE 8Gb DDRMC5_MEMORY_DENSITY 1GB DDRMC5_DM_EN true DDRMC5_DQS_OSCI_EN DISABLE DDRMC5_SIDE_BAND_ECC false DDRMC5_INLINE_ECC false DDRMC5_DDR5_2T DISABLE DDRMC5_DDR5_RDIMM_ADDR_MODE DDR DDRMC5_REFRESH_MODE NORMAL DDRMC5_REFRESH_TYPE ALL_BANK DDRMC5_FREQ_SWITCHING false DDRMC5_BACKGROUND_SCRUB false DDRMC5_SCRUB_SIZE 1 DDRMC5_MEM_FILL false DDRMC5_PERIODIC_READ ENABLE DDRMC5_USER_REFRESH false DDRMC5_WL_SET A DDRMC5_WR_DBI false DDRMC5_RD_DBI false DDRMC5_AUTO_PRECHARGE true DDRMC5_CRYPTO false DDRMC5_ON_DIE_ECC false DDRMC5_F0_TCK 1250 DDRMC5_INPUTCLK0_PERIOD 10000 DDRMC5_F0_TFAW 20000 DDRMC5_F0_DDR5_TRP 18000 DDRMC5_F0_TRTP 7500 DDRMC5_F0_TRCD 18000 DDRMC5_TREFI 3906000 DDRMC5_DDR5_TRFC1 295000 DDRMC5_DDR5_TRFC2 160000 DDRMC5_DDR5_TRFCSB 130000 DDRMC5_F0_TRAS 42000 DDRMC5_F0_TZQLAT 30000 DDRMC5_F0_DDR5_TCCD_L_WR 0 DDRMC5_F0_TXP 7000 DDRMC5_F0_DDR5_TPD 0 DDRMC5_DDR5_TREFSBRD 0 DDRMC5_DDR5_TRFC1_DLR 0 DDRMC5_DDR5_TRFC1_DPR 0 DDRMC5_DDR5_TRFC2_DLR 0 DDRMC5_DDR5_TRFC2_DPR 0 DDRMC5_DDR5_TRFCSB_DLR 0 DDRMC5_DDR5_TREFSBRD_SLR 0 DDRMC5_DDR5_TREFSBRD_DLR 0 DDRMC5_F0_CL 46 DDRMC5_F0_CWL 0 DDRMC5_F0_DDR5_TRRD_L 0 DDRMC5_F0_TCCD_L 4 DDRMC5_F0_DDR5_TCCD_L_WR2 0 DDRMC5_DDR5_TFAW_DLR 0 DDRMC5_F1_TCK 1250 DDRMC5_F1_TFAW 20000 DDRMC5_F1_DDR5_TRP 18000 DDRMC5_F1_TRTP 7500 DDRMC5_F1_TRCD 18000 DDRMC5_F1_TRAS 42000 DDRMC5_F1_TZQLAT 30000 DDRMC5_F1_DDR5_TCCD_L_WR 0 DDRMC5_F1_TXP 7000 DDRMC5_F1_DDR5_TPD 0 DDRMC5_F1_CL 46 DDRMC5_F1_CWL 0 DDRMC5_F1_DDR5_TRRD_L 0 DDRMC5_F1_TCCD_L 4 DDRMC5_F1_DDR5_TCCD_L_WR2 0 DDRMC5_LP5_TRFCAB 210000 DDRMC5_LP5_TRFCPB 120000 DDRMC5_LP5_TPBR2PBR 90000 DDRMC5_F0_LP5_TRPAB 21000 DDRMC5_F0_LP5_TRPPB 18000 DDRMC5_F0_LP5_TRRD 5000 DDRMC5_LP5_TPBR2ACT 7500 DDRMC5_F0_LP5_TCSPD 11250 DDRMC5_F0_RL 17 DDRMC5_F0_WL 9 DDRMC5_F1_LP5_TRPAB 21000 DDRMC5_F1_LP5_TRPPB 18000 DDRMC5_F1_LP5_TRRD 5000 DDRMC5_F1_LP5_TCSPD 11250 DDRMC5_F1_RL 17 DDRMC5_F1_WL 9 DDRMC5_LP5_TRFMAB 210000 DDRMC5_LP5_TRFMPB 170000 DDRMC5_SYSTEM_CLOCK Differential DDRMC5_UBLAZE_BLI_INTF false DDRMC5_REF_AND_PER_CAL_INTF false DDRMC5_PRE_DEF_ADDR_MAP_SEL ROW_BANK_COLUMN DDRMC5_USER_DEFINED_ADDRESS_MAP None DDRMC5_ADDRESS_MAP NA,NA,NA,NA,NA,NA,NA,NA,NA,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,NC,CA1,CA0,NC,NC,NC,NC,NA DDRMC5_MC0_CONFIG_SEL config9 DDRMC5_LOW_TRFC_DPR false DDRMC5_NUM_MC 1 DDRMC5_NUM_MCP 1 DDRMC5_MAIN_DEVICE_TYPE Components DDRMC5_INTERLEAVE_SIZE 128 } \
  CONFIG.NUM_MI {0} \
  CONFIG.NUM_NSI {1} \
  CONFIG.NUM_SI {0} \
] $noc2_ddr5
#make_bd_intf_pins_external  [get_bd_intf_pins noc2_ddr5/sys_clk0] [get_bd_intf_pins noc2_ddr5/C0_DDR5]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /noc2_ddr5/S00_INI]
make_bd_intf_pins_external  [get_bd_intf_pins noc2_ddr5/sys_clk0] [get_bd_intf_pins noc2_ddr5/C0_CH0_LPDDR5] [get_bd_intf_pins noc2_ddr5/C0_CH1_LPDDR5]

connect_bd_intf_net [get_bd_intf_pins ps_wiz_noc2/M00_INI] [get_bd_intf_pins noc2_ddr5/S00_INI]
	
	connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S04_AXI]
	connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins ps_wiz_noc2/S05_AXI]
	connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S00_AXI] 
	connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC1] [get_bd_intf_pins ps_wiz_noc2/S01_AXI]
	connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC2 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC2] [get_bd_intf_pins ps_wiz_noc2/S02_AXI]
	connect_bd_intf_net -intf_net ps_wizard_0_FPD_CCI_NOC3 [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC3] [get_bd_intf_pins ps_wiz_noc2/S03_AXI]
	connect_bd_intf_net -intf_net ps_wizard_0_LPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S06_AXI]
	connect_bd_intf_net -intf_net ps_wizard_0_PMC_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S07_AXI]
	# Create port connections
	connect_bd_net -net ps_wizard_0_fpd_cci_noc0_clk [get_bd_pins ps_wizard_0/fpd_cci_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk1]
	connect_bd_net -net ps_wizard_0_fpd_cci_noc1_clk [get_bd_pins ps_wizard_0/fpd_cci_noc1_clk] [get_bd_pins ps_wiz_noc2/aclk2]
	connect_bd_net -net ps_wizard_0_fpd_cci_noc2_clk [get_bd_pins ps_wizard_0/fpd_cci_noc2_clk] [get_bd_pins ps_wiz_noc2/aclk3]
	connect_bd_net -net ps_wizard_0_fpd_cci_noc3_clk [get_bd_pins ps_wizard_0/fpd_cci_noc3_clk] [get_bd_pins ps_wiz_noc2/aclk4]
	connect_bd_net -net ps_wizard_0_fpd_axi_noc0_clk [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk5]
	connect_bd_net -net ps_wizard_0_fpd_axi_noc1_clk [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] [get_bd_pins ps_wiz_noc2/aclk6]
	connect_bd_net -net ps_wizard_0_lpd_axi_noc0_clk [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk7]
	connect_bd_net -net ps_wizard_0_pmc_axi_noc0_clk [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk8]
  

	# Create instance: proc_sys_reset_N, and set properties
	for {set i 0} {$i < $num_clks} {incr i} {
		set proc_sys_reset_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_$i ]
	}

	connect_bd_net -net ps_wizard_0_pl_clk0 [get_bd_pins ps_wizard_0/pl0_ref_clk] [get_bd_pins clk_wizard_0/clk_in1]
	connect_bd_net -net ps_wizard_0_pl_resetn1 [get_bd_pins ps_wizard_0/pl0_resetn] [get_bd_pins clk_wizard_0/resetn]

	for {set i 0} {$i < $num_clks} {incr i} {
		connect_bd_net -net ps_wizard_0_pl_resetn1 [get_bd_pins proc_sys_reset_$i/ext_reset_in]
	}
	   
	# Create instance: icn_ctrl, and set properties
	set icn_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl ]
	 
	set default_clock_net clk_wizard_0_$default_clk_port
	connect_bd_net -net $default_clock_net [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] [get_bd_pins ps_wiz_noc2/aclk0] [get_bd_pins icn_ctrl/aclk] 
	 
	
	# Create instance: icn_ctrl, and set properties
	
	if {!$no_irqs} {
		  
		if { $use_intc_15 } {
		
			# Using only 1 smartconnect to accomodate 15 AXI_Masters 

			set num_masters 1
							
			set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI $num_masters CONFIG.NUM_SI {1} ] $icn_ctrl
			

		} else {
		
			# Adding multiple Smartconnects and dummy AXI_VIP to accomodate 32 or 63 AXI_Masters selected
		
			set num_masters [ expr "$use_cascaded_irqs ? 6 : 3" ]
			set num_kernal [ expr "$use_cascaded_irqs ? 4 : 2" ]
			set m_incr [ expr "$use_cascaded_irqs ? 2 : 1" ]

			set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI $num_masters CONFIG.NUM_SI {1} ] $icn_ctrl 
		  
			for {set i 0} {$i < $num_kernal} {incr i} {
				set to_delete_kernel_ctrl_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel_ctrl_$i ]
				set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] [get_bd_cells to_delete_kernel_ctrl_$i]
				set icn_ctrl_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_$i ]
				set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} ] [get_bd_cells icn_ctrl_$i]
				set m [expr $i+$m_incr]
				connect_bd_intf_net [get_bd_intf_pins icn_ctrl/M0${m}_AXI] [get_bd_intf_pins icn_ctrl_$i/S00_AXI]
				connect_bd_intf_net [get_bd_intf_pins to_delete_kernel_ctrl_$i/S_AXI] [get_bd_intf_pins icn_ctrl_$i/M00_AXI]
				connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins to_delete_kernel_ctrl_$i/aresetn]
				connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins icn_ctrl_$i/aresetn]
				connect_bd_net -net $default_clock_net [get_bd_pins icn_ctrl_$i/aclk]
				connect_bd_net -net $default_clock_net [get_bd_pins to_delete_kernel_ctrl_$i/aclk]
			} 
		}
	}

	if {$no_irqs} {
		
		set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells icn_ctrl]
		set_property -dict [list CONFIG.PS_PMC_CONFIG { PS_IRQ_USAGE {{CH0 0} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}}}] [get_bd_cells ps_wizard_0]

		set to_delete_kernel [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel ]
		set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] $to_delete_kernel

		connect_bd_intf_net [get_bd_intf_pins icn_ctrl/M00_AXI] [get_bd_intf_pins to_delete_kernel/S_AXI]
		connect_bd_net -net $default_clock_net [get_bd_pins to_delete_kernel/aclk] 
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins to_delete_kernel/aresetn] 
		
	}
		
	connect_bd_intf_net -intf_net ps_wizard_0_M_AXI_GP0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL] [get_bd_intf_pins icn_ctrl/S00_AXI]

	for {set i 0} {$i < $num_clks} {incr i} {
		set port [lindex $clk_ports $i]
		connect_bd_net -net clk_wizard_0_$port [get_bd_pins clk_wizard_0/$port] [get_bd_pins proc_sys_reset_$i/slowest_sync_clk]
	}

	connect_bd_net -net clk_wizard_0_locked [get_bd_pins clk_wizard_0/locked]

	for {set i 0} {$i < $num_clks} {incr i} {
		connect_bd_net -net clk_wizard_0_locked [get_bd_pins proc_sys_reset_$i/dcm_locked] 
	}

	connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins proc_sys_reset_${default_clk_num}/peripheral_aresetn] [get_bd_pins icn_ctrl/aresetn] 
	  

	if { $use_intc_15 } {
		set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells icn_ctrl]
		connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins icn_ctrl/M00_AXI]
		connect_bd_net -net axi_intc_0_irq [get_bd_pins ps_wizard_0/pl_ps_irq0] [get_bd_pins axi_intc_0/irq]
		connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_0/s_axi_aclk]
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn]
	}
	  
	  
	if { $use_intc_32 } {
		set_property -dict [list CONFIG.NUM_MI {3}] [get_bd_cells icn_ctrl]
		connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins icn_ctrl/M00_AXI]
		connect_bd_net -net axi_intc_0_irq [get_bd_pins ps_wizard_0/pl_ps_irq0] [get_bd_pins axi_intc_0/irq]
		connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_0/s_axi_aclk]
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn]
	}
	  
	if { $use_cascaded_irqs } {
		connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_cascaded_1/s_axi] [get_bd_intf_pins icn_ctrl/M00_AXI]
		connect_bd_intf_net -intf_net icn_ctrl_M01_AXI [get_bd_intf_pins axi_intc_parent/s_axi] [get_bd_intf_pins icn_ctrl/M01_AXI]
		connect_bd_net [get_bd_pins axi_intc_cascaded_1/irq] [get_bd_pins xlconcat_0/In31]
		connect_bd_net [get_bd_pins axi_intc_parent/intr] [get_bd_pins xlconcat_0/dout]
		#connect_bd_net [get_bd_pins axi_intc_cascaded_1/intr] [get_bd_pins xlconcat_1/dout]
		connect_bd_net -net axi_intc_0_irq [get_bd_pins ps_wizard_0/pl_ps_irq0] [get_bd_pins axi_intc_parent/irq]
		connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_cascaded_1/s_axi_aclk]
		connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_parent/s_axi_aclk]
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_cascaded_1/s_axi_aresetn]
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_parent/s_axi_aresetn]
	}


	if { $use_aie } {

		set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_CLKS {10}] [get_bd_cells ps_wiz_noc2]
		set_property -dict [list CONFIG.CATEGORY {aie}] [get_bd_intf_pins /ps_wiz_noc2/M00_AXI]
		set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
		set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
		set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
		set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
		set_property -dict [list CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
		set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
		set_property -dict [list CONFIG.ASSOCIATED_BUSIF {M00_AXI}] [get_bd_pins /ps_wiz_noc2/aclk9]

		# Create instance: ai_engine_0, and set properties
		 set ai_engine_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ai_engine:* ai_engine_0 ]
		 set_property -dict [ list \
		  CONFIG.CLK_NAMES {} \
		  CONFIG.NAME_MI_AXI {} \
		  CONFIG.NAME_MI_AXIS {} \
		  CONFIG.NAME_SI_AXI {S00_AXI,} \
		  CONFIG.NAME_SI_AXIS {} \
		  CONFIG.NUM_CLKS {0} \
		  CONFIG.NUM_MI_AXI {0} \
		  CONFIG.NUM_MI_AXIS {0} \
		  CONFIG.NUM_SI_AXI {1} \
		  CONFIG.NUM_SI_AXIS {0} \
		] $ai_engine_0
		
		set_property -dict [ list CONFIG.CATEGORY {NOC} ] [get_bd_intf_pins /ai_engine_0/S00_AXI]
	  
		connect_bd_intf_net [get_bd_intf_pins ps_wiz_noc2/M00_AXI] [get_bd_intf_pins ai_engine_0/S00_AXI]
		connect_bd_net [get_bd_pins ai_engine_0/s00_axi_aclk] [get_bd_pins ps_wiz_noc2/aclk9] 

		assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/PMC_NOC_AXI_0] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
		assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_0] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
		assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_3] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
		assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_1] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
		assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_2] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
	}



	if { $use_lpddr } {

		puts "INFO: lpddr5 selected"
		
		if {$use_aie } {
			set_property -dict [list CONFIG.NUM_NMI {2}] [get_bd_cells ps_wiz_noc2]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
			set_property -dict [list CONFIG.ASSOCIATED_BUSIF {}] [get_bd_pins /ps_wiz_noc2/aclk9]
		} else {
			set_property -dict [list CONFIG.NUM_NMI {2}] [get_bd_cells ps_wiz_noc2]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
		}

		# create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* noc_lpddr4
		
		# set_property -dict [list CONFIG.NUM_SI {0} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {1} CONFIG.NUM_CLKS {0} CONFIG.NUM_MC {1} CONFIG.NUM_MCP {1} CONFIG.CONTROLLERTYPE {LPDDR4_SDRAM} CONFIG.MC_CHAN_REGION0 {DDR_CH1} CONFIG.MC_NO_CHANNELS {Dual} ] [get_bd_cells noc_lpddr4]
		# set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /noc_lpddr4/S00_INI]

		# # make_bd_intf_pins_external  [get_bd_intf_pins noc_lpddr4/CH1_LPDDR4_1] [get_bd_intf_pins noc_lpddr4/CH0_LPDDR4_0] [get_bd_intf_pins noc_lpddr4/CH0_LPDDR4_1] [get_bd_intf_pins noc_lpddr4/sys_clk0] [get_bd_intf_pins noc_lpddr4/CH1_LPDDR4_0] [get_bd_intf_pins noc_lpddr4/sys_clk1]

		# make_bd_intf_pins_external  [get_bd_intf_pins noc_lpddr4/CH0_LPDDR4_0] [get_bd_intf_pins noc_lpddr4/sys_clk0] [get_bd_intf_pins noc_lpddr4/CH1_LPDDR4_0]

		# # set_property -dict [list CONFIG.NUM_SI {0} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {1} CONFIG.NUM_CLKS {0} CONFIG.MC_CHAN_REGION0 {DDR_CH1}] [get_bd_cells noc_lpddr4]
		# # set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /noc_lpddr4/S00_INI]

		# connect_bd_intf_net [get_bd_intf_pins ps_wiz_noc2/M01_INI] [get_bd_intf_pins noc_lpddr4/S00_INI] 
		
		#L20
		# Create instance: noc2_lpddr5, and set properties
  set noc2_lpddr5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 noc2_lpddr5 ]
  set_property -dict [list \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NSI {1} \
    CONFIG.NUM_SI {0} \
  ] $noc2_lpddr5

connect_bd_intf_net [get_bd_intf_pins ps_wiz_noc2/M01_INI] [get_bd_intf_pins noc2_lpddr5/S00_INI]
make_bd_intf_pins_external  [get_bd_intf_pins noc2_lpddr5/C0_CH0_LPDDR5] [get_bd_intf_pins noc2_lpddr5/C0_CH1_LPDDR5] [get_bd_intf_pins noc2_lpddr5/sys_clk0]


  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
 ] [get_bd_intf_pins /noc2_lpddr5/S00_INI]

		# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
		# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/LPD_AXI_NOC_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
		# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_NOC_1] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
		# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_NOC_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
		# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_3] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
		# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_2] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
		# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_1] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force
		# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1x2] -force

		#assign_bd_address -offset 0x050000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1] -force
		#assign_bd_address -offset 0x050000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/LPD_AXI_NOC_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1] -force
		#assign_bd_address -offset 0x050000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_NOC_1] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1] -force
		#assign_bd_address -offset 0x050000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_NOC_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1] -force
		#assign_bd_address -offset 0x050000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_3] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1] -force
		#assign_bd_address -offset 0x050000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_2] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1] -force
		#assign_bd_address -offset 0x050000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_1] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1] -force
		#assign_bd_address -offset 0x050000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc_lpddr4/S00_INI/C0_DDR_CH1] -force

	}

	# if { $use_intc_15 } {
		# #assign_bd_address -target_address_space /ps_wizard_0/FPD_AXI_PL [get_bd_addr_segs axi_intc_0/S_AXI/Reg] -force
		# assign_bd_address -offset 0xA4000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_PL] [get_bd_addr_segs axi_intc_0/S_AXI/Reg] 
	# }


	# if { $use_intc_32 } {
		# #assign_bd_address -target_address_space /ps_wizard_0/FPD_AXI_PL [get_bd_addr_segs axi_intc_0/S_AXI/Reg] -force
		# assign_bd_address -offset 0xA4000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_PL] [get_bd_addr_segs axi_intc_0/S_AXI/Reg] 
	# }


	# if { $use_cascaded_irqs } {
		# assign_bd_address -offset 0xA4000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_PL] [get_bd_addr_segs axi_intc_cascaded_1/S_AXI/Reg] -force 
		# assign_bd_address -offset 0xA5000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_PL] [get_bd_addr_segs axi_intc_parent/S_AXI/Reg] -force 
	# }

	#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/LPD_AXI_NOC_0] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW0] -force
	#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_NOC_1] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW0] -force
	#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_NOC_0] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW0] -force
	#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_3] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW0] -force
	#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_2] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW0] -force
	#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_1] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW0] -force
	#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW0] -force
	#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW0] -force
	#
	#assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_1] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW1] -force
	#assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_2] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW1] -force
	#assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/LPD_AXI_NOC_0] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW1] -force
	#assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_3] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW1] -force
	#assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW1] -force
	#assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_NOC_0] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW1] -force
	#assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW1] -force
	#assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/FPD_AXI_NOC_1] [get_bd_addr_segs noc2_ddr5/S00_INI/C0_DDR_LOW1] -force

	set_param project.replaceDontTouchWithKeepHierarchySoft 0
	assign_bd_address
	catch {
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexa72_0/SEG_to_delete_kernel_ctrl_0_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexa72_0/SEG_to_delete_kernel_ctrl_1_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexa72_0/SEG_to_delete_kernel_ctrl_2_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexa72_0/SEG_to_delete_kernel_ctrl_3_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexa72_1/SEG_to_delete_kernel_ctrl_0_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexa72_1/SEG_to_delete_kernel_ctrl_1_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexa72_1/SEG_to_delete_kernel_ctrl_2_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexa72_1/SEG_to_delete_kernel_ctrl_3_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_0/SEG_to_delete_kernel_ctrl_0_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_0/SEG_to_delete_kernel_ctrl_1_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_0/SEG_to_delete_kernel_ctrl_2_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_0/SEG_to_delete_kernel_ctrl_3_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_1/SEG_to_delete_kernel_ctrl_0_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_1/SEG_to_delete_kernel_ctrl_1_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_1/SEG_to_delete_kernel_ctrl_2_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_cortexr5_1/SEG_to_delete_kernel_ctrl_3_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_pmc_0/SEG_to_delete_kernel_ctrl_0_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_pmc_0/SEG_to_delete_kernel_ctrl_1_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_pmc_0/SEG_to_delete_kernel_ctrl_2_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_pmc_0/SEG_to_delete_kernel_ctrl_3_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_psm_0/SEG_to_delete_kernel_ctrl_0_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_psm_0/SEG_to_delete_kernel_ctrl_1_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_psm_0/SEG_to_delete_kernel_ctrl_2_Reg]
		exclude_bd_addr_seg [get_bd_addr_segs ps_wizard_0/pmcps_0_psv_psm_0/SEG_to_delete_kernel_ctrl_3_Reg]
	}
	
	
	if { ! $use_intc_15 } {
		group_bd_cells axi_smc_vip_hier [get_bd_cells to_delete_kernel_ctrl_*] [get_bd_cells icn_ctrl] [get_bd_cells icn_ctrl_*]  
	}

}


##################################################################
# MAIN FLOW
##################################################################

# puts "INFO: design_name:: $design_name and options:: $options is selected from GUI"
# get the clock options

set clk_options_param "Clock_Options.VALUE"
# set clk_options { clk_out1 200.000 0 true clk_out2 100.000 1 false clk_out3 300.000 2 false }
set clk_options { clk_out1 156.250000 0 true }
if { [dict exists $options $clk_options_param] } {
	set clk_options [ dict get $options $clk_options_param ]
}

# By default all available memory will be used. Here user choice is disabled
# Versal Prime Series ES1 : xcvm1102-sfva784* & Versal AI Edge Series ES1 : xcve2302-sfva784* parts do not support both LPDDR4 and DDR4 as the available MRMAC on the device is 1.
# Filterig unsupported parts for lpddr4

set fpga_part_prop [debug::dump_part_properties [get_property PART [current_project ]]]

set ddrmc_flag 1
set io_flag 1

foreach ddrmc_prop $fpga_part_prop {

	if {([regexp "DDRMC5C" [lindex $ddrmc_prop 1 ]] == 1) && ([lindex $ddrmc_prop 3 ] < 2) } {
		set ddrmc_flag 0
	} elseif {$ddrmc_flag == 1} {
		set ddrmc_flag 1
	}
}


foreach io_prop $fpga_part_prop {
	if {([regexp "Io" [lindex $io_prop 1 ]] == 1) && ([lindex $io_prop 3 ] < 324)} {
		set io_flag 0
	} elseif {$io_flag == 1} {
		set io_flag 1
	}
}

if {( $ddrmc_flag == 0 ) || ($io_flag == 0) } {
	set use_lpddr 0
} else {
	set use_lpddr 1
}
#Force disable NOC2 lpddr5 instantiation as already noc2_ddr5 configured as lpddr5 in 2023.2.1
set use_lpddr 0

set aie "Include_AIE.VALUE"
set use_aie 0
if { [dict exists $options $aie] } {
	set use_aie [dict get $options $aie ] 
}
puts "INFO: selected use_aie:: $use_aie"

# 0 (no interrupts) / 15 (interrupt controller : default) / 32 (interrupt controller) / 63 (interrupt controller + cascade block)

set irqs_param "IRQS.VALUE"
set irqs 15
if { [dict exists $options $irqs_param] } {
	set irqs [dict get $options $irqs_param ]
}


create_root_design $currentDir $design_name $use_lpddr $clk_options $irqs $use_aie

open_bd_design [get_bd_files $design_name]

puts "INFO: Block design generation completed, yet to set PFM properties"

set fpga_part [get_property PART [current_project ]]
set part1 [split $fpga_part "-"]
set part [lindex $part1 0]


puts "INFO: Creating extensible_platform for part:: $fpga_part"
set  pfmName "xilinx.com:${fpga_part}:extensible_platform_base:1.0"
set_property PFM_NAME  $pfmName [get_files ${design_name}.bd]


#set_property PFM.AXI_PORT {M00_AXI {memport "NOC_MASTER"}} [get_bd_cells /ps_wiz_noc2]

if { $irqs eq "15" } {
	set_property PFM.IRQ {intr {id 0 range 15}}  [get_bd_cells /axi_intc_0]
	
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells /icn_ctrl]
}

if { $irqs eq "32" } {
	# set_property PFM.IRQ {intr {id 0 range 31}}  [get_bd_cells /xlconcat_0]
	set_property PFM.IRQ {intr {id 0 range 31}}  [get_bd_cells /axi_intc_0]
	# set_property PFM.IRQ {In0 {id 0} In1 {id 1} In2 {id 2} In3 {id 3} In4 {id 4} In5 {id 5} In6 {id 6} In7 {id 7} In8 {id 8} In9 {id 9} In10 {id 10} \
	In11 {id 11} In12 {id 12} In13 {id 13} In14 {id 14} In15 {id 15} In16 {id 16} In17 {id 17} In18 {id 18} In19 {id 19} In20 {id 20} In21 {id 21} In22 {id 22} \
	In23 {id 23} In24 {id 24} In25 {id 25} In26 {id 26} In27 {id 27} In28 {id 28} In29 {id 29} In30 {id 30} In31 {id 31}} [get_bd_cells /xlconcat_0]

	set_property PFM.AXI_PORT {M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} } [get_bd_cells axi_smc_vip_hier/icn_ctrl]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_0]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_1]
}

if { $irqs eq "63" } {

	set_property PFM.IRQ {intr {id 0 range 32}}  [get_bd_cells /axi_intc_cascaded_1]
	#set_property PFM.IRQ {In0 {id 0} In1 {id 1} In2 {id 2} In3 {id 3} In4 {id 4} In5 {id 5} In6 {id 6} In7 {id 7} In8 {id 8} In9 {id 9} In10 {id 10} \
	In11 {id 11} In12 {id 12} In13 {id 13} In14 {id 14} In15 {id 15} In16 {id 16} In17 {id 17} In18 {id 18} In19 {id 19} In20 {id 20} In21 {id 21} In22 {id 22} \
	In23 {id 23} In24 {id 24} In25 {id 25} In26 {id 26} In27 {id 27} In28 {id 28} In29 {id 29} In30 {id 30} } [get_bd_cells /xlconcat_0]
	
	#set_property PFM.IRQ {intr {id 32 range 63}}  [get_bd_cells /xlconcat_1]
	set_property PFM.IRQ {In0 {id 32} In1 {id 33} In2 {id 34} In3 {id 35} In4 {id 36} In5 {id 37} In6 {id 38} In7 {id 39} In8 {id 40} \
	In9 {id 41} In10 {id 42} In11 {id 43} In12 {id 44} In13 {id 45} In14 {id 46} In15 {id 47} In16 {id 48} In17 {id 49} In18 {id 50} \
	In19 {id 51} In20 {id 52} In21 {id 53} In22 {id 54} In23 {id 55} In24 {id 56} In25 {id 57} In26 {id 58} In27 {id 59} In28 {id 60} \
	In29 {id 61} In30 {id 62} } [get_bd_cells /xlconcat_0]
	
	set_property PFM.AXI_PORT {M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_0]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_1]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_2]
	set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_3]
	
}

set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "DDR"} S01_AXI {memport "S_AXI_NOC" sptag "DDR"} S02_AXI {memport "S_AXI_NOC" sptag "DDR"} S03_AXI {memport "S_AXI_NOC" sptag "DDR"} S04_AXI {memport "S_AXI_NOC" sptag "DDR"} S05_AXI {memport "S_AXI_NOC" sptag "DDR"} S06_AXI {memport "S_AXI_NOC" sptag "DDR"} S07_AXI {memport "S_AXI_NOC" sptag "DDR"} S08_AXI {memport "S_AXI_NOC" sptag "DDR"} S09_AXI {memport "S_AXI_NOC" sptag "DDR"} S10_AXI {memport "S_AXI_NOC" sptag "DDR"} S11_AXI {memport "S_AXI_NOC" sptag "DDR"} S12_AXI {memport "S_AXI_NOC" sptag "DDR"} S13_AXI {memport "S_AXI_NOC" sptag "DDR"} S14_AXI {memport "S_AXI_NOC" sptag "DDR"} S15_AXI {memport "S_AXI_NOC" sptag "DDR"} S16_AXI {memport "S_AXI_NOC" sptag "DDR"} S17_AXI {memport "S_AXI_NOC" sptag "DDR"} S18_AXI {memport "S_AXI_NOC" sptag "DDR"} S19_AXI {memport "S_AXI_NOC" sptag "DDR"} S20_AXI {memport "S_AXI_NOC" sptag "DDR"} S21_AXI {memport "S_AXI_NOC" sptag "DDR"} S22_AXI {memport "S_AXI_NOC" sptag "DDR"} S23_AXI {memport "S_AXI_NOC" sptag "DDR"} S24_AXI {memport "S_AXI_NOC" sptag "DDR"} S25_AXI {memport "S_AXI_NOC" sptag "DDR"} S26_AXI {memport "S_AXI_NOC" sptag "DDR"} S27_AXI {memport "S_AXI_NOC" sptag "DDR"}} [get_bd_cells /noc2_ddr5]

set clocks {}

set i 0

foreach { port freq id is_default } $clk_options {
	dict append clocks $port "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed\""
	incr i
}

set_property PFM.CLOCK $clocks [get_bd_cells /clk_wizard_0]
#puts "clocks :: $clocks  PFM properties"

catch { set lpddr [get_bd_cells /noc2_lpddr5] }

if { $use_lpddr } {
	puts "INFO: lpddr5 selected"
	set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S01_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S02_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S03_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S04_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S05_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S06_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S07_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S08_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S09_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S10_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S11_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S12_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S13_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S14_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S15_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S16_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S17_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S18_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S19_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S20_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S21_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S22_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S23_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S24_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S25_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S26_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S27_AXI {memport "S_AXI_NOC" sptag "LPDDR"}} [get_bd_cells /noc2_lpddr5]
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells /noc2_lpddr5]
}

#Platform Level Properties
set_property platform.default_output_type "sd_card" [current_project]
set_property platform.design_intent.embedded "true" [current_project]
set_property platform.num_compute_units $irqs [current_project]
set_property platform.design_intent.server_managed "false" [current_project]
set_property platform.design_intent.external_host "false" [current_project]
set_property platform.design_intent.datacenter "false" [current_project]
set_property platform.uses_pr  "false" [current_project]
set_property platform.extensible true [current_project]

puts "INFO: Platform creation completed!"

set_property platform.extensible true [current_project]

# Add USER_COMMENTS on $design_name
#set_property USER_COMMENTS.comment0 "An Example Versal Extensible Embedded Platform" [get_bd_designs $design_name]

if { $use_aie eq "true" } {
	
	set_property USER_COMMENTS.comment0 {\t \t \t =============== >>>> An Example Versal Extensible Embedded Platform <<<< ===============
	\t Note: 
	\t --> SD boot mode and UART are enabled in the CIPS
	\t --> AI Engine control path is connected to CIPS
	\t --> V++ will connect AI Engine data path automatically
	\t --> Execute TCL command: launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation} [current_bd_design]

} else {
	
	set_property USER_COMMENTS.comment0 {\t \t \t =============== >>>> An Example Versal Extensible Embedded Platform <<<< ===============
	\t Note: 
	\t --> SD boot mode and UART are enabled in the CIPS
	\t --> Execute TCL command: launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation} [current_bd_design]
}

# Perform GUI Layout

if { $use_aie == "true" } {
 
   regenerate_bd_layout -layout_string {
	   "ActiveEmotionalView":"Default View",
	   "comment_0":"\t \t \t =============== >>>> An Example Versal Extensible Embedded Platform <<<< ===============
		\t Note: 
		\t --> SD boot mode and UART are enabled in the CIPS
		\t --> AI Engine control path is connected to CIPS
		\t --> V++ will connect AI Engine data path automatically
		\t --> Execute TCL command: launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.",
	   "commentid":"comment_0|",
	   "font_comment_0":"14",
	   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
		#  -string -flagsOSRD
		preplace cgraphic comment_0 place right -1500 -145 textcolor 4 linecolor 3
		",
	   "linktoobj_comment_0":"",
	   "linktotype_comment_0":"bd_design" }
 
 } else {
 
  regenerate_bd_layout -layout_string {
	   "ActiveEmotionalView":"Default View",
	   "comment_0":"\t \t \t =============== >>>> An Example Versal Extensible Embedded Platform <<<< ===============
		\t Note: 
		\t --> SD boot mode and UART are enabled in the CIPS
		\t --> Execute TCL command: launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.",
	   "commentid":"comment_0|",
	   "font_comment_0":"14",
	   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
		#  -string -flagsOSRD
		preplace cgraphic comment_0 place right -1500 -130 textcolor 4 linecolor 3
		",
	   "linktoobj_comment_0":"",
	   "linktotype_comment_0":"bd_design" }
}


set_property SELECTED_SIM_MODEL tlm [get_bd_cells /ps_wizard_0]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells /ps_wiz_noc2]
#set_property SELECTED_SIM_MODEL tlm [get_bd_cells /noc2_lpddr5]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells /noc2_ddr5]
set_property preferred_sim_model tlm [current_project]

set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] [get_bd_cells clk_wizard_0]

save_bd_design
validate_bd_design
open_bd_design [get_bd_files $design_name]
regenerate_bd_layout

make_wrapper -files [get_files $design_name.bd] -top -import -quiet
set_property SOURCE_SET sources_1 [get_filesets sim_1]
# -flat imports all files into the imports folder without preserving their relative paths
update_compile_order -fileset sim_1	

puts "INFO: End of create_root_design"
