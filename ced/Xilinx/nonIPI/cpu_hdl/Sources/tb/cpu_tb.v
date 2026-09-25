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

module test;
	reg [0:72] indata_array;
	reg sysClk;
	reg reset;
	reg bench_TILE0_REFCLK_PAD_N_IN;
	wire bench_TILE0_REFCLK_PAD_P_IN;
	wire bench_TILE1_REFCLK_PAD_N_IN;
	wire bench_TILE1_REFCLK_PAD_P_IN;
	wire bench_TILE2_REFCLK_PAD_N_IN;
	wire bench_TILE2_REFCLK_PAD_P_IN;
	wire bench_TILE3_REFCLK_PAD_N_IN;
	wire bench_TILE3_REFCLK_PAD_P_IN;
	wire bench_GTPRESET_IN;
	wire  [7:0] bench_RXN_IN;
	wire  [7:0] bench_RXP_IN;
	wire  [7:0] bench_TXN_OUT;
	wire  [7:0] bench_TXP_OUT;
	wire bench_phy_rst_pad_0_o;
	wire  [7:0] bench_DataOut_pad_0_o;
	wire bench_TxValid_pad_0_o;
	wire bench_TxReady_pad_0_i;
	wire  [7:0] bench_DataIn_pad_0_i;
	wire bench_RxValid_pad_0_i;
	wire bench_RxActive_pad_0_i;
	wire bench_RxError_pad_0_i;
	wire bench_XcvSelect_pad_0_o;
	wire bench_TermSel_pad_0_o;
	wire bench_SuspendM_pad_0_o;
	wire  [1:0] bench_LineState_pad_0_i;
	wire  [1:0] bench_OpMode_pad_0_o;
	wire bench_usb_vbus_pad_0_i;
	wire bench_VControl_Load_pad_0_o;
	wire  [3:0] bench_VControl_pad_0_o;
	wire  [7:0] bench_VStatus_pad_0_i;
	wire bench_phy_rst_pad_1_o;
	wire  [7:0] bench_DataOut_pad_1_o;
	wire bench_TxValid_pad_1_o;
	wire bench_TxReady_pad_1_i;
	wire  [7:0] bench_DataIn_pad_1_i;
	wire bench_RxValid_pad_1_i;
	wire bench_RxActive_pad_1_i;
	wire bench_RxError_pad_1_i;
	wire bench_XcvSelect_pad_1_o;
	wire bench_TermSel_pad_1_o;
	wire bench_SuspendM_pad_1_o;
	wire  [1:0] bench_LineState_pad_1_i;
	wire  [1:0] bench_OpMode_pad_1_o;
	wire bench_usb_vbus_pad_1_i;
	wire bench_VControl_Load_pad_1_o;
	wire  [3:0] bench_VControl_pad_1_o;
	wire  [7:0] bench_VStatus_pad_1_i;
	wire bench_or1200_clmode;
	wire bench_or1200_pic_ints;
	wire  [3:0] bench_or1200_pm_out;

	assign bench_sysClk = sysClk;
	assign bench_reset = reset;
	initial
	begin
	    bench_TILE0_REFCLK_PAD_N_IN = 0;
	    forever #7 	bench_TILE0_REFCLK_PAD_N_IN = ~bench_TILE0_REFCLK_PAD_N_IN;
	end
	assign  #2 bench_TILE0_REFCLK_PAD_P_IN = bench_TILE0_REFCLK_PAD_N_IN;
	assign  #4 bench_TILE1_REFCLK_PAD_N_IN = bench_TILE0_REFCLK_PAD_N_IN;
	assign  #6 bench_TILE1_REFCLK_PAD_P_IN = bench_TILE0_REFCLK_PAD_N_IN;
	assign  #8 bench_TILE2_REFCLK_PAD_N_IN = bench_TILE0_REFCLK_PAD_N_IN;
	assign  #10 bench_TILE2_REFCLK_PAD_P_IN = bench_TILE0_REFCLK_PAD_N_IN;
	assign  #12 bench_TILE3_REFCLK_PAD_N_IN = bench_TILE0_REFCLK_PAD_N_IN;
	assign  #14 bench_TILE3_REFCLK_PAD_P_IN = bench_TILE0_REFCLK_PAD_N_IN;
	assign bench_GTPRESET_IN = indata_array[8:8];
	assign bench_RXN_IN = indata_array[9:16];
	assign bench_RXP_IN = indata_array[17:24];
	assign bench_TxReady_pad_0_i = indata_array[25:25];
	assign bench_DataIn_pad_0_i = indata_array[26:33];
	assign bench_RxValid_pad_0_i = indata_array[34:34];
	assign bench_RxActive_pad_0_i = indata_array[35:35];
	assign bench_RxError_pad_0_i = indata_array[36:36];
	assign bench_LineState_pad_0_i = indata_array[37:38];
	assign bench_usb_vbus_pad_0_i = indata_array[39:39];
	assign bench_VStatus_pad_0_i = indata_array[40:47];
	assign bench_TxReady_pad_1_i = indata_array[48:48];
	assign bench_DataIn_pad_1_i = indata_array[49:56];
	assign bench_RxValid_pad_1_i = indata_array[57:57];
	assign bench_RxActive_pad_1_i = indata_array[58:58];
	assign bench_RxError_pad_1_i = indata_array[59:59];
	assign bench_LineState_pad_1_i = indata_array[60:61];
	assign bench_usb_vbus_pad_1_i = indata_array[62:62];
	assign bench_VStatus_pad_1_i = indata_array[63:70];
	assign bench_or1200_clmode = indata_array[71:71];
	assign bench_or1200_pic_ints = indata_array[72:72];

	initial
	begin
		#0  sysClk = 1'b0;
	end

	always
	begin
		#5  sysClk = !sysClk;
	end

	initial
	begin
		#0  reset = 1'b0;
	end

	initial
	begin
		#500 reset = 0;
		#700 reset = 1;
		#100 reset = 0;
	end

	always
	  begin : stim
	     reg [0:31] r1;
	     reg [0:31] r2;
	     reg [0:7] 	r3;

	     r1 = $random;
	     r2 = $random;
	     r3 = $random;
	     
	     #5  indata_array = {r1, r2, r3};
	  end


	top inst(
        .sysClk(bench_sysClk), 
        .reset(bench_reset), 
        .TILE0_REFCLK_PAD_N_IN(bench_TILE0_REFCLK_PAD_N_IN), 
        .TILE0_REFCLK_PAD_P_IN(bench_TILE0_REFCLK_PAD_P_IN), 
        .TILE1_REFCLK_PAD_N_IN(bench_TILE1_REFCLK_PAD_N_IN), 
        .TILE1_REFCLK_PAD_P_IN(bench_TILE1_REFCLK_PAD_P_IN), 
        .TILE2_REFCLK_PAD_N_IN(bench_TILE2_REFCLK_PAD_N_IN), 
        .TILE2_REFCLK_PAD_P_IN(bench_TILE2_REFCLK_PAD_P_IN), 
        .TILE3_REFCLK_PAD_N_IN(bench_TILE3_REFCLK_PAD_N_IN), 
        .TILE3_REFCLK_PAD_P_IN(bench_TILE3_REFCLK_PAD_P_IN), 
        .GTPRESET_IN(bench_GTPRESET_IN), 
        .RXN_IN(bench_RXN_IN), 
        .RXP_IN(bench_RXP_IN), 
        .TXN_OUT(bench_TXN_OUT), 
        .TXP_OUT(bench_TXP_OUT), 
        .phy_rst_pad_0_o(bench_phy_rst_pad_0_o), 
        .DataOut_pad_0_o(bench_DataOut_pad_0_o), 
        .TxValid_pad_0_o(bench_TxValid_pad_0_o), 
        .TxReady_pad_0_i(bench_TxReady_pad_0_i), 
        .DataIn_pad_0_i(bench_DataIn_pad_0_i), 
        .RxValid_pad_0_i(bench_RxValid_pad_0_i), 
        .RxActive_pad_0_i(bench_RxActive_pad_0_i), 
        .RxError_pad_0_i(bench_RxError_pad_0_i), 
        .XcvSelect_pad_0_o(bench_XcvSelect_pad_0_o), 
        .TermSel_pad_0_o(bench_TermSel_pad_0_o), 
        .SuspendM_pad_0_o(bench_SuspendM_pad_0_o), 
        .LineState_pad_0_i(bench_LineState_pad_0_i), 
        .OpMode_pad_0_o(bench_OpMode_pad_0_o), 
        .usb_vbus_pad_0_i(bench_usb_vbus_pad_0_i), 
        .VControl_Load_pad_0_o(bench_VControl_Load_pad_0_o), 
        .VControl_pad_0_o(bench_VControl_pad_0_o), 
        .VStatus_pad_0_i(bench_VStatus_pad_0_i), 
        .phy_rst_pad_1_o(bench_phy_rst_pad_1_o), 
        .DataOut_pad_1_o(bench_DataOut_pad_1_o), 
        .TxValid_pad_1_o(bench_TxValid_pad_1_o), 
        .TxReady_pad_1_i(bench_TxReady_pad_1_i), 
        .DataIn_pad_1_i(bench_DataIn_pad_1_i), 
        .RxValid_pad_1_i(bench_RxValid_pad_1_i), 
        .RxActive_pad_1_i(bench_RxActive_pad_1_i), 
        .RxError_pad_1_i(bench_RxError_pad_1_i), 
        .XcvSelect_pad_1_o(bench_XcvSelect_pad_1_o), 
        .TermSel_pad_1_o(bench_TermSel_pad_1_o), 
        .SuspendM_pad_1_o(bench_SuspendM_pad_1_o), 
        .LineState_pad_1_i(bench_LineState_pad_1_i), 
        .OpMode_pad_1_o(bench_OpMode_pad_1_o), 
        .usb_vbus_pad_1_i(bench_usb_vbus_pad_1_i), 
        .VControl_Load_pad_1_o(bench_VControl_Load_pad_1_o), 
        .VControl_pad_1_o(bench_VControl_pad_1_o), 
        .VStatus_pad_1_i(bench_VStatus_pad_1_i), 
        .or1200_clmode(bench_or1200_clmode), 
        .or1200_pic_ints(bench_or1200_pic_ints), 
        .or1200_pm_out(bench_or1200_pm_out)
    );

	initial
	begin
//		$monitor($time, " reset = %b, sysClk = %b, TILE0_REFCLK_PAD_N_IN = %b , TILE0_REFCLK_PAD_P_IN = %b , TILE1_REFCLK_PAD_N_IN = %b , TILE1_REFCLK_PAD_P_IN = %b , TILE2_REFCLK_PAD_N_IN = %b , TILE2_REFCLK_PAD_P_IN = %b , TILE3_REFCLK_PAD_N_IN = %b , TILE3_REFCLK_PAD_P_IN = %b , GTPRESET_IN = %b , RXN_IN = %b , RXP_IN = %b , TxReady_pad_0_i = %b , DataIn_pad_0_i = %b , RxValid_pad_0_i = %b , RxActive_pad_0_i = %b , RxError_pad_0_i = %b , LineState_pad_0_i = %b , usb_vbus_pad_0_i = %b , VStatus_pad_0_i = %b , TxReady_pad_1_i = %b , DataIn_pad_1_i = %b , RxValid_pad_1_i = %b , RxActive_pad_1_i = %b , RxError_pad_1_i = %b , LineState_pad_1_i = %b , usb_vbus_pad_1_i = %b , VStatus_pad_1_i = %b , or1200_clmode = %b , or1200_pic_ints = %b , TXN_OUT = %b , TXP_OUT = %b , phy_rst_pad_0_o = %b , DataOut_pad_0_o = %b , TxValid_pad_0_o = %b , XcvSelect_pad_0_o = %b , TermSel_pad_0_o = %b , SuspendM_pad_0_o = %b , OpMode_pad_0_o = %b , VControl_Load_pad_0_o = %b , VControl_pad_0_o = %b , phy_rst_pad_1_o = %b , DataOut_pad_1_o = %b , TxValid_pad_1_o = %b , XcvSelect_pad_1_o = %b , TermSel_pad_1_o = %b , SuspendM_pad_1_o = %b , OpMode_pad_1_o = %b , VControl_Load_pad_1_o = %b , VControl_pad_1_o = %b , or1200_pm_out = %b  ",
//			bench_reset, bench_sysClk, bench_TILE0_REFCLK_PAD_N_IN, bench_TILE0_REFCLK_PAD_P_IN, bench_TILE1_REFCLK_PAD_N_IN, bench_TILE1_REFCLK_PAD_P_IN, bench_TILE2_REFCLK_PAD_N_IN, bench_TILE2_REFCLK_PAD_P_IN, bench_TILE3_REFCLK_PAD_N_IN, bench_TILE3_REFCLK_PAD_P_IN, bench_GTPRESET_IN, bench_RXN_IN, bench_RXP_IN, bench_TxReady_pad_0_i, bench_DataIn_pad_0_i, bench_RxValid_pad_0_i, bench_RxActive_pad_0_i, bench_RxError_pad_0_i, bench_LineState_pad_0_i, bench_usb_vbus_pad_0_i, bench_VStatus_pad_0_i, bench_TxReady_pad_1_i, bench_DataIn_pad_1_i, bench_RxValid_pad_1_i, bench_RxActive_pad_1_i, bench_RxError_pad_1_i, bench_LineState_pad_1_i, bench_usb_vbus_pad_1_i, bench_VStatus_pad_1_i, bench_or1200_clmode, bench_or1200_pic_ints, bench_TXN_OUT, bench_TXP_OUT, bench_phy_rst_pad_0_o, bench_DataOut_pad_0_o, bench_TxValid_pad_0_o, bench_XcvSelect_pad_0_o, bench_TermSel_pad_0_o, bench_SuspendM_pad_0_o, bench_OpMode_pad_0_o, bench_VControl_Load_pad_0_o, bench_VControl_pad_0_o, bench_phy_rst_pad_1_o, bench_DataOut_pad_1_o, bench_TxValid_pad_1_o, bench_XcvSelect_pad_1_o, bench_TermSel_pad_1_o, bench_SuspendM_pad_1_o, bench_OpMode_pad_1_o, bench_VControl_Load_pad_1_o, bench_VControl_pad_1_o, bench_or1200_pm_out);
	end

	initial
	begin
	   #5000 $display("TEST PASSED");
	   $finish;
	end

endmodule
