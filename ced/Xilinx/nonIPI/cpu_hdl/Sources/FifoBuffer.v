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

module FifoBuffer(
	din,
	rd_clk,
	rd_en,
	rst,
	wr_clk,
	wr_en,
	dout,
	empty,
	full);


input [31 : 0] din;
input rd_clk;
input rd_en;
input rst;
input wr_clk;
input wr_en;
output [31 : 0] dout;
output empty;
output full;
	  
wire full_wire, wr_ack_wire; 
  
async_fifo buffer_fifo (.din(din), .rd_clk(rd_clk), .rd_en(rd_en), .rst(rst), .wr_clk(wr_clk), .wr_en(wr_en), .dout(dout), .full(full_wire), .wr_ack(wr_ack_wire), .empty(empty) );
    defparam buffer_fifo.FIFO_WIDTH = 32;
	defparam buffer_fifo.FIFO_DEPTH = 10;
	defparam buffer_fifo.DEVICE = "7SERIES" ;
 	defparam buffer_fifo.FIFO_RAM_TYPE = "BLOCKRAM";
 //	defparam buffer_fifo.OPTIMIZE = "POWER";

assign full = full_wire;
endmodule

