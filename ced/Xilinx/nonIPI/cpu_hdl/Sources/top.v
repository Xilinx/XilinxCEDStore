/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2008 Xilinx, Inc.  All rights reserved.
//
//                 XILINX CONFIDENTIAL PROPERTY
// This   document  contains  proprietary information  which   is
// protected by  copyright. All rights  are reserved.  This notice
// refers to original work by Xilinx, Inc. which may be derivitive
// of other work distributed under license of the authors.  In the
// case of derivitive work, nothing in this notice overrides the
// original author's license agreeement.  Where applicable, the 
// original license agreement is included in it's original 
// unmodified form immediately below this header.
//
// Xilinx, Inc.
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
// COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
// ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
// STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
// IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
// FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
// XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
// THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
// ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
// FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE.
//
/////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:38:31 06/05/2007 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top(
   sysClk,
   reset, 
   TILE0_REFCLK_PAD_N_IN, TILE0_REFCLK_PAD_P_IN, TILE1_REFCLK_PAD_N_IN, TILE1_REFCLK_PAD_P_IN,
   TILE2_REFCLK_PAD_N_IN, TILE2_REFCLK_PAD_P_IN, TILE3_REFCLK_PAD_N_IN, TILE3_REFCLK_PAD_P_IN,
   GTPRESET_IN, 
   RXN_IN, RXP_IN, TXN_OUT, TXP_OUT,
   phy_rst_pad_0_o,
   DataOut_pad_0_o, TxValid_pad_0_o, TxReady_pad_0_i,
   RxValid_pad_0_i, RxActive_pad_0_i, RxError_pad_0_i,
   DataIn_pad_0_i, XcvSelect_pad_0_o, TermSel_pad_0_o,
   SuspendM_pad_0_o, LineState_pad_0_i,
   OpMode_pad_0_o, usb_vbus_pad_0_i,
   VControl_Load_pad_0_o, VControl_pad_0_o, VStatus_pad_0_i,
   phy_rst_pad_1_o,
   DataOut_pad_1_o, TxValid_pad_1_o, TxReady_pad_1_i,
   RxValid_pad_1_i, RxActive_pad_1_i, RxError_pad_1_i,
   DataIn_pad_1_i, XcvSelect_pad_1_o, TermSel_pad_1_o,
   SuspendM_pad_1_o, LineState_pad_1_i,
   OpMode_pad_1_o, usb_vbus_pad_1_i,
   VControl_Load_pad_1_o, VControl_pad_1_o, VStatus_pad_1_i,
   or1200_clmode, or1200_pic_ints, or1200_pm_out  
);

   // clock and reset pads
   input sysClk;
   input reset;

   // GTP pads
   input TILE0_REFCLK_PAD_N_IN;
   input TILE0_REFCLK_PAD_P_IN;
   input TILE1_REFCLK_PAD_N_IN;
   input TILE1_REFCLK_PAD_P_IN;
   input TILE2_REFCLK_PAD_N_IN;
   input TILE2_REFCLK_PAD_P_IN;
   input TILE3_REFCLK_PAD_N_IN;
   input TILE3_REFCLK_PAD_P_IN;
   input GTPRESET_IN;
   input [7:0] RXN_IN;
   input [7:0] RXP_IN;
   output [7:0] TXN_OUT;
   output [7:0] TXP_OUT;

   // USB 0 UTMI pads
   output phy_rst_pad_0_o;
   output [7:0]	DataOut_pad_0_o;
   output TxValid_pad_0_o;
   input TxReady_pad_0_i;
   input [7:0]	DataIn_pad_0_i;
   input RxValid_pad_0_i;
   input RxActive_pad_0_i;
   input RxError_pad_0_i;
   output XcvSelect_pad_0_o;
   output TermSel_pad_0_o;
   output SuspendM_pad_0_o;
   input [1:0]	LineState_pad_0_i;
   output [1:0]	OpMode_pad_0_o;
   input usb_vbus_pad_0_i;
   output VControl_Load_pad_0_o;
   output [3:0]	VControl_pad_0_o;
   input [7:0]	VStatus_pad_0_i;      

   // USB 1 UTMI pads
   output phy_rst_pad_1_o;
   output [7:0]	DataOut_pad_1_o;
   output TxValid_pad_1_o;
   input TxReady_pad_1_i;
   input [7:0]	DataIn_pad_1_i;
   input RxValid_pad_1_i;
   input RxActive_pad_1_i;
   input RxError_pad_1_i;
   output XcvSelect_pad_1_o;
   output TermSel_pad_1_o;
   output SuspendM_pad_1_o;
   input [1:0]	LineState_pad_1_i;
   output [1:0]	OpMode_pad_1_o;
   input usb_vbus_pad_1_i;
   output VControl_Load_pad_1_o;
   output [3:0]	VControl_pad_1_o;
   input [7:0]	VStatus_pad_1_i;	 
	   
   
   //or1200 pads
   input or1200_clmode, or1200_pic_ints;
  
   output [3:0] or1200_pm_out;
  
   // wishbone master 0 signals
   wire m0_stb_i;
   wire [31:0] m0_data_o;
   wire  [31:0] m0_data_i;
   wire m0_ack_o;
   wire m0_err_o;
   wire m0_rty_o;
   wire [31:0] m0_addr_i;
   wire m0_we_i;
   wire m0_cyc_i;
   wire [3:0] m0_sel_i;

   // wishbone master 1 signals
   wire m1_stb_i;
   wire [31:0] m1_data_o;
   wire  [31:0] m1_data_i;
   wire m1_ack_o;
   wire m1_err_o;
   wire m1_rty_o;
   wire [31:0] m1_addr_i;
   wire m1_we_i;
   wire m1_cyc_i;
   wire [3:0] m1_sel_i;

   // wishbone slave 0 signals
   wire s0_stb_o;
   wire [31:0] s0_data_o;
   wire  [31:0] s0_data_i;
   wire s0_ack_i;
   wire s0_err_i;
   wire s0_rty_i;
   wire [31:0] s0_addr_o;
   wire s0_we_o;
   wire s0_cyc_o;
   wire [15:0] s0_sel_o;

   // wishbone slave 1 signals
   wire s1_stb_o;
   wire [31:0] s1_data_o;
   wire  [31:0] s1_data_i;
   wire s1_ack_i;
   wire s1_err_i;
   wire s1_rty_i;
   wire [31:0] s1_addr_o;
   wire s1_we_o;
   wire s1_cyc_o;
   wire [15:0] s1_sel_o;

   // wishbone slave 2 signals
   wire s2_stb_o;
   wire [31:0] s2_data_o;
   wire  [31:0] s2_data_i;
   wire s2_ack_i;
   wire s2_err_i;
   wire s2_rty_i;
   wire [31:0] s2_addr_o;
   wire s2_we_o;
   wire s2_cyc_o;
   wire [3:0] s2_sel_o;

   // wishbone slave 3 signals
   wire s3_stb_o;
   wire [31:0] s3_data_o;
   wire  [31:0] s3_data_i;
   wire s3_ack_i;
   wire s3_err_i;
   wire s3_rty_i;
   wire [31:0] s3_addr_o;
   wire s3_we_o;
   wire s3_cyc_o;
   wire [3:0] s3_sel_o;
   wire wbClk;   
						   
   //wisbone slave 4 signals
   wire [31:0] s4_data_o;
   wire  [31:0] s4_data_i;
   wire [31:0] s4_addr_o;   
   wire [3:0] s4_sel_o;
   
   //usb wb signals
   wire [31:0] wb_data_0;
   wire [31:0] wb_data_1;
   
     //register golbal inputs
     reg reset_reg;
   
      always @(posedge wbClk)
        reset_reg <= reset;

    // register usb_1 inputs
     reg usb_vbus_pad_1_i_reg;
     reg [3:0] VControl_pad_1_o;
     wire [3:0] VControl_pad_1_o_temp;
     
     reg [1:0]	OpMode_pad_1_o;
     wire [1:0]	OpMode_pad_1_o_temp;
												  
	 reg phy_rst_pad_1_o;
	 wire phy_rst_pad_1_o_temp;
												  
	 reg SuspendM_pad_1_o;
	 wire SuspendM_pad_1_o_temp; 

	 // Input buffering
	 //------------------------------------
	 IBUFG clkin1_buf
	  (.O (sysClk_int),
	   .I (sysClk));

     // Take system clock and create internal clocks
	 clock_generator clkgen
	  (// Clock in ports
	   .sysClk              (sysClk_int), // IN
	   // Clock out ports
	   .cpuClk_o            (cpuClk),     // OUT 50MHz
	   .wbClk_o             (wbClk),      // OUT 50MHz
	   .usbClk_o            (usbClk),     // OUT 100MHz
	   .phyClk0_o           (phyClk0),    // OUT 100MHz
	   .phyClk1_o           (phyClk1),    // OUT 100MHz
	   .fftClk_o            (fftClk),     // OUT 100MHz
	   // Status and control signals
	   .RESET               (reset));     // IN
	 
    always @(posedge usbClk) 
     begin
      	 usb_vbus_pad_1_i_reg <= usb_vbus_pad_1_i;
      	 VControl_pad_1_o <= VControl_pad_1_o_temp;
      	 OpMode_pad_1_o <= OpMode_pad_1_o_temp;
      	 SuspendM_pad_1_o <= SuspendM_pad_1_o_temp;
      	 phy_rst_pad_1_o <= phy_rst_pad_1_o_temp;
    end  
    
    
    
    // register usb_0 inputs
     reg usb_vbus_pad_0_i_reg;
     
     reg [3:0] VControl_pad_0_o;
     wire [3:0] VControl_pad_0_o_temp;
     											  
     reg [1:0]	OpMode_pad_0_o;
     wire [1:0]	OpMode_pad_0_o_temp;
 			  
 	 reg phy_rst_pad_0_o;
 	 wire phy_rst_pad_0_o_temp;
 			  
 	 reg SuspendM_pad_0_o;
     wire SuspendM_pad_0_o_temp;
 
     always @(posedge usbClk)
     begin
      	 usb_vbus_pad_0_i_reg <= usb_vbus_pad_0_i;
    	 VControl_pad_0_o <= VControl_pad_0_o_temp;
    	 OpMode_pad_0_o <= OpMode_pad_0_o_temp;
    	 SuspendM_pad_0_o <= SuspendM_pad_0_o_temp;
    	 phy_rst_pad_0_o <= phy_rst_pad_0_o_temp;
     end

// MGT Engine - wishbone slave 2
   mgtTop mgtEngine (
      .Q0_CLK0_GTREFCLK_PAD_N_IN(TILE0_REFCLK_PAD_N_IN),
      .Q0_CLK0_GTREFCLK_PAD_P_IN(TILE0_REFCLK_PAD_P_IN),
      .Q0_CLK1_GTREFCLK_PAD_N_IN(TILE1_REFCLK_PAD_N_IN),
      .Q0_CLK1_GTREFCLK_PAD_P_IN(TILE1_REFCLK_PAD_P_IN),
      .Q1_CLK0_GTREFCLK_PAD_N_IN(TILE2_REFCLK_PAD_N_IN),
      .Q1_CLK0_GTREFCLK_PAD_P_IN(TILE2_REFCLK_PAD_P_IN),
      .Q1_CLK1_GTREFCLK_PAD_N_IN(TILE3_REFCLK_PAD_N_IN),
      .Q1_CLK1_GTREFCLK_PAD_P_IN(TILE3_REFCLK_PAD_P_IN),
      .SYSCLK_IN(sysClk_int),
      .GTTXRESET_IN(GTPRESET_IN),
      .GTRXRESET_IN(GTPRESET_IN),      
      .TRACK_DATA_OUT(TRACK_DATA_OUT),
      .RXN_IN(RXN_IN), 
      .RXP_IN(RXP_IN), 
      .TXN_OUT(TXN_OUT), 
      .TXP_OUT(TXP_OUT),
      .wb_clk(wbClk), .wb_reset(reset_reg), .wb_stb_i(s2_stb_o), .wb_dat_o(s2_data_i), .wb_dat_i(s2_data_o), .wb_ack_o(s2_ack_i),
      .wb_adr_i(s2_addr_o),.wb_we_i(s2_we_o), .wb_cyc_i(s2_cyc_o), .wb_sel_i(s2_sel_o), .wb_err_o(s2_err_i), .wb_rty_o(s2_rty_i)
   );

   // FFT engine -wishbone slave 3
   fftTop fftEngine (
       .wb_clk(wbClk), .clk(fftClk), .reset(reset_reg), 
      .wb_stb_i(s3_stb_o), .wb_dat_o(s3_data_i), .wb_dat_i(s3_data_o), .wb_ack_o(s3_ack_i),
      .wb_adr_i(s3_addr_o), .wb_we_i(s3_we_o), .wb_cyc_i(s3_cyc_o), .wb_sel_i(s3_sel_o), .wb_err_o(s3_err_i), .wb_rty_o(s3_rty_i)
   );

   // open risc processor - wishbone master 0
   or1200_top cpuEngine (
      .wb_clk(wbClk), .clk_i(cpuClk), .rst_i(reset_reg), .pic_ints_i(or1200_pic_ints), .clmode_i(or1200_clmode), 
      .iwb_clk_i(wbClk), .iwb_rst_i(reset), .iwb_ack_i(m0_ack_o), .iwb_err_i(m0_err_o), .iwb_rty_i(m0_rty_o), 
      .iwb_dat_i(m0_data_o), .iwb_cyc_o(m0_cyc_i), .iwb_adr_o(m0_addr_i), .iwb_stb_o(m0_stb_i), .iwb_we_o(m0_we_i), 
      .iwb_sel_o(m0_sel_i), .iwb_dat_o(m0_data_i), // .iwb_cab_o(), 
      .dwb_clk_i(wbClk), .dwb_rst_i(reset_reg), .dwb_ack_i(m1_ack_o), .dwb_err_i(m1_err_o), .dwb_rty_i(m1_rty_o), 
      .dwb_dat_i(m1_data_o), .dwb_cyc_o(m1_cyc_i), .dwb_adr_o(m1_addr_i), .dwb_stb_o(m1_stb_i), .dwb_we_o(m1_we_i), 
      .dwb_sel_o(m1_sel_i), .dwb_dat_o(m1_data_i), // .dwb_cab_o(), 
      .dbg_stall_i(m0_rty_o), .dbg_ewt_i(m0_rty_o),  .dbg_is_o(s4_err_i),  .dbg_bp_o(s4_rty_i), .dbg_stb_i(s3_ack_i), 
      .dbg_we_i(m0_rty_o), .dbg_adr_i(s4_addr_o), .dbg_dat_i(s4_data_o), .dbg_dat_o(s4_data_i), .dbg_ack_o(s4_ack_i), 
      .pm_cpustall_i(m0_stb_i), .pm_clksd_o(or1200_pm_out)//, .pm_dc_gate_o(), .pm_ic_gate_o(), .pm_dmmu_gate_o(), .pm_immu_gate_o(), 
      //.pm_tt_gate_o()
 
      //, .pm_cpu_gate_o(), .pm_wakeup_o(), .pm_lvolt_o()
   );
 
wire rectify_reset;
assign rectify_reset = reset_reg;
   // Wishbone Arbiter
   //wb_conmax_top
   wb_conmax_top #( 32, // Data Bus width
                    32, // Address Bus width
                    4'hf, // Register File Address
                    2'h1, // Number of priorities for Slave 0
                    2'h1 // Number of priorities for Slave 1
                    // Priorities for Slave 2 through 15 will default to 2\u2019h2
   ) wbArbEngine ( 
//code modification for a third part synthesis tool   
//      .clk_i(wbClk), .rst_i(reset_reg), 
      .clk_i(wbClk), .rst_i(rectify_reset), 
      // master 0 - or1200 instruction bus
      .m0_data_i(m0_data_i), .m0_data_o(m0_data_o), .m0_addr_i(m0_addr_i), .m0_sel_i(m0_sel_i), .m0_we_i(m0_we_i), .m0_cyc_i(m0_cyc_i),
      .m0_stb_i(m0_stb_i), .m0_ack_o(m0_ack_o), .m0_err_o(m0_err_o), .m0_rty_o(m0_rty_o),
      // master 1 - or1200 data bus
      .m1_data_i(m1_data_i), .m1_data_o(m1_data_o), .m1_addr_i(m1_addr_i), .m1_sel_i(m1_sel_i), .m1_we_i(m1_we_i), .m1_cyc_i(m1_cyc_i),
      .m1_stb_i(m1_stb_i), .m1_ack_o(m1_ack_o), .m1_err_o(m1_err_o), .m1_rty_o(m1_rty_o),
      // slave 0 - usb core 0
      .s0_data_i(s0_data_i), .s0_data_o(s0_data_o), .s0_addr_o(s0_addr_o), .s0_sel_o(s0_sel_o), .s0_we_o(s0_we_o), .s0_cyc_o(s0_cyc_o),
      .s0_stb_o(s0_stb_o), .s0_ack_i(s0_ack_i), .s0_err_i(s0_err_i), .s0_rty_i(s0_rty_i),
      // slave 1 - usb core 1
      .s1_data_i(s1_data_i), .s1_data_o(s1_data_o), .s1_addr_o(s1_addr_o), .s1_sel_o(s1_sel_o), .s1_we_o(s1_we_o), .s1_cyc_o(s1_cyc_o),
      .s1_stb_o(s1_stb_o), .s1_ack_i(s1_ack_i), .s1_err_i(s1_err_i), .s1_rty_i(s1_rty_i),
      // slave 2 - mgt engine
      .s2_data_i(s2_data_i), .s2_data_o(s2_data_o), .s2_addr_o(s2_addr_o), .s2_sel_o(s2_sel_o), .s2_we_o(s2_we_o), .s2_cyc_o(s2_cyc_o),
      .s2_stb_o(s2_stb_o), .s2_ack_i(s2_ack_i), .s2_err_i(s2_err_i), .s2_rty_i(s2_rty_i),
      // slave 3 - fft engine
      .s3_data_i(s3_data_i), .s3_data_o(s3_data_o), .s3_addr_o(s3_addr_o), .s3_sel_o(s3_sel_o), .s3_we_o(s3_we_o), .s3_cyc_o(s3_cyc_o),
//      .s3_stb_o(s3_stb_o), .s3_ack_i(s3_ack_i), .s3_err_i(s3_err_i), .s3_rty_i(s3_rty_i),
      .s3_stb_o(s3_stb_o), .s3_ack_i(s3_ack_i), .s3_err_i(s3_err_i), .s3_rty_i(s3_rty_i)
      // master 2 - unused
//      .m2_data_i(1'b0), .m2_data_o(), .m2_addr_i(1'b0), .m2_sel_i(1'b0), .m2_we_i(1'b0), .m2_cyc_i(1'b0),
//      .m2_stb_i(1'b0), .m2_ack_o(), .m2_err_o(), .m2_rty_o(),
      // master 3 - unused
//      .m3_data_i(1'b0), .m3_data_o(), .m3_addr_i(1'b0), .m3_sel_i(1'b0), .m3_we_i(1'b0), .m3_cyc_i(1'b0),
//      .m3_stb_i(1'b0), .m3_ack_o(), .m3_err_o(), .m3_rty_o(),

      // master 4 - unused
//      .m4_data_i(1'b0), .m4_data_o(), .m4_addr_i(1'b0), .m4_sel_i(1'b0), .m4_we_i(1'b0), .m4_cyc_i(1'b0),
//      .m4_stb_i(1'b0), .m4_ack_o(), .m4_err_o(), .m4_rty_o(),
      // master 5 - unused
//      .m5_data_i(1'b0), .m5_data_o(), .m5_addr_i(1'b0), .m5_sel_i(1'b0), .m5_we_i(1'b0), .m5_cyc_i(1'b0),
//      .m5_stb_i(1'b0), .m5_ack_o(), .m5_err_o(), .m5_rty_o(),
      // master 6 - unused
//      .m6_data_i(1'b0), .m6_data_o(), .m6_addr_i(1'b0), .m6_sel_i(1'b0), .m6_we_i(1'b0), .m6_cyc_i(1'b0),
//      .m6_stb_i(1'b0), .m6_ack_o(), .m6_err_o(), .m6_rty_o(),
      // master 7 - unused
//      .m7_data_i(1'b0), .m7_data_o(), .m7_addr_i(1'b0), .m7_sel_i(1'b0), .m7_we_i(1'b0), .m7_cyc_i(1'b0),
//      .m7_stb_i(1'b0), .m7_ack_o(), .m7_err_o(), .m7_rty_o(),
       //slave 4 - cpu debug data
    ,  .s4_data_i(s4_data_i), .s4_data_o(s4_data_o), .s4_addr_o(s4_addr_o), .s4_sel_o(), .s4_we_o(), .s4_cyc_o(),
   .s4_stb_o(), .s4_ack_i(s4_ack_i), .s4_err_i(s4_err_i), .s4_rty_i(s4_rty_i)
      // slave 5 - unused
//      .s5_data_i(1'b0), .s5_data_o(), .s5_addr_o(), .s5_sel_o(), .s5_we_o(), .s5_cyc_o(),
//      .s5_stb_o(), .s5_ack_i(1'b0), .s5_err_i(1'b0), .s5_rty_i(1'b0),
      // slave 6 - unused
//      .s6_data_i(1'b0), .s6_data_o(), .s6_addr_o(), .s6_sel_o(), .s6_we_o(), .s6_cyc_o(),
//      .s6_stb_o(), .s6_ack_i(1'b0), .s6_err_i(1'b0), .s6_rty_i(1'b0),
      // slave 7 - unused
//      .s7_data_i(1'b0), .s7_data_o(), .s7_addr_o(), .s7_sel_o(), .s7_we_o(), .s7_cyc_o(),
//      .s7_stb_o(), .s7_ack_i(1'b0), .s7_err_i(1'b0), .s7_rty_i(1'b0),
      // slave 8 - unused
//      .s8_data_i(1'b0), .s8_data_o(), .s8_addr_o(), .s8_sel_o(), .s8_we_o(), .s8_cyc_o(),
//      .s8_stb_o(), .s8_ack_i(1'b0), .s8_err_i(1'b0), .s8_rty_i(1'b0),
      // slave 9 - unused
//      .s9_data_i(1'b0), .s9_data_o(), .s9_addr_o(), .s9_sel_o(), .s9_we_o(), .s9_cyc_o(),
//      .s9_stb_o(), .s9_ack_i(1'b0), .s9_err_i(1'b0), .s9_rty_i(1'b0),
      // slave 10 - unused
//      .s10_data_i(1'b0), .s10_data_o(), .s10_addr_o(), .s10_sel_o(), .s10_we_o(), .s10_cyc_o(),
//      .s10_stb_o(), .s10_ack_i(1'b0), .s10_err_i(1'b0), .s10_rty_i(1'b0),
      // slave 11 - unused
//      .s11_data_i(1'b0), .s11_data_o(), .s11_addr_o(), .s11_sel_o(), .s11_we_o(), .s11_cyc_o(),
//      .s11_stb_o(), .s11_ack_i(1'b0), .s11_err_i(1'b0), .s11_rty_i(1'b0),
      // slave 12 - unused
//      .s12_data_i(1'b0), .s12_data_o(), .s12_addr_o(), .s12_sel_o(), .s12_we_o(), .s12_cyc_o(),
//      .s12_stb_o(), .s12_ack_i(1'b0), .s12_err_i(1'b0), .s12_rty_i(1'b0),
      // slave 13 - unused
//      .s13_data_i(1'b0), .s13_data_o(), .s13_addr_o(), .s13_sel_o(), .s13_we_o(), .s13_cyc_o(),
//      .s13_stb_o(), .s13_ack_i(1'b0), .s13_err_i(1'b0), .s13_rty_i(1'b0),
      // slave 14 - unused
//      .s14_data_i(1'b0), .s14_data_o(), .s14_addr_o(), .s14_sel_o(), .s14_we_o(), .s14_cyc_o(),
//      .s14_stb_o(), .s14_ack_i(1'b0), .s14_err_i(1'b0), .s14_rty_i(1'b0),
      // slave 15 - unused
//      .s15_data_i(1'b0), .s15_data_o(), .s15_addr_o(), .s15_sel_o(), .s15_we_o(), .s15_cyc_o(),
//     .s15_stb_o(), .s15_ack_i(1'b0), .s15_err_i(1'b0), .s15_rty_i(1'b0)
   );
				 
				 

   // USB 2.0 core - wishbone slave 0
   usbf_top usbEngine0 (
      .wb_clk(wbClk), .clk_i(usbClk), .rst_i(reset_reg), .wb_addr_i(s0_addr_o), .wb_data_i(s0_data_o), .wb_data_o(s0_data_i),
      .wb_ack_o(s0_ack_i), .wb_we_i(s0_we_o), .wb_stb_i(s0_stb_o), .wb_cyc_i(s0_cyc_o), 
      .inta_o(s0_rty_i), .dma_ack_i(s0_sel_o), .susp_o(s0_err_i), .resume_req_i(s0_rty_i),
      // UTMI Interface
      .phy_clk_pad_i(phyClk0), .phy_rst_pad_o(phy_rst_pad_0_o_temp),
      .DataOut_pad_o(DataOut_pad_0_o), .TxValid_pad_o(TxValid_pad_0_o), .TxReady_pad_i(TxReady_pad_0_i),
      .RxValid_pad_i(RxValid_pad_0_i), .RxActive_pad_i(RxActive_pad_0_i), .RxError_pad_i(RxError_pad_0_i),
      .DataIn_pad_i(DataIn_pad_0_i), .XcvSelect_pad_o(XcvSelect_pad_0_o), .TermSel_pad_o(TermSel_pad_0_o),
      .SuspendM_pad_o(SuspendM_pad_0_o_temp), .LineState_pad_i(LineState_pad_0_i),
      .OpMode_pad_o(OpMode_pad_0_o_temp), .usb_vbus_pad_i(usb_vbus_pad_0_i),
      .VControl_Load_pad_o(VControl_Load_pad_0_o), .VControl_pad_o(VControl_pad_0_o_temp), .VStatus_pad_i(VStatus_pad_0_i)
   );  


// USB 2.0 core - wishbone slave 1
   usbf_top usbEngine1 (
      .wb_clk(wbClk), .clk_i(usbClk), .rst_i(reset_reg), .wb_addr_i(s1_addr_o), .wb_data_i(s1_data_o), .wb_data_o(s1_data_i),
      .wb_ack_o(s1_ack_i), .wb_we_i(s1_we_o), .wb_stb_i(s1_stb_o), .wb_cyc_i(s1_cyc_o), 
      .inta_o(s1_rty_i), .dma_ack_i(s1_sel_o), .susp_o(s1_err_i), .resume_req_i(s1_rty_i),
      // UTMI Interface
      .phy_clk_pad_i(phyClk1), .phy_rst_pad_o(phy_rst_pad_1_o_temp),
      .DataOut_pad_o(DataOut_pad_1_o), .TxValid_pad_o(TxValid_pad_1_o), .TxReady_pad_i(TxReady_pad_1_i),
      .RxValid_pad_i(RxValid_pad_1_i), .RxActive_pad_i(RxActive_pad_1_i), .RxError_pad_i(RxError_pad_1_i),
      .DataIn_pad_i(DataIn_pad_1_i), .XcvSelect_pad_o(XcvSelect_pad_1_o), .TermSel_pad_o(TermSel_pad_1_o),
      .SuspendM_pad_o(SuspendM_pad_1_o_temp), .LineState_pad_i(LineState_pad_1_i),
      .OpMode_pad_o(OpMode_pad_1_o_temp), .usb_vbus_pad_i(usb_vbus_pad_1_i),
      .VControl_Load_pad_o(VControl_Load_pad_1_o), .VControl_pad_o(VControl_pad_1_o_temp), .VStatus_pad_i(VStatus_pad_1_i)
   );
  

endmodule
