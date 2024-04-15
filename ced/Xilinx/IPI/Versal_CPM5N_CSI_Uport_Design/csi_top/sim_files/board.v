//-----------------------------------------------------------------------------
//
// (c) Copyright 1986-2022 Xilinx, Inc. All rights reserved.
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
// Description: Top level testbench
//
//------------------------------------------------------------------------------

`timescale 1ps/1ps

`include "board_common.vh"

`define SIMULATION
`define XIL_TIMING
/*
parameter C_SEG_W = 160;
interface xil_cpm5n_intf5332 ();
logic [7  : 0] [C_SEG_W-1:0] seg;
logic [7  : 0]               sop;
logic [7  : 0]               eop;
logic [7  : 0]               vld;
logic [7  : 0]               rdy;
logic [7  : 0]               err;

modport in (
	input  seg,
	input  vld,
	input  sop,
	input  eop,
	input  err,
	output rdy
	);

modport out(
	output  seg,
	output  vld,
	output  sop,
	output  eop,
	output  err,
	input   rdy
	);


modport mon (
	input	seg,
	input	vld,
	input	sop,
	input	eop,
	input	err,
	input	rdy
    );

endinterface

interface xil_cpm5n_intf5333 ();
logic [3 : 0] [C_SEG_W-1:0] seg;
logic [3 : 0]               sop;
logic [3 : 0]               eop;
logic [3 : 0]               err;
logic [3 : 0]               vld;
logic [3 : 0]               rdy;

modport in (
	input  seg,
	input  vld,
	input  sop,
	input  eop,
	input  err,
	output rdy
	);

modport out(
	output  seg,
	output  vld,
	output  sop,
	output  eop,
	output  err,
	input   rdy
	);



modport mon (
	input  seg,
	input  vld,
	input  sop,
	input  eop,
	input  err,
	input  rdy
	);

endinterface
interface xil_cpm5n_intf5334 ();
logic [C_SEG_W-1:0] seg;
logic               sop;
logic               eop;
logic               err;
logic               vld;
logic               rdy;

modport in (
	input  seg,
	input  vld,
	input  sop,
	input  eop,
	input  err,
	output rdy
	);

modport out(
	output  seg,
	output  vld,
	output  sop,
	output  eop,
	output  err,
	input   rdy
	);


modport mon (
	input  seg,
	input  vld,
	input  sop,
	input  eop,
	input  err,
	input  rdy
	);

endinterface
*/
module board;

  parameter          REF_CLK_FREQ       = 0 ;      // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter    [4:0] LINK_WIDTH         = 5'd16;
  `ifdef LINKSPEED
  localparam   [3:0] LINK_SPEED_US      = 4'h`LINKSPEED;
  `else
  localparam   [3:0] LINK_SPEED_US      = 4'h4;
  `endif
  localparam   [1:0] LINK_SPEED         = (LINK_SPEED_US == 4'h8) ? 2'h3 :
                                          (LINK_SPEED_US == 4'h4) ? 2'h2 :
                                          (LINK_SPEED_US == 4'h2) ? 2'h1 : 2'h0;

  localparam         REF_CLK_HALF_CYCLE = (REF_CLK_FREQ == 0) ? 5000 :
                                          (REF_CLK_FREQ == 1) ? 4000 :
                                          (REF_CLK_FREQ == 2) ? 2000 : 0;

  localparam   [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b011;

  //// RP cdo file to use
  //defparam board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIM_CPM_CDO_FILE_NAME = "rp_cpm_data_sim.cdo";
  //// EP cdo file to use
  //defparam board.EP.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIM_CPM_CDO_FILE_NAME = "cpm_data_sim.cdo";
  defparam board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIM_CPM_CDO_MODE = 2;
  defparam board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIM_CPM_CDO_MODE = 2;
  
  integer            i;

  // System-level clock and reset
  reg                sys_rst_n;
  reg                perstn;

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
  
  // Generate Clocks
  initial begin
    clk1000mhz = 0;
    forever #(500)   clk1000mhz = ~clk1000mhz;
  end
  initial begin
    clk250mhz  = 0;
    forever #(2000)  clk250mhz  = ~clk250mhz;
  end
  initial begin
    clk33_3mhz = 0;
    forever #(15000) clk33_3mhz = ~clk33_3mhz;
  end
  
  //------------------------------------------------------------------------------//
  // Generate system-level reset
  //------------------------------------------------------------------------------//
  
  ////initial begin
  ////   $system("date +'Simulation Start : System Time %X--%x'");
  ////  // PSXL / CPM Init Start
  ////  // Create clock on the user design. This is a free running clock or some generated clock for user design use
  ////  // EP
  ////  force board.EP.design_1_wrapper_i.pcie0_user_clk_0 = clk250mhz;
  ////  // RP    
  ////  force board.RP.user_clk         = clk250mhz;
  ////  
  ////  // CPM5n CIPS does not have PS VIP model yet. So we're creating mandatory resets and clocks here:
  ////  // Set the frequency based on GUI selection.
  ////  // All signals that don't have wire from core_top will be forced at CPM INST directly. (will have to be brought out)
  ////  // EP
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.cpm_osc_clk_div2 = clk1000mhz;
  ////  //force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.lpd_refclk_in    = clk33_3mhz; // LPDCPMINREFCLK
  ////  //force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.lpd_swclk        = clk1000mhz; // LPDCPMTTOPSWCLK
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.psx_vip_clk = clk1000mhz; // Need to be CPM Top SW clk (used in NOC_CLK, ACELITE INTC CLK)
//////  SA: PLCPMREFCLK not used. Turn off clocks to speed up sim
//////    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.pl_ref_clk          = clk250mhz;
  ////  //force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.pl_ref_clk          = 0;
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cpm_top_user_clk    = 0; // Only using BOTCLK for CTRL0
  ////  force board.EP.design_1_wrapper_i.pl0_ref_clk_0    = clk250mhz;
  ////  
  ////  // RP
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.cpm_osc_clk_div2 = clk1000mhz;
  ////  //force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.lpd_refclk_in    = clk33_3mhz; // LPDCPMINREFCLK
  ////  //force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.lpd_swclk        = clk1000mhz; // LPDCPMTTOPSWCLK
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.psx_vip_clk = clk1000mhz; // Need to be CPM Top SW clk (used in NOC_CLK, ACELITE INTC CLK)
  ////  //  SA: PLCPMREFCLK not used. Turn off clocks to speed up sim
  ////  //    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.pl_ref_clk          = clk250mhz;
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.pl_ref_clk          = 0;
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.cpm_top_user_clk    = 0; // Only using BOTCLK for CTRL0

  ////  // Enable CPM PS ACE to PS HNOC AXI routing (all ACELite to HNOC AXI MM 0/1/2/3)
  ////  board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("CPMPSCDXACELITE","PSXNOCPCIAXI0",1);
  ////  //    board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("CPMPSCDXACELITE","PSXNOCPCIAXI1",1);
  ////  //    board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("CPMPSCDXACELITE","PSXNOCPCIAXI2",1);
  ////  //    board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("CPMPSCDXACELITE","PSXNOCPCIAXI3",1);
  ////  // Enable Slave Bridge PS HNOC to CPM PS AXI
  ////  board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("NOCPSXLPCIAXI0","PSXCPMCDXAXI",1);
  ////  
  ////end
 
  ////  
  ////initial begin
  ////  // CPM5n Global Reset
  ////  $display("[%t] : System Reset Is Asserted...", $realtime);
  ////  $system("date +'Reset Asserted : System Time %X--%x'");
  ////  sys_rst_n = 1'b0;

  ////  // EP
  ////  board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.por_reset(0);
  ////  // POR assert
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.lpd_cpm5n_por_n   = 1'b0;
  ////  // LPD RAW RSTN assert (New)
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.dbg_lpd_raw_rstn = 1'b0;
  ////  // PCR-INITSTATE assert
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.ps_pcr_init_state = 1'b1;

  ////  // RP
  ////  // POR assert
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.lpd_cpm5n_por_n   = 1'b0;
  ////  // LPD RAW RSTN assert (New)
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.dbg_lpd_raw_rstn = 1'b0;
  ////  // PCR-INITSTATE assert
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.ps_pcr_init_state = 1'b1;
  ////  
  ////  // Endpoint reset assert based on GUI selection for each controller
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst0n = 1'b0;
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst1n = 1'b0;
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst2n = 1'b0;
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst3n = 1'b0;
  ////  
  ////  force board.EP.design_1_wrapper_i.pcie0_user_reset_0 = 1'b1;
  ////  force board.EP.design_1_wrapper_i.pl0_rst_n          = 1'b0;
  ////  //force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_top_rst_n = 1'b0;
  ////  //force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_bot_rst_n = 1'b0;
  ////  
  ////  // RP
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst0n = 1'b0;
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst1n = 1'b0;
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst2n = 1'b0;
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst3n = 1'b0;
  ////  
  ////  force board.RP.user_reset = 1'b1;
  ////  
  ////  
  ////  // Release resets after some delay
  ////  repeat (500) @(posedge rp_sys_clk_p);
  ////  $display("[%t] : POR Reset Is De-asserted...", $realtime);
  ////  
  ////  // Root Port Testbench reset release
  ////  sys_rst_n = 1'b1;
  ////  
  ////  
  ////  // EP
  ////  board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.por_reset(1);
  ////  //// POR Deassert
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.lpd_cpm5n_por_n   = 1'b1;
  ////  //// LPD RAW RSTN Deassert (New)
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.dbg_lpd_raw_rstn = 1'b1;
  ////  //// PCR-INITSTATE keep asserted, not used for PCIe stream mode
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.ps_pcr_init_state = 1'b0;
  ////  
  ////  // RP
  ////  // POR Deassert
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.LPDCPM5PORN   = 1'b1;
  ////  // LPD RAW RSTN Deassert (New)
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.DBGLPDRAWRSTN = 1'b1;
  ////  // PCR-INITSTATE keep asserted, not used for PCIe stream mode
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.ps_pcr_init_state = 1'b0;
  ////  
  ////  // PSXL / CPM Init end
  ////  
  ////  // Release resets after some delay
  ////  // Wait for CDO load to complete before releasing PCIe reset
  ////  repeat (24500) @(posedge rp_sys_clk_p);
  ////  $display("[%t] : System Reset Is De-asserted...", $realtime);

  ////  // Endpoint reset release based on GUI selection.
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst0n = 1'b1;
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst1n = 1'b0;
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst2n = 1'b0;
  ////  force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst3n = 1'b0;
  ////  
  ////  force board.EP.design_1_wrapper_i.pcie0_user_reset_0 = 1'b0;
  ////  force board.EP.design_1_wrapper_i.pl0_rst_n          = 1'b1;
  ////  //force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_top_rst_n = 1'b1;
  ////  //force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_bot_rst_n = 1'b1;
  ////  
  ////  // RP
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst0n = 1'b1;
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst1n = 1'b0;
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst2n = 1'b0;
  ////  force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst3n = 1'b0;
  ////  
  ////  force board.RP.user_reset = 1'b0;
  ////  
  ////end
 
  initial begin
    //force board.EP.design_1_wrapper_i.axi_vip_en = 0;
    // EP
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst1n = 0;               // PCIe1 not enabled
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst2n = 0;               // PCIe2 not enabled
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst3n = 0;               // PCIe3 not enabled
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.pl_ref_clk = 0;       //  SA: PLCPMREFCLK not used. Turn off clocks to speed up sim
    //force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cpm_top_user_clk = 0; // Only using BOTCLK for CTRL0
    
    force board.EP.design_1_wrapper_i.pl0_rst_n = perstn;
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.perst0n = perstn;
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_bot_rst_n = perstn;
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_top_rst_n = perstn;
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.lpd_cpm5n_por_n = sys_rst_n; // POR Deassert
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.dbg_lpd_raw_rstn = sys_rst_n; // LPD RAW RSTN deassert (New.. Unsure what domain this is)
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.ps_pcr_init_state = ~sys_rst_n;  
    //force board.EP.design_1_wrapper_i.user_reset = ~sys_rst_n;
    
    //Clocks
    force board.EP.design_1_wrapper_i.pl0_ref_clk_0               = clk250mhz;
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0_pl0_ref_clk      = clk250mhz;
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.lpd_swclk = clk1000mhz;  //From PSX VIP now
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.lpd_refclk_in = clk33_3mhz;   //From PSX VIP now
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.cpm_osc_clk_div2 = clk1000mhz;
    force board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.psx_vip_clk = clk1000mhz; // Need to be CPM Top SW clk (used in NOC_CLK, ACELITE INTC CLK)
    
    // RP
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst1n = 0;                // PCIe1 not enabled
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst2n = 0;                // PCIe2 not enabled
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst3n = 0;                // PCIe3 not enabled
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.pl_ref_clk = 0;        //  SA: PLCPMREFCLK not used. Turn off clocks to speed up sim
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.cpm_top_user_clk  = 0; // Only using BOTCLK for CTRL0

    force board.RP.user_reset = ~perstn;
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.perst0n = perstn;    
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_bot_rst_n = perstn;
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.cdx_top_rst_n = perstn;
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.lpd_cpm5n_por_n = sys_rst_n;
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.dbg_lpd_raw_rstn = sys_rst_n;
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.ps_pcr_init_state = ~sys_rst_n;

    //Clocks
    force board.RP.user_clk = clk250mhz;
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.lpd_swclk = clk1000mhz;   //From PSX VIP now
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.lpd_refclk_in = clk33_3mhz;   //From PSX VIP now
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.cpm_osc_clk_div2 = clk1000mhz;
    
    force board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.psx_vip_clk = clk1000mhz; // Need to be CPM Top SW clk (used in NOC_CLK, ACELITE INTC CLK)
    
    // Enable CPM PS ACE to PS HNOC AXI routing (all ACELite to HNOC AXI MM 0/1/2/3)
    ////board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("CPMPSCDXACELITE","PSXNOCPCIAXI0",1);
    //board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("CPMPSCDXACELITE","PSXNOCPCIAXI1",1);
    //board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("CPMPSCDXACELITE","PSXNOCPCIAXI2",1);
    //board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("CPMPSCDXACELITE","PSXNOCPCIAXI3",1);
    // Enable Slave Bridge PS HNOC to CPM PS AXI
    board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.set_routing_config("NOCPSXLPCIAXI0","PSXCPMCDXAXI",1);
    
  end
  
  initial begin
    // Assert System resets
    $display("[%t] : System Reset Is Asserted...", $realtime);
    $system("date +'%X--%x :  System Reset Is Asserted...' > time.log");
    perstn = 1'b0;
    sys_rst_n = 1'b0;
    
    board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.por_reset(0);
    
    // Release POR resets after some delay
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : POR Reset Is De-asserted...", $realtime);
    $system("date +'%X--%x :  POR Reset Is De-asserted...' >> time.log");
    sys_rst_n = 1'b1;
    
    board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.psxl_0.inst.PSX_VIP_inst.inst.por_reset(1);
    
    // Wait for CDO load to complete before releasing PCIe reset
    //repeat (24500) @(posedge rp_sys_clk_p);

    wait(board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.i_cpm5n_sim_cfg_wrap.u_cpm5n_sim_cfg.cdo_programming_done == 1'b1)
    wait(board.EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.i_cpm5n_sim_cfg_wrap.u_cpm5n_sim_cfg.cdo_programming_done == 1'b1)
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
  //design_1_wrapper EP (
  design_1_wrapper_sim_wrapper EP (
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
  // Ideally use CPM5N RP model or 3rd party BFM that supports full Gen5x16.
  // Must not be paired with non-Versal Xilinx RP model which has sim speed-up parameter enabled
  xilinx_pcie5_versal_rp #(
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
//  defparam board.EP.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.PIPESIM = "TRUE";
//  defparam board.RP.design_rp_wrapper_i.design_rp_i.psx_wizard_0.inst.cpm5n_0.inst.PIPESIM = "TRUE";

  initial begin  
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_commands_in                       = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_commands_in;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_commands_out = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_commands_out;
    
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_0  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_0;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_1  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_1;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_2  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_2;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_3  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_3;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_4  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_4;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_5  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_5;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_6  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_6;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_7  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_7;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_8  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_8;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_9  = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_9;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_10 = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_10;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_11 = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_11;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_12 = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_12;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_13 = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_13;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_14 = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_14;
    force board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_rx_15 = board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_rx_15;
    
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_0  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_0;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_1  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_1;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_2  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_2;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_3  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_3;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_4  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_4;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_5  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_5;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_6  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_6;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_7  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_7;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_8  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_8;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_9  = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_9;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_10 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_10;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_11 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_11;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_12 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_12;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_13 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_13;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_14 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_14;
    force board.RP.design_rp_wrapper_i.design_rp_i.pcie0_pipe_rp_0_tx_15 = board.EP.design_1_wrapper_i.design_1_i.pcie0_pipe_ep_0_tx_15;
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
// Hier referencing
wire i_clk;
wire i_rstn;
wire sticky_rst_n;

/*
xil_cpm5n_intf5332 i_cdm_prcmpl_seg_if();  //.in                            
xil_cpm5n_intf5333 i_pcie_prcmpl_seg_if(); //.in                            
xil_cpm5n_intf5333 i_tnoc_prcmpl_seg_if(); //.in                            
xil_cpm5n_intf5333 i_psx_prcmpl_seg_if();  //.in                            
                  
xil_cpm5n_intf5334 i_cdm_npr_seg_if();     //.in                            
xil_cpm5n_intf5334 i_pcie_npr_seg_if();    //.in                            
xil_cpm5n_intf5334 i_tnoc_npr_seg_if();    //.in                            
xil_cpm5n_intf5334 i_psx_npr_seg_if();     //.in                            
                 
xil_cpm5n_intf5333 o_pcie_seg_if();        //.out                           
xil_cpm5n_intf5333 o_tnoc_seg_if();        //.out                           
xil_cpm5n_intf5333 o_psx_seg_if();         //.out                           
xil_cpm5n_intf5332 o_cdm_seg_if();         //.out                           
*/


assign i_clk                = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_clk; 
assign i_rstn               = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_rstn; 
assign sticky_rst_n         = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.sticky_rst_n;


//assign i_cdm_prcmpl_seg_if.seg  = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_cdm_prcmpl_seg_if.seg;
//assign i_pcie_prcmpl_seg_if.mon = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_pcie_prcmpl_seg_if;
//assign i_tnoc_prcmpl_seg_if.mon = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_tnoc_prcmpl_seg_if;
//assign i_psx_prcmpl_seg_if.mon  = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_psx_prcmpl_seg_if;
//assign i_cdm_npr_seg_if.mon     = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_cdm_npr_seg_if;
//assign i_pcie_npr_seg_if.mon    = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_pcie_npr_seg_if;
//assign i_tnoc_npr_seg_if.mon    = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_tnoc_npr_seg_if;
//assign i_psx_npr_seg_if.mon     = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.i_psx_npr_seg_if;
//assign o_pcie_seg_if.seg        = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.o_pcie_seg_if.seg;
//assign o_tnoc_seg_if.mon        = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.o_tnoc_seg_if;
//assign o_psx_seg_if.mon         = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.o_psx_seg_if;
//assign o_cdm_seg_if.mon         = EP.design_1_wrapper_i.design_1_i.psx_wizard_0.inst.cpm5n_0.inst.CPM_INST.SIP_CPM5N_INST.BUT.uut.Icpm5n_atom_X1Y0_R0.Icpm5n_core_top.i_cpm5n_iso_wrap.i_cpm5n_cdx_ss.i_cpm5n_cdx_b1_wrap.i_cdx5n_b1_wrap.cdx5n_csi_inst.o_cdm_seg_if;

endmodule // BOARD
