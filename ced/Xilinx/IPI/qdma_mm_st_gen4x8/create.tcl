proc createDesign {design_name options} {

    # Set the reference directory for source file relative paths (by default the value is script directory path)
    variable currentDir

    # Create 'sources_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sources_1] ""]} {
        create_fileset -srcset sources_1
    }

   # Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${currentDir}/exdes/ST_c2h.sv"] \
 [file normalize "${currentDir}/exdes/ST_h2c.sv"] \
 [file normalize "${currentDir}/exdes/axi_st_module.sv"] \
 [file normalize "${currentDir}/exdes/dsc_byp_c2h.sv"] \
 [file normalize "${currentDir}/exdes/dsc_byp_h2c.sv"] \
 [file normalize "${currentDir}/exdes/qdma_stm_defines.svh"] \
 [file normalize "${currentDir}/exdes/qdma_fifo_lut.sv"] \
 [file normalize "${currentDir}/exdes/qdma_lpbk.sv"] \
 [file normalize "${currentDir}/exdes/qdma_stm_c2h_stub.sv"] \
 [file normalize "${currentDir}/exdes/qdma_stm_h2c_stub.sv"] \
 [file normalize "${currentDir}/exdes/qdma_stm_lpbk.sv"] \
 [file normalize "${currentDir}/exdes/user_control.sv"] \
 [file normalize "${currentDir}/exdes/xilinx_qdma_ep.sv"] \
]
#add_files -norecurse -fileset $obj $files

# Import local files from the original project

import_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for remote files
#set file "$currentDir/exdes/ST_c2h.sv"
set file [get_files ST_c2h.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/ST_h2c.sv"
set file [get_files ST_h2c.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/axi_st_module.sv"
set file [get_files axi_st_module.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/dsc_byp_c2h.sv"
set file [get_files dsc_byp_c2h.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/dsc_byp_h2c.sv"
set file [get_files dsc_byp_h2c.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/qdma_stm_defines.svh"
set file [get_files qdma_stm_defines.svh]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

#set file "$currentDir/exdes/qdma_fifo_lut.sv"
set file [get_files qdma_fifo_lut.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/qdma_lpbk.sv"
set file [get_files qdma_lpbk.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/qdma_stm_c2h_stub.sv"
set file [get_files qdma_stm_c2h_stub.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/qdma_stm_h2c_stub.sv"
set file [get_files qdma_stm_h2c_stub.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/qdma_stm_lpbk.sv"
set file [get_files qdma_stm_lpbk.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/user_control.sv"
set file [get_files user_control.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

#set file "$currentDir/exdes/xilinx_qdma_ep.sv"
set file [get_files xilinx_qdma_ep.sv]
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj


# Set 'sources_1' fileset file properties for local files


# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "xilinx_qdma_ep" -objects $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$currentDir/top_impl.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$currentDir/top_impl.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${currentDir}/sim_files/pcie_4_0_rp.v"] \
 [file normalize "${currentDir}/sim_files/sys_clk_gen.v"] \
 [file normalize "${currentDir}/sim_files/sys_clk_gen_ds.v"] \
 [file normalize "${currentDir}/sim_files/board_common.vh"] \
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_cfg.v"] \
 [file normalize "${currentDir}/sim_files/pci_exp_expect_tasks.vh"] \
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_com.v"] \
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_rx.v"] \
 [file normalize "${currentDir}/sim_files/sample_tests.vh"] \
 [file normalize "${currentDir}/sim_files/tests.vh"] \
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_tx.v"] \
 [file normalize "${currentDir}/sim_files/xilinx_pcie_uscale_rp.v"] \
 [file normalize "${currentDir}/sim_files/xp4_usp_smsw_model_core_top.v"] \
 [file normalize "${currentDir}/sim_files/board.v"] \
 [file normalize "${currentDir}/sim_files/usp_pci_exp_usrapp_tx_sriov.sv"] \
 [file normalize "${currentDir}/sim_files/sample_tests_sriov.vh"] \
]
add_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset file properties for remote files
set file "$currentDir/sim_files/board_common.vh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$currentDir/sim_files/pci_exp_expect_tasks.vh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$currentDir/sim_files/sample_tests.vh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$currentDir/sim_files/tests.vh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj

set file "$currentDir/sim_files/usp_pci_exp_usrapp_tx_sriov.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "SystemVerilog" -objects $file_obj

set file "$currentDir/sim_files/sample_tests_sriov.vh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property -name "file_type" -value "Verilog Header" -objects $file_obj


# Set 'sim_1' fileset file properties for local files
# None
set infile [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports exdes xilinx_qdma_ep.sv]]
set contents [read $infile]
close $infile
set contents [string map [list "design_1" "$design_name"] $contents]

set outfile  [open [file join [get_property directory [current_project]] [current_project].srcs sources_1 imports exdes xilinx_qdma_ep.sv] w]
puts -nonewline $outfile $contents
close $outfile

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "board" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

# Set 'utils_1' fileset object
set obj [get_filesets utils_1]
# Empty (no sources present)

# Set 'utils_1' fileset properties
set obj [get_filesets utils_1]

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  

# Create interface ports
  set M00_AXI_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {42} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $M00_AXI_0

  set PCIE0_GT_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 PCIE0_GT_0 ]

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

  set dma0_s_axis_c2h_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_qdma:s_axis_c2h_rtl:1.0 dma0_s_axis_c2h_0 ]

  set dma0_s_axis_c2h_cmpt_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_qdma:s_axis_c2h_cmpt_rtl:1.0 dma0_s_axis_c2h_cmpt_0 ]

  set dma0_st_rx_msg_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 dma0_st_rx_msg_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $dma0_st_rx_msg_0

  set dma0_tm_dsc_sts_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:qdma_tm_dsc_sts_rtl:1.0 dma0_tm_dsc_sts_0 ]

  set gt_refclk0_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_refclk0_0 ]

  set usr_flr_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_eqdma:usr_flr_rtl:1.0 usr_flr_0 ]

  set usr_irq_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:qdma_usr_irq_rtl:1.0 usr_irq_0 ]

 # Create ports
  set dma0_axi_aresetn_0 [ create_bd_port -dir O -type rst dma0_axi_aresetn_0 ]
  set dma0_soft_resetn_0 [ create_bd_port -dir I -type rst dma0_soft_resetn_0 ]
  set pcie0_user_clk_0 [ create_bd_port -dir O -type clk pcie0_user_clk_0 ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {dma0_st_rx_msg_0:M00_AXI_0} \
   CONFIG.FREQ_HZ {250000000} \
 ] $pcie0_user_clk_0
  set pcie0_user_lnk_up_0 [ create_bd_port -dir O pcie0_user_lnk_up_0 ]

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:* axi_bram_ctrl_0 ]

  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:* axi_bram_ctrl_0_bram ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH_A {19} \
   CONFIG.ADDR_WIDTH_B {19} \
   CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} \
 ] $axi_bram_ctrl_0_bram

  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* axi_noc_0 ]
  set_property -dict [ list \
   CONFIG.HBM_CHNL0_CONFIG { } \
   CONFIG.LOGO_FILE {data/noc.png} \
   CONFIG.MC_ADDR_BIT14 {BA0} \
   CONFIG.MC_ADDR_BIT15 {BA1} \
   CONFIG.MC_ADDR_BIT16 {RA0} \
   CONFIG.MC_ADDR_BIT17 {RA1} \
   CONFIG.MC_ADDR_BIT18 {RA2} \
   CONFIG.MC_ADDR_BIT19 {RA3} \
   CONFIG.MC_ADDR_BIT20 {RA4} \
   CONFIG.MC_ADDR_BIT21 {RA5} \
   CONFIG.MC_ADDR_BIT22 {RA6} \
   CONFIG.MC_ADDR_BIT23 {RA7} \
   CONFIG.MC_ADDR_BIT24 {RA8} \
   CONFIG.MC_ADDR_BIT25 {RA9} \
   CONFIG.MC_ADDR_BIT26 {RA10} \
   CONFIG.MC_ADDR_BIT27 {RA11} \
   CONFIG.MC_ADDR_BIT28 {RA12} \
   CONFIG.MC_ADDR_BIT29 {RA13} \
   CONFIG.MC_ADDR_BIT30 {RA14} \
   CONFIG.MC_ADDR_BIT31 {RA15} \
   CONFIG.MC_ADDR_BIT32 {NA} \
   CONFIG.MC_BG_WIDTH {1} \
   CONFIG.MC_CASLATENCY {22} \
   CONFIG.MC_COMPONENT_WIDTH {x16} \
   CONFIG.MC_DDR_INIT_TIMEOUT {0x000408B7} \
   CONFIG.MC_ECC_SCRUB_SIZE {4096} \
   CONFIG.MC_EN_INTR_RESP {FALSE} \
   CONFIG.MC_F1_LPDDR4_MR1 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR2 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR3 {0x0000} \
   CONFIG.MC_F1_LPDDR4_MR13 {0x0000} \
   CONFIG.MC_F1_TFAW {30000} \
   CONFIG.MC_F1_TFAWMIN {30000} \
   CONFIG.MC_F1_TRCD {13750} \
   CONFIG.MC_F1_TRCDMIN {13750} \
   CONFIG.MC_F1_TRRD_L {11} \
   CONFIG.MC_F1_TRRD_L_MIN {11} \
   CONFIG.MC_F1_TRRD_S {9} \
   CONFIG.MC_F1_TRRD_S_MIN {9} \
   CONFIG.MC_INPUTCLK0_PERIOD {5000} \
   CONFIG.MC_INPUT_FREQUENCY0 {200.000} \
   CONFIG.MC_MEMORY_DENSITY {4GB} \
   CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
   CONFIG.MC_MEM_DEVICE_WIDTH {x16} \
   CONFIG.MC_TFAW {30000} \
   CONFIG.MC_TFAWMIN {30000} \
   CONFIG.MC_TFAW_nCK {48} \
   CONFIG.MC_TRC {45750} \
   CONFIG.MC_TRCD {13750} \
   CONFIG.MC_TRCDMIN {13750} \
   CONFIG.MC_TRCMIN {45750} \
   CONFIG.MC_TRP {13750} \
   CONFIG.MC_TRPMIN {13750} \
   CONFIG.MC_TRRD_L {11} \
   CONFIG.MC_TRRD_L_MIN {11} \
   CONFIG.MC_TRRD_S {9} \
   CONFIG.MC_TRRD_S_MIN {9} \
   CONFIG.MC_USER_DEFINED_ADDRESS_MAP {16RA-2BA-1BG-10CA} \
   CONFIG.NUM_CLKS {3} \
   CONFIG.NUM_MC {0} \
   CONFIG.NUM_MCP {0} \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {2} \
 ] $axi_noc_0

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x208_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x210_4000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720}}} \
   CONFIG.DEST_IDS {M01_AXI:0x80:M02_AXI:0x40:M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {M01_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M02_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} M00_AXI { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M01_AXI:0x80:M02_AXI:0x40:M00_AXI:0x0} \
   CONFIG.CATEGORY {ps_pcie} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:M01_AXI:M02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  # Create instance: pcie_qdma_mailbox_0, and set properties
  set pcie_qdma_mailbox_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_qdma_mailbox:* pcie_qdma_mailbox_0 ]

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:* smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_0

  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:* smartconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_1

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
  set_property -dict [ list \
   CONFIG.CPM_CONFIG {\
     CPM_AUX0_REF_CTRL_ACT_FREQMHZ {899.991028}\
     CPM_AUX0_REF_CTRL_DIVISOR0 {2}\
     CPM_AUX0_REF_CTRL_FREQMHZ {900}\
     CPM_AUX1_REF_CTRL_ACT_FREQMHZ {899.991028}\
     CPM_AUX1_REF_CTRL_DIVISOR0 {2}\
     CPM_AUX1_REF_CTRL_FREQMHZ {900}\
     CPM_CORE_REF_CTRL_ACT_FREQMHZ {899.991028}\
     CPM_CORE_REF_CTRL_DIVISOR0 {2}\
     CPM_CORE_REF_CTRL_FREQMHZ {900}\
     CPM_CPLL_CTRL_FBDIV {108}\
     CPM_DBG_REF_CTRL_ACT_FREQMHZ {299.997009}\
     CPM_DBG_REF_CTRL_DIVISOR0 {6}\
     CPM_DBG_REF_CTRL_FREQMHZ {300}\
     CPM_DESIGN_USE_MODE {4}\
     CPM_LSBUS_REF_CTRL_DIVISOR0 {12}\
     CPM_PCIE0_AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned}\
     CPM_PCIE0_AXISTEN_IF_ENABLE_CLIENT_TAG {1}\
     CPM_PCIE0_AXISTEN_IF_RC_STRADDLE {1}\
     CPM_PCIE0_AXISTEN_IF_WIDTH {512}\
     CPM_PCIE0_CONTROLLER_ENABLE {1}\
     CPM_PCIE0_COPY_PF0_ENABLED {1}\
     CPM_PCIE0_COPY_PF0_QDMA_ENABLED {0}\
     CPM_PCIE0_COPY_PF0_SRIOV_QDMA_ENABLED {0}\
     CPM_PCIE0_COPY_XDMA_PF0_ENABLED {1}\
     CPM_PCIE0_DMA_DATA_WIDTH {512bits}\
     CPM_PCIE0_DMA_INTF {AXI_MM_and_AXI_Stream}\
     CPM_PCIE0_DSC_BYPASS_RD {1}\
     CPM_PCIE0_DSC_BYPASS_WR {1}\
     CPM_PCIE0_FUNCTIONAL_MODE {QDMA}\
     CPM_PCIE0_LINK_SPEED0_FOR_POWER {GEN4}\
     CPM_PCIE0_LINK_WIDTH0_FOR_POWER {8}\
     CPM_PCIE0_MAILBOX_ENABLE {1}\
     CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s}\
     CPM_PCIE0_MODE0_FOR_POWER {CPM_STREAM_W_DMA}\
     CPM_PCIE0_MODES {DMA}\
     CPM_PCIE0_MODE_SELECTION {Advanced}\
     CPM_PCIE0_MSIX_RP_ENABLED {0}\
     CPM_PCIE0_MSI_X_OPTIONS {MSI-X_Internal}\
     CPM_PCIE0_NUM_USR_IRQ {0}\
     CPM_PCIE0_PF0_BAR0_64BIT {0}\
     CPM_PCIE0_PF0_BAR0_PREFETCHABLE {0}\
     CPM_PCIE0_PF0_BAR0_SRIOV_QDMA_SIZE {1}\
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
     CPM_PCIE0_PF0_CLASS_CODE {0x058000}\
     CPM_PCIE0_PF0_DEV_CAP_EXT_TAG_EN {1}\
     CPM_PCIE0_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE {1}\
     CPM_PCIE0_PF0_INTERFACE_VALUE {00}\
     CPM_PCIE0_PF0_MSIX_CAP_PBA_BIR {BAR_0}\
     CPM_PCIE0_PF0_MSIX_CAP_PBA_OFFSET {1400}\
     CPM_PCIE0_PF0_MSIX_CAP_TABLE_BIR {BAR_0}\
     CPM_PCIE0_PF0_MSIX_CAP_TABLE_OFFSET {2000}\
     CPM_PCIE0_PF0_MSI_ENABLED {0}\
     CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_0 {0x0000000000000000}\
     CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2 {0x0000021040000000}\
     CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020804000000}\
     CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000021040004000}\
     CPM_PCIE0_PF0_SRIOV_BAR0_64BIT {0}\
     CPM_PCIE0_PF0_SRIOV_BAR0_PREFETCHABLE {0}\
     CPM_PCIE0_PF0_SRIOV_BAR0_SIZE {1}\
     CPM_PCIE0_PF0_SRIOV_BAR2_64BIT {1}\
     CPM_PCIE0_PF0_SRIOV_BAR2_ENABLED {1}\
     CPM_PCIE0_PF0_SRIOV_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF0_SRIOV_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF0_SRIOV_BAR2_SIZE {4}\
     CPM_PCIE0_PF0_SRIOV_CAP_ENABLE {0}\
     CPM_PCIE0_PF0_SRIOV_CAP_INITIAL_VF {64}\
     CPM_PCIE0_PF0_SRIOV_SUPPORTED_PAGE_SIZE {00000553}\
     CPM_PCIE0_PF1_BAR0_QDMA_64BIT {0}\
     CPM_PCIE0_PF1_BAR0_QDMA_PREFETCHABLE {0}\
     CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_64BIT {0}\
     CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_PREFETCHABLE {0}\
     CPM_PCIE0_PF1_BAR0_SRIOV_QDMA_SIZE {1}\
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
     CPM_PCIE0_PF1_CLASS_CODE {0x058000}\
     CPM_PCIE0_PF1_MSIX_CAP_PBA_OFFSET {1400}\
     CPM_PCIE0_PF1_MSIX_CAP_TABLE_OFFSET {2000}\
     CPM_PCIE0_PF1_MSI_ENABLED {0}\
     CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_0 {0x0000020801000000}\
     CPM_PCIE0_PF1_PCIEBAR2AXIBAR_QDMA_2 {0x0000021040001000}\
     CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020805000000}\
     CPM_PCIE0_PF1_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000021040005000}\
     CPM_PCIE0_PF1_SRIOV_BAR0_64BIT {0}\
     CPM_PCIE0_PF1_SRIOV_BAR0_PREFETCHABLE {0}\
     CPM_PCIE0_PF1_SRIOV_BAR0_SIZE {1}\
     CPM_PCIE0_PF1_SRIOV_BAR2_64BIT {1}\
     CPM_PCIE0_PF1_SRIOV_BAR2_ENABLED {1}\
     CPM_PCIE0_PF1_SRIOV_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF1_SRIOV_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF1_SRIOV_BAR2_SIZE {4}\
     CPM_PCIE0_PF1_SRIOV_CAP_ENABLE {0}\
     CPM_PCIE0_PF1_SRIOV_CAP_INITIAL_VF {64}\
     CPM_PCIE0_PF1_SRIOV_FIRST_VF_OFFSET {67}\
     CPM_PCIE0_PF1_SRIOV_SUPPORTED_PAGE_SIZE {00000553}\
     CPM_PCIE0_PF2_BAR0_QDMA_64BIT {0}\
     CPM_PCIE0_PF2_BAR0_QDMA_PREFETCHABLE {0}\
     CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_64BIT {0}\
     CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_PREFETCHABLE {0}\
     CPM_PCIE0_PF2_BAR0_SRIOV_QDMA_SIZE {1}\
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
     CPM_PCIE0_PF2_CLASS_CODE {0x058000}\
     CPM_PCIE0_PF2_MSIX_CAP_PBA_OFFSET {1400}\
     CPM_PCIE0_PF2_MSIX_CAP_TABLE_OFFSET {2000}\
     CPM_PCIE0_PF2_MSI_ENABLED {0}\
     CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_0 {0x0000020802000000}\
     CPM_PCIE0_PF2_PCIEBAR2AXIBAR_QDMA_2 {0x0000021040002000}\
     CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020806000000}\
     CPM_PCIE0_PF2_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000021040006000}\
     CPM_PCIE0_PF2_SRIOV_BAR0_64BIT {0}\
     CPM_PCIE0_PF2_SRIOV_BAR0_PREFETCHABLE {0}\
     CPM_PCIE0_PF2_SRIOV_BAR0_SIZE {1}\
     CPM_PCIE0_PF2_SRIOV_BAR2_64BIT {1}\
     CPM_PCIE0_PF2_SRIOV_BAR2_ENABLED {1}\
     CPM_PCIE0_PF2_SRIOV_BAR2_PREFETCHABLE {1}\
     CPM_PCIE0_PF2_SRIOV_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF2_SRIOV_BAR2_SIZE {4}\
     CPM_PCIE0_PF2_SRIOV_CAP_ENABLE {0}\
     CPM_PCIE0_PF2_SRIOV_CAP_INITIAL_VF {64}\
     CPM_PCIE0_PF2_SRIOV_FIRST_VF_OFFSET {130}\
     CPM_PCIE0_PF2_SRIOV_SUPPORTED_PAGE_SIZE {00000553}\
     CPM_PCIE0_PF3_BAR0_QDMA_64BIT {0}\
     CPM_PCIE0_PF3_BAR0_QDMA_PREFETCHABLE {0}\
     CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_64BIT {0}\
     CPM_PCIE0_PF3_BAR0_SRIOV_QDMA_SIZE {1}\
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
     CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SCALE {Kilobytes}\
     CPM_PCIE0_PF3_BAR2_SRIOV_QDMA_SIZE {4}\
     CPM_PCIE0_PF3_CLASS_CODE {0x058000}\
     CPM_PCIE0_PF3_MSIX_CAP_PBA_OFFSET {1400}\
     CPM_PCIE0_PF3_MSIX_CAP_TABLE_OFFSET {2000}\
     CPM_PCIE0_PF3_MSI_ENABLED {0}\
     CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_0 {0x0000020803000000}\
     CPM_PCIE0_PF3_PCIEBAR2AXIBAR_QDMA_2 {0x0000021040003000}\
     CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_0 {0x0000020807000000}\
     CPM_PCIE0_PF3_PCIEBAR2AXIBAR_SRIOV_QDMA_2 {0x0000021040007000}\
     CPM_PCIE0_PF3_SRIOV_BAR0_64BIT {0}\
     CPM_PCIE0_PF3_SRIOV_BAR0_SIZE {1}\
     CPM_PCIE0_PF3_SRIOV_BAR2_64BIT {1}\
     CPM_PCIE0_PF3_SRIOV_BAR2_ENABLED {1}\
     CPM_PCIE0_PF3_SRIOV_BAR2_SCALE {Kilobytes}\
     CPM_PCIE0_PF3_SRIOV_BAR2_SIZE {4}\
     CPM_PCIE0_PF3_SRIOV_CAP_ENABLE {0}\
     CPM_PCIE0_PF3_SRIOV_CAP_INITIAL_VF {60}\
     CPM_PCIE0_PF3_SRIOV_FIRST_VF_OFFSET {193}\
     CPM_PCIE0_PF3_SRIOV_SUPPORTED_PAGE_SIZE {00000553}\
     CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8}\
     CPM_PCIE0_SRIOV_CAP_ENABLE {1}\
     CPM_PCIE0_TL_PF_ENABLE_REG {4}\
     CPM_PCIE0_USER_CLK2_FREQ {500_MHz}\
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
     CPM_PCIE1_CORE_CLK_FREQ {250}\
     CPM_PCIE1_MSI_X_OPTIONS {MSI-X_External}\
     CPM_PCIE1_PF0_CLASS_CODE {0x058000}\
     CPM_PCIE1_PF0_INTERFACE_VALUE {00}\
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
     CPM_XPIPE_0_CLKDLY_CFG {268485632}\
     CPM_XPIPE_0_INSTANTIATED {1}\
     CPM_XPIPE_0_LINK0_CFG {X8}\
     CPM_XPIPE_0_MODE {1}\
     CPM_XPIPE_0_REG_CFG {8146}\
     CPM_XPIPE_1_CLKDLY_CFG {33557632}\
     CPM_XPIPE_1_CLK_CFG {1048320}\
     CPM_XPIPE_1_INSTANTIATED {1}\
     CPM_XPIPE_1_LINK0_CFG {X8}\
     CPM_XPIPE_1_MODE {1}\
     CPM_XPIPE_1_REG_CFG {8137}\
     CPM_XPIPE_2_CLKDLY_CFG {0}\
     CPM_XPIPE_2_CLK_CFG {0}\
     CPM_XPIPE_2_INSTANTIATED {0}\
     CPM_XPIPE_2_LINK0_CFG {DISABLE}\
     CPM_XPIPE_2_MODE {0}\
     CPM_XPIPE_2_REG_CFG {0}\
     CPM_XPIPE_3_CLKDLY_CFG {0}\
     CPM_XPIPE_3_CLK_CFG {0}\
     CPM_XPIPE_3_INSTANTIATED {0}\
     CPM_XPIPE_3_LINK0_CFG {DISABLE}\
     CPM_XPIPE_3_MODE {0}\
     CPM_XPIPE_3_REG_CFG {0}\
     PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ {824.991760}\
     PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {825}\
     PS_USE_PS_NOC_PCI_0 {1}\
     PS_USE_PS_NOC_PCI_1 {1}\
   } \
   CONFIG.DESIGN_MODE {1} \
   CONFIG.PS_PMC_CONFIG {\
     DESIGN_MODE {1}\
     PCIE_APERTURES_DUAL_ENABLE {0}\
     PCIE_APERTURES_SINGLE_ENABLE {1}\
     PMC_CRP_HSM0_REF_CTRL_FREQMHZ {33.333}\
     PMC_CRP_NOC_REF_CTRL_ACT_FREQMHZ {999.989990}\
     PMC_CRP_NOC_REF_CTRL_FREQMHZ {1000}\
     PMC_CRP_NPLL_CTRL_FBDIV {120}\
     PMC_CRP_PL0_REF_CTRL_FREQMHZ {334}\
     PMC_CRP_PL0_REF_CTRL_SRCSEL {NPLL}\
     PMC_CRP_PL1_REF_CTRL_FREQMHZ {334}\
     PMC_CRP_PL1_REF_CTRL_SRCSEL {NPLL}\
     PMC_CRP_PL2_REF_CTRL_FREQMHZ {334}\
     PMC_CRP_PL2_REF_CTRL_SRCSEL {NPLL}\
     PMC_CRP_PL3_REF_CTRL_FREQMHZ {334}\
     PMC_CRP_PL3_REF_CTRL_SRCSEL {NPLL}\
     PMC_MIO_TREE_PERIPHERALS {######################################PCIE#######################################}\
     PMC_MIO_TREE_SIGNALS {######################################reset1_n#######################################}\
     PS_BOARD_INTERFACE {Custom}\
     PS_CRF_ACPU_CTRL_ACT_FREQMHZ {1349.986450}\
     PS_CRF_ACPU_CTRL_FREQMHZ {1350}\
     PS_CRF_APLL_CTRL_FBDIV {81}\
     PS_CRF_DBG_FPD_CTRL_ACT_FREQMHZ {299.997009}\
     PS_CRF_DBG_FPD_CTRL_DIVISOR0 {4}\
     PS_CRF_DBG_FPD_CTRL_FREQMHZ {300}\
     PS_CRF_DBG_TRACE_CTRL_FREQMHZ {300}\
     PS_CRF_FPD_TOP_SWITCH_CTRL_ACT_FREQMHZ {824.991760}\
     PS_CRF_FPD_TOP_SWITCH_CTRL_DIVISOR0 {1}\
     PS_CRF_FPD_TOP_SWITCH_CTRL_FREQMHZ {825}\
     PS_CRF_FPD_TOP_SWITCH_CTRL_SRCSEL {RPLL}\
     PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ {824.991760}\
     PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {825}\
     PS_CRL_CPU_R5_CTRL_ACT_FREQMHZ {599.994019}\
     PS_CRL_CPU_R5_CTRL_FREQMHZ {600}\
     PS_CRL_CPU_R5_CTRL_SRCSEL {PPLL}\
     PS_CRL_DBG_LPD_CTRL_ACT_FREQMHZ {299.997009}\
     PS_CRL_DBG_LPD_CTRL_DIVISOR0 {4}\
     PS_CRL_DBG_LPD_CTRL_FREQMHZ {300}\
     PS_CRL_DBG_TSTMP_CTRL_ACT_FREQMHZ {299.997009}\
     PS_CRL_DBG_TSTMP_CTRL_DIVISOR0 {4}\
     PS_CRL_DBG_TSTMP_CTRL_FREQMHZ {300}\
     PS_CRL_GEM0_REF_CTRL_DIVISOR0 {4}\
     PS_CRL_GEM0_REF_CTRL_SRCSEL {NPLL}\
     PS_CRL_GEM1_REF_CTRL_DIVISOR0 {4}\
     PS_CRL_GEM1_REF_CTRL_SRCSEL {NPLL}\
     PS_CRL_GEM_TSU_REF_CTRL_DIVISOR0 {2}\
     PS_CRL_GEM_TSU_REF_CTRL_SRCSEL {NPLL}\
     PS_CRL_IOU_SWITCH_CTRL_ACT_FREQMHZ {249.997498}\
     PS_CRL_IOU_SWITCH_CTRL_DIVISOR0 {1}\
     PS_CRL_IOU_SWITCH_CTRL_SRCSEL {NPLL}\
     PS_CRL_LPD_TOP_SWITCH_CTRL_ACT_FREQMHZ {599.994019}\
     PS_CRL_LPD_TOP_SWITCH_CTRL_FREQMHZ {600}\
     PS_CRL_LPD_TOP_SWITCH_CTRL_SRCSEL {PPLL}\
     PS_CRL_RPLL_CTRL_FBDIV {99}\
     PS_CRL_USB3_DUAL_REF_CTRL_FREQMHZ {100}\
     PS_PCIE1_PERIPHERAL_ENABLE {1}\
     PS_PCIE2_PERIPHERAL_ENABLE {0}\
     PS_PCIE_EP_RESET1_IO {PMC_MIO 38}\
     PS_PCIE_RESET {{ENABLE 1} {IO {PS_MIO 18 .. 19}}}\
     PS_USE_PS_NOC_PCI_0 {1}\
     PS_USE_PS_NOC_PCI_1 {1}\
     SMON_ALARMS {Set_Alarms_On}\
     SMON_ENABLE_TEMP_AVERAGING {0}\
     SMON_MEAS33 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX} {SUPPLY_NUM 0}}\
     SMON_MEAS34 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX_PMC} {SUPPLY_NUM 0}}\
     SMON_MEAS35 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCAUX_SMON} {SUPPLY_NUM 0}}\
     SMON_MEAS36 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCINT} {SUPPLY_NUM 0}}\
     SMON_MEAS37 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_306} {SUPPLY_NUM 0}}\
     SMON_MEAS38 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_406} {SUPPLY_NUM 0}}\
     SMON_MEAS39 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_500} {SUPPLY_NUM 0}}\
     SMON_MEAS40 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_501} {SUPPLY_NUM 0}}\
     SMON_MEAS41 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_502} {SUPPLY_NUM 0}}\
     SMON_MEAS42 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {4 V unipolar}} {NAME VCCO_503} {SUPPLY_NUM 0}}\
     SMON_MEAS43 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_700} {SUPPLY_NUM 0}}\
     SMON_MEAS44 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_701} {SUPPLY_NUM 0}}\
     SMON_MEAS45 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_702} {SUPPLY_NUM 0}}\
     SMON_MEAS46 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_703} {SUPPLY_NUM 0}}\
     SMON_MEAS47 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_704} {SUPPLY_NUM 0}}\
     SMON_MEAS48 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_705} {SUPPLY_NUM 0}}\
     SMON_MEAS49 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_706} {SUPPLY_NUM 0}}\
     SMON_MEAS50 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_707} {SUPPLY_NUM 0}}\
     SMON_MEAS51 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_708} {SUPPLY_NUM 0}}\
     SMON_MEAS52 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_709} {SUPPLY_NUM 0}}\
     SMON_MEAS53 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_710} {SUPPLY_NUM 0}}\
     SMON_MEAS54 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCCO_711} {SUPPLY_NUM 0}}\
     SMON_MEAS55 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_BATT} {SUPPLY_NUM 0}}\
     SMON_MEAS56 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PMC} {SUPPLY_NUM 0}}\
     SMON_MEAS57 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSFP} {SUPPLY_NUM 0}}\
     SMON_MEAS58 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_PSLP} {SUPPLY_NUM 0}}\
     SMON_MEAS59 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_RAM} {SUPPLY_NUM 0}}\
     SMON_MEAS60 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VCC_SOC} {SUPPLY_NUM 0}}\
     SMON_MEAS61 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE {2 V unipolar}} {NAME VP_VN} {SUPPLY_NUM 0}}\
     SMON_MEAS62 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE None} {NAME VCC_PMC} {SUPPLY_NUM 0}}\
     SMON_MEAS63 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE None} {NAME VCC_PSFP} {SUPPLY_NUM 0}}\
     SMON_MEAS64 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE None} {NAME VCC_PSLP} {SUPPLY_NUM 0}}\
     SMON_MEAS65 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE None} {NAME VCC_RAM} {SUPPLY_NUM 0}}\
     SMON_MEAS66 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE None} {NAME VCC_SOC} {SUPPLY_NUM 0}}\
     SMON_MEAS67 {{ALARM_ENABLE 0} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN\
0} {ENABLE 0} {MODE None} {NAME VP_VN} {SUPPLY_NUM 0}}\
     SMON_MEASUREMENT_COUNT {62}\
     SMON_MEASUREMENT_LIST {BANK_VOLTAGE:GTY_AVTT-GTY_AVTT_103,GTY_AVTT_104,GTY_AVTT_105,GTY_AVTT_106,GTY_AVTT_200,GTY_AVTT_201,GTY_AVTT_202,GTY_AVTT_203,GTY_AVTT_204,GTY_AVTT_205,GTY_AVTT_206#VCC-GTY_AVCC_103,GTY_AVCC_104,GTY_AVCC_105,GTY_AVCC_106,GTY_AVCC_200,GTY_AVCC_201,GTY_AVCC_202,GTY_AVCC_203,GTY_AVCC_204,GTY_AVCC_205,GTY_AVCC_206#VCCAUX-GTY_AVCCAUX_103,GTY_AVCCAUX_104,GTY_AVCCAUX_105,GTY_AVCCAUX_106,GTY_AVCCAUX_200,GTY_AVCCAUX_201,GTY_AVCCAUX_202,GTY_AVCCAUX_203,GTY_AVCCAUX_204,GTY_AVCCAUX_205,GTY_AVCCAUX_206#VCCO-VCCO_306,VCCO_406,VCCO_500,VCCO_501,VCCO_502,VCCO_503,VCCO_700,VCCO_701,VCCO_702,VCCO_703,VCCO_704,VCCO_705,VCCO_706,VCCO_707,VCCO_708,VCCO_709,VCCO_710,VCCO_711|DEDICATED_PAD:VP-VP_VN|SUPPLY_VOLTAGE:VCC-VCC_BATT,VCC_PMC,VCC_PSFP,VCC_PSLP,VCC_RAM,VCC_SOC#VCCAUX-VCCAUX,VCCAUX_PMC,VCCAUX_SMON#VCCINT-VCCINT}\
     SMON_TEMP_AVERAGING_SAMPLES {0}\
   } \
   CONFIG.PS_PMC_CONFIG_APPLIED {1} \
 ] $versal_cips_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins axi_noc_0/M00_AXI] [get_bd_intf_pins smartconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M01_AXI [get_bd_intf_pins axi_noc_0/M01_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_M02_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins axi_noc_0/M02_AXI]
  connect_bd_intf_net -intf_net dma0_c2h_byp_in_mm_0_1 [get_bd_intf_ports dma0_c2h_byp_in_mm_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_in_mm]
  connect_bd_intf_net -intf_net dma0_c2h_byp_in_st_csh_0_1 [get_bd_intf_ports dma0_c2h_byp_in_st_csh_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_in_st_csh]
  connect_bd_intf_net -intf_net dma0_c2h_byp_in_st_sim_0_1 [get_bd_intf_ports dma0_c2h_byp_in_st_sim_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_in_st_sim]
  connect_bd_intf_net -intf_net dma0_dsc_crdt_in_0_1 [get_bd_intf_ports dma0_dsc_crdt_in_0] [get_bd_intf_pins versal_cips_0/dma0_dsc_crdt_in]
  connect_bd_intf_net -intf_net dma0_h2c_byp_in_mm_0_1 [get_bd_intf_ports dma0_h2c_byp_in_mm_0] [get_bd_intf_pins versal_cips_0/dma0_h2c_byp_in_mm]
  connect_bd_intf_net -intf_net dma0_h2c_byp_in_st_0_1 [get_bd_intf_ports dma0_h2c_byp_in_st_0] [get_bd_intf_pins versal_cips_0/dma0_h2c_byp_in_st]
  connect_bd_intf_net -intf_net dma0_s_axis_c2h_0_1 [get_bd_intf_ports dma0_s_axis_c2h_0] [get_bd_intf_pins versal_cips_0/dma0_s_axis_c2h]
  connect_bd_intf_net -intf_net dma0_s_axis_c2h_cmpt_0_1 [get_bd_intf_ports dma0_s_axis_c2h_cmpt_0] [get_bd_intf_pins versal_cips_0/dma0_s_axis_c2h_cmpt]
  connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports gt_refclk0_0] [get_bd_intf_pins versal_cips_0/gt_refclk0]
  connect_bd_intf_net -intf_net pcie_qdma_mailbox_0_dma_flr [get_bd_intf_pins pcie_qdma_mailbox_0/dma_flr] [get_bd_intf_pins versal_cips_0/dma0_usr_flr]
  connect_bd_intf_net -intf_net pcie_qdma_mailbox_0_dma_usr_irq [get_bd_intf_pins pcie_qdma_mailbox_0/dma_usr_irq] [get_bd_intf_pins versal_cips_0/dma0_usr_irq]
  connect_bd_intf_net -intf_net pcie_qdma_mailbox_0_pcie_mgmt [get_bd_intf_pins pcie_qdma_mailbox_0/pcie_mgmt] [get_bd_intf_pins versal_cips_0/dma0_mgmt]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_ports M00_AXI_0] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M00_AXI [get_bd_intf_pins pcie_qdma_mailbox_0/S_AXI_LITE] [get_bd_intf_pins smartconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net usr_flr_0_1 [get_bd_intf_ports usr_flr_0] [get_bd_intf_pins pcie_qdma_mailbox_0/usr_flr]
  connect_bd_intf_net -intf_net usr_irq_0_1 [get_bd_intf_ports usr_irq_0] [get_bd_intf_pins pcie_qdma_mailbox_0/usr_irq]
  connect_bd_intf_net -intf_net versal_cips_0_CPM_PCIE_NOC_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_0]
  connect_bd_intf_net -intf_net versal_cips_0_CPM_PCIE_NOC_1 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins versal_cips_0/CPM_PCIE_NOC_1]
  connect_bd_intf_net -intf_net versal_cips_0_PCIE0_GT [get_bd_intf_ports PCIE0_GT_0] [get_bd_intf_pins versal_cips_0/PCIE0_GT]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_axis_c2h_status [get_bd_intf_ports dma0_axis_c2h_status_0] [get_bd_intf_pins versal_cips_0/dma0_axis_c2h_status]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_c2h_byp_out [get_bd_intf_ports dma0_c2h_byp_out_0] [get_bd_intf_pins versal_cips_0/dma0_c2h_byp_out]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_h2c_byp_out [get_bd_intf_ports dma0_h2c_byp_out_0] [get_bd_intf_pins versal_cips_0/dma0_h2c_byp_out]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_m_axis_h2c [get_bd_intf_ports dma0_m_axis_h2c_0] [get_bd_intf_pins versal_cips_0/dma0_m_axis_h2c]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_st_rx_msg [get_bd_intf_ports dma0_st_rx_msg_0] [get_bd_intf_pins versal_cips_0/dma0_st_rx_msg]
  connect_bd_intf_net -intf_net versal_cips_0_dma0_tm_dsc_sts [get_bd_intf_ports dma0_tm_dsc_sts_0] [get_bd_intf_pins versal_cips_0/dma0_tm_dsc_sts]

  # Create port connections
  connect_bd_net -net dma0_soft_resetn_0_1 [get_bd_ports dma0_soft_resetn_0] [get_bd_pins versal_cips_0/dma0_soft_resetn]
  connect_bd_net -net versal_cips_0_cpm_pcie_noc_axi0_clk [get_bd_pins axi_noc_0/aclk0] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi0_clk]
  connect_bd_net -net versal_cips_0_cpm_pcie_noc_axi1_clk [get_bd_pins axi_noc_0/aclk1] [get_bd_pins versal_cips_0/cpm_pcie_noc_axi1_clk]
  connect_bd_net -net versal_cips_0_dma0_axi_aresetn [get_bd_ports dma0_axi_aresetn_0] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins pcie_qdma_mailbox_0/axi_aresetn] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins smartconnect_1/aresetn] [get_bd_pins versal_cips_0/dma0_axi_aresetn]
  connect_bd_net -net versal_cips_0_pcie0_user_clk [get_bd_ports pcie0_user_clk_0] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_noc_0/aclk2] [get_bd_pins pcie_qdma_mailbox_0/axi_aclk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins smartconnect_1/aclk] [get_bd_pins versal_cips_0/pcie0_user_clk]
  connect_bd_net -net versal_cips_0_pcie0_user_lnk_up [get_bd_ports pcie0_user_lnk_up_0] [get_bd_pins versal_cips_0/pcie0_user_lnk_up]

  # Create address segments
  assign_bd_address -offset 0x021040000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs M00_AXI_0/Reg] -force
  assign_bd_address -offset 0x021040000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs M00_AXI_0/Reg] -force
  assign_bd_address -offset 0x020100000000 -range 0x00080000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020100000000 -range 0x00080000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x020800000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_0] [get_bd_addr_segs pcie_qdma_mailbox_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x020800000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/CPM_PCIE_NOC_1] [get_bd_addr_segs pcie_qdma_mailbox_0/S_AXI_LITE/Reg] -force



  validate_bd_design
  save_bd_design
}
# End of create_root_design()


create_root_design ""

}
