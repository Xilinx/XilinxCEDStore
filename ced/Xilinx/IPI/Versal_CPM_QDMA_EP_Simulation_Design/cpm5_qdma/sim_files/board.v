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
//`include "cpm5_mdma_defines.svh"
//`include "h10_cisco_cmpt_sig.svh"
`define SIMULATION

module board;

  parameter          REF_CLK_FREQ       = 0 ;      // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz




  localparam         REF_CLK_HALF_CYCLE = (REF_CLK_FREQ == 0) ? 5000 :
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
  localparam   [2:0] LINK_SPEED = 3'h8;
  `endif

  localparam EXT_PIPE_SIM = "FALSE";
  localparam EP_DATA_WIDTH = 512;

//  `include  "h10_cisco_cmpt_sig.svh"
   
   
  // RP cdo file
//  defparam board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.CPM_INST.SIM_CPM_CDO_FILE_NAME = "rp_cpm_data_sim.cdo";

   integer            i;

  // System-level clock and reset
  reg                sys_rst_n;

  wire               ep_sys_clk;
  wire               rp_sys_clk;
  wire               ep_sys_clk_p;
  wire               ep_sys_clk_n;
  wire               rp_sys_clk_p;
  wire               rp_sys_clk_n;



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



  //------------------------------------------------------------------------------//
  // Generate system-level reset
  //------------------------------------------------------------------------------//
  parameter ON=3, OFF=4, UNIQUE=32, UNIQUE0=64, PRIORITY=128;
  reg lpdcpmtopswclk;
  
  initial begin
    // Create clocks for the CPM LPD domain to NOC clock (lpdcpmtopswclk)
    // Set the frequency based on GUI selection.
    lpdcpmtopswclk = 0;
    forever #(500) lpdcpmtopswclk = ~lpdcpmtopswclk;
  end

   // Enable PIPESIM
   defparam board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.C_CPM_PIPESIM = "TRUE";
   defparam board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.C_CPM_PIPESIM = "TRUE";
   
   // Set the PIPESIM clock generation. TRUE = Generate PIPESIM clock and our PIPE is synced to this clock. FALSE = We take in PIPESIM clock and sync our PIPE to that clock.
 //  defparam board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.in st.PIPESIM_CLK_MASTER = "FALSE";
 //  defparam board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.PIPESIM_CLK_MASTER = "TRUE";
 
   // PIPESIM Signal Assignments
   initial begin
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_commands_in = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_commands_out;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_commands_in = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_commands_out;
      
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_0 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_0;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_1 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_1;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_2 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_2;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_3 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_3;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_4 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_4;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_5 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_5;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_6 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_6;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_7 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_7;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_8 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_8;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_9 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_9;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_10 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_10;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_11 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_11;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_12 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_12;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_13 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_13;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_14 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_14;
      force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_rx_15 = board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_tx_15;
      

      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_0 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_0;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_1 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_1;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_2 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_2;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_3 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_3;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_4 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_4;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_5 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_5;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_6 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_6;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_7 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_7;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_8 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_8;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_9 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_9;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_10 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_10;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_11 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_11;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_12 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_12;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_13 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_13;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_14 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_14;
      force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.pcie0_pipe_rx_15 = board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.pcie1_pipe_tx_15;
      
   end // initial begin
   
  initial begin
    // New Bug.. NoC
     //force board.EP.design_1_wrapper_i.design_1_i.axi_noc_0.M01_AXI_bid = 2'h0;
     //force board.EP.design_1_wrapper_i.design_1_i.axi_noc_0.M01_AXI_rid = 2'h0 ;
  
    // CR-1118514
//    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.qdma_0_wrapper_i.s_axis_mdma_c2h_ctrl_qid[11] = 1'b0;
//    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.qdma_0_wrapper_i.mdma_dsc_crdt_in_qid[12:11]  = 2'b00;
//    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.qdma_0_wrapper_i.h2c_byp_in_st_qid[12:11]     = 2'b00;
    
//    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.qdma_0_wrapper_i.c2h_byp_in_mm_0_qid[12:11]   = 2'b00;
//    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.qdma_0_wrapper_i.c2h_byp_in_mm_1_qid[12:11]   = 2'b00;
//    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.qdma_0_wrapper_i.h2c_byp_in_mm_0_qid[12:11]   = 2'b00;
//    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.qdma_0_wrapper_i.h2c_byp_in_mm_1_qid[12:11]   = 2'b00;
    
    // Create the PS-VIP clock
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.versal_cips_ps_vip_clk = lpdcpmtopswclk;
    force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.versal_cips_ps_vip_clk = lpdcpmtopswclk;
    
    // Set VIP PL output clocks based on GUI selection
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(0,250);
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(1,250);
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(2,250);
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(3,250);
    
    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(0,250);
    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(1,250);
    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(2,250);
    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(3,250);
    
    // Generate Reference Clocks for the CPM
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_gen_clock(100);
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_osc_clk_div2_gen_clock(100);

    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_gen_clock(100);
    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_osc_clk_div2_gen_clock(100);  
    
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
    // Endpoint reset assert based on GUI selection for each controller
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b0;
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b0;
    // Assert VIP PL output resets based on GUI Selection
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'h0);
    // POR reset is the master reset for the PS Simulation Model. Deserting will enable the PS-VIP.
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(0);
    
    // RP reset assert based on GUI selection for each controller
    force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b0;
    force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b0;
    // Assert VIP PL output resets based on GUI Selection
    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'h0);
    // POR reset is the master reset for the PS Simulation Model. Deserting will enable the PS-VIP.
    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(0);
    
    // Need hack for LPD CPM5 POR_N
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.lpd_cpm5_por_n = 1'b0;
    force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.lpd_cpm5_por_n = 1'b0;
 
    // Release resets after some delay
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : System Reset Is De-asserted...", $realtime);
    // Root port reset release
    sys_rst_n = 1'b1;
    // De-assert VIP PL output resets based on GUI Selection
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'hF);
    // Release reset on the PS-VIP
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(1);
    
    // De-assert VIP PL output resets based on GUI Selection
    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'hF);
    // Release reset on the PS-VIP
    board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(1);
    
    // Need hack for LPD CPM5 POR_N
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.lpd_cpm5_por_n = 1'b1;
    force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.cpm_0.inst.lpd_cpm5_por_n = 1'b1;
    
    //repeat (545000) @(posedge rp_sys_clk_p);
    repeat (5200) @(posedge rp_sys_clk_p);
    // Endpoint reset release based on GUI selection.
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b1;
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b1;
    // RP reset release based on GUI selection.
    force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b1;
    force board.RP.design_rp_wrapper_i.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b1;
 
    `ifndef XILINX_SIMULATOR
    // Re-enable UNIQUE, UNIQUE0, and PRIORITY analysis
    $assertcontrol( ON , UNIQUE | UNIQUE0 | PRIORITY);
    `endif
  end
  //------------------------------------------------------------------------------//

  //------------------------------------------------------------------------------//
  // EndPoint DUT with PIO Slave
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Endpoint Instance
  //

  design_1_wrapper_sim_wrapper
   EP (
    // SYS Inteface
    .gt_refclk1_0_clk_n(ep_sys_clk_n),
    .gt_refclk1_0_clk_p(ep_sys_clk_p),
//    .sys_rst_n(sys_rst_n),

    .sys_clk0_0_clk_n (ep_sys_clk_n),
    .sys_clk0_0_clk_p (ep_sys_clk_p),
    // PCI-Express Serial Interface
    .PCIE1_GT_0_gtx_n(ep_pci_exp_txn),
    .PCIE1_GT_0_gtx_p(ep_pci_exp_txp),
    .PCIE1_GT_0_grx_n(rp_pci_exp_txn),
    .PCIE1_GT_0_grx_p(rp_pci_exp_txp)

  );  //------------------------------------------------------------------------------//
  // Simulation Root Port Model
  // (Comment out this module to interface EndPoint with BFM)
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Model Root Port Instance
  //

  xilinx_pcie5_versal_rp # (
    .PF0_DEV_CAP_MAX_PAYLOAD_SIZE ( PF0_DEV_CAP_MAX_PAYLOAD_SIZE )
  ) RP (

    // SYS Inteface
    .sys_clk_n(rp_sys_clk_n),
    .sys_clk_p(rp_sys_clk_p),
    .sys_rst_n(sys_rst_n),
    // PCI-Express Serial Interface
    .pci_exp_txn(rp_pci_exp_txn),
    .pci_exp_txp(rp_pci_exp_txp),
    .pci_exp_rxn(ep_pci_exp_txn),
    .pci_exp_rxp(ep_pci_exp_txp)

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



endmodule // BOARD
