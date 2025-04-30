//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : The Xilinx PCI Express DMA
// File       : board.v
// Version    : 5.0
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// Project    : Ultrascale FPGA Gen3 Integrated Block for PCI Express
// File       : board.v
// Version    : 4.0
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// Description: Top level testbench
//
//------------------------------------------------------------------------------

`timescale 1ps/1ps

`include "board_common.vh"

`define SIMULATION

module board;

  parameter REF_CLK_FREQ = 0 ;      // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  localparam REF_CLK_HALF_CYCLE = (REF_CLK_FREQ == 0) ? 5000 :
                                  (REF_CLK_FREQ == 1) ? 4000 :
                                  (REF_CLK_FREQ == 2) ? 2000 : 0;

  localparam   [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b010;
  `ifdef LINKWIDTH
  localparam   [4:0] LINK_WIDTH = 5'd`LINKWIDTH;
  `else
  localparam   [4:0] LINK_WIDTH = 5'd8;
  `endif
  `ifdef LINKSPEED
  localparam   [2:0] LINK_SPEED = 3'h`LINKSPEED;
  `else
  localparam   [3:0] LINK_SPEED = 4'h8;
  `endif

  // System-level clock and reset
  reg  sys_rst_n;

  wire ep_sys_clk;
  wire rp_sys_clk;
  wire ep_sys_clk_p;
  wire ep_sys_clk_n;
  wire rp_sys_clk_p;
  wire rp_sys_clk_n;

  //
  // PCI-Express Serial Interconnect
  //
  wire  [(LINK_WIDTH-1):0]  ep_pci_exp_txn;
  wire  [(LINK_WIDTH-1):0]  ep_pci_exp_txp;
  wire  [(LINK_WIDTH-1):0]  rp_pci_exp_txn;
  wire  [(LINK_WIDTH-1):0]  rp_pci_exp_txp;

  //------------------------------------------------------------------------------//
  // Generate system clock
  //------------------------------------------------------------------------------//
  sys_clk_gen_ds # (
    .halfcycle(REF_CLK_HALF_CYCLE),
    .offset(0)
  )
  CLK_GEN_RP (
    .sys_clk_p(rp_sys_clk_p),
    .sys_clk_n(rp_sys_clk_n)
  );

  sys_clk_gen_ds # (
    .halfcycle(REF_CLK_HALF_CYCLE),
    .offset(0)
  )
  CLK_GEN_EP (
    .sys_clk_p(ep_sys_clk_p),
    .sys_clk_n(ep_sys_clk_n)
  );

  wire [13:0] pcie0_pipe_rp_0_commands_in;
  wire [13:0] pcie0_pipe_rp_0_commands_out;
  wire [41:0] pcie0_pipe_rp_0_rx_0;
  wire [41:0] pcie0_pipe_rp_0_rx_1;
  wire [41:0] pcie0_pipe_rp_0_rx_2;
  wire [41:0] pcie0_pipe_rp_0_rx_3;
  wire [41:0] pcie0_pipe_rp_0_rx_4;
  wire [41:0] pcie0_pipe_rp_0_rx_5;
  wire [41:0] pcie0_pipe_rp_0_rx_6;
  wire [41:0] pcie0_pipe_rp_0_rx_7;
  wire [41:0] pcie0_pipe_rp_0_rx_8;
  wire [41:0] pcie0_pipe_rp_0_rx_9;
  wire [41:0] pcie0_pipe_rp_0_rx_10;
  wire [41:0] pcie0_pipe_rp_0_rx_11;
  wire [41:0] pcie0_pipe_rp_0_rx_12;
  wire [41:0] pcie0_pipe_rp_0_rx_13;
  wire [41:0] pcie0_pipe_rp_0_rx_14;
  wire [41:0] pcie0_pipe_rp_0_rx_15;
  wire [41:0] pcie0_pipe_rp_0_tx_0;
  wire [41:0] pcie0_pipe_rp_0_tx_1;
  wire [41:0] pcie0_pipe_rp_0_tx_2;
  wire [41:0] pcie0_pipe_rp_0_tx_3;
  wire [41:0] pcie0_pipe_rp_0_tx_4;
  wire [41:0] pcie0_pipe_rp_0_tx_5;
  wire [41:0] pcie0_pipe_rp_0_tx_6;
  wire [41:0] pcie0_pipe_rp_0_tx_7;
  wire [41:0] pcie0_pipe_rp_0_tx_8;
  wire [41:0] pcie0_pipe_rp_0_tx_9;
  wire [41:0] pcie0_pipe_rp_0_tx_10;
  wire [41:0] pcie0_pipe_rp_0_tx_11;
  wire [41:0] pcie0_pipe_rp_0_tx_12;
  wire [41:0] pcie0_pipe_rp_0_tx_13;
  wire [41:0] pcie0_pipe_rp_0_tx_14;
  wire [41:0] pcie0_pipe_rp_0_tx_15;

  //------------------------------------------------------------------------------//
  // EndPoint DUT with PIO Slave
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Endpoint Instance
  //
  design_1_wrapper_sim_wrapper
  EP (
    // SYS Inteface
    .GT_REFCLK0_D_0_clk_n(ep_sys_clk_n),
    .GT_REFCLK0_D_0_clk_p(ep_sys_clk_p),

    // PCI-Express Serial Interface
    .GT_Serial_TX_0_txn(ep_pci_exp_txn),
    .GT_Serial_TX_0_txp(ep_pci_exp_txp),
    .GT_Serial_RX_0_rxn(rp_pci_exp_txn),
    .GT_Serial_RX_0_rxp(rp_pci_exp_txp)
  );

   initial begin
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_0 = pcie0_pipe_rp_0_rx_0;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_1 = pcie0_pipe_rp_0_rx_1;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_2 = pcie0_pipe_rp_0_rx_2;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_3 = pcie0_pipe_rp_0_rx_3;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_4 = pcie0_pipe_rp_0_rx_4;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_5 = pcie0_pipe_rp_0_rx_5;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_6 = pcie0_pipe_rp_0_rx_6;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_7 = pcie0_pipe_rp_0_rx_7;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_8 = pcie0_pipe_rp_0_rx_8;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_9 = pcie0_pipe_rp_0_rx_9;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_10 = pcie0_pipe_rp_0_rx_10;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_11 = pcie0_pipe_rp_0_rx_11;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_12 = pcie0_pipe_rp_0_rx_12;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_13 = pcie0_pipe_rp_0_rx_13;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_14 = pcie0_pipe_rp_0_rx_14;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_15 = pcie0_pipe_rp_0_rx_15;

	force pcie0_pipe_rp_0_tx_0 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_0;
	force pcie0_pipe_rp_0_tx_1 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_1;
	force pcie0_pipe_rp_0_tx_2 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_2;
	force pcie0_pipe_rp_0_tx_3 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_3;
	force pcie0_pipe_rp_0_tx_4 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_4;
	force pcie0_pipe_rp_0_tx_5 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_5;
	force pcie0_pipe_rp_0_tx_6 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_6;
	force pcie0_pipe_rp_0_tx_7 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_7;
	force pcie0_pipe_rp_0_tx_8 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_8;
	force pcie0_pipe_rp_0_tx_9 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_9;
	force pcie0_pipe_rp_0_tx_10 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_10;
	force pcie0_pipe_rp_0_tx_11 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_11;
	force pcie0_pipe_rp_0_tx_12 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_12;
	force pcie0_pipe_rp_0_tx_13 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_13;
	force pcie0_pipe_rp_0_tx_14 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_14;
	force pcie0_pipe_rp_0_tx_15 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_15;

	force pcie0_pipe_rp_0_commands_out = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_commands_out;
	force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_commands_in = pcie0_pipe_rp_0_commands_in;

   end // initial begin

  //------------------------------------------------------------------------------//
  // Simulation Root Port Model
  // (Comment out this module to interface EndPoint with BFM)
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Model Root Port Instance
  //
  xilinx_pcie4_uscale_rp
  #(
    .PF0_DEV_CAP_MAX_PAYLOAD_SIZE(PF0_DEV_CAP_MAX_PAYLOAD_SIZE),
    .PL_LINK_CAP_MAX_LINK_WIDTH(LINK_WIDTH),
    .PL_LINK_CAP_MAX_LINK_SPEED(LINK_SPEED)
    //ONLY FOR RP
  ) RP (
    // SYS Inteface
    .sys_clk_n(rp_sys_clk_n),
    .sys_clk_p(rp_sys_clk_p),
    .sys_rst_n(sys_rst_n),
    // PCI-Express Serial Interface
    .pci_exp_txn(rp_pci_exp_txn),
    .pci_exp_txp(rp_pci_exp_txp),
    .pci_exp_rxn(ep_pci_exp_txn),
    .pci_exp_rxp(ep_pci_exp_txp),

    .pcie0_pipe_rp_0_commands_in (pcie0_pipe_rp_0_commands_in),
    .pcie0_pipe_rp_0_commands_out(pcie0_pipe_rp_0_commands_out),

    .pcie0_pipe_rp_0_rx_0 (pcie0_pipe_rp_0_rx_0),
    .pcie0_pipe_rp_0_rx_1 (pcie0_pipe_rp_0_rx_1),
    .pcie0_pipe_rp_0_rx_2 (pcie0_pipe_rp_0_rx_2),
    .pcie0_pipe_rp_0_rx_3 (pcie0_pipe_rp_0_rx_3),
    .pcie0_pipe_rp_0_rx_4 (pcie0_pipe_rp_0_rx_4),
    .pcie0_pipe_rp_0_rx_5 (pcie0_pipe_rp_0_rx_5),
    .pcie0_pipe_rp_0_rx_6 (pcie0_pipe_rp_0_rx_6),
    .pcie0_pipe_rp_0_rx_7 (pcie0_pipe_rp_0_rx_7),
    .pcie0_pipe_rp_0_rx_8 (pcie0_pipe_rp_0_rx_8),
    .pcie0_pipe_rp_0_rx_9 (pcie0_pipe_rp_0_rx_9),
    .pcie0_pipe_rp_0_rx_10(pcie0_pipe_rp_0_rx_10),
    .pcie0_pipe_rp_0_rx_11(pcie0_pipe_rp_0_rx_11),
    .pcie0_pipe_rp_0_rx_12(pcie0_pipe_rp_0_rx_12),
    .pcie0_pipe_rp_0_rx_13(pcie0_pipe_rp_0_rx_13),
    .pcie0_pipe_rp_0_rx_14(pcie0_pipe_rp_0_rx_14),
    .pcie0_pipe_rp_0_rx_15(pcie0_pipe_rp_0_rx_15),

    .pcie0_pipe_rp_0_tx_0 (pcie0_pipe_rp_0_tx_0),
    .pcie0_pipe_rp_0_tx_1 (pcie0_pipe_rp_0_tx_1),
    .pcie0_pipe_rp_0_tx_2 (pcie0_pipe_rp_0_tx_2),
    .pcie0_pipe_rp_0_tx_3 (pcie0_pipe_rp_0_tx_3),
    .pcie0_pipe_rp_0_tx_4 (pcie0_pipe_rp_0_tx_4),
    .pcie0_pipe_rp_0_tx_5 (pcie0_pipe_rp_0_tx_5),
    .pcie0_pipe_rp_0_tx_6 (pcie0_pipe_rp_0_tx_6),
    .pcie0_pipe_rp_0_tx_7 (pcie0_pipe_rp_0_tx_7),
    .pcie0_pipe_rp_0_tx_8 (pcie0_pipe_rp_0_tx_8),
    .pcie0_pipe_rp_0_tx_9 (pcie0_pipe_rp_0_tx_9),
    .pcie0_pipe_rp_0_tx_10(pcie0_pipe_rp_0_tx_10),
    .pcie0_pipe_rp_0_tx_11(pcie0_pipe_rp_0_tx_11),
    .pcie0_pipe_rp_0_tx_12(pcie0_pipe_rp_0_tx_12),
    .pcie0_pipe_rp_0_tx_13(pcie0_pipe_rp_0_tx_13),
    .pcie0_pipe_rp_0_tx_14(pcie0_pipe_rp_0_tx_14),
    .pcie0_pipe_rp_0_tx_15(pcie0_pipe_rp_0_tx_15)
  );

  initial begin
    if ($test$plusargs ("dump_all")) begin
  `ifdef NCV // Cadence TRN dump
      $recordsetup("design=board",
                   "compress",
                   "wrapsize=100M",
                   "version=1",
                   "run=1");
      $recordvars();

  `elsif VCS //Synopsys VPD dump
      $vcdplusfile("board.vpd");
      $vcdpluson;
      $vcdplusglitchon;
      $vcdplusflush;

  `else
      // Verilog VC dump
      $dumpfile("board.vcd");
      $dumpvars(0, board);

  `endif

    end
  end

 // Simulation
 parameter ON=3, OFF=4, UNIQUE=32, UNIQUE0=64, PRIORITY=128;

initial begin
  // Enable Multi Clock Support API
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.en_multi_clock_support();
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.en_multi_clock_support();
  // cpm_osc_clk_div2_gen_clock = 200MHz
  // cpm_gen_clock = 33.33MHz
  // ps_gen_clk = 1GHz
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_osc_clk_div2_gen_clock(100);
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_osc_clk_div2_gen_clock(100);

  // Set VIP PL output clocks
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(0,250);
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(1,250);
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(2,250);
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(3,250);

  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(0,250);
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(1,250);
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(2,250);
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(3,250);

  // Enable CPM PS AXI to PS NOC AXI routing (both AXI MM 0 and AXI MM 1)
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.set_routing_config("CPMPSAXI0","PSNOCPCIAXI0",1);
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.set_routing_config("CPMPSAXI1","PSNOCPCIAXI1",1);
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.set_routing_config("NOCPSPCIAXI0","PSCPMPCIEAXI",1);

  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.set_routing_config("CPMPSAXI0","PSNOCPCIAXI0",1);
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.set_routing_config("CPMPSAXI1","PSNOCPCIAXI1",1);

  // Assert PCIe reset
  $display("[%t] : System Reset Is Asserted...", $realtime);
  // Root Port reset assert
  sys_rst_n = 1'b0;
  // Endpoint reset assert
  force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b0;
  force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b0;

  force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b0;
  force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b0;
  // Assert VIP PL output resets
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'h0);
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'h0);
  // POR reset is the master reset for the PS Simulation Model. Deserting will enable the PS-VIP.
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(0);
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(0);

  // Release resets after some delay
  repeat (500) @(posedge rp_sys_clk_p);
  $display("[%t] : System Reset Is De-asserted...", $realtime);
  // Root port reset release
  sys_rst_n = 1'b1;

  // Release reset on the PL
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'hF);
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'hF);
  
  // Release reset on the PS-VIP
  board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(1);
  board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(1);

  // Wait for CDO load to complete before releasing PCIe reset
  wait(board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.CPM_INST.CPM_MAIN_INST.SIP_CPM_MAIN_INST.i_cpm_sim_cfg_wrap.u_cpm_sim_cfg.cdo_programming_done);
  $display("[%t] : RP CDO programming done...", $realtime);
  wait(board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.CPM_INST.CPM_MAIN_INST.SIP_CPM_MAIN_INST.i_cpm_sim_cfg_wrap.u_cpm_sim_cfg.cdo_programming_done);
  $display("[%t] : EP CDO programming done...", $realtime);

  // Endpoint reset release
  force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b1;
  force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b1;

  force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b1;
  force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b1;

  `ifndef XILINX_SIMULATOR
  // Re-enable UNIQUE, UNIQUE0, and PRIORITY analysis
  $assertcontrol( ON , UNIQUE | UNIQUE0 | PRIORITY);
  `endif
end


endmodule // BOARD

