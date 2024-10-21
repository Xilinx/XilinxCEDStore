//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Store Buffer FIFO                                  ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Implementation of store buffer FIFO.                        ////
////                                                              ////
////  To Do:                                                      ////
////   - N/A                                                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: or1200_sb_fifo.v,v $
// Revision 1.1  2008/05/07 22:43:22  daughtry
// Initial Demo RTL check-in
//
// Revision 1.3  2002/11/06 13:53:41  simons
// SB mem width fixed.
//
// Revision 1.2  2002/08/22 02:18:55  lampret
// Store buffer has been tested and it works. BY default it is still disabled until uClinux confirms correct operation on FPGA board.
//
// Revision 1.1  2002/08/18 19:53:08  lampret
// Added store buffer.
//
//
			
//XLNX added this to generate a cleaner synchronous fifo
//the block in the ifdef was all added by XLNX
`define SYNC_FIFO
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_sb_fifo(
	clk_i, rst_i, dat_i, wr_i, rd_i, dat_o, full_o, empty_o
);

parameter dw = 68;
parameter fw = `OR1200_SB_LOG;
parameter fl = `OR1200_SB_ENTRIES;
parameter RAM_TYPE = "BLOCK_RAM";
//
// FIFO signals
//
input			clk_i;	// Clock
input			rst_i;	// Reset
input	[dw-1:0]	dat_i;	// Input data bus
input			wr_i;	// Write request
input			rd_i;	// Read request
output [dw-1:0]	dat_o;	// Output data bus
output			full_o;	// FIFO full
output			empty_o;// FIFO empty



`ifdef SYNC_FIFO
//the right way - fix before release
//async_fifo #(dw, fl, RAM_TYPE ) async_fifo (.din(dat_i), .rd_clk(clk_i), .rd_en(rd_i), .ainit(rst_i), .wr_clk(clk_i), .wr_en(wr_i),
//                       .dout(dat_o), .full(full_o), .empty(empty_o));	

//REMOVE - this is the workaround
async_fifo  async_fifo (.din(dat_i[67:0]), .rd_clk(clk_i), .rd_en(rd_i), .rst(rst_i), .wr_clk(clk_i), .wr_en(wr_i),
                       .dout(dat_o[67:0]), .full(full_o), .empty(empty_o));	
    defparam async_fifo.FIFO_WIDTH = 68;
	defparam async_fifo.FIFO_DEPTH = fl;
	defparam async_fifo.DEVICE = "7SERIES" ;
 	defparam async_fifo.FIFO_RAM_TYPE = "HARDFIFO";	                       
/*
async_fifo  async_fifo (.din(dat_i[67:52]), .rd_clk(clk_i), .rd_en(rd_i), .rst(rst_i), .wr_clk(clk_i), .wr_en(wr_i),
                       .dout(dat_o[67:52]), .full(full_o), .empty(empty_o));	
    defparam async_fifo.FIFO_WIDTH = 68;
	defparam async_fifo.FIFO_DEPTH = fl;
	defparam async_fifo.DEVICE = "7SERIES" ;
 	defparam async_fifo.FIFO_RAM_TYPE = "HARDFIFO";	 

async_fifo #(16, fl, RAM_TYPE ) async_fifo1 (.din(dat_i[51:36]), .rd_clk(clk_i), .rd_en(rd_i), .rst(rst_i), .wr_clk(clk_i), .wr_en(wr_i),
                       .dout(dat_o[51:36]));	
async_fifo #(18, fl, RAM_TYPE ) async_fifo2 (.din(dat_i[35:18]), .rd_clk(clk_i), .rd_en(rd_i), .rst(rst_i), .wr_clk(clk_i), .wr_en(wr_i),
                       .dout(dat_o[35:18]) );	
async_fifo #(18, fl, RAM_TYPE ) async_fifo3 (.din(dat_i[17:0]), .rd_clk(clk_i), .rd_en(rd_i), .rst(rst_i), .wr_clk(clk_i), .wr_en(wr_i),
                       .dout(dat_o[17:0]) );	
*/
/*
 input [FIFO_WIDTH-1:0] din,
   input                  rd_clk,
   input                  rd_en,
   input                  ainit,
   input                  wr_clk,
   input                  wr_en,

   output reg [FIFO_WIDTH-1:0]       dout,
   (* ASYNC_REG="TRUE", TIG="TRUE" *) output reg empty,
   (* ASYNC_REG="TRUE", TIG="TRUE" *) output reg full,
   (* ASYNC_REG="TRUE", TIG="TRUE" *) output reg almost_empty,
   (* ASYNC_REG="TRUE", TIG="TRUE" *) output reg almost_full,
   output reg                        wr_ack
*/ 

`else
//
// Internal regs
//
reg	[dw-1:0]	mem [fl-1:0];
reg	[dw-1:0]	dat_o;
reg	[fw+1:0]	cntr;
reg	[fw-1:0]	wr_pntr;
reg	[fw-1:0]	rd_pntr;
reg			empty_o;
reg			full_o;

				


always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		full_o <= #1 1'b0;
		empty_o <= #1 1'b1;
		wr_pntr <= #1 {fw{1'b0}};
		rd_pntr <= #1 {fw{1'b0}};
		cntr <= #1 {fw+2{1'b0}};
		dat_o <= #1 {dw{1'b0}};
	end
	else if (wr_i && rd_i) begin		// FIFO Read and Write
		mem[wr_pntr] <= #1 dat_i;
		if (wr_pntr >= fl-1)
			wr_pntr <= #1 {fw{1'b0}};
		else
			wr_pntr <= #1 wr_pntr + 1'b1;
		if (empty_o) begin
			dat_o <= #1 dat_i;
		end
		else begin
			dat_o <= #1 mem[rd_pntr];
		end
		if (rd_pntr >= fl-1)
			rd_pntr <= #1 {fw{1'b0}};
		else
			rd_pntr <= #1 rd_pntr + 1'b1;
	end
	else if (wr_i && !full_o) begin		// FIFO Write
		mem[wr_pntr] <= #1 dat_i;
		cntr <= #1 cntr + 1'b1;
		empty_o <= #1 1'b0;
		if (cntr >= (fl-1)) begin
			full_o <= #1 1'b1;
			cntr <= #1 fl;
		end
		if (wr_pntr >= fl-1)
			wr_pntr <= #1 {fw{1'b0}};
		else
			wr_pntr <= #1 wr_pntr + 1'b1;
	end
	else if (rd_i && !empty_o) begin	// FIFO Read
		dat_o <= #1 mem[rd_pntr];
		cntr <= #1 cntr - 1'b1;
		full_o <= #1 1'b0;
		if (cntr <= 1) begin
			empty_o <= #1 1'b1;
			cntr <= #1 {fw+2{1'b0}};
		end
		if (rd_pntr >= fl-1)
			rd_pntr <= #1 {fw{1'b0}};
		else
			rd_pntr <= #1 rd_pntr + 1'b1;
	end
`endif

endmodule
