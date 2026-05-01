

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
set current_vivado_version [version -short]





# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
#
#

proc create_root_design_scu200 { parentCell } {

  variable script_folder
  variable design_name

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
  set lpddr5_sdram [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr5_rtl:1.0 lpddr5_sdram ]

  set default_sysclk1_lpddrmc [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_sysclk1_lpddrmc ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {266670000} \
   ] $default_sysclk1_lpddrmc


  # Create ports
  set resetn_0 [ create_bd_port -dir I -type rst resetn_0 ]
  set gth_refclk0n_i_0 [ create_bd_port -dir I -from 0 -to 0 gth_refclk0n_i_0 ]
  set gth_refclk0p_i_0 [ create_bd_port -dir I -from 0 -to 0 gth_refclk0p_i_0 ]
  set gth_refclk1n_i_0 [ create_bd_port -dir I -from 0 -to 0 gth_refclk1n_i_0 ]
  set gth_refclk1p_i_0 [ create_bd_port -dir I -from 0 -to 0 gth_refclk1p_i_0 ]
  set gth_rxn_i_0 [ create_bd_port -dir I -from 7 -to 0 gth_rxn_i_0 ]
  set gth_rxp_i_0 [ create_bd_port -dir I -from 7 -to 0 gth_rxp_i_0 ]
  set gth_sysclkn_i_0 [ create_bd_port -dir I gth_sysclkn_i_0 ]
  set gth_sysclkp_i_0 [ create_bd_port -dir I gth_sysclkp_i_0 ]
  set gth_txn_o_0 [ create_bd_port -dir O -from 7 -to 0 gth_txn_o_0 ]
  set gth_txp_o_0 [ create_bd_port -dir O -from 7 -to 0 gth_txp_o_0 ]

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {50.0} \
    CONFIG.CLKOUT1_JITTER {106.024} \
    CONFIG.CLKOUT1_PHASE_ERROR {82.655} \
    CONFIG.CLKOUT2_JITTER {92.799} \
    CONFIG.CLKOUT2_PHASE_ERROR {82.655} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {Custom} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {6.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {5.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {6} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.NUM_OUT_CLKS {2} \
    CONFIG.PRIM_IN_FREQ {200.000} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.RESET_BOARD_INTERFACE {reset} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true} \
  ] $clk_wiz_0


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: jtag_axi_0, and set properties
  set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_0 ]

  puts "creating counters"
  # Create instance: counters
  create_hier_cell_counters [current_bd_instance .] counters

  # Create instance: tg_bc
  create_hier_cell_tg_bc [current_bd_instance .] tg_bc

  # Create instance: example_ibert_ultrascale_0, and set properties
  set block_name example_ibert_ultrascale_gth_0
  set block_cell_name example_ibert_ultrascale_0
  if { [catch {set example_ibert_ultrascale_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $example_ibert_ultrascale_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net default_sysclk1_lpddrmc_1 [get_bd_intf_ports default_sysclk1_lpddrmc] [get_bd_intf_pins tg_bc/default_sysclk1_lpddrmc]
  connect_bd_intf_net -intf_net jtag_axi_0_M_AXI [get_bd_intf_pins jtag_axi_0/M_AXI] [get_bd_intf_pins tg_bc/S00_AXI]
  connect_bd_intf_net -intf_net lpddrmc_0_LPDDR5 [get_bd_intf_ports lpddr5_sdram] [get_bd_intf_pins tg_bc/lpddr5_sdram]

  # Create port connections
  connect_bd_net -net clk_wiz_0_clk_out1  [get_bd_pins clk_wiz_0/clk_out1] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
  [get_bd_pins jtag_axi_0/aclk] \
  [get_bd_pins tg_bc/aclk]
  connect_bd_net -net clk_wiz_0_clk_out2  [get_bd_pins clk_wiz_0/clk_out2] \
  [get_bd_pins tg_bc/clk]
  connect_bd_net -net example_ibert_ultrascale_0_gth_txn_o  [get_bd_pins example_ibert_ultrascale_0/gth_txn_o] \
  [get_bd_ports gth_txn_o_0]
  connect_bd_net -net example_ibert_ultrascale_0_gth_txp_o  [get_bd_pins example_ibert_ultrascale_0/gth_txp_o] \
  [get_bd_ports gth_txp_o_0]
  connect_bd_net -net example_ibert_ultrascale_0_sys_clock_out  [get_bd_pins example_ibert_ultrascale_0/sys_clock_out] \
  [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net gth_refclk0n_i_0_1  [get_bd_ports gth_refclk0n_i_0] \
  [get_bd_pins example_ibert_ultrascale_0/gth_refclk0n_i]
  connect_bd_net -net gth_refclk0p_i_0_1  [get_bd_ports gth_refclk0p_i_0] \
  [get_bd_pins example_ibert_ultrascale_0/gth_refclk0p_i]
  connect_bd_net -net gth_refclk1n_i_0_1  [get_bd_ports gth_refclk1n_i_0] \
  [get_bd_pins example_ibert_ultrascale_0/gth_refclk1n_i]
  connect_bd_net -net gth_refclk1p_i_0_1  [get_bd_ports gth_refclk1p_i_0] \
  [get_bd_pins example_ibert_ultrascale_0/gth_refclk1p_i]
  connect_bd_net -net gth_rxn_i_0_1  [get_bd_ports gth_rxn_i_0] \
  [get_bd_pins example_ibert_ultrascale_0/gth_rxn_i]
  connect_bd_net -net gth_rxp_i_0_1  [get_bd_ports gth_rxp_i_0] \
  [get_bd_pins example_ibert_ultrascale_0/gth_rxp_i]
  connect_bd_net -net gth_sysclkn_i_0_1  [get_bd_ports gth_sysclkn_i_0] \
  [get_bd_pins example_ibert_ultrascale_0/gth_sysclkn_i]
  connect_bd_net -net gth_sysclkp_i_0_1  [get_bd_ports gth_sysclkp_i_0] \
  [get_bd_pins example_ibert_ultrascale_0/gth_sysclkp_i]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins jtag_axi_0/aresetn] \
  [get_bd_pins tg_bc/aresetn]
  connect_bd_net -net resetn_0_1  [get_bd_ports resetn_0] \
  [get_bd_pins clk_wiz_0/resetn] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins counters/locked]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins counters/clk100]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins counters/clk200]

  # Create address segments
  assign_bd_address -offset 0xC0000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs tg_bc/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs tg_bc/lpddrmc_0/LPDDRMC_S0_AXI/LPDDRMC_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs tg_bc/sim_trig_0/SIM_TRIG_MEMORY_MAP/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces tg_bc/perf_axi_tg_0/Data] [get_bd_addr_segs tg_bc/lpddrmc_0/LPDDRMC_S1_AXI/LPDDRMC_ADDRESS_BLOCK] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
