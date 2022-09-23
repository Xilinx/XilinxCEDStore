open_bd_design [get_bd_files $design_name]

# Create instance: CIPS_0, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:* CIPS_0

#apply board preset 
apply_board_connection -board_interface "ps_pmc_fixed_io" -ip_intf "CIPS_0/FIXED_IO" -diagram $design_name

set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom DDR_MEMORY_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 99.999992 PMC_USE_PMC_NOC_AXI0 1 PS_IRQ_USAGE {{CH0 1} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} PS_NUM_FABRIC_RESETS 1 PS_PL_CONNECTIVITY_MODE Custom PS_USE_FPD_AXI_NOC0 1 PS_USE_FPD_AXI_NOC1 1 PS_USE_FPD_CCI_NOC 1 PS_USE_M_AXI_FPD 1 PS_USE_NOC_LPD_AXI0 1 PS_USE_PMCPL_CLK0 1 } CONFIG.CLOCK_MODE {Custom} CONFIG.DDR_MEMORY_MODE {Custom} CONFIG.PS_PL_CONNECTIVITY_MODE {Custom}] [get_bd_cells CIPS_0]

set_property -dict [list CONFIG.PS_PMC_CONFIG {PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI0_MASTER A72 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI1_MASTER A72 PS_GEN_IPI2_ENABLE 1 PS_GEN_IPI2_MASTER A72 PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI3_MASTER A72 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI4_MASTER A72 PS_GEN_IPI5_ENABLE 1 PS_GEN_IPI5_MASTER A72 PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI6_MASTER A72} ] [get_bd_cells CIPS_0]


# Create instance: IsoReset, and set properties
set IsoReset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset IsoReset ]

# Create instance: VitisRegion, and set properties
set VitisRegion [ create_bd_cell -type container -reference VitisRegion VitisRegion ]
set_property -dict [list \
  CONFIG.ACTIVE_SIM_BD {VitisRegion.bd} \
  CONFIG.ACTIVE_SYNTH_BD {VitisRegion.bd} \
  CONFIG.ENABLE_DFX {true} \
  CONFIG.LIST_SIM_BD {VitisRegion.bd} \
  CONFIG.LIST_SYNTH_BD {VitisRegion.bd} \
  CONFIG.LOCK_PROPAGATE {true} \
] $VitisRegion

set_property APERTURES {{0xA700_0000 144M}} [get_bd_intf_pins /VitisRegion/PL_CTRL_S_AXI]

# Create instance: icn_ctrl_0, and set properties
set icn_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_0 ]


if {$use_intc} {

	#set properties of instance icn_ctrl_0
	set_property -dict [list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {3} CONFIG.NUM_SI {1} ] $icn_ctrl_0

	# Create instance: axi_intc_0, and set properties
	set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
	set_property -dict [ list CONFIG.C_ASYNC_INTR {0xFFFFFFFF} CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_0
}

if { $use_cascaded_irqs } {

	#set properties of instance icn_ctrl_0
	set_property -dict [list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {4} CONFIG.NUM_SI {1} ] $icn_ctrl_0

	# Create instance: axi_intc_cascaded_1, and set properties
	set axi_intc_cascaded_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_cascaded_1 ]
	set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_cascaded_1

	# Create instance: axi_intc_parent, and set properties
	set axi_intc_parent [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_parent ]
	set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_parent
}

# Create instance: clk_wizard_1, and set properties
set clk_wizard_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_1 ]
set_property -dict [list \
  CONFIG.CLKOUT_DRIVES {BUFG} \
  CONFIG.CLKOUT_DYN_PS {None} \
  CONFIG.CLKOUT_MATCHED_ROUTING {false} \
  CONFIG.CLKOUT_PORT {clk_out1} \
  CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000} \
  CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {100.000} \
  CONFIG.CLKOUT_REQUESTED_PHASE {0.000} \
  CONFIG.CLKOUT_USED {true} \
  CONFIG.JITTER_SEL {Min_O_Jitter} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.USE_PHASE_ALIGNMENT {true} \
  CONFIG.USE_RESET {true} \
] $clk_wizard_1

set_property CONFIG.PRIM_SOURCE {No_buffer} [get_bd_cells clk_wizard_1]

# Create instance: dfx_decoupler, and set properties
set dfx_decoupler [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_decoupler dfx_decoupler ]
set_property CONFIG.ALL_PARAMS {HAS_SIGNAL_CONTROL 0 HAS_SIGNAL_STATUS 0 HAS_AXI_LITE 1 INTF {intf_0 {ID 0 VLNV xilinx.com:interface:aximm_rtl:1.0 MODE slave PROTOCOL AXI4 SIGNALS {ARVALID {WIDTH 1 PRESENT\
1} ARREADY {WIDTH 1 PRESENT 1} AWVALID {WIDTH 1 PRESENT 1} AWREADY {WIDTH 1 PRESENT 1} BVALID {WIDTH 1 PRESENT 1} BREADY {WIDTH 1 PRESENT 1} RVALID {WIDTH 1 PRESENT 1} RREADY {WIDTH 1 PRESENT 1} WVALID\
{WIDTH 1 PRESENT 1} WREADY {WIDTH 1 PRESENT 1} AWID {WIDTH 16 PRESENT 1} AWADDR {WIDTH 44 PRESENT 1} AWLEN {WIDTH 8 PRESENT 1} AWSIZE {WIDTH 3 PRESENT 1} AWBURST {WIDTH 2 PRESENT 1} AWLOCK {WIDTH 1 PRESENT\
1} AWCACHE {WIDTH 4 PRESENT 1} AWPROT {WIDTH 3 PRESENT 1} AWREGION {WIDTH 4 PRESENT 0} AWQOS {WIDTH 4 PRESENT 1} AWUSER {WIDTH 16 PRESENT 1} WID {WIDTH 16 PRESENT 1} WDATA {WIDTH 32 PRESENT 1} WSTRB {WIDTH\
4 PRESENT 1} WLAST {WIDTH 1 PRESENT 1} WUSER {WIDTH 4 PRESENT 1} BID {WIDTH 16 PRESENT 1} BRESP {WIDTH 2 PRESENT 1} BUSER {WIDTH 0 PRESENT 0} ARID {WIDTH 16 PRESENT 1} ARADDR {WIDTH 44 PRESENT 1} ARLEN\
{WIDTH 8 PRESENT 1} ARSIZE {WIDTH 3 PRESENT 1} ARBURST {WIDTH 2 PRESENT 1} ARLOCK {WIDTH 1 PRESENT 1} ARCACHE {WIDTH 4 PRESENT 1} ARPROT {WIDTH 3 PRESENT 1} ARREGION {WIDTH 4 PRESENT 0} ARQOS {WIDTH 4\
PRESENT 1} ARUSER {WIDTH 16 PRESENT 1} RID {WIDTH 16 PRESENT 1} RDATA {WIDTH 32 PRESENT 1} RRESP {WIDTH 2 PRESENT 1} RLAST {WIDTH 1 PRESENT 1} RUSER {WIDTH 4 PRESENT 1}}} intf_1 {ID 1 VLNV xilinx.com:signal:interrupt_rtl:1.0\
MODE master SIGNALS {INTERRUPT {PRESENT 1 WIDTH 32}}} intf_2 {ID 2 VLNV xilinx.com:signal:interrupt_rtl:1.0 MODE master SIGNALS {INTERRUPT {PRESENT 1 WIDTH 31}}}} ALWAYS_HAVE_AXI_CLK 1 IPI_PROP_COUNT 1}\
$dfx_decoupler

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* default_mem
if {[regexp "vpk120" $board_name]||[regexp "vpk180" $board_name]||[regexp "vek280" $board_name]} {
apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "default_mem/CH0_LPDDR4_0" -diagram $design_name 
apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "default_mem/CH1_LPDDR4_0" -diagram $design_name 
apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "default_mem/sys_clk0" -diagram $design_name
} elseif {[regexp "vhk158" $board_name]} {
apply_board_connection -board_interface "ddr4_dimm0" -ip_intf "default_mem/CH0_DDR4_0" -diagram $design_name 
apply_board_connection -board_interface "ddr4_dimm0_sma_clk" -ip_intf "default_mem/sys_clk0" -diagram $design_name 
} else {
apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "default_mem/CH0_DDR4_0" -diagram $design_name 
apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "default_mem/sys_clk0" -diagram $design_name 
}
set_property -dict [list CONFIG.MC_CHAN_REGION1 {DDR_LOW1} CONFIG.NUM_MCP {4} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {8} CONFIG.NUM_SI {0} ] [get_bd_cells default_mem]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /default_mem/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /default_mem/S01_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /default_mem/S02_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /default_mem/S03_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /default_mem/S04_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /default_mem/S05_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /default_mem/S06_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /default_mem/S07_INI]

# Create instance: ps_noc, and set properties
set ps_noc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc ps_noc ]
set_property -dict [list CONFIG.NUM_CLKS {8} CONFIG.NUM_MI {0} CONFIG.NUM_NMI {4} CONFIG.NUM_SI {8} ] [get_bd_cells ps_noc]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M02_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M03_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI { read_bw {5} write_bw {5}}}] [get_bd_intf_pins /ps_noc/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI { read_bw {5} write_bw {5}}}] [get_bd_intf_pins /ps_noc/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M00_INI { read_bw {5} write_bw {5}}}] [get_bd_intf_pins /ps_noc/S06_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M00_INI { read_bw {5} write_bw {5}}}] [get_bd_intf_pins /ps_noc/S07_AXI]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S03_AXI:S02_AXI:S00_AXI:S01_AXI:S04_AXI:S07_AXI:S06_AXI:S05_AXI}] [get_bd_pins /ps_noc/aclk0]

if { $use_lpddr } {
puts "INFO: additional_memory is selected"
# Create instance: noc_lpddr, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* additional_mem

if {[regexp "vpk120" $board_name]||[regexp "vpk180" $board_name]||[regexp "vek280" $board_name]} {

apply_board_connection -board_interface "ch0_lpddr4_trip2" -ip_intf "additional_mem/CH0_LPDDR4_0" -diagram $design_name 
apply_board_connection -board_interface "ch1_lpddr4_trip2" -ip_intf "additional_mem/CH1_LPDDR4_0" -diagram $design_name 
apply_board_connection -board_interface "lpddr4_clk2" -ip_intf "additional_mem/sys_clk0" -diagram $design_name 

apply_board_connection -board_interface "ch0_lpddr4_trip3" -ip_intf "/additional_mem/CH0_LPDDR4_1" -diagram $design_name 
apply_board_connection -board_interface "ch1_lpddr4_trip3" -ip_intf "/additional_mem/CH1_LPDDR4_1" -diagram $design_name 
apply_board_connection -board_interface "lpddr4_clk3" -ip_intf "/additional_mem/sys_clk1" -diagram $design_name 

} elseif {[regexp "vhk158" $board_name]} {
apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "additional_mem/CH0_DDR4_0" -diagram $design_name 
apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "additional_mem/sys_clk0" -diagram $design_name 
} else {

apply_board_connection -board_interface "ch0_lpddr4_c0" -ip_intf "additional_mem/CH0_LPDDR4_0" -diagram $design_name 
apply_board_connection -board_interface "ch1_lpddr4_c0" -ip_intf "additional_mem/CH1_LPDDR4_0" -diagram $design_name 
apply_board_connection -board_interface "lpddr4_sma_clk1" -ip_intf "additional_mem/sys_clk0" -diagram $design_name 

apply_board_connection -board_interface "ch0_lpddr4_c1" -ip_intf "/additional_mem/CH0_LPDDR4_1" -diagram $design_name 
apply_board_connection -board_interface "ch1_lpddr4_c1" -ip_intf "/additional_mem/CH1_LPDDR4_1" -diagram $design_name 
apply_board_connection -board_interface "lpddr4_sma_clk2" -ip_intf "/additional_mem/sys_clk1" -diagram $design_name 
}

set_property -dict [list CONFIG.MC_CHAN_REGION0 {DDR_CH1} CONFIG.NUM_MCP {4} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {8} CONFIG.NUM_SI {0} ] [get_bd_cells additional_mem]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /additional_mem/S00_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /additional_mem/S01_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /additional_mem/S02_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /additional_mem/S03_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /additional_mem/S04_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /additional_mem/S05_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /additional_mem/S06_INI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} CONFIG.INI_STRATEGY {load}] [get_bd_intf_pins /additional_mem/S07_INI]


if { $use_aie } {
set_property CONFIG.NUM_NMI {9} [get_bd_cells ps_noc]
set_property -dict [list CONFIG.CONNECTIONS {M08_INI { read_bw {128} write_bw {128}} M04_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M08_INI { read_bw {128} write_bw {128}} M01_INI { read_bw {128} write_bw {128}} M05_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M02_INI { read_bw {128} write_bw {128}} M08_INI { read_bw {128} write_bw {128}} M06_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M07_INI { read_bw {128} write_bw {128}} M08_INI { read_bw {128} write_bw {128}} M03_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M08_INI { read_bw {128} write_bw {128}} M04_INI { read_bw {5} write_bw {5}} M00_INI { read_bw {5} write_bw {5}}}] [get_bd_intf_pins /ps_noc/S07_AXI]
} else {
set_property CONFIG.NUM_NMI {8} [get_bd_cells ps_noc]
set_property -dict [list CONFIG.CONNECTIONS {M04_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M05_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M02_INI { read_bw {128} write_bw {128}} M06_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M07_INI { read_bw {128} write_bw {128}} M03_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S03_AXI] }

} elseif {$use_aie } {
set_property CONFIG.NUM_NMI {5} [get_bd_cells ps_noc]
set_property -dict [list CONFIG.CONNECTIONS {M04_INI { read_bw {1720} write_bw {1720}} M00_INI { read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_noc/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {M04_INI { read_bw {1720} write_bw {1720}} M00_INI { read_bw {5} write_bw {5}}}] [get_bd_intf_pins /ps_noc/S07_AXI]  }

set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S00_AXI} ] [get_bd_pins /ps_noc/aclk0]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S01_AXI} ] [get_bd_pins /ps_noc/aclk1]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S02_AXI} ] [get_bd_pins /ps_noc/aclk2]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S03_AXI} ] [get_bd_pins /ps_noc/aclk3]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S04_AXI} ] [get_bd_pins /ps_noc/aclk4]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S05_AXI} ] [get_bd_pins /ps_noc/aclk5]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S06_AXI} ] [get_bd_pins /ps_noc/aclk6]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S07_AXI} ] [get_bd_pins /ps_noc/aclk7]

if { $use_cascaded_irqs } {
# Create instance: xlconcat_0, and set properties
set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]
set_property -dict [list CONFIG.IN0_WIDTH {31} CONFIG.NUM_PORTS {2} ] $xlconcat_0 }


# Create instance: xlconcat_3, and set properties
set xlconcat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_3 ]
set_property -dict [list CONFIG.IN0_WIDTH {32} CONFIG.NUM_PORTS {1} ] $xlconcat_3 

  # Create interface connections
  connect_bd_intf_net -intf_net ShellSide_M_AXI [get_bd_intf_pins CIPS_0/M_AXI_FPD] [get_bd_intf_pins icn_ctrl_0/S00_AXI]
  connect_bd_intf_net -intf_net VitisRegion_DDR_0 [get_bd_intf_pins VitisRegion/DDR_0] [get_bd_intf_pins default_mem/S04_INI]
  connect_bd_intf_net -intf_net VitisRegion_DDR_1 [get_bd_intf_pins VitisRegion/DDR_1] [get_bd_intf_pins default_mem/S05_INI]
  connect_bd_intf_net -intf_net VitisRegion_DDR_2 [get_bd_intf_pins VitisRegion/DDR_2] [get_bd_intf_pins default_mem/S06_INI]
  
  if { $use_lpddr } {
  connect_bd_intf_net -intf_net VitisRegion_LPDDR_0 [get_bd_intf_pins VitisRegion/LPDDR_0] [get_bd_intf_pins additional_mem/S04_INI]
  connect_bd_intf_net -intf_net VitisRegion_LPDDR_1 [get_bd_intf_pins VitisRegion/LPDDR_1] [get_bd_intf_pins additional_mem/S05_INI]
  connect_bd_intf_net -intf_net VitisRegion_LPDDR_2 [get_bd_intf_pins VitisRegion/LPDDR_2] [get_bd_intf_pins additional_mem/S06_INI]
  connect_bd_intf_net -intf_net VitisRegion_M03_INI1 [get_bd_intf_pins VitisRegion/LPDDR_3] [get_bd_intf_pins additional_mem/S07_INI]
  # connect_bd_intf_net -intf_net axi_noc_0_CH0_LPDDR4_0 [get_bd_intf_ports ch0_lpddr4_c0] [get_bd_intf_pins additional_mem/CH0_LPDDR4_0]
  # connect_bd_intf_net -intf_net axi_noc_0_CH0_LPDDR4_1 [get_bd_intf_ports ch0_lpddr4_c1] [get_bd_intf_pins additional_mem/CH0_LPDDR4_1]
  # connect_bd_intf_net -intf_net axi_noc_0_CH1_LPDDR4_0 [get_bd_intf_ports ch1_lpddr4_c0] [get_bd_intf_pins additional_mem/CH1_LPDDR4_0]
  # connect_bd_intf_net -intf_net axi_noc_0_CH1_LPDDR4_1 [get_bd_intf_ports ch1_lpddr4_c1] [get_bd_intf_pins additional_mem/CH1_LPDDR4_1] 
  # connect_bd_intf_net -intf_net lpddr4_sma_clk1_1 [get_bd_intf_ports lpddr4_sma_clk1] [get_bd_intf_pins additional_mem/sys_clk0]
  # connect_bd_intf_net -intf_net lpddr4_sma_clk2_1 [get_bd_intf_ports lpddr4_sma_clk2] [get_bd_intf_pins additional_mem/sys_clk1]
  connect_bd_intf_net -intf_net ps_noc_M04_INI [get_bd_intf_pins additional_mem/S00_INI] [get_bd_intf_pins ps_noc/M04_INI]
  connect_bd_intf_net -intf_net ps_noc_M05_INI [get_bd_intf_pins additional_mem/S01_INI] [get_bd_intf_pins ps_noc/M05_INI]
  connect_bd_intf_net -intf_net ps_noc_M06_INI [get_bd_intf_pins additional_mem/S02_INI] [get_bd_intf_pins ps_noc/M06_INI]
  connect_bd_intf_net -intf_net ps_noc_M07_INI [get_bd_intf_pins additional_mem/S03_INI] [get_bd_intf_pins ps_noc/M07_INI]
   if {$use_aie } {
  connect_bd_intf_net -intf_net ps_noc_M08_INI [get_bd_intf_pins VitisRegion/AIE_CTRL_INI] [get_bd_intf_pins ps_noc/M08_INI] }
  } elseif {$use_aie } {
  connect_bd_intf_net -intf_net ps_noc_M08_INI [get_bd_intf_pins VitisRegion/AIE_CTRL_INI] [get_bd_intf_pins ps_noc/M04_INI] }
  
  connect_bd_intf_net -intf_net VitisRegion_M03_INI2 [get_bd_intf_pins VitisRegion/DDR_3] [get_bd_intf_pins default_mem/S07_INI]
  connect_bd_intf_net -intf_net dfx_decoupler_M_AXI [get_bd_intf_pins VitisRegion/PL_CTRL_S_AXI] [get_bd_intf_pins dfx_decoupler/rp_intf_0]
  connect_bd_intf_net -intf_net icn_ctrl_0_M00_AXI [get_bd_intf_pins dfx_decoupler/s_intf_0] [get_bd_intf_pins icn_ctrl_0/M00_AXI]
  
  connect_bd_intf_net -intf_net icn_ctrl_0_M02_AXI [get_bd_intf_pins dfx_decoupler/s_axi_reg] [get_bd_intf_pins icn_ctrl_0/M02_AXI]
  
 
  connect_bd_intf_net -intf_net ps_cips_FPD_AXI_NOC_0 [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_0] [get_bd_intf_pins ps_noc/S04_AXI]
  connect_bd_intf_net -intf_net ps_cips_FPD_AXI_NOC_1 [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_1] [get_bd_intf_pins ps_noc/S05_AXI]
  connect_bd_intf_net -intf_net ps_cips_IF_PS_NOC_CCI_0 [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_0] [get_bd_intf_pins ps_noc/S00_AXI]
  connect_bd_intf_net -intf_net ps_cips_IF_PS_NOC_CCI_1 [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_1] [get_bd_intf_pins ps_noc/S01_AXI]
  connect_bd_intf_net -intf_net ps_cips_IF_PS_NOC_CCI_2 [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_2] [get_bd_intf_pins ps_noc/S02_AXI]
  connect_bd_intf_net -intf_net ps_cips_IF_PS_NOC_CCI_3 [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_3] [get_bd_intf_pins ps_noc/S03_AXI]
  connect_bd_intf_net -intf_net ps_cips_NOC_LPD_AXI_0 [get_bd_intf_pins CIPS_0/LPD_AXI_NOC_0] [get_bd_intf_pins ps_noc/S06_AXI]
  connect_bd_intf_net -intf_net ps_cips_PMC_NOC_AXI_0 [get_bd_intf_pins CIPS_0/PMC_NOC_AXI_0] [get_bd_intf_pins ps_noc/S07_AXI]
  connect_bd_intf_net -intf_net ps_noc_M00_INI [get_bd_intf_pins default_mem/S00_INI] [get_bd_intf_pins ps_noc/M00_INI]
  connect_bd_intf_net -intf_net ps_noc_M01_INI [get_bd_intf_pins default_mem/S01_INI] [get_bd_intf_pins ps_noc/M01_INI]
  connect_bd_intf_net -intf_net ps_noc_M02_INI [get_bd_intf_pins default_mem/S02_INI] [get_bd_intf_pins ps_noc/M02_INI]
  connect_bd_intf_net -intf_net ps_noc_M03_INI [get_bd_intf_pins default_mem/S03_INI] [get_bd_intf_pins ps_noc/M03_INI]
  
  # if {$use_aie } {
  # connect_bd_intf_net -intf_net ps_noc_M08_INI [get_bd_intf_pins VitisRegion/AIE_CTRL_INI] [get_bd_intf_pins ps_noc/M08_INI] }

  # Create port connections
  connect_bd_net -net CIPS_0_pl_clk0 [get_bd_pins CIPS_0/pl0_ref_clk] [get_bd_pins clk_wizard_1/clk_in1]
  connect_bd_net -net CtrlReset_peripheral_aresetn [get_bd_pins IsoReset/peripheral_aresetn] [get_bd_pins VitisRegion/ExtReset]  [get_bd_pins dfx_decoupler/intf_0_arstn] [get_bd_pins dfx_decoupler/s_axi_reg_aresetn] [get_bd_pins icn_ctrl_0/aresetn]
  
  connect_bd_net -net VitisRegion_Interrupt [get_bd_pins VitisRegion/Interrupt] [get_bd_pins dfx_decoupler/rp_intf_1_INTERRUPT]
  
  connect_bd_net -net clk_wizard_1_clk_out1 [get_bd_pins CIPS_0/m_axi_fpd_aclk] [get_bd_pins IsoReset/slowest_sync_clk] [get_bd_pins VitisRegion/ExtClk]   [get_bd_pins clk_wizard_1/clk_out1] [get_bd_pins dfx_decoupler/aclk] [get_bd_pins dfx_decoupler/intf_0_aclk] [get_bd_pins icn_ctrl_0/aclk]
  
  connect_bd_net -net clk_wizard_1_locked [get_bd_pins IsoReset/dcm_locked] [get_bd_pins clk_wizard_1/locked]
  connect_bd_net -net ps_cips_fpd_axi_noc_axi0_clk [get_bd_pins CIPS_0/fpd_axi_noc_axi0_clk] [get_bd_pins ps_noc/aclk4]
  connect_bd_net -net ps_cips_fpd_axi_noc_axi1_clk [get_bd_pins CIPS_0/fpd_axi_noc_axi1_clk] [get_bd_pins ps_noc/aclk5]
  connect_bd_net -net ps_cips_lpd_axi_noc_clk [get_bd_pins CIPS_0/lpd_axi_noc_clk] [get_bd_pins ps_noc/aclk6]
  connect_bd_net -net ps_cips_pl0_resetn [get_bd_pins CIPS_0/pl0_resetn] [get_bd_pins IsoReset/ext_reset_in] [get_bd_pins clk_wizard_1/resetn]
  connect_bd_net -net ps_cips_pmc_axi_noc_axi0_clk [get_bd_pins CIPS_0/pmc_axi_noc_axi0_clk] [get_bd_pins ps_noc/aclk7]
  connect_bd_net -net ps_cips_ps_ps_noc_cci_axi0_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi0_clk] [get_bd_pins ps_noc/aclk0]
  connect_bd_net -net ps_cips_ps_ps_noc_cci_axi1_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi1_clk] [get_bd_pins ps_noc/aclk1]
  connect_bd_net -net ps_cips_ps_ps_noc_cci_axi2_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi2_clk] [get_bd_pins ps_noc/aclk2]
  connect_bd_net -net ps_cips_ps_ps_noc_cci_axi3_clk [get_bd_pins CIPS_0/fpd_cci_noc_axi3_clk] [get_bd_pins ps_noc/aclk3]
  
  if { $use_cascaded_irqs } {
  connect_bd_net -net VitisRegion_Interrupt1 [get_bd_pins VitisRegion/Interrupt1] [get_bd_pins dfx_decoupler/rp_intf_2_INTERRUPT]
  connect_bd_intf_net -intf_net icn_ctrl_0_M01_AXI [get_bd_intf_pins axi_intc_parent/s_axi] [get_bd_intf_pins icn_ctrl_0/M01_AXI]
  connect_bd_intf_net -intf_net icn_ctrl_0_M03_AXI [get_bd_intf_pins axi_intc_cascaded_1/s_axi] [get_bd_intf_pins icn_ctrl_0/M03_AXI]
  connect_bd_net -net CtrlReset_peripheral_aresetn [get_bd_pins IsoReset/peripheral_aresetn] [get_bd_pins axi_intc_cascaded_1/s_axi_aresetn] [get_bd_pins axi_intc_parent/s_axi_aresetn]
  connect_bd_net -net clk_wizard_1_clk_out1 [get_bd_pins CIPS_0/m_axi_fpd_aclk] [get_bd_pins axi_intc_parent/s_axi_aclk] [get_bd_pins axi_intc_cascaded_1/s_axi_aclk]
  connect_bd_net -net axi_intc_cascaded_1_irq [get_bd_pins axi_intc_cascaded_1/irq] [get_bd_pins xlconcat_0/In1] 
  connect_bd_net -net axi_intc_parent_irq [get_bd_pins CIPS_0/pl_ps_irq0] [get_bd_pins axi_intc_parent/irq] 
  connect_bd_net -net xlconcat_0_dout [get_bd_pins axi_intc_parent/intr] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconcat_3_dout [get_bd_pins axi_intc_cascaded_1/intr] [get_bd_pins xlconcat_3/dout] 
  connect_bd_net -net dfx_decoupler_s_intf_1_INTERRUPT [get_bd_pins dfx_decoupler/s_intf_1_INTERRUPT] [get_bd_pins xlconcat_3/In0]
  connect_bd_net -net dfx_decoupler_s_intf_2_INTERRUPT [get_bd_pins dfx_decoupler/s_intf_2_INTERRUPT] [get_bd_pins xlconcat_0/In0]     }

 if { $use_intc } {
	connect_bd_net [get_bd_pins dfx_decoupler/s_intf_1_INTERRUPT] [get_bd_pins xlconcat_3/In0]
	connect_bd_net [get_bd_pins xlconcat_3/dout] [get_bd_pins axi_intc_0/intr]
	connect_bd_intf_net [get_bd_intf_pins icn_ctrl_0/M01_AXI] [get_bd_intf_pins axi_intc_0/s_axi]
	connect_bd_net [get_bd_pins axi_intc_0/s_axi_aclk] [get_bd_pins clk_wizard_1/clk_out1]
	connect_bd_net [get_bd_pins axi_intc_0/s_axi_aresetn] [get_bd_pins IsoReset/peripheral_aresetn]
	connect_bd_net [get_bd_pins CIPS_0/pl_ps_irq0] [get_bd_pins axi_intc_0/irq]
  }




  # Create address segments
  # assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW0] -force
  # assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW1] -force
  # assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW0] -force
  # assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW1] -force
  # assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs VitisRegion/ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
  # assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW0] -force
  # assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW1] -force
  # assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs additional_mem/S00_INI/C0_DDR_CH1x2] -force
  # assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs VitisRegion/ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
  # assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs default_mem/S01_INI/C1_DDR_LOW0] -force
  # assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs default_mem/S01_INI/C1_DDR_LOW1] -force
  # assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs additional_mem/S01_INI/C1_DDR_CH1x2] -force
  # assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs VitisRegion/ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
  # assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs default_mem/S02_INI/C2_DDR_LOW0] -force
  # assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs default_mem/S02_INI/C2_DDR_LOW1] -force
  # assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs additional_mem/S02_INI/C2_DDR_CH1x2] -force
  # assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs VitisRegion/ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
  # assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs default_mem/S03_INI/C3_DDR_LOW0] -force
  # assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs default_mem/S03_INI/C3_DDR_LOW1] -force
  # assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs additional_mem/S03_INI/C3_DDR_CH1x2] -force
  # assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW0] -force
  # assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW1] -force
  # assign_bd_address -offset 0xA4000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs axi_intc_cascaded_1/S_AXI/Reg] -force
  
  # assign_bd_address -offset 0xA5000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs axi_intc_parent/S_AXI/Reg] -force
  
  # assign_bd_address -offset 0xA6000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs dfx_decoupler/s_axi_reg/Reg] -force
  # assign_bd_address -offset 0xA7000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs VitisRegion/to_delete_kernel_ctrl_0/S_AXI/Reg] -force
  # assign_bd_address -offset 0xA8000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs VitisRegion/to_delete_kernel_ctrl_1/S_AXI/Reg] -force
  # assign_bd_address -offset 0xA9000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs VitisRegion/to_delete_kernel_ctrl_2/S_AXI/Reg] -force
  # assign_bd_address -offset 0xAA000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs VitisRegion/to_delete_kernel_ctrl_3/S_AXI/Reg] -force
  # assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs VitisRegion/ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
  # assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW0] -force
  # assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs default_mem/S00_INI/C0_DDR_LOW1] -force
  # assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs additional_mem/S00_INI/C0_DDR_CH1x2] -force
  
  set_param project.replaceDontTouchWithKeepHierarchySoft 0
  assign_bd_address
  validate_bd_design
  save_bd_design



