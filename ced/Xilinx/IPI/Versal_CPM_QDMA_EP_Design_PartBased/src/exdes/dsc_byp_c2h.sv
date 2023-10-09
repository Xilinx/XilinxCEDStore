//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
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
// Project    : The Xilinx PCI Express DMA 
// File       : dsc_byp_c2h.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

module dsc_byp_c2h
  (
   
   input 	       clk,
   input 	       resetn,
   input [1:0] 	       c2h_dsc_bypass,
   input 	       c2h_mm_marker_req,
   input logic [255:0] c2h_byp_out_dsc,
   input logic [2:0]   c2h_byp_out_fmt,
   input logic 	       c2h_byp_out_st_mm,
   input logic [1:0]   c2h_byp_out_dsc_sz,
   input logic [11:0]  c2h_byp_out_qid,
   input logic 	       c2h_byp_out_error,
   input logic [11:0]  c2h_byp_out_func,
   input logic         c2h_byp_out_mm_chn,
   input logic [15:0]  c2h_byp_out_cidx,
   input logic [2:0]   c2h_byp_out_port_id,
   input logic [6:0]   c2h_byp_out_pfch_tag,
   input logic 	       c2h_byp_out_vld,
   output logic        c2h_byp_out_rdy,
   
   output logic [63:0] c2h_byp_in_mm_radr,
   output logic [63:0] c2h_byp_in_mm_wadr,
   output logic [15:0] c2h_byp_in_mm_len,
   output logic        c2h_byp_in_mm_mrkr_req,
   output logic        c2h_byp_in_mm_sdi,
   output logic [11:0] c2h_byp_in_mm_qid,
   output logic        c2h_byp_in_mm_error,
   output logic [11:0] c2h_byp_in_mm_func,
   output logic [15:0] c2h_byp_in_mm_cidx,
   output logic [2:0]  c2h_byp_in_mm_port_id,
   output logic        c2h_byp_in_mm_no_dma,
   output logic        c2h_byp_in_mm_vld,
   input logic 	       c2h_byp_in_mm_rdy,

   output logic [63:0] c2h_byp_in_st_csh_addr,
   output logic [11:0] c2h_byp_in_st_csh_qid,
   output logic        c2h_byp_in_st_csh_error,
   output logic [11:0] c2h_byp_in_st_csh_func,
   output logic [2:0]  c2h_byp_in_st_csh_port_id,
   output logic [6:0]  c2h_byp_in_st_csh_pfch_tag,
   output logic        c2h_byp_in_st_csh_vld,
   input logic 	       c2h_byp_in_st_csh_rdy,
   input logic [6:0]   pfch_byp_tag

   );

   wire 	       c2h_csh_byp;
   wire 	       c2h_sim_byp;

   // c2h_csh_byp is used for C2H St Cash Bypass and also C2H MM bypass looback.
   assign c2h_csh_byp = (c2h_dsc_bypass == 2'b01) ? 1'b1 : 1'b0; // 2'b01 : Cache dsc bypass/MM
   assign c2h_sim_byp = c2h_dsc_bypass[1];                       // 2'b1x : Simple dsc_bypass
   
   logic 	       mm_fifo_full;
   logic 	       st_fifo_full;
   assign c2h_byp_out_rdy     = ~mm_fifo_full | ~st_fifo_full;

   // AXI-MM C2H bypass

   localparam MM_FIFO_WIDTH = 1+3+12+12+16+256;
   logic 	       mm_fifo_rden;
   logic 	       mm_fifo_empty;
   logic 	       mm_fifo_wren;
   logic [255:0]       mm_dout_dsc;
   
   assign mm_fifo_wren           = c2h_byp_out_vld & c2h_byp_out_st_mm & ~mm_fifo_full;
   assign mm_fifo_rden           = c2h_byp_in_mm_rdy & ~mm_fifo_empty;
   assign c2h_byp_in_mm_vld      = c2h_mm_marker_req | (c2h_dsc_bypass & ~mm_fifo_empty );  // Fix
   
   assign c2h_byp_in_mm_mrkr_req = c2h_mm_marker_req;
   assign c2h_byp_in_mm_radr     = mm_dout_dsc[63:0];
   assign c2h_byp_in_mm_wadr     = mm_dout_dsc[191:128];
   assign c2h_byp_in_mm_len      = mm_dout_dsc[79:64];
   assign c2h_byp_in_mm_sdi      = mm_dout_dsc[94];  // eop. send sdi at last discriptor;
   assign c2h_byp_in_mm_no_dma   = 1'b0;

      xpm_fifo_sync # 
     (
      .FIFO_MEMORY_TYPE     ("auto"), //string; "auto", "block", "distributed", or "ultra";
      .ECC_MODE             ("no_ecc"), //string; "no_ecc" or "en_ecc";
      .FIFO_WRITE_DEPTH     (16), //positive integer
      .WRITE_DATA_WIDTH     (MM_FIFO_WIDTH), //positive integer
      .WR_DATA_COUNT_WIDTH  (4), //positive integer
      .PROG_FULL_THRESH     (10), //positive integer
      .FULL_RESET_VALUE     (0), //positive integer; 0 or 1
      .READ_MODE            ("fwft"), //string; "std" or "fwft";
      .FIFO_READ_LATENCY    (0), //positive integer;
      .READ_DATA_WIDTH      (MM_FIFO_WIDTH), //positive integer
      .RD_DATA_COUNT_WIDTH  (4), //positive integer
      .PROG_EMPTY_THRESH    (10), //positive integer
      .DOUT_RESET_VALUE     ("0"), //string
      .WAKEUP_TIME          (0) //positive integer; 0 or 2;
      ) xpm_fifo_desc_c2h_MM_i 
       (
	.sleep           (1'b0),
	.rst             (~resetn),
	.wr_clk          (clk),
	.wr_en           (mm_fifo_wren),
	.din             ({c2h_byp_out_error, c2h_byp_out_port_id, c2h_byp_out_qid, c2h_byp_out_func, c2h_byp_out_cidx, c2h_byp_out_dsc}),
	.full            (mm_fifo_full),
	.prog_full       (mm_prog_full),
	.wr_data_count   (),
	.overflow        (overflow),
	.wr_rst_busy     (wr_rst_busy),
	.rd_en           (mm_fifo_rden),
	.dout            ({c2h_byp_in_mm_error, c2h_byp_in_mm_port_id, c2h_byp_in_mm_qid, c2h_byp_in_mm_func, c2h_byp_in_mm_cidx, mm_dout_dsc}),
	.empty           (mm_fifo_empty),
	.prog_empty      (prog_empty),
	.rd_data_count   (),
	.underflow       (underflow),
	.rd_rst_busy     (rd_rst_busy),
	.injectsbiterr   (1'b0),
	.injectdbiterr   (1'b0),
	.sbiterr         (),
	.dbiterr         ()
	);
   // End of xpm_fifo_sync instance declaration



// AXI-ST

   localparam ST_FIFO_WIDTH = 1+7+3+12+12+64;
   logic 	       st_fifo_rden;
   logic 	       st_fifo_empty;
   logic 	       st_fifo_wren;
   logic [63:0]       st_dout_dsc;
   logic [6:0] 	      c2h_pfch_tag;
//   logic [6:0] 	      c2h_pfch_tag_in;

//   assign c2h_pfch_tag_in = c2h_sim_byp ? 'h0 : c2h_byp_out_pfch_tag;
   
   
   assign st_fifo_wren               = c2h_byp_out_vld & ~c2h_byp_out_st_mm & ~st_fifo_full;
   assign st_fifo_rden               = c2h_byp_in_st_csh_rdy & ~st_fifo_empty;
   assign c2h_byp_in_st_csh_vld      = (c2h_csh_byp | c2h_sim_byp ) & ~st_fifo_empty;

   assign c2h_byp_in_st_csh_addr     = st_dout_dsc[63:0];
   assign c2h_byp_in_st_csh_pfch_tag = c2h_sim_byp ? pfch_byp_tag : c2h_pfch_tag;  // for simple bypass use prefetch tag register


      xpm_fifo_sync # 
     (
      .FIFO_MEMORY_TYPE     ("auto"), //string; "auto", "block", "distributed", or "ultra";
      .ECC_MODE             ("no_ecc"), //string; "no_ecc" or "en_ecc";
      .FIFO_WRITE_DEPTH     (16), //positive integer
      .WRITE_DATA_WIDTH     (ST_FIFO_WIDTH), //positive integer
      .WR_DATA_COUNT_WIDTH  (4), //positive integer
      .PROG_FULL_THRESH     (10), //positive integer
      .FULL_RESET_VALUE     (0), //positive integer; 0 or 1
      .READ_MODE            ("fwft"), //string; "std" or "fwft";
      .FIFO_READ_LATENCY    (0), //positive integer;
      .READ_DATA_WIDTH      (ST_FIFO_WIDTH), //positive integer
      .RD_DATA_COUNT_WIDTH  (4), //positive integer
      .PROG_EMPTY_THRESH    (10), //positive integer
      .DOUT_RESET_VALUE     ("0"), //string
      .WAKEUP_TIME          (0) //positive integer; 0 or 2;
      ) xpm_fifo_desc_c2h_ST_i 
       (
	.sleep           (1'b0),
	.rst             (~resetn),
	.wr_clk          (clk),
	.wr_en           (st_fifo_wren),
	.din             ({c2h_byp_out_error, c2h_byp_out_pfch_tag, c2h_byp_out_port_id, c2h_byp_out_qid, c2h_byp_out_func, c2h_byp_out_dsc[63:0]}),
	.full            (st_fifo_full),
	.prog_full       (st_prog_full),
	.wr_data_count   (),
	.overflow        (),
	.wr_rst_busy     (),
	.rd_en           (st_fifo_rden),
	.dout            ({c2h_byp_in_st_csh_error, c2h_pfch_tag, c2h_byp_in_st_csh_port_id, c2h_byp_in_st_csh_qid, c2h_byp_in_st_csh_func, st_dout_dsc}),
	.empty           (st_fifo_empty),
	.prog_empty      (),
	.rd_data_count   (),
	.underflow       (),
	.rd_rst_busy     (),
	.injectsbiterr   (1'b0),
	.injectdbiterr   (1'b0),
	.sbiterr         (),
	.dbiterr         ()
	);
   // End of xpm_fifo_sync instance declaration

endmodule // dsc_bypass

