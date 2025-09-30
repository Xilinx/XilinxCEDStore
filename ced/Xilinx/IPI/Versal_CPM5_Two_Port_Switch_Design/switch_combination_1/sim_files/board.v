
//-----------------------------------------------------------------------------
//
// (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Switch Testbench
// File       : board.v
// Version    : 1.0 
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// Project    : Versal PCIe Switch
// File       : board.v
// Version    : 31.0
//-----------------------------------------------------------------------------
//
// Description: Top level testbench for Switch
//
//------------------------------------------------------------------------------

`timescale 1ns / 1ns

`include "board_common.vh"

`define SIMULATION

module board;

  parameter REF_CLK_FREQ = 0;  // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter [4:0] LINK_WIDTH = 5'd4;

  localparam REF_CLK_HALF_CYCLE = (REF_CLK_FREQ == 0) ? 5000 :
                                  (REF_CLK_FREQ == 1) ? 4000 :
                                  (REF_CLK_FREQ == 2) ? 2000 : 0;

  localparam [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b000;

  // System-level clock and reset
  reg sys_rst_n;
  reg perstn;

  wire ep_sys_clk_p;
  wire ep_sys_clk_n;
  wire rp_sys_clk_p;
  wire rp_sys_clk_n;

  wire [13:0] common_commands_out_usp;
  wire [25:0] common_commands_out_dsp;
  wire [25:0] common_commands_out_rp;
  wire [25:0] common_commands_out_ep;
  wire [83:0] xil_tx0_sigs_ep;
  wire [83:0] xil_tx1_sigs_ep;
  wire [83:0] xil_tx2_sigs_ep;
  wire [83:0] xil_tx3_sigs_ep;
  wire [83:0] xil_tx4_sigs_ep;
  wire [83:0] xil_tx5_sigs_ep;
  wire [83:0] xil_tx6_sigs_ep;
  wire [83:0] xil_tx7_sigs_ep;
  wire [83:0] xil_tx8_sigs_ep;
  wire [83:0] xil_tx9_sigs_ep;
  wire [83:0] xil_tx10_sigs_ep;
  wire [83:0] xil_tx11_sigs_ep;
  wire [83:0] xil_tx12_sigs_ep;
  wire [83:0] xil_tx13_sigs_ep;
  wire [83:0] xil_tx14_sigs_ep;
  wire [83:0] xil_tx15_sigs_ep;

  wire [83:0] xil_rx0_sigs_ep;
  wire [83:0] xil_rx1_sigs_ep;
  wire [83:0] xil_rx2_sigs_ep;
  wire [83:0] xil_rx3_sigs_ep;
  wire [83:0] xil_rx4_sigs_ep;
  wire [83:0] xil_rx5_sigs_ep;
  wire [83:0] xil_rx6_sigs_ep;
  wire [83:0] xil_rx7_sigs_ep;
  wire [83:0] xil_rx8_sigs_ep;
  wire [83:0] xil_rx9_sigs_ep;
  wire [83:0] xil_rx10_sigs_ep;
  wire [83:0] xil_rx11_sigs_ep;
  wire [83:0] xil_rx12_sigs_ep;
  wire [83:0] xil_rx13_sigs_ep;
  wire [83:0] xil_rx14_sigs_ep;
  wire [83:0] xil_rx15_sigs_ep;

  wire [83:0] xil_tx0_sigs_rp;
  wire [83:0] xil_tx1_sigs_rp;
  wire [83:0] xil_tx2_sigs_rp;
  wire [83:0] xil_tx3_sigs_rp;
  wire [83:0] xil_tx4_sigs_rp;
  wire [83:0] xil_tx5_sigs_rp;
  wire [83:0] xil_tx6_sigs_rp;
  wire [83:0] xil_tx7_sigs_rp;
  wire [83:0] xil_tx8_sigs_rp;
  wire [83:0] xil_tx9_sigs_rp;
  wire [83:0] xil_tx10_sigs_rp;
  wire [83:0] xil_tx11_sigs_rp;
  wire [83:0] xil_tx12_sigs_rp;
  wire [83:0] xil_tx13_sigs_rp;
  wire [83:0] xil_tx14_sigs_rp;
  wire [83:0] xil_tx15_sigs_rp;

  wire [83:0] xil_rx0_sigs_rp;
  wire [83:0] xil_rx1_sigs_rp;
  wire [83:0] xil_rx2_sigs_rp;
  wire [83:0] xil_rx3_sigs_rp;
  wire [83:0] xil_rx4_sigs_rp;
  wire [83:0] xil_rx5_sigs_rp;
  wire [83:0] xil_rx6_sigs_rp;
  wire [83:0] xil_rx7_sigs_rp;
  wire [83:0] xil_rx8_sigs_rp;
  wire [83:0] xil_rx9_sigs_rp;
  wire [83:0] xil_rx10_sigs_rp;
  wire [83:0] xil_rx11_sigs_rp;
  wire [83:0] xil_rx12_sigs_rp;
  wire [83:0] xil_rx13_sigs_rp;
  wire [83:0] xil_rx14_sigs_rp;
  wire [83:0] xil_rx15_sigs_rp;

  wire [LINK_WIDTH-1:0] dsp_pcie_mgt_grx_n;
  wire [LINK_WIDTH-1:0] dsp_pcie_mgt_grx_p;
  wire [LINK_WIDTH-1:0] dsp_pcie_mgt_gtx_n;
  wire [LINK_WIDTH-1:0] dsp_pcie_mgt_gtx_p;

  wire [LINK_WIDTH-1:0] usp_PCIE0_GT_grx_n;
  wire [LINK_WIDTH-1:0] usp_PCIE0_GT_grx_p;
  wire [LINK_WIDTH-1:0] usp_PCIE0_GT_gtx_n;
  wire [LINK_WIDTH-1:0] usp_PCIE0_GT_gtx_p;

  sys_clk_gen_ds #(
      .halfcycle(REF_CLK_HALF_CYCLE),
      .offset(0)
  ) CLK_GEN_RP (
      .sys_clk_p(rp_sys_clk_p),
      .sys_clk_n(rp_sys_clk_n)
  );

  sys_clk_gen_ds #(
      .halfcycle(REF_CLK_HALF_CYCLE),
      .offset(0)
  ) CLK_GEN_EP (
      .sys_clk_p(ep_sys_clk_p),
      .sys_clk_n(ep_sys_clk_n)
  );

  defparam board.RP.design_rp_i.pcie_versal_0.inst.PL_EQ_RX_ADAPTATION_MODE = 3'h1;
  defparam board.RP.design_rp_i.pcie_versal_0.inst.PL_EQ_RX_ADV_EQ_PER_DATA_RATE_ENABLE = 5'h00;
  defparam board.RP.design_rp_i.pcie_versal_0.inst.PL_EQ_BYPASS_PHASE23 = 3'b111;
  defparam board.EP.design_ep_i.pcie_versal_0.inst.PL_EQ_RX_ADAPTATION_MODE = 3'h1;
  defparam board.EP.design_ep_i.pcie_versal_0.inst.PL_EQ_RX_ADV_EQ_PER_DATA_RATE_ENABLE = 5'h00;
  defparam board.EP.design_ep_i.pcie_versal_0.inst.PL_EQ_BYPASS_PHASE23 = 3'b111;
  defparam board.SWITCH_TOP.gen_ext_pipe_sim_dsp.switch_dsp.pcie_versal_0.inst.PL_EQ_RX_ADAPTATION_MODE = 3'h1;
  defparam board.SWITCH_TOP.gen_ext_pipe_sim_dsp.switch_dsp.pcie_versal_0.inst.PL_EQ_RX_ADV_EQ_PER_DATA_RATE_ENABLE = 5'h00;
  defparam board.SWITCH_TOP.gen_ext_pipe_sim_dsp.switch_dsp.pcie_versal_0.inst.PL_EQ_BYPASS_PHASE23 = 3'b111;

  defparam board.RP.design_rp_i.pcie_versal_0.inst.PIPE_SIM = "FALSE";
  defparam board.EP.design_ep_i.pcie_versal_0.inst.PIPE_SIM = "FALSE";
  defparam board.SWITCH_TOP.gen_ext_pipe_sim_dsp.switch_dsp.pcie_versal_0.inst.PIPE_SIM = "FALSE";

  initial begin
    force SWITCH_TOP.gen_ext_pipe_sim_usp.switch_usp.versal_cips_0.inst.cpm_0.inst.lpd_cpm5_por_n = sys_rst_n;
    force SWITCH_TOP.gen_ext_pipe_sim_usp.switch_usp.versal_cips_0.inst.cpm_0.inst.perst0n = perstn;
    force SWITCH_TOP.gen_ext_pipe_sim_usp.switch_usp.versal_cips_0.inst.cpm_0.inst.cpm_pcr_init_state = ~sys_rst_n;
  end

  //------------------------------------------------------------------------------//
  // Generate system-level reset
  //------------------------------------------------------------------------------//
  initial begin
    SWITCH_TOP.gen_ext_pipe_sim_usp.switch_usp.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.en_multi_clock_support();
    $display("[%t] : System Reset Is Asserted...", $realtime);
    sys_rst_n = 1'b0;
    perstn = 1'b0;
    SWITCH_TOP.gen_ext_pipe_sim_usp.switch_usp.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(0);
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : System Reset Is De-asserted...", $realtime);
    sys_rst_n = 1'b1;
    SWITCH_TOP.gen_ext_pipe_sim_usp.switch_usp.versal_cips_0.inst.pspmc_0.inst.PS9_VIP_inst.inst.por_reset(1);

    wait(SWITCH_TOP.gen_ext_pipe_sim_usp.switch_usp.versal_cips_0.inst.cpm_0.inst.CPM_INST.SIP_CPM5_INST.i_cpm_sim_cfg_wrap.u_cpm_sim_cfg.cdo_programming_done);
    perstn = 1'b1;
    $display("[%t] : perstn Is De-asserted...", $realtime);
  end

  //------------------------------------------------------------------------------//
  // Simulation endpoint with PIO Slave
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Endpoint Instance
  //
  xilinx_pcie_versal_ep #(
    .EXT_PIPE_SIM("FALSE")
  ) EP (
    .pci_exp_txp(dsp_pcie_mgt_grx_p),
    .pci_exp_txn(dsp_pcie_mgt_grx_n),
    .pci_exp_rxp(dsp_pcie_mgt_gtx_p),
    .pci_exp_rxn(dsp_pcie_mgt_gtx_n),
    
    // SYS Inteface
    .sys_clk_n(ep_sys_clk_n),
    .sys_clk_p(ep_sys_clk_p),

    .sys_rst_n(sys_rst_n)
  );

  //------------------------------------------------------------------------------//
  // Simulation Root Port Model
  // (Comment out this module to interface EndPoint with BFM)
  //------------------------------------------------------------------------------//
  // PCI-Express Model Root Port Instance
  //------------------------------------------------------------------------------//

  xilinx_pcie_versal_rp #(
      .PL_LINK_CAP_MAX_LINK_WIDTH(4),
      .PL_LINK_CAP_MAX_LINK_SPEED(16),
      .EXT_PIPE_SIM("FALSE")
  ) RP (
      .pci_exp_txp       (usp_PCIE0_GT_grx_p),
      .pci_exp_txn       (usp_PCIE0_GT_grx_n),
      .pci_exp_rxp       (usp_PCIE0_GT_gtx_p),
      .pci_exp_rxn       (usp_PCIE0_GT_gtx_n),
      // SYS Inteface
      .sys_clk_n         (rp_sys_clk_n),
      .sys_clk_p         (rp_sys_clk_p),
      .sys_rst_n         (sys_rst_n)
  );

  //TODO: Connect to RP and EP
  two_port_switch_top #(
      .EXT_PIPE_SIM("FALSE")
  ) SWITCH_TOP (
      // USP GTs
      .usp_PCIE0_GT_grx_n(usp_PCIE0_GT_grx_n),
      .usp_PCIE0_GT_gtx_n(usp_PCIE0_GT_gtx_n),
      .usp_PCIE0_GT_grx_p(usp_PCIE0_GT_grx_p),
      .usp_PCIE0_GT_gtx_p(usp_PCIE0_GT_gtx_p),
      // DSP GTs
      .dsp_pcie_mgt_grx_n(dsp_pcie_mgt_grx_n),
      .dsp_pcie_mgt_grx_p(dsp_pcie_mgt_grx_p),
      .dsp_pcie_mgt_gtx_n(dsp_pcie_mgt_gtx_n),
      .dsp_pcie_mgt_gtx_p(dsp_pcie_mgt_gtx_p),
      // DSP Sys Clk
      .dsp_pcie_refclk_clk_n(ep_sys_clk_n),
      .dsp_pcie_refclk_clk_p(ep_sys_clk_p),
      // USP Sys Clk
      .usp_gt_refclk0_clk_n(rp_sys_clk_n),
      .usp_gt_refclk0_clk_p(rp_sys_clk_p),
      // Sys Reset
      .sys_rst(sys_rst_n),
      .sys_rst_o()
  );

  initial begin

    if ($test$plusargs("dump_all")) begin

`ifdef NCV  // Cadence TRN dump
      $recordsetup("design=board", "compress", "wrapsize=100M", "version=1", "run=1");
      $recordvars();

`elsif VCS  //Synopsys VPD dump
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

endmodule  // BOARD
