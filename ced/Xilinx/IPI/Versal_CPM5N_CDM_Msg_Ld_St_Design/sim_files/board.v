//-----------------------------------------------------------------------------
//
// (c) Copyright 2020-2024 Xilinx, Inc. All rights reserved.
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
// Project    : Versal CPM5N BMD Test bench 
// File       : board.v
// Version    : 31.0 
//-----------------------------------------------------------------------------
//
// Description: Top level testbench
//
//------------------------------------------------------------------------------

`timescale 1ps/1ps

`include "board_common.vh"

`define SIMULATION
`define XIL_TIMING
module board;

  //localparam PIPE_SIM_EN = board.EP.design_1_i.psx_wizard_0.inst.cpm5n_0;
  localparam REF_CLK_FREQ = 0 ; // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  localparam [4:0] LINK_WIDTH = 5'd16;
  localparam [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b010;

  localparam REF_CLK_HALF_CYCLE = (REF_CLK_FREQ == 0) ? 5000 :
                                  (REF_CLK_FREQ == 1) ? 4000 :
                                  (REF_CLK_FREQ == 2) ? 2000 : 0;


  // System-level clock and reset
  reg sys_rst_n;

  wire ep_sys_clk_p;
  wire ep_sys_clk_n;
  wire rp_sys_clk_p;
  wire rp_sys_clk_n;
  
  //defparam board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIM_CPM_CDO_FILE_NAME = "../../../../../Versal_CPM5N_CDM_Msg_Ld_St_Design/cdo/msgst_ld/bd_c6ab_cpm5n_0_0_sim.cdo";
  defparam board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIM_CPM_CDO_FILE_NAME = "bd_f3b5_cpm5n_0_0_sim.cdo";
  //
  // PCI-Express Serial Interconnect
  //
  wire  [(LINK_WIDTH-1):0]  ep_pci_exp_txn;
  wire  [(LINK_WIDTH-1):0]  ep_pci_exp_txp;
  wire  [(LINK_WIDTH-1):0]  rp_pci_exp_txn;
  wire  [(LINK_WIDTH-1):0]  rp_pci_exp_txp;
  

  
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

  parameter ON=3, OFF=4, UNIQUE=32, UNIQUE0=64, PRIORITY=128;
  reg lpdcpmtopswclk;
  reg clk1000mhz;
  reg clk250mhz;
  reg clk33_3mhz;
  reg perstn;

  
  initial begin
    // Create clocks for the CPM LPD domain to NOC clock (lpdcpmtopswclk)
    // Set the frequency based on GUI selection.
    lpdcpmtopswclk = 0;
    forever #(500) lpdcpmtopswclk = ~lpdcpmtopswclk;
  end
  // Other clocks
  initial begin
    // Generate Clocks
    clk1000mhz = 0;
    forever #(500) clk1000mhz = ~clk1000mhz;
  end
  initial begin
    clk250mhz  = 0;
    forever #(2000)  clk250mhz  = ~clk250mhz;
  end
  initial begin
    clk33_3mhz = 0;
    forever #(15000) clk33_3mhz = ~clk33_3mhz;
  end
  
  initial begin
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst1n = 0;               // PCIe1 not enabled
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst2n = 0;               // PCIe2 not enabled
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst3n = 0;               // PCIe3 not enabled
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.pl_ref_clk = 0;       //  SA: PLCPMREFCLK not used. Turn off clocks to speed up sim
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cpm_top_user_clk = 0; // Only using BOTCLK for CTRL0
    
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst0n = perstn;
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_bot_rst_n = perstn;
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_top_rst_n = perstn;
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.lpd_cpm5n_por_n = sys_rst_n; // POR Deassert
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.dbg_lpd_raw_rstn = sys_rst_n; // LPD RAW RSTN deassert (New.. Unsure what domain this is)
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.ps_pcr_init_state = ~sys_rst_n;  
    force board.EP.user_reset = ~sys_rst_n;
    
    //Clocks
    force board.EP.cpm_bot_user_clk = clk250mhz;
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.lpd_swclk = clk1000mhz; 
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.lpd_refclk_in = clk33_3mhz;
    force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.cpm_osc_clk_div2 = clk1000mhz;
    
    // RP
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst1n = 0;                // PCIe1 not enabled
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst2n = 0;                // PCIe2 not enabled
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst3n = 0;                // PCIe3 not enabled
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.pl_ref_clk = 0;        //  SA: PLCPMREFCLK not used. Turn off clocks to speed up sim
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.cpm_top_user_clk  = 0; // Only using BOTCLK for CTRL0

    force board.RP.user_reset = ~perstn;
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst0n = perstn;    
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_bot_rst_n = perstn;
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_top_rst_n = perstn;
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.lpd_cpm5n_por_n = sys_rst_n;
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.dbg_lpd_raw_rstn = sys_rst_n;
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.ps_pcr_init_state = ~sys_rst_n;

    //Clocks
    force board.RP.user_clk = clk250mhz;
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.lpd_swclk = clk1000mhz; 
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.lpd_refclk_in = clk33_3mhz; 
    force board.RP.design_rp_i.psx_wizard_0.inst.cpm5n_0.cpm_osc_clk_div2 = clk1000mhz;
    
  end
  
  initial begin
    // Assert System resets
    $display("[%t] : System Reset Is Asserted...", $realtime);
    $system("date +'%X--%x :  System Reset Is Asserted...' > time.log");
    perstn = 1'b0;
    sys_rst_n = 1'b0;
    
    // Release POR resets after some delay
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : POR Reset Is De-asserted...", $realtime);
    $system("date +'%X--%x :  POR Reset Is De-asserted...' >> time.log");
    sys_rst_n = 1'b1;
    
    // Wait for CDO load to complete before releasing PCIe reset
	repeat (38500) @(posedge rp_sys_clk_p);
//    repeat (5) @(posedge rp_sys_clk_p);//test
    $display("[%t] : PCIe Reset Is De-asserted...", $realtime);
    $system("date +'%X--%x :  PCIe Reset Is De-asserted...' >> time.log");

    // Endpoint reset release based on GUI selection.
    perstn = 1'b1;
  end

  //------------------------------------------------------------------------------//
  // Simulation endpoint with PIO Slave
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Endpoint Instance
  //

//  design_1_wrapper EP (
  cdm_msgld_msgst_top EP (
    // SYS Inteface
    .gt_refclk0_0_clk_n(ep_sys_clk_n),
    .gt_refclk0_0_clk_p(ep_sys_clk_p),
   // .sys_rst_n(sys_rst_n),
    //
    // PCI-Express Serial Interface
    //
    .PCIE0_GT_0_grx_n (rp_pci_exp_txn),
    .PCIE0_GT_0_grx_p (rp_pci_exp_txp),
    .PCIE0_GT_0_gtx_n (ep_pci_exp_txn),
    .PCIE0_GT_0_gtx_p (ep_pci_exp_txp)
	
  );

  //------------------------------------------------------------------------------//
  // Simulation Root Port Model
  // (Comment out this module to interface EndPoint with BFM)
  
  //------------------------------------------------------------------------------//
  // PCI-Express Model Root Port Instance
  //------------------------------------------------------------------------------//
  design_rp_wrapper #(
    .PF0_DEV_CAP_MAX_PAYLOAD_SIZE ( PF0_DEV_CAP_MAX_PAYLOAD_SIZE )
  ) RP (
    // SYS Inteface
    .sys_clk_n(rp_sys_clk_n),
    .sys_clk_p(rp_sys_clk_p),
    .sys_rst_n(sys_rst_n),
    //
    // PCI-Express Serial Interface
    //
    .pci_exp_rxn (ep_pci_exp_txn),
    .pci_exp_rxp (ep_pci_exp_txp),
    .pci_exp_txn (rp_pci_exp_txn),
    .pci_exp_txp (rp_pci_exp_txp)
	
   );
   
  //------------------------------------------------------------------------------//
  // PIPE Sim Signal Assignments
  //------------------------------------------------------------------------------//
  initial begin
    if (board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.C_CPM_PIPESIM == "TRUE") begin
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_commands_in = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_commands_in;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_commands_out = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_commands_out;
      
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_0  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_0;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_1  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_1;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_2  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_2;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_3  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_3;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_4  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_4;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_5  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_5;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_6  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_6;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_7  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_7;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_8  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_8;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_9  = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_9;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_10 = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_10;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_11 = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_11;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_12 = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_12;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_13 = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_13;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_14 = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_14;
      force board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_rx_15 = board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_rx_15;
      
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_0  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_0;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_1  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_1;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_2  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_2;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_3  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_3;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_4  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_4;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_5  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_5;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_6  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_6;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_7  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_7;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_8  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_8;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_9  = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_9;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_10 = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_10;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_11 = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_11;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_12 = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_12;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_13 = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_13;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_14 = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_14;
      force board.RP.design_rp_i.psx_wizard_0.pcie0_pipe_rp_tx_15 = board.EP.design_ep_wrapper_i.design_1_i.psx_wizard_0.pcie0_pipe_ep_tx_15;
    end
  end    
   


 initial begin
`ifndef XILINX_SIMULATOR
      // Re-enable UNIQUE, UNIQUE0, and PRIORITY analysis
      $assertcontrol( ON , UNIQUE | UNIQUE0 | PRIORITY);
`endif

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
