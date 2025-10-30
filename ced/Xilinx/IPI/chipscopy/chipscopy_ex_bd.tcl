

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.2
set current_vivado_version [version -short]





# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design_vck190 { parentCell } {

  variable script_folder
  variable design_name
  puts "beginning create_root_design"

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
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

  set ddr4_dimm1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_dimm1 ]

  set ddr4_dimm1_sma_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ddr4_dimm1_sma_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $ddr4_dimm1_sma_clk


  # Create ports
  puts "creating noc"
  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 axi_noc_0 ]
set_property -dict [list \
  CONFIG.CH0_DDR4_0_BOARD_INTERFACE {ddr4_dimm1} \
  CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
  CONFIG.MC_EN_INTR_RESP {TRUE} \
  CONFIG.MC_INPUTCLK0_PERIOD {5000} \
  CONFIG.MC_MEMORY_DEVICETYPE {UDIMMs} \
  CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
  CONFIG.NUM_CLKS {8} \
  CONFIG.NUM_MCP {4} \
  CONFIG.NUM_MI {2} \
  CONFIG.NUM_SI {7} \
  CONFIG.sys_clk0_BOARD_INTERFACE {ddr4_dimm1_sma_clk} \
] $axi_noc_0

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_8000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x40} \
   CONFIG.CATEGORY {pl} \
   CONFIG.PHYSICAL_LOC {NOC_NMU512_X0Y0} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80:M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk7]

  # Create instance: clk_wizard_0, and set properties
  set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard:1.0 clk_wizard_0 ]
  set_property -dict [ list \
   CONFIG.BANDWIDTH {OPTIMIZED} \
   CONFIG.CLKFBOUT_MULT {27.000000} \
   CONFIG.CLKOUT1_DIVIDE {24.000000} \
   CONFIG.CLKOUT2_DIVIDE {30.000000} \
   CONFIG.CLKOUT3_DIVIDE {15.000000} \
   CONFIG.CLKOUT4_DIVIDE {9.000000} \
   CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
   CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
   CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
   CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
   CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
   CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
   CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {125.000,100.000,200.000,333.000,100.000,100.000,100.000} \
   CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
   CONFIG.CLKOUT_USED {true,true,true,true,false,false,false} \
   CONFIG.DIVCLK_DIVIDE {3} \
   CONFIG.SECONDARY_IN_FREQ {240.000} \
   CONFIG.USE_LOCKED {true} \
 ] $clk_wizard_0

  puts "creating counters"
  # Create instance: counters
  create_hier_cell_counters [current_bd_instance .] counters

  # Create instance: noc_tg_bc
  create_hier_cell_noc_tg_bc [current_bd_instance .] noc_tg_bc

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.DDR_MEMORY_MODE {Custom} \
    CONFIG.DEVICE_INTEGRITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Custom} \
      DEVICE_INTEGRITY_MODE {Custom} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_MEAS33 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCAUX} {SUPPLY_NUM 0}} \
      SMON_MEAS56 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PMC} {SUPPLY_NUM 1}} \
      SMON_MEAS57 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSFP} {SUPPLY_NUM 3}} \
      SMON_MEAS58 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSLP} {SUPPLY_NUM 2}} \
      SMON_MEAS60 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_SOC} {SUPPLY_NUM 4}} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] $versal_cips_0


  # Must create quads after CIPs as the apb3 clk is connected to pl_out_clk

      # Create instance: gty_quad_105
  create_quad [current_bd_instance .] gty_quad_105 X0Y10 GTY 10.3125 156.25 
  
   # Create instance: gty_quad_201
  create_quad [current_bd_instance .] gty_quad_201 X1Y2 GTY 10.3125 100.0
  
   # Create instance: gty_quad_204
  create_quad [current_bd_instance .] gty_quad_204 X1Y8 GTY 16.0 100.0
  
   # Create instance: gty_quad_205
  create_quad [current_bd_instance .] gty_quad_205 X1Y10 GTY 25.0 100.0
  
  # Create interface connections
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_ports ddr4_dimm1] [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
  # constrain DDRMC to X0Y0 !!
  set_property -dict [list CONFIG.PHYSICAL_LOC {DDRMC_X0Y0}] [get_bd_intf_pins /axi_noc_0/CH0_DDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins noc_tg_bc/SLOT_0_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets axi_noc_0_M00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins noc_tg_bc/S00_AXI]
  
  connect_bd_intf_net -intf_net ddr4_dimm1_sma_clk_1 [get_bd_intf_ports ddr4_dimm1_sma_clk] [get_bd_intf_pins axi_noc_0/sys_clk0]
  
  connect_bd_intf_net -intf_net noc_tg_M_AXI [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins noc_tg_bc/M_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S06_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]

  # Create port connections
  connect_bd_net -net clk_wizard_0_clk_out1 [get_bd_pins axi_noc_0/aclk6] [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins gty_quad_105/apb3clk] [get_bd_pins gty_quad_201/apb3clk] [get_bd_pins gty_quad_204/apb3clk] [get_bd_pins gty_quad_205/apb3clk] [get_bd_pins noc_tg_bc/pclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net clk_wizard_0_clk_out2 [get_bd_pins clk_wizard_0/clk_out2] [get_bd_pins counters/clk100]
  connect_bd_net -net clk_wizard_0_clk_out3 [get_bd_pins clk_wizard_0/clk_out3] [get_bd_pins counters/clk200]
  connect_bd_net -net clk_wizard_0_clk_out4 [get_bd_pins axi_noc_0/aclk7] [get_bd_pins clk_wizard_0/clk_out4] [get_bd_pins noc_tg_bc/clk]
  connect_bd_net -net clk_wizard_0_locked [get_bd_pins clk_wizard_0/locked] [get_bd_pins counters/locked]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins noc_tg_bc/aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_zzz_peripheral_aresetn [get_bd_pins noc_tg_bc/rst_n] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk [get_bd_pins axi_noc_0/aclk2] [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk [get_bd_pins axi_noc_0/aclk3] [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins axi_noc_0/aclk4] [get_bd_pins versal_cips_0/lpd_axi_noc_clk]
  connect_bd_net -net versal_cips_0_pl0_ref_clk1 [get_bd_pins clk_wizard_0/clk_in1] [get_bd_pins versal_cips_0/pl0_ref_clk]
  connect_bd_net -net versal_cips_0_pl0_resetn [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins versal_cips_0/pl0_resetn]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk5] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x020180000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S02_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S02_AXI/C1_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S03_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S03_AXI/C2_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x020100000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020180000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/noc_tg/Data] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/noc_tg/Data] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW1] -force  
  
  # Perform GUI Layout
 regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.5",
   "Default View_TopLeft":"-300,-150",
   "DisplayHardenedConnections":"1",
   "DisplayPinAutomationMissing":"1",
   "DisplayPinsOfHiddenNets":"1",
   "DisplayTieOff":"1",
   "ExpandedHierarchyInLayout":"",
   "comment_0":"ChipScoPy Configurable Example Design (CED)
-----------------------------------------------------------------
This CED targets the VCK190 evaluation board and is designed 
to be used with the ChipScoPy API examples found at 
https://xilinx.github.com/chipscopy

This design includes support for the following API examples:
- GTY transceivers for IBERT API examples
- DDR4 memory controller for DDRMC API examples
- SysMon voltage and temp sensors for SysMon API examples
- NoC, traffic generator, and BRAM controller for 
  NoC Perfmon API examples
- Binary counters and DDS cores for ILA and VIO API examples",
   "commentid":"comment_0|",
   "fillcolor_comment_0":"",
   "font_comment_0":"15",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace cgraphic comment_0 place top -250 -80 textcolor 4 linecolor 3 linewidth 2
",
   "linecolor_comment_0":"#000080",
   "textcolor_comment_0":"#800000"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design_vck190()

proc create_root_design_vpk120 { parentCell } {
  # Procedure to create entire design; Provide argument to make

  variable script_folder
  variable design_name
  puts "beginning create_root_design"

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
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

  
  
  set lpddr4_clk1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 lpddr4_clk1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $lpddr4_clk1

  set ch0_lpddr4_trip1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch0_lpddr4_trip1 ]

  set ch1_lpddr4_trip1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch1_lpddr4_trip1 ]


  # Create ports
  puts "creating noc"
   set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 axi_noc_0 ]
  set_property -dict [list \
    CONFIG.CH0_LPDDR4_0_BOARD_INTERFACE {ch0_lpddr4_trip1} \
    CONFIG.CH1_LPDDR4_0_BOARD_INTERFACE {ch1_lpddr4_trip1} \
    CONFIG.MC1_FLIPPED_PINOUT {true} \
    CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
    CONFIG.MC_DM_WIDTH {4} \
    CONFIG.MC_DQS_WIDTH {4} \
    CONFIG.MC_DQ_WIDTH {32} \
    CONFIG.MC_EN_INTR_RESP {TRUE} \
    CONFIG.MC_SYSTEM_CLOCK {Differential} \
    CONFIG.NUM_CLKS {8} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {7} \
    CONFIG.sys_clk0_BOARD_INTERFACE {lpddr4_clk1} \
  ] $axi_noc_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_8000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x40} \
   CONFIG.CATEGORY {pl} \
   CONFIG.PHYSICAL_LOC {NOC_NMU512_X0Y0} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80:M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk7]

  # Create instance: clk_wizard_0, and set properties
  set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard:1.0 clk_wizard_0 ]
  set_property -dict [ list \
   CONFIG.BANDWIDTH {OPTIMIZED} \
   CONFIG.CLKFBOUT_MULT {27.000000} \
   CONFIG.CLKOUT1_DIVIDE {24.000000} \
   CONFIG.CLKOUT2_DIVIDE {30.000000} \
   CONFIG.CLKOUT3_DIVIDE {15.000000} \
   CONFIG.CLKOUT4_DIVIDE {9.000000} \
   CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
   CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
   CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
   CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
   CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
   CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
   CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {125.000,100.000,200.000,333.000,100.000,100.000,100.000} \
   CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
   CONFIG.CLKOUT_USED {true,true,true,true,false,false,false} \
   CONFIG.DIVCLK_DIVIDE {3} \
   CONFIG.SECONDARY_IN_FREQ {240.000} \
   CONFIG.USE_LOCKED {true} \
 ] $clk_wizard_0

  puts "creating counters"
  # Create instance: counters
  create_hier_cell_counters [current_bd_instance .] counters

  # Create instance: noc_tg_bc
  create_hier_cell_noc_tg_bc [current_bd_instance .] noc_tg_bc

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
set_property -dict [list \
  CONFIG.DEVICE_INTEGRITY_MODE {Custom} \
  CONFIG.PS_PMC_CONFIG { \
    CLOCK_MODE {Custom} \
    DDR_MEMORY_MODE {Custom} \
    DEVICE_INTEGRITY_MODE {Custom} \
    PMC_USE_PMC_NOC_AXI0 {1} \
    PS_NUM_FABRIC_RESETS {1} \
    PS_USE_FPD_CCI_NOC {1} \
    PS_USE_NOC_LPD_AXI0 {1} \
    PS_USE_PMCPL_CLK0 {1} \
    SMON_ALARMS {Set_Alarms_On} \
    SMON_ENABLE_TEMP_AVERAGING {0} \
    SMON_MEAS36 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCAUX} {SUPPLY_NUM 0}} \
    SMON_MEAS58 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PMC} {SUPPLY_NUM 1}} \
    SMON_MEAS59 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSFP} {SUPPLY_NUM 3}} \
    SMON_MEAS60 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSLP} {SUPPLY_NUM 2}} \
    SMON_MEAS62 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_SOC} {SUPPLY_NUM 4}} \
    SMON_TEMP_AVERAGING_SAMPLES {0} \
  } \
] $versal_cips_0


  # Must create quads after CIPs as the apb3 clk is connected to pl_out_clk

      # Create instance: gtyp_quad_200
  create_quad [current_bd_instance .] gtyp_quad_200 X1Y0 GTYP 25.0 100.0
  
   # Create instance: gtyp_quad_201
  create_quad [current_bd_instance .] gtyp_quad_201 X1Y2 GTYP 16.0 100.0
  
   # Create instance: gtm_quad_204
  create_quad [current_bd_instance .] gtm_quad_204 X0Y4 GTM 56.42 156.25
  
   # Create instance: gtm_quad_205
  create_quad [current_bd_instance .] gtm_quad_205 X0Y6 GTM 56.42 156.25
  
   # Create interface connections
  connect_bd_intf_net -intf_net axi_noc_0_CH0_LPDDR4_0 [get_bd_intf_ports ch0_lpddr4_trip1] [get_bd_intf_pins axi_noc_0/CH0_LPDDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_CH1_LPDDR4_0 [get_bd_intf_ports ch1_lpddr4_trip1] [get_bd_intf_pins axi_noc_0/CH1_LPDDR4_0]
  connect_bd_intf_net -intf_net lpddr4_clk1_1 [get_bd_intf_ports lpddr4_clk1] [get_bd_intf_pins axi_noc_0/sys_clk0]  
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins noc_tg_bc/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins noc_tg_bc/S00_AXI]
  set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {axi_noc_0_M00_AXI}]
  connect_bd_intf_net -intf_net noc_tg_M_AXI [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins noc_tg_bc/M_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S06_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]

  # Create port connections
  connect_bd_net -net clk_wizard_0_clk_out1 [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins axi_noc_0/aclk6] [get_bd_pins gtyp_quad_200/apb3clk] [get_bd_pins gtyp_quad_201/apb3clk] [get_bd_pins gtm_quad_204/apb3clk] [get_bd_pins gtm_quad_205/apb3clk] [get_bd_pins noc_tg_bc/pclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net clk_wizard_0_clk_out2 [get_bd_pins clk_wizard_0/clk_out2] [get_bd_pins counters/clk100]
  connect_bd_net -net clk_wizard_0_clk_out3 [get_bd_pins clk_wizard_0/clk_out3] [get_bd_pins counters/clk200]
  connect_bd_net -net clk_wizard_0_clk_out4 [get_bd_pins axi_noc_0/aclk7] [get_bd_pins clk_wizard_0/clk_out4] [get_bd_pins noc_tg_bc/clk]
  connect_bd_net -net clk_wizard_0_locked [get_bd_pins clk_wizard_0/locked] [get_bd_pins counters/locked]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins noc_tg_bc/aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_zzz_peripheral_aresetn [get_bd_pins noc_tg_bc/rst_n] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk [get_bd_pins axi_noc_0/aclk2] [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk [get_bd_pins axi_noc_0/aclk3] [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins axi_noc_0/aclk4] [get_bd_pins versal_cips_0/lpd_axi_noc_clk]
  connect_bd_net -net versal_cips_0_pl0_ref_clk1 [get_bd_pins clk_wizard_0/clk_in1] [get_bd_pins versal_cips_0/pl0_ref_clk]
  connect_bd_net -net versal_cips_0_pl0_resetn [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins versal_cips_0/pl0_resetn]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk5] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x020180000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S02_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S02_AXI/C1_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S03_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S03_AXI/C2_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x020100000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020180000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/noc_tg/Data] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/noc_tg/Data] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW1] -force


  # Perform GUI Layout
 regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.5",
   "Default View_TopLeft":"-300,-150",
   "DisplayHardenedConnections":"1",
   "DisplayPinAutomationMissing":"1",
   "DisplayPinsOfHiddenNets":"1",
   "DisplayTieOff":"1",
   "ExpandedHierarchyInLayout":"",
   "comment_0":"ChipScoPy Configurable Example Design (CED)
-----------------------------------------------------------------
This CED targets the VPK120 evaluation board and is designed 
to be used with the ChipScoPy API examples found at 
https://xilinx.github.com/chipscopy

This design includes support for the following API examples:
- GTYP and GTM transceivers for IBERT API examples
- LPDDR4 memory controller for DDRMC API examples
- SysMon voltage and temp sensors for SysMon API examples
- NoC, traffic generator, and BRAM controller for 
  NoC Perfmon API examples
- Binary counters and DDS cores for ILA and VIO API examples",
   "commentid":"comment_0|",
   "fillcolor_comment_0":"",
   "font_comment_0":"15",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace cgraphic comment_0 place top -250 -80 textcolor 4 linecolor 3 linewidth 2
",
   "linecolor_comment_0":"#000080",
   "textcolor_comment_0":"#800000"
}
  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}

proc create_root_design_vhk158 { parentCell } {

  variable script_folder
  variable design_name
  puts "beginning create_root_design"

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
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



  set ddr4_dimm0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_dimm0 ]

  set ddr4_dimm0_sma_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ddr4_dimm0_sma_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $ddr4_dimm0_sma_clk


  # Create ports
  puts "creating noc"
  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 axi_noc_0 ]
    set_property -dict [list \
    CONFIG.CH0_DDR4_0_BOARD_INTERFACE {ddr4_dimm0} \
    CONFIG.HBM_NUM_CHNL {1} \
    CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
    CONFIG.MC_INPUTCLK0_PERIOD {5000} \
    CONFIG.MC_MEMORY_DEVICETYPE {RDIMMs} \
    CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
    CONFIG.MC_PARITY {true} \
    CONFIG.MC_ROWADDRESSWIDTH {17} \
    CONFIG.MC_WRITE_DM_DBI {NONE} \
    CONFIG.NUM_CLKS {8} \
    CONFIG.NUM_HBM_BLI {2} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {7} \
    CONFIG.sys_clk0_BOARD_INTERFACE {ddr4_dimm0_sma_clk} \
  ] $axi_noc_0

  set_property -dict [ list \
   CONFIG.CONNECTIONS {HBM0_PORT0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl_hbm} \
 ] [get_bd_intf_pins /axi_noc_0/HBM00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {HBM0_PORT2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl_hbm} \
 ] [get_bd_intf_pins /axi_noc_0/HBM01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_8000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x40} \
   CONFIG.CATEGORY {pl} \
   CONFIG.PHYSICAL_LOC {NOC_NMU512_X0Y0} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80:M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk7]

  # Create instance: clk_wizard_0, and set properties
  set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard:1.0 clk_wizard_0 ]
  set_property -dict [ list \
   CONFIG.BANDWIDTH {OPTIMIZED} \
   CONFIG.CLKFBOUT_MULT {27.000000} \
   CONFIG.CLKOUT1_DIVIDE {24.000000} \
   CONFIG.CLKOUT2_DIVIDE {30.000000} \
   CONFIG.CLKOUT3_DIVIDE {15.000000} \
   CONFIG.CLKOUT4_DIVIDE {9.000000} \
   CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
   CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
   CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
   CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
   CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
   CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
   CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {125.000,100.000,200.000,333.000,100.000,100.000,100.000} \
   CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
   CONFIG.CLKOUT_USED {true,true,true,true,false,false,false} \
   CONFIG.DIVCLK_DIVIDE {3} \
   CONFIG.SECONDARY_IN_FREQ {240.000} \
   CONFIG.USE_LOCKED {true} \
 ] $clk_wizard_0

  puts "creating counters"
  # Create instance: counters
  create_hier_cell_counters [current_bd_instance .] counters

  # Create instance: noc_tg_bc
  create_hier_cell_hbm_noc_tg_bc [current_bd_instance .] noc_tg_bc

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]  
  set_property -dict [list \
    CONFIG.DEVICE_INTEGRITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Custom} \
      DEVICE_INTEGRITY_MODE {Custom} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_MEAS66 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCAUX} {SUPPLY_NUM 3}} \
      SMON_MEAS88 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PMC} {SUPPLY_NUM 4}} \
      SMON_MEAS89 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSFP} {SUPPLY_NUM 0}} \
      SMON_MEAS90 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSLP} {SUPPLY_NUM 1}} \
      SMON_MEAS92 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_SOC} {SUPPLY_NUM 2}} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] $versal_cips_0

  # Must create quads after CIPs as the apb3 clk is connected to pl_out_clk
      # Create instance: gtyp_quad_200
  create_quad [current_bd_instance .] gtyp_quad_200 X1Y0 GTYP 25.0 100.0

   # Create instance: gtyp_quad_201
  create_quad [current_bd_instance .] gtyp_quad_201 X1Y2 GTYP 16.0 100.0

   # Create instance: gtm_quad_204
  create_quad [current_bd_instance .] gtm_quad_204 X0Y4 GTM 56.42 156.25

   # Create instance: gtm_quad_205
  create_quad [current_bd_instance .] gtm_quad_205 X0Y6 GTM 56.42 156.25


  # Create interface connections
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_ports ddr4_dimm0] [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
  set_property -dict [list CONFIG.PHYSICAL_LOC {DDRMC_X0Y0}] [get_bd_intf_pins /axi_noc_0/CH0_DDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins noc_tg_bc/SLOT_0_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets axi_noc_0_M00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins noc_tg_bc/S00_AXI]

  connect_bd_intf_net -intf_net ddr4_dimm1_sma_clk_1 [get_bd_intf_ports ddr4_dimm0_sma_clk] [get_bd_intf_pins axi_noc_0/sys_clk0]

  connect_bd_intf_net -intf_net noc_tg_M_AXI [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins noc_tg_bc/M_AXI]
  connect_bd_intf_net -intf_net noc_tg_bc_HBM00_AXI [get_bd_intf_pins noc_tg_bc/HBM00_AXI] [get_bd_intf_pins axi_noc_0/HBM00_AXI]
  connect_bd_intf_net -intf_net noc_tg_bc_HBM01_AXI [get_bd_intf_pins noc_tg_bc/HBM01_AXI] [get_bd_intf_pins axi_noc_0/HBM01_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S06_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]

  # Create port connections
  connect_bd_net -net clk_wizard_0_clk_out1 [get_bd_pins axi_noc_0/aclk6] [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins gtyp_quad_200/apb3clk] [get_bd_pins gtyp_quad_201/apb3clk] [get_bd_pins gtm_quad_204/apb3clk] [get_bd_pins gtm_quad_205/apb3clk] [get_bd_pins noc_tg_bc/pclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net clk_wizard_0_clk_out2 [get_bd_pins clk_wizard_0/clk_out2] [get_bd_pins counters/clk100]
  connect_bd_net -net clk_wizard_0_clk_out3 [get_bd_pins clk_wizard_0/clk_out3] [get_bd_pins counters/clk200]
  connect_bd_net -net clk_wizard_0_clk_out4 [get_bd_pins axi_noc_0/aclk7] [get_bd_pins clk_wizard_0/clk_out4] [get_bd_pins noc_tg_bc/clk]
  connect_bd_net -net clk_wizard_0_locked [get_bd_pins clk_wizard_0/locked] [get_bd_pins counters/locked]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins noc_tg_bc/aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_zzz_peripheral_aresetn [get_bd_pins noc_tg_bc/rst_n] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk [get_bd_pins axi_noc_0/aclk2] [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk [get_bd_pins axi_noc_0/aclk3] [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins axi_noc_0/aclk4] [get_bd_pins versal_cips_0/lpd_axi_noc_clk]
  connect_bd_net -net versal_cips_0_pl0_ref_clk1 [get_bd_pins clk_wizard_0/clk_in1] [get_bd_pins versal_cips_0/pl0_ref_clk]
  connect_bd_net -net versal_cips_0_pl0_resetn [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins versal_cips_0/pl0_resetn]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk5] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x020180000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S02_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S02_AXI/C1_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S03_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S03_AXI/C2_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x020100000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020180000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/ddr_tg/Data] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000380000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/ddr_tg/Data] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x004000000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/hbm_tg_0/Data] [get_bd_addr_segs axi_noc_0/HBM00_AXI/HBM0_PC0] -force
  assign_bd_address -offset 0x004040000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/hbm_tg_1/Data] [get_bd_addr_segs axi_noc_0/HBM01_AXI/HBM0_PC1] -force


  # Perform GUI Layout
 regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.5",
   "Default View_TopLeft":"-300,-150",
   "DisplayHardenedConnections":"1",
   "DisplayPinAutomationMissing":"1",
   "DisplayPinsOfHiddenNets":"1",
   "DisplayTieOff":"1",
   "ExpandedHierarchyInLayout":"",
   "comment_0":"ChipScoPy Configurable Example Design (CED)
-----------------------------------------------------------------
This CED targets the VHK158 evaluation board and is designed 
to be used with the ChipScoPy API examples found at 
https://xilinx.github.com/chipscopy

This design includes support for the following API examples:
- GTYP and GTM transceivers for IBERT API examples
- DDR4 memory controller for DDRMC API examples
- SysMon voltage and temp sensors for SysMon API examples
- NoC, traffic generator, and BRAM controller for 
  NoC Perfmon API examples
- Binary counters and DDS cores for ILA and VIO API examples",
   "commentid":"comment_0|",
   "fillcolor_comment_0":"",
   "font_comment_0":"15",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace cgraphic comment_0 place top -250 -220 textcolor 4 linecolor 3 linewidth 2
",
   "linecolor_comment_0":"#000080",
   "textcolor_comment_0":"#800000"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}

proc create_root_design_vek280 { parentCell } {

  variable script_folder
  variable design_name
  puts "beginning create_root_design"

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
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

  
  
  set lpddr4_clk1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 lpddr4_clk1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $lpddr4_clk1

  set ch0_lpddr4_trip1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch0_lpddr4_trip1 ]

  set ch1_lpddr4_trip1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch1_lpddr4_trip1 ]


  # Create ports
  puts "creating noc"
   set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 axi_noc_0 ]
  set_property -dict [list \
    CONFIG.CH0_LPDDR4_0_BOARD_INTERFACE {ch0_lpddr4_trip1} \
    CONFIG.CH1_LPDDR4_0_BOARD_INTERFACE {ch1_lpddr4_trip1} \
    CONFIG.MC1_FLIPPED_PINOUT {true} \
    CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
    CONFIG.MC_DM_WIDTH {4} \
    CONFIG.MC_DQS_WIDTH {4} \
    CONFIG.MC_DQ_WIDTH {32} \
    CONFIG.MC_EN_INTR_RESP {TRUE} \
    CONFIG.MC_SYSTEM_CLOCK {Differential} \
    CONFIG.NUM_CLKS {8} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {7} \
    CONFIG.sys_clk0_BOARD_INTERFACE {lpddr4_clk1} \
  ] $axi_noc_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_8000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M00_AXI:0x40} \
   CONFIG.CATEGORY {pl} \
   CONFIG.PHYSICAL_LOC {NOC_NMU512_X0Y0} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 { read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}} M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.DEST_IDS {M01_AXI:0x80:M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk7]

  # Create instance: clk_wizard_0, and set properties
  set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard:1.0 clk_wizard_0 ]
  set_property -dict [ list \
   CONFIG.BANDWIDTH {OPTIMIZED} \
   CONFIG.CLKFBOUT_MULT {27.000000} \
   CONFIG.CLKOUT1_DIVIDE {24.000000} \
   CONFIG.CLKOUT2_DIVIDE {30.000000} \
   CONFIG.CLKOUT3_DIVIDE {15.000000} \
   CONFIG.CLKOUT4_DIVIDE {9.000000} \
   CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
   CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
   CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
   CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
   CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
   CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
   CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {125.000,100.000,200.000,333.000,100.000,100.000,100.000} \
   CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
   CONFIG.CLKOUT_USED {true,true,true,true,false,false,false} \
   CONFIG.DIVCLK_DIVIDE {3} \
   CONFIG.SECONDARY_IN_FREQ {240.000} \
   CONFIG.USE_LOCKED {true} \
 ] $clk_wizard_0

  puts "creating counters"
  # Create instance: counters
  create_hier_cell_counters [current_bd_instance .] counters

  # Create instance: noc_tg_bc
  create_hier_cell_noc_tg_bc [current_bd_instance .] noc_tg_bc

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.DEVICE_INTEGRITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Custom} \
      DEVICE_INTEGRITY_MODE {Custom} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_MEAS24 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCAUX} {SUPPLY_NUM 0}} \
      SMON_MEAS44 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PMC} {SUPPLY_NUM 4}} \
      SMON_MEAS45 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSFP} {SUPPLY_NUM 3}} \
      SMON_MEAS46 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSLP} {SUPPLY_NUM 2}} \
      SMON_MEAS48 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_SOC} {SUPPLY_NUM 1}} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] $versal_cips_0


  # Must create quads after CIPs as the apb3 clk is connected to pl_out_clk

      # Create instance: gty_quad_105
  create_quad [current_bd_instance .] gtyp_quad_106 X0Y8 GTYP 10.3125 156.25 
  
   # Create instance: gty_quad_201
  create_quad [current_bd_instance .] gtyp_quad_204 X1Y4 GTYP 10.3125 100.0
  
   # Create instance: gty_quad_204
  create_quad [current_bd_instance .] gtyp_quad_205 X1Y6 GTYP 16.0 100.0
  
   # Create instance: gty_quad_205
  create_quad [current_bd_instance .] gtyp_quad_206 X1Y8 GTYP 25.0 100.0
  
   # Create interface connections
  connect_bd_intf_net -intf_net axi_noc_0_CH0_LPDDR4_0 [get_bd_intf_ports ch0_lpddr4_trip1] [get_bd_intf_pins axi_noc_0/CH0_LPDDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_CH1_LPDDR4_0 [get_bd_intf_ports ch1_lpddr4_trip1] [get_bd_intf_pins axi_noc_0/CH1_LPDDR4_0]
  connect_bd_intf_net -intf_net lpddr4_clk1_1 [get_bd_intf_ports lpddr4_clk1] [get_bd_intf_pins axi_noc_0/sys_clk0]  
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins noc_tg_bc/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins noc_tg_bc/S00_AXI]
  set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {axi_noc_0_M00_AXI}]
  connect_bd_intf_net -intf_net noc_tg_M_AXI [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins noc_tg_bc/M_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S06_AXI] [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]

  # Create port connections
  connect_bd_net -net clk_wizard_0_clk_out1 [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins axi_noc_0/aclk6] [get_bd_pins gtyp_quad_106/apb3clk] [get_bd_pins gtyp_quad_204/apb3clk] [get_bd_pins gtyp_quad_205/apb3clk] [get_bd_pins gtyp_quad_206/apb3clk] [get_bd_pins noc_tg_bc/pclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net clk_wizard_0_clk_out2 [get_bd_pins clk_wizard_0/clk_out2] [get_bd_pins counters/clk100]
  connect_bd_net -net clk_wizard_0_clk_out3 [get_bd_pins clk_wizard_0/clk_out3] [get_bd_pins counters/clk200]
  connect_bd_net -net clk_wizard_0_clk_out4 [get_bd_pins axi_noc_0/aclk7] [get_bd_pins clk_wizard_0/clk_out4] [get_bd_pins noc_tg_bc/clk]
  connect_bd_net -net clk_wizard_0_locked [get_bd_pins clk_wizard_0/locked] [get_bd_pins counters/locked]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins noc_tg_bc/aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_zzz_peripheral_aresetn [get_bd_pins noc_tg_bc/rst_n] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk [get_bd_pins axi_noc_0/aclk2] [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk [get_bd_pins axi_noc_0/aclk3] [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins axi_noc_0/aclk4] [get_bd_pins versal_cips_0/lpd_axi_noc_clk]
  connect_bd_net -net versal_cips_0_pl0_ref_clk1 [get_bd_pins clk_wizard_0/clk_in1] [get_bd_pins versal_cips_0/pl0_ref_clk]
  connect_bd_net -net versal_cips_0_pl0_resetn [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins versal_cips_0/pl0_resetn]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc_0/aclk5] [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000880000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S01_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x020180000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S02_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x000880000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S02_AXI/C1_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S03_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x000880000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S03_AXI/C2_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x000880000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000880000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000880000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x020100000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020180000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/noc_tg/Data] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000880000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/noc_tg/Data] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW1] -force

  # Perform GUI Layout
 regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.5",
   "Default View_TopLeft":"-300,-150",
   "DisplayHardenedConnections":"1",
   "DisplayPinAutomationMissing":"1",
   "DisplayPinsOfHiddenNets":"1",
   "DisplayTieOff":"1",
   "ExpandedHierarchyInLayout":"",
   "comment_0":"ChipScoPy Configurable Example Design (CED)
-----------------------------------------------------------------
This CED targets the VEK280 evaluation board and is designed 
to be used with the ChipScoPy API examples found at 
https://xilinx.github.com/chipscopy

This design includes support for the following API examples:
- GTYP transceivers for IBERT API examples
- LPDDR4 memory controller for DDRMC API examples
- SysMon voltage and temp sensors for SysMon API examples
- NoC, traffic generator, and BRAM controller for 
  NoC Perfmon API examples
- Binary counters and DDS cores for ILA and VIO API examples",
   "commentid":"comment_0|",
   "fillcolor_comment_0":"",
   "font_comment_0":"15",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace cgraphic comment_0 place top -250 -80 textcolor 4 linecolor 3 linewidth 2
",
   "linecolor_comment_0":"#000080",
   "textcolor_comment_0":"#800000"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}

proc create_root_design_vek385 { parentCell } {
  # Procedure to create entire design; Provide argument to make

  variable script_folder
  variable design_name
  puts "beginning create_root_design"

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
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

  
  
  # Create interface ports
  set ch0_lpddr5 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 ch0_lpddr5 ]

    set lpddr5_clk0_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 lpddr5_clk0_1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {320000000} \
   ] $lpddr5_clk0_1


  # Create ports

  # Create instance: axi_noc2_0, and set properties
  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2:1.1 axi_noc2_0 ]
  set_property -dict [list \
    CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {lpddr5_Controller_c0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {8Gb} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_EXTENDED_DDRMC5E) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {BG} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {10938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {3750} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {25} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {938} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {12} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3127} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {210000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {120000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {210000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {170000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {1GB} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ON_DIE_ECC) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {15} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-8533} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {No_Buffer} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
    CONFIG.MC_CHAN_REGION1 {NONE} \
    CONFIG.NUM_CLKS {12} \
    CONFIG.NUM_MCP {1} \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {11} \
    CONFIG.sys_clk0_BOARD_INTERFACE {Custom} \
  ] $axi_noc2_0


  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x800_0000_0000 4G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc2_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x801_0000_0000 4G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc2_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc2_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins $axi_noc2_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}} M01_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M01_AXI:0x0:M00_AXI:0x40} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins $axi_noc2_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S09_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {false}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc2_0/S10_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk8]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S08_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk9]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S09_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk10]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S10_AXI} \
 ] [get_bd_pins $axi_noc2_0/aclk11]

  # Create instance: clk_wizard_0, and set properties
  set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz:1.0 clk_wizard_0 ]
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {125.000,100.000,200.000,333.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,true,true,true,false,false,false} \
    CONFIG.USE_LOCKED {true} \
  ] $clk_wizard_0

  puts "creating counters"
  # Create instance: counters
  create_hier_cell_counters [current_bd_instance .] counters

  # Create instance: noc_tg_bc
  create_hier_cell_noc_tg_bc [current_bd_instance .] noc_tg_bc

 # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: ps_wizard_0, and set properties
  set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard:1.0 ps_wizard_0 ]
  set_property -dict [list \
    CONFIG.MMI_CONFIG(MMI_GPU_ENABLE) {1} \
    CONFIG.PS11_CONFIG(MMI_GPU_ENABLE) {1} \
    CONFIG.PS11_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
    CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
    CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_NOC) {1} \
    CONFIG.PS11_CONFIG(PS_USE_LPD_AXI_NOC) {1} \
    CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} \
    CONFIG.PS11_CONFIG(SMON_MEAS18) {ENABLE 1 MODE 2V_unipolar NAME VCCAUX AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 0} \
    CONFIG.PS11_CONFIG(SMON_MEAS39) {ENABLE 1 MODE 2V_unipolar NAME VCC_PMC AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 1} \
    CONFIG.PS11_CONFIG(SMON_MEAS40) {ENABLE 1 MODE 2V_unipolar NAME VCC_PSFP AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 2} \
    CONFIG.PS11_CONFIG(SMON_MEAS41) {ENABLE 1 MODE 2V_unipolar NAME VCC_PSLP AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 3} \
    CONFIG.PS11_CONFIG(SMON_MEAS43) {ENABLE 1 MODE 2V_unipolar NAME VCC_SOC AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 4} \
    CONFIG.PS11_CONFIG_APPLIED {1} \
  ] $ps_wizard_0

  set util_ds_buf_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0]


  # Must create quads after CIPs as the apb3 clk is connected to pl_out_clk

      # Create instance: gtyp_quad_200
  create_quad [current_bd_instance .] gtyp_quad_106 X0Y2 GTYP 25.0 100.0
  
   # Create instance: gtyp_quad_201
  create_quad [current_bd_instance .] gtyp_quad_107 X0Y4 GTYP 16.0 100.0
  
   # Create instance: gtm_quad_204
  create_quad [current_bd_instance .] gtyp_quad_205 X1Y0 GTYP 20 156.25
  
   # Create instance: gtm_quad_205
  create_quad [current_bd_instance .] gtyp_quad_206 X1Y2 GTYP 10 156.25
 

  # Create interface connections
  connect_bd_intf_net -intf_net axi_noc2_C0_CH0_LPDDR5_0 [get_bd_intf_ports ch0_lpddr5] [get_bd_intf_pins axi_noc2_0/C0_CH0_LPDDR5] 
  connect_bd_intf_net -intf_net axi_noc2_0_M00_AXI [get_bd_intf_pins axi_noc2_0/M00_AXI] [get_bd_intf_pins noc_tg_bc/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_noc2_0_M01_AXI [get_bd_intf_pins axi_noc2_0/M01_AXI] [get_bd_intf_pins noc_tg_bc/S00_AXI]
  set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {axi_noc2_0_M00_AXI}]
  connect_bd_intf_net -intf_net noc_tg_M_AXI [get_bd_intf_pins axi_noc2_0/S00_AXI] [get_bd_intf_pins noc_tg_bc/M_AXI] 
  connect_bd_intf_net -intf_net ps_wizard_0_LPD_AXI_NOC_0 [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S01_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_PMC_AXI_NOC_0 [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S02_AXI] 
  connect_bd_net [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins axi_noc2_0/sys_clk0]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {lpddr5_clk0_1 ( Lpddr5 Clock 01 ) } Manual_Source {Auto}}  [get_bd_intf_pins util_ds_buf_0/CLK_IN_D] 
    connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins axi_noc2_0/S03_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC1 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins axi_noc2_0/S04_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC2 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC2] [get_bd_intf_pins axi_noc2_0/S05_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC3 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC3] [get_bd_intf_pins axi_noc2_0/S06_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC4 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC4] [get_bd_intf_pins axi_noc2_0/S07_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC5 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC5] [get_bd_intf_pins axi_noc2_0/S08_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC6 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC6] [get_bd_intf_pins axi_noc2_0/S09_AXI]
  connect_bd_intf_net -intf_net ps_wizard_0_FPD_AXI_NOC7 [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC7] [get_bd_intf_pins axi_noc2_0/S10_AXI]

  # Create port connections
  connect_bd_net -net clk_wizard_0_clk_out1 [get_bd_pins clk_wizard_0/clk_out1] [get_bd_pins axi_noc2_0/aclk2] [get_bd_pins gtyp_quad_106/apb3clk] [get_bd_pins gtyp_quad_107/apb3clk] [get_bd_pins gtyp_quad_205/apb3clk] [get_bd_pins gtyp_quad_206/apb3clk] [get_bd_pins noc_tg_bc/pclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net clk_wizard_0_clk_out2 [get_bd_pins clk_wizard_0/clk_out2] [get_bd_pins counters/clk100]
  connect_bd_net -net clk_wizard_0_clk_out3 [get_bd_pins clk_wizard_0/clk_out3] [get_bd_pins counters/clk200]
  connect_bd_net -net clk_wizard_0_clk_out4 [get_bd_pins axi_noc2_0/aclk3] [get_bd_pins clk_wizard_0/clk_out4] [get_bd_pins noc_tg_bc/clk]
  connect_bd_net -net clk_wizard_0_locked [get_bd_pins clk_wizard_0/locked] [get_bd_pins counters/locked]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins noc_tg_bc/aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_zzz_peripheral_aresetn [get_bd_pins noc_tg_bc/rst_n] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins axi_noc2_0/aclk0] [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins axi_noc2_0/aclk1] [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk]  
  connect_bd_net -net versal_cips_0_pl0_ref_clk1 [get_bd_pins clk_wizard_0/clk_in1] [get_bd_pins ps_wizard_0/pl0_ref_clk]
  connect_bd_net -net versal_cips_0_pl0_resetn [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins ps_wizard_0/pl0_resetn]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc0_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] \
  [get_bd_pins axi_noc2_0/aclk4]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc1_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] \
  [get_bd_pins axi_noc2_0/aclk5]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc2_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc2_clk] \
  [get_bd_pins axi_noc2_0/aclk6]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc3_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc3_clk] \
  [get_bd_pins axi_noc2_0/aclk7]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc4_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc4_clk] \
  [get_bd_pins axi_noc2_0/aclk8]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc5_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc5_clk] \
  [get_bd_pins axi_noc2_0/aclk9]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc6_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc6_clk] \
  [get_bd_pins axi_noc2_0/aclk10]
  connect_bd_net -net ps_wizard_0_fpd_axi_noc7_clk  [get_bd_pins ps_wizard_0/fpd_axi_noc7_clk] \
  [get_bd_pins axi_noc2_0/aclk11]


  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/mmi_0_mmi_gpu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_asu] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x080000000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0] -force
  assign_bd_address -offset 0x080100000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x080000000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0] -force
  assign_bd_address -offset 0x080100000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dma_pmc_1] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x080000000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0] -force
  assign_bd_address -offset 0x080100000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_dpc] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_lpd_dma_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x080000000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0] -force
  assign_bd_address -offset 0x080100000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_pmc_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces noc_tg_bc/noc_tg/Data] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_asu] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_asu] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_0] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_1] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_2] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_3] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_4] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_5] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_6] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexa78_7] [get_bd_addr_segs axi_noc2_0/DDR_MC_PORTS/DDR_CH0_LEGACY]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_1] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_2] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_3] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_4] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_5] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_6] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_7] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_8] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_cortexr52_9] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs noc_tg_bc/noc_bc/S_AXI/Mem0]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces ps_wizard_0/ps11_0_ppu_0] [get_bd_addr_segs noc_tg_bc/noc_sim_trig/SIM_TRIG_MEMORY_MAP/Reg]

  # Perform GUI Layout
 regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.5",
   "Default View_TopLeft":"-300,-150",
   "DisplayHardenedConnections":"1",
   "DisplayPinAutomationMissing":"1",
   "DisplayPinsOfHiddenNets":"1",
   "DisplayTieOff":"1",
   "ExpandedHierarchyInLayout":"",
   "comment_0":"ChipScoPy Configurable Example Design (CED)
-----------------------------------------------------------------
This CED targets the VEK385 evaluation board and is designed 
to be used with the ChipScoPy API examples found at 
https://xilinx.github.com/chipscopy

This design includes support for the following API examples:
- GTYP transceivers for IBERT API examples
- LPDDR5 memory controller for DDRMC API examples
- SysMon voltage and temp sensors for SysMon API examples
- NoC, traffic generator, and BRAM controller for 
  NoC Perfmon API examples
- Binary counters and DDS cores for ILA and VIO API examples",
   "commentid":"comment_0|",
   "fillcolor_comment_0":"",
   "font_comment_0":"15",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace cgraphic comment_0 place top -250 -80 textcolor 4 linecolor 3 linewidth 2
",
   "linecolor_comment_0":"#000080",
   "textcolor_comment_0":"#800000"
}
  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
####

