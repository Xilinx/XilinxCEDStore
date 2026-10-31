////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
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
////////////////////////////////////////////////////////////////////////

//--------------------------------------------------------------------------------
// rp_axibrdg_ddr DUT instantiation (included by tb_top).
//
// Topology:  Avery VIP (EP) --PCIe/PIPE--> CPM6 RP (BRIDGE)
//                                       -> INBOUND_REGION0 -> MMIO_APERTURE0
//                                       -> CPM_PCIE_AXI_NOC0 -> axi_noc2 -> MC_0
//                                       -> DDRMC/PHY -> ddrmc5_responder (LPDDR5 DRAM)
//
// The DUT is the *_sim_wrapper, NOT the bare top wrapper: Vivado's sim wrapper is
// the layer that instantiates the xlnoc NoC BFM and cross-connects it to the
// axi_noc2 NMU/NSU NPP taps. Instantiating the bare wrapper leaves the NoC fabric
// unconnected and nothing reaches DDR.
//
// GT serial pins dangle (PIPE mode drives the core through binds, not these pins).
// CH0_LPDDR5_0_* dangle too - the DRAM model lives *inside* the BD, in
// ddrmc5_responder_0, so nothing outside the DUT needs to drive those pins.
//--------------------------------------------------------------------------------

  // Clock signal declarations
  bit ctrl1_gt_refclk_0_clk_n;
  bit ctrl1_gt_refclk_0_clk_p;
  bit pcie1_clk_0;
  bit pcie1_rstn_0;

  bit ctrl0_gt_refclk_0_clk_n;
  bit ctrl0_gt_refclk_0_clk_p;
  bit pcie0_clk_0;
  bit pcie0_rstn_0;

  task automatic clkgen_basic(input shortreal delay, input shortreal clk_T, ref bit clk);
       #delay;
       clk = 1'b0;
       forever clk = #(clk_T/2) !clk;
   endtask

  initial begin
    fork
      clkgen_basic (0,   10.0,   ctrl1_gt_refclk_0_clk_n);
      clkgen_basic (0,   10.0,   ctrl1_gt_refclk_0_clk_p);
      clkgen_basic (0,   2.631,  pcie1_clk_0);  //380MHz
      clkgen_basic (0,   10.0,   ctrl0_gt_refclk_0_clk_n);
      clkgen_basic (0,   10.0,   ctrl0_gt_refclk_0_clk_p);
      clkgen_basic (0,   2.631,  pcie0_clk_0);  //380MHz
    join_none
  end

  // ---- DDR system clock -------------------------------------------------------
  // 3127 ps period (319.8 MHz), matching axi_noc2's DDRMC5_INPUTCLK0_PERIOD=3127.
  // Declared locally rather than taken from the framework: this tb_top has no
  // sys_clk generator at all, and where one does exist upstream it runs at ~9.86
  // MHz, which the ddr5mc BFM rejects at ~20us ("Incorrect MC_CLK_FREQUENCY").
  // _n is a true complement (not a second in-phase generator).
  bit  ddr_sysclk_p;
  wire ddr_sysclk_n = ~ddr_sysclk_p;
  initial forever ddr_sysclk_p = #1.5635ns ~ddr_sysclk_p;

  generate if(tb_top.LINK0_WIDTH != 0 && tb_top.LINK1_WIDTH != 0) begin : ctrl_inst
      rp_axi_mmbr_ddr_top_wrapper_ctrl1_ctrl0_sim_wrapper dut_inst (
        .CTRL1_GT_0_grx_n       (/* CTRL1_GT_0_grx_n */),
        .CTRL1_GT_0_grx_p       (/* CTRL1_GT_0_grx_p */),
        .CTRL1_GT_0_gtx_n       (/* CTRL1_GT_0_gtx_n */),
        .CTRL1_GT_0_gtx_p       (/* CTRL1_GT_0_gtx_p */),
        .ctrl1_gt_refclk_0_clk_n(ctrl1_gt_refclk_0_clk_n),
        .ctrl1_gt_refclk_0_clk_p(ctrl1_gt_refclk_0_clk_p),
        .CTRL0_GT_0_grx_n       (/* CTRL0_GT_0_grx_n */),
        .CTRL0_GT_0_grx_p       (/* CTRL0_GT_0_grx_p */),
        .CTRL0_GT_0_gtx_n       (/* CTRL0_GT_0_gtx_n */),
        .CTRL0_GT_0_gtx_p       (/* CTRL0_GT_0_gtx_p */),
        .ctrl0_gt_refclk_0_clk_n(ctrl0_gt_refclk_0_clk_n),
        .ctrl0_gt_refclk_0_clk_p(ctrl0_gt_refclk_0_clk_p),
        .sys_clk0_0_clk_p       (ddr_sysclk_p),
        .sys_clk0_0_clk_n       (ddr_sysclk_n)
      );
    end
    else if (tb_top.LINK1_WIDTH != 0) begin
      rp_axi_mmbr_ddr_top_wrapper_ctrl1_sim_wrapper dut_inst (
        .CTRL1_GT_0_grx_n       (/* CTRL1_GT_0_grx_n */),
        .CTRL1_GT_0_grx_p       (/* CTRL1_GT_0_grx_p */),
        .CTRL1_GT_0_gtx_n       (/* CTRL1_GT_0_gtx_n */),
        .CTRL1_GT_0_gtx_p       (/* CTRL1_GT_0_gtx_p */),
        .ctrl1_gt_refclk_0_clk_n(ctrl1_gt_refclk_0_clk_n),
        .ctrl1_gt_refclk_0_clk_p(ctrl1_gt_refclk_0_clk_p),
        .sys_clk0_0_clk_p       (ddr_sysclk_p),
        .sys_clk0_0_clk_n       (ddr_sysclk_n)
      );
    end
    else if (tb_top.LINK0_WIDTH != 0) begin
      rp_axi_mmbr_ddr_top_wrapper_ctrl0_sim_wrapper dut_inst (
        .CTRL0_GT_0_grx_n       (/* CTRL0_GT_0_grx_n */),
        .CTRL0_GT_0_grx_p       (/* CTRL0_GT_0_grx_p */),
        .CTRL0_GT_0_gtx_n       (/* CTRL0_GT_0_gtx_n */),
        .CTRL0_GT_0_gtx_p       (/* CTRL0_GT_0_gtx_p */),
        .ctrl0_gt_refclk_0_clk_n(ctrl0_gt_refclk_0_clk_n),
        .ctrl0_gt_refclk_0_clk_p(ctrl0_gt_refclk_0_clk_p),
        .sys_clk0_0_clk_p       (ddr_sysclk_p),
        .sys_clk0_0_clk_n       (ddr_sysclk_n)
      );
    end
    else begin
      `uvm_fatal("DUT_INSTANTIATION", "No link width specified for either controller, cannot instantiate DUT")
    end
  endgenerate
