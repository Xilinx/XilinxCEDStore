# ########################################################################
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
# Licensed under the Apache License, Version 2.0
# ########################################################################
# Shared SoC-platform content (PS peripherals, NoC, optional LPDDR5) reused by
# the CPM6 CEDs. Contains NO CPM6 CTRL0/CTRL1 configuration and no bridge-mode
# (cpm_axi_pl0 / PCIe-AXI-NoC) content.
#
# This is ONE self-contained Tcl file: it sources nothing, needs no other file and no tool. Put it in your CED's platform/ folder and
#   source <ced_dir>/platform/run.tcl
# from your design_1_bd.tcl. Sourcing only defines procedures; nothing changes in the design until you call them.
# Rule: where the platform and your CED set the same thing, YOUR value wins.
#
# Requires in the IP catalog: ps_wizard, axi_noc2:1.1, axi_bram_ctrl, emb_mem_gen, proc_sys_reset.
# No cell names are assumed: every proc takes the PS cell ($ps, the ps_wizard) and the NoC cell ($noc, the axi_noc2) as arguments,
# passed down from the top; platform_auto finds them once, by IP type. (Core address spaces are named pmcps_0_psv_<core> by the ps_wizard.)
#
# SIMPLEST (a design that already has a ps_wizard): just source this file AFTER the block design is built (Tcl console, or the last line
# of your BD script). Nothing else to call. Turn off: set ::platform_auto_disable 1 first.
#   * the design HAS an axi_noc2 (DMA, CXL, RP): it attaches the PS ports to your NoC, gives the PS cores your DDR / NoC-attached memories at
#     your own addresses (cores that cannot reach them are excluded) and validates.
#   * the design has NO axi_noc2 (e.g. the original BMD): it builds everything -- the platform PS peripherals (your own settings win), the NoC with
#     the PS ports, a BRAM on the NoC, the address plan -- and validates. The only choice is DDR: set ::platform_ddr 1 first to add the
#     LPDDR5 DDR (adds top-level ports); without it there is no DDR.
# It does nothing on a design that has no ps_wizard yet, so it is also safe to source at the top of a BD script (USAGE A / B below).
#
# USAGE A -- your CED has no NoC (e.g. BMD). Inside create_root_design:
#   platform_create_ports   $ddr          ;# LPDDR5 / sys_clk ports (only when $ddr is 1)
#   set noc [platform_create_noc $ddr]    ;# NoC cell with the 8 PS ports (+ DDR memory controller), before the PS cell
#   set_property -dict [concat [platform_ps_props] [list <your ps_wizard props>]] $ps_wizard_0   ;# platform FIRST, yours last
#   platform_noc_connect_ps $ps $noc $ddr ;# after the PS cell exists ($ps = your ps_wizard cell)
#   platform_add_bram       $ps $noc      ;# optional: PL BRAM reached through the NoC (adds NoC master M00)
#   platform_assign_addr    $ps $noc $ddr ;# create-mode address plan (DDR @0x0 2G for the 8 PS cores), under "Create address segments"
#   Own ports on top:  platform_noc_add $noc [list [dict create kind master|slave pin <bd pin> clk <clk pin> category pl]]
#
# USAGE B -- your CED already has its own axi_noc2 (e.g. DMA, CXL, RP):
#   set_property -dict [concat [platform_ps_props] [list <your ps_wizard props>]] $ps_wizard_0
#   ... build your own NoC and connections ...
#   platform_noc_attach $ps $noc          ;# adds only the PS ports you have not connected, on the next free indices;
#                                         ;# your own ports / routing / destination IDs are never touched. Turns the 5 PS->NoC
#                                         ;# enables on if you had them off (calling attach is the request for the PS ports).
#   platform_noc_assign_ddr $ps $noc <offset> <range> {<cores>}   ;# your address plan for the PS cores that now reach your DDR
#   platform_noc_exclude_ddr $ps $noc {<cores that cannot reach it>}   ;# e.g. cortexr5_0 cortexr5_1 psm_0
#   (platform_assign_addr is the CREATE-mode address plan, used by BD scripts that call platform_create_noc; platform_auto_plan is the
#    ATTACH/auto-mode plan, which follows the parent's own addresses.)
#
# Procs: platform_ps_props platform_create_ports platform_create_bram platform_noc_create platform_noc_connect_ps
#        platform_noc_add platform_noc_attach platform_noc_route platform_noc_assign_ddr platform_noc_exclude_ddr
#        platform_add_bram platform_create_noc platform_assign_addr platform_auto_plan platform_auto
# Known limits: the RPUs and PSM cannot reach NoC-attached PL memory (their NoC windows are only 0x0 2G and 0xE000_0000 256M).
# Maintained by hand from now on (it was first derived from Versal_CPM6_SoC_Platform_Design/design_1_bd.tcl, 2026-10-13).

# Folder this file was sourced from (the DDR constraints file lives in <platform_dir>/constrs).
set ::platform_dir [file dirname [file normalize [info script]]]

# DDR is created ONLY when the design has none and the user asked for it (::platform_ddr 1):
#   1. the design already has DDR (an axi_noc2 whose memory controller is enabled): the platform does nothing for DDR, ::platform_ddr is ignored
#   2. no DDR and ::platform_ddr is 1: the platform creates the LPDDR5 ports and memory controller and adds the DDR constraints file
#   3. no DDR and DDR not requested: all DDR code is skipped
# 1 if the NoC cell $noc has a memory controller (DDR) enabled.
proc platform_ddr_in_design {noc} {
  if { $noc eq "" } { return 0 }
  set n [get_property CONFIG.NUM_MC $noc]
  return [expr {$n ne "" && $n > 0}]
}

# Add the DDR pin constraints (LPDDR5 + sys_clk0, <platform_dir>/constrs/noc_ddr5_phy_phy.xdc) to constrs_1 once. Only case 2 calls it.
proc platform_add_ddr_xdc {} {
  set x [file join $::platform_dir constrs noc_ddr5_phy_phy.xdc]
  if { ![file exists $x] } { puts "WARNING: platform: DDR constraints file $x not found"; return }
  if { [get_files -quiet [file tail $x]] ne "" } { puts "INFO: platform: DDR constraints file already in the project"; return }
  add_files -fileset constrs_1 -norecurse $x
  import_files -fileset constrs_1 $x
  puts "INFO: platform: DDR constraints file added ($x)"
}

# Common ps_wizard properties. Caller must merge these into its single
# set_property -dict call on ps_wizard_0.
proc platform_ps_props {} {
  return [list \
    CONFIG.CPM6_CONFIG(CPM6_PERIPHERAL_EN) {1} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO40) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION out} \
    CONFIG.PS_PMC_CONFIG(PMC_MIO41) {DRIVE_STRENGTH 8mA SLEW slow PULL pullup SCHMITT 0 AUX_IO 0 USAGE GPIO OUTPUT_DATA default DIRECTION out} \
    CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC1) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_FPD_CCI_NOC) {1} \
    CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {1} \
    CONFIG.PS_PMC_CONFIG(PMC_I2CPMC_PERIPHERAL) {ENABLE 1 IO PMC_MIO_38:39 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_I2C0_PERIPHERAL) {ENABLE 1 IO PMC_MIO_42:43 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_I2C1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_44:45 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_TTC0_WAVEOUT) {ENABLE 1 IO PS_MIO_23 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_ENET0_MDIO) {ENABLE 1 IO PS_MIO_24:25 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_ENET0_PERIPHERAL) {ENABLE 1 IO PS_MIO_0:11 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_USB3_PERIPHERAL) {ENABLE 1 IO PMC_MIO_13:25 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PMC_GPIO_EMIO_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GPIO_EMIO_PERIPHERAL_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PMC_OSPI_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 IO PMC_MIO_0:13 MODE Dual_Stacked} \
    CONFIG.PS_PMC_CONFIG(PS_I2CSYSMON_PERIPHERAL) {ENABLE 0 IO_TYPE MIO IO PS_MIO_13:15} \
    CONFIG.PS_PMC_CONFIG(PMC_SD1_30AD) {CD_ENABLE 1 POW_ENABLE 1 WP_ENABLE 0 RESET_ENABLE 0 CD_IO PMC_MIO_28 POW_IO PMC_MIO_51 WP_IO PMC_MIO_1 RESET_IO PMC_MIO_12 CLK_50_SDR_ITAP_DLY 0x25 CLK_50_SDR_OTAP_DLY 0x4 CLK_50_DDR_ITAP_DLY 0x2A CLK_50_DDR_OTAP_DLY 0x3 CLK_100_SDR_OTAP_DLY 0x3 CLK_200_SDR_OTAP_DLY 0x2} \
    CONFIG.PS_PMC_CONFIG(PMC_SD1_30AD_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 IO PMC_MIO_26:36 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_UART0_BAUD_RATE) {115200} \
    CONFIG.PS_PMC_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PS_MIO_16:17 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_UART1_BAUD_RATE) {115200} \
    CONFIG.PS_PMC_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 1 IO PMC_MIO_46:47 IO_TYPE MIO} \
    CONFIG.PS_PMC_CONFIG(PS_TRISTATE_INVERTED) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
    CONFIG.PS_PMC_CONFIG(SMON_INTERFACE_TO_USE) {PMBus} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS0) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVCCAUX_102 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 96} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS1) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVCCAUX_103 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 97} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS18) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVCC_102 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 78} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS19) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVCC_103 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 79} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS2) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVCCAUX_104 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 98} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS20) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVCC_104 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 80} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS21) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVCC_105 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 114} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS3) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVCCAUX_105 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 99} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS36) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVTT_102 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 0} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS37) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVTT_103 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 61} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS38) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVTT_104 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 62} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS39) {ENABLE 1 MODE 2V_unipolar NAME GTMPW_AVTT_105 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 63} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS54) {ENABLE 1 MODE 2V_unipolar NAME VCCAUX AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 1} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS55) {ENABLE 1 MODE 2V_unipolar NAME VCCAUX_PMC AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 2} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS56) {ENABLE 1 MODE 2V_unipolar NAME VCCAUX_SMON AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 3} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS57) {ENABLE 1 MODE 2V_unipolar NAME VCCINT AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 10} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS58) {ENABLE 1 MODE 4V_unipolar NAME VCCO_500 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 4.00 SUPPLY_NUM 43} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS59) {ENABLE 1 MODE 4V_unipolar NAME VCCO_501 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 4.00 SUPPLY_NUM 44} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS60) {ENABLE 1 MODE 4V_unipolar NAME VCCO_502 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 4.00 SUPPLY_NUM 45} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS61) {ENABLE 1 MODE 4V_unipolar NAME VCCO_503 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 4.00 SUPPLY_NUM 46} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS62) {ENABLE 1 MODE 2V_unipolar NAME VCCO_700 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 47} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS63) {ENABLE 1 MODE 2V_unipolar NAME VCCO_702 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 48} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS64) {ENABLE 1 MODE 2V_unipolar NAME VCCO_704 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 49} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS65) {ENABLE 1 MODE 2V_unipolar NAME VCCO_706 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 50} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS66) {ENABLE 1 MODE 2V_unipolar NAME VCCO_708 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 51} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS67) {ENABLE 1 MODE 2V_unipolar NAME VCCO_710 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 52} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS68) {ENABLE 1 MODE 2V_unipolar NAME VCCO_712 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 53} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS69) {ENABLE 1 MODE 2V_unipolar NAME VCCO_714 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 54} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS70) {ENABLE 1 MODE 2V_unipolar NAME VCCO_716 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 55} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS71) {ENABLE 1 MODE 2V_unipolar NAME VCCO_718 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 56} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS72) {ENABLE 1 MODE 2V_unipolar NAME VCCO_720 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 57} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS73) {ENABLE 1 MODE 2V_unipolar NAME VCCO_722 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 58} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS74) {ENABLE 1 MODE 2V_unipolar NAME VCCO_724 AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 59} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS75) {ENABLE 1 MODE 2V_unipolar NAME VCC_BATT AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 4} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS76) {ENABLE 1 MODE 2V_unipolar NAME VCC_PMC AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 5} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS77) {ENABLE 1 MODE 2V_unipolar NAME VCC_PSFP AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 6} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS78) {ENABLE 1 MODE 2V_unipolar NAME VCC_PSLP AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 7} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS79) {ENABLE 1 MODE 2V_unipolar NAME VCC_RAM AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 8} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS80) {ENABLE 1 MODE 2V_unipolar NAME VCC_SOC AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 2.00 SUPPLY_NUM 9} \
    CONFIG.PS_PMC_CONFIG(SMON_MEAS81) {ENABLE 1 MODE 1V_unipolar NAME VP_VN AVERAGE_EN 0 ALARM_ENABLE 0 ALARM_LOWER 0.00 ALARM_UPPER 1.00 SUPPLY_NUM 11} \
    CONFIG.PS_PMC_CONFIG(SMON_OT) {THRESHOLD_LOWER -50 THRESHOLD_UPPER 125} \
    CONFIG.PS_PMC_CONFIG(SMON_USER_TEMP) {USER_ALARM_TYPE hysteresis THRESHOLD_LOWER -50 THRESHOLD_UPPER 125} \
    CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK1) {1} \
  ]
}

# Interface ports needed by the platform content.
proc platform_create_ports {ddr_enabled} {
  if { $ddr_enabled } {
    set CH0_LPDDR5_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 CH0_LPDDR5_0 ]

    set sys_clk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_0 ]
    set_property -dict [ list \
     CONFIG.FREQ_HZ {319795000} \
     ] $sys_clk0_0
  }
}

# PL BRAM reached by the PS through the NoC (no CPM bridge). Returns the new cells as a dict: mem, ctrl, rst.
proc platform_create_bram {} {
  set emb_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 emb_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.MEMORY_TYPE {Single_Port_RAM} \
  ] $emb_mem_gen_0

  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {128} \
    CONFIG.SINGLE_PORT_BRAM {1} \
    CONFIG.ECC_TYPE {0} \
  ] $axi_bram_ctrl_0

  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
  return [dict create mem $emb_mem_gen_0 ctrl $axi_bram_ctrl_0 rst $proc_sys_reset_0]
}

# ---------------------------------------------------------------------------
# NoC library
#
# The platform owns the PS-facing slave ports of the axi_noc2 cell (table below). A parent CED adds its own ports on
# top with platform_noc_add (slave or master): the port counts, clocks, categories, ASSOCIATED_BUSIF and the
# CONNECTIONS/DEST_IDS routing tables are all computed here, nothing is hardcoded per design.
#
# Two modes:
#   create  platform_noc_create   no NoC in the design yet (e.g. BMD): build it with the PS ports (+ DDR).
#   attach  platform_noc_attach   the parent already has a NoC: add only the PS ports it has not connected, on the
#                                 next free indices, routed to the parent's existing masters / memory controller.
# Where the platform and a parent set the same thing, the parent wins (the parent's own ports, routing and
# destination IDs are never rewritten).
# ---------------------------------------------------------------------------

# State shared by the procs below. The PS and NoC cells themselves are never stored here: every proc that needs them
# takes them as arguments (ps = the ps_wizard cell, noc = the axi_noc2 cell), passed down from the top.
set ::pnoc(owned) {}                 ;# slave ports this file added to the NoC; only these get their routing rewritten
set ::pnoc(ids) [dict create]        ;# master port -> destination ID the parent already uses (attach mode)

# Platform PS -> NoC slave ports, in S00.. order: {ps_wizard interface, its clock pin, NoC category, extra port props}
set ::pnoc_base [list \
  {FPD_AXI_NOC1 fpd_axi_noc1_clk ps_nci {}} \
  {FPD_AXI_NOC0 fpd_axi_noc0_clk ps_nci {}} \
  {PMC_AXI_NOC0 pmc_axi_noc0_clk ps_pmc {}} \
  {LPD_AXI_NOC0 lpd_axi_noc0_clk ps_rpu {CONFIG.R_TRAFFIC_CLASS BEST_EFFORT CONFIG.W_TRAFFIC_CLASS BEST_EFFORT CONFIG.REMAPS {}}} \
  {FPD_CCI_NOC3 fpd_cci_noc3_clk ps_cci {}} \
  {FPD_CCI_NOC2 fpd_cci_noc2_clk ps_cci {}} \
  {FPD_CCI_NOC1 fpd_cci_noc1_clk ps_cci {}} \
  {FPD_CCI_NOC0 fpd_cci_noc0_clk ps_cci {}} \
]

# ps_wizard properties that switch the PS -> NoC interfaces on (also part of platform_ps_props). platform_noc_attach re-applies
# them if the parent has them off: calling attach is the parent's explicit request for these ports.
set ::pnoc_ps_enables [list \
  CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
  CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC0) {1} \
  CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC1) {1} \
  CONFIG.PS_PMC_CONFIG(PS_USE_FPD_CCI_NOC) {1} \
  CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {1} \
]

# Bandwidth/burst attributes of one routing entry. initial_boot is true only for the memory controller.
proc platform_noc_bw {boot} {
  return "read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} initial_boot {$boot}"
}

# (Re)build CONNECTIONS / DEST_IDS of every slave port this file added to $noc: each reaches the memory controller (when the
# NoC has one) and every master port currently on the NoC. Called again whenever a port is added. A master's destination ID is
# the one the parent already uses for it, else index * 0x40.
proc platform_noc_route {noc} {
  set nmi [get_property CONFIG.NUM_MI $noc]
  set has_mc [expr {[get_property CONFIG.NUM_MC $noc] > 0}]
  foreach port $::pnoc(owned) {
    set conns {}
    set ids {}
    if { $has_mc } { lappend conns "MC_0 {[platform_noc_bw true]}" }
    for {set i 0} {$i < $nmi} {incr i} {
      set m [format M%02d_AXI $i]
      lappend conns "$m {[platform_noc_bw false]}"
      if { [dict exists $::pnoc(ids) $m] } { set id [dict get $::pnoc(ids) $m] } else { set id [format 0x%x [expr {$i * 0x40}]] }
      lappend ids "$m:$id"
    }
    set_property -dict [list CONFIG.CONNECTIONS [join $conns " "] CONFIG.DEST_IDS [join $ids ":"]] [get_bd_intf_pins $noc/$port]
  }
}

# Create the NoC cell (axi_noc2_0) with the platform PS ports (and the LPDDR5 memory controller when DDR is on). Returns the NoC cell.
proc platform_noc_create {ddr_enabled} {
  set nb [llength $::pnoc_base]
  set ::pnoc(owned) {}
  set ::pnoc(ids) [dict create]
  set axi_noc2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2:1.1 axi_noc2_0 ]
  if { $ddr_enabled } {
    set_property -dict [list \
    CONFIG.C0_CH0_LPDDR5_BOARD_INTERFACE {Custom} \
    CONFIG.DDR5_DEVICE_TYPE {Components} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ADDRESS_MAP) {NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA3,BA2,BA1,BA0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA,NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_AUTO_PRECHARGE) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BACKGROUND_SCRUB) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BOARD_INTRF_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_BURST_ADDR_WIDTH) {4} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CAL_MASK_POLL) {ENABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_COL_ADDR_WIDTH) {6} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CONFIG13_OPT) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CONTROLLERTYPE) {LPDDR5_SDRAM} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_CRYPTO) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DATA_WIDTH) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_2T) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_PAR_RCD_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_RDIMM_ADDR_MODE) {DDR} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TFAW_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TREFSBRD_SLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC1_DPR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFC2_DPR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DDR5_TRFCSB_DLR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DM_EN) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DQS_OSCI_EN) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_SIZE) {16Gb} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_DRAM_WIDTH) {x16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_EXTENDED_DDRMC5E) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_CL) {64} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_BANK_ARCH) {16B} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TCSPD) {12500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_LP5_TRRD) {5000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_RL) {10} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCCD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TCK) {1087} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TXP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F0_WL) {5} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_CL) {64} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR2_RU) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TCCD_L_WR_RU) {32} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TPD) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRP) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_DDR5_TRRD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_BANK_ARCH) {16B} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TCSPD) {12500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPAB) {21000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRPPB) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_LP5_TRRD) {5000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_RL) {10} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCCD_L) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TCK) {2500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TFAW) {15000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRAS) {42000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRCD) {18000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TRTP_RU) {24} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TXP) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_TZQLAT) {30000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_F1_WL) {5} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_FREQ_SWITCHING) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INIT_TIMEOUT) {0X0068CF0E} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INLINE_ECC) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INPUTCLK0_PERIOD) {3125} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_INTERLEAVE_SIZE) {0} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LATENCY_MODE) {x16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LBDQ_SWAP) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LOW_TRFC_DPR) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2ACT) {7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TPBR2PBR) {90000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCAB) {280000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFCPB) {140000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMAB) {280000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_TRFMPB) {190000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_LP5_X64_EN) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MAIN_DEVICE_TYPE) {Components} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC0_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC1_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC2_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC3_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC4_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC5_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC6_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MC7_CONFIG_SEL) {config13} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_MEMORY_DENSITY) {4GB} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CH) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_CK) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MC) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_MCP) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_NUM_RANKS) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_OP_TEMPERATURE) {LOW} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_OTF_SCRUB) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_PERIODIC_READ) {ENABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_PRE_DEF_ADDR_MAP_SEL) {ROW_BANK_COLUMN} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_RDIMM_DUAL_SLOT) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_RD_DBI) {true} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_MODE) {NORMAL} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REFRESH_TYPE) {ALL_BANK} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REF_AND_PER_CAL_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_REG_SCRUB_INTVL) {0x015180} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_ROW_ADDR_WIDTH) {16} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SCRUB_SIZE) {1} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SELF_REFRESH) {DISABLE} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SILICON_REVISION) {NA} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SPEED_GRADE) {LPDDR5X-7500} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {Differential} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_TREFI) {3906000} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_UBLAZE_BLI_INTF) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_USER_REFRESH) {false} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WL_SET) {A} \
    CONFIG.DDRMC5_CONFIG(DDRMC5_WR_DBI) {true} \
    CONFIG.DDRMC5_NUM_CH {1} \
    CONFIG.INLINE_HDL {false} \
    CONFIG.MC_BOARD_INTRF_EN {false} \
    CONFIG.MC_CHAN_REGION0 {DDR_CH0_LEGACY} \
    CONFIG.NUM_CLKS $nb \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_SI $nb \
    CONFIG.sys_clk0_BOARD_INTERFACE {Custom} \
    ] $axi_noc2_0
  } else {
    set_property -dict [list \
      CONFIG.INLINE_HDL {false} \
      CONFIG.NUM_CLKS $nb \
      CONFIG.NUM_MC {0} \
      CONFIG.NUM_MI {0} \
      CONFIG.NUM_SI $nb \
    ] $axi_noc2_0
  }
  set i 0
  foreach b $::pnoc_base {
    lassign $b ps_pin ps_clk cat extra
    set port [format S%02d_AXI $i]
    set_property -dict [concat [list CONFIG.DATA_WIDTH {128} CONFIG.REGION {0} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY $cat] $extra] [get_bd_intf_pins $axi_noc2_0/$port]
    set_property CONFIG.ASSOCIATED_BUSIF $port [get_bd_pins $axi_noc2_0/aclk$i]
    lappend ::pnoc(owned) $port
    incr i
  }
  platform_noc_route $axi_noc2_0
  return $axi_noc2_0
}

# Connect the platform PS ports (and DDR) to the NoC created by platform_noc_create. ps / noc are the PS and NoC cells.
proc platform_noc_connect_ps {ps noc ddr_enabled} {
  set i 0
  foreach b $::pnoc_base {
    lassign $b ps_pin ps_clk cat extra
    connect_bd_intf_net [get_bd_intf_pins $ps/$ps_pin] [get_bd_intf_pins $noc/[format S%02d_AXI $i]]
    connect_bd_net [get_bd_pins $ps/$ps_clk] [get_bd_pins $noc/aclk$i]
    incr i
  }
  if { $ddr_enabled } {
    connect_bd_intf_net [get_bd_intf_pins $noc/C0_CH0_LPDDR5] [get_bd_intf_ports CH0_LPDDR5_0]
    connect_bd_intf_net [get_bd_intf_ports sys_clk0_0] [get_bd_intf_pins $noc/sys_clk0]
  }
}

# Add ports to the NoC cell $noc. specs is a list of dicts:
#   kind (slave|master)   required
#   pin                   BD interface pin/port to connect to the new NoC port (optional)
#   clk                   BD clock pin to connect to the new NoC clock pin (optional)
#   category              NoC port category (default pl)
#   width                 data width (default 128)
#   extra                 extra CONFIG.* property list for a slave port (optional)
# New ports always take the next free index, so existing ports are never renumbered.
proc platform_noc_add {noc specs} {
  foreach s $specs {
    set kind [dict get $s kind]
    set cat [expr {[dict exists $s category] ? [dict get $s category] : "pl"}]
    set width [expr {[dict exists $s width] ? [dict get $s width] : 128}]
    set extra [expr {[dict exists $s extra] ? [dict get $s extra] : {}}]
    set nclk [get_property CONFIG.NUM_CLKS $noc]
    if { $kind eq "slave" } {
      set n [get_property CONFIG.NUM_SI $noc]
      set port [format S%02d_AXI $n]
      set_property -dict [list CONFIG.NUM_SI [expr {$n + 1}] CONFIG.NUM_CLKS [expr {$nclk + 1}]] $noc
    } elseif { $kind eq "master" } {
      set n [get_property CONFIG.NUM_MI $noc]
      set port [format M%02d_AXI $n]
      set_property -dict [list CONFIG.NUM_MI [expr {$n + 1}] CONFIG.NUM_CLKS [expr {$nclk + 1}]] $noc
    } else {
      error "platform_noc_add: kind must be slave or master, got $kind"
    }
    set pin [get_bd_intf_pins $noc/$port]
    set clkpin [get_bd_pins $noc/aclk$nclk]
    set_property CONFIG.ASSOCIATED_BUSIF $port $clkpin
    if { $kind eq "slave" } {
      set_property -dict [concat [list CONFIG.DATA_WIDTH $width CONFIG.REGION {0} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY $cat] $extra] $pin
      lappend ::pnoc(owned) $port
    } else {
      set_property CONFIG.DATA_WIDTH $width $pin
    }
    if { [dict exists $s pin] } {
      set peer [get_bd_intf_pins -quiet [dict get $s pin]]
      if { $peer eq "" } { set peer [get_bd_intf_ports [dict get $s pin]] }
      connect_bd_intf_net $peer $pin
    }
    if { [dict exists $s clk] } { connect_bd_net [get_bd_pins [dict get $s clk]] $clkpin }
  }
  platform_noc_route $noc
}

# Switch the PS -> NoC interfaces of the PS cell $ps on if it has any of them off.
proc platform_noc_enable_ps {ps} {
  set missing 0
  foreach b $::pnoc_base { if { [get_bd_intf_pins -quiet $ps/[lindex $b 0]] eq "" } { set missing 1 } }
  if { $missing } {
    puts "INFO: platform: enabling the PS NoC interfaces on [get_property NAME $ps]"
    set_property -dict $::pnoc_ps_enables $ps
  }
}

# Extra NoC port properties by category (the RPU port also carries traffic-class settings).
set ::pnoc_cat_extra [dict create ps_rpu {CONFIG.R_TRAFFIC_CLASS BEST_EFFORT CONFIG.W_TRAFFIC_CLASS BEST_EFFORT CONFIG.REMAPS {}}]

# The clock pin of the IP that is associated with an interface (its ASSOCIATED_BUSIF names the interface); "" if none.
proc platform_noc_clk_of {intf} {
  set cell [get_bd_cells -of_objects $intf]
  set name [get_property NAME $intf]
  foreach pin [get_bd_pins -quiet -of_objects $cell -filter {TYPE==clk}] {
    set busif [get_property CONFIG.ASSOCIATED_BUSIF $pin]
    if { $busif ne "" && [lsearch [split $busif ":"] $name] >= 0 } { return $pin }
  }
  return ""
}

# Find the interfaces in the design that ask for a NoC connection (CONFIG.CATEGORY == noc) and are not connected yet, and
# return them as platform_noc_add specs: a master-mode interface needs a NoC slave port, a slave-mode one a NoC master port.
# The NoC port category is the interface's MY_CATEGORY (default pl); the clock is the IP clock associated with the interface.
proc platform_noc_discover {} {
  set specs {}
  foreach pin [lsort [get_bd_intf_pins -hierarchical -quiet -filter {CONFIG.CATEGORY==noc}]] {
    if { [get_bd_intf_nets -quiet -of_objects $pin] ne "" } continue
    set cat [get_property CONFIG.MY_CATEGORY $pin]
    if { $cat eq "" } { set cat pl }
    set s [dict create kind [expr {[get_property MODE $pin] eq "Master" ? "slave" : "master"}] pin $pin category $cat]
    set clk [platform_noc_clk_of $pin]
    if { $clk ne "" } { dict set s clk $clk }
    if { [dict exists $::pnoc_cat_extra $cat] } { dict set s extra [dict get $::pnoc_cat_extra $cat] }
    puts "INFO: platform_noc_discover: $pin ([get_property MODE $pin], $cat) -> NoC [dict get $s kind] port"
    lappend specs $s
  }
  return $specs
}

# Attach to a NoC ($noc) the parent already built, for the PS cell $ps. Finds (platform_noc_discover) the NoC-capable interfaces the
# parent has not connected (falling back to the PS port table) and adds them, on the next free indices. The new slaves route to
# the parent's memory controller (if any) and to every master the parent has, reusing the parent's destination IDs.
# The parent's own ports and tables are never touched.
proc platform_noc_attach {ps noc} {
  if { $noc eq "" } { error "platform_noc_attach: no axi_noc2 cell given, use platform_noc_create" }
  set ::pnoc(owned) {}
  set ::pnoc(ids) [dict create]
  # destination IDs the parent already uses, per master
  foreach pin [get_bd_intf_pins -of_objects $noc -filter {MODE==Slave}] {
    set parts [split [get_property CONFIG.DEST_IDS $pin] ":"]
    for {set k 0} {$k + 1 < [llength $parts]} {incr k 2} { dict set ::pnoc(ids) [lindex $parts $k] [lindex $parts [expr {$k + 1}]] }
  }
  platform_noc_enable_ps $ps
  set specs [platform_noc_discover]
  if { $specs ne "" } {
    platform_noc_add $noc $specs
    return
  }
  puts "INFO: platform_noc_attach: no unconnected interface with CATEGORY noc found, using the platform port table"
  foreach b $::pnoc_base {
    lassign $b ps_pin ps_clk cat extra
    set p [get_bd_intf_pins -quiet $ps/$ps_pin]
    if { $p eq "" } { puts "INFO: platform_noc_attach: $ps/$ps_pin does not exist, skipped"; continue }
    if { [get_bd_intf_nets -quiet -of_objects $p] ne "" } { puts "INFO: platform_noc_attach: $ps/$ps_pin already connected by the parent, skipped"; continue }
    platform_noc_add $noc [list [dict create kind slave pin $ps/$ps_pin clk $ps/$ps_clk category $cat extra $extra]]
  }
}

# Assign the NoC's DDR memory segment(s) to PS cores at an address chosen by the parent. cores is a list such as
# {cortexa72_0 cortexa72_1 pmc_0}; one call per address group (cores have different NoC windows, e.g. the RPUs only see the
# low 2G). Each core is assigned in its own command, so one refusal does not undo the others.
proc platform_noc_assign_ddr {ps noc offset range cores} {
  set segs [get_bd_addr_segs -quiet $noc/DDR_MC_PORTS/*]
  foreach asp $cores {
    set sp [get_bd_addr_spaces $ps/pmcps_0_psv_$asp]
    foreach seg $segs {
      if { [catch {assign_bd_address -offset $offset -range $range -target_address_space $sp $seg} msg] } {
        puts "WARNING: platform_noc_assign_ddr: $asp / $seg not assigned at $offset"
      }
    }
  }
}

# Exclude the NoC's DDR segment(s) for PS cores that cannot reach it (e.g. the RPUs when the memory controller has no low-2G window).
proc platform_noc_exclude_ddr {ps noc cores} {
  set segs [get_bd_addr_segs -quiet $noc/DDR_MC_PORTS/*]
  foreach asp $cores {
    set sp [get_bd_addr_spaces $ps/pmcps_0_psv_$asp]
    foreach seg $segs {
      if { [catch {exclude_bd_addr_seg -target_address_space $sp $seg} msg] } { puts "WARNING: platform_noc_exclude_ddr: $asp / $seg: $msg" }
    }
  }
}

# PL BRAM reached by the PS through the NoC (no CPM bridge): BRAM cells plus a NoC master port for it. ps / noc are the PS and NoC cells.
proc platform_add_bram {ps noc} {
  set b [platform_create_bram]
  set mem [dict get $b mem]
  set ctrl [dict get $b ctrl]
  set rst [dict get $b rst]
  platform_noc_add $noc [list [dict create kind master pin $ctrl/S_AXI clk $ps/pl0_ref_clk]]
  connect_bd_intf_net [get_bd_intf_pins $ctrl/BRAM_PORTA] [get_bd_intf_pins $mem/BRAM_PORTA]
  connect_bd_net [get_bd_pins $ps/pl0_ref_clk] [get_bd_pins $ctrl/s_axi_aclk] [get_bd_pins $rst/slowest_sync_clk]
  connect_bd_net [get_bd_pins $ps/pl0_resetn] [get_bd_pins $rst/ext_reset_in]
  connect_bd_net [get_bd_pins $rst/peripheral_aresetn] [get_bd_pins $ctrl/s_axi_aresetn]
}

# Kept for the BD scripts: NoC with the platform PS ports (and DDR); returns the NoC cell. Parent ports are added with platform_noc_add.
proc platform_create_noc {ddr_enabled} {
  return [platform_noc_create $ddr_enabled]
}

# CREATE MODE address plan (the platform builds the NoC, so the platform decides): default assignment for everything, then the DDR at
# 0x0, 2G for all 8 PS address spaces. It is called from the BD script of a CED that used platform_create_noc (BMD) -- not from auto
# mode, which follows the PARENT's addresses instead (platform_auto_plan below).
proc platform_assign_addr {ps noc ddr_enabled} {
  assign_bd_address
  if { $ddr_enabled } {
    set seg [get_bd_addr_segs $noc/DDR_MC_PORTS/DDR_CH0_LEGACY]
    foreach asp {cortexa72_0 cortexa72_1 cortexr5_0 cortexr5_1 dpc_0 pmc_0 psm_0 cpm_0} {
      assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces $ps/pmcps_0_psv_$asp] $seg -force
    }
  }
}

# ---------------------------------------------------------------------------
# Automatic mode: sourcing this file on a block design that already contains a ps_wizard and a NoC does everything.
# ---------------------------------------------------------------------------
# Cores that only reach DDR below 2G (their NoC ports see {0x0 2G} and {0xE000_0000 256M}).
set ::pnoc_low_cores {cortexr5_0 cortexr5_1 psm_0}

# Give the PS cores ($ps) every memory the NoC ($noc) reaches (its DDR, and the slave segments of the parent's IPs behind the NoC
# master ports, e.g. a BRAM) at the address the parent already uses for it (taken from CPM/DPC/...); exclude the cores that cannot
# reach that address. Cores the parent already assigned are left alone.
proc platform_auto_plan {ps noc} {
  # (segment, name fragment that identifies its master segments in the address spaces)
  set targets {}
  if { [get_property CONFIG.NUM_MC $noc] > 0 } {
    foreach seg [get_bd_addr_segs -quiet $noc/DDR_MC_PORTS/*] { lappend targets [list $seg [file tail $seg]] }
  }
  foreach m [get_bd_intf_pins -quiet -of_objects $noc -filter {MODE==Master && NAME=~M*_AXI}] {
    set nets [get_bd_intf_nets -quiet -of_objects $m]
    if { $nets eq "" } continue
    foreach q [get_bd_intf_pins -quiet -of_objects $nets] {
      if { $q eq $m } continue
      foreach seg [get_bd_addr_segs -quiet -of_objects $q] {
        lappend targets [list $seg "[get_property NAME [get_bd_cells -of_objects $q]]_[file tail $seg]"]
      }
    }
  }
  foreach t $targets {
    lassign $t seg tail
    set off ""
    set rng ""
    foreach asp {cpm_0 dpc_0 pmc_0 cortexa72_0 cortexa72_1} {
      set sp [get_bd_addr_spaces -quiet $ps/pmcps_0_psv_$asp]
      if { $sp eq "" } continue
      foreach m [get_bd_addr_segs -quiet -of_objects $sp] {
        if { [string match "*$tail*" [get_property NAME $m]] } { set off [get_property OFFSET $m]; set rng [get_property RANGE $m]; break }
      }
      if { $off ne "" } break
    }
    if { $off eq "" } { puts "INFO: platform_auto: no existing address for $tail, plan skipped"; continue }
    foreach asp {cortexa72_0 cortexa72_1 pmc_0 cortexr5_0 cortexr5_1 psm_0} {
      set sp [get_bd_addr_spaces -quiet $ps/pmcps_0_psv_$asp]
      if { $sp eq "" } continue
      set have 0
      foreach m [get_bd_addr_segs -quiet -of_objects $sp] { if { [string match "*$tail*" [get_property NAME $m]] } { set have 1 } }
      if { $have } continue
      if { [lsearch $::pnoc_low_cores $asp] >= 0 && $off >= 0x80000000 } {
        catch {exclude_bd_addr_seg -target_address_space $sp $seg}
      } elseif { [catch {assign_bd_address -offset $off -range $rng -target_address_space $sp $seg}] } {
        catch {exclude_bd_addr_seg -target_address_space $sp $seg}
      }
    }
  }
}

# 1 if something already assigned in the PS address spaces overlaps the OSPI/QSPI flash window (0xC000_0000, 512M, fixed by the ps_wizard).
# Must run BEFORE the platform's own properties are applied, so the OSPI segments are not there yet (they are skipped by name anyway).
proc platform_ospi_window_used {ps} {
  set w0 0xC0000000
  set w1 [expr {0xC0000000 + 0x20000000}]
  foreach asp {cortexa72_0 cortexa72_1 cortexr5_0 cortexr5_1 dpc_0 pmc_0 psm_0 cpm_0} {
    set sp [get_bd_addr_spaces -quiet $ps/pmcps_0_psv_$asp]
    if { $sp eq "" } continue
    foreach seg [get_bd_addr_segs -quiet -of_objects $sp] {
      if { [string match "*OSPI*" [get_property NAME $seg]] } continue
      if { [string is true -strict [get_property EXCLUDE $seg]] } continue
      set o [expr {[get_property OFFSET $seg]}]
      set e [expr {$o + [get_property RANGE $seg]}]
      if { $o < $w1 && $e > $w0 } {
        puts "INFO: platform: [get_property NAME $seg] ($asp) at [get_property OFFSET $seg] overlaps the OSPI window"
        return 1
      }
    }
  }
  return 0
}

# Apply the platform's PS properties (platform_ps_props) to an EXISTING ps_wizard, parent wins: a property whose current value differs from the IP
# default (read from a temporary, untouched ps_wizard) was set by the parent and is kept; the others get the platform value. The PS-side copy of
# each controller's PERST pin (PS_PMC_CONFIG(CPM6_CTRLx_PERST)) is first set to the CPM-side value if the parent left it at the default, so the PS
# pin allocator does not park PERST on its default MIO, where it would collide with the PMC I2C. All in ONE set_property call.
proc platform_apply_ps_props {ps} {
  set tmp [create_bd_cell -type ip -vlnv [get_property VLNV $ps] platform_tmp_ps_defaults]
  set apply {}
  foreach i {0 1} {
    set cpm "CONFIG.CPM6_CONFIG(CPM6_CTRL${i}_PERST)"
    set pss "CONFIG.PS_PMC_CONFIG(CPM6_CTRL${i}_PERST)"
    set cpm_v [get_property $cpm $ps]
    if { $cpm_v ne "" && [get_property $pss $ps] eq [get_property $pss $tmp] } { lappend apply $pss $cpm_v }
  }
  set kept 0
  set ospi_off [platform_ospi_window_used $ps]
  foreach {name value} [platform_ps_props] {
    if { $ospi_off && $name eq "CONFIG.PS_PMC_CONFIG(PMC_OSPI_PERIPHERAL)" } {
      puts "INFO: platform: OSPI left disabled (its 0xC000_0000 window is already used by the design)"
      set value {PRIMARY_ENABLE 0 SECONDARY_ENABLE 0 IO PMC_MIO_0:13 MODE Single}
    }
    if { [get_property $name $ps] eq [get_property $name $tmp] } { lappend apply $name $value } else { incr kept }
  }
  delete_bd_objs $tmp
  puts "INFO: platform: applying [expr {[llength $apply] / 2}] PS properties to [get_property NAME $ps] ($kept kept: set by the parent)"
  set_property -dict $apply $ps
}

# Do the whole job. Finds the PS and the NoC once, then:
#   a NoC is present -> attach: apply the PS peripheral properties (the parent's own settings win), add the PS ports to the NoC, plan the PS cores' addresses to follow the parent's, validate
#   no NoC           -> build everything: the PS peripherals, the NoC with the PS ports, the BRAM (and DDR if ::platform_ddr is 1),
#                       the create-mode address plan, validate
# Returns 1 if it did something, 0 if the design has no ps_wizard yet (then call the procs from your BD script).
# The ONE argument (set before sourcing): ::platform_ddr 1 = add the LPDDR5 memory controller and the DDR constraints file (adds top-level ports),
# only if the design has no DDR yet; default 0 = no DDR. If the design already has DDR the argument is ignored.
proc platform_auto {} {
  set d [current_bd_design]   ;# the CED flow always has a block design open
  set ps [lindex [get_bd_cells -quiet -filter {VLNV=~*ps_wizard*}] 0]
  if { $ps eq "" } { return 0 }
  set noc [lindex [get_bd_cells -quiet -filter {VLNV=~*axi_noc2*}] 0]
  if { $noc ne "" } {
    puts "INFO: platform_auto: attaching the platform to the NoC of $d"
    if { [platform_ddr_in_design $noc] } {
      puts "INFO: platform_auto: DDR found in the design: no DDR code is run (::platform_ddr is ignored)"
    } else {
      puts "INFO: platform_auto: no DDR in the design and none created here: DDR code skipped"
    }
    platform_apply_ps_props $ps
    platform_noc_attach $ps $noc
    platform_auto_plan $ps $noc
  } else {
    set ddr [expr {[info exists ::platform_ddr] && $::platform_ddr}]
    puts "INFO: platform_auto: no axi_noc2 in $d: building the platform (PS peripherals, NoC, BRAM, address plan; ddr=$ddr)"
    platform_apply_ps_props $ps
    platform_noc_enable_ps $ps
    platform_create_ports $ddr
    set noc [platform_create_noc $ddr]
    platform_noc_connect_ps $ps $noc $ddr
    if { [get_bd_cells -quiet axi_bram_ctrl_0] ne "" || [get_bd_pins -quiet $ps/pl0_ref_clk] eq "" } {
      puts "INFO: platform_auto: BRAM not added (the design already has axi_bram_ctrl_0, or the PS has no pl0_ref_clk)"
    } else {
      platform_add_bram $ps $noc
    }
    platform_assign_addr $ps $noc $ddr
    if { $ddr } { platform_add_ddr_xdc } else { puts "INFO: platform_auto: DDR not requested: DDR code skipped" }
  }
  catch {validate_bd_design}
  puts "INFO: platform_auto: done"
  return 1
}

# Run automatically when sourced (set ::platform_auto_disable 1 before sourcing to turn this off). On a design with no ps_wizard
# yet (e.g. sourced at the top of a BD script) it does nothing.
if { ![info exists ::platform_auto_disable] || !$::platform_auto_disable } {
  if { [catch {platform_auto} err] } { puts "ERROR: platform_auto: $err" }
}
