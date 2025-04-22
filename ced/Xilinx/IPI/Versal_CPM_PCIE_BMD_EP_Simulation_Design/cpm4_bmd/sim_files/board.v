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

  `ifdef SINGLE_CTRL
  localparam PCIE_CTRL_MODE                     = 0;      // 0 - PCIE0(x16), 1 - PCIE0+1(x8x8) -- Add more when other configuration is supported
  `elsif DUAL_CTRL
  localparam PCIE_CTRL_MODE                     = 1;      // 0 - PCIE0(x16), 1 - PCIE0+1(x8x8) -- Add more when other configuration is supported
  `endif
  localparam REF_CLK_FREQ                       = 0;      // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
  localparam [4:0] PL_LINK_CAP_MAX_LINK_SPEED   = 5'd8;   // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4. 16 - GEN5
  localparam [4:0] PL_LINK_CAP_MAX_LINK_WIDTH   = 5'd8;  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16
  localparam [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b011;

  localparam REF_CLK_HALF_CYCLE = (REF_CLK_FREQ == 0) ? 5000 :
                                  (REF_CLK_FREQ == 1) ? 4000 :
                                  (REF_CLK_FREQ == 2) ? 2000 : 0;

 localparam C_CPM_PIPESIM = `EP_CPM_PATH.inst.C_CPM_PIPESIM;
 
  // System-level clock and reset
  reg sys_rst_n;

  wire ep_sys_clk_p;
  wire ep_sys_clk_n;
  wire rp_sys_clk_p;
  wire rp_sys_clk_n;

  //
  // PCI-Express Serial Interconnect
  //
  wire  [(PL_LINK_CAP_MAX_LINK_WIDTH-1):0]  ep_pci_exp_txn;
  wire  [(PL_LINK_CAP_MAX_LINK_WIDTH-1):0]  ep_pci_exp_txp;
  wire  [(PL_LINK_CAP_MAX_LINK_WIDTH-1):0]  rp_pci_exp_txn;
  wire  [(PL_LINK_CAP_MAX_LINK_WIDTH-1):0]  rp_pci_exp_txp;
 

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
  reg clk1000mhz;
  reg clk250mhz;
  reg clk33_3mhz;
  reg perstn;
  
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

generate
if (PCIE_CTRL_MODE == 0) begin : Single_CTRL_CRX // CTRL 0 x16
  initial begin
    // PS-VIP clock
    force `EP_PS_PATH.inst.versal_cips_ps_vip_clk = clk33_3mhz;
    force `RP_PS_PATH.inst.versal_cips_ps_vip_clk = clk33_3mhz;
  // Enable Multi Clock Support API
    `EP_PS_PATH.inst.en_multi_clock_support();
    `RP_PS_PATH.inst.en_multi_clock_support();
  // cpm_osc_clk_div2_gen_clock = 200MHz
  // cpm_gen_clock = 33.33MHz
  // ps_gen_clk = 1GHz
    `EP_PS_PATH.inst.ps_gen_clock(5'd0,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd1,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd2,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd3,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd4,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd5,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd6,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd7,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd8,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd9,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd10,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd11,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd12,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd13,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd14,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd15,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd16,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd0,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd1,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd2,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd3,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd4,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd5,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd6,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd7,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd8,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd9,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd10,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd11,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd12,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd13,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd14,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd15,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd16,1000);
    
    
    // Reference Clocks for the CPM
    `EP_PS_PATH.inst.cpm_gen_clock(33.33);
    `EP_PS_PATH.inst.cpm_osc_clk_div2_gen_clock(200);

    `RP_PS_PATH.inst.cpm_gen_clock(33.33);
    `RP_PS_PATH.inst.cpm_osc_clk_div2_gen_clock(200);
    
    // EP reset
    force `EP_PS_PATH.inst.PERST0N = perstn;
    force `EP_PS_PATH.inst.PERST1N = 0;                // PCIe1 not enabled
    
    // RP reset
    force `RP_PS_PATH.inst.PERST0N = perstn;
    force `RP_PS_PATH.inst.PERST1N = 0;   // PCIe1 not enabled
  end
  
  initial begin
    // Assert System resets
    $display("[%t] : System Reset Is Asserted...", $realtime);
    $system("date +'%X--%x :  System Reset Is Asserted...' > time.log");
    perstn = 1'b0;
    sys_rst_n = 1'b0;
    
    `EP_PS_PATH.inst.por_reset(0);
    `RP_PS_PATH.inst.por_reset(0);
    `EP_PS_PATH.inst.pl_gen_reset(4'h0); // PL RSTN
    `RP_PS_PATH.inst.pl_gen_reset(4'h0); // PL RSTN
 
    // Release POR resets after some delay
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : POR Reset Is De-asserted...", $realtime);
    $system("date +'%X--%x :  POR Reset Is De-asserted...' >> time.log");
    sys_rst_n = 1'b1;
    
    `EP_PS_PATH.inst.por_reset(1);
    `RP_PS_PATH.inst.por_reset(1);
    `EP_PS_PATH.inst.pl_gen_reset(4'h1); // PL RSTN
    `RP_PS_PATH.inst.pl_gen_reset(4'h1); // PL RSTN
    
    // Wait for CDO load to complete before releasing PCIe reset
    repeat (10000) @(posedge rp_sys_clk_p);
    $display("[%t] : PCIe Reset Is De-asserted...", $realtime);
    $system("date +'%X--%x :  PCIe Reset Is De-asserted...' >> time.log");
    perstn = 1'b1;
  end
end
else if (PCIE_CTRL_MODE == 1) begin : Dual_Ctrl_CRX // CTRL 0+1 x8x8
  initial begin
    // PS-VIP clock
    force `EP_PS_PATH.inst.versal_cips_ps_vip_clk = clk33_3mhz;
    force `RP_PS_PATH.inst.versal_cips_ps_vip_clk = clk33_3mhz;
  // Enable Multi Clock Support API
    `EP_PS_PATH.inst.en_multi_clock_support();
    `RP_PS_PATH.inst.en_multi_clock_support();
  // cpm_osc_clk_div2_gen_clock = 200MHz
  // cpm_gen_clock = 33.33MHz
  // ps_gen_clk = 1GHz
    `EP_PS_PATH.inst.ps_gen_clock(5'd0,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd1,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd2,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd3,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd4,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd5,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd6,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd7,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd8,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd9,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd10,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd11,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd12,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd13,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd14,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd15,1000);
    `EP_PS_PATH.inst.ps_gen_clock(5'd16,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd0,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd1,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd2,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd3,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd4,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd5,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd6,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd7,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd8,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd9,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd10,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd11,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd12,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd13,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd14,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd15,1000);
    `RP_PS_PATH.inst.ps_gen_clock(5'd16,1000);
    
    
    // Reference Clocks for the CPM
    `EP_PS_PATH.inst.cpm_gen_clock(33.33);
    `EP_PS_PATH.inst.cpm_osc_clk_div2_gen_clock(200);

    `RP_PS_PATH.inst.cpm_gen_clock(33.33);
    `RP_PS_PATH.inst.cpm_osc_clk_div2_gen_clock(200);
    
    // EP reset
    force `EP_PS_PATH.inst.PERST0N = perstn;
    force `EP_PS_PATH.inst.PERST1N = perstn;
    
    // RP reset
    force `RP_PS_PATH.inst.PERST0N = perstn;
    force `RP_PS_PATH.inst.PERST1N = perstn;
  end
  
  initial begin
    // Assert System resets
    $display("[%t] : System Reset Is Asserted...", $realtime);
    $system("date +'%X--%x :  System Reset Is Asserted...' > time.log");
    perstn = 1'b0;
    sys_rst_n = 1'b0;
    
    `EP_PS_PATH.inst.por_reset(0);
    `RP_PS_PATH.inst.por_reset(0);
    `EP_PS_PATH.inst.pl_gen_reset(4'h0); // PL RSTN
    `RP_PS_PATH.inst.pl_gen_reset(4'h0); // PL RSTN
 
    // Release POR resets after some delay
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : POR Reset Is De-asserted...", $realtime);
    $system("date +'%X--%x :  POR Reset Is De-asserted...' >> time.log");
    sys_rst_n = 1'b1;
    
    `EP_PS_PATH.inst.por_reset(1);
    `RP_PS_PATH.inst.por_reset(1);
    `EP_PS_PATH.inst.pl_gen_reset(4'h1); // PL RSTN
    `RP_PS_PATH.inst.pl_gen_reset(4'h1); // PL RSTN
    
    // Wait for CDO load to complete before releasing PCIe reset
    repeat (10000) @(posedge rp_sys_clk_p);
    $display("[%t] : PCIe Reset Is De-asserted...", $realtime);
    $system("date +'%X--%x :  PCIe Reset Is De-asserted...' >> time.log");
    perstn = 1'b1;
  end
end
endgenerate

  //------------------------------------------------------------------------------//
  // Simulation endpoint with PIO Slave
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Endpoint Instance
  //

  design_1_wrapper EP (
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
    .PCIE_CTRL_MODE               ( PCIE_CTRL_MODE               ),
    .PL_LINK_CAP_MAX_LINK_WIDTH   ( PL_LINK_CAP_MAX_LINK_WIDTH   ),
    .PL_LINK_CAP_MAX_LINK_SPEED   ( PL_LINK_CAP_MAX_LINK_SPEED   ),
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
  
generate
if ((PCIE_CTRL_MODE == 0) &&
   (C_CPM_PIPESIM == "TRUE")) begin : Single_CTRL_PIPE // CTRL 0 x16
  initial begin
     force `EP_IP_PATH.pcie0_pipe_ep_commands_in = `RP_IP_PATH.pcie0_pipe_rp_commands_in;
     force `RP_IP_PATH.pcie0_pipe_rp_commands_out = `EP_IP_PATH.pcie0_pipe_ep_commands_out;
     
     force `EP_IP_PATH.pcie0_pipe_ep_rx_0  = `RP_IP_PATH.pcie0_pipe_rp_rx_0;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_1  = `RP_IP_PATH.pcie0_pipe_rp_rx_1;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_2  = `RP_IP_PATH.pcie0_pipe_rp_rx_2;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_3  = `RP_IP_PATH.pcie0_pipe_rp_rx_3;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_4  = `RP_IP_PATH.pcie0_pipe_rp_rx_4;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_5  = `RP_IP_PATH.pcie0_pipe_rp_rx_5;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_6  = `RP_IP_PATH.pcie0_pipe_rp_rx_6;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_7  = `RP_IP_PATH.pcie0_pipe_rp_rx_7;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_8  = `RP_IP_PATH.pcie0_pipe_rp_rx_8;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_9  = `RP_IP_PATH.pcie0_pipe_rp_rx_9;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_10 = `RP_IP_PATH.pcie0_pipe_rp_rx_10;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_11 = `RP_IP_PATH.pcie0_pipe_rp_rx_11;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_12 = `RP_IP_PATH.pcie0_pipe_rp_rx_12;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_13 = `RP_IP_PATH.pcie0_pipe_rp_rx_13;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_14 = `RP_IP_PATH.pcie0_pipe_rp_rx_14;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_15 = `RP_IP_PATH.pcie0_pipe_rp_rx_15;
     
     force `RP_IP_PATH.pcie0_pipe_rp_tx_0  = `EP_IP_PATH.pcie0_pipe_ep_tx_0;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_1  = `EP_IP_PATH.pcie0_pipe_ep_tx_1;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_2  = `EP_IP_PATH.pcie0_pipe_ep_tx_2;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_3  = `EP_IP_PATH.pcie0_pipe_ep_tx_3;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_4  = `EP_IP_PATH.pcie0_pipe_ep_tx_4;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_5  = `EP_IP_PATH.pcie0_pipe_ep_tx_5;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_6  = `EP_IP_PATH.pcie0_pipe_ep_tx_6;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_7  = `EP_IP_PATH.pcie0_pipe_ep_tx_7;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_8  = `EP_IP_PATH.pcie0_pipe_ep_tx_8;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_9  = `EP_IP_PATH.pcie0_pipe_ep_tx_9;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_10 = `EP_IP_PATH.pcie0_pipe_ep_tx_10;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_11 = `EP_IP_PATH.pcie0_pipe_ep_tx_11;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_12 = `EP_IP_PATH.pcie0_pipe_ep_tx_12;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_13 = `EP_IP_PATH.pcie0_pipe_ep_tx_13;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_14 = `EP_IP_PATH.pcie0_pipe_ep_tx_14;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_15 = `EP_IP_PATH.pcie0_pipe_ep_tx_15;
  end
end
else if ((PCIE_CTRL_MODE == 1) &&
         (C_CPM_PIPESIM == "TRUE")) begin : Dual_Ctrl_PIPE // CTRL 0+2 x8x8
  initial begin
     force `EP_IP_PATH.pcie0_pipe_ep_commands_in = `RP_IP_PATH.pcie0_pipe_rp_commands_in;
     force `RP_IP_PATH.pcie0_pipe_rp_commands_out = `EP_IP_PATH.pcie0_pipe_ep_commands_out;
        
     force `EP_IP_PATH.pcie0_pipe_ep_rx_0  = `RP_IP_PATH.pcie0_pipe_rp_rx_0;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_1  = `RP_IP_PATH.pcie0_pipe_rp_rx_1;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_2  = `RP_IP_PATH.pcie0_pipe_rp_rx_2;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_3  = `RP_IP_PATH.pcie0_pipe_rp_rx_3;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_4  = `RP_IP_PATH.pcie0_pipe_rp_rx_4;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_5  = `RP_IP_PATH.pcie0_pipe_rp_rx_5;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_6  = `RP_IP_PATH.pcie0_pipe_rp_rx_6;
     force `EP_IP_PATH.pcie0_pipe_ep_rx_7  = `RP_IP_PATH.pcie0_pipe_rp_rx_7;
     
     force `RP_IP_PATH.pcie0_pipe_rp_tx_0  = `EP_IP_PATH.pcie0_pipe_ep_tx_0;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_1  = `EP_IP_PATH.pcie0_pipe_ep_tx_1;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_2  = `EP_IP_PATH.pcie0_pipe_ep_tx_2;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_3  = `EP_IP_PATH.pcie0_pipe_ep_tx_3;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_4  = `EP_IP_PATH.pcie0_pipe_ep_tx_4;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_5  = `EP_IP_PATH.pcie0_pipe_ep_tx_5;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_6  = `EP_IP_PATH.pcie0_pipe_ep_tx_6;
     force `RP_IP_PATH.pcie0_pipe_rp_tx_7  = `EP_IP_PATH.pcie0_pipe_ep_tx_7;
     
     force `EP_IP_PATH.pcie1_pipe_ep_commands_in = `RP_IP_PATH.pcie1_pipe_rp_commands_in;
     force `RP_IP_PATH.pcie1_pipe_rp_commands_out = `EP_IP_PATH.pcie1_pipe_ep_commands_out;
     
     force `EP_IP_PATH.pcie1_pipe_ep_rx_0  = `RP_IP_PATH.pcie1_pipe_rp_rx_0;
     force `EP_IP_PATH.pcie1_pipe_ep_rx_1  = `RP_IP_PATH.pcie1_pipe_rp_rx_1;
     force `EP_IP_PATH.pcie1_pipe_ep_rx_2  = `RP_IP_PATH.pcie1_pipe_rp_rx_2;
     force `EP_IP_PATH.pcie1_pipe_ep_rx_3  = `RP_IP_PATH.pcie1_pipe_rp_rx_3;
     force `EP_IP_PATH.pcie1_pipe_ep_rx_4  = `RP_IP_PATH.pcie1_pipe_rp_rx_4;
     force `EP_IP_PATH.pcie1_pipe_ep_rx_5  = `RP_IP_PATH.pcie1_pipe_rp_rx_5;
     force `EP_IP_PATH.pcie1_pipe_ep_rx_6  = `RP_IP_PATH.pcie1_pipe_rp_rx_6;
     force `EP_IP_PATH.pcie1_pipe_ep_rx_7  = `RP_IP_PATH.pcie1_pipe_rp_rx_7;
     
     force `RP_IP_PATH.pcie1_pipe_rp_tx_0  = `EP_IP_PATH.pcie1_pipe_ep_tx_0;
     force `RP_IP_PATH.pcie1_pipe_rp_tx_1  = `EP_IP_PATH.pcie1_pipe_ep_tx_1;
     force `RP_IP_PATH.pcie1_pipe_rp_tx_2  = `EP_IP_PATH.pcie1_pipe_ep_tx_2;
     force `RP_IP_PATH.pcie1_pipe_rp_tx_3  = `EP_IP_PATH.pcie1_pipe_ep_tx_3;
     force `RP_IP_PATH.pcie1_pipe_rp_tx_4  = `EP_IP_PATH.pcie1_pipe_ep_tx_4;
     force `RP_IP_PATH.pcie1_pipe_rp_tx_5  = `EP_IP_PATH.pcie1_pipe_ep_tx_5;
     force `RP_IP_PATH.pcie1_pipe_rp_tx_6  = `EP_IP_PATH.pcie1_pipe_ep_tx_6;
     force `RP_IP_PATH.pcie1_pipe_rp_tx_7  = `EP_IP_PATH.pcie1_pipe_ep_tx_7;
  end
end
endgenerate
   
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
