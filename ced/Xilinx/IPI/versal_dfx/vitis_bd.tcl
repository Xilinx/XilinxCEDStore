create_bd_design "VitisRegion"

# Create DDR ports and apply its properties 
set DDR_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 -portmaps { \
   INTERNOC { physical_name DDR_0_internoc direction O left 0 right 0 } \
   } \
  DDR_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.COMPUTED_STRATEGY {load} \
   CONFIG.INI_STRATEGY {load} \
   ] $DDR_0
  set_property APERTURES {{0x0 2G} {0x8_0000_0000 6G}} [get_bd_intf_ports DDR_0]
  set_property HDL_ATTRIBUTE.LOCKED {TRUE} [get_bd_intf_ports DDR_0]

  set DDR_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 -portmaps { \
   INTERNOC { physical_name DDR_1_internoc direction O left 0 right 0 } \
   } \
  DDR_1 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.COMPUTED_STRATEGY {load} \
   CONFIG.INI_STRATEGY {load} \
   ] $DDR_1
  set_property APERTURES {{0x0 2G} {0x8_0000_0000 6G}} [get_bd_intf_ports DDR_1]
  set_property HDL_ATTRIBUTE.LOCKED {TRUE} [get_bd_intf_ports DDR_1]

  set DDR_2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 -portmaps { \
   INTERNOC { physical_name DDR_2_internoc direction O left 0 right 0 } \
   } \
  DDR_2 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.COMPUTED_STRATEGY {load} \
   CONFIG.INI_STRATEGY {load} \
   ] $DDR_2
  set_property APERTURES {{0x0 2G} {0x8_0000_0000 6G}} [get_bd_intf_ports DDR_2]
  set_property HDL_ATTRIBUTE.LOCKED {TRUE} [get_bd_intf_ports DDR_2]

  set DDR_3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 -portmaps { \
   INTERNOC { physical_name DDR_3_internoc direction O left 0 right 0 } \
   } \
  DDR_3 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.COMPUTED_STRATEGY {load} \
   CONFIG.INI_STRATEGY {load} \
   ] $DDR_3
  set_property APERTURES {{0x0 2G} {0x8_0000_0000 6G}} [get_bd_intf_ports DDR_3]
  set_property HDL_ATTRIBUTE.LOCKED {TRUE} [get_bd_intf_ports DDR_3]


  set PL_CTRL_S_AXI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 -portmaps { \
   ARADDR { physical_name PL_CTRL_S_AXI_araddr direction I left 43 right 0 } \
   ARBURST { physical_name PL_CTRL_S_AXI_arburst direction I left 1 right 0 } \
   ARCACHE { physical_name PL_CTRL_S_AXI_arcache direction I left 3 right 0 } \
   ARID { physical_name PL_CTRL_S_AXI_arid direction I left 15 right 0 } \
   ARLEN { physical_name PL_CTRL_S_AXI_arlen direction I left 7 right 0 } \
   ARLOCK { physical_name PL_CTRL_S_AXI_arlock direction I left 0 right 0 } \
   ARPROT { physical_name PL_CTRL_S_AXI_arprot direction I left 2 right 0 } \
   ARQOS { physical_name PL_CTRL_S_AXI_arqos direction I left 3 right 0 } \
   ARREADY { physical_name PL_CTRL_S_AXI_arready direction O } \
   ARSIZE { physical_name PL_CTRL_S_AXI_arsize direction I left 2 right 0 } \
   ARUSER { physical_name PL_CTRL_S_AXI_aruser direction I left 15 right 0 } \
   ARVALID { physical_name PL_CTRL_S_AXI_arvalid direction I } \
   AWADDR { physical_name PL_CTRL_S_AXI_awaddr direction I left 43 right 0 } \
   AWBURST { physical_name PL_CTRL_S_AXI_awburst direction I left 1 right 0 } \
   AWCACHE { physical_name PL_CTRL_S_AXI_awcache direction I left 3 right 0 } \
   AWID { physical_name PL_CTRL_S_AXI_awid direction I left 15 right 0 } \
   AWLEN { physical_name PL_CTRL_S_AXI_awlen direction I left 7 right 0 } \
   AWLOCK { physical_name PL_CTRL_S_AXI_awlock direction I left 0 right 0 } \
   AWPROT { physical_name PL_CTRL_S_AXI_awprot direction I left 2 right 0 } \
   AWQOS { physical_name PL_CTRL_S_AXI_awqos direction I left 3 right 0 } \
   AWREADY { physical_name PL_CTRL_S_AXI_awready direction O } \
   AWSIZE { physical_name PL_CTRL_S_AXI_awsize direction I left 2 right 0 } \
   AWUSER { physical_name PL_CTRL_S_AXI_awuser direction I left 15 right 0 } \
   AWVALID { physical_name PL_CTRL_S_AXI_awvalid direction I } \
   BID { physical_name PL_CTRL_S_AXI_bid direction O left 15 right 0 } \
   BREADY { physical_name PL_CTRL_S_AXI_bready direction I } \
   BRESP { physical_name PL_CTRL_S_AXI_bresp direction O left 1 right 0 } \
   BVALID { physical_name PL_CTRL_S_AXI_bvalid direction O } \
   RDATA { physical_name PL_CTRL_S_AXI_rdata direction O left 31 right 0 } \
   RID { physical_name PL_CTRL_S_AXI_rid direction O left 15 right 0 } \
   RLAST { physical_name PL_CTRL_S_AXI_rlast direction O } \
   RREADY { physical_name PL_CTRL_S_AXI_rready direction I } \
   RRESP { physical_name PL_CTRL_S_AXI_rresp direction O left 1 right 0 } \
   RUSER { physical_name PL_CTRL_S_AXI_ruser direction O left 3 right 0 } \
   RVALID { physical_name PL_CTRL_S_AXI_rvalid direction O } \
   WDATA { physical_name PL_CTRL_S_AXI_wdata direction I left 31 right 0 } \
   WLAST { physical_name PL_CTRL_S_AXI_wlast direction I } \
   WREADY { physical_name PL_CTRL_S_AXI_wready direction O } \
   WSTRB { physical_name PL_CTRL_S_AXI_wstrb direction I left 3 right 0 } \
   WUSER { physical_name PL_CTRL_S_AXI_wuser direction I left 3 right 0 } \
   WVALID { physical_name PL_CTRL_S_AXI_wvalid direction I } \
   } \
  PL_CTRL_S_AXI ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {44} \
   CONFIG.ARUSER_WIDTH {16} \
   CONFIG.AWUSER_WIDTH {16} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {16} \
   CONFIG.INSERT_VIP {0} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {4} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {4} \
   ] $PL_CTRL_S_AXI
  set_property APERTURES {{0xA700_0000 144M}} [get_bd_intf_ports PL_CTRL_S_AXI]
  set_property HDL_ATTRIBUTE.LOCKED {TRUE} [get_bd_intf_ports PL_CTRL_S_AXI]


  # Create ports
  set ExtClk [ create_bd_port -dir I -type clk ExtClk ]
  set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {PL_CTRL_S_AXI} ] $ExtClk
  
  set ExtReset [ create_bd_port -dir I -type rst ExtReset ]

  # Create instance: DDRNoc, and set properties
  set DDRNoc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc DDRNoc ]
  set_property -dict [list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {0} CONFIG.NUM_NMI {4} CONFIG.NUM_SI {4} ] $DDRNoc
  
set_property -dict [ list CONFIG.INI_STRATEGY {load} ] [get_bd_intf_pins /DDRNoc/M00_INI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} ] [get_bd_intf_pins /DDRNoc/M01_INI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} ] [get_bd_intf_pins /DDRNoc/M02_INI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} ] [get_bd_intf_pins /DDRNoc/M03_INI]

set_property -dict [ list CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} } CONFIG.DEST_IDS {} CONFIG.CATEGORY {pl} ] [get_bd_intf_pins /DDRNoc/S00_AXI]
set_property -dict [ list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} } CONFIG.DEST_IDS {} CONFIG.CATEGORY {pl} ] [get_bd_intf_pins /DDRNoc/S01_AXI]
set_property -dict [ list CONFIG.CONNECTIONS {M02_INI { read_bw {128} write_bw {128}} } CONFIG.DEST_IDS {} CONFIG.CATEGORY {pl} ] [get_bd_intf_pins /DDRNoc/S02_AXI]
set_property -dict [ list CONFIG.CONNECTIONS {M03_INI { read_bw {128} write_bw {128}} } CONFIG.DEST_IDS {} CONFIG.CATEGORY {pl} ] [get_bd_intf_pins /DDRNoc/S03_AXI]
set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {S00_AXI:S01_AXI:S02_AXI:S03_AXI} ] [get_bd_pins /DDRNoc/aclk0]

  # Create instance: IsoRegDynamic, and set properties
  set IsoRegDynamic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice IsoRegDynamic ]
  set_property -dict [list \
    CONFIG.ADDR_WIDTH {44} \
    CONFIG.ARUSER_WIDTH {16} \
    CONFIG.AWUSER_WIDTH {16} \
    CONFIG.BUSER_WIDTH {0} \
    CONFIG.DATA_WIDTH {32} \
    CONFIG.HAS_BRESP {1} \
    CONFIG.HAS_BURST {1} \
    CONFIG.HAS_CACHE {1} \
    CONFIG.HAS_LOCK {1} \
    CONFIG.HAS_PROT {1} \
    CONFIG.HAS_QOS {1} \
    CONFIG.HAS_REGION {0} \
    CONFIG.HAS_RRESP {1} \
    CONFIG.HAS_WSTRB {1} \
    CONFIG.ID_WIDTH {16} \
    CONFIG.MAX_BURST_LENGTH {256} \
    CONFIG.NUM_READ_OUTSTANDING {1} \
    CONFIG.NUM_READ_THREADS {1} \
    CONFIG.NUM_WRITE_OUTSTANDING {1} \
    CONFIG.NUM_WRITE_THREADS {1} \
    CONFIG.PROTOCOL {AXI4} \
    CONFIG.READ_WRITE_MODE {READ_WRITE} \
    CONFIG.REG_AR {0} \
    CONFIG.REG_AW {0} \
    CONFIG.REG_B {0} \
    CONFIG.REG_R {0} \
    CONFIG.REG_W {0} \
    CONFIG.RUSER_BITS_PER_BYTE {0} \
    CONFIG.RUSER_WIDTH {4} \
    CONFIG.SUPPORTS_NARROW_BURST {1} \
    CONFIG.WUSER_BITS_PER_BYTE {0} \
    CONFIG.WUSER_WIDTH {4} \
  ] $IsoRegDynamic


  # Create instance: IsoReset, and set properties
  set IsoReset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset IsoReset_0 ]
  
if { $use_lpddr } {
puts "INFO: additional_mem is selected"

  set LPDDR_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 -portmaps { \
   INTERNOC { physical_name LPDDR_0_internoc direction O left 0 right 0 } \
   } \
  LPDDR_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.COMPUTED_STRATEGY {load} \
   CONFIG.INI_STRATEGY {load} \
   ] $LPDDR_0
  set_property APERTURES {{0x500_0000_0000 8G}} [get_bd_intf_ports LPDDR_0]
  set_property HDL_ATTRIBUTE.LOCKED {TRUE} [get_bd_intf_ports LPDDR_0]

  set LPDDR_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 -portmaps { \
   INTERNOC { physical_name LPDDR_1_internoc direction O left 0 right 0 } \
   } \
  LPDDR_1 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.COMPUTED_STRATEGY {load} \
   CONFIG.INI_STRATEGY {load} \
   ] $LPDDR_1
  set_property APERTURES {{0x500_0000_0000 8G}} [get_bd_intf_ports LPDDR_1]
  set_property HDL_ATTRIBUTE.LOCKED {TRUE} [get_bd_intf_ports LPDDR_1]

  set LPDDR_2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 -portmaps { \
   INTERNOC { physical_name LPDDR_2_internoc direction O left 0 right 0 } \
   } \
  LPDDR_2 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.COMPUTED_STRATEGY {load} \
   CONFIG.INI_STRATEGY {load} \
   ] $LPDDR_2
  set_property APERTURES {{0x500_0000_0000 8G}} [get_bd_intf_ports LPDDR_2]
  set_property HDL_ATTRIBUTE.LOCKED {TRUE} [get_bd_intf_ports LPDDR_2]

  set LPDDR_3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:inimm_rtl:1.0 -portmaps { \
   INTERNOC { physical_name LPDDR_3_internoc direction O left 0 right 0 } \
   } \
  LPDDR_3 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.COMPUTED_STRATEGY {load} \
   CONFIG.INI_STRATEGY {load} \
   ] $LPDDR_3
  set_property APERTURES {{0x500_0000_0000 8G}} [get_bd_intf_ports LPDDR_3]
  set_property HDL_ATTRIBUTE.LOCKED {TRUE} [get_bd_intf_ports LPDDR_3]  
  
# Create instance: LPDDRNoc, and set properties
set LPDDRNoc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc LPDDRNoc ]
set_property -dict [list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {0} CONFIG.NUM_NMI {4} CONFIG.NUM_SI {4} ] $LPDDRNoc
set_property -dict [ list CONFIG.INI_STRATEGY {load} ] [get_bd_intf_pins /LPDDRNoc/M00_INI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} ] [get_bd_intf_pins /LPDDRNoc/M01_INI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} ] [get_bd_intf_pins /LPDDRNoc/M02_INI]
set_property -dict [ list CONFIG.INI_STRATEGY {load} ] [get_bd_intf_pins /LPDDRNoc/M03_INI]

set_property -dict [ list CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} } CONFIG.DEST_IDS {} CONFIG.CATEGORY {pl} ] [get_bd_intf_pins /LPDDRNoc/S00_AXI]
set_property -dict [ list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} } CONFIG.DEST_IDS {} CONFIG.CATEGORY {pl} ] [get_bd_intf_pins /LPDDRNoc/S01_AXI]
set_property -dict [ list CONFIG.CONNECTIONS {M02_INI { read_bw {128} write_bw {128}} } CONFIG.DEST_IDS {} CONFIG.CATEGORY {pl} ] [get_bd_intf_pins /LPDDRNoc/S02_AXI]
set_property -dict [ list CONFIG.CONNECTIONS {M03_INI { read_bw {128} write_bw {128}} } CONFIG.DEST_IDS {} CONFIG.CATEGORY {pl} ] [get_bd_intf_pins /LPDDRNoc/S03_AXI]

set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_AXI:S01_AXI:S02_AXI:S03_AXI} ] [get_bd_pins /LPDDRNoc/aclk0] 

connect_bd_intf_net -intf_net LPDDRNoc_M00_INI [get_bd_intf_ports LPDDR_0] [get_bd_intf_pins LPDDRNoc/M00_INI]
connect_bd_intf_net -intf_net LPDDRNoc_M01_INI [get_bd_intf_ports LPDDR_1] [get_bd_intf_pins LPDDRNoc/M01_INI]
connect_bd_intf_net -intf_net LPDDRNoc_M02_INI [get_bd_intf_ports LPDDR_2] [get_bd_intf_pins LPDDRNoc/M02_INI]
connect_bd_intf_net -intf_net Conn2 [get_bd_intf_ports LPDDR_3] [get_bd_intf_pins LPDDRNoc/M03_INI]
connect_bd_net [get_bd_ports ExtClk] [get_bd_pins LPDDRNoc/aclk0] }

if { $use_aie } {

# Create interface ports
set AIE_CTRL_INI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:inimm_rtl:1.0 AIE_CTRL_INI ]
set_property -dict [ list CONFIG.COMPUTED_STRATEGY {load} CONFIG.INI_STRATEGY {load} ] $AIE_CTRL_INI

# Create instance: ai_engine_0, and set properties
set ai_engine_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ai_engine ai_engine_0 ]
set_property -dict [list \
  CONFIG.CLK_NAMES {} \
  CONFIG.FIFO_TYPE_MI_AXIS {} \
  CONFIG.FIFO_TYPE_SI_AXIS {} \
  CONFIG.NAME_MI_AXIS {} \
  CONFIG.NAME_SI_AXIS {} \
  CONFIG.NUM_CLKS {0} \
  CONFIG.NUM_MI_AXI {0} \
  CONFIG.NUM_MI_AXIS {0} \
  CONFIG.NUM_SI_AXIS {0} \
] $ai_engine_0
  
set_property -dict [ list CONFIG.CATEGORY {NOC} ] [get_bd_intf_pins /ai_engine_0/S00_AXI]

# Create instance: ConfigNoc, and set properties
set ConfigNoc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc ConfigNoc ]
set_property -dict [list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_NSI {1} CONFIG.NUM_SI {0} ] $ConfigNoc
set_property -dict [list CONFIG.DATA_WIDTH {128} CONFIG.CATEGORY {aie}] [get_bd_intf_pins /ConfigNoc/M00_AXI]
set_property -dict [list CONFIG.INI_STRATEGY {load} CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} } ] [get_bd_intf_pins ConfigNoc/S00_INI]
set_property -dict [list CONFIG.ASSOCIATED_BUSIF {M00_AXI} ] [get_bd_pins /ConfigNoc/aclk0]  

connect_bd_intf_net -intf_net ConfigNoc_M00_AXI [get_bd_intf_pins ConfigNoc/M00_AXI] [get_bd_intf_pins ai_engine_0/S00_AXI]
connect_bd_net -net ai_engine_0_s00_axi_aclk [get_bd_pins ConfigNoc/aclk0] [get_bd_pins ai_engine_0/s00_axi_aclk] 
connect_bd_intf_net -intf_net AIE_CTRL_INI_1 [get_bd_intf_ports AIE_CTRL_INI] [get_bd_intf_pins ConfigNoc/S00_INI]

# Create address segments
assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces AIE_CTRL_INI] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force }

# Cclocks optins, and set properties
set clk_freqs [ list 100.000 150.000 300.000 100.000 100.000 100.000 100.000 ]
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
set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_0 ]
set_property -dict [ list \
 CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
 CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
 CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
 CONFIG.CLKOUT_PORT [join $clk_ports ","] \
 CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
 CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [join $clk_freqs ","] \
 CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
 CONFIG.CLKOUT_USED [join $clk_used "," ]\
 CONFIG.JITTER_SEL {Min_O_Jitter} \
 CONFIG.RESET_TYPE {ACTIVE_LOW} \
 CONFIG.USE_LOCKED {true} \
 CONFIG.USE_PHASE_ALIGNMENT {true} \
 CONFIG.USE_RESET {true} \
 ] $clk_wizard_0

set_property CONFIG.PRIM_SOURCE {No_buffer} [get_bd_cells clk_wizard_0]

# Create port, and set properties
set Interrupt [ create_bd_port -dir O -from 31 -to 0 -type intr Interrupt ]
set_property -dict [ list CONFIG.PortWidth {32} ] $Interrupt

# Create instance: xlconcat_1, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:* xlconcat_1
set_property -dict [list CONFIG.NUM_PORTS {32} CONFIG.IN0_WIDTH {1}] [get_bd_cells xlconcat_1]

connect_bd_net -net xlconcat_1_dout [get_bd_ports Interrupt] [get_bd_pins xlconcat_1/dout]

if { $use_cascaded_irqs } {

set Interrupt1 [ create_bd_port -dir O -from 30 -to 0 -type intr Interrupt1 ]
set_property -dict [ list CONFIG.PortWidth {31} ] $Interrupt1

# Create instance: xlconcat_2, and set properties
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:* xlconcat_2
set_property -dict [list CONFIG.NUM_PORTS {31} CONFIG.IN0_WIDTH {1}] [get_bd_cells xlconcat_2]

connect_bd_net -net xlconcat_2_dout [get_bd_ports Interrupt1] [get_bd_pins xlconcat_2/dout]
}

for {set i 0} {$i < $num_clks} {incr i} {
    # Create instance: proc_sys_reset_N, and set properties
    set proc_sys_reset_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_$i ]
  }

for {set i 0} {$i < $num_clks} {incr i} {
    connect_bd_net -net CIPS_0_pl_resetn1 [get_bd_pins proc_sys_reset_$i/ext_reset_in]
}
  
connect_bd_net [get_bd_ports ExtClk] [get_bd_pins clk_wizard_0/clk_in1]
connect_bd_net [get_bd_ports ExtReset] [get_bd_pins clk_wizard_0/resetn]

# Create instance: icn_ctrl, and set properties
set icn_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_1 ]

set default_clock_net clk_wizard_0_$default_clk_port
  

# Create instance: icn_ctrl, and set properties
set num_masters [ expr "$use_cascaded_irqs ? 4 : 2" ]
set num_kernal [ expr "$use_cascaded_irqs ? 4 : 2" ]
#set m_incr [ expr "$use_cascaded_irqs ? 2 : 1" ]
set_property -dict [ list CONFIG.NUM_CLKS {2} CONFIG.NUM_MI $num_masters CONFIG.NUM_SI {1} ] $icn_ctrl_1
  
  for {set i 0} {$i < $num_kernal} {incr i} {
	set to_delete_kernel_ctrl_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel_ctrl_$i ]
	set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] [get_bd_cells to_delete_kernel_ctrl_$i]
	set m [expr $i+2]
	set icn_ctrl_$m [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_$m ]
	set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} ] [get_bd_cells icn_ctrl_$m]
	#set m [expr $i]
	connect_bd_intf_net [get_bd_intf_pins icn_ctrl_1/M0${i}_AXI] [get_bd_intf_pins icn_ctrl_$m/S00_AXI]
	connect_bd_intf_net [get_bd_intf_pins to_delete_kernel_ctrl_$i/S_AXI] [get_bd_intf_pins icn_ctrl_$m/M00_AXI]
	connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins to_delete_kernel_ctrl_$i/aresetn]
	connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins icn_ctrl_$m/aresetn]
	connect_bd_net -net $default_clock_net [get_bd_pins icn_ctrl_$m/aclk]
	connect_bd_net -net $default_clock_net [get_bd_pins to_delete_kernel_ctrl_$i/aclk]
} 
 
for {set i 0} {$i < $num_clks} {incr i} {
    set port [lindex $clk_ports $i]
    connect_bd_net -net clk_wizard_0_$port [get_bd_pins clk_wizard_0/$port] [get_bd_pins proc_sys_reset_$i/slowest_sync_clk]
	}

connect_bd_net -net clk_wizard_0_locked [get_bd_pins clk_wizard_0/locked]

for {set i 0} {$i < $num_clks} {incr i} {
    connect_bd_net -net clk_wizard_0_locked [get_bd_pins proc_sys_reset_$i/dcm_locked] 
  }

connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins proc_sys_reset_${default_clk_num}/peripheral_aresetn] [get_bd_pins icn_ctrl_1/aresetn] 

# Create interface connections
connect_bd_intf_net -intf_net Conn3 [get_bd_intf_ports DDR_3] [get_bd_intf_pins DDRNoc/M03_INI]
connect_bd_intf_net -intf_net DDRNoc_M00_INI [get_bd_intf_ports DDR_0] [get_bd_intf_pins DDRNoc/M00_INI]
connect_bd_intf_net -intf_net DDRNoc_M01_INI [get_bd_intf_ports DDR_1] [get_bd_intf_pins DDRNoc/M01_INI]
connect_bd_intf_net -intf_net DDRNoc_M02_INI [get_bd_intf_ports DDR_2] [get_bd_intf_pins DDRNoc/M02_INI]
connect_bd_net [get_bd_ports ExtClk] [get_bd_pins DDRNoc/aclk0]
connect_bd_intf_net -intf_net IsoRegDynam_M_AXI [get_bd_intf_pins IsoRegDynamic/M_AXI] [get_bd_intf_pins icn_ctrl_1/S00_AXI]
connect_bd_intf_net -intf_net PL_CTRL_S_AXI_1 [get_bd_intf_ports PL_CTRL_S_AXI] [get_bd_intf_pins IsoRegDynamic/S_AXI]

connect_bd_net [get_bd_ports ExtReset] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins IsoReset_0/ext_reset_in]
connect_bd_net -net IsoReset_peripheral_aresetn [get_bd_pins IsoRegDynamic/aresetn] [get_bd_pins IsoReset_0/peripheral_aresetn]

#connect_bd_net [get_bd_pins icn_ctrl_1/aclk] [get_bd_pins clk_wizard_0/clk_out${default_clk_num}]
connect_bd_net -net $default_clock_net [get_bd_pins icn_ctrl_1/aclk]
connect_bd_net [get_bd_ports ExtClk] [get_bd_pins IsoRegDynamic/aclk] [get_bd_pins IsoReset_0/slowest_sync_clk]  [get_bd_pins clk_wizard_0/clk_in1] [get_bd_pins icn_ctrl_1/aclk1]

# Create address segments
assign_bd_address -offset 0xA7000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PL_CTRL_S_AXI] [get_bd_addr_segs to_delete_kernel_ctrl_0/S_AXI/Reg] -force
assign_bd_address -offset 0xA8000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PL_CTRL_S_AXI] [get_bd_addr_segs to_delete_kernel_ctrl_1/S_AXI/Reg] -force
if { $use_cascaded_irqs } {
assign_bd_address -offset 0xA9000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PL_CTRL_S_AXI] [get_bd_addr_segs to_delete_kernel_ctrl_2/S_AXI/Reg] -force
assign_bd_address -offset 0xAA000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces PL_CTRL_S_AXI] [get_bd_addr_segs to_delete_kernel_ctrl_3/S_AXI/Reg] -force }

regenerate_bd_layout
validate_bd_design
save_bd_design
