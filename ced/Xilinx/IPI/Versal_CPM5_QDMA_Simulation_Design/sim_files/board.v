// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps
`include "board_common.vh"
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
  localparam   [2:0] LINK_SPEED = 3'h4;
  `endif

  localparam EXT_PIPE_SIM = "FALSE";
  localparam EP_DATA_WIDTH = 512;
  
  // RP cdo file
  //defparam board.RP.design_rp_i.versal_cips_0.inst.cpm_0.inst.CPM_INST.SIM_CPM_CDO_FILE_NAME = "rp_cpm_data_sim.cdo";

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

  initial begin
    // Create the PS-VIP clock
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.versal_cips_ps_vip_clk = lpdcpmtopswclk;
    force board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.versal_cips_ps_vip_clk = lpdcpmtopswclk;
    
    // Set VIP PL output clocks based on GUI selection
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(0,250);
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(1,250);
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(2,250);
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(3,250);
    
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(0,250);
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(1,250);
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(2,250);
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_clock(3,250);
    
    // Generate Reference Clocks for the CPM
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_gen_clock(100);
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_osc_clk_div2_gen_clock(100);

    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_gen_clock(100);
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.cpm_osc_clk_div2_gen_clock(100);  
    
    // Enable CPM PS AXI to PS NOC AXI routing (both AXI MM 0 and AXI MM 1)
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.set_routing_config("CPMPSAXI0","PSNOCPCIAXI0",1);
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.set_routing_config("CPMPSAXI1","PSNOCPCIAXI1",1);
    
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.set_routing_config("CPMPSAXI0","PSNOCPCIAXI0",1);
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.set_routing_config("CPMPSAXI1","PSNOCPCIAXI1",1);
    
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
    force board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b0;
    force board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b0;
    // Assert VIP PL output resets based on GUI Selection
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'h0);
    // POR reset is the master reset for the PS Simulation Model. Deserting will enable the PS-VIP.
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(0);
    
    // Need hack for LPD CPM5 POR_N
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.lpd_cpm5_por_n = 1'b0;
    force board.RP.design_rp_i.versal_cips_0.inst.cpm_0.inst.lpd_cpm5_por_n = 1'b0;
 
    // Release resets after some delay
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : System Reset Is De-asserted...", $realtime);
    // Root port reset release
    sys_rst_n = 1'b1;
    // Endpoint reset release based on GIU selection.
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b1;
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b1;
    // Assert VIP PL output resets based on GUI Selection
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'hF);
    // Release reset on the PS-VIP
    board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(1);
    
    // RP reset release based on GIU selection.
    force board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST0N = 1'b1;
    force board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.PERST1N = 1'b1;
    // Assert VIP PL output resets based on GUI Selection
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.pl_gen_reset(4'hF);
    // Release reset on the PS-VIP
    board.RP.design_rp_i.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(1);
    
    // Need hack for LPD CPM5 POR_N
    force board.EP.design_1_wrapper_i.design_1_i.versal_cips_0.inst.cpm_0.inst.lpd_cpm5_por_n = 1'b1;
    force board.RP.design_rp_i.versal_cips_0.inst.cpm_0.inst.lpd_cpm5_por_n = 1'b1;
 
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
    .gt_refclk0_0_clk_n(ep_sys_clk_n),
    .gt_refclk0_0_clk_p(ep_sys_clk_p),
//    .sys_rst_n(sys_rst_n),

    // PCI-Express Serial Interface
    .PCIE0_GT_0_gtx_n(ep_pci_exp_txn),
    .PCIE0_GT_0_gtx_p(ep_pci_exp_txp),
    .PCIE0_GT_0_grx_n(rp_pci_exp_txn),
    .PCIE0_GT_0_grx_p(rp_pci_exp_txp)

  );

  //------------------------------------------------------------------------------//
  // Simulation Root Port Model
  // (Comment out this module to interface EndPoint with BFM)
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Model Root Port Instance
  //

  design_rp_wrapper # (
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
