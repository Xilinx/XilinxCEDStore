// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// Description: Top level testbench
//
//------------------------------------------------------------------------------

`timescale 1ps/1ps

`include "board_common.vh"

`define SIMULATION

module board;

  parameter          REF_CLK_FREQ       = 0 ;      // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz




  localparam         REF_CLK_HALF_CYCLE = (REF_CLK_FREQ == 0) ? 5000 :
                                          (REF_CLK_FREQ == 1) ? 4000 :
                                          (REF_CLK_FREQ == 2) ? 2000 : 0;

  
  localparam         SYS_CLK_HALF_CYCLE = 2500;

  localparam   [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b011;
  `ifdef LINKWIDTH
  localparam   [4:0] LINK_WIDTH = 5'd`LINKWIDTH;
  `else
  localparam   [4:0] LINK_WIDTH = 5'd4;
  `endif
  `ifdef LINKSPEED
  localparam   [2:0] LINK_SPEED = 3'h`LINKSPEED;
  `else
  localparam   [2:0] LINK_SPEED = 3'h4;
  `endif



//  defparam board.EP.qdma_0_i.inst.pcie4_ip_i.inst.PL_SIM_FAST_LINK_TRAINING=2'h3;

  localparam EXT_PIPE_SIM = "FALSE";

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

 sys_clk_gen_ds # (
    .halfcycle(SYS_CLK_HALF_CYCLE), 
    .offset(0)
  )
  SYS_GEN (
    .sys_clk_p(sys_clk_in_p),
    .sys_clk_n(sys_clk_in_n)
  );
  

  //------------------------------------------------------------------------------//
  // Generate system-level reset
  //------------------------------------------------------------------------------//
  parameter ON=3, OFF=4, UNIQUE=32, UNIQUE0=64, PRIORITY=128;

  initial begin
    `ifndef XILINX_SIMULATOR
    // Disable UNIQUE, UNIQUE0, and PRIORITY analysis during reset because signal can be at unknown value during reset
    $assertcontrol( OFF , UNIQUE | UNIQUE0 | PRIORITY);
    `endif

    $display("[%t] : System Reset Is Asserted...", $realtime);
    sys_rst_n = 1'b0;
 // IMPL SIM   board.EP.design_1_i.versal_cips_0.inst.perst0n =  1'b0;
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : System Reset Is De-asserted...", $realtime);
    sys_rst_n = 1'b1;
 // IMPL SIM   board.EP.design_1_i.versal_cips_0.inst.perst0n  =  1'b1;

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
   
  design_1_wrapper
   EP (

    .CH0_DDR4_0_act_n  (),  
    .CH0_DDR4_0_adr    (),
    .CH0_DDR4_0_ba     (),
    .CH0_DDR4_0_bg     (),
    .CH0_DDR4_0_ck_c   (),
    .CH0_DDR4_0_ck_t   (),
    .CH0_DDR4_0_cke    (),
    .CH0_DDR4_0_cs_n   (),
    .CH0_DDR4_0_dm_n   (),
    .CH0_DDR4_0_dq     (),
    .CH0_DDR4_0_dqs_c  (),
    .CH0_DDR4_0_dqs_t  (),
    .CH0_DDR4_0_odt    (),
    .CH0_DDR4_0_reset_n(),

    // SYS Inteface
    .GT_REFCLK0_D_0_clk_n(ep_sys_clk_n),
    .GT_REFCLK0_D_0_clk_p(ep_sys_clk_p),
    .SYS_CLK0_IN_0_clk_n (sys_clk_in_p), 
    .SYS_CLK0_IN_0_clk_p (sys_clk_in_n),
    .CLK_IN1_D_0_clk_p   (ep_sys_clk_p),
    .CLK_IN1_D_0_clk_n   (ep_sys_clk_n),

    // PCI-Express Serial Interface
    .GT_Serial_TX_0_txn(ep_pci_exp_txn),
    .GT_Serial_TX_0_txp(ep_pci_exp_txp),
    .GT_Serial_RX_0_rxn(rp_pci_exp_txn),
    .GT_Serial_RX_0_rxp(rp_pci_exp_txp)
  
  );

  //------------------------------------------------------------------------------//
  // Simulation Root Port Model
  // (Comment out this module to interface EndPoint with BFM)
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Model Root Port Instance
  //

  xilinx_pcie4_uscale_rp
  #(
     .PF0_DEV_CAP_MAX_PAYLOAD_SIZE(PF0_DEV_CAP_MAX_PAYLOAD_SIZE)
     //ONLY FOR RP
  ) RP (

    // SYS Inteface
    .sys_clk_n(rp_sys_clk_n),
    .sys_clk_p(rp_sys_clk_p),
    .sys_rst_n                  ( sys_rst_n ),
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
